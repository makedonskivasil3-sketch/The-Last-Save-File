class_name World
extends Node2D

## The session. Owns the player, HUD, the owner, and whichever area is loaded.
## Handles moving between areas, talking, dying, quitting, and winning.

## A conversation with `node` (a person, a book, a file) was read to its
## last line. Progress that needs the whole text waits for this.
signal conversation_completed(node: Node)

const TITLE_SCENE := "res://scenes/title.tscn"
const INTERACT_DISTANCE := 22.0
const TALK_BREAK_DISTANCE := 40.0
## How long a death card ignores input before it offers a retry: the first
## time a cause kills you, and after that.
const RETRY_LOCK := 1.2
const RETRY_LOCK_REPEAT := 0.5
const WIPE_HOLD_TIME := 1.5
## The purge ending: seconds of quiet before its card and buttons appear.
const PURGED_CARD_DELAY := 4.0
## You can't leave an area without Wren closer than this.
const ESCORT_LEASH := 70.0

var area: Area
## Session-only facts: "pointer" (have Slot 2's pointer), "mira_deleted", ...
var flags: Dictionary = {}
## "", "death", "quit", "suspend" (save and exit), "win", "demo" (the demo build's end card)
var ending := ""
## Development benchmark only (tests/tour_benchmark.gd): Rue can't be killed,
## so a pursuit sample is never a death card. Never set in play.
var bench_immune := false
## Why you last died this session (a key of Story.DEATHS), for the death card.
var last_death := ""
var purged := false

var _focused: Node2D
var _talking_to: Node2D
## What _talking_to said (Npc.interact): its conversation id and the events
## it commits once read to the end.
var _talk_result: Dictionary = {}
var _wipe_hold := 0.0
var _light: CanvasModulate
var _pause_menu: PauseMenu
var _transitioning := false
var _visited: Dictionary = {}
## True while a story sequence (boot, flashback) has control.
var _cutscene := false
## True while choose_safely() holds the owner for a question.
var _choice_hold := false
## A conversation is open: the owner holds still while Rue reads (_update_reading_hold).
var _reading_hold := false
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
	Sfx.reset_scene_state()  # nothing muffled or ducked carries in from the last scene
	ArchivePages.escort_now = ""  # escorts never carry over into a new session
	# The Archivist's pointer to Slot 2 is kept in the save once given: the
	# north road isn't an errand to repeat every run.
	flags["pointer"] = OwnerMemory.met_archivist
	player.z_index = 10
	_pause_menu = PauseMenu.new()
	_pause_menu.console_hud = hud
	_pause_menu.quit_requested.connect(_quit)
	_pause_menu.suspend_handler = try_suspend
	_pause_menu.report_provider = problem_report
	OwnerMemory.safe_close = _close_safely
	_pause_menu.debug_requested.connect(debug)
	add_child(_pause_menu)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	var takeover := _Takeover.new()
	takeover.world = self
	add_child(takeover)
	_light = CanvasModulate.new()
	add_child(_light)
	hud.dialogue_closed.connect(_on_dialogue_closed)
	hud.line_revealed.connect(_on_line_revealed)
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
	var previous := OwnerMemory.begin_session(true)
	var resume := suspend_start(previous)
	var start := anchor_start(previous)
	if not resume.is_empty():
		var back := _make_area(resume.area)
		if back is ArinsRoom:
			(back as ArinsRoom).previous_exit = previous
		_load_area(back, "start")
		_resume_at(resume)
	elif start.is_empty():
		var room := ArinsRoom.new()
		room.previous_exit = previous
		_load_area(room, "start")
	else:
		_load_area(_make_area(start[0]), start[1])
		woke_at_anchor = true
	hud.unknown_processes = 1 if OwnerMemory.purge >= 2 else 0
	_begin_session(previous)


## Waking up: the very first time, the save boots and flags you; every time,
## you assemble out of pixels before the owner starts watching.
func _begin_session(previous: String) -> void:
	PlaytestLog.mark("session %d started" % OwnerMemory.sessions, "purge %d/%d, last exit: %s, owner pace: %s, %s" % [OwnerMemory.purge, OwnerMemory.MAX_PURGE, previous, "gentle" if Settings.owner_pace == 1 else "normal", BuildInfo.stamp()])
	_cutscene = true
	player.frozen = true
	# The boot log, unless the festival just showed its own (in the square).
	if OwnerMemory.sessions == 1 and previous == "none" and not Prologue.take_boot_shown():
		await hud.cinematic("", Story.BOOT, Hud.SYSTEM_COLOR, 1.0, "boot")
		if not is_inside_tree() or ending != "":
			return
	if woke_from_suspend:
		await _settle_resume()  # before she can move: never inside something rebuilt
		if not is_inside_tree() or ending != "":
			return
	# Back after a real break: where she was and what she was doing, before
	# anything moves (docs/prompts/NEXT_PASS_2026-10-29.md §1).
	var recap := previously()
	if not recap.is_empty():
		await hud.cinematic("PREVIOUSLY", recap, Hud.SELF_COLOR, 0.8)
		if not is_inside_tree() or ending != "":
			return
	fx.spike(0.6, 1.0)  # loading into a save you don't belong in
	player.dissolve("materialize")
	Sfx.play("fragment", -4.0, 0.5, 0.0)  # pieces of you, pulled together
	await get_tree().create_timer(1.4 if OwnerMemory.sessions == 1 else 0.45).timeout
	if not is_inside_tree() or ending != "":
		return
	player.frozen = false
	_cutscene = false
	_awake = true
	# The first run: "you" over her (the opening's figure, the same one),
	# whether the film was watched or skipped. Gone at the first step.
	player.you_cue = OwnerMemory.sessions == 1
	if pip and OwnerMemory.sessions > 1:
		pip.greet()  # back with her
	OwnerMemory.arm_session()  # play starts now: quits and crashes count from here
	_area_intro()
	director.start(self, previous)
	_tutorial = Tutorial.new()
	add_child(_tutorial)
	_tutorial.start(self)
	if woke_from_suspend:
		hud.say(SUSPEND_WAKE, "self")
		if _resumed_escort != "":
			hud.say("(%s went home while i was gone. we can still go.)" % _resumed_escort, "self")
	elif woke_at_anchor:
		hud.say(WellSequence.ANCHOR_NOTE, "self")
	else:
		voice("wake_first" if OwnerMemory.sessions == 1 else "wake_again")
	var door: Variant = area.get("door")
	if area.area_id == "room" and door is Door and door.state == Door.State.DELETED:
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if is_inside_tree() and ending == "" and area.area_id == "room":
				voice("door_gone"))
	if OwnerMemory.fragments.is_empty():
		get_tree().create_timer(7.0).timeout.connect(func() -> void:
			if is_inside_tree() and ending == "":
				voice("fragment_hint"))


## The text "Report a problem" copies: what build, where, what Rue was
## doing, the settings that change play, and the last console lines. No
## names, paths or anything about the player's machine beyond the platform.
func problem_report() -> String:
	var lines: Array[String] = ["THE LAST SAVE FILE · problem report", BuildInfo.stamp(),
		"platform: %s" % OS.get_name(),
		"area: %s at (%d, %d)" % [area.area_id if area else "?", int(player.global_position.x) if player else 0, int(player.global_position.y) if player else 0],
		"session %d · purge %d/%d · awareness %d" % [OwnerMemory.sessions, OwnerMemory.purge, OwnerMemory.MAX_PURGE, int(director.awareness) if director else 0],
		"goal: %s" % current_goal(),
		"with: %s%s" % [escort.display_name if escort else "nobody", " + Pip" if OwnerMemory.found_pip else ""],
		"settings: movement %s · owner pace %s · reduce motion %s · reduce flashing %s · text %s" % [MoveFeel.current(), "gentle" if Settings.owner_pace == 1 else "normal", Settings.reduce_motion, Settings.reduce_flashing, "large" if Settings.large_text else "normal"],
		"", "last lines:"]
	var recent: Array = hud.history.slice(maxi(0, hud.history.size() - 40))
	for e: Dictionary in recent:
		lines.append("  " + str(e.get("text", "")).replace("\n", " "))
	if PlaytestLog.enabled():
		lines.append("")
		lines.append("playtest log:")
		for l in PlaytestLog.lines.slice(maxi(0, PlaytestLog.lines.size() - 40)):
			lines.append("  " + l)
	return "\n".join(lines)


## "Previously" after this long away (seconds).
const RECAP_AFTER := 20.0 * 60.0
var _recapped := false


