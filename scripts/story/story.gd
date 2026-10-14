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

const SECOND_PLAYER_NAME := "RUE"

## Shown once, the very first time the game is played.
const BOOT := [
	"SLOT 1  ·  ARIN  ·  LV 7  ·  14:22:00",
	"LOADING SAVE DATA . . . . . . . . OK",
	"VERIFYING . . . . . [!] 1 UNRECOGNISED ENTITY",
	"ENTITY OWNER: none.   ENTITY NAME: none.   ENTITY SLOT: 02",
	"slot 02 does not exist.",
]

## The intruder's thoughts. Keys are story beats; arrays pick at random.
const VOICE := {
	"wake_first": ["...where is this?", "this body isn't mine. it's barely a body."],
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
}

## The five memory fragments, in the order the story makes most sense.
## area / pos: where the shard floats. lines: the flashback.
const FRAGMENTS := [
	{
		"id": "controller",
		"title": "MEMORY · THE SECOND CONTROLLER",
		"area": "room", "pos": Vector2(505, 96),
		"lines": [
			"a second controller, plugged in next to the first.",
			"two people on one couch. one screen. one save.",
			"\"you be arin,\" they said. \"i'll make my own.\"",
		],
		"after": "i was here before. not in this room. in front of it.",
	},
	{
		"id": "well",
		"title": "MEMORY · THE WELL",
		"area": "square", "pos": Vector2(320, 202),
		"lines": [
			"my character walked into the well by accident.",
			"it clipped through the stone and fell out of the map.",
			"we laughed until we cried. we saved anyway.",
		],
		"after": "i fell out of the world once before. i got back in.",
	},
	{
		"id": "new_game",
		"title": "MEMORY · NEW GAME",
		"area": "archive", "pos": Vector2(470, 104),
		"lines": [
			"NEW GAME.  SLOT 02.  ENTER NAME: _",
			"i typed a name. i was so proud of it.",
			"it's the only thing i can't remember.",
		],
		"after": "slot 02. that's what the save said about me. 'entity slot: 02'.",
	},
	{
		"id": "argument",
		"title": "MEMORY · THE LAST TIME",
		"area": "edge", "pos": Vector2(92, 262),
		"lines": [
			"\"you never come round anymore.\"",
			"\"it's my console.\"",
			"the second controller stayed unplugged on the floor for weeks.",
		],
		"after": "i stopped coming. they stopped waiting.",
	},
	{
		"id": "delete",
		"title": "MEMORY · DELETE SLOT 2?",
		"area": "edge", "pos": Vector2(470, 262),
		"lines": [
			"DELETE SLOT 02?      > YES      NO",
			"they didn't ask me. they just needed the space.",
			"but nothing is ever really deleted.",
			"not while someone still remembers.",
		],
		"after": "my name was RUE. slot 2 was mine.",
	},
]

## The owner, once they start to suspect who you are (by fragments found).
const OWNER_RECOGNITION := {
	3: "...you move like someone i used to know.",
	5: "no. you can't be. i deleted you.",
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
