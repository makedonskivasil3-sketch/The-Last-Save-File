class_name CharacterArt
extends RefCounted
## Character portraits (docs/CHARACTER_ART.md). Drawn in code like the rest
## of the cast, from the SAME palette keys as the in-world sprite
## (PixelCharacter / Player.RUE), so a portrait always matches the figure on
## screen. That includes Rue's restoration: until her memories come back the
## portrait has the "missing" palette (cyan, a void where the face should
## be, two points of light), exactly like her sprite.
##
## A finished external portrait can replace the drawn one: put
## res://art/characters/<who>/<who>_<expression>.png (32×32, transparent,
## import with filter off) and it is used for the fully restored look.

## Expressions every major character should have, plus character-specific
## ones (docs/CHARACTER_ART.md).
const EXPRESSIONS := ["neutral", "concerned", "afraid", "relieved", "determined", "remembering"]
const SIZE := 32
const OUTLINE := Color("1a1014")
const ART_DIR := "res://art/characters/"

## Rue, 32×32 bust. Keys: h hair, H hair shade, s skin, S skin shade,
## a scarf, A scarf shade, c coat, C coat shade, d coat seams, o outline.
## The cowlick (top) is her one unique pixel in the sprite too.
const RUE_GRID := [
	".................oo.............",
	"................ohho............",
	"................oho.............",
	"...........oooooooooo...........",
	".........oohhhhhhhhhhoo.........",
	"........ohhhhhhhhhhhhhho........",
	".......ohhhhhhhhhhhhhhhho.......",
	"......ohhhhhhhhhhhhhhhhhho......",
	"......ohhhhhhhhhhhhhhhhhho......",
	".....ohhhhHhhhhhhhhhhHhhhho.....",
	".....ohhhHHhhhhhhhhhhHHhhho.....",
	".....ohhHssHhhHsHhhhHssHhho.....",
	".....ohHsssshHsssHhHssssHho.....",
	"....ohhHssssssssssssssssHhho....",
	"....ohhsssssssssssssssssShho....",
	"....ohhsssssssssssssssssShho....",
	"....ohhsssssssssssssssssShho....",
	".....ohsssssssssssssssssSho.....",
	".....ohSssssssssssssssssSho.....",
	"......oSssssssssssssssssSo......",
	".......oSSssssssssssssSSo.......",
	"........ooSSssssssssSSoo........",
	".........oaaaSSSSSSaaAo.........",
	".......ooaaaaaaaaaaaaAAoo.......",
	".....oocdaaaaaaaaaaaaAAdcoo.....",
	"....occcdAaaaaaaaaaaaAAdccco....",
	"...occcccdAAaaaaaaaaAAdccccCo...",
	"..occcccccdAAAAAAAAAAdcccccCCo..",
	"..occccccdccdddaadddcccccccCCo..",
	".occcccccccccddaaddccccccccCCCo.",
	".occcccccdcccdaaaadccccccccCCCo.",
	".occcccccccccdaaaadccccccccCCCo.",
]

## Face features per expression, in grid coordinates. Eyes are drawn at
## x0 = 11 (left) and 19 (right), offsets from row 14. "lids" draws closed
## or smiling eyes as a line instead. Brows use the hair shade.
const FACES := {
	"neutral": {"eye": [[0, 0], [1, 0], [0, 1], [1, 1], [0, 2], [1, 2]],
		"brows": [[10, 12], [11, 12], [12, 12], [19, 12], [20, 12], [21, 12]], "mouth": [[15, 19], [16, 19]], "cheeks": true},
	"concerned": {"eye": [[0, 1], [1, 1], [0, 2], [1, 2]],
		"brows": [[10, 13], [11, 12], [12, 11], [19, 11], [20, 12], [21, 13]], "mouth": [[14, 20], [15, 19], [16, 19], [17, 20]], "cheeks": true},
	"afraid": {"eye": [[0, -1], [1, -1], [0, 0], [1, 0], [0, 1], [1, 1], [0, 2], [1, 2]], "white_ring": true,
		"brows": [[10, 12], [11, 11], [12, 11], [19, 11], [20, 11], [21, 12]], "mouth": [[15, 19], [16, 19], [15, 20], [16, 20]], "cheeks": false},
	"relieved": {"lids": [[-1, 1], [0, 2], [1, 2], [2, 1]],
		"brows": [[10, 12], [11, 12], [12, 12], [19, 12], [20, 12], [21, 12]], "mouth": [[14, 19], [15, 20], [16, 20], [17, 19]], "cheeks": true},
	"determined": {"eye": [[0, 1], [1, 1], [0, 2], [1, 2]],
		"brows": [[10, 12], [11, 12], [12, 13], [19, 13], [20, 12], [21, 12]], "mouth": [[14, 19], [15, 19], [16, 19], [17, 19]], "cheeks": false},
	"remembering": {"lids": [[-1, 2], [0, 2], [1, 2], [2, 2]],
		"brows": [[10, 12], [11, 12], [12, 12], [19, 12], [20, 12], [21, 12]], "mouth": [[15, 19], [16, 19]], "cheeks": true},
}

