class_name Opening
extends Node2D
## The opening (about 45 s, in-engine, before the first run; the shot list is
## docs/NARRATIVE_CONTRACT.md §8). Two pairs of hands on two controllers in
## front of a television, late at night. Her thumb taps twice before it
## presses (her habit). Player 1's hands leave; hers stay, and go slack: she
## falls asleep holding it. SAVING SLOT 2 stops at 87%. Arin stops; the small
## figure keeps walking with nobody's hands on her. PAUSE: everything stops
## except her. A sound from the well, in the wrong place: the music box, one
## note missing. She turns and looks out at the hands. An unfinished sentence
## types itself across the room and into the screen. Then her first move,
## in the room, is yours.
##
## It shows an impossible event, not an explanation: nothing names who she
## is or says what happened to the girl. No run starts until it ends:
## quitting here costs nothing.
##
## Hold interact (or Esc, or touch and hold) to skip. Replay it from the
## title. Reduced flashing / zero glitch intensity: no camera push, no flicker.

signal finished

const GAME_SCENE := "res://scenes/main.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"
const LENGTH := 45.0
const SKIP_HOLD := 0.7
## The television, centred on the 640×360 canvas.
const TV := Rect2(150, 34, 340, 214)
const FLOOR_Y := 196.0
## The two pairs of hands, below the screen (player 1 left, player 2 right).
const HANDS_Y := 284.0
const P1_HANDS := Vector2(232, HANDS_Y)
const P2_HANDS := Vector2(408, HANDS_Y)
## Shot 8, months later (docs/NARRATIVE_CONTRACT.md §0.4 C1): her message
## arrives whole; the owner's reply stops mid-word and is never sent.
const HER_MESSAGE := "still have my save?"
const OWNER_REPLY := "yes i still have your sa"
## When shot 8 cuts in (months later): no push, her hands gone.
const LATER := 38.5
## The figures on the television, large enough to read a posture.
const FIGURE := 1.35

## Back to the title afterwards (a replay) instead of into the game.
var replay := false

var _t := 0.0
var _held := false
var _skip_t := 0.0
var _hint_t := 0.0
var _done := false
## Skips count only after every skip input has been seen released.
var _armed := false
var _handed_off := false
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
## The title's theme carries on under the film (it was silent apart from
## three cues: on a phone that sounded like the music had stopped), and
## thins out as the picture goes, until only the one note is left.
var _music: AudioStreamPlayer
const MUSIC_DB := -15.0
var _prewarmed := false
var _tune_started := false


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
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = MUSIC_DB
	add_child(_music)
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
	# Looking away holds the film, its music and any skip in progress where
	# they are; coming back resumes from the same frame (no time jump), and a
	# key still held from before has to be let go before it can skip.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_held = true
		_skip_t = 0.0
		_armed = false
		if _music:
			_music.stream_paused = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_held = false
		if _music:
			_music.stream_paused = false


## Any of the skip inputs held right now (keys, pad, a finger or the mouse).
static func _skip_held() -> bool:
	return Input.is_action_pressed("interact") or Input.is_action_pressed("confirm") \
		or Input.is_action_pressed("ui_cancel") or Input.is_action_pressed("pause") \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


