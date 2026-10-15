class_name PerfOverlay
extends CanvasLayer
## Debug: frame times in the corner, so you can check performance on a real
## phone. FPS, frame time (average and worst over the last second; a smooth
## 60 fps is under 16.7 ms), and whether sounds/themes are still being built in the
## background. Also printed to the console once a second (the browser's
## console on the web build). Toggle with F3 or Pause > Debug.

var _label: Label
var _frames := 0
var _sum := 0.0
var _worst := 0.0
var _t := 0.0


func _ready() -> void:
	layer = 19
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.position = Vector2(6, 40)
	_label.add_theme_font_size_override("font_size", 9)
	_label.add_theme_color_override("font_color", Color("8cf2ff"))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 3)
	add_child(_label)


func _process(delta: float) -> void:
	var ms := delta * 1000.0
	_frames += 1
	_sum += ms
	_worst = maxf(_worst, ms)
	_t += delta
	if _t < 1.0:
		return
	var text := "FPS %d · frame %.1f ms (worst %.1f)%s" % [Engine.get_frames_per_second(), _sum / _frames, _worst,
			" · building" if Sfx.is_busy() else ""]
	_label.text = text
	print("PERF " + text)
	_frames = 0
	_sum = 0.0
	_worst = 0.0
	_t = 0.0
