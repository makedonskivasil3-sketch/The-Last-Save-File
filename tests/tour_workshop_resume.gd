extends "res://tests/test_case.gd"
## Native route check: close and relaunch at each new mission stage.


func test_resume_every_workshop_stage() -> void:
	for stage in 3:
		memory().wipe()
		var w: World = await start_session()
		await go_to(w, "workshop", "stairs")
		if stage >= 1:
			w.area.wick.interact()
		if stage >= 2:
			w.area.lamp.interact()
		w.player.position = Vector2(250, 240)
		await frames(3)
		var purge: int = memory().purge
		var quits: int = memory().quits
		w._suspend()
		await wait_until(func() -> bool: return scene() != null and scene().get("player") == null, 5.0, "saved to title")
		var resumed: World = await start_session()
		await frames(3)
		check_eq(resumed.area.area_id, "workshop", "stage %d resumes in workshop" % stage)
		check(resumed.woke_from_suspend, "resumed the saved run")
		check(resumed.player.position.distance_to(Vector2(250, 240)) < 2, "safe saved position restored")
		check(resumed.body_fits(resumed.player.position), "whole body fits after reload")
		check_eq(Relationships.has(LanternRoute.SPOOL), stage >= 1, "wick state survives")
		check_eq(LanternRoute.repaired(), stage >= 2, "repair state survives")
		check_eq(resumed.area.hatch.can_interact(), stage >= 2, "hatch state survives")
		check_eq(memory().purge, purge, "no purge charge")
		check_eq(memory().quits, quits, "no quit charge")
