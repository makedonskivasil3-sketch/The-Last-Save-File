class_name Npc
extends StaticBody2D
## Mira. One of the owner's characters. She notices you before they do.

enum State { NORMAL, RESTRICTED, DELETING, DELETED }

const DRESS := Color("c9733e")
const SKIN := Color("e8c48a")
const HAIR := Color("5a3420")
const NULL_COL := Color("e0704f")

const NORMAL_LINES := [
	"Arin! You're up early.",
	"...Arin? Your colors look wrong.",
	"You're not Arin. Who are you?",
	"They're going to notice you. They notice everything.",
]
const RESTRICTED_LINES := [
	"I'm not allowed to talk to you anymore.",
	"Please go away. They're reading this.",
	"...",
]

var state: State = State.NORMAL
var display_name := "MIRA"
var dress_color := DRESS
var hair_color := HAIR
var deleted_in_session := 0
var player: Node2D

var _line := 0
var _delete_t := 0.0
var _col: CollisionShape2D


func setup(initial: State, session_deleted: int = 0) -> void:
	state = initial
	deleted_in_session = session_deleted
	var shape := RectangleShape2D.new()
	shape.size = Vector2(8, 8)
	_col = CollisionShape2D.new()
	_col.shape = shape
	_col.position = Vector2(0, 2)
	add_child(_col)
	_col.disabled = state == State.DELETED


## The owner removes her. Returns false if there's nothing left to remove.
func delete() -> bool:
	if state == State.DELETING or state == State.DELETED:
		return false
	state = State.DELETING
	_delete_t = 0.0
	return true


func can_interact() -> bool:
	return state == State.NORMAL or state == State.RESTRICTED


func interact_prompt() -> String:
	return "talk"


func interact() -> String:
	var lines: Array = NORMAL_LINES if state == State.NORMAL else RESTRICTED_LINES
	var line: String = lines[mini(_line, lines.size() - 1)]
	_line += 1
	return line


func _process(delta: float) -> void:
	if state == State.DELETING:
		_delete_t += delta
		if _delete_t > 1.6:
			state = State.DELETED
			_col.set_deferred("disabled", true)
	queue_redraw()


func _draw() -> void:
	match state:
		State.NORMAL, State.RESTRICTED:
			_draw_body(1.0, state == State.RESTRICTED)
		State.DELETING:
			# Flickers between her and nothing, sliced into scanlines.
			if randf() < 1.0 - _delete_t / 1.6:
				_draw_body(1.0, true)
			for i in 6:
				if randf() < 0.5:
					draw_rect(Rect2(-6, -10 + i * 3, 12, 1), Color(NULL_COL, 0.8))
		State.DELETED:
			_draw_outline()


func _draw_body(alpha: float, desaturated: bool) -> void:
	var dress := dress_color if not desaturated else Color(0.45, 0.42, 0.4)
	var skin := SKIN if not desaturated else Color(0.6, 0.58, 0.55)
	draw_rect(Rect2(-4, -5, 8, 11), Color(dress, alpha))
	draw_rect(Rect2(-3, -10, 6, 5), Color(skin, alpha))
	draw_rect(Rect2(-4, -11, 8, 2), Color(hair_color, alpha))
	# Eyes follow you.
	var look := Vector2.ZERO
	if is_instance_valid(player):
		look = (player.global_position - global_position).normalized()
	var eye_off := Vector2(roundf(look.x), clampf(roundf(look.y), 0.0, 1.0))
	draw_rect(Rect2(Vector2(-2, -8) + eye_off, Vector2(1, 1)), Color(0.1, 0.05, 0.05))
	draw_rect(Rect2(Vector2(1, -8) + eye_off, Vector2(1, 1)), Color(0.1, 0.05, 0.05))


func _draw_outline() -> void:
	var c := Color(NULL_COL, 0.35)
	draw_rect(Rect2(-4, -11, 8, 17), c, false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-30, 16), "mira.npc = null", HORIZONTAL_ALIGNMENT_CENTER, 60, 7, c)
