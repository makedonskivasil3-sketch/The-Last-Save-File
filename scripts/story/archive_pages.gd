class_name ArchivePages
extends RefCounted
## The journal's sections (docs/NARRATIVE_CONTRACT.md §3): people, memories,
## documents, objects, places and leads, each built from lasting state, never
## from anything Rue hasn't met, read, seen or been told.
##
## What Rue knows about someone is kept in four kinds, never mixed:
##   SEEN     what she saw happen (an event, a meeting)
##   SAID     what someone told her (a claim; it may be wrong)
##   RUE      her own reading of it
##   UNKNOWN  a question a claim opened and nothing has answered yet
## A fact is learned when the line that tells her is shown (World ->
## OwnerMemory.learn_fact), not when she meets the person.
##
## An entry is {"key", "title", "kind", "area", "body", "who", "rev"}. "rev"
## is built from what the entry says, as ids (facts, events, a status), so
## the journal can mark an entry "updated" when it says something new,
## without being fooled by wording or formatting changes.

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

## Facts learned from what people say, by id: who it's about, its kind,
## the line that teaches it (exactly as written in the game) and how the
## journal says it. "after" (UNKNOWN only): shown once that fact is known;
## "until": hidden again once that fact is known (answered).
const FACTS := {
	"mira.not_arin": {"who": "mira", "kind": "said", "line": "You're not Arin. Who are you?",
		"text": "She saw at once that you aren't Arin."},
	"mira.never_out": {"who": "mira", "kind": "said", "line": "Can I tell you something? I've never been outside this room. Not once.",
		"text": "She says she has never been outside Arin's room."},
	"mira.note": {"who": "mira", "kind": "said", "line": "I wrote a note for the board in the square. The owner reads the board.",
		"text": "She wrote a note for the square's board. She says the owner reads the board."},
	"mira.other_one": {"who": "mira", "kind": "said", "line": "Arin never talks about the other one. The one who used to sit next to them.",
		"text": "She says Arin never talks about \"the other one\", who used to sit next to them."},
	"mira.hands": {"who": "mira", "kind": "said", "line": Story.TRUTH_LINES.mira,
		"text": "She says Arin only moves when the owner's there, and you move when nobody is. She asked who's holding you."},
	"mira.who_other": {"who": "mira", "kind": "unknown", "after": "mira.other_one", "until": "rue.file",
		"text": "Who \"the other one\" was."},
	"wren.cant_see": {"who": "wren", "kind": "said", "line": "Stand right next to me. The owner can't see what I'm standing beside. I don't know why.",
		"text": "She says the owner can't see what she stands beside. She doesn't know why."},
	"wren.risk": {"who": "wren", "kind": "said", "line": "If they find out I hid you, they'll take me out of the save. It's okay. Go.",
		"text": "She knows hiding you could get her deleted. She does it anyway."},
	"wren.edge": {"who": "wren", "kind": "said", "line": Story.WREN_ASK,
		"text": "She wants to see the Edge before they delete her."},
	"wren.played": {"who": "wren", "kind": "said", "line": Story.TRUTH_LINES.wren,
		"text": "She says nobody plays her, and nobody plays you either."},
	"archivist.unfinished": {"who": "wren", "kind": "said", "line": "The hand can't select what Wren stands beside. Don't ask me why. I wasn't finished either.",
		"text": "The Archivist says the hand can't select what she stands beside, and hints it's because she isn't finished."},
	"wren.why_hidden": {"who": "wren", "kind": "unknown", "after": "wren.cant_see", "until": "archivist.unfinished",
		"text": "Why the owner can't see what she stands beside."},
	"tobben.reports": {"who": "tobben", "kind": "said", "line": "Welcome to... I have to tell them, you know. It's in my script.",
		"text": "He says he has to report you to the owner. It's in his script."},
	"tobben.sorry": {"who": "tobben", "kind": "said", "line": "I told them. I'm sorry. Welcome to Tobben's.",
		"text": "He told the owner about you, and said he was sorry."},
	"tobben.two_names": {"who": "tobben", "kind": "said", "line": "There used to be two names in my guest book. Now there's one. I don't remember the other.",
		"text": "His guest book used to have two names. He doesn't remember the other."},
	"tobben.handwriting": {"who": "tobben", "kind": "said", "line": Story.TRUTH_LINES.tobben,
		"text": "He says you wrote RUE back in a different hand: the first was rounder, and pressed harder."},
	"tobben.whose_name": {"who": "tobben", "kind": "unknown", "after": "tobben.two_names", "until": "found.guestbook",
		"text": "Whose the other name in his guest book was."},
	"archivist.cut": {"who": "archivist", "kind": "said", "line": "I'm the Archivist. I was cut from this game before it shipped. The owner has never seen me.",
		"text": "He says he was cut from the game before it shipped, so the owner has never seen him."},
	"archivist.slot2": {"who": "archivist", "kind": "said", "line": "Slot 2? They deleted it. What was left washed up past the Edge, with the rest of the cut things. It's empty.",
		"text": "He says Slot 2 was deleted, but what was left of it washed up past the Edge. He says it's empty."},
}