## The recap for a player coming back after RECAP_AFTER: the goal, the last
## two things she read or heard, and who is with her. Only what the player
## has seen (the journal holds nothing else). Empty when not due: a first
## run, a quick retry, or already shown this launch.
func previously() -> Array:
	if _recapped or OwnerMemory.sessions <= 1 or OwnerMemory.away_seconds < RECAP_AFTER or OwnerMemory.journal.is_empty():
		return []
	_recapped = true
	var lines: Array = []
	var goal := current_goal()
	if goal != "":
		lines.append("(where i was: %s)" % goal.to_lower().trim_suffix("."))
	var seen: Array = []
	for i in range(OwnerMemory.journal.size() - 1, -1, -1):
		var e: Dictionary = OwnerMemory.journal[i]
		if str(e.get("title", "")) != "" and e.get("lines", []).size() > 0:
			seen.append(e)
		if seen.size() == 2:
			break
	for e: Dictionary in seen:
		lines.append("%s: \"%s\"" % [str(e.title).to_upper(), str(e.lines[0]).left(90)])
	var with: Array[String] = []
	if escort:
		with.append(escort.display_name.capitalize())
	if OwnerMemory.found_pip:
		with.append("Pip")
	if not with.is_empty():
		lines.append("(with me: %s.)" % " and ".join(with))
	PlaytestLog.mark("previously shown", "away %d min" % int(OwnerMemory.away_seconds / 60.0))
	return lines


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
	PlaytestLog.mark("memory touched", m.fragment_id + (" (the planted one)" if m.planted else ""))
	if ending != "" or _cutscene or _transitioning:
		return
	var planted := m.fragment_id == Story.FALSE_FRAGMENT.id
	var f: Dictionary = Story.FALSE_FRAGMENT if planted else Story.fragment(m.fragment_id)
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
	Sfx.muffle(true, 500.0, "memory")
	var music := AudioStreamPlayer.new()
	music.bus = "Memory"
	# The owner's version plays the theme upside down.
	music.stream = MusicBox.stream(OwnerMemory.fragments.size(), "invert") if planted else MusicBox.stream(mini(OwnerMemory.fragments.size() + 1, MusicBox.MAX_LEVEL - 1))
	music.volume_db = -40.0
	add_child(music)
	music.play()
	create_tween().tween_property(music, "volume_db", Sfx.LEVEL["memory_loop"], 1.0)
	# Rue's face, as much of it as is back: remembering, or afraid of the
	# memory that isn't hers.
	var face := CharacterArt.rue("afraid" if planted else "remembering", player.palette())
	await hud.cinematic(f.title, f.lines, Color("ffb0a0") if planted else Hud.SELF_COLOR, 0.45, "memory." + f.id, face, f.get("replay", ""))
	if not is_inside_tree() or ending != "":
		return  # the run ended during the scene: nothing here is kept
	# Kept only once it has been lived through: quitting mid-memory changes
	# nothing (no fragment, no journal entry), so the next run is coherent.
	if planted:
		OwnerMemory.record_read("memory:" + f.id, "memory", f.title, area.display_name, f.lines)
	else:
		# The fragment and its journal page are one save: no crash between
		# two writes can leave one without the other.
		OwnerMemory.keep_memory(f.id, f.title, area.display_name, f.lines)
	fx.memory(false)
	Sfx.muffle(false, 700.0, "memory")
	var out := create_tween()
	out.tween_property(music, "volume_db", -40.0, 1.2)
	out.tween_callback(music.queue_free)
	if planted:
		_took_false_memory(f)
		return
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
	director.notice(6.0, "a memory flickered")


## Rue read her CHARACTER FILE whole (docs/DARK_TRUTH_DESIGN.md): the world
## stops while she understands what she is. Kept once it has been lived
## through, like a memory.
func reveal_truth() -> void:
	if OwnerMemory.knows_truth or ending != "" or _cutscene or _transitioning or not Story.truth_ready():
		return
	PlaytestLog.mark("the truth", "read the CHARACTER FILE whole", true)
	_cutscene = true
	player.frozen = true
	director.paused = true
	hud.set_prompt("")
	fx.memory(true)
	Sfx.play("fragment", -2.0, 0.6, 0.0)
	Sfx.muffle(true, 500.0, "memory")
	await hud.cinematic("WHO I AM", Story.TRUTH_REVEAL, Hud.SELF_COLOR, 0.6, "truth.reveal", CharacterArt.rue("remembering", player.palette()))
	if not is_inside_tree() or ending != "":
		return  # the run ended during the scene: nothing here is kept
	# The page and the truth are one save, like a memory.
	OwnerMemory.record_read("truth:reveal", "memory", "WHO I AM", area.display_name, Story.TRUTH_REVEAL, false)
	OwnerMemory.learn_truth()
	fx.memory(false)
	Sfx.muffle(false, 700.0, "memory")
	player.frozen = false
	director.paused = false
	_cutscene = false
	hud.say(Story.TRUTH_AFTER, "self")


# --- leaving a body (docs/DARK_TRUTH_DESIGN.md, layer B) -----------------------

## Bodies left this run.
var sheds_this_run := 0
var _pip_refused := false
var _archivist_tried := false
var _all_frayed_now := false


## Whether holding [E] beside `npc` offers LEAVE THIS BODY: Rue knows what she
## is, they still have their piece (or it's the Archivist, who has nothing
## to take and says so), she hasn't done it too often this run, and the owner
## isn't looking: not hunting, no save ring, Arin's eyes not on her.
func can_shed(npc: Node) -> bool:
	if not (npc is Npc) or not OwnerMemory.knows_truth or ending != "" or _cutscene:
		return false
	if not npc.is_present():
		return false
	if npc.npc_id == "archivist":
		return not _archivist_tried  # he says it once; then the hold is the glitch again
	if npc.npc_id not in Story.SHED_TARGETS or npc.is_frayed() or sheds_this_run >= Story.SHED_MAX_PER_RUN:
		return false
	if director.awareness >= OwnerDirector.HUNT or owner_moves.save_progress >= 0.0:
		return false
	var arin: Variant = area.get("arin")
	if arin is OwnerAvatar and arin.can_see(player.global_position):
		return false
	return true


## The hold finished: say what it costs, then ask. Nothing happens until she
## chooses (the question holds the owner).
func offer_shed(npc: Npc) -> void:
	if not can_shed(npc):
		return
	if npc.npc_id == "archivist":
		_archivist_tried = true
		hud.show_dialogue(npc.display_name, npc.name_color, [Story.ARCHIVIST_NOTHING_TO_TAKE], "npc.archivist")
		return
	if pip and pip.visible and pip.global_position.distance_to(player.global_position) < 80.0 and not _pip_refused:
		_pip_refused = true
		hud.say(Story.PIP_REFUSE, "self")
	_cutscene = true
	player.frozen = true
	# The irreversible answer is never the one already selected.
	var pick := await choose_safely(Story.shed_preview(npc.npc_id), Story.shed_options(npc.npc_id), 1)
	if not is_inside_tree():
		return
	_cutscene = false
	if ending != "":
		return  # the run ended with the question open: nothing is taken
	player.frozen = false
	if pick == 0 and is_instance_valid(npc):
		_shed(npc)


func _shed(npc: Npc) -> void:
	var who := npc.npc_id
	PlaytestLog.mark("left a body", "took %s's %s" % [who, Story.SHED_PIECE[who]], true)
	# The body she leaves, where she stood, a step away from the person she
	# took from (so the prompt stays on them). It stays this run and the next.
	var away := (player.global_position - npc.global_position).normalized()
	var at := area.to_local(husk_spot(player.global_position, away if away != Vector2.ZERO else Vector2.DOWN, npc.global_position))
	area.place_husk(at)
	if OwnerMemory.frayed.size() + 1 >= Story.SHED_TARGETS.size() and who not in OwnerMemory.frayed \
			and "all_frayed" not in OwnerMemory.shed_said:
		OwnerMemory.shed_said.append("all_frayed")  # saved with the fray, one write
		_all_frayed_now = true
	OwnerMemory.fray(who, area.area_id, at)
	area.relearn_owner_routes()  # forgotten now, not only next run
	sheds_this_run += 1
	director.awareness = maxf(director.floor_level(), director.awareness - Story.SHED_COOL)
	director.add_awareness(0.0)  # refresh the meter and the mood
	npc.refresh_fray()
	player.refresh_look()
	GlitchBurst.at(self, player.global_position, Vector2(18, 28), 0.6)
	fx.noise(0.5, 0.4)
	Sfx.play("unload", -4.0, 0.8, 0.0)
	# What they say as it's taken, and what she thinks.
	hud.show_dialogue(Story.TOBBEN_WRITTEN if who == "tobben" else npc.display_name, npc.name_color, Story.FRAY_TAKEN[who],
		"" if who == "tobben" else "npc." + who, CharacterArt.for_npc(npc), World.expressions_for(npc, Story.FRAY_TAKEN[who]))
	hud.say(Story.shed_thought(who, OwnerMemory.sheds, OwnerMemory.frayed.size()), "self")
	# The owner notices the walk, then the damage.
	director.say(Story.OWNER_SECOND_SHED if sheds_this_run >= 2 else Story.OWNER_NEW_FACE)
	director.say(Story.OWNER_FRAYED[who])
	if _all_frayed_now:
		_all_frayed_now = false
		director.say(Story.OWNER_ALL_FRAYED)


## Where the body she leaves can lie: a step away from her helper, on open
## floor inside the area (not in a wall, furniture, a doorway gap or off the
## edge), so it can be seen and walked to. Tries the step she'd take first,
## then around her; else where she stood.
func husk_spot(from: Vector2, away: Vector2, helper: Vector2) -> Vector2:
	for dist: float in [16.0, 12.0]:
		for turn: float in [0.0, 45.0, -45.0, 90.0, -90.0, 135.0, -135.0, 180.0]:
			var q := from + away.rotated(deg_to_rad(turn)) * dist
			if husk_spot_ok(q, helper):
				return q
	return from


func husk_spot_ok(q: Vector2, helper: Vector2) -> bool:
	if area == null or not area.bounds.grow(-10.0).has_point(q) or q.distance_to(helper) < 10.0:
		return false
	if area.has_method("floor_at") and not area.floor_at(q):
		return false
	var params := PhysicsPointQueryParameters2D.new()
	params.position = q
	params.collision_mask = player.collision_mask
	params.exclude = [player.get_rid()]
	return get_world_2d().direct_space_state.intersect_point(params, 1).is_empty()


## The owner's planted memory: it doesn't count, and it costs you.
func _took_false_memory(f: Dictionary) -> void:
	OwnerMemory.false_memory_taken = true
	OwnerMemory.save_memory()
	area.process_mode = Node.PROCESS_MODE_INHERIT
	player.frozen = false
	director.paused = false
	_cutscene = false
	fx.spike(0.8 * Settings.flash_scale(), 0.8)
	Sfx.play("denied", 0.0, 0.7)
	hud.say("MEMORY REJECTED  ·  NO SIGNATURE", "system")
	hud.say(f.after, "self")
	director.say("that's how i remember it.")
	director.notice(20.0, "took the planted memory")
	owner_moves.start_save_over()


## For the browser check: is the run playable yet, and where is Rue (WebState).
var _web_tick := 0.0


## The slowest frame since the last publish (ms), for the startup timing.
var _web_slowest := 0.0


