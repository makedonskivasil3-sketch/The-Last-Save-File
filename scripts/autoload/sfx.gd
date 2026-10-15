extends Node
## Every sound effect in the game, synthesised in code (see Synth) and cached.
##
## Buses (created at startup, all routed to Master):
##   Music   drone layers and stingers        <- Settings.music_volume
##   Memory  flashback music (unmuffled)      <- Settings.music_volume
##   SFX     the world: deletions, eraser, deaths, typing, voices <- Settings.sfx_volume
##   UI      menus; keeps playing while paused <- Settings.sfx_volume
## SFX and Music each carry a low-pass filter that muffle() switches on (pause,
## flashbacks); SFX also has a little reverb so the save feels like a space.
##
## Harshness: sounds listed in HARSH (static bursts, stingers, whines, deaths)
## are scaled by harshness(): Settings.glitch_intensity lowers them gently,
## Settings.reduce_flashing halves them. Glitch-texture sounds (crackle, the
## eraser's ticks) follow glitch intensity directly.
##
## Sounds are rendered lazily on first use; prewarm() queues the common ones so
## they're built a few per frame during calm moments (title screen, waking).

const BUSES := ["Music", "Memory", "SFX", "UI"]
const POOL_SIZE := 14

## Mix level per sound (dB). Anything not listed plays at 0 dB.
const LEVEL := {
	"key_owner": -13.0, "key_system": -21.0, "key_self": -22.0, "voice": -15.0,
	"ui_move": -20.0, "ui_confirm": -13.0, "ui_back": -15.0, "pause": -11.0,
	"deletion": -3.0, "erase_cell": -25.0, "erase_start": -5.0,
	"cursor_arrive": -6.0, "select_loop": -12.0, "click": -7.0,
	"death_erased": -2.0, "death_overwritten": -2.0, "death_selected": -2.0,
	"wound_open": -7.0, "seal": -9.0, "stinger": -8.0, "spotted": -11.0,
	"win": -4.0, "power_off": -5.0, "purge_bell": -7.0, "fragment": -6.0,
	"memory_loop": -9.0, "door_lock": -6.0, "denied": -12.0, "flicker": -13.0,
	"pop": -17.0, "scribble": -16.0, "transition": -15.0, "unload": -5.0,
	"step": -27.0, "heartbeat": -5.0,
	"glitch_charge": -10.0, "glitch_fire": -4.0, "phase": -6.0, "glitch_learn": -6.0,
	"owner_pause": -6.0, "owner_unpause": -7.0,
}
## Loud, sudden or piercing sounds that Reduce flashing / glitch intensity tame.
const HARSH := ["deletion", "erase_start", "cursor_arrive", "select_loop", "click",
	"death_erased", "death_overwritten", "death_selected", "stinger", "spotted",
	"unload", "flicker", "wound_open", "power_off", "glitch_fire"]
## Pure glitch texture: scaled straight by glitch intensity.
const GLITCHY := ["erase_cell", "flicker"]
## Each speaker's voice pitch for dialogue blips.
const VOICES := {"MIRA": 1.25, "WREN": 1.65, "TOBBEN": 0.78, "THE ARCHIVIST": 0.62, "ARIN": 1.0}
## Built a few per frame when prewarm() is called, most-needed first.
const PREWARM := ["key_owner_0", "key_owner_1", "key_owner_2", "key_system", "key_self", "voice",
	"ui_move", "ui_confirm", "ui_back", "pause", "pop", "step_0", "step_1", "transition",
	"door_lock", "denied", "flicker", "scribble", "stinger", "spotted", "erase_cell_0",
	"erase_cell_1", "erase_start", "wound_open", "seal", "fragment", "cursor_arrive",
	"select_loop", "click", "purge_bell", "heartbeat", "death_erased", "death_overwritten",
	"death_selected", "power_off", "unload", "win", "memory_loop", "glitch_charge", "glitch_fire",
	"phase", "glitch_learn", "owner_pause", "owner_unpause"]

