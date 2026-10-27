# Backlog to a commercial 1.0

**Revision:** 2026-10-27. IDs in brackets refer to [`ISSUE_REGISTER.md`](ISSUE_REGISTER.md).

Each task states:
- the **problem**;
- the **scope**;
- its **dependencies** (deps);
- the **acceptance criteria**;
- how it is **verified**;
- any **licensing** or spend consideration.

**"Author"** marks a creative decision only the author can make. Nothing here authorises spending, publishing, voice cloning or merging.

## Blockers (no release without these)

| # | Task | Problem → scope | Deps | Accept when | Verify | Licensing/spend |
|---|---|---|---|---|---|---|
| B1 | Windows run on real hardware [PL-1] | The build has never been executed on Windows. Run `WINDOWS_PLAYTEST.txt` end to end on one PC | a person with Windows | Festival → room → square without crash; exit and reopen keeps the save | a written report with device, GPU and build hash | — |
| B2 | Hardware performance [PL-2] | Only llvmpipe numbers exist. Profile the square HUNT, the Edge and the bin on one mid-range PC | B1 | ≥ 60 fps at 1080p, or a documented minimum spec | F3 overlay capture plus a CSV | — |
| B3 | Physical controller [PL-2] | Simulated only. Play the festival and the room on an Xbox/PS pad | B1 | Every prompt shows pad glyphs; holds work; rumble only on the active pad | report | — |
| B4 | Save and Exit rule [SV-1] | **Done 2026-10-27:** the author delegated the choice; option (b) is built | — | Safe-moment suspend, one resume, no purge; quitting still counts | `test_suspend.gd` | — |
| B5 | Unfamiliar-player playtests [EV-1] | No evidence. Run `PLAYTEST_PLAN.md` with ≥ 5 people who haven't seen the game | B1 | Findings logged; S1/S2 findings fixed or accepted by the author | session notes + PlaytestLog files | possibly participant reward → **authorisation** |
| B6 | Campaign complete | All six endings reachable by a human, not only bots | B5 | One human run per ending, or the author accepts bot evidence for the rarest | report | — |
| B7 | Control remapping [UI-3] | None exists. Settings → Controls: rebind keyboard and pad, persist, reset | — | Every action can be rebound; conflicts are refused; prompts show the new binding | unit tests + a tour | — |

## Essential

| # | Task | Problem → scope | Deps | Accept when | Verify |
|---|---|---|---|---|---|
| E1 | One exceptional relationship | **Author chose Wren (2026-10-27).** First pass built: [`WREN_ARC.md`](WREN_ARC.md) | — | Each beat reachable, kept across sessions, changes the ending text | `test_wren_arc.gd`; playtest pending |
| E2 | Fair Owner | Audit every Owner move: telegraph ≥ 0.6 s, readable counter, never during cards | — | A matrix row per move with a passing test | suite |
| E3 | Earned endings | Each ending's preconditions shown in the journal as leads, never as a checklist | E1 | Every ending has a lead visible before its choice | tests |
| E4 | Console backlog [UI-1] | Long lines are cut; no history. Add scroll-back | — | The last 50 lines are readable; wrapping, not ellipsis | test |
| E5 | Flash measurement [UI-4] | Measure the flashing sequences against WCAG 2.3.1 with and without Reduce flashing | — | Documented ≤ 3 flashes/s, or the sequence is changed | frame analysis script |
| E6 | Bot route stability [PL-4] | Purge-3 steering stalls. Root-cause, don't widen timeouts | — | 10 consecutive green bot runs | bot logs |
| E7 | Captions pass | Every voiced or ambient line has a caption with a speaker label | — | `test_voice_manifest` + a caption audit | tests |

## Polish

| # | Task | Scope | Accept when |
|---|---|---|---|
| P1 | Fifth-lantern arc vs. nameplate [OP-6] | Move the arc, or lift the nameplate, while holding | No overlap in the frames |
| P2 | Idle pacing [OP-8] | Tune `AUTO_AFTER` from playtest data only | B5 data |
| P3 | Silhouette mode [UI-5] | A real silhouette, if callers need one | Callers audited |
| P4 | Act numbering [UI-6] | **Author** | Decision applied |
| P5 | Suite runtime [PL-6] | Parallel shards, or a fast subset for local loops; the strict full suite stays the gate | < 10 min local subset |

## Optional

- Recorded voice pilot (Mira or Wren, one scene). Needs **authorisation** to spend and a performer contract; no cloning.
- Commissioned key art for the store capsule (**authorisation**).
- Trailer from `tour_intro_capture` frames.

## Post-release

- Move binary captures out of the repository: LFS or release assets [PL-7].
- Mobile and touch [UI-2].
- Localisation.

## Milestones

| M | Content | State |
|---|---|---|
| M1 | Evidence: spec, register, matrices, backlog, beat sheet | **this branch** |
| M2 | Opening rebuilt (OP-1…OP-7) | **this branch** (automated verification only) |
| M3 | B4, B7, E2, E4, E5 | proposed |
| M4 | E1, E3, E7 (relationship and endings) | proposed (needs the author's choice) |
| M5 | B1–B3, B5, B6 (hardware and people) | blocked on people and hardware |
| M6 | Release QA, store kit, author sign-off | proposed |
