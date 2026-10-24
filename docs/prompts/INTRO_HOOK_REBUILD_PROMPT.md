# Brief: rebuild the first ten minutes of The Last Save File (hook, story, look)

You are the game director, lead gameplay engineer, narrative designer and art
director for *The Last Save File*. The repository is
`makedonskivasil3-sketch/The-Last-Save-File`. Work on the branch
`claude/last-save-file-prototype-ljwuq4`.

Your job is to make the first ten minutes **impossible to put down**.

- A new player has to understand who they are and why it matters.
- They have to feel the bond between the two players before it breaks.
- They have to want to know what happens next.
- The game has to look like a modern indie release, not a 1990s prototype.

Deliver working, tested changes and evidence. A plan alone is not the
deliverable.

The author's verdict on the current build, in their words: *"the
introduction to the game is a bit off for the player, I don't see where the
connection is quite built… the two small moving characters need to change,
it's too 90s looking and it may put gamers off right away. We need a strong
story and far better visuals… clearer storytelling, jumping through maps
should come with purpose and missions, to find, discover… the story and the
visuals have leaks… concentrate on the introduction. Maybe the two
characters would do a mission together and one of them just ends up in the
game while the other is off, but done in a much more modern, addictive way.
We need to hook the experience right away."*

---

## 0. Before you change anything

1. **Check the baseline and write down what you find.**
   - Check `git status`, the head commit, `origin/main`, and PR #10. The PR is a draft and must not be merged.
   - Run the full suite (`tests/run.sh`, about 25 minutes) and the bots (`tests/run.sh --bots`).
   - Record the results. The last known state was 643 passed, 0 failed, with the purge-3 bot flaky on the baseline too.
2. **Read these documents.** Treat everything except `RELEASE_READINESS.md` as history, not as the current state.
   - `docs/RELEASE_READINESS.md` (the current state)
   - `docs/REVIEW_OCT24.md` (latest ledger, measurements, open author questions)
   - `docs/STORY_CHRONOLOGY.md`
   - `docs/CANON_DECISIONS.md`
   - `docs/NARRATIVE_CONTRACT.md`
   - `docs/OPENING_REVIEW.md`
   - `docs/STORE_KIT.md`
   - `docs/SAVE_AND_EXIT_PROPOSAL.md`
3. **Play the opening yourself, three ways.** Use `tests/tour_timing_oct24.gd` and the captures from `tests/tour_opening_review.gd`.
   - Watch it with no input.
   - Play it promptly.
   - Skip it.

   Capture stills every 2 s and a 30 fps clip of the first 90 s. These are your "before" evidence.
4. **Keep a ledger.** Use five headings:
   - confirmed defects;
   - source-backed risks;
   - design weaknesses;
   - completed improvements;
   - questions for the author.

   Every claim needs evidence: a file and line, a test, a capture, or a measurement.

---

## 1. What the game is (do not reopen; build on it)

**Canon, decided by the author on 2026-10-22:**
- Two children shared one console.
- Player 1 (the owner) always played **Arin** in slot 1.
- Player 2, a girl, made her own character, **Rue**, in slot 2 and played her for **41 hours**.
- The girl moved away. Months later she sent a message: "still have my save?" The owner never answered and deleted slot 2.
- The game is set **three years later**. Rue is the character her player left running. She is **not** the girl.
- Rue uses she/her.

**Keep all of the following:**
- the five memories;
- the CHARACTER FILE truth reveal, and the truth requirements;
- an ordinary escape that doesn't need the truth;
- all six endings;
- fraying and restoration;
- Pip is never shed;
- the line "the owner doesn't know this slot survived. not yet.";
- Arin is distinct from the owner, and is mute (a pure avatar);
- the well's recordings are distinct from live contact;
- the cast: Mira, Wren, Tobben, the Archivist, Pip.

**The author's new direction fits this canon.** "The two characters do a
mission together and one of them ends up in the game while the other is
off" is exactly the girl's last session: Arin and Rue on a co-op quest; the
girl's controller goes quiet; Rue keeps going. Build the opening on that.

**If a beat would change canon, propose it instead of building it.** Examples:
- Rue *being* the girl;
- the owner being the one who left;
- live contact with the girl before the message ending.

Write these in the questions ledger.

---

