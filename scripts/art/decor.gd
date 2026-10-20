class_name Decor
extends RefCounted
## The illustrated environment kit (docs/VISUAL_DIRECTION.md). Static drawing
## helpers in world coordinates, so every area builds its places from the
## same materials: painted planks and stone, walls with thickness and a cap,
## furniture seen from three-quarters above (a lit top, a shaded front), soft
## contact shadows, and a little colour variation so nothing looks stamped.
##
## Rules that keep the play space readable:
##   - Anything drawn with a front face (furniture()) is solid in the game.
##     Decoration that isn't solid stays flat: on the floor, or on a wall face.
##   - Floors are mid-value and low-contrast; characters, doors and
##     interactables carry the strongest contrast.

const INK := Color("1b1418")


## A filled circle with few sides: draw_circle uses many, and figures and
## canopies are drawn every frame (docs/VISUAL_DIRECTION.md, performance).
static func disc(ci: CanvasItem, c: Vector2, r: float, col: Color, n := 12) -> void:
	var pts := PackedVector2Array()
	pts.resize(n)
	for i in n:
		var a := TAU * i / n
		pts[i] = c + Vector2(cos(a) * r, sin(a) * r)
	ci.draw_colored_polygon(pts, col)


## A stable 0..1 value for (x, y, seed): colour variation that never flickers.
static func hash01(x: float, y: float, s: float = 0.0) -> float:
	var h := sin(x * 12.9898 + y * 78.233 + s * 37.719) * 43758.5453
	return h - floorf(h)


## Wooden floor: boards of slightly different tones, staggered joints,
## grain lines and the odd knot. `board` is the board width (px).
static func planks(ci: CanvasItem, r: Rect2, base: Color, board := 12.0, s := 0.0) -> void:
	ci.draw_rect(r, base)
	var y := r.position.y
	var row := 0
	while y < r.end.y:
		var h := minf(board, r.end.y - y)
		var x := r.position.x - float((row * 37) % 70)
		while x < r.end.x:
			var w := 58.0 + hash01(x, y, s) * 40.0
			var x0 := maxf(x, r.position.x)
			var x1 := minf(x + w, r.end.x)
			if x1 > x0:
				var tone := (hash01(x, y, s + 1.0) - 0.5) * 0.12
				var c := base.lightened(tone) if tone > 0.0 else base.darkened(-tone)
				ci.draw_rect(Rect2(x0, y, x1 - x0, h), c)
				# Grain: two faint lines along the board.
				var g := Color(base.darkened(0.18), 0.35)
				ci.draw_line(Vector2(x0 + 3, y + h * 0.35), Vector2(x1 - 4, y + h * 0.38), g, 0.5)
				ci.draw_line(Vector2(x0 + 8, y + h * 0.7), Vector2(x1 - 10, y + h * 0.66), g, 0.5)
				if hash01(x, y, s + 2.0) > 0.82:
					ci.draw_circle(Vector2(lerpf(x0, x1, hash01(x, y, s + 3.0)), y + h * 0.5), 0.9, Color(base.darkened(0.3), 0.6))
				# The joint at the board's end.
				ci.draw_line(Vector2(x1, y), Vector2(x1, y + h), Color(base.darkened(0.32), 0.9), 0.6)
			x += w
		ci.draw_line(Vector2(r.position.x, y + h), Vector2(r.end.x, y + h), Color(base.darkened(0.35), 0.9), 0.7)
		y += board
		row += 1


## Stone or cobbles: rounded, irregular stones on a mortar ground.
static func cobbles(ci: CanvasItem, r: Rect2, base: Color, size := 9.0, s := 0.0) -> void:
	ci.draw_rect(r, base.darkened(0.28))
	var y := r.position.y
	var row := 0
	while y < r.end.y:
		var x := r.position.x - (size * 0.5 if row % 2 == 1 else 0.0)
		while x < r.end.x:
			var w := size * (0.8 + hash01(x, y, s) * 0.5)
			var c := Vector2(x + w * 0.5, y + size * 0.5)
			var rr := Vector2(w * 0.46, size * 0.4)
			var tone := (hash01(x, y, s + 4.0) - 0.5) * 0.14
			var col := base.lightened(tone) if tone > 0.0 else base.darkened(-tone)
			_blob(ci, c, rr, col, r)
			_blob(ci, c + Vector2(-rr.x * 0.2, -rr.y * 0.3), rr * Vector2(0.55, 0.35), Color(col.lightened(0.12), 0.6), r)
			x += w
		y += size * 0.86
		row += 1


