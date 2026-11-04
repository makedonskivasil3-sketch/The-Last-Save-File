class_name CharacterSheet
extends HeroFigure
## An artist's sprite sheet for one character (docs/ART_BIBLE.md,
## "Pipeline"): assets/characters/<who>/sheet.png and sheet.json. When a
## sheet is present and valid it is drawn; for any clip it doesn't have, and
## for the effects that need the rig (the tear slices), the procedural
## HeroFigure underneath draws instead. A missing or broken sheet is never
## an error: CharacterArt.figure() simply doesn't use it.
##
## sheet.json:
##   {"frame": [w, h], "feet": [x, y], "px_per_unit": 2.0,
##    "rows": ["idle.front", "idle.back", "idle.side", "walk.front", ...],
##    "clips": {"idle": {"frames": 6, "fps": 6}, "walk": {"frames": 8, "fps": 12}, ...}}
## Row r of the png holds the frames of rows[r], left to right. "side"
## faces right; left is mirrored. "feet" is where the feet are in a frame,
## and px_per_unit how many sheet pixels make one logical pixel.

const ROOT := "res://assets/characters/"
const CLIPS := ["idle", "walk", "run", "crouch", "interact", "habit", "spin", "wave", "talk"]
const VIEWS := ["front", "back", "side"]

## Where sheets are looked for (tests point it at user://).
static var root := ROOT

var who := ""
var texture: Texture2D
var frame_size := Vector2.ZERO
var feet := Vector2.ZERO
var px_per_unit := 2.0
## "clip.view" -> row index.
var rows := {}
var clips := {}


## The sheet for `who`, or null when there is none or it can't be used.
static func load_for(name: String, body_kind: String, colours: Dictionary) -> CharacterSheet:
	var dir := root.path_join(name)
	var json_path := dir.path_join("sheet.json")
	var png_path := dir.path_join("sheet.png")
	if not FileAccess.file_exists(json_path):
		return null
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	if not data is Dictionary:
		push_warning("CharacterSheet: %s is not a JSON object; using the procedural figure" % json_path)
		return null
	var tex := _texture(png_path)
	if tex == null:
		push_warning("CharacterSheet: %s has no readable sheet.png; using the procedural figure" % dir)
		return null
	var s := CharacterSheet.new(body_kind, colours)
	s.who = name
	s.texture = tex
	if not s._read(data):
		push_warning("CharacterSheet: %s doesn't describe its frames (frame, feet, rows, clips); using the procedural figure" % json_path)
		return null
	return s


static func _texture(path: String) -> Texture2D:
	if path.begins_with("res://") and ResourceLoader.exists(path):
		return load(path) as Texture2D
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	return ImageTexture.create_from_image(img) if img and not img.is_empty() else null


func _read(d: Dictionary) -> bool:
	var f: Variant = d.get("frame")
	var ft: Variant = d.get("feet")
	if not (f is Array and f.size() == 2 and ft is Array and ft.size() == 2):
		return false
	frame_size = Vector2(float(f[0]), float(f[1]))
	feet = Vector2(float(ft[0]), float(ft[1]))
	px_per_unit = maxf(0.25, float(d.get("px_per_unit", 2.0)))
	if frame_size.x <= 0.0 or frame_size.y <= 0.0:
		return false
	var r: Variant = d.get("rows")
	var c: Variant = d.get("clips")
	if not (r is Array and c is Dictionary):
		return false
	for i in r.size():
		rows[str(r[i])] = i
	for name: String in c:
		var clip: Variant = c[name]
		if clip is Dictionary and int(clip.get("frames", 0)) > 0:
			clips[name] = {"frames": int(clip.frames), "fps": maxf(1.0, float(clip.get("fps", 8.0)))}
	# The sheet must at least stand still facing the camera, and every row it
	# names must be inside the image.
	if not rows.has("idle.front") or not clips.has("idle"):
		return false
	if rows.size() * frame_size.y > texture.get_height() + 0.5:
		return false
	for key: String in rows:
		var clip_name := key.get_slice(".", 0)
		if clips.has(clip_name) and clips[clip_name].frames * frame_size.x > texture.get_width() + 0.5:
			return false
	return true


