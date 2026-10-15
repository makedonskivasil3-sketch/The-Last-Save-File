class_name Story
extends RefCounted
## All of the game's narrative text in one place: the boot sequence, the
## intruder's inner voice, the five memory fragments, and ending variants.
##
## THE STORY (spoilers for the player, notes for the writer):
## Two people shared one console. One of them always played Arin in slot 1.
## The other made their own character in slot 2, a name they can no longer
## remember. They drifted apart; the second player stopped coming round.
## One night the owner needed the space and deleted slot 2.
## You are what's left of that deleted save, waking up inside the slot that
## survived. The owner thinks you're a bug. The fragments tell you otherwise.
## Find all five and you remember your name: RUE.
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
	"PLAYER 2 . . . . . . [deleted]",
	"VERIFYING . . . . . [!] 1 UNRECOGNISED ENTITY IN ARIN'S ROOM",
	"ENTITY NAME: none.   ENTITY SLOT: 02",
	"slot 02 does not exist.",
	"> ...who's in my save?",
]

## The title screen, the first time: the save is not quite right.
const TITLE_WHISPERS := ["Load Slot 1  (it isn't yours)", "Load Slot 1  (they'll see you)", "Load Slot 1  (again?)"]
const TITLE_FIRST_OWNER := "> is someone there?"

## The intruder's thoughts. Keys are story beats; arrays pick at random.
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
	"bin_restored": ["come back. it's not your turn to be gone."],
	"oob_fell": ["fell out of the world. again."],
	"hidden_first": ["she's warm. like a real person.", "stay still. stay small."],
	"idle_long": ["don't just stand here. it notices stillness."],
}

## What comes back with each recovered fragment (1..5): your own colours,
## restored onto your body one part at a time (see Player.RESTORE_ORDER).
const RESTORED := {
	1: "a scarf. red. i picked that colour myself.",
	2: "my hair. it always stuck up at the back like that.",
	3: "a yellow raincoat. it was raining the day we made me.",
	4: "real shoes. i can feel the floor now.",
	5: "that's my face. that's me.",
}

## The five memory fragments, in the order the story makes most sense.
## area / pos: where the shard floats. lines: the flashback.
const FRAGMENTS := [
	{
		"id": "controller",
		"title": "MEMORY · THE SECOND CONTROLLER",
		"area": "room", "pos": Vector2(505, 96),
		"lines": [
			"a second controller, the cable taped where the dog chewed it.",
			"two people on one couch. one screen. one save. crisps in the cushions.",
			"\"you be arin,\" they said. \"i'll make my own.\"",
			"[the rest of the evening is too bright to look at]",
		],
		"after": "i was here before. not in this room. in front of it.",
	},
	{
		"id": "well",
		"title": "MEMORY · THE WELL",
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
		"area": "edge", "pos": Vector2(92, 262),
		"lines": [
			"boxes in the hall. my half of the room already empty.",
			"\"you'll visit.\"  \"every weekend.\"  \"you won't.\"",
			"\"it's my console anyway.\"",
			"the second controller stayed on the floor where i dropped it.",
		],
		"after": "i moved away. i said i'd come back. i came back twice.",
	},
	{
		"id": "delete",
		"title": "MEMORY · DELETE SLOT 2?",
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
	"area": "square", "pos": Vector2(500, 250),
	"lines": [
		"you packed the second controller first. you didn't look at the screen.",
		"you never asked about the save. not once. not even when you left.",
		"you wanted to be forgotten. so i forgot you.",
		"[ this memory has no signature. it isn't yours. ]",
	],
	"after": "that wasn't mine. it felt like mine. it was so close.",
}

## The owner's notes: one a run (from the second), in order. Read together
## they tell the owner's side: why they pressed delete.
const OWNER_NOTES := [
	"there's something in arin's room again. i'm not imagining it.",
	"we used to play this on the couch at mum's. two controllers. i don't know why i'm writing that down.",
	"she moved in the summer. said she'd visit every weekend. she came twice.",
	"i kept her save for two years. i'd walk arin past the spot where her character used to stand.",
	"the night i deleted slot 2 i told myself it was for space. the card wasn't even half full.",
	"she sent a message once. 'still have my save?' i didn't answer. i'd already deleted it. i couldn't say so.",
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
	if OwnerMemory.guestbook_restored:
		lines.append("> someone wrote her name back in the guest book.")
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
	"It's the most beautiful thing I've ever seen.",
]
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
	"> i kept your controller. it's still under the couch.",
	"it presses LOAD.",
]
const EPILOGUE_PIP := "a small orange fox curls up at the bottom of the screen. nobody saved it. it came anyway."


