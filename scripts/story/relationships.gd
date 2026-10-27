class_name Relationships
extends RefCounted
## What happened between Rue and the people of Ashvale, as event records that
## survive death and restart (OwnerMemory.rel_events), and the one place that
## chooses what someone says next (docs/NARRATIVE_CONTRACT.md §4).
##
## A conversation is a Dictionary: {"lines": Array, "id": String,
## "commit": Array of event ids, "ask": bool, "after": Array of Callables
## run once it's read whole (one-time remarks that aren't events)}. The conversation id and the
## ids in "commit" are written only when the box is read to its last line
## (World._on_dialogue_closed), so walking away halfway never marks a
## confession heard; it is said again next time.
##
## Precedence, first match wins (one topic per conversation):
##   1. urgent current condition    (urgent(): a piece taken or given back;
##                                   escorting; the area's reset/restricted
##                                   state shapes how the rest is said)
##   2. consequence of a recent event
##   3. relationship continuation   (an open promise, a second ask)
##   4. a new story topic           (what they noticed, the well)
##   5. a brief familiar greeting   (greeting(), before their usual lines)
##   6. an optional repeat          (the area's own line counters)
## The per-character selectors below cover 2–4; Npc.interact applies 1 and 5.

## Events, and how the journal says each one (every id the game writes is
## here: an event without a label would vanish from the People page).
## Listed in the order they can happen, which breaks ties within a session.
## Events that are bookkeeping, not something that happened between people:
## recorded like the rest, never listed in the journal.
const INTERNAL_EVENTS := ["archivist.intro_pending"]
const EVENTS := {
	"wren.met": "Met Wren in the square.",
	"wren.sheltered": "You hid beside Wren.",
	"wren.concealed": "Arin looked straight at you while you hid beside Wren, and didn't see you.",
	"wren.promised": "You promised to take Wren to the Edge.",
	"wren.saw_death": "Wren saw you taken.",
	"wren.reunited": "You came back to Wren after she saw you taken.",
	"wren.promise_kept": "You took Wren to the Edge.",
	"wren.promise_broken": "Wren was deleted while she trusted you.",
	"wren.restored": "You brought Wren back from the Recycle Bin.",
	"wren.ribbon_taken": "You took Wren's ribbon.",
	"wren.ribbon_returned": "You gave Wren's ribbon back.",
	"wren.heard_well": "Wren hears the well too.",
	"wren.marked_well": "Wren chalked a mark on the well's rim, so you'd find your way up.",
	"wren.watched": "Wren watched the festival from the square. Nobody ever picked her to play.",
	"wren.unplayed": "Wren asked if the well keeps a recording of her. It can't: nobody ever played her.",
	"wren.chalk": "Wren gave you her chalk, so somebody would remember her.",
	"wren.named": "You wrote WREN on the well's rim, beside her mark of you.",
	"mira.met": "Met Mira in Arin's room.",
	"mira.asked": "Mira told you she has never left the room, and asked you to take her out.",
	"mira.walked": "You walked Mira out of her room.",
	"mira.pinned": "Mira pinned her note on the square's board.",
	"mira.note_lost": "You were taken while Mira walked with you. The owner took her note.",
	"mira.reset": "The owner reset Mira while she was with you.",
	"mira.saw_death": "Mira saw you taken, in her room.",
	"mira.deleted": "The owner deleted Mira in front of you.",
	"mira.restored": "You brought Mira back from the Recycle Bin.",
	"mira.piece_taken": "You took Mira's colour.",
	"mira.piece_returned": "You gave Mira her colour back.",
	"rue.own_press": "At Arin's save point you stopped tapping twice first, and pressed once.",
	"mira.board_checked": "You checked the board for Mira: her note is still up.",
	"mira.festival": "Mira watched the lantern festival from the window. She saw you light the last one.",
	"wren.lantern": "Wren told you the lantern by the well has been lit since the festival.",
	"tobben.met": "Met Tobben at his stall.",
	"tobben.fireworks": "Tobben still keeps the festival's fireworks under his counter.",
	"tobben.guestbook": "You wrote RUE back in Tobben's guest book.",
	"tobben.restored": "You brought Tobben back from the Recycle Bin.",
	"tobben.piece_taken": "You took Tobben's voice.",
	"tobben.piece_returned": "You gave Tobben his voice back.",
	"archivist.met": "Met the Archivist.",
	"archivist.pointer": "The Archivist gave you a pointer to Slot 2.",
	"archivist.introduced": "The Archivist told you what he is: cut before the game shipped, never seen by the owner.",
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
## The checkpoint scene (docs/VERTICAL_SLICE.md §5a): back up the well after
## waking under it, Wren is waiting at the rim with a chalk mark.
const WREN_MARKED := [
	"There you are! I did a mark. On the rim, look.",
	"That's you. The two dots are your eyes. I'm not good at hands, so you haven't got any.",
	"It's so you'd find your way up. If you came up. ...You came up.",
	"Don't tell Arin it's chalk. He thinks chalk is how you start a fire.",
]
## When she saw Rue taken first: the same, starting from that.
const WREN_MARKED_SAW := [
	"There you are! I saw them take you. So I came here, because the well's where you went before.",
	"I did a mark. On the rim, look. The two dots are your eyes. I'm not good at hands.",
	"It's so you'd find your way up. ...You came up.",
	"Don't tell Arin it's chalk. He thinks chalk is how you start a fire.",
]
## Wren's own story (docs/production/WREN_ARC.md): she watched the festival
## from the square; she learns the well keeps only people who were played,
## and she never was; she gives Rue her chalk; Rue writes her name.
const WREN_WATCHED_OPEN := "I was there. At the festival. By the crates, like always."
const WREN_WATCHED := {
	"tried": "His player stopped, and you kept holding the last lantern on your own. It doesn't light for one. Then everybody went home, and it lit anyway.",
	"stayed": "His player stopped, and you stood next to him. He didn't move. I thought you were both broken. Then everybody went home, and the last lantern lit anyway.",
	"lit": "His player stopped, and you ran to the last lantern on your own. Everybody saw. Nobody clapped.",
	"": "Everybody went home before the last lantern. Then it lit anyway. I saw it.",
}
const WREN_WATCHED_CLOSE := "Nobody ever picked me for anything. I just watched. I'm good at watching."
const WREN_UNPLAYED := [
	"The well hums like the people who used to play. That's what I said.",
	"So that's them down there. Their voices. Whoever got played.",
	"...Is there one of me?",
	"There isn't. Is there. Nobody ever played me.",
]
const WREN_CHALK_ASK := "Will you remember me? You can have my chalk."
const WREN_CHALK_CHOICES := ["I'll remember you.", "Not now."]
const WREN_CHALK_GIVEN := [
	"Write it where the owner doesn't look. The well's rim. That's where I put you.",
	"W-R-E-N. Four letters. Don't do the R backwards.",
]
const WREN_CHALK_LATER := ["That's okay. I'll keep it. It's only chalk."]
const WREN_CHALK_AGAIN := "I've still got the chalk. If you want it."
const WREN_SAW_NAME := [
	"You wrote it. On the rim, next to you.",
	"...Now there's one of me. Even if it's only chalk.",
]
## Said to herself as Rue writes it.
const RUE_WRITES_WREN := "(W-R-E-N. the R the right way round.)"
## The session she was last told "not now" (she offers again next session).
static var chalk_declined_session := -1

## Set by the square when this visit is that return (arrived by the well,
## woke under it this run): her next conversation is the scene.
static var wren_at_well := false

## The lantern festival, three years ago (docs/INTRO_REBUILD.md §2): the
## last session two players shared. Each of them saw a piece of it, and says
## it once, after they've met her. Mira watched from Arin's window; what she
## saw is how the festival ended for this save (OwnerMemory.festival_choice).
const MIRA_FESTIVAL_OPEN := "Wait. I know you. From the festival. I watched it from the window, the whole afternoon."
const MIRA_FESTIVAL_HOW := {
	"lit": "His player stopped. You didn't. You ran to the well on your own.",
	"tried": "His player stopped. You kept holding the lantern on your own. It needs two, that one. Everybody knows that.",
	"stayed": "His player stopped, and you stayed beside him. Then it got dark, and you went to the well anyway.",
	"": "Everybody went home. You didn't. You went to the well on your own.",
}
const MIRA_FESTIVAL_LAST := "You lit the last one. Nobody else came."
const WREN_FESTIVAL := [
	"The lantern by the well's still lit. Since the festival. Nobody's got oil for that long.",
	"I think it's waiting for somebody. ...Are you somebody?",
]
const TOBBEN_FESTIVAL := [
	"Still got the festival fireworks under the counter. Three years.",
	"Nobody came back to set them off. Nobody comes back for anything.",
]


static func mira_festival() -> Dictionary:
	var how: String = MIRA_FESTIVAL_HOW.get(OwnerMemory.festival_choice, MIRA_FESTIVAL_HOW[""])
	return _once("mira.festival", [MIRA_FESTIVAL_OPEN, how, MIRA_FESTIVAL_LAST], ["mira.festival"])


## Wren's own story, one step a conversation, in order (see WREN_WATCHED).
static func _wren_own() -> Dictionary:
	if has("wren.named"):
		return _once("wren.saw_name", WREN_SAW_NAME)
	if has("wren.lantern") and not has("wren.watched"):
		var how: String = WREN_WATCHED.get(OwnerMemory.festival_choice, WREN_WATCHED[""])
		return {"lines": [WREN_WATCHED_OPEN, how, WREN_WATCHED_CLOSE], "id": "wren.watched", "commit": ["wren.watched"]}
	if has("wren.watched") and has("wren.heard_well") and not has("wren.unplayed"):
		return {"lines": WREN_UNPLAYED, "id": "wren.unplayed", "commit": ["wren.unplayed"], "offer": "chalk"}
	if has("wren.unplayed") and not has("wren.chalk") and chalk_declined_session != OwnerMemory.sessions:
		return {"lines": [WREN_CHALK_AGAIN], "id": "", "commit": [], "offer": "chalk"}
	return {}


static func wren_festival() -> Dictionary:
	return _once("wren.lantern", WREN_FESTIVAL, ["wren.lantern"])


static func tobben_festival() -> Dictionary:
	return _once("tobben.fireworks", TOBBEN_FESTIVAL, ["tobben.fireworks"])


## Mira. She can't leave her room, so she knows what happens there, what
## the save's lists say (who's in it, which slots), and what you tell her.
const MIRA_ESCORT := ["I'm behind you. Don't look at me, look where we're going."]
const MIRA_ASK_AGAIN := [
	"The square. I keep thinking about it.",
	"Will you take me? I've still got the note.",
]
const MIRA_HUSHED := "I'm not supposed to talk to you. So I'll be quick."
const MIRA_AFTER_DEATH := [
	"You went grey. Right there, on the rug. And then you were gone, and the room said everything was fine.",
	"Is it always like that? You don't have to answer. I'm just glad it's you again.",
]
const MIRA_AFTER_RESTORE := [
	"I was deleted. Then I wasn't. I remember the dark in between.",
	"You came and got me. Nobody comes and gets anybody. Thank you.",
]
const MIRA_AFTER_PINNED := [
	"I pinned it. Me! With my own hands, in the square. The owner stood at the board for a whole minute. They didn't take it down.",
	"I keep wondering if it's still up. I can't check. You can. Tell me if it is?",
]
## Rue looked at the board because Mira asked her to.
const MIRA_STILL_UP := [
	"It's still up? ...It's still up.",
	"Thank you for looking. Nobody's ever gone and looked for me before.",
]
const MIRA_AFTER_NOTE_LOST := [
	"My note... they took it off me, after they took you. I had it in both hands.",
	"It's alright. I'll write another one. ...I won't. I don't think I can, twice.",
]
const MIRA_WREN_GONE := "Wren's name went out of the list last night. I felt it go. She wanted to see the Edge so badly."
const MIRA_WREN_SAFE := "Wren's name moved. It's somewhere the list can't reach now. Was that you?"
const MIRA_GREETING := "You're back. I set out two cups again. I don't know who the other one's for."
## Further down the purge she still sets them out, and has forgotten why.
const MIRA_GREETING_FADED := "Two cups again. I don't drink. I don't know why I do it."
const MIRA_GREETING_HUSHED := "...You're back. I'm not supposed to say that."

const TOBBEN_GREETING := "Back again! I'd know a face with no inventory anywhere."
const TOBBEN_GREETING_BOOK := "Two names, still. I check every morning. Welcome back."


## Every line said from here (the voice manifest lists them).
static func wren_lines() -> Array:
	return WREN_ESCORT + WREN_AFTER_DEATH + [WREN_SAW_STATIC] + WREN_AFTER_RESTORE + WREN_AFTER_RESTORE_BROKEN \
		+ [WREN_PROMISE_OPEN, WREN_PROMISE_BROKEN] + WREN_WELL + [WREN_GREETING] + WREN_MARKED + WREN_MARKED_SAW + WREN_FESTIVAL \
		+ [WREN_WATCHED_OPEN, WREN_WATCHED_CLOSE] + WREN_WATCHED.values() + WREN_UNPLAYED + [WREN_CHALK_ASK] + WREN_CHALK_GIVEN \
		+ WREN_CHALK_LATER + [WREN_CHALK_AGAIN] + WREN_SAW_NAME


static func mira_lines() -> Array:
	return MIRA_ESCORT + MIRA_ASK_AGAIN + [MIRA_HUSHED] + MIRA_AFTER_DEATH + MIRA_AFTER_RESTORE + MIRA_AFTER_PINNED + MIRA_STILL_UP \
		+ MIRA_AFTER_NOTE_LOST + [MIRA_WREN_GONE, MIRA_WREN_SAFE, MIRA_GREETING, MIRA_GREETING_FADED, MIRA_GREETING_HUSHED] \
		+ [MIRA_FESTIVAL_OPEN] + MIRA_FESTIVAL_HOW.values() + [MIRA_FESTIVAL_LAST]


static func tobben_lines() -> Array:
	return [TOBBEN_GREETING, TOBBEN_GREETING_BOOK] + TOBBEN_FESTIVAL


## Records an event once; the session it happened in is kept.
static func add(id: String) -> bool:
	return OwnerMemory.add_event(id)


## Records an event that can happen again (counted, latest session kept).
static func mark(id: String) -> void:
	OwnerMemory.mark_event(id)


static func has(id: String) -> bool:
	return OwnerMemory.has_event(id)


## Did `id` last happen in the session just before this one?
static func last_session(id: String) -> bool:
	return has(id) and OwnerMemory.event_session(id) == OwnerMemory.sessions - 1


## The session an event last happened in, if `who` hasn't been met since
## (so this is the first meeting after it), else -1. The selector runs before
## the conversation's own meeting is counted, so "since" means before now.
## A witnessed death keeps until the next time they see Rue, however many
## runs later (waking under the well can skip Mira's room for a run).
static func unacknowledged(who: String, event: String) -> int:
	if not has(event):
		return -1
	var at := OwnerMemory.event_session(event)
	var e: Dictionary = OwnerMemory.encounters.get(who, {})
	# This session's own meeting doesn't count as "since": a reunion cut off
	# halfway is still the first meeting after it.
	var seen_last := int(e.get("last", -1))
	if seen_last >= OwnerMemory.sessions:
		seen_last = int(e.get("prev", -1))
	return at if seen_last <= at and at < OwnerMemory.sessions else -1


## Did `a` happen after `b` (latest occurrences)? A never-happened `b` counts
## as before everything.
static func after(a: String, b: String) -> bool:
	return has(a) and OwnerMemory.event_order(a) > OwnerMemory.event_order(b)


## One conversation, said once, keyed by `id` (committed when read whole).
static func _once(id: String, lines: Array, commit: Array = []) -> Dictionary:
	if OwnerMemory.has_conversation(id):
		return {}
	return {"lines": lines, "id": id, "commit": commit}


## 1. Urgent, for anyone: a piece Rue took, or gave back. Said once a
## session (a remark about how they are, not a revelation), and alone: the
## next conversation picks up the rest.
static func urgent(npc: Npc) -> Dictionary:
	var id := npc.npc_id
	if id in OwnerMemory.returned_pending and Story.FRAY_RETURNED.has(id):
		OwnerMemory.returned_pending.erase(id)
		OwnerMemory.save_memory()
		return {"lines": [Story.FRAY_RETURNED[id]], "id": "", "commit": []}
	if npc.is_frayed() and "fray:" + id not in OwnerMemory.session_recalled and Story.FRAY_LINES.has(id):
		OwnerMemory.session_recalled.append("fray:" + id)  # once a session, not once a visit
		return {"lines": [Story.FRAY_LINES[id] if id in OwnerMemory.session_frayed else Story.FRAY_RECALL[id]], "id": "", "commit": []}
	return {}


## A line from Story.RECALL whose condition is `condition`, or "".
static func _recall(who: String, condition: String) -> String:
	for entry in Story.RECALL.get(who, []):
		if entry[0] == condition:
			return entry[1]
	return ""


## How the last session ended, if it was an ending ("" otherwise).
static func _last_ending() -> String:
	return OwnerMemory.last_ending if OwnerMemory.previous_exit in ["win", "escape"] else ""


## Wren's next conversation (village_square.gd asks; `ask_ready` says
## whether she would ask now).
static func wren(_talk: int, ask_ready: bool, escorting: bool) -> Dictionary:
	# 1. Urgent: she's with you.
	if escorting:
		return {"lines": WREN_ESCORT, "id": "wren.escort", "commit": []}
	# 2. Consequences of something recent (said once each).
	if has("wren.restored"):
		var told := _once("wren.after_restore:%d" % OwnerMemory.event_count("wren.restored"),
			WREN_AFTER_RESTORE_BROKEN if has("wren.promise_broken") else WREN_AFTER_RESTORE)
		if not told.is_empty():
			return told
	var died_at := unacknowledged("wren", "wren.saw_death")
	# The checkpoint scene: waiting at the well with a chalk mark. It is her
	# reunion too, when she saw Rue taken (so that isn't said twice).
	if wren_at_well:
		var marked := _once("wren.marked_well", WREN_MARKED_SAW if died_at >= 0 else WREN_MARKED,
			["wren.marked_well", "wren.reunited"] if died_at >= 0 else ["wren.marked_well"])
		if not marked.is_empty():
			return marked
	if died_at >= 0 and has("wren.marked_well") and OwnerMemory.event_session("wren.marked_well") > died_at:
		died_at = -1  # met at the well since: already said
	if died_at >= 0:
		var seen: Array = WREN_AFTER_DEATH.duplicate()
		if OwnerMemory.last_death == "eraser" and died_at == OwnerMemory.sessions - 1:
			seen[0] = WREN_SAW_STATIC
		var told := _once("wren.after_death:%d" % died_at, seen, ["wren.reunited"])
		if not told.is_empty():
			return told
	var ending := _last_ending()
	if ending != "" and _recall("wren", "ended:" + ending) != "":
		var told := _once("wren.after_ending:%d" % (OwnerMemory.sessions - 1), [_recall("wren", "ended:" + ending)])
		if not told.is_empty():
			return told
	# 3. Continuation: an open promise (she asks again: the ask flow follows).
	if has("wren.promised") and not has("wren.promise_kept") and ask_ready:
		var open := WREN_PROMISE_BROKEN if has("wren.promise_broken") else WREN_PROMISE_OPEN
		return {"lines": [open], "id": "wren.promise_open", "commit": [], "ask": true}
	# 4. New topics: what she noticed about Rue; the well, once Rue has heard it.
	var truth := Story.truth_line("wren")
	if truth != "":
		return {"lines": [truth], "id": "", "commit": []}
	# Her own story waits while her ask is due and unanswered: the Edge first.
	var own := _wren_own() if not (ask_ready and not has("wren.promised")) else {}
	if not own.is_empty():
		return own
	if OwnerMemory.has_well_event("words") and not has("wren.heard_well"):
		return {"lines": WREN_WELL, "id": "wren.well", "commit": ["wren.heard_well"]}
	return {}


## Mira's next conversation (arins_room.gd asks). Not called once she has
## been reset: then she doesn't know Rue, and the room says only that.
## `restricted`: the owner told her not to talk to Rue; she still does, quickly.
static func mira(restricted: bool, ask_ready: bool, escorting: bool) -> Dictionary:
	if escorting:
		return {"lines": MIRA_ESCORT, "id": "mira.escort", "commit": []}
	var told := _mira_news(ask_ready)
	if not told.is_empty() and restricted:
		told.lines = [MIRA_HUSHED] + told.lines
	return told


static func _mira_news(ask_ready: bool) -> Dictionary:
	# 2. Consequences, once each, most recent kinds first.
	if has("mira.restored"):
		var told := _once("mira.after_restore:%d" % OwnerMemory.event_count("mira.restored"), MIRA_AFTER_RESTORE)
		if not told.is_empty():
			return told
	var died_at := unacknowledged("mira", "mira.saw_death")
	if died_at >= 0:
		var told := _once("mira.after_death:%d" % died_at, MIRA_AFTER_DEATH)
		if not told.is_empty():
			return told
	if has("mira.note_lost"):
		var told := _once("mira.after_note_lost", MIRA_AFTER_NOTE_LOST)
		if not told.is_empty():
			return told
	if has("mira.pinned"):
		var told := _once("mira.after_pinned", MIRA_AFTER_PINNED)
		if not told.is_empty():
			return told
		if has("mira.board_checked"):
			told = _once("mira.still_up", MIRA_STILL_UP)
			if not told.is_empty():
				return told
	# What the save's list tells her (not what she saw: she can't leave).
	if OwnerMemory.is_deleted("wren"):
		var told := _once("mira.wren_gone:%d" % OwnerMemory.event_count("wren.promise_broken"), [MIRA_WREN_GONE])
		if not told.is_empty():
			return told
	elif OwnerMemory.wren_saved:
		var told := _once("mira.wren_safe", [MIRA_WREN_SAFE])
		if not told.is_empty():
			return told
	var ending := _last_ending()
	if ending != "" and _recall("mira", "ended:" + ending) != "":
		var told := _once("mira.after_ending:%d" % (OwnerMemory.sessions - 1), [_recall("mira", "ended:" + ending)])
		if not told.is_empty():
			return told
	if OwnerMemory.previous_exit == "death" and OwnerMemory.last_death == "arin" \
			and not (has("mira.saw_death") and OwnerMemory.event_session("mira.saw_death") == OwnerMemory.sessions - 1):
		# Arin walks back into her room alone: she sees that much.
		var told := _once("mira.arin_alone:%d" % (OwnerMemory.sessions - 1), [_recall("mira", "died:arin")])
		if not told.is_empty():
			return told
	# 3. Continuation: she asked once and you said not yet. The ask itself
	# comes from the room (it opens the question); this is the shorter one.
	if ask_ready and has("mira.asked") and OwnerMemory.mira_quest == "":
		return {"lines": MIRA_ASK_AGAIN, "id": "mira.ask_again", "commit": [], "ask": true}
	# 4. A new topic: what she noticed about Rue.
	var truth := Story.truth_line("mira")
	if truth != "":
		return {"lines": [truth], "id": "", "commit": []}
	return {}


## Tobben's next conversation (village_square.gd asks).
static func tobben() -> Dictionary:
	if OwnerMemory.guestbook_restored:
		var told := _once("tobben.after_guestbook", [_recall("tobben", "guestbook_restored")])
		if not told.is_empty():
			return told
	elif OwnerMemory.found_guestbook:
		var told := _once("tobben.name_back", [_recall("tobben", "found_guestbook")])
		if not told.is_empty():
			return told
	if OwnerMemory.is_deleted("wren"):
		var told := _once("tobben.wren_gone:%d" % OwnerMemory.event_count("wren.promise_broken"), [_recall("tobben", "wren_lost")])
		if not told.is_empty():
			return told
	elif OwnerMemory.wren_saved:
		var told := _once("tobben.wren_safe", [_recall("tobben", "wren_saved")])
		if not told.is_empty():
			return told
	if _last_ending() == "message":
		var told := _once("tobben.after_ending:%d" % (OwnerMemory.sessions - 1), [_recall("tobben", "ended:message")])
		if not told.is_empty():
			return told
	if OwnerMemory.deaths >= 3:
		var told := _once("tobben.tab", [_recall("tobben", "deaths:3")])
		if not told.is_empty():
			return told
	var truth := Story.truth_line("tobben")
	if truth != "":
		return {"lines": [truth], "id": "", "commit": []}
	return {}


## 5. The familiar greeting, for someone met in an earlier session, said
## once a session before their usual lines ("" for none).
static func greeting(npc: Npc) -> String:
	var id := npc.npc_id
	if not OwnerMemory.met_before(id) or "greet:" + id in OwnerMemory.session_recalled:
		return ""
	var line := ""
	match id:
		"wren":
			line = WREN_GREETING
		"mira":
			if OwnerMemory.mira_quest == "reset":
				return ""  # she doesn't know Rue
			if npc.state == Npc.State.RESTRICTED:
				line = MIRA_GREETING_HUSHED
			else:
				line = MIRA_GREETING_FADED if OwnerMemory.purge >= 3 else MIRA_GREETING
		"tobben":
			line = TOBBEN_GREETING_BOOK if OwnerMemory.guestbook_restored else TOBBEN_GREETING
	if line != "":
		OwnerMemory.session_recalled.append("greet:" + id)
	return line


## Short summaries for the journal's People page, in the order they
## happened, only for events that happened (never a hint of what hasn't).
## A repeated event is listed once, where it first happened, with its count.
static func history(who: String) -> Array[String]:
	var out: Array[String] = []
	var ids: Array = OwnerMemory.rel_events.keys().filter(func(k: String) -> bool: return k.begins_with(who + ".") and EVENTS.has(k))
	ids.sort_custom(func(a: String, b: String) -> bool:
		return int(OwnerMemory.rel_events[a].get("first_seq", 0)) < int(OwnerMemory.rel_events[b].get("first_seq", 0)))
	for id in ids:
		var n := OwnerMemory.event_count(id)
		out.append(EVENTS[id] + (" (%d times)" % n if n > 1 else ""))
	return out


## The promise or worry still open with someone, or "".
static func unresolved(who: String) -> String:
	return open_item(who)[1]


## [id, text] of what is still open with someone (["", ""] when nothing is):
## the id is stable, so the journal can tell when it changes.
static func open_item(who: String) -> Array:
	match who:
		"wren":
			if has("wren.promised") and not has("wren.promise_kept"):
				if has("wren.promise_broken"):
					return ["wren.promise_broken", "You promised her the Edge. She was deleted before you got there."]
				return ["wren.promise", "You promised her the Edge."]
			if after("wren.ribbon_taken", "wren.ribbon_returned") and "wren" in OwnerMemory.frayed:
				return ["wren.ribbon", "You still have her ribbon."]
		"mira":
			if OwnerMemory.mira_quest == "reset":
				return ["mira.reset", "She doesn't remember you."]
			if OwnerMemory.mira_quest == "lost":
				return ["mira.note_lost", "Her note was taken from her when you were."]
			if after("mira.piece_taken", "mira.piece_returned") and "mira" in OwnerMemory.frayed:
				return ["mira.colour", "You're still wearing her colour."]
			if has("mira.asked") and OwnerMemory.mira_quest == "":
				return ["mira.square", "She wants to see the square."]
		"tobben":
			if after("tobben.piece_taken", "tobben.piece_returned") and "tobben" in OwnerMemory.frayed:
				return ["tobben.voice", "You still have his voice."]
			if OwnerMemory.found_guestbook and not OwnerMemory.guestbook_restored:
				return ["tobben.name", "His guest book is missing a name. You know which."]
	return ["", ""]
