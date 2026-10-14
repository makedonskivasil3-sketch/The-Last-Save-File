# THE LAST SAVE FILE — Story Script

*A game in five acts and an epilogue. Every line below is the line the game shows: the
narrative text lives in `scripts/story/story.gd` and the area scripts, and this document
is the readable version of it.*

---

## The story in one paragraph

Two friends shared one console. One of them always played **Arin**, in slot 1. The other
made their own character in slot 2: a kid called **Rue**, with a red scarf, a yellow
raincoat and a fox called **Pip**. One afternoon Rue walked into the village well by
accident, clipped through the stone and fell out of the map, and the two friends laughed
until they cried. Years later the friends drifted apart. The second controller stayed
unplugged on the floor. One night the owner needed the space, and deleted slot 2.

You are what's left of that deleted save, waking up inside the slot that survived. The
owner thinks you are a bug. The world thinks you are Arin with the colours wrong. Pip
has been waiting out of bounds all this time, because nothing out there was ever saved,
so nothing out there could be deleted.

## Cast

| Who | What they are | Voice |
| --- | --- | --- |
| **RUE** (you) | Slot 2's character. Deleted. Starts as "missing texture" cyan with a void for a face; each memory restores a part of them. | Lowercase, in brackets, in cyan: `(like this)`. Short, honest, a bit afraid. |
| **THE OWNER** | The one who kept playing. Never seen. Types into the console. | Lowercase, orange, starts with `>`. Bored, then irritated, then cruel, then cracking. |
| **ARIN** | The owner's character in slot 1, driven by the owner. Patrols the square. | Silent. A light cone and footsteps. |
| **MIRA** | Lives in Arin's room. First to notice you. | Warm, worried. |
| **WREN** | A child in the square. Sees things she shouldn't. Hides you. | Plain and brave. |
| **TOBBEN** | Shopkeeper. Has to report you; it's in his script. | Cheerful, sorry. |
| **THE ARCHIVIST** | Cut before the game shipped, so the owner has never seen them. | Dry, kind, a librarian of mistakes. |
| **PIP** | Rue's fox. Fell out of the map with Rue years ago and never got saved back in. Lives out of bounds. | Lowercase, quick, loyal. Talks in short bursts. |

Pronouns: Rue, the owner and the second player are *they*.

---

## PROLOGUE — Boot

*First launch only. Black screen, letterboxed. System text types itself.*

```
SLOT 1  ·  ARIN  ·  LV 7  ·  14:22:00
LOADING SAVE DATA . . . . . . . . OK
VERIFYING . . . . . [!] 1 UNRECOGNISED ENTITY
ENTITY OWNER: none.   ENTITY NAME: none.   ENTITY SLOT: 02
slot 02 does not exist.
```

*Pixels pull together in the middle of a bedroom. Something small and cyan is standing
where nothing should be.*

---

## ACT I — SOMEONE ELSE'S SAVE

> **Title card:** `ACT I` · *SOMEONE ELSE'S SAVE*

**INT. ARIN'S ROOM — NIGHT**

*A bed, a rug, a table, a pinned note, a save crystal humming in the corner. MIRA sways
by the bed. A cyan shard glints under it. The door at the top is open.*

**RUE:** (...where is this?)
**RUE:** (this body isn't mine. it's barely a body.)

**CONSOLE:** `SLOT 1 LOADED`

*The owner is watching. The awareness bar in the corner starts to fill.*

**THE NOTE** *(pinned to the wall):* Welcome home, Arin. Don't forget to save!

**MIRA:** Arin! You're up early.
**MIRA:** ...Arin? Your colors look wrong.
**MIRA:** You're not Arin. Who are you?
**MIRA:** They're going to notice you. They notice everything.
**MIRA:** If you get out, find Wren in the square. She sees things too.
**MIRA:** Arin never talks about the other one. The one who used to sit next to them.

**RUE:** (something cyan, in the corner of my eye. it feels like mine.)

*If Rue touches the shard under the bed, the world freezes and goes pale, like an old
photo of a screen. A music box plays.*

> **MEMORY · THE SECOND CONTROLLER**
> a second controller, plugged in next to the first.
> two people on one couch. one screen. one save.
> "you be arin," they said. "i'll make my own."

**RUE:** (i was here before. not in this room. in front of it.)
**RUE:** (a scarf. red. i picked that colour myself.)

*Rue's scarf turns red.*

*If Rue walks to the open door:*

**THE OWNER:** > nope.

*The door slams and locks. At 25% the note rewrites itself while Rue isn't looking:*
**THE NOTE:** Welcome home, Arin. Someone else is here.
**THE OWNER:** > huh. arin doesn't walk like that.

*At 40% the lights flicker and a wall of the room tears open in a red wound.*
**THE OWNER:** > who are you?
**CONSOLE:** `WARNING: wall integrity 97%`

*Rue slips through the wound.*

---

## ACT II — ASHVALE

> **Title card:** `ACT II` · *ASHVALE*

**EXT. ASHVALE · VILLAGE SQUARE — DAY**