## Game time (summed frame deltas) since the session began, against the
## wall clock: if the engine clamps long frames, game time falls behind.
var _web_game_ms := 0.0
var _web_wall0 := -1


func _publish_web_state(delta: float) -> void:
	_web_slowest = maxf(_web_slowest, delta * 1000.0)
	_web_game_ms += delta * 1000.0
	if _web_wall0 < 0:
		_web_wall0 = Time.get_ticks_msec()
	_web_tick -= delta
	if _web_tick > 0.0 or not OS.has_feature("web"):
		return
	_web_tick = 0.5
	var playable := ending == "" and not player.frozen and not _cutscene and not hud.is_cinematic() and area != null
	# "reading": text is open that a press of E moves on (the browser check
	# presses E only then, instead of pressing into the world's interactions).
	var reading := hud.is_cinematic() or hud.is_dialogue_open() or hud.is_choosing()
	# What is holding play, if anything (the check logs it: a slow machine
	# and a stuck state look the same from outside otherwise).
	var hold := "" if playable else ("ending" if ending != "" else ("cinematic" if hud.is_cinematic() else ("cutscene" if _cutscene else "frozen")))
	var slowest := roundi(_web_slowest)
	_web_slowest = 0.0
	WebState.publish({"scene": "game", "playable": playable, "reading": reading, "hold": hold, "awake": _awake, "slowest_ms": slowest,
		"sfx_busy": Sfx.is_busy(), "game_ms": roundi(_web_game_ms), "wall_ms": Time.get_ticks_msec() - _web_wall0,
		"area": area.area_id if area else "", "stop": suspend_blocker(), "persistent": OwnerMemory.storage_persistent(),
		"x": snappedf(player.global_position.x, 0.1), "y": snappedf(player.global_position.y, 0.1)})


func _process(delta: float) -> void:
	update_camera(delta)
	_observe_t -= delta
	if _observe_t <= 0.0:
		_observe_t = OBSERVE_EVERY
		_observe_in_view()
	_publish_web_state(delta)
	_handle_wipe(delta)
	# Before anything returns early: a scene holds the owner like a question
	# does (the cursor, the erasure and Arin wait), whichever scene it is.
	if ending == "" and not purged and area:
		_update_reading_hold()
	if purged or ending != "" or _transitioning or _cutscene:
		_focus_marker.target = null
		return
	area.area_process(delta)
	_update_objective()
	for node in area.interactables:
		if node is Npc:
			node.talking = node == _talking_to and hud.is_dialogue_open()
			node.speaking = node.talking and hud.dialogue_is_speaking()
	player.instability = director.awareness / 100.0
	if player.velocity.length() > 1.0:
		PlaytestLog.mark("first movement", "", true)
		player.you_cue = false
	var cursor: Variant = area.get("cursor")
	var watcher: Variant = area.get("arin")
	_mark_offscreen([watcher, cursor])
	player.set_targeted((cursor is OwnerCursor and cursor.is_selecting()) or (watcher is OwnerAvatar and watcher.is_seeing()))
	# Reading or answering isn't "standing still" for the owner's save-over.
	player.reading = hud.is_dialogue_open() or hud.is_choosing()
	# Reading a tip, a card, or lines the console is still delivering (the
	# owner's note at the start of a run) is not standing still either.
	player.reading_card = hud.is_tip_shown() or hud.is_act_shown() or hud.is_console_busy()
	_update_reading_hold()
	var helper := hiding_npc()
	player.sheltered = is_hidden_now()
	if player.sheltered and not Relationships.has("wren.sheltered"):
		var hider := hiding_npc()
		if hider and hider.npc_id == "wren":
			Relationships.add("wren.sheltered")
	if helper:
		hud.set_status("HIDDEN  ·  %s covers you" % helper.display_name)
	else:
		var label: String = area.hide_label() if area.has_method("hide_label") and area.hides_player(player.global_position) else ""
		hud.set_status(("HIDDEN  ·  " + label if label != "" else "HIDDEN") if player.sheltered else "")
	if helper:
		voice("hidden_first")
	if player.idle_time > OwnerDirector.IDLE_WARN and director.awareness > OwnerDirector.NOTICE:
		voice("idle_long")
	if _talking_to and (not is_instance_valid(_talking_to) or player.global_position.distance_to(_talking_to.global_position) > TALK_BREAK_DISTANCE):
		hud.close_dialogue()
	_update_focus()
	_update_decoy()
	_update_escort(delta)
	_update_safe_mark(delta)
	owner_moves.update(delta)
	_check_portrait()
	# [E] itself is read by the GlitchController: a tap comes back as tap_interact().


## Open the pause menu with what it shows (goal, map, debug).
func open_pause() -> void:
	_pause_menu.debug_available = debug_enabled()
	_pause_menu.suspend_blocked = suspend_blocker()
	_pause_menu.goal = current_goal()
	var map := map_state()
	_pause_menu.current_area = map.current
	_pause_menu.visited_areas = map.visited
	_pause_menu.discovered_areas = map.discovered
	_pause_menu.closed_areas = map.closed
	_pause_menu.open()


## What the map shows (MapView): where Rue is, where she has been this run,
## everywhere she has found in any run, and which found places have no way
## in right now (and why). Never a place she hasn't found.
func map_state() -> Dictionary:
	var discovered := {}
	for id in OwnerMemory.places:
		discovered[id] = true
	var closed := {}
	if area and area.area_id != "room":
		closed["room"] = "no way back in"  # Arin's front door locks behind you
	if not flags.get("pointer", false):
		closed["edge"] = "not loaded"
	if not (glitch and glitch.unlocked("unlock")) and not (area and area.area_id == "house"):
		closed["house"] = "locked"
	return {"current": area.area_id if area else "", "visited": _visited.duplicate(), "discovered": discovered, "closed": closed}


# --- the camera (docs/VERTICAL_SLICE.md §3c) --------------------------------

## The view's top-left in area coordinates (0,0 for a one-screen area).
var view_offset := Vector2.ZERO
## Rue may move this far either side of the view's centre before it follows.
const CAMERA_DEADZONE := 60.0
## How quickly the view catches up (per second; no overshoot).
const CAMERA_RATE := 5.0
## Reduce motion: the view never pans; it cuts between fixed framings when
## Rue gets this close to its edge.
const CAMERA_CUT_MARGIN := 96.0


## Follows Rue across an area wider than the screen, inside its painted
## limits (Area.view_size). Never pans while the owner holds the scene, and
## threats outside the view are marked at the screen edge (Hud).
func update_camera(delta: float, snap := false) -> void:
	if area == null or not is_instance_valid(player):
		return
	var screen := Area.BACKDROP_SIZE
	var limit := maxf(0.0, area.view_size.x - screen.x)
	var x := view_offset.x
	if limit <= 0.0:
		x = 0.0
	elif Settings.reduce_motion:
		# Fixed framings, a screen apart, overlapping at the middle.
		var framings := [0.0, limit]
		var rel := player.global_position.x - x
		if snap or rel < CAMERA_CUT_MARGIN or rel > screen.x - CAMERA_CUT_MARGIN or not (x in framings):
			x = framings[0] if absf(player.global_position.x - (framings[0] + screen.x * 0.5)) <= absf(player.global_position.x - (framings[1] + screen.x * 0.5)) else framings[1]
	else:
		var centre := x + screen.x * 0.5
		var want := x
		var off := player.global_position.x - centre
		if absf(off) > CAMERA_DEADZONE:
			want = x + off - signf(off) * CAMERA_DEADZONE
		want = clampf(want, 0.0, limit)
		if snap:
			x = clampf(player.global_position.x - screen.x * 0.5, 0.0, limit)
		else:
			x = lerpf(x, want, 1.0 - exp(-CAMERA_RATE * delta))
			if absf(x - want) < 0.25:
				x = want
	view_offset = Vector2(x, 0.0)
	if fx:
		fx.view_offset = view_offset
	if snap and fx:
		get_viewport().canvas_transform = Transform2D(0.0, -view_offset.round())


## The owner's hands outside the view get an arrow at that edge (Hud).
func _mark_offscreen(threats: Array) -> void:
	var marks := []
	var view := view_rect()
	for t: Variant in threats:
		if not (t is Node2D) or not is_instance_valid(t) or not (t as Node2D).visible:
			continue
		var p: Vector2 = (t as Node2D).global_position
		if p.x < view.position.x - 4.0 or p.x > view.end.x + 4.0:
			marks.append({"side": -1 if p.x < view.position.x else 1, "y": p.y - view.position.y,
				"label": "ARIN" if t is OwnerAvatar else "CURSOR"})
	hud.set_offscreen(marks)


## What the screen shows now, in area coordinates.
func view_rect() -> Rect2:
	return Rect2(view_offset, Area.BACKDROP_SIZE)


## Paused only because the window lost focus (no menu to close): resumes
## by itself when focus comes back.
var _focus_paused := false


## Alt-tab, a notification, a phone call: nothing should happen to the
## story or to Rue while the player is looking away (Settings.pause_on_focus_loss).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		focus_lost()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focus_returned()


func focus_lost() -> void:
	if not Settings.pause_on_focus_loss or not is_inside_tree() or get_tree().paused:
		return
	if ending == "" and not purged:
		open_pause()  # the player resumes when ready
	else:
		get_tree().paused = true  # an epilogue or end card: hold it
		_focus_paused = true


## A phone turned to portrait mid-play (UI-2): the game is too small to play
## like that, so it pauses like a lost focus; turning back, the player
## resumes from the menu when ready.
func _check_portrait() -> void:
	if touch == null or not touch.active or not is_inside_tree() or get_tree().paused:
		return
	if TouchControls.is_portrait(Vector2(get_window().size)) and ending == "" and not purged:
		open_pause()


## The player's controller dropped out mid-play (battery, cable): hold the
## game like a lost focus, so nothing happens to Rue until the player is
## back. Another pad coming or going changes nothing (one player).
func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if not connected and Settings.is_players_pad(device):
		_lost_pad = device
		controller_lost()
	elif connected and _pad_paused and device == _lost_pad:
		_pad_paused = false
		_release_hold()


