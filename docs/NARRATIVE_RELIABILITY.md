# Narrative reliability and safety

- **Branch:** `claude/narrative-reliability`, from `main` at `f2fcf32`.
- **Regressions:** `tests/test_narrative_reliability.gd`. Each test was first run against `f2fcf32`, with the code unchanged, and failed. Those failures are listed under each finding.
- **Labels:**
  - **reproduced**: a committed test failed on `f2fcf32`.
  - **source**: established by reading the code.
  - **hypothesis**: needs playtesting.
  - **production**: work not done yet.

Nothing in this document is a result from a human playtest.

## Audit

### 1. Urgent warnings waited behind Slow typing and backlogs

**Label:** reproduced. **Severity:** high, because it causes unfair deaths.

**Problem.**
- Owner warnings were ordinary console lines (`OwnerDirector.say` → `Hud.say(…, "owner")`).
- They jumped ahead of queued lines, but still waited for the line being typed to finish, then a further gap of up to 0.8 s (`hud.gd` `_update_typing`).
- On Slow text (0.6×), a 150-character thought takes about 7 s to type.
- The save-over kills a player who stands still for 4 s (`OwnerMoves.SAVE_TIME`). Its warning ("saving over you.") could therefore arrive after the death it was announcing.
- The console is also hidden while a conversation is open, so a warning during dialogue was invisible.

**Reproduction.** `test_a_warning_is_readable_at_once_behind_slow_typing` and `test_a_warning_is_not_lost_in_a_backlog` failed on `f2fcf32`: "timed out waiting for the save-over warning on screen".

**Fix.**
- `Hud.warn()` puts warnings on their own strip under the banner. They show at once, whatever the console is typing or whatever is open.
- A warning stays for its reading time (at least 2.5 s) and is logged once in the History.
- `cancel_warning()` takes it down when the threat ends: the save is interrupted, the deletion is interrupted, or Rue changes area.
- **Lines sent through it:**
  - the save-over;
  - the reload warning and the reload itself;
  - "you stopped moving";
  - Mira's reset;
  - Wren's deletion.

**Acceptance.** Both tests pass. The warning is fully visible within 1 s.

### 2. A flat 10 s cap cut long lines short on Slow

**Label:** reproduced. **Severity:** medium (auto mode only; manual mode, the default, never times out).

**Problem.** `reading_time()` was capped at 10 s. The longest authored lines are about 150 characters, which need 13 s on Slow (0.75×). Nothing paginated text longer than one box.

**Reproduction.** `test_long_lines_get_the_time_they_need_on_slow` failed on `f2fcf32`:
- 125 letters on Slow: 10.0 s given, 13.0 s needed;
- 250 letters on Slow: 10.0 s given, 24.9 s needed.

**Fix.**
- `MAX_TIME` is now 30 s, a sanity bound only.
- `StoryPacing.pages()` splits any line over 180 characters between sentences, or between words if it has to. Each page gets its own allowance.
- The dialogue box and cinematics paginate through `Hud.paginate()`. A recorded line is never split, because it is one performance.
- Only system lines are hurried by a console backlog. Thoughts, people and the owner keep their reading time.

**Acceptance.** Both pacing tests pass. Joining the pages with spaces gives back the original text.

### 3. The death card restarted by itself

**Label:** reproduced. **Severity:** medium.

**Problem.** `World.kill` reloaded the scene after 2.8 s, or 3.6 s when there was a tip, whether or not the advice had been read.

**Reproduction.** `test_death_advice_waits_for_the_player` failed on `f2fcf32`: "the death card stays until the player is ready".

**Fix.**
- The card waits for a press of interact or confirm.
- The retry prompt appears after 1.2 s the first time a cause kills you, and after 0.5 s for a cause you have died from before. That is the fast path for repeat players.
- Presses before the prompt are ignored, so mashing doesn't skip the card.
- Input is ignored while the pause menu is open.

**Acceptance.** Both death tests pass. `tests/test_case.gd` `wait_for_new_session` now presses retry, as a player would.

