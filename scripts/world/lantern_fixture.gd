class_name LanternFixture
extends Node2D
## The wick is an object, not a memory fragment or another save crystal.
## Its actions are immediate, written feedback; no actor recording implied.

signal changed
var lamp := false
## The fifth festival frame on the shelf (LanternRoute.NAMED).
var frame := false


func can_interact() -> bool:
	if frame:
		return true
	return lamp or not Relationships.has(LanternRoute.SPOOL)


func interact_name() -> String:
	if frame:
		return "THE FIFTH FRAME"
	return "SERVICE LANTERN" if lamp else "FESTIVAL WICK"


func interact_prompt() -> String:
	if frame:
		return "read the label" if LanternRoute.named() or not LanternRoute.repaired() else "look at the blank label"
	if not lamp:
		return "take spare wick"
	if LanternRoute.repaired():
		return "look at the light"
	return "fit wick" if Relationships.has(LanternRoute.SPOOL) else "inspect empty lantern"


func interact() -> String:
	if frame:
		if LanternRoute.named():
			return "1 · 2 · 3 · 4 · RUE. My own handwriting, a little crooked."
		if not LanternRoute.repaired():
			return "Five festival frames. Four labels are numbered, one to four. The fifth label is blank, and the frame is empty."
		return ""  # the question follows (LanternWorkshop.interact_extra)
	if not lamp:
		var kept := LanternRoute.record(LanternRoute.SPOOL, "A spare festival wick", [
			"A coil of wick, still wrapped in paper marked FIFTH LANTERN.",
			"The service lantern on the centre bench has an empty holder. This will fit."])
		Sfx.play("ui_confirm")
		changed.emit()
		queue_redraw()
		return "WICK KEPT  ·  fit it to the service lantern. (journal: Objects)" + _unsaved_note(kept)
	if LanternRoute.repaired():
		return "The light reaches the hatch. A way back that doesn't cross Arin's road."
	if not Relationships.has(LanternRoute.SPOOL):
		return "Cold glass and an empty wick holder. Without it, the hatch beside the well ladder is too dark to find. A spare coil lies on the west workbench."
	var saved := LanternRoute.record(LanternRoute.REPAIRED, "A light kept burning", [
		"I fitted the spare wick. The service light came on, and the hatch under the well opened.",
		"The festival needed two people to hold a light. I kept this one burning myself.",
		"Nobody asked me to. Nobody was holding the controller. It still counts.",
		"The workshop is quiet. Save and exit is available here when no story panel is open."])
	Sfx.play("ui_confirm")
	changed.emit()
	queue_redraw()
	return "SERVICE ROUTE OPEN  ·  hatch to the well; stairs to the Archive." + _unsaved_note(saved)


## Said only when the write failed: the step stands, the game keeps trying.
func _unsaved_note(saved: bool) -> String:
	return "" if saved else "  ·  NOT SAVED YET (the game keeps trying)"


func _draw() -> void:
	if frame:
		# Drawn up on the shelf, in line with the four painted frames.
		draw_rect(Rect2(-4, -36, 8, 13), Color("ba9158"), false, 1)
		draw_line(Vector2(-5, -22), Vector2(5, -22), Color("e3c995"), 1)
		draw_rect(Rect2(-5, -20, 10, 4), Color("e9dcc0"))
		if LanternRoute.named():
			for i in 3:
				draw_line(Vector2(-3 + i * 2.2, -17), Vector2(-2 + i * 2.2, -19), Color("8f6ad6"), 1)
		return
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
