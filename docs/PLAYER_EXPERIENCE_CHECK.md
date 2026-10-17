# Player experience validation

## Changes in this pass

- Pause → Console history: full, wrapped text of the latest 200 console messages that have started appearing this run. No future queued messages. Resets on a new run. Mouse wheel, touch scrollbar and Older/Newer buttons; keyboard/controller focus on buttons. Reading pauses the game.
- A multi-threshold awareness jump applies all consequences, but plays one stinger, pulse and startle and speaks only the highest state. The door approach also names its awareness cost. No change to thresholds, purge rules, NPC fates or ending requirements.
- Repeat materialization takes 0.45 seconds instead of 1.4. First-run animation and boot are unchanged; later runs retain death recall, owner notes, changed world and repeat thoughts.
- CI now runs the four existing full-game bots and boots the exported Linux build after the unit suite.

## Human playtest: 3–5 people, 15 minutes each

Use a build from this PR; record its commit hash. Do not use the main Pages build until the PR is merged. Get permission before recording a person or their screen. Use `?playtest=1` for web or `-- --playtest` on desktop. Reset owner memory before each fresh player. Keep separate saves/profiles so the quit test does not affect their session.

Observe silently; avoid explaining controls. Record:

| Moment | Time / player explanation / any help needed |
| --- | --- |
| First movement | |
| Door closes: why did awareness rise? | |
| First deliberate hold-to-glitch | |
| Leaves bedroom | |
| Understands hiding and its risk | |
| First death and cause understood | |
| Notices a concrete change on next run | |
| Finds console history and recovers a missed line | |
| Chooses to explore or avoids it because of punishment | |
| Wants to continue or stop; why? | |

Afterwards ask: “What do you think is happening?”, “What would you try next?”, “What felt unfair or unclear?” Copy Pause → Playtest log alongside notes into PLAYTEST_RESULTS.md. Keep that file marked untested until real sessions happen.

For returning players, observe runs 2–3: do they regain control promptly, notice the changed world, and still understand the owner's response? Do not assume a faster animation solves route repetition.

## Device and platform checks

Fill in actual device, OS/browser versions, input, resolution, build hash, pass/fail and evidence. Blank means untested.

| Check | Evidence / result |
| --- | --- |
| Desktop keyboard: pause → history → Older/Newer → Back → Resume | |
| Large text: history wraps and every button remains reachable | |
| Physical controller: same path, focus visible, no accidental choices | |
| Android Chrome and iPhone Safari: landscape touch movement and hold-to-glitch | |
| Phone portrait: controls, pause access, rotation back to landscape | |
| Browser audio: silent/autoplay state before gesture, audible music/effects/voices after gesture | |
| Sound sliders, mute/unmute and headphones: listen for clipping or harsh spikes | |
| Chrome, Firefox, Safari: title → session → save → reopen | |
| Close active tab: warning where supported; next visit counts one quit | |
| F3 performance: square during HUNT, Edge fight, bin sweep; record timings/device | |
| Exported Windows and Linux: launch, play, quit, reopen/save persistence | |

Headless tests cannot establish sound quality, physical controller feel, phone usability or real GPU performance. A simulated controller event is not physical-device verification.

## Automated checks

Run sequentially (tests use shared test-save paths):

```sh
GODOT=/path/to/godot tests/run.sh
GODOT=/path/to/godot tests/run.sh --bots --speed=3
```

For a web export, use the existing `tests/web/web_check.cjs` with Playwright and a fresh browser profile. It inspects audio context state and save persistence; listen on a real device too. See its header for invocation.
