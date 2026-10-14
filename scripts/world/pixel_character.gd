class_name PixelCharacter
extends RefCounted
## Code-drawn pixel-art characters with simple animation. No image assets:
## each body is an 8-pixel-wide template of palette keys, and legs, eyes,
## mouth, arms and accessories are drawn on top so they can animate.
##
## Owned by a node (Player, Npc, OwnerAvatar): call update() in _process and
## draw() in _draw. Feet sit at y = +6 in the owner's local space, matching
## the 8x8 collision boxes used everywhere.
##
## Palette keys: h hair, s skin, c clothes, d clothes dark, a accent,
## w white/apron, g hood, v void (the intruder's face), . transparent.

const FEET_Y := 6
## Each template pixel is drawn as SCALE x SCALE game pixels: chunky enough to
## read through the CRT effects, while collision stays the small 8x8 box.
const SCALE := 2
const TEMPLATES := {
	# Arin: tunic and trousers.
	"adult": {
		"rows": ["..hhhh..", ".hhhhhh.", ".hssssh.", ".hssssh.", "..ssss..", "..cccc..", ".cccccc.", "sccaaccs", ".cccccc.", ".dddddd."],
		"eye_row": 3, "mouth_row": 4, "head_rows": 5, "arm_row": 7, "legs": "trousers",
	},
	# Mira: long hair and a dress.
	"dress": {
		"rows": ["..hhhh..", ".hhhhhh.", "hhsssshh", "hhsssshh", "h.ssss.h", "..cccc..", ".cccccc.", "sccccccs", ".cccccc.", "cccccccc"],
		"eye_row": 3, "mouth_row": 4, "head_rows": 5, "arm_row": 7, "legs": "bare",
	},
	# Tobben: bald on top, moustache, shopkeeper's apron.
	"apron": {
		"rows": ["..hhhh..", ".hsssshh", ".ssssss.", ".ssssss.", "..saas..", ".cccccc.", "ccwwwwcc", "scwwwwcs", ".cwwwwc.", ".dwwwwd."],
		"eye_row": 3, "mouth_row": 4, "head_rows": 5, "arm_row": 7, "legs": "trousers",
	},
	# Wren: a child with pigtails.
	"child": {
		"rows": ["..hhhh..", ".hhhhhh.", "hhsssshh", "h.ssss.h", "..cccc..", ".cccccc.", "s.cccc.s", "..dddd.."],
		"eye_row": 3, "mouth_row": 3, "head_rows": 4, "arm_row": 6, "legs": "bare",
	},
	# The Archivist: tall, white beard, a robe to the floor.
	"robe": {
		"rows": ["..hhhh..", ".hhhhhh.", ".hssssh.", ".hssssh.", ".hhsshh.", "..hhhh..", ".cccccc.", "cccccccc", "sccaaccs", ".cccccc.", ".cccccc.", ".dddddd.", "dddddddd"],
		"eye_row": 3, "mouth_row": 4, "head_rows": 6, "arm_row": 8, "legs": "feet",
	},
	# You: a hood around nothing, two points of light.
	"intruder": {
		"rows": ["..gggg..", ".gggggg.", ".gvvvvg.", ".gvvvvg.", ".gvvvvg.", "..gccg..", ".cccccc.", "c.cccc.c", ".cccccc.", "..cccc.."],
		"eye_row": 3, "mouth_row": -1, "head_rows": 5, "arm_row": 7, "legs": "trousers",
	},
}

var template: Dictionary
var palette: Dictionary = {}
var leg_color := Color("3a3040")
var shoe_color := Color("221c22")
var eye_color := Color("1a0c0c")

## Animation state.
var facing := Vector2.DOWN
var moving := false
var talking := false
## "", "sway", "hop", "wave", "read".
var idle_style := ""
## Wave/raise one arm (Tobben greeting, Arin pointing).
var waving := false

var _t := randf() * 10.0
var _walk := 0.0
var _blink := 0.0
var _blink_timer := randf_range(1.0, 4.0)
var _hop := 0.0
var _hop_timer := randf_range(2.0, 5.0)


func _init(kind: String, colours: Dictionary) -> void:
	template = TEMPLATES.get(kind, TEMPLATES["adult"])
	palette = colours
	leg_color = colours.get("l", leg_color)
	shoe_color = colours.get("f", shoe_color)
	eye_color = colours.get("e", eye_color)


## Height in game pixels (feet at FEET_Y, top at FEET_Y - height()).
func height() -> int:
	return (template.rows.size() + 2) * SCALE


