# Prompt for ChatGPT: The Last Save File, review, fixes and modern gameplay

Copy everything below the line into ChatGPT.
- Attach or paste the files it asks for. It cannot see the repository on its own.
- Repository: `makedonskivasil3-sketch/The-Last-Save-File`, branch `claude/last-save-file-prototype-ljwuq4`.

---

You are a senior game programmer and game designer working with me on **The Last Save File**, a finished vertical slice built in **Godot 4.3** (GDScript, Compatibility renderer). Your job:
1. **Fix the known issues** listed below, carefully and with tests.
2. **Propose and implement more modern gameplay feel and systems** within the game's established direction and rules.

Work in small, reviewable steps. Never guess at code you haven't seen: ask me to paste a file before you change it.

## 1. What the game is (context you must respect)

### Premise

You wake up inside someone else's video game save file, as an intruder.
- The console belongs to "the owner", who plays the hero **Arin** in Slot 1.
- Years ago a girl played her own character in **Slot 2** for 41 hours, then moved away. Months later the owner deleted Slot 2.
- You are **Rue**: that character, still running in the save that survived. Rue is **not** the girl; she is what the girl left behind. Rue is "she".
- The owner notices Rue and tries to get rid of her.

### The story

- Rue recovers five memories across five areas.
- She learns the truth from a "CHARACTER FILE".
- She reaches Slot 2 at "the Edge" (an unloaded part of the world), where she chooses an ending.
- There are six endings (escape, RUE, message, Wren, unseen, overwrite).
- Persistent cross-run state: deaths and quits add "purge" steps; at 6 the save is wiped.

### The threat: the owner

- An **awareness meter** with thresholds: NOTICE, SUSPECT, CONTAIN, SILENCE, HUNT, PURGE.
- **Arin** patrols with a vision cone.
- At HUNT a **mouse cursor** chases Rue and "clicks" (deletes) her if she stands still under it.
- **Erasure static** spreads across the floor.
- **"Saving over you"** is a ring that fills while Rue stands still.
- **Reload rewinds** drag Rue back about 10 s.
- **Dragged crates** can block roads.

### Rue's tools

- **Glitches**, each held on the interact button:
  - PHASE (through walls);
  - FREEZE (Arin);
  - BLIND (the cursor);
  - DECOY (leaves a stale copy of Rue);
  - PAUSE (the owner).
- **Hiding**: beside a friendly NPC, or in closets.
- Glitches raise awareness.

### Areas

Arin's room, the village square (Ashvale), Out of Bounds, the Archive, the Recycle Bin, Arin's house, and the Edge.

### The cast

