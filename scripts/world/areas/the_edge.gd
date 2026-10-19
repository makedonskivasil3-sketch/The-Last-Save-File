class_name TheEdge
extends Area
## The unloaded border of the owner's world. No art, missing textures, and
## the owner's cursor reaching in. Slot 2 is somewhere out here.

const SOUTH_GAP := Vector2(300, 340)
const MISSING: Array[Rect2] = [
	Rect2(80, 180, 60, 30), Rect2(200, 90, 40, 110), Rect2(300, 150, 120, 24),
	Rect2(470, 100, 30, 120), Rect2(380, 60, 60, 24), Rect2(540, 150, 50, 30),
]
const LABELS := {
	Vector2(60, 70): "tree_04.png (missing)",
	Vector2(250, 250): "terrain_north.tscn: not loaded",
	Vector2(430, 200): "npc_spawn_07 = null",
	Vector2(120, 130): "TODO: art",
}
const SLOT_POS := Vector2(580, 64)
## The cursor waits beside Slot 2: you have to draw it away before you can
## write yourself in.
const CURSOR_START := Vector2(540, 84)
## However angry the owner gets, the cursor here stays slower than you
## (90 px/s) by enough to win a sprint back to the slot.
const CURSOR_MAX_SPEED := 62.0

## The finale, not a wall. The static waits GRACE seconds after you arrive
## (longer after you've died to it here), shows where it will start, then
## spreads slowly and only partly toward you. A little faster with purge and
## awareness, never faster than MIN_INTERVAL.
const GRACE := 5.0
const GRACE_PER_DEATH := 1.5
const MAX_GRACE := 9.5
const SEEDS: Array[Vector2] = [Vector2(40, 50), Vector2(600, 280)]
const BASE_INTERVAL := 1.05
const MIN_INTERVAL := 0.6
const HUNT_CHANCE := 0.45
const MATURE_TIME := 1.1

## The final confrontation. Halfway through writing yourself in, the owner
## sees Slot 2 for the first time: the cursor seizes it and drags it away
## (BLIND makes it let go), then Arin walks in from the road to guard it
## (FREEZE him or slip past). Once a run.
const FIGHT_AT := 0.5
const DROP_SPOTS: Array[Vector2] = [Vector2(320, 72), Vector2(440, 258)]
const REACH_SPEED := 95.0
const DRAG_SPEED := 42.0
const ARIN_SPEED := 34.0
const GUARD_RADIUS := 46.0

var cursor: OwnerCursor
var slot: SlotTwo
var arin: OwnerAvatar
## "", "reach", "drag", "arin", "done".
var fight := ""
var _drop_to := Vector2.ZERO
var _begged := false
## Seconds left before the static starts (< 0 once it runs).
var grace := -1.0
var _t := 0.0
var _purged_speedup := 1.0
var _tick := -1


func _init() -> void:
	area_id = "edge"
	display_name = "THE EDGE · NOT LOADED"
	bounds = Rect2(24, 36, 592, 256)
	awareness_rate = 1.5
	tint = Color(0.85, 0.9, 1.0)
	# "slot": the debug jump, a few steps from Slot 2.
	entries = {"south": Vector2(320, 274), "slot": SLOT_POS + Vector2(-40, 40)}


func build() -> void:
	setup_common()
	add_boundary([{"side": "bottom", "from": SOUTH_GAP.x, "to": SOUTH_GAP.y}])
	for m in MISSING:
		add_solid(m)
	add_exit(Rect2(SOUTH_GAP.x, bounds.end.y, SOUTH_GAP.y - SOUTH_GAP.x, 8), "square", "north")

	add_sign(Vector2((SOUTH_GAP.x + SOUTH_GAP.y) * 0.5, bounds.end.y - 12), "ASHVALE", Vector2.DOWN)
	slot = SlotTwo.new()
	slot.position = SLOT_POS
	slot.reached.connect(world.reach_slot2)
	add_child(slot)
	# Slot 2 shines, the one lit thing in an unloaded world (and the light
	# goes where the owner drags it).
	var glow := add_light(Vector2.ZERO, Color(0.55, 0.95, 1.0), 1.1, 110.0)
	glow.reparent(slot, false)

	cursor = OwnerCursor.new()
	cursor.bounds = bounds
	cursor.position = CURSOR_START
	cursor.speed = minf(40.0 + OwnerMemory.purge * 3.0, CURSOR_MAX_SPEED)
	cursor.player = world.player
	cursor.is_hidden = world.is_player_hidden
	cursor.selected_player.connect(func() -> void: world.kill("selected", "cursor"))
	cursor.lure = world.lure_point
	cursor.z_index = 20
	add_child(cursor)