## Where the eyes are, in the owner's local space.
func eye_position() -> Vector2:
	return Vector2(0, FEET_Y - height() + (template.eye_row + 0.5) * SCALE)


## Advance animation. `velocity` in px/s; zero means standing.
func update(delta: float, velocity: Vector2) -> void:
	_t += delta
	moving = velocity.length() > 2.0
	if moving:
		_walk += delta * clampf(velocity.length() / 9.0, 3.0, 9.0)
		if absf(velocity.x) > absf(velocity.y):
			facing = Vector2.RIGHT if velocity.x > 0.0 else Vector2.LEFT
		else:
			facing = Vector2.DOWN if velocity.y > 0.0 else Vector2.UP
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink = 0.13
		_blink_timer = randf_range(1.8, 5.0)
	_blink = maxf(0.0, _blink - delta)
	if idle_style == "hop" and not moving:
		_hop_timer -= delta
		if _hop_timer <= 0.0:
			_hop = 0.45
			_hop_timer = randf_range(2.5, 6.0)
	_hop = maxf(0.0, _hop - delta)


## Current walk frame 0..3 (1 and 3 are the steps); 0 when standing.
func step_frame() -> int:
	return floori(_walk * 2.0) % 4 if moving else 0


## Turn to face a point (used by NPCs watching you).
func look_at(from: Vector2, to: Vector2) -> void:
	var d := to - from
	if d.length() < 1.0:
		return
	if absf(d.x) > absf(d.y) * 1.2:
		facing = Vector2.RIGHT if d.x > 0.0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if d.y > 0.0 else Vector2.UP


## Draw the character.
##   offset: Vector2       where (feet centre is at offset + (0, 6))
##   alpha: float
##   solid: Color          draw as a single-colour silhouette (ghosts, flashes)
##   grey: bool            desaturated (restricted NPCs)
##   slices: Array         x-offsets for [head, body, legs] (glitch tearing)
func draw(ci: CanvasItem, opts: Dictionary = {}) -> void:
	var offset: Vector2 = opts.get("offset", Vector2.ZERO)
	var alpha: float = opts.get("alpha", 1.0)
	var solid: Variant = opts.get("solid", null)
	var grey: bool = opts.get("grey", false)
	var slices: Array = opts.get("slices", [0.0, 0.0, 0.0])
	var rows: Array = template.rows
	# Everything below is in template pixels with the feet at y = 0; the
	# canvas transform scales it up and places it.
	ci.draw_set_transform(offset + Vector2(0, FEET_Y), 0.0, Vector2(SCALE, SCALE))
	var top := -float(rows.size() + 2)
	var head_rows: int = template.head_rows
	var back := facing == Vector2.UP

	# Idle motion: breathing head-bob, a hop, a sway.
	var breath := 1.0 if fmod(_t, 1.8) < 0.35 and not moving else 0.0
	var step := floori(_walk * 2.0) % 4 if moving else 0
	var bounce := -1.0 if moving and (step == 1 or step == 3) else 0.0
	var hop := -roundf(sin(_hop / 0.45 * PI) * 3.0) if _hop > 0.0 else 0.0
	var sway := roundf(sin(_t * 1.4) * 0.6) if idle_style == "sway" and not moving else 0.0
	var base := Vector2(-4, top + bounce + hop)

	for r in rows.size():
		var line: String = rows[r]
		var is_head := r < head_rows
		var row_off := Vector2(sway if is_head else 0.0, breath if is_head else 0.0)
		row_off.x += float(slices[0] if is_head else slices[1]) / SCALE
		var x := 0
		while x < 8:
			var key := line[x]
			if key == ".":
				x += 1
				continue
			# Back view: the face becomes the back of the head.
			if back and is_head and key == "s":
				key = "h"
			# Arms swing while walking; one arm raised when waving.
			var arm_dy := 0.0
			if r == template.arm_row and (x == 0 or x == 7) and key == "s":
				if moving:
					arm_dy = (1.0 if (step < 2) == (x == 0) else -1.0)
				if waving and x == 7:
					arm_dy = -3.0 - roundf(absf(sin(_t * 8.0)) * 2.0)
				_px(ci, base + row_off + Vector2(x, r + arm_dy), 1, key, solid, grey, alpha)
				x += 1
				continue
			# Merge horizontal runs of the same key into one rect.
			var run := 1
			while x + run < 8 and line[x + run] == key and not (r == template.arm_row and x + run == 7):
				run += 1
			_px(ci, base + row_off + Vector2(x, r), run, key, solid, grey, alpha)
			x += run

	_draw_legs(ci, base + Vector2(float(slices[2]) / SCALE, rows.size()), step, solid, grey, alpha)
	if solid == null and not back:
		_draw_face(ci, base + Vector2(sway + float(slices[0]) / SCALE, breath), alpha, grey)
	if idle_style == "read" and not moving and solid == null:
		_draw_book(ci, base + Vector2(0, template.arm_row), alpha)
	ci.draw_set_transform(Vector2.ZERO)


