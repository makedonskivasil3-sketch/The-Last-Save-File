class_name PortraitView
extends Control
## A character's portrait: the same illustrated figure as in the world
## (IllustratedCharacter), framed as a bust, in their current palette and
## mood (docs/VISUAL_DIRECTION.md). Because it is drawn from the same body
## and the same colours, the face in the box is always the face on screen:
## restored, frayed or borrowed.

## Who and how they look (CharacterArt.Portrait), or null for none.
var portrait: CharacterArt.Portrait:
	set(p):
		portrait = p
		_rebuild()
## "" still, "talk" (the mouth moves) or "blink".
var frame := "":
	set(f):
		frame = f
		if _figure:
			_figure.talking = f == "talk"
			_figure._blink = 0.12 if f == "blink" else 0.0
		queue_redraw()
## The backdrop's tint (the speaker's colour).
var tint := Color("8a7a9a")

var _figure: IllustratedCharacter


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _rebuild() -> void:
	_figure = null
	if portrait and CharacterArt.has_portrait(portrait.who):
		_figure = IllustratedCharacter.new(CharacterArt.kind_for(portrait.who), portrait.palette)
		_figure.leg_color = portrait.palette.get("l", _figure.leg_color)
		_figure.eye_color = portrait.palette.get("e", _figure.eye_color)
		_figure.expression = portrait.expression
		_figure.idle_style = ""
	queue_redraw()


func _process(_delta: float) -> void:
	if _figure and visible:
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(tint.darkened(0.72), 0.95)
	bg.set_corner_radius_all(4)
	bg.border_color = Color(tint, 0.55)
	bg.set_border_width_all(1)
	bg.anti_aliasing = true
	draw_style_box(bg, r)
	# A soft light behind the head.
	draw_circle(Vector2(size.x * 0.5, size.y * 0.4), size.x * 0.34, Color(tint, 0.16))
	if _figure == null:
		return
	var head_r := float(_figure.body.head)
	var k := size.x * 0.24 / head_r
	var head_y := float(PixelCharacter.FEET_Y) + _figure._head_y()
	var offset := Vector2(size.x * 0.5, size.y * 0.44 - head_y * k)
	_figure.draw(self, {"offset": offset, "scale": k})
