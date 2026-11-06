class_name Pacing
extends RefCounted
## A slower first act (2026-11-06, approved by the author after the friends'
## playtest: "lost among the characters", "from 0 to 100 too fast").
## docs/production/SLOWER_ACT_ONE.md.
##
## Nothing is added or removed; what a first-time player has to learn is
## spread out:
##   - glitches open one or two at a time, by memories recovered. In Arin's
##     room only PHASE (the cracked wall) is offered; FREEZE comes with the
##     first memory, when Arin starts to matter in the square;
##   - in Act 1 (fewer than two memories) Tobben doesn't report Rue to the
##     owner: talking to someone new is never punished in the first minutes.
##
## Tests switch it off (test_case.gd) so they keep exercising every glitch
## from the start; test_slower_act_one.gd switches it on.

static var staged := true

## Memories needed before each glitch is offered, when staged. The flat
## rule (Glitch.DEFS "needs") applies otherwise.
const GLITCH_NEEDS := {
	"phase": 0,
	"freeze": 1,
	"unlock": 2,
	"decoy": 2,
	"falsify": 3,
	"scrub": 3,
	"blind": 3,
	"restore": 4,
	"pause": 5,
}

## Act 1 ends with the second memory (the well).
const ACT_ONE_MEMORIES := 2


static func glitch_needs(id: String) -> int:
	if staged and GLITCH_NEEDS.has(id):
		return int(GLITCH_NEEDS[id])
	return int(Glitch.DEFS[id].needs)


## Glitches that recovering memory number `count` opens (in DEFS order).
static func glitches_opened_by(count: int) -> Array[String]:
	var out: Array[String] = []
	if count <= 0:
		return out
	for id: String in Glitch.DEFS:
		if glitch_needs(id) == count:
			out.append(id)
	return out


## Still in Act 1: the room and the square, before the well's memory.
static func act_one() -> bool:
	return staged and OwnerMemory.fragments.size() < ACT_ONE_MEMORIES
