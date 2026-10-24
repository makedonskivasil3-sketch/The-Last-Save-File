extends "res://tests/test_case.gd"
## Reproducible review captures, not human playtest evidence. Run with
## --tour --filter=tour_opening_review --screenshots=<directory>.

class CastSheet:
	extends Node2D
	var figures: Array = []
	var labels := ["RUE", "MISSING", "ARIN", "MIRA", "WREN", "TOBBEN", "ARCHIVIST"]
	func _ready() -> void:
		var entries := [["rue", Player.RUE], ["rue", Player.MISSING],
			["adult", {"h": OwnerAvatar.HAIR, "s": OwnerAvatar.SKIN, "c": OwnerAvatar.BODY, "a": Color("c0392b")}],
			["dress", {"h": Color("6a3a2a"), "s": Color("f0c8a0"), "c": Color("c9733e")}],
			["child", {"h": Color("3a2a22"), "s": Color("eac09a"), "c": Color("5a7a9a")}],
			["apron", {"h": Color("6a5a4a"), "s": Color("e8b890"), "c": Color("6a5a7a")}],
			["robe", {"h": Color("e8e8e8"), "s": Color("e0b890"), "c": Color("4a4a6a")}]]
		for e in entries:
			figures.append(IllustratedCharacter.new(e[0], e[1]))
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 640, 360), Color("282830"))
		var directions := [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
		for i in figures.size():
			draw_string(UiStyle.system_font(), Vector2(12 + i * 90, 20), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
			for j in directions.size():
				var fig: IllustratedCharacter = figures[i]
				fig.facing = directions[j]
				fig._t = 0.0
				fig._blink = 0.0
				fig.draw(self, {"offset": Vector2(42 + i * 90, 90 + j * 80), "scale": 1.5})

func test_cast_directions() -> void:
	# A previous tour may leave a world/CanvasLayer alive. A reference sheet
	# must not inherit its HUD, lighting or corruption shader.
	if tree.current_scene != null:
		var previous := tree.current_scene
		tree.current_scene = null
		previous.queue_free()
		await frames(3)
	var sheet := CastSheet.new()
	tree.root.add_child(sheet)
	await frames(3)
	await shot("cast_directions")
	sheet.queue_free()
	await frames(2)

func test_fresh_opening_and_first_exit() -> void:
	settings().opening_seen = false
	settings().tutorial_tips = true
	settings().reduce_flashing = true
	settings().glitch_intensity = 0.0
	tree.change_scene_to_file(TITLE_SCENE)
	await frames(5)
	await shot("fresh_title")
	scene()._play_opening(false)  # (the earlier film, now off the first-run path)
	await wait_until(func() -> bool: return scene() is Opening, 3.0, "opening")
	await wait(2.0)
	await shot("fresh_opening")
	Input.action_press("interact")
	await wait(0.9)
	Input.action_release("interact")
	await wait_until(func() -> bool: return scene() is World, 4.0, "fresh room")
	var w := scene()
	await wait_until(func() -> bool: return w.hud.is_cinematic(), 3.0, "boot")
	await read_through_cinematic(w)
	await wait_until(func() -> bool: return not w._cutscene, 4.0, "arrival")
	await wait(4.5)
	await shot("fresh_room")
	# Staged close-up of the real charge presentation; no claim that a
	# human found this partition or exit. Story state above is truly fresh.
	w.director.paused = true
	w.player.global_position = Vector2(450, 100)
	w.player._sprite.facing = Vector2.RIGHT
	w.glitch.set_process(false)
	w.glitch.target = {"id": "phase", "node": null, "pos": Vector2(468, 100)}
	w.glitch._charge = Glitch.hold_time("phase") * 0.55
	w.glitch._update_prompt()
	w.glitch.queue_redraw()
	await frames(3)
	await shot("charge_native")
	settings().large_text = true
	await frames(3)
	w.glitch.queue_redraw()
	await shot("charge_large_text")
	settings().large_text = false
	w.glitch._cancel()
	w.glitch.set_process(true)
	w.player.global_position = Vector2(320, 120)
	w.director.paused = false
	# Real doorway trigger: on the fresh run it closes and the seam opens.
	w.player.global_position = w.area.door.global_position + Vector2(0, 40)
	await wait(1.0)
	check(w.area.seam != null and w.area.seam.open, "first approach exposes a usable seam")
	w.player.global_position = w.area.seam.global_position
	await wait_until(func() -> bool: return w.area.area_id == "square", 5.0, "first exit")
	await wait(0.8)
	await shot("first_exit")
