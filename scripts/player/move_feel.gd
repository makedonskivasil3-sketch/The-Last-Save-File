class_name MoveFeel
## Movement tuning variants for side-by-side playtests
## (docs/production/MOVEMENT_SPEC.md, "Variants"). The default is C, the
## shipped movement; A and B exist to be compared against it, not chosen
## here: no variant is preferred without players.
##
##   A  immediate response, restrained presentation: no start lean, turn
##      squeeze or stop settle on the figure.
##   B  slightly weighted: about 0.1 s to full speed, 0.07 s to a stop.
##   C  current: immediate response, with the lean, squeeze and settle.
##
## `-- --move=a|b|c`, or ?move=a|b|c on the web. Collision, speed and the
## pointer's never-past-the-target rule are the same in all three.

const TO_FULL := 0.10
const TO_STOP := 0.07

static var variant := ""


static func current() -> String:
	if variant == "":
		variant = "c"
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--move="):
				variant = arg.trim_prefix("--move=").to_lower()
		if OS.has_feature("web"):
			var q := str(JavaScriptBridge.eval("window.location.search", true))
			for v in ["a", "b", "c"]:
				if q.contains("move=" + v):
					variant = v
		if variant not in ["a", "b", "c"]:
			variant = "c"
	return variant


## The velocity to drive with this step, from the last one and what the
## input asks for. A and C answer at once; B eases in and out.
static func drive(last: Vector2, wanted: Vector2, speed: float, delta: float) -> Vector2:
	if current() != "b":
		return wanted
	var rate := speed / (TO_FULL if wanted.length() >= last.length() else TO_STOP)
	return last.move_toward(wanted, rate * delta)


## Whether the figure leans into a start, squeezes through a turn and settles
## on a stop (presentation only: the body never waits for it).
static func body_language() -> bool:
	return current() != "a"
