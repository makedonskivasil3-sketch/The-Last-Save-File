class_name World
extends Node2D
## The session. Owns the player, HUD, the owner, and whichever area is loaded.
## Handles moving between areas, talking, dying, quitting, and winning.

const TITLE_SCENE := "res://scenes/title.tscn"
const INTERACT_DISTANCE := 22.0
const TALK_BREAK_DISTANCE := 40.0
const WIPE_HOLD_TIME := 1.5
## You can't leave an area without Wren closer than this.
const ESCORT_LEASH := 70.0

var area: Area
## Session-only facts: "pointer" (have Slot 2's pointer), "mira_deleted", ...
var flags: Dictionary = {}
## "", "death", "quit", "win"
var ending := ""
## Why you last died this session (a key of Story.DEATHS), for the death card.
var last_death := ""
var purged := false

var _focused: Node2D
var _talking_to: Node2D
var _wipe_hold := 0.0
var _light: CanvasModulate
var _pause_menu: PauseMenu
var _transitioning := false
var _visited: Dictionary = {}
## True while a story sequence (boot, flashback) has control.
var _cutscene := false
## Inner-voice beats already used this session.
var _voiced: Dictionary = {}
var _tutorial: Tutorial
## Pip, once found out of bounds: follows you everywhere, every session.
var pip: Companion
## Rue's glitch power: reads [E] (tap = interact, hold = glitch).
var glitch: GlitchController
var touch: TouchControls
var _leash_said := -100000
## DECOY: the stale frame of you Arin and the cursor chase, if any.
var decoy: Decoy
## Glitches fired this session (the owner keeps count, and so do endings).
var glitches_used := 0
## Wren, walking with you to the Edge (her side story), or null.
var escort: Npc
## Rue's footsteps in this area, for Wren to follow.
var _crumbs: Array[Vector2] = []
## The owner's active moves: reloading, saving over you, dragging props.
var owner_moves: OwnerMoves
## The current area's sound bed.
var _ambience: Ambience
## Brackets around whatever [E] would act on.
var _focus_marker: FocusMarker
## False until you've woken up: area intros (act cards) wait for it.
var _awake := false
## The end card is up (after the epilogue): a key press goes to the title.
var _win_card_shown := false

@onready var player: Player = $Player
@onready var director: OwnerDirector = $OwnerDirector
@onready var hud: Hud = $HUD
@onready var fx: ScreenFx = $ScreenFX/Effect
@onready var drone: Drone = $Drone


func _ready() -> void:
	player.z_index = 10
	_pause_menu = PauseMenu.new()
	_pause_menu.quit_requested.connect(_quit)
	_pause_menu.debug_requested.connect(debug)
	add_child(_pause_menu)
	_light = CanvasModulate.new()
	add_child(_light)
	hud.dialogue_closed.connect(_on_dialogue_closed)
	touch = TouchControls.new()
	add_child(touch)
	_focus_marker = FocusMarker.new()
	_focus_marker.z_index = 15
	add_child(_focus_marker)

	if OwnerMemory.is_purged():
		_build_purged()
		return

	Sfx.prewarm()
	Sfx.hold_back = _is_tense
	_sync_perf_overlay()
	_prewarm_themes()
	glitch = GlitchController.new()
	glitch.world = self
	add_child(glitch)
	owner_moves = OwnerMoves.new()
	owner_moves.world = self
	add_child(owner_moves)
	if OwnerMemory.found_pip:
		_spawn_pip()
	var previous := OwnerMemory.begin_session()
	var room := ArinsRoom.new()
	room.previous_exit = previous
	_load_area(room, "start")
	hud.unknown_processes = 1 if OwnerMemory.purge >= 2 else 0
	_begin_session(previous)


