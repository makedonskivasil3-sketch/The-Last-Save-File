class_name Prologue
extends Node2D
## The festival (docs/INTRO_REBUILD.md §2): the girl's last session, played.
## Years ago, on a festival afternoon, Player 1 (Arin) and Player 2 (Rue,
## you) light the village's five lanterns together. Each lantern needs both
## of them and teaches a verb the game uses later:
##
##   1 PLATE    Arin holds the plate, the gate opens: move, interact.
##   2 WATCH    Tobben watches the fireworks: hide beside Arin as he looks.
##   3 SPECIAL  Both hold [E] at once: the co-op special (hold to charge).
##   4 BEAM     The festival spotlight sweeps the gap: cross when it turns.
##
## The fifth, by the well, needs both of them too. Halfway through the
## hold, Arin's half stops: he freezes, the music cuts, and only then
## PLAYER 1 HAS LEFT THE SESSION. Stay beside him, or try alone (it needs
## two): the first decision. PLAYER 2 HAS LEFT THE SESSION. Then, with
## nobody holding anything, the player holds [E] and Rue lights it alone:
## the first impossible action (docs/production/OPENING_BEATS.md).
## Time passes over the square (the message,
## SLOT 2 · DELETED, 3 YEARS LATER); one lantern never goes out. The owner
## loads slot 1, Arin sees her: "...who's in my save?" Then the game.
##
## Arin is mute here as everywhere: Player 1 talks through what Arin does.
## Hold Esc (or the skip chip on a touch screen) to skip to the present; a
## player who does nothing is shown each step after a while, then played
## through it, so nothing is lost by waiting.

signal finished

const GAME_SCENE := "res://scenes/main.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"

enum Beat { L1, L2, L3, L4, P1_LEFT, P2_LEFT, TIMELAPSE, LOAD, DONE }

## The square, then (logical px).
const BOUNDS := Rect2(16, 74, 608, 270)
const RUE_START := Vector2(130, 262)
const ARIN_START := Vector2(162, 252)
const LANTERNS: Array[Vector2] = [Vector2(82, 140), Vector2(356, 100), Vector2(330, 234), Vector2(520, 336), Vector2(424, 132)]
## 1: the fenced corner and its gate, the plate across the path.
const FENCE := Rect2(56, 118, 52, 54)
const GATE := Rect2(74, 168, 26, 4)
const PLATE := Vector2(166, 178)
## 2: Tobben's stall and where he stands watching the fireworks.
const STALL := Rect2(244, 82, 88, 26)
const TOBBEN_AT := Vector2(292, 120)
const LOOK_RANGE := 130.0
const LOOK_HALF := 0.34
const LOOK_PERIOD := 5.5
## 3: the maypole lantern, a place for each of them.
const SPECIAL_LEFT := Vector2(310, 248)
const SPECIAL_RIGHT := Vector2(352, 248)
const SPECIAL_TIME := 1.3
## 4: the hedge, its gap, the spotlight tower.
const HEDGE_Y := Vector2(294, 306)
const GAP := Vector2(506, 534)
const TOWER := Vector2(586, 236)
const BEAM_PERIOD := 4.2
const BEAM_ON := 0.38  # share of the cycle the light is on the gap
## 5: the well, and the lantern beside it.
const WELL := Rect2(444, 150, 40, 24)
## Arin stops here when Player 1 leaves (mid-run for the fifth). Kept for
## older captures; the break now happens at the fifth lantern itself.
const ARIN_STOPS := Vector2(470, 252)
## 5: the fifth needs both, like the maypole: a place for each of them.
const FIFTH_LEFT := Vector2(404, 150)
const FIFTH_RIGHT := Vector2(438, 150)
const FIFTH_TIME := 1.6
## Arin's half stops when the shared hold gets this far.
const P1_STOPS_AT := 0.5
## Seconds of his absence before anything names it.
const ABSENCE_QUIET := 2.5
## Alone (with her player still there) the hold gets this far, then stalls.
const ALONE_CAP := 0.5
## Holding alone this long makes "tried" her answer.
const TRY_TIME := 1.6
## After Player 2 leaves: when the faint [E] appears, and when it's named.
const IMPOSSIBLE_PROMPT := 2.0
const IMPOSSIBLE_HINT := 8.0

const SPEED := 90.0
const ARIN_SPEED := 78.0
const HIDE_R := 20.0
const INTERACT_R := 20.0
## Waiting this long without input shows the step; this long, plays it.
const HINT_AFTER := 6.0
const AUTO_AFTER := 24.0
const DECIDE_TIME := 20.0
const TIMELAPSE := 20.0
const LOAD_TIME := 6.0
const SKIP_HOLD := 0.7
## The skip chip on touch screens (screen coordinates, 640×360).
const SKIP_CHIP := Rect2(560, 328, 76, 26)

const P1_COLOR := Color(0.55, 0.72, 1.0)
const P2_COLOR := Color(1.0, 0.78, 0.45)
const OWNER_COLOR := Color("e0504f")
const SYSTEM_COLOR := Color("8cf2ff")

const MESSAGE := "still have my save?"

## Shown once the prologue hands off, so the room doesn't show the boot
## log again (World reads and clears it).
static var boot_shown := false

## Back to the title afterwards (a replay) instead of into the game.
var replay := false
## Plays itself (tests, captures): Rue's player acts at once.
var autoplay := false

var beat: Beat = Beat.L1
var beat_t := 0.0
var elapsed := 0.0
## What happened, and when (seconds since the prologue began): tests,
## timings, the playtest log.
var acted := {}
## The first decision, when Player 1 stops: "stayed" (beside Arin),
## "tried" (the fifth, alone: it needs two) or "idle" (neither). Saves from
## the earlier festival may hold "lit" (she lit it with her player there).
var choice := ""
## The fifth's shared hold (0..1), and when Player 1's half stopped.
var _fifth := 0.0
var _p1_stopped_at := -1.0
var _alone_t := 0.0
var _arin_frozen := false
var lit: Array[bool] = [false, false, false, false, false]
var caught := 0

var rue := HeroFigure.new("rue", Player.RUE)
var arin := HeroFigure.new("adult", {
	"h": OwnerAvatar.HAIR, "s": OwnerAvatar.SKIN, "c": OwnerAvatar.BODY, "d": Color("2e3f5c"), "a": Color("c0392b"),
	"l": Color("2e3f5c"), "f": Color("1a1a20"), "e": Color("101018"),
})
var mira := HeroFigure.new("dress", {"h": Color("6a3a2a"), "s": Color("f0c8a0"), "c": Color("c9733e"), "d": Color("a85a2e")})
var wren := HeroFigure.new("child", {"h": Color("c9a04a"), "s": Color("eac09a"), "c": Color("6a8f5a"), "d": Color("4a6a3a")})
var tobben := HeroFigure.new("apron", {"h": Color("bbbbbb"), "s": Color("e0b48a"), "c": Color("7a5a8a"), "d": Color("4a3a5a")})

var rue_pos := RUE_START
var arin_pos := ARIN_START
## What Rue actually travelled last frame (px/s): the gait, dust and
## camera read this, so pushing into a wall isn't walking.
var _rue_vel := Vector2.ZERO
## What the player is asking for (direction, 0..1): she faces it even
## when blocked (docs/production/MOVEMENT_SPEC.md).
var _rue_intent := Vector2.ZERO
## Seconds a pointer destination has made no real progress.
var _stuck_t := 0.0
var _arin_vel := Vector2.ZERO
var _arin_goal := ARIN_START
var _arin_overshoot := Vector2.ZERO
## Where Arin goes after his current goal (a route, one point at a time).
var _arin_path: Array[Vector2] = []
## Leading her through Tobben's watch: slow, and only while she's close.
var _escorting := false
var _arin_present := true
var _emotes := {}  # who -> [text, seconds]
var _glow: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
var _bursts: Array = []  # [pos, t]
var _special := 0.0
var _idle := 0.0
var _toast := ""
var _toast_t := 0.0
var _toast_color := SYSTEM_COLOR
var _skip_t := 0.0
var _armed := false
var _done := false
var _handed_off := false
var _focus_lost := false
var _pad_lost := false
var _lost_pad := -1
var _decided_t := 0.0
var _rue_free := true  # the player moves her (false while time moves her)
var _walk_to := Vector2.INF
var _act_queued := false
var _hold_down := false
var _music: AudioStreamPlayer
## The camera: close on the two of them at the festival, the whole square
## while the years pass, close again when the owner loads.
var zoom := 1.7
## Motion (all of it off under reduced motion, calm()): camera trauma that
## decays (shake), a zoom punch, a brief slow-down on big moments
## (hit-stop), and ambient motes (pollen by day, fireflies round lit
## lanterns, dust from her feet, sparks). Its own RNG: never the game's.
var _shake := 0.0
var _punch := 0.0
var _hitstop := 0.0
var _motes: Array = []  # [pos, vel, life, max_life, kind]
var _fx_rng := RandomNumberGenerator.new()
var _dust_t := 0.0
var _cam := Vector2(320, 200)
var _hud: CanvasLayer
var _banner: Label
var _quest: Label
var _pips: Label
var _hint: Label
var _toast_label: Label
var _skip_label: Label
var _diag: Label
var _owner_line: Label
var _years: Label
var _chip: Label
var story: PrologueStory
var _touch: TouchControls
var _story_seen := {}
var _story_release := false


static func wanted() -> bool:
	return Opening.wanted()


## World asks once: did the festival just show the boot (its own way)?
static func take_boot_shown() -> bool:
	var was := boot_shown
	boot_shown = false
	return was


static func calm() -> bool:
	return Settings.reduce_motion


static func load_flicker() -> bool:
	return not calm() and not Settings.reduce_flashing and Settings.glitch_intensity > 0.01


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Sfx.reset_scene_state()
	WebState.publish({"scene": "prologue", "playable": true})
	PlaytestLog.mark("prologue: the festival", "replay" if replay else "first run")
	camera_plain = plain_camera_requested()
	_build_hud()
	# Phones and tablets: the same on-screen stick and E button as the game
	# (hidden until the screen is touched).
	_touch = TouchControls.new()
	add_child(_touch)
	var story_layer := CanvasLayer.new()
	story_layer.layer = 20
	add_child(story_layer)
	story = PrologueStory.new()
	story_layer.add_child(story)
	story.page_read.connect(_remember_story)
	rue.facing = Vector2.UP
	arin.facing = Vector2.LEFT
	wren.idle_style = "hop"
	tobben.idle_style = "tend"
	mira.idle_style = "sway"
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = -16.0
	add_child(_music)
	_music.stream = MusicBox.stream(3)
	_music.play()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_show_toast("PLAYER 2 HAS JOINED", P2_COLOR, 2.4)
	_set_arin_goal(PLATE)


