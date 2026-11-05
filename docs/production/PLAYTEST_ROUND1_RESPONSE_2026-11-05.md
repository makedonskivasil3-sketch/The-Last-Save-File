# Friends' playtest: what changed, and what comes next (2026-11-05)

**Source:** the author's report from a couple of friends. They found:
- "E not working or buggy at times";
- crashing ("the game closed itself");
- getting lost among the characters;
- too fast a start;
- a wish for better maps;
- a wish for a list at the side of what to look for;
- dialogues that start too suddenly;
- no moment of shock for Wren.

The build they played is unknown. It was most likely the browser link, which still served the 30 October build, without this week's fixes.

## Done in this change (automated tests; no human has checked it yet)

| Report | Cause found | Change |
|---|---|---|
| **E "not working or buggy"** | E acts on **release**. Holding it past 0.22 s started a glitch charge instead. FREEZE fires after a further 0.4 s, and it can target friendly people. So a slightly long press on Mira or Wren froze her and raised awareness. Letting go mid-charge played "denied" and did nothing. The festival had just taught players to hold E | <ul><li>A tap is now anything up to 0.35 s.</li><li>Glitching someone friendly, or a note, needs a deliberate 1 s hold.</li><li>Threats (Arin, the cursor) keep their quick holds.</li><li>Letting go before a glitch fires, with something in reach, now interacts. It never plays a silent "denied".</li></ul>`test_playtest_round1` |
| **"A list at the side"** | — | **An always-on checklist** under the awareness meter: the mission's title and its 2–3 steps. Each step is ticked from what the save says happened. It hides during conversations, scenes and cards, and fades when Rue or what she's looking at is underneath. An optional identity lead appears only once it is open |
| **Dialogues "too sudden, without knowing where we are"; characters met too fast** | First conversations began with the character's first line | **A first-meeting card** for Mira, Wren, Tobben and the Archivist, before the first word, ever. It shows their name, two lines of what Rue sees, and where she is. It is observation, not exposition, and the Owner is held while it is on screen |
| **A moment of shock for Wren** (the author chose "Wren sees what Rue is") | Her truth line was one calm sentence | **Wren sees it before she says it:**<br>• "...Wait. Stay there. Don't move." / the thin line going up from Arin to whoever holds him / "You don't have one. There's nothing above you at all.";<br>• then her original line, so the truth piece still counts;<br>• a sting sound and her "!";<br>• then Rue: *(she took a step back. she has never stepped back from me before.)* |
| **"Crashing" / "the game closed itself"** | **Not found in code.** The game has no path that quits on its own during play. Things that look like a close:<br>• the deliberate power-off sounds when the players leave in the festival;<br>• "Save and exit" and quitting, which return to the title;<br>• an ending card going to the title on a key press.<br>A real engine crash would leave a log | **Ask them for:**<br>• the Windows log `%APPDATA%\Godot\app_userdata\The Last Save File\logs\godot.log`;<br>• in the browser, Esc → Playtest log → Copy;<br>• what they were doing just before.<br>With that, it can be reproduced and fixed |

## Next, in order (not done yet)

1. **Deeper first-time stories for each character, and ways to build a relationship.** For Mira, Wren, Tobben and the Archivist, the plan per character is:
   - a small desire;
   - one favour Rue can do early (no new map);
   - a visible change after it;
   - a returning line that remembers it.

   The relationship and memory system already exists (`Relationships`, encounters). The work is writing and staging, about one character a day. **The author should approve each character's arc first.**
2. **Slower opening.** Let the room breathe before the first threat:
   - Mira's introduction first;
   - one quiet minute to look around;
   - the first awareness rise only after Rue's first deliberate action.

   This needs one playtest to measure before and after.
3. **"Better maps."** Needs the author to say which is meant:
   - the **in-game map screen**: clearer "you are here", the mission destination, named places;
   - or the **places themselves**: the art pass on the six areas not yet done.

   Both are planned; the order is the author's call.
4. **Commercial:**
   - a demo built on the workshop mission;
   - a Coming Soon page with screenshots from this build;
   - a new playtest round with the protocol in `COMPREHENSION_AND_FAIRNESS_2026-11-04.md` §6.

   Steam timing for December is still unconfirmed (checklist B13).

## For the next round with friends

- **Send the new link only after PR #14 merges** and the author has opened it once. The old link is the old build.
- **Ask after each session:**
  - Was E ever unresponsive, and where?
  - Did anything close, and what was on screen just before?
  - Who did you meet first, and what did you think they wanted?
