class_name Drone
extends AudioStreamPlayer
## A procedural low hum. No audio assets needed.
## `tension` (0..1) detunes it and adds digital crackle.

const MIX_RATE := 22050.0

var tension := 0.0

var _playback: AudioStreamGeneratorPlayback
var _p1 := 0.0
var _p2 := 0.0
var _p3 := 0.0


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.2
	stream = gen
	volume_db = -16.0
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_delta: float) -> void:
	if _playback == null:
		return
	var f1 := 55.0 * (1.0 - tension * 0.05)
	var f2 := 55.0 * 1.012 + tension * 3.0
	var f3 := 110.3 + tension * 17.0
	for i in _playback.get_frames_available():
		_p1 = fmod(_p1 + f1 / MIX_RATE, 1.0)
		_p2 = fmod(_p2 + f2 / MIX_RATE, 1.0)
		_p3 = fmod(_p3 + f3 / MIX_RATE, 1.0)
		var s := sin(TAU * _p1) * 0.35 + sin(TAU * _p2) * 0.25 + sin(TAU * _p3) * (0.05 + tension * 0.1)
		if randf() < tension * 0.0015:
			s += randf_range(-0.7, 0.7)
		_playback.push_frame(Vector2(s, s) * 0.5)
