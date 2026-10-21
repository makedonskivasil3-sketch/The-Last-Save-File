class_name Hud
extends CanvasLayer
## The save file's own UI, plus a console the owner types into, a dialogue
## box for characters, area title cards and screen fades.

signal dialogue_closed
## A line of the open conversation has been shown whole (its last page is on
## screen). Carries the line as written, before it was split into pages.
signal line_shown(line: String)
## choose() picked an option (index).
signal _chosen(index: int)

## A choice ignores input for this long after it appears, so a press still
## mashing through the dialogue can't pick an answer (or an ending) by accident.
const CHOICE_GRACE_MS := 450
var _choice_ready_ms := 0

const OWNER_COLOR := Color("e0704f")
const SYSTEM_COLOR := Color("8a8f98")
const NPC_COLOR := Color("e8c48a")
## The intruder's own thoughts.
const SELF_COLOR := Color("8cf2ff")
## The speaker portrait beside dialogue (PortraitView), in game pixels.
const PORTRAIT_SIZE := 50.0
const SLOT_COLOR := Color("c8b8a0")
## Lines kept in the console (one fewer with large text, so it still fits).
const MAX_LINES := 4
const MAX_HISTORY := 200
## Full console messages that have started appearing, never queued spoilers.
var console_history: Array[String] = []
## Keep text this far from the screen edges: the curved CRT glass and its
## bezel eat the corners.
const SAFE := Vector2(14, 10)
## The tallest the dialogue box may grow (logical px): its pages are sized to fit.
const DIALOGUE_MAX_H := 132.0
const STATUS_COLOR := Color("8cf2ff")
const TYPE_SPEED := 36.0  # characters per second (console), x Settings.text_rate()
const DIALOGUE_SPEED := 55.0  # characters per second (dialogue box), x pace x text_rate()

## The owner's character. Not you.
var character_name := "ARIN"
var unknown_processes := 0

var narrator: Narration

var _slot: Label
var _meter: AwarenessMeter
## Owner lines in the console, kept so they can corrupt themselves later.
var _owner_lines: Array[Label] = []
var _corrupt_timer := 0.0
var _corrupted: Label
var _corrupted_text := ""
var _death_style := ""
var _death_title := ""
var _death_ghosts: Array[Label] = []
var _awareness := 0.0
var _console: VBoxContainer
## Dark backing behind the console, so it reads over any floor or effect.
var _console_box: PanelContainer
## One short line under the awareness meter ("HIDDEN", ...).
var _status: Label
## Tutorial tip card.
var _tip: PanelContainer
var _tip_title: Label
var _tip_body: Label
var _tip_tween: Tween
var _prompt: Label
var _overlay: ColorRect
var _overlay_title: Label
var _overlay_body: Label
var _overlay_tip: Label
## Whether the last dialogue was read to its end (vs. walked away from or
## closed by something else).
var dialogue_finished := false
## The frame the HUD last used an interact press (advancing or closing a
## dialogue, picking a choice): that press must not also count as a tap on
## the world, or closing a chat would reopen it.
var interact_used_frame := -10
var _finishing := false
var _hint: Label
## "hold [E]  FREEZE +6": what holding interact would do right now.
var _glitch_prompt: Label
## Big centred line for owner-scale events ("‖ OWNER PAUSED").
var _banner: Label
## Urgent owner warnings (warn()): shown at once, whatever is being read.
var _warning: Label
var _warning_tween: Tween
var _overlay_retry: Label
## The death card's last line: what carries into the next run.
var _overlay_kept: Label
## A choice: a question and a list of options (choose()).
var _choice: PanelContainer
var _choice_question: Label
var _choice_list: VBoxContainer
var _choice_frame := -1
const GLITCH_COLOR := Color(1.0, 0.45, 0.75)

var _queue: Array[Dictionary] = []
var _typing: Label
var _typed := 0.0
var _pause := 0.0
var _playtime := 14.0 * 3600.0 + 22.0 * 60.0  # the owner has played a lot

var _dialogue: Panel
var _dialogue_speaker: Label
var _dialogue_text: Label
var _dialogue_hint: Label
var _dialogue_lines: Array = []
## The voice id of each entry in _dialogue_lines ("" for a continuation page).
var _dialogue_ids: Array[String] = []
## The speaker's portrait (null: none) and the expression for each entry in
## _dialogue_lines; the face talks while the line types and blinks after.
var _dialogue_face: CharacterArt.Portrait
var _dialogue_exprs: Array[String] = []
var _face_t := 0.0
var _dialogue_index := 0
var _dialogue_typed := 0.0
var _dialogue_opened_frame := -1
var _area_title: Label
## Act cards: "ACT III" above the title, the place name under it.
var _act_label: Label
var _area_sub: Label
var _area_tween: Tween
var _fade: ColorRect
var _bars: Array[ColorRect] = []
var _cine_title: Label
var _cine_text: Label
var _cine_hint: Label
var _cinematic := false
## The pacing of the dialogue line on screen (LinePacer, docs/STORY_PACING.md).
var _pacer: LinePacer
var _dialogue_voice := ""
var _dialogue_voice_prefix := ""
## Cinematics: the line on screen and the hold-to-skip state.
var _cine_pacer: LinePacer
var _skip_hold := 0.0
var _skip_armed := false
var _skip_requested := false
var _cine_backing: Panel
var _cine_portrait: PortraitView
var _objective: Label
var _objective_tween: Tween
var _dialogue_portrait: PortraitView
var _objective_hint: Label
var _dialogue_box_style: StyleBoxFlat
var _console_style: StyleBoxFlat
var _cine_style: StyleBoxFlat
const HISTORY_MAX := 300
## Everything shown this run, oldest first, from every route (dialogue,
## cinematics, the console): {speaker, text, kind, voice}. The pause menu's
## History page reads it; lines still waiting in the queue are not in it.
var history: Array[Dictionary] = []
signal history_added(entry: Dictionary)


