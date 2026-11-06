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


## The real first-time rules (Pacing staging: glitches open by memory,
## Tobben quiet in Act 1). The other bot routes keep the flat rules the
## suite tests with; these two prove the staged game can still be finished.
func test_full_game_escape_staged() -> void:
	Pacing.staged = true
	await _playthrough("escape", 0)
	Pacing.staged = false


func test_full_game_message_staged() -> void:
	Pacing.staged = true
	await _playthrough("message", 0)
	Pacing.staged = false


func test_full_game_escape_purge_3() -> void:
	await _playthrough("escape", 3)


## The last purge step before the save is lost (pass 8: the caps on the
## owner's growth must keep even this winnable).
func test_full_game_escape_purge_5() -> void:
	await _playthrough("escape", 5)


## A probe, not part of the bot suite (run with `-- --probe-scarred`): the
## late purge with two earlier deaths already on the square's road west. The
## square seeds its static where Rue died there before (Area.start_erasure),
## so this is the state the one failing purge-3 run reached in its last
## sessions (ISSUE_REGISTER PL-4).
func test_probe_purge_5_scarred_square() -> void:
	if "--probe-scarred" not in OS.get_cmdline_user_args():
		skip("a diagnostic probe; run with -- --probe-scarred")
		return
	await _playthrough("escape", 5, [Vector2(470, 108), Vector2(720, 96)])


func test_wren_ending() -> void:
	await _playthrough("wren", 0)


## The reckless hidden ending, played: every glitch the run can afford on
## the way to the slot, until the owner is at full awareness with ten
## glitches spent (World.is_reckless_run), then Slot 1 is overwritten.
func test_full_game_overwrite() -> void:
	await _playthrough("overwrite", 0)


## RUE, played over two runs, the way the save is built: the truth needs
## all five memories, and two of them are at the Edge, past the guard. Run 1
## takes the slot without it (escape). Memories survive an ending, so run 2
## starts knowing everything: Wren's piece in the square, Pip's FIRST HITBOX
## out of bounds, the CHARACTER FILE read whole in the Archive, then the
## slot again, written RUE. (Going back down from the Edge in run 1 was
## tried first: the guard, the cursor and the static killed it 2 of 2 times,
## see RELEASE_READINESS 2026-11-03.)
func test_full_game_rue() -> void:
	await _playthrough("rue", 0)


## RUE in ONE continuous playthrough (no ending in between): after the
## Edge's two memories, it refuses the slot and goes back south for the
## truth. If the way back kills it, the save keeps every memory (the first
## Edge death is forgiven) and the next session collects the truth before
## the Edge. Fails if any ending is taken first.
func test_full_game_rue_one_playthrough() -> void:
	await _playthrough("rue_one", 0)


## UNSEEN: no glitches of its own (the room's crack is the one allowed),
## and Arin must never see her (World.is_unseen_run). The route is the
## escape route's own lures; if Arin ever sees her the option is missing
## and the case fails as "unavailable", never as a pass.
func test_full_game_unseen() -> void:
	await _playthrough("unseen", 0)


# --- the run ---------------------------------------------------------------------

## The overwrite route glitches at every chance (a reckless player).
var _reckless := false


## The ending this run is playing for.
var _ending := ""


## Runs ended so far (RUE plays a second one).
var _runs := 0
## RUE without an ending in between (test_full_game_rue_one_playthrough).
var _one_playthrough := false


