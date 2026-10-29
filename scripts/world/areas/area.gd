class_name Area
extends Node2D
## One screen of the owner's world. Subclasses build their layout in build()
## and react to the owner in on_owner_event(). The World loads one at a time.

const WALL := 8.0
const WALL_COL := Color("4a3b33")
## The illustrated walls (Decor.walls): the face seen along the top wall, and
## the cap seen from above. Areas set their own before drawing.
var wall_face := Color("6a5546")
var wall_cap := Color("2e2620")
const WALL_EDGE := Color("6b5546")

var world: World
var area_id := ""
var display_name := ""
var bounds := Rect2(96, 36, 448, 256)
## The whole painted area (the camera's limits). One screen unless an area
## is wider (the Square): then World.update_camera follows Rue across it.
var view_size := Vector2(640, 360)
## How Rue came in this time (World._load_area sets it before build).
var arrival := ""
## Multiplies how fast the owner's awareness rises while you're here.
## Negative: awareness cools here instead (see OwnerDirector.floor_level()).
var awareness_rate := 1.0
## CanvasModulate tint for this area (darkened further by purge).
var tint := Color(1, 1, 1)
var erasure: Erasure
var interactables: Array[Node2D] = []
var exits: Array[Exit] = []
## Arrival name -> position.
var entries: Dictionary = {}

var _body: StaticBody2D

## Lighting ("modern pixel", docs/ART_DIRECTION.md). An area that adds
## lights sets `ambient` below 1: World dims the whole area by it, and the
## PointLight2Ds bring warmth and colour back where they shine. Solids cast
## soft shadows from lights that have shadows on. Rue carries a faint glow of
## her own in lit areas, so she's never lost in the dark.
var ambient := 1.0
var lights: Array[PointLight2D] = []
## Set by add_dust(): the area has its own lit motes, so the generic
## AreaAtmosphere dust stays out of it (one dust layer per area, not two).
var has_dust := false
## Lit areas paint their floors brighter (their daylight colours) and let
## `ambient` dim them: set with light_surfaces().
func light_surfaces(ambient_level: float, surface_boost: float) -> void:
	ambient = ambient_level
	self_modulate = Color(surface_boost, surface_boost, surface_boost)
static var _light_tex: Texture2D


## A soft round light (radius in px) at pos.
func add_light(pos: Vector2, color: Color, energy := 1.0, radius := 120.0, shadows := false) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = light_texture()
	l.texture_scale = radius / 64.0
	l.color = color
	l.energy = energy
	l.position = pos
	l.shadow_enabled = shadows and Settings.screen_effects >= 2
	if shadows:
		l.shadow_filter = Light2D.SHADOW_FILTER_PCF5
		l.shadow_filter_smooth = 3.0
		l.shadow_color = Color(0, 0, 0, 0.55)
	add_child(l)
	lights.append(l)
	return l


## Slow motes drifting through `rect` (dust in a sunbeam, pollen, loose data).
## Unshaded so they glow in the dark; their count drops with Screen effects.
func add_dust(rect: Rect2, color: Color, amount := 24, drift := Vector2(4, -3)) -> CPUParticles2D:
	has_dust = true
	var p := CPUParticles2D.new()
	p.position = rect.get_center()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = rect.size * 0.5
	p.amount = maxi(4, roundi(amount * (0.5 if Settings.screen_effects < 2 else 1.0)))
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.direction = drift.normalized() if drift != Vector2.ZERO else Vector2.UP
	p.spread = 60.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = drift.length() * 0.4
	p.initial_velocity_max = drift.length()
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.6
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.25, 0.75, 1.0])
	fade.colors = PackedColorArray([Color(color, 0.0), color, color, Color(color, 0.0)])
	p.color_ramp = fade
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	p.z_index = 5
	add_child(p)
	return p


## The shared falloff texture: bright centre, smooth fade to nothing.
static func light_texture() -> Texture2D:
	if _light_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 128
		t.height = 128
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		_light_tex = t
	return _light_tex


## Lay out walls, props and characters. `world` is already set.
func build() -> void:
	pass


