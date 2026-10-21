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
