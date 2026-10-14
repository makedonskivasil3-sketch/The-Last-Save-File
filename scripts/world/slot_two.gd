class_name SlotTwo
extends Area2D
## An empty save slot the owner forgot about. The last save file.
##
## Touching it isn't enough: you have to stand in it while you write yourself
## in (WRITE_TIME seconds), and the owner's cursor selects anything that holds
## still. Lure it away first. Stepping out keeps part of your progress.

signal reached

## Seconds of standing in the slot to write yourself in. Longer than the
## cursor's select time (1.1 s), so you need a head start on it.
const WRITE_TIME := 2.4
## Progress drains at this fraction of the writing speed while you're out.
const DRAIN := 0.5

## 0..1 written.
var progress := 0.0

var _t := 0.0
var _done := false
var _tick := 0.0


func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 9.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _physics_process(delta: float) -> void:
	if _done:
		return
	var inside := false
	for body in get_overlapping_bodies():
		if body is Player:
			inside = true
	if inside:
		progress = minf(1.0, progress + delta / WRITE_TIME)
		# The sound of you typing yourself into the save.
		_tick -= delta
		if _tick <= 0.0:
			_tick = 0.09
			Sfx.type_key("self")
	else:
		progress = maxf(0.0, progress - delta / WRITE_TIME * DRAIN)
	if progress >= 1.0:
		_done = true
		reached.emit()


func is_writing() -> bool:
	return progress > 0.0 and not _done


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var bob := sin(_t * 2.0) * 2.0
	for i in 3:
		draw_circle(Vector2(0, bob), 10.0 + i * 6.0 + sin(_t * 3.0 + i) * 2.0, Color(0.55, 0.95, 1.0, 0.06))
	draw_rect(Rect2(Vector2(-7, -9 + bob), Vector2(14, 18)), Color("0c1a1f"))
	draw_rect(Rect2(Vector2(-7, -9 + bob), Vector2(14, 18)), Color("8cf2ff"), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-6, 3 + bob), "02", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("8cf2ff"))
	if progress > 0.0:
		# Writing yourself in: the slot fills, and says so.
		draw_rect(Rect2(Vector2(-7, 9 + bob - 18 * progress), Vector2(14, 18 * progress)), Color("8cf2ff", 0.35))
		draw_rect(Rect2(-16, 14, 32, 3), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-16, 14, 32 * progress, 3), Color("8cf2ff"))
		draw_string(ThemeDB.fallback_font, Vector2(-40, 26), "WRITING SLOT 2 · %d%%" % int(progress * 100.0),
				HORIZONTAL_ALIGNMENT_CENTER, 80, 7, Color("e8ffff"))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(-30, 24), "SLOT 2 · EMPTY", HORIZONTAL_ALIGNMENT_CENTER, 60, 7, Color("8cf2ff", 0.7))
