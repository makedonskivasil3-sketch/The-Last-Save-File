class_name IllustratedCharacter
extends PixelCharacter
## The cast, drawn as illustrated figures (docs/VISUAL_DIRECTION.md): soft
## shapes with one dark outline, big readable heads, painted shading, drawn
## as vectors so they render at the window's resolution while the world
## keeps its 640×360 coordinates, collision boxes and speeds.
##
## Same palette keys and animation state as PixelCharacter (it extends it),
## so restoration, borrowed pieces, fraying, startle, crouch, hug, glance,
## wave and point all read the same values as before. Only the drawing is
## new. Feet still sit at y = FEET_Y in the owner's local space.

const OUTLINE := Color("1b1418")
const OUTLINE_W := 0.75

## Proportions per body (logical pixels): height, shoulder half-width, head
## radius, and what the silhouette is built from.
const BODIES := {
	"rue": {"h": 26.0, "sh": 4.6, "head": 5.4, "hair": "messy", "lower": "trousers", "scarf": true},
	"adult": {"h": 30.0, "sh": 5.4, "head": 5.4, "hair": "short", "lower": "trousers", "belt": true, "scarf": true},
	"dress": {"h": 28.0, "sh": 4.8, "head": 5.4, "hair": "long", "lower": "dress"},
	"apron": {"h": 28.0, "sh": 6.0, "head": 5.6, "hair": "bald", "lower": "trousers", "apron": true, "moustache": true},
	"child": {"h": 21.0, "sh": 3.8, "head": 5.0, "hair": "pigtails", "lower": "smock"},
	"robe": {"h": 33.0, "sh": 5.2, "head": 5.2, "hair": "elder", "lower": "robe", "beard": true, "sash": true},
	"intruder": {"h": 26.0, "sh": 4.6, "head": 5.4, "hair": "hood", "lower": "trousers"},
}

var kind := "adult"
var body: Dictionary
## The face's mood (CharacterArt.EXPRESSIONS and each character's own): ""
## is the everyday face. Portraits set it; the world figure can too.
var expression := ""

## How each mood moves the face: brows (inner, outer lift), eye size, the
## mouth's shape (-1 frown .. 1 smile; "o" open), lids (0..1 closed).
const MOODS := {
	"": {"brow": [0.0, 0.0], "eye": 1.0, "mouth": 0.0, "lids": 0.0},
	"neutral": {"brow": [0.0, 0.0], "eye": 1.0, "mouth": 0.0, "lids": 0.0},
	"concerned": {"brow": [0.8, -0.2], "eye": 1.0, "mouth": -0.4, "lids": 0.0},
	"afraid": {"brow": [1.0, 0.4], "eye": 1.3, "mouth": "o", "lids": 0.0},
	"relieved": {"brow": [0.3, 0.0], "eye": 1.0, "mouth": 0.7, "lids": 0.55},
	"determined": {"brow": [-0.8, 0.2], "eye": 0.9, "mouth": -0.1, "lids": 0.25},
	"remembering": {"brow": [0.5, 0.2], "eye": 0.95, "mouth": 0.25, "lids": 0.45, "look_up": true},
	"eager": {"brow": [0.4, 0.5], "eye": 1.15, "mouth": 0.9, "lids": 0.0},
	"proud": {"brow": [-0.2, 0.3], "eye": 1.0, "mouth": 0.8, "lids": 0.35},
	"reset": {"brow": [0.0, 0.0], "eye": 1.0, "mouth": 0.6, "lids": 0.0, "blank": true},
	"brave": {"brow": [-0.6, 0.1], "eye": 1.05, "mouth": 0.2, "lids": 0.1},
	"awed": {"brow": [0.7, 0.6], "eye": 1.25, "mouth": "o", "lids": 0.0, "look_up": true},
}


func _init(k: String, colours: Dictionary) -> void:
	super(k, colours)
	kind = k if BODIES.has(k) else "adult"
	body = BODIES[kind]


