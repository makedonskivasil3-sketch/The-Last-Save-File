# Opening, characters and world revision (review of `59d4d21`)

**Started from** `59d4d21` (`claude/last-save-file-prototype-ljwuq4`).
`main` is `09aeb3b`; PR #10 is an open draft, not merged.

**Canon:** the author decided `CANON_DECISIONS.md` §1 on 2026-10-22. It
is `main`'s premise: Rue is the game character left running after her
player moved away. The opening follows the author's direction: a
character beginning to act after her player stops. She is introduced
through a gesture she inherited, and later makes one entirely her own.

## Evidence ledger

| Kind | Item | Evidence | Status |
|---|---|---|---|
| Confirmed defect | A controller reconnecting released a focus hold (`_pad_resumed()` called the focus-in handler) | `test_a_reconnected_controller_does_not_bring_back_the_window` failed on `59d4d21` | **Fixed** (`451a47e`) |
| Confirmed defect | Unplugging any pad paused the film or the game, even an unused one; an unrelated pad plugged in "resumed" a lost one | Three regressions failed | **Fixed**: `Settings.active_pad`; only the player's pad counts |
| Confirmed defect | An end card held for a lost controller was released by focus coming back | Regression failed | **Fixed**: separate `_pad_paused` |
| Confirmed defect | Releases between `TAP` (0.3 s) and `SKIP_HOLD` (0.7 s) did nothing | Releases at 0.35, 0.5 and 0.6 s and a 0.5 s click failed | **Fixed**: one rule. Let go before the skip completes and it acts; held to the end it skips, and only skips |
| Confirmed defect | Rumble went to every connected pad | Source | **Fixed**: the player's pad only |
| Confirmed defect | The Archivist's one-time remarks were marked said while being chosen, and his introduction was consumed on opening | Four regressions failed | **Fixed** (`2779940`): `after` callables and `archivist.introduced`, committed on reading. The pointer stays an immediate, shown grant |
| Confirmed defect (found in this pass) | In the opening, holding right walked her straight past the save point and Arin; a press there then only played the habit | Motion capture | **Fixed**: the save point catches her during the ritual |
| Design weakness | Nothing tied a controller to a figure: the labels sat in the TV's top corners, and both controllers had the same red light | Captures | **Addressed** (below) |
| Design weakness | The months-later jump was only a caption | Captures | **Addressed**: a black "months later" card |
| Design weakness | Under PAUSE nothing showed that the controller had stopped driving her | Captures | **Addressed**: her light goes out, her tag fades, "you" moves onto the figure |
| Hypothesis | Five seconds before the first hint is right | — | **Untested.** "you · move" now shows as soon as a state asks, so the essential control no longer waits on it |
| Already fixed (earlier) | Journal overclaim, lamp and gate, OOB flashing, Bin region, FIRST HITBOX, chime, caption resume, independent RNG, bot replanning | Earlier tests | Kept; not redone |

Audit of other selection-time counters: Wren's and Mira's ambient lines
advance when chosen. Each is a single page, shown as the box opens, so
nothing unread is lost. They are unchanged.

## Opening storyboard (after)

Frames are in `docs/review/opening/` (`before_*.jpg` at `59d4d21`,
`after_*.jpg` now). The motion clip is
`docs/review/opening/motion_opening.mp4`: game time at 10 frames a second,
human-paced input.

