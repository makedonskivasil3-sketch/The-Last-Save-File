class_name ActionPreview
extends RefCounted
## What holding [E] on a target will do, said before the hold and checked
## again when it completes, from one place (docs/GAMEPLAY_CONSISTENCY.md):
## the prompt, the touch button, the charge and the commit all read this.
##
## A glitch costs awareness and can trigger the owner's reload; leaving a
## body costs nobody's awareness, cools the owner, never reloads, and takes a
## piece of the person beside her for good (until it's given back).


## {id, title, hold, cost, relief, reloads, consequence, available, reason}
static func describe(t: Dictionary, world: Node) -> Dictionary:
	if t.is_empty():
		return {}
	var id: String = t.id
	var out := {
		"id": id, "title": "", "hold": Glitch.hold_time(id), "cost": 0.0, "relief": 0.0,
		"reloads": false, "consequence": "", "available": true, "reason": "",
	}
	if id == "shed":
		var node: Variant = t.get("node")
		out.title = Glitch.SHED.name
		out.relief = Story.SHED_COOL
		if node is Npc:
			out.consequence = "takes %s's %s" % [_name(node), Story.SHED_PIECE.get(node.npc_id, "piece")]
			out.available = world.can_shed(node)
		else:
			out.available = false
		if not out.available:
			out.reason = "not here, not now"
		return out
	out.title = str(Glitch.DEFS[id].name)
	out.cost = Glitch.cost(id)
	out.reloads = world.owner_moves.next_glitch_reloads()
	return out


## The line under the target: "hold [E]  FREEZE +6  ·  RELOADS".
static func prompt(p: Dictionary, glyph: String) -> String:
	if p.is_empty():
		return ""
	var text := "hold [%s]  %s" % [glyph, short(p)]
	if p.consequence != "":
		text += "  ·  " + str(p.consequence)
	if p.reloads:
		text += "  ·  RELOADS"  # the owner said so; the prompt keeps saying so
	return text


## The name with its price, for small spaces (the touch button).
static func short(p: Dictionary) -> String:
	if p.is_empty():
		return ""
	if p.cost > 0.0:
		return "%s +%d" % [p.title, int(p.cost)]
	return str(p.title)


static func _name(npc: Npc) -> String:
	var n := npc.display_name.capitalize()
	return n if n != "" else npc.npc_id.capitalize()
