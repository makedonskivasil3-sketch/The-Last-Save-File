extends "res://tests/test_case.gd"
## Rendered proof that a finished portrait set reaches the live dialogue box
## (PortraitArt -> PortraitView). The set is a test fixture drawn here (a
## striped placeholder face, not character art), installed under user:// and
## removed afterwards. Captures: the drawn bust, the fixture still, and the
## fixture's talk frame on the mouth beat.

const FIXTURES := "user://tour_portraits/"


func _face(size: int, open_mouth: bool) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			# Diagonal stripes: unmistakably a placeholder.
			var stripe := (x + y) / 12 % 2 == 0
			img.set_pixel(x, y, Color("3a2f4a") if stripe else Color("4a3d5c"))
	var c := Vector2(size * 0.5, size * 0.42)
	for y in size:
		for x in size:
			var p := Vector2(x, y)
			if p.distance_to(c) < size * 0.28:
				img.set_pixel(x, y, Color("e8c48a"))
			for eye in [c + Vector2(-size * 0.1, -size * 0.03), c + Vector2(size * 0.1, -size * 0.03)]:
				if p.distance_to(eye) < size * 0.035:
					img.set_pixel(x, y, Color("2a2030"))
			var m := c + Vector2(0, size * 0.13)
			if open_mouth and absf(x - m.x) < size * 0.06 and absf(y - m.y) < size * 0.04:
				img.set_pixel(x, y, Color("7a2a2a"))
			elif not open_mouth and absf(x - m.x) < size * 0.07 and absf(y - m.y) < size * 0.008:
				img.set_pixel(x, y, Color("7a2a2a"))
	return img


func _install(palette: Dictionary) -> void:
	var dir := FIXTURES + "mira"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var pal := {}
	for k in palette:
		pal[k] = "#" + (palette[k] as Color).to_html(false)
	var f := FileAccess.open(dir + "/portrait.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "size": [192, 192], "anchor": [0.5, 0.42], "zoom": 1.0, "palette": pal, "provenance": "tour fixture"}))
	f.close()
	for e in CharacterArt.expressions_for("mira"):
		_face(192, false).save_png("%s/%s.png" % [dir, e])
		_face(192, true).save_png("%s/%s_talk.png" % [dir, e])


func _remove() -> void:
	var g := ProjectSettings.globalize_path(FIXTURES + "mira")
	if DirAccess.dir_exists_absolute(g):
		for file in DirAccess.get_files_at(g):
			DirAccess.remove_absolute(g + "/" + file)
		DirAccess.remove_absolute(g)
	PortraitArt.root = PortraitArt.ROOT
	PortraitArt.clear_cache()


func test_finished_art_in_the_live_dialogue() -> void:
	var w := await start_session()
	var mira: Npc = w.area.mira
	await interact_with(w, mira)
	await frames(3)
	check(not w.hud._dialogue_portrait.uses_external_art(), "no art installed: the drawn bust")
	await shot("live_art_0_drawn_bust")
	await finish_dialogue(w)
	_install(mira.sprite().palette)
	PortraitArt.root = FIXTURES
	PortraitArt.clear_cache()
	await interact_with(w, mira)
	await frames(3)
	var view: PortraitView = w.hud._dialogue_portrait
	check(view.uses_external_art(), "fixture installed: the live box shows it")
	# Hold the mouth clock on each beat for a deterministic capture.
	view.set_process(false)
	view.frame = "talk"
	view._figure._t = 0.15
	view.queue_redraw()
	await frames(2)
	check(not view.mouth_open(), "closed on this beat")
	await shot("live_art_1_fixture_closed")
	view._figure._t = 0.0
	view.queue_redraw()
	await frames(2)
	check(view.mouth_open(), "open on this beat")
	await shot("live_art_2_fixture_talk")
	view.set_process(true)
	await finish_dialogue(w)
	_remove()
