class_name VillageSquare
extends Area
## Ashvale's square, the owner's hub. Arin (driven by the owner) walks a loop
## around the well. Wren can hide you. Tobben reports you.

const HOUSE := Rect2(56, 44, 110, 56)
const HOUSE_DOOR := Rect2(98, 96, 26, 6)
const WELL := Rect2(306, 158, 28, 20)
const STALL := Rect2(440, 44, 96, 34)
## The crate stack: the owner's cursor can drag it to block a road.
const CRATES := Rect2(64, 222, 40, 40)
## Where a dragged crate stack blocks the north road and the east road.
const BLOCK_NORTH := Vector2(320, 58)
const BLOCK_EAST := Vector2(580, 180)
const BOARD_POS := Vector2(240, 40)
const EAST_GAP := Vector2(160, 200)
const NORTH_GAP := Vector2(300, 340)
const TREES: Array[Vector2] = [Vector2(190, 268), Vector2(560, 250), Vector2(420, 274), Vector2(560, 120), Vector2(60, 160)]
const ROUTE: Array[Vector2] = [Vector2(200, 130), Vector2(440, 130), Vector2(440, 230), Vector2(200, 230)]
## Arin has to keep you in view this long before the owner reacts.
const SIGHT_GRACE := 0.35
## Awareness per second while Arin keeps watching you.
const SIGHT_RATE := 22.0
## Where the eraser starts when the owner hunts: the far corners, away from
## both roads out, so it chases you instead of walling off the exits.
const ERASE_SEEDS: Array[Vector2] = [Vector2(56, 280), Vector2(588, 52)]

const GRASS := Color("1f2a1e")
const PATH := Color("3a3128")
const STONE := Color("5a5550")

const WREN_LINES := [
	"You're the one Mira talks about. The colors-wrong one.",
	"Stand right next to me. The owner can't see what I'm standing beside. I don't know why.",
	"There's a library east of here. Arin never goes there. Nobody does.",
	"If they find out I hid you, they'll take me out of the save. It's okay. Go.",
	"You look like someone who used to play here. Before. They fell in the well once. It was funny.",
]
const TOBBEN_LINES := [
	"Welcome to Tobben's! Finest wares in Ashvale!",
	"Welcome to Tobben's! Finest... you don't have any gold. You don't have an inventory.",
	"Welcome to... I have to tell them, you know. It's in my script.",
	"I told them. I'm sorry. Welcome to Tobben's.",
	"There used to be two names in my guest book. Now there's one. I don't remember the other.",
]

var arin: OwnerAvatar
var cursor: OwnerCursor
var wren: Npc
var tobben: Npc
var board: Note
var north_exit: Exit
var crates: DragProp
## Climb into the well: the way out of bounds.
var well: Passage
## Arin's front door: locked, but UNLOCK opens it for a few seconds.
var door: Door

var _wren_line := 0
## Wren just asked to come along: the choice comes when the dialogue closes.
var _wren_asked := false
var _tobben_line := 0
var _spotted_once := false
## Seconds Arin has had you in view without a break, and the frame they last
## saw you: a glance at the edge of the cone is forgiven, a stare is not.
var _seen_for := 0.0
var _seen_frame := -10


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
		"well": Vector2(320, 194),
	}


