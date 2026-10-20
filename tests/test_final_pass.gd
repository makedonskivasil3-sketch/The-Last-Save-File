extends "res://tests/test_case.gd"
## Phase 4: the music box peaks only in RUE; the world sounds like what
## you did to it; phones feel it.


func test_the_complete_theme_is_held_back() -> void:
	for f in Story.FRAGMENTS:
		memory().add_fragment(f.id)
	check_eq(MusicBox.held_level(5), MusicBox.MAX_LEVEL - 1, "five memories: still one layer short")
	memory().last_ending = "rue"
	check_eq(MusicBox.held_level(5), MusicBox.MAX_LEVEL, "after RUE, the title plays it whole")


func test_putting_things_right_warms_the_village() -> void:
	memory().npc_fates["wren"] = "deleted"
	var w := await start_session()
	await go_to(w, "square", "house")
	var amb: Ambience = null
	for c in w.get_children():
		if c is Ambience:
			amb = c
	var thin := amb.village_life()
	memory().mira_quest = "pinned"
	memory().guestbook_restored = true
	check(amb.village_life() > thin, "Mira's note and the guest book bring some of it back (%.2f -> %.2f)" % [thin, amb.village_life()])


func test_the_edge_swells_when_it_unloads() -> void:
	var w := await start_session()
	w.flags["pointer"] = true
	await go_to(w, "edge", "south")
	await wait_until(func() -> bool: return not w.hud.is_act_shown(), 8.0, "the act card")  # the countdown waits for it
	await wait(1.6)
	var amb: Ambience = null
	for c in w.get_children():
		if c is Ambience:
			amb = c
	var calm: float = amb._theme.volume_db
	w.area.grace = 0.01
	await wait(1.0)
	check(amb._theme.volume_db > calm + 2.0, "louder once the static starts (%.1f -> %.1f dB)" % [calm, amb._theme.volume_db])


func test_phones_feel_it() -> void:
	settings().using_touch = true
	settings().vibration = true
	settings().last_buzz = 0
	var w := await start_session()
	w.glitch._pay("phase")
	check(settings().last_buzz > 0, "a glitch buzzes")
	settings().vibration = false
	settings().last_buzz = 0
	w.glitch._pay("phase")
	check_eq(settings().last_buzz, 0, "not with Vibration off")
	settings().using_touch = false
