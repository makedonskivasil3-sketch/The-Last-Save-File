class_name PauseMenu
extends CanvasLayer
## Esc / Start during play. Quitting from here still counts against you,
## so the menu says so before letting you go.

signal quit_requested(to_title: bool)
## A debug tool was picked (World.debug()).
signal debug_requested(action: String)

## Session console history, available without playtest mode.
var _history_box: VBoxContainer
var _replay_row: HBoxContainer
## How many recorded lines get a replay button on the History page.
const REPLAY_BUTTONS := 3
var _history_text: RichTextLabel
var _history_back: Button
var console_hud: Hud
## The playtest log page (PlaytestLog, only with ?playtest=1 / --playtest).
var _log_box: VBoxContainer
var _log_text: Label
var _log_back: Button
var _root: Control
var _main: VBoxContainer
var _confirm: VBoxContainer
var _settings_box: VBoxContainer
var _settings: SettingsPanel
var _map_box: VBoxContainer
var _map: MapView
var _map_back: Button
var _journal_box: VBoxContainer
var _journal: JournalPanel
var _debug_box: VBoxContainer
var _debug_button: Button
## Set by World before open(): show the Debug button.
var debug_available := false
var _resume: Button
var _pending_to_title := false
var _confirm_label: Label
var _goal_label: Label
## Shown under the title: what to do next (set by World before open()).
var goal := ""
## For the map (set by World before open()): current area id, areas visited.
var current_area := ""
var visited_areas: Dictionary = {}


func _ready() -> void:
	layer = 20  # above the screen shader, so menus stay crisp
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiStyle.make_theme()
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.6)
	_root.add_child(dim)

	_main = UiStyle.centered_panel(_root, 380)
	UiStyle.heading(_main, "PAUSED", UiStyle.TEXT)
	UiStyle.note(_main, "the owner is still here.", UiStyle.OWNER)
	_goal_label = UiStyle.note(_main, "", UiStyle.TEXT)
	var actions := GridContainer.new()
	actions.columns = 2
	_main.add_child(actions)
	_resume = UiStyle.button(actions, "Resume", close, "ui_back")
	UiStyle.button(actions, "Map", _show_map)
	UiStyle.button(actions, "Journal", _show_journal)
	UiStyle.button(actions, "History", _show_history)
	_debug_button = UiStyle.button(actions, "Debug", func() -> void: _show_only(_debug_box); (_debug_box.get_child(1) as Button).grab_focus())
	UiStyle.button(actions, "Settings", _show_settings)
	if PlaytestLog.enabled():
		UiStyle.button(actions, "Playtest log", _show_playtest_log)
	UiStyle.button(actions, "Quit to title", _ask_quit.bind(true))
	UiStyle.button(actions, "Quit game", _ask_quit.bind(false))

	_confirm = UiStyle.centered_panel(_root, 260)
	UiStyle.heading(_confirm, "QUIT?", UiStyle.OWNER)
	_confirm_label = UiStyle.note(_confirm, "", UiStyle.TEXT)
	UiStyle.button(_confirm, "Stay", _show_main, "ui_back")
	UiStyle.button(_confirm, "Quit anyway", _do_quit)

	_log_box = UiStyle.centered_panel(_root, 460)
	UiStyle.heading(_log_box, "PLAYTEST LOG", UiStyle.TEXT, 14)
	var log_scroll := ScrollContainer.new()
	log_scroll.custom_minimum_size = Vector2(440, 200)
	_log_box.add_child(log_scroll)
	_log_text = UiStyle.note(log_scroll, "", UiStyle.TEXT)
	_log_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_log_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.button(_log_box, "Copy to clipboard", func() -> void: DisplayServer.clipboard_set("\n".join(PlaytestLog.lines)))
	_log_back = UiStyle.button(_log_box, "Back", _show_main, "ui_back")

	_history_box = UiStyle.centered_panel(_root, 480)
	UiStyle.heading(_history_box, "HISTORY", UiStyle.TEXT, 14)
	UiStyle.note(_history_box, "Everything said this run: dialogue, scenes and the console", UiStyle.MUTED)
	_history_text = RichTextLabel.new()
	_history_text.custom_minimum_size = Vector2(440, 120)
	_history_text.bbcode_enabled = false
	_history_text.selection_enabled = true
	_history_text.focus_mode = Control.FOCUS_ALL
	UiStyle.sized(_history_text, 11)
	_history_box.add_child(_history_text)
	# Lines with a recording can be heard again (newest first).
	_replay_row = HBoxContainer.new()
	_replay_row.add_theme_constant_override("separation", 4)
	_history_box.add_child(_replay_row)
	var navigation := HBoxContainer.new()
	_history_box.add_child(navigation)
	UiStyle.button(navigation, "Older ↑", _scroll_history.bind(-120.0))
	UiStyle.button(navigation, "Newer ↓", _scroll_history.bind(120.0))
	_history_back = UiStyle.button(navigation, "Back", _show_main, "ui_back")

	_map_box = UiStyle.centered_panel(_root, 420)
	UiStyle.heading(_map_box, "MAP", UiStyle.TEXT, 14)
	_map = MapView.new()
	_map.custom_minimum_size = Vector2(400, 170)
	_map_box.add_child(_map)
	_map_back = UiStyle.button(_map_box, "Back", _show_main, "ui_back")

	_debug_box = UiStyle.centered_panel(_root, 260)
	UiStyle.heading(_debug_box, "DEBUG", UiStyle.OWNER, 14)
	for pair in [["Unlock all glitches", "glitches"], ["Owner: load last save", "load"], ["Owner: save over you", "save"],
			["Owner: drag the crates", "drag"], ["Wren joins you", "wren"], ["Jump to Slot 2", "slot2"], ["Show frame times", "perf"]]:
		UiStyle.button(_debug_box, pair[0], _debug.bind(pair[1]))
	UiStyle.button(_debug_box, "Back", _show_main, "ui_back")

	_journal_box = UiStyle.centered_panel(_root, 560)
	_journal = JournalPanel.new()
	_journal.closed.connect(_show_main)
	_journal_box.add_child(_journal)

	_settings_box = UiStyle.centered_panel(_root, 480)
	_settings = SettingsPanel.new()
	_settings.closed.connect(_show_main)
	_settings_box.add_child(_settings)


