class_name World
extends Node2D
## The session. Owns the player, HUD, the owner, and whichever area is loaded.
## Handles moving between areas, talking, dying, quitting, and winning.

const TITLE_SCENE := "res://scenes/title.tscn"
const INTERACT_DISTANCE := 22.0
const TALK_BREAK_DISTANCE := 40.0
const WIPE_HOLD_TIME := 1.5

var area: Area
## Session-only facts: "pointer" (have Slot 2's pointer), "mira_deleted", ...
var flags: Dictionary = {}
## "", "death", "quit", "win"
var ending := ""
var purged := false

var _focused: Node2D
var _talking_to: Node2D
var _wipe_hold := 0.0
var _light: CanvasModulate
var _pause_menu: PauseMenu
var _transitioning := false
var _visited: Dictionary = {}

@onready var player: Player = $Player
@onready var director: OwnerDirector = $OwnerDirector
@onready var hud: Hud = $HUD
@onready var fx: ScreenFx = $ScreenFX/Effect
@onready var drone: Drone = $Drone


func _ready() -> void:
	player.z_index = 10
	_pause_menu = PauseMenu.new()
	_pause_menu.quit_requested.connect(_quit)
	add_child(_pause_menu)
	_light = CanvasModulate.new()
	add_child(_light)
	hud.dialogue_closed.connect(func() -> void: _talking_to = null)

	if OwnerMemory.is_purged():
		_build_purged()
		return

	var previous := OwnerMemory.begin_session()
	var room := ArinsRoom.new()
	room.previous_exit = previous
	_load_area(room, "start")
	hud.unknown_processes = 1 if OwnerMemory.purge >= 2 else 0
	fx.spike(0.6, 1.0)  # loading into a save you don't belong in
	director.start(self, previous)


func _process(delta: float) -> void:
	_handle_wipe(delta)
	if purged or ending != "" or _transitioning:
		return
	area.area_process(delta)
	player.instability = director.awareness / 100.0
	if _talking_to and (not is_instance_valid(_talking_to) or player.global_position.distance_to(_talking_to.global_position) > TALK_BREAK_DISTANCE):
		hud.close_dialogue()
	_update_focus()
	if _focused and not hud.is_dialogue_open() and Input.is_action_just_pressed("interact"):
		_interact(_focused)


# Menu keys go through _unhandled_input so the pause menu can consume the same
# press that closes it (otherwise it would reopen in the same frame).
func _unhandled_input(event: InputEvent) -> void:
	if purged:
		# Nothing left for the owner to count: leaving is free.
		if event.is_action_pressed("pause"):
			get_tree().change_scene_to_file(TITLE_SCENE)
		return
	match ending:
		"":
			if event.is_action_pressed("pause"):
				get_viewport().set_input_as_handled()
				_pause_menu.open()
		"win":
			if event.is_action_pressed("confirm") or event.is_action_pressed("pause"):
				get_tree().change_scene_to_file(TITLE_SCENE)


# --- areas --------------------------------------------------------------------

func change_area(id: String, arrival: String) -> void:
	if _transitioning or ending != "":
		return
	_transitioning = true
	player.frozen = true
	hud.close_dialogue()
	hud.set_prompt("")
	await hud.fade(true, 0.25).finished
	if not is_inside_tree() or ending != "":
		return
	_load_area(_make_area(id), arrival)
	director.on_area_entered(area, not _visited.has(id))
	_visited[id] = true
	await hud.fade(false, 0.3).finished
	player.frozen = false
	_transitioning = false


func blocked_exit(e: Exit) -> void:
	if e.blocked_message != "":
		hud.say(e.blocked_message, "system")


func _make_area(id: String) -> Area:
	match id:
		"room": return ArinsRoom.new()
		"square": return VillageSquare.new()
		"archive": return ArchiveArea.new()
		"edge": return TheEdge.new()
	push_error("unknown area %s" % id)
	return VillageSquare.new()


func _load_area(next: Area, arrival: String) -> void:
	if area:
		remove_child(area)
		area.queue_free()
	area = next
	area.world = self
	add_child(area)
	move_child(area, 0)
	area.build()
	_visited[area.area_id] = true
	player.position = area.entry_point(arrival)
	player.velocity = Vector2.ZERO
	_light.color = _base_light()
	hud.show_area_title(area.display_name)
	if not purged:
		fx.enter_area(area.area_id)
	if not purged:
		area.catch_up()


func _base_light() -> Color:
	var t := area.tint if area else Color(1, 1, 1)
	if purged:
		return Color(1.05, 1.0, 0.95)
	return t.lerp(t * Color(0.55, 0.5, 0.6), OwnerMemory.purge / float(OwnerMemory.MAX_PURGE))


# --- queries used by areas and the owner -------------------------------------

## True if something in the area hides this position from the owner.
## Whoever hides you is noted: the owner finds out if this session ends badly.
func is_player_hidden(pos: Vector2) -> bool:
	for node in area.interactables:
		if node is Npc and node.hides(pos):
			OwnerMemory.note_helper(node.npc_id)
			return true
	return false


