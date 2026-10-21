# Follow-up implementation prompt: animation, art, play and atmosphere

Copy the prompt below into Claude/Codex with access to this repository.
It describes the **next implementation pass**, not work already completed.
Start from the latest fetched `main`; the review baseline was `da83f01` and
the two live-portrait repairs are in `e69ab5c`; detached-area navigation
refresh cancellation is repaired in `9117b18`. Incoming main `2644629` adds
PR #8 / `2ffc036` finale/gaze fixes; retain those too. Read the audit and verification
record before repeating work. Targets below are proposed acceptance criteria,
not claims that players have already met them.

---

You are the lead Godot gameplay programmer, animation director, technical
artist, narrative designer, audio implementer and QA lead for **The Last Save
File**. Deliver a coherent, playable improvement with evidence. Your standard
is a memorable small game with clear rules, expressive people and deliberate
tension. Avoid a larger feature list that weakens the existing experience.

## 1. Establish the truth before editing

1. Fetch GitHub and inspect `main`, `codex/presentation-functionality-audit`,
   `codex/integration-follow-up`, `game-presentation-polish`, and any newer
   remote heads. Record exact hashes, dirty files and ancestry. Preserve work
   already integrated. Do not reset or force-push someone else's changes.
2. Read any applicable AGENTS.md, project.godot, export_presets.cfg,
   tests/run.sh, tests/run_tests.gd and the active GitHub workflow.
3. Read docs/PRESENTATION_FUNCTIONALITY_AUDIT.md,
   docs/INTEGRATION_FOLLOWUP_RESULTS.md, docs/RELEASE_READINESS.md,
   docs/NARRATIVE_DECISIONS.md, docs/DARK_TRUTH_DESIGN.md,
   docs/VISUAL_DIRECTION.md, docs/STORY_PACING.md, docs/ASSET_PRODUCTION.md,
   docs/VOICE_BIBLE.md, docs/REVISION_OCT21.md,
   docs/NEXT_GAMEPLAY_VISUAL_PROMPT.md and relevant tests. Historical proposals
   are not canon.
   Some comments reference a nonexistent VOICE_PRODUCTION.md; locate the real
   production instructions rather than pretending the linked file exists.
4. Inspect the actual runtime paths, not only screenshots or documentation:
   - scripts/world/illustrated_character.gd and pixel_character.gd;
   - scripts/ui/portrait_view.gd, character_art.gd, hud.gd, line_pacer.gd,
     story_pacing.gd, map_view.gd, touch_controls.gd;
   - scripts/player/player.gd, glitch_controller.gd, action_preview.gd;
   - scripts/world/world.gd, npc.gd, companion.gd, drag_prop.gd and areas/;
   - scripts/owner/owner_avatar.gd, owner_cursor.gd, owner_moves.gd,
     owner_director.gd, nav_grid.gd and erasure.gd;
   - scripts/audio/, scripts/autoload/settings.gd, owner_memory.gd,
     safe_file.gd and sfx.gd; shaders/save_corruption.gdshader.
5. Produce a short ledger: finding, file/function, trigger, evidence type,
   player consequence, severity, proposed repair and acceptance check.
   Distinguish reproduced bugs, source-confirmed integration gaps, measurement
   gaps and subjective proposals. Do not label a hypothesis as a tested bug.

**Already done — preserve rather than duplicate:** manual advancement by
 default; safe reveal/advance separation; reading-time scaling; warning strip;
 history and subtitle settings; backed charge labels; eligible charge timing;
 PHASE landing validation; stable interaction targets; escort travel facing;
 shared occupancy/versioned navigation; final crate movement flush; numeric
 retry metadata validation; correct overview Bin direction; Arin scarf,
 Rue rear cowlick and Tobben rear apron ties; live portrait clock and system
 speech mouth predicate (`e69ab5c`, test_presentation_revision.gd); safe
 cancellation between the two deferred physics waits (`9117b18`,
 test_pending_refresh_can_detach_on_the_first_physics_frame). Also preserve
 PR #8 finale cursor ownership through resume, held confrontation transitions,
 completed-objective clearing, gaze turn/hysteresis and steady reduced-flashing
 brackets (`2ffc036`, test_revision_oct21.gd).

