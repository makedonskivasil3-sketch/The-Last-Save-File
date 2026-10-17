class_name VoiceOver
extends RefCounted
## Recorded voice lines for key moments (docs/VOICE_SCRIPT.md). A line plays
## only if its file exists in res://audio/voice/ (<id>.ogg, .mp3 or .wav);
## everything else keeps the procedural voice and the subtitles as they are.
## Subtitles always show: a recording never replaces the text.

const DIR := "res://audio/voice/"
const EXTENSIONS := ["ogg", "mp3", "wav"]


## The file for a line id, or "" if it hasn't been recorded.
static func path_for(id: String) -> String:
	for ext in EXTENSIONS:
		var p := "%s%s.%s" % [DIR, id, ext]
		if ResourceLoader.exists(p):
			return p
	return ""


static func has_line(id: String) -> bool:
	return path_for(id) != ""


## Play a recorded line on the Voice bus under `parent`. Returns the player
## (freed when it finishes), or null if the line isn't recorded.
static func play(parent: Node, id: String) -> AudioStreamPlayer:
	var p := path_for(id)
	if p == "":
		return null
	var stream := load(p) as AudioStream
	if stream == null:
		return null
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Voice"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return player
