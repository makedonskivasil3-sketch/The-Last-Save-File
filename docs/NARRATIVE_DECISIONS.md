# Narrative decisions waiting on the author

**Nothing in this file has been decided.** It lists, for each of the three open questions, every line and system that depends on the answer, so that once the author decides, all the edits can be made in one consistent pass.

Line numbers are from commit `fb1ffc9`. `S:` means `scripts/story/story.gd`. The background is in `NARRATIVE_BIBLE.md` §10–§11.

Until these are decided, no milestone work may change these lines, add visual cues or sound motifs that imply an answer, or touch ending conditions that depend on them. The procedural voice and music work (`AUDIO_DIRECTION.md`) deliberately keeps the owner's motif neutral on question 1.

---

## 1. Does the owner know Slot 2 exists?

The game currently says both.

| Says | Where | Text |
|---|---|---|
| **No** | `archive.gd:104` (the Archivist) | "There's a slot the owner never used. Slot 2. The last save file. It's empty." |
| **No** | `archive.gd:168` (the book THE OWNER) | "They don't know there's a second slot. If they find out, they'll delete that too." |
| **No** | `S:166` (`FINAL_FIGHT.notice`) | "> what's that. what is SLOT 2. that's not yours." |
| **No** | `S:805` (the escape ending's text) | "the owner doesn't know this slot exists. not yet." |
| **Cut, never used** | `archive.gd:154` (CUT CONTENT) | "CUT: save slot 2. Note: 'one slot is enough, players never use the second one'." |
| **Yes, the owner deleted it** | `S:10` (file header) and `S:136–144` (Fragment 5) | "DELETE SLOT 02? > YES", then "slot 2 was mine." |
| **Yes** | `S:181` (owner note 5) | "the night i deleted slot 2 i told myself it was for space." |
| **Yes** | `S:207` (`owner_note_about_you`) | "you're looking for slot 2. it isn't there. i made sure." |
| **Yes** | `S:27` (BOOT) | "PLAYER 2 . . . . . . [deleted]" |
| **Yes** | `S:802` (the RUE ending) | "…staring at a save they deleted years ago." |
| **Yes** | `S:553` (`ENDING_RETURN.escape`) | "there's a second slot. you hid in it." |

**What else depends on it:**
- The Slot 2 fight's framing (`the_edge.gd`, `FINAL_FIGHT`).
- The escape ending's text.
- The Archivist's role.

No ending *conditions* depend on it; only text does.

**A reconciliation that would change only text, as an option** (the author's call): "The owner deleted Slot 2. What Rue finds at the Edge is the slot's *cut-content ghost*, which the owner doesn't know survived." That would mean rewording `archive.gd:104` ("a slot the owner thinks is gone") and `S:805` ("the owner doesn't know this slot survived"). The "yes" lines would stay as they are.

## 2. Two years, or months later?

| Where | Text | Implies |
|---|---|---|
| `S:139` (Fragment 5) | "a message, months later: \"still have my save?\"" | the message came months after the move |
| `S:180` (owner note 4) | "i kept her save for two years." | the deletion came about two years after the move |
| `S:182` (owner note 6) | "she sent a message once… i'd already deleted it." | the deletion came *before* the message |
| `recycle_bin.gd:174, 204` | "deleted 3 years ago" | how long ago the deletion was (consistent with either) |
| `recycle_bin.gd:194–195` (the owner's draft) | "deleted the same night as slot2.sav"; "yes i still have your sa" | the deletion came *after* the message, the same night as the draft |

**The conflict.** "Months later" combined with "already deleted" means the deletion happened within months, not two years. The draft says the owner still had the save when the message arrived.

**What depends on it:**
- The order of owner notes 4–6.
- Fragment 5.
- The recycle-bin draft.

No ending conditions depend on it.

**Decision needed:** how long after the move the message arrived, and whether the deletion came before or after it.

## 3. Who speaks which line in Fragment 1?

`S:95`: `"you be arin," they said. "i'll make my own."`

The fragment is Rue's memory. Attributing both clauses to "they" (the other person) would mean *the other person* made their own character in Slot 2. That reverses the established roles: Rue is Player 2 (`S:8`, BOOT, Fragment 5).

**Readings:**
- (a) Rue speaks both lines: `"you be arin," i said. "i'll make my own."`
- (b) Split: `"you be arin," i said. "i'll make my own," i said.`
- (c) Keep "they" deliberately, as Rue's memory confusing who was who. If so, mark it as intentional in the bible.

**What depends on it:**
- `S:95`.
- `docs/STORY_SCRIPT.md:90`.
- How players read Rue's identity in their first memory (this fragment is in Arin's room, so it's often the first one found).

---

## Answering

One line per question is enough, for example: "1: cut-content ghost; 2: message after 2 years, deleted the same night; 3: (a)". All the listed edits and the bible update will then be made together, with a test asserting the chosen wording where practical.
