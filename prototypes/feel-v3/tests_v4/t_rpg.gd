# PROTOTYPE - NOT FOR PRODUCTION
# tests_v4/t_rpg.gd - locked test (step 0, written from design/contract.md section 4 only).
# RPG behaviour on the W and R autoloads (S0): XP, levels, points, stats, Sutures, gear,
# forwarding, snapshots, award_kill, the spawner interface, main.gd size and SYSTEMS.
# Builders never edit this pack. Run: godot --headless --path . res://tests_v4/t_rpg.tscn
extends Node

var main: Node = null
var passed := 0
var failed := 0
var box: Node2D = null
var leveled_count := 0


func _ready() -> void:
	G.peace = true
	if ResourceLoader.exists("res://main.tscn"):
		main = load("res://main.tscn").instantiate()
		add_child(main)
		box = Node2D.new()
		add_child(box)
		await _frames(30)
	_r_seed()
	await _run()
	var ok := failed == 0 and passed > 0
	print("t_rpg %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
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


func _reset_all() -> void:
	var r := _r()
	var w := _w()
	if r != null and r.has_method("reset"):
		r.call("reset")
	if r != null and r.has_method("debug_seed"):
		r.call("debug_seed", 7)
	if w != null and w.has_method("debug_set"):
		w.call("debug_set", {"flags": {}, "taken": {}})


func _on_leveled(_lvl: int, _pts: int) -> void:
	leveled_count += 1


func _run() -> void:
	var r := _r()
	var w := _w()
	_check("W autoload exists", w != null, "get_node_or_null('/root/W')")
	_check("R autoload exists", r != null, "get_node_or_null('/root/R')")
	if r == null or w == null:
		return

	# --- interfaces ------------------------------------------------------------
	var w_needs := ["flag", "set_flag", "mark_taken", "is_taken", "meta", "title", "room_list", "cell_of", "snapshot", "restore", "start_shift", "end_shift", "debug_set"]
	var w_missing := []
	for m in w_needs:
		if not w.has_method(m):
			w_missing.append(m)
	for prop in ["flags", "visited", "taken", "sheet", "best_times"]:
		if w.get(prop) == null and prop != "best_times":
			w_missing.append("var " + prop)
	_check("W carries its whole public interface", w_missing.is_empty(), "missing=%s" % str(w_missing))

	var r_needs := ["max_hp", "max_en", "max_mp", "atk", "def", "special_pct", "hit_damage", "taken", "award_kill", "add_xp", "spend", "auto_allocate", "has", "set_owned", "count", "add_item", "use_item", "equip_gear", "gear_effect", "add_scrap", "refill_at_terminal", "snapshot", "restore", "reset", "debug_set", "debug_seed"]
	var r_missing := []
	for m in r_needs:
		if not r.has_method(m):
			r_missing.append(m)
	for prop in ["level", "xp", "points", "alloc", "items", "owned_gear", "equip", "scrap", "names_seen", "rng"]:
		if r.get(prop) == null and prop != "rng":
			r_missing.append("var " + prop)
	if r.get("rng") == null:
		r_missing.append("var rng")
	_check("R carries its whole public interface", r_missing.is_empty(), "missing=%s" % str(r_missing))

	# --- XP and levels ---------------------------------------------------------
	_reset_all()
	leveled_count = 0
	if r.has_signal("leveled"):
		r.connect("leveled", _on_leveled)
	var lvl0: int = int(r.get("level"))
	if lvl0 != 1:
		_check("R.reset() starts her at level 1 with 0 points", false, "level=%d points=%s" % [lvl0, str(r.get("points"))])
		return
	r.call("add_xp", 20)
	var lvl2: int = int(r.get("level"))
	var pts2: int = int(r.get("points"))
	_check("add_xp(20) at L1 gives L2, 2 points and exactly one leveled",
		lvl2 == 2 and pts2 == 2 and leveled_count == 1, "level=%d points=%d leveled=%d" % [lvl2, pts2, leveled_count])

	_reset_all()
	r.call("add_xp", 70)
	var lvl3: int = int(r.get("level"))
	_check("add_xp(70) from L1 gives L3 and 4 points", lvl3 == 3 and int(r.get("points")) == 4,
		"level=%d points=%d" % [lvl3, int(r.get("points"))])

	_reset_all()
	r.call("add_xp", 99999)
	var cap := int(_tv("level_cap"))
	_check("XP stops at level_cap", int(r.get("level")) == cap, "level=%d cap=%d" % [int(r.get("level")), cap])

	# --- the level-up refill ---------------------------------------------------
	_reset_all()
	var maxhp: float = float(r.call("max_hp"))
	var maxen: float = float(r.call("max_en"))
	var maxmp: float = float(r.call("max_mp"))
	if main != null and main.get("player") != null:
		var pl: Node = main.get("player")
		if pl.has_method("debug_set"):
			pl.call("debug_set", {"hp": 10.0, "energy": 5.0, "mp": 3.0})
	r.call("add_xp", 20)
	var php: float = float(main.get("player").get("hp")) if main != null and main.get("player") != null else 0.0
	var pen: float = float(main.get("player").get("energy")) if main != null and main.get("player") != null else 0.0
	var pmp: float = float(main.get("player").get("mp")) if main != null and main.get("player") != null else 0.0
	_check("a level-up refills HP, EN and MP", absf(php - maxhp) < 0.5 and absf(pen - maxen) < 0.5 and absf(pmp - maxmp) < 0.5,
		"hp=%.0f/%.0f en=%.0f/%.0f mp=%.0f/%.0f" % [php, maxhp, pen, maxen, pmp, maxmp])

	# --- one point gives (lead ruling 3) ---------------------------------------
	_reset_all()
	r.call("add_xp", 99999)
	var ok_v = r.call("spend", "vigor")
	var hp_gain: float = float(r.call("max_hp")) - maxhp
	_check("spend('vigor') raises max_hp by vigor_hp", bool(ok_v) and absf(hp_gain - _tv("vigor_hp", "vit_hp")) < 0.01,
		"gain=%.0f want=%.0f" % [hp_gain, _tv("vigor_hp", "vit_hp")])
	r.call("spend", "power")
	var atk: float = float(r.call("atk"))
	_check("spend('power') raises ATK to 108", absf(atk - (100.0 + _tv("power_atk", "str_atk"))) < 0.01, "atk=%.0f" % atk)
	r.call("spend", "guard")
	var dfn: float = float(r.call("def"))
	_check("spend('guard') raises DEF to 3", absf(dfn - _tv("guard_def", "end_def")) < 0.01, "def=%.0f" % dfn)
	r.call("spend", "stamina")
	var en: float = float(r.call("max_en"))
	_check("spend('stamina') raises max EN by 8", absf(en - (maxen + _tv("stamina_en", "end_en"))) < 0.01, "en=%.0f" % en)
	r.call("spend", "magic")
	var mp: float = float(r.call("max_mp"))
	var spc: float = float(r.call("special_pct"))
	_check("spend('magic') gives +6 MP and +8 percent special",
		absf(mp - (maxmp + _tv("magic_mp", "mag_mp"))) < 0.01 and absf(spc - (100.0 + _tv("magic_special", "mag_special"))) < 0.01,
		"mp=%.0f spc=%.0f" % [mp, spc])
	# spend every remaining point, then the next spend must be refused
	var drain := 0
	while int(r.get("points")) > 0 and drain < 40:
		r.call("spend", "vigor")
		drain += 1
	var spent_all: bool = not bool(r.call("spend", "vigor"))
	_check("spend with no points left is refused", spent_all, "points_left=%d" % int(r.get("points")))

	# --- AUTO ------------------------------------------------------------------
	_reset_all()
	r.call("add_xp", 90)
	r.call("auto_allocate")
	var alloc = r.get("alloc")
	var alloc_sum := 0
	if alloc is Dictionary:
		for k in alloc:
			alloc_sum += int(alloc[k])
	_check("auto_allocate spends every point in auto_order", int(r.get("points")) == 0 and alloc_sum == 6,
		"points=%d alloc_sum=%d alloc=%s" % [int(r.get("points")), alloc_sum, str(alloc)])

	# --- Sutures ---------------------------------------------------------------
	_reset_all()
	r.call("add_item", "suture", 3)
	if main != null and main.get("player") != null:
		main.get("player").set("hp", 50.0)
	var used: bool = bool(r.call("use_item", "suture"))
	var php2: float = float(main.get("player").get("hp")) if main != null and main.get("player") != null else 0.0
	_check("a Suture heals 40 and one is spent", used and absf(php2 - 90.0) < 0.5 and int(r.call("count", "suture")) == 2,
		"healed to %.0f count=%d" % [php2, int(r.call("count", "suture"))])
	if main != null and main.get("player") != null:
		main.get("player").set("hp", float(r.call("max_hp")))
	var refused: bool = not bool(r.call("use_item", "suture"))
	_check("a Suture is refused at full HP", refused and int(r.call("count", "suture")) == 2,
		"refused=%s count=%d" % [str(not refused), int(r.call("count", "suture"))])
	r.call("add_item", "suture", 99)
	var want_cap: float = _tv("suture_max")
	_check("the Suture count clamps to suture_max", absf(float(int(r.call("count", "suture"))) - want_cap) < 0.01,
		"count=%d cap=%s" % [int(r.call("count", "suture")), str(want_cap)])

	# --- gear ------------------------------------------------------------------
	_reset_all()
	var eq1: bool = bool(r.call("equip_gear", "module1", "coupler_034"))
	var hp_coupler: float = float(r.call("max_hp"))
	var want_coupler: float = maxf(100.0 + _tv("coupler_hp"), _tv("max_hp_floor"))
	var php3: float = float(main.get("player").get("hp")) if main != null and main.get("player") != null else 0.0
	_check("COUPLER-034 drops max HP to 60 and clamps her current HP",
		eq1 and absf(hp_coupler - want_coupler) < 0.01 and php3 <= hp_coupler + 0.01,
		"max=%.0f want=%.0f hp=%.0f" % [hp_coupler, want_coupler, php3])
	var off: bool = bool(r.call("equip_gear", "module1", ""))
	var hp_back: float = float(r.call("max_hp"))
	var php4: float = float(main.get("player").get("hp")) if main != null and main.get("player") != null else 0.0
	_check("unequipping never heals her", off and absf(hp_back - 100.0) < 0.01 and absf(php4 - php3) < 0.01,
		"max=%.0f hp=%.0f -> %.0f" % [hp_back, php3, php4])
	var floor_ok := true
	for probe in [["module1", "coupler_034"], ["module2", "governor_207"]]:
		r.call("equip_gear", probe[0], probe[1])
		if float(r.call("max_hp")) < _tv("max_hp_floor") - 0.01:
			floor_ok = false
	_check("the max HP floor holds", floor_ok and _tv("max_hp_floor") == 50.0, "floor=%s" % str(_tv("max_hp_floor")))
	r.call("equip_gear", "module1", "")
	r.call("equip_gear", "module2", "")

	# one DRIVE id at a time: COUPLER and REGULATOR never add up
	r.call("equip_gear", "module1", "coupler_034")
	r.call("equip_gear", "module2", "regulator_000")
	var eq = r.get("equip")
	var drive_ids := []
	if eq is Dictionary:
		for slot in ["module1", "module2"]:
			var sid = eq.get(slot, "")
			if sid == "coupler_034" or sid == "regulator_000":
				drive_ids.append(sid)
	var add: float = float(r.call("gear_effect", "atk_add_key"))
	_check("two DRIVE modules never add up (one id fits one slot)",
		drive_ids.size() <= 1 and add <= maxf(_tv("coupler_damage"), _tv("regulator_damage")) + 0.01,
		"drive=%s atk_add=%.0f" % [str(drive_ids), add])
	r.call("equip_gear", "module1", "")
	r.call("equip_gear", "module2", "")

	var wrong1: bool = bool(r.call("equip_gear", "harness1", "coupler_034"))
	var wrong2: bool = bool(r.call("equip_gear", "module1", "cerement_112"))
	var wrong3: bool = bool(r.call("equip_gear", "module1", "restore_module"))
	_check("a module will not go in a harness slot and the restore module has no slot",
		not wrong1 and not wrong2 and not wrong3, "harness1=%s module1(harness)=%s module1(core)=%s" % [str(wrong1), str(wrong2), str(wrong3)])
	var hok: bool = bool(r.call("equip_gear", "harness1", "cerement_112"))
	_check("a harness fits its harness slot", hok, "equip_gear('harness1','cerement_112')")

	# --- forwarding ------------------------------------------------------------
	_reset_all()
	var fwd_bad := []
	if main != null:
		if main.get("has_elegy") == null:
			fwd_bad.append("main.has_elegy missing")
		else:
			main.set("has_elegy", true)
			if not bool(r.call("has", "elegy_013")):
				fwd_bad.append("elegy not forwarded")
		if main.get("lever_library") == null:
			fwd_bad.append("main.lever_library missing")
		else:
			main.set("lever_library", true)
			if not bool(w.call("flag", "lever_library")):
				fwd_bad.append("lever flag not forwarded")
	_check("main.has_elegy reaches R.has and main.lever_library reaches W.flag", fwd_bad.is_empty(), str(fwd_bad))

	# --- snapshot / restore round trips ----------------------------------------
	_reset_all()
	var s1 = w.call("snapshot")
	w.call("set_flag", "probe_x", true)
	w.call("mark_taken", "church", "1")
	w.call("restore", s1)
	_check("W snapshot/restore round trip", not bool(w.call("flag", "probe_x")), "flag after restore")
	var s2 = r.call("snapshot")
	r.call("add_xp", 50)
	r.call("add_item", "suture", 5)
	r.call("restore", s2)
	_check("R snapshot/restore round trip", int(r.get("level")) == 1 and int(r.call("count", "suture")) == 0,
		"level=%d suture=%d" % [int(r.get("level")), int(r.call("count", "suture"))])

	# --- award_kill ------------------------------------------------------------
	_reset_all()
	var xp0: int = int(r.get("xp"))
	var d1: int = int(r.call("award_kill", "ghost", false))
	var d2: int = int(r.call("award_kill", "ghost", true))
	var want_xp := _tv("xp_ghost")
	var want_back: float = ceilf(want_xp * _tv("xp_respawn_mult"))
	_check("award_kill gives xp_ghost, half rounded up for respawned",
		d1 == int(want_xp) and d2 == int(want_back),
		"normal=%d want=%.0f respawned=%d want=%.0f" % [d1, want_xp, d2, want_back])

	# --- spawner ---------------------------------------------------------------
	var sp = _sys("spawner")
	_check("main holds a spawner system", sp != null, "no spawner on main")
	if sp != null and sp.has_method("enemy"):
		var kinds := ["ghost", "leech", "spitter", "hound", "choir", "moth", "scribe", "crab", "warden"]
		var spawn_bad := []
		for k in kinds:
			var spawned = sp.call("enemy", k, Vector2(0, 0))
			if spawned == null:
				spawn_bad.append(k + " null")
			elif spawned is Node:
				box.add_child(spawned)
		_check("spawner.enemy returns a node for every enemies.json id", spawn_bad.is_empty(), str(spawn_bad))
		var ghost = sp.call("enemy", "ghost", Vector2(0, 0))
		var iface_bad := []
		if ghost == null:
			iface_bad.append("no ghost")
		else:
			box.add_child(ghost)
			for m in ["setup", "hurt_rect", "can_hurt", "damage", "touched_player", "take_hit"]:
				if not ghost.has_method(m):
					iface_bad.append(m)
			for prop in ["kind", "hp"]:
				if ghost.get(prop) == null:
					iface_bad.append("var " + prop)
		_check("the enemy interface is complete", iface_bad.is_empty(), str(iface_bad))

	# --- main.gd size and SYSTEMS ----------------------------------------------
	var lines := 0
	var f := FileAccess.open("res://main.gd", FileAccess.READ)
	if f != null:
		while not f.eof_reached():
			f.get_line()
			lines += 1
		f.close()
	_check("main.gd has 600 lines or fewer", lines <= 600 and lines > 0, "lines=%d" % lines)

	var systems = main.get("SYSTEMS") if main != null else null
	var sys_bad := []
	if systems is Dictionary:
		for nm in systems:
			var entry = systems[nm]
			var path := ""
			if entry is String:
				path = entry
			elif entry is Dictionary and entry.has("file"):
				path = str(entry["file"])
			if path == "":
				sys_bad.append(nm + " no file")
			elif ResourceLoader.exists(path):
				var node = main.get(String(nm))
				if node == null:
					node = main.get_node_or_null(NodePath(String(nm)))
				if node == null:
					sys_bad.append(String(nm) + " not created")
	else:
		sys_bad.append("SYSTEMS is not a dictionary")
	_check("every SYSTEMS entry whose file exists is created", sys_bad.is_empty(), str(sys_bad))