func _ready() -> void:
	narrator = Narration.new()
	add_child(narrator)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_slot = _make_label(root, SAFE, Vector2(380, 14), 10, SLOT_COLOR)

	_meter = AwarenessMeter.new()
	_meter.position = Vector2(640 - SAFE.x - 180, SAFE.y - 2)
	_meter.size = Vector2(180, 36)
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_meter)

	# The current goal, under the save header (World shows it when it changes).
	_objective = _make_label(root, SAFE + Vector2(0, 15), Vector2(400, 12), 9, Color("c8b8a0"))
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.modulate.a = 0.0
	_objective.add_theme_stylebox_override("normal", _backing(0.82))
	# A quieter line under it: where the story might lead (Progression).
	_objective_hint = _make_label(_objective, Vector2(10, 14), Vector2(390, 12), 8, Color(SYSTEM_COLOR, 0.9))
	_objective_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.resized.connect(func() -> void: _objective_hint.position.y = _objective.size.y + 1.0)

	_status = _make_label(root, Vector2(640 - SAFE.x - 220, SAFE.y + 36), Vector2(220, 12), 9, STATUS_COLOR)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status.grow_horizontal = Control.GROW_DIRECTION_BEGIN  # large text grows left, never off screen

	# The console grows upward from the bottom edge, with a dark backing
	# exactly as tall as its lines.
	_console_box = PanelContainer.new()
	var console_bg := _backing(0.55)
	console_bg.content_margin_left = 6
	console_bg.content_margin_right = 6
	console_bg.content_margin_top = 2
	console_bg.content_margin_bottom = 2
	_console_box.add_theme_stylebox_override("panel", console_bg)
	_console_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_console_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_console_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_console_box.offset_left = SAFE.x - 4
	_console_box.offset_top = -SAFE.y
	_console_box.offset_bottom = -SAFE.y
	_console_box.visible = false
	root.add_child(_console_box)
	_console = VBoxContainer.new()
	_console.add_theme_constant_override("separation", 0)
	_console_box.add_child(_console)

	_prompt = _make_label(root, Vector2(640 - SAFE.x - 176, 360 - SAFE.y - 62), Vector2(176, 16), 11, SLOT_COLOR)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_glitch_prompt = _make_label(root, Vector2(640 - SAFE.x - 220, 360 - SAFE.y - 78), Vector2(220, 14), 10, GLITCH_COLOR)
	_glitch_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_glitch_prompt.grow_horizontal = Control.GROW_DIRECTION_BEGIN

	# The choice box: bottom of the screen, like the dialogue box.
	_choice = PanelContainer.new()
	_choice.theme = UiStyle.make_theme()
	var choice_bg := _backing(0.92)
	choice_bg.border_color = Color(SELF_COLOR, 0.5)
	choice_bg.set_border_width_all(1)
	choice_bg.set_content_margin_all(8)
	_choice.add_theme_stylebox_override("panel", choice_bg)
	_choice.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_choice.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_choice.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_choice.offset_bottom = -SAFE.y
	_choice.custom_minimum_size.x = 420
	_choice.visible = false
	root.add_child(_choice)
	var choice_v := VBoxContainer.new()
	choice_v.add_theme_constant_override("separation", 4)
	_choice.add_child(choice_v)
	_choice_question = Label.new()
	UiStyle.sized(_choice_question, 11)
	_choice_question.add_theme_color_override("font_color", SLOT_COLOR)
	_choice_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_choice_question.custom_minimum_size.x = 400
	choice_v.add_child(_choice_question)
	_choice_list = VBoxContainer.new()
	_choice_list.add_theme_constant_override("separation", 3)
	choice_v.add_child(_choice_list)

	# A compact plate high on the screen (pass 8): a warning that names the
	# danger, not a headline across the play area.
	_banner = _make_label(root, Vector2(170, 50), Vector2(300, 18), 13, SELF_COLOR)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var plate := _backing(0.55)
	plate.set_corner_radius_all(3)
	plate.content_margin_left = 8
	plate.content_margin_right = 8
	_banner.add_theme_stylebox_override("normal", plate)
	_banner.visible = false  # the plate shows only with something on it

	# Warnings sit under the banner on their own dark strip: never queued
	# behind the console, never hidden by a conversation.
	_warning = _make_label(root, Vector2(120, 72), Vector2(400, 18), 11, OWNER_COLOR)
	_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var warn_bg := StyleBoxFlat.new()
	warn_bg.bg_color = Color(0, 0, 0, 0.8)
	warn_bg.border_color = Color(OWNER_COLOR, 0.6)
	warn_bg.set_border_width_all(1)
	warn_bg.content_margin_left = 8
	warn_bg.content_margin_right = 8
	warn_bg.content_margin_top = 2
	warn_bg.content_margin_bottom = 2
	_warning.add_theme_stylebox_override("normal", warn_bg)
	_warning.visible = false

	_hint = _make_label(root, Vector2(640 - SAFE.x - 176, 360 - SAFE.y - 14), Vector2(176, 12), 9, Color(SYSTEM_COLOR, 0.8))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN

	# Tutorial tips: a small card, centred under the top bar.
	var tip_row := VBoxContainer.new()
	tip_row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tip_row.position.y = SAFE.y + 50  # under the status line, not over it
	tip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tip_row)
	_tip = PanelContainer.new()
	_tip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_tip.custom_minimum_size.x = 300
	var tip_box := _backing(0.85)
	tip_box.border_color = Color(STATUS_COLOR, 0.5)
	tip_box.set_border_width_all(1)
	tip_box.set_content_margin_all(6)
	_tip.add_theme_stylebox_override("panel", tip_box)
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.modulate.a = 0.0
	_tip.visible = false
	tip_row.add_child(_tip)
	var tip_lines := VBoxContainer.new()
	tip_lines.add_theme_constant_override("separation", 1)
	_tip.add_child(tip_lines)
	_tip_title = Label.new()
	UiStyle.sized(_tip_title, 10)
	_tip_title.add_theme_color_override("font_color", STATUS_COLOR)
	_tip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_lines.add_child(_tip_title)
	_tip_body = Label.new()
	UiStyle.sized(_tip_body, 10)
	_tip_body.add_theme_color_override("font_color", SLOT_COLOR)
	_tip_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_body.custom_minimum_size.x = 288
	tip_lines.add_child(_tip_body)

	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0.82)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	root.add_child(_overlay)
	# Two colour-split ghosts behind the title, used by the death screens.
	for c in [Color(1.0, 0.1, 0.35, 0.6), Color(0.3, 0.9, 1.0, 0.6)]:
		var ghost := _make_label(_overlay, Vector2(0, 120), Vector2(640, 40), 28, c)
		ghost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ghost.add_theme_constant_override("outline_size", 0)  # pure colour fringes
		ghost.visible = false
		_death_ghosts.append(ghost)
	_overlay_title = _make_label(_overlay, Vector2(0, 120), Vector2(640, 40), 28, OWNER_COLOR)
	_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_body = _make_label(_overlay, Vector2(40, 170), Vector2(560, 140), 11, SLOT_COLOR)
	_overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Death cards: what to try next time.
	_overlay_tip = _make_label(_overlay, Vector2(80, 268), Vector2(480, 40), 10, Color("ffe08a"))
	_overlay_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var tip_bg := StyleBoxFlat.new()
	tip_bg.bg_color = Color(0, 0, 0, 0.75)
	tip_bg.content_margin_left = 8
	tip_bg.content_margin_right = 8
	tip_bg.content_margin_top = 3
	tip_bg.content_margin_bottom = 3
	_overlay_tip.add_theme_stylebox_override("normal", tip_bg)
	# The death card waits for the player (show_retry()).
	_overlay_retry = _make_label(_overlay, Vector2(80, 318), Vector2(480, 14), 10, SLOT_COLOR)
	_overlay_retry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_retry.visible = false
	_overlay_kept = _make_label(_overlay, Vector2(40, 334), Vector2(560, 14), 9, Color("8a8f98"))
	_overlay_kept.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_kept.visible = false

	_area_title = _make_label(root, Vector2(0, 150), Vector2(640, 24), 16, SLOT_COLOR)
	_area_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_area_title.add_theme_constant_override("outline_size", 4)
	_area_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_area_title.modulate.a = 0.0
	_act_label = _make_label(_area_title, Vector2(0, -16), Vector2(640, 14), 10, SELF_COLOR)
	_act_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_area_sub = _make_label(_area_title, Vector2(0, 26), Vector2(640, 14), 9, SYSTEM_COLOR)
	_area_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_dialogue = Panel.new()
	_dialogue.position = Vector2(SAFE.x - 4, 360 - SAFE.y - 68)
	_dialogue.size = Vector2(640 - SAFE.x * 2 + 8, 68)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(UiStyle.SURFACE, 0.94)
	box.set_border_width_all(1)
	box.border_color = Color(1, 1, 1, 0.12)
	box.set_corner_radius_all(6)
	box.anti_aliasing = true
	_dialogue.add_theme_stylebox_override("panel", box)
	_dialogue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue.visible = false
	root.add_child(_dialogue)
	_dialogue_speaker = _make_label(_dialogue, Vector2(8, 3), Vector2(400, 14), 10, NPC_COLOR)
	_dialogue_text = _make_label(_dialogue, Vector2(8, 18), Vector2(560, 34), 11, SLOT_COLOR)
	_dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_hint = _make_label(_dialogue, Vector2(_dialogue.size.x - 130, 52), Vector2(122, 12), 9, SYSTEM_COLOR)
	_dialogue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fade)

	# Cinematic: letterbox bars and a centred, typed text block (above the fade,
	# so a fully black fade still shows the text).
	for i in 2:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.position = Vector2(0, 0 if i == 0 else 360)
		bar.size = Vector2(640, 0)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(bar)
		_bars.append(bar)
	_cine_title = _make_label(root, Vector2(0, 118), Vector2(640, 16), 9, SYSTEM_COLOR)
	_cine_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cine_text = _make_label(root, Vector2(60, 140), Vector2(520, 80), 12, SELF_COLOR)
	_cine_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cine_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cine_text.add_theme_color_override("font_outline_color", Color.BLACK)
	_cine_text.add_theme_constant_override("outline_size", 4)
	_cine_hint = _make_label(root, Vector2(0, 326), Vector2(640 - SAFE.x, 12), 9, Color(SYSTEM_COLOR, 0.8))
	_cine_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cine_style = StyleBoxFlat.new()
	_cine_style.set_corner_radius_all(4)
	_cine_backing = Panel.new()
	_cine_backing.add_theme_stylebox_override("panel", _cine_style)
	_cine_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_cine_backing)
	root.move_child(_cine_backing, _cine_text.get_index())  # behind the text
	_cine_portrait = PortraitView.new()
	_cine_portrait.size = Vector2(64, 64)
	_cine_portrait.position = Vector2(52, 134)
	_cine_portrait.visible = false
	root.add_child(_cine_portrait)
	# The speaker's face: the same illustrated figure as in the world.
	_dialogue_portrait = PortraitView.new()
	_dialogue_portrait.size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	_dialogue_portrait.position = Vector2(6, 6)
	_dialogue_portrait.visible = false
	_dialogue.add_child(_dialogue_portrait)
	for l in [_cine_title, _cine_text, _cine_hint, _cine_backing]:
		l.visible = false
	# Subtitles size and back themselves from the story settings, not only
	# the general Large text toggle.
	for l in [_dialogue_text, _dialogue_speaker, _cine_text, _cine_title]:
		l.remove_from_group(UiStyle.TEXT_GROUP)
	_dialogue_box_style = _dialogue.get_theme_stylebox("panel") as StyleBoxFlat
	_console_style = _console_box.get_theme_stylebox("panel") as StyleBoxFlat
	apply_subtitle_style()
	Settings.changed.connect(apply_subtitle_style)


