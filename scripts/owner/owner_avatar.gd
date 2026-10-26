class_name OwnerAvatar
extends Node2D
## Arin, driven by the owner. Walks a route through the area and looks where
## it walks. If it sees you, the owner's awareness climbs fast. If it walks
## into you, you're overwritten.

signal sees_player(delta: float)
signal touched_player

const BODY := Color("5a7fb0")
const HAIR := Color("2a2a30")
const SKIN := Color("e8c48a")
const VIEW_COL := Color(0.88, 0.44, 0.31)

var route: Array[Vector2] = []
## A body Rue left in this area last run (docs/DARK_TRUTH_DESIGN.md §2.4):
## Arin stops beside it on every round and stands guard. INF when there's none.
var guard_point := Vector2.INF
## How long Arin stands over the body each round, and how far to one side.
const GUARD_WAIT := 3.0
const GUARD_GAP := 12.0
var speed := 40.0
var view_distance := 85.0
var view_angle := deg_to_rad(70.0)
var player: Node2D
## Callable(Vector2) -> bool: true if the position is hidden from the owner.
var is_hidden: Callable
var paused := false
## Callable() -> Vector2: a decoy to chase instead of patrolling (Vector2.INF
## when there's none). Arin can't see you while chasing it.
var lure: Callable
## Seconds left frozen by Rue's FREEZE glitch: no moving, seeing or touching.
var stunned := 0.0

## Arin's feet: walls, furniture and missing-texture blocks stop a circle this
## size (people don't: Arin walks past them, as before).
const RADIUS := 4.0
## Making less than this share of the expected progress for STUCK_TIME counts
## as blocked: a patrol point is skipped, a decoy is given up.
const STUCK_SHARE := 0.25
const STUCK_TIME := 0.75
## After giving up on a decoy it can't reach, Arin stares at it this long,
## then ignores decoys for LURE_COOLDOWN and goes back to the round.
const INVESTIGATE_TIME := 1.5
const LURE_COOLDOWN := 4.0
## How far a destination inside a solid may be moved to the nearest clear floor.
const FREE_SEARCH := 40.0

var _target := 0
var _vel := Vector2.ZERO
var _stuck := 0.0
var _lure_cooldown := 0.0
var _chasing := false
var _ignore: Array[RID] = []
var _ignore_age := 99.0
## A route point that can't be reached is skipped; after a whole round of
## them, Arin keeps watch where it stands this long before trying again.
const WATCH_TIME := 3.0
## How far Arin may step to get out of a solid it finds itself in.
const RECOVER_RANGE := 16.0
var _nav: NavGrid
var _path := PackedVector2Array()
var _path_goal := Vector2.INF
## The grid version the current path was planned on (NavGrid.version).
var _path_version := -1
## Keeping watch because nothing on the round could be reached: a change in
## the level (a new grid version) ends the watch early.
var _watching_blocked := false
var _watch_version := -1
## How far the current recovery has carried Arin (bounded by RECOVER_RANGE).
var _recovered := 0.0
var _path_short := false
var _skipped := 0
## The protagonist the owner loves: blue tunic, dark hair, a red scarf.
var _sprite := CharacterArt.figure("arin", "adult", {
	"h": HAIR, "s": SKIN, "c": BODY, "d": Color("2e3f5c"), "a": Color("c0392b"),
	"l": Color("2e3f5c"), "f": Color("1a1a20"), "e": Color("101018"),
})
var _facing := Vector2.RIGHT
var _seeing := false
var _wait := 0.0
## Arin's footsteps, positional: you hear which side they're coming from.
var _steps: AudioStreamPlayer2D
var _last_step := 0


func _physics_process(delta: float) -> void:
	_ignore_age += delta
	var before := position
	_physics_step(delta)
	_vel = (position - before) / maxf(delta, 0.0001)


## FREEZE: Arin stops dead, sees nothing, overwrites nothing.
func stun(seconds: float) -> void:
	stunned = maxf(stunned, seconds)
	_seeing = false


