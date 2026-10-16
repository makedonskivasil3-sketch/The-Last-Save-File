# Character direction: The Last Save File

> **Status (2026-10-16):**
> - **Implemented:**
>   - Arin points (a still arm) instead of waving.
>   - Arin's alert is an owner-coloured warning triangle (shape, not just colour).
>   - The real Arin is mute.
>   - Rue's eyes go wide while the cursor settles on her or Arin points.
> - **Still open:** the palette contrast fixes, which need a visual review.

Companion to `docs/ART_DIRECTION.md` (world, colour language) and `docs/NARRATIVE_BIBLE.md` (who these people are).
Part 1 is the **current state** as the code draws it, with file:line references. Part 2 is a **readability evaluation** based on actual colour values. Part 3 is a **PROPOSED** direction. Nothing in Part 3 is implemented yet.

Contrast figures are WCAG contrast ratios (1.0 means invisible, 3.0 reads clearly at pixel scale). Colour differences are CIELAB ΔE76 (below about 10 reads as "the same colour" at 2 px). They were computed from the hex values in code, without the per-area `CanvasModulate` tint (all tints are within 15% of white: e.g. `archive.gd:31`, `village_square.gd:75`) and without the CRT shader.

---

## Part 1: Current state

### 1.0 The shared renderer: `PixelCharacter` (`scripts/world/pixel_character.gd`)

All humanoids use this renderer: Rue, Arin (avatar and NPC), Mira, Wren, Tobben and the Archivist. Pip and the cursor are drawn by hand.

- **Construction.** Each body is an 8-column template of palette keys (`:18-55`). Legs, eyes, mouth, scarf end and book are drawn on top so they can animate (`:248-291`). Keys: `h` hair, `s` skin, `c` clothes, `d` clothes dark, `a` accent, `w` apron, `g`/`v` hood/void, plus `l` legs, `f` shoes, `e` eyes (`:11-12`, `:92-94`).
- **Scale.** Each template pixel is drawn as 2×2 game pixels (`SCALE := 2`, `:17`). Every humanoid is **16 px wide**. Height is `(rows + 2) × 2` (`:98-99`). Feet sit at local y = +6 (`:14`), and collision is always 8×8 (`npc.gd:56`).
- **Outline.** There is **none**. No template has an outline key, and `_rect` draws flat fills only (`:298-304`). Contrast against the floor comes entirely from the palette.
- **Facing.** There are 4 directions, set from velocity (`:113-116`) or by `look_at` (`:142-149`, using a 1.2 bias toward vertical). The sprite is never mirrored. Back view turns face skin `s` into hair `h` (`:194-195`) and hides the face (`:219`). Left and right differ only in eye position (`:271-275`) and the scarf side.

**Every animation flag and state, and what drives it in gameplay:**

| Flag / state | Visual (pixel_character.gd) | Driven by |
|---|---|---|
| `moving` | 4-frame walk: frames 1 and 3 lift one leg 1 px (`:251-261`), body bounces −1 px on step frames (`:175`), arms swing ±1 (`:199-200`). Rate is `velocity/9` clamped to 3..9 (`:112`) | velocity passed to `update()`: player `player.gd:169`, NPC escort `npc.gd:162`/`:90`, Arin `owner_avatar.gd:110` |
| `facing` | eye placement, back view, scarf direction | velocity (`:113`); NPCs watch Rue within 90 px (`npc.gd:168-171`); Arin's cone `_facing` when idle (`owner_avatar.gd:118-119`); Rue's glance-over-shoulder flip (`player.gd:195-196`) |
| breathing | head rows bob 1 px for 0.35 s of every 1.8 s while standing (`:173`, `:185`) | always on when not moving |
| blink | eyes hidden for 0.13 s every 1.8–5 s (`:117-121`, `:270`) | always on |
| `talking` | 1×2 mouth flaps at about 4 Hz (`:280-283`) | NPCs only: `world.gd:234` → `npc.gd:163`. Rue and the Arin avatar never set it |
| `idle_style "sway"` | head sways ±1 px (`:177`) | Mira (`arins_room.gd:108`) |
| `idle_style "hop"` | 3 px hop (6 game px) every 2.5–6 s (`:122-127`, `:176`) | Wren (`village_square.gd:349`) |
| `idle_style "wave"` | sets `waving` within 70 px | Tobben (`village_square.gd:153`, `npc.gd:175`) |
| `idle_style "read"` | open book at arm row, page flips every 3 s (`:221-222`, `:286-291`) | Archivist (`archive.gd:52`) |
| `waving` | the screen-right arm (x=7) is raised 3–5 px and **oscillates** at 8 Hz (`:201-202`) | Tobben near Rue (`npc.gd:175`); **Arin while it sees you** (`owner_avatar.gd:131`, commented "points at you") |
| `crouch` | whole body 1 px lower, legs 1 px shorter (`:178`, `:218`) | `player.sheltered` = `world.is_hidden_now()` (`world.gd:237` → `player.gd:186`), i.e. beside Wren, in bin shelters, in closets |
| `glance` | eyes shift ±1 px while facing the camera (`:277-279`) | Rue still for over 2 s, re-rolled every 0.6–1.8 s ÷ (1+instability) (`player.gd:190-198`) |
| `hug` | arms tuck from x=0/7 to x=1/6 (`:204-205`) | Rue still, `idle_time > 7`, `instability > 0.3` (`player.gd:187`) |
| `shiver` | 0.5 px horizontal tremble at 30 Hz, only when not moving (`:179-180`) | `hug` and `instability > 0.5` (`player.gd:188`) |
| `startled` | eyes 1 px taller, never blink (`:268-270`) | `player.startle()` (`player.gd:125-128`), called at every awareness threshold (`owner_director.gd:183`) |
| `hop(s)` | arc up to 3 px (`:132-133`, `:176`) | startle (`player.gd:127`) |
| draw opts `solid` / `grey` / `slices` / `alpha` | silhouette fill, desaturate, per-band x-tear (head / body / legs), fade (`:153-163`, `:186`) | ghosts, trails, freeze, restricted NPCs, Rue's tearing |

