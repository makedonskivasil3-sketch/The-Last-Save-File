class_name VillageSquare
extends Area
## Ashvale's square, the owner's hub. Arin (driven by the owner) walks a loop
## around the well. Wren can hide you. Tobben reports you.

const HOUSE := Rect2(56, 44, 110, 56)
const WELL := Rect2(306, 158, 28, 20)
const STALL := Rect2(440, 44, 96, 34)
const CRATES := Rect2(64, 230, 40, 26)
const BOARD_POS := Vector2(240, 40)
const EAST_GAP := Vector2(160, 200)
const NORTH_GAP := Vector2(300, 340)
const TREES: Array[Vector2] = [Vector2(190, 268), Vector2(560, 250), Vector2(420, 274), Vector2(560, 120), Vector2(60, 160)]
const ROUTE: Array[Vector2] = [Vector2(200, 130), Vector2(440, 130), Vector2(440, 230), Vector2(200, 230)]

const GRASS := Color("1f2a1e")
const PATH := Color("3a3128")
const STONE := Color("5a5550")

const WREN_LINES := [
	"You're the one Mira talks about. The colors-wrong one.",
	"Stand right next to me. The owner can't see what I'm standing beside. I don't know why.",
	"There's a library east of here. Arin never goes there. Nobody does.",
	"If they find out I hid you, they'll take me out of the save. It's okay. Go.",
]
const TOBBEN_LINES := [
	"Welcome to Tobben's! Finest wares in Ashvale!",
	"Welcome to Tobben's! Finest... you don't have any gold. You don't have an inventory.",
	"Welcome to... I have to tell them, you know. It's in my script.",
	"I told them. I'm sorry. Welcome to Tobben's.",
]

var arin: OwnerAvatar
var cursor: OwnerCursor
var wren: Npc
var tobben: Npc
var board: Note
var north_exit: Exit

var _wren_line := 0
var _tobben_line := 0
var _spotted_once := false


func _init() -> void:
	area_id = "square"
	display_name = "ASHVALE · VILLAGE SQUARE"
	bounds = Rect2(40, 36, 560, 256)
	awareness_rate = 1.0
	tint = Color(0.95, 0.95, 1.0)
	entries = {
		"house": Vector2(111, 118),
		"east": Vector2(578, 180),
		"north": Vector2(320, 54),
	}


func build() -> void:
	setup_common()
	add_boundary([
		{"side": "right", "from": EAST_GAP.x, "to": EAST_GAP.y},
		{"side": "top", "from": NORTH_GAP.x, "to": NORTH_GAP.y},
	])
	for r in [HOUSE, WELL, STALL, CRATES]:
		add_solid(r)

	add_exit(Rect2(bounds.end.x, EAST_GAP.x, 8, EAST_GAP.y - EAST_GAP.x), "archive", "west")
	north_exit = add_exit(
		Rect2(NORTH_GAP.x, bounds.position.y - 8, NORTH_GAP.y - NORTH_GAP.x, 8), "edge", "south",
		world.flags.get("pointer", false),
		"The road north isn't loaded. Nothing in this save points there.")

	board = Note.new()
	board.title = "NOTICE BOARD"
	board.position = BOARD_POS
	board.player = world.player
	board.text = "ASHVALE NOTICES\nHarvest fair on Sunday." if OwnerMemory.sessions <= 1 else "MISSING: ONE (1) INTRUDER.\nIF SEEN, TELL TOBBEN."
	add_child(board)
	interactables.append(board)

	var house_door := add_readable("ARIN'S HOUSE", Vector2(111, 104), Readable.Look.SIGN,
		func() -> Array: return ["The door is locked from the inside.", "You came out through a wall. You won't get back in that way."])
	house_door.prompt = "door"

	wren = add_npc("wren", Vector2(126, 246))
	wren.display_name = "WREN"
	wren.dress_color = Color("6a8f5a")
	wren.hair_color = Color("c9a04a")
	wren.height = 0.75
	wren.hide_radius = 22.0
	wren.lines_provider = _wren_lines

	tobben = add_npc("tobben", Vector2(488, 92))
	tobben.display_name = "TOBBEN"
	tobben.dress_color = Color("7a5a8a")
	tobben.hair_color = Color("bbbbbb")
	tobben.height = 1.1
	tobben.lines_provider = _tobben_lines
	tobben.on_talk = _tobben_reports

	arin = OwnerAvatar.new()
	arin.route = ROUTE
	arin.position = ROUTE[0]
	arin.speed = 38.0 + OwnerMemory.purge * 6.0
	arin.player = world.player
	arin.is_hidden = world.is_player_hidden
	arin.sees_player.connect(_on_arin_sees)
	arin.touched_player.connect(func() -> void: world.kill("overwritten"))
	add_child(arin)


func catch_up() -> void:
	if world.director.has_fired(OwnerDirector.NOTICE):
		board.set_text_now("MISSING: ONE (1) INTRUDER.\nIF SEEN, TELL TOBBEN.")
	if world.director.has_fired(OwnerDirector.SUSPECT):
		arin.speed *= 1.25
	if world.director.has_fired(OwnerDirector.CONTAIN):
		arin.view_distance += 20.0
	if world.director.has_fired(OwnerDirector.HUNT):
		_unleash()


