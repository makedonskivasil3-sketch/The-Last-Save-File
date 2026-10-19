# Audio diagnosis: why the game seemed to have no music

**Date:** 2026-10-19
**Engine:** Godot 4.3-stable (GL Compatibility)
**Branch:** `claude/review-fixes`

Every check below is marked **pass**, **fail**, **blocked** or **not run**.

## The report

"Sound has not been playing", and later "the music won't play".

## What was found

There are two separate causes. Each one alone would make the game seem silent.

### 1. Web build: completely silent (reproduced and fixed)

**Cause.** The game created its five buses (Music, Memory, SFX, UI, Voice) at startup with `AudioServer.add_bus()`, one at a time.

- On the web, Godot 4.3 plays audio as *Samples*. The project setting `audio/general/default_playback_type.web` defaults to 1 = Sample, and this project doesn't change it.
- In Sample mode the engine keeps a copy of every bus in JavaScript.
- `add_bus()` with its default position (-1) calls `GodotAudio.Bus.addAt(-1)` in `platform/web/js/libs/library_godot_audio.js`. That creates the new bus at the end of the list, then *moves* it with `splice(-1 - 1, 0, bus)`, which puts it second from the end.
- After five calls, the browser's bus list no longer matches the engine's:

  | Engine index | Engine bus | Browser bus at that index |
  |---|---|---|
  | 0 | Master | Memory |
  | 1 | Music | SFX |
  | 2 | Memory | UI |
  | 3 | SFX | Voice |
  | 4 | UI | Music |
  | 5 | Voice | Master |

- Every send and volume the engine then sets lands on the wrong browser bus. No bus is left connected to the speakers.

**How it was established:**
- Read in the 4.3-stable engine source:
  - `servers/audio_server.cpp`, `add_bus` → `add_sample_bus(p_at_pos)`;
  - `library_godot_audio.js`, `Bus.addAt`, `Bus.move` and `Bus.setSend`.
- That JavaScript was run (Node, with a mock audio graph) on the exact call sequence the game made. Result: no bus reached the speakers.

**Reproduced in a real browser:**
- **Setup:** headless Chromium, using the web export of this branch before the fix.
- **Method:** `tests/web/audio_output_check.cjs` taps the page's real Web Audio graph. Everything connected to the speakers passes through an AnalyserNode first.
- **Result:** after a click, on the title and in the first room, the post-mix output was exactly zero (RMS -inf dBFS). The AudioContext still reported `running` and the page had no errors.

**Fix** (`scripts/autoload/sfx.gd`, `_make_buses`):
- All missing buses are created in one step, `AudioServer.bus_count = n`, then named and sent to Master.
- `set_bus_count` maps to `set_sample_bus_count`, which creates the browser's buses in order.
- In the same Node simulation, every bus then reached the speakers.

**Verified in the browser after the fix:**

| Moment | Before | After |
|---|---|---|
| Title | silent | -29.4 dBFS RMS, sound in 100% of windows, no clipping; the theme's A4 (441 Hz) and E5 (657 Hz) are the two strongest pitches |
| First room | silent | -31.7 dBFS RMS, sound in 92% of windows, no clipping; 441 Hz and 657 Hz among the strongest pitches |

**Still different on the web.** In Sample mode Godot doesn't run bus *effects*. The SFX reverb, the low-pass "muffle" on pause and in memories, and the speech duck (AudioEffectAmplify) don't apply in the browser. Volumes and mutes do. This is an engine limitation of Sample playback, recorded here rather than worked around.

The alternative is Stream playback, which on the web needs main-thread mixing in this threadless export. It has not been measured, so it isn't adopted.

### 2. Desktop: the music was there but buried (measured and fixed; listening not done)

**Measurement setup:** `tools/audio_probe.gd` records Godot's final mix (AudioEffectCapture on Master, dummy driver, 44.1 kHz). `tools/analysis/spectrum.py` splits that capture into frequency bands with an FFT.

**Before:**
- **Title:** 95% of the energy was below 120 Hz. That's the drone's 55 Hz hum, at -15 dB.
- **Title theme:** played at -22 dB, below the drone.
- **Arin's room:** no music at all, only the drone.
- **Village and Archive:** the theme sat at -29 and -25 dB.
- **What this means:** laptop and phone speakers barely reproduce anything below about 150 Hz, so on them the opening was effectively silent and the music inaudible. On headphones the drone was audible and the music faint.

**Changes:**
- The hum gains odd harmonics at 3×, 5× and 7×, so a small speaker carries its pitch and its slow beat. The bass isn't boosted.
- The hum drops to -18 dB.
- The title theme rises to -13 dB.
- The theme now plays softly in Arin's room, at -21 dB less 0.15 dB per point of awareness. It thins as the owner watches more closely.
- The Village theme moves to -20 dB and the Archive to -16 dB.
- Dialogue and scenes still dip the theme by 8 dB.

**Desktop mixer, after:**
- Soloed on the title, the Music bus has 41% of its energy between 300 Hz and 4 kHz, up from 3%.
- The theme plays in Arin's room at about -25 dB.

## Verification status

| Check | Status |
|---|---|
| Engine source traced (4.3-stable) | pass |
| Bus routing simulated: old call sequence | fail (silent), reproduces the defect |
| Bus routing simulated: fixed call sequence | pass |
| Browser post-mix output, before fix | fail (silent) |
| Browser post-mix output, after fix: level, no clipping, theme pitches present | pass |
| Native mixer capture, after fix: title, room, memory | pass |
| `tests/test_audio_routing.gd`: bus order and sends, no `AudioServer.add_bus(`, theme above hum, hum harmonics | pass |
| CI step `Web build is audible (headless Chromium)` | not run yet (added to `.github/workflows/build.yml`) |
| Listening on headphones and on laptop/phone speakers | **blocked**: no audio device or listener in this environment |
| A real browser on a real device, with an actual click | not run |
| Windows build audio | not run (no Windows machine) |
| System narration (TTS) output | not run (it doesn't pass through Godot's buses; it needs a device with voices) |

## For a person to check

1. **Web:** open the browser build and click once on the title. The two-note music box should be clear over a soft hum.
2. **Laptop speakers at a normal volume:** on the title you should hear the music box. In Arin's room the hum should be just audible and the theme faint.
3. **Headphones:** the hum shouldn't feel boomy, and the added harmonics shouldn't sound like a buzz. This is a timbre change to judge by ear.
4. **Settings:** set Music to 0. The theme and the hum should stop, and the effects should continue.
