extends "res://tests/test_case.gd"
## Procedural voices and text speed (docs/AUDIO_DIRECTION.md).


func test_every_speaker_has_a_distinct_voice() -> void:
	var sounds := {}
	for who in ["MIRA", "WREN", "THE ARCHIVIST", "PIP"]:
		var v: Dictionary = Sfx.VOICE_PROFILES[who]
		check(Sfx.stream(v.sound) != null, "%s's voice builds" % who)
		sounds[v.sound] = true
	check_eq(sounds.size(), 4, "four different timbres, not one blip at four pitches")


func test_voices_play_on_their_own_bus() -> void:
	Sfx._last_key = 0
	Sfx._syllable = 0
	Sfx.voice_blip("MIRA")
	var playing_voice := false
	for p in Sfx._voice_pool:
		if p.playing:
			playing_voice = true
	check(playing_voice, "Mira speaks on the Voice bus")
	check(AudioServer.get_bus_index("Voice") != -1, "which exists")


func test_rue_gains_notes_with_memories() -> void:
	var m := memory()
	var heard := {}
	for i in 12:
		Sfx._last_key = 0
		Sfx.rue_note()
		heard[Sfx._rue_note] = true
	check_eq(heard.size(), 2, "two notes with no memories")
	for f in Story.FRAGMENTS:
		m.add_fragment(f.id)
	heard.clear()
	for i in 12:
		Sfx.rue_note()
		heard[Sfx._rue_note] = true
	check_eq(heard.size(), Sfx.RUE_MOTIF.size(), "the whole phrase with all five")


func test_the_owner_voice_breaks_up_when_hunting() -> void:
	seed(7)
	Sfx.owner_strain = 0.0
	var calm := 0
	for i in 200:
		Sfx._last_key = 0
		var before: int = Sfx.history.size()
		Sfx.owner_blip("a")
		if Sfx.history.size() > before or Sfx.history.size() == 32:
			calm += 1
	Sfx.owner_strain = 1.0
	var dropped := 0
	for i in 200:
		Sfx._last_key = 0
		Sfx.history.clear()
		Sfx.owner_blip("a")
		if Sfx.history.is_empty():
			dropped += 1
	Sfx.owner_strain = 0.0
	check(dropped > 20, "at full strain syllables drop out (%d of 200)" % dropped)


func test_text_speed_setting() -> void:
	var s := settings()
	s.text_speed = 3
	var w := await start_session()
	await interact_with(w, w.area.mira)
	await frames(2)
	check_eq(w.hud._dialogue_text.visible_characters, w.hud._dialogue_text.get_total_character_count(), "Instant shows the whole line at once")
	s.text_speed = 1


func test_new_settings_persist() -> void:
	var s := settings()
	s.voice_volume = 0.3
	s.text_speed = 2
	s.save()
	s.voice_volume = 0.9
	s.text_speed = 1
	s._load()
	check(absf(s.voice_volume - 0.3) < 0.01, "voice volume is remembered")
	check_eq(s.text_speed, 2, "text speed too")
	s.text_speed = 1
	s.voice_volume = 0.9
	s.save()


func test_muting_music_keeps_the_heartbeat() -> void:
	var w := await start_session()
	check_eq(w.drone._heart.bus, "SFX", "the heartbeat is a threat cue, not music")
