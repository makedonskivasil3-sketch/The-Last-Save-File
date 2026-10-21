# Implementation prompt: make The Last Save File feel deliberate

Use this as a complete assignment to an implementation agent. Read the current
repository before acting: the observations below describe the October 21, 2026
review starting from `da83f01`, with the accompanying revision in
`REVISION_OCT21.md`. Later commits may already have addressed individual items.
Do not repeat old repairs or treat a historical report as current test evidence.

## Your assignment and product goal

Act as the lead Godot engineer, gameplay designer, animation director, environment
artist and QA owner for **The Last Save File**. Improve this existing game through
finished, tested changes. Begin with a concise evidence ledger, implement a
coherent playable slice, then extend its proven visual and interaction language
across all seven areas. Do not stop after proposing a redesign.

The goal is a contemporary, authored narrative stealth adventure about a character
surviving in an abandoned save. Its strongest feature is the relationship between
Rue's recovered identity, the world's rules, the Owner's attention, and the
player's decisions. Preserve and clarify that relationship. The desired first
impression is controlled composition, readable characters, confident interaction
feedback and unsettling atmosphere. More decoration, blur, bloom, gradients or
particles alone will not achieve it. Keep the stylisation coherent; do not turn
this into a generic realistic horror game or a dashboard with a game behind it.

Use Godot 4.3, GDScript and the Compatibility renderer unless a demonstrated
requirement justifies a separate migration proposal. Preserve the 640×360 logical
gameplay coordinate system, input mapping, collision scale and existing saves.
Judge artwork both at native gameplay size and at enlarged inspection size.

## Establish the real baseline

1. Read `AGENTS.md` if present, `project.godot`, the current release-readiness
   introduction, `REVISION_OCT21.md`, `INTEGRATION_FOLLOWUP_RESULTS.md`,
   `OPENING_CAST_REVIEW.md`, `VISUAL_DIRECTION.md`, `GAMEPLAY_CONSISTENCY.md`,
   and the current test/build workflow. Historical sections remain historical.
2. Record branch, HEAD, remote main, working-tree changes and ancestry. Preserve
   unrelated edits. Every currently available remote head was already included
   in main at the starting review; do not merge older branches over newer code.
   Local `959d9cf`/`87c203a` are older implementations whose features evolved in
   main; compare behaviour rather than blindly cherry-picking them.
3. The previously advertised unpublished `a918b79` object and MapSurvey patch were
   unavailable. Search only accessible project material for recovery before
   duplicating work. If absent, state that explicitly. Current `MapView` is an
   overview diagram, not a geometry-derived local map.
4. Run the actual title → opening → boot → first playable room from a clean test
   profile. `start_session(true, true)` fabricates a preceding death to skip the
   boot; it does not establish a genuinely fresh first session. Use the real
   fresh-title regression as the starting reference.
5. Capture all areas and the cast on this baseline. Record settings, restoration
   state, route, timing, logical/window resolution, renderer and source hash.
   Static composition captures with threats held cannot establish pursuit clarity.
6. Classify each finding: reproduced functional defect, visual observation,
   usability hypothesis, performance hypothesis, or production gap. Attach an
   exact file/function and a reproducible trigger where applicable. Do not
   silently promote hypotheses into measured player findings.

## Preserve story and game rules

- Rue is the game character left running after her player, a girl, moved away.
  She is not that real girl transported into the game. Use she/her consistently.
- The Owner played Arin in Slot 1. The girl played Slot 2 for 41 hours; the Owner
  deleted that slot months after she moved. Preserve the existing chronology.
- Keep five memories, truth witnesses, the Character File and all existing
  ending prerequisites. Preserve escape, Rue, message, Wren, unseen and overwrite.
- Preserve the authored escape line: “the owner doesn't know this slot survived.
  not yet.” Do not rewrite it as a supposed continuity correction.
- Preserve fraying/shedding, its two-per-run cap, restoration and Pip's rules.
  Pip is not a source for shedding. Frayed Tobben must remain unvoiced.
- Preserve glitch prices, unlocks, hold thresholds, movement balance, purge,
  retry consequences and save compatibility unless a separate balance change
  has a documented reason and explicit scope.
- Fast writing before the Owner's hand arrives is earned counterplay. Keep it.
- Death and quitting have persistent consequences; six purge steps wipe the
  save under the current rule. Keep truthful warnings. An Edge checkpoint or
  different mobile-suspension policy is a design proposal, not an approved rule.
- No new maps, endings or glitch abilities in this pass. Build depth and clarity
  within the existing game.

## Priority 1: make every interaction trustworthy

