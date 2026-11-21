extends Node2D
## Demo: a LimboAI behaviour tree built in code: wait, then set a blackboard var.
## Real use: build the tree in the LimboAI editor (BehaviorTree .tres) and assign it to a BTPlayer.
func _ready() -> void:
	var bt: BehaviorTree = BehaviorTree.new()
	var seq: BTSequence = BTSequence.new()
	var wait: BTWait = BTWait.new()
	wait.duration = 0.1
	var set_var: BTSetVar = BTSetVar.new()
	set_var.variable = &"phase"
	var val: BBVariant = BBVariant.new()
	val.type = TYPE_STRING
	val.saved_value = "lunge"
	set_var.value = val
	seq.add_child(wait)
	seq.add_child(set_var)
	bt.root_task = seq
	var player: BTPlayer = BTPlayer.new()
	add_child(player)
	player.owner = self
	player.behavior_tree = bt
	await get_tree().create_timer(0.5).timeout
	var phase: Variant = player.blackboard.get_var(&"phase", "none")
	print("LIMBOAI_DEMO phase=%s pass=%s" % [str(phase), str(phase == "lunge")])
	get_tree().quit()