func _playthrough(ending: String, purge: int, square_deaths: Array = []) -> void:
	if OS.get_environment("BOT_STAGED") != "":
		Pacing.staged = true  # every route under the first-time rules
	var asked := ending
	if ending == "rue_one":
		_one_playthrough = true
		ending = "rue"
	else:
		_one_playthrough = false
	_ending = ending
	_runs = 0
	_edge_returns = 0
	_reckless = false  # the overwrite route turns reckless at the Edge (_be_reckless)
	memory().wipe()
	memory().last_exit = "death"  # skip the boot cinematic
	if purge > 0:
		memory().sessions = purge
		memory().purge = purge
		memory().deaths = purge
	for at: Vector2 in square_deaths:
		memory().deaths_log.append({"area": "square", "x": at.x, "y": at.y, "session": purge})
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
		if ending == "rue" and result == "ending:escape" and not memory().knows_truth and _runs < 2:
			# Run 1 is over; the next one starts from the title, like a player's.
			_runs += 1
			_say("run %d ended in escape: playing again for the truth" % _runs)
			if _reading:
				await _watch_epilogue()
			w = await start_session(true, false)
			continue
		if result != "death":
			break
		_reckless = false
		_deaths.append(_death_note(w))
		_say("DIED: %s" % _deaths[-1])
		for line in _trace:
			_say("   trace " + line)
		_trace.clear()
		_say_map(w)
		w = await wait_for_new_session(w)
	var summary := "BOT SUMMARY %s purge %d: %s after %d session(s), %.0f s of game time · memories %d/5 · pip %s · deaths %d %s · glitches %d · reloads %d · stalls %d" % [
		ending, purge, result, _session, _now() - _t0, memory().fragments.size(), memory().found_pip,
		_deaths.size(), str(_deaths), _glitches, _reloads, _stalls]
	print(summary)
	if _reading:
		await _watch_epilogue()
	# The ending asked for, exactly: a different ending is a failure, not a pass.
	check_eq(result, "ending:" + ending, "the bot reached the %s ending" % ending)
	if asked == "rue_one":
		check_eq(_runs, 0, "and no ending was taken before it (one continuous playthrough)")


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
	# RUE, a run that starts remembering everything: two of them have
	# noticed what she is (Story.truth_ready), then the Archive's file.
	if ending == "rue" and memory().fragments.size() >= Story.FRAGMENTS.size() and not memory().knows_truth:
		if not await _truth_pieces(w):
			return _why(w, "the truth pieces")
	# Wren deleted for helping in an earlier run: bring her back from the bin
	# like a player would, then fetch her again.
	if not await _archive(w, ending != "wren" or memory().is_deleted("wren")):
		return _why(w, "the archive")
	_step(w, "archive done")
	if ending == "wren" and w.escort == null and not memory().is_deleted("wren"):
		if not await _take_wren(w):
			return _why(w, "asking Wren (after the bin)")
		_step(w, "Wren comes along (after the bin)")
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
	for i in 8:
		# Her game comes before her ask (WREN_ARC.md): play it like a player,
		# a mark under the awning, then let her go and look.
		var sq: VillageSquare = w.area
		if Relationships.has("wren.game") and not Relationships.has("wren.mark_ok") and VillageSquare.pending_mark() == "" \
				and sq._wren_path.is_empty() and sq._wren_at_spot == "":
			await _go(w, [VillageSquare.CHALK_SPOTS.recess + Vector2(-8, 0)], 12.0)
			await _read_press()
			await frames(3)
			_step(w, "chalked a mark under the awning")
		if not sq._wren_path.is_empty():
			await wait_until(func() -> bool: return sq._wren_path.is_empty(), 20.0, "Wren reaching the mark")
		# Across the square the way she walks it (the straight line is blocked).
		var via: Array = [Vector2(400, 262)] if absf(w.player.global_position.x - wren.global_position.x) > 200.0 else []
		await _go(w, via + [wren.global_position + Vector2(14, 0)], 14.0)
		await _read_press()
		await frames(3)
		var opened: bool = w.hud.is_dialogue_open()
		await _read_dialogue(w)
		await frames(3)
		_say("talked to Wren (%d): opened %s, focus %s, asked %s, choosing %s" % [i, opened, w._focused, w.area._wren_asked, w.hud.is_choosing()])
		if w.hud.is_choosing():
			await _read_press()  # "Take her with you"
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
		await _read_press()
		await _read_dialogue(w)
		await frames(10)
		_step(w, "pip found: %s" % memory().found_pip)
	if _ending == "rue" and "pip" not in memory().truth_pieces and memory().fragments.size() >= Story.FRAGMENTS.size():
		# Pip's ledge: the shape Slot 2 was made with (a piece of the truth,
		# counted once its last line is read: World._on_line_revealed).
		await _go(w, [OutOfBounds.FIRST_SHAPE_POS + Vector2(-6, 6)], 6.0)
		await _read_press()
		await _read_dialogue(w)
		_step(w, "first hitbox read: pieces %s" % str(memory().truth_pieces))
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
			if _at_entry(w) or (not outbound and _on_landing(w)):
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
			if not outbound and _on_landing(w):
				return true
			i = 0 if outbound else i
			continue
		i += 1
	return w.ending == ""


