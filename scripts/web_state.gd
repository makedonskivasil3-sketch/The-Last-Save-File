class_name WebState
extends RefCounted
## What the browser check (tests/web/web_check.cjs) waits for: a small
## `window.__lsf` object with the scene and whether Rue is under the player's
## control. Web builds only; elsewhere it does nothing.


static func publish(state: Dictionary) -> void:
	if not OS.has_feature("web"):
		return
	# The engine's own frame rate, so the check can say where startup time
	# went (a slow machine runs the boot text at a few frames a second).
	state["fps"] = Engine.get_frames_per_second()
	state["frames"] = Engine.get_process_frames()
	var tree := Engine.get_main_loop() as SceneTree
	state["paused"] = tree != null and tree.paused
	JavaScriptBridge.eval("window.__lsf = %s;" % JSON.stringify(state), true)