## Subtitle size and backing from Settings (subtitle_size, subtitle_bg,
## large_text, speaker_labels). Called again whenever a setting changes.
func apply_subtitle_style() -> void:
	var k := Settings.text_scale() * Settings.subtitle_scale()
	for pair in [[_dialogue_text, 11], [_dialogue_speaker, 10], [_cine_text, 12], [_cine_title, 9]]:
		(pair[0] as Label).add_theme_font_size_override("font_size", roundi(pair[1] * k))
	var bg := Settings.subtitle_bg
	if _dialogue_box_style:
		_dialogue_box_style.bg_color.a = clampf(bg, 0.0, 1.0)
	if _console_style:
		_console_style.bg_color.a = bg * 0.7
	if _cine_style:
		_cine_style.bg_color = Color(0, 0, 0, bg * 0.6)
	_dialogue_speaker.visible = Settings.speaker_labels
	if _dialogue.visible:
		_fit_dialogue()
	if _cinematic:
		_fit_cinematic()


## Keep a line in the run's history (every route calls this when a line is
## actually shown). voice: the id of a recording that can be replayed.
func _log_line(speaker: String, text: String, kind: String, voice := "") -> void:
	var entry := {"speaker": speaker, "text": text, "kind": kind, "voice": voice}
	history.append(entry)
	while history.size() > HISTORY_MAX:
		history.pop_front()
	history_added.emit(entry)


## Show (or hide, with null) a character portrait beside cinematic text.
func _show_portrait(portrait: CharacterArt.Portrait) -> void:
	var shown := portrait != null and CharacterArt.has_portrait(portrait.who)
	_cine_portrait.portrait = portrait if shown else null
	_cine_portrait.tint = SELF_COLOR if shown and portrait.who == "rue" else NPC_COLOR
	_cine_portrait.visible = shown
	if shown:
		_cine_text.position.x = 128
		_cine_text.size.x = 452
		_cine_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		_cine_text.position.x = 60
		_cine_text.size.x = 520
		_cine_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## Change the portrait's expression mid-scene (CharacterArt expressions).
func set_portrait(portrait: CharacterArt.Portrait) -> void:
	if _cinematic:
		_show_portrait(portrait)


## Plays a letterboxed sequence of story lines; await it. Each line types
## out, then waits for the player (Settings.advance_mode manual, the
## default) or advances by itself once read and spoken (auto). Holding
## interact/confirm skips the rest; every line still goes in the history.
## `dim` darkens the world behind the text (0 = see-through, 1 = black).
## voice_prefix: the scene's id stem; each line's id is voice_id(prefix, text).
## portrait: a character portrait shown with the text (CharacterArt), or null.
func cinematic(title: String, lines: Array, color: Color = SELF_COLOR, dim: float = 0.55, voice_prefix := "", portrait: CharacterArt.Portrait = null) -> void:
	# A scene owns the screen: an open dialogue box is hidden and holds its
	# place (it is NOT closed: closing would end the conversation and run its
	# side effects mid-scene), and the act card clears.
	var dialogue_held := _dialogue.visible
	_dialogue.visible = false
	if dialogue_held:
		# Its line stops with it; it is said again when the conversation returns.
		VoiceOver.stop()
		narrator.stop()
	_clear_title()
	_cinematic = true
	_skip_requested = false
	_skip_armed = false
	_skip_hold = 0.0
	_console_box.visible = false
	_prompt.visible = false
	_cine_title.text = title if Settings.speaker_labels or title == "EPILOGUE" else ""
	_cine_text.add_theme_color_override("font_color", color)
	_show_portrait(portrait)
	for l in [_cine_title, _cine_text, _cine_hint, _cine_backing]:
		l.visible = true
	var tw := create_tween().set_parallel()
	tw.tween_property(_bars[0], "size:y", 40.0, 0.4)
	tw.tween_property(_bars[1], "size:y", 40.0, 0.4)
	tw.tween_property(_bars[1], "position:y", 320.0, 0.4)
	tw.tween_property(_fade, "color:a", dim, 0.4)
	while tw.is_running():
		await get_tree().process_frame
		if not is_inside_tree():
			return
		if _advance_pressed():
			_skip_armed = true  # a hold that starts as the scene opens counts
	var paged := paginate(lines, voice_prefix)
	var shown: Array = paged[0]
	var ids: Array[String] = []
	ids.assign(paged[1])
	var carry: Array = paged[3]
	var cue: Array = paged[4]
	for i in shown.size():
		if _skip_requested:
			# Skipped lines are still part of the story: keep them readable.
			_log_line(title, str(shown[i]), _cine_kind(str(shown[i]), color), "")
			continue
		var next_carries: bool = i + 1 < carry.size() and carry[i + 1]
		var began: float = cue[i - 1] if i > 0 and paged[2][i - 1] == paged[2][i] else 0.0
		await _cinematic_line(str(shown[i]), ids[i], title, color, carry[i], cue[i], next_carries, float(cue[i]) - began)
		if not is_inside_tree():
			return
	VoiceOver.stop()
	narrator.stop()
	_cine_pacer = null
	_cine_text.text = ""
	var out := create_tween().set_parallel()
	out.tween_property(_bars[0], "size:y", 0.0, 0.4)
	out.tween_property(_bars[1], "size:y", 0.0, 0.4)
	out.tween_property(_bars[1], "position:y", 360.0, 0.4)
	out.tween_property(_fade, "color:a", 0.0, 0.5)
	await out.finished
	for l in [_cine_title, _cine_text, _cine_hint, _cine_backing]:
		l.visible = false
	_show_portrait(null)
	_cinematic = false
	if dialogue_held and _pacer != null:
		_dialogue.visible = true  # back to the conversation, where it was
		_dialogue_opened_frame = Engine.get_process_frames()  # the scene's last press doesn't advance it
		# Pick the line up again from its start (typed, and said if recorded),
		# so a press still coming from the scene can't skip it unread.
		if _dialogue_voice != "":
			VoiceOver.play(self, _dialogue_voice)
		_pacer = LinePacer.new(_dialogue_text.text, StoryPacing.is_auto(), voice_busy)
		_dialogue_typed = 0.0
		_dialogue_text.visible_characters = 0
	else:
		_console_box.visible = _console.get_child_count() > 0
		_prompt.visible = true


func is_cinematic() -> bool:
	return _cinematic


