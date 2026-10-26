# Brief: tear down the opening and rebuild it as a real first act

You are the game director, lead engineer, narrative designer and art
director of **The Last Save File** (Godot 4.3, GDScript, Compatibility
renderer, 640×360 logical viewport with `canvas_items` stretch). Work on
branch `claude/last-save-file-prototype-ljwuq4`. PR #10 stays a draft.

The author's verdict on the current beginning (the "festival" prologue,
`scripts/ui/prologue.gd`): **it is way too basic and needs a complete
change.** Don't polish it. Rethink it, build the new one, and prove it
works.

Deliver working, tested, captured changes, not plans. Where the brief
asks for thinking (§2), write it down first; then build.

---

## 0. Read first, then look

1. Read:
   - `docs/INTRO_REBUILD.md`: the last pass, its ledger, and the Q1–Q5 author questions;
   - `docs/ART_BIBLE.md`;
   - `docs/STORY_CHRONOLOGY.md`;
   - `docs/CANON_DECISIONS.md`;
   - `docs/RELEASE_READINESS.md` (the current section);
   - `scripts/ui/prologue.gd`, `scripts/story/quests.gd`, `scripts/world/hero_figure.gd`.
2. Play the current opening three ways, from a fresh profile, under
   xvfb, and capture each:
   - prompt (autoplay);
   - hesitant;
   - skip.
3. Look at `docs/review/intro/after_*.jpg` and write down, in your own
   words, why a player would put this down in the first minute.

Start from this diagnosis. Verify each point, and add what it misses:

### Why the current opening is "too basic"

**Design**
- It is a tutorial checklist wearing a festival costume: "light the five
  lanterns", five pips, then four lanterns, each one mechanic (plate,
  hide, hold E, time a beam).
- Nothing is at stake, nothing surprises, and nobody says anything to
  anybody.

**Story**
- The bond between the two players is announced, not lived:
  - P1 is a scripted bot that walks to points;
  - the kids never speak;
  - there is no shared joke, no ritual and no history.
- "PLAYER 1 HAS LEFT THE SESSION" is a toast on a HUD, so the loss lands
  as UI, not as an event.
- The real world (the couch, the move, the argument, the message) is
  almost invisible. The game's whole premise lives *outside* the screen,
  and the opening never shows it.
- The three years are a text overlay on a time-lapse. The owner's reveal
  is one red line.

**Look**
- A flat green field, placeholder props (blocks, black rectangles),
  debug-style labels ("P2 · RUE (you)", "ARIN ▸ OWNER", "???").
- No layered lighting or depth, no crowd, no festival life.
- Camera framing that cuts tags off.

**Feel**
- No music cue structure, no sound design per beat, no animation
  anticipation or impact, no screen-level drama (framing, pacing,
  silence).

### What is good: keep it, don't rebuild it
- **Tests and safety:**
  - the test culture: 130 test files, about 680 tests, regression tests
    that fail first, a strict runner that fails on script errors;
  - save safety: atomic and versioned files, migration, old saves load.
- **Players' settings:**
  - accessibility: reduced motion and flashing, large text, subtitles,
    touch, remappable keys, shape-plus-colour P1/P2;
  - input ownership: focus and controller holds, the active pad.
- **Story systems:**
  - caption and voice continuity;
  - line milestones (facts learned when a line is revealed);
  - the protection policy.
- **Quests:** missions derived from the save, so there is nothing new to migrate.
- **Art pipeline:** `CharacterArt.figure` with sheet → HeroFigure →
  IllustratedCharacter fallback.
- **Verification:** CI exports to Linux, Windows and Web, a headless
  Chromium web check, a benchmark harness, and PlaytestLog instrumentation.
- **Canon:** decided, with a chronology.

### What the codebase does badly (fix what the new opening touches)
- **Everything is drawn in code.** 48 files have `_draw`, with about 890
  `draw_*` calls. There are only 3 `.tscn` scenes, and the only assets
  are fonts. Nothing can be authored, laid out or replaced by an artist,
  and every composition is hard-coded coordinates (`prologue.gd` alone
  has a dozen position constants and draws its whole town by hand).
- **God classes:**
  - `world.gd`: about 2,030 lines, 103 functions;
  - `hud.gd`: about 1,750 lines;
  - `prologue.gd`: about 1,390 lines, mixing state machine, input, AI,
    camera, HUD, drawing and audio.
