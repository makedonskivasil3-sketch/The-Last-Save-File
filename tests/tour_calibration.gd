extends "res://tests/test_case.gd"
## Visual calibration captures (brief of 2026-11-03, §4–5): the same save
## state, Rue's position and output size every time, so a before/after pair
## differs only by the art. Run with
##   xvfb-run godot --path . -s res://tests/run_tests.gd -- --test-mode --tour \
##     --filter=tour_calibration --screenshots=<dir>

## Where Rue stands in each area for its capture: a calm, central view.
const SPOTS := {
	"room": [Vector2(320, 220), "door"],
	"square": [Vector2(320, 200), "house"],
	"house": [Vector2(320, 220), "square"],
	"archive": [Vector2(250, 240), "square"],
	"workshop": [Vector2(250, 240), "stairs"],
	"oob": [Vector2(110, 84), "well"],
	"bin": [Vector2(118, 180), "archive"],
	"edge": [Vector2(320, 262), "north"],
}


func _settle(w: World, at: Vector2) -> void:
	w.player.global_position = at
	w.director.awareness = 0.0
	await wait(1.2)  # lights, dust and the camera settle


func test_workshop_and_square_calibration() -> void:
	var w: World = await start_session()
	await go_to(w, "workshop", "stairs")
	await _settle(w, SPOTS.workshop[0])
	await shot("cal_workshop_unrepaired")
	w.area.wick.interact()
	await frames(3)
	await finish_dialogue(w)
	w.area.lamp.interact()
	await wait(0.5)
	await finish_dialogue(w)
	await _settle(w, SPOTS.workshop[0])
	await shot("cal_workshop_repaired")
	await go_to(w, "square", "house")
	if w.area.get("arin"):
		w.area.arin.position = Vector2(560, 280)
		w.area.arin.route = [Vector2(560, 280)] as Array[Vector2]
	await _settle(w, SPOTS.square[0])
	await shot("cal_square")


func test_every_area_now() -> void:
	for id: String in SPOTS:
		memory().wipe()
		var w: World = await start_session()
		if id != "room":
			await go_to(w, id, SPOTS[id][1])
		await _settle(w, SPOTS[id][0])
		await shot("area_" + id)
