# Release readiness

**This section is the single authoritative statement of the project's current status.** Other docs (audits, pass notes) are history; where they disagree, this wins.

## Current: review milestone after the vertical slice (2026-10-22)

**Branch:** `claude/last-save-file-prototype-ljwuq4`.
- PR #10 is a **draft, not merged**. `main` is at `09aeb3b`.
- Runtime code changed after `537df8c`: the vertical slice, then the
  22 October review fixes. The previous "documents only" note below is
  history, not the current state.

**Canon:** still **proposed**, and needs the author's decision
(`docs/CANON_DECISIONS.md`). Nothing on this branch is approved canon.

**Last fully green CI:** run 129 (`7710f10`),
https://github.com/makedonskivasil3-sketch/The-Last-Save-File/actions/runs/39749038209
- It covered the strict suite, five ending bots, Web, Windows and Linux
  exports, browser audio and lifecycle checks, and the Linux smoke test.
- Earlier CI runs on this branch failed and are kept on record in
  `docs/VERTICAL_SLICE.md` §7:
  - runs 121 and 123–125: a bot harness that didn't know the wider Square;
  - run 127: a real purge-5 balance regression from the lamp, since
    retuned;
  - run 128: a flaky test.

**This milestone:**
- The review findings and their fixes are in `docs/REVIEW_OCT22.md`.
- This section is updated with the final head, CI run and test counts
  when the milestone closes.

**Not verified:**
- Windows execution (an export is not a playtest)
- an iPhone
- a real GPU or gamepad
- human listening
- uncoached players

None of these is claimed.

## Previous: coherence milestone, review branch (2026-10-21)

Branch: `claude/last-save-file-prototype-ljwuq4` (PR #10, draft, **not
merged**). `main` = `09aeb3b`. The code head is `537df8c`; later commits
are documents only. The evidence and the remaining work are in
`docs/COHERENCE_MILESTONE.md`. The contract is
`docs/NARRATIVE_CONTRACT.md`, **proposed** (revision 2, §0).

**Behaviour changes, each documented and tested:**
- **Save v3, migrated from v2.** Ordered, counted relationship events.
  Learned facts. Archive marks by revision.
- **One selection path for conversations.** Mira and Tobben react to
  what happened between you. A consequence is said once, when it's read
  whole; it waits for the next meeting, however many runs later.
- **The archive** says only what Rue saw, was told, thinks, or doesn't
  know. It gives each object one status, marks updated entries, and keeps
  the reader's place.
- **The map** keeps every place found across runs.
- **The kept place** under the well is offered earlier (after the well's
  tune), and Rue chooses it. Answering the well no longer sets it.
  Quit and crash rules are unchanged.
- **The well's evidence** is honest: a recording, not live contact.
- **The opening's last shot** matches canon.
- **The browser check** measures startup and bounds it by game time.

**Verification on `537df8c`:**

| Check | Result |
|---|---|
| Strict full suite (one complete monolithic run) | **547/547**, 1238.3 s, exit 0; 547 unique cases across all 81 test files |
| Ending bots `--speed=3` | **5/5** exact endings. Two Edge deaths with retries (escape at purge 0 and at purge 3); 14 recovered bot stalls in total |
| Exports | Web, Windows Desktop, Linux: exit 0. SHA-256 prefixes: exe `a502defdd9b4`, linux `4636f527b6af`, pck `fc6243607296`, wasm `fe5cebc59075` |
| Linux binary | 300 frames under xvfb, exit 0 (no audio device in the container) |
| `web_check.cjs` | All passed. Playable after 6.0 s of game time (55.3 s wall on SwiftShader) |
| `audio_output_check.cjs` | Audible after a gesture, "running", **no visible badge** |
| Shutdown | ObjectDB warning still printed at the full suite's exit (A14). Owners identified; not filtered |

**Not verified:**
- Windows execution
- an iPhone
- a real GPU, a phone or a gamepad
- human listening
- uncoached players

None of these is claimed.

## Previous: continuity milestone, review branch (2026-10-21)

