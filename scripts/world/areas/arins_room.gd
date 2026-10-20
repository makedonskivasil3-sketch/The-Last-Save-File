class_name ArinsRoom
extends Area
## Where you wake up. The owner watches this room closely: awareness rises
## fast here. The door is the owner's; the way out is a seam in the wall that
## only tears once the owner starts rewriting the room.

const DOOR_RECT := Rect2(304, 28, 32, 8)
const NOTE_POS := Vector2(150, 32)
const MIRA_POS := Vector2(440, 130)
const SAVE_POS := Vector2(420, 236)
const BED := Rect2(470, 44, 58, 32)
const TABLE := Rect2(116, 216, 36, 22)
const RUG := Rect2(256, 130, 128, 80)
## The window in the top wall: the afternoon comes in here (SunBeam).
const WINDOW := Rect2(196, 28, 52, 8)
## Gaps in the walls. Each one you use gets patched once the owner catches you.
const SEAM_SPOTS: Array[Rect2] = [
	Rect2(88, 170, 12, 22),
	Rect2(540, 210, 12, 22),
	Rect2(400, 288, 22, 12),
	Rect2(200, 28, 22, 12),
	Rect2(88, 70, 12, 22),
]
const DOOR_TRIGGER_DISTANCE := 70.0
## The corner behind the bed is walled off by a thin cracked partition: the
## room's memory is behind it, and PHASE is the way in (the first glitch).
const NOOK_WALLS: Array[Rect2] = [Rect2(458, 36, 4, 84), Rect2(458, 116, 86, 4)]
const CRACK := Vector2(500, 118)

## Surfaces are lit (Area.ambient + lights), so their colours are the
## daylight colours; the room's dimness comes from the lighting.
const FLOOR := Color("4a3b30")
const FLOOR_LINE := Color("3a2e26")
const RUG_COL := Color("6a4240")
const WOOD := Color("7a5a40")
const SHEET := Color("b8a890")

const MIRA_LINES := [
	"Arin! You're up early.",
	"...Arin? Your colors look wrong.",
	"You're not Arin. Who are you?",
	"They're going to notice you. They notice everything.",
	"If you get out, find Wren in the square. She sees things too.",
	"Arin never talks about the other one. The one who used to sit next to them.",
]
const MIRA_RESTRICTED := [
	"I'm not allowed to talk to you anymore.",
	"Please go away. They're reading this.",
	"...the square. Wren. Go.",
]



## Every line Mira can say that is the same in every run, by voice id stem
## (VoiceManifest), including what she remembers (Story.recall_lines).
static func voice_lines() -> Dictionary:
	return {"npc.mira": Story.recall_lines("mira") + [Story.TRUTH_LINES.mira] + Story.FRAY_TAKEN.mira
		+ [Story.FRAY_LINES.mira, Story.FRAY_RECALL.mira, Story.FRAY_RETURNED.mira] + MIRA_LINES + MIRA_RESTRICTED + Story.MIRA_RESET_LINES + Story.MIRA_ASK + Story.MIRA_JOINS + Story.MIRA_DECLINED}


## How Mira looks saying each of her lines (CharacterArt expressions; the
## rest are "neutral"). docs/CHARACTER_ART.md has her brief.
static func mira_expression(line: String) -> String:
	var by_line := {
		MIRA_LINES[0]: "eager", MIRA_LINES[1]: "concerned", MIRA_LINES[2]: "afraid",
		MIRA_LINES[3]: "concerned", MIRA_LINES[4]: "determined", MIRA_LINES[5]: "remembering",
		MIRA_RESTRICTED[0]: "afraid", MIRA_RESTRICTED[1]: "afraid", MIRA_RESTRICTED[2]: "determined",
		Story.MIRA_JOINS[0]: "eager", Story.MIRA_DECLINED[0]: "relieved",
		Story.TRUTH_LINES.mira: "concerned",
	}
	for l in Story.MIRA_ASK:
		by_line[l] = "eager"
	for l in Story.MIRA_RESET_LINES:
		by_line[l] = "reset"
	var recall := {"mira_pinned": "relieved", "mira_lost": "concerned", "mira_restored": "remembering",
		"wren_lost": "concerned", "ended:message": "remembering", "ended:wren": "eager",
		"ended:escape": "concerned", "died:arin": "afraid"}
	for entry in Story.RECALL["mira"]:
		if recall.has(entry[0]):
			by_line[entry[1]] = recall[entry[0]]
	return by_line.get(line, "neutral")