Unused: the **`"intruder"` template** (`:44-48`, hood plus void face) is never instantiated. Rue uses `"rue"`, and the `g`/`v` keys appear nowhere else.

### 1.1 Rue (player): `scripts/player/player.gd`

- **Size and silhouette.** Template `"rue"` (`pixel_character.gd:51-54`) is 10 rows plus legs, so **16×24 px**. It has a one-pixel cowlick on top (row 0), a scarf band at rows 5–6, a raincoat with pocket darks `d` at row 8, and trousers. The scarf's loose end is drawn separately: it trails behind when walking sideways, is 3 px long and flutters at 11 Hz, and hangs down the back when facing away (`pixel_character.gd:228-245`).
- **Palette, restored** (`player.gd:23-26`): hair `#8a4f2c`, skin `#f0c49c`, coat `#e9b44c`, coat dark `#a9772a`, scarf `#d8463a`, legs `#3d4e78`, shoes `#3a2226`, eyes `#2a1612`.
- **Palette, deleted / "missing texture"** (`player.gd:28-31`): hair `#3fa6b8`, face `#05070a` (a void), coat `#8cf2ff`, coat dark `#5fc8d8`, scarf `#d8ffff`, legs `#2f8a9a`, shoes `#1c4e58`, eyes `#e8ffff` (two points of light).
- **Memories.** `RESTORE_ORDER` (`:33`) restores, one fragment each: scarf, then hair, then coat, then legs and shoes, then face and eyes (`refresh_look`, `:81-93`, called from `world.gd:200`). Each gain flashes a white silhouette for 1.2 s (`:91-92`, `:222-224`). Until all 5 are back, a faint cyan eye glow (r = 5, α 0.08) shows when not facing up (`:237-238`). **The silhouette never changes with memories; only the palette does.**
- **Instability** (`= awareness/100`, `world.gd:235`), every effect × `Settings.glitch_intensity`:
  - horizontal jitter ±2 px, rate `2 + 10·inst` per second (`:152`)
  - head / body / leg bands tear ±3 px with probability `unstable·0.25` per frame (`:154-155`), with pink edge flashes at the tear (`:241-244`)
  - dropped frames, where Rue is not drawn, with chance `inst·0.02` (`:157`, `:215`)
  - a pink chromatic ghost `(1,0.2,0.4,0.22)` offset 1 px that sways with instability (`:21`, `:218-219`)
  - a 6-frame stale trail alternating cyan and pink, with strength `0.35 + 0.65·inst` (`:247-256`)
  - restored colours flicker back to MISSING with chance `inst·0.04` per frame (`:200-201`)
- **Idle and anxiety ladder** (`_update_mood`, `:181-201`): standing still → after 2 s, glances (and sometimes looks over the shoulder) → after 7 s at inst > 0.3, hugs → hugs plus shivers at inst > 0.5.
- **Reactions.** Startle (hop, wide eyes, amber "!" `(1,0.85,0.45)` 2×5 px plus a 2×2 dot above the head, 0.9 s, `:125-128`, `:225-229`). Crouch when sheltered (`:186`).
- **Walk.** At 90 px/s (`:37`) the cycle runs at the clamp maximum: about 18 frames/s, or **9 steps/s**. Footstep SFX play on contact frames (`:172-175`).
- **Glitch feedback around Rue** (`glitch_controller.gd:304-333`). Magenta brackets on the target turn cyan as the charge fills. A 15 px charge ring is centred on Rue's chest. PHASE leaves a dotted line and a 5-frame cyan/pink streak (`player.gd:209-214`). Each glitch leaves a pink/cyan tear on the floor for 25 s (`glitch_scar.gd:38-52`). **Rue's body itself does not pose while charging.**
- **DECOY** (`decoy.gd:27-39`). A frozen snapshot (`player.gd:102-108`) at α 0.75 with a pink offset copy and black scanlines every 3 px.
- **Death / dissolve** (`player.gd:259-298`):
  - `materialize`: 36 pixels converge, then flicker in, 1.4 s
  - `erased`: black eats from the feet up with a red bite line, 1.2 s
  - `overwritten`: Arin's blue `#5a7fb0` sweeps down row by row with a white edge, 0.8 s
  - `selected`: a selection box snaps in, then a scatter
  - `rescued`: a stretched cyan streak pulled upward

