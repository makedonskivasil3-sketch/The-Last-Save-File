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
## Darker clothes / trousers and accent colours for the sprite.
var dark_color := Color("6b3a24")
var accent_color := Color("e8c48a")
## Sprite template: "adult", "dress", "apron", "child", "robe".
var body_kind := "adult"
## "", "sway", "hop", "wave", "read" (see PixelCharacter).
var idle_style := ""
## Emote shown the first time you come close ("!", "?", "...").
var notice_emote := ""
## Set by World while you're talking to them.
var talking := false
## Never moves their mouth (the real Arin only says "...").
var mute := false
## Their own colours, kept the first time a piece is taken from the drawing.
var _unfrayed: Dictionary = {}
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
var _sprite: PixelCharacter
var _emote := ""
var _emote_t := 0.0
var _noticed := false
## Seconds left frozen by Rue's FREEZE glitch.
var frozen := 0.0
## Escorted: walking behind Rue along her footsteps (World.escort).
var escorted := false
## Hurrying to catch up (a little faster than Rue walks).
const ESCORT_CATCH_UP := 96.0
const ESCORT_SPEED := 60.0
var _walk_velocity := Vector2.ZERO


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
	Sfx.deletion(npc_id)
	return true


## Escort: walk along Rue's footsteps (`crumbs`, oldest first; reached ones
## are removed), stopping a little behind her.
func follow(crumbs: Array[Vector2], leader: Vector2, delta: float) -> void:
	_walk_velocity = Vector2.ZERO
	if frozen > 0.0 or not is_present():
		return
	# Beside the leader: stand, and forget the steps taken meanwhile (else she
	# would later walk back over every fidget).
	if global_position.distance_to(leader) < 16.0:
		crumbs.clear()
		return
	# Skip ahead to the trail point nearest her (never across it).
	var nearest := 0
	for i in mini(crumbs.size(), 24):
		if global_position.distance_to(crumbs[i]) < global_position.distance_to(crumbs[nearest]):
			nearest = i
	for i in nearest:
		crumbs.pop_front()
	while not crumbs.is_empty() and global_position.distance_to(crumbs[0]) < 3.0:
		crumbs.pop_front()
	if crumbs.is_empty():
		return
	# Her own pace close by; she hurries when she falls behind, so doors
	# don't wait on her (Rue walks at 90).
	var behind := global_position.distance_to(leader)
	var speed := lerpf(ESCORT_SPEED, ESCORT_CATCH_UP, clampf((behind - 24.0) / 30.0, 0.0, 1.0))
	var to := crumbs[0] - global_position
	var step := to.normalized() * minf(speed * delta, to.length())
	global_position += step
	_walk_velocity = step / maxf(delta, 0.0001)


## FREEZE: they stop mid-motion for a moment.
func freeze(seconds: float) -> void:
	frozen = maxf(frozen, seconds)


## RESTORE: undo a deletion. Back as they were, a little glitchy.
func restore() -> bool:
	if state != State.DELETED and state != State.DELETING:
		return false
	state = State.NORMAL
	_col.set_deferred("disabled", false)
	_noticed = false
	frozen = 0.6
	return true


func is_present() -> bool:
	return state == State.NORMAL or state == State.RESTRICTED


## A little speech bubble over their head.
func emote(text: String, duration: float = 1.6) -> void:
	_emote = text
	_emote_t = duration
	Sfx.play("pop", 0.0, 1.0 + randf() * 0.2)


func _enter_tree() -> void:
	add_to_group("canopy_reveal")


func sprite() -> PixelCharacter:
	if _sprite == null:
		_apply_fray()
		_sprite = IllustratedCharacter.new(body_kind, {
			"h": hair_color, "s": skin_color, "c": dress_color, "d": dark_color,
			"a": accent_color, "w": Color("d8d0c0"), "l": dark_color.darkened(0.3),
		})
		_sprite.idle_style = idle_style
	return _sprite


## Rue took this one's piece (docs/DARK_TRUTH_DESIGN.md): Wren's ribbon,
## Mira's colour, Tobben's voice.
func is_frayed() -> bool:
	return npc_id in OwnerMemory.frayed


