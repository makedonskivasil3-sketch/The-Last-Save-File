class_name StoryPacing
extends RefCounted
## One set of timing rules for every route that shows story text: the
## dialogue box, cinematics (memories, the boot, endings), the console and
## tutorial tips. See docs/STORY_PACING.md for the rules and the reasons.
##
## Reading allowance, in seconds, for a line that is FULLY visible (it never
## runs during the typewriter animation):
##
##   raw  = BASE + letters / CPS + SENTENCE × sentence ends + CLAUSE × clause marks
##   time = clamp(raw / READ_SPEEDS[auto_speed], MIN_TIME, MAX_TIME)
##
## MAX_TIME is only a sanity bound for runaway text: every line that fits on
## a page (PAGE_CHARS) gets its full allowance, at every reading speed.
##
## letters ignores spaces and the owner's ">" prompt; "..." counts as one
## sentence end. CPS 14 is ~170 words a minute, a comfortable pace for
## players reading in a second language or on a small screen.

const BASE := 0.8
const CPS := 14.0
const SENTENCE := 0.4
const CLAUSE := 0.15
const MIN_TIME := 1.6
const MAX_TIME := 30.0
## A line longer than this is shown in pages (pages()), split between
## sentences, so no box overflows and each page gets its own allowance.
const PAGE_CHARS := 180
## Settings.auto_speed: slow, normal, fast.
const READ_SPEEDS := [0.75, 1.0, 1.35]
const READ_SPEED_NAMES := ["Slow", "Normal", "Fast"]
## Settings.voice_delay: seconds after a voice line (and the allowance) ends.
const VOICE_DELAYS := [0.0, 0.5, 1.0, 2.0]
## Holding interact/confirm this long skips the rest of a cinematic.
const SKIP_HOLD := 1.2
## Console (ambient) lines come in two kinds (docs/STORY_TEXT_ROUTES.md):
## story (thoughts, people, the owner talking) keeps its full reading time;
## telemetry ("system": counters, file events) is capped at AMBIENT_MAX and
## moves at MIN_TIME each when BACKLOG more lines are already waiting.
const AMBIENT_MAX := 6.0
const BACKLOG := 3
## An owner line goes ahead of queued lines, and cuts the pause after a
## telemetry line to this; it never cuts a story line short. (Urgent owner
## warnings don't queue at all: Hud.warn shows them at once.)
const OWNER_GAP := 0.8


static func letters(text: String) -> int:
	var t := text.strip_edges().trim_prefix(">").replace(" ", "")
	return t.length()


static func sentence_ends(text: String) -> int:
	var t := text.strip_edges().replace("...", ".").replace("…", ".")
	var n := 0
	for i in t.length():
		if t[i] in [".", "!", "?"] and (i == t.length() - 1 or t[i + 1] in [" ", "\"", ")", "'", "\n"]):
			n += 1
	return n


static func clause_marks(text: String) -> int:
	var n := 0
	for c in text:
		if c in [",", ";", ":", "—", "–"]:
			n += 1
	return n


## Seconds to read `text` once it is all on screen. speed: an index into
## READ_SPEEDS, or -1 for the player's setting.
static func reading_time(text: String, speed := -1) -> float:
	var s: int = Settings.auto_speed if speed < 0 else speed
	var raw := BASE + letters(text) / CPS + SENTENCE * sentence_ends(text) + CLAUSE * clause_marks(text)
	return clampf(raw / READ_SPEEDS[clampi(s, 0, READ_SPEEDS.size() - 1)], MIN_TIME, MAX_TIME)


## How long a console line stays the newest before the next one starts.
## Story lines: their reading time. Telemetry: at most AMBIENT_MAX, and the
## minimum pace in a backlog. Everything is in the History either way.
static func ambient_time(text: String, waiting: int, kind := "system") -> float:
	if not is_telemetry(kind):
		return reading_time(text)
	if waiting >= BACKLOG:
		return MIN_TIME
	return minf(reading_time(text), AMBIENT_MAX)


## A console kind that reports state rather than telling the story.
static func is_telemetry(kind: String) -> bool:
	return kind == "system"


static func voice_delay() -> float:
	return VOICE_DELAYS[clampi(Settings.voice_delay, 0, VOICE_DELAYS.size() - 1)]


static func is_auto() -> bool:
	return Settings.advance_mode == 1


## `text` split into pages of at most PAGE_CHARS: between sentences where
## possible, else between words. Joining the pages with spaces gives the text
## back exactly. Short text is one page.
static func pages(text: String, page_chars := PAGE_CHARS) -> Array[String]:
	var out: Array[String] = []
	var rest := text
	while rest.length() > page_chars:
		var cut := -1
		for i in range(page_chars, 0, -1):
			if rest[i] == " " and rest[i - 1] in [".", "!", "?", "…"]:
				cut = i
				break
		if cut < page_chars / 3:
			cut = rest.rfind(" ", page_chars)
		if cut <= 0:
			break  # one unbroken word: show it whole rather than cut it
		out.append(rest.substr(0, cut))
		rest = rest.substr(cut + 1)
	out.append(rest)
	return out
