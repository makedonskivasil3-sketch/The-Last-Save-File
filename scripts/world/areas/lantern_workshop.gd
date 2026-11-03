class_name LanternWorkshop
extends Area
## A service room beneath the Archive, joined to the well by an earned
## hatch. One small action loop before any wider campaign expansion.

const NORTH_GAP := Vector2(430, 470)
const WICK_POS := Vector2(182, 116)
const LAMP_POS := Vector2(320, 178)
const HATCH_POS := Vector2(128, 250)
## The fifth festival frame, last on the shelf (LanternRoute.NAMED).
const FRAME_POS := Vector2(418, 118)
## Storage along the walls (2026-11-03 calibration): a working room, not
## three benches in a hall. All of it hugs a wall, clear of the stair
## runner, the hatch, both entries and every bench's working side.
const TOOL_WALL := Rect2(120, 36, 150, 10)      # pegboard over the wick bench
const FRAME_SHELF := Rect2(514, 84, 28, 120)    # finished frames, east wall
const SPOOL_RACK := Rect2(98, 96, 16, 70)       # wick spools, west wall
const STOCK := Rect2(488, 246, 54, 44)          # crates and an oil drum, SE corner
var hatch: Passage
var wick: LanternFixture
var lamp: LanternFixture
var fifth: LanternFixture
var _service_light: PointLight2D
var _hatch_light: PointLight2D


func _init() -> void:
	area_id = "workshop"
	display_name = "LANTERN WORKSHOP · BELOW THE ARCHIVE"
	bounds = Rect2(96, 36, 448, 256)
	awareness_rate = -0.6
	tint = Color(1.0, 0.94, 0.84)
	entries = {"stairs": Vector2(450, 64), "well": Vector2(152, 250)}
	entry_facings = {"well": Vector2.RIGHT}


func build() -> void:
	setup_common()
	Relationships.add(LanternRoute.ENTERED)
	set_backdrop(_paint)
	add_boundary([{"side": "top", "from": NORTH_GAP.x, "to": NORTH_GAP.y}])
	add_solid(Rect2(150, 100, 66, 12))
	add_solid(Rect2(286, 154, 68, 16))
	add_solid(Rect2(360, 100, 70, 16))
	for r: Rect2 in [FRAME_SHELF, SPOOL_RACK, STOCK]:
		add_solid(r)
	add_exit(Rect2(NORTH_GAP.x, bounds.position.y - 8, 40, 8), "archive", "workshop")
	add_sign(Vector2(450, 80), "ARCHIVE UPSTAIRS", Vector2.UP)
	light_surfaces(0.62, 1.45)
	add_light(Vector2(450, 58), Color("d8e4f0"), 0.7, 140)
	_service_light = add_light(LAMP_POS + Vector2(0, -12), Color("ffd392"), 1.3, 210, true)
	# The repair's payoff reaches the hatch: light where the route goes next.
	_hatch_light = add_light(HATCH_POS + Vector2(4, -6), Color("ffcf86"), 0.7, 70)
	add_dust(Rect2(270, 110, 100, 140), Color(1, 0.85, 0.6, 0.3), 12, Vector2(1, -1))
	wick = LanternFixture.new()
	wick.position = WICK_POS
	wick.changed.connect(_refresh)
	add_child(wick)
	interactables.append(wick)
	lamp = LanternFixture.new()
	lamp.lamp = true
	lamp.position = LAMP_POS
	lamp.changed.connect(_refresh)
	add_child(lamp)
	interactables.append(lamp)
	fifth = LanternFixture.new()
	fifth.frame = true
	fifth.position = FRAME_POS
	fifth.changed.connect(_refresh)
	add_child(fifth)
	interactables.append(fifth)
	hatch = Passage.new()
	hatch.position = HATCH_POS
	hatch.object_name = "WELL SERVICE HATCH"
	hatch.prompt = "go down to the well"
	hatch.arrival = "workshop"
	hatch.taken.connect(func(p: Passage) -> void: world.change_area(p.target_area, p.arrival))
	add_child(hatch)
	interactables.append(hatch)
	add_sign(Vector2(155, 230), "WELL SERVICE HATCH", Vector2.LEFT, LanternRoute.repaired)
	_refresh()


