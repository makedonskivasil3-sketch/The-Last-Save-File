class_name PauseMenu
extends CanvasLayer
## Esc / Start during play. Quitting from here still counts against you,
## so the menu says so before letting you go.

signal quit_requested(to_title: bool)
## A debug tool was picked (World.debug()).
signal debug_requested(action: String)

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

	_main = UiStyle.centered_panel(_root, 260)
	UiStyle.heading(_main, "PAUSED", UiStyle.TEXT)
	UiStyle.note(_main, "the owner is still here.", UiStyle.OWNER)
	_goal_label = UiStyle.note(_main, "", UiStyle.TEXT)
	_resume = UiStyle.button(_main, "Resume", close, "ui_back")
	UiStyle.button(_main, "Map", _show_map)
	UiStyle.button(_main, "Journal", _show_journal)
	_debug_button = UiStyle.button(_main, "Debug", func() -> void: _show_only(_debug_box); (_debug_box.get_child(1) as Button).grab_focus())
	UiStyle.button(_main, "Settings", _show_settings)
	if PlaytestLog.enabled():
		UiStyle.button(_main, "Playtest log", _show_playtest_log)
	UiStyle.button(_main, "Quit to title", _ask_quit.bind(true))
	UiStyle.button(_main, "Quit game", _ask_quit.bind(false))

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
	visible = false
	get_tree().paused = false
	Sfx.muffle(false)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _panel_of(_settings_box).visible or _panel_of(_journal_box).visible:
		return  # the settings panel handles its own back
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _panel_of(_confirm).visible or _panel_of(_map_box).visible or _panel_of(_debug_box).visible or _panel_of(_log_box).visible:
			_show_main()
		else:
			close()


func _show_only(box: VBoxContainer) -> void:
	for b in [_main, _confirm, _settings_box, _map_box, _debug_box, _log_box, _journal_box]:
		_panel_of(b).visible = b == box


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
	return box.get_parent().get_parent() as Control
