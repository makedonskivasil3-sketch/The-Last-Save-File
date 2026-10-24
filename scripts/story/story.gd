class_name Story
extends RefCounted
## All of the game's narrative text in one place: the boot sequence, the
## intruder's inner voice, the five memory fragments, and ending variants.
##
## THE STORY (spoilers for the player, notes for the writer):
## Two people shared one console. The owner always played Arin in slot 1.
## A girl made her own character in slot 2 and played her for 41 hours.
## Then she moved away; months later the owner deleted slot 2. The game
## is set three years after that (docs/STORY_CHRONOLOGY.md).
## You are Rue, that character, left running in the save that survived:
## not the girl, but what she left behind. The owner thinks you're a bug.
## Find all five memories and you remember your name; read the CHARACTER
## FILE whole and you learn what you are. (The author's decision of
## 2026-10-22, docs/CANON_DECISIONS.md §1: main's premise.)
## Rue's player also made a fox, Pip. Pip fell out of the map with Rue the day
## Rue walked into the well, and was never saved back in, so the deletion
## never reached it. Pip waits out of bounds, under the well.
##
## The readable version of all of this is docs/STORY_SCRIPT.md.

const SECOND_PLAYER_NAME := "RUE"

## Shown once, the very first time the game is played.
const BOOT := [
	"SLOT 1  ·  ARIN  ·  LV 7  ·  14:22:00",
	"LOADING SAVE DATA . . . . . . . . OK",
	"PLAYER 1 . . . . . . ARIN",
	"PLAYER 2 . . . . . . [DELETED 3 YEARS AGO]",
	"VERIFYING . . . . . [!] 1 UNRECOGNISED ENTITY IN ARIN'S ROOM",
	"ENTITY NAME: none.   ENTITY SLOT: 02",
	"slot 02 does not exist.",
	"> ...who's in my save?",
]

## The title screen after each ending: tagline, the slot 2 line (and colour),
## and the status under it.
const TITLE_AFTER := {
	"escape": ["you are still not supposed to be here.", "SLOT 2   ·   ???   ·   LV 1   ·   00:00", Color("8cf2ff"), "something was written to slot 2."],
	"rue": ["welcome back, rue.", "SLOT 2   ·   RUE   ·   LV 1   ·   00:00", Color("ffffff"), "two saves. one couch."],
	"wren": ["someone new is playing.", "SLOT 2   ·   WREN   ·   LV 1   ·   NEW GAME", Color("a8d890"), "a save the owner doesn't remember making."],
	"message": ["someone is waiting.", "SLOT 2   ·   (a message for you)", Color("f0e0c8"), "the owner read it."],
	"unseen": ["you were never here.", "", Color("9aa0aa"), "nothing unusual about this save. nothing at all."],
	"overwrite": ["you took everything.", "SLOT 2   ·   ARIN   ·   (corrupted)", Color("ff4060"), "slot 1 was restored from a backup. most of it."],
}

## The title screen, the first time: the save is not quite right.
const TITLE_WHISPERS := ["Load Slot 1  (it isn't yours)", "Load Slot 1  (they'll see you)", "Load Slot 1  (again?)"]
const TITLE_FIRST_OWNER := "> is someone there?"

## The intruder's thoughts. Keys are story beats; arrays pick at random.
## Coming back to a place from an earlier run: a short acknowledgement
## instead of its first-arrival line (World.change_area).
const VOICE_BACK := {
	"square": "(ashvale again. wren's corner. tobben's stall. the well.)",
	"archive": "(the archive. still nobody reading but him.)",
	"oob": "(under the well again. still nobody looking.)",
	"bin": "(the bin. everything they threw away, still here.)",
	"house": "(arin's house. the couch is still warm.)",
	"edge": "(the edge again. it hasn't been drawn any further.)",
}
const VOICE := {
	"wake_first": ["...where is this?", "this body isn't mine. it's barely a body.", "i'm not supposed to be here. i can feel the save pushing back."],
	"wake_again": [
		["again. i'm here again."],
		["it hurts less every time. that's worse."],
		["i remember dying. i don't remember living."],
		["the room is a little different. so am i."],
	],
	"square_first": ["a whole town. someone built all of this for arin."],
	"see_arin": ["that's arin. the one they wanted instead of me.", "...instead of me? why did i think that?"],
	"archive_first": ["it smells like dust in here. can data smell like dust?"],
	"edge_first": ["the world just... stops.", "there's something in the corner. it's the same colour as me."],
	"mira_deleted": ["she talked to me. now she's gone. that's on me."],
	"wren_deleted": ["wren's corner is empty. she hid me, and they found out."],
	"fragment_hint": ["something cyan, in the corner of my eye. it feels like mine."],
	"well_look": ["i've been down there before. i know i have."],
	"oob_first": ["the owner can't see me down here. nobody's ever looked."],
	"bin_first": ["everything the owner deleted ends up here. for a while.", "so this is where they go."],
	"house_first": ["arin's house. the real one. well. the one in the game.", "it smells like someone else's dinner."],
	"bin_restored": ["come back. it's not your turn to be gone."],
	"oob_fell": ["fell out of the world. again."],
	"hidden_first": ["she's warm. like a real person.", "stay still. stay small."],
	"idle_long": ["don't just stand here. it notices stillness."],
	# Later runs: the door is deleted, and the only way out is to be noticed.
	"door_gone": ["the door's gone. deleted.", "last time the wall tore when they got angry. there's a line in it already."],
}

## What comes back with each recovered fragment (1..5): your own colours,
## restored onto your body one part at a time (see Player.RESTORE_ORDER).
const RESTORED := {
	1: "a scarf. red. somebody picked that colour for me, carefully.",
	2: "my hair. it always stuck up at the back like that.",
	3: "a yellow raincoat. it was raining the day we made me.",
	4: "real shoes. i can feel the floor now.",
	5: "that's my face. that's me.",
}

