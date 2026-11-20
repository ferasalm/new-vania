# PROTOTYPE - NOT FOR PRODUCTION
extends Node

var passed := 0
var failed := 0


func _ready() -> void:
	G.peace = true
	var main: Node = load("res://main.tscn").instantiate()
	add_child.call_deferred(main)
	for i in 30:
		await get_tree().physics_frame
	var menu = main.menu
	W.visited = {W.sheet: {"church": true}}
	menu.open("MAP")
	var map_view = menu.get_node("map_view")
	var cell: Array = W.meta("church")["cell"]
	var expected := Rect2i(int(cell[0]), int(cell[1]), int(cell[2]), int(cell[3]))
	_check(map_view.cell_rect("church") == expected, "visited room uses its metadata rectangle")
	_check(not map_view.cell_rect("gallery").has_area(), "unvisited room is hidden by default")
	await _capture("pause-map")
	if OS.is_debug_build():
		menu.debug_tap(menu.debug_rows().size() - 1)
		_check(map_view.cell_rect("gallery").has_area(), "dev map reveals unvisited rooms")
		var rooms: Array = W.room_list(W.sheet)
		menu.debug_tap(rooms.find("gallery"))
		_check(not menu.is_open and main.room_name == "gallery", "dev teleport closes pause and enters the room")
	menu.close()
	await get_tree().physics_frame
	R.debug_set({"owned_gear": ["pall_090", "governor_207"]})
	menu.open("EQUIPMENT")
	menu.debug_press("down")
	menu.debug_press("down")
	_check(menu._gear_list.get_child_count() == 3, "torso choices show empty and the owned harness")
	await _capture("pause-equipment")
	menu._gear_list.get_child(2).pressed.emit()
	_check(R.equip["harness1"] == "pall_090", "clicking the side list fits the selected gear")
	menu.debug_press("down")
	_check(menu._gear_list.get_child_count() == 2, "a harness already fitted elsewhere cannot be selected twice")
	menu.close()
	print("pause_tabs %s %d/%d" % ["PASS" if failed == 0 else "FAIL", passed, passed + failed])
	get_tree().quit(0 if failed == 0 else 1)


func _capture(filename: String) -> void:
	if not OS.get_cmdline_user_args().has("shots") or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://.godot/%s.png" % filename)
	_check(get_viewport().get_texture().get_image().save_png(path) == OK, "saved " + filename)


func _check(ok: bool, description: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("%s  %s" % ["ok" if ok else "FAIL", description])
