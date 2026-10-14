class_name Drone
extends AudioStreamPlayer
## A procedural low hum. No audio assets needed.
##
## The loop is synthesized once per run; at runtime `tension`
## (0..1) only bends its pitch and triggers digital crackle, so the audio
## costs nothing per frame.

const MIX_RATE := 22050
## Every partial completes a whole number of cycles in this time, so the loop
## is seamless.
const LOOP_SECONDS := 4.0
const PARTIALS: Array[Vector2] = [
	Vector2(55.0, 0.35),    # 220 cycles
	Vector2(55.75, 0.25),   # 223 cycles: a slow, uneasy beat against the first
	Vector2(110.25, 0.08),  # 441 cycles
]

var tension := 0.0

var _crackle: AudioStreamPlayer


func _ready() -> void:
	# Cached on the autoload so scene reloads don't re-synthesize, and so it is
	# released cleanly when the game exits.
	if not OwnerMemory.runtime_cache.has("drone_hum"):
		OwnerMemory.runtime_cache["drone_hum"] = _build_hum()
		OwnerMemory.runtime_cache["drone_crackle"] = _build_crackle()
	stream = OwnerMemory.runtime_cache["drone_hum"]
	volume_db = -16.0
	play()
	_crackle = AudioStreamPlayer.new()
	_crackle.stream = OwnerMemory.runtime_cache["drone_crackle"]
	_crackle.volume_db = -20.0
	add_child(_crackle)


func _process(delta: float) -> void:
	var pitch := 1.0 - tension * 0.06
	if not is_equal_approx(pitch, pitch_scale):
		pitch_scale = pitch
	# Crackles become more frequent as the owner gets hostile (~2 per second at max).
	if tension > 0.2 and randf() < tension * 2.0 * delta and not _crackle.playing:
		_crackle.pitch_scale = randf_range(0.6, 1.6)
		_crackle.play()


static func _build_hum() -> AudioStreamWAV:
	var count := int(MIX_RATE * LOOP_SECONDS)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / MIX_RATE
		var s := 0.0
		for p in PARTIALS:
			s += sin(TAU * p.x * t) * p.y
		data.encode_s16(i * 2, int(clampf(s * 0.5, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = count
	return wav


static func _build_crackle() -> AudioStreamWAV:
	var count := int(MIX_RATE * 0.12)
	var data := PackedByteArray()
	data.resize(count * 2)
	var held := 0.0
	for i in count:
		if i % 40 == 0:
			held = randf_range(-1.0, 1.0) if randf() < 0.6 else 0.0
		var fade := 1.0 - float(i) / count
		data.encode_s16(i * 2, int(held * fade * 0.6 * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.data = data
	return wav


func _exit_tree() -> void:
	# Stop explicitly so the audio server releases its playback on quit.
	stop()
	_crackle.stop()
