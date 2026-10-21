class_name PortraitResolver
extends RefCounted
## Resolved only when identity/expression/palette changes, never during draw.
const DIR := "res://art/characters/"
static var _registered: Dictionary = {}
static var _cache: Dictionary = {}

static func register(asset: PortraitAsset) -> void:
	_registered["%s/%s" % [asset.who, asset.expression]] = asset

static func clear_registered() -> void:
	_registered.clear()
	_cache.clear()

static func resolve(p: CharacterArt.Portrait) -> PortraitAsset:
	if p == null or not CharacterArt.has_portrait(p.who):
		return null
	var key := "%s/%s" % [p.who, p.expression]
	var asset: PortraitAsset = _registered.get(key)
	if asset == null:
		if not _cache.has(key):
			var path := "%s%s/%s_%s.tres" % [DIR, p.who, p.who, p.expression]
			_cache[key] = ResourceLoader.load(path) as PortraitAsset if ResourceLoader.exists(path) else null
		asset = _cache[key]
	return asset if asset and asset.matches(p) else null
