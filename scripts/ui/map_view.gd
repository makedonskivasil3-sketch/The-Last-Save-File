class_name MapView
extends Control
## The pause menu's map: every area as a box, and how many of your memories
## each place still holds. Four things are kept apart:
##   discovered   found in any run (OwnerMemory.places): named
##   visited      been there this run (World._visited): drawn bright
##   accessible   a way there is open right now; a found place that isn't
##                says why ("locked", "no way back in", "not loaded")
##   current      where you are: cyan
## Places never found are "???", so nothing unvisited is given away.

## Area id -> [display name, centre on the map (0..1 of the control)].
const NODES := {
	"edge": ["THE EDGE", Vector2(0.37, 0.12)],
	"room": ["ARIN'S ROOM", Vector2(0.12, 0.46)],
	"square": ["ASHVALE", Vector2(0.37, 0.46)],
	"archive": ["THE ARCHIVE", Vector2(0.64, 0.46)],
	"oob": ["OUT OF BOUNDS", Vector2(0.37, 0.84)],
	"bin": ["RECYCLE BIN", Vector2(0.89, 0.46)],
	"workshop": ["WORKSHOP", Vector2(0.64, 0.84)],
	"house": ["ARIN'S HOUSE", Vector2(0.12, 0.12)],
}
const LINKS := [["room", "square"], ["square", "archive"], ["square", "edge"], ["square", "oob"], ["archive", "bin"], ["square", "house"], ["archive", "workshop"]]
const BOX := Vector2(84, 22)
const CYAN := Color("8cf2ff")
const TEXT := Color("c8b8a0")
const DIM := Color("8a8f98")

## Set before showing (World.map_state()): the current area id, places found
## in any run, places visited this run, and id -> why it's closed now
## ("" or missing: open).
var current := ""
var discovered: Dictionary = {}
var visited: Dictionary = {}
var closed: Dictionary = {}

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var font := UiStyle.system_font()
	var fs := roundi(8 * Settings.text_scale())
	for link in LINKS:
		var a := _centre(link[0])
		var b := _centre(link[1])
		var known: bool = is_found(link[0]) and is_found(link[1])
		draw_line(a, b, Color(TEXT, 0.35 if known else 0.12), 1.0)
	if LanternRoute.repaired() and is_found("workshop"):
		draw_line(_centre("workshop"), _centre("oob"), Color(CYAN, 0.65), 2.0)
	for id: String in NODES:
		var c := _centre(id)
		var r := Rect2(c - BOX * 0.5, BOX)
		var here := id == current
		var found := is_found(id)
		var this_run := visited.has(id) or here
		draw_rect(r, Color(0.02, 0.02, 0.03, 0.9))
		var border := Color(TEXT, 0.6) if this_run else (Color(TEXT, 0.3) if found else Color(DIM, 0.3))
		if here:
			border = Color(CYAN, 0.6 + 0.4 * sin(_t * 4.0))
		draw_rect(r, border, false, 1.0)
		var label: String = NODES[id][0] if found else "???"
		var baseline := c.y + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5
		draw_string(font, Vector2(r.position.x, baseline), label, HORIZONTAL_ALIGNMENT_CENTER, BOX.x, fs,
				CYAN if here else (TEXT if this_run else (Color(TEXT, 0.6) if found else DIM)))
		if found:
			_draw_memories(id, Vector2(c.x, r.end.y + 4))
			var why: String = closed.get(id, "")
			if why != "" and not here:
				draw_string(font, Vector2(r.position.x, r.position.y - 2), why, HORIZONTAL_ALIGNMENT_CENTER, BOX.x, fs - 2, Color(DIM, 0.9))
	draw_string(font, Vector2(0, size.y - 2), "bright: been there this run · dim: found before · dots: your memories", HORIZONTAL_ALIGNMENT_CENTER, size.x, fs - 1, Color(DIM, 0.8))


## Found in any run (or this one, or where you are).
func is_found(id: String) -> bool:
	return discovered.has(id) or visited.has(id) or id == current


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
