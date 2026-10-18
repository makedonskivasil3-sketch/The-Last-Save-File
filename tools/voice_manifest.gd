extends SceneTree
## Writes audio/voice/manifest.csv from the game's story text.
##   godot --headless --path . -s res://tools/voice_manifest.gd
## Run it after changing any voiced line; tests/test_voice_manifest.gd fails
## while the file is out of date.
##
## The manifest code is loaded at runtime (not named as a class) so it
## compiles after the autoloads it reads (OwnerMemory) exist.

func _initialize() -> void:
	_write.call_deferred()


func _write() -> void:
	var vm: GDScript = load("res://scripts/audio/voice_manifest.gd")
	var rows: Array = vm.rows()
	var f := FileAccess.open(vm.PATH, FileAccess.WRITE)
	f.store_string(vm.to_csv(rows))
	f.close()
	print("wrote %d lines to %s" % [rows.size(), vm.PATH])
	quit()
