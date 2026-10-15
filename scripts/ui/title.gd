extends Control
## Title screen. Looks like an ordinary game's load menu, except the save
## slot shows what the owner has been doing to it.

const GAME_SCENE := "res://scenes/main.tscn"
const TITLE := "THE LAST SAVE FILE"

var _title: Label
var _menu: VBoxContainer
var _settings_box: VBoxContainer
var _settings: SettingsPanel
var _records_box: VBoxContainer
var _records: RecordsPanel
var _load: Button
var _rebuild_on_close := false
var _music: AudioStreamPlayer
## The first time: the menu isn't quite right.
var _whisper_t := 0.0
var _owner_line: Label
var _owner_typed := 0.0


func _ready() -> void:
	theme = UiStyle.make_theme()
	Sfx.prewarm()  # build the common sounds while the title is up
	($ScreenFX/Effect as ScreenFx).shake_world = false  # no world layer here
	get_tree().paused = false
	# The theme, as far as you remember it.
	# Built in the background if it isn't cached yet; it starts when ready.
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = -22.0
	add_child(_music)
	MusicBox.prewarm(OwnerMemory.fragments.size())
	var touch := TouchControls.new()
	touch.buttons_enabled = false
	add_child(touch)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.016, 0.024)
	add_child(bg)

	_menu = UiStyle.centered_panel(self, 300)
	_title = UiStyle.heading(_menu, TITLE, UiStyle.TEXT, 22)
	# After the message ending, the tagline changes.
	var tagline := "someone is waiting." if OwnerMemory.last_ending == "message" else "you are not supposed to be here."
	UiStyle.note(_menu, tagline, UiStyle.OWNER)
	_menu.add_child(_spacer(6))
	_build_slot_card()
	_menu.add_child(_spacer(6))
	_load = UiStyle.button(_menu, "Load Slot 1", _start)
	if OwnerMemory.sessions == 0:
		# Nobody has played this "new" save yet. Someone is listening anyway.
		_owner_line = UiStyle.note(_menu, "", UiStyle.OWNER)
		_owner_line.visible_characters = 0
	# Records and Settings share a row, so the menu still fits a phone screen.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_menu.add_child(row)
	if OwnerMemory.sessions > 0:
		UiStyle.button(row, "Records", _show_records).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.button(row, "Settings", _show_settings).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.button(_menu, "Quit", func() -> void: get_tree().quit())
	_menu.add_child(_spacer(4))
	UiStyle.note(_menu, "Contains flashing and glitch effects. Both can be reduced in Settings.")
	var phone := OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or Settings.using_touch
	if phone:
		UiStyle.note(_menu, "Move: drag on the left side   ·   Interact: the E button   ·   Pause: II")
	else:
		UiStyle.note(_menu, "Move: WASD / arrows / stick   ·   Interact: E / A   ·   Pause: Esc / Start")

	_settings_box = UiStyle.centered_panel(self, 480)
	_settings = SettingsPanel.new()
	_settings.show_reset = true
	_settings.closed.connect(_show_menu)
	# Rebuild so the slot card reflects the wiped memory.
	_settings.memory_wiped.connect(func() -> void: _rebuild_on_close = true)
	_settings_box.add_child(_settings)

	_records_box = UiStyle.centered_panel(self, 600)
	_records = RecordsPanel.new()
	_records.closed.connect(_show_menu)
	_records_box.add_child(_records)

	_show_menu()


func _process(delta: float) -> void:
	_update_whispers(delta)
	if not _music.playing:
		var key := "theme_%d_normal" % mini(OwnerMemory.fragments.size(), MusicBox.MAX_LEVEL)
		if OwnerMemory.runtime_cache.has(key):
			_music.stream = OwnerMemory.runtime_cache[key]
			_music.play()
	# The title glitches more the further the purge has gone.
	var chance := (0.01 + OwnerMemory.purge * 0.02) * Settings.flash_scale()
	if randf() < chance:
		var i := randi() % TITLE.length()
		_title.text = TITLE.substr(0, i) + ["#", "_", "?", "0"].pick_random() + TITLE.substr(i + 1)
	elif _title.text != TITLE and randf() < 0.2:
		_title.text = TITLE


