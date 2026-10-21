# Live portrait assets

Dialogue and cinematics both use `PortraitView`, which resolves a `PortraitAsset`
once per identity/expression/palette change. With no matching approved resource,
the shared `IllustratedCharacter` remains the fallback. No new character art or
licensed performances are delivered merely by adding this route.

Place a resource at `res://art/characters/<who>/<who>_<expression>.tres`.
It must use `portrait_asset.gd` and declare `who`, `expression`, positive `version`,
nonempty `provenance` and `rights`, the exact current palette, and a square
64–2048 px `still` texture. Optional `talk` and `blink` textures must have the
same dimensions. Use transparent RGBA art. The normalised square `crop` is
shared across frames; align face/shoulders consistently across expressions.
Missing animation frames hold the still image rather than switching art styles.

Identities: rue, arin, mira, wren, tobben, archivist. Pip has no human portrait.
Palette matching is exact and covers every supplied key: incomplete Rue,
borrowed coat/scarf, frayed ribbon or colour and alternate NPC palettes cannot
silently acquire a fully restored portrait. Provide an approved variant or keep
the procedural fallback. The current file convention provides one palette per
identity/expression resource; a future multi-variant catalogue is separate work.

`PortraitResolver.register` supports authored in-code sets and test fixtures.
Tests use disposable synthetic textures, never production acting/art evidence.
Malformed metadata, missing textures, incompatible frames, identity mismatch or
invalid crop are rejected. Missing resources are cached, not polled per frame.
Corrupt engine resource files may still report a loader diagnostic and fall back;
do not suppress that diagnostic. Legacy CharacterArt PNG/raster helpers remain
available for old tools but no longer promise to change the live UI by themselves.