static var _cache: Dictionary = {}


## One character in one expression, in a given palette (their current look).
class Portrait:
	extends RefCounted
	var who := "rue"
	var expression := "neutral"
	var palette: Dictionary = {}

	func _init(character: String, expr: String, colours: Dictionary) -> void:
		who = character
		expression = expr if expr in CharacterArt.EXPRESSIONS else "neutral"
		palette = colours

	func texture() -> Texture2D:
		return CharacterArt.texture_for(self)

	## The same character with another expression.
	func with(expr: String) -> Portrait:
		return Portrait.new(who, expr, palette)


## Rue as she looks right now (pass Player._palette), or fully restored.
static func rue(expression := "neutral", colours: Dictionary = {}) -> Portrait:
	return Portrait.new("rue", expression, colours if not colours.is_empty() else Player.RUE)


static func texture_for(p: Portrait) -> Texture2D:
	var restored: bool = p.palette.get("s") == Player.RUE["s"] and p.palette.get("c") == Player.RUE["c"]
	var file := "%s%s/%s_%s.png" % [ART_DIR, p.who, p.who, p.expression]
	if restored and ResourceLoader.exists(file):
		return load(file) as Texture2D  # a finished external portrait
	var key := "%s/%s/%s" % [p.who, p.expression, _palette_key(p.palette)]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(image(p))
	return _cache[key]


static func _palette_key(colours: Dictionary) -> String:
	var parts: PackedStringArray = []
	for k in ["h", "s", "c", "d", "a", "e"]:
		parts.append((colours.get(k, Color.BLACK) as Color).to_html(false))
	return "-".join(parts)


## The portrait as a 32×32 image (transparent background).
static func image(p: Portrait) -> Image:
	var c := p.palette
	var h: Color = c.get("h", Color("8a4f2c"))
	var s: Color = c.get("s", Color("f0c49c"))
	var a: Color = c.get("a", Color("d8463a"))
	var coat: Color = c.get("c", Color("e9b44c"))
	var keys := {
		"h": h, "H": h.darkened(0.25), "s": s, "S": s.darkened(0.12),
		"a": a, "A": a.darkened(0.22), "c": coat, "C": coat.darkened(0.18),
		"d": c.get("d", coat.darkened(0.3)), "o": OUTLINE,
	}
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in RUE_GRID.size():
		var row: String = RUE_GRID[y]
		for x in row.length():
			if keys.has(row[x]):
				img.set_pixel(x, y, keys[row[x]])
	_draw_face(img, FACES.get(p.expression, FACES["neutral"]), c)
	return img


## Eyes, brows, mouth and cheeks. With the face still missing (Rue before her
## last memory) only the eyes show, as two points of light.
static func _draw_face(img: Image, face: Dictionary, c: Dictionary) -> void:
	var s: Color = c.get("s", Color("f0c49c"))
	var eye_col: Color = c.get("e", Color("2a1612"))
	var has_face := s.get_luminance() > 0.2  # the void face is near-black
	var shine := Color("fffaf0") if has_face else eye_col.lightened(0.5)
	for x0 in [11, 19]:
		if face.has("lids"):
			for o in face.lids:
				img.set_pixel(x0 + o[0], 14 + o[1], eye_col)
			continue
		if face.get("white_ring", false) and has_face:
			for dx in range(-1, 3):
				img.set_pixel(x0 + dx, 12, Color("fffaf0"))
		var top := 99
		for o in face.eye:
			img.set_pixel(x0 + o[0], 14 + o[1], eye_col)
			top = mini(top, o[1])
		img.set_pixel(x0, 14 + top, shine)
	if not has_face:
		return
	var brow: Color = (c.get("h", Color("8a4f2c")) as Color).darkened(0.25)
	for b in face.brows:
		img.set_pixel(b[0], b[1], brow)
	var mouth := s.darkened(0.45).lerp(Color("9a3a30"), 0.4)
	for m in face.mouth:
		img.set_pixel(m[0], m[1], mouth)
	if face.get("cheeks", false):
		var blush := s.lerp(c.get("a", Color("d8463a")), 0.3)
		for px in [[10, 18], [11, 18], [20, 18], [21, 18]]:
			img.set_pixel(px[0], px[1], blush)


## A reference sheet of every expression, in a palette, scaled up (docs).
static func sheet(who: String, colours: Dictionary, scale := 6) -> Image:
	var out := Image.create(SIZE * scale * EXPRESSIONS.size(), SIZE * scale, false, Image.FORMAT_RGBA8)
	out.fill(Color("282028"))
	for i in EXPRESSIONS.size():
		var img := image(Portrait.new(who, EXPRESSIONS[i], colours))
		img.resize(SIZE * scale, SIZE * scale, Image.INTERPOLATE_NEAREST)
		out.blend_rect(img, Rect2i(0, 0, SIZE * scale, SIZE * scale), Vector2i(i * SIZE * scale, 0))
	return out
