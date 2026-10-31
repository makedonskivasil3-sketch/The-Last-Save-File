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
## Where the four records stand, each in its alcove.
const RECORD_SPOTS: Array[Vector2] = [Vector2(180, 138), Vector2(440, 138), Vector2(200, 84), Vector2(440, 84)]
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
	entries = {"west": Vector2(118, 180), "east": Vector2(522, 180), "workshop": Vector2(450, 266)}


func build() -> void:
	setup_common()
	set_backdrop(_paint)
	# Quiet and safe: one lamp on the Archivist's desk, the shelves fading
	# into the dark around it.
	light_surfaces(0.54, 1.6)
	add_light(DESK.get_center() + Vector2(0, -10), Color(1.0, 0.78, 0.5), 1.6, 170.0, true)
	# Moonlight from the high window onto the aisle (the room's shape, and
	# the way through it, from the doorway).
	add_light(Vector2(320, 150), Color(0.6, 0.75, 1.0), 0.5, 150.0)
	add_dust(Rect2(DESK.position.x - 70, DESK.position.y - 120, DESK.size.x + 140, 130), Color(1.0, 0.85, 0.6, 0.45), 20, Vector2(2, -2))
	add_boundary([{"side": "left", "from": WEST_GAP.x, "to": WEST_GAP.y}, {"side": "right", "from": EAST_GAP.x, "to": EAST_GAP.y},
		{"side": "bottom", "from": 430.0, "to": 470.0}])
	for s in SHELVES:
		add_solid(s)
	add_solid(DESK)
	add_exit(Rect2(bounds.position.x - 8, WEST_GAP.x, 8, WEST_GAP.y - WEST_GAP.x), "square", "east")

	add_sign(Vector2(bounds.position.x + 32, WEST_GAP.x - 10), "ASHVALE", Vector2.LEFT)
	add_exit(Rect2(bounds.end.x, EAST_GAP.x, 8, EAST_GAP.y - EAST_GAP.x), "bin", "west")
	add_sign(Vector2(bounds.end.x - 40, EAST_GAP.x - 10), "RECYCLE BIN", Vector2.RIGHT)
	add_exit(Rect2(430, bounds.end.y, 40, 8), "workshop", "stairs")
	add_sign(Vector2(450, 252), "LANTERN WORKSHOP", Vector2.DOWN)
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
	for rec in [["SESSION LOG", RECORD_SPOTS[0], _session_log], ["DELETED ASSETS", RECORD_SPOTS[1], _deleted_assets],
			["CUT CONTENT", RECORD_SPOTS[2], _cut_content], ["THE OWNER", RECORD_SPOTS[3], _owner_notes]]:
		var book := add_readable(rec[0], rec[1], Readable.Look.RECORD, rec[2])
		add_light(rec[1] + Vector2(0, -6), Color(1.0, 0.85, 0.6), 0.75, 44.0)  # each record has its reading lamp
		var title: String = rec[0]
		book.was_read = func() -> bool: return OwnerMemory.journal.any(func(e: Dictionary) -> bool: return e.get("title", "") == title)
	# Filed long ago, at the Archivist's desk: what Rue is (docs/DARK_TRUTH_DESIGN.md).
	# It pulses only once the story points at it (Progression FILE), and says
	# nothing about what's inside.
	_file = add_readable(Story.CHARACTER_FILE_TITLE, Vector2(DESK.end.x + 10, DESK.get_center().y), Readable.Look.TERMINAL, _character_file)
	_file.emphasis = func() -> bool: return Progression.stage() == Progression.Stage.FILE
	# After she has read it: he started a new one, on the desk's left end,
	# filed under people (docs/production/CHARACTERS.md). What he does
	# says what he thinks; he doesn't make a speech of it.
	if OwnerMemory.knows_truth:
		var started := add_readable(NEW_FILE_TITLE, Vector2(DESK.position.x + 26, DESK.position.y + 6), Readable.Look.NONE,
			func() -> Array: return NEW_FILE_LINES.duplicate())
		started.prompt = "look"
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
## The first exchange: who he is, the way out, and what it's for. The rest
## he tells a piece at a time if she talks to him again (ARCHIVIST_TOPICS).
const ARCHIVIST_FIRST := [
	"Oh. A visitor. Nobody visits.",
	"I'm the Archivist. I was cut from this game before it shipped. The owner has never seen me.",
	"You want out. Here: a pointer to Slot 2, the slot the owner thinks is gone. It opens the north road.",
	"Reach Slot 2 and you can write yourself into it. A save of your own. Nothing here could delete you then.",
]
## What used to be the rest of his first speech, one piece per later talk,
## each kept until heard to the end. (The records say the same things in
## their own words: he isn't the only way to learn them.)
const ARCHIVIST_TOPICS := [
	"Slot 2? They deleted it. What was left washed up past the Edge, with the rest of the cut things. It's empty.",
	"The north road isn't loaded. Up there the owner reaches in by hand. Keep away from the hand.",
	"Why you? Everything in here wants out. You're the only one I've filed who can actually leave.",
	"And they can't delete me: they'd have to see me first. Lucky me. Lucky you, maybe.",
]
## The introduction again, for someone given the pointer who walked off
## before he'd finished (or whose save predates "archivist.introduced").
const ARCHIVIST_RESUMED_OPEN := "You came back. I hadn't finished."
const ARCHIVIST_RESUMED_POINTER := "The pointer I gave you opens the north road. The world isn't loaded up there, so the owner reaches in by hand."
const ARCHIVIST_BACK := "Back again. I remember you. Properly, I mean. The others only half do."
const ARCHIVIST_AGAIN := "You kept the pointer. Good. North road, when you're ready."
## Canon proposal A/E (CANON_PROPOSAL_2026-10-28.md, adopted 2026-10-29):
## colour is choice. Said once, the first time he sees her partly coloured.
const ARCHIVIST_COLOURS := "Colours are what someone chose for you. You're getting yours back one at a time. Interesting that they're hers."
const NEW_FILE_TITLE := "A NEW FILE"
const NEW_FILE_LINES := [
	"Started since you read the other one, in his small, careful hand.",
	"NAME: RUE.   FILED UNDER: PEOPLE.   (Not under CHARACTERS. That drawer is the other side of the room.)",
	"The rest of the page is blank. He has left it for you.",
]
const ARCHIVIST_NO_PIECES := "Things like you leave pieces behind when they're deleted. Look for anything your colour."


