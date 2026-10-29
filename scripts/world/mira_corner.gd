class_name MiraCorner
extends Node2D
## Mira's corner of Arin's room (docs/production/CHARACTERS.md): a small
## round table with her two cups, and what her story has left on it. Drawn
## only (no collision): she lives here, it isn't in Rue's way.
##
##   before her ask   two cups, one steaming; her note, folded, FOR THE BOARD
##   with you         the cups; the note is gone (she's carrying it)
##   pinned           one cup has moved to the windowsill, where she watches
##   lost             one cup upside down; a blank sheet she never wrote on
##   reset            two clean cups and nothing else: she doesn't know Rue
##   kept (restricted) the owner's selection box drawn round where she stands

## "" (before), "carried", "pinned", "lost" or "reset" (OwnerMemory.mira_quest).
var quest := ""
## The owner has restricted her: drawn as a selection box round `kept_at`.
var kept := false
var kept_at := Vector2.ZERO
## Where the window's sill is (for the cup she moved there).
var sill := Vector2.ZERO

var _t := 0.0

const WOOD := Color("7a5236")
const CUP := Color("e8e0d0")
const CUP_RIM := Color("b8ae9c")
const TEA := Color("8a5a3a")


## Her note is on the table (not yet carried, pinned or lost; and she knows Rue).
func note_on_table() -> bool:
	return quest == ""


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	# The table: a round top seen from above and in front, one leg, its shadow.
	draw_set_transform(Vector2(1.5, 8), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_rect(Rect2(-1.2, 0, 2.4, 8), WOOD.darkened(0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2(0, 1.5), 9.0, WOOD.darkened(0.25))
	draw_circle(Vector2.ZERO, 9.0, WOOD)
	draw_arc(Vector2.ZERO, 9.0, PI * 1.05, PI * 1.95, 12, WOOD.lightened(0.2), 0.8)
	draw_arc(Vector2.ZERO, 5.5, 0.3, 2.2, 8, WOOD.darkened(0.12), 0.5)  # grain
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	match quest:
		"pinned":
			_cup(Vector2(-3, -1), false, true)
			_cup_at(sill, true)  # the other one is at the window with her
		"lost":
			_cup(Vector2(-3.5, -1), false, false)
			_upturned(Vector2(3.5, -0.5))
			# A sheet she never wrote on.
			draw_colored_polygon(PackedVector2Array([Vector2(-1, 1.5), Vector2(5, 0.5), Vector2(6, 3.5), Vector2(0, 4.5)]), Color("efe6d6"))
		"reset":
			_cup(Vector2(-3.5, -1), false, false)
			_cup(Vector2(3.5, -1), false, false)
		_:
			_cup(Vector2(-3.5, -1.5), true, true)
			_cup(Vector2(3.5, -1), false, true)
			if note_on_table():
				_note(Vector2(0, 2.5))
	if kept:
		_selection(kept_at - position)


## A cup from above: saucer, cup, tea, a handle turned her way; steam rising
## from the one she's just poured.
func _cup(at: Vector2, steaming: bool, tea: bool) -> void:
	draw_set_transform(at, 0.0, Vector2(1.0, 0.6))
	draw_circle(Vector2.ZERO, 2.6, CUP_RIM)
	draw_circle(Vector2(0, -0.6), 1.9, CUP)
	if tea:
		draw_circle(Vector2(0, -0.6), 1.3, TEA)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_arc(at + Vector2(2.1, -0.4), 0.8, -PI * 0.5, PI * 0.5, 5, CUP_RIM, 0.6)
	if steaming:
		for k in 2:
			var ph := fmod(_t * 0.7 + k * 0.5, 1.0)
			var p := at + Vector2(sin(_t * 2.0 + k * 2.0) * 1.0, -2.0 - ph * 6.0)
			draw_circle(p, 0.7 + ph * 0.6, Color(1, 1, 1, 0.35 * (1.0 - ph)))


## A cup on the windowsill (in the room's coordinates).
func _cup_at(world_at: Vector2, tea: bool) -> void:
	_cup(world_at - position, false, tea)


func _upturned(at: Vector2) -> void:
	draw_set_transform(at, 0.0, Vector2(1.0, 0.6))
	draw_circle(Vector2.ZERO, 2.4, CUP_RIM.darkened(0.1))
	draw_circle(Vector2.ZERO, 1.2, CUP_RIM.darkened(0.3))  # its foot, upside down
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Her note, folded in four, FOR THE BOARD on the outside in two short lines.
func _note(at: Vector2) -> void:
	var r := Rect2(at + Vector2(-3, -1.5), Vector2(6, 4))
	draw_rect(Rect2(r.position + Vector2(0.5, 0.5), r.size), Color(0, 0, 0, 0.25))
	draw_rect(r, Color("f2ead8"))
	draw_line(r.position + Vector2(0, 2), r.position + Vector2(6, 2), Color("d8ccb4"), 0.4)  # the fold
	draw_line(r.position + Vector2(1, 0.9), r.position + Vector2(4.6, 0.9), Color("7a4a3a"), 0.45)
	draw_line(r.position + Vector2(1, 3.1), r.position + Vector2(3.8, 3.1), Color("7a4a3a"), 0.45)


## The owner's restriction: a dashed selection box with handles, as an
## editor draws round an object, round where she has been kept.
func _selection(at: Vector2) -> void:
	var r := Rect2(at + Vector2(-9, -30), Vector2(18, 33))
	var c := Color(0.55, 0.95, 1.0, 0.35 + 0.15 * sin(_t * 2.0))
	var dash := 3.0
	for side in 4:
		var a: Vector2 = [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)][side]
		var b: Vector2 = [Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position][side]
		var n := int(a.distance_to(b) / (dash * 2.0))
		for i in n:
			var f0 := float(i) / n
			draw_line(a.lerp(b, f0), a.lerp(b, f0 + 0.5 / n), c, 0.6)
	for p in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), c)
