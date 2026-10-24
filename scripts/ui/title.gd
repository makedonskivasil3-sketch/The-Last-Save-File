extends Control
## Title screen. Looks like an ordinary game's load menu, except the save
## slot shows what the owner has been doing to it.

const GAME_SCENE := "res://scenes/main.tscn"
const TITLE := "THE LAST SAVE FILE"

## The theme on the title (dB, Music bus).
const MUSIC_DB := -13.0

var _title: Label
var _menu: VBoxContainer
## The layer the menus live on (above the screen effects).
var _ui: Control
var _settings_box: VBoxContainer
var _settings: SettingsPanel
var _records_box: VBoxContainer
var _records: RecordsPanel
var _help_box: VBoxContainer
var _help: HowToPlayPanel
## The menu button that opened the page now showing (focus goes back to it).
var _opener: Button
var _credits_box: VBoxContainer
var _credits: CreditsPanel
var _journal_box: VBoxContainer
var _journal: JournalPanel
var _load: Button
var _rebuild_on_close := false
var _music: AudioStreamPlayer
## The first time: the menu isn't quite right.
var _whisper_t := 0.0
var _owner_line: Label
var _owner_typed := 0.0
## The small print under the menu, the controls line first (_fit_menu).
var _small_print: Array[Label] = []
var _menu_scroll: ScrollContainer


