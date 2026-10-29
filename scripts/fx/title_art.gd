class_name TitleArt
extends Control
## The title's key art (docs/VISUAL_DIRECTION.md, docs/VERTICAL_SLICE.md §3b):
## a staged room in depth. Rue, drawn large, alone in a dark room in front
## of the television the save is running on. The screen is the only light:
## it rims her on the side facing it, throws a cone across a floor that
## recedes to the wall, casts her shadow away from it, and catches the edges
## of what is nearest the viewer (an armchair, and the second controller on
## the floor with its taped cable). Her colours are the ones she has got
## back (Player.palette_for): a first launch shows the missing version, two
## points of light for eyes. The left third stays dark and quiet for the menu.
##
## Depth: four layers (wall, set, her, foreground) shift by a slow,
## bounded drift (at most PARALLAX px for the nearest), with no input
## needed: the menu never moves. Reduce motion: no drift, no dust travel.
## No assets, no flashes, no input capture, no 3D (measured unnecessary: one
## CanvasItem pass, docs/VERTICAL_SLICE.md §3b).

const VIEW := Vector2(640, 360)
## Where she stands (midground), and where the far wall meets the floor.
const FLOOR_Y := 300.0
const WALL_Y := 258.0
## The set, against the far wall (smaller than she is: it's further away).
const TV := Rect2(478, 150, 108, 80)
const SCREEN := Rect2(486, 157, 92, 60)
const RUE_X := 404.0
const FIGURE := 3.6
const GLOW := Color(0.45, 0.82, 0.95)
## The floor's vanishing point (the boards run towards it).
const VP := Vector2(500, 120)
## The nearest layer's largest shift, in canvas pixels; the others less.
const PARALLAX := 4.0
const DEPTH := {"wall": 0.12, "set": 0.25, "her": 0.45, "near": 1.0}

var elapsed := 0.0
var _rue := CharacterArt.figure("rue", "rue", Player.MISSING)
## The title was composed around a 26 px Rue: the taller cast keeps that size.
var _fit := 26.0 / float(_rue.height())
var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_font = UiStyle.system_font()
	var palette := Player.palette_for(OwnerMemory.fragments.size(), OwnerMemory.frayed, Player.chose_own())
	_rue.palette = palette
	_rue.leg_color = palette["l"]
	_rue.shoe_color = palette["f"]
	_rue.eye_color = palette["e"]
	_rue.facing = Vector2.RIGHT


func _process(delta: float) -> void:
	elapsed += delta
	_rue.update(delta, Vector2.ZERO)
	_rue.facing = Vector2.RIGHT
	queue_redraw()


## How bright the screen is now: a slow breath with a rare dip, deeper the
## further the purge has gone (softened by the flash setting).
func screen_light() -> float:
	var dip := 0.0
	if fmod(elapsed, 9.0) > 8.7:
		dip = (0.25 + OwnerMemory.purge * 0.1) * Settings.flash_scale()
	return clampf(0.82 + sin(elapsed * 0.9) * 0.06 - dip, 0.3, 1.0)


## The slow drift every layer shares (-1..1 on each axis): a long, uneven
## loop, as if someone shifted their weight in the doorway. Zero with
## reduced motion.
func drift() -> Vector2:
	if Settings.reduce_motion:
		return Vector2.ZERO
	return Vector2(sin(elapsed * 0.11) * 0.8 + sin(elapsed * 0.047) * 0.2, sin(elapsed * 0.083 + 1.3) * 0.5)


## A layer's offset now (canvas pixels).
func layer_offset(layer: String) -> Vector2:
	return drift() * PARALLAX * float(DEPTH[layer])


func _layer(layer: String) -> void:
	var k := size / VIEW
	draw_set_transform(layer_offset(layer) * k, 0.0, k)


func _draw() -> void:
	var light := screen_light()
	_layer("wall")
	_room(light)
	_layer("set")
	_television(light)
	_light_cone(light)
	_layer("her")
	_figure(light)
	_dust(light)
	_layer("near")
	_foreground(light)
	draw_set_transform(Vector2.ZERO, 0.0, size / VIEW)
	_vignette()


