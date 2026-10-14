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
	var fx := get_tree().get_first_node_in_group("screen_fx") as ScreenFx
	if fx:
		fx.deletion_hit()
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
			_draw_deletion(_delete_t)
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


## Deletion, in three beats: the body convulses in split colour, bursts into
## a spray of pixels, and the spray burns out leaving static behind.
func _draw_deletion(t: float) -> void:
	var glitch := Settings.glitch_intensity
	if t < 0.45:
		# Convulsing: RGB-split copies jump around the real body.
		var k := (1.0 + t * 6.0) * glitch
		draw_set_transform(Vector2(randf_range(-2, 2) * k, 0))
		_draw_body(randf() < 0.5)
		draw_set_transform(Vector2(-2 - randf() * 2.0 * k, 0))
		_draw_tinted(Color(1.0, 0.1, 0.4, 0.6))
		draw_set_transform(Vector2(2 + randf() * 2.0 * k, 0))
		_draw_tinted(Color(0.3, 0.9, 1.0, 0.6))
		draw_set_transform(Vector2.ZERO)
		for i in 6:
			if randf() < 0.6:
				draw_rect(Rect2(-8 - randf() * 4.0, -12 + i * 3, 16 + randf() * 8.0, 1), Color(NULL_COL, 0.9))
		return
	# Colour explosion: pixels from the body fly outward and fall.
	var s := t - 0.45
	var fade := 1.0 - clampf(s / 1.1, 0.0, 1.0)
	var palette := [dress_color, skin_color, hair_color, Color(1, 0.15, 0.55), Color(0.4, 0.95, 1.0), Color.WHITE]
	for i in 48:
		var h := fmod(absf(sin(float(i) * 12.9898 + npc_id.length()) * 43758.5453), 1.0)
		var h2 := fmod(absf(sin(float(i) * 78.233) * 12345.678), 1.0)
		var dir := Vector2.from_angle(h * TAU) * (0.3 + h2)
		var p := Vector2(-4 + (i % 8), -12 + floori(i / 8.0) * 3) + dir * 42.0 * s + Vector2(0, 30.0 * s * s)
		draw_rect(Rect2(p, Vector2.ONE * (2 if i % 3 == 0 else 1)), Color(palette[i % palette.size()], fade))
	_draw_residue(1.0 - fade * 0.5)


func _draw_tinted(c: Color) -> void:
	var h := height
	draw_rect(Rect2(-4, 6 - 16 * h, 8, 16 * h + 1), c)


## Static that keeps crawling where someone used to be.
func _draw_residue(strength: float) -> void:
	for i in 3:
		if randf() < 0.5 * strength:
			var p := Vector2(randf_range(-6, 6), randf_range(5 - 17 * height, 6))
			draw_rect(Rect2(p, Vector2(randf_range(1, 3), 1)), [Color(NULL_COL), Color.WHITE, Color(1, 0.15, 0.55)].pick_random())


func _draw_outline() -> void:
	_draw_residue(0.35)
	var c := Color(NULL_COL, 0.35)
	draw_rect(Rect2(-4, 5 - 17 * height, 8, 17 * height), c, false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-34, 16), "%s.npc = null" % npc_id, HORIZONTAL_ALIGNMENT_CENTER, 68, 7, c)
