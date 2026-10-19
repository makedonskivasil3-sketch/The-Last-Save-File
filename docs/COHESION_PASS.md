# Cohesion pass

**Branch:** `claude/cohesion-pass`. It is based on `claude/narrative-reliability` at `8fe3f35`, which is [PR #3](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/pull/3) and still unmerged. `main` is still at `f2fcf32`.

This branch therefore carries PR #3's commits as well as its own. Merge PR #3 first, or review this branch as one piece.

**Nothing in this document is a human playtest result.** The labels:
- **reproduced**: a committed test failed before the fix and passes after it.
- **source**: established by reading the code.
- **hypothesis**: needs playtesting.
- **not testable here**: needs hardware, ears or people this environment doesn't have.

## 1. Verification of the previous pass (`8fe3f35`)

| Item | Status | Evidence |
|---|---|---|
| Manual advance is the default | VERIFIED | `test_case.before_each` resets to the defaults; `Settings.advance_mode` is 0; `test_manual_first_press_reveals_second_advances` |
| Reveal and advance need separate presses | VERIFIED | `test_one_press_never_reveals_and_advances`, `test_mashing_reads_every_line_in_turn` |
| Long text in auto mode | VERIFIED | `test_long_lines_get_the_time_they_need_on_slow`, `test_a_very_long_line_is_shown_in_pages` |
| Warnings not blocked by Slow typing | VERIFIED | `test_a_warning_is_readable_at_once_behind_slow_typing`; screenshot `review/after_warning_strip_over_slow_thought.png` |
| Death advice has reading time | VERIFIED | `test_death_advice_waits_for_the_player`. New this pass: `test_the_death_card_ignores_presses_while_paused` |
| Pause and focus loss preserve narrative state | VERIFIED | `test_pausing_freezes_reading_time_and_voice`, `test_losing_focus_pauses_and_returning_resumes` |
| Interrupted conversations recover text and audio | **BROKEN, now fixed** | Three faults, found by `test_a_scene_over_a_recorded_conversation_says_the_line_again`: (1) the voice kept playing under the scene's opening; (2) a press during the scene could close the conversation and start a new one; (3) on return the line was already fully shown, so a press carried over from the scene skipped it |
| History and replay | VERIFIED | `test_history_keeps_every_route_with_speakers`, `test_replaying_history_keeps_the_paused_story_voice` |
| NPC dialogue has voice ids | VERIFIED | `test_ordinary_dialogue_asks_for_a_voice_line` |
| Manifest independent of the save | VERIFIED | `test_the_manifest_does_not_depend_on_the_save` |
| Manifest matches the script | VERIFIED | `test_the_manifest_matches_the_story_text`; regenerated this pass (197 lines) |
| Missing recordings fall back | VERIFIED | `test_missing_recordings_fall_back_to_text`, `test_an_unrecorded_line_is_silent_and_harmless` |
| Voice files exist where delivery was claimed | VERIFIED (none claimed) | `audio/voice/` holds only the manifest. The pilot takes are local and unshipped (`VOICE_PILOT.md`) |
| Playback, ducking, interruption and replay together | PARTIAL | Covered by tests with silent clips. **Not testable here:** how it sounds |
| Mira integrated in gameplay | VERIFIED | `test_talking_to_mira_shows_her_face_and_mood`; screenshot `review/after_mira_dialogue_portrait.png` |
| Portraits match sprites | VERIFIED | `test_mira_s_portrait_is_her_sprite` (pixel colours) |
| Expressions follow context | VERIFIED | `test_mira_s_moods_cover_her_story` |
| No other character's face as a fallback | VERIFIED | `test_no_one_wears_rue_s_face` |
| Assets' commercial rights | VERIFIED for the portraits | Portraits are code-drawn in this repository. The generated pilot voice is **not cleared** (free tier) and is not shipped |
| Reading and choices follow a danger policy | **PARTIAL, now fixed** | Conversations and questions held the owner, but **scenes did not**. The guest book scene froze Rue while the owner kept hunting (`test_a_scene_holds_the_owner_like_a_conversation`) |
| Memories save coherently | VERIFIED | `test_a_memory_is_kept_in_one_write`, `test_quitting_mid_memory_keeps_the_story_coherent` |
| Existing saves stay usable | VERIFIED | `test_save_safety` (versioned, backed up, unversioned, wrong types, half-written). No save fields were added this pass |
| Persistent difficulty has survivable routes | VERIFIED (bot) | A new bot, `test_full_game_escape_purge_5`, starts one step from the purge ending and reached *escape* in one session, 2 of 2 runs |
| Earlier interaction and glitch fixes intact | VERIFIED | Full suite (see section 8) |

## 2. Creative target

**"You enter someone else's saved world. Its Owner notices and adapts."**

| Question | Answer, grounded in what the game already is |
|---|---|
| **First minute** | Trespass and quiet: a lived-in room that isn't yours, and a meter that says someone is paying attention. Curiosity first, threat second |
| **Central interaction** | Choosing *when* to break the rules. Every glitch solves a problem and costs the owner's attention, so each one is a small bet |
| **Question that keeps you going** | Who was in Slot 2, and why does this world half-recognise you? |
| **Relationship that makes it matter** | Rue and the owner: two people who played together once. Mira, Wren and Tobben are what the owner's world remembers of that |
| **What the owner does that other horror games don't** | Reads the save, not just the screen. They remember where you walked, who hid you and how you died, and they say so: in notes, in rewrites of the room, and in changed rules the next run |
| **What changes between runs** | Who is still there (deletions and restorations), what the owner says and allows (notes, sealed seams, route detours, the truce after the gentle endings), and what Rue has remembered |
| **What a player remembers a week later** | Being forgiven for one run after the RUE ending, and then breaking that by reflex |

### Pillars (used to accept or reject features)

1. **The owner is a person, not a timer.** Every adaptation is something a person at a keyboard could plausibly notice. It is said or shown, and it can be answered.
2. **Breaking rules is a choice with a price.** Glitches are bets. Costs and consequences are previewed before you commit, never revealed afterwards.
3. **Reading is safe.** No danger begins or completes while you read something you didn't choose to skip, whether a conversation, a scene, a question, the death card or the start of a run.
4. **The save remembers kindness too.** Characters recall what you did for them, and consequences persist in both directions.
5. **One clear thing at a time.** Emotionally important moments don't share the screen with countdowns.

**Rejected under these pillars:**
- a relationship meter (pillar 4 is served by recall lines);
- random owner disruptions (pillar 1);
- new glitches (pillar 2 is better served by making the existing ones legible). **Exception, by the author on 2026-10-19:** leaving a body (`DARK_TRUTH_DESIGN.md` §8), which uses the glitch hold but is not a glitch: no awareness cost, previewed, and asked first.

## 3. Player journey: the problems that mattered

The full map, with file references, came from a code audit. The rows below are what was acted on.

| Section | Problem | Label | Action |
|---|---|---|---|
| Arin's room, run 2 and later | The door is deleted and the only exit opens at awareness 40, about 20 s in. Nothing on screen says why | source | **Clarified, not removed.** Provoking the owner is the intended way out. Rue now says the door is gone and that the wall tore when they got angry, and a hairline marks the seam |
| Start of every later run | About 14 s of the owner's note and recall lines in the console, while the idle timer runs. A reader got "you stopped moving" and then a save-over | reproduced | Reading console lines that are still arriving is not standing still |
| Tips and cards | Reading a tutorial tip or a NEW GLITCH card counted as idling | reproduced | Fixed |
| Mira's room | After a "not now", every talk repeated her request. "You're not Arin. Who are you?" and the rest of her lines were unreachable | reproduced | She says two more of her own lines before asking again. Same fix for Wren |
| Every later run | Mira is RESTRICTED from purge 1, and memories only played in NORMAL, so her memories of you never played | reproduced | Characters remember whenever they are present |
| Archive | The pointer to Slot 2 was session-only: the same errand every run | reproduced | Kept in the save; a short greeting for returners |
| Guest book (square) | The scene froze Rue while the owner kept hunting | reproduced | Every scene holds the owner |
| After the RUE or message ending | The owner says "i'm not deleting anything tonight", then plays exactly as before | source | A one-run truce. Its rule is on the goal line, and three warned glitches break it |
| Wren's ending, next run | Wren is back with no memory of it | source | A recall line: she dreamt of a whole slot of her own |
| Records | The hint "Bring someone to the Edge with you" fails for Mira | source | "Bring someone who wants to see the Edge." |
| Mira's lines | "Arin walks past my window", although she lives in Arin's room | source | "Arin walks out that door every morning." |

**Deferred, logged with their evidence:**

| Item | Label | Note |
|---|---|---|
| The square's crowded first arrival: act card, objective, tip, owner line and Rue's line together | hypothesis | Playtest first |
| The last memory ("DELETE SLOT 2?") plays in the Edge's static | hypothesis | Moving it changes the map's emotional order. It needs a design decision |
| Rue's name appears before the memory that reveals it (Pip, Bin filenames, guest book) | source | Already listed in `NARRATIVE_BIBLE.md` §10.6 as an author question |
| Owner notes 6–8 are mostly reachable only through wins or a reset | source | The pacing of the owner's backstory. An author decision |
| The ending sequence is about 20 lines across three scenes | hypothesis | Playtest first |
| Glitches cost awareness in places the owner "can't see" (Archive, out of bounds) | source | A balance change. Deferred until a playtest says it confuses players |
| No way to choose between two valid glitch targets | source | Partly fixed (FREEZE now prefers Arin). A full target cycle is new UI |

## 4. Glitches: what changed

The full table of the nine glitches is in the audit notes (§9 below). Changed this pass:

- **The reload is always announced.** Glitches made before the owner noticed you could make the next glitch reload with no warning; that glitch now gives the warning instead.
- **The reload is previewed.** Once warned, the glitch prompt ends with `· RELOADS`.
- **FREEZE means Arin when Arin is in reach.** It used to pick the friend beside you, which did nothing useful.
- **The Edge countdown waits** during conversations, questions and PAUSE.

## 5. Owner adaptation table

All of this is authored, reactive behaviour: rules over recorded facts. **None of it is machine learning.**

| Player behaviour | What the owner observes | Response | Warning | Counterplay | Persistence and limits |
|---|---|---|---|---|---|
| Glitching | Count since the last load | A reload: Rue is dragged back about 10 s and glitch effects are undone | **Always** "do that again and i'm loading the autosave." first; the prompt shows `RELOADS` | Glitch less; a glitch that interrupts a save-over doesn't count | Session; 40 s cooldown |
| Standing still in the open | Idle time (not while reading anything) | A line at 6 s, a save-over ring at 8 s once suspicious | Line, ring, warning strip | Move, hide, glitch | Session |
| Where Arin saw you | Spots noted; learned on a bad end | The square patrol detours through up to 3 learned spots | "i know where you like to walk." | Different routes | Across runs (square) |
| Who hid you | Helpers noted | Wren deleted at SILENCE that run; all helpers deleted after a bad end | "and i know who helped you." | Win; restore at the Bin | Across runs |
| Which seam you used | Seam id | That seam is patched on a bad end (the last one never is) | Scar and a "seal" sound on waking | Another seam | Across runs, at most 4 |
| How you died | Cause, place, count | Note text, recall lines, ghosts and erasure at death spots; a mercy at the Edge | Death card, notes | The tip names the counter-glitch | Across runs |
| **How the last run ended (new)** | `last_ending` after a win | **Truce** after RUE or message: watching only, for one run | Owner's return lines, plus `TRUCE` on the goal line | Don't glitch, or accept that it breaks after 3 warned glitches | The next run only |

**Never treated as a mistake:**
- slow reading: of conversations, scenes, questions, tips, cards, console lines being delivered, and the death card;
- menus and pause;
- focus loss (with the setting on);
- accessibility settings.

**Still open:**
- quitting counts as a purge, by design: "quitting counts" is an early tip;
- with *Pause when unfocused* turned off, alt-tab leaves the owner running. That is the player's choice, and the setting says so.

## 6. Characters

| Character | Desire | Fear | Relationship to Rue | This pass |
|---|---|---|---|---|
| Mira | to leave her room and be remembered | being reset | the first to notice Rue isn't Arin | All her lines are reachable; she remembers you whenever present |
| Wren | to see the Edge before she's deleted | being "cut content" | hides Rue; can receive Slot 2 | Lines reachable after a "not now"; remembers her own ending |
| Tobben | to remember the second name | his own script | can write Rue back into his book | Reports you after the conversation, not during it; the guest book scene is safe |
| The Archivist | to be visited; to keep records | — | the only one who remembers Rue kindly | Greets returners; no repeated errand |
| Pip | Rue (an old companion) | — | the guide | Unchanged (deferred: a portrait) |
| Arin | — (the owner's avatar) | — | the body that should have been Rue's | Unchanged |
| The owner | to stop feeling Slot 2's absence | being seen | the other player | Keeps their word after the gentle endings |

## 7. Art, audio, performance, accessibility

- **Art:** Rue and Mira have portraits. The second supporting portrait is deferred to the next pass: Wren is the strongest candidate, since she appears in conversations, hiding and an ending.
- **Audio:** nothing could be heard here. The state map is in `AUDIO_DIRECTION.md`. Interruption, replay and ducking are covered by tests with silent clips. **Not testable here:** levels, intelligibility, emotional fit.
- **Performance:** see `RELEASE_READINESS.md` for this pass's measured numbers.
- **Input:** the new prompts use the `Settings.glyph()` names. Tests drive real key events for reading-freeze, mashing and retry. **Not testable here:** physical controllers.

## 8. Validation

See `RELEASE_READINESS.md` (updated this pass) for exact test counts, bots, exports and the build hash.

## 9. Audit notes

The glitch table, the adaptation inventory, and the journey and character audit behind sections 3–6 are reproduced in the PR description.
