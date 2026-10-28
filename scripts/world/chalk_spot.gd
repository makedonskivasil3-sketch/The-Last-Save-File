class_name ChalkSpot
extends Node2D
## A place Rue can chalk a mark during Wren's game (docs/production/WREN_ARC.md):
## the square decides when it is offered and what the mark means.

signal chalked(spot: ChalkSpot)

## "recess" (under the awning), "crossing" (open, in the lamp's sweep).
var id := ""
var active := false


func can_interact() -> bool:
	return active


func interact_prompt() -> String:
	return "chalk a mark"


## What this is, shown small over the prompt (World.object_name).
func interact_name() -> String:
	return {"recess": "under the awning", "crossing": "out on the crossing"}.get(id, "")


func interact() -> String:
	chalked.emit(self)
	return ""