func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 15
	add_child(_hud)
	# A soft backing strip under the title, so the world moving behind it
	# never runs through the words.
	var strip := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.05, 0.03, 0.08, 0.55))
	grad.set_color(1, Color(0.05, 0.03, 0.08, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 4
	tex.height = 64
	strip.texture = tex
	strip.stretch_mode = TextureRect.STRETCH_SCALE
	strip.position = Vector2.ZERO
	strip.size = Vector2(640, 70)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(strip)
	_banner = _label(Vector2(0, 8), 13, Color(1.0, 0.92, 0.75))
	_banner.text = "THE LANTERN FESTIVAL"
	_quest = _label(Vector2(0, 26), 9, Color(0.95, 0.9, 0.82))
	_quest.text = "light the five lanterns before sundown"
	_pips = _label(Vector2(0, 40), 10, Color(1.0, 0.8, 0.45))
	_toast_label = _label(Vector2(0, 62), 12, SYSTEM_COLOR)
	# A plate under the system line, so it reads over the nameplates below it.
	var toast_bg := StyleBoxFlat.new()
	toast_bg.bg_color = Color(0.03, 0.04, 0.07, 0.82)
	toast_bg.set_corner_radius_all(3)
	toast_bg.content_margin_left = 8
	toast_bg.content_margin_right = 8
	_toast_label.add_theme_stylebox_override("normal", toast_bg)
	_hint = _label(Vector2(0, 334), 9, Color(0.95, 0.93, 0.88))
	_skip_label = _label(Vector2(0, 346), 8, Color(0.75, 0.77, 0.8))
	_diag = Label.new()
	_diag.position = Vector2(14, 10)
	UiStyle.sized(_diag, 9)
	UiStyle.outline(_diag, 2)
	_diag.add_theme_color_override("font_color", SYSTEM_COLOR)
	_hud.add_child(_diag)
	_owner_line = _label(Vector2(0, 300), 11, OWNER_COLOR)
	_chip = Label.new()
	_chip.position = SKIP_CHIP.position
	_chip.size = SKIP_CHIP.size
	_chip.text = "skip ▸▸"
	_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiStyle.sized(_chip, 9)
	var chip_bg := StyleBoxFlat.new()
	chip_bg.bg_color = Color(0, 0, 0, 0.5)
	chip_bg.set_corner_radius_all(4)
	_chip.add_theme_stylebox_override("normal", chip_bg)
	_chip.visible = false
	_hud.add_child(_chip)
	_years = _label(Vector2(0, 160), 20, Color(0.95, 0.95, 0.95))


func _label(pos: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(640, 16)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.sized(l, size)
	UiStyle.outline(l, 3)
	l.add_theme_color_override("font_color", color)
	_hud.add_child(l)
	return l


# --- holds and input ownership (the same rules as the opening film) ----------------

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focus_lost = true
		_update_hold()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focus_lost = false
		_update_hold()


func held() -> bool:
	return _focus_lost or _pad_lost


func _update_hold() -> void:
	if held():
		_skip_t = 0.0
		_armed = false
		if story:
			story.rearm()
	if _music:
		_music.stream_paused = held()


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if not connected and not _done and Settings.is_players_pad(device):
		_lost_pad = device
		_pad_lost = true
		_update_hold()
		_hint.text = "controller disconnected: reconnect it, or press any key"
	elif connected and _pad_lost and device == _lost_pad:
		_pad_lost = false
		_update_hold()


func _input(event: InputEvent) -> void:
	if _pad_lost and event.is_pressed() and (event is InputEventKey or event is InputEventScreenTouch \
			or event is InputEventMouseButton or event is InputEventJoypadButton):
		_pad_lost = false  # the player took over: this press does nothing else
		_update_hold()
		get_viewport().set_input_as_handled()
		return
	if held() or _done:
		return
	if story.visible or _story_release:
		return  # the panel takes taps; none become walking destinations
	# A tap or click: walk there; on a lantern, light it once there.
	var pointer := (event is InputEventScreenTouch) or (event is InputEventMouseButton \
		and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION)
	if pointer and event.is_pressed():
		if Settings.using_touch and SKIP_CHIP.has_point(get_viewport().get_mouse_position()):
			return  # the skip chip (held: _skip_held)
		var at: Vector2 = make_input_local(event).position
		_walk_to = at
		_act_queued = _near_lantern(at) >= 0
		_mark_input()


func _skip_held() -> bool:
	if Input.is_action_pressed("ui_cancel") or Input.is_action_pressed("pause"):
		return true
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return SKIP_CHIP.has_point(get_viewport().get_mouse_position())
	return false


func _mark_input() -> void:
	_idle = 0.0
	if not acted.has("control"):
		acted["control"] = elapsed
		PlaytestLog.mark("prologue: first movement", "%.1f s" % elapsed)


# --- the loop -----------------------------------------------------------------------

func _process(delta: float) -> void:
	if _done:
		if not _skip_held() and not Input.is_action_pressed("interact") and not _handed_off:
			_handed_off = true
			if is_inside_tree():
				get_tree().change_scene_to_file.call_deferred(TITLE_SCENE if replay else GAME_SCENE)
		return
	if held():
		return
	# Reading owns the simulation clock, including assistance and decisions.
	# Skip is still available, but never commits an unread page.
	if story.visible:
		_update_skip(delta)
		if story.visible:
			story.tick(delta, autoplay)
		if not story.visible:
			_story_release = true
		return
	if _story_release:
		if not Input.is_action_pressed("interact") and not Input.is_action_pressed("confirm") \
				and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_story_release = false
			_touch.buttons_enabled = true
		return
	# A beat of slow motion when something big happens.
	if _hitstop > 0.0:
		_hitstop = maxf(0.0, _hitstop - delta)
		delta *= 0.3
	elapsed += delta
	beat_t += delta
	_idle += delta
	_update_skip(delta)
	if _done:
		return
	_toast_t = maxf(0.0, _toast_t - delta)
	for who in _emotes.keys():
		_emotes[who][1] -= delta
		if _emotes[who][1] <= 0.0:
			_emotes.erase(who)
	_move_rue(delta)
	_think_arin(delta)
	_update_beat(delta)
	for i in 5:
		_glow[i] = move_toward(_glow[i], 1.0 if lit[i] else 0.0, delta * (1.5 if calm() else 3.0))
	for b in _bursts:
		b[1] += delta
	_bursts = _bursts.filter(func(b: Array) -> bool: return b[1] < 1.2)
	rue.update(delta, _rue_vel, false)
	rue.face(_rue_intent)
	# Nobody driving him: not even a breath (he resumes when the owner loads).
	if not _arin_frozen:
		arin.update(delta, _arin_vel)
	for f in [mira, wren, tobben]:
		f.update(delta, Vector2.ZERO)
	_update_hud(delta)
	_update_camera(delta)
	_update_motes(delta)
	queue_redraw()


## Camera trauma, a zoom punch and a moment of slow motion (none when calm).
func _kick(trauma: float, punch: float, stop := 0.0) -> void:
	if calm():
		return
	_shake = minf(1.0, _shake + trauma)
	_punch = maxf(_punch, punch)
	_hitstop = maxf(_hitstop, stop)


func _update_motes(delta: float) -> void:
	for m in _motes:
		m[0] += m[1] * delta
		m[2] -= delta
		match m[4]:
			"firefly":
				m[1] = m[1].rotated(_fx_rng.randf_range(-2.0, 2.0) * delta) * 0.995
			"spark":
				m[1].y += 60.0 * delta
			"dust":
				m[1] *= 0.92
	_motes = _motes.filter(func(m: Array) -> bool: return m[2] > 0.0)
	if calm() or beat >= Beat.LOAD:
		return
	var view := Vector2(640, 360) / zoom
	var tl := -position / zoom
	# Pollen drifting across the afternoon; fireflies round lit lanterns.
	if _motes.size() < 90:
		if _sky_t() < 1.4 and _fx_rng.randf() < delta * 14.0:
			var at := tl + Vector2(_fx_rng.randf() * view.x, _fx_rng.randf() * view.y)
			_motes.append([at, Vector2(_fx_rng.randf_range(4, 12), _fx_rng.randf_range(-4, 2)), 4.0, 4.0, "pollen"])
		for i in 5:
			if lit[i] and _fx_rng.randf() < delta * 2.5:
				var at := LANTERNS[i] + Vector2(_fx_rng.randf_range(-14, 14), _fx_rng.randf_range(-30, 0))
				_motes.append([at, Vector2.from_angle(_fx_rng.randf() * TAU) * 8.0, 3.0, 3.0, "firefly"])
	# Dust from her feet when she runs, or stops hard.
	_dust_t -= delta
	if _rue_vel.length() > 60.0 and _dust_t <= 0.0:
		_dust_t = 0.12
		_motes.append([rue_pos + Vector2(_fx_rng.randf_range(-3, 3), 0), Vector2(-_rue_vel.x * 0.15, -8), 0.5, 0.5, "dust"])


func _spark_burst(at: Vector2, n: int) -> void:
	if calm():
		return
	for i in n:
		var dir := Vector2.from_angle(-PI * 0.5 + _fx_rng.randf_range(-1.2, 1.2))
		_motes.append([at, dir * _fx_rng.randf_range(40, 110), 1.1, 1.1, "spark"])


func _draw_motes() -> void:
	for m in _motes:
		var a: float = clampf(m[2] / m[3], 0.0, 1.0)
		match m[4]:
			"pollen":
				draw_circle(m[0], 0.7, Color(1.0, 0.97, 0.8, 0.55 * sin(a * PI)))
			"firefly":
				var blink := 0.5 + 0.5 * sin(elapsed * 7.0 + m[0].x)
				draw_circle(m[0], 3.0, Color(1.0, 0.85, 0.4, 0.12 * a * blink))
				draw_circle(m[0], 0.9, Color(1.0, 0.95, 0.6, 0.9 * a * blink))
			"spark":
				draw_line(m[0], m[0] - m[1] * 0.03, Color(1.0, 0.8, 0.4, a), 1.0)
			"dust":
				draw_circle(m[0], 2.5 * (1.5 - a), Color(0.85, 0.78, 0.6, 0.35 * a))


## Camera (docs/production/MOVEMENT_SPEC.md, Camera). Arin is blended into
## the framing by distance, never switched. The look-ahead cancels the
## follow's own lag (at full speed the smoothing alone trails her by about
## speed / 2.5 px), so she stays near the centre and a reversal barely moves
## the view; it reads what she actually travels (none against a wall) and
## fades beside a lantern so that stays framed. Reduced motion: no
## look-ahead, drift, shake or punch; the view follows her closely.
const SHARE_NEAR := 110.0
const SHARE_FAR := 190.0
const LOOK_AHEAD := 0.35  # seconds of travel (about 1 / the follow rate)
const LOOK_MAX := 31.5
## Comparison captures only: centred on Rue, nothing else.
var camera_fixed := false
## Movement playtests: the follow's smoothing only, with no look-ahead,
## drift, shake or zoom punch, so the controller is judged on its own.
## `-- --camera-plain`, or ?camera=plain on the web.
var camera_plain := false


static func plain_camera_requested() -> bool:
	if "--camera-plain" in OS.get_cmdline_user_args():
		return true
	return OS.has_feature("web") and str(JavaScriptBridge.eval("window.location.search", true)).contains("camera=plain")
var _look := Vector2.ZERO


## Where the camera wants to be (before smoothing and the look-ahead).
func _camera_focus() -> Vector2:
	var share := 0.0
	if _arin_present:
		share = smoothstep(SHARE_FAR, SHARE_NEAR, arin_pos.distance_to(rue_pos))
	if beat in [Beat.LOAD, Beat.DONE]:
		share = 1.0
	return rue_pos.lerp((rue_pos + arin_pos) * 0.5, share)


## 1 in the open, 0 beside something she can light or use (it stays framed).
func _look_room() -> float:
	var near := INF
	for i in 5:
		if not lit[i]:
			near = minf(near, rue_pos.distance_to(LANTERNS[i]))
	return smoothstep(18.0, 44.0, near)


func _update_camera(delta: float) -> void:
	var want_zoom := 1.7
	match beat:
		Beat.P2_LEFT:
			want_zoom = 1.5
		Beat.TIMELAPSE:
			want_zoom = 1.0
		Beat.LOAD, Beat.DONE:
			want_zoom = 1.45
	var focus := _camera_focus()
	var k := 1.0 - exp(-(2.5 if not calm() else 6.0) * delta)
	# During his absence the camera holds its breath too.
	var hush := _p1_stopped_at >= 0.0 and beat == Beat.P1_LEFT
	var lively := not calm() and not hush and not camera_fixed and not camera_plain
	_look = (_rue_vel * LOOK_AHEAD).limit_length(LOOK_MAX) * _look_room() if lively else Vector2.ZERO
	focus += _look
	if lively:
		focus += Vector2(sin(elapsed * 0.37) * 2.0, cos(elapsed * 0.29) * 1.2)
	if camera_fixed:
		focus = rue_pos
		k = 1.0
	_punch = move_toward(_punch, 0.0, delta * 0.6) if not camera_plain else 0.0
	zoom = lerpf(zoom, want_zoom, k)
	_cam = _cam.lerp(focus + Vector2(0, -16), k)
	var z := zoom + _punch
	var view := Vector2(640, 360) / z
	var tl := (_cam - view * 0.5).clamp(Vector2.ZERO, Vector2(640, 360) - view)
	# Trauma shake: squared, so small knocks stay small.
	_shake = move_toward(_shake, 0.0, delta * 1.6)
	if _shake > 0.0 and not camera_fixed and not camera_plain:
		var amt := _shake * _shake * 5.0
		tl += Vector2(_fx_rng.randf_range(-amt, amt), _fx_rng.randf_range(-amt, amt)) / z
	scale = Vector2(z, z)
	position = -tl * z


func _update_skip(delta: float) -> void:
	var holding := _skip_held()
	if not _armed:
		_armed = not holding
		holding = false
	if holding and (beat < Beat.LOAD or story.visible):
		_skip_t += delta
		if _skip_t >= SKIP_HOLD:
			acted["skipped"] = elapsed
			PlaytestLog.mark("prologue skipped", Beat.keys()[beat])
			_skip_t = 0.0
			_armed = false
			_to_beat(Beat.LOAD)
	else:
		_skip_t = maxf(0.0, _skip_t - delta * 2.0)


## The player's stick, keys, a tap's destination, or (autoplay, or a long
## wait) the next step played for them.
func _input_dir() -> Vector2:
	# The actions' own deadzone (0.3, rescaled by get_vector) is the only
	# one, as in the game: a light stick walks slowly in both.
	var d := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if d != Vector2.ZERO:
		_walk_to = Vector2.INF  # keys or a stick take over from a tap
		_act_queued = false
		_mark_input()
		return d
	if _walk_to != Vector2.INF:
		return Vector2.ZERO  # a tap's destination: _move_rue steps to it
	if autoplay or _shown_how():
		return _auto_dir()
	return Vector2.ZERO


## Waited long enough at a step: it's played for them. Never the decision
## at the break: that stays theirs (doing nothing is an answer too).
func _shown_how() -> bool:
	return _idle > AUTO_AFTER and not (beat == Beat.P1_LEFT and _p1_stopped_at >= 0.0)


func _interact_pressed() -> bool:
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("confirm"):
		_mark_input()
		return true
	return false


func _interact_held() -> bool:
	if Input.is_action_pressed("interact") or Input.is_action_pressed("confirm"):
		_mark_input()
		return true
	return _hold_down


## Movement (docs/production/MOVEMENT_SPEC.md): intent -> the step asked
## for -> what the solids allow -> the velocity that animates her.
func _move_rue(delta: float) -> void:
	var want := Vector2.ZERO
	if not _rue_free:
		var spot := LANTERNS[4] + Vector2(0, 14)
		if rue_pos.y > HEDGE_Y.x - 4.0:
			var gx := (GAP.x + GAP.y) * 0.5
			spot = Vector2(gx, rue_pos.y - 20.0) if absf(rue_pos.x - gx) < 3.0 else Vector2(gx, rue_pos.y)
		var to := spot - rue_pos
		want = to.limit_length(SPEED * 0.6 * delta) if to.length() > 2.0 else Vector2.ZERO
	else:
		var d := _input_dir()
		if _walk_to != Vector2.INF:
			# Never past it: the step is bounded by what's left.
			want = (_walk_to - rue_pos).limit_length(SPEED * delta)
		else:
			want = d * SPEED * delta
	_rue_intent = want / (SPEED * delta) if delta > 0.0 else Vector2.ZERO
	var from := rue_pos
	rue_pos = _slide(rue_pos, want, true)
	var moved := rue_pos - from
	_rue_vel = moved / delta if delta > 0.0 else Vector2.ZERO
	if _walk_to != Vector2.INF:
		_follow_tap(want, moved, delta)
	if _rue_free and beat <= Beat.P1_LEFT and (_interact_pressed() or _auto_act()):
		_interact()


func _solids(for_rue: bool) -> Array[Rect2]:
	var out: Array[Rect2] = [
		Rect2(FENCE.position.x, FENCE.position.y, 4, FENCE.size.y),
		Rect2(FENCE.end.x - 4, FENCE.position.y, 4, FENCE.size.y),
		Rect2(FENCE.position.x, FENCE.position.y, FENCE.size.x, 4),
		Rect2(FENCE.position.x, FENCE.end.y - 4, GATE.position.x - FENCE.position.x, 4),
		Rect2(GATE.end.x, FENCE.end.y - 4, FENCE.end.x - GATE.end.x, 4),
		STALL, WELL,
		Rect2(372, HEDGE_Y.x, GAP.x - 372, HEDGE_Y.y - HEDGE_Y.x),
		Rect2(GAP.y, HEDGE_Y.x, BOUNDS.end.x - GAP.y, HEDGE_Y.y - HEDGE_Y.x),
	]
	if for_rue and not _gate_open():
		out.append(GATE)
	return out


func _gate_open() -> bool:
	return lit[0] or arin_pos.distance_to(PLATE) < 8.0


## A tap's destination: arrived (and act, once), or stuck (say so, stop).
const ARRIVE := 0.05
const STUCK_TIME := 0.35
func _follow_tap(want: Vector2, moved: Vector2, delta: float) -> void:
	if rue_pos.distance_to(_walk_to) < ARRIVE:
		rue_pos = _walk_to if _free(_walk_to, _solids(true)) else rue_pos
		_walk_to = Vector2.INF
		_stuck_t = 0.0
		if _act_queued:
			_act_queued = false
			_interact()
		return
	# Something is in the way: a fence, a closed gate. No path-finding
	# here: she stops and shows it, instead of walking into it forever.
	_stuck_t = _stuck_t + delta if moved.length() < want.length() * 0.25 else 0.0
	if _stuck_t > STUCK_TIME:
		_walk_to = Vector2.INF
		_act_queued = false
		_stuck_t = 0.0
		_emote("rue", "?", 1.2)


## Rue's footprint (the same 8 x 6 the game's body uses at her feet).
const FOOT := Vector2(8, 6)
## No step longer than this is tested at once: thinner than any solid plus
## the footprint, so a long frame can't carry her through a gate.
const SUBSTEP := 2.0


func _free(at: Vector2, solids: Array[Rect2]) -> bool:
	var box := Rect2(at - FOOT * 0.5, FOOT)
	if not BOUNDS.encloses(box):
		return false
	for s in solids:
		if s.intersects(box):
			return false
	return true


## Moves by `step` in short sub-steps (swept: nothing thin is skipped),
## sliding along what blocks her. At a corner the axis with more of the
## motion wins, whichever axis it is, so mirrored approaches slide alike.
func _slide(from: Vector2, step: Vector2, for_rue: bool) -> Vector2:
	var solids := _solids(for_rue)
	var at := from
	var n := maxi(1, ceili(step.length() / SUBSTEP))
	var part := step / float(n)
	for i in n:
		var moved := false
		for f in [1.0, 0.5, 0.25]:
			var d: Vector2 = part * f
			if _free(at + d, solids):
				at += d
				moved = true
				break
			var x := Vector2(d.x, 0)
			var y := Vector2(0, d.y)
			var x_ok := d.x != 0.0 and _free(at + x, solids)
			var y_ok := d.y != 0.0 and _free(at + y, solids)
			if x_ok and (not y_ok or absf(d.x) >= absf(d.y)):
				at += x
				moved = true
				break
			if y_ok:
				at += y
				moved = true
				break
		if not moved:
			break
	return at


## A free spot about `dist` from `at` (right, left, above, below, in that
## order), clear of every solid and inside the square.
func _clear_spot_near(at: Vector2, dist: float) -> Vector2:
	for off: Vector2 in [Vector2(dist, -8), Vector2(-dist, -8), Vector2(0, -dist), Vector2(0, dist)]:
		var spot := at + off
		var box := Rect2(spot - Vector2(4, 3), Vector2(8, 6))
		if not BOUNDS.encloses(box):
			continue
		var clear := true
		for s in _solids(false):
			if s.intersects(box):
				clear = false
				break
		if clear:
			return spot
	return at + Vector2(dist, 0)


# --- Player 1: Arin, played by a person -------------------------------------------

## A person heading somewhere: a little past it first, then back (overshoot).
## `via`: points on the way (through the hedge's gap).
func _set_arin_goal(goal: Vector2, via: Array[Vector2] = []) -> void:
	_arin_path = via.duplicate()
	_arin_path.append(goal)
	_next_arin_point()


func _next_arin_point() -> void:
	var goal: Vector2 = _arin_path.pop_front()
	_arin_goal = goal
	var dir := (goal - arin_pos).normalized()
	var last := _arin_path.is_empty()
	_arin_overshoot = goal + dir * _fx_rng.randf_range(4.0, 9.0) if last and arin_pos.distance_to(goal) > 30.0 else goal


func _think_arin(delta: float) -> void:
	if not _arin_present:
		_arin_vel = Vector2.ZERO
		return
	var target := _arin_overshoot
	if arin_pos.distance_to(_arin_overshoot) < 2.0:
		_arin_overshoot = _arin_goal
		target = _arin_goal
		if arin_pos.distance_to(_arin_goal) < 2.0 and not _arin_path.is_empty():
			_next_arin_point()
			target = _arin_overshoot
	var speed := ARIN_SPEED
	if _escorting:
		speed = 24.0 if rue_pos.distance_to(arin_pos) <= HIDE_R else 0.0
	var to := target - arin_pos
	if to.length() > 1.5 and speed > 0.0:
		_arin_vel = to.normalized() * speed
		arin_pos = _slide(arin_pos, _arin_vel * delta, false)
	else:
		_arin_vel = Vector2.ZERO
		arin.facing = _facing_to(rue_pos - arin_pos)
	# Waiting for her too long: wave her over.
	if _arin_vel == Vector2.ZERO and rue_pos.distance_to(arin_pos) > 70.0 and fmod(beat_t, 6.0) < delta and beat <= Beat.L4:
		_emote("arin", "→", 1.4)
		arin.waving = true
	elif _arin_vel != Vector2.ZERO or rue_pos.distance_to(arin_pos) < 40.0:
		arin.waving = false


static func _facing_to(d: Vector2) -> Vector2:
	if d.length() < 1.0:
		return Vector2.DOWN
	if absf(d.x) > absf(d.y):
		return Vector2.RIGHT if d.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if d.y > 0.0 else Vector2.UP


func _emote(who: String, text: String, seconds: float) -> void:
	_emotes[who] = [text, seconds]


# --- the steps ------------------------------------------------------------------------

func _near_lantern(at: Vector2) -> int:
	for i in 5:
		if at.distance_to(LANTERNS[i]) < INTERACT_R + 6.0:
			return i
	return -1


func _interact() -> void:
	var i := _near_lantern(rue_pos + Vector2(0, -8))
	if i < 0:
		i = _near_lantern(rue_pos)
	if i < 0 or lit[i]:
		return
	match i:
		0:
			if beat == Beat.L1:
				_light(0)
		1:
			if beat == Beat.L2:
				_light(1)
		3:
			if beat == Beat.L4:
				_light(3)
		_:
			pass  # the maypole and the fifth are held, not pressed


func _light(i: int) -> void:
	lit[i] = true
	acted["lit_%d" % (i + 1)] = elapsed
	_bursts.append([LANTERNS[i], 0.0])
	_kick(0.45 if i < 4 else 0.7, 0.12 if i < 4 else 0.2, 0.18)
	_spark_burst(LANTERNS[i] + Vector2(0, -18), 18 if i < 4 else 30)
	Sfx.play("fragment", -8.0, 1.3 + i * 0.08)
	rue.play_habit()  # her celebration: two light taps, then the press
	for h in Opening.HABIT:
		get_tree().create_timer(h[0]).timeout.connect(func() -> void: Sfx.play("click", h[1], 1.3 if h[0] < 0.5 else 1.0, 0.0))
	if _arin_present and i < 4:
		arin.play_spin()
		_emote("arin", "yes!", 1.6)
	if i == 4:
		# Nobody is holding her controller, and the lantern that needed two
		# is lit. The music comes back as one phrase.
		acted["lit_by_herself"] = elapsed
		_music_to(-16.0, 1.6)
	PlaytestLog.mark("prologue: lantern %d" % (i + 1), "%.1f s" % elapsed)
	match i:
		0:
			_to_beat(Beat.L2)
		1:
			_to_beat(Beat.L3)
		2:
			_to_beat(Beat.L4)
		3:
			_to_beat(Beat.P1_LEFT)
	if i == 0:
		_story_break("first_light", [
			["PLAYER 2 · beside the television", "You always let me do the first one."],
			["PLAYER 1 · beside the television", "You always check whether I will."],
		])
	elif i == 2:
		_story_break("ritual", [
			["PLAYER 2 · beside the television", "Two taps. Then together. Same as last year."],
			["MIRA · from her window", "There. Now it looks like someone lives here."],
		])


func _to_beat(b: Beat) -> void:
	beat = b
	beat_t = 0.0
	_idle = 0.0
	match b:
		Beat.L2:
			_set_arin_goal(Vector2(240, 196))
		Beat.L3:
			_escorting = false
			_set_arin_goal(SPECIAL_LEFT)
		Beat.L4:
			_set_arin_goal(Vector2(GAP.x - 18, 284))
		Beat.P1_LEFT:
			var gx := (GAP.x + GAP.y) * 0.5
			_set_arin_goal(FIFTH_LEFT, [Vector2(gx, 318), Vector2(gx, 282)])
		Beat.P2_LEFT:
			_fifth = 0.0
			_alone_t = 0.0
			# Her last words beside the television, then her controller goes down.
			_story_break("goodbye", [
				["PLAYER 2 · beside the television", "The car's here."],
				["PLAYER 2 · beside the television", "I'll leave it on. Say bye to her for me."],
			])
		Beat.TIMELAPSE:
			acted["timelapse"] = elapsed
		Beat.LOAD:
			story.cancel()
			acted["load"] = elapsed
			_arin_present = true
			_arin_frozen = false
			_music_to(-16.0, 0.6)
			_rue_free = true
			if not lit[4]:
				lit[4] = true  # (skipped: it was lit, whoever lit it)
			for i in 4:
				lit[i] = false
			# The owner loads slot 1: Arin stands where the save put him.
			arin_pos = _clear_spot_near(rue_pos, 58.0)
			_set_arin_goal(arin_pos)
			arin.facing = Vector2.LEFT if arin_pos.x > rue_pos.x else Vector2.RIGHT
			Sfx.play("unload", -8.0)
		Beat.DONE:
			_finish()


func _update_beat(delta: float) -> void:
	match beat:
		Beat.L1:
			if arin_pos.distance_to(PLATE) < 8.0 and not acted.has("gate_open"):
				acted["gate_open"] = elapsed
				Sfx.play("click", -10.0, 0.8)
		Beat.L2:
			if not _escorting and arin_pos.distance_to(Vector2(240, 196)) < 3.0 and rue_pos.distance_to(arin_pos) < HIDE_R + 10.0:
				_escorting = true
				_set_arin_goal(LANTERNS[1] + Vector2(-12, 14))
			if _seen_by_tobben():
				caught += 1
				_emote("tobben", "!", 1.4)
				_show_toast("TOBBEN: No running near the fireworks!", Color(0.9, 0.75, 1.0), 2.2)
				Sfx.play("spotted", -12.0, 1.3)
				rue_pos = Vector2(226, 222)
				_escorting = false
				_set_arin_goal(Vector2(240, 196))
		Beat.L3:
			var arin_ready := arin_pos.distance_to(SPECIAL_LEFT) < 6.0
			var rue_ready := rue_pos.distance_to(SPECIAL_RIGHT) < 14.0
			var holding := _interact_held() or ((autoplay or _shown_how()) and rue_ready)
			if arin_ready and rue_ready and holding:
				_special = minf(1.0, _special + delta / SPECIAL_TIME)
				if not acted.has("special_start"):
					acted["special_start"] = elapsed
				if _special >= 1.0:
					_light(2)
			else:
				_special = maxf(0.0, _special - delta * 2.0)
		Beat.L4:
			# Player 1 shows how: waits for the light to turn, then crosses.
			if arin_pos.distance_to(Vector2(GAP.x - 18, 284)) < 3.0 and not _beam_on_gap(0.6) and _arin_path.is_empty():
				var gx := (GAP.x + GAP.y) * 0.5
				_set_arin_goal(Vector2(GAP.y + 26, 324), [Vector2(gx, 282), Vector2(gx, 318)])
			if _in_beam(rue_pos):
				caught += 1
				_show_toast("DAZZLED", Color(1.0, 0.95, 0.7), 1.2)
				Sfx.play("flicker", -12.0)
				rue_pos = Vector2(GAP.x - 10, 276)
		Beat.P1_LEFT:
			_update_fifth(delta)
		Beat.P2_LEFT:
			_update_impossible(delta)
		Beat.TIMELAPSE:
			if beat_t >= 8.0 and not _story_seen.has("message"):
				_story_break("message", [
					["MONTHS AFTER THE MOVE · a message outside the game", "PLAYER 2: still have my save?"],
					["PLAYER 1 · an unsent reply", "yes i still have your sa"],
				])
				return
			# (Arrived here without it lit: a test or a capture forcing the
			# years. It was lit, whoever lit it.)
			if not lit[4]:
				lit[4] = true
			if beat_t > 4.0 and beat_t < 15.0:
				for i in 4:
					if beat_t > 12.0 + i * 0.6:
						lit[i] = false
			if beat_t >= TIMELAPSE:
				_to_beat(Beat.LOAD)
		Beat.LOAD:
			if beat_t > 3.0 and not acted.has("skipped") and not _story_seen.has("owner"):
				_story_break("owner", [
					["THE OWNER · three years later", "> ...who's in my save?"],
					["RUE · nobody is holding her controller", "(i can still move.)"],
				])
				return
			if beat_t > 1.8:
				arin.facing = _facing_to(rue_pos - arin_pos)
			if beat_t > 2.6 and not acted.has("seen"):
				acted["seen"] = elapsed
				_emote("arin", "!", 2.0)
				arin.startled = 0.6
				Sfx.play("stinger", -10.0)
			if beat_t >= LOAD_TIME:
				_to_beat(Beat.DONE)


func _decide() -> void:
	acted["choice"] = elapsed
	_decided_at = beat_t
	rue.crouch = false
	if not replay:
		OwnerMemory.festival_choice = choice
	PlaytestLog.mark("prologue: the first decision", choice)


## Holding at the fifth: near it, and pressing (or played for them).
func _at_fifth() -> bool:
	return rue_pos.distance_to(LANTERNS[4] + Vector2(0, 16)) < 26.0


## The run for the fifth, the shared hold, Player 1's half stopping, and
## the decision (stay beside him, or try alone).
func _update_fifth(delta: float) -> void:
	var at := _at_fifth()
	if _p1_stopped_at < 0.0:
		# Together, like the maypole. The hold is played for them only when
		# nothing has been pressed for a while: this isn't the decision yet.
		var arin_ready := arin_pos.distance_to(FIFTH_LEFT) < 6.0
		var holding := at and (_interact_held() or autoplay or _idle > AUTO_AFTER)
		if arin_ready and holding:
			_fifth = minf(1.0, _fifth + delta / FIFTH_TIME)
			if _fifth >= P1_STOPS_AT:
				_stop_player_one()
		else:
			_fifth = maxf(0.0, _fifth - delta * 2.0)
		return
	# His half drains away; hers alone can't hold it past halfway.
	var trying := at and (_interact_held() or (autoplay and choice == ""))
	if trying and acted.has("p1_left"):
		_fifth = move_toward(_fifth, ALONE_CAP, delta / FIFTH_TIME)
	else:
		_fifth = maxf(0.0, _fifth - delta * 0.8)
	# The absence first; the words after.
	if not acted.has("p1_left") and elapsed - _p1_stopped_at >= ABSENCE_QUIET:
		acted["p1_left"] = elapsed
		_arin_present = false
		_show_toast("PLAYER 1 HAS LEFT THE SESSION", P1_COLOR, 3.2)
		_kick(0.3, 0.0, 0.0)
		Sfx.play("power_off", -10.0)
		PlaytestLog.mark("prologue: player 1 left", "%.1f s" % elapsed)
	if acted.has("p1_left") and choice == "":
		if rue_pos.distance_to(arin_pos) < HIDE_R and not trying:
			_decided_t += delta
			rue.crouch = true
			if _decided_t > 2.5:
				choice = "stayed"
				_decide()
		else:
			_decided_t = 0.0
			rue.crouch = false
		if trying:
			_alone_t += delta
			if _alone_t > TRY_TIME:
				choice = "tried"
				_emote("rue", "...", 1.6)
				_decide()
		if elapsed - float(acted.p1_left) > DECIDE_TIME and choice == "":
			choice = "idle"
			_decide()
	if choice != "" and _decided_at >= 0.0 and beat_t - _decided_at > 1.6:
		_to_beat(Beat.P2_LEFT)


## Player 1 stops: no notification yet. Arin freezes mid-breath, the music
## cuts, and the camera stops drifting.
func _stop_player_one() -> void:
	_p1_stopped_at = elapsed
	acted["p1_stopped"] = elapsed
	_arin_frozen = true
	arin.waving = false
	_arin_vel = Vector2.ZERO
	_music_to(-60.0, 0.35)
	_hold_down = false
	PlaytestLog.mark("prologue: player 1 stopped", "%.1f s" % elapsed)


## After Player 2 leaves: nobody is holding anything. The player holds [E]
## at the fifth, and Rue lights it alone.
func _update_impossible(delta: float) -> void:
	if not acted.has("p2_left") and beat_t > 0.25:
		acted["p2_left"] = elapsed
		_show_toast("PLAYER 2 HAS LEFT THE SESSION", P2_COLOR, 3.0)
		_kick(0.5, 0.0, 0.0)
		Sfx.play("power_off", -14.0, 1.2)
		PlaytestLog.mark("prologue: player 2 left", choice)
	if lit[4]:
		if elapsed - float(acted.get("lit_5", elapsed)) > 2.5:
			_to_beat(Beat.TIMELAPSE)
		return
	if beat_t < IMPOSSIBLE_PROMPT:
		return
	var holding := _at_fifth() and (_interact_held() or autoplay or _shown_how())
	if holding:
		_fifth = minf(1.0, _fifth + delta / (FIFTH_TIME * 1.25))
		if _fifth >= 1.0:
			_light(4)
	else:
		_fifth = maxf(0.0, _fifth - delta * 0.8)


func _music_to(db: float, seconds: float) -> void:
	if _music == null:
		return
	var tw := create_tween()
	tw.tween_property(_music, "volume_db", db, seconds)


func _story_break(id: String, pages: Array) -> void:
	if _story_seen.has(id):
		return
	_story_seen[id] = true
	_walk_to = Vector2.INF
	_act_queued = false
	_hold_down = false
	_touch.cancel_touches()
	_touch.buttons_enabled = false
	story.open(id, pages)
	PlaytestLog.mark("prologue: story", id)


func _remember_story(id: String, speaker: String, text: String) -> void:
	if not replay:
		OwnerMemory.record_read("festival:" + id, "note", "Festival · " + id.replace("_", " "), "festival", [speaker + ": " + text])


## When the decision was made (beat time): Player 2 leaves a moment later.
var _decided_at := -1.0


## Tobben's look (lantern 2): a cone toward the lane, sweeping.
func _look_angle() -> float:
	return PI * 0.5 + sin(elapsed * TAU / LOOK_PERIOD) * 1.05


func _seen_by_tobben() -> bool:
	var d := rue_pos - TOBBEN_AT
	if d.length() > LOOK_RANGE or d.length() < 6.0:
		return false
	if absf(wrapf(d.angle() - _look_angle(), -PI, PI)) > LOOK_HALF:
		return false
	return rue_pos.distance_to(arin_pos) > HIDE_R  # beside Arin: hidden


## The spotlight (lantern 4): its angle sweeps across the hedge's gap.
func _beam_angle() -> float:
	var gap := (Vector2((GAP.x + GAP.y) * 0.5, (HEDGE_Y.x + HEDGE_Y.y) * 0.5) - TOWER).angle()
	return gap + sin(elapsed * TAU / BEAM_PERIOD) * 0.9


func _beam_on_gap(margin := 0.0) -> bool:
	var gap := (Vector2((GAP.x + GAP.y) * 0.5, (HEDGE_Y.x + HEDGE_Y.y) * 0.5) - TOWER).angle()
	return absf(wrapf(_beam_angle() - gap, -PI, PI)) < 0.3 + margin * 0.2


func _in_beam(at: Vector2) -> bool:
	if lit[3] or beat != Beat.L4:
		return false
	# Only the gap is watched: waiting beside it is safe.
	if at.x < GAP.x - 6.0 or at.x > GAP.y + 6.0 or at.y < HEDGE_Y.x - 8.0 or at.y > HEDGE_Y.y + 8.0:
		return false
	var d := at - TOWER
	if d.length() > 120.0:
		return false
	return absf(wrapf(d.angle() - _beam_angle(), -PI, PI)) < 0.16


# --- autoplay: the next step, done for the player ------------------------------------

func _auto_target() -> Vector2:
	match beat:
		Beat.L1:
			return LANTERNS[0] + Vector2(0, 14) if _gate_open() else Vector2(88, 190)
		Beat.L2:
			return arin_pos + Vector2(-8, 6) if rue_pos.distance_to(LANTERNS[1]) > 26.0 else LANTERNS[1] + Vector2(0, 14)
		Beat.L3:
			return SPECIAL_RIGHT
		Beat.L4:
			if rue_pos.y < HEDGE_Y.x - 4.0:
				if _beam_on_gap(1.2):
					return Vector2(GAP.x - 10, 276)
				return Vector2((GAP.x + GAP.y) * 0.5, 320)
			return LANTERNS[3] + Vector2(0, -14) if LANTERNS[3].y > 320 else LANTERNS[3] + Vector2(0, 14)
		Beat.P1_LEFT, Beat.P2_LEFT:
			return FIFTH_RIGHT
	return rue_pos


func _auto_dir() -> Vector2:
	var to := _auto_target() - rue_pos
	if to.length() < 3.0:
		return Vector2.ZERO
	# Round the hedge through its gap.
	if beat == Beat.L4 and rue_pos.y < HEDGE_Y.x and _auto_target().y > HEDGE_Y.y:
		var gx := (GAP.x + GAP.y) * 0.5
		if absf(rue_pos.x - gx) > 3.0:
			return Vector2(signf(gx - rue_pos.x), 0.2).normalized()
		return Vector2.DOWN
	if beat in [Beat.P1_LEFT, Beat.P2_LEFT] and rue_pos.y > HEDGE_Y.y and _auto_target().y < HEDGE_Y.x:
		var gx2 := (GAP.x + GAP.y) * 0.5
		if absf(rue_pos.x - gx2) > 3.0:
			return Vector2(signf(gx2 - rue_pos.x), -0.2).normalized()
		return Vector2.UP
	return to.normalized()


func _auto_act() -> bool:
	if not (autoplay or _shown_how()):
		return false
	var i := _near_lantern(rue_pos + Vector2(0, -8))
	if i < 0:
		i = _near_lantern(rue_pos)
	return i >= 0 and not lit[i] and i != 2 and i != 4


# --- HUD --------------------------------------------------------------------------------

func _show_toast(text: String, color: Color, seconds: float) -> void:
	_toast = text
	_toast_color = color
	_toast_t = seconds


func step_hint() -> String:
	var press := "tap" if Settings.using_touch else Settings.glyph("interact")
	match beat:
		Beat.L1:
			if not acted.has("control"):
				return "%s to move" % ("drag" if Settings.using_touch else Settings.glyph("move").to_lower())
			return "Arin holds the plate: go through the gate and light it  [%s]" % press if _gate_open() else "Arin's heading for the plate"
		Beat.L2:
			return "Tobben's watching: stay right beside Arin while his look sweeps past"
		Beat.L3:
			return "the maypole: stand on the other side and hold [%s] together" % press
		Beat.L4:
			return "cross the gap when the spotlight turns away"
		Beat.P1_LEFT:
			if _p1_stopped_at >= 0.0 and not acted.has("p1_left"):
				return ""  # his absence, before any words
			if acted.has("p1_left"):
				if choice == "" and _fifth >= ALONE_CAP - 0.01:
					return "it needs two"
				return "stay beside him   ·   or try alone  [hold %s]" % press if choice == "" else ""
			return "the last lantern, by the well: both of you hold [%s]" % press
		Beat.P2_LEFT:
			if not lit[4] and beat_t > IMPOSSIBLE_HINT:
				return "hold [%s] at the lantern" % press
	return ""


func _update_hud(delta: float) -> void:
	var lit_n := lit.count(true)
	var then := beat <= Beat.P2_LEFT
	_banner.visible = then
	_quest.visible = then
	_pips.visible = then
	var pips := ""
	for i in 5:
		pips += ("◆" if lit[i] else "◇") + (" " if i < 4 else "")
	_pips.text = pips
	if _toast_label.text != _toast:
		_toast_label.text = _toast
		var w := _toast_label.get_theme_font("font").get_string_size(_toast, HORIZONTAL_ALIGNMENT_LEFT, -1, _toast_label.get_theme_font_size("font_size")).x + 16.0
		_toast_label.size.x = w
		_toast_label.position.x = 320.0 - w * 0.5
	_toast_label.visible = _toast != ""
	_toast_label.add_theme_color_override("font_color", _toast_color)
	_toast_label.modulate.a = clampf(_toast_t * 2.0, 0.0, 1.0)
	var hint := step_hint() if (beat_t > 1.2 or not acted.has("control")) else ""
	_hint.text = hint
	_hint.modulate.a = move_toward(_hint.modulate.a, 1.0 if hint != "" else 0.0, delta * 3.0)
	var how := "hold the skip chip" if Settings.using_touch else "hold Esc"
	_skip_label.text = ("%s to skip  %s" % [how, "▮".repeat(int(_skip_t / SKIP_HOLD * 6.0))]) if beat < Beat.LOAD else ""
	_skip_label.modulate.a = 0.75 if (lit_n >= 1 or elapsed > 8.0 or _skip_t > 0.0) else 0.0
	_chip.visible = Settings.using_touch and beat < Beat.LOAD
	# The present: a short, diegetic boot, and the owner's first words.
	var lines: Array[String] = []
	if beat == Beat.LOAD:
		if beat_t > 0.3:
			lines.append("LOADING SLOT 1 · ARIN")
		if beat_t > 0.9:
			lines.append("PLAYER 2 · [DELETED 3 YEARS AGO]")
		if beat_t > 1.6:
			lines.append("[!] 1 UNRECOGNISED ENTITY")
	_diag.text = "\n".join(lines)
	_owner_line.text = "> ...who's in my save?" if beat == Beat.LOAD and beat_t > 3.0 else ""
	var years := ""
	if beat == Beat.TIMELAPSE and beat_t > 15.0:
		years = "3 YEARS LATER"
	_years.text = years
	_years.modulate.a = clampf((beat_t - 15.0) * 2.0, 0.0, 1.0) if beat == Beat.TIMELAPSE else 0.0


# --- drawing ------------------------------------------------------------------------------

## 0 = afternoon, 1 = sundown (the lanterns move the sun), 2 = night, 3 = now.
func _sky_t() -> float:
	match beat:
		Beat.TIMELAPSE:
			return 1.0 + clampf(beat_t / 4.0, 0.0, 1.0)
		Beat.LOAD, Beat.DONE:
			return 3.0
	return minf(1.0, lit.count(true) / 4.0)


func _draw() -> void:
	var k := _sky_t()
	_draw_sky(k)
	_draw_houses(k)
	_draw_ground(k)
	# Bunting across the square while the festival lasts.
	var bunting := 1.0 if beat < Beat.TIMELAPSE else clampf(1.0 - (beat_t - 4.0) / 4.0, 0.0, 1.0)
	if beat >= Beat.LOAD:
		bunting = 0.0
	if bunting > 0.0:
		for row in 2:
			var y0 := 92.0 + row * 70.0
			draw_polyline(PackedVector2Array([Vector2(16, y0), Vector2(320, y0 + 18), Vector2(624, y0)]), Color(0.2, 0.15, 0.1, 0.6 * bunting), 0.6)
			for i in 20:
				var t := i / 19.0
				var at := Vector2(16, y0).lerp(Vector2(624, y0), t) + Vector2(0, sin(t * PI) * 18.0)
				var flag: Color = [Color("d8463a"), Color("f0c050"), Color("5aa0c8"), Color("8ab05a")][i % 4]
				# Each flag flutters in the breeze (still when calm).
				var tip := Vector2(3, 6) if calm() else Vector2(3.0 + sin(elapsed * 4.0 + i * 1.3 + row) * 1.6, 6.0 - absf(sin(elapsed * 3.1 + i)) * 1.2)
				draw_colored_polygon(PackedVector2Array([at, at + Vector2(6, 0), at + tip]), Color(flag, bunting))
	_draw_board(k)
	_draw_fence()
	# Things in depth order.
	var items: Array = []
	items.append([STALL.end.y, "stall"])
	items.append([WELL.end.y, "well"])
	items.append([HEDGE_Y.y, "hedge"])
	for i in 5:
		items.append([LANTERNS[i].y + 6, "lantern", i])
	items.append([rue_pos.y, "rue"])
	items.append([arin_pos.y, "arin"])
	if _npcs_alpha() > 0.0:
		items.append([TOBBEN_AT.y, "tobben"])
		items.append([306.0, "wren"])
	items.append([PLATE.y - 4, "plate"])
	items.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for it in items:
		match it[1]:
			"stall":
				_draw_stall(k)
			"well":
				_draw_well(k)
			"hedge":
				_draw_hedge(k)
			"lantern":
				_draw_lantern(it[2])
			"plate":
				_draw_plate()
			"rue":
				_draw_figure(rue, rue_pos, "rue")
			"arin":
				_draw_figure(arin, arin_pos, "arin")
			"tobben":
				tobben.facing = Vector2.DOWN
				tobben.draw(self, {"offset": TOBBEN_AT + Vector2(0, -6), "scale": 1.2, "alpha": _npcs_alpha()})
				_draw_emote("tobben", TOBBEN_AT + Vector2(0, -52))
			"wren":
				wren.facing = Vector2.RIGHT
				wren.draw(self, {"offset": Vector2(38, 300), "scale": 1.2, "alpha": _npcs_alpha()})
	# Mira at her window, leaning out (the third house).
	if _npcs_alpha() > 0.0:
		var win := Rect2(170, 34, 32, 26)
		draw_rect(win.grow(2.0), Color("5a3a2a"))
		draw_rect(win, Color(1.0, 0.82, 0.5, 0.9))
		mira.facing = Vector2.DOWN
		mira.draw(self, {"offset": Vector2(186, 72), "scale": 0.8, "alpha": _npcs_alpha()})
		draw_rect(Rect2(win.position.x - 3, win.end.y - 2, win.size.x + 6, 4), Color("6a4a34"))  # the sill
	if beat == Beat.L2:
		_draw_look()
	if beat == Beat.L4:
		_draw_beam()
	if beat == Beat.L3:
		_draw_special()
	if _fifth_ring_shown():
		_draw_fifth()
	for b in _bursts:
		_draw_burst(b[0], b[1])
	if beat == Beat.TIMELAPSE:
		_draw_timelapse()
	if beat >= Beat.LOAD:
		_draw_load()
	_draw_motes()
	_draw_vignette()
	# The skip chip (touch).


## The sky: a gradient from the horizon up, a low sun with its glow, and
## (at night and after) a few stars.
func _draw_sky(k: float) -> void:
	var top: Color
	var low: Color
	if k <= 1.0:
		top = Color("8ab8e0").lerp(Color("e0906a"), k)
		low = Color("ffe0a8").lerp(Color("ffb070"), k)
	elif k <= 2.0:
		top = Color("e0906a").lerp(Color("141a34"), k - 1.0)
		low = Color("ffb070").lerp(Color("2a3050"), k - 1.0)
	else:
		top = Color("26304a")
		low = Color("4a5a78")
	var bands := 12
	for i in bands:
		var t := float(i) / bands
		draw_rect(Rect2(0, t * 80.0, 640, 80.0 / bands + 1), top.lerp(low, t))
	# Clouds drifting over the rooftops, lit by the low sun.
	var cloud := Color(1.0, 0.96, 0.9, 0.55).lerp(Color(1.0, 0.7, 0.55, 0.5), clampf(k, 0.0, 1.0))
	if k > 1.6:
		cloud = Color(0.5, 0.55, 0.7, 0.25)
	for c in 4:
		var cx := fmod(c * 190.0 + elapsed * (5.0 + c * 1.5), 820.0) - 90.0
		var cy := 14.0 + (c % 2) * 14.0
		for b in 4:
			draw_circle(Vector2(cx + b * 12.0, cy + absf(b - 1.5) * 2.0), 9.0 - absf(b - 1.5) * 2.0, cloud)
	if k < 1.9:
		var sun := Vector2(520, 30 + k * 40.0)
		for r in [60.0, 36.0, 20.0]:
			draw_circle(sun, r, Color(1.0, 0.9, 0.6, 0.08 + (0.06 if r < 30 else 0.0)))
		draw_circle(sun, 9.0, Color(1.0, 0.95, 0.8, 0.95 - k * 0.3))
	if k > 1.4:
		for i in 24:
			var at := Vector2(float((i * 211) % 640), float((i * 97) % 60) + 4)
			draw_circle(at, 0.7, Color(1, 1, 1, 0.5 * clampf(k - 1.4, 0.0, 1.0)))


## The houses round the square: walls with a lit side and a shaded side,
## tiled roofs, windows warm or dark. Mira's (the second) has her window.
func _draw_houses(k: float) -> void:
	var then := k < 3.0
	for i in 8:
		var x := 18.0 + i * 80.0
		var h := 36.0 + float((i * 37) % 21)
		var base := 76.0
		var wall := Color("c8a888").lerp(Color("6a5a64"), clampf(k - 0.8, 0.0, 1.0)) if then else Color("4a4e5c")
		var body := Rect2(x, base - h, 66, h)
		draw_rect(body, wall)
		draw_rect(Rect2(x + 44, base - h, 22, h), wall.darkened(0.18))  # the side away from the sun
		var roof := Color("9a4a3a").lerp(Color("4a2a34"), clampf(k - 0.8, 0.0, 1.0)) if then else Color("2c3040")
		var peak := Vector2(x + 33, base - h - 20)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 5, base - h + 2), peak, Vector2(x + 71, base - h + 2)]), roof)
		draw_colored_polygon(PackedVector2Array([peak, Vector2(x + 71, base - h + 2), Vector2(x + 33, base - h + 2)]), roof.darkened(0.15))
		for row in 3:
			draw_line(Vector2(x + 2 + row * 4, base - h - 4 - row * 5), Vector2(x + 64 - row * 4, base - h - 4 - row * 5), roof.darkened(0.25), 0.5)
		var lit_win := Color(1.0, 0.82, 0.48) if k > 0.6 and k < 2.6 else Color(0.75, 0.85, 0.95, 0.7)
		if not then:
			lit_win = Color(0.12, 0.14, 0.2)
		for wx: float in [x + 10, x + 46]:
			var w := Rect2(wx, base - h + 10, 10, 9)
			draw_rect(w.grow(1.0), Color("3a2a24"))
			draw_rect(w, lit_win)
			draw_line(Vector2(w.get_center().x, w.position.y), Vector2(w.get_center().x, w.end.y), Color("3a2a24"), 0.6)
		draw_rect(Rect2(x + 28, base - 14, 10, 14), Color("5a3a2a"))  # the door
		draw_rect(Rect2(x, base - 2, 66, 3), Color(0, 0, 0, 0.25))  # where it meets the ground


