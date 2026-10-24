# Suspend (Save and Exit): a proposal

**Status: not built.** The rule today is unchanged: quitting during a run
raises purge by one (`OwnerMemory.record_quit`). This page proposes an
alternative for the author to decide on. It does not add free suspension,
a checkpoint or a difficulty cut, and nothing here is in the game.

## The problem

- A player who has to stop (dinner, a train stop) pays the same as one
  who quits to escape a threat. Purge makes later runs harder, so a
  necessary stop is punished like a strategic one.
- The pause menu says "only quitting ends the run (and counts)". That is
  honest, but it gives the player only two choices: keep playing, or take
  the cost.
- The protection policy already holds threats during cards and choices,
  so the game has a precise idea of "a safe moment". Suspend could reuse it.

## Proposal

**"Suspend" in the pause menu, beside the two quit buttons.**

1. **Allowed only when nothing is about to land.** This uses the same test
   as the reading hold (`World._update_reading_hold`): no warning on
   screen, no cursor or static in play, not escorting, not in a scene or
   a conversation. Otherwise the button is disabled and says why
   ("not while the owner is reaching in").
2. **It writes one suspend record:** area, position, the run's flags, and
   the escort's id if any, with the session number and a geometry
   version (the same rule as `anchor_valid()`).
3. **The next launch resumes there, once,** and deletes the record when
   play starts. There is no "load again": a crash after resuming is a
   crash, as today.
4. **No purge, no death, no quit counted.** `last_exit` becomes "suspend".
   The owner's next note can acknowledge it ("you left. you came back.")
   without punishing it.
5. **Doesn't stack with the anchor.** Resuming takes precedence over the
   well anchor for that one launch. The anchor is unchanged.

## What stays the same

- Quitting from the pause menu still raises purge.
- Deaths, the anchor and the endings are unchanged.
- Web: closing the tab is still a quit (`record_quit`). A suspend needs
  the button.

## Risks

| Risk | Mitigation |
|---|---|
| Save-scumming (suspend, then quit at the title to retry) | One record, deleted when play starts. Resuming reproduces the moment rather than rewinding it |
| A suspend inside a scripted moment | The protection test refuses it. The scripted moments (cards, cinematics, choices) already register with it |
| Old saves | The record is optional. Its absence means today's behaviour |
| Purge loses its teeth | Purge still comes from deaths and quits. Suspend only removes the cost of stopping at a safe moment |

## Tests it would need

- Suspend refused under a warning, the cursor, the static or an escort.
- Suspend then launch: same area and position, no purge, `last_exit ==
  "suspend"`.
- The record is deleted when play starts, and a second launch is ordinary.
- A geometry-version mismatch discards the record safely.
- Quitting still raises purge; closing the web tab still counts as a quit.

## Decision needed

The author decides between:

- (a) keep today's rule;
- (b) Suspend as above;
- (c) Suspend with a cost (for example the next run starts at the room),
  which keeps a little of the owner's pressure.
