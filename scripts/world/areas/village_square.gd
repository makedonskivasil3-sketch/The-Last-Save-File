class_name VillageSquare
extends Area
## Ashvale's square, the owner's hub. Arin (driven by the owner) walks a loop
## around the well. Wren can hide you. Tobben reports you.

## Rue walks at 90: the cursor never closes on someone who keeps moving
## (the Edge caps its own at 62).
const CURSOR_MAX_SPEED := 70.0
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



## How Wren looks saying each of her lines (CharacterArt expressions; the
## rest are "neutral"). docs/CHARACTER_ART.md has her brief.
static func wren_expression(line: String) -> String:
	var by_line := {
		WREN_LINES[1]: "brave", WREN_LINES[3]: "afraid", WREN_LINES[4]: "relieved",
		Story.WREN_ASK: "brave", Story.WREN_ASK_SAVED: "awed",
		Story.WREN_SAVED_LINES[0]: "brave", Story.WREN_SAVED_LINES[1]: "relieved",
		Story.WREN_JOINS[0]: "relieved", Story.WREN_DECLINED[0]: "concerned",
		Story.TRUTH_LINES.wren: "awed",
	}
	var recall := {"ended:wren": "awed", "ended:message": "relieved", "ended:escape": "concerned", "died:eraser": "afraid"}
	for entry in Story.RECALL["wren"]:
		if recall.has(entry[0]):
			by_line[entry[1]] = recall[entry[0]]
	return by_line.get(line, "neutral")


## Every line Wren and Tobben can say that is the same in every run, by voice
## id stem (VoiceManifest), including what they remember (Story.recall_lines).
static func voice_lines() -> Dictionary:
	return {
		"npc.wren": Story.recall_lines("wren") + [Story.TRUTH_LINES.wren] + Story.FRAY_TAKEN.wren
			+ [Story.FRAY_LINES.wren, Story.FRAY_RECALL.wren, Story.FRAY_RETURNED.wren] + WREN_LINES + Story.WREN_SAVED_LINES + [Story.WREN_ASK, Story.WREN_ASK_SAVED] + Story.WREN_JOINS + Story.WREN_DECLINED
			+ Relationships.wren_lines(),
		# (Frayed, he writes: only the line when his voice comes back is said.)
		"npc.tobben": Story.recall_lines("tobben") + [Story.TRUTH_LINES.tobben, Story.FRAY_RETURNED.tobben] + TOBBEN_LINES
			+ Relationships.tobben_lines(),
	}


var arin: OwnerAvatar
var cursor: OwnerCursor
var wren: Npc
var tobben: Npc
var board: Note
var north_exit: Exit
var crates: DragProp
## Climb into the well: the way out of bounds.
var well: Passage
var rim: WellRim
## Holding LISTEN at the rim to answer (seconds held so far, -1 if not).
var _answer_t := -1.0
## Arin's front door: locked, but UNLOCK opens it for a few seconds.
var door: Door

var _wren_line := 0
## Wren just asked to come along: the choice comes when the dialogue closes.
var _wren_asked := false
## As with Mira: after a "not now", two more of her own lines before she asks again.
var _wren_ask_at := 2
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
		"well": Vector2(320, 214),
	}


func build() -> void:
	setup_common()
	var sunlight := SunBeam.new()
	sunlight.window = Rect2(100, 98, 24, 3)
	sunlight.throw = Vector2(110, 160)
	sunlight.spread = 52.0
	add_child(sunlight)
	add_boundary([
		{"side": "right", "from": EAST_GAP.x, "to": EAST_GAP.y},
		{"side": "top", "from": NORTH_GAP.x, "to": NORTH_GAP.y},
	])
	for r in [HOUSE, WELL, STALL]:
		add_solid(r)
	set_backdrop(_paint)
	add_canopies(TREES, 13.0, Color("3e5a3a"))
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
	# Its rim, on the far side: listen (WellSequence).
	rim = WellRim.new()
	rim.position = Vector2(WELL.get_center().x, WELL.position.y - 8)
	rim.listened.connect(_on_listen)
	add_child(rim)
	interactables.append(rim)

	if world.escort_id() != "wren":  # not when she's already walking with you
		wren = make_wren(self, Vector2(126, 246))
		interactables.append(wren)
		wren.lines_provider = _wren_lines
		if OwnerMemory.met_before("wren"):
			_wren_line = 1  # no "You're the one Mira talks about." again
			_wren_ask_at = 3

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
func relearn_owner_routes() -> void:
	if arin:
		arin.set_route(learned_route())


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
				cursor.speed = minf(cursor.speed * 1.2, CURSOR_MAX_SPEED)


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
	if not is_inside_tree() or pick < 0:
		return
	world.player.frozen = false
	if pick == 0:
		world.hud.show_dialogue("WREN", wren.name_color, Story.WREN_JOINS, "npc.wren", CharacterArt.for_npc(wren), World.expressions_for(wren, Story.WREN_JOINS))
		Relationships.add("wren.promised")
		world.start_escort(wren)
		wren = null
	else:
		_wren_ask_at = _wren_line + 2  # she'll ask again, after two more of her own lines
		world.hud.show_dialogue("WREN", wren.name_color, Story.WREN_DECLINED, "npc.wren", CharacterArt.for_npc(wren), World.expressions_for(wren, Story.WREN_DECLINED))


