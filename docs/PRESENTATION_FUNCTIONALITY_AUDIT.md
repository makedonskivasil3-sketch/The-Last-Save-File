# Code and player-experience revision — 2026-10-21

Reviewed baseline: `da83f01aeaab6015914a7d7d028783e9c84b9558` (fetched GitHub
`main`). Runtime repairs in this revision: `e69ab5c` and `9117b18`.
During verification, GitHub main advanced to `2644629` (PR #8, runtime
`2ffc036`). That incoming finale/gaze revision is reviewed and integrated
before final publication; its historical evidence remains separate.
Combined runtime/merge source: `1c21266c5ac34c07b09cf7004867003e8aa05a8e`.
The 467-case pre-integration suite below is retained as historical evidence;
the integrated tree contains 471 cases and requires separate acceptance.

## Judgment

The game has a coherent, implemented identity: trespassing inside somebody
else's save, a learning Owner, five memories restoring Rue, consequential
retries, fraying, companions and six authored endings. It is a substantial
late prototype. The main remaining gap is the consistency of presentation
and player understanding, rather than a need for more mechanics or endings.
The current verification does not establish commercial readiness, emotional
impact, or comfortable narration for real players.

The review read the live renderer, player/NPC animation drivers, HUD/pacing,
voice loaders, progression/interaction/escort code, threat navigation,
area/FX helpers, saves/settings, export workflow and relevant regressions.
It also inspected the previously captured opening room, Edge composition and
cast sheet. Those historical captures are labelled as historical; a new
rendered portrait check accompanies the repairs below. This is not a human
playthrough or an exhaustive proof that all code is defect-free.

## What is already implemented and must be retained

- Manual dialogue advancement is the default. First press reveals, a later
  press advances; automatic mode waits for reading allowance and speech.
- Reading time scales with text/punctuation; unvoiced long dialogue is paginated.
  Warning strip, history, subtitle size/backing and reduced effects exist.
- Charge timing excludes hold/cooldown gates; PHASE validates its landing;
  prompts use ActionPreview and target retention. Do not reimplement these.
- Shared NavGrid, conditional occupancy versions, collision-safe threat travel,
  unreachable-route recovery and final crate movement notifications exist.
- Cast uses IllustratedCharacter, with restored/borrowed palettes, Arin's scarf,
  Rue's rear cowlick and Tobben's rear apron ties already corrected.
- Save recovery uses SafeFile; Edge retry session metadata has been hardened.
  Quitting intentionally affects the persistent world.
- Music has baked layers and speech ducking; optional system TTS and procedural
  character blips are available. These are not shipped actor performances.
- Windows/Linux/Web exports, browser lifecycle/audio checks and five exact-ending
  bots exist. The bots cover three ending identities, not all six end to end.

## Findings, ranked by player impact

Severity means next-pass priority, not a claim that every item crashes the game.
**Confirmed** means a direct source finding or reproduced behavior; **risk**
means a plausible failure requiring its specified reproduction; **design**
means a proposed experiential improvement awaiting observation.