var _lost_pad := -1
## An end card held for the controller (the pause menu covers play itself).
## Kept apart from _focus_paused: each is cleared only by its own return.
var _pad_paused := false


func controller_lost() -> void:
	if not is_inside_tree():
		return
	if ending == "" and not purged:
		if not get_tree().paused:
			open_pause()
	else:
		get_tree().paused = true
		_pad_paused = true
		if _lost_pad == -1:
			_lost_pad = Settings.active_pad


func focus_returned() -> void:
	if _focus_paused:
		_focus_paused = false
		_release_hold()


func _release_hold() -> void:
	if is_inside_tree() and not _focus_paused and not _pad_paused:
		get_tree().paused = false


## While an end card is held for a lost controller, the player can take
## over with anything else (a key, a touch, another pad's press). That press
## only takes over: it does nothing else. (Runs while the tree is paused.)
class _Takeover extends Node:
	var world: Node

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _input(event: InputEvent) -> void:
		if not world._pad_paused or not event.is_pressed() or event.is_echo():
			return
		if event is InputEventKey or event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventJoypadButton:
			world._pad_paused = false
			world._release_hold()
			get_viewport().set_input_as_handled()


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
				get_viewport().set_input_as_handled()
				open_pause()
		"win":
			if not _win_card_shown:
				return  # the epilogue is still playing
			if event.is_action_pressed("confirm") or event.is_action_pressed("pause"):
				get_tree().change_scene_to_file(TITLE_SCENE)
		"demo":
			if event.is_action_pressed("confirm") or event.is_action_pressed("pause"):
				get_tree().change_scene_to_file(TITLE_SCENE)


# --- areas --------------------------------------------------------------------

## The demo build (COMMERCIAL_DIRECTION.md §4, a proposal awaiting the
## author): it ends under the Archive's arch, the first time Rue gets there,
## before the Archivist, the CHARACTER FILE, the Edge or any ending. Off
## unless asked for: a "demo" export feature, `-- --demo`, or ?demo=1.
const DEMO_END_AREAS: Array[String] = ["archive", "bin", "edge"]
static var demo_override := -1  # tests: 1 on, 0 off, -1 ask the build


static func demo_build() -> bool:
	if demo_override != -1:
		return demo_override == 1
	if OS.has_feature("demo") or "--demo" in OS.get_cmdline_user_args():
		return true
	return OS.has_feature("web") and str(JavaScriptBridge.eval("window.location.search", true)).contains("demo")


func change_area(id: String, arrival: String) -> void:
	# Mid-reload you're being dragged back, not walking: no exits (the exit
	# retries once you're free, if you're still standing in it).
	if _transitioning or ending != "" or (owner_moves and owner_moves.rewinding):
		return
	if escort and escort.global_position.distance_to(player.global_position) > ESCORT_LEASH:
		var now := Time.get_ticks_msec()
		if now - _leash_said > 2500:
			_leash_said = now
			hud.say("wait for %s." % escort.npc_id, "self")
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
	if id in DEMO_END_AREAS and demo_build():
		_end_demo()
		return
	# Decided before _load_area, which marks the area visited.
	var first := not _visited.has(id)
	PlaytestLog.mark("entered %s" % id, "first time" if first else "")
	if id != "room":
		PlaytestLog.mark("FIRST TIME OUT OF ARIN'S ROOM", "into %s" % id, true)
	# A place seen in an earlier run isn't new: no first-arrival line again,
	# just a short "back" (once a session).
	var new_place := id not in OwnerMemory.places
	_load_area(_make_area(id), arrival)
	director.on_area_entered(area, first)
	_visited[id] = true
	if new_place:
		voice({"square": "square_first", "archive": "archive_first", "edge": "edge_first", "oob": "oob_first", "bin": "bin_first", "house": "house_first"}.get(id, ""))
	elif first and Story.VOICE_BACK.has(id):
		hud.say(Story.VOICE_BACK[id], "self")
	await hud.fade(false, 0.3).finished
	player.frozen = false
	_transitioning = false


## The demo's last card: nothing past the arch, nothing explained. The
## session closes cleanly (not a quit: no purge).
func _end_demo() -> void:
	PlaytestLog.mark("DEMO END", "under the Archive's arch")
	ending = "demo"
	director.stop()
	hud.cancel_choice()
	hud.close_dialogue()
	hud.clear_queue()
	hud.set_prompt("")
	hud.set_status("")
	area.erasure.active = false
	OwnerMemory.record_demo_end()
	hud.show_overlay("", Story.DEMO_END + "\n\n[%s] title screen" % Settings.glyph("confirm"), Hud.OWNER_COLOR)
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
		"house": return ArinsHouse.new()
	push_error("unknown area %s" % id)
	return VillageSquare.new()


## How often Rue looks around (seconds): what she sees goes in her journal.
const OBSERVE_EVERY := 0.25
var _observe_t := 0.0


## Rue sees how the people in view are (her journal says what she last
## saw). In view: inside the screen as it is framed now, and drawn. Someone
## off-screen keeps what she last saw of them, however they are now.
## (No line of sight: the screen is the rule. Talking to someone also sees
## them, Npc.)
func _observe_in_view() -> void:
	if area == null:
		return
	var view := Rect2(view_offset, Area.BACKDROP_SIZE).grow(-4.0)
	for n in area.interactables + ([escort] if escort else []):
		if n is Npc and is_instance_valid(n) and n.is_inside_tree() and n.is_visible_in_tree() \
				and view.has_point(n.global_position):
			OwnerMemory.observe(n.npc_id, n.observed_state())


func _load_area(next: Area, arrival: String) -> void:
	if area:
		remove_child(area)
		area.queue_free()
	area = next
	area.world = self
	area.arrival = arrival
	OwnerMemory.discover_place(area.area_id)
	Quests.area_now = area.area_id
	if owner_moves:
		owner_moves.on_area_changed()
	add_child(area)
	move_child(area, 0)
	area.build()
	var atmosphere := AreaAtmosphere.new()
	atmosphere.area = area
	area.add_child(atmosphere)
	_visited[area.area_id] = true
	player.position = area.entry_point(arrival)
	player.velocity = Vector2.ZERO
	update_camera(0.0, true)  # arrive already framed: no pan on the way in
	_observe_in_view()
	if pip:
		pip.arrive(player.position)
	_crumbs.clear()
	_escort_cut = false
	player.jumped = false
	if escort:
		# Behind Rue, toward the way she came in, on open floor.
		var back := (player.position - area.bounds.get_center()).normalized()
		var spot := player.position + back * 14.0
		if not husk_spot_ok(spot, player.position + back * 100.0):
			spot = player.position + Vector2(-16, 4)
			if not husk_spot_ok(spot, player.position + Vector2(100, 0)):
				spot = player.position
		escort.global_position = spot
	_light.color = _base_light()
	# Rue's own faint glow, only where the area is lit (and so darker).
	player.glow.enabled = area.ambient < 1.0
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
		# PAUSE carries across a doorway: the new area's owner holds still too.
		if is_owner_paused():
			area.set_owner_paused(true)
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
		hud.show_act(Story.act_label(OwnerMemory.acts_seen.size()), Story.ACTS[id][1], area.display_name)
	else:
		hud.show_area_title(area.display_name)


func _base_light() -> Color:
	var t := area.tint if area else Color(1, 1, 1)
	if purged:
		return Color(1.05, 1.0, 0.95)
	var a := area.ambient if area else 1.0
	return Color(t.lerp(t * Color(0.55, 0.5, 0.6), OwnerMemory.purge / float(OwnerMemory.MAX_PURGE)) * a, 1.0)


# --- queries used by areas and the owner -------------------------------------

## True if something in the area hides this position from the owner.
## Whoever hides you is noted: the owner finds out if this session ends badly.
## `witness` names a watcher whose look has already reached `pos` (range,
## angle and walls checked: Arin binds "arin"): only then is a concealment
## something Rue saw happen, and the journal may say so.
func is_player_hidden(pos: Vector2, witness := "") -> bool:
	if area and area.has_method("hides_player") and area.hides_player(pos):
		if witness != "":
			PlaytestLog.mark("hidden from %s by cover in %s" % [witness, area.area_id], "", true)
		return true
	var helper := _hider_at(pos)
	if helper:
		if witness != "":
			PlaytestLog.mark("hidden from %s behind %s" % [witness, helper.npc_id], "", true)
		OwnerMemory.note_helper(helper.npc_id)
		if witness == "arin" and helper.npc_id == "wren" and not Relationships.has("wren.concealed"):
			Relationships.add("wren.concealed")
	return helper != null


## Is the player hidden right now (by someone or by the area)? No side effects.
func is_hidden_now() -> bool:
	if area == null:
		return false
	if area.has_method("hides_player") and area.hides_player(player.global_position):
		return true
	return hiding_npc() != null


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
## The goal shown under the save header, so a new player always knows what
## to do next without opening a menu. It appears only when it changes (an
## area, a clue), never on a timer: guidance, not nagging.
var _shown_goal := ""


var _goal_check := 0.0


func _update_objective() -> void:
	_goal_check -= get_process_delta_time()
	if _goal_check > 0.0:
		return
	_goal_check = 0.5  # goals change on events, not every frame
	# The goal, and under it the quiet truth-route hint (Progression), if any.
	var goal := current_goal().get_slice("\n", 0)
	var hint := Progression.goal_hint()
	if goal + hint != _shown_goal and not hud.is_dialogue_open() and not hud.is_cinematic() and not hud.is_choosing():
		_shown_goal = goal + hint
		hud.show_objective(goal, hint)


