class_name Room
extends Node2D
## Arin's room. The first (and so far only) place in someone else's save.
##
## Builds the space from OwnerMemory each session, so the room you load into
## reflects everything the owner has learned about you.

const ROOM := Rect2(96, 36, 448, 256)
const WALL := 8.0
const DOOR_RECT := Rect2(304, 28, 32, 8)
const NOTE_POS := Vector2(150, 32)
const MIRA_POS := Vector2(440, 130)
const SAVE_POS := Vector2(420, 236)
const BED := Rect2(470, 44, 58, 32)
const TABLE := Rect2(116, 216, 36, 22)
const RUG := Rect2(256, 130, 128, 80)
## Gaps the owner hasn't rewritten yet. Each escape patches one.
const SEAM_SPOTS: Array[Rect2] = [
	Rect2(88, 170, 12, 22),
	Rect2(540, 210, 12, 22),
	Rect2(400, 288, 22, 12),
	Rect2(200, 28, 22, 12),
	Rect2(88, 70, 12, 22),
]
const DOOR_TRIGGER_DISTANCE := 70.0
const INTERACT_DISTANCE := 22.0
const WIPE_HOLD_TIME := 1.5

const FLOOR := Color("2a2320")
const FLOOR_LINE := Color("231d1a")
const WALL_COL := Color("4a3b33")
const WALL_EDGE := Color("6b5546")
const RUG_COL := Color("3d2a2a")
const WOOD := Color("4f3a2c")
const SHEET := Color("8a7a68")

var note: Note
var mira: Npc
var door: Door
var seam: Seam
var save_point: SavePoint
var erasure: Erasure

var _interactables: Array[Node2D] = []
var _focused: Node2D
var _ending := ""  # "", "death", "quit", "escape"
var _purged := false
var _wipe_hold := 0.0
var _light: CanvasModulate
var _base_light := Color(1, 1, 1)

@onready var player: Player = $Player
@onready var director: OwnerDirector = $OwnerDirector
@onready var hud: Hud = $HUD
@onready var fx: ScreenFx = $ScreenFX/Effect
@onready var drone: Drone = $Drone


func _ready() -> void:
	player.z_index = 10
	_build_walls()
	_light = CanvasModulate.new()
	add_child(_light)

	if OwnerMemory.is_purged():
		_build_purged()
		return

	var previous := OwnerMemory.begin_session()
	_place_props(previous)
	_base_light = Color(1, 1, 1).lerp(Color(0.55, 0.5, 0.6), OwnerMemory.purge / float(OwnerMemory.MAX_PURGE))
	_light.color = _base_light
	hud.unknown_processes = 1 if OwnerMemory.purge >= 2 else 0
	fx.spike(0.6, 1.0)  # loading into a save you don't belong in
	director.start(self, previous)


func _process(delta: float) -> void:
	_handle_wipe(delta)
	if _purged:
		if Input.is_action_just_pressed("quit_game"):
			get_tree().quit()
		return

	match _ending:
		"":
			pass
		"escape":
			if Input.is_action_just_pressed("confirm"):
				get_tree().reload_current_scene()
			elif Input.is_action_just_pressed("quit_game"):
				get_tree().quit()
			return
		_:
			return

	if Input.is_action_just_pressed("quit_game"):
		_quit()
		return

	if door.state == Door.State.OPEN and player.global_position.distance_to(door.global_position) < DOOR_TRIGGER_DISTANCE:
		director.on_door_approached()

	seam_reveal()
	_update_focus()
	if _focused and Input.is_action_just_pressed("interact"):
		_interact(_focused)


func seams_remaining() -> int:
	return SEAM_SPOTS.size() - OwnerMemory.patched_seams.size()


func seam_reveal() -> void:
	if seam:
		seam.reveal = 0.2 + director.awareness / 100.0 * 0.6


func start_erasure() -> void:
	erasure.active = true
	erasure.interval = maxf(0.12, 0.45 - 0.06 * OwnerMemory.purge)
	erasure.burst = 1 + OwnerMemory.purge / 2
	# It starts where you died before. The owner remembers.
	for p in OwnerMemory.death_positions:
		erasure.seed_at(p)
	erasure.seed_at(door.global_position + Vector2(0, 10))
	fx.spike(0.9, 1.0)


