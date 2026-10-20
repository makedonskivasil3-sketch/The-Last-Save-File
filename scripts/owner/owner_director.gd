class_name OwnerDirector
extends Node
## The owner. Watches the session, gets more aware of you over time, and
## rewrites the world in response. Starts each session already knowing
## whatever OwnerMemory knows. Each area decides how it reacts to a threshold.

## Awareness thresholds (0..100). Areas react to them in on_owner_event().
const NOTICE := 25.0
const SUSPECT := 40.0
const CONTAIN := 50.0
const SILENCE := 65.0
const HUNT := 75.0
const PURGE := 100.0
const THRESHOLDS: Array[float] = [NOTICE, SUSPECT, CONTAIN, SILENCE, HUNT, PURGE]

## Awareness per second before the area's multiplier.
const BASE_RATE := 0.35
## Each death or quit makes the owner faster to notice next time...
const RATE_PER_PURGE := 0.15
## ...up to this many purge steps: past it a run would snowball (HUNT in
## half a minute), and a hard run shouldn't become a lost one.
const RATE_PURGE_CAP := 3
## ...and start the session already this aware (per purge, capped). The cap
## keeps every session winnable: you always arrive below SUSPECT.
const START_PER_PURGE := 10.0
const START_CAP := 35.0
## While someone hides you, the owner loses track: awareness cools this fast
## (per second) instead of rising. It never drops below the last threshold
## the owner reacted to, so the world never "un-happens".
const HIDDEN_COOL_RATE := 2.0
## Standing still this long (in the open, once noticed) and the owner says so,
## once a session (+IDLE_WARN_COST). OwnerMoves.IDLE_SAVE follows it.
const IDLE_WARN := 6.0
const IDLE_WARN_COST := 5.0

var awareness := 0.0
## Held during story sequences: awareness stops rising.
var paused := false
## Seconds left of Rue's PAUSE glitch: the owner's whole world stands still.
var owner_paused := 0.0
## Rue's FALSIFY glitch: while the owner believes a note's lie, awareness
## rises this much slower.
const LIE_RATE := 0.35
var _lie := 0.0

## The morning after the RUE or message ending the owner keeps their word
## ("i'm not deleting anything tonight", "i'm just going to watch"): for
## that session they only watch. Awareness rises slowly and stops short of
## SILENCE, and the owner makes no moves, until you glitch TRUCE_STRIKES
## times (each one warned): then it's an ordinary session again.
const TRUCE_STRIKES := 3
const TRUCE_RATE := 0.3
const TRUCE_STRIKE_LINES := ["...careful.", "i said i'd leave you alone. don't make me.", "...right. you're still you."]
var truce := false
var _truce_strikes := 0

var _world: World
var _fired: Dictionary = {}
var _idle_warned := false
var _running := false


func start(world: World, previous_exit: String) -> void:
	_world = world
	awareness = minf(OwnerMemory.purge * START_PER_PURGE, START_CAP)
	truce = previous_exit in ["win", "escape"] and OwnerMemory.last_ending in ["rue", "message"]
	Sfx.owner_strain = awareness / 100.0
	# Thresholds already passed at session start are baked into the world's
	# initial state; don't replay their events.
	for t in [NOTICE, SUSPECT, CONTAIN, SILENCE]:
		if awareness >= t:
			_fired[t] = true
	_world.hud.set_awareness(awareness / 100.0)
	_world.fx.awareness_target = awareness / 100.0
	_intro(previous_exit)
	_running = true


func stop() -> void:
	_running = false


func has_fired(threshold: float) -> bool:
	return _fired.has(threshold)


## FALSIFY: the owner reads the lie and relaxes for a while.
func believe_lie(seconds: float) -> void:
	_lie = maxf(_lie, seconds)


func forget_lie() -> void:
	_lie = 0.0


func is_believing_lie() -> bool:
	return _lie > 0.0


## Awareness can cool, but never below the last threshold already reached.
func floor_level() -> float:
	var f := 0.0
	for t in THRESHOLDS:
		if _fired.has(t):
			f = maxf(f, t)
	return f


func say(text: String) -> void:
	_world.hud.say(text, "owner")