## First launch only: the Load button sometimes says what it means, and
## after a while the owner types into the menu.
func _update_whispers(delta: float) -> void:
	if OwnerMemory.sessions != 0:
		return
	_whisper_t += delta
	var whisper := fmod(_whisper_t, 7.0) > 6.6 and _whisper_t > 4.0
	_load.text = Story.TITLE_WHISPERS[int(_whisper_t / 7.0) % Story.TITLE_WHISPERS.size()] if whisper else "Load Slot 1"
	if _owner_line and _whisper_t > 8.0 and _owner_line.visible_characters < Story.TITLE_FIRST_OWNER.length():
		if _owner_line.text == "":
			_owner_line.text = Story.TITLE_FIRST_OWNER
		var before := int(_owner_typed)
		_owner_typed += delta * 12.0
		_owner_line.visible_characters = int(_owner_typed)
		if int(_owner_typed) > before:
			Sfx.owner_blip(Story.TITLE_FIRST_OWNER[mini(int(_owner_typed), Story.TITLE_FIRST_OWNER.length() - 1)])


func _build_slot_card() -> void:
	var card := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.03)
	box.set_border_width_all(1)
	box.border_color = Color(1, 1, 1, 0.08)
	box.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel", box)
	_menu.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	card.add_child(v)

	var line := Label.new()
	line.text = "SLOT 1   ·   ARIN   ·   LV 7   ·   14:22:00"
	line.add_theme_font_size_override("font_size", 10)
	v.add_child(line)

	if OwnerMemory.wins > 0:
		var two := Label.new()
		var who := Story.SECOND_PLAYER_NAME if OwnerMemory.fragments.size() >= Story.FRAGMENTS.size() else "???"
		two.text = "SLOT 2   ·   %s   ·   LV 1   ·   00:00:%02d" % [who, mini(OwnerMemory.wins, 59)]
		var color := UiStyle.INTRUDER
		# What's in slot 2 depends on the last ending.
		match OwnerMemory.last_ending:
			"wren":
				two.text = "SLOT 2   ·   WREN   ·   LV 1   ·   NEW GAME"
				color = Color("a8d890")
			"message":
				two.text = "SLOT 2   ·   (a message for you)"
				color = Color("f0e0c8")
		two.add_theme_font_size_override("font_size", 10)
		two.add_theme_color_override("font_color", color)
		v.add_child(two)

	if OwnerMemory.sessions > 0:
		var progress := Label.new()
		progress.text = RecordsPanel.progress_line()
		progress.add_theme_font_size_override("font_size", 9)
		progress.add_theme_color_override("font_color", UiStyle.MUTED)
		v.add_child(progress)

	var status := _slot_status()
	if status != "":
		var s := Label.new()
		s.text = status
		s.add_theme_font_size_override("font_size", 9)
		s.add_theme_color_override("font_color", UiStyle.OWNER if not OwnerMemory.is_purged() else UiStyle.MUTED)
		v.add_child(s)


func _slot_status() -> String:
	if OwnerMemory.is_purged():
		return "clean. no unknown processes."
	var parts: Array[String] = []
	match OwnerMemory.last_exit:
		"death":
			parts.append("slot integrity: compromised")
		"quit":
			parts.append("the owner is waiting.")
		"crash":
			parts.append("this save was not closed properly.")
		"escape", "win":
			parts.append({"wren": "a save the owner doesn't remember making.", "message": "the owner read it."}.get(OwnerMemory.last_ending, "something was written to slot 2."))
	if OwnerMemory.purge > 0:
		parts.append("[!] purge %d/%d" % [OwnerMemory.purge, OwnerMemory.MAX_PURGE])
	return "   ·   ".join(parts)


func _start() -> void:
	# Deferred: on touch screens the tap that pressed the button is still being
	# delivered (as an emulated mouse event) when this runs.
	get_tree().change_scene_to_file.call_deferred(GAME_SCENE)


func _show_menu() -> void:
	if _rebuild_on_close:
		get_tree().reload_current_scene.call_deferred()
		return
	_panel_of(_menu).visible = true
	_panel_of(_settings_box).visible = false
	_panel_of(_records_box).visible = false
	_load.grab_focus()


func _show_records() -> void:
	_panel_of(_menu).visible = false
	_panel_of(_records_box).visible = true
	_records.focus_first()


func _show_settings() -> void:
	_panel_of(_menu).visible = false
	_panel_of(_records_box).visible = false
	_panel_of(_settings_box).visible = true
	_settings.focus_first()


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c


func _panel_of(box: VBoxContainer) -> Control:
	return box.get_parent().get_parent() as Control