## The ground: grass with tufts and flowers, the cobbled cross with its
## stones, soft shadow along the houses. Warm then, cold now.
func _draw_ground(k: float) -> void:
	var then := k < 3.0
	var grass := Color("7a9a50").lerp(Color("2a3a3a"), clampf(k - 1.0, 0.0, 1.0)) if then else Color("3a4848")
	draw_rect(Rect2(0, 74, 640, 286), grass)
	draw_rect(Rect2(0, 74, 640, 10), Color(0, 0, 0, 0.18))
	for i in 220:
		var at := Vector2(float((i * 131) % 640), 84.0 + float((i * 71) % 270))
		var shade := grass.lightened(0.08) if i % 3 else grass.darkened(0.12)
		var sway := 0.0 if calm() else sin(elapsed * 1.6 + at.x * 0.045 + at.y * 0.02) * 0.9
		draw_line(at, at + Vector2(-1 + sway, -3), shade, 0.8)
		draw_line(at, at + Vector2(1.2 + sway, -2.6), shade, 0.8)
		if then and i % 17 == 0:
			draw_circle(at + Vector2(0, -3), 1.1, [Color("f8e8a0"), Color("f0a0b0"), Color("ffffff")][i % 3])
	var cobble := Color("a8987e").lerp(Color("4a4a58"), clampf(k - 1.0, 0.0, 1.0)) if then else Color("464a56")
	for r: Rect2 in [Rect2(0, 186, 640, 22), Rect2(300, 74, 22, 286)]:
		draw_rect(r, cobble.darkened(0.12))
		var y := r.position.y + 2.0
		var row := 0
		while y < r.end.y - 1.0:
			var x := r.position.x + (3.0 if row % 2 else 0.0)
			while x < r.end.x - 1.0:
				var w := 6.0 + float(int(x * 7.0 + y) % 3)
				draw_rect(Rect2(x + 0.5, y, minf(w - 1.0, r.end.x - x - 0.5), 4.5), cobble.lightened(0.05 if (int(x) + row) % 2 else 0.0))
				x += w
			y += 5.5
			row += 1


