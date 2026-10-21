class_name PortraitAsset
extends Resource
## Approved bust art for one exact identity, expression and gameplay palette.
## Missing variants deliberately use the shared illustrated fallback.

@export var who := ""
@export var expression := "neutral"
@export var version := 1
@export var provenance := ""
@export var rights := ""
@export var palette: Dictionary = {}
@export var still: Texture2D
@export var talk: Texture2D
@export var blink: Texture2D
## Normalised crop; all frames share its size and placement.
@export var crop := Rect2(0, 0, 1, 1)

func matches(p: CharacterArt.Portrait) -> bool:
	if p == null or not CharacterArt.has_portrait(who) or who != p.who or expression != p.expression:
		return false
	if version < 1 or provenance.strip_edges() == "" or rights.strip_edges() == "" or palette.size() != p.palette.size():
		return false
	for key in palette:
		if not p.palette.has(key):
			return false
		if palette[key] is Color and p.palette[key] is Color:
			if not (palette[key] as Color).is_equal_approx(p.palette[key]):
				return false
		elif palette[key] != p.palette[key]:
			return false
	if still == null or still.get_width() < 64 or still.get_width() > 2048 or still.get_height() != still.get_width():
		return false
	if not crop.has_area() or not Rect2(0, 0, 1, 1).encloses(crop) or not is_equal_approx(crop.size.x, crop.size.y):
		return false
	for tex in [talk, blink]:
		if tex and tex.get_size() != still.get_size():
			return false
	return true

func texture(frame: String) -> Texture2D:
	if frame == "talk" and talk:
		return talk
	if frame == "blink" and blink:
		return blink
	return still
