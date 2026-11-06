# A slower first act (2026-11-06)

**Why:** the friends' playtest said "lost among the characters" and "from 0 to 100 too fast". A count of the first 10–15 minutes agreed:
- about 10 named people;
- about 7 systems;
- two framing scenes before play.

The author approved the recommendation: introduce less at once, and add no content.

**Rule:** rearrange what already exists. No story text, characters, places or endings were added or removed. Code: `scripts/story/pacing.gd` (`Pacing.staged`, on in play).

## What changed

### 1. Glitches open one or two at a time

Before, PHASE, FREEZE, FALSIFY and UNLOCK were all open from the start, and DECOY came with the first memory. Arin's room therefore offered FREEZE on Mira and FALSIFY on the note in the first minute, before the player had a reason to want either.

| Memories | Opens | Where it is first needed |
|---|---|---|
| 0 (Arin's room) | **PHASE** | The cracked wall: the room's one lesson |
| 1 (the room's memory) | **FREEZE** | The square, where Arin starts to matter |
| 2 (the well) | **UNLOCK**, **DECOY** | Arin's house door; outrunning hunters |
| 3 (the Archive) | **FALSIFY**, **SCRUB**, **BLIND** | Notes, the static, the Edge's cursor |
| 4 | **RESTORE** | Bringing someone deleted back |
| 5 | **PAUSE** | The last stretch |

Each new glitch gets its own NEW GLITCH card, 3 s apart when several open together.

### 2. Tobben is quiet in Act 1

Talking to Tobben used to send him to report Rue to the Owner, every time, from the first minute. A new player was punished for meeting someone new.

Now, in Act 1 (before the well's memory), meeting him costs nothing. From the second memory on, he reports as before. His first-meeting card, his lines and his story are unchanged.

### 3. Already staged, and kept

- The Archivist appears in the Archive and Pip out of bounds; both are met later in the route.
- First-meeting cards (5 Nov) for Mira, Wren, Tobben and the Archivist.
- The side checklist: the mission and its steps.
- The progression stages (MEMORIES → INVESTIGATE → FILE → KNOWN) keep the truth about Rue and the girl until after the memories.

## Acts, as the player meets them

| Act | Places | People met | Systems in play | The one question |
|---|---|---|---|---|
| **1** (0–1 memories) | Arin's room, the square, the lantern workshop, down the well | Mira, Wren; Tobben harmless | Awareness; PHASE, then FREEZE; Arin walking his round | Who am I, and how do I get out? |
| **2** (2–3) | Out of bounds (the well's memory is found there), the Archive, the house | Pip, the Archivist; Tobben now reports | UNLOCK, DECOY, then FALSIFY, SCRUB, BLIND; the static | Who kept the fifth lantern burning? |
| **3** (4–5) | The Edge, Slot 2 | (the truth pieces) | RESTORE, PAUSE; the cursor | What is Rue, and what will she do with Slot 2? |

## Verified

**`tests/test_slower_act_one.gd`** (6 cases):
- only PHASE is offered in the room (no FREEZE on Mira, no FALSIFY on the note);
- glitches open in the order above, never more than three at once, and all are open by the last memory;
- the NEW GLITCH cards, one per glitch;
- Tobben is quiet in Act 1 and reports from memory 2 on;
- the flat rule is kept with staging off.

**Bots under the staged rules:**
- the new CI tests `test_full_game_escape_staged` and `test_full_game_message_staged`;
- the Wren, RUE (both routes), overwrite and unseen routes, run with `BOT_STAGED=1`.

Every ending is still reached: no route depends on a glitch arriving early.

The rest of the suite keeps the flat rule (`test_case.gd` switches staging off). It tests every glitch from the start, as before.

## Not verified: the point of it

Whether a new player is now **less lost** is a human question. Measure it with the playtest in [`PHONE_INPUT_PASS_2026-11-06.md`](PHONE_INPUT_PASS_2026-11-06.md) §8, with 3–5 new players:

- Can they answer "who are you controlling" and "who is controlling Arin"?
- How many people can they name after 15 minutes, and which?
- Do they try a glitch before its card, and look for it?
- Do they feel the game slowing down too much (too little to do in Act 1)?

If Act 1 now feels empty, the next lever is staging, not words: a small task for Mira or Wren, from the per-character arcs the author has still to approve.
