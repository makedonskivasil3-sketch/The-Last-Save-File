# Prompt: pass 9, a code-review follow-up to passes 7–8

Continue developing The Last Save File on `claude/last-save-file-prototype-ljwuq4`, from the current head.

This pass is a **code-quality and correctness pass** on what passes 7 and 8 added (`ac7c742..HEAD`, 25 scripts). The review below was done by reading the diff; nothing in it was run.

- Confirm each finding before you change anything: reproduce it, or show the exact code path.
- Fix what is confirmed, with a test for each fix.
- Leave design decisions to the author, and record them.
- Do not add features, areas, endings or glitches.
- Do not change the quit/purge rule, the escape card's wording (`NARRATIVE_DECISIONS.md` §1), or any canon.
- Do not merge or deploy.

## 0. Baseline first

- Record the head commit, CI on it, and whether PR #7 and PR #6 are merged. If they are, follow the repo's merged-PR rule: restart the branch from `main`.
- Run the full suite, the bots (`--bots --speed=3`, 5 bots including purge 5), `web_check` (three runs) and `audio_output_check`. Write the results down against that commit before editing anything.
- Do not run two Godot processes at once.
- Do not edit scripts or tests while a run is in progress.
- Do not use `pkill -f` with a pattern that matches your own command.

## 1. Navigation lifecycle (`nav_grid.gd`, `area.gd`, `owner_avatar.gd`, `drag_prop.gd`, `door.gd`)

**1.1 The version goes up even when nothing changed.**
- `NavGrid.refresh()` always does `version += 1`.
- `OwnerAvatar._go()` calls `geometry_changed()` every time a walker is stuck. So one stuck walker forces every walker in the area to replan, every `STUCK_TIME`, even when the level didn't change.
- Fix: `_mark()` returns how many cells flipped; bump `version` only when that number is above 0. A stuck walker on an unchanged grid then gets `Go.BLOCKED` and the patrol's skip/watch logic handles it, as designed.
- Test: two walkers. Make one stuck against a solid the grid already knows about. The other's path must not be replanned (its `_path_version` stays the same).

**1.2 A crate's last small move can be lost.**
- `DragProp._process` notifies only after a move of more than `NOTIFY_STEP` (4 px), throttled to every `NOTIFY_EVERY` (0.25 s).
- A drag that ends with under 4 px of movement since the last notice never tells the grid where the stack finally stopped.
- Fix: notify once more when the stack stops (`held` goes false, or the position is unchanged for a frame) whenever `_told_at` isn't the current position.
- Test: drag the stack a total of 3 px and stop. Within one refresh, the grid's solid cells must match the stack's final rectangle.

**1.3 `geometry_changed` awaits on the area.**
- It awaits two `physics_frame`s on the Area. If the area is freed during that wait (an area change mid-drag, or a door forced open just before leaving), the coroutine resumes on a freed instance.
- Today's suite shows no such error, but no test covers it.
- Reproduce: force a door open, then change area within the same frame. Look for "Resumed function after await, but class instance is gone".
- If it reproduces, schedule the refresh on the tree with a callable that checks `is_instance_valid(area)`, or use `call_deferred` and a physics-frame counter.

**1.4 Recovery.**
- `_push_out()` relies on `get_rest_info().normal`. Untested: a body whose centre is deep inside a thick solid, say 6 px inside a 40 px block. Does `get_rest_info` still return a normal? If not, Arin holds still forever and detection keeps running.
- Add that test. If the normal is empty, fall back to the direction of `nearest_open()`, taking a step only when `_penetration` decreases.
- `_penetration()` and `_body_query()` build a new `PhysicsShapeQueryParameters2D` and `CircleShape2D` on every call, up to 8 per frame while recovering. Cache one query and shape per avatar, and reuse `_ignored()`.
- `_recovered` resets only once Arin is clear. After `RECOVER_RANGE` with no escape, Arin is stuck for the rest of the area.
  - Decide and document: should a level change (a new grid version) reset `_recovered`? It probably should: an opening appearing next to a stuck Arin should let it try again.