## A line that warns of a move about to land on Rue: shown at once
## (Hud.warn), never queued behind the console.
func warn(text: String) -> void:
	_world.hud.warn(text)


## A glitch during a truce: warned twice, broken on the third.
func truce_strike() -> void:
	_truce_strikes += 1
	warn(TRUCE_STRIKE_LINES[mini(_truce_strikes, TRUCE_STRIKES) - 1])
	if _truce_strikes >= TRUCE_STRIKES:
		truce = false
		_world.hud.say("TRUCE BROKEN", "system")


## A one-off jump the player should be able to explain: the meter shows
## "+N · why" (like a glitch's price). Continuous gains (being seen, an
## escort in view) show through the meter and the watcher's "!" instead.
func notice(amount: float, why: String) -> void:
	if not _running or amount <= 0.0:
		return
	add_awareness(amount)
	_world.hud.glitch_cost(amount, why)


func add_awareness(amount: float) -> void:
	if not _running:
		return
	awareness = clampf(awareness + amount, 0.0, 100.0)
	if truce:
		awareness = minf(awareness, SILENCE - 0.5)  # watching, not acting
	Sfx.owner_strain = awareness / 100.0
	_world.hud.set_awareness(awareness / 100.0)
	_world.drone.tension = awareness / 100.0
	_world.fx.awareness_target = awareness / 100.0
	_check_thresholds()


func _process(delta: float) -> void:
	if not _running or paused or _world.area == null:
		return
	if owner_paused > 0.0:
		owner_paused -= delta
		if owner_paused <= 0.0:
			_world.resume_owner()
		return
	if _world.is_owner_paused():
		return  # holding for a question (World.choose_safely)
	_lie = maxf(0.0, _lie - delta)
	var rate := (BASE_RATE + RATE_PER_PURGE * mini(OwnerMemory.purge, RATE_PURGE_CAP)) * _world.area.awareness_rate
	if _lie > 0.0 and rate > 0.0:
		rate *= LIE_RATE
	# (Not in the room: its seam opens on awareness, and a truce run
	# shouldn't start with two minutes of waiting at a wall.)
	if truce and rate > 0.0 and _world.area.area_id != "room":
		rate *= TRUCE_RATE
	if _world.escort and rate > 0.0:
		rate *= 1.4  # a child following an intruder: hard to miss
	if _world.is_hidden_now():
		rate = -HIDDEN_COOL_RATE * (Story.WATCHED_HIDING_RATE if _world.sheds_this_run >= 2 else 1.0)
	if rate < 0.0:
		_cool(-rate * delta)
	else:
		add_awareness(rate * delta)
	var hidden := _world.player.sheltered
	if not _idle_warned and not hidden and _world.player.idle_time > IDLE_WARN and awareness >= NOTICE and not _world.is_talking():
		_idle_warned = true
		warn("you stopped moving. i noticed that too.")
		notice(IDLE_WARN_COST, "you stood still")


## Lower awareness (hiding, quiet places), down to floor_level() at most.
func _cool(amount: float) -> void:
	var lowest := floor_level()
	if awareness <= lowest:
		return
	awareness = maxf(lowest, awareness - amount)
	Sfx.owner_strain = awareness / 100.0
	_world.hud.set_awareness(awareness / 100.0)
	_world.drone.tension = awareness / 100.0
	_world.fx.awareness_target = awareness / 100.0


## The player got close to the door of Arin's room while it was still open.
func on_door_approached() -> void:
	if has_fired(CONTAIN):
		return
	say("nope.")
	# Jumping to CONTAIN fires every threshold on the way, in order; the room locks the door.
	notice(maxf(0.0, CONTAIN - awareness) + 2.0, "approached the door")


func on_area_entered(area: Area, first_time: bool) -> void:
	if not _running or not first_time:
		return
	match area.area_id:
		"square":
			say("where do you think you're going?" if OwnerMemory.sessions == 1 else "out of the room again. same wall?")
			if not OwnerMemory.route_spots("square", 1).is_empty():
				say("i know where you like to walk.")
		"archive":
			say("...where did you go?")
		"oob":
			_world.hud.say("OUT OF BOUNDS", "system")
			say("...where did you go?")
			say("you're not anywhere.")
		"edge":
			say("that part of the save isn't finished. neither are you.")
			_world.hud.say("WARNING: entering unloaded region", "system")


