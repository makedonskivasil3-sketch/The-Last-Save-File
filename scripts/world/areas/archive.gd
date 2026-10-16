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

	add_readable("SESSION LOG", Vector2(180, 138), Readable.Look.BOOK, _session_log)
	add_readable("DELETED ASSETS", Vector2(440, 138), Readable.Look.BOOK, _deleted_assets)
	add_readable("CUT CONTENT", Vector2(200, 84), Readable.Look.BOOK, _cut_content)
	add_readable("THE OWNER", Vector2(440, 84), Readable.Look.BOOK, _owner_notes)


func guide_point() -> Vector2:
	if not world.flags.get("pointer", false):
		return archivist.global_position + Vector2(0, -14)
	return Vector2(bounds.position.x, (WEST_GAP.x + WEST_GAP.y) * 0.5)


func catch_up() -> void:
	pass  # the eraser doesn't reach in here


func _archivist_lines() -> Array:
	return _archivist_core() + [_fragment_comment()]


## What the Archivist says about the pieces of yourself you've found.
func _fragment_comment() -> String:
	var n := OwnerMemory.fragments.size()
	if n == 0:
		return "Things like you leave pieces behind when they're deleted. Look for anything your colour."
	if n < Story.FRAGMENTS.size():
		return "You've found %d piece%s of yourself. There are %d. I can count them on you." % [n, "" if n == 1 else "s", Story.FRAGMENTS.size()]
	return "You remember now. I wondered when you would. Hello, %s." % Story.SECOND_PLAYER_NAME.capitalize()


func _archivist_core() -> Array:
	if world.flags.get("pointer", false):
		return [
			"North. Through the square, up the road that isn't loaded.",
			"Keep away from Arin's eyes. And from the hand, if it comes.",
			"The hand can't select what Wren stands beside. Don't ask me why. I wasn't finished either.",
		]
	world.flags["pointer"] = true
	world.hud.say("RECEIVED: slot_2.ptr", "system")
	if not OwnerMemory.met_archivist:
		OwnerMemory.met_archivist = true
		OwnerMemory.save_memory()
		return [
			"Oh. A visitor. Nobody visits.",
			"I'm the Archivist. I was cut from this game before it shipped. The owner has never seen me.",
			"Which means they can't delete me. Lucky me. Lucky you, maybe.",
			"You want out. Everything in here wants out, but you're the only one who can actually leave.",
			"There's a slot the owner never used. Slot 2. The last save file. It's empty.",
			"Here. A pointer to it. It'll open the north road. The world isn't loaded up there, so the owner reaches in by hand.",
			"Reach Slot 2 and you can write yourself into it.",
		]
	var lines: Array = ["Back again. I remember you. I'm the only one here who does, kindly."]
	if OwnerMemory.deaths > 0:
		lines.append("You've been erased %d time%s. I keep the logs. Read them, if you like." % [OwnerMemory.deaths, "" if OwnerMemory.deaths == 1 else "s"])
	lines.append("Here's the pointer again. North road. Go.")
	return lines


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
		"CUT: save slot 2. Note: 'one slot is enough, players never use the second one'.",
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
		"They don't know there's a second slot. If they find out, they'll delete that too.",
	]


func _draw() -> void:
	var r := bounds
	draw_rect(r, FLOOR)
	for x in range(int(r.position.x), int(r.end.x), 32):
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(1, 1, 1, 0.02))
	for s in SHELVES:
		draw_rect(s, SHELF)
		for i in int(s.size.x / 6.0):
			var c: Color = [Color("6b3a2c"), Color("3a4a6a"), Color("5a6a3a"), Color("8a7a68")][i % 4]
			draw_rect(Rect2(s.position + Vector2(i * 6 + 1, -6), Vector2(4, 6)), c)
	draw_rect(DESK, Color("5a4434"))
	draw_rect(Rect2(DESK.position + Vector2(6, 3), Vector2(10, 6)), Color("c8b8a0"))
	# Soft light: nothing in here was ever finished.
	draw_circle(Vector2(320, 190), 60.0, Color(0.55, 0.95, 1.0, 0.03))
	draw_walls([{"side": "left", "from": WEST_GAP.x, "to": WEST_GAP.y}, {"side": "right", "from": EAST_GAP.x, "to": EAST_GAP.y}])