func _process(delta: float) -> void:
	if _done:
		# The hand-off: whatever skipped (or a press during the last frames)
		# is let go before the game or the title takes input, so it can't
		# charge a glitch in the room or press a menu button.
		if not _skip_held() and not _handed_off:
			_handed_off = true
			if is_inside_tree():
				get_tree().change_scene_to_file.call_deferred(TITLE_SCENE if replay else GAME_SCENE)
		return
	if _held:
		return  # focus elsewhere: nothing moves, nothing skips
	_update_skip(delta)
	if _done:
		return
	_t += delta
	_update_music()
	# 1. Two people, one television.
	_cue(0.4, func() -> void: _caption.text = "[a television, late at night. two controllers.]")
	_cue(4.6, func() -> void: _caption.text = "")
	# 2. Her habit: two light taps before she presses.
	_cue(7.0, func() -> void: Sfx.play("click", -16.0, 1.3, 0.0))
	_cue(7.25, func() -> void: Sfx.play("click", -16.0, 1.3, 0.0))
	_cue(7.6, func() -> void: Sfx.play("click", -12.0, 1.0, 0.0))
	# 3. Player 1 puts theirs down and goes; hers stays in her hands.
	_cue(12.0, func() -> void: _caption.text = "[she falls asleep holding it]")
	_cue(15.6, func() -> void: _caption.text = "")
	# 4. The save that never finishes; Arin stops, she doesn't.
	_cue(16.0, func() -> void: Sfx.play("key_system", -4.0, 0.8, 0.0))
	# 5. Pause stops everything except her.
	_cue(22.0, func() -> void:
		Sfx.play("denied", -10.0, 0.7, 0.0)
		_caption.text = "[paused. she keeps walking.]")
	_cue(26.5, func() -> void: _caption.text = "")
	# 6. The well, in the wrong place.
	_cue(28.2, func() -> void: Sfx.play("click", -14.0, 0.45, 0.0))
	_cue(29.0, func() -> void:
		_play_tune()
		_caption.text = "[a music box, from somewhere it can't be. one note missing.]")
	_cue(33.0, func() -> void: _caption.text = "")
	# 8. Months later: her message, the owner's reply that stops, and the
	# owner's one click (hers were always two light taps first).
	_cue(LATER + 0.1, func() -> void: _caption.text = "[months later. her message. the owner starts to answer.]")
	_cue(LATER + 0.5, func() -> void: Sfx.play("key_system", -12.0, 1.1, 0.0))
	_cue(42.8, func() -> void: _caption.text = "")
	_cue(44.0, func() -> void: Sfx.play("click", -12.0, 1.0, 0.0))
	# On the television: they walk together; Arin stops when player 1 is
	# gone; she keeps going with nobody's hands on her, even through PAUSE.
	var arin_walks := _t > 5.0 and _t < 17.0
	var rue_walks := _t > 5.0 and _t < 33.0
	var pace := 11.0 if _t < 22.0 else 6.0
	if rue_walks:
		_rue_x = minf(_rue_x + pace * delta, TV.end.x - 40.0)
	if arin_walks:
		_arin_x += 11.0 * delta
	_rue.update(delta, Vector2(pace, 0) if rue_walks else Vector2.ZERO)
	_arin.update(delta if _t < 22.0 else 0.0, Vector2(11, 0) if arin_walks else Vector2.ZERO)
	if _t > 17.5 and _t < 22.0:
		_arin.look_at(Vector2.ZERO, Vector2.LEFT)  # waiting for input that won't come
	if _t > 33.0:
		# 7. She turns and looks out of the screen, at the hands; her
		# colours aren't quite holding.
		_rue.look_at(Vector2.ZERO, Vector2.DOWN)
		_rue.palette = _lerp_palette(Player.RUE, Player.MISSING, clampf((_t - 34.0) / 3.0, 0.0, 0.6))
	queue_redraw()
	if _t >= LENGTH:
		_finish()


func _update_music() -> void:
	if not _music.playing and _t < 20.0 and not _tune_started:
		var key := "theme_%d_normal" % MusicBox.held_level(OwnerMemory.fragments.size())
		if OwnerMemory.runtime_cache.has(key):
			_music.stream = OwnerMemory.runtime_cache[key]
			_music.play()
		elif not _prewarmed:
			_prewarmed = true  # (normally already built while the title was up)
			MusicBox.prewarm(MusicBox.held_level(OwnerMemory.fragments.size()))
	# Full while they play together; down as the interface goes out; gone
	# before the note.
	if _tune_started:
		return
	var k := 1.0 - clampf((_t - 13.0) / 7.0, 0.0, 1.0)
	_music.volume_db = MUSIC_DB + linear_to_db(maxf(k, 0.0001))
	if k <= 0.0 and _music.playing:
		_music.stop()


## Shot 6: the music box, one note short, from the well's direction.
func _play_tune() -> void:
	_tune_started = true
	_music.stop()
	_music.stream = MusicBox.stream(MusicBox.MAX_LEVEL - 1)
	_music.volume_db = MUSIC_DB - 4.0
	_music.play()


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
	var held := _skip_held()
	# A press that began before the film (the title's Load, held) or before
	# focus came back doesn't count: let go first, then hold to skip.
	if not _armed:
		_armed = not held
		held = false
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
	if _music:
		_music.stop()
	finished.emit()
	# The scene changes in _process, once nothing is held.


