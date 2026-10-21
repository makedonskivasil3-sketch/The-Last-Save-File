class_name Relationships
extends RefCounted
## What happened between Rue and the people of Ashvale, as event ids that
## survive death and restart (OwnerMemory.rel_events), and the choice of what
## someone says next (docs/NARRATIVE_CONTRACT.md §4).
##
## A conversation is a Dictionary: {"lines": Array, "id": String,
## "commit": Array of event ids}. The ids in "commit" are written only when
## the box is read to its last line (World._on_dialogue_closed), so walking
## away halfway never marks a confession heard.
##
## Precedence, first match wins:
##   1. urgent current condition    2. consequence of a recent event
##   3. relationship continuation   4. a new story topic
##   5. a brief familiar greeting   6. an optional repeat

## Events and what they mean (the journal and the selector read these).
const EVENTS := {
	"wren.met": "Met Wren in the square.",
	"wren.sheltered": "Wren hid you from Arin.",
	"wren.promised": "You promised to take Wren to the Edge.",
	"wren.saw_death": "Wren saw you taken.",
	"wren.reunited": "You came back to Wren after she saw you taken.",
	"wren.promise_kept": "You took Wren to the Edge.",
	"wren.promise_broken": "Wren was deleted while she trusted you.",
	"wren.restored": "You brought Wren back from the Recycle Bin.",
	"wren.ribbon_taken": "You took Wren's ribbon.",
	"wren.ribbon_returned": "You gave Wren's ribbon back.",
	"wren.heard_well": "Wren hears the well too.",
	"mira.met": "Met Mira in Arin's room.",
	"tobben.met": "Met Tobben at his stall.",
	"archivist.met": "Met the Archivist.",
}

## Wren's lines for each step (the order is the precedence above).
const WREN_ESCORT := ["I'm right behind you. Don't stop for me. I'll keep up."]
const WREN_AFTER_DEATH := [
	"You came back. I saw them take you. Right there. I didn't know people could come back.",
	"...I kept your place. By the crates. Stand there if you need to.",
]
const WREN_SAW_STATIC := "I saw the static take you. It went right past me after. Like I wasn't worth erasing. ...You came back, though."
const WREN_AFTER_RESTORE := ["It was dark. Then it wasn't. You came all the way to the bin for me?"]
const WREN_AFTER_RESTORE_BROKEN := ["You said you'd— ...I remember the first half of that. You came back for me anyway."]
const WREN_PROMISE_OPEN := "Are we still going? To the Edge. You said."
const WREN_PROMISE_BROKEN := "You said you'd— I don't remember the rest. Something about the Edge."
const WREN_WELL := [
	"You heard it too? The well. It hums sometimes. I thought it was just me.",
	"It doesn't hum like us. It hums like the people who used to play.",
]
const WREN_GREETING := "Oh. It's you. Hi. You still look like someone."


## Every line Wren can say from here (the voice manifest lists them).
static func wren_lines() -> Array:
	return WREN_ESCORT + WREN_AFTER_DEATH + [WREN_SAW_STATIC] + WREN_AFTER_RESTORE + WREN_AFTER_RESTORE_BROKEN \
		+ [WREN_PROMISE_OPEN, WREN_PROMISE_BROKEN] + WREN_WELL + [WREN_GREETING]


## Records an event once; the session it happened in is kept.
static func add(id: String) -> bool:
	return OwnerMemory.add_event(id)


## Records an event that can happen again: the latest session is kept.
static func mark(id: String) -> void:
	OwnerMemory.rel_events[id] = OwnerMemory.sessions
	OwnerMemory.save_memory()


static func has(id: String) -> bool:
	return OwnerMemory.has_event(id)


## Did `id` happen in the session just before this one?
static func last_session(id: String) -> bool:
	return has(id) and int(OwnerMemory.rel_events[id]) == OwnerMemory.sessions - 1


## Wren's next conversation (village_square.gd asks; `talk` counts her
## repeat lines this visit, `ask_ready` says whether she would ask now).
static func wren(talk: int, ask_ready: bool, escorting: bool) -> Dictionary:
	# 1. Urgent: she's with you.
	if escorting:
		return {"lines": WREN_ESCORT, "id": "wren.escort", "commit": []}
	# 2. Consequences of something recent (said once each).
	if has("wren.restored") and not OwnerMemory.has_conversation("wren.after_restore"):
		var broken := has("wren.promise_broken")
		return {"lines": WREN_AFTER_RESTORE_BROKEN if broken else WREN_AFTER_RESTORE, "id": "wren.after_restore", "commit": []}
	if last_session("wren.saw_death") and not OwnerMemory.has_conversation("wren.after_death:%d" % OwnerMemory.rel_events["wren.saw_death"]):
		var seen: Array = WREN_AFTER_DEATH.duplicate()
		if OwnerMemory.last_death == "eraser":
			seen[0] = WREN_SAW_STATIC
		return {"lines": seen, "id": "wren.after_death:%d" % OwnerMemory.rel_events["wren.saw_death"], "commit": ["wren.reunited"]}
	# 3. Continuation: an open promise (she asks again: the ask flow follows).
	if has("wren.promised") and not has("wren.promise_kept") and ask_ready:
		var open := WREN_PROMISE_BROKEN if has("wren.promise_broken") else WREN_PROMISE_OPEN
		return {"lines": [open], "id": "wren.promise_open", "commit": [], "ask": true}
	# 4. A new topic: the well, once Rue has heard it speak.
	if OwnerMemory.has_well_event("words") and not has("wren.heard_well"):
		return {"lines": WREN_WELL, "id": "wren.well", "commit": ["wren.heard_well"]}
	return {}


## The familiar greeting, for someone met in an earlier session, said once
## a session before their usual lines.
static func greeting(id: String) -> String:
	if id == "wren" and OwnerMemory.met_before(id):
		return WREN_GREETING
	return ""


## Short summaries for the journal's People page, oldest first, only for
## events that happened (never a hint of what hasn't).
static func history(who: String) -> Array[String]:
	var out: Array[String] = []
	var ids: Array = OwnerMemory.rel_events.keys().filter(func(k: String) -> bool: return k.begins_with(who + ".") and EVENTS.has(k))
	ids.sort_custom(func(a: String, b: String) -> bool: return int(OwnerMemory.rel_events[a]) < int(OwnerMemory.rel_events[b]))
	for id in ids:
		out.append(EVENTS[id])
	return out


## The promise or worry still open with someone, or "".
static func unresolved(who: String) -> String:
	if who == "wren":
		if has("wren.promised") and not has("wren.promise_kept"):
			return "You promised her the Edge." if not has("wren.promise_broken") else "You promised her the Edge. She was deleted before you got there."
		if has("wren.ribbon_taken") and not has("wren.ribbon_returned") and "wren" in OwnerMemory.frayed:
			return "You still have her ribbon."
	if who == "mira":
		if OwnerMemory.mira_quest == "reset":
			return "She doesn't remember you."
		if OwnerMemory.mira_quest == "lost":
			return "Her note was taken from you."
	return ""
