extends "res://tests/test_case.gd"
## Rendered staging checks, not evidence of human playtesting or a GPU profile.


func test_title_and_player_paced_festival() -> void:
	tree.change_scene_to_file(TITLE_SCENE)
	await frames(8)
	await shot("title_layered_room")
	settings().opening_seen = false
	scene()._start()
	await wait_until(func() -> bool: return scene() is Prologue, 4.0, "the festival")
	var p: Prologue = scene()
	p.autoplay = true
	await wait_until(func() -> bool: return p.story.visible, 40.0, "the first shared lantern")
	p.autoplay = false
	await frames(5)
	await shot("festival_first_shared_lantern")
	settings().large_text = true
	UiStyle.rescale_text(tree)
	await frames(5)
	check(p.story.get_rect().end.y <= 360.0, "large-text reader stays in the viewport")
	await shot("festival_large_text_reader")
	p.story.cancel()
	p._story_release = false
	p._to_beat(Prologue.Beat.TIMELAPSE)
	p.beat_t = 8.0
	await frames(5)
	check(p.story.visible and p.story.story_id == "message", "the historical message waits for reading")
	await shot("festival_historical_message")
	p.story.cancel()
	p._story_release = false
	p._to_beat(Prologue.Beat.LOAD)
	p.beat_t = 3.1
	await frames(5)
	check(p.story.visible and p.story.story_id == "owner", "the present-day reveal waits for reading")
	await shot("festival_owner_revelation")
	# Finish via the real skip path, including its release handoff.
	Input.action_press("ui_cancel")
	await wait(1.1)
	Input.action_release("ui_cancel")
	await wait_until(func() -> bool: return scene() is World, 15.0, "playable room")
	await wait_until(func() -> bool: return scene()._awake, 10.0, "Rue awake")
	await shot("festival_handoff_room")
