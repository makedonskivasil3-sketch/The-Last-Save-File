class_name ArchivePages
extends RefCounted
## The journal's sections (docs/NARRATIVE_CONTRACT.md §3): people, memories,
## documents, objects, places and leads, each built from lasting state, never
## from anything Rue hasn't met, read or done. Facts and Rue's own reading of
## them are kept apart ("RUE:" lines). An entry is
## {"key", "title", "kind", "area", "body", "who"}, and is new until opened.

const SECTIONS := ["people", "memories", "documents", "objects", "places", "leads"]
const SECTION_LABEL := {"people": "PEOPLE", "memories": "MEMORIES", "documents": "DOCUMENTS",
	"objects": "OBJECTS", "places": "PLACES", "leads": "LEADS"}

const NAMES := {"mira": "MIRA", "wren": "WREN", "tobben": "TOBBEN", "archivist": "THE ARCHIVIST", "pip": "PIP"}
const PLACE_NAMES := {"room": "Arin's room", "square": "Ashvale square", "oob": "Out of bounds, under the well",
	"archive": "The Archive", "bin": "The Recycle Bin", "house": "Arin's house", "edge": "The Edge"}
## What each place is, once Rue has been there (no spoilers of what's beyond).
const PLACE_NOTES := {
	"room": "Where you wake. Mira lives here. The owner watches this room most.",
	"square": "The village. Arin walks a loop. Wren stands by the crates; Tobben keeps the stall. The well is in the middle.",
	"oob": "Under the well, where nothing is saved. The floor comes and goes. The owner can barely see down here.",
	"archive": "Shelves of everything the game kept. The Archivist reads here. A breather: the owner rarely looks.",
	"bin": "Everything the owner deleted, waiting to be emptied.",
	"house": "Arin's house. Somebody's couch. Somebody's photo.",
	"edge": "Where the map stops being drawn. Slot 2 is out here.",
}


## Facts Rue has actually learned about someone, each gated on how she
## learned it. Then one line of her own interpretation.
static func facts(who: String) -> Array[String]:
	var out: Array[String] = []
	match who:
		"mira":
			out.append("Lives in Arin's room. Has never been out of it.")
			if OwnerMemory.mira_quest != "":
				out.append("Wants to be more than a line. Asked you to take her to the square.")
			if OwnerMemory.mira_quest == "pinned":
				out.append("Pinned her own note on the square's board.")
		"wren":
			out.append("Stands by the crates in the square. Arin can't see what she stands beside.")
			if Relationships.has("wren.promised") or OwnerMemory.wren_saved:
				out.append("Wants to see the Edge.")
			if OwnerMemory.wren_saved:
				out.append("Cut content. She can't be deleted any more.")
			if Relationships.has("wren.heard_well"):
				out.append("Hears the well too.")
		"tobben":
			out.append("Keeps the stall. Has to report you: it's in his script.")
			if OwnerMemory.found_guestbook:
				out.append("His guest book used to have two names.")
		"archivist":
			out.append("Keeps the Archive. Cut before the game shipped.")
		"pip":
			out.append("A small orange fox. It waits out of bounds, under the well.")
	return out


const RUE_READS := {
	"mira": "RUE: she knows I'm not Arin. She was glad anyway.",
	"wren": "RUE: she sees more than she says.",
	"tobben": "RUE: he's sorry every time.",
	"archivist": "RUE: he reads me like a file he already filed.",
	"pip": "RUE: it knows me. I don't know how yet.",
}


## Current known condition (what Rue last knew, not what she can't know).
static func condition(who: String) -> String:
	if OwnerMemory.is_deleted(who):
		return "Deleted. In the Recycle Bin, if anything."
	if who in OwnerMemory.frayed:
		return "Frayed: you're wearing a piece of them."
	if who == "mira" and OwnerMemory.mira_quest == "reset":
		return "Reset to her defaults. She doesn't know you."
	if who == "mira" and OwnerMemory.purge >= 1:
		return "Restricted: the owner has told her not to talk to you."
	if who == "wren" and OwnerMemory.wren_saved:
		return "Safe, as cut content."
	if who in OwnerMemory.restored:
		return "Restored. She remembers the dark in between." if who != "tobben" else "Restored."
	return "As you left them."


static func people() -> Array:
	var out: Array = []
	var ids: Array = OwnerMemory.encounters.keys().filter(func(id: String) -> bool: return NAMES.has(id))
	if OwnerMemory.found_pip and "pip" not in ids:
		ids.append("pip")
	for id in ids:
		var lines: Array = []
		lines.append_array(facts(id))
		if RUE_READS.has(id):
			lines.append(RUE_READS[id])
		lines.append("NOW: " + condition(id))
		var hist := Relationships.history(id)
		if not hist.is_empty():
			lines.append("BETWEEN YOU:\n· " + "\n· ".join(hist))
		var open := Relationships.unresolved(id)
		if open != "":
			lines.append("STILL OPEN: " + open)
		var e: Dictionary = OwnerMemory.encounters.get(id, {})
		if e.has("area") and PLACE_NAMES.has(e.area):
			lines.append("LAST SEEN: " + PLACE_NAMES[e.area])
		out.append({"key": "person:" + id, "title": NAMES[id], "kind": "person", "area": "", "body": "\n\n".join(lines), "who": id})
	return out