### 1.2 Arin, the owner's avatar: `scripts/owner/owner_avatar.gd`

- **Template and size.** `"adult"` (`pixel_character.gd:20-23`), **16×24 px**. Hair cap, a neck row, tunic, red belt at the arm row (`sccaaccs`), trousers.
- **Palette** (`:10-12`, `:32-35`): hair `#2a2a30`, skin `#e8c48a`, tunic `#5a7fb0`, dark/legs `#2e3f5c`, belt `#c0392b`, shoes `#1a1a20`, eyes `#101018`. The comment at `:31` says "a red scarf", but the template draws a **belt**, not a scarf.
- **Movement.** It patrols a route at 38–58 px/s (`village_square.gd:166`), so the walk runs at about 4.4 steps/s. It pauses 0.6 s at corners (`:79`). Footsteps are positional and pitched down to 0.75–0.85 (`:111-117`). When lured, it walks at the decoy at 1.2× speed and stares at it (`:62-70`).
- **Tells.** The view cone is the main tell: `VIEW_COL (0.88,0.44,0.31)`, α 0.06, or 0.18 when it sees you, 85 px, 70° (`:125-130`). When seeing: an alert bubble (white 8×9 with an orange "!", bobbing, `:136-140`) and `waving = true` (`:131`).
- **Stunned (FREEZE).** Magenta and cyan silhouettes ±2 px, a grey body, and a cyan "pause" glyph (`:144-151`).
- **Idle.** No `idle_style`. It only breathes and blinks, and faces the cone direction (`:118-119`).
- **Areas.** Square (`village_square.gd:161`), house (`arins_house.gd:107`), Edge (`the_edge.gd:232`).

### 1.3 The owner / cursor: `scripts/owner/owner_cursor.gd`

- **Shape.** A standard arrow pointer, a 7-point polygon **12×20 px**, white with a 1 px black outline (`:191-200`). It is the **only outlined character** in the game. On arrival it starts at up to 7× scale and shrinks (`:150`, `:166`).
- **Layers.** 4 afterimages in alternating pink and cyan (`:181-184`). An RGB split of ±1 px, ±3 px while tracking, and up to +6 px while arriving (`:185-187`).
- **States.** Drift (`_random_point`). Tracking, with full-area crosshair scan lines (`:168-173`). Selecting, with a shrinking cyan selection box and marching ants, screen noise and a rising whine (`:130-137`, `:175-179`). Drag fetch/carry (`:70-94`), which has no visual difference from drift. Blinded, shown as a grey pointer full of static (`:159-164`). Paused.

### 1.4 Mira: `arins_room.gd:105-110` (defaults from `npc.gd:15-21`)

- **Template.** `"dress"`, **16×24 px**. Long hair framing the face down to row 4, a full-width hem, bare legs drawn in skin colour (`pixel_character.gd:250`).
- **Palette.** Dress `#c9733e` (default), hair `#5a3420`, skin `#e8c48a`, hem/legs-base `#a85a2e` (`:110`), accent `#e8c48a` (not drawn on the dress template), shoes `#221c22` (default `pixel_character.gd:60`; `Npc.sprite()` never passes `f`).
- **Idle and emote.** Sway idle. Her notice emote is "!" (`:109`).
- **States.** She is RESTRICTED (greyed) at purge ≥ 1 (`:99-100`). She can be escorted (`npc.gd:79-91`), walking along Rue's crumbs at 60 px/s.
- **Floor.** `#2a2320` (`arins_room.gd:30`).

### 1.5 Wren: `village_square.gd:340-357`

- **Template.** `"child"`, **16×20 px**: the only short body. Pigtails at rows 2–3 and bare legs.
- **Palette.** Dress `#6a8f5a`, hair `#c9a04a`, dark `#4a6a3a`, skin `#e8c48a`, shoes `#221c22`.
- **Idle and emote.** Hop idle, and "!" notice.
- **Hiding.** `hide_radius 22` draws a faint cyan disc, α 0.05 (`npc.gd:185-186`). Rue crouches inside it.
- **Floors.** Grass `#1f2a1e` and path `#3a3128` (`village_square.gd:28-29`).

### 1.6 Tobben: `village_square.gd:148-159`

- **Template.** `"apron"`, **16×24 px**. Bald crown with a hair fringe on one side (row 1 `.hsssshh`), a moustache in accent (row 4), and a white apron `w = #d8d0c0` (`npc.gd:124`) over rows 6–9.
- **Palette.** Shirt `#7a5a8a`, hair and moustache `#bbbbbb`, skin `#e0b48a`, dark `#4a3a5a`, shoes `#221c22`.
- **Idle and emote.** Wave idle (he waves while Rue is within 70 px and he is not talking). His notice is "?".
- **Position.** He stands at the stall (`:148`), on grass.

### 1.7 The Archivist: `archive.gd:46-55`