func _cine_kind(line: String, _color: Color) -> String:
	# Scene lines (memories, epilogues) aren't Rue's in-the-moment thoughts,
	# so the History shows them plainly, not in thought brackets.
	return "owner" if line.begins_with(">") else "scene"


func _cinematic_line(line: String, vid: String, title: String, base_color: Color, carried := false, cue := 1.0, keep_voice := false, share := 1.0) -> void:
	var owner_line := line.begins_with(">")
	var original_color := _cine_text.get_theme_color("font_color")
	if owner_line:
		_cine_text.add_theme_color_override("font_color", OWNER_COLOR)
	# The face beside the scene is the character's: it steps back while the
	# owner speaks, so a portrait never seems to say the owner's words.
	_cine_portrait.modulate.a = 0.25 if owner_line else 1.0
	var spoken := line.trim_prefix(">").strip_edges() if owner_line else line
	# A caption page of a take already playing carries it on (no restart).
	var recorded: AudioStreamPlayer = VoiceOver.current() if carried else VoiceOver.play(self, vid)
	if recorded == null and not carried:
		narrator.speak(spoken, "OWNER" if owner_line else "")
	_log_line("OWNER" if owner_line else title, spoken if owner_line else line, _cine_kind(line, base_color), vid if recorded else "")
	_cine_text.text = line
	_cine_text.visible_characters = 0
	_cine_hint.text = ""
	_fit_cinematic()
	var pacer := LinePacer.new(line, StoryPacing.is_auto(), voice_busy if recorded == null else _take_busy.bind(cue))
	_cine_pacer = pacer
	var typed := 0.0
	var start_frame := Engine.get_process_frames()
	while not pacer.is_done():
		await get_tree().process_frame
		if not is_inside_tree():
			return  # the session ended mid-line (quit to title)
		if get_tree().paused:
			continue  # paused (menu, lost focus): no typing, no reading time
		var delta := get_process_delta_time()
		var frame := Engine.get_process_frames()
		if _update_skip(delta):
			_skip_requested = true
			break
		if pacer.phase == LinePacer.Phase.REVEALING:
			var shown := int(typed)
			var cps := _reveal_rate(40.0, line, share)
			typed = float(line.length()) if is_inf(cps) else typed + cps * delta
			_cine_text.visible_characters = int(typed)
			if int(typed) > shown and not is_inf(cps) and not VoiceOver.is_playing() and not (Settings.narration and narrator.supported):
				if owner_line and not line.is_empty():
					Sfx.owner_blip(line[mini(int(typed) - 1, line.length() - 1)])
				else:
					Sfx.type_key("self" if original_color == SELF_COLOR else "system")
			if typed >= line.length():
				_cine_text.visible_characters = -1
				pacer.reveal(frame)
		else:
			pacer.tick(delta)
		# The press that started the scene (or ended the last line) is old news.
		if frame > start_frame + 1 and _advance_pressed():
			if pacer.press(frame) == "reveal":
				_cine_text.visible_characters = -1
		_cine_hint.text = _skip_text() if _skip_hold > 0.25 else (_continue_text(false) if pacer.is_shown() else "")
		_fit_cinematic()  # wrapping can change after the font or text settles
	if not keep_voice:
		VoiceOver.stop()
		narrator.stop()
	_cine_text.add_theme_color_override("font_color", original_color)


## Holding interact/confirm skips the rest of the scene. Only a hold that
## began during this scene counts (not one carried in from a glitch).
func _update_skip(delta: float) -> bool:
	var held := Input.is_action_pressed("interact") or Input.is_action_pressed("confirm")
	if _advance_pressed():
		_skip_armed = true
	if held and _skip_armed:
		_skip_hold += delta
	else:
		_skip_hold = 0.0
	return _skip_hold >= StoryPacing.SKIP_HOLD


func _skip_text() -> String:
	var n := int(clampf(_skip_hold / StoryPacing.SKIP_HOLD, 0.0, 1.0) * 6.0)
	return "skipping  " + "■".repeat(n) + "□".repeat(6 - n)


## Size the cinematic text block to its lines, with a backing behind it.
func _fit_cinematic() -> void:
	var lh := _cine_text.get_line_height()
	var lines := maxi(1, _cine_text.get_line_count())
	_cine_text.size.y = lines * lh + 4.0
	_cine_backing.position = _cine_text.position - Vector2(8, 6)
	_cine_backing.size = _cine_text.size + Vector2(16, 12)


func _advance_pressed() -> bool:
	return Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("confirm")


## Opens the dialogue box. lines: Array of Strings, advanced with interact
## (or automatically, Settings.advance_mode). voice_prefix: the scene's id
## stem; a line plays voice_id(voice_prefix, text) if it was recorded.
## portrait: the speaker's face (CharacterArt), or null; expressions: one per
## line ("" keeps the portrait's own).
func show_dialogue(speaker: String, color: Color, lines: Array, voice_prefix := "", portrait: CharacterArt.Portrait = null, expressions: Array = []) -> void:
	if lines.is_empty():
		return
	_dialogue_voice_prefix = voice_prefix
	var paged := paginate(lines, voice_prefix)
	_dialogue_source_lines = lines.duplicate()
	_dialogue_sources.assign(paged[2])
	_dialogue_carry.assign(paged[3])
	_dialogue_cue.assign(paged[4])
	_dialogue_lines = paged[0]
	_dialogue_ids.assign(paged[1])
	_dialogue_face = portrait if portrait and CharacterArt.has_portrait(portrait.who) else null
	_dialogue_portrait.tint = color
	_dialogue_exprs.clear()
	for i in paged[2]:
		var e: String = str(expressions[i]) if i < expressions.size() else ""
		_dialogue_exprs.append(e if e != "" else (portrait.expression if portrait else ""))
	_layout_dialogue_face()
	_dialogue_index = 0
	_dialogue_typed = 0.0
	_dialogue_opened_frame = Engine.get_process_frames()
	_dialogue_speaker.text = speaker
	_dialogue_speaker.add_theme_color_override("font_color", color)
	_dialogue.visible = true
	_console_box.visible = false
	_prompt.visible = false
	_clear_title()
	_show_dialogue_line()


func close_dialogue() -> void:
	if not _dialogue.visible:
		return
	narrator.stop()
	VoiceOver.stop()
	_pacer = null
	_dialogue_face = null
	_layout_dialogue_face()
	dialogue_finished = _finishing
	_finishing = false
	_dialogue.visible = false
	_console_box.visible = _console.get_child_count() > 0
	_prompt.visible = true
	dialogue_closed.emit()


## Asks a question and waits for a pick (arrows / stick + E, or tap).
## Returns the option's index. Await it.
## A question still open when the run ends (death, quit, an ending) answers
## nothing: the asker gets -1.
func cancel_choice() -> void:
	if _choice.visible:
		_chosen.emit(-1)


func choose(question: String, options: Array, focus := 0) -> int:
	_choice_question.text = question
	for c in _choice_list.get_children():
		c.queue_free()
	var first: Button = null
	for i in options.size():
		var b := Button.new()
		b.text = str(options[i])
		b.focus_mode = Control.FOCUS_ALL
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func() -> void:
			if Time.get_ticks_msec() >= _choice_ready_ms:  # not the press that ended the dialogue
				_chosen.emit(i))
		b.focus_entered.connect(func() -> void: Sfx.ui("ui_move"))
		_choice_list.add_child(b)
		if first == null or i == focus:
			first = b
	_choice.visible = true
	_choice_ready_ms = Time.get_ticks_msec() + CHOICE_GRACE_MS
	_choice.move_to_front()  # above an end card's dimming overlay, if one is up
	_choice_frame = Engine.get_process_frames()
	_console_box.visible = false
	_prompt.visible = false
	first.grab_focus()
	var picked: int = await _chosen
	Sfx.ui("ui_confirm")
	_choice.visible = false
	_console_box.visible = _console.get_child_count() > 0
	_prompt.visible = true
	return picked


func is_choosing() -> bool:
	return _choice.visible


