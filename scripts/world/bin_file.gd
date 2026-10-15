class_name BinFile
extends Node2D
## A deleted character in the Recycle Bin: a greyed-out file with their
## silhouette. Press interact to start restoring it, then stay beside it
## while the bar fills (stepping away pauses it). The Bin empties on a
## timer, so a restore has to fit between sweeps, or you shelter mid-way.

signal restored(npc_id: String)

const RESTORE_TIME := 3.5
const RANGE := 26.0

var npc_id := ""
var tint := Color("8a8f98")
var player: Node2D
## 0..1; < 0 until you start it.
var progress := -1.0
var done := false

var _t := 0.0
var _tick := 0.0


func can_interact() -> bool:
	return not done and progress < 0.0


func interact_prompt() -> String:
	return "restore %s.npc" % npc_id


func interact() -> String:
	progress = 0.0
	Sfx.play("glitch_charge", -8.0, 0.7)
	return "RESTORING %s.npc . . . stay close" % npc_id


func is_restoring() -> bool:
	return progress >= 0.0 and not done


func _process(delta: float) -> void:
	_t += delta
	if is_restoring() and is_instance_valid(player) and player.global_position.distance_to(global_position) <= RANGE:
		progress = minf(1.0, progress + delta / RESTORE_TIME)
		_tick -= delta
		if _tick <= 0.0:
			_tick = 0.12
			Sfx.type_key("self")
		if progress >= 1.0:
			done = true
			Sfx.play("glitch_learn", -4.0, 1.2)
			GlitchBurst.at(get_parent(), global_position, Vector2(26, 34), 0.5)
			restored.emit(npc_id)
	queue_redraw()


func _draw() -> void:
	if done:
		# Back where they belong: only an empty outline left here.
		draw_rect(Rect2(-7, -9, 14, 18), Color(1, 1, 1, 0.12), false, 1.0)
		return
	var bob := sin(_t * 1.6) * 1.0
	# Their silhouette, greyed out and flickering.
	var ghost := Color(tint, 0.35 + 0.1 * sin(_t * 7.0))
	draw_circle(Vector2(0, -22 + bob), 4.0, ghost)
	draw_rect(Rect2(-4, -18 + bob, 8, 10), ghost)
	# The file icon: a page with a folded corner.
	draw_colored_polygon(PackedVector2Array([Vector2(-7, -9), Vector2(3, -9), Vector2(7, -5), Vector2(7, 9), Vector2(-7, 9)]), Color("2a2a32"))
	draw_polyline(PackedVector2Array([Vector2(-7, -9), Vector2(3, -9), Vector2(7, -5), Vector2(7, 9), Vector2(-7, 9), Vector2(-7, -9)]), Color("8a8f98"), 1.0)
	draw_line(Vector2(3, -9), Vector2(3, -5), Color("8a8f98"), 1.0)
	draw_line(Vector2(3, -5), Vector2(7, -5), Color("8a8f98"), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-30, 20), "%s.npc" % npc_id, HORIZONTAL_ALIGNMENT_CENTER, 60, 7, Color("8a8f98"))
	if progress >= 0.0:
		draw_rect(Rect2(-16, 24, 32, 3), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-16, 24, 32 * progress, 3), Color("8cf2ff"))
		draw_arc(Vector2.ZERO, RANGE, 0.0, TAU, 32, Color("8cf2ff", 0.15), 1.0)
