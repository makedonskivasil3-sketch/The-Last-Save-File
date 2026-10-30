# Verification of the unified world pass

Game runtime: `2f03453`. Final test fixture/runner revision: `335a5f3`.
Godot 4.3 stable. No game-runtime changes follow those entrance fixes.

## Complete native coverage

**793/793 passed, zero failures or script errors, at normal game speed.**
This is a fresh four-shard run with isolated XDG directories, **not a completed
monolithic run**. Each expected test appears exactly once. See
[test-coverage.json](test-coverage.json), [test-inventory.txt](test-inventory.txt)
and the four native-shard logs. Earlier aborted/failed attempts are excluded.

| Shard | Passed | Failed | Wall time |
| --- | --- | --- | --- |
| 1/4 | 199 | 0 | 429.4 s |
| 2/4 | 198 | 0 | 352.0 s |
| 3/4 | 198 | 0 | 430.1 s |
| 4/4 | 198 | 0 | 461.0 s |

Reproduce each group with `GODOT=/path/to/godot-4.3 tests/run.sh --shard=i/4`,
setting a different XDG_DATA_HOME, XDG_CONFIG_HOME and XDG_CACHE_HOME per group.
`--list-tests` provides the inventory; malformed/out-of-range shard arguments
were independently verified to exit 2. Default `tests/run.sh` still runs all
cases in one process; main's existing CI command uses that default.

## Functional and export checks

| Check | Result and scope |
| --- | --- |
| Rendered workshop mission | **1/1**, 16.8 s, runtime 2f03453; actual walking and interact input from Archive stair through pickup, repair and hatch; software llvmpipe |
| Save and relaunch | **1/1**, 11.6 s, runtime 2f03453; all three mission stages, position/body fit, wick, hatch, quits and purge |
| Ending bots | **5/5 played routes** reached the requested ending; runner 6/6, 304.4 s includes an inactive opt-in probe. Gameplay revision a47e3f5, before the final portrait-layer and entrance-facing metadata adjustments |
| Purge-3 bot detail | Two deaths/retries (Square eraser, Edge eraser); eventual escape, not a death-free route |
| Wren bot detail | Reached Wren ending; two recovered steering stalls |
| Windows / Linux / Web exports | Final runtime 2f03453, all exit 0; no script/parse/export errors in committed logs |
| Exported Linux smoke | Runtime 2f03453, 240 headless frames, exit 0 |
| Browser lifecycle | Title → memory card → festival → room, keyboard motion, persistent calm close/reopen, no page errors; exported 9a2aa22 before the final entrance-facing metadata correction |
| Browser audio | Audible after gesture; room about -31 dBFS, no clipping or page errors; exported 9a2aa22 |
| Exported manual story reader | Keyboard and real Continue click each acknowledge one page; no session/purge charge; passed serial rerun. Earlier concurrent attempt failed the second-click assertion; both logs retained |
| Browser touch/rotation | Final export 2f03453: gameplay clock holds in portrait, Resume refused, landscape preserves pause, explicit Resume works, no page errors. Chromium touch emulation, not physical iPhone Safari |
| Source formatting | git diff --check passes |

Build identities: [build-hashes.json](build-hashes.json).
Screenshots: [screenshots](screenshots/). The Windows ZIP is packaged locally;
a local path is not a public download. Main's build workflow creates the
supported GitHub Actions artifacts and deploys Pages after its own checks.
Do not equate a local export with a completed public deployment.

## Warnings and limits

- Existing ObjectDB shutdown warning and anchor/size warnings remain visible.
- Save-failure tests intentionally exercise broken JSON/write failures; these
  expected engine messages are distinct from SCRIPT ERROR/Parse Error.
- The first browser story-click failure under concurrent software-rendering
  load is not presented as a diagnosed, fixed product bug. A serial rerun
  passed; slow-device input and reading behaviour still need stress checking.
- No physical Windows, iPhone, controller or hardware-GPU session was performed
  here; no human listening or unfamiliar-player study was conducted here.
- Friends' early feedback motivated this pass; their exact build/device and
  route have not been independently verified.
- All art remains procedural/provisional. No recorded acting was added.
- No claim of final campaign pacing, playtime, price/value or sales validation.
