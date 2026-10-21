extends "res://tests/test_case.gd"
## The character presentation contract (docs/CHARACTER_ART.md): only a
## character with their own portrait shows one (never Rue's face as a
## stand-in), and Mira's portrait matches her sprite, has every expression,
## talks and blinks, and follows what she says.


func _mask(img: Image) -> PackedByteArray:
	var out := PackedByteArray()
	for y in img.get_height():
		for x in img.get_width():
			out.append(1 if img.get_pixel(x, y).a > 0.5 else 0)
	return out


func test_no_one_wears_rue_s_face() -> void:
	# Everyone with a face has their own illustrated bust (PortraitView),
	# drawn from their own body; nobody stands in for anybody, and Pip, a
	# creature, has none.
	var bodies := {}
	for who in ["rue", "mira", "wren", "tobben", "archivist", "arin"]:
		check(CharacterArt.has_portrait(who), "%s has a portrait" % who)
		bodies[CharacterArt.kind_for(who)] = who
	check_eq(bodies.size(), 6, "six people, six different bodies")
	check(not CharacterArt.has_portrait("pip"), "Pip has none")
	var w := await start_session()
	await go_to(w, "square", "house")
	await interact_with(w, w.area.tobben)
	check(w.hud.is_dialogue_open(), "talking to Tobben")
	check(w.hud._dialogue_portrait.visible, "his own portrait in his box")
	check_eq(w.hud._dialogue_portrait.portrait.who, "tobben", "and it's Tobben's, not Rue's")
	check_eq(w.hud._dialogue_portrait.portrait.palette, w.area.tobben.sprite().palette, "in his sprite's colours")
	await finish_dialogue(w)


func test_mira_s_portrait_is_her_sprite() -> void:
	var w := await start_session()
	var mira: Npc = w.area.mira
	var p := CharacterArt.for_npc(mira)
	check(p != null and p.who == "mira", "Mira has a portrait")
	var img := CharacterArt.image(p)
	var pal: Dictionary = mira.sprite().palette
	check_eq(img.get_pixel(12, 5), pal.h, "her hair is her sprite's hair")
	check_eq(img.get_pixel(15, 15), pal.s, "her skin is her sprite's skin")
	check_eq(img.get_pixel(10, 29), pal.c, "her dress is her sprite's dress")
	check_eq(img.get_pixel(25, 7), pal.d, "her ribbon is her dress trim")
	var rue := CharacterArt.image(CharacterArt.rue())
	var a := _mask(img)
	var b := _mask(rue)
	var differ := 0
	for i in a.size():
		if a[i] != b[i]:
			differ += 1
	check(differ > 60, "her silhouette is her own, not Rue's recoloured (%d pixels differ)" % differ)


func test_every_expression_and_frame_reads_differently() -> void:
	var seen := {}
	for e in CharacterArt.expressions_for("mira"):
		var img := CharacterArt.image(CharacterArt.mira(e, {"h": Color("5a3420"), "s": Color("e8c48a"), "c": Color("c9733e"), "d": Color("a85a2e")}))
		var key := img.get_data().hex_encode().md5_text()
		check(not seen.has(key), "'%s' is not the same face as '%s'" % [e, seen.get(key, "")])
		seen[key] = e
	for own in ["eager", "proud", "reset"]:
		check(own in CharacterArt.expressions_for("mira"), "Mira has her own '%s'" % own)
		check(not (own in CharacterArt.expressions_for("rue")), "and it is hers, not Rue's")
	var p := CharacterArt.mira("neutral", {"s": Color("e8c48a")})
	var still := CharacterArt.image(p).get_data()
	check(CharacterArt.image(p, "talk").get_data() != still, "a talking frame")
	check(CharacterArt.image(p, "blink").get_data() != still, "a blink frame")