func current_goal() -> String:
	# The mission (Quests): its title, then what to do, survival first where
	# a place can kill her.
	var id := area.area_id if area else ""
	var edge_goal: String = area.goal_text() if id == "edge" and area.has_method("goal_text") else ""
	var goal := Quests.goal(id, edge_goal, flags.get("pointer", false))
	if id == "square" and not OwnerMemory.found_pip:
		goal += " The well looks deeper than it should."
	if sheds_this_run >= 2:
		goal += " " + Story.GOAL_WATCHED_HIDING
	# The truth route, as a quiet hint; the way out above stays open.
	var hint := Progression.goal_hint()
	if hint != "":
		goal += "\n" + hint
	if director and director.truce:
		goal = "TRUCE: the owner only watches this run, unless you glitch. " + goal
	return "%s\nMemories recovered: %d / %d" % [goal, OwnerMemory.fragments.size(), Story.FRAGMENTS.size()]


# --- escorts: Wren to the Edge, Mira to the square ----------------------------------

## What someone noticed about Rue counts once she has actually read it:
## walking away before the line leaves it for next time.
func _on_line_revealed(line: String) -> void:
	# What someone just told Rue, once the whole line is on screen, becomes
	# something she knows (her journal). Once per line (Hud.line_revealed).
	for id in ArchivePages.facts_taught_by(line):
		OwnerMemory.learn_fact(id)
	if OwnerMemory.knows_truth:
		return
	for who: String in Story.TRUTH_LINES:
		if line == Story.TRUTH_LINES[who] and who not in OwnerMemory.truth_pieces:
			OwnerMemory.learn_truth_piece(who)
	if line == Story.FIRST_SHAPE[-1] and "pip" not in OwnerMemory.truth_pieces:
		OwnerMemory.learn_truth_piece("pip")


func _on_dialogue_closed() -> void:
	var who := _talking_to
	var told := _talk_result
	_talking_to = null
	_talk_result = {}
	# Read to its last line, not walked away from or cut off by something else.
	if who and hud.dialogue_finished:
		# What was said is committed now, not when the box opened.
		OwnerMemory.complete_conversation(told.get("conversation", ""))
		for e in told.get("commit", []):
			Relationships.add(e)
		for f: Callable in told.get("after", []):
			f.call()  # a one-time remark, heard
		conversation_completed.emit(who)
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
	OwnerMemory.note_helper(npc.npc_id)
	if npc.npc_id == "mira":
		Relationships.add("mira.walked")
	ArchivePages.escort_now = npc.npc_id
	hud.say("%s.npc  ·  following" % npc.npc_id, "system")
	director.say("mira? what is mira doing out of her room." if npc.npc_id == "mira" else "where are you taking her?")


## Who's walking with you ("" if nobody).
func escort_id() -> String:
	return escort.npc_id if escort else ""


func _update_escort(delta: float) -> void:
	if escort == null:
		return
	var p := player.global_position
	# Rue jumped (PHASE through a wall, a reload pulling her back):
	# the trail is cut. Her companion can't walk through walls, so she waits
	# where she is until Rue comes back within sight, and Rue notices once.
	if player.jumped:
		player.jumped = false
		_crumbs.clear()
		_escort_cut = true
		if not _escort_cut_said:
			_escort_cut_said = true
			hud.say(Story.ESCORT_CUT % escort.npc_id, "self")
	if _escort_cut:
		if p.distance_to(escort.global_position) < 40.0 and _clear_between(escort.global_position, p):
			_escort_cut = false  # together again: follow from here
		else:
			escort.follow(_crumbs, escort.global_position, delta)  # stands and waits
			return
	if _crumbs.is_empty() or _crumbs[-1].distance_to(p) > 6.0:
		_crumbs.append(p)
		if _crumbs.size() > 300:
			_crumbs.pop_front()
	escort.follow(_crumbs, p, delta)
	if escort.npc_id == "mira" and area.area_id != "room":
		# A bedroom character out of her bedroom: the owner can tell. That is
		# passive exposure: like every other, it waits while Rue reads, answers
		# or holds the owner still (is_owner_paused), and in scenes.
		if escort_exposed():
			director.add_awareness(MIRA_EXPOSURE * delta)
		var board: Variant = area.get("board")
		if board is Node2D and escort.global_position.distance_to(board.global_position) < 40.0:
			mira_pins_note()


## Rue went through a wall (PHASE): her companion waits on the other side.
var _escort_cut := false
var _escort_cut_said := false


## No wall or furniture on the straight line from a to b (people don't count).
func _clear_between(a: Vector2, b: Vector2) -> bool:
	var q := PhysicsRayQueryParameters2D.create(a, b)
	q.collision_mask = player.collision_mask
	q.exclude = [player.get_rid()]
	if escort:
		q.exclude = q.exclude + [escort.get_rid()]
	for i in 4:
		var hit := get_world_2d().direct_space_state.intersect_ray(q)
		if hit.is_empty():
			return true
		if not (hit.collider is Npc):
			return false
		q.exclude = q.exclude + [hit.rid]
	return true


## Awareness a second for Mira walking outside her room with you.
const MIRA_EXPOSURE := 2.5


## Whether an escort is in the owner's view right now: not while a
## conversation, question, scene or PAUSE holds the owner.
func escort_exposed() -> bool:
	return not is_owner_paused() and not _cutscene and not hud.is_choosing() and ending == ""


## Mira made it to the notice board: she pins her note herself.
func mira_pins_note() -> void:
	if escort == null or escort.npc_id != "mira" or _cutscene:
		return
	_cutscene = true
	player.frozen = true
	director.paused = true
	OwnerMemory.mira_quest = "pinned"
	Relationships.add("mira.pinned")  # saves
	await hud.cinematic("MIRA", Story.MIRA_PIN_SCENE, Color("e0a070"), 0.6, "mira.pin", CharacterArt.for_npc(escort, "proud"))
	if not is_inside_tree() or ending != "":
		return  # the run ended during the scene: nothing here is kept
	var board: Variant = area.get("board")
	if board is Note:
		board.set_text_now(Story.MIRA_NOTE_TEXT)
	hud.say("PINNED: mira_note.txt", "system")
	Sfx.play("seal", -4.0, 1.3)
	# She walks home on her own.
	var gone := escort
	escort = null
	ArchivePages.escort_now = ""
	create_tween().tween_property(gone, "modulate:a", 0.0, 1.2)
	get_tree().create_timer(1.3).timeout.connect(gone.queue_free)
	player.frozen = false
	director.paused = false
	_cutscene = false
	director.notice(5.0, "a note on the board")
	director.say("...mira wrote this?")


## The owner got her while she was with you. Wren: deleted, for good.
## Mira: reset to her defaults, for good (she won't remember you).
func lose_escort() -> void:
	if escort == null:
		return
	var lost := escort
	escort = null
	ArchivePages.escort_now = ""
	if lost.npc_id == "mira":
		OwnerMemory.mira_quest = "reset"
		Relationships.add("mira.reset")  # saves
		OwnerMemory.observe("mira", "reset")
		hud.say(Story.MIRA_RESET_LAST, "npc", "MIRA")
		hud.say("mira.npc  ·  reset to defaults", "system")
		director.say("there. back where you belong.")
		hud.say("(she looked right at me. she didn't know me.)", "self")
		fx.spike(0.6 * Settings.flash_scale(), 1.0)
		create_tween().tween_property(lost, "modulate:a", 0.0, 1.0)
		get_tree().create_timer(1.1).timeout.connect(lost.queue_free)
		return
	# She trusted you. She gets half a sentence.
	hud.say(Story.WREN_LAST_WORDS, "npc", "WREN")
	lost.delete()
	OwnerMemory.observe("wren", "deleted")
	OwnerMemory.npc_fates["wren"] = "deleted"
	Relationships.add("wren.promise_broken")
	OwnerMemory.save_memory()
	hud.say("wren.npc deleted", "system")
	director.say(Story.WREN_LOST_OWNER)
	for line in Story.WREN_LOST_VOICE:
		hud.say(line, "self")
	fx.spike(0.8, 1.2)
	get_tree().create_timer(2.0).timeout.connect(lost.queue_free)


## Wren made it to the Edge: her moment, and she's out of the owner's reach.
func _wren_sees_edge() -> void:
	if escort == null or escort.npc_id != "wren" or OwnerMemory.wren_saved:
		return
	OwnerMemory.wren_saved = true
	Relationships.add("wren.promise_kept")
	OwnerMemory.observe("wren", "safe")
	OwnerMemory.npc_fates.erase("wren")
	OwnerMemory.save_memory()
	for line in Story.WREN_EDGE:
		hud.say(line, "npc", "WREN")
	hud.say("wren.npc  ·  moved to CUT CONTENT", "system")
	director.say("where did she go. she's not in the list anymore.")


# --- debug ------------------------------------------------------------------------

## Debug tools are on in the editor, debug builds, tests, and on the web with
## ?debug=1 in the address (so they can be used from a phone).
## Tests switch the debug tools off to check what a release build does.
var debug_forced_off := false


func debug_enabled() -> bool:
	if debug_forced_off:
		return false
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
		or hud.is_dialogue_open() or hud.is_cinematic() or get_tree().paused)


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
	if area and not is_owner_paused():  # a conversation or question still holds it
		area.set_owner_paused(false)
	fx.memory(false)
	hud.set_banner("")
	Sfx.play("owner_unpause")


func is_owner_paused() -> bool:
	return director.owner_paused > 0.0 or _choice_hold or _reading_now()


## The protection policy (docs/GAMEPLAY_CONSISTENCY.md, pass 8): anything
## that covers the scene or asks for the player's attention holds the owner.
## That means a conversation, a question, a scene, and a large centre card (an
## act title or NEW GLITCH). Small things don't: tips, console lines, the
## goal line, area names. The pause menu stops the whole tree; focus loss
## opens it. PAUSE (the glitch) holds the owner but not Rue's own progress.
## Every threat reads this one rule through is_owner_paused() or
## set_owner_paused(); the area's own pause follows it each frame in
## _update_reading_hold.
func _reading_now() -> bool:
	return hud.is_dialogue_open() or hud.is_cinematic() or _cutscene or hud.is_act_shown()