var _cache: Dictionary = {}
var _queue: Array = []
var _pool: Array[AudioStreamPlayer] = []
var _ui_pool: Array[AudioStreamPlayer] = []
var _next := 0
var _next_ui := 0
var _last_key := 0
var _last_cell := 0
var _lowpass: Dictionary = {}  # bus name -> AudioEffectLowPassFilter
## The last few sound names requested (newest last). Cheap; lets tests check
## that gameplay events actually make a sound.
var history: Array[String] = []


func _ready() -> void:
	_make_buses()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.bus = "UI"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_ui_pool.append(p)


## Queue the common sounds to be built a few per frame.
func prewarm() -> void:
	for n in PREWARM:
		if not _cache.has(n) and n not in _queue:
			_queue.append(n)


func _process(_delta: float) -> void:
	# Build queued sounds within a small time budget per frame.
	var t0 := Time.get_ticks_usec()
	while not _queue.is_empty() and Time.get_ticks_usec() - t0 < 6000:
		stream(_queue.pop_front())


# --- playing ----------------------------------------------------------------------

## Plays a one-shot. `name` may be a variant ("key_owner_1"); the mix level is
## looked up by base name. Returns the player (or null if nothing played).
func play(name: String, volume_db: float = 0.0, pitch: float = 1.0, jitter: float = 0.04, bus: String = "SFX") -> AudioStreamPlayer:
	var base := _base(name)
	history.append(name)
	if history.size() > 32:
		history.pop_front()
	var gain := 1.0
	if base in HARSH:
		gain *= harshness()
	if base in GLITCHY:
		gain *= lerpf(0.15, 1.0, Settings.glitch_intensity)
	if gain <= 0.01:
		return null
	var p: AudioStreamPlayer
	if bus == "UI":
		p = _ui_pool[_next_ui]
		_next_ui = (_next_ui + 1) % _ui_pool.size()
	else:
		p = _pool[_next]
		_next = (_next + 1) % _pool.size()
		p.bus = bus
	p.stream = stream(name)
	p.volume_db = LEVEL.get(base, 0.0) + volume_db + linear_to_db(gain)
	p.pitch_scale = maxf(0.05, pitch * (1.0 + randf_range(-jitter, jitter)))
	p.play()
	return p


## Menu sounds: always audible, even while the game is paused.
func ui(name: String) -> void:
	play(name, 0.0, 1.0, 0.02, "UI")


## One key of the console typing. kind: "owner", "system" or "self".
func type_key(kind: String) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_key < 28:
		return
	_last_key = now
	match kind:
		"owner":
			play("key_owner_%d" % (randi() % 3), 0.0, 1.0, 0.06)
		"self":
			play("key_self", 0.0, 1.0, 0.08)
		_:
			play("key_system", 0.0, 1.0, 0.05)


## A dialogue blip in the speaker's voice.
func voice_blip(speaker: String) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_key < 45:
		return
	_last_key = now
	play("voice", 0.0, VOICES.get(speaker, 1.1), 0.07)


## A cell of the room turning to void: tiny ticks, rate-limited.
func erase_tick() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_cell < 90:
		return
	_last_cell = now
	play("erase_cell_%d" % (randi() % 2), 0.0, 1.0, 0.25)


## Each character's deletion sounds like them: pitch and timbre per id.
func deletion(npc_id: String) -> void:
	play("deletion_" + npc_id, 0.0, 1.0, 0.0)


## A dedicated player for a sustained loop the caller controls (cursor whine).
func loop_player(name: String, parent: Node) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = stream(name)
	p.volume_db = -80.0
	parent.add_child(p)
	p.play()
	return p


## Dull the world: low-pass on SFX and Music (pause menu, flashbacks).
func muffle(on: bool, cutoff_hz: float = 700.0) -> void:
	for bus in _lowpass:
		var f: AudioEffectLowPassFilter = _lowpass[bus]
		f.cutoff_hz = cutoff_hz
		AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index(bus), 1 if bus == "SFX" else 0, on)


## 0..1 multiplier for harsh sounds, from the accessibility settings.
func harshness() -> float:
	var h := lerpf(0.45, 1.0, Settings.glitch_intensity)
	if Settings.reduce_flashing:
		h *= 0.5
	return h


