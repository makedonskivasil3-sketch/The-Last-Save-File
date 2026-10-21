extends "res://tests/test_case.gd"
## Console lines (docs/STORY_TEXT_ROUTES.md): story lines (thoughts, people,
## the owner talking) keep their whole reading time and are never cut short;
## telemetry ("system") is capped and hurried by a backlog; the owner's lines
## still go first, and cut a telemetry pause, but not a thought being read.
## Urgent warnings are a separate strip (Hud.warn) and stay immediate.

const STORY := "the couch still has two dents in it. one is mine. the other one is the shape of somebody who used to sit very close to the screen and laugh at the parts that weren't funny."
const SYSTEM := "MEMORY RECOVERED  1 / 5"


func _fresh(w: Node) -> void:
	w.hud.clear_queue()
	w.hud._typing = null
	w.hud._pause = 0.0
	settings().text_speed = 3  # instant typing: only the pause is measured


func _shown(w: Node, text: String) -> bool:
	return w.hud.history.any(func(e: Dictionary) -> bool: return e.text == text or e.text == "> " + text)


func test_a_long_story_line_keeps_its_whole_reading_time() -> void:
	check(StoryPacing.reading_time(STORY) > StoryPacing.AMBIENT_MAX, "the line needs more than %.0f s (%.1f)" % [StoryPacing.AMBIENT_MAX, StoryPacing.reading_time(STORY)])
	for kind in ["self", "owner", "npc"]:
		check_eq(StoryPacing.ambient_time(STORY, 0, kind), StoryPacing.reading_time(STORY), "%s: all of it" % kind)
		check_eq(StoryPacing.ambient_time(STORY, StoryPacing.BACKLOG + 2, kind), StoryPacing.reading_time(STORY), "%s: even in a backlog" % kind)
	check_eq(StoryPacing.ambient_time(STORY, 0, "system"), StoryPacing.AMBIENT_MAX, "telemetry is capped")
	check_eq(StoryPacing.ambient_time(STORY, StoryPacing.BACKLOG, "system"), StoryPacing.MIN_TIME, "and hurried by a backlog")


func test_the_owner_waits_for_a_thought_but_not_for_a_counter() -> void:
	var w := await start_session()
	_fresh(w)
	settings().auto_speed = 1
	w.hud.say(STORY, "self")
	await wait_until(func() -> bool: return _shown(w, STORY), 2.0, "the thought")
	w.hud.say("a second thought.", "self")
	w.hud.say("who taught you to do that.", "owner")
	check_eq(w.hud._queue[0].kind, "owner", "the owner's line goes ahead of the waiting thought")
	await wait(StoryPacing.AMBIENT_MAX + 0.5)
	check(not _shown(w, "who taught you to do that."), "but lets the thought be read: still waiting after %.0f s" % StoryPacing.AMBIENT_MAX)
	await wait_until(func() -> bool: return _shown(w, "who taught you to do that."), StoryPacing.reading_time(STORY), "the owner's line, once the thought is read")
	check(not _shown(w, "a second thought."), "and the queued thought still comes after it")
	# A counter, though, doesn't hold the owner up.
	_fresh(w)
	w.hud.say(SYSTEM, "system")
	await wait_until(func() -> bool: return _shown(w, SYSTEM), 2.0, "the counter")
	w.hud.say("stop touching those.", "owner")
	await wait(StoryPacing.OWNER_GAP + 0.4)
	check(_shown(w, "stop touching those."), "after telemetry the owner is on within %.1f s" % (StoryPacing.OWNER_GAP + 0.4))


func test_urgent_warnings_never_queue() -> void:
	var w := await start_session()
	_fresh(w)
	w.hud.say(STORY, "self")
	await wait_until(func() -> bool: return _shown(w, STORY), 2.0, "the thought")
	w.director.warn(Story.RELOAD_WARNING)
	await frames(1)
	check(w.hud._warning.visible and w.hud._warning.text.ends_with(Story.RELOAD_WARNING), "a warning is on its strip at once, over a thought being read")
