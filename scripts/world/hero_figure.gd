class_name HeroFigure
extends IllustratedCharacter
## The cast at the modern quality bar (docs/ART_BIBLE.md): taller figures,
## longer limbs and a rigged walk, a real face, painted light, and secondary
## motion. A drop-in for IllustratedCharacter: the same palette keys, moods,
## poses (crouch, hug, wave, point, startle) and feet at FEET_Y, so every
## owner (Player, Npc, OwnerAvatar, portraits) can use either one. When an
## imported sheet exists for a character (assets/characters/<who>/), that
## sheet wins (CharacterSheet); this procedural figure is its fallback, and
## IllustratedCharacter remains behind it.
##
## Drawing only: collision boxes, speeds and sight lines stay in the owners.

## Light comes from the upper left (the same as the areas' painted shading).
const LIGHT := Vector2(-0.6, -0.8)
const RIM := Color(1.0, 0.96, 0.86, 0.35)

## Proportions in logical pixels. h: height; head: head height; sh, hip:
## shoulder and hip half-widths; leg: fraction of h below the hips.
const HERO_BODIES := {
	"rue": {"h": 34.0, "head": 9.4, "sh": 4.3, "hip": 3.3, "leg": 0.40, "hair": "messy", "lower": "trousers", "coat": true, "scarf": true},
	"intruder": {"h": 34.0, "head": 9.4, "sh": 4.3, "hip": 3.3, "leg": 0.40, "hair": "hood", "lower": "trousers", "coat": true},
	"adult": {"h": 38.0, "head": 9.6, "sh": 5.0, "hip": 3.8, "leg": 0.42, "hair": "short", "lower": "trousers", "belt": true, "scarf": true},
	"dress": {"h": 36.0, "head": 9.4, "sh": 4.3, "hip": 4.0, "leg": 0.40, "hair": "long", "lower": "dress"},
	"child": {"h": 28.0, "head": 9.0, "sh": 3.5, "hip": 3.0, "leg": 0.36, "hair": "pigtails", "lower": "smock"},
	"apron": {"h": 37.0, "head": 9.6, "sh": 5.8, "hip": 5.2, "leg": 0.36, "hair": "bald", "lower": "trousers", "apron": true, "moustache": true},
	"robe": {"h": 42.0, "head": 9.4, "sh": 4.8, "hip": 4.8, "leg": 0.40, "hair": "elder", "lower": "robe", "beard": true, "sash": true},
}

var hero: Dictionary
## Seconds left of the habit (two light taps, then the press), as a gesture.
var habit := 0.0
const HABIT_TIME := 0.95
## Seconds left of a celebration spin (Arin's).
var spin := 0.0
const SPIN_TIME := 0.6
## Secondary motion: the scarf's loose end and the hair, as damped springs
## that lag behind the body's motion.
var _scarf_off := Vector2.ZERO
var _scarf_vel := Vector2.ZERO
var _hair_off := Vector2.ZERO
var _hair_vel := Vector2.ZERO
var _speed := 0.0
## "Left running": the faint shimmer of a character nobody saves any more.
var left_running := false


func _init(k: String, colours: Dictionary) -> void:
	super(k, colours)
	hero = HERO_BODIES.get(kind, HERO_BODIES["adult"])


func height() -> int:
	return int(hero.h)


func _head_y() -> float:
	return -float(hero.h) + float(hero.head) * 0.5


func eye_position() -> Vector2:
	return Vector2(0, FEET_Y + _head_y() + float(hero.head) * 0.08)


## The girl's habit as a gesture: her hand taps twice, lightly, then presses.
func play_habit() -> void:
	habit = HABIT_TIME


func play_spin() -> void:
	spin = SPIN_TIME


func update(delta: float, velocity: Vector2, face_motion := true) -> void:
	super(delta, velocity, face_motion)
	_speed = velocity.length()
	habit = maxf(0.0, habit - delta)
	spin = maxf(0.0, spin - delta)
	# The loose ends trail against the motion and settle back: k (stiffness)
	# and c (damping) tuned so they swing once and rest.
	var push := -velocity * 0.012
	_scarf_vel += ((push - _scarf_off) * 38.0 - _scarf_vel * 6.5) * delta
	_scarf_off += _scarf_vel * delta
	_hair_vel += ((push * 0.5 - _hair_off) * 60.0 - _hair_vel * 9.0) * delta
	_hair_off += _hair_vel * delta
	_scarf_off = _scarf_off.limit_length(4.0)
	_hair_off = _hair_off.limit_length(1.6)


# --- drawing --------------------------------------------------------------------------