## 2. Non-negotiable identity and rules

- Rue is the character left running from another person's play, not the real
  girl physically transported into the console. Preserve author-confirmed
  identity, pronouns, relationships and the revelation through the CHARACTER FILE.
- Preserve the five memories, six endings, persistent Owner learning, purge,
  deleted/restored NPCs, fraying/returned pieces, Pip and the existing truth route.
- Ordinary escape must remain available without learning the full truth.
  Preserve its authored line: “the owner doesn't know this slot survived.
  not yet.” Do not treat this as an unsolicited continuity correction.
- Keep the Owner's off-screen human ambiguity. No generic demon, evil AI reveal,
  jump-scare spam, collectible grind, combat system or new currency.
- Preserve quit consequences and clear warnings. Do not add checkpoints,
  delete persistence or quietly soften purge to solve onboarding confusion.
- Preserve earned completion of Slot 2 before the Owner's hand reaches it.
- Keep Godot 4.3 Compatibility and the 640×360 logical world with existing
  feet anchors, colliders and speeds unless a separately evidenced change
  is necessary and explicitly reported.
- No multiplayer, extra endings, extra zones, procedural quest generator,
  daily rewards or monetization in this pass.

## 3. Work in completed slices

Write an implementation plan with dependencies, then finish **Milestone A**
first: live asset loading, subtitle/voice safety, and coherent speaking/pose
state. Verify and commit it before expanding. Milestone B is one polished
first-room-to-square experience. Milestone C extends validated patterns.
Do not attempt every proposal at once. Keep a clear implemented/deferred list.

### Milestone A1 — make new character artwork actually reach the screen

**Problem:** CharacterArt.texture_for supports external PNGs, but the displayed
PortraitView draws a newly built IllustratedCharacter directly. Existing
CharacterArt.image tests can pass while the live view ignores new artwork.

- Choose one explicit presentation resolver used by the actual dialogue and
  cinematic controls. Support external approved assets and the existing
  procedural fallback. Retain one source of character identity/palette data.
- Define a small Resource/schema for `who`, asset version, expression,
  frame/animation, normalized crop/anchor, size and provenance. A full data
  migration is unnecessary if a simpler resolver suffices.
- Provide six character identities: Rue, Arin, Mira, Wren, Tobben and the
  Archivist. Pip remains a creature; do not give Pip a human stand-in.
- Handle missing/corrupt/wrong-sized assets without a crash or unrelated face.
  Resolve once on identity/state changes, not by repeatedly loading files in draw.
- Preserve partial restoration and borrowed/frayed palettes. A fully restored
  PNG must not overwrite Rue's missing face or show Wren's lost ribbon.
  If an external set lacks that variant, choose the documented procedural
  fallback; do not apply arbitrary recolouring to finished skin/hair artwork.
- Keep a stable crop and face scale across expressions. No bust jumps when
  changing from concerned to afraid. Text must not move when only the mood changes.
- Add a meaningful test that installs a temporary approved-format fixture,
  opens the actual PortraitView/HUD route, and proves the fixture was used.
  Test missing assets and restored/frayed fallback, not merely a filename helper.
- Remove or mark superseded loader claims/comments after the real route works.

### Milestone A2 — never let performance outrun comprehension

Keep manual advance as the default. **Do not fix the old narration complaint
by simply increasing a global delay.** Audit each text delivery route.

Create a route matrix for dialogue, boot/opening, memories, truth reveal,
ending exchange, epilogue, ambient self/Owner lines, warnings, objectives and
history replay. Record who owns reveal, reading allowance, voice lifetime,
advance, skip, interruption, pause and persistence.

Required behavior:

1. One press reveals the complete current page; a separate later press
   advances. The input that opens a box must not consume its first line.
