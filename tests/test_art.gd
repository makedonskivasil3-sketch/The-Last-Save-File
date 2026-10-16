extends "res://tests/test_case.gd"
## Art direction systems with rules (docs/ART_DIRECTION.md).


func test_the_afternoon_drains_when_the_owner_watches() -> void:
	var w := await start_session()
	var sun: SunBeam = w.area.sun
	check(sun != null, "Arin's room has its afternoon")
	sun.watched = 0.0
	var calm := sun.warmth()
	sun.watched = OwnerDirector.SUSPECT / 100.0
	var suspect := sun.warmth()
	sun.watched = OwnerDirector.HUNT / 100.0
	var hunt := sun.warmth()
	check(calm > 0.95, "full warmth while the owner is calm (%.2f)" % calm)
	check(suspect < calm and hunt < suspect, "and it drains as they look (%.2f > %.2f > %.2f)" % [calm, suspect, hunt])
	check(hunt >= 0.15, "but never quite goes out")


func test_the_light_follows_awareness() -> void:
	var w := await start_session()
	var sun: SunBeam = w.area.sun
	w.director.add_awareness(OwnerDirector.CONTAIN)
	await wait(1.5)
	check(sun.watched > 0.3, "the beam reads the owner's attention (%.2f)" % sun.watched)


func test_the_light_stutters_on_a_reload() -> void:
	var w := await start_session()
	var sun: SunBeam = w.area.sun
	w.player.global_position = Vector2(320, 240)
	await wait(1.0)
	w.player.global_position = Vector2(200, 240)
	await wait(1.0)
	w.owner_moves.load_last_save(true)
	await frames(3)
	check(sun._stutter > 0.5, "the remembered afternoon skips when the owner reloads")
