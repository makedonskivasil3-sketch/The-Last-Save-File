# Wren: the exceptional relationship

**Decision:** the author chose Wren on 2026-10-27.

**Revision:** this branch.

**Canon held** (authoritative: [`TRUTH_TABLE.md`](TRUTH_TABLE.md)):
- Wren is a child in the square, cut content, and never played.
- Rue was played, then left.
- The well **keeps what is said near it** (recordings, nothing live). Whether it keeps only people who were played is **Wren's fear, never a rule**: the game neither confirms nor denies it.

No beat contradicts these. *(Corrected 2026-10-28: this introduction used to state her fear as the well's rule.)*

## The idea

Rue and Wren are two kinds of left behind:
- **Rue** was played, then left running.
- **Wren** was never played at all. She watched other people play.

Wren has listened at the well and never heard herself in it, and she believes that is because nobody played her. Her arc is about wanting **one trace** of herself. She gets it because Rue chooses to give it.

## The playable slice: her game (2026-10-28)

The arc used to start sad. It now starts with a game she leads, so the player knows her before she is vulnerable.

| Need | How it's played | Kept as |
|---|---|---|
| **Warmth, initiative** | The talk after her lantern line (she needn't have hidden Rue yet), Wren starts it: "You hide like a lamp post." She chalks an X where she stands (her shelter) and lends Rue her chalk: "Give it back. It's my only one." | `wren.game` |
| **Shared action, player choice** | Rue chalks a mark in one of two places: under the awning (a real hiding place) or out on the crossing (the lamp sweeps it) | `wren.mark_recess` / `wren.mark_crossing` |
| **Agency; she only judges what she sees** | She won't judge from her corner: "I'm going to look." She **walks there** and waits beside the mark | — |
| **Friction, for a reason** | The crossing: "The lamp goes right over this." She rubs it out and refuses to count it | `wren.mark_refused` |
| **Personality** | The awning: "That's a real one." Then: "Is that an R? It's backwards." She takes her chalk back | `wren.mark_ok`, `wren.chalk_back` |
| **She acts between sessions** | Next session the R is drawn the right way round: "I fixed your R. You're welcome." | conversation `wren.r_fixed` |
| **Behaviour, not speech** | When the Owner hunts and Rue hides at Wren's X (beside her), Wren answers "shh": once a session, silent | (session) |
| **Vulnerability comes after** | Her own sad beats (the festival she watched, "is there one of me?") wait until the game is played out. The chalk gift then reads "For keeps this time", and "Don't do the R backwards" is a callback | gating in `Relationships._wren_own` |
| **Payoff** | The epilogue: "under the awning in ashvale there's an R in chalk, the right way round. somebody keeps fixing it." | — |

**Order rules (revised 2026-10-28):** her introduction, then her lantern line, then **her game**, then her ask to see the Edge.
- *Why:* before, the ask came first and the game waited for it to be settled. A fresh profile hears the ask on the third talk; accepting it takes Wren out of the square as an escort, so most players would have left without ever seeing the game. Measured by `tests/test_wren_route.gd` on a fresh profile: the game now starts on the third talk, and the ask follows once it's played.
- The game no longer needs her to have hidden Rue first.
- Her own sad beats wait for the game **only in the session it starts**. A player who leaves it unfinished hears her story next time; the game stays open.
- **Discoverable before it's explained:** once the game is next, her prompt reads "WREN · CHALK OUT", and she holds the chalk up ("!") the first time Rue comes near. While it's open it reads "WAITING FOR YOUR MARK", which also reminds a returning player. The two places read "UNDER THE AWNING" and "OUT ON THE CROSSING" before Rue chooses.

**Tests:** `tests/test_wren_game.gd`; `tests/test_wren_route.gd` (fresh profile, ordinary interactions only); the Wren-ending bot plays the game on its way.

## Beats (★ = new in this revision)

| # | Beat | When | What the player does | Kept as | Pays off |
|---|---|---|---|---|---|
| 1 | Met: "You still look like someone." | First visit to the square | Talks to her | `wren.met` | — |
| 2 | Shelter: she hides you | When Arin comes near | Stands beside her | `wren.sheltered`, `wren.concealed` | Trust; the Owner's anger at helpers |
| 3 | The lantern: "it's waiting for somebody" | After meeting, once | Listens | `wren.lantern` | Beat 4 |
| 4 ★ | **She watched the festival.** What she saw follows this save's festival choice (tried / stayed / lit / none). "Nobody ever picked me for anything." | The next talk, once her ask isn't due | Listens | `wren.watched` | A second witness of the first impossible action; sets up beat 7 |
| 5 | The promise: she asks to see the Edge | After a few talks | Takes her or declines | `wren.promised` | Escort; the Wren ending |
| 6 | Well hum: "it hums like the people who used to play" | After Rue hears the well's words | Listens | `wren.heard_well` | Beat 7 |
| 7 ★ | **"Is there one of me?"** She has listened at the well and never heard herself; she believes it's because nobody played her long enough. **This is her fear, not the well's rule**: the well keeps what's said near it (`WellSequence`). The game never confirms it. She offers her chalk | After 4 and 6 | **Chooses:** "I'll remember you." / "Not now." (offered again in a later session) | `wren.unplayed`, `wren.chalk` | Beat 8 |
| 8 ★ | **Rue writes WREN on the well's rim.** It is drawn from then on. The journal page, Wren's line about it and the epilogue say what is actually on the rim: her name alone, or her name beside Wren's drawing of Rue. If the drawing comes later, Wren says "Next to my name. So now we're both on it" | Any time with the chalk | Uses the rim ("write WREN in chalk") | `wren.named` | Beats 9 and 10 |
| 9 ★ | **"Now there's one of me. Even if it's only chalk."** | The next talk, once | Listens | conversation `wren.saw_name` | — |
| 10 ★ | **Every ending except overwrite** keeps the chalk: "on the well's rim in ashvale, in chalk: two dots for eyes, an arrow up, and WREN. nobody rubs it out." | Epilogue | — | — | The arc's last image |

**Unchanged:** the existing beats about her checkpoint scene (`wren.marked_well`), the restore, the ribbon, her deletion and the Wren ending. Beat 8 deliberately answers her chalk mark from the checkpoint scene: she marked Rue on the rim, and Rue marks her back.

## Rules

- **Her ask comes first.** Her own story waits while her ask to see the Edge is due and unanswered (`Relationships.wren`), so the main quest's pacing is unchanged.
- **One step per conversation**, each said once and kept in the save.
- **"Not now" is a real answer.** She doesn't ask again in the same session.
- **Overwrite has no chalk line.** In that ending Rue has become Arin; the memory isn't hers to keep.

## Verification

- **Tests:** `tests/test_wren_arc.gd`. They cover the order, the festival variants, the choice both ways, writing the name, the journal and the epilogues.
- **Regression:** the existing Wren suites pass.
- **Voice manifest:** regenerated (text only; nothing is recorded).
- **Not verified:** whether players find the rim beat without a hint, which needs a playtest. There is no recorded voice.