## The owner reached an awareness threshold while you were here.
## `threshold` is one of OwnerDirector's constants (NOTICE, SUSPECT, ...).
func on_owner_event(_threshold: float) -> void:
	pass


## You just arrived: apply thresholds the owner already passed this session.
func catch_up() -> void:
	if world.director.has_fired(OwnerDirector.HUNT):
		start_erasure()


## Called every frame while this area is active and the session is running.
func area_process(_delta: float) -> void:
	pass


## Rue's PAUSE glitch: everything the owner drives holds still.
# --- navigation lifecycle (docs/GAMEPLAY_CONSISTENCY.md, pass 8) ------------

var _nav_dirty := Rect2()
var _nav_full := false
var _nav_pending := false


## Something solid changed here (a door opened or shut, crates were dragged,
## a wall crumbled): the shared walking grid re-checks that region once
## physics has the new shapes (deferred collision changes land on the next
## physics frame). Only changed cell occupancy advances the version and
## makes every walker plan again; redundant notices leave paths valid.
## Calls in the same frames are merged into one refresh. An empty rect means
## "somewhere": everything is re-checked.
func geometry_changed(where := Rect2()) -> void:
	if not has_meta("nav_grid"):
		return  # nobody walks here yet; the grid is built fresh on first use
	if where.size == Vector2.ZERO:
		_nav_full = true
	else:
		_nav_dirty = where if _nav_dirty.size == Vector2.ZERO else _nav_dirty.merge(where)
	if _nav_pending or not is_inside_tree():
		return
	_nav_pending = true
	var active_tree := get_tree()
	await active_tree.physics_frame
	# Transitions detach an area before freeing it. It can still resume here,
	# but get_tree() is already null: do not start a second wait on that node.
	if not is_inside_tree() or get_tree() != active_tree:
		_nav_pending = false
		return
	await active_tree.physics_frame
	_nav_pending = false
	if not is_inside_tree() or get_tree() != active_tree or not has_meta("nav_grid"):
		return
	var grid: NavGrid = get_meta("nav_grid")
	grid.refresh(Rect2() if _nav_full else _nav_dirty)
	_nav_full = false
	_nav_dirty = Rect2()


## For a solid that changed: tell the area it's in (if any).
static func notify_geometry(node: Node, where := Rect2()) -> void:
	var n := node
	while n != null and not (n is Area):
		n = n.get_parent()
	if n is Area:
		(n as Area).geometry_changed(where)


func set_owner_paused(on: bool) -> void:
	if erasure:
		erasure.set_process(not on)
	for n in [get("arin"), get("cursor"), get("lamp")]:
		if n is Node:
			n.set("paused", on)


## Static scenery painted once (Decor), under everything else in the area:
## `painter(ci: CanvasItem)` is called when the backdrop first draws. Areas
## keep only what moves in their own _draw.
##
## The painting is baked once into a texture at twice the logical resolution
## (an off-screen viewport, rendered once) and shown as one image: the lights
## then shade one quad instead of thousands of shapes every frame
## (docs/VISUAL_DIRECTION.md, performance).
const BACKDROP_SCALE := 2.0
const BACKDROP_SIZE := Vector2(640, 360)


func set_backdrop(painter: Callable) -> Node2D:
	var vp := SubViewport.new()
	vp.size = Vector2i(view_size.max(BACKDROP_SIZE) * BACKDROP_SCALE)
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var b := _Painted.new()
	b.painter = painter
	b.scale = Vector2(BACKDROP_SCALE, BACKDROP_SCALE)
	vp.add_child(b)
	var img := Sprite2D.new()
	img.texture = vp.get_texture()
	img.centered = false
	img.scale = Vector2(1.0 / BACKDROP_SCALE, 1.0 / BACKDROP_SCALE)
	img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	img.z_index = -1
	add_child(img)
	move_child(img, 0)
	return img


## Tree canopies over the play space (Decor.tree): drawn above the cast, and
## see-through over anyone standing beneath, so they never hide a threat.
func add_canopies(spots: Array, radius: float, leaf: Color) -> void:
	var c := _Canopies.new()
	c.spots = spots
	c.radius = radius
	c.leaf = leaf
	c.area = self
	c.z_index = 20
	add_child(c)