## The rendered stream for a sound name, building it on first use.
func stream(name: String) -> AudioStreamWAV:
	if not _cache.has(name):
		_cache[name] = _build(name)
	return _cache[name]


func _base(name: String) -> String:
	for prefix in ["key_owner", "erase_cell", "deletion", "step"]:
		if name.begins_with(prefix):
			return prefix
	return name


func _make_buses() -> void:
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) != -1:
			continue
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus)
		AudioServer.set_bus_send(i, "Master")
	var sfx := AudioServer.get_bus_index("SFX")
	var reverb := AudioEffectReverb.new()
	reverb.room_size = 0.55
	reverb.damping = 0.6
	reverb.wet = 0.12
	reverb.dry = 1.0
	AudioServer.add_bus_effect(sfx, reverb, 0)
	for bus in ["Music", "SFX"]:
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 700.0
		var idx := AudioServer.get_bus_index(bus)
		AudioServer.add_bus_effect(idx, lp)
		AudioServer.set_bus_effect_enabled(idx, AudioServer.get_bus_effect_count(idx) - 1, false)
		_lowpass[bus] = lp


# --- the sounds ---------------------------------------------------------------------

func _build(name: String) -> AudioStreamWAV:
	var S := Synth
	var W := Synth.Wave
	if name.begins_with("deletion_"):
		return _deletion(name.trim_prefix("deletion_"))
	match name:
		# The owner's keyboard: a bright tick, a plastic clack and a low thunk.
		"key_owner_0", "key_owner_1", "key_owner_2":
			var v := int(name[-1])
			var b := S.begin(0.07)
			S.noise(b, 0.0, 0.006, 0.6, 0.0005, 300.0, 1.0, -1.0, true)
			S.tone(b, 0.0, 0.02, 1700.0 + v * 260.0, 1500.0 + v * 200.0, 0.22, W.SQUARE, 0.0005, 260.0)
			S.tone(b, 0.002, 0.05, 115.0 - v * 8.0, 80.0, 0.5, W.SINE, 0.001, 90.0)
			S.normalize(b, 0.8)
			return S.to_wav(b)
		# System text: a thin teletype tick.
		"key_system":
			var b := S.begin(0.035)
			S.tone(b, 0.0, 0.012, 3300.0, 3000.0, 0.3, W.SQUARE, 0.0005, 350.0)
			S.noise(b, 0.0, 0.004, 0.4, 0.0005, 500.0, 1.0, -1.0, true)
			S.normalize(b, 0.6)
			return S.to_wav(b)
		# Your own thoughts: a soft breath of a note.
		"key_self":
			var b := S.begin(0.09)
			S.tone(b, 0.0, 0.09, 660.0, 610.0, 0.3, W.SINE, 0.012, 35.0)
			S.noise(b, 0.0, 0.06, 0.05, 0.01, 40.0, 0.05)
			S.normalize(b, 0.5)
			return S.to_wav(b)
		# Dialogue blip (pitched per speaker at play time).
		"voice":
			var b := S.begin(0.06)
			S.tone(b, 0.0, 0.06, 240.0, 220.0, 0.4, W.SQUARE, 0.002, 45.0)
			S.tone(b, 0.0, 0.06, 480.0, 440.0, 0.15, W.TRIANGLE, 0.002, 60.0)
			S.lowpass(b, 0.35)
			S.normalize(b, 0.7)
			return S.to_wav(b)
		"ui_move":
			var b := S.begin(0.03)
			S.tone(b, 0.0, 0.03, 1250.0, 1150.0, 0.4, W.SINE, 0.001, 140.0)
			return S.to_wav(b)
		"ui_confirm":
			var b := S.begin(0.12)
			S.tone(b, 0.0, 0.05, 660.0, 660.0, 0.35, W.SQUARE, 0.001, 50.0)
			S.tone(b, 0.045, 0.07, 990.0, 990.0, 0.35, W.SQUARE, 0.001, 45.0)
			S.lowpass(b, 0.4)
			return S.to_wav(b)
		"ui_back":
			var b := S.begin(0.12)
			S.tone(b, 0.0, 0.05, 990.0, 990.0, 0.35, W.SQUARE, 0.001, 50.0)
			S.tone(b, 0.045, 0.07, 660.0, 660.0, 0.35, W.SQUARE, 0.001, 45.0)
			S.lowpass(b, 0.4)
			return S.to_wav(b)
		# Pause: the CRT relay clicks and the hum sags.
		"pause":
			var b := S.begin(0.3)
			S.noise(b, 0.0, 0.006, 0.7, 0.0005, 300.0)
			S.tone(b, 0.0, 0.3, 150.0, 70.0, 0.5, W.SINE, 0.002, 10.0)
			S.normalize(b, 0.8)
			return S.to_wav(b)
		"pop":
			var b := S.begin(0.06)
			S.tone(b, 0.0, 0.06, 880.0, 1400.0, 0.4, W.SINE, 0.002, 40.0)
			return S.to_wav(b)
		# Footsteps: barely there, a little digital.
		"step_0", "step_1":
			var b := S.begin(0.04)
			S.noise(b, 0.0, 0.03, 0.5, 0.001, 120.0, 0.25)
			S.tone(b, 0.0, 0.03, 190.0 + (30.0 if name == "step_1" else 0.0), 150.0, 0.4, W.SINE, 0.001, 110.0)
			S.normalize(b, 0.6)
			return S.to_wav(b)
		# Moving between areas: a static whoosh, like changing channel.
		"transition":
			var b := S.begin(0.45)
			S.noise(b, 0.0, 0.45, 0.6, 0.15, 4.0, 0.05, 0.6)
			S.fade_out(b, 0.2)
			S.normalize(b, 0.7)
			return S.to_wav(b)
		"door_lock":
			var b := S.begin(0.45)
			S.noise(b, 0.0, 0.08, 0.8, 0.001, 40.0, 0.2)
			S.tone(b, 0.0, 0.3, 95.0, 70.0, 0.7, W.SINE, 0.001, 14.0)
			S.tone(b, 0.01, 0.12, 1250.0, 1180.0, 0.18, W.SQUARE, 0.001, 35.0)
			S.normalize(b, 0.9)
			return S.to_wav(b)
		# The save crystal refusing you.
		"denied":
			var b := S.begin(0.4)
			S.tone(b, 0.0, 0.4, 110.0, 104.0, 0.6, W.SQUARE, 0.002, 6.0)
			S.gate(b, 0.0, 0.4, 28.0, 0.6)
			S.lowpass(b, 0.3)
			S.normalize(b, 0.8)
			return S.to_wav(b)
		# Mains buzz from the flickering lights.
		"flicker":
			var b := S.begin(0.55)
			S.tone(b, 0.0, 0.55, 120.0, 120.0, 0.5, W.SAW, 0.002, 3.0)
			S.tone(b, 0.0, 0.55, 240.0, 240.0, 0.25, W.SQUARE, 0.002, 3.0)
			S.gate(b, 0.0, 0.55, 22.0, 0.5)
			S.normalize(b, 0.7)
			return S.to_wav(b)
		# A note being rewritten: dry scratching.
		"scribble":
			var b := S.begin(0.45)
			S.noise(b, 0.0, 0.45, 0.6, 0.01, 4.0, 0.7, -1.0, true)
			S.gate(b, 0.0, 0.45, 18.0, 0.55)
			S.lowpass(b, 0.5)
			S.normalize(b, 0.6)
			return S.to_wav(b)
		# Threshold stinger: a reversed swell into a hit. Classic dread.
		"stinger":
			var b := S.begin(1.5)
			for f in [110.0, 116.5, 155.6]:
				S.tone(b, 0.0, 0.9, f, f * 1.01, 0.25, W.SAW, 0.85, 0.0)
			S.noise(b, 0.0, 0.9, 0.25, 0.85, 0.0, 0.1, 0.5)
			S.tone(b, 0.9, 0.6, 60.0, 38.0, 0.9, W.SINE, 0.002, 7.0)
			S.noise(b, 0.9, 0.5, 0.6, 0.001, 9.0, 0.6)
			S.lowpass(b, 0.55)
			S.normalize(b, 0.9)
			return S.to_wav(b)
		# Arin sees you: a sour two-note stab.
		"spotted":
			var b := S.begin(0.5)
			S.tone(b, 0.0, 0.5, 466.0, 460.0, 0.4, W.SAW, 0.003, 7.0)
			S.tone(b, 0.0, 0.5, 494.0, 490.0, 0.4, W.SAW, 0.003, 7.0)
			S.noise(b, 0.0, 0.06, 0.4, 0.001, 50.0)
			S.lowpass(b, 0.4)
			S.normalize(b, 0.8)
			return S.to_wav(b)
		# One cell turning to void.
		"erase_cell_0", "erase_cell_1":
			var b := S.begin(0.05)
			S.noise(b, 0.0, 0.03, 0.8, 0.0005, 120.0, 1.0, -1.0, true)
			S.tone(b, 0.0, 0.04, 70.0, 50.0, 0.5, W.SINE, 0.001, 70.0)
			S.crush(b, 0.0, 0.05, 4, 3 + int(name[-1]) * 2)
			S.normalize(b, 0.7)
			return S.to_wav(b)
		# The eraser starting: the floor groans and the room sags.
		"erase_start":
			var b := S.begin(2.2)
			S.noise(b, 0.0, 2.2, 0.8, 0.6, 1.5, 0.02, 0.06)
			S.tone(b, 0.0, 2.2, 48.0, 28.0, 0.8, W.SINE, 0.4, 1.2)
			S.crackle(b, 0.3, 1.8, 18.0, 0.3)
			S.fade_out(b, 0.6)
			S.normalize(b, 0.95)
			return S.to_wav(b)
		# A wall tearing open.
		"wound_open":
			var b := S.begin(1.2)
			S.noise(b, 0.0, 1.2, 0.8, 0.05, 2.5, 0.05, 0.7)
			S.gate(b, 0.0, 1.0, 40.0, 0.65)
			S.tone(b, 0.0, 1.2, 85.0, 58.0, 0.5, W.SINE, 0.1, 2.0)
			S.normalize(b, 0.85)
			return S.to_wav(b)
		# The owner stitching a seam shut.
		"seal":
			var b := S.begin(1.0)
			for t in [0.0, 0.22, 0.44]:
				S.tone(b, t, 0.15, 130.0, 95.0, 0.7, W.SINE, 0.001, 30.0)
				S.noise(b, t, 0.02, 0.4, 0.0005, 150.0, 1.0, -1.0, true)
			S.noise(b, 0.5, 0.5, 0.15, 0.05, 5.0, 0.8, -1.0, true)
			S.normalize(b, 0.8)
			return S.to_wav(b)
		# A memory fragment: a reversed shimmer resolving into a glass chime.
		"fragment":
			var b := S.begin(1.6)
			S.noise(b, 0.0, 0.5, 0.15, 0.45, 0.0, 0.6, -1.0, true)
			for f in [1318.5, 1760.0, 2637.0]:
				S.tone(b, 0.5, 1.1, f, f, 0.25, W.SINE, 0.002, 3.5, Vector2(0.004, 5.0))
			S.tone(b, 0.5, 1.1, 659.0, 659.0, 0.2, W.TRIANGLE, 0.002, 2.5)
			S.normalize(b, 0.8)
			return S.to_wav(b)
		# The cursor reaching in: piercing whine riding on static.
		"cursor_arrive":
			var b := S.begin(1.8)
			S.tone(b, 0.0, 1.8, 2900.0, 5200.0, 0.25, W.SINE, 0.03, 1.6, Vector2(0.015, 31.0))
			S.tone(b, 0.0, 1.8, 3050.0, 5350.0, 0.15, W.SINE, 0.03, 1.6)
			S.noise(b, 0.0, 0.7, 0.55, 0.005, 3.5, 0.9)
			S.crackle(b, 0.0, 1.5, 40.0, 0.3)
			S.normalize(b, 0.85)
			return S.to_wav(b)
		# Hovering over you: a pulsing tone (loop; pitch/volume set live).
		"select_loop":
			var b := S.begin(1.0)
			S.tone(b, 0.0, 1.0, 1800.0, 1800.0, 0.5, W.SINE, 0.0, 0.0, Vector2(0.0, 0.0))
			# 12 Hz tremolo, 12 whole cycles: seamless.
			for i in b.size():
				b[i] *= 0.6 + 0.4 * sin(TAU * 12.0 * i / S.rate)
			return S.to_wav(b, true)
		# Charging a glitch: a buzzing, rising wrongness (loop; pitch set live).
		"glitch_charge":
			var b := S.begin(1.0)
			S.tone(b, 0.0, 1.0, 220.0, 220.0, 0.35, W.SQUARE, 0.0, 0.0)
			S.tone(b, 0.0, 1.0, 331.0, 331.0, 0.2, W.SAW, 0.0, 0.0)
			S.crackle(b, 0.0, 1.0, 60.0, 0.25)
			S.gate(b, 0.0, 1.0, 30.0, 0.7)
			S.lowpass(b, 0.45)
			S.loop_crossfade(b, 0.05)
			S.normalize(b, 0.6)
			return S.to_wav(b, true)
		# A glitch landing: reality crunches, skips and comes back wrong.
		"glitch_fire":
			var b := S.begin(0.7)
			S.tone(b, 0.0, 0.5, 1900.0, 140.0, 0.5, W.SQUARE, 0.001, 6.0)
			S.noise(b, 0.0, 0.35, 0.7, 0.001, 9.0, 0.9)
			S.tone(b, 0.05, 0.6, 70.0, 45.0, 0.7, W.SINE, 0.002, 6.0)
			S.crush(b, 0.0, 0.5, 3, 7)
			S.gate(b, 0.08, 0.3, 45.0, 0.6)
			S.normalize(b, 0.9)
			return S.to_wav(b)
		# Slipping through a wall: a reversed whoosh and a soft pop.
		"phase":
			var b := S.begin(0.45)
			S.noise(b, 0.0, 0.35, 0.6, 0.3, 0.0, 0.08, 0.7, true)
			S.tone(b, 0.3, 0.15, 400.0, 1600.0, 0.4, W.SINE, 0.002, 30.0)
			S.normalize(b, 0.8)
			return S.to_wav(b)
		# A new glitch learned: a bright, broken arpeggio.
		"glitch_learn":
			var b := S.begin(1.2)
			var notes := [523.3, 659.3, 784.0, 1046.5, 987.8]
			for i in notes.size():
				S.tone(b, i * 0.1, 0.6, notes[i], notes[i], 0.3, W.SQUARE, 0.002, 6.0)
			S.crush(b, 0.0, 1.2, 4, 3)
			S.lowpass(b, 0.5)
			S.normalize(b, 0.8)
			return S.to_wav(b)
		# The owner's world stopping: everything sags to a halt...
		"owner_pause":
			var b := S.begin(1.0)
			S.tone(b, 0.0, 1.0, 330.0, 55.0, 0.6, W.SAW, 0.002, 2.5)
			S.noise(b, 0.0, 0.2, 0.5, 0.001, 15.0, 0.4)
			S.lowpass(b, 0.3)
			S.normalize(b, 0.8)
			return S.to_wav(b)
		# ...and lurching back into motion.
		"owner_unpause":
			var b := S.begin(0.6)
			S.tone(b, 0.0, 0.6, 55.0, 330.0, 0.6, W.SAW, 0.05, 4.0)
			S.lowpass(b, 0.3)
			S.normalize(b, 0.8)
			return S.to_wav(b)
		# A mouse button. Plastic, close, final.
		"click":
			var b := S.begin(0.12)
			for t in [0.0, 0.07]:
				S.noise(b, t, 0.004, 0.8, 0.0002, 600.0, 1.0, -1.0, true)
				S.tone(b, t, 0.01, 2600.0, 2400.0, 0.3, W.SQUARE, 0.0002, 500.0)
			S.normalize(b, 0.9)
			return S.to_wav(b)
		# Erased: crunching down into nothing, getting coarser as it goes.
		"death_erased":
			var b := S.begin(2.4)
			S.noise(b, 0.0, 1.7, 0.8, 0.002, 1.2, 0.9, 0.02)
			S.tone(b, 0.0, 1.7, 220.0, 38.0, 0.6, W.SAW, 0.002, 1.5)
			S.crush(b, 0.3, 0.5, 6, 2)
			S.crush(b, 0.8, 0.5, 4, 5)
			S.crush(b, 1.3, 0.5, 3, 12)
			S.tone(b, 1.75, 0.6, 55.0, 35.0, 0.9, W.SINE, 0.001, 6.0)
			S.normalize(b, 0.95)
			return S.to_wav(b)
		# Overwritten: a storm of data writing over you, then a slam.
		"death_overwritten":
			var b := S.begin(2.4)
			var t := 0.0
			var gap := 0.06
			while t < 1.05:
				var f := randf_range(600.0, 2600.0)
				S.tone(b, t, 0.03, f, f, 0.25, W.SQUARE, 0.001, 80.0)
				t += gap
				gap = maxf(0.012, gap * 0.9)
			S.noise(b, 0.0, 1.1, 0.4, 1.0, 0.0, 0.1, 0.8)
			S.tone(b, 1.1, 0.5, 70.0, 45.0, 1.0, W.SINE, 0.001, 8.0)
			S.noise(b, 1.1, 0.3, 0.7, 0.001, 12.0, 0.3)
			S.tone(b, 1.15, 1.2, 440.0, 438.0, 0.18, W.TRIANGLE, 0.01, 2.0)
			S.tone(b, 1.15, 1.2, 466.2, 466.0, 0.18, W.TRIANGLE, 0.01, 2.0)
			S.normalize(b, 0.95)
			return S.to_wav(b)
		# Selected: double click, an error chime falling, glass scattering.
		"death_selected":
			var b := S.begin(2.0)
			for t in [0.0, 0.07]:
				S.noise(b, t, 0.004, 0.8, 0.0002, 600.0, 1.0, -1.0, true)
				S.tone(b, t, 0.01, 2600.0, 2400.0, 0.3, W.SQUARE, 0.0002, 500.0)
			var notes := [880.0, 659.0, 440.0]
			for i in notes.size():
				S.tone(b, 0.3 + i * 0.14, 0.4, notes[i], notes[i], 0.3, W.SQUARE, 0.002, 9.0)
			for i in 26:
				var f := randf_range(2200.0, 5200.0)
				S.tone(b, 0.75 + randf() * 0.7, 0.12, f, f * 0.9, 0.12, W.SINE, 0.001, 30.0)
			S.crackle(b, 0.75, 0.9, 60.0, 0.35)
			S.lowpass(b, 0.6)
			S.normalize(b, 0.9)
			return S.to_wav(b)
		# Winning: a rising arpeggio, a warm chord... and one note that's wrong.
		"win":
			var b := S.begin(3.6, 16000)
			var arp := [440.0, 523.3, 659.3, 880.0]
			for i in arp.size():
				S.tone(b, i * 0.14, 0.5, arp[i], arp[i], 0.25, W.TRIANGLE, 0.003, 5.0)
			for f in [440.0, 554.4, 659.3]:
				S.tone(b, 0.6, 2.8, f, f, 0.2, W.TRIANGLE, 0.08, 0.9, Vector2(0.003, 4.0))
			S.tone(b, 2.3, 1.3, 466.2, 466.2, 0.12, W.SINE, 0.6, 1.2)
			S.crush(b, 0.0, 0.6, 7, 2)
			S.normalize(b, 0.85)
			return S.to_wav(b)
		# Quitting: the CRT powers off. Whine, thunk, the picture's last breath.
		"power_off":
			var b := S.begin(1.3)
			S.tone(b, 0.0, 0.5, 9500.0, 9000.0, 0.08, W.SINE, 0.001, 5.0)
			S.tone(b, 0.0, 0.7, 800.0, 40.0, 0.4, W.SINE, 0.001, 3.0)
			S.tone(b, 0.0, 0.4, 60.0, 50.0, 0.9, W.SINE, 0.001, 9.0)
			S.noise(b, 0.0, 1.2, 0.3, 0.001, 3.5, 0.5)
			S.normalize(b, 0.9)
			return S.to_wav(b)
		# Purge progress: a low, inharmonic bell. Something is counting.
		"purge_bell":
			var b := S.begin(2.6, 11025)  # all partials < 600 Hz: 11 kHz is plenty
			var partials := [[98.0, 0.6, 1.2], [263.0, 0.35, 1.8], [412.0, 0.25, 2.5], [581.0, 0.15, 3.2], [99.4, 0.4, 1.0]]
			for p in partials:
				S.tone(b, 0.0, 2.6, p[0], p[0] * 0.998, p[1], W.SINE, 0.003, p[2])
			S.noise(b, 0.0, 0.03, 0.3, 0.001, 100.0, 0.3)
			S.normalize(b, 0.85)
			return S.to_wav(b)
		# Entering the Edge: the world unloading under your feet.
		"unload":
			var b := S.begin(1.6)
			S.tone(b, 0.0, 1.6, 300.0, 30.0, 0.6, W.SAW, 0.002, 1.8)
			S.noise(b, 0.0, 1.4, 0.5, 0.002, 2.0, 0.8, 0.03)
			S.crush(b, 0.2, 1.4, 5, 4)
			S.normalize(b, 0.9)
			return S.to_wav(b)
		# Flashback music: a slow music box in A minor, wobbling like old tape.
		# 8 s loop at 8 kHz; tails of late notes fold back to the start.
		"memory_loop":
			var b := S.begin(9.0, 8000)  # lo-fi on purpose: an old tape of a music box
			var melody := [440.0, 523.3, 659.3, 587.3, 523.3, 493.9, 440.0, 392.0,
				349.2, 440.0, 523.3, 493.9, 440.0, 415.3, 440.0, 0.0]
			for i in melody.size():
				if melody[i] > 0.0:
					S.tone(b, i * 0.5, 0.9, melody[i], melody[i], 0.3, W.TRIANGLE, 0.004, 3.4)
					S.tone(b, i * 0.5, 0.35, melody[i] * 2.0, melody[i] * 2.0, 0.08, W.SINE, 0.002, 8.0)
			S.wrap(b, 8.0)
			S.lowpass(b, 0.55)
			S.normalize(b, 0.7)
			return S.to_wav(b, true)
		"heartbeat":
			var b := S.begin(0.5)
			S.tone(b, 0.0, 0.25, 62.0, 48.0, 1.0, W.SINE, 0.004, 16.0)
			S.tone(b, 0.18, 0.3, 58.0, 44.0, 0.7, W.SINE, 0.004, 14.0)
			S.normalize(b, 0.9)
			return S.to_wav(b)
	push_warning("Sfx: unknown sound '%s'" % name)
	return S.to_wav(S.begin(0.01))


