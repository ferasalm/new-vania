# PROTOTYPE - NOT FOR PRODUCTION
# tests_v4/t_data.gd - locked test (step 0, written from design/contract.md section 4 only).
# Static files: tuning integrity (6 fields, min<=value<=max, no duplicates), the S0 tuning
# values, and the data file stubs (items, gear, enemies, levels, rooms_meta).
# Builders never edit this pack. Run: godot --headless --path . res://tests_v4/t_data.tscn
extends Node

const GEAR_EFFECTS := ["atk_add_key", "def_add_key", "hp_max_add_key", "en_max_add_key", "mp_max_add_key", "mag_add_key", "orb_reach_add_key", "scrap_gain_mult_key", "rebuild_here_key"]
const EXIT_KINDS := ["door", "open", "hole", "tunnel", "lever_door", "boss_door", "sealed_x", "shutter", "bricked"]
const MARK_TYPES := ["item", "lever", "winch", "candle", "terminal", "organ", "talk", "boss"]
const ITEM_TYPES := ["consumable", "key", "ability", "weapon", "gear", "orb", "material"]
# Automatic leveling (user decision 2026-11-20): four growth entries, and the old manual-allocation keys are gone.
const GROWTH_IDS := ["hp", "en", "atk", "def"]
const GONE_KEYS := ["points_per_level", "vigor_hp", "power_atk", "guard_def", "stamina_en", "magic_special", "magic_mp"]

var main: Node = null
var passed := 0
var failed := 0