var purged := false
var previous_exit := "none"
var note: Note
var mira: Npc
var door: Door
var seam: Seam
var save_point: SavePoint
var cracked: CrackedWall

var _mira_line := 0
## Mira just asked to come along: the choice comes when the dialogue closes.
var _mira_asked := false
## The talk on which she asks (again): after a "not now" she says two more
## of her own lines first, so who she is never gets lost behind the request.
var _mira_ask_at := 2


func _init() -> void:
	area_id = "room"
	display_name = "ARIN'S ROOM"
	bounds = Rect2(96, 36, 448, 256)
	awareness_rate = 3.0
	entries = {"start": Vector2(320, 270)}


var sun: SunBeam


func build() -> void:
	setup_common()
	sun = SunBeam.new()
	sun.window = WINDOW
	add_child(sun)
	# The remembered afternoon: dim room, warm light where it falls.
	ambient = 0.45
	add_light(Vector2(TABLE.get_center().x, TABLE.position.y - 4), Color(1.0, 0.7, 0.4), 1.8, 120.0, true)  # the desk lamp, on the table (outside its shadow-caster)
	add_light(WINDOW.get_center() + Vector2(14, 70), Color(1.0, 0.86, 0.6), 1.4, 160.0, true)  # daylight off the floor
	add_light(BED.get_center() + Vector2(0, 34), Color(0.7, 0.78, 1.0), 0.8, 80.0)  # the nook, cooler
	add_dust(Rect2(WINDOW.position.x - 10, WINDOW.end.y + 6, WINDOW.size.x + 40, 110), Color(1.0, 0.9, 0.7, 0.55), 18, Vector2(3, 2))
	add_boundary([{"side": "top", "from": DOOR_RECT.position.x, "to": DOOR_RECT.end.x}])
	add_solid(BED)
	add_solid(TABLE)
	set_backdrop(_paint)

	door = Door.new()
	add_child(door)
	var door_state := Door.State.OPEN if OwnerMemory.sessions <= 1 or purged else Door.State.DELETED
	door.setup(DOOR_RECT, door_state)

	note = Note.new()
	note.position = NOTE_POS
	note.player = world.player
	note.text = _note_text()
	note.lie = "Welcome home, Arin.\nEverything is fine."
	add_child(note)

	var mira_state := Npc.State.NORMAL
	if not purged:
		if world.is_mira_deleted():
			mira_state = Npc.State.DELETED
		elif OwnerMemory.purge >= 1:
			mira_state = Npc.State.RESTRICTED
	if world.escort and world.escort.npc_id == "mira":
		mira = world.escort  # she's out walking with you
	else:
		mira = add_npc("mira", MIRA_POS, mira_state)
		mira.display_name = "MIRA"
		mira.body_kind = "dress"
		mira.idle_style = "sway"
		mira.notice_emote = "!"
		mira.dark_color = Color("a85a2e")
		mira.lines_provider = _mira_lines
		mira.awareness_cost = 8.0

	save_point = SavePoint.new()
	save_point.position = SAVE_POS
	add_child(save_point)
	interactables.append(note)
	interactables.append(save_point)

	if purged:
		_build_purged_extras()
		return
	var hidden_memory := ""
	for f in Story.fragments_in(area_id):
		if not OwnerMemory.has_fragment(f.id):
			hidden_memory = f.id
	if hidden_memory != "":
		cracked = CrackedWall.new()
		add_child(cracked)
		cracked.setup(NOOK_WALLS, CRACK, hidden_memory)
	# The owner patched the seam you used last time: you arrive to the sound
	# of it being stitched shut.
	if previous_exit in ["death", "quit", "crash"] and OwnerMemory.session_seam == -1 \
			and not OwnerMemory.patched_seams.is_empty() and OwnerMemory.sessions > 1:
		get_tree().create_timer(2.2).timeout.connect(func() -> void:
			if is_inside_tree():
				Sfx.play("seal"))
	# Seams the owner patched in earlier sessions stay visible as scars.
	for i in OwnerMemory.patched_seams:
		if i >= 0 and i < SEAM_SPOTS.size():
			var scar := Seam.new()
			scar.sealed = true
			add_child(scar)
			scar.setup(i, SEAM_SPOTS[i])
	for i in SEAM_SPOTS.size():
		if i not in OwnerMemory.patched_seams:
			seam = Seam.new()
			add_child(seam)
			seam.setup(i, SEAM_SPOTS[i])
			seam.slipped_through.connect(_on_seam)
			break


