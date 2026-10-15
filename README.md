# The Last Save File

> You wake up inside someone else's save file.
> You are not supposed to be here.
> The owner has noticed.

**The Last Save File** is a small, tense, systemic game about being an intruder. You're a stray process
inside another player's save slot: their character's room, their NPCs, their notes to themselves.
The owner is still playing. They see you. And every time you die or quit, they learn something and
rewrite the world to get rid of you.

Built with **Godot 4.3+** and **GDScript**.

---

## The fantasy

- **You are not the protagonist.** The world belongs to someone else. The protagonist is *Arin*,
  the owner's character. NPCs call you by that name until they realize you're wrong.
- **The world is rewritten between sessions.** Doors get deleted. Notes change. NPCs who talked to
  you get removed. Every reload of the save is a slightly more hostile version of the last one.
- **Death and quitting are permanent.** The owner's memory lives *outside* the save slot. You can
  reload the world, but you can't reload the owner. Closing the game counts as a quit, and so does
  killing the process (it's treated as a crash, and the owner goes looking for your traces).
- **Atmosphere over combat.** You can't fight the owner. You can only move, read, talk, and slip
  through gaps they haven't written yet.

## Pillars

1. **Paranoia.** Things change when you aren't looking. The room is always watching.
2. **Systemic reactions.** Everything the owner does comes from a small set of rules driven by what
   they know (awareness, deaths, quits, escapes, where you died).
3. **Permanent consequences.** There is no clean reset for the intruder. Only for the owner.
4. **Readable dread.** Simple shapes, a tight palette, and a typed console voice do the heavy lifting.

---

## The current build

Five areas in five acts, six characters and a fox, one owner who's getting impatient, and one way
out. The whole story, as a readable script, is in **[docs/STORY_SCRIPT.md](docs/STORY_SCRIPT.md)**.

**Controls**

| Keyboard | Gamepad | Action |
| --- | --- | --- |
| WASD / Arrows | Left stick / D-pad | Move |
| E / Space | A | Tap: interact (read, talk, advance dialogue). **Hold: glitch** whatever is in the pink brackets (see [Glitches](#glitches)) |
| Esc | Start | Pause menu (Resume · Settings · Quit). Quitting counts, and the menu warns you first. |
| Hold F9 | | Wipe the owner's memory (debug / "new game") |
| F5 / F6 / F7 / F8 / F10 / F11 | | Debug (editor, debug builds, or the web build with `?debug=1`): all glitches · load last save · save over you · drag the crates · jump to Slot 2 · Wren joins you. Also under **Pause → Debug**, for phones. |

**On a phone or tablet** (in the browser): turn it sideways. Drag anywhere on the left side to
move (a joystick appears under your thumb), tap **E** (bottom right) to interact or advance text,
and **II** (top right) to pause. Menus are tapped directly. The controls appear as soon as you
touch the screen (`scripts/ui/touch_controls.gd`).

Menus work with mouse, keyboard or gamepad. **Settings** (title screen or pause menu) is in two
columns: *Sound* (master, music, effects), *Picture* (fullscreen, CRT curvature, screen effects),
*Comfort* (glitch intensity, reduce flashing, **large text**) and *Help* (**tutorial tips**), plus
*Reset owner memory* on the title screen. See [Visual effects](#visual-effects) and [Sound](#sound)
for exactly what each one controls.

**Getting started.** The first time you play, short tips appear one at a time under the top bar:
how to move, that the owner is watching (and what the bar means), that dying *and* quitting both
count, and that Wren will hide you in the village. Others appear the first time they matter: the
first thing you can interact with, the locked door, and the first time you're hidden. Each tip is
shown once ever; turn *Tutorial tips* off to skip them, or back on to see them all again
(`scripts/world/tutorial.gd`).

**Reading the screen.**
- *Top left:* the owner's save slot. *Top right:* **OWNER AWARENESS**, with ticks where the owner's
  next reactions start and, under the bar, what the owner is doing now (CALM, NOTICED, SUSPICIOUS,
  CONTAINING, SILENCING, HUNTING, PURGING). Under that, `HIDDEN · WREN covers you` while someone
  shelters you.
- *Bottom left:* the console, on a dark backing so it reads over anything: the owner in orange
  `> like this`, system text in grey, your thoughts in cyan `(like this)`.
- *Bottom right:* what you can do right now (`[E] talk`).
- *Pause menu:* your current goal, how many memories you've recovered, and a **Map** of the
  places you've found (where you are, and which memories each place still holds).
- *In the world:* **signs** at every way out (crossed out while it's closed), **corner brackets**
  around whatever `[E]` would act on, and, once you've found him, **Pip** running ahead toward
  what's next.
- *Act cards:* the first time you reach each act's area, its title card shows
  (*ACT III · OUT OF BOUNDS*).
- All HUD text has a dark outline and stays clear of the CRT's curved corners; **Large text**
  makes the HUD and menus 25% bigger (the console keeps one line fewer so it still fits).

**The world**

| Area | What's there |
| --- | --- |
| **Arin's Room** | Where you wake up. The owner watches it closely, so awareness rises fast. The door locks; Mira is deleted for talking to you. A **seam** tears open in the wall once the owner gets suspicious (40%): that's your way out, and agitating the owner on purpose opens it sooner. |
| **Ashvale · Village Square** | The owner's hub. **Arin** (the owner's character, driven by the owner) patrols around the well with a view cone: if Arin sees you, awareness climbs fast, and if Arin walks into you, you're overwritten. **Wren**, a child, hides you while you stand next to her, and while she does the owner loses track of you (awareness cools). **Tobben** the shopkeeper reports anything you say to him. A notice board, Arin's locked house, and a road north that isn't loaded. |
| **Out of Bounds · Below Ashvale** | Down the village well (*"they fell in the well once. it was funny."*). The underside of the map: the square hangs upside down overhead, collision boxes glow, debug labels float in the dark. The owner can't see here at all. There's no floor: only a few **anchor** platforms are solid, and chunks of floor stream in and out between them (they flicker red before they go). Step into the void and you drop back to where you came in. **Pip**, Rue's fox, is curled up on the far ledge next to a memory. A respawn pillar takes you back up. |
| **The Archive · Cut Content** | East of the square. The owner can't see in here: awareness slowly cools. **The Archivist** was cut before the game shipped, so the owner can't delete them; they give you a pointer to Slot 2 that opens the north road. The books are live logs of *your* history: every death (where and when), every deleted character, every patched seam. |
| **The Edge · Not Loaded** | North of the square. Missing textures, wireframe, debug labels, an eraser already running, and the owner's **cursor** reaching in. Hold still under it and you get selected and deleted. Somewhere out here is **Slot 2**: the last save file, with the cursor waiting beside it. Stand in it for 2.4 seconds to write yourself in and win, but the cursor selects anything that holds still for 1.1, so lead it away first. The eraser never touches the slot: the owner doesn't know it exists. |

**The owner's awareness** rises over time (fastest in Arin's room), and with what you do: being
seen by Arin (a glance under a third of a second is forgiven; a stare isn't), Tobben's reports,
touching the save crystal. It **cools** while Wren hides you and inside the Archive, but never below
the last threshold the owner has reacted to, so nothing the owner did gets undone. At each threshold the
owner acts on whatever area you're in:

| Awareness | The owner... |
| --- | --- |
| 25 | rewrites notes and notices, but only once you've walked away from them |
| 40 | flickers the lights and tears the wall of Arin's room; Arin walks faster |
| 50 | locks the door; Arin looks further |
| 65 | deletes whoever has been talking to you or hiding you |
| 75 | starts the eraser where you died before (and in the far corners, never on the roads out), and sends in the cursor |
| 100 | "hold still." Everything speeds up. |

**How the owner adapts (persisted across sessions)**

| You... | The owner... |
| --- | --- |
| Die | Remembers where and in which area. Your ghost marker stays, and the eraser starts there. |
| Were hidden by Wren, then died or quit | Deletes Wren for good. The Archive's books record it. |
| Used a seam, then died or quit | Patches that seam. (It never finds the last one.) |
| Quit (from the pause menu, or closing the window) | Notices. *"you closed the game. i didn't."* |
| Kill the process | Treats it as running away and counts it as a quit. **This includes the Stop button in the Godot editor**: quit from the pause menu instead, or hold F9 to reset. |
| Reach Slot 2 | Shows up on the title screen as a second save slot, and the owner opens the next session with *"there's a second slot. you hid in it."* |
| Anything | Starts the next session more aware (+10 per purge, never above 35), with the door gone, Mira restricted or removed, a darker world, and a faster Arin, cursor and eraser. All of them stay slower than you, so every session can still be won. |

Every death or quit adds one to **purge progress**. At **6/6** the owner wins: the save is clean,
the real Arin is back in the room, and you're gone. (Reset from the title screen's Settings, or
hold F9.)

The owner's memory is stored at `user://owner_memory.json`:

- Linux: `~/.local/share/godot/app_userdata/The Last Save File/`
- Windows: `%APPDATA%\Godot\app_userdata\The Last Save File\`
- macOS: `~/Library/Application Support/Godot/app_userdata/The Last Save File/`

---

## Glitches

Rue can corrupt the owner's reality. **Hold E** (or the E button on a phone) on whatever is in the
pink brackets: a ring charges around Rue, a buzz rises, and the glitch fires. A tap of E still just
interacts. **Every glitch costs awareness**: the cost flies up into the meter and the owner feels the
save twitch (and says so, the first time). Stronger glitches cost more. Four work from the start,
and each recovered memory unlocks one more (a big *NEW GLITCH* card says so).

The prompt names the price (`hold [E]  phase  +8`), and while you charge, the price shows as a
blinking pink ghost on the awareness meter, so you know what you're paying before you pay it. On a
phone the E button grows a dashed pink **HOLD** ring naming the glitch, which fills as you charge, and
the target brackets are bigger and bolder.

**The first glitch is taught by the first room.** The room's memory sits behind a thin partition
with a glowing crack in the corner by the bed; the guide points at it, and the first time you get
close a tip says to face the wall and hold E. Phase through, take the memory, and the partition
comes down (you're never shut in).

| Memories | Glitch | Cost | What it does |
| --- | --- | --- | --- |
| 0 | **Phase** | +8 | Facing a wall: slip through it (up to ~50 px). Out of bounds, it jumps gaps in the floor. Patched seams, crates, missing textures... |
| 0 | **Freeze** | +6 | Arin (or anyone) stops dead for 2 s: no moving, no seeing, no overwriting. |
| 0 | **Falsify** | +4 | A note or the notice board lies ("ALL CLEAR."): the owner relaxes and awareness rises far slower for 15 s. Tobben's report becomes a lie too. |
| 0 | **Unlock** | +10 | The locked door glitches open for 5 s: a second way out of Arin's room. |
| 1 | **Decoy** | +7 | Hold while running: leave a stale frame of yourself. Arin walks at it and the cursor selects it. |
| 2 | **Scrub** | +9 | Wipe the eraser's void back into floor around you. |
| 3 | **Blind** | +10 | The cursor goes grey and can't see you for 3 s. |
| 4 | **Restore** | +20 | Bring back someone the owner deleted, for good. |
| 5 | **Pause** | +15 | Hold standing still: the owner's world stops for 6 s (everything but Rue). |

The code is `scripts/player/glitch.gd` (definitions, costs, unlocks, owner reactions) and
`scripts/player/glitch_controller.gd` (hold, targeting, charging, firing, feedback).

## The owner's moves

The owner doesn't just watch; they play (`scripts/owner/owner_moves.gd`). None of this happens where
the owner can't see (the Archive, out of bounds).

| Move | When | What happens |
| --- | --- | --- |
| **Load Last Save** | Your 3rd glitch since the last reload (once noticed), or once at 65% | `◀◀ LOADING AUTOSAVE`: Rue is dragged back along her own path ~10 s, Arin and the cursor snap back, and every glitch effect is undone (freezes, blinds, lies, the glitched door, decoys). It never drops you into danger: it skips moments in the void, under the cursor or within Arin's reach, and afterwards the cursor loses you for a beat (Rue flickers) so you can see where you are. |
| **Saving Over You** | From the hunt, every ~35 s, or when you stand still too long under suspicion | A save ring fills over Rue: fast while you stand still, slowly while you move. **Any glitch interrupts it.** If it fills, you're overwritten. It never starts (and holds still) while you're writing yourself into Slot 2. |
| **Drag** | In the square during the hunt, when you head for a road | The cursor grabs the crate stack and drags it across that road. Phase through it, or wait for it to be dragged back. |
| **Route memory** | When a session ends badly | Where Arin saw you is remembered. Next time Arin's patrol detours through those spots (one more each session, up to three), and the owner tells you so. |

**Deaths explain themselves.** The death card says what got you (Arin walking through you, the
owner saving over you, the cursor's click, the static) and gives one yellow **TIP** line on what to
try next time. Once you have the glitch that answers that death, the tip names it instead
(`Story.DEATHS`).

## Wren, and the three endings

**Wren's escort.** Talk to Wren a few times and she asks to see the Edge before they delete her. A
choice: take her or not. Escorting her is risky: she's slow (she walks your exact footsteps at 2/3 your
speed), you can't leave an area until she catches up, Arin seeing her raises awareness, the owner
notices you faster, and from 40% on the owner tries to delete her (a red ring over her; any glitch
interrupts it). Lose her and she's gone for good. Get her to the Edge and she has her moment there:
she's logged as *cut content*, and the owner can never delete her again, in any future run.

**Slot 2.** When Rue finishes writing herself into Slot 2, the world freezes and you choose:

| Choice | Ending |
| --- | --- |
| **Write yourself in** (*Write RUE* once you remember) | Escape. With all five memories: the load menu, the owner's cursor hovering over `SLOT 2 · RUE`, and LOAD. Title: `SLOT 2 · RUE`. |
| **Give Slot 2 to Wren** (only if she's with you) | She gets a new game; Rue stays behind (and Pip goes with her). Title: `SLOT 2 · WREN · NEW GAME`. |
| **Leave the slot to the owner, with a message** (pick one of three) | The owner reads it and answers (differently by memories and message). The purge resets and everyone deleted comes back. Title: *"someone is waiting."* |

Each ending has its own epilogue, end card, title-screen aftermath, and what the owner says next time.
The full text is in [docs/STORY_SCRIPT.md](docs/STORY_SCRIPT.md).

## Characters & story

**Who are you?** The game opens on the save booting: `[!] 1 UNRECOGNISED ENTITY · ENTITY SLOT: 02
· slot 02 does not exist.` Then you assemble out of pixels in Arin's room: a small figure in
"missing texture" cyan, with a void for a face and two points of light, and no idea why you're here. Your own thoughts appear in
the console in cyan `(like this)`, reacting to waking up, to the town, to Arin, to the characters
the owner deletes because of you.

**Five acts.** *I · Someone Else's Save* (Arin's room), *II · Ashvale* (the square), *III · Out of
Bounds* (under the well), *IV · Cut Content* (the Archive), *V · The Last Save File* (the Edge),
then an **epilogue**: with all five memories, the load menu, and the owner's cursor hovering over
`SLOT 2 · RUE`... and pressing LOAD. If Pip came, Pip comes too.

**Memory fragments.** Five cyan shards float where something happened: under Arin's bed, out of
bounds beneath the well, between the Archive's shelves, and two at the Edge. Touching one stops the world for a short
letterboxed flashback, with the screen going pale and cyan like an old photo of a screen. Fragments
are *your* memories, not the owner's: they survive deaths and purges (only a full reset clears
them). Together they tell what happened: two people shared one console; one always played Arin in
slot 1, the other made their own character in slot 2. They drifted apart, and one night the owner
deleted slot 2. **You are what's left of that save.**

The world reacts to how much you remember:
- the Archivist counts the pieces of you they can see, and greets you by name once you have them all;
- Mira, Wren and Tobben each half-remember "the other one";
- the owner starts to recognise you (*"...you move like someone i used to know."*);
- the ending changes, and with all five the title screen shows `SLOT 2 · RUE`.

**Rue, coming back.** You are a real character: **Rue**, the one slot 2's player made (messy hair
with a cowlick, a red scarf that trails behind you, a yellow raincoat). Deleted, Rue loads with no
texture. Every memory you recover restores part of them, in order: the scarf, the hair, the coat,
the shoes, and last of all their face, each with a line of their own (*"a scarf. red. i picked that
colour myself."*). Restored colours aren't stable yet: when the owner's awareness is high they
flicker back to cyan for a frame.

Rue also has body language (`scripts/player/player.gd`):
- glances around and looks over their shoulder when standing still;
- hugs themself and shivers if left idle while the owner is on edge;
- ducks down while someone hides them;
- jumps with wide eyes and a `!` whenever the owner reacts (each awareness threshold);
- thinks out loud at new moments: being hidden for the first time, standing still too long.

All narrative text lives in `scripts/story/story.gd`, with the full story in its header comment.

**Characters.** Everyone is code-drawn pixel art (`scripts/world/pixel_character.gd`): 8-pixel
templates drawn at 2x, with a 4-frame walk cycle, swinging arms, breathing, blinking, a mouth that
moves while they talk, facing in four directions, and speech-bubble emotes. Each has a personality
in motion:

| Character | Look | Moves |
| --- | --- | --- |
| Rue (you) | Messy hair, red scarf, yellow raincoat, restored part by part from missing-texture cyan | Walk cycle, a scarf that streams behind, glances, hugging, ducking, startles, plus trail, tearing slices, dropped frames |
| Mira | Long hair, orange dress | Sways, turns to watch you, `!` when she notices you |
| Arin | Blue tunic, red scarf | Patrols with a walk cycle, points at you when they see you |
| Wren | Child, pigtails, green dress | Hops in place, `!` |
| Tobben | Bald, moustache, apron | Waves you over, `?` |
| The Archivist | Tall, white beard, robe | Reads a book and turns the pages, `...` |
| Pip | A small orange fox with a white-tipped tail | Asleep out of bounds until found. Then follows you everywhere, every session, through walls; trots ahead toward the next memory or the way on; yips `!` when Arin is close. The owner can't see Pip. |

## Visual effects

Everything is still coloured rectangles; the atmosphere comes from one full-screen shader
(`shaders/save_corruption.gdshader`), one controller (`scripts/fx/screen_fx.gd`) and a handful of
effects drawn in the world. Only 3 texture reads per pixel, so it stays cheap in the browser too.

**The screen.** Curved CRT glass with a soft bezel, one scanline per game pixel row, an RGB
aperture grille, a faint refresh band rolling down, radial chromatic aberration (stronger at the
edges), and animated grain.

**Awareness drives the look.** `OwnerDirector` feeds awareness into `ScreenFx.awareness_target`,
eased so the screen *slides* into sickness rather than jumping:

| Awareness | What the screen does |
| --- | --- |
| low | Clean-ish CRT. Rare background twitches. |
| rising | Colour drains and tints red/magenta. Fringing widens. Vignette closes in. |
| 35%+ | Background tearing starts; a thin tear line sweeps down the screen. |
| high | The image breathes and wobbles row by row; the world layer jitters and skews (the HUD doesn't); brightness flickers; the player's trail and body-tearing intensify. |
| each threshold | A jolt: tearing spike, vertical-hold slip, red wash, world shake, the meter flinches. |

**Events.**

| Event | Effect |
| --- | --- |
| Character deleted | Body convulses in split colour, bursts into a spray of pixels in its own palette, leaves crawling static and a `name.npc = null` outline. Magenta wash and shake. |
| Cursor arrives | Heavy static, thin bright "whine" lines, vertical roll; the pointer materialises huge and shrinks into the world with red/cyan afterimages. While tracking it draws scan lines through itself; while selecting, marching ants close in and static builds on the whole screen. |
| Eraser | New cells: red strobing frame with a black core that grows until the cell is lethal. Settled cells: void with baked red grain, a burning dark-red bite edge, crawling static, occasional scar lines. Starting it floods the screen dark red. |
| Wall seam | Opens as a pulsing wound: red glow bleeding into the room, ragged edges, a white-hot core, leaking pixels. Patched seams from earlier sessions stay as stitched, faintly pulsing scars. |
| Entering the Edge | Big tear and roll; then a cold, colourless picture with rows of unloaded data flickering through. |
| Death: ERASED | The screen is eaten in blocks, red at the bite, while the player is eaten from the feet up. |
| Death: OVERWRITTEN | Rows smear sideways under a wash of Arin's blue as Arin's colours sweep down over the player. |
| Death: SELECTED · DELETED | Negative flashes, static, a selection box snaps shut and the player scatters into pixels. |
| Win (Slot 2) | Cyan flood, the player is pulled up into a streak, the tube collapses to a line and springs back... and a magenta flicker keeps coming back afterwards. |
| Quitting | The picture powers off like an old CRT. |

Death titles shake with colour-split ghosts and keep corrupting themselves; owner messages type
in as garbage that resolves into words, carry a cyan shadow, and corrupt themselves later (more
often the more aware the owner is). The awareness meter is segmented, beats like a pulse that
quickens as it fills, shifts orange → red → magenta, misfires, and its label changes to
`OWNER IS WATCHING` and `OWNER IS HERE`.

**Controls (Settings).** All applied in `ScreenFx`, so they cover every effect:

- **Glitch intensity** (0–1) scales all distortion: tearing, aberration, sickness, block glitches,
  world jitter and shake, player tearing and trail, text corruption. At 0 you get a calm CRT.
- **Reduce flashing** cuts colour washes, negative flashes, static bursts, brightness flicker,
  strobing and screen roll to about 30%.
- **CRT curvature** flattens the glass.
- **Screen effects** (Full / Light / Off) trades the CRT pass for speed on weak GPUs; see Performance.

**Tuning.** Every shader uniform is documented at the top of the shader; event strengths and
durations live in the event methods of `screen_fx.gd` (`threshold_pulse()`, `deletion_hit()`,
`cursor_arrives()`, `play_death()`, `play_win()`, ...).

## Balance

Tuned with a playtest bot that walks the real route with real input and collisions at every purge
level (0 to 5), in two styles: a careful player taking the direct route, and a curious one who reads
everything, talks to everyone and wanders the square. What it found, and what changed:

| Problem the bot found | Fix |
| --- | --- |
| At the hunt, the square's eraser seeded *on* the north road and the path to the Archive: it walled off the exits instead of chasing you. Most deaths came from walking into a sealed exit. | Hunt seeds moved to the far corners; the eraser now chases you. |
| Death spiral: each death added +15 starting awareness and +0.25/s. From purge 3 the square hit 100% before you could cross it once. | +10 start (capped at 35) and +0.15/s per purge. |
| At purge 5, Arin (85 px/s) and the cursor (up to 117) were as fast as you (90) or faster: escape was impossible. | Arin 38 + 4/purge, cursors 48 + 5/purge with smaller boosts; the Edge cursor is capped at 62. |
| A split-second glimpse by Arin cost ~17 awareness, and awareness never went down: hiding only paused it. | 0.35 s grace before Arin's sight counts (then 22/s); hiding with Wren and the Archive cool awareness, down to the last threshold reached. |
| After the first session (no door to trigger) you waited ~27 s in the first room for the wall to open. | The seam opens at 40% instead of 50%, and a tip says the walls change when the owner gets suspicious. |
| The finale was a 5-second sprint nothing could stop, even at 100%. | Slot 2 takes 2.4 s of standing still to write yourself in, and the cursor waits beside it: lure it away, then sprint back. The eraser can't touch the slot. |
| Nothing told you that Arin's touch kills. | New tips: Arin, the Archive as a safe place, and how Slot 2 works. |

Result: the careful bot now wins at every purge level (arriving at the Edge at 78% awareness on
purge 0 and 100% on purge 5); the curious bot survives exploring at purge 0 and 2 and dies at purge 4,
standing still to read while the cursor hunts. Early sessions forgive curiosity; later ones demand care.

Tuning lives in `OwnerDirector` (rates, start, cooling), `VillageSquare` (Arin, sight grace, hunt
seeds), `TheEdge` (cursor), `SlotTwo.WRITE_TIME` and `Area.start_erasure()` (eraser speed).

## Sound

There are no audio files. Every sound is synthesised from code when the game starts
(`scripts/audio/synth.gd`: oscillators, filtered noise, crackle, bit-crushing, gating), rendered
once into an `AudioStreamWAV` and cached. `Sfx.prewarm()` builds them a few at a time on the title
screen (about 6 ms of work per frame), so the first death never hitches. All of it together takes
about half a second of CPU, once.

**Buses.** `Sfx` (`scripts/autoload/sfx.gd`) creates four buses under Master:

| Bus | What's on it | Volume slider |
| --- | --- | --- |
| Music | The drone and its layers | Music |
| Memory | The flashback melody | Music |
| SFX | Everything in the world (small reverb, plus a low-pass used for muffling) | Effects |
| UI | Menu sounds (keep playing while paused) | Effects |

**What makes a sound.**

| Event | Sound |
| --- | --- |
| The owner types in the console | The owner *speaks*: a low, slightly detuned voice blip per letter, its pitch following the letters (Undertale-style). System text is a thin teletype tick; your own thoughts are a soft breath of a note. |
| Dialogue | A voice blip per letter, pitched per character (Wren high, Tobben low, the Archivist lowest). |
| Character deleted | A unique sound per character, in their own pitch and timbre: a convulsion in their voice, a burst, a falling sweep, a thud, then static that won't stop for a moment. |
| Eraser | The floor groans and the room sags when it starts; a crackle per cell turning to void (rate-limited). |
| Cursor | A piercing whine on static as it reaches in; while hovering, a pulsing tone that rises with how close it is to clicking; then a plastic, final click. |
| Deaths | Three variants: *erased* (crunching down into nothing, coarser as it goes), *overwritten* (a storm of data writing over you, then a slam), *selected* (a double click, a falling error chime, scattering glass). |
| Wall seam | The wall tearing open; seams the owner patched since last session are heard being stitched shut. |
| Awareness thresholds | A reversed swell into a hit, lower and louder the higher awareness is. Arin spotting you is a sour two-note stab. |
| Purge / quitting | A low, inharmonic bell after the owner's intro once purge has started: something is counting. Quitting is a CRT powering off. |
| Slot 2 | A rising arpeggio into a warm chord... with one note that's wrong. |
| Memory fragment | A reversed shimmer resolving into a glass chime; the flashback muffles the world and plays the music-box theme with this memory's new layer. |
| Glitches | A buzz rising while you charge, then reality crunching and skipping; slipping through a wall is a reversed whoosh; a new glitch learned is a bright, broken arpeggio; PAUSE sags the world to a halt and lurches it back. |
| The owner's moves | The reload: a rewind roar; saving over you: disk ticks that speed up; dragging: a click and a heavy drop. |
| Small things | Footsteps, door lock, denied save, rewritten note, light flicker, emotes, area transitions, the Edge unloading. |
| Menus | Quiet, diegetic: move, confirm, back, and a muffled world while paused. |

**The theme** (`scripts/audio/music_box.gd`). One melody, a fragile music box in A minor, that
grows with Rue's memories: two notes with none; then the first phrase, the answering phrase (left
hanging on the leading tone), a bass line, a high countermelody, and with all five it finally
resolves, to A major. It plays in every flashback (with the new layer), quietly on the title screen
(so your progress is audible there), and through every epilogue (complete only in the true ending).

**Area beds** (`scripts/fx/ambience.gd`, Music bus): Ashvale has wind, birds and distant voices
that thin with every character the owner deletes (and the birds go quiet during the hunt); the
Archive hums and pages turn somewhere in the stacks; the Edge plays the theme **backwards**, slowed;
out of bounds plays it **upside down** (every interval mirrored) at half speed over thin air.

**Positional sound.** The listener is on Rue: Arin's heavy footsteps pan and fade with distance
(you can hear which side Arin is coming from), and the cursor has a hum that grows as it closes in.

**The drone** (`scripts/fx/drone.gd`) is layered and follows awareness:

| Layer | When |
| --- | --- |
| Hum | Always: two low sines beating against each other. |
| Dread | From ~25%: a dissonant, breathing pad. |
| Shimmer | From ~55%, and always a little in the Edge: a thin whine over hiss. |
| Heartbeat | From 65%: 55 bpm rising to 125. |
| Crackle | Random digital crackle, more often as awareness rises. |

**Settings.** *Master / Music / Effects* sliders drive the buses. *Glitch intensity* and *Reduce
flashing* also tame the audio: harsh sounds (deletions, the eraser, the cursor, deaths, stingers,
shimmer, crackle) are scaled by `Sfx.harshness()` (45-100% with glitch intensity, halved with reduce
flashing), and glitchy ticks (eraser cells, flicker) fade out almost completely at zero glitch.

**Tuning.** Each sound is one recipe in `Sfx._build()`; its loudness is in `Sfx.LEVEL` (dB), and the
`HARSH` / `GLITCHY` lists decide which settings soften it. To add a sound, add a `match` branch in
`_build()`, a level, optionally a `PREWARM` entry, and call `Sfx.play("name")`. `test_audio.gd`
checks that every sound renders, is audible and builds in under 250 ms
(`tests/run.sh --filter=test_audio --verbose-audio` prints the build times).

## Performance

Measured in Godot 4.3 with the frame cap removed (headless, so this is all CPU work: scripts plus
building draw commands):

| Scene | CPU per frame |
| --- | --- |
| Arin's room | ~0.3 ms |
| Square (Arin, Wren, Tobben) | ~0.4 ms |
| Square, fully erased, cursor hunting | ~0.5 ms |
| The Edge | ~0.5 ms |
| Archive | ~0.3 ms |

The eraser draws settled cells on a layer that only redraws when a cell settles and grows from a
tracked frontier; the background hum is synthesised once at startup (~15 ms) and looped; the HUD only
re-shapes text when it changes. A soak test (40 area changes, repeated deaths) shows no node,
resource or object leaks, and the project has no GDScript warnings even with warnings-as-errors.

Most of the cost is on the **GPU**: one full-screen CRT pass at window resolution. Settings →
**Screen effects** picks how much of it runs:

| Screen effects | What you get | Relative GPU cost* |
| --- | --- | --- |
| Full (default) | Everything: 3-tap colour fringing, aperture grille, static lines | 100% |
| Light (default on phones) | Same CRT look with 1 texture read, no fringing or grille | ~70% |
| Off | No full-screen pass at all | ~30% |

*Frame time on a software GPU at 1280x720; real GPUs are far faster, the proportions are what matter.

## Playing it

### Just play (no Godot needed)

Every push to `main` builds the game automatically (see `.github/workflows/build.yml`):

1. Open the repo's **Actions** tab, then the latest green **Build game** run.
2. Under **Artifacts**, download **TheLastSaveFile-windows** (or `-linux` / `-web`).
3. Unzip and run `TheLastSaveFile.exe`. Windows SmartScreen may warn because the game isn't
   signed: click **More info → Run anyway**.

Tagging a version (`git tag v0.2.0 && git push --tags`) also publishes the zips on a **Release** page.

**Optional: play in the browser.** Under *Settings → Pages* set *Source* to **GitHub Actions**, then
under *Settings → Secrets and variables → Actions → Variables* add `ENABLE_PAGES` = `true`. The
next push deploys the web build to `https://<user>.github.io/The-Last-Save-File/`.

### From the Godot editor

1. Install [Godot 4.3+](https://godotengine.org/download) (standard build, no .NET needed).
2. Open Godot, choose **Import**, and select this folder's `project.godot`.
3. Press **F5**.

Building locally: install the 4.3 export templates (*Editor → Manage Export Templates*), then
*Project → Export…* and use one of the presets (Windows Desktop, Linux, Web).

From the command line:

```bash
godot --path .            # play
godot --path . --editor   # open the editor
```

There are no external assets yet. All visuals are drawn in code, the hum is synthesized at runtime,
and the CRT/corruption look is a single screen shader.

## Tests

The suite lives in `tests/` and runs headless in about 1.5 minutes. CI runs it on every push and
pull request **before** building; a failing test or any Godot script error blocks the build and
the web deploy.

```bash
tests/run.sh                         # everything (uses `godot` on PATH)
GODOT=/path/to/godot tests/run.sh    # a specific Godot 4.3 binary
tests/run.sh --filter=story          # only files/methods matching "story"
# Screenshots of the effects (needs a display, so not headless):
godot --path . -s res://tests/run_tests.gd -- --test-mode --screenshots=/tmp/shots
```

Tests run with `--test-mode`, which points the owner's memory and the settings at separate
`test_*` files, so running them never touches your real progress.

| File | Covers |
| --- | --- |
| `test_memory.gd` | What the owner learns: deaths, quits, crashes, helpers, seams, fragments, purge, old-save migration |
| `test_world.gd` | The full route: seam, door, dialogue, Wren hiding (and being deleted), Tobben reporting, the pointer, the Edge, Slot 2, the hunt |
| `test_menus.gd` | Pause/resume, quitting counts, Slot 2 on the title screen, settings |
| `test_story.gd` | Boot sequence, flashbacks, fragments persisting, endings |
| `test_effects.gd` | Every death style, owner events, the win sequence, reduce flashing |
| `test_performance.gd` | Worst-case frame budget (fully hunted square) and leak checks across area changes |
| `test_glitch.gd` | Tap still interacts; every glitch (freeze, falsify, unlock, phase, decoy, pause, restore, blind, scrub), its cost and its unlock |
| `test_owner_moves.gd` | Load last save (and what it undoes), the 3-glitch reload, saving over you (and a glitch interrupting it), no moves where the owner can't see, the crates dragged across the road, Arin's route memory, debug tools |
| `test_wren.gd` | Wren asks, comes along and follows; declining; the leash; reaching the Edge saves her for good; the owner deleting her; a glitch saving her |
| `test_endings.gd` | The Slot 2 choice (two or three options), the escape, Wren and message endings, and the title aftermath |
| `test_fairness.gd` | Reloads skip moments next to the cursor or Arin and give you a beat; no save-over while writing Slot 2; death cards explain the cause with a tip (naming the glitch once you have it); the first room teaches PHASE; the cost preview and the phone HOLD ring |
| `test_touch.gd` | Phone controls with real touch events: dragging walks, the E button talks, the II button pauses |
| `test_expansion.gd` | The well, Out of Bounds (cooling, falling back, anchors and streaming floor), finding Pip and Pip staying, Pip leading the way, act cards, focus brackets, the map, the epilogue |
| `test_onboarding.gd` | Tips appear in order and only once, can be turned off and replayed; the HIDDEN status; large text; the pause menu's goal |
| `test_character.gd` | Rue starts as missing texture, each fragment restores the right part, Rue startles at thresholds |
| `test_audio.gd` | Every sound renders, is audible and builds fast; loops loop; buses follow the volume sliders; accessibility softens harsh sounds; the drone follows awareness; gameplay events make their sounds; the theme grows with memories (and plays backwards / inverted); area beds thin as characters are deleted; positional steps; the owner's voice |

Writing a test: add `tests/test_<thing>.gd` extending `res://tests/test_case.gd` and give it
`test_*` methods. They're coroutines, so you can `await start_session()`, `go_to()`, `press()`,
`interact_with()`, `wait_until()`; record problems with `check()` / `check_eq()`.

## Project structure

```
project.godot                  Engine config (640x360 viewport, GL Compatibility renderer)
export_presets.cfg             Windows / Linux / Web export presets
.github/workflows/build.yml    CI: runs the tests, exports all three on every push, releases on tags
docs/STORY_SCRIPT.md           The whole story as a script
tests/                         Automated test suite (run.sh, run_tests.gd, test_*.gd)
scenes/
  title.tscn                   Title screen (main scene)
  main.tscn                    The session: World, player, owner director, HUD, screen FX, drone
  player.tscn                  The intruder
scripts/
  autoload/owner_memory.gd     What the owner knows. Persists outside the save. Registers input.
  autoload/settings.gd         Player preferences (user://settings.cfg), button glyphs
  world/world.gd               Loads areas, transitions, talking, death / quit / win, purge ending
  world/areas/area.gd          Base class: walls with gaps, exits, NPCs, readables, the eraser
  world/areas/arins_room.gd    Start area: door, note, Mira, save crystal, seams
  world/areas/village_square.gd  Arin's patrol, Wren, Tobben, notice board, roads east and north
  world/areas/archive.gd       The Archivist and the live log books
  world/areas/the_edge.gd      Unloaded region, cursor, Slot 2
  world/npc.gd                 Any character: sprite, emotes, dialogue provider, hiding, deletion
  world/pixel_character.gd     Code-drawn pixel-art bodies and their animation
  world/memory_fragment.gd     The cyan shards of your past
  story/story.gd               Boot text, inner voice, the five fragments, endings
  world/readable.gd            Books, signs, terminals
  world/exit.gd                Area-to-area exits (open or blocked with a reason)
  world/slot_two.gd            The last save file
  world/door.gd, note.gd, save_point.gd, seam.gd, ghost_marker.gd
  world/tutorial.gd            First-session tips (once each; Settings > Tutorial tips)
  world/areas/out_of_bounds.gd Act III: under the well, anchors and streaming floor, Pip's ledge
  world/companion.gd           Pip: follows you, leads the way, warns about Arin
  world/passage.gd             Ways you take on purpose: into the well, back up the respawn pillar
  world/exit_sign.gd, focus_marker.gd   Signs at exits; brackets on what [E] acts on
  world/drag_prop.gd           The crate stack the cursor can drag across a road
  world/cracked_wall.gd        The first room's thin partition: the first PHASE
  player/glitch.gd             The glitches: costs, hold times, unlocks, the owner's reactions
  player/glitch_controller.gd  Hold [E]: targeting, charging, firing, feedback
  player/decoy.gd, fx/glitch_burst.gd   DECOY's stale frame; what a glitch looks like where it lands
  owner/owner_moves.gd         The owner's moves: load last save, saving over you, drag, route memory, deleting Wren
  audio/music_box.gd           The growing theme (and its reversed / inverted versions)
  fx/ambience.gd               Each area's sound bed
  ui/map_view.gd               The pause menu's map
  owner/owner_director.gd      Awareness, thresholds, the owner's voice; areas react to thresholds
  owner/owner_avatar.gd        Arin, driven by the owner: patrol route and view cone
  owner/owner_cursor.gd        The owner's mouse pointer: hunts and selects
  owner/erasure.gd             The eraser: a grid of overwritten cells that hunts you
  player/player.gd             Rue: movement, restored colours, body language, glitches
  ui/hud.gd                    Save-slot header, awareness meter, status line, console, tips, dialogue, fades
  ui/title.gd, pause_menu.gd, settings_panel.gd, ui_style.gd
  fx/screen_fx.gd              The screen: awareness look, event effects, world shake, settings
  ui/awareness_meter.gd        The living OWNER AWARENESS bar
  fx/drone.gd                  Layered ambient drone that follows awareness
  autoload/sfx.gd              Every sound effect: recipes, buses, pooled players, settings
  audio/synth.gd               The tiny offline synthesiser the sounds are rendered with
shaders/
  save_corruption.gdshader     CRT glass, scanlines, grille, aberration, sickness, tearing, deaths
```

**Architecture:** `OwnerMemory` (persistent) → `World` loads one `Area` at a time and builds it from
that memory → `OwnerDirector` raises awareness and tells the current area when a threshold is
crossed → deaths, quits, helpers and wins flow back into `OwnerMemory`.

**Adding an area:** subclass `Area`, set `area_id`, `bounds`, `entries` and `awareness_rate` in
`_init()`, build the layout in `build()` with `add_boundary()`, `add_solid()`, `add_exit()`,
`add_npc()` and `add_readable()`, react in `on_owner_event()`, and register it in
`World._make_area()`.

---

## Where this could go next

- **More out-of-bounds places**: under the Archive, behind the Edge's missing textures.
- **Life after Slot 2**: playing *from* Slot 2, a save the owner is now hunting for.
- **The owner's habits**: they learn your *routes* as well as your death spots, and pre-place
  erasure, locked doors and watchers along the paths you favor.
- **More characters with loyalties**: someone who trades secrets with the owner, someone who
  forgets you every session, NPCs who remember what happened to Wren.
- **Save-file UI as terrain**: the inventory, the map screen and the load menu as spaces you can
  physically enter.
- **More owner presence**: dragging props around, dialog boxes that open on their own, a
  "Delete save?" prompt you have to stop.

## License

TBD.