| ID | Priority / evidence | Finding and source | Consequence / required next action |
|---|---|---|---|
| A01 | P2 / reproduced, fixed here | `PortraitView._process` redraws but never updates `_figure`; the live renderer's `_t` stays at its random initial value | Breathing and mouth phase can freeze despite changing `frame` strings. Advance the actual figure only while visible in the tree. New regression failed, now passes. |
| A02 | P2 / reproduced, fixed here | `Hud._update_dialogue_face` checks recordings but omits system speech after revealing the line | Mouth can stop while TTS continues. Use existing `voice_busy()`; retain reduced-flashing behavior. Regression controls the speech callback, not a real OS voice. |
| A03 | P1 before art replacement / confirmed integration gap | `CharacterArt.texture_for` supports external PNGs, but live `PortraitView._rebuild/_draw` always builds/draws IllustratedCharacter | Supplying the documented portrait PNG does not update live dialogue. Introduce one tested asset resolver/fallback path and preserve restoration/fraying. Existing `CharacterArt.image` assertions do not validate the live portrait. |
| A04 | P1 before recording rollout / confirmed branch, overflow risk | `Hud.paginate` leaves a recorded source line whole whenever VoiceOver has it; `_fit_dialogue` grows height without a viewport cap | Adding a long recording can bypass subtitle pagination. Reproduce at maximum combined text settings; implement timed caption pages while playing one uninterrupted take. No current shipped take demonstrates this overflow. |
| A05 | P1 / confirmed timing difference; human impact unmeasured | `StoryPacing.ambient_time` caps every kind at 6 s; owner priority can reduce the current pause to 0.8 s; console retains 4 lines, or 3 with large text | Manual dialogue does not protect all ambient story reading. Classify essential narrative versus incidental telemetry; keep urgent warnings immediate. History is recovery, not proof of comfortable first reading. |
| A06 | P2 / confirmed | `World._process` drives `Npc.talking` for the conversation's duration; `World.expressions_for` supplies authored per-line moods only for Mira and Wren | World mouths can continue while waiting for manual advance, while other speakers mostly use default moods. Drive speaking from the active line/voice with mute/written exceptions; HUD reveal-time mouth animation also needs a muted/written-speaker case. Author a small grounded expression set. |
| A07 | P2 / confirmed | `Npc._process` keeps its normal idle style/wave when RESTRICTED; both renderers draw the reading book without checking rear-facing/talking | Restriction can read as a normal friendly wave/hop; book can appear on the back. Define pose priority and prop occlusion, test restored/frozen/restricted/deleting variants. Do not suppress a mute character's ability to communicate in writing. |
| A08 | P2 / confirmed on original baseline; fixed upstream | `PixelCharacter.look_at` bypassed `turn` and lacked directional hysteresis at `da83f01` | Incoming PR #8 / `2ffc036` adds both. Preserve its regression and validate it with the live-portrait clock repair; do not ask the next implementer to redo this fix. |
| A09 | P2 / confirmed frame-based probabilities | `Player._process/_update_mood` evaluates tear/dropout/palette-flicker probabilities per frame, while other jitter uses delta | Event frequency/duration varies with rendering FPS. Specify rates/holds in seconds and sample timers; validate at simulated 30/60/120 FPS. Do not claim these visual probabilities change threat difficulty. |
| A10 | P2 / design, supported by inspected captures | Cast is readable but shares procedural limb/mouth motion; room rug/light compete with the tiny initial actionable objects; Edge shot reviewed was staged with threats held | More detail alone will not supply acting or route clarity. Prototype one movement/turn/talk beat and one playable room with focused lighting; inspect active hazards separately. No assertion that an uncoached player missed these objects. |
| A11 | P2 / confirmed limitation, not a map regression | `MapView` is a topology overview; no available MapSurvey or room floor plan exists | If players get lost, test a discovered local map against improved landmarks first. Do not advertise the overview as a floor plan or reveal unseen content. |
| A12 | P2 / measurement gap | `IllustratedCharacter.draw/_Parts` rebuilds shape arrays/outlines; `PortraitView._draw` creates a StyleBox; canopy logic gathers reveal nodes; performance test is headless | Candidate costs, not established bottlenecks. Profile rendered builds, report p50/p95/p99 and allocation/frame spikes before caching or rewriting. |
| A13 | P1 release gate / confirmed absence | `audio/voice` contains the manifest/README, no shipped recordings; `Narration` selects device voices by list index; archived VOICE_PILOT reports non-shipping takes | TTS voice identity varies by device. Produce a small rights-cleared voice pilot and actually listen. Verify current provider/voice terms; historic pilot notes are not a current licence check. |
| A14 | P1 release gate / known observed warning | ObjectDB/resource-in-use messages remain at shutdown even though assertions pass | Isolate ownership/callback/audio teardown with small cases and repeated exits. Preserve warnings as evidence. Do not call them fixed by broad object-count checks or log filtering. |
| A15 | P1 release gate / confirmed evidence gap | Bots exercise escape/message/Wren identities; unit tests cover other endings; no uncoached humans, Windows execution, real GPU/phone/gamepad sessions verified | Add exact-route bots for remaining endings where useful, but obtain actual human/device evidence. Automation cannot certify engagement, fair surprise, voice performance or commercial demand. |
| A16 | P2 / source-risk, not reproduced here | `Settings._load` validates some bools/arrays but directly converts most numeric preferences | Malformed ConfigFile values deserve isolated fuzz cases before claiming safe recovery. This review does not label an untested settings crash as reproduced or change the save schema. |
| A17 | P2 / confirmed project limitation | UI/prose are authored in English; input mappings exist but no runtime rebinding/localization system was found | Prioritize keyboard/gamepad clarity and text expansion before proposing localization. Bulgarian discussion does not mean the game itself has a Bulgarian translation. |
| A19 | P1 / reproduced, fixed here | `Area.geometry_changed` awaited a second `get_tree().physics_frame` after the old area had been detached | An actual bot run emitted a null-tree script error. Capture the active tree and check membership after each wait; the new detach-before-first-resume regression failed, then passed. The previous immediate-free regression did not cover this lifecycle. |
| A20 | P2 / reproduced, fixed here | `tests/test_case.gd:shot` ignored failed PNG writes | A supplemental run printed 7 passing assertions while screenshots were absent because its output directory had not been created. The helper now creates the directory and checks the image/write result. A blocked target intentionally fails; a new nested output directory succeeds. |
| A21 | P2 / confirmed duplication | RecycleBin constructs the `SYSTEM_FILES`/`SHADOW` protected rectangle separately in drawing and `sheltered_at` | Centralize the geometry before improving shelter edges. No mismatch or unsafe shelter was reproduced here. |
| A22 | P2 / source-supported risk | OwnerAvatar._recover refuses recovery when NavGrid.nearest_open finds no cell centre within RECOVER_RANGE | An exact clear position may differ from a grid-centre result. Reproduce a thin-obstacle/cell-alignment case before changing collision-safe recovery. |
| A23 | P2 / confirmed guidance gap | OOB.guide_point always returns PILLAR_POS; Progression.local_target handles memories/NPC witnesses/Character File but not FIRST HITBOX | Once memories are gone, guidance does not select an eligible unread First Shape terminal. Add a progression-aware target without revealing or auto-counting the witness. No human confusion was measured. |
| A24 | P2 / observed backend diagnostic + confirmed eager probe | Narration._ready calls available() even with narration off; rendered Linux runs without a speech service log `Parameter synth is null` during voice enumeration | Probe optional speech lazily or with bounded capability refresh. Preserve delayed browser-voice discovery and fallback. This is distinct from a script error, audible Web failure or the ObjectDB shutdown warning. |
| A18 | P2 / confirmed documentation drift | CHARACTER_DIRECTION includes obsolete pixel-only assumptions and a proposed no-scarf Arin; CharacterArt header says only Rue/Mira despite six portraits; many pass docs present local statuses | Use live code and author-confirmed canon; keep historical notes but mark superseded portions. Do not remove Arin's implemented scarf because an old proposal says so. |

