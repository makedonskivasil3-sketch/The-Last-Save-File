class_name TitleArt
extends Control
## The title's key art (docs/VISUAL_DIRECTION.md): Rue, drawn large, alone
## in a dark room in front of the television the save is running on. The
## screen is the only light; it rims her on the side facing it and throws a
## cone across the floor. Her colours are the ones she has got back
## (Player.palette_for): a first launch shows the missing version, two points
## of light for eyes. The left third stays dark and quiet for the menu.
## No assets, no flashes, no input capture.

const VIEW := Vector2(640, 360)
const FLOOR_Y := 300.0
const TV := Rect2(456, 150, 128, 96)
const SCREEN := Rect2(466, 159, 108, 74)
const RUE_X := 404.0
const FIGURE := 3.6
const GLOW := Color(0.45, 0.82, 0.95)

var elapsed := 0.0
var _rue := IllustratedCharacter.new("rue", Player.MISSING)
var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_font = UiStyle.system_font()
	var palette := Player.palette_for(OwnerMemory.fragments.size(), OwnerMemory.frayed)
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


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, size / VIEW)
	var light := screen_light()
	_room(light)
	_light_cone(light)
	_television(light)
	_figure(light)
	_dust(light)
	_vignette()


func _room(light: float) -> void:
	# The wall: near-black, a little lighter around the screen.
	draw_polygon(PackedVector2Array([Vector2(0, 0), VIEW * Vector2(1, 0), Vector2(VIEW.x, FLOOR_Y), Vector2(0, FLOOR_Y)]),
		PackedColorArray([Color("06080d"), Color("0b1018"), Color("0d131c"), Color("06080d")]))
	for i in 10:
		var r := 60.0 + i * 22.0
		draw_circle(SCREEN.get_center(), r, Color(GLOW, 0.012 * light * (1.0 - i / 10.0)))
	# The floor, and its edge against the wall.
	draw_polygon(PackedVector2Array([Vector2(0, FLOOR_Y), Vector2(VIEW.x, FLOOR_Y), VIEW, Vector2(0, VIEW.y)]),
		PackedColorArray([Color("07090d"), Color("0e131a"), Color("0a0e14"), Color("040507")]))
	draw_line(Vector2(300, FLOOR_Y), Vector2(VIEW.x, FLOOR_Y), Color(GLOW, 0.05 * light), 1.0)
	# A window frame on the far wall, night behind it: the room is somewhere.
	var win := Rect2(326, 92, 56, 74)
	draw_rect(win, Color("080b12"))
	draw_rect(win, Color(GLOW, 0.05 * light), false, 1.0)
	draw_line(Vector2(win.get_center().x, win.position.y), Vector2(win.get_center().x, win.end.y), Color(GLOW, 0.04 * light), 1.0)
	draw_line(Vector2(win.position.x, win.get_center().y), Vector2(win.end.x, win.get_center().y), Color(GLOW, 0.04 * light), 1.0)


func _light_cone(light: float) -> void:
	# The screen's light across the floor, toward her and past her.
	var top_l := Vector2(SCREEN.position.x, SCREEN.end.y)
	var top_r := SCREEN.end
	draw_polygon(PackedVector2Array([top_l, top_r, Vector2(TV.end.x + 10, VIEW.y), Vector2(300, VIEW.y)]),
		PackedColorArray([Color(GLOW, 0.06 * light), Color(GLOW, 0.06 * light), Color(GLOW, 0.0), Color(GLOW, 0.0)]))
	draw_colored_polygon(PackedVector2Array([Vector2(330, FLOOR_Y + 6), Vector2(TV.position.x, FLOOR_Y - 2), Vector2(TV.end.x, FLOOR_Y + 2), Vector2(360, FLOOR_Y + 26)]),
		Color(GLOW, 0.035 * light))


