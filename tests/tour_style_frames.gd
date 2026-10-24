extends "res://tests/test_case.gd"
## Style frames for docs/ART_BIBLE.md: the cast before (IllustratedCharacter)
## and after (HeroFigure), a walk cycle, the moods. Not part of the suite.
## Run with --tour --filter=tour_style_frames --screenshots=<dir>.

const CAST := [
	["rue", "RUE"], ["adult", "ARIN"], ["dress", "MIRA"], ["child", "WREN"],
	["apron", "TOBBEN"], ["robe", "ARCHIVIST"],
]


static func palette_for(kind: String) -> Dictionary:
	match kind:
		"rue":
			return Player.RUE
		"adult":
			return {"h": OwnerAvatar.HAIR, "s": OwnerAvatar.SKIN, "c": OwnerAvatar.BODY, "a": Color("c0392b")}
		"dress":
			return {"h": Color("6a3a2a"), "s": Color("f0c8a0"), "c": Color("c9733e"), "d": Color("a85a2e")}
		"child":
			return {"h": Color("c9a04a"), "s": Color("eac09a"), "c": Color("6a8f5a"), "d": Color("4a6a3a")}
		"apron":
			return {"h": Color("bbbbbb"), "s": Color("e0b48a"), "c": Color("7a5a8a"), "d": Color("4a3a5a")}
		"robe":
			return {"h": Color("d8d8e0"), "s": Color("e0b890"), "c": Color("3a4a6a"), "a": Color("c8a040")}
	return {}


class Sheet:
	extends Node2D
	var mode := "cast"
	var figures: Array = []
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var font := UiStyle.system_font()
		draw_rect(Rect2(0, 0, 640, 360), Color("2a2a33"))
		draw_rect(Rect2(0, 180, 640, 180), Color("323240"))
		if mode == "cast":
			draw_string(font, Vector2(8, 12), "BEFORE (IllustratedCharacter, 21–33 px)", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.7))
			draw_string(font, Vector2(8, 192), "AFTER (HeroFigure, 28–42 px)", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.7))
			for i in CAST.size():
				var x := 52.0 + i * 100.0
				draw_string(font, Vector2(x - 20, 170), CAST[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
				for j in 2:
					var old: IllustratedCharacter = figures[i * 4 + j * 2]
					var new: HeroFigure = figures[i * 4 + j * 2 + 1]
					old.facing = [Vector2.DOWN, Vector2.RIGHT][j]
					new.facing = old.facing
					old.draw(self, {"offset": Vector2(x - 18 + j * 34, 140), "scale": 2.0})
					new.draw(self, {"offset": Vector2(x - 18 + j * 34, 330), "scale": 2.0})
		else:
			var rue: HeroFigure = figures[0]
			draw_string(font, Vector2(8, 12), "RUE · walk cycle (side), run, moods, habit", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.7))
			for i in 8:
				rue.facing = Vector2.RIGHT
				rue.moving = true
				rue._walk = i * 0.25
				rue._speed = 50.0
				rue.draw(self, {"offset": Vector2(40 + i * 72, 130), "scale": 2.4})
			var moods := ["", "eager", "afraid", "determined", "concerned", "relieved"]
			rue.moving = false
			rue._speed = 0.0
			for i in moods.size():
				rue.facing = Vector2.DOWN
				rue.expression = moods[i]
				rue._blink = 0.0
				rue.draw(self, {"offset": Vector2(52 + i * 100, 330), "scale": 3.0})
				draw_string(font, Vector2(32 + i * 100, 352), moods[i] if moods[i] != "" else "neutral", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
			rue.expression = ""


func _sheet(mode: String) -> Sheet:
	if tree.current_scene != null:
		var previous := tree.current_scene
		tree.current_scene = null
		previous.queue_free()
		await frames(3)
	var s := Sheet.new()
	s.mode = mode
	for c in CAST:
		for j in 2:
			s.figures.append(IllustratedCharacter.new(c[0], palette_for(c[0])))
			s.figures.append(HeroFigure.new(c[0], palette_for(c[0])))
	if mode != "cast":
		s.figures = [HeroFigure.new("rue", Player.RUE)]
	tree.root.add_child(s)
	await frames(3)
	return s


func test_cast_before_after() -> void:
	var s := await _sheet("cast")
	await shot("style_cast_before_after")
	s.queue_free()
	await frames(2)


func test_rue_motion_and_moods() -> void:
	var s := await _sheet("rue")
	await shot("style_rue_walk_moods")
	s.queue_free()
	await frames(2)
