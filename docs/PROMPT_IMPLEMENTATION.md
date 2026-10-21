# Executing the supplied prompts

Baseline: fetched main `1e371b1` (October 21, 2026). All existing work is
preserved in an isolated `codex/prompt-implementation` worktree.

The newest `PRESENTATION_GAMEPLAY_FOLLOWUP_PROMPT.md` explicitly asks to finish
Milestone A before expanding to the opening/maps. Implementation order:

1. Make the live portrait route resolve approved, palette-specific external
   resources with a safe shared procedural fallback. Validate actual HUD use.
2. Repair speaker/pose ownership: mute/written text, idle mouth, moving escorts,
   restricted animation. Keep existing gaze and live-clock repairs.
3. Address caption/voice ownership and reading aids, retaining manual advance,
   single playback, source-line history and pause semantics.
4. Validate the completed slice before publishing. The later map/local-survey,
   new artwork/performances, human listening/playtesting and hardware targets
   remain separately tracked, not claimed complete by adding loaders or tests.

Initial source-confirmed findings: PortraitView bypasses external texture loading;
world NPC talking follows the conversation rather than the active line;
written Tobben/Arin text can animate mouths; movement facing and conversational
gaze can repeatedly restart turns; recorded text bypasses pagination. Each
repair below will be accompanied by actual-route regression coverage.

## Implemented first milestone

- Live `PortraitResolver` / `PortraitAsset` integration for dialogue and scenes;
  six identities, matching restoration/fraying/borrowed palettes, metadata and
  frame/crop validation, resource round-trip tests and same-character fallback.
- One mouth rhythm and active-line speaking ownership in portraits and world
  NPCs. Written/silent responses stay still; moving dialogue gaze no longer
  perpetually retriggers turns; restricted/speaking idle loops yield.
- Caption pagination for recorded performances without restarting audio;
  source history/events stay coherent, auto final pages wait for the take,
  held dialogue resumes its recording position after a scene interruption.
- Independent, persisted system-speech rate, bounded from 0.75 to 1.1×.

See [CAPTION_VOICE_CONTRACT.md](CAPTION_VOICE_CONTRACT.md) for route ownership,
cue limitations, settings behaviour and the explicitly remaining prompt work.
No new production art, recorded cast, map layout or local floor plan is claimed.

## Verification

The three speaking/gaze cases reproduced failures before repair (0/3) and pass
afterwards. The actual-HUD, asset, caption, speaking and character compatibility
run completed **18 passed, 0 failed**, 10.7 s, wrapper exit 0 with isolated
temporary and user data. A first integration run included an obsolete test
requiring a second HUD mouth rhythm; it was updated to exercise the actual live
renderer clock and speech state, then rechecked. Initial incomplete/false-summary
runs are not counted as acceptance. Coverage completed across **all 482 unique
cases in 71 test files**, using independent processes/profiles and strict
completed-summary, expected-count, exit and script-error checks. This is
per-file coverage, **not a completed monolithic local run**. The first parallel
run reported 481/482: its verifier incorrectly capped the CPU-budget file at
60 FPS (16.67 ms versus an uncapped 4 ms budget). An uncapped, independent
wrapper rerun passed that entire file **6/6**, 19.6 s, exit 0; the budget was
not weakened. Both outcomes are retained in the evidence. New CI is tracked in
[PR #9](https://github.com/makedonskivasil3-sketch/The-Last-Save-File/pull/9).

[Verification metadata](review/prompt-milestone/verification.json) and
[per-file raw logs](review/prompt-milestone/isolated-tests.log) retain exact
scope, counts and the initial capped-performance failure. Local monolithic
attempts were interrupted/incomplete and are not counted as passes; one
earlier compatibility wrapper also rejected a displayed summary. The isolated
18-case wrapper repeat and per-file acceptance checks completed successfully.
The CI workflow still provides the separate monolithic/export/browser check.

Five exact-ending bots completed **5 passed, 0 failed**, 257.7 s, exit 0.
Escape, purge-3 escape, purge-5 escape and Wren each reported zero deaths and
zero stalls. The message run reported **one eraser death/retry and 17 recovered
navigation stalls** before reaching its exact ending. This is not a smooth or
stall-free campaign claim; route readability and bot navigation remain open.

Rendered checks completed **2 passed, 0 failed**, 9.1 s, exit 0. Compatibility
renderer, Mesa llvmpipe, 1280×720 window / 640×360 logical canvas, Dummy audio.
The environment lacks `libspeechd`, so TTS setup diagnostics are retained and
no system-voice listening claim is made. These are staged references from a
returning-session test helper, not an actual first-run route or human playtest.

Reviewed captures:

- [Live Mira dialogue](review/prompt-milestone/mira_live_dialogue.jpg)
- [Waiting for input](review/prompt-milestone/mira_waiting_for_input.jpg)
- [Largest combined caption text](review/prompt-milestone/large_recorded_caption.jpg)
- [Written Tobben beside Rue](review/prompt-milestone/tobben_written_response.jpg)

Visual inspection caught two staging mistakes in the first harness attempt:
forcing SHOWN had not revealed the label, and staging a conversation away from
Tobben let the normal distance rule close it. The final harness explicitly
reveals the caption, moves Rue beside him, checks that the dialogue stays open,
and was rerun. The final images visibly contain the required text. No game rule
was weakened to keep a staged screenshot open.

Shutdown ObjectDB/resource diagnostics remain unresolved. Real-device speech,
listening, human playtesting, hardware measurement and the next map milestones
remain pending. The next implementation should address the first-room/Square
experience and observed route stalls before broader environment decoration.
