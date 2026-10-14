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

var sessions: int = 0
var deaths: int = 0
var quits: int = 0
var escapes: int = 0
var purge: int = 0
var death_positions: Array[Vector2] = []
var patched_seams: Array[int] = []
## How the previous session ended: "none", "death", "quit", "crash", "escape".
## While a session is running it is stored as "active", so if the process is
## killed the owner finds out next launch.
var last_exit: String = "none"

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


## Starts a new session and returns how the previous one ended.
func begin_session() -> String:
	var previous := last_exit
	sessions += 1
	last_exit = "active"
	_session_closed = false
	save_memory()
	return previous


func record_death(at: Vector2) -> void:
	if _session_closed:
		return
	deaths += 1
	purge += 1
	death_positions.append(at)
	if death_positions.size() > MAX_REMEMBERED_DEATHS:
		death_positions.pop_front()
	_close_session("death")


func record_quit() -> void:
	if _session_closed:
		return
	quits += 1
	purge += 1
	_close_session("quit")


func record_escape(seam_id: int) -> void:
	if _session_closed:
		return
	escapes += 1
	if seam_id not in patched_seams:
		patched_seams.append(seam_id)
	_close_session("escape")


## Debug / "new game": forget everything the owner learned.
func wipe() -> void:
	sessions = 0
	deaths = 0
	quits = 0
	escapes = 0
	purge = 0
	death_positions.clear()
	patched_seams.clear()
	last_exit = "none"
	_session_closed = true
	save_memory()


func save_memory() -> void:
	var positions: Array = []
	for p in death_positions:
		positions.append([p.x, p.y])
	var data := {
		"sessions": sessions,
		"deaths": deaths,
		"quits": quits,
		"escapes": escapes,
		"purge": purge,
		"death_positions": positions,
		"patched_seams": patched_seams,
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
	escapes = int(data.get("escapes", 0))
	purge = int(data.get("purge", 0))
	last_exit = str(data.get("last_exit", "none"))
	death_positions.clear()
	for p in data.get("death_positions", []):
		if p is Array and p.size() == 2:
			death_positions.append(Vector2(float(p[0]), float(p[1])))
	patched_seams.clear()
	for id in data.get("patched_seams", []):
		patched_seams.append(int(id))

	# The last session never closed properly: the game was killed or crashed.
	# The owner treats that as running away.
	if last_exit == "active":
		quits += 1
		purge += 1
		last_exit = "crash"
		save_memory()


func _close_session(how: String) -> void:
	last_exit = how
	_session_closed = true
	save_memory()


func _register_input() -> void:
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("move_up", [KEY_W, KEY_UP])
	_add_action("move_down", [KEY_S, KEY_DOWN])
	_add_action("interact", [KEY_E, KEY_SPACE])
	_add_action("confirm", [KEY_ENTER, KEY_KP_ENTER])
	_add_action("quit_game", [KEY_ESCAPE])
	_add_action("wipe_memory", [KEY_F9])


func _add_action(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key: Key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