Inspect `scripts/player/glitch_controller.gd`, `action_preview.gd` (locate its
current path), `player.gd`, `scripts/ui/hud.gd`, `scripts/world/world.gd`,
`slot_two.gd`, `scripts/owner/owner_cursor.gd` and `areas/the_edge.gd`.

The existing eligible-time charging and PHASE destination revalidation are
already implemented. Preserve them. A frame crossing HOLD_START or cooldown
must count only eligible time. A changed PHASE destination must cancel without
payment rather than silently selecting a different destination. The object
shown before commitment must remain the object acted upon, unless it becomes
invalid and produces a clear cancellation.

The October 21 revision adds terminal cursor ownership, story-held confrontation
transitions, completed-objective clearing and gaze hysteresis. Preserve these
regressions and extend coverage only for newly exposed failure paths.

Build a compact interaction matrix: tap, short hold, committed hold, release,
cancel, invalid target, target deletion, target movement, blocked landing,
dialogue hand-off, menu resume, focus loss and input-device change. For each,
specify shown action, target, cost, actual outcome and whether the Owner moves.
Use that matrix to find contradictions across keyboard, controller and touch.
Never make a costly action fire from the press that dismissed dialogue.

Improve action feedback at three stages: anticipation, commitment and result.
Give each a distinct visual shape and modest sound cue. Keep target brackets
and charge progress readable against light and dark scenery. Reduced flashing
must retain a stable indicator; do not replace important information with a
strobe or remove it when effects are disabled. Keep percentages anchored to a
fixed-width plate measured against the maximum caption, so 9→10 or 99→100 does
not cause distracting horizontal jumps. Respect large text and safe screen
margins. Avoid rebuilding themes or allocating new UI nodes every frame.

Make finale transitions explicit: idle → reach → drag → dropped/guarded →
completed, plus the fast-write branch. Generic pause/resume must not overwrite
state-specific cursor ownership. A completed slot must never advertise further
writing, spawn a new confrontation, restart a click or retain an obsolete goal.
Keep writing frozen during story holds but available during the intentional
PAUSE ability as the existing rule requires. Test real transitions as well as
directly constructed state combinations.

Do not fix difficulty by weakening every threat. Improve anticipation, causal
feedback and the player's ability to predict and recover from a mistake.

## Priority 2: give the cast weight, direction and personality

Inspect `scripts/world/pixel_character.gd`, `illustrated_character.gd`,
`npc.gd`, the Owner avatar, Player animation and shared portrait/opening renderers.
Keep one authoritative character definition and palette route. Do not create
separate copies for world sprites, portraits, title artwork and the opening.

The current shared renderer has recognisable colours and rear-view identity,
but much of the acting still comes from bobbing, squash and generic limbs.
Develop a restrained pose language at native scale before increasing detail.

1. **Locomotion:** distinguish planted contact, passing pose and weight transfer.
   Link gait progression to actual movement distance where practical, rather
   than letting feet cycle while a character is blocked. Preserve immediate
   control; do not add acceleration or input lag just to make animation smooth.
   Test slow motion, full speed, diagonal movement, sliding along walls,
   abrupt reversal, stop/start and escort catch-up.
2. **Facing:** moving companions face travel; dialogue deliberately faces the
   speaker; idle gaze has hysteresis. The new gaze turn must animate once,
   decay, and not restart continuously on repeated `look_at` calls. Check the
   transition between movement-facing and gaze-facing for repeated turn squash.
3. **Foot anchoring:** stop/turn deformation should pivot around the contact
   point. Shadows, hitboxes and feet must agree; do not scale collision with
   an expressive pose. Prevent slipping, body popping and sudden height changes.
4. **Rue:** keep the cowlick, scarf, coat pockets and stages of palette recovery.
   Missing Rue must retain a face void; do not accidentally draw skin/nose/ears
   through it. Give anticipation to a hold, a brief result pose after a glitch,
   and readable protected/afraid/relieved states without obscuring hazards.
5. **Arin:** preserve the red scarf, distinguish the Owner-controlled hero's
   threat posture from a welcoming NPC, and retain the non-speaking-body rule.
   Use a deliberate searching, noticing and pointing sequence with interruptible
   transitions. A detection tell must correspond to real detection state.
6. **Wren:** retain pigtails/ribbon and child proportions. Convey follow, waiting,
   shelter, fear and reassurance through a small number of clear poses.
7. **Mira, Tobben, Archivist:** differentiate posture and idle rhythm. Keep
   Tobben's bald scalp, moustache and correct rear apron ties; keep Mira's
   restricted/restored colours and the Archivist's reading posture readable.