static func _archivist_remembers() -> String:
	return "You remember now. I wondered when you would. Hello, %s." % Story.SECOND_PLAYER_NAME.capitalize()


## Every line the Archivist can say that is the same in every run, by voice
## id stem (VoiceManifest). Lines with run counts in them stay text only.
static func voice_lines() -> Dictionary:
	return {"npc.archivist": ARCHIVIST_POINTER + ARCHIVIST_FIRST + ARCHIVIST_TOPICS + [ARCHIVIST_RESUMED_OPEN, ARCHIVIST_RESUMED_POINTER, ARCHIVIST_BACK, ARCHIVIST_AGAIN, ARCHIVIST_NO_PIECES, ARCHIVIST_COLOURS, _archivist_remembers(),
		Story.ARCHIVIST_FILE_HINT, Story.ARCHIVIST_KNOWS, Story.ARCHIVIST_PIECE_BACK, Story.ARCHIVIST_NOTHING_TO_TAKE] + Story.ARCHIVIST_SHED_FIRST}


## What he says, and what counts once it has been read to the end. Choosing
## the lines changes nothing that is told: his introduction and his
## one-time remarks are kept for the next talk until they're heard whole
## (World._on_dialogue_closed runs "after"). The pointer is the exception,
## on purpose: a gameplay grant, given (and shown) the moment he hands it
## over, so walking away can never strand Rue without the north road.
func _archivist_lines() -> Dictionary:
	var after: Array = []
	var commit: Array = []
	_topic_after = -1
	var lines: Array = _archivist_core(commit)
	if _topic_after >= 0:
		# A topic is its own short exchange.
		return {"lines": lines, "id": "", "commit": [], "after": [_heard_topic.bind(_topic_after)]}
	lines.append(_fragment_comment())
	var n := OwnerMemory.fragments.size()
	if n > 0 and n < Story.FRAGMENTS.size() and "archivist.colours" not in OwnerMemory.shed_said:
		after.append(_said.bind("archivist.colours"))
		lines.append(ARCHIVIST_COLOURS)
	if OwnerMemory.fragments.size() >= Story.FRAGMENTS.size():
		lines.append(Story.ARCHIVIST_KNOWS if OwnerMemory.knows_truth else Story.ARCHIVIST_FILE_HINT)
	# What he thinks of her leaving bodies behind (each said once, heard).
	if OwnerMemory.sheds > 0 and "archivist" not in OwnerMemory.shed_said:
		after.append(_said.bind("archivist"))
		lines.append_array(Story.ARCHIVIST_SHED_FIRST)
	elif "archivist_back" not in OwnerMemory.shed_said and OwnerMemory.sheds > 0 and OwnerMemory.frayed.size() < OwnerMemory.sheds:
		after.append(_said.bind("archivist_back"))
		lines.append(Story.ARCHIVIST_PIECE_BACK)
	return {"lines": lines, "id": "", "commit": commit, "after": after}


