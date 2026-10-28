class_name VillageSquare
extends Area
## Ashvale's square, the owner's hub. Arin (driven by the owner) walks a loop
## around the well. Wren can hide you. Tobben reports you.
##
## Wider than the screen (docs/VERTICAL_SLICE.md §3c): the camera follows Rue
## east from the old square (arrival, the well, Wren, Tobben's) across an
## exposed crossing the owner watches through a sweeping lamp, past a
## covered bench to hide under, to the Archive's front and the road under
## its arch. Behind Tobben's a fenced lane runs east, sheltered, to a gate
## latched on the lane side: lifted once, it stays open (the shortcut).

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
const BLOCK_EAST := Vector2(898, 180)
const BOARD_POS := Vector2(240, 40)
const EAST_GAP := Vector2(160, 200)
const NORTH_GAP := Vector2(300, 340)
const TREES: Array[Vector2] = [Vector2(190, 268), Vector2(560, 250), Vector2(420, 274), Vector2(566, 132), Vector2(60, 160),
	Vector2(840, 262), Vector2(616, 270)]
## The lamp is a warning more than a hunter: a longer grace than Arin's look
## and a quarter of his rate, so crossing on the road costs little and
## lingering in the beam costs a lot (balance: VERTICAL_SLICE.md §3c).
const LAMP_GRACE := 0.6
const LAMP_RATE := 6.0
## Where the lamp's sweep starts once the lane gate is open (it covers the
## gate's mouth as well as the crossing).
const LAMP_GATE_ARC := -0.25
## The east half (docs/VERTICAL_SLICE.md §3c).
## The crossing: open cobbles, no cover, the lamp's beam.
const CROSSING := Rect2(600, 118, 190, 124)
const LAMP_POS := Vector2(668, 114)
## The covered bench on the crossing's south side: the awning hides you.
const RECESS := Rect2(708, 248, 52, 32)
## The Archive's front, over the road out east (the landmark).
const LIBRARY := Rect2(790, 36, 130, 66)
## The lane behind Tobben's, its fence, and the gate at its east end.
const LANE := Rect2(540, 40, 250, 58)
const FENCE_Y := 98.0
const GATE := Rect2(740, 98, 34, 6)
## The Archive's gatehouse over the road out east: its two piers are solid,
## the passage between them (EAST_GAP) is the way in.
const GATEHOUSE_N := Rect2(884, 102, 36, 54)
const GATEHOUSE_S := Rect2(884, 206, 36, 86)
const ROUTE: Array[Vector2] = [Vector2(200, 130), Vector2(440, 130), Vector2(440, 230), Vector2(200, 230)]
## Arin has to keep you in view this long before the owner reacts.
const SIGHT_GRACE := 0.35
## Awareness per second while Arin keeps watching you.
const SIGHT_RATE := 22.0
## Where the eraser starts when the owner hunts: the far corners, away from
## both roads out, so it chases you instead of walling off the exits.
const ERASE_SEEDS: Array[Vector2] = [Vector2(56, 280), Vector2(820, 280)]

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
## Wren's wave, when Arin comes and Rue is in the open near her (before
## she has ever explained why standing beside her works).
const WREN_BECKON := "here!"
const BECKON_ARIN := 150.0
const BECKON_RUE := 110.0
## Her shelter, and after the Edge (safe for good, out of the owner's reach):
## she can cover Rue from a little further out.
const WREN_SHELTER := 22.0
const WREN_SHELTER_SAFE := 30.0
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
var lamp: OwnerLamp
var gate: LaneGate
## The checkpoint scene (Relationships.WREN_MARKED): Wren waits at the rim.
const WREN_AT_WELL := Vector2(342, 194)
var _marking := false
var _mark_started := false
var _lamp_seen_for := 0.0
var _lamp_seen_frame := -10
var _lamp_spotted := false
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
## Wren just offered her chalk (Relationships._wren_own): ask when her box closes.
var _wren_offer := false
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
	bounds = Rect2(40, 36, 880, 256)
	view_size = Vector2(960, 360)
	awareness_rate = 1.0
	tint = Color(0.95, 0.95, 1.0)
	entries = {
		"house": Vector2(111, 118),
		"east": Vector2(898, 180),
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
	for r in [HOUSE, WELL, STALL, LIBRARY, GATEHOUSE_N, GATEHOUSE_S]:
		add_solid(r)
	# The lane's fence, either side of its gate.
	add_solid(Rect2(LANE.position.x, FENCE_Y, GATE.position.x - LANE.position.x, GATE.size.y))
	add_solid(Rect2(GATE.end.x, FENCE_Y, LANE.end.x - GATE.end.x, GATE.size.y))
	set_backdrop(_paint)
	add_canopies(TREES, 13.0, Color("3e5a3a"))
	# The remembered afternoon, outdoors: a low warm sun that the houses
	# cast shadows from, a lantern at the well, the stall's awning light.
	light_surfaces(0.82, 1.2)
	add_light(Vector2(220, 70), Color(1.0, 0.86, 0.62), 0.75, 560.0, true)
	add_light(WELL.get_center() + Vector2(0, 14), Color(1.0, 0.75, 0.45), 0.9, 70.0)
	add_light(STALL.get_center() + Vector2(0, 30), Color(1.0, 0.8, 0.55), 0.8, 90.0)
	add_light(Vector2(GATEHOUSE_N.get_center().x - 10, (EAST_GAP.x + EAST_GAP.y) * 0.5), Color(1.0, 0.82, 0.5), 0.9, 90.0)  # the gatehouse's lamp
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

	add_sign(Vector2(GATEHOUSE_N.position.x - 26, EAST_GAP.x - 10), "ARCHIVE", Vector2.RIGHT)
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
	well.object_name = "the well"
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
	# Wren's game: two places Rue might chalk (one is a real hiding place).
	for spot_id in CHALK_SPOTS:
		var spot := ChalkSpot.new()
		spot.id = spot_id
		spot.position = CHALK_SPOTS[spot_id]
		spot.chalked.connect(_on_chalked)
		add_child(spot)
		interactables.append(spot)
		_chalk_spots[spot_id] = spot
	_update_chalk_spots()

	# Back up the well after waking under it: Wren is waiting at the rim.
	_marking = arrival == "well" and world.woke_at_anchor and Relationships.has("wren.met") \
		and not Relationships.has("wren.marked_well") and not OwnerMemory.is_deleted("wren") and world.escort_id() != "wren"
	Relationships.wren_at_well = _marking
	if world.escort_id() != "wren":  # not when she's already walking with you
		wren = make_wren(self, WREN_AT_WELL if _marking else Vector2(126, 246))
		interactables.append(wren)
		wren.lines_provider = _wren_lines
		if OwnerMemory.met_before("wren"):
			_wren_line = 1  # no "You're the one Mira talks about." again
			_wren_ask_at = 3

	gate = LaneGate.new()
	gate.setup(GATE)
	gate.player = world.player
	add_child(gate)
	interactables.append(gate)

	lamp = OwnerLamp.new()
	lamp.position = LAMP_POS
	lamp.player = world.player
	lamp.is_hidden = world.is_player_hidden.bind("lamp")
	# Once the gate is open, the owner turns the lamp to cover it too: the
	# moment it opens (watched), and from then on (restored).
	if OwnerMemory.square_gate_open:
		lamp.widen_to(LAMP_GATE_ARC, 0.0)
	gate.opened.connect(_on_gate_opened)
	lamp.sees_player.connect(_on_lamp_sees)
	add_child(lamp)

	tobben = add_npc("tobben", Vector2(488, 92))
	tobben.display_name = "TOBBEN"
	tobben.dress_color = Color("7a5a8a")
	tobben.hair_color = Color("bbbbbb")
	tobben.body_kind = "apron"
	tobben.idle_style = "tend"  # at his wares; he still waves when you come close
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
	arin.is_hidden = world.is_player_hidden.bind("arin")
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


## Pinning Mira's note to the board (and, once she's asked, looking for her).
func interact_extra(node: Node2D) -> void:
	if node == board and OwnerMemory.mira_quest == "pinned" and OwnerMemory.has_conversation("mira.after_pinned") \
			and not Relationships.has("mira.board_checked"):
		Relationships.add("mira.board_checked")
		world.hud.say("(still up. i'll tell her.)", "self")
	if node == board and OwnerMemory.mira_quest == "carried":
		OwnerMemory.mira_quest = "pinned"
		OwnerMemory.save_memory()
		board.set_text_now(Story.MIRA_NOTE_TEXT)
		queue_redraw()
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
	if who == wren and _wren_offer:
		_wren_offer = false
		await _offer_chalk()
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


## Wren's chalk: so somebody remembers her (docs/production/WREN_ARC.md).
func _offer_chalk() -> void:
	if not world.hud.dialogue_finished or world.ending != "" or wren == null:
		return
	world.player.frozen = true
	var pick := await world.choose_safely(Relationships.chalk_ask(), Relationships.WREN_CHALK_CHOICES)
	if not is_inside_tree() or pick < 0 or wren == null:
		return
	world.player.frozen = false
	if pick == 0:
		Relationships.add("wren.chalk")
		var given: Array = Relationships.WREN_CHALK_GIVEN if Relationships.has("wren.marked_well") else Relationships.WREN_CHALK_GIVEN_NO_MARK
		world.hud.show_dialogue("WREN", wren.name_color, given, "npc.wren", CharacterArt.for_npc(wren), World.expressions_for(wren, given))
		world.hud.say("KEPT: WREN'S CHALK  ·  the well's rim", "system")
	else:
		Relationships.chalk_declined_session = OwnerMemory.sessions
		world.hud.show_dialogue("WREN", wren.name_color, Relationships.WREN_CHALK_LATER, "npc.wren", CharacterArt.for_npc(wren), World.expressions_for(wren, Relationships.WREN_CHALK_LATER))


# --- Wren's game (docs/production/WREN_ARC.md): chalk marks for good places ------

## Her corner, and her X beside it (where she stands: she hides you).
const WREN_HOME := Vector2(126, 246)
## Where Rue might chalk: under the awning (a real hiding place) or out on
## the crossing (the lamp sweeps it).
const CHALK_SPOTS := {"recess": Vector2(734, 266), "crossing": Vector2(660, 196)}
## Where Wren stands to look at each (beside it), and her way there.
const CHALK_LOOK := {"recess": Vector2(756, 270), "crossing": Vector2(678, 200)}
const WREN_WALK := 70.0
var _chalk_spots := {}
var _wren_path: Array[Vector2] = []
var _wren_arrived: Callable
## The mark she is standing at, waiting to give her verdict ("" if none).
var _wren_at_spot := ""
var _game_nudged := false
var _nodded := false


## Rue's mark waiting for Wren to see it ("" if none).
static func pending_mark() -> String:
	if Relationships.has("wren.mark_ok") or not Relationships.has("wren.game"):
		return ""
	if Relationships.has("wren.mark_recess"):
		return "recess"
	if Relationships.has("wren.mark_crossing") and not Relationships.has("wren.mark_refused"):
		return "crossing"
	return ""


func _update_chalk_spots() -> void:
	var playing := Relationships.has("wren.game") and pending_mark() == "" and not Relationships.has("wren.mark_ok")
	for spot_id in _chalk_spots:
		var spot: ChalkSpot = _chalk_spots[spot_id]
		spot.active = playing and not (spot_id == "crossing" and Relationships.has("wren.mark_refused"))
	queue_redraw()


func _on_chalked(spot: ChalkSpot) -> void:
	if world.ending != "" or world.is_talking():
		return
	Relationships.add("wren.mark_" + spot.id)
	Sfx.play("seal", -10.0, 1.8)
	world.hud.say("(an R. she said a mark. it's my mark.)" if spot.id == "recess" else "(there. an R. a mark's a mark.)", "self")
	_update_chalk_spots()


## Her game's lines at her corner ({} when there's nothing). It starts once
## she has introduced herself (her lantern line) and isn't about to ask to
## see the Edge: her own introduction and her quest come first.
## Her game (WREN_ARC.md). It starts the talk after her lantern line: before
## her ask to see the Edge, so a player who takes her along has played it
## first (when the ask came first, most players left the square with her
## and never saw it). It doesn't need her to have hidden Rue yet.
func _chalk_game_lines() -> Dictionary:
	if wren == null or OwnerMemory.is_deleted("wren"):
		return {}
	if not Relationships.has("wren.game") and Relationships.has("wren.lantern"):
		return {"lines": Relationships.WREN_GAME_START, "id": "wren.game", "commit": ["wren.game"],
			"after": [_update_chalk_spots]}
	var mark := pending_mark()
	if mark != "":
		return {"lines": Relationships.WREN_GAME_SHOW, "id": "", "commit": [], "after": [_go_look.bind(mark)]}
	if Relationships.has("wren.game") and not Relationships.has("wren.mark_ok") and not _game_nudged:
		_game_nudged = true
		return {"lines": [Relationships.WREN_GAME_NUDGE], "id": "", "commit": []}
	if Relationships.has("wren.mark_ok") and OwnerMemory.event_session("wren.mark_ok") < OwnerMemory.sessions \
			and not OwnerMemory.has_conversation("wren.r_fixed"):
		return {"lines": [Relationships.WREN_R_FIXED], "id": "wren.r_fixed", "commit": []}
	return {}


## She goes to see for herself: she trusts nobody's marks but hers.
func _go_look(mark: String) -> void:
	if wren == null:
		return
	_wren_path = [Vector2(400, 262), CHALK_LOOK[mark]] as Array[Vector2]
	_wren_arrived = func() -> void:
		_wren_at_spot = mark
		if wren:
			wren.emote("hmm", 1.4)


func _walk_wren(delta: float) -> void:
	if _wren_path.is_empty() or wren == null or not is_instance_valid(wren):
		return
	var to := _wren_path[0] - wren.global_position
	var step := to.limit_length(WREN_WALK * delta)
	wren.global_position += step
	wren._walk_velocity = step / maxf(delta, 0.0001)
	if to.length() <= WREN_WALK * delta + 0.01:
		_wren_path.pop_front()
	if _wren_path.is_empty():
		wren._walk_velocity = Vector2.ZERO
		var arrived := _wren_arrived
		_wren_arrived = Callable()
		if arrived.is_valid():
			arrived.call()


## Standing at the mark: a real one, or rubbed out.
func _chalk_verdict() -> Dictionary:
	var spot := _wren_at_spot
	if spot == "recess":
		return {"lines": Relationships.WREN_GAME_OK, "id": "wren.game_ok", "commit": ["wren.mark_ok", "wren.chalk_back"],
			"after": [_walk_home]}
	return {"lines": Relationships.WREN_GAME_NO, "id": "", "commit": ["wren.mark_refused"],
		"after": [_walk_home]}


func _walk_home() -> void:
	_wren_at_spot = ""
	_update_chalk_spots()
	if wren:
		_wren_path = [Vector2(400, 262), WREN_HOME] as Array[Vector2]


## What Wren is up to, said over her prompt: so her game can be noticed
## before it's explained, and a returning player is reminded of it.
var _invited := false


func _wren_doing() -> void:
	if wren == null or not is_instance_valid(wren):
		return
	var doing := ""
	if not _wren_path.is_empty():
		doing = "going to look"
	elif _wren_at_spot != "":
		doing = "looking at your mark"
	elif Relationships.has("wren.lantern") and not Relationships.has("wren.game"):
		doing = "chalk out"
	elif Relationships.has("wren.game") and not Relationships.has("wren.mark_ok"):
		doing = "waiting for your mark" if pending_mark() == "" else "wants to see your mark"
	wren.doing = doing
	# The first time her game is next and Rue comes near: she holds up the chalk.
	if doing == "chalk out" and not _invited and world.player.global_position.distance_to(wren.global_position) < 70.0:
		_invited = true
		wren.emote("!", 1.4)


## Her X, used without being told: hiding right beside her while the
## owner hunts. She sees it (she's right there) and answers without words.
func _wren_nod() -> void:
	if _nodded or wren == null or not Relationships.has("wren.game") or not _wren_path.is_empty() or _wren_at_spot != "":
		return
	if world.director.awareness < OwnerDirector.SUSPECT or world.hiding_npc() != wren:
		return
	_nodded = true
	wren.emote("shh", 2.0)
	PlaytestLog.mark("wren: shh", "Rue hid at her X during a hunt")


## Rue has Wren's chalk and hasn't written her name yet.
static func can_write_wren() -> bool:
	return Relationships.has("wren.chalk") and not Relationships.has("wren.named")


## Writing WREN on the rim, beside Wren's mark of Rue. Kept for good.
func _write_wren() -> void:
	Relationships.add("wren.named")
	_journal_rim()
	Sfx.play("seal", -8.0, 1.6)
	world.hud.say(Relationships.RUE_WRITES_WREN_GONE if OwnerMemory.is_deleted("wren") else Relationships.RUE_WRITES_WREN, "self")
	queue_redraw()


var wren_beckoned := false
var _beckon_cooldown := 0.0


func area_process(delta: float) -> void:
	_walk_wren(delta)
	_wren_nod()
	_wren_doing()
	_well_process(delta)
	_wren_beckon(delta)
	_mark_process()
	# UNLOCK on the front door: walk in while it's glitched open.
	if door.is_forced_open() and world.player.global_position.distance_to(door.global_position) < 18.0:
		world.change_area("house", "front")
		return
	# Arin sees Wren walking with you: the owner notices.
	if world.escort and arin.can_see(world.escort.global_position):
		world.director.add_awareness(8.0 * delta)
	north_exit.open = world.flags.get("pointer", false)
	arin.paused = world.is_talking() or world.is_owner_paused()
	lamp.paused = arin.paused
	if world.player.global_position.distance_to(well.global_position) < 40.0:
		world.voice("well_look")


## Before she has said a word about it, Wren waves Rue over when Arin comes
## (her generosity is something she does first, and explains later).
func _wren_beckon(delta: float) -> void:
	_beckon_cooldown = maxf(0.0, _beckon_cooldown - delta)
	if _beckon_cooldown > 0.0 or wren == null or not is_instance_valid(wren) or not wren.is_present() \
			or Relationships.has("wren.sheltered") or world.player.sheltered or world.is_talking():
		return
	var rue := world.player.global_position
	if arin.global_position.distance_to(rue) < BECKON_ARIN and rue.distance_to(wren.global_position) < BECKON_RUE:
		wren_beckoned = true
		_beckon_cooldown = 6.0
		wren.emote(WREN_BECKON, 2.0)
		wren.offer_shelter(2.0)


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
		cursor.is_hidden = world.is_player_hidden.bind("cursor")
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
	if p.x > 780.0:
		return "archive"
	if LANE.has_point(p):
		return "lane"
	if p.x > 600.0:
		return "crossing"
	if p.x > 420.0 and p.y < 140.0:
		return "shop"
	if p.x < 200.0:
		return "house"
	return "road"


## The scene starts by itself once Rue is up and near her (she speaks
## first). Committed only when read whole (Relationships._once); its words
## go in the journal at once, so a scene cut short can be re-read there.
func _mark_process() -> void:
	if not _marking or _mark_started or wren == null or not world._awake or world.in_cutscene() or world.is_talking():
		return
	if world.player.global_position.distance_to(wren.global_position) > World.TALK_BREAK_DISTANCE - 6.0:
		return  # (only where a conversation holds: closer than it breaks)
	_mark_started = true
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree() or wren == null or world.ending != "" or world.is_talking():
		_mark_started = false
		return
	world._interact(wren)
	OwnerMemory.record_read("square:WREN, AT THE WELL", "note", "WREN, AT THE WELL", display_name,
		Relationships.WREN_MARKED_SAW if world._talk_result.get("lines", []) == Relationships.WREN_MARKED_SAW else Relationships.WREN_MARKED)
	if not world.conversation_completed.is_connected(_on_marked):
		world.conversation_completed.connect(_on_marked)


func _on_marked(_who: Node) -> void:
	queue_redraw()  # the chalk, from now on
	if Relationships.has("wren.named"):
		_journal_rim()  # the two marks are together now


## The journal's page for the rim: what's on it, in either order.
func _journal_rim() -> void:
	# A "file" page: rewritten to say what is on the rim now, not appended to.
	OwnerMemory.record_read("square:WREN, IN CHALK", "file", "THE WELL'S RIM", display_name, Relationships.rim_journal())


func _exit_tree() -> void:
	Relationships.wren_at_well = false  # only on this visit


func _on_gate_opened() -> void:
	lamp.widen_to(LAMP_GATE_ARC)
	world.director.say("the gate behind the stall. i'll keep the lamp on it.")


## In the lamp's beam: like Arin's look (a short grace, then attention).
func _on_lamp_sees(delta: float) -> void:
	var frame := Engine.get_physics_frames()
	if frame - _lamp_seen_frame > 2:
		_lamp_seen_for = 0.0
	_lamp_seen_frame = frame
	_lamp_seen_for += delta
	if _lamp_seen_for < LAMP_GRACE:
		return
	world.director.add_awareness(LAMP_RATE * delta)
	world.flags["seen_by_lamp"] = true
	# Held in the beam: the owner learns the spot (once per time in it), so
	# later runs Arin walks the crossing too. Crossing openly costs little
	# now and more later; the bench and the lane are how to avoid that.
	if _lamp_seen_for - delta < LAMP_GRACE:
		OwnerMemory.note_spot(area_id, world.player.global_position)
	if not _lamp_spotted:
		_lamp_spotted = true
		Sfx.play("spotted")
		world.director.say("the lamp. i can see the crossing from here.")


## The bench under the awning (World.is_player_hidden asks).
func hides_player(pos: Vector2) -> bool:
	return RECESS.has_point(pos)


func hide_label() -> String:
	return "the awning hides you"


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
	n.hide_radius = WREN_SHELTER_SAFE if OwnerMemory.wren_saved else WREN_SHELTER
	parent.add_child(n)
	n.player = parent.get("world").player if parent.get("world") else null
	n.setup(Npc.State.DELETED if OwnerMemory.is_deleted("wren") else Npc.State.NORMAL)
	return n


func _wren_lines() -> Variant:
	# Where she is right now comes first: off looking at Rue's mark.
	if not _wren_path.is_empty():
		return [Relationships.WREN_GAME_WALKING]
	if _wren_at_spot != "":
		return _chalk_verdict()
	var told := Relationships.wren(_wren_line, _wren_line >= _wren_ask_at - 1, world.escort_id() == "wren")
	if not told.is_empty():
		if told.get("ask", false):
			_wren_asked = true
		_wren_offer = told.get("offer", "") == "chalk"
		return told
	var game := _chalk_game_lines()
	if not game.is_empty():
		return game
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
	return _with_festival(line, _wren_line > 1, Relationships.wren_festival)


func _tobben_lines() -> Variant:
	# What happened between you comes first (Relationships.tobben).
	var told := Relationships.tobben()
	if not told.is_empty():
		return told
	var i := _tobben_line
	if OwnerMemory.met_before("tobben") and i == 0:
		i = 2  # met in an earlier run: no "Welcome to Tobben's!" introduction again
	_tobben_line = i + 1
	return _with_festival(TOBBEN_LINES[mini(i, TOBBEN_LINES.size() - 1)], i >= 1, Relationships.tobben_festival)


## After someone's own line, once they've met her: what they remember of
## the festival (once ever, Relationships), in the same conversation.
func _with_festival(line: String, met: bool, festival: Callable) -> Variant:
	if met:
		var told: Dictionary = festival.call()
		if not told.is_empty():
			told.lines = [line] + told.lines
			told["usual"] = true
			return told
	return [line]


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
	queue_redraw()
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


## Seconds after a conversation before Tobben's report reaches the owner.
const REPORT_DELAY := 4.0
const TOBBEN_REPORT := "tobben says you were asking questions."
## After the guest book: he still reports (it's his script), and leaves out
## what she asked.
const TOBBEN_REPORT_BOOK := "tobben says you came by. he didn't say what for."


## After a report, he doesn't tell again for this long (he already did).
const REPORT_COOLDOWN := 60.0
var _report_pending := false


## Tobben tells the owner about Rue after she talks to him: once, a few
## seconds after the conversation (and after any scene that follows), not
## once per conversation. He can't while his voice is Rue's (written). After
## the guest book he still does, but leaves out what she asked.
func _tobben_reports() -> void:
	if _report_pending or tobben.mute or not _report_cooled():
		return
	_report_pending = true
	await _story_clear()
	if not is_inside_tree():
		return
	await get_tree().create_timer(REPORT_DELAY).timeout
	await _story_clear()  # a scene that started meanwhile goes first
	if is_inside_tree():
		_tobben_report_lands()
	_report_pending = false


func _report_cooled() -> bool:
	var at: float = world.get_meta("tobben_reported_at", -INF)
	return Time.get_ticks_msec() / 1000.0 - at >= REPORT_COOLDOWN


## Waits until nobody is talking and no scene or question is on screen.
func _story_clear() -> void:
	while is_inside_tree() and (world.hud.is_dialogue_open() or world.hud.is_cinematic() or world.hud.is_choosing() or world._cutscene):
		await get_tree().process_frame


func _tobben_report_lands() -> void:
	if not is_inside_tree() or world.ending != "" or tobben.mute:
		return
	world.set_meta("tobben_reported_at", Time.get_ticks_msec() / 1000.0)
	if world.director.is_believing_lie():
		# The owner already believes the lie on the board.
		world.director.say("tobben says you're gone. good.")
		return
	if OwnerMemory.guestbook_restored:
		world.director.say(TOBBEN_REPORT_BOOK)
		world.director.notice(6.0, "tobben mentioned you")
		return
	world.director.say(TOBBEN_REPORT)
	world.director.notice(12.0, "tobben told on you")


func _draw() -> void:
	# Mira's note, pinned beside the notices: her paper, her hand, two pins.
	if OwnerMemory.mira_quest == "pinned":
		var n := Rect2(BOARD_POS + Vector2(6, -9), Vector2(11, 9))
		draw_rect(Rect2(n.position + Vector2(1, 1), n.size), Color(0, 0, 0, 0.3))
		draw_rect(n, Color("f4e6c8"))
		draw_rect(n, Decor.INK, false, 0.6)
		draw_string(ThemeDB.fallback_font, n.position + Vector2(2, 7.5), "M", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("c9733e"))
		for px: float in [n.position.x + 1.5, n.end.x - 1.5]:
			draw_circle(Vector2(px, n.position.y + 1.2), 0.9, Color("c84a3a"))
	# Tobben's guest book, open on the counter once RUE is back in it.
	if OwnerMemory.guestbook_restored:
		var b := Rect2(STALL.position + Vector2(STALL.size.x * 0.5 - 7, 6), Vector2(14, 7))
		draw_rect(b, Color("efe4cc"))
		draw_line(Vector2(b.get_center().x, b.position.y), Vector2(b.get_center().x, b.end.y), Color("8a7a68"), 0.6)
		draw_line(b.position + Vector2(1.5, 2.5), b.position + Vector2(5.5, 2.5), Color("3a2a20"), 0.6)  # ARIN
		draw_line(b.position + Vector2(1.5, 4.5), b.position + Vector2(4.5, 4.5), Color("2a8aa0"), 0.8)  # RUE, a different hand
		draw_rect(b, Decor.INK, false, 0.5)
	# Wren's chalk on the rim (kept for good once she's shown you).
	if Relationships.has("wren.marked_well"):
		var c := Color(0.95, 0.95, 0.9, 0.85)
		# On the ring's stone face (draw_well), where chalk shows.
		var at := Vector2(WELL.end.x - 8, WELL.position.y + 15)
		draw_arc(at, 2.8, 0.0, TAU, 10, c, 0.7)  # her head for you
		draw_rect(Rect2(at + Vector2(-1.4, -0.6), Vector2(0.8, 0.8)), c)  # two dots for eyes
		draw_rect(Rect2(at + Vector2(0.6, -0.6), Vector2(0.8, 0.8)), c)
		draw_line(at + Vector2(0, 2.8), at + Vector2(0, 6), c, 0.7)
		draw_line(at + Vector2(5, 5), at + Vector2(5, -1), c, 0.7)  # an arrow, up
		draw_line(at + Vector2(5, -1), at + Vector2(3.4, 1.2), c, 0.7)
		draw_line(at + Vector2(5, -1), at + Vector2(6.6, 1.2), c, 0.7)
	# Wren's game: her X where she stands; Rue's R where Rue chose (backwards
	# until Wren fixes it, next session); a refused mark is rubbed out.
	if Relationships.has("wren.game"):
		var cx := Color(0.95, 0.95, 0.9, 0.8)
		var x0 := WREN_HOME + Vector2(-16, 10)
		draw_line(x0 + Vector2(-3, -3), x0 + Vector2(3, 3), cx, 0.8)
		draw_line(x0 + Vector2(-3, 3), x0 + Vector2(3, -3), cx, 0.8)
		for spot_id in ["recess", "crossing"]:
			if not Relationships.has("wren.mark_" + spot_id) or (spot_id == "crossing" and Relationships.has("wren.mark_refused")):
				continue
			var fixed: bool = spot_id == "recess" and Relationships.has("wren.mark_ok") and OwnerMemory.event_session("wren.mark_ok") < OwnerMemory.sessions
			var at: Vector2 = CHALK_SPOTS[spot_id]
			draw_set_transform(at, 0.0, Vector2(1.0 if fixed else -1.0, 1.0))
			draw_string(ThemeDB.fallback_font, Vector2(-3, 3), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, cx)
			draw_set_transform(Vector2.ZERO)
	# Her name beside it, in Rue's hand (once Rue has written it).
	if Relationships.has("wren.named"):
		var c := Color(0.95, 0.95, 0.9, 0.85)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(WELL.position.x + 3, WELL.position.y + 20), "WREN", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, c)
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
	Decor.cobbles(ci, Rect2(100, 170, r.end.x - 100, 20), STONE.darkened(0.12), 8.0, 2.0)
	_paint_east(ci)
	Decor.cobbles(ci, Rect2(NORTH_GAP.x, r.position.y, 40, 130), STONE.darkened(0.12), 8.0, 3.0)
	# Flower beds and a low fence along the south edge: flat, never in the way.
	var bed_y := r.end.y - 16.0
	for x in [150.0, 270.0, 470.0, 640.0, 800.0, 868.0]:
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
	draw_well(ci, WELL, STONE)
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
	# The fifth lantern (the festival, docs/INTRO_REBUILD.md): still lit by
	# the well, three years on, the only one that is. A post with a crook,
	# a paper lantern on it, and a faded festival ribbon. Its light is one
	# of the area's lights.
	var post := WELL.get_center() + Vector2(22, 10)
	ci.draw_circle(post, 2.4, Color(0, 0, 0, 0.3))
	ci.draw_rect(Rect2(post + Vector2(-1, -18), Vector2(2, 18)), Color("3a2a20"))
	ci.draw_line(post + Vector2(0, -18), post + Vector2(-5, -18), Color("3a2a20"), 1.4)
	ci.draw_line(post + Vector2(-5, -18), post + Vector2(-5, -15), Color("2a2018"), 0.6)
	var lamp := post + Vector2(-5, -11)
	ci.draw_circle(lamp, 6.5, Color(1.0, 0.78, 0.4, 0.16))
	ci.draw_colored_polygon(PackedVector2Array([lamp + Vector2(-2.5, -4), lamp + Vector2(2.5, -4), lamp + Vector2(3.6, 0),
		lamp + Vector2(2.5, 4), lamp + Vector2(-2.5, 4), lamp + Vector2(-3.6, 0)]), Color("f2b860"))
	ci.draw_line(lamp + Vector2(0, -4), lamp + Vector2(0, 4), Color("c8823a"), 0.5)
	ci.draw_rect(Rect2(lamp + Vector2(-2.5, -5), Vector2(5, 1.2)), Color("5a3a24"))
	ci.draw_rect(Rect2(lamp + Vector2(-2.5, 4), Vector2(5, 1.2)), Color("5a3a24"))
	ci.draw_circle(lamp, 1.6, Color("fff0c0"))
	ci.draw_line(post + Vector2(1, -16), post + Vector2(5, -10), Color("a8605a", 0.8), 1.0)  # the ribbon, faded
	Decor.wall_shadow(ci, r, 10.0, 0.22)
	Decor.walls(ci, r, WALL, Color("5a4a3a"), Color("2a2620"), [
		{"side": "right", "from": EAST_GAP.x, "to": EAST_GAP.y},
		{"side": "top", "from": NORTH_GAP.x, "to": NORTH_GAP.y},
	])