- **Template.** `"robe"`, **16×30 px**: the tallest figure. Hair runs down into a beard (rows 4–5), and a floor-length robe with a 2-row dark hem ends in two shoe blocks rather than legs (`pixel_character.gd:254-257`).
- **Palette.** Robe `#3a4a6a`, hair and beard `#d8d8e0`, belt `#c8a040`. The hem is `#6b3a24`, the **unset `dark_color` default** (`npc.gd:20`), so the hem is brown under a blue robe. Shoes are `#221c22`, which is **identical to the Archive floor** `#221c22` (`archive.gd:18`). His name colour is cyan `#8cf2ff` (`:48`).
- **Idle and emote.** Read idle and "..." notice.

### 1.8 Pip: `scripts/world/companion.gd`

- **Shape.** Hand-drawn at ×1.5 (`:24`). Trotting, it is about **25×16 px** (x −10..7, y −10..1 in units). Asleep it is a curled heap of about **18×8 px** (`:114-123`).
- **Palette** (`:17-19`): orange `#e8833a`, dark `#6a3418` (legs, nose), white `#f4ead8` (chest, muzzle, tail tip), eye `(0.1,0.05,0.05)`.
- **Animation.**
  - waiting: a sleeping curl with a rising "z"
  - following: a 2-frame leg trot at 10 Hz, with the tail wagging at 9 Hz
  - standing: a sit pose, a 0.5 px bob and a slow tail (`:110-141`)
  - facing: a horizontal flip only (`:148-150`)
- **Reaction.** A yip "!" when Arin is within 85 px of Rue (`:97-104`, `:142-145`). It is drawn in the **same amber, same glyph and same 2×5 + 2×2 geometry as Rue's startle mark** (`player.gd:225-229`).
- **Hidden from the owner.** The narrative says the owner cannot see Pip, but nothing in the visuals shows this.

### 1.9 The real Arin (purged room): `arins_room.gd:264-272`

