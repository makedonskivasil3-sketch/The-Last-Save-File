class_name PlaytestLog
## Development-only progression log for observed playtests
## (docs/PLAYTEST_PLAN.md): a timestamp for each moment on the session sheet
## (first movement, leaving the room, first glitch, deaths, memories, the
## pointer, the Edge, endings, quits, owner thresholds).
##
## Off unless asked for: the web build with ?playtest=1 in the address, or a
## desktop build started with `-- --playtest`. Lines go to the pause menu's
## "Playtest log" page, the browser console / stdout, and
## user://playtest_log.txt. Nothing is ever sent anywhere.

const PATH := "user://playtest_log.txt"

static var lines: Array[String] = []
static var _on := -1
static var _start_ms := -1
static var _once: Dictionary = {}


static func enabled() -> bool:
	if _on == -1:
		var on := "--playtest" in OS.get_cmdline_user_args()
		if not on and OS.has_feature("web"):
			on = str(JavaScriptBridge.eval("window.location.search", true)).contains("playtest")
		_on = 1 if on else 0
	return _on == 1


## Record a moment. once: only the first time this event happens (this launch).
static func mark(event: String, detail := "", once := false) -> void:
	if not enabled():
		return
	if once:
		if _once.has(event):
			return
		_once[event] = true
	if _start_ms < 0:
		_start_ms = Time.get_ticks_msec()
	var s := (Time.get_ticks_msec() - _start_ms) / 1000
	var line := "%02d:%02d  %s%s" % [s / 60, s % 60, event, ("  ·  " + detail) if detail != "" else ""]
	lines.append(line)
	if lines.size() > 400:
		lines.pop_front()
	print("PLAYTEST ", line)
	var f := FileAccess.open(PATH, FileAccess.READ_WRITE if FileAccess.file_exists(PATH) else FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(line)
		f.close()


## For tests.
static func reset(on: bool) -> void:
	_on = 1 if on else 0
	_start_ms = -1
	_once.clear()
	lines.clear()