func test_talking_to_mira_shows_her_face_and_mood() -> void:
	var w := await start_session()
	await interact_with(w, w.area.mira)
	check(w.hud.is_dialogue_open(), "talking to Mira")
	check(w.hud._dialogue_portrait.visible and w.hud._dialogue_portrait.portrait != null, "her portrait is in the box")
	check_eq(w.hud._dialogue_portrait.portrait.palette, w.area.mira.sprite().palette, "drawn in her sprite's colours")
	check(w.hud._dialogue_text.position.x > w.hud._dialogue_portrait.size.x, "the text makes room for it")
	var line: String = w.hud._dialogue_text.text
	check_eq(w.hud.dialogue_expression(), ArinsRoom.mira_expression(line), "her expression follows the line")
	var clock_start: float = w.hud._dialogue_portrait._figure._t
	var spoke := false
	for i in 20:
		spoke = spoke or w.hud._dialogue_portrait._figure.talking
		await frames(2)
	check((spoke and w.hud._dialogue_portrait._figure._t > clock_start) or Settings.reduce_flashing,
		"the live renderer owns mouth motion and its clock advances; HUD need not toggle a second mouth rhythm")
	await shot("mira_dialogue_portrait")
	await finish_dialogue(w)
	check(not w.hud._dialogue_portrait.visible, "and goes with the box")


func test_mira_s_moods_cover_her_story() -> void:
	check_eq(ArinsRoom.mira_expression(ArinsRoom.MIRA_LINES[2]), "afraid", "'Who are you?' is afraid")
	check_eq(ArinsRoom.mira_expression(Story.MIRA_ASK[0]), "eager", "asking to go out is eager")
	check_eq(ArinsRoom.mira_expression(Story.RECALL["mira"][0][1]), "relieved", "after pinning her note: relieved")
	check_eq(ArinsRoom.mira_expression(Story.MIRA_RESET_LINES[0]), "reset", "reset by the owner: the blank smile")
	var used := {}
	for stem in ArinsRoom.voice_lines():
		for l in ArinsRoom.voice_lines()[stem]:
			used[ArinsRoom.mira_expression(l)] = true
	check(used.size() >= 6, "her lines use most of her faces (%s)" % ", ".join(used.keys()))


func test_wren_s_portrait_is_her_sprite_and_her_own() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var wren: Npc = w.area.wren
	var p := CharacterArt.for_npc(wren)
	check(p != null and p.who == "wren", "Wren has a portrait")
	var img := CharacterArt.image(p)
	var pal: Dictionary = wren.sprite().palette
	check_eq(img.get_pixel(12, 7), pal.h, "her hair is her sprite's hair")
	check_eq(img.get_pixel(15, 15), pal.s, "her skin is her sprite's skin")
	check_eq(img.get_pixel(12, 29), pal.c, "her pinafore is her sprite's clothes")
	check_eq(img.get_pixel(4, 13), pal.d, "her pigtail ties are her clothes' trim")
	for own in ["brave", "awed"]:
		check(own in CharacterArt.expressions_for("wren"), "Wren has her own '%s'" % own)
	var masks := {}
	for who in ["rue", "mira", "wren"]:
		masks[who] = _mask(CharacterArt.image(CharacterArt.Portrait.new(who, "neutral", pal)))
	for pair in [["wren", "rue"], ["wren", "mira"]]:
		var differ := 0
		for i in masks[pair[0]].size():
			if masks[pair[0]][i] != masks[pair[1]][i]:
				differ += 1
		check(differ > 60, "Wren's silhouette isn't %s's (%d pixels differ)" % [pair[1], differ])


func test_talking_to_wren_shows_her_face() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	await interact_with(w, w.area.wren)
	check(w.hud.is_dialogue_open(), "talking to Wren")
	check(w.hud._dialogue_portrait.visible and w.hud._dialogue_portrait.portrait.who == "wren", "her portrait is in the box")
	check_eq(w.hud.dialogue_expression(), VillageSquare.wren_expression(w.hud._dialogue_text.text), "her expression follows the line")
	check_eq(w.hud._dialogue_portrait._figure.expression, w.hud.dialogue_expression(), "and the face shows it")
	await shot("wren_dialogue_portrait")
	await finish_dialogue(w)