A strict bot run initially failed despite its five ending assertions passing:
the wrapper correctly rejected the A19 script error. Its purge-3 run also
recorded one Edge-erasure death and one 120-second scene watchdog stall. The
stall is retained as a separate diagnostic, not claimed fixed by the lifecycle
repair. A cutscene may be waiting for choice input that the movement helper
does not service; investigate before calling it a player softlock.

No new P0 blocker was reproduced in this bounded revision. That is not a
certificate that the remaining game has none.

## What changed now

`e69ab5c` changes just two presentation paths: the actual visible portrait now
advances its shared animation state; mouth activity uses the HUD's existing
recording/system-speech predicate. It includes two regressions that first
failed 0/2 on the baseline. A hidden-parent case guards against updating
invisible portraits. Reading progression, narration timing, saves, movement,
threat math, story and endings are unchanged.

`9117b18` repairs the independently reproduced detached-area refresh error.
It keeps the two-physics-frame collision-settling policy and clears pending
state when the old area leaves its tree. The initial full-suite run was
interrupted after this new runtime change; it is not counted as a completed
verification. A fresh final full suite and strict bot run validate the combined
code.

The new graphical tour renders the real PortraitView at controlled 0 and
150 ms phases. It is a staged, enlarged sample using CharacterArt.mira's
default palette, not a new Mira art direction or a human speech evaluation.
The future work is specified in [the detailed implementation prompt](PRESENTATION_GAMEPLAY_FOLLOWUP_PROMPT.md).

The clock/speech-status repairs are not phoneme lip-sync or a complete acting
system. HUD still alternates `frame` every 0.12 s while the illustrated face
also gates the mouth on its own 0.24 s phase. That duplicate phase ownership
is a source-supported animation risk; the next prompt explicitly requires
one mouth-phase owner and actual live-output checks. No real OS-TTS listening
or timing-quality claim is made by the controlled speech-predicate regression.


## Verification of this revision

Results are added only after the corresponding process completes.


