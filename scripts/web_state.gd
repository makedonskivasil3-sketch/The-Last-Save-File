class_name WebState
extends RefCounted
## What the browser check (tests/web/web_check.cjs) waits for: a small
## `window.__lsf` object with the scene and whether Rue is under the player's
## control. Web builds only; elsewhere it does nothing.


static func publish(state: Dictionary) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.__lsf = %s;" % JSON.stringify(state), true)
