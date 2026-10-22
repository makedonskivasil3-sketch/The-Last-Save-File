# Commercial direction (proposal)

**Everything commercial here is a hypothesis.** Price, length and sales
are not known. No market statistics, wishlist counts or revenue forecasts
are given, because none have been measured. No store page has been
published, no asset bought, and no public release deployed. Each of those
needs the owner's authorisation.

## 1. Pitch

> You've entered someone else's saved game. The people inside are slowly
> losing themselves, and they remember what you do. You might be able to
> escape, but leaving them behind means something now.

*The Last Save File* is a short psychological suspense game in a
pixel-art village that belongs to someone's abandoned save. The owner of
the save is still watching, and learns your habits. You hide, glitch the
save, and look after its people. Every death, kindness and broken promise
is kept, across runs.

## 2. Three promises

1. **They remember.** Wren, Mira and Tobben react to what they actually
   saw you do, in this run and in earlier ones. They do not react to what
   the script assumes.
2. **The owner adapts.** It learns where you hid and which way you went.
   It patches the seams you used and turns its lamp toward the shortcut
   you opened.
3. **Leaving costs something.** There is always a way out. Choosing who
   comes with you, and who doesn't, is the game.

## 3. Core loop (ten minutes, then repeated with variation)

Notice → investigate → glitch → avoid a readable threat → help someone →
keep a consequence.

- **Notice:** something isn't right; the well clicks with her two-tap
  gesture.
- **Investigate:** read, listen, and keep what you read in the journal.
- **Glitch:** PAUSE, FREEZE, UNLOCK, at a cost in owner attention.
- **Avoid:** Arin's view cone, the lamp's beam, and later the cursor and
  the static. Each is telegraphed, and each has shelter.
- **Help:** hide behind Wren, walk Mira out of her room, write Rue's name
  back into Tobben's guest book.
- **Keep:** relationship events, the chalk on the rim, the open gate,
  memories. These survive death; only Reset clears them.

## 4. Spoiler-safe demo endpoint (proposal)

**The demo ends under the Archive's arch, the first time Rue reaches it.**

The demo covers:
- the title and the interactive opening;
- Arin's room and Mira;
- the Square: Wren, the well and its words;
- the crossing and the lamp, with the shortcut optional;
- a first death and return, including Wren's chalk-mark scene if earned.

At the arch, the end card shows "still have my save?" and nothing more.

The demo withholds:
- the CHARACTER FILE;
- the Archivist;
- the Edge;
- Slot 2 and every ending;
- the Rue reveal.

**The endpoint is built behind a flag that is off by default.**
- It is switched on by the `demo` export feature, `-- --demo` or
  `?demo=1`. `World.DEMO_END_AREAS` turns the way into the Archive, the
  Bin or the Edge into the end card.
- `tests/test_demo.gd` checks the end card, that it costs nothing, and
  that nothing past the arch is reachable.
- Shipping a demo is still the author's decision (`CANON_DECISIONS.md`
  §5). No demo build has been exported or published.

## 5. Remaining scope to a commercial 1.0 (not estimated in hours)

| Area | Remaining |
|---|---|
| Story | The playable recognition in front of the CHARACTER FILE (`VERTICAL_SLICE.md` §4); author decisions on the canon flagged there |
| Places | The Archive, the Edge and Out of Bounds, each given the Square's treatment (subspaces, returns that reveal change). The camera now supports wider areas |
| Characters | Per-character changed interactions after a trust action, for Mira and Tobben (Wren now has hers) |
| Voice | Auditions (`VOICE_AUDITION.md`), then production and listening |
| Save | Save and Exit / Continue (`VERTICAL_SLICE.md` §6). Needs the owner's decision |
| Platforms | Windows gameplay on real hardware; controller hardware; Steam Deck (untested) |
| QA | Unfamiliar-player sessions (below), with fixes from them |
| Store | Capsule art, trailer and store text. None started; nothing published |

## 6. Asset and licensing inventory (in the repository today)

| Asset | Source | Licence | Shipped |
|---|---|---|---|
| Code, story, characters, art | This project | All rights reserved (`LICENSE`) | Yes |
| All graphics | Drawn in code (`scripts/art`, `scripts/fx`) | Project | Yes |
| All music and sound effects | Synthesised in code (`Sfx`, `MusicBox`) | Project | Yes |
| Inter (Regular, SemiBold) | rsms/inter | SIL OFL 1.1 (`assets/fonts/OFL-Inter.txt`) | Yes, credited |
| DejaVu Sans Mono | DejaVu fonts | Bitstream Vera licence (`assets/fonts/LICENSE-DejaVu.txt`) | Yes, credited |
| Godot Engine 4.3 | godotengine.org | MIT (credit required) | Yes |
| Generated voice takes (earlier pilot) | ElevenLabs free tier | Not licensed for commercial use | **No.** Git-excluded |
| Voice acting | — | — | None exists |

## 7. Cost model (structure, not a forecast)

Total cost = voice + art top-up + QA + platform + tools. Every input below
is a variable to fill in with real quotes.

| Item | Driver | How to price it |
|---|---|---|
| Voice, human | Lines × takes, or session hours × performers | Quotes from performers; about 250 lines in the manifest |
| Voice, generated (fallback) | Characters × takes | Plan price × months, from the plan page on the day |
| Playtesting | Sessions × participant fee | Local rate; five to eight sessions a round |
| Store | Platform fee | Steam Direct fee, from Steamworks |
| Hardware checks | Devices borrowed or bought | A Windows PC, a controller, optionally a Deck |
| Art | Optional portrait pass | Artist quote, against `CHARACTER_ART.md` briefs |

Revenue is deliberately not modelled: there is no data to base it on.

## 8. Unfamiliar-player sessions (plan)

**Who:** five to eight people who haven't seen the game. Fresh profile,
Windows build, one at a time, think-aloud welcome but not required. The
developer doesn't help unless the player is stuck for two minutes.

**Record two separate columns:**
- **Observations:** what the player did and said, timestamped.
- **Intentions:** what the player says they meant or expected, asked
  afterwards.

Never merge the columns, and never write a guess about intent as an
observation.

**Watch for (observation column):**
- the opening: do they move her before the hint? Do they press at 87%?
  Do they walk under PAUSE?
- the time to first movement in the room, and the time to the Square;
- every death: where it happened, what killed them, and whether the
  warning was on screen;
- whether they find the lane and lift the gate without being told;
- whether they hide under the awning or behind Wren;
- where they stop reading, skip, or open the journal.

**Ask afterwards (intention column, in this order, words written down
verbatim):**
1. What do you think happened in the opening?
2. Who is the small figure, as far as you can tell?
3. What was the owner trying to do?
4. When you died, did you know why? Could you have seen it coming?
5. Who in the village do you care about, if anyone? Why?
6. Was there a moment you wanted to stop? A moment you wanted to go on?
7. Would you play the next hour? What would you want to find out?

**Report:** per session, the two columns plus the death list. Across the
round, count how many players did each watched thing. No percentages
with fewer than five players.
