extends "res://tests/test_case.gd"
## The playthrough bot: plays the whole game with real input, the way a
## careful player would, and retries after every death (memories, Pip and
## everything else the save keeps carry over, like for a person).
##
## One run: wake up, phase through the cracked wall for the first memory,
## leave through the seam; down the well, across the streaming floor to Pip
## and the second memory, back up; the Archive (the pointer and a memory);
## the Recycle Bin if anyone needs restoring; the north road; both memories
## at the Edge; lure the cursor, write into Slot 2, pick an ending.
## Glitches: breaks saves, freezes Arin up close, blinds a cursor that's on
## top of it.
##
##   tests/run.sh --bots                       every bot
##   tests/run.sh --bots --speed=3             3x game speed
##   tests/run.sh --bots --filter=escape       one of them
##
## Prints BOT lines: each step with game time and awareness, every death and
## why, and a summary. Fails only if no ending is reached in MAX_SESSIONS.

const MAX_SESSIONS := 8
const STEP_TIMEOUT := 40.0

var _log: Array[String] = []
var _t0 := 0.0
var _session := 0
var _deaths: Array[String] = []
var _glitches := 0
var _reloads := 0
var _in_rewind := false
var _stalls := 0


func test_full_game_escape() -> void:
	await _playthrough("escape", 0)


func test_full_game_message() -> void:
	await _playthrough("message", 0)


func test_full_game_escape_purge_3() -> void:
	await _playthrough("escape", 3)


func test_wren_ending() -> void:
	await _playthrough("wren", 0)


# --- the run ---------------------------------------------------------------------

func _playthrough(ending: String, purge: int) -> void:
	memory().wipe()
	memory().last_exit = "death"  # skip the boot cinematic
	if purge > 0:
		memory().sessions = purge
		memory().purge = purge
		memory().deaths = purge
	_t0 = _now()
	var w := await start_session(true, purge == 0)
	var result := ""
	for s in MAX_SESSIONS:
		_session = s + 1
		_say("session %d starts (purge %d, memories %d)" % [_session, memory().purge, memory().fragments.size()])
		if w.purged:
			result = "purged (the owner won)"
			break
		result = await _play_session(w, ending)
		_release_all()
		if result != "death":
			break
		_deaths.append(_death_note(w))
		_say("DIED: %s" % _deaths[-1])
		w = await wait_for_new_session(w)
	var summary := "BOT SUMMARY %s purge %d: %s after %d session(s), %.0f s of game time · memories %d/5 · pip %s · deaths %d %s · glitches %d · reloads %d · stalls %d" % [
		ending, purge, result, _session, _now() - _t0, memory().fragments.size(), memory().found_pip,
		_deaths.size(), str(_deaths), _glitches, _reloads, _stalls]
	print(summary)
	check(result.begins_with("ending"), "the bot reached an ending (%s)" % result)


## One session; returns "ending:<id>", "death" or "stuck:<where>".
func _play_session(w: Node, ending: String) -> String:
	# Arin's room.
	if not memory().has_fragment("controller"):
		if not await _room_memory(w):
			return _why(w, "room memory")
	if not await _leave_room(w):
		return _why(w, "leaving the room")
	_step(w, "out of the room")
	# Ashvale. Wren first, if she's coming along.
	if ending == "wren" and w.escort == null and not memory().is_deleted("wren"):
		if not await _take_wren(w):
			return _why(w, "asking Wren")
		_step(w, "Wren comes along")
	if ending != "wren" and not (memory().has_fragment("well") and memory().found_pip):
		if not await _down_the_well(w):
			return _why(w, "out of bounds")
		_step(w, "out of bounds done")
	if not await _archive(w, ending != "wren"):
		return _why(w, "the archive")
	_step(w, "archive done")
	if not await _north(w):
		return _why(w, "the north road")
	_step(w, "at the Edge")
	return await _edge(w, ending)


func _why(w: Node, where: String) -> String:
	return "death" if w.ending == "death" else "stuck:" + where


# --- areas -------------------------------------------------------------------------

