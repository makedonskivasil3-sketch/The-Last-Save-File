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


## Writes `text` to `path` as one transaction: true only when the new file
## is in place, read back intact. On false nothing the player had is lost:
## the previous save and its backup are exactly as they were, and
## last_error says why (no paths: those go to the log, for support).
static func write_atomic(path: String, text: String) -> bool:
	last_error = ""
	var tmp := path + TMP
	var f: FileAccess = null if fail_at == "open" else FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return _fail("couldn't create the save file", "open %s: %s" % [tmp, error_string(FileAccess.get_open_error())])
	f.store_string(text)
	f.close()
	# Read it back: a full disk or a failed write must not replace a good save.
	if fail_at == "readback" or FileAccess.get_file_as_string(tmp) != text:
		DirAccess.remove_absolute(tmp)
		return _fail("the save didn't read back intact", "readback %s" % tmp)
	var had_main := FileAccess.file_exists(path)
	var had_bak := FileAccess.file_exists(path + BAK)
	if had_main:
		# Keep the old backup aside until the new save is in place.
		if had_bak and _rename(path + BAK, path + BAK + OLD, "park") != OK:
			DirAccess.remove_absolute(tmp)
			return _fail("couldn't rotate the backup", "park %s" % (path + BAK))
		if _rename(path, path + BAK, "backup") != OK:
			if had_bak:
				DirAccess.rename_absolute(path + BAK + OLD, path + BAK)
			DirAccess.remove_absolute(tmp)
			return _fail("couldn't back up the last save", "backup %s" % path)
	if _rename(tmp, path, "rename") != OK:
		# Put everything back as it was.
		if had_main:
			DirAccess.rename_absolute(path + BAK, path)
			if had_bak:
				DirAccess.rename_absolute(path + BAK + OLD, path + BAK)
		DirAccess.remove_absolute(tmp)
		return _fail("couldn't put the new save in place", "rename %s" % tmp)
	if had_bak:
		DirAccess.remove_absolute(path + BAK + OLD)
	return true


## Tests only: make one step of write_atomic fail ("open", "readback",
## "park", "backup", "rename"), as a full or read-only disk would.
static var fail_at := ""
## Why the last write_atomic failed, in words a player can read ("" if it didn't).
static var last_error := ""
## Recent failures with their detail (paths, engine errors), for support.
static var support_log: Array[String] = []
const OLD := ".old"


static func _rename(from: String, to: String, step: String) -> Error:
	if fail_at == step:
		return ERR_CANT_CREATE
	return DirAccess.rename_absolute(from, to)


static func _fail(reason: String, detail: String) -> bool:
	last_error = reason
	var line := "%s  SafeFile: %s (%s)" % [Time.get_datetime_string_from_system(), reason, detail]
	support_log.append(line)
	if support_log.size() > 20:
		support_log.pop_front()
	push_warning(line)  # into the engine log file too (user://logs on desktop)
	return false


## The first of path, path.tmp, path.bak that parses as a JSON object, and
## which one it was ("" if none). {} if there was nothing to read.
static func read_json(path: String) -> Array:
	var main_bad := false
	for suffix in ["", TMP, BAK, BAK + OLD]:
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
	for suffix in [TMP, BAK, BAK + OLD]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
