# PROTOTYPE - NOT FOR PRODUCTION
# tests_dev/d7_library_route.gd - the Library's doors and its map entry (user's two-cell Library, ledger N8):
# the file and the map entry agree on height, every door leads somewhere real, she arrives from the Church at the
# lowest left door, and walking out of each door reaches the right room (both directions with the Church).
# Run: godot --headless --path . --log-file <log> res://tests_dev/d7_library_route.tscn
extends Node

const RoomScript := preload("res://room.gd")

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
	print("d7_library_route %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _run() -> void:
	await _arrive_from_church()
	var rm = main.room
	var rows := int(round(rm.size.y / float(RoomScript.TILE)))
	var cell: Array = rm.meta.get("cell", [])
	_check("the Library file and its map entry agree on height",
		rows % 14 == 0 and cell.size() == 4 and int(cell[3]) == rows / 14, "rows=%d cell=%s" % [rows, str(cell)])

	var bad: Array = []
	for d in rm.doors_all:
		var to_id := String(d.to).trim_suffix("_shift")
		if to_id == "" or not FileAccess.file_exists("res://rooms/%s.txt" % to_id):
			bad.append("%s door at y=%.0f -> '%s'" % [d.side, d.feet().y, to_id])
	_check("every Library door leads to a real room", rm.doors_all.size() == 3 and bad.is_empty(), "doors=%d bad=%s" % [rm.doors_all.size(), str(bad)])

	var lefts := _doors("left")
	_check("the lowest left door leads to the Church", lefts.size() == 2 and lefts[1].to == "church",
		"left doors=%s" % str(lefts.map(func(d): return String(d.to))))
	if lefts.size() != 2:
		return
	var church_door = lefts[1]

	# Church -> Library: she appears at the lower-left door
	var p = main.player
	_check("coming from the Church she appears at the lowest left door",
		p.global_position.x < 60.0 and absf(p.global_position.y - church_door.feet().y) < 6.0,
		"pos=%s door_y=%.0f" % [str(p.global_position), church_door.feet().y])

	# Library -> Church: walk out of that door and arrive at the Church's right edge
	p.global_position = Vector2(40.0, church_door.feet().y)
	p.velocity = Vector2.ZERO
	await _walk("left")
	_check("walking out of the lowest left door leads to the Church",
		main.room_name == "church" and main.player.global_position.x > main.room.size.x - 120.0,
		"room=%s x=%.0f" % [main.room_name, main.player.global_position.x])

	# the top-left door leads to the scriptorium
	await _arrive_from_church()
	var top = _doors("left")[0]
	main.player.global_position = Vector2(40.0, top.feet().y)
	main.player.velocity = Vector2.ZERO
	await _frames(3)
	await _walk("left")
	_check("the top-left door leads to the scriptorium", main.room_name == "scriptorium", "room=%s" % main.room_name)

	# the right door leads to the save room
	await _arrive_from_church()
	var rd: Array = _doors("right")
	_check("the Library has one right door", rd.size() == 1, "n=%d" % rd.size())
	if rd.size() == 1:
		main.player.global_position = Vector2(main.room.size.x - 40.0, rd[0].feet().y)
		main.player.velocity = Vector2.ZERO
		await _frames(3)
		await _walk("right")
		_check("the right door leads to the save room", main.room_name == "save", "room=%s" % main.room_name)


func _arrive_from_church() -> void:
	main.enter("library", "left", "church")
	await _frames(10)


func _doors(side: String) -> Array:
	var out: Array = main.room.doors_all.filter(func(d): return d.side == side)
	out.sort_custom(func(a, b): return a.feet().y < b.feet().y)
	return out


func _walk(action: String) -> void:
	var start: String = main.room_name
	Input.action_press(action)
	for i in 240:
		if main.room_name != start:
			break
		await get_tree().physics_frame
	Input.action_release(action)
	await _frames(40)


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FAIL ", name, " | ", detail)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