func _room_memory(w: Node) -> bool:
	var crack: Vector2 = ArinsRoom.CRACK
	if not await _go(w, [Vector2(320, 220), crack + Vector2(0, 30), crack + Vector2(0, 10)]):
		return false
	# Face the crack and glitch through it.
	for attempt in 3:
		await _nudge(w, Vector2.UP, 0.15)
		await _glitch(w)
		if w.player.global_position.y < 116.0:
			break
	if w.player.global_position.y >= 116.0:
		return false
	await _go(w, [Vector2(505, 100)], 6.0)
	await _wait_cutscene(w)
	_step(w, "memory: the second controller")
	return w.ending == ""


func _leave_room(w: Node) -> bool:
	var room: ArinsRoom = w.area
	# Out of the nook if we're in it (the wall is down by now).
	if w.player.global_position.y < 120.0 and w.player.global_position.x > 455.0:
		await _go(w, [Vector2(500, 140)], 6.0)
	if room.seam == null:
		return false
	# Pace until the wall tears (the owner gets suspicious).
	var pace := 0
	var until := _now() + 60.0
	while not room.seam.open and w.ending == "" and _now() < until:
		await _go(w, [Vector2(220 + (pace % 2) * 120, 200)], 4.0)
		pace += 1
	if not room.seam.open:
		return false
	var c: Vector2 = room.seam.global_position
	var out := _outward(room.bounds, c)
	await _go(w, [c - out * 24.0, c + out * 20.0], 10.0)
	return await _arrived(w, "square")


func _take_wren(w: Node) -> bool:
	var wren: Npc = w.area.wren
	if wren == null:
		return false
	for i in 4:
		await _go(w, [wren.global_position + Vector2(14, 0)], 10.0)
		await press("interact")
		await frames(3)
		var opened: bool = w.hud.is_dialogue_open()
		await _read_dialogue(w)
		await frames(3)
		_say("talked to Wren (%d): opened %s, focus %s, asked %s, choosing %s" % [i, opened, w._focused, w.area._wren_asked, w.hud.is_choosing()])
		if w.hud.is_choosing():
			await press("interact")  # "Take her with you"
			await frames(3)
			await _read_dialogue(w)
			return w.escort != null
	return false


func _down_the_well(w: Node) -> bool:
	if not await _go(w, [Vector2(150, 150), Vector2(260, 196), Vector2(320, 196)], 20.0):
		return false
	await _interact_until_gone(w, "square")
	if not await _arrived(w, "oob"):
		return false
	# Over the streaming floor to Pip's ledge.
	if not await _oob_cross(w, true):
		return false
	if not memory().has_fragment("well"):
		await _go(w, [Vector2(540, 112)], 6.0)
		await _wait_cutscene(w)
		_step(w, "memory: the well")
	if not memory().found_pip and w.pip == null:
		await _go(w, [OutOfBounds.PIP_POS + Vector2(0, 14)], 6.0)
		await press("interact")
		await _read_dialogue(w)
		await frames(10)
		_step(w, "pip found: %s" % memory().found_pip)
	if not await _oob_cross(w, false):
		_say("couldn't get back across (at %s)" % w.player.global_position.round())
		return false
	await _go(w, [OutOfBounds.PILLAR_POS + Vector2(4, 8)], 8.0)
	await _interact_until_gone(w, "oob", OutOfBounds.PILLAR_POS + Vector2(4, 8))
	if not await _arrived(w, "square"):
		_say("the pillar didn't take us up (at %s, focus %s)" % [w.player.global_position.round(), w._focused])
		return false
	return true


## The route across, one floor chunk at a time: [where to wait (on an
## anchor), chunk index, the path over it (ending on the next anchor)].
const OOB_OUT := [
	[Vector2(134, 77), 0, [Vector2(240, 77)]],
	[Vector2(255, 90), 1, [Vector2(255, 208)]],
	[Vector2(280, 225), 2, [Vector2(414, 225)]],
	[Vector2(433, 206), 3, [Vector2(433, 121), Vector2(492, 121)]],
]
const OOB_BACK := [
	[Vector2(492, 121), 3, [Vector2(433, 121), Vector2(433, 208)]],
	[Vector2(414, 225), 2, [Vector2(280, 225)]],
	[Vector2(255, 208), 1, [Vector2(255, 90)]],
	[Vector2(240, 77), 0, [Vector2(134, 77)]],
]


