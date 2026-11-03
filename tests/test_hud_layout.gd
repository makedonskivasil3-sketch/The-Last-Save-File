extends "res://tests/test_case.gd"
## The goal stays out of the playfield (brief of 2026-11-03, §6): it sits in
## the band under the map, above the console, and rises with the console.
## At the top it covered the room's wall notes and the workshop's top wall
## whenever it wrapped (tour_calibration captures).

## Every area's map ends near y 300 in the 640 x 360 HUD space.
const PLAYFIELD_END := 300.0


func test_the_goal_sits_under_the_map_and_above_the_console() -> void:
	var w := await start_session()
	for big in [false, true]:
		settings().large_text = big
		UiStyle.rescale_text(tree)
		w.hud._console_box.visible = false  # measured with an empty console first
		w.hud.show_objective("Explore the village. The road east leads somewhere old and the well looks deeper than it should.", Progression.HINT_INVESTIGATE)
		await frames(3)
		var o: Label = w.hud._objective
		var top: float = o.position.y
		var bottom: float = o.position.y + o.size.y + w.hud._objective_hint.size.y + 1.0
		check(top >= w.hud._slot.position.y + w.hud._slot.size.y, "large %s: below the save header (top %.0f)" % [big, top])
		check(bottom <= 360.0 - Hud.SAFE.y + 0.5, "large %s: on screen (bottom %.0f)" % [big, bottom])
		check(top >= PLAYFIELD_END - 30.0, "large %s: under the map, not over its top walls (top %.0f)" % [big, top])
		w.hud.say("(a line in the console.)", "self")
		await frames(4)
		var box: Control = w.hud._console_box
		if box.visible:
			check(o.position.y + o.size.y <= box.position.y + 0.5, "large %s: above the console, never under it" % big)
	settings().large_text = false
	UiStyle.rescale_text(tree)