| Check | Completed result | Limits |
|---|---|---|
| Baseline live-portrait regressions | 0 passed, 2 failed | Both presentation defects reproduced before repair |
| Baseline detached-area regression | 0 passed, 1 failed; script error | Detach occurs before first wait resumes, not immediate freeing |
| Earlier character/pacing/voice focused run | 33 passed, 0 failed, 99.7 s | Portrait repair only, before navigation repair |
| Final new/integration regressions | 8 passed, 0 failed, 1.8 s | Both runtime repairs |
| Final navigation compatibility group | 33 passed, 0 failed, 105.4 s | pass8, threat navigation, integration and new portraits |
| Rendered live portrait | 1 passed, 0 failed, 0.8 s | Actual mouth-region pixels differ between 0/150 ms; software OpenGL, no speech listening |

Runtime source for final checks/exports is `9117b18` (includes `e69ab5c`), before the `1c21266` merge.
The pre-integration full suite completed **467 passed, 0 failed, 1062.3 s**,
exit 0, with 467 unique cases and no script/parse errors. This run predates
the incoming PR #8 changes. Its shutdown resource warnings remain visible.
The post-merge 471-case run is recorded separately after completion. Raw evidence: [review/presentation-revision](review/presentation-revision/).

The rendered images show a controlled live-portrait sample:
[0 ms](review/presentation-revision/live_portrait_clock_000.png) and
[150 ms](review/presentation-revision/live_portrait_clock_150.png).
The difference was checked in the mouth region, not merely by comparing file
hashes. This does not certify acting quality or real-device TTS behavior.

Commands use isolated XDG config/cache/data directories and Godot 4.3:

```sh
GODOT=<Godot4.3> bash tests/run.sh --filter=presentation_revision,character_presentation,story_pacing,voice_over
GODOT=<Godot4.3> bash tests/run.sh --filter=integration_followup,presentation_revision
GODOT=<Godot4.3> bash tests/run.sh --filter=pass8,threat_navigation,integration_followup,presentation_revision
GODOT=<Godot4.3> bash tests/run.sh
GODOT=<Godot4.3> bash tests/run.sh --bots --speed=3
```

Graphics used Xvfb and Mesa llvmpipe. Browser checks use Playwright with a
system-Chromium launcher override; assertions are unchanged. Browser lifecycle
is not a full browser ending route. Local export hashes do not necessarily
match a later CI package with a different evidence commit.


| Pre-integration runtime check (`9117b18`) | Completed result | Limits |
|---|---|---|
| Strict bots | 5 passed, 0 failed, 241.1 s; wrapper exit 0, no script errors | Purge 3 needed 2 sessions with 1 Edge-erasure death; all routes recorded 0 stalls. Other routes recorded 0 deaths. This does not erase the initial failed run. |
| Browser lifecycle | Completed, exit 0, ALL WEB CHECKS PASSED | Fresh title/opening/input/save/quit/reopen; one final-runtime trial, not ten new trials |
| Browser audio | Passed, exit 0; no page errors or sampled clipping | Post-mix signal measurement, not listening or an OS-TTS performance test |
| Web / Windows / Linux exports | All exited 0 | Final runtime `9117b18` |
| Linux exported-game smoke | 240 headless frames, exit 0 | No Windows or real-GPU execution |
| Windows export integrity | AMD64 PE header and embedded pack verified; ZIP CRC passed | Unsigned export; no claim about SmartScreen or real execution |

[Build checksums](review/presentation-revision/build-hashes.json) identify the
local exports and ZIP. Earlier browser/audio checks on portrait-only `e69ab5c`
also passed but are not counted as additional final-runtime trials.

### Visual timing detail (source-derived, not hardware measurement)

At instability 1 and glitch intensity 1, Player's per-frame dropout probability
is 0.02. Its expected sampled frequency is therefore 0.6/1.2/2.4 dropout frames
per second at 30/60/120 FPS, each lasting one frame (33.3/16.7/8.3 ms). Average
frame share is similar; temporal texture is different. A09 proposes timed
events so the artistic intent can be compared consistently, not a claim of
measured fairness or performance gains.


### Capture harness correction

The first supplemental character-HUD render run had 7 passing assertions but
failed to save its requested PNGs. It is archived as a capture failure, not
successful visual evidence. After creating the directory, the real HUD rerun
completed 7/7 in 10.0 s and saved the
[Mira](review/presentation-revision/mira_dialogue_portrait.png) and
[Wren](review/presentation-revision/wren_dialogue_portrait.png) views.