**1.5 Small cleanups.**
- `_patrol()` calls `nav()` twice per frame while watching.
- `OwnerAvatar.nav()` still builds its own grid when the area has none, while `TheEdge.guard_grid()` builds one too, with different exclusions (only the player's RID, not NPCs).
  - Make one owner of the area grid, e.g. `Area.nav_grid()`, used by both.
  - Assert that both callers get the same exclusions.

## 2. The protection policy (`world.gd`, `hud.gd`, `owner_cursor.gd`, `the_edge.gd`)

**2.1 Rue can walk while a large card freezes every threat.**
- `is_act_shown()` is true for about 4 s: a 0.4 s fade-in, a 2.8 s hold and a 0.8 s fade-out. Rue stays fully controllable throughout.
- A player can walk past a frozen Arin or cursor under an act or NEW GLITCH card.
- This is a **design question**: free movement, a hold that ends when the fade-out starts, or freezing Rue too. Measure how far Rue can travel under a card (about 90 px/s × 4 s). Present the options with that number and implement only what the author picks.
- At minimum, end the hold when the fade-out *starts*, not when it ends (`is_act_shown` while `modulate.a` rises or holds).

**2.2 Clearing the cursor's click on any pause also changes PAUSE.**
- Resetting `OwnerCursor._select` on any `paused` also applies to Rue's PAUSE glitch, so PAUSE now cancels a click in progress. That makes PAUSE stronger, and it isn't documented.
- Decide: either clear only for story holds (have World tell the cursor why it's paused) or keep it.
- Document the decision in `GAMEPLAY_CONSISTENCY.md`, with a test either way.

**2.3 Two mechanisms pause the Edge's cursor.**
- `TheEdge._arriving()` still pauses the cursor itself, and the shared rule now does the same.
- Remove `_arriving()`, or reduce it to the countdown banner logic, so only one path writes `cursor.paused` on arrival.
- Keep `test_the_countdown_waits_for_the_act_card` passing.

**2.4 Most tests no longer go through the card hold.**
- `start_session` and `go_to` in `tests/test_case.gd` now dismiss the act card, so most tests never run with the card's real timing. A regression in the hold could pass the suite.
- Add one integration test that plays a first visit with the card left up, from the doorway: real `change_area`, no `dismiss_title`.
  - It must assert that nothing moves, then that everything resumes once the card is gone.
- Check that the bots (which don't dismiss cards) still pass.

## 3. Finale (`the_edge.gd`, `story.gd`)

- `goal_text()` returns `""` for `"beaten"`. Check what `World._update_objective()` shows for an empty Edge goal; it may fall back to the generic "Lead the cursor away…" line during the recap. If so, keep the goal line empty or freeze it.
- `_beaten()` sets `cursor.paused = true`. Make sure nothing (`set_owner_paused(false)` after the Slot 2 choice, PAUSE ending) un-pauses the cursor while the ending plays. Add a test that holds the bypass for 3 s after the choice opens: no click and no death.
- Bypass test coverage: add the case where the cursor is lured by DECOY rather than BLIND, and the case where the fight never starts (the cursor within 40 px of Rue at 50%).

## 4. Retry pacing (`arins_room.gd`)

- `back_from_the_edge()` runs twice per frame in `area_process`. Compute it once in `build()` and store it.
- It depends on `deaths_log` entries carrying `session`. Old saves may have entries without it. Confirm `int(last.get("session", -1))` behaves on a save from before that field existed, and add a migration test.
- Record the decision: the seam is open, but the owner's "you used that wall" patching still applies. Check that the seam chosen after a death at the Edge is one that isn't patched; if every seam is patched, check what happens.

## 5. Presentation code (`ui_style.gd`, `hud.gd`, `title.gd`, `pixel_character.gd`, `illustrated_character.gd`, `decor.gd`)

**5.1 Owner text.** `UiStyle.outline()` now sets `shadow_outline_size = px`. The console's owner lines then override `font_shadow_color` (cyan) and `shadow_offset_x = -1`, so the owner's colour-split ghost is now a blurred cyan halo, `px` wide. That is unintended.
- Compare before and after on owner lines.
- Set `shadow_outline_size = 0` for owner lines.

**5.2 Banner overflow.** The banner is a fixed `Vector2(170, 50)` plate, 300 × 18. Check it with large text (`text_scale`) and the longest banners:
- `"◀◀  LOADING AUTOSAVE  ·  00:10 AGO"`
- `"THE EDGE IS UNLOADING  ·  10"`
- `"‖  OWNER PAUSED"`

Also check that the two-line goal line top-left (the square's long goal) doesn't run into the plate with large text. Size the plate to its text, or wrap it, and capture both.

**5.3 Motion.**
- The turn squeeze and stop settle ignore `Settings.reduce_flashing` / `glitch_intensity`. Decide whether reduced motion should disable them (the opening's reduced-motion rule is the precedent).
- `look_at()` changes `facing` outside `update()`, so NPCs turning to watch Rue never squeeze. Decide whether that's intended.
- In `pixel_character.gd`, the new `const` lines sit in the middle of the `var` block. Move them up with the other constants.

**5.4 Title.**
- `Settings.changed.connect(lambda)` in `title.gd` is never disconnected. Check that reloading the title (via `_rebuild_on_close`) and returning from a run don't stack connections or call `_fit_menu` on a freed title. Connect with a method, not a lambda, or disconnect in `_exit_tree`.
- `tests/tour_title.gd` measures `_menu.get_parent()`, which is now the ScrollContainer. Measure the panel (`_panel_of(_menu)`) as well.
- In `t04_large_text`, the text looked about the same size as without large text. Confirm large text is actually applied on the title (`UiStyle.rescale_text` after the menu is built).
- `TitleArt` redraws every frame. Measure its cost in `tour_profile`, and redraw only the moving parts (dust, screen) if it matters.

**5.5 Doc comments moved by the edits.** These sit on the wrong declarations:
- In `area.gd`, `## Rue's PAUSE glitch: everything the owner drives holds still.` now sits above the navigation section instead of `set_owner_paused()`.
- In `area.gd`, the `start_erasure()` doc block now sits above `SAFE_SEED_DISTANCE`.
- In `ui_style.gd`, `outline()` has the old one-line doc and the new block stacked together.

Put each comment back on its own declaration.

## 6. Story and data (`story.gd`, `world.gd`, `recycle_bin.gd`, `archive.gd`)

- `Story.messages()` swaps the first message when `knows_truth`. Check:
  - that the voice manifest has a line ID for the truth variant (`tools/voice_manifest.gd` iterates only `MESSAGES.size()` under a state set: confirm the truth state is among `_states()`);
  - that the journal and the history show the swapped text.
- `win_text()` now has three cases at five memories. Add a state-combination test over `found ∈ {0, 3, 5}` × `knows_truth` × each ending, asserting each card's text against the canon table in `GAMEPLAY_CONSISTENCY.md`.
- `the_edge.gd`: `Story.FINAL_FIGHT.late` is said by `director.say` while `reach_slot2` opens the recap. Confirm it is shown, recorded in the history and not cut off by the cinematic.

## 7. Tests and tools

- `tests/tour_retry.gd` extends `bot_playthrough.gd` and stubs every inherited `test_*`. A new bot added to `bot_playthrough.gd` will run inside the tour too. Move the shared driving into a helper script that both extend.
- `web_check.cjs`: the beforeunload wait is now bounded (5 s). Run it 10 times. If it still flakes, record the failure rate in `RELEASE_READINESS.md`; don't hide it.
- `test_pass8.test_dragged_crates_move_the_blocked_cells_with_them` moves the crate by setting `global_position`. Also drive it through the real cursor drag (`OwnerCursor.drag`), so the notification path under test is the one players hit.

## 8. Deliver

- Run the focused tests for every touched file, then the full suite, the bots, `web_check` ×3, `audio_output_check`, the web export, and `tour_visual` + `tour_title` + `tour_edge` captures.
- Tie every result to a commit in `RELEASE_READINESS.md`.
- Add a pass 9 ledger to `GAMEPLAY_CONSISTENCY.md`: finding → evidence → confirmed/not → fix → test. Mark design questions as open, with the measured numbers.
- Update the PR #7 description. Don't merge.
- Report: confirmed issues fixed, findings that didn't reproduce (and why), decisions left to the author, test results by commit, save compatibility (no save fields should change), and three prioritised next steps.