func height() -> int:
	return int(body.h)


func eye_position() -> Vector2:
	return Vector2(0, FEET_Y + _head_y())


func _head_y() -> float:
	return -float(body.h) + float(body.head) + 0.5


# --- colours ------------------------------------------------------------------------

func _c(key: String, fallback: Color) -> Color:
	var c: Variant = palette.get(key)
	return c if c is Color else fallback


func _face_missing() -> bool:
	return _c("s", Color("f0c49c")).get_luminance() < 0.2


## Applies the draw options: a single-colour silhouette, greyed, faded.
func _paint(c: Color, solid: Variant, grey: bool, alpha: float) -> Color:
	if solid is Color:
		return Color(solid.r, solid.g, solid.b, solid.a * alpha)
	if grey:
		var l := c.get_luminance()
		c = Color(l, l, l, c.a).lerp(c, 0.15)
	return Color(c, c.a * alpha)


# --- the figure ---------------------------------------------------------------------

## opts as PixelCharacter.draw: offset, alpha, solid, grey, slices.
func draw(ci: CanvasItem, opts: Dictionary = {}) -> void:
	var offset: Vector2 = opts.get("offset", Vector2.ZERO)
	var alpha: float = opts.get("alpha", 1.0)
	var solid: Variant = opts.get("solid", null)
	var grey: bool = opts.get("grey", false)
	var slices: Array = opts.get("slices", [0.0, 0.0, 0.0])
	var side := facing.x != 0.0
	var flip := -1.0 if facing.x < 0.0 else 1.0
	var k: float = opts.get("scale", 1.0)
	var rot: float = opts.get("rotation", 0.0)
	# A turn squeezes the figure through its middle; a stop settles it down
	# and back up (scales about the feet, so it stays standing where it is).
	var squeeze := 1.0 - 0.28 * sin(clampf(turn / TURN_TIME, 0.0, 1.0) * PI)
	var sink := sin(clampf(settle / SETTLE_TIME, 0.0, 1.0) * PI) * 0.06
	ci.draw_set_transform(offset + Vector2(0, FEET_Y).rotated(rot) * k, rot, Vector2(flip * squeeze * (1.0 + sink * 0.5), 1.0 - sink) * k)
	if solid == null and alpha > 0.5:
		_shadow(ci, alpha)
	# Motion, eased: a step bounce, a breath, a hop, a sway, a shiver.
	var step := floori(_walk * 2.0) % 4 if moving else 0
	var phase := sin(_walk * PI) if moving else 0.0
	var bounce := -absf(sin(_walk * PI)) * 0.9 if moving else 0.0
	var breath := sin(_t * TAU / 2.4) * 0.35 if not moving else 0.0
	var hop_y := -sin(minf(_hop / 0.45, 1.0) * PI) * 3.0 if _hop > 0.0 else 0.0
	var sway := sin(_t * 1.4) * 0.6 if idle_style == "sway" and not moving else 0.0
	var dy := bounce + hop_y + (1.5 if crouch else 0.0)
	if shiver and not moving:
		sway += float(floori(_t * 30.0) % 2) * 0.4 - 0.2
	var s_head := float(slices[0]) * flip
	var s_body := float(slices[1]) * flip
	var s_legs := float(slices[2]) * flip
	var parts := _Parts.new(self, ci, solid, grey, alpha)
	_legs(parts, Vector2(s_legs, dy * 0.4), phase, side)
	_torso(parts, Vector2(s_body, dy), phase, side, step)
	_head(parts, Vector2(s_head + sway, dy + breath), side)
	parts.flush()
	if solid == null and not (facing == Vector2.UP):
		_face(ci, Vector2(s_head + sway, dy + breath), side, alpha, grey)
	if idle_style == "read" and not moving and solid == null:
		_book(ci, Vector2(s_body, dy), alpha)
	ci.draw_set_transform(Vector2.ZERO)