8. **Pip:** preserve a distinct fox silhouette and guidance intent; avoid a
   mechanically identical hop/idle loop shared with every humanoid.
9. **Accessibility:** reduce high-frequency jitter when requested, preserve
   useful pose changes, and never imply safety merely through cosmetic calm.

Deliver a cast matrix: every character in front/back/left/right, idle, walk,
talking where valid, threat/protection and special story states. Include both
enlarged sheets and normal-size gameplay clips. A static sheet does not prove
animation quality. Keep before/after speed, camera and palette identical.

## Priority 3: rebuild map readability around actual decisions

Before editing each map, write its entry, required decision, optional reward,
threat, real cover, intended sightline and exit. Then change composition to
support those decisions. Do not fill every empty area with props: quiet space
can support navigation, anticipation and story. Avoid increasing traversal
distance without a meaningful choice or reward.

### Arin's room — the first five minutes

File: `scripts/world/areas/arins_room.gd`.

The current captures offer warm lighting and a clear cyan Rue, but notes,
save crystal, Mira, the partition and multiple HUD messages compete. Establish
an ordered composition: arrival → a safe experiment → suspicious partition →
exit. The initial useful action must be discoverable without an external guide.
Keep the profile-mismatch crystal as story feedback; do not imply that it saves
Rue's progress. Check whether the Slot 1/Arin header causes players to identify
the wrong controlled character. Clarify context without prematurely naming Rue
or spoiling the reveal. Use environmental framing and a short contextual cue,
not an explanatory wall of text. Preserve existing door/seam timing rules.

Verify zero previous sessions/deaths/quits, return after ordinary death, return
after an Edge death, and post-ending truce. Do not use the same capture to claim
all four states work. The opening film already exists: polish its comprehension,
skip/focus behaviour and input hand-off before proposing another video. Any new
opening beat must preserve the girl's anonymity and story chronology.

### Square — readable hub under pressure

File: `areas/village_square.gd`.

The current crossroad is geometrically legible but has several competing goals:
Wren, well, stall, Archive, house and north road. Use a distinct local silhouette
and material treatment for each route. Make north-road locked/open state legible.
Keep required navigation separate from optional curiosity through composition,
not a permanently flashing objective arrow. Clarify the useful sides of crates,
Arin's sightlines and Wren's state-dependent shelter. Do not suggest cover where
collision or visibility rules do not provide it. Retain safe cursor arrival and
its speed cap. Evaluate calm, HUNT, moved crates, deleted Wren and restored Wren.

### Archive — reading space and intentional discovery

File: `areas/archive.gd`.

Retain its quiet pacing. Distinguish readable record stands from shelf spines
and environmental decoration using silhouette, placement and a consistent
interaction accent. Improve the composition from west entry to Archivist/desk,
then to optional records and the east Bin exit. Avoid making all objects equally
bright. The Character File should receive stronger emphasis only when the
progression stage warrants it; do not expose its truth early. Check actual
walkable aisle width, approach positions, desk occlusion and text at large size.

### House — shelter that looks usable before the chime

File: `areas/arins_house.gd`.

Closets are actual traversable hiding recesses, not interaction buttons or solid
wardrobes. Make their open side, depth, threshold and sheltered result readable.
Use the same closet geometry for status, optional map markers and visuals.
Keep the existing four-second chime lead unless playtest evidence supports a
separate balance change. Provide a visual arrival warning equivalent to the
chime, preserve reading holds, and ensure a first visitor has a reachable
closet without prior knowledge. Check both closets, the dividing-wall doorway,
Arin's complete route, couch/controller discovery and Player 2's empty room.
Keep furniture outlines distinct from real colliders and current shelter.

### Recycle Bin — honest safety boundaries

File: `areas/recycle_bin.gd`.

Current protection uses `SYSTEM_FILES` plus `SHADOW`, while drawing and
`sheltered_at` duplicate the rectangle construction. Centralise the protected
geometry in a small shared helper before adding further markers. Draw a steady,
precise edge and directional cue for the usable shadow, with a stronger warning
state that remains readable with effects off. Avoid a vague glowing zone that
extends beyond the actual protection test. Preserve restore interruption and
the sweep's full crossed interval, including a long frame. Inspect every
boundary from both sides, first arrival, warning, sweep, partial restore,
restoration complete, deleted friends and existing route back to the Archive.
Do not call shelter discoverable until actual players find and use it.

### Out of Bounds — temporary ground with understandable timing

File: `areas/out_of_bounds.gd`, plus `scripts/story/progression.gd`.

