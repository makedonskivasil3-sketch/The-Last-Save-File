class_name OwnerMoves
extends Node2D
## The owner doesn't just watch: they play. Signature moves, escalating with
## awareness and with how much you cheat:
##
##   LOAD LAST SAVE  Rue is dragged back along her path to where she was ~10 s
##                   ago, Arin and the cursor snap back, and every glitch
##                   effect is undone. Triggered by your 3rd glitch since the
##                   last load (once the owner has noticed you), or once when
##                   awareness reaches SILENCE.
##   SAVING OVER YOU A save ring fills over Rue: fast while you stand still,
##                   slowly while you move. Any glitch interrupts it. If it
##                   fills, you're overwritten. From HUNT on, every ~35 s, and
##                   whenever you stand still too long under suspicion.
##   DRAG            In the square, during the hunt, the cursor grabs the
##                   crate stack and drags it across the road you're heading
##                   for. Phase through it, or wait for it to be dragged back.
##   DELETE WREN     While Wren walks with you (and suspicion is up), the
##                   owner tries to delete her: a red ring fills over her.
##                   Any glitch interrupts it. If it fills, she's gone.
##   ROUTE MEMORY    Where Arin saw you is remembered (OwnerMemory.note_spot);
##                   next session Arin's patrol detours through those spots.
##
## None of this happens where the owner can't see (the Archive, out of
## bounds). Reduce flashing softens the rewind.

const SNAPSHOT_EVERY := 0.25
const HISTORY := 48             # 12 s of snapshots
const REWIND_BACK := 10.0       # seconds
const REWIND_TIME := 0.9        # how long the drag back takes
const LOAD_COOLDOWN := 40.0
const GLITCHES_PER_LOAD := 3
const SAVE_TIME := 4.0          # standing still
const SAVE_MOVING := 0.3        # fraction of the speed while you move
const SAVE_EVERY := 35.0
const IDLE_SAVE := 5.0          # standing still this long under suspicion
const DRAG_COOLDOWN := 25.0
const DRAG_HOLD := 14.0         # how long a dragged prop blocks the way
const SPOT_EVERY := 1.5
const WREN_DELETE_TIME := 5.0
const WREN_DELETE_EVERY := 30.0
## A reload never drops you into danger: it skips moments when the cursor or
## Arin were this close, and gives you a beat to react afterwards.
const SAFE_FROM_CURSOR := 64.0
const SAFE_FROM_ARIN := 44.0
const GRACE := 0.8
## Where the owner can't see you, there are no moves.
const BLIND_AREAS := ["archive", "oob"]

var world: World
## The save ring (0..1) while "Saving over you" runs; -1 when it doesn't.
var save_progress := -1.0
var rewinding := false
## The ring over Wren (0..1) while the owner deletes her; -1 otherwise.
var wren_delete := -1.0

var _history: Array[Dictionary] = []
var _snap_t := 0.0
var _clock := 0.0
var _load_cd := 0.0
var _glitches_since_load := 0
var _loaded_at_silence := false
var _next_save := INF
var _save_tick := 0.0
var _drag_cd := 8.0
var _drag_back := -1.0
var _spot_t := 0.0
var _next_wren := INF


func _ready() -> void:
	z_index = 17


func _owner_watching() -> bool:
	return world.area != null and not (world.area.area_id in BLIND_AREAS) and not world.is_owner_paused()


## Called by World every frame while the session runs.
func update(delta: float) -> void:
	_clock += delta
	_load_cd = maxf(0.0, _load_cd - delta)
	_drag_cd = maxf(0.0, _drag_cd - delta)
	_snapshot(delta)
	if rewinding or not _owner_watching():
		queue_redraw()
		return
	var aw := world.director.awareness
	_note_route(delta)
	# Saving over you.
	if _writing_slot():
		pass  # standing still in Slot 2 is the point: no save-over there
	elif save_progress >= 0.0:
		_update_save(delta)
	elif (aw >= OwnerDirector.HUNT and _clock >= _next_save) \
			or (aw >= OwnerDirector.SUSPECT and world.player.idle_time > IDLE_SAVE and _clock >= _next_save - SAVE_EVERY * 0.5):
		start_save_over()
	_update_drag(delta)
	_update_wren(delta, aw)
	queue_redraw()


