class_name TimedGlitch
extends RefCounted
## A brief visual glitch that starts at random and lasts a set time, both in
## seconds, so how often it happens and how long it shows don't depend on
## the frame rate (docs/PRESENTATION_FUNCTIONALITY_AUDIT.md, A09). Purely
## visual: nothing here changes what the owner does or how dangerous it is.

## How long each event shows, in seconds.
var hold := 1.0 / 30.0
var _left := 0.0


func _init(hold_seconds := 1.0 / 30.0) -> void:
	hold = hold_seconds


## Advance by `delta`; `rate` is the average events per second right now.
## Returns true while an event is showing (and true on the frame one starts).
func update(delta: float, rate: float) -> bool:
	if _left > 0.0:
		_left -= delta
		if _left > 0.0001:
			return true
		_left = 0.0
	if rate > 0.0 and randf() < 1.0 - exp(-rate * delta):
		_left = hold
		return true
	return false


func active() -> bool:
	return _left > 0.0
