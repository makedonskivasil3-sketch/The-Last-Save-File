# Character art: direction, briefs, expressions

> **Superseded for the in-game look (2026-10-19):** the cast is now drawn as illustrated vector figures (`IllustratedCharacter`); see `docs/VISUAL_DIRECTION.md`. The briefs, palettes and expression lists below still apply; the pixel-grid specifics are historical.

The cast was code-drawn pixel art, like the rest of the game. This document sets the look for **in-world sprites, portraits, animation and interface**.
- **Rue** (the reference), **Mira** and **Wren** (supporting characters) are fully integrated.
- The others have briefs, ready to build the same way.

**The presentation contract** (`CharacterArt.CAST`, tested in `tests/test_character_presentation.gd`):
- A character has a portrait only if they are in `CAST`. That means:
  - their own 32×32 bust grid;
  - the six shared expressions, plus any of their own;
  - colours taken from their in-world sprite's palette.
- Everyone else gets **no portrait**, never Rue's face as a stand-in. The dialogue box then uses its full width.
- A portrait has three frames: still, talking (the mouth moves while the line types or the voice speaks) and a blink. Reduce flashing keeps the mouth still.
- Expressions follow the line. The area maps each authored line to a face, as `ArinsRoom.mira_expression` does.
- Canon is from `NARRATIVE_BIBLE.md` §3. Nothing here adds biography.

## How characters render today (inspected 2026-10-18)

| Layer | What exists | File |
|---|---|---|
| **In-world sprite** | 8-pixel-wide palette templates drawn at 2× (16×24 px on the 640×360 screen). They have animated legs, eyes, mouth, arms, Rue's scarf end, blink, breathing, hop and sway. **Expressions:** startled (wide eyes), glance, crouch, hug, shiver, pointing (Arin). Soft ground shadow | `scripts/world/pixel_character.gd` |
| **Palette** | Per-character keys (`h` hair, `s` skin, `c` clothes, `d` dark, `a` accent, `l` legs, `f` shoes, `e` eyes). Rue starts in the **missing** palette, and each recovered memory restores keys in a fixed order: scarf → hair → coat → legs → face | `scripts/player/player.gd` (`RUE`, `MISSING`, `RESTORE_ORDER`) |
| **Portraits** | None before this pass | — |
| **Interface** | Speaker names in colour; procedural voices per speaker | `hud.gd`, `sfx.gd` |

**Problems:**
- Four of the six humanoids share one silhouette and differ mostly by colour (`CHARACTER_DIRECTION.md`).
- Faces are 1–2 pixels, so emotion was carried almost entirely by text.

## Direction: "a save file's people, seen up close"

1. **One grid, two scales.**
   - **Sprites** stay 8×N templates at 2×. They have to read through the CRT pass at 640×360.
   - **Portraits** are 32×32 busts shown at 2× (64 px) in story scenes.
   - Both draw from **the same palette keys**, so a portrait can never disagree with the sprite on screen. That includes Rue's restoration.
2. **Proportions.** Portrait heads take the top 2/3 of the frame: large eyes (2×3 px) and small mouths (2 px). These are the readable, slightly soft proportions of the 16-bit RPGs that Arin's save imitates. **No realistic anatomy:** the save is a game, and its people are game people.
3. **Rendering.**
   - A 1 px dark outline (`#1a1014`) around every figure, for separation from any background, lit or dark.
   - Two tones per material (base plus a shade 12–30% darker), lit from the top-left, which matches the room's window.
   - No dithering and no anti-aliasing.
4. **Silhouettes first.** Each character must be recognisable as a solid black shape:
   - Rue: the cowlick, the scarf end and the raincoat collar.
   - Mira: long hair and a dress hem.
   - Wren: pigtails and a child's height.
   - Tobben: a bald crown and a moustache.
   - The Archivist: a tall robe.
   - Arin: plain and square, deliberately.
5. **Palettes mean something** (`ART_DIRECTION.md`). Cyan (Rue's missing look and the intruder's glitches) is **never** used for the owner. Owner-orange (`#e0704f`) is only for the owner and their avatar's threat tells.
6. **Expressions are shapes, not colours.** Every expression changes eye and brow shape and mouth. Fear adds visible whites; relief closes the eyes into arcs. Readable without colour, and at 1×.
7. **Unsettling without gore.** The unease comes from **absence and wrongness**: Rue's void face before her last memory, Arin's unblinking point, the owner never appearing as a body. **Threats stay legible:** Arin's cone, the warning triangle, the cursor's ring on Rue.

## Rue: the reference character (integrated)

- **Role:** the intruder; Slot 2's deleted character; the player.
- **Personality:** scared, honest, dry, short sentences (bible §3.1).
- **Silhouette:**
  - messy brown hair with a **cowlick** (her one unique sprite pixel);
  - **red scarf** with a trailing end;
  - **yellow raincoat** with seams and toggles.
