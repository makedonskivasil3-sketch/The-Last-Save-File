class_name SafeFile
## Writing the save without ever destroying the last good copy.
##
## write_atomic: write `path.tmp`, read it back, then rotate the old file to
## `path.bak` and move the new one into place. If the game dies at any point,
## one of the three is complete. read_json tries them in that order, and keeps
## a file it couldn't read as `path.corrupt` instead of silently writing over it.

const TMP := ".tmp"
const BAK := ".bak"
const CORRUPT := ".corrupt"


static func write_atomic(path: String, text: String) -> bool:
	var tmp := path + TMP
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("SafeFile: could not open %s (%s)" % [tmp, error_string(FileAccess.get_open_error())])
		return false
	f.store_string(text)
	f.close()
	# Read it back: a full disk or a failed write must not replace a good save.
	if FileAccess.get_file_as_string(tmp) != text:
		push_warning("SafeFile: %s didn't read back intact, keeping the old save" % tmp)
		DirAccess.remove_absolute(tmp)
		return false
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + BAK):
			DirAccess.remove_absolute(path + BAK)
		if DirAccess.rename_absolute(path, path + BAK) != OK:
			push_warning("SafeFile: could not back up %s" % path)
			return false
	if DirAccess.rename_absolute(tmp, path) != OK:
		push_warning("SafeFile: could not move %s into place (the backup is intact)" % tmp)
		return false
	return true


## The first of path, path.tmp, path.bak that parses as a JSON object, and
## which one it was ("" if none). {} if there was nothing to read.
static func read_json(path: String) -> Array:
	var main_bad := false
	for suffix in ["", TMP, BAK]:
		var p: String = path + suffix
		if not FileAccess.file_exists(p):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
		if parsed is Dictionary:
			if main_bad:
				push_warning("SafeFile: %s was unreadable, recovered from %s" % [path, p])
			return [parsed, suffix]
		if suffix == "":
			main_bad = true
			# Keep it for a bug report; the next save would overwrite it.
			if FileAccess.file_exists(path + CORRUPT):
				DirAccess.remove_absolute(path + CORRUPT)
			DirAccess.copy_absolute(path, path + CORRUPT)
	if main_bad:
		push_warning("SafeFile: %s and its backups are unreadable, starting fresh (kept as %s)" % [path, path + CORRUPT])
	return [{}, ""]


## Removes the temp and backup copies (after a deliberate reset).
static func remove_copies(path: String) -> void:
	for suffix in [TMP, BAK]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
