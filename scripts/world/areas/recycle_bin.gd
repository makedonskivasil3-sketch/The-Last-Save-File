class_name RecycleBin
extends Area
## Where deleted things go, for a while. East of the Archive. The owner can
## see in here, and every so often empties the bin: a white line sweeps
## across the room and deletes everything it touches, except what sits in
## the shadow of a protected system file. Between sweeps you can restore
## the characters the owner deleted (stand beside their file), and read
## what the owner threw away years ago.

## The system files the bin can't delete; each casts a protected shadow
## (east of it, away from the sweep) where you're safe.
const SYSTEM_FILES: Array[Rect2] = [
	Rect2(170, 70, 24, 30), Rect2(300, 200, 24, 30), Rect2(420, 90, 24, 30), Rect2(220, 230, 24, 30),
]
const SHADOW := Vector2(34, 0)    # how far the safe shadow reaches past a file
const WEST_GAP := Vector2(160, 200)
## Seconds between sweeps (faster with every purge), the warning before one,
## and how long the line takes to cross.
const EMPTY_EVERY := 16.0
const WARNING := 3.0
const SWEEP_TIME := 2.6
## Where deleted characters' files lie.
## Up to four deleted characters and three taken pieces at once.
const FILE_SPOTS: Array[Vector2] = [Vector2(260, 120), Vector2(380, 160), Vector2(480, 240), Vector2(150, 160),
	Vector2(340, 110), Vector2(200, 200), Vector2(450, 200)]

const FLOOR := Color("16161c")

var files: Array[BinFile] = []
## Seconds until the next sweep starts (the warning runs in the last WARNING).
var next_empty := 9.0
## -1 when no sweep runs; otherwise the line's x.
var sweep_x := -1.0

var _warned := -1
var _t := 0.0


func _init() -> void:
	area_id = "bin"
	display_name = "RECYCLE BIN"
	bounds = Rect2(96, 36, 448, 256)
	awareness_rate = 1.2
	tint = Color(0.85, 0.9, 1.0)
	entries = {"west": Vector2(118, 180)}


func build() -> void:
	setup_common()
	add_boundary([{"side": "left", "from": WEST_GAP.x, "to": WEST_GAP.y}])
	for r in SYSTEM_FILES:
		add_solid(r)
		add_light(r.get_center() + Vector2(SHADOW.x * 0.6, 0), Color(0.55, 0.95, 1.0), 0.45, 55.0)
	add_dust(bounds.grow(-12), Color(0.55, 0.95, 1.0, 0.4), 26, Vector2(0, -5))  # loose bits, floating up
	add_exit(Rect2(bounds.position.x - 8, WEST_GAP.x, 8, WEST_GAP.y - WEST_GAP.x), "archive", "east")
	add_sign(Vector2(bounds.position.x + 32, WEST_GAP.x - 10), "ARCHIVE", Vector2.LEFT)

	var i := 0
	for id in deleted_characters():
		if i >= FILE_SPOTS.size():
			break
		var f := BinFile.new()
		f.npc_id = id
		f.tint = {"wren": Color("a8d890"), "mira": Color("e0a070"), "tobben": Color("b090c0")}.get(id, Color("8a8f98"))
		f.player = world.player
		f.position = FILE_SPOTS[i]
		f.restored.connect(_on_restored)
		add_child(f)
		files.append(f)
		interactables.append(f)
		i += 1

	# The pieces Rue took, where deleted things go (after the characters).
	for who in OwnerMemory.frayed:
		if i >= FILE_SPOTS.size():
			break
		var piece := BinFile.new()
		piece.npc_id = who
		piece.asset = Story.SHED_ASSET[who]
		piece.tint = Color("c8b8a0")
		piece.player = world.player
		piece.position = FILE_SPOTS[i]
		piece.restored.connect(_on_piece_returned)
		add_child(piece)
		files.append(piece)
		interactables.append(piece)
		i += 1

	add_readable("slot2_backup.sav", Vector2(470, 60), Readable.Look.TERMINAL, _backup)
	add_readable("guestbook_p2.txt", Vector2(140, 264), Readable.Look.TERMINAL, _guestbook)
	add_readable("rue_last_message.txt", Vector2(500, 150), Readable.Look.TERMINAL, _last_message)
	if OwnerMemory.mira_quest == "lost":
		add_readable("mira_note.txt", Vector2(320, 64), Readable.Look.TERMINAL, func() -> Array: return Story.MIRA_NOTE_LOST)
	add_readable("owner_draft.txt", Vector2(380, 272), Readable.Look.TERMINAL, _owner_draft)
	next_empty = maxf(6.0, 9.0 - OwnerMemory.purge * 0.5)


