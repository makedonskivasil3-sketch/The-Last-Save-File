class_name PauseMenu
extends CanvasLayer
## Esc / Start during play. Quitting from here still counts against you,
## so the menu says so before letting you go. Save and exit doesn't: it is
## only offered at a safe moment (World.suspend_blocker).

signal quit_requested(to_title: bool)
## Save and exit (World.try_suspend): returns "" once the save is on disk,
## otherwise why it isn't, and then the menu stays up and says so.
var suspend_handler: Callable
## World.problem_report: the text for "Report a problem".
var report_provider: Callable
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
var build_label: Label
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
var _help_box: VBoxContainer
var _help: HowToPlayPanel
## The main-page button that opened the page now showing (focus goes back to it).
var _opener: Button
## Set by World before open(): show the Debug button.
var debug_available := false
var _resume: Button
var _pending_to_title := false
var _confirm_label: Label
var _goal_label: Label
var _suspend: Button
var _suspend_note: Label
var _save_failed: VBoxContainer
var _save_failed_label: Label
## Set by World before open(): why Save and exit can't happen now, or "".
var suspend_blocked := ""
## Shown under the title: what to do next (set by World before open()).
var goal := ""
## For the map (set by World before open(), World.map_state()): current
## area id, places visited this run, places found in any run, closed ones.
var current_area := ""
var visited_areas: Dictionary = {}
var discovered_areas: Dictionary = {}
var closed_areas: Dictionary = {}


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
	# Pausing is safe; only quitting ends the run (and counts).
	UiStyle.note(_main, "nothing moves until you resume. the owner waits.", UiStyle.MUTED)
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
	UiStyle.button(actions, "How to Play", _show_help)
	if PlaytestLog.enabled():
		UiStyle.button(actions, "Playtest log", _show_playtest_log)
	_suspend = UiStyle.button(actions, "Save and exit", _do_suspend)
	UiStyle.button(actions, "Quit to title", _ask_quit.bind(true))
	UiStyle.button(actions, "Quit game", _ask_quit.bind(false))

	_suspend_note = UiStyle.note(_main, "", UiStyle.MUTED)

	# A save that didn't reach the disk: nothing was lost, and the run waits.
	_save_failed = UiStyle.centered_panel(_root, 300)
	UiStyle.heading(_save_failed, "NOT SAVED", UiStyle.OWNER)
	_save_failed_label = UiStyle.note(_save_failed, "", UiStyle.TEXT)
	UiStyle.button(_save_failed, "Retry", _do_suspend)
	UiStyle.button(_save_failed, "Return to game", close, "ui_back")

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
	# Which build, and a way to tell the author what went wrong (the report
	# carries these lines with it).
	build_label = UiStyle.note(_history_box, BuildInfo.stamp(), UiStyle.MUTED)
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
	UiStyle.button(navigation, "Report a problem", _show_report)
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

	_help_box = UiStyle.centered_panel(_root, 480)
	_help = HowToPlayPanel.new()
	_help.closed.connect(_show_main)
	_help_box.add_child(_help)

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
	_suspend.disabled = suspend_blocked != ""
	_suspend_note.text = ("save and exit: " + suspend_blocked) if suspend_blocked != "" \
		else "save and exit: you'll pick up here, though people and things may have moved on. nothing is counted."
	Sfx.ui("pause")
	Sfx.muffle(true)
	_show_main()


func close() -> void:
	VoiceOver.stop_preview()  # a replay from the History page ends with the menu
	visible = false
	get_tree().paused = false
	Sfx.muffle(false)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _panel_of(_settings_box).visible or _panel_of(_journal_box).visible or _panel_of(_help_box).visible:
		return  # these panels handle their own back
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _panel_of(_confirm).visible or _panel_of(_map_box).visible or _panel_of(_debug_box).visible or _panel_of(_log_box).visible or _panel_of(_history_box).visible:
			_show_main()
		else:
			close()


func _show_only(box: VBoxContainer) -> void:
	# Leaving the main page: remember which button opened the page, to come back to it.
	var owner_now := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if box != _main and _panel_of(_main).visible and owner_now is Button and _main.is_ancestor_of(owner_now):
		_opener = owner_now
	for b in [_main, _confirm, _save_failed, _settings_box, _map_box, _debug_box, _log_box, _history_box, _journal_box, _help_box]:
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
	PlaytestLog.mark("journal opened")
	_journal.refresh()
	_show_only(_journal_box)
	_journal.focus_first.call_deferred()