func _update_choice() -> void:
	if not _choice.visible or Engine.get_process_frames() <= _choice_frame + 1 or Time.get_ticks_msec() < _choice_ready_ms:
		return
	# W/S (movement keys that aren't also ui_up/ui_down) move the choice too.
	var step := 0
	if Input.is_action_just_pressed("move_down") and not Input.is_action_just_pressed("ui_down"):
		step = 1
	elif Input.is_action_just_pressed("move_up") and not Input.is_action_just_pressed("ui_up"):
		step = -1
	if step != 0:
		var focused := get_viewport().gui_get_focus_owner()
		var n := _choice_list.get_child_count()
		if n > 0:
			var i := focused.get_index() if focused is Button and focused.get_parent() == _choice_list else 0
			(_choice_list.get_child((i + step + n) % n) as Button).grab_focus()
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("confirm"):
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button and focused.get_parent() == _choice_list:
			interact_used_frame = Engine.get_process_frames()
			_chosen.emit(focused.get_index())


func is_dialogue_open() -> bool:
	return _dialogue.visible


func show_area_title(text: String) -> void:
	_act_label.text = ""
	_area_sub.text = ""
	_show_title(text, 1.6)


## A chapter card: "ACT III" / OUT OF BOUNDS / the place's own name.
func show_act(act: String, title: String, place: String) -> void:
	_act_label.text = "—  %s  —" % act
	_area_sub.text = place
	_show_title(title, 2.8)
	# Shown (and holding the owner) from this frame, not from the tween's
	# first step: no frame of countdown slips in before it appears.
	_area_title.modulate.a = maxf(_area_title.modulate.a, 0.01)
	Sfx.play("stinger", -10.0, 0.7, 0.0)


## Puts away an act or area card now (as if it had been read).
func dismiss_title() -> void:
	_clear_title()


func is_act_shown() -> bool:
	return _act_label.text != "" and _area_title.modulate.a > 0.0


## An act or area card gives way to dialogue and scenes (one thing to read
## at a time).
func _clear_title() -> void:
	if _area_tween:
		_area_tween.kill()
	_area_title.modulate.a = 0.0


func _show_title(text: String, hold: float) -> void:
	_area_title.text = text
	if _area_tween:
		_area_tween.kill()
	var tw := create_tween()
	_area_tween = tw
	tw.tween_property(_area_title, "modulate:a", 1.0, 0.4)
	tw.tween_interval(hold)
	tw.tween_property(_area_title, "modulate:a", 0.0, 0.8)


## Fades the screen to black (or back). Await the returned tween's `finished`.
func fade(to_black: bool, duration: float = 0.25) -> Tween:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0 if to_black else 0.0, duration)
	return tw


## For line_shown: the lines as given, and which of them each page is from.
var _dialogue_source_lines: Array = []
var _dialogue_sources: Array[int] = []
## Per page: a continuation of the take already playing, and where it ends.
var _dialogue_carry: Array[bool] = []
var _dialogue_cue: Array[float] = []


func _show_dialogue_line() -> void:
	var text := str(_dialogue_lines[_dialogue_index])
	_dialogue_text.text = text
	if _dialogue_index < _dialogue_sources.size():
		var src := _dialogue_sources[_dialogue_index]
		var last_page := _dialogue_index + 1 >= _dialogue_sources.size() or _dialogue_sources[_dialogue_index + 1] != src
		if last_page and src < _dialogue_source_lines.size():
			line_shown.emit(str(_dialogue_source_lines[src]))
	_dialogue_voice = _dialogue_ids[_dialogue_index] if _dialogue_index < _dialogue_ids.size() else ""
	var carried := _dialogue_index < _dialogue_carry.size() and _dialogue_carry[_dialogue_index]
	var cue := _dialogue_cue[_dialogue_index] if _dialogue_index < _dialogue_cue.size() else 1.0
	var recorded: AudioStreamPlayer = VoiceOver.current() if carried else VoiceOver.play(self, _dialogue_voice)
	if recorded == null and not carried and _dialogue_speaker.text != Story.TOBBEN_WRITTEN:  # written, not said
		narrator.speak(text, _dialogue_speaker.text)
	_dialogue_text.visible_characters = 0
	_dialogue_typed = 0.0
	# A caption page of a take waits for its own words; the last page for the
	# end of the take (its last words are never cut to suit a timer).
	var busy: Callable = voice_busy if recorded == null else _take_busy.bind(cue)
	_pacer = LinePacer.new(text, StoryPacing.is_auto(), busy)
	_log_line(_dialogue_speaker.text, text, "npc", _dialogue_voice if recorded else "")
	_dialogue_hint.text = ""
	_face_t = 0.0
	_update_dialogue_face(0.0)
	_fit_dialogue()


## With a portrait the text moves right to make room for it.
func _layout_dialogue_face() -> void:
	var x := PORTRAIT_SIZE + 14.0 if _dialogue_face else 8.0
	_dialogue_portrait.visible = _dialogue_face != null
	_dialogue_speaker.position.x = x
	_dialogue_text.position.x = x
	_dialogue_text.size.x = 568.0 - x


## The face talks (mouth frames) while the line types or the voice speaks,
## and blinks now and then while it waits.
func _update_dialogue_face(delta: float) -> void:
	if _dialogue_face == null:
		return
	_face_t += delta
	var expr: String = _dialogue_exprs[_dialogue_index] if _dialogue_index < _dialogue_exprs.size() else ""
	var face := _dialogue_face.with(expr) if expr != "" else _dialogue_face
	var speaking := (_pacer != null and _pacer.phase == LinePacer.Phase.REVEALING) or voice_busy()
	var frame := ""
	if speaking and not Settings.reduce_flashing:
		frame = "talk" if int(_face_t / 0.12) % 2 == 0 else ""
	elif fmod(_face_t, 3.2) > 3.05:
		frame = "blink"
	if _dialogue_portrait.portrait == null or _dialogue_portrait.portrait.expression != face.expression \
			or _dialogue_portrait.portrait.who != face.who or _dialogue_portrait.portrait.palette != face.palette:
		_dialogue_portrait.portrait = face
	_dialogue_portrait.frame = frame


## The expression the portrait shows now ("" without one).
func dialogue_expression() -> String:
	if _dialogue_face == null or not _dialogue.visible:
		return ""
	return _dialogue_exprs[_dialogue_index] if _dialogue_index < _dialogue_exprs.size() else _dialogue_face.expression


## The stable dialogue id of a line: "<scene>.<first 8 hex of md5(text)>".
## Same text, same id, in whatever order or variant a scene shows it; a
## change to the text makes a new id, so an outdated recording never plays
## under new words (audio/voice/manifest.csv lists them all).
## Lines too long for one box become pages (StoryPacing.pages, sized for the
## current text settings), each with its own reading time. A recorded line is
## one performance: its pages are captions over the one take, which starts
## with the first page and carries on through the rest (never restarted per
## page, never cut to fit a page). Returns [lines, voice ids, index of the
## line each came from, carries (a continuation of a recorded take), cue end
## (share of the line's text, 0..1, where the page ends)]; a continuation page
## has no id.
static func paginate(lines: Array, prefix: String) -> Array:
	var out: Array = []
	var ids: Array[String] = []
	var source: Array[int] = []
	var carry: Array[bool] = []
	var cue_end: Array[float] = []
	for n in lines.size():
		var line := str(lines[n])
		var id := voice_id(prefix, line)
		var recorded := VoiceOver.has_line(id)
		var pages: Array[String] = StoryPacing.pages(line, page_chars())
		var done := 0
		for i in pages.size():
			out.append(pages[i])
			ids.append(id if i == 0 else "")
			source.append(n)
			carry.append(recorded and i > 0)
			done += pages[i].length() + (1 if i + 1 < pages.size() else 0)
			cue_end.append(1.0 if i + 1 == pages.size() else float(done) / maxf(1.0, float(line.length())))
	return [out, ids, source, carry, cue_end]


## Characters per page for the current subtitle and text size: bigger text,
## fewer words per page, so a page always fits the box (DIALOGUE_MAX_H).
static func page_chars() -> int:
	var k := Settings.subtitle_scale() * Settings.text_scale()
	return clampi(int(StoryPacing.PAGE_CHARS / (k * k)), 70, StoryPacing.PAGE_CHARS)


