extends "res://tests/test_case.gd"
## The silent-audio fix (docs/AUDIO_DIAGNOSIS.md). On the web (Sample
## playback, Godot 4.3) every add_bus() put the browser's copy of the bus in
## the wrong place, so nothing reached the speakers. The buses are created in
## one step instead, and the music sits where it can be heard.


func test_buses_are_in_order_and_reach_master() -> void:
	var names: Array = []
	for i in AudioServer.bus_count:
		names.append(AudioServer.get_bus_name(i))
	check_eq(names.slice(0, 6), ["Master", "Music", "Memory", "SFX", "UI", "Voice"], "every bus, in order")
	for b in Sfx.BUSES:
		check_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(b)), &"Master", "%s sends to Master" % b)


func test_no_bus_is_added_one_at_a_time() -> void:
	# add_bus() misfiles the browser's copy of the bus (the web build went silent).
	for path in ["res://scripts/autoload/sfx.gd", "res://scripts/autoload/settings.gd", "res://scripts/audio/voice_over.gd"]:
		check(not FileAccess.get_file_as_string(path).contains("AudioServer.add_bus("), "%s doesn't call AudioServer.add_bus()" % path)


func test_the_theme_is_above_the_drone() -> void:
	var title_db: float = load("res://scripts/ui/title.gd").MUSIC_DB
	check(title_db > Drone.HUM_DB, "the title theme (%.0f dB) sits above the hum (%.0f dB)" % [title_db, Drone.HUM_DB])
	var w := await start_session()
	await wait(4.0)
	var amb: Ambience = w._ambience
	var theme: AudioStreamPlayer = amb._memory_theme
	check(theme != null and theme.playing, "Arin's room plays the theme")
	check(theme.volume_db > -30.0, "loud enough to be heard (%.1f dB)" % theme.volume_db)


func test_the_hum_reaches_small_speakers() -> void:
	# Most of a laptop's or phone's speaker can't play 55 Hz: the hum carries
	# harmonics above 250 Hz.
	var w := Drone._build_hum()
	var pcm := w.data
	var n := pcm.size() / 2
	var rate := float(w.mix_rate)
	var mid := 0.0
	var all := 0.0
	# Goertzel at the 5th and 7th harmonics vs the fundamental.
	for f in [275.0, 385.0, 55.0]:
		var k := 2.0 * cos(TAU * f / rate)
		var s1 := 0.0
		var s2 := 0.0
		for i in n:
			var x := float(pcm.decode_s16(i * 2)) / 32768.0
			var s0 := x + k * s1 - s2
			s2 = s1
			s1 = s0
		var p := s1 * s1 + s2 * s2 - k * s1 * s2
		all += p
		if f > 250.0:
			mid += p
	check(mid / all > 0.03, "the hum has energy a small speaker can play (%.1f%% at 275/385 Hz)" % (100.0 * mid / all))


func test_speech_ducks_the_music_by_bus_volume() -> void:
	# The browser's Sample playback runs no bus effects, so the duck is bus
	# volume (which it does follow), never an AudioEffectAmplify.
	settings().music_volume = 0.8
	settings().apply()
	for b in ["Music", "Memory"]:
		var i := AudioServer.get_bus_index(b)
		for e in AudioServer.get_bus_effect_count(i):
			check(not (AudioServer.get_bus_effect(i, e) is AudioEffectAmplify), "%s has no amplify effect to duck with" % b)
	var music := AudioServer.get_bus_index("Music")
	var memory := AudioServer.get_bus_index("Memory")
	var base := AudioServer.get_bus_volume_db(music)
	Sfx.duck_for_speech(true)
	await wait(0.8)
	check(absf(AudioServer.get_bus_volume_db(music) - (base + Sfx.SPEECH_DUCK_DB)) < 0.5, "the music dips under speech (%.1f dB from %.1f)" % [AudioServer.get_bus_volume_db(music), base])
	check(absf(AudioServer.get_bus_volume_db(memory) - (base + Sfx.SPEECH_DUCK_DB)) < 0.5, "and the memory theme")
	# A volume change mid-line keeps the dip; a muted slider stays muted.
	settings().set_value("music_volume", 0.5)
	check(absf(AudioServer.get_bus_volume_db(music) - (linear_to_db(0.5) + Sfx.SPEECH_DUCK_DB)) < 0.5, "a new music volume, still ducked")
	settings().set_value("music_volume", 0.0)
	check(AudioServer.is_bus_mute(music), "music at 0 stays muted under speech")
	settings().set_value("music_volume", 0.8)
	Sfx.duck_for_speech(false)
	await wait(1.5)
	check(absf(AudioServer.get_bus_volume_db(music) - base) < 0.1, "and comes back after the line (%.1f dB)" % AudioServer.get_bus_volume_db(music))
	check(Sfx.speech_duck_db() <= 0.0, "the duck never raises anything")


func test_the_web_page_turns_sound_on_at_the_first_gesture() -> void:
	# web/sound_unlock.js goes into the page's head (export_presets.cfg): it
	# resumes the browser's audio on the first click, tap or key, plays a
	# silent media loop so an iPhone's silent switch doesn't mute the game,
	# and says on screen whether sound is on.
	var js := FileAccess.get_file_as_string("res://web/sound_unlock.js")
	check(js.contains("resume()") and js.contains("audioSession"), "the unlock script resumes audio")
	var cfg := ConfigFile.new()
	check_eq(cfg.load("res://export_presets.cfg"), OK, "export presets load")
	var head := ""
	for s in cfg.get_sections():
		if cfg.get_value(s, "platform", "") == "Web":
			head = str(cfg.get_value(s.replace(".options", "") + ".options", "html/head_include", ""))
	check_eq(head, "<script>\n" + js + "</script>", "the Web export includes it, unchanged")