func _ready() -> void:
	Sfx.reset_scene_state()
	WebState.publish({"scene": "title", "playable": false})  # nothing muffled or ducked carries in from the run
	theme = UiStyle.make_theme()
	Sfx.prewarm()  # build the common sounds while the title is up
	($ScreenFX/Effect as ScreenFx).shake_world = false  # no world layer here
	get_tree().paused = false
	# The theme, as far as you remember it.
	# Built in the background if it isn't cached yet; it starts when ready.
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	# Above the drone: at -22 dB under it the theme was inaudible on laptop
	# and phone speakers (docs/AUDIO_DIAGNOSIS.md).
	_music.volume_db = MUSIC_DB
	add_child(_music)
	MusicBox.prewarm(MusicBox.held_level(OwnerMemory.fragments.size()))
	var touch := TouchControls.new()
	touch.buttons_enabled = false
	add_child(touch)

	add_child(TitleArt.new())

	# Menus sit above the screen effects (layer 10), like the in-game HUD:
	# the backdrop can tremble; the words you read never do.
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 15
	add_child(ui_layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(_ui)
	# Left column, title type large and flush left; the key art has the
	# right of the screen (scripts/fx/title_art.gd).
	_menu = UiStyle.side_panel(_ui, 268)
	# The column scrolls when it can't fit (large text, every button, a long
	# slot card): it follows keyboard and controller focus, so every button
	# stays reachable without shrinking anything (_fit_menu).
	var column := _menu.get_parent()
	_menu_scroll = ScrollContainer.new()
	_menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_menu_scroll.follow_focus = true
	column.remove_child(_menu)
	column.add_child(_menu_scroll)
	_menu_scroll.add_child(_menu)
	_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title = UiStyle.heading(_menu, TITLE, UiStyle.TEXT, 24)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# After the message ending, the tagline changes.
	var after: Array = _after()
	var tagline: String = after[0] if not after.is_empty() and OwnerMemory.wins > 0 else "you are not supposed to be here."
	UiStyle.note(_menu, tagline, UiStyle.OWNER).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_menu.add_child(_spacer(4))
	_build_slot_card()
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
	UiStyle.button(row, "Credits", _show_credits).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	_menu.add_child(row2)
	UiStyle.button(row2, "How to Play", _show_help).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if Settings.opening_seen:
		UiStyle.button(row2, "The Festival", _play_prologue.bind(true)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not OwnerMemory.journal.is_empty():
		UiStyle.button(row2, "Journal", _show_journal).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.button(row2, "Quit", func() -> void: OwnerMemory.quit_game()).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The small print, flush left under the menu.
	var phone := OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or Settings.using_touch
	var keys := "drag left side to move  ·  E to interact  ·  II pauses" if phone else "WASD / arrows to move  ·  E to interact  ·  Esc pauses"
	for line in [keys, "Flashing and glitch effects: reduce them in Settings."]:
		var small := UiStyle.note(_menu, line)
		small.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		UiStyle.sized(small, 9)
		_small_print.append(small)
	# Reflow, not shrink: with large text and every button there, the
	# controls line (also in How to Play) gives way first; the flashing
	# warning always stays.
	_fit_menu.call_deferred()
	Settings.changed.connect(func() -> void: _fit_menu.call_deferred())

	_settings_box = UiStyle.centered_panel(_ui, 480)
	_settings = SettingsPanel.new()
	_settings.show_reset = true
	_settings.closed.connect(_show_menu)
	# Rebuild so the slot card reflects the wiped memory.
	_settings.memory_wiped.connect(func() -> void: _rebuild_on_close = true)
	_settings_box.add_child(_settings)

	_records_box = UiStyle.centered_panel(_ui, 600)
	_records = RecordsPanel.new()
	_records.closed.connect(_show_menu)
	_records_box.add_child(_records)

	_help_box = UiStyle.centered_panel(_ui, 480)
	_help = HowToPlayPanel.new()
	_help.closed.connect(_show_menu)
	_help_box.add_child(_help)

	_credits_box = UiStyle.centered_panel(_ui, 520)
	_credits = CreditsPanel.new()
	_credits.closed.connect(_show_menu)
	_credits_box.add_child(_credits)

	_journal_box = UiStyle.centered_panel(_ui, 560)
	_journal = JournalPanel.new()
	_journal.closed.connect(_show_menu)
	_journal_box.add_child(_journal)

	_show_menu()


## Keeps the whole menu on screen: lines that are repeated elsewhere give
## way when the menu would be taller than the screen.
func _fit_menu() -> void:
	if not is_inside_tree() or _small_print.is_empty():
		return
	var panel := _menu_scroll.get_parent() as Control
	var box := panel.get_theme_stylebox("panel")
	var chrome := box.get_content_margin(SIDE_TOP) + box.get_content_margin(SIDE_BOTTOM) if box else 0.0
	var room := get_viewport_rect().size.y - 8.0 - chrome
	_small_print[0].visible = true
	if _menu.get_combined_minimum_size().y > room:
		_small_print[0].visible = false
	# Fits: the column is exactly its content. Doesn't: it is the screen's
	# height and scrolls.
	var need := _menu.get_combined_minimum_size().y
	_menu_scroll.custom_minimum_size = Vector2(_menu.get_combined_minimum_size().x, minf(need, room))
	_menu_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if need > room else ScrollContainer.SCROLL_MODE_DISABLED
	panel.reset_size()


func _process(delta: float) -> void:
	_update_whispers(delta)
	if not _music.playing:
		var key := "theme_%d_normal" % MusicBox.held_level(OwnerMemory.fragments.size())
		if OwnerMemory.runtime_cache.has(key):
			_music.stream = OwnerMemory.runtime_cache[key]
			_music.play()
	# The title glitches more the further the purge has gone.
	var chance := (0.01 + OwnerMemory.purge * 0.02) * Settings.flash_scale()
	if randf() < 1.0 - pow(1.0 - clampf(chance, 0.0, 1.0), delta * 60.0):
		var i := randi() % TITLE.length()
		_title.text = TITLE.substr(0, i) + ["#", "_", "?", "0"].pick_random() + TITLE.substr(i + 1)
	elif _title.text != TITLE and randf() < 1.0 - pow(0.8, delta * 60.0):
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


## The title's aftermath for the last ending (old saves: the escape, or
## RUE's if every memory is found; RUE's also once Rue knows the truth).
## The last ending achieved, as it was achieved: learning the truth later
## doesn't turn an old escape into RUE. Only a save from before endings were
## recorded by name (wins but no last_ending) is read as an escape.
static func _after() -> Array:
	var ending := OwnerMemory.last_ending
	if ending == "" and OwnerMemory.wins > 0:
		ending = "escape"
	return Story.TITLE_AFTER.get(ending, [])


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

	# What's in slot 2 (and sometimes slot 1) depends on the last ending.
	var after: Array = _after()
	if OwnerMemory.wins > 0 and not after.is_empty() and after[1] != "":
		var two := Label.new()
		two.text = after[1]
		# The slot's name is what she remembers now (progress), not a
		# different ending: an escape stays an escape, with her name on it
		# once she has it back.
		if OwnerMemory.fragments.size() >= Story.FRAGMENTS.size():
			two.text = two.text.replace("???", Story.SECOND_PLAYER_NAME)
		two.add_theme_font_size_override("font_size", 10)
		two.add_theme_color_override("font_color", after[2])
		v.add_child(two)
	if OwnerMemory.last_ending == "overwrite" and OwnerMemory.wins > 0:
		line.text = "SLOT 1   ·   ARIN?   ·   LV 7   ·   14:22:00"

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
			var after: Array = _after()
			parts.append(after[3] if not after.is_empty() else "something was written to slot 2.")
	if OwnerMemory.purge > 0:
		parts.append("[!] purge %d/%d" % [OwnerMemory.purge, OwnerMemory.MAX_PURGE])
	return "   ·   ".join(parts)


func _start() -> void:
	# Deferred: on touch screens the tap that pressed the button is still being
	# delivered (as an emulated mouse event) when this runs.
	# The first time, the opening film plays before the run (no run starts
	# until it has ended or been skipped).
	if Prologue.wanted():
		_play_prologue(false)
		return
	get_tree().change_scene_to_file.call_deferred(GAME_SCENE)


## The festival (Prologue): before the first run, or replayed from the menu.
func _play_prologue(replay: bool) -> void:
	var festival := Prologue.new()
	festival.replay = replay
	var swap := func() -> void:
		var old := get_tree().current_scene
		get_tree().root.add_child(festival)
		get_tree().current_scene = festival
		old.queue_free()
	swap.call_deferred()


## The earlier opening film (the TV and the hands). Off the first-run path
## since the festival (docs/INTRO_REBUILD.md, author question Q3); kept for
## its tests until the author decides.
func _play_opening(replay: bool) -> void:
	var film := Opening.new()
	film.replay = replay
	var swap := func() -> void:
		var old := get_tree().current_scene
		get_tree().root.add_child(film)
		get_tree().current_scene = film
		old.queue_free()
	swap.call_deferred()


func _show_menu() -> void:
	if _rebuild_on_close:
		get_tree().reload_current_scene.call_deferred()
		return
	_panel_of(_menu).visible = true
	_panel_of(_settings_box).visible = false
	_panel_of(_records_box).visible = false
	_panel_of(_help_box).visible = false
	_panel_of(_credits_box).visible = false
	_panel_of(_journal_box).visible = false
	# Back from a page: focus returns to the button that opened it.
	if is_instance_valid(_opener) and _opener.is_visible_in_tree():
		_opener.grab_focus()
	else:
		_load.grab_focus()
	_opener = null


## Leaving the menu for a page: remember the button that opened it.
func _leave_menu() -> void:
	var f := get_viewport().gui_get_focus_owner()
	if f is Button and _menu.is_ancestor_of(f):
		_opener = f
	_panel_of(_menu).visible = false


func _show_records() -> void:
	_leave_menu()
	_panel_of(_records_box).visible = true
	_records.focus_first()


func _show_credits() -> void:
	_leave_menu()
	_panel_of(_credits_box).visible = true
	_credits.focus_first()


func _show_journal() -> void:
	_leave_menu()
	_journal.refresh()
	_panel_of(_journal_box).visible = true
	_journal.focus_first.call_deferred()


func _show_help() -> void:
	_leave_menu()
	_panel_of(_help_box).visible = true
	_help.focus_first()


func _show_settings() -> void:
	_leave_menu()
	_panel_of(_records_box).visible = false
	_panel_of(_settings_box).visible = true
	_settings.focus_first()


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c


func _panel_of(box: VBoxContainer) -> Control:
	return box.get_parent().get_parent() as Control
