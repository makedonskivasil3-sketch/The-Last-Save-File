class_name OwnerCursor
extends Node2D
## The owner's mouse pointer, reaching into the world. It drifts, then homes
## in when it can see you. Hold still under it too long and you get selected.
## Selected things get deleted.

signal selected_player

const SELECT_TIME := 1.1

var bounds := Rect2()
var player: Node2D
var is_hidden: Callable
var speed := 55.0
## Callable() -> Vector2: a decoy to select instead of you (Vector2.INF if none).
var lure: Callable
## Seconds left blinded by Rue's BLIND glitch: it drifts and selects nothing.
var blinded := 0.0
## Held still (the owner's world is paused).
var paused := false

## DRAG: fetching a prop, then carrying it to _drag_to ("" when not dragging).
var _drag_phase := ""
var _drag_prop: DragProp
var _drag_to := Vector2.ZERO

var _goal := Vector2.ZERO
var _select := 0.0
var _tracking := false
var _trail: Array[Vector2] = []
var _arrive := 1.0  # 1 -> 0 as it materialises
var _fx: ScreenFx
## Rising whine while it hovers over you.
var _whine: AudioStreamPlayer
## The cursor's hum, positional: louder as it closes in.
var _hum: AudioStreamPlayer2D
var _t := 0.0
var _done := false
## Its wandering has its own generator, apart from the cosmetic static
## drawn every frame, so a run can be replayed with `rng.seed`.
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	_goal = _random_point()
	_fx = get_tree().get_first_node_in_group("screen_fx") as ScreenFx
	if _fx:
		_fx.cursor_arrives()
	Sfx.play("cursor_arrive")
	_whine = Sfx.loop_player("select_loop", self)
	_hum = AudioStreamPlayer2D.new()
	_hum.bus = "SFX"
	_hum.stream = Sfx.stream("cursor_hum")
	_hum.max_distance = 360.0
	_hum.attenuation = 1.4
	_hum.volume_db = Sfx.LEVEL["cursor_hum"] + linear_to_db(maxf(Sfx.harshness(), 0.05))
	add_child(_hum)
	_hum.play()


## The owner grabs a prop and drags it to `to` (to block your way).
func drag(prop: DragProp, to: Vector2) -> void:
	_drag_prop = prop
	_drag_to = to
	_drag_phase = "fetch"
	_select = 0.0


func is_dragging() -> bool:
	return _drag_phase != ""


func _drag_step(delta: float) -> void:
	if not is_instance_valid(_drag_prop):
		_drag_phase = ""
		return
	match _drag_phase:
		"fetch":
			var to := _drag_prop.global_position - position
			position += to.normalized() * minf(speed * 1.6 * delta, to.length())
			if to.length() < 3.0:
				_drag_phase = "carry"
				_drag_prop.held = true
				Sfx.play("click")
		"carry":
			var to := _drag_to - _drag_prop.global_position
			var step := to.normalized() * minf(speed * 0.9 * delta, to.length())
			# Never drop it onto Rue: wait while she's in the way.
			var next := Rect2(_drag_prop.global_position + step - _drag_prop.size * 0.5, _drag_prop.size).grow(5.0)
			if is_instance_valid(player) and next.has_point(player.global_position):
				return
			_drag_prop.global_position += step
			position = _drag_prop.global_position
			if to.length() < 1.0:
				_drag_prop.held = false
				_drag_phase = ""
				Sfx.play("door_lock", -6.0, 1.4)


## BLIND: the pointer loses you for a while.
## It's settling on you right now (the click is coming).
func is_selecting() -> bool:
	return _select > 0.0


func blind(seconds: float) -> void:
	blinded = maxf(blinded, seconds)
	_select = 0.0


func _physics_process(delta: float) -> void:
	_t += delta
	if paused:
		# Nothing banked: a click that was building starts again from zero
		# once the hold ends, so closing a card never lands an instant click.
		_select = 0.0
		_whine.volume_db = -80.0
		return
	blinded = maxf(0.0, blinded - delta)
	if _drag_phase != "":
		_drag_step(delta)
		_tracking = false
		_select = 0.0
		_whine.volume_db = -80.0
		return
	var decoy: Vector2 = lure.call() if lure.is_valid() else Vector2.INF
	var visible_target: bool = blinded <= 0.0 and decoy == Vector2.INF and is_instance_valid(player) \
			and not (is_hidden.is_valid() and is_hidden.call(player.global_position))
	if decoy != Vector2.INF and blinded <= 0.0:
		_goal = decoy  # fooled: it goes for the stale frame
	elif visible_target:
		_goal = player.global_position
	elif position.distance_to(_goal) < 6.0:
		_goal = _random_point()
	var to := _goal - position
	var spd := speed if visible_target or decoy != Vector2.INF else speed * 0.6
	position += to.normalized() * minf(spd * delta, to.length())

	_tracking = visible_target
	var over: bool = visible_target and player.global_position.distance_to(position) < 12.0
	_select = clampf(_select + (delta if over else -delta * 2.0), 0.0, SELECT_TIME)
	# Being hovered is felt on the whole screen: static builds as the click comes.
	if _fx and _select > 0.0:
		_fx.noise(0.25 + 0.5 * _select / SELECT_TIME, 0.2)
		_fx.spike(0.2 * _select / SELECT_TIME, 0.2)
	var pressure := _select / SELECT_TIME
	_whine.volume_db = Sfx.LEVEL["select_loop"] + linear_to_db(maxf(pressure * Sfx.harshness(), 0.0001))
	_whine.pitch_scale = 0.8 + pressure * 0.9
	if _select >= SELECT_TIME and not _done:
		_done = true
		_whine.stop()
		Sfx.play("click")
		selected_player.emit()


