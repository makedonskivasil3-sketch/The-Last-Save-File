# Audit: story pacing, characters, voices, first minutes

**Date:** 2026-10-18.

**Base:** `playtest/first-minutes-fairness` (`6eafb64`, which already contains `game-presentation-polish` `2c0936f`), plus:
- `claude/last-save-file-prototype-ljwuq4` (`c1ebba6`: lighting, journal, voice loader);
- `codex/player-experience` (`99fbdc6`: console history, compact pause grid).

All three were merged into the working branch `claude/story-pacing-cast-pass`, so none of that work is lost or rebuilt twice. **Nothing here comes from a human playtest.**

**Verified by reading code or tests** is marked **[V]**. **An assumption to confirm with players** is marked **[A]**.

## What already exists (confirmed on the branches)

| Feature | Where | State |
|---|---|---|
| Optional system speech (OS text-to-speech, *not* recorded acting) | `scripts/audio/narration.gd` | Off by default; pauses with the game |
| Text speed: Slow / Normal / Fast / Instant | `Settings.text_speed` | Applies to the dialogue box, console and cinematic typing |
| Contextual tutorials that hide behind banners and choices | `scripts/world/tutorial.gd` | Working |
| PHASE preferred when facing a thin wall; cursor ring on Rue; owner lines styled | first-minutes branch | Working |
| Adaptive music that ducks under dialogue and owner banners | `scripts/fx/ambience.gd` | Working |
| Console history (last 200 lines) | codex branch, pause menu | Text only, no speaker labels, no replay |
| Artefact journal; recorded-voice loader (no lines recorded) | prototype branch | Working; the memory cinematic only |

## Highest-impact problems

| # | Severity | Problem | Evidence | Fix in this pass |
|---|---|---|---|---|
| 1 | **Blocker** | **Every cinematic advances on its own.** Each line leaves after `2.4 s + 0.045 s × characters`, read or not. This covers the boot, all five memories, the planted memory, Mira's pinning, the guest book, the Slot 2 recap, the final exchange and the epilogue. | [V] `hud.gd` `_cinematic_line`: `var wait := 2.4 + line.length() * 0.045`. A 60-character line gets 5.1 s, including time the player spends looking away | Manual advance by default. One shared pacing rule; auto mode as an option |
| 2 | **Blocker** | **Console story lines leave too soon.** Owner threats, Rue's thoughts and recall lines type at 36 characters/s, wait **0.5 s**, then the next one starts. Only 4 lines are kept (3 with large text). On arrival in an area, 3–4 lines arrive back to back and push each other out. | [V] `LINE_PAUSE := 0.5`, `MAX_LINES := 4`. Screenshot `13_house` shows 4 lines stacked within ~6 s of arriving | A reading allowance per line, compressed only under a backlog. Long lines wrap; history keeps everything |
| 3 | **High** | **The console keeps typing behind dialogue and cinematics.** Lines queued during a conversation are typed into a hidden box and can scroll out before it reappears. | [V] `_update_typing` has no dialogue/cinematic check, while `show_dialogue` hides `_console_box` | Hold the queue while a modal or the dialogue box is up |
| 4 | **High** | **Long console lines are cut off with "…"** | [V] `OVERRUN_TRIM_ELLIPSIS` | Wrap the text |
| 5 | **High** | **Losing window focus doesn't pause.** Text, timers and the owner keep running behind an alt-tab. | [V] no `NOTIFICATION_APPLICATION_FOCUS_OUT` handler anywhere | Pause on focus loss (a setting, on by default) |
| 6 | **High** | **No dialogue history with speakers.** The codex history is plain console text; dialogue-box and cinematic lines aren't in it. | [V] `console_history` is only appended in `_update_typing` | One history for every route, with speaker, kind and replay where a recording exists |
| 7 | Medium | **No way to skip a whole sequence** (only line by line). Not a blocker, but a repeat player re-reads the boot and memories. | [V] | Hold to skip, with an on-screen meter; the consequences still apply |
| 8 | Medium | **A memory reaches the journal before it counts as found.** Quitting mid-memory leaves the journal and Records disagreeing. | [V] `world.gd` records before `hud.cinematic` | Record after the scene completes, with the fragment |
| 9 | Medium | **The desk lamp in Arin's room lights nothing.** It sits inside the table, which casts shadows. | [V] TABLE `Rect2(116,216,36,22)`, light at `(134,221)`; screenshot `40_purged_quiet` | Move it above the table |
| 10 | Medium | **Journal text can't be scrolled with keys or gamepad** | [V] `ScrollContainer.focus_mode == 0` in Godot 4.3 | Make it focusable |
| 11 | Medium | **Arin's view cone is darkened by the new lighting.** It is drawn at 6% alpha, and the scene ambient multiplies it. | [V] in the square (screenshot `20b`). [A] in the house (ambient 0.42) | Compensate for the ambient so it reads as before |
| 12 | Medium | **Character readability:** characters are 8×N templates at 2×, with no portraits anywhere. Expressions exist only as single-pixel eye states. | [V] `pixel_character.gd`, the template rows | Art direction + Rue's portrait set (below) |
| 13 | Info | **Tutorial tips close after 8 s**, regardless of length. | [V] `MAX_TIME := 8.0` | Use the reading allowance (at least 8 s) |

## External tools and access actually needed

- **Voices:** a paid ElevenLabs plan (or a human actor). On 2026-10-17 the connected ElevenLabs account refused generation: 55 credits left, and free-tier access disabled. **Nothing in this pass depends on it.** Missing lines fall back to text.
- **Character art:** nothing is needed to ship this milestone. Rue's portraits are drawn in-house as pixel art from the same palette as her sprite, and documented as replaceable. An image-generation service and Aseprite or Krita are recommended in `docs/ASSET_PRODUCTION.md`.

## Priorities

1. **Story pacing** (problems 1–8): shared rules, settings, history, tests.
2. **Rue as the representative character:** art direction, portraits with expressions, presentation in cinematics, in-world consistency.
3. **Voices:** voice bible, manifest with stable IDs, a format spec, and timing driven by the recording.
4. **First-minutes fixes** (problems 9–11), checked again in the opening.
5. **Validation:** full suite, a bot playthrough to an ending, screenshots, Windows export, PR.