## New area: the past belongs to the old one.
func on_area_changed() -> void:
	_history.clear()
	if save_progress >= 0.0:
		save_progress = -1.0
	_drag_back = -1.0


func on_threshold(t: float) -> void:
	if t == OwnerDirector.SILENCE and not _loaded_at_silence and _owner_watching():
		_loaded_at_silence = true
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			if is_inside_tree():
				load_last_save())
	if t == OwnerDirector.HUNT:
		_next_save = _clock + 3.0


## Every glitch is a provocation: it interrupts a save, and enough of them
## make the owner reload.
func on_glitch(_id: String) -> void:
	if wren_delete >= 0.0:
		wren_delete = -1.0
		world.director.say("...fine. later.")
		Sfx.play("denied", -2.0, 0.8)
	if save_progress >= 0.0:
		save_progress = -1.0
		world.hud.say("SAVE FAILED: SLOT 1 IN USE", "system")
		world.director.say("...the save failed. what did you do.")
		Sfx.play("denied", -2.0, 0.8)
		_next_save = _clock + SAVE_EVERY
		return
	_glitches_since_load += 1
	if _glitches_since_load >= GLITCHES_PER_LOAD and _load_cd <= 0.0 \
			and world.director.awareness >= OwnerDirector.NOTICE and _owner_watching():
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if is_inside_tree():
				load_last_save())


# --- LOAD LAST SAVE -----------------------------------------------------------------

func _snapshot(delta: float) -> void:
	_snap_t -= delta
	if _snap_t > 0.0 or rewinding:
		return
	_snap_t = SNAPSHOT_EVERY
	var s := {"t": _clock, "player": world.player.global_position}
	var arin: Variant = world.area.get("arin")
	if arin is OwnerAvatar:
		s["arin"] = arin.global_position
	var cursor: Variant = world.area.get("cursor")
	if cursor is OwnerCursor:
		s["cursor"] = cursor.global_position
	_history.append(s)
	if _history.size() > HISTORY:
		_history.pop_front()


## The owner reloads: Rue is dragged back ~10 seconds along her own path.
func load_last_save(force := false) -> void:
	if rewinding or _history.size() < 2 or world.ending != "" or not world.can_act():
		return
	if _load_cd > 0.0 and not force:
		return  # one reload at a time, however many glitches queued one
	rewinding = true
	OwnerMemory.total_reloads += 1
	_load_cd = LOAD_COOLDOWN
	_glitches_since_load = 0
	if save_progress >= 0.0:
		save_progress = -1.0
	var target := _pick_snapshot()
	var path: Array[Vector2] = [world.player.global_position]
	for i in range(_history.size() - 1, target - 1, -1):
		path.append(_history[i].player)
	var snap: Dictionary = _history[target]
	world.director.say(["no. loading autosave.", "let's try that again.", "rewind."].pick_random())
	world.hud.set_banner("◀◀  LOADING AUTOSAVE  ·  00:%02d AGO" % int(_clock - float(snap.t)))
	Sfx.play("unload", -2.0, 1.6)
	Sfx.play("transition", 0.0, 0.6)
	var flash := Settings.flash_scale()
	world.fx.spike(0.9 * flash, 1.0)
	world.fx.noise(0.9, 1.0)
	world.fx.roll_slip(0.2 * flash)
	world.player.frozen = true
	# Dragged back through every step you took.
	var tw := create_tween()
	var step := REWIND_TIME / maxf(1.0, path.size() - 1)
	for i in range(1, path.size()):
		tw.tween_property(world.player, "global_position", path[i], step)
	await tw.finished
	if not is_inside_tree() or world.ending != "":
		return
	_apply(snap)
	_undo_glitches()
	_history.resize(target + 1)
	world.player.frozen = false
	world.player.velocity = Vector2.ZERO
	rewinding = false
	_grace()
	await get_tree().create_timer(0.8).timeout
	if is_inside_tree() and world.hud.banner_text().begins_with("◀◀"):
		world.hud.set_banner("")


