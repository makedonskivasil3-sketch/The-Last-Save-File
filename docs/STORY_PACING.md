# Story pacing

How every line of story reaches the player, and why. The code is:
- `scripts/ui/story_pacing.gd` (`StoryPacing`): the shared timing rules;
- `scripts/ui/line_pacer.gd` (`LinePacer`): one line's state;
- `scripts/ui/hud.gd`: the routes that show text;
- `scripts/audio/voice_over.gd`: recorded lines.

Tests: `tests/test_story_pacing.gd`.

## The routes

| Route | Examples | How it advances |
|---|---|---|
| **Dialogue box** | Mira, Wren, Tobben, the Archivist, books, notes, files | `LinePacer`: manual by default, auto optional |
| **Cinematics** | the boot, the memories, the planted memory, Mira's pinning, the guest book, the Slot 2 recap, the final exchange, the epilogue | `LinePacer`, the same rules as dialogue. **Holding** interact/confirm for 1.2 s skips the rest |
| **Console** (ambient) | owner lines, Rue's thoughts, system lines | Plays *during* play, so it never waits for input. Each line gets reading time; owner lines go first |
| **Tutorial tips** | first-session tips | Stay up at least 8 s, longer for long tips (1.5 × the reading allowance). They hide behind dialogue, scenes, questions and banners |
| **Banners** | "◀◀ LOADING AUTOSAVE", "THE EDGE IS UNLOADING" | Real-time danger states. They are never queued behind story |
| **End cards** | ending titles, death cards | Wait for confirm |

## One line's life (`LinePacer`)

1. **REVEALING.** The typewriter runs at the player's *text reveal* speed (Slow / Normal / Fast / Instant). With a recording, it is never slower than the voice needs: the whole line is visible by 85% of the clip.
   - **The first advance press reveals the whole line, and does nothing else.**
