# Voice script (AI voices for key lines)

The author chose this on 2026-10-17: **ElevenLabs voices for key lines only**, about 60–100 lines. Everything else keeps the text plus the procedural voice blips.

## Status

**No line has been recorded yet.** The pilot (one memory for Rue, one owner line) was attempted on 2026-10-17 and ElevenLabs refused it:
- The account had **55 credits** left; the pilot lines needed 56 and 231 credits each.
- The service also reported: "Unusual activity has been detected on your account, so Free Tier access has been disabled … Please upgrade to a paid subscription to continue."

Nothing was generated and the game ships no recordings. To continue, the account needs a paid plan. A rough cost is about 1 credit per character on `eleven_v4`, so ~100 lines × ~80 characters is roughly 8,000–10,000 credits per take.

## How it works in the game

- `scripts/audio/voice_over.gd` (`VoiceOver`) plays `res://audio/voice/<id>.ogg` (or `.mp3` / `.wav`) on the **Voice** bus, which the Voices volume slider controls.
- **A missing file is normal.** That line keeps its procedural voice, and nothing else changes (`tests/test_voice_over.gd`).
- **Subtitles always show.** A recording never replaces the text.
- If the player skips ahead, the recording stops with the text.
- **Wired so far:** the memories (`memory_<id>`), including the planted one.
- **Not wired yet:** the owner's notes, the character introductions and the endings. Each needs a call site, added the same way once its lines are recorded.

## Voices (picked from the ElevenLabs library, 2026-10-17)

| Character | Voice | Why | Direction |
|---|---|---|---|
| Rue (she) | **Karla**: breathy, expressive young American woman (`0TfZ4rvne3QI7UjDxVkM`) | Soft and close, like someone remembering | `[softly]`, `[quietly]`; lower case, unhurried |
| The owner | **Bradley**: quiet, deliberate, grounded (`IzFL458lJFnp5DUApI6q`) | Never shouts; tired, not theatrical | `[tired, flat, close to the mic]` |
| Mira, Wren, Tobben, the Archivist | not picked yet | One voice each, with clearly different ages and pitches | Keep it short: introductions only |

The user can still change any of these in ElevenLabs before recording.

## Lines (ids → text source)

The text is **not copied here**, so it can't drift from the game. Each id says where its text lives.

| Id | Speaker | Text from | Notes |
|---|---|---|---|
| `memory_controller` | Rue | `Story.FRAGMENTS` "controller" `lines` | Leave out the `[bracketed]` stage line, or read it as a whisper |
| `memory_well` | Rue | "well" | |
| `memory_new_game` | Rue | "new_game" | |
| `memory_argument` | Rue | "argument" | |
| `memory_delete` | Rue | "delete" | |
| `memory_false` | **The owner**, imitating Rue | `Story.FALSE_FRAGMENT` | The planted memory: it should sound slightly wrong |
| `owner_note_<n>` | The owner | `Story.OWNER_NOTES[n]` | Not wired yet |
| `intro_<npc>` | Each NPC | their first line in each area script | Not wired yet |
| `ending_<id>` | Rue / the owner | `Story.ENDING_*` | Not wired yet |

## Licence and credits

ElevenLabs output on a **paid** plan can be used commercially. The free tier requires attribution and doesn't allow commercial use. Check the plan's terms when recording.

The Credits screen must then add "Voices generated with ElevenLabs", and `RELEASE_READINESS.md` must drop "no third-party assets".