## A soft darkening toward the edges of the frame (drawn last, screen-wide).
func _draw_vignette() -> void:
	var view := Vector2(640, 360) / zoom
	var tl := -position / zoom
	var c := Color(0.05, 0.03, 0.08, 0.22 if beat < Beat.LOAD else 0.32)
	var e := 18.0 / zoom
	for i in 4:
		var a := Color(c, c.a * (1.0 - i / 4.0))
		draw_rect(Rect2(tl.x, tl.y + i * e, view.x, e), a)
		draw_rect(Rect2(tl.x, tl.y + view.y - (i + 1) * e, view.x, e), a)


## How present the townsfolk are: full at the festival, thinning as time
## passes, gone in the present.
func _npcs_alpha() -> float:
	match beat:
		Beat.TIMELAPSE:
			return clampf(1.0 - beat_t / 14.0, 0.0, 1.0) * (0.6 + 0.4 * absf(sin(beat_t * 1.3)) if not calm() else 1.0)
		Beat.LOAD, Beat.DONE:
			return 0.0
	return 1.0


func _draw_board(k: float) -> void:
	var at := Rect2(198, 84, 40, 22)
	draw_rect(Rect2(at.position + Vector2(18, 20), Vector2(4, 14)), Color("5a4030"))
	draw_rect(at, Color("7a5a40"))
	draw_rect(at.grow(-2), Color("e8dcc4") if k < 3.0 else Color("8a8a96"))
	var text := "FESTIVAL\nTODAY!"
	if beat == Beat.TIMELAPSE:
		text = "FESTIVAL\nTODAY!" if beat_t < 5.0 else ("CANCELLED" if beat_t < 7.5 else "")
	elif beat >= Beat.LOAD:
		text = ""
	var y := at.position.y + 10.0
	for line in text.split("\n"):
		draw_string(UiStyle.system_font(), Vector2(at.position.x + 4, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("5a2a20"))
		y += 8.0


func _draw_fence() -> void:
	var wood := Color("8a6440")
	for x in range(int(FENCE.position.x), int(FENCE.end.x) + 1, 6):
		var gate := x > GATE.position.x and x < GATE.end.x
		if gate and _gate_open():
			continue
		for y_edge: float in [FENCE.position.y, FENCE.end.y]:
			if y_edge == FENCE.position.y or not gate or not _gate_open():
				draw_rect(Rect2(x - 1, y_edge - 8, 2, 10), wood.darkened(0.1 if gate else 0.0))
	for y in range(int(FENCE.position.y), int(FENCE.end.y) + 1, 6):
		draw_rect(Rect2(FENCE.position.x - 1, y - 8, 2, 10), wood)
		draw_rect(Rect2(FENCE.end.x - 1, y - 8, 2, 10), wood)
	draw_line(FENCE.position + Vector2(0, -5), Vector2(FENCE.end.x, FENCE.position.y - 5), wood.lightened(0.1), 1.0)


func _draw_plate() -> void:
	var on := arin_pos.distance_to(PLATE) < 8.0 or lit[0]
	draw_rect(Rect2(PLATE - Vector2(9, 5), Vector2(18, 10)), Color("6a6a6a"))
	draw_rect(Rect2(PLATE - Vector2(7, 3.5 - (1.0 if on else 0.0)), Vector2(14, 7)), Color("c8a040") if on else Color("9a9a9a"))


func _draw_stall(k: float) -> void:
	var r := STALL
	var col := Color("6b5040") if k < 3.0 else Color("3a3440")
	draw_rect(r, col)
	for i in 6:
		var a := Rect2(r.position + Vector2(i * r.size.x / 6.0, -8), Vector2(r.size.x / 6.0, 10))
		draw_rect(a, (Color("a8443a") if i % 2 == 0 else Color("e8dcc4")) if k < 3.0 else Color("4a4652"))
	if k < 2.5:
		for i in 7:
			draw_circle(Vector2(r.position.x + 8 + i * 12, r.end.y - 6), 2.6, [Color("f0c050"), Color("d8463a"), Color("5aa0c8")][i % 3])  # the fireworks


func _draw_well(k: float) -> void:
	var stone := Color("8a8478") if k < 3.0 else Color("4a4a56")
	draw_rect(WELL, stone)
	draw_rect(WELL.grow(-4), Color("1a1a22"))
	draw_rect(Rect2(WELL.position + Vector2(0, -14), Vector2(3, 16)), Color("5a4030"))
	draw_rect(Rect2(Vector2(WELL.end.x - 3, WELL.position.y - 14), Vector2(3, 16)), Color("5a4030"))
	draw_rect(Rect2(WELL.position + Vector2(-2, -16), Vector2(WELL.size.x + 4, 3)), Color("6a4a30"))


func _draw_hedge(k: float) -> void:
	var g := Color("3a6a3a") if k < 3.0 else Color("24343a")
	draw_rect(Rect2(372, HEDGE_Y.x - 6, GAP.x - 372, HEDGE_Y.y - HEDGE_Y.x + 6), g)
	draw_rect(Rect2(GAP.y, HEDGE_Y.x - 6, BOUNDS.end.x - GAP.y, HEDGE_Y.y - HEDGE_Y.x + 6), g)
	for x in range(372, int(BOUNDS.end.x), 9):
		if x > GAP.x - 4 and x < GAP.y:
			continue
		draw_circle(Vector2(x, HEDGE_Y.x - 6), 5.0, g.lightened(0.08))
	# The spotlight tower.
	draw_rect(Rect2(TOWER + Vector2(-3, -2), Vector2(6, 40)), Color("4a4a52"))
	draw_circle(TOWER, 5.0, Color("c8c0a8") if beat == Beat.L4 else Color("5a5a62"))


func _draw_lantern(i: int) -> void:
	var at := LANTERNS[i]
	var big := i == 2
	var post := Color("4a3424")
	var h := 30.0 if big else 20.0
	draw_rect(Rect2(at + Vector2(-1.5, -h + 10), Vector2(3, h)), post)
	var g := _glow[i]
	var body := Rect2(at + Vector2(-6, -h) * (1.3 if big else 1.0), Vector2(12, 12) * (1.3 if big else 1.0))
	if g > 0.0:
		var flick := 1.0 if calm() else 0.9 + 0.1 * sin(elapsed * 9.0 + i)
		for r in [40.0, 26.0, 14.0]:
			draw_circle(body.get_center(), r * (1.3 if big else 1.0), Color(1.0, 0.75, 0.35, 0.07 * g * flick))
	if g > 0.0:
		# A warm pool of light on the ground under it.
		var pool := 0.12 * g * (1.0 if calm() else 0.85 + 0.15 * sin(elapsed * 7.0 + i * 2.0))
		draw_set_transform(at + Vector2(0, 8), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 34.0 * (1.3 if big else 1.0), Color(1.0, 0.78, 0.4, pool))
		draw_set_transform(Vector2.ZERO)
	draw_rect(body, Color("a8443a").lerp(Color("ffd890"), g))
	if g > 0.5 and not calm():
		# The flame inside, dancing.
		var c := body.get_center()
		var fl := sin(elapsed * 13.0 + i) * 0.8
		draw_colored_polygon(PackedVector2Array([c + Vector2(-2.2, 3), c + Vector2(fl, -4.5), c + Vector2(2.2, 3)]), Color(1.0, 0.95, 0.7, 0.9 * g))
	draw_rect(body, Color("2a1a14"), false, 1.0)
	draw_line(body.position + Vector2(body.size.x * 0.5, 0), body.position + Vector2(body.size.x * 0.5, body.size.y), Color("2a1a14", 0.5), 0.6)
	# Which one is next: a soft ring, until it's lit.
	var next := _next_lantern()
	if next == i and beat <= Beat.P1_LEFT and not lit[i]:
		var pulse := 0.5 if calm() else 0.4 + 0.3 * absf(sin(elapsed * 3.0))
		draw_arc(body.get_center(), 12.0 * (1.3 if big else 1.0), 0, TAU, 24, Color(1.0, 0.9, 0.6, pulse), 1.0)


func _next_lantern() -> int:
	match beat:
		Beat.L1:
			return 0
		Beat.L2:
			return 1
		Beat.L3:
			return 2
		Beat.L4:
			return 3
		Beat.P1_LEFT:
			return 4
	return -1


func _draw_figure(f: HeroFigure, at: Vector2, who: String) -> void:
	f.left_running = who == "rue" and beat >= Beat.P2_LEFT and not calm()
	f.draw(self, {"offset": at + Vector2(0, -6), "scale": 1.35})
	var top := at + Vector2(0, -6 + (PixelCharacter.FEET_Y - f.height()) * 1.35 - 12.0)
	# Standing close, the one further back carries their tag higher.
	if rue_pos.distance_to(arin_pos) < 60.0:
		var behind := rue_pos.y < arin_pos.y if who == "rue" else arin_pos.y <= rue_pos.y
		if behind:
			top.y -= 11.0
	# Arin cheers beside his head, so it never lands on her tag when they stand together.
	_draw_emote(who, top + (Vector2(30, 6) if who == "arin" else Vector2(0, -14 - 8.0 * Settings.text_scale())))
	# Who drives whom: a nameplate with a shape as well as a colour. Then, the
	# game's own player tags; now, the loaded save's labels.
	var font := UiStyle.system_font()
	var text := ""
	var col := Color.WHITE
	var shape := ""
	if who == "rue":
		if beat <= Beat.P1_LEFT:
			# "(you)" until the first lantern: who the stick moves.
			text = "P2 · RUE  (you)" if not lit[0] else "P2 · RUE"
			col = P2_COLOR
			shape = "circle"
		elif beat == Beat.P2_LEFT:
			# Her controller is down: the tag empties.
			text = "P2 · —" if acted.has("p2_left") else "P2 · RUE"
			col = Color(P2_COLOR, clampf(1.0 - beat_t / 2.0, 0.35, 1.0))
		elif beat >= Beat.LOAD:
			text = "UNKNOWN ENTITY"
			col = SYSTEM_COLOR
	else:
		if beat < Beat.LOAD:
			text = "P1 · ARIN" if _arin_present else "P1 · —"
			col = P1_COLOR if _arin_present else Color(0.6, 0.62, 0.68)
			shape = "triangle" if _arin_present else ""
		else:
			text = "SLOT 1 · ARIN"
			col = OWNER_COLOR
	if text == "":
		return
	# Larger text grows the tags too (they're drawn, not Labels).
	var fs := roundi(8 * Settings.text_scale())
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var pad := 4.0 + (8.0 if shape != "" else 0.0)
	var plate := Rect2(top + Vector2(-(size.x + pad) * 0.5 - 2.0, -size.y + 2.0), Vector2(size.x + pad + 4.0, size.y + 2.0))
	# The fifth lantern's hold ring is the thing to watch there: a tag that
	# would cover it steps aside (Rue's to the right, Arin's to the left).
	if _fifth_ring_shown():
		var ring := Rect2(LANTERNS[4] + Vector2(-21, -51), Vector2(42, 42))
		if plate.intersects(ring):
			var dx := (ring.end.x + 2.0 - plate.position.x) if who == "rue" else (ring.position.x - 2.0 - plate.end.x)
			plate.position.x += dx
			top.x += dx
	draw_rect(plate, Color(0.05, 0.04, 0.08, 0.55 * col.a))
	draw_rect(Rect2(plate.position.x, plate.end.y - 1.0, plate.size.x, 1.0), Color(col, 0.8 * col.a))  # an underline in their colour
	var text_x := plate.position.x + 2.0 + (8.0 if shape != "" else 0.0)
	draw_string(font, Vector2(text_x, top.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	var mark := Vector2(plate.position.x + 6.0, plate.get_center().y)
	if shape == "circle":
		draw_circle(mark, 2.4, col)
	elif shape == "triangle":
		draw_colored_polygon(PackedVector2Array([mark + Vector2(0, -3), mark + Vector2(3, 2.5), mark + Vector2(-3, 2.5)]), col)


func _draw_emote(who: String, at: Vector2) -> void:
	if not _emotes.has(who):
		return
	var text: String = _emotes[who][0]
	var k := Settings.text_scale()
	var w := 6.0 + text.length() * 6.0 * k
	draw_rect(Rect2(at - Vector2(w * 0.5, 8 * k), Vector2(w, 11 * k)), Color(0.97, 0.95, 0.9, 0.95))
	draw_string(UiStyle.system_font(), at + Vector2(-w * 0.5 + 3, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(9 * k), Color(0.15, 0.1, 0.1))


func _draw_look() -> void:
	var a := _look_angle()
	var pts := PackedVector2Array([TOBBEN_AT])
	for i in 9:
		var t := a - LOOK_HALF + LOOK_HALF * 2.0 * i / 8.0
		pts.append(TOBBEN_AT + Vector2(cos(t), sin(t)) * LOOK_RANGE)
	draw_colored_polygon(pts, Color(1.0, 0.95, 0.6, 0.16))
	# Arin's cover: the ring she stands in to be hidden.
	draw_arc(arin_pos, HIDE_R, 0, TAU, 24, Color(0.55, 0.72, 1.0, 0.45), 1.0)


func _draw_beam() -> void:
	var a := _beam_angle()
	var pts := PackedVector2Array([TOWER])
	for i in 5:
		var t := a - 0.16 + 0.32 * i / 4.0
		pts.append(TOWER + Vector2(cos(t), sin(t)) * 120.0)
	draw_colored_polygon(pts, Color(1.0, 0.97, 0.8, 0.22 if not calm() else 0.3))


func _draw_special() -> void:
	var c := LANTERNS[2] + Vector2(0, -24)
	draw_arc(c, 18.0, -PI * 0.5, -PI * 0.5 + TAU * _special, 32, Color(1.0, 0.85, 0.4, 0.9), 2.0)
	for at in [SPECIAL_LEFT, SPECIAL_RIGHT]:
		draw_arc(at, 9.0, 0, TAU, 20, Color(1.0, 0.9, 0.6, 0.5), 1.0)


func _fifth_ring_shown() -> bool:
	return beat == Beat.P1_LEFT or (beat == Beat.P2_LEFT and not lit[4] and beat_t >= IMPOSSIBLE_PROMPT)


## The fifth's hold: two halves, his (blue, left) and hers (amber, right).
## After he stops, his half drains; alone, hers stalls at halfway and
## flickers. After both have left, only a faint [E] remains.
func _draw_fifth() -> void:
	var c := LANTERNS[4] + Vector2(0, -30)
	if beat == Beat.P2_LEFT:
		var pulse := 0.35 if calm() else 0.25 + 0.2 * absf(sin(elapsed * 2.0))
		draw_arc(c, 18.0, -PI * 0.5, -PI * 0.5 + TAU * _fifth, 32, Color(1.0, 0.9, 0.7, 0.9), 2.0)
		draw_string(UiStyle.system_font(), c + Vector2(-5, 4), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(10 * Settings.text_scale()), Color(1, 1, 1, pulse))
		return
	draw_arc(c, 18.0, 0, TAU, 32, Color(0, 0, 0, 0.25), 2.0)
	var stalled := _p1_stopped_at >= 0.0 and _fifth >= ALONE_CAP - 0.01 and not calm()
	var a := 0.9 if not stalled else 0.5 + 0.4 * absf(sin(elapsed * 14.0))
	if _p1_stopped_at < 0.0:
		# Together: both halves grow from the top.
		draw_arc(c, 18.0, -PI * 0.5, -PI * 0.5 - PI * _fifth * 2.0 * 0.5, 24, Color(P1_COLOR, a), 2.0)
		draw_arc(c, 18.0, -PI * 0.5, -PI * 0.5 + PI * _fifth * 2.0 * 0.5, 24, Color(P2_COLOR, a), 2.0)
	else:
		draw_arc(c, 18.0, -PI * 0.5, -PI * 0.5 + TAU * _fifth, 32, Color(P2_COLOR, a), 2.0)
	for at in [FIFTH_LEFT, FIFTH_RIGHT]:
		draw_arc(at, 9.0, 0, TAU, 20, Color(1.0, 0.9, 0.6, 0.4), 1.0)


func _draw_burst(at: Vector2, t: float) -> void:
	if calm():
		draw_circle(at + Vector2(0, -16), 18.0 * (1.0 - t), Color(1.0, 0.85, 0.5, 0.25 * (1.0 - t)))
		return
	for i in 14:
		var dir := Vector2.from_angle(TAU * i / 14.0 + i)
		var p := at + Vector2(0, -16) + dir * t * 46.0 + Vector2(0, t * t * 20.0)
		draw_circle(p, 1.6 * (1.0 - t * 0.7), Color([Color("ffd070"), Color("ff8a5a"), Color("fff0c0")][i % 3], 1.0 - t / 1.2))


## The time-lapse over the square (TIMELAPSE s): night, the board, seasons,
## the message, SLOT 2 · DELETED, 3 YEARS LATER.
func _draw_timelapse() -> void:
	var t := beat_t
	var font := UiStyle.system_font()
	# Seasons: leaves, then snow (none under reduced motion).
	if not calm() and t > 4.0 and t < 12.0:
		for i in 40:
			var x := fmod(i * 53.0 + t * 30.0 * (1.0 + (i % 3) * 0.3), 640.0)
			var y := fmod(i * 37.0 + t * 40.0, 300.0) + 60.0
			var snow := t > 8.0
			draw_circle(Vector2(x, y), 1.2, Color(1, 1, 1, 0.7) if snow else Color("d8803a"))
	# The message, on the screen layer: hers, then a reply typing, then not.
	if t > 8.0 and t < 12.5:
		var box := Rect2(170, 96, 300, 54)
		draw_rect(box, Color(0.05, 0.06, 0.08, 0.88))
		draw_rect(box, Color(0.5, 0.55, 0.6, 0.6), false, 1.0)
		draw_string(font, box.position + Vector2(10, 16), "P2:  " + MESSAGE, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, P2_COLOR)
		if t > 9.4 and t < 11.4:
			var dots := ".".repeat(1 + int(t * 3.0) % 3) if not calm() else "..."
			draw_string(font, box.position + Vector2(10, 38), "P1 is typing" + dots, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(P1_COLOR, 0.8))
		elif t >= 11.4:
			draw_string(font, box.position + Vector2(10, 38), "(no reply)", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.6, 0.62, 0.66))
	# SLOT 2 · DELETED, stamped across the sky like a system dialog.
	if t > 12.5 and t < 15.5:
		var box2 := Rect2(180, 30, 280, 40)
		draw_rect(box2, Color(0.08, 0.04, 0.06, 0.9))
		draw_rect(box2, OWNER_COLOR, false, 1.5)
		draw_string(font, box2.position + Vector2(0, 26), "SLOT 2  ·  DELETED", HORIZONTAL_ALIGNMENT_CENTER, box2.size.x, 14, OWNER_COLOR)


## The present: cold, half-unloaded (squares of nothing along the edges).
func _draw_load() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.2, 0.3, 0.5, 0.18))
	var gone := minf(1.0, beat_t / 2.0)
	for i in 30:
		var x := float((i * 97) % 640)
		var y := 74.0 + float((i * 53) % 270)
		if x < 120 or x > 520 or y > 320:
			draw_rect(Rect2(x, y, 22, 14), Color(0, 0, 0, 0.85 * gone))
	if load_flicker() and fmod(beat_t, 0.7) < 0.08:
		draw_rect(Rect2(0, randf() * 360.0, 640, 2), Color(SYSTEM_COLOR, 0.4))


func _finish() -> void:
	if _done:
		return
	_done = true
	acted["handoff"] = elapsed
	if not replay:
		Settings.set_value("opening_seen", true)
		OwnerMemory.festival_seen = true
		if OwnerMemory.festival_choice == "":
			OwnerMemory.festival_choice = choice if choice != "" else "skipped"
		OwnerMemory.save_memory()
		boot_shown = true
	if _music:
		_music.stop()
	PlaytestLog.mark("prologue over", "%.1f s, choice %s" % [elapsed, choice])
	finished.emit()