func flicker_lights() -> void:
	var tw := create_tween()
	for i in 3:
		tw.tween_property(_light, "color", Color(0.25, 0.2, 0.25), 0.05)
		tw.tween_property(_light, "color", _base_light, 0.08)
	fx.spike(0.4, 0.5)


func _build_walls() -> void:
	var body := StaticBody2D.new()
	add_child(body)
	var r := ROOM
	var rects: Array[Rect2] = [
		Rect2(r.position.x - WALL, r.position.y - WALL, DOOR_RECT.position.x - r.position.x + WALL, WALL),
		Rect2(DOOR_RECT.end.x, r.position.y - WALL, r.end.x - DOOR_RECT.end.x + WALL, WALL),
		Rect2(r.position.x - WALL, r.end.y, r.size.x + WALL * 2, WALL),
		Rect2(r.position.x - WALL, r.position.y, WALL, r.size.y),
		Rect2(r.end.x, r.position.y, WALL, r.size.y),
		BED,
		TABLE,
	]
	for rect in rects:
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var col := CollisionShape2D.new()
		col.shape = shape
		col.position = rect.get_center()
		body.add_child(col)


func _place_props(previous: String) -> void:
	erasure = Erasure.new()
	erasure.setup(ROOM, player)
	erasure.caught_player.connect(_on_player_erased)
	add_child(erasure)

	for i in OwnerMemory.death_positions.size():
		var g := GhostMarker.new()
		g.index = i
		g.position = OwnerMemory.death_positions[i]
		add_child(g)

	door = Door.new()
	add_child(door)
	door.setup(DOOR_RECT, Door.State.OPEN if OwnerMemory.sessions == 1 else Door.State.DELETED)

	note = Note.new()
	note.position = NOTE_POS
	note.player = player
	note.text = _note_text_for(previous)
	add_child(note)

	mira = Npc.new()
	mira.position = MIRA_POS
	mira.player = player
	var mira_state := Npc.State.NORMAL
	if OwnerMemory.purge >= 3:
		mira_state = Npc.State.DELETED
	elif OwnerMemory.purge >= 1:
		mira_state = Npc.State.RESTRICTED
	add_child(mira)
	mira.setup(mira_state)

	save_point = SavePoint.new()
	save_point.position = SAVE_POS
	add_child(save_point)

	for i in SEAM_SPOTS.size():
		if i not in OwnerMemory.patched_seams:
			seam = Seam.new()
			add_child(seam)
			seam.setup(i, SEAM_SPOTS[i])
			seam.slipped_through.connect(_on_escape)
			break

	_interactables = [note, mira, save_point]


func _note_text_for(previous: String) -> String:
	match previous:
		"death":
			return "I REMEMBER WHERE\nYOU DIED."
		"quit", "crash":
			return "CLOSING THE GAME\nWON'T SAVE YOU."
		"escape":
			return "I FOUND YOUR\nLITTLE GAP."
	if OwnerMemory.sessions > 1:
		return "I SAW YOU."
	return "Welcome home, Arin.\nDon't forget to save!"


func _update_focus() -> void:
	_focused = null
	var best := INTERACT_DISTANCE
	for node in _interactables:
		if not node.can_interact():
			continue
		var d := player.global_position.distance_to(node.global_position)
		if d < best:
			best = d
			_focused = node
	hud.set_prompt(_focused.interact_prompt() if _focused else "")


func _interact(node: Node2D) -> void:
	var line: String = node.interact()
	if node == mira:
		hud.say(line, "npc", mira.display_name)
		director.add_awareness(8.0)
	elif node == note:
		hud.say("NOTE: " + line, "system")
		director.add_awareness(4.0)
	elif node == save_point:
		hud.say(line, "system")
		fx.spike(0.3, 0.4)
		if director.awareness >= OwnerDirector.NOTICE:
			hud.say("don't touch that.", "owner")
		director.add_awareness(15.0)


func _on_player_erased() -> void:
	if _ending != "":
		return
	_ending = "death"
	player.frozen = true
	director.stop()
	hud.clear_queue()
	hud.set_prompt("")
	fx.spike(1.0, 2.5)
	drone.tension = 1.0
	OwnerMemory.record_death(player.global_position)
	var body := "the owner learned something."
	if OwnerMemory.is_purged():
		body = "the owner has learned enough."
	hud.show_overlay("ERASED", body)
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()


