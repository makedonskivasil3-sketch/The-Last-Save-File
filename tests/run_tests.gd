extends SceneTree
## Test runner. Finds every tests/test_*.gd, runs each `test_*` method on a
## fresh instance, prints a report and exits with code 0 (all passed) or 1.
##
##   godot --headless --path . -s res://tests/run_tests.gd -- --test-mode
##   ... -- --test-mode --filter=story          only files/methods containing "story"
##   ... -- --test-mode --screenshots=/tmp/s    also save screenshots (needs a display)
##
##   ... -- --test-mode --bots                  the playtest bots instead (tests/bot_*.gd):
##                                              slow, not part of the normal run
##   ... -- --test-mode --bots --speed=3         bots at 3x game speed
##
## Use tests/run.sh rather than calling this directly: it also fails the run
## if Godot printed any SCRIPT ERROR, which the runner itself can't observe.

const TEST_DIR := "res://tests/"
## A single test that takes longer than this is reported as hung.
const TEST_TIMEOUT := 90.0
## A bot plays whole runs: give it far longer.
const BOT_TIMEOUT := 3600.0

var _timeout := TEST_TIMEOUT

var _failed := 0
var _passed := 0
var _current := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not "--test-mode" in OS.get_cmdline_user_args():
		push_error("Run tests with `-- --test-mode` so they can't touch real save data.")
		quit(2)
		return
	var filter := ""
	var prefix := "test_"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			filter = arg.trim_prefix("--filter=")
		elif arg == "--bots":
			prefix = "bot_"
			_timeout = BOT_TIMEOUT
		elif arg.begins_with("--speed="):
			Engine.time_scale = clampf(float(arg.trim_prefix("--speed=")), 0.25, 8.0)

	var files := DirAccess.get_files_at(TEST_DIR)
	files.sort()
	var started := Time.get_ticks_msec()
	for file in files:
		if not (file.begins_with(prefix) and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		var script: GDScript = load(TEST_DIR + file)
		for method in script.get_script_method_list():
			var name: String = method.name
			if not name.begins_with("test_"):
				continue
			if filter != "" and filter not in file and filter not in name:
				continue
			await _run_one(script, file.get_basename(), name)

	var secs := (Time.get_ticks_msec() - started) / 1000.0
	print("")
	print("==== %d passed, %d failed (%.1fs) ====" % [_passed, _failed, secs])
	_cleanup()
	quit(1 if _failed > 0 else 0)


func _run_one(script: GDScript, file: String, method: String) -> void:
	_current = "%s.%s" % [file, method]
	var test = script.new()
	test.tree = self
	# Watchdog: a test that errors out mid-coroutine never returns.
	var watchdog := create_timer(_timeout, true, false, true)  # real seconds, whatever the game speed
	var on_timeout := _on_timeout.bind(_current)
	watchdog.timeout.connect(on_timeout)
	await test.before_each()
	await test.call(method)
	await test.after_each()
	watchdog.timeout.disconnect(on_timeout)
	if test.failures.is_empty():
		_passed += 1
		print("  PASS  ", _current)
	else:
		_failed += 1
		print("  FAIL  ", _current)
		for f in test.failures:
			print("        - ", f)


func _on_timeout(name: String) -> void:
	print("  FAIL  ", name, "\n        - timed out after %ds (a script error or a hang)" % _timeout)
	_failed += 1
	_cleanup()
	quit(1)


func _cleanup() -> void:
	var mem := root.get_node_or_null("OwnerMemory")
	if mem:
		mem.wipe()