## The well, seen from above and in front: a round stone ring (its rim an
## ellipse, its front a curved face of laid stones), black water with a
## glint, a winch frame with its rope and a bucket on the rim. Chalk is
## drawn on the rim's top (see the WREN and X marks), which stays flat.
static func draw_well(ci: CanvasItem, r: Rect2, stone: Color) -> void:
	var c := Vector2(r.get_center().x, r.position.y + 7.0)
	var rx := r.size.x * 0.5
	var ry := 6.0
	var ring := func(cx: Vector2, ax: float, ay: float, n := 20) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in n:
			var t := TAU * i / n
			pts.append(cx + Vector2(cos(t) * ax, sin(t) * ay))
		return pts
	# Shadow, then the front face: the lower half of the ring, extruded.
	ci.draw_colored_polygon(ring.call(c + Vector2(2, r.size.y - 5), rx + 1, ry), Color(0, 0, 0, 0.3))
	var face := PackedVector2Array()
	for i in 11:
		var t := PI * i / 10.0
		face.append(c + Vector2(cos(t) * rx, sin(t) * ry))
	for i in range(10, -1, -1):
		var t := PI * i / 10.0
		face.append(c + Vector2(cos(t) * rx, sin(t) * ry + r.size.y - 9))
	ci.draw_colored_polygon(face, stone.darkened(0.2))
	# Laid stones: two courses, joints staggered, following the curve.
	for row in 2:
		var y := 4.0 + row * 4.5
		for i in 7:
			var t := PI * (i + (0.5 if row == 1 else 0.0)) / 7.0
			var x := cos(t) * rx * 0.97
			var p := c + Vector2(x, sin(t) * ry + y)
			ci.draw_line(p + Vector2(0, -2), p + Vector2(0, 2), stone.darkened(0.5), 0.6)
		var band := PackedVector2Array()
		for i in 11:
			var t := PI * i / 10.0
			band.append(c + Vector2(cos(t) * rx, sin(t) * ry + y + 2.2))
		ci.draw_polyline(band, stone.darkened(0.45), 0.6)
	# The rim: a ring of stone, lit on top, around the dark water.
	ci.draw_colored_polygon(ring.call(c, rx, ry), stone.lightened(0.12))
	ci.draw_colored_polygon(ring.call(c + Vector2(0, 0.6), rx - 3.5, ry - 2.4), Color("0e1822"))
	ci.draw_arc(c + Vector2(0, 0.6), rx - 3.5, PI * 1.1, PI * 1.9, 10, stone.darkened(0.35), 0.8)  # the inner lip in shadow
	ci.draw_line(c + Vector2(-5, 0.5), c + Vector2(1, 1.6), Color(0.6, 0.8, 1.0, 0.4), 0.7)  # the water's glint
	ci.draw_polyline(ring.call(c, rx, ry) + PackedVector2Array([c + Vector2(rx, 0)]), Decor.INK, 0.7)
	# The winch: two posts from the rim, a beam, the rope, a bucket left on the rim.
	var wood := Color("6b4a30")
	for side in [-1.0, 1.0]:
		var foot := c + Vector2(side * (rx - 1.5), 1.0)
		ci.draw_rect(Rect2(foot + Vector2(-1.2, -15), Vector2(2.4, 15)), wood.darkened(0.15))
		ci.draw_line(foot + Vector2(-1.2, -15), foot + Vector2(-1.2, 0), wood.lightened(0.2), 0.5)
	ci.draw_rect(Rect2(c + Vector2(-rx + 0.5, -15.5), Vector2(2 * rx - 1.0, 2.2)), wood)
	ci.draw_line(c + Vector2(-rx + 0.5, -15.5), c + Vector2(rx - 0.5, -15.5), wood.lightened(0.25), 0.5)
	ci.draw_rect(Rect2(c + Vector2(-3, -16.5), Vector2(6, 4)), wood.darkened(0.3))  # the drum
	ci.draw_line(c + Vector2(0, -12.5), c + Vector2(0, -1.5), Color("c8b080"), 0.6)  # the rope, down into the dark
	var bucket := c + Vector2(rx - 6, -2.5)
	ci.draw_colored_polygon(PackedVector2Array([bucket + Vector2(-2.5, -2), bucket + Vector2(2.5, -2), bucket + Vector2(2, 2), bucket + Vector2(-2, 2)]), Color("7a5a3a"))
	ci.draw_line(bucket + Vector2(-2.5, -1), bucket + Vector2(2.5, -1), Color("4a3a2a"), 0.6)
	ci.draw_arc(bucket + Vector2(0, -2), 2.4, PI, TAU, 6, Color("3a2a20"), 0.5)


