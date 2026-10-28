# The opening: beat sheet (revision of 2026-10-27)

**Baseline:** `main` @ `6fb8e23`, the festival as integrated. The cooperative stations, the remembered choice and the reader-paced story breaks stay; they work. This revision changes the **break**: how Player 1 leaves, what the player tries, and the first impossible action.

**Why:**
- **The break was announced, not felt.** Player 1 "left" the moment Arin reached a waypoint, and the toast appeared in the same frame.
- **The impossible action was not the player's.**
  - If they stayed, Rue lit the last lantern by herself during the time-lapse, on autopilot.
  - If they "lit it alone", Player 2 was still holding the controller, so nothing impossible happened.

## Beats

| # | Beat | The player does | Learns | Feels | What changes | Pays off later |
|---|---|---|---|---|---|---|
| A | **Joined** | Moves Rue at once; Arin waits, waves her over | Who they are (P2 · Rue) and who the other is (P1 · Arin) | Welcome | — | The tags (P1/P2) set up the leaves |
| A2 | **Lantern 1, the plate** | Walks through the gate Arin holds open; lights it | Move, interact; Arin helps by standing still | A small shared win | Story break: "You always let me do the first one." / "You always check whether I will." | Their habit of checking on each other |
| A3 | **Lantern 2, the watch** | Hides beside Arin as Tobben's look sweeps | Hide beside someone | Mischief | — | Wren's shelter, Arin's look in the present |
| A4 | **Lantern 3, the maypole** | Holds [E] with Arin: the co-op special | Hold to charge; it needs two | Togetherness | Ritual break: two taps, then together; Mira notices from her window | The girl's two-tap habit; Mira remembers the festival |
| A5 | **Lantern 4, the spotlight** | Crosses the gap when the light turns | Time a crossing | Competence | — | The lamp, the static |
| **B** | **The interruption** | Runs with Arin to the last lantern, by the well. Like the maypole, it needs **both** hands: both take their places and the player starts to hold | — | Expectation, then wrongness | **Halfway through the hold, Arin's half stops.** His side of the meter drains. He freezes mid-breath: no blink, no sway, because nobody is driving him. The music cuts out and the camera stops drifting. **No text for ~2.5 s.** Only then: PLAYER 1 HAS LEFT THE SESSION | The owner walked away; the absence is felt before it is named |
| C | **What she does** | Chooses: **stay** beside him (stand by Arin), or **try alone** (hold at the lantern). Doing nothing times out to "idle" | It needs two. Trying alone fills half and stalls, flickering: "it needs two" | Helplessness; loyalty or stubbornness | The choice is kept (`festival_choice`: stayed / tried / idle) | Mira saw it from the window; her line differs by choice. The Archive's log |
| C2 | **Player 2 leaves** | Reads one line from beside the television: "the car's here. I have to go." Then PLAYER 2 HAS LEFT THE SESSION; Rue's tag fades | Both players are gone | Loss | Rue's P2 tag empties; the world desaturates | Moving day (memory 4) |
| **C3** | **The first impossible action** | With nobody holding anything, a faint [E] glows at the lantern. **The player holds it, and Rue lights the lantern alone, a lantern that needed two** | Rue can act when no one is playing her | Awe, unease | `lit_by_herself` recorded; music returns as one music-box phrase | The CHARACTER FILE ("character: still running"); the Archive's "controller: none" |
| D | **The years** | Watches (skippable) | Time: the message, the unsent reply, SLOT 2 · DELETED, 3 YEARS LATER | Grief | The four shared lanterns go out; hers never does | The lantern by the well and at Slot 2 |
| E | **The load** | — | The owner is back, and doesn't know who she is | Dread | "> ...who's in my save?"; Rue: "(i can still move.)" | The first mission: "Find who kept the fifth lantern burning" |

## Rules this revision keeps

- **Control and skipping:** control within 1 s. Hold Esc (or the touch chip) to skip from any beat; the present is reached in ≤ 15 s.
- **Reading and replay:** story breaks wait for the reader; a replay changes nothing in the save.
- **Assistance only takes over when nothing is pressed.** It is shown step by step after a delay, and drives only after 24 s without input. At the decision, the impossible action and the reading it never drives: an active player is never overridden.
  - The decision times out to "idle" (unchanged).
  - The impossible action is hinted after 8 s. It is played for the player only after the same 24 s of no input, so an absent player still reaches the present.
- **Reduced motion and flashing:** no shake, punch, slow motion or flicker.

## Data compatibility

- `festival_choice` gains **"tried"**. The values "lit", "stayed", "idle" and "skipped" from existing saves keep their meaning and their lines.
- In a new run, nobody lights the fifth while a player holds a controller, so "lit" is never written again.
- The Archive's log reads "lit by SLOT 2 · controller: none" for every new run.
