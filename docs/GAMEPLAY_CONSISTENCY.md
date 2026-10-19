# Gameplay consistency: the rules the player can trust

- **Branch:** `claude/last-save-file-prototype-ljwuq4`, stacked on PR #6 (`claude/review-fixes`, 701af0e)
- **Baseline at 701af0e:** 376 tests passed, 0 failed (`tests/run.sh`, Godot 4.3, headless).

**Verification labels:**
- **pass:** an automated test covers it and passes.
- **not run:** no automated or human check has been done.

## Findings

| # | Finding (state at 701af0e) | Fixed by | Test |
|---|---|---|---|
| A | Guidance ignored the truth route. With all five memories, the goal and Pip still pointed only at the ordinary exit; the CHARACTER FILE and the people with something to say went unmentioned | `Progression` (one read of the save, no new flags); a hint line under the goal; Pip leads to a witness or the file; the journal shows a summary | `test_progression_stages_follow_the_save`, `test_goal_keeps_the_way_out_and_adds_the_hint`, `test_pip_leads_*`: pass |
| B | Mira's escort exposure (+2.5 awareness a second) kept counting during dialogue, choices, scenes and PAUSE | `World.escort_exposed()`: passive exposure follows the modal hold, like every other passive source | `test_mira_escort_exposure_respects_reading_choices_and_pause`: pass |
| C | Leaving a body cleared the saved route memory, but the Arin already walking kept the old learned round until the next run | `Area.relearn_owner_routes()` → `OwnerAvatar.set_route()`: no jump, a valid next point, guard stop kept | `test_shedding_rebuilds_the_live_patrol`: pass |
| D | The hold prompt could say RELOADS for LEAVE THIS BODY, which never reloads; the prompt didn't say what it takes | `ActionPreview`: one description used by the prompt, the touch button, the charge and the commit; the commit re-checks and says why if it's no longer possible | `test_prompts_match_what_happens`: pass |
| E | The title read a recorded escape as RUE once the truth was learned later | `Title._after()` uses `last_ending` as recorded. Only saves with wins but no ending name read as an escape | `test_an_old_escape_stays_an_escape`: pass |
| F | The CHARACTER FILE gave the truth on any later `dialogue_closed`: walking away from it, or another conversation closing. Truth pieces counted when a conversation opened, before their line was shown | Truth: only the file, read to its last line (`World.conversation_completed`). Pieces: counted when their line is shown whole (`Hud.line_shown`); Pip's ledge on its last line | `test_the_truth_needs_the_whole_file`, `test_a_truth_piece_counts_when_its_line_is_shown`: pass |
| G | The body was placed 16 px from the helper without checking walls, furniture, gaps or bounds | `World.husk_spot()`: tries eight directions at two distances on open floor inside the area; else where she stood | `test_a_body_is_never_left_in_a_wall_or_off_the_edge`: pass |

## The rules

**Awareness, by source:**

| Source | Kind | While reading, answering, a scene or PAUSE |
|---|---|---|
| Time passing (area rate), an escort in view, being seen by Arin | Passive | Held |
| A glitch, a forced door, touching the owner's things | Direct action | Can't happen: input is held |
| Story consequences (a note on the board, a file restored) | Scripted | Applied when the script runs, at a point it chooses |

**When progress counts:**

| Progress | Counted when |
|---|---|
| A memory | Its cinematic has played (unchanged) |
| A truth piece (Mira, Wren, Tobben) | Its line has been shown whole. Walk away before it and it's said next time |
| Pip's first-hitbox piece | The ledge text's last line is shown |
| The truth | The CHARACTER FILE, shown whole, read to its last line |
| An ending | `last_ending` at the moment it happens; nothing later rewrites it |

**Guidance (Progression stages):**

| Stage | HUD goal | Pip | Journal |
|---|---|---|---|
| MEMORIES | Area goal | Memory here, else area way on | Memories n/5 |
| INVESTIGATE | Area goal + "someone who has watched you may have noticed something" | A person here with something to say | How many noticed, of how many needed |
| FILE | Area goal + "something on the Archivist's shelf has your name" | The CHARACTER FILE, in the Archive | "The file will read whole now" |
| KNOWN | Area goal + "Slot 2 is still north" (until RUE is done) | Area way on | "You read your CHARACTER FILE" |

The ordinary escape is open in every stage.

## Save compatibility

No saved field was added or renamed, so no migration is needed. Truth pieces already counted under the old rule stay counted. A save made between opening the file and finishing it (the old leak) keeps whatever it recorded.
