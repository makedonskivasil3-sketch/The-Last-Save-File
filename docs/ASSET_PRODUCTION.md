# Producing voices and character art

A short production guide covering:
1. what each tool makes;
2. how files enter Godot;
3. how to replace them;
4. licensing.

The briefs are in `VOICE_BIBLE.md` and `CHARACTER_ART.md`. The line list is `audio/voice/manifest.csv`.

**Nothing in this guide was bought or uploaded.** Prices and terms below were checked on 2026-10-18 from **third-party summaries**, because the official ElevenLabs pricing page couldn't be reached from the build machine. **Confirm on the vendor's own pages before paying.**

## Four kinds of voice: say which one you mean

| Kind | What it is | In this game |
|---|---|---|
| **Recorded human performance** | An actor reads the script into a microphone | Not yet; the best quality, needs casting and a session |
| **Generated voice acting** | A synthetic voice (for example ElevenLabs) rendered to audio files | Not yet; the pilot was blocked (below) |
| **Operating-system text-to-speech** | The OS reads text at runtime (`Narration`, Settings → Spoken narration) | Exists, off by default. **It is not voice acting** and isn't described as such |
| **Procedural character sounds** | Per-speaker blips and typing made in code (`Sfx.VOICE_PROFILES`) | Exists; the fallback for every line without a recording |

## Voice

### Recommended primary workflow: generated voices, directed per line

