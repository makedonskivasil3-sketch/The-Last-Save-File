# Opening/cast verification

Runtime source: `afb44e7a4122786f59bc29ce00d02ad8c0c87952`, including
`7a5142a`'s preceding fixes.
Baseline: `decaf1f7f1851358bf0b357f15509d654066d20a`.
Later review commits add evidence, documentation and a static map-capture
harness; they do not change the tested runtime or headless regression cases.

The full unit suite and browser repetition results are filled below only
when completed. An exited process or partial log is not counted as a pass.

## Completed focused checks

| Check | Result | Kind |
|---|---|---|
| Godot 4.3 import and parse | Passed | Automated |
| `tests/run.sh --filter=opening_slice` | 6 passed, 0 failed, 10.4 s | Automated integration |
| Charge at simulated 30/60/120 FPS | Hold and cooldown threshold-crossing fractions checked at each rate | Automated; not hardware FPS |
| Final opening/cast tour | 2 opening/cast cases passed; genuinely fresh title/film/boot/room/first exit | Rendered automation and visual inspection |
| Final static composition tour | 1 passed, 0 failed, 12.1 s; all seven named areas | Rendered automation; effects off, threats held |
| `tests/run.sh --bots --speed=3` | 5 passed, 0 failed, 230.1 s | Exact-ending automation |
| Summary/import rejection probes | Missing summary, empty summary, script error and failed import all rejected | Negative harness checks |
| Web audio output | Title, film and room have post-mix signal; no sampled clipping or page errors | Waveform/output check; no listening |
| Windows export | PE32+ x86-64, embedded pack, ZIP CRC verified | Export and file integrity only |
| Linux export | Exported binary runs 240 headless frames, exit 0, no script error | Exported-build smoke |

The initial targeted run reproduced three gameplay defects; its fresh-save
test also had a fixture access error (`Note` has `text`, not `lines_provider`).
That fixture was corrected before claiming fresh-save coverage. The separate
objective regression failed before its correction. An intermediate bot run
exposed a finished-tween replay error introduced during this pass; it was
fixed, regression-tested, and the complete bot run restarted. Intermediate
interrupted runs are not included in final pass counts.

## Exact-ending bots

| Scenario | Ending | Deaths | Reported stalls | Other evidence |
|---|---|---|---|---|
| Fresh escape | escape | 0 | 0 | 5/5 memories, Pip, one reload |
| Message | message | 0 | 0 | 5/5 memories, Pip, one reload |
| Escape, purge 3 | escape | 0 | 11 | Recovered; 5/5 memories, Pip, one reload |
| Escape, purge 5 | escape | 0 | 0 | 5/5 memories, Pip, no reload |
| Wren | wren | 0 | 0 | Wren present, 4/5 memories, one reload |

The purge-3 stalls occur during the Edge routing/lure loop. Completion is
verified; smooth human navigation is not established by that result.

## Reproduction

Use the official Godot 4.3 Linux editor binary as `$GODOT`, with writable
`XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `XDG_DATA_HOME`. Concurrent checks must
use separate user-data/config/cache roots. Commands from the repository:

```sh
"$GODOT" --headless --path . --import
GODOT="$GODOT" bash tests/run.sh --filter=opening_slice
GODOT="$GODOT" bash tests/run.sh
GODOT="$GODOT" bash tests/run.sh --bots --speed=3
```

With a display or Xvfb and an existing screenshot directory:

```sh
"$GODOT" --audio-driver Dummy --path . -s res://tests/run_tests.gd -- \
  --test-mode --tour --filter=tour_opening_review --screenshots=/path/to/evidence
"$GODOT" --audio-driver Dummy --path . -s res://tests/run_tests.gd -- \
  --test-mode --tour --filter=tour_map_review --screenshots=/path/to/evidence