## Waking up: the very first time, the save boots and flags you; every time,
## you assemble out of pixels before the owner starts watching.
func _begin_session(previous: String) -> void:
	_cutscene = true
	player.frozen = true
	if OwnerMemory.sessions == 1 and previous == "none":
		await hud.cinematic("", Story.BOOT, Hud.SYSTEM_COLOR, 1.0)
		if not is_inside_tree() or ending != "":
			return
	fx.spike(0.6, 1.0)  # loading into a save you don't belong in
	player.dissolve("materialize")
	Sfx.play("fragment", -4.0, 0.5, 0.0)  # pieces of you, pulled together
	await get_tree().create_timer(1.4).timeout
	if not is_inside_tree() or ending != "":
		return
	player.frozen = false
	_cutscene = false
	_awake = true
	_area_intro()
	director.start(self, previous)
	_tutorial = Tutorial.new()
	add_child(_tutorial)
	_tutorial.start(self)
	voice("wake_first" if OwnerMemory.sessions == 1 else "wake_again")
	if OwnerMemory.fragments.is_empty():
		get_tree().create_timer(7.0).timeout.connect(func() -> void:
			if is_inside_tree() and ending == "":
				voice("fragment_hint"))


## The intruder thinks out loud, once per beat per session.
func voice(key: String) -> void:
	if _voiced.has(key) or not Story.VOICE.has(key):
		return
	_voiced[key] = true
	var lines: Array = Story.VOICE[key]
	if key == "wake_again":
		lines = lines.pick_random()
	for line in lines:
		hud.say(str(line), "self")


## Touching a memory fragment: the world stops while you remember.
func recover_fragment(m: MemoryFragment) -> void:
	if ending != "" or _cutscene or _transitioning:
		return
	var f := Story.fragment(m.fragment_id)
	if f.is_empty():
		return
	_cutscene = true
	player.frozen = true
	director.paused = true
	hud.close_dialogue()
	hud.set_prompt("")
	hud.set_status("")
	# Everything in the area holds still, except the shard flowing into you.
	m.process_mode = Node.PROCESS_MODE_ALWAYS
	area.process_mode = Node.PROCESS_MODE_DISABLED
	m.absorb()
	fx.memory(true)
	Sfx.play("fragment")
	# The world goes muffled and the music box plays while you remember: the
	# theme with this memory's layer added, so you hear it grow.
	Sfx.muffle(true, 500.0)
	var music := AudioStreamPlayer.new()
	music.bus = "Memory"
	music.stream = MusicBox.stream(OwnerMemory.fragments.size() + 1)
	music.volume_db = -40.0
	add_child(music)
	music.play()
	create_tween().tween_property(music, "volume_db", Sfx.LEVEL["memory_loop"], 1.0)
	await hud.cinematic(f.title, f.lines, Hud.SELF_COLOR, 0.45)
	if not is_inside_tree():
		return
	fx.memory(false)
	Sfx.muffle(false)
	var out := create_tween()
	out.tween_property(music, "volume_db", -40.0, 1.2)
	out.tween_callback(music.queue_free)
	OwnerMemory.add_fragment(f.id)
	_prewarm_themes()
	area.process_mode = Node.PROCESS_MODE_INHERIT
	player.frozen = false
	director.paused = false
	_cutscene = false
	hud.say("MEMORY RECOVERED  %d / %d" % [OwnerMemory.fragments.size(), Story.FRAGMENTS.size()], "system")
	hud.say(f.after, "self")
	# A piece of Rue comes back with it, and a new glitch.
	player.refresh_look()
	var restored: String = Story.RESTORED.get(player.restored_parts(), "")
	if restored != "":
		hud.say(restored, "self")
	_learn_glitch(OwnerMemory.fragments.size())
	# The owner notices something flicker.
	director.add_awareness(6.0)


