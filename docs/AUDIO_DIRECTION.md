# THE LAST SAVE FILE — Audio Direction

> **Status (2026-10-16):**
> - **Implemented:**
>   - A Voice bus (own volume slider, own player pool).
>   - Per-character voice profiles (`Sfx.VOICE_PROFILES`) for Mira, Wren, Tobben, the Archivist and Pip.
>   - Rue's motif grows from 2 to 5 notes with her memories (`Sfx.RUE_MOTIF`).
>   - The owner's voice clips at high suspicion (`Sfx.owner_strain`).
>   - The heartbeat moved to SFX.
>   - In-world themes are capped below the RUE ending's resolved level.
>   - Deletion sounds are prewarmed.
> - **Not listened to by a person.** Web audio unlock is still unverified.

Status: 2026-10-16. Godot 4.3, GL Compatibility, every sound synthesised in code (no audio files).
Parts 1–2 describe **what the code does now** (cited `file:line`). Part 3 lists **confirmed problems**.
Parts 4–6 are **design proposals**: everything there is PROPOSED unless marked EXISTS.

Short file keys: `sfx` = scripts/autoload/sfx.gd · `amb` = scripts/fx/ambience.gd · `drone` = scripts/fx/drone.gd ·
`mb` = scripts/audio/music_box.gd · `set` = scripts/autoload/settings.gd · `W` = scripts/world/world.gd ·
`hud` = scripts/ui/hud.gd · `vs` = scripts/world/areas/village_square.gd · `OD` = scripts/owner/owner_director.gd ·
`OMv` = scripts/owner/owner_moves.gd · `cur` = scripts/owner/owner_cursor.gd · `av` = scripts/owner/owner_avatar.gd.

---

## 1. Current state

### 1.1 Bus layout

There is **no `default_bus_layout.tres`** and `project.godot` has no `[audio]` section. Buses are
created at runtime by `sfx._make_buses()` (sfx:273-294); autoload order OwnerMemory → Sfx → Settings
(project.godot:21-23) guarantees they exist before `Settings.apply()` runs (set:45-50).

| Bus | Created | Effects | Volume source | What actually plays on it |
| --- | --- | --- | --- | --- |
| Master (0) | engine | – | `Settings.volume` (set:126-127) | everything |
| **Music** | sfx:274-280 | low-pass 700 Hz, off by default (sfx:288-294) | `music_volume` (set:128-129) | Drone hum + dread + shimmer + **heartbeat** + crackle (drone:34, 39, 97, 103); every area bed and theme (amb:49); square birds/murmurs and archive page turns (amb:91, 93, 96 pass `"Music"`); title theme (title.gd:33) |
| **Memory** | sfx:274-280 | none (never muffled) | `music_volume` (set:128-129) | flashback music box (W:172-179); ending theme (W:1022-1029); guestbook two-note scene (vs:400-404) |
| **SFX** | sfx:274-280 | reverb (room 0.55, wet 0.12) at slot 0, low-pass at slot 1 (sfx:281-294) | `sfx_volume` (set:130-131) | default bus of `Sfx.play()` (sfx:148): all one-shots — deaths, stingers, `spotted`, cursor click, save ticks, deletions, steps, glitches, typing, **all voice blips** (owner + NPC) ; loop players (sfx:235: cursor whine, glitch charge); positional players (cur:49 cursor hum; av:103 Arin's steps) |
| **UI** | sfx:274-280 | none | **`sfx_volume`** (set:130-131) | 4-player pool, `PROCESS_MODE_ALWAYS` (sfx:82-87), via `Sfx.ui()` (sfx:176-177): menu move/confirm/back, pause click |

`Sfx.muffle(on, cutoff)` (sfx:244-248) toggles the low-pass on **Music and SFX** (index 1 on SFX, 0 on
Music). Called by the pause menu (pause_menu.gd:92, 99) and flashbacks (W:171, 184 at 500 Hz).

Settings slider labels: "Master", "Music", "Effects" (settings_panel.gd:29-31). There is no Voice,
Ambience or UI slider.

### 1.2 Volume settings and persistence

- Linear 0..1: `volume` 0.8, `music_volume` 0.8, `sfx_volume` 0.9 (set:13-15).
- Applied as `linear_to_db`, and the bus is hard-muted at ≤ 0.001 (set:140-145).
- **Persisted** to `user://settings.cfg` section `[audio]` on every change (set:116-122, 148-151) and
  loaded/clamped at start (set:172-174). Test mode uses a separate file (set:9, 47-48).
- Accessibility affecting audio: `Sfx.harshness()` = lerp(0.45, 1, glitch_intensity), halved by
  Reduce flashing (sfx:252-256), applied to the `HARSH` list (sfx:41-43); `GLITCHY` sounds scale
  straight with glitch intensity (sfx:45, 156-157). Drone shimmer/crackle (drone:52, 66), cursor whine
  and hum (cur:53, 136) and glitch charge (glitch_controller.gd:95) also follow `harshness()`. A sound
  whose gain falls below 0.01 is skipped entirely (sfx:158-159).

### 1.3 Generation and caching

- `Synth` (scripts/audio/synth.gd) renders `PackedFloat32Array` buffers → `AudioStreamWAV`;
  default 22 050 Hz, low beds at 11 025 Hz, music box at 8 000 Hz (mb:17).
- **Sfx cache**: `_cache` dict, built lazily on first `stream(name)` (sfx:260-263). Survives scene
  reloads (autoload).
- **Prewarm queue**: `PREWARM` list of ~50 names (sfx:49-56) is queued by `Sfx.prewarm()` (sfx:91-94)
  from the title (title.gd:27) and the world (W:87). `_process` builds queued sounds within
  **`BUILD_BUDGET` = 4000 µs per frame** (sfx:59, 125-133).
- **Job queue**: `queue_job()/finish_job()` (sfx:106-118) run resumable `MusicBox.Job`s in the remaining
  budget (sfx:134-141). `finish_job` forces a job to completion synchronously when its result is needed.
- **`hold_back`** (sfx:103): World sets it to `_is_tense` (W:88, 773-783) so nothing is built during a
  hunt, save-over, Wren delete, or when Arin / the cursor is within 120 px.
- **`OwnerMemory.runtime_cache`** (owner_memory.gd:87, not saved): holds the music-box themes
  (`theme_<level>_<variant>`, mb:52-61) and drone layers (`drone_*`, drone:111-116). Drone builds one
  layer per frame (drone:29, 44-46).
- **Pooling**: 14 SFX players + 4 UI players, round-robin, created once (sfx:21, 77-87, 160-171).

### 1.4 Positional audio

- One `AudioListener2D` on the player (player.gd:74-76).
- `AudioStreamPlayer2D` only in two places: **Arin's footsteps** (av:102-115; max 300 px, attenuation
  1.6, −8 dB, pitch 0.75-0.85) and the **cursor hum** (cur:48-54; max 360 px, attenuation 1.4).
