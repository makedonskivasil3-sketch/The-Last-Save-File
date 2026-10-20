# Playtest results

**Status (2026-10-20): no human playtest has taken place yet.** Nothing in this file is a finding. The next round is ready to run: see "Round focus: onboarding, threat and recovery (pass 4)" in `PLAYTEST_PLAN.md`. When a round is run, its results go below, in the template from `PLAYTEST_PLAN.md`.

## Running a session

1. Open the game with **`?playtest=1`** at the end of the address, for example `https://makedonskivasil3-sketch.github.io/The-Last-Save-File/?playtest=1`. A desktop build needs `-- --playtest`.
2. Start from a clean save: Title → Settings → Reset owner memory.
3. Watch without helping. The game timestamps:
   - first movement;
   - leaving Arin's room;
   - the first glitch and each glitch after it;
   - every death (cause, area, awareness);
   - memories, including the planted one;
   - the pointer;
   - each area entered;
   - the owner's thresholds;
   - endings and quits.
4. Afterwards: Pause → **Playtest log** → **Copy to clipboard**, and paste it next to your notes. Nothing is sent anywhere. The log only exists on that device (`user://playtest_log.txt`, and the browser console).

## Round 1: plan

The method, consent and the session sheet are in `PLAYTEST_PLAN.md`. Instead of the generic sheet, record these for every player:
- **Build:** the git hash, from the commit shown in the repo.
- **Input and screen:** keyboard / gamepad / phone; browser or desktop build; screen size.

### What this round must answer

Each question is tied to a change in this milestone, so the round can show whether the change worked:

| Question | Observe | Related change |
|---|---|---|
| Do players understand why awareness jumps? | They say why after a "+N · why" pop-up; or they ignore it | the reasons on one-off awareness jumps |
| Is the reload warning heard and understood? | After "do that again and i'm loading the autosave.", do they stop glitching or do it anyway, knowingly? | the reload tell |
| Do they read dialogue safely? | Any death while a dialogue box or question is open (should now be none from the save-over) | reading isn't standing still; questions hold the owner |
| Do they accidentally pick a choice? | Any choice they didn't mean (should be none) | the choice input grace |
| Is Arin's sighting read as a threat? | Their words when Arin points: "it saw me" vs "it waved" | Arin points; the warning triangle |
| Do characters feel distinct? | Can they describe Mira, Wren and Tobben by voice or behaviour without being asked about sound? | procedural voices |
| Is text speed comfortable? | Do they skip lines, or go to Settings → Text? | text speed |
| Time to leave Arin's room; first glitch; first death; whether they noticed what changed after it | timestamps | baseline for later rounds |

### Neutral questions (from the brief)

- "What do you think is happening?"
- "What do you think caused that?"
- "What would you try next?"
- "How did that moment feel?"
- "Was anything unclear?"
- "Was there a point where you wanted to stop playing? Why?"

## Results

*(empty until a round has actually been run)*