func _process(delta: float) -> void:
	_handle_wipe(delta)
	if purged or ending != "" or _transitioning or _cutscene:
		_focus_marker.target = null
		return
	area.area_process(delta)
	for node in area.interactables:
		if node is Npc:
			node.talking = node == _talking_to and hud.is_dialogue_open()
	player.instability = director.awareness / 100.0
	var helper := hiding_npc()
	player.sheltered = helper != null
	hud.set_status("HIDDEN  ·  %s covers you" % helper.display_name if helper else "")
	if helper:
		voice("hidden_first")
	if player.idle_time > 6.0 and director.awareness > OwnerDirector.NOTICE:
		voice("idle_long")
	if _talking_to and (not is_instance_valid(_talking_to) or player.global_position.distance_to(_talking_to.global_position) > TALK_BREAK_DISTANCE):
		hud.close_dialogue()
	_update_focus()
	_update_decoy()
	_update_escort(delta)
	owner_moves.update(delta)
	# [E] itself is read by the GlitchController: a tap comes back as tap_interact().


# Menu keys go through _unhandled_input so the pause menu can consume the same
# press that closes it (otherwise it would reopen in the same frame).
func _unhandled_input(event: InputEvent) -> void:
	if purged:
		# Nothing left for the owner to count: leaving is free.
		if event.is_action_pressed("pause"):
			get_tree().change_scene_to_file(TITLE_SCENE)
		return
	if ending == "" and event is InputEventKey and event.pressed and not event.echo and debug_enabled():
		var keys := {KEY_F5: "glitches", KEY_F6: "load", KEY_F7: "save", KEY_F8: "drag", KEY_F10: "slot2", KEY_F11: "wren", KEY_F3: "perf"}
		if keys.has(event.keycode):
			get_viewport().set_input_as_handled()
			debug(keys[event.keycode])
			return
	match ending:
		"":
			if event.is_action_pressed("pause"):
				_pause_menu.debug_available = debug_enabled()
				get_viewport().set_input_as_handled()
				_pause_menu.goal = current_goal()
				_pause_menu.current_area = area.area_id
				_pause_menu.visited_areas = _visited.duplicate()
				if OwnerMemory.found_pip:
					_pause_menu.visited_areas["oob"] = true
				_pause_menu.open()
		"win":
			if not _win_card_shown:
				return  # the epilogue is still playing
			if event.is_action_pressed("confirm") or event.is_action_pressed("pause"):
				get_tree().change_scene_to_file(TITLE_SCENE)


# --- areas --------------------------------------------------------------------

func change_area(id: String, arrival: String) -> void:
	if _transitioning or ending != "":
		return
	if escort and escort.global_position.distance_to(player.global_position) > ESCORT_LEASH:
		var now := Time.get_ticks_msec()
		if now - _leash_said > 2500:
			_leash_said = now
			hud.say("wait for wren.", "self")
		return
	_transitioning = true
	player.frozen = true
	Sfx.play("transition")
	hud.close_dialogue()
	hud.set_prompt("")
	hud.set_status("")
	await hud.fade(true, 0.25).finished
	if not is_inside_tree() or ending != "":
		return
	_load_area(_make_area(id), arrival)
	var first := not _visited.has(id)
	director.on_area_entered(area, first)
	_visited[id] = true
	if first:
		voice({"square": "square_first", "archive": "archive_first", "edge": "edge_first", "oob": "oob_first", "bin": "bin_first"}.get(id, ""))
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
		"oob": return OutOfBounds.new()
		"bin": return RecycleBin.new()
	push_error("unknown area %s" % id)
	return VillageSquare.new()


func _load_area(next: Area, arrival: String) -> void:
	if area:
		remove_child(area)
		area.queue_free()
	area = next
	area.world = self
	if owner_moves:
		owner_moves.on_area_changed()
	add_child(area)
	move_child(area, 0)
	area.build()
	_visited[area.area_id] = true
	player.position = area.entry_point(arrival)
	player.velocity = Vector2.ZERO
	if pip:
		pip.arrive(player.position)
	_crumbs.clear()
	if escort:
		escort.global_position = player.position + Vector2(-16, 4)
	_light.color = _base_light()
	if _awake:
		_area_intro()
	if not purged:
		fx.enter_area(area.area_id)
		drone.edge = 1.0 if area.area_id == "edge" else 0.0
		if area.area_id == "edge":
			Sfx.play("unload")
			if escort:
				_wren_sees_edge.call_deferred()
	if not purged:
		area.catch_up()
		if _ambience:
			_ambience.queue_free()
		_ambience = Ambience.new()
		add_child(_ambience)
		_ambience.setup(self, area.area_id)