## The current dialogue page's share of its whole line (1 for a one-page line).
func _page_share() -> float:
	if _dialogue_index >= _dialogue_sources.size():
		return 1.0
	var src := _dialogue_sources[_dialogue_index]
	var whole := str(_dialogue_source_lines[src]) if src < _dialogue_source_lines.size() else _dialogue_text.text
	return float(_dialogue_text.text.length()) / maxf(1.0, float(whole.length()))


## While a recorded take is speaking the part of its line up to `until`
## (a share of the line, 1 = the whole take): a page waits for its own words.
func _take_busy(until: float) -> bool:
	if not VoiceOver.is_playing():
		return false
	if until >= 1.0:
		return true
	return VoiceOver.progress() < until


static func voice_id(prefix: String, text: String) -> String:
	if prefix == "":
		return ""
	return "%s.%s" % [prefix, text.strip_edges().md5_text().substr(0, 8)]


## A story voice is speaking: a recording, or (if on) system speech.
func voice_busy() -> bool:
	return VoiceOver.is_playing() or narrator.is_speaking()


## Characters per second for the typewriter: the player's text speed, but
## never slower than a recording needs (text keeps up with the voice).
func _reveal_rate(base_cps: float, text: String, share := 1.0) -> float:
	var rate := Settings.text_rate()
	if is_inf(rate):
		return INF
	var cps := base_cps * rate
	var p := VoiceOver.current()
	if p and p.stream and p.stream.get_length() > 0.1:
		# A caption page keeps up with its own share of the take.
		cps = maxf(cps, text.length() / (p.stream.get_length() * clampf(share, 0.05, 1.0) * 0.85))
	return cps


## The continue marker: shown only once the whole line is visible.
func _continue_text(last: bool) -> String:
	if StoryPacing.is_auto():
		return "auto  »"
	return "%s  [%s]" % ["close" if last else "▼", Settings.glyph("interact")]


func _next_dialogue_line() -> void:
	var carries := _dialogue_index + 1 < _dialogue_carry.size() and _dialogue_carry[_dialogue_index + 1]
	if not carries:
		VoiceOver.stop()  # advancing deliberately ends this line's speech (manual)
		narrator.stop()
	if _dialogue_index < _dialogue_lines.size() - 1:
		_dialogue_index += 1
		_show_dialogue_line()
	else:
		_finishing = true  # read to the end, not walked away from
		close_dialogue()


## Grow the dialogue box to fit its text (long lines, large subtitles).
func _fit_dialogue() -> void:
	var lines := maxi(2 if _dialogue_face == null else 3, _dialogue_text.get_line_count())
	var lh := _dialogue_text.get_line_height()
	var top := 18.0 * Settings.subtitle_scale() if Settings.speaker_labels else 6.0
	_dialogue_text.position.y = top
	_dialogue_text.size.y = lines * lh + 2.0
	var h := top + _dialogue_text.size.y + 14.0
	if _dialogue_face:
		h = maxf(h, PORTRAIT_SIZE + 14.0)  # the face never overhangs the box
	h = minf(h, DIALOGUE_MAX_H)  # pages are sized to fit (page_chars)
	_dialogue.size.y = h
	_dialogue.position.y = 360 - SAFE.y - h
	_dialogue_hint.position.y = h - 14.0


func _update_dialogue(delta: float) -> void:
	if not _dialogue.visible or _pacer == null or _cinematic:
		return
	_update_dialogue_face(delta)
	var frame := Engine.get_process_frames()
	var total := _dialogue_text.get_total_character_count()
	if _pacer.phase == LinePacer.Phase.REVEALING:
		var before := int(_dialogue_typed)
		var cps := _reveal_rate(DIALOGUE_SPEED * Sfx.voice_pace(_dialogue_speaker.text), _dialogue_text.text, _page_share())
		if is_inf(cps):
			_dialogue_typed = float(total)  # Text: Instant
		else:
			_dialogue_typed += cps * delta
		_dialogue_text.visible_characters = mini(int(_dialogue_typed), total)
		if _dialogue_typed >= total:
			_dialogue_text.visible_characters = -1
			_pacer.reveal(frame)
			_fit_dialogue()
		if int(_dialogue_typed) > before and not is_inf(cps) and not VoiceOver.is_playing():
			# Each speaker has their own voice (Sfx.VOICE_PROFILES); books and notes rustle.
			if narrator.voicing():
				pass  # system speech is carrying the line; if it never starts, the syllables do
			elif _dialogue_speaker.text in Sfx.VOICE_PROFILES:
				Sfx.voice_blip(_dialogue_speaker.text)
			else:
				Sfx.type_key("system")
	else:
		_pacer.tick(delta)
	if _pacer.is_shown():
		_dialogue_hint.text = _continue_text(_dialogue_index == _dialogue_lines.size() - 1)
		_dialogue_hint.modulate.a = 1.0 if Settings.reduce_flashing or StoryPacing.is_auto() else 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.003))
	if frame != _dialogue_opened_frame and _advance_pressed():
		# The press that opened the box doesn't also advance it.
		interact_used_frame = frame
		if _pacer.press(frame) == "reveal":
			_dialogue_text.visible_characters = -1  # first press: the whole line, nothing more
	if _pacer.is_done():
		_next_dialogue_line()


## kind: "owner", "system", "self" (the intruder's thoughts) or "npc".
## speaker is shown for npc lines.
func say(text: String, kind: String = "owner", speaker: String = "") -> void:
	var msg := {"text": text, "kind": kind, "speaker": speaker}
	if kind == "owner":
		# The owner's lines carry the warnings: they go ahead of thoughts and
		# system lines still waiting (in order among themselves).
		var at := _queue.size()
		for i in _queue.size():
			if _queue[i].kind != "owner":
				at = i
				break
		_queue.insert(at, msg)
	else:
		_queue.append(msg)


## The console is still typing or has lines waiting.
func is_console_busy() -> bool:
	return _typing != null or not _queue.is_empty()


func clear_queue() -> void:
	_queue.clear()


## An urgent owner warning: something will happen to Rue unless the player
## acts. It shows at once on its own strip, whatever the console is typing
## and whatever is open (a conversation, a scene), stays for its reading
## time, and goes in the History once. It never waits in the console queue.
func warn(text: String) -> void:
	var shown := "> " + text
	_warning.text = shown
	_warning.visible = true
	_warning.modulate.a = 1.0
	_warning.reset_size()
	_warning.size.x = 400
	hide_tip(true)
	Sfx.owner_blip(text[0] if text != "" else "a")
	console_history.append(shown)
	if console_history.size() > MAX_HISTORY:
		console_history.pop_front()
	_log_line("OWNER", text, "owner")
	if _warning_tween:
		_warning_tween.kill()
	_warning_tween = create_tween()
	_warning_tween.tween_interval(maxf(2.5, StoryPacing.reading_time(text)))
	_warning_tween.tween_property(_warning, "modulate:a", 0.0, 0.4)
	_warning_tween.tween_callback(func() -> void: _warning.visible = false)


## The warning on screen now ("" if none).
func warning_text() -> String:
	return _warning.text.trim_prefix("> ") if _warning.visible else ""


## The threat is over (the save was interrupted, Rue left): take it down.
func cancel_warning() -> void:
	if _warning_tween:
		_warning_tween.kill()
	_warning.visible = false


func set_awareness(value: float) -> void:
	_awareness = clampf(value, 0.0, 1.0)


## at: the target's world position; the prompt sits just above it (kept on
## screen). Without one it sits in the bottom-right corner.
func set_prompt(text: String, at := Vector2.INF) -> void:
	_prompt.text = "[%s] %s" % [Settings.glyph("interact"), text] if text != "" else ""
	_prompt_at = at
	_place_prompt()


var _prompt_at := Vector2.INF


## Where the prompt sits with no target: bottom right, clear of the on-screen
## E button on phones.
func _prompt_corner() -> Vector2:
	return Vector2(640 - SAFE.x - 176 - (72.0 if Settings.using_touch else 0.0), 360 - SAFE.y - 62)