- **Tool:** ElevenLabs. Commercial use needs a paid plan; Starter is reported at about $5–6 a month with about 30k credits, Creator at about $22 with about 100k ([bigvu](https://bigvu.tv/blog/elevenlabs-pricing-2026-plans-credits-commercial-rights-api-costs/), [smallest.ai](https://smallest.ai/blog/elevenlabs-pricing-plans-cost-what-you-get-in-2026)). **The free tier does not allow commercial use and requires attribution.**
- **Budget:** the manifest has 118 lines (about 9,000 characters). At about 1 credit per character on the expressive model, one take of everything is roughly 9–10k credits; three takes to choose from are about 30k. **One month of Starter covers it.**
- **Voices:** pick library voices by the briefs. No cloning of any real person; Wren is a designed voice (an adult character voice or a voice-design prompt), never a real child. The pilot picks were Karla for Rue and Bradley for the owner (the 2026-10-17 pilot attempt). **Re-audition before recording.**
- **Output:** download each take as **WAV 44.1 kHz/16-bit** where the plan allows, otherwise the highest-bitrate MP3.
- **Process:** master to the spec below, then encode to **Ogg Vorbis**.

**Status:** blocked. On 2026-10-17 the connected account refused generation: 55 credits left, and "Free Tier access has been disabled … Please upgrade to a paid subscription". **To proceed, the owner of the account needs a paid plan, or another account.** That is the only access this pass needs for voices.

### Affordable fallback: human actors, self-recorded

- One actor for Rue (and the narration), one for the owner, and one doubling Mira, Wren (character voice), Tobben and the Archivist.
- Record at home on a USB microphone into **Audacity** (free) or **Reaper**, as **WAV 48 kHz/24-bit**, mono, in a quiet, soft room.
- Agree in writing: payment, the game, platforms, and **no AI training or cloning of their voice**.
- Cost: per-line or per-hour rates agreed with the actors. About 118 lines is about one session each.

### Format and loudness spec (both workflows)

| | Source (keep in `audio/source/`, not exported) | Runtime (`audio/voice/<id>.ogg`) |
|---|---|---|
| Format | WAV, mono, 48 kHz (or 44.1 kHz), 24-bit | **Ogg Vorbis, mono, 44.1 kHz, quality 0.6 (~112 kbps)**, as Godot recommends for speech ([Godot docs](https://docs.godotengine.org/en/4.2/tutorials/assets_pipeline/importing_audio_samples.html)) |
| Loudness | — | **−18 LUFS integrated per line (±1 LU)**, true peak **≤ −1 dBTP** |
| Head and tail | Keep the takes whole | Trim to 100 ms before the first sound and 250 ms after the last. **Keep written pauses inside the line** |
| Processing | Raw | High-pass at 80 Hz, gentle de-ess, light compression (2:1). No reverb baked in, so the game adds room |

Why −18 LUFS:
- Speech has to sit above the game's music and effects at the default levels.
- −18 is the common portable and mobile target, and close to how loud the game's own mix sits.
- Console guidance is quieter, around −24 ([Audiokinetic](https://audiokinetic.com/ko/blog/mastering-a-game-with-wwise-part1), [Designing Sound](https://designingsound.org/2012/07/30/video-games-and-loudness-standards-interview-with-sonys-garry-taylor/)). The *Voices* slider and the music duck (−9 dB under speech) do the rest.

Normalise with `ffmpeg -i in.wav -af loudnorm=I=-18:TP=-1:LRA=7 -ar 44100 -ac 1 -c:a libvorbis -q:a 6 audio/voice/<id>.ogg`.

### How a voice file enters the game

1. Find the line's **id** in `audio/voice/manifest.csv`, for example `memory.controller.4a8c4986`.
2. Save the processed file as `audio/voice/<id>.ogg`. Godot imports it on the next editor or `--import` run, with the default Ogg settings and loop off.
3. That's all. `VoiceOver` plays it when the line shows:
   - the typewriter keeps pace with it;
   - auto mode waits for it;
   - music ducks under it;
   - it pauses with the game and stops on skip or scene change;
   - the History offers replay.
4. Regenerate the manifest so the file shows as `recorded` with its duration: `godot --headless --path . -s res://tools/voice_manifest.gd`.
5. Record the performer or voice, the tool and plan, the date and the licence in `audio/voice/CREDITS.md`. Add a line to the in-game Credits.

**When a line's text changes, its id changes.** The old file stops playing, so an outdated take never plays under new words, and the manifest test fails until it is regenerated.

## Character art

### Recommended primary workflow: draw in Aseprite, from the briefs

- **Tool:** Aseprite, a pixel-art editor. About $20 one-off on Steam or itch ([Aseprite FAQ](https://www.aseprite.org/faq), [GG.deals](https://gg.deals/ca/application/aseprite/)). It exports PNG frames and sprite sheets, and has a command-line exporter. Its FAQ allows making assets for commercial games.
- **What it produces:**
  - per character, 32×32 portrait PNGs per expression (`<who>_<expression>.png`);
  - 8×N sprite templates, or sprite sheets if the in-world sprites are replaced later;
  - the `.aseprite` source.
- **Why this one:** pixel art at this scale is drawn, not generated. A human hand gets consistency across expressions and with the sprites.

### Optional: concepts with an image generator

- A generator (for example **Midjourney**, on a paid plan) can explore costume or mood **concepts** before drawing. Paid plans are reported to grant ownership and commercial use; companies over $1M revenue need Pro or Mega; free-trial images are CC BY-NC ([terms.law summary](https://terms.law/2026/01/15/midjourney-commercial-use-rights-complete-2026-guide/)). **Read the current terms first:** they changed in 2026, and AI-only images have uncertain copyright protection.
- **Generated images are references, never shipped directly.** Final pixels are drawn to the grid and palette.
- **Never** prompt with a living artist's name, a real person, or another game's characters.

### Affordable fallback: Krita, or the built-in code art

- **Krita** is free and open source (GPL; your artwork is yours). It handles pixel work with a pixel brush, nearest-neighbour scaling and a grid.
- **Or keep extending `CharacterArt`:**
  - the 32×32 grid for each character lives in code;
  - expressions are data;
  - the palette comes from the sprite.

  This is how Rue was made for this pass: no licence questions, and restoration-aware by construction.

### How a portrait enters the game

1. Draw to `CHARACTER_ART.md`'s checklist: 32×32, transparent, the palette keys, a 1 px outline, every expression.
2. Save as `art/characters/<who>/<who>_<expression>.png`. In Godot's Import dock:
   - **Filter: off** (Nearest);
   - **Mipmaps: off**;
   - **Compress: Lossless**;
   - Reimport.
3. `CharacterArt.texture_for` uses the file for the character's finished look. Rue's missing and partly restored looks stay code-drawn, because they depend on her memories.
4. Check it with the story tour (`tests/tour_story.gd`) at Normal and Large text, with effects on and off.
5. Credit the artist and licence in `art/CREDITS.md` and in the in-game Credits.

## Licensing rules (all assets)

- **Commercial-use rights in writing** before anything ships: a paid plan's terms, or a contract with the performer or artist.
- **No cloning or imitation of an identifiable person's voice or likeness** without their written consent.
- **No uploading private material** (scripts are fine; personal recordings are not) to a service without the owner's permission.
- **Track everything:** keep every source file, plus `CREDITS.md` entries (who, tool, plan, date, licence).
- `LICENSE` (all rights reserved) covers the game's own code and art. **Third-party assets keep their own licences**, listed in the Credits.