## Everyone the owner has deleted (and you haven't brought back).
func deleted_characters() -> Array[String]:
	var out: Array[String] = []
	for id in OwnerMemory.npc_fates:
		if OwnerMemory.is_deleted(id):
			out.append(id)
	if world.is_mira_deleted():
		if "mira" not in out:
			out.append("mira")
	return out


func guide_point() -> Vector2:
	for f in files:
		if not f.done:
			return f.global_position
	return Vector2.INF


func catch_up() -> void:
	pass  # no eraser in here: the bin has its own way of deleting things


func set_owner_paused(on: bool) -> void:
	super.set_owner_paused(on)
	_paused = on


var _paused := false


func area_process(delta: float) -> void:
	_t += delta
	if _paused:
		return
	if sweep_x >= 0.0:
		var before := sweep_x
		sweep_x += bounds.size.x / SWEEP_TIME * delta
		_check_sweep(before, sweep_x)
		if sweep_x > bounds.end.x:
			sweep_x = -1.0
			next_empty = maxf(8.0, EMPTY_EVERY - OwnerMemory.purge * 1.0)
			world.hud.say("RECYCLE BIN EMPTIED", "system")
		queue_redraw()
		return
	next_empty -= delta
	var count := ceili(next_empty)
	if next_empty <= WARNING and count != _warned and count > 0:
		_warned = count
		world.hud.set_banner("EMPTYING RECYCLE BIN IN %d" % count)
		Sfx.play("key_system", -2.0, 0.8 + 0.1 * (3 - count))
		if count == ceili(WARNING):
			world.director.say(["emptying the trash.", "taking out the trash.", "empty recycle bin? yes."].pick_random())
	if next_empty <= 0.0:
		start_sweep()
	queue_redraw()


func start_sweep() -> void:
	sweep_x = bounds.position.x
	_warned = -1
	if world.hud.banner_text().begins_with("EMPTYING"):
		world.hud.set_banner("")
	Sfx.play("erase_start", 0.0, 1.3)
	world.fx.spike(0.4 * Settings.flash_scale(), 0.5)


## The protected shadow of one system file: the one definition the sweep,
## the drawing and any debug view all use, so a glow never promises safety
## the sweep doesn't give.
static func shelter_rect(file: Rect2) -> Rect2:
	return Rect2(file.position, file.size + SHADOW).grow_individual(0, 6, 0, 6)


## Is this spot in a protected file's shadow?
static func sheltered_at(p: Vector2) -> bool:
	for r in SYSTEM_FILES:
		if shelter_rect(r).has_point(p):
			return true
	return false


func _check_sweep(from_x: float, to_x: float) -> void:
	# A half-restored file goes back to the start: restores fit between sweeps.
	for f in files:
		if f.is_restoring() and f.global_position.x >= from_x and f.global_position.x < to_x and f.progress > 0.0:
			f.progress = 0.0
			world.hud.say("%s  ·  restore lost" % f.file_name(), "system")
	var p := world.player.global_position
	if p.x >= from_x and p.x < to_x and not sheltered_at(p):
		world.kill("erased", "bin")


func _on_restored(id: String) -> void:
	world.note_restored(id)
	world.director.notice(10.0, "a file came back")
	world.director.say({"wren": "wren? i deleted you.", "mira": "mira. who put you back."}.get(id, "who restored that."))
	world.voice("bin_restored")


## A piece given back: they're whole again, and the owner notices that too.
func _on_piece_returned(id: String) -> void:
	OwnerMemory.return_piece(id)
	world.player.refresh_look()
	if world.escort and world.escort.npc_id == id:
		world.escort.refresh_fray()  # walked in with you: whole again here too
	world.hud.say("%s  ·  returned" % Story.SHED_ASSET[id], "system")
	world.director.notice(6.0, "something went back")


