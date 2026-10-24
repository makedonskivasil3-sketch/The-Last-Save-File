# Voice audition pilot (vertical slice)

**Status: script, cue sheet and manifest only. No voice was recorded or
generated for this pilot; the acting is outstanding.**
- No credits were spent and nothing was bought (per the brief).
- A person must listen to the auditions before any line is produced at
  scale.
- Earlier generated takes (`VOICE_PILOT.md`) remain unlistened and
  unshippable on the free tier.

The four kinds of voice (`ASSET_PRODUCTION.md`) stay distinct:
**recorded acting**, **generated acting**, **system TTS** (off by
default; not acting) and **written-only** (procedural blips).

## 1. What an audition must show

Five short exchanges, one per emotional register the slice needs. Every
line is a real line from the game, so a take that passes can go straight
into `audio/voice/<id>.ogg` (ids in `audio/voice/manifest.csv`).

| # | Register | Exchange | Characters |
|---|---|---|---|
| A | Intimate | Wren's chalk mark at the well (`Relationships.WREN_MARKED`) | Wren, Rue (thought) |
| B | Fearful | Mira after seeing Rue taken (`Relationships.MIRA_AFTER_DEATH`) | Mira |
| C | Humorous | Tobben's welcome, failing (`VillageSquare.TOBBEN_LINES`) | Tobben |
| D | Revelation | Slot 2, the owner recognises Rue (`Story.FINAL_EXCHANGE.rue`) | the owner, Rue |
| E | Whispered | Answering the well (`WellSequence.ANSWER_LINES`) | Rue |

## 2. Script with performance direction

Directions build on `VOICE_BIBLE.md`. Cast adults only. Wren and Rue are
child-like characters played by adult performers; never a real child's
voice, and never a clone of any identifiable person.

### A. Intimate: "so you'd find your way up" (Wren)

The first warm moment after a death. She has been waiting. She is
proud of the drawing and shy about it at once.

| Line | Direction |
|---|---|
| WREN: There you are! I did a mark. On the rim, look. | Relief arriving before the words; the "look" is a small invitation, not a command. |
| WREN: That's you. The two dots are your eyes. I'm not good at hands, so you haven't got any. | Matter-of-fact child logic; a tiny laugh at herself on "hands". Don't play it cute. |
| WREN: It's so you'd find your way up. If you came up. ...You came up. | The pause before the last sentence is the whole scene: she hadn't been sure. Quieter, not sadder. |
| WREN: Don't tell Arin it's chalk. He thinks chalk is how you start a fire. | Conspiratorial; back to play. Let the joke land flat; she believes it. |

### B. Fearful: "you went grey" (Mira)

She saw it happen in her own room and couldn't move. She's afraid of the
answer, so she offers Rue a way not to give one.

| Line | Direction |
|---|---|
| MIRA: You went grey. Right there, on the rug. And then you were gone, and the room said everything was fine. | Held breath; she keeps her voice level because the room is listening. "said everything was fine" is the frightening part. |
| MIRA: Is it always like that? You don't have to answer. I'm just glad it's you again. | The question is barely asked; the reassurance is for herself as much as Rue. A small exhale on "again". |

### C. Humorous: "you don't have an inventory" (Tobben)

A shopkeeper whose script keeps breaking against a customer who
shouldn't exist. Comedy from timing, never from a silly voice.

| Line | Direction |
|---|---|
| TOBBEN: Welcome to Tobben's! Finest wares in Ashvale! | Full pitch, rehearsed a thousand times. |
| TOBBEN: Welcome to Tobben's! Finest... you don't have any gold. You don't have an inventory. | The pitch runs into a wall mid-word; genuine bafflement, a little offended on Rue's behalf. |
| TOBBEN: Welcome to... I have to tell them, you know. It's in my script. | Apologetic, almost whispered aside; the welcome dies on its own. |

### D. Revelation: "...rue?" (the owner, Rue)

The owner recognises who is in Slot 2. It must not be a villain beat:
it's a tired person meeting something they lost.

| Line | Direction |
|---|---|
| OWNER: > what are you doing in slot 2. | Flat, close to the mic, no question mark; irritation covering fear. |
| RUE: (you know what i'm doing. you've always known.) | Very close, unhurried, kind. Not an accusation. |
| OWNER: > ...rue? | Two beats of silence first. The name is barely voiced, as if typed by someone holding their breath. |
| RUE: (hi.) | The smallest possible word. Warm. Do a take that is almost a laugh and one that is almost crying; pick in the edit. |

### E. Whispered: "i'm here" (Rue)

Rue answers a recording that can't hear her. The whisper must stay
intelligible over the game's ambience at −18 LUFS (record a normal-voice
safety take too).

