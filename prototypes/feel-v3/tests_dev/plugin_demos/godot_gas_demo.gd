extends Node
## Demo: run GodotGAS's own test suite (tags, attributes, cues, effects, abilities, full system).
func _ready() -> void:
	var tester: Node = load("res://addons/GodotGAS/utilities/testing/master_gas_tester.gd").new()
	add_child(tester)
	await get_tree().create_timer(8.0).timeout
	print("GODOT_GAS_DEMO done")
	get_tree().quit()
