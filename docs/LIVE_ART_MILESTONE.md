# Milestone: readable storytelling and expressive characters

This milestone covers the opening room and the first Square encounter. It
was built on `main` at `1e371b1` in branch
`claude/last-save-file-prototype-ljwuq4`. Every claim below names the
commit and the test that supports it. Simulation is labelled as
simulation. Nothing here was checked on hardware, by human players or by
listeners.

## Baseline

- The branch was fast-forwarded to `origin/main` `1e371b1` with no force
  and a clean tree.
- Focused baseline run (`presentation_revision`, `character_presentation`,
  `story_pacing`, `voice_over`, `revision_oct21`): **37/37 passed**.
- The 471-test result and the five ending bots recorded in
  `RELEASE_READINESS.md` belong to `1c21266`, not to this branch's head.
  The new runs are under *Verification* below.
- Each defect below was reproduced against the baseline source before it
  was fixed. The failing reproduction is quoted in the commit that fixes it.

## Findings, classified

| # | Finding | Class | Evidence | Status |
|---|---|---|---|---|
| A03 | `PortraitView` never drew external portrait art; `CharacterArt.texture_for`'s PNG path never reached live dialogue | source-confirmed gap | `test_portrait_art`: 3 of 5 failed on the baseline `PortraitView` | fixed `cc76537` |
| A04 | A recorded line skipped pagination and could grow the box off screen; one take had no defined behaviour across pages | source-confirmed gap (no shipped take was long enough to show it) | `test_captions`: 3 of 4 failed on the baseline | fixed `2dc26b9` |
| A06 | World mouths kept moving while the box waited for the next press | reproduced defect | baseline probe: "mouth rests while waiting" failed | fixed `65c0cd9` |
| A06 | Frayed Tobben (written answer) mouthed in the world and the portrait, and his note went to the narrator | reproduced defect | baseline probe failed | fixed `65c0cd9` |
| A07 | A restricted NPC still waved and hopped | reproduced defect | baseline probe: Tobben waved while restricted | fixed `65c0cd9` |
| A07 | The reading book could be drawn on a back view | source-confirmed gap | inline condition in both renderers | fixed `65c0cd9` (`shows_book()`) |
| — | Two mouth clocks: the HUD toggled `frame` every 0.12 s while the figure kept its own phase | source-confirmed gap | `hud._update_dialogue_face` vs `IllustratedCharacter._t` | fixed `65c0cd9`: one clock |
| A05 | Console story lines were capped at 6 s, and a queued owner line cut a thought to 0.8 s | reproduced defect | `test_ambient_pacing`: 2 of 3 failed (8 assertions) | fixed `fae5fa2` |
| A09 | Rue's tears, dropouts and colour dropouts were rolled per frame, so they ran 4× as often at 120 FPS as at 30, at a quarter of the length | reproduced (simulated FPS) | `test_timed_glitch` baseline: dropouts 0.45/s at 30 FPS vs 2.35/s at 120; 8 ms each at 120 | fixed `80cc756` |
| A24 | Narration asked the device for voices at startup even with narration off; the title's settings menu asked again | reproduced (rendered Linux, no speech service) | `Parameter "synth" is null`: 2 before, 0 after | fixed `131eb3c` |
| — | The objective's fixed 400 px backing covered the owner's wall note in the opening room | visual observation (rendered capture) | `fresh_room.png` before/after | fixed (see below) |
| — | In the Square, the long first goal still wraps at 400 px and briefly overlaps the MISSING notice while it is shown | visual observation | `s03_square` timing; the goal fades after its reading time | open |
| — | The rug and the window light still compete with the small first actionable objects in the room (A10) | usability hypothesis | captures only; no uncoached player observed | open |
| — | Speech rate was tied to each character's pace only; no player control | missing content | settings audit | added `131eb3c` |

## What a player now sees

- **Finished portrait art can be dropped in.** Each character has one
  folder (`art/portraits/<who>/`), and it reaches the live dialogue and
  scene portraits. The art is shown only for the look it was painted for:
  a restored Rue never covers her missing face, and frayed Wren keeps her
  lost ribbon lost. A missing expression uses the set's own neutral face.
  Broken, mis-sized or unreadable files fall back to the drawn bust and
  warn once. No finished art ships yet; fixtures prove the route.
- **A long recorded line is one performance.** It is shown as caption
  pages that follow the take, the story event fires once, and the box never
  leaves the screen at any text size.
- **Bodies follow the line.** A mouth moves only while that character's own
  line is being typed or voiced. Written and mute speakers never mouth. A
  restricted character stands still, with no hop, wave or book. The
  portrait's mouth runs on the figure's clock.