| Line | Direction |
|---|---|
| RUE: (i'm here.) | Whisper with some voice in it, mouth close to the mic; the line is a promise, not a secret. |
| RUE: (nothing comes back. that isn't what it does. it keeps.) | Thinking aloud, steadier; disappointment accepted mid-sentence. |

## 3. Cue sheet

Lengths are estimates at a natural pace (not measured; nothing has been
recorded). The manifest's `duration_s` column fills in when files exist.

| Cue | Manifest scene | Speaker | Lines | Est. length | Takes to record | In-game trigger |
|---|---|---|---|---|---|---|
| A | `npc.wren` | WREN | 4 | 14 s | 3 per line | Back up the well after waking under it (`VillageSquare._mark_process`) |
| B | `npc.mira` | MIRA | 2 | 11 s | 3 | First talk after she saw Rue taken |
| C | `npc.tobben` | TOBBEN | 3 | 10 s | 3 | Talking to Tobben, first three times |
| D | `final.rue` | OWNER, RUE | 4 | 9 s + 2 s silence | 4 (Rue's "hi": 6) | Slot 2, the Rue ending |
| E | `well` | RUE | 2 | 6 s | 3 whispered + 1 voiced | Answering at the rim |

Total: 15 lines, about 50 s of finished audio and roughly 1,000
characters of text. Format, loudness and file naming are as in
`ASSET_PRODUCTION.md` (WAV source; Ogg Vorbis, −18 LUFS, ≤ −1 dBTP at
runtime).

## 4. Two routes, compared

| | Human recording | Licensed generated voice (ElevenLabs as the example) |
|---|---|---|
| Consent | A written agreement per performer: the game, platforms, payment, credit, and **no AI training, cloning or reuse** of their voice | Only voices offered for commercial use (Voice Library or designed voices); never a clone of an identifiable person without written permission. Library voices may carry their creator's extra terms: read each listing |
| Commercial rights | Granted by the agreement | Reported to need a paid plan; the free tier is reported to have **no commercial rights** and to require attribution ([bigvu](https://bigvu.tv/blog/elevenlabs-pricing-2026-plans-credits-commercial-rights-api-costs/), [dupple](https://dupple.com/learn/is-elevenlabs-free), [smallest.ai](https://smallest.ai/blog/elevenlabs-alternatives-for-commercial-use-licensing-checklist-and-safe-workflows)) |
| Cost of this pilot | Per-line or per-hour rates agreed with each actor (union rates differ; SAG-AFTRA's indie tiers are reported at roughly $338 to $3,500+ by tier and task, [Game Developer](https://gamedeveloper.com/audio/sag-aftra-launches-new-contract-tiers-for-indie-devs); unverified against the current rate card) | Starter plan, reported at $5–6/month with about 30k credits ([bigvu](https://bigvu.tv/blog/elevenlabs-pricing-2026-plans-credits-commercial-rights-api-costs/), [smallest.ai](https://smallest.ai/blog/elevenlabs-pricing-plans-cost-what-you-get-in-2026)); ~1,000 characters × 3 takes ≈ 3k credits |
| Export | WAV 48 kHz/24-bit from the session | WAV/PCM on higher plans, MP3 otherwise (confirm on the plan page) |
| Direction | Live, with the bible and this sheet | Prompt tags per line; less control over timing (the earlier pilot's takes were 15–30 dB too quiet) |
| Platform disclosure | None | Steam asks developers to disclose pre-generated AI content players hear, voice included ([VGC](https://videogameschronicle.com/news/valve-has-significantly-rewritten-steams-rules-for-how-developers-much-disclose-ai-use), [tbreak](https://tbreak.com/steam-ai-disclosure-policy-update-developers/)) |
| Other | Performers can be credited and rebooked for later scenes | The provider may keep a licence to use generated output to improve its models ([Cinevva guide](https://app.cinevva.com/guides/ai-voice-acting-games)) |

**Verification limits.** The ElevenLabs pricing page and terms could not
be fetched from this environment (DNS failure), and Valve's text was not
read directly. Every figure above comes from third-party summaries dated
2026 and must be checked by the project owner on the day of purchase.

**Recommendation (author decides):**
1. Audition the five exchanges with **human performers first**. These are
   the scenes where acting carries the twist (D) and the attachment (A).
2. Keep generated voice as a fallback for incidental lines only, on a
   paid plan whose terms were read in full, with Steam disclosure.
3. Whichever route is used, someone must listen to every take before more
   lines are produced.

## 5. Manifest

The ids, subtitles, speakers and directions for every line above are
already in `audio/voice/manifest.csv`, regenerated by
`tools/voice_manifest.gd`. This slice added Wren's two chalk-mark
variants (7 new rows). Status for all 15 audition lines:
`text only (not recorded)`.