func draw(ci: CanvasItem, opts: Dictionary = {}) -> void:
	var offset: Vector2 = opts.get("offset", Vector2.ZERO)
	var alpha: float = opts.get("alpha", 1.0)
	var solid: Variant = opts.get("solid", null)
	var grey: bool = opts.get("grey", false)
	var slices: Array = opts.get("slices", [0.0, 0.0, 0.0])
	var k: float = opts.get("scale", 1.0)
	var rot: float = opts.get("rotation", 0.0)
	var side := facing.x != 0.0
	var flip := -1.0 if facing.x < 0.0 else 1.0
	if spin > 0.0:
		# A spin turns through the four views (drawn, not a facing change).
		var views := [Vector2.DOWN, Vector2.RIGHT, Vector2.UP, Vector2.LEFT]
		var f: Vector2 = views[int((1.0 - spin / SPIN_TIME) * 4.0) % 4]
		side = f.x != 0.0
		flip = -1.0 if f.x < 0.0 else 1.0
	var squeeze := 1.0 - 0.22 * sin(clampf(turn / TURN_TIME, 0.0, 1.0) * PI)
	var sink := sin(clampf(settle / SETTLE_TIME, 0.0, 1.0) * PI) * 0.05
	ci.draw_set_transform(offset + Vector2(0, FEET_Y).rotated(rot) * k, rot, Vector2(flip * squeeze * (1.0 + sink * 0.4), 1.0 - sink) * k)
	if solid == null and alpha > 0.5:
		_hero_shadow(ci, alpha)
	var running := _speed > 70.0
	var a := _walk * PI  # gait phase: one stride per PI
	var lean := sin(clampf(start / START_TIME, 0.0, 1.0) * PI)
	var bob := -absf(sin(a)) * (1.2 if running else 0.7) if moving else 0.0
	var breath := sin(_t * TAU / 2.6) * 0.3 if not moving else 0.0
	var hop_y := -sin(minf(_hop / 0.45, 1.0) * PI) * 3.5 if _hop > 0.0 else 0.0
	var habit_y := 0.0
	if habit > 0.0:
		var ht := HABIT_TIME - habit
		habit_y = -(maxf(0.0, sin(ht * TAU * 2.0)) * 0.6 if ht < 0.5 else sin(clampf((ht - 0.5) / 0.45, 0.0, 1.0) * PI) * 2.2)
	var sway := sin(_t * 1.4) * 0.6 if idle_style == "sway" and not moving else 0.0
	if shiver and not moving:
		sway += float(floori(_t * 30.0) % 2) * 0.4 - 0.2
	var dy := bob + hop_y + habit_y + (2.4 if crouch else 0.0)
	var tilt := (lean * 1.6 + (1.0 if running else 0.4) * (1.0 if moving else 0.0)) if side else 0.0
	var rig := {
		"side": side, "flip": flip, "a": a, "running": running, "dy": dy, "breath": breath, "sway": sway, "tilt": tilt, "k": k,
		"s_head": float(slices[0]) * flip, "s_body": float(slices[1]) * flip, "s_legs": float(slices[2]) * flip,
		"back": facing == Vector2.UP and spin <= 0.0,
	}
	var p := IllustratedCharacter._Parts.new(self, ci, solid, grey, alpha)
	_hero_legs(p, rig)
	_hero_body(p, rig)
	_hero_head(p, rig)
	p.flush()
	if solid == null:
		_hero_light(ci, rig, alpha, grey)
		if not rig.back:
			_hero_face(ci, rig, alpha, grey)
		if left_running:
			_shimmer(ci, alpha)
	if shows_book() and solid == null:
		_book(ci, Vector2(rig.s_body, -float(hero.h) * 0.25 + dy), alpha)
	ci.draw_set_transform(Vector2.ZERO)


## Unit shapes, built once and transformed natively each frame (a GDScript
## cos/sin loop per shape per frame was most of the figure's cost).
static var UNIT_20 := IllustratedCharacter._unit_circle(20)
## The face: a circle narrower toward the chin (unit radius).
static var UNIT_FACE := _unit_face()
## The upper half of a circle, left to right (15 points), for hair caps.
static var UNIT_CAP := _unit_arc(PI, TAU, 15)
## The rim light's arc on the head's upper left (7 points).
static var UNIT_RIM := _unit_arc(PI * 1.05, PI * 1.05 + 0.72, 7)


static func _unit_face() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		var t := TAU * i / 20.0
		var y := sin(t)
		pts.append(Vector2(cos(t) * (1.0 - maxf(0.0, y) * 0.16), y))
	return pts


