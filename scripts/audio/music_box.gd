class_name MusicBox
extends RefCounted
## The game's one melody: a fragile music box in A minor that grows with
## Rue's memories. With none it's two notes; each memory adds a layer; with
## all five it finally resolves (to A major). Rendered from code (Synth) and
## cached per level and variant:
##   "normal"   as written
##   "reverse"  played backwards (the Edge: time running out)
##   "invert"   upside down, every interval mirrored around A (out of bounds)
## Loops seamlessly (late notes ring into the start).

## Lo-fi on purpose (an old music box). A full render takes ~20-70 ms (several
## times that on the web, which has no threads), so themes the session will
## need are built ahead of time a few notes per frame (prewarm(), run by Sfx
## in quiet moments); stream() only renders on the spot if that hasn't
## happened yet. Cached for the run.
const RATE := 8000
const BEAT := 0.42          # seconds
const BEATS := 16
const ROOT := 69            # A4: the axis for "invert"

## [beat, midi note, length in beats, level it appears at, volume].
const NOTES := [
	# Level 0: the motif, two notes.
	[0.0, 76, 2.0, 0, 1.0], [2.0, 69, 1.0, 0, 1.0],
	# Level 1: the first phrase finishes.
	[3.0, 72, 1.0, 1, 0.9], [4.0, 71, 2.0, 1, 0.9], [6.0, 69, 2.0, 1, 0.9],
	# Level 2: the answer, ending unresolved on the leading tone.
	[8.0, 76, 1.0, 2, 0.9], [9.0, 74, 1.0, 2, 0.85], [10.0, 72, 1.0, 2, 0.85],
	[11.0, 71, 1.0, 2, 0.85], [12.0, 68, 2.0, 2, 0.9],
	# Level 3: a bass line underneath.
	[0.0, 45, 4.0, 3, 0.7], [4.0, 41, 4.0, 3, 0.7], [8.0, 48, 4.0, 3, 0.7], [12.0, 40, 4.0, 3, 0.7],
	# Level 4: a high countermelody, softly.
	[1.0, 81, 2.0, 4, 0.45], [5.0, 79, 2.0, 4, 0.45], [9.0, 77, 2.0, 4, 0.45], [13.0, 76, 1.0, 4, 0.45],
	# Level 5: it comes home. A major, at last.
	[14.0, 69, 2.0, 5, 1.0], [14.0, 73, 2.0, 5, 0.7], [14.0, 76, 2.0, 5, 0.6], [14.0, 57, 2.0, 5, 0.6],
]
const MAX_LEVEL := 5


## The theme as far as you remember it, outside the RUE ending: the last
## layer (where it resolves) is held back for that ending alone.
static func held_level(memories: int) -> int:
	if OwnerMemory.last_ending == "rue" and memories >= MAX_LEVEL:
		return MAX_LEVEL  # you've heard it whole; the title remembers
	return mini(memories, MAX_LEVEL - 1)


## The theme at this memory level (0..5) as a looping stream.
static func stream(level: int, variant := "normal") -> AudioStreamWAV:
	level = clampi(level, 0, MAX_LEVEL)
	var key := "theme_%d_%s" % [level, variant]
	if not OwnerMemory.runtime_cache.has(key):
		if Sfx.finish_job(key):
			pass  # it was being built in the background: finished it now
		elif variant == "reverse":
			# Backwards is the same samples, flipped: no need to render again.
			OwnerMemory.runtime_cache[key] = _reversed(stream(level))
		else:
			OwnerMemory.runtime_cache[key] = render(level, variant)
	return OwnerMemory.runtime_cache[key]


static func _reversed(src: AudioStreamWAV) -> AudioStreamWAV:
	var data := src.data
	var out := PackedByteArray()
	out.resize(data.size())
	var n := data.size() / 2
	for i in n:
		out.encode_s16(i * 2, data.decode_s16((n - 1 - i) * 2))
	var wav := src.duplicate() as AudioStreamWAV
	wav.data = out
	return wav


## How many notes the theme has at a memory level.
static func notes_at(level: int) -> int:
	return NOTES.filter(func(n: Array) -> bool: return int(n[3]) <= level).size()


static func render(level: int, variant := "normal") -> AudioStreamWAV:
	var job := Job.new(level, variant)
	job.step(-1)
	return job.result


## Queue this theme to be built in the background (no-op if it's cached or
## already queued). "reverse" builds the normal theme, then flips it.
static func prewarm(level: int, variant := "normal") -> void:
	level = clampi(level, 0, MAX_LEVEL)
	var key := "theme_%d_%s" % [level, variant]
	if OwnerMemory.runtime_cache.has(key):
		return
	if variant == "reverse":
		prewarm(level)
	Sfx.queue_job(key, Job.new(level, variant))


## A theme render that can be spread over frames: step() renders notes until
## its time budget runs out. When done, `result` holds the stream and it's in
## the cache.
class Job:
	var level: int
	var variant: String
	var result: AudioStreamWAV
	var _b: PackedFloat32Array
	var _notes: Array = []
	var _i := 0

	func _init(lv: int, v: String) -> void:
		level = clampi(lv, 0, MusicBox.MAX_LEVEL)
		variant = v
		if variant == "reverse":
			return  # derived from the normal theme in step()
		for n in MusicBox.NOTES:
			if int(n[3]) <= level:
				_notes.append(n)

	## Renders for up to budget_usec (< 0: until done). Returns true when done.
	func step(budget_usec: int) -> bool:
		var key := "theme_%d_%s" % [level, variant]
		if OwnerMemory.runtime_cache.has(key):
			result = OwnerMemory.runtime_cache[key]
			return true
		if variant == "reverse":
			result = MusicBox._reversed(MusicBox.stream(level))
			OwnerMemory.runtime_cache[key] = result
			return true
		var t0 := Time.get_ticks_usec()
		if _b.is_empty():
			_b = Synth.begin(MusicBox.BEAT * MusicBox.BEATS + 1.6, MusicBox.RATE)
		Synth.rate = MusicBox.RATE  # other sounds may have been built in between
		while _i < _notes.size():
			var n: Array = _notes[_i]
			_i += 1
			var midi: int = n[1]
			if variant == "invert":
				midi = 2 * MusicBox.ROOT - midi
			MusicBox._tine(_b, float(n[0]) * MusicBox.BEAT, MusicBox._freq(midi), float(n[2]) * MusicBox.BEAT, float(n[4]))
			if budget_usec >= 0 and Time.get_ticks_usec() - t0 > budget_usec:
				return false
		_b = Synth.wrap(_b, MusicBox.BEAT * MusicBox.BEATS)
		Synth.normalize(_b, 0.7)
		result = Synth.to_wav(_b, true)
		OwnerMemory.runtime_cache[key] = result
		return true


## One music-box tine: a plucked sine with a bright overtone and a click.
static func _tine(b: PackedFloat32Array, start: float, f: float, length: float, vol: float) -> void:
	var ring := minf(length + 0.35, 1.0)  # the tail is inaudible past this
	var decay := 3.2 if f > 200.0 else 1.6
	Synth.tone(b, start, ring, f, f, 0.5 * vol, Synth.Wave.SINE, 0.002, decay)
	Synth.tone(b, start, ring * 0.5, f * 2.0, f * 2.0, 0.12 * vol, Synth.Wave.SINE, 0.001, decay * 2.5)
	Synth.tone(b, start, 0.02, f * 4.0, f * 4.0, 0.08 * vol, Synth.Wave.TRIANGLE, 0.0005, 120.0)


static func _freq(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)
