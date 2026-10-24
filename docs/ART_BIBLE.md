# Art bible (2026-10-24)

Style frames: `docs/review/intro/style_cast_before_after.jpg`,
`style_rue_walk_moods.jpg`, and the prologue frames (`after_*`). They are
reproduced by `tests/tour_style_frames.gd`.

## Direction: illustrated 2D, vector-drawn at window resolution

**What it is.**
- Clean shapes with one dark silhouette line and painted two-tone shading.
- Light comes from the upper left, with a warm rim light on the lit edges.
- Expressive faces (eye whites, irises, highlights, brows that move).
- Rigged limbs: two-segment arms and legs, swing and bend.
- Secondary motion on the scarf and hair (damped springs).
- Drawn as vectors in code (`HeroFigure`). They render at the window's
  resolution: 1280×720 and up, never stretched pixels. The world keeps its
  640×360 logical coordinates, collision boxes and speeds.

**Why this, not hi-bit pixel art.**
1. The game already draws everything as vectors at native resolution.
   Lights, particles, portraits and the CRT effect are tuned for it. Pixel
   art at a new base resolution would need every area repainted to match.
2. One rig serves every animation and every palette change. Rue's five-step
   restoration, borrowed pieces, fraying and the missing-texture look are
   palette and pose states. With frame-by-frame pixel art, each would
   multiply the frame count by 5–8.
3. It scales cleanly into close shots (the prologue, portraits, the capsule)
   with no new art.

**What it is not, said plainly.**
- This procedural cast is a clear step up from the 21–33 px figures it
  replaces: taller, a real walk, readable faces, motion that follows
  through.
- It is **not** the hand-drawn quality of a commercially illustrated indie
  release.
- That needs an artist working from this bible. The pipeline below takes
  their sheets without code changes; see the commission brief at the end.
- Until then, every figure on screen is the procedural fallback. It is
  final enough to judge the game, not final art.

## Proportions (logical px; the screen shows them at 2× or more)

| Character | Height | Head | Shoulders (half) | Hips (half) | Legs | Silhouette key |
|---|---|---|---|---|---|---|
| Rue | 34 | 9.4 | 4.3 | 3.3 | 40% | Cowlick tuft, flared raincoat skirt, red scarf tail |
| Arin | 38 | 9.6 | 5.0 | 3.8 | 42% | Straight shoulders, belt with buckle, red scarf |
| Mira | 36 | 9.4 | 4.3 | 4.0 | 40% | Long hair to the shoulders, dress hem |
| Wren | 28 | 9.0 | 3.5 | 3.0 | 36% | Pigtails with ribbons, a child's head-to-body ratio |
| Tobben | 37 | 9.6 | 5.8 | 5.2 | 36% | Stout, bald crown with a side fringe, moustache, apron |
| Archivist | 42 | 9.4 | 4.8 | 4.8 | 40% | The tallest, beard to the chest, robe to the floor, sash |
| Pip | 10 (fox) | — | — | — | — | Ears, a white tail tip, always low to the ground |

The ratio is about 1 : 3.6 head-to-body for adults (it was about 1 : 2.6),
and 1 : 3.1 for Wren. All six silhouettes are distinct in black fill
(`style_cast_before_after.jpg`, top row against bottom).

## Palette

Then and now are the game's two time states.

| Element | "Then" (the festival) | "Now" (three years later) |
|---|---|---|
| Light | Low gold sun, warm bounce (`#ffcf8a`) | Cold blue fill (`#9ab4d8`), dim |
| Shadow | Warm violet | Blue-black |
| Rue | Full colours, with no shimmer | The missing-texture cyan (`#8cf2ff`) until restored, plus the "left running" shimmer |
| Threat accents | None | The owner's red (`#e0504f`), used sparingly |
| UI | Cream on dark | Cream on dark. System toasts in cyan, the owner in red, prefixed with `>` |

The character colours are unchanged (`Player.RUE`, `OwnerAvatar`, the NPC
palettes), so everything already keyed to them still works.

## Faces

Moods: `IllustratedCharacter.MOODS`, shared by world figures and portraits.
At least neutral, eager (happy), afraid, determined, concerned (sad) and
relieved; plus remembering, awed, proud, brave, and reset (blank).
- **Neutral** brows sit level: a friendly face at rest.
- **The missing texture:** two points of light, no mouth.
- **Rue "left running":** faint cyan slips drift up through her. It never
  hides her shape, and it is off under reduced motion (`HeroFigure.left_running`).

## Animation list

| Clip | HeroFigure state | Notes |
|---|---|---|
| Idle | breath (2.6 s), blink | Per-character idles: tend (Tobben), read (Archivist), hop (Wren), sway |
| Walk | gait phase `_walk`, a stride per π | Thigh swing ±0.38 rad, the knee lifts on the back swing, arms counter-swing |
| Run | above 70 px/s | Stride ±0.55, elbows bent, body tilt, scarf streams |
| Start / stop / turn | `start` 0.14 s lean; `settle` 0.18 s; `turn` 0.12 s squeeze | |
| Interact | point (near hand out) | |
| Hide / crouch | `crouch` | Drops 2.4 px, knees bent |
| Emote: the habit | `play_habit()` 0.95 s | Two light taps of the near hand, then the press, with a small hop |
| Emote: spin | `play_spin()` 0.6 s | Arin's celebration: a turn through the four views |
| Wave | `waving` | |
| Hurt / erase | Owners' dissolve and deletion effects (unchanged) | |
| Talk | `talking` | The mouth flaps at 4 Hz |

**For an artist's sheets:**
- Frame counts: idle 6, walk 8, run 8, crouch 2, interact 4, habit 10,
  spin 8, wave 6, talk 4.
- Views: front, back and side (mirrored).

## Pipeline (assets → game)

- The asset path is `assets/characters/<who>/sheet.png` plus `sheet.json`
  (frame size, the clips above, feet anchor).
- `CharacterArt` stays the one place that picks how someone is drawn. A
  sheet, when present and valid, is used. Otherwise `HeroFigure` (this
  file's procedural cast). Otherwise `IllustratedCharacter`.
- A missing or broken sheet never breaks the game.
- **No sheet exists yet.** Nothing has been bought, generated or
  commissioned (author question Q4).

## Commission brief (if the author wants hand-drawn final art)

- **Scope:** seven characters × the animation list above × three views,
  plus five portrait busts (Rue, Mira, Wren, Tobben, the Archivist) in the
  listed moods.
- **Deliverables:** sheets at 2× (characters about 70–90 px tall), on a
  transparent background, in the palettes above, with the silhouette keys
  kept.
- **Rights:** a work-for-hire or exclusive licence for commercial
  distribution on PC, web and consoles; layered sources included.
- **Cost structure** (to be priced from real quotes, not estimated here):
  - per character: turnaround + clips × frames × views;
  - portraits per mood;
  - one revision round each;
  - a test character first (Rue), before the rest is commissioned.