## Laid flagstones: rectangular slabs in staggered courses, thin mortar,
## each slab a slightly different tone with a lit top edge. Calmer than
## cobbles: for interiors that should feel old and still.
static func flagstones(ci: CanvasItem, r: Rect2, base: Color, course := 18.0, s := 0.0) -> void:
	ci.draw_rect(r, base.darkened(0.2))
	var y := r.position.y
	var row := 0
	while y < r.end.y:
		var h := minf(course, r.end.y - y)
		var x := r.position.x - hash01(row, 0.0, s) * course
		while x < r.end.x:
			var w := course * (0.9 + hash01(x, y, s) * 0.8)
			var slab := Rect2(x + 1.0, y + 1.0, w - 2.0, h - 2.0).intersection(r)
			if slab.size.x > 1.0 and slab.size.y > 1.0:
				var tone := (hash01(x, y, s + 3.0) - 0.5) * 0.1
				var col := base.lightened(tone) if tone > 0.0 else base.darkened(-tone)
				ci.draw_rect(slab, col)
				ci.draw_rect(Rect2(slab.position, Vector2(slab.size.x, 1.0)), Color(col.lightened(0.1), 0.5))
				# The odd worn chip or crack keeps it from looking printed.
				if hash01(x, y, s + 7.0) > 0.82:
					var p := slab.position + slab.size * Vector2(hash01(x, y, s + 8.0), 0.6)
					ci.draw_line(p, p + Vector2(5, 3), Color(base.darkened(0.3), 0.6), 0.7)
			x += w
		y += course
		row += 1


## Grass ground: a soft base with tufts and the odd flower, never busy.
static func grass(ci: CanvasItem, r: Rect2, base: Color, s := 0.0, density := 0.004) -> void:
	ci.draw_rect(r, base)
	var n := int(r.get_area() * density)
	for i in n:
		var p := Vector2(r.position.x + hash01(i, 1.0, s) * r.size.x, r.position.y + hash01(i, 2.0, s) * r.size.y)
		var dark := hash01(i, 3.0, s) > 0.5
		var c := base.darkened(0.12) if dark else base.lightened(0.1)
		if hash01(i, 4.0, s) > 0.55:
			# A tuft: three blades.
			for b in 3:
				ci.draw_line(p + Vector2(b - 1.0, 0), p + Vector2((b - 1.0) * 1.6, -2.4 - float(b % 2)), c, 0.6)
		else:
			ci.draw_circle(p, 1.4 + hash01(i, 5.0, s) * 1.6, Color(c, 0.45))
		if hash01(i, 6.0, s) > 0.985:
			ci.draw_circle(p + Vector2(1, -1), 0.8, Color("e8d890") if hash01(i, 7.0, s) > 0.5 else Color("d88aa0"))


## A worn dirt or stone path with soft edges.
static func path(ci: CanvasItem, r: Rect2, base: Color, s := 0.0) -> void:
	ci.draw_rect(r.grow(1.5), Color(base.darkened(0.15), 0.5))
	ci.draw_rect(r, base)
	var n := int(r.get_area() * 0.006)
	for i in n:
		var p := Vector2(r.position.x + hash01(i, 8.0, s) * r.size.x, r.position.y + hash01(i, 9.0, s) * r.size.y)
		ci.draw_circle(p, 0.6 + hash01(i, 10.0, s), Color(base.darkened(0.2) if hash01(i, 11.0, s) > 0.5 else base.lightened(0.12), 0.6))


