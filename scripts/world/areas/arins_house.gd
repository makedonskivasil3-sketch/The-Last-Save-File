class_name ArinsHouse
extends Area
## Arin's house, behind the locked door in the square (UNLOCK opens it).
## The couch faces a TV that's showing this game. Upstairs, through the
## doorway on the right, is Player 2's room: emptied, the outlines of
## furniture still on the floor. The second controller is under the couch.
##
## Every so often Arin comes home: the door chimes, Arin walks a loop
## through the house and leaves. Get into a closet (they hide you).

const FRONT_GAP := Vector2(300, 340)
const COUCH := Rect2(150, 186, 96, 22)
const TV := Rect2(172, 104, 52, 14)
const TABLE := Rect2(176, 146, 44, 16)
## The wall between the living room and Player 2's room, with a doorway.
const WALL_X := 380.0
const DOORWAY := Vector2(196, 236)  # y range of the gap in that wall
## Closets: step inside and Arin can't see you.
const CLOSETS: Array[Rect2] = [Rect2(104, 44, 26, 34), Rect2(508, 248, 26, 34)]
## Where Player 2's furniture used to be (drawn as outlines).
const OUTLINES: Array[Rect2] = [Rect2(420, 60, 70, 34), Rect2(500, 120, 30, 40), Rect2(410, 150, 40, 20)]
const FIRST_VISIT := 8.0
const VISIT_EVERY := 24.0
const VISIT_TIME := 15.0
const ARIN_ROUTE: Array[Vector2] = [
	Vector2(320, 250), Vector2(260, 140), Vector2(330, 90), Vector2(460, 110),
	Vector2(470, 220), Vector2(400, 216), Vector2(320, 260),
]

const FLOOR := Color("2b2420")
const WOOD := Color("4f3a2c")

var arin: OwnerAvatar
## Seconds until Arin comes home (counts down; the chime is a warning).
var next_visit := FIRST_VISIT
var _visit_left := 0.0
var _chimed := false


func _init() -> void:
	area_id = "house"
	display_name = "ARIN'S HOUSE"
	bounds = Rect2(96, 36, 448, 256)
	awareness_rate = 1.1
	tint = Color(1.0, 0.95, 0.9)
	entries = {"front": Vector2(320, 270)}


func build() -> void:
	setup_common()
	add_boundary([{"side": "bottom", "from": FRONT_GAP.x, "to": FRONT_GAP.y}])
	for r in [COUCH, TV, TABLE]:
		add_solid(r)
	# The wall to Player 2's room, with its doorway.
	add_solid(Rect2(WALL_X - 3, bounds.position.y, 6, DOORWAY.x - bounds.position.y))
	add_solid(Rect2(WALL_X - 3, DOORWAY.y, 6, bounds.end.y - DOORWAY.y))
	add_exit(Rect2(FRONT_GAP.x, bounds.end.y, FRONT_GAP.y - FRONT_GAP.x, 8), "square", "house")
	add_sign(Vector2((FRONT_GAP.x + FRONT_GAP.y) * 0.5, bounds.end.y - 12), "ASHVALE", Vector2.DOWN)

	add_readable("THE TV", Vector2(198, 124), Readable.Look.TERMINAL, _tv)
	add_readable("PHOTO", Vector2(300, 44), Readable.Look.SIGN, _photo)
	var couch := add_readable("THE COUCH", Vector2(198, 214), Readable.Look.SIGN, _couch)
	couch.prompt = "look under"
	add_readable("PLAYER 2", Vector2(WALL_X + 20, DOORWAY.x - 8), Readable.Look.SIGN, _player_two)


func guide_point() -> Vector2:
	if not OwnerMemory.found_controller:
		return Vector2(198, 214)
	return Vector2((FRONT_GAP.x + FRONT_GAP.y) * 0.5, bounds.end.y)


## The closets hide you (World.is_player_hidden asks).
func hides_player(pos: Vector2) -> bool:
	for c in CLOSETS:
		if c.has_point(pos):
			return true
	return false


func area_process(delta: float) -> void:
	if world.is_owner_paused():
		if arin:
			arin.paused = true
		return  # PAUSE: Arin holds still, and nobody comes home
	if arin:
		arin.paused = world.is_talking()
		_visit_left -= delta
		if _visit_left <= 0.0:
			arin.queue_free()
			arin = null
			world.hud.say("arin left.", "self")
		return
	next_visit -= delta
	if next_visit <= 2.5 and not _chimed:
		_chimed = true
		Sfx.play("ui_confirm", 0.0, 0.6)  # the door chime
		world.hud.say("(the door. someone's coming in.)", "self")
	if next_visit <= 0.0:
		_arin_comes_home()