| Beat | Film time | What is on screen | The one question it answers |
|---|---|---|---|
| 1. Two players | 0–5 s | Two figures on the TV, each tagged with its controller (blue **P1 · ARIN**, amber **P2**); below, two pairs of hands, each controller lit in its colour | Who is who? |
| 2. Ritual | holds at 5 s | Arin walks to the save point first, turns and waits for her. Her controller shows **you · move**, from the first moment, before any hint | Which one do I drive, and how? |
| 2b. Together | on the press | She stops on the save point beside him. Her two taps and the press (her habit), and the two figures hop once together. SAVING SLOT 2 | Their routine |
| 3. Interruption | holds at 10.8 s | 87%. The same press, refused. P1's hands leave; hers go slack, and her light goes out | Something broke |
| 4. Impossible action | holds at 23 s | PAUSE. Her controller is dark and her tag fades. **you · move** lifts from the controller onto the figure. She walks when the player moves: "[her hands are still. she moves anyway.]" | What changed? Nobody holds her, and she moves |
| 5. The well | 29 s | A well where none should be; the music box, one note missing | — |
| 6. She looks out | 33–37 s | She turns to the hands. Her colours waver | — |
| 7. Months later | 37.3–38.9 s | Black. "months later" | When are we? |
| 8. Her message | 38.5–45 s | "still have my save?"; the owner's reply stops mid-word | — |
| Room | handoff | The same figure, now in Arin's room, with **you** over her until the first step (first run only, watched or skipped) | Am I still her? |

## Control and knowledge map

| Moment | The player controls | The player knows | Deliberately unknown |
|---|---|---|---|
| Ritual | The amber figure, through the amber controller | The two figures belong to two players. Theirs is P2 | Her name. Who the girl is |
| Interruption | The press | The save failed. P1 left. P2's player fell asleep | Why it hung |
| Impossible action | The figure itself (the controller is dark) | She moves with no one holding her | What she is (the CHARACTER FILE, much later) |
| Months later | — | Time passed; the girl wrote; the owner didn't answer | Whether the girl still asks |
| Room | Rue | It's the same figure, changed | Her name (the memories) |

The two controllers are story objects. The game is single-player. One
keyboard, one pad or touch is enough, and nothing asks for a second
controller.

## No-input, prompt, hesitant and replay paths

| Path | What happens | Evidence |
|---|---|---|
| No input | Each state shows its hint after 5 s, then plays itself (autopilot, logged as "played itself") | `test_waiting_shows_what_to_do_then_the_hands_do_it`, PlaytestLog |
| Prompt | Arin is at the save point before she can be | `test_who_holds_what_reads_before_any_hint` |
| Hesitant or slow presses | Any release before the skip completes presses | `test_a_slow_press_still_presses`, `test_a_slow_click…` |
| Held right, too long | The save point catches her | `test_the_save_point_catches_her_on_the_way_past` |
| Skip | Hold to the end; the room's **you** cue still shows which one is her | `test_the_first_room_says_which_one_is_you_until_she_moves` |
| Replay | From the title, back to the title | Existing tests |

## Limits

- No unfamiliar player has seen it. Whether two controllers imply co-op,
  and what people think happened at 87% and under PAUSE, are the first
  questions of the playtest round (`PLAYTEST_PLAN.md`).
- Input was injected, not played on hardware: no real pad was unplugged.

## Character experience matrix

**Implemented** means it is in the game at this head (new in this pass
where marked). **Proposed** means it is not built.

