extends "res://tests/test_case.gd"
## The bundled fonts cover every character the game's text uses
## (assets/fonts/README.md), and they're the ones actually in use.


func _game_text() -> String:
	var out := ""
	for dir in ["res://scripts"]:
		out += _read_dir(dir)
	return out


func _read_dir(path: String) -> String:
	var out := ""
	var d := DirAccess.open(path)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out += FileAccess.get_file_as_string(path + "/" + f)
	for sub in d.get_directories():
		out += _read_dir(path + "/" + sub)
	return out


func test_every_character_has_a_glyph() -> void:
	var body := UiStyle.body_font()
	var mono := UiStyle.system_font()
	var missing := {}
	for c in _game_text():
		var code := c.unicode_at(0)
		if code < 32 or code == 0x09:
			continue
		var ok := body.has_char(code)
		for fb in (body as FontFile).fallbacks:
			ok = ok or fb.has_char(code)
		if not ok:
			missing[c] = true
		if code > 126 and not mono.has_char(code) and not body.has_char(code):
			missing[c] = true
	check(missing.is_empty(), "no missing glyphs (%s)" % ", ".join(missing.keys()))


func test_the_bundled_fonts_are_in_use() -> void:
	check_eq(ThemeDB.fallback_font, UiStyle.body_font(), "Inter is the default font")
	var t := UiStyle.make_theme()
	check_eq(t.default_font, UiStyle.body_font(), "and the menus' font")
	check(UiStyle.system_font() != UiStyle.body_font(), "the owner's system text has its own face")