func _arin_comes_home() -> void:
	next_visit = VISIT_EVERY
	_chimed = false
	_visit_left = VISIT_TIME
	arin = OwnerAvatar.new()
	arin.route = ARIN_ROUTE.duplicate()
	arin.position = Vector2(320, bounds.end.y - 4)
	arin.speed = 40.0
	arin.player = world.player
	arin.is_hidden = world.is_player_hidden
	arin.touched_player.connect(func() -> void: world.kill("overwritten", "arin"))
	arin.sees_player.connect(func(d: float) -> void:
		world.director.add_awareness(20.0 * d)
		world.flags["seen_by_arin"] = true)
	arin.lure = world.lure_point
	add_child(arin)
	world.director.say("arin's home.")


func _tv() -> Array:
	world.director.add_awareness(4.0)
	return [
		"the TV is on. it's showing this game.",
		"on the screen: a little house, a little room, a little someone standing in front of a TV.",
		"when you raise your hand, the little someone raises theirs.",
	]


func _photo() -> Array:
	return [
		"a photo, half corrupted: two kids on a couch, two controllers, crisps everywhere.",
		"one face has been pixelated out. carefully. square by square.",
	]


func _couch() -> Array:
	if OwnerMemory.found_controller:
		return ["just dust now. you have what was under there."]
	OwnerMemory.found_controller = true
	OwnerMemory.save_memory()
	world.director.add_awareness(10.0)
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		if is_inside_tree() and world.ending == "":
			world.director.say("...don't touch that."))
	world.hud.say("FOUND: controller_p2", "system")
	return [
		"you reach under the couch. dust. a crisp. a cable, taped where the dog chewed it.",
		"the second controller. PLAYER 2.",
		"(it's warm. it can't be warm. it's data.)",
	]


func _player_two() -> Array:
	return [
		"a door sign in felt-tip: PLAYER 2. KNOCK FIRST.",
		"the room behind it is empty. the wallpaper is brighter where a poster used to be.",
		"someone moved out of this room in a hurry, and nobody moved in.",
	]


func _draw() -> void:
	var r := bounds
	draw_rect(r, FLOOR)
	for y in range(int(r.position.y) + 10, int(r.end.y), 10):
		draw_line(Vector2(r.position.x, y), Vector2(WALL_X, y), Color(0, 0, 0, 0.12))
	# Player 2's room: colder, emptier.
	draw_rect(Rect2(WALL_X, r.position.y, r.end.x - WALL_X, r.size.y), Color("23252b"))
	for o in OUTLINES:
		draw_rect(o, Color(1, 1, 1, 0.12), false, 1.0)
	draw_rect(Rect2(440, 40, 40, 24), Color(1, 1, 1, 0.05))  # where the poster was
	# The living room.
	draw_rect(Rect2(150, 120, 96, 64), Color("3d2a2a"))  # rug
	draw_rect(COUCH, Color("5a4a6a"))
	draw_rect(Rect2(COUCH.position + Vector2(0, -6), Vector2(COUCH.size.x, 6)), Color("4a3a5a"))
	draw_rect(TABLE, WOOD)
	draw_rect(TV, Color("101014"))
	# The TV glows with the game.
	var glow := 0.5 + 0.2 * sin(Time.get_ticks_msec() * 0.003)
	draw_rect(TV.grow(-2), Color(0.55, 0.95, 1.0, 0.25 * glow))
	for c in CLOSETS:
		draw_rect(c, WOOD)
		draw_rect(c.grow(-3), Color("2b1f18"))
		draw_line(Vector2(c.get_center().x, c.position.y + 3), Vector2(c.get_center().x, c.end.y - 3), WOOD, 1.0)
	# The inner wall.
	draw_rect(Rect2(WALL_X - 3, r.position.y, 6, DOORWAY.x - r.position.y), WALL_COL)
	draw_rect(Rect2(WALL_X - 3, DOORWAY.y, 6, r.end.y - DOORWAY.y), WALL_COL)
	draw_walls([{"side": "bottom", "from": FRONT_GAP.x, "to": FRONT_GAP.y}])