func _room(light: float) -> void:
	var m := 8.0  # (painted past the frame, so a drift never shows an edge)
	# The far wall: near-black, a little lighter around the screen.
	draw_polygon(PackedVector2Array([Vector2(-m, -m), Vector2(VIEW.x + m, -m), Vector2(VIEW.x + m, WALL_Y), Vector2(-m, WALL_Y)]),
		PackedColorArray([Color("06080d"), Color("0b1018"), Color("0d131c"), Color("06080d")]))
	for i in 10:
		draw_circle(SCREEN.get_center(), 50.0 + i * 20.0, Color(GLOW, 0.012 * light * (1.0 - i / 10.0)))
	# The floor, receding from the viewer to the wall, and its boards
	# running to the vanishing point.
	draw_polygon(PackedVector2Array([Vector2(-m, WALL_Y), Vector2(VIEW.x + m, WALL_Y), Vector2(VIEW.x + m, VIEW.y + m), Vector2(-m, VIEW.y + m)]),
		PackedColorArray([Color("0a0d12"), Color("10151c"), Color("0c1016"), Color("040507")]))
	for i in range(-6, 15):
		var bottom := Vector2(i * 56.0, VIEW.y + m)
		var t := (WALL_Y - VP.y) / (bottom.y - VP.y)
		var top := VP.lerp(bottom, t)
		var lit := 1.0 - clampf(absf(bottom.x - 470.0) / 360.0, 0.0, 1.0)
		draw_line(top, bottom, Color(0, 0, 0, 0.35), 1.0)
		draw_line(top + Vector2(1, 0), bottom + Vector2(1, 0), Color(GLOW, 0.025 * light * lit), 1.0)
	# The skirting where wall meets floor, lit near the set.
	draw_line(Vector2(-m, WALL_Y), Vector2(VIEW.x + m, WALL_Y), Color(0, 0, 0, 0.6), 2.0)
	draw_line(Vector2(300, WALL_Y - 1), Vector2(VIEW.x, WALL_Y - 1), Color(GLOW, 0.06 * light), 1.0)
	# A window frame on the far wall, night behind it: the room is somewhere.
	var win := Rect2(336, 96, 50, 66)
	draw_rect(win, Color("080b12"))
	draw_rect(win.grow(-3), Color(0.12, 0.16, 0.24, 0.12))
	draw_rect(win, Color(GLOW, 0.05 * light), false, 1.0)
	draw_line(Vector2(win.get_center().x, win.position.y), Vector2(win.get_center().x, win.end.y), Color(GLOW, 0.04 * light), 1.0)
	draw_line(Vector2(win.position.x, win.get_center().y), Vector2(win.end.x, win.get_center().y), Color(GLOW, 0.04 * light), 1.0)
	# A shelf on the wall, its edge catching the screen.
	draw_rect(Rect2(404, 118, 52, 3), Color("0e1218"))
	draw_line(Vector2(404, 118), Vector2(456, 118), Color(GLOW, 0.07 * light), 1.0)
	for b in [[408, 9, 0.9], [419, 7, 0.7], [428, 11, 0.8], [442, 6, 0.6]]:
		draw_rect(Rect2(b[0], 118 - b[1], 6, b[1]), Color(0.05, 0.06, 0.08, b[2]))