func _oob_cross(w: Node, outbound: bool) -> bool:
	var legs: Array = OOB_OUT if outbound else OOB_BACK
	var tries := 0
	var i := 0
	while i < legs.size():
		if w.ending != "" or tries > 12:
			return false
		var leg: Array = legs[i]
		if not await _go(w, [leg[0]], 10.0):
			_say("didn't reach the wait point %s (at %s)" % [leg[0], w.player.global_position.round()])
			if _at_entry(w):
				# Fell on the way: outbound, start over; on the way back, the
				# fall put us next to the pillar anyway.
				if not outbound:
					return true
				tries += 1
				i = 0
				continue
			return false
		# Wait until the chunk has just appeared, then cross.
		var offset: float = OutOfBounds.CHUNKS[leg[1]][1]
		var until := _now() + 8.0
		while _now() < until:
			var phase: float = fmod(w.area._t + offset, OutOfBounds.PERIOD)
			if phase < 0.25:
				break
			_steer(w, Vector2.ZERO)
			await frames(1)
		await _go(w, leg[2], 4.0)
		var end: Vector2 = leg[2][-1]
		if w.player.global_position.distance_to(end) > 12.0:
			tries += 1
			_say("fell out of bounds (try %d)" % tries)
			if not outbound and _at_entry(w):
				return true
			i = 0 if outbound else i
			continue
		i += 1
	return w.ending == ""


func _at_entry(w: Node) -> bool:
	return w.player.global_position.distance_to(OutOfBounds.ENTRY) < 30.0


func _archive(w: Node, with_bin: bool) -> bool:
	var from: Vector2 = w.player.global_position
	var path: Array = [Vector2(320, 272), Vector2(590, 272), Vector2(590, 182), Vector2(640, 182)]
	if from.y < 160.0:
		path = [Vector2(150, 150), Vector2(150, 272)] + path.slice(1)
	if not await _go(w, path, 30.0):
		pass
	if not await _arrived(w, "archive"):
		return false
	# The Archivist: the pointer to Slot 2.
	if not w.flags.get("pointer", false):
		await _go(w, [Vector2(320, 172)], 8.0)
		await press("interact")
		await frames(4)
		await _read_dialogue(w)
	for f in Story.fragments_in("archive"):
		if not memory().has_fragment(f.id):
			await _go(w, [Vector2(360, 170), Vector2(525, 170), Vector2(525, 100), f.pos], 14.0)
			await _wait_cutscene(w)
			_step(w, "memory: %s" % f.id)
	if with_bin and not memory().npc_fates.is_empty():
		await _bin(w)
	await _go(w, [Vector2(525, 170), Vector2(300, 170), Vector2(110, 180), Vector2(80, 180)], 18.0)
	return await _arrived(w, "square")


func _bin(w: Node) -> void:
	await _go(w, [Vector2(525, 180), Vector2(560, 180)], 8.0)
	if not await _arrived(w, "bin"):
		return
	var bin: RecycleBin = w.area
	for f in bin.files:
		var guard := 0
		while not f.done and w.ending == "" and guard < 6:
			guard += 1
			await _shelter_through_sweep(w, bin)
			await _go(w, [f.global_position + Vector2(0, 14)], 6.0)
			if f.can_interact():
				await press("interact")
			while not f.done and w.ending == "" and bin.next_empty > RecycleBin.WARNING + 0.6 and bin.sweep_x < 0.0:
				_steer(w, Vector2.ZERO)
				await frames(1)
		if f.done:
			_step(w, "restored %s" % f.npc_id)
	await _shelter_through_sweep(w, bin)
	await _go(w, [Vector2(118, 180), Vector2(80, 180)], 12.0)
	await _arrived(w, "archive")