2. Auto advances only after full reveal, reading allowance, the current voice
   finishing and the selected post-voice delay. Pause and focus-loss preserve
   remaining time. Settings changes take effect without losing a story line.
3. Urgent danger warnings bypass ambient backlog and remain visible in their
   own channel. Essential story is not silently discarded to make room.
4. Ambient lines currently receive at most 6 seconds before another starts,
   and an Owner line can shorten the current pause to 0.8 seconds. Classify
   essential story separately from telemetry. Either give essential text its
   full safe allowance or route it through the existing deliberate story UI.
   Do not automatically freeze every ambient line: that would change survival
   rules. Use protected story beats where appropriate and retain warnings.
5. Fix the latent recording/pagination conflict: recorded lines currently
   bypass Hud.paginate's splitting. Implement caption pages/cues against one
   audio playback, or another explicit bounded layout that preserves speech.
   Never replay the whole take on every caption page or cut off its last words.
6. Persist/history-log each source line coherently: no duplicated journal
   events or truth pieces just because one line has several caption pages.
7. In manual mode, advancing may deliberately cut current speech; stop the
   old voice and prevent overlap. In auto mode, do not cut it to meet a timer.
8. Handle missing take, invalid cue, TTS start failure, TTS cancellation,
   recording completion, silent volumes and scene exit. Progression must work
   without any installed system voice or external media.
9. Keep speaker labels, readable backing and History accessible. History is
   a recovery tool, not an excuse for unreadable first delivery.

Test a 180+ character line, a 300+ character voiced fixture, slow/normal/fast/
instant reveal, manual/auto, all subtitle sizes, large UI text, maximal combined
text scaling, 16:9 and 4:3 windows, reduced flashing and missing voices.
Check measured control bounds against viewport safe areas. Use synthetic
audio fixtures to test timing, clearly labelled as fixtures, not new acting.

### Milestone A3 — one coherent animation state per character

Retain the shared renderer and its palette semantics. Introduce a small
presentation state resolver if needed; avoid a rewrite of all game logic.

Use an explicit priority order, for example:
`deleted/dissolving > frozen > restricted > targeted/charging > speaking >
locomotion > contextual idle`. Explain exceptions such as a talking escort
stopping or looking at Rue. States must be driven by actual gameplay events.

| Character | Required readable states | Distinctive detail to preserve |
|---|---|---|
| Rue | idle, walk, turn, shelter, targeted, charge, commit/cancel, restore, dissolve | cowlick, scarf, coat; incomplete face/palette tracks memories |
| Arin avatar | patrol, corner look, decoy pursuit, detection/point, stun | blue tunic and existing red scarf; static hostile pointing, no greeting wave |
| Real Arin remnant | restricted/mute, look | no mouth speech or misleading threat cone |
| Mira | anxious idle, speak, escort, pin note, restricted/reset | hair silhouette, warm dress, eager versus reset expression |
| Wren | idle hop, shelter, speak, escort, brave/fearful, restricted/deleted | shortest silhouette; ribbon disappearance when frayed |
| Tobben | greeting, speak, report aftermath, mute/writing, restricted | bald crown, moustache, front apron versus rear ties |
| Archivist | read, look up, speak, turn | tallest robe/beard; book occludes correctly |
| Pip | sleep, follow/trot, sit, guide, warn | fox shape and tail/ear language, not a human exclamation clone |

Specific repairs/prototypes:

- Drive world NPC mouth motion from the active line's reveal/voice, not the
  fact that the entire conversation remains open. Maintain mute/written rules.
- Keep the new live-portrait clock and voice_busy fixes. Test the actual live
  renderer; checking only frame names or legacy CharacterArt.image is insufficient.
- Make one system own mouth phase. HUD frame toggles and renderer time gates
  currently both affect it; avoid a second rhythm that creates irregular flaps.
  Coarse talking animation is acceptable; do not call it phoneme lip-sync.
