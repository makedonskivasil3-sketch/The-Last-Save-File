class_name LanternRoute
extends RefCounted
## A small optional mission. Physical actions are lasting relationship-style
## events, so existing saves need no extra flags or inventory migration.

const ENTERED := "lantern.workshop"
const SPOOL := "lantern.wick"
const REPAIRED := "lantern.repaired"


static func repaired() -> bool:
	return Relationships.has(REPAIRED)


static func goal() -> String:
	if repaired():
		return "The service light is on. Use the hatch to the well, or return upstairs to the Archive."
	if Relationships.has(SPOOL):
		return "Fit the festival wick to the lamp on the centre workbench."
	return "Find the spare wick on the west workbench, then repair the service lamp."


static func record(id: String, title: String, lines: Array) -> void:
	Relationships.add(id)
	OwnerMemory.record_read("workshop:" + id, "note", title, "workshop", lines)
