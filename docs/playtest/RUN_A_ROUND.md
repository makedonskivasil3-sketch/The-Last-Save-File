# Run a playtest round: everything in one place (2026-10-29)

**Status: ready to run; not run.** Nobody has been recruited and no session has taken place. Nothing in this folder is a finding until people have played.

This file is the whole kit, in the order you'll use it. The protocol it follows is [`../PLAYTEST_PLAN.md`](../PLAYTEST_PLAN.md), "Round focus: trust and one relationship", plus the additions at the end of this file.

| You need | Where |
|---|---|
| A message to invite players | §1 |
| What to tell them before they play (consent) | §2, and [`TESTER_NOTE.md`](TESTER_NOTE.md) to send them |
| The links, one per session | §3 |
| The schedule for five sessions | §4 |
| What you say and do in each session | §5 |
| The sheet you fill in while they play | [`OBSERVER_SHEET.md`](OBSERVER_SHEET.md), one per player per session |
| How to keep the game's own log | §6 |
| How to turn five sheets into a decision | §7 |

---

## 1. Inviting players

**Who:** five people who have never seen the game. Ideally two who play story games often, two who play a little, one who rarely plays. Friends of friends are better than close friends: close friends are kind. Nobody who has read the docs.

**Message (copy, fill in the brackets):**

> Hi [name]. I'm making a small story game about a character left behind in an old save file, and I'd love to watch someone play it for the first time. It takes about [30–45] minutes in a desktop browser (Chrome, Edge or Firefox), with sound on. You can't do it wrong: I'm testing the game, not you. I'd sit with you (or watch over a video call with screen share), say almost nothing, and ask a few questions at the end. Would [day] at [time] work? There's no payment [or: I can offer (thank-you)].

**Don't** describe the story, the characters or what to look for. Don't send screenshots.

## 2. Before they play: consent

Say this (or send [`TESTER_NOTE.md`](TESTER_NOTE.md) and confirm they read it):

1. "It's unfinished. Things may break; that's useful."
2. "Please think out loud: what you're trying to do, what confuses you, what you like."
3. "I won't explain anything. That's on purpose."
4. "Stop whenever you like. You don't need a reason."
5. **Recording:** ask, and write down the answer. "May I write notes while you play?" (always needed). "May I record the screen and your voice?" (optional; only with a clear yes; say where it's kept and that it's deleted after the round). If they say no to recording, take notes only.
6. "The game keeps a log of what happens in it (when you moved, when you were caught). It stays on this computer. Nothing is sent anywhere. I'll copy it at the end, with your OK."

Record the consent on the observer sheet's header line ("notes / screen / voice: yes/no").

## 3. The links

**Use one build for the whole round** and write its commit on every sheet.

- **The web build on GitHub Pages** (deployed from `main` by `.github/workflows/build.yml` after the merge): `https://makedonskivasil3-sketch.github.io/The-Last-Save-File/`. **Open it yourself first** on the computer they'll use. If it doesn't load, use a desktop build (below) and note it.
- **Desktop:** the Windows or Linux export from the CI run for that commit (Actions → the run → Artifacts). Start options go after `--`, for example `TheLastSaveFile.exe -- --playtest --move=b`.

Add these to the address (web) or the command line (desktop):

| Session | Web address ends with | Desktop |
|---|---|---|
| 1. Movement, variant A / B / C | `?playtest=1&move=a` (then `b`, then `c`, in a different order per player) | `-- --playtest --move=a` |
| 1. Camera, plain | `?playtest=1&camera=plain` | `-- --playtest --camera-plain` |
| 2–5. Everything else | `?playtest=1` | `-- --playtest` |

**A fresh profile** for sessions 1–3 and 5: the game keeps its save in the browser. Use a **private window** for each fresh player (the save goes when the window closes), or on desktop delete the folder named in the Godot docs for user data (`%APPDATA%\Godot\app_userdata\The Last Save File` on Windows). Session 4 needs a save **in progress**: let them continue in the same window as session 3.

**Order variants with this table** (so no variant is always first):

| Player | Order |
|---|---|
| P1 | A, B, C |
| P2 | B, C, A |
| P3 | C, A, B |
| P4 | A, C, B |
| P5 | B, A, C |

Don't tell them which variant is which, or that the camera changed.

## 4. Schedule

