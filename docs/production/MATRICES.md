# Matrices: route, mechanics, characters, revelations

**Revision:** `main` @ `6fb8e23` plus this branch, 2026-10-27.

**Sources:**
- Geometry and exits: [`MAP_DESIGN.md`](../MAP_DESIGN.md).
- Missions: `scripts/story/quests.gd`.
- Revelations: [`CANON_DECISIONS.md`](../CANON_DECISIONS.md).

This page is a summary for planning. Where code and this page disagree, the code is the truth and this page is a defect.

## World route graph (missions in story order)

```
festival prologue ──► room ──► square ──┬──► oob (under the well) ──► square
  THE FIFTH LANTERN      THE LIGHT BY   ├──► archive (east)  WHO KEPT IT BURNING ──► pointer
                         THE WELL       ├──► house           WHAT SHE LEFT (optional)
                                        ├──► bin             BRING THEM BACK (Wren / deleted)
                                        └──► edge (north road, needs the pointer)
                                              WHAT'S LEFT OF SLOT 2 ──► six endings
```

Threat and shelter columns are a summary; per-map detail is in `MAP_DESIGN.md`, and the Owner can't see into the Archive or Out of Bounds (`NARRATIVE_BIBLE.md` §rules).

| Map | Mission while there | Unlocks / gives | Threat | Shelter |
|---|---|---|---|---|
| Festival | Light the five lanterns | `festival_choice`; first mission | none (story) | — |
| Room | THE FIFTH LANTERN | way out; Mira's first meeting | owner's lamp, glances | under/behind furniture |
| Square | THE LIGHT BY THE WELL | the well, Wren, Tobben | cursor, eraser (HUNT) | beside Wren |
| Out of Bounds | UNDER THE WELL | Pip; the kept anchor | streaming floor | unseen by the Owner |
| Archive | WHO KEPT IT BURNING → SLOT 2 | the session log, the pointer | breather (none) | — |
| House | WHAT SHE LEFT | the controller | sweeps | closets |
| Bin | BRING THEM BACK | rescues | sweep | shadows |
| Edge | WHAT'S LEFT OF SLOT 2 | the final choice | cursor, static | — |

## Mechanic matrix

| Mechanic | Introduced | Taught by | Tested in | Paid off |
|---|---|---|---|---|
| Move / interact | Festival, lantern 1 | Arin holding the gate | room exit | everywhere |
| Hide beside someone | Festival, lantern 2 | Tobben's look | Square shelter | Wren's checkpoint scene |
| Hold together | Festival, lantern 3 (the maypole) | ritual break | fifth lantern (it needs two) | Rue alone at the fifth: the first impossible action |
| Time a crossing | Festival, lantern 4 | the spotlight | the lamp in the room | the Edge |
| Read the Owner | Room | glances, warnings | Square HUNT | the Edge |
| Glitch power (cost) | Room/Square | the first glance | Wren's rescue | Slot 2 |
| Escort | Square/Bin | Wren asks | can't leave her behind | endings |
| Persistence and purge | first quit | pause menu wording | sessions | ending "unseen" / "overwrite" |

## Character matrix (relationship arc)

| Character | Who | First meeting | What they remember | Arc, built | Arc, to build |
|---|---|---|---|---|---|
| Rue | the game character, left running | the festival (P2 · RUE) | — | gestures, preference | — |
| Arin | Slot 1's mute avatar | the festival | — (mute) | nameplate: "SLOT 1 · ARIN" at the load | his presence after the load |
| Mira | lives in Arin's room and has never left it | the room (she watched the festival from the window) | the festival, by choice (lit / tried / stayed / idle / skipped) | festival memory, request | — |
| Wren | a child in the square who hides you and wants to see the Edge | the square | the lantern still lit | escort, checkpoint scene, rescue | **the deep arc** (author, 2026-10-27): she watched the festival; nothing of her is in the well; her chalk; WREN on the rim (`WREN_ARC.md`) |
| Tobben | the shopkeeper; must report you ("It's in my script") | the festival (the look) | nobody came back to set them off | observable change | — |
| Archivist | keeper of the records | the Archive | every session | pointer, topics | — |
| Pip | Rue's fox, never saved back in, so never deleted | Out of Bounds | — | reunion | — |

## Revelation matrix (what the player can know, and when)

| Truth | Earliest the player can see it | Confirmed by | Never contradicted by |
|---|---|---|---|
| Rue moves when nobody is playing her | **Festival C3**: the player lights the fifth lantern after both players have left | CHARACTER FILE "character: still running"; the Archive's "controller: none" | the room's first minute |
| Player 1 is the owner and left first | Festival B, "PLAYER 1 HAS LEFT THE SESSION" | load: "SLOT 1 · ARIN"; the owner's lines | — |
| Player 2 moved away | Festival C2: "the car's here" | the message ending | — |
| The well holds recordings, not contact | Out of Bounds | the Archive | every ending |
| Slot 2 was deleted | Festival D, "SLOT 2 · DELETED" | the Edge | — |