## A character's deletion: convulsion in their voice, a burst, a falling sweep,
## a thud, and static that won't stop for a moment. Each one sounds like them.
func _deletion(npc_id: String) -> AudioStreamWAV:
	var S := Synth
	var W := Synth.Wave
	var looks := {
		"mira": [330.0, W.TRIANGLE], "wren": [520.0, W.TRIANGLE],
		"tobben": [140.0, W.SAW], "arin": [220.0, W.SQUARE],
	}
	var look: Array = looks.get(npc_id, [260.0, W.SQUARE])
	var f: float = look[0]
	var wave: Synth.Wave = look[1]
	var b := S.begin(2.0)
	# Convulsing: their voice stuttering between pitches.
	var steps := [1.0, 1.5, 0.75, 1.26, 0.5, 1.5]
	for i in steps.size():
		S.tone(b, i * 0.07, 0.08, f * steps[i], f * steps[i], 0.35, wave, 0.001, 20.0)
	S.crush(b, 0.0, 0.45, 5, 3)
	# Burst and fall.
	S.noise(b, 0.45, 0.5, 0.7, 0.001, 6.0, 0.9)
	S.tone(b, 0.45, 0.9, f * 4.0, f * 0.25, 0.45, wave, 0.001, 3.0)
	# The thud, then the residue.
	S.tone(b, 0.9, 0.4, 62.0, 40.0, 0.8, W.SINE, 0.002, 9.0)
	S.crackle(b, 1.0, 1.0, 25.0, 0.25)
	S.fade_out(b, 0.4)
	S.normalize(b, 0.9)
	return S.to_wav(b)