func _television(light: float) -> void:
	# A low cabinet, then the set on it.
	var cab := Rect2(TV.position.x - 14, TV.end.y + 4, TV.size.x + 28, FLOOR_Y - TV.end.y - 4)
	draw_rect(cab, Color("0c0f14"))
	draw_line(cab.position, Vector2(cab.end.x, cab.position.y), Color(GLOW, 0.12 * light), 1.0)
	draw_rect(Rect2(cab.position.x + 8, cab.position.y + 14, cab.size.x - 16, 1), Color(1, 1, 1, 0.03))
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
	var at := SCREEN.position + Vector2(8 + shift, 15)
	draw_string(_font, at, "SLOT 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ink)
	draw_rect(Rect2(at + Vector2(0, 5), Vector2(SCREEN.size.x - 16, 4)), Color(ink, 0.5 * light))
	draw_string(_font, at + Vector2(0, 26), "SLOT 2", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(ink, 0.6))
	# Slot 2: the save that started and never finished. Its bar writes a
	# little, stops, and the cursor waits.
	var bar := Rect2(at + Vector2(0, 31), Vector2(SCREEN.size.x - 16, 4))
	draw_rect(bar, Color(ink, 0.25 * light), false, 1.0)
	var fill := clampf(0.2 + OwnerMemory.fragments.size() * 0.12, 0.0, 0.85)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * fill, bar.size.y)), Color(1.0, 0.75, 0.5, 0.55 * light))
	if fmod(elapsed, 1.1) < 0.6:
		draw_rect(Rect2(bar.position + Vector2(bar.size.x * fill + 2, -1), Vector2(2, 6)), Color(ink, 0.9))
	# The glass: a soft highlight across the top corner.
	draw_colored_polygon(PackedVector2Array([SCREEN.position, SCREEN.position + Vector2(40, 0), SCREEN.position + Vector2(0, 26)]), Color(1, 1, 1, 0.035))


func _figure(light: float) -> void:
	var at := Vector2(RUE_X, FLOOR_Y)
	# Her shadow falls away from the screen.
	draw_colored_polygon(PackedVector2Array([at + Vector2(-6, 0), at + Vector2(6, 0), at + Vector2(-60, 10), at + Vector2(-74, 6)]), Color(0, 0, 0, 0.35))
	# The rim: the side of her facing the screen catches its light.
	_rue.draw(self, {"offset": at + Vector2(1.6, 0), "scale": FIGURE, "solid": Color(GLOW, 0.55 * light)})
	_rue.draw(self, {"offset": at, "scale": FIGURE})
	# And the far side of her stays in the dark.
	_rue.draw(self, {"offset": at + Vector2(-1.2, 0), "scale": FIGURE, "solid": Color(0.02, 0.03, 0.05, 0.28)})
	draw_set_transform(Vector2.ZERO, 0.0, size / VIEW)


func _dust(light: float) -> void:
	# Motes, visible only where the screen's light catches them.
	for i in 22:
		var x := 300.0 + fposmod(i * 61.0 + elapsed * (2.0 + i % 3), 300.0)
		var y := 120.0 + fposmod(i * 37.0 - elapsed * (1.5 + i % 2), 200.0)
		var near := 1.0 - clampf(Vector2(x, y).distance_to(SCREEN.get_center()) / 180.0, 0.0, 1.0)
		draw_rect(Rect2(x, y, 1, 1), Color(0.8, 0.95, 1.0, 0.35 * near * light))


func _vignette() -> void:
	# The left third holds the menu: kept darkest, fading into the room.
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(330, 0), Vector2(330, VIEW.y), Vector2(0, VIEW.y)]),
		PackedColorArray([Color(0.01, 0.01, 0.02, 0.7), Color(0.01, 0.01, 0.02, 0.0), Color(0.01, 0.01, 0.02, 0.0), Color(0.01, 0.01, 0.02, 0.7)]))
	for i in 6:
		var w := 6.0 + i * 6.0
		var c := Color(0, 0, 0, 0.06)
		draw_rect(Rect2(0, 0, VIEW.x, w), c)
		draw_rect(Rect2(0, VIEW.y - w, VIEW.x, w), c)
		draw_rect(Rect2(VIEW.x - w, 0, w, VIEW.y), c)