- **Palette** (restored): hair `#8a4f2c`, skin `#f0c49c`, coat `#e9b44c`/`#a9772a`, scarf `#d8463a`, eyes `#2a1612`.
- **Missing palette:** cyan hair `#3fa6b8`, a void face `#05070a` with eyes as two points of light `#e8ffff`.

### Expressions

| Expression | Shape | Used for |
|---|---|---|
| **neutral** | open 2×3 eyes with a highlight, level brows, small mouth, cheeks | default |
| **concerned** | half-lidded eyes, brows tilted up toward the centre, wavering mouth | warnings, Mira's worry |
| **afraid** | taller eyes with whites above, raised brows, open mouth, no blush | the planted memory, being caught |
| **relieved** | closed smiling arcs, soft mouth, extra blush | the guest book, the epilogue |
| **determined** (Rue-specific) | narrowed eyes, brows angled down, flat mouth | the Slot 2 recap and the final exchange |
| **remembering** (Rue-specific) | closed eyes (a flat line), level brows | the memory scenes |

**Before her last memory, only the eyes show:** two points of light that still take each expression's shape. Brows, mouth and cheeks appear when her face comes back. This is the same order as her sprite, so no new canon.

Reference sheets, generated by the game's own code (`tests/tour_story.gd`, `test_tour_rue_sheet`):
- `docs/review/rue_expressions_restored.png`
- `docs/review/rue_expressions_three_memories.png`
- `docs/review/rue_expressions_missing.png`

### Where she appears

| Scene | Expression | Look |
|---|---|---|
| Memory | remembering | her **current** palette, as restored so far |
| Planted memory | afraid | current palette |
| Guest book | relieved | current palette |
| Slot 2 recap, final exchange | determined | current palette |
| Epilogue | relieved | current palette |

**In-world:** she keeps her sprite; the same keys and outline language apply.

### Assets and import

- Portraits are generated at runtime (`scripts/ui/character_art.gd`, `CharacterArt`): a 32×32 RGBA `ImageTexture`, cached per expression and palette.
- They are shown in a `TextureRect` with **nearest filtering** (no smoothing), at exactly 2×.
- **Replacing them with drawn art:** put `res://art/characters/rue/rue_<expression>.png` (32×32, transparent, sRGB). Godot import settings:
  - Texture **Filter: off** (or Nearest);
  - **Mipmaps: off**;
  - **Compression: Lossless**.

  It is used for the fully restored look. The missing and partly restored looks stay code-drawn, so the restoration mechanic keeps working.

## Briefs for the rest of the cast (to build the same way)

### Arin (the owner's avatar)

- **Role:** patrols, sees, comes home, guards Slot 2. **Silent.**
- **Visual brief:**
  - A deliberately generic RPG hero: square shoulders, tunic, a belt in owner-red. No personal details. **The plainness is the point:** a character someone stopped playing.
  - Portrait: symmetrical, **eyes that never blink** (the only character without a blink cycle), mouth always closed.
- **Expressions:**
  - neutral (blank);
  - noticing (pupils shift toward the viewer, 1 px);
  - pointing (in-world only: arm out, still);
  - **frozen** (the PAUSE glitch: desaturated, outline doubled).

  **No afraid or relieved:** Arin has no inner life of its own. The real Arin on the purge screen is the one exception: a single **relieved** frame, eyes closed.
- **Keep legible:** the cone is compensated for lighting (`OwnerAvatar.cone_color`). The warning triangle is owner-orange, never white.

### The owner (never shown as a body)

- **Presence:**
  - the console (lowercase, `>`);
  - the cursor;
  - the eraser;
  - the reload banner;
  - the drag of props.

  **Never draw a face.**
- **Behaviour as composition:** the owner is felt through *what changes on screen*:
  - notes rewritten while Rue's back is turned;
  - the cursor settling on Rue (the ring);
  - the screen holding still when they pause.
- **Animation:** the cursor eases in like a hand (slow, then sure), and hovers a beat before acting. That hover is the reaction window, and **it must stay readable**: never shorter than it is now.
- **Sound:** a flat, tired voice (`VOICE_BIBLE.md`), blips that drop syllables as strain rises, and silence before the worst moments.
- **Expressions (in voice and console, not portrait):**
  - bored;
  - irritated;
  - cruel;
  - cracking ("> stop. stop. please.");
  - **recognising** ("...rue?").

### Mira (integrated)

**Built in this pass.** The art is code-drawn in this repository, so there is nothing external to attribute.
- **Silhouette:**
  - long, straight hair with a centre parting, falling past both shoulders;
  - a ribbon on her left side (the dress trim colour);
  - a dress with a round collar and a centre seam.

  No cowlick and no scarf: at a glance she is not Rue recoloured. The test requires the two silhouettes to differ by more than 60 pixels.