## Soft shadow pooling where floor meets wall (inside `r`, `depth` px deep).
static func wall_shadow(ci: CanvasItem, r: Rect2, depth := 10.0, strength := 0.35) -> void:
	var dark := Color(0, 0, 0, strength)
	var clear := Color(0, 0, 0, 0)
	_grad(ci, Rect2(r.position, Vector2(r.size.x, depth)), dark, clear, true)
	_grad(ci, Rect2(r.position.x, r.end.y - depth * 0.5, r.size.x, depth * 0.5), clear, Color(0, 0, 0, strength * 0.5), true)
	_grad(ci, Rect2(r.position, Vector2(depth * 0.7, r.size.y)), Color(0, 0, 0, strength * 0.7), clear, false)
	_grad(ci, Rect2(r.end.x - depth * 0.7, r.position.y, depth * 0.7, r.size.y), clear, Color(0, 0, 0, strength * 0.7), false)


## Walls around `r`, `t` thick: a cap seen from above and, along the top, the
## wall's face. `gaps` as Area.draw_walls (side, from, to): left open.
static func walls(ci: CanvasItem, r: Rect2, t: float, face: Color, cap: Color, gaps: Array = []) -> void:
	var outer := r.grow(t)
	ci.draw_rect(Rect2(outer.position, Vector2(outer.size.x, t)), face)
	# The top wall's face: a skirting board and a lighter upper band.
	ci.draw_rect(Rect2(r.position.x, r.position.y - 2.0, r.size.x, 2.0), face.darkened(0.25))
	ci.draw_rect(Rect2(outer.position.x, outer.position.y, outer.size.x, 2.0), cap)
	ci.draw_rect(Rect2(outer.position.x, r.end.y, outer.size.x, t), cap)
	ci.draw_rect(Rect2(outer.position.x, r.position.y, t, r.size.y), cap)
	ci.draw_rect(Rect2(r.end.x, r.position.y, t, r.size.y), cap)
	# A thin highlight on the inner lip, and ink on the outside.
	ci.draw_rect(r, Color(cap.lightened(0.25), 0.6), false, 0.6)
	ci.draw_rect(outer, INK, false, 1.0)
	for g in gaps:
		var gr: Rect2
		match str(g.side):
			"top":
				gr = Rect2(g.from, outer.position.y - 1, g.to - g.from, t + 2)
			"bottom":
				gr = Rect2(g.from, r.end.y - 1, g.to - g.from, t + 2)
			"left":
				gr = Rect2(outer.position.x - 1, g.from, t + 2, g.to - g.from)
			_:
				gr = Rect2(r.end.x - 1, g.from, t + 2, g.to - g.from)
		ci.draw_rect(gr, Color(0.02, 0.016, 0.024))


## Solid furniture seen from three-quarters above: the footprint `r` is the
## top surface, with a front face `front` px tall below it and a contact
## shadow. Returns the top rect for details.
static func furniture(ci: CanvasItem, r: Rect2, top: Color, front := 4.0) -> Rect2:
	ci.draw_rect(Rect2(r.position + Vector2(1.5, front + 1.5), r.size), Color(0, 0, 0, 0.28))
	var t := Rect2(r.position, Vector2(r.size.x, r.size.y - front))
	ci.draw_rect(Rect2(r.position.x, t.end.y, r.size.x, front), top.darkened(0.3))
	ci.draw_rect(t, top)
	ci.draw_line(t.position, Vector2(t.end.x, t.position.y), top.lightened(0.18), 0.8)
	ci.draw_rect(r, INK, false, 0.8)
	ci.draw_line(Vector2(r.position.x, t.end.y), Vector2(r.end.x, t.end.y), Color(INK, 0.6), 0.6)
	return t


