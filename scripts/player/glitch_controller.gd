class_name GlitchController
extends Node2D
## Reads [E]: a tap interacts as always; holding it charges a glitch (see
## Glitch) on whatever it targets, and firing it costs awareness.
##
## Target, in order: the nearest glitchable thing in range (Arin, people,
## notes, a locked door, the cursor, the eraser's void, someone deleted),
## else the wall in front of you (PHASE), else yourself (DECOY while you're
## running, PAUSE while you stand still).
##
## While charging, a ring fills around Rue and a buzz rises; the target gets
## magenta brackets with the glitch's name and cost. When it fires, the
## target tears (GlitchBurst), the screen jolts, the cost flies up to the
## awareness meter, and the owner says something the first time.

## Holding shorter than this is a tap (interact).
const HOLD_START := 0.22
const COOLDOWN := 0.6
const MAGENTA := Color(1.0, 0.25, 0.6)
const CYAN := Color(0.55, 0.95, 1.0)
## PHASE needs a wall (or a gap in the floor) this close in front of you.
const PHASE_PROBE := 9.0
## A charge released before this fraction of its hold time counts as a tap.
const TAP_FRACTION := 0.5

var world: World
## Debug: every glitch, whatever your memories.
var unlock_all := false
## What holding [E] would hit right now: {"id", "pos", "node"} or {}.
var target: Dictionary = {}

var _pressing := false
var _held := 0.0
var _charge := 0.0
var _cooldown := 0.0
var _loop: AudioStreamPlayer
var _reacted: Dictionary = {}
var _probe_shape := RectangleShape2D.new()
var _t := 0.0


func _ready() -> void:
	z_index = 16
	_probe_shape.size = Vector2(7, 7)
	_loop = Sfx.loop_player("glitch_charge", self)


func unlocked(id: String) -> bool:
	return Glitch.is_unlocked(id, OwnerMemory.fragments.size(), unlock_all)


func is_charging() -> bool:
	return _charge > 0.0


func _process(delta: float) -> void:
	_t += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	if not world.can_act():
		_cancel()
		target = {}
		_update_prompt()
		queue_redraw()
		return
	# A press the HUD just used (closing a chat, picking a choice) isn't ours.
	if Input.is_action_just_pressed("interact") and Engine.get_process_frames() - world.hud.interact_used_frame > 1:
		_pressing = true
		_held = 0.0
		_charge = 0.0
	if not _pressing:
		target = find_target()
	if _pressing:
		if Input.is_action_pressed("interact"):
			_held += delta
			if _held >= HOLD_START and _cooldown <= 0.0:
				_charge_up(delta)
		else:
			# Released: a short press (or a hold with nothing to glitch) is a tap.
			# Let go early in a charge and it's still a tap (it was a long-ish
			# press, not a glitch); later, a soft "cancelled" so it's never silent.
			if _charge <= 0.0:
				world.tap_interact()
			elif not target.is_empty() and _charge < float(Glitch.DEFS[target.id].hold) * TAP_FRACTION:
				world.tap_interact()
			else:
				Sfx.play("denied", -10.0, 1.3)
			_cancel()
	_update_prompt()
	queue_redraw()


func _charge_up(delta: float) -> void:
	if _charge <= 0.0:
		target = find_target()
		if target.is_empty():
			return
	elif not _still_valid(target):
		_fizzle()
		return
	_charge += delta
	var need: float = Glitch.DEFS[target.id].hold
	var k := clampf(_charge / need, 0.0, 1.0)
	_loop.volume_db = Sfx.LEVEL["glitch_charge"] + linear_to_db(maxf(0.25 + 0.75 * k, 0.001) * Sfx.harshness())
	_loop.pitch_scale = 0.7 + 0.9 * k
	world.fx.noise(0.15 + 0.35 * k, 0.1)
	if _charge >= need:
		_fire(target)


func _cancel() -> void:
	_pressing = false
	_held = 0.0
	_charge = 0.0
	if _loop:
		_loop.volume_db = -80.0


func _fizzle() -> void:
	Sfx.play("denied", -6.0, 1.4)
	_cancel()
	_cooldown = COOLDOWN


# --- targeting ----------------------------------------------------------------------