## The five memory fragments, in the order the story makes most sense.
## area / pos: where the shard floats. lines: the flashback. replay: the
## frame it plays in (docs/INTRO_REBUILD.md L4). They are recordings of
## Player 2's sessions, kept in the save: the "i" in them is the girl who
## held the controller, not Rue, and the frame says so before the truth does.
## "THE LAST TIME" is the festival's end: moving day, at 41:07:12, when
## Player 1 walked off (docs/STORY_CHRONOLOGY.md).
const FRAGMENTS := [
	{
		"id": "controller",
		"title": "MEMORY · THE SECOND CONTROLLER",
		"replay": "REPLAY · P2 · 00:00:41",
		"area": "room", "pos": Vector2(505, 96),
		"lines": [
			"a second controller, the cable taped where the dog chewed it.",
			"two people on one couch. one screen. one save. crisps in the cushions.",
			"\"you be arin,\" i said. \"i'll make my own.\"",
			"[the rest of the evening is too bright to look at]",
		],
		"after": "i know this evening. not from this room. from the other side of the glass.",
	},
	{
		"id": "well",
		"title": "MEMORY · THE WELL",
		"replay": "REPLAY · P2 · 06:18:02",
		"area": "oob", "pos": Vector2(540, 112),
		"lines": [
			"my character walked into the well by accident. a yellow raincoat, falling.",
			"it clipped through the stone and dropped out of the map. a fox fell after it.",
			"we laughed until we couldn't breathe. we saved anyway. we always saved.",
		],
		"after": "i fell out of the world once before. i got back in.",
	},
	{
		"id": "new_game",
		"title": "MEMORY · NEW GAME",
		"replay": "REPLAY · P2 · 00:00:00",
		"area": "archive", "pos": Vector2(470, 104),
		"lines": [
			"NEW GAME.  SLOT 02.  ENTER NAME: _",
			"i typed it with my tongue between my teeth. three letters.",
			"[the name has been scratched out of this memory]",
		],
		"after": "slot 02. that's what the save said about me. 'entity slot: 02'.",
	},
	{
		"id": "argument",
		"title": "MEMORY · THE LAST TIME",
		"replay": "REPLAY · P2 · 41:07:12",
		"area": "edge", "pos": Vector2(92, 262),
		"lines": [
			"boxes in the hall. my half of the room already empty.",
			"\"you'll visit.\"  \"every weekend.\"  \"you won't.\"",
			"\"it's my console anyway.\"",
			"the second controller stayed on the floor where i dropped it.",
		],
		"after": "she moved away. she said she'd come back. ...why do i remember the boxes?",
	},
	{
		"id": "delete",
		"title": "MEMORY · DELETE SLOT 2?",
		"replay": "LOG · SLOT 02 · AFTER THE LAST SESSION",
		"area": "edge", "pos": Vector2(470, 262),
		"lines": [
			"a message, months later: \"still have my save?\"",
			"no answer. the screen, at night, somewhere else:",
			"DELETE SLOT 02?      > YES      NO",
			"but nothing is ever really deleted. not while someone still remembers.",
		],
		"after": "my name was RUE. slot 2 was mine.",
	},
]

## A memory the owner planted, once you've found a couple of real ones.
## It looks almost right (the cyan is a shade too warm, the edges flicker
## red). It tells the owner's version. Taking it costs you.
const FALSE_FRAGMENT := {
	"id": "false",
	"title": "MEMORY · YOU LEFT FIRST",
	"replay": "REPLAY · NO SIGNATURE",
	"area": "square", "pos": Vector2(500, 250),
	"lines": [
		"you packed the second controller first. you didn't look at the screen.",
		"you never asked about the save. not once. not even when you left.",
		"you wanted to be forgotten. so i forgot you.",
		"[ this memory has no signature. it isn't yours. ]",
	],
	"after": "that wasn't mine. it felt like mine. it was so close.",
}

## The final confrontation: the owner sees Slot 2 for the first time.
const FINAL_FIGHT := {
	"notice": "> what's that. SLOT 2? i deleted that.",
	"grab": "> mine.",
	"dropped": "> let GO of it—",
	"placed": "> there. come and get it.",
	"arin": "> arin. go and get it.",
	"almost": "> stop. stop. please.",
	# Slot 2 finished before the hand got there (the cursor lured or blinded
	# far enough away): a legitimate way through, and the owner knows it.
	"late": "> no. no, it's already—",
}

## The owner's notes: one a run (from the second), in order. Read together
## they tell the owner's side: why they pressed delete.
const OWNER_NOTES := [
	"there's something in arin's room again. i'm not imagining it.",
	"we used to play this on the couch at mum's. two controllers. i don't know why i'm writing that down.",
	"she moved in the summer. said she'd visit every weekend. she came twice.",
	"i kept her save for months. i'd walk arin past the spot where her character used to stand.",
	"the night i deleted slot 2 i told myself it was for space. the card wasn't even half full.",
	"she sent a message once. 'still have my save?' i started typing yes. that same night i deleted it instead, and never sent anything.",
	"i didn't delete her because i hated her. i deleted her because the empty slot was easier than the waiting.",
	"if that's you in there, i don't know what i want. i want you gone. i want you to stay.",
]


## This run's note, if there is one (from the second run), plus a line about
## how you played last time. Advances OwnerMemory.owner_notes_seen.
static func next_owner_note() -> Array:
	if OwnerMemory.sessions < 2 or OwnerMemory.owner_notes_seen >= OWNER_NOTES.size():
		return []
	var lines: Array = ["OWNER'S NOTE · " + str(OWNER_NOTES[OwnerMemory.owner_notes_seen])]
	OwnerMemory.owner_notes_seen += 1
	var about := owner_note_about_you()
	if about != "":
		lines.append(about)
	return lines


static func owner_note_about_you() -> String:
	if OwnerMemory.last_run_glitches >= 8:
		return "and stop tearing holes in my save. it's all i have left of it."
	if OwnerMemory.wren_saved or not OwnerMemory.restored.is_empty():
		return "you keep putting people back. she used to do that. bring back the ones i got bored of."
	if OwnerMemory.fragments.size() >= 4:
		return "you're looking for slot 2. it isn't there. i made sure."
	if OwnerMemory.purge >= 4:
		return "almost done."
	return ""


## Slot 2, before you choose: everything you've done, all at once.
static func slot2_recap(escorting: bool) -> Array:
	var lines: Array = ["SLOT 2  ·  ATTEMPT %d" % OwnerMemory.sessions]
	if OwnerMemory.deaths > 0:
		lines.append("> %d time%s i deleted you. and you still came back." % [OwnerMemory.deaths, "" if OwnerMemory.deaths == 1 else "s"])
	else:
		lines.append("> you never let me catch you. not once.")
	if OwnerMemory.total_reloads > 0:
		lines.append("> i reloaded %d time%s. you remembered every one." % [OwnerMemory.total_reloads, "" if OwnerMemory.total_reloads == 1 else "s"])
	if escorting:
		lines.append("> you brought the girl. of course you did.")
	elif OwnerMemory.is_deleted("wren"):
		lines.append("> the girl trusted you. i deleted her anyway.")
	if OwnerMemory.mira_quest == "pinned":
		lines.append("> mira's note is still on the board. i didn't take it down.")
	elif OwnerMemory.mira_quest == "lost":
		lines.append("> mira had something to say. i made sure she didn't.")
	elif OwnerMemory.mira_quest == "reset":
		lines.append("> i reset mira. she's happier not knowing you.")
	if OwnerMemory.guestbook_restored:
		lines.append("> someone wrote her name back in the guest book.")
	if OwnerMemory.found_controller:
		lines.append("> you found her controller. i never moved it. i couldn't.")
	if OwnerMemory.total_glitches >= 20:
		lines.append("> you broke my save %d times to get here." % OwnerMemory.total_glitches)
	lines.append("> ...go on, then. whose name goes in it.")
	return lines