func _physics_step(delta: float) -> void:
	if stunned > 0.0:
		stunned -= delta
		return
	if paused:
		return
	_lure_cooldown = maxf(0.0, _lure_cooldown - delta)
	if _recover(delta):
		pass  # stepping back out onto open floor first (detection still runs)
	else:
		var decoy: Vector2 = lure.call() if lure.is_valid() and _lure_cooldown <= 0.0 else Vector2.INF
		_chasing = decoy != Vector2.INF and decoy.distance_to(global_position) < 200.0
		if _chasing:
			# Fooled: walk at the stale frame of you, staring at it, around
			# whatever is in the way.
			var to_decoy := decoy - global_position
			_facing = _facing.lerp(to_decoy.normalized(), minf(1.0, delta * 8.0)).normalized()
			if to_decoy.length() > 6.0 and _go(decoy, speed * 1.2, delta) == Go.BLOCKED:
				# Can't get to it (no way round, or as close as it gets): look a
				# moment where it should be, then give up on it and go back to
				# the round. No walking through walls, no endless pushing.
				_chasing = false
				_lure_cooldown = LURE_COOLDOWN
				_wait = INVESTIGATE_TIME
			_seeing = false
			return
		_patrol(delta)
	_seeing = can_see(player.global_position) if is_instance_valid(player) else false
	if _seeing:
		sees_player.emit(delta)
	if is_instance_valid(player) and player.global_position.distance_to(global_position) < 8.0:
		touched_player.emit()


## True while Arin is walking at a decoy.
func is_chasing() -> bool:
	return _chasing


## The round: walk from point to point (around solids, through doorways),
## pausing at each. A point that can't be reached is skipped; if none of
## them can be, Arin keeps watch where it stands for a while, then tries the
## round again. With no route at all, Arin keeps watch (it still sees and
## still touches).
func _patrol(delta: float) -> void:
	if _wait > 0.0:
		var grid := nav()
		if _watching_blocked and grid and grid.version != _watch_version:
			_wait = 0.0  # the level changed: somewhere may be reachable now
		else:
			_wait -= delta
			return
	_watching_blocked = false
	if route.is_empty():
		return
	_target %= route.size()  # the route may have been changed under us
	var goal := route[_target]
	match _go(goal, speed, delta):
		Go.ARRIVED:
			_target = (_target + 1) % route.size()
			_wait = GUARD_WAIT if goal == guard_point else 0.6  # pauses at corners, looking around
			_skipped = 0
		Go.BLOCKED:
			_target = (_target + 1) % route.size()
			_skipped += 1
			if _skipped >= route.size():
				_skipped = 0
				_wait = WATCH_TIME  # nowhere it can get to: keep watch, then try again
				_watching_blocked = true
				_watch_version = nav().version if nav() else -1


enum Go { MOVING, ARRIVED, BLOCKED }


## One step toward `goal` along a path around solids. ARRIVED when there;
## BLOCKED when it can't be reached (the path ends short of it, or Arin got
## stuck and the area's grid is rebuilt for next time).
func _go(goal: Vector2, spd: float, delta: float) -> Go:
	if global_position.distance_to(goal) < 2.0:
		_path = PackedVector2Array()
		return Go.ARRIVED
	var grid := nav()
	if grid and grid.version != _path_version:
		_path = PackedVector2Array()  # the level changed: plan again
	if _path_goal.distance_to(goal) > 4.0 or _path.is_empty():
		_path_goal = goal
		_path_version = grid.version if grid else -1
		_path = grid.path(global_position, goal) if grid else PackedVector2Array([goal])
		_path_short = _path.is_empty() or _path[_path.size() - 1].distance_to(goal) > 6.0
		if _path.is_empty():
			return Go.BLOCKED
	while not _path.is_empty() and global_position.distance_to(_path[0]) < 1.5:
		_path.remove_at(0)
	if _path.is_empty():
		_path_goal = Vector2.INF
		return Go.BLOCKED if _path_short else Go.ARRIVED
	var next := _path[0]
	_facing = _facing.lerp((next - global_position).normalized(), minf(1.0, delta * 6.0)).normalized()
	if _travel(next, minf(spd * delta, global_position.distance_to(next)), delta):
		_stuck = 0.0
		_path = PackedVector2Array()
		_path_goal = Vector2.INF
		# Collision stopped it where the grid said it could walk: the level
		# changed under the grid. Re-check around here; the new version
		# makes every walker plan again (no oscillating on the old path).
		var a := get_parent()
		if a is Area:
			(a as Area).geometry_changed(Rect2(global_position - Vector2(24, 24), Vector2(48, 48)))
		return Go.BLOCKED
	return Go.MOVING


