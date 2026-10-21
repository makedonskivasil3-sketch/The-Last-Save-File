class_name PortraitArt
extends RefCounted
## Finished external portrait art, resolved for the live dialogue and
## cinematic portraits (PortraitView). The procedural bust (IllustratedCharacter)
## stays the fallback, so a character always has a face, and the right one.
##
## One folder per character, `<ROOT>/<who>/`:
##   portrait.json   the contract for the set (below)
##   <expression>.png, optional <expression>_talk.png and _blink.png
##
## portrait.json:
##   {"version": 1,
##    "size": [w, h],            every image in the set has exactly this size
##    "anchor": [x, y],          the face centre, 0..1 of the image (stable crop)
##    "zoom": 1.0,               the image width as a share of the frame
##    "palette": {"h": "#..."},  the look the art was painted for (story state)
##    "provenance": "who made it, licence"}
##
## The art is used only when the character looks exactly like that now: every
## palette key in the manifest must match the portrait's current colours. So a
## finished, restored Rue never shows over her missing face or a part-restored
## look, and Wren's painted ribbon never comes back while she has lost it. Any
## other look falls back to the procedural bust, which follows every state.
## A missing expression uses the set's neutral image (identity stays steady
## across a conversation); missing, unreadable or wrongly sized files fall back
## and warn once. Everything is resolved when the portrait changes, never per draw.

const ROOT := "res://art/portraits/"
## Where sets are looked up (tests point it at a fixture folder).
static var root := ROOT

## Accepted image sizes (pixels, each side).
const MIN_SIDE := 16
const MAX_SIDE := 4096


## A resolved set for one character in one expression.
class Art:
	extends RefCounted
	var who := ""
	var expression := ""
	## "" (still), "talk", "blink" -> Texture2D. "" is always present.
	var frames: Dictionary = {}
	var anchor := Vector2(0.5, 0.42)
	var zoom := 1.0
	var size := Vector2i.ZERO

	func texture(frame: String) -> Texture2D:
		return frames.get(frame, frames[""])


static var _manifests: Dictionary = {}  # who -> Dictionary ({} = none / invalid)
static var _cache: Dictionary = {}  # key -> Art or null
static var _warned: Dictionary = {}


## Forget everything loaded (tests, or after new art is installed).
static func clear_cache() -> void:
	_manifests.clear()
	_cache.clear()
	_warned.clear()


## The finished art for this portrait in its current state, or null to draw
## the procedural bust.
static func resolve(p: CharacterArt.Portrait) -> Art:
	if p == null:
		return null
	var m := _manifest(p.who)
	if m.is_empty() or not _matches(m, p.palette):
		return null
	var key := "%s|%s|%s" % [root, p.who, p.expression]
	if _cache.has(key):
		return _cache[key]
	var art := _load_set(p.who, p.expression, m)
	if art == null and p.expression != "neutral":
		art = _load_set(p.who, "neutral", m)  # the set's own face, never the procedural one mid-scene
	_cache[key] = art
	return art


## Does the set's painted look match these colours (every key it declares)?
static func _matches(m: Dictionary, colours: Dictionary) -> bool:
	var want: Dictionary = m.get("palette", {})
	if want.is_empty():
		return false  # a set must say which look it was painted for
	for k in want:
		if not colours.has(k):
			return false
		if (colours[k] as Color).to_html(false) != Color(str(want[k])).to_html(false):
			return false
	return true


static func _manifest(who: String) -> Dictionary:
	var k := root + who
	if _manifests.has(k):
		return _manifests[k]
	var out := {}
	var path := "%s%s/portrait.json" % [root, who]
	if FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary and _valid_manifest(parsed):
			out = parsed
		else:
			_warn(path, "portrait.json is not a valid set (version, size, palette)")
	_manifests[k] = out
	return out


static func _valid_manifest(m: Dictionary) -> bool:
	var s: Variant = m.get("size")
	return int(m.get("version", 0)) == 1 and s is Array and (s as Array).size() == 2 \
		and m.get("palette") is Dictionary


static func _load_set(who: String, expression: String, m: Dictionary) -> Art:
	var want := Vector2i(int(m["size"][0]), int(m["size"][1]))
	var still := _load_image_texture("%s%s/%s.png" % [root, who, expression], want)
	if still == null:
		return null
	var art := Art.new()
	art.who = who
	art.expression = expression
	art.size = want
	art.frames[""] = still
	for f in ["talk", "blink"]:
		var t := _load_image_texture("%s%s/%s_%s.png" % [root, who, expression, f], want)
		if t:
			art.frames[f] = t
	var a: Variant = m.get("anchor", [0.5, 0.42])
	if a is Array and (a as Array).size() == 2:
		art.anchor = Vector2(clampf(float(a[0]), 0.0, 1.0), clampf(float(a[1]), 0.0, 1.0))
	art.zoom = clampf(float(m.get("zoom", 1.0)), 0.25, 4.0)
	return art


## An imported texture (res://) or a plain PNG on disk (user://, fixtures).
## Wrong size or unreadable: null, with one warning.
static func _load_image_texture(path: String, want: Vector2i) -> Texture2D:
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
	else:
		return null  # simply not drawn (yet): no warning
	if tex == null:
		_warn(path, "unreadable image")
		return null
	var s := Vector2i(tex.get_width(), tex.get_height())
	if s != want or s.x < MIN_SIDE or s.y < MIN_SIDE or s.x > MAX_SIDE or s.y > MAX_SIDE:
		_warn(path, "image is %s, the set says %s" % [s, want])
		return null
	return tex


static func _warn(path: String, why: String) -> void:
	if _warned.has(path):
		return
	_warned[path] = true
	push_warning("PortraitArt: %s: %s; using the drawn portrait" % [path, why])
