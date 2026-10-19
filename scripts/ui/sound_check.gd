extends VBoxContainer
## Settings > Sound > Sound check (docs/AUDIO_DIAGNOSIS.md): play an effect,
## the music box and a voice sample at the current volumes, say truthfully
## what can't be heard and why, and restore the sound defaults. Works on the
## title and from the pause menu (it runs while paused); never touches the
## run, the purge or the save, and never raises or unmutes a volume itself.

signal defaults_restored

const DEFAULTS := {"volume": 0.8, "music_volume": 0.8, "sfx_volume": 0.9, "voice_volume": 0.9}

var _status: Label
var _music: AudioStreamPlayer
var _music_left := 0.0
var _peak := -200.0
var _listening := 0.0
var _narrator: Node
## The bus the current test plays on: its own meter, not Master's, so music
## already playing can't make an effect or voice test look heard.
var _meter_bus := "Master"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	add_child(row)
	_button(row, "Effect", _test_effect)
	_button(row, "Music", _test_music)
	_button(row, "Voice", _test_voice)
	_button(self, "Restore sound defaults", _restore_defaults)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.x = 180
	UiStyle.sized(_status, 8)
	_status.add_theme_color_override("font_color", UiStyle.MUTED)
	add_child(_status)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music)
	_narrator = Narration.new()
	add_child(_narrator)


func _button(parent: Control, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _test_effect() -> void:
	Sfx.ui("ui_confirm")
	Sfx.play("pop", 0.0, 1.0, 0.0, "UI")
	_report("effects", "sfx_volume", "Effects", "", "UI")


func _test_music() -> void:
	var level := MusicBox.held_level(OwnerMemory.fragments.size())
	_music.stream = MusicBox.stream(level)
	_music.volume_db = -10.0
	_music.play()
	_music_left = 5.0
	_report("the music box", "music_volume", "Music", "", "Music")


func _test_voice() -> void:
	# No character performances are recorded in this build: the voice sample
	# is the procedural one the game uses for speech.
	for i in 6:
		get_tree().create_timer(0.09 * i, true, false, true).timeout.connect(func() -> void: Sfx.voice_blip("MIRA"))
	var line := "Procedural voice (this build has no recorded speech)."
	if Settings.narration:
		if Narration.available():
			_narrator.speak("This is the narration voice.")
			line += " System narration: speaking now, through the device's own speech, not the game's mixer."
		else:
			line += " System narration: no system voice available on this device."
	_report("a voice", "voice_volume", "Voices", line, "Voice")


## What should be audible right now, and what stops it. Truthful: it names a
## volume at zero instead of raising it.
func _report(what: String, key: String, slider: String, extra := "", bus := "Master") -> void:
	_meter_bus = bus
	var problems: Array = []
	if Settings.volume <= 0.001:
		problems.append("Master is at 0")
	if float(Settings.get(key)) <= 0.001:
		problems.append("%s is at 0" % slider)
	var text := ""
	if problems.is_empty():
		text = "Playing %s at your current volume." % what
	else:
		text = "Nothing will play: %s. Raise it above, or restore the defaults." % " and ".join(problems)
	if extra != "":
		text += " " + extra
	if OS.has_feature("web"):
		text += " In a browser: click the game once first; check the tab isn't muted."
	else:
		_peak = -200.0
		_listening = 1.2  # then say whether the game's output carried it
	_status.text = text


func _restore_defaults() -> void:
	for k in DEFAULTS:
		Settings.set_value(k, DEFAULTS[k])
	_status.text = "Sound settings restored (Master 80%, Music 80%, Effects 90%, Voices 90%). Story progress and other settings are unchanged."
	defaults_restored.emit()


func _process(delta: float) -> void:
	if _music_left > 0.0:
		_music_left -= delta
		if _music_left <= 0.0:
			_music.stop()
	if _listening > 0.0:
		# The Master meter: what the game's mixer really sent out (desktop;
		# the web's Sample playback bypasses this meter).
		var i := maxi(AudioServer.get_bus_index(_meter_bus), 0)
		_peak = maxf(_peak, maxf(AudioServer.get_bus_peak_volume_left_db(i, 0), AudioServer.get_bus_peak_volume_right_db(i, 0)))
		_listening -= delta
		if _listening <= 0.0:
			if _peak > -60.0:
				_status.text += " The %s channel carried it (peak %.0f dB): if you heard nothing, check the device's volume and output." % [_meter_bus, _peak]
			else:
				_status.text += " The %s channel stayed silent." % _meter_bus


## For tests: the status line.
func status_text() -> String:
	return _status.text