### 4. Reading a conversation could kill you

**Label:** reproduced. **Severity:** high.

**Problem.** While a dialogue was open:
- awareness kept rising;
- the save-over could start, or keep filling;
- the cursor, the erasure and timed deletions kept running.

Only the square's Arin paused (`village_square.gd`). Rue could also walk up to 40 px while talking.

**Reproduction.** `test_reading_a_conversation_holds_the_owner` failed on `f2fcf32`:
- "no save-over starts under a conversation (expected -1, got 0)";
- "awareness doesn't climb while reading (76.1 → 81.3)".

**Fix.**
- A conversation holds the owner exactly as a question already did: `World._update_reading_hold`, which feeds `is_owner_paused()` and calls `Area.set_owner_paused`.
- Rue stands still while reading (`Player.reading`), so the hold can't be used to slip past anything.
- A save ring that is already filling holds where it is and resumes, visibly, when the box closes.
- One-off jumps that are explained still apply, such as "+N · talking to Mira".

**Acceptance.** `test_reading_a_conversation_holds_the_owner` and `test_a_save_in_progress_holds_while_you_read_and_resumes_after` pass.

> **Note on the second test:** the first version of it talked to Mira at HUNT, where she has already been deleted, so its failure on `f2fcf32` was partly an artefact of that setup. The committed version opens the conversation directly.

### 5. Ordinary dialogue had no voice id

**Label:** reproduced. **Severity:** medium (it blocked voicing every NPC line).

**Problem.** `World._interact` called `show_dialogue` without a voice prefix. Mira's and Wren's join and decline lines had none either.

**Reproduction.** `test_ordinary_dialogue_asks_for_a_voice_line` failed on `f2fcf32`: "Mira's line has a voice id".

**Fix.**
- People use `npc.<id>` and Pip uses `npc.pip` (`World.dialogue_voice_prefix`).
- The join and decline lines use `npc.mira` / `npc.wren`.
- What people remember (`Story.recall`) is now a table, so every possible line can be listed (`Story.recall_lines`).
- The areas list their constant lines (`ArinsRoom` / `VillageSquare` / `ArchiveArea.voice_lines()`).

**Acceptance.** The test passes. The id is in the manifest.

### 6. The manifest depended on the local save

**Label:** reproduced. **Severity:** medium (a regenerated manifest could silently drop lines).

**Problem.** `VoiceManifest._apply()` took its defaults from the live `OwnerMemory`. A save with `wren_saved = true` hid the "Wren was deleted" variants and changed which rows were written.

**Reproduction.** `test_the_manifest_does_not_depend_on_the_save` failed on `f2fcf32`.

**Fix.**
- Each state is built from a new game's state (`OwnerMemory.clear_state()`) plus one flag.
- The live save is snapshotted and restored around generation (`snapshot()` / `restore()`).

**Acceptance.** The CSV is identical from a clean save and from a played save, and the save is left untouched.

### 7. A memory was two saves

**Label:** source, now covered by a test. **Severity:** low (the window is two consecutive synchronous writes).

**Problem.** Recovering a memory wrote the journal page (`record_read`) and then, separately, the fragment (`add_fragment`). A crash between the two left a journal page for a memory that didn't count.

**Fix.** `OwnerMemory.keep_memory()` writes both in one save. `save_count` lets a test check it.

**Acceptance.** `test_a_memory_is_kept_in_one_write` passes.

### 8. A scene that interrupted a conversation cut its voice off

**Label:** source. **Severity:** low.

**Policy.** A cinematic hides an open dialogue and holds it, as it already did. When the conversation comes back, a recorded line is played again from the start, and the line is shown in full.

### Open items

| Item | Label | Note |
|---|---|---|
| Whether holding the owner during conversations makes the game too easy | hypothesis | Rue is frozen while reading, so nothing can be gained by it, but this needs observation |
| Whether 1.2 s is the right lock on the first death card | hypothesis | |
| Whether the warning strip is noticed during the hunt | hypothesis | Playtest question |
| NPC lines recorded | production | 0 of the new NPC rows are recorded |

