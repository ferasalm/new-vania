# PROTOTYPE - NOT FOR PRODUCTION
# tests_quick/q2_moth_time.gd - proof for ledger N2 (handoff Q2).
# Times one butterfly (moth) dive attack, phase by phase: the warning, the dive
# itself, and the moment it is back up in the air after the strike. The whole
# attack (warning -> strike -> backing away) must take about 0.8 s or less, and
# the embers it drops must not keep burning on the floor long after the attack.
# The moth's flying speed and damage are not touched by this check.
# Run: godot --headless --path . res://tests_quick/q2_moth_time.tscn
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
	print("q2_moth_time %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _run() -> void:
	var p: Node2D = _player()
	_check("she is in the room", p != null, "player=%s" % str(p))
	if p == null:
		return
	# the church door is on the left, so she starts against the west wall: stand
	# her in the open middle of the nave so the dive has air on every side
	var room: Node2D = main.get("room")
	var cx: float = room.size.x * 0.5
	p.call("debug_set", {"pos": Vector2(cx, p.global_position.y)})
	await _frames(15)
	var feet: Vector2 = p.global_position
	# spawn the moth exactly on the spot it would pick for the dive warning
	# (her right side, 90 px over and 88 px up; setup() lifts it 30 more)
	var moth := _spawn_moth(feet + Vector2(90.0, -58.0))
	_check("a moth is spawned near her", moth != null and String(moth.get("kind")) == "moth",
		"moth=%s" % str(moth))
	if moth == null:
		return
	# the moth works her right side (side follows _count; 2 means right)
	moth.set("_count", 2)
	# force the dive attack (start_attack is the same hook the AI uses)
	moth.set("_cool", 0.0)
	moth.call("start_attack", "dive")
	# walk the attack through its phases, counting 60 fps frames
	var warn_frames := 0
	var dive_frames := 0
	var got_warn := false
	var got_dive := false
	var end_y := NAN
	var player_y: float = p.global_position.y
	for i in 480:
		await get_tree().physics_frame
		var st: String = String(moth.get("state"))
		if st == "warn_dive":
			got_warn = true
			warn_frames += 1
		elif st == "dive":
			got_dive = true
			dive_frames += 1
		elif st == "hover" and got_dive:
			end_y = float((moth as Node2D).global_position.y)
			break
	_check("the moth telegraphs (warn_dive) then dives", got_warn and got_dive,
		"warn=%d dive=%d" % [warn_frames, dive_frames])
	var warn_s := warn_frames / 60.0
	var dive_s := (dive_frames + 1) / 60.0    # +1: the frame it leaves the dive belongs to the dive
	var total_s := (warn_frames + dive_frames + 1) / 60.0
	print("moth dive attack phases: warning %.2f s, dive %.2f s, whole attack %.2f s"
		% [warn_s, dive_s, total_s])
	_check("the dive ran its full length (not cut short by a wall)",
		absf(dive_s - _tv("moth_dive_time")) <= 0.08,
		"dive=%.2f s tuning=%.2f s" % [dive_s, _tv("moth_dive_time")])
	_check("the whole dive attack (warning + strike + back away) is about 0.8 s or less",
		total_s <= 0.85, "total=%.2f s (want <= 0.80)" % total_s)
	_check("after the strike it is back up in the air, not down at the bottom",
		end_y < player_y - 40.0, "moth_y=%.0f her_y=%.0f" % [end_y, player_y])
	# the embers it dropped: how long do they stay on screen after the strike
	var linger := await _embers_gone(240)
	print("moth embers still on screen after the strike: %.2f s" % linger)
	_check("no ember keeps burning long after the strike is over", linger <= 1.30,
		"linger=%.2f s (want <= 1.30)" % linger)


func _spawn_moth(at: Vector2) -> Node2D:
	var sp: Node = main.get("spawner")
	if sp == null or not sp.has_method("enemy"):
		return null
	var moth: Node2D = sp.call("enemy", "moth", at)
	if moth != null:
		main.get("world").add_child(moth)
	return moth


func _embers_gone(max_frames: int) -> float:
	# seconds from the end of the strike until no ember is left falling or burning
	for i in max_frames:
		await get_tree().physics_frame
		if _ember_count() == 0:
			return i / 60.0
	return max_frames / 60.0


func _ember_count() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("e2_ember"):
		if is_instance_valid(e):
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


func _tv(key: String, alt := "") -> float:
	if T.data.has(key):
		return T.v(key)
	if alt != "" and T.data.has(alt):
		return T.v(alt)
	return NAN


func _player() -> Node2D:
	if main == null:
		return null
	return main.get("player")