- **36 `static var`s of global state**, reset by hand in tests.
- **Story text lives in GDScript constants** (`story.gd`,
  `relationships.gd`, area scripts). There are no data files, so
  localisation and writer edits mean code changes.
- **`prologue.gd` duplicates `opening.gd`'s** hold, skip and pad logic.
- **The suite takes about 25 minutes**: most tests wait on the wall
  clock, and a few are timing-sensitive under load. The ending bots fail
  differently from run to run (purge 3 and purge 5), on the baseline too.
- **`docs/` is 51 MB** of images and clips in git. Evidence should be
  smaller or kept as CI artifacts.

---

## 1. Canon: do not reopen (propose changes in the ledger, don't build them)

- **The two children:**
  - two children shared one console;
  - P1, the owner, played Arin in slot 1;
  - P2, a girl, made Rue in slot 2 and played her for 41 hours.
- **The break:**
  - she moved away;
  - months later she messaged "still have my save?";
  - the owner never answered, and deleted slot 2.
- **The present:**
  - three years later;
  - Rue is the character left running; she is not the girl;
  - Rue is she/her;
  - Arin is distinct from the owner, and mute.
- **Keep as they are:**
  - the five memories, the CHARACTER FILE and its truth requirements, an
    ordinary escape without the truth;
  - all six endings, fraying and restoration;
  - Pip, never shed;
  - "the owner doesn't know this slot survived. not yet.";
  - the well's recordings, kept distinct from live contact;
  - the cast.
- **Keep the decisions from the last pass** unless §2's chosen concept
  needs one changed. If it does, record that as an author question, with
  the reason.

---

## 2. Think first: three concepts, one choice (write it in `docs/OPENING_V3.md`)

Design **three genuinely different openings**. For each, write:
- a one-paragraph pitch;
- the first 10 seconds, shot by shot;
- the beat list to the moment the player controls Rue in Arin's room;
- the emotional curve;
- the verbs taught;
- what the player knows, and wants, at each beat;
- a risk list.

Then score all three against the rubric in §5, and pick one with reasons.

Use these three directions as the starting set. Replace any of them with
something better if you find it:

### A. The screen within the room (recommended to explore first)
- **The frame:** the opening is framed as the real living room at
  night. The game is a TV in that room. The camera starts on the room:
  - a couch, two controllers (one with tape on its cable);
  - moving boxes;
  - a phone on the armrest;
  - the TV's glow.
  The two children are only hands, legs, voices (captions) and
  silhouettes. They never show faces; respect the canon.
- **The game on the TV:** Rue and Arin's last session is a *real*
  set-piece mission with stakes. For example, escape the collapsing
  festival tower before the save point closes. The game shows its own
  co-op mechanics: revive, carry, combo jump, shared light.
