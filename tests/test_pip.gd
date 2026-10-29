extends "res://tests/test_case.gd"
## Pip as a companion, not a route arrow (docs/production/CHARACTERS.md):
## leads once after a long stop, lies down at her feet while she waits, and
## hides behind her, ears flat, when Arin comes close.


func _with_pip() -> Node:
	memory().found_pip = true
	var w := await start_session()
	await wait_until(func() -> bool: return w.pip != null and w._awake, 8.0, "Pip")
	await go_to(w, "square", "house")
	w.director.paused = true
	w.area.arin.paused = true
	w.area.arin.position = Vector2(860, 300)
	w.player.global_position = Vector2(400, 250)
	return w


func test_he_leads_once_per_stop_then_lies_down() -> void:
	var w := await _with_pip()
	var pip: Companion = w.pip
	await wait_until(func() -> bool: return pip._still > Companion.REST_AFTER + 0.4, 20.0, "a short stop")
	check(not pip.leading(), "a short stop: no nudge")
	check(pip.resting(), "he lies down at her feet")
	await wait_until(func() -> bool: return pip._still > Companion.HESITATE + 0.4, 20.0, "a long stop")
	check(pip.leading(), "a long stop: he noses the way, once")
	await wait(4.0)
	check(not pip.leading(), "then back to her heel, not on and on")


func test_he_hides_behind_her_when_arin_is_close() -> void:
	var w := await _with_pip()
	await wait(Companion.ARRIVAL_LEAD + 0.5)
	var arin: Node2D = w.area.arin
	arin.global_position = w.player.global_position + Vector2(60, 0)
	await wait(1.2)
	check(w.pip._afraid > 0.9, "ears flat, crouched (%.2f)" % w.pip._afraid)
	check(w.pip.global_position.x < w.player.global_position.x, "on her far side from Arin (pip %s, rue %s)" % [w.pip.global_position.round(), w.player.global_position.round()])
	check(not w.pip.resting() and not w.pip.leading(), "neither lying down nor leading the way past him")