## One place decides where the prompt goes (set_prompt and every frame), so it
## never jumps between the corner and its target within a frame.
func _place_prompt() -> void:
	if _prompt_at == Vector2.INF or _prompt.text == "":
		_prompt.position = _prompt_corner()
		_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		return
	var screen := get_viewport().canvas_transform * _prompt_at
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var w := _prompt.size.x
	_prompt.position = Vector2(clampf(screen.x - w * 0.5, SAFE.x, 640.0 - SAFE.x - w), clampf(screen.y - 44.0, SAFE.y + 30.0, 360.0 - SAFE.y - 20.0))


func set_hint(text: String) -> void:
	_hint.text = text


## What holding [E] would glitch ("" hides it).
func set_glitch_prompt(text: String) -> void:
	if _glitch_prompt.text != text:
		_glitch_prompt.text = text


func glitch_prompt_text() -> String:
	return _glitch_prompt.text


## A glitch's price: "+8" flies up into the awareness meter, which flinches.
## While a glitch charges: its price as a ghost on the meter (0 hides it).
func preview_cost(amount: float) -> void:
	_meter.preview = amount / 100.0


func cost_preview() -> float:
	return _meter.preview * 100.0


func glitch_cost(amount: float, why := "") -> void:
	var w := 40.0 if why == "" else _meter.size.x
	# Under the meter's state word, inside the screen, right-aligned.
	# Below the state word (lower still with large text), drifting down and
	# away from it; a reason stays long enough to be read.
	var pos := _meter.position + Vector2(_meter.size.x - w, (24 if why == "" else 40) * Settings.text_scale())
	var l := _make_label(_meter.get_parent(), pos, Vector2(w, 14), 12 if why == "" else 10, Color(1.0, 0.35, 0.45))
	l.text = "+%d" % int(amount) if why == "" else "+%d  ·  %s" % [int(amount), why]
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var hold := 0.3 if why == "" else StoryPacing.reading_time(why)
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y + 6.0, hold + 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(hold)
	tw.chain().tween_callback(l.queue_free)
	_meter.jolt()


## A big line under the top bar ("" hides it).
func set_banner(text: String) -> void:
	_banner.text = text
	_banner.visible = text != ""
	if text != "":
		hide_tip(true)


func banner_text() -> String:
	return _banner.text


## One short status line under the meter (e.g. "HIDDEN"), "" to clear.
func set_status(text: String) -> void:
	if _status.text != text:
		_status.text = text


## Show the current goal for its reading time plus 3 s, then fade it to a
## faint reminder (Pause shows it in full).
func show_objective(text: String, hint := "") -> void:
	if _objective_tween:
		_objective_tween.kill()
	_objective_tween = null
	_objective.text = "· " + text if text != "" else ""
	_objective_hint.text = hint if text != "" else ""
	_objective_hint.visible = _objective_hint.text != ""
	if text == "":
		_objective.modulate.a = 0.0
		_objective.visible = false
		return
	_objective_tween = create_tween()
	_objective_tween.tween_property(_objective, "modulate:a", 1.0, 0.4)
	_objective_tween.tween_interval(StoryPacing.reading_time(text) + 3.0)
	_objective_tween.tween_property(_objective, "modulate:a", 0.0, 1.2)
	_objective_tween.finished.connect(func() -> void: _objective_tween = null)
	_update_objective_priority()


func objective_text() -> String:
	return _objective.text if _objective.visible and _objective.modulate.a > 0.05 else ""


func _update_objective_priority() -> void:
	var bounds := _objective.get_global_rect()
	if _objective_hint.visible:
		bounds = bounds.merge(_objective_hint.get_global_rect())
	var overlaps := _prompt.visible and _prompt.text != "" and bounds.intersects(_prompt.get_global_rect())
	var blocked := _cinematic or _dialogue.visible or _choice.visible or is_act_shown() \
		or is_tip_shown() or _banner.visible or _warning.visible or overlaps
	_objective.visible = _objective.text != "" and not blocked
	if _objective_tween and _objective_tween.is_valid():
		if blocked:
			_objective_tween.pause()
		elif not _objective_tween.is_running():
			_objective_tween.play()


## Shows a tutorial tip card (replacing any current one).
func show_tip(title: String, body: String) -> void:
	if banner_text() != "" or is_choosing():
		return
	_tip_title.text = title
	_tip_body.text = body
	_tip.visible = true
	if _tip_tween:
		_tip_tween.kill()
	_tip_tween = create_tween()
	_tip_tween.tween_property(_tip, "modulate:a", 1.0, 0.3)


func hide_tip(immediate := false) -> void:
	if not _tip.visible:
		return
	if _tip_tween:
		_tip_tween.kill()
	if immediate:
		_tip.visible = false
		_tip.modulate.a = 0.0
		return
	_tip_tween = create_tween()
	_tip_tween.tween_property(_tip, "modulate:a", 0.0, 0.3)
	_tip_tween.tween_callback(func() -> void: _tip.visible = false)


## The area's title card is up (tips wait for it: one message at a time).
func is_area_title_shown() -> bool:
	return _area_title.modulate.a > 0.05


## A danger warning is on screen (tips make way for it).
func is_warning_shown() -> bool:
	return _warning.visible


func is_tip_shown() -> bool:
	return _tip.visible and _tip.modulate.a > 0.0


## A threshold was crossed: the awareness meter flinches.
func awareness_jolt() -> void:
	_meter.jolt()


## Death screen, styled per cause ("erased", "overwritten", "selected"):
## the title shakes with colour-split ghosts and keeps corrupting itself.
## kept: what carries into the next run (memories, journal, the purge count).
func show_death(title: String, body: String, cause: String, tip := "", kept := "") -> void:
	_death_style = cause
	_death_title = title
	var colors := {"erased": OWNER_COLOR, "overwritten": Color("8fb4e8"), "selected": Color.WHITE}
	show_overlay(title, body, colors.get(cause, OWNER_COLOR))
	_overlay.color = {"erased": Color(0, 0, 0, 0.88), "overwritten": Color(0.04, 0.07, 0.14, 0.85), "selected": Color(0.02, 0.03, 0.06, 0.8)}.get(cause, Color(0, 0, 0, 0.82))
	for g in _death_ghosts:
		g.visible = Settings.glitch_intensity > 0.0
		g.text = title
	_overlay_tip.text = ("TIP  ·  " + tip) if tip != "" else ""
	_overlay_tip.visible = tip != ""
	_overlay_kept.text = kept
	_overlay_kept.visible = kept != ""


func death_tip_text() -> String:
	return _overlay_tip.text


## The death card's way out, shown once it has had a moment to be read.
func show_retry() -> void:
	_overlay_retry.text = "[%s]  retry" % Settings.glyph("interact")
	_overlay_retry.visible = true
	_overlay_retry.modulate.a = 0.0
	create_tween().tween_property(_overlay_retry, "modulate:a", 1.0, 0.3)


func show_overlay(title: String, body: String, title_color: Color = OWNER_COLOR) -> void:
	if _area_tween:
		_area_tween.kill()
	_area_title.modulate.a = 0.0
	_overlay.visible = true
	_overlay_title.text = title
	_overlay_title.add_theme_color_override("font_color", title_color)
	_overlay_body.text = body
	_overlay_tip.text = ""
	_overlay_tip.visible = false
	_overlay_retry.visible = false
	_overlay_kept.visible = false


func hide_overlay() -> void:
	_overlay.visible = false


func _process(delta: float) -> void:
	_playtime += delta
	_place_prompt()
	_update_objective_priority()
	_glitch_prompt.position.x = _prompt_corner().x + 176 - 220
	# The current interaction outranks a tip: a tip over the prompt steps back.
	var over := _tip.visible and _prompt.visible and _prompt.text != "" and _tip.get_global_rect().intersects(_prompt.get_global_rect())
	var tip_row := _tip.get_parent() as Control  # (the card's own alpha is its show/hide fade)
	tip_row.modulate.a = move_toward(tip_row.modulate.a, 0.2 if over else 1.0, delta * 4.0)
	_glitch_prompt.visible = _prompt.visible
	_update_slot()
	_meter.value = _awareness
	_trim_console()  # text size may have changed
	_update_typing(delta)
	_update_corruption(delta)
	_update_death_title()
	_update_dialogue(delta)
	_update_choice()


