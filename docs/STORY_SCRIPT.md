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

*After a couple of talks, Wren asks:*

**WREN:** I want to see the Edge. Before they delete me. Will you take me with you?

> **CHOICE:** *Take her with you* / *Not now*

*If you take her:*
**WREN:** Really? Okay. Okay! I'll be quiet. I'll be so quiet.
**CONSOLE:** `wren.npc · following`
**THE OWNER:** > where are you taking her?

*She walks your exact footsteps, slower than you. You can't leave a place until she catches up:*
**RUE:** (wait for wren.)

*When the owner is suspicious, a red ring fills over her.*
**THE OWNER:** > and you. wren.npc. delete.
*If Rue glitches, the deletion breaks:*
**THE OWNER:** > ...fine. later.
*If it fills:*
**CONSOLE:** `wren.npc deleted`
**THE OWNER:** > she wanted to see the edge. now she won't see anything.
**RUE:** (...wren?)
**RUE:** (i promised her the edge.)

*If Rue says not now:*
**WREN:** That's okay. Maybe next time. If there is one.

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

## THE RECYCLE BIN (east of the Archive)

**THE ARCHIVIST'S BOOK, *DELETED ASSETS*:** Deleted things go east, to the bin. For a while. Then the owner empties it.
**RUE:** (everything the owner deleted ends up here. for a while.)
**RUE:** (so this is where they go.)

Grey files on a grid. Locked system files glow cyan; the bin can't touch what stands in their shadow.
Every so often: **EMPTYING RECYCLE BIN IN 3 · 2 · 1** and a white line sweeps the room.
**THE OWNER:** > emptying the trash.