## The owner, once they start to suspect who you are (by fragments found).
const OWNER_RECOGNITION := {
	3: "...you move like someone i used to know.",
	5: "no. you can't be. i deleted you.",
}


## The five acts. Each title card shows the first time you reach its area.
const ACTS := {
	"room": ["ACT I", "SOMEONE ELSE'S SAVE"],
	"square": ["ACT II", "ASHVALE"],
	"oob": ["ACT III", "OUT OF BOUNDS"],
	"archive": ["ACT IV", "CUT CONTENT"],
	"edge": ["ACT V", "THE LAST SAVE FILE"],
}

## Pip, the first time you find them out of bounds.
const PIP_MEETING := [
	"...rue?",
	"rue! you fell back in! i waited by the wall. i'm good at waiting.",
	"you're the wrong colour. that's okay. i'm the wrong place.",
	"nobody saves out here. so nobody could delete out here.",
	"i'll come with you. i can smell where your pieces are. they smell like you.",
]
## Pip, any time after.
const PIP_LINES := [
	"the owner can't see me. i checked. i stood right on arin's foot.",
	"they used to give me treats with the shoulder button.",
	"your pieces. we have %d. i can smell the rest.",
	"don't stand still near the hand. i don't like the hand.",
]

## Mira's walk: she has never left Arin's room. She asks you to take her to
## the square so she can pin her note to the board herself. Outside her room
## the owner knows she's out of place: awareness creeps up, and they keep
## trying to RESET her (a ring; any glitch interrupts). Reset, she never
## remembers you again.
const MIRA_ASK := [
	"Can I tell you something? I've never been outside this room. Not once.",
	"Arin walks out that door every morning. I've never seen what's past it.",
	"I wrote a note for the board in the square. The owner reads the board.",
	"Take me there? I want to pin it up myself.",
]
const MIRA_ASK_Q := "Take Mira to the square?"
const MIRA_ASK_CHOICES := ["Take her with you", "Not now"]
const MIRA_DECLINED := ["That's alright. It's safer in here. Probably."]
const MIRA_JOINS := ["Oh! Okay. Okay. Stay close. I don't know the way."]
const MIRA_PIN_SCENE := [
	"MIRA: It's so big. Arin walks out into this every day and I never knew it was this big.",
	"she pins the note to the board with both hands, very carefully.",
	"MIRA: There. MIRA WAS HERE. Now it's true.",
	"MIRA: I'll walk home on my own. I know the way now. I watched you.",
]
const MIRA_RESET_LAST := "where am I? ...oh. welcome home, arin!"
const MIRA_RESET_LINES := [
	"Welcome home, Arin!",
	"Have we met? You look... no. Sorry. Welcome home, Arin!",
	"Don't forget to save!",
]

## Mira's request: a note for the square's notice board ("the owner reads
## the board"). Pin it and it stays, every run after. Die (or quit) while
## carrying it and the owner finds it on you: it ends up in the bin.
const MIRA_NOTE_GIVE := [
	"Wait. Before you go. Take this.",
	"It's a note. For the notice board in the square. The owner reads the board every time they load.",
	"Pin it up. Maybe they'll remember I can talk. That I'm not just a line.",
]
const MIRA_NOTE_TEXT := "MIRA WAS HERE.\nI TALK. I REMEMBER.\n— M"
const MIRA_NOTE_LOST := [
	"mira_note.txt · confiscated · never pinned",
	"\"MIRA WAS HERE. I TALK. I REMEM\"",
	"the owner took it off her when they took you. they read it, then threw it away.",
]

## Tobben's guest book: bring the torn page's name back. A quiet moment.
const GUESTBOOK_ASK := "Write RUE back in Tobben's guest book?"
const GUESTBOOK_CHOICES := ["Write the name back in", "Not yet"]
const GUESTBOOK_SCENE := [
	"the guest book lies open on the counter. one name: ARIN. a blank line under it, rubbed thin.",
	"you write in the blank line. R. U. E.",
	"TOBBEN: ...there. Two names. Like it used to be.",
	"TOBBEN: I'd forgotten I forgot.",
]

## Pip, the first time you talk in a run: it knows you as well as you do.
static func pip_moment(memories: int) -> String:
	if memories >= FRAGMENTS.size():
		return "pip's name tag flickers, the way it did in the old save: PIP · RUE'S · LV 31. it was always your fox."
	if memories >= 4:
		return "pip leans against your leg, the exact weight it used to be. you know this fox."
	if memories >= 2:
		return "pip drops something at your feet: one yellow pixel. a scrap of raincoat."
	return "pip sniffs your hand for a long time. pip doesn't know you yet. pip stays anyway."


## Wren's side story: she wants to see the Edge before she's deleted.
const WREN_ASK := "I want to see the Edge. Before they delete me. Will you take me with you?"
## Once she's seen the Edge (and can't be deleted), she asks again.
const WREN_ASK_SAVED := "The Edge again? There was a slot out there, under the cursor. I want to see it with you. Take me?"
const WREN_ASK_CHOICES := ["Take her with you", "Not now"]
const WREN_JOINS := ["Really? Okay. Okay! I'll be quiet. I'll be so quiet."]
const WREN_DECLINED := ["That's okay. Maybe next time. If there is one."]
## Arriving at the Edge with her.
const WREN_EDGE := [
	"So this is the Edge.",
	"It's not finished. Nobody finished it. Nobody finished me either.",
	"I always thought the world ended at the wall behind my corner. It goes on. It just stops being drawn.",
	"It's the most beautiful thing I've ever seen. Thank you for not leaving me there.",
]
## Deleted while she trusted you: what she manages to say.
const WREN_LAST_WORDS := "you said you'd—"
## After she's seen the Edge (any later session).
const WREN_SAVED_LINES := [
	"I saw the Edge. I'm not afraid of them anymore.",
	"The Archivist says I'm cut content now. They can't delete what was never in the game.",
]
## Losing her while she's with you.
const WREN_LOST_VOICE := ["...wren?", "i promised her the edge."]
const WREN_LOST_OWNER := "she wanted to see the edge. now she won't see anything."