## The east half, under the same afternoon: the crossing's cobbles, the
## lane and its fence, the covered bench, and the Archive's stone front
## over the road out.
func _paint_east(ci: CanvasItem) -> void:
	# The crossing: a plaza of large pale flags inside a kerb, with the road
	# running straight through it in darker setts (so the way on reads at a
	# glance), a gutter along the road, a drain, and a path worn diagonally
	# from the lane's gate towards the bench (where people actually walk).
	var c := CROSSING
	ci.draw_rect(c.grow(3.0), STONE.darkened(0.42))  # the kerb's shadow
	Decor.flagstones(ci, c, STONE.darkened(0.06), 22.0, 7.0)
	ci.draw_rect(c, Color(STONE.lightened(0.1), 0.7), false, 2.0)  # the kerb
	var road := Rect2(c.position.x, 168, c.size.x, 24)
	Decor.cobbles(ci, road, STONE.darkened(0.2), 7.0, 4.0)
	for y in [road.position.y, road.end.y]:
		ci.draw_line(Vector2(road.position.x, y), Vector2(road.end.x, y), Color(0, 0, 0, 0.35), 1.0)  # gutters
	ci.draw_rect(Rect2(c.get_center().x - 6, road.end.y + 3, 12, 4), Color(0.08, 0.08, 0.09))  # a drain
	for k in 4:
		ci.draw_line(Vector2(c.get_center().x - 5 + k * 3, road.end.y + 3), Vector2(c.get_center().x - 5 + k * 3, road.end.y + 7), STONE.darkened(0.1), 0.6)
	var worn := PackedVector2Array([GATE.get_center() + Vector2(-6, 8), GATE.get_center() + Vector2(8, 8),
		RECESS.get_center() + Vector2(10, -16), RECESS.get_center() + Vector2(-8, -16)])
	ci.draw_colored_polygon(worn, Color(1.0, 0.95, 0.85, 0.06))
	# The lane behind Tobben's: a worn track along the fence.
	Decor.path(ci, Rect2(LANE.position.x, LANE.position.y + 30, LANE.size.x, 22), PATH.lightened(0.02), 4.0)
	for k in 9:
		ci.draw_circle(Vector2(LANE.position.x + 18 + k * 27, LANE.position.y + 14 + (k % 3) * 3), 3.0, Color("2e3d2a"))  # weeds by the wall
	# The fence (the gate draws itself): posts and two rails, a shadow south.
	ci.draw_rect(Rect2(LANE.position.x, FENCE_Y + 6, LANE.size.x, 4), Color(0, 0, 0, 0.18))
	for seg in [[LANE.position.x, GATE.position.x], [GATE.end.x, LANE.end.x]]:
		ci.draw_rect(Rect2(seg[0], FENCE_Y, seg[1] - seg[0], GATE.size.y), Color("5a4632"))
		ci.draw_line(Vector2(seg[0], FENCE_Y + 1), Vector2(seg[1], FENCE_Y + 1), Color("8a6a48"), 1.0)
		ci.draw_line(Vector2(seg[0], FENCE_Y + 4), Vector2(seg[1], FENCE_Y + 4), Color("4a3828"), 1.0)
		var x: float = seg[0]
		while x <= seg[1]:
			ci.draw_rect(Rect2(x - 1, FENCE_Y - 4, 2.4, 10), Color("4a3828"))
			x += 12.0
	# The covered bench: an awning on two posts, a bench in its shade.
	ci.draw_rect(Rect2(RECESS.position + Vector2(-2, 6), RECESS.size + Vector2(4, 0)), Color(0, 0, 0, 0.22))
	Decor.furniture(ci, Rect2(RECESS.position.x + 8, RECESS.end.y - 12, RECESS.size.x - 16, 8), Color("6b5040"), 3.0)
	for k in 4:
		ci.draw_rect(Rect2(RECESS.position.x + k * 13, RECESS.position.y, 13, 9), Color("5a7a8a") if k % 2 == 0 else Color("e8dcc4"))
	ci.draw_rect(Rect2(RECESS.position, Vector2(RECESS.size.x, 9)), Decor.INK, false, 0.8)
	for x in [RECESS.position.x + 2, RECESS.end.x - 4]:
		ci.draw_rect(Rect2(x, RECESS.position.y + 9, 2, RECESS.size.y - 10), Color("3a2a20"))
	# The Archive: a pale stone front with tall windows and a rose window,
	# and its gatehouse over the road out: the only doorway, lit from inside,
	# its name cut over the arch. (No door on the front: the way in is the
	# road, and nothing on the facade pretends otherwise.)
	var f := LIBRARY
	var stone := Color("8a8478")
	ci.draw_rect(Rect2(f.position + Vector2(4, 6), f.size), Color(0, 0, 0, 0.28))
	ci.draw_rect(f, stone)
	ci.draw_rect(Rect2(f.position.x, f.end.y - 14, f.size.x, 14), Color("6a645a"))  # its front face
	ci.draw_rect(Rect2(f.position.x - 2, f.position.y, f.size.x + 4, 6), Color("5a5650"))
	for k in 5:
		var wx := f.position.x + 10 + k * 22
		if k == 2:
			continue
		ci.draw_rect(Rect2(wx, f.position.y + 14, 9, 34), Color("1e2a3a"))
		ci.draw_rect(Rect2(wx, f.position.y + 14, 9, 34), Decor.INK, false, 0.8)
		ci.draw_rect(Rect2(wx + 1, f.position.y + 15, 7, 10), Color(1.0, 0.85, 0.55, 0.18))  # a lamp inside
	var rose := Vector2(f.position.x + 54, f.position.y + 30)
	ci.draw_circle(rose, 11.0, Color("5a5650"))
	ci.draw_circle(rose, 9.0, Color("2a4a6a"))
	for k in 8:
		ci.draw_line(rose, rose + Vector2.from_angle(k * TAU / 8.0) * 9.0, stone, 0.8)
	ci.draw_rect(f, Decor.INK, false, 1.0)
	# The gatehouse: two piers and a lintel over the passage.
	for g in [GATEHOUSE_N, GATEHOUSE_S]:
		ci.draw_rect(Rect2(g.position + Vector2(3, 4), g.size), Color(0, 0, 0, 0.3))
		ci.draw_rect(g, stone.darkened(0.08))
		ci.draw_rect(Rect2(g.position.x, g.end.y - 10, g.size.x, 10), Color("6a645a"))
		for yy in range(int(g.position.y) + 8, int(g.end.y) - 10, 8):
			ci.draw_line(Vector2(g.position.x, yy), Vector2(g.end.x, yy), Color(0, 0, 0, 0.12), 0.6)
		ci.draw_rect(g, Decor.INK, false, 1.0)
	var passage := Rect2(GATEHOUSE_N.position.x, GATEHOUSE_N.end.y, GATEHOUSE_N.size.x, GATEHOUSE_S.position.y - GATEHOUSE_N.end.y)
	ci.draw_rect(passage, Color(0.12, 0.1, 0.09))
	ci.draw_rect(passage.grow_individual(-4, -2, 0, -2), Color(1.0, 0.82, 0.5, 0.22))  # lamplight from inside
	for k in 6:  # the light spilling out onto the road
		ci.draw_rect(Rect2(passage.position.x - 6 - k * 8, passage.position.y + 4 + k, 8, passage.size.y - 8 - k * 2), Color(1.0, 0.82, 0.5, 0.05 * (6 - k)))
	var lintel := Rect2(GATEHOUSE_N.position.x - 4, GATEHOUSE_N.end.y - 14, GATEHOUSE_N.size.x + 4, 12)
	ci.draw_rect(lintel, Color("5a5650"))
	ci.draw_line(lintel.position + Vector2(2, 3), Vector2(lintel.end.x - 2, lintel.position.y + 3), Color("8a8478"), 1.0)  # carved
	# (Its name is the exit sign beside it, the same as every way out.)


