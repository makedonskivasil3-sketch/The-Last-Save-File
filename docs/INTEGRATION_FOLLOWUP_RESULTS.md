# Integration follow-up: implementation and evidence

Runtime source: `2b3e70d32a9df2fdd4eea5cdb9ec46767aaffe37`, Godot 4.3.
The subsequent evidence/capture commit does not change gameplay.

## What was integrated

The integration starts with the previously local opening/cast work (`7a5142a`,
`afb44e7`, `dfaa270`), merges fetched `main` (`3f471e6`) in `0bf887b`,
and includes every available remote head at review time. The ancestry ledger
is [included here](review/integration-followup/ancestry.txt). This includes
`game-presentation-polish`, `claude/review-fixes`, and `codex/map-experience`.
The advertised unpublished `a918b79`/MapSurvey code remains unavailable; no
missing geometric floor plan was reconstructed or claimed as delivered.

The [detailed Bulgarian prompt](INTEGRATION_FOLLOWUP_PROMPT.md) was committed
before implementation (`2984fe6`), then executed within its stated scope.
This is an integration and targeted repair pass, not a claim that every issue
in the project has been resolved.

## Implemented repairs

1. **Safe retry metadata.** Edge retry accepts only the exact previous numeric
   session. JSON integer-valued floats remain valid; strings, fractions,
   nonfinite values, missing keys and containers are rejected safely.
   A malformed Variant previously caused a script error, not a demonstrated
   native engine crash. Save schema, counters and ending prerequisites stay intact.
2. **Navigation reflects actual occupancy.** Redundant full/partial refreshes
   no longer invalidate all routes. The grid version changes when a cell's
   accessibility changes. Collision shapes/queries are reused with the same
   masks, exclusions and clearance. No measured hardware FPS gain is claimed.
   The existing shared-grid regression now inserts a real wall before expecting
   a version change; accepting redundant invalidation would preserve the defect.
3. **Crate movements reach navigation.** Ending a drag flushes the final 1–3 px
   movement; a settled programmatic correction also flushes after 0.25 s.
   Notifications cover old and new bounds, ongoing motion remains throttled,
   and stationary crates produce no repeated notifications.
4. **Overview matches travel direction.** Bin is east of Archive. Labels use
   the UI font, fit the actual 400×170 minimum at normal/large text, and unknown
   destinations remain `???`. This remains a topology diagram, not a floor plan.
5. **Tobben's rear clothing.** The shared illustrated renderer draws apron
   ties/bow on his back and retains the front bib/pocket in front views.

These build on the previously local charge/PHASE, escort-facing, HUD/objective,
Arin scarf and Rue/Tobben rear-view fixes; they do not replace that work.
No new endings, areas, purge rules, glitch costs or movement balance were added.

The inherited narrative reliability work was retained: reading time scales with
line length/settings, oversized lines are paginated, urgent warnings have a
separate route, and death advice waits for player input. Existing regressions
exercise these rules. This addresses the earlier fast-narration complaint at
the code level; a real listener/reader must still judge comfort and delivery.
The earlier findings ledger remains in [OPENING_CAST_REVIEW.md](OPENING_CAST_REVIEW.md).

## Evidence and acceptance

The new regression file initially produced **1 passed, 4 failed**, including
script errors for malformed metadata. After repair its five cases pass.
The pending-area-release case already passed before repair and is a retained
safety check, not a newly fixed crash. Raw logs are under
[review/integration-followup](review/integration-followup/).

Commands use isolated `XDG_CONFIG_HOME`, `XDG_CACHE_HOME` and `XDG_DATA_HOME`
per runner, with `GODOT=/workspace/.tools/godot-4.3/Godot_v4.3-stable_linux.x86_64`:

```sh
bash tests/run.sh
bash tests/run.sh --filter=integration_followup
bash tests/run.sh --bots --speed=3
# Browser tests target a local HTTP server serving the newly exported build:
node tests/web/web_check.cjs http://127.0.0.1:8767/index.html <trial-output>
node tests/web/audio_output_check.cjs http://127.0.0.1:8767/index.html
```

