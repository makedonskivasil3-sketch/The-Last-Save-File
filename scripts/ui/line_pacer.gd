class_name LinePacer
extends RefCounted
## The life of one story line, shared by the dialogue box and cinematics
## (docs/STORY_PACING.md):
##
##   REVEALING  the typewriter is running. The first advance press reveals
##              the whole line (and does nothing else).
##   SHOWN      the whole line is visible. A later press advances. In auto
##              mode the line advances by itself once BOTH its reading
##              allowance and any voice playback are over, plus the
##              voice delay. The allowance starts here, never earlier.
##   DONE       move on to the next line.
##
## Time only passes through tick(), which callers skip while the game is
## paused, so a paused line keeps its remaining allowance.

enum Phase { REVEALING, SHOWN, DONE }

var phase := Phase.REVEALING
var text := ""
var auto := false
## Returns true while this line's voice (recorded or system speech) plays.
var voice_busy: Callable = func() -> bool: return false
## Seconds of reading allowance left (from SHOWN), then of the post-line delay.
var read_left := 0.0
var delay_left := 0.0
## The frame the line became fully visible: a press on that same frame
## never also advances it.
var shown_frame := -1


func _init(line := "", auto_mode := false, busy := Callable()) -> void:
	text = line
	auto = auto_mode
	if busy.is_valid():
		voice_busy = busy
	read_left = StoryPacing.reading_time(text)
	delay_left = StoryPacing.voice_delay()


## The typewriter finished (or a press revealed the rest).
func reveal(frame: int) -> void:
	if phase != Phase.REVEALING:
		return
	phase = Phase.SHOWN
	shown_frame = frame


## An advance press on `frame`. Returns "reveal", "advance" or "" (ignored).
func press(frame: int) -> String:
	match phase:
		Phase.REVEALING:
			reveal(frame)
			return "reveal"
		Phase.SHOWN:
			if frame <= shown_frame:
				return ""  # the press that revealed the line doesn't advance it
			phase = Phase.DONE
			return "advance"
	return ""


## Advance time (only while the game runs). Auto mode finishes the line.
func tick(delta: float) -> void:
	if phase != Phase.SHOWN or not auto:
		return
	if read_left > 0.0:
		read_left -= delta
		return
	if voice_busy.call():
		return  # the voice is still speaking: wait for it
	delay_left -= delta
	if delay_left <= 0.0:
		phase = Phase.DONE


func is_shown() -> bool:
	return phase == Phase.SHOWN


func is_done() -> bool:
	return phase == Phase.DONE
