extends "res://tests/test_case.gd"
## Regressions for physical touch ownership and first-run reading.
var _emulate := true

func before_each() -> void:
	_emulate = Input.emulate_mouse_from_touch
	await super.before_each()

func after_each() -> void:
	Input.emulate_mouse_from_touch = _emulate
	Input.action_release("interact")
	Input.action_release("confirm")
	settings().using_touch = false
	await super.after_each()

func _event(index: int, at: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = tree.root.get_final_transform() * at
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func _beside_mira() -> World:
	var w: World = await start_session(true, true)
	w.player.position = w.area.mira.position + Vector2(0,14)
	await frames(4)
	return w

func test_standard_e_tap_baseline() -> void:
	var w := await _beside_mira()
	_event(1, TouchControls.BUTTONS.interact.center, true)
	await frames(3)
	_event(1, TouchControls.BUTTONS.interact.center, false)
	await frames(5)
	check(w.hud.is_dialogue_open(), "ordinary spaced touch opens dialogue")

func test_touch_press_and_release_between_frames() -> void:
	var w := await _beside_mira()
	_event(1, TouchControls.BUTTONS.interact.center, true)
	_event(1, TouchControls.BUTTONS.interact.center, false)
	await frames(5)
	check(w.hud.is_dialogue_open(), "a short tap must survive between game frames")

func test_two_fingers_on_e_releasing_one_keeps_other_hold() -> void:
	var w := await _beside_mira()
	_event(1, TouchControls.BUTTONS.interact.center, true)
	await frames(2)
	_event(2, TouchControls.BUTTONS.interact.center, true)
	await frames(2)
	_event(1, TouchControls.BUTTONS.interact.center, false)
	await frames(2)
	check(Input.is_action_pressed("interact"), "remaining finger must retain its hold")
	_event(2, TouchControls.BUTTONS.interact.center, false)

func test_festival_touch_skip_without_mouse_emulation() -> void:
	Input.emulate_mouse_from_touch = false
	var p := Prologue.new()
	var old := scene()
	tree.root.add_child(p)
	tree.current_scene = p
	if old: old.queue_free()
	await frames(3)
	_event(3, Prologue.SKIP_CHIP.get_center(), true)
	await wait(1.0)
	check(p.acted.has("skipped"), "holding touch skip works independently of mouse emulation")
	_event(3, Prologue.SKIP_CHIP.get_center(), false)
	p._done=true
	p._handed_off=true
	p.queue_free()
	await frames(2)

func test_cold_open_has_touch_skip_control() -> void:
	var card := ColdOpen.new()
	var old := scene()
	tree.root.add_child(card)
	tree.current_scene=card
	if old: old.queue_free()
	await frames(3)
	var buttons := card.find_children("*","StoryTouchControl",true,false)
	check(not buttons.is_empty(), "memory card has a discoverable touch skip/continue control")

func test_fresh_touch_after_closing_dialogue_is_not_discarded() -> void:
	settings().text_speed = 3
	var w := await _beside_mira()
	w.hud.show_dialogue("TEST",Color.WHITE,["One line."])
	await frames(6)
	_event(1, TouchControls.BUTTONS.interact.center, true)
	await frames(1)
	_event(1, TouchControls.BUTTONS.interact.center, false)
	check(not w.hud.is_dialogue_open(), "setup: first press closes the shown line")
	_event(1, TouchControls.BUTTONS.interact.center, true)
	_event(1, TouchControls.BUTTONS.interact.center, false)
	await frames(5)
	check(w.hud.is_dialogue_open(), "a new tap after releasing must open Mira, not be suppressed as the old press")

func _card() -> ColdOpen:
	var card := ColdOpen.new()
	var old := scene()
	tree.root.add_child(card)
	tree.current_scene = card
	if old: old.queue_free()
	await frames(3)
	return card

func _festival() -> Prologue:
	var p := Prologue.new()
	var old := scene()
	tree.root.add_child(p)
	tree.current_scene = p
	if old: old.queue_free()
	await frames(3)
	return p

func _close_festival(p: Prologue) -> void:
	p._done = true
	p._handed_off = true
	p.queue_free()
	await frames(2)

func test_card_touch_reveals_then_separately_advances_without_mouse() -> void:
	Input.emulate_mouse_from_touch = false
	var card := await _card()
	var at := card._continue.get_global_rect().get_center()
	_event(4, at, true)
	_event(4, at, false)
	check_eq(card._line, 0, "first tap only reveals")
	check_eq(card._labels[0].visible_characters, card._labels[0].text.length(), "whole line revealed")
	await wait(0.4)
	_event(4, at, true)
	_event(4, at, false)
	check_eq(card._line, 1, "separate tap advances exactly once")

func test_card_touch_skip_reaches_festival_without_an_input_leak() -> void:
	Input.emulate_mouse_from_touch = false
	var card := await _card()
	var at := card._skip.get_global_rect().get_center()
	_event(5, at, true)
	await wait(0.8)
	check(card._done, "hold skip works without a mouse")
	_event(5, at, false)
	await wait_until(func() -> bool: return scene() is Prologue, 4.0, "festival")
	var p: Prologue = scene()
	check(not p.acted.has("skipped"), "card skip is not also festival skip")
	check(not Input.is_action_pressed("interact"), "no virtual E carried over")
	await _close_festival(p)

func test_festival_story_touch_continue_and_final_skip_without_mouse() -> void:
	Input.emulate_mouse_from_touch = false
	var p := await _festival()
	p._light(0)
	await wait(0.4)
	check(p.story.visible, "shared first-light reader opens")
	var at := p.story._next.get_global_rect().get_center()
	_event(6, at, true)
	_event(6, at, false)
	check_eq(p.story.page, 1, "touch advances one story page")
	p.beat = Prologue.Beat.LOAD
	await frames(3)
	check(p._chip.visible, "skip stays visible during the final reader")
	check(p._chip.get_parent().layer > p.story.get_parent().layer, "skip is above the story panel")
	_event(7, Prologue.SKIP_CHIP.get_center(), true)
	await wait(0.85)
	check(p.acted.has("skipped"), "final reader can be skipped by touch")
	_event(7, Prologue.SKIP_CHIP.get_center(), false)
	await _close_festival(p)

func test_a_canceled_e_gesture_never_talks() -> void:
	var w := await _beside_mira()
	_event(1, TouchControls.BUTTONS.interact.center, true)
	await frames(1)
	w.touch._touch_up(1, true)
	await frames(5)
	check(not w.hud.is_dialogue_open(), "cancellation does not become a tap")
	_event(1, TouchControls.BUTTONS.interact.center, true)
	_event(1, TouchControls.BUTTONS.interact.center, false)
	await frames(5)
	check(w.hud.is_dialogue_open(), "a fresh gesture after cancellation still works")

func test_held_dialogue_close_never_reopens_the_world() -> void:
	settings().text_speed = 3
	var w := await _beside_mira()
	w.hud.show_dialogue("TEST", Color.WHITE, ["One line."])
	await frames(6)
	_event(1, TouchControls.BUTTONS.interact.center, true)
	await frames(8)
	check(not w.hud.is_dialogue_open(), "held closing press does not reopen Mira")
	_event(1, TouchControls.BUTTONS.interact.center, false)
	await frames(5)
	check(not w.hud.is_dialogue_open(), "its release is not a new tap")

func test_dragging_out_of_skip_cancels_the_hold() -> void:
	Input.emulate_mouse_from_touch = false
	var card := await _card()
	var at := card._skip.get_global_rect().get_center()
	_event(8, at, true)
	await wait(0.3)
	var drag := InputEventScreenDrag.new()
	drag.index = 8
	drag.position = tree.root.get_final_transform() * Vector2(20, 20)
	Input.parse_input_event(drag)
	Input.flush_buffered_events()
	await wait(0.8)
	check(not card._done, "moving off skip cancels, rather than completing unseen")
	_event(8, Vector2(20, 20), false)

func test_virtual_cinematic_tap_advances_one_page_without_auto_repetition() -> void:
	settings().text_speed = 3
	var w := await _beside_mira()
	w.hud.cinematic("TEST", ["First.", "Second."], Color.WHITE)
	await wait(1.0)
	check_eq(w.hud._cine_text.text, "First.", "first page is shown")
	_event(1, TouchControls.BUTTONS.interact.center, true)
	_event(1, TouchControls.BUTTONS.interact.center, false)
	await frames(8)
	check_eq(w.hud._cine_text.text, "Second.", "tap reaches next page, not swallowed by skip arming")
	check(w.hud.is_cinematic(), "one tap cannot finish both pages")
	await wait(0.4)
	_event(1, TouchControls.BUTTONS.interact.center, true)
	_event(1, TouchControls.BUTTONS.interact.center, false)
	await wait_until(func() -> bool: return not w.hud.is_cinematic(), 4.0, "reader closes")
	check(not w.hud.is_dialogue_open(), "closing a cinematic doesn't also talk to Mira")

func test_old_controls_cannot_cancel_a_new_scenes_gesture() -> void:
	var w := await _beside_mira()
	var next := TouchControls.new()
	w.add_child(next)
	w.touch._touch_down(10, TouchControls.BUTTONS.interact.center)
	next._touch_down(11, TouchControls.BUTTONS.interact.center)
	var owned := TouchControls.interact_serial
	w.touch.cancel_touches()
	check(TouchControls.interact_held, "old scene cleanup does not release the new hold")
	check(TouchControls.canceled_interact_serial != owned, "new scene input was not canceled")
	next.cancel_touches()
	check(not TouchControls.interact_held, "actual owner can cancel")
	next.queue_free()
	await frames(2)
