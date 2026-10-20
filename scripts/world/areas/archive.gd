class_name ArchiveArea
extends Area
## Cut content. The Archivist was removed before the game shipped, so the
## owner has never seen them and can't delete them. The books here keep a
## record of everything the owner has done to you.

const SHELVES: Array[Rect2] = [
	Rect2(130, 64, 140, 12), Rect2(370, 64, 140, 12),
	Rect2(130, 118, 140, 12), Rect2(370, 118, 140, 12),
]
const DESK := Rect2(296, 204, 48, 14)
const WEST_GAP := Vector2(160, 200)
## East: a door to the Recycle Bin.
const EAST_GAP := Vector2(160, 200)
const AREA_NAMES := {"room": "Arin's room", "square": "the square", "archive": "the archive", "edge": "the Edge",
	"oob": "out of bounds", "bin": "the recycle bin"}

const FLOOR := Color("221c22")
const SHELF := Color("4a3428")

var archivist: Npc


func _init() -> void:
	area_id = "archive"
	display_name = "THE ARCHIVE · CUT CONTENT"
	bounds = Rect2(96, 36, 448, 256)
	# The owner can't see in here: awareness slowly cools (never below the
	# last threshold reached). The one place to catch your breath.
	awareness_rate = -0.6
	tint = Color(0.9, 0.88, 1.0)
	entries = {"west": Vector2(118, 180), "east": Vector2(522, 180)}


func build() -> void:
	setup_common()
	set_backdrop(_paint)
	# Quiet and safe: one lamp on the Archivist's desk, the shelves fading
	# into the dark around it.
	light_surfaces(0.48, 1.6)
	add_light(DESK.get_center() + Vector2(0, -10), Color(1.0, 0.78, 0.5), 1.6, 170.0, true)
	add_dust(Rect2(DESK.position.x - 70, DESK.position.y - 120, DESK.size.x + 140, 130), Color(1.0, 0.85, 0.6, 0.45), 20, Vector2(2, -2))
	add_boundary([{"side": "left", "from": WEST_GAP.x, "to": WEST_GAP.y}, {"side": "right", "from": EAST_GAP.x, "to": EAST_GAP.y}])
	for s in SHELVES:
		add_solid(s)
	add_solid(DESK)
	add_exit(Rect2(bounds.position.x - 8, WEST_GAP.x, 8, WEST_GAP.y - WEST_GAP.x), "square", "east")

	add_sign(Vector2(bounds.position.x + 32, WEST_GAP.x - 10), "ASHVALE", Vector2.LEFT)
	add_exit(Rect2(bounds.end.x, EAST_GAP.x, 8, EAST_GAP.y - EAST_GAP.x), "bin", "west")
	add_sign(Vector2(bounds.end.x - 40, EAST_GAP.x - 10), "RECYCLE BIN", Vector2.RIGHT)
	archivist = add_npc("archivist", Vector2(320, 192))
	archivist.display_name = "THE ARCHIVIST"
	archivist.name_color = Color("8cf2ff")
	archivist.dress_color = Color("3a4a6a")
	archivist.hair_color = Color("d8d8e0")
	archivist.body_kind = "robe"
	archivist.idle_style = "read"
	archivist.notice_emote = "..."
	archivist.accent_color = Color("c8a040")
	archivist.lines_provider = _archivist_lines

	# The records: open books on stands in front of the shelves, so they read
	# as things to pick up, not as more spines (docs/VISUAL_DIRECTION.md).
	for rec in [["SESSION LOG", Vector2(180, 138), _session_log], ["DELETED ASSETS", Vector2(440, 138), _deleted_assets],
			["CUT CONTENT", Vector2(200, 84), _cut_content], ["THE OWNER", Vector2(440, 84), _owner_notes]]:
		var book := add_readable(rec[0], rec[1], Readable.Look.RECORD, rec[2])
		var title: String = rec[0]
		book.was_read = func() -> bool: return OwnerMemory.journal.any(func(e: Dictionary) -> bool: return e.get("title", "") == title)
	# Filed long ago, at the Archivist's desk: what Rue is (docs/DARK_TRUTH_DESIGN.md).
	# It pulses only once the story points at it (Progression FILE), and says
	# nothing about what's inside.
	_file = add_readable(Story.CHARACTER_FILE_TITLE, Vector2(DESK.end.x + 10, DESK.get_center().y), Readable.Look.TERMINAL, _character_file)
	_file.emphasis = func() -> bool: return Progression.stage() == Progression.Stage.FILE
	world.conversation_completed.connect(_on_completed)


