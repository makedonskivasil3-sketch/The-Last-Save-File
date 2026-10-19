class_name Narration
extends Node
## Optional system speech. Captions remain the source of truth on platforms
## without a voice. Never queue stale dialogue or speak after leaving a scene.
static var _english_voices: PackedStringArray = []

var _voice := ""
var _owns_speech := false
var last_text := ""
var supported := false

func _ready() -> void:
	supported = available()
	Settings.changed.connect(_settings_changed)

## Asked again while the list is empty: browsers (and some desktops) only
## report their voices a moment after startup, and caching the first, empty
## answer switched narration off for the whole session.
static func available() -> bool:
	if _english_voices.is_empty() and DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		_english_voices = DisplayServer.tts_get_voices_for_language("en")
	return not _english_voices.is_empty()

func speak(text: String, speaker := "") -> void:
	if not Settings.narration or Settings.voice_volume <= 0.001 or Settings.volume <= 0.001:
		return
	if _voice == "":
		supported = available()  # voices may have arrived since _ready
		if not supported:
			return
		_voice = _english_voices[0]
	last_text = (speaker + ". " if speaker != "" else "") + text
	var level := roundi(Settings.voice_volume * Settings.volume * 100.0)
	DisplayServer.tts_speak(last_text, _voice, level, 0.85 if speaker == "OWNER" else 1.0, 1.0, 0, true)
	_owns_speech = true

func is_speaking() -> bool:
	return _owns_speech and DisplayServer.tts_is_speaking()

func stop() -> void:
	if _owns_speech:
		DisplayServer.tts_stop()
	_owns_speech = false
	last_text = ""

func _settings_changed() -> void:
	# A volume or accessibility change must also affect an active utterance.
	stop()

func _notification(what: int) -> void:
	if not _owns_speech:
		return
	if what == NOTIFICATION_PAUSED:
		DisplayServer.tts_pause()
	elif what == NOTIFICATION_UNPAUSED:
		DisplayServer.tts_resume()

func _exit_tree() -> void:
	stop()
