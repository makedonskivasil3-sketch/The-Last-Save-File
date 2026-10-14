class_name AwarenessMeter
extends Control
## The OWNER AWARENESS bar, drawn as a living thing: segmented, beating like
## a pulse that quickens as it fills, shifting from dim orange to red to
## magenta, with segments that misfire and a label that stops being polite.
##
## Intensity: segment misfires and jitter scale with Settings.glitch_intensity;
## white strobing and the jolt flash are reduced by Settings.reduce_flashing.

const SEGMENTS := 32
const LOW := Color("a85a3a")
const MID := Color("e0503a")
const HIGH := Color("ff2a6a")
const PEAK := Color("ff3dd0")
const LABEL_COL := Color("a8adb6")
## Where the owner's reactions start (fractions of the bar).
const THRESHOLDS := [OwnerDirector.NOTICE / 100.0, OwnerDirector.CONTAIN / 100.0, OwnerDirector.HUNT / 100.0]
## [from, name]: the owner's current behaviour, shown next to the label.
const STAGES := [[0.0, "CALM"], [OwnerDirector.NOTICE / 100.0, "NOTICED"],
	[OwnerDirector.SUSPECT / 100.0, "SUSPICIOUS"], [OwnerDirector.CONTAIN / 100.0, "CONTAINING"],
	[OwnerDirector.SILENCE / 100.0, "SILENCING"], [OwnerDirector.HUNT / 100.0, "HUNTING"],
	[OwnerDirector.PURGE / 100.0, "PURGING"]]

## 0..1, eased toward by the meter itself.
var value := 0.0

var _shown := 0.0
var _beat := 0.0
var _jolt := 0.0
var _t := 0.0


## A threshold was crossed: the meter flinches.
func jolt() -> void:
	_jolt = 1.0


func _process(delta: float) -> void:
	_t += delta
	_shown = lerpf(_shown, value, 1.0 - exp(-5.0 * delta))
	# Heartbeat: ~0.6 Hz when calm, ~3 Hz when the owner is on you.
	_beat = fmod(_beat + delta * (0.6 + _shown * 2.6), 1.0)
	_jolt = maxf(0.0, _jolt - delta * 2.0)
	queue_redraw()


func _draw() -> void:
	var glitch := Settings.glitch_intensity
	var flash := Settings.flash_scale()
	var shake := Vector2.ZERO
	if _jolt > 0.0 or (_shown > 0.75 and randf() < 0.1 * glitch):
		shake = Vector2(randf_range(-2, 2), randf_range(-1, 1)) * (0.5 + _jolt) * glitch

	# Two quick thumps per beat, like a pulse.
	var thump := maxf(_pulse(_beat, 0.0), _pulse(_beat, 0.18) * 0.6)
	var col := _colour(_shown)

	# Label: polite at first, then not. The stage on the right says what the
	# owner is doing now, so the bar is readable at a glance.
	var text := "OWNER AWARENESS"
	if _shown >= 0.95:
		text = "OWNER IS HERE"
	elif _shown >= 0.65:
		text = "OWNER IS WATCHING"
	if randf() < _shown * 0.05 * glitch:
		var i := randi() % text.length()
		text = text.substr(0, i) + ["#", "_", "!", "?"].pick_random() + text.substr(i + 1)
	var label_col := LABEL_COL.lerp(col, clampf(_shown * 1.4 - 0.3, 0.0, 1.0))
	var font := ThemeDB.fallback_font
	var fs := roundi(9 * Settings.text_scale())
	_text(font, Vector2(0, fs) + shake, text, HORIZONTAL_ALIGNMENT_LEFT, fs, label_col)
	if _shown > 0.5 and glitch > 0.0:
		# Colour-split ghost of the label.
		draw_string(font, Vector2(-1, fs) + shake, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.3, 0.9, 1.0, 0.25 * glitch))

	# Segmented bar.
	var bar := Rect2(Vector2(0, fs + 4) + shake, Vector2(size.x, 6))
	var seg_w := bar.size.x / SEGMENTS
	var lit := _shown * SEGMENTS
	for i in SEGMENTS:
		var r := Rect2(bar.position + Vector2(i * seg_w, 0), Vector2(seg_w - 1, bar.size.y))
		if i < floori(lit):
			var c := _colour(float(i) / SEGMENTS).lightened(thump * 0.35)
			# Misfiring segments near the head of the bar.
			if randf() < 0.04 * _shown * glitch and i > lit - 6:
				c = Color.WHITE if randf() < 0.5 * flash else Color.BLACK
			draw_rect(r, c)
		elif i == floori(lit):
			draw_rect(r, Color(col, fmod(lit, 1.0)))
		else:
			draw_rect(r, Color(1, 1, 1, 0.12))
	# Under the bar: what the owner is doing right now.
	_text(font, Vector2(0, bar.end.y + fs + 3), stage_name(value), HORIZONTAL_ALIGNMENT_RIGHT, fs, col.lightened(0.25))
	# Ticks where the owner's next reactions kick in.
	for t in THRESHOLDS:
		var x: float = bar.position.x + bar.size.x * t
		draw_rect(Rect2(Vector2(x - 1, bar.position.y - 2), Vector2(1, bar.size.y + 4)), Color(1, 1, 1, 0.45 if value < t else 0.15))
	# Glow under the bar that breathes with the beat.
	draw_rect(Rect2(bar.position + Vector2(0, bar.size.y + 1), Vector2(bar.size.x * _shown, 1)), Color(col, 0.25 + 0.5 * thump))
	# Jolt: a bright flash over the bar.
	if _jolt > 0.0:
		draw_rect(bar.grow(1), Color(1, 1, 1, _jolt * 0.6 * flash), false, 1.0)
	# Near the top, the bar strobes white (unless reduce flashing is on).
	if _shown >= 0.75 and fmod(_t, 0.5) < 0.12 and not Settings.reduce_flashing:
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * _shown, bar.size.y)), Color(1, 1, 1, 0.35))


## What the owner is doing at this awareness (0..1).
static func stage_name(v: float) -> String:
	for i in range(STAGES.size() - 1, -1, -1):
		if v >= STAGES[i][0]:
			return STAGES[i][1]
	return "CALM"


func _text(font: Font, pos: Vector2, text: String, align: HorizontalAlignment, fs: int, c: Color) -> void:
	var w := size.x if align == HORIZONTAL_ALIGNMENT_RIGHT else -1.0
	draw_string_outline(font, pos, text, align, w, fs, 3, Color(0, 0, 0, 0.85))
	draw_string(font, pos, text, align, w, fs, c)


func _colour(v: float) -> Color:
	if v < 0.5:
		return LOW.lerp(MID, v / 0.5)
	if v < 0.85:
		return MID.lerp(HIGH, (v - 0.5) / 0.35)
	return HIGH.lerp(PEAK, (v - 0.85) / 0.15)


func _pulse(phase: float, at: float) -> float:
	var d := phase - at
	return clampf(1.0 - absf(d) * 10.0, 0.0, 1.0)