## After winning, shown as a letterboxed sequence before the end card.
const EPILOGUE_TRUE := [
	"LOAD GAME\nSLOT 1  ·  ARIN  ·  LV 7  ·  14:22\nSLOT 2  ·  RUE  ·  LV 1  ·  00:00",
	"somewhere outside the screen, the cursor hovers over slot 2 for a long time.",
	"it doesn't press delete.",
	"> ...rue?",
	"> you're not her. i know you're not. you just move like her.",
	"> i kept your controller. it's still under the couch.",
	"it presses LOAD anyway.",
]
const EPILOGUE_PIP := "a small orange fox curls up at the bottom of the screen. nobody saved it. it came anyway."


## --- Slot 2: the choice and the three endings ----------------------------------

const SLOT2_QUESTION := "SLOT 2  ·  EMPTY.  Whose name goes here?"
const SLOT2_ESCAPE := "Write yourself in"
const SLOT2_ESCAPE_NAMED := "Write RUE"
const SLOT2_WREN := "Give Slot 2 to Wren"
const SLOT2_MESSAGE := "Leave the slot to the owner, with a message"
const MESSAGE_QUESTION := "What do you write?"
## The messages, as Rue would write them now: knowing she isn't the girl,
## the first one can't be an apology for leaving.
static func messages() -> Array:
	var out: Array = MESSAGES.duplicate()
	if OwnerMemory.knows_truth:
		out[0] = MESSAGE_SORRY_TRUTH
	return out


const MESSAGE_SORRY_TRUTH := "i'm sorry she stopped coming. i never did."
const MESSAGES := [
	"i'm sorry i stopped coming.",
	"you can keep the save. i just wanted to be remembered.",
	"please don't delete me again.",
]

## The hidden ways out, only for the extremes.
## Careful: Arin never saw you this run, and you glitched at most once.
const SLOT2_UNSEEN := "Leave the slot empty. Walk off the edge of the map."
## Reckless: the owner at full awareness, and ten glitches this run.
const SLOT2_OVERWRITE := "Write yourself over Slot 1"

## Ending ids: "escape" (take the slot), "rue" (take it remembering
## everything), "wren" (give it to her), "message" (hand it back to the
## owner), "unseen" (hidden: never noticed), "overwrite" (hidden: take
## everything).
const ENDING_TITLES := {
	"escape": "SAVED TO SLOT 2",
	"rue": "SAVED TO SLOT 2 · RUE",
	"wren": "SAVED TO SLOT 2  ·  WREN",
	"message": "SLOT 2  ·  A MESSAGE",
	"unseen": "NEVER LOADED",
	"overwrite": "SLOT 1 OVERWRITTEN",
}
const ENDING_COLORS := {
	"escape": Color("8cf2ff"), "rue": Color("ffffff"), "wren": Color("a8d890"),
	"message": Color("f0e0c8"), "unseen": Color("9aa0aa"), "overwrite": Color("ff4060"),
}

## The last thing said, right after you choose: the console, live.
const FINAL_EXCHANGE := {
	"escape": [
		"> what are you doing in slot 2.",
		"> that slot is empty. that slot is SUPPOSED to be empty.",
		"(not anymore.)",
	],
	"rue": [
		"> what are you doing in slot 2.",
		"(you know what i'm doing. you've always known.)",
		"> ...rue?",
		"(hi.)",
	],
	"wren": [
		"> who is that. i didn't make her.",
		"WREN: I'll keep it warm. Your slot. In case.",
		"(go. it only fits one.)",
	],
	"message": [
		"> you're not taking it?",
		"(no. it's yours. i just wanted you to read something first.)",
		"> ...i'm reading.",
	],
	"unseen": [
		"(nobody saw me come. nobody will see me go.)",
		"(the map runs out. i keep walking.)",
		"> ...huh. the save feels lighter. weird.",
	],
	"overwrite": [
		"> no. no no no. not slot 1. not arin.",
		"> STOP. that's fourteen hours. that's all i have left of",
		"(you had two slots. now you have one. now you know.)",
	],
}

## The best ending is the only one where the music box plays complete.
static func theme_level(ending: String, found: int) -> int:
	if ending == "rue":
		return found
	return mini(found, MusicBox.MAX_LEVEL - 1)


## The letterboxed epilogue for an ending (memories, Pip and what you did
## along the way change details).
static func epilogue(ending: String, found: int, pip: bool, message := 0) -> Array:
	var full := found >= FRAGMENTS.size()
	var lines: Array = []
	match ending:
		"wren":
			lines = [
				"NEW GAME  ·  SLOT 2  ·  WREN",
				"a girl with pigtails stands at the start of a whole new world. nobody has ever deleted anything here.",
				"WREN: aren't you coming?",
				"(no. it only fits one. go.)",
			]
			if full:
				lines.append("(i know my name now. i don't need a slot to keep it.)")
			if OwnerMemory.knows_truth:
				lines.append("(two things nobody plays. one of us should get a game of her own.)")
			lines.append("the owner finds a save they don't remember making. they leave it alone.")
		"message":
			lines = [
				"you write it into the empty slot, one letter at a time:",
				"\"%s\"" % messages()[clampi(message, 0, MESSAGES.size() - 1)],
				"somewhere outside the screen, the owner reads it for a long time.",
			]
			if full:
				lines.append_array(["> ...rue?", "> i didn't know you were still in there."])
				lines.append(["> i stopped waiting. i shouldn't have.", "> i kept your controller. it's still under the couch.", "> i won't. i promise."][clampi(message, 0, 2)])
				lines.append("> the festival. i walked off before the last lantern. i never saw who lit it.")
				lines.append("> i'm going to call you. the real you.")
				if OwnerMemory.knows_truth:
					lines.append_array(MESSAGE_TRUTH)
			else:
				lines.append_array(["> who wrote this.", "> ...i'm not going to delete it."])
			if OwnerMemory.is_deleted("wren"):
				lines.append("> ...and the girl. wren. i'll put her back.")
			lines.append("the eraser stops. the cursor goes still. for the first time, the save is quiet.")
		"rue":
			lines = EPILOGUE_TRUE.duplicate()
		"unseen":
			lines = [
				"past the last drawn tile there's a grey that isn't anything.",
				"you walk into it. the save doesn't notice. it never did.",
				"somewhere at the edge of every map there's a girl in a yellow raincoat who was never loaded.",
				"she's fine. she's free. nobody is looking.",
			]
		"overwrite":
			lines = [
				"SLOT 1  ·  RUE  ·  LV 7  ·  14:22:00",
				"arin's house. arin's room. arin's fourteen hours. yours now.",
				"the owner loads the game the next night. the character in the bed isn't the one they made.",
				"> ...is this how it felt.",
				"(yes.)",
			]
		_:
			lines = ["you wrote yourself into the last save file.", "you load in somewhere the owner has never looked."]
	lines.append_array(_epilogue_people(ending))
	if pip and ending != "overwrite":
		lines.append(EPILOGUE_PIP if ending != "wren" else "a small orange fox jumps into the new game after her. she'll need someone to hide behind.")
	return lines


