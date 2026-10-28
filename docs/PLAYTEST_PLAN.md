# Playtest plan

The aim is to find out whether the first 30 minutes work on people who have never seen the game.

Automated tests and bot wins only prove the game *can* be completed. They don't prove anyone *wants* to finish it. Treat friends' compliments the same way.

## Three kinds of evidence

| Kind | What | How |
|---|---|---|
| Technical | Tests, bots, logs, save reliability, frame times | `tests/run.sh`, `tests/run.sh --bots --speed=2`, the visual tour (`--tour`), and the F3 frame-time overlay on the test machine |
| Observation | What fresh players do, uncoached | Silent observation plus a screen recording (with consent), using the session sheet below |
| Feedback | What they say afterwards | The questions below, asked in that order, without leading them |

## Who and how

- Recruit **5–8 players per round** who have never seen the game. Ideally aim for about half who play horror and half who don't. Collect no personal data beyond first name or initials and "plays horror: yes/no".
- Run a **clean save** each time: Settings → Reset the owner's memory, or delete `user://owner_memory.json`.
- **PC build**, keyboard or gamepad, whichever they prefer. Note which.
- Give them one sentence only: "It's a horror game; play as long as you like, think aloud if you can." **Do not explain controls or goals.** If they're stuck for more than 3 minutes, note it, then say only "what do you think you could try?"
- Allow 30–45 minutes. Stop when they stop.

## Session sheet (one per player)

```
Player: __   Plays horror: Y/N   Input: KB / pad   Date: __   Build: <git hash>

Timestamps (mm:ss from Load Slot 1)
  first movement ............ __      first door attempt ....... __ (locked? reaction?)
  first glitch used ......... __ (which?)  out of Arin's room ....... __ (how: seam / unlock / phase)
  first death ............... __ (cause)   noticed something changed after death? Y/N  what: __
  reached Archive ........... __      got the pointer .......... __
  reached the Edge .......... __      Slot 2 / ending .......... __ (which)
  quit / stopped ............ __ (why, in their words)

Stalls (>60 s without progress): where, what they tried, how it ended
Misreads: things they believed that aren't true (e.g. "I thought the cyan thing was an enemy")
Missed: interactions they walked past (notes, Mira, the cracked wall, the well)
First visible tension (face/posture/comment): __ at __
Quotes (verbatim):
```

## Afterwards (ask in this order, write down the answers word for word)

1. What do you remember most from that?
2. Was anything confusing? What?
3. Was there a moment it became frightening or uncomfortable? When?
4. What did the game do that you haven't seen a game do before?
5. Was there a point you lost interest?
6. What do you think happened, in the story?
7. Would you play more of it on your own? Why, or why not?

Don't ask "did you like X?", and don't explain anything until all the answers are written down.

## What to measure across a round

| Metric | Target for the demo (hypothesis, to be adjusted) |
|---|---|
| Out of Arin's room within 5 min | ≥ 80% |
| Used a glitch on purpose within 10 min | ≥ 70% |
| Noticed a persistent change after their first death, unprompted | ≥ 60% |
| Reached the Edge within 30 min | ≥ 50% |
| Q6 mentions the second player, or a deleted save | ≥ 50% |
| Q7 is a clear yes | track it; no target until there's a baseline |

## Developer-side instrumentation

- **In place:** `OwnerMemory` records deaths and causes, glitches, reloads and endings (the Records screen). The bots log their stalls (`tests/bot_playthrough.gd`).
- **Done (development only):** `PlaytestLog` (`scripts/autoload/playtest_log.gd`), switched on by `?playtest=1` or `-- --playtest`. It is shown under Pause → Playtest log, with a copy button.
- **What it records, timestamped from launch** (the observation column of `COMMERCIAL_DIRECTION.md` §8; never intent):
  - the opening's three states, each "by the player", "played itself" or "passed over", with the seconds waited and whether the hint was on screen; "opening skipped" with how far in;
  - session start (purge, last exit), first movement, first time out of the room, each area entered;
  - **each death**: cause, area, Rue's position, attention, and the warning text on screen at that moment (or "none");
  - hiding that actually turned a look aside, once per witness and cover: "hidden from arin behind wren", "hidden from lamp by cover in square";
  - lifting the lane gate; the pointer; memories; glitches; owner thresholds; the CHARACTER FILE read whole;
  - "scene skipped" (which scene), "journal opened", console history opened; quits and endings.
