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
var hatch: Passage
var wick: LanternFixture
var lamp: LanternFixture
var fifth: LanternFixture
var _service_light: PointLight2D


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
	add_exit(Rect2(NORTH_GAP.x, bounds.position.y - 8, 40, 8), "archive", "workshop")
	add_sign(Vector2(450, 80), "ARCHIVE UPSTAIRS", Vector2.UP)
	light_surfaces(0.62, 1.45)
	add_light(Vector2(450, 58), Color("d8e4f0"), 0.7, 140)
	_service_light = add_light(LAMP_POS + Vector2(0, -12), Color("ffd392"), 1.2, 190, true)
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
	for bench: Rect2 in [Rect2(150, 100, 66, 12), Rect2(286, 154, 68, 16), Rect2(360, 100, 70, 16)]:
		Decor.furniture(ci, bench, Color("77553b"), 5.0)
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


func _draw() -> void:
	if LanternRoute.repaired():
		draw_line(Vector2(320, 182), Vector2(320, 224), Color("efcd8c"), 1)
		draw_line(Vector2(320, 224), Vector2(128, 250), Color("efcd8c"), 1)
