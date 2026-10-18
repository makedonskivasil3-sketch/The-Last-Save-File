# Story pacing and cast pass

**Branch:** `claude/story-pacing-cast-pass`.
- **Base:** `playtest/first-minutes-fairness`, which already contains `game-presentation-polish`.
- **Merged in, without losing or duplicating work:**
  - the lighting and journal branch;
  - `codex/player-experience` (console history, the compact pause grid).
- The audit is in `STORY_PACING_AUDIT.md`.

**Nothing here is a human playtest result.** Audio was **not heard** (headless and xvfb only). **Windows was not launched.**

## What changed, and what the player gets

| Change | Player benefit |
|---|---|
| **Story waits for the player.** Every dialogue and scene line: the first press shows it all, the next press moves on. One press can never do both | Nobody is rushed. Previously every memory, the boot and the endings moved on after `2.4 s + 0.045 s per letter`, read or not (before/after below) |
| **Optional auto mode**: waits for the reading allowance (from length and punctuation, 1.6–10 s) **and** the voice, then a delay | Hands-free reading that never cuts off a voice |
| **One timing rule for every route** (`StoryPacing`, `LinePacer`): dialogue, scenes, console, tips | Consistent behaviour; documented in `STORY_PACING.md` |
| **The console** holds behind dialogue and scenes, gives each line reading time, wraps instead of truncating, and lets **owner warnings jump the queue** (at most 0.8 s wait) | No lines lost unseen; warnings stay prompt |
| **Hold to skip** a scene (1.2 s, with a meter); skipped lines still go to the History; consequences still apply | Repeat players can skip; nothing is skipped by accident |
| **History** (Pause): everything said this run, speakers, replay of recorded lines | Recover any missed line |
| **Pause on focus loss** (a setting, on by default) | Alt-tab doesn't cost a death or a line |
| **Story text settings**: reveal speed, manual/auto, reading speed, delay after voice, subtitle size, backing opacity, speaker names | Readable on any screen, for any reader |
| **On-screen goal** under the save header whenever it changes | The next step is always known without a menu |
| **One thing to read at a time**: scenes close dialogue and clear act cards; dialogue clears act cards; tips hide behind banners | No stacked text |
| **"+N · why"** stays for its reading time, below the meter's state word | The reason for an awareness jump can be read |
| **Rue's portrait**: six expressions, drawn from her sprite's palette and restoration order (void face until her last memory) | The protagonist has a face, and it tells her story |
| **Memories count only once lived through**: quitting mid-memory changes nothing | Coherent saves; no half-applied beats |
| **Voice pipeline**: stable dialogue ids, a 118-line manifest kept in sync by tests, one voice at a time, pause/duck/stop/replay, missing files fall back to text | Ready for recorded or generated lines with no code changes |
| **Fixes**: the desk lamp was inside its own shadow-caster; journal text couldn't scroll by key or pad; Arin's cone was dimmed by lighting | Each has a regression test that fails without the fix |
| **Docs**: `CHARACTER_ART.md` (direction, cast briefs, expressions), `VOICE_BIBLE.md`, `ASSET_PRODUCTION.md` (tools, formats, loudness, licensing, production guide) | The next art and voice work can start from a brief |

## Tests run (Godot 4.3, Linux container)

| Run | Result |
|---|---|
| Full suite, final code (`tests/run.sh`) | **288 passed, 0 failed**, exit 0, 676.5 s. The only warning is Godot's existing "ObjectDB instances leaked at exit" |
| New: `test_story_pacing` (20 tests) | All pass. They cover: the formula with short and long lines; reveal versus advance; same-frame protection; mashing; auto waiting for the voice and then the delay; the allowance starting after reveal; pause freezing text and voice; focus loss; leaving a scene stopping its voice; missing recordings; history with speakers; console reading time and wrapping; owner priority; quitting mid-memory; hold-to-skip keeping consequences; a tap never skipping; the Rue portrait matching her sprite; subtitle settings applying and persisting; the goal line |
| New: `test_voice_manifest` (3), `test_lighting` (2), the journal scroll test | Pass. The lamp and journal tests were **confirmed to fail** with their fixes reverted |
| Bot playthroughs to endings (`--bots --speed=2`) | **4 of 4 endings reached:** escape (2 sessions), message (2 sessions), escape at purge 3 (1 session), wren (1 session). The Wren run logs 13 "stalls" inside its cursor-luring loop at the Edge, which retries 1 s moves; the others logged 0 |
| Windows export | **Exit 0.** PE32+ x86-64 GUI executable with the game pack embedded, 84.7 MB. **Not launched on Windows** |
| Linux export and smoke test | Exit 0; the exported game runs 240 frames headless with no script errors |

**Changed existing tests:** in each case the new behaviour is intended, and no assertion was weakened.
- Three tests, and the bots, waited for scenes to advance by themselves. They now read through them like a player (`read_through_cinematic`).
- `test_text_speed_setting` asserted `visible_characters == length`. It now accepts Godot's `-1` (all visible) as well, and also checks that the line counts as revealed.

## Before and after (staged, software GL, xvfb)

| | Before (`bd3b1f1`) | After |
|---|---|---|
| A memory, no input for 6 s | `review/before_memory_line1.png`, then `review/before_memory_after_6s_no_input.png` (it moved on by itself) | `review/after_memory_rue_portrait.png` (it waits; Rue's portrait; continue marker) |
| Talking to Mira on arrival | `review/before_dialogue_under_act_card.png` (the act card over the dialogue) | `review/after_dialogue_goal_line.png` (the card clears; the goal line shows) |
| Ending | — | `review/after_epilogue_rue_restored.png` |
| Danger warning | — | `review/after_danger_reload_banner.png` |
| History | — | `review/after_history.png` |
| Large text, larger subtitles, effects off, reduced flashing | — | `review/after_large_text_dialogue.png`, `review/after_large_text_memory.png`, `review/after_settings_large_text.png` |
| Rue's expressions | — | `review/rue_expressions_missing.png`, `…three_memories.png`, `…restored.png` |

## Remaining limits

- **No recorded or generated voices ship.** The ElevenLabs account refused generation (free tier disabled, 55 credits). A paid plan is the only access needed (`ASSET_PRODUCTION.md`). System text-to-speech remains optional and is labelled as such.
- **Only Rue has portraits.** The other characters have briefs (`CHARACTER_ART.md`), and the dialogue box has a portrait slot ready.
- **Not verified:** audio by ear; physical controllers (only simulated events); Windows launch; phones; real-GPU frame times.
- Every screenshot is a staged automation shot, not a human session.
