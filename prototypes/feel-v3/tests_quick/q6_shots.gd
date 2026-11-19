# PROTOTYPE - NOT FOR PRODUCTION
# Q6 helper: takes screenshots of the library and the lab so the room easing can
# be checked by eye (before vs after). Pictures go to shots/q6_<tag>_<room>_<spot>.png.
# Run windowed (NOT headless):
#   & "<godot>" --path . res://tests_quick/q6_shots.tscn ++ library before
#   & "<godot>" --path . res://tests_quick/q6_shots.tscn ++ lab after
# Args after ++: room name, tag (before/after), optional "shift" for the shift world.
extends Node

# where to park her in each room: [x, y] a little above the floor she should land on
const SPOTS := {
	"library": {
		"top": Vector2(360, 60),   # the top platform with the item
		"mid": Vector2(376, 190),  # the middle corridor
		"low": Vector2(120, 640),  # the bottom floor
	},
	"lab": {
		"top": Vector2(280, 56),   # the item ledge in the upper hall
		"mid": Vector2(330, 180),  # the upper floor by the ladder
		"low": Vector2(120, 400),  # the lower hall by the side ledges
	},
}

var main: Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var room_name: String = args[0] if args.size() > 0 else "library"
	var tag: String = args[1] if args.size() > 1 else "before"
	var shifted: bool = args.size() > 2 and args[2] == "shift"
	G.peace = true
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _run(room_name, tag, shifted)
	print("Q6 SHOTS DONE ", tag, " ", room_name)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _run(room_name: String, tag: String, shifted: bool) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	if not main.has_method("debug_enter"):
		return
	var spots: Dictionary = SPOTS.get(room_name, {})
	await main.debug_enter(room_name, "left", shifted)
	await _frames(20)
	for spot_name in spots:
		var p: CharacterBody2D = main.player
		if p == null:
			return
		p.global_position = spots[spot_name]
		p.velocity = Vector2.ZERO
		await _frames(40)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(
			ProjectSettings.globalize_path("res://shots/q6_%s_%s_%s.png" % [tag, room_name, spot_name]))
