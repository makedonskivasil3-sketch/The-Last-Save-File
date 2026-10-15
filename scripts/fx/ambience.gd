class_name Ambience
extends Node
## Each area's sound bed, on the Music bus (under the drone):
##   square   wind, birds and distant voices; thinner with every character
##            the owner has deleted, and the birds go quiet during the hunt
##   archive  a low hum and pages turning somewhere in the stacks
##   edge     the music box theme backwards, slowed: time running out
##   oob      the theme upside down at half speed, over thin air
##   room     nothing but the drone (the owner is listening)
## World swaps it on every area change.

var world: World
var area_id := ""

var _bed: AudioStreamPlayer
var _theme: AudioStreamPlayer
var _next_event := 2.0


## Build the bed for an area (call once, right after creating it).
func setup(w: World, id: String) -> void:
	world = w
	area_id = id
	match id:
		"square":
			_bed = _loop(Sfx.stream("wind"), Sfx.LEVEL["wind"])
		"archive":
			_bed = _loop(Sfx.stream("archive_hum"), Sfx.LEVEL["archive_hum"])
		"edge":
			_theme = _loop(MusicBox.stream(OwnerMemory.fragments.size(), "reverse"), -14.0)
			_theme.pitch_scale = 0.8
		"bin":
			# The archive's hum, lower: a drive spinning somewhere.
			_bed = _loop(Sfx.stream("archive_hum"), Sfx.LEVEL["archive_hum"] - 2.0)
			_bed.pitch_scale = 0.7
		"oob":
			_bed = _loop(Sfx.stream("air"), Sfx.LEVEL["air"])
			_theme = _loop(MusicBox.stream(OwnerMemory.fragments.size(), "invert"), -12.0)
			_theme.pitch_scale = 0.5


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
