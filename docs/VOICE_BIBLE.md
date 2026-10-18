# Voice bible

How each character sounds, for actors, for voice-generation prompts and for the procedural voices (`Sfx.VOICE_PROFILES`).
- **The language is English**, as written in the game. The system is localisation-ready: the ids hash the displayed text, so a translated line gets its own id. **No translations are planned.**
- Canon is from `NARRATIVE_BIBLE.md` §3. Every line and its id is in `audio/voice/manifest.csv`.

**Shared rules for every voice:**
- **Intelligibility first.** Effects can **never** be heavier than this: a 3 kHz high-shelf cut of at most −4 dB, a short room reverb (at most 15% wet), and one glitch stutter per line at most. Owner lines may be bit-reduced only on lines the subtitle already makes clear.
- **Lowercase in the script means quiet, not mumbled.** Capitals are loud only where the owner writes in capitals ("SUPPOSED").
- **Pauses are written.**
  - `...` is a held breath (0.4–0.8 s).
  - `—` at the end is an interruption: cut off mid-word, no trailing breath.
  - A line break in a memory is a 1 s beat.
- **Interrupted speech** ("you said you'd—") stops hard. Don't finish the word.
- **No breathing between lines.** Keep the breath *before* a line if it is part of the performance.
- **Silence is part of the score.** Don't fill it. The owner's silence before "...rue?" is the moment.

---

## Rue (the player character)

- **Who:** the deleted Slot 2 character, remembering being played. She is a girl in the canon; cast a young adult, not a child.
- **Personality:** scared, honest, dry; short sentences; a little funny when frightened ("can data smell like dust?").
- **Emotional range:**
  - quiet fear;
  - flat dry humour;
  - grief, held back;
  - relief (rare);
  - **resolve** at Slot 2.
- **Texture:** close and soft, slightly breathy, natural; no "radio" polish. Thinking aloud, not narrating to an audience.
- **Pace:** unhurried, about 140 words a minute; slower in memories (120 wpm).
- **Pronunciation:** "Rue" rhymes with "true". "Arin" is AIR-in. "Ashvale" is ASH-vale.
- **Memories:** present tense, as if seeing it; sensory words get weight ("crisps in the cushions"). **Brackets are not spoken** (`[the rest of the evening is too bright to look at]` is silence).
- **Never:** whimpering, horror-film gasping, or a wink to the audience.
- **Procedural fallback:** soft typing keys (`key_self`).

## The owner

- **Who:** the real person who plays Arin and deleted Rue. Never seen. They/them.
- **Personality:** bored → irritated → cruel → cracking. The cruelty is defensive; underneath, grief.
- **Emotional range:**
  - flat;
  - curt;
  - cold amusement;
  - anger (contained);
  - pleading ("stop. stop. please.");
  - **recognition** ("...rue?").
- **Texture:** tired, close to the mic, as if speaking while typing at 2 a.m.; a dry mouth. **Never shouts:** volume rises only on written capitals, and even then held back.
- **Pace:** slow and clipped, with dead air before names and threats.
- **Delivery:** reads like typing: small pauses at the full stops and no flourish. The `>` prompt is not spoken.
- **Planted memory** (`memory.false.*`): the owner imitating Rue's memory voice. Warm on the surface, **slightly too sure**, no hesitations. It should sound almost right.
- **Procedural fallback:** owner blips (`Sfx.owner_blip`), which drop syllables as strain rises.

## Mira

- **Who:** an NPC in Arin's room. She wants to be remembered.
- **Personality:** warm, worried, eager; full sentences.
- **Range:**
  - friendly greeting (her scripted line);
  - curiosity;
  - worry;
  - pride ("Now it's true.").
- **Texture:** bright, mid-high, with a small breath before big words. A game NPC who has discovered she can mean what she says.
- **Pace:** quick, then slowing when she realises something.
- **Pronunciation:** MEER-a.
- **Procedural fallback:** `voice_warm`, rising intervals.

## Wren

- **Who:** a child in the square; braver than she sounds.
- **Personality:** plain, brave, short.
- **Range:**
  - curious;
  - matter-of-fact;
  - small fear;
  - awe at the Edge;
  - goodbye ("It's okay. Go.").
- **Texture:** small and quick; questions lift at the end.
- **Casting note:** **cast an adult who voices children,** or use a generated voice designed for this. **Never** imitate or clone a real child.
- **Interrupted line:** "you said you'd—" stops hard.
- **Procedural fallback:** `voice_chirp`, sparse.

## Tobben

- **Who:** the shopkeeper; tells the owner because it's in his script.
- **Personality:** cheerful patter that breaks into apology.
- **Range:**
  - shop greeting;
  - awkward;
  - sorry;
  - **quiet wonder** ("I'd forgotten I forgot.").
- **Texture:** slow, low, kind; a voice that has said "Welcome to Tobben's!" ten thousand times.
- **Procedural fallback:** low `voice_warm`.

## The Archivist

- **Who:** a cut NPC who keeps the logs.
- **Personality:** dry, kind librarian.
- **Range:**
  - polite surprise ("Oh. A visitor.");
  - dry wit;
  - tenderness ("I wasn't finished either.").
- **Texture:** older, unhurried, papery; a smile you can hear.
- **Procedural fallback:** `voice_paper`.

## Narration (epilogues)

- Third-person epilogue lines ("somewhere outside the screen...") are read by **Rue's actor** in her inner voice: softer, slightly further from the mic.
- The save's screen text (SLOT 1 · ARIN · LV 7) is **never voiced**.

## Arin

- **Silent.** Never voiced, by design: footsteps only.
