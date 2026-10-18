extends "res://tests/test_case.gd"

func _tutorial(w: Node) -> Tutorial:
	for child in w.get_children():
		if child is Tutorial:
			return child
	return null

func test_facing_the_nook_wall_does_not_freeze_mira() -> void:
	var w := await start_session(true, true)
	w.director.stop()
	w.player.global_position = Vector2(450, 100)
	w.player._sprite.facing = Vector2.RIGHT
	await frames(3)
	check_eq(w.glitch.find_target().get("id", ""), "phase", "facing the thin wall offers PHASE even with Mira behind you")
	await hold("interact", 0.9)
	check(w.player.global_position.x > 462.0, "holding interact actually crosses the partition")
	check_eq(w.area.mira.frozen, 0.0, "Mira was not frozen by mistake")

func test_owner_banner_has_priority_over_tips() -> void:
	var w := await start_session(true, true)
	settings().tutorial_tips = true
	var tutorial := _tutorial(w)
	tutorial._show("move")
	await frames(3)
	w.hud.set_banner("LOADING AUTOSAVE")
	check(not w.hud.is_tip_shown(), "an owner warning clears the overlapping tutorial immediately")
	var elapsed := tutorial._shown_for
	await wait(0.4)
	check_eq(tutorial._shown_for, elapsed, "reading time does not expire behind the warning")
	w.hud.set_banner("")
	await frames(3)
	check(w.hud.is_tip_shown(), "the same lesson returns after the warning")
	check_eq(tutorial._current, "move", "the lesson is not lost or replaced")
	settings().tutorial_tips = false

func test_wren_is_taught_where_the_player_can_find_her() -> void:
	var w := await start_session(true, true)
	settings().tutorial_tips = true
	for id in ["move", "watched", "quit", "interact", "way_out", "crack", "glitch", "price"]:
		settings().mark_tip_seen(id)
	var tutorial := _tutorial(w)
	check(tutorial._next_tip() != "wren", "do not teach a future character in the opening room")
	await go_to(w, "square", "house")
	settings().mark_tip_seen("arin")
	w.player.global_position = w.area.wren.global_position + Vector2(55, 0)
	await frames(2)
	check_eq(tutorial._next_tip(), "wren", "teach shelter when Wren is nearby")
	settings().tutorial_tips = false


func test_modal_choices_suspend_the_lesson() -> void:
	var w := await start_session(true, true)
	settings().tutorial_tips = true
	var tutorial := _tutorial(w)
	tutorial._show("move")
	await frames(2)
	w.hud._choice.visible = true
	await frames(2)
	check(not w.hud.is_tip_shown(), "choices have no tutorial layered above them")
	var elapsed := tutorial._shown_for
	await wait(0.2)
	check_eq(tutorial._shown_for, elapsed, "the suspended lesson keeps its reading time")
	w.hud._choice.visible = false
	await frames(3)
	check(w.hud.is_tip_shown(), "the lesson returns after the choice")
	settings().tutorial_tips = false


func test_owner_warnings_have_room_above_the_music() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	w.director.stop()
	var ambience: Ambience = w._ambience
	await wait_until(func() -> bool: return ambience._memory_theme.playing, 5.0, "music")
	ambience._update_memory_theme(10.0)
	var before := ambience._memory_theme.volume_db
	w.hud.set_banner("LOADING AUTOSAVE")
	ambience._update_memory_theme(10.0)
	check(ambience._memory_theme.volume_db <= before - 7.0, "warnings duck the score")
	w.hud.set_banner("")
	ambience._update_memory_theme(10.0)
	check_eq(ambience._memory_theme.volume_db, before, "the score recovers after the warning")


class RecordingNarration extends Narration:
	var speaker := ""
	func speak(text: String, who := "") -> void:
		last_text = text
		speaker = who

func _play_owner_line(hud: Hud, done: Array) -> void:
	await hud.cinematic("", ["> who is in my save?"], Hud.SYSTEM_COLOR)
	done[0] = true

func test_first_owner_line_is_distinct_in_colour_and_narration() -> void:
	var w := await start_session()
	var old_speed: int = settings().text_speed
	settings().text_speed = 3
	w.hud.narrator.queue_free()
	var recording := RecordingNarration.new()
	w.hud.add_child(recording)
	w.hud.narrator = recording
	var done := [false]
	_play_owner_line.call_deferred(w.hud, done)
	await wait_until(func() -> bool: return recording.speaker == "OWNER", 2.0, "owner line")
	check_eq(w.hud._cine_text.get_theme_color("font_color"), Hud.OWNER_COLOR, "owner uses the established warning colour")
	check_eq(recording.last_text, "who is in my save?", "speech excludes the visual prompt character")
	await press("confirm")
	await wait_until(func() -> bool: return done[0], 6.0, "cinematic completes")
	check_eq(w.hud._cine_text.get_theme_color("font_color"), Hud.SYSTEM_COLOR, "later system text keeps its own colour")
	settings().text_speed = old_speed
