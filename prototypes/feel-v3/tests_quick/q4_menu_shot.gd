# PROTOTYPE - NOT FOR PRODUCTION
# Q4 proof shot: opens the pause menu on one tab and saves the picture, so the
# menu can be checked at two window sizes (1280x720 and a phone's 2400x1080).
#   godot --path . res://tests_quick/q4_menu_shot.tscn --resolution 1280x720 -- shot=q4_menu_1280 tab=ITEMS
#   godot --path . res://tests_quick/q4_menu_shot.tscn -- shot=q4_menu_2400 win=2400x1080 tab=EQUIPMENT
# win= asks for a borderless window that big (a desktop smaller than it still
# renders the whole picture; only the on-screen part is clipped, not the file).
# It also prints the rows of the tab, as the locked test's debug_rows sees them.
extends Node

var main: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shot := "q4_menu_1280"
	var tab := "ITEMS"
	var win := Vector2i.ZERO
	for a in OS.get_cmdline_user_args():
		if a.begins_with("shot="):
			shot = a.substr(5)
		elif a.begins_with("tab="):
			tab = a.substr(4)
		elif a.begins_with("win="):
			var parts: PackedStringArray = a.substr(4).split("x")
			if parts.size() == 2:
				win = Vector2i(int(parts[0]), int(parts[1]))
	if win.x > 0:
		get_window().borderless = true
		get_window().size = win
		get_window().position = Vector2i(0, 0)
	G.peace = true
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _frames(40)
	# a little carry and gear so the screens show real rows
	R.add_item("suture", 2)
	R.debug_set({"owned_gear": ["cerement_112", "pall_090", "coupler_034", "governor_207"]})
	R.equip_gear("harness1", "cerement_112")
	R.equip_gear("module1", "coupler_034")
	if tab == "OVERLAY":
		# the old one-sheet pause surface (the fallback), for the cropping proof
		main.touch._pause()
		await _frames(8)
		var worst := 0.0
		var count := 0
		for b in _all_buttons(main.touch._overlay):
			count += 1
			worst = maxf(worst, b.get_global_rect().end.y)
		print("overlay: %d buttons, lowest ends at y=%.0f of 216" % [count, worst])
	else:
		main.menu.open(tab)
		await _frames(8)
		print("menu tab %s rows: %s" % [tab, ", ".join(main.menu.debug_rows())])
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/%s.png" % shot))
	print("saved shots/%s.png  window=%s menu_open=%s paused=%s" % [shot, str(get_window().size),
		str(main.menu.is_open), str(get_tree().paused)])
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _all_buttons(root: Node) -> Array:
	var out: Array = []
	for c in root.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_all_buttons(c))
	return out