func _television(light: float) -> void:
	# A low cabinet against the wall, then the set on it.
	var cab := Rect2(TV.position.x - 12, TV.end.y + 3, TV.size.x + 24, WALL_Y - TV.end.y - 1)
	draw_rect(cab, Color("0c0f14"))
	draw_line(cab.position, Vector2(cab.end.x, cab.position.y), Color(GLOW, 0.12 * light), 1.0)
	draw_rect(Rect2(cab.position.x + 8, cab.position.y + 12, cab.size.x - 16, 1), Color(1, 1, 1, 0.03))
	# Its shadow on the floor, and the screen's reflection in the boards.
	draw_rect(Rect2(cab.position.x - 2, WALL_Y, cab.size.x + 4, 4), Color(0, 0, 0, 0.4))
	for i in 6:
		draw_rect(Rect2(SCREEN.position.x + 6, WALL_Y + 3 + i * 3, SCREEN.size.x - 12, 3), Color(GLOW, 0.022 * light * (1.0 - i / 6.0)))
	draw_rect(TV, Color("101318"))
	draw_rect(TV, Color(GLOW, 0.1 * light), false, 1.0)
	# The screen.
	draw_rect(SCREEN, Color(0.05, 0.09, 0.12).lerp(Color(0.1, 0.2, 0.26), light))
	for y in range(int(SCREEN.position.y), int(SCREEN.end.y), 2):
		draw_line(Vector2(SCREEN.position.x, y), Vector2(SCREEN.end.x, y), Color(0, 0, 0, 0.18), 1.0)
	var ink := Color(0.75, 0.95, 1.0, 0.85 * light)
	var shift := 0.0
	if OwnerMemory.purge > 0 and fmod(elapsed, 5.0) > 4.85:
		shift = 3.0 * Settings.flash_scale()
	var at := SCREEN.position + Vector2(7 + shift, 13)
	draw_string(_font, at, "SLOT 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ink)
	draw_rect(Rect2(at + Vector2(0, 4), Vector2(SCREEN.size.x - 14, 3)), Color(ink, 0.5 * light))
	draw_string(_font, at + Vector2(0, 22), "SLOT 2", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(ink, 0.6))
	# Slot 2: the save that started and never finished. Its bar writes a
	# little, stops, and the cursor waits.
	var bar := Rect2(at + Vector2(0, 26), Vector2(SCREEN.size.x - 14, 3))
	draw_rect(bar, Color(ink, 0.25 * light), false, 1.0)
	var fill := clampf(0.2 + OwnerMemory.fragments.size() * 0.12, 0.0, 0.85)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * fill, bar.size.y)), Color(1.0, 0.75, 0.5, 0.55 * light))
	if fmod(elapsed, 1.1) < 0.6:
		draw_rect(Rect2(bar.position + Vector2(bar.size.x * fill + 2, -1), Vector2(2, 5)), Color(ink, 0.9))
	# The glass: a soft highlight across the top corner.
	draw_colored_polygon(PackedVector2Array([SCREEN.position, SCREEN.position + Vector2(34, 0), SCREEN.position + Vector2(0, 22)]), Color(1, 1, 1, 0.035))


## Where the screen's light lands on the floor (the source for shadows).
func light_on_floor() -> Vector2:
	return Vector2(SCREEN.get_center().x, WALL_Y)


func _light_cone(light: float) -> void:
	# The screen's light across the floor, widening as the floor comes
	# towards the viewer.
	var src := light_on_floor()
	draw_polygon(PackedVector2Array([src + Vector2(-SCREEN.size.x * 0.5, 0), src + Vector2(SCREEN.size.x * 0.5, 0),
			Vector2(VIEW.x + 40, VIEW.y), Vector2(250, VIEW.y)]),
		PackedColorArray([Color(GLOW, 0.075 * light), Color(GLOW, 0.075 * light), Color(GLOW, 0.0), Color(GLOW, 0.0)]))


func _figure(light: float) -> void:
	var at := Vector2(RUE_X, FLOOR_Y)
	# Her cast shadow, thrown away from the screen along the floor.
	var away := (at - light_on_floor()).normalized()
	var reach := 86.0
	var side := Vector2(-away.y, away.x) * 7.0
	draw_colored_polygon(PackedVector2Array([at - side, at + side, at + away * reach + side * 2.2, at + away * reach - side * 2.2]),
		Color(0, 0, 0, 0.28))
	# Contact: where her feet meet the boards.
	var k := size / VIEW
	draw_set_transform((layer_offset("her") + at) * k, 0.0, k * Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, 15.0, Color(0, 0, 0, 0.45))
	draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.35))
	_layer("her")
	# The rim: the side of her facing the screen catches its light. (The
	# character sets its own transform, in canvas units: the layer's shift
	# goes in its offset.)
	at += layer_offset("her")
	_rue.draw(self, {"offset": at + Vector2(1.6, 0), "scale": FIGURE * _fit, "solid": Color(GLOW, 0.55 * light)})
	_rue.draw(self, {"offset": at, "scale": FIGURE * _fit})
	# And the far side of her stays in the dark.
	_rue.draw(self, {"offset": at + Vector2(-1.2, 0), "scale": FIGURE * _fit, "solid": Color(0.02, 0.03, 0.05, 0.28)})
	_layer("her")  # (IllustratedCharacter leaves its own transform set)


