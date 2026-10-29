class_name WellRim
extends Node2D
## The well's rim, on the north side: where Rue listens (and, once she
## knows who is asking, answers). The way down is the Passage on the south
## side. WellSequence holds the rules; the square runs them.

signal listened(rim: WellRim)

## Set by the square: what pressing here does now.
var prompt := "listen"


func can_interact() -> bool:
	return true


func interact_prompt() -> String:
	return prompt


## What this is, shown small over the prompt (World.object_name).
func interact_name() -> String:
	return "the well's rim"


func interact() -> String:
	listened.emit(self)
	return ""