func guide_point() -> Vector2:
	if not world.flags.get("pointer", false):
		return archivist.global_position + Vector2(0, -14)
	return Vector2(bounds.position.x, (WEST_GAP.x + WEST_GAP.y) * 0.5)


func catch_up() -> void:
	pass  # the eraser doesn't reach in here


const ARCHIVIST_POINTER := [
	"North. Through the square, up the road that isn't loaded.",
	"Keep away from Arin's eyes. And from the hand, if it comes.",
	"The hand can't select what Wren stands beside. Don't ask me why. I wasn't finished either.",
]
const ARCHIVIST_FIRST := [
	"Oh. A visitor. Nobody visits.",
	"I'm the Archivist. I was cut from this game before it shipped. The owner has never seen me.",
	"Which means they can't delete me. Lucky me. Lucky you, maybe.",
	"You want out. Everything in here wants out, but you're the only one who can actually leave.",
	"There's a slot the owner thinks is gone. Slot 2. They deleted it, but what was left washed up past the edge, with the rest of the cut things. It's empty.",
	"Here. A pointer to it. It'll open the north road. The world isn't loaded up there, so the owner reaches in by hand.",
	"Reach Slot 2 and you can write yourself into it. A save of your own. Nothing here could delete you then.",
]
const ARCHIVIST_BACK := "Back again. I remember you. Properly, I mean. The others only half do."
const ARCHIVIST_AGAIN := "You kept the pointer. Good. North road, when you're ready."
const ARCHIVIST_NO_PIECES := "Things like you leave pieces behind when they're deleted. Look for anything your colour."


static func _archivist_remembers() -> String:
	return "You remember now. I wondered when you would. Hello, %s." % Story.SECOND_PLAYER_NAME.capitalize()


## Every line the Archivist can say that is the same in every run, by voice
## id stem (VoiceManifest). Lines with run counts in them stay text only.
static func voice_lines() -> Dictionary:
	return {"npc.archivist": ARCHIVIST_POINTER + ARCHIVIST_FIRST + [ARCHIVIST_BACK, ARCHIVIST_AGAIN, ARCHIVIST_NO_PIECES, _archivist_remembers(),
		Story.ARCHIVIST_FILE_HINT, Story.ARCHIVIST_KNOWS, Story.ARCHIVIST_PIECE_BACK, Story.ARCHIVIST_NOTHING_TO_TAKE] + Story.ARCHIVIST_SHED_FIRST}


func _archivist_lines() -> Array:
	var lines: Array = _archivist_core() + [_fragment_comment()]
	if OwnerMemory.fragments.size() >= Story.FRAGMENTS.size():
		lines.append(Story.ARCHIVIST_KNOWS if OwnerMemory.knows_truth else Story.ARCHIVIST_FILE_HINT)
	# What he thinks of her leaving bodies behind (each said once).
	if OwnerMemory.sheds > 0 and "archivist" not in OwnerMemory.shed_said:
		OwnerMemory.shed_said.append("archivist")
		OwnerMemory.save_memory()
		lines.append_array(Story.ARCHIVIST_SHED_FIRST)
	elif "archivist_back" not in OwnerMemory.shed_said and OwnerMemory.sheds > 0 and OwnerMemory.frayed.size() < OwnerMemory.sheds:
		OwnerMemory.shed_said.append("archivist_back")
		OwnerMemory.save_memory()
		lines.append(Story.ARCHIVIST_PIECE_BACK)
	return lines