## --- Slot 2: the choice and the three endings ----------------------------------

const SLOT2_QUESTION := "SLOT 2  ·  EMPTY.  Whose name goes here?"
const SLOT2_ESCAPE := "Write yourself in"
const SLOT2_ESCAPE_NAMED := "Write RUE"
const SLOT2_WREN := "Give Slot 2 to Wren"
const SLOT2_MESSAGE := "Leave the slot to the owner, with a message"
const MESSAGE_QUESTION := "What do you write?"
const MESSAGES := [
	"i'm sorry i stopped coming.",
	"you can keep the save. i just wanted to be remembered.",
	"please don't delete me again.",
]

## Ending ids: "escape" (take the slot), "wren" (give it to her),
## "message" (hand it back to the owner).
const ENDING_TITLES := {
	"escape": "SAVED TO SLOT 2",
	"wren": "SAVED TO SLOT 2  ·  WREN",
	"message": "SLOT 2  ·  A MESSAGE",
}


## The letterboxed epilogue for an ending (memories and Pip change details).
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
			lines.append("the owner finds a save they don't remember making. they leave it alone.")
		"message":
			lines = [
				"you write it into the empty slot, one letter at a time:",
				"\"%s\"" % MESSAGES[clampi(message, 0, MESSAGES.size() - 1)],
				"somewhere outside the screen, the owner reads it for a long time.",
			]
			if full:
				lines.append_array(["> ...rue?", "> i didn't know you were still in there."])
				lines.append(["> i stopped waiting. i shouldn't have.", "> i kept your controller. it's still under the couch.", "> i won't. i promise."][clampi(message, 0, 2)])
				lines.append("> i'm going to call you. the real you.")
			else:
				lines.append_array(["> who wrote this.", "> ...i'm not going to delete it."])
			lines.append("the eraser stops. the cursor goes still. for the first time, the save is quiet.")
		_:
			if full:
				lines = EPILOGUE_TRUE.duplicate()
			else:
				lines = ["you wrote yourself into the last save file.", "you load in somewhere the owner has never looked."]
	if pip:
		lines.append(EPILOGUE_PIP if ending != "wren" else "a small orange fox jumps into the new game after her. she'll need someone to hide behind.")
	return lines


## The end card's text.
static func ending_text(ending: String, found: int) -> String:
	match ending:
		"wren":
			return "you gave the last save file away.\nyou're still out here, in someone else's save.\nbut someone is safe because of you."
		"message":
			if found >= FRAGMENTS.size():
				return "you didn't take the slot. you gave it back, with your name on it.\nsomewhere, a phone is ringing."
			return "you didn't take the slot. you gave the owner a reason to stop.\n(memories recovered: %d of %d)" % [found, FRAGMENTS.size()]
	return win_text(found)


## What the owner says when you come back after an ending.
const ENDING_RETURN := {
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
}


