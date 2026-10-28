# Vertical slice: the first route, made playable and testable

Branch: `claude/last-save-file-prototype-ljwuq4` (PR #10, draft). It is the
designated branch for this work and is separate from `main`; nothing is
merged. The canon here was the **proposed** contract at the time;
the decided canon is `CANON_DECISIONS.md` §1 (history document).

The experience this slice must deliver:
> "I entered someone else's saved world. The people inside are slowly
> losing themselves. They remember what I do. I may be able to escape, but
> leaving them behind now means something."

## 1. Starting point (verified 2026-10-22)

- **Hashes.** `origin/main` = `09aeb3b`. The review branch is `d8e868b`,
  36 commits ahead of `main`, with `main` as its ancestor. No other branch
  is ahead of `main`.
- **CI.** Green on `537df8c` (the code head) and `d8e868b` (documents).
- **Last local verification.** 547/547 strict suite on `537df8c`; 5/5
  ending bots; three exports; both browser checks.
- **Read for this audit:**
  - the release readiness, coherence, continuity and narrative contract
    documents;
  - the narrative bible (superseded in part), story script, caption and
    voice contract, art direction and map design.
- **Code inspected:** `opening.gd`, `title.gd`/`title_art.gd`,
  `world.gd` (transitions, sessions, anchor), `npc.gd`/`relationships.gd`,
  `archive_pages.gd`/`journal_panel.gd`, `owner_memory.gd`, `sfx.gd`,
  `village_square.gd`, `area.gd`, `hud.gd` (prompt placement), and the
  endings in `story.gd`.

## 2. Audit

### 2.1 Confirmed defects (each checked in the code or reproduced)

| # | Defect | Evidence |
|---|---|---|
| D1 | **Closing the game during the boot text counts as quitting** (purge +1), before the player has controlled anything. | `OwnerMemory.begin_session()` sets `last_exit = "active"` and opens the session at `World._ready`. The boot text plays after that, so `record_quit()` (window close) and crash detection apply from the first frame. Reproduced by `test_vertical_slice` (first version, failing). **Fixed:** the World's session is deferred (`begin_session(true)`) and armed when Rue is first controllable; an unarmed quit or crash is undone. |
| D2 | **A controller disconnecting mid-opening or mid-run is not handled.** No pause, and no message. | No `joy_connection_changed` handler anywhere in `scripts/`. **Fixed:** losing the pad in use opens the pause menu (`World.controller_lost`); the opening already holds on focus loss. Untested on real hardware. |
| D3 | **The pause map, the HUD clamp and the Owner's nav fallback assume one 640×360 screen.** | `hud.gd:1185,1198`; `owner_avatar.gd:333`; `area.gd:205` (`BACKDROP_SIZE`). |
| D4 | **The Archivist chooses his lines outside the shared selector.** He has no familiar greeting route and no witnessing rule. | `archive.gd` `_archivist_lines` (documented in `COHERENCE_MILESTONE.md` §5). |

### 2.2 Design weaknesses supported by observable behaviour

| # | Weakness | What is observable |
|---|---|---|
| W1 | **The opening is watched, not played.** For 45 s the only input is "hold to skip". The habit (two taps) is shown, not performed. | `opening.gd`: all events are on a timer. |
| W2 | **The title is one flat plane** at a fixed distance, with nothing in front of or behind the figure. | `title_art.gd` draws wall, floor, TV and Rue on one plane. |
| W3 | **The Square is a single screen.** Its exits are a few steps from the centre, so there is no route choice: the Archive is always the same 30-step walk past Arin. | `VillageSquare.bounds = Rect2(40,36,560,256)`. |
| W4 | **Nobody notices that Rue came back.** Waking at the kept place gives one line of Rue's own; the first person she meets after a death reacts only if they saw it. | `world.gd` `ANCHOR_NOTE`; `Relationships.wren`. |
| W5 | **A boot text of seven system lines** is the first thing after the opening: consecutive explanation panels. | `Story.BOOT`, `world.gd` `_begin_session`. |
| W6 | **There are no Save and Exit or Continue semantics.** Quitting is always punished, and the menu says so. This is honest, but it is a commercial risk: a player who stops for dinner pays purge. | `pause_menu.gd` `_ask_quit`. |

### 2.3 Proposed improvements (this slice implements the first five)

1. **An interactive opening** (§4): the player performs the ritual, sees
   it fail, and makes the impossible move.
2. **A layered, dimensional title** with bounded parallax and a
   reduced-motion mode.
3. **A bounded camera, and a Square half again as wide**, with purposeful
   subspaces and a shortcut that is earned.
4. **A character-focused checkpoint scene:** someone notices that Rue
   came back.
5. **Sessions start counting when play starts**, not at the boot text
   (D1); a controller disconnect holds the game (D2).
6. Proposed only: Save and Exit / Continue (§6).
7. Proposed only: a shorter boot text (W5). It is kept for now; its lines
   are canon the author approved.

### 2.4 Already implemented (kept, not redone)

- Persistent encounters and ordered relationship events (v3).
- One selection path, with Wren, Mira and Tobben arcs.
- The six-section archive with SEEN / SAID / RUE / UNKNOWN.
- The map's four states.
- The kept place under the well (opt-in, earned by the tune).
- The well's honest evidence.
- Caption pages over a single take; manual advance; text speed, including
  instant; subtitle size and background; history replay; the speech-rate
  setting.
- Audio unlock and recovery, without a visible badge.
- Exact-ending bots and the browser checks.

### 2.5 Claims that need human playtesting

None of the following is claimed. Each needs unfamiliar players (§7):
- whether the first objective is understood;
- whether the opening's anomaly reads without narration;
- whether players care about Mira, Wren or Tobben;
- whether the kept place is understood;
- whether players want to continue after the demo;
- what value they perceive.

## 3. The milestone route and its experience specification

Title → interactive opening → first relationship (Mira) → first threat
(the owner's attention in the room, then Arin's cone in the Square) →
Square exploration → first recovery anchor (the place under the well) →
meaningful discovery (the well's words; a memory) → continuation hook.

Timings are provisional targets. They are measured in play only where
noted.

| Stage | Knows | Wants | Fears | Can do | What changes | Why continue |
|---|---|---|---|---|---|---|
| Title (any) | A girl, a TV, a save that never finished | To see what this is | — | Load Slot 1 | — | The figure's eyes are two points of light |
| Opening A, the ritual (~15 s) | Two people play together | To finish the evening together | — | Walk Rue beside Arin; press to save (her two taps happen) | The save starts | It feels like a memory |
| Opening B, the interruption (~10 s) | Player 1 left; the save stuck at 87% | For it to finish | That it won't | Press again: the familiar action fails | The sound thins; her hands go slack | She can still move. Why? |
| Opening C, the impossible action (~10–25 s) | Everything is paused except her | To follow the sound | Being alone in a paused game | Walk to the well at the picture's edge; look out | She turns to the real room | Something outside can see her |
| Opening D, the handoff (~6 s) | Months later her message came; the reply stopped | — | — | (skippable) | The room fades in, at the same angle | Her first move in the room is the player's |
| Room (1–4 min) | Someone else's save; a note; Mira | To get out | The owner's attention (the bar) | Read, talk, find a memory, glitch | Mira is met; a memory is recovered; the wall tears | "Find Wren in the square." |
| Square (3–6 min) | A village; Arin's cone; a well that clicks | To find a way on | Arin seeing her | Hide by Wren, cross or take the lane, listen at the well | Wren is met; the well clicks with **her** gesture | The well is deeper than it should be |
| Under the well (2–4 min) | The tune, one note short | To understand | Falling | Cross the floor; take THE WELL; keep her place | The anchor is set; Pip | If taken, she wakes here |
| A death, then the return (≤1 min) | She came back | To know what's left | Losing people | Climb up | **Wren noticed** (§5); her place by the crates | Someone is waiting for her |
| Hook | The Archive is east; "still have my save?" | To find out who asked | The owner learning her | Go east, or to the Edge with Wren | — | Who is she? |

### 3a. The interactive opening as built (`scripts/ui/opening.gd`)

Film time (`_t`, 45 s of picture) runs between states and **holds** at each
one until it is done. Nothing is lost by waiting, and nothing is punished:
no run exists yet (D1).

| State | Holds at | Done when | Hint (after 5 s idle) | If nobody acts | What the player sees |
|---|---|---|---|---|---|
| RITUAL | 5.0 s | A press within 14 px of the save point | "walk to the save point with Arin, then press" | After 16 s idle, she walks there and presses | Her thumb taps twice, then presses (any press, anywhere: her habit) |
| INTERRUPT | 10.8 s (bar at 87%) | One press after the stall | "press E" (or "tap") | After 8 s, she presses | Two taps and a press, then a refusal sound; the bar doesn't move. P1's hands leave; hers go slack |
| IMPOSSIBLE | 23.0 s (PAUSE) | Rue reaches the well | "walk" | After 16 s idle, she walks there herself | Arin is frozen. Her hands are slack and still, and she still walks. Caption "[she keeps walking.]" on the first step |
| LATER | — | (film) | — | — | Her message, then the owner's unfinished reply |
| HANDOFF | 45 s, or a skip | Skip inputs released | — | — | The room; the player's first move |

**Input.** Keys and stick walk her and interact presses. A tap or click on
the picture walks her there, or presses at the save point or during the
stall. Interact released within 0.3 s **acts**; held 0.7 s it **skips**; a
hold never also presses (tested). Esc, pause or a mouse hold also skip.
A press already down when the film starts must be released first.

**Holds.**
- Losing focus holds the film, its music and any skip in progress.
- If the pad in use disconnects, the film holds with "controller
  disconnected: reconnect it, or press any key", and resumes when the pad
  reconnects or another input is used.
- During any hold, the autopilot clocks stop.

**Reduced motion or flashing.** No camera push, no flicker on the stuck
bar, and the save point doesn't pulse.

**Essential versus optional.**
- Essential: the hints, which say only what to do and never name anyone or
  explain.
- Optional: the captions, which describe sounds.

**Timing.** With prompt input, the full film now takes about 45 s plus the
player's walks (about 6 s each way). If the player never touches anything,
it takes about 45 + 16 + 8 + 16 s. Both figures are measured in tests with
simulated input, not with players.

**Not yet verified.** Whether players understand that the hands under PAUSE
are not theirs while the figure still answers them. This needs a playtest
(§2.5).

### 3b. The dimensional title as built (`scripts/fx/title_art.gd`)

The room is now staged in four depth layers:

1. **The wall:** a window, a shelf, and the screen's glow.
2. **The set:**
   - the television on its cabinet against the wall;
   - the cabinet's floor shadow and the screen's reflection in the boards;
   - a light cone that widens across a floor whose boards run to a
     vanishing point.
3. **Her:**
   - Rue, rim-lit on the side facing the screen;
   - a contact shadow at her feet;
   - a cast shadow thrown along the floor, away from the light on it.
4. **Near:** out-of-focus silhouettes whose edges facing the screen are
   lit:
   - the roll of an armchair arm;
   - the second controller dropped on the floor, its taped cable running
     out of frame. This is the object the opening's hands held.

**Depth and parallax.**
- A slow, uneven drift moves each layer in proportion to its depth: the
  nearest layer by at most `PARALLAX` = 4 px, the wall by 0.5 px.
- No input is needed and the mouse plays no part.
- The menu is a separate layer and never moves (tested).
- Reduce motion (a new setting under COMFORT) removes the drift and dust
  travel, and also the opening's camera push.

**Why no 3D SubViewport.** One CanvasItem pass already gives floor contact,
a coherent light and layered depth, so 3D was not needed. (The frame time
of this pass has not been measured on a low-end device: §2.5.)

**Evidence** (in `docs/review/slice/`):
- `title_before.png` and `title_after.png`;
- `title_reduced_motion.png`;
- `title_motion.gif`: 6 s of the drift, rendered in-engine frame by frame
  at 10 fps through `tests/tour_title.gd`. It is a frame sequence, not a
  real-time screen recording.

### 3c. The wider Square as built (`village_square.gd`, `owner_lamp.gd`, `lane_gate.gd`)

The Square is now 880 × 256 (it was 560 × 256), painted on a 960 × 360
backdrop. The camera follows Rue across it.

**Prerequisites, done first**

| Prerequisite | How | Test |
|---|---|---|
| Bounded camera | `World.update_camera`: a 60 px dead zone; an ease inside `[0, view_size.x − 640]`; snapped on arrival | `test_the_square_camera_follows_within_its_limits` |
| Camera-relative prompts | `Hud` already projects the prompt through `canvas_transform`, which is now the camera | `test_a_prompt_follows_the_camera` |
| Collision, navigation and the Owner across the new bounds | The nav grid, erasure grid and cursor bounds come from `bounds` | `test_arin_and_the_cursor_can_cross_the_whole_square` |
| Background art reworked, not stretched | `_paint_east` paints new ground; the backdrop bakes at `view_size` | `tour_square` stills |
| Threats never hidden by the camera | An off-screen arrow at the screen edge for Arin or the cursor, with the name in text (`ART_DIRECTION.md`) | `tour_square` sq8 |
| Spatial audio | 2D players are placed relative to the canvas transform, so they follow the camera. Existing reach (300–360 px) is kept | Not heard by a person |
| HUD and touch | Both are screen-space and unchanged | Existing suites |
| Reduced-motion camera | Cuts between two framings; no panning | `test_reduced_motion_cuts_instead_of_panning` |

**Subspaces**

| Place | Identity | What it's for |
|---|---|---|
| Arrival (west, unchanged) | Arin's door, the well, Wren, Tobben's stall | The first relationship and the well |
| Exposed crossing (x 600–790) | Wide, open cobbles with nothing to stand behind | **The lamp**: the owner's eye on a post. It sweeps a fixed arc, holds and ticks before each turn, and adds attention after a short grace. It is a variation on Arin's cone: it never moves, so it can be timed |
| Sheltered recess | A covered bench on the crossing's south side | A hiding place (`hides_player`, "the awning hides you") mid-crossing, out of the beam's reach |
| The Archive's front (landmark) | Pale stone, tall windows, a rose window, and an arch over the road out east | Visible from the crossing: where the road goes |
| Earned shortcut | A fenced lane behind Tobben's, with a gate latched on the lane side | Walk the lane once and lift the latch. It stays open (`OwnerMemory.square_gate_open`), giving a sheltered way between the old square and the Archive road |

**Balance**
- The lamp is a warning more than a hunter: its grace is 0.6 s (Arin's is
  0.35 s), and its rate is 6 per second, about a quarter of Arin's 22.
- With the first tuning, at 0.8 of Arin's rate, the walk from the Archive
  back to the north road added about 30 owner attention on the bots' route.
  Before the wider Square it added about 16. The purge-5 bot was purged at
  the Edge in CI run 127.
- After retuning, the same walk adds 15–21 attention, measured across five
  bot runs.

**Return trips reveal change**
- The gate stays open.
- The owner turns the lamp's arc to cover the gate mouth: the shortcut is
  remembered by both sides.
- (Wren's ribbon, §5a, is the other change visible on the way back.)

**Each exit has a coherent arrival**
- From the Archive, Rue arrives under the arch, already framed east.
- From the house and the well, the old square is framed.

**Not changed**
- Arin's route, his speed, and every glitch price.
- The north road and its condition.
- The well and its sequence.
- The relative position of every west-side placement.

**Not verified**
- How the lamp's timing feels.
- Whether the shortcut is found without a hint.
- Spatial audio across the pan.

All three need a playtest and a listening pass (§2.5).

## 4. Revelation table (the primary reveal: the proposed canon)

| | |
|---|---|
| **Underlying truth** | *(Corrected 2026-10-28: this row stated the rejected draft premise.)* Rue is the game character left running after her player moved away (`CANON_DECISIONS.md` §1). |
| **Mira believes** | Rue is "the other one, who used to sit next to them". True, though she can't know why. |
| **Wren believes** | Rue is a ghost of someone who played; nobody plays either of them. Half true. |
| **Tobben believes** | The name RUE is just a name that went out of his book. |
| **The owner believes** | "You're not her": something is wearing her walk. Denial. |
| **The player has observed** | The two taps before a press, which they performed in the opening; the save stuck at 87%; Rue moving with nobody's hands on her; the well's click with the same two taps. |
| **Early clues (three channels)** | (1) **A bodily habit:** her two taps, performed in the opening, heard again at the well, and noticed by Mira ("your hands hold something that isn't there"). (2) **A character remembering outside their script:** Tobben's guest book had two names; Mira "remembers the dark in between". (3) **A document separating the costume from the occupant:** the CHARACTER FILE, "costume rebuilt from…; player: still in session". |
| **Plausible first readings** | She is a glitch; a copy of the player; a ghost of a deleted character. |
| **Resolving evidence** | The file read whole; her memories are told from the second player's seat; the habit the player performed is hers. |
| **The playable recognition** | Proposed, implemented in part: at the well, the click repeats the two taps the player made in the opening. The full reveal needs the player to perform the gesture in front of the file. This is listed as the next milestone, not claimed. |
| **The decision it unlocks** | RUE at Slot 2 (write herself in, knowing who she is). The message ending tells the girl where the rest of her is. Leaving now means leaving people who remember her. |

The rules are unchanged:
- **The well keeps recordings; it is not live contact.** Live contact
  would need a present-time response that a recording could not produce.
- **No extra twist** may undo relationships.

## 5. Characters: distinct emotional functions

| | Desire | Ordinary habit | Limitation / fear | Imperfect trait | Offers Rue | Needs from Rue | Trust action | Changed interaction |
|---|---|---|---|---|---|---|---|---|
| **Mira** | To be more than a line; to leave the room | Sets out two cups (one forgotten) | Locked in the room; the blank smile (reset) | Talks too much when nervous; a little bossy | The first welcome; warnings; "find Wren" | To be taken outside; to be believed | Walking her to the board | Whispers past the owner's lock; remembers the death she saw |
| **Wren** | To see the Edge | Tugs her ribbon; stands by the crates | Being cut again; being left | Blunt; teases ("you smell like the bin") | Shelter from Arin's eyes; the way | A promise kept | Standing beside her while Arin passes | **Notices that Rue came back** (§5a); half-remembers a broken promise |
| **Tobben** | Order; his guest book whole | Counts under his breath; shop patter | His script makes him report her | Cheerful to the point of being annoying; guilty | A name; the guest book | Her name written back | Writing RUE back | Reports less; jokes about her "tab" |

### 5a. The checkpoint scene implemented in this slice

**When it plays**
- Rue wakes at her kept place, under the well, and climbs back into the
  Square.
- Wren has been met, wasn't deleted, and isn't escorting.
- The code condition: `arrival == "well"`, `World.woke_at_anchor`,
  `wren.met`, and not yet `wren.marked_well`.

**What happens**
- Wren is waiting at the well's rim instead of her corner, close enough
  that she speaks first as Rue arrives.
- She has chalked a mark on the rim: a round head with two dots for eyes
  ("I'm not good at hands, so you haven't got any") and an arrow up,
  "so you'd find your way up". Then a joke at Arin's expense.
- If she saw Rue taken, the scene opens with that ("I saw them take you…
  the well's where you went before"). It then counts as their reunion, so
  the crates speech isn't repeated.
- (It is a chalk mark, not a ribbon, so it isn't confused with her ribbon,
  which is a piece Rue can take.)

**Protection**
- The owner holds while the conversation is open. This is the existing
  reading hold, which also holds Arin and the lamp (tested).

**How it commits**
- `wren.marked_well` (and `wren.reunited`, if she saw the death) is
  written only when the exchange is read whole: `Relationships._once`,
  committed in `World._on_dialogue_closed`.
- Cut short (walked off, or something cut in), it plays again when Rue
  talks to her.
- Once read, it never replays: the next return finds her back in her
  corner.

**Reachable later**
- The words go into the journal ("WREN, AT THE WELL") as the scene starts,
  so a scene cut short can still be re-read from the pause menu.
- The People page lists "Wren chalked a mark on the well's rim…".

**What persists**
- The chalk stays on the rim in every later run.

**Evidence**
- Tests: `test_wren_waits_at_the_well_with_a_mark`,
  `test_cut_short_it_plays_again_and_never_twice_once_read`,
  `test_when_she_saw_rue_taken_the_scene_is_the_reunion`.
- Stills: `docs/review/slice/cp1_wren_at_the_well.png`,
  `cp2_the_chalk_stays.png`.

## 6. Save behaviour: what survives, and a proposal

**What survives today:**

| Event | What survives | What is lost | Where the next run starts |
|---|---|---|---|
| Death | everything lasting (A), world consequences (B), the kept place (C) | the attempt (T); purge +1 | the kept place if set, else Arin's room |
| Retry (after the death card) | same as death | same | same |
| Quit (pause menu) | A, B, C | the attempt; purge +1 (the menu warns) | Arin's room |
| Application closed mid-run | A, B, C | the attempt; purge +1, counted on the next launch | Arin's room |
| Crash | same as closed | same | Arin's room |
| Before play starts (opening, boot text) | everything (**fixed in this slice**, D1) | nothing | as before |
| Ending | A; some B (a message ending clears purge and fates) | the kept place (an ending is a new start) | Arin's room |

New lasting state in this slice is all category A: it survives death, quit,
crash and endings, and only Reset clears it.
- `square_gate_open`: the lane shortcut.
- `wren.marked_well`: the chalk on the rim.
- The journal entry "WREN, AT THE WELL".

The kept place is a **place**, not a snapshot. Position, items, an escort
and the owner's awareness are not saved.

**Commercial proposal (not implemented; the author decides):**
- **Save and Exit** (the pause menu): end the session without purge.
  Resuming continues where the player was (the kept place, else the room),
  with a short "you were away" line from the owner.
- **The story action stays separate.** A deliberate in-world "leave the
  save" (glitching out of the game) keeps today's purge. It is the
  diegetic quit, and it is clearly labelled as one.
- **Closing the window** counts as Save and Exit, not as running away.
- Purge from deaths is unchanged.

## 7. Verification (2026-10-22)

These results were run locally in a Linux container (Godot 4.3, llvmpipe
or SwiftShader).

| Check | Command | Revision | Result |
|---|---|---|---|
| Strict full suite | `GODOT=… tests/run.sh` | `a43a072` (game code identical to `bd73368`) | **567/567**, exit 0 (1276 s) |
| Ending bots, fresh profile each | `tests/run.sh --bots --speed=3` | `bd73368`, and again after the lamp retune | **5/5 exact endings** both times. After the retune, the purge-5 bot reached its ending with no deaths |
| Exports | `--export-release` Web / Windows Desktop / Linux | `bd73368` | All exit 0. The Linux binary runs 300 frames under xvfb |
| Headless Chromium page check | `tests/web/web_check.cjs` | `bd73368` | All pass. Rue moves on real keys; a tab closed mid-run counts as a quit; no page errors |
| Headless Chromium audio check | `tests/web/audio_output_check.cjs` | `bd73368` | Audible after a gesture; no visible badge |
| Captures | `tests/tour_opening.gd`, `tour_title.gd`, `tour_square.gd` | `bd73368` | `docs/review/slice/` |

**CI history on this branch, kept visible**
- Runs 121, 123 and 124 failed in the bot step only; their unit suites
  passed.
- Run 121, at `958ade8`: the message bot stalled south of the well after
  an owner reload. Its suite passed 556/556.
- Runs 123 and 124: every bot still aimed for the old east edge (x = 640),
  which is now inside the Square.
- Both are fixed in `bd73368`, which points the bots past the new edge and
  replans the north road after a reload.
- Run 127, at `4425779`: the purge-5 bot was purged at the Edge. The cause
  was the lamp's first tuning (see §3c, Balance), which is now retuned.

**Kept visible: warnings**
- "ObjectDB instances leaked at exit" and "resources still in use at
  exit". They were already present at `537df8c` and are unchanged.

**Not verified**
- Windows gameplay. An export is not a playtest, and no Windows machine
  was available.
- Real controllers, including connecting or disconnecting one (simulated
  only).
- Touch on a phone, and a real GPU.
- Human listening, and unfamiliar players. No playtest results are
  claimed.

**Motion evidence**
- `title_motion.gif` is an in-engine frame sequence, not a screen
  recording.
- The opening and the Square are evidenced by stills and tests only.
- Animation quality has not been judged by a person.

## 8. Creative decisions for the author

1. Does the playable Rue reveal (§4) become canon?
2. Are the opening's hands the player's own under PAUSE? The slice implies
   it.
3. Save and Exit / Continue (§6).
4. The demo endpoint (`COMMERCIAL_DIRECTION.md` §4).
5. Human or generated voice for the auditions (`VOICE_AUDITION.md` §4).
6. Whether the lamp's widening after the gate opens is too punishing.

## 9. Next milestone

1. **The playable recognition.** Rue's two-tap gesture in front of the
   CHARACTER FILE.
2. **The Archive's treatment, as the Square got.** Subspaces, returns that
   reveal change, and the camera.
3. **One unfamiliar-player round** on Windows (`COMMERCIAL_DIRECTION.md`
   §8), then fixes from it.
4. **Voice auditions**, with human listening before any production.
