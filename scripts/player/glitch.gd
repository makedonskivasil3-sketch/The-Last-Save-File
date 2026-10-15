class_name Glitch
extends RefCounted
## Rue's power: hold [E] on something to corrupt it. Every glitch is loud:
## it costs awareness (the owner feels the save twitch), more for stronger
## glitches. Four are there from the start; each memory you recover unlocks
## one more, stronger one.
##
## Targets are picked by GlitchController: the nearest glitchable thing in
## range, else the wall in front of you (phase), else yourself (decoy while
## running, pause while standing still).

## id -> definition.
##   name   shown in the prompt
##   cost   awareness added when it fires
##   hold   seconds of holding [E] to charge it
##   needs  memories recovered to unlock it
##   range  how far away a target can be
##   how    one line for the unlock notice / README
const DEFS := {
	"phase": {"name": "PHASE", "cost": 8.0, "hold": 0.45, "needs": 0, "range": 14.0,
		"how": "hold [E] facing a wall: slip through it"},
	"freeze": {"name": "FREEZE", "cost": 6.0, "hold": 0.4, "needs": 0, "range": 70.0,
		"how": "hold [E] near Arin or anyone: they stop for 2 seconds"},
	"falsify": {"name": "FALSIFY", "cost": 4.0, "hold": 0.4, "needs": 0, "range": 34.0,
		"how": "hold [E] on a note: it lies, and the owner relaxes for a while"},
	"unlock": {"name": "UNLOCK", "cost": 10.0, "hold": 0.55, "needs": 0, "range": 44.0,
		"how": "hold [E] on a locked door: it opens for 5 seconds"},
	"decoy": {"name": "DECOY", "cost": 7.0, "hold": 0.35, "needs": 1, "range": 0.0,
		"how": "hold [E] while running: leave a frame of yourself behind for them to chase"},
	"scrub": {"name": "SCRUB", "cost": 9.0, "hold": 0.5, "needs": 2, "range": 40.0,
		"how": "hold [E] near the eraser: wipe its void back into floor"},
	"blind": {"name": "BLIND", "cost": 10.0, "hold": 0.45, "needs": 3, "range": 90.0,
		"how": "hold [E] near the cursor: it can't see you for 3 seconds"},
	"restore": {"name": "RESTORE", "cost": 20.0, "hold": 1.2, "needs": 4, "range": 34.0,
		"how": "hold [E] on what's left of someone deleted: bring them back"},
	"pause": {"name": "PAUSE", "cost": 15.0, "hold": 0.8, "needs": 5, "range": 0.0,
		"how": "hold [E] standing still: pause the owner's world for 6 seconds"},
}

## How long each effect lasts.
const FREEZE_TIME := 2.0
const UNLOCK_TIME := 5.0
const DECOY_TIME := 4.0
const BLIND_TIME := 3.0
const PAUSE_TIME := 6.0
const LIE_TIME := 15.0
## Phase moves you at most this far.
const PHASE_RANGE := 46.0

## The owner, the first time each glitch is used in a session.
const OWNER_REACTION := {
	"phase": "you can't walk through walls.",
	"freeze": "arin? ARIN.",
	"falsify": "i didn't write that.",
	"unlock": "that door is locked. i locked it.",
	"decoy": "there you— no.",
	"scrub": "stop undoing my work.",
	"blind": "i can't see. why can't i see.",
	"restore": "i deleted them. i DELETED them.",
	"pause": "...why won't it move.",
}


static func is_unlocked(id: String, memories: int, all := false) -> bool:
	return all or memories >= int(DEFS[id].needs)


## The glitch that recovering memory number `count` unlocks ("" if none).
static func unlocked_by(count: int) -> String:
	for id: String in DEFS:
		if int(DEFS[id].needs) == count and count > 0:
			return id
	return ""


static func cost(id: String) -> float:
	return float(DEFS[id].cost)


static func label(id: String) -> String:
	return "%s +%d" % [DEFS[id].name, int(DEFS[id].cost)]