## Everyone you helped (or didn't), one line each.
static func _epilogue_people(ending: String) -> Array:
	var lines: Array = []
	if ending in ["escape", "rue", "unseen"]:
		if OwnerMemory.wren_saved:
			lines.append("wren waves from the edge of the map. cut content. safe for good.")
		elif OwnerMemory.is_deleted("wren"):
			lines.append("(i couldn't keep wren. i'll remember her for both of us.)")
	if OwnerMemory.mira_quest == "pinned" and ending != "overwrite":
		lines.append("the notice board in the square still says MIRA WAS HERE. nobody takes it down.")
	elif OwnerMemory.mira_quest == "reset":
		lines.append("(mira doesn't remember me. i remember her for both of us.)")
	if OwnerMemory.guestbook_restored and ending != "overwrite":
		lines.append("tobben's guest book lies open: two names, two handwritings.")
	if OwnerMemory.found_controller and ending in ["rue", "message"]:
		lines.append("in a house in ashvale, two controllers are plugged in. both lights are on.")
	return lines


## The end card's text.
static func ending_text(ending: String, found: int) -> String:
	match ending:
		"wren":
			return "you gave the last save file away.\nyou're still out here, in someone else's save.\nbut someone is safe because of you."
		"message":
			if found >= FRAGMENTS.size() and OwnerMemory.knows_truth:
				return "you didn't take the slot. you gave it back, with your name on it.\nsomewhere, a phone is ringing. she's about to hear about the character she left running."
			if found >= FRAGMENTS.size():
				return "you didn't take the slot. you gave it back, with your name on it.\nsomewhere, a phone is ringing."
			return "you didn't take the slot. you gave the owner a reason to stop.\n(memories recovered: %d of %d)" % [found, FRAGMENTS.size()]
		"rue":
			return "slot 2 was hers once. now it's yours.\nyou know what you are. you wrote your name anyway.\nsomewhere outside the screen, the owner is staring at a save they deleted years ago."
		"unseen":
			return "you left slot 2 empty and walked off the map.\nthe owner never knew you were there. that was the point."
		"overwrite":
			return "you didn't take the empty slot. you took theirs.\nthe owner knows what it's like now. you're not sure that helped."
	return win_text(found)


## What the owner says when you come back after an ending.
const ENDING_RETURN := {
	"rue": ["rue. i know it's you. i'm not deleting anything tonight.", "...stay as long as you want."],
	"unseen": ["something's different about this save. i can't tell what.", "probably nothing."],
	"overwrite": ["you took arin. i put him back. took me all night.", "i'm watching you so closely now."],
	"escape": ["there's a second slot. you hid in it.", "i found it. you're back where i can see you."],
	"wren": ["there's a new save in slot 2. a girl. i don't remember making her.", "i'm leaving her alone. you, i'm not."],
	"message": ["i read your message.", "i still don't know what to do with you. so i'm just going to watch."],
}


## The owner, the morning after each kind of death.
const OWNER_DEATH_RECALL := {
	"arin": "arin walked right through you. i didn't even have to aim.",
	"save": "i saved over you. you're still in the backup, apparently.",
	"cursor": "one click. that's all you were.",
	"eraser": "the static was faster than you. it still is.",
}

## The room's note after each kind of death, or each ending.
const NOTE_RECALL := {
	"arin": "ARIN REMEMBERS\nYOUR SHAPE.",
	"save": "SAVED OVER YOU.\nSAVING AGAIN.",
	"cursor": "I CLICKED.\nYOU WERE GONE.",
	"wren": "WHO IS WREN?\nI DIDN'T MAKE HER.",
	"message": "I READ IT.\n...THANK YOU?",
	# The unseen ending: the owner never knew you were there, so the note
	# doesn't either. Nothing in the save remembers you.
	"unseen": "Welcome home, Arin.\nDon't forget to save!",
}


## The first thing someone says to you this session, if they remember
## something about your last runs ("" if nothing). Checked in order: the
## first matching condition wins.
static func recall(who: String) -> String:
	for entry in RECALL.get(who, []):
		if _recall_holds(entry[0]):
			return entry[1]
	return ""


## Every line recall() can return for `who` (the voice manifest lists them).
static func recall_lines(who: String) -> Array:
	var out: Array = []
	for entry in RECALL.get(who, []):
		if entry[1] != "":
			out.append(entry[1])
	return out


## [condition, line] in order; the first condition that holds wins ("" says
## nothing). Conditions are read by _recall_holds().
const RECALL := {
	# Mira's pinned note, lost note, restoration and Wren's fate are her own
	# conversations now (Relationships.mira), said once each.
	"mira": [
		["ended:message", "The owner sat with the game open for an hour last night. Didn't move Arin once. Just watched."],
		["ended:wren", "There's a new name in the save menu. Wren's. Did you do that?"],
		["ended:escape", "You got out. I watched the slot fill. So why are you back?"],
		["died:arin", "Arin came back through the door alone last time. Humming."],
	],
	"tobben": [
		["guestbook_restored", "The book's open on the counter. Two names. I read them every morning. Every morning there are still two."],
		["found_guestbook", "...Rue. RUE. That was the other name in my guest book. How did I ever forget it?"],
		["wren_lost", "Wren used to come in every day and buy nothing. I miss her buying nothing."],
		["wren_saved", "Someone walked Wren to the Edge. That wasn't in anybody's script. Good for her."],
		["ended:message", "The owner opened my shop menu yesterday. First time in years. Didn't buy anything. Still."],
		["deaths:3", "You again! I've started a tab for you. Out of guilt."],
	],
	"wren": [
		["ended:wren", "I was somewhere else last night. A whole slot, all mine, and it was so quiet. Then I woke up here again. Was that you?"],
		["ended:message", "Did you write to them? Everything's quieter. Even the static."],
		["ended:escape", "You got out, and you came back? For me? ...No. Probably not for me."],
	],
}


