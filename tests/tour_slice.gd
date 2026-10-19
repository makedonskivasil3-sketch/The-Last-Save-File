extends "res://tests/test_case.gd"
## The visual slice (docs/VISUAL_DIRECTION.md): the cast lineup, Arin's room,
## a conversation, the square calm and hunting, and a memory. Not part of the
## suite; screenshots for review.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . -s res://tests/run_tests.gd \
##       -- --test-mode --tour --filter=tour_slice --screenshots=/some/dir


class Figure:
	extends Node2D
	var fig: IllustratedCharacter

	func _process(delta: float) -> void:
		fig.update(delta, Vector2.ZERO)
		queue_redraw()

	func _draw() -> void:
		fig.draw(self)


class Lineup:
	extends Node2D

	func _ready() -> void:
		var kinds := [
			["rue", Player.RUE], ["rue", Player.MISSING],
			["dress", {"h": Color("6a3a2a"), "s": Color("f0c8a0"), "c": Color("c9733e"), "d": Color("a85a2e"), "a": Color("e0a070")}],
			["child", {"h": Color("3a2a22"), "s": Color("eac09a"), "c": Color("5a7a9a"), "d": Color("3a5a7a"), "a": Color("e8c48a")}],
			["apron", {"h": Color("6a5a4a"), "s": Color("e8b890"), "c": Color("6a5a7a"), "d": Color("4a3a5a"), "a": Color("bbbbbb"), "w": Color("e8e0d0")}],
			["robe", {"h": Color("e8e8e8"), "s": Color("e0b890"), "c": Color("4a4a6a"), "d": Color("2a2a4a"), "a": Color("8a3a3a")}],
			["adult", {"h": OwnerAvatar.HAIR, "s": OwnerAvatar.SKIN, "c": OwnerAvatar.BODY, "d": OwnerAvatar.BODY.darkened(0.3), "a": Color("2e3f5c")}],
		]
		var facings := [Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP]
		for row in 2:
			for i in kinds.size():
				var f := Figure.new()
				f.fig = IllustratedCharacter.new(kinds[i][0], kinds[i][1])
				f.fig.facing = facings[(i + row) % 4] if row == 1 else Vector2.DOWN
				f.fig.talking = row == 0 and i == 2
				f.position = Vector2(50 + i * 90, 120 + row * 150)
				f.scale = Vector2(2.0, 2.0)
				add_child(f)

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 640, 360), Color("2a2630"))
		draw_rect(Rect2(0, 200, 640, 160), Color("3a3440"))


func test_slice_lineup() -> void:
	var l := Lineup.new()
	tree.root.add_child(l)
	await wait(0.5)
	await shot("s00_lineup")
	l.queue_free()
	await frames(2)


func test_slice_room_and_square() -> void:
	var w := await start_session()
	w.director.paused = true
	await wait(1.0)
	await shot("s01_room")
	await interact_with(w, w.area.mira)
	await wait(1.2)
	await shot("s02_room_mira_talks")
	w.hud.close_dialogue()
	await go_to(w, "square", "house")
	await wait(1.0)
	await shot("s03_square")
	w.director.paused = false
	w.director.add_awareness(OwnerDirector.HUNT + 2.0 - w.director.awareness)
	await wait(1.5)
	await shot("s04_square_hunt")