- **Not recorded:** reading speed, gaze, what the player meant. Those stay in the observer's notes.

## Report template

```
Round N · date · build <hash> · players: n
Top 3 stalls (count, where, likely cause)
Top 3 misreads
Moments remembered (Q1, tallied)
First-fear moments (Q3, tallied)
Story understanding (Q6: what fraction got the second-player idea)
Metrics table vs targets
Changes we'll make (each tied to an observation above), and what we won't change and why
```

## Round focus: narrative reliability (`claude/narrative-reliability`)

Use the same sheet, plus these targeted observations. Run at least one session with **Text reveal: Slow** and **Advance: Auto, Slow**.

| Question | What to watch | What would count as a problem |
|---|---|---|
| Is the warning strip noticed during the hunt? | When "saving over you." appears under the banner, does the player move within about 2 s? | The player keeps standing still, or later asks "why did I die?" |
| Do conversations feel safe or exploitable? | Talking during the hunt. Does the player use talking to wait out the cursor or Arin? | The player says talking is a pause button, or uses it to wait instead of to read |
| Is the death card read? | Time from card to retry press, and whether they mention the tip | Retry within 1 s of the prompt on a *first* death, every time |
| Is the 0.5 s repeat fast path fast enough? | Comments on dying repeatedly | "The death screen is slow" |
| Mira's face | Do players remark on her expressions? Can they say how she feels in the room, and after the walk? | Her portrait is read as Rue, or as the same face every time |
| Auto mode on Slow | Do long lines leave before they are read? | The player presses for History to re-read a line auto moved past |

**Results: untested.** No session has been run for this round. Results go in `PLAYTEST_RESULTS.md`, with the build hash, when real sessions happen.

## Round focus: sound and the first fifteen minutes (`claude/review-fixes`)

**Setup:**
- 3–5 first-time players, about 15 minutes each, then one returning run, about 5 minutes.
- Half on headphones, half on laptop speakers at their usual volume. Note which.
- Use the browser build for at least one player.

**Before they start.** Don't mention sound. If, after 2 minutes, they haven't said anything about it, ask once: "Can you hear the game?" Note the answer.

```
Player: __  Output: headphones / laptop speakers / phone  Build: web / Windows / Linux <hash>
Heard on the title (music box)? Y/N      Heard in Arin's room? Y/N      Turned volume up? Y/N
first movement .............. __     door reaction understood? Y/N (what they said)
first deliberate glitch ..... __ (which)   noticed the meter rise? Y/N
first memory ................ __     could say whose memory it was? Y/N
left the room ............... __ (how)
hid (Wren / closet) ......... __
first failure ............... __ (cause)   understood the cause? Y/N (their words)
after retry: noticed a change? Y/N (what)
willing to explore? (went somewhere optional) Y/N
point they wanted to stop ... __ (why)
```

**Afterwards (neutral, in this order, answers written word for word):**
1. What do you think happened?
2. What caused that? (Point at their first failure.)
3. What would you try next?
4. What felt unclear or unfair?

**Returning run.** Start the same save once more. Watch whether they notice the deleted door, the owner's note and the characters' lines. Ask "What's different?" and write the answer down.

**Results: not run.** Nobody has played this build. Don't fill in this section from bots or from guesses.

## Round focus: onboarding, threat and recovery (pass 4, `claude/last-save-file-prototype-ljwuq4`)

**Status: ready to run; results pending.** No session has taken place. Do not record expectations as results.

**Who:** 5 players who have never seen the game, about 20–30 minutes each, clean save, `?playtest=1`. Record the build hash (bottom of this section is filled in per round), the device (PC model or phone), browser or desktop build, and the input (keyboard, gamepad or touch).

**What this round tests (pass 4 changes):** awareness is explained before any glitch; tap vs hold is spelled out; tips come back if cut short; the pause menu says pausing is safe and quitting counts; the death card says what's kept and the purge count; the prompt never hides behind a tip.

**Watch for, without coaching** (tick and time each; write what they *did*, not what you think they meant):

