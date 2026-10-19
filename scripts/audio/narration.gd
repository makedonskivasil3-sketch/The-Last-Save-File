class_name Narration
extends Node
## Optional system speech. Captions remain the source of truth on platforms
## without a voice. Never queue stale dialogue or speak after leaving a scene.
static var _english_voices: PackedStringArray = []

var _voice := ""
## Each character speaks in their own way: pitch, pace, and their own system
## voice when the device has several (an iPhone has many English voices).
## "voice" picks from the device's English voices, wrapping round; "" is the
## story's narration and Rue.
const CHARACTER_SPEECH := {
	"": {"voice": 0, "pitch": 1.0, "rate": 1.0},
	"OWNER": {"voice": 1, "pitch": 0.8, "rate": 0.95},
	"MIRA": {"voice": 2, "pitch": 1.15, "rate": 1.0},
	"WREN": {"voice": 3, "pitch": 1.4, "rate": 0.95},
	"TOBBEN": {"voice": 4, "pitch": 0.75, "rate": 0.9},
	"THE ARCHIVIST": {"voice": 5, "pitch": 0.6, "rate": 0.85},
	"ARIN": {"voice": 6, "pitch": 0.9, "rate": 1.0},
	"PIP": {"voice": 7, "pitch": 1.8, "rate": 1.15},
}
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
	var how := speech_for(speaker, _english_voices.size())
	# With one voice for everyone, the name says who is talking; with their
	# own voices, it would only get in the way.
	last_text = (speaker + ". " if speaker != "" and how.say_name else "") + text
	var level := roundi(Settings.voice_volume * Settings.volume * 100.0)
	DisplayServer.tts_speak(last_text, _english_voices[how.voice], level, how.pitch, how.rate, 0, true)
	_owns_speech = true

## How this speaker sounds on a device with `voices` English voices: which
## voice (an index), pitch, rate, and whether to say their name first.
static func speech_for(speaker: String, voices: int) -> Dictionary:
	var c: Dictionary = CHARACTER_SPEECH.get(speaker, CHARACTER_SPEECH[""])
	var n := maxi(voices, 1)
	return {"voice": int(c.voice) % n, "pitch": float(c.pitch), "rate": float(c.rate), "say_name": n < 3}


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
