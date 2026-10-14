extends Node
## What the save file's owner knows about you.
##
## This survives deaths, quits, crashes and restarts. It lives OUTSIDE the
## save slot you are trapped in (user://owner_memory.json), which is the whole
## point: you can reload the world, but you can't reload the owner.

const SAVE_PATH := "user://owner_memory.json"
## When purge reaches this, the intruder is gone for good.
const MAX_PURGE := 6
const MAX_REMEMBERED_DEATHS := 12
## The owner never finds the last seam out of Arin's room.
const SEAM_COUNT := 5

var sessions: int = 0
var deaths: int = 0
var quits: int = 0
var wins: int = 0
var purge: int = 0
## Each death: {"area": String, "x": float, "y": float, "session": int}.
var deaths_log: Array[Dictionary] = []
var patched_seams: Array[int] = []
## Characters the owner has dealt with for helping you: name -> "deleted".
var npc_fates: Dictionary = {}
var met_archivist := false
## How the previous session ended: "none", "death", "quit", "crash", "win"
## (or "escape" from old saves). While a session is running it is stored as
## "active", so if the process is killed the owner finds out next launch.
var last_exit: String = "none"

## Not saved. Resources that should survive scene reloads (e.g. synthesized audio).
var runtime_cache: Dictionary = {}

## This session only: who helped you and how you got out of the room. The
## owner learns these when the session ends badly.
var session_helpers: Array[String] = []
var session_seam := -1

var _session_closed := true


func _ready() -> void:
	_register_input()
	load_memory()
	# We want to see the window close so the owner can count it as a quit.
	get_tree().set_auto_accept_quit(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		record_quit()
		get_tree().quit()


func is_purged() -> bool:
	return purge >= MAX_PURGE


func is_deleted(npc: String) -> bool:
	return npc_fates.get(npc, "") == "deleted"


func deaths_in(area: String) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for d in deaths_log:
		if d.get("area", "") == area:
			out.append(Vector2(float(d.x), float(d.y)))
	return out


## Starts a new session and returns how the previous one ended.
func begin_session() -> String:
	var previous := last_exit
	sessions += 1
	last_exit = "active"
	session_helpers.clear()
	session_seam = -1
	_session_closed = false
	save_memory()
	return previous


func note_helper(npc: String) -> void:
	if npc not in session_helpers:
		session_helpers.append(npc)


func note_seam(seam_id: int) -> void:
	session_seam = seam_id


func record_death(area: String, at: Vector2) -> void:
	if _session_closed:
		return
	deaths += 1
	purge += 1
	deaths_log.append({"area": area, "x": at.x, "y": at.y, "session": sessions})
	if deaths_log.size() > MAX_REMEMBERED_DEATHS:
		deaths_log.pop_front()
	_learn()
	_close_session("death")


func record_quit() -> void:
	if _session_closed:
		return
	quits += 1
	purge += 1
	_learn()
	_close_session("quit")


func record_win() -> void:
	if _session_closed:
		return
	wins += 1
	_close_session("win")


## Debug / "new game": forget everything the owner learned.
func wipe() -> void:
	sessions = 0
	deaths = 0
	quits = 0
	wins = 0
	purge = 0
	deaths_log.clear()
	patched_seams.clear()
	npc_fates.clear()
	met_archivist = false
	last_exit = "none"
	session_helpers.clear()
	session_seam = -1
	_session_closed = true
	save_memory()


func save_memory() -> void:
	var data := {
		"sessions": sessions,
		"deaths": deaths,
		"quits": quits,
		"wins": wins,
		"purge": purge,
		"deaths_log": deaths_log,
		"patched_seams": patched_seams,
		"npc_fates": npc_fates,
		"met_archivist": met_archivist,
		"last_exit": last_exit,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("OwnerMemory: could not write %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_memory() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("OwnerMemory: memory file unreadable, starting fresh")
		return
	var data: Dictionary = parsed
	sessions = int(data.get("sessions", 0))
	deaths = int(data.get("deaths", 0))
	quits = int(data.get("quits", 0))
	wins = int(data.get("wins", 0))
	purge = int(data.get("purge", 0))
	last_exit = str(data.get("last_exit", "none"))
	met_archivist = bool(data.get("met_archivist", false))
	deaths_log.clear()
	for d in data.get("deaths_log", []):
		if d is Dictionary and d.has("x") and d.has("y"):
			deaths_log.append(d)
	# Older saves only stored positions in Arin's room.
	for p in data.get("death_positions", []):
		if p is Array and p.size() == 2:
			deaths_log.append({"area": "room", "x": float(p[0]), "y": float(p[1]), "session": 0})
	patched_seams.clear()
	for id in data.get("patched_seams", []):
		patched_seams.append(int(id))
	var fates: Variant = data.get("npc_fates", {})
	npc_fates = fates if fates is Dictionary else {}

	# The last session never closed properly: the game was killed or crashed.
	# The owner treats that as running away.
	if last_exit == "active":
		quits += 1
		purge += 1
		last_exit = "crash"
		save_memory()


## A session ended badly: the owner goes through what happened.
func _learn() -> void:
	for npc in session_helpers:
		npc_fates[npc] = "deleted"
	if session_seam >= 0 and session_seam not in patched_seams and patched_seams.size() < SEAM_COUNT - 1:
		patched_seams.append(session_seam)


func _close_session(how: String) -> void:
	last_exit = how
	_session_closed = true
	save_memory()


func _register_input() -> void:
	# Keyboard keys are physical, so WASD works on QWERTZ/AZERTY layouts too.
	_add_action("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_add_action("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_add_action("move_up", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], JOY_AXIS_LEFT_Y, -1.0)
	_add_action("move_down", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_add_action("interact", [KEY_E, KEY_SPACE], [JOY_BUTTON_A])
	_add_action("confirm", [KEY_ENTER, KEY_KP_ENTER], [JOY_BUTTON_A])
	_add_action("pause", [KEY_ESCAPE], [JOY_BUTTON_START])
	_add_action("wipe_memory", [KEY_F9], [])


func _add_action(action: StringName, keys: Array, buttons: Array, axis: JoyAxis = JOY_AXIS_INVALID, direction := 0.0) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.3)
	for key: Key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
	for button: JoyButton in buttons:
		var pad := InputEventJoypadButton.new()
		pad.button_index = button
		InputMap.action_add_event(action, pad)
	if axis != JOY_AXIS_INVALID:
		var motion := InputEventJoypadMotion.new()
		motion.axis = axis
		motion.axis_value = direction
		InputMap.action_add_event(action, motion)