## 0..1: how far into the film (for tests and the storyboard).
func progress() -> float:
	return clampf(_t / LENGTH, 0.0, 1.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color.BLACK)
	var fade_in := clampf(_t / 2.5, 0.0, 1.0)
	var fade_out := 1.0 - clampf((_t - 43.0) / 2.0, 0.0, 1.0)
	var paused := _t > 22.0 and _t < 33.0
	var room_light := 1.0 - clampf((_t - 33.0) / 3.0, 0.0, 1.0)
	# The push in on her as she looks out (not with reduced motion).
	var push := 1.0 if calm() or _t >= LATER else 1.0 + 0.5 * smoothstep(33.0, LATER, _t)
	var focus := Vector2(_rue_x, FLOOR_Y)
	draw_set_transform(focus * (1.0 - push), 0.0, Vector2(push, push))
	var a := fade_in * fade_out
	for g in 4:  # the screen's glow on the dark room around it
		draw_rect(TV.grow(14.0 + g * 10.0), Color(0.35, 0.55, 0.75, 0.018 * a * (0.4 + 0.6 * room_light)))
	draw_rect(TV.grow(10), Color(0.07, 0.07, 0.08, a))
	draw_rect(TV.grow(10), Color(0.2, 0.2, 0.22, a), false, 1.0)
	draw_rect(TV, Color(0.02, 0.025, 0.03, a))
	var inner := TV.grow(-6)
	if room_light > 0.0:
		var ra := a * room_light
		Decor.planks(self, inner, Color("3a2c24"), 10.0, 2.0)
		Decor.rug(self, Rect2(TV.get_center().x - 60, FLOOR_Y - 40, 120, 56), Color("5a3a34"), Color("b08a5a"))
		Decor.bed(self, Rect2(inner.position.x + 18, inner.position.y + 14, 64, 40), Color("5a4030"), Color("3d5a8a"), Color("e8e0d0"))
		var desk := Decor.furniture(self, Rect2(inner.end.x - 84, inner.position.y + 18, 54, 16), Color("6a5040"), 4.0)
		Decor.lamp(self, desk.position + Vector2(desk.size.x - 8, desk.size.y * 0.5), Color("f0d090"))
		draw_circle(desk.get_center(), 40.0, Color(1.0, 0.8, 0.5, 0.05))
		# Shot 6: a well where no well should be, at the edge of the picture.
		if _t > 28.0:
			var wa := ra * clampf((_t - 28.0) / 1.0, 0.0, 1.0)
			var wc := Vector2(inner.position.x + 34, inner.end.y - 26)
			draw_circle(wc, 11.0, Color(0.32, 0.31, 0.3, wa))
			draw_circle(wc, 7.0, Color(0.02, 0.03, 0.05, wa))
			var ring := fmod(_t * 0.8, 1.0)
			draw_arc(wc, 3.0 + ring * 5.0, 0.0, TAU, 16, Color(0.6, 0.9, 1.0, wa * (1.0 - ring) * 0.6), 1.0)
		draw_rect(inner, Color(0, 0, 0, 1.0 - ra))  # the picture going out
		if paused:
			draw_rect(inner, Color(0, 0, 0, 0.45 * ra))  # the game dims under PAUSE
	# The figures.
	if _t < 33.0:
		_arin.draw(self, {"offset": Vector2(_arin_x, FLOOR_Y), "scale": FIGURE, "alpha": a * (1.0 - clampf((_t - 31.0) / 2.0, 0.0, 1.0)) * (0.55 if paused else 1.0)})
	# (Once her colours start to go, her eyes are the two points of light the
	# missing palette gives her: she looks out at the hands with them.)
	# (Months later she is still in there, fainter, watching the words.)
	_rue.draw(self, {"offset": Vector2(_rue_x, FLOOR_Y), "scale": FIGURE, "alpha": a * (0.55 if _t >= LATER else 1.0)})
	var font := UiStyle.system_font()
	var labels_a := a * (1.0 - clampf((_t - 33.0) / 1.0, 0.0, 1.0))
	draw_string(font, TV.position + Vector2(8, 14), "P1  ARIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.55, 0.7, 1.0, labels_a * (1.0 if _t < 12.5 else 0.4)))
	# Player 2 is a player, not a name: the opening doesn't say who she was.
	draw_string(font, Vector2(TV.end.x - 60, TV.position.y + 14), "P2", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.8, 0.5, labels_a))
	if _t > 16.0 and _t < 33.0:
		var sa := a * clampf((_t - 16.0) / 0.4, 0.0, 1.0) * (1.0 - clampf((_t - 32.0) / 1.0, 0.0, 1.0))
		var fill := 0.87 * smoothstep(16.2, 18.5, _t)
		var bar := Rect2(TV.get_center().x - 70, TV.end.y - 24, 140, 4)
		draw_string(font, bar.position + Vector2(0, -6), "SAVING SLOT 2 ...", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.8, 0.95, 1.0, sa))
		draw_rect(bar, Color(1, 1, 1, 0.12 * sa))
		var stuck_flicker := 1.0 if calm() or _t < 19.0 else (0.6 + 0.4 * sin(_t * 18.0))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * fill, bar.size.y)), Color(0.55, 0.95, 1.0, 0.9 * sa * stuck_flicker))
		draw_string(font, bar.position + Vector2(bar.size.x + 6, 4), "87%" if _t > 18.5 else "", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.7, 0.75, 0.8, 0.8 * sa))
	if paused:
		var pa := a * clampf((_t - 22.0) / 0.3, 0.0, 1.0) * (1.0 - clampf((_t - 32.0) / 1.0, 0.0, 1.0))
		draw_string(font, Vector2(TV.get_center().x - 18, TV.position.y + 40), "PAUSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, pa))
	draw_set_transform(Vector2.ZERO)
	_draw_hands(a)
	# Shot 8, months later: her message on the screen, whole; under it the
	# owner's reply, typed and then stopping mid-word. Never sent.
	if _t > LATER + 0.4:
		var ma := fade_out * clampf((_t - LATER - 0.4) / 0.4, 0.0, 1.0)
		var box := Rect2(TV.position.x + 24, TV.position.y + 24, TV.size.x - 48, 46)
		draw_rect(box, Color(0.02, 0.03, 0.05, 0.9 * ma))
		draw_rect(box, Color(0.55, 0.7, 0.8, 0.5 * ma), false, 1.0)
		draw_string(font, box.position + Vector2(8, 15), HER_MESSAGE, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.85, 0.6, ma))
		var n := clampi(int((_t - 39.6) / 3.0 * OWNER_REPLY.length()), 0, OWNER_REPLY.length()) if _t > 39.6 else 0
		var cursor := "_" if fmod(_t, 0.8) < 0.4 else " "
		draw_string(font, box.position + Vector2(8, 34), "> " + OWNER_REPLY.substr(0, n) + cursor,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.75, 0.95, 1.0, ma))


