class_name CharacterArt
extends RefCounted
## Character portraits (docs/CHARACTER_ART.md). Drawn in code like the rest
## of the cast, from the SAME palette keys as the in-world sprite
## (PixelCharacter / Player.RUE), so a portrait always matches the figure on
## screen.
##
## The contract: a character has a portrait only if they are in CAST (their
## own 32×32 grid, the shared EXPRESSIONS plus their own extras). Anyone else
## gets no portrait at all: never somebody else's face. Rue is in CAST and so
## is Mira; the rest of the cast have briefs only. That includes Rue's restoration: until her memories come back the
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

const MIRA_GRID := [
	"................................",
	"................................",
	"................................",
	"...........oooooooooo...........",
	".........oohhhhhhhhhhoo.........",
	"........ohhhhhhhhhhhhhhoo.......",
	".......ohhhhhhhHhhhhhhhhddo.....",
	"......ohhhhhhhHHhhhhhhhhdddo....",
	"......ohhhhhhHhhHhhhhhhhhddo....",
	".....ohhhhhhHhhhhHhhhhhhhho.....",
	".....ohhhhhHssssssHhhhhhhho.....",
	".....ohhhhHssssssssHhhhhhho.....",
	".....ohhhHssssssssssssHhhho.....",
	".....ohhhssssssssssssssShho.....",
	".....ohhhssssssssssssssShho.....",
	".....ohhhssssssssssssssShho.....",
	".....ohhhssssssssssssssShho.....",
	".....ohhhssssssssssssssShho.....",
	".....ohhhSsssssssssssssShho.....",
	".....ohhhhSssssssssssssShho.....",
	".....ohhhhoSSssssssssSShhho.....",
	".....ohhhhhooSSSSSSSSoohhho.....",
	".....ohhhhhhoooSSSSoooHhhho.....",
	".....ohhhhhhooccddccoohhhhho....",
	"....ohhhhhooccccddccccoohhhho...",
	"....ohhhhoccccccddcccccCohhhho..",
	"...ohhhhocccccccddcccccCCohhho..",
	"...ohhhoccccccccccccccccCCohho..",
	"...ohhoccccccccccccccccccCCoho..",
	"...ooccccccccccccccccccccCCCoo..",
	"..occcccccccccccccccccccccCCCo..",
	"..occcccccccccccccccccccccCCCo..",
]

## Wren: a child. Round head and short fringe, two pigtails tied with green
## (d) sticking out at the sides, narrow shoulders, a green pinafore.
const WREN_GRID := [
	"................................",
	"................................",
	"................................",
	"................................",
	"...........oooooooooo...........",
	".........oohhhhhhhhhhoo.........",
	"........ohhhhhhhhhhhhhhho.......",
	".......ohhhhhhhhhhhhhhhhho......",
	".......ohhhhhhhhhhhhhhhhho......",
	"......ohhhhhhhhhhhhhhhhhhho.....",
	"......ohhhHhhhHhhhhHhhhHhho.....",
	"..oo..ohhHsssHssssHsssHhhho..oo.",
	".ohho.ohhssssssssssssssShho.ohho",
	"ohhhdoohhssssssssssssssShhoodhhh",
	"ohhhddohSssssssssssssssShSoddhhh",
	".ohhdooSsssssssssssssssssSoodhho",
	".ohhho.oSssssssssssssssssSo.ohho",
	"..ohho.oSssssssssssssssssSo.ohho",
	"..ohhho.oSsssssssssssssSSo.ohho.",
	"...ohho..oSsssssssssssSSo..ohho.",
	"...ohho...oSSssssssssSSo...oho..",
	"....oho....ooSSSSSSSSoo....oo...",
	".....oo......oSSSSSSo...........",
	"...........ooccddddccoo.........",
	".........ooccccddddccccoo.......",
	"........occcccccddcccccCCo......",
	".......occccccccddccccccCCo.....",
	"......occcccccccccccccccCCo.....",
	"......occcccccccccccccccCCCo....",
	".....occccccccccccccccccCCCo....",
	".....occccccccccccccccccCCCo....",
	".....occccccccccccccccccCCCo....",
]

## Who has a portrait: their bust grid (keys as RUE_GRID; d is trim, ribbon
## or seams in the clothes-dark colour) and expressions of their own.
const CAST := {
	"rue": {"grid": RUE_GRID, "extras": []},
	"mira": {"grid": MIRA_GRID, "extras": ["eager", "proud", "reset"]},
	"wren": {"grid": WREN_GRID, "extras": ["brave", "awed"]},
}

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
	# Mira's own: bright, a little too eager (raised brows, open smile).
	"eager": {"eye": [[0, -1], [1, -1], [0, 0], [1, 0], [0, 1], [1, 1]],
		"brows": [[10, 11], [11, 10], [12, 11], [19, 11], [20, 10], [21, 11]], "mouth": [[14, 19], [15, 20], [16, 20], [17, 19], [15, 19], [16, 19]], "cheeks": true},
	# Mira's: chin up, eyes closed, a wide smile ("MIRA WAS HERE").
	"proud": {"lids": [[-1, 1], [0, 2], [1, 2], [2, 1]],
		"brows": [[10, 11], [11, 11], [12, 11], [19, 11], [20, 11], [21, 11]], "mouth": [[13, 19], [14, 20], [15, 20], [16, 20], [17, 20], [18, 19]], "cheeks": true},
	# Wren's: brows down, mouth set. Smaller than her courage.
	"brave": {"eye": [[0, 1], [1, 1], [0, 2], [1, 2]],
		"brows": [[10, 12], [11, 12], [12, 13], [19, 13], [20, 12], [21, 12]], "mouth": [[14, 19], [15, 19], [16, 19], [17, 19]], "cheeks": true},
	# Wren's, at the Edge: wide eyes with the slot's cyan in them, mouth open.
	"awed": {"eye": [[0, -1], [1, -1], [0, 0], [1, 0], [0, 1], [1, 1], [0, 2], [1, 2]], "shine": Color("7ff6ff"),
		"brows": [[10, 11], [11, 10], [12, 11], [19, 11], [20, 10], [21, 11]], "mouth": [[15, 19], [16, 19], [15, 20], [16, 20]], "cheeks": true},
	# Mira's, after the owner resets her: wide eyes with no light in them and
	# a blank, too-wide smile.
	"reset": {"eye": [[0, 0], [1, 0], [0, 1], [1, 1]], "no_shine": true,
		"brows": [[10, 11], [11, 11], [12, 11], [19, 11], [20, 11], [21, 11]], "mouth": [[12, 19], [13, 20], [14, 20], [15, 20], [16, 20], [17, 20], [18, 20], [19, 19]], "cheeks": false},
}

