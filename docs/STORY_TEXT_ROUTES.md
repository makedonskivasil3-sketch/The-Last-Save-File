# Story text routes

Every way story text reaches the player, who advances it, how long it
stays, and what speaks it. The rules come from the code, not from intent:
each row names its entry point, and the "Tested by" column names the
regression that holds the rule. Read alongside `docs/STORY_PACING.md`
(reading-time formula, settings) and `docs/PRESENTATION_FUNCTIONALITY_AUDIT.md`
(A04, A05).

## The matrix

| Route | Entry point | Kind of text | Advance | Time on screen | Voice / speech | Pages | History | Holds threats | Tested by |
|---|---|---|---|---|---|---|---|---|---|
| Conversation box | `Hud.show_dialogue` | a person's lines (NPC, Rue, written notes) | Manual by default (press: reveal, then next); Auto (setting) waits for the reading time and for the take | Until advanced; Auto: `StoryPacing.reading_time` per page, or the take, whichever is longer | Recorded take (`VoiceOver`) if present, else device speech (`Narration`) if on; **never** for written or mute speakers (`dialogue_silent`) | `StoryPacing.pages(line, Hud.page_chars())`; one recorded take spans all its pages | yes, once per line | yes (story owns the screen) | `test_captions`, `test_story_pacing`, `test_character_states` |
| Scene (cinematic) | `Hud.cinematic` | narrated story beats, portraits | Manual (press), hold to skip the scene | as conversation | as conversation; a take carries across pages | as conversation | yes | yes | `test_captions`, `test_presentation_revision` |
| Question | `Hud.choose` | a decision | the player's choice | until chosen | none | no | the answer | yes | `test_story_pacing` (question hold) |
| Console: story | `Hud.say(text, "self" / "npc" / "owner")`, `OwnerDirector.say` | Rue's thoughts, people nearby, the owner talking | automatic, in order | the whole `reading_time`, never capped, never hurried by a backlog, never cut or overtaken by an owner line | owner lines type with the owner's blip; none spoken | no (wraps) | yes | no (waits while a conversation, scene or question is up) | `test_ambient_pacing` |
| Console: telemetry | `Hud.say(text, "system")` | counters and file events (`MEMORY RECOVERED 2 / 5`, `wren.npc deleted`) | automatic | `min(reading_time, 6 s)`; `MIN_TIME` each once 3 more lines are waiting | none | no | yes | no | `test_ambient_pacing`, `test_story_pacing` |
| Owner warning strip | `Hud.warn`, `OwnerDirector.warn` | urgent: something is about to happen to Rue | none (shown at once, over everything) | `max(2.5 s, reading_time)` then fades; taken down early when the threat ends (`cancel_warning`) | owner blip | no | yes, once | it *is* the threat's notice | `test_ambient_pacing` (urgent warnings never queue), owner tests |
| Objective | `Hud.show_objective` | the current goal | automatic | `reading_time + 3 s`; paused (not lost) while any story route or prompt covers it | none | no | no | no | `test_story_pacing` (goal shows when it changes) |
| Tip card | `Hud.show_tip` | controls / how-to | dismissed by the tutorial | until dismissed | none | no | no | no | tutorial tests |
| Act / area card | `Hud.show_act`, `Hud.show_area_title` | chapter and place names | automatic | 2.8 s / 1.6 s | stinger | no | no | yes (act card) | protection-policy tests |
| Death / ending overlay | `Hud.show_death`, `Hud.show_overlay` | what happened, what was kept | press | until pressed | none | no | no | n/a | death and ending tests |

## Owner priority

The owner's console lines go ahead of **telemetry** still queued (in order
among themselves), and may cut the pause after a telemetry line down to
`StoryPacing.OWNER_GAP` (0.8 s). They neither overtake nor cut short a
**story** line: a thought or another person's line keeps its place and is
read in full. (Rue's thoughts often carry the way out: on a run after a
death, "the door's gone" was arriving after the owner's taunts at ~30 s;
keeping story order brings it forward. `test_cohesion_story` holds it.)
Anything urgent is not in the console at all: it is the warning strip
(`Hud.warn`), shown at once whatever is open.

## Why the console split exists

Before this change, `StoryPacing.ambient_time` capped every console line at
6 s, and any queued owner line cut the current pause to 0.8 s. A 180-character
thought (reading time about 11.8 s at normal speed) therefore stayed the
newest line for at most 6 s, or 0.8 s if the owner spoke. The baseline
probe in `tests/test_ambient_pacing.gd` failed 8 assertions on those two
points before the fix. The History still holds every line, but the History
is for recovering a line, not for reading it the first time.

## What this does not establish

These are timing rules. Nobody has measured whether real players find the
console comfortable to read at these times, and no human test has done so.
The first-minutes sheet in `docs/PLAYTEST_PLAN.md` is where that question
belongs.
