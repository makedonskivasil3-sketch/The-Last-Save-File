class_name Opening
extends Node2D
## The opening (about 28 s, in-engine, before the first run): a two-player
## session on someone's television, late at night. Player 2's controller is
## unplugged, a save of slot 2 starts and never finishes, the screen's
## interface goes out one piece at a time, and one small figure is left
## standing. A single note, and she looks up. Then the room.
##
## It shows a situation, not the truth (docs/DARK_TRUTH_DESIGN.md): nothing
## says who Rue is, who played her, or what the owner did. No run starts
## until it ends: quitting here costs nothing.
##
## Hold interact (or Esc, or touch and hold) to skip. Replay it from the
## title. Reduced flashing / zero glitch intensity: no camera push, no flicker.

signal finished

const GAME_SCENE := "res://scenes/main.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"
const LENGTH := 28.0
const SKIP_HOLD := 0.7
## The television, centred on the 640×360 canvas.
const TV := Rect2(150, 62, 340, 220)
const FLOOR_Y := 222.0
## The figures on the television, large enough to read a posture.
const FIGURE := 1.35

## Back to the title afterwards (a replay) instead of into the game.
var replay := false

var _t := 0.0
var _held := false
var _skip_t := 0.0
var _hint_t := 0.0
var _done := false
var _cues := {}
var _arin := IllustratedCharacter.new("adult", {
	"h": OwnerAvatar.HAIR, "s": OwnerAvatar.SKIN, "c": OwnerAvatar.BODY, "d": Color("2e3f5c"), "a": Color("c0392b"),
	"l": Color("2e3f5c"), "f": Color("1a1a20"), "e": Color("101018"),
})
var _rue := IllustratedCharacter.new("rue", Player.RUE)
var _arin_x := 0.0
var _rue_x := 0.0
var _caption: Label
var _hint: Label


## Plays the opening on the next run? (First launch only, unless asked to
## replay; ?intro=on / ?intro=off in the address forces it, for playtests.)
static func wanted() -> bool:
	var forced := _url_choice()
	if forced != "":
		return forced == "on"
	return not Settings.opening_seen and OwnerMemory.sessions == 0


static func _url_choice() -> String:
	if not OS.has_feature("web"):
		return ""
	var q := str(JavaScriptBridge.eval("window.location.search", true))
	if q.contains("intro=off"):
		return "off"
	if q.contains("intro=on"):
		return "on"
	return ""


static func calm() -> bool:
	return Settings.reduce_flashing or Settings.glitch_intensity <= 0.01


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Sfx.reset_scene_state()
	WebState.publish({"scene": "opening", "playable": false})
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	_caption = _label(layer, Vector2(40, 316), 10, Color(0.85, 0.85, 0.82))
	_hint = _label(layer, Vector2(40, 340), 9, Color(0.6, 0.62, 0.66))
	_hint.modulate.a = 0.0
	_arin_x = TV.position.x + 120.0
	_rue_x = TV.position.x + 92.0