## Walks up to `dist` toward `goal` without entering a solid, sliding along
## walls (the level's solids are rectangles, so moving each axis separately
## slides cleanly). Returns true once Arin has been blocked for STUCK_TIME.
func _travel(goal: Vector2, dist: float, delta: float) -> bool:
	var motion := (goal - global_position).limit_length(dist)
	var before := global_position
	if is_inside_tree():
		for axis in [Vector2(motion.x, 0.0), Vector2(0.0, motion.y)]:
			if axis.length() > 0.001:
				global_position += axis * _free_fraction(axis)
	var moved := global_position.distance_to(before)
	if moved < dist * STUCK_SHARE:
		_stuck += delta
	else:
		_stuck = 0.0
	return _stuck >= STUCK_TIME


## Inside a solid (a spawn point at a doorway, a wall that moved): step back
## out to the nearest open floor within RECOVER_RANGE, never across an
## obstacle, never by teleporting. With none that close, stay put (and keep
## watching) rather than walk through. True while recovering.
func _recover(delta: float) -> bool:
	var grid := nav()
	if grid == null or grid.clear(global_position, -0.5):
		_recovered = 0.0
		return false
	if _recovered >= RECOVER_RANGE or grid.nearest_open(global_position, RECOVER_RANGE) == Vector2.INF:
		return true  # stuck fast (or gone as far as it may): hold still, safely
	# Out along the way that reduces the overlap, a step at a time: towards the
	# nearest face of what it's in, never through it. Each step must lessen
	# the overlap or it isn't taken.
	var depth := _penetration(global_position)
	var push := _push_out()
	if push == Vector2.ZERO:
		return true
	var step := minf(speed * delta, RECOVER_RANGE - _recovered)
	for k in [1.0, 0.5, 0.25]:
		var next: Vector2 = global_position + push * step * k
		if _penetration(next) < depth - 0.01:
			_recovered += global_position.distance_to(next)
			global_position = next
			return true
	return true  # no step makes it better (an inside corner): hold still


## Deepest overlap of Arin's body with the solids (px; 0 when clear).
func _penetration(at: Vector2) -> float:
	var q := _body_query(at)
	var pts := get_world_2d().direct_space_state.collide_shape(q, 16)
	var deepest := 0.0
	for i in range(0, pts.size() - 1, 2):
		deepest = maxf(deepest, (pts[i] as Vector2).distance_to(pts[i + 1]))
	if deepest == 0.0 and not get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty():
		deepest = RADIUS  # wholly inside: no contact pair, but still in
	return deepest


## The way out of the deepest overlap: the solid's surface normal there.
func _push_out() -> Vector2:
	var info := get_world_2d().direct_space_state.get_rest_info(_body_query(global_position))
	if info.is_empty():
		return Vector2.ZERO
	var n: Vector2 = info.get("normal", Vector2.ZERO)
	return n.normalized()


func _body_query(at: Vector2) -> PhysicsShapeQueryParameters2D:
	var q := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	q.shape = circle
	q.transform = Transform2D(0.0, at)
	q.collision_mask = _mask()
	q.exclude = _ignored()
	return q


## How much of `motion` Arin's feet can take before touching a solid (0..1).
func _free_fraction(motion: Vector2) -> float:
	var q := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	q.shape = circle
	q.transform = Transform2D(0.0, global_position)
	q.motion = motion
	q.collision_mask = _mask()
	q.exclude = _ignored()
	var r := get_world_2d().direct_space_state.cast_motion(q)
	return r[0] if r.size() > 0 else 1.0


func _mask() -> int:
	return player.collision_mask if player is CollisionObject2D else 1


## Rue and the people in the area: Arin doesn't collide with them.
func _ignored() -> Array[RID]:
	if _ignore_age > 0.5:
		_ignore_age = 0.0
		_ignore.clear()
		if player is CollisionObject2D:
			_ignore.append(player.get_rid())
		var a := get_parent()
		if a:
			for n in a.get_children():
				if n is CollisionObject2D and n is Npc:
					_ignore.append((n as CollisionObject2D).get_rid())
	return _ignore