Browser runs use system Chromium through a Playwright launcher override; test
assertions are unchanged. Each lifecycle trial has a fresh browser profile.
The ten trials are retained individually without retrying failures away.

| Check | Completed result | Scope |
|---|---|---|
| Full headless suite | 464 passed, 0 failed, 1064.0 s; exit 0 | 464 unique completed cases, no script/parse errors |
| Final focused regression run | 5 passed, 0 failed, 2.1 s | All five new tests on final runtime |
| Earlier focused compatibility run | 30 passed, 0 failed, 105.4 s | Integration, pass8, threat navigation; preceded final diagram layout adjustment |
| Exact-ending bots | 5 passed, 0 failed, 228.6 s | Escape, message, escape purge 3/5, Wren; zero reported deaths and stalls on all five |
| Browser lifecycle | 10/10 completed trials, exit 0 | Each reports ALL WEB CHECKS PASSED; fresh profile, title/film/skip/input/save/quit/reopen |
| Browser audio output | Passed; page errors empty, no sampled clipping | Title/film/room post-mix signal; no listening |
| Exports | Web, Windows, Linux: exit 0 | Same runtime source as above |
| Exported Linux smoke | 240 headless frames, exit 0 | No script error observed |
| Windows integrity | AMD64 PE + embedded pack; ZIP CRC passed | Export only, not Windows execution |
| Rendered clean map→cast sequence | 2 passed, 0 failed, 15.1 s | llvmpipe, isolated cast scene |

The full suite completed with its summary and zero exit status verified.
The shutdown ObjectDB warning remains present and is not treated as resolved.

[Build hashes](review/integration-followup/build-hashes.json) identify local
exports. [ZIP metadata](review/integration-followup/windows-zip.json) records
the separately packaged Windows build. CI exports may have different hashes
because a later evidence commit is packaged; gameplay source is unchanged.

## Visual checks

The overview was rendered at normal/large text and with undiscovered areas:
[normal](review/integration-followup/overview_normal.png),
[large](review/integration-followup/overview_large.png),
[undiscovered](review/integration-followup/overview_undiscovered.png).
The [direction sheet](review/integration-followup/cast_directions.png) can be
compared with [the baseline](review/integration-followup/cast_before.png).

Review also caught a flaw in our earlier capture harness: the cast sheet
could inherit the preceding world's HUD/effects. The harness now explicitly
releases that scene. A combined map-then-cast rerun passed 2/2 and supplied the
clean sheet above. The four-case initial combined render pass is not used as
proof of a clean cast sheet. Rendered checks use Mesa llvmpipe under Xvfb,
not a real GPU. Seven staged area compositions and the fresh opening were
also captured locally; staged threats/effects do not establish live difficulty.

## Remaining limits and next priorities

- ObjectDB/resource-in-use messages still occur at test shutdown. They remain
  visible in the raw logs; passing assertions do not resolve these warnings.
- No human uncoached playtest, listening session, Windows execution, phone,
  gamepad or real-GPU performance measurement was performed.
- Generated audio output is tested as signal. System TTS/blips are distinct
  from recorded performances; no new actor voices or licensed voice assets ship.
- A local geometric map with discovery/cover markers, additional gaze/hysteresis
  work and recovery-version budgeting remain separate tasks.
- Narrative emotional impact, commercial demand and subtitle comfort still
  require human observation. Automated reading rules cannot certify those.
- Windows export integrity does not prove SmartScreen acceptance or execution.
  Use the current main workflow's Windows artifact once its build completes;
  a local file path is not a public download link.


## Publication

The user explicitly authorized integration into GitHub/main. After completed
local checks, this branch is published as `codex/integration-follow-up` and
fast-forwarded into `main` without force. Verify the published commit and the
subsequent CI run on GitHub; local passes do not mean that remote CI has finished.

- [main](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/tree/main)
- [integration branch](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/tree/codex/integration-follow-up)
- [build workflow](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/actions/workflows/build.yml)
