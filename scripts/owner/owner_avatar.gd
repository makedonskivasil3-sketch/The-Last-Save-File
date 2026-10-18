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

var _target := 0
var _vel := Vector2.ZERO
## The protagonist the owner loves: blue tunic, dark hair, a red scarf.
var _sprite := PixelCharacter.new("adult", {
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
	if route.is_empty() or paused:
		return
	var decoy: Vector2 = lure.call() if lure.is_valid() else Vector2.INF
	if decoy != Vector2.INF and decoy.distance_to(global_position) < 200.0:
		# Fooled: walk at the stale frame of you, staring at it.
		var to_decoy := decoy - global_position
		_facing = _facing.lerp(to_decoy.normalized(), minf(1.0, delta * 8.0)).normalized()
		if to_decoy.length() > 6.0:
			position += to_decoy.normalized() * speed * 1.2 * delta
		_seeing = false
		return
	if _wait > 0.0:
		_wait -= delta
	else:
		_target %= route.size()  # the route may have been changed under us
		var goal := route[_target]
		var to := goal - position
		if to.length() < 2.0:
			_target = (_target + 1) % route.size()
			_wait = 0.6  # pauses at corners, looking around
		else:
			_facing = _facing.lerp(to.normalized(), minf(1.0, delta * 6.0)).normalized()
			position += to.normalized() * minf(speed * delta, to.length())
	_seeing = can_see(player.global_position) if is_instance_valid(player) else false
	if _seeing:
		sees_player.emit(delta)
	if is_instance_valid(player) and player.global_position.distance_to(global_position) < 8.0:
		touched_player.emit()


func can_see(pos: Vector2) -> bool:
	if stunned > 0.0 or paused:
		return false
	var to := pos - global_position
	if to.length() > view_distance:
		return false
	if absf(_facing.angle_to(to)) > view_angle * 0.5:
		return false
	return not (is_hidden.is_valid() and is_hidden.call(pos))


func _ready() -> void:
	_steps = AudioStreamPlayer2D.new()
	_steps.bus = "SFX"
	_steps.max_distance = 300.0
	_steps.attenuation = 1.6
	add_child(_steps)


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
	for i in 9:
		var ang := _facing.angle() - view_angle * 0.5 + view_angle * i / 8.0
		pts.append(Vector2.from_angle(ang) * view_distance)
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