## The oldest moment within reach that's safe to land in: never the eraser's
## void, never under the cursor or within Arin's reach. If no moment is
## fully safe, the oldest one that isn't void.
func _pick_snapshot() -> int:
	var fallback := _history.size() - 1
	var safe := -1
	for i in range(_history.size() - 1, -1, -1):
		var s: Dictionary = _history[i]
		if _clock - float(s.t) > REWIND_BACK:
			break
		if _is_void(s.player):
			continue
		fallback = i
		if is_safe(s):
			safe = i
	return safe if safe >= 0 else fallback


## Would landing in this snapshot put Rue right next to a threat?
static func is_safe(s: Dictionary) -> bool:
	var p: Vector2 = s.player
	if s.has("cursor") and p.distance_to(s.cursor) < SAFE_FROM_CURSOR:
		return false
	if s.has("arin") and p.distance_to(s.arin) < SAFE_FROM_ARIN:
		return false
	return true


## After a reload you get a beat to see where you are: the cursor's click
## starts over and it loses you briefly; Rue flickers while it lasts.
func _grace() -> void:
	var cursor: Variant = world.area.get("cursor")
	if cursor is OwnerCursor:
		cursor.blind(GRACE)
	var tw := world.player.create_tween()
	for i in 3:
		tw.tween_property(world.player, "modulate:a", 0.35, GRACE / 6.0)
		tw.tween_property(world.player, "modulate:a", 1.0, GRACE / 6.0)


## Rue is writing herself into Slot 2.
func _writing_slot() -> bool:
	var slot: Variant = world.area.get("slot")
	return slot is SlotTwo and slot.is_writing()


func _apply(snap: Dictionary) -> void:
	var arin: Variant = world.area.get("arin")
	if arin is OwnerAvatar and snap.has("arin"):
		arin.global_position = snap.arin
	var cursor: Variant = world.area.get("cursor")
	if cursor is OwnerCursor and snap.has("cursor"):
		cursor.global_position = snap.cursor
	if world.pip:
		world.pip.arrive(world.player.global_position)


## A reload wipes what your glitches did to the world.
func _undo_glitches() -> void:
	var area := world.area
	var arin: Variant = area.get("arin")
	if arin is OwnerAvatar:
		arin.stunned = 0.0
	var cursor: Variant = area.get("cursor")
	if cursor is OwnerCursor:
		cursor.blinded = 0.0
	var door: Variant = area.get("door")
	if door is Door:
		door.relock()
	for node in area.interactables:
		if node is Note and node.falsified:
			node.unfalsify()
		elif node is Npc:
			node.frozen = 0.0
	if is_instance_valid(world.decoy):
		world.decoy.queue_free()
	world.director.forget_lie()


func _is_void(p: Vector2) -> bool:
	var e := world.area.erasure
	return e != null and e.is_void(p)


# --- SAVING OVER YOU ----------------------------------------------------------------

func start_save_over() -> void:
	if save_progress >= 0.0 or rewinding or _writing_slot() or not _owner_watching() or world.ending != "":
		return
	save_progress = 0.0
	_next_save = _clock + SAVE_EVERY
	world.director.say(["saving over you.", "i'll just save over you.", "hold still. it's saving."].pick_random())
	world.hud.say("SAVING SLOT 1 . . .", "system")


func _update_save(delta: float) -> void:
	var still: bool = world.player.velocity.length() < 10.0
	save_progress += delta / SAVE_TIME * (1.0 if still else SAVE_MOVING)
	_save_tick -= delta
	if _save_tick <= 0.0:
		_save_tick = lerpf(0.35, 0.08, save_progress)
		Sfx.play("key_system", -2.0, 0.6 + save_progress)
		if save_progress > 0.5:
			Settings.buzz(12)  # the ring, felt
	if save_progress >= 1.0:
		save_progress = -1.0
		world.hud.say("SAVE COMPLETE: 0 UNKNOWN ENTITIES", "system")
		world.kill("overwritten", "save")


# --- DELETE WREN ---------------------------------------------------------------------

func _update_wren(delta: float, aw: float) -> void:
	if world.escort == null or OwnerMemory.wren_saved:
		wren_delete = -1.0
		_next_wren = INF
		return
	if wren_delete >= 0.0:
		wren_delete += delta / WREN_DELETE_TIME
		if wren_delete >= 1.0:
			wren_delete = -1.0
			world.lose_escort()
		return
	if aw < OwnerDirector.SUSPECT:
		return
	if _next_wren == INF:
		_next_wren = _clock + 6.0
	elif _clock >= _next_wren:
		start_wren_delete()


