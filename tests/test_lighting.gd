extends "res://tests/test_case.gd"
## Lighting must never hide what matters (docs/ART_DIRECTION.md).


func test_no_shadow_casting_light_sits_inside_a_solid() -> void:
	var w := await start_session()
	for stop in [["room", "start"], ["square", "house"], ["house", "front"], ["archive", "west"]]:
		if w.area.area_id != stop[0]:
			await go_to(w, stop[0], stop[1])
		for l in w.area.lights:
			if not l.shadow_enabled:
				continue
			for occ in w.area.get_children():
				if occ is LightOccluder2D:
					var poly: PackedVector2Array = occ.occluder.polygon
					check(not Geometry2D.is_point_in_polygon(l.position, poly), "%s: a light at %s is inside a shadow-caster, so it lights nothing" % [stop[0], l.position])


func test_arins_cone_reads_the_same_in_lit_areas() -> void:
	var w := await start_session()
	await go_to(w, "square", "house")
	var arin: OwnerAvatar = w.area.arin
	var c := arin.cone_color(0.06)
	# What reaches the screen: the cone colour times the area's ambient.
	var shown := Color(c.r * w.area.ambient, c.g * w.area.ambient, c.b * w.area.ambient)
	check(shown.is_equal_approx(Color(OwnerAvatar.VIEW_COL, 1.0)), "the cone isn't dimmed by the lighting (%s)" % shown)
