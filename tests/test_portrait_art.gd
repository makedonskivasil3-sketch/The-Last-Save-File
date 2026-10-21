extends "res://tests/test_case.gd"
## Finished portrait art reaches the live dialogue and cinematic portraits
## (PortraitArt, PortraitView), but only for the story state it was painted
## for; every other state, and every broken file, falls back to the drawn bust.
## The images here are test fixtures written by the test (flat colours),
## not character art.

const FIXTURES := "user://test_portraits/"


func _fixture_set(who: String, palette: Dictionary, expressions: Dictionary, size := Vector2i(48, 64), extra := {}) -> void:
	var dir := FIXTURES + who
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var pal := {}
	for k in palette:
		pal[k] = "#" + (palette[k] as Color).to_html(false)
	var m := {"version": 1, "size": [size.x, size.y], "anchor": [0.5, 0.3], "zoom": 1.0, "palette": pal, "provenance": "test fixture"}
	m.merge(extra, true)
	var f := FileAccess.open(dir + "/portrait.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(m))
	f.close()
	for name in expressions:
		var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		img.fill(expressions[name])
		img.save_png(dir + "/" + name + ".png")


func _clean() -> void:
	var g := ProjectSettings.globalize_path(FIXTURES)
	if DirAccess.dir_exists_absolute(g):
		for who in DirAccess.get_directories_at(g):
			for file in DirAccess.get_files_at(g + who):
				DirAccess.remove_absolute(g + who + "/" + file)
			DirAccess.remove_absolute(g + who)
	PortraitArt.clear_cache()


func _use_fixtures() -> void:
	_clean()
	PortraitArt.root = FIXTURES


func _restore_root() -> void:
	_clean()
	PortraitArt.root = PortraitArt.ROOT


func _pixel(t: Texture2D) -> Color:
	return t.get_image().get_pixel(4, 4)


func test_mira_s_finished_art_is_what_the_live_dialogue_shows() -> void:
	_use_fixtures()
	var w := await start_session()
	var mira: Npc = w.area.mira
	_fixture_set("mira", mira.sprite().palette, {"neutral": Color.RED, "concerned": Color.GREEN, "remembering": Color.BLUE, "eager": Color.YELLOW, "relieved": Color.MAGENTA, "afraid": Color.CYAN, "determined": Color.ORANGE})
	await interact_with(w, mira)
	var view: PortraitView = w.hud._dialogue_portrait
	check(w.hud.is_dialogue_open() and view.visible, "talking to Mira, her portrait is up")
	check(view.uses_external_art(), "her finished art is in the box, not the drawn bust")
	var shown := view.shown_texture()
	check(shown != null, "a texture is drawn")
	if shown:
		var c := _pixel(shown)
		var expected: Color = {"neutral": Color.RED, "concerned": Color.GREEN, "remembering": Color.BLUE, "eager": Color.YELLOW, "relieved": Color.MAGENTA, "afraid": Color.CYAN, "determined": Color.ORANGE}.get(view.portrait.expression, Color.RED)
		check(c.is_equal_approx(expected), "it is the fixture for her current expression (%s: %s)" % [view.portrait.expression, c])
	await finish_dialogue(w)
	_restore_root()


func test_a_changing_expression_keeps_the_bust_and_text_still() -> void:
	_use_fixtures()
	var w := await start_session()
	var mira: Npc = w.area.mira
	_fixture_set("mira", mira.sprite().palette, {"neutral": Color.RED, "afraid": Color.CYAN})
	w.hud.show_dialogue("MIRA", Hud.NPC_COLOR, ["one", "two"], "", CharacterArt.mira("neutral", mira.sprite().palette), ["neutral", "afraid"])
	await frames(2)
	var view: PortraitView = w.hud._dialogue_portrait
	var r1 := view.art_rect()
	var text_x: float = w.hud._dialogue_text.position.x
	check(_pixel(view.shown_texture()).is_equal_approx(Color.RED), "neutral first")
	w.hud._next_dialogue_line()
	await frames(2)
	check(_pixel(view.shown_texture()).is_equal_approx(Color.CYAN), "then afraid")
	check_eq(view.art_rect(), r1, "the bust doesn't move between expressions")
	check_eq(w.hud._dialogue_text.position.x, text_x, "and neither does the text")
	w.hud.close_dialogue()
	_restore_root()


func test_rue_s_restored_art_never_covers_her_missing_or_part_restored_face() -> void:
	_use_fixtures()
	_fixture_set("rue", Player.RUE, {"neutral": Color.RED})
	var missing := CharacterArt.rue("neutral", Player.palette_for(0, []))
	var part := CharacterArt.rue("neutral", Player.palette_for(3, []))
	var whole := CharacterArt.rue("neutral", Player.palette_for(5, []))
	var borrowed := CharacterArt.rue("neutral", Player.palette_for(5, ["wren"]))
	check(PortraitArt.resolve(missing) == null, "no memories: the drawn missing face")
	check(PortraitArt.resolve(part) == null, "three memories: the drawn part-restored face")
	check(PortraitArt.resolve(borrowed) == null, "wearing Wren's ribbon: the drawn face with it")
	check(PortraitArt.resolve(whole) != null, "all five memories: the finished art")
	# Through the actual cinematic portrait too.
	var w := await start_session()
	w.hud._show_portrait(missing)  # what a scene does for each line
	await frames(1)
	check(not w.hud._cine_portrait.uses_external_art(), "the scene portrait keeps the missing face")
	w.hud._show_portrait(whole)
	await frames(1)
	check(w.hud._cine_portrait.uses_external_art(), "restored, the scene portrait shows the finished art")
	w.hud._show_portrait(null)
	_restore_root()


func test_frayed_wren_keeps_her_lost_ribbon_lost() -> void:
	_use_fixtures()
	var w := await start_session()
	await go_to(w, "square", "house")
	var wren: Npc = w.area.wren
	_fixture_set("wren", wren.sprite().palette, {"neutral": Color.RED})
	check(PortraitArt.resolve(CharacterArt.for_npc(wren)) != null, "with her ribbon: her finished art")
	memory().frayed.append("wren")
	wren.refresh_fray()
	await frames(2)
	var frayed := CharacterArt.for_npc(wren)
	check(PortraitArt.resolve(frayed) == null, "ribbon taken: the drawn portrait, without it (%s)" % frayed.palette.get("a"))
	memory().frayed.erase("wren")
	wren.refresh_fray()
	await frames(2)
	check(PortraitArt.resolve(CharacterArt.for_npc(wren)) != null, "given back: her finished art again")
	_restore_root()


func test_broken_or_partial_sets_fall_back_safely() -> void:
	_use_fixtures()
	var pal := {"h": Color("5a3420"), "s": Color("e8c48a"), "c": Color("c9733e"), "d": Color("a85a2e")}
	# A missing expression uses the set's own neutral face.
	_fixture_set("mira", pal, {"neutral": Color.RED})
	var a := PortraitArt.resolve(CharacterArt.mira("afraid", pal))
	check(a != null and _pixel(a.texture("")).is_equal_approx(Color.RED), "afraid, not painted yet: the set's neutral")
	check(PortraitArt.resolve(CharacterArt.mira("afraid", pal)) == a, "resolved once, then cached")
	# A wrongly sized image is refused.
	_clean()
	_fixture_set("mira", pal, {"neutral": Color.RED}, Vector2i(48, 64), {"size": [64, 64]})
	check(PortraitArt.resolve(CharacterArt.mira("neutral", pal)) == null, "an image the wrong size for its set: the drawn bust")
	# An unreadable manifest is refused.
	_clean()
	_fixture_set("mira", pal, {"neutral": Color.RED})
	var f := FileAccess.open(FIXTURES + "mira/portrait.json", FileAccess.WRITE)
	f.store_string("{ not json")
	f.close()
	PortraitArt.clear_cache()
	check(PortraitArt.resolve(CharacterArt.mira("neutral", pal)) == null, "a broken portrait.json: the drawn bust")
	# A corrupt image is refused.
	_clean()
	_fixture_set("mira", pal, {"neutral": Color.RED})
	var g := FileAccess.open(FIXTURES + "mira/neutral.png", FileAccess.WRITE)
	g.store_string("not a png")
	g.close()
	PortraitArt.clear_cache()
	check(PortraitArt.resolve(CharacterArt.mira("neutral", pal)) == null, "a corrupt image: the drawn bust")
	# No set at all.
	_clean()
	check(PortraitArt.resolve(CharacterArt.mira("neutral", pal)) == null, "no art installed: the drawn bust")
	_restore_root()