| Moment | Observation (what happened, time) | Player's words (verbatim) | Hypothesis (yours, kept separate) |
|---|---|---|---|
| First intentional glitch: did they hold on purpose, on what, and did they look at the bar afterwards? | | | |
| Understanding awareness: do they mention the bar, or change behaviour when it jumps? | | | |
| First hiding attempt: where (beside Wren, closet, out of the cone) and did it work? | | | |
| First death: did they read the card; what did they try next run? | | | |
| Recognising persistence: did they notice a change after death (deleted door, ghost markers, someone remembering)? | | | |
| Optional exploration: notes, the well, Tobben, the Archive shelves | | | |
| Attachment: comments about Mira, Wren, Pip; hesitation before shedding | | | |
| Confusion: stalls over 60 s, misreads, repeated failed inputs | | | |
| Voluntary stopping: when and why, in their words | | | |

**Ask afterwards, in this order, without explaining anything first:**
1. What were you trying to do just then? (ask at one or two marked moments, during play if they pause naturally)
2. What do you think caused that? (after their first death)
3. What would you try next?
4. What did you remember most?
5. What felt unclear or unfair?
6. Would you continue on your own, and why?

**Keep three columns apart in the report:** observations (what happened), opinions (what the player said), hypotheses (what the team thinks it means). A change is justified only by observations, or by an opinion repeated by several players.

```
Round: pass 4 · date: __ · build: <git rev-parse --short HEAD> · players: 5
Player __ · device __ · browser/desktop __ · input __ · minutes played __
```

## Round focus: pass 5 additions (shelves, closets, the Edge, the opening)

**Status: ready; results pending.** Same five-player protocol as pass 4 (20–30 min each, clean save, build hash and device recorded). Additions:

**Intro variants (same build):** players 1, 3, 5 use `?intro=on`; players 2, 4 use `?intro=off`. (Desktop: the title's Settings can't toggle it; use the web build.) After play, ask: "What did you think was going on at the very start?" Record curiosity, basic understanding, emotional interest, impatience (did they skip? when?) and whether it revealed too much. Keep it only if it helps.

**Watch for (classify every miss as one of: not seen · seen, use not understood · understood, input missed · chose not to · unfair):**

| Moment | Time to discovery | Classification | Failures before success |
|---|---|---|---|
| Archive record (first one read) | | | |
| CHARACTER FILE (only if they reach the FILE stage) | | | |
| Closet discovered (before or after the first chime?) | | | |
| First house visit: hid in time? | | | |
| Edge: understood "write yourself in"? | | | |
| Edge: cause of first failure | | | |

Report denominators ("2 of 5"), not percentages; five players is exploratory evidence.

## Round focus: the festival and the first ten minutes (`INTRO_REBUILD.md`)

**Status: protocol and instrumentation ready. No session has been run.** No unfamiliar players were available during this pass, so every number in `INTRO_REBUILD.md` §6 comes from scripted runs (autoplay, a 6 s hesitant script, no input), not from people.

**Setup:**
- A clean profile. Start from the title with Start (not "The Festival").
- Web: add `?playtest=1`. Desktop: `-- --playtest`.
- Five players who have never seen the game.
- Don't explain anything. Answer only "I can't say" until the debrief.

**The log already marks** (PlaytestLog, pause menu → "Playtest log"):
- `prologue: first movement`;
- each `lantern N`;
- `player 1 left`;
- `the first decision` (lit / stayed / idle);
- `player 2 left`;
- `prologue skipped` (at which beat);
- `prologue over` (with the choice).

The room, the first goal and the rest come from the existing marks.

**Watch for** (time from Start; classify every miss as in pass 5):

| Moment | Time | Classification | Notes |
|---|---|---|---|
| First movement (target < 10 s) | | | |
| First lantern / first co-op success (target < 45 s) | | | |
| Hid beside Arin from Tobben's look, without being told twice | | | |
| Maypole: held [E] together on purpose | | | |
| PLAYER 1 HAS LEFT: what they did next (looked for him / lit it / stayed) | | | |
| The decision: which, and how long they took | | | |
| Skipped? At which beat? | | | |
| "who's in my save?": surprise by about 2:30? (ask afterwards) | | | |
| Reached the square: did they head for the lantern by the well? | | | |
| Talked to Mira: did "You lit the last one" land? (ask afterwards) | | | |