The screenshot helper was then hardened separately from runtime code: it
creates relative/absolute output directories, checks nonempty image data and
records PNG-save errors as assertion failures. Its positive tour created a new
nested directory and passed 1/1; its negative tour targeted a regular file
inside the workspace and correctly failed 0/1 with process exit 1. Those two
expected outcomes are retained. The negative result is not a game regression.

Helper commit: `3ee11fc`. A fresh strict headless import/focused run after
this helper change completed 8/8 in 1.8 s, exit 0.

This helper-only change does not alter the headless suite's no-screenshot
branch or any exported gameplay resource. The live runtime remains `9117b18`.


### Incoming GitHub revision

While this review ran, `main` advanced from `da83f01` to `2644629` via PR #8.
Its runtime `2ffc036` preserves finale cursor ownership through common resume,
holds confrontation transitions behind story cards, removes completed-writing
objectives, adds gaze hysteresis/turn animation and steadies target brackets
under Reduce flashing. The code and four new regressions were reviewed.
[REVISION_OCT21.md](REVISION_OCT21.md) and
[NEXT_GAMEPLAY_VISUAL_PROMPT.md](NEXT_GAMEPLAY_VISUAL_PROMPT.md) remain preserved.
Our current prompt builds on them; A08 is now implemented upstream rather than
remaining work. The final combined runtime needs its own verification.


## Combined integration acceptance

Source: `1c21266c5ac34c07b09cf7004867003e8aa05a8e`. The merge preserves all four
new PR #8 regressions and our three new behavior regressions: 471 ordinary
cases in total. Only RELEASE_READINESS.md conflicted; its resolution retains
both histories and adds one authoritative combined status. No code conflict
was resolved by choosing an older implementation.

The strict post-merge full suite completed **471 passed, 0 failed, 1063.9 s**,
process exit 0. All 471 case names are unique, the completed summary is present,
and the log contains no script/parse errors or failed cases.
[Full combined log](review/presentation-revision/combined/full-suite.log).
Shutdown ObjectDB/resource diagnostics remain visible and unresolved.
Earlier green runs above do not substitute for this combined-runtime result.


| Post-merge check | Completed result | Limits |
|---|---|---|
| Strict ending bots | 5 passed, 0 failed, 247.5 s; exit 0; no script/parse errors | Escape: 4 recovered movement stalls, no deaths. Message: 1 Edge-erasure death, 2 sessions, 0 stalls. Purge-3 escape, purge-5 escape and Wren: 0 deaths/0 stalls. |
| Browser lifecycle | Completed, exit 0, ALL WEB CHECKS PASSED | One post-merge trial; not a full browser ending route |
| Browser audio output | Passed, exit 0; page errors empty, sampled clipping 0 | Signal measurement, not listening |
| Windows / Linux / Web export | All exit 0 | Same `1c21266` runtime |
| Linux smoke | 240 exported headless frames, exit 0 | No Windows execution or GPU claim |
| Windows PE/embedded pack/ZIP | Structure and CRC verified | Export integrity only |
| Rendered Edge + live portrait | 3 passed, 0 failed, 34.1 s | Xvfb/llvmpipe; Edge tour uses bench immunity and scripted positioning |

[Combined logs and build hashes](review/presentation-revision/combined/)
are separate from the pre-integration evidence. The graphical tour checks
confrontation phases and reduced effects, but its invulnerability means it
cannot establish survivability or fair difficulty. The
[drag-phase image](review/presentation-revision/combined/e6_dragging.png) and
[reduced-effects image](review/presentation-revision/combined/e9_reduced_effects.png)
were visually inspected. Full effects visibly fringe the ambient console;
critical first-reading comfort still needs human testing. Dialogue portraits
remain a separate clean UI route. No actor speech or listening was added.


## Pinned implementation entry points

These links target the reviewed combined commit, so later line shifts do not
change the evidence location.