## Rue's own reading of someone, shown once she has something to read it
## from (the fact named), never on meeting alone.
const RUE_READS := {
	"mira": ["mira.not_arin", "RUE: she knows I'm not Arin. She was glad anyway."],
	"wren": ["wren.cant_see", "RUE: she sees more than she says."],
	"tobben": ["tobben.sorry", "RUE: he's sorry every time."],
	"archivist": ["archivist.cut", "RUE: he reads me like a file he already filed."],
	"pip": ["", "RUE: it knows me. I don't know how yet."],
}

## Where the escort is right now (World keeps it up to date): the journal
## can say Mira is carrying her note while she walks with you.
static var escort_now := ""


## Facts by id that a line teaches (for World._on_line_revealed).
static func facts_taught_by(line: String) -> Array[String]:
	var out: Array[String] = []
	for id in FACTS:
		if FACTS[id].get("line", "") == line:
			out.append(id)
	return out


## Whether a fact (or a pseudo-fact for UNKNOWN answers) is known.
static func _known(id: String) -> bool:
	match id:
		"":
			return true
		"rue.file":
			return OwnerMemory.knows_truth
		"found.guestbook":
			return OwnerMemory.found_guestbook
	return OwnerMemory.knows_fact(id)


## What Rue knows about someone, as [kind, text, id] triples, in the order
## she learned the "said" ones; "seen" ones come from what happened.
static func facts(who: String) -> Array:
	var out: Array = []
	var seen := func(id: String, text: String) -> void: out.append(["seen", text, id])
	match who:
		"mira":
			if OwnerMemory.has_met("mira"):
				seen.call("seen.mira", "Lives in Arin's room.")
			if Relationships.has("mira.walked"):
				seen.call("seen.mira_out", "She walked out of the room with you.")
		"wren":
			if OwnerMemory.has_met("wren"):
				seen.call("seen.wren", "Stands by the crates in the square.")
			if Relationships.has("wren.sheltered"):
				seen.call("seen.wren_hid", "You stood beside her and the owner's marks didn't settle on you.")
			# Only from a look that actually reached Rue and was turned aside
			# (World.is_player_hidden, asked by Arin after range, angle and walls).
			if Relationships.has("wren.concealed"):
				seen.call("seen.wren_hid_arin", "Arin looked straight past you while you stood by her. It's true.")
			if Relationships.has("wren.promise_kept"):
				seen.call("seen.wren_cut", "She was moved to CUT CONTENT at the Edge. The owner can't delete her now.")
		"tobben":
			if OwnerMemory.has_met("tobben"):
				seen.call("seen.tobben", "Keeps the stall in the square.")
		"archivist":
			if OwnerMemory.has_met("archivist"):
				seen.call("seen.archivist", "Reads in the Archive, where the owner rarely looks.")
		"pip":
			seen.call("seen.pip", "A small orange fox. It was waiting out of bounds, under the well.")
	var said: Array = []
	for id in FACTS:
		var f: Dictionary = FACTS[id]
		if f.who != who:
			continue
		if f.kind == "said" and _known(id):
			said.append([int(OwnerMemory.facts[id]), ["said", f.text, id]])
	said.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for s in said:
		out.append(s[1])
	for id in FACTS:
		var f: Dictionary = FACTS[id]
		if f.who == who and f.kind == "unknown" and _known(f.get("after", "")) and not _known(f.get("until", "")):
			out.append(["unknown", f.text, id])
	return out


