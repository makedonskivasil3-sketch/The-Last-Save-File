extends "res://tests/test_case.gd"
## The voice manifest (audio/voice/manifest.csv) is the production list for
## recorded lines. It must match the game's text exactly, and the ids the
## game asks for at runtime must be the ids in it.


func test_the_manifest_matches_the_story_text() -> void:
	var expected := VoiceManifest.to_csv(VoiceManifest.rows())
	var actual := FileAccess.get_file_as_string(VoiceManifest.PATH)
	check(actual == expected, "audio/voice/manifest.csv is up to date (regenerate: godot --headless --path . -s res://tools/voice_manifest.gd)")
	var ids := {}
	for r in VoiceManifest.rows():
		check(not ids.has(r.id), "ids are unique: %s" % r.id)
		ids[r.id] = true
		check(r.subtitle != "" and r.spoken != "", "every line has subtitle and spoken text")
		check(not r.spoken.begins_with(">") and not r.spoken.begins_with("MIRA:"), "spoken text has no prompt or name tag: %s" % r.spoken)


func test_the_game_asks_for_manifest_ids() -> void:
	var f := Story.fragment("controller")
	var id := Hud.voice_id("memory.controller", f.lines[0])
	var row: Array = VoiceManifest.rows().filter(func(r: Dictionary) -> bool: return r.id == id)
	check_eq(row.size(), 1, "the first line of the controller memory is in the manifest")
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = 11025
	var data := PackedByteArray()
	data.resize(11025 * 2)
	clip.data = data
	VoiceOver.register(id, clip)
	var w := await start_session()
	for c in w.area.get_children():
		if c is MemoryFragment:
			w.player.global_position = c.global_position
	await wait_until(func() -> bool: return VoiceOver.current_id() == id, 4.0, "the game to play the manifest id")
	await read_through_cinematic(w)


func test_no_line_needs_audio_to_be_understood() -> void:
	# Every voiced line is also shown as text: the subtitle is the line itself.
	for r in VoiceManifest.rows():
		check(r.subtitle.contains(r.spoken.substr(0, mini(12, r.spoken.length()))), "the subtitle carries what is spoken: %s" % r.id)
