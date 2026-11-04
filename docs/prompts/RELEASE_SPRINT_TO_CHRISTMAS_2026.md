# Release sprint: ship THE LAST SAVE FILE before Christmas 2026

**Written 2026-10-30 for the next working sessions.** This brief replaces every earlier pass prompt. Paste it as the session's task. Check each external date against Valve's own documentation on the day you act on it.

## Where the game is (measured, not hoped)

**Built:**
- **Code:** a Godot 4.3 game.
  - 30k lines of game code in 102 scripts, plus 18.5k lines of tests (809 tests).
  - The full suite passes, and six ending bots finish the game.
- **Content:**
  - a playable prologue (the festival);
  - seven maps;
  - six endings;
  - the Owner as a threat system;
  - Wren's relationship, a supporting cast with visible behaviour, and a journal.
- **Builds:** Windows, Linux and web export in CI. The web build plays in a browser.
- **Player options:**
  - saves are transactional;
  - stopping at calm moments is free;
  - keyboard and pad remapping;
  - accessibility settings, including reduced motion, reduced flashing, Owner pace and text size;
  - "Report a problem";
  - a build stamp.

**Not proven:**
- **Players:** **No unfamiliar person has played it. Zero playtests.**
- **Platforms:** never run on Windows or a Steam Deck, and never tried with a physical controller.
- **Length:** unmeasured. The critical path is about 2.5 minutes of travel, and the rest is reading. The first ending is probably 30–60 minutes; that's a guess.
- **Art:** all code-drawn, consistent but plainly "programmer art". There's no capsule art, key art or trailer.
- **Audio:** synthesised (a music box, drones, beeps). No recorded music or voice.
- **Market:** no store page, no wishlists, no community, no press.

**The process problem:** the project has 189,000 words of documentation (56 MB in `docs/`) and no player evidence. That ratio has to flip. **From now on, every day must produce something a player sees or a fact about players.**

## The decision this sprint is built around

There are two honest routes. **The author picks one on day 1**; this brief plans route A and notes where B differs.