## The condition Rue last saw them in, and whether that is this run's
## (otherwise "since then: unknown"). Never read from state she hasn't seen.
static func condition(who: String) -> String:
	if who in OwnerMemory.frayed:
		return "Frayed: you're wearing a piece of them. (You know this; you're wearing it.)"
	var e: Dictionary = OwnerMemory.encounters.get(who, {})
	var seen: Dictionary = e.get("seen", {})
	var state: String = seen.get("state", "")
	var text: String = {
		"well": "Themselves, when you last saw them.",
		"restricted": "Restricted: not allowed to talk to you, when you last saw them.",
		"deleted": "Deleted: you saw them gone.",
		"reset": "Reset to her defaults. She didn't know you.",
		"safe": "Safe, as cut content.",
		"restored": "Back from the Recycle Bin, when you last saw them.",
	}.get(state, "")
	if text == "":
		return "Unknown."
	if int(seen.get("session", 0)) < OwnerMemory.sessions and state not in ["safe", "reset"]:
		text += " Since then: unknown."
	return text


static func people() -> Array:
	var out: Array = []
	var ids: Array = OwnerMemory.encounters.keys().filter(func(id: String) -> bool: return NAMES.has(id))
	if OwnerMemory.found_pip and "pip" not in ids:
		ids.append("pip")
	for id in ids:
		var lines: Array = []
		var rev: Array = []
		var by_kind := {"seen": [], "said": [], "unknown": []}
		for f in facts(id):
			by_kind[f[0]].append(f[1])
			rev.append(f[2])
		if not by_kind.seen.is_empty():
			lines.append("SEEN:\n· " + "\n· ".join(by_kind.seen))
		if not by_kind.said.is_empty():
			lines.append("SAID:\n· " + "\n· ".join(by_kind.said))
		if RUE_READS.has(id) and _known(RUE_READS[id][0]):
			lines.append(RUE_READS[id][1])
			rev.append("rue")
		if not by_kind.unknown.is_empty():
			lines.append("UNKNOWN:\n· " + "\n· ".join(by_kind.unknown))
		if id != "pip":
			var cond := condition(id)
			lines.append("NOW: " + cond)
			rev.append("c:" + str(OwnerMemory.encounters.get(id, {}).get("seen", {}).get("state", "")) + ("f" if id in OwnerMemory.frayed else ""))
		var hist := Relationships.history(id)
		if not hist.is_empty():
			lines.append("BETWEEN YOU:\n· " + "\n· ".join(hist))
		for k in OwnerMemory.rel_events:
			if k.begins_with(id + "."):
				rev.append("%s#%d" % [k, OwnerMemory.event_count(k)])
		var open := Relationships.unresolved(id)
		if open != "":
			lines.append("STILL OPEN: " + open)
			rev.append("o:" + str(Relationships.open_item(id)[0]))
		var e: Dictionary = OwnerMemory.encounters.get(id, {})
		if e.has("area") and PLACE_NAMES.has(e.area):
			var when := "" if int(e.get("last", 0)) >= OwnerMemory.sessions else " (an earlier run)"
			lines.append("LAST SEEN: " + PLACE_NAMES[e.area] + when)
		rev.sort()
		out.append({"key": "person:" + id, "title": NAMES[id], "kind": "person", "area": "", "body": "\n\n".join(lines), "who": id,
			"rev": ",".join(rev)})
	return out


static func memories() -> Array:
	return OwnerMemory.journal.filter(func(e: Dictionary) -> bool: return e.kind == "memory").map(_from_journal)


static func documents() -> Array:
	return OwnerMemory.journal.filter(func(e: Dictionary) -> bool: return e.kind != "memory").map(_from_journal)


## A document grows when the owner rewrites a note Rue has read (every
## version is kept): its revision is how many versions it holds.
static func _from_journal(e: Dictionary) -> Dictionary:
	return {"key": "journal:" + e.id, "title": e.title, "kind": e.kind, "area": e.area, "body": "\n\n".join(e.lines), "who": "",
		"rev": str(e.lines.size())}