class _Painted:
	extends Node2D
	var painter: Callable

	func _draw() -> void:
		if painter.is_valid():
			painter.call(self)


class _Canopies:
	extends Node2D
	var spots: Array = []
	var radius := 14.0
	var leaf := Color("2c4430")
	var area: Node2D
	var _fade: Array = []

	func _ready() -> void:
		for i in spots.size():
			_fade.append(1.0)

	func _process(delta: float) -> void:
		var people: Array = []
		for n in get_tree().get_nodes_in_group("canopy_reveal"):
			if n is Node2D:
				people.append(n.global_position)
		var changed := false
		for i in spots.size():
			var under := false
			for p: Vector2 in people:
				if p.distance_to(to_global(spots[i])) < radius + 8.0:
					under = true
			var want := 0.28 if under else 0.95
			var f: float = move_toward(_fade[i], want, delta * 3.0)
			if f != _fade[i]:
				_fade[i] = f
				changed = true
		if changed:
			queue_redraw()

	func _draw() -> void:
		for i in spots.size():
			Decor.tree(self, spots[i], radius, leaf, float(i), _fade[i])


## The owner's learned habits changed mid-run (OwnerMemory.fray clears the
## route memory): areas whose watchers walk a learned round rebuild it now.
func relearn_owner_routes() -> void:
	pass


## Where to go next in this area (Pip trots toward it), or Vector2.INF.
func guide_point() -> Vector2:
	return Vector2.INF


func entry_point(arrival: String) -> Vector2:
	return entries.get(arrival, bounds.get_center())


## Erasure grows in this area; seeded where you died here before.
## seed_deaths: also seed where you died here before (the owner remembers).
## Death seeds closer than this to Rue are skipped when the static starts.
const SAFE_SEED_DISTANCE := 40.0
## How long a death spot glows before its static starts.
const DEATH_SEED_WARNING := 3.0


func start_erasure(extra_seeds: Array[Vector2] = [], seed_deaths := true) -> void:
	if erasure == null or erasure.active:
		return
	erasure.active = true
	# Faster with every purge, but always something you can outrun.
	erasure.interval = maxf(0.2, 0.45 - 0.04 * OwnerMemory.purge)
	erasure.burst = 1 + OwnerMemory.purge / 3
	if seed_deaths:
		# (Not where you're standing: arriving onto static you can't see
		# yet isn't a fair death.)
		var here: Vector2 = world.player.global_position if world and world.player else Vector2.INF
		for p in OwnerMemory.deaths_in(area_id):
			if here == Vector2.INF or p.distance_to(here) > SAFE_SEED_DISTANCE:
				# Shown first, then grown: the spot glows for a few seconds
				# before its static starts (PL-4b), so it can be read and
				# gone round; the owner still remembers where she died.
				erasure.seed_after(p, DEATH_SEED_WARNING * Settings.pace("warning"))
				for g in get_children():
					if g is GhostMarker and g.position.distance_to(p) < 1.0:
						g.warn(DEATH_SEED_WARNING * Settings.pace("warning"))
	for p in extra_seeds:
		erasure.seed_at(p)
	world.fx.eraser_starts()
	Sfx.play("erase_start")


# --- helpers for subclasses -------------------------------------------------

## The body Rue left (docs/DARK_TRUTH_DESIGN.md §8): one at a time.
func place_husk(at: Vector2) -> void:
	for n in interactables.duplicate():
		if n is Husk:
			interactables.erase(n)
			n.queue_free()
	var husk := Husk.new()
	husk.position = at
	add_child(husk)
	interactables.append(husk)


func setup_common() -> void:
	_body = StaticBody2D.new()
	add_child(_body)
	erasure = Erasure.new()
	erasure.setup(bounds, world.player)
	erasure.caught_player.connect(func() -> void: world.kill("erased", "eraser"))
	add_child(erasure)
	if not world.purged:
		add_fragments.call_deferred()
	if OwnerMemory.husk_in(area_id):
		place_husk(OwnerMemory.husk_pos)
	var deaths := OwnerMemory.deaths_in(area_id)
	for i in deaths.size():
		var g := GhostMarker.new()
		g.index = i
		g.position = deaths[i]
		add_child(g)


