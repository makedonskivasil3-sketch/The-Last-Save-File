# Representative voiced segment: the Wren ending

**Status: production-ready line package. Nothing is recorded.**

This is the first segment to record and audition in the game, before the rest of the script. It is the complete Slot 2 exchange and the epilogue when Rue gives the slot to Wren. It is chosen because one scene carries the owner's control giving way, Wren's plainness, and Rue's steadiness at the end.

## Blocker (exact)

No recorded or generated performance in this repository has established rights.

- The earlier pilot (`docs/VOICE_PILOT.md`) was generated on a free-tier account. Its commercial rights are not established, and nobody has listened to it. It must not be shipped or used as evidence.
- Recording needs one of the following:
  - **(a) Actors:** consenting actors with a signed release.
  - **(b) A licensed AI-voice service:** a paid plan whose terms grant commercial use, chosen by the author. Using a service means buying a plan, which needs the author's approval; it hasn't been attempted.
- No identifiable performer is to be imitated.

## Whole-script size (from `audio/voice/manifest.csv`, 2026-10-19)

**Total: 216 lines, 2,479 words, 12,728 characters.**

| Speaker | Lines | Words | Characters |
|---|---|---|---|
| Narration (Rue's inner voice in scenes) | 55 | 682 | 3,574 |
| Owner | 36 | 296 | 1,400 |
| Rue | 34 | 316 | 1,688 |
| Mira | 34 | 382 | 1,924 |
| Wren | 22 | 300 | 1,507 |
| Archivist | 20 | 306 | 1,582 |
| Tobben | 15 | 197 | 1,053 |

The manifest is built from a new game's state.

- **Missing from the manifest:** lines that only appear under conditions, such as the truth lines once Rue knows what she is, or counts of runs and deaths.
- **What it would take to add them:** a pass over `Story` that adds each conditional line once.

## Coverage, defined honestly

**Would play recorded audio once files exist:**
- conversations (`npc.<id>.*`);
- scenes and cinematics, including memories, the Slot 2 recap, final exchanges and epilogues.

**Would not play recorded audio:**
- the owner's ambient console lines;
- urgent warnings.

The ambient lines and warnings stay as typed text with procedural blips. Warnings appear on their own strip, so they never wait behind speech, and they remain fully readable with speech muted.

**Never voiced:**
- frayed Tobben, who only writes;
- interface text and speaker tags.

Lines written to cut off mid-word (for example `that's all i have left of`) are recorded as cut off.

## The segment

It plays in this order: the recap (its last two lines are shown here), the choice, the final exchange, then the epilogue.

| # | ID | Speaker | Subtitle | Spoken | Context | Objective | Direction |
|---|---|---|---|---|---|---|---|
| 1 | `slot2.recap.cb69a042` | Owner | > you brought the girl. of course you did. | you brought the girl. of course you did. | Recap, Wren at Rue's side | Contempt that's really tiredness | Flat, close; "of course" almost fond |
| 2 | `slot2.recap.855065c3` | Owner | > ...go on, then. whose name goes in it. | ...go on, then. whose name goes in it. | Last recap line, before the choice | Giving up control without saying so | Long breath before "go on"; no question lift |
| 3 | `final.wren.ef85eaa6` | Owner | > who is that. i didn't make her. | who is that. i didn't make her. | Wren is written into Slot 2 | Disorientation: something in the save isn't theirs | Quiet, slower; not a threat |
| 4 | `final.wren.303565e2` | Wren | WREN: I'll keep it warm. Your slot. In case. | I'll keep it warm. Your slot. In case. | Wren, inside the slot | Comfort Rue without crying | Plain, brave, economical; no cuteness; small pause before "In case" |
| 5 | `final.wren.d8aa4b56` | Rue | (go. it only fits one.) | go. it only fits one. | Rue, outside | Let her go | Close, steady (the steadiest she sounds in the game) |
| 6 | `epilogue.wren.5ccb244f` | Narration | a girl with pigtails stands at the start of a whole new world… | (as subtitle) | Epilogue | Wonder, held back | Rue's inner voice, present tense, soft |
| 7 | `epilogue.wren.208ca4af` | Wren | WREN: aren't you coming? | aren't you coming? | Epilogue | Hope | Lift at the end, not sung |
| 8 | `epilogue.wren.1e731aa3` | Rue | (no. it only fits one. go.) | no. it only fits one. go. | Epilogue | Gentle insistence | Same steadiness as line 5 |
| 9 | `epilogue.wren.9d5b495e` | Rue | (i know my name now. i don't need a slot to keep it.) | (as subtitle) | Only with every memory | Peace | Slower; a small smile |
| 10 | `epilogue.wren.3ffe4075` | Narration | the owner finds a save they don't remember making. they leave it alone. | (as subtitle) | Epilogue | Release | Even, unhurried |

**For every line:**
- **Take:** none.
- **Duration:** none.
- **Approval:** not recorded.
- **Source and rights:** none.

## Mastering and checks when files exist

**Targets.** Use the house targets in `docs/VOICE_BIBLE.md` as provisional. Don't normalise whispers or very short lines up to the target; match perceived level by ear.

**File handling:**
- Keep editable source takes outside `audio/voice/`. Only the encoded runtime `.ogg` goes there, at the manifest path.
- Check the exported build contains them (`export_filter="all_resources"`).

**Test in the game:**
- manual reveal and advance, auto-advance, hold-to-skip;
- a missing file falls back to the procedural voice;
- a scene interrupting a line;
- pause and focus loss, death and retry;
- History replay;
- muted speech.

**Ducking on the web.** The music dips under speech by the Music and Memory buses' volume, which the browser build follows (`docs/AUDIO_DIAGNOSIS.md`). When the first files exist, check by ear in a browser that the dip is enough.