Separate permanent anchors, present temporary chunks, warning chunks and absent
floor through shape/edge treatment as well as colour. Add a stable remaining-time
cue for temporary floor instead of depending on flicker. Keep the existing
`floor_at` tolerance and falling rule until a tested design change is approved.
Verify PHASE landings against live floor state. Check camera edges, return route
and falling recovery with Pip. Investigate the current guide-point fallback to
the return pillar: guidance must lead to an eligible unread First Shape witness
when that is the relevant objective, and back to the exit only afterwards.
Derive eligibility from existing progression rules, not a duplicate truth model.
No hint should reveal the witness text or count as reading it.

### Edge — an authored climax, not an unfinished editor

File: `areas/the_edge.gd`, `slot_two.gd` and finale handling in `world.gd`.

Keep its deliberately unloaded fiction, but distinguish that fiction from an
unpolished build. The visible TODO/missing-resource labels may support the theme;
they should be subordinate texture, never the main composition. Give walkable
ground, real blocks, void, erasure, cursor and Slot 2 distinct spatial identities.
Retain exact collision edges and body-safe corridors. Frame the initial Slot 2
and both drop positions. Verify the road-to-slot route and all guard positions
using actual clearance, not only centre-point distances. Capture every phase
under normal effects, reduced flashing and effects off. Preserve earned fast
writing and make its clean result legible. Keep retries efficient under the
existing seam rule; do not silently introduce a checkpoint.

## Priority 4: a useful map without spoilers

`scripts/ui/map_view.gd` currently provides an area topology diagram. Keep that
overview; Bin is already correctly east of Archive. Add a separate compact local
survey only after defining its data contract and testing representative rooms.

- Derive solids and doors from actual active shapes/current state; include
  moved crates and disabled collision. Do not paint an approximate second level.
- Represent bounds, player position, exits and permanent/temporary floor clearly.
  A visually open but unloaded/solid door must not be shown as traversable.
- Discover landmarks by approach; record only knowledge the player earned.
  Opening a map must not award memories, read records, complete witnesses or
  reveal undiscovered truth, character identities or enemy locations.
- Distinguish cover, readable records and exits with shape and text legend.
  Mark a closet or Bin shadow only according to real shelter rules. Do not
  advertise a generic shelf as safe merely because it looks substantial.
- Preserve current overview memory disclosure unless a separate spoiler-policy
  change is explicitly chosen; do not silently alter progression information.
- Capture the map when opened and update only as needed. Avoid per-frame scene
  traversal/physics scans, especially while the game is paused.
- Verify all seven areas, non-origin bounds, normal/large text, changed geometry,
  present/absent temporary floor and undiscovered states. Keep focus/navigation
  usable with controller and touch. Clearly label overview versus local plan.

## Priority 5: unify the modern visual language and HUD

Use a small role-based palette: environment/materials, interaction, safety,
threat and narrative emphasis. Colour alone must not carry a lethal distinction.
Define outline weights, corner treatment, light falloff and typography in shared
helpers. Do not solve inconsistencies by putting identical glowing frames around
every prop. Reduce repeated floor detail where it competes with small figures.

Give world objects a consistent perspective, wall depth and contact shadow.
Remove seams between painted backdrop and dynamic props. Check y-ordering near
shelves, crates, the well, doorways and tree canopies; essential silhouettes must
not disappear. Keep the player recognisable through all five palette stages,
borrowed colours, maximum instability, bright light and dark floor.

Use one primary reading task at a time: choices/cinematics/dialogue, urgent
danger, contextual action, objective, ambient console. Preserve the existing
priority and hidden-objective reading-time behaviour. Examine real overlap
rectangles for the slot header, objective/hint, banner/warning, Owner meter,
prompt, subtitles and touch controls. Do not solve overlap by making text tiny.
Use wrapping, measured plates, bounded placement and transient suppression.
Keep pause history and replay available; the historical “no backlog” report is
obsolete for the current code. Update stale current-status claims where found.

Capture title, actual fresh room, every map and finale at normal and large text,
effects Off/Light/Full, restored/missing Rue, keyboard/controller/touch prompts,
and at supported aspect ratios. Validate clipping and focus, not just colours.

## Priority 6: sound, voices and emotional rhythm

Read the current audio diagnosis, voice bible, manifest and production/licensing
documents. Browser bus routing and baked themes already exist. Preserve the
browser audio-output regression and all volume settings. Do not reintroduce
one-by-one web audio bus creation. Never raise a deliberately muted bus.

Distinguish procedural character blips, optional system TTS and recorded dramatic
performances. A manifest of dialogue IDs is not a delivered voice cast. Audit
which files actually ship before promising voices. Use only owned or properly
licensed performances; do not imitate an identifiable performer without rights.
Ensure missing recordings fall back cleanly without blocking progression.

