extends Node
## What the save file's owner knows about you.
##
## This survives deaths, quits, crashes and restarts. It lives OUTSIDE the
## save slot you are trapped in (user://owner_memory.json), which is the whole
## point: you can reload the world, but you can't reload the owner.

const SAVE_PATH := "user://owner_memory.json"
## Automated tests run with `-- --test-mode` and use their own file, so they
## can never touch a player's real progress.
const TEST_SAVE_PATH := "user://test_owner_memory.json"
## When purge reaches this, the intruder is gone for good.
const MAX_PURGE := 6
const MAX_REMEMBERED_DEATHS := 12
## The owner never finds the last seam out of Arin's room.
const SEAM_COUNT := 5
## Bump when the save's shape changes, and teach _migrate the old shape.
const SAVE_VERSION := 1

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
## Pip, Rue's fox, found out of bounds. Pip was never in the save, so the
## owner can't take it away: once found, Pip stays with you.
var found_pip := false
## Wren saw the Edge with you: she's logged as cut content now, and the
## owner can never delete her again.
var wren_saved := false
## How many of the owner's notes you've read (they come one a run).
var owner_notes_seen: int = 0
## Glitches this run, and last run's total (the owner notices).
var session_glitches: int = 0
var last_run_glitches: int = 0
var total_glitches: int = 0
## Times the owner has reloaded you, ever.
var total_reloads: int = 0
## You took the memory the owner planted.
var false_memory_taken: bool = false
## Mira's note: "" (not given), "carried", "pinned" or "lost".
var mira_quest: String = ""
## Rue's name is back in Tobben's guest book.
var guestbook_restored: bool = false
## Read the torn guest book page in the Recycle Bin.
var found_guestbook := false
## Found the second controller under the couch in Arin's house.
var found_controller := false
## How the last game ended at Slot 2: "escape", "wren" or "message" ("" if
## never), and every ending reached so far.
var last_ending := ""
## Why you died last (a key of Story.DEATHS), for lines next time.
var last_death := ""
## How often each kind of death got you (records screen).
var death_causes: Dictionary = {}
## Deaths to the static at the Edge in a row (each buys a longer grace).
var edge_static_deaths := 0
## The Edge's one free death has been used (until you next reach Slot 2).
var edge_mercy_used := false
## Characters you brought back with RESTORE, ever.
var restored: Array[String] = []
var endings_seen: Array[String] = []
## Where the owner has seen you go in each area, learned when a session ends
## badly: {"area", "x", "y", "w" (weight)}. Arin's patrol detours through
## the heaviest spots next time.
var route_memory: Array[Dictionary] = []
## This session only: spots the owner noticed you at ({"area", "pos"}).
var session_spots: Array[Dictionary] = []
## Story acts whose title card has been shown (Story.ACTS ids).
var acts_seen: Array[String] = []
## Memory fragments the intruder has recovered (Story.FRAGMENTS ids). These
## are YOUR memories, not the owner's: they survive deaths and purges, and
## only a full reset clears them.
var fragments: Array[String] = []
## How the previous session ended: "none", "death", "quit", "crash", "win"
## (or "escape" from old saves). While a session is running it is stored as
## "active", so if the process is killed the owner finds out next launch.
var last_exit: String = "none"

## Not saved. Resources that should survive scene reloads (e.g. synthesized audio).
var runtime_cache: Dictionary = {}

## This session only: who helped you and how you got out of the room. The
## owner learns these when the session ends badly.
var session_helpers: Array[String] = []
## How the session before this one ended (last_exit is "active" while
## one runs).
var previous_exit := "none"
## Characters who already said their "remember last time" line this session.
var session_recalled: Array[String] = []
var session_seam := -1

var _session_closed := true
var _path := SAVE_PATH