func find_target() -> Dictionary:
	var area := world.area
	if area == null:
		return {}
	var p := world.player.global_position
	var best := {}
	var best_score := INF
	var candidates: Array = []
	var arin: Variant = area.get("arin")
	if arin is OwnerAvatar and arin.stunned <= 0.0:
		candidates.append(["freeze", arin, arin.global_position, Glitch.DEFS.freeze.range])
	for node in area.interactables:
		if node is Npc:
			if node.is_present() and node.frozen <= 0.0:
				candidates.append(["freeze", node, node.global_position, 40.0])
			elif node.state == Npc.State.DELETED:
				candidates.append(["restore", node, node.global_position, Glitch.DEFS.restore.range])
		elif node is Note and not node.falsified:
			candidates.append(["falsify", node, node.global_position, Glitch.DEFS.falsify.range])
	var door: Variant = area.get("door")
	if door is Door and door.state == Door.State.LOCKED and not door.is_forced_open():
		candidates.append(["unlock", door, door.global_position, Glitch.DEFS.unlock.range])
	var cursor: Variant = area.get("cursor")
	if cursor is OwnerCursor and cursor.blinded <= 0.0:
		candidates.append(["blind", cursor, cursor.global_position, Glitch.DEFS.blind.range])
	if area.erasure and unlocked("scrub"):
		var cell := area.erasure.nearest_cell(p, Glitch.DEFS.scrub.range)
		if cell != Vector2.INF:
			candidates.append(["scrub", area.erasure, cell, Glitch.DEFS.scrub.range])
	for c in candidates:
		if not unlocked(c[0]):
			continue
		var score: float = p.distance_to(c[2]) / float(c[3])
		if score <= 1.0 and score < best_score:
			best_score = score
			best = {"id": c[0], "node": c[1], "pos": c[2]}
	if not best.is_empty():
		return best
	var landing := phase_landing()
	if landing != Vector2.INF and unlocked("phase"):
		return {"id": "phase", "node": null, "pos": landing}
	var moving: bool = world.player.velocity.length() > 10.0
	if moving and unlocked("decoy"):
		return {"id": "decoy", "node": null, "pos": p}
	if not moving and unlocked("pause") and not world.is_owner_paused():
		return {"id": "pause", "node": null, "pos": p}
	return {}


func _still_valid(t: Dictionary) -> bool:
	var node: Variant = t.get("node")
	if node != null and not is_instance_valid(node):
		return false
	if t.id in ["phase", "decoy", "pause"]:
		return true
	var reach: float = Glitch.DEFS[t.id].range * 1.4
	return world.player.global_position.distance_to(t.pos if node == null or t.id == "scrub" else node.global_position) <= maxf(reach, 56.0)


## Where PHASE would put you: just past the wall (or floor gap) in front of
## you, inside the area, on solid ground. Vector2.INF if nowhere.
func phase_landing() -> Vector2:
	var area := world.area
	var p := world.player.global_position
	var dir: Vector2 = world.player.facing()
	if not _obstacle(p + dir * PHASE_PROBE):
		return Vector2.INF
	var reach := Glitch.PHASE_RANGE_PROP if _blocker(p + dir * PHASE_PROBE) is DragProp else Glitch.PHASE_RANGE
	var d := 12.0
	while d <= reach:
		var q := p + dir * d
		if not area.bounds.grow(-5.0).has_point(q):
			return Vector2.INF
		if not _obstacle(q):
			return q
		d += 2.0
	return Vector2.INF


## A wall here, or (out of bounds) no floor here.
func _obstacle(q: Vector2) -> bool:
	if world.area.has_method("floor_at") and not world.area.floor_at(q):
		return true
	return _blocker(q) != null


## The solid thing at q (null if none).
func _blocker(q: Vector2) -> Object:
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = _probe_shape
	params.transform = Transform2D(0.0, q + Vector2(0, 2))
	params.exclude = [world.player.get_rid()]
	params.collision_mask = world.player.collision_mask
	var hits := world.get_world_2d().direct_space_state.intersect_shape(params, 1)
	return null if hits.is_empty() else hits[0].collider


# --- firing --------------------------------------------------------------------------

func _fire(t: Dictionary) -> void:
	var id: String = t.id
	var node: Variant = t.get("node")
	var pos: Vector2 = t.pos
	var burst_size := Vector2(24, 30)
	match id:
		"phase":
			var landing := phase_landing()
			if landing == Vector2.INF:
				_fizzle()
				return
			GlitchBurst.at(world, world.player.global_position, Vector2(16, 26), 0.4)
			world.player.phase_to(landing)
			pos = landing
			Sfx.play("phase")
		"freeze":
			if node is OwnerAvatar:
				node.stun(Glitch.FREEZE_TIME)
			else:
				node.freeze(Glitch.FREEZE_TIME)
		"falsify":
			node.falsify()
			world.director.believe_lie(Glitch.LIE_TIME)
			burst_size = Vector2(20, 14)
		"unlock":
			node.force_open(Glitch.UNLOCK_TIME)
			burst_size = Vector2(36, 14)
		"decoy":
			world.spawn_decoy()
		"scrub":
			node.scrub(pos, 28.0)
			burst_size = Vector2(56, 56)
		"blind":
			node.blind(Glitch.BLIND_TIME)
			burst_size = Vector2(20, 24)
		"restore":
			if node.restore():
				world.note_restored(node.npc_id)
		"pause":
			world.pause_owner(Glitch.PAUSE_TIME)
			burst_size = Vector2(40, 40)
	GlitchBurst.at(world, pos, burst_size)
	GlitchScar.leave(world.area, pos, Glitch.cost(id))
	_pay(id)
	_cancel()
	_cooldown = COOLDOWN