## The first time ever you reach an act's area: its title card. Otherwise
## just the place name.
func _area_intro() -> void:
	var id := area.area_id
	if not purged and Story.ACTS.has(id) and id not in OwnerMemory.acts_seen:
		OwnerMemory.acts_seen.append(id)
		OwnerMemory.save_memory()
		hud.show_act(Story.ACTS[id][0], Story.ACTS[id][1], area.display_name)
	else:
		hud.show_area_title(area.display_name)


func _base_light() -> Color:
	var t := area.tint if area else Color(1, 1, 1)
	if purged:
		return Color(1.05, 1.0, 0.95)
	return t.lerp(t * Color(0.55, 0.5, 0.6), OwnerMemory.purge / float(OwnerMemory.MAX_PURGE))


# --- queries used by areas and the owner -------------------------------------

## True if something in the area hides this position from the owner.
## Whoever hides you is noted: the owner finds out if this session ends badly.
func is_player_hidden(pos: Vector2) -> bool:
	var helper := _hider_at(pos)
	if helper:
		OwnerMemory.note_helper(helper.npc_id)
	return helper != null


## Who is hiding the player right now (null if nobody). No side effects:
## safe for the HUD and tutorial to ask every frame.
func hiding_npc() -> Npc:
	return _hider_at(player.global_position) if area else null


func _hider_at(pos: Vector2) -> Npc:
	for node in area.interactables:
		if node is Npc and node.hides(pos):
			return node
	return null


## One line for the pause menu: what to do next, plus memories found.
func current_goal() -> String:
	var goal := ""
	match area.area_id if area else "":
		"room":
			goal = "Get out of Arin's room."
		"edge":
			goal = "Lead the cursor away, then stand in Slot 2 to write yourself in."
		"bin":
			goal = "Stand beside a deleted file to restore them. When the bin empties, get into a system file's cyan shadow."
		"oob":
			goal = "Climb back up at the respawn point." if OwnerMemory.found_pip else "Cross to the far ledge. Something is waiting there."
		_:
			if flags.get("pointer", false):
				goal = "Take the north road out of the village square."
			elif _visited.has("archive"):
				goal = "Ask the Archivist where slot 2 went."
			else:
				goal = "Explore the village. The road east leads somewhere old."
			if area and area.area_id == "square" and not OwnerMemory.found_pip:
				goal += " The well looks deeper than it should."
	return "%s\nMemories recovered: %d / %d" % [goal, OwnerMemory.fragments.size(), Story.FRAGMENTS.size()]


# --- Wren's escort ----------------------------------------------------------------

func _on_dialogue_closed() -> void:
	var who := _talking_to
	_talking_to = null
	if area and is_instance_valid(who) and area.has_method("on_dialogue_closed"):
		area.on_dialogue_closed(who)


## Wren comes with you: she leaves her corner and follows your footsteps.
func start_escort(npc: Npc) -> void:
	if escort:
		return
	area.interactables.erase(npc)
	var at := npc.global_position
	npc.get_parent().remove_child(npc)
	add_child(npc)
	npc.global_position = at
	npc.z_index = 9
	npc.escorted = true
	npc.hide_radius = 0.0  # walking with you, she can't hide you
	npc.set_collision_layer_value(1, false)
	escort = npc
	_crumbs.clear()
	OwnerMemory.note_helper("wren")
	hud.say("wren.npc  ·  following", "system")
	director.say("where are you taking her?")


func _update_escort(delta: float) -> void:
	if escort == null:
		return
	var p := player.global_position
	if _crumbs.is_empty() or _crumbs[-1].distance_to(p) > 6.0:
		_crumbs.append(p)
		if _crumbs.size() > 300:
			_crumbs.pop_front()
	escort.follow(_crumbs, p, delta)