| Concern | Source |
|---|---|
| Live portrait clock | [scripts/ui/portrait_view.gd:44](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/blob/1c21266c5ac34c07b09cf7004867003e8aa05a8e/scripts/ui/portrait_view.gd#L44) |
| Shared mouth activity | [scripts/ui/hud.gd:869](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/blob/1c21266c5ac34c07b09cf7004867003e8aa05a8e/scripts/ui/hud.gd#L869) |
| Unused external portrait route | [scripts/ui/character_art.gd:244](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/blob/1c21266c5ac34c07b09cf7004867003e8aa05a8e/scripts/ui/character_art.gd#L244) |
| Recorded-line pagination | [scripts/ui/hud.gd:902](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/blob/1c21266c5ac34c07b09cf7004867003e8aa05a8e/scripts/ui/hud.gd#L902) |
| Dialogue height | [scripts/ui/hud.gd:962](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/blob/1c21266c5ac34c07b09cf7004867003e8aa05a8e/scripts/ui/hud.gd#L962) |
| Ambient allowance | [scripts/ui/story_pacing.gd:79](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/blob/1c21266c5ac34c07b09cf7004867003e8aa05a8e/scripts/ui/story_pacing.gd#L79) |
| NPC pose driver | [scripts/world/npc.gd:227](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/blob/1c21266c5ac34c07b09cf7004867003e8aa05a8e/scripts/world/npc.gd#L227) |
| Turn and gaze | [scripts/world/pixel_character.gd:160](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/blob/1c21266c5ac34c07b09cf7004867003e8aa05a8e/scripts/world/pixel_character.gd#L160) |
| Player visual timing | [scripts/player/player.gd:205](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/blob/1c21266c5ac34c07b09cf7004867003e8aa05a8e/scripts/player/player.gd#L205) |
| Deferred area refresh | [scripts/world/areas/area.gd:152](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/blob/1c21266c5ac34c07b09cf7004867003e8aa05a8e/scripts/world/areas/area.gd#L152) |
| Bin safety boundary | [scripts/world/areas/recycle_bin.gd:166](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/blob/1c21266c5ac34c07b09cf7004867003e8aa05a8e/scripts/world/areas/recycle_bin.gd#L166) |
| Recovery gate | [scripts/owner/owner_avatar.gd:235](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/blob/1c21266c5ac34c07b09cf7004867003e8aa05a8e/scripts/owner/owner_avatar.gd#L235) |
| Guidance eligibility | [scripts/story/progression.gd:75](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/blob/1c21266c5ac34c07b09cf7004867003e8aa05a8e/scripts/story/progression.gd#L75) |
| OOB fallback | [scripts/world/areas/out_of_bounds.gd:105](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/blob/1c21266c5ac34c07b09cf7004867003e8aa05a8e/scripts/world/areas/out_of_bounds.gd#L105) |
| Preferences loading | [scripts/autoload/settings.gd:227](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/blob/1c21266c5ac34c07b09cf7004867003e8aa05a8e/scripts/autoload/settings.gd#L227) |


## Why adding portrait PNGs alone does not update dialogue

The reviewed live view and legacy texture route are separate:

```mermaid
flowchart TD
    W[World interaction] --> D[CharacterArt portrait data: identity, palette, expression]
    D --> H[HUD dialogue / cinematic]
    H --> V[PortraitView]
    V --> I[IllustratedCharacter drawing]
    V --> C[Animation clock: repaired here]
    L[Legacy CharacterArt.texture_for] --> P[External PNG when available]
    L --> R[Legacy raster fallback]
```

The live PortraitView has no call into the legacy texture route. A03 proposes
one explicit resolver/fallback contract before producing and importing a
large new cast. That integration must preserve restoration and fraying as
well as expressions. This diagram describes source structure, not a delivered
new asset system.


Narration's per-speaker speech rates are currently fixed in
`Narration.CHARACTER_SPEECH`; Settings.auto_speed changes reading allowance,
not the device's spoken rate. The next prompt separates those controls so a
slower auto-caption setting is not mistakenly presented as slower narration.
This is an accessibility improvement proposal; no human speech-rate discomfort
was measured in this environment.


## Publication and next step

The user explicitly requested commit, push and merge. All fetched remote heads
are ancestors of the combined tree; see the
[ancestry ledger](review/presentation-revision/combined-ancestry.txt).
The branch is `codex/presentation-functionality-audit`; after the completed
checks it is fast-forwarded to main without force. The subsequent documentation
commit changes no runtime/test code from the verified combined source.

- [Main code](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/tree/main)
- [Review branch](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/tree/codex/presentation-functionality-audit)
- [Updated detailed prompt](PRESENTATION_GAMEPLAY_FOLLOWUP_PROMPT.md)
- [Build workflow and Windows artifact](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/actions/workflows/build.yml)

Remote CI/deployment is a separate result: check the run on the published main
commit. Do not treat local export integrity as a ready public download or link
an older build as this revision. A local Windows ZIP was prepared and CRC-checked;
GitHub's workflow supplies the supported downloadable artifact after success.
The game remains a late prototype, with the explicitly deferred art/voice,
human testing, Windows execution and hardware work above.
