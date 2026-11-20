# PROTOTYPE - NOT FOR PRODUCTION
# tests_dev/d6_map.gd - the F3 map builder (ledger N8): rooms as boxes, move and resize, red overlaps,
# a save that only touches the changed rooms' "cell" numbers, open in F2, jump into a room.
# Run: godot --headless --path . res://tests_dev/d6_map.tscn
extends Node

const MetaPatch := preload("res://editor/meta_patch.gd")

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
	print("d6_map %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _run() -> void:
	# a private copy of the project folder's data, so the real file is never touched
	var dir := ProjectSettings.globalize_path("user://d6_proj_%d" % Time.get_ticks_msec())
	DirAccess.make_dir_recursive_absolute(dir.path_join("data"))
	var src := FileAccess.get_file_as_string("res://data/rooms_meta.json")
	var f := FileAccess.open(dir.path_join("data/rooms_meta.json"), FileAccess.WRITE)
	f.store_string(src)
	f.close()
	Dev.project_dir_override = dir
	W.sheet = "before"

	var m = Dev.open_tool("dev_map")
	_check("F3 opens the map builder and pauses the game", m != null and Dev.busy() and get_tree().paused, "tool=%s" % str(m))
	if m == null:
		return
	await _frames(3)
	_check("it shows the 15 rooms of the BEFORE page", m._rooms().size() == 15 and m.sheet == "before", "n=%d sheet=%s" % [m._rooms().size(), m.sheet])
	m.set_sheet("after")
	var n_after: int = m._rooms().size()
	m.set_sheet("restored")
	var n_rest: int = m._rooms().size()
	_check("AFTER and RESTORED pages load", n_after == 11 and m._rooms().has("arnetria") and n_rest >= 15, "after=%d restored=%d" % [n_after, n_rest])
	m.set_sheet("before")
	print("  (info) red marks on the real BEFORE map: ", m.warnings.size(), " ", m.warnings.map(func(w): return w["text"]))

	# move one room, save, and see that only its cell numbers changed in the text
	m.select("church")
	var c0: Array = (m._rooms()["church"]["cell"] as Array).duplicate()
	_check("a room can be picked", m.picked == "church", "")
	var moved: bool = m.nudge(1, 0)
	var c1: Array = m._rooms()["church"]["cell"]
	_check("nudge moves it one map cell", moved and c1[0] == c0[0] + 1 and c1[1] == c0[1] and m.is_dirty(), "c=%s" % str(c1))
	m.undo()
	_check("undo puts it back", m._rooms()["church"]["cell"] == c0 and not m.is_dirty(), "")
	m.nudge(1, 0)
	m.resize_by(1, 0)
	m.resize_by(-9, -9)
	_check("a room never gets smaller than 1x1", m._rooms()["church"]["cell"][2] == 1 and m._rooms()["church"]["cell"][3] == 1, str(m._rooms()["church"]["cell"]))
	m.undo()
	var want: Array = m._rooms()["church"]["cell"].duplicate()
	_check("save works", m.save() and not m.is_dirty(), "")
	var out := FileAccess.get_file_as_string(dir.path_join("data/rooms_meta.json"))
	var a := src.split("\n")
	var b := out.split("\n")
	var diff := 0
	for i in mini(a.size(), b.size()):
		if a[i] != b[i]:
			diff += 1
	_check("only ONE line of the file changed", a.size() == b.size() and diff == 1, "lines %d/%d diff=%d" % [a.size(), b.size(), diff])
	var parsed: Dictionary = JSON.parse_string(out)
	var pc: Array = parsed["sheets"]["before"]["church"]["cell"]
	_check("the saved file is the edited map", int(pc[0]) == int(want[0]) and int(pc[1]) == int(want[1]) and int(pc[2]) == int(want[2]) and int(pc[3]) == int(want[3]), str(pc))
	_check("the running game's table follows", int(Db.table("rooms_meta")["sheets"]["before"]["church"]["cell"][2]) == int(want[2]), "")
	_check("the patch helper says no for an unknown room", MetaPatch.set_cell(src, "before", "nonesuch", [1, 1, 1, 1]) == "", "")

	# overlap goes red
	var reds0: int = m.warnings.size()
	var lib: Array = m._rooms()["library"]["cell"]
	var scr: Array = m._rooms()["scriptorium"]["cell"]
	m.select("scriptorium")
	m.nudge(int(lib[0]) - int(scr[0]), int(lib[1]) - int(scr[1]))
	var over := false
	for w in m.warnings:
		if String(w["text"]).contains("scriptorium overlaps library"):
			over = true
	_check("two rooms on top of each other are red", over, "")
	m.undo()
	_check("and undo clears the red", m.warnings.size() == reds0, "%d vs %d" % [m.warnings.size(), reds0])

	# a room of the base page cannot be moved from RESTORED
	m.set_sheet("restored")
	m.select("church")
	_check("RESTORED does not edit base rooms", not m.nudge(1, 0), "")
	m.select("arnetria")
	_check("but the rooms it adds can be moved", m.nudge(0, 1) and m.is_dirty(), "")
	m.undo()

	# Stacked rooms remain individually selectable.
	m.set_sheet("before")
	var hits: Array = m._rooms_at(m._to_screen(m._rect("scriptorium").get_center()))
	_check("every room in the stack is a choice", hits.size() == 4 and hits.has("loft") and hits.has("scriptorium"), str(hits))
	m._search.text = "scriptorium"
	m._refresh_rooms()
	_check("search can find a covered room", m._list.item_count == 1 and m._list.get_item_metadata(0) == "scriptorium", "")
	m._select_list_room(0)
	_check("selecting a search result highlights the room", m.picked == "scriptorium", "")
	m._search.clear()
	m._refresh_rooms()

	# The original regression only checked that Library's document opened.
	m.select("church")
	m.nudge(2, 0)
	var pending: Array = m._rooms()["church"]["cell"].duplicate()
	m.select("library")
	m.open_in_room_builder()
	await _frames(4)
	var rb = Dev.tool
	_check("Edit Room opens Library from the Church", rb != null and Dev.tool_action == "dev_room" and rb.doc.file_id == "library", "action=%s" % Dev.tool_action)
	if rb == null or Dev.tool_action != "dev_room":
		return
	rb.doc.set_cell(2, 2, "m")
	await rb.play()
	await _frames(4)
	_check("Playtest loads the Library draft and its edits", String(main.room_name) == "library" and main.room.grid[2][2] == "m" and not get_tree().paused, "room=%s" % main.room_name)
	Dev.return_to_builder()
	_check("stopping restores gameplay and keeps the draft", Dev.tool == rb and main.room_name == "church" and rb.doc.get_cell(2, 2) == "m", "")
	Dev.show_map()
	_check("switching to Room and back preserves an unsaved map edit", Dev.tool == m and m.is_dirty() and m._rooms()["church"]["cell"] == pending, "")
	m.open_in_room_builder()
	_check("reopening the same room restores its draft", Dev.tool == rb and rb.doc.get_cell(2, 2) == "m", "")
	Dev.show_map()

	m.set_sheet("after")
	m.select("church_shift")
	m.open_in_room_builder()
	var shifted_builder = Dev.tool
	_check("After opens the shifted room file", shifted_builder != m and shifted_builder.doc.file_id == "church_shift", "")
	if shifted_builder != m:
		await shifted_builder.play()
		await _frames(4)
		_check("After playtest uses the shifted room and sheet", main.room.file_id == "church_shift" and W.sheet == "after" and G.shifted, "")
		Dev.return_to_builder()
		Dev.show_map()

	# Play from the map on the requested era, and return to its open draft.
	m.set_sheet("restored")
	m.select("arnetria")
	m.teleport()
	await _frames(12)
	_check("Play Here loads a room on the Restored sheet in colour", String(main.room_name) == "arnetria" and not G.shifted and W.sheet == "restored", "room=%s shifted=%s sheet=%s" % [main.room_name, str(G.shifted), W.sheet])
	Dev.return_to_builder()
	_check("stopping map playtest restores the same map and era", Dev.tool == m and get_tree().paused and m.sheet == "restored" and m.is_dirty(), "")

	Dev.request_close()
	_check("closing dirty drafts opens a confirmation", Dev._close_dialog != null and Dev.busy(), "")
	if Dev._close_dialog != null:
		Dev._close_dialog.canceled.emit()
	_check("Keep editing retains the map and room drafts", Dev._close_dialog == null and Dev.tool == m and m.is_dirty(), "")
	Dev.request_close()
	if Dev._close_dialog != null:
		Dev._close_dialog.custom_action.emit(&"discard")
	await _frames(2)
	_check("Discard ends the session and returns to gameplay", not Dev.busy() and not get_tree().paused and main.room_name == "church", "")

	m = Dev.open_tool("dev_map")
	m.select("church")
	m.nudge(2, 0)
	var saved_cell: Array = m._rooms()["church"]["cell"].duplicate()
	m.select("library")
	m.open_in_room_builder()
	rb = Dev.tool
	rb.doc.set_cell(2, 2, "H")
	Dev.request_close()
	if Dev._close_dialog != null:
		Dev._close_dialog.confirmed.emit()
	await _frames(2)
	var saved_map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("data/rooms_meta.json")))
	var saved_room := FileAccess.get_file_as_string(dir.path_join("rooms/library.txt")).split("\n", false)
	var disk_cell: Array = saved_map["sheets"]["before"]["church"]["cell"]
	_check("Save all writes the active room and hidden map drafts",
		not Dev.busy() and disk_cell.map(func(value): return int(value)) == saved_cell.map(func(value): return int(value))
		and saved_room.size() > 3 and saved_room[3][2] == "H", "")


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FAIL ", name, " | ", detail)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