## Safety matrix

What runs while each thing is open.

| Open | Rue moves | Awareness rises | Owner moves start | Save ring | Cursor and erasure | Warnings |
|---|---|---|---|---|---|---|
| Nothing | yes | yes | yes | fills | run | strip |
| Conversation | **no** | **no** | **no** | **holds** | **hold** | strip |
| Question (`choose_safely`) | no | no | no | holds | hold | strip |
| Cinematic (memory, guest book, endings) | no (`_cutscene`) | no (`director.paused`) | no | cleared or held | area process disabled | strip |
| Pause menu or focus loss | tree paused | no | no | holds | hold | — |
| PAUSE glitch | yes | no | no | holds | hold | strip |
| Death card | no | stopped | no | — | — | — |

**The rule:** no danger begins, or completes, while the player is reading something they did not choose to skip.

## Voice coverage (manifest rows by route)

- The manifest went from 117 to **196 rows**. Every row from `f2fcf32` is kept with the same id.
- No new row is recorded.

| Route | Stem | Policy |
|---|---|---|
| NPC conversation | `npc.mira` / `wren` / `tobben` / `archivist` / `pip` | Voiced when recorded. Lines with run counts in them ("You've been erased 3 times") stay as text plus a procedural voice |
| Join and decline lines | `npc.mira`, `npc.wren` | Voiced when recorded |
| Memories, boot, Mira's pin, guest book, finals, Slot 2 recap, epilogues | as before | Voiced when recorded |
| Owner warnings (strip) | — | Text plus the owner's blip. Warnings must not wait for audio |
| Console thoughts and ambient lines | — | Text plus procedural blips (not voiced in this milestone) |
| Notes, books, signs, terminals | — | Read silently (text) |

## Voice id stability

- Ids are `"<stem>.<first 8 hex of md5(text)>"`. Editing a line's text makes a new id, so an outdated take never plays under new words.
- Reordering lines, or adding lines, changes nothing.
- `test_the_manifest_matches_the_story_text` fails while `audio/voice/manifest.csv` is stale, and it checks that ids are unique.
- Production metadata (actor, take, licence) belongs in `audio/voice/CREDITS.md`, not in the id or in the generated manifest.

## Milestone D: focused refinement review

This milestone stayed deliberately narrow. Each item below either has a change backed by evidence, or is labelled as a question for a playtest. **Nothing here is evidence that the game is enjoyable.**