## After the light is on, the fifth frame asks its question: write her
## name, or leave it (nothing is recorded, so she can choose later).
func interact_extra(node: Node) -> void:
	if node != fifth or not LanternRoute.repaired() or LanternRoute.named():
		return
	var pick: int = await world.choose_safely(LanternRoute.NAME_ASK, LanternRoute.NAME_CHOICES)
	if not is_inside_tree() or pick < 0:
		return
	if pick != 0:
		world.hud.say("(not yet.)", "self")
		return
	var kept := LanternRoute.record(LanternRoute.NAMED, "My name on the fifth frame", [
		"The fifth lantern's label was blank. I wrote RUE on it.",
		"Nobody gave me the name for that lantern. I'm taking it anyway."])
	Sfx.play("ui_confirm")
	fifth.queue_redraw()
	world.hud.say("RUE  ·  written on the fifth frame. (journal: Objects)" + fifth._unsaved_note(kept), "system")
	world.hud.say("(the first thing in this save with my name on it that i chose.)", "self")


func _refresh() -> void:
	_service_light.enabled = LanternRoute.repaired()
	_hatch_light.enabled = LanternRoute.repaired()
	hatch.target_area = "oob" if LanternRoute.repaired() else ""
	# Backdrops are baked once, so redraw only the stateful layer.
	queue_redraw()


func guide_point() -> Vector2:
	return HATCH_POS if LanternRoute.repaired() else (LAMP_POS if Relationships.has(LanternRoute.SPOOL) else WICK_POS)


func _paint(ci: CanvasItem) -> void:
	Decor.flagstones(ci, bounds, Color("514539"), 26.0, 6.0)
	Decor.walls(ci, bounds, WALL, Color("6a5546"), Color("2e2620"), [{"side": "top", "from": NORTH_GAP.x, "to": NORTH_GAP.y}])
	# Continuous brass-edged runner from the Archive stair to the bench.
	for rect: Rect2 in [Rect2(438, 36, 24, 190), Rect2(124, 214, 338, 18)]:
		ci.draw_rect(rect, Color("47362d"))
		ci.draw_rect(rect.grow(-2), Color("66503a"), false, 1)
	# Work zones: a worn mat in front of each bench, shavings where the
	# cutting happens. Read as places people stood, not decoration.
	for mat: Rect2 in [Rect2(146, 116, 74, 20), Rect2(280, 174, 80, 20), Rect2(356, 120, 78, 18)]:
		ci.draw_rect(mat, Color("3f3429"))
		ci.draw_rect(mat.grow(-2), Color("5a4733"), false, 1)
	for i in 14:
		var at := Vector2(352 + Decor.hash01(i, 1.0) * 86.0, 122 + Decor.hash01(i, 2.0) * 16.0)
		ci.draw_line(at, at + Vector2(2, 1), Color("b99a6a", 0.7), 1)
	for bench: Rect2 in [Rect2(150, 100, 66, 12), Rect2(286, 154, 68, 16), Rect2(360, 100, 70, 16)]:
		Decor.furniture(ci, bench, Color("77553b"), 5.0)
	_paint_storage(ci)
	# Empty lantern frames, scissors, paper labels, and the remembered five.
	for i in 4:
		var at := Vector2(370 + i * 12, 96)
		ci.draw_rect(Rect2(at - Vector2(4, 14), Vector2(8, 13)), Color("ba9158"), false, 1)
		ci.draw_line(at + Vector2(-5, 0), at + Vector2(5, 0), Color("e3c995"), 1)
	ci.draw_line(Vector2(198, 102), Vector2(208, 108), Color("c6c6bb"), 1)
	ci.draw_line(Vector2(198, 108), Vector2(208, 102), Color("c6c6bb"), 1)
	ci.draw_rect(Rect2(112, 238, 32, 24), Color("241f20"))
	ci.draw_rect(Rect2(112, 238, 32, 24), Color("b18a50"), false, 2)
	for y in range(244, 259, 5):
		ci.draw_line(Vector2(116, y), Vector2(140, y), Color("66503a"), 1)
	# The stair repeats the Archive's stones, with a clear opening overhead.
	for y in range(38, 64, 5):
		ci.draw_line(Vector2(432, y), Vector2(468, y), Color("b3a18c"), 1)


