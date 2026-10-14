class_name Npc
extends StaticBody2D
## A character in the owner's save. Look, name and dialogue are configured by
## the area that places them; `lines_provider` decides what they say each time
## you talk, so lines can depend on the session, OwnerMemory, or world flags.

enum State { NORMAL, RESTRICTED, DELETING, DELETED }

const NULL_COL := Color("e0704f")

var state: State = State.NORMAL
## Internal id, used for OwnerMemory fates ("mira", "wren", ...).
var npc_id := "npc"
var display_name := "NPC"
var name_color := Color("e8c48a")
var dress_color := Color("c9733e")
var hair_color := Color("5a3420")
var skin_color := Color("e8c48a")
## 0.6 = child, 1.0 = adult, 1.15 = tall.
var height := 1.0
var player: Node2D
## Returns Array[String]: the lines for this conversation.
var lines_provider: Callable
## Called after a conversation opens (e.g. to set flags or warn the owner).
var on_talk: Callable
var awareness_cost := 0.0
## Stand this close to them and the owner can't see you.
var hide_radius := 0.0

var _delete_t := 0.0
var _col: CollisionShape2D


func setup(initial: State) -> void:
	state = initial
	var shape := RectangleShape2D.new()
	shape.size = Vector2(8, 8)
	_col = CollisionShape2D.new()
	_col.shape = shape
	_col.position = Vector2(0, 2)
	add_child(_col)
	_col.disabled = state == State.DELETED


## The owner removes them. Returns false if there's nothing left to remove.
func delete() -> bool:
	if state == State.DELETING or state == State.DELETED:
		return false
	state = State.DELETING
	_delete_t = 0.0
	return true


func is_present() -> bool:
	return state == State.NORMAL or state == State.RESTRICTED


func hides(pos: Vector2) -> bool:
	return hide_radius > 0.0 and is_present() and pos.distance_to(global_position) < hide_radius


func can_interact() -> bool:
	return is_present() and lines_provider.is_valid()


func interact_prompt() -> String:
	return "talk"


func interact() -> Dictionary:
	var lines: Array = lines_provider.call()
	if on_talk.is_valid():
		on_talk.call()
	return {"speaker": display_name, "color": name_color, "lines": lines}


func _process(delta: float) -> void:
	if state == State.DELETING:
		_delete_t += delta
		if _delete_t > 1.6:
			state = State.DELETED
			_col.set_deferred("disabled", true)
	queue_redraw()


func _draw() -> void:
	if hide_radius > 0.0 and is_present():
		draw_circle(Vector2(0, 4), hide_radius, Color(0.55, 0.95, 1.0, 0.05))
	match state:
		State.NORMAL, State.RESTRICTED:
			_draw_body(state == State.RESTRICTED)
		State.DELETING:
			# Flickers between them and nothing, sliced into scanlines.
			if randf() < 1.0 - _delete_t / 1.6:
				_draw_body(true)
			for i in 6:
				if randf() < 0.5:
					draw_rect(Rect2(-6, -10 + i * 3, 12, 1), Color(NULL_COL, 0.8))
		State.DELETED:
			_draw_outline()


func _draw_body(desaturated: bool) -> void:
	var grey := Color(0.45, 0.42, 0.4)
	var dress := grey if desaturated else dress_color
	var skin := Color(0.6, 0.58, 0.55) if desaturated else skin_color
	var h := height
	draw_rect(Rect2(-4, 6 - 11 * h, 8, 11 * h), dress)
	draw_rect(Rect2(-3, 6 - 16 * h, 6, 5), skin)
	draw_rect(Rect2(-4, 5 - 17 * h, 8, 2), hair_color)
	# Eyes follow you.
	var look := Vector2.ZERO
	if is_instance_valid(player):
		look = (player.global_position - global_position).normalized()
	var eye := Vector2(roundf(look.x), clampf(roundf(look.y), 0.0, 1.0)) + Vector2(0, 8 - 16 * h)
	draw_rect(Rect2(Vector2(-2, 0) + eye, Vector2(1, 1)), Color(0.1, 0.05, 0.05))
	draw_rect(Rect2(Vector2(1, 0) + eye, Vector2(1, 1)), Color(0.1, 0.05, 0.05))


func _draw_outline() -> void:
	var c := Color(NULL_COL, 0.35)
	draw_rect(Rect2(-4, 5 - 17 * height, 8, 17 * height), c, false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-34, 16), "%s.npc = null" % npc_id, HORIZONTAL_ALIGNMENT_CENTER, 68, 7, c)