*A green square with a stone well in the middle, Arin's house, a market stall, a notice
board. ARIN walks a slow loop around the well with a pale light cone in front of them.
WREN hops by some crates. TOBBEN waves from the stall.*

**THE OWNER:** > where do you think you're going?
**RUE:** (a whole town. someone built all of this for arin.)

*The first time Arin's cone touches Rue:*
**RUE:** (that's arin. the one they wanted instead of me.)
**RUE:** (...instead of me? why did i think that?)
**THE OWNER:** > there. by the well.

**THE NOTICE BOARD:** ASHVALE NOTICES. Harvest fair on Sunday.
*(later)* MISSING: ONE (1) INTRUDER. IF SEEN, TELL TOBBEN.

**WREN:** You're the one Mira talks about. The colors-wrong one.
**WREN:** Stand right next to me. The owner can't see what I'm standing beside. I don't know why.
**WREN:** There's a library east of here. Arin never goes there. Nobody does.
**WREN:** If they find out I hid you, they'll take me out of the save. It's okay. Go.
**WREN:** You look like someone who used to play here. Before. They fell in the well once. It was funny.

*Standing beside Wren, Rue ducks down. `HIDDEN · WREN covers you`.*
**RUE:** (she's warm. like a real person.)
**RUE:** (stay still. stay small.)

**TOBBEN:** Welcome to Tobben's! Finest wares in Ashvale!
**TOBBEN:** Welcome to Tobben's! Finest... you don't have any gold. You don't have an inventory.
**TOBBEN:** Welcome to... I have to tell them, you know. It's in my script.
*(four seconds later)*
**THE OWNER:** > tobben says you were asking questions.
**TOBBEN:** I told them. I'm sorry. Welcome to Tobben's.
**TOBBEN:** There used to be two names in my guest book. Now there's one. I don't remember the other.

*The well. A sign on it reads `WELL · out of order`. Rue looks down. Something down
there is cyan.*

**RUE:** (i've been down there before. i know i have.)

*Interact: CLIMB IN.*

---

## ACT III — OUT OF BOUNDS

> **Title card:** `ACT III` · *OUT OF BOUNDS*

**INT. BELOW ASHVALE — NO TIME**

*The underside of the map. The square hangs upside down overhead as flat, grey shapes:
the bottoms of houses, the base of the well, Arin's loop drawn as a dotted line. Around
Rue, collision boxes glow as wireframes. Labels float in the dark: `kill_plane y = -999`,
`chunk_07: streaming...`, `TODO: nobody should ever see this`.*

*The floor isn't really there. It streams in and out in waves: tiles flicker before they
vanish, so Rue has to move with the wave, from one solid debug platform to the next.*

**CONSOLE:** `OUT OF BOUNDS`
**THE OWNER:** > ...where did you go?
**THE OWNER:** > you're not anywhere.

**RUE:** (the owner can't see me down here. nobody's ever looked.)

*If Rue falls through a gap, they land back on the first platform with a crunch of static.*
**RUE:** (fell out of the world. again.)

*On the far ledge, curled up next to a cyan shard: a small orange FOX with a white-tipped
tail. It lifts its head.*

**PIP:** ...rue?
**PIP:** rue! you fell back in! i waited by the wall. i'm good at waiting.
**PIP:** you're the wrong colour. that's okay. i'm the wrong place.
**PIP:** nobody saves out here. so nobody could delete out here.
**PIP:** i'll come with you. i can smell where your pieces are. they smell like you.

> **MEMORY · THE WELL**
> my character walked into the well by accident.
> it clipped through the stone and fell out of the map.
> we laughed until we cried. we saved anyway.

**RUE:** (i fell out of the world once before. i got back in.)
**RUE:** (my hair. it always stuck up at the back like that.)

*From now on PIP follows Rue everywhere. The owner can't see Pip. Pip runs a few steps
ahead toward whatever Rue should find next (a memory, or the way out) and yips `!` when
Arin is close.*

**PIP** *(talked to again):* the owner can't see me. i checked. i stood right on arin's foot.
**PIP:** they used to give me treats with the shoulder button.
**PIP:** your pieces. we have some. i can smell the rest.

*The RESPAWN POINT (a cyan pillar) takes them back up into the square, beside the well.*

---

## ACT IV — CUT CONTENT

> **Title card:** `ACT IV` · *CUT CONTENT*

**INT. THE ARCHIVE — DUST**

*East of the square. Shelves of books that are live logs. A desk. A tall figure in a robe
reads by a soft cyan light. The awareness bar slowly falls: the owner can't see in here.*

**THE OWNER:** > ...where did you go?
**RUE:** (it smells like dust in here. can data smell like dust?)

**THE ARCHIVIST:** Oh. A visitor. Nobody visits.
**THE ARCHIVIST:** I'm the Archivist. I was cut from this game before it shipped. The owner has never seen me.
**THE ARCHIVIST:** Which means they can't delete me. Lucky me. Lucky you, maybe.
**THE ARCHIVIST:** You want out. Everything in here wants out, but you're the only one who can actually leave.
**THE ARCHIVIST:** There's a slot the owner never used. Slot 2. The last save file. It's empty.
**THE ARCHIVIST:** Here. A pointer to it. It'll open the north road. The world isn't loaded up there, so the owner reaches in by hand.
**THE ARCHIVIST:** Reach Slot 2 and you can write yourself into it.
*(if Pip is with Rue)* **THE ARCHIVIST:** And you brought the fox. I logged a fox once. "pip.npc: location unknown." Not unknown anymore.

**CONSOLE:** `RECEIVED: slot_2.ptr`

**BOOK · CUT CONTENT:** CUT: save slot 2. Note: 'one slot is enough, players never use the second one'. ... Someone has written underneath, in pencil: everything cut is still here. Just not drawn.
**BOOK · THE OWNER:** They play at night, mostly. They talk to the screen when they think nobody hears. They don't know there's a second slot. If they find out, they'll delete that too.

> **MEMORY · NEW GAME**
> NEW GAME.  SLOT 02.  ENTER NAME: _
> i typed a name. i was so proud of it.
> it's the only thing i can't remember.

**RUE:** (slot 02. that's what the save said about me. 'entity slot: 02'.)
**RUE:** (a yellow raincoat. it was raining the day we made me.)

---

## ACT V — THE LAST SAVE FILE

> **Title card:** `ACT V` · *THE LAST SAVE FILE*

**EXT. THE EDGE — NOT LOADED**

*North of the square, up a road that isn't drawn. Black, with a faint cyan grid.
Magenta-and-black checkerboards where trees should be. Labels: `tree_04.png (missing)`,
`npc_spawn_07 = null`. The eraser is already eating the corners. In the far corner floats
a small cyan card: `SLOT 2 · EMPTY`. Beside it hangs the owner's CURSOR, huge, then
shrinking into the world.*

**CONSOLE:** `WARNING: entering unloaded region`
**THE OWNER:** > that part of the save isn't finished. neither are you.
**RUE:** (the world just... stops.)
**RUE:** (there's something in the corner. it's the same colour as me.)

> **MEMORY · THE LAST TIME**
> "you never come round anymore."
> "it's my console."
> the second controller stayed unplugged on the floor for weeks.

**RUE:** (i stopped coming. they stopped waiting.)
**RUE:** (real shoes. i can feel the floor now.)

> **MEMORY · DELETE SLOT 2?**
> DELETE SLOT 02?      > YES      NO
> they didn't ask me. they just needed the space.
> but nothing is ever really deleted.
> not while someone still remembers.

**RUE:** (my name was RUE. slot 2 was mine.)
**RUE:** (that's my face. that's me.)

*To win, Rue has to stand in Slot 2 for a few seconds, writing themself in, while the
cursor selects anything that holds still. Lure it away, then run.*

**THE OWNER:** > hold still.

---

## EPILOGUE

*Rue streaks upward into the slot. White. Then the load menu, letterboxed.*

**If Rue remembers fewer than 3 memories:**

> SAVED TO SLOT 2
> you wrote yourself into the last save file.
> the owner doesn't know this slot exists. not yet.

**If Rue remembers 3 or 4:**

> SAVED TO SLOT 2
> you wrote yourself into the last save file.
> you almost remember whose it was.

**If Rue remembers all 5 (the true ending):**

```
LOAD GAME
SLOT 1  ·  ARIN  ·  LV 7  ·  14:22
SLOT 2  ·  RUE   ·  LV 1  ·  00:00
```
> somewhere outside the screen, the cursor hovers over slot 2 for a long time.
> it doesn't press delete.
> > ...rue?
> > i kept your controller. it's still under the couch.
> it presses LOAD.

**If Pip came too, the last line of any ending:**

> a small orange fox curls up at the bottom of the screen. nobody saved it. it came anyway.

*Title screen. From now on it shows a second save slot. With all five memories it
reads `SLOT 2 · RUE`.*

---

## When things go wrong

**Death** (*erased* by the eraser, *overwritten* by Arin's touch, *selected* by the
cursor). The next session opens with:
**THE OWNER:** > got you.
**THE OWNER:** > 3 times now. i'm learning how you move.
**THE NOTE:** I REMEMBER WHERE YOU DIED.

**Quitting.** Closing the game counts as dying.
**THE OWNER:** > you closed the game.
**THE OWNER:** > i didn't. i'm always here.
**THE NOTE:** CLOSING THE GAME WON'T SAVE YOU.

**Helpers pay.** If Wren hid you and you die or quit, she is deleted next time:
**THE OWNER:** > and i know who helped you.
**RUE:** (wren's corner is empty. she hid me, and they found out.)

**The owner starts to recognise you** (by memories recovered):
**THE OWNER:** > ...you move like someone i used to know. *(3)*
**THE OWNER:** > no. you can't be. i deleted you. *(5)*

**Purge.** After six deaths or quits, the owner wins: the room is clean, the real Arin
stands where you used to, and the console reads `SCAN COMPLETE: 0 UNKNOWN PROCESSES`.
**THE OWNER:** > there. clean.
**THE OWNER:** > welcome back, arin.
