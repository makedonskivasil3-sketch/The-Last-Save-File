# Release readiness

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

## Known defects and limits (open)

These are listed in `EXPERIENCE_POLISH_BASELINE.md` §3 and in each audit's status note:

- **Web tab close probably counts as a quit/crash (+1 purge).** Unverified. Distinguishing a deliberate quit from an interruption needs a browser test and **an author decision**.
- The console cuts off long lines with an ellipsis and has no backlog (UX C5).
- Act numbering doesn't match the guided route: Archive is ACT IV, Out of Bounds ACT III (**author decision**).
- Portrait orientation doesn't pause the game on phones (UX C9). Touch control overlaps are listed under UX C11 and C12.
- The palette contrast fixes in `CHARACTER_DIRECTION.md` need a visual review.
- **Web audio first-interaction unlock:** not verified in a real browser.

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

- **Licence:** none chosen. The README says "TBD", and there's no LICENSE file. **This blocks any public release.**
- **Third-party assets:** none. All graphics and audio are generated in code, and the font is Godot's built-in fallback. Godot itself is MIT-licensed and must be credited.
- **Credits screen:** none yet.

## Release blockers

1. Choose a licence and add credits, including Godot's MIT notice.
2. Make the author decisions in `NARRATIVE_DECISIONS.md`, plus the purge rule for web tab close.
3. Test web audio and the save in a real browser (first-interaction audio; tab close, then reload).
4. Run at least one round of human playtests (`PLAYTEST_RESULTS.md`).
5. Merge this milestone to `main` and let CI build it.