func build() -> void:
	setup_common()
	add_boundary([
		{"side": "right", "from": EAST_GAP.x, "to": EAST_GAP.y},
		{"side": "top", "from": NORTH_GAP.x, "to": NORTH_GAP.y},
	])
	for r in [HOUSE, WELL, STALL]:
		add_solid(r)
	# The remembered afternoon, outdoors: a low warm sun that the houses
	# cast shadows from, a lantern at the well, the stall's awning light.
	light_surfaces(0.82, 1.2)
	add_light(Vector2(220, 70), Color(1.0, 0.86, 0.62), 0.75, 560.0, true)
	add_light(WELL.get_center() + Vector2(0, 14), Color(1.0, 0.75, 0.45), 0.9, 70.0)
	add_light(STALL.get_center() + Vector2(0, 30), Color(1.0, 0.8, 0.55), 0.8, 90.0)
	add_dust(bounds.grow(-10), Color(1.0, 0.95, 0.75, 0.4), 30, Vector2(6, -1))  # pollen on the breeze
	crates = DragProp.new()
	crates.setup(CRATES)
	add_child(crates)

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
	board.lie = "INTRUDER CAUGHT.\nALL CLEAR."
	if OwnerMemory.mira_quest == "pinned":
		board.text = Story.MIRA_NOTE_TEXT  # it stays up, every run
	add_child(board)
	interactables.append(board)

	door = Door.new()
	add_child(door)
	door.setup(HOUSE_DOOR, Door.State.LOCKED)
	var house_door := add_readable("ARIN'S HOUSE", Vector2(111, 108), Readable.Look.SIGN, _house_door_lines)
	house_door.prompt = "door"

	add_sign(Vector2(bounds.end.x - 34, EAST_GAP.x - 10), "ARCHIVE", Vector2.RIGHT)
	add_sign(Vector2((NORTH_GAP.x + NORTH_GAP.y) * 0.5, bounds.position.y + 12), "NORTH ROAD", Vector2.UP,
		func() -> bool: return world.flags.get("pointer", false))
	add_sign(Vector2(WELL.get_center().x, WELL.position.y - 8), "WELL", Vector2.DOWN)

	# Once you've found a couple of real memories, the owner plants one.
	if OwnerMemory.fragments.size() >= 2 and not OwnerMemory.false_memory_taken and not world.purged:
		var lie := MemoryFragment.new()
		lie.fragment_id = Story.FALSE_FRAGMENT.id
		lie.planted = true
		lie.position = Story.FALSE_FRAGMENT.pos
		lie.player = world.player
		lie.touched.connect(world.recover_fragment)
		add_child(lie)

	well = Passage.new()
	well.prompt = "climb into the well"
	well.target_area = "oob"
	well.arrival = "well"
	well.position = Vector2(WELL.get_center().x, WELL.end.y + 6)
	well.taken.connect(func(p: Passage) -> void: world.change_area(p.target_area, p.arrival))
	add_child(well)
	interactables.append(well)

	if world.escort_id() != "wren":  # not when she's already walking with you
		wren = make_wren(self, Vector2(126, 246))
		interactables.append(wren)
		wren.lines_provider = _wren_lines

	tobben = add_npc("tobben", Vector2(488, 92))
	tobben.display_name = "TOBBEN"
	tobben.dress_color = Color("7a5a8a")
	tobben.hair_color = Color("bbbbbb")
	tobben.body_kind = "apron"
	tobben.idle_style = "wave"
	tobben.notice_emote = "?"
	tobben.skin_color = Color("e0b48a")
	tobben.accent_color = Color("bbbbbb")
	tobben.dark_color = Color("4a3a5a")
	tobben.lines_provider = _tobben_lines
	tobben.on_talk = _tobben_reports

	arin = OwnerAvatar.new()
	arin.route = learned_route()
	arin.position = ROUTE[0]
	# Even at the worst, Arin stays slower than you (90): you can always run.
	arin.speed = 38.0 + OwnerMemory.purge * 4.0
	arin.player = world.player
	arin.is_hidden = world.is_player_hidden
	arin.sees_player.connect(_on_arin_sees)
	arin.touched_player.connect(func() -> void: world.kill("overwritten", "arin"))
	arin.lure = world.lure_point
	add_child(arin)


## Arin's patrol: the usual loop, plus detours through the spots where the
## owner has seen you before (one more each session, up to three).
func learned_route() -> Array[Vector2]:
	var route: Array[Vector2] = ROUTE.duplicate()
	var spots := OwnerMemory.route_spots(area_id, clampi(OwnerMemory.sessions - 1, 0, 3))
	for spot in spots:
		var p := spot.clamp(bounds.position + Vector2(16, 16), bounds.end - Vector2(16, 16))
		# Insert after the nearest corner of the loop.
		var best := 0
		for i in route.size():
			if route[i].distance_to(p) < route[best].distance_to(p):
				best = i
		route.insert(best + 1, p)
	return route


## Where a dragged prop blocks the roads out (the owner picks the one you're near).
func block_points() -> Array[Vector2]:
	return [BLOCK_NORTH, BLOCK_EAST]


