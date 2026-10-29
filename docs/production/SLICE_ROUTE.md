# The vertical slice: one route, and its rhythm (2026-10-28)

**The feeling to prove:** "I can control Rue precisely. I understand enough to act. The world unsettles me. Someone inside matters to me. What we do together changes something. I want to know what happens next." Underneath it, the author's reference: *we are probably doomed, and we keep fighting for the little hope there is.*

## The route

| # | Scene | Player intention | Action available | Emotional purpose | Information gained | Consequence | Later payoff |
|---|---|---|---|---|---|---|---|
| 1 | **Title** | Start | Load Slot 1 | Curiosity | Slot 2 is empty | — | The title changes after each ending |
| 2 | **Memory card** (cold open, new) | Read | Read on, or hold Esc | **Dread**: someone means to clean this place up tonight | The last two-player session never closed | Kept in the journal | Every Owner escalation; "still running" |
| 3 | **Festival** | Light the lanterns together | Move, light, hide, hold with Arin | Warmth, then wrongness | Two players, one save; P1 leaves mid-hold | `festival_choice` | Mira and Wren saw it; the lantern still burns |
| 4 | **The impossible lantern** | Finish what two started | Hold E with nobody playing | Awe, unease | Rue acts unplayed | `lit_by_herself` | The CHARACTER FILE |
| 5 | **Arin's room** | Get out | Talk to Mira, read the note, try the crystal, find the crack | Trapped, observed | The owner sees an intruder; the crystal refuses her | First memory (her red scarf comes back) | Her own press at the crystal |
| 6 | **The square: first threat** | Reach the lantern by the well | Hide by Wren, read Arin's cone and the lamp | Exposure | Arin is the owner's hands; Wren can hide you | Awareness rises; "wren.sheltered" | The lamp and the static later |
| 7 | **Wren's game** (now reached on the 3rd talk) | Play her game | Chalk a mark under the awning or out on the crossing | Warmth; friction when she rubs out the bad one | She judges only what she walks over to see | The R; her chalk back; her drawings in later sessions | Her shelter X during hunts; the epilogue's R |
| 8 | **One discovery: the well** | Find out what the lantern means | Listen at the rim; climb in | The world is older than you | The well keeps what was said near it: her message | The second memory; Pip | Rue's answer played back; the kept place |
| 9 | **Continuation hook** | Leave a mark | Answer at the well, or go on to the Archive | Small hope against the doom | "UNKNOWN: whether she's still asking" | — | The Archive's file; the endings |

**For the demo build:** the spoiler-safe endpoint is the Archive's arch (`CANON_DECISIONS.md` §5, behind a flag).

## Rhythm: what is measured

**The critical path, measured by the bots** (`bot_full_game_escape.log`, this revision; headless, no reading, festival not played):

| Segment | Bot time (game s) | Kind |
|---|---|---|
| Room: memory, out | 35 | movement, discovery |
| Under the well: memory, Pip, back up | 40 | movement, danger (the floor), discovery |
| Square → Archive: memory | 26 | movement, discovery |
| Square → the Edge | 11 | danger (Arin, reload) |
| The Edge → Slot 2 | 41 | danger (static, cursor), discovery (two memories), major choice |
| **Total to an ending** | **≈150–160** | |

**What this says:**
- **The game's length is reading, exploring, relationships and retries, not travel.** An optimal route covers the whole map in under three minutes.
- **The product spec's "2–3 hours" is unmeasured.** It is probably too long for the content that exists. **Do not price from it.** Measure the first ending with unfamiliar players (`PLAYTEST_PLAN.md` session E).
- **Required returns:** the critical path re-crosses the square twice (to the Archive and back, then north). Each crossing has a reason (a different exit) and a different threat state; the second has the reload. **No required return lacks a change.**
- **The festival:** measured earlier at about 4–6 min for an engaged player (`INTRO_REBUILD.md`).

**Not measured (needs people):**
- How long reading takes.
- Whether three exposition beats in a row occur on a real route (the Archive is the risk).
- Whether players reach an ending before Wren's arc has developed.

**A risk to watch:** the Wren ending can be reached on the first visit now, since her game precedes her ask. The arc's deeper beats (`wren.watched`, "is there one of me?") come only in later visits, so a player who takes her to the Edge at once ends her story early. That is a choice, not a defect, but the playtest should note it.