func _at_entry(w: Node) -> bool:
	return w.player.global_position.distance_to(OutOfBounds.ENTRY) < 30.0


## On the landing ledge (where a fall puts her, and the pillar is): on the
## way back, that is home, wherever on the ledge she stands. (CI, 2026-11-03:
## a fall on the return left her 31 px from ENTRY, and the bot walked all
## the way out again.)
func _on_landing(w: Node) -> bool:
	return OutOfBounds.ANCHORS[0].grow(16.0).has_point(w.player.global_position)


func _archive(w: Node, with_bin: bool) -> bool:
	var from: Vector2 = w.player.global_position
	# (Out past the square's east edge: it's wider than the screen now.)
	var path: Array = [Vector2(320, 272), Vector2(590, 272), Vector2(590, 182), Vector2(w.area.bounds.end.x + 20.0, 182)]
	if from.y < 160.0:
		path = [Vector2(150, 150), Vector2(150, 272)] + path.slice(1)
	if not await _go(w, path, 30.0):
		pass
	if not await _arrived(w, "archive"):
		return false
	# The Archivist: the pointer to Slot 2 (kept in the save once given; the
	# bot still walks the same way past him, the route it knows is clear).
	await _go(w, [Vector2(320, 172)], 8.0)
	if not w.flags.get("pointer", false):
		await _read_press()
		await frames(4)
		await _read_dialogue(w)
	for f in Story.fragments_in("archive"):
		if not memory().has_fragment(f.id):
			await _go(w, [Vector2(360, 170), Vector2(525, 170), Vector2(525, 100), f.pos], 14.0)
			await _wait_cutscene(w)
			_step(w, "memory: %s" % f.id)
	if _ending == "rue" and Story.truth_ready() and not memory().knows_truth:
		await _read_character_file(w)
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
				await _read_press()
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


## Down through the south gap and out to the square, once Arin is clear of
## it (he enters there and circles the slot).
func _leave_edge_south(w: Node) -> bool:
	var gap := Vector2(320, w.area.bounds.end.y - 8.0)
	var waited := 0
	while w.ending == "" and w.area.area_id == "edge" and waited < 60:
		var arin: Node2D = w.area.get("arin")
		if arin == null or arin.global_position.distance_to(gap) > 150.0:
			break
		await _go(w, [Vector2(140, 240 - (waited % 2) * 24)], 1.0)
		waited += 1
	_say("leaving the edge for the truth after %d waits" % waited)
	await _go(w, [Vector2(320, 262), gap], 20.0)
	if w.area.area_id == "edge" and w.ending == "":
		await _nudge(w, Vector2.DOWN, 1.5)
	return await _arrived(w, "square")