- **Palette:** read from her sprite (`Npc.sprite().palette`): hair `5a3420`, skin `e8c48a`, dress `c9733e`, trim `a85a2e`. The portrait matches the figure in the room.
- **Expressions:** the shared six, plus three of her own:
  - **eager**: asking to go out;
  - **proud**: pinning her note, "MIRA WAS HERE";
  - **reset**: the blank, too-wide smile, with no light in the eyes, after the owner resets her.
- **Where she appears:**
  - every conversation in Arin's room;
  - her request, join and decline lines;
  - what she remembers from earlier runs;
  - the notice-board scene (**proud**).
- **Evidence:**
  - `review/mira_expressions.png` (left to right: neutral, concerned, afraid, relieved, determined, remembering, eager, proud, reset);
  - `review/mira_frames_still_talk_blink.png`;
  - `review/after_mira_dialogue_portrait.png`.

  These are staged automation screenshots, **not an approval of the art**.
- **Still open:** the brief asks to move her dress away from Pip's orange, toward rose. That changes her in-world sprite as well, so it is left for an art review.

The original brief follows.

- **Role:** in Arin's room; warm, worried; wants to be remembered.
- **Visual brief:** long hair framing the face, a dress with a hem, a slight forward lean (eager). Palette: dress orange-tan; **keep her away from Pip's orange** (ΔE 14 today; shift the dress toward rose).
- **Expressions:**
  - neutral;
  - concerned;
  - afraid;
  - relieved;
  - **proud** (Mira-specific: chin up, eyes closed, "MIRA WAS HERE");
  - **reset** (Mira-specific: a blank, too-wide smile after the owner resets her).

### Wren (integrated)

**Built in the cohesion pass.** The art is code-drawn in this repository, so there is nothing external to attribute.
- **Silhouette:** a round head with a short fringe, and two pigtails sticking straight out at the sides, tied in green. Narrow shoulders and a green pinafore. She is visibly a child, and unlike Rue or Mira (the test requires more than 60 pixels of difference).
- **Palette:** read from her sprite: hair `c9a04a`, skin `e8c48a`, pinafore `6a8f5a`, trim `4a6a3a`.
- **Expressions:** the shared six, plus the two in her brief:
  - **brave**: brows down, mouth set;
  - **awed**: wide eyes with the slot's cyan in them.
- **Where she appears:**
  - her conversations in the square;
  - her request, join and decline lines;
  - what she remembers. Her own ending gives *awed*; a death by static gives *afraid*.
- **Evidence:** `review/wren_expressions.png` (left to right: neutral, concerned, afraid, relieved, determined, remembering, brave, awed) and `review/after_wren_dialogue_portrait.png`. These are staged automation shots, **not an art approval**.

The original brief follows.

- **Role:** a child in the square who hides you; wants to see the Edge.
- **Visual brief:** smallest of the cast, pigtails, oversized eyes. Quick hop idle.
- **Expressions:**
  - neutral;
  - concerned;
  - afraid;
  - relieved;
  - **brave** (Wren-specific: brows down, small fists);
  - **awed** (Wren-specific: at the Edge; wide eyes and a cyan reflection).

### Pip

- **Role:** Rue's fox, out of bounds; loyal; invisible to the owner.
- **Visual brief:** a 10×8 fox, orange with a white tail tip. The name tag flickers. **The only character that is not humanoid:** ears carry the emotion.
- **Expressions (ears and tail):**
  - neutral;
  - alert (ears up);
  - afraid (ears flat, tail tucked);
  - relieved (tail wag);
  - **waiting** (Pip-specific: curled up).

### Tobben

- **Role:** shopkeeper; tells the owner because it's in his script; remembers RUE.
- **Visual brief:** bald crown, moustache, apron. A broad, warm silhouette.
- **Expressions:**
  - neutral (shop smile);
  - concerned;
  - **sorry** (Tobben-specific: eyes down, hand on the back of the neck);
  - relieved;
  - **remembering** ("I'd forgotten I forgot.").

### The Archivist

- **Role:** a cut NPC; keeps the logs; kind and dry.
- **Visual brief:** the tallest, white beard, a robe to the floor; a desk-lamp warmth in the palette.
- **Expressions:**
  - neutral;
  - **amused** (Archivist-specific: one brow up);
  - concerned;
  - relieved (greeting Rue by name).

## Production (when external art is commissioned or generated)

See `ASSET_PRODUCTION.md` for the tools and licences. The **acceptance checklist** for any character asset:
- [ ] 32×32 portrait / 8×N sprite template, transparent PNG, sRGB, no anti-aliasing.
- [ ] Uses the character's palette keys. Rue: also works in the missing palette, or leaves that look to code.
- [ ] Every expression in this document's list, named `<who>_<expression>.png`.
- [ ] Reads at 1× and in greyscale (expressions are shapes).
- [ ] 1 px outline; distinct silhouette in solid black.
- [ ] Source file (`.aseprite` or `.kra`) kept in `art/source/`, with licence and author recorded in `art/CREDITS.md`.
- [ ] Checked in game: `tests/tour_story.gd` screenshots at Normal and Large text, with effects off and full.
