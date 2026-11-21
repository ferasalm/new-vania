# PROTOTYPE - NOT FOR PRODUCTION
# Gate for the explicit 45-degree stair terrain and normal walking in both directions.
extends Node

const RoomScript := preload("res://room.gd")

var passed := 0
var failed := 0
var _runner: CharacterBody2D


func _ready() -> void:
	var fixture := FileAccess.get_file_as_string("res://tests_dev/fixtures/stairs_room.txt")
	RoomScript.override["stairs_fixture"] = fixture
	var room: Node2D = RoomScript.new()
	add_child(room)
	var loaded: bool = room.load_room("stairs_fixture")
	_check("fixture room loads", loaded, "")
	if not loaded:
		_finish()
		return
	var run: Array[Vector2] = []
	for x in range(2, 8):
		run.append(Vector2(x, 12 - x))
	_check("fixture contains a continuous ascending right stair", _has_run(room, run, "/"), "expected x2..7 rising right")
	_make_runner(Vector2(24, 176))
	await _walk_for(140, 1.0)
	var reached_top := _runner.global_position.x >= 112.0 and _runner.global_position.y <= 92.0 and _runner.is_on_floor()
	_check("normal right movement walks up the stair", reached_top,
		"position=%s floor=%s" % [str(_runner.global_position), str(_runner.is_on_floor())])
	await _walk_for(140, -1.0)
	var reached_bottom := _runner.global_position.x <= 40.0 and _runner.global_position.y >= 150.0 and _runner.is_on_floor()
	_check("normal left movement walks down the same stair", reached_bottom,
		"position=%s floor=%s" % [str(_runner.global_position), str(_runner.is_on_floor())])
	RoomScript.override.erase("stairs_fixture")
	_finish()


func _has_run(room: Node2D, cells: Array[Vector2], glyph: String) -> bool:
	for cell: Vector2 in cells:
		if room.cell(int(cell.x), int(cell.y)) != glyph:
			return false
	return true


func _make_runner(at: Vector2) -> void:
	_runner = CharacterBody2D.new()
	_runner.position = at
	_runner.collision_layer = 4
	_runner.collision_mask = 1
	_runner.floor_max_angle = deg_to_rad(60.0)
	_runner.floor_snap_length = 6.0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 36)
	shape.shape = rect
	shape.position = Vector2(0, -18)
	_runner.add_child(shape)
	add_child(_runner)


func _walk_for(frames: int, direction: float) -> void:
	for _i in frames:
		_runner.velocity.x = direction * 70.0
		_runner.velocity.y = minf(_runner.velocity.y + 980.0 / 60.0, 760.0)
		_runner.move_and_slide()
		await get_tree().physics_frame


func _check(label: String, ok: bool, detail: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("%s  %s%s" % ["ok" if ok else "FAIL", label, " — " + detail if detail != "" else ""])


func _finish() -> void:
	var ok := failed == 0 and passed > 0
	print("d15_stairs %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)
