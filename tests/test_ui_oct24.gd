extends "res://tests/test_case.gd"
## Found in the 24 October captures at the largest text: the tip card (bottom
## right) covered the "hold [E]" glitch prompt in the same corner.


func test_a_tip_never_covers_the_glitch_prompt() -> void:
	settings().large_text = true
	settings().subtitle_size = 2
	var w := await start_session()
	w.hud.apply_subtitle_style()
	await go_to(w, "square", "house")  # at the locked front door: [E] door, hold [E] UNLOCK
	await wait(0.4)
	check(w.hud.glitch_prompt_text() != "" and w.hud._glitch_prompt.visible, "the glitch prompt is up (%s)" % w.hud.glitch_prompt_text())
	w.hud.show_tip("HIDE", "Stand beside Wren while Arin passes. The owner can't see what she stands beside.")
	await wait(0.6)
	var tip: Rect2 = w.hud._tip.get_global_rect()
	var glitch: Rect2 = w.hud._glitch_prompt.get_global_rect()
	check(not tip.intersects(glitch), "the tip sits clear of it (tip %s, prompt %s)" % [tip, glitch])
	check(tip.position.y >= Hud.SAFE.y, "and still on screen")
	settings().large_text = false
	settings().subtitle_size = 0