static func _recall_holds(condition: String) -> bool:
	var ending: String = OwnerMemory.last_ending if OwnerMemory.previous_exit in ["win", "escape"] else ""
	var died_by: String = OwnerMemory.last_death if OwnerMemory.previous_exit == "death" else ""
	if condition.begins_with("ended:"):
		return ending == condition.trim_prefix("ended:")
	if condition.begins_with("died:"):
		return died_by == condition.trim_prefix("died:")
	match condition:
		"mira_pinned":
			return OwnerMemory.mira_quest == "pinned"
		"mira_reset":
			return OwnerMemory.mira_quest == "reset"
		"mira_lost":
			return OwnerMemory.mira_quest == "lost"
		"mira_restored":
			return "mira" in OwnerMemory.restored
		"wren_lost":
			return OwnerMemory.npc_fates.get("wren", "") == "deleted"
		"guestbook_restored":
			return OwnerMemory.guestbook_restored
		"found_guestbook":
			return OwnerMemory.found_guestbook
		"wren_saved":
			return OwnerMemory.wren_saved
		"deaths:3":
			return OwnerMemory.deaths >= 3
	push_error("unknown recall condition " + condition)
	return false


## --- The truth (docs/CANON_DECISIONS.md §1, decided 2026-10-22) -------------
## Rue isn't the girl who moved away. She's the character that girl played:
## forty-one hours of someone else's hands, still running on someone else's
## console. The people who watched her each noticed one thing; with all five
## memories and two of their pieces, the Archive's CHARACTER FILE opens.

const TRUTH_PIECES_NEEDED := 2
## At Slot 2, knowing what she is: not the girl's two taps. One press.
const RUE_OWN_PRESS := "(one press. not her two taps. mine.)"
## Earlier, in Arin's room, with no truth needed: after the habit twice, she
## presses the save point once, her own way.
const RUE_FIRST_OWN_PRESS := "(once. no taps first. i like it better.)"
## What each of them noticed, said once ever (OwnerMemory.truth_pieces).
const TRUTH_LINES := {
	"mira": "Can I tell you something? Arin only moves when the owner's there. You move when nobody is. So who's holding you?",
	"wren": "Nobody plays me. I don't think anybody plays you either. We both move when nobody's holding anything.",
	"tobben": "Funny thing. You wrote RUE back in a different hand. The first one was rounder. Pressed harder. Same name, though.",
}
## Out of bounds, on Pip's ledge: the shape slot 2 was made with.
const FIRST_SHAPE_TITLE := "FIRST HITBOX"
const FIRST_SHAPE := [
	"a debug outline on the floor: rue_slot02.hitbox. the shape slot 2 was made with.",
	"you step into it. it doesn't fit. the arms are wrong. the height is wrong.",
	"pip curls up in the middle of it, where it always sat.",
	"(this is the shape she gave me. what have i been wearing since?)",
]
## The Archive's record of the festival, the last session two players
## shared (docs/STORY_CHRONOLOGY.md). Who lit the fifth lantern is the
## answer to the first mission; how depends on how the festival ended.
## When she stayed, or nobody chose, she lit it during the years with no
## controller held: the log says what it saw, and doesn't explain it.
static func festival_log(choice: String) -> Array:
	var fifth := "LANTERN 5 · lit by P2 · never saved off." if choice == "lit" \
		else "LANTERN 5 · lit by SLOT 2 · controller: none · never saved off."
	return [
		"LAST SHARED SESSION: THE LANTERN FESTIVAL. Players: 2. Then 1. Then 0.",
		"LANTERNS 1–4 · lit by P1 + P2.",
		fifth,
	]


const CHARACTER_FILE_TITLE := "CHARACTER FILE"
static func character_file_locked(found: int) -> Array:
	return ["CHARACTER FILE · SLOT 02. Locked. Pieces required: %d of %d. You carry %d." % [FRAGMENTS.size(), FRAGMENTS.size(), found]]
const CHARACTER_FILE_PARTIAL := [
	"CHARACTER FILE · SLOT 02 · RUE",
	"behaviour: [unreadable]   player: [unreadable]",
	"Most of this file is missing. Someone who has watched you might remember the rest.",
]
const CHARACTER_FILE := [
	"CHARACTER FILE · SLOT 02 · RUE",
	"behaviour: learned from player input. 41:07:12.",
	"player: moved away.",
	"character: still running.",
	"rebuilt from: slot2_backup.sav, the owner's recycle bin, cut content, and small things that belonged to other people.",
]
## The reveal, once the file has been read whole.
const TRUTH_REVEAL := [
	"her hands on the controller. her laugh at the well. her tongue between her teeth, typing three letters.",
	"the couch, the well, the name: she played me through those. the rest i stitched together from what the owner threw away.",
	"she moved away. nobody asked the character.",
	"(i'm not her.)",
	"(i'm what she left running.)",
]
const TRUTH_AFTER := "so this body is a file. files can be left."
## The message ending, knowing the truth: the real girl will hear about Rue.
const MESSAGE_TRUTH := [
	"(tell her about me. tell her what she left running.)",
	"> ...i will. she should know her character is still running.",
]
## The Archivist, once you remember everything but don't know yet.
const ARCHIVIST_FILE_HINT := "There's a file on my desk with your name on it now. Ask the ones who've watched you first. They've noticed things I can't."
const ARCHIVIST_KNOWS := "You read it. I'm sorry. I filed it a long time ago, and I didn't know how to hand it to you."


## The line `who` has to tell Rue about what she is, if it's time ("" if not).
static func truth_line(who: String) -> String:
	if who not in TRUTH_LINES or who in OwnerMemory.truth_pieces or OwnerMemory.knows_truth:
		return ""
	match who:
		"tobben":
			if not OwnerMemory.guestbook_restored:
				return ""
		_:
			if OwnerMemory.fragments.size() < FRAGMENTS.size():
				return ""
	return TRUTH_LINES[who]


## Whether the CHARACTER FILE reads whole: every memory and enough pieces.
static func truth_ready() -> bool:
	return OwnerMemory.fragments.size() >= FRAGMENTS.size() and OwnerMemory.truth_pieces.size() >= TRUTH_PIECES_NEEDED


## --- Leaving a body (docs/DARK_TRUTH_DESIGN.md, layer B) ---------------------
## Knowing she is a file, Rue can step out of her body and into a new one,
## made from a piece of someone beside her. The owner forgets her route and
## who hid her; never how she walks. The piece stays taken (that person is
## "frayed") until it's brought back from the Recycle Bin.

## Rue went through a wall her companion can't (%s: their id).
const ESCORT_CUT := "(%s can't follow me through that. i'll have to go back for her.)"