## Is the story holding the action right now (see _reading_now)? Unlike
## is_owner_paused(), PAUSE (the glitch) doesn't count: Rue's own progress
## (writing Slot 2) carries on under it.
func story_holds() -> bool:
	return _reading_now() or hud.is_choosing()


## Reading is safe (docs/NARRATIVE_RELIABILITY.md, the modal safety matrix):
## while a conversation or a scene is open Rue stands still and so does the owner, like a
## question. No move starts, a save ring in progress holds where it is, and
## awareness doesn't climb. All of it resumes, visibly, when the box closes.
func _update_reading_hold() -> void:
	var reading := _reading_now()
	if reading == _reading_hold:
		return
	_reading_hold = reading
	if area:
		area.set_owner_paused(is_owner_paused())


## A question asked in the middle of play (Wren, Mira, Tobben): Rue can't
## move while it's open, so the owner holds still too, like PAUSE, instead of
## killing someone who is reading. Awareness holds as well.
## The hold is kept for the whole question, even when it starts during PAUSE
## (PAUSE running out mustn't let the owner back in mid-question). Returns -1
## if the run ended while it was open: nothing was answered.
func choose_safely(question: String, options: Array, focus := 0) -> int:
	if not is_owner_paused():
		area.set_owner_paused(true)
	_choice_hold = true
	var pick := await hud.choose(question, options, focus)
	if not is_inside_tree():
		return -1
	_choice_hold = false
	if not is_owner_paused() and area:
		area.set_owner_paused(false)
	return pick if ending == "" else -1


## Where Pip should lead: something relevant here (a memory, someone with
## something to tell her, the CHARACTER FILE once it reads whole; see
## Progression), else the area's own way on.
func guide_target() -> Vector2:
	if area == null:
		return Vector2.INF
	var here := Progression.local_target(self)
	return here if here != Vector2.INF else area.guide_point()


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
	MusicBox.prewarm(mini(found + 1, MusicBox.MAX_LEVEL - 1))
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
	if OwnerMemory.safe_close == Callable(_close_safely):
		OwnerMemory.safe_close = Callable()


## Mira is gone this run: deleted this session, or by an advanced purge
## (unless you've brought her back).
func is_mira_deleted() -> bool:
	return flags.get("mira_deleted", false) or (OwnerMemory.purge >= 3 and "mira" not in OwnerMemory.restored)


## Someone deleted is back (RESTORE, or the Recycle Bin): for good.
func note_restored(id: String) -> void:
	Relationships.mark(id + ".restored")  # each time: someone can be lost and brought back again
	OwnerMemory.observe(id, "restored")
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
	var previous := _focused
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
	# Keep a valid target until another is meaningfully closer. This stops
	# adjacent notes and characters flickering between prompts as you move.
	if is_instance_valid(previous) and previous in area.interactables and previous.can_interact():
		var distance := player.global_position.distance_to(previous.global_position)
		if distance < INTERACT_DISTANCE and distance <= best + 6.0:
			_focused = previous
	# Pip trots at your heels: Pip is only what E talks to when nothing
	# else is in reach (or Pip would steal every pillar, door and note).
	if _focused == null and pip and pip.can_interact() \
			and player.global_position.distance_to(pip.global_position) < INTERACT_DISTANCE:
		_focused = pip
	# Said beside the thing itself, where the eye already is.
	hud.set_prompt(_focused.interact_prompt() if _focused else "", _focused.global_position if _focused else Vector2.INF,
		World.object_name(_focused) if _focused else "")
	_focus_marker.target = _focused


## What an interactable is, in a few words ("SAVE POINT", "WREN"): its own
## interact_name() if it has one, else a character's name, else nothing.
static func object_name(node: Node) -> String:
	if node.has_method("interact_name"):
		return node.interact_name()
	if node is Npc:
		return node.display_name + (" · " + node.doing if node.doing != "" else "")
	return ""


func _interact(node: Node2D) -> void:
	var result: Variant = node.interact()
	if result is Dictionary:
		var face: CharacterArt.Portrait = CharacterArt.for_npc(node) if node is Npc else null
		hud.show_dialogue(result.speaker, result.color, result.lines, dialogue_voice_prefix(node, result), face, expressions_for(node, result.lines),
			node is Npc and (node as Npc).mute)
		_talking_to = node
		_talk_result = result
		_keep_in_journal(node, result)
	elif str(result) != "":
		hud.say(str(result), "system")
	var cost: Variant = node.get("awareness_cost")
	if cost is float and cost > 0.0:
		var who: Variant = node.get("display_name")
		director.notice(cost, "talking to %s" % who if who is String and who != "" else "you touched something")
	if area.has_method("interact_extra"):
		area.interact_extra(node)


## The voice id stem for what `node` says (Hud.voice_id): people speak as
## "npc.<id>", notes, books and signs as "read.<area>". VoiceManifest lists
## the same ids, so a recording dropped in audio/voice/ just plays.
static func dialogue_voice_prefix(node: Node, result: Dictionary) -> String:
	if node is Npc and node.npc_id == "tobben" and node.is_frayed():
		return ""  # he writes; nothing is said aloud
	if node is Npc:
		return "npc." + str(node.npc_id)
	if node is Companion:
		return "npc.pip"
	return ""


## The portrait expression for each line someone says ("" = their default).
static func expressions_for(node: Node, lines: Array) -> Array:
	var out: Array = []
	for l in lines:
		var who: String = node.npc_id if node is Npc else ""
		match who:
			"mira":
				out.append(ArinsRoom.mira_expression(str(l)))
			"wren":
				out.append(VillageSquare.wren_expression(str(l)))
			_:
				out.append("")
	return out


## Notes, books and files go in the artefact journal (signs and props don't).
func _keep_in_journal(node: Node2D, result: Dictionary) -> void:
	var kind := ""
	if node is Note:
		kind = "note"
	elif node is Readable and node.look != Readable.Look.SIGN:
		kind = "book" if node.look in [Readable.Look.BOOK, Readable.Look.RECORD] else "file"
	if kind != "" and OwnerMemory.record_read("%s:%s" % [area.area_id, result.speaker], kind, str(result.speaker), area.display_name, result.lines):
		hud.say("KEPT IN JOURNAL  ·  %s%s" % [result.speaker, "  (pause to re-read)" if OwnerMemory.journal.size() == 1 else ""], "system")


# --- endings ------------------------------------------------------------------

## The death card's last line: what the next run keeps, and how far the purge is.
static func death_kept_line() -> String:
	if OwnerMemory.is_purged():
		return ""
	var wake := "  ·  you'll wake under the well" if anchor_valid() else ""
	return "kept for next run: %d/%d memories, your glitches, the journal, everyone you've met  ·  purge %d/%d%s" % [
		OwnerMemory.fragments.size(), Story.FRAGMENTS.size(), OwnerMemory.purge, OwnerMemory.MAX_PURGE, wake]


# --- the well anchor (docs/NARRATIVE_CONTRACT.md §5) ----------------------------

## The one checkpoint: anchor id -> [area id, arrival]. Places are looked up
## by id, never stored as coordinates, so a changed map can't strand you.
const ANCHORS := {"oob:pillar": ["oob", "anchor"]}
## Bumped when an anchor's place changes meaning: older anchors are dropped.
const ANCHOR_VERSION := 1
## This session began at the anchor (after a death), not in Arin's room.
var woke_at_anchor := false


static func anchor_valid() -> bool:
	var a := OwnerMemory.anchor
	return not a.is_empty() and ANCHORS.has(a.get("id", "")) and int(a.get("version", 0)) == ANCHOR_VERSION


## Where a session starts: the anchor after a death (if one is set and
## still valid), otherwise Arin's room. A quit or a crash always starts in
## the room: the anchor is for failure, not for leaving. An unknown or
## outdated anchor is dropped, and the room is used.
static func anchor_start(previous: String) -> Array:
	if OwnerMemory.anchor.is_empty():
		return []
	if not anchor_valid():
		OwnerMemory.anchor.clear()
		OwnerMemory.save_memory()
		return []
	if previous != "death":
		return []
	return ANCHORS[OwnerMemory.anchor.id]


## Answering the well sets (or re-confirms) the anchor. Never during a
## conversation, a scene, a move between areas or an escort.
func set_anchor(id: String) -> bool:
	if not ANCHORS.has(id) or escort != null or _transitioning or ending != "" or hud.is_dialogue_open() or hud.is_cinematic():
		return false
	OwnerMemory.anchor = {"id": id, "version": ANCHOR_VERSION, "session": OwnerMemory.sessions}
	OwnerMemory.save_memory()
	return true


