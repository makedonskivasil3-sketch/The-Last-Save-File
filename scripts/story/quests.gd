class_name Quests
extends RefCounted
## The one mission Rue is on, and the ones behind her (docs/INTRO_REBUILD.md
## §3): a reason for every map. Like Progression, read only from the save
## and the run, never from flags of its own, so a save from before missions
## existed opens on the mission its progress has reached.
##
## The HUD shows one line, "TITLE · what to do". Where a place can kill
## her (the Bin, the house, the Edge, under the well), what keeps her alive
## comes first, and the mission after it. Missions frame the story; they
## never gate it: the memories, the truth and all six endings are unchanged.

const ORDER := ["fifth_lantern", "well_light", "under_well", "who_kept", "what_she_left", "bring_back", "slot2"]
const TITLES := {
	"fifth_lantern": "THE FIFTH LANTERN",
	"well_light": "THE LIGHT BY THE WELL",
	"under_well": "UNDER THE WELL",
	"who_kept": "WHO KEPT IT BURNING",
	"what_she_left": "WHAT SHE LEFT",
	"bring_back": "BRING THEM BACK",
	"slot2": "WHAT'S LEFT OF SLOT 2",
}
## Why she goes: the journal's line for each (the HUD's comes from line()).
const WHY := {
	"fifth_lantern": "The fifth lantern is still lit. Find out who kept it burning.",
	"well_light": "The last lantern of the festival still burns by the well, three years on.",
	"under_well": "The lantern's light goes down the well, further than a well should.",
	"who_kept": "The Archive keeps the records of every session. One of them is the festival's.",
	"what_she_left": "Player 2 sat in Arin's house, in front of the screen. Something of hers may still be there.",
	"bring_back": "The owner deleted someone. Deleted things wait in the bin, for a while.",
	"slot2": "Slot 2 was deleted. Something of it is left, north of the square.",
}
const SEP := "  ·  "

## Where she is now (World sets it on arrival), for the journal, which
## doesn't know the world.
static var area_now := ""

const ROOM := "Find who kept the fifth lantern burning: get out of Arin's room."
const WELL := "Reach the fifth lantern by the well; Wren can hide you from Arin."
const OOB := "Follow the lantern's light: cross to the far ledge. Something is waiting there."
const OOB_DONE := "Climb back up at the respawn point. The Archive, east of the square, keeps the festival's records."
const ARCHIVE := "Ask the Archivist who lit the fifth lantern, and where Slot 2 went."
const EAST := "Ask the Archive who lit the fifth lantern: the road east leads somewhere old."
const NORTH := "Take the north road out of the village square, to what's left of Slot 2."
const BIN := "When the bin empties, stand in a system file's shadow; between sweeps, restore what was deleted."
const HOUSE := "When the door chimes, step into a closet; until then, look around Arin's house."
const HOUSE_DONE := "Get back to the square: you found what was under the couch."
const EDGE := "Lead the cursor away, then stand in Slot 2 to write yourself in."


## Where the story has got to, wherever she stands. `pointer`: this run
## holds the Archivist's pointer to Slot 2 (World.flags), which the save
## also keeps once he has given it.
static func story_mission(pointer := false) -> String:
	if pointer or OwnerMemory.met_archivist:
		return "slot2"
	if OwnerMemory.found_pip or "archive" in OwnerMemory.places:
		return "who_kept"
	if "square" in OwnerMemory.places:
		return "well_light"
	return "fifth_lantern"


## The active mission in `area_id` (a dangerous place has its own).
static func active(area_id: String, pointer := false) -> String:
	match area_id:
		"edge":
			return "slot2"
		"bin":
			return "bring_back"
		"house":
			return "what_she_left"
		"oob":
			return "under_well"
		"archive":
			return "slot2" if pointer or OwnerMemory.met_archivist else "who_kept"
	return story_mission(pointer)


## The HUD's goal line in `area_id` (without the title). `edge_goal` is the
## Edge's own reading of what is happening there, if it has one.
static func line(area_id: String, edge_goal := "", pointer := false) -> String:
	match area_id:
		"edge":
			return edge_goal if edge_goal != "" else EDGE
		"bin":
			return BIN
		"house":
			return HOUSE_DONE if OwnerMemory.found_controller else HOUSE
		"oob":
			return OOB_DONE if OwnerMemory.found_pip else OOB
		"archive":
			return NORTH if pointer or OwnerMemory.met_archivist else ARCHIVE
		"room":
			if story_mission(pointer) == "fifth_lantern":
				return ROOM
	match story_mission(pointer):
		"slot2":
			return NORTH
		"who_kept":
			return EAST
		"well_light":
			return WELL
	return ROOM


## The goal as World shows it: "TITLE  ·  line".
static func goal(area_id: String, edge_goal := "", pointer := false) -> String:
	return TITLES[active(area_id, pointer)] + SEP + line(area_id, edge_goal, pointer)


## Missions finished, from what the save says happened.
static func done(id: String) -> bool:
	match id:
		"fifth_lantern":
			return "square" in OwnerMemory.places
		"well_light":
			return "oob" in OwnerMemory.places
		"under_well":
			return OwnerMemory.found_pip
		"who_kept":
			return OwnerMemory.met_archivist
		"what_she_left":
			return OwnerMemory.found_controller
		"bring_back":
			return not OwnerMemory.restored.is_empty()
		"slot2":
			return not OwnerMemory.endings_seen.is_empty()
	return false


## The quest log (the journal's LEADS): the active mission first, then
## those done. Optional missions she hasn't started aren't listed (no
## spoilers of places she hasn't found).
static func log_text(area_id: String) -> String:
	var now := active(area_id)
	var lines: Array[String] = ["NOW  ·  %s\n%s\n%s" % [TITLES[now], WHY[now], line(area_id)]]
	var finished: Array[String] = []
	for id in ORDER:
		if id != now and done(id):
			finished.append("✓ " + TITLES[id])
	if not finished.is_empty():
		lines.append("DONE\n" + "\n".join(finished))
	return "\n\n".join(lines)


## Why Rue is going where she is going, in her own words, for the passage
## card between two maps (docs/prompts/TRAVEL_AND_DEPTH_2026-10-30.md §2).
## From the mission she is on there; "back" when the place has nothing new.
static func passage_reason(dest: String, pointer := false) -> String:
	var mission := active(dest, pointer)
	match dest:
		"room":
			return "(back into arin's room.)"
		"oob":
			return "(down, after the light.)" if not OwnerMemory.found_pip else "(back under the well.)"
		"archive":
			return "(the records. someone wrote down who lit it.)" if mission == "who_kept" else "(the archive. then north.)"
		"house":
			return "(her house. she sat here, in front of the screen.)" if not OwnerMemory.found_controller else "(back through arin's house.)"
		"bin":
			return "(the bin. deleted things wait there, for a while.)"
		"edge":
			return "(slot 2. what's left of it.)"
		"square":
			match mission:
				"fifth_lantern", "well_light":
					return "(the lantern by the well.)"
				"who_kept":
					return "(east, to the archive.)"
				"slot2":
					return "(north. slot 2.)"
	return "(on.)"