**A. Release before Christmas (the author's stated goal).**
- **Steam:**
  - **Release on Thursday 10 December 2026.** The Steam Winter Sale runs 17 December to 4 January and buries new releases.
  - Use itch.io as well, or only itch.io, if the Steam deadlines are missed.
- **Expectation:** launching with few wishlists, the realistic outcome is **dozens to low hundreds of sales**. It's a proof of release, reviews and a portfolio, not a revenue event.

**B. Page before Christmas, launch with a demo at the February 2027 Steam Next Fest.**
- **Before Christmas:** a store page and a free demo (the demo endpoint already exists behind a flag).
- **Release:** in the weeks after Next Fest.
- **Expectation:** commercially much stronger, because wishlists drive the launch week. **It misses the "released by Christmas" goal.**

**Recommendation:** route B if revenue matters, route A if releasing by Christmas matters more. Either way, the store page must go up within three weeks.

## Hard external deadlines for route A (author actions; Claude cannot pay, sign or publish)

| By | What | Why |
|---|---|---|
| **Fri 6 Nov** | Create the Steamworks partner account, pay the **$100 Steam Direct fee**, finish the tax and bank forms | Several sources state a 30-day wait between paying and releasing (one says 21). Plan on 30 |
| **Fri 13 Nov** | Choose a capsule and key-art artist, or a licensed asset approach | The store page can't go up without capsule images |
| **Fri 20 Nov** | Store page live as **Coming Soon**: capsule, 5+ screenshots, a short trailer, description, tags | Valve requires at least two weeks of Coming Soon before release |
| **Tue 1 Dec** | Release build uploaded and **submitted for review** | Reviews take a few days; leave time for one rejection |
| **Thu 10 Dec** | **Release** on Steam and itch.io | A week before the Winter Sale |

## The sprint, week by week (Claude's work, in the repo)

Run every week the same way:
1. Build the week's items.
2. Run the strict suite and the bots.
3. Publish the web build.
4. Ship a playtest build to real people.
5. Read their reports ("Report a problem" + `RUN_A_ROUND.md`).
6. Fix the top three.

Write **no new design documents.** Update only:
- `RELEASE_READINESS.md` (one short section per week);
- `ISSUE_REGISTER.md`;
- a single `docs/RELEASE_CHECKLIST.md` (create it).

### Week 1 (2–8 Nov): lock scope, modernise the base, get players
- **Freeze scope.** Nothing new except what this brief lists. The seven maps and six endings are the game.
- **Engine:** time-box **one day** to move from Godot 4.3 to the current stable 4.x.
  - Only if the full suite, the bots and the web export all pass on it.
  - If it doesn't pass in a day, stay on 4.3. Don't upgrade later in the sprint.
- **Steam Deck / 16:10:**
  - Run at 1280×800.
  - Check the HUD, the passage card and the menus there.
  - Make the controller the default prompt on Deck.
- **Windows:** the author, or a friend, runs the Windows build end to end (`WINDOWS_PLAYTEST.txt`). Fix any crash first.
- **Playtests:** five people play the web build with `?playtest=1`, and the author collects reports. **This is the most important item of the sprint.**
- **Docs weight:** move `docs/review/` captures and old pass notes out of the repo (an archive branch or release asset). The working tree should hold only what governs.

### Week 2 (9–15 Nov): fix what players hit; make it look like a product
- Fix the top problems from playtest round 1:
  - confusion about where to go;
  - unfair deaths;
  - text they skipped;
  - the passage card if it annoys.
- **Measure the first-ending time** from the playtest logs. Write it in `RELEASE_CHECKLIST.md`. Price from it (below).
- **Visual modernisation, without new art assets:**
  - **Lighting:** a consistent palette pass per map, with a warm key light and a cool Owner light. Use the existing light system.
  - **Post-processing:** a subtle, optional CRT and colour grade, consistent across maps.
  - **Effects:** particles on interactions (memory pick-ups, saves, the lantern).
  - **UI:** screen-shake and hit-stop budgets reviewed; menus with consistent animated focus; a new-looking title screen.
- **Character art, decided by the author:**
  - (a) commission sprite sheets for Rue, Arin, Wren, Mira and Tobben through the existing `CharacterSheet` pipeline (`docs/ART_BIBLE.md`, `PRODUCTION_STANDARD.md`); or
  - (b) keep the code-drawn cast and polish it.
  - Option (a) needs the brief sent by 9 Nov to land by 1 Dec.

### Week 3 (16–22 Nov): store page, trailer, second playtest round
- **Screenshots:** 6 at 1920×1080, captured from the real game with the tour harness, from the best moments:
  - the festival;
  - the square at dusk;
  - Wren's chalk;
  - a passage card;
  - the Edge;
  - an ending.
- **Trailer:** 45–60 s, captured in-game. Use `docs/TRAILER_*` if present; otherwise:
  - hook (the memory card);
  - premise (you're a character left running);
  - threat (the Owner);
  - people (Wren);
  - stakes (Slot 2);
  - title card.
- **Store text:**
  - a short description (≤300 characters);
  - a long description;
  - tags: narrative, short, atmospheric, pixel graphics, horror-lite, emotional;
  - content descriptors;
  - an honest playtime.
- **Playtest round 2:** five new people, on the build with the round-1 fixes.

### Week 4 (23–29 Nov): content polish where players dropped off
- **Spend this week only where round 2 shows boredom or confusion.** Likely candidates:
  - the first ten minutes;
  - the Archive's exposition;
  - the Edge's difficulty.
- **Optional, only if time:**
  - **Steam achievements** for the six endings and finding Pip, via GodotSteam.
  - **Steam Cloud** through Auto-Cloud on `user://`. No code.
- **Localisation:** none for launch. English only, stated on the store page.

### Week 5 (30 Nov – 6 Dec): release candidate
- **RC1 by 1 Dec:**
  - full suite;
  - bots ×3;
  - exports;
  - browser checks;
  - a Windows run;
  - a Deck run (if available).
- **Submit the build for review.**
- **From here, bug fixes only.** Any change needs a test and a passing suite.
- **Prepare:**
  - a launch announcement;
  - an itch.io page from the same assets;
  - a press kit (`presskit()` style: facts, screenshots, trailer, contact).

### Week 6 (7–13 Dec): launch
- **Launch on 10 December.**
- **Watch** reviews, crash reports and "Report a problem".
- **Patch 1.0.1 within 72 hours** if needed.

## Commercial frame (provisional; replace with real numbers)

- **Price:** set it from the measured length and from comparable short narrative games.
  - Under 1 hour: $3.99–4.99.
  - 1–2 hours with replayable endings: $5.99–7.99.
  - **Don't price from the old "2–3 hours" estimate.**
- **Launch discount:** 10–15% for the first week.
- **Assets:**
  - **Rights inventory:** fonts are OFL/DejaVu (fine).
  - **Voices:** no AI or other voices without commercial rights and the author's consent.
  - **Commissioned art:** written assignment of rights.
- **Revenue expectation:** say it plainly in `RELEASE_CHECKLIST.md`. Without wishlists, a December launch is small. The value is the shipped game, its reviews and the next project.

## Rules that stay

- **Canon:** `CANON_DECISIONS.md` and `TRUTH_TABLE.md` stand.
- **Never:**
  - weaken a test;
  - hide a warning;
  - claim verification you didn't do;
  - spend money, publish or sign anything without the author.
- **Git:** one branch per week, merged after CI is green and the author says merge.
- **Every claim names a commit.**
