class_name Drone
extends AudioStreamPlayer
## The room tone of someone else's save: four layers that fade in as the
## owner's `tension` (awareness, 0..1) rises. All synthesised once per run and
## cached on OwnerMemory.runtime_cache; layers after the base hum are built a
## frame at a time so nothing hitches.
##
##   hum       always: two slightly detuned low partials beating against each other
##   dread     from ~25%: a tritone / minor-second pad, slowly breathing
##   shimmer   from ~55%: a thin high whine over hissing static (stronger at the Edge)
##   heartbeat from ~65%: lub-dub, quickening with tension
##   crackle   random digital crackle, more often as tension rises
##
## Every loop is seamless (whole numbers of cycles, or crossfaded noise).
## Music bus; Settings.music_volume controls it. Reduce flashing / glitch
## intensity soften the shimmer and crackle (via Sfx.harshness()).

const HUM_RATE := 11025
const LOOP_SECONDS := 4.0

## 0..1, set by OwnerDirector from awareness.
var tension := 0.0
## 1 in the Edge: the shimmer never quite goes away there.
var edge := 0.0

var _layers: Dictionary = {}   # name -> AudioStreamPlayer
var _crackle: AudioStreamPlayer
var _heart: AudioStreamPlayer
var _beat_timer := 1.0
var _build_queue := ["dread", "shimmer", "crackle"]


func _ready() -> void:
	bus = "Music"
	stream = _cached("hum", _build_hum)
	volume_db = -15.0
	play()
	_heart = AudioStreamPlayer.new()
	_heart.bus = "SFX"  # a threat cue: muting the music mustn't silence it
	add_child(_heart)


func _process(delta: float) -> void:
	# Build one missing layer per frame.
	if not _build_queue.is_empty():
		var n: String = _build_queue.pop_front()
		_add_layer(n)

	var t := tension
	var harsh := Sfx.harshness()
	pitch_scale = 1.0 - t * 0.05
	_set_layer("dread", smoothstep(0.2, 0.6, t), -14.0, delta)
	_set_layer("shimmer", maxf(smoothstep(0.5, 0.95, t), edge * 0.6) * harsh, -20.0, delta)

	# Heartbeat: from 65% awareness, 55 -> 125 bpm.
	if t > 0.65:
		_beat_timer -= delta
		if _beat_timer <= 0.0:
			_beat_timer = 60.0 / lerpf(55.0, 125.0, (t - 0.65) / 0.35)
			_heart.stream = Sfx.stream("heartbeat")
			_heart.volume_db = -10.0 + (t - 0.65) * 18.0
			_heart.play()

	# Digital crackle, more often as tension rises.
	if _crackle and t > 0.15 and not _crackle.playing and randf() < t * 2.0 * delta:
		_crackle.pitch_scale = randf_range(0.6, 1.6)
		_crackle.volume_db = -20.0 + linear_to_db(maxf(harsh * Settings.glitch_intensity, 0.05))
		_crackle.play()


func _exit_tree() -> void:
	# Stop explicitly so the audio server releases its playback on quit.
	stop()
	for p in _layers.values():
		p.stop()


func _set_layer(name: String, amount: float, full_db: float, delta: float) -> void:
	var p: AudioStreamPlayer = _layers.get(name)
	if p == null:
		return
	var target := full_db + linear_to_db(maxf(amount, 0.0001))
	p.volume_db = move_toward(p.volume_db, target, delta * 30.0)
	p.pitch_scale = pitch_scale


func _add_layer(name: String) -> void:
	match name:
		"dread":
			var p := _looping(_cached("dread", _build_dread))
			_layers["dread"] = p
		"shimmer":
			var p := _looping(_cached("shimmer", _build_shimmer))
			_layers["shimmer"] = p
		"crackle":
			_crackle = AudioStreamPlayer.new()
			_crackle.bus = "Music"
			_crackle.stream = _cached("crackle", _build_crackle)
			add_child(_crackle)


func _looping(s: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	p.stream = s
	p.volume_db = -80.0
	add_child(p)
	p.play()
	return p


func _cached(key: String, builder: Callable) -> AudioStreamWAV:
	var k := "drone_" + key
	if not OwnerMemory.runtime_cache.has(k):
		OwnerMemory.runtime_cache[k] = builder.call()
	return OwnerMemory.runtime_cache[k]


# --- layers ------------------------------------------------------------------------

## 55 Hz against 55.75 Hz (a slow, uneasy beat) plus an octave. 4 s, every
## partial a whole number of cycles.
static func _build_hum() -> AudioStreamWAV:
	var b := Synth.begin(LOOP_SECONDS, HUM_RATE)
	Synth.tone(b, 0.0, LOOP_SECONDS, 55.0, 55.0, 0.35, Synth.Wave.SINE, 0.0, 0.0)
	Synth.tone(b, 0.0, LOOP_SECONDS, 55.75, 55.75, 0.25, Synth.Wave.SINE, 0.0, 0.0)
	Synth.tone(b, 0.0, LOOP_SECONDS, 110.25, 110.25, 0.08, Synth.Wave.SINE, 0.0, 0.0)
	Synth.normalize(b, 0.5)
	return Synth.to_wav(b, true)


## A dissonant pad: 41 Hz, its tritone 58 Hz and a sour 61.5 Hz, breathing
## once per 6 s loop.
static func _build_dread() -> AudioStreamWAV:
	var secs := 6.0
	var b := Synth.begin(secs, HUM_RATE)
	for f in [41.0, 58.0, 61.5, 82.0]:
		Synth.tone(b, 0.0, secs, f, f, 0.25, Synth.Wave.SAW, 0.0, 0.0)
	Synth.lowpass(b, 0.08)
	for i in b.size():
		b[i] *= 0.65 + 0.35 * sin(TAU * i / b.size())
	Synth.normalize(b, 0.6)
	return Synth.to_wav(b, true)


## A thin high whine (two beating sines) over band-limited hiss, trembling.
static func _build_shimmer() -> AudioStreamWAV:
	var secs := 4.0
	var b := Synth.begin(secs + 0.25, HUM_RATE)
	Synth.noise(b, 0.0, secs + 0.25, 0.25, 0.0, 0.0, 0.5, -1.0, true)
	Synth.tone(b, 0.0, secs + 0.25, 2093.0, 2093.0, 0.12, Synth.Wave.SINE, 0.0, 0.0)
	Synth.tone(b, 0.0, secs + 0.25, 2217.0, 2217.0, 0.08, Synth.Wave.SINE, 0.0, 0.0)
	Synth.loop_crossfade(b, 0.25)
	for i in b.size():
		b[i] *= 0.7 + 0.3 * sin(TAU * 2.0 * i / b.size() * secs)
	Synth.normalize(b, 0.5)
	return Synth.to_wav(b, true)


static func _build_crackle() -> AudioStreamWAV:
	var b := Synth.begin(0.12, HUM_RATE)
	var held := 0.0
	for i in b.size():
		if i % 20 == 0:
			held = randf_range(-1.0, 1.0) if randf() < 0.6 else 0.0
		b[i] = held * 0.6 * (1.0 - float(i) / b.size())
	return Synth.to_wav(b)