2. **SHOWN.** The whole line is visible and the continue marker appears: `▼ [E]` (`close [E]` on a dialogue's last line, `auto ▸` in auto mode). The marker pulses gently, or stays steady with Reduce flashing.
   - **Manual** (the default): **a later press advances.** A press on the same frame the line became complete never also advances it (`LinePacer.press`), so one press can't both reveal and skip a line.
   - **Auto:** the line advances by itself once **both** its reading allowance and its voice (a recording, or system speech if on) have finished, **then** the *delay after voice*.
3. **DONE.** The voice stops; the next line starts.

**Time only passes while the game runs.** Pausing, opening a menu or losing focus freezes the typewriter, the allowance and the voice; the line keeps what it had left.

## The reading allowance

Time to read a line that is **fully visible**. It never runs during the typewriter:

```
raw  = 0.8 s + letters / 14 + 0.4 s × sentence ends + 0.15 s × clause marks
time = clamp(raw / speed, 1.6 s, 30 s)        speed: Slow 0.75 · Normal 1.0 · Fast 1.35
```

- **30 s is only a bound for runaway text.** There used to be a flat 10 s cap, which cut the longest authored lines short on Slow (about 150 characters need 13 s).
- A line longer than **180 characters is shown in pages** (`StoryPacing.pages`), split between sentences where possible. Each page gets its own allowance.
- A recorded line is never split, because it is one performance.

- **letters** ignores spaces and the owner's `>` prompt. 14 letters a second is about 170 words a minute: comfortable for a second-language reader on a small screen.
- **Sentence ends** are `.` `!` `?` followed by a space or the end of the line. An ellipsis counts once.
- **Clause marks** are `,` `;` `:` `—` `–`.

Examples (Normal):

| Line | Allowance |
|---|---|
| "ok." | 1.6 s (minimum) |
| "a second controller, the cable taped where the dog chewed it, two people on one couch." | 6.6 s |
| A 200-word paragraph | Shown as about 6 pages, each with its own allowance |

The **console** uses the same allowance as the gap before its next line (at most 6 s). With 3 or more lines waiting, **system lines** drop to the 1.6 s minimum, so a backlog never goes stale. Thoughts, people and the owner keep their time. Every console line is in the History.

## Priority and queuing

1. **A question (choice), a cinematic, or the dialogue box owns the screen.** While one is up:
   - the console *holds* its next line (nothing types into a hidden box);
   - tips hide;
   - only one story voice ever plays (`VoiceOver` stops the previous line).
2. **Urgent warnings are never queued.** Banners and the owner's warnings appear on screen at once (`Hud.warn`), whatever is typing or open, including a conversation. A warning has its own strip under the banner. It stays for its reading time (at least 2.5 s), is in the History once, and comes down when the threat ends.
   - Warnings: the save-over, the reload warning and the reload, standing still, Mira's reset, Wren's deletion.
   - Tips hide while a banner or warning shows.
3. **Other owner console lines go ahead** of queued thoughts and system lines, and wait at most 0.8 s behind the line on screen.
4. **Rue's thoughts and system lines** follow, each with its reading time.
5. **Nothing is lost:** everything actually shown is kept in **Pause → History** (300 entries per run), with speaker names. Lines still waiting in the queue aren't in it, so no spoilers.

## Reading is safe

- **While a conversation is open, Rue stands still and so does the owner**, as for a question:
  - awareness doesn't climb;
  - no move starts;
  - a save ring that is already filling holds where it is.

  Everything resumes, visibly, when the box closes.
- **A death card waits for the player.** The retry prompt appears after 1.2 s the first time a cause kills you, or 0.5 s for a cause you have died from before. Until then, presses are ignored, so mashing doesn't skip the advice.
- See `NARRATIVE_RELIABILITY.md` for the whole safety matrix.

## Skipping

- **Skipping a whole scene needs a deliberate hold** of interact/confirm for 1.2 s. A "skipping ■■■□□□" meter fills from 0.25 s, so a tap can't skip by accident.
- Only a hold that **began during the scene** counts, not one carried in from a glitch.
- **Skipped lines still go to the History.** Skipping never skips **consequences:** the memory still counts, the ending still happens.

## Saving and quitting mid-scene

The game saves the owner's memory, not a mid-scene position. The rule is: **a story beat's consequences apply only once it has played through.**
- A memory is counted (fragment, journal, restored colours, new glitch) only after its scene ends.
- Quitting mid-memory changes nothing, and the memory is still there next run (`test_quitting_mid_memory_keeps_the_story_coherent`).
- Nothing is applied twice: the journal de-duplicates by id, and fragments by name.

## Pause and focus

- The pause menu stops everything, including a recorded voice, which resumes where it was.
- **Losing window focus** (alt-tab, a notification) opens the pause menu during play. During an ending, it holds the scene and resumes when focus returns.
- The behaviour is set by **Pause when unfocused**, on by default.

## Settings (Settings → Story text)

| Setting | Default | Why this default |
|---|---|---|
| Text reveal: Slow / **Normal** / Fast / Instant | Normal | The established feel; Instant is there for fast readers and screen-reader users |
| Advance: **Manual** / Auto | **Manual** | Nobody is rushed. The game is about reading what was left behind |
| Auto reading: Slow / **Normal** / Fast | Normal | 170 wpm. Also paces the console |
| After voice: 0 / **0.5** / 1 / 2 s | 0.5 s | A beat after a spoken line, so it lands |
| Subtitles: **Normal** / Large / Larger | Normal | ×1 / ×1.2 / ×1.4, on top of Large text |
| Text backing | 0.75 | Strong enough over the CRT and lighting; 0 leaves the text outline |
| Speaker names | On | Who is speaking is never carried by colour alone |
| Pause when unfocused | On | Nothing happens while the player is away |

Separate **Master, Music, Effects and Voices** volumes are under Sound. **No objective or story event needs audio:**
- every voiced line is also its subtitle (`test_no_line_needs_audio_to_be_understood`);
- warnings are banners and the warning strip;
- recordings that are missing fall back to text.