func _shadow(ci: CanvasItem, alpha: float) -> void:
	var w := float(body.sh) + 1.5
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(Vector2(cos(a) * w, sin(a) * 1.6 + 0.3))
	ci.draw_colored_polygon(pts, Color(0, 0, 0, 0.3 * alpha))


func _legs(p: _Parts, o: Vector2, phase: float, side: bool) -> void:
	var h := float(body.h)
	var hip := -h * 0.36 + o.y
	var lower: String = body.lower
	var leg := leg_color
	var shoe := shoe_color
	var spread := 1.6 if not side else 0.6
	var swing := phase * (2.4 if side else 1.0)
	if lower in ["dress", "robe"]:
		# Feet peek out under the hem.
		var hem := 0.0 if lower == "robe" else -2.2
		p.ellipse(Vector2(-1.8 + swing * 0.5 + o.x, -0.4), Vector2(1.6, 1.0), shoe)
		p.ellipse(Vector2(1.8 - swing * 0.5 + o.x, -0.4), Vector2(1.6, 1.0), shoe)
		if lower == "dress":
			p.capsule(Vector2(-1.5 + o.x, hem), Vector2(-1.6 + swing * 0.5 + o.x, -1.0), 0.9, _c("s", Color("f0c49c")))
			p.capsule(Vector2(1.5 + o.x, hem), Vector2(1.6 - swing * 0.5 + o.x, -1.0), 0.9, _c("s", Color("f0c49c")))
		return
	if lower == "smock":
		leg = _c("s", Color("f0c49c"))
	for side_i: float in [-1.0, 1.0]:
		var lift := maxf(0.0, phase * side_i) * 1.2
		var top := Vector2(side_i * spread + o.x, hip)
		var foot := Vector2(side_i * spread + swing * side_i + o.x, -0.6 - lift)
		p.capsule(top, foot, 1.25 if kind != "child" else 1.0, leg)
		p.ellipse(foot + Vector2(0.4 if side else 0.0, 0.3), Vector2(1.6 if side else 1.4, 0.9), shoe)


func _torso(p: _Parts, o: Vector2, phase: float, side: bool, _step: int) -> void:
	var h := float(body.h)
	var sh := float(body.sh) * (0.72 if side else 1.0)
	var top := -h + float(body.head) * 2.0 - 0.2 + o.y
	var hip := -h * 0.36 + o.y
	var clothes := _c("c", Color("6a6a7a"))
	var dark := _c("d", clothes.darkened(0.3))
	var lower: String = body.lower
	var bottom := hip + 0.8
	var flare := 0.4
	match lower:
		"dress":
			bottom = -2.2
			flare = 2.4
		"robe":
			bottom = -0.6
			flare = 1.6
		"smock":
			bottom = hip + 2.0
			flare = 1.2
	var x := o.x
	var body_pts := PackedVector2Array([
		Vector2(x - sh, top + 1.2), Vector2(x - sh + 0.8, top), Vector2(x + sh - 0.8, top), Vector2(x + sh, top + 1.2),
		Vector2(x + sh * 0.86 + flare, bottom), Vector2(x - sh * 0.86 - flare, bottom),
	])
	p.poly(body_pts, clothes)
	# Painted shade down the side away from the light (upper left).
	p.poly(PackedVector2Array([Vector2(x + sh * 0.35, top + 0.4), Vector2(x + sh - 0.6, top + 0.2), Vector2(x + sh, top + 1.2),
		Vector2(x + sh * 0.86 + flare, bottom), Vector2(x + sh * 0.3 + flare * 0.5, bottom)]), Color(dark, 0.55), false)
	if body.get("apron", false):
		var w := _c("w", Color("efe6d6"))
		p.poly(PackedVector2Array([Vector2(x - sh * 0.62, top + 3.0), Vector2(x + sh * 0.62, top + 3.0),
			Vector2(x + sh * 0.7, bottom - 0.2), Vector2(x - sh * 0.7, bottom - 0.2)]), w, false)
		p.rect(Rect2(x - 1.4, top + 5.5, 2.8, 1.8), w.darkened(0.12), false)
	if body.get("belt", false):
		p.rect(Rect2(x - sh * 0.9, hip - 1.0, sh * 1.8, 1.2), _c("a", dark), false)
	if body.get("sash", false):
		p.poly(PackedVector2Array([Vector2(x - sh * 0.8, top + 2.0), Vector2(x - sh * 0.4, top + 1.2),
			Vector2(x + sh * 0.8, hip - 0.4), Vector2(x + sh * 0.5, hip + 0.8)]), _c("a", Color("8a3a3a")), false)
	if kind == "rue":
		# Raincoat: a seam and two pockets.
		p.line(Vector2(x + 0.3, top + 2.0), Vector2(x + 0.3, bottom - 0.4), dark, 0.45)
		p.rect(Rect2(x - sh * 0.75, hip - 3.2, 1.8, 1.4), dark, false)
		p.rect(Rect2(x + sh * 0.75 - 1.8, hip - 3.2, 1.8, 1.4), dark, false)
	if lower == "dress":
		p.line(Vector2(x - sh * 0.86 - flare + 0.6, bottom - 0.7), Vector2(x + sh * 0.86 + flare - 0.6, bottom - 0.7), dark, 0.7)
	_arms(p, Vector2(x, top), sh, phase, side)
	if body.get("scarf", false):
		_scarf(p, Vector2(x, top), sh, phase, side)


