class_name LanternFixture
extends Node2D
## The wick is an object, not a memory fragment or another save crystal.
## Its actions are immediate, written feedback; no actor recording implied.

signal changed
var lamp := false


func can_interact() -> bool:
	return lamp or not Relationships.has(LanternRoute.SPOOL)


func interact_name() -> String:
	return "SERVICE LANTERN" if lamp else "FESTIVAL WICK"


func interact_prompt() -> String:
	if not lamp:
		return "take spare wick"
	if LanternRoute.repaired():
		return "look at the light"
	return "fit wick" if Relationships.has(LanternRoute.SPOOL) else "inspect empty lantern"


func interact() -> String:
	if not lamp:
		LanternRoute.record(LanternRoute.SPOOL, "A spare festival wick", [
			"A coil of wick, still wrapped in paper marked FIFTH LANTERN.",
			"The service lantern on the centre bench has an empty holder. This will fit."])
		Sfx.play("ui_confirm")
		changed.emit()
		queue_redraw()
		return "WICK KEPT  ·  fit it to the service lantern. (journal: Objects)"
	if LanternRoute.repaired():
		return "The light reaches the hatch. A way back that doesn't cross Arin's road."
	if not Relationships.has(LanternRoute.SPOOL):
		return "An empty wick holder. A spare coil lies on the west workbench."
	LanternRoute.record(LanternRoute.REPAIRED, "A light kept burning", [
		"I fitted the spare wick. The service light came on, and the hatch under the well opened.",
		"The festival needed two people to hold a light. I kept this one burning myself.",
		"The workshop is quiet. Save and exit is available here when no story panel is open."])
	Sfx.play("ui_confirm")
	changed.emit()
	queue_redraw()
	return "SERVICE ROUTE OPEN  ·  hatch to the well; stairs to the Archive."


func _draw() -> void:
	if not lamp:
		if Relationships.has(LanternRoute.SPOOL):
			return
		draw_rect(Rect2(-8, -5, 16, 9), Color("d8c7a1"))
		for i in 5:
			draw_arc(Vector2(-3 + i, -1), 3.0, 0.0, TAU, 12, Color("866440"), 0.8)
		draw_line(Vector2(4, 1), Vector2(10, 4), Color("bba478"), 1.0)
		return
	var lit := LanternRoute.repaired()
	draw_rect(Rect2(-7, -18, 14, 18), Color("49392d"))
	draw_rect(Rect2(-4, -15, 8, 11), Color("f3cd83") if lit else Color("1c252b"))
	draw_rect(Rect2(-8, 0, 16, 3), Color("b18a50"))
	draw_arc(Vector2(0, -19), 5.0, PI, TAU, 12, Color("b18a50"), 1.5)
	if lit:
		draw_circle(Vector2(0, -10), 12, Color(1, 0.8, 0.4, 0.12))