func open() -> void:
	if visible:
		return
	visible = true
	get_tree().paused = true
	_goal_label.text = goal
	_goal_label.visible = goal != ""
	Sfx.ui("pause")
	Sfx.muffle(true)
	_show_main()


func close() -> void:
	VoiceOver.stop_preview()  # a replay from the History page ends with the menu
	visible = false
	get_tree().paused = false
	Sfx.muffle(false)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _panel_of(_settings_box).visible or _panel_of(_journal_box).visible:
		return  # the settings panel handles its own back
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _panel_of(_confirm).visible or _panel_of(_map_box).visible or _panel_of(_debug_box).visible or _panel_of(_log_box).visible or _panel_of(_history_box).visible:
			_show_main()
		else:
			close()


func _show_only(box: VBoxContainer) -> void:
	for b in [_main, _confirm, _settings_box, _map_box, _debug_box, _log_box, _history_box, _journal_box]:
		_panel_of(b).visible = b == box


func _show_history() -> void:
	_history_text.text = history_text(console_hud.history if console_hud else [])
	_build_replay_buttons()
	_show_only(_history_box)
	_history_text.scroll_to_line(0)
	_history_back.grab_focus()
	PlaytestLog.mark("console history opened")


## The history as readable text: "SPEAKER  line", one entry per paragraph.
## Speaker labels follow Settings.speaker_labels.
static func history_text(entries: Array) -> String:
	if entries.is_empty():
		return "(nothing yet)"
	var out: PackedStringArray = []
	for e in entries:
		var text: String = e.text
		match e.kind:
			"owner":
				text = "> " + text
			"self":
				text = "(%s)" % text
		var who: String = e.speaker
		out.append("%s  %s" % [who, text] if Settings.speaker_labels and who != "" else text)
	return "\n\n".join(out)


func _build_replay_buttons() -> void:
	for c in _replay_row.get_children():
		c.queue_free()
	var shown := 0
	var entries: Array = console_hud.history if console_hud else []
	for i in range(entries.size() - 1, -1, -1):
		var e: Dictionary = entries[i]
		if e.voice == "" or not VoiceOver.has_line(e.voice) or shown >= REPLAY_BUTTONS:
			continue
		var label := "▶ %s" % (e.speaker if e.speaker != "" else "line")
		var b := UiStyle.button(_replay_row, label, func() -> void: VoiceOver.preview(self, e.voice))
		b.tooltip_text = e.text
		shown += 1
	_replay_row.visible = shown > 0


func _scroll_history(amount: float) -> void:
	var bar := _history_text.get_v_scroll_bar()
	bar.value += amount


func _show_journal() -> void:
	_journal.refresh()
	_show_only(_journal_box)
	_journal.focus_first.call_deferred()


func _show_playtest_log() -> void:
	_log_text.text = "\n".join(PlaytestLog.lines) if not PlaytestLog.lines.is_empty() else "(nothing yet)"
	_show_only(_log_box)
	_log_back.grab_focus()


func _show_main() -> void:
	_show_only(_main)
	_debug_button.visible = debug_available
	_resume.grab_focus()


func _debug(action: String) -> void:
	close()
	debug_requested.emit(action)


func _show_map() -> void:
	_map.current = current_area
	_map.visited = visited_areas
	_show_only(_map_box)
	_map_back.grab_focus()


func _show_settings() -> void:
	_show_only(_settings_box)
	_settings.focus_first()


func _ask_quit(to_title: bool) -> void:
	_pending_to_title = to_title
	var after := OwnerMemory.purge + 1
	var consequence := "Purge progress will rise to %d/%d." % [after, OwnerMemory.MAX_PURGE]
	if after >= OwnerMemory.MAX_PURGE:
		consequence = "This finishes the purge. You'll be gone."
	elif after == OwnerMemory.MAX_PURGE - 1:
		consequence += " One more and you're gone."
	_confirm_label.text = "Quitting counts. The owner will remember.\n" + consequence
	_show_only(_confirm)
	(_confirm.get_child(2) as Button).grab_focus()  # "Stay"


func _do_quit() -> void:
	close()
	quit_requested.emit(_pending_to_title)


## centered_panel() returns the VBox inside PanelContainer inside CenterContainer.
func _panel_of(box: VBoxContainer) -> Control:
	var parent := box.get_parent()
	while not parent is CenterContainer:
		parent = parent.get_parent()
	return parent as Control