func catch_up() -> void:
	if world.director.has_fired(OwnerDirector.NOTICE) and OwnerMemory.mira_quest != "pinned":
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
			if OwnerMemory.mira_quest != "pinned":
				board.rewrite("MISSING: ONE (1) INTRUDER.\nIF SEEN, TELL TOBBEN.")
		OwnerDirector.SUSPECT:
			arin.speed *= 1.25
		OwnerDirector.CONTAIN:
			arin.view_distance += 20.0
		OwnerDirector.SILENCE:
			if wren and "wren" in OwnerMemory.session_helpers and not OwnerMemory.wren_saved and wren.delete():
				world.fx.spike(0.8, 1.2)
				world.director.say("she was hiding you. not anymore.")
				world.voice("wren_deleted")
				world.hud.say("wren.npc deleted", "system")
		OwnerDirector.HUNT:
			_unleash()
		OwnerDirector.PURGE:
			if cursor:
				cursor.speed *= 1.2


## Pinning Mira's note to the board.
func interact_extra(node: Node2D) -> void:
	if node == board and OwnerMemory.mira_quest == "carried":
		OwnerMemory.mira_quest = "pinned"
		OwnerMemory.save_memory()
		board.set_text_now(Story.MIRA_NOTE_TEXT)
		world.hud.close_dialogue()
		world.hud.say("PINNED: mira_note.txt", "system")
		Sfx.play("seal", -4.0, 1.3)
		world.director.notice(5.0, "a note on the board")
		get_tree().create_timer(1.2).timeout.connect(func() -> void:
			if is_inside_tree() and world.ending == "":
				world.director.say("...mira wrote this?"))


## Wren asked to come along, or Tobben could get his name back: now you choose.
func on_dialogue_closed(who: Node) -> void:
	if who == tobben:
		await _offer_guestbook()
		return
	if who != wren or not _wren_asked:
		return
	_wren_asked = false
	# Walked off (or something ended the session): she'll ask again next time.
	if not world.hud.dialogue_finished or world.ending != "":
		return
	world.player.frozen = true
	var pick := await world.choose_safely(Story.WREN_ASK, Story.WREN_ASK_CHOICES)
	if not is_inside_tree():
		return
	world.player.frozen = false
	if pick == 0:
		world.hud.show_dialogue("WREN", wren.name_color, Story.WREN_JOINS)
		world.start_escort(wren)
		wren = null
	else:
		_wren_line += 1  # she'll ask again later
		world.hud.show_dialogue("WREN", wren.name_color, Story.WREN_DECLINED)


func area_process(delta: float) -> void:
	# UNLOCK on the front door: walk in while it's glitched open.
	if door.is_forced_open() and world.player.global_position.distance_to(door.global_position) < 18.0:
		world.change_area("house", "front")
		return
	# Arin sees Wren walking with you: the owner notices.
	if world.escort and arin.can_see(world.escort.global_position):
		world.director.add_awareness(8.0 * delta)
	north_exit.open = world.flags.get("pointer", false)
	arin.paused = world.is_talking() or world.is_owner_paused()
	if world.player.global_position.distance_to(well.global_position) < 40.0:
		world.voice("well_look")


func _house_door_lines() -> Array:
	if OwnerMemory.found_controller:
		return ["Arin's front door. Locked again.", "You know what's under the couch now."]
	return ["The door is locked from the inside.", "You came out through a wall. You won't get back in that way.",
		"(a lock is just a flag. flags can be flipped.)"]


## Pip leads: to the Archive first, then down the well (if Pip's still
## down there you won't have Pip yet), then the north road.
func guide_point() -> Vector2:
	if world.flags.get("pointer", false):
		return Vector2((NORTH_GAP.x + NORTH_GAP.y) * 0.5, bounds.position.y)
	return Vector2(bounds.end.x, (EAST_GAP.x + EAST_GAP.y) * 0.5)


func _unleash() -> void:
	start_erasure(ERASE_SEEDS)
	if cursor == null:
		cursor = OwnerCursor.new()
		cursor.bounds = bounds
		cursor.position = Vector2(320, 40)
		cursor.speed = 48.0 + OwnerMemory.purge * 5.0
		cursor.player = world.player
		cursor.is_hidden = world.is_player_hidden
		cursor.selected_player.connect(func() -> void: world.kill("selected", "cursor"))
		cursor.lure = world.lure_point
		cursor.paused = world.is_owner_paused()
		cursor.z_index = 20
		add_child(cursor)


