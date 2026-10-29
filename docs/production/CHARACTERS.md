# The supporting cast: what each one does, wants and shows (2026-10-29)

**Why this document:** the author asked for more development for the characters that weren't built enough, with attention to detail and graphics. Wren had a full arc (`WREN_ARC.md`); the others mostly spoke. The rule for this pass: **a character is developed by what they do where the player can see it, not by more lines.** Each change below is something visible in the world, with a test, and it changes no canon (`TRUTH_TABLE.md`).

Code comments that say "docs/production/CHARACTERS.md" point here.

## Tobben, the shopkeeper who reports you

**Want:** to keep his stall and his place in the script. **Fear:** being the one who's taken out. **Contradiction:** he reports Rue because he's written to, and he's ashamed of it.

| What you see | How it works | Test |
|---|---|---|
| After Rue talks to him, he **hesitates** ("pen in hand", 1.6 s), then **walks** to the notice board and writes `SEEN NEAR THE STALL. —T.` | `VillageSquare._tobben_reports()`, `_walk_tobben()`; the report lands only when he gets there (`REPORT_DELAY` 7 s) | `test_tobben.gd` |
| Rue can **catch him on the way**. He's embarrassed: "I was just... going for a walk. Towards the board. Not to write anything on it. ...It's in my script. It isn't in me." | `_tobben_caught()`; relationship event `tobben.caught` | `test_tobben.gd` |
| After the guest book, he **scratches his own name off** the board ("TELL xxxxxx"), and it stays crossed out in later runs | `_tobben_at_board()`; event `tobben.crossed_out` | `test_tobben.gd` |
| **His stall, redrawn:** posts, a scalloped awning, baskets, scales, a till, a price slate, and the festival's fireworks still in their box under the counter | `VillageSquare.draw_stall()` | `tour_characters` (c01–c03) |

## Mira, who waits in Arin's room

**Want:** to be seen; her note on the board is how. **Fear:** being restricted (the owner's selection box). **Detail:** she was "the only colour in that room".

| What you see | How it works | Test |
|---|---|---|
| **Her corner:** a small round table with two cups (one steaming). Before she asks, her note is on it, folded in four, FOR THE BOARD. Rue can look at it but won't open it: "(it isn't mine to open.)" | `MiraCorner` (`scripts/world/mira_corner.gd`); readable "MIRA'S NOTE" | `test_mira_corner.gd` |
| **Her story leaves things behind:** carried (the note is gone); pinned (one cup moved to the windowsill, and **she stands at the window** watching the square); lost (one cup upside down, a blank sheet she never wrote on); reset (two clean cups: she doesn't know Rue) | `MiraCorner.quest`; `ArinsRoom.MIRA_WINDOW` | `test_mira_corner.gd`; `tour_characters` (m01–m03) |
| **Restricted by the owner:** a dashed editor's selection box, with handles, round where she stands | `MiraCorner.kept` | `tour_characters` (m04) |

## Pip, the fox nobody saved

**Want:** to stay near Rue. **Fear:** Arin. **Detail:** a companion, not a route arrow.

| What you see | How it works | Test |
|---|---|---|
| He **leads only once per long stop** (after 12 s still), for about 2.5 s, then gives up and waits | `Companion.HESITATE`, `_led_this_stop` | `test_pip.gd` |
| When Arin comes near he **hides behind Rue**, on the side away from Arin, ears flat, crouched low | `_afraid` (ears lerp back, body lowers 1.4 px) | `test_pip.gd`; `tour_characters` (p02) |
| When she stays still a while, he **lies down** and rests | `resting()`, `_draw_resting()` | `test_pip.gd`; `tour_characters` (p01) |

## The Archivist, who keeps records

**Want:** to file things properly. **Change:** he learns Rue is a person, not a record.

| What you see | How it works | Test |
|---|---|---|
| Once, while Rue is **partly coloured**, he says what the colours are: "Colours are what someone chose for you. You're getting yours back one at a time. Interesting that they're hers." (canon A, E) | `ArchiveArea.ARCHIVIST_COLOURS`, said once (`archivist.colours`) | `test_archivist_file.gd` |
| After she reads the CHARACTER FILE, **he starts a new file** on his desk: a manila folder, RUE on the tab. Inside: "NAME: RUE. FILED UNDER: PEOPLE. (Not under CHARACTERS. That drawer is the other side of the room.)" and a blank page "he has left for you". What he does says what he thinks; he doesn't make a speech of it | `NEW_FILE_TITLE`, `NEW_FILE_LINES`; the folder in `_paint` | `test_archivist_file.gd`; `tour_characters` (a01) |

## The Owner, who means to clean up

**Want:** to close the door (canon C). **Contradiction:** he plays once more because he can't stop wanting to be nine.

| What you see | How it works | Test |
|---|---|---|
| The cold open's last line: "> one more go. then i'm cleaning it up." | `ColdOpen.LINES` | `test_cold_open.gd` |
| Two new notes among his in the Archive: "mum's house is sold. everything in the loft goes in the van on friday. the console too, once i've cleaned it up." and "when i play arin i'm nine again. when i stop, i'm in an empty house full of boxes." | `Story.OWNER_NOTES` | `test_story*`, `test_dark_truth` (all pass) |

## Rue, and the colour she picks

**Change across the game:** from inherited habits to her own choices (`CANON_PROPOSAL_2026-10-28.md` §2).

| What you see | How it works | Test |
|---|---|---|
| In the `rue` ending she picks **one colour nobody chose for her**, a lilac nobody in the cast wears, and wears it from then on: **a small flower clip in her hair**, in the world and on the title screen. The owner's flicker takes it away with the rest | `Player.OWN`, `Player.chose_own()`, `HeroFigure._own_clip()`, `Story.RUE_OWN_COLOUR` | `test_own_colour.gd`; `tour_characters` (r01) |

## What this pass did not do

- **No new art assets, no voices, nothing bought.** All of the above is code-drawn, like the rest of the game, and provisional by `PRODUCTION_STANDARD.md`.
- **Arin stays mute.** Wren's arc is unchanged (`WREN_ARC.md`).
- **Unverified with people:** whether players notice any of this. The playtest kit asks (`../playtest/RUN_A_ROUND.md` §8).