func on_owner_event(threshold: float) -> void:
	match threshold:
		OwnerDirector.NOTICE:
			board.rewrite("MISSING: ONE (1) INTRUDER.\nIF SEEN, TELL TOBBEN.")
		OwnerDirector.SUSPECT:
			arin.speed *= 1.25
		OwnerDirector.CONTAIN:
			arin.view_distance += 20.0
		OwnerDirector.SILENCE:
			if "wren" in OwnerMemory.session_helpers and wren.delete():
				world.fx.spike(0.8, 1.2)
				world.director.say("she was hiding you. not anymore.")
				world.hud.say("wren.npc deleted", "system")
		OwnerDirector.HUNT:
			_unleash()
		OwnerDirector.PURGE:
			if cursor:
				cursor.speed *= 1.3


func area_process(_delta: float) -> void:
	north_exit.open = world.flags.get("pointer", false)
	arin.paused = world.is_talking()


func _unleash() -> void:
	start_erasure([Vector2(320, 60), Vector2(580, 270)])
	if cursor == null:
		cursor = OwnerCursor.new()
		cursor.bounds = bounds
		cursor.position = Vector2(320, 40)
		cursor.speed = 50.0 + OwnerMemory.purge * 8.0
		cursor.player = world.player
		cursor.is_hidden = world.is_player_hidden
		cursor.selected_player.connect(func() -> void: world.kill("selected"))
		cursor.z_index = 20
		add_child(cursor)


func _on_arin_sees(delta: float) -> void:
	world.director.add_awareness(28.0 * delta)
	if not _spotted_once:
		_spotted_once = true
		world.director.say("there. by the %s." % _landmark(world.player.global_position))


func _landmark(p: Vector2) -> String:
	if p.distance_to(WELL.get_center()) < 70.0:
		return "well"
	if p.x > 420.0 and p.y < 140.0:
		return "shop"
	if p.x < 200.0:
		return "house"
	return "road"


func _wren_lines() -> Array:
	var line: String = WREN_LINES[mini(_wren_line, WREN_LINES.size() - 1)]
	_wren_line += 1
	return [line]


func _tobben_lines() -> Array:
	var i := _tobben_line
	if OwnerMemory.sessions > 1 and i == 0:
		i = 2  # he remembers what he's for
	_tobben_line = i + 1
	return [TOBBEN_LINES[mini(i, TOBBEN_LINES.size() - 1)]]


func _tobben_reports() -> void:
	# He tells the owner a few seconds later.
	get_tree().create_timer(4.0).timeout.connect(_tobben_report_lands)


func _tobben_report_lands() -> void:
	if is_inside_tree() and world.ending == "":
		world.director.say("tobben says you were asking questions.")
		world.director.add_awareness(12.0)


func _draw() -> void:
	var r := bounds
	draw_rect(r, GRASS)
	# Paths: house to well, well to the east road, well to the north road.
	draw_rect(Rect2(100, 100, 24, 90), PATH)
	draw_rect(Rect2(100, 170, 500, 20), PATH)
	draw_rect(Rect2(NORTH_GAP.x, r.position.y, 40, 130), PATH)
	# Unloaded road north: static where the path should continue.
	if not world.flags.get("pointer", false):
		for i in 10:
			draw_rect(Rect2(NORTH_GAP.x + randf() * 36.0, r.position.y + randf() * 14.0, 4, 1), Color(1, 1, 1, 0.15))
	for t in TREES:
		draw_circle(t, 12.0, Color("223322"))
		draw_circle(t + Vector2(-3, -3), 8.0, Color("2c4430"))
	# Arin's house.
	draw_rect(HOUSE, Color("5a4434"))
	draw_rect(Rect2(HOUSE.position - Vector2(4, 6), Vector2(HOUSE.size.x + 8, 12)), Color("6b3a2c"))
	draw_rect(Rect2(Vector2(104, 82), Vector2(14, 18)), Color("3a2a20"))
	# Well.
	draw_rect(WELL, STONE)
	draw_rect(WELL.grow(-4), Color("1a2a3a"))
	# Tobben's stall.
	draw_rect(STALL, Color("4f3a2c"))
	for i in 6:
		draw_rect(Rect2(STALL.position + Vector2(i * 16, -6), Vector2(16, 8)), Color("8a3a3a") if i % 2 == 0 else Color("c8b8a0"))
	draw_rect(CRATES, Color("5a4632"))
	draw_rect(CRATES, Color("3a2a20"), false, 1.0)
	draw_walls([
		{"side": "right", "from": EAST_GAP.x, "to": EAST_GAP.y},
		{"side": "top", "from": NORTH_GAP.x, "to": NORTH_GAP.y},
	])


func _process(_delta: float) -> void:
	if not world.flags.get("pointer", false):
		queue_redraw()  # animates the unloaded road
