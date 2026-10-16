class_name MapView
extends Control
## The pause menu's map: every area as a box, where you are, where you've
## been, and how many of your memories each place still holds. Places you
## haven't found yet are "???".

## Area id -> [display name, centre on the map (0..1 of the control)].
const NODES := {
	"edge": ["THE EDGE", Vector2(0.5, 0.12)],
	"room": ["ARIN'S ROOM", Vector2(0.14, 0.46)],
	"square": ["ASHVALE", Vector2(0.5, 0.46)],
	"archive": ["THE ARCHIVE", Vector2(0.86, 0.46)],
	"oob": ["OUT OF BOUNDS", Vector2(0.5, 0.84)],
	"bin": ["RECYCLE BIN", Vector2(0.86, 0.84)],
	"house": ["ARIN'S HOUSE", Vector2(0.14, 0.12)],
}
const LINKS := [["room", "square"], ["square", "archive"], ["square", "edge"], ["square", "oob"], ["archive", "bin"], ["square", "house"]]
const BOX := Vector2(84, 22)
const CYAN := Color("8cf2ff")
const TEXT := Color("c8b8a0")
const DIM := Color("8a8f98")

## Set before showing: the current area id and the ids visited this session
## (plus anything the save remembers, e.g. Pip's home once Pip is found).
var current := ""
var visited: Dictionary = {}

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var fs := roundi(8 * Settings.text_scale())
	for link in LINKS:
		var a := _centre(link[0])
		var b := _centre(link[1])
		var known: bool = visited.has(link[0]) and visited.has(link[1])
		draw_line(a, b, Color(TEXT, 0.35 if known else 0.12), 1.0)
	for id: String in NODES:
		var c := _centre(id)
		var r := Rect2(c - BOX * 0.5, BOX)
		var here := id == current
		var seen := visited.has(id) or here
		draw_rect(r, Color(0.02, 0.02, 0.03, 0.9))
		var border := CYAN if here else (Color(TEXT, 0.6) if seen else Color(DIM, 0.3))
		if here:
			border = Color(CYAN, 0.6 + 0.4 * sin(_t * 4.0))
		draw_rect(r, border, false, 1.0)
		var label: String = NODES[id][0] if seen else "???"
		draw_string(font, Vector2(r.position.x, c.y + 1), label, HORIZONTAL_ALIGNMENT_CENTER, BOX.x, fs,
				CYAN if here else (TEXT if seen else DIM))
		if seen:
			_draw_memories(id, Vector2(c.x, r.end.y + 4))
	draw_string(font, Vector2(0, size.y - 2), "cyan dots: your memories (filled = found)", HORIZONTAL_ALIGNMENT_CENTER, size.x, fs - 1, Color(DIM, 0.8))


## One dot per memory in this area: filled if you have it.
func _draw_memories(id: String, at: Vector2) -> void:
	var frags := Story.fragments_in(id)
	var x := at.x - (frags.size() - 1) * 4.0
	for f in frags:
		var p := Vector2(x, at.y)
		if OwnerMemory.has_fragment(f.id):
			draw_circle(p, 2.0, CYAN)
		else:
			draw_arc(p, 2.0, 0.0, TAU, 8, Color(CYAN, 0.6), 1.0)
		x += 8.0


func _centre(id: String) -> Vector2:
	var rel: Vector2 = NODES[id][1]
	return Vector2(rel.x * size.x, rel.y * (size.y - 10.0))