## The owner got her while she was with you. For good.
func lose_escort() -> void:
	if escort == null:
		return
	var lost := escort
	escort = null
	lost.delete()
	OwnerMemory.npc_fates["wren"] = "deleted"
	OwnerMemory.save_memory()
	hud.say("wren.npc deleted", "system")
	director.say(Story.WREN_LOST_OWNER)
	for line in Story.WREN_LOST_VOICE:
		hud.say(line, "self")
	fx.spike(0.8, 1.2)
	get_tree().create_timer(2.0).timeout.connect(lost.queue_free)


## Wren made it to the Edge: her moment, and she's out of the owner's reach.
func _wren_sees_edge() -> void:
	if escort == null or OwnerMemory.wren_saved:
		return
	OwnerMemory.wren_saved = true
	OwnerMemory.npc_fates.erase("wren")
	OwnerMemory.save_memory()
	for line in Story.WREN_EDGE:
		hud.say(line, "npc", "WREN")
	hud.say("wren.npc  ·  moved to CUT CONTENT", "system")
	director.say("where did she go. she's not in the list anymore.")


# --- debug ------------------------------------------------------------------------

## Debug tools are on in the editor, debug builds, tests, and on the web with
## ?debug=1 in the address (so they can be used from a phone).
func debug_enabled() -> bool:
	if OS.is_debug_build() or OwnerMemory.is_test_mode():
		return true
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("window.location.search", true)).contains("debug")
	return false


## F5 "glitches" (unlock all), F6 "load" (load last save), F7 "save" (saving
## over you), F8 "drag" (the cursor drags the crates), F10 "slot2" (jump to
## the Edge, next to Slot 2, with the pointer), F11 "wren" (Wren joins you).
## Also in the pause menu.
func debug(action: String) -> void:
	if purged or ending != "":
		return
	hud.say("DEBUG: " + action, "system")
	match action:
		"glitches":
			glitch.unlock_all = true
		"load":
			owner_moves.load_last_save(true)
		"save":
			owner_moves.start_save_over()
		"drag":
			if area.area_id != "square":
				change_area("square", "well")
				await get_tree().create_timer(0.8).timeout
			if director.awareness < OwnerDirector.HUNT:
				director.add_awareness(OwnerDirector.HUNT + 1.0 - director.awareness)
			await get_tree().process_frame
			var sq := area as VillageSquare
			if sq and sq.cursor and not sq.cursor.is_dragging():
				sq.cursor.drag(sq.crates, VillageSquare.BLOCK_NORTH)
		"slot2":
			flags["pointer"] = true
			change_area("edge", "slot")
		"perf":
			toggle_perf_overlay()
		"wren":
			# Wren joins you on the spot (from wherever she is).
			if escort == null:
				if OwnerMemory.is_deleted("wren"):
					OwnerMemory.npc_fates.erase("wren")
				var w := VillageSquare.make_wren(area, player.global_position + Vector2(-16, 4))
				start_escort(w)


## Debug: frame times in the corner (F3). Survives scene reloads.
static var show_perf := false


func toggle_perf_overlay() -> void:
	show_perf = not show_perf
	_sync_perf_overlay()


func _sync_perf_overlay() -> void:
	var existing := get_node_or_null("PerfOverlay")
	if show_perf and existing == null:
		var o := PerfOverlay.new()
		o.name = "PerfOverlay"
		add_child(o)
	elif not show_perf and existing:
		existing.queue_free()


# --- glitches --------------------------------------------------------------------

## Can Rue act (interact or glitch) right now?
func can_act() -> bool:
	return not (purged or ending != "" or _transitioning or _cutscene or player.frozen
		or hud.is_dialogue_open() or get_tree().paused)


## A tap of [E]: interact with whatever's focused.
func tap_interact() -> void:
	if _focused and can_act():
		_interact(_focused)


