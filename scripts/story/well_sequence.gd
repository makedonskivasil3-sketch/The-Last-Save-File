class_name WellSequence
extends RefCounted
## The well's five steps (docs/NARRATIVE_CONTRACT.md §6), one explanation
## for all of them: sound from the real room carries down the well, and the
## unsaved space under it keeps what saves lose. Each step needs the one
## before it, and is saved in OwnerMemory.well_events.
##
##   click     first time near the well            a real button's click
##   tune      click + memory THE WELL, at the     the music box, one note
##             pillar below                        missing
##   words     tune + LISTEN at the rim            "still have my save?"
##   compared  words + memory DELETE or the        it's her, outside
##             owner's draft in the bin read
##   answered  compared + answer, then stay at the +20 awareness; the anchor
##             rim 2 s (open square, no escort)   is set (World.ANCHORS)

const STEPS := ["click", "tune", "words", "compared", "answered"]

const CLICK_LINE := "(that was a button. a real one. like a controller, very far up.)"
const TUNE_LINE := "(the tune from up there. the same note's missing. it was always missing.)"
const LISTEN_NOTHING := "(water. and something like a room, very far up. nothing yet.)"
const LISTEN_WAITING := "(it's quiet. it was only ever going to say it once.)"
const WORDS_SPEAKER := "THE WELL"
const WORDS := ["...", "> still have my save?"]
const WORDS_AFTER := "(nobody here talks like that. nobody here types.)"
const COMPARED := [
	"(still have my save? ...she asked that. months later. the owner started to answer and didn't.)",
	"(it's her. outside. she's still asking.)",
]
const COMPARED_NOT_YET := "(i've heard that somewhere. i don't remember where yet.)"
const ANSWER_PROMPT := "answer the well (stay close)"
const ANSWER_LINES := [
	"(i'm here.)",
	"(something down there keeps it. i can feel where.)",
]
const ANSWER_HOPE := "(she's still out there asking. and wren still wants to see the edge. that's two reasons.)"
const ANSWER_HOPE_ALONE := "(she's still out there asking. that's a reason.)"
const ANSWER_NOT_ESCORTING := "(not now. not with someone to keep safe.)"
const ANSWER_SECONDS := 2.0
const ANSWER_AWARENESS := 20.0
## The prerequisite for comparing: the memory that has the same words, or
## the owner's half-written reply in the Recycle Bin.
const DRAFT_JOURNAL_ID := "bin:owner_draft.txt"
const TOBBEN_WELL := "Don't lean over that. Things come back up wrong."
const ANCHOR_NOTE := "(under the well. where it kept my answer. i woke up where it kept me.)"


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


static func record(step: String) -> void:
	# Never out of order: every step needs the one before it.
	var i := STEPS.find(step)
	if i < 0 or done(step) or (i > 0 and not done(STEPS[i - 1])):
		return
	OwnerMemory.add_well_event(step)