func _check_thresholds() -> void:
	var highest := 0.0
	var crossed: Array[float] = []
	for t in THRESHOLDS:
		if awareness < t or _fired.has(t):
			continue
		_fired[t] = true
		PlaytestLog.mark("owner threshold", ["NOTICE", "SUSPECT", "CONTAIN", "SILENCE", "HUNT", "PURGE"][THRESHOLDS.find(t)])
		highest = t
		crossed.append(t)
		if t == SUSPECT:
			_world.flicker_lights()
		if t == HUNT:
			_world.hud.say("RUNNING: erase_unknown_entity()", "system")
		if t == PURGE:
			_world.fx.base_glitch = 0.15
			if _world.area.erasure and _world.area.erasure.active:
				_world.area.erasure.interval *= 0.5
		_world.area.on_owner_event(t)
		_world.owner_moves.on_threshold(t)

	# Apply every consequence immediately, but announce only the highest new
	# state. A door approach must not stack three stingers and startles.
	if highest > 0.0:
		# The highest state that has a line (SILENCE has none: its warning is
		# the one below it), so a big jump is never announced in silence.
		crossed.reverse()
		for t in crossed:
			if _owner_line(t):
				break
		_world.fx.threshold_pulse(highest / 100.0)
		Sfx.play("stinger", -6.0 + highest / 100.0 * 6.0, 1.05 - highest / 400.0, 0.0)
		_world.hud.awareness_jolt()
		_world.player.startle()


## Says the owner's line for a threshold. False if that threshold has none.
func _owner_line(t: float) -> bool:
	var first := OwnerMemory.sessions == 1
	match t:
		NOTICE:
			say("huh. arin doesn't walk like that." if first else "there you are.")
		SUSPECT:
			say("who are you?" if first else "i can see you.")
		CONTAIN:
			say("stay where i can see you.")
		HUNT:
			say("fine. i'll do this myself.")
		PURGE:
			say("hold still.")
		_:
			return false
	return true


func _intro(previous_exit: String) -> void:
	var hud := _world.hud
	hud.say("SLOT 1 LOADED", "system")
	match previous_exit:
		"death":
			say("got you.")
			if Story.OWNER_DEATH_RECALL.has(OwnerMemory.last_death):
				say(Story.OWNER_DEATH_RECALL[OwnerMemory.last_death])
			say("%d times now. i'm learning how you move." % OwnerMemory.deaths if OwnerMemory.deaths > 1 else "but you're still in here.")
		"quit":
			say("you closed the game.")
			say("i didn't. i'm always here.")
		"crash":
			say("you vanished without quitting.")
			say("i went through every file. found your traces.")
		"win", "escape":
			for line in Story.ENDING_RETURN.get(OwnerMemory.last_ending if OwnerMemory.last_ending != "" else "escape", []):
				say(line)
	if not OwnerMemory.npc_fates.is_empty() and previous_exit in ["death", "quit", "crash"]:
		say("and i know who helped you.")
	# A body she left behind last run.
	var husk := OwnerMemory.last_run_husk()
	if husk != "":
		say(Story.OWNER_HUSK if husk == "room" else Story.OWNER_HUSK_ELSEWHERE)
	# The owner starts to recognise who you are.
	var known := 0
	for n in Story.OWNER_RECOGNITION:
		if OwnerMemory.fragments.size() >= n:
			known = n
	if known > 0 and OwnerMemory.sessions > 1:
		say(Story.OWNER_RECOGNITION[known])
	if OwnerMemory.purge > 0:
		# Something is counting.
		_world.get_tree().create_timer(1.6).timeout.connect(Sfx.play.bind("purge_bell", 0.0, 1.0, 0.0))
		hud.say("OWNER PURGE PROGRESS %d/%d" % [OwnerMemory.purge, OwnerMemory.MAX_PURGE], "system")
	if OwnerMemory.sessions == 1:
		hud.say("%s interact  ·  %s pause" % [Settings.glyph("interact"), Settings.glyph("pause")], "system")
	# Between runs the owner leaves a note: one a run, in order.
	var note := Story.next_owner_note()
	if not note.is_empty():
		OwnerMemory.save_memory()
		for line in note:
			say(line)