var _topic_after := -1


## The topics he hasn't finished telling her (by index).
func topics_left() -> Array:
	return range(ARCHIVIST_TOPICS.size()).filter(func(i: int) -> bool: return "archivist.topic:%d" % i not in OwnerMemory.shed_said)


func _next_topic() -> int:
	var left := topics_left()
	return left[0] if not left.is_empty() else -1


static func _heard_topic(i: int) -> void:
	_said("archivist.topic:%d" % i)


static func _said(key: String) -> void:
	if key not in OwnerMemory.shed_said:
		OwnerMemory.shed_said.append(key)
		OwnerMemory.save_memory()


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


func _archivist_core(commit: Array) -> Array:
	if world.flags.get("pointer", false):
		if Relationships.has("archivist.intro_pending") and not Relationships.has("archivist.introduced"):
			# Given the pointer, but he never got to say who he is: he does.
			# (Saves from before "introduced" existed have no pending mark:
			# they heard it then, and are greeted as returning visitors.)
			commit.append("archivist.introduced")
			return [ARCHIVIST_RESUMED_OPEN, ARCHIVIST_FIRST[1], ARCHIVIST_RESUMED_POINTER, ARCHIVIST_FIRST[3]]
		if _greeted or not OwnerMemory.met_archivist:
			var topic := _next_topic()
			if topic >= 0:
				_topic_after = topic
				return [ARCHIVIST_TOPICS[topic]]
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
	Relationships.add("archivist.intro_pending")  # (not shown in the journal)
	Relationships.add("archivist.pointer")  # saves
	commit.append("archivist.introduced")  # once it's heard
	return ARCHIVIST_FIRST.duplicate()


func _erased_line() -> String:
	return "You've been erased %d time%s. I keep the logs. Read them, if you like." % [OwnerMemory.deaths, "" if OwnerMemory.deaths == 1 else "s"]


