# Story chronology and knowledge matrix (24 October 2026)

The premise is decided (`CANON_DECISIONS.md` §1): Rue is the game character
left running after her player moved away. This file gives the order of
events, who witnessed each one, and who knows what at the start of play.
Every row cites the text that establishes it. Nothing here is new canon:
where the game didn't say, the gap is marked **not stated**.

## Timeline

"Y" is the year the girl moved away. The present (the game) is about three
years after the deletion.

| When | What happened | Witnesses | Source |
|---|---|---|---|
| Before Y | Two children share one console "on the couch at mum's". The owner plays Arin in slot 1. The girl makes her own character in slot 2: "you be arin, i'll make my own" | Both children; Arin and Rue (as avatars) | Memory 1 (`FRAGMENTS[0]`); owner note 2 |
| Before Y | NEW GAME, SLOT 02, she types the name RUE ("tongue between my teeth, three letters"). It was raining | The girl | Memory 3; `RESTORED[3]` |
| Before Y | Rue walks into the well by accident and drops out of the map. The fox, Pip, falls after her. They save anyway. Pip is never saved back in | Both children; Pip | Memory 2; `story.gd` header |
| Before Y | RUE is written in Tobben's guest book "in a rounder hand" | Tobben | `TRUTH_LINES.tobben` |
| Before Y, total | 41 hours of play: Rue's behaviour is learned from her player's input (41:07:12) | — | `CHARACTER_FILE` |
| Summer, Y | The girl moves away. "Boxes in the hall." The second controller is left on the floor. "You'll visit." She came back twice | Both | Memory 4; owner note 3 |
| Y + months | The owner keeps her save, walking Arin past where her character stood | Owner | Owner note 4 |
| Y + months | Her message: "still have my save?" The owner starts typing yes, and deletes slot 2 that night instead. Nothing is sent | Owner | Memory 5; owner note 6; the opening's months-later shot |
| Same night | `slot2_backup.sav` and `rue_last_message.txt` go to the Recycle Bin, "deleted 3 years ago". What was left of slot 2 washes up past the Edge | Nobody (the Archivist filed the CHARACTER FILE "a long time ago") | `recycle_bin.gd`; Archivist |
| Y + months → present | Rue keeps running in the save that survived, unplayed. The owner barely plays ("first time in years") | — | `story.gd` header; Tobben's recall |
| Present (≈3 years on) | The owner loads slot 1. The boot finds an unrecognised entity in Arin's room. Slot 2 is "[DELETED 3 YEARS AGO]" | Owner; Rue | `Story.BOOT` (dated in this pass) |

The opening is not in this order: it shows the routine (before Y), the
interruption, the impossible action (Rue moving with nobody holding her:
an image of what she became, not a dated event), then "months later" (the
message). The boot then dates the present. Before this pass nothing in the
first minute said how long ago the deletion was; the only dates were the
Bin's file names, an Act III discovery.

## Knowledge at the start of play

| Who | Knows | Believes (may be wrong) | Doesn't know |
|---|---|---|---|
| **Rue** | Nothing: no name, no memories. Habits only (the two taps) | That she shouldn't be here | Her name (five memories), what she is (the CHARACTER FILE) |
| **The owner** | Deleted slot 2; why ("the empty slot was easier than the waiting") | That something is in Arin's room; that it might be "her" ("if that's you in there") | That it is the character, not the girl |
| **Arin** | Nothing. An avatar: moves only when the owner plays | — | — |
| **Mira** | Arin moves only when the owner is there | That Rue is "the other one, the one who used to sit next to them" (half true) | Why Rue moves when nobody does |
| **Wren** | She is cut content; nobody plays her | That nobody plays Rue either (true) | That Rue was played for 41 hours |
| **Tobben** | There were two names in his book; now one | That reporting is safe ("it's my script") | Who the other name was, until it's written back |
| **The Archivist** | He was cut before the game shipped; he filed Rue's CHARACTER FILE long ago | — | (He reads records; he wasn't there. He knows nothing the records don't say) |
| **Pip** | Rue: they fell together | That she "fell back in" | That she is not quite who fell |
| **The girl** | That she asked about her save and got no answer | — | That her character is still running |

## What the player can infer, and when

| Question | Earliest evidence | Settled by |
|---|---|---|
| Whom do I control? | The opening: the amber figure, her controller, "you · move" | The room's **you** cue |
| Is Rue the girl? | Memories say "i" (they were learned from her player) | The CHARACTER FILE: "player: moved away. character: still running." TRUTH_REVEAL: "(i'm not her.)" |
| When is now? | The boot: "[DELETED 3 YEARS AGO]" | The Bin's dates; the endings' "deleted years ago" |
| Is the well's voice live? | No: the well keeps recordings of what was said in the room, and plays them back; it doesn't send (`NARRATIVE_CONTRACT.md` §0.5, C2) | Kept apart from live communication: only the message ending reaches the girl |
| Does the owner know the slot survived? | "> what's that. SLOT 2? i deleted that." | Kept: "the owner doesn't know this slot survived. not yet." |

## Contradictions checked

| Pair | Verdict |
|---|---|
| Memory 4 "the second controller stayed on the floor" vs the false memory "you packed the second controller first" | Deliberate: the false memory is the owner's version, and is marked unsigned |
| Memory 4 "i came back twice" vs owner note 3 "she came twice" | Agree |
| Memory 5 "no answer" vs owner note 6 "i started typing yes… never sent anything" vs the opening's reply that stops mid-word | Agree: the typing is seen, nothing is sent |
| Tobben "one name: ARIN" vs "the first one was rounder" | Agree: the first RUE was rubbed out; Rue writes it again |
| Message ending: "a part of her stayed behind" | **Ambiguous** (reads as the girl herself). **Reworded:** "she's about to hear about the character she left running"; the owner: "she should know her character is still running" |
| "months later" (opening) vs "deleted years ago" (endings, Bin) | Both right, but the present was undated in the first minute. **Fixed:** the boot dates it |
| Tobben "reports less once you return his voice" (`NARRATIVE_CONTRACT.md`) | **Not true in the code** (he reported after every conversation). **Now:** one report at a time with a cooldown; none while his voice is Rue's; after the guest book a smaller report that leaves out what she asked |
