# PROTOTYPE - NOT FOR PRODUCTION
# tests_v4/t_math.gd - locked test (step 0, written from design/contract.md section 4 only).
# The rpg_math.gd formulas (contract 2.7, exact signatures) and the R-side damage behaviour.
# Builders never edit this pack. Run: godot --headless --path . res://tests_v4/t_math.tscn
extends Node

var main: Node = null
var passed := 0
var failed := 0
var math_obj = null


func _ready() -> void:
	G.peace = true
	if ResourceLoader.exists("res://main.tscn"):
		main = load("res://main.tscn").instantiate()
		add_child(main)
		await _frames(30)
	_r_seed()
	await _load_math()
	await _run()
	var ok := failed == 0 and passed > 0
	print("t_math %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


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


func _load_math() -> void:
	if not ResourceLoader.exists("res://rpg_math.gd"):
		_check("rpg_math.gd exists and loads", false, "ResourceLoader cannot find res://rpg_math.gd")
		return
	var rm = load("res://rpg_math.gd")
	if rm == null:
		_check("rpg_math.gd exists and loads", false, "load returned null")
		return
	var ok := false
	if rm.has_method("new"):
		math_obj = rm.new()
		ok = math_obj != null
	_check("rpg_math.gd exists and loads", ok, "class=%s" % str(rm.get_instance_base_type()))


func _m(fname: String, args: Array) -> float:
	# Static formulas are called through an instance so the call works either way.
	if math_obj == null or not math_obj.has_method(fname):
		return NAN
	var v = math_obj.callv(fname, args)
	if v is int or v is float:
		return float(v)
	return NAN


func _run() -> void:
	var step := 10.0
	if T.data.has("xp_curve_step"):
		step = T.v("xp_curve_step")

	# xp_total(level, step): 0,20,50,90,140,200,270,350,440,540 for levels 1..10
	var want := [0, 20, 50, 90, 140, 200, 270, 350, 440, 540]
	var got := []
	var bad := []
	for i in 10:
		var v := int(_m("xp_total", [i + 1, step]))
		got.append(v)
		if v != want[i]:
			bad.append("L%d=%d want %d" % [i + 1, v, want[i]])
	_check("xp_total 1..10 is 0,20,50,90,140,200,270,350,440,540", bad.is_empty(), "step=%.0f got=%s bad=%s" % [step, str(got), str(bad)])

	# level_for(xp, step, cap)
	var lv_bad := []
	var cap := 10.0
	if T.data.has("level_cap"):
		cap = T.v("level_cap")
	if int(_m("level_for", [0, step, cap])) != 1:
		lv_bad.append("0 xp")
	if int(_m("level_for", [20, step, cap])) != 2:
		lv_bad.append("20 xp")
	if int(_m("level_for", [50, step, cap])) != 3:
		lv_bad.append("50 xp")
	if int(_m("level_for", [140, step, cap])) != 5:
		lv_bad.append("140 xp")
	if int(_m("level_for", [540, step, cap])) != 10:
		lv_bad.append("540 xp")
	if int(_m("level_for", [99999, step, cap])) != int(cap):
		lv_bad.append("over cap")
	_check("level_for maps XP to levels and stops at level_cap", lv_bad.is_empty(), str(lv_bad))

	# dealt(power, atk, add) = max(1, round(power * atk / 100 + add))
	var d_bad := []
	if int(_m("dealt", [10.0, 100.0, 0.0])) != 10:
		d_bad.append("base")
	if int(_m("dealt", [10.0, 132.0, 0.0])) != 13:
		d_bad.append("atk132")
	if int(_m("dealt", [10.0, 100.0, 5.0])) != 15:
		d_bad.append("coupler")
	if int(_m("dealt", [0.5, 100.0, 0.0])) != 1:
		d_bad.append("min 1")
	_check("dealt follows F1 (flat add, at least 1)", d_bad.is_empty(), str(d_bad))

	# special(power, special_pct) = max(1, round(power * special_pct / 100)); ignores ATK
	var s_bad := []
	if int(_m("special", [30.0, 100.0])) != 30:
		s_bad.append("base")
	if int(_m("special", [30.0, 116.0])) != 35:
		s_bad.append("magic2 wave")
	if int(_m("special", [24.0, 116.0])) != 28:
		s_bad.append("magic2 requiem")
	_check("special follows F2 (ignores ATK)", s_bad.is_empty(), str(s_bad))

	# taken(raw, mult, def) = max(1, round(raw * mult * (100 - def) / 100))
	var t_bad := []
	if int(_m("taken", [7.0, 0.75, 0.0])) != 5:
		t_bad.append("ghost touch")
	if int(_m("taken", [16.0, 1.0, 11.0])) != 14:
		t_bad.append("cerement")
	if int(_m("taken", [40.0, 1.0, 40.0])) != 24:
		t_bad.append("def40")
	if int(_m("taken", [1.0, 0.1, 100.0])) != 1:
		t_bad.append("min 1")
	_check("taken follows F3 (round half up, at least 1)", t_bad.is_empty(), str(t_bad))

	# scrap_chance(base, low, hp_share) = clamp(base + low * (1 - hp_share), 0, 1)
	var c_bad := []
	if absf(_m("scrap_chance", [0.4, 1.0, 1.0]) - 0.4) > 0.001:
		c_bad.append("full hp")
	if absf(_m("scrap_chance", [0.4, 1.0, 0.75]) - 0.65) > 0.001:
		c_bad.append("half hp")
	if absf(_m("scrap_chance", [0.4, 1.0, 0.1]) - 1.0) > 0.001:
		c_bad.append("clamped at 1")
	if absf(_m("scrap_chance", [0.1, 0.35, 0.0]) - 0.45) > 0.001:
		c_bad.append("drop values")
	_check("scrap_chance follows the contract formula (clamp 0..1)", c_bad.is_empty(), str(c_bad))

	# --- R-side damage behaviour (S0) -----------------------------------------
	var r := _r()
	if r == null:
		_check("R exists for the damage checks", false, "no /root/R autoload")
		return

	# boss and ordinary-enemy mults at her base sheet (DEF 0, before any points are spent)
	var boss_hit: float = float(r.call("taken", 16.0, "boss"))
	_check("a boss hit uses mult 1.0", boss_hit == 16.0, "taken=%.0f" % boss_hit)
	var ghost_hit: float = float(r.call("taken", 7.0, "ghost"))
	_check("a ghost touch takes 5 (area mult 0.75)", ghost_hit == 5.0, "taken=%.0f area=%s" % [ghost_hit, str(_tv("area_damage_mult"))])

	var hd_plain := -1
	var hd_special := -1
	if r.has_method("hit_damage"):
		hd_plain = int(r.call("hit_damage", 10.0, false))
		hd_special = int(r.call("hit_damage", 30.0, true))
	_check("hit_damage(10, false) is 10 and (30, true) is 30 at her base sheet",
		hd_plain == 10 and hd_special == 30, "plain=%d special=%d" % [hd_plain, hd_special])

	# a trap ignores DEF: give her DEF through points, then the trap is still unchanged
	var trap1: float = float(r.call("taken", 40.0, "trap"))
	var trap_def := NAN
	if r.has_method("debug_set"):
		r.call("debug_set", {"points": 8})
	var spent := false
	if r.has_method("spend"):
		spent = bool(r.call("spend", "guard"))
		if spent and r.has_method("spend"):
			r.call("spend", "guard")
	var trap2: float = float(r.call("taken", 40.0, "trap"))
	if spent:
		trap_def = trap2
	_check("a trap takes its raw number whatever her DEF", trap1 == 40.0 and (not spent or trap_def == 40.0),
		"raw=%.0f with_def=%.0f (def applied=%s)" % [trap1, trap_def, str(spent)])
