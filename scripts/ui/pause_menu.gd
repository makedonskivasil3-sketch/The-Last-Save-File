class_name PauseMenu
extends CanvasLayer
## Esc / Start during play. Quitting from here still counts against you,
## so the menu says so before letting you go.

signal quit_requested(to_title: bool)

var _root: Control
var _main: VBoxContainer
var _confirm: VBoxContainer
var _settings_box: VBoxContainer
var _settings: SettingsPanel
var _resume: Button
var _pending_to_title := false
var _confirm_label: Label
var _goal_label: Label
## Shown under the title: what to do next (set by World before open()).
var goal := ""


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
	UiStyle.button(_main, "Settings", _show_settings)
	UiStyle.button(_main, "Quit to title", _ask_quit.bind(true))
	UiStyle.button(_main, "Quit game", _ask_quit.bind(false))

	_confirm = UiStyle.centered_panel(_root, 260)
	UiStyle.heading(_confirm, "QUIT?", UiStyle.OWNER)
	_confirm_label = UiStyle.note(_confirm, "", UiStyle.TEXT)
	UiStyle.button(_confirm, "Stay", _show_main, "ui_back")
	UiStyle.button(_confirm, "Quit anyway", _do_quit)

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
	if not visible or _panel_of(_settings_box).visible:
		return  # the settings panel handles its own back
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _panel_of(_confirm).visible:
			_show_main()
		else:
			close()


func _show_only(box: VBoxContainer) -> void:
	for b in [_main, _confirm, _settings_box]:
		_panel_of(b).visible = b == box


func _show_main() -> void:
	_show_only(_main)
	_resume.grab_focus()


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