## RUE's pieces, in a run that starts with every memory: Wren in the
## square (all five memories make her say what she noticed), then, if one
## more is needed, the FIRST HITBOX on Pip's ledge out of bounds.
func _truth_pieces(w: Node) -> bool:
	_say("for the truth: memories %d, pieces %s" % [memory().fragments.size(), str(memory().truth_pieces)])
	for i in 6:
		if Story.truth_ready() or "wren" in memory().truth_pieces or w.ending != "":
			break
		var wren: Npc = w.area.wren
		if wren == null:
			break
		var via: Array = [Vector2(400, 262)] if absf(w.player.global_position.x - wren.global_position.x) > 200.0 else []
		await _go(w, via + [wren.global_position + Vector2(14, 0)], 16.0)
		await _read_press()
		await frames(3)
		await _read_dialogue(w)
		if w.hud.is_choosing():
			await press("ui_down")  # "Not now": this run goes alone
			await _read_press()
			await frames(3)
			await _read_dialogue(w)
		_say("talked to Wren for her piece (%d): pieces %s" % [i, str(memory().truth_pieces)])
	if not Story.truth_ready() and w.ending == "":
		if not await _down_the_well(w):
			return false
	_step(w, "truth pieces %s, the file opens: %s" % [str(memory().truth_pieces), Story.truth_ready()])
	return Story.truth_ready()


## The CHARACTER FILE on the Archive desk, read to its last line: the truth.
func _read_character_file(w: Node) -> void:
	var file := Vector2(ArchiveArea.DESK.end.x + 10.0, ArchiveArea.DESK.get_center().y)
	await _go(w, [Vector2(525, 170), Vector2(file.x + 14.0, 172), file + Vector2(6, 14)], 14.0)
	for i in 3:
		if memory().knows_truth or w.ending != "":
			break
		await _read_press()
		await frames(3)
		await _read_dialogue(w)
		await _wait_cutscene(w)
	await _read_dialogue(w)
	_step(w, "the CHARACTER FILE: knows the truth %s" % memory().knows_truth)


func _north(w: Node) -> bool:
	# Planned again from wherever Rue is if the first try didn't get there
	# (the owner's reload can move her back, e.g. to just south of the well).
	for attempt in 2:
		var p: Vector2 = w.player.global_position
		var path: Array = [Vector2(560, 180), Vector2(560, 110), Vector2(320, 110), Vector2(320, 20)]
		if p.x < 300.0:
			path = [Vector2(150, 150), Vector2(180, 100), Vector2(320, 100), Vector2(320, 20)]
		await _go(w, path, 30.0)
		if w.area.area_id != "square" or w.ending != "":
			break
	return await _arrived(w, "edge")


## Stumbled out of the Edge (into the road home)? Walk back in and start
## again, as a player would; give up after a few tries.
var _edge_returns := 0


func _back_to_edge(w: Node, ending: String) -> String:
	_edge_returns += 1
	_say("back into the Edge (%d)" % _edge_returns)
	if _edge_returns > 3 or w.ending != "":
		return "death" if w.ending == "death" else "stuck:left the edge"
	if w.area.area_id == "square":
		await _go(w, [Vector2(320, 40), Vector2(320, 20)], 10.0)
	if not await _arrived(w, "edge"):
		return "stuck:left the edge"
	return await _edge(w, ending)


