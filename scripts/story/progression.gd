class_name Progression
extends RefCounted
## Where Rue is in her story, read only from the save (OwnerMemory) and the
## run's flags: no second set of flags that could disagree with it.
##
## Stages, in order (docs/GAMEPLAY_CONSISTENCY.md):
##   MEMORIES     fewer than all five memories
##   INVESTIGATE  every memory, but not enough of what the others noticed
##   FILE         ready: the CHARACTER FILE will read whole
##   KNOWN        she read it; RUE is open at Slot 2
## Ordinary escape is open in every stage: none of this gates Slot 2.
##
## Each surface says a different amount: the HUD goal one quiet hint, Pip a
## place to stand, the journal a little more. Hints never name the truth.

enum Stage { MEMORIES, INVESTIGATE, FILE, KNOWN }

## Who can still tell Rue what they noticed (said once, ever).
const WITNESSES := ["mira", "wren", "tobben"]

const HINT_INVESTIGATE := "Every memory is back. Someone who has watched you may have noticed something."
const HINT_FILE := "Something on the Archivist's desk has your name on it now."
const HINT_KNOWN := "You know who you are. Slot 2 is still north of the square."


static func stage() -> Stage:
	if OwnerMemory.knows_truth:
		return Stage.KNOWN
	if OwnerMemory.fragments.size() < Story.FRAGMENTS.size():
		return Stage.MEMORIES
	if Story.truth_ready():
		return Stage.FILE
	return Stage.INVESTIGATE


## The ones who still have something to tell her right now.
static func open_witnesses() -> Array[String]:
	var out: Array[String] = []
	for who: String in WITNESSES:
		if Story.truth_line(who) != "":
			out.append(who)
	return out


## The quiet second line under the area goal ("" for none).
static func goal_hint() -> String:
	match stage():
		Stage.INVESTIGATE:
			return HINT_INVESTIGATE
		Stage.FILE:
			return HINT_FILE
		Stage.KNOWN:
			return HINT_KNOWN if "rue" not in OwnerMemory.endings_seen else ""
	return ""


## What the journal shows at the top: more than the HUD, still no spoilers.
static func journal_summary() -> String:
	var lines: Array[String] = ["Memories: %d / %d" % [OwnerMemory.fragments.size(), Story.FRAGMENTS.size()]]
	match stage():
		Stage.INVESTIGATE:
			var noticed := OwnerMemory.truth_pieces.size()
			lines.append("Things others noticed about you: %d of %d needed." % [mini(noticed, Story.TRUTH_PIECES_NEEDED), Story.TRUTH_PIECES_NEEDED])
			if open_witnesses().is_empty() and noticed < Story.TRUTH_PIECES_NEEDED:
				lines.append("Nobody has more to say yet. Some only notice after a kindness.")
		Stage.FILE:
			lines.append("The CHARACTER FILE in the Archive will read whole now.")
		Stage.KNOWN:
			lines.append("You read your CHARACTER FILE.")
	return "\n".join(lines)


## Where Pip should lead in `area`: something relevant here and reachable,
## else Vector2.INF (then the area's own route out). `world` gives the area.
static func local_target(world: Node) -> Vector2:
	var area: Area = world.area
	if area == null:
		return Vector2.INF
	for c in area.get_children():
		if c is MemoryFragment and not c.planted:  # Pip won't lead you to the owner's lie
			return c.global_position
	match stage():
		Stage.INVESTIGATE:
			var open := open_witnesses()
			for node in area.interactables:
				if node is Npc and node.npc_id in open and node.is_present():
					return node.global_position
			# The ledge under the well has one of the things to notice too
			# (Story.FIRST_SHAPE teaches the "pip" piece on its last line).
			if "pip" not in OwnerMemory.truth_pieces:
				for node in area.interactables:
					if node is Readable and node.title == Story.FIRST_SHAPE_TITLE:
						return node.global_position
		Stage.FILE:
			for node in area.interactables:
				if node is Readable and node.title == Story.CHARACTER_FILE_TITLE:
					return node.global_position
	return Vector2.INF
