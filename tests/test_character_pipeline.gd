extends "res://tests/test_case.gd"
## The character pipeline (docs/ART_BIBLE.md): an artist's sheet when one is
## valid, the procedural HeroFigure otherwise, and never an error for a
## missing or broken sheet. CharacterArt.figure() is the one place that
## decides.

const DIR := "user://test_sheets"


func before_each() -> void:
	super()
	CharacterSheet.root = DIR
	_clear()


func after_each() -> void:
	CharacterSheet.root = CharacterSheet.ROOT
	_clear()
	super()


func _clear() -> void:
	for who in ["rue", "broken", "short"]:
		for f in ["sheet.json", "sheet.png"]:
			var p := DIR.path_join(who).path_join(f)
			if FileAccess.file_exists(p):
				DirAccess.remove_absolute(p)


## A sheet of solid blocks: idle (front, back, side) and walk (front, side).
func _write_sheet(who: String, rows: Array, frames := 4, image_rows := -1) -> void:
	DirAccess.make_dir_recursive_absolute(DIR.path_join(who))
	var n := rows.size() if image_rows < 0 else image_rows
	var img := Image.create(16 * frames, 32 * n, false, Image.FORMAT_RGBA8)
	for r in n:
		for f in frames:
			img.fill_rect(Rect2i(f * 16 + 4, r * 32 + 4, 8, 28), Color(0.2 + 0.1 * r, 0.5, 0.2 + 0.15 * f))
	img.save_png(DIR.path_join(who).path_join("sheet.png"))
	var json := {"frame": [16, 32], "feet": [8, 32], "px_per_unit": 2.0, "rows": rows,
		"clips": {"idle": {"frames": frames, "fps": 6}, "walk": {"frames": frames, "fps": 12}}}
	var f := FileAccess.open(DIR.path_join(who).path_join("sheet.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(json))
	f.close()


func test_without_a_sheet_the_cast_is_the_procedural_figure() -> void:
	for kind in ["rue", "adult", "dress", "child", "apron", "robe"]:
		var fig := CharacterArt.figure("nobody", kind, Player.RUE)
		check(fig is HeroFigure and not fig is CharacterSheet, "%s: HeroFigure" % kind)


func test_a_valid_sheet_is_used() -> void:
	_write_sheet("rue", ["idle.front", "idle.back", "idle.side", "walk.front", "walk.side"])
	var fig := CharacterArt.figure("rue", "rue", Player.RUE)
	check(fig is CharacterSheet, "the sheet wins")
	if not fig is CharacterSheet:
		return
	var s: CharacterSheet = fig
	check_eq(s.current_frame()[0], 0, "standing, facing the camera: idle.front")
	s.facing = Vector2.UP
	check_eq(s.current_frame()[0], 1, "facing away: idle.back")
	s.facing = Vector2.LEFT
	s.update(0.1, Vector2(-40, 0))
	check_eq(s.clip_name(), "walk", "moving: walk")
	check_eq(s.current_frame()[0], 4, "walk.side (left is mirrored)")
	s.update(0.1, Vector2.ZERO)
	s.crouch = true
	check_eq(s.clip_name(), "crouch", "hiding asks for crouch")
	check_eq(s.current_frame()[0], 2, "which this sheet hasn't got: its idle for the view")
	# It draws, inside a real draw call, without errors.
	var node := Node2D.new()
	tree.root.add_child(node)
	var drew := [false]
	node.draw.connect(func() -> void:
		s.draw(node, {"offset": Vector2(40, 40)})
		s.draw(node, {"slices": [2.0, 0.0, 0.0]})  # a tear: the procedural rig draws it
		drew[0] = true)
	node.queue_redraw()
	await frames(3)
	check(drew[0], "drawn")
	node.queue_free()


func test_a_broken_sheet_falls_back_without_breaking_anything() -> void:
	DirAccess.make_dir_recursive_absolute(DIR.path_join("broken"))
	var f := FileAccess.open(DIR.path_join("broken").path_join("sheet.json"), FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	var fig := CharacterArt.figure("broken", "rue", Player.RUE)
	check(fig is HeroFigure and not fig is CharacterSheet, "bad JSON: the procedural figure")
	# Rows that name more of the image than exists.
	_write_sheet("short", ["idle.front", "idle.back", "idle.side"], 4, 1)
	fig = CharacterArt.figure("short", "rue", Player.RUE)
	check(not fig is CharacterSheet, "rows outside the image: not used")
	# No idle at all.
	_write_sheet("rue", ["walk.front"])
	fig = CharacterArt.figure("rue", "rue", Player.RUE)
	check(not fig is CharacterSheet, "a sheet that can't stand still: not used")


func test_the_world_draws_the_new_cast() -> void:
	CharacterSheet.root = CharacterSheet.ROOT
	var w := await start_session()
	check(w.player._sprite is HeroFigure, "Rue")
	check(w.area.mira.sprite() is HeroFigure, "Mira")
	check_eq(w.player._sprite.height(), 34, "Rue at the art bible's height")
	await go_to(w, "square", "house")
	check(w.area.arin._sprite is HeroFigure, "Arin")
	check(w.area.wren.sprite() is HeroFigure and w.area.tobben.sprite() is HeroFigure, "Wren and Tobben")
	check(w.area.wren.sprite().height() < w.area.tobben.sprite().height(), "Wren is a child beside Tobben")