- Reuse existing expressions and author small per-line mappings for Tobben/
  Archivist where text justifies them. Do not give every sentence a random mood.
- Stop normal greeting/hop loops when RESTRICTED; keep intentional reset behavior
  distinct. Put the book behind the body when appropriate and close/lower it
  during speech. Preserve freezing exactly mid-pose where intended.
- Preserve the `2ffc036` gaze turn and direction hysteresis. Test it with the
  advancing live portrait clock and movement/gaze hand-off; do not restart
  turn squash on repeated look_at calls. Keep eyes/head offset bounded while
  feet/body continue to face travel.
- Prototype gait based on travelled distance, or retain current cadence if
  measured alignment is better. Do not change speed to make the walk look nicer.
  Check low analog input, diagonals, wall sliding, immediate reversal and stop.
- Replace frame-based visual random events with rates/holds in seconds.
  Use a stable seeded presentation RNG where testing requires it; never let
  a new draw-time random call perturb Owner decisions or persistent outcomes.
- Review safe timings: 0.12 s turn and 0.18 s stop settle already exist.
  Treat 80–150 ms anticipation and 120–220 ms follow-through as prototype
  ranges, not compulsory delays on player input. The action must stay responsive.
- Charge effects may anticipate the hold, but must not imply success before
  commit. Cancellation and insufficient cost/invalid landing need distinct feedback.

Acceptance: side-by-side real gameplay plus a labelled state/direction contact
sheet at 1× and 2× scale; no foot-anchor jumps, back-facing facial features,
front-only props on backs, moving collision boxes, silhouette swapping or
threat cue lost with reduced effects. Simulate 30/60/120 FPS for event timing;
measure real hardware separately. Log which states are staged and which were
reached through normal play.

## 4. Art direction and level readability

The existing illustrated figures, dark outlined shapes, warm domestic spaces,
cold save-system spaces and hostile Owner colour form the baseline. A complete
style replacement is not justified merely because more elaborate assets are
available. Improve hierarchy and acting before adding density.

Build a one-page art specification: silhouette, outline width, relative head/
body proportions, palette roles, materials, light direction, UI typography,
portrait crop, allowable corruption and asset scale/import settings.
Use existing Inter/DejaVu assets and their licences consistently.

For each scene, prioritize: immediate danger → player/interaction → destination
→ landmark → optional story detail → decoration. Do not use colour alone.
Give danger a shape/motion/audio cue and shelter a clear environmental reason.
A bright decoration should not outshine the required first interaction.

| Area | Emotional role | Concrete review target |
|---|---|---|
| Arin's room | familiarity becoming intrusion | desk/door/seam/readable affordance hierarchy; rug/shaft of light should support the route; first memory remains discoverable |
| Village square | public exposure | patrol/cone versus friendly notice; stall/well silhouettes and route signs; Wren's shelter distinguishable without a flashing billboard |
| Archive | relief and investigation | desk/file versus decorative shelves; breathing room and visible east exit to Bin |
| Arin's house | domestic warmth beside absence | closets read as shelter; TV light supports room layout; empty player-two space carries history |
| Recycle Bin | system coldness and loss | navigable lane, active sweep, file shadows and restored people read distinctly |
| Out of Bounds | unfinished vertigo and trust | anchors versus failing floor at a glance; Pip's ledge and crossing warning remain visible with effects reduced |
| Edge | collapse and chosen action | distinguish inactive corruption from killing cells; keep Rue, Slot 2 and moving cursor legible through active confrontation |

- Capture each area in calm, warning and actual danger states. A staged empty
  overview does not validate a chase. Inspect with shader full/light/off,
  reduced flashing, large text, missing/restored Rue and colour vision simulations.
- Light physical materials consistently. Furniture fronts imply collision;
  flat paper/rugs do not. Draw decorative depth from the same geometry used
  for solids where possible; do not paint a safe route through a collider.