One player at a time. Five players, each one **long sitting** of about 60–75 minutes, or two shorter sittings on different days (better for session 3's "later visit"):

| Sitting | Sessions | Minutes |
|---|---|---|
| Day 1 | 1 (movement, three variants, about 4 min each), 2 (opening) | 25–30 |
| Day 1, after a break | 3 (Wren), 4 (Save and exit at a calm moment) | 30–40 |
| Day 2 (if they'll come back) | 3 again (a later visit: does anything they did show?), 5 (the whole route to an ending, stopwatch running) | 30–60 |

Book 15 minutes between players to copy the log, finish the sheet and reset the profile.

## 5. In each session

**Before:** a fresh sheet; write player code, date, device, browser, input, the commit and the link. Start a stopwatch when they press their first key.

**During:** write behaviour with times, not interpretations. ("4:10 walked into the board three times" not "confused by the board".) If they're stuck for two minutes, write the time and what they were trying; only then say "keep going, or stop if you like".

**What to watch, by session:** the "Look for these" list on the sheet, plus the additions below (§8).

**After:** the questions on the sheet, **in that order**, answers word for word. Then the two questions in §8 that match what they reached.

## 6. Keeping the game's log

With `playtest=1` the game writes a timestamped line for each milestone (first movement, leaving the room, first glitch, deaths, memories, the Edge, endings, quits, the owner's thresholds, the cold open read or skipped).

At the end of each session, **with their OK**:
1. Esc → **Playtest log** → **Copy to clipboard**.
2. Paste it into a text file named `P<code>_S<session>_<date>.txt`, next to the sheet.
3. On desktop the same log is also in the user-data folder as `playtest_log.txt`.

The log is evidence of **what happened**; the sheet is evidence of **what they did and said**. Keep both. Never put names in file names: use the player code.

## 7. After the round: from sheets to a decision

Fill this in once all five are done. Copy the table into `docs/PLAYTEST_RESULTS.md` under a new dated heading, with the commit.

| Question | P1 | P2 | P3 | P4 | P5 | Count |
|---|---|---|---|---|---|---|
| Preferred movement variant (A/B/C) | | | | | | A _ B _ C _ |
| Overshoots at the crystal/gate (per variant) | | | | | | |
| Pressed E on something they couldn't name | | | | | | _ / 5 |
| Read the memory card (or skipped) | | | | | | _ / 5 |
| Said who lit the last lantern ("Rue", "nobody", other) | | | | | | |
| Found Wren's game (talk no.) | | | | | | _ / 5 |
| Named Wren when asked who they care about | | | | | | _ / 5 |
| Noticed Tobben walk to the board | | | | | | _ / 5 |
| Noticed the colours coming back (§8) | | | | | | _ / 5 |
| Said what the colours mean, roughly "chosen for her" | | | | | | _ / 5 |
| Trusted Save and exit (would use it before dinner) | | | | | | _ / 5 |
| Kept playing when told they could stop | | | | | | _ / 5 |
| Time to first ending (min), of which reading (min) | | | | | | median _ |
| Biggest problem (one line each) | | | | | | |

**Decide with these rules, written before the round so the results can't bend them:**
- **3 or more of 5 couldn't name what they pressed E on:** the object names and art come before any new content.
- **3 or more of 5 didn't find Wren's game, or don't name her:** revise her scenes before buying any art or voice (the gate in `PLAYTEST_PLAN.md`).
- **2 or fewer of 5 noticed the colours:** cut the `rue` epilogue's colour line (canon B), or make the restore moment louder. Canon A stays (it changes no text).
- **A movement variant preferred by 4 or more:** make it the default. Otherwise keep A and note the split.
- **Median time to first ending:** replace the product spec's "2–3 hours" with the measured number before any pricing.

Then add a dated line to `RELEASE_READINESS.md`: what was run, with which commit, by how many people, and the decisions taken.

## 8. Additions for this round (2026-10-29)

Since the protocol was written, the supporting cast changed (`../production/CHARACTERS.md`) and canon A–E was decided (`../CANON_DECISIONS.md` §7). Watch for, and tick on the sheet's margin:

- **Tobben:** after Rue talks to him, does the player watch him walk to the notice board? Do they catch him on the way (talk to him while he walks)? Later, do they notice his name crossed out on the board?
- **Mira:** in Arin's room, do they look at her table (her note, her cups) before she asks? After her errand, do they notice what changed on the table?
- **Pip:** do they wait for him? Do they notice him leading, resting or hiding behind Rue near Arin?
- **The Archivist:** after the CHARACTER FILE, do they find his new file on the desk?
- **The colours:** do they mention Rue's colours coming back? Ask afterwards: **"Did anything about how Rue looked change? What do you think that meant?"**
- **The memory card:** ask **"Before the festival started, what did you think was going to happen? Who typed the last line?"**
- **Travel (2026-10-30):** ask "Moving between places, did you know where you were going and why?" Watch whether they skip the passage card, and whether anyone leaves a map by accident.
