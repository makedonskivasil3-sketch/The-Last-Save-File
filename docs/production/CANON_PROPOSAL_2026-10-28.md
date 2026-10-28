# Canon proposal: the colours, Rue's mind, the Owner (2026-10-28)

**Status: proposal for the author.** Nothing here overrides [`CANON_DECISIONS.md`](../CANON_DECISIONS.md) or [`TRUTH_TABLE.md`](TRUTH_TABLE.md) until it is approved. Only the cold open (§4) is built, because the author asked for more tension at the start. It is one scene and easy to remove.

Every proposal below is checked against what the game already shows. Nothing contradicts the decided canon:
- Rue is the character left running, not the girl.
- Arin is mute.
- The well keeps recordings and makes no live contact.
- Beliefs are not facts.
- The natives matter in their own right.

## 1. The losing colours: what the game already does, explained

**What is built today** (`Player.MISSING`, `Player.RESTORE_ORDER`, `Story.RESTORED`):
- Rue wakes in missing-texture cyan: no face, two points of light.
- Each recovered memory gives back one thing the girl chose when she made her, in order: the red scarf, the hair, the yellow raincoat, real shoes, then her face.
- Shedding a body takes a colour from someone else: Mira's colour, Wren's ribbon (Tobben's voice is taken too, but doesn't show).
- When the owner comes close, Rue flickers back to cyan.

**The rule (proposed truth):** *colour is choice.*
- Slot 2 held what the girl **chose**: name, colours, face. Deleting it took those.
- The backup kept what she **did**: 41 hours of behaviour.
- So Rue runs on in a body with no chosen colours: the engine's missing-texture cyan.
- A memory is a moment when the girl chose something for her ("somebody picked that colour for me, carefully"). Recovering one puts that choice back.

**What follows from the rule:**
- **The natives' colours are their own.** They are native data that nobody chose for them. That is why taking Mira's is a theft: "she was the only colour in that room."
- **The owner's flicker:** under his attention Rue becomes what his save says she is, *unrecognised*.
- **The one open hook, not built:** in the `rue` ending, Rue writes her own name. A colour nobody chose for her could appear there, her first one. *Author decision B.*

**Where the player learns it:** nothing new needs saying. The five restore lines already say it piece by piece.
- **Proposed:** one optional Archivist remark the first time he sees Rue partly coloured: "Colours are what someone chose for you. You're getting yours back one at a time. Interesting that they're hers." Not built.

## 2. Rue's independent mind

**The rule (proposed truth):** *a habit with nobody to correct it becomes a choice.*
- The behaviour file is 41 hours of the girl's input, learned: what she would press next.
- The festival's last session never closed (§4). When both players left, that prediction kept running with nothing to check it against.
- Every action since is a guess about the girl that nobody marks wrong. A guess nobody marks wrong is a decision.

**The game already plays this:**
- At the save crystal, Rue first does the inherited habit (two light taps, then the press). From the third press she presses once, her own way (`SavePoint.OWN_AT`).
- The festival's fifth lantern is lit with no controller held.

**Proposed extension (not built):** let the line between inherited and own show more often, with no new mechanics:
- Rue's thoughts mark the moment a habit is broken. Example: the first time she hides somewhere the girl never would have.

## 3. The Owner: who he is and what he wants

**Already canon:**
- Player 1, Arin's player: the girl's sibling. The "couch at mum's" and the console ("it's my console anyway").
- He deleted slot 2 the night her message came, "because the empty slot was easier than the waiting".
- He returns three years later.

**Proposed: his larger goal is to finish closing the door.**
- Mum's house is being cleared, and the console goes with it.
- Tonight he plays the save one last time, then cleans it up: a save with only Arin in it, a childhood that doesn't wait for anyone.
- Each escalation (patching seams, reloading, saving over, deleting helpers) is him making the save match the version he can live with.
- It isn't malice. It is grief handled by deletion. That excuses nothing: Mira, Wren and Tobben are harmed, and the game never says otherwise.

**The "in and out of the machine" frame (the author's Assassin's Creed reference):**
- *Inside:* he plays through Arin. When Arin moves, he is in the dream.
- *Outside:* the only views of the real room are what the well keeps (its sounds, his typing) and his notes. Both are already canon.
- **Proposed:** say this once in his notes: "when i play arin i'm nine again. when i stop, i'm in an empty house with boxes." That makes the pull between the two places his conflict.
- No live contact is added: the room is only ever *recorded*.

**Why this serves the experience:**
- **The doom** (the "Attack on Titan" feeling): from the first minute the player knows the person with all the power means to clean this place up tonight.
- **The small hope:** everything Rue does with the others is done against that.
- **The endings already fit:**
  - **message:** he calls her instead of cleaning up.
  - **escape and rue:** Rue saves herself before he can.
  - **wren:** Wren gets the slot.
  - **overwrite:** he wins.

**Rejected alternatives:**
- **A third party (he sells the console):** adds a person the story never shows.
- **He is trying to recover the girl:** contradicts "you're not her" and pushes toward live contact.

## 4. The cold open (built)

`scripts/ui/cold_open.gd` plays before the festival on a first run only. Four console lines on black, each typed, then held until the player reads on:

> MEMORY CARD · 1 FILE
> SLOT 1 · ARIN · LAST PLAYED 3 YEARS AGO
> LAST 2-PLAYER SESSION · NEVER CLOSED
> \> one more go. then i'm cleaning it up.

**What each line does:**
- **"Never closed":** a reason Rue is still running that the festival then shows ("the session is never saved off", `STORY_CHRONOLOGY.md`).
- **The Owner's line:** says what's at stake before the festival's warmth.

**Rules it keeps:**
- **No exposition:** it explains nothing the festival shows.
- **Skip:** a held Esc skips it.
- **Recoverable:** it is kept in the journal either way ("The memory card").
- **Replays:** a replay from the menu skips it.
- **Tests:** `tests/test_cold_open.gd`.

## Author decisions

| | Question | Recommendation |
|---|---|---|
| A | Adopt "colour is choice" (§1) as canon? | Yes: it explains what's built and changes no text |
| B | Rue's own first colour in the `rue` ending? | Yes, but only after a playtest shows players read the colours at all |
| C | The Owner's goal (§3): clearing the house, cleaning the save tonight? | Yes |
| D | Keep the cold open (§4)? | Keep it; judge in play |
| E | The two proposed lines (Archivist §1, owner note §3)? | Add once A and C are decided |