func _label(layer: CanvasLayer, pos: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(560, 16)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.sized(l, size)
	UiStyle.outline(l, 2)
	l.add_theme_color_override("font_color", color)
	layer.add_child(l)
	return l


func _notification(what: int) -> void:
	# Looking away holds the film where it is.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_held = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_held = false


func _process(delta: float) -> void:
	if _done:
		return
	_update_skip(delta)
	if _done or _held:
		return
	_t += delta
	_cue(0.4, func() -> void: _caption.text = "[a television, late at night]")
	_cue(4.5, func() -> void: _caption.text = "")
	_cue(9.0, func() -> void:
		Sfx.play("denied", -6.0, 0.8, 0.0)
		_caption.text = "[a controller is unplugged]")
	_cue(12.0, func() -> void:
		_caption.text = ""
		Sfx.play("key_system", -4.0, 0.8, 0.0))
	_cue(16.0, func() -> void: Sfx.play("click", -10.0, 0.6, 0.0))
	_cue(23.0, func() -> void:
		Sfx.play("fragment", -8.0, 0.75, 0.0)
		_caption.text = "[one note, from a music box]")
	_cue(26.0, func() -> void: _caption.text = "")
	# The two of them walk together until Player 2 is gone; then only Arin.
	var rue_walks := _t > 2.5 and _t < 9.0
	var arin_walks := _t > 2.5 and _t < 11.0
	if rue_walks:
		_rue_x += 11.0 * delta
	if arin_walks:
		_arin_x += 11.0 * delta
	_rue.update(delta, Vector2(11, 0) if rue_walks else Vector2.ZERO)
	_arin.update(delta, Vector2(11, 0) if arin_walks else Vector2.ZERO)
	if _t > 11.6 and _t < 19.0:
		_arin.look_at(Vector2.ZERO, Vector2.LEFT)  # looks back at where she stopped
	if _t > 21.0:
		# Left standing, she isn't quite as she was.
		_rue.palette = _lerp_palette(Player.RUE, Player.MISSING, clampf((_t - 21.0) / 2.5, 0.0, 1.0))
	if _t > 23.2:
		_rue.look_at(Vector2.ZERO, Vector2.DOWN)  # at you
	queue_redraw()
	if _t >= LENGTH:
		_finish()


func _cue(at: float, what: Callable) -> void:
	if _t >= at and not _cues.has(at):
		_cues[at] = true
		what.call()


static func _lerp_palette(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	var out := {}
	for key in a:
		out[key] = (a[key] as Color).lerp(b.get(key, a[key]), k)
	return out


## Any press shows how to skip; holding it skips.
func _update_skip(delta: float) -> void:
	var held := Input.is_action_pressed("interact") or Input.is_action_pressed("confirm") \
		or Input.is_action_pressed("ui_cancel") or Input.is_action_pressed("pause") \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if held:
		_hint_t = 3.0
		_skip_t += delta
		if _skip_t >= SKIP_HOLD:
			_finish()
			return
	else:
		_skip_t = maxf(0.0, _skip_t - delta * 2.0)
		_hint_t = maxf(0.0, _hint_t - delta)
	var how := "touch and hold" if Settings.using_touch else "hold %s" % Settings.glyph("interact")
	_hint.text = "%s to skip  %s" % [how, "▮".repeat(int(_skip_t / SKIP_HOLD * 6.0))]
	_hint.modulate.a = move_toward(_hint.modulate.a, 1.0 if _hint_t > 0.0 else 0.0, delta * 4.0)


func _finish() -> void:
	if _done:
		return
	_done = true
	Settings.set_value("opening_seen", true)
	finished.emit()
	if is_inside_tree():
		get_tree().change_scene_to_file.call_deferred(TITLE_SCENE if replay else GAME_SCENE)


## 0..1: how far into the film (for tests and the storyboard).
func progress() -> float:
	return clampf(_t / LENGTH, 0.0, 1.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color.BLACK)
	var fade_in := clampf(_t / 2.5, 0.0, 1.0)
	var fade_out := 1.0 - clampf((_t - 26.0) / 2.0, 0.0, 1.0)
	var room_light := 1.0 - clampf((_t - 19.0) / 2.5, 0.0, 1.0)
	# The push in on her at the end (not with reduced motion).
	var push := 1.0 if calm() else 1.0 + 0.6 * smoothstep(24.0, 27.5, _t)
	var focus := Vector2(_rue_x, FLOOR_Y)
	draw_set_transform(focus * (1.0 - push), 0.0, Vector2(push, push))
	# The television: bezel, glass, and its glow on the dark around it.
	var a := fade_in * fade_out
	for g in 4:  # the screen's glow on the dark room around it
		draw_rect(TV.grow(14.0 + g * 10.0), Color(0.35, 0.55, 0.75, 0.018 * a * (0.4 + 0.6 * room_light)))
	draw_rect(TV.grow(10), Color(0.07, 0.07, 0.08, a))
	draw_rect(TV.grow(10), Color(0.2, 0.2, 0.22, a), false, 1.0)
	draw_rect(TV, Color(0.02, 0.025, 0.03, a))
	# On it: the room, small, the way the game draws it.
	if room_light > 0.0:
		var ra := a * room_light
		var inner := TV.grow(-6)
		Decor.planks(self, inner, Color("3a2c24"), 10.0, 2.0)
		Decor.rug(self, Rect2(TV.get_center().x - 60, FLOOR_Y - 40, 120, 56), Color("5a3a34"), Color("b08a5a"))
		Decor.bed(self, Rect2(inner.position.x + 18, inner.position.y + 14, 64, 40), Color("5a4030"), Color("3d5a8a"), Color("e8e0d0"))
		var desk := Decor.furniture(self, Rect2(inner.end.x - 84, inner.position.y + 18, 54, 16), Color("6a5040"), 4.0)
		Decor.lamp(self, desk.position + Vector2(desk.size.x - 8, desk.size.y * 0.5), Color("f0d090"))
		draw_circle(desk.get_center(), 40.0, Color(1.0, 0.8, 0.5, 0.05))
		draw_rect(inner, Color(0, 0, 0, 1.0 - ra))  # the picture going out
	# The figures.
	if _t < 20.5:
		_arin.draw(self, {"offset": Vector2(_arin_x, FLOOR_Y), "scale": FIGURE, "alpha": a * (1.0 - clampf((_t - 19.0) / 1.5, 0.0, 1.0))})
	# (Once her colours have gone, her eyes are the two points of light the
	# missing palette gives her: she looks up at you with them.)
	_rue.draw(self, {"offset": Vector2(_rue_x, FLOOR_Y), "scale": FIGURE, "alpha": a})
	# The interface on the screen, which goes out piece by piece.
	var font := UiStyle.system_font()
	var labels_a := a * (1.0 - clampf((_t - 17.0) / 1.0, 0.0, 1.0))
	draw_string(font, TV.position + Vector2(8, 14), "P1  ARIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.55, 0.7, 1.0, labels_a))
	var p2 := "P2  RUE" if _t < 9.0 else "P2  ---"
	draw_string(font, Vector2(TV.end.x - 60, TV.position.y + 14), p2, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.8, 0.5, labels_a))
	if _t > 9.0 and _t < 12.5:
		var ta := a * clampf((_t - 9.0) / 0.3, 0.0, 1.0) * (1.0 - clampf((_t - 12.0) / 0.5, 0.0, 1.0))
		var box := Rect2(TV.get_center().x - 80, TV.end.y - 34, 160, 18)
		draw_rect(box, Color(0, 0, 0, 0.75 * ta))
		draw_rect(box, Color(1.0, 0.8, 0.5, 0.6 * ta), false, 1.0)
		draw_string(font, box.position + Vector2(10, 12), "PLAYER 2 DISCONNECTED", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.8, ta))
	if _t > 12.0 and _t < 19.5:
		var sa := a * clampf((_t - 12.0) / 0.4, 0.0, 1.0) * (1.0 - clampf((_t - 18.5) / 1.0, 0.0, 1.0))
		var fill := 0.87 * smoothstep(12.2, 15.5, _t)
		var bar := Rect2(TV.get_center().x - 70, TV.end.y - 30, 140, 4)
		draw_string(font, bar.position + Vector2(0, -6), "SAVING SLOT 2 ...", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.8, 0.95, 1.0, sa))
		draw_rect(bar, Color(1, 1, 1, 0.12 * sa))
		# Stuck at 87%: after a moment it flickers, as if nobody is watching.
		var stuck_flicker := 1.0 if calm() or _t < 16.0 else (0.6 + 0.4 * sin(_t * 18.0))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * fill, bar.size.y)), Color(0.55, 0.95, 1.0, 0.9 * sa * stuck_flicker))
		draw_string(font, bar.position + Vector2(0, 14), "41:07:12", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.7, 0.75, 0.8, 0.7 * sa))
	draw_set_transform(Vector2.ZERO)
