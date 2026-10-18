# Voice pilot: the Slot 2 Wren ending

**Status:** generated takes, not shipped. Nobody has listened to them. The licence does **not** allow shipping yet.

## The scene

This is the Slot 2 confrontation when Rue gives the slot to Wren (`Story.FINAL_EXCHANGE["wren"]`). It is the one scene in which the Owner, a supporting character and Rue each speak once:

| Id | Speaker | Subtitle |
|---|---|---|
| `final.wren.ef85eaa6` | OWNER | `> who is that. i didn't make her.` |
| `final.wren.303565e2` | WREN | `WREN: I'll keep it warm. Your slot. In case.` |
| `final.wren.d8aa4b56` | RUE | `(go. it only fits one.)` |

## Provenance

All takes were generated speech: **not recorded human acting, and not system TTS.**

- **Tool:** ElevenLabs, model `eleven_v4`, through the workspace connector, on 2026-10-18.
- **Voices:** ElevenLabs Voice Library voices. They are shared by their creators under ElevenLabs' library terms. None was cloned for this game, and none imitates a named performer or a character.

| Line | Voice (library name, id) | Prompt, with direction tags | Takes | Raw length | Credits |
|---|---|---|---|---|---|
| Owner | Bradley, `IzFL458lJFnp5DUApI6q` | `[flat, tired, close to the mic] who is that. [pause] i didn't make her.` | 2 of 4 requested (one stuck pending, one refused) | 5.84 s, 4.24 s | 71 each |
| Wren | Fena, `BlgEcC0TfWpBak7FmvHW` | `[small, earnest, quietly hopeful] I'll keep it warm. Your slot. [softer] In case.` | 2 of 4 (2 refused) | 3.92 s, 4.00 s | 81 each |
| Rue | Karla, `0TfZ4rvne3QI7UjDxVkM` (also used for the earlier memory narration) | `[quiet, gentle, close] go. [pause] it only fits one.` | 1 of 4 (3 rate-limited) | 2.64 s | 52 |

- **Flows** (ElevenLabs workspace): `FcS1DR0knR1cSl9PtLGp` (Owner), `CYFBk3unuqyTEpAYJ91F` (Wren), `wLicdswNVZK55aYUxymK` (Rue).
- **Local copies:** `narration_review/pilot_final_wren/`. This folder is git-excluded and Godot-ignored, so the takes are not in the repository or in any build.
- **Copies for review:** under `ogg/`. Leading and trailing silence was trimmed at −55 dB and the takes were loudness-normalised to −18 LUFS integrated, −1.5 dBTP.

**Measured before normalising:**

| Take | Integrated loudness | Peak |
|---|---|---|
| Wren, take 1 | −34.7 LUFS | −14.8 dBFS |
| Wren, take 2 | −37.5 LUFS | −15.7 dBFS |
| Rue | −49.6 LUFS | −34.7 dBFS |
| Owner, take 1 | −36.5 LUFS | −19.5 dBFS |
| Owner, take 2 | −28.0 LUFS | −13.9 dBFS |

The raw takes are far too quiet for the −18 LUFS dialogue target in `ASSET_PRODUCTION.md`. The Rue take is very quiet even for a whisper.

## What has not been checked

- **Nobody has listened to any take.** These are headless measurements only. The following are all unknown:
  - whether the words are right;
  - whether the direction landed;
  - whether there are artefacts.
- **No transcription check was run.** ElevenLabs refused further requests (see the licence section).

## Licence: why these don't ship

During this session ElevenLabs refused generations with this message:

> Free Tier access has been disabled … Please upgrade to a paid subscription to continue.

So the workspace is on the **free tier**.
- ElevenLabs' free tier does not grant commercial-use rights, and it requires attribution.
- Whether a free, non-commercial web game counts must be checked against ElevenLabs' current terms by the project owner.
- No subscription was bought.

**To ship generated voice, one of these is needed:**
1. a paid ElevenLabs plan that grants commercial rights to the output, checked against the terms on the day; or
2. human performers recorded under a written agreement (`ASSET_PRODUCTION.md`).

## Installing an approved take

No code change is needed:
1. Copy the chosen take to `audio/voice/<id>.ogg`. For example: `audio/voice/final.wren.303565e2.ogg`.
2. Add a row to `audio/voice/CREDITS.md` with:
   - the performer or voice;
   - the tool and plan;
   - the date;
   - the licence.
3. Regenerate the manifest:

   ```
   godot --headless --path . -s res://tools/voice_manifest.gd
   ```

   Its `status` column then says `recorded`.

`VoiceOver` plays a line whenever its file exists:
- it ducks the music by −9 dB while it plays (`test_auto_waits_for_the_voice_then_the_delay` checks the duck target);
- it pauses with the game;
- it stops when its scene ends.