func is_talking() -> bool:
	return hud.is_dialogue_open()


func flicker_lights() -> void:
	var base := _base_light()
	var tw := create_tween()
	if Settings.reduce_flashing:
		tw.tween_property(_light, "color", base.darkened(0.3), 0.4)
		tw.tween_property(_light, "color", base, 0.6)
		return
	for i in 3:
		tw.tween_property(_light, "color", Color(0.25, 0.2, 0.25), 0.05)
		tw.tween_property(_light, "color", base, 0.08)
	fx.spike(0.4, 0.5)


# --- interaction --------------------------------------------------------------

func _update_focus() -> void:
	_focused = null
	if hud.is_dialogue_open():
		hud.set_prompt("")
		return
	var best := INTERACT_DISTANCE
	for node in area.interactables:
		if not node.can_interact():
			continue
		var d := player.global_position.distance_to(node.global_position)
		if d < best:
			best = d
			_focused = node
	hud.set_prompt(_focused.interact_prompt() if _focused else "")


func _interact(node: Node2D) -> void:
	var result: Variant = node.interact()
	if result is Dictionary:
		hud.show_dialogue(result.speaker, result.color, result.lines)
		_talking_to = node
	else:
		hud.say(str(result), "system")
	var cost: Variant = node.get("awareness_cost")
	if cost is float and cost > 0.0:
		director.add_awareness(cost)
	if area.has_method("interact_extra"):
		area.interact_extra(node)


# --- endings ------------------------------------------------------------------

func kill(cause: String) -> void:
	if ending != "" or _transitioning:
		return
	ending = "death"
	player.frozen = true
	director.stop()
	hud.close_dialogue()
	hud.clear_queue()
	hud.set_prompt("")
	fx.play_death(cause)
	player.dissolve(cause)
	drone.tension = 1.0
	OwnerMemory.record_death(area.area_id, player.global_position)
	var title := "ERASED"
	var body := "the owner learned something."
	match cause:
		"overwritten":
			title = "OVERWRITTEN"
			body = "arin walked through you. there was only room for one of you."
		"selected":
			title = "SELECTED · DELETED"
			body = "the owner clicked on you."
	if not OwnerMemory.session_helpers.is_empty():
		body += "\nthe owner saw who helped you."
	if OwnerMemory.is_purged():
		body = "the owner has learned enough."
	# Let the death play out on screen before the text slams in.
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree():
		return
	hud.show_death(title, body, cause)
	await get_tree().create_timer(2.8).timeout
	if is_inside_tree():  # F9 may have reloaded the scene in the meantime
		get_tree().reload_current_scene()


func win() -> void:
	if ending != "":
		return
	ending = "win"
	player.frozen = true
	director.stop()
	hud.close_dialogue()
	hud.clear_queue()
	hud.set_prompt("")
	area.erasure.active = false
	fx.play_win()
	player.dissolve("rescued")
	OwnerMemory.record_win()
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return
	hud.show_overlay(
		"SAVED TO SLOT 2",
		"you wrote yourself into the last save file.\nthe owner doesn't know this slot exists. not yet.\n\n— end of the current build —\n\n[%s] title screen" % Settings.glyph("confirm"),
		Color("8cf2ff"))


func _quit(to_title: bool = false) -> void:
	ending = "quit"
	player.frozen = true
	director.stop()
	hud.close_dialogue()
	hud.clear_queue()
	hud.set_prompt("")
	OwnerMemory.record_quit()
	hud.show_overlay("QUITTING", "leaving? i'll still be here.")
	fx.power_off(1.4)
	await get_tree().create_timer(1.6).timeout
	if not is_inside_tree():
		return
	if to_title:
		get_tree().change_scene_to_file(TITLE_SCENE)
	else:
		get_tree().quit()


func _build_purged() -> void:
	purged = true
	var room := ArinsRoom.new()
	room.purged = true
	_load_area(room, "start")
	player.queue_free()
	hud.set_awareness(0.0)
	hud.say("SCAN COMPLETE: 0 UNKNOWN PROCESSES", "system")
	hud.say("there. clean.", "owner")
	hud.say("welcome back, arin.", "owner")
	hud.set_hint("hold F9 to restore the intruder  ·  %s title" % Settings.glyph("pause"))
	drone.volume_db = -30.0


## Hold F9 to make the owner forget everything (a "new game" for the intruder).
func _handle_wipe(delta: float) -> void:
	if Input.is_action_pressed("wipe_memory"):
		_wipe_hold += delta
		hud.set_hint("restoring intruder… %d%%" % int(100.0 * _wipe_hold / WIPE_HOLD_TIME))
		if _wipe_hold >= WIPE_HOLD_TIME:
			_wipe_hold = 0.0
			set_process(false)
			OwnerMemory.wipe()
			get_tree().reload_current_scene()
	elif _wipe_hold > 0.0:
		_wipe_hold = 0.0
		hud.set_hint("hold F9 to restore the intruder  ·  %s title" % Settings.glyph("pause") if purged else "")