func _ready() -> void:
	if is_test_mode():
		_path = TEST_SAVE_PATH
	_register_input()
	load_memory()
	# We want to see the window close so the owner can count it as a quit.
	get_tree().set_auto_accept_quit(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		record_quit()
		get_tree().quit()


static func is_test_mode() -> bool:
	return "--test-mode" in OS.get_cmdline_user_args()


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
	previous_exit = previous
	last_run_glitches = session_glitches
	session_glitches = 0
	sessions += 1
	last_exit = "active"
	session_helpers.clear()
	session_recalled.clear()
	session_seam = -1
	session_spots.clear()
	_session_closed = false
	save_memory()
	_leave_guard(true)
	return previous


func has_fragment(id: String) -> bool:
	return id in fragments


func add_fragment(id: String) -> void:
	if id not in fragments:
		fragments.append(id)
		save_memory()


## Mira's note, still in your pocket when the run ends badly: the owner
## finds it.
func _lose_carried_note() -> void:
	if mira_quest == "carried":
		mira_quest = "lost"


## Brought someone back with RESTORE (remembered across runs).
func note_restored(npc: String) -> void:
	if npc not in restored:
		restored.append(npc)
	save_memory()


func note_helper(npc: String) -> void:
	if npc not in session_helpers:
		session_helpers.append(npc)


func note_seam(seam_id: int) -> void:
	session_seam = seam_id


## Returns true when the death was forgiven: the first death at the Edge
## (the world isn't loaded out there; the owner didn't see it) doesn't add
## to the purge. That mercy comes back when you reach Slot 2.
func record_death(area: String, at: Vector2, reason := "") -> bool:
	if _session_closed:
		return false
	last_death = reason
	if reason != "":
		death_causes[reason] = int(death_causes.get(reason, 0)) + 1
	# The static at the Edge waits a little longer each time it gets you there.
	if area == "edge" and reason == "eraser":
		edge_static_deaths += 1
	elif area != "edge":
		edge_static_deaths = 0
	_lose_carried_note()
	var forgiven := area == "edge" and not edge_mercy_used
	if forgiven:
		edge_mercy_used = true
	deaths += 1
	if not forgiven:
		purge += 1
	deaths_log.append({"area": area, "x": at.x, "y": at.y, "session": sessions})
	if deaths_log.size() > MAX_REMEMBERED_DEATHS:
		deaths_log.pop_front()
	_learn()
	_close_session("death")
	return forgiven


func record_quit() -> void:
	if _session_closed:
		return
	_lose_carried_note()
	quits += 1
	purge += 1
	_learn()
	_close_session("quit")


## Reached Slot 2 and chose an ending ("escape", "rue", "wren", "message",
## or one of the hidden ones: "unseen", "overwrite").
func record_win(ending := "escape") -> void:
	if _session_closed:
		return
	wins += 1
	last_ending = ending
	if ending not in endings_seen:
		endings_seen.append(ending)
	edge_mercy_used = false
	edge_static_deaths = 0
	# Taking the slot remembering everything is its own ending: RUE.
	if ending == "rue" and "escape" not in endings_seen:
		endings_seen.append("escape")  # RUE is also the slot, taken
	if ending == "escape" and fragments.size() >= Story.FRAGMENTS.size() and "rue" not in endings_seen:
		endings_seen.append("rue")
	if ending == "message":
		# Reconciliation: the owner stops the purge and lets everyone back.
		purge = 0
		npc_fates.clear()
	_close_session("win")


## Debug / "new game": forget everything the owner learned.
func wipe() -> void:
	_leave_guard(false)
	sessions = 0
	deaths = 0
	quits = 0
	wins = 0
	purge = 0
	deaths_log.clear()
	patched_seams.clear()
	npc_fates.clear()
	met_archivist = false
	found_pip = false
	wren_saved = false
	found_guestbook = false
	found_controller = false
	owner_notes_seen = 0
	session_glitches = 0
	last_run_glitches = 0
	total_glitches = 0
	total_reloads = 0
	false_memory_taken = false
	mira_quest = ""
	guestbook_restored = false
	last_ending = ""
	last_death = ""
	edge_static_deaths = 0
	edge_mercy_used = false
	death_causes.clear()
	restored.clear()
	session_recalled.clear()
	previous_exit = "none"
	endings_seen.clear()
	route_memory.clear()
	session_spots.clear()
	acts_seen.clear()
	fragments.clear()
	last_exit = "none"
	session_helpers.clear()
	session_seam = -1
	_session_closed = true
	save_memory()
	SafeFile.remove_copies(_path)  # a reset shouldn't be undone by the backup


func save_memory() -> void:
	var data := {
		"version": SAVE_VERSION,
		"sessions": sessions,
		"deaths": deaths,
		"quits": quits,
		"wins": wins,
		"purge": purge,
		"deaths_log": deaths_log,
		"patched_seams": patched_seams,
		"npc_fates": npc_fates,
		"met_archivist": met_archivist,
		"found_pip": found_pip,
		"wren_saved": wren_saved,
		"found_guestbook": found_guestbook,
		"found_controller": found_controller,
		"owner_notes_seen": owner_notes_seen,
		"session_glitches": session_glitches,
		"last_run_glitches": last_run_glitches,
		"total_glitches": total_glitches,
		"total_reloads": total_reloads,
		"false_memory_taken": false_memory_taken,
		"mira_quest": mira_quest,
		"guestbook_restored": guestbook_restored,
		"last_ending": last_ending,
		"endings_seen": endings_seen,
		"last_death": last_death,
		"edge_static_deaths": edge_static_deaths,
		"edge_mercy_used": edge_mercy_used,
		"death_causes": death_causes,
		"restored": restored,
		"acts_seen": acts_seen,
		"route_memory": route_memory,
		"fragments": fragments,
		"last_exit": last_exit,
	}
	SafeFile.write_atomic(_path, JSON.stringify(data, "\t"))


## Brings an older save up to SAVE_VERSION. Files from before versioning are
## version 0; their only difference (death_positions) is read in load_memory.
## A save from a NEWER build is read as far as this build understands it.
func _migrate(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return data
	var version := _int(data, "version", 0)
	if version > SAVE_VERSION:
		push_warning("OwnerMemory: save is from a newer version (%d > %d)" % [version, SAVE_VERSION])
	# (version 0 -> 1: nothing to convert, the reader handles both.)
	return data


# Typed reads: a hand-edited or damaged value falls back to the default
# instead of stopping the load half-way.
static func _num(d: Dictionary, key: String) -> bool:
	return d.get(key) is float or d.get(key) is int


static func _int(d: Dictionary, key: String, fallback: int, most := 1 << 30) -> int:
	return clampi(int(d[key]), 0, most) if _num(d, key) else fallback


static func _bool(d: Dictionary, key: String) -> bool:
	var v: Variant = d.get(key, false)
	return v if v is bool else false


static func _str(d: Dictionary, key: String, fallback: String) -> String:
	var v: Variant = d.get(key, fallback)
	return v if v is String else fallback


static func _list(d: Dictionary, key: String) -> Array:
	var v: Variant = d.get(key, [])
	return v if v is Array else []


## A list of unique strings (anything else in it is dropped).
static func _strings(d: Dictionary, key: String) -> Array[String]:
	var out: Array[String] = []
	for v in _list(d, key):
		if v is String and v not in out:
			out.append(v)
	return out


func load_memory() -> void:
	var read: Array = SafeFile.read_json(_path)
	var data: Dictionary = _migrate(read[0])
	if data.is_empty():
		return
	sessions = _int(data, "sessions", 0)
	deaths = _int(data, "deaths", 0)
	quits = _int(data, "quits", 0)
	wins = _int(data, "wins", 0)
	purge = _int(data, "purge", 0, MAX_PURGE)
	last_exit = _str(data, "last_exit", "none")
	met_archivist = _bool(data, "met_archivist")
	found_pip = _bool(data, "found_pip")
	wren_saved = _bool(data, "wren_saved")
	found_guestbook = _bool(data, "found_guestbook")
	found_controller = _bool(data, "found_controller")
	owner_notes_seen = _int(data, "owner_notes_seen", 0)
	session_glitches = _int(data, "session_glitches", 0)
	last_run_glitches = _int(data, "last_run_glitches", 0)
	total_glitches = _int(data, "total_glitches", 0)
	total_reloads = _int(data, "total_reloads", 0)
	false_memory_taken = _bool(data, "false_memory_taken")
	mira_quest = _str(data, "mira_quest", "")
	guestbook_restored = _bool(data, "guestbook_restored")
	last_ending = _str(data, "last_ending", "")
	endings_seen.assign(_strings(data, "endings_seen"))
	last_death = _str(data, "last_death", "")
	edge_static_deaths = _int(data, "edge_static_deaths", 0)
	edge_mercy_used = _bool(data, "edge_mercy_used")
	death_causes.clear()
	var causes: Variant = data.get("death_causes", {})
	if causes is Dictionary:
		for k in causes:
			if causes[k] is float or causes[k] is int:
				death_causes[str(k)] = maxi(0, int(causes[k]))
	restored.assign(_strings(data, "restored"))
	route_memory.clear()
	for r in _list(data, "route_memory"):
		if r is Dictionary and _num(r, "x") and _num(r, "y") and _num(r, "w") and r.get("area") is String:
			route_memory.append(r)
	acts_seen.assign(_strings(data, "acts_seen"))
	fragments.assign(_strings(data, "fragments"))
	deaths_log.clear()
	for d in _list(data, "deaths_log"):
		if d is Dictionary and _num(d, "x") and _num(d, "y") and d.get("area") is String:
			deaths_log.append(d)
	# Older saves only stored positions in Arin's room.
	for p in _list(data, "death_positions"):
		if p is Array and p.size() == 2 and (p[0] is float or p[0] is int) and (p[1] is float or p[1] is int):
			deaths_log.append({"area": "room", "x": float(p[0]), "y": float(p[1]), "session": 0})
	while deaths_log.size() > MAX_REMEMBERED_DEATHS:
		deaths_log.pop_front()
	patched_seams.clear()
	for id in _list(data, "patched_seams"):
		if (id is float or id is int) and int(id) not in patched_seams and patched_seams.size() < SEAM_COUNT - 1:
			patched_seams.append(int(id))
	npc_fates.clear()
	var fates: Variant = data.get("npc_fates", {})
	if fates is Dictionary:
		for k in fates:
			npc_fates[str(k)] = str(fates[k])

	# The last session never closed properly: the game was killed or crashed.
	# The owner treats that as running away.
	if last_exit == "active":
		quits += 1
		purge += 1
		last_exit = "crash"
		save_memory()


## A session ended badly: the owner goes through what happened.
## The owner noticed you here (Arin saw you, or you lingered).
func note_spot(area: String, pos: Vector2) -> void:
	if session_spots.size() < 64:
		session_spots.append({"area": area, "pos": pos})


## The heaviest remembered spots in an area, heaviest first.
func route_spots(area: String, count: int) -> Array[Vector2]:
	var mine := route_memory.filter(func(r: Dictionary) -> bool: return r.get("area", "") == area)
	mine.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.w) > float(b.w))
	var out: Array[Vector2] = []
	for r in mine.slice(0, count):
		out.append(Vector2(float(r.x), float(r.y)))
	return out