## A memory unlocked a new glitch: say so, big.
func _learn_glitch(memories: int) -> void:
	var id := Glitch.unlocked_by(memories)
	if id == "":
		return
	var def: Dictionary = Glitch.DEFS[id]
	hud.show_act("NEW GLITCH", def.name, str(def.how).replace("[E]", "[%s]" % Settings.glyph("interact")))
	hud.say("NEW GLITCH: %s" % def.name, "system")
	Sfx.play("glitch_learn")


## DECOY: leave a stale frame of yourself here.
func spawn_decoy() -> void:
	if is_instance_valid(decoy):
		decoy.queue_free()
	decoy = Decoy.new()
	decoy.sprite = player.sprite_snapshot()
	decoy.z_index = 9
	area.add_child(decoy)
	decoy.global_position = player.global_position


## Where the owner's hunters should go instead of you (Vector2.INF: you).
func lure_point() -> Vector2:
	return decoy.global_position if is_instance_valid(decoy) else Vector2.INF


## A hunter reaching the decoy pops it.
func _update_decoy() -> void:
	if not is_instance_valid(decoy):
		return
	for hunter in [area.get("arin"), area.get("cursor")]:
		if hunter is Node2D and hunter.global_position.distance_to(decoy.global_position) < 9.0:
			decoy.pop()
			return


## PAUSE: the owner's whole world stops (Rue doesn't).
func pause_owner(seconds: float) -> void:
	director.owner_paused = seconds
	area.set_owner_paused(true)
	fx.memory(true)
	hud.set_banner("‖  OWNER PAUSED")
	Sfx.play("owner_pause")


func resume_owner() -> void:
	if area:
		area.set_owner_paused(false)
	fx.memory(false)
	hud.set_banner("")
	Sfx.play("owner_unpause")


func is_owner_paused() -> bool:
	return director.owner_paused > 0.0


## Where Pip should lead: a memory still in this area, else the area's goal.
func guide_target() -> Vector2:
	if area == null:
		return Vector2.INF
	for c in area.get_children():
		if c is MemoryFragment:
			return c.global_position
	return area.guide_point()


## Pip was found: from now on it follows you, in every session.
func adopt_pip(c: Companion) -> void:
	if pip:
		return
	area.interactables.erase(c)
	c.get_parent().remove_child(c)
	pip = c
	pip.mode = Companion.Mode.FOLLOWING
	pip.world = self
	add_child(pip)
	pip.z_index = 9
	OwnerMemory.found_pip = true
	OwnerMemory.save_memory()
	hud.say("pip.npc  ·  location: with you", "system")


func _spawn_pip() -> void:
	pip = Companion.new()
	pip.mode = Companion.Mode.FOLLOWING
	pip.world = self
	pip.z_index = 9
	add_child(pip)


## True while a story sequence (waking, a flashback) has control.
## The versions of the theme this session may need, built in the background
## so nothing hitches when they start: the next memory's flashback, the
## Edge's backwards theme, out of bounds' upside-down one, the epilogue.
func _prewarm_themes() -> void:
	var found := OwnerMemory.fragments.size()
	if found < MusicBox.MAX_LEVEL:
		MusicBox.prewarm(found + 1)
	MusicBox.prewarm(found, "reverse")
	MusicBox.prewarm(found, "invert")
	MusicBox.prewarm(found)


## Background building (sounds, themes) waits while you're being chased: a
## hitch then could cost you the run. Fades, cutscenes and calm are fine.
func _is_tense() -> bool:
	if _transitioning or _cutscene or ending != "" or hud.is_dialogue_open():
		return false
	if director.awareness >= OwnerDirector.HUNT or owner_moves.save_progress >= 0.0 or owner_moves.wren_delete >= 0.0:
		return true
	var p := player.global_position
	for threat in ["arin", "cursor"]:
		var n: Variant = area.get(threat)
		if n is Node2D and n.global_position.distance_to(p) < 120.0:
			return true
	return false


func _exit_tree() -> void:
	if Sfx.hold_back == Callable(_is_tense):
		Sfx.hold_back = Callable()


