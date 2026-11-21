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
	_runner.queue_free()
	room.queue_free()      # its walls sit at the same coordinates as the game room below
	await get_tree().physics_frame
	await _pandora_checks()
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
	_runner.floor_constant_speed = true      # mirrors player.gd: full speed up a slope
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


# The real gate: Pandora herself, in the real game, with the real keys (added 2026-11-21).
# Run on the fixture as written (stair rising right, "/") and mirrored (rising left, "\\").
func _pandora_checks() -> void:
	G.peace = true
	var text := FileAccess.get_file_as_string("res://tests_dev/fixtures/stairs_room_full.txt")
	var main: Node = load("res://main.tscn").instantiate()
	add_child(main)
	for i in 30:
		await get_tree().physics_frame
	await _pandora_run(main, text, 1)
	await _pandora_run(main, _mirror(text), -1)
	RoomScript.override.erase("scriptorium")


func _mirror(text: String) -> String:
	var out: Array = []
	for line in text.split("\n"):
		if line.contains("="):
			out.append(line)
			continue
		var r := ""
		for i in range(line.length() - 1, -1, -1):
			var ch := line[i]
			r += "\\" if ch == "/" else ch
		out.append(r)
	return "\n".join(out)


# side 1: the stair rises to the right; -1: mirrored, it rises to the left. Room is 384 wide.
func _pandora_run(main: Node, text: String, side: int) -> void:
	var up_key := "right" if side == 1 else "left"
	var down_key := "left" if side == 1 else "right"
	var mx := func(x: float) -> float: return x if side == 1 else 384.0 - x
	var name := "rising %s" % up_key
	RoomScript.override["scriptorium"] = text
	await main.debug_enter("scriptorium", "left", false)
	for i in 10:
		await get_tree().physics_frame
	var pl: Node2D = main.player
	pl.global_position = Vector2(mx.call(56.0), 190)
	pl.velocity = Vector2.ZERO
	for i in 20:
		await get_tree().physics_frame
	var start_x: float = pl.global_position.x
	Input.action_press(up_key)
	var frames_up := -1
	for i in 240:
		await get_tree().physics_frame
		var past: bool = pl.global_position.x >= 216.0 if side == 1 else pl.global_position.x <= 168.0
		if past and pl.global_position.y <= 113.0 and pl.is_on_floor():
			frames_up = i
			break
	Input.action_release(up_key)
	_check("Pandora walks up the stair (%s) with the %s key alone" % [name, up_key.capitalize()], frames_up >= 0,
		"position=%s floor=%s" % [str(pl.global_position.round()), str(pl.is_on_floor())])
	# the climb (about 160 px across) takes about as long as the same distance on flat floor
	var run_speed: float = T.v("run_speed") if T.data.has("run_speed") else 0.0
	if run_speed > 0.0 and frames_up >= 0:
		var flat_frames := absf(mx.call(216.0) - start_x) / run_speed * 60.0
		_check("she climbs (%s) at her flat-floor speed (within 25 percent)" % name, float(frames_up) <= flat_frames * 1.25 + 10.0,
			"%d frames, flat would be %.0f" % [frames_up, flat_frames])
	for i in 10:
		await get_tree().physics_frame
	Input.action_press(down_key)
	var down_ok := false
	for i in 240:
		await get_tree().physics_frame
		var back: bool = pl.global_position.x <= 100.0 if side == 1 else pl.global_position.x >= 284.0
		if back and pl.global_position.y >= 207.0 and pl.is_on_floor():
			down_ok = true
			break
	Input.action_release(down_key)
	_check("Pandora walks down the stair (%s) with the %s key alone" % [name, down_key.capitalize()], down_ok,
		"position=%s floor=%s" % [str(pl.global_position.round()), str(pl.is_on_floor())])


func _finish() -> void:
	var ok := failed == 0 and passed > 0
	print("d15_stairs %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)