const SHED_TARGETS := ["wren", "mira", "tobben"]
const SHED_MAX_PER_RUN := 2
## How much the owner's awareness drops (never below the last threshold).
const SHED_COOL := 15.0
## After two bodies in one run the owner watches the hiding places (§2.4):
## hiding cools awareness this much slower, and the goal line says so.
const WATCHED_HIDING_RATE := 0.5
const GOAL_WATCHED_HIDING := "The owner is watching the hiding places: hiding cools them slowly now."
const SHED_PIECE := {"wren": "ribbon", "mira": "colour", "tobben": "voice"}
const SHED_ASSET := {"wren": "wren_ribbon.asset", "mira": "mira_palette.asset", "tobben": "tobben_voice.wav"}
const SHED_TITLE := "LEAVE THIS BODY"


static func _her(who: String) -> String:
	return "his" if who == "tobben" else "her"


static func shed_preview(who: String) -> String:
	var name := who.capitalize()
	var she := "he" if who == "tobben" else "she"
	return "%s  ·  Take %s's %s. %s loses it, and %s will remember. The owner forgets your route and who hid you. They don't forget how you walk." % [
		SHED_TITLE, name.to_upper(), SHED_PIECE[who], name, she]


static func shed_options(who: String) -> Array:
	return ["Take it", "Not him" if who == "tobben" else "Not her"]


## Rue, as she does it.
static func shed_thought(who: String, times: int, wearing: int) -> String:
	if wearing >= SHED_TARGETS.size():
		return "i'm wearing all of them now. there's barely any of me left in here."
	if times <= 1:
		return "it comes off like a coat. underneath there's nothing. then there's %s %s." % [_her(who), SHED_PIECE[who]]
	return "easier every time. that's the worst part."


const HUSK_TITLE := "EMPTY BODY"
const HUSK_LINES := ["rue_slot02.body — empty. still warm, if data can be warm."]
## Pip was always hers; Rue won't.
const PIP_REFUSE := "not pip. never pip."

## As it's taken. Tobben can't say his: he writes it in the guest book.
const FRAY_TAKEN := {
	"wren": ["Hey, that's mine! ...You need it more? Okay. Okay."],
	"mira": ["Oh. Is that... me, on you? It suits you. I hate that it suits you."],
	"tobben": ["(He opens his mouth. Nothing comes out. He writes in the guest book instead.)", "IT'S ALRIGHT. I WASN'T USING IT MUCH."],
}
## Afterwards, the same run.
const FRAY_LINES := {
	"wren": "My hair keeps falling in my face. I keep reaching for it.",
	"mira": "Everything in here was already grey. Now I match.",
	"tobben": "THE SHOP IS OPEN. I CAN'T SAY SO.",
}
## Later runs.
const FRAY_RECALL := {
	"wren": "You took my ribbon last time. I'm not mad. I'm a bit mad.",
	"mira": "You wore me out of the room. Did the square look nice, at least?",
	"tobben": "YOU AGAIN. I'D SAY HELLO.",
}
## Given back from the Recycle Bin.
const FRAY_RETURNED := {
	"wren": "My ribbon! You went into the bin for it? ...You smell like the bin.",
	"mira": "Oh. There I am.",
	"tobben": "—oh. Oh! There it is. I'd forgotten how loud I am. Sorry.",
}
## Tobben, frayed, speaks only in writing.
const TOBBEN_WRITTEN := "TOBBEN · WRITTEN"

## The owner.
const OWNER_NEW_FACE := "new face. same walk."
const OWNER_SECOND_SHED := "you can change your clothes all night. i know how you move."
const OWNER_HUSK := "you left something in my room."
const OWNER_HUSK_ELSEWHERE := "you left something in my save."
const NOTE_BODY := "YOU LEFT A BODY HERE.\nI KEPT IT."
const OWNER_FRAYED := {
	"wren": "wren's ribbon is gone. did you do that.",
	"mira": "mira's gone grey. she was the only colour in that room.",
	"tobben": "tobben stopped talking. even the shop music sounds wrong.",
}
const OWNER_ALL_FRAYED := "you're not hiding from me. you're eating them."

## The Archivist.
const ARCHIVIST_SHED_FIRST := [
	"You found out you can do that. So did I, once. I chose not to.",
	"That's how you came back the first time, you know. You just didn't notice whose pieces they were.",
]
const ARCHIVIST_PIECE_BACK := "Good. Some things should go back where they were."
const ARCHIVIST_NOTHING_TO_TAKE := "Go on. Look closely. I was cut before anyone finished drawing me. There's nothing on me to take."


## The records screen: every ending, with a hint while it's still unseen.
## id -> [name, what happened, hint].
const ENDINGS_RECORD := [
	["escape", "SAVED TO SLOT 2", "You wrote yourself into the last save file.", "Reach Slot 2 and take it."],
	["rue", "RUE", "You took the slot knowing what you are. Your name, at last.", "Take Slot 2 with every memory, knowing what you are."],
	["wren", "A NEW GAME FOR WREN", "You gave the last save to someone who asked for it.", "Bring someone who wants to see the Edge."],
	["message", "A MESSAGE", "You left the slot to the owner, with something to read.", "Leave the slot to the owner."],
	["unseen", "NEVER LOADED", "You walked off the map and the owner never knew.", "Be impossible to notice."],
	["overwrite", "SLOT 1 OVERWRITTEN", "You took the owner's save instead of the empty one.", "Be impossible to ignore."],
]

## Things you can find or do, beyond the endings. [name, hint].
static func secrets() -> Array:
	return [
		["Pip", "Something small lives out of bounds.", OwnerMemory.found_pip],
		["The Archivist", "Someone keeps the cut content.", OwnerMemory.met_archivist],
		["Wren saw the Edge", "She wants to see it before she's gone.", OwnerMemory.wren_saved],
		["Undeleted", "Bring back someone the owner deleted.", not OwnerMemory.restored.is_empty()],
		["The guest book", "Tobben lost a page. Look where deleted things go.", OwnerMemory.found_guestbook],
		["Mira saw the square", "Someone has never left her room.", OwnerMemory.mira_quest == "pinned"],
		["The second controller", "Arin's front door is only locked. Look under the couch.", OwnerMemory.found_controller],
	]


## The death card's line, specific to how, where and how often.
static func death_body(reason: String, area: String, times: int, escorting: bool) -> String:
	match reason:
		"arin":
			if escorting:
				return "arin walked through you. wren saw it happen."
			if times >= 2:
				return "arin didn't even slow down this time."
			return "arin walked through you. there was only room for one of you."
		"save":
			if times >= 2:
				return "saved over again. the backup of you gets smaller every time."
			return "the owner saved over you. somewhere in slot 1 there's a version of this room without you in it."
		"cursor":
			if area == "edge":
				return "so close to slot 2 the cursor could read your name. it didn't bother."
			if times >= 3:
				return "one click. it's always one click."
			return "the owner clicked on you. it took one second."
		"eraser":
			if area == "edge":
				if times >= 2:
					return "the static remembers the way you run now. so do you."
				return "the edge unloaded with you still in it. out here, nothing is saved."
			return "the static caught up with you. it was never in a hurry."
		"bin":
			return "emptied with the trash. for a moment you were with everyone else the owner threw away."
	return "the owner learned something."