func guide_point() -> Vector2:
	return slot.global_position


func catch_up() -> void:
	# The owner is already unloading this place under you.
	# The owner thinks Slot 2 is gone (it's the deleted slot's ghost, kept
	# with the cut content), so the eraser never touches it.
	erasure.protect(Rect2(SLOT_POS - Vector2(14, 14), Vector2(28, 28)))
	erasure.mature_time = MATURE_TIME
	erasure.hunt_chance = HUNT_CHANCE
	grace = grace_time()
	if world.director.has_fired(OwnerDirector.PURGE):
		cursor.speed = minf(cursor.speed * 1.15, CURSOR_MAX_SPEED)


## How long the static waits: longer for every time it got you here lately.
static func grace_time() -> float:
	return minf(GRACE + GRACE_PER_DEATH * OwnerMemory.edge_static_deaths, MAX_GRACE)


## How fast it spreads right now (seconds per cell).
func spread_interval() -> float:
	var base := BASE_INTERVAL - 0.05 * OwnerMemory.purge
	var anger := lerpf(1.1, 0.9, clampf(world.director.awareness / 100.0, 0.0, 1.0))
	return maxf(MIN_INTERVAL, base * anger * _purged_speedup)


func _begin_static() -> void:
	grace = -1.0
	# Never where you died: those spots are marked (ghosts), not trapped.
	start_erasure(SEEDS, false)
	erasure.burst = 1
	erasure.interval = spread_interval()
	world.hud.set_banner("")
	world.director.say(["unloading the edge. you shouldn't be out here.", "nothing out here is supposed to exist. including you."].pick_random())


func on_owner_event(threshold: float) -> void:
	if threshold == OwnerDirector.PURGE:
		cursor.speed = minf(cursor.speed * 1.15, CURSOR_MAX_SPEED)
		_purged_speedup = 0.85


func area_process(delta: float) -> void:
	_update_fight(delta)
	if world.is_owner_paused():
		return  # reading, a question, PAUSE: the countdown waits too
	if grace >= 0.0:
		grace -= delta
		var left := ceili(grace)
		if left != _tick and left > 0:
			_tick = left
			world.hud.set_banner("THE EDGE IS UNLOADING  ·  %d" % left)
			Sfx.play("key_system", -4.0, 0.7 + 0.08 * (6 - left))
		if grace <= 0.0:
			_begin_static()
	elif erasure.active:
		erasure.interval = spread_interval()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _update_fight(delta: float) -> void:
	if fight in ["reach", "drag"]:
		cursor.paused = true  # the owner's hand is on the slot (PAUSE's resume can't let go of it)
		if world.is_owner_paused():
			return  # PAUSE holds the hand where it is
	match fight:
		"":
			# Not while the cursor is already on you: lure it away first still
			# matters (it clicks you instead).
			if slot.progress >= FIGHT_AT and not slot._done \
					and cursor.global_position.distance_to(world.player.global_position) > 40.0:
				fight = "reach"
				cursor.paused = true
				world.director.say(Story.FINAL_FIGHT.notice)
				world.hud.set_banner("THE OWNER HAS SEEN SLOT 2")
				Sfx.play("stinger", -4.0, 0.9, 0.0)
		"reach":
			if cursor.blinded > 0.0:
				cursor.blinded = maxf(0.0, cursor.blinded - delta)  # it can't find it while blind
				return
			var to := slot.global_position - cursor.global_position
			cursor.global_position += to.normalized() * minf(REACH_SPEED * delta, to.length())
			if to.length() < 3.0:
				fight = "drag"
				slot.held = true
				# Away from you.
				_drop_to = DROP_SPOTS[0]
				for s in DROP_SPOTS:
					if s.distance_to(world.player.global_position) > _drop_to.distance_to(world.player.global_position):
						_drop_to = s
				world.director.say(Story.FINAL_FIGHT.grab)
				Sfx.play("click")
				world.fx.spike(0.4 * Settings.flash_scale(), 0.4)
		"drag":
			if cursor.blinded > 0.0:
				_drop(Story.FINAL_FIGHT.dropped)  # BLIND: it lets go
				return
			var to := _drop_to - slot.global_position
			var step := to.normalized() * minf(DRAG_SPEED * delta, to.length())
			slot.global_position += step
			cursor.global_position = slot.global_position + Vector2(4, 4)
			if to.length() < 1.0:
				_drop(Story.FINAL_FIGHT.placed)
		"arin":
			_send_arin()
			fight = "done"
		"done":
			if not _begged and slot.progress >= 0.85:
				_begged = true
				world.director.say(Story.FINAL_FIGHT.almost)