## A bed in a footprint (headboard at the top): frame, mattress, a quilt
## with a fold, a pillow.
static func bed(ci: CanvasItem, r: Rect2, wood: Color, quilt: Color, sheet: Color) -> void:
	var top := furniture(ci, r, wood, 4.0)
	var mat := top.grow(-2.0)
	ci.draw_rect(mat, sheet)
	var q := Rect2(mat.position + Vector2(0, mat.size.y * 0.42), Vector2(mat.size.x, mat.size.y * 0.58))
	ci.draw_rect(q, quilt)
	for i in int(q.size.x / 7.0):
		ci.draw_line(Vector2(q.position.x + 3.5 + i * 7.0, q.position.y + 1), Vector2(q.position.x + 3.5 + i * 7.0, q.end.y - 1), Color(quilt.lightened(0.15), 0.5), 0.6)
	ci.draw_rect(Rect2(q.position.x, q.position.y, q.size.x, 2.2), quilt.lightened(0.2))  # the fold
	var pillow := Rect2(mat.position + Vector2(mat.size.x * 0.18, 2), Vector2(mat.size.x * 0.64, mat.size.y * 0.28))
	_round_rect(ci, pillow, 2.0, sheet.lightened(0.12))
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 3.0), wood.darkened(0.12))  # headboard


## A rug: rounded, a border, a pattern, fringe at both ends.
static func rug(ci: CanvasItem, r: Rect2, col: Color, accent: Color) -> void:
	_round_rect(ci, r.grow(0.8), 2.5, Color(0, 0, 0, 0.18))
	_round_rect(ci, r, 2.5, col)
	ci.draw_rect(r.grow(-4.0), Color(accent, 0.75), false, 1.2)
	ci.draw_rect(r.grow(-7.0), Color(accent, 0.35), false, 0.6)
	var n := int((r.size.x - 20.0) / 22.0) + 1
	for i in n:
		var c := Vector2(r.position.x + 20.0 + i * 22.0, r.get_center().y)
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -7), c + Vector2(7, 0), c + Vector2(0, 7), c + Vector2(-7, 0)]), Color(accent, 0.5))
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -3), c + Vector2(3, 0), c + Vector2(0, 3), c + Vector2(-3, 0)]), Color(col.darkened(0.2), 0.8))
	var x := r.position.x + 2.0
	while x < r.end.x - 1.0:
		ci.draw_line(Vector2(x, r.position.y - 2.2), Vector2(x, r.position.y), Color(accent.lightened(0.2), 0.7), 0.6)
		ci.draw_line(Vector2(x, r.end.y), Vector2(x, r.end.y + 2.2), Color(accent.lightened(0.2), 0.7), 0.6)
		x += 2.5


## A lamp seen from above: a round shade with a warm rim.
static func lamp(ci: CanvasItem, at: Vector2, shade: Color) -> void:
	ci.draw_circle(at + Vector2(1, 1.5), 3.6, Color(0, 0, 0, 0.25))
	ci.draw_circle(at, 3.6, INK)
	ci.draw_circle(at, 3.0, shade)
	ci.draw_circle(at + Vector2(-0.8, -0.8), 1.2, shade.lightened(0.4))


## A potted plant or bush: overlapping leaf blobs on a shadow.
static func plant(ci: CanvasItem, at: Vector2, r: float, leaf: Color, s := 0.0) -> void:
	ci.draw_circle(at + Vector2(1.5, 2.0), r, Color(0, 0, 0, 0.25))
	ci.draw_circle(at, r + 0.7, INK)
	for i in 6:
		var a := TAU * (i / 6.0 + hash01(at.x, at.y, s + i) * 0.1)
		var p := at + Vector2(cos(a), sin(a)) * r * 0.45
		ci.draw_circle(p, r * 0.6, leaf.darkened(0.12) if i % 2 == 0 else leaf)
	ci.draw_circle(at + Vector2(-r * 0.25, -r * 0.3), r * 0.35, leaf.lightened(0.15))


## A tree seen from above: a big canopy with light on one side and a soft
## shadow cast down-right.
static func tree(ci: CanvasItem, at: Vector2, r: float, leaf: Color, s := 0.0, alpha := 1.0) -> void:
	_blob(ci, at + Vector2(r * 0.35, r * 0.45), Vector2(r * 1.05, r * 0.85), Color(0, 0, 0, 0.28 * alpha), Rect2(-1e6, -1e6, 2e6, 2e6))
	disc(ci, at, r + 0.8, Color(INK, alpha))
	for i in 7:
		var a := TAU * i / 7.0 + hash01(at.x, at.y, s) * 2.0
		disc(ci, at + Vector2(cos(a), sin(a)) * r * 0.45, r * 0.62, Color(leaf.darkened(0.1 + 0.08 * float(i % 2)), alpha))
	disc(ci, at + Vector2(-r * 0.2, -r * 0.25), r * 0.55, Color(leaf, alpha))
	disc(ci, at + Vector2(-r * 0.35, -r * 0.4), r * 0.28, Color(leaf.lightened(0.15), alpha))