func _arms(p: _Parts, shoulder: Vector2, sh: float, phase: float, side: bool) -> void:
	var clothes := _c("c", Color("6a6a7a"))
	var skin := _c("s", Color("f0c49c"))
	var h := float(body.h)
	var arm_len := h * 0.28
	for s: float in [-1.0, 1.0]:
		if side and s < 0.0:
			continue  # the far arm hides behind the body in profile
		var at := shoulder + Vector2(s * (sh - 0.4), 1.4)
		var hand := at + Vector2(s * 0.8, arm_len)
		if moving:
			hand.x += -phase * s * (2.2 if side else 0.8)
			if side:
				hand.x = at.x + phase * 2.6
		if hug and not moving:
			hand = shoulder + Vector2(-s * sh * 0.4, arm_len * 0.55)
		if waving and s > 0.0:
			hand = at + Vector2(2.4, -arm_len * 0.8 + absf(sin(_t * 8.0)) * 1.5)
		if pointing and s > 0.0:
			hand = at + Vector2(arm_len * 0.95, 0.4)
		p.capsule(at, hand, 1.15, clothes)
		p.circle(hand, 1.05, skin)


func _scarf(p: _Parts, neck: Vector2, sh: float, phase: float, side: bool) -> void:
	var a := _c("a", Color("d8463a"))
	p.poly(PackedVector2Array([Vector2(neck.x - sh * 0.7, neck.y - 0.6), Vector2(neck.x + sh * 0.7, neck.y - 0.6),
		Vector2(neck.x + sh * 0.6, neck.y + 1.5), Vector2(neck.x - sh * 0.6, neck.y + 1.5)]), a)
	# The loose end: hangs in front, trails behind when she walks sideways.
	var flutter := sin(_t * 9.0) * 0.6 if moving else sin(_t * 1.6) * 0.2
	var root := Vector2(neck.x + (sh * 0.3 if not side else -sh * 0.3), neck.y + 1.0)
	var tip := root + (Vector2(-5.0 - absf(phase) * 1.5, 1.2 + flutter) if side and moving else Vector2(0.4, 5.0 + flutter))
	p.capsule(root, tip, 0.95, a.darkened(0.08))


