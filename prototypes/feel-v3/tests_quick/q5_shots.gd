# PROTOTYPE - NOT FOR PRODUCTION
# Q5 helper: takes a calm screenshot of the backdrop wall in a few rooms, so
# the backdrop fix can be checked by eye (before vs after). Pictures go to
# shots/q5_after_<room>.png. The wide and tall rooms also get a copy under the
# shape name they had before the fix (q5_after_wide_church and so on), so every
# old picture has a matching new one. Run windowed (NOT headless):
#   & "<godot>" --path . res://tests_quick/q5_shots.tscn
extends Node

const ROOMS := ["church", "library", "shaft", "lab", "hazard"]
const SHAPE := {"church": "wide_church", "lab": "wide_lab",
	"library": "tall_library", "shaft": "tall_shaft"}

var main: Node


func _ready() -> void:
	G.peace = true
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _run()
	print("Q5 SHOTS DONE")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	for room_name in ROOMS:
		if not main.has_method("debug_enter"):
			return
		await main.debug_enter(room_name, "left", false)
		await _frames(45)
		await _shot("shots/q5_after_%s.png" % room_name)
		if SHAPE.has(room_name):
			await _shot("shots/q5_after_%s.png" % SHAPE[room_name])


func _shot(path: String) -> void:
	# park the player halfway into the room so the camera rests on the wall
	var p: CharacterBody2D = main.player
	if p != null:
		p.global_position = Vector2(main.room.size.x * 0.5, main.room.size.y - 40.0)
		p.velocity = Vector2.ZERO
	await _frames(30)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(
		ProjectSettings.globalize_path(path))