func _on_escape(s: Seam) -> void:
	if _ending != "":
		return
	_ending = "escape"
	player.frozen = true
	director.stop()
	hud.clear_queue()
	hud.set_prompt("")
	erasure.active = false
	fx.spike(1.0, 1.5)
	OwnerMemory.record_escape(s.id)
	hud.show_overlay(
		"YOU SLIPPED THROUGH",
		"a gap the owner hasn't written yet.\n\n— end of prototype —\n\n[ENTER] load the save again      [ESC] quit",
		Color("8cf2ff")
	)


func _quit() -> void:
	_ending = "quit"
	player.frozen = true
	director.stop()
	hud.clear_queue()
	OwnerMemory.record_quit()
	hud.show_overlay("QUITTING", "leaving? i'll still be here.")
	fx.spike(0.5, 1.5)
	await get_tree().create_timer(1.6).timeout
	get_tree().quit()


func _build_purged() -> void:
	_purged = true
	player.queue_free()
	_light.color = Color(1.05, 1.0, 0.95)

	door = Door.new()
	add_child(door)
	door.setup(DOOR_RECT, Door.State.OPEN)

	note = Note.new()
	note.position = NOTE_POS
	note.text = "Welcome home, Arin.\nDon't forget to save!"
	add_child(note)

	mira = Npc.new()
	mira.position = MIRA_POS
	add_child(mira)
	mira.setup(Npc.State.NORMAL)

	# The real Arin, back where you used to stand.
	var arin := Npc.new()
	arin.display_name = "ARIN"
	arin.dress_color = Color("5a7fb0")
	arin.hair_color = Color("2a2a30")
	arin.position = Vector2(320, 270)
	add_child(arin)
	arin.setup(Npc.State.NORMAL)

	save_point = SavePoint.new()
	save_point.position = SAVE_POS
	add_child(save_point)

	hud.set_awareness(0.0)
	hud.say("SCAN COMPLETE: 0 UNKNOWN PROCESSES", "system")
	hud.say("there. clean.", "owner")
	hud.say("welcome back, arin.", "owner")
	hud.set_hint("hold F9 to restore the intruder")
	drone.volume_db = -30.0


## Hold F9 to make the owner forget everything (a "new game" for the intruder).
func _handle_wipe(delta: float) -> void:
	if Input.is_action_pressed("wipe_memory"):
		_wipe_hold += delta
		hud.set_hint("restoring intruder… %d%%" % int(100.0 * _wipe_hold / WIPE_HOLD_TIME))
		if _wipe_hold >= WIPE_HOLD_TIME:
			OwnerMemory.wipe()
			get_tree().reload_current_scene()
	elif _wipe_hold > 0.0:
		_wipe_hold = 0.0
		hud.set_hint("hold F9 to restore the intruder" if _purged else "")


func _draw() -> void:
	var r := ROOM
	draw_rect(r, FLOOR)
	var y := r.position.y + 12.0
	while y < r.end.y:
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), FLOOR_LINE)
		y += 12.0
	draw_rect(RUG, RUG_COL)
	draw_rect(RUG.grow(-4), Color(RUG_COL.lightened(0.08)), false, 1.0)

	# Bed and table: the owner's character's things.
	draw_rect(BED, WOOD)
	draw_rect(Rect2(BED.position + Vector2(3, 3), Vector2(BED.size.x - 6, BED.size.y - 6)), SHEET)
	draw_rect(Rect2(BED.position + Vector2(BED.size.x - 15, 5), Vector2(10, BED.size.y - 10)), Color("c8b8a0"))
	draw_rect(TABLE, WOOD)
	draw_rect(Rect2(TABLE.position + Vector2(4, 4), Vector2(6, 6)), Color("7fd6a8", 0.6))

	# Walls (top wall is split around the door).
	var top := r.position.y - WALL
	draw_rect(Rect2(r.position.x - WALL, top, r.size.x + WALL * 2, WALL), WALL_COL)
	draw_rect(Rect2(r.position.x - WALL, r.end.y, r.size.x + WALL * 2, WALL), WALL_COL)
	draw_rect(Rect2(r.position.x - WALL, r.position.y, WALL, r.size.y), WALL_COL)
	draw_rect(Rect2(r.end.x, r.position.y, WALL, r.size.y), WALL_COL)
	draw_rect(r.grow(WALL), WALL_EDGE, false, 1.0)
	draw_rect(r, WALL_EDGE, false, 1.0)
