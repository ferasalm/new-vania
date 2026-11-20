# PROTOTYPE - NOT FOR PRODUCTION
# tests_quick/q2_moth_time.gd - proof for ledger N12 (redo of N2).
# User: the butterfly's smoke object floats and then disappears too slowly. The smoke
# clouds must be gone about 3 s after they are released, and the dive attack must be
# back at its original timing (OpenCode had sped up the moth itself by mistake).
# Run: godot --headless --path . res://tests_quick/q2_moth_time.tscn
extends Node

const OLD_DIVE := {"moth_dive_warning": 0.6, "moth_dive_time": 1.1, "moth_ember_burn": 1.0, "moth_ember_every": 0.14}

var main: Node = null
var passed := 0
var failed := 0


func _ready() -> void:
	G.peace = true
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _frames(30)
	_r_seed()
	if main.has_method("debug_enter"):
		await main.debug_enter("church", "left", false)
	await _frames(10)
	await _run()
	var ok := failed == 0 and passed > 0
	print("q2_moth_time %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _run() -> void:
	var p: Node2D = _player()
	_check("she is in the room", p != null, "player=%s" % str(p))
	if p == null:
		return
	# the dive keeps its original numbers (the moth itself is not faster)
	for k in OLD_DIVE:
		_check("%s is back at %.2f" % [k, OLD_DIVE[k]], absf(_tv(k) - float(OLD_DIVE[k])) < 0.001,
			"%s=%s" % [k, str(_tv(k))])
	_check("smoke cloud life is 3.0 s", absf(_tv("moth_cloud_life") - 3.0) < 0.001,
		"moth_cloud_life=%s" % str(_tv("moth_cloud_life")))
	# stand her in the open middle of the nave and put a moth beside her
	var room: Node2D = main.get("room")
	p.call("debug_set", {"pos": Vector2(room.size.x * 0.5, p.global_position.y)})
	await _frames(15)
	var feet: Vector2 = p.global_position
	var moth := _spawn_moth(feet + Vector2(90.0, -58.0))
	_check("a moth is spawned near her", moth != null and String(moth.get("kind")) == "moth",
		"moth=%s" % str(moth))
	if moth == null:
		return
	moth.set("_cool", 0.0)
	moth.call("start_attack", "veil")
	# wait for the smoke to be released
	var released := false
	for i in 240:
		await get_tree().physics_frame
		if _cloud_count() > 0:
			released = true
			break
	_check("the veil attack releases smoke clouds", released, "clouds=%d" % _cloud_count())
	if not released:
		return
	# how long until every cloud is gone
	var frames := 0
	var peak := _cloud_count()
	for i in 600:
		await get_tree().physics_frame
		frames += 1
		peak = maxi(peak, _cloud_count())
		if _cloud_count() == 0:
			break
	var secs := frames / 60.0
	print("moth smoke: %d clouds at most, all gone %.2f s after release" % [peak, secs])
	_check("all smoke is gone about 3 s after release", secs <= 3.1 and secs >= 1.5,
		"gone after %.2f s (want 1.5 to 3.1)" % secs)


func _spawn_moth(at: Vector2) -> Node2D:
	var sp: Node = main.get("spawner")
	if sp == null or not sp.has_method("enemy"):
		return null
	var moth: Node2D = sp.call("enemy", "moth", at)
	if moth != null:
		main.get("world").add_child(moth)
	return moth


func _cloud_count() -> int:
	var n := 0
	for c in get_tree().get_nodes_in_group("e2_cloud"):
		if is_instance_valid(c) and not c.is_queued_for_deletion():
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


func _r_seed() -> void:
	var r := get_node_or_null("/root/R")
	if r != null and r.has_method("debug_seed"):
		r.debug_seed(7)


func _tv(key: String) -> float:
	if T.data.has(key):
		return T.v(key)
	return NAN


func _player() -> Node2D:
	if main == null:
		return null
	return main.get("player")
