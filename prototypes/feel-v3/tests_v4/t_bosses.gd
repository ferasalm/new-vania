# PROTOTYPE - NOT FOR PRODUCTION
# tests_v4/t_bosses.gd - locked test (step 0, written from design/contract.md section 4 only).
# Machines (S4): the two lab enemies, the hit formula, area damage, XP, scrap, area_rest_mult.
# S5 THE PALLBEARER: HP 330, stages, warnings, hit rects, death reward.
# S6 THE UNMUZZLED: HP 160, states, landing stun, the wall jump.
# S7 ARNETRIA: the stored lie, stages, the visor, the end of the shift.
# S8 RECALL and REBUILD HERE.
# Builders never edit this pack. Run: godot --headless --path . res://tests_v4/t_bosses.tscn
extends Node

var main: Node = null
var passed := 0
var failed := 0
var box: Node2D = null


func _ready() -> void:
	G.peace = false
	if ResourceLoader.exists("res://main.tscn"):
		main = load("res://main.tscn").instantiate()
		add_child(main)
		box = Node2D.new()
		add_child(box)
		await _frames(30)
	_r_seed()
	await _run()
	var ok := failed == 0 and passed > 0
	print("t_bosses %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
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


func _pframes(n: int) -> void:
	for i in n:
		await get_tree().create_timer(1.0 / 60.0).timeout


func _wait_until(pred: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if pred.call():
			return true
		await get_tree().create_timer(1.0 / 60.0).timeout
	return pred.call()


func _r_seed() -> void:
	var r := get_node_or_null("/root/R")
	if r != null and r.has_method("debug_seed"):
		r.debug_seed(7)


func _r() -> Node:
	return get_node_or_null("/root/R")


func _w() -> Node:
	return get_node_or_null("/root/W")


func _tv(key: String, alt := "") -> float:
	if T.data.has(key):
		return T.v(key)
	if alt != "" and T.data.has(alt):
		return T.v(alt)
	return NAN


func _sys(nm: String):
	if main == null:
		return null
	var v = main.get(nm)
	if v != null:
		return v
	var n = main.get_node_or_null(NodePath(nm))
	if n != null:
		return n
	for c in main.find_children("*", "", true, false):
		if c is Node and c.get_script() != null and String(c.get_script().resource_path).ends_with(nm + ".gd"):
			return c
	return null


func _arity(obj: Node, mname: String) -> int:
	for md in obj.get_method_list():
		if md["name"] == mname:
			return (md["args"] as Array).size()
	return -1


func _hit(obj: Node, dmg: float) -> void:
	if obj == null or not obj.has_method("take_hit"):
		return
	var args := _arity(obj, "take_hit")
	if args <= 1:
		obj.call("take_hit", dmg)
	else:
		obj.call("take_hit", dmg, 0.0)


func _spawn_enemy(kind: String):
	var sp = _sys("spawner")
	if sp == null or not sp.has_method("enemy"):
		return null
	var en = sp.call("enemy", kind, Vector2(120.0, 0.0))
	if en != null and en is Node:
		box.add_child(en)
	return en


func _spawn_boss(id: String, size: Vector2):
	var sp = _sys("spawner")
	if sp == null or not sp.has_method("boss"):
		return null
	var b = sp.call("boss", id, Vector2(160.0, 0.0), size)
	if b != null and b is Node:
		box.add_child(b)
		var arena = _sys("arena")
		if arena != null and arena.has_method("attach"):
			arena.call("attach", b)
	return b


func _begin(b) -> void:
	if b != null and b.has_method("setup"):
		b.call("setup", Vector2(160.0, 0.0), Vector2(480.0, 224.0))
	if b != null and b.has_method("begin"):
		b.call("begin")
	await _frames(10)


func _run() -> void:
	# ======================= S4: machines =======================
	var trolley = _spawn_enemy("trolley")
	var orderly = _spawn_enemy("orderly")
	_check("SAWBONES TROLLEY spawns from its glyph in the lab", trolley != null, "trolley=%s" % str(trolley != null))
	_check("GRAFTED ORDERLY spawns from its glyph in the lab", orderly != null, "orderly=%s" % str(orderly != null))
	var iface_bad := []
	if trolley != null:
		for m in ["setup", "hurt_rect", "can_hurt", "damage", "touched_player", "take_hit"]:
			if not trolley.has_method(m):
				iface_bad.append(m)
		for prop in ["kind", "hp"]:
			if trolley.get(prop) == null:
				iface_bad.append("var " + prop)
	_check("both machines carry the full enemy interface", iface_bad.is_empty(), str(iface_bad))

	var r := _r()
	if trolley != null and r != null and r.has_method("hit_damage"):
		var dmg: float = float(r.call("hit_damage", T.v("attack_damage"), false))
		var hp0: float = float(trolley.get("hp"))
		_hit(trolley, dmg)
		await _frames(3)
		var hp1: float = float(trolley.get("hp"))
		_check("a hit on a machine uses the damage formula", absf((hp0 - hp1) - dmg) < 0.51,
			"hp %.0f -> %.0f for dmg %.0f" % [hp0, hp1, dmg])
	else:
		_check("a hit on a machine uses the damage formula", false, "no trolley or no R")

	if orderly != null and r != null and main != null and main.get("player") != null:
		var pl: Node = main.get("player")
		if pl.has_method("debug_set"):
			pl.call("debug_set", {"hp": 100.0})
		var want: float = roundf(_tv("orderly_clamp_damage") * _tv("area_damage_mult"))
		var hp0: float = float(pl.get("hp"))
		if orderly.has_method("touched_player"):
			var args := _arity(orderly, "touched_player")
			if args <= 0:
				orderly.call("touched_player")
			else:
				orderly.call("touched_player", pl)
		await _frames(5)
		var took: float = hp0 - float(pl.get("hp"))
		_check("machine damage to her uses area_damage_mult", absf(took - want) < 0.51,
			"took %.0f want %.0f (clamp=%s area=%s)" % [took, want, str(_tv("orderly_clamp_damage")), str(_tv("area_damage_mult"))])
	else:
		_check("machine damage to her uses area_damage_mult", false, "no orderly")

	if orderly != null and r != null:
		var xp0: int = int(r.get("xp"))
		_hit(orderly, 9999.0)
		await _frames(10)
		var gain: int = int(r.get("xp")) - xp0
		_check("a machine kill gives its XP", gain == int(_tv("xp_orderly")), "gain=%d want=%.0f" % [gain, _tv("xp_orderly")])
	else:
		_check("a machine kill gives its XP", false, "no orderly")

	var lo = _sys("loot")
	if lo != null and lo.has_method("roll_drops"):
		var rate_o := _scrap_rate("orderly")
		var rate_h := _scrap_rate("hound")
		_check("machines roll scrap with scrap_machine_mult (orderly above hound)", rate_o > rate_h,
			"orderly=%.3f hound=%.3f" % [rate_o, rate_h])
	else:
		_check("machines roll scrap with scrap_machine_mult (orderly above hound)", false, "no loot.roll_drops")

	var rest_bad := []
	if _tv("area_rest_mult") == 1.2:
		var hound = _spawn_enemy("hound")
		var crab = _spawn_enemy("crab")
		for probe in [[hound, "hound_rest"], [crab, "crab_rest"]]:
			if probe[0] == null:
				rest_bad.append("no " + String(probe[1]))
				continue
			var want: float = _tv(String(probe[1])) * _tv("area_rest_mult")
			var found := false
			for prop in ["rest", "rest_time", "attack_rest", "wait", "wait_time", "calm"]:
				var v = probe[0].get(prop)
				if v != null and (v is float or v is int) and absf(float(v) - want) <= want * 0.15:
					found = true
			if not found:
				rest_bad.append(String(probe[1]) + " rest not lengthened (no observable value near %.2f)" % want)
	else:
		rest_bad.append("area_rest_mult=%s" % str(_tv("area_rest_mult")))
	_check("area_rest_mult lengthens the rest of hound and crab", rest_bad.is_empty(), str(rest_bad))

	# ======================= S5: THE PALLBEARER =======================
	var pb = _spawn_boss("pallbearer", Vector2(480, 224))
	if pb != null:
		await _begin(pb)
		var max_hp: float = float(pb.call("max_hp"))
		_check("THE PALLBEARER starts at boss_hp (330)", max_hp == _tv("boss_hp") and _tv("boss_hp") == 330.0,
			"max_hp=%.0f boss_hp=%s" % [max_hp, str(_tv("boss_hp"))])
		pb.set("hp", max_hp * 0.59)
		await _frames(3)
		var st_low := int(pb.call("stage"))
		pb.set("hp", max_hp * 0.24)
		await _frames(3)
		var st_low3 := int(pb.call("stage"))
		_check("the Pallbearer changes stage at 60 and 25 percent", st_low == 2 and st_low3 == 3,
			"at 59%%=%d at 24%%=%d" % [st_low, st_low3])
		pb.set("hp", max_hp * 0.2)
		await _frames(3)
		var warns_ok := true
		var warn_detail := "no stage 3 attacks logged"
		await _wait_until(_pred_log3.bind(pb), 600)
		var log = pb.get("attack_log")
		if log is Array and not (log as Array).is_empty():
			var min_warn2 := 99.0
			var n3b := 0
			for e in log:
				if e is Dictionary and int(e.get("stage", 0)) == 3:
					n3b += 1
					min_warn2 = minf(min_warn2, float(e.get("warn", 99.0)))
			warns_ok = n3b > 0 and min_warn2 >= _tv("boss_min_warn") - 0.01
			warn_detail = "%d stage-3 attacks, min warn %.2f" % [n3b, min_warn2]
		_check("every stage 3 warning is at least boss_min_warn", warns_ok, warn_detail)
		var rects_ok := false
		var rect_detail := "no hit_rects seen"
		if pb.has_method("hit_rects") and pb.has_method("scythe_rect"):
			for i in 120:
				var rects = pb.call("hit_rects")
				if rects is Array and not (rects as Array).is_empty():
					var sc = pb.call("scythe_rect")
					var inside := true
					for rc in rects:
						if rc is Rect2 and not (sc as Rect2).encloses(rc):
							inside = false
					rects_ok = inside
					rect_detail = "%d rects inside=%s" % [(rects as Array).size(), str(inside)]
					break
				await get_tree().create_timer(1.0 / 60.0).timeout
		_check("every hit rect lies inside the grown scythe rect", rects_ok, rect_detail)
		var w := _w()
		var xp0: int = int(r.get("xp")) if r != null else 0
		_hit(pb, 99999.0)
		var died := await _wait_until(_pred_dead.bind(pb), 600)
		await _frames(10)
		var flag_ok: bool = w != null and w.has_method("flag") and bool(w.call("flag", "beaten_pallbearer"))
		var elegy_ok := _loot_has("elegy_013")
		_check("the Pallbearer's death sets its flag and leaves ELEGY-013", died and flag_ok and elegy_ok,
			"alive=%s flag=%s pickup=%s" % [str(pb.get("alive")), str(flag_ok), str(elegy_ok)])
	else:
		_check("THE PALLBEARER starts at boss_hp (330)", false, "no pallbearer boss")
		_check("the Pallbearer changes stage at 60 and 25 percent", false, "no boss")
		_check("every stage 3 warning is at least boss_min_warn", false, "no boss")
		_check("every hit rect lies inside the grown scythe rect", false, "no boss")
		_check("the Pallbearer's death sets its flag and leaves ELEGY-013", false, "no boss")

	# ======================= S6: THE UNMUZZLED =======================
	if main != null and main.has_method("debug_enter"):
		await main.debug_enter("kennel", "left", false)
	else:
		await _frames(10)
	var wolf = _spawn_boss("unmuzzled", Vector2(320, 192))
	if wolf != null:
		await _begin(wolf)
		var wmax: float = float(wolf.call("max_hp"))
		_check("THE UNMUZZLED has HP 160", wmax == _tv("wolf_hp") and _tv("wolf_hp") == 160.0,
			"max=%.0f wolf_hp=%s" % [wmax, str(_tv("wolf_hp"))])
		wolf.set("hp", wmax * 0.49)
		await _frames(3)
		var wst := int(wolf.call("stage"))
		_check("the Unmuzzled changes stage at 50 percent", wst == 2, "at 49%%=%d" % wst)
		wolf.set("hp", wmax)
		var states := {}
		var stun_best := 0.0
		var stun_run := 0.0
		var last_state := ""
		for i in 900:
			var st := String(wolf.get("state"))
			if st != "":
				states[st] = true
				if st == last_state:
					stun_run += 1.0 / 60.0
				else:
					if _is_stun_state(last_state):
						stun_best = maxf(stun_best, stun_run)
					stun_run = 1.0 / 60.0
				last_state = st
			await get_tree().create_timer(1.0 / 60.0).timeout
		var need := ["cling", "pounce", "ricochet"]
		var seen_missing := []
		for s in need:
			if not states.has(s):
				seen_missing.append(s)
		_check("the state log shows cling, pounce and ricochet", seen_missing.is_empty(),
			"states=%s missing=%s" % [str(states.keys()), str(seen_missing)])
		var want_stun: float = _tv("wolf_land_stun")
		if is_nan(want_stun):
			want_stun = 1.2
		_check("landing stuns last at least wolf_land_stun", stun_best >= want_stun - 0.25 and stun_best > 0.0,
			"best=%.2f want=%.2f" % [stun_best, want_stun])
		var seal_bad := _doors_sealed()
		_check("the doors seal while he fights", seal_bad == "", seal_bad)
		var w2 := _w()
		_hit(wolf, 99999.0)
		var died := await _wait_until(_pred_dead.bind(wolf), 600)
		await _frames(10)
		var wj_ok := _loot_has("wall_jump")
		_check("his death leaves the wall jump pickup", died and wj_ok, "alive=%s pickup=%s" % [str(wolf.get("alive")), str(wj_ok)])
		if wj_ok:
			var loot = _sys("loot")
			var live = loot.get("live") if loot != null else null
			if live is Array:
				for it in live:
					if it != null and is_instance_valid(it) and str(it.get("item_id")) == "wall_jump":
						if it.has_method("take"):
							it.call("take")
						break
			await _frames(10)
			var latch = main.get("player").get("_can_latch") if main != null and main.get("player") != null else null
			_check("after taking the wall jump she can latch a wall", latch != null and bool(latch), "_can_latch=%s" % str(latch))
		else:
			_check("after taking the wall jump she can latch a wall", false, "no wall_jump pickup")
	else:
		_check("THE UNMUZZLED has HP 160", false, "no unmuzzled boss")
		_check("the Unmuzzled changes stage at 50 percent", false, "no boss")
		_check("the state log shows cling, pounce and ricochet", false, "no boss")
		_check("landing stuns last at least wolf_land_stun", false, "no boss")
		_check("the doors seal while he fights", false, "no boss")
		_check("his death leaves the wall jump pickup", false, "no boss")
		_check("after taking the wall jump she can latch a wall", false, "no boss")

	# ======================= S7: ARNETRIA =======================
	var dlg = _read_json("res://data/dialogue.json")
	var dlg_ok: bool = dlg is Dictionary and (dlg as Dictionary).has("arnetria_intro")
	_check("dialogue.json holds arnetria_intro", dlg_ok, "found=%s" % str(dlg_ok))
	var arn = _spawn_boss("arnetria", Vector2(480, 224))
	if arn != null:
		await _begin(arn)
		var amax: float = float(arn.call("max_hp"))
		var shown0 = arn.get("shown_hp")
		_hit(arn, 20.0)
		await _frames(3)
		_hit(arn, 20.0)
		await _frames(3)
		var shown1 = arn.get("shown_hp")
		_check("body hits do not move shown_hp until a mirror breaks",
			shown0 != null and shown1 != null and absf(float(shown1) - float(shown0)) < 0.01 and float(arn.get("hp")) < amax,
			"shown %.0f -> %.0f real %.0f/%.0f" % [float(shown0), float(shown1), float(arn.get("hp")), amax])
		var stored = arn.get("stored")
		_check("the stored damage is kept", stored != null and float(stored) >= 39.0, "stored=%s" % str(stored))
		if arn.has_method("debug_break_mirror"):
			arn.call("debug_break_mirror")
			await _frames(5)
		var shown2 = arn.get("shown_hp")
		_check("breaking a mirror applies the stored damage", shown2 != null and float(shown2) <= float(shown1) - 39.0,
			"shown %.0f -> %.0f stored=%s" % [float(shown1), float(shown2), str(stored)])
		arn.set("hp", amax * 0.65)
		await _frames(3)
		var a2 := int(arn.call("stage"))
		arn.set("hp", amax * 0.32)
		await _frames(3)
		var a3 := int(arn.call("stage"))
		var cracked = arn.get("visor_cracked")
		_check("stages change at 66 and 33 percent and the visor cracks at stage 3",
			a2 == 2 and a3 == 3 and cracked == true, "stage2=%d stage3=%d cracked=%s" % [a2, a3, str(cracked)])
		var w3 := _w()
		var db = _sys("dialog_box")
		var intro_ok := db != null and bool(db.get("active"))
		_check("the intro dialogue is shown", intro_ok, "dialog active=%s" % str(intro_ok))
		var shifted0: bool = bool(G.get("shifted")) if G.get("shifted") != null else false
		_hit(arn, 99999.0)
		var died := await _wait_until(_pred_dead.bind(arn), 1200)
		await _frames(30)
		var shifted1: bool = bool(G.get("shifted")) if G.get("shifted") != null else false
		var sheet = w3.get("sheet") if w3 != null else ""
		var visor_ok := _loot_has("visor")
		var term_ok: bool = r != null and bool(r.call("refill_at_terminal"))
		_check("her death ends the shift, sheet restored, visor present, terminals work",
			died and shifted1 == false and String(sheet) == "restored" and visor_ok and term_ok,
			"alive=%s shifted %s->%s sheet=%s visor=%s terminal=%s" % [str(arn.get("alive")), str(shifted0), str(shifted1), str(sheet), str(visor_ok), str(term_ok)])
	else:
		_check("dialogue.json holds arnetria_intro", dlg_ok, str(dlg_ok))
		_check("body hits do not move shown_hp until a mirror breaks", false, "no arnetria boss")
		_check("the stored damage is kept", false, "no boss")
		_check("breaking a mirror applies the stored damage", false, "no boss")
		_check("stages change at 66 and 33 percent and the visor cracks at stage 3", false, "no boss")
		_check("the intro dialogue is shown", false, "no boss")
		_check("her death ends the shift, sheet restored, visor present, terminals work", false, "no boss")

	# ======================= S8: RECALL and REBUILD HERE =======================
	var recall = _sys("recall")
	if recall == null:
		_check("RECALL is offered only with a beaten boss and no shift", false, "no recall system")
		_check("a recall win records the best time and adds the XP share", false, "no recall")
		_check("a recall loss shows no OFFLINE screen and restores the snapshot", false, "no recall")
		_check("END RECALL appears while a recall runs", false, "no recall")
		_check("REBUILD HERE needs the module and a charge", false, "no recall")
	else:
		var opts0 = recall.call("options") if recall.has_method("options") else []
		_check("RECALL offers nothing before a boss is beaten", opts0 is Array and (opts0 as Array).is_empty(), str(opts0))
		var w4 := _w()
		if w4 != null and w4.has_method("set_flag"):
			w4.call("set_flag", "beaten_pallbearer", true)
		if w4 != null and w4.has_method("start_shift"):
			w4.call("start_shift")
			await _frames(5)
			var opts_shift = recall.call("options") if recall.has_method("options") else []
			w4.call("end_shift")
			await _frames(5)
			var opts_after = recall.call("options") if recall.has_method("options") else []
			var has_pb := false
			if opts_after is Array:
				for o in opts_after:
					var oid := ""
					if o is Dictionary:
						oid = String(o.get("id", o.get("boss", "")))
					elif o is String:
						oid = o
					if oid == "pallbearer":
						has_pb = true
			_check("RECALL is offered only with a beaten boss and no shift",
				(opts_shift is Array and (opts_shift as Array).is_empty()) and has_pb,
				"shifted=%s after=%s" % [str(opts_shift), str(opts_after)])
		var arena = _sys("arena")
		var win_bad := ""
		if recall.has_method("start") and arena != null:
			recall.call("start", "pallbearer")
			await _frames(5)
			var active: bool = bool(recall.get("active"))
			var mode = arena.get("mode")
			arena.set("fight_time", 10.0)
			if arena.has_method("debug_win"):
				arena.call("debug_win")
			await _frames(10)
			var best1 = w4.get("best_times") if w4 != null else null
			var best_after := -1.0
			if best1 is Dictionary and (best1 as Dictionary).has("pallbearer"):
				best_after = float((best1 as Dictionary)["pallbearer"])
			var xp_a := 0
			if r != null:
				xp_a = int(r.get("xp"))
			arena.set("fight_time", 20.0)
			arena.call("debug_win")
			await _frames(10)
			var best2 = w4.get("best_times") if w4 != null else null
			var best_final := -1.0
			if best2 is Dictionary and (best2 as Dictionary).has("pallbearer"):
				best_final = float((best2 as Dictionary)["pallbearer"])
			var share: float = _tv("recall_xp_share", "recall_xp_mult")
			var want_xp := -999999
			if not is_nan(share) and not is_nan(_tv("xp_pallbearer")):
				want_xp = int(round(_tv("xp_pallbearer") * share))
			var xp_gain := -1
			if r != null:
				xp_gain = int(r.get("xp")) - xp_a
			if not active:
				win_bad = "not active"
			elif String(mode) != "recall":
				win_bad = "arena mode=%s" % str(mode)
			elif absf(best_after - 10.0) > 0.5:
				win_bad = "best after first win=%s" % str(best_after)
			elif absf(best_final - 10.0) > 0.5:
				win_bad = "a slower win changed the best time (%s)" % str(best_final)
			elif xp_gain != want_xp:
				win_bad = "xp gain %d want %d" % [xp_gain, want_xp]
			_check("a recall win records the best time and adds the XP share", win_bad == "",
				"%s (best=%.1f xp+%d)" % [win_bad, best_final, xp_gain])
			# a loss shows no OFFLINE screen, restores the snapshot and puts her at the terminal
			if w4 != null and w4.has_method("set_flag"):
				w4.call("set_flag", "probe_recall", true)
			recall.call("start", "pallbearer")
			await _frames(5)
			if w4 != null and w4.has_method("set_flag"):
				w4.call("set_flag", "probe_recall", false)
			recall.call("end", false)
			await _frames(10)
			var offline = _sys("offline")
			var off_inactive: bool = offline == null or not bool(offline.get("active"))
			var canary: bool = w4 != null and w4.has_method("flag") and bool(w4.call("flag", "probe_recall"))
			var at_terminal: bool = main != null and String(main.get("room_name")) == "vault"
			_check("a recall loss shows no OFFLINE screen, restores the snapshot and puts her at the terminal",
				off_inactive and canary and at_terminal,
				"offline=%s canary=%s room=%s" % [str(off_inactive), str(canary), str(main.get("room_name")) if main != null else "?"])
			# END RECALL shows while a recall runs
			var menu = _sys("menu")
			var end_row := false
			recall.call("start", "pallbearer")
			await _frames(5)
			if menu != null:
				menu.call("open", "SYSTEM")
				await _pframes(4)
				var rows = menu.call("debug_rows")
				var joined := ""
				if rows is Array:
					for x in rows:
						joined += String(x) + " "
				end_row = joined.contains("END RECALL")
				menu.call("close")
				await _pframes(3)
			recall.call("end", false)
			await _frames(5)
			_check("END RECALL appears while a recall runs", end_row, "row=%s" % str(end_row))
		else:
			_check("a recall win records the best time and adds the XP share", false, "no arena or start()")
			_check("a recall loss shows no OFFLINE screen and restores the snapshot", false, "no recall.start")
		# REBUILD HERE
		var can0: bool = bool(recall.call("can_rebuild")) if recall.has_method("can_rebuild") else false
		if r != null and r.has_method("set_owned"):
			r.call("set_owned", "restore_module", true)
		var can1: bool = bool(recall.call("can_rebuild")) if recall.has_method("can_rebuild") else false
		var rebuilt_ok := false
		var room_before := String(main.get("room_name")) if main != null else ""
		if can1 and main != null and main.get("player") != null:
			var pl: Node = main.get("player")
			if pl.has_method("debug_set"):
				pl.call("debug_set", {"hp": 0.0})
			if recall.has_method("rebuild_here"):
				recall.call("rebuild_here")
				await _frames(10)
			var max_hp: float = float(r.call("max_hp"))
			var hp_now: float = float(pl.get("hp"))
			var share2: float = _tv("rebuild_hp_share")
			if is_nan(share2):
				share2 = 0.5
			var same_room := String(main.get("room_name")) == room_before
			rebuilt_ok = absf(hp_now - max_hp * share2) <= max_hp * 0.15 + 1.0 and same_room
			_check("REBUILD HERE rebuilds her in the same room at rebuild_hp_share", rebuilt_ok,
				"hp=%.0f want~%.0f room %s->%s" % [hp_now, max_hp * share2, room_before, str(main.get("room_name"))])
			if recall.has_method("can_rebuild"):
				var used := not bool(recall.call("can_rebuild"))
				if r.has_method("refill_at_terminal"):
					r.call("refill_at_terminal")
				var refilled := bool(recall.call("can_rebuild"))
				_check("a terminal refills the rebuild charge", used and refilled, "used=%s refilled=%s" % [str(used), str(refilled)])
			else:
				_check("a terminal refills the rebuild charge", false, "no can_rebuild")
		else:
			_check("REBUILD HERE rebuilds her in the same room at rebuild_hp_share", false,
				"can_rebuild before=%s after=%s" % [str(can0), str(can1)])
			_check("a terminal refills the rebuild charge", false, "no rebuild")
		_check("REBUILD HERE needs the restore module", not can0 and can1, "before=%s after=%s" % [str(can0), str(can1)])


func _is_stun_state(st: String) -> bool:
	var s := st.to_lower()
	return s.contains("stun") or s.contains("skid") or s.contains("land")


func _pred_dead(b) -> bool:
	return b != null and b.get("alive") == false


func _pred_log3(b) -> bool:
	var lg = b.get("attack_log")
	return lg is Array and (lg as Array).size() >= 3


func _doors_sealed() -> String:
	var room: Node = main.get("room") if main != null else null
	if room == null or not (room.get("doors") is Dictionary):
		return "no room doors"
	var doors: Dictionary = room.get("doors")
	if doors.is_empty():
		return "kennel has no door nodes (the hole may be unguarded)"
	for side in doors:
		var d = doors[side]
		if bool(d.get("sealed")) or bool(d.get("locked")):
			continue
		if d.has_method("refuse") and bool(d.call("refuse")):
			continue
		return "%s not sealed (locked=%s sealed=%s)" % [side, str(d.get("locked")), str(d.get("sealed"))]
	return ""


func _loot_has(item_id: String) -> bool:
	var loot = _sys("loot")
	if loot == null:
		return false
	var live = loot.get("live")
	if live is Array:
		for it in live:
			if it != null and is_instance_valid(it) and str(it.get("item_id")) == item_id:
				return true
	return false


func _scrap_rate(kind: String) -> float:
	var lo = _sys("loot")
	var r := _r()
	r.call("debug_seed", 7)
	if main != null and main.get("player") != null and main.get("player").has_method("debug_set"):
		main.get("player").call("debug_set", {"hp": float(r.call("max_hp"))})
	var hits := 0
	for i in 500:
		var res = lo.call("roll_drops", kind, Vector2.ZERO, false)
		if res is Array:
			for it in res:
				var s := str(it.get("item", "")) if it is Dictionary else str(it)
				if s.contains("scrap"):
					hits += 1
	return float(hits) / 500.0


func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed
