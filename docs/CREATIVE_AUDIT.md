# Creative audit: The Last Save File

> **Historical record.** This audit describes an earlier build. For the current state, see `RELEASE_READINESS.md` (status and validation) and `COHESION_PASS.md` (what was verified, fixed and deferred most recently). Findings marked fixed there supersede the ones here.

This audit looks at the game as a first-time player, a horror critic, a technical artist and a potential customer would. It was written on 2026-10-16 at commit `c7f0ff8`.

The evidence comes from four sources:
- **Screenshots** from the visual tour (`tests/tour_visual.gd`, run with `--tour`; see §F), taken at 1280×720 under xvfb.
- **The code**, cited by path.
- **`docs/NARRATIVE_BIBLE.md`**, which records the canon and its contradictions.
- **`docs/AUDIT.md`**, the earlier technical audit.

Two limits apply throughout. Nothing here comes from a human play session, and no audio was listened to: the sound comments come from reading the code. Every score is an internal heuristic, not market research.

---

## A. First session (first launch → first threat → first consequence)

| Beat | What actually happens (tour shots `00`, `02`, `03a`–`03d`) | Verdict |
|---|---|---|
| First image | The title card is a plain dark panel with an amber title. The tagline "you are not supposed to be here." is in the owner's red. The save card reads `SLOT 1 · ARIN · LV 7 · 14:22:00`. | Clean and legible, but generic. Apart from the save card it could be any indie game's menu. The save card is the hook, and it is small. |
| First sound | The music-box theme on the title (procedural, `scripts/audio/music_box.gd`). | Not listened to. Worth checking in a real session. |
| Opening | A boot log on black (`Story.BOOT`): `PLAYER 2 . . . [deleted]` … `1 UNRECOGNISED ENTITY` … `slot 02 does not exist.` | **Strong.** It sets up the premise (you are the deleted Player 2) in about 15 seconds without exposition. |
| Wake (0–10 s) | Rue materialises. An act card reads "ACT I · SOMEONE ELSE'S SAVE". A wall note says "Welcome home, Arin. Don't forget to save!". Rue's three thoughts type one after another at the bottom left. A controls hint appears. At 10 s comes "something cyan, in the corner of my eye." | The pacing is good: the text arrives in sequence, not all at once. **But the room is a flat, dim brown box** (shot `03d`), and nothing unsettling happens on screen in the first 10 s. All the dread is carried by text. |
| Controls | The title screen lists them. In game only "E interact · ESC pause" appears. The movement tip waits until the tutorial's sequence reaches it. | Acceptable. Movement is universally guessed. |
| First unsettling event | Walk toward the door and it **locks in front of you** (`ArinsRoom.on_owner_event`, `door.lock()`), and awareness jumps to CONTAIN. | Excellent and systemic: the world reacts to *intent*. It is the best moment of the opening, and it currently depends on the player trying the obvious exit. |
| Owner shown to be reactive | The door lock, the "I SAW YOU." note on later runs, and the owner's typed lines. | Clear by about the 1-minute mark. |
| First glitch | The cracked wall in Arin's room teaches PHASE (`cracked_wall.gd`, tutorial "crack"). | It is taught well (a tip plus pink brackets). Whether it feels satisfying needs a human playtest. |
| First consequence | After dying, the next run's note recalls the cause (`Story.NOTE_RECALL`), the seam you used is patched with an audible stitch, and a helper (Wren) is deleted. | **This is the game's signature.** It needs a death to show, so a player who doesn't die early never sees it. |
| First reason to continue | Memories (cyan) and the line "it feels like mine". | Good. The mystery is personal, not abstract. |

**Stall risks (hypotheses for playtesting):**
- The seam only opens once the owner is suspicious (`test_world.test_seam_opens…`). A cautious player who stays calm may not find a way out.
- The cracked wall needs `hold E`, which is unusual.
- In the square, the route to the north road needs the Archivist's pointer. There's a sign, but "NORTH ROAD" is shown struck through.

## B. Visual identity

| Element | Observation (tour shots) |
|---|---|
| Palette | Room, square, archive, bin and house all use the same **low-contrast brown on black** (`Area.WALL_COL #4a3b33`, floors `#2a2320`…). Only the Edge (cold wireframe and magenta missing-texture checkerboards, `15_edge`) and Out of Bounds (a blueprint grid, `14_oob`) are instantly recognisable. |
| Composition | Every area is a rectangle floating in black with the HUD around it. The framing reads as "a screen inside a screen", which suits the premise, but within the rectangle there are few focal points. The middle of the opening room is an empty rug where the act card appears. |
| Lighting | There is one `CanvasModulate` per area (`world.gd:_base_light`) and no light sources. Depth and atmosphere come entirely from the full-screen shader. |
| Characters | Characters are 16 px procedural sprites (`pixel_character.gd`) with distinct colours: Rue cyan, Mira orange, Arin blue, Wren green. They are readable, but the silhouettes are similar. |
| Corruption | **Already semantically split, though not documented:** cyan is Rue's (memories, glitch success, Slot 2), magenta/red is the owner's (cursor, deletion washes, awareness tint), and the cold blue wash is the Edge (unloaded). It is used consistently in code (`screen_fx.gd`). This is a strength to formalise (→ `ART_DIRECTION.md`). |
| Readability | The death cards are readable (`23`, `25`). The HUNT state is readable: a red-tinted world with clear threats (`20b`). The Edge adds a ghosting aberration to all UI text (`25`, `26`), so it is legible but tiring. |
| Screenshot appeal | The Edge (a missing-texture world) and Slot 2's choice (`31`) are distinctive. The warm areas are not: a screenshot of the square or the room says "small pixel RPG", not "horror". |

## C. Characters and narrative

Canon is documented in `docs/NARRATIVE_BIBLE.md`. In summary:

- **Rue (you).** Player 2, whose save was deleted, comes back as an "unrecognised entity". The code consistently calls her she/her. Her identity is revealed through 5 memories plus the Recycle Bin.
- **The owner.** Arin's real-world player. They lost Rue when Rue moved away, deleted slot 2, and never sent the reply. Their behaviour (reloads, saving over you, deleting helpers) has coherent grief-and-control motivation.
- **Arin.** The owner's avatar walking the square. The bible §3.0 notes how the text separates avatar from person.
- **Mira, Wren and Tobben** are villagers with side stories (an escort, an escort, the guest book). **Pip** is Rue's fox from out of bounds. **The Archivist** keeps the cut content.

**Confirmed problems (bible §10):**
1. It contradicts itself on whether the owner knows Slot 2 exists. This is **major**, because it's the central mystery.
2. The backstory timeline contradicts itself: "two years" vs "months later", and "already deleted" vs the draft "i still have your sa".
3. Fragment 1's speakers appear reversed.
4. Rue's name leaks before it is "remembered".
5. The room note after the *unseen* ending says "I KNOW ABOUT SLOT 2", contradicting that ending.
6. A dead branch: Mira's note is never "carried".
7. Repeated exposition: "the owner can't see…" is said by five characters.

**Endings.** All six (escape, rue, wren, message, unseen, overwrite) exist and are mechanically distinct. Each gets a final exchange (`Story.FINAL_EXCHANGE`), a title-screen aftermath and an epilogue. The hidden two (unseen and overwrite) have no in-world foreshadowing beyond the Records hints. **Items 1, 2 and 3 need author decisions** (see the bible §11) before anyone rewrites lines.

## D. Gameplay and horror

| Area | Assessment |
|---|---|
| Threat readability | Good. Arin has a visible cone, the cursor is a literal cursor, the static has cracks that appear 0.5–9.5 s before it spreads, and the save-over has a ring. Every threat has a tell. |
| Agency | High. 9 glitches, each with a cost, and several routes out of the room (seam, door UNLOCK, PHASE). |
| AI fairness | Purge caps the starting awareness below SUSPECT. Reloads skip dangerous moments. There's mercy at the Edge (see `test_fairness`, `docs/AUDIT.md`). |
| Tension and relief | The Archive and Out of Bounds are safe rooms (awareness cools), and the bin runs on a rhythm. That's good contrast. |
| Consequences | Strong and visible: notes, patched seams, deleted helpers, Arin's detours. |
| Repetition risk | Each run restarts in the same room with the same route. Five patched seams cap the variation. Hypothesis: runs 3 to 5 feel samey. |
| Difficulty spikes | The Edge (static plus cursor plus the Slot 2 fight) is where the bots die most (`bots.log`: eraser in the Edge). |

## E. Commercial

- **USP.** *A horror game that remembers you.* The world physically changes after you die or quit: the seam you used is stitched shut, the friend who hid you is deleted, and the note on the wall knows how you died.
- **Most marketable mechanic.** The owner's reactions to *intent*: the door locking as you approach, the reload dragging you backwards along your own path, the ring that saves over you.
- **Most emotional element.** The second player whose save was deleted, and the unsent reply in the Recycle Bin ("hey. i know it's been ages. yes i still have your sa").
- **Hard to show in a trailer.** Cross-session persistence, which needs a before-and-after edit, and the owner's typed lines, which are small text.
- **Candidate 15–30 s clips:**
  - the door locking as you walk up to it;
  - the reload rewind;
  - the Edge's missing-texture world plus the cursor;
  - "I SAW YOU." on the note after a death;
  - the Slot 2 choice.
- **Quit-risk friction (hypotheses):**
  - the opening's visual blandness;
  - a cautious player not finding the seam;
  - deaths at the Edge late in a run.

## Scores (internal heuristic, 1–10)

| Category | Score | Why |
|---|---|---|
| Opening / first session | 6 | The boot log and the door lock are strong. The first room is visually inert, and the dread is text-only for the first 10 s. |
| Visual identity | 5 | The Edge and OOB are distinctive and the corruption colour language is good. The five "real" areas look interchangeable and flat. |
| Characters | 6 | Distinct colours and side stories. The silhouettes are similar and several voices share the same lowercase-cryptic register. |
| Narrative | 6 | A strong premise and a good unsent-message payoff. Contradictions on the central mystery (Slot 2's existence) weaken it. |
| Gameplay / horror systems | 8 | Every threat has a tell and a counter, and the persistence is real and visible. |
| Owner AI as a feature | 7 | Coherent and fair. Its reactions are mostly immediate; there's little delayed or "it remembered" timing within a run. |
| Audio | ? | Not listened to. The code shows per-area beds, a music box that grows with memories, and positional sound. |
| Commercial clarity | 6 | The USP is strong but its visuals undersell it: screenshots of the warm areas don't say horror. |

## Top three improvements

1. **Give the remembered places a look that means something: the frozen afternoon.** The room, square and house are "the version someone remembers", so make them look *remembered*: warm, specific, lit by an afternoon sun that never moves (the save clock says 14:22). Then let the owner's attention visibly drain that warmth. This turns the most-seen screens from generic into premise-bearing. It costs draw code only, with no collision or canon change.
2. **Resolve the central contradictions** (Slot 2's existence, the timeline, Fragment 1's speakers). Players who chase the mystery, and streamers who read every note, will find them. This needs author approval first (the bible §11).
3. **Make the first 60 seconds show the owner, not just tell it.** One on-screen sign of the world reacting before the player reaches the door. For example, the room's light could shift toward Rue when the owner first notices. It would reuse the warmth system from item 1.

**Why these beat a new area or mechanic.** The game already has 7 areas, 9 glitches and 6 endings, which is more content than a demo needs. Every player sees the first room and the square many times, while new content is seen once, by fewer players. The bottleneck is how the existing content *reads*, in screenshots, in the first minute, and in the story's consistency. Its quantity is not the bottleneck.

## F. Reproducing the visual tour

```
xvfb-run -a -s "-screen 0 1280x720x24" $GODOT --path . -s res://tests/run_tests.gd \
    -- --test-mode --tour --screenshots=/some/dir
```

The tour writes a PNG per stop, and `frame_times.txt` (milliseconds per frame under software GL). Those timings are only good for comparing before and after on the same machine, never real hardware.

## Changelog
- 2026-10-16: First audit. Implemented improvement 1 for Arin's room (see `ART_DIRECTION.md`, "The frozen afternoon").