- Recycle Bin protection is constructed twice from SYSTEM_FILES/SHADOW. Share
  one geometry helper before drawing clearer shelter edges; test exact bounds
  during the sweep, including a long frame. A glow must never promise safety
  outside the real rectangle.
- House closets need a visible open threshold and depth. Keep the existing
  four-second visit chime and provide a readable visual counterpart; verify
  both recesses, Arin's doorway route and the actual sheltered status.
- In Out of Bounds, distinguish permanent, temporary, warning and missing
  floor without flicker alone. Check Progression.local_target plus guide_point
  against an eligible unread FIRST HITBOX terminal: the current pillar fallback
  should not guide past the needed witness. Do not auto-count it as read.
- Keep UI text/critical cues out of destructive full-screen effects. No heavy
  grain, chromatic fringes or bloom over subtitles to manufacture atmosphere.
- Preserve canopies becoming translucent above characters.
- For imported art, use transparent edges, consistent pivots, atlas padding,
  intended filtering and scaling. Inspect exported Web and native builds;
  editor appearance alone is insufficient.
- Only add a local map if navigation observation supports it. The existing
  overview is a graph, not a room plan. A future floor plan must derive from
  real bounds/solids/exits, reveal explored portions only and mark discovered
  cover/landmarks without revealing the truth route. Do not pretend MapSurvey exists.

## 5. Gameplay feel and the first ten minutes

Make the loop **observe → understand a risk → choose → act → see a consequence
→ learn one thing**. Repeat engagement should come from mastery, relationships
and unanswered questions, never pressure schedules or busywork.

Proposed first-session beats are observation targets, not forced time locks:

- Opening/first action: explain how to advance/skip, move and interact through
  a clear local affordance. Make deliberate holding distinguishable from tapping.
- Room: let the player discover the false welcome, locked door response,
  seam/PHASE and first memory without an unrelated NPC stealing the target.
- Square: demonstrate a readable patrol/warning and shelter with room to react.
  The player should infer a safe next step without revealing all Owner rules.
- Archive/next exploration: one coherent destination, a useful character and
  one new question. Optional lore remains optional; Pip/Progression/journal
  hints must agree with actual state.

Measure rather than invent: time to first movement, intentional interaction,
first successful hold, room exit, first shelter, first death, next understood
objective and voluntary story reread. Record why the player stopped.

Review tap/hold arbitration, target hysteresis, range boundaries, cost preview,
cancellation, PHASE landing, pause/focus transitions and analog/touch behavior.
Keep the prompt, target marker, cost and actual committed action consistent.
If two candidates are equally plausible, retain the stable target or add a
clear directional rule. Never solve ambiguity with unpredictable auto-selection.

For every lethal hazard document: warning trigger → visual/audio onset →
control availability → time/distance to safety → lethal condition. Test it
at fresh, mid and high purge, with low effects and muted music. The player
must have a real available response; a warning that arrives after a decision
is already irreversible is not fair. Preserve previously earned actions.

Do not duplicate existing nav fixes. Exercise blockers opening/closing,
dragged crates, changing routes, decoys behind solids, an unreachable goal,
an embedded spawn and scene exit during deferred refresh. Maintain shared
grid versions, body-safe travel and bounded recovery. Investigate whether a
new geometry version should reset a recovery budget; decide from a failing
scenario, not a speculative rewrite. Also test exact body-clear positions
versus the nearest grid-cell-centre gate in OwnerAvatar._recover; a nearby
clear sliver and an open cell centre are different conditions.

Check escort corners, thresholds/doors, catching up, player reversal,
PHASE-separated followers, frozen/deleted followers and the exact Wren ending.
Followers must not teleport through solids to hide a navigation error.

Retain the observed purge-3 diagnostic: the initial revision bot died once
at Edge and later logged a 120-second scene stall before completing escape.
Trace whether the movement helper is waiting on a choice it does not answer,
a real story coroutine is blocked, or another cause. Do not increase the
watchdog or erase the stall counter to manufacture a clean run. The detached-
area script error from that same run was separately reproduced and repaired
in `9117b18`; do not assume that repair resolves the scene wait.