func _apply_fray() -> void:
	if _unfrayed.is_empty():
		_unfrayed = {"accent_color": accent_color, "dress_color": dress_color, "dark_color": dark_color, "mute": mute}
	for k in _unfrayed:
		set(k, _unfrayed[k])
	if not is_frayed():
		return
	match npc_id:
		"wren":
			accent_color = hair_color  # no ribbon
		"mira":
			dress_color = Color("8a8a8a")
			dark_color = Color("5a5a5a")
		"tobben":
			mute = true


## Taken (or given back) just now: redraw from the right colours.
func refresh_fray() -> void:
	_sprite = null
	queue_redraw()


func hides(pos: Vector2) -> bool:
	return hide_radius > 0.0 and is_present() and pos.distance_to(global_position) < hide_radius


func can_interact() -> bool:
	return is_present() and lines_provider.is_valid()


func interact_prompt() -> String:
	return "talk"


func interact() -> Dictionary:
	var lines: Array = lines_provider.call()
	# A piece Rue took (or gave back): said once a session, before anything.
	if state != State.DELETED:
		if npc_id in OwnerMemory.returned_pending and Story.FRAY_RETURNED.has(npc_id):
			OwnerMemory.returned_pending.erase(npc_id)
			OwnerMemory.save_memory()
			lines = [Story.FRAY_RETURNED[npc_id]] + lines
		elif is_frayed() and "fray:" + npc_id not in OwnerMemory.session_recalled:
			OwnerMemory.session_recalled.append("fray:" + npc_id)  # once a session, not once a visit
			lines = [Story.FRAY_LINES[npc_id] if npc_id in OwnerMemory.session_frayed else Story.FRAY_RECALL[npc_id]] + lines
	# What they've noticed about what Rue is, once it's time (said once ever),
	# goes before their usual lines...
	# (Counted when the line is actually shown: World._on_line_shown.)
	var truth := Story.truth_line(npc_id) if state != State.DELETED else ""
	if truth != "":
		lines = [truth] + lines
	# ...and the first time you talk this session, anything they remember
	# from your last runs comes first of all.
	if state != State.DELETED and npc_id not in OwnerMemory.session_recalled:
		OwnerMemory.session_recalled.append(npc_id)
		var memory := Story.recall(npc_id)
		if memory != "":
			lines = [memory] + lines
	if on_talk.is_valid():
		on_talk.call()
	return {"speaker": Story.TOBBEN_WRITTEN if npc_id == "tobben" and is_frayed() else display_name, "color": name_color, "lines": lines}


func _process(delta: float) -> void:
	var s := sprite()
	if frozen > 0.0:
		frozen -= delta
		queue_redraw()
		return
	# Conversation gaze owns facing while speaking; locomotion still owns
	# gait, but cannot flip away and restart the same turn every frame.
	s.update(delta, _walk_velocity, not talking)
	s.talking = talking and not mute
	s.idle_style = "" if state == State.RESTRICTED or talking else idle_style
	_emote_t = maxf(0.0, _emote_t - delta)
	if is_present() and is_instance_valid(player):
		var d := player.global_position.distance_to(global_position)
		# They turn to watch you when you're close.
		if talking or (d < 90.0 and not (escorted and s.moving)):
			s.look_at(global_position, player.global_position)
		elif not talking and not (escorted and s.moving):
			s.facing = Vector2.DOWN
		if d < 50.0 and not _noticed and notice_emote != "":
			_noticed = true
			emote(notice_emote)
		s.waving = idle_style == "wave" and d < 70.0 and not talking
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
			if frozen > 0.0:
				var k := 2.0 * Settings.glitch_intensity
				_draw_tinted(Color(1.0, 0.15, 0.5, 0.5), Vector2(-k, 0))
				_draw_tinted(Color(0.3, 0.95, 1.0, 0.5), Vector2(k, 0))
			_draw_body(state == State.RESTRICTED or frozen > 0.0)
		State.DELETING:
			_draw_deletion(_delete_t)
		State.DELETED:
			_draw_outline()


func _draw_body(desaturated: bool) -> void:
	sprite().draw(self, {"grey": desaturated})
	if _emote_t > 0.0 and state != State.DELETING:
		_draw_emote()