func start_wren_delete() -> void:
	if world.escort == null or wren_delete >= 0.0:
		return
	wren_delete = 0.0
	_next_wren = _clock + WREN_DELETE_EVERY
	world.director.say("and you. wren.npc. delete.")
	Sfx.play("stinger", -6.0, 1.3, 0.0)


# --- DRAG ----------------------------------------------------------------------------

func _update_drag(delta: float) -> void:
	var area := world.area
	var prop: Variant = area.get("crates")
	var cursor: Variant = area.get("cursor")
	if not (prop is DragProp) or not (cursor is OwnerCursor) or cursor.is_dragging():
		return
	if _drag_back >= 0.0:
		_drag_back -= delta
		if _drag_back < 0.0:
			cursor.drag(prop, prop.home)  # done blocking: put it back
		return
	if _drag_cd > 0.0 or prop.global_position.distance_to(prop.home) > 2.0:
		return
	var p: Vector2 = world.player.global_position
	for block: Vector2 in area.call("block_points"):
		if p.distance_to(block) < 150.0 and p.distance_to(block) > 36.0:
			cursor.drag(prop, block)
			world.director.say("no. not that way.")
			_drag_cd = DRAG_COOLDOWN
			_drag_back = DRAG_HOLD
			return


func _note_route(delta: float) -> void:
	_spot_t -= delta
	if _spot_t > 0.0:
		return
	var arin: Variant = world.area.get("arin")
	if arin is OwnerAvatar and arin.can_see(world.player.global_position):
		OwnerMemory.note_spot(world.area.area_id, world.player.global_position)
		_spot_t = SPOT_EVERY


# --- the save ring -------------------------------------------------------------------

func _draw() -> void:
	if wren_delete >= 0.0 and world.escort:
		_draw_ring(world.escort.global_position + Vector2(0, -34), wren_delete, "DELETE wren.npc ?")
	if save_progress < 0.0:
		return
	var p: Vector2 = world.player.global_position + Vector2(0, -40)
	var flash := Settings.flash_scale()
	draw_circle(p, 11.0, Color(0, 0, 0, 0.7))
	draw_arc(p, 10.0, 0.0, TAU, 32, Color(1, 1, 1, 0.2), 2.0)
	var col := Color(1.0, 0.85, 0.85).lerp(Color(1.0, 0.2, 0.25), save_progress)
	if save_progress > 0.75 and fmod(Time.get_ticks_msec() * 0.01, 2.0) < 1.0 and flash >= 1.0:
		col = Color.WHITE
	draw_arc(p, 10.0, -PI * 0.5, -PI * 0.5 + TAU * save_progress, 32, col, 2.5)
	# A little floppy disk in the middle.
	draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), Color(0.75, 0.75, 0.8))
	draw_rect(Rect2(p - Vector2(2, 4), Vector2(4, 3)), Color(0.3, 0.3, 0.35))
	draw_string(ThemeDB.fallback_font, p + Vector2(-30, 21), "SAVING  %d%%" % int(save_progress * 100.0),
			HORIZONTAL_ALIGNMENT_CENTER, 60, 8, col)


func _draw_ring(p: Vector2, k: float, text: String) -> void:
	draw_circle(p, 10.0, Color(0, 0, 0, 0.7))
	draw_arc(p, 9.0, 0.0, TAU, 32, Color(1, 1, 1, 0.2), 2.0)
	draw_arc(p, 9.0, -PI * 0.5, -PI * 0.5 + TAU * k, 32, Color(1.0, 0.25, 0.3), 2.5)
	draw_line(p + Vector2(-4, -4), p + Vector2(4, 4), Color(1.0, 0.4, 0.4), 2.0)
	draw_line(p + Vector2(4, -4), p + Vector2(-4, 4), Color(1.0, 0.4, 0.4), 2.0)
	draw_string(ThemeDB.fallback_font, p + Vector2(-40, 20), text, HORIZONTAL_ALIGNMENT_CENTER, 80, 8, Color(1.0, 0.5, 0.5))