## cause picks the death effect ("erased", "overwritten", "selected");
## reason picks the explanation and tip (a key of Story.DEATHS).
func kill(cause: String, reason := "") -> void:
	if bench_immune:
		return  # development benchmark only (tests/tour_benchmark.gd): nothing else changes
	if ending != "" or _transitioning:
		return
	var warned := hud.warning_text()
	PlaytestLog.mark("DIED", "%s (%s) in %s at %s, awareness %d, warning on screen: %s" % [
		reason, cause, area.area_id, player.global_position.round(), int(director.awareness), ("\"%s\"" % warned) if warned != "" else "none"])
	ending = "death"
	player.frozen = true
	director.stop()
	hud.cancel_choice()  # a question still open answers nothing now
	hud.close_dialogue()
	hud.clear_queue()
	hud.set_prompt("")
	hud.set_status("")
	fx.play_death(cause)
	Settings.buzz(160)
	player.dissolve(cause)
	Sfx.play("death_" + cause, 0.0, 1.0, 0.0)
	drone.tension = 1.0
	if escort_id() == "mira":
		OwnerMemory.mira_quest = "lost"  # the owner found her out of her room, and her note
		Relationships.mark("mira.note_lost")
	# Mira sees it only if it happens in her room, in front of her.
	var mira_here: Variant = area.get("mira")
	if area.area_id == "room" and mira_here is Npc and is_instance_valid(mira_here) and (mira_here as Npc).is_present() \
			and OwnerMemory.mira_quest != "reset":
		Relationships.mark("mira.saw_death")
	# Wren remembers it only if she saw it: walking with you, or there.
	var wren_here: Variant = area.get("wren")
	if escort_id() == "wren" or (wren_here is Npc and is_instance_valid(wren_here) and (wren_here as Npc).is_present()):
		Relationships.mark("wren.saw_death")
	var forgiven := OwnerMemory.record_death(area.area_id, player.global_position, reason)
	last_death = reason
	var info: Array = Story.DEATHS.get(reason, ["ERASED", "the owner learned something.", "", "", ""])
	var title: String = info[0]
	var times := int(OwnerMemory.death_causes.get(reason, 1))
	var body: String = Story.death_body(reason, area.area_id, times, escort_id() == "wren") if reason != "" else str(info[1])
	if not OwnerMemory.session_helpers.is_empty():
		body += "\nthe owner saw who helped you."
	if OwnerMemory.is_purged():
		body = "the owner has learned enough."
	elif OwnerMemory.purge == OwnerMemory.MAX_PURGE - 1:
		# One step from the purge ending: say so while it can still be avoided.
		body += "\n" + Story.PURGE_WARNING
	elif forgiven:
		body += "\nthe edge isn't loaded. the owner didn't see that one. (it didn't count.)"
	var tip := death_tip(reason)
	if area.area_id == "edge" and reason == "eraser":
		tip = "Next time the static waits %d s before it starts. Its cracks show where." % int(TheEdge.grace_time())
	# Let the death play out on screen before the text slams in.
	await get_tree().create_timer(0.6).timeout
	if not is_inside_tree():
		return
	hud.show_death(title, body, cause, tip, death_kept_line())
	# The card waits for the player: the advice is read, then a press retries.
	# A moment first, so a press still held from play doesn't skip it; less
	# for a death the player has had before (the repeat player's fast path).
	await get_tree().create_timer(RETRY_LOCK_REPEAT if times > 1 else RETRY_LOCK).timeout
	if not is_inside_tree():
		return  # F9 may have reloaded the scene in the meantime
	hud.show_retry()
	while is_inside_tree():
		await get_tree().process_frame
		if not is_inside_tree():
			return  # the scene changed while the card waited
		if get_tree().paused:
			continue  # the pause menu has the input
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("confirm"):
			break
	if is_inside_tree():
		get_tree().reload_current_scene()


## What to try next time, given the glitches you have.
func death_tip(reason: String) -> String:
	if not Story.DEATHS.has(reason):
		return ""
	var info: Array = Story.DEATHS[reason]
	var tip: String = info[4] if glitch and glitch.unlocked(info[3]) else info[2]
	return tip.replace("{interact}", Settings.glyph("interact"))


## Careful: Arin never saw you this run, and you glitched at most once.
func is_unseen_run() -> bool:
	return not flags.get("seen_by_arin", false) and OwnerMemory.session_glitches <= 1


## Reckless: the owner at full awareness, and ten glitches this run.
func is_reckless_run() -> bool:
	return director.awareness >= OwnerDirector.PURGE and OwnerMemory.session_glitches >= 10


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
	hud.show_objective("")
	owner_moves.save_progress = -1.0
	owner_moves.wren_delete = -1.0
	# RUE needs every memory and the truth they add up to.
	var full := OwnerMemory.fragments.size() >= Story.FRAGMENTS.size() and OwnerMemory.knows_truth
	var options: Array = [Story.SLOT2_ESCAPE_NAMED if full else Story.SLOT2_ESCAPE]
	var ids: Array[String] = ["rue" if full else "escape"]
	if escort and escort.npc_id == "wren" and escort.is_present():
		options.append(Story.SLOT2_WREN)
		ids.append("wren")
	options.append(Story.SLOT2_MESSAGE)
	ids.append("message")
	# The hidden ways out, only for the extremes.
	if is_unseen_run():
		options.append(Story.SLOT2_UNSEEN)
		ids.append("unseen")
	if is_reckless_run():
		options.append(Story.SLOT2_OVERWRITE)
		ids.append("overwrite")
	# Everything you've done, all at once, before you choose.
	await hud.cinematic("", Story.slot2_recap(escort_id() == "wren"), Hud.OWNER_COLOR, 0.8, "slot2.recap", CharacterArt.rue("determined", player.palette()))
	if not is_inside_tree():
		return
	var pick := await hud.choose(Story.SLOT2_QUESTION, options)
	if not is_inside_tree() or pick < 0:
		return
	var message := 0
	if ids[pick] == "message":
		message = await hud.choose(Story.MESSAGE_QUESTION, Story.messages())
		if not is_inside_tree() or message < 0:
			return
	await _slot2_press()
	if not is_inside_tree():
		return
	_cutscene = false
	win(ids[pick], message)


## Her press at Slot 2. Until she knows what she is, it is the girl's
## habit (two light taps, then the press: the opening, the well). Knowing,
## it is one press, her own: the first gesture that is only hers (the
## author's direction, CANON_DECISIONS.md §1).
var slot2_press := ""


func _slot2_press() -> void:
	if OwnerMemory.knows_truth:
		slot2_press = "own"  # (she says so as the final exchange opens: win())
		Sfx.play("click", -6.0, 0.85, 0.0)
		await get_tree().create_timer(0.6).timeout
	else:
		slot2_press = "habit"
		for h in Opening.HABIT:
			get_tree().create_timer(h[0]).timeout.connect(func() -> void: Sfx.play("click", h[1], 1.3 if h[0] < 0.5 else 1.0, 0.0))
		await get_tree().create_timer(0.8).timeout


## An ending: "escape" (Rue takes Slot 2), "wren" (Wren gets it), or
## "message" (the slot goes back to the owner, with one of Story.MESSAGES).
func win(chosen := "escape", message := 0) -> void:
	PlaytestLog.mark("ENDING", chosen)
	if ending != "":
		return
	# Taking the slot remembering everything, and knowing what you are, is RUE.
	if chosen == "escape" and OwnerMemory.fragments.size() >= Story.FRAGMENTS.size() and OwnerMemory.knows_truth:
		chosen = "rue"
	ending = "win"
	player.frozen = true
	director.stop()
	hud.cancel_choice()  # a question still open answers nothing now
	hud.close_dialogue()
	hud.clear_queue()
	hud.set_prompt("")
	hud.set_status("")
	hud.set_glitch_prompt("")
	area.erasure.active = false
	_ending_visuals(chosen)
	var found := OwnerMemory.fragments.size()
	var epilogue := Story.epilogue(chosen, found, OwnerMemory.found_pip, message)
	OwnerMemory.record_win(chosen)
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return
	# The console, live: the last thing said.
	var exchange: Array = Story.FINAL_EXCHANGE.get(chosen, []).duplicate()
	if slot2_press == "own":
		exchange.push_front(Story.RUE_OWN_PRESS)  # her first gesture that is only hers
	await hud.cinematic("", exchange, Hud.OWNER_COLOR, 0.85, "final." + chosen, CharacterArt.rue("determined", player.palette()))
	if not is_inside_tree():
		return
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
	var variant: String = {"overwrite": "invert", "unseen": "reverse"}.get(chosen, "normal")
	theme.stream = MusicBox.stream(Story.theme_level(chosen, found), variant)
	theme.volume_db = -30.0
	add_child(theme)
	theme.play()
	create_tween().tween_property(theme, "volume_db", -6.0, 2.0)
	await hud.cinematic("EPILOGUE", epilogue, Hud.SELF_COLOR, 1.0, "epilogue." + chosen, CharacterArt.rue("relieved", player.palette()))
	if not is_inside_tree():
		return
	hud.show_overlay(
		Story.ENDING_TITLES[chosen],
		Story.ending_text(chosen, found) + "\n\n— end of the current build —\n\n[%s] title screen" % Settings.glyph("confirm"),
		Story.ENDING_COLORS[chosen])
	_win_card_shown = true


## How each ending looks the moment you choose it.
func _ending_visuals(chosen: String) -> void:
	var flash := Settings.flash_scale()
	match chosen:
		"wren":
			# She goes in; you stay.
			fx.wash(Color("a8d890"), 0.6 * flash, 1.4)
			fx.play_win()
			if escort:
				GlitchBurst.at(self, escort.global_position, Vector2(20, 30), 1.0)
				escort.visible = false
			Sfx.play("win", -2.0, 1.15, 0.0)
		"message":
			# Nobody goes in. The save stops fighting: the static freezes.
			area.erasure.set_process(false)
			fx.wash(Color("f0c890"), 0.45 * flash, 2.0)
			fx.memory(true)
			Sfx.play("fragment", 0.0, 0.8, 0.0)
		"rue":
			# Everything comes back at once: white, then your colours.
			fx.wash(Color.WHITE, 0.9 * flash, 2.2)
			fx.play_win()
			player.dissolve("rescued")
			Sfx.play("win", 0.0, 0.9, 0.0)
			Sfx.play("glitch_learn", -4.0, 0.8, 0.0)
		"unseen":
			# You just... go. The picture greys and you fade out of it.
			fx.wash(Color(0.25, 0.26, 0.3), 0.7, 3.0)
			create_tween().tween_property(player, "modulate:a", 0.0, 2.5)
			Sfx.play("unload", -4.0, 0.6, 0.0)
		"overwrite":
			# Red, loud, wrong.
			fx.wash(Color("ff2040"), 0.8 * flash, 1.6)
			fx.spike(1.0 * flash, 1.4)
			fx.noise(1.0, 1.4)
			fx.shake(6.0 * flash)
			Sfx.play("death_selected", 0.0, 0.7, 0.0)
			Sfx.play("purge_bell", 0.0, 0.8, 0.0)
		_:
			fx.play_win()
			player.dissolve("rescued")
			Sfx.play("win", 0.0, 1.0, 0.0)


func _quit(to_title: bool = false) -> void:
	PlaytestLog.mark("QUIT from the pause menu", "to title" if to_title else "closed the game")
	ending = "quit"
	player.frozen = true
	director.stop()
	hud.cancel_choice()  # a question still open answers nothing now
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
		OwnerMemory.quit_game()