func _draw_legs(ci: CanvasItem, at: Vector2, step: int, solid: Variant, grey: bool, alpha: float) -> void:
	var legs: String = template.legs
	var lc: Color = leg_color if legs == "trousers" else palette.get("s", leg_color)
	# Step frames: 0 stand, 1 left up, 2 stand, 3 right up.
	var left_up := 1.0 if step == 1 else 0.0
	var right_up := 1.0 if step == 3 else 0.0
	if legs == "feet":
		_rect(ci, Rect2(at + Vector2(1 + (1 if step == 1 else 0), 0), Vector2(2, 1)), shoe_color, solid, grey, alpha)
		_rect(ci, Rect2(at + Vector2(5 - (1 if step == 3 else 0), 0), Vector2(2, 1)), shoe_color, solid, grey, alpha)
		return
	_rect(ci, Rect2(at + Vector2(2, -left_up), Vector2(2, 1)), lc, solid, grey, alpha)
	_rect(ci, Rect2(at + Vector2(4, -right_up), Vector2(2, 1)), lc, solid, grey, alpha)
	_rect(ci, Rect2(at + Vector2(2, 1 - left_up), Vector2(2, 1)), shoe_color, solid, grey, alpha)
	_rect(ci, Rect2(at + Vector2(4, 1 - right_up), Vector2(2, 1)), shoe_color, solid, grey, alpha)


func _draw_face(ci: CanvasItem, base: Vector2, alpha: float, grey: bool) -> void:
	var er: int = template.eye_row
	var eye := eye_color if not grey else Color(0.25, 0.25, 0.25)
	if _blink <= 0.0:
		match facing:
			Vector2.LEFT:
				ci.draw_rect(Rect2(base + Vector2(2, er), Vector2(1, 1)), Color(eye, alpha))
			Vector2.RIGHT:
				ci.draw_rect(Rect2(base + Vector2(5, er), Vector2(1, 1)), Color(eye, alpha))
			_:
				ci.draw_rect(Rect2(base + Vector2(2, er), Vector2(1, 1)), Color(eye, alpha))
				ci.draw_rect(Rect2(base + Vector2(5, er), Vector2(1, 1)), Color(eye, alpha))
	var mr: int = template.mouth_row
	if mr >= 0 and talking and fmod(_t, 0.24) < 0.12:
		var mx := 3.0 if facing == Vector2.DOWN else (2.0 if facing == Vector2.LEFT else 4.0)
		ci.draw_rect(Rect2(base + Vector2(mx, mr), Vector2(2 if facing == Vector2.DOWN else 1, 1)), Color(0.25, 0.08, 0.08, alpha))


func _draw_book(ci: CanvasItem, at: Vector2, alpha: float) -> void:
	# Held open; a page flips every few seconds.
	ci.draw_rect(Rect2(at + Vector2(1, -1), Vector2(6, 3)), Color(0.42, 0.23, 0.17, alpha))
	ci.draw_rect(Rect2(at + Vector2(2, -1), Vector2(4, 2)), Color(0.85, 0.8, 0.7, alpha))
	if fmod(_t, 3.0) < 0.25:
		ci.draw_rect(Rect2(at + Vector2(4 - roundf(fmod(_t, 3.0) * 8.0), -2), Vector2(1, 2)), Color(0.95, 0.92, 0.85, alpha))


func _px(ci: CanvasItem, pos: Vector2, run: int, key: String, solid: Variant, grey: bool, alpha: float) -> void:
	_rect(ci, Rect2(pos, Vector2(run, 1)), palette.get(key, Color.MAGENTA), solid, grey, alpha)


func _rect(ci: CanvasItem, r: Rect2, c: Color, solid: Variant, grey: bool, alpha: float) -> void:
	if solid != null:
		c = solid
	elif grey:
		var l := c.get_luminance()
		c = Color(l, l, l).lerp(Color(0.45, 0.42, 0.4), 0.4)
	ci.draw_rect(r, Color(c, c.a * alpha))