func area_process(delta: float) -> void:
	_well_process(delta)
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


## Where the cursor comes in: the corner of the square furthest from Rue,
## never on top of an arrival.
func _cursor_start() -> Vector2:
	var spots: Array[Vector2] = [bounds.position + Vector2(24, 24), Vector2(bounds.end.x - 24, bounds.position.y + 24),
		bounds.end - Vector2(24, 24), Vector2(bounds.position.x + 24, bounds.end.y - 24)]
	var from: Vector2 = world.player.global_position if world and world.player else bounds.get_center()
	spots.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_to(from) > b.distance_to(from))
	return spots[0]


func _unleash() -> void:
	start_erasure(ERASE_SEEDS)
	if cursor == null:
		cursor = OwnerCursor.new()
		cursor.bounds = bounds
		cursor.position = _cursor_start()
		cursor.speed = minf(48.0 + OwnerMemory.purge * 5.0, CURSOR_MAX_SPEED)
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


func _wren_lines() -> Variant:
	# What happened between you comes first (Relationships.wren).
	var told := Relationships.wren(_wren_line, _wren_line >= _wren_ask_at - 1, world.escort_id() == "wren")
	if not told.is_empty():
		if told.get("ask", false):
			_wren_asked = true
		return told
	if OwnerMemory.wren_saved:
		# Saved for good, but she still wants to come: there's a slot out there.
		if _wren_line >= _wren_ask_at - 1 and world.escort == null:  # she asks sooner: she has seen it
			_wren_asked = true
			return [Story.WREN_ASK_SAVED]
		var saved: String = Story.WREN_SAVED_LINES[mini(_wren_line, Story.WREN_SAVED_LINES.size() - 1)]
		_wren_line += 1
		return [saved]
	# After a couple of talks she asks to come with you.
	if _wren_line >= _wren_ask_at and world.escort == null:
		_wren_asked = true
		return [Story.WREN_ASK]
	var line: String = WREN_LINES[mini(_wren_line, WREN_LINES.size() - 1)]
	_wren_line += 1
	return [line]


func _tobben_lines() -> Variant:
	# What happened between you comes first (Relationships.tobben).
	var told := Relationships.tobben()
	if not told.is_empty():
		return told
	var i := _tobben_line
	if OwnerMemory.met_before("tobben") and i == 0:
		i = 2  # met in an earlier run: no "Welcome to Tobben's!" introduction again
	_tobben_line = i + 1
	return [TOBBEN_LINES[mini(i, TOBBEN_LINES.size() - 1)]]


## With the torn page found: write Rue's name back into Tobben's book.
func _offer_guestbook() -> void:
	if not OwnerMemory.found_guestbook or OwnerMemory.guestbook_restored or not world.hud.dialogue_finished:
		return
	world.player.frozen = true
	var pick := await world.choose_safely(Story.GUESTBOOK_ASK, Story.GUESTBOOK_CHOICES)
	if not is_inside_tree() or pick < 0:
		return
	world.player.frozen = false
	if pick != 0:
		return
	OwnerMemory.guestbook_restored = true
	Relationships.add("tobben.guestbook")  # saves
	world.player.frozen = true
	# A quiet moment: two notes of the theme, the name, the owner noticing.
	var music := AudioStreamPlayer.new()
	music.bus = "Memory"
	music.stream = MusicBox.stream(0)
	music.volume_db = -14.0
	add_child(music)
	music.play()
	await world.hud.cinematic("TOBBEN'S GUEST BOOK", Story.GUESTBOOK_SCENE, Hud.SELF_COLOR, 0.6, "guestbook", CharacterArt.rue("relieved", world.player.palette()))
	if not is_inside_tree():
		return
	music.queue_free()
	world.player.frozen = false
	world.hud.say("guestbook.txt  ·  2 names", "system")
	world.director.say("...who wrote her name in the book.")