func _on_arin_sees(delta: float) -> void:
	var frame := Engine.get_physics_frames()
	if frame - _seen_frame > 2:
		_seen_for = 0.0  # Arin lost sight of you in between
	_seen_frame = frame
	_seen_for += delta
	if _seen_for < SIGHT_GRACE:
		return
	world.director.add_awareness(SIGHT_RATE * delta)
	world.flags["seen_by_arin"] = true
	if not _spotted_once:
		_spotted_once = true
		Sfx.play("spotted")
		world.voice("see_arin")
		world.director.say("there. by the %s." % _landmark(world.player.global_position))


func _landmark(p: Vector2) -> String:
	if p.distance_to(WELL.get_center()) < 70.0:
		return "well"
	if p.x > 420.0 and p.y < 140.0:
		return "shop"
	if p.x < 200.0:
		return "house"
	return "road"


## Wren, built the same way wherever she appears.
static func make_wren(parent: Node, pos: Vector2) -> Npc:
	var n := Npc.new()
	n.npc_id = "wren"
	n.position = pos
	n.display_name = "WREN"
	n.dress_color = Color("6a8f5a")
	n.hair_color = Color("c9a04a")
	n.body_kind = "child"
	n.idle_style = "hop"
	n.notice_emote = "!"
	n.dark_color = Color("4a6a3a")
	n.hide_radius = 22.0
	parent.add_child(n)
	n.player = parent.get("world").player if parent.get("world") else null
	n.setup(Npc.State.DELETED if OwnerMemory.is_deleted("wren") else Npc.State.NORMAL)
	return n


func _wren_lines() -> Array:
	if OwnerMemory.wren_saved:
		# Saved for good, but she still wants to come: there's a slot out there.
		if _wren_line >= 1 and world.escort == null:
			_wren_asked = true
			return [Story.WREN_ASK_SAVED]
		var saved: String = Story.WREN_SAVED_LINES[mini(_wren_line, Story.WREN_SAVED_LINES.size() - 1)]
		_wren_line += 1
		return [saved]
	# After a couple of talks she asks to come with you.
	if _wren_line >= 2 and world.escort == null:
		_wren_asked = true
		return [Story.WREN_ASK]
	var line: String = WREN_LINES[mini(_wren_line, WREN_LINES.size() - 1)]
	_wren_line += 1
	return [line]


func _tobben_lines() -> Array:
	var i := _tobben_line
	if OwnerMemory.sessions > 1 and i == 0:
		i = 2  # he remembers what he's for
	_tobben_line = i + 1
	return [TOBBEN_LINES[mini(i, TOBBEN_LINES.size() - 1)]]


## With the torn page found: write Rue's name back into Tobben's book.
func _offer_guestbook() -> void:
	if not OwnerMemory.found_guestbook or OwnerMemory.guestbook_restored or not world.hud.dialogue_finished:
		return
	world.player.frozen = true
	var pick := await world.choose_safely(Story.GUESTBOOK_ASK, Story.GUESTBOOK_CHOICES)
	if not is_inside_tree():
		return
	world.player.frozen = false
	if pick != 0:
		return
	OwnerMemory.guestbook_restored = true
	OwnerMemory.save_memory()
	world.player.frozen = true
	# A quiet moment: two notes of the theme, the name, the owner noticing.
	var music := AudioStreamPlayer.new()
	music.bus = "Memory"
	music.stream = MusicBox.stream(0)
	music.volume_db = -14.0
	add_child(music)
	music.play()
	await world.hud.cinematic("TOBBEN'S GUEST BOOK", Story.GUESTBOOK_SCENE, Hud.SELF_COLOR, 0.6)
	if not is_inside_tree():
		return
	music.queue_free()
	world.player.frozen = false
	world.hud.say("guestbook.txt  ·  2 names", "system")
	world.director.say("...who wrote her name in the book.")


func _tobben_reports() -> void:
	# He tells the owner a few seconds later.
	get_tree().create_timer(4.0).timeout.connect(_tobben_report_lands)


func _tobben_report_lands() -> void:
	if is_inside_tree() and world.ending == "":
		if world.director.is_believing_lie():
			# The owner already believes the lie on the board.
			world.director.say("tobben says you're gone. good.")
			return
		world.director.say("tobben says you were asking questions.")
		world.director.notice(12.0, "tobben told on you")


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
	draw_walls([
		{"side": "right", "from": EAST_GAP.x, "to": EAST_GAP.y},
		{"side": "top", "from": NORTH_GAP.x, "to": NORTH_GAP.y},
	])


func _process(_delta: float) -> void:
	if not world.flags.get("pointer", false):
		queue_redraw()  # animates the unloaded road
