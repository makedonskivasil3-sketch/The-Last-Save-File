# THE LAST SAVE FILE: product specification (one page, 2026-10-31)

**This page is current.** The older spec below it is history. Canon follows [`CANON_DECISIONS.md`](../CANON_DECISIONS.md); where this page and canon disagree, canon wins. Nothing here is measured with players yet; every number marked *provisional* waits on [`playtest/RUN_A_ROUND.md`](../playtest/RUN_A_ROUND.md).

**Audience:**
- **Who:** adults who finish short narrative games in one or two sittings. Players of quiet, character-led suspense who like a mystery told through places and objects, not combat.
- **Not for:** players who want action, progression systems or long play.

**Platform and input:**
- **Windows PC first** (the commercial target, owner to confirm), with keyboard, a controller and pointer.
- **Linux:** kept, because it costs nothing extra.
- **Browser:** a free demo or playtest build only, verified separately.
- **Mobile:** not a launch platform. Touch works, but has its own verification.

**Three promises:**
1. **You are the character someone left running.** Rue acts on her own when no one is playing her, and the game makes you feel that impossibility.
2. **The person with all the power is coming back to clean up.** The Owner adapts to what you do, through Arin, reloads and erasure. Every threat is warned before it hurts.
3. **The people in the save matter.** Wren, Mira, Tobben, the Archivist and Pip change because of what you do together, and they remember it between sessions.

**Core loop:** explore a small place, read the Owner's warning, hide or act, then find a memory or fix something. Somebody notices. The save remembers.

**Emotional progression:**
1. Warmth (the festival).
2. Abandonment and an impossible act (the fifth lantern).
3. Being hunted in someone else's save.
4. Small victories with people who aren't played.
5. The truth about what Rue is.
6. A choice at Slot 2.

**Campaign structure:**
- **Prologue:** the festival.
- **Chapters I–IV:** the story stages (Arin's room; the light by the well; who kept it burning; what's left of Slot 2).
- **Chapter V:** the Edge.
- **Places:** seven, plus the optional lantern workshop.
- **Endings:** six. Each is preserved with its identity.
- **Length:** *unmeasured*. The bots reach an ending in about 2.5 minutes of travel; the real length is reading and relationships. **Don't price from a guess.**

**Demo** *(proposed, to review)*:
- **Contents:** the festival; Arin's room; the square with Wren's game; the Archive arch; the workshop repair; Wren noticing the light.
- **Ends:** on that acknowledgement, before the CHARACTER FILE, the Edge or any ending.
- **Saves:** separate from the full game.

**Business model (recommended):**
- A premium, one-time-purchase narrative game with a free demo.
- **No** ads, microtransactions, daily tasks or engagement loops: they would fight a short, finite story about leaving.
- **Price:** set after the first ending is measured with people. Not before.

**Out of scope for 1.0:**
- online play;
- new areas or endings beyond those listed;
- procedural content;
- voice cloning;
- a mobile release;
- localisation (English first; strings are stable before translation);
- any reinterpretation of canon (Rue is not the girl; the well keeps recordings; Arin is mute).

---

# THE LAST SAVE FILE: product specification

**Status:** working spec, 2026-10-27, written against `main` @ `6fb8e23` plus this branch. It describes the game **to be released**; anything not yet built is marked *(to build)*. Canon follows [`CANON_DECISIONS.md`](../CANON_DECISIONS.md); where this page and canon disagree, canon wins.

## The promise

A short narrative suspense game about a game character left running after the person who played her moved away. You are Rue. The owner of the save comes back three years later, doesn't know who she is, and starts cleaning up.

- **Genre:** narrative suspense / light stealth, top-down pixel art.
- **Length target** *(proposed, not measured)*: 2–3 hours for a first ending.
- **Platforms** *(proposed)*: Windows first (Steam/itch), Web (itch) as demo. Linux build kept. Mobile is not a launch target.
- **Price band:** *proposed* in [`COMMERCIAL_DIRECTION.md`](../COMMERCIAL_DIRECTION.md); not decided.

## Identity (fixed)

| | |
|---|---|
| **Rue** | The game character, left running. Not the girl who played her. |
| **Player 2** | The girl who played Rue. Moved away. Present only as recordings and traces. |
| **Arin** | Slot 1's avatar. Mute. Not the Owner and not Player 1. |
| **Player 1 / the Owner** | The person who owns the save. Returns three years later. Antagonist by indifference, not malice. |
| **The well** | Holds **recordings**, never live contact. |

No twist may invalidate these relationships.

## Core loop

1. **Explore** a map with one active mission and a reason to be there.
2. **Read the Owner:** cursor, lamp, sweeps, saves-over. Every threat is telegraphed and holds during cards and choices.
3. **Hide or act:** shelter, closets, shadows; the glitch power at a cost.
4. **Find** memory fragments and recordings. They feed the journal and the relationships.
5. **Decide:** with people (Mira, Wren, Tobben, the Archivist, Pip) and finally at Slot 2.
6. **Persist:** what happened is kept across sessions. Quitting has a cost *(rule under author review: see Save and Exit)*.

## Structure

The festival prologue, then: Arin's Room → Village Square → Out of Bounds → the Archive → Arin's House → the Recycle Bin → the Edge (Slot 2). Six endings: escape, rue, wren, message, unseen, overwrite. The route graph is in [`MATRICES.md`](MATRICES.md).

## Quality bar for release

Commercially ready only when **all** of these hold, each with evidence tied to a revision:

- The campaign is complete: all six endings reachable by a human and by the bots.
- The controls are clear: unfamiliar players get through the festival and the room without help.
- Saves are trustworthy: atomic, versioned, migrated, and no ordinary closure is punished without the author's rule.
- Accessibility settings work: reduce motion, reduce flashing, text size and speed, captions, remapping *(to build)*.
- The platform is tested: Windows executed on real hardware, plus one physical controller.
- Rights are documented: fonts, voice and any commissioned art.
- Known defects are resolved or explicitly accepted.
- Evidence from unfamiliar players exists ([`PLAYTEST_PLAN.md`](../PLAYTEST_PLAN.md)).
- **The author approves.**

None of the last four is met today.

## Out of scope for 1.0

Online multiplayer; voice cloning; mobile release; procedural content.