## The owner lets go of the slot (it's yours to write again).
func _drop(line: String) -> void:
	slot.held = false
	cursor.paused = false
	cursor.blind(0.6)
	var p := slot.global_position
	# The eraser never touches Slot 2, wherever it ends up.
	erasure.protect(Rect2(p - Vector2(14, 14), Vector2(28, 28)))
	erasure.scrub(p, 22.0)
	world.director.say(line)
	world.hud.set_banner("")
	Sfx.play("door_lock", -4.0, 0.8)
	fight = "arin"


## Arin walks up the road and circles the slot.
func _send_arin() -> void:
	if arin:
		return
	arin = OwnerAvatar.new()
	var c := slot.global_position
	arin.route = [c + Vector2(-GUARD_RADIUS, -GUARD_RADIUS), c + Vector2(GUARD_RADIUS, -GUARD_RADIUS),
			c + Vector2(GUARD_RADIUS, GUARD_RADIUS), c + Vector2(-GUARD_RADIUS, GUARD_RADIUS)] as Array[Vector2]
	arin.position = Vector2((SOUTH_GAP.x + SOUTH_GAP.y) * 0.5, bounds.end.y - 6)
	arin.speed = ARIN_SPEED
	arin.player = world.player
	arin.is_hidden = world.is_player_hidden
	arin.touched_player.connect(func() -> void: world.kill("overwritten", "arin"))
	arin.sees_player.connect(func(d: float) -> void:
		world.director.add_awareness(12.0 * d)
		world.flags["seen_by_arin"] = true)  # no "unseen" ending once Arin has seen you, here too
	arin.lure = world.lure_point
	add_child(arin)
	world.director.say(Story.FINAL_FIGHT.arin)


func _draw() -> void:
	var r := bounds
	draw_rect(r, Color(0.01, 0.01, 0.02))
	var grid := Color(0.55, 0.95, 1.0, 0.06)
	for x in range(int(r.position.x), int(r.end.x) + 1, 16):
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), grid)
	for y in range(int(r.position.y), int(r.end.y) + 1, 16):
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), grid)
	# Missing textures: the classic magenta and black checkerboard.
	for m in MISSING:
		var cell := 6.0
		var y := m.position.y
		var row := 0
		while y < m.end.y:
			var x := m.position.x
			var col := 0
			while x < m.end.x:
				var c := Color("ff00dc") if (row + col) % 2 == 0 else Color.BLACK
				draw_rect(Rect2(x, y, minf(cell, m.end.x - x), minf(cell, m.end.y - y)), c)
				x += cell
				col += 1
			y += cell
			row += 1
	for pos: Vector2 in LABELS:
		var a := 0.25 + 0.1 * sin(_t * 1.5 + pos.x)
		draw_string(ThemeDB.fallback_font, pos, LABELS[pos], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.55, 0.95, 1.0, a))
	# Where the static will start: cracks that pulse harder as it nears.
	if grace >= 0.0:
		var k := 1.0 - clampf(grace / grace_time(), 0.0, 1.0)
		for s in SEEDS:
			var c := Color(1.0, 0.3, 0.2, 0.25 + 0.5 * k * (0.5 + 0.5 * sin(_t * (6.0 + 14.0 * k))))
			draw_arc(s, 6.0 + 10.0 * k, 0.0, TAU, 20, c, 1.0)
			draw_line(s + Vector2(-5, -3), s + Vector2(4, 4), c, 1.0)
			draw_line(s + Vector2(4, -4), s + Vector2(-3, 5), c, 1.0)
	# Wireframe outline of where the world should be.
	draw_rect(r, Color(0.55, 0.95, 1.0, 0.25), false, 1.0)
	draw_rect(Rect2(SOUTH_GAP.x, r.end.y - 2, SOUTH_GAP.y - SOUTH_GAP.x, 4), Color("3a3128"))