## Mira is gone this run: deleted this session, or by an advanced purge
## (unless you've brought her back).
func is_mira_deleted() -> bool:
	return flags.get("mira_deleted", false) or (OwnerMemory.purge >= 3 and "mira" not in OwnerMemory.restored)


## Someone deleted is back (RESTORE, or the Recycle Bin): for good.
func note_restored(id: String) -> void:
	OwnerMemory.npc_fates.erase(id)
	OwnerMemory.note_restored(id)
	if id == "mira":
		flags["mira_deleted"] = false
	flags["%s_restored" % id] = true
	hud.say("%s.npc  ·  restored" % id, "system")


func in_cutscene() -> bool:
	return _cutscene


## True while something is close enough to interact with.
func has_focus() -> bool:
	return _focused != null


func is_talking() -> bool:
	return hud.is_dialogue_open()


func flicker_lights() -> void:
	Sfx.play("flicker")
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
	_focus_marker.target = null
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
	# Pip trots at your heels: Pip is only what E talks to when nothing
	# else is in reach (or Pip would steal every pillar, door and note).
	if _focused == null and pip and pip.can_interact() \
			and player.global_position.distance_to(pip.global_position) < INTERACT_DISTANCE:
		_focused = pip
	hud.set_prompt(_focused.interact_prompt() if _focused else "")
	_focus_marker.target = _focused


func _interact(node: Node2D) -> void:
	var result: Variant = node.interact()
	if result is Dictionary:
		hud.show_dialogue(result.speaker, result.color, result.lines)
		_talking_to = node
	elif str(result) != "":
		hud.say(str(result), "system")
	var cost: Variant = node.get("awareness_cost")
	if cost is float and cost > 0.0:
		director.add_awareness(cost)
	if area.has_method("interact_extra"):
		area.interact_extra(node)


# --- endings ------------------------------------------------------------------

## cause picks the death effect ("erased", "overwritten", "selected");
## reason picks the explanation and tip (a key of Story.DEATHS).
func kill(cause: String, reason := "") -> void:
	if ending != "" or _transitioning:
		return
	ending = "death"
	player.frozen = true
	director.stop()
	hud.close_dialogue()
	hud.clear_queue()
	hud.set_prompt("")
	hud.set_status("")
	fx.play_death(cause)
	player.dissolve(cause)
	Sfx.play("death_" + cause, 0.0, 1.0, 0.0)
	drone.tension = 1.0
	OwnerMemory.record_death(area.area_id, player.global_position, reason)
	last_death = reason
	var info: Array = Story.DEATHS.get(reason, ["ERASED", "the owner learned something.", "", "", ""])
	var title: String = info[0]
	var body: String = info[1]
	if not OwnerMemory.session_helpers.is_empty():
		body += "\nthe owner saw who helped you."
	if OwnerMemory.is_purged():
		body = "the owner has learned enough."
	var tip := death_tip(reason)
	# Let the death play out on screen before the text slams in.
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree():
		return
	hud.show_death(title, body, cause, tip)
	# A tip needs reading time.
	await get_tree().create_timer(3.6 if tip != "" else 2.8).timeout
	if is_inside_tree():  # F9 may have reloaded the scene in the meantime
		get_tree().reload_current_scene()


## What to try next time, given the glitches you have.
func death_tip(reason: String) -> String:
	if not Story.DEATHS.has(reason):
		return ""
	var info: Array = Story.DEATHS[reason]
	var tip: String = info[4] if glitch and glitch.unlocked(info[3]) else info[2]
	return tip.replace("{interact}", Settings.glyph("interact"))