- **Story text in the console is readable.** Thoughts, people and the
  owner keep their full reading time. Counters stay brisk. The owner's
  lines still go first but no longer cut a thought short, and urgent
  warnings still appear at once on their own strip. The full route matrix
  is in `docs/STORY_TEXT_ROUTES.md`.
- **The glitch looks the same at any frame rate.**
- **Speech rate** is its own setting (Slower to Fastest), separate from text
  speed, and the device is asked for voices only when speech may be used.
- **The opening room's wall note is no longer hidden** behind the goal.

## Portrait art specification

This is the contract `PortraitArt` enforces (`scripts/ui/portrait_art.gd`).
Art that breaks it is refused and falls back to the drawn bust, so a
mistake can never show the wrong face.

- **Folder:** `art/portraits/<who>/`. The value of `who` is one of `rue`,
  `mira`, `wren`, `tobben`, `archivist`, `arin`.
- **Files:** `portrait.json`, plus `<expression>.png` for each expression
  drawn. Optional frames are `<expression>_talk.png` (mouth open) and
  `<expression>_blink.png`. Without a talk frame, the face lifts one pixel
  on the mouth beat.
- **Expressions:** use the names in `CharacterArt.expressions_for(who)`.
  `neutral` is required; it is the fallback for any expression not drawn.
- **`portrait.json`:**
  ```json
  {"version": 1, "size": [192, 192], "anchor": [0.5, 0.42], "zoom": 1.0,
   "palette": {"h": "#5a3420", "s": "#e8c48a", "c": "#c9733e", "d": "#a85a2e"},
   "provenance": "artist, date, licence"}
  ```
  - `size`: every image in the set must have exactly this size, between
    16 and 4096 px per side.
  - `anchor`: the face centre in the image, from 0 to 1. Every expression
    and frame is placed by it, so the bust never jumps between lines.
  - `zoom`: the image width as a share of the portrait frame.
  - `palette`: the look the art was painted for. Use the colour keys of the
    character's current portrait (`CharacterArt.for_npc(...).palette`, or
    `Player.palette_for(5, [])` for fully restored Rue). The art is used
    only while every listed key matches exactly.
  - `provenance`: who made the art and under what licence. It is required
    by `docs/ASSET_PRODUCTION.md`.
- **Frames on screen:** dialogue 50×50 and scenes 64×64 logical pixels,
  scaled with the window (2× at 720p, 6× at 4K). A 192 px set covers the
  scene portrait at 3× without upscaling. Keep the face inside the central
  60%: the frame is square and crops the edges.
- **Story states need their own sets, or rely on the drawn fallback:**
  Rue's missing and part-restored looks, a frayed Wren or Mira, and
  borrowed pieces. Never paint a restored look and label it with another
  state's palette.

## Sound and voice inventory (as shipped on this branch)

| What | Source | In the build | Status |
|---|---|---|---|
| Music box theme (6 variations × normal/reverse/invert) | synthesised in code, baked to `audio/baked/*.res` | yes | original, procedural |
| Drones (hum, dread) | synthesised, baked | yes | original, procedural |
| Effects (steps, keys, owner blip, stingers, glitches) | synthesised at runtime (`scripts/autoload/sfx.gd`) | yes | original, procedural |
| Character "voices" in text (syllable blips) | procedural, per character | yes | not speech |
| System speech (Narration) | the player's device TTS, off by default | uses the device | identity varies by device and OS. With one device voice, the speaker's name is read out first |
| Recorded voice lines (`audio/voice/<id>.ogg`) | none shipped | **no** | `manifest.csv` lists 216 lines, every one "text only (not recorded)" |
| Generated review takes (`narration_review/`) | ElevenLabs, voice "Karla", 2026-10-18; 8 of 12 memory lines | **excluded from exports** (`export_presets.cfg`) | generated voice, not human performance. Terms must be checked at use; not listened to by a human reviewer for this milestone |

Nothing in this milestone was listened to by a person. The caption and take
tests use silent WAV fixtures.

## Verification

Filled in from the runs on this branch's head:

- Full headless suite: see `RELEASE_READINESS.md`, current section.
- Bots, Web and audio checks, exports and captures: same section.

## Not done here

- No finished portrait art, recorded performances or human listening.
- No uncoached players: first-ten-minutes figures come from bots and
  simulation only.
- No Windows execution or real-GPU, phone or gamepad sessions.
- ObjectDB/resource warnings at shutdown remain (A14). They were not
  investigated in this milestone.
- The A10 room readability and the Square goal overlap are listed as open
  above.