func _edge(w: Node, ending: String) -> String:
	for f in Story.fragments_in("edge"):
		if not memory().has_fragment(f.id) and w.ending == "":
			await _go(w, [Vector2(320, 262), f.pos], 15.0)
			await _wait_cutscene(w)
			if memory().has_fragment(f.id):
				_step(w, "memory: %s" % f.id)
	if w.ending != "":
		return "death"
	if w.area.area_id != "edge":
		return await _back_to_edge(w, ending)
	if _one_playthrough and not memory().knows_truth:
		# Every memory now: go back for the truth rather than take the slot.
		if not await _leave_edge_south(w):
			return "death" if w.ending == "death" else "stuck:leaving the edge"
		if not await _truth_pieces(w):
			return _why(w, "the truth pieces (one playthrough)")
		if not await _archive(w, false):
			return _why(w, "the archive (one playthrough)")
		if not await _north(w):
			return _why(w, "the north road (one playthrough)")
		_edge_returns = 0
		return await _edge(w, ending)
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
	if w.ending == "" and w.area.area_id != "edge":
		return await _back_to_edge(w, ending)
	_step(w, "cursor lured (%d)" % lure)
	if ending == "overwrite":
		await _be_reckless(w)
	await _go(w, [Vector2(250, 236), Vector2(420, 236), Vector2(520, 230), Vector2(520, 90), TheEdge.SLOT_POS], 15.0)
	if w.ending == "" and w.area.area_id != "edge":
		return await _back_to_edge(w, ending)
	# The owner grabs the slot halfway: chase it, blind the cursor if close,
	# then write while Arin circles.
	var slot: SlotTwo = w.area.slot
	var until := _now() + 60.0
	while w.ending == "" and not w.hud.is_choosing() and not w._cutscene and _now() < until:
		if w.area.area_id != "edge":
			return await _back_to_edge(w, ending)
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
	var escort_note := "escort %s%s" % [w.escort.npc_id if w.escort else "none",
		" (present)" if w.escort and w.escort.is_present() else ""]
	_say("SLOT 2 options %s · %s · wren deleted %s · memories %d · truth %s · seen by arin %s · glitches this run %d" % [str(options), escort_note,
		memory().is_deleted("wren"), memory().fragments.size(), memory().knows_truth,
		w.flags.get("seen_by_arin", false), memory().session_glitches])
	# By name: hidden options can shift the list. The option missing is a
	# result of its own, never a quiet fallback to the first one.
	var label: String = {"escape": "Write", "rue": Story.SLOT2_ESCAPE_NAMED, "unseen": Story.SLOT2_UNSEEN, "wren": "Wren", "message": "message", "overwrite": Story.SLOT2_OVERWRITE}.get(ending, "Write")
	if ending == "rue" and not memory().knows_truth:
		label = "Write"  # run 1: the slot without the truth (escape)
	var want := -1
	for i in options.size():
		if str(options[i]).contains(label):
			want = i
			break
	if want < 0:
		return "unavailable:%s (options %s, %s)" % [ending, str(options), escort_note]
	for i in want:
		await press("ui_down")
	await _read_press()
	if ending == "message":
		await frames(4)
		await _read_press()
	# Read up to the end card, and stop there: the card takes E too (touch
	# players), so one more press would leave for the title.
	for i in 120:
		if not is_instance_valid(w) or not w.is_inside_tree() or w._win_card_shown:
			break
		if w.ending != "" and not (w.hud.is_dialogue_open() or w.hud.is_cinematic() or w.hud.is_choosing()):
			await wait(0.25)
			continue
		await _read_press()
		await wait(0.25)
	return "ending:" + memory().last_ending  # exactly as recorded: escape and rue are different endings


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
				# Let the change finish before handing back: returning in the
				# same frame let a caller retry without ever yielding, so the
				# game never got a frame to complete the transition (CI hung
				# at the Edge's exit this way).
				var waited := 0
				while is_instance_valid(w) and w.is_inside_tree() and w._transitioning and waited < 600:
					await tree.process_frame
					waited += 1
				await tree.process_frame
				return w.ending == ""
			_heartbeat(w, p)
			if w._cutscene or w.hud.is_dialogue_open():
				_steer(w, Vector2.ZERO)
				# Read like a player: story text waits for a press (manual advance).
				if w.hud.is_dialogue_open() or w.hud.is_cinematic():
					await _read_press()
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
			_trace_step(w, n)
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
			# Before giving up: plan a way round with the area's own walking
			# grid (the one Arin uses), as a player would look for one, once.
			if not _replanning and w.ending == "":
				var grid := _grid(w)
				var route := grid.path(w.player.global_position, p)
				# The grid knows walls, not the static: a way round through
				# (or brushing) erased floor is no way round.
				if route.size() >= 2 and _through_static(w, route):
					_say("replan refused: the way round crosses the static")
				elif route.size() >= 2:
					_say("replanned round it (%d steps)" % route.size())
					_replanning = true
					# Walked a step at a time, looking again before each: the
					# static can grow onto a route after it was planned.
					var ok := true
					for q in Array(route).slice(1):
						if _through_static(w, PackedVector2Array([q])):
							_say("replan abandoned: the static reached the way round")
							ok = false
							break
						if not await _go(w, [q], 2.0):
							ok = false
							break
					_replanning = false
					if ok and w.player.global_position.distance_to(p) < 12.0:
						continue
			return false
	_release_all()
	return true


