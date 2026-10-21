extends "res://tests/test_case.gd"

func _asset(who: String, palette: Dictionary) -> PortraitAsset:
	var a := PortraitAsset.new()
	a.who = who
	a.palette = palette.duplicate()
	a.provenance = "Synthetic regression fixture"
	a.rights = "Created by this test"
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.MAGENTA)
	a.still = ImageTexture.create_from_image(img)
	return a

func test_actual_hud_uses_registered_approved_art_and_preserves_palette_fallback() -> void:
	var w := await start_session()
	var face := CharacterArt.rue()
	var a := _asset("rue", face.palette)
	PortraitResolver.register(a)
	w.hud.show_dialogue("RUE", Color.WHITE, ["fixture"], "", face)
	check(w.hud._dialogue_portrait._asset == a, "actual dialogue uses the approved external resource")
	check(w.hud._dialogue_portrait._asset.texture("") == a.still, "the fixture is the texture delivered to draw")
	w.hud.show_dialogue("RUE", Color.WHITE, ["missing"], "", CharacterArt.rue("neutral", Player.MISSING))
	check(w.hud._dialogue_portrait._asset == null, "a restored asset cannot overwrite Rue's missing face")
	var borrowed := Player.palette_for(5, ["mira", "wren"])
	w.hud.show_dialogue("RUE", Color.WHITE, ["borrowed"], "", CharacterArt.rue("neutral", borrowed))
	check(w.hud._dialogue_portrait._asset == null, "borrowed coat and scarf retain the procedural variant")
	w.hud.close_dialogue()
	PortraitResolver.clear_registered()

func test_resource_round_trip_and_all_six_live_identities() -> void:
	for who in CharacterArt.KINDS:
		var face := CharacterArt.Portrait.new(who, "neutral", Player.RUE)
		var a := _asset(who, face.palette)
		var path := "user://portrait_fixture_%s.tres" % who
		check_eq(ResourceSaver.save(a, path), OK, "fixture resource saves")
		var loaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as PortraitAsset
		PortraitResolver.register(loaded)
		var view := PortraitView.new()
		tree.root.add_child(view)
		view.portrait = face
		check(view._asset == loaded, "live resolver supports %s" % who)
		view.frame = "talk"
		if view._asset:
			check(view._asset.texture(view.frame) == loaded.still, "missing talk frame holds the same art")
		view.free()
		DirAccess.remove_absolute(path)
	PortraitResolver.clear_registered()

func test_invalid_art_never_replaces_a_valid_procedural_character() -> void:
	var face := CharacterArt.rue()
	for fault in ["rights", "size", "crop", "frame"]:
		var a := _asset("rue", face.palette)
		match fault:
			"rights": a.rights = ""
			"size": a.still = ImageTexture.create_from_image(Image.create(8, 8, false, Image.FORMAT_RGBA8))
			"crop": a.crop = Rect2(-1, 0, 1, 1)
			"frame": a.talk = ImageTexture.create_from_image(Image.create(128, 128, false, Image.FORMAT_RGBA8))
		PortraitResolver.register(a)
		var view := PortraitView.new()
		tree.root.add_child(view)
		view.portrait = face
		check(view._asset == null and view._figure != null, "invalid %s uses the same character's fallback" % fault)
		view.free()
	PortraitResolver.clear_registered()