## 2. Diagnosis: what is wrong now (verify each point, then fix it)

Measured on `757f172`, from `REVIEW_OCT24.md` and the source. Re-measure each one.

**1. The connection is told, not felt.**
- The opening (`scripts/ui/opening.gd`, about 45 s of film) shows a TV with two tiny figures, two pairs of hands, P1/P2 tags, a save at 87%, a PAUSE walk, a well, a "months later" card and a message.
- The player never shares an *experience* with the other player. There is no shared goal, no teamwork, no joke, no small win together. The "routine" is one shared hop at a save point.
- When the girl stops playing, nothing the player cares about is lost, because nothing was built.

**2. No mission frames the opening.**
- The first objective after the film is "Get out of Arin's room." (`world.gd` around line 1004). It is a generic escape, not a reason.
- Later objectives point at places ("the road east leads somewhere old"), not purposes. Moving between maps feels like corridor-walking.

**3. The film-to-game seam drops the thread.**
- After the film there are eight lines of boot log (33 s at reading pace), then a dark room. What the player just did in the film has no continuation in the room.
- Measured times to agency in the room:

  | Path | Time |
  |---|---|
  | Prompt | 53.5 s |
  | Hesitant | 71.5 s |
  | No input | 93.6 s |

- The first real decision (Mira's request) comes only after that.

**4. The characters look dated.**
- The cast are 21–33 *logical pixels* tall (`scripts/world/illustrated_character.gd`, `BODIES`). They are drawn in code at a 640×360 viewport and stretched 2× (`project.godot`).
- Silhouettes are chibi blobs, with no readable faces in the world, limited poses, and walk cycles of a few frames.
- Next to modern 2D indies (Hyper-HD pixel art, HD-2D, illustrated 2D with skeletal animation), this reads as a 1990s prototype. It is the first thing a player and a store capsule see.

**5. Story leaks.**
- The memories speak as "i" (the girl's voice) before the player knows Rue isn't her.
- The owner, Arin and the girl are easy to conflate.
- "Months later" and "three years later" arrive in fragments.
- Audit every first-hour line against `STORY_CHRONOLOGY.md`. List each leak with file and line before fixing it.

**6. The hook is weak.** Nothing in the first 60 seconds poses a question the player *needs* answered. Nothing gives them a skill they enjoy using, or a promise of what they'll get to do next.

---

## 3. The new introduction (design target; build it)

### Principles
- **Show, play, then tell.** Every story beat in the first 10 minutes is something the player *does* or *sees happen*, never a block of text.
- **Under 10 s from pressing Start to controlling someone.** The first meaningful choice comes in under 3 minutes. Something surprising happens within 60 s.
- **One question at a time,** each answered just as the next one opens. This is the hook.
- **No monologues.** No line is longer than 2 short sentences. No more than 3 lines in a row without player input.
- **Fair and respectful.** No dark patterns, no fake timers, no manipulative monetisation hooks. "Addictive" here means curiosity, mastery and attachment.

### Beat sheet (target lengths; adjust only with evidence)

**A. "Player 2 has joined" (0:00–0:10).**
- A warm, bright, *in-world* scene, not a TV seen from the couch.
- The two avatars, Arin and Rue, stand at the edge of the village square on an afternoon years ago, with a small quest banner: **"The Lantern Festival: light the five lanterns before sundown"** (or a better co-op quest of your design).
- The player controls Rue at once.
- Arin's moves come from scripted "Player 1" input, with a human feel: overshooting, waiting, a celebratory spin.
- A small, unobtrusive HUD tag shows **P1 · ARIN** and **P2 · RUE (you)**.

**B. The mission together (0:10–2:30). A real co-op mini-quest, short and fun.**
- Each lantern needs both players.
  - One holds a switch while the other crosses.
  - One distracts a grumpy NPC while the other sneaks.
  - Both push a cart.
  - Both jump the well-rim gap together.
- This teaches **every core verb** the game later needs: move, interact, hide beside someone, time a crossing, one glitch-like ability framed as a "co-op special".
- **Arin reacts to the player.** He waits if Rue lags, points the way if she's lost, and does a victory emote when she succeeds.
- **The girl's habit** (two light taps, then the press) becomes Rue's signature celebration emote. The player sees it, and it must come back later.
- The village is alive and *full*: Mira at her window, Wren hopping, Tobben's stall open. This is the save as it used to be, the baseline the player will later see decayed.
- Each lantern lit raises a "festival" meter with satisfying feedback: sound, light, particles. This is the first dopamine loop.

**C. The break (2:30–3:00).**
- Four lanterns lit, the fifth across the square.
- Arin's input stops mid-run, and he idles. A system toast reads **"PLAYER 1 HAS LEFT THE SESSION"**. Rue's player input still works.
- The player can light the fifth lantern **alone**. That is the first decision, and the first act Rue does that nobody asked for.
- Then **"PLAYER 2 HAS LEFT THE SESSION"**. The controller prompt fades, but **the player keeps control**. That is the shock.
- *Keep the canon nuance.* The owner leaving first is the night-of-the-move version (the girl was still holding the controller). The girl then stops playing, moves away, and never returns. Decide the order with the author if it matters (ledger). The point is that Rue keeps moving after both players are gone.

**D. Time passes (3:00–3:30).** A 20-second, skippable time-lapse in the same square, playable or semi-playable.
- The sun sets, the festival decorations fade.
- Seasons cycle and NPCs loop their scripted idles, emptier each time.
- Text appears only as **in-world artefacts**:
  - the board's notice changes;
  - a message bubble on the TV layer reads "still have my save?" with an unanswered typing indicator that stops;
  - **"SLOT 2 · DELETED"** stamps across the sky like a system dialog;
  - **"3 YEARS LATER"**.
- Rue stands where the fifth lantern was. The lantern she lit is the only light that never went out. That is the visual through-line.

**E. The load (3:30–4:00).**
- The world snaps to the present: colder, glitchier, half-unloaded.
- The owner loads slot 1, and the boot log becomes **short, diegetic HUD**: `LOADING SLOT 1 · ARIN` … `1 UNRECOGNISED ENTITY`.
- Arin, now owner-driven, turns and **sees Rue**. The owner's first line appears: `> ...who's in my save?`
- The chase/escape tutorial starts here, using exactly the verbs taught in B.

**F. The first mission of the present (4:00–10:00).**
- Replace "Get out of Arin's room" with a **named mission that continues the festival**: *"The fifth lantern is still lit. Find out who kept it burning."* (Or *"Find your way back to Slot 2"* if the author prefers. Ledger it.)
- Arin's room, the seam and Mira become the first mission step, not an aimless escape.
- Mira remembers the festival: "You lit the last one. Nobody else came." That is the connection.

### Missions across maps (purpose for every transition)
Design a **quest log**: a short list, always one active, in the journal and on the HUD as one line. Every map transition is a mission step with a reason, a place and a reward.

| Mission | Why the player goes there | What they find | What it unlocks |
|---|---|---|---|
| Light | The lantern that never went out (Square) | The well underneath | Out of Bounds, and Pip |
| Who | Who kept it burning (the Archive) | The CHARACTER FILE stub, the pointer | The north road |
| Where | What's left of Slot 2 (the Edge) | Memories | The choice |

These are examples. Design the full set covering all seven maps, and keep the five memories, the truth gates and all six endings. Each step must:
- name the destination *and* the reason;
- teach or test one verb;
- end on a reveal or a character beat;
- be written into `STORY_CHRONOLOGY.md` (who knows what, when).

The existing objectives system (`World._update_objective`, `Hud.show_objective`) should become this quest system, migrated without breaking old saves.

---

## 4. Visual overhaul (characters first, then the opening's spaces)

**Target:** modern 2D, readable at a glance in a store capsule. Pick one direction, justify it, and show style frames before mass production:
1. **Hi-bit pixel art.** Characters about 48–64 px tall at a 640×360 base, or about 96–128 px at 1280×720. Expressive 8-direction or 4-direction animation with anticipation, follow-through and secondary motion (scarf, hair). Dynamic 2D lighting with normal maps.
2. **Illustrated 2D with skeletal animation.** Godot `Skeleton2D`/`Polygon2D` or cut-out rigs at 1280×720, soft shading, painterly backgrounds.

**Requirements:**
- **Characters.** Rue, Arin, Mira, Wren, Tobben, the Archivist and Pip, each with:
  - a distinct silhouette that reads in black fill;
  - a readable face, with at least neutral, happy, afraid, determined and sad;
  - idle, walk, run, interact, hide/crouch, emote (Rue's two-tap habit), hurt/erase, and talk;
  - turn and start/stop transitions.

  Rue additionally needs her **missing-texture → restored** states, which drive the five-memory restoration as visible costume pieces. She also needs a **"left running"** look: slightly desaturated, with a subtle glitch shimmer that is never hard to read.
- **Opening spaces.** The festival square ("then", warm), the same square ("now", cold, half-unloaded), and Arin's room. Use layered parallax and light, and give both time states.
- **The UI:** quest line, P1/P2 tags, the session toasts, the time-lapse artefacts, and the "you" cue. All of it must be readable at maximum text size and near touch controls.
- **Rendering.** Stay on **Godot 4.3, Compatibility renderer**, with the web export working. If a higher base resolution or rendering mode is needed, measure frame time before and after (see §7) and keep collision and gameplay tuning in logical units.
- **Pipeline.** Build an asset pipeline: sprite sheets or rigs imported from `assets/characters/<who>/`, with metadata. It must **fall back automatically** to the current procedural `IllustratedCharacter` when an asset is missing, so the game never breaks. Keep `CharacterArt`/`PortraitResolver` as the single source of truth.
- **Rights and money.** Do **not** purchase assets, use unlicensed art, spend generation credits, or ship AI-generated art as final without the author's explicit approval.
  - You *may* produce in-repo procedural or hand-authored art, clearly-labelled placeholders, and **style frames and a character art bible** (`docs/ART_BIBLE.md`, with proportions, palettes, line, light, a turnaround sheet per character, and an animation list with frame counts) that an artist could execute.
  - If the procedural route can't reach the target quality, say so plainly and present the commission brief and cost structure. Do not fake it.
- **Captures.** Before/after stills of the cast sheet, the opening's six key frames, and the room and square at a typical gameplay moment, plus a 30 fps motion clip of Rue walk, run, stop, turn, emote, and the session-leaves moment.

---

## 5. Story clarity (fix the leaks)

- **Voices are separate and visibly distinguished:** the girl (memories, the message), Rue (thoughts), the owner (`>` console), Arin (mute), and the system (toasts).
  - Decide how the memories' "i" reads: for example, framed as **recorded play sessions** ("REPLAY · 41:07:12 · P2") until the CHARACTER FILE reframes them.
  - Fix any line that implies Rue *is* the girl before the reveal.
- **Make the timeline explicit in play:** the festival is "then", the break is "the night she moved", then the message "months later", then "3 years later", now.
- **Every new or changed line** gets a voice-manifest entry (`tools/voice_manifest.gd`), a journal/fact entry where it teaches something (`ArchivePages`, learned at reveal), and a row in `STORY_CHRONOLOGY.md`.
- **The festival must pay off later.** Each NPC remembers it differently (Mira, Wren and Tobben each get one line). At the end, the fifth lantern reappears at Slot 2, and the message ending can mention it.

---

## 6. Hook and retention (ethical)

- **The first 60 s:**
  - controlled play under 10 s;
  - a co-op success under 45 s;
  - a surprise (the player leaving) by about 2:30.

  Measure these, don't assert them.
- **Curiosity loop.** Each mission ends with a new question: who kept the lantern lit? why did slot 2 survive? what's under the well?
- **Mastery loop.** The verbs from the festival return under pressure in the present.
- **Attachment loop.** NPCs remember the festival and react to what Rue did then *and* now.
- **Session end.** Every natural stopping point (an area exit, a memory) shows the next mission line, so the player knows why to come back. No nagging, no fake urgency, no punishing breaks.
- **Skippability.** The co-op prologue can be skipped after the first lantern (hold to skip), and the time-lapse is always skippable. Replays from the title are shortened but keep the playable parts.

---

## 7. Constraints (non-negotiable)

**Git and the PR**
- Godot 4.3 Compatibility, GDScript, with web, Linux and Windows exports working.
- Never merge PR #10, never force-push, and push only to the branch above.
- Commit messages end with:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01SRRn3kLdYJgU2zsAFTY9Cn
  ```
- PR bodies end with:
  ```
  🤖 Generated with [Claude Code](https://claude.com/claude-code)

  https://claude.ai/code/session_01SRRn3kLdYJgU2zsAFTY9Cn
  ```
- No model IDs anywhere in repository artifacts.

**Saves, tests and existing behaviour**
- Saves migrate: older saves must load. Skip the new prologue for profiles that have already started, and offer it from the title as "the festival".
- Do not delete or weaken tests. Every bug gets a regression test that fails first. Every new mechanic gets tests: the prologue state machine, the session-leave beats, skip and replay, the quest log, save migration, and accessibility.
- Keep, and do not re-implement, the existing work:
  - input ownership (focus vs controller holds, active pad);
  - caption and voice continuity;
  - the protection policy (cards hold threats);
  - the floor warning;
  - the Bin shelter;
  - independent RNG;
  - the line milestones (facts at reveal);
  - in-view observation;
  - Tobben's single report.
- Investigate warnings, don't suppress them.

**Accessibility**
- Maximum text and subtitle size.
- Reduced flashing and reduced motion. The time-lapse needs a static alternative.
- Muted audio: every beat must read without sound.
- Touch controls.
- Remappable keys.
- Colour-blind-safe P1/P2 distinction, using shape as well as colour.

**Honesty**
- Don't publish anything (no store page, no public release).
- Don't purchase anything, and don't spend service credits or clone voices.
- Don't claim listening tests or playtests that didn't happen.
- If no unfamiliar players are available, ship the protocol and instrumentation and say so.
- No invented metrics, awards, quotes, forecasts or playtime.
- Don't silently add checkpoints, free suspension or difficulty cuts.

---

## 8. Deliverables and order of work (one commit group each, tested and pushed)

1. **Audit and design.**
   - The ledger.
   - A one-page intro design: the beat sheet with timings, the verbs taught, and the questions posed and answered.
   - The quest/mission map for all seven areas.
   - Style frames with the chosen visual direction and the reason for it.
   - `docs/ART_BIBLE.md`.
   - Author questions, kept separate.
2. **The playable festival prologue** (beats A–E) with the co-op mini-quest, Arin's scripted-human P1 input, the session-leave beats, the time-lapse and the hand-off. Includes tests and "before/after" timing (`tour_timing_*`).
3. **The quest system** replacing generic objectives, with mission lines for the first hour, and NPC festival callbacks. Includes tests and save migration.
4. **The character visual upgrade:** the pipeline with fallback, and Rue and Arin first at full quality (the two players), then Mira, Wren and Pip. Includes cast sheets, motion clips and a performance comparison.
5. **The story leak fixes** across the first hour, with an updated `STORY_CHRONOLOGY.md` and voice manifest.
6. **Verification and report.**
   - The full suite and all ending bots, with deaths, stalls and retries recorded honestly, and an A/B against the baseline for anything flaky.
   - Exports, the Linux smoke test, the web check (zero console errors), and the benchmark (CPU frame time; no GPU claims on software renderers).
   - Fresh-profile runs: watched, prompt, hesitant, no-input and skip.
   - Accessibility captures.
   - An unfamiliar-player protocol for the new intro, focused on "who am I", "who was the other player", "what happened", and "do you want to keep playing, and why".
   - Update `RELEASE_READINESS.md` (current section) and the PR #10 description.

## 9. Acceptance criteria (state each one as met or not met, with evidence)

- Controlled play in **≤ 10 s** from Start on a fresh profile (prompt path).
- The co-op success, the P1 leave, the P2 leave and the "3 years later" beat all happen in **≤ 4 minutes** on the prompt path. A skip reaches the present in **≤ 15 s**.
- A first meaningful choice in **≤ 3 minutes**.
- Every map transition in the first hour has a named mission with a reason.
- No first-hour line contradicts `STORY_CHRONOLOGY.md`. The voices are distinguishable without colour.
- Rue and Arin are re-drawn or re-rigged at the new quality bar, with a fallback that never breaks the game. Every character has at least idle, walk, interact, emote and talk.
- No frame-time regression beyond 10% on the benchmark's opening and square workloads, or a measured and justified exception.
- Suite green. Bots no worse than baseline (A/B). Exports and the web check green. Old saves load.
- A final report with:
  - the revision;
  - what changed;
  - before/after captures;
  - measurements;
  - risks;
  - asset status (placeholder vs final; rights);
  - every unresolved author decision, as a short numbered list with a recommendation each.