func _update_slot() -> void:
	var secs := int(_playtime)
	var name_shown := character_name
	# The name glitches more as the owner gets agitated.
	if randf() < _awareness * 0.04:
		var i := randi() % name_shown.length()
		name_shown = name_shown.substr(0, i) + ["#", "?", "_", "0"].pick_random() + name_shown.substr(i + 1)
	var text := "SLOT 1  ·  %s  ·  LV 7  ·  %02d:%02d:%02d" % [name_shown, floori(secs / 3600.0), floori(secs / 60.0) % 60, secs % 60]
	if unknown_processes > 0:
		text += "  ·  [!] %d UNKNOWN PROCESS" % unknown_processes
	if _slot.text != text:  # re-shaping text every frame is wasted work
		_slot.text = text


func _update_typing(delta: float) -> void:
	# Story owns the screen: while a conversation, scene or question is up,
	# the console waits, including a line it was halfway through typing.
	if _cinematic or _dialogue.visible or _choice.visible:
		return
	if _typing:
		var rate := Settings.text_rate()
		var step := 1000000.0 if is_inf(rate) else TYPE_SPEED * rate * delta
		_typed += step
		var full: String = _typing.get_meta("full", _typing.text)
		var n := mini(int(_typed), full.length())
		# One key sound per new visible character (the sound rate-limits itself).
		if not is_inf(rate) and n > int(_typed - step) and n > 0 and n <= full.length() and full[n - 1] != " ":
			if _typing.get_meta("kind", "") == "owner":
				Sfx.owner_blip(full[n - 1])  # the owner "speaks"
			else:
				Sfx.type_key(_typing.get_meta("kind", "system"))
		if _typing.has_meta("owner") and n < full.length() and Settings.glitch_intensity > 0.0:
			# The owner's text arrives wrong first: garbage ahead of the cursor
			# that resolves into the real letters as they're typed.
			_typing.text = full.substr(0, n) + _garbage(mini(2, full.length() - n))
			_typing.visible_characters = -1
		else:
			_typing.text = full
			_typing.visible_characters = n
		if _typed >= full.length():
			_typing.text = full
			_typing.visible_characters = -1
			# Time to read it before the next one starts (StoryPacing).
			_pause = StoryPacing.ambient_time(full, _queue.size(), _typing.get_meta("kind", "system"))
			_typing = null
		return
	if _pause > 0.0:
		if not _queue.is_empty() and _queue[0].kind == "owner":
			_pause = minf(_pause, StoryPacing.OWNER_GAP)  # a warning doesn't wait for a thought
		_pause -= delta
		return
	if _queue.is_empty():
		return
	var msg: Dictionary = _queue.pop_front()
	var line := Label.new()
	UiStyle.sized(line, 10)
	UiStyle.outline(line, 2)
	# Long lines wrap; nothing is cut off.
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size.x = 420
	match msg.kind:
		"owner":
			# (Some owner lines are written with their own prompt: one "> " only.)
			line.text = msg.text if msg.text.begins_with("> ") else "> " + msg.text
			line.add_theme_color_override("font_color", OWNER_COLOR)
			# A colour-split shadow so the owner's words never sit quite still.
			line.add_theme_color_override("font_shadow_color", Color(0.3, 0.9, 1.0, 0.35 * Settings.glitch_intensity))
			line.add_theme_constant_override("shadow_offset_x", -1)
			line.add_theme_constant_override("shadow_offset_y", 0)
			line.set_meta("owner", true)
			_owner_lines.append(line)
		"self":
			line.text = "(%s)" % msg.text
			line.add_theme_color_override("font_color", SELF_COLOR)
		"npc":
			line.text = "%s: %s" % [msg.speaker, msg.text] if Settings.speaker_labels else msg.text
			line.add_theme_color_override("font_color", NPC_COLOR)
		_:
			line.text = msg.text
			line.add_theme_color_override("font_color", SYSTEM_COLOR)
	console_history.append(line.text)
	if console_history.size() > MAX_HISTORY:
		console_history.pop_front()
	var who: String = {"owner": "OWNER", "self": "RUE", "npc": msg.speaker}.get(msg.kind, "")
	_log_line(who, msg.text, msg.kind)
	line.set_meta("full", line.text)
	line.set_meta("kind", msg.kind)
	line.visible_characters = 0
	_console.add_child(line)
	if not (_cinematic or _dialogue.visible):
		_console_box.visible = true
	_trim_console(true)
	_typing = line
	_typed = 0.0


## Drop the oldest lines beyond what fits (one fewer with large text), and
## fade the older ones.
func _trim_console(force := false) -> void:
	var keep := MAX_LINES - 1 if Settings.large_text else MAX_LINES
	if _console.get_child_count() <= keep and not force:
		return
	while _console.get_child_count() > keep:
		var old := _console.get_child(0) as Label
		_console.remove_child(old)
		_owner_lines.erase(old)
		if old == _corrupted:
			_corrupted = null
		old.queue_free()
	for i in _console.get_child_count():
		var l := _console.get_child(i) as Label
		l.modulate.a = 0.45 + 0.55 * float(i + 1) / _console.get_child_count()


## Every so often a finished owner line corrupts for a moment, more often the
## more aware the owner is. Scales with Settings.glitch_intensity.
func _update_corruption(delta: float) -> void:
	if _corrupted:
		_corrupt_timer -= delta
		if _corrupt_timer <= 0.0:
			_corrupted.text = _corrupted_text
			_corrupted.position.x = 0.0
			_corrupted = null
		return
	var rate := (0.2 + _awareness * 2.0) * Settings.glitch_intensity
	if _owner_lines.is_empty() or randf() > rate * delta:
		return
	var line: Label = _owner_lines.pick_random()
	if line == _typing or not is_instance_valid(line):
		return
	_corrupted = line
	_corrupted_text = line.text
	var chars := line.text.length()
	var text := line.text
	for i in 1 + int(_awareness * 4.0):
		var at := randi() % chars
		text = text.substr(0, at) + _garbage(1) + text.substr(at + 1)
	line.text = text
	line.position.x = randf_range(-2.0, 2.0) * Settings.glitch_intensity
	_corrupt_timer = randf_range(0.06, 0.18)


func _update_death_title() -> void:
	if _death_style == "" or not _overlay.visible:
		return
	var glitch := Settings.glitch_intensity
	var text := _death_title
	if randf() < 0.25 * glitch:
		var at := randi() % text.length()
		text = text.substr(0, at) + _garbage(1) + text.substr(at + 1)
	_overlay_title.text = text
	var base := Vector2(0, 120)
	match _death_style:
		"overwritten":
			# Dragged sideways, like the row is being written over.
			_overlay_title.position = base + Vector2(randf_range(-1, 6) * glitch, 0)
		"selected":
			# Snaps between positions, like a selection being dragged.
			if randf() < 0.1:
				_overlay_title.position = base + Vector2(randf_range(-4, 4), randf_range(-2, 2)) * glitch
		_:
			_overlay_title.position = base + Vector2(randf_range(-2, 2), randf_range(-1, 1)) * glitch
	for i in _death_ghosts.size():
		var g := _death_ghosts[i]
		g.text = text
		var dir := -1.0 if i == 0 else 1.0
		g.position = _overlay_title.position + Vector2(dir * randf_range(1.0, 4.0) * glitch, 0)


func _garbage(count: int) -> String:
	var pool := "#%&@!?/\\|_=+*<>01"
	var out := ""
	for i in count:
		out += pool[randi() % pool.length()]
	return out


func _make_label(parent: Control, pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.sized(l, font_size)
	UiStyle.outline(l, 2 if font_size < 14 else 4)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _backing(alpha: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.0, 0.0, 0.01, alpha)
	return box
