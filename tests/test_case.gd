extends RefCounted
## Base class for tests. Each `test_*` method is a coroutine run on a fresh
## instance; record problems with check()/check_eq() instead of asserting, so
## one test reports every failure it finds.
##
## Helpers drive the real game: start a session, move between areas, press
## actions, wait. All waits use wall-clock timers, so they don't depend on
## frame rate.

const MAIN_SCENE := "res://scenes/main.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"

var tree: SceneTree
var failures: Array[String] = []


# --- lifecycle -----------------------------------------------------------------

func before_each() -> void:
	memory().wipe()
	var s := settings()
	s.glitch_intensity = 1.0
	s.reduce_flashing = false
	s.screen_effects = 2
	s.large_text = false
	# Tips off by default so they never get in a test's way; test_tutorial
	# turns them on.
	s.tutorial_tips = false
	s.tips_seen.clear()
	tree.paused = false


func after_each() -> void:
	tree.paused = false
	memory().wipe()


# --- checks ----------------------------------------------------------------------

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])


# --- access ----------------------------------------------------------------------

func memory() -> Node:
	return tree.root.get_node("OwnerMemory")


func settings() -> Node:
	return tree.root.get_node("Settings")


func scene() -> Node:
	return tree.current_scene


# --- driving the game --------------------------------------------------------------

func wait(seconds: float) -> void:
	await tree.create_timer(seconds).timeout


func frames(n: int) -> void:
	for i in n:
		await tree.process_frame


## Waits until `condition` returns true, or fails the test after `timeout`.
func wait_until(condition: Callable, timeout: float, what: String) -> bool:
	var left := timeout
	while left > 0.0:
		if condition.call():
			return true
		await tree.process_frame
		left -= tree.root.get_process_delta_time()
	failures.append("timed out waiting for " + what)
	return false


## Starts a game session and waits until the player can move.
## skip_boot: skip the first-launch boot cinematic. With first_session the
## session still counts as the very first one (door open, first-time lines).
func start_session(skip_boot := true, first_session := false) -> Node:
	if skip_boot and memory().sessions == 0:
		if first_session:
			memory().last_exit = "death"  # any non-"none" exit skips the boot
		else:
			memory().sessions = 1
	tree.change_scene_to_file(MAIN_SCENE)
	await wait_until(func() -> bool: return scene() != null and scene().get("player") != null and scene().get("area") != null, 5.0, "main scene")
	var w := scene()
	await wait_until(func() -> bool: return not w._cutscene, 30.0 if not skip_boot else 6.0, "session start")
	return w


## Waits for World to reload into a new session (after a death).
func wait_for_new_session(old: Node) -> Node:
	var old_id := old.get_instance_id()
	await wait_until(func() -> bool:
		var s := scene()
		return s != null and s.get_instance_id() != old_id and s.get("area") != null, 8.0, "the next session")
	var w := scene()
	await wait_until(func() -> bool: return not w._cutscene, 6.0, "next session start")
	return w


## Moves to an area through World (as an exit would) and waits for the fade.
func go_to(w: Node, area: String, arrival: String) -> void:
	w.change_area(area, arrival)
	await wait_until(func() -> bool: return w.area.area_id == area and not w._transitioning, 5.0, "arriving in " + area)


## Presses and releases an input action, giving the game a few frames to see it.
func press(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await frames(2)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await frames(1)


## Stands the player next to something and presses interact.
func interact_with(w: Node, node: Node2D, offset := Vector2(0, 14)) -> void:
	w.player.global_position = node.global_position + offset
	await frames(3)
	await press("interact")
	await frames(2)


## Advances the dialogue box until it closes.
func finish_dialogue(w: Node) -> void:
	for i in 40:
		if not w.hud.is_dialogue_open():
			return
		await press("interact")
		await wait(0.05)


## Saves a screenshot when run with --screenshots=<dir> (needs a display).
func shot(name: String) -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshots="):
			await tree.process_frame
			await RenderingServer.frame_post_draw
			var img := tree.root.get_texture().get_image()
			if img:
				img.save_png(arg.trim_prefix("--screenshots=").path_join(name + ".png"))
