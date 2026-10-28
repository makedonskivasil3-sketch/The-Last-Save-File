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