var _replanning := false


func _through_static(w: Node, route: PackedVector2Array) -> bool:
	var e: Variant = w.area.get("erasure")
	if e == null or not is_instance_valid(e):
		return false
	for q in route:
		if (e as Erasure).nearest_cell(q, 16.0) != Vector2.INF:
			return true
	return false


## The area's walking grid if a walker already built one (it stays fresh as
## doors and crates move), else a fresh one for this replan only, built the
## way Arin's is. Not stored on the area, so the game's own state is untouched.
func _grid(w: Node) -> NavGrid:
	if w.area.has_meta("nav_grid"):
		return w.area.get_meta("nav_grid")
	var grid := NavGrid.new()
	var skip: Array[RID] = [w.player.get_rid()]
	grid.build(w.area.get_world_2d().direct_space_state, w.area.bounds, w.player.collision_mask, skip, OwnerAvatar.RADIUS)
	return grid


## Dodging the cursor or Arin must not carry the bot out through a doorway
## (unless the doorway is where it is going): the nearest heading that
## doesn't, else standing still.
func _off_exits(w: Node, n: Vector2, goal: Vector2) -> Vector2:
	var p: Vector2 = w.player.global_position
	# Look ahead no further than the goal: a waypoint just short of a doorway
	# must still be reachable.
	var ahead := minf(30.0, p.distance_to(goal))
	if n == Vector2.ZERO or _near_exit(w, goal) or not w.area.bounds.grow(-4.0).has_point(goal) \
			or not _near_exit(w, p + n * ahead):
		return n
	for turn in [0.5, -0.5, 1.0, -1.0, 1.5, -1.5]:
		var m := n.rotated(turn)
		if not _near_exit(w, p + m * ahead):
			return m
	return Vector2.ZERO


func _near_exit(w: Node, p: Vector2) -> bool:
	for e: Exit in w.area.exits:
		if Rect2(e.global_position - e.size / 2.0, e.size).grow(16.0).has_point(p):
			return true
	return false


func _avoid(w: Node, n: Vector2) -> Vector2:
	var p: Vector2 = w.player.global_position
	# Arin walks a visible round: a player who sees him coming steps off
	# his line instead of walking into him (PL-4: the bot used to react only
	# inside 44 px, about 0.3 s head-on, and was caught walking into him
	# after a reload re-timed its crossing). Not a change to the game.
	var arin: Variant = w.area.get("arin")
	if arin is OwnerAvatar and arin.stunned <= 0.0:
		var to_arin: Vector2 = arin.global_position - p
		if to_arin.length() < 130.0 and n.dot(to_arin.normalized()) > 0.5:
			var side := to_arin.orthogonal().normalized()
			if side.dot(n) < 0.0:
				side = -side
			# Never sidestep into a wall: on the square's north road the bot
			# pinned itself against the top edge until Arin walked into it
			# (purge 5, "arin in square"). Step to the open side instead.
			var body: CharacterBody2D = w.player
			if body.test_move(body.global_transform, side * 8.0) and not body.test_move(body.global_transform, -side * 8.0):
				side = -side
			n = (side * 1.2 - to_arin.normalized() * 0.3).normalized()
	for pair in [["arin", 44.0], ["cursor", 56.0]]:
		var h: Variant = w.area.get(pair[0])
		if h is Node2D:
			var away: Vector2 = p - h.global_position
			if away.length() < pair[1]:
				n = (away.normalized() * 1.5 + n * 0.4).normalized()
	# Static ahead (the square's eraser at high purge): step round it, as a
	# player would, instead of walking into it.
	var e: Variant = w.area.get("erasure")
	if e is Erasure and e.active:
		# Look further ahead when frames are long: on a slow runner (CI; or
		# --max-fps 15 here) the static grew onto the bot between two looks
		# (purge 5: "eraser in square", 3 CI runs and 1 of 4 throttled runs).
		var ahead := 10.0 + clampf(w.get_physics_process_delta_time() * 600.0, 0.0, 30.0)
		var c: Vector2 = e.nearest_cell(p + n * ahead, 20.0 + ahead * 0.5)
		if c != Vector2.INF:
			n = ((p - c).normalized() * 1.4 + n * 0.5).normalized()
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
	if _reckless:
		return true  # the overwrite route: every glitch it can reach
	if _ending == "unseen":
		return false  # one glitch at most this run (World.is_unseen_run): none
	if w.owner_moves.save_progress > 0.25 or w.owner_moves.wren_delete > 0.3:
		return true
	if t.id == "freeze" and t.node is OwnerAvatar:
		return w.player.global_position.distance_to(t.node.global_position) < 50.0
	if t.id == "blind" and t.node is OwnerCursor:
		return w.player.global_position.distance_to(t.node.global_position) < 45.0
	return false