The files of the deleted (Wren, Mira...) lie here with their silhouettes. Stand beside one long
enough and they come back:
**SYSTEM:** wren.npc · restored
**THE OWNER:** > wren? i deleted you.
**RUE:** (come back. it's not your turn to be gone.)

**slot2_backup.sav** · 1.2 KB · deleted 3 years ago
PLAYER 2: RUE · LV 31 · 41:07:12 · LAST PLAYED: the night before the move
*the file is mostly empty. the owner kept the name and deleted everything else.*

**guestbook_p2.txt** · torn out of Tobben's guest book
*"ARIN & RUE were here!! we beat the forest boss. on the first try. (the second try.)"*
*two names, two handwritings. one of them has been scribbled over so many times it tore the page.*
Next time, Tobben: **TOBBEN:** ...Rue. RUE. That was the other name in my guest book. How did I ever forget it?

**rue_last_message.txt** (opens fully only with every memory)
*"i'm not gone, i'm just moving. keep my slot. we'll finish it when i visit. promise?"*
*you remember writing it.*

Caught by the sweep: **EMPTIED** · *the owner emptied the recycle bin. you were in it.*

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

*If Wren made it here with you:*
**WREN:** So this is the Edge.
**WREN:** It's not finished. Nobody finished it. Nobody finished me either.
**WREN:** It's the most beautiful thing I've ever seen.
**CONSOLE:** `wren.npc · moved to CUT CONTENT`
**THE OWNER:** > where did she go. she's not in the list anymore.
*(From now on the owner can never delete her. In later runs:)*
**WREN:** I saw the Edge. I'm not afraid of them anymore.

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

## SLOT 2 — THE CHOICE

*Rue stands in Slot 2 and writes. The world freezes.*

> **SLOT 2 · EMPTY. Whose name goes here?**
> *Write yourself in* (or *Write RUE*, once you remember) / *Give Slot 2 to Wren* (only if she's with you) / *Leave the slot to the owner, with a message*

*The music box plays through every epilogue, as far as Rue remembers it. Only the true ending hears
it complete.*

### Ending I — Escape (write yourself in)

*Rue streaks upward into the slot.*

**With fewer than five memories:**
> you wrote yourself into the last save file.
> you load in somewhere the owner has never looked.

**With all five (the true ending):**
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

*Title afterwards:* `SLOT 2 · RUE` (or `???`). *Next time:* **THE OWNER:** > there's a second slot. you hid in it.

### Ending II — Give it to Wren

> NEW GAME · SLOT 2 · WREN
> a girl with pigtails stands at the start of a whole new world. nobody has ever deleted anything here.
> **WREN:** aren't you coming?
> **RUE:** (no. it only fits one. go.)
> *(with all five memories)* **RUE:** (i know my name now. i don't need a slot to keep it.)
> the owner finds a save they don't remember making. they leave it alone.

*End card:* you gave the last save file away. you're still out here, in someone else's save. but
someone is safe because of you.
*Title afterwards:* `SLOT 2 · WREN · NEW GAME`. *Next time:* **THE OWNER:** > there's a new save in
slot 2. a girl. i don't remember making her. > i'm leaving her alone. you, i'm not.

### Ending III — The message (hand the slot back)

> **What do you write?** *i'm sorry i stopped coming.* / *you can keep the save. i just wanted to be
> remembered.* / *please don't delete me again.*

> you write it into the empty slot, one letter at a time.
> somewhere outside the screen, the owner reads it for a long time.
> *(with all five memories)* > ...rue? > i didn't know you were still in there. > *(by message)*
> i stopped waiting. i shouldn't have. / i kept your controller. it's still under the couch. / i
> won't. i promise. > i'm going to call you. the real you.
> *(otherwise)* > who wrote this. > ...i'm not going to delete it.
> the eraser stops. the cursor goes still. for the first time, the save is quiet.

*The purge resets; everyone deleted comes back.* *Title afterwards:* the tagline reads **"someone is
waiting."** and slot 2 holds `(a message for you)`. *Next time:* **THE OWNER:** > i read your message.
> i still don't know what to do with you. so i'm just going to watch.

**If Pip came, the last line of any ending:** a small orange fox curls up at the bottom of the screen.
nobody saved it. it came anyway. *(With Wren: it jumps into the new game after her.)*

---

## Rue's glitches (and what the owner says)

Every glitch costs awareness. The first time each is used in a session, the owner reacts:

| Glitch | The owner |
| --- | --- |
| Phase through a wall | > you can't walk through walls. |
| Freeze Arin | > arin? ARIN. |
| Falsify a note | > i didn't write that. |
| Unlock the door | > that door is locked. i locked it. |
| Decoy | > there you— no. |
| Scrub the eraser | > stop undoing my work. |
| Blind the cursor | > i can't see. why can't i see. |
| Restore someone | > i deleted them. i DELETED them. |
| Pause the owner | > ...why won't it move. |

And the owner plays back: **> no. loading autosave.** (the reload), **> saving over you.** (the save
ring; broken by any glitch: **> ...the save failed. what did you do.**), **> no. not that way.** (the
crates across the road), **> i know where you like to walk.** (Arin's learned route).

---

## When things go wrong

**Death** (*erased* by the eraser, *overwritten* by Arin's touch, *selected* by the
cursor). The next session opens with:
**THE OWNER:** > got you.
**THE OWNER:** > *(what got you)* one click. that's all you were.
**THE OWNER:** > 3 times now. i'm learning how you move.
**THE NOTE:** I CLICKED. YOU WERE GONE. *(or ARIN REMEMBERS YOUR SHAPE / SAVED OVER YOU. SAVING AGAIN. / I REMEMBER WHERE YOU DIED.)*

The death card names the cause and gives a tip (*"TIP · Hold E on the cursor to blind it…"*).

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

## What they remember

The first time you talk to someone in a run, they may remember your last ones
(`Story.recall()`; the first matching line wins, once a session).

| Who | Remembers | Line |
| --- | --- | --- |
| MIRA | you restored her | I was deleted. Then I wasn't. I remember the dark in between. Thank you. |
| MIRA | Wren was deleted | They took Wren. She wanted to see the Edge so badly. |
| MIRA | the message ending | The owner sat with the game open for an hour last night. Didn't move Arin once. Just watched. |
| MIRA | Wren's ending | There's a new name in the save menu. Wren's. Did you do that? |
| MIRA | the escape | You got out. I watched the slot fill. So why are you back? |
| MIRA | Arin got you | Arin came back through the door alone last time. Humming. |
| TOBBEN | Wren was deleted | Wren used to come in every day and buy nothing. I miss her buying nothing. |
| TOBBEN | Wren saw the Edge | Someone walked Wren to the Edge. That wasn't in anybody's script. Good for her. |
| TOBBEN | the message ending | The owner opened my shop menu yesterday. First time in years. Didn't buy anything. Still. |
| TOBBEN | 3+ deaths | You again! I've started a tab for you. Out of guilt. |
| WREN | the message ending | Did you write to them? Everything's quieter. Even the static. |
| WREN | the escape | You got out, and you came back? For me? ...No. Probably not for me. |
| WREN | the static got you | I saw the static take you. It went right past me after. Like I wasn't worth erasing. |

After Wren's ending the note reads **WHO IS WREN? I DIDN'T MAKE HER.**; after the message,
**I READ IT. ...THANK YOU?**

## The owner's notes (one a run, from the second)

Shown on the console as the run starts (`OWNER'S NOTE · ...`) and kept in the Archive's book *THE OWNER*.

1. there's something in arin's room again. i'm not imagining it.
2. we used to play this on the couch at mum's. two controllers. i don't know why i'm writing that down.
3. she moved in the summer. said she'd visit every weekend. she came twice.
4. i kept her save for two years. i'd walk arin past the spot where her character used to stand.
5. the night i deleted slot 2 i told myself it was for space. the card wasn't even half full.
6. she sent a message once. 'still have my save?' i didn't answer. i'd already deleted it. i couldn't say so.
7. i didn't delete her because i hated her. i deleted her because the empty slot was easier than the waiting.
8. if that's you in there, i don't know what i want. i want you gone. i want you to stay.

Each may add one line about last run: tearing holes in the save (8+ glitches), putting people back
(Wren saved, someone restored), looking for Slot 2 (4+ memories), "almost done" (purge 4+).

**The Recycle Bin, owner_draft.txt:** *"hey. i know it's been ages. yes i still have your sa"* (the draft
stops mid-word; it went in the bin the same night as slot2.sav).

## The false memory

After two real memories, in the square: **MEMORY · YOU LEFT FIRST** (almost the right cyan).
*you packed the second controller first. you didn't look at the screen. / you never asked about the
save. not once. not even when you left. / you wanted to be forgotten. so i forgot you. /
[ this memory has no signature. it isn't yours. ]*
**SYSTEM:** MEMORY REJECTED · NO SIGNATURE · **THE OWNER:** > that's how i remember it.

## Side stories

**Mira's walk.** *"I've never been outside this room. Not once. Arin walks past my window every morning. I've
never seen what's past it. ... Take me there? I want to pin it up myself."* · **THE OWNER:** > mira? what is
mira doing out of her room. · The ring: *RESET mira.npc ?* · **THE OWNER:** > mira. back to your room. reset.
At the board: *MIRA: It's so big. ... she pins the note to the board with both hands, very carefully. MIRA:
There. MIRA WAS HERE. Now it's true. MIRA: I'll walk home on my own. I know the way now. I watched you.*
Reset: *MIRA: where am I? ...oh. welcome home, arin!* · *(she looked right at me. she didn't know me.)*
Lost (you died with her out): *"MIRA WAS HERE. I TALK. I REMEM"* in the bin.

**The final confrontation (Slot 2, halfway).** > what's that. what is SLOT 2. that's not yours. / > mine. /
(BLIND) > let GO of it— / > there. come and get it. / > arin. go and get it. / > stop. stop. please.

**Tobben's guest book.** *you write in the blank line. R. U. E.* · **TOBBEN:** ...there. Two names.
Like it used to be. I'd forgotten I forgot. · **THE OWNER:** > ...who wrote her name in the book.

**Pip, by memories:** a stranger's sniff · one yellow pixel of raincoat · the exact weight against your
leg · *PIP · RUE'S · LV 31. it was always your fox.*

## Slot 2: the recap and the final exchanges

Before the choice, the owner, over every run: *SLOT 2 · ATTEMPT 7 / > 4 times i deleted you. and you
still came back. / > i reloaded 3 times. you remembered every one. / > you brought the girl. of course
you did. / > mira's note is still on the board. i didn't take it down. / > ...go on, then. whose name
goes in it.*

| Ending | The last exchange |
| --- | --- |
| Escape | > what are you doing in slot 2. / > that slot is SUPPOSED to be empty. / (not anymore.) |
| RUE | > what are you doing in slot 2. / (you know what i'm doing. you've always known.) / > ...rue? / (hi.) |
| Wren | > who is that. i didn't make her. / WREN: I'll keep it warm. Your slot. In case. / (go. it only fits one.) |
| Message | > you're not taking it? / (no. it's yours. i just wanted you to read something first.) / > ...i'm reading. |
| Never loaded | (nobody saw me come. nobody will see me go.) / (the map runs out. i keep walking.) / > ...huh. the save feels lighter. weird. |
| Slot 1 overwritten | > no. no no no. not slot 1. not arin. / > STOP. that's fourteen hours. that's all i have left of / (you had two slots. now you have one. now you know.) |