- Everything else, including NPC deletions and the cursor's select whine, is non-positional.
- There is no camera; each area (448×256, area.gd:13) fits on the 640×360 screen, so no threat can be
  off-screen.

### 1.5 Per-area ambience (amb:21-44, events amb:77-99)

Ambience is a fresh `Ambience` node created on **every** area load (W:372-376); beds fade in from
−60 dB over 1.5 s (amb:47-55). The drone (scene node `$Drone`, main.tscn:43) persists across areas.

| Area | Bed (Music bus) | Theme layer | Random events | Notes |
| --- | --- | --- | --- | --- |
| room | none | none | none (`_` branch: amb:97-98) | "nothing but the drone (the owner is listening)" amb:9 |
| square | `wind` −18 dB (amb:26) | – | `bird` (not during HUNT, × village life) / `murmur` every 1.5–4.5 s ÷ life (amb:87-94) | `village_life()` thins with each deletion, warms with pinned note / guestbook / restores (amb:60-74) |
| house | `archive_hum` −20 dB at pitch 1.4 ("fridge") (amb:36-39) | theme **normal**, level = `fragments.size()`, −20 dB (amb:40) | none | "the TV's game music through the wall" |
| archive | `archive_hum` −16 dB (amb:28) | – | `page_turn` every 4–9 s (amb:95-96) | |
| bin | `archive_hum` −18 dB at pitch 0.7 (amb:32-35) | – | none | "a drive spinning" |
| oob | `air` −20 dB (amb:42) | theme **invert**, level = `fragments.size()`, −12 dB, pitch 0.5 (amb:43-44) | none | |
| edge | none | theme **reverse**, level = `fragments.size()`, −14 dB, pitch 0.8 (amb:30-31) | none | swells to −8 dB while the eraser runs (amb:80-82); drone shimmer floor `edge=1` (W:362, drone:52); `unload` on entry (W:364) |

### 1.6 Drone (tension score, Music bus)

`tension` = awareness/100 (OD:102, 141); 1.0 on death (W:891), 0 at the epilogue (W:1020); −30 dB in
the purged room (W:1116). Layers (drone:7-12, 49-67): hum always (−15 dB, pitch sags 5%); dread from
~25%; shimmer from ~55% (or edge); **heartbeat from 65% awareness, 55→125 bpm** (drone:55-61);
crackle probability ∝ tension.

### 1.7 Music box (mb) — levels, variants, memory mapping

