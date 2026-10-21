# Caption and speaking ownership

This pass implements the first presentation milestone from the supplied prompts,
on top of main `1e371b1`. It does not deliver a new voice cast or a new map set.

| Route | Reveal / reading | Voice and advance | History / progression | Threat rule |
|---|---|---|---|---|
| Dialogue | LinePacer, manual by default; every caption page receives its reading allowance | One recording per original line, continued across pages; unrecorded TTS is per page; final auto page waits for speech and delay | Original line logged once; existing source event emitted on the final page | Existing reading hold |
| Memories, reveal, ending, epilogue | Same caption pages and reveal/advance separation | One recording across pages; manual next-source/close may cut speech; held skip stops it | Source logged once, including skipped source lines; existing game consequences retained | Existing cinematic hold |
| Boot and opening film | Existing dedicated opening/cinematic routes | Opening timeline, captions, skip arming and focus safety unchanged | Existing opening-seen and boot rules | Existing protection |
| Ambient Owner/self/NPC console | Existing typewriter and ambient allowance | Procedural blips; no new automatic freeze | Existing History | Continues under existing survival rules |
| Urgent warning | Immediate warning strip | Bypasses ambient queue | Existing warning history | No new pause rule |
| Objectives | Existing priority/tween reading budget | No spoken performance | Existing per-area goals and pause display | No new hold |
| History replay | Full original source line | Separate preview player; paused story voice retains its position | No new journal/truth event | Menu pause |

For recorded caption pages without authored timing metadata, automatic cue
positions are estimated from their share of the source's characters. A page
waits for both its reading allowance and its estimated audio boundary. Final
pages wait for the full take and post-voice delay. These are conservative
proportional cues, not word-aligned subtitles or phoneme lip-sync. Manual page
advance can reveal the next caption without restarting the voice; the next
source line deliberately stops the old voice. A cinematic interrupt resumes
the interrupted recording at its saved playback position rather than replaying
the whole take from the beginning.

Long resource identifiers without spaces are now bounded too. The original
source is retained for history/IDs/events; splitting does not invent a new
recording or duplicate truth evidence. Existing voices, reveal/reading settings,
mute levels, focus/menu pause and no-recording fallbacks remain independent.

Portraits and world mouths use the active line's reveal/voice state, not merely
an open conversation. Written Tobben and punctuation-only silent Arin do not
mouth or narrate their text. The renderer owns the mouth rhythm; the HUD sends
speaking state rather than multiplying it by another rhythm. NPC dialogue gaze
owns facing while speaking, so movement cannot restart turn squash each frame.
Restricted/speaking characters suppress ordinary greeting/hop/reading idles;
the existing explicit freeze path still holds the pose.

System speech has an independent 0.75 / 0.85 / 1.0 / 1.1× preference, multiplied
by each character's existing base rate. It persists outside Owner memory. A
settings change stops the current system utterance; its caption stays visible,
and the next line uses the new preference. Recorded acting is never stretched.
Real-device listening is still required to choose a preferred audition speed.

## Remaining prompt work

The following remain open and must not be inferred from automated checks:

- Authored artwork and licensed dramatic performances. The asset resolver
  makes approved resources usable; it does not manufacture or approve a cast.
- Real listening, human comprehension/playtests, real-GPU measurements,
  Windows execution, physical controller/phone and mobile-browser validation.
- A comprehensive pose/style overhaul, gait-distance experiments and isolation
  of all existing presentation RNG from gameplay RNG.
- Classification/migration of any additional essential ambient story beats.
  Current essential dialogue/cinematic routes stay deliberate; the existing
  console backlog/Owner-gap policy is not silently rebalanced in this pass.
- Milestones B/C: first-room/Square staging, seven-map readability, geometry-
  derived local survey, shelter affordances and stable temporary-floor timing.
- Remaining shutdown ObjectDB/resource diagnostics and observed bot stalls.

The next coherent implementation is Milestone B with matched captures and
uncoached observations where humans are available. This milestone's completion
does not mean every proposal in either supplied prompt has been delivered.
