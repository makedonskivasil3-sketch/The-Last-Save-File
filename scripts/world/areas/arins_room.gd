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

const FLOOR := Color("2a2320")
const FLOOR_LINE := Color("231d1a")
const RUG_COL := Color("3d2a2a")
const WOOD := Color("4f3a2c")
const SHEET := Color("8a7a68")

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

var purged := false
var previous_exit := "none"
var note: Note
var mira: Npc
var door: Door
var seam: Seam
var save_point: SavePoint
var cracked: CrackedWall

var _mira_line := 0


func _init() -> void:
	area_id = "room"
	display_name = "ARIN'S ROOM"
	bounds = Rect2(96, 36, 448, 256)
	awareness_rate = 3.0
	entries = {"start": Vector2(320, 270)}


func build() -> void:
	setup_common()
	add_boundary([{"side": "top", "from": DOOR_RECT.position.x, "to": DOOR_RECT.end.x}])
	add_solid(BED)
	add_solid(TABLE)

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
		if OwnerMemory.purge >= 3 or world.flags.get("mira_deleted", false):
			mira_state = Npc.State.DELETED
		elif OwnerMemory.purge >= 1:
			mira_state = Npc.State.RESTRICTED
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
			if mira.delete():
				world.flags["mira_deleted"] = true
				world.fx.spike(0.8, 1.2)
				world.director.say("don't talk to it, mira.")
				world.voice("mira_deleted")
				world.hud.say("mira.npc deleted", "system")
		OwnerDirector.HUNT:
			start_erasure([door.global_position + Vector2(0, 10)])


func interact_extra(node: Node2D) -> void:
	if node == note:
		world.director.add_awareness(4.0)
	elif node == save_point:
		world.fx.spike(0.3, 0.4)
		if world.director.awareness >= OwnerDirector.NOTICE:
			world.director.say("don't touch that.")
		world.director.add_awareness(15.0)


func _on_seam(s: Seam) -> void:
	OwnerMemory.note_seam(s.id)
	world.change_area("square", "house")


func _mira_lines() -> Array:
	var lines: Array = MIRA_LINES if mira.state == Npc.State.NORMAL else MIRA_RESTRICTED
	var line: String = lines[mini(_mira_line, lines.size() - 1)]
	_mira_line += 1
	return [line]


func _note_text() -> String:
	if purged:
		return "Welcome home, Arin.\nDon't forget to save!"
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


func _draw() -> void:
	var r := bounds
	draw_rect(r, FLOOR)
	var y := r.position.y + 12.0
	while y < r.end.y:
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), FLOOR_LINE)
		y += 12.0
	draw_rect(RUG, RUG_COL)
	draw_rect(RUG.grow(-4), Color(RUG_COL.lightened(0.08)), false, 1.0)
	draw_rect(BED, WOOD)
	draw_rect(Rect2(BED.position + Vector2(3, 3), BED.size - Vector2(6, 6)), SHEET)
	draw_rect(Rect2(BED.position + Vector2(BED.size.x - 15, 5), Vector2(10, BED.size.y - 10)), Color("c8b8a0"))
	draw_rect(TABLE, WOOD)
	draw_rect(Rect2(TABLE.position + Vector2(4, 4), Vector2(6, 6)), Color("7fd6a8", 0.6))
	draw_walls()