- 16 beats × 0.42 s, A minor, 8 kHz, seamless loop (mb:17-19, 142).
- Levels (mb:23-37): **0** two-note motif E5–A4 · **1** first phrase ends on A · **2** answer, ends on
  G♯ (leading tone, unresolved) · **3** bass line · **4** high countermelody · **5** A-major cadence.
- Variants: `normal`; `reverse` (sample-flipped, mb:56-58, 64-73); `invert` (mirrored round A4, mb:137-138).
- **Memories → levels** (levels follow the *count* of memories, not which memory):

| Moment | Level played | Evidence |
| --- | --- | --- |
| Recovering memory #n (n = 1..4) | n | W:175 `mini(fragments.size()+1, MAX_LEVEL-1)` |
| Recovering memory #5 | **4** (same as #4) | same line: the cadence is held back |
| Planted false memory | `invert` at current count | W:175 |
| Title | `held_level` = min(n, 4); 5 only after the RUE ending with 5 memories | mb:43-46, title.gd:36, 103-107 |
| Epilogue | `Story.theme_level`: rue → n; others → min(n, 4); overwrite = invert, unseen = reverse | story.gd:449-452, W:1021-1029 |
| Area themes (house / oob / edge) | **raw `fragments.size()` (can be 5)** | amb:30, 40, 43 — see §3, P6 |
| Guestbook scene | 0 | vs:402 |

The five memories (story.gd:87-150): `controller` "The Second Controller", `well` "The Well",
`new_game` "New Game", `argument` "The Last Time", `delete` "Delete Slot 2?". No memory has its own
musical motif; order of discovery decides which layer it "adds".

### 1.8 Title and ending music

- **Title**: theme on Music at −22 dB, starts in `_process` as soon as the cached theme exists, no input
  gate (title.gd:32-36, 103-107). First launch: after 8 s the owner types `TITLE_FIRST_OWNER` with
  owner blips (title.gd:125-132). Records panel also uses owner blips (records_panel.gd:91).
- **Endings** (W:1040-1081): one-shot per ending — wren `win` ×1.15; message `fragment` ×0.8; rue `win`
  + `glitch_learn`; unseen `unload`; overwrite `death_selected` + `purge_bell`. Then the epilogue theme
  on Memory, −30 → −6 dB over 2 s (W:1022-1029). Only RUE reaches level 5.
- **Quit**: `power_off` (W:1095). **Death**: `death_<cause>` (W:890) then scene reload (W:920) —
  drone and ambience restart from the start.

### 1.9 Dialogue / voice blips (EXISTS)

