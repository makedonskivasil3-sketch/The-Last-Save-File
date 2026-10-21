extends "res://tests/test_case.gd"
## Optional system speech (Narration) is looked for only when it may be used
## (A24): not at startup with narration off, not when the settings menu is
## merely built, at most every PROBE_INTERVAL_MS while nothing is found (so
## voices a browser reports late are still found), and once narration is
## switched on. The spoken speech rate is its own setting, apart from text
## speed. The headless runner has no speech service: these tests count the
## questions asked, not what a real device answers.


func _reset_probe() -> void:
	Narration._english_voices = PackedStringArray()
	Narration.probes = 0
	Narration._probed_at = -Narration.PROBE_INTERVAL_MS


func test_with_narration_off_nothing_asks_the_device() -> void:
	settings().narration = false
	_reset_probe()
	var n := Narration.new()
	tree.root.add_child(n)
	await frames(1)
	check_eq(Narration.probes, 0, "a narrator created with narration off asks nothing")
	var box := Control.new()
	box.visible = false
	tree.root.add_child(box)
	var panel := SettingsPanel.new()
	box.add_child(panel)
	await frames(1)
	check_eq(Narration.probes, 0, "the settings menu, built but not shown, asks nothing")
	box.visible = true
	await frames(1)
	check_eq(Narration.probes, 1, "shown, it asks once (to show whether a voice exists)")
	box.queue_free()
	n.queue_free()


func test_switching_narration_on_asks() -> void:
	settings().narration = false
	_reset_probe()
	var n := Narration.new()
	tree.root.add_child(n)
	await frames(1)
	Settings.set_value("narration", true)
	check_eq(Narration.probes, 1, "switched on: asked")
	Settings.set_value("narration", false)
	n.queue_free()


func test_an_empty_answer_is_asked_again_but_not_every_frame() -> void:
	_reset_probe()
	for i in 20:
		Narration.available()
	check_eq(Narration.probes, 1, "twenty calls in a row ask once")
	Narration._probed_at -= Narration.PROBE_INTERVAL_MS  # time passes
	Narration.available()
	check_eq(Narration.probes, 2, "later, still nothing found: asked again (late browser voices)")
	Narration._english_voices = PackedStringArray(["test-voice"])
	for i in 5:
		check(Narration.available(), "once found, always available")
	check_eq(Narration.probes, 2, "and never asked again")
	_reset_probe()


func test_speech_rate_is_its_own_setting() -> void:
	var before_text: int = settings().text_speed
	var rates := []
	for r in Narration.SPEECH_RATES.size():
		Settings.set_value("speech_rate", r)
		rates.append(Narration.speech_for("MIRA", 12).rate)
		check_eq(settings().text_speed, before_text, "speech rate %d leaves text speed alone" % r)
		check(rates[r] >= 0.5 and rates[r] <= 2.0, "a pace the device accepts (%.2f)" % rates[r])
	check(rates[0] < rates[1] and rates[1] < rates[2] and rates[2] <= rates[3], "slower to fastest: %s" % [rates])
	Settings.set_value("speech_rate", 1)
	check_eq(Narration.speech_for("MIRA", 12).rate, float(Narration.CHARACTER_SPEECH["MIRA"].rate), "normal: each character's own pace")
	var pip: float = Narration.speech_for("PIP", 12).rate
	Settings.set_value("text_speed", 3)
	check_eq(Narration.speech_for("PIP", 12).rate, pip, "instant text doesn't hurry the voice")
	Settings.set_value("text_speed", before_text)
	Settings.set_value("speech_rate", 2)
	var cfg := ConfigFile.new()
	cfg.load(Settings._path)
	check_eq(int(cfg.get_value("story", "speech_rate", -1)), 2, "saved with the other story settings")
	Settings.set_value("speech_rate", 1)