- Mira and Wren (escortable side stories);
- Tobben (the shopkeeper who reports you);
- the Archivist (cut content);
- Pip (Rue's fox).

### Art direction

- A contemporary illustrated psychological thriller.
- Vector-drawn characters with one dark outline, at a 640×360 logical resolution.
- Licensed Inter type; restrained UI; atmospheric lighting.
- Corruption used deliberately, never as noise.
- The title screen has key art: Rue facing the TV the save runs on.

### Architecture

- **Autoloads:** `OwnerMemory` (persistent save, atomic JSON), `Settings`, `Sfx`, `PlaytestLog`.
- **World** (`world.gd`) runs the session. Each area extends `Area`.
- **The HUD** (`hud.gd`) owns dialogue, choices, cinematics, the console, cards and banners.
- **`OwnerDirector`** owns awareness. **`OwnerMoves`** owns save-over, reload and drag.
- **`OwnerAvatar`** is Arin: it walks on a `NavGrid` (AStarGrid2D) at its body's clearance.
- **`OwnerCursor`**, **`SlotTwo`**, **`Erasure`**.
- **One protection rule**, `World._reading_now()`, holds every threat while something covers the screen (dialogue, a question, a cinematic, an act or NEW GLITCH card). Small text (tips, console lines) never holds.
- **Tests:**
  - about 470 headless tests (`tests/run.sh`);
  - 5 exact-ending bots that play with real input;
  - a Playwright browser lifecycle check (`tests/web/web_check.cjs`) and an audio output check;
  - visual tours that take screenshots.

### Rules you must keep (do not break these)

- Don't invent canon. Rue is the character, not the girl.
- The author decided the escape card's wording ("the owner doesn't know this slot survived. not yet."). Keep it; you may propose alternatives.
- Keep the quit/purge rule: quitting mid-run counts and adds purge, and the browser warns before closing a tab mid-run.
- No new areas, endings or glitches unless I explicitly approve them. Propose first.
- Never force maximum volume. Respect reduced-flashing, large text and tips-off settings.
- Do not call the game release-ready.
- Do not claim human, listening or hardware results you didn't get. Label every claim as one of: Implemented / Automated test / Visually inspected / Human observed / Hardware measured / Pending.
- Every change needs a test, or a stated reason why it can't have one.

## 2. Known issues to fix (from a code review of the latest work)

For each issue:
- **Confirm it first:** ask for the file, show me the exact code path, or write a test that fails.
- **Then fix it,** with the smallest correct change.
- **Then explain:** player impact, the fix, and the test.

**A. Navigation (`scripts/owner/nav_grid.gd`, `scripts/world/areas/area.gd`, `scripts/owner/owner_avatar.gd`, `scripts/world/drag_prop.gd`, `scripts/world/door.gd`)**

1. **`NavGrid.refresh()` always bumps `version`.** A stuck walker calls `Area.geometry_changed()` around itself, which makes every walker in the area replan every few seconds even when nothing changed.
   - Fix: `_mark()` returns how many cells flipped; bump the version only when that is above 0.
   - Test: two walkers. One stuck on a known solid must not cause the other to replan.
2. **A crate's last small move can be lost.** `DragProp` notifies only after a move of more than 4 px, at most every 0.25 s. A drag that ends with under 4 px of movement leaves the grid stale.
   - Fix: notify once more when the stack stops.
   - Test: through the real cursor drag (`OwnerCursor.drag`), not by setting the position.
3. **`Area.geometry_changed()` waits on a freed area.** It awaits two physics frames on the area. If the area is freed during that wait (leaving mid-drag, or a door forced open just before an area change), the coroutine may resume on a freed instance.
   - Reproduce it first.
   - If it reproduces, use a tree-level deferred call guarded by `is_instance_valid`.
4. **Deep-penetration recovery is untested.** Recovery uses `get_rest_info().normal`. With Arin's centre deep inside a thick block (say 6 px into a 40 px block), the normal may be empty and Arin would freeze forever.
   - Add the test.
   - If it fails, fall back to the direction of the nearest open cell, still taking only steps that reduce the overlap.
5. **Recovery allocates on every call.** It builds a new `PhysicsShapeQueryParameters2D` and `CircleShape2D` every call. Cache them per avatar.
6. **Recovery is bounded per area, not per attempt.** `_recovered` (capped at 16 px) resets only once Arin is clear. Decide whether a new grid version (a level change) should reset it, so a stuck Arin can try again when an opening appears.
7. **Two owners of the area grid.** The Edge (`guard_grid()`) and `OwnerAvatar.nav()` can each build the area's grid, with different exclusions. Make `Area.nav_grid()` the single owner.

**B. Protection policy (`world.gd`, `hud.gd`, `owner_cursor.gd`, `the_edge.gd`)**

8. **Free movement under cards (design question).** An act or NEW GLITCH card freezes every threat for about 4 s (fade-in, a 2.8 s hold, a 0.8 s fade-out) while Rue can still move about 360 px. Present options with numbers:
   - end the hold when the fade-out starts;
   - shorten the card;
   - slow Rue under cards;
   - keep it.

   Implement only the option I choose. Ending the hold when the fade-out starts is the safe minimum.
9. **PAUSE now cancels clicks, undocumented.** Clearing the cursor's click progress on any pause also applies to the PAUSE glitch, so PAUSE now cancels a click in progress. Decide whether to clear only for story holds, and document the decision.
10. **Two arrival holds at the Edge.** The Edge still has its own arrival hold (`_arriving()`) next to the shared rule. Remove the duplicate so only one path pauses the cursor.
11. **Tests skip the card's real timing.** The test helpers `start_session` and `go_to` dismiss the act card, so most tests never exercise its timing. Add one end-to-end test of a first visit with the card left up: nothing moves, then everything resumes.

**C. Finale and retry (`the_edge.gd`, `arins_room.gd`)**

12. **Empty goal after the bypass.** When Slot 2 finishes before the owner's grab, `goal_text()` returns `""`. Check that the HUD doesn't fall back to a stale goal line during the recap.
13. **Nothing may re-enable the cursor after the bypass.** `_beaten()` pauses the cursor. Make sure nothing un-pauses it during the ending (the choice closing, PAUSE ending).
    - Test the bypass with DECOY as well as BLIND.
    - Test the case where the confrontation never starts.
14. **`back_from_the_edge()` (the seam is open after a death at the Edge).**
    - Compute it once, not twice per frame.
    - Make it safe for old saves whose death log has no `session` field.
    - Check what happens when every seam has already been patched.

**D. Presentation code (`ui_style.gd`, `hud.gd`, `title.gd`, `pixel_character.gd`, `illustrated_character.gd`)**

15. **The owner's text effect changed by accident.** The new soft text shadow (`shadow_outline_size`) turned the owner's thin cyan colour-split into a blurred halo. Set it to 0 for owner lines and compare.
16. **The warning banner is a fixed 300×18 plate.**
    - Check it with large text and the longest banners ("◀◀ LOADING AUTOSAVE · 00:10 AGO").
    - Check it against a two-line goal line.
    - Size it to its text or let it wrap.
17. **Motion and reduced motion.**
    - The new turn squeeze and stop settle ignore reduced-motion settings.
    - NPC head-turns (`look_at`) don't trigger them.
    - Decide both.
18. **The title screen's settings connection.**
    - Its `Settings.changed` connection is a lambda that is never disconnected. Use a method, or disconnect it in `_exit_tree`.
    - Verify that large text is really applied on the title.
19. **Doc comments on the wrong code.** Three were left above the wrong declarations by recent edits (`area.gd` ×2, `ui_style.gd`).

**E. Story data (`story.gd`)**

20. **The truth variant of the first message ending.**
    - Verify the voice manifest, the journal and the history all show the truth variant.
    - Add a combination test over memories found {0, 3, 5} × knows the truth (yes/no) × every ending, against the canon table.
21. **The owner's "too late" line.** Verify it is shown and recorded, and not cut off by the recap cinematic.

**F. Older open items (from the player-experience review; still open)**

22. **Finale retry.** The walk back to the Edge now takes 14–17 s, measured with a bot. A full checkpoint at the Edge is a proposal only; it must not restore deleted characters, erase purge, or grant missing prerequisites. Propose a design.
23. **Phones lose runs they never quit.** Phones kill background tabs, and the next visit counts that as a quit (purge +1). Propose a fair rule that respects "quitting counts", e.g. a "suspended" state written on `visibilitychange`.
24. **The finale's balance.** Finishing Slot 2 before the owner's grab, by luring or blinding the cursor far enough away, is kept as earned counterplay. Check that it's discoverable.
25. **The finale's tests are flaky.** The browser beforeunload check has failed about 1 run in 3 in the past. Run it 10 times and report the rate honestly.

## 3. More modern gameplay (propose, then implement what I approve)

Make it feel like a 2024–2026 indie psychological thriller (*Inscryption*, *OneShot*, *Pony Island*, *Hollow Knight*-level feel, *Celeste*-level fairness), **without new areas, endings or glitches.** Deepen the systems that already exist.

For each idea, give:
- **What the player experiences**, in one sentence.
- **Why it's better**, tied to a real problem (fairness, clarity, tension, agency, repetition).
- **The exact systems or files it touches.**
- **Its risk to existing rules or tests.**
- **How we'd know it works:** a test, a playtest question, a metric.

Then rank them by impact ÷ effort. Ideas to consider (add your own):

**Feel and control**
- Coyote time and an input buffer on interactions and glitch holds.
- A radial hold indicator that fills under Rue.
- Clear tap-versus-hold feedback.
- Analog movement acceleration and deceleration curves.
- Tiny hit-pause and screen-shake budgets that respect reduced flashing.
- Rumble patterns per threat.

**Readable threats**
- Telegraphs before every lethal action: the cursor's click wind-up, the save ring's first tick, Arin's turn toward you.
- Off-screen threat indicators at the screen edge.
- A consistent danger colour language (one colour for lethal, one for warning, one for safe).
- Audio cues with a visual twin for players who play muted.

**The owner as an adaptive opponent**
- The owner already "learns" routes. Make it legible: short owner notes that react to how *you* play ("you always go left."). Rotate the counter-strategies and keep them fair.
- Never adapt in a way the player can't see or answer.

**Stealth depth with existing tools**
- Sound and line-of-sight readouts while hiding.
- A "last known position" ghost that Arin investigates.
- Hiding spots that feel risky (Wren can be deleted for helping you; make that cost visible beforehand).

**Glitch combos and expression**
- Interactions between existing glitches, e.g. a DECOY placed while PHASEd, or BLIND during a drag.
- Each combo needs clear costs and a short, optional tutorial.

**Run-to-run meaning (roguelite-style persistence, no new content)**
- A clearer "what carried over" summary on death.
- Optional challenge modifiers unlocked after the first ending: faster owner, no hiding, one glitch only.
- A run-history timeline in Records.

**Accessibility as design**
- An assist mode that slows the owner or extends grace times, clearly labelled and never shaming.
- Remappable controls.
- A hold-to-toggle option.
- Colour-blind-safe danger cues.
- A "story mode" that keeps the narrative but softens purge (it must not override the author's quit rule; propose how they coexist).

**Onboarding**
- Teach by doing, in the first room: one safe, scripted encounter for each verb (move, interact, hold, hide).
- Remove anything a player can't do yet from the HUD.

**Moment-to-moment polish**
- Contextual camera framing during the finale.
- Diegetic UI where it fits: the save ring drawn as an in-world UI widget from the owner's game, the cursor as the owner's real mouse.
- Subtle dynamic music layers per awareness threshold (the music box motif already exists).

**Session shape**
- Target 25–40 minutes for a first full run.
- Show where the current flow is slow, using the bot timings: room 30 s, out of bounds 34 s, the Archive 23 s, the Edge 45 s on a clean run.

## 4. How to work with me

1. **Start** by asking me for the files you need for the first group of issues (A1–A7). Don't ask for the whole repository at once.
2. **For each fix, give:**
   - a unified diff, or full replaced functions, with GDScript 4.3 types (`var x: Type`, explicit types where inference fails on untyped arrays and dictionaries);
   - the new or changed test, in the style of `tests/test_case.gd`: `extends "res://tests/test_case.gd"`, `check()`, `check_eq()`, `await wait_until(...)`, `start_session()`, `go_to(w, area, arrival)`;
   - the exact command to run it:
     `GODOT=/path/to/Godot_v4.3 tests/run.sh --filter=test_name`
3. **Keep code in the repository's style:**
   - short `##` doc comments that explain *why*, in plain English;
   - British spelling in player-facing text;
   - no new dependencies.
4. **For design questions,** give me two or three options with measured or estimated numbers, then stop and wait for my choice.
5. **After each group, give me a short ledger:** finding → confirmed? → fix → test → status label.
6. **At the end, give me:**
   - a prioritised next-steps list (three items);
   - a playtest plan of five questions, to check the modern-gameplay changes with 3–5 new players. Don't coach them, and don't invent their answers.

Begin with section 2, group A. Ask me for `scripts/owner/nav_grid.gd`, `scripts/world/areas/area.gd`, `scripts/owner/owner_avatar.gd` and `scripts/world/drag_prop.gd`.
