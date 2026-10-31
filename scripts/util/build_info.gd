class_name BuildInfo
## Which build this is, so a playtest note or a bug report can name the
## commit (docs/prompts/NEXT_PASS_2026-10-29.md §4). CI writes
## res://build_info.json before exporting ({"commit": "abc1234", "date":
## "2026-10-29"}); a local or editor run has no file and reads "dev".

const PATH := "res://build_info.json"

static var _cached := {}


static func info() -> Dictionary:
	if _cached.is_empty():
		_cached = {"commit": "dev", "date": ""}
		if FileAccess.file_exists(PATH):
			var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
			if data is Dictionary and str(data.get("commit", "")) != "":
				_cached = {"commit": str(data.commit).left(12), "date": str(data.get("date", ""))}
	return _cached


## "build abc1234 · 2026-10-29", or "build dev".
static func stamp() -> String:
	var i := info()
	return "build %s%s" % [i.commit, "  ·  " + i.date if i.date != "" else ""]


## Tests: forget the cached read.
static func reset() -> void:
	_cached = {}
