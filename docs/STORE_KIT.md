# Store and demo kit (draft, 24 October 2026; feature claims corrected 3 November 2026)

**Nothing here is published.** No store page, trailer or capsule exists
outside this repository. Every image named below is a capture of the game
as it is now. No awards, quotes, sales figures, forecasts or playtime are
claimed, because none exist. The game's length has not been measured with
players.

## Pitch (one paragraph)

> Rue is a game character whose player moved away. Three years later the
> save is loaded again, and she is still running, in a village that
> belongs to someone else. The owner wants her gone. The people in the
> village remember what she does for them. Hide, glitch the save, look
> after its people, and find out what you are, and whether that changes
> where you go.

**Short (store capsule line):** *A game character left running in an
abandoned save, and the people who remember her.*

## Three promises (from `COMMERCIAL_DIRECTION.md`, kept)

1. **They remember.** Wren, Mira and Tobben react to what they actually
   saw you do, in this run and in earlier ones.
2. **The owner adapts.** It learns where you hid and which way you went,
   and patches what you used.
3. **Leaving costs something.** There is always a way out. Choosing who
   comes with you is the game.

## Feature list (each item is in the build)

- A playable prologue, the Lantern Festival: you play the second player
  beside the first; both leave, and the fifth lantern is lit with nobody
  holding a controller. One keyboard, controller or touchscreen: the two
  players are part of the story, not local co-op.
- Eight connected places: Arin's room, the village square, Arin's house,
  under the well, the Archive, the lantern workshop, the Recycle Bin and
  the Edge.
- Stealth you can read: view cones, a lamp, the owner's cursor and the
  static. Each is telegraphed and each has shelter.
- Ten glitch powers, each with a cost; memories unlock six of them.
- Characters with memory. Relationship events persist across deaths and
  are shown in the journal as seen, said or unknown.
- An owner that adapts to the routes, hiding spots and seams you used.
- Five memories, a CHARACTER FILE, and six endings. One needs the truth;
  an ordinary escape doesn't.
- Accessibility: text size and speed, auto-advance, reduced flashing and
  motion, captions with speaker labels, remappable keys and pad buttons,
  an Owner pace setting. Touch controls exist in the browser build only,
  as an experimental playtest feature.
- No voice acting: dialogue is written, with procedural voice blips.
  Optional system narration reads text aloud where the device offers it.
- Platforms to claim: Windows only, once it has been run and finished on
  real hardware. Linux, Steam Deck and browser only after their own tests.
- Every graphic, sound and piece of music is made in code, with no
  third-party art.

## Is the demo endpoint enough? (evaluation)

**Update, 3 November 2026:** there are two demo behaviours in the build.
`?demo=1` / `--demo` ends under the Archive's arch. The candidate,
`?demo=workshop` / `--demo=workshop`, ends after the workshop repair and
Wren noticing the light. Its ways to the Archive, Bin and Edge stay shut
with a line pointing back to the mission, so a wrong turn can't end it
early. Choose one after a player round. The table below evaluates the arch.

The demo ends under the Archive's arch (`COMMERCIAL_DIRECTION.md` §4).

| Promise | Shown before the arch? | Evidence in the demo |
|---|---|---|
| They remember | **Yes, if the player dies once.** Wren's reunion after a death, the chalk mark at the well. Mira after being walked out | Relationship events, `test_demo.gd` reachability |
| The owner adapts | **Partly.** Patched seams and the lamp's turn show on a second run. A player who never dies sees only the first owner moves | — |
| Leaving costs something | **Weakly.** Mira's note can be lost if Rue dies while Mira is with her. No choice about who comes along is reached | — |

**Verdict:** the endpoint shows the premise and the first promise well,
the second only to players who retry, and the third barely. **Options for
the author (not built):**

- (a) keep the arch, and add the owner's adapted patrol to the demo's
  second run, which is already in the build, to the trailer instead;
- (b) move the end past the Archivist's first exchange (the pointer). It
  shows a choice-shaped goal (Slot 2) without the Edge or any ending;
- (c) keep it as is and say plainly on the page that the demo is the
  first act.

## Trailer storyboard (gameplay first, readable without sound)

**Stale shots (3 November 2026):** shots that name the two-controller
opening (`after_o1_two_players.jpg`, `after_o2b_saving.jpg`) show the
discarded animatic. Recapture them from the festival prologue before any
trailer cut. Screenshots must show the shipped game.

Every shot is a scene that exists. On-screen words are the game's own text
(cards, captions, the console). The trailer needs no voice-over and works
muted. Length target: 60–75 s. Not cut, and nothing rendered.

