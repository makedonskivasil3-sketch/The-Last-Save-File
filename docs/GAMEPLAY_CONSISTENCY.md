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

## The player's journey, phase by phase (what this pass changed)

| Phase | What the player wants | What told them before | What tells them now |
|---|---|---|---|
| First launch, the room | Get out; understand who they are | Goal line, owner's note, act card | Same. The screen is clean, so the owner's first distortion is noticed; the prompt sits on the thing itself |
| Interaction and hiding | Know what [E] does here | A corner prompt, a generic hold label | The prompt above the target; the hold names its price, what it takes and whether it reloads (`ActionPreview`) |
| First escalation and failure | Know why it happened, and what persists | Death card with a tip (unchanged) | Unchanged. The card sits above the effects, so the tip is never distorted |
| Escorts | Not to be punished for reading | Exposure accrued while reading or answering | Exposure waits while reading, answering, in scenes and during PAUSE |
| All memories, the truth | Learn there's more without being told what | The goal pointed only at the exit | A quiet hint line; Pip noses toward whoever has something to say, then the file; the journal says how many have noticed |
| Shedding | See the cost and its consequences | Prompt could say RELOADS; Arin kept the old patrol; the body could sit in a wall | The prompt says what's taken; Arin forgets at once; the body lies on open floor |
| Endings and the title | The ending they got is the one remembered | Title could rewrite an escape as RUE | The ending as recorded; the slot shows her name once she remembers it |

**Bot coverage vs human play:**
- The four bots reach exact endings (escape, message, escape with purge, Wren), and focused tests cover RUE, unseen and overwrite.
- A human-equivalent playthrough of each ending: **not run**.

## Pass 3: moment-to-moment rules

**Threat line of sight (`OwnerAvatar.can_see`, `_blocked`).**
- Arin sees Rue only if a ray from Arin to Rue reaches her without crossing a wall, stall, furniture or any other solid on Rue's collision mask. People don't block sight.
- The drawn cone is the same rays (13 of them), clipped where they hit something. What the cone covers is what Arin can see; standing behind the stall is safe and looks safe.
- Covered by `tests/test_threat_fairness.gd`.

**Interaction targeting (`GlitchController._retarget`).**
- When two things in the world are both in reach, the target changes only after the new one has stayed best for 0.15 s, so the prompt and brackets don't flicker between them.
- Rue's own actions (PAUSE standing still, DECOY, PHASE at a wall) and losing the old target switch at once.
- A hold keeps the thing it started on. If that thing stops being valid mid-hold, the glitch fizzles instead of landing on something else.

**Escorts (`World._update_escort`, `Npc.follow`).**
- Steps taken within 16 px of her are forgotten, so fidgeting beside her isn't replayed.
- She takes the shortest way along the trail (skips ahead to the nearest of the next crumbs) and hurries, up to 96 px/s, when more than 24 px behind.
- If Rue PHASEs through a wall, the trail is cut; Rue says once that the companion can't follow. The companion waits until Rue is back beside her, within 40 px with nothing between them.
- After a door, she arrives just behind Rue on open floor, never inside a wall.

**Scenes always end cleanly.**
- Any scene (memory, the truth, Mira pinning her note) holds the owner exactly like reading does. Nobody dies, and awareness doesn't grow, while the player can't act.
- If the run ends during a scene's waits, the scene stops; nothing from it is recorded.
- Sound: each muffle has a source (pause menu, memory). The music opens only when every source has let go, so closing the pause menu during a memory no longer un-muffles it. A new run or the title screen clears every muffle and duck (`Sfx.reset_scene_state`).
- Covered by `tests/test_moment_safety.gd`.

**Noted, not changed:** a companion being escorted can't be talked to; tap focus ignores facing (it's sticky, so it doesn't flicker).