func _dust(light: float) -> void:
	# Motes, visible only where the screen's light catches them. Held still
	# with reduced motion.
	var t := 0.0 if Settings.reduce_motion else elapsed
	for i in 22:
		var x := 300.0 + fposmod(i * 61.0 + t * (2.0 + i % 3), 300.0)
		var y := 110.0 + fposmod(i * 37.0 - t * (1.5 + i % 2), 200.0)
		var near := 1.0 - clampf(Vector2(x, y).distance_to(SCREEN.get_center()) / 180.0, 0.0, 1.0)
		draw_rect(Rect2(x, y, 1, 1), Color(0.8, 0.95, 1.0, 0.35 * near * light))


## Nearest the viewer, out of focus and almost black: the arm of a chair at
## the right edge, and the second controller on the floor, its taped cable
## running out of frame. Only their edges facing the screen are lit.
func _foreground(light: float) -> void:
	var dark := Color("030405")
	# The chair arm: a padded roll and its side, out of focus (a soft halo
	# first), its top edge catching the screen.
	var roll := Vector2(640, 250)
	draw_circle(roll, 30.0, Color(dark, 0.5))
	draw_rect(Rect2(608, 250, 60, 130), Color(dark, 0.5))
	draw_circle(roll, 27.0, dark)
	draw_rect(Rect2(611, 250, 60, 130), dark)
	draw_arc(roll, 27.0, PI * 1.02, PI * 1.45, 10, Color(GLOW, 0.2 * light), 1.5)
	# The second controller, dropped, the cable taped where the dog chewed it.
	var pad := Vector2(548, 324)
	var cable := PackedVector2Array([pad + Vector2(-30, 8), pad + Vector2(-80, 22), pad + Vector2(-128, 20), pad + Vector2(-176, 44)])
	draw_polyline(cable, Color(0.02, 0.02, 0.03), 3.0)
	draw_line(cable[0], cable[1], Color(GLOW, 0.06 * light), 1.0)
	draw_rect(Rect2(pad + Vector2(-110, 18), Vector2(11, 6)), Color(0.42, 0.42, 0.38, 0.5))  # the tape
	var k := size / VIEW
	draw_set_transform((layer_offset("near") + pad) * k, -0.16, k * 1.4)
	for r in [Vector2(-22, 2), Vector2(22, 2)]:
		draw_circle(r, 11.0, Color(dark, 0.5))
		draw_circle(r, 9.0, dark)
	draw_rect(Rect2(-24, -7, 48, 15), dark)
	draw_line(Vector2(-25, -7.5), Vector2(25, -7.5), Color(GLOW, 0.22 * light), 1.0)
	draw_arc(Vector2(22, 2), 9.0, -PI * 0.8, -PI * 0.1, 8, Color(GLOW, 0.22 * light), 1.0)
	draw_circle(Vector2(14, -1), 1.6, Color(0.55, 0.16, 0.16, 0.8))
	_layer("near")


func _vignette() -> void:
	# The left third holds the menu: kept darkest, fading into the room.
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(330, 0), Vector2(330, VIEW.y), Vector2(0, VIEW.y)]),
		PackedColorArray([Color(0.01, 0.01, 0.02, 0.72), Color(0.01, 0.01, 0.02, 0.0), Color(0.01, 0.01, 0.02, 0.0), Color(0.01, 0.01, 0.02, 0.72)]))
	for i in 6:
		var w := 6.0 + i * 6.0
		var c := Color(0, 0, 0, 0.06)
		draw_rect(Rect2(0, 0, VIEW.x, w), c)
		draw_rect(Rect2(0, VIEW.y - w, VIEW.x, w), c)
		draw_rect(Rect2(VIEW.x - w, 0, w, VIEW.y), c)