func _ready() -> void:
	G.peace = true
	if ResourceLoader.exists("res://main.tscn"):
		main = load("res://main.tscn").instantiate()
		add_child(main)
		await _frames(30)
	_r_seed()
	await _run()
	var ok := failed == 0 and passed > 0
	print("t_data %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
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


# Numbers come through T.v; keys may exist under the rpg-items v2 name or the contract's
# older name, so each read accepts a fallback. A missing key reads as NAN and fails.
func _tv(key: String, alt := "") -> float:
	if T.data.has(key):
		return T.v(key)
	if alt != "" and T.data.has(alt):
		return T.v(alt)
	return NAN


func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed


func _tuning_sources() -> Array:
	var out := []
	var tj = _read_json("res://tuning.json")
	if tj is Dictionary:
		out.append(["tuning.json", tj])
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://tuning.d")):
		var d := DirAccess.open("res://tuning.d")
		if d != null:
			d.list_dir_begin()
			var nm := d.get_next()
			while nm != "":
				if not d.current_is_dir() and nm.ends_with(".json"):
					var j = _read_json("res://tuning.d/" + nm)
					if j is Dictionary:
						out.append(["tuning.d/" + nm, j])
				nm = d.get_next()
	return out


func _merged_tuning() -> Dictionary:
	var merged := {}
	for src in _tuning_sources():
		var d: Dictionary = src[1]
		for k in d:
			merged[k] = d[k]
	return merged


func _run() -> void:
	# --- tuning integrity ------------------------------------------------------
	var sources := _tuning_sources()
	var merged := _merged_tuning()
	var bad_fields := []
	for k in merged:
		var e = merged[k]
		if not (e is Dictionary):
			bad_fields.append("%s not a table" % k)
			continue
		for fld in ["value", "min", "max", "step", "label", "help"]:
			if not e.has(fld):
				bad_fields.append("%s missing %s" % [k, fld])
		if e.has("value") and e.has("min") and e.has("max"):
			if not (float(e["min"]) <= float(e["value"]) and float(e["value"]) <= float(e["max"])):
				bad_fields.append("%s out of range" % k)
	_check("every tuning key has 6 fields and min <= value <= max", bad_fields.is_empty(),
		"keys=%d bad=%s" % [merged.size(), str(bad_fields.slice(0, 6))])

	var dupes := []
	var seen := {}
	for src in sources:
		var text := ""
		var f := FileAccess.open("res://" + String(src[0]), FileAccess.READ)
		if f != null:
			text = f.get_as_text()
			f.close()
		var lines := text.split("\n")
		for ln in lines:
			if ln.begins_with("  \"") and ln.contains("\": {"):
				var k := ln.strip_edges()
				k = k.substr(1, k.find("\":") - 1)
				var where := String(src[0])
				if seen.has(k):
					dupes.append(k)
				else:
					seen[k] = where
	_check("no tuning key appears twice", dupes.is_empty(), "dupes=%s" % str(dupes))

	var tdata = T.get("data")
	var tdata_ok := tdata is Dictionary
	var tdata_missing := []
	if tdata is Dictionary:
		for k in merged:
			if not tdata.has(k):
				tdata_missing.append(k)
	_check("T.data holds every tuning key", tdata_ok and tdata_missing.is_empty(),
		"tdata=%s missing=%s" % ["yes" if tdata_ok else "no", str(tdata_missing.slice(0, 6))])

	# --- S0 tuning values ------------------------------------------------------
	# Level growth (user decision 2026-11-20): the numbers are tuned by playing, so only "above 0" is pinned.
	var growth_keys := ["level_hp", "level_en", "level_atk", "level_def"]
	var gain_bad := []
	for gk in growth_keys:
		if not (_tv(gk) > 0.0):
			gain_bad.append("%s=%s" % [gk, str(_tv(gk))])
	_check("every level raises HP, EN, ATK and DEF (gain above 0)", gain_bad.is_empty(), str(gain_bad))
	var gone_left := []
	for gk in GONE_KEYS:
		if T.data.has(gk):
			gone_left.append(gk)
	_check("no points, MAGIC or AUTO keys remain in tuning", gone_left.is_empty(), str(gone_left))
	_check("highest level is 10", _tv("level_cap") == 10.0, "level_cap=%s" % str(_tv("level_cap")))
	_check("the XP curve step is 10", _tv("xp_curve_step") == 10.0, "xp_curve_step=%s" % str(_tv("xp_curve_step")))
	_check("DEF stops at 40", _tv("def_cap") == 40.0, "def_cap=%s" % str(_tv("def_cap")))
	_check("max HP never drops below 50", _tv("max_hp_floor") == 50.0, "max_hp_floor=%s" % str(_tv("max_hp_floor")))
	_check("a level-up refills HP, EN and MP", _tv("levelup_refill") == 1.0, "levelup_refill=%s" % str(_tv("levelup_refill")))
	_check("ordinary enemy damage is 0.75 of its value", _tv("area_damage_mult") == 0.75, "area_damage_mult=%s" % str(_tv("area_damage_mult")))
	_check("respawned enemies give half XP", _tv("xp_respawn_mult") == 0.5, "xp_respawn_mult=%s" % str(_tv("xp_respawn_mult")))

	var want_xp := {"xp_ghost": 3.0, "xp_hound": 3.0, "xp_spitter": 3.0, "xp_leech": 4.0, "xp_choir": 6.0, "xp_moth": 7.0, "xp_scribe": 10.0, "xp_crab": 12.0, "xp_warden": 14.0, "xp_boss": 50.0, "xp_unmuzzled": 30.0, "xp_arnetria": 80.0}
	var bad_xp := []
	for k in want_xp:
		if not T.data.has(k):
			bad_xp.append("missing " + k)
		elif T.v(k) != want_xp[k]:
			bad_xp.append("%s=%s" % [k, str(T.v(k))])
	_check("every enemy has its XP key", bad_xp.is_empty(), str(bad_xp))
	_check("a Suture heals 40", _tv("suture_heal") == 40.0, "suture_heal=%s" % str(_tv("suture_heal")))
	_check("she can carry every Suture that exists (8)", _tv("suture_max") >= 8.0, "suture_max=%s" % str(_tv("suture_max")))
	var gear_bad := []
	if _tv("coupler_damage") != 5.0:
		gear_bad.append("coupler_damage=%s" % str(_tv("coupler_damage")))
	if _tv("coupler_hp") != -40.0:
		gear_bad.append("coupler_hp=%s" % str(_tv("coupler_hp")))
	if _tv("governor_hp") != 10.0:
		gear_bad.append("governor_hp=%s" % str(_tv("governor_hp")))
	if _tv("regulator_damage") != 5.0:
		gear_bad.append("regulator_damage=%s" % str(_tv("regulator_damage")))
	_check("the four gear tuning values are right", gear_bad.is_empty(), str(gear_bad))

	# --- data/items.json -------------------------------------------------------
	var items = _read_json("res://data/items.json")
	_check("data/items.json exists and parses", items is Dictionary, "found %s" % ("table" if items is Dictionary else "nothing"))
	var want_items := ["suture", "lexicon_core", "wall_jump", "elegy_013", "soul_orb", "scrap"]
	var missing_items := []
	if items is Dictionary:
		for k in want_items:
			if not items.has(k):
				missing_items.append(k)
	_check("items.json holds the six S0 stub ids", missing_items.is_empty(), "missing=%s" % str(missing_items))
	if items is Dictionary and items.has("suture"):
		var s: Dictionary = items["suture"]
		var sbad := []
		for fld in ["name", "tag", "type", "desc", "effect", "icon"]:
			if not s.has(fld):
				sbad.append("missing " + fld)
		if s.get("type", "") != "consumable":
			sbad.append("type=%s" % str(s.get("type")))
		if s.get("max_key", "") != "suture_max":
			sbad.append("max_key=%s" % str(s.get("max_key")))
		if not (s.has("use") and s["use"] is Dictionary and s["use"].get("heal_hp_key", "") == "suture_heal"):
			sbad.append("use.heal_hp_key wrong")
		if s.get("touch_take", true) != false:
			sbad.append("touch_take must be false (Up takes it)")
		if s.get("refill_at_terminal", true) != false:
			sbad.append("refill_at_terminal must be false: Sutures are NEVER refilled (lead ruling 1)")
		_check("the SUTURE entry follows the schema and ruling 1", sbad.is_empty(), str(sbad))
	var grants_bad := []
	if items is Dictionary:
		if not (items.has("lexicon_core") and items["lexicon_core"] is Dictionary and items["lexicon_core"].get("grants", "") == "lexicon_core"):
			grants_bad.append("lexicon_core grants wrong")
		if not (items.has("wall_jump") and items["wall_jump"] is Dictionary and items["wall_jump"].get("grants", "") == "wall_jump"):
			grants_bad.append("wall_jump grants wrong")
	_check("abilities grant themselves to R.has()", grants_bad.is_empty(), str(grants_bad))
	var touch_bad := []
	if items is Dictionary:
		if not (items.has("soul_orb") and items["soul_orb"].get("type", "") == "orb" and items["soul_orb"].get("touch_take", false) == true):
			touch_bad.append("soul_orb")
		if not (items.has("scrap") and items["scrap"].get("type", "") == "material" and items["scrap"].get("touch_take", false) == true):
			touch_bad.append("scrap")
	_check("soul orbs and scrap are touch items", touch_bad.is_empty(), str(touch_bad))

	# --- data/gear.json --------------------------------------------------------
	var gear = _read_json("res://data/gear.json")
	_check("data/gear.json exists and parses", gear is Dictionary, "found %s" % ("table" if gear is Dictionary else "nothing"))
	var want_gear := ["coupler_034", "governor_207", "regulator_000", "cerement_112", "pall_090", "tether_06"]
	var gear_missing := []
	if gear is Dictionary:
		for k in want_gear:
			if not gear.has(k):
				gear_missing.append(k)
		if not (gear.has("restore_module") or gear.has("restore_unit")):
			gear_missing.append("restore_module")
	_check("gear.json holds the rpg-items v2 pieces", gear_missing.is_empty(), "missing=%s" % str(gear_missing))
	var effects_bad := []
	var keyrefs_bad := []
	if gear is Dictionary:
		for gid in gear:
			var g = gear[gid]
			if not (g is Dictionary and g.has("effects") and g["effects"] is Dictionary):
				continue
			for eff in g["effects"]:
				if not GEAR_EFFECTS.has(eff):
					effects_bad.append("%s.%s" % [gid, eff])
				var tkey := str(g["effects"][eff])
				if tkey != "" and not T.data.has(tkey):
					keyrefs_bad.append("%s -> %s" % [gid, tkey])
	_check("every gear effect is in the closed list", effects_bad.is_empty(), str(effects_bad))
	_check("every gear effect points at a real tuning key", keyrefs_bad.is_empty(), str(keyrefs_bad))

	# --- data/enemies.json -----------------------------------------------------
	var enemies = _read_json("res://data/enemies.json")
	_check("data/enemies.json exists and parses", enemies is Dictionary, "found %s" % ("table" if enemies is Dictionary else "nothing"))
	var want_enemies := ["ghost", "leech", "spitter", "hound", "choir", "moth", "scribe", "crab", "warden"]
	var enemies_missing := []
	if enemies is Dictionary:
		for k in want_enemies:
			if not enemies.has(k):
				enemies_missing.append(k)
	_check("enemies.json holds the nine ordinary enemies", enemies_missing.is_empty(), "missing=%s" % str(enemies_missing))
	var boss_bad := []
	if enemies is Dictionary:
		if enemies.has("pallbearer"):
			var pb: Dictionary = enemies["pallbearer"]
			if pb.get("boss", false) != true or pb.get("reward", "") != "elegy_013" or pb.get("flag", "") != "beaten_pallbearer":
				boss_bad.append("pallbearer")
		else:
			boss_bad.append("pallbearer missing")
		if enemies.has("unmuzzled"):
			if enemies["unmuzzled"].get("reward", "") != "wall_jump":
				boss_bad.append("unmuzzled.reward")
		else:
			boss_bad.append("unmuzzled missing")
		if not enemies.has("arnetria"):
			boss_bad.append("arnetria missing")
	_check("the three bosses are in enemies.json with their rewards", boss_bad.is_empty(), str(boss_bad))
	var xp_bad := []
	var drop_bad := []
	var weak_bad := []
	var schema_bad := []
	if enemies is Dictionary and items is Dictionary:
		for eid in enemies:
			var e = enemies[eid]
			if not (e is Dictionary):
				continue
			for fld in ["name", "kind", "boss", "script", "xp_key", "weak", "drops", "bestiary"]:
				if not e.has(fld) and not e.has("glyph"):
					schema_bad.append("%s missing %s" % [eid, fld])
			var xk := str(e.get("xp_key", ""))
			if xk != "" and not T.data.has(xk):
				xp_bad.append("%s -> %s" % [eid, xk])
			if not (e.get("kind", "") in ["spirit", "machine", "cyborg", "organic"]):
				schema_bad.append("%s kind=%s" % [eid, str(e.get("kind"))])
			for d in e.get("drops", []):
				if d is Dictionary and d.has("item") and not items.has(str(d["item"])):
					drop_bad.append("%s drops %s" % [eid, str(d["item"])])
		for weak_id in ["ghost", "leech", "spitter", "hound"]:
			if enemies.has(weak_id) and enemies[weak_id].get("weak", null) != true:
				weak_bad.append(weak_id + " must be weak")
		for re_id in ["choir", "moth", "scribe", "crab", "warden"]:
			if enemies.has(re_id) and enemies[re_id].get("weak", null) != false:
				weak_bad.append(re_id + " must come back on re-entry")
	_check("every enemy xp_key exists in T.data", xp_bad.is_empty(), str(xp_bad))
	_check("every drop item exists in items.json", drop_bad.is_empty(), str(drop_bad))
	_check("weak flags follow rpg-items 3.5", weak_bad.is_empty(), str(weak_bad))
	_check("enemy entries carry the schema fields", schema_bad.is_empty(), str(schema_bad.slice(0, 6)))

	# --- data/levels.json ------------------------------------------------------
	var levels = _read_json("res://data/levels.json")
	_check("data/levels.json exists and parses", levels is Dictionary, "found %s" % ("table" if levels is Dictionary else "nothing"))
	var base_bad := []
	if levels is Dictionary and levels.has("base"):
		var b: Dictionary = levels["base"]
		if b.get("hp_max_key", "") != "player_hp":
			base_bad.append("hp_max_key=%s" % str(b.get("hp_max_key")))
		if b.get("en_max_key", "") != "energy_max":
			base_bad.append("en_max_key=%s" % str(b.get("en_max_key")))
		if b.get("mp_max_key", "") != "mp_max":
			base_bad.append("mp_max_key=%s" % str(b.get("mp_max_key")))
	else:
		base_bad.append("base missing")
	_check("levels.json base points at the real tuning keys", base_bad.is_empty(), str(base_bad))
	var growth_ids := []
	if levels is Dictionary and levels.has("growth") and levels["growth"] is Dictionary:
		growth_ids = levels["growth"].keys()
	var growth_ids_ok := growth_ids.size() == GROWTH_IDS.size()
	if growth_ids_ok:
		for gid in GROWTH_IDS:
			if not growth_ids.has(gid):
				growth_ids_ok = false
	_check("levels.json growth names HP, EN, ATK and DEF", growth_ids_ok, str(growth_ids))
	var growth_bad := []
	if levels is Dictionary and levels.has("growth") and levels["growth"] is Dictionary:
		for gid in levels["growth"]:
			var g = levels["growth"][gid]
			if not (g is Dictionary and g.has("label") and g.has("help") and g.has("key")):
				growth_bad.append("%s fields" % gid)
				continue
			if not T.data.has(str(g["key"])):
				growth_bad.append("%s -> %s missing" % [gid, str(g["key"])])
	else:
		growth_bad.append("growth missing")
	_check("every growth entry points at a real tuning key", growth_bad.is_empty(), str(growth_bad))
	var manual_left := []
	if levels is Dictionary:
		for gone in ["stats", "auto_order"]:
			if levels.has(gone):
				manual_left.append(gone)
	_check("levels.json has no stats or AUTO order (no manual allocation)", manual_left.is_empty(), str(manual_left))

	# --- data/rooms_meta.json --------------------------------------------------
	var meta = _read_json("res://data/rooms_meta.json")
	_check("data/rooms_meta.json exists and parses", meta is Dictionary, "found %s" % ("table" if meta is Dictionary else "nothing"))
	var meta_bad := []
	if meta is Dictionary:
		var ct = meta.get("cell_tiles", [])
		if not (ct is Array and ct.size() == 2 and int(ct[0]) == 24 and int(ct[1]) == 14):
			meta_bad.append("cell_tiles=%s" % str(ct))
		for sh in ["before", "after", "restored"]:
			if not meta.has("sheets") or not (meta["sheets"] is Dictionary) or not meta["sheets"].has(sh):
				meta_bad.append("missing sheet " + sh)
		var before = meta.get("sheets", {}).get("before", {})
		if before is Dictionary:
			if before.size() < 10:
				meta_bad.append("before has %d rooms, needs the 10 of today" % before.size())
			for fid in before:
				var rm = before[fid]
				if not (rm is Dictionary):
					continue
				for fld in ["code", "title", "cell", "entry", "save", "music", "exits", "marks"]:
					if not rm.has(fld):
						meta_bad.append("%s missing %s" % [fid, fld])
				var cell = rm.get("cell", [])
				if not (cell is Array and cell.size() == 4):
					meta_bad.append("%s cell shape" % fid)
				for ex in rm.get("exits", []):
					if not (ex is Dictionary and ex.has("side") and ex.has("at") and ex.has("to") and ex.has("kind")):
						meta_bad.append("%s exit shape" % fid)
						continue
					if not ["L", "R", "U", "D"].has(str(ex["side"])):
						meta_bad.append("%s side %s" % [fid, str(ex["side"])])
					if not EXIT_KINDS.has(str(ex["kind"])):
						meta_bad.append("%s kind %s" % [fid, str(ex["kind"])])
				for mk in rm.get("marks", {}):
					var m = rm["marks"][mk]
					if m is Dictionary and not MARK_TYPES.has(str(m.get("type", ""))):
						meta_bad.append("%s mark %s type %s" % [fid, mk, str(m.get("type"))])
		else:
			meta_bad.append("before sheet is not a table")
	_check("rooms_meta.json follows the schema (cell_tiles, sheets, fields, exits, marks)", meta_bad.is_empty(), str(meta_bad.slice(0, 6)))