## If the bin is about to empty (or is emptying), wait it out in a shadow.
func _shelter_through_sweep(w: Node, bin: RecycleBin) -> void:
	if bin.next_empty > RecycleBin.WARNING + 2.5 and bin.sweep_x < 0.0:
		return
	var best := Vector2.INF
	for r in RecycleBin.SYSTEM_FILES:
		var spot := Vector2(r.end.x + 12, r.get_center().y)
		if best == Vector2.INF or w.player.global_position.distance_to(spot) < w.player.global_position.distance_to(best):
			best = spot
	await _go(w, [best], 5.0)
	while w.ending == "" and (bin.sweep_x >= 0.0 or bin.next_empty <= RecycleBin.WARNING + 0.5):
		_steer(w, Vector2.ZERO)
		await frames(1)


func _north(w: Node) -> bool:
	var p: Vector2 = w.player.global_position
	var path: Array = [Vector2(560, 180), Vector2(560, 110), Vector2(320, 110), Vector2(320, 20)]
	if p.x < 300.0:
		path = [Vector2(150, 150), Vector2(180, 100), Vector2(320, 100), Vector2(320, 20)]
	await _go(w, path, 30.0)
	return await _arrived(w, "edge")


func _edge(w: Node, ending: String) -> String:
	for f in Story.fragments_in("edge"):
		if not memory().has_fragment(f.id) and w.ending == "":
			await _go(w, [Vector2(320, 262), f.pos], 15.0)
			await _wait_cutscene(w)
			if memory().has_fragment(f.id):
				_step(w, "memory: %s" % f.id)
	if w.ending != "":
		return "death"
	# Lure the cursor far from the slot, then sprint.
	var cursor: OwnerCursor = w.area.cursor
	var lure := 0
	# Kite it to the bottom-left, staying well above the road home.
	await _go(w, [Vector2(320, 236), Vector2(140, 240)], 10.0)
	while w.ending == "" and cursor.global_position.distance_to(TheEdge.SLOT_POS) < 300.0 and lure < 30:
		await _go(w, [Vector2(140, 240 - (lure % 2) * 24)], 1.0)
		lure += 1
	# Let it come close (it's slower than us), then run for the slot.
	var wait_until_close := 0
	while w.ending == "" and cursor.global_position.distance_to(w.player.global_position) > 70.0 and wait_until_close < 40:
		_steer(w, Vector2.ZERO)
		await frames(3)
		wait_until_close += 1
	_step(w, "cursor lured (%d)" % lure)
	await _go(w, [Vector2(250, 236), Vector2(420, 236), Vector2(520, 230), Vector2(520, 90), TheEdge.SLOT_POS], 15.0)
	# The owner grabs the slot halfway: chase it, blind the cursor if close,
	# then write while Arin circles.
	var slot: SlotTwo = w.area.slot
	var until := _now() + 60.0
	while w.ending == "" and not w.hud.is_choosing() and not w._cutscene and _now() < until:
		if w.player.global_position.distance_to(slot.global_position) > 6.0:
			await _go(w, [slot.global_position], 1.0)
		else:
			_steer(w, Vector2.ZERO)
			if _should_glitch(w):
				await _glitch(w)
			await frames(2)
	if w._cutscene and w.ending == "":
		await until_choosing(w, 40.0)  # the owner's recap first
	if not w.hud.is_choosing():
		return "death" if w.ending == "death" else "stuck:slot 2"
	_step(w, "SLOT 2: choosing %s" % ending)
	var options: Array = []
	for b in w.hud._choice_list.get_children():
		options.append(b.text)
	# By name: hidden options can shift the list.
	var label: String = {"escape": "Write", "wren": "Wren", "message": "message"}.get(ending, "Write")
	var want := 0
	for i in options.size():
		if str(options[i]).contains(label):
			want = i
			break
	for i in want:
		await press("ui_down")
	await press("interact")
	if ending == "message":
		await frames(4)
		await press("interact")
	for i in 120:
		if w._win_card_shown:
			break
		await press("interact")
		await wait(0.25)
	var got: String = memory().last_ending
	return "ending:" + ("escape" if got == "rue" else got)


# --- moving --------------------------------------------------------------------------