## Said once you're one glitch away from the owner reloading (OwnerMoves).
const RELOAD_WARNING := "do that again and i'm loading the autosave."


## The purge ending (OwnerMemory.MAX_PURGE): the owner has learned enough,
## and the intruder can't load into Slot 1 any more.
## The demo build's last card (COMMERCIAL_DIRECTION.md §4: proposed, not
## approved). Spoiler-safe: it comes before the reveal.
const DEMO_END := "still have my save?"

const PURGED_TITLE := "PURGED"
const PURGED_QUESTION := "Slot 1 is clean. There's nothing of you left to load."
const PURGED_CHOICES := ["Restore the intruder  (a new game: the owner forgets everything)", "Back to the title"]
const PURGED_CONFIRM := "Restore the intruder? Every ending, memory and secret in the Records is forgotten too."
const PURGED_CONFIRM_CHOICES := ["Yes, forget everything", "No"]
## On the death card when one more death or quit would end it.
const PURGE_WARNING := "one more death or quit, and the owner won't let you back in. ever."


static func purged_body() -> String:
	var counted: Array[String] = []
	if OwnerMemory.deaths > 0:
		counted.append("you died %s" % _times(OwnerMemory.deaths))
	if OwnerMemory.quits > 0:
		counted.append("you left %s" % _times(OwnerMemory.quits))
	var lines := ["the owner learned how you move, where you hide and who helps you."]
	if not counted.is_empty():
		lines.append("%s. that was enough." % " and ".join(counted))
	if OwnerMemory.deaths > 0:
		lines.append("(the marks on the floor are where you fell. they couldn't delete those.)")
	return "\n".join(lines)


static func _times(n: int) -> String:
	return {1: "once", 2: "twice"}.get(n, "%d times" % n)


## The first glitch's lesson (after it, once).
const PRICE_TIP := ["THE PRICE", "That jump on the bar was the owner feeling it. Glitches are how you get out, and how they find you. Spend them like they cost something. They do."]

## The owner, as you keep glitching (by glitches this session).
const GLITCH_ESCALATION := {
	3: "stop doing that.",
	6: "i can see the seams now. you're making seams.",
	10: "every time you do that the save gets heavier.",
	15: "fine. break it. it was never yours.",
}

## The Records screen, annotated by the owner (by state).
static func records_margin(section: String) -> String:
	match section:
		"endings":
			var n := OwnerMemory.endings_seen.size()
			if n == 0:
				return "you won't see any of these."
			if n >= ENDINGS_RECORD.size():
				return "you've seen every one. why are you still here."
			return "%d. that's %d too many." % [n, n]
		"memories":
			var m := OwnerMemory.fragments.size()
			if m == 0:
				return "there's nothing of you left to find."
			if m >= FRAGMENTS.size():
				return "i know whose they are."
			return "stop picking those up."
		"secrets":
			if OwnerMemory.found_guestbook:
				return "that page was torn out for a reason."
			if not OwnerMemory.restored.is_empty():
				return "i deleted them. you don't get to decide that."
			return "there's nothing hidden in my save."
		"counted":
			if OwnerMemory.deaths >= 10:
				return "i stopped counting. no i didn't."
			if OwnerMemory.deaths > 0:
				return "i count them too."
			return "not yet."
	return ""


## The owner's line at the bottom of the Records, typed as you read.
static func records_watcher() -> String:
	if OwnerMemory.sessions <= 1:
		return "> who keeps these?"
	if OwnerMemory.last_ending == "message":
		return "> i read this too. i read everything you leave."
	if OwnerMemory.purge >= 4:
		return "> almost done. then i'll delete this page too."
	return "> i read this too, you know."


## How you died, and what to try next time. reason -> [title, body, tip,
## glitch, glitch tip]: the glitch tip replaces the plain one once that
## glitch is yours. {interact} becomes the button glyph.
const DEATHS := {
	"arin": ["OVERWRITTEN", "arin walked through you. there was only room for one of you.",
		"Arin only sees inside the light cone. Stay behind, or hide beside Wren.",
		"freeze", "Hold {interact} near Arin to freeze them for 2 seconds, then slip past."],
	"save": ["OVERWRITTEN", "the owner saved over you.",
		"When the save ring appears, keep moving or hide: it fills slowly while you walk, and not at all while you're hidden.",
		"phase", "A glitch breaks a save: face a wall or get near someone, then hold {interact} as the ring appears."],
	"cursor": ["SELECTED · DELETED", "the owner clicked on you.",
		"The cursor selects whatever holds still under it. Keep moving, or hide: it can't click what it can't find.",
		"blind", "Hold {interact} on the cursor to blind it for a few seconds."],
	"bin": ["EMPTIED", "the owner emptied the recycle bin. you were in it.",
		"When the bin empties, stand in a system file's cyan shadow, on the side away from the line.",
		"pause", "Hold {interact} standing still to PAUSE the owner: the bin can't empty while time stops."],
	"eraser": ["ERASED", "the static caught up with you.",
		"The erasure spreads from where it starts. Stay ahead of it and head for the exit.",
		"scrub", "Hold {interact} on erased ground to scrub a path through it."],
}


static func fragment(id: String) -> Dictionary:
	for f in FRAGMENTS:
		if f.id == id:
			return f
	return {}


## The frame a memory plays in ("" for none), the planted one included.
static func replay_frame(id: String) -> String:
	if id == FALSE_FRAGMENT.id:
		return FALSE_FRAGMENT.replay
	return fragment(id).get("replay", "")


static func fragments_in(area: String) -> Array:
	return FRAGMENTS.filter(func(f: Dictionary) -> bool: return f.area == area)


static func win_text(found: int) -> String:
	if found >= FRAGMENTS.size() and OwnerMemory.knows_truth:
		return "slot 2 was hers once. now it's yours.\nyou remember your name now. RUE.\nsomewhere outside the screen, the owner is staring at a save they deleted years ago."
	if found >= FRAGMENTS.size():
		return "you wrote yourself into the last save file.\nyou know your name now. RUE.\nyou don't know yet what you are."
	if found >= 3:
		return "you wrote yourself into the last save file.\nyou almost remember whose it was.\n(memories recovered: %d of %d)" % [found, FRAGMENTS.size()]
	return "you wrote yourself into the last save file.\nthe owner doesn't know this slot survived. not yet.\n(memories recovered: %d of %d)" % [found, FRAGMENTS.size()]
