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
## Finished art for the current portrait and state (PortraitArt), or null:
## then the procedural bust is drawn.
var _art: PortraitArt.Art


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Is finished external art on screen now (rather than the drawn bust)?
func uses_external_art() -> bool:
	return _art != null


func _rebuild() -> void:
	_figure = null
	_art = PortraitArt.resolve(portrait) if portrait and CharacterArt.has_portrait(portrait.who) else null
	if portrait and CharacterArt.has_portrait(portrait.who):
		_figure = IllustratedCharacter.new(CharacterArt.kind_for(portrait.who), portrait.palette)
		_figure.leg_color = portrait.palette.get("l", _figure.leg_color)
		_figure.eye_color = portrait.palette.get("e", _figure.eye_color)
		_figure.expression = portrait.expression
		_figure.idle_style = ""
	queue_redraw()


func _process(delta: float) -> void:
	if _figure and is_visible_in_tree():
		_figure.update(delta, Vector2.ZERO)
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
	if _art:
		_draw_art()
		return
	if _figure == null:
		return
	var head_r := float(_figure.body.head)
	var k := size.x * 0.24 / head_r
	var head_y := float(PixelCharacter.FEET_Y) + _figure._head_y()
	var offset := Vector2(size.x * 0.5, size.y * 0.44 - head_y * k)
	_figure.draw(self, {"offset": offset, "scale": k})


## Finished art: the set's own frames, placed by its face anchor so every
## expression and frame sits exactly where the last one did (no jumping bust,
## no moving text). Without a talk frame the face lifts a pixel on the beat.
func _draw_art() -> void:
	var r := art_rect()
	if frame == "talk" and not _art.frames.has("talk"):
		r.position.y -= 1.0
	draw_texture_rect(_art.texture(frame), r, false)


## Where the finished art is drawn: from the set's face anchor and zoom only,
## so it is the same for every expression and frame of the set.
func art_rect() -> Rect2:
	if _art == null:
		return Rect2()
	var k := size.x * _art.zoom / float(_art.size.x)
	var dest := Vector2(_art.size) * k
	var face := Vector2(size.x * 0.5, size.y * 0.44)
	return Rect2(face - Vector2(_art.anchor.x * dest.x, _art.anchor.y * dest.y), dest)


## The texture on screen now (finished art only; null for the drawn bust).
func shown_texture() -> Texture2D:
	return _art.texture(frame) if _art else null