## Two pairs of hands on two controllers, below the screen: player 1's leave
## (12–13.5 s); hers stay, tap twice before pressing (7 s), then go slack.
## Her controller's cable is taped where the dog chewed it (the memory THE
## SECOND CONTROLLER). Months later (shot 8) only the owner's hands are
## there; hers is on the floor where she dropped it.
func _draw_hands(a: float) -> void:
	var skin := Color(0.78, 0.62, 0.5)
	if _t >= LATER:
		_controller(P2_HANDS + Vector2(80, 12), skin, a, 0.6, 0.0, true, false)
		var typing := 1.5 if _t > 39.6 and _t < 42.6 and fmod(_t, 0.25) < 0.12 else 0.0
		_controller(P1_HANDS, skin, a * clampf((_t - LATER) / 0.4, 0.0, 1.0), 0.0, typing)
		return
	var p1_off := smoothstep(12.0, 13.5, _t) * 70.0
	var slack := smoothstep(13.0, 15.0, _t)
	_controller(P1_HANDS + Vector2(-p1_off, p1_off * 0.4), skin, a * (1.0 - smoothstep(12.5, 13.5, _t)), 0.0, 0.0)
	var tap := 0.0
	for at in [7.0, 7.25, 7.6]:
		if _t > at and _t < at + 0.12:
			tap = 2.0
	_controller(P2_HANDS + Vector2(0, slack * 6.0), skin, a, slack * 0.25, tap, true)


func _controller(at: Vector2, skin: Color, a: float, tilt: float, thumb: float, taped := false, hands := true) -> void:
	if a <= 0.0:
		return
	draw_set_transform(at, tilt, Vector2.ONE)
	if taped:
		# The cable, out of the bottom and away; a band of tape halfway.
		draw_line(Vector2(0, 8), Vector2(6, 30), Color(0.1, 0.1, 0.12, a), 2.0)
		draw_line(Vector2(6, 30), Vector2(-4, 60), Color(0.1, 0.1, 0.12, a), 2.0)
		draw_rect(Rect2(2, 18, 6, 4), Color(0.85, 0.85, 0.78, a))
	draw_rect(Rect2(-24, -6, 48, 14), Color(0.12, 0.12, 0.14, a))
	draw_circle(Vector2(-22, 2), 8.0, Color(0.12, 0.12, 0.14, a))
	draw_circle(Vector2(22, 2), 8.0, Color(0.12, 0.12, 0.14, a))
	draw_circle(Vector2(14, -1), 2.0, Color(0.85, 0.3, 0.3, a))
	if not hands:
		draw_set_transform(Vector2.ZERO)
		return
	# Thumbs on top, the rest of the hand around the grips.
	draw_circle(Vector2(-26, 6), 7.0, Color(skin, a))
	draw_circle(Vector2(26, 6), 7.0, Color(skin, a))
	draw_circle(Vector2(-12, -6), 3.5, Color(skin, a))
	draw_circle(Vector2(13, -6 - thumb), 3.5, Color(skin, a))
	draw_set_transform(Vector2.ZERO)