| Item | Label | Finding | Action |
|---|---|---|---|
| ObjectDB leak at exit | reproduced (`--verbose`) | Running the title screen for 600 frames and quitting leaked one generated `AudioStreamWAV` and its playback. Godot 4.3 keeps a generated stream's playback alive when its player is freed while still sounding | **Fixed:** `Sfx` stops every `AudioStreamPlayer`/`2D` as it leaves the tree. The title run now leaks **0** instances |
| Leaks reported when quitting mid-scene | source + reproduced | Quitting during the boot cinematic still reports suspended coroutines (`GDScriptFunctionState`, the scene's `LinePacer`, a `Tween`) and in-flight audio playbacks. These are freed by process exit, not leaked during play | Left as is; documented. Watching object counts during play is a follow-up |
| A reload could drag Rue out through a doorway | reproduced (`test_a_reload_never_lands_on_an_exit` fails with the fix disabled) | `load_last_save` drags Rue back along up to 10 s of her path. Arriving through a doorway and being reloaded soon after could pull her back onto the exit, which then took her to the previous area. This bug is already on `main` | **Fixed:** a reload never goes back past a moment within 16 px of an exit (`OwnerMoves.EXIT_CLEARANCE`) |
| The purge-3 bot left the Edge by accident | reproduced (twice) | After its sidestep "slide along" move, the bot stepped down into the Edge's south doorway and ran its Edge script in the square. The run had diverged from `main` earlier (on `main` it died to the static at the same point and finished in session 2) | Bot only: a sidestep never steps into a doorway. Same outcome as on `main`: escape in 2 sessions |
| A conversation banked the owner's next move | reproduced (`test_a_conversation_doesnt_bank_the_owner_s_next_move` fails without the fix) | While a hold was on, the owner's cadence clock kept running, so the next save-over (or Wren's deletion) could start the moment the box closed | **Fixed:** the cadences wait while the owner is held |
| The Wren bot reaches the Wren ending less often | bots (small samples); cause **not established** | Wren ending: `main` 1 of 1 runs (one session). This branch with the conversation hold switched off: 2 of 2. With the hold: 2 of 6 (the others ended on *escape* after Wren was lost to the cursor or Arin in the square). The bot passes either way, because it only checks for some ending. The hold also keeps awareness from rising while reading, which shifts when the hunt reaches the square | Kept the hold; it is the safety rule. **Playtest risk:** does escorting Wren feel harder? |
| The planted memory | source | After the planted memory, `_took_false_memory` starts a save-over at once. Before this branch its warning waited for "MEMORY REJECTED" to type and for the owner's "that's how i remember it." ahead of it | Fixed by the warning strip (finding 1); the warning is now immediate |
| Supporting characters' desires | source | Each has a want the player can act on: Mira wants to see the square (escort, notice board); Wren wants to see the Edge (escort); Tobben wants the second name back (the guest book page) | Mira's portrait now carries hers (eager, proud, reset). Whether players notice the wants: **hypothesis**, see the round questions in `PLAYTEST_PLAN.md` |
| Persistent difficulty across purges | source | Each purge adds 10 starting awareness (capped at 35) and 0.15/s to the rate, up to purge 6. The purge-3 bot reaches an ending | Not changed. The reading hold removes one source of unfair purge progress (deaths while reading). Whether purges 4–5 are too hard: **hypothesis** |
| First ten minutes | hypothesis | Earlier passes covered the opening, tested by `test_first_minutes`, `test_onboarding` and the bots. This pass changes it in three ways: death cards wait for a press, Mira's first conversation shows her face, and conversations hold the owner | Observe in the next round |
| Endings and replay value | hypothesis | Six endings, with a record and hints on the records screen. Recall lines change with past runs (now a table, `Story.RECALL`) | No change without playtest data |
| Glitch feedback | source | "+N · why" stays for its reading time under the meter (earlier pass) | No change |
| Presentation and audio consistency | source | Owner warnings now always use the same strip, colour and blip; death cards share one retry prompt; portraits share one contract | Done in milestones A and C |
| Extracting HUD/World responsibilities | source | `hud.gd` grew by the warning strip and the portrait animation, each about 40 lines with one entry point (`warn`, `show_dialogue(…, portrait)`) | Not extracted. Splitting it now would move code without making anything safer. Revisit when a third portrait character is added |

## Validation (code at `25f3894`, plus this doc)

Godot 4.3, Linux container.

| Check | Result |
|---|---|
| Full suite (`tests/run.sh`) | **309 passed, 0 failed**, exit 0, 684 s. The previous base was 291 |
| New and changed tests | `test_narrative_reliability` (12), `test_character_presentation` (5), `test_owner_moves` (+1). Each regression was confirmed to fail without its fix |
| Ending bots (`--bots --speed=2`) | **4 of 4 reached an ending** (asserted: any ending). Escape: 1 session. Message: 1 session. Escape at purge 3: 3 sessions. Wren run: *escape*, after Wren was lost; see the open item above |
| Windows export | Exit 0. PE32+ x86-64 GUI executable, 84.8 MB. **Not launched on Windows** |
| Linux export | Exit 0; runs 240 frames headless with no script errors |
| Exit leaks | The title screen exits with 0 leaked instances. A full test run still prints Godot's "ObjectDB instances leaked" warning once, from scenes freed mid-coroutine by the test harness |

**Not established by any of this:**
- that the game is enjoyable;
- that it runs on Windows;
- that the art is approved;
- how anything sounds.
