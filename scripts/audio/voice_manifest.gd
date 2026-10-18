class_name VoiceManifest
extends RefCounted
## Every story line that can be voiced, with its stable dialogue id
## (Hud.voice_id), speaker, exact subtitle text and delivery direction:
## the production list for docs/VOICE_PRODUCTION.md. Written to
## audio/voice/manifest.csv by tools/voice_manifest.gd; a test keeps the file
## in sync with the game's text, so a changed line can't keep an old take.
##
## Lines that carry run-specific numbers ("3 times i deleted you") are left
## out: they can't be prerecorded, and stay text plus procedural voice.

const PATH := "res://audio/voice/manifest.csv"
const COLUMNS := ["id", "scene", "speaker", "subtitle", "spoken", "direction", "file", "duration_s", "status", "licence"]

## Default direction per speaker (docs/VOICE_BIBLE.md has the full brief).
const DIRECTION := {
	"RUE": "close, quiet, unhurried; thinking aloud, not performing",
	"OWNER": "flat and tired, close to the mic; never shouts; pauses before names",
	"MIRA": "warm, bright, a little too eager; small breath before big words",
	"TOBBEN": "slow, low, kind; a shopkeeper who has said the same thing for years",
	"WREN": "small and quick; questions lift at the end; braver than she sounds",
	"NARRATION": "Rue's inner voice describing what she sees; soft, present tense",
	"OWNER_AS_RUE": "the owner imitating Rue's memory voice: warm on the surface, slightly too sure",
}


## [scene, line] pairs from every scene that plays voiced lines.
static func scenes() -> Array:
	var out: Array = []
	for line in Story.BOOT:
		if line.begins_with(">"):
			out.append(["boot", line])  # the rest of the boot is the save's screen text
	for f in Story.FRAGMENTS:
		for line in f.lines:
			out.append(["memory." + f.id, line])
	for line in Story.FALSE_FRAGMENT.lines:
		out.append(["memory." + Story.FALSE_FRAGMENT.id, line])
	for line in Story.MIRA_PIN_SCENE:
		out.append(["mira.pin", line])
	for line in Story.GUESTBOOK_SCENE:
		out.append(["guestbook", line])
	for ending in Story.FINAL_EXCHANGE:
		for line in Story.FINAL_EXCHANGE[ending]:
			out.append(["final." + ending, line])
	for state in _states():
		_apply(state)
		for line in Story.slot2_recap(state.get("escorting", false)):
			out.append(["slot2.recap", line])
		for ending in Story.ENDING_TITLES:
			for found in [0, Story.FRAGMENTS.size()]:
				for pip in [false, true]:
					for message in Story.MESSAGES.size():
						for line in Story.epilogue(ending, found, pip, message):
							out.append(["epilogue." + ending, line])
	_apply({})
	return out


## The saved flags epilogues and the recap read: the base state, then one
## flag at a time (each extra line depends on a single flag).
static func _states() -> Array:
	return [{}, {"wren_saved": true}, {"wren_deleted": true}, {"mira_quest": "pinned"}, {"mira_quest": "lost"},
		{"mira_quest": "reset"}, {"guestbook_restored": true}, {"found_controller": true}, {"escorting": true}]


static var _saved: Dictionary = {}


## Set the flags a state names (and put everything back for {}).
static func _apply(state: Dictionary) -> void:
	var m := OwnerMemory
	if _saved.is_empty():
		_saved = {"wren_saved": m.wren_saved, "fates": m.npc_fates.duplicate(), "mira_quest": m.mira_quest,
			"guestbook_restored": m.guestbook_restored, "found_controller": m.found_controller}
	m.wren_saved = state.get("wren_saved", _saved.wren_saved)
	m.npc_fates = _saved.fates.duplicate()
	if state.get("wren_deleted", false):
		m.npc_fates["wren"] = "deleted"
	m.mira_quest = state.get("mira_quest", _saved.mira_quest)
	m.guestbook_restored = state.get("guestbook_restored", _saved.guestbook_restored)
	m.found_controller = state.get("found_controller", _saved.found_controller)
	if state.is_empty():
		_saved = {}


## Who says a line, from how the game writes it.
static func speaker(line: String) -> String:
	if line.begins_with(">"):
		return "OWNER"
	if line.begins_with("("):
		return "RUE"
	for who in ["MIRA", "TOBBEN", "WREN"]:
		if line.begins_with(who + ":"):
			return who
	return "NARRATION"


## What the actor says: no "NAME:" tag, no ">" prompt, no thought brackets.
static func spoken(line: String) -> String:
	var s := line.strip_edges()
	s = s.trim_prefix(">").strip_edges()
	for who in ["MIRA:", "TOBBEN:", "WREN:"]:
		s = s.trim_prefix(who).strip_edges()
	if s.begins_with("(") and s.ends_with(")"):
		s = s.substr(1, s.length() - 2)
	return s.replace("\n", " ")


## A line that can't be prerecorded (numbers that change from run to run)
## or isn't speech (the save file's UI text).
static func voiceable(scene: String, line: String) -> bool:
	if scene == "slot2.recap" and line.to_lower() != line.to_upper() and RegEx.create_from_string("\\d").search(line):
		return false
	if line == line.to_upper() and line.to_lower() != line:
		return false  # SLOT 2  ·  ATTEMPT, NEW GAME · SLOT 2 · WREN...: screen text
	if line.strip_edges().begins_with("[") and line.strip_edges().ends_with("]"):
		return false  # a stage direction, shown but never spoken
	return true


## The manifest rows, deduplicated by id, in a stable order.
static func rows() -> Array:
	var seen := {}
	var out: Array = []
	for pair in scenes():
		var scene: String = pair[0]
		var line: String = pair[1]
		if not voiceable(scene, line):
			continue
		var id := Hud.voice_id(scene, line)
		if seen.has(id):
			continue
		seen[id] = true
		var who := speaker(line)
		if who == "NARRATION" and scene.begins_with("memory."):
			# Memories are Rue remembering; the planted one is the owner's
			# imitation of her (it should sound almost right).
			who = "OWNER" if scene == "memory." + Story.FALSE_FRAGMENT.id else "RUE"
		var file := "audio/voice/%s.ogg" % id
		var recorded := VoiceOver.path_for(id) != ""
		out.append({
			"id": id, "scene": scene, "speaker": who, "subtitle": line, "spoken": spoken(line),
			"direction": DIRECTION["OWNER_AS_RUE"] if scene == "memory." + Story.FALSE_FRAGMENT.id else DIRECTION.get(who, ""), "file": file,
			"duration_s": "%.2f" % (VoiceOver.stream_for(id) as AudioStream).get_length() if recorded else "",
			"status": "recorded" if recorded else "text only (not recorded)",
			"licence": "" if not recorded else "see audio/voice/CREDITS.md",
		})
	return out


static func to_csv(rows_: Array) -> String:
	var lines: PackedStringArray = [",".join(COLUMNS)]
	for r in rows_:
		var cells: PackedStringArray = []
		for c in COLUMNS:
			cells.append("\"%s\"" % str(r[c]).replace("\"", "\"\"").replace("\n", "\\n"))
		lines.append(",".join(cells))
	return "\n".join(lines) + "\n"