## For the overwrite route: spend glitches at the Edge until the run counts
## as reckless. Bounded; the result says if it never got there.
func _be_reckless(w: Node) -> void:
	_reckless = true  # from here to the slot, every glitch it can reach
	var tries := 0
	var dir := 1.0
	var why := {"cannot_act": 0, "no_target": 0, "glitched": 0}
	while w.ending == "" and not w.is_reckless_run() and tries < 300:
		tries += 1
		if w.area.area_id != "edge":
			return
		if not w.can_act():
			why.cannot_act += 1
			if w.hud.is_dialogue_open() or w.hud.is_cinematic():
				await _read_press()  # story text holds play: read on, like a player
			else:
				await wait(0.25)
			continue
		elif w.glitch.target.is_empty():
			why.no_target += 1
		else:
			why.glitched += 1
			await _glitch(w)
			continue
		# Keep moving (DECOY needs a run) and drift towards the cursor (BLIND).
		var cursor: Node2D = w.area.cursor
		var to: Vector2 = cursor.global_position - w.player.global_position if cursor else Vector2.ZERO
		var n := Vector2(dir, 0.0) if to.length() < 60.0 or to == Vector2.ZERO else to.normalized()
		if tries % 6 == 0:
			dir = -dir
		_steer(w, n)
		await wait(0.25)
	_release_all()
	_reckless = false  # reckless enough: now get to the slot
	_step(w, "reckless: %s (glitches %d, awareness %.0f, tries %s)" % [w.is_reckless_run(), memory().session_glitches, w.director.awareness, str(why)])


## The last 1.5 s of walking, printed when the bot dies, so a CI death
## says where the static was and which way the bot was going.
var _trace: Array[String] = []


## The area's static as text, 16 px a character: # settled, + young,
## R Rue, A Arin. Printed on a death by the static.
func _say_map(w: Node) -> void:
	var e: Variant = w.area.get("erasure")
	if not (e is Erasure):
		return
	var er: Erasure = e
	var arin: Variant = w.area.get("arin")
	var rp: Vector2 = w.player.global_position
	for y in range(int(er.bounds.position.y), int(er.bounds.end.y), 16):
		var row := ""
		for x in range(int(er.bounds.position.x), int(er.bounds.end.x), 16):
			var q := Vector2(x + 8, y + 8)
			if q.distance_to(rp) < 9.0:
				row += "R"
			elif arin is Node2D and q.distance_to(arin.global_position) < 9.0:
				row += "A"
			elif er.is_void(q):
				row += "#"
			elif er.nearest_cell(q, 6.0) != Vector2.INF:
				row += "+"
			else:
				row += "."
		_say("   map %4d %s" % [y, row])