Branch: `claude/last-save-file-prototype-ljwuq4`, not merged. `main` (now
`09aeb3b`, with PR #9) was merged into it. Where PR #9 and this branch
built the same thing, PR #9's version was kept: the portrait resources,
caption paging and the speech-rate setting. The numbers below were
measured before that merge; see "After merging main" for the re-run.
It carries two milestones:
- **Live-art milestone** (`cc76537`…`a38049f`): portrait art route, caption
  pages, character states, console pacing, timed glitches, speech rate.
- **Continuity milestone** (`8256c29`…`3fea14f`). Contract:
  `docs/NARRATIVE_CONTRACT.md` (**proposed**). Evidence:
  `docs/CONTINUITY_MILESTONE.md`.

**New canon (proposed, needs the author's approval):** Rue is the part of
the second player that stayed in an interrupted save.

**Behaviour changes, each documented and tested:**
- Lasting encounters, conversations and relationship events (save v2,
  migrated from v1). Wren's reunions react to what she saw.
- A six-section archive.
- One checkpoint: after a death you wake under the well once the well has
  your answer. Quit and crash still start in the room; purge rules are
  unchanged.
- The well's five-step sequence.
- A 45 s opening animatic.
- The visible iPhone sound badge is removed. Audio recovery is kept.

**Verification on this branch:**

| Check | Result |
|---|---|
| Strict full suite, live-art head `a38049f` | 496/496 (1165.8 s, exit 0) |
| Strict full suite, continuity code `dc372e9` | **517/517** (1211.1 s, exit 0) |
| After `dc372e9` | One code change, the history ordering in `3fea14f`; its suites (continuity, archive) pass 13/13. The full suite was not re-run after it. |
| Ending bots, `--speed=3` | 5/5 exact endings: escape, message, escape at purge 3, escape at purge 5, Wren. One Edge death with retry; one recovered stall on the Wren route. |
| Exports at `3fea14f` | Web, Windows Desktop, Linux: exit 0. SHA-256: exe `7539e4e5…`, linux `64807693…`, web pck `fccc6a68…`, wasm `fe5cebc5…` |
| Linux binary run | 300 frames under xvfb, exit 0. No script errors; only the container's missing audio device is reported. |
| Headless Chromium `web_check.cjs` | All passed: title, opening, skip, playable, keyboard, save, leave guard, quit counted, no page errors |
| Headless Chromium `audio_output_check.cjs` | Audible after a gesture; `soundState` "running"; **no visible badge**; no clipping |
| Captures | `docs/review/continuity/` (opening before and after, the slice, the archive) |
| **After merging main** (`d527151`, with PR #9) | Strict full suite **523/523** (1215.2 s, exit 0), including PR #9's own tests. Ending bots 5/5: the escape at purge 3 took 4 sessions and 3 deaths this run; the other routes had no deaths. Web, Windows and Linux exports exit 0. Both headless-Chromium checks pass, with no visible badge. |
| PR CI | Passed on `d527151` (run 109, with downloadable Windows, Linux and Web artifacts). On `1b6f053` (a docs-only change) the export job first failed `web_check`'s "run becomes playable" step: the boot scene was still open at the 90 s limit on the slow software-rendered runner. One re-run passed. It failed the same way again on `d27d106` (also docs-only), so it was treated as real. Cause: the check's 90 s budget, not the game. At 12× CPU throttling, `main` and this branch both reach a playable run at 54.6 s, and the same code has passed and failed on CI. The budget is now 240 s (`tests/web/web_check.cjs`); the check passes locally both throttled and unthrottled. |

**Not verified:**
- Windows execution
- a real iPhone
- real GPU, phone or gamepad
- human listening
- uncoached players

The questions for players are in `CONTINUITY_MILESTONE.md`. No player
results exist, and none are claimed.

**A playable build is available through:**
- the private web artifact (owner's link);
- the PR's CI run, which uploads a Windows zip (`.github/workflows/build.yml`)
  once it completes.

A running CI job is not a finished build.

## Prompt implementation on main, PR #9 (2026-10-21)

Runtime `eec7e576` preserves combined main `1e371b1` and implements the supplied
prompts' first presentation milestone: live approved portrait resources with
palette-safe fallback, continuous recording playback across readable caption
pages, coherent world/portrait speaking and gaze, and an independent system-
speech rate preference. No new production artwork or recorded cast is claimed.

See [PROMPT_IMPLEMENTATION.md](PROMPT_IMPLEMENTATION.md) for implementation,
evidence and remaining scope, [CAPTION_VOICE_CONTRACT.md](CAPTION_VOICE_CONTRACT.md)
for route semantics, and [PORTRAIT_ASSETS.md](PORTRAIT_ASSETS.md) for the asset
contract. All **482 unique cases across 71 files** passed in isolated coverage,
including a correctly uncapped **6/6 CPU-budget rerun** after a verifier-cap
failure. This is not a completed monolithic local run. Focused actual-HUD
compatibility: **18/18**; exact-ending bots **5/5**; staged rendered checks **2/2**.
The message bot required one death/retry and 17 recovered navigation stalls;
other acceptance routes reported zero deaths/stalls. CI/export/browser status
is tracked separately in PR #9, not inferred from older builds.

The first-room/Square and wider map milestones remain open, as do authored
assets, human listening/playtests, Windows execution, real GPU/device/input
checks and shutdown diagnostics. The game remains a late prototype.

## Previous combined presentation/functionality revision (2026-10-21)

The combined branch retains main `2644629` / PR #8 (`2ffc036`): finale cursor
ownership, reading-held confrontation transitions, completed-objective clearing,
gaze hysteresis/turns and reduced-flashing brackets. It adds `e69ab5c` live
portrait clocks/system-speech mouth activity and `9117b18` cancellation of a
navigation refresh when its area leaves the tree. Test-only `3ee11fc` makes
failed screenshot saves fail visual checks. Save and balance rules are intact.

See [PRESENTATION_FUNCTIONALITY_AUDIT.md](PRESENTATION_FUNCTIONALITY_AUDIT.md)
for the combined results, evidence and remaining issues;
[PRESENTATION_GAMEPLAY_FOLLOWUP_PROMPT.md](PRESENTATION_GAMEPLAY_FOLLOWUP_PROMPT.md)
is the updated detailed assignment, incorporating the incoming revision.
Its future work is not presented as completed. Earlier verification below
belongs to its own source hash, not automatically to the combined runtime.
Combined runtime `1c21266` completed **471/471 headless tests** (1063.9 s,
exit 0), five exact-ending bots and Web/Windows/Linux exports. Current browser
lifecycle/audio and three rendered checks passed. Bots recorded four recovered
escape-route stalls and one message-route death/retry; ObjectDB/resource
shutdown warnings remain. Full logs and build checksums are in the audit.
The final evidence commit changes no gameplay code; remote CI is tracked
separately after publication.
The game remains a late prototype: human listening/playtesting, Windows
execution and real-GPU/device checks remain outstanding.

## Historical PR #8 code and experience revision (2026-10-21)

Runtime `2ffc036` completed 468 headless tests, 40 focused tests and five
exact-ending bots in its recorded environment. Purge-3 bots recorded two
recovered stalls. Its evidence remains in [REVISION_OCT21.md](REVISION_OCT21.md),
with its original next brief in [NEXT_GAMEPLAY_VISUAL_PROMPT.md](NEXT_GAMEPLAY_VISUAL_PROMPT.md).
Those earlier results do not substitute for the final combined check.

## Historical integration follow-up (2026-10-21)

The local opening/cast changes and every fetched remote branch have been
integrated on `codex/integration-follow-up`. Runtime source is `2b3e70d`.
See [INTEGRATION_FOLLOWUP_RESULTS.md](INTEGRATION_FOLLOWUP_RESULTS.md) for the
current results and limitations, and [INTEGRATION_FOLLOWUP_PROMPT.md](INTEGRATION_FOLLOWUP_PROMPT.md)
for the detailed prompt written before the new repairs and then executed.
Historical “not pushed/merged” statements below describe their original pass.
Publication status is recorded in the integration report after verification.
The game remains a late prototype pending human and hardware validation.

## Historical local follow-up: opening and cast review (2026-10-20)

Local branch `codex/opening-cast-review`, based on fetched PR #7 head
`decaf1f7`. Runtime changes: `7a5142a` and `afb44e7`. Nothing from this follow-up
has been pushed, merged or deployed. The advertised unpublished `a918b79`
work was not available; `codex/map-experience` on GitHub contains the earlier
pass-8 code, not that patch.

See [OPENING_CAST_REVIEW.md](OPENING_CAST_REVIEW.md) for the findings ledger,
preserved/missing features, scope, and uncoached playtest plan, and
[OPENING_CAST_RESULTS.md](OPENING_CAST_RESULTS.md) for current verification.
The pass-8 results below remain historical, not evidence for the new code.
Stage remains a late prototype: human playtesting, listened-to audio,
Windows execution and real hardware measurements are still pending.

## Historical status (2026-10-20, pass 8): `claude/last-save-file-prototype-ljwuq4`

**Stage:** a complete vertical slice / late prototype. **Not** a release candidate. Unmet: a human playtest (none run), listening (none), a real-GPU measurement (none), Windows, phone and gamepad runs (none), recorded voices (none ship). Not merged, nothing deployed by this pass.

**Pass 8: consistent rules, a navigation lifecycle, a deliberate finale, faster retries, a visible art pass.** Details and evidence are in `GAMEPLAY_CONSISTENCY.md` (pass 8) and `VISUAL_DIRECTION.md` (pass 8); captures are in `docs/review/pass8/`.

| Area | Implemented | Automated | Visually inspected | Human / hardware |
|---|---|---|---|---|
| One protection rule: act and NEW GLITCH cards hold the owner everywhere, small text never does; no banked click | Yes | `test_pass8` (4) | — | Pending |
| Navigation lifecycle: grid versions, partial refresh after physics, doors/wall/crates notify, walkers replan, watch ends on a new way | Yes | `test_pass8` (4) | — | — |
| Recovery by depenetration (never deepens, never crosses); body-safe path ends | Yes | `test_pass8` (3), `test_threat_navigation` | — | — |
| Finale: Slot 2 finished before the grab is a deliberate, clean outcome | Yes | `test_pass8` (2), `test_confrontation` | Edge phases sheet | Pending |
| Retry after an Edge death: the seam is already open | Yes | `test_pass8` (2), `tour_retry` (40.5 → 14.0 s at purge 1) | — | Pending |
| Edge grey-box geometry, compact banner, softer text, wall faces, motion weight | Yes | Existing suites | `before_after.jpg`, `edge_phases.jpg` | Pending |
| Title in every state; reflow then focus-following scroll | Yes | `test_the_title_menu_fits…` | `title_states.jpg` | Pending |
| Balance as a system: a closet at purge 4 against every threat; a purge-5 ending bot | Yes | `test_pass8`, `test_full_game_escape_purge_5` | — | Pending |

| Commit | Check | Result |
|---|---|---|
| `306a53f` | Full suite (local) | 453 passed, 0 failed |
| `306a53f` | Bots, speed 3 (escape, message, escape purge 3, escape purge 5, Wren) | 5/5 reached their exact ending |
| `306a53f` | `web_check` ×3 | 2 of 3 passed; 1 missed the browser's beforeunload dialog (the check then waited a fixed 1.5 s) |
| `aa45cf2` | `web_check` ×2 (now: guard armed, bounded wait for the dialog) | 2/2 all pass (and 4/4 on the same check before the final commit) |
| `aa45cf2` | `audio_output_check` | Audible |
| `aa45cf2` | Full suite (local) | 453 passed, 0 failed |
| CI | PR #7 | Earlier commits in this pass failed CI: the card hold changed timing in 13 tests (fixed in `84bdd15` and `306a53f`), and the browser check pressed E into the world (`48ffbd4`). See the PR for the run on the head commit |

**Save compatibility:** no save fields were added or changed. `slot2_beaten` is a run-only flag. Settings are unchanged.

## Status at pass 7 (2026-10-20)

**Stage:** a complete, polished **vertical slice / late prototype**. Every planned area, threat, ending and system is in and covered by automated checks. Nothing a real player experienced has been observed yet. **Not** a release candidate (same unmet items as below).

**Pass 7** (three read-only reviews, then fixes; details in `GAMEPLAY_CONSISTENCY.md`, pass 7):

| Area | Implemented | Automated | Visually inspected | Human / hardware |
|---|---|---|---|---|
| Title key art and asymmetric layout (`TitleArt`, `UiStyle.side_panel`) | Yes | Title/menu suites | `tour_visual` 00/01 | First-impression opinion pending |
| Fairness: hidden stops save-over; square cursor capped and spawned away; purge rate capped at 3; no static under Rue on arrival; room exempt from truce slowdown; seam hint; truthful death tips | Yes | `test_pass7` (5), full suite | — | Pending |
| Story: truth-aware end cards and apology; Archivist's stake; reveal no longer contradicts memories 4–5; pronoun fixes; canon header | Yes | `test_pass7`, `test_canon`, `test_voice_manifest` | — | Reading pending |
| Open for the author: Edge retry distance (checkpoint proposal); quit/purge on phones; the escape card's "doesn't know this slot survived" | — | — | — | Author's call |

| Commit | Check | Result |
|---|---|---|
| `ba3fcdd` | Full suite (local and CI) | 435 passed, 1 failed (`test_canon`: an author-decided line I had changed; restored in `12077ed`) |
| `12077ed` | `test_canon`, `test_pass7`, `test_voice_manifest`; bots (4 exact endings) | 12/12; 4/4 |
| `12077ed` | `web_check` (headless Chromium), `audio_output_check` | Lifecycle: 2 of 3 runs all-pass; one run missed the beforeunload dialog (intermittent, watch in CI). Audio: audible |

## Status at pass 6 (2026-10-20)

**Branches:** [PR #7](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/pull/7) on this branch, stacked on [PR #6](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/pull/6). Not merged; nothing deployed. The author asked for both to be merged into `main` and for GitHub Pages; the merge needs to be done on github.com (this session may not merge), and Pages needs *Settings → Pages → Source: GitHub Actions*.

**Release candidate?** No. Unmet: human playtest (none run), listening (none), real-GPU measurement (none), Windows/phone/gamepad runs (none), recorded voice (none ships).

### What changed since pass 4 (passes 5–6)

| Area | Implemented | Automated | Visually inspected | Human / hardware |
|---|---|---|---|---|
| Arin's navigation (grid paths, clearance, recovery, unreachable targets) | Yes | `test_threat_navigation` (9) | — | Pending |
| Edge: valid guard routes, safe arrival, state-tied goals, frozen writing behind text, readable floor | Yes | `test_edge_confrontation`, `test_edge`, `test_confrontation` | `docs/review/pass6/edge_confrontation_sheet.jpg` | Pending |
| Closets as open recesses, cue, status, 4 s chime | Yes | `test_house` | Pass 5 screenshots | Discoverability pending |
| Archive record stands, file emphasis at FILE stage | Yes | `test_gameplay_consistency` | Pass 5 | Discoverability pending |
| Opening film (unnamed P2, skip/replay/captions, focus and input hand-off) | Yes | `test_opening` (9) | `docs/review/pass6/opening_storyboard.jpg` | Comprehension pending (intro on/off variants ready) |
| Phone audio recovery after spoken lines; music under the opening | Yes | `audio_output_check` (headless Chromium: audible) | — | **Listening on an iPhone: pending** |
| Strict browser lifecycle in CI | Yes | `web_check` locally: all pass | — | — |
| Benchmark harness | Yes | Smoke run, 9 workloads valid | — | **Real GPU: pending** (`tools/run_benchmark.sh`) |

### Verification tied to commits

| Commit | Check | Result |
|---|---|---|
| `c7293fe` | Full suite (local) | 425 passed, 0 failed |
| `ade8215` | CI (GitHub) | Passed |
| later commits | Full suite, bots, CI | See the PR; results are not carried forward from earlier commits |

### Measuring on a real GPU

`GODOT=/path/to/Godot_v4.3-stable tools/run_benchmark.sh` on the machine to measure (windowed, nothing heavy running). It needs the Godot 4.3 editor binary and this repository (the harness lives with the tests, which exports leave out). Output: `benchmark-<commit>.json` plus a console table. Each of gameplay (room, square calm, square hunted with Wren, Archive with a portrait on screen, house visit, Edge spreading), stress (CRT and full effects while hunted), transitions and the opening is checked throughout capture; anything that stops being what its label says is listed under `invalid`, never averaged in. Software renderers (llvmpipe, SwiftShader…) are flagged as not a hardware GPU. GPU time is **not** measured separately (frame time is wall clock; CPU time is Godot's process monitor). Development-only change: `World.bench_immune` keeps Rue alive; threats run as in play.

---

## Status at pass 4 (2026-10-20): `claude/last-save-file-prototype-ljwuq4` (pass 4)

**Branches:** this branch carries [PR #7](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/pull/7) (stacked on [PR #6](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/pull/6)). Nothing is merged or deployed. `main` is unchanged.

**Environment:** Linux container, Godot 4.3, Mesa llvmpipe (no GPU), headless Chromium. No Windows, phones, gamepads or speakers.

### Is this a release candidate?

**No.** No critical functional failure is known. Unmet gates:
- **Human playtest:** none has run. A five-player round is ready (`PLAYTEST_PLAN.md`, "pass 4"); results pending.
- **Listening:** no one has listened to the mix. The browser check proves audio *output*, not that it sounds good.
- **Voice:** no recorded performances ship. Spoken lines use the device's system speech or the procedural voice; the generated pilot (`narration_review/`, untracked) is unlicensed and now excluded from every export preset.
- **Real hardware:** no Windows launch, no real-GPU frame times, no physical controllers or phones.

### What the game is now

| Area | State | Evidence |
|---|---|---|
| Characters | Illustrated vector figures and matching portrait busts for the whole cast, Pip and the shed body included | Visual inspection of tour screenshots |
| Places | Shared `Decor` kit, baked backdrops; Archive floor redone as flagstones in pass 4; system spaces keep their deliberate look | Visual inspection; per-area review in `VISUAL_DIRECTION.md` |
| Type | Inter (OFL) for world and UI, DejaVu Sans Mono for the owner's system text; licences in Credits and in exports | `test_fonts`, `test_polish` |
| Screen | Clean by default; CRT optional; corruption tied to awareness and events; UI above effects | Screenshots; earlier tests |
| Threats | Line of sight blocked by solids; cone drawn from the same rays | `test_threat_fairness` |
| Onboarding | One lesson at a time; awareness before glitches; tap vs hold explicit; tips persist until read; tips yield to danger, the act card and the prompt | `test_onboarding`, `test_first_minutes` |
| Recovery | Pause says it's safe; quit says what it costs, keeps and loses; death card says what carries over and the purge count; How to Play in-run | `test_onboarding`, `test_menus` |
| Scenes and sound state | Scenes hold the owner; stop cleanly if the run ends; muffles tracked per source; reset per run | `test_moment_safety` |

### Verification (this pass)

| Check | Result |
|---|---|
| Full suite | **405 passed, 0 failed** (923 s) |
| Ending bots | **4 of 4 reached their exact endings**: escape, message, escape at purge 3, wren |
| Web export | Built; pck 2.9 MB; contains the font licences, no review audio |
| Browser checks (headless Chromium) | `audio_output_check`: audible after a gesture, no clipping, no page errors. `web_check`: closing mid-run asks first and counts as a quit |
| Visual inspection | Developer screenshots at 1280×720: title, room, square, archive, bin, house, out of bounds, Edge, tips, prompt, pause, quit, help, death card, Large text. Not inspected by anyone else |
| Listening | **Not run** |
| Human playtest | **Not run** |

### Performance (llvmpipe software rendering, 1280×720, `tests/tour_profile.gd`)

| Scene | p50 | p95 | Earlier p50 (2026-10-19, before the illustrated pass) |
|---|---|---|---|
| Room, session start | 61.5 ms | 96.5 ms | 64.1 ms |
| Square, calm, effects full | 59.9 ms | 65.6 ms | 58.6 ms |
| Square, calm, effects off | 38.2 ms | 43.1 ms | 32.9 ms |
| Square, HUNT + Wren escort | 63.9 ms | 73.7 ms | 57.2 ms |
| Edge, static spreading | 47.6 ms | 57.6 ms | 44.4 ms |
| Archive after 8 area changes | 49.1 ms | 55.3 ms | 42.3 ms |

- These numbers measure a CPU rasteriser, not a player's GPU; they show relative cost only.
- The illustrated cast and new areas cost about 5–7 ms here. Arin's line-of-sight cone costs 0.03 ms per frame (measured: 2.4 µs per ray, 14 rays).
- Node and object counts stay flat across area changes (no growth during play).
- No optimisation was made without real-device evidence. Candidates if a device shows a problem: sun shadows off on Light effects; baking figure outlines.

### Save compatibility

No saved field was added, renamed or removed in passes 3–4. Settings gain nothing new; `tips_seen` keeps its meaning (tips now enter it when read rather than when shown, so an older save simply has them marked already).

---

## Previous status (2026-10-19): `claude/cohesion-pass`

**Branches and commits:**
- `claude/cohesion-pass` is based on `claude/narrative-reliability` (`8fe3f35`, [PR #3](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/pull/3)), which is unmerged.
- `main` is still at `f2fcf32`.
- Code at `56ec8bb` (later commits on this branch are documentation only).

**Environment:** Linux container, Godot 4.3. No real GPU (Mesa llvmpipe), no Windows, no phones, no gamepads, no speakers.

### Is this a release candidate?

**Not yet.** No critical functional failure is known. These gates are still unmet:
- **Windows:** the build is exported but has never been launched on Windows.
- **Human playtest:** none has run. See the plan in `PLAYTEST_PLAN.md`.
- **Audio by ear:** nothing has been listened to.
- **Voice:** nothing ships. The generated pilot is not licensed for release (`VOICE_PILOT.md`).

### Builds

| Target | Result |
|---|---|
| Windows | Exported locally (exit 0), 84.8 MB PE32+. CI builds it as the `TheLastSaveFile-windows` artifact. **Not launched on Windows** |
| Linux | Exported (exit 0), 66.6 MB. Runs 240 frames headless with no script errors and no leak warning |
| Web | Built by CI (`TheLastSaveFile-web`). The browser check (`tests/web/web_check.cjs`) was **not re-run this pass** |

### Automated tests (this pass)

| Suite | Result |
|---|---|
| Full suite | **325 passed, 0 failed** at `8f287a7` (768 s). The suite is re-run on the final code before the PR; see the PR description |
| Character tests after Wren | 7 passed, 0 failed |
| Ending bots | **4 of 4 committed bots reached an ending:** escape (1 session), message (1), escape at purge 3 (2), wren (2, the Wren ending). An extra purge-5 bot escaped in one session in 2 of 3 runs. In the third it died once, which at purge 5 is the purge ending by design. It was not kept as a committed check |

New regression files:
- `test_verification_probes` (4)
- `test_cohesion_fairness` (5)
- `test_cohesion_story` (7)
- `test_character_presentation` (+2)

Each new fix's test was confirmed to fail without it.

### Performance (`tests/tour_profile.gd`, rendered through xvfb on llvmpipe at 1280×720)

**Software rendering:** these numbers measure this container's CPU rasteriser, not a player's GPU.

| Scene | p50 | p95 | max | Nodes | Objects |
|---|---|---|---|---|---|
| Room, session start | 64.1 ms | 101.8 ms | 129.8 ms | 269 | 2129 |
| Square, calm (effects full) | 58.6 ms | 70.6 ms | 112.8 ms | 286 | 2170 |
| Square, calm (effects off) | 32.9 ms | 38.9 ms | 42.0 ms | 287 | 2170 |
| Square, HUNT + Wren escort | 57.2 ms | 62.7 ms | 66.5 ms | 291 | 2235 |
| Edge, static spreading | 44.4 ms | 53.5 ms | 59.1 ms | 278 | 2224 |
| Out of bounds | 43.3 ms | 50.3 ms | 52.2 ms | 255 | 2188 |
| Archive after 8 area changes | 42.3 ms | 51.8 ms | 54.8 ms | 284 | 2242 |

**What this does and doesn't show:**
- **Screen effects** (CRT, lighting, shadows) are about 40% of software render time. *Settings → Screen effects* already lets low-end machines turn them off.
- **Node and object counts stay flat** across area changes, so there is no growth during play.
- **Game logic is cheap:** headless CPU time per frame stays within its budget (`test_performance`, the fully hunted square).
- **Not optimised this pass:** without real-device numbers there was no evidence to justify removing lighting or effects.

### Exit warnings

| Case | Status |
|---|---|
| Title screen | **0 leaked instances.** `Sfx` stops every audio player as it leaves the tree |
| The test harness | Still prints Godot's "ObjectDB instances leaked" once, from scenes freed mid-coroutine. **A harmless shutdown artefact**, not growth during play (see above) |

### Not verified

- Windows launch.
- Audio levels and intelligibility.
- Physical controllers.
- Phones and touch devices.
- Real-GPU frame times.
- Any human play.

---

## Historical status (2026-10-16, experience-polish milestone)


**Status on 2026-10-16:** the end of the experience-polish milestone, branch `claude/last-save-file-prototype-ljwuq4`. Everything below was run in a Linux container (Godot 4.3, headless, plus xvfb for screenshots). There was no real GPU, phone or gamepad.

## Builds

| Target | Result | How |
|---|---|---|
| Web (HTML5) | **Exported (exit 0)**: index.html, .js, .wasm (35 MB), .pck (0.4 MB). In headless Chromium (SwiftShader) it **loads and reaches the engine boot screen**; the title screen was **not confirmed** within the headless time budget | `godot --export-release "Web"`; `chrome --headless --screenshot` |
| Linux | **Exported (exit 0), 66 MB.** Ran about 240 frames headless with no script errors | `--export-release "Linux"`; `--headless --quit-after 240` |
| Windows | **Exported (exit 0), 85 MB. Not run** (no Windows here) | `--export-release "Windows Desktop"` |
| CI | The last `main` build passed (run #30, `fb1ffc9`). **This milestone isn't on `main`**, so CI hasn't built it | GitHub Actions |

Tests are excluded from exports (`exclude_filter="tests/*"`).

## Automated tests

| Suite | Baseline (`fb1ffc9`) | Now |
|---|---|---|
| Unit and scene tests | 209 passed, 0 failed | **234 passed, 0 failed** (769 s) |
| Bot playthroughs (4 endings) | 4 of 4 | **4 of 4** (escape, message, escape at purge 3, wren) |

During this milestone the choice input grace broke 9 existing tests and the Wren bot. The fix was to make the test helper `press()` wait for the grace the way a person would. **No assertion was weakened.**

## Real-browser check (Playwright, Chromium 1194 with SwiftShader)

The check is in `tests/web/web_check.cjs`; the steps to run it are in its header. Results on 2026-10-16:

| Check | Result |
|---|---|
| The engine starts and reaches the title, then a session | **Yes.** WebGL 2 (GL Compatibility), no page errors. Screenshots show the title and Arin's room mid-run |
| Audio before and after the first gesture | Before any gesture Chromium logs "AudioContext was not allowed to start"; afterwards the spied context reports `running`. **Headless autoplay rules can differ from desktop and mobile browsers. Confirm by ear on a real device** |
| The save reaches IndexedDB mid-run | **Yes:** `sessions 1, last_exit "active"` |
| Closing the tab mid-run | **Confirmed to count as a quit** on the next visit (`quits 1, purge 1, last_exit "crash"`). **The author's rule (2026-10-16): keep counting it, but warn.** The browser now asks "Leave site?" during a run (`beforeunload`, verified: `asks first: true`), and How to Play says so |

## Known defects and limits (open)

These are listed in `EXPERIENCE_POLISH_BASELINE.md` §3 and in each audit's status note:

- The console cuts off long lines with an ellipsis and has no backlog (UX C5).
- Act numbering doesn't match the guided route: Archive is ACT IV, Out of Bounds ACT III (**author decision**).
- Portrait orientation doesn't pause the game on phones (UX C9). Touch control overlaps are listed under UX C11 and C12.
- The palette contrast fixes in `CHARACTER_DIRECTION.md` need a visual review.
- **Web audio by ear:** not yet heard on a real device. Mobile Safari may not show the leave prompt, so there the tab close still counts silently.

## Platform verification

| Platform | Status |
|---|---|
| Desktop keyboard | Simulated input events in tests |
| Gamepad | Simulated joypad events in tests. **No physical controller tested** |
| Touch / phone | Simulated in tests. **No physical phone tested** |
| Browsers | Headless Chromium load only. Not tested in Firefox or Safari, not on mobile, not with audio |

## Accessibility

**Settings:**
- Master, Music, Effects and **Voices** volume.
- Fullscreen, CRT curvature, Screen effects (Off / Light / Full).
- Glitch intensity, Reduce flashing, **Screen shake**.
- Large text, Vibration, **Text speed** (Slow / Normal / Fast / Instant).
- Tutorial tips.

All settings persist (`Settings.save`/`_load`, tested). Flashing is scaled by `Settings.flash_scale()` throughout `screen_fx.gd`. **No formal WCAG flash-threshold measurement has been done.**

## Performance

Only relative frame timings are available: the visual tour under xvfb with software GL, roughly 30–45 ms per frame. These are **not** a statement about real hardware.

What still needs measuring on real devices:
- the F3 overlay in the square during HUNT;
- the Edge during the fight;
- the bin's sweep.

These should be measured on one mid-range PC and one mid-range phone, recording device, browser and resolution.

## Licensing and credits

- **Licence: all rights reserved** (author's decision, 2026-10-16). See `LICENSE`.
- **Third-party assets:** two fonts (2026-10-20): Inter (SIL OFL 1.1) and DejaVu Sans Mono (Bitstream Vera licence), subset, in `assets/fonts` with their licences; the credits screen shows both licences. All graphics and audio are generated in code. Godot itself is MIT-licensed and must be credited.
- **Credits screen:** on the title screen. It reads Godot's licence and every third-party notice from the engine at runtime (`tests/test_polish.gd` checks it).

## Release blockers

1. ~~Licence and credits~~ **Done.**
2. ~~Narrative decisions and the tab-close rule~~ **Done.**
3. ~~Save and tab-close checks in a real browser~~ **Done** (Chromium). Audio by ear and mobile browsers are still open.
4. Run at least one round of human playtests (`PLAYTEST_RESULTS.md`). The playtest log helps: open the game with `?playtest=1`.
5. ~~Merge to `main`~~ **Done** (CI builds each push).
