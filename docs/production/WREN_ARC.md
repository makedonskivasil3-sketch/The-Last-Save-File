# Wren: the exceptional relationship

**Decision:** the author chose Wren on 2026-10-27.

**Revision:** this branch.

**Canon held:**
- Wren is a child in the square, cut content, and never played.
- Rue was played, then left.
- The well keeps **recordings** of people who were played, and nothing live.

No beat contradicts these.

## The idea

Rue and Wren are two kinds of left behind:
- **Rue** was played, then left running.
- **Wren** was never played at all. She watched other people play.

The well keeps recordings of the people who played. So it keeps something of Rue's world, and nothing of Wren. Wren's arc is about wanting **one trace** of herself. She gets it because Rue chooses to give it.

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
