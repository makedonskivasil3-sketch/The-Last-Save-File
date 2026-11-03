# Release checklist: full PC release, target 10 December 2026

**One of three control documents**, with `RELEASE_READINESS.md` (evidence) and `production/ISSUE_REGISTER.md` (issues). It supersedes earlier plans where they disagree.

**Decision dates:**
- **Go or no-go:** 4 December 2026, against the evidence below.
- **Launch:** 10 December, if approved and safe.
- **Stabilisation:** 11–24 December.

**The scope is frozen:** the festival, eight places, six endings and Godot 4.3. Nothing new.

## Platforms and claims

| Target | Claim allowed when | Status |
|---|---|---|
| **Windows, keyboard and mouse plus a physical controller** (primary) | A clean install runs to a first ending on real hardware. Every item in the Windows gate below has passed | **Not run yet** |
| Linux | It has been run and supported on real hardware | Exports; smoke run only |
| Browser (demo or playtest) | Lifecycle checks pass, the save contract below is stated on the page, and a real low-end browser session is recorded | Automated checks only |
| Steam Deck / handheld | A real device test. A 16:10 simulation or a Linux export doesn't count | **No claim** |
| Phone browser | Experimental, playtest only. No app-store package | **No claim** |
| macOS, consoles, native mobile | Not this sprint | **No claim** |

## Release blockers

| ID | Blocker | Reproduction | Owner | Acceptance | Target | Status |
|---|---|---|---|---|---|---|
| B1 | CI red on the PR head (browser calm-save check) | Run 41537563245 at `f042ae9` | Claude | Cause measured; check fixed; head CI green | 6 Nov | **Fixed in code (`55141d6`)**: the game marks calm at once, and IndexedDB stores it 5.2–30.7 s later depending on CPU throttle. Waiting for CI on the head |
| B2 | Engine errors passed the suite | `ERROR: Lambda capture at index 0 was freed` in the 841-case run | Claude | No unexpected engine errors; the gate rejects new ones | 6 Nov | **Fixed and gated (`55141d6`)**: cause was `Area.on_arrival`. Gate self-test 7/7 |
| B3 | Coverage overstated (a skipped probe counted as passed; "six endings" claimed from five routes) | `bot_playthrough` summary | Claude | Skips reported; each ending's coverage stated exactly | 6 Nov | **Fixed (`55141d6`)**. Routes: escape, message, Wren, overwrite. Rue and unseen are Slot 2 scenarios only, so the **human round must reach them** |
| B4 | The demo candidate could end before its mission | `test_the_stairs_up_still_end_the_candidate_at_the_archive` (old) | Claude, then the author picks one endpoint | Wrong turns don't end the demo; it ends after Wren notices the light | 8 Nov | **Fixed (`55141d6`)**. The author chooses the endpoint after the player round |
| B5 | Web saves are durable only after IndexedDB sync | Measured: 5–31 s on a throttled CPU | Claude (contract), author (page text) | The page states it; a real low-end browser is measured | 20 Nov | **Contract stated (WEB-1)**. Device measurement open |
| B6 | No unfamiliar players | — | **Author** (recruit), Claude (build and kit) | 5 sessions on one build by 8 Nov, keyboard and controller | 8 Nov | **Open**. The kit is fixed: regular profiles, never wipe real saves |
| B7 | Never run on Windows hardware or a physical controller | — | **Author** | The Windows gate below | 8 Nov | **Open** |
| B8 | Steam onboarding, fee, tax and eligibility date unknown | — | **Author** | The dashboard shows the release-eligibility date. Plan on 30 days from the fee | 6 Nov | **Open**. If the fee isn't paid by ~10 Nov, a Steam launch on 10 Dec is unlikely |
| B9 | Coming Soon page live by 20 Nov | — | **Author** (assets and submission), Claude (text and captures) | Live, with honest text and shipped-game screenshots | 20 Nov | **Open** |
| B10 | Build submitted for review | — | Author | Submitted by 24 Nov | 24 Nov | **Open** |
| B11 | RC1 | — | Claude | Clean suite, every bot, exports with hashes, browser checks, rollback package | 1 Dec | **Open** |

## Required launch polish (not blockers alone)

- **The Square as the visual standard:** consistent line weight and props, light that guides routes, goals and prompts that never cover top-wall exits or windows. Then apply the rules to the other areas.
- **The workshop's staging:** see the lamp, match the wick, repair it, see the light reach the hatch, then a response.
- **The three largest problems from the player round**, fixed by staging before adding words.
- **Large text and subtitles at maximum** on every menu and the journal.
- **Store kit (`STORE_KIT.md`):** recapture the stale animatic shots from the festival; no voice-acting claims; an honest length once measured.

## Post-launch (deferred)

Steam achievements; Steam Cloud (needs its own design: not the whole user folder); localisation; recorded voice; Deck verification; other platforms.

## Windows gate (every item on a real PC, recorded with device, GPU and driver, build hash)

- [ ] Clean install and start; a first ending reached
- [ ] Across the round, all six endings reached by players
- [ ] Alt-tab; fullscreen and windowed; 1280×720, 1920×1080, 1280×800, a small window; DPI scaling; maximum text
- [ ] Controller only, from title to ending; remapping and reset; unplug and reconnect; keyboard takeover; correct glyphs; rumble on the active pad only
- [ ] Save and exit, relaunch, free resume; a failed save keeps the last good file
- [ ] Audio device change; mute and focus behaviour; laptop speakers and headphones
- [ ] Uninstall and reinstall behaviour of the save folder understood and stated

## Evidence classes used in this project

**Implemented** (in code) → **automated** (a test or bot) → **visually inspected** (a capture looked at) → **human observed** (a playtest) → **hardware measured** (a real device).

A claim names its class. Only the last two count for "ready to sell".