func _backup() -> Array:
	return [
		"slot2_backup.sav · 1.2 KB · deleted 3 years ago",
		"PLAYER 2: RUE · LV 31 · 41:07:12 · LAST PLAYED: the night before the move",
		"the file is mostly empty. the owner kept the name and deleted everything else.",
	]


func _guestbook() -> Array:
	if not OwnerMemory.found_guestbook:
		OwnerMemory.found_guestbook = true
		OwnerMemory.save_memory()
	return [
		"guestbook_p2.txt · torn out of Tobben's guest book",
		"\"ARIN & RUE were here!! we beat the forest boss. on the first try. (the second try.)\"",
		"two names, two handwritings. one of them has been scribbled over so many times it tore the page.",
	]


## The owner's side, in the bin: a reply that was deleted instead of sent.
func _owner_draft() -> Array:
	var lines: Array = [
		"owner_draft.txt · never sent · deleted the same night as slot2.sav",
		"\"hey. i know it's been ages. yes i still have your sa\"",
		"the draft stops mid-word. the cursor blinked there for a long time, then the file went in the bin.",
	]
	if OwnerMemory.owner_notes_seen >= Story.OWNER_NOTES.size() - 2:
		lines.append("you know the rest now. they couldn't send it. it wasn't true anymore.")
	return lines


func _last_message() -> Array:
	var lines: Array = ["rue_last_message.txt · deleted 3 years ago"]
	if OwnerMemory.fragments.size() >= Story.FRAGMENTS.size():
		lines.append("\"i'm not gone, i'm just moving. keep my slot. we'll finish it when i visit. promise?\"")
		lines.append("you remember her writing it." if OwnerMemory.knows_truth else "you remember writing it.")
	else:
		lines.append("\"i'm not gone, i'm just ███████. keep my ████. we'll finish it when ███████. promise?\"")
		lines.append("most of it won't open. maybe if you remembered more of yourself.")
	return lines


func _draw() -> void:
	var r := bounds
	draw_rect(r, FLOOR)
	# A grid like an empty folder view.
	for x in range(int(r.position.x), int(r.end.x), 24):
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(1, 1, 1, 0.025))
	for y in range(int(r.position.y), int(r.end.y), 24):
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(1, 1, 1, 0.025))
	var warn := next_empty <= WARNING or sweep_x >= 0.0
	for f in SYSTEM_FILES:
		# The protected shadow: brighter when the bin is about to empty
		# (steady with Reduce flashing), with a solid edge that is exactly
		# where the sweep stops counting you.
		var shade := shelter_rect(f)
		var pulse := 0.0 if Settings.reduce_flashing else 0.06 * sin(_t * 8.0)
		var a := 0.06 + (0.12 + pulse if warn else 0.0)
		draw_rect(shade, Color(0.55, 0.95, 1.0, a))
		draw_rect(shade, Color(0.55, 0.95, 1.0, 0.35 + (0.3 if warn else 0.0)), false, 1.0)
		draw_rect(f, Color("3a3f4a"))
		draw_rect(f, Color("8cf2ff", 0.5), false, 1.0)
		# A little padlock.
		var c := f.get_center()
		draw_rect(Rect2(c + Vector2(-4, -1), Vector2(8, 7)), Color("8cf2ff", 0.7))
		draw_arc(c + Vector2(0, -1), 3.0, PI, TAU, 8, Color("8cf2ff", 0.7), 1.0)
		draw_string(UiStyle.system_font(), Vector2(f.position.x - 8, f.end.y + 9), "system", HORIZONTAL_ALIGNMENT_CENTER, 40, 6, Color("8cf2ff", 0.6))
	draw_walls([{"side": "left", "from": WEST_GAP.x, "to": WEST_GAP.y}])
	if sweep_x >= 0.0:
		var flash := Settings.flash_scale()
		draw_rect(Rect2(r.position.x, r.position.y, sweep_x - r.position.x, r.size.y), Color(1, 1, 1, 0.04 * flash))
		draw_rect(Rect2(sweep_x - 2, r.position.y, 4, r.size.y), Color(1, 1, 1, 0.5 + 0.4 * flash))
		draw_rect(Rect2(sweep_x - 10, r.position.y, 8, r.size.y), Color(0.55, 0.95, 1.0, 0.15))