## A house seen from three-quarters above: a roof (the footprint's top part)
## with ridge and tiles, and a front wall with a door and windows.
static func house(ci: CanvasItem, r: Rect2, roof: Color, wall: Color, door_x := -1.0, lit := true) -> void:
	var wall_h := minf(14.0, r.size.y * 0.4)
	var roof_r := Rect2(r.position, Vector2(r.size.x, r.size.y - wall_h))
	var front := Rect2(r.position.x, roof_r.end.y, r.size.x, wall_h)
	ci.draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.3))
	ci.draw_rect(front, wall)
	for i in int(front.size.x / 5.0):
		ci.draw_line(Vector2(front.position.x + i * 5.0, front.position.y), Vector2(front.position.x + i * 5.0, front.end.y), Color(wall.darkened(0.12), 0.5), 0.5)
	ci.draw_rect(roof_r, roof)
	var ridge := roof_r.get_center().y
	ci.draw_rect(Rect2(roof_r.position.x, roof_r.position.y, roof_r.size.x, ridge - roof_r.position.y), roof.lightened(0.1))
	var y := roof_r.position.y + 3.0
	while y < roof_r.end.y - 1.0:
		ci.draw_line(Vector2(roof_r.position.x, y), Vector2(roof_r.end.x, y), Color(roof.darkened(0.2), 0.7), 0.6)
		y += 3.5
	ci.draw_line(Vector2(roof_r.position.x, ridge), Vector2(roof_r.end.x, ridge), roof.darkened(0.35), 1.0)
	ci.draw_rect(Rect2(roof_r.position.x - 1, roof_r.end.y - 1.5, roof_r.size.x + 2, 2.0), roof.darkened(0.35))  # eaves
	var win := Color("f2c878") if lit else Color("2a2a3a")
	var n := int(front.size.x / 22.0)
	for i in n:
		var wx := front.position.x + (i + 0.5) * front.size.x / n - 3.0
		if door_x >= 0.0 and absf(wx + 3.0 - door_x) < 8.0:
			continue
		ci.draw_rect(Rect2(wx, front.position.y + 3.0, 6.0, 5.0), INK)
		ci.draw_rect(Rect2(wx + 0.8, front.position.y + 3.8, 4.4, 3.4), win)
		ci.draw_line(Vector2(wx + 3.0, front.position.y + 3.8), Vector2(wx + 3.0, front.position.y + 7.2), INK, 0.5)
	if door_x >= 0.0:
		ci.draw_rect(Rect2(door_x - 4.0, front.end.y - 9.0, 8.0, 9.0), INK)
		ci.draw_rect(Rect2(door_x - 3.2, front.end.y - 8.2, 6.4, 8.2), wall.darkened(0.45))
	ci.draw_rect(r, INK, false, 1.0)


static func _round_rect(ci: CanvasItem, r: Rect2, rad: float, c: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(int(maxf(1.0, rad)))
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)


static func _blob(ci: CanvasItem, c: Vector2, r: Vector2, col: Color, clip: Rect2) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0
		var q := c + Vector2(cos(a) * r.x, sin(a) * r.y)
		pts.append(Vector2(clampf(q.x, clip.position.x, clip.end.x), clampf(q.y, clip.position.y, clip.end.y)))
	ci.draw_colored_polygon(pts, col)


## A vertical (`down`) or horizontal gradient rectangle.
static func _grad(ci: CanvasItem, r: Rect2, from: Color, to: Color, down: bool) -> void:
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var cols := PackedColorArray([from, from if down else to, to, to if down else from])
	ci.draw_polygon(pts, cols)
