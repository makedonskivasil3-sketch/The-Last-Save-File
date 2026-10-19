class_name OutOfBounds
extends Area
## Under the well: the underside of the map, where Rue fell once, years ago.
## The owner's camera has no data here, so awareness cools and nothing hunts
## you. The danger is the floor: there isn't one. Only a few debug platforms
## (anchors) are always there; between them, chunks of floor stream in and
## out on a timer. A chunk flickers before it goes. Step into the void and
## you fall back to where you came in (not a death: nobody saw).
##
## Pip waits on the far ledge, curled up next to the memory of the well.

## Always solid.
const ANCHORS: Array[Rect2] = [
	Rect2(64, 48, 76, 60),     # where you land, with the respawn point
	Rect2(232, 52, 44, 44),
	Rect2(232, 200, 52, 48),
	Rect2(408, 200, 52, 48),
	Rect2(484, 64, 92, 76),    # Pip's ledge
]
## Floor chunks that stream in and out: [rects, phase offset (s)]. A chunk
## made of several rects appears and vanishes as one.
const CHUNKS := [
	[[Rect2(140, 64, 92, 26)], 0.0],
	[[Rect2(242, 96, 26, 104)], 0.8],
	[[Rect2(284, 212, 124, 26)], 1.6],
	[[Rect2(420, 120, 26, 80), Rect2(446, 108, 38, 26)], 2.4],
]
## Every chunk: here for ON seconds of each PERIOD, flickering for the last
## WARN of them.
const PERIOD := 3.2
const ON := 2.2
const WARN := 0.6
## Off the floor this long and you fall.
const FALL_GRACE := 0.12
const ENTRY := Vector2(110, 84)
const PIP_POS := Vector2(512, 100)
const PILLAR_POS := Vector2(84, 66)
const FIRST_SHAPE_POS := Vector2(500, 124)

const VOID := Color(0.01, 0.015, 0.04)
const WIRE := Color(0.55, 0.95, 1.0)
const LABELS := {
	Vector2(300, 300): "kill_plane  y = -999",
	Vector2(150, 160): "chunk_07: streaming...",
	Vector2(330, 150): "TODO: nobody should ever see this",
	Vector2(470, 282): "collision_debug = true",
}

var pip: Companion
var pillar: Passage

var _t := 0.0
var _off_floor := 0.0
var _falling := false


func _init() -> void:
	area_id = "oob"
	display_name = "OUT OF BOUNDS · BELOW ASHVALE"
	bounds = Rect2(56, 40, 528, 252)
	# The owner can't see down here at all.
	awareness_rate = -0.8
	tint = Color(0.85, 0.9, 1.05)
	entries = {"well": ENTRY}


func build() -> void:
	setup_common()
	add_boundary()

	pillar = Passage.new()
	pillar.look = Passage.Look.PILLAR
	pillar.prompt = "climb up"
	pillar.target_area = "square"
	pillar.arrival = "well"
	pillar.position = PILLAR_POS
	add_sign(Vector2(102, 118), "UP TO ASHVALE", Vector2.UP)
	pillar.taken.connect(func(p: Passage) -> void: world.change_area(p.target_area, p.arrival))
	add_child(pillar)
	interactables.append(pillar)

	# Once Pip is yours and every memory is back: the shape slot 2 was made
	# with, outlined on Pip's ledge (docs/DARK_TRUTH_DESIGN.md).
	if OwnerMemory.found_pip and OwnerMemory.fragments.size() >= Story.FRAGMENTS.size():
		add_readable(Story.FIRST_SHAPE_TITLE, FIRST_SHAPE_POS, Readable.Look.TERMINAL, _first_shape)

	if not OwnerMemory.found_pip:
		pip = Companion.new()
		pip.world = world
		pip.position = PIP_POS
		pip.z_index = 9
		add_child(pip)
		interactables.append(pip)


func catch_up() -> void:
	pass  # the eraser can't reach out of bounds either


func _first_shape() -> Array:
	return Story.FIRST_SHAPE.duplicate()  # counted on its last line (World._on_line_shown)


## Where Pip (once found) would lead you: the ledge, then back to the pillar.
func guide_point() -> Vector2:
	return PILLAR_POS


func area_process(delta: float) -> void:
	_t += delta
	if _falling or world.is_talking():
		return
	if floor_at(world.player.global_position):
		_off_floor = 0.0
		return
	_off_floor += delta
	if _off_floor >= FALL_GRACE:
		_fall()


## Is there floor under this point right now? (PHASE uses it too.)
func floor_at(p: Vector2) -> bool:
	for r in ANCHORS:
		if r.grow(3.0).has_point(p):
			return true
	for c in CHUNKS:
		if chunk_present(c[1], _t):
			for r: Rect2 in c[0]:
				if r.grow(3.0).has_point(p):
					return true
	return false


## Whether a chunk with this phase offset is there at time t.
static func chunk_present(offset: float, t: float) -> bool:
	return fmod(t + offset, PERIOD) < ON


