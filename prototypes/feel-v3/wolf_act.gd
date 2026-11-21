# PROTOTYPE - NOT FOR PRODUCTION
# One step of THE UNMUZZLED's behaviour tree (LimboAI). The tree (built in
# werewolf.gd) decides the ORDER of his moves; each step asks the werewolf to
# do one move until it is finished. Needs the LimboAI addon (addons/limboai).
extends BTAction

## the move this step runs: stalk, leap, cling, bounce_turn, ricochet, pounce, land_stun, skip
@export var move: StringName = &"skip"


func _generate_name() -> String:
	return "Wolf: %s" % move


func _enter() -> void:
	agent.bt_enter(move)


func _tick(delta: float) -> Status:
	var r: int = agent.bt_tick(move, delta)
	if r == 1:
		return SUCCESS
	if r == -1:
		return FAILURE
	return RUNNING