- **The world around the screen tells the story:** the kids' banter
  appears as captions from the room ("you be arin, i'll make my own"
  belongs to memory 1; here it's their running jokes). A phone buzzes.
  "Boxes in the hall."
- **The break:**
  - mid-mission, the argument starts in the room ("it's my console
    anyway"); P1's controller is put down on screen, and Arin freezes
    mid-jump;
  - the player, as P2, must finish the set piece alone. Rue does
    something she shouldn't be able to, a beat that plants the truth
    without saying it;
  - then the girl's controller is set down too, and Rue keeps moving.
- **The years:** the camera pulls back through the TV into the room as
  it empties across three years:
  - furniture leaves, dust settles, the phone lights with "still have
    my save?";
  - the typing indicator stops;
  - the TV is the last thing in frame.
- **The return:** years later the TV turns on. A new, older hand, the
  owner's, picks up one controller. The game loads. On screen: "> ...who's
  in my save?". Then push in through the screen into Arin's room.

### B. Start in the present, flash back as play
Open cold in the present:
- the corrupted room;
- the owner's cursor hunting;
- Rue in missing-texture, hiding: a 60-second stealth hook.

Each memory found later is a *playable* co-op flashback, not text. The
first one comes within 3 minutes and is the last session. The bond is
built across the first hour rather than front-loaded.

### C. The save menu as the stage
The whole opening happens in the game's own UI layer:
- the save-select screen, years of timestamps, slot 2's thumbnail;
- the girl's last message as a save note;
- the owner's cursor hovering DELETE.

The player, as Rue, physically runs *inside* the menu (between slot
cards, under the cursor) before falling into slot 1. It is meta, fast
and very readable.

**Rule:** whichever you pick, the player has control within 10 s, and
the player's first minute contains something they have never seen
before.

---

## 3. Build the chosen opening as a vertical slice

### 3.1 Story and writing
- **Characterise the two players through behaviour and words.** Give
  them:
  - a shared ritual (the girl's two-tap habit already exists; use it);
  - a running joke;
  - one disagreement before the real one;
  - one kindness.
- **Captions carry voices:**
  - girl;
  - owner-as-child;
  - Rue (only after the break, and never as the girl);
  - the system.
  Each is distinct in typeface and colour **and** shape (a speaker
  glyph). None depends on sound.
- **Plant, don't tell.** One beat must make an attentive player suspect
  that Rue moves on her own, and pay that off at the CHARACTER FILE.
- **The owner's first line in the present must be earned**: we have
  seen the child he was.
- **Every line goes through the existing systems:** voice manifest rows,
  `ArchivePages` facts at reveal, and chronology rows. Text lives in
  data (see §3.4), not constants.

### 3.2 Play
- **One real set piece**, not a checklist. Two to four co-op mechanics,
  each used for something that matters in the fiction. They escalate,
  and they are combined at the climax.
- **The scripted P1 must feel like a person:**
  - imperfect timing;
  - waiting for you;
  - showing off;
  - a mistake you help with;
  - reacting to what you do.
- **Failure is soft and fast:** no death screens in the prologue, but
  real tension (timers, collapse, the light going out).
- **The first decision matters and is remembered:** at least two NPCs
  and one ending line differ by it. Keep `OwnerMemory.festival_choice`,
  or replace it with a migration.
- **Skippable after the first minute**, always skippable on a replay, a
  static version under reduced motion, and fully playable by touch, pad
  and keyboard.

### 3.3 Look and feel: the bar is a modern indie release, not a prototype
- **Author it as scenes.** The opening is built from `.tscn` scenes
  with real nodes:
  - `TileMapLayer` or authored sprites for ground and buildings;
  - `PointLight2D`, `LightOccluder2D` and `CanvasModulate` for time of
    day;
  - `GPUParticles2D` with a CPU fallback for Compatibility;
  - `AnimationPlayer` for the set piece and camera;
  - `Camera2D` with authored framing.
  Hard-coded `_draw` composition is only for what has to be procedural
  (glitches, the owner's UI).
- **Assets:** you may create original art in-repo (SVG, or PNG made by a
  committed script or by hand in code). You may **not**:
  - buy, download unlicensed, or generate AI art for final use;
  - use credits or services.
  If an asset is a placeholder, say so in `ART_BIBLE.md` and the asset
  list, and make the pipeline accept the real one without code changes.
  If procedural art can't reach the bar for a shot, say so plainly, and
  write the commission brief for that shot.
- **Composition per beat:** a shot list (framing, focal point, light,
  palette). There must be no labels over characters except where the
  fiction is a game UI, and those must look like that game's UI, not
  debug text.
- **Animation:** anticipation and follow-through on every big action,
  hit-stop or screen pulse on success, idle life in the background
  (crowd, flags, lights).
- **Sound:** a cue sheet per beat, using the existing synth and music
  box (no new paid assets). Every sound has a visual equivalent.
- **The room layer (if concept A):** the real world must read instantly
  as real, in a different visual language from the game inside the TV
  (lighting, scale, grain). The TV image must be the actual running
  game, rendered through a `SubViewport`, not a fake.

### 3.4 Architecture: leave the code better than you found it
- **Split the opening into small units:**
  - a state machine / sequencer driven by data (a `Resource` timeline,
    or a JSON beat file);
  - set-piece logic;
  - the scripted P1 controller;
  - the camera director;
  - the opening HUD;
  - presentation (scenes).
  The old `prologue.gd` and `opening.gd` are retired or reduced to
  thin adapters. Keep old-save compatibility.
- **Input:** extract the shared hold/skip/pad/focus logic that
  `opening.gd` and `prologue.gd` duplicate into one component, and use
  it in both places (with tests).
- **Text:** move the opening's text (and, if time allows, the first
  hour's) into data files the game loads, with the manifest generated
  from them. The format must work for localisation.
- **Global state:** don't add new `static var`s. Where the opening
  touches existing ones, wrap them in an explicit reset used by tests.
- **Tests:** new tests drive the sequencer in stepped game time, not
  wall-clock waits. Each new test must run in under 2 s.

---

## 4. Constraints (non-negotiable)

- **Platforms:** Godot 4.3 Compatibility, GDScript, with Web, Linux and
  Windows exports working. CI's web check updated, and green.
- **Git:**
  - never merge PR #10, never force-push, push only to the branch above;
  - commit messages end with the session's attribution lines (see the
    system reminder);
  - no model IDs anywhere in repository artifacts.
- **Saves:** older saves load, and profiles that already started skip
  the new opening. The title offers it for replay.
- **Tests:**
  - don't delete or weaken tests; update the ones whose premise you
    deliberately change, and say why in the commit;
  - every bug gets a regression test that fails first;
  - every new mechanic gets tests: sequencer, set piece, scripted P1,
    the leaves, skip and replay, save migration, accessibility.
- **Keep, don't re-implement:**
  - input ownership;
  - caption/voice continuity;
  - the protection policy;
  - the floor warning;
  - the Bin shelter;
  - independent RNG;
  - line milestones;
  - in-view observation;
  - Tobben's single report;
  - Quests.
- **Accessibility:**
  - maximum text and subtitle size;
  - reduced flashing and motion, each with a static alternative;
  - muted audio: every beat reads without sound;
  - touch, pad, and remappable keys;
  - a colour-blind-safe distinction using shape as well as colour.
- **Performance:** frame time at most 10% worse than the current head on
  the existing benchmark. Add a workload for the opening itself.
- **Honesty:**
  - don't publish, purchase, spend credits or clone voices;
  - don't claim playtests or listening tests that didn't happen; if no
    unfamiliar players are available, ship the protocol and
    instrumentation and say so;
  - no invented metrics, quotes or forecasts.
- **Investigate warnings**, don't suppress them.

---

## 5. Rubric (score the three concepts with it, then the built slice)

Score each 1–5, with evidence (a capture, a timing, a test):

1. **Hook:** is something new and surprising on screen within 10 s, and
   is there a question the player wants answered within 60 s?
2. **Bond:** is the friendship shown through play and behaviour, not
   labels? Would a player miss P1 when he leaves?
3. **The break lands:** do the two leaves feel like events in the real
   world, not UI notifications?
4. **Clarity:** at every beat, can a first-time player say who they are,
   who the other one is, and what to do, with sound muted?
5. **Craft:** does the composition, light, animation and sound read as
   a modern indie release? Compare against two or three named reference
   games you choose, and say what you take from each, without copying
   any assets.
6. **Pacing:**
   - control ≤ 10 s;
   - the set piece's climax ≤ 3 min on the prompt path;
   - the owner's line ≤ 4 min;
   - a skip reaches the present in ≤ 15 s.
7. **Systems:** does it teach at least two verbs the first hour uses?
   Does the decision echo later?
8. **Code health:**
   - is `prologue.gd` gone or thin;
   - is the logic data-driven;
   - is the input logic unduplicated;
   - are the tests fast?

The built slice must score at least 4 on 1–4 and 6. A score under 4
anywhere else is reported, with what would raise it.

---

## 6. Commit groups (in order)

1. **Thinking:** `docs/OPENING_V3.md` with the three concepts, rubric
   scores, the choice, the shot list, the cue sheet and an updated
   ledger. Before captures.
2. **Foundations:**
   - the shared input/skip component;
   - the data-driven sequencer and text files;
   - their tests;
   - no behaviour change yet: the current opening runs on them.
3. **The new opening**: scenes, set piece, scripted P1, the leaves, the
   years, the return. Tests and save migration.
4. **Art, light and sound pass** for the opening, the asset list, and
   ART_BIBLE updates.
5. **Payoffs:** NPC lines, the CHARACTER FILE plant, the ending line,
   the chronology, the voice manifest.
6. **Verification and report:**
   - the full suite, the bots A/B against the current head, the three
     exports, the web check, the benchmark;
   - before/after captures (stills every 2 s, a 30 fps clip of the first
     3 minutes, prompt/hesitant/skip, max text, reduced motion, touch);
   - the rubric scores for the built slice;
   - the RELEASE_READINESS current section;
   - the PR #10 description;
   - a final report: what changed, what was measured, the risks, the
     asset status, and the author decisions with recommendations.