| # | Shot (source) | On screen | Reads without sound because |
|---|---|---|---|
| 1 | Opening: two figures, two controllers (`after_o1_two_players.jpg`) | P1 · ARIN, P2 | The tags |
| 2 | The shared routine: both at the save point, the hop (`after_o2b_saving.jpg`) | SAVING SLOT 2 | The bar |
| 3 | 87%, the hands leave (`after_o4_stuck_87.jpg`) | 87% | The stopped bar |
| 4 | PAUSE: she walks anyway (`after_o5_paused_she_walks.jpg`) | "[her hands are still. she moves anyway.]" | The caption |
| 5 | Black card: "months later", then her message (`after_o7b_months_later.jpg`, `after_o8_unfinished.jpg`) | "still have my save?" | The text |
| 6 | Boot: `PLAYER 2 . . . [DELETED 3 YEARS AGO]`, `slot 02 does not exist.` | Boot log | The log |
| 7 | Arin's room: Rue, "you" over her, the first step (`world_after_02_first_room.jpg`) | "you" | The cue |
| 8 | The square: Arin's cone sweeps; Wren waves "here!", Rue crouches beside her, HIDDEN · WREN COVERS YOU | Status line | The status line |
| 9 | The lamp and the shortcut (`world_after_04_square_east_crossing.jpg`) | The beam | Motion |
| 10 | Death and return: the death card; the chalk mark on the rim (`docs/review/oct22/motion_death_return.mp4`) | The card | The card text |
| 11 | Mira pins her note: "MIRA WAS HERE. I TALK. I REMEMBER." | The board | The note |
| 12 | Tobben's guest book: "two names, two handwritings" | The scene card | The text |
| 13 | The Archive (`world_after_06_archive.jpg`) | THE ARCHIVE · CUT CONTENT | The area card |
| 14 | The owner's hand on the north road; the static at the Edge | — | Motion, colour |
| 15 | Title card | THE LAST SAVE FILE | — |

Withheld from the trailer: the CHARACTER FILE, the truth, every ending,
Slot 2's choice.

## Refresh, 3 November 2026 (implementation brief §13)

**Positioning hypothesis, to test with players, not assume:** a story-driven escape adventure about a forgotten character trying to survive in someone else's save. The commercial asset is the relationship between player, character and save, not graphics or volume of content.

**One-sentence hook:** *You are the character someone left running. The save is being cleared.*

**What the screenshots must show** (every one from the current build, `docs/review/calibration_2026-11-03/`, re-captured at 1920×1080 from a release export before any store use):
1. Control: Rue in Arin's room, the first exit in view (`area_room.jpg`).
2. Exploration: the Square around the well and the fifth lantern (`area_square.jpg`).
3. A readable threat: the Edge unloading, the cursor and Slot 2 (`area_edge.jpg`).
4. A character's response and a consequence: the workshop's repaired light running to the hatch (`cal_workshop_repaired_before_after.jpg`, right half).
5. A colder system space: the Recycle Bin (`area_bin.jpg`).

No identity truth or final choice in any image.

**Demo to full game:** the workshop candidate ends after Wren notices the light (DM-2); its save is separate from the full game's. The full game starts its own save; nothing is carried over, so nobody replays the tutorial to buy, and nobody is told they will keep demo progress.

**Price:** not set. It waits for measured human campaign length, finish quality and a current comparable list. Scenarios, when made, are low, base and high, with stated assumptions and net receipts after platform share, refunds and tax. No forecast is claimed.

## Screenshot shortlist (5, existing captures; superseded by the refresh above)

1. `docs/review/opening/after_o5_paused_she_walks.jpg`: the premise in one
   frame.
2. `docs/review/opening/world_after_03_square_west.jpg`: the village and
   its people.
3. `docs/review/opening/world_after_04_square_east_crossing.jpg`: the
   stealth.
4. `docs/review/opening/world_after_06_archive.jpg`: the Archive.
5. `docs/review/opening/world_after_10_bin_shelter.jpg`: a colder system
   space.

Before any store use, re-capture these at 1920×1080 from a release export,
with the debug overlay off.

## Capsule art brief

- **Subject:** Rue, small, cyan, half-restored (scarf red, face still a
  void), standing on the cobbles at the well. Behind her, out of focus, a
  village at warm afternoon light. Across the top edge, a cold blue strip
  of the save UI: `SLOT 2 · ??? · LV 1`.
- **Feeling:** something left on, alone, being looked at.
- **Palette:** the game's own. Warm village, Rue's cyan, one restrained
  red accent (the owner). No neon, no horror gore.
- **Type:** the title in the game's UI face (Inter SemiBold), set like a
  save-slot label.
- **Must read at the smallest capsule size:** the cyan figure and the
  title. Nothing else is required.
- **Art source:** the in-game procedural art may be enough for a first
  capsule. A commissioned painting needs a brief, a quote and a rights
  agreement. None has been made.