```

The cast sheet is deliberately enlarged; ordinary gameplay captures retain
the native game figure size. See [the ledger](OPENING_CAST_REVIEW.md) for the
actual first-run fixture and staged positioning limits.

Browser checks use the project’s existing scripts, Playwright 1.56.1 and
system Chromium, against a local HTTP server serving `build/web`. This
environment uses a local Node preload to set Playwright's `executablePath`
to `/usr/bin/chromium`; assertions are unchanged. Each trial starts its own
fresh browser context and save storage. No failed trial is retried away.

```sh
node tests/web/web_check.cjs http://127.0.0.1:8766/index.html /path/to/trial-NN
node tests/web/audio_output_check.cjs http://127.0.0.1:8766/index.html
```

Official Godot export templates were SHA512-verified against the release
checksum file before installation. Windows, Linux and Web exports used
the existing presets; no unlicensed voice pilot was added to an export.

## Evidence

- [Cast before](review/opening-cast/cast_before.png) / [after](review/opening-cast/cast_after.png).
- [Charge before](review/opening-cast/charge_before.png) / [after](review/opening-cast/charge_after.png).
- [Large-text charge](review/opening-cast/charge_large_text.png).
- [Actual fresh room](review/opening-cast/fresh_room.png) / [first exit](review/opening-cast/first_exit.png).
- Composition: [room](review/opening-cast/map_room.png), [square](review/opening-cast/map_square.png),
  [Archive](review/opening-cast/map_archive.png), [house](review/opening-cast/map_house.png),
  [Bin](review/opening-cast/map_bin.png), [Out of Bounds](review/opening-cast/map_oob.png),
  [Edge](review/opening-cast/map_edge.png).

## Failures and limits retained

- Historical `tour_visual.test_tour_areas` timed out at 90 s under software GL.
  Its accumulated 90-frame measurements exceeded the method budget. It has no
  successful final summary and is not reported as a passing tour. The shorter
  composition harness addresses capture validation; it does not establish
  performance or hide that timeout.
- An earlier visual invocation lacked its output directory; it was invalid
  setup, not gameplay evidence. Final captures use existing, separate output
  directories.
- Verbose isolated shutdown logs identify WAV streams/playbacks retained at
  exit. A title-only diagnostic stopping all players and waiting 0.3 s for the
  mixer exits without the warning. No general fix or gameplay crash is claimed.
- Graphical Linux reports no speech service (`synth is null`); system speech
  on this machine is not verified. Optional speech was not enabled by the pass.
- No recorded voice performances were produced. Existing manifests and
  truth-dependent dialogue were preserved and remain subject to the full suite.
- Human playtest, listening, real-GPU profiling, Windows execution, phones,
  and physical-controller tests are pending. Native Windows export success is
  not Windows runtime verification.
- Local builds and paths are not public download URLs. No publication or
  merge was performed. The Windows ZIP is a local review artifact only.

## Integrated completion

Full suite: **459 passed, 0 failed, 1064.8 s, process exit 0**. The completed
summary and absence of script/parse errors were checked; 459 distinct passing
case names match the 459 methods discovered in the current unit/integration
source. This is one complete final run, not a sum of focused runs. Runtime
and headless-test code match `afb44e7`; the later review commit changes only
documentation/evidence and the separate static composition tour.

The full run ends with the existing **ObjectDB instances leaked at exit**
warning. It does not end with the three-resource-in-use error seen in the
isolated diagnostic runs. The warning remains unresolved and is not hidden.
See [the full log](review/opening-cast/full-suite.txt).
Browser lifecycle trials: **10/10 passed, 0 failed**, ten separate fresh
contexts, each with its own completed `ALL WEB CHECKS PASSED` summary.
Chromium `154.0.8037.57` (Debian trixie), headless SwiftShader. Trials cover
title, first film/skip, readable boot, actual movement, saved active session,
armed beforeunload guard, close confirmation and exactly one quit/purge on
reopening. See [browser-results.json](review/opening-cast/browser-results.json).
No failed lifecycle trial was retried. This does not establish mobile-browser
or physical-device reliability.