| Who | Where it sounds | Sound | Parameters |
| --- | --- | --- | --- |
| Owner (console `>` lines) | hud:694-696, title.gd:132, records_panel.gd:91 | `owner_voice`: square 150→140 Hz + detuned saw 153→142, LP 0.25, 70 ms (sfx:542-548), −16 dB | pitch 0.8 + (code%7)·0.035, +0.12 on vowels, jitter 2%, ≥38 ms apart, skips whitespace (sfx:197-206) |
| MIRA / WREN / TOBBEN / THE ARCHIVIST / ARIN (dialogue box) | hud:507-508 | shared `voice`: square 240→220 + triangle octave, LP 0.35, 60 ms (sfx:329-335), −15 dB | pitch per speaker: MIRA 1.25, WREN 1.65, TOBBEN 0.78, ARCHIVIST 0.62, ARIN 1.0 (sfx:47); jitter 7%; ≥45 ms apart (sfx:210-215) |
| **PIP** (dialogue box) | hud:509-510 | `key_system` teletype tick | not in `VOICES` → system tick |
| Readables / notes (dialogue box) | hud:509-510 | `key_system` | – |
| Rue (console "self" lines, cinematics in SELF_COLOR) | hud:356, 698 | `key_self`: 660→610 Hz sine breath, 90 ms (sfx:322-327), −22 dB | jitter 8% |
| System console | hud:698 | `key_system`: 3.3 kHz square tick (sfx:315-320), −21 dB | |
| NPC console lines (`kind "npc"`: Wren's last words, Mira reset) | W:549, 558, 578 → hud:698 | `key_system` (falls to default, sfx:191-192) | |
| Any cinematic not in SELF_COLOR (owner final exchange, planted memory) | hud:356 | `key_system` | |

All typed sounds share one rate limiter `_last_key` (sfx:67, 183, 199, 212). Deletions have per-character
timbre: mira 330 Hz triangle, wren 520 triangle, tobben 140 saw, arin 220 square, others (archivist)
260 square (sfx:726-730). Emote bubbles `pop` (npc.gd:117). `pixel_character.gd` has no audio.

### 1.10 Web export

Preset "Web": `thread_support=false`, no custom HTML shell, empty `head_include` (export_presets.cfg,
preset.2). There is **no JavaScript audio-unlock code** in the repo (only `JavaScriptBridge.eval` for a
debug query string, W:591). Unlocking relies entirely on Godot's own web audio driver.

---

## 2. Acceptance questions (answers with evidence)

**Q1. Does muting the Music bus mute any threat cue?** — **Partly yes.** Primary threat one-shots are on
SFX (`stinger` OD:181 / OMv:378 / hud:464, `spotted` vs:325, cursor `cursor_arrive`/whine/click cur:46-47,
81, 141, save ticks OMv:334, Arin's steps av:103). But these tension cues live on Music and vanish with
the Music slider at 0: the **heartbeat** at ≥65% awareness (drone:39, 55-61), the dread/shimmer layers,
the birds falling silent during HUNT (amb:89-91), and the Edge theme swelling when the eraser starts
(amb:80-82). Each has a visual twin (awareness meter, eraser), so nothing becomes *undetectable*, but the
"music" slider is also a "danger" slider.

**Q2. Does muting SFX mute dialogue/voice?** — **Yes.** Voice and owner blips and all typing play through
`Sfx.play()` with the default bus "SFX" (sfx:148, 188-192, 206, 215). Worse, `sfx_volume` also drives
the **UI** bus (set:130-131), so "Effects 0" silences menus, voices and every threat cue at once. There
is no separate Voice bus or slider.

**Q3. Are any threat cues audio-only?** — **No confirmed case.** Every threat found has a visual: awareness
thresholds (stinger + `threshold_pulse`, OD:179-181), Arin (view cone av:123+, on-screen), cursor
(screen noise/spike while hovering, cur:132-134), save-over and Wren/Mira delete (drawn rings
OMv:416-445 + console text), reload (banner OMv:187), eraser (visual). The heartbeat (≥65%) and
the Edge swell are audio-*first* but duplicate the meter. Arin's positional footsteps are the only
directional cue, but Arin is always on screen (no camera, area.gd:13). Haptics duplicate some
(Settings.buzz, OMv:335-336, W:888).

**Q4. Do music/ambience restart on every doorway?** — **Ambience yes; drone no.** `_load_area` frees the
old `Ambience` without a fade and builds a new one (W:372-376); the new bed fades in from −60 dB over
1.5 s (amb:47-55) and themes start from beat 0. Walking square → house → square restarts the wind bed
twice. The drone persists (main.tscn:43), only `drone.edge` toggles (W:362). Death reloads the whole
scene (W:920), restarting drone and ambience.

**Q5. Any per-frame audio allocation?** — **No players or streams are allocated per frame.** Minor
per-frame work: `_jobs.keys()` allocates an Array per loop iteration while jobs are pending (sfx:139);
title builds a format string every frame until its theme starts (title.gd:104); drone/cursor/glitch
set `volume_db` each frame (cheap). The real hitch risk is **synchronous synthesis at play time**:
`deletion_<id>` is not in `PREWARM` (sfx:49-56) so the 2 s deletion sound is rendered on the frame the
owner deletes someone (npc.gd:73 → sfx:302-303, 723-747) — usually a tense moment. `MusicBox.stream()`
also falls back to `finish_job`/`render` synchronously (mb:53-60) if a theme wasn't prewarmed (e.g. an
area entered while `hold_back` was blocking builds). Two loop players run permanently at −80 dB
(sfx:233-240; cur:47, glitch_controller.gd:43), costing mix time but not allocation.

**Q6. Web: does the title wait for input before audio?** — **No.** The title starts its theme as soon as
it is built (title.gd:103-107) and, on first launch, types the owner line with blips after 8 s
(title.gd:125-132), with no "click to start" gate and no JS unlock. Browsers keep the AudioContext
suspended until a gesture, so the first-launch owner whisper can be silent and the theme enters mid-loop
on the first click/keypress. (Godot's driver resumes the context on input; that behaviour is engine-side
and must be verified in a browser — see P8.)

---

## 3. Confirmed audio problems (evidence)

Severity: **H** affects play/accessibility, **M** audible inconsistency, **L** polish/perf.

| # | Sev | Problem | Evidence |
| --- | --- | --- | --- |
| P1 | H | **"Effects" slider controls SFX + UI + all voices + most threat cues.** Players who lower effects to hear dialogue less (or vice versa) lose everything together; no voice slider. | set:130-131; sfx:148, 176-177, 206, 215 |
| P2 | H | **Round-robin pool steals long sounds.** 14 SFX players reused in order with no "is playing"/priority check. At a threshold, `stinger` (1.5 s, hit at 0.9 s) is followed in the same frame by the owner's typed line at up to ~26 blips/s (38 ms limiter) plus steps; 14 slots wrap in ≈0.5 s, cutting the stinger before its hit. Same risk for `death_*` (2.4 s) and deletions (2 s). Code-path confirmed; needs a listening test for audibility. | sfx:21, 165-166; OD:180-181 (`_owner_line` then stinger); sfx:199 |
| P3 | H | **Tension cues on the Music bus** (heartbeat, dread, shimmer, Edge swell, bird silence). Music=0 removes the audio half of the awareness feedback. | drone:34, 39, 97, 103; amb:49, 80-91 |
| P4 | M | **Deletion sounds not prewarmed** → 2 s synthesis on the deletion frame (WAV built synchronously, `hold_back` doesn't apply to direct `stream()` calls). | sfx:49-56 (no `deletion_*`), 260-263, 302-303 |
| P5 | M | **Voice coverage gaps**: PIP has no voice (system teletype); NPC console lines (`"npc"` kind: Wren's last words, Mira's reset) use the system tick; all cinematics not in SELF_COLOR — including the owner's final exchange and "WREN:"/"MIRA:"/"TOBBEN:" lines inside scenes — use `key_system`, so the owner sounds like the OS at the climax. ARIN has a voice pitch though the bible says Arin is silent. All NPCs share one timbre; only pitch differs. | hud:356, 507-510, 698; sfx:47, 186-192; W:549, 558, 578, 1010; NARRATIVE_BIBLE §3.3 |
| P6 | M | **Level-5 (resolved) theme leaks before the RUE ending.** House, OOB and Edge use raw `fragments.size()`, so with 5 memories the house "TV" plays the A-major cadence, and the Edge plays it backwards — contradicting "the last layer is held back for that ending alone". Flashback #5 meanwhile replays level 4, so the 5th memory gets no new layer. | amb:30, 40, 43 vs mb:41-46, story.gd:449-452, W:175 |
| P7 | M | **Ambience hard-cuts on every doorway** and themes restart at beat 0; old players are freed with no fade-out. | W:372-376; amb:47-55 |
| P8 | M | **No web audio gate.** Title audio starts without user input; first-launch owner whisper may be lost. Additionally, with `thread_support=false` Godot 4.3 web defaults to *sample* playback, where bus effects (SFX reverb, the muffle low-pass) and live `pitch_scale` changes may not behave as on desktop. **Unverified risk** — needs a browser test. | title.gd:103-107, 125-132; export_presets.cfg preset.2 |
| P9 | L | **Pause during a flashback ends the flashback muffle early**: closing the pause menu calls `muffle(false)` while the cinematic is still running (pause is allowed when `ending == ""`). | pause_menu.gd:99; W:171, 184, 269-279 |
| P10 | L | **Shared rate limiter**: owner blips, NPC blips, typing and Rue's breath share `_last_key`, so overlapping console + dialogue text drop each other's blips. `voice_blip` also blips on spaces/punctuation (owner_blip skips whitespace). | sfx:183, 199, 212 |
| P11 | L | Ambient one-shots (birds, murmur, page turns) borrow the SFX pool and re-bus it to Music, competing with gameplay sounds for the 14 slots (feeds P2). | amb:91, 93, 96; sfx:164-167 |
| P12 | L | Footsteps identical in every area (`step_0/1`, −27 dB); no surface identity. Arin's steps use the same sample pitched down at −8 dB (ignores `LEVEL`). | player.gd:174; av:112-115; sfx:364-369 |

---

## 4. DESIGN — character voice profiles (PROPOSED)

Principles: a voice is a **synth recipe + pitch set + rhythm**, not just a pitch scale. Blips are per
syllable-ish (every 2nd letter, skip spaces/punctuation, stretch on `…`/`—`). Keep every voice below
−12 dB under the console and inside 150–1200 Hz fundamental so it reads on phone speakers.
"Owner suspicion" = `director.awareness` 0..100. "Memory" = `fragments.size()` 0..5.

### 4.1 Rue (you) — EXISTS as `key_self` breath; profile PROPOSED
- **Grounding:** lowercase, in parentheses, "short, honest, scared, dry" (bible §3.1); "it hurts less
  every time. that's worse."
- **Baseline:** quiet, close, breathy. Not a voice the world hears — an inner one.
- **Pitch:** 520–700 Hz, narrow (±2 semitones). **Timbre:** sine + soft noise breath (current `key_self`),
  no square edge. **Rhythm:** one blip per word, not per letter; slight hesitation before the last word.
- **Phrase length:** 3–8 words. **Signature motif:** each phrase ends on E or A (the theme's two notes, mb:25).
- **Calm:** as now. **Afraid** (awareness ≥ SUSPECT or a threat within 120 px): pitch +2 st, blips
  shorter, noise up. **Lying:** n/a (Rue doesn't lie). **Remembering** (cinematic in SELF_COLOR): blips
  replaced by single music-box tines on the theme notes. **Corrupted** (planted memory, ffb0a0): the
  tines invert (mirror round A, like `invert`).
- **Memory modulation:** 0 memories = pure noise breath; each memory adds a sine partial; at 5 the
  breath is a clear tone. **Owner suspicion:** none directly — Rue is heard only by the player.
- **Silent:** during death and the "unseen" ending.

### 4.2 The owner (console `>`) — EXISTS as `owner_voice`; modulation PROPOSED
- **Grounding:** "lowercase, `>`-prefixed, curt; bored → irritated → cruel → cracking" (bible §3.2).
- **Baseline:** low, close-mic, slightly detuned (current recipe sfx:542-548 is right).
- **Pitch:** 130–190 Hz. **Rhythm:** per letter (keyboard-like), 38 ms floor. **Phrase:** 1–10 words.
- **Signature:** the minor-second detune (150/153 Hz) — the same interval as `spotted` (sfx:422-423).
- **Suspicion modulation (key):** 0–25 bored: softer, slower; 25–50 irritated: detune widens to ¼ tone;
  50–75 cruel: add the `owner_pause` saw grit, faster; 75–100: clipped, staccato, pitch drops 2 st.
- **Cracking** (final exchanges S:443, "> stop. stop. please."; OWNER_RECOGNITION at 3/5 memories):
  detune collapses to unison, pitch wavers ±3%, gaps between words.
- **Memory modulation:** at ≥3 memories the owner's blips occasionally land on a theme note.
- **Fix with P5:** cinematics in OWNER_COLOR must use owner blips, not `key_system`.
- **Silent:** while Rue's PAUSE glitch holds the owner (they literally stop typing); the purged room
  after "welcome back, arin." (silence is the punishment).

### 4.3 Arin (avatar) — silent (bible §3.3)
- **No voice.** Remove `ARIN` from `VOICES` (sfx:47) or keep it as **non-vocal**: a 2-note console
  "beep" like a game character with no lines. Purged room `"..."`: three slow soft clicks.
- **Presence = footsteps** (EXISTS, av:102-115) + a faint controller-rumble thud when it turns its view
  cone toward you (PROPOSED). Heavier, regular, never hurried until HUNT, then 1.3× tempo.
- **Deletion timbre** EXISTS (220 Hz square, sfx:727).

### 4.4 Mira — EXISTS (pitch 1.25); profile PROPOSED
- **Grounding:** "warm, worried, full sentences, capitalised" (bible §3.4); "There. MIRA WAS HERE. Now it's true."
- **Pitch:** 260–380 Hz, medium range, rising contour on questions. **Timbre:** triangle + soft square
  octave (warm), slight vibrato 5 Hz. **Rhythm:** even, every 2nd letter. **Phrase:** long (8–20 words).
- **Signature:** a three-blip "welcome" turn (up-down-up) on "Welcome home, Arin!".
- **Afraid** (escort, reset ring filling): faster, higher, vibrato deeper. **Lying:** n/a.
- **Remembering** (`Story.recall`, pinned note): one music-box tine at line end. **Corrupted / reset**
  (MIRA_RESET_LINES): perfectly quantised, no jitter, no vibrato — a "default NPC" voice.
- **Owner suspicion:** in her room, none; outside (escort), +1 st per threshold.
- **Silent:** once deleted; capital-letter shouting ("MIRA WAS HERE") = louder, not higher.

### 4.5 Wren — EXISTS (pitch 1.65); profile PROPOSED
- **Grounding:** "plain, brave, short" (bible §3.5): "It's okay. Go." · last words "you said you'd—".
- **Pitch:** 380–520 Hz. **Timbre:** pure triangle, no square (a child's clean tone). **Rhythm:** clipped,
  one blip per word; full stops = clear gaps. **Phrase:** 2–8 words.
- **Signature:** a two-note step-up on "Okay. Okay!" (WREN_JOINS).
- **Afraid** (delete ring): blips speed up but stay quiet ("I'll be so quiet."). **Brave** (WREN_EDGE):
  slower, wider range. **Deleted mid-line**: voice cut at the dash and replaced by her deletion sound
  (520 Hz triangle, sfx:727) — "you said you'd—" must route through the voice, not `key_system`.
- **Memory/Edge:** once `wren_saved`, add a faint reverb tail (she's "cut content").
- **Silent:** hiding you (she holds her breath — no emote pop).

### 4.6 Tobben — EXISTS (pitch 0.78); profile PROPOSED
- **Grounding:** "cheerful shop patter that breaks" (bible §3.6): "Welcome to Tobben's! Finest... you
  don't have any gold."
- **Pitch:** 160–240 Hz, wide bouncy range. **Timbre:** saw, slightly bright (matches his deletion saw,
  sfx:728). **Rhythm:** fast patter (every letter) for scripted shop lines, then **drops to half-speed
  on the break** ("..."). **Phrase:** long patter, short confessions.
- **Signature:** shop "ding" (re-use `ui_confirm` at 0.6, already the house chime) on "Welcome".
- **Lying / scripted** ("It's in my script"): perfectly regular rhythm, no jitter. **Sorry** ("I told
  them. I'm sorry."): pitch −2 st, slow. **Remembering** (GUESTBOOK_SCENE, "I'd forgotten I forgot."):
  patter stops; two theme tines.
- **Owner suspicion:** after he reports you, his blips get a faint owner-detune (he's working for them).
- **Silent:** when deleted; the shop murmur in the square drops with him (village_life EXISTS).

### 4.7 Pip — NOT IMPLEMENTED (currently system ticks)
- **Grounding:** "lowercase, quick bursts" (bible §3.7): "you're the wrong colour. that's okay. i'm the
  wrong place."
- **Pitch:** 700–1100 Hz, small sniffing chirps. **Timbre:** sine chirp with upward glide + tiny noise
  "sniff". **Rhythm:** bursts of 3–5 blips, gap, burst. **Phrase:** short.
- **Signature:** the two-note motif (E–A) as a chirp on "...rue?".
- **Afraid** ("i don't like the hand"): bursts tighter, higher. **Remembering** (`pip_moment` by memory
  count): 0–1 sniff only; 2–3 chirps; 4 one tine; 5 the name-tag line gets the full two-note motif.
- **Owner suspicion:** unaffected — "the owner can't see me" (PIP_LINES). Pip is the only voice that
  never bends to the owner.
- **Silent:** in the overwrite ending (Pip is absent from its last line, bible §3.7).

### 4.8 The Archivist — EXISTS (pitch 0.62); profile PROPOSED
- **Grounding:** "dry, kind librarian" (bible §3.8): "Oh. A visitor. Nobody visits."
- **Pitch:** 130–180 Hz, narrow. **Timbre:** soft square through heavy low-pass + page-noise grain (from
  `page_turn`). **Rhythm:** slow, every 3rd letter, longer gaps at full stops. **Phrase:** medium,
  measured.
- **Signature:** a dry "hm" (single low blip) before each first line.
- **Kind** (greets Rue by name at 5 memories): one-octave lift on "Rue". **Lying:** n/a.
- **Remembering** ("I wasn't finished either."): archive hum dips under the line.
- **Silent:** never deleted in the current code; if deleted, falls back to the 260 Hz square (sfx:730).

### 4.9 System console — EXISTS
Teletype tick (sfx:315-320). Keep it **reserved for SYSTEM and readables** only (fix P5).

---

## 5. DESIGN — area audio identity matrix

`EXISTS` = in code now; `PROP` = proposed. Owner proximity = Arin / cursor nearby. Death/reload covers
`kill()` + owner reload.

| Area | Base ambience | Footsteps | Interactables | Safe vs unsafe | Memory | Glitch | Owner proximity | Transition in | Death / reload |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **room** | EXISTS: drone only. PROP: faint CRT whine + PC fan, ticks of a wall clock that stops at SILENCE | EXISTS generic. PROP: carpet (softer, LP) | EXISTS: door_lock, denied (save crystal), scribble (note), seal. PROP: board pin "tack" | EXISTS: drone layers. PROP: clock stops at SILENCE | EXISTS: flashback (Memory bus) | EXISTS: charge/fire/phase | PROP: owner's keyboard heard through the "screen" when they type (re-use key_owner) | EXISTS: transition whoosh | EXISTS: death_*; scene reload |
| **square** | EXISTS: wind + birds/murmur, thinning with deletions | EXISTS generic. PROP: gravel (noisier) | EXISTS: notice board, emote pops. PROP: shop door bell, well echo | EXISTS: birds stop at HUNT. PROP: murmur hushes when Arin's cone passes | EXISTS | EXISTS | EXISTS: Arin steps (2D), cursor hum (2D), `spotted` | EXISTS | EXISTS |
| **house** | EXISTS: fridge hum + theme through wall (level n; see P6) | EXISTS generic. PROP: wooden floor creak | EXISTS: door chime (arins_house.gd:97) | PROP: theme ducks as Arin "comes home" | EXISTS | EXISTS | EXISTS: Arin steps | EXISTS | EXISTS |
| **archive** | EXISTS: hum + page turns | EXISTS generic. PROP: stone, longer reverb | EXISTS: readables (system tick). PROP: drawer slide per log | PROP: hum is the safe-room signal (no drone dread here) | EXISTS | EXISTS | none (owner "can't find" you, OD:163) | EXISTS | EXISTS |
| **bin** | EXISTS: hum ×0.7 | EXISTS generic. PROP: crunchy (bit-crushed) | EXISTS: countdown ticks (recycle_bin.gd:128), erase_start (141), glitch_charge/learn (bin_file.gd:34,52) | EXISTS: countdown ticks speed up | EXISTS | EXISTS | PROP: owner's "empty bin" click | EXISTS | EXISTS |
| **oob** | EXISTS: air + inverted theme ½ speed | EXISTS generic. PROP: none (no floor: footsteps absent, only cloth) | EXISTS: cracked wall `phase`. PROP: Pip chirps | PROP: safest place — drone dread capped at 0.3 | EXISTS | EXISTS | none | EXISTS + PROP: low drop on arrival | EXISTS (unload on leaving, out_of_bounds.gd:141) |
| **edge** | EXISTS: reversed theme, swells with eraser; shimmer floor; unload on entry | EXISTS generic. PROP: steps decimate (crush) as you near the end | EXISTS: countdown keys (the_edge.gd:149), stinger (176), click (192), door_lock (224) | EXISTS: swell + shimmer | EXISTS | EXISTS | EXISTS: cursor hum, Arin steps | EXISTS: unload | EXISTS |

---

## 6. DESIGN — mix rules (PROPOSED unless noted)

1. **Bus split** (fixes P1, P3): `Master → {Music, Ambience, Memory, Threat, SFX, Voice, UI}`.
   - *Threat* (stinger, spotted, cursor whine/hum/click, save ticks, heartbeat, Arin's steps, erase_start,
     deaths): follows **Effects** but has a floor of −24 dB unless Master is 0 — a threat must stay
     audible when Music is off and must never ride the Music slider.
   - *Voice* (all blips incl. owner): its own slider "Voices"; not muffled by pause.
   - *Ambience* (beds, birds, hums): follows Music, or its own slider.
   - *UI*: follows Master only (menus must stay audible to fix a 0 Effects slider).
2. **Priority pool** (fixes P2, P11): separate pools — 6 voice/typing, 4 ambient, 10 gameplay; a new
   sound may not steal a player that is still playing a sound with higher priority
   (death > threat > deletion > glitch > world > step > ambient > typing).
3. **Ducking**: Voice lines duck Ambience −6 dB and Music −3 dB (150 ms attack, 600 ms release).
   Threat stingers duck everything else −6 dB for their length. Flashbacks: Memory bus up, all others
   muffled (EXISTS) — but pause must restore the flashback muffle state on close (fixes P9).
4. **Headroom targets** (per bus peak): Music −14 dBFS, Ambience −18, Voice −12, Threat −8, deaths −3.
   Keep current `LEVEL` table (sfx:24-39) as the per-sound trim.
5. **Doorways** (fixes P7): crossfade old ambience out over 0.4 s while the screen fades (hud fade 0.25 s);
   if the next area uses the same bed (house/archive/bin share `archive_hum`), keep the player and only
   retune pitch/volume. Themes resume at the same beat position via `play(from_position)`.
6. **Theme rule** (fixes P6): every area theme uses `MusicBox.held_level(fragments.size())`. Give the
   5th memory its own audible change (e.g. level 4 + the cadence's bass note only) so each memory still
   adds something.
7. **Prewarm** (fixes P4): add `deletion_mira/wren/tobben/arin/archivist` to `PREWARM`; never call
   `Synth` synchronously while `_is_tense()` — play a cheap placeholder instead.
8. **Web** (fixes P8): title shows a "press any key" gate on web (`OS.has_feature("web")`) before the
   first sound; test reverb/low-pass/pitch in a browser with sample playback, or set
   `audio/general/default_playback_type.web` to Stream if effects matter more than latency.
9. **Accessibility**: every audio-only nuance keeps a visual twin (already true, §2 Q3). Add a
   "Mono audio" toggle (Arin's 2D steps pan) and subtitles-for-sounds (e.g. `[heartbeat]`, `[the cursor
   hums]`) as an optional HUD line.
10. **Silence is a sound**: the room has no bed on purpose (amb:9); the purged room drops the drone to
    −30 dB (W:1116). Keep at least one silent beat (≥1.5 s, nothing but the drone) before each act card
    stinger (hud:464) and before the final exchange.

---

## 7. Test hooks that exist

`tests/test_audio.gd` covers: every sound renders, loops loop, buses follow settings, harsh-sound
softening, muffle toggling, drone layers, gameplay events make sounds (`Sfx.history`, sfx:72),
theme growth, area beds, positional steps and owner blips (test_audio.gd:10-150). None covers bus
assignment of threat cues, voice coverage per speaker, pool stealing or doorway continuity — add those
alongside any fix above.
