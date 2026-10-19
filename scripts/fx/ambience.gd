class_name Ambience
extends Node
## Each area's sound bed, on the Music bus (under the drone):
##   square   wind, birds and distant voices; thinner with every character
##            the owner has deleted, and the birds go quiet during the hunt
##   archive  a low hum and pages turning somewhere in the stacks
##   edge     the music box theme backwards, slowed: time running out
##   oob      the theme upside down at half speed, over thin air
##   room     the drone, and the theme faintly, like a toy left playing; it
##            fades as the owner watches more closely
## World swaps it on every area change.

var world: World
var area_id := ""

var _bed: AudioStreamPlayer
var _theme: AudioStreamPlayer
var _next_event := 2.0
var _memory_theme: AudioStreamPlayer
var _memory_level := -1
## The theme's level per calm area (dB, before awareness takes some away).
const THEME_DB := {"archive": -16.0, "square": -20.0, "room": -21.0}


## Build the bed for an area (call once, right after creating it).
func setup(w: World, id: String) -> void:
	world = w
	area_id = id
	if id in ["square", "archive", "room"]:
		_memory_theme = AudioStreamPlayer.new()
		_memory_theme.bus = "Music"
		_memory_theme.volume_db = -60.0
		add_child(_memory_theme)
		MusicBox.prewarm(_level())
	match id:
		"square":
			_bed = _loop(Sfx.stream("wind"), Sfx.LEVEL["wind"])
		"archive":
			_bed = _loop(Sfx.stream("archive_hum"), Sfx.LEVEL["archive_hum"])
		"edge":
			_theme = _loop(MusicBox.stream(_level(), "reverse"), -14.0)
			_theme.pitch_scale = 0.8
		"bin":
			# The archive's hum, lower: a drive spinning somewhere.
			_bed = _loop(Sfx.stream("archive_hum"), Sfx.LEVEL["archive_hum"] - 2.0)
			_bed.pitch_scale = 0.7
		"house":
			# A fridge hum, and the TV's game music through the wall.
			_bed = _loop(Sfx.stream("archive_hum"), Sfx.LEVEL["archive_hum"] - 4.0)
			_bed.pitch_scale = 1.4
			_theme = _loop(MusicBox.stream(_level()), -20.0)
		"oob":
			_bed = _loop(Sfx.stream("air"), Sfx.LEVEL["air"])
			_theme = _loop(MusicBox.stream(_level(), "invert"), -12.0)
			_theme.pitch_scale = 0.5


## The theme's level here: one short of whole. The resolved theme belongs to
## the RUE ending (and the title after it), never to an area.
static func _level() -> int:
	return mini(OwnerMemory.fragments.size(), MusicBox.MAX_LEVEL - 1)


func _loop(s: AudioStream, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	p.stream = s
	p.volume_db = -60.0
	add_child(p)
	p.play()
	create_tween().tween_property(p, "volume_db", db, 1.5)
	return p


## How lively the village still is: every character the owner deleted
## takes some of the sound with them (0..1).
func village_life() -> float:
	var gone := 0
	for id in OwnerMemory.npc_fates:
		if OwnerMemory.is_deleted(id):
			gone += 1
	if world and world.is_mira_deleted():
		gone += 1
	# What you put right gives a little of it back.
	var warmth := 0.0
	if OwnerMemory.mira_quest == "pinned":
		warmth += 0.1
	if OwnerMemory.guestbook_restored:
		warmth += 0.1
	warmth += 0.05 * OwnerMemory.restored.size()
	return clampf(1.0 - gone * 0.3 + warmth, 0.1, 1.0)


func _process(delta: float) -> void:
	if world == null or world.ending != "":
		return
	_update_memory_theme(delta)
	if area_id == "edge" and _theme and world.area.erasure != null and world.area.erasure.active:
		# The backwards theme swells once the Edge starts unloading.
		_theme.volume_db = move_toward(_theme.volume_db, -8.0, 4.0 * delta)
	_next_event -= delta
	if _next_event > 0.0:
		return
	match area_id:
		"square":
			var life := village_life()
			var hunted: bool = world.director.awareness >= OwnerDirector.HUNT
			if not hunted and randf() < 0.6 * life:
				Sfx.play("bird", randf_range(-6.0, 0.0), randf_range(0.85, 1.2), 0.0, "Music")
			elif randf() < life:
				Sfx.play("murmur", randf_range(-6.0, -1.0), randf_range(0.8, 1.1), 0.0, "Music")
			_next_event = randf_range(1.5, 4.5) / maxf(life, 0.2)
		"archive":
			Sfx.play("page_turn", randf_range(-6.0, 0.0), randf_range(0.8, 1.2), 0.0, "Music")
			_next_event = randf_range(4.0, 9.0)
		_:
			_next_event = 10.0


## A restrained musical thread in remembered and safe places. Build only in
## the existing background budget; never synthesize synchronously in a chase.
func _update_memory_theme(delta: float) -> void:
	if _memory_theme == null:
		return
	var level := _level()
	var key := "theme_%d_normal" % level
	if _memory_level != level:
		MusicBox.prewarm(level)
		if OwnerMemory.runtime_cache.has(key):
			_memory_theme.stream = OwnerMemory.runtime_cache[key]
			_memory_theme.volume_db = -60.0
			_memory_theme.play()
			_memory_level = level
	# Heard, not buried (docs/AUDIO_DIAGNOSIS.md): it used to sit at -25/-29 dB
	# under the drone and read as no music at all.
	var target: float = THEME_DB.get(area_id, -20.0) - world.director.awareness * (0.15 if area_id == "room" else 0.12)
	if world.hud.is_dialogue_open() or world.hud.is_cinematic() or world.hud.banner_text() != "":
		target -= 8.0
	_memory_theme.volume_db = move_toward(_memory_theme.volume_db, target, delta * 12.0)