## The area's walkable grid (shared by everything walking in it), built on
## first use from the area's solids at Arin's radius.
func nav() -> NavGrid:
	if _nav != null or not is_inside_tree():
		return _nav
	var a := get_parent()
	if a and a.has_meta("nav_grid"):
		_nav = a.get_meta("nav_grid")
		return _nav
	var b := Rect2(0, 0, 640, 360)
	if a is Area:
		b = (a as Area).bounds
	_ignore_age = 99.0
	_nav = NavGrid.new()
	_nav.build(get_world_2d().direct_space_state, b, _mask(), _ignored(), RADIUS)
	if a:
		a.set_meta("nav_grid", _nav)
	return _nav


## The nearest open floor to `p` with room for Arin's whole body (itself if
## clear), or INF if there's none within FREE_SEARCH.
func free_point(p: Vector2) -> Vector2:
	var grid := nav()
	return grid.nearest_open(p, FREE_SEARCH) if grid else p


## Every destination on open floor with room for Arin: points inside or
## against a solid move to the nearest open spot; points with none nearby
## are dropped. Nothing rejected is kept: if every point goes, the route is
## empty and Arin keeps watch where it stands. A guard point with no open
## floor near it is given up the same way.
func _sanitize_route() -> void:
	if not is_inside_tree():
		return
	if guard_point != Vector2.INF:
		var g := free_point(guard_point)
		for i in route.size():
			if route[i] == guard_point:
				route[i] = g
		guard_point = g
	var clean: Array[Vector2] = []
	for p in route:
		var f := free_point(p)
		if f != Vector2.INF and (clean.is_empty() or clean.back().distance_to(f) > 2.0):
			clean.append(f)
	route = clean
	_target = 0 if route.is_empty() else _target % route.size()
	_path = PackedVector2Array()
	_path_goal = Vector2.INF


func can_see(pos: Vector2) -> bool:
	if stunned > 0.0 or paused:
		return false
	var to := pos - global_position
	if to.length() > view_distance:
		return false
	if absf(_facing.angle_to(to)) > view_angle * 0.5:
		return false
	if _blocked(pos) != pos:
		return false  # a wall, a house, the stall, the crates: Arin can't see through them
	return not (is_hidden.is_valid() and is_hidden.call(pos))


## Where a look from Arin toward `pos` stops: the first solid in the way
## (the same walls and furniture that stop walking), else `pos` itself. The
## view cone is drawn to the same points, so what you see is what Arin sees.
func _blocked(pos: Vector2) -> Vector2:
	if not is_inside_tree():
		return pos
	var q := PhysicsRayQueryParameters2D.create(global_position, pos)
	if player is CollisionObject2D:
		q.collision_mask = player.collision_mask
		q.exclude = [player.get_rid()]
	# People don't block the view (a child beside you isn't a wall): look past them.
	for i in 4:
		var hit := get_world_2d().direct_space_state.intersect_ray(q)
		if hit.is_empty():
			return pos
		if not (hit.collider is Npc):
			return hit.position
		q.exclude = q.exclude + [hit.rid]
	return pos


func _ready() -> void:
	add_to_group("canopy_reveal")  # never hidden under a tree
	_guard_husk()
	_sanitize_route.call_deferred()  # once the area's solids exist
	_steps = AudioStreamPlayer2D.new()
	_steps.bus = "SFX"
	_steps.max_distance = 300.0
	_steps.attenuation = 1.6
	add_child(_steps)


## Seen, said (the owner's note) and answerable: shed somewhere else.
func _guard_husk() -> void:
	var a := get_parent() as Area
	if a == null or route.is_empty() or OwnerMemory.last_run_husk() != a.area_id:
		return
	guard_point = OwnerMemory.husk_pos + Vector2(GUARD_GAP, 0.0)
	_insert_guard()


## Stop at the body after the nearest point of the round.
func _insert_guard() -> void:
	if guard_point == Vector2.INF or route.is_empty() or guard_point in route:
		return
	var best := 0
	for i in route.size():
		if route[i].distance_to(guard_point) < route[best].distance_to(guard_point):
			best = i
	route.insert(best + 1, guard_point)