static func memories() -> Array:
	return OwnerMemory.journal.filter(func(e: Dictionary) -> bool: return e.kind == "memory").map(_from_journal)


static func documents() -> Array:
	return OwnerMemory.journal.filter(func(e: Dictionary) -> bool: return e.kind != "memory").map(_from_journal)


static func _from_journal(e: Dictionary) -> Dictionary:
	return {"key": "journal:" + e.id, "title": e.title, "kind": e.kind, "area": e.area, "body": "\n\n".join(e.lines), "who": ""}


## Things, and exactly where they are now. Remembering something is not
## carrying it: the status says which.
static func objects() -> Array:
	var out: Array = []
	var add := func(id: String, title: String, status: String, note: String) -> void:
		out.append({"key": "object:" + id, "title": title, "kind": "object", "area": "", "body": "STATUS: %s\n\n%s" % [status, note], "who": ""})
	match OwnerMemory.mira_quest:
		"pinned":
			add.call("mira_note", "Mira's note", "Used: pinned on the square's notice board.", "She wrote it herself. It's still up.")
		"lost":
			add.call("mira_note", "Mira's note", "Lost: the owner found it on you when you were taken.", "She says she'll write another one.")
		"reset":
			add.call("mira_note", "Mira's note", "Lost, with her memory of writing it.", "")
	for who in ["wren", "mira", "tobben"]:
		var piece: String = Story.SHED_PIECE.get(who, "")
		if piece == "":
			continue
		var taken := Relationships.has(who + (".ribbon_taken" if who == "wren" else ".piece_taken"))
		if not taken:
			continue
		if who in OwnerMemory.frayed:
			add.call(who + "_piece", "%s's %s" % [NAMES[who].capitalize(), piece], "Carried: you're wearing it.", "It isn't yours. They're missing it.")
		else:
			add.call(who + "_piece", "%s's %s" % [NAMES[who].capitalize(), piece], "Returned.", "")
	if OwnerMemory.found_guestbook:
		add.call("guestbook", "The torn guest-book page", "Returned: back in Tobben's book." if OwnerMemory.guestbook_restored else "Found. Tobben's book is missing it.", "")
	if OwnerMemory.found_controller:
		add.call("controller", "The second controller", "Seen: under the couch in Arin's house. Left there.", "The cable is taped where the dog chewed it.")
	if not OwnerMemory.anchor.is_empty():
		add.call("anchor", "Your answer, under the well", "Kept out of bounds, where nothing is saved.", "If the owner takes you, you wake there.")
	return out


static func places() -> Array:
	var out: Array = []
	for id in OwnerMemory.places:
		if not PLACE_NAMES.has(id):
			continue
		var here: Array = []
		for who in OwnerMemory.encounters:
			if NAMES.has(who) and OwnerMemory.encounters[who].get("area", "") == id:
				here.append(NAMES[who].capitalize())
		var body: String = PLACE_NOTES.get(id, "")
		if not here.is_empty():
			body += "\n\nLAST SEEN HERE: " + ", ".join(here)
		out.append({"key": "place:" + id, "title": PLACE_NAMES[id], "kind": "place", "area": id, "body": body, "who": ""})
	return out


## What Rue could do next, from what she knows (never what she doesn't).
static func leads() -> Array:
	var out: Array = []
	var add := func(id: String, title: String, body: String) -> void:
		out.append({"key": "lead:" + id, "title": title, "kind": "lead", "area": "", "body": body, "who": ""})
	add.call("goal", "Where you're going", Progression.journal_summary())
	for who in ["wren", "mira"]:
		var open := Relationships.unresolved(who)
		if open != "":
			add.call("promise:" + who, NAMES[who].capitalize(), open)
	if OwnerMemory.has_well_event("words") and not OwnerMemory.has_well_event("compared"):
		add.call("well_words", "Words in the well", "Up from the well: \"still have my save?\". Nobody here said that. Where have you seen it before?")
	elif OwnerMemory.has_well_event("compared") and not OwnerMemory.has_well_event("answered"):
		add.call("well_answer", "Answer the well", "It was her, outside. Stand at the well and answer. The owner will see you doing it.")
	elif OwnerMemory.has_well_event("tune") and not OwnerMemory.has_well_event("words"):
		add.call("well_listen", "The well", "Something down there keeps the sounds from the room. Listen at the rim.")
	return out


static func section(id: String) -> Array:
	match id:
		"people": return people()
		"memories": return memories()
		"documents": return documents()
		"objects": return objects()
		"places": return places()
		"leads": return leads()
	return []