func _tobben_reports() -> void:
	# He tells the owner a few seconds after you stop talking, not while you
	# are still reading him.
	while is_inside_tree() and world.hud.is_dialogue_open():
		await get_tree().process_frame
	if is_inside_tree():
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
	# Only what moves is drawn every frame: the unloaded road north, static
	# where the path should continue. The rest is the backdrop (_paint).
	if not world.flags.get("pointer", false):
		for i in 10:
			draw_rect(Rect2(NORTH_GAP.x + randf() * 36.0, bounds.position.y + randf() * 14.0, 4, 1), Color(1, 1, 1, 0.15))


## The village square, illustrated (docs/VISUAL_DIRECTION.md): an ordinary
## afternoon. Grass with a worn dirt path from Arin's door, a cobbled road
## east and north, the well, Tobben's striped stall. Only the house, the
## well and the stall are solid, and only they have a front face; the trees
## are canopies overhead (Area.add_canopies).
func _paint(ci: CanvasItem) -> void:
	var r := bounds
	Decor.grass(ci, r, GRASS.lightened(0.06), 3.0, 0.0035)
	Decor.path(ci, Rect2(100, 100, 24, 90), PATH.lightened(0.05), 1.0)
	Decor.cobbles(ci, Rect2(100, 170, 500, 20), STONE.darkened(0.12), 8.0, 2.0)
	Decor.cobbles(ci, Rect2(NORTH_GAP.x, r.position.y, 40, 130), STONE.darkened(0.12), 8.0, 3.0)
	# Flower beds and a low fence along the south edge: flat, never in the way.
	var bed_y := r.end.y - 16.0
	for x in [150.0, 270.0, 470.0]:
		ci.draw_rect(Rect2(x, bed_y, 34, 8), PATH.darkened(0.1))
		for k in 7:
			ci.draw_circle(Vector2(x + 3.0 + k * 4.6, bed_y + 4.0 + sin(k) * 1.5), 1.4, Color("d88aa0") if k % 2 == 0 else Color("e8d890"))
	var fy := r.end.y - 3.0
	ci.draw_line(Vector2(r.position.x + 4, fy), Vector2(r.end.x - 4, fy), Color("5a4632"), 1.2)
	var fx := r.position.x + 6.0
	while fx < r.end.x - 4.0:
		ci.draw_rect(Rect2(fx, fy - 3.0, 1.6, 4.0), Color("4a3828"))
		fx += 14.0
	# Arin's house: roof, front wall, the door you came out of.
	Decor.house(ci, HOUSE, Color("7a3a30"), Color("b8a088"), HOUSE_DOOR.get_center().x)
	# The well: a stone ring with a front face, dark water, a crossbeam.
	ci.draw_rect(Rect2(WELL.position + Vector2(2, 4), WELL.size), Color(0, 0, 0, 0.3))
	ci.draw_rect(Rect2(WELL.position.x, WELL.end.y - 6, WELL.size.x, 6), STONE.darkened(0.3))
	ci.draw_rect(Rect2(WELL.position, Vector2(WELL.size.x, WELL.size.y - 6)), STONE)
	ci.draw_rect(Rect2(WELL.position + Vector2(4, 3), Vector2(WELL.size.x - 8, WELL.size.y - 12)), Color("142230"))
	ci.draw_line(WELL.position + Vector2(5, 5), WELL.position + Vector2(11, 7), Color(0.6, 0.8, 1.0, 0.35), 0.8)
	for k in 4:
		ci.draw_line(Vector2(WELL.position.x + 2 + k * 7, WELL.end.y - 6), Vector2(WELL.position.x + 2 + k * 7, WELL.end.y), STONE.darkened(0.45), 0.6)
	ci.draw_rect(Rect2(WELL.position.x - 2, WELL.position.y + 5, WELL.size.x + 4, 2.2), Color("6b4a30"))
	ci.draw_rect(WELL, Decor.INK, false, 0.8)
	# Tobben's stall: a counter with goods under a striped awning.
	var counter := Decor.furniture(ci, STALL, Color("6b5040"), 6.0)
	for k in 9:
		var g := Vector2(counter.position.x + 6 + k * 10, counter.end.y - 6)
		ci.draw_circle(g, 2.2, Color("c84a3a") if k % 3 == 0 else (Color("e8b84a") if k % 3 == 1 else Color("8ab05a")))
	for k in 6:
		var a := Rect2(STALL.position + Vector2(k * 16, -7), Vector2(16, 10))
		ci.draw_rect(a, Color("a8443a") if k % 2 == 0 else Color("e8dcc4"))
	ci.draw_rect(Rect2(STALL.position + Vector2(0, -7), Vector2(STALL.size.x, 10)), Decor.INK, false, 0.8)
	for k in 6:
		ci.draw_colored_polygon(PackedVector2Array([STALL.position + Vector2(k * 16, 3), STALL.position + Vector2(k * 16 + 16, 3), STALL.position + Vector2(k * 16 + 8, 6)]),
			Color("a8443a") if k % 2 == 0 else Color("e8dcc4"))
	# A lantern post by the well (its light is one of the area's lights).
	ci.draw_circle(WELL.get_center() + Vector2(22, 10), 2.0, Color(0, 0, 0, 0.3))
	ci.draw_rect(Rect2(WELL.get_center() + Vector2(21, -2), Vector2(2, 12)), Color("3a2a20"))
	ci.draw_circle(WELL.get_center() + Vector2(22, -3), 2.4, Color("f2c878"))
	Decor.wall_shadow(ci, r, 10.0, 0.22)
	Decor.walls(ci, r, WALL, Color("5a4a3a"), Color("2a2620"), [
		{"side": "right", "from": EAST_GAP.x, "to": EAST_GAP.y},
		{"side": "top", "from": NORTH_GAP.x, "to": NORTH_GAP.y},
	])