## A new round, mid-walk (the owner forgot her route: Rue left a body): no
## jump, no stale index. Arin carries on from where it stands toward the
## nearest point of the new round, still stopping at a body it guards.
func set_route(points: Array[Vector2]) -> void:
	route = points.duplicate()
	_insert_guard()
	_sanitize_route()
	if route.is_empty():
		_target = 0
		return
	var best := 0
	for i in route.size():
		if route[i].distance_to(position) < route[best].distance_to(position):
			best = i
	_target = best


func _process(delta: float) -> void:
	_sprite.update(delta, _vel if not paused and stunned <= 0.0 else Vector2.ZERO)
	var step := _sprite.step_frame()
	if step != _last_step and step % 2 == 1:
		_steps.stream = Sfx.stream("step_%d" % (step >> 1))
		_steps.volume_db = -8.0
		_steps.pitch_scale = randf_range(0.75, 0.85)  # heavier than yours
		_steps.play()
	_last_step = step
	if not _sprite.moving:
		_sprite.look_at(Vector2.ZERO, _facing)
	# His view cone is drawn with him: redrawn whenever any of it could be in view.
	if IllustratedCharacter.near_view(self, view_distance + 16.0):
		queue_redraw()


## The cone's colour, brightened by 1/ambient in lit areas: the scene's
## dimming (Area.ambient, via the CanvasModulate) must never hide the main
## stealth tell, so it reads exactly as it did before areas were lit.
func cone_color(alpha: float) -> Color:
	var boost := 1.0
	var n := get_parent()
	while n and not n is Area:
		n = n.get_parent()
	if n is Area and (n as Area).ambient > 0.05:
		boost = 1.0 / (n as Area).ambient
	return Color(VIEW_COL.r * boost, VIEW_COL.g * boost, VIEW_COL.b * boost, alpha)


func _draw() -> void:
	# View cone: faint, brighter when it has you.
	var a := 0.18 if _seeing else 0.06
	var pts := PackedVector2Array([Vector2.ZERO])
	for i in 13:
		var ang := _facing.angle() - view_angle * 0.5 + view_angle * i / 12.0
		var tip := global_position + Vector2.from_angle(ang) * view_distance
		pts.append(_blocked(tip) - global_position)  # stops at walls, like the look itself
	draw_colored_polygon(pts, cone_color(a))
	_sprite.pointing = _seeing  # points at you: still, not a friendly wave
	if stunned > 0.0:
		_draw_frozen()
		return
	_sprite.draw(self)
	if _seeing:
		# A warning triangle, owner-coloured: a different shape from the
		# villagers' friendly white "!" bubbles, not just a different colour.
		var y := float(PixelCharacter.FEET_Y - _sprite.height()) - 13.0 + sin(Time.get_ticks_msec() * 0.015)
		draw_colored_polygon(PackedVector2Array([Vector2(0, y), Vector2(6, y + 10), Vector2(-6, y + 10)]), VIEW_COL)
		draw_polyline(PackedVector2Array([Vector2(0, y - 1), Vector2(7, y + 11), Vector2(-7, y + 11), Vector2(0, y - 1)]), Color(0.1, 0.03, 0.03), 1.0)
		draw_rect(Rect2(-0.5, y + 3, 1, 4), Color(0.1, 0.03, 0.03))
		draw_rect(Rect2(-0.5, y + 8, 1, 1), Color(0.1, 0.03, 0.03))


func is_seeing() -> bool:
	return _seeing


## Frozen mid-step: colour-split copies hang either side, and a pause glyph.
func _draw_frozen() -> void:
	var k := Settings.glitch_intensity
	_sprite.draw(self, {"solid": Color(1.0, 0.15, 0.5, 0.55), "offset": Vector2(-2.0 * k, 0)})
	_sprite.draw(self, {"solid": Color(0.3, 0.95, 1.0, 0.55), "offset": Vector2(2.0 * k, 0)})
	_sprite.draw(self, {"grey": true})
	var top := float(PixelCharacter.FEET_Y - _sprite.height())
	draw_rect(Rect2(-4, top - 10, 3, 7), Color(0.55, 0.95, 1.0))
	draw_rect(Rect2(1, top - 10, 3, 7), Color(0.55, 0.95, 1.0))