## Things, and exactly where they are now. Each has one status:
## HEARD OF, SEEN, READ, CARRIED, USED, LOST, RETURNED or REMEMBERED.
## Remembering something is not carrying it.
static func objects() -> Array:
	var out: Array = []
	var add := func(id: String, title: String, status: String, word: String, note: String) -> void:
		out.append({"key": "object:" + id, "title": title, "kind": "object", "area": "",
			"body": "STATUS: %s: %s\n\n%s" % [word, status, note] if note != "" else "STATUS: %s: %s" % [word, status], "who": "", "rev": word})
	match OwnerMemory.mira_quest:
		"pinned":
			add.call("mira_note", "Mira's note", "pinned on the square's notice board. Mira pinned it herself.", "USED", "It's still up.")
		"lost":
			add.call("mira_note", "Mira's note", "the owner took it off Mira when they took you.", "LOST", "It was in her hands. She says she'll write another one.")
		"reset":
			add.call("mira_note", "Mira's note", "gone, with her memory of writing it.", "LOST", "")
		_:
			if escort_now == "mira":
				add.call("mira_note", "Mira's note", "Mira has it. She's carrying it to the board herself.", "CARRIED", "Not by you: by her.")
			elif OwnerMemory.knows_fact("mira.note"):
				add.call("mira_note", "Mira's note", "Mira has it, in Arin's room. She wants to pin it on the square's board.", "HEARD OF", "")
	for who in ["wren", "mira", "tobben"]:
		var piece: String = Story.SHED_PIECE.get(who, "")
		var taken_id: String = who + (".ribbon_taken" if who == "wren" else ".piece_taken")
		var back_id: String = who + (".ribbon_returned" if who == "wren" else ".piece_returned")
		if piece == "" or not Relationships.has(taken_id):
			continue
		var title := "%s's %s" % [NAMES[who].capitalize(), piece]
		if Relationships.after(taken_id, back_id) and who in OwnerMemory.frayed:
			add.call(who + "_piece", title, "you're wearing it.", "CARRIED", "It isn't yours. They're missing it.")
		else:
			add.call(who + "_piece", title, "given back, from the Recycle Bin." if Relationships.has(back_id) else "back with them.", "RETURNED", "")
	if OwnerMemory.guestbook_restored:
		add.call("guestbook", "The torn guest-book page", "you wrote the name on it back into Tobben's book.", "USED", "")
	elif OwnerMemory.found_guestbook:
		add.call("guestbook", "The torn guest-book page", "in the Recycle Bin. You remember the name on it.", "READ", "Tobben's book is missing it.")
	if OwnerMemory.found_controller:
		add.call("controller", "The second controller", "under the couch in Arin's house. Left there.", "SEEN", "The cable is taped where the dog chewed it.")
	elif OwnerMemory.has_fragment("controller"):
		add.call("controller", "The second controller", "in a memory. Where it is now, you don't know.", "REMEMBERED", "The cable was taped where the dog chewed it.")
	if Relationships.has("archivist.pointer") or OwnerMemory.met_archivist:
		add.call("pointer", "slot_2.ptr", "kept in the save. It opens the north road.", "CARRIED", "The Archivist gave it to you.")
	if not OwnerMemory.anchor.is_empty():
		add.call("anchor", "Your place, under the well", "kept out of bounds, where nothing is saved.", "USED", "If the owner takes you, you wake there.")
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
		out.append({"key": "place:" + id, "title": PLACE_NAMES[id], "kind": "place", "area": id, "body": body, "who": "",
			"rev": ",".join(here)})
	return out


## What Rue could do next, from what she knows (never what she doesn't).
static func leads() -> Array:
	var out: Array = []
	var add := func(id: String, title: String, body: String) -> void:
		out.append({"key": "lead:" + id, "title": title, "kind": "lead", "area": "", "body": body, "who": "", "rev": ""})
	add.call("goal", "Where you're going", Progression.journal_summary())
	for who in ["wren", "mira", "tobben"]:
		var open := Relationships.unresolved(who)
		if open != "":
			add.call("promise:" + who, NAMES[who].capitalize(), open)
	for l in WellSequence.leads():
		add.call(l[0], l[1], l[2])
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
