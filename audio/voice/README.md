Recorded or generated voice lines go here, named by stable dialogue id:
`<id>.ogg` (see manifest.csv for every id, its exact subtitle and direction).

A missing file is normal: that line keeps its text and procedural voice and
never blocks progression. Production spec, loudness and licensing:
docs/ASSET_PRODUCTION.md. Character voices: docs/VOICE_BIBLE.md.

Regenerate the manifest after changing story text:
    godot --headless --path . -s res://tools/voice_manifest.gd