## Walks through waypoints with real input. Steers around Arin and the cursor,
## glitches when it should, sidesteps when stuck. False if the session ended
## or the last point wasn't reached.
func _go(w: Node, points: Array, timeout := STEP_TIMEOUT) -> bool:
	var area_id: String = w.area.area_id
	for p: Vector2 in points:
		var left := timeout
		var last: Vector2 = w.player.global_position
		var still := 0.0
		var cutscene_for := 0.0
		while left > 0.0:
			if w.ending != "" or w.area.area_id != area_id or w._transitioning:
				if w.ending == "":
					_say("left %s unplanned (heading for %s, at %s)" % [area_id, p, w.player.global_position.round()])
				_release_all()
				return w.ending == ""
			_heartbeat(w, p)
			if w._cutscene or w.hud.is_dialogue_open():
				_steer(w, Vector2.ZERO)
				# Read like a player: story text waits for a press (manual advance).
				if w.hud.is_dialogue_open() or w.hud.is_cinematic():
					await press("interact")
					await wait(0.1)
				await frames(1)
				cutscene_for += tree.root.get_process_delta_time()
				if cutscene_for > 120.0:
					_stalls += 1
					_say("stall: a scene in %s never ended" % area_id)
					_release_all()
					return false
				continue
			cutscene_for = 0.0
			var d: Vector2 = p - w.player.global_position
			if d.length() < 5.0:
				break
			var n := _off_exits(w, _avoid(w, d.normalized()), p)
			if still > 0.5:
				# Stuck on something: phase through it if we can, else slide along.
				if still > 0.8 and w.glitch.target.get("id", "") == "phase":
					await _glitch(w)
					still = 0.0
					continue
				var side := n.orthogonal() * (1.0 if int(_now()) % 2 == 0 else -1.0)
				# Never sidestep out through a doorway beside the obstacle.
				if _near_exit(w, w.player.global_position + (n + side).normalized() * 40.0) or _near_exit(w, w.player.global_position + side * 30.0):
					side = -side
				n = (n + side).normalized()
			_steer(w, n)
			if _should_glitch(w):
				await _glitch(w)
			_track_rewinds(w)
			await frames(1)
			var dt: float = tree.root.get_process_delta_time()
			left -= dt
			still = still + dt if w.player.global_position.distance_to(last) < 0.3 else 0.0
			last = w.player.global_position
		if left <= 0.0:
			_stalls += 1
			_say("stall in %s going to %s, at %s" % [area_id, p, w.player.global_position.round()])
			_release_all()
			return false
	_release_all()
	return true


## Dodging the cursor or Arin must not carry the bot out through a doorway
## (unless the doorway is where it is going): the nearest heading that
## doesn't, else standing still.
func _off_exits(w: Node, n: Vector2, goal: Vector2) -> Vector2:
	var p: Vector2 = w.player.global_position
	if n == Vector2.ZERO or _near_exit(w, goal) or not w.area.bounds.grow(-4.0).has_point(goal) \
			or not _near_exit(w, p + n * 30.0):
		return n
	for turn in [0.5, -0.5, 1.0, -1.0, 1.5, -1.5]:
		var m := n.rotated(turn)
		if not _near_exit(w, p + m * 30.0):
			return m
	return Vector2.ZERO


func _near_exit(w: Node, p: Vector2) -> bool:
	for e: Exit in w.area.exits:
		if Rect2(e.global_position - e.size / 2.0, e.size).grow(16.0).has_point(p):
			return true
	return false


func _avoid(w: Node, n: Vector2) -> Vector2:
	var p: Vector2 = w.player.global_position
	for pair in [["arin", 44.0], ["cursor", 56.0]]:
		var h: Variant = w.area.get(pair[0])
		if h is Node2D:
			var away: Vector2 = p - h.global_position
			if away.length() < pair[1]:
				n = (away.normalized() * 1.5 + n * 0.4).normalized()
	# Dodging shouldn't carry us out of an exit we didn't mean to take
	# (the Edge's road home is right under the arrival point).
	if w.area.area_id == "edge" and p.y > 266.0 and n.y > 0.0:
		n = Vector2(n.x, -0.3).normalized()
	return n


func _should_glitch(w: Node) -> bool:
	if w.owner_moves.rewinding or not w.can_act():
		return false
	var t: Dictionary = w.glitch.target
	if t.is_empty():
		return false
	if w.owner_moves.save_progress > 0.25 or w.owner_moves.wren_delete > 0.3:
		return true
	if t.id == "freeze" and t.node is OwnerAvatar:
		return w.player.global_position.distance_to(t.node.global_position) < 50.0
	if t.id == "blind" and t.node is OwnerCursor:
		return w.player.global_position.distance_to(t.node.global_position) < 45.0
	return false