## Pegboard, spool rack, frame shelf and stock: what a lantern-maker
## keeps within reach. Shapes, not texture, at play scale.
func _paint_storage(ci: CanvasItem) -> void:
	var wood := Color("6b4c35")
	var brass := Color("c9a061")
	# Pegboard with hung tools: two saws, a hammer, shears, a coil of wire.
	ci.draw_rect(TOOL_WALL, Color("4a3a2c"))
	ci.draw_rect(TOOL_WALL, Color("2e2620"), false, 1)
	for x in range(int(TOOL_WALL.position.x) + 4, int(TOOL_WALL.end.x), 6):
		ci.draw_rect(Rect2(x, TOOL_WALL.position.y + 4, 1, 1), Color("2e2620"))
	ci.draw_line(Vector2(132, 39), Vector2(132, 50), Color("c6c6bb"), 2)
	ci.draw_line(Vector2(129, 39), Vector2(135, 39), wood, 2)
	ci.draw_line(Vector2(148, 39), Vector2(156, 51), Color("c6c6bb"), 1)
	ci.draw_line(Vector2(170, 39), Vector2(170, 49), wood, 2)
	ci.draw_rect(Rect2(166, 47, 8, 3), Color("8d8d86"))
	ci.draw_arc(Vector2(196, 45), 4.0, 0.0, TAU, 10, brass, 1)
	ci.draw_arc(Vector2(196, 45), 2.0, 0.0, TAU, 8, brass, 1)
	for i in 3:
		ci.draw_line(Vector2(216 + i * 14, 39), Vector2(216 + i * 14, 52), Color("e3c995", 0.8), 1)  # wick lengths drying
	# Spool rack on the west wall: the wick she needs came from here.
	Decor.furniture(ci, SPOOL_RACK, wood, 3.0)
	for i in 4:
		var c := Vector2(SPOOL_RACK.get_center().x, SPOOL_RACK.position.y + 10 + i * 16)
		Decor.disc(ci, c, 5.0, Color("d9c08a"))
		Decor.disc(ci, c, 2.0, Color("6b4c35"))
	# Shelf of finished frames on the east wall, three high, each with a
	# paper label; one gap where the fifth frame would have gone.
	Decor.furniture(ci, FRAME_SHELF, wood, 3.0)
	for row in 3:
		var y := FRAME_SHELF.position.y + 12 + row * 38
		ci.draw_line(Vector2(FRAME_SHELF.position.x + 2, y + 14), Vector2(FRAME_SHELF.end.x - 2, y + 14), Color("2e2620"), 1)
		for k in 2:
			if row == 2 and k == 1:
				continue  # the empty place
			var f := Rect2(FRAME_SHELF.position.x + 4 + k * 12, y, 8, 12)
			ci.draw_rect(f, brass, false, 1)
			ci.draw_rect(Rect2(f.position.x + 1, f.end.y - 3, 6, 2), Color("efe6d2", 0.8))
	# Stock in the corner: two crates and an oil drum, with their shadows.
	Decor.wall_shadow(ci, STOCK, 6.0, 0.3)
	Decor.furniture(ci, Rect2(STOCK.position.x, STOCK.position.y + 14, 24, 30), Color("8a6a46"), 4.0)
	Decor.furniture(ci, Rect2(STOCK.position.x + 4, STOCK.position.y, 18, 16), Color("94744c"), 3.0)
	Decor.disc(ci, Vector2(STOCK.end.x - 14, STOCK.get_center().y + 4), 11.0, Color("3d4a52"))
	ci.draw_arc(Vector2(STOCK.end.x - 14, STOCK.get_center().y + 4), 11.0, 0.0, TAU, 16, Color("6c7c86"), 1)
	ci.draw_arc(Vector2(STOCK.end.x - 14, STOCK.get_center().y + 4), 6.0, 0.0, TAU, 12, Color("2b353b"), 1)


func _draw() -> void:
	if LanternRoute.repaired():
		# The light runs down the service line to the hatch: a soft band
		# with a bright core, so the next route reads at a glance.
		var path := PackedVector2Array([Vector2(320, 182), Vector2(320, 224), Vector2(140, 246)])
		draw_polyline(path, Color("ffcf86", 0.18), 6.0)
		draw_polyline(path, Color("efcd8c", 0.9), 1.0)
		draw_rect(Rect2(112, 238, 32, 24).grow(1), Color("ffd392", 0.85), false, 1)
