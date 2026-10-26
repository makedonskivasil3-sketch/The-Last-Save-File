class_name WellSequence
extends RefCounted
## The well's five steps (docs/NARRATIVE_CONTRACT.md §6, rev 2), one
## explanation for all of them: the well is where the saves lose things, and
## it KEEPS them, sounds from the real room included. It plays them back the
## same way every time. It does not send anything up, and nothing in the
## game proves that anyone outside hears Rue (§0.5). Each step needs the one
## before it, and is saved in OwnerMemory.well_events.
##
##   click     first time near the well            a real button's click
##   tune      click + memory THE WELL, at the     the music box, one note
##             pillar below                        missing; the place where
##                                                 she climbed back in can be
##                                                 kept (the checkpoint)
##   words     tune + LISTEN at the rim, read to   "still have my save?"; the
##             its last line                       same pause every time
##   compared  words + memory DELETE or the        her message, from months
##             owner's draft in the bin read       after she left: kept, not live
##   answered  compared + answer, then stay at the +20 awareness; listening
##             rim 2 s (open square, no escort)    again plays HER answer back

const STEPS := ["click", "tune", "words", "compared", "answered"]

const CLICK_LINE := "(that was a button. a real one. two light taps, then a press. like someone very far up, holding a controller.)"
## [delay s, volume dB, pitch]: the same gesture as the opening's shot 2
## (Opening: taps at 7.0 and 7.25 s, the press at 7.6 s).
const CLICK_PATTERN := [[0.0, -16.0, 1.3], [0.25, -16.0, 1.3], [0.6, -10.0, 0.9]]
const TUNE_LINE := "(the tune from up there. the same note's missing. it was always missing.)"
## Down here, after the tune: the place she climbed back in, once.
const ANCHOR_OFFER := "(this is where i climbed back in, the time i fell out of the world. nothing down here is saved. nothing down here can be saved over.)"
const ANCHOR_KEPT := "(if they take me, i'll wake up here. not in arin's room.)"
const ANCHOR_AGAIN := "(it's still here. it'll keep.)"
const ANCHOR_NOT_NOW := "(not now.)"
const ANCHOR_NOT_ESCORTING := "(not with someone to keep safe. later.)"
const ANCHOR_SYSTEM := "PLACE KEPT  ·  under the well"
const LISTEN_NOTHING := "(water. and something like a room, very far up. nothing yet.)"
const WORDS_SPEAKER := "THE WELL"
const WORDS := ["...", "> still have my save?"]
const WORDS_AFTER := "(nobody here talks like that. nobody here types.)"
## Listening again: exactly the same. That's the evidence it's kept, not said.
const WORDS_REPLAY_NOTE := "(the same words. the same pause before them, to the frame. it isn't saying it. it's playing it back.)"
const COMPARED := [
	"(still have my save? ...she sent that. months after she left. the owner started to answer and didn't.)",
	"(the well kept it. the room heard it once. that was then; i don't know if she's still asking.)",
]
const COMPARED_NOT_YET := "(i've heard that somewhere. i don't remember where yet.)"
const ANSWER_PROMPT := "answer the well (stay close)"
const ANSWER_LINES := [
	"(i'm here.)",
	"(nothing comes back. that isn't what it does. it keeps.)",
]
const ANSWER_HOPE := "(she asked once and nobody answered. now somebody has. and wren still wants to see the edge. that's two reasons.)"
const ANSWER_HOPE_ALONE := "(she asked once and nobody answered. now somebody has. that's a reason.)"
## Listening after answering: the well plays Rue's own answer back.
const ANSWER_REPLAY := ["...", "> i'm here."]
const ANSWER_REPLAY_NOTE := "(that's mine. it kept mine too. so it keeps what's said here; it doesn't carry it anywhere. if anything is going to reach her, it has to go through the one who reads.)"
const ANSWER_NOT_ESCORTING := "(not now. not with someone to keep safe.)"
const ANSWER_SECONDS := 2.0
const ANSWER_AWARENESS := 20.0
## The prerequisite for comparing: the memory that has the same words, or
## the owner's half-written reply in the Recycle Bin.
const DRAFT_JOURNAL_ID := "bin:owner_draft.txt"
const TOBBEN_WELL := "Don't lean over that. Things come back up wrong."
## Waking at the kept place after a death.
const ANCHOR_NOTE := "(under the well. where i climbed back in last time. it kept my place.)"


static func done(step: String) -> bool:
	return OwnerMemory.has_well_event(step)


## The next step that could happen, or "" when the sequence is complete.
static func next_step() -> String:
	for s in STEPS:
		if not done(s):
			return s
	return ""


static func can_compare() -> bool:
	return OwnerMemory.has_fragment("delete") or OwnerMemory.journal.any(func(e: Dictionary) -> bool: return e.id == DRAFT_JOURNAL_ID)


## The kept place can be chosen once the tune has played down here.
static func anchor_offered() -> bool:
	return done("tune")


static func record(step: String) -> void:
	# Never out of order: every step needs the one before it.
	var i := STEPS.find(step)
	if i < 0 or done(step) or (i > 0 and not done(STEPS[i - 1])):
		return
	OwnerMemory.add_well_event(step)


## The journal's leads for the well, as [id, title, body]: what Rue knows
## and what she doesn't, never what comes next.
static func leads() -> Array:
	var out: Array = []
	if done("tune") and OwnerMemory.anchor.is_empty():
		out.append(["well_place", "Your place, under the well",
			"By the pillar under the well, you could keep your place. If the owner takes you, you'd wake there instead of Arin's room."])
	if done("click") and not done("tune"):
		out.append(["well_click", "The well",
			"A real button clicked, from very far up. Something under the well might be worth a look."])
	elif done("tune") and not done("words"):
		out.append(["well_listen", "Listen at the well",
			"The well keeps sounds from the room up there. Listen at the rim, in the square."])
	elif done("words") and not done("compared"):
		out.append(["well_words", "Words in the well",
			"Up from the well: \"still have my save?\". The same pause, every time: kept, not said. Nobody here types. Where have you seen those words before?"])
	elif done("compared") and not done("answered"):
		out.append(["well_answer", "Answer the well",
			"Her message, from months after she left. The well kept it. You could answer at the rim, in the open; the owner will see. It won't send anything. It keeps."])
	elif done("answered"):
		out.append(["well_known", "What the well is",
			"It keeps what's said near it: her message, and now your answer. It doesn't carry anything up.\nUNKNOWN: whether she's still asking.\nIf anything is going to reach her, it has to go through the one who reads."])
	return out
