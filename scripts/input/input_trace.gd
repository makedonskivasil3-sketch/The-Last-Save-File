class_name InputTrace
extends RefCounted
## A bounded, local input trace for phone playtests (docs/INPUT_POLICY.md):
## each touch, press, release, drag and cancellation, which scene and modal
## it met, what it was meant to do, who owned it, and whether it was
## accepted (with the reason when it wasn't).
##
## On only with the playtest flag (?playtest=1 on the web, -- --playtest on
## desktop) or when a test switches it on. Kept in memory (MAX lines), shown
## and copied from the pause menu's Playtest log page with the rest of the
## log. Nothing is sent anywhere.
##
## Reading a line: "12.48s 9fps touch#1 down E  hud dialogue  taken  press #7"
##   - no "touch" line at all: the tap never reached the game;
##   - "touch ... missed": it landed on no control (hit test);
##   - "refused ... already used by hud": the dialogue box had that press;
##   - "refused ... stale": it came too long after its release;
##   - "hold started": E was held long enough to start charging a glitch;
##   - "blocked ... transition": a passage or card had the input.

const MAX := 300

static var lines: Array[String] = []
static var forced := false


static func enabled() -> bool:
	return forced or PlaytestLog.enabled()


## kind: touch-down, touch-up, drag-off, cancel, press, release, taken,
## refused, claimed, cancelled, hold, blocked. what: the control or action.
## owner: who had it. accepted: true/false when the line is a decision.
static func add(kind: String, what: String, owner := "", detail := "", accepted: Variant = null) -> void:
	if not enabled():
		return
	var fps := Engine.get_frames_per_second()
	var t := Time.get_ticks_msec() / 1000.0
	var verdict := "" if accepted == null else ("  ACCEPTED" if accepted else "  REFUSED")
	var line := "%8.2fs %3dfps  %-11s %-10s %-14s %s%s%s" % [t, fps, kind, what, owner, _context(), verdict, ("  " + detail) if detail != "" else ""]
	lines.append(line)
	if lines.size() > MAX:
		lines.pop_front()


## Scene and active modal, as briefly as possible.
static func _context() -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return "-"
	var scene := tree.current_scene
	var name := scene.get_class() if scene.get_script() == null else str(scene.get_script().get_global_name())
	if name == "":
		name = scene.name
	var modal := ""
	if tree.paused:
		modal = "paused"
	elif scene is World:
		var w := scene as World
		if w.hud.is_choosing():
			modal = "choice"
		elif w.hud.is_cinematic():
			modal = "cinematic"
		elif w.hud.is_dialogue_open():
			modal = "dialogue"
		elif w._transitioning:
			modal = "transition"
	return name + ("/" + modal if modal != "" else "")


static func text() -> String:
	return "\n".join(lines)


static func clear() -> void:
	lines.clear()