## The clip the figure's state asks for (the same state HeroFigure reads).
func clip_name() -> String:
	if spin > 0.0:
		return "spin"
	if habit > 0.0:
		return "habit"
	if crouch:
		return "crouch"
	if pointing:
		return "interact"
	if waving:
		return "wave"
	if moving:
		return "run" if _speed > 70.0 else "walk"
	if talking:
		return "talk"
	return "idle"


func view_name() -> String:
	if facing == Vector2.UP:
		return "back"
	return "side" if facing.x != 0.0 else "front"


## [row, frame] for the current state, or [] when the sheet hasn't got it.
func current_frame() -> Array:
	var c := clip_name()
	var v := view_name()
	for key in [c + "." + v, c + ".front", "idle." + v, "idle.front"]:
		if rows.has(key):
			var clip: Dictionary = clips.get(key.get_slice(".", 0), {})
			if clip.is_empty():
				continue
			var n: int = clip.frames
			# Walking frames follow the stride (one stride per PI of _walk), so
			# the feet don't slide; the rest play at their own rate.
			var i := int(_walk * 0.5 * n) % n if key.begins_with("walk") or key.begins_with("run") else int(_t * clip.fps) % n
			return [int(rows[key]), i]
	return []


func draw(ci: CanvasItem, opts: Dictionary = {}) -> void:
	var slices: Array = opts.get("slices", [0.0, 0.0, 0.0])
	var at := current_frame()
	# Effects that cut the figure apart need the rig: the procedural one.
	if at.is_empty() or slices.any(func(s: float) -> bool: return absf(s) > 0.01):
		super(ci, opts)
		return
	var offset: Vector2 = opts.get("offset", Vector2.ZERO)
	var alpha: float = opts.get("alpha", 1.0)
	var solid: Variant = opts.get("solid", null)
	var grey: bool = opts.get("grey", false)
	var k: float = opts.get("scale", 1.0)
	var rot: float = opts.get("rotation", 0.0)
	var flip := -1.0 if facing.x < 0.0 else 1.0
	var unit := k / px_per_unit
	ci.draw_set_transform(offset + Vector2(0, FEET_Y).rotated(rot) * k, rot, Vector2(flip * unit, unit))
	var src := Rect2(Vector2(at[1] * frame_size.x, at[0] * frame_size.y), frame_size)
	var mod := Color(1, 1, 1, alpha)
	var tex := texture
	if solid != null:
		# A silhouette, as the procedural rig draws it (rim light, shadow,
		# the owner's colour split): the sheet's shape, one colour.
		mod = Color(solid, (solid as Color).a * alpha)
		tex = silhouette()
	elif grey:
		mod = Color(0.62, 0.62, 0.66, alpha)
	ci.draw_texture_rect_region(tex, Rect2(-feet, frame_size), src, mod)
	if left_running and solid == null:
		ci.draw_set_transform(offset + Vector2(0, FEET_Y).rotated(rot) * k, rot, Vector2(k, k))
		_shimmer(ci, alpha)
	ci.draw_set_transform(Vector2.ZERO)


var _silhouette: Texture2D


## The sheet with every opaque pixel white (alpha kept), built once: drawn
## modulated by a colour, it is a true silhouette, not a tint (UI-5). Falls
## back to the sheet itself where the renderer can't read pixels back.
func silhouette() -> Texture2D:
	if _silhouette:
		return _silhouette
	var img := texture.get_image() if texture else null
	if img == null or img.is_empty():
		_silhouette = texture
		return _silhouette
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				img.set_pixel(x, y, Color(1, 1, 1, c.a))
	_silhouette = ImageTexture.create_from_image(img)
	return _silhouette