func _trace_step(w: Node, n: Vector2) -> void:
	var p: Vector2 = w.player.global_position
	var e: Variant = w.area.get("erasure")
	var near := "-"
	if e is Erasure and e.active:
		var c: Vector2 = e.nearest_cell(p, 48.0)
		if c != Vector2.INF:
			near = "%s at %.0f px (void %s)" % [c.round(), c.distance_to(p), e.is_void(c)]
	_trace.append("%.2fs %s pos %s dir %s static %s%s" % [_now(), w.area.area_id, p.round(), (n * 10.0).round() / 10.0, near, " REWIND" if w.owner_moves.rewinding else ""])
	if _trace.size() > 45:
		_trace.pop_front()


func _glitch(w: Node) -> void:
	var need: float = GlitchController.hold_need(w.glitch.target) if not w.glitch.target.is_empty() else 0.5
	_act("interact", true)
	# Let go when it fires, as a player does (the cooldown starts then), or
	# after the hold plus a margin if it never does. Holding a fixed margin
	# past the fire cost purge 5 its run: each glitch held 0.13 s longer
	# than before the tap window grew, the owner's awareness crossed SILENCE
	# 0.1 earlier and could no longer cool under it.
	# _now() is game time: under the movie writer a wall-clock hold let go
	# before PHASE could fire.
	var until := _now() + GlitchController.HOLD_START + need + 0.3
	while _now() < until and w.glitch._cooldown <= 0.0:
		await frames(1)
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
	# Time, not frames: a passage between maps takes ~2 s (World travel
	# beats), more frames than a fast headless run used to allow.
	var until := _now() + 8.0
	while _now() < until:
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
			await _read_press()  # read each line, then move on (manual advance)
			await wait(0.15)
		await frames(2)
	await frames(3)


func _read_dialogue(w: Node) -> void:
	for i in 60:
		if not w.hud.is_dialogue_open():
			return
		await _read_press()
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
		await _read_press()
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

## For a film an observer can follow (BOT_READ=1, tools/record_film.sh):
## before pressing on, wait as long as a person needs for the text on
## screen. Off by default: the bot suite reads at once.
static var _reading := OS.get_environment("BOT_READ") != ""


## For the film: read the epilogue through, then let the title show.
func _watch_epilogue() -> void:
	var t := 0.0
	while t < 240.0:
		var w: Node = scene()
		if not (w is World):
			await wait(5.0)
			return
		var hud: Node = (w as World).hud
		if hud.is_cinematic() or hud.is_dialogue_open() or hud._overlay.visible:
			await _read_press()
			t += 2.0
		else:
			await wait(0.5)
			t += 0.5


func _read_press() -> void:
	if _reading:
		var w: Node = scene()
		var text := ""
		if w is World:
			var hud: Node = (w as World).hud
			if hud.is_dialogue_open():
				text = str(hud._dialogue_text.text)
			elif hud.is_cinematic():
				text = str(hud._cine_text.text) if "_cine_text" in hud else ""
		await wait(clampf(1.2 + text.length() / 16.0, 1.6, 7.0))
	await press("interact")


## The bot's clock: game time, summed from each frame's (scaled) delta.
## It used to be the wall clock times time_scale, which is only game time
## when the game keeps up with real time: under the movie writer
## (tools/record_film.sh, a third of real time) or --fixed-fps it drifted, and
## holds and timeouts ended at the wrong moment.
static var _clock := 0.0
static var _clock_on := false


func _now() -> float:
	if not _clock_on:
		_clock_on = true
		var t := tree
		t.process_frame.connect(func() -> void: _clock += t.root.get_process_delta_time())
	return _clock


func _step(w: Node, what: String) -> void:
	_say("%-28s aw %3.0f" % [what, w.director.awareness])


func _say(text: String) -> void:
	var line := "BOT [s%d %6.1fs] %s" % [_session, _now() - _t0, text]
	_log.append(line)
	print(line)


func _death_note(w: Node) -> String:
	return "%s in %s" % [w.last_death if w.last_death != "" else "?", w.area.area_id]
