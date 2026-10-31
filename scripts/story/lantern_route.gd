class_name LanternRoute
extends RefCounted
## A small optional mission. Physical actions are lasting relationship-style
## events, so existing saves need no extra flags or inventory migration.

const ENTERED := "lantern.workshop"
const SPOOL := "lantern.wick"
const REPAIRED := "lantern.repaired"
## The decision after the light: Rue writes her own name on the fifth
## frame's blank label (or leaves it; leaving it records nothing, so she can
## still choose later).
const NAMED := "lantern.named"
const NAME_ASK := "The fifth frame was the lantern by the well, the one two players had to hold together. Its label is blank. Write a name on it?"
const NAME_CHOICES := ["Write RUE", "Leave it blank"]


static func named() -> bool:
	return Relationships.has(NAMED)


static func repaired() -> bool:
	return Relationships.has(REPAIRED)


static func goal() -> String:
	if repaired():
		var frame := "" if named() else " The fifth frame on the shelf has a blank label."
		return "The service light is on. Use the hatch to the well, or return upstairs to the Archive." + frame
	if Relationships.has(SPOOL):
		return "Fit the festival wick to the lamp on the centre workbench."
	return "Find the spare wick on the west workbench, then repair the service lamp."


## One step of the mission, saved as a single write (OwnerMemory.commit_step).
## Returns whether it reached the disk: the caller tells the player if not.
static func record(id: String, title: String, lines: Array) -> bool:
	return OwnerMemory.commit_step([id], "workshop:" + id, title, "workshop", lines)