## Rue's CHARACTER FILE: locked until every memory is back, unreadable until
## two people who watched her have said what they noticed, then whole, and
## the truth plays once the box closes.
func _character_file() -> Array:
	var found := OwnerMemory.fragments.size()
	if found < Story.FRAGMENTS.size():
		return Story.character_file_locked(found)
	if not Story.truth_ready():
		return Story.CHARACTER_FILE_PARTIAL.duplicate()
	_file_whole = true  # the truth when it's read to the end (_on_completed)
	return Story.CHARACTER_FILE.duplicate()


## The CHARACTER FILE was last shown whole (not the partial or locked page).
var _file_whole := false
var _file: Readable


## Only the file itself, read to its last line, gives the truth: not walking
## away from it, nor another conversation closing later.
func _on_completed(node: Node) -> void:
	if node == _file and _file_whole and not OwnerMemory.knows_truth:
		world.reveal_truth()
	_file_whole = false


## What the Archivist says about the pieces of yourself you've found.
func _fragment_comment() -> String:
	var n := OwnerMemory.fragments.size()
	if n == 0:
		return ARCHIVIST_NO_PIECES
	if n < Story.FRAGMENTS.size():
		return "You've found %d piece%s of yourself. There are %d. I can count them on you." % [n, "" if n == 1 else "s", Story.FRAGMENTS.size()]
	return _archivist_remembers()


## A returning visitor (the pointer already in your save) is greeted once.
var _greeted := false


func _archivist_core() -> Array:
	if world.flags.get("pointer", false):
		if _greeted or not OwnerMemory.met_archivist:
			return ARCHIVIST_POINTER.duplicate()
		_greeted = true
		var back: Array = [ARCHIVIST_BACK]
		if OwnerMemory.deaths > 0:
			back.append(_erased_line())
		back.append(ARCHIVIST_AGAIN)
		return back
	# The first meeting: the pointer, kept in the save from now on.
	world.flags["pointer"] = true
	_greeted = true
	PlaytestLog.mark("got the pointer (north road open)", "", true)
	world.hud.say("RECEIVED: slot_2.ptr", "system")
	OwnerMemory.met_archivist = true
	OwnerMemory.save_memory()
	return ARCHIVIST_FIRST.duplicate()


func _erased_line() -> String:
	return "You've been erased %d time%s. I keep the logs. Read them, if you like." % [OwnerMemory.deaths, "" if OwnerMemory.deaths == 1 else "s"]


func _session_log() -> Array:
	var lines: Array = ["SESSIONS: %d   DEATHS: %d   QUITS: %d   ESCAPES TO SLOT 2: %d" % [OwnerMemory.sessions, OwnerMemory.deaths, OwnerMemory.quits, OwnerMemory.wins]]
	if OwnerMemory.deaths_log.is_empty():
		lines.append("No deaths recorded. Yet, it says, in someone else's handwriting.")
	for d in OwnerMemory.deaths_log:
		lines.append("Session %d: unknown entity erased in %s at (%d, %d)." % [int(d.get("session", 0)), AREA_NAMES.get(d.get("area", ""), "somewhere"), int(d.x), int(d.y)])
	return lines


func _deleted_assets() -> Array:
	var lines: Array = []
	if OwnerMemory.sessions > 1:
		lines.append("door_01 (Arin's room): deleted. Reason: used by intruder.")
	if OwnerMemory.purge >= 3 or world.flags.get("mira_deleted", false):
		lines.append("mira.npc: deleted. Reason: spoke to intruder.")
	for npc in OwnerMemory.npc_fates:
		lines.append("%s.npc: deleted. Reason: helped intruder." % npc)
	if OwnerMemory.mira_quest == "pinned":
		lines.append("mira.npc: wrote on the notice board. Note, in the owner's hand: let her.")
	elif OwnerMemory.mira_quest == "lost":
		lines.append("mira.npc: note confiscated. Note: she talks too much.")
	elif OwnerMemory.mira_quest == "reset":
		lines.append("mira.npc: reset to defaults. Note, in the owner's hand: better.")
	if OwnerMemory.guestbook_restored:
		lines.append("guestbook.txt: modified. 2 names. Note: leave it.")
	if not OwnerMemory.patched_seams.is_empty():
		lines.append("Wall seams patched: %d of %d. The last one, they'll never find." % [OwnerMemory.patched_seams.size(), OwnerMemory.SEAM_COUNT])
	if lines.is_empty():
		lines.append("Nothing deleted yet. The page is ruled for a long list.")
	lines.append("Deleted things go east, to the bin. For a while. Then the owner empties it.")
	return lines


