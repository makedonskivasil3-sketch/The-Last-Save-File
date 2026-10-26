class_name VoiceOver
extends RefCounted
## Recorded or generated voice lines (docs/ASSET_PRODUCTION.md). A line plays
## only if its file exists, at res://audio/voice/<id>.ogg (or .wav / .mp3),
## where <id> is the line's stable dialogue id (audio/voice/manifest.csv).
## Everything else keeps its readable text and procedural voice: a missing
## file never blocks progression. Subtitles always show.
##
## Only one story voice plays at a time: starting a line stops the last one.
## Lines pause with the game, duck the music while they speak, and stop when
## the scene that started them goes away.

const DIR := "res://audio/voice/"
const EXTENSIONS := ["ogg", "wav", "mp3"]

## Streams registered in code (tests, or a mod) take priority over files.
static var _registered: Dictionary = {}
static var _current: WeakRef = null
static var _current_id := ""


static func register(id: String, stream: AudioStream) -> void:
	if stream == null:
		_registered.erase(id)
	else:
		_registered[id] = stream


static func clear_registered() -> void:
	_registered.clear()


## The file for a line id, or "" if it hasn't been recorded.
static func path_for(id: String) -> String:
	if id == "":
		return ""
	for ext in EXTENSIONS:
		var p := "%s%s.%s" % [DIR, id, ext]
		if ResourceLoader.exists(p):
			return p
	return ""


static func has_line(id: String) -> bool:
	return id != "" and (_registered.has(id) or path_for(id) != "")


static func stream_for(id: String) -> AudioStream:
	if _registered.has(id):
		return _registered[id]
	var p := path_for(id)
	return load(p) as AudioStream if p != "" else null


## Play a line under `parent` on the Voice bus. Returns the player (freed
## when it finishes), or null if the line has no recording. while_paused:
## play even though the game is paused (replaying from the history page).
static func play(parent: Node, id: String, while_paused := false) -> AudioStreamPlayer:
	stop()
	var stream := stream_for(id)
	if stream == null or parent == null or not parent.is_inside_tree():
		return null
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Voice"
	# Story lines stop with the game; a replay from the pause menu runs anyway.
	player.process_mode = Node.PROCESS_MODE_ALWAYS if while_paused else Node.PROCESS_MODE_PAUSABLE
	parent.add_child(player)
	player.finished.connect(_finished.bind(player))
	player.tree_exiting.connect(_finished.bind(player))
	player.play()
	_current = weakref(player)
	_current_id = id
	Sfx.duck_for_speech(true)
	return player


static var _preview: WeakRef = null


## Replay a line from the History page while the game is paused. It uses its
## own player, so the paused story line keeps its place and resumes after.
static func preview(parent: Node, id: String) -> AudioStreamPlayer:
	var old: Variant = _preview.get_ref() if _preview else null
	if is_instance_valid(old):
		(old as AudioStreamPlayer).queue_free()
	var stream := stream_for(id)
	if stream == null or parent == null or not parent.is_inside_tree():
		return null
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Voice"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	_preview = weakref(player)
	return player


static func stop_preview() -> void:
	var old: Variant = _preview.get_ref() if _preview else null
	if is_instance_valid(old):
		(old as AudioStreamPlayer).queue_free()
	_preview = null


## The line that's playing now, or null.
static func current() -> AudioStreamPlayer:
	var p: Variant = _current.get_ref() if _current else null
	return p as AudioStreamPlayer if is_instance_valid(p) else null


static func current_id() -> String:
	return _current_id if current() != null else ""


## How far the current take has played, 0..1 (0 with none).
static func progress() -> float:
	var p := current()
	if p == null or p.stream == null or p.stream.get_length() <= 0.0:
		return 0.0
	return clampf(p.get_playback_position() / p.stream.get_length(), 0.0, 1.0)


## True while a story voice is speaking. A paused line still counts: the
## player is freed only when it finishes or is stopped. (While the game is
## paused Godot reports playing = false, so that flag alone can't be used.)
static func is_playing() -> bool:
	return current() != null


## Stop whatever is speaking (advancing, skipping, leaving the scene).
static func stop() -> void:
	var p := current()
	if p:
		p.stop()
		_finished(p)


static func _finished(player: AudioStreamPlayer) -> void:
	if current() == player:
		_current = null
		_current_id = ""
		Sfx.duck_for_speech(false)
	if is_instance_valid(player) and player.is_inside_tree() and not player.is_queued_for_deletion():
		player.queue_free()