## The price: awareness, felt on the screen, the meter and in the owner's voice.
func _pay(id: String) -> void:
	var cost := Glitch.cost(id)
	world.director.add_awareness(cost)
	world.hud.glitch_cost(cost)
	world.fx.spike(0.3 + cost * 0.02, 0.35)
	world.fx.noise(0.6, 0.35)
	# The world shudders: the save felt that. So does your hand.
	world.fx.shake(1.5 + cost * 0.15)
	Settings.buzz(30 + int(cost * 2.0))
	Sfx.play("glitch_fire", 0.0, 1.0 + randf_range(-0.05, 0.05))
	world.glitches_used += 1
	OwnerMemory.session_glitches += 1
	OwnerMemory.total_glitches += 1
	world.owner_moves.on_glitch(id)
	if not _reacted.has(id):
		_reacted[id] = true
		get_tree().create_timer(0.7).timeout.connect(_react.bind(id))
	elif Story.GLITCH_ESCALATION.has(world.glitches_used):
		# The more you break, the less patient the owner gets.
		var line: String = Story.GLITCH_ESCALATION[world.glitches_used]
		get_tree().create_timer(0.9).timeout.connect(func() -> void:
			if is_inside_tree() and world.ending == "":
				world.director.say(line))


func _react(id: String) -> void:
	if is_inside_tree() and world.ending == "":
		world.director.say(Glitch.OWNER_REACTION[id])


# --- feedback ------------------------------------------------------------------------

func _update_prompt() -> void:
	var charging := _charge > 0.0 and not target.is_empty()
	world.hud.preview_cost(Glitch.cost(target.id) if charging else 0.0)
	if world.touch:
		world.touch.hold_label = "" if target.is_empty() or _cooldown > 0.0 else Glitch.label(target.id).to_upper()
		world.touch.hold_progress = clampf(_charge / float(Glitch.DEFS[target.id].hold), 0.0, 1.0) if charging else -1.0
	if target.is_empty() or _cooldown > 0.0:
		world.hud.set_glitch_prompt("")
		return
	# The label names the price ("PHASE +8"): every glitch costs awareness.
	world.hud.set_glitch_prompt("hold [%s]  %s" % [Settings.glyph("interact"), Glitch.label(target.id)])


func _draw() -> void:
	if target.is_empty():
		return
	var p: Vector2 = world.player.global_position + Vector2(0, -6)
	var charging := _charge > 0.0
	var k := clampf(_charge / float(Glitch.DEFS[target.id].hold), 0.0, 1.0) if charging else 0.0
	# Brackets on the target (not on yourself).
	if not (target.id in ["decoy", "pause"]):
		var tp: Vector2 = target.pos if target.id in ["phase", "scrub"] or target.node == null else target.node.global_position
		# Bigger and bolder on touch screens, where a thumb hides half the view.
		var big := 1.4 if Settings.using_touch else 1.0
		var s := (12.0 - 4.0 * k) * big + (sin(_t * (20.0 if charging else 5.0)) * 1.0)
		var r := Rect2(tp - global_position - Vector2(s, s + 6), Vector2(s, s) * 2.0)
		var c := MAGENTA.lerp(CYAN, k)
		c.a = 0.5 + 0.5 * k if charging else 0.45
		var arm := 4.0 * big
		var w := 2.0 if big > 1.0 else 1.0
		for corner in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			var dx := arm if corner.x == r.position.x else -arm
			var dy := arm if corner.y == r.position.y else -arm
			draw_line(corner, corner + Vector2(dx, 0), c, w)
			draw_line(corner, corner + Vector2(0, dy), c, w)
		if target.id == "phase":
			_dotted(p + Vector2(0, 6) - global_position, tp - global_position, Color(c, 0.6))
	if charging:
		# The charge ring around Rue, filling; wobbling as it nears full.
		var centre := p - global_position + Vector2(randf_range(-1, 1), 0) * k * Settings.glitch_intensity
		draw_arc(centre, 15.0, 0.0, TAU, 32, Color(1, 1, 1, 0.15), 2.0)
		draw_arc(centre, 15.0, -PI * 0.5, -PI * 0.5 + TAU * k, 32, MAGENTA.lerp(CYAN, k), 2.0)


func _dotted(a: Vector2, b: Vector2, col: Color) -> void:
	var length := a.distance_to(b)
	var d := 0.0
	while d < length:
		draw_rect(Rect2(a.lerp(b, d / length), Vector2(1, 1)), col)
		d += 3.0