## The first thing someone says to you this session, if they remember
## something about your last runs ("" if nothing). Checked in order: the
## first matching condition wins.
static func recall(who: String) -> String:
	var wren_lost: bool = OwnerMemory.npc_fates.get("wren", "") == "deleted"
	var ending: String = OwnerMemory.last_ending if OwnerMemory.previous_exit in ["win", "escape"] else ""
	var died_by: String = OwnerMemory.last_death if OwnerMemory.previous_exit == "death" else ""
	match who:
		"mira":
			if "mira" in OwnerMemory.restored:
				return "I was deleted. Then I wasn't. I remember the dark in between. Thank you."
			if wren_lost:
				return "They took Wren. She wanted to see the Edge so badly."
			if ending == "message":
				return "The owner sat with the game open for an hour last night. Didn't move Arin once. Just watched."
			if ending == "wren":
				return "There's a new name in the save menu. Wren's. Did you do that?"
			if ending == "escape":
				return "You got out. I watched the slot fill. So why are you back?"
			if died_by == "arin":
				return "Arin came back through the door alone last time. Humming."
		"tobben":
			if OwnerMemory.found_guestbook:
				return "...Rue. RUE. That was the other name in my guest book. How did I ever forget it?"
			if wren_lost:
				return "Wren used to come in every day and buy nothing. I miss her buying nothing."
			if OwnerMemory.wren_saved:
				return "Someone walked Wren to the Edge. That wasn't in anybody's script. Good for her."
			if ending == "message":
				return "The owner opened my shop menu yesterday. First time in years. Didn't buy anything. Still."
			if OwnerMemory.deaths >= 3:
				return "You again! I've started a tab for you. Out of guilt."
		"wren":
			if ending == "message":
				return "Did you write to them? Everything's quieter. Even the static."
			if ending == "escape":
				return "You got out, and you came back? For me? ...No. Probably not for me."
			if died_by == "eraser":
				return "I saw the static take you. It went right past me after. Like I wasn't worth erasing."
	return ""


## The records screen: every ending, with a hint while it's still unseen.
## id -> [name, what happened, hint].
const ENDINGS_RECORD := [
	["escape", "SAVED TO SLOT 2", "You wrote yourself into the last save file.", "Reach Slot 2 and take it."],
	["rue", "RUE", "You took the slot remembering everything. Your name, at last.", "Take Slot 2 with every memory."],
	["wren", "A NEW GAME FOR WREN", "You gave the last save to someone who asked for it.", "Bring someone to the Edge with you."],
	["message", "A MESSAGE", "You left the slot to the owner, with something to read.", "Leave the slot to the owner."],
]

## Things you can find or do, beyond the endings. [name, hint].
static func secrets() -> Array:
	return [
		["Pip", "Something small lives out of bounds.", OwnerMemory.found_pip],
		["The Archivist", "Someone keeps the cut content.", OwnerMemory.met_archivist],
		["Wren saw the Edge", "She wants to see it before she's gone.", OwnerMemory.wren_saved],
		["Undeleted", "Bring back someone the owner deleted.", not OwnerMemory.restored.is_empty()],
		["The guest book", "Tobben lost a page. Look where deleted things go.", OwnerMemory.found_guestbook],
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
		"When the save ring appears, keep moving: it fills slowly while you walk.",
		"phase", "Any glitch breaks a save. Hold {interact} the moment the ring appears."],
	"cursor": ["SELECTED · DELETED", "the owner clicked on you.",
		"The cursor selects whatever holds still under it. Keep moving, or break its line of sight.",
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


static func fragments_in(area: String) -> Array:
	return FRAGMENTS.filter(func(f: Dictionary) -> bool: return f.area == area)


static func win_text(found: int) -> String:
	if found >= FRAGMENTS.size():
		return "slot 2 was yours. it always was.\nyou remember your name now. RUE.\nsomewhere outside the screen, the owner is staring at a save they deleted years ago."
	if found >= 3:
		return "you wrote yourself into the last save file.\nyou almost remember whose it was.\n(memories recovered: %d of %d)" % [found, FRAGMENTS.size()]
	return "you wrote yourself into the last save file.\nthe owner doesn't know this slot exists. not yet.\n(memories recovered: %d of %d)" % [found, FRAGMENTS.size()]
