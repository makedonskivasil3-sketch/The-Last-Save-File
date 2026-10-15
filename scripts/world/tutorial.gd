class_name Tutorial
extends Node
## First-session tips: how to move, that the owner is watching, how to hide,
## and that quitting counts. Shown one at a time in the HUD's tip card.
##
## The room tips play in order as soon as you wake; the contextual ones
## (interacting, the locked door, being hidden, Arin, the Archive, Slot 2)
## jump in the first time their moment comes. Each tip is shown once ever (Settings.tips_seen), and none
## at all with Settings > Tutorial tips off. Turning tips back on replays them.

## id -> [title, body]. {move} / {interact} / {pause} become button glyphs.
const TIPS := {
	"move": ["MOVE", "{move} to walk. You're not supposed to be here. Don't stand still for long."],
	"watched": ["THE OWNER IS WATCHING", "The bar at the top right fills while you're here, faster when you're seen or idle. Each tick is a new reaction. When it's full, they come for you."],
	"quit": ["QUITTING COUNTS", "Dying and quitting both count against you. Close the game and the owner remembers you tried to leave."],
	"wren": ["HIDE WITH WREN", "Some people here will protect you. In the village square, stand right beside Wren and the owner's eyes slide past you."],
	"interact": ["LOOK CLOSER", "Press {interact} to talk, read and touch things."],
	"way_out": ["LOCKED OUT", "The door is the owner's, not yours. Rooms change when the owner gets suspicious: watch the walls."],
	"hidden": ["HIDDEN", "Arin can't see you here, and the owner slowly loses track of you. But if the owner finds out who helped you, they pay for it."],
	"arin": ["ARIN IS THE OWNER", "The owner plays as Arin. Stay out of the light cone, and never let Arin touch you."],
	"quiet": ["A QUIET PLACE", "The owner can't see in here. Awareness slowly cools, but never below what the owner has already done."],
	"oob": ["THE FLOOR ISN'T THERE", "Only the anchors are solid. Chunks of floor stream in and out: cross while they're there, and get off when they flicker red."],
	"pip": ["PIP", "Pip follows you and runs ahead toward whatever you need next. Pip yips when Arin is close. The owner can't see Pip."],
	"crack": ["A THIN WALL", "Something glints behind that crack. Face the wall and hold {interact} to glitch through it. Every glitch costs awareness: the bar jumps."],
	"glitch": ["GLITCH", "Hold {interact} to corrupt whatever is in the pink brackets. It works, but the owner feels every glitch: each one raises awareness."],
	"bin": ["THE RECYCLE BIN", "Stand beside a deleted file to restore them. When the bin empties, a line sweeps the room: get into a system file's cyan shadow."],
	"slot": ["SLOT 2", "Stand in the slot to write yourself in. It takes a few seconds, and the cursor selects anything that holds still. Lead it away first."],
}
## Shown in this order after waking.
const SEQUENCE := ["move", "watched", "quit", "wren"]
## A tip stays up at least this long, and at most this long.
const MIN_TIME := 3.5
const MAX_TIME := 8.0
## Behind the cracked wall (the first room's partition).
const NOOK := Rect2(462, 36, 82, 80)
## Breathing room between tips.
const GAP := 1.2

var _world: World
var _current := ""
var _shown_for := 0.0
var _gap := 1.0
var _moved := 0.0
var _last_pos := Vector2.ZERO


## Starts the tips for this session (does nothing if tips are off or seen).
func start(world: World) -> void:
	_world = world
	_last_pos = world.player.global_position


static func _unseen(id: String) -> bool:
	return Settings.tutorial_tips and id not in Settings.tips_seen


func _process(delta: float) -> void:
	if _world == null or not Settings.tutorial_tips:
		_dismiss()
		return
	var hud := _world.hud
	# Tips wait while you talk, remember, or the session is ending.
	if _world.ending != "" or _world.in_cutscene() or hud.is_dialogue_open() or hud.is_cinematic():
		if _current != "":
			hud.hide_tip()
		return
	var p := _world.player.global_position
	_moved += p.distance_to(_last_pos)
	_last_pos = p

	if _current != "":
		if not hud.is_tip_shown():
			hud.show_tip(_title(_current), _body(_current))  # back after a pause
		_shown_for += delta
		if _shown_for >= MAX_TIME or (_shown_for >= MIN_TIME and _done(_current)):
			_dismiss()
		return
	_gap -= delta
	if _gap > 0.0:
		return
	var next := _next_tip()
	if next != "":
		_show(next)


## Which tip should come up now: a contextual one if its moment is here,
## otherwise the next of the waking sequence (first room only).
func _next_tip() -> String:
	if _world.has_focus() and _unseen("interact"):
		return "interact"
	var door: Variant = _world.area.get("door")
	if door is Door and door.state != Door.State.OPEN and _unseen("way_out"):
		return "way_out"
	if _world.hiding_npc() != null and _unseen("hidden"):
		return "hidden"
	# The cracked wall in the first room teaches the first glitch.
	var cracked: Variant = _world.area.get("cracked")
	if cracked is CrackedWall and not cracked.is_open() and _unseen("crack") and "move" in Settings.tips_seen \
			and _world.player.global_position.distance_to(cracked.crack) < 90.0:
		return "crack"
	# The glitch tip waits until you've learned to move.
	if _world.glitch and not _world.glitch.target.is_empty() and _unseen("glitch") and "move" in Settings.tips_seen:
		return "glitch"
	if _world.pip != null and _unseen("pip"):
		return "pip"
	var area_tip: String = {"square": "arin", "archive": "quiet", "edge": "slot", "oob": "oob", "bin": "bin"}.get(_world.area.area_id, "")
	if area_tip != "" and _unseen(area_tip):
		return area_tip
	if _world.area.area_id != "room":
		return ""
	for id in SEQUENCE:
		if _unseen(id):
			return id
	return ""


func _show(id: String) -> void:
	_current = id
	_shown_for = 0.0
	if id == "move":
		_moved = 0.0
	Settings.mark_tip_seen(id)
	if id == "crack":
		Settings.mark_tip_seen("glitch")  # the same lesson
	_world.hud.show_tip(_title(id), _body(id))
	Sfx.ui("ui_move")


func _dismiss() -> void:
	if _current == "":
		return
	_current = ""
	_gap = GAP
	if _world:
		_world.hud.hide_tip()


## Has the player done what this tip asks?
func _done(id: String) -> bool:
	match id:
		"move":
			return _moved > 48.0
		"interact":
			return not _world.has_focus()
		"hidden":
			return _world.hiding_npc() == null
		"crack":
			return NOOK.has_point(_world.player.global_position)
	return false  # the rest just need reading time


func _title(id: String) -> String:
	return TIPS[id][0]


func _body(id: String) -> String:
	var text: String = TIPS[id][1]
	for action in ["move", "interact", "pause"]:
		text = text.replace("{%s}" % action, Settings.glyph(action))
	return text