func add_solid(rect: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = rect.get_center()
	_body.add_child(col)
	# Furniture and walls cast shadows from lights that have them.
	var occ := LightOccluder2D.new()
	var poly := OccluderPolygon2D.new()
	poly.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	occ.occluder = poly
	add_child(occ)


## Walls around `bounds`, leaving gaps. Each gap: {"side": "top"|"bottom"|"left"|"right", "from": float, "to": float}.
func add_boundary(gaps: Array = []) -> void:
	var r := bounds
	for side in ["top", "bottom", "left", "right"]:
		var horizontal: bool = side == "top" or side == "bottom"
		var start := r.position.x - WALL if horizontal else r.position.y
		var stop := r.end.x + WALL if horizontal else r.end.y
		var cuts: Array = []
		for g in gaps:
			if g.side == side:
				cuts.append(Vector2(g.from, g.to))
		cuts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var pos := start
		for c: Vector2 in cuts + [Vector2(stop, stop)]:
			if c.x > pos:
				add_solid(_side_rect(side, pos, c.x))
			pos = maxf(pos, c.y)


func _side_rect(side: String, a: float, b: float) -> Rect2:
	var r := bounds
	match side:
		"top": return Rect2(a, r.position.y - WALL, b - a, WALL)
		"bottom": return Rect2(a, r.end.y, b - a, WALL)
		"left": return Rect2(r.position.x - WALL, a, WALL, b - a)
		_: return Rect2(r.end.x, a, WALL, b - a)


## A wall segment blocking one of the gaps so the player can't walk off-screen.
func add_exit(rect: Rect2, target: String, arrival: String, open := true, blocked_message := "") -> Exit:
	var e := Exit.new()
	add_child(e)
	e.setup(rect, target, arrival)
	e.open = open
	e.blocked_message = blocked_message
	e.used.connect(func(x: Exit) -> void: world.change_area(x.target_area, x.arrival))
	e.blocked.connect(func(x: Exit) -> void: world.blocked_exit(x))
	exits.append(e)
	# Something solid just beyond the exit so you can't leave the screen.
	var beyond := rect
	if rect.size.x < rect.size.y:
		beyond.position.x += rect.size.x * (1.0 if rect.position.x > bounds.get_center().x else -1.0)
	else:
		beyond.position.y += rect.size.y * (1.0 if rect.position.y > bounds.get_center().y else -1.0)
	add_solid(beyond)
	return e


## A label at a way out: where it goes, with an arrow. `is_open` (optional)
## returns whether the way is open right now.
func add_sign(pos: Vector2, text: String, direction: Vector2, is_open := Callable()) -> ExitSign:
	var s := ExitSign.new()
	s.position = pos
	s.text = text
	s.direction = direction
	s.is_open = is_open
	s.z_index = 5
	add_child(s)
	return s


func add_npc(id: String, pos: Vector2, initial := Npc.State.NORMAL) -> Npc:
	var n := Npc.new()
	n.npc_id = id
	n.position = pos
	n.player = world.player
	add_child(n)
	n.setup(Npc.State.DELETED if OwnerMemory.is_deleted(id) else initial)
	interactables.append(n)
	return n


## Places this area's memory fragments that haven't been recovered yet.
func add_fragments() -> void:
	for f in Story.fragments_in(area_id):
		if OwnerMemory.has_fragment(f.id):
			continue
		var m := MemoryFragment.new()
		m.fragment_id = f.id
		m.position = f.pos
		m.player = world.player
		m.touched.connect(world.recover_fragment)
		add_child(m)


func add_readable(title: String, pos: Vector2, look: Readable.Look, provider: Callable) -> Readable:
	var r := Readable.new()
	r.title = title
	r.position = pos
	r.look = look
	r.lines_provider = provider
	add_child(r)
	interactables.append(r)
	return r


func draw_walls(gaps: Array = []) -> void:
	Decor.wall_shadow(self, bounds, 12.0, 0.3)
	Decor.walls(self, bounds, WALL, wall_face, wall_cap, gaps)