Keep retry costs and persistent consequences understandable. Preserve already
seen story-skip behavior and the Edge retry seam. Do not make a player reread
a long unchanged scene after every death just to reach one new action.

## 6. Story, characters and small details

Trace every memory, witness line and character-file prerequisite. Preserve
optional ordinary escape and reveal order. Rewrite a confusing line only
with its trigger/context documented; regenerate stable voice IDs when text
changes so old speech never plays under new captions.

Give each major character one observable desire, one fear and one action
that supports the existing story. Prefer a changed glance, missing ribbon,
shorter answer or altered prop to an added exposition paragraph.

Maintain a small detail ledger with `trigger → observable response → persistence
→ repeat rule → test`. Examples to evaluate, not automatically add:
- Mira's pinning changes the real board and later response coherently;
- Tobben's posture changes after reporting Rue, without announcing a spoiler;
- Wren's familiar hop becomes stillness while sheltering somebody;
- Pip's ear/tail warning identifies danger direction without a text spam loop;
- recovered colour returns on sprite, portrait and title according to the same rule;
- an NPC recalls one meaningful prior action once at the appropriate time;
- room audio/light acknowledges an exit or restoration without obscuring a warning.

No detail should reveal unreached content, contradict a deleted NPC or trigger
on every frame. Limit repeated barks, use cooldowns and keep silence meaningful.
Protect the Owner's tired, conflicted human voice from melodramatic villain lines.

## 7. Music, sound and voice production

Inventory what actually ships: baked/procedural music, SFX, blips, optional OS
TTS and any approved media. Mark absent content honestly. Historic generated
pilot takes are not assumed available, listened to or commercially licensed.

- Retain memory-linked theme layers, current ducking and spatial threat cues.
  Check transitions for clicks, stale loops, sudden gain jumps and competing rhythms.
- Give calm, suspicion, pursuit and aftermath distinct intensity through
  arrangement, density and silence. Do not simply play a louder drone forever.
- Spatially distinguish Arin's feet/cursor from Rue. Check mono downmix,
  headphones, speakers and muted music. Essential warnings stay audible on SFX.
- Use one spoken line at a time; cancel on scene exit and pause/resume correctly.
  Test recorded voice, TTS and no voice. Never describe blips as full narration.
- Evaluate a small actual voice pilot before producing hundreds of lines:
  one quiet memory, one intimate dialogue, one urgent line and one three-person
  exchange. Use stable manifest IDs, exact captions and contextual direction.
- If available, ElevenLabs or another licensed voice tool can produce candidate
  takes; a human performer is equally valid. Check current rights, subscription,
  voice consent and cost before generation/shipping. Do not buy plans or upload
  private material as part of routine implementation. No imitation of a named actor.
- Existing `ASSET_PRODUCTION.md` provides the production baseline; provisionally
  target dialogue around −18 LUFS integrated and ≤−1.5 dBTP, then actually
  listen in the game mix. Do not force a very short whisper to a meter reading
  that destroys its character. Log measured and listening judgments separately.
- Keep speaker styles consistent: Rue intimate/uncertain; Owner restrained and
  tired; Mira warm/anxious; Wren small/earnest/brave; Tobben measured/guilty;
  Archivist dry/papery. Arin's real remnant is mute; Pip is a fox.
- Deliver raw takes, approved masters, edit/cue metadata and provenance separately.
  Check pronunciation, omitted words, emotional contour and artificial artefacts.
  Text or waveform analysis cannot substitute for listening.

If no approved voice tool/access is available, complete the resolver, timing,
manifest and tests with labelled fixtures and report the real production block.
Do not silently ship unlicensed placeholders or claim voices were produced.

## 8. Accessibility, performance and engineering discipline

- Preserve manual/auto options, speaker labels, subtitle backing/size, large
  UI text, reduced flashing, shake control, effects quality and audio buses.