static func _unit_arc(from: float, to: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var t := from + (to - from) * i / float(n - 1)
		pts.append(Vector2(cos(t), sin(t)))
	return pts


static func _scaled(unit: PackedVector2Array, c: Vector2, r: Vector2) -> PackedVector2Array:
	return Transform2D(Vector2(r.x, 0), Vector2(0, r.y), c) * unit


func _hero_shadow(ci: CanvasItem, alpha: float) -> void:
	var w := float(hero.sh) + 2.2
	ci.draw_colored_polygon(_scaled(UNIT_20, Vector2(0, 0.4), Vector2(w, 1.9)), Color(0, 0, 0, 0.32 * alpha))


## Key heights for the rig (negative is up, the feet are at 0).
func _hip_y(r: Dictionary) -> float:
	return -float(hero.h) * float(hero.leg) + r.dy * 0.5


func _neck_y(r: Dictionary) -> float:
	return -float(hero.h) + float(hero.head) - 0.4 + r.dy


## A limb from a to b, tapering from r1 to r2, with round joints. `ink`
## draws its edges over whatever it crosses (an arm in front of a coat of
## the same colour still reads as an arm).
func _limb(p: IllustratedCharacter._Parts, from: Vector2, to: Vector2, r1: float, r2: float, c: Color, ink := false) -> void:
	p.taper(from, to, r1, r2, c)
	if ink:
		var n := (to - from).normalized().orthogonal() if (to - from).length() > 0.01 else Vector2.RIGHT
		var line := Color(OUTLINE, 0.75)
		p.line(from + n * r1, to + n * r2, line, 0.4)
		p.line(from - n * r1, to - n * r2, line, 0.4)


## One leg (s: -1 near, +1 far) at the rig's gait phase: hip, knee and foot
## in the figure's frame (x forward when side-on), and how lifted it is.
func _leg_pose(s: float, r: Dictionary) -> Dictionary:
	var hip := _hip_y(r)
	var leg_len := -hip
	var x0 := float(r.s_legs)
	var crouch_k := 0.35 if crouch else 0.0
	# Contact (MOVEMENT_SPEC, "Animation contact"): half of each leg's cycle
	# is stance, and a planted foot must stay where it landed. The body covers
	# one STRIDE of floor per stance, so the foot travels back exactly that
	# far, at an even rate, in the figure's frame (scaled by how big it is
	# drawn); the other half lifts and eases it forward again. A sine swing
	# moved the planted foot forward, so she skated 20 to 29 px a step.
	var q := fposmod(float(r.a) + (0.0 if s < 0.0 else PI) + PI * 0.5, TAU)  # 0..PI stance, PI..TAU swing
	var reach := PixelCharacter.STRIDE / maxf(0.01, float(r.get("k", 1.0))) if moving else 0.0
	var fx: float
	var lift := crouch_k
	if q < PI:
		fx = reach * (0.5 - q / PI)
	else:
		var u := (q - PI) / PI
		fx = reach * (-0.5 + u * u * (3.0 - 2.0 * u))
		lift += sin(u * PI) * (0.5 if r.running else 0.32) * (1.0 if moving else 0.0)
	var swing := asin(clampf(fx / maxf(0.01, leg_len * 1.02), -0.95, 0.95))
	var top: Vector2
	var knee: Vector2
	var foot: Vector2
	if r.side:
		top = Vector2(x0 + s * 0.4, hip)
		var thigh := leg_len * 0.52
		knee = top + Vector2(sin(swing) * thigh, cos(swing) * thigh) + Vector2(lift * 2.2, -lift * 1.4)
		var shin_a := swing - lift * 1.8
		foot = knee + Vector2(sin(shin_a) * leg_len * 0.5, cos(shin_a) * leg_len * 0.5)
		foot.y = minf(foot.y, -0.4)
	else:
		var spread := float(hero.hip) * 0.55
		top = Vector2(x0 + s * spread, hip)
		var up := lift * leg_len * 0.22
		knee = Vector2(x0 + s * spread * 1.05, hip * 0.5 - up * 0.6)
		foot = Vector2(x0 + s * spread * 1.1, -0.6 - up)
	return {"top": top, "knee": knee, "foot": foot, "lift": lift - crouch_k}


## Both feet now, side-on, in the figure's frame (x forward), with whether
## each is planted: what tests and the contact tour measure.
func feet_now(scale := 1.0) -> Array:
	var r := {"side": true, "a": _walk * PI, "running": _speed > 70.0, "dy": 0.0, "s_legs": 0.0, "k": scale}
	var out := []
	for s: float in [-1.0, 1.0]:
		var pose := _leg_pose(s, r)
		out.append({"foot": pose.foot, "planted": pose.lift <= 0.001})
	return out


func _hero_legs(p: IllustratedCharacter._Parts, r: Dictionary) -> void:
	var lower: String = hero.lower
	var skin := _c("s", Color("f0c49c"))
	var leg := leg_color if lower != "smock" else skin
	var shoe := shoe_color
	for s: float in [-1.0, 1.0]:
		var pose := _leg_pose(s, r)
		var top: Vector2 = pose.top
		var knee: Vector2 = pose.knee
		var foot: Vector2 = pose.foot
		var far: bool = r.side and s > 0.0
		var lc := leg.darkened(0.18) if far else leg
		if lower in ["dress", "robe"]:
			# Under a hem only the shins and feet show.
			var hem := -float(hero.h) * (0.12 if lower == "dress" else 0.02)
			if lower == "dress":
				_limb(p, Vector2(foot.x * 0.9, hem), foot, 0.8, 0.7, skin.darkened(0.1 if far else 0.0))
			p.ellipse(foot + Vector2(0.6 if r.side else 0.0, 0.2), Vector2(1.9 if r.side else 1.5, 0.9), shoe.darkened(0.15 if far else 0.0))
			continue
		_limb(p, top, knee, 1.35 if kind != "child" else 1.1, 1.05, lc)
		_limb(p, knee, foot, 1.05, 0.85, lc)
		p.ellipse(foot + Vector2(0.8 if r.side else 0.0, 0.1), Vector2(2.1 if r.side else 1.5, 1.0), shoe.darkened(0.15 if far else 0.0))


func _hero_body(p: IllustratedCharacter._Parts, r: Dictionary) -> void:
	var clothes := _c("c", Color("6a6a7a"))
	var dark := _c("d", clothes.darkened(0.3))
	var top := _neck_y(r) + 0.6
	var hip := _hip_y(r)
	var sh := float(hero.sh) * (0.7 if r.side else 1.0)
	var hw := float(hero.hip) * (0.75 if r.side else 1.0)
	var x := float(r.s_body) + float(r.tilt) * 0.5
	var lower: String = hero.lower
	var bottom := hip + 1.0
	var flare := 0.4
	match lower:
		"dress":
			bottom = -float(hero.h) * 0.12
			flare = 2.6
		"robe":
			bottom = -0.6
			flare = 2.2
		"smock":
			bottom = hip + 3.0
			flare = 1.6
	if hero.get("coat", false):
		bottom = hip + 4.2  # the raincoat's skirt
		flare = 1.4
	# The far arm goes behind the body.
	if r.side:
		_hero_arm(p, r, Vector2(x - float(r.tilt) * 0.2, top + 1.0), -1.0, sh, true)
	var body_pts := PackedVector2Array([
		Vector2(x - sh * 0.55, top - 0.4), Vector2(x - sh, top + 1.4), Vector2(x - hw * 1.05 - flare, bottom),
		Vector2(x + hw * 1.05 + flare, bottom), Vector2(x + sh, top + 1.4), Vector2(x + sh * 0.55, top - 0.4),
	])
	p.poly(body_pts, clothes)
	# Painted shade on the side away from the light, and the waist fold.
	p.poly(PackedVector2Array([Vector2(x + sh * 0.25, top), Vector2(x + sh, top + 1.4), Vector2(x + hw * 1.05 + flare, bottom),
		Vector2(x + hw * 0.2 + flare * 0.4, bottom)]), Color(dark, 0.5), false)
	if hero.get("coat", false):
		var seam := Color(dark, 0.9)
		p.line(Vector2(x + 0.2, top + 1.6), Vector2(x + 0.2, bottom - 0.4), seam, 0.4)
		for s: float in [-1.0, 1.0]:
			if r.side and s < 0.0:
				continue
			p.rect(Rect2(x + s * hw * 0.5 - 0.9, hip - 1.0, 1.8, 1.3), Color(dark, 0.8), false)
		# Buttons, light on the dark coat.
		for i in 3:
			p.circle(Vector2(x + 1.0, top + 2.4 + i * 2.6), 0.32, clothes.lightened(0.35), false)
	if hero.get("apron", false) and not r.back:
		var w := _c("w", Color("efe6d6"))
		p.poly(PackedVector2Array([Vector2(x - sh * 0.62, top + 3.2), Vector2(x + sh * 0.62, top + 3.2),
			Vector2(x + hw * 0.85, bottom - 0.2), Vector2(x - hw * 0.85, bottom - 0.2)]), w, false)
		p.rect(Rect2(x - 1.6, hip - 3.0, 3.2, 2.0), w.darkened(0.12), false)
	if hero.get("belt", false):
		p.rect(Rect2(x - hw * 1.05, hip - 1.2, hw * 2.1, 1.3), _c("a", dark).darkened(0.25), false)
		p.rect(Rect2(x - 0.7, hip - 1.3, 1.4, 1.5), Color("c8a040"), false)
	if hero.get("sash", false):
		p.poly(PackedVector2Array([Vector2(x - sh * 0.8, top + 2.0), Vector2(x - sh * 0.4, top + 1.0),
			Vector2(x + hw * 0.9, hip - 0.4), Vector2(x + hw * 0.6, hip + 1.0)]), _c("a", Color("8a3a3a")), false)
	if lower == "dress":
		p.line(Vector2(x - hw - flare + 0.6, bottom - 0.8), Vector2(x + hw + flare - 0.6, bottom - 0.8), dark, 0.7)
	if hero.get("scarf", false):
		_hero_scarf(p, r, Vector2(x, top))
	# The near arm (or both, facing the viewer).
	if r.side:
		_hero_arm(p, r, Vector2(x + float(r.tilt) * 0.2, top + 1.0), 1.0, sh, false)
	else:
		for s: float in [-1.0, 1.0]:
			_hero_arm(p, r, Vector2(x + s * (sh - 0.3), top + 1.2), s, sh, false)


func _hero_arm(p: IllustratedCharacter._Parts, r: Dictionary, shoulder: Vector2, s: float, sh: float, far: bool) -> void:
	var clothes := _c("c", Color("6a6a7a"))
	var skin := _c("s", Color("f0c49c"))
	if far:
		clothes = clothes.darkened(0.2)
		skin = skin.darkened(0.15)
	var upper := float(hero.h) * 0.16
	var fore := float(hero.h) * 0.15
	var swing := sin(float(r.a) + (PI if s > 0.0 else 0.0)) * ((0.8 if r.running else 0.5) if moving else 0.0)
	var ua := swing * (1.0 if r.side else 0.35)  # shoulder angle from straight down
	var ea := (0.5 + maxf(0.0, swing) * 0.6) if r.running else 0.15 + absf(swing) * 0.25  # elbow bend
	var dir := 1.0 if r.side else s
	var elbow: Vector2
	var hand: Vector2
	if r.side:
		elbow = shoulder + Vector2(sin(ua) * upper, cos(ua) * upper)
		hand = elbow + Vector2(sin(ua + ea) * fore, cos(ua + ea) * fore)
	else:
		elbow = shoulder + Vector2(dir * 0.9, upper)
		hand = elbow + Vector2(dir * 0.4, fore - absf(swing) * 1.6)
	# Poses override the swing (the nearer or right hand acts).
	var acting: bool = (r.side and not far) or (not r.side and s > 0.0)
	if hug and not moving:
		elbow = shoulder + Vector2(-dir * 0.2, upper * 0.85)
		hand = shoulder + Vector2(-dir * sh * 0.6, upper * 0.9)
	if idle_style == "tend" and not moving and not talking:
		elbow = shoulder + Vector2(dir * 0.6, upper * 0.9)
		hand = elbow + Vector2(-dir * 0.8, fore * 0.55 + sin(_t * 2.2 + s * 1.6) * 0.8)
	if acting and waving:
		elbow = shoulder + Vector2(dir * 2.0, -upper * 0.2)
		hand = elbow + Vector2(dir * 0.6 + sin(_t * 9.0) * 1.2, -fore * 0.9)
	if acting and pointing:
		elbow = shoulder + Vector2(upper * 0.95, 0.4)
		hand = elbow + Vector2(fore * 0.95, 0.0)
	if acting and habit > 0.0:
		# Two light taps (the hand dips twice), then the press (pushed out).
		var ht := HABIT_TIME - habit
		elbow = shoulder + Vector2(dir * 1.6, upper * 0.7)
		if ht < 0.5:
			hand = elbow + Vector2(dir * fore * 0.7, -1.0 + maxf(0.0, sin(ht * TAU * 2.0)) * 1.4)
		else:
			hand = elbow + Vector2(dir * fore * 0.95, -fore * 0.45 * sin(clampf((ht - 0.5) / 0.45, 0.0, 1.0) * PI))
	var sleeve := clothes.lightened(0.07)
	_limb(p, shoulder, elbow, 1.2, 1.0, sleeve, not far)
	_limb(p, elbow, hand, 1.0, 0.8, sleeve, not far)
	p.circle(hand, 1.05, skin)


func _hero_scarf(p: IllustratedCharacter._Parts, r: Dictionary, neck: Vector2) -> void:
	var a := _c("a", Color("d8463a"))
	var sh := float(hero.sh) * (0.7 if r.side else 1.0)
	p.poly(PackedVector2Array([Vector2(neck.x - sh * 0.75, neck.y - 0.8), Vector2(neck.x + sh * 0.75, neck.y - 0.8),
		Vector2(neck.x + sh * 0.65, neck.y + 1.4), Vector2(neck.x - sh * 0.65, neck.y + 1.4)]), a)
	p.poly(PackedVector2Array([Vector2(neck.x + sh * 0.1, neck.y - 0.6), Vector2(neck.x + sh * 0.75, neck.y - 0.8),
		Vector2(neck.x + sh * 0.65, neck.y + 1.4), Vector2(neck.x + sh * 0.05, neck.y + 1.4)]), Color(a.darkened(0.3), 0.6), false)
	# The loose end hangs, swings with the spring, and streams behind a run.
	var root := Vector2(neck.x + (sh * 0.35 if not r.side else -sh * 0.4), neck.y + 1.0)
	var rest := Vector2(0.4, 6.0) if not r.side else Vector2(-1.2, 5.4)
	var tail := rest + Vector2(_scarf_off.x * float(r.flip), _scarf_off.y)
	if r.side and moving:
		tail = Vector2(-5.5 - (2.0 if r.running else 0.0), 1.8 + sin(_t * 10.0) * 0.7)
	var mid := root + tail * 0.5 + Vector2(0.3, 0.6)
	_limb(p, root, mid, 1.0, 0.95, a.darkened(0.06))
	_limb(p, mid, root + tail, 0.95, 0.8, a.darkened(0.12))


func _hero_head(p: IllustratedCharacter._Parts, r: Dictionary) -> void:
	var hh := float(hero.head)
	var rx := hh * 0.46
	var ry := hh * 0.5
	var c := Vector2(float(r.s_head) + float(r.sway) + float(r.tilt) + (0.5 if r.side else 0.0), _head_y() + float(r.dy) + float(r.breath))
	var hair := _c("h", Color("5a3a2a"))
	var skin := _c("s", Color("f0c49c"))
	var style: String = hero.hair
	var back: bool = r.back
	var ho := _hair_off * Vector2(float(r.flip), 1.0)
	# The neck.
	p.rect(Rect2(c.x - 0.9, c.y + ry - 1.2, 1.8, 2.0), skin.darkened(0.12))
	# Hair behind the head first.
	match style:
		"long":
			p.poly(PackedVector2Array([c + Vector2(-rx - 0.8, -1.0), c + Vector2(rx + 0.8, -1.0),
				c + Vector2(rx + 1.4, ry + 5.5) + ho, c + Vector2(-rx - 1.4, ry + 5.5) + ho]), hair)
		"pigtails":
			for s: float in [-1.0, 1.0]:
				if r.side and s < 0.0:
					continue
				var tail := c + Vector2(s * (rx + 1.8), 1.2) + ho
				p.ellipse(tail, Vector2(1.6, 2.8), hair)
				p.circle(tail + Vector2(0, -2.4), 1.0, _c("a", Color("e8c48a")))
		"elder":
			p.ellipse(c + Vector2(0, 1.0), Vector2(rx + 1.0, ry + 0.8), hair)
	if style == "hood":
		p.ellipse(c, Vector2(rx + 1.4, ry + 1.2), _c("g", _c("h", Color("3fa6b8"))))
		p.ellipse(c + Vector2(0.4 if r.side else 0.0, 0.8), Vector2(rx - 1.2, ry - 1.0), Color("05070a"), false)
		return
	# The head: an ear on the visible side(s), then the face shape (a soft
	# jaw, wider at the cheeks than a circle).
	if not back:
		var ears: Array = [1.0] if r.side else [-1.0, 1.0]
		for s: float in ears:
			if r.side:
				p.ellipse(c + Vector2(-rx * 0.15, 0.6), Vector2(0.9, 1.3), skin.darkened(0.06))
			else:
				p.ellipse(c + Vector2(s * rx, 0.6), Vector2(0.8, 1.2), skin.darkened(0.06))
	var face := _scaled(UNIT_FACE, c, Vector2(rx, ry))  # narrower toward the chin
	p.poly_grown(face, _scaled(UNIT_FACE, c, Vector2(rx + OUTLINE_W, ry + OUTLINE_W)), skin if not back or style == "bald" else hair)
	if back:
		if style == "bald":
			p.ellipse(c + Vector2(-rx + 0.6, 0.8), Vector2(1.1, 2.2), hair)
			p.ellipse(c + Vector2(rx - 0.6, 0.8), Vector2(1.1, 2.2), hair)
		elif style == "messy":
			_tuft(p, c + Vector2(0.4, -ry) + ho * 1.6, hair)
		return
	# Hair on top: a crown with locks, shaped per character.
	match style:
		"messy":
			_hair_cap(p, c, rx, ry, 0.4, hair)
			_tuft(p, c + Vector2(0.4, -ry) + ho * 1.6, hair)
			# Fringe locks over the forehead.
			for i in 3:
				var fx := -rx * 0.6 + i * rx * 0.55
				p.poly(PackedVector2Array([c + Vector2(fx - 1.2, -ry * 0.55), c + Vector2(fx + 1.4, -ry * 0.6), c + Vector2(fx + 0.3, -ry * 0.08 + (i % 2) * 0.6)]), hair, false)
		"short":
			_hair_cap(p, c, rx, ry, 0.0, hair)
			p.poly(PackedVector2Array([c + Vector2(rx * 0.1, -ry * 0.75), c + Vector2(rx * 0.95, -ry * 0.4), c + Vector2(rx * 0.4, -ry * 0.25)]), hair, false)
		"long":
			_hair_cap(p, c, rx, ry, 0.8, hair)
		"pigtails":
			_hair_cap(p, c, rx, ry, 0.5, hair)
		"bald":
			for s: float in [-1.0, 1.0]:
				p.poly(PackedVector2Array([c + Vector2(s * (rx + 0.3), 0.6), c + Vector2(s * (rx - 0.6), -2.6), c + Vector2(s * (rx - 2.2), -1.8), c + Vector2(s * (rx - 1.2), 1.6)]), hair)
		"elder":
			_hair_cap(p, c, rx, ry, -0.8, hair)
	if hero.get("beard", false):
		p.poly(PackedVector2Array([c + Vector2(-rx + 0.6, ry * 0.25), c + Vector2(rx - 0.6, ry * 0.25), c + Vector2(rx * 0.55, ry + 4.4), c + Vector2(0, ry + 5.6), c + Vector2(-rx * 0.55, ry + 4.4)]), hair)
	if hero.get("moustache", false):
		p.ellipse(c + Vector2(0.4 if r.side else 0.0, ry * 0.42), Vector2(2.4, 0.75), hair.darkened(0.1), false)


func _tuft(p: IllustratedCharacter._Parts, at: Vector2, hair: Color) -> void:
	p.poly(PackedVector2Array([at + Vector2(-1.2, 2.2), at + Vector2(-0.2, -2.6), at + Vector2(1.6, 1.6)]), hair)
	p.poly(PackedVector2Array([at + Vector2(0.4, 1.8), at + Vector2(2.4, -1.4), at + Vector2(2.2, 2.2)]), hair)


func _hair_cap(p: IllustratedCharacter._Parts, c: Vector2, rx: float, ry: float, fringe: float, hair: Color) -> void:
	p.poly_grown(_hero_cap(c, rx, ry, fringe), _hero_cap(c, rx + OUTLINE_W, ry + OUTLINE_W, fringe - OUTLINE_W * 0.5), hair)


func _hero_cap(c: Vector2, rx: float, ry: float, fringe: float) -> PackedVector2Array:
	var pts := _scaled(UNIT_CAP, c, Vector2(rx + 0.6, ry + 0.6))
	pts.append(c + Vector2(rx * 0.8, -ry * 0.25 + fringe))
	pts.append(c + Vector2(0.0, -ry * 0.4 + fringe))
	pts.append(c + Vector2(-rx * 0.8, -ry * 0.25 + fringe))
	return pts


## A rim of light on the lit edges (upper left), over the fills.
func _hero_light(ci: CanvasItem, r: Dictionary, alpha: float, grey: bool) -> void:
	var col := _paint(RIM, null, grey, alpha)
	var hh := float(hero.head)
	var c := Vector2(float(r.s_head) + float(r.sway) + float(r.tilt) + (0.5 if r.side else 0.0), _head_y() + float(r.dy) + float(r.breath))
	ci.draw_polyline(_scaled(UNIT_RIM, c, Vector2(hh * 0.46, hh * 0.5)), col, 0.5)
	var top := _neck_y(r) + 1.6
	var x := float(r.s_body) + float(r.tilt) * 0.5 - float(hero.sh) * (0.7 if r.side else 1.0) + 0.4
	ci.draw_line(Vector2(x, top + 0.6), Vector2(x - 0.5, _hip_y(r)), col, 0.45)


func _hero_face(ci: CanvasItem, r: Dictionary, alpha: float, grey: bool) -> void:
	var hh := float(hero.head)
	var c := Vector2(float(r.s_head) + float(r.sway) + float(r.tilt) + (0.5 if r.side else 0.0), _head_y() + float(r.dy) + float(r.breath))
	var missing := _face_missing()
	var mood: Dictionary = MOODS.get(expression, MOODS[""])
	var look := Vector2(float(glance) * 0.5, -0.4 if mood.get("look_up", false) else 0.0)
	var ey := c.y + hh * 0.08
	var eyes: Array = [Vector2(c.x + hh * 0.2, ey)] if r.side else [Vector2(c.x - hh * 0.19, ey), Vector2(c.x + hh * 0.19, ey)]
	var size := float(mood.eye) * (1.2 if startled > 0.0 else 1.0)
	var lids := float(mood.lids)
	var iris := _paint(eye_color.lerp(_c("h", Color("5a3a2a")), 0.25), null, grey, alpha)
	var white := _paint(Color(0.98, 0.97, 0.95), null, grey, alpha)
	var ink := _paint(OUTLINE, null, grey, alpha)
	for e: Vector2 in eyes:
		var at := e + look
		if missing:
			Decor.disc(ci, at, 1.2, Color(eye_color, 0.35 * alpha))
			Decor.disc(ci, at, 0.7, _paint(eye_color, null, false, alpha))
			continue
		if _blink > 0.0 or lids >= 0.95:
			ci.draw_line(at + Vector2(-1.1, 0.2), at + Vector2(1.1, 0.2), ink, 0.55)
			continue
		var rx := 1.05 * size
		var ry := 1.35 * size * (1.0 - lids * 0.5)
		_ellipse(ci, at, Vector2(rx, ry), white)
		_ellipse(ci, at + Vector2(0.15 if not r.side else 0.35, 0.15), Vector2(rx * 0.68, ry * 0.75), iris)
		if not mood.get("blank", false):
			_ellipse(ci, at + Vector2(0.15 if not r.side else 0.35, 0.2), Vector2(rx * 0.32, ry * 0.36), ink)
			Decor.disc(ci, at + Vector2(-0.3, -0.45), 0.32, Color(1, 1, 1, 0.95 * alpha))
		# The upper lid line, heavier when lids drop.
		ci.draw_polyline(PackedVector2Array([at + Vector2(-rx, -ry * 0.35 + lids), at + Vector2(0, -ry + lids * 1.2), at + Vector2(rx, -ry * 0.35 + lids)]), Color(ink, 0.8), 0.35 + lids * 0.3)
		# Brows: level at rest (a friendly face), the inner end lifting with
		# worry or dropping with resolve.
		var b: Array = mood.brow
		var inward := -signf(e.x - c.x) if not r.side else -1.0
		var inner := at + Vector2(inward * 0.7, -ry - 1.5 - float(b[0]) * 0.6)
		var outer := at + Vector2(-inward * 1.2, -ry - 1.3 - float(b[1]) * 0.6)
		ci.draw_line(inner, outer, _paint(_c("h", Color("5a3a2a")).darkened(0.2), null, grey, alpha), 0.5)
	if missing or kind == "intruder":
		return
	var skin := _c("s", Color("f0c49c"))
	# A small nose shadow, then the mouth.
	ci.draw_line(c + Vector2(0.35 + (0.9 if r.side else 0.0), hh * 0.2), c + Vector2(0.15 + (1.1 if r.side else 0.0), hh * 0.27), _paint(skin.darkened(0.25), null, grey, alpha), 0.45)
	var mouth := _paint(skin.darkened(0.5).lerp(Color("8a2a28"), 0.45), null, grey, alpha)
	var m := c + Vector2(0.9 if r.side else 0.0, hh * 0.34)
	var shape: Variant = mood.mouth
	if talking and fmod(_t, 0.24) < 0.12:
		_ellipse(ci, m, Vector2(0.9, 0.7), mouth)
	elif startled > 0.0 or shape is String:
		_ellipse(ci, m, Vector2(0.6, 0.8), mouth)
	else:
		var curve := float(shape)
		ci.draw_polyline(PackedVector2Array([m + Vector2(-1.1, -curve * 0.4), m + Vector2(0, curve * 0.35), m + Vector2(1.1, -curve * 0.4)]), mouth, 0.55)
	var blush := _paint(skin.lerp(Color("e07a6a"), 0.4), null, grey, alpha * 0.5)
	if not r.side:
		_ellipse(ci, c + Vector2(-hh * 0.3, hh * 0.24), Vector2(1.1, 0.6), blush)
		_ellipse(ci, c + Vector2(hh * 0.3, hh * 0.24), Vector2(1.1, 0.6), blush)
	else:
		_ellipse(ci, c + Vector2(hh * 0.12, hh * 0.24), Vector2(1.0, 0.6), blush)


## A character nobody saves any more: faint horizontal slips of colour that
## drift up through her. Never strong enough to hide her shape.
func _shimmer(ci: CanvasItem, alpha: float) -> void:
	var h := float(hero.h)
	for i in 3:
		var y := -fmod(_t * 9.0 + i * h / 3.0, h)
		var w := float(hero.sh) * 2.2
		ci.draw_rect(Rect2(-w * 0.5 + sin(_t * 3.0 + i) * 0.8, y, w, 0.5), Color(0.55, 0.95, 1.0, 0.18 * alpha))
