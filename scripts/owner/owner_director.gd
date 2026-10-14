class_name OwnerDirector
extends Node
## The owner. Watches the session, gets more aware of you over time, and
## rewrites the room in response. Starts each session already knowing
## whatever OwnerMemory knows.

## Awareness thresholds (0..100) and what happens at each.
const NOTICE := 25.0
const SUSPECT := 40.0
const CONTAIN := 50.0
const SILENCE := 65.0
const HUNT := 75.0
const PURGE := 100.0

var awareness := 0.0

var _room: Room
var _fired: Dictionary = {}
var _idle_warned := false
var _running := false


func start(room: Room, previous_exit: String) -> void:
	_room = room
	# Capped below HUNT so even late sessions get a breath before the eraser.
	awareness = minf(OwnerMemory.purge * 15.0, HUNT - 5.0)
	# Thresholds already passed at session start are baked into the room's
	# initial state; don't replay their events.
	for t in [NOTICE, SUSPECT, CONTAIN, SILENCE]:
		if awareness >= t:
			_fired[t] = true
	_room.hud.set_awareness(awareness / 100.0)
	_intro(previous_exit)
	_running = true


func stop() -> void:
	_running = false


func add_awareness(amount: float) -> void:
	if not _running:
		return
	awareness = clampf(awareness + amount, 0.0, 100.0)
	_room.hud.set_awareness(awareness / 100.0)
	_room.drone.tension = awareness / 100.0
	_check_thresholds()


func _process(delta: float) -> void:
	if not _running:
		return
	add_awareness((1.1 + 0.5 * OwnerMemory.purge) * delta)
	if not _idle_warned and _room.player.idle_time > 6.0 and awareness >= NOTICE:
		_idle_warned = true
		_say("you stopped moving. i noticed that too.")
		add_awareness(5.0)


## The player got close to the door while it was still open.
func on_door_approached() -> void:
	if _room.door.state != Door.State.OPEN:
		return
	_say("nope.")
	# Jumping to CONTAIN fires every threshold on the way, in order; CONTAIN locks the door.
	add_awareness(maxf(0.0, CONTAIN - awareness) + 2.0)


func _check_thresholds() -> void:
	if _fire_once(NOTICE):
		_room.note.rewrite("Welcome home, Arin.\nSomeone else is here.")
		_say("huh. arin doesn't walk like that." if OwnerMemory.sessions == 1 else "there you are.")
	if _fire_once(SUSPECT):
		_room.flicker_lights()
		_say("who are you?" if OwnerMemory.sessions == 1 else "i can see you.")
	if _fire_once(CONTAIN):
		if _room.door.state == Door.State.OPEN:
			_room.door.lock()
			_room.fx.spike(0.6, 0.8)
		_say("stay where i can see you.")
		_room.hud.say("WARNING: wall integrity 97%", "system")
	if _fire_once(SILENCE):
		if _room.mira.delete():
			_room.fx.spike(0.8, 1.2)
			_say("don't talk to it, mira.")
			_room.hud.say("mira.npc deleted", "system")
	if _fire_once(HUNT):
		_room.start_erasure()
		_room.hud.say("RUNNING: erase_unknown_entity()", "system")
		_say("fine. i'll do this myself.")
	if _fire_once(PURGE):
		_room.erasure.interval *= 0.5
		_room.fx.base_glitch = 0.15
		_say("hold still.")


func _fire_once(threshold: float) -> bool:
	if awareness < threshold or _fired.has(threshold):
		return false
	_fired[threshold] = true
	return true


func _intro(previous_exit: String) -> void:
	var hud := _room.hud
	hud.say("SLOT 1 LOADED", "system")
	match previous_exit:
		"death":
			_say("got you.")
			_say("%d times now. i'm learning how you move." % OwnerMemory.deaths if OwnerMemory.deaths > 1 else "but you're still in here.")
		"quit":
			_say("you closed the game.")
			_say("i didn't. i'm always here.")
		"crash":
			_say("you vanished without quitting.")
			_say("i went through every file. found your traces.")
		"escape":
			var left := _room.seams_remaining()
			_say("found the gap you used. patched it.")
			_say("%d left. i'll find those too." % left if left > 0 else "there are no gaps left.")
	if OwnerMemory.purge > 0:
		hud.say("OWNER PURGE PROGRESS %d/%d" % [OwnerMemory.purge, OwnerMemory.MAX_PURGE], "system")
	if OwnerMemory.sessions == 1:
		hud.say("%s interact  ·  %s pause" % [Settings.glyph("interact"), Settings.glyph("pause")], "system")


func _say(text: String, kind: String = "owner") -> void:
	_room.hud.say(text, kind)