- Critical information must remain available with effects and music off.
  Reduced flashing must still communicate targeting, charging and lethal cells.
- Review keyboard and gamepad focus through title/settings/history/choices;
  prevent stuck actions after pause, alt-tab, device change or touch release.
  Runtime rebinding/localization are separate scoped additions if supported
  by observation; do not claim they already exist.
- Test corrupt preference types in an isolated settings file; recover per field
  with valid defaults if a defect is reproduced. Never overwrite a real save
  for tests, and keep SafeFile's last-good-copy behavior intact.
- Profile the rendered exported game before optimizing. Record OS, renderer,
  resolution, hardware, effects settings, scenario length and source hash.
  Report p50/p95/p99 frame time, worst transition, draw calls, memory and object
  growth over repeated area changes. A headless CPU test is not GPU evidence.
- A provisional 60 Hz target is p95 ≤16.7 ms on a named target device, not a
  universal claim. If the device cannot meet it, report the measurement and
  choose a quality fallback. Inspect pacing spikes as well as average FPS.
- Cache immutable drawing resources only where profiling justifies it. Avoid
  changing scene ownership or pooling everything to chase an unmeasured cost.
- Investigate shutdown ObjectDB/resource warnings separately: minimal title,
  portrait-only, active speech, repeated areas, pause and exit. Identify the
  retaining owner/callback. Do not suppress logs or weaken tests for a green run.
- Small helpers may split responsibilities out of the 1500+ line HUD and
  1600+ line World, but only alongside touched behavior and regression checks.
  No wholesale architecture rewrite as a prerequisite for visual polish.

## 9. Verification and delivery

For each repaired defect, preserve the initial failing case and final result.
Tests must exercise behavior that can fail independently of the implementation.
Keep the real live portrait route in tests, not just legacy raster helpers.
Retain the hardened screenshot helper: PNG existence/write failure must affect
the result. Test a newly created output directory and a deliberately blocked
path; a passed assertion summary without saved evidence is not a visual pass.

Run relevant focused cases, then the strict full tests/run.sh. Verify a
nonempty completed zero-fail summary, process exit code, no parse/script errors
and expected test count. Keep other engine warnings visible with an explanation.
Run exact-ending bots including purge 3/5 and Wren; report requested versus
actual ending, deaths, sessions and stalls. Do not call three ending identities
proof that all six routes were traversed. Add missing route coverage where
needed without changing the win conditions to satisfy the bot.

Export Windows, Linux and Web. Run native smoke and browser lifecycle/audio
checks against those exports. Distinguish Windows export/PE integrity from
actual Windows execution. Label screenshots as staged/rendered automation,
human play, or historical. Keep every browser trial, including failures.

Prepare five short uncoached human sessions if participants are available.
Do not coach the first ten minutes. Ask players afterwards: Who are you? What
can hurt you? What were you trying to do? What did quitting/death keep? Which
character mattered? Where did the text move too fast? Record observations
without inventing participants or demographic conclusions from a tiny sample.

Deliver:
1. Ranked findings and explicit implemented/deferred/blocked lists.
2. Before/after animation clips or contact sheets and playable-room captures,
   with source hash, state, settings and capture method.
3. Exact tests/results, known warnings, device/listening gaps and measured limits.
4. Small commits, a clean worktree and a reviewable GitHub branch/PR. This prompt
   authorizes implementation and pushing that branch; merge to main only if
   the current user request authorizes merging and checks pass. Never force push.
5. A current Windows build through the supported artifact/release mechanism,
   a browser link only if deployment is verified, and real GitHub evidence links.
   Do not present local paths as public downloads or a running workflow as success.
6. Update the authoritative release status without rewriting historical evidence
   to pretend it describes the new runtime.

The pass succeeds when a new player understands an immediate goal and an
available response, can finish reading without fighting the interface, sees
characters react coherently to gameplay, can distinguish danger from atmosphere,
and remembers a specific relationship or choice. Evidence must support each
claim; presentation volume and test count alone do not establish this.