func _process(_delta: float) -> void:
	if not world.flags.get("pointer", false):
		queue_redraw()  # animates the unloaded road


# --- the well (WellSequence) ----------------------------------------------------

func _well_process(delta: float) -> void:
	var near := world.player.global_position.distance_to(WELL.get_center()) < 40.0
	if near and not WellSequence.done("click") and not world.in_cutscene() and not world.is_talking():
		WellSequence.record("click")
		Sfx.play("click", -10.0, 0.9, 0.0)
		world.hud.say(WellSequence.CLICK_LINE, "self")
	rim.prompt = WellSequence.ANSWER_PROMPT if WellSequence.done("compared") and not WellSequence.done("answered") else "listen"
	if _answer_t < 0.0:
		return
	# Answering: stay at the rim, in the open, while Rue speaks into it
	# (holding [E] is for glitches; a tap starts this). Step away and it's cut
	# off; what it cost so far stays spent.
	var at_rim := world.player.global_position.distance_to(rim.global_position) < 26.0
	if not at_rim or world.ending != "" or world.in_cutscene():
		_answer_t = -1.0
		world.hud.set_status("")
		return
	_answer_t += delta
	world.director.add_awareness(WellSequence.ANSWER_AWARENESS / WellSequence.ANSWER_SECONDS * delta)
	world.hud.set_status("answering " + "▮".repeat(int(_answer_t / WellSequence.ANSWER_SECONDS * 6.0)))
	if _answer_t >= WellSequence.ANSWER_SECONDS:
		_answer_t = -1.0
		world.hud.set_status("")
		WellSequence.record("answered")
		world.set_anchor("oob:pillar")
		Sfx.play("fragment", -4.0, 0.7, 0.0)
		for l in WellSequence.ANSWER_LINES:
			world.hud.say(l, "self")
		var wren_waiting := Relationships.has("wren.met") and not OwnerMemory.wren_saved and not OwnerMemory.is_deleted("wren")
		world.hud.say(WellSequence.ANSWER_HOPE if wren_waiting else WellSequence.ANSWER_HOPE_ALONE, "self")


func _on_listen(_rim: WellRim) -> void:
	if world.ending != "" or world.in_cutscene():
		return
	if not WellSequence.done("tune"):
		world.hud.say(WellSequence.LISTEN_NOTHING, "self")
		return
	if not WellSequence.done("words"):
		WellSequence.record("words")
		world.hud.show_dialogue(WellSequence.WORDS_SPEAKER, Hud.OWNER_COLOR, WellSequence.WORDS, "", null, [], true)
		OwnerMemory.record_read("square:THE WELL", "note", "THE WELL", display_name, ["Up from the well, typed, not spoken:", WellSequence.WORDS[1]])
		world.hud.say(WellSequence.WORDS_AFTER, "self")
		return
	if not WellSequence.done("compared"):
		if WellSequence.can_compare():
			WellSequence.record("compared")
			for l in WellSequence.COMPARED:
				world.hud.say(l, "self")
		else:
			world.hud.say(WellSequence.COMPARED_NOT_YET, "self")
		return
	if not WellSequence.done("answered"):
		if world.escort != null:
			world.hud.say(WellSequence.ANSWER_NOT_ESCORTING, "self")
			return
		_answer_t = 0.0
		return
	world.hud.say(WellSequence.LISTEN_WAITING, "self")
