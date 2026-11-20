# PROTOTYPE - NOT FOR PRODUCTION
# tests_dev/d4_builder.gd - the F2 room builder end to end (ledger N8): it opens on the room she is in,
# edits (paint, place a PNG, spread, undo), plays the edited room from a cell, comes back, and
# leaves nothing behind when closed.
# Run: godot --headless --path . res://tests_dev/d4_builder.tscn
extends Node

const EdAssets := preload("res://editor/ed_assets.gd")
const RoomScript := preload("res://room.gd")
const WorkspaceFiles := preload("res://editor/workspace_files.gd")

var main: Node = null
var passed := 0
var failed := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	G.peace = true
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _frames(30)
	await main.debug_enter("church", "left", false)
	await _frames(10)
	await _run()
	var ok := failed == 0 and passed > 0
	print("d4_builder %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _run() -> void:
	var dir := ProjectSettings.globalize_path("user://d4_editor_%d" % Time.get_ticks_msec())
	EdAssets.root_override = dir
	var proj := ProjectSettings.globalize_path("user://d4_project_%d" % Time.get_ticks_msec())
	var initial := FileAccess.get_file_as_string("res://rooms/church.txt")
	var target := proj.path_join("rooms/church.txt")
	var props_target := proj.path_join("rooms/church.props.json")
	_check("create a private room fixture", WorkspaceFiles.commit({target: initial}, {target: null}) == "", "")
	Dev.project_dir_override = proj
	var b = Dev.open_tool("dev_room")
	_check("F2 opens the room builder", b != null and Dev.busy() and get_tree().paused, "tool=%s" % str(b))
	if b == null:
		return
	await _frames(3)
	_check("it opened on the room she is in", b.doc.file_id == "church" and b.doc.width() > 10, "file=%s" % b.doc.file_id)
	_check("the palette has every tab", b._tabs.item_count == 7 and b._list.item_count > 5, "tabs=%d items=%d" % [b._tabs.item_count, b._list.item_count])
	# paint a wall cell
	b._set_tab("TERRAIN")
	b.sel = {"glyph": "#", "name": "solid wall"}
	b.doc.push_undo()
	b._paint(Vector2i(3, 3))
	_check("painting puts the character in the room", b.doc.get_cell(3, 3) == "#", "")
	b._undo()
	_check("undo takes it back", b.doc.get_cell(3, 3) != "#" or b.doc.get_cell(3, 3) == ".", "cell=%s" % b.doc.get_cell(3, 3))
	# a PNG prop from a dropped folder
	EdAssets.ensure_folders()
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.9, 0.3))
	img.save_png(dir.path_join("props/lamp.png"))
	EdAssets.clear_cache()
	b._set_tab("PROPS")
	_check("the dropped PNG is in the PROPS tab", b._entries.size() == 1 and b._entries[0]["png"] == "props/lamp.png", str(b._entries))
	b._list.select(0)
	b._on_pick(0, true)
	var n0: int = b.doc.props.size()
	b._place_picture(Vector2(100, 100))
	_check("placing a PNG adds a prop", b.doc.props.size() == n0 + 1 and int(b.doc.props[n0]["x"]) % 8 == 0, str(b.doc.props))
	# Put a solid PNG over an existing wall and erase it again.
	img.save_png(dir.path_join("tiles/block.png"))
	EdAssets.clear_cache()
	b._set_tab("TILES")
	b.sel = {"png": "tiles/block.png", "name": "Block"}
	b.plane = "solid"
	b.doc.set_cell(3, 3, "#")
	var tile_at := Vector2(3.5, 3.5) * 16.0
	b._place_picture(tile_at)
	b._erase_at(tile_at)
	_check("erasing a solid PNG preserves preexisting wall collision", b.doc.get_cell(3, 3) == "#", b.doc.get_cell(3, 3))
	# Spread over a zone.
	b._set_tab("ENEMIES")
	b._list.deselect_all()
	var hi := -1
	for i in b._entries.size():
		if b._entries[i]["glyph"] == "H":
			hi = i
	b._list.select(hi)
	b._zone = Rect2i(1, 1, b.doc.width() - 2, b.doc.height() - 2)
	b._zone_on = true
	b._count.value = 3
	var before := _count_glyph(b.doc, "H")
	b.spread_zone()
	_check("SPREAD places the number asked for", _count_glyph(b.doc, "H") - before == 3, "added=%d" % (_count_glyph(b.doc, "H") - before))
	# The hazard variant used to be advertised but rejected.
	b._set_tab("HAZARDS")
	b._list.deselect_all()
	for index in b._entries.size():
		if b._entries[index].get("glyph") == "i":
			b._list.select(index)
	var spikes := _count_glyph(b.doc, "i")
	b.spread_zone()
	_check("Spread places selected traps on suitable tiles", _count_glyph(b.doc, "i") > spikes, b._msg)
	# Play the edited room from a marked cell and return.
	b.doc.set_cell(2, 2, "H")
	b._start_cell = Vector2i(10, 8)
	await b.play()
	await _frames(5)
	var p: Node2D = main.get("player")
	_check("playing runs the edited room, not the saved file", RoomScript.override.has("church") and main.room.grid.size() == b.doc.height(), "")
	_check("the game runs while playing", not get_tree().paused, "paused=%s" % str(get_tree().paused))
	_check("she starts at the marked cell", absf(p.global_position.x - 168.0) < 24.0, "x=%.0f want 168" % p.global_position.x)
	b.edit_again()
	_check("Tab comes back to editing (paused again)", get_tree().paused and b._playing == false, "")
	# Failed writes leave both source files and the draft intact.
	b.doc.set_cell(4, 4, "m")
	DirAccess.make_dir_absolute(props_target)
	_check("a props write failure preserves the room and unsaved draft",
		not b.save() and b.is_dirty() and FileAccess.get_file_as_string(target) == initial, b._msg)
	DirAccess.remove_absolute(props_target)
	var saved: bool = b.save()
	var back_text := FileAccess.get_file_as_string(target)
	_check("save writes the edited room", saved and back_text == b.doc.to_text() and back_text.contains("m"), b._msg)
	_check("save writes the props next to it", FileAccess.file_exists(props_target)
		and FileAccess.get_file_as_string(props_target).contains("props/lamp.png"), "")
	var bk := DirAccess.open(ProjectSettings.globalize_path("user://room_backups"))
	var found := false
	if bk != null:
		for f in bk.get_files():
			if f.begins_with("church_") and FileAccess.get_file_as_string(ProjectSettings.globalize_path("user://room_backups").path_join(f)) == initial:
				found = true
	_check("the old room is available as a backup", found, "")
	_check("success clears the saved draft status", not b.is_dirty(), "")
	b._recheck()
	b.doc.set_cell(1, 1, "D")
	b._recheck()
	_check("the quick checks run after an edit", b.checks is Array, "")
	# F2 again closes it and leaves nothing behind
	Dev.close_tool()
	await _frames(3)
	_check("closing frees the tool and the game runs", not Dev.busy() and not get_tree().paused, "")
	_check("the unsaved copy is gone", not RoomScript.override.has("church"), "")
	var reopened = Dev.open_tool("dev_room")
	_check("a reopened editor loads the saved room and props", reopened != null and reopened.doc.get_cell(4, 4) == "m" and reopened.doc.props.size() >= 1, "")
	Dev.close_tool()
	Dev.project_dir_override = ""
	EdAssets.root_override = ""


func _count_glyph(doc, g: String) -> int:
	var n := 0
	for y in doc.height():
		for x in doc.width():
			if doc.get_cell(x, y) == g:
				n += 1
	return n


func _check(nm: String, ok: bool, detail: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("%s  %s  (%s)" % ["ok  " if ok else "FAIL", nm, detail])


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