Create an event-to-sound matrix for footsteps/materials, interaction, hold,
cancellation, glitch commitment, danger, shelter, restore, memory and finale.
Prioritise threats over ambience, and speech over music when speech is active.
Keep transitions free of clicks and competing sustained tones. Inspect title,
film, room, quiet Archive, HUNT, Bin sweep and the complete finale on headphones
and laptop/phone speakers. Record device and listener observations. Signal/RMS
checks prove signal, not dramatic quality, intelligibility or pleasant mixing.
Investigate remaining shutdown ObjectDB/audio retention instead of suppressing
warnings or accepting a clean title-only probe as a universal fix.

## Validation, measurement and acceptance

Make a failing regression before fixing each substantive reproduced defect.
Prefer tests of player outcomes/state transitions to snapshots of the exact
implementation. Keep the strict import/script-error/completed-summary wrapper.
An exit-zero process without a nonempty completed summary is not a passing run.
Do not modify expectations merely to make a broken game green.

Run focused regressions, then the complete headless suite and all five existing
exact-ending bots on the final runtime. Include escape/message, high purge and
Wren recovery. Record deaths, stalls and retries as well as ending. Exercise all
six endings through appropriate regression coverage; five bots do not prove six
human-playable routes. Test malformed save metadata, settings persistence,
normal/large text, real first-run opening, focus loss, menu resume and controller
focus. Export Web/Linux/Windows and distinguish export from native execution.

Run the browser lifecycle and audio-output checks on the newly exported build.
For repeated lifecycle trials retain every result, including intermittent
failures; do not silently rerun until green. Record build hashes and page errors.
Confirm final CI and deployment state from the actual commit. Do not call a
previous build the current deliverable or merge around a failed required check.

For performance use a real GPU when available. Record CPU/GPU, OS, driver,
renderer, resolution, refresh rate, effects settings, build hash and workload.
Measure warm steady-state and transitions separately: Square HUNT with moved
crates, Edge reach/drag/guard, Bin sweep/restoration, maximum instability, map
open and dialogue/voice transitions. Report median/p95/p99 frame time and hitch
counts over repeatable samples, plus CPU/GPU bottleneck evidence and allocations.
60 FPS corresponds to a 16.67 ms frame budget; make any hardware target explicit.
Do not describe llvmpipe, SwiftShader, headless or simulated-frame results as
real-GPU performance. Optimise measured bottlenecks without reducing readability.

Run 3–5 uncoached new-player sessions on the reviewed build when humans are
available. Obtain consent before recording. Timestamp first deliberate action,
first interaction/hold/shelter/exit, missed shelves/closets, first understood
failure, map use and return-route confusion. Ask what they expected and what
caused the outcome. Compare intro watched/skipped with the limits of the small
sample stated. Use this as qualitative evidence, not a statistically meaningful
conversion claim. Do not invent participants or results. Pending sessions remain
pending if you cannot recruit players from the execution environment.

Propose measurable usability goals before testing, such as an understood first
action within a minute and a first shelter reached after its warning, but label
them targets until observed. Do not weaken consequences simply to satisfy a
target. Use observed confusion to decide whether a shelf/closet needs relocation,
lighting, silhouette, a cue or a rule explanation.

## Delivery and sequencing

Work in small coherent commits: interaction/state reliability; opening and one
map as the validated visual slice; cast/animation; remaining maps; survey; audio
and platform validation. Do not announce every item complete after one slice.
Carry out all work possible within the authorised scope and report blockers
precisely. If a required human/device/asset-rights dependency is unavailable,
finish the independent code and provide the exact remaining procedure.

Deliver:

1. A concise assessment and a finding table with severity, category, reproduction,
   file/function, player impact, fix, evidence and remaining limits.
2. The implemented code and committed assets, with source hashes and no unrelated
   work overwritten. When publication/merge is authorised, push normally and
   merge only the reviewed branch after its required checks; never force history.
3. Matched before/after captures, short animation/gameplay clips and seven-area
   route/cover notes. Clearly label staged automation versus observed human play.
4. Exact test summaries, bot results, export/browser status and performance data
   with raw evidence. Explain incomplete checks rather than burying them.
5. Updated current release-readiness notes with separate Implemented, Automated,
   Visually inspected, Human observed, Hardware measured and Pending columns.
6. A prioritised next backlog. Keep speculative features separate from reproduced
   defects. State honestly whether this is still a late prototype or whether new
   evidence justifies a stronger readiness claim.

The success criterion is that the player understands a situation, makes a
meaningful decision, receives a truthful response, and wants to see what Rue
does next. Every visual and technical change should support that experience.
