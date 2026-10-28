class_name AnchorMark
extends Node2D
## Under the well, on the landing beside the pillar: where Rue can choose to
## keep her place (the checkpoint, docs/NARRATIVE_CONTRACT.md §5). It is
## offered once the well has played her the tune down here: this is where
## she climbed back in the first time she fell out of the world. Choosing it
## is explicit; nothing sets it behind her back.

signal kept(mark: AnchorMark)

## Set by the area: whether it can be chosen now, and whether it already is.
var offered := false
var is_kept := false

var _t := 0.0


func can_interact() -> bool:
	return offered


func interact_prompt() -> String:
	return "your place (kept)" if is_kept else "keep my place here"


## What this is, shown small over the prompt (World.object_name).
func interact_name() -> String:
	return "under the well"


func interact() -> String:
	kept.emit(self)
	return ""


func _process(delta: float) -> void:
	_t += delta
	if offered:
		queue_redraw()


func _draw() -> void:
	if not offered:
		return
	# A small ring scratched into the debug floor, the way you'd mark where
	# you left something; it glows warm once it's hers.
	var pulse := 0.5 + 0.5 * sin(_t * 2.2)
	var col := Color(1.0, 0.82, 0.5, 0.55 + 0.3 * pulse) if is_kept else Color(0.8, 0.95, 1.0, 0.25 + 0.2 * pulse)
	draw_arc(Vector2.ZERO, 6.0, 0.0, TAU, 16, col, 1.0)
	draw_line(Vector2(-2, 0), Vector2(2, 0), col, 1.0)
	draw_line(Vector2(0, -2), Vector2(0, 2), col, 1.0)