func area_process(_delta: float) -> void:
	# UNLOCK: through the glitched-open door, out into the square.
	if door.is_forced_open() and world.player.global_position.y < bounds.position.y + 2.0 \
			and absf(world.player.global_position.x - door.global_position.x) < DOOR_RECT.size.x * 0.5 + 2.0:
		world.change_area("square", "house")
		return
	if door.state == Door.State.OPEN and world.player.global_position.distance_to(door.global_position) < DOOR_TRIGGER_DISTANCE:
		world.director.on_door_approached()
	if seam:
		# The wall tears once the owner gets suspicious and starts rewriting
		# the room. (Agitating the owner on purpose is a way out.)
		seam.open = world.director.awareness >= OwnerDirector.SUSPECT
		seam.hint = door.state != Door.State.OPEN  # locked behind you counts too
		seam.reveal = 0.25 + world.director.awareness / 100.0 * 0.6 if seam.open else 0.0


func guide_point() -> Vector2:
	if seam and seam.open:
		return seam.global_position
	if cracked and not cracked.is_open():
		return CRACK
	return Vector2.INF


func on_owner_event(event: float) -> void:
	match event:
		OwnerDirector.NOTICE:
			note.rewrite("Welcome home, Arin.\nSomeone else is here.")
		OwnerDirector.CONTAIN:
			if door.state == Door.State.OPEN:
				door.lock()
				world.fx.spike(0.6, 0.8)
			world.hud.say("WARNING: wall integrity 97%", "system")
		OwnerDirector.SILENCE:
			if not mira.escorted and mira.delete():
				world.flags["mira_deleted"] = true
				world.fx.spike(0.8, 1.2)
				world.director.say("don't talk to it, mira.")
				world.voice("mira_deleted")
				world.hud.say("mira.npc deleted", "system")
		OwnerDirector.HUNT:
			start_erasure([door.global_position + Vector2(0, 10)])


func interact_extra(node: Node2D) -> void:
	if node == note:
		world.director.notice(4.0, "read the owner's note")
	elif node == save_point:
		world.fx.spike(0.3, 0.4)
		if world.director.awareness >= OwnerDirector.NOTICE:
			world.director.say("don't touch that.")
		world.director.notice(15.0, "touched the save point")


func _on_seam(s: Seam) -> void:
	world.change_area("square", "house")
	if not world._transitioning:
		# Refused (waiting for Mira, mid-reload): the seam stays open for the
		# next try instead of being used up, which could strand you here.
		s._used = false
		return
	OwnerMemory.note_seam(s.id)


func _mira_lines() -> Array:
	# Reset by the owner: she doesn't know you any more.
	if OwnerMemory.mira_quest == "reset":
		var reset: String = Story.MIRA_RESET_LINES[mini(_mira_line, Story.MIRA_RESET_LINES.size() - 1)]
		_mira_line += 1
		return [reset]
	# Her request, once she trusts you a little: take her to the square.
	if mira.state == Npc.State.NORMAL and OwnerMemory.mira_quest in ["", "carried"] and _mira_line >= _mira_ask_at \
			and world.escort == null:
		_mira_asked = true
		return Story.MIRA_ASK
	var lines: Array = MIRA_LINES if mira.state == Npc.State.NORMAL else MIRA_RESTRICTED
	var line: String = lines[mini(_mira_line, lines.size() - 1)]
	_mira_line += 1
	return [line]


## Mira asked to come along: now you choose.
func on_dialogue_closed(who: Node) -> void:
	if who != mira or not _mira_asked:
		return
	_mira_asked = false
	if not world.hud.dialogue_finished or world.ending != "":
		return
	world.player.frozen = true
	var pick := await world.choose_safely(Story.MIRA_ASK_Q, Story.MIRA_ASK_CHOICES)
	if not is_inside_tree() or pick < 0:
		return
	world.player.frozen = false
	if pick == 0:
		world.hud.show_dialogue("MIRA", mira.name_color, Story.MIRA_JOINS, "npc.mira", CharacterArt.for_npc(mira), World.expressions_for(mira, Story.MIRA_JOINS))
		world.start_escort(mira)
	else:
		_mira_ask_at = _mira_line + 2
		world.hud.show_dialogue("MIRA", mira.name_color, Story.MIRA_DECLINED, "npc.mira", CharacterArt.for_npc(mira), World.expressions_for(mira, Story.MIRA_DECLINED))