func _learn() -> void:
	if wren_saved:
		session_helpers.erase("wren")  # out of the owner's reach
	# Route memory: cluster this session's spots on a 40-pixel grid.
	for s in session_spots:
		var at: Vector2 = s.pos
		var cell: Vector2 = (at / 40.0).floor() * 40.0 + Vector2(20, 20)
		var found := false
		for r in route_memory:
			if r.area == s.area and Vector2(float(r.x), float(r.y)) == cell:
				r.w = float(r.w) + 1.0
				found = true
				break
		if not found:
			route_memory.append({"area": s.area, "x": cell.x, "y": cell.y, "w": 1.0})
	route_memory.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.w) > float(b.w))
	if route_memory.size() > 16:
		route_memory.resize(16)
	for npc in session_helpers:
		npc_fates[npc] = "deleted"
	if session_seam >= 0 and session_seam not in patched_seams and patched_seams.size() < SEAM_COUNT - 1:
		patched_seams.append(session_seam)


func _close_session(how: String) -> void:
	last_exit = how
	_session_closed = true
	save_memory()
	_leave_guard(false)


## Web: closing the tab mid-run counts as quitting (the next visit finds the
## session still "active"), so while a run is open the browser asks first
## ("Leave site?"). The author's rule: count it, but warn. Desktop builds get
## a close request instead (record_quit), so this is web-only.
static func _leave_guard(on: bool) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
		if (!window.__tlsfGuard) {
			window.__tlsfGuard = true;
			window.addEventListener('beforeunload', function (e) {
				if (window.__tlsfRunning) { e.preventDefault(); e.returnValue = ''; }
			});
		}
		window.__tlsfRunning = %s;
	""" % ("true" if on else "false"), true)


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
	# Menus with a gamepad: make sure the built-in ui actions take the stick,
	# the d-pad, A and B (whatever the engine's defaults are).
	_ensure_pad("ui_up", JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0)
	_ensure_pad("ui_down", JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	_ensure_pad("ui_left", JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_ensure_pad("ui_right", JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_ensure_pad("ui_accept", JOY_BUTTON_A)
	_ensure_pad("ui_cancel", JOY_BUTTON_B)


func _ensure_pad(action: StringName, button: JoyButton, axis: JoyAxis = JOY_AXIS_INVALID, direction := 0.0) -> void:
	if not InputMap.has_action(action):
		return
	var has_button := false
	var has_axis := axis == JOY_AXIS_INVALID
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == button:
			has_button = true
		elif e is InputEventJoypadMotion and (e as InputEventJoypadMotion).axis == axis \
				and signf((e as InputEventJoypadMotion).axis_value) == signf(direction):
			has_axis = true
	if not has_button:
		var pad := InputEventJoypadButton.new()
		pad.button_index = button
		InputMap.action_add_event(action, pad)
	if not has_axis:
		var motion := InputEventJoypadMotion.new()
		motion.axis = axis
		motion.axis_value = direction
		InputMap.action_add_event(action, motion)


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
