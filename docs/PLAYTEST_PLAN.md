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