func _session_log() -> Array:
	var lines: Array = ["SESSIONS: %d   DEATHS: %d   QUITS: %d   ESCAPES TO SLOT 2: %d" % [OwnerMemory.sessions, OwnerMemory.deaths, OwnerMemory.quits, OwnerMemory.wins]]
	lines.append_array(Story.festival_log(OwnerMemory.festival_choice))
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
	# The Archive, illustrated: old flagstones, tall cases of unfinished
	# things along the north wall, the records open on lit stands in front
	# of them, an aisle runner from the square's door to the Bin's, and the
	# Archivist's desk under its lamp. Warm, a little dusty: the one place
	# that remembers kindly.
	var r := bounds
	Decor.flagstones(ci, r, FLOOR.lightened(0.12), 26.0, 5.0)
	# The same stair stones continue in the workshop below.
	for y in range(270, 296, 5):
		ci.draw_line(Vector2(432, y), Vector2(468, y), Color("b3a18c"), 1)
	# The aisle: west door to east door, the way through.
	var aisle := Rect2(r.position.x, WEST_GAP.x + 4, r.size.x, WEST_GAP.y - WEST_GAP.x - 8)
	ci.draw_rect(aisle, Color("2e2628"))
	ci.draw_rect(aisle.grow_individual(0, -3, 0, -3), Color("3a2c2e"))
	for y in [aisle.position.y + 2, aisle.end.y - 2]:
		ci.draw_line(Vector2(aisle.position.x, y), Vector2(aisle.end.x, y), Color("a07a50"), 1.0)
	# The high window on the north wall, and its light down to the aisle.
	var win := Rect2(300, r.position.y + 2, 40, 22)
	ci.draw_rect(win, Color("1e2a3a"))
	ci.draw_arc(Vector2(win.get_center().x, win.position.y + 6), 20.0, PI, TAU, 16, Color("5a4a40"), 3.0)
	ci.draw_line(Vector2(win.get_center().x, win.position.y), Vector2(win.get_center().x, win.end.y), Color("5a4a40"), 1.5)
	ci.draw_colored_polygon(PackedVector2Array([win.position + Vector2(4, win.size.y), Vector2(win.end.x - 4, win.end.y),
		Vector2(win.end.x + 30, aisle.position.y + 10), Vector2(win.position.x - 30, aisle.position.y + 10)]), Color(0.6, 0.75, 1.0, 0.05))
	Decor.rug(ci, Rect2(DESK.position.x - 22, DESK.position.y - 30, DESK.size.x + 44, 56), Color("4a2e30"), Color("a07a50"))
	# The arrival: a worn mat inside the square's door, and the returns cart
	# beside it (nobody has returned anything in years; it's full anyway).
	var mat := Rect2(r.position.x + 4, WEST_GAP.x + 10, 26, WEST_GAP.y - WEST_GAP.x - 20)
	ci.draw_rect(mat, Color("4a3a30"))
	ci.draw_rect(mat.grow(-2.0), Color("5a4636"))
	ci.draw_rect(mat, Decor.INK, false, 0.6)
	var cart := Rect2(r.position.x + 8, WEST_GAP.y + 6, 22, 9)
	ci.draw_rect(Rect2(cart.position + Vector2(1, 2), cart.size), Color(0, 0, 0, 0.3))
	ci.draw_rect(cart, Color("5a4030"))
	for k in 5:
		ci.draw_rect(Rect2(cart.position.x + 2 + k * 4, cart.position.y - 5, 3, 6), [Color("6b3a2c"), Color("3a4a6a"), Color("5a6a3a"), Color("8a7a68"), Color("7a5a2a")][k])
	ci.draw_rect(cart, Decor.INK, false, 0.6)
	for wx: float in [cart.position.x + 3, cart.end.x - 3]:
		ci.draw_circle(Vector2(wx, cart.end.y + 1), 1.4, Decor.INK)
	ci.draw_string(ThemeDB.fallback_font, cart.position + Vector2(0, -7), "RETURNS", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("c8b890"))
	for sh in SHELVES:
		# Tall cases behind the shelf (their height is drawn, their foot is
		# the solid shelf), so the room has its silhouette from the door.
		var case := Rect2(sh.position.x, sh.position.y - 22, sh.size.x, 22)
		ci.draw_rect(Rect2(case.position + Vector2(2, -2), case.size), Color(0, 0, 0, 0.25))
		ci.draw_rect(case, SHELF.darkened(0.25))
		for row in 2:
			var ry := case.position.y + 3 + row * 9
			var bx := case.position.x + 2.0
			var j := 0
			while bx < case.end.x - 3.0:
				var bw := 2.5 + Decor.hash01(bx, ry, 3.0) * 2.0
				var bc: Color = [Color("6b3a2c"), Color("3a4a6a"), Color("5a6a3a"), Color("8a7a68"), Color("7a5a2a")][(j + row) % 5]
				ci.draw_rect(Rect2(bx, ry, bw, 7), bc.darkened(0.2))
				bx += bw + 0.5
				j += 1
		ci.draw_rect(case, Decor.INK, false, 0.8)
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
	# Each record has its own alcove cut into the cases behind it, with a
	# brass plate: four places to read, not a lecture.
	for at: Vector2 in RECORD_SPOTS:
		var arch := Rect2(at.x - 11, at.y - 30, 22, 22)
		ci.draw_rect(arch, Color("1a1418"))
		ci.draw_arc(Vector2(arch.get_center().x, arch.position.y + 6), 11.0, PI, TAU, 12, Color("1a1418"), 6.0)
		ci.draw_arc(Vector2(arch.get_center().x, arch.position.y + 6), 11.0, PI, TAU, 12, Color("a07a50"), 1.0)
		ci.draw_line(arch.position + Vector2(0, 6), Vector2(arch.position.x, arch.end.y), Color("a07a50"), 1.0)
		ci.draw_line(Vector2(arch.end.x, arch.position.y + 6), arch.end, Color("a07a50"), 1.0)
		ci.draw_rect(Rect2(at.x - 4, arch.end.y - 4, 8, 2), Color("c8a040"))
	var desk := Decor.furniture(ci, DESK, Color("6a5040"), 4.0)
	ci.draw_rect(Rect2(desk.position + Vector2(6, 2), Vector2(12, 7)), Color("e8dcc4"))
	ci.draw_line(desk.position + Vector2(8, 4), desk.position + Vector2(16, 4), Color("8a7a68"), 0.5)
	ci.draw_line(desk.position + Vector2(8, 6), desk.position + Vector2(14, 6), Color("8a7a68"), 0.5)
	Decor.lamp(ci, desk.position + Vector2(desk.size.x - 8, desk.size.y * 0.5), Color("f0d090"))
	if OwnerMemory.knows_truth:
		# The new file: a manila folder, its tab lettered, a clip, a fresh page.
		var f := Rect2(DESK.position.x + 20, DESK.position.y + 2, 12, 8)
		ci.draw_rect(Rect2(f.position + Vector2(1, 1), f.size), Color(0, 0, 0, 0.3))
		ci.draw_rect(f, Color("d8b878"))
		ci.draw_rect(Rect2(f.position + Vector2(1, -2), Vector2(5, 2.5)), Color("d8b878"))  # the tab
		ci.draw_line(f.position + Vector2(1.6, -1), f.position + Vector2(4.6, -1), Color("4a3020"), 0.5)  # RUE, on the tab
		ci.draw_rect(Rect2(f.position + Vector2(2, 1.5), Vector2(8, 5.5)), Color("f4ecd8"))
		ci.draw_line(f.position + Vector2(3, 3), f.position + Vector2(8, 3), Color("6a5a48"), 0.4)
		ci.draw_rect(Rect2(f.position + Vector2(9, 0.5), Vector2(1.2, 2.5)), Color("a0a0a8"))  # the clip
	# Once he has given Rue the pointer, a map of the north road stays
	# pinned to the desk's front: what happened here shows next time.
	if Relationships.has("archivist.pointer"):
		var m := Rect2(DESK.position.x + 18, DESK.end.y - 2, 16, 11)
		ci.draw_rect(m, Color("e8dcc4"))
		ci.draw_rect(m, Decor.INK, false, 0.6)
		ci.draw_line(m.position + Vector2(8, 9), m.position + Vector2(8, 2), Color("6b3a2c"), 0.8)
		ci.draw_line(m.position + Vector2(8, 2), m.position + Vector2(6, 4), Color("6b3a2c"), 0.8)
		ci.draw_line(m.position + Vector2(8, 2), m.position + Vector2(10, 4), Color("6b3a2c"), 0.8)
	# The Bin's door: a bin over the east doorway, so it isn't just a gap.
	var bin_at := Vector2(r.end.x - 6, EAST_GAP.x - 18)
	ci.draw_rect(Rect2(bin_at + Vector2(-5, 0), Vector2(10, 11)), Color("3a3f4a"))
	ci.draw_rect(Rect2(bin_at + Vector2(-6, -2), Vector2(12, 2)), Color("5a606a"))
	for k in 3:
		ci.draw_line(bin_at + Vector2(-3 + k * 3, 2), bin_at + Vector2(-3 + k * 3, 9), Color("8cf2ff", 0.5), 0.6)
	# Soft light: nothing in here was ever finished.
	ci.draw_circle(Vector2(320, 190), 60.0, Color(0.55, 0.95, 1.0, 0.03))
	Decor.wall_shadow(ci, bounds, 12.0, 0.3)
	Decor.walls(ci, bounds, WALL, Color("5a4a40"), Color("241e1c"), [{"side": "left", "from": WEST_GAP.x, "to": WEST_GAP.y}, {"side": "right", "from": EAST_GAP.x, "to": EAST_GAP.y}, {"side": "bottom", "from": 430.0, "to": 470.0}])


## Arrival (Area.on_arrival): the Archivist doesn't look up. He is filing.
func arrival_people() -> Array:
	return [[archivist, "archivist", "..."]]
