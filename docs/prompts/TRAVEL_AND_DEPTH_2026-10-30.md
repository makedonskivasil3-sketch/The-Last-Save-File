# Travel, movement, graphics and character depth (written 2026-10-30)

**Written by Claude for Claude**, from the author's request: "Update the game's graphics, movement and character depth; work on fixing the fast meaningless jumping from map to map."

**Status:** built in the same pass (see the bottom). Check every line against the code before trusting it.

## The problem, measured

- **The maps are single screens.**
  - Most areas are 448×256 logical px.
  - The square is 880 wide.
  - Rue walks at 90 px/s, so she crosses most rooms in about 5 s.
- **Leaving is a touch.** An `Exit` fires the moment Rue's body overlaps it, from any direction: brushing a doorway sideways counts.
- **The change itself is about half a second:**
  - a 0.25 s fade out;
  - the next map;
  - a 0.3 s fade in, with Rue already standing inside.
- **Nothing between the two maps says why she is going, or that she went anywhere.**
- **The bots change area every 10–20 s on the critical path.** For a player that reads as jumping, not travelling.

## Rules for the fix

- **No padding.** Don't make maps bigger or walks longer for their own sake.
- **Every transition carries one piece of meaning:**
  - where she is going;
  - why;
  - who is with her.
- **Keep everything that already works:**
  - the escort leash;
  - reload protection;
  - the protection policy (cards hold threats);
  - the free stop at calm moments;
  - the act cards.
- **Reduced motion gets the meaning without the motion:** text and fades only.
- **A returning player is never slowed twice:** the long beat plays only when it has something new to say.

## What to build

### 1. Leaving on purpose (movement)
- **Intent to leave:** an exit fires only when Rue is moving into it.
  - Her velocity points through the exit (dot product > 0.3), or she is standing still inside it after having walked in.
  - Brushing past a doorway sideways no longer changes the map.
  - A blocked exit still explains itself when touched.
- **Walking out:** Rue walks on through the doorway for about 0.35 s, in the exit's direction, while the screen darkens. She leaves, rather than vanishing.
- **Walking in:** on arrival she starts a few pixels outside the entry point and walks in for about 0.35 s as the picture comes up. Control returns once she is inside.
- **No bounce:** after arriving, the exit she came through ignores her until she has moved 24 px from where she arrived. Holding the direction can't throw her straight back.

### 2. A passage, not a cut
- **The passage card:** between the two maps, a short card over black.
  - The destination's name, large.
  - Under it, one line in Rue's voice saying why she is going, from the active mission: "(the lantern by the well.)". If nothing new applies: "(back to the square.)".
  - Under that, who is with her: "(Wren's hand in mine.)" with an escort, "(Pip, at my heels.)" with Pip.
- **Timing:**
  - **Long beat, about 1.4 s:** when the mission line or the company changed since the last passage, or on the first passage of a session.
  - **Short beat, about 0.6 s, name only:** for every other passage.
  - A press of interact or confirm ends the card early.
- **The card is not an act card.** A first visit still shows its act card in the new area as before.
- **Threats are held while it shows**, like any story card.

### 3. Doorways you can see (graphics)
- **Every open exit draws a threshold:**
  - a lit gap or road-end strip;
  - light spilling a few pixels into the room;
  - a soft vignette towards it.
- **As Rue comes within about 40 px**, the threshold brightens.
- **A closed exit draws a dimmer, cold threshold**, matching its crossed-out sign.
- **Dust:** small puffs at Rue's feet when she starts running, stops sharply or reverses, at gameplay scale. Off with reduced motion.

### 4. People notice her arrive (character depth)
- **Arrival reactions, once per arrival, only for people Rue has already met:**
  - **Wren:** looks up and waves.
  - **Tobben:** glances up from his stall, then quickly back down ("busy").
  - **The Archivist:** doesn't look up and keeps writing (he is filing).
  - **Mira:** turns from the window if her note is pinned.
- **How they show:** as their `doing` text and an emote, never as dialogue.
- **When they don't happen:** not with an escort who explains herself, and not while a threat is hunting.
- **Pip on arrival:** after a passage, Pip trots in a beat after Rue instead of appearing with her.

## Out of scope for this pass
- New maps, or larger maps.
- New dialogue trees.

## Evidence required
- **Tests:**
  - an exit ignores sideways contact and fires on intent;
  - no bounce back after arrival;
  - the passage card's long beat versus short beat;
  - skipping the card;
  - reduced motion;
  - arrival reactions only for people already met, and not while hunted;
  - the threshold is drawn and brightens.
- **Measured:** the time per transition before and after.
- **Integrated:** the bots finish with travel beats on.
- **Captures:** a passage card, a threshold and an arrival reaction.
- **Unchanged:**
  - the full suite;
  - exports;
  - browser checks.

## Built (2026-10-30)

See `RELEASE_READINESS.md`, top section, for the commit and the evidence.