**Debrief**, in this order, word for word:
1. Who were you at the start, and who was the other one?
2. What happened to the other player? And to yours?
3. Why could you still move?
4. Who do you think kept the fifth lantern burning?
5. Would you keep playing right now? Why?

Answers to 1–3 test whether the connection was felt and the premise read. Answer 4 tests the hook. Report denominators ("3 of 5"), never percentages, and quote players' words exactly, not paraphrased.

## Round focus: trust and one relationship (2026-10-28)

**Status:** not run. This protocol is ready, but no participants have been arranged. **Nothing here may be reported as a result until it has been run with people.**

Run five **separate** sessions; one player may do more than one, on different days. Observe without explaining. Write down **behaviour** (what they did, with the time) separately from **opinion** (what they said).

**Builds:**
- Windows if available, otherwise the web build.
- For session 1, play once with the normal camera and once with the plain camera (`-- --camera-plain`, or `?camera=plain`). Alternate the order between players.

| # | Session | Setup | Watch for (behaviour) | Ask afterwards (opinion) |
|---|---|---|---|---|
| 1 | **Movement feel** (10 min) | A fresh profile. Festival only, then the room. Keyboard, then controller | Overshoots, wall-hugging, missed interactions, repeated taps on a target, hesitation at the gate, facing confusion | "What did you intend to do there?" "Did Rue respond as you expected?" "What made the movement uncomfortable?" "Which camera felt calmer?" |
| 2 | **Opening comprehension** (15 min) | A fresh profile, through the festival | When they notice Player 1 has stopped (before or after the text); whether they try alone or stay; what they believe lit the fifth lantern | "What happened to Player 1?" "Who lit the last lantern?" "Who are you playing?" |
| 3 | **Wren's arc** (30 min) | A profile at the square, Wren met | Whether they find her game; which spot they chalk; their reaction to the rubbing-out and the backwards R; whether they hide at her X when hunted; whether they write her name | "Who do you care about, and why?" "What changed between you and Wren?" "What do you believe the well can do?" |
| 4 | **Save and exit trust** (10 min) | Mid-run, at a calm moment and during an escort | Do they find Save and exit? Their expectation before resuming; what they look for after | "What did you expect Save and exit to keep?" "Did it keep it?" "Would you trust it before dinner?" |
| 5 | **Desire to continue** (open) | Wherever session 3 ended | Whether they keep playing unprompted; where attention drops (looking away, fidgeting, skipping text) | "What would make you continue?" |

**Additions (2026-10-28), same sessions:**
- **Session 1, movement:** also play the three movement variants on the same route. Use `-- --move=a`, `--move=b` and `--move=c` (or `?move=`), in a different order per player, without saying which is which. Record per variant: overshoots at the save crystal and the gate, taps repeated on a target, and any comment on "floaty", "stiff" or "slidey". Ask: "Which of the three felt most like Rue did what you meant?" `VARIANTS.md` has the numbers to compare against. Players supply the preference.
- **Session 1, objects:** whenever they press E, note whether they could say beforehand what the thing was. Every prompt now names it ("SAVE POINT", "THE WELL'S RIM"). Ask afterwards: "Was there anything you touched without knowing what it was?"
- **Session 2, opening:** the memory card comes before the festival. Watch whether they read it or skip it. Ask: "Before the festival started, what did you think was going to happen?" and "Who typed the last line?"
- **Session 3, Wren, now from a fresh profile, not "Wren met":** note the talk on which her game starts (it should be the third), and whether they notice "CHALK OUT" or the raised chalk before she explains. Note whether they read the place names before chalking. In a second session on a later day, note whether they notice her new drawings.
- **Session 5 (new), the whole route:** time the first ending with a stopwatch and note the time spent reading. The product spec's 2–3 hours is unmeasured, and the bots reach an ending in about 2.5 minutes of travel (`production/SLICE_ROUTE.md`). This is the number that decides scope and price.

**Gate for the next investment:**
- **Controls work but players are indifferent** to Wren: revise the interactions and scenes before buying assets.
- **They care and want more:** proceed to the representative-section art and audio standard and a voice pilot. Spending needs the author's authorisation.