func _random_point() -> Vector2:
	return Vector2(rng.randf_range(bounds.position.x, bounds.end.x), rng.randf_range(bounds.position.y, bounds.end.y))


func _process(delta: float) -> void:
	_arrive = maxf(0.0, _arrive - delta * 1.5)
	_trail.push_front(position)
	if _trail.size() > 5:
		_trail.pop_back()
	queue_redraw()


func _draw() -> void:
	var glitch := Settings.glitch_intensity
	if blinded > 0.0:
		# Blind: a grey pointer full of static.
		_draw_arrow(Vector2.ZERO, 1.0, Color(0.5, 0.5, 0.55, 0.7), true)
		for i in 6:
			draw_rect(Rect2(randf_range(0, 12), randf_range(0, 20), randf_range(2, 6), 1), Color(1, 1, 1, 0.6))
		return
	# Arriving: a huge pointer shrinking down into the world.
	var scale := 1.0 + _arrive * _arrive * 6.0
	# Tracking: thin scan lines through the pointer, across the whole area.
	if _tracking:
		var a := 0.12 + 0.08 * sin(Time.get_ticks_msec() * 0.02)
		var tl := bounds.position - position
		var br := bounds.end - position
		draw_line(Vector2(tl.x, 0), Vector2(br.x, 0), Color(0.55, 0.8, 1.0, a))
		draw_line(Vector2(0, tl.y), Vector2(0, br.y), Color(0.55, 0.8, 1.0, a))
	# Mark the selected character, not the pointer's offset. A steady ring
	# stays readable even with screen effects and flashing turned off.
	if _select > 0.0 and is_instance_valid(player):
		var center := to_local(player.global_position) + Vector2(0, -5)
		var progress := _select / SELECT_TIME
		var color := Color("e0704f")
		draw_arc(center, 17.0, 0.0, TAU, 40, Color(0, 0, 0, 0.85), 3.0)
		draw_arc(center, 17.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 40, color, 2.0)
		var s := 6.0 + 10.0 * (1.0 - progress)
		var r := Rect2(center - Vector2(s, s), Vector2(s, s) * 2.0)
		draw_rect(r, Color(color, 0.12))
		_draw_ants(r, _t * 12.0)
		draw_string_outline(ThemeDB.fallback_font, center + Vector2(-13, 28), "MOVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color.BLACK)
		draw_string(ThemeDB.fallback_font, center + Vector2(-13, 28), "MOVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
	# Afterimages: the pointer smears behind itself in split colour.
	for i in range(1, _trail.size()):
		var off := _trail[i] - position
		var c := Color(1.0, 0.2, 0.5, 0.25 / i) if i % 2 == 1 else Color(0.4, 0.9, 1.0, 0.25 / i)
		_draw_arrow(off, scale, c, false)
	var split := (1.0 + (2.0 if _tracking else 0.0) + _arrive * 6.0) * glitch
	_draw_arrow(Vector2(-split, 0), scale, Color(1.0, 0.1, 0.4, 0.55), false)
	_draw_arrow(Vector2(split, 0), scale, Color(0.3, 0.9, 1.0, 0.55), false)
	_draw_arrow(Vector2.ZERO, scale, Color.WHITE, true)


func _draw_arrow(offset: Vector2, scale: float, color: Color, outline: bool) -> void:
	# A plain arrow pointer, much bigger than anything in the world.
	var arrow := PackedVector2Array()
	for p in [Vector2(0, 0), Vector2(0, 17), Vector2(4, 13), Vector2(7, 20), Vector2(10, 19), Vector2(7, 12), Vector2(12, 12)]:
		arrow.append(offset + p * scale)
	draw_colored_polygon(arrow, color)
	if outline:
		var closed := arrow.duplicate()
		closed.append(arrow[0])
		draw_polyline(closed, Color.BLACK, 1.0)


func _draw_ants(r: Rect2, phase: float) -> void:
	# Dashed outline whose dashes crawl around the rectangle.
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	for e in 4:
		var a: Vector2 = pts[e]
		var b: Vector2 = pts[e + 1]
		var length := a.distance_to(b)
		var d := fmod(phase, 4.0)
		while d < length:
			var p0 := a.lerp(b, d / length)
			var p1 := a.lerp(b, minf(d + 2.0, length) / length)
			draw_line(p0, p1, Color.WHITE, 1.0)
			d += 4.0
