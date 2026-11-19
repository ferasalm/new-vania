# PROTOTYPE - NOT FOR PRODUCTION
# tests_quick/q3_weapon_frames.gd - proof for ledger N14 (redo of N3).
# The level J and I slashes must not show the old vertical look: no weapon on the
# wind-up frame, no weapon on the last frame, and no ghost copy of the blade left
# behind (only sparks). The scythe's head is drawn flatter in the level swing.
# Run: godot --headless --path . res://tests_quick/q3_weapon_frames.tscn
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
	var p: Node2D = main.get("player")
	main.set("has_elegy", true)
	for w in 2:
		for btn in ["attack", "attack2"]:
			await _swing(p, w, btn)
	var ok := failed == 0 and passed > 0
	print("q3_weapon_frames %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _swing(p: Node2D, w: int, btn: String) -> void:
	T.set_v("weapon", float(w))
	p.set("energy", T.v("energy_max"))
	await _frames(40)    # let the last swing end
	var tag := "%s %s" % [p.call("weapon_name"), "J" if btn == "attack" else "I"]
	var world: Node = p.get_parent()
	var base := _ghosts(world)
	var spr: AnimatedSprite2D = p.get("_spr")
	var blade: Sprite2D = p.get("_blade")
	var total := T.v("elegy_time") if w == 1 else T.v("attack_time")
	Input.action_press(btn)
	await _frames(2)
	Input.action_release(btn)
	var by_frame := {}          # body frame -> [blade visible, blade scale.y]
	var most_ghosts := base
	for i in int(total * 60.0) + 40:
		await get_tree().physics_frame
		if String(spr.animation) in ["attack", "attack2"]:
			by_frame[spr.frame] = [blade.visible, blade.scale.y]
		most_ghosts = maxi(most_ghosts, _ghosts(world))
	var n := by_frame.size()
	_check("%s: the swing ran through its frames" % tag, n >= 4, "frames seen=%s" % str(by_frame.keys()))
	if n < 4:
		return
	var last: int = by_frame.keys().max()
	_check("%s: no weapon on the wind-up frame" % tag, not by_frame[0][0], "frame 0 visible=%s" % str(by_frame[0][0]))
	var middle_ok := true
	for f in range(1, last):
		if by_frame.has(f) and not by_frame[f][0]:
			middle_ok = false
	_check("%s: weapon shown on the frames between" % tag, middle_ok, str(by_frame))
	_check("%s: no weapon on the last frame" % tag, not by_frame[last][0], "last visible=%s" % str(by_frame[last][0]))
	_check("%s: no ghost copy of the blade is left behind" % tag, most_ghosts == base,
		"shader sprites in the world %d -> %d" % [base, most_ghosts])
	if w == 1:
		var flat := T.v("weapon_level_flat")
		var f1: float = by_frame[1][1] if by_frame.has(1) else NAN
		_check("%s: the scythe head is drawn flatter" % tag, absf(f1 - flat) < 0.001 and flat < 1.0,
			"scale.y=%s want %s" % [str(f1), str(flat)])
	else:
		var f1s: float = by_frame[1][1] if by_frame.has(1) else NAN
		_check("%s: the sword is drawn as it is" % tag, absf(f1s - 1.0) < 0.001, "scale.y=%s" % str(f1s))


func _ghosts(world: Node) -> int:
	# a dissolving copy of the blade is a Sprite2D with the weapon shader that is not the player's own blade
	var n := 0
	for c in world.get_children():
		if c is Sprite2D and (c as Sprite2D).material is ShaderMaterial:
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
