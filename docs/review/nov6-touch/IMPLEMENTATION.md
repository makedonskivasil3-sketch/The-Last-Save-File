# Touch gameplay and production review — 6 November 2026

Base: main 8112117 (PR #13). Runtime changes: ac3786d, 9c99122 and 0ad88b3. The recent reload protection,
Edge grace, story chapters, clearer RUE route, naming choice and calibration art
are preserved. This pass implements interaction reliability, not new story scope.

## What changed

- Virtual E gestures have an identity independent of frame timing. The HUD records
  the gesture it consumed; a released-and-pressed new gesture can act immediately
  after dialogue, while the closing gesture cannot reopen the world.
- Multi-touch E holds belong to all participating fingers until the last release.
  Logical holds survive unrelated pointer events. Cancelled gestures never tap;
  an old scene cannot release a newer scene's owned gesture. Reasserted actions
  are released synchronously on focus loss.
- Cinematic readers retain a pending virtual gesture within their current context
  instead of depending on one-frame flags. Skip arming only peeks at a gesture;
  reveal/advance consumes it. Scene-entry presses are consumed at context entry.
- The memory card has explicit Show line/Continue and hold-to-skip controls.
- Festival Continue and Skip accept raw touch and real mouse input without mouse
  emulation. Skip is above story panels, including the final reader. Drag-out,
  cancellation and focus loss cancel the gesture. Festival portrait holds its
  simulation and clears virtual controls. Keyboard/controller input cannot dismiss
  the portrait hold and accidentally unblock Resume.
- Keyboard/controller routes remain in the readers; normal gameplay speeds,
  map geometry, endings, irreversible-loss policy and approved canon are unchanged.

## Reproduction and tests

An isolated review of 8112117 reproduced a new E tap being discarded after a
one-frame-old dialogue close (twice), multi-touch E losing its hold, a festival
skip dependency on mouse emulation, and the missing memory-card touch controls.
Ordinary E and same-frame down/up worked; no blanket claim that fast taps fail.
The existing helpers spaced down/up over multiple frames and missed these cases.

New test_touch_reliability (14 cases) covers those conditions plus raw-touch reading,
final-reader skip, cancellation, held-input safety, cinematic page consumption
and scene ownership. No physical iPhone/Android or Windows session was performed.
Full-suite/export/browser evidence and any limitations are recorded alongside this
report after verification; do not equate native injection with phone certification.

## Opinion and next work

The game has a clearer emotional arc and better automated ending coverage. It
still lacks a documented structured unfamiliar-player round and physical launch
hardware evidence. Input trust is the immediate priority: a player cannot fairly
judge the story while unsure whether a tap registered. Final artwork, character
presence, human listening, measured pacing/value and the permanent-loss decision
remain production work, not things solved by adding more lore or maps.

This is a source and automated-play assessment, with rendered browser inspection;
it is not a substitute for an unfamiliar person's complete playthrough. My stage
assessment is a developed playable prototype approaching a production-quality
slice, not a commercially validated release candidate. Six functioning endings
prove breadth of implementation, not that the emotional journey lands.

The owner's reports from friends are useful qualitative feedback and motivated
the touch investigation. A supported-platform strategy does not make an unreliable
visible control acceptable. What is missing is a structured round with exact
builds/devices, observed routes and recorded comprehension, not evidence that
anyone has ever tried the game.

### Gameplay

The useful core is investigation under an adapting threat, with help and memories
changing what Rue can do. The workshop gives a better example of a complete
action/consequence loop than travelling to collect another explanation. Expand
that quality within existing places: changed encounters on required returns,
shortcuts after accomplishments, and an actionable next destination after a
discovery. Measure empty retracing before changing geography. Keep the distinction
between a short interaction and a deliberate held glitch legible. Reliable input
is foundational; adding content while taps feel unreliable would hide the problem.

### Story and characters

Rue gaining agency and Wren remembering a shared action are the strongest emotional
foundation. Preserve them and deepen two weaker arcs through actions and changed
behaviour, particularly Mira's agency and Tobben's conflict between duty and
choice. Avoid using every encounter to explain another system. Sequence concepts
around immediate needs; journal facts, claims and mysteries separately. The well's
recordings must not imply live contact. A twist should reframe witnessed actions,
not invalidate the investment players made in a character. The RUE route needs
human discovery testing, not an invented second-run restriction.

These arcs already have substantial state: `relationships.gd` records Mira's
walk, pinned/lost note, board check, restoration and colour, and Tobben's guestbook,
interception, crossed-out name, restoration and voice. The next task is to measure
their discovery and payoff, not pretend those features are missing. The journal
already separates people, memories, documents, objects, places and leads; improve
its usefulness and discoverability before building a second collection screen.

### Commercial judgement

There is a plausible niche premium PC game here: the abandoned-save premise,
remembered relationships and an adapting Owner can support a clear pitch. There
is no defensible sales probability or revenue estimate from the present evidence.
The immediate commercial risks are provisional visuals, concept overload, input
trust, unmeasured human pacing/value, permanent-loss fairness and missing Windows
hardware validation. These take priority over new maps or full voice production.

I would fund the next bounded milestone: one connected section at final visual
quality, dependable controls, two character payoffs and an unfamiliar-player round.
Use observed comprehension, completion, voluntary continuation and repeated
frustrations to decide the next investment. Build the budget from measured work
and asset quotes. Treat the December date as conditional; the repository does
not establish storefront eligibility or sufficient release evidence.

Recorded acting could help after the script is stable. Distinguish it from TTS,
retain subtitles/manual advance, and test a small licensed voice pilot first.
Do not voice every line before testing whether people understand and care about it.

Detailed next-stage prompt:
[GAMEPLAY_STORY_COMMERCIAL_NEXT_NOV6.md](../../prompts/GAMEPLAY_STORY_COMMERCIAL_NEXT_NOV6.md).


## Final verification

Runtime candidate: **0ad88b372d69b34712389e2e051bf18674b00146**, Godot
**4.3.stable.official.77dcf97d8**. Documentation/CI commits after this revision do
not change the runtime. Evidence is stored in this directory.

| Check | Result | Evidence / limit |
|---|---|---|
| Full native suite, normal speed | **867 passed, 0 failed, 0 skipped** | Four independent source copies and isolated XDG directories. All inventory IDs occur exactly once; strict unexpected-engine-error checker passed on each log. `coverage.json`, `inventory.log`, `full-shard1.log` through `full-shard4.log` |
| Focused touch checks | **26/26** | `touch-focused.log`; includes 14 new regressions and the extended existing portrait regression |
| Exported Web opening, final candidate | **Pass** | Raw touch reads or skips the card, then holds festival Skip to reach the game; title bootstrap uses mouse/keyboard. `browser-opening-0ad88b3.log` and JSON/captures |
| Exported Web portrait recovery, final candidate | **Pass** | Portrait freezes, Escape cannot resume, landscape preserves pause, explicit Resume works. `browser-orientation-0ad88b3.log` |
| Exported Web lifecycle | **Pass on 9c99122** | Actual keyboard movement, IndexedDB save, calm tab close and free resume, no page/runtime errors. Final candidate additionally changes portrait input handling only. `browser-lifecycle-9c99122.log` |
| Exported Web reader | **Pass on 9c99122** | Keyboard and real mouse Continue each acknowledge one page and store it; no session/purge cost. `browser-reader-9c99122.log`; reader acknowledgements 87/117 ms in this loaded environment, not a performance benchmark |
| Windows, Linux, Web exports | **All succeeded on final candidate** | Local packages hashed in `build-manifest.json`. Local displayed build stamp is `dev`; CI generates its own commit stamp |
| Exported Linux headless smoke | **240 frames, exit 0** | `linux-smoke.log`; not a human playthrough |
| CI integration | **Configured, remote execution pending** | New opening touch browser check runs after lifecycle checks and blocks packaging on failure. YAML parsed and script syntax checked |

The first full attempt caught the focus-loss action regression, now corrected in
9c99122 (`pre-fix-focus-loss.log`). A subsequent shared-tree run during export/import
activity had two fatal engine thread-access errors. Raw failures are retained in
`interrupted-shared-tree-shard2.log` / `interrupted-shared-tree-shard3.log`; no
allowlist was relaxed. Other superseded runs were stopped, not counted as passed.
The complete final isolated-source run above did not reproduce either crash.
The cause is **unconfirmed**, tracked as QA-3; source isolation is a verification
condition, not proof of a root cause or a runtime repair. Known anchor/ObjectDB
fixture warnings remain visible in logs.

Physical phones, a Windows playthrough, a physical controller, human mix approval,
structured comprehension and campaign pacing remain unverified. All-six-ending
bot evidence belongs to baseline 8112117; those full routes were not rerun locally
on this input revision. The existing CI bot gate will run separately. No commercial
readiness, new recorded acting, final art approval or revenue outcome is claimed.
Local package paths are not public downloads; GitHub Actions produces downloadable
artifacts only after its own workflow succeeds.
