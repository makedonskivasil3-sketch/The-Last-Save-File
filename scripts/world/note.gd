class_name Note
extends Node2D
## A note pinned to the wall by the owner, for their character.
## The owner edits it. Never while you're looking.

const PAPER := Color("e6d6b0")
const INK := Color("e6d6b0")
const REWRITE_DISTANCE := 110.0

var text := ""
var title := "NOTE"
var player: Node2D

## Rue's FALSIFY glitch made it lie (once per note per session).
var falsified := false
## What it says when falsified.
var lie := "ALL CLEAR.\nNOTHING TO SEE HERE."
## What it said before it lied (a reload puts it back).
var _truth := ""

var _label: Label
var _pending := ""
var _smudge := 0.0


func _ready() -> void:
	_label = Label.new()
	_label.position = Vector2(-60, 6)
	_label.size = Vector2(120, 30)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", Color(INK, 0.75))
	add_child(_label)
	_label.text = text


func set_text_now(value: String) -> void:
	text = value
	_pending = ""
	if _label:
		_label.text = value


## FALSIFY: the note lies, right now, in front of you.
func falsify() -> void:
	_truth = text
	falsified = true
	set_text_now(lie)
	_smudge = 0.8


## The owner reloads: the note says what it said before.
func unfalsify() -> void:
	if falsified:
		falsified = false
		set_text_now(_truth)
		_smudge = 0.8


## Queue a rewrite. It only lands once the player is far enough away.
func rewrite(value: String) -> void:
	if falsified:
		return  # the owner already believes the lie
	_pending = value


func can_interact() -> bool:
	return true


func interact_prompt() -> String:
	return "read note"


func interact() -> Dictionary:
	return {"speaker": title, "color": INK, "lines": [text.replace("\n", " ")]}


func _process(delta: float) -> void:
	_smudge = maxf(0.0, _smudge - delta)
	if _pending != "" and is_instance_valid(player):
		if player.global_position.distance_to(global_position) > REWRITE_DISTANCE:
			set_text_now(_pending)
			_smudge = 1.2
			Sfx.play("scribble")  # behind your back
	if _label:
		_label.modulate.a = 1.0 if _smudge <= 0.0 or randf() > 0.5 else 0.2
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-7, -5, 14, 9), PAPER)
	for i in 3:
		draw_line(Vector2(-5, -3 + i * 2.5), Vector2(4 - i, -3 + i * 2.5), Color(0.3, 0.2, 0.15, 0.7))
	if _smudge > 0.0:
		draw_rect(Rect2(-7, -5, 14, 9), Color(0.88, 0.44, 0.31, _smudge * 0.5))