func _glitch(w: Node) -> void:
	_act("interact", true)
	await wait(0.8)
	_act("interact", false)
	await frames(2)
	_glitches += 1


func _nudge(w: Node, dir: Vector2, seconds: float) -> void:
	var until := _now() + seconds
	while _now() < until:
		_steer(w, dir)
		await frames(1)
	_release_all()


func _track_rewinds(w: Node) -> void:
	var now: bool = w.owner_moves.rewinding
	if now and not _in_rewind:
		_reloads += 1
		_say("the owner reloaded")
	_in_rewind = now


func _steer(_w: Node, n: Vector2) -> void:
	_axis("move_right", "move_left", n.x)
	_axis("move_down", "move_up", n.y)


func _axis(pos: String, neg: String, v: float) -> void:
	if v > 0.05:
		Input.action_press(pos, v)
		Input.action_release(neg)
	elif v < -0.05:
		Input.action_press(neg, -v)
		Input.action_release(pos)
	else:
		Input.action_release(pos)
		Input.action_release(neg)


func _release_all() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)


# --- waiting -------------------------------------------------------------------------

func _arrived(w: Node, id: String) -> bool:
	for i in 240:
		if w.ending != "" or not is_instance_valid(w):
			return false
		if w.area.area_id == id and not w._transitioning:
			return true
		await frames(1)
	return false


func _wait_cutscene(w: Node) -> void:
	await frames(3)
	var until := _now() + 30.0
	while (w._cutscene or w.hud.is_cinematic()) and w.ending == "" and _now() < until:
		if w.hud.is_cinematic():
			await press("interact")  # read each line, then move on (manual advance)
			await wait(0.15)
		await frames(2)
	await frames(3)


func _read_dialogue(w: Node) -> void:
	for i in 60:
		if not w.hud.is_dialogue_open():
			return
		await press("interact")
		await wait(0.05)


## Presses interact until we leave this area (a passage), reading anything
## that opens by mistake (Pip trotting close) and stepping back to `spot`.
func _interact_until_gone(w: Node, from_area: String, spot := Vector2.INF) -> void:
	for i in 10:
		if w.area.area_id != from_area or w._transitioning or w.ending != "":
			return
		if w.hud.is_dialogue_open():
			await _read_dialogue(w)
			if spot != Vector2.INF:
				await _go(w, [spot], 3.0)
		await press("interact")
		await wait(0.2)


func _outward(bounds: Rect2, c: Vector2) -> Vector2:
	var dl := absf(c.x - bounds.position.x)
	var dr := absf(c.x - bounds.end.x)
	var dt := absf(c.y - bounds.position.y)
	var db := absf(c.y - bounds.end.y)
	var m := minf(minf(dl, dr), minf(dt, db))
	if m == dl:
		return Vector2.LEFT
	if m == dr:
		return Vector2.RIGHT
	if m == dt:
		return Vector2.UP
	return Vector2.DOWN


# --- reporting -----------------------------------------------------------------------

var _beat := 0.0


## Every 10 s of game time: where the bot is and what it's waiting on.
func _heartbeat(w: Node, goal: Vector2) -> void:
	if _now() - _beat < 10.0:
		return
	_beat = _now()
	_say("... %s at %s -> %s  cutscene %s  dialogue %s  frozen %s" % [w.area.area_id, w.player.global_position.round(),
			goal, w._cutscene, w.hud.is_dialogue_open(), w.player.frozen])

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0 * Engine.time_scale


func _step(w: Node, what: String) -> void:
	_say("%-28s aw %3.0f" % [what, w.director.awareness])


func _say(text: String) -> void:
	var line := "BOT [s%d %6.1fs] %s" % [_session, _now() - _t0, text]
	_log.append(line)
	print(line)


func _death_note(w: Node) -> String:
	return "%s in %s" % [w.last_death if w.last_death != "" else "?", w.area.area_id]