func _head(p: _Parts, o: Vector2, side: bool) -> void:
	var r := float(body.head)
	var c := Vector2(o.x + (0.6 if side else 0.0), _head_y() + o.y)
	var hair := _c("h", Color("5a3a2a"))
	var skin := _c("s", Color("f0c49c"))
	var back := facing == Vector2.UP
	var style: String = body.hair
	# Hair behind the head first (long hair, pigtails, the elder's mane).
	match style:
		"long":
			p.poly(PackedVector2Array([Vector2(c.x - r - 0.6, c.y - 1.0), Vector2(c.x + r + 0.6, c.y - 1.0),
				Vector2(c.x + r + 1.0, c.y + r + 4.5), Vector2(c.x - r - 1.0, c.y + r + 4.5)]), hair)
		"pigtails":
			for s: float in [-1.0, 1.0]:
				if side and s < 0.0:
					continue
				var tail := c + Vector2(s * (r + 1.6), 1.4)
				p.ellipse(tail, Vector2(1.5, 2.6), hair)
				p.circle(tail + Vector2(0, -2.2), 1.0, _c("a", Color("e8c48a")))  # the ribbon
		"elder":
			p.ellipse(c + Vector2(0, 0.6), Vector2(r + 0.8, r + 0.6), hair)
	if style == "hood":
		p.circle(c, r + 1.2, _c("g", _c("h", Color("3fa6b8"))))
		p.ellipse(c + Vector2(0.4 if side else 0.0, 0.6), Vector2(r - 1.2, r - 0.8), Color("05070a"), false)
		return
	p.circle(c, r, skin if not back or style == "bald" else hair)
	if back:
		if style == "bald":
			# Bald on every view: hair is a rim, never a full cap.
			p.ellipse(c + Vector2(-r + 0.7, 0.6), Vector2(1.0, 2.0), hair)
			p.ellipse(c + Vector2(r - 0.7, 0.6), Vector2(1.0, 2.0), hair)
		if style == "messy":
			p.poly(PackedVector2Array([c + Vector2(0.4, -r - 2.6), c + Vector2(-0.8, -r + 0.2), c + Vector2(1.4, -r + 0.2)]), hair)
		return
	# Hair on top: a cap with a shape that says who it is.
	match style:
		"messy":
			p.poly(_cap(c, r, 0.2), hair)
			p.poly(PackedVector2Array([c + Vector2(0.4, -r - 2.6), c + Vector2(-0.8, -r + 0.2), c + Vector2(1.4, -r + 0.2)]), hair)  # the cowlick
			p.poly(PackedVector2Array([c + Vector2(-r, -0.6), c + Vector2(-r + 1.0, -2.6), c + Vector2(-r + 2.0, -0.2)]), hair, false)
		"short":
			p.poly(_cap(c, r, 0.0), hair)
		"long":
			p.poly(_cap(c, r, 0.6), hair)
		"pigtails":
			p.poly(_cap(c, r, 0.4), hair)
		"bald":
			p.poly(PackedVector2Array([c + Vector2(-r - 0.3, 0.4), c + Vector2(-r + 0.6, -2.4), c + Vector2(-r + 2.2, -1.6), c + Vector2(-r + 1.2, 1.4)]), hair)
			p.poly(PackedVector2Array([c + Vector2(r + 0.3, 0.4), c + Vector2(r - 0.6, -2.4), c + Vector2(r - 2.2, -1.6), c + Vector2(r - 1.2, 1.4)]), hair)
		"elder":
			p.poly(_cap(c, r, -0.6), hair)
	if body.get("beard", false):
		p.poly(PackedVector2Array([c + Vector2(-r + 0.8, 1.2), c + Vector2(r - 0.8, 1.2), c + Vector2(r * 0.5, r + 4.2), c + Vector2(0, r + 5.2), c + Vector2(-r * 0.5, r + 4.2)]), hair)
	if body.get("moustache", false):
		p.ellipse(c + Vector2(0.3 if side else 0.0, 1.9), Vector2(2.2, 0.7), hair.darkened(0.1), false)


