class_name PressGate
extends RefCounted
## One owner per press of E (docs/INPUT_POLICY.md).
##
## "interact" and "confirm" are one logical button: E, Space and Enter on a
## keyboard, A on a pad (bound to both), the on-screen E (sends both). Each
## time that button goes down it is a new press with its own id. The first
## owner to take() a press acts on it; anyone else asking about the same
## press is refused, with the reason in the input trace. A press nobody took
## lives while it is held and for STALE_FRAMES after it is let go (a tap
## whose down and up land in one frame still counts), never longer: nothing
## is buffered across a scene or a modal.
##
## Owners: "hud" (dialogue reveal/advance, cinematics, choices), "world"
## (talk, use, charge a glitch), "retry", the openings. A modal that opens
## calls claim() so a press still held from play can't act inside it.
## cancel() marks the press as cancelled (OS cancel, drag-off, focus loss,
## rotation): its release then does nothing.
##
## Synced lazily from Input on the first question each process frame, so it
## works whatever order nodes and coroutines run in that frame.

## How many process frames after its release an untaken press may still be
## taken: the frame it was let go plus one (a press/release within one
## render interval is seen by consumers on the next process frame).
const STALE_FRAMES := 1
const ACTIONS: Array[String] = ["interact", "confirm"]

static var _synced := -1
static var _id := 0
static var _down := false
static var _down_frame := -1
static var _down_ms := 0
static var _up_frame := -1
static var _owner := ""
static var _canceled := false
static var _actions: Dictionary = {}


static func _sync() -> void:
	var f := Engine.get_process_frames()
	if f == _synced:
		return
	_synced = f
	var just := false
	var held := false
	for a in ACTIONS:
		if Input.is_action_just_pressed(a):
			just = true
		if Input.is_action_pressed(a):
			held = true
	# A new press: the button went down this frame (and it wasn't already
	# down, so the on-screen E sending interact then confirm is one press).
	if just and not _down:
		_id += 1
		_down_frame = f
		_down_ms = Time.get_ticks_msec()
		_owner = ""
		_canceled = false
		_actions.clear()
		for a in ACTIONS:
			if Input.is_action_just_pressed(a) or Input.is_action_pressed(a):
				_actions[a] = true
		InputTrace.add("press", "E", "", "new press #%d %s" % [_id, ",".join(_actions.keys())])
		if not held:
			_up_frame = f  # down and up inside one frame: a quick tap
	elif _down and not held:
		_up_frame = f
		InputTrace.add("release", "E", _owner, "press #%d after %d ms" % [_id, Time.get_ticks_msec() - _down_ms])
	_down = held


## The current press's id (0 before any press).
static func current() -> int:
	_sync()
	return _id


static func is_down() -> bool:
	_sync()
	return _down


## Is there a press nobody has taken yet, still live? need: the press must
## include this action ("interact" for the world, so Enter alone doesn't
## talk to people).
static func available(need := "") -> bool:
	return _why_not(need) == ""


static func _why_not(need: String) -> String:
	_sync()
	if _id == 0:
		return "no press yet"
	if _canceled:
		return "press cancelled"
	if _owner != "":
		return "already used by " + _owner
	if need != "" and not _actions.has(need):
		return "not a %s press" % need
	if not _down and Engine.get_process_frames() - _up_frame > STALE_FRAMES:
		return "stale (released %d frames ago)" % (Engine.get_process_frames() - _up_frame)
	return ""


## Take the current press for `owner`. True once per press, for one owner.
static func take(owner: String, need := "") -> bool:
	var why := _why_not(need)
	if why != "":
		# Only worth tracing when there was a real, recent press.
		if _id != 0 and Engine.get_process_frames() - maxi(_down_frame, _up_frame) <= STALE_FRAMES:
			InputTrace.add("refused", "E", owner, "press #%d: %s" % [_id, why], false)
		return false
	_owner = owner
	InputTrace.add("taken", "E", owner, "press #%d" % _id, true)
	return true


## A modal or transition takes whatever press is live, so it can't act in
## what opens next (a press held from play never advances a new line).
static func claim(reason: String) -> void:
	_sync()
	if _id != 0 and _owner == "" and (_down or Engine.get_process_frames() - _up_frame <= STALE_FRAMES):
		_owner = reason
		InputTrace.add("claimed", "E", reason, "press #%d" % _id)


## The press was cancelled (OS cancel, dragged off the button, focus lost,
## rotation): whatever owns it must not act on its release.
static func cancel(reason: String) -> void:
	_sync()
	if _id == 0 or (not _down and Engine.get_process_frames() - _up_frame > STALE_FRAMES):
		return
	if not _canceled:
		_canceled = true
		InputTrace.add("cancelled", "E", _owner, "press #%d: %s" % [_id, reason])


## Was this press (by id) cancelled?
static func was_canceled(id: int) -> bool:
	_sync()
	return id == _id and _canceled


## Who took the current press ("" if nobody yet).
static func owner_of_current() -> String:
	_sync()
	return _owner


## Tests.
static func reset() -> void:
	_synced = -1
	_down = false
	_owner = ""
	_canceled = false
	_actions.clear()
	_up_frame = -1
	_down_frame = -1
