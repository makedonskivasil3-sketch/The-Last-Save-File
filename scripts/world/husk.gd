class_name Husk
extends Readable
## The body Rue stepped out of (docs/DARK_TRUTH_DESIGN.md, layer B): her
## shape, emptied, left where she stood. Readable, like a file.


func _init() -> void:
	title = Story.HUSK_TITLE
	prompt = "look"
	look = Look.SIGN  # not kept in the journal: it's a body, not a page
	lines_provider = func() -> Array: return Story.HUSK_LINES.duplicate()


## The body itself: Rue's own figure, emptied of colour, lying on its side
## with its eyes closed (docs/DARK_TRUTH_DESIGN.md, layer B).
var _body := IllustratedCharacter.new("rue", Player.RUE)


func _draw() -> void:
	_body.expression = "relieved"  # lids down: it isn't looking at anything
	_body._blink = 1.0
	var breath := 0.42 + 0.06 * sin(_t * 1.2)  # not breathing: a slow flicker of the save
	_body.draw(self, {"offset": Vector2(-1, -2), "rotation": -PI * 0.5, "grey": true, "alpha": breath})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