## 0 = steady, 1 = about to vanish (for the flicker).
static func chunk_warning(offset: float, t: float) -> float:
	var phase := fmod(t + offset, PERIOD)
	if phase >= ON or phase < ON - WARN:
		return 0.0
	return (phase - (ON - WARN)) / WARN


## You stepped into the void: down, and back to where you came in.
func _fall() -> void:
	_falling = true
	world.player.frozen = true
	Sfx.play("unload", -6.0, 1.3)
	world.fx.spike(0.4, 0.5)
	world.voice("oob_fell")
	await world.hud.fade(true, 0.2).finished
	if not is_inside_tree():
		return
	world.player.global_position = ENTRY
	world.player.velocity = Vector2.ZERO
	if world.pip:
		world.pip.arrive(ENTRY)
	await world.hud.fade(false, 0.3).finished
	if not is_inside_tree():
		return
	world.player.frozen = false
	_off_floor = 0.0
	_falling = false


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var r := bounds
	draw_rect(r.grow(8), VOID)
	_draw_upside_down_square()
	# A faint debug grid over everything.
	var grid := Color(WIRE, 0.035)
	for x in range(int(r.position.x), int(r.end.x) + 1, 16):
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), grid)
	for y in range(int(r.position.y), int(r.end.y) + 1, 16):
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), grid)
	# Dust of data falling upward.
	for i in 24:
		var h := fmod(sin(float(i) * 12.9898) * 43758.5453, 1.0)
		var x := r.position.x + absf(h) * r.size.x
		var y := r.end.y - fmod(_t * (8.0 + i % 5 * 4.0) + i * 37.0, r.size.y)
		draw_rect(Rect2(x, y, 1, 1), Color(WIRE, 0.25))
	for pos: Vector2 in LABELS:
		draw_string(ThemeDB.fallback_font, pos, LABELS[pos], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(WIRE, 0.22 + 0.06 * sin(_t * 1.3 + pos.x)))
	# Chunks: tiles when present (flickering before they go), a dotted
	# outline where they will come back.
	for c in CHUNKS:
		var present := chunk_present(c[1], _t)
		var warn := chunk_warning(c[1], _t)
		for rect: Rect2 in c[0]:
			if present:
				var blink := warn > 0.0 and fmod(_t, 0.16) < 0.08 + 0.04 * (1.0 - warn)
				_draw_tiles(rect, Color(1.0, 0.35, 0.45) if blink else WIRE, 0.55 if not blink else 0.3)
			else:
				_draw_dotted(rect, Color(WIRE, 0.18))
	# Anchors: solid debug platforms.
	for a in ANCHORS:
		draw_rect(a, Color(0.05, 0.12, 0.14))
		draw_rect(a, Color(WIRE, 0.7), false, 1.0)
		draw_string(ThemeDB.fallback_font, a.position + Vector2(3, 8), "anchor", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(WIRE, 0.35))
	draw_rect(r, Color(WIRE, 0.25), false, 1.0)


## The square above, seen from underneath: flat grey undersides, mirrored.
func _draw_upside_down_square() -> void:
	var r := bounds
	var c := Color(0.5, 0.55, 0.65, 0.07)
	var flip := func(rect: Rect2) -> Rect2:
		return Rect2(rect.position.x, r.position.y + r.end.y - rect.end.y, rect.size.x, rect.size.y)
	for rect in [VillageSquare.HOUSE, VillageSquare.WELL, VillageSquare.STALL, VillageSquare.CRATES]:
		draw_rect(flip.call(rect), c)
	# Arin's patrol loop, as the engine stores it: a dotted path.
	var route := VillageSquare.ROUTE
	for i in route.size():
		var a := Vector2(route[i].x, r.position.y + r.end.y - route[i].y)
		var b := Vector2(route[(i + 1) % route.size()].x, r.position.y + r.end.y - route[(i + 1) % route.size()].y)
		_dotted_line(a, b, Color(0.9, 0.6, 0.5, 0.12))


func _draw_tiles(rect: Rect2, col: Color, alpha: float) -> void:
	draw_rect(rect, Color(col, alpha * 0.25))
	var x := rect.position.x
	while x < rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(col, alpha * 0.5))
		x += 8.0
	var y := rect.position.y
	while y < rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(col, alpha * 0.5))
		y += 8.0
	draw_rect(rect, Color(col, alpha), false, 1.0)


func _draw_dotted(rect: Rect2, col: Color) -> void:
	var pts := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y), rect.position]
	for i in 4:
		_dotted_line(pts[i], pts[i + 1], col)


func _dotted_line(a: Vector2, b: Vector2, col: Color) -> void:
	var length := a.distance_to(b)
	var d := 0.0
	while d < length:
		var p := a.lerp(b, d / length)
		draw_rect(Rect2(p, Vector2(1, 1)), col)
		d += 4.0