func _note_text() -> String:
	if purged:
		return "Welcome home, Arin.\nDon't forget to save!"
	if OwnerMemory.last_run_husk() == "room":
		return Story.NOTE_BODY
	match previous_exit:
		"death":
			return Story.NOTE_RECALL.get(OwnerMemory.last_death, "I REMEMBER WHERE\nYOU DIED.")
		"quit", "crash":
			return "CLOSING THE GAME\nWON'T SAVE YOU."
		"win", "escape":
			return Story.NOTE_RECALL.get(OwnerMemory.last_ending, "I KNOW ABOUT\nSLOT 2.")
	if OwnerMemory.sessions > 1:
		return "I SAW YOU."
	return "Welcome home, Arin.\nDon't forget to save!"


func _build_purged_extras() -> void:
	# The real Arin, back where you used to stand.
	var arin := add_npc("arin", Vector2(320, 270))
	arin.display_name = "ARIN"
	arin.dress_color = Color("5a7fb0")
	arin.dark_color = Color("2e3f5c")
	arin.accent_color = Color("c0392b")
	arin.hair_color = Color("2a2a30")
	arin.lines_provider = func() -> Array: return ["..."]
	arin.mute = true


func _paint(ci: CanvasItem) -> void:
	# Arin's room, illustrated (docs/VISUAL_DIRECTION.md): warm boards, a
	# worn rug, the bed in its walled-off nook, the desk with its lamp and
	# console light. Only the bed and the desk are solid, and only they have
	# a front face.
	Decor.planks(ci, bounds, FLOOR, 12.0, 1.0)
	Decor.rug(ci, RUG, RUG_COL, Color("c89a6a"))
	# Flat things on the floor (never in the way): a book, a sock, a drawing.
	ci.draw_rect(Rect2(212, 246, 9, 6), Color("6b3a2c"))
	ci.draw_rect(Rect2(213, 246.6, 3.6, 4.8), Color("e8dcc4"))
	ci.draw_rect(Rect2(216.8, 246.6, 3.6, 4.8), Color("e8dcc4"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(330, 250), Vector2(338, 248), Vector2(340, 252), Vector2(332, 254)]), Color("8aa0c0"))
	ci.draw_rect(Rect2(150, 120, 16, 12), Color("efe6d6"))
	ci.draw_line(Vector2(152, 128), Vector2(158, 123), Color("d8463a"), 0.8)
	ci.draw_circle(Vector2(161, 126), 2.0, Color("e9b44c"))
	Decor.bed(ci, BED, WOOD, Color("5a7a9a"), SHEET)
	var desk := Decor.furniture(ci, TABLE, WOOD, 4.0)
	# The console on the desk: where the saves live. Its light is the room's
	# one cold colour.
	ci.draw_rect(Rect2(desk.position + Vector2(3, 3), Vector2(12, 7)), Decor.INK)
	ci.draw_rect(Rect2(desk.position + Vector2(4, 4), Vector2(10, 5)), Color("1e2a26"))
	ci.draw_rect(Rect2(desk.position + Vector2(5, 5), Vector2(3, 1.4)), Color("7fd6a8", 0.9))
	Decor.lamp(ci, desk.position + Vector2(desk.size.x - 7, desk.size.y * 0.5), Color("f0c070"))
	Decor.wall_shadow(ci, bounds, 12.0, 0.3)
	Decor.walls(ci, bounds, WALL, Color("7a6656"), Color("2e2620"))
	# On the top wall's face: a framed drawing, and the window frame.
	ci.draw_rect(Rect2(WINDOW.position.x - 1, WINDOW.position.y - 1, WINDOW.size.x + 2, WINDOW.size.y + 2), Decor.INK)
	ci.draw_rect(WINDOW, Color("c8e0f0"))
	ci.draw_line(Vector2(WINDOW.get_center().x, WINDOW.position.y), Vector2(WINDOW.get_center().x, WINDOW.end.y), Decor.INK, 0.8)
	ci.draw_rect(Rect2(372, 29, 14, 6), Decor.INK)
	ci.draw_rect(Rect2(373, 30, 12, 4), Color("e8c48a"))