func _process(_delta: float) -> void:
	if not world.flags.get("pointer", false):
		queue_redraw()  # animates the unloaded road


# --- the well (WellSequence) ----------------------------------------------------

func _well_process(delta: float) -> void:
	var near := world.player.global_position.distance_to(WELL.get_center()) < 40.0
	if near and not WellSequence.done("click") and not world.in_cutscene() and not world.is_talking():
		WellSequence.record("click")
		# Her habit from the opening film: two light taps, then the press.
		for beat in WellSequence.CLICK_PATTERN:
			get_tree().create_timer(beat[0]).timeout.connect(_well_click.bind(beat[1], beat[2]))
		world.hud.say(WellSequence.CLICK_LINE, "self")
	rim.prompt = "write WREN in chalk" if can_write_wren() else WellSequence.ANSWER_PROMPT if WellSequence.done("compared") and not WellSequence.done("answered") else "listen"
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
		Sfx.play("fragment", -4.0, 0.7, 0.0)
		for l in WellSequence.ANSWER_LINES:
			world.hud.say(l, "self")
		var wren_waiting := Relationships.has("wren.met") and not OwnerMemory.wren_saved and not OwnerMemory.is_deleted("wren")
		world.hud.say(WellSequence.ANSWER_HOPE if wren_waiting else WellSequence.ANSWER_HOPE_ALONE, "self")