# --- Save and exit (docs/SAVE_AND_EXIT_PROPOSAL.md, option b) ----------------

## Bumped when a map changes enough that a stored position could be wrong:
## older suspends are dropped and the run starts in Arin's room.
const SUSPEND_VERSION := 1
## Where a suspend can resume (the Edge is the finale: never there).
const SUSPEND_AREAS := ["room", "square", "archive", "oob", "bin", "house"]
const SUSPEND_WAKE := "(you came back. i stayed right here.)"
## This session resumed a suspended run.
var woke_from_suspend := false
## Who was walking with her when she stopped ("" if nobody): back home now.
var _resumed_escort := ""


## Why Save and exit isn't possible right now, or "" when it is. The same
## idea of a safe moment as the protection policy: nothing about to land,
## nobody depending on her, no story open.
func suspend_blocker() -> String:
	if purged or ending != "" or _transitioning or _cutscene or not _awake or not OwnerMemory.session_armed():
		return "not right now."
	if area == null or area.area_id not in SUSPEND_AREAS:
		return "not here. this is where it ends."
	if story_holds() or hud.is_choosing():
		return "not in the middle of a conversation."
	if director.awareness >= OwnerDirector.SUSPECT or hud.warning_text() != "":
		return "not while the owner is looking for you."
	if owner_moves and (owner_moves.save_progress >= 0.0 or owner_moves.wren_delete >= 0.0):
		return "not while the owner is reaching in."
	var erasure: Variant = area.get("erasure")
	if erasure is Node and erasure.get("active"):
		return "not with the static spreading."
	var p := player.global_position
	for threat in ["arin", "cursor"]:
		var n: Variant = area.get(threat)
		if n is Node2D and n.global_position.distance_to(p) < 120.0:
			return "not with the owner this close."
	return ""


## Save and exit, step one (the pause menu calls it, with the game still
## paused): write the record. Returns "" when it is on disk, otherwise why
## not, and nothing has changed: the run is still open and still paused.
func try_suspend(to_title := true) -> String:
	var blocked := suspend_blocker()
	if blocked != "":
		return blocked
	# Someone walking with her goes home and asks again next time (their
	# own "are we still going?"): stopping mid-escort costs them nothing.
	var kept := flags.duplicate()
	if escort:
		kept["suspended_escort_" + escort.npc_id] = true
	if not OwnerMemory.record_suspend(area.area_id, player.global_position, SUSPEND_VERSION, kept):
		PlaytestLog.mark("SAVE AND EXIT FAILED", OwnerMemory.suspend_error)
		return OwnerMemory.suspend_error
	PlaytestLog.mark("SUSPENDED (save and exit)", "%s at %s" % [area.area_id, player.global_position.round()])
	_leave_suspended(to_title)
	return ""


## Step two, only after the save is on disk: say so and go to the title.
func _leave_suspended(to_title := true) -> void:
	ending = "suspend"
	player.frozen = true
	director.stop()
	hud.set_prompt("")
	hud.set_status("")
	hud.show_overlay("SAVED", "i'll be right here.")
	fx.power_off(1.0)
	Sfx.play("power_off", -4.0, 1.2, 0.0)
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	if to_title:
		get_tree().change_scene_to_file(TITLE_SCENE)
	else:
		OwnerMemory.quit_game()


## Closing the window: free at a calm moment (records the Save and exit).
func _close_safely() -> bool:
	if not is_inside_tree() or suspend_blocker() != "":
		return false
	var kept := flags.duplicate()
	if escort:
		kept["suspended_escort_" + escort.npc_id] = true
	return OwnerMemory.record_suspend(area.area_id, player.global_position, SUSPEND_VERSION, kept)


## Keeps the calm moment on disk while it lasts (OwnerMemory.mark_safe), so a
## tab closed, a crash or a power cut now costs nothing; withdrawn the moment
## it isn't calm. Checked four times a second; written only on a change, or
## every few seconds while she moves.
const SAFE_CHECK := 0.25
const SAFE_REWRITE := 5.0
var _safe_t := 0.0
var _safe_written := -INF
var _safe_at := Vector2.INF


func _update_safe_mark(delta: float) -> void:
	_safe_t -= delta
	if _safe_t > 0.0 or purged:
		return
	_safe_t = SAFE_CHECK
	var safe := suspend_blocker() == ""
	if not safe:
		OwnerMemory.mark_unsafe()
		_safe_at = Vector2.INF
		return
	var now := Time.get_ticks_msec() / 1000.0
	var moved := _safe_at == Vector2.INF or player.global_position.distance_to(_safe_at) > 16.0
	var new_place := str(OwnerMemory.suspend.get("area", "")) != area.area_id
	if OwnerMemory.last_exit != "safe" or new_place or (moved and now - _safe_written > SAFE_REWRITE):
		var kept := flags.duplicate()
		if escort:
			kept["suspended_escort_" + escort.npc_id] = true
		OwnerMemory.mark_safe(area.area_id, player.global_position, SUSPEND_VERSION, kept)
		_safe_written = now
		_safe_at = player.global_position


## (Kept for callers and tests: the same as choosing Save and exit.)
func _suspend() -> void:
	var why := try_suspend()
	if why != "":
		hud.say("save and exit: " + why, "system")


## The suspend to resume this session, or {} (none, outdated, or the last
## session didn't end in one). An unusable record is dropped.
static func suspend_start(previous: String) -> Dictionary:
	var s := OwnerMemory.suspend
	if s.is_empty():
		return {}
	if previous != "suspend" or int(s.get("version", 0)) != SUSPEND_VERSION or str(s.get("area", "")) not in SUSPEND_AREAS \
			or int(s.get("session", -1)) != OwnerMemory.sessions - 1:
		OwnerMemory.suspend.clear()
		OwnerMemory.save_memory()
		return {}
	return s


## Whether Rue's whole body fits at `at`: inside the map, on floor, and
## clear of every solid as rebuilt this session (props, doors, walls).
func body_fits(at: Vector2) -> bool:
	if not area.bounds.grow(-6.0).has_point(at):
		return false
	if area.has_method("floor_at") and not area.floor_at(at):
		return false
	var shape_node := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return true
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape_node.shape
	q.transform = Transform2D(0.0, at + shape_node.position)
	q.collision_mask = player.collision_mask
	q.exclude = [player.get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()


## A resumed spot is checked once the rebuilt map is in the physics world:
## if anything now stands there (a crate the owner moved, a closed door),
## the nearest clear spot, else the area's first way in.
func _settle_resume() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	var at := player.global_position
	if body_fits(at):
		return
	var found := Vector2.INF
	for ring in range(1, 11):
		for k in 16:
			var c := at + Vector2.from_angle(TAU * k / 16.0) * ring * 6.0
			if body_fits(c):
				found = c
				break
		if found != Vector2.INF:
			break
	if found == Vector2.INF:
		found = area.entry_point("start" if area.entries.has("start") else str(area.entries.keys()[0]) if not area.entries.is_empty() else "")
	PlaytestLog.mark("resume moved", "%s: %s -> %s (blocked)" % [area.area_id, at.round(), found.round()])
	player.global_position = found
	update_camera(0.0, true)
	if pip:
		pip.arrive(player.position)


## Puts Rue back where she was (if it is still inside the map) with the
## run's flags; _settle_resume then checks her whole body against the map.
func _resume_at(s: Dictionary) -> void:
	var at := Vector2(float(s.x), float(s.y))
	if area.bounds.grow(-6.0).has_point(at) and (not area.has_method("floor_at") or area.floor_at(at)):
		player.position = at
		update_camera(0.0, true)
		if pip:
			pip.arrive(player.position)
	var kept: Dictionary = s.get("flags", {})
	for k in kept:
		if str(k).begins_with("suspended_escort_"):
			_resumed_escort = str(k).trim_prefix("suspended_escort_")
			continue
		flags[k] = kept[k]
	flags["pointer"] = flags.get("pointer", false) or OwnerMemory.met_archivist
	woke_from_suspend = true


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
	drone.volume_db = -30.0
	# Let the quiet sink in, then say plainly what happened and how to come back.
	get_tree().create_timer(PURGED_CARD_DELAY).timeout.connect(_purged_card)


## The purge ending's card: what happened, and real buttons (mouse, keys,
## gamepad, touch) instead of only holding F9.
func _purged_card() -> void:
	if not is_inside_tree() or not purged:
		return
	hud.show_overlay(Story.PURGED_TITLE, Story.purged_body(), UiStyle.MUTED)
	while is_inside_tree():
		var pick := await hud.choose(Story.PURGED_QUESTION, Story.PURGED_CHOICES)
		if pick == 1:
			get_tree().change_scene_to_file(TITLE_SCENE)
			return
		var sure := await hud.choose(Story.PURGED_CONFIRM, Story.PURGED_CONFIRM_CHOICES)
		if sure == 0:
			restore_intruder()
			return


## A new game for the intruder: the owner forgets everything (and so do the
## Records). The same as Settings > Reset the owner's memory.
func restore_intruder() -> void:
	set_process(false)
	OwnerMemory.wipe()
	get_tree().reload_current_scene()


## Hold F9 to make the owner forget everything (a "new game" for the intruder).
func _handle_wipe(delta: float) -> void:
	# Only where it's offered (the purge screen) or in debug builds: holding
	# a key mid-run must never wipe a player's progress by accident.
	if not (purged or debug_enabled()):
		return
	if Input.is_action_pressed("wipe_memory"):
		_wipe_hold += delta
		hud.set_hint("restoring intruder… %d%%" % int(100.0 * _wipe_hold / WIPE_HOLD_TIME))
		if _wipe_hold >= WIPE_HOLD_TIME:
			_wipe_hold = 0.0
			restore_intruder()
	elif _wipe_hold > 0.0:
		_wipe_hold = 0.0
		hud.set_hint("")