| Character | First sight | Distinctive action | Immediate want | Fear | Contradiction | Player choice | Consequence | Return beat | Optional revelation | Ending relevance |
|---|---|---|---|---|---|---|---|---|---|---|
| **Rue** | The amber figure in the opening; **you** over her in the room (**new**) | The girl's two-tap habit (inherited). At Slot 2, knowing what she is: **one press, her own** (**new**: "(one press. not her two taps. mine.)") | Get out of Arin's room; then out of the owner's reach | Being overwritten again | Made of someone else's attention; acts on her own | Every route; whom she helps; which ending | Colour restored with memories; borrowed pieces | Waking again; the well's chalk mark | The CHARACTER FILE | All six; RUE needs the truth |
| **Mira** | In her corner at her two cups, **tending them** (**new**: her routine shown before any request) | Keeps her room; writes a note for the board | To be seen ("I talk. I remember.") | Being reset | Notices Rue moves when nobody holds her, but can't leave her room alone | Walk her to the square, or not | The note pinned (the board changes) or lost; reset; restoration | Her conversations by event (Relationships) | "So who's holding you?" (a truth piece) | The message ending clears her fate |
| **Wren** | Hopping in the square | Shelters Rue beside her ("the owner can't see what I'm standing beside") | To see the Edge | Being taken out of the save | Cut content who wants to finish | The promise; the escort | Sheltering is recorded only when it happened, and concealment only when Arin's look reached Rue | The chalk mark at the well after a death (her action) | "Nobody plays me…" | The Wren ending |
| **Tobben** | At his stall, **tending his wares** (previous pass) | The compulsory welcome, breaking ("you don't have an inventory") | To follow his script | Not reporting | Reports Rue, and is sorry | Write Rue's name back into the guest book | His greeting changes after the book (`TOBBEN_GREETING_BOOK`); written-only after fraying | A one-time reaction after the book | "You wrote RUE back in a different hand" | — |
| **Archivist** | At his desk, **reading** | Keeps the records nobody reads | That someone reads them | Being seen (he can't be deleted only while unseen) | Gives the way out; can't leave | Talk; read the records | The pointer opens the north road (an immediate grant); the introduction now counts **only once heard** (**new**) | "You came back. I hadn't finished." after a broken-off introduction (**new**); otherwise "Back again." | The CHARACTER FILE at his desk | The truth that RUE needs |
| **Pip** | Under the well, waiting | Recognises her first: "...rue? rue! you fell back in! i waited…" (existing; now tested) | To be with her | Being saved back in (and deleted) | The girl's drawing, still here | Wake it | It follows and guides | A first-talk line each run, by memories | — | Goes with her into the slot, or with Wren |
| **Arin** | P1 · ARIN in the opening, waiting for her at the save point (**new**) | Walks only when the owner plays; mute | — (the owner's) | — | An avatar without a will | Hide from his look | Learns routes and spots (`note_spot`) | Patrols what he learned | — | — |
| **Owner** | The opening's reply that stops; notes | Lamp, cursor, reload, save-over | An empty slot 2 | That it's her | "You're not her" is true and misses the point | — | Adapts to what Rue actually did | Notes per run | "...rue?" | The message ending |
| **The girl** | The amber controller, the taped cable, the habit | Two light taps, then the press | — | — | Absent; present in every habit | — | — | The well keeps her message | Months later: "still have my save?" | The message ending tells her what she left running |

**Proposed, not built:**
- Pip: a quiet return gesture after separation.
- Mira: a visible board change that she reacts to in person.
- The Archivist: split his seven-page introduction into a shorter first
  exchange and a follow-up, so it isn't one long speech (it was kept, and
  its completion is now tracked).
- A second gesture of Rue's own, earlier than Slot 2, for players who never
  read the file.

## Maps and presentation (this pass)

- **Tips no longer cover the scene.** The tutorial card moved from
  top-centre (over the Archive's shelves and the Square's crossing) to the
  bottom-right corner, above the control hint. That is the part the areas
  leave empty, and away from the console. It is left-aligned and grows
  upwards with larger text, and it still steps back when it overlaps the
  interaction prompt. Compare `docs/review/opening/compare_tips_and_you.jpg`
  (left: the 22 October head; right: now).
- **The first room** shows **you** over Rue until her first step.
- **Mira** tends her cups; **Tobben** tends his wares (previous pass); the
  **Archivist** reads at his desk.
- Captures of every review state at this head are
  `docs/review/opening/world_after_*.jpg`. The matching earlier set is
  `docs/review/oct22/after_*.jpg`.

**Not changed (proposals):**
- The act card ("ACT I · SOMEONE ELSE'S SAVE") still sits centred over the
  rug on a first arrival. It holds the owner until it is read (the
  protection policy), so moving it is a design decision, not a fix. The
  proposal is a lower placement with the same hold.
- No new portraits or recorded performances exist; the procedural cast
  and the portrait loader's fallback are unchanged.
- The cast's hand and arm poses, gaze and start/stop transitions were not
  redrawn in this pass.
