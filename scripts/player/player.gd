class_name Player
extends CharacterBody2D
## You. The thing that isn't supposed to be in this save.
##
## Drawn in colors the world's palette doesn't use, and the renderer never
## quite agrees on where you are.

const BODY := Color("8cf2ff")
const HEAD := Color("d8ffff")
const GHOST := Color(1.0, 0.2, 0.4, 0.22)

@export var speed := 90.0

var frozen := false
## Seconds since the player last moved; the owner watches this.
var idle_time := 0.0

var _jitter := Vector2.ZERO


func _physics_process(delta: float) -> void:
	if frozen:
		velocity = Vector2.ZERO
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * speed
	move_and_slide()
	idle_time = idle_time + delta if dir == Vector2.ZERO else 0.0


func _process(delta: float) -> void:
	_jitter = Vector2(randf_range(-2.0, 2.0), 0.0) if randf() < 3.0 * delta else Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	# Chromatic ghost: a second copy of you, slightly out of sync.
	draw_rect(Rect2(Vector2(-4, -10) - _jitter + Vector2(1, 0), Vector2(8, 16)), GHOST)
	draw_rect(Rect2(Vector2(-4, -5) + _jitter, Vector2(8, 11)), BODY)
	draw_rect(Rect2(Vector2(-3, -10) + _jitter, Vector2(6, 5)), HEAD)