## The top of a head of hair: from ear to ear over the crown, down to `fringe`.
func _cap(c: Vector2, r: float, fringe: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		pts.append(c + Vector2(cos(a) * (r + 0.5), sin(a) * (r + 0.6)))
	pts.append(c + Vector2(r * 0.7, -1.2 + fringe))
	pts.append(c + Vector2(0.0, -2.0 + fringe))
	pts.append(c + Vector2(-r * 0.7, -1.2 + fringe))
	return pts


func _face(ci: CanvasItem, o: Vector2, side: bool, alpha: float, grey: bool) -> void:
	var c := Vector2(o.x + (0.6 if side else 0.0), _head_y() + o.y)
	var missing := _face_missing()
	var eye := _paint(eye_color, null, grey, alpha)
	var mood: Dictionary = MOODS.get(expression, MOODS[""])
	var look := Vector2(float(glance) * 0.6, -0.4 if mood.get("look_up", false) else 0.0)
	var eyes: Array = [Vector2(2.1, 0.2)] if side else [Vector2(-1.9, 0.2), Vector2(1.9, 0.2)]
	var wide := startled > 0.0
	var size := float(mood.eye) * (1.25 if wide else 1.0)
	var lids := float(mood.lids)
	for e: Vector2 in eyes:
		var at := c + e + look
		if missing:
			# No face: two points of light.
			Decor.disc(ci, at, 0.95, Color(eye, 0.35 * alpha))
			Decor.disc(ci, at, 0.55, eye)
			continue
		if _blink > 0.0 or lids >= 0.95:
			ci.draw_line(at + Vector2(-0.9, 0), at + Vector2(0.9, 0), eye, 0.5)
			continue
		var rx := 0.75 * size
		var ry := 1.05 * size * (1.0 - lids * 0.55)
		_ellipse(ci, at + Vector2(0, lids * 0.35), Vector2(rx, ry), eye)
		if not mood.get("blank", false):
			Decor.disc(ci, at + Vector2(-0.25, -0.4 + lids * 0.3), 0.28, Color(1, 1, 1, 0.9 * alpha))
		# Brows: inner and outer ends lift or drop with the mood.
		var b: Array = mood.brow
		var inward := -signf(e.x) if not side else -1.0
		var inner := at + Vector2(inward * 0.7, -1.9 - float(b[0]) * 0.5)
		var outer := at + Vector2(-inward * 0.9, -1.8 - float(b[1]) * 0.5)
		ci.draw_line(inner, outer, _paint(_c("h", Color("5a3a2a")).darkened(0.25), null, grey, alpha), 0.45)
	if missing or kind == "intruder":
		return
	var skin := _c("s", Color("f0c49c"))
	var mouth := _paint(skin.darkened(0.45).lerp(Color("9a3a30"), 0.4), null, grey, alpha)
	var m := c + Vector2(0.9 if side else 0.0, 2.6)
	var shape: Variant = mood.mouth
	if talking and fmod(_t, 0.24) < 0.12:
		_ellipse(ci, m, Vector2(0.7, 0.55), mouth)
	elif wide or shape is String:
		_ellipse(ci, m, Vector2(0.45, 0.6), mouth)
	else:
		var curve := float(shape)
		ci.draw_polyline(PackedVector2Array([m + Vector2(-0.8, -curve * 0.3), m + Vector2(0, curve * 0.25), m + Vector2(0.8, -curve * 0.3)]), mouth, 0.45)
	# A touch of colour on the cheeks.
	var blush := _paint(skin.lerp(Color("e07a6a"), 0.35), null, grey, alpha * 0.55)
	if not side:
		_ellipse(ci, c + Vector2(-2.9, 1.6), Vector2(0.9, 0.5), blush)
		_ellipse(ci, c + Vector2(2.9, 1.6), Vector2(0.9, 0.5), blush)


func _book(ci: CanvasItem, o: Vector2, alpha: float) -> void:
	var at := Vector2(o.x, -float(body.h) * 0.5 + o.y)
	ci.draw_rect(Rect2(at + Vector2(-2.4, -1.2), Vector2(4.8, 3.0)), Color(Color("6b3a2c"), alpha))
	ci.draw_rect(Rect2(at + Vector2(-2.0, -0.9), Vector2(1.8, 2.4)), Color(Color("e8dcc4"), alpha))
	ci.draw_rect(Rect2(at + Vector2(0.2, -0.9), Vector2(1.8, 2.4)), Color(Color("e8dcc4"), alpha))


static func _ellipse(ci: CanvasItem, c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	ci.draw_colored_polygon(pts, col)


## Collects a figure's shapes so its outline is drawn once, behind all of
## them (one clean silhouette line), then the fills in order.
class _Parts:
	extends RefCounted
	var _ch: IllustratedCharacter
	var _ci: CanvasItem
	var _solid: Variant
	var _grey: bool
	var _alpha: float
	var _shapes: Array = []

	func _init(ch: IllustratedCharacter, ci: CanvasItem, solid: Variant, grey: bool, alpha: float) -> void:
		_ch = ch
		_ci = ci
		_solid = solid
		_grey = grey
		_alpha = alpha

	func poly(pts: PackedVector2Array, c: Color, outline := true) -> void:
		_shapes.append(["poly", pts, c, outline])

	func circle(at: Vector2, r: float, c: Color, outline := true) -> void:
		_shapes.append(["ellipse", at, Vector2(r, r), c, outline])

	func ellipse(at: Vector2, r: Vector2, c: Color, outline := true) -> void:
		_shapes.append(["ellipse", at, r, c, outline])

	func rect(r: Rect2, c: Color, outline := true) -> void:
		poly(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), c, outline)

	func capsule(a: Vector2, b: Vector2, r: float, c: Color, outline := true) -> void:
		_shapes.append(["capsule", a, b, r, c, outline])

	func line(a: Vector2, b: Vector2, c: Color, w: float) -> void:
		_shapes.append(["line", a, b, c, w])

	func flush() -> void:
		if _solid == null:
			var ol := _ch._paint(OUTLINE, null, false, _alpha)
			for s in _shapes:
				if s[0] != "line" and s[s.size() - 1]:
					_draw(s, ol, OUTLINE_W)
		for s in _shapes:
			var c: Color
			match s[0]:
				"poly":
					c = s[2]
				"ellipse":
					c = s[3]
				"capsule":
					c = s[4]
				"line":
					c = s[3]
			_draw(s, _ch._paint(c, _solid, _grey, _alpha), 0.0)

	func _draw(s: Array, c: Color, grow: float) -> void:
		match s[0]:
			"poly":
				var pts: PackedVector2Array = s[1]
				if grow > 0.0:
					pts = _grown(pts, grow)
				if pts.size() >= 3:
					_ci.draw_colored_polygon(pts, c)
			"ellipse":
				IllustratedCharacter._ellipse(_ci, s[1], s[2] + Vector2(grow, grow), c)
			"capsule":
				var a: Vector2 = s[1]
				var b: Vector2 = s[2]
				var r: float = float(s[3]) + grow
				Decor.disc(_ci, a, r, c, 8)
				Decor.disc(_ci, b, r, c, 8)
				var n := (b - a).normalized().orthogonal() * r
				if (b - a).length() > 0.01:
					_ci.draw_colored_polygon(PackedVector2Array([a + n, b + n, b - n, a - n]), c)
			"line":
				_ci.draw_line(s[1], s[2], c, s[4])

	## A polygon pushed outward from its centre by `d` (an outline behind it).
	static func _grown(pts: PackedVector2Array, d: float) -> PackedVector2Array:
		var centre := Vector2.ZERO
		for q in pts:
			centre += q
		centre /= pts.size()
		var out := PackedVector2Array()
		for q in pts:
			var dir := q - centre
			out.append(q + (dir.normalized() * d if dir.length() > 0.001 else Vector2.ZERO))
		return out