- **Template.** An `Npc` with the default `"adult"` template, at (320, 270) on floor `#2a2320`. Colours match the avatar: tunic `#5a7fb0`, dark `#2e3f5c`, belt `#c0392b`, hair `#2a2a30`, skin default `#e8c48a`.
- **Differences from the avatar.** Shoes are `#221c22` and eyes `#1a0c0c` (defaults, not the avatar's `#1a1a20`/`#101018`). Legs are `#2e3f5c` darkened 30% = `#202c40` (`npc.gd:124`).
- **Behaviour.** No cone, no idle style and no emote. It turns to watch Rue within 90 px. Its lines are `["..."]` (`:272`).

### 1.10 NPC states (shared, `scripts/world/npc.gd`)

| State | Visual |
|---|---|
| NORMAL | full colour (`:188-193`) |
| RESTRICTED | `grey` desaturated, but idle style continues (`:193`, `pixel_character.gd:301-303`) |
| frozen (FREEZE glitch) | pink and cyan silhouettes ±2 px plus grey body; all animation halts because `update()` is skipped (`:158-161`, `:189-193`) |
| emote | white bubble `(0.95,0.93,0.88)` with tail, dark glyph, 8 px font, pops and bobs, 1.6 s (`:206-215`) |
| DELETING (1.6 s) | convulsing RGB-split copies with `#e0704f` scan bars (0–0.45 s), then a 48-pixel colour burst falling under gravity, then static residue (`:220-242`) |
| DELETED | static residue plus a 16×h dashed outline in `#e0704f` α 0.35, with the label `"<id>.npc = null"` (`:257-261`) |
| restored | NORMAL plus 0.6 s frozen glitch look (`:98-106`) |

---

## Part 2: Readability evaluation

### 2.1 Contrast of each colour against the floor it stands on (WCAG ratio)

| Colour | Floor (hex) | Ratio | Verdict |
|---|---|---|---|
| Archivist shoes `#221c22` | Archive `#221c22` | **1.00** | invisible: the Archivist has no feet |
| Archivist robe `#3a4a6a` | Archive | 1.88 | the body mass barely reads; only the beard (11.8) and belt (6.8) stand out |
| Archivist hem `#6b3a24` | Archive | 1.79 | reads as a brown band, not as the robe |
| Arin hair `#2a2a30` | room 1.08, grass 1.05, path 1.12, house 1.07, Edge ≈1.3 | **≈1.1** | Arin's head top vanishes everywhere, so Arin reads as a skin blob on a blue body |
| Arin trousers / shoes `#2e3f5c` / `#1a1a20` | grass | 1.41 / 1.16 | **the step frames are invisible**; Arin's walk reads only through bounce and arms |
| Arin tunic `#5a7fb0` | grass / path | 3.62 / 3.09 | OK |
| Rue shoes `#3a2226` (restored) | room / grass | 1.06 / 1.02 | the restored walk loses its foot lift |
| Rue legs `#3d4e78` | grass | 1.82 | weak |
| Rue hair `#8a4f2c` | path | 1.96 | weak, so the cowlick (Rue's unique pixel) is lost on the path |
| Rue missing face `#05070a` | Edge / OOB | 1.01–1.0 | intended (void face), and it reads as a hole |
| Rue coat `#e9b44c` / missing coat `#8cf2ff` | all floors | 6.7–15.8 | excellent: Rue is always the brightest figure |
| Mira hair `#5a3420` | room `#2a2320` | 1.43 | her long-hair silhouette (her identifying shape) is lost; she reads as a face plus dress |
| Mira dress `#c9733e` | room | 4.42 | OK |
| Tobben shirt `#7a5a8a` | grass | 2.60 | weak, but the apron (9.7) and white hair (7.8) carry him |
| Wren dress / hair | grass | 4.04 / 6.11 | OK; the best-reading NPC |
| Pip orange `#e8833a` | room / grass / void | 5.7 / 5.5 / 7.5 | OK; the dark legs (1.5) vanish, so the trot is invisible |
| All NPC shoes `#221c22` | any floor | 1.0–1.3 | `Npc.sprite()` (`npc.gd:122-125`) never passes `f` |

The pattern: **every character's darkest key (hair, shoes, trousers) falls below 1.5:1 on these dark floors.** With no outline, the readable silhouette is the bright subset only. The two characters whose identity rests on a dark shape, **Arin (dark hair cap)** and **the Archivist (dark robe, tallest body)**, lose it.

### 2.2 Shared silhouettes (template IoU, bottom-aligned, legs included)

| Pair | IoU | Different pixels | Note |
|---|---|---|---|
| adult (Arin) / apron (Tobben) | 0.93 | 5 | almost identical outline |
| adult (Arin) / **rue** | **0.89** | **7** | same width, same height; Rue differs by the cowlick, no neck row, and the scarf end |
| adult / dress (Mira) | 0.89 | 8 | the hair flare at rows 2–4 is the only difference, and it is low-contrast (see 2.1) |
| rue / apron | 0.83 | 12 | |
| child (Wren) | 0.57–0.69 vs all | 21–33 | distinct (short) |
| robe (Archivist) | 0.54–0.59 vs all | 40–48 | distinct (tall), but most of the extra height is the low-contrast robe |

Four of the six humanoids (Rue, Arin, Mira, Tobben) share one 16×24 silhouette. They are told apart **by colour alone**.

### 2.3 Similar colours (ΔE76, main masses)

- **Rue's scarf `#d8463a` vs Arin's belt `#c0392b`: ΔE 7.2.** This is effectively the same red, worn by both protagonist-shaped figures in the torso band. The comment at `owner_avatar.gd:31` ("a red scarf") suggests the overlap may be deliberate (the owner's character echoes Rue's). If it is unintentional, it blurs the one accent that is uniquely Rue's.
- **Mira's dress `#c9733e` vs Pip `#e8833a`: ΔE 14.2.** These are close oranges. They rarely share a screen, except when Pip follows Rue into Arin's room or during Mira's escort.
- **Rue-missing `#8cf2ff` vs the cursor's cyan split `(0.3,0.9,1.0)`: ΔE 11.3.** By design (the "renderer" palette), but it is the owner's tool using Rue's colour. That conflicts with ART_DIRECTION's rule "never use cyan for an owner action" (`ART_DIRECTION.md:26`), and the selection box is cyan too (`owner_cursor.gd:178`).
- **Rue's own chromatic ghost, trail and tear edges are pink/magenta** (`player.gd:21`, `:213`, `:244`, `:255`), so the owner's colour is drawn on Rue every frame. The same rule says magenta is the owner's colour.
- **Archivist name colour `#8cf2ff`** is Rue's cyan. That fits (he helps Rue).
- Wren's hair `#c9a04a` vs Rue's coat `#e9b44c`: ΔE 12.7. They sit on different body parts, so this does not cause confusion.

### 2.4 Is Rue distinguishable from Arin?

**Yes, by colour, not by shape.** Rue's coat vs Arin's tunic is ΔE 92 when restored and ΔE 49 when missing (cyan vs mid-blue), and Arin always carries the cone. The silhouettes differ by only 7 template pixels, so the distinction weakens:

- in the **Edge** (tint `(0.85,0.9,1.0)`, `the_edge.gd:68`), where a cyan-blue Rue and blue Arin are both cool
- during **freeze**, when Arin is drawn grey with cyan and pink splits, much like Rue's own ghosting
- in the **overwritten** death, which turns Rue into Arin's blue (intended)
- at **5 memories** in the purged room, where the real Arin stands still with no cone and a red belt, and Rue wears a red scarf

### 2.5 Animations that imply something gameplay did not do

1. **Arin "waves" at you when it spots you.** `waving` oscillates the arm at 8 Hz (`pixel_character.gd:201-202`) and always lifts the screen-right arm, even when Arin faces left or away (no mirroring). The intent is "points at you" (`owner_avatar.gd:131`). What the player sees is a friendly greeting at the moment of greatest danger.
2. **The real Arin's mouth flaps while saying "..."**. `talking` is set for any open dialogue (`world.gd:234`, `npc.gd:163`), and its lines are only `"..."` (`arins_room.gd:272`). The animation shows speech; the text shows silence.
3. **Friendly "!" notice looks like Arin's spotted bubble.** Mira and Wren pop a white bubble with "!" (`npc.gd:206-215`, `arins_room.gd:109`, `village_square.gd:350`). Arin's "I see you" bubble is also white with "!" (`owner_avatar.gd:136-140`); only the glyph colour differs (dark vs orange, 8 px font). An NPC noticing Rue reads as an alarm, but neither Mira nor Wren raises awareness on notice.
4. **Pip's warning yip and Rue's own startle are the same glyph** (`companion.gd:142-145` vs `player.gd:225-229`). "Arin is near" (Pip's warning) and "the owner reacted" (an awareness threshold) cannot be told apart.
5. **The Archivist's book is drawn on his back.** The `read` book ignores `back` (`pixel_character.gd:221`) and stays up while talking. He turns to face Rue (`npc.gd:168-169`), so when Rue approaches from above he "reads" through his own back.
6. **Restricted (greyed) NPCs keep their cheerful idles.** Tobben still waves and Mira still sways (`npc.gd:175`, `pixel_character.gd:177`), although RESTRICTED means the owner has clamped them.
7. **The drag cursor looks identical to the hunting cursor** (`owner_cursor.gd:157-188`). Gameplay is in a different, non-lethal mode (`_select` is held at 0 during drags, `:109-114`), but nothing shows it.
8. **Rue's charge has no body response.** Holding E for up to a second (`glitch_controller.gd:84-99`) draws a ring, but the sprite stands idle, or walks if moving. This understates an action gameplay treats as costly.

---

## Part 3: DIRECTION (PROPOSED)

Everything below is **PROPOSED**. The two global rules first:

- **G1. Floor-relative minimum.** Every character's *identifying* shape must be drawn in keys with at least 1.5:1 contrast against its area floor, and its unique tell at 3:1. Dark keys (hair, shoes, trousers) are fine only if the identifying shape does not depend on them.
- **G2. Silhouette before palette.** At 16×24 px, every character in the same area must differ from Rue by at least about 12 template pixels of *visible* (≥1.5:1) outline, or carry a moving tell (scarf end, cone, book) that Rue lacks.
- **G3. Colour semantics** (from ART_DIRECTION). Cyan is Rue and help; magenta and red-orange are the owner; Arin's blue means being overwritten. Rue's red scarf is hers alone.

### 3.1 Rue

- **Silhouette.** Keep `"rue"` 16×24. The cowlick and the trailing scarf end are the signature shapes and must never be lost.
- **Proportions.** Head 5 rows to body 5 rows, slightly top-heavy, the "made by a kid" look.
- **Shape language.** Asymmetric (cowlick off-centre, scarf to one side), with soft corners. Everyone else is symmetric.
- **Colours.** Primary is the coat (yellow restored, cyan missing). Secondary is the scarf red `#d8463a`, Rue's alone. Lift the restored shoes `#3a2226` to about `#5a3a34` (≥1.5 on grass) so the foot lift reads.
- **Idle.** Weight on one leg, breathing, plus the existing glance → hug → shiver ladder. This is already the best-built character language in the game. Keep it.
- **Movement.** Quick and light. The 9 steps/s cadence is twitchy; cap Rue's walk rate at about 7 (`pixel_character.gd:112`) so it reads as hurrying, not vibrating.
- **Emotional tells.** Eyes (wide on startle, darting glances); arms (hug); scarf end (droops while still, streams while moving).
- **Corruption.** Tearing, jitter and dropped frames scale with instability (keep). Move the constant chromatic ghost toward cyan/white at low instability and let pink take over only as awareness rises, so magenta on Rue means "the owner is on you" (G3).
- **Unique tell.** The scarf end. It is the only secondary motion on any humanoid.
- **Smallest-resolution rule.** At 1× (8×12 effective), Rue must still show *the bright coat block plus one off-centre pixel on top plus one red pixel at the neck*.

### 3.2 Arin (avatar)

- **Silhouette.** `"adult"`, but with a visible head cap. Lift the hair to at least `#44405a` (1.5 on grass and room) or add a 1-row rim light on hair row 0. **No scarf** and no red accent near the neck.
- **Proportions.** Upright, symmetric, centred: a "default protagonist".
- **Shape language.** Square and regular. It is the owner's idealised character: no asymmetry, no secondary motion.
- **Colours.** Primary tunic `#5a7fb0`. Secondary: change the belt from red to a dark leather or navy (e.g. `#6b4a2a`) so red stays Rue's (G3). If the echo of Rue's scarf is a deliberate story beat, keep the red but document it in NARRATIVE_BIBLE §3.3.
- **Idle.** Stands square and turns its head toward the cone. At corners, a two-beat look left and right is already implied by the 0.6 s wait (`owner_avatar.gd:79`); reflect it with `look_at` toggling.
- **Movement.** Heavy and metronomic: about 4 steps/s, low pitch (already).
- **Emotional tells.** None. Arin has no inner life; the owner's intent is shown through the **cone** and the **point**.
- **Corruption.** None of its own. When stunned, it uses the existing split.
- **Unique tell.** The cone, plus a **static pointing arm** toward Rue when seeing (not a wave).
- **Smallest-resolution rule.** The blue block, the skin dot, and the cone must read. The cone carries Arin at any scale.

### 3.3 The owner / cursor

- **Silhouette.** The OS arrow (keep). It is the only black-outlined, white, non-pixel-art object, so it is foreign by construction.
- **Colours.** White with a black outline. Change the splits and selection box from cyan to owner red-orange `#e0704f` and magenta, per G3. Rue's colours should not appear on the owner's hand.
- **States.**
  - drift: slow, small split
  - track: crosshair lines
  - select: ants, whine
  - drag: switch to a **closed-hand or grab glyph** (or a dotted tether to the prop) so the player knows it is busy
  - blind: grey with static (keep)
- **Smallest-resolution rule.** It is always drawn at least 12×20 px. Never scale it below 1×.

### 3.4 Mira

- **Silhouette.** `"dress"`. The hair flare at rows 2–4 is her shape. Lift the hair to about `#7a4a2c` (≥1.9 on the room floor) so the long hair reads.
- **Colours.** Keep the dress `#c9733e`. Shift it slightly toward rose (e.g. `#c96a5a`) to pull it away from Pip's orange (ΔE 14).
- **Idle.** Sway (keep): a nervous, homebound person. When RESTRICTED, stop the sway and hold still.
- **Movement.** Escort at 60 px/s. Short steps with the head down (the sway stops while walking).
- **Tells.** A notice glyph that is *not* "!" (see top-5 #3), e.g. "?" for "you're not Arin".
- **Corruption.** The standard NPC deletion. When restored, a 0.6 s split (keep).
- **Smallest-resolution rule.** A warm block with a darker frame at the head sides.

### 3.5 Wren

- **Silhouette.** `"child"` 16×20 is the shortest body (keep). The pigtail pixels at row 3 are the tell.
- **Colours.** Keep. She is the best-contrasted NPC.
- **Idle.** Hop (keep), but suppress the hop while she is hiding Rue: her stillness should "cover" Rue. She could also hop toward Rue.
- **Tells.** The faint cyan hide disc (keep). Increase it to α 0.08 while Rue is actually inside it.
- **Smallest-resolution rule.** The short green block plus a gold top.

### 3.6 Tobben

- **Silhouette.** `"apron"`. The white apron block is his shape (keep). He shares 93% of Arin's outline, so the apron must stay ≥8:1.
- **Colours.** Keep the apron and white moustache. The shirt `#7a5a8a` is fine because the apron carries him.
- **Idle.** Wave (keep). Stop waving when RESTRICTED. After he reports you (`on_talk` → `_tobben_reports`), switch to arms folded (`hug`) as a guilty tell.
- **Smallest-resolution rule.** A pale vertical block with a grey top.

### 3.7 The Archivist

- **Silhouette.** `"robe"` 16×30, the tallest figure (keep). The height only counts if the robe reads, so lift the robe to `#4a5a80` (2.4:1 on the Archive floor), set `dark_color` to about `#3a4a6a` (blue hem), and give him visible feet (`#4a3a30` or lighter).
- **Colours.** Primary is the blue robe. Secondary is the white beard and gold belt `#c8a040`.
- **Idle.** Reading (keep). Hide the book when he faces away, and close it while talking (`talking`).
- **Unique tell.** The book.
- **Smallest-resolution rule.** A tall dark-blue column with a white top. Taller than Rue at a glance.

### 3.8 Pip

- **Silhouette.** A 25×16 horizontal fox. It is the only quadruped and the only horizontal shape (keep).
- **Colours.** Keep the orange and white. Lift the leg dark `#6a3418` to about `#8a4a28` so the trot reads (1.5 → about 2.2).
- **Idle.** Sit (keep). Add an ear flick every few seconds as a cheap "alive" tell.
- **Warning tell.** Do **not** reuse Rue's "!". Pip's alarm should be body language: ears up (+1 px), a stiff tail (tail wag 0), and a short crouch toward Arin. Optionally a different glyph (a small orange chevron).
- **Owner-invisible tell.** A very faint cyan rim or a 1-pixel shimmer offset, the same treatment Rue's missing data has, to show "this isn't in the save".
- **Smallest-resolution rule.** An orange horizontal bar plus a white tail tip.

### 3.9 The real Arin (purged room)

- **Silhouette.** Same as the avatar (it is Arin), but **without the cone and greyed** (RESTRICTED) or at α 0.8, so it reads as a remnant, not a threat.
- **Animation.** No mouth movement (it says "..."). Blink at half rate. Idle: the head turns toward Rue (keep).
- **Smallest-resolution rule.** Must not read as the avatar. The absence of the cone is the tell; greyed is safer.

### 3.10 Minimal animation-state set (only states gameplay already has)

| Character | State | Gameplay source | Visual (existing → proposed) |
|---|---|---|---|
| Rue | idle / walk | `velocity` (`player.gd:169`) | existing |
| Rue | hidden | `player.sheltered` (`world.gd:237`) | crouch (existing) |
| Rue | anxious (glance → hug → shiver) | `idle_time`, `instability` (`player.gd:187-198`) | existing |
| Rue | startle | awareness threshold (`owner_director.gd:183`) | existing |
| Rue | **charging** | `world.glitch.is_charging()` (`glitch_controller.gd:50`) | **new:** arms out (reuse the `waving` arm offset on both arms), scarf lifts |
| Rue | **targeted** | cursor `_select > 0` or Arin `_seeing` | **new:** hold `startled` eyes and glance toward the threat (no hop) |
| Rue | dissolve ×5 / restore flash | `world.kill`, `world.gd:117`, `:200` | existing |
| NPC | idle style / walk (escort) / talk | `npc.gd:156-175` | existing; mute for "..." speakers |
| NPC | notice | `_noticed` (`npc.gd:172-174`) | existing; distinct from Arin's alert |
| NPC | restricted | `State.RESTRICTED` | grey (existing) + **suppress idle style** |
| NPC | frozen / deleting / deleted / restored | `npc.gd:94-106`, `:176-180` | existing |
| Arin | patrol / corner look / lured | `owner_avatar.gd:56-88` | existing |
| Arin | **spot** | `_seeing` | cone brighten + bubble (existing) + **static point** (replaces wave) |
| Arin | stunned / paused | `stunned`, `paused` | existing |
| Cursor | arrive / drift / track / select / blind | `owner_cursor.gd` | existing; cyan → owner colours |
| Cursor | **drag** | `_drag_phase != ""` | **new:** grab glyph |
| Pip | sleep / trot / sit | `mode`, `_moving` | existing |
| Pip | warn | `_yip > 0` | **change:** ears and tail instead of Rue's "!" |

No other states are proposed (no run, attack or emotion states), because gameplay has no events to drive them.

### 3.11 Top 5 improvements (highest value, lowest risk)

1. **Arin points instead of waving.**
   - Where: `scripts/world/pixel_character.gd:69-70` (add `var pointing := false`) and `:197-203` (arm block).
   - Change: when `pointing`, lift the arm on the facing side (x=7 for RIGHT/DOWN, x=0 for LEFT) by a fixed −2 rows with no `sin()`.
   - Then: in `scripts/owner/owner_avatar.gd:131`, set `_sprite.pointing = _seeing` instead of `waving`.
   - Why: fixes a reversed emotional read at the most dangerous moment, with about 6 lines and no gameplay effect.
2. **Mute the real Arin (and any "..." speaker).**
   - Where: `scripts/world/npc.gd:163`.
   - Change: `s.talking = talking and not mute`, with a new `var mute := false` near `:29`, and set `arin.mute = true` at `scripts/world/areas/arins_room.gd:272`.
   - Why: removes a mouth that contradicts the text. Two lines, no risk.
3. **Separate friendly notice from hostile alert.**
   - Where: `scripts/world/npc.gd:213-215`, plus the notice glyphs at `scripts/world/areas/arins_room.gd:109` and `scripts/world/areas/village_square.gd:350`.
   - Change: draw NPC bubbles without the "!" glyph (use "?" or "♪" for Mira and Wren). Make Arin's bubble at `scripts/owner/owner_avatar.gd:139` owner-coloured (fill `VIEW_COL`, white "!").
   - Also: give Pip's yip its own shape at `scripts/world/companion.gd:142-145` (an ear-up pose, or a chevron instead of the 2×5 + 2×2 "!" shared with `player.gd:225-229`).
   - Why: "!" then means only "you are seen", which is what the gameplay means. Data-only and draw-only changes.
4. **Fix dark-on-dark pixels with palette-only edits.**
   - Archivist (`scripts/world/areas/archive.gd:49-54`): robe `#4a5a80`, add `dark_color = Color("3a4a6a")`.
   - NPC shoes: `scripts/world/npc.gd:122-125` should pass `"f"` (e.g. `dark_color.darkened(0.1)`) so shoes stop defaulting to `#221c22`, which equals the Archive floor.
   - Arin hair: `scripts/owner/owner_avatar.gd:11` and `scripts/world/areas/arins_room.gd:271` to about `#44405a`.
   - Mira hair: `scripts/world/areas/arins_room.gd:105-110`, set `hair_color` to about `#7a4a2c`.
   - Rue shoes: `scripts/player/player.gd:25` `"f"` to about `#5a3a34`.
   - Why: restores the Archivist's feet and height and Arin's head, and makes walk foot-lifts visible. Constants only, no logic.
5. **Rue shows she is targeted.**
   - Where: `scripts/player/player.gd:181-201` (`_update_mood`).
   - Change: add `var targeted := false`. When true, keep `_sprite.startled` at least 0.1 (wide eyes, no blink) and point `_sprite.glance` / `facing` toward the threat.
   - Set it in `scripts/world/world.gd:235-237` from `area.cursor._select > 0` or `area.arin._seeing`. Both are private, so expose two read-only getters in `owner_cursor.gd` and `owner_avatar.gd`.
   - Why: the character reacts to the threat the player must react to, which reinforces the selection box and the cone. It adds no new art and reuses existing flags.

**Honourable mentions** (one-liners):
- Hide the Archivist's book when his back is turned (`pixel_character.gd:221`, add `and not back`).
- Suppress idle styles when RESTRICTED (`npc.gd:175` and `sprite().idle_style`).
- Cap the walk rate at 7 (`pixel_character.gd:112`).
- Delete the unused `"intruder"` template (`pixel_character.gd:44-48`).
- Correct the "red scarf" comment (`owner_avatar.gd:31`).
