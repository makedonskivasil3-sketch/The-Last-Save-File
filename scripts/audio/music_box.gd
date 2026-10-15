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

## Lo-fi on purpose (an old music box). A full render takes ~80-120 ms, so it
## only happens at load, behind area fades, or as a flashback starts; cached.
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


## The theme at this memory level (0..5) as a looping stream.
static func stream(level: int, variant := "normal") -> AudioStreamWAV:
	level = clampi(level, 0, MAX_LEVEL)
	var key := "theme_%d_%s" % [level, variant]
	if not OwnerMemory.runtime_cache.has(key):
		if variant == "reverse":
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
	var loop_len := BEAT * BEATS
	var b := Synth.begin(loop_len + 1.6, RATE)
	for n in NOTES:
		if int(n[3]) > level:
			continue
		var midi: int = n[1]
		if variant == "invert":
			midi = 2 * ROOT - midi
		_tine(b, float(n[0]) * BEAT, _freq(midi), float(n[2]) * BEAT, float(n[4]))
	Synth.wrap(b, loop_len)
	if variant == "reverse":
		b.reverse()
	Synth.normalize(b, 0.7)
	return Synth.to_wav(b, true)


## One music-box tine: a plucked sine with a bright overtone and a click.
static func _tine(b: PackedFloat32Array, start: float, f: float, length: float, vol: float) -> void:
	var ring := minf(length + 0.35, 1.0)  # the tail is inaudible past this
	var decay := 3.2 if f > 200.0 else 1.6
	Synth.tone(b, start, ring, f, f, 0.5 * vol, Synth.Wave.SINE, 0.002, decay)
	Synth.tone(b, start, ring * 0.5, f * 2.0, f * 2.0, 0.12 * vol, Synth.Wave.SINE, 0.001, decay * 2.5)
	Synth.tone(b, start, 0.02, f * 4.0, f * 4.0, 0.08 * vol, Synth.Wave.TRIANGLE, 0.0005, 120.0)


static func _freq(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)