## Pops in, bobs, fades: a white bubble with a dark glyph.
func _draw_emote() -> void:
	var top := float(PixelCharacter.FEET_Y - sprite().height())
	var pop := clampf((1.6 - _emote_t) * 8.0, 0.0, 1.0)
	var y := top - 9.0 - pop * 2.0 + sin(_emote_t * 6.0)
	var w := 4.0 + _emote.length() * 4.0
	var a := clampf(_emote_t * 3.0, 0.0, 1.0)
	draw_rect(Rect2(-w / 2.0, y, w, 9), Color(0.95, 0.93, 0.88, a))
	draw_rect(Rect2(-1, y + 9, 2, 2), Color(0.95, 0.93, 0.88, a))
	draw_string(ThemeDB.fallback_font, Vector2(-w / 2.0 + 2, y + 7.5), _emote, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.1, 0.06, 0.08, a))


## Deletion, in three beats: the body convulses in split colour, bursts into
## a spray of pixels, and the spray burns out leaving static behind.
func _draw_deletion(t: float) -> void:
	var glitch := Settings.glitch_intensity
	if t < 0.45:
		# Convulsing: RGB-split copies jump around the real body.
		var k := (1.0 + t * 6.0) * glitch
		sprite().draw(self, {"offset": Vector2(randf_range(-2, 2) * k, 0), "grey": randf() < 0.5})
		_draw_tinted(Color(1.0, 0.1, 0.4, 0.6), Vector2(-2 - randf() * 2.0 * k, 0))
		_draw_tinted(Color(0.3, 0.9, 1.0, 0.6), Vector2(2 + randf() * 2.0 * k, 0))
		for i in 6:
			if randf() < 0.6:
				draw_rect(Rect2(-12 - randf() * 4.0, PixelCharacter.FEET_Y - sprite().height() + i * 4, 24 + randf() * 8.0, 1), Color(NULL_COL, 0.9))
		return
	# Colour explosion: pixels from the body fly outward and fall.
	var s := t - 0.45
	var fade := 1.0 - clampf(s / 1.1, 0.0, 1.0)
	var palette := [dress_color, skin_color, hair_color, Color(1, 0.15, 0.55), Color(0.4, 0.95, 1.0), Color.WHITE]
	for i in 48:
		var h := fmod(absf(sin(float(i) * 12.9898 + npc_id.length()) * 43758.5453), 1.0)
		var h2 := fmod(absf(sin(float(i) * 78.233) * 12345.678), 1.0)
		var dir := Vector2.from_angle(h * TAU) * (0.3 + h2)
		var p := Vector2(-8 + (i % 8) * 2, PixelCharacter.FEET_Y - sprite().height() + floori(i / 8.0) * 4) + dir * 48.0 * s + Vector2(0, 30.0 * s * s)
		draw_rect(Rect2(p, Vector2.ONE * (2 if i % 3 == 0 else 1)), Color(palette[i % palette.size()], fade))
	_draw_residue(1.0 - fade * 0.5)


func _draw_tinted(c: Color, offset: Vector2 = Vector2.ZERO) -> void:
	sprite().draw(self, {"solid": c, "offset": offset})


## Static that keeps crawling where someone used to be.
func _draw_residue(strength: float) -> void:
	for i in 3:
		if randf() < 0.5 * strength:
			var p := Vector2(randf_range(-10, 10), randf_range(PixelCharacter.FEET_Y - sprite().height(), 6))
			draw_rect(Rect2(p, Vector2(randf_range(1, 3), 1)), [Color(NULL_COL), Color.WHITE, Color(1, 0.15, 0.55)].pick_random())


func _draw_outline() -> void:
	_draw_residue(0.35)
	var c := Color(NULL_COL, 0.35)
	draw_rect(Rect2(-8, PixelCharacter.FEET_Y - sprite().height(), 16, sprite().height()), c, false, 1.0)
	draw_string(UiStyle.system_font(), Vector2(-34, 16), "%s.npc = null" % npc_id, HORIZONTAL_ALIGNMENT_CENTER, 68, 7, c)
