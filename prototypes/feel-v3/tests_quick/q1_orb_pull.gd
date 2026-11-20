# PROTOTYPE - NOT FOR PRODUCTION
# tests_quick/q1_orb_pull.gd - proof for ledger N1 and N13.
# An MP orb or a scrap piece dropped 150 px and 400 px away must reach her within
# 2 s with no input. When her MP (or scrap) bar is full it waits on the floor and
# flies to her as soon as she has room.
# Run: godot --headless --path . res://tests_quick/q1_orb_pull.tscn
extends Node

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
	print("q1_orb_pull %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _run() -> void:
	var lo = _loot()
	_check("loot system exists", lo != null and lo.has_method("spawn_pickup"), "loot=%s" % str(lo))
	if lo == null:
		return
	# 150 px away, no input, MP not full
	_player().call("debug_set", {"mp": 10.0})
	var orb_a = _spawn("soul_orb", Vector2(150.0, -6.0))
	var got_a := await _wait_collected(orb_a, 120)
	var mp_a: float = float(_player().get("mp"))
	_check("MP orb 150 px away is collected within 2 s with no input", got_a,
		"mp after=%.0f" % mp_a)
	_check("a collected orb gives her MP", mp_a >= 10.0 + _tv("mp_pickup") - 0.01,
		"mp %.0f want >= %.0f" % [mp_a, 10.0 + _tv("mp_pickup") - 0.01])
	# 400 px away, no input, MP not full
	_player().call("debug_set", {"mp": 10.0})
	var orb_b = _spawn("soul_orb", Vector2(400.0, -6.0))
	var got_b := await _wait_collected(orb_b, 120)
	_check("MP orb 400 px away is collected within 2 s with no input", got_b, "")
	# full MP: the orb waits on the floor (not lost), then flies once there is room
	var maxmp: float = float(_r().call("max_mp"))
	_player().call("debug_set", {"mp": maxmp})
	var orb_c = _spawn("soul_orb", Vector2(150.0, -6.0))
	var start_c: Vector2 = orb_c.global_position
	await _frames(240)    # 4 s: longer than the pop-out, longer than the old fly time
	_check("MP orb waits on the floor while her MP is full",
		is_instance_valid(orb_c) and orb_c.global_position.distance_to(start_c) < 4.0,
		"moved %.0f px" % (orb_c.global_position.distance_to(start_c) if is_instance_valid(orb_c) else -1.0))
	_player().call("debug_set", {"mp": maxmp - _tv("mp_pickup") * 0.5})
	await _frames(70)
	_check("the MP orb stays put until its whole charge fits",
		is_instance_valid(orb_c) and orb_c.global_position.distance_to(start_c) < 4.0, "")
	_player().call("debug_set", {"mp": 10.0})
	var got_c := await _wait_collected(orb_c, 150)
	_check("the waiting MP orb flies to her once she has room", got_c, "")
	# scrap flies to her like an orb
	_r().call("add_scrap", -float(_r().get("scrap")))
	var sc0: float = float(_r().get("scrap"))
	var scrap_a = _spawn("scrap", Vector2(150.0, -6.0))
	var got_sa := await _wait_collected(scrap_a, 120)
	_check("scrap 150 px away is collected within 2 s with no input", got_sa, "")
	_check("a collected scrap piece adds scrap_per_pickup",
		float(_r().get("scrap")) >= sc0 + _tv("scrap_per_pickup") - 0.01,
		"scrap %.0f -> %.0f" % [sc0, float(_r().get("scrap"))])
	var scrap_b = _spawn("scrap", Vector2(400.0, -6.0))
	var got_sb := await _wait_collected(scrap_b, 120)
	_check("scrap 400 px away is collected within 2 s with no input", got_sb, "")
	# a full scrap bar: the piece waits, then flies once she has spent some
	_r().call("add_scrap", 100000.0)
	var scrap_c = _spawn("scrap", Vector2(150.0, -6.0))
	var start_s: Vector2 = scrap_c.global_position
	await _frames(240)
	_check("scrap waits on the floor while her scrap bar is full",
		is_instance_valid(scrap_c) and scrap_c.global_position.distance_to(start_s) < 4.0,
		"moved %.0f px" % (scrap_c.global_position.distance_to(start_s) if is_instance_valid(scrap_c) else -1.0))
	_r().call("add_scrap", -_tv("scrap_per_pickup") * 0.5)
	await _frames(70)
	_check("the scrap stays put until the whole piece fits",
		is_instance_valid(scrap_c) and scrap_c.global_position.distance_to(start_s) < 4.0, "")
	_r().call("add_scrap", -40.0)
	var got_sc := await _wait_collected(scrap_c, 150)
	_check("the waiting scrap flies to her once she has room", got_sc, "")


func _wait_collected(orb, max_frames: int) -> bool:
	if orb == null:
		return false
	var lo = _loot()
	for i in max_frames:
		var gone: bool = not is_instance_valid(orb) or not lo.live.has(orb)
		if gone:
			return true
		await get_tree().create_timer(1.0 / 60.0).timeout
	return not is_instance_valid(orb) or not lo.live.has(orb)


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


func _r() -> Node:
	return get_node_or_null("/root/R")


func _tv(key: String, alt := "") -> float:
	if T.data.has(key):
		return T.v(key)
	if alt != "" and T.data.has(alt):
		return T.v(alt)
	return NAN


func _player() -> Node:
	return main.get("player")


func _loot():
	if main == null:
		return null
	var v = main.get("loot")
	if v != null:
		return v
	return main.get_node_or_null(NodePath("loot"))


func _spawn(item_id: String, offset: Vector2):
	var lo = _loot()
	if lo == null or not lo.has_method("spawn_pickup"):
		return null
	return lo.call("spawn_pickup", item_id, _player().global_position + offset, {})
