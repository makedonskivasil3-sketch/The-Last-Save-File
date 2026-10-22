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
