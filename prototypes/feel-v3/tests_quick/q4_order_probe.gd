# PROTOTYPE - NOT FOR PRODUCTION
# Q4 probe: answers two questions the menu_swallow hook depends on.
# 1. Where do the menu and the world sit under main (tree order)?
# 2. If this node presses "attack" at the physics_frame signal and the menu
#    releases it in its own _physics_process, does the hero still read it?
extends Node

var main: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	G.peace = true
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _frames(30)
	print("children of main in order:")
	for c in main.get_children():
		print("  %d %s" % [c.get_index(), c.name])
	var p = main.player
	p.set("energy", 100.0)
	main.menu.open("CHARACTER")
	await _pframes(4)
	main.menu.close()
	await _pframes(2)
	p.set("energy", 100.0)
	Input.action_press("attack")
	await _frames(2)
	Input.action_release("attack")
	print("energy after one attack press inside the hold: %s (100 = the hook let it go, 88 = she read it)" % str(p.get("energy")))
	print("just_pressed now: %s" % str(Input.is_action_just_pressed("attack")))
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _pframes(n: int) -> void:
	for i in n:
		await get_tree().create_timer(1.0 / 60.0).timeout