## One click of the well's gesture (bound to the area: leaving drops the rest).
func _well_click(volume_db: float, pitch: float) -> void:
	Sfx.play("click", volume_db, pitch, 0.0)


func _on_listen(_rim: WellRim) -> void:
	if world.ending != "" or world.in_cutscene() or world.hud.is_dialogue_open():
		return
	if can_write_wren():
		_write_wren()
		return
	if not WellSequence.done("tune"):
		world.hud.say(WellSequence.LISTEN_NOTHING, "self")
		return
	if WellSequence.done("compared") and not WellSequence.done("answered"):
		if world.escort != null:
			world.hud.say(WellSequence.ANSWER_NOT_ESCORTING, "self")
			return
		_answer_t = 0.0
		return
	# The well plays back what it keeps: her words, or (once Rue has
	# answered) Rue's own. What it means counts once the box is read whole:
	# walk away and it plays again next time, the same way.
	var lines: Array = WellSequence.ANSWER_REPLAY if WellSequence.done("answered") else WellSequence.WORDS
	world.hud.show_dialogue(WellSequence.WORDS_SPEAKER, Hud.OWNER_COLOR, lines, "", null, [], true)
	world.hud.dialogue_closed.connect(_on_well_heard, CONNECT_ONE_SHOT)


func _on_well_heard() -> void:
	if not world.hud.dialogue_finished or world.ending != "":
		return
	if WellSequence.done("answered"):
		world.hud.say(WellSequence.ANSWER_REPLAY_NOTE, "self")
		return
	if not WellSequence.done("words"):
		WellSequence.record("words")
		OwnerMemory.record_read("square:THE WELL", "note", "THE WELL", display_name, ["Up from the well, typed, not spoken:", WellSequence.WORDS[1]])
		world.hud.say(WellSequence.WORDS_AFTER, "self")
		return
	# Heard before: exactly the same. Kept, not said.
	world.hud.say(WellSequence.WORDS_REPLAY_NOTE, "self")
	if WellSequence.done("compared"):
		return
	if WellSequence.can_compare():
		WellSequence.record("compared")
		OwnerMemory.record_read("square:THE WELL", "note", "THE WELL", display_name, ["Played back the same way every time: kept, not said.",
			"The same words as her message, months after she left."])
		for l in WellSequence.COMPARED:
			world.hud.say(l, "self")
	else:
		world.hud.say(WellSequence.COMPARED_NOT_YET, "self")
