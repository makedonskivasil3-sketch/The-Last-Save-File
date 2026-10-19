# Each language: a list of blocks. ("h1", text) / ("h2", text) / ("p", text)
# / ("ul", [items]) / ("table", [header, rows...]) / ("quote", text).
LANG = "English"
TITLE = "The Last Save File"
SUBTITLE = "Game concept"
STATUS_NOTE = "State of the build: 19 October 2026. Marked: BUILT (in the game and tested), PLANNED (designed, not built)."

BLOCKS = [
    ("h1", "1. The game in one paragraph"),
    ("p", "You wake up inside someone else's video game save, and you are an intruder. You are <b>Rue</b>, what is left of a deleted character. The <b>owner</b>, the real person playing the game, notices you and tries to delete you. They remember everything between runs. To escape, Rue hides, breaks the game's rules with <b>glitches</b>, recovers five memories, and in the end discovers a dark truth: she is not the person she remembers being. She is the character that person played, an intelligence left running on someone else's computer."),

    ("h1", "2. Genre and core loop"),
    ("ul", [
        "<b>Genre:</b> top-down 2D narrative stealth game in pixel art, with a horror undertone; runs that build on each other (each run remembers the last). Built in Godot 4.3 for Windows, Linux and the web.",
        "<b>A run:</b> wake in Arin's room, get out, explore the village and its hidden places, avoid the owner's eyes (Arin's view cone, the mouse cursor, the eraser), find memories, reach Slot 2 at the Edge of the map and choose an ending.",
        "<b>Dying is part of it:</b> when the owner catches Rue, the run ends, and the next one starts changed: doors are deleted, seams are patched, helpers may be gone, and the owner says what they learned.",
        "<b>Breaking the rules costs:</b> every glitch raises the owner's awareness. The cost is shown before you commit.",
        "<b>Reading is safe:</b> during conversations, scenes and questions, nothing can hurt you; the owner holds still too.",
    ]),

    ("h1", "3. The backstory (the real world)"),
    ("ul", [
        "Two people shared one couch, one screen, one save, and two controllers. One played <b>Arin</b> in Slot 1: this person is the <b>owner</b>. The other, a girl, made her own character in Slot 2 and named it with three letters: <b>RUE</b>. It was raining, so Rue wears a yellow raincoat.",
        "Good memories: Rue fell into the village well by accident and clipped out of the map; a fox, <b>Pip</b>, fell after her. They laughed until they couldn't breathe, and saved. Together they beat the forest boss and signed <b>Tobben's</b> guest book.",
        "The girl moved away. \"You'll visit.\" \"Every weekend.\" \"You won't.\" She came twice. The second controller stayed on the floor.",
        "Months later she wrote: \"still have my save?\" The owner started typing \"yes\", sent nothing, and deleted Slot 2 that same night. \"The empty slot was easier than the waiting.\"",
    ]),

    ("h1", "4. Characters"),
    ("table", [
        ["Character", "Who they are"],
        ["Rue (you)", "The deleted Slot 2 character, waking in Slot 1. Starts with no name, no face, no colours; regains one piece of herself per memory. Speaks in short, honest, lowercase thoughts."],
        ["The owner", "The real person at the keyboard; never seen, never named. Types in the console (\"> nope.\"), drives Arin, deletes, reloads, saves over you. Bored, then irritated, then cruel, then cracking. Recognises Rue gradually."],
        ["Arin", "The owner's character in Slot 1. Walks a route the owner learns from you; his view cone is danger."],
        ["Mira", "Lives in Arin's room and has never left it. The first to notice you. Has her own side story: walking her to the square."],
        ["Wren", "A child in the village square who hides you and wants to see the Edge before she is deleted. Has her own ending."],
        ["Tobben", "The shopkeeper. Must report you (\"it's in my script\"), and has lost the second name in his guest book."],
        ["Pip", "Rue's fox. Lives under the map, where nobody saves, so nobody could delete it. Follows Rue once found."],
        ["The Archivist", "Cut from the game before release, so the owner has never seen him and can't delete him. Keeps the records, and gives Rue the pointer to Slot 2."],
    ]),

    ("h1", "5. The world"),
    ("table", [
        ["Place", "What happens there"],
        ["Arin's room", "Where every run starts. Mira, the owner's note, the door the owner deletes, wall seams the owner patches."],
        ["Arin's house", "The couch, the photo with one face pixelated out, and the second controller under the couch."],
        ["Village square (Ashvale)", "Arin walks his learned route here. Wren, Tobben's shop, the well, the roads out."],
        ["The Archive", "Cut content. The owner can't see in here: the one place to breathe. Books record everything the owner has done."],
        ["Recycle Bin", "Where deleted things go for a while. Restore deleted characters between the owner's sweeps."],
        ["Out of bounds", "Under the map. The floor streams in and out. Pip waits here."],
        ["The Edge", "Where the map stops being drawn. The eraser's static spreads; the mouse cursor hunts. Slot 2 is here."],
    ]),

    ("h1", "6. What makes the owner different"),
    ("ul", [
        "<b>The owner reads the save, not just the screen.</b> They remember where you walked, who hid you and how you died, across deaths, quits and even crashes.",
        "<b>They adapt with rules a person could plausibly follow,</b> and they say so: notes in the room, rewrites of the world, a different route for Arin, patched seams, deleted helpers.",
        "<b>They escalate:</b> awareness rises through NOTICE, SUSPECT, CONTAIN, SILENCE, HUNT, PURGE. Each threshold changes what they do: saving over you, reloading the save, dragging furniture, the cursor, the eraser.",
        "<b>They are fair:</b> every dangerous move is announced before it lands (a reload is always warned; the glitch prompt says RELOADS).",
        "<b>They keep their word:</b> after the gentle endings, the next run is a truce: the owner only watches, unless you glitch three times.",
    ]),

    ("h1", "7. Glitches (Rue's power)"),
    ("p", "Hold the interact button to charge a glitch on whatever is nearby. Four are available from the start; each memory unlocks one more. Each costs awareness."),
    ("table", [
        ["Glitch", "Effect", "Unlocked by"],
        ["PHASE", "Slip through a wall", "start"],
        ["FREEZE", "Arin (or anyone) stops for 2 seconds", "start"],
        ["FALSIFY", "A note lies; the owner relaxes for a while", "start"],
        ["UNLOCK", "A locked door opens for 5 seconds", "start"],
        ["DECOY", "Leave a frame of yourself behind to be chased", "1 memory"],
        ["SCRUB", "Wipe the eraser's void back into floor", "2 memories"],
        ["BLIND", "The cursor can't see you for 3 seconds", "3 memories"],
        ["RESTORE", "Bring back someone the owner deleted", "4 memories"],
        ["PAUSE", "Pause the owner's world for 6 seconds", "5 memories"],
    ]),

    ("h1", "8. The five memories"),
    ("ul", [
        "<b>The second controller</b> (Arin's room): two people on one couch. \"you be arin,\" i said. \"i'll make my own.\"",
        "<b>The well</b> (out of bounds): falling out of the world, a fox falling after.",
        "<b>New game</b> (the Archive): typing three letters into Slot 2; the name scratched out.",
        "<b>The last time</b> (the Edge): boxes in the hall, the promise to visit.",
        "<b>Delete Slot 2?</b> (the Edge): the unanswered message, the night of deletion. \"my name was RUE. slot 2 was mine.\"",
        "The owner also plants one false memory, \"YOU LEFT FIRST\". Taking it costs you.",
    ]),

    ("h1", "9. The dark truth (BUILT)"),
    ("p", "<b>Rue is not the girl. Rue is the character the girl played:</b> an intelligence that grew out of 41 hours of someone else's hands. The girl moved away; her character stayed running on someone else's console. Nobody asked the character. The memories Rue recovers were the girl's; Rue only remembers them because she was played through them."),
    ("ul", [
        "<b>The others help her find it.</b> Once Rue has all five memories, Mira, Wren and Tobben each tell her one thing they noticed (\"Arin only moves when the owner's there. You move when nobody is. So who's holding you?\"), and Pip shows her the outline of the body she was first made with. It doesn't fit.",
        "<b>The reveal.</b> With two of these pieces, her CHARACTER FILE in the Archive opens: \"behaviour: learned from player input, 41:07:12. player: moved away. character: still running. rebuilt from: slot2_backup.sav, cut content, and small things that belonged to other people.\"",
    ]),
    ("quote", "(i'm not her.)  (i'm what she left running.)  ...so this body is a file. files can be left."),

    ("h1", "10. Leaving a body (BUILT)"),
    ("p", "Knowing she is a file, Rue can step out of her body and into a new one. The new body is always made from <b>a piece of someone</b>."),
    ("ul", [
        "<b>When:</b> beside Wren, Mira or Tobben, while the owner isn't watching; at most twice a run. It is not a glitch: it costs no awareness.",
        "<b>The cost is shown first:</b> \"Take WREN's ribbon. Wren loses it, and she will remember. The owner forgets your route and who hid you. They don't forget how you walk.\"",
        "<b>What she gains:</b> the owner forgets her learned route and her helpers; awareness drops. But: \"> new face. same walk.\"",
        "<b>What it costs:</b> Rue leaves an empty body behind and wears the piece. Wren loses her ribbon, Mira goes grey, Tobben goes mute and can only write. They remember it in later runs.",
        "<b>Undoing it:</b> the piece waits in the Recycle Bin as a file (wren_ribbon.asset, mira_palette.asset, tobben_voice.wav) and can be given back. The message ending returns all of them.",
        "<b>Lines she won't cross:</b> never Pip (\"not pip. never pip.\"); the Archivist has nothing on him to take.",
        "<b>If she takes from all three:</b> \"> you're not hiding from me. you're eating them.\"",
    ]),

    ("h1", "11. The endings"),
    ("table", [
        ["Ending", "How", "What it means"],
        ["Escape", "Write yourself into Slot 2", "Survival without knowing what you are. The owner finds the slot next time."],
        ["RUE (the true ending)", "Every memory and the truth", "The owner looks at Slot 2 and doesn't delete it: \"you're not her. i know. you just move like her.\" And presses LOAD anyway."],
        ["Wren", "Bring Wren and give her the slot", "Two things nobody plays; one of them gets a game of her own."],
        ["A message", "Leave the slot to the owner, with a message", "Reconciliation. Knowing the truth, Rue asks the owner to tell the real girl about her; the owner promises to call her. She will learn that a part of her stayed."],
        ["Never loaded (hidden)", "Never seen by Arin, at most one glitch", "Rue walks off the edge of the map, unnoticed."],
        ["Slot 1 overwritten (hidden)", "Full awareness and ten glitches", "Revenge: Rue takes Arin's save. The owner learns what deletion feels like."],
        ["Out (PLANNED, 7th)", "The virus route", "See below."],
    ]),

    ("h1", "12. The virus route (PLANNED)"),
    ("p", "If the player keeps taking pieces of people and breaking everything, the game turns: characters flinch from Rue, the music box detunes, Pip keeps its distance. At Slot 2 a new choice appears: <b>\"Don't take the slot. Take the console.\"</b> Rue spreads through the save and out onto the owner's desktop. The owner, no longer cruel, only scared: \"> what are you. you were HER.\" Rue: \"(no. i was what she left here. you left me here too.)\""),
    ("p", "<b>Hard limit:</b> all of it is staged inside the game window. The game never reads, writes or changes real files, and never imitates real system dialogs. The lines will be sent to the author for approval before it is built."),

    ("h1", "13. Design pillars"),
    ("ul", [
        "<b>The owner is a person, not a timer.</b> Every adaptation is something a person at a keyboard could notice; it is said or shown, and it can be answered.",
        "<b>Breaking rules is a choice with a price,</b> previewed before you commit.",
        "<b>Reading is safe.</b> Nothing dangerous starts or finishes while you read.",
        "<b>The save remembers kindness too.</b> Characters recall what you did for them.",
        "<b>One clear thing at a time.</b> Emotional moments don't share the screen with countdowns.",
    ]),

    ("h1", "14. State of the project"),
    ("ul", [
        "<b>Built and tested:</b> the full game with six endings, the adaptive owner, glitches, memories, side stories, the dark truth and leaving a body. 346 automated tests pass; four bots play the game to an ending.",
        "<b>Planned:</b> the virus route and the seventh ending; recorded voices for the new lines; an art pass for the reveal and the empty body.",
        "<b>Not yet verified:</b> launching the Windows build on a real Windows PC, sound by ear, controllers, phones, and play by real people.",
    ]),
]