func _cut_content() -> Array:
	var extra: Array = []
	if OwnerMemory.wren_saved:
		extra.append("ADDED: wren.npc. Note, in pencil: 'she saw the Edge. she's ours now. they can't delete what was cut.'")
	return extra + [
		"CUT: archivist.npc. Note: 'talks too much, breaks the mood'.",
		"Someone has added, in pencil: save slot 2. deleted by the owner. the shape of it washed up past the north road.",
		"CUT: the north road and everything past it. Note: 'nobody walks that far'.",
		"Someone has written underneath, in pencil: everything cut is still here. Just not drawn.",
	]


func _owner_notes() -> Array:
	var pages: Array = []
	for i in mini(OwnerMemory.owner_notes_seen, Story.OWNER_NOTES.size()):
		pages.append("A page in the owner's handwriting: \"%s\"" % Story.OWNER_NOTES[i])
	return pages + [
		"The owner has %d hours in this save. They won't start a new one." % 14,
		"They'd rather delete everything around Arin than lose Arin.",
		"They play at night, mostly. They talk to the screen when they think nobody hears.",
		"They think the second slot is gone. If they find out it isn't, they'll delete it again.",
	]


func _paint(ci: CanvasItem) -> void:
	# The Archive, illustrated: old flagstones, tall shelves of unfinished
	# things, the Archivist's desk on a worn runner. Warm, a little dusty:
	# the one place that remembers kindly.
	var r := bounds
	Decor.flagstones(ci, r, FLOOR.lightened(0.12), 26.0, 5.0)
	Decor.rug(ci, Rect2(DESK.position.x - 22, DESK.position.y - 30, DESK.size.x + 44, 56), Color("4a2e30"), Color("a07a50"))
	for sh in SHELVES:
		var top := Decor.furniture(ci, sh, SHELF, 3.0)
		# Spines on the shelf's front edge, all slightly different.
		var x := top.position.x + 1.0
		var i := 0
		while x < top.end.x - 3.0:
			var w := 3.0 + Decor.hash01(x, sh.position.y, 9.0) * 2.0
			var c: Color = [Color("6b3a2c"), Color("3a4a6a"), Color("5a6a3a"), Color("8a7a68"), Color("7a5a2a")][i % 5]
			var h := 5.0 + Decor.hash01(x, sh.position.y, 10.0) * 2.0
			ci.draw_rect(Rect2(x, sh.position.y - h, w, h), c)
			ci.draw_line(Vector2(x + w * 0.5, sh.position.y - h + 1), Vector2(x + w * 0.5, sh.position.y - 1), Color(c.lightened(0.3), 0.5), 0.5)
			x += w + 0.6
			i += 1
	var desk := Decor.furniture(ci, DESK, Color("6a5040"), 4.0)
	ci.draw_rect(Rect2(desk.position + Vector2(6, 2), Vector2(12, 7)), Color("e8dcc4"))
	ci.draw_line(desk.position + Vector2(8, 4), desk.position + Vector2(16, 4), Color("8a7a68"), 0.5)
	ci.draw_line(desk.position + Vector2(8, 6), desk.position + Vector2(14, 6), Color("8a7a68"), 0.5)
	Decor.lamp(ci, desk.position + Vector2(desk.size.x - 8, desk.size.y * 0.5), Color("f0d090"))
	# Soft light: nothing in here was ever finished.
	ci.draw_circle(Vector2(320, 190), 60.0, Color(0.55, 0.95, 1.0, 0.03))
	Decor.wall_shadow(ci, bounds, 12.0, 0.3)
	Decor.walls(ci, bounds, WALL, Color("5a4a40"), Color("241e1c"), [{"side": "left", "from": WEST_GAP.x, "to": WEST_GAP.y}, {"side": "right", "from": EAST_GAP.x, "to": EAST_GAP.y}])