## The mouth while speaking (alternates with the expression's own) and the
## eyes mid-blink: the portrait's two animation frames.
const TALK_MOUTH := [[15, 19], [16, 19], [15, 20], [16, 20]]
const BLINK_LIDS := [[0, 2], [1, 2]]

static var _cache: Dictionary = {}


## One character in one expression, in a given palette (their current look).
class Portrait:
	extends RefCounted
	var who := "rue"
	var expression := "neutral"
	var palette: Dictionary = {}

	func _init(character: String, expr: String, colours: Dictionary) -> void:
		who = character
		expression = expr if expr in CharacterArt.expressions_for(character) else "neutral"
		palette = colours

	## null for someone without a portrait (CharacterArt.CAST).
	## frame: "" (still), "talk" (mouth open) or "blink".
	func texture(frame := "") -> Texture2D:
		return CharacterArt.texture_for(self, frame)

	## The same character with another expression.
	func with(expr: String) -> Portrait:
		return Portrait.new(who, expr, palette)


## Rue as she looks right now (pass Player._palette), or fully restored.
static func rue(expression := "neutral", colours: Dictionary = {}) -> Portrait:
	return Portrait.new("rue", expression, colours if not colours.is_empty() else Player.RUE)


## Mira as her sprite looks right now (pass Npc.sprite().palette).
static func mira(expression := "neutral", colours: Dictionary = {}) -> Portrait:
	return Portrait.new("mira", expression, colours)


## The portrait of a character in the world, in their sprite's colours, or
## null if they have none.
static func for_npc(npc: Npc, expression := "neutral") -> Portrait:
	if npc == null or not has_portrait(npc.npc_id):
		return null
	return Portrait.new(npc.npc_id, expression, npc.sprite().palette)


static func has_portrait(who: String) -> bool:
	return CAST.has(who)


static func expressions_for(who: String) -> Array:
	return EXPRESSIONS + (CAST[who].extras if CAST.has(who) else [])


static func texture_for(p: Portrait, frame := "") -> Texture2D:
	if not has_portrait(p.who):
		return null  # never another character's face
	# Rue's finished art is only for her restored look; others have one look.
	var restored: bool = p.who != "rue" or (p.palette.get("s") == Player.RUE["s"] and p.palette.get("c") == Player.RUE["c"])
	var file := "%s%s/%s_%s.png" % [ART_DIR, p.who, p.who, p.expression]
	if restored and frame == "" and ResourceLoader.exists(file):
		return load(file) as Texture2D  # a finished external portrait
	var key := "%s/%s/%s/%s" % [p.who, p.expression, frame, _palette_key(p.palette)]
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(image(p, frame))
	return _cache[key]


static func _palette_key(colours: Dictionary) -> String:
	var parts: PackedStringArray = []
	for k in ["h", "s", "c", "d", "a", "e"]:
		parts.append((colours.get(k, Color.BLACK) as Color).to_html(false))
	return "-".join(parts)


## The portrait as a 32×32 image (transparent background).
static func image(p: Portrait, frame := "") -> Image:
	if not has_portrait(p.who):
		return null
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
	var grid: Array = CAST[p.who].grid
	for y in grid.size():
		var row: String = grid[y]
		for x in row.length():
			if keys.has(row[x]):
				img.set_pixel(x, y, keys[row[x]])
	var face: Dictionary = FACES.get(p.expression, FACES["neutral"]).duplicate()
	if frame == "talk" and face.has("mouth"):
		face["mouth"] = TALK_MOUTH
	elif frame == "blink" and not face.has("lids"):
		face["lids"] = BLINK_LIDS
	_draw_face(img, face, c)
	return img


## Eyes, brows, mouth and cheeks. With the face still missing (Rue before her
## last memory) only the eyes show, as two points of light.
static func _draw_face(img: Image, face: Dictionary, c: Dictionary) -> void:
	var s: Color = c.get("s", Color("f0c49c"))
	var eye_col: Color = c.get("e", Color("2a1612"))
	var has_face := s.get_luminance() > 0.2  # the void face is near-black
	var shine: Color = face.get("shine", Color("fffaf0")) if has_face else eye_col.lightened(0.5)
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
		if not face.get("no_shine", false):
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
	var exprs := expressions_for(who)
	var out := Image.create(SIZE * scale * exprs.size(), SIZE * scale, false, Image.FORMAT_RGBA8)
	out.fill(Color("282028"))
	for i in exprs.size():
		var img := image(Portrait.new(who, exprs[i], colours))
		img.resize(SIZE * scale, SIZE * scale, Image.INTERPOLATE_NEAREST)
		out.blend_rect(img, Rect2i(0, 0, SIZE * scale, SIZE * scale), Vector2i(i * SIZE * scale, 0))
	return out