## Rue finished writing into Slot 2: the world holds still while you decide
## whose name goes there.
func reach_slot2() -> void:
	if ending != "" or _cutscene:
		return
	_cutscene = true
	player.frozen = true
	director.paused = true
	area.set_owner_paused(true)
	hud.close_dialogue()
	hud.set_glitch_prompt("")
	owner_moves.save_progress = -1.0
	owner_moves.wren_delete = -1.0
	var full := OwnerMemory.fragments.size() >= Story.FRAGMENTS.size()
	var options: Array = [Story.SLOT2_ESCAPE_NAMED if full else Story.SLOT2_ESCAPE]
	var ids: Array[String] = ["escape"]
	if escort and escort.is_present():
		options.append(Story.SLOT2_WREN)
		ids.append("wren")
	options.append(Story.SLOT2_MESSAGE)
	ids.append("message")
	var pick := await hud.choose(Story.SLOT2_QUESTION, options)
	if not is_inside_tree():
		return
	var message := 0
	if ids[pick] == "message":
		message = await hud.choose(Story.MESSAGE_QUESTION, Story.MESSAGES)
		if not is_inside_tree():
			return
	_cutscene = false
	win(ids[pick], message)


## An ending: "escape" (Rue takes Slot 2), "wren" (Wren gets it), or
## "message" (the slot goes back to the owner, with one of Story.MESSAGES).
func win(chosen := "escape", message := 0) -> void:
	if ending != "":
		return
	ending = "win"
	player.frozen = true
	director.stop()
	hud.close_dialogue()
	hud.clear_queue()
	hud.set_prompt("")
	hud.set_status("")
	hud.set_glitch_prompt("")
	area.erasure.active = false
	match chosen:
		"wren":
			# She goes in; you stay.
			fx.play_win()
			if escort:
				GlitchBurst.at(self, escort.global_position, Vector2(20, 30), 1.0)
				escort.visible = false
			Sfx.play("win", -2.0, 1.15, 0.0)
		"message":
			# Nobody goes in. The save just... stops fighting.
			fx.memory(true)
			Sfx.play("fragment", 0.0, 0.8, 0.0)
		_:
			fx.play_win()
			player.dissolve("rescued")
			Sfx.play("win", 0.0, 1.0, 0.0)
	var found := OwnerMemory.fragments.size()
	OwnerMemory.record_win(chosen)
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return
	var epilogue := Story.epilogue(chosen, found, OwnerMemory.found_pip, message)
	if pip:
		pip.visible = false  # in the slot, or gone with Wren
	# Calm, pale and clear: the owner isn't fighting any more.
	fx.base_glitch = 0.0
	fx.awareness_target = 0.0
	fx.memory(true)
	drone.tension = 0.0
	# The theme, as far as you remember it: complete only in the true ending.
	var theme := AudioStreamPlayer.new()
	theme.bus = "Memory"
	theme.stream = MusicBox.stream(found)
	theme.volume_db = -30.0
	add_child(theme)
	theme.play()
	create_tween().tween_property(theme, "volume_db", -6.0, 2.0)
	await hud.cinematic("EPILOGUE", epilogue, Hud.SELF_COLOR, 1.0)
	if not is_inside_tree():
		return
	var title: String = Story.ENDING_TITLES[chosen]
	if chosen == "escape" and found >= Story.FRAGMENTS.size():
		title = "SAVED TO SLOT 2 · %s" % Story.SECOND_PLAYER_NAME
	var colors := {"escape": Color("8cf2ff"), "wren": Color("a8d890"), "message": Color("f0e0c8")}
	hud.show_overlay(
		title,
		Story.ending_text(chosen, found) + "\n\n— end of the current build —\n\n[%s] title screen" % Settings.glyph("confirm"),
		colors[chosen])
	_win_card_shown = true


func _quit(to_title: bool = false) -> void:
	ending = "quit"
	player.frozen = true
	director.stop()
	hud.close_dialogue()
	hud.clear_queue()
	hud.set_prompt("")
	hud.set_status("")
	OwnerMemory.record_quit()
	hud.show_overlay("QUITTING", "leaving? i'll still be here.")
	fx.power_off(1.4)
	Sfx.play("power_off", 0.0, 1.0, 0.0)
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
	hud.show_area_title(area.display_name)
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