## "Report a problem": the facts the author needs, shown and copied. It goes
## nowhere by itself (docs/prompts/NEXT_PASS_2026-10-29.md §3).
func _show_report() -> void:
	var text: String = report_provider.call() if report_provider.is_valid() else BuildInfo.stamp()
	last_report = text
	DisplayServer.clipboard_set(text)
	_log_text.text = "COPIED. Paste it into your message to the author, with what you were doing. Nothing is sent from the game.\n\n" + text
	_show_only(_log_box)
	_log_back.grab_focus()


var last_report := ""


func _show_playtest_log() -> void:
	_log_text.text = "\n".join(PlaytestLog.lines) if not PlaytestLog.lines.is_empty() else "(nothing yet)"
	_show_only(_log_box)
	_log_back.grab_focus()


func _show_main() -> void:
	_show_only(_main)
	_debug_button.visible = debug_available
	# Back from a page: focus returns to the button that opened it.
	if is_instance_valid(_opener) and _opener.is_visible_in_tree():
		_opener.grab_focus()
	else:
		_resume.grab_focus()
	_opener = null


func _debug(action: String) -> void:
	close()
	debug_requested.emit(action)


func _show_map() -> void:
	_map.current = current_area
	_map.visited = visited_areas
	_map.discovered = discovered_areas
	_map.closed = closed_areas
	_show_only(_map_box)
	_map_back.grab_focus()


func _show_help() -> void:
	_show_only(_help_box)
	_help.focus_first()


func _show_settings() -> void:
	_show_only(_settings_box)
	_settings.focus_first()


func _ask_quit(to_title: bool) -> void:
	_pending_to_title = to_title
	if suspend_blocked == "":
		# A calm moment: quitting keeps her place and counts nothing.
		_confirm_label.text = "It's calm: quitting now keeps your place, like Save and exit. Nothing is counted.\nNext time you'll pick up here, though people and things may have moved on."
		_show_only(_confirm)
		(_confirm.get_child(2) as Button).grab_focus()  # "Stay"
		return
	var after := OwnerMemory.purge + 1
	var consequence := "Purge progress will rise to %d/%d." % [after, OwnerMemory.MAX_PURGE]
	if after >= OwnerMemory.MAX_PURGE:
		consequence = "This finishes the purge. You'll be gone."
	elif after == OwnerMemory.MAX_PURGE - 1:
		consequence += " One more and you're gone."
	# Pausing is free; this ends the run. Say what is kept and what it costs.
	_confirm_label.text = "This ends the run. Quitting counts, like dying: the owner will remember.\n" + consequence \
		+ "\nKept: your memories, glitches, journal and everyone you've met. Lost: anything you're carrying." \
		+ ("\nYou'll start in Arin's room: the well only keeps you after a death." if World.anchor_valid() else "") \
		+ ("\nResume instead (or Save and exit), and nothing is counted." if suspend_blocked == "" else "\nResume instead, and nothing is counted.")
	_show_only(_confirm)
	(_confirm.get_child(2) as Button).grab_focus()  # "Stay"


func _do_suspend() -> void:
	if suspend_blocked != "" or not suspend_handler.is_valid():
		return
	var why: String = suspend_handler.call(true)
	if why == "":
		close()
		return
	# Still paused, still in the run: say what happened and offer the way on.
	_save_failed_label.text = "Your run wasn't saved: %s\nNothing was lost: your last save is as it was, and the run is still open.\nRetry, or return to the game and keep playing." % why
	_show_only(_save_failed)
	(_save_failed.get_child(2) as Button).grab_focus()  # "Retry"


func _do_quit() -> void:
	if suspend_blocked == "" and suspend_handler.is_valid():
		var why: String = suspend_handler.call(_pending_to_title)
		if why == "":
			close()
			return
		_save_failed_label.text = "Your run wasn't saved: %s\nNothing was lost: your last save is as it was, and the run is still open.\nRetry, or return to the game and keep playing." % why
		_show_only(_save_failed)
		(_save_failed.get_child(2) as Button).grab_focus()
		return
	close()
	quit_requested.emit(_pending_to_title)


## centered_panel() returns the VBox inside PanelContainer inside CenterContainer.
func _panel_of(box: VBoxContainer) -> Control:
	var parent := box.get_parent()
	while not parent is CenterContainer:
		parent = parent.get_parent()
	return parent as Control
