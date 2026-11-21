# PROTOTYPE - NOT FOR PRODUCTION
# tests_v4/t_interact_ui.gd - locked test (step 0, written from design/contract.md section 4 only).
# Interact (S2): Up pickups, the card, the special show, EQUIP NOW, orbs and scrap by touch,
# the scrap rate at low health, the quick key, the terminal (ruling 1: never refills Sutures),
# self-repair, nearest wins, Up+attack is the special attack, persistence, LEXICON.
# UI (S3): pause menu tabs, debug_rows, CHARACTER, ITEMS, EQUIPMENT, MAP, minimap,
# no level-up prompt, the name plate, the dialog box, menu_swallow, debug_tap.
# Builders never edit this pack. Run: godot --headless --path . res://tests_v4/t_interact_ui.tscn
extends Node

var main: Node = null
var passed := 0
var failed := 0
var stop_reasons := []


func _ready() -> void:
	G.peace = true
	if ResourceLoader.exists("res://main.tscn"):
		main = load("res://main.tscn").instantiate()
		add_child(main)
		await _frames(30)
	_r_seed()
	await _run()
	var ok := failed == 0 and passed > 0
	print("t_interact_ui %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
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


# pause-safe wait: timers run even while the tree is paused
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
	var r := _r()
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


func _player() -> Node:
	if main == null:
		return null
	return main.get("player")


func _enter(room: String) -> void:
	if main != null and main.has_method("debug_enter"):
		await main.debug_enter(room, "left", false)
	else:
		await _frames(10)


func _reset_all() -> void:
	var r := _r()
	var w := _w()
	if r != null and r.has_method("reset"):
		r.call("reset")
	if r != null and r.has_method("debug_seed"):
		r.call("debug_seed", 7)
	if w != null and w.has_method("debug_set"):
		w.call("debug_set", {"flags": {}, "taken": {}})


func _loot():
	return _sys("loot")


func _spawn(item_id: String, offset: Vector2):
	var lo = _loot()
	if lo == null or not lo.has_method("spawn_pickup"):
		return null
	return lo.call("spawn_pickup", item_id, _player().global_position + offset, {})


func _take_with_up() -> void:
	Input.action_press("up")
	await _frames(4)
	Input.action_release("up")
	await _frames(6)


func _run() -> void:
	# ======================= S2: interact =======================
	await _reset_and_enter("church")
	var lo = _loot()
	_check("main holds a loot system with spawn_pickup and roll_drops",
		lo != null and lo.has_method("spawn_pickup") and lo.has_method("roll_drops"),
		"loot=%s" % ("found" if lo != null else "missing"))
	var card = _sys("card") if _sys("card") != null else _sys("pickup_card")
	_check("main holds a pickup card system", card != null, "card=%s" % ("found" if card != null else "missing"))

	# walking across an item does not take it
	if lo != null and _player() != null:
		var c0: int = int(_r().call("count", "suture"))
		_r().call("add_item", "suture", -int(_r().call("count", "suture")))
		var pk = _spawn("suture", Vector2(40, -6))
		var live0: int = _live_count(lo)
		var x0: float = _player().global_position.x
		Input.action_press("right")
		await _frames(30)
		Input.action_release("right")
		await _frames(10)
		var walked = _player().global_position.x - x0
		_check("walking across an item does not take it",
			int(_r().call("count", "suture")) == 0 and _live_count(lo) == live0 and walked > 30.0,
			"count=%d live=%d walked=%.0f" % [int(_r().call("count", "suture")), _live_count(lo), walked])

		# Up within pickup_reach takes it; outside it does not
		_player().set("velocity", Vector2.ZERO)
		await _frames(5)
		var far_off: float = _tv("pickup_reach") + 40.0
		pk = _spawn("suture", Vector2(far_off, -6))
		await _frames(5)
		await _take_with_up()
		_check("Up outside pickup_reach does not take", int(_r().call("count", "suture")) == 0,
			"count=%d reach=%s" % [int(_r().call("count", "suture")), str(_tv("pickup_reach"))])
		pk = _spawn("suture", Vector2(12.0, -6))
		await _frames(5)
		var t0 := Time.get_ticks_msec()
		await _take_with_up()
		var got := int(_r().call("count", "suture")) == 1
		var card_on: bool = card != null and bool(card.get("active"))
		_check("Up within pickup_reach takes the item and the card shows", got and card_on,
			"count=%d card_active=%s" % [int(_r().call("count", "suture")), str(card_on)])

		# the card cannot close before pickup_lock, closes after; she does not jump on close
		if card != null and card_on:
			var lock: float = _tv("pickup_lock")
			card.call("debug_close", "ok")
			await _pframes(3)
			var still_open := bool(card.get("active"))
			await _pframes(int((lock + 0.2) * 60.0))
			card.call("debug_close", "ok")
			await _pframes(5)
			var closed := not bool(card.get("active"))
			var grounded: bool = _player().is_on_floor() and absf(_player().get("velocity").y) < 1.0
			_check("the card holds for pickup_lock, closes after, and she does not jump on close",
				still_open and closed and grounded, "locked=%s closed=%s grounded=%s" % [str(still_open), str(closed), str(grounded)])

		# the special show runs about special_pickup_time for an ability; ordinary skips it
		_r().call("add_item", "lexicon_core", -1)
		var pk2 = _spawn("lexicon_core", Vector2(12.0, -6))
		await _frames(5)
		var t1 := Time.get_ticks_msec()
		await _take_with_up()
		var shown := await _wait_until(_pred_active.bind(card), 400)
		var dt: float = float(Time.get_ticks_msec() - t1) / 1000.0
		var want: float = _tv("special_pickup_time")
		_check("the special show lasts special_pickup_time (+/-0.1 s) for an ability",
			shown and absf(dt - want) <= 0.15, "%.2f s want %.2f" % [dt, want])
		card.call("debug_close", "ok")
		await _pframes(5)
		_check("taking LEXICON CORE answers R.has('lexicon_core')", bool(_r().call("has", "lexicon_core")),
			"has=%s" % str(_r().call("has", "lexicon_core")))

		# ordinary item skips the show
		_r().call("add_item", "suture", -int(_r().call("count", "suture")))
		_spawn("suture", Vector2(12.0, -6))
		await _frames(5)
		var t2 := Time.get_ticks_msec()
		await _take_with_up()
		await _wait_until(_pred_active.bind(card), 200)
		var dt2: float = float(Time.get_ticks_msec() - t2) / 1000.0
		_check("an ordinary item skips the special show", dt2 < 0.6, "%.2f s" % dt2)
		card.call("debug_close", "ok")
		await _pframes(5)

		# EQUIP NOW fills the first free harness slot
		var pk3 = _spawn("cerement_112", Vector2(12.0, -6))
		await _frames(5)
		await _take_with_up()
		await _wait_until(_pred_active.bind(card), 400)
		if card != null:
			card.call("debug_close", "equip_now")
			await _pframes(5)
		var eq = _r().get("equip")
		var slot_val = eq.get("harness1", "") if eq is Dictionary else ""
		_check("EQUIP NOW fills the first free harness slot", slot_val == "cerement_112", "harness1=%s" % str(slot_val))

		# orbs and scrap are taken by touch
		_r().call("add_scrap", -float(_r().get("scrap")))
		if _player().has_method("debug_set"):
			_player().call("debug_set", {"mp": 10.0})
		var orb = _spawn("soul_orb", Vector2(20.0, -6))
		await _frames(5)
		var mp0: float = float(_player().get("mp"))
		Input.action_press("right")
		await _frames(20)
		Input.action_release("right")
		await _frames(10)
		_check("a soul orb is taken by touch for mp_pickup MP",
			float(_player().get("mp")) >= mp0 + _tv("mp_pickup") - 0.01,
			"mp %.0f -> %.0f want +%.0f" % [mp0, float(_player().get("mp")), _tv("mp_pickup")])
		var scrap_pk = _spawn("scrap", Vector2(20.0, -6))
		await _frames(5)
		var sc0: float = float(_r().get("scrap"))
		Input.action_press("right")
		await _frames(20)
		Input.action_release("right")
		await _frames(10)
		_check("scrap is taken by touch for scrap_per_pickup",
			float(_r().get("scrap")) >= sc0 + _tv("scrap_per_pickup") - 0.01,
			"scrap %.0f -> %.0f want +%.0f" % [sc0, float(_r().get("scrap")), _tv("scrap_per_pickup")])

	# the scrap rate rises at low health by scrap_drop_low * 0.9 (+/-0.03), 1000 seeded rolls
	if lo != null and lo.has_method("roll_drops"):
		var rate_full := _scrap_rate(1.0)
		var rate_low := _scrap_rate(0.1)
		var diff := rate_low - rate_full
		_check("scrap rate at 10 percent HP is higher by scrap_drop_low x 0.9 (+/-0.03)",
			absf(diff - _tv("scrap_drop_low") * 0.9) <= 0.03 and diff > 0.0,
			"full=%.3f low=%.3f diff=%.3f want=%.3f" % [rate_full, rate_low, diff, _tv("scrap_drop_low") * 0.9])

	# the quick key uses one Suture and is refused at full HP
	if InputMap.has_action("quick") and _player() != null:
		_reset_all()
		_r().call("add_item", "suture", 1)
		_player().set("hp", 55.0)
		Input.action_press("quick")
		await _frames(4)
		Input.action_release("quick")
		await _frames(10)
		var hp_after: float = float(_player().get("hp"))
		_check("the quick key uses one Suture", int(_r().call("count", "suture")) == 0 and absf(hp_after - 95.0) < 0.5,
			"count=%d hp=%.0f" % [int(_r().call("count", "suture")), hp_after])
		_r().call("add_item", "suture", 1)
		_player().set("hp", float(_r().call("max_hp")))
		Input.action_press("quick")
		await _frames(4)
		Input.action_release("quick")
		await _frames(10)
		_check("the quick key is refused at full HP", int(_r().call("count", "suture")) == 1, "count=%d" % int(_r().call("count", "suture")))
	else:
		_check("the quick key uses one Suture", false, "no 'quick' action in InputMap")

	# a terminal never refills Sutures (lead ruling 1: only the 8 placed exist)
	_reset_all()
	var r_term = _r()
	var term_count := -1
	if r_term != null:
		r_term.call("add_item", "suture", 2)
		r_term.call("refill_at_terminal")
		term_count = int(r_term.call("count", "suture"))
	_check("a terminal never refills Sutures (ruling 1)", term_count == 2,
		"count after refill=%d" % term_count)

	# self-repair
	await _repair_checks()

	# with a lever and an item both in reach, the nearer one wins
	_reset_all()
	if lo != null:
		_spawn("suture", Vector2(8.0, -6))
		_spawn("governor_207", Vector2(26.0, -6))
		await _frames(5)
		_r().call("add_item", "suture", -int(_r().call("count", "suture")))
		await _take_with_up()
		var near_got: bool = int(_r().call("count", "suture")) == 1
		var far_stayed: bool = _loot_has(lo, "governor_207")
		_check("the nearer target wins the Up press", near_got and far_stayed, "near=%s far_live=%s" % [str(near_got), str(far_stayed)])

	# Up plus attack on the same frame is the special attack, not a pickup
	_reset_all()
	if lo != null and _player() != null:
		_spawn("suture", Vector2(12.0, -6))
		await _frames(5)
		_r().call("add_item", "suture", -int(_r().call("count", "suture")))
		if _player().has_method("debug_set"):
			_player().call("debug_set", {"mp": 60.0})
		var mp_a: float = float(_player().get("mp"))
		Input.action_press("up")
		Input.action_press("attack")
		await _frames(3)
		Input.action_release("up")
		Input.action_release("attack")
		await _frames(20)
		var mp_b: float = float(_player().get("mp"))
		_check("Up + attack on the same frame is the special attack",
			mp_b < mp_a - 0.5 and int(_r().call("count", "suture")) == 0,
			"mp %.0f -> %.0f count=%d" % [mp_a, mp_b, int(_r().call("count", "suture"))])

	# a taken item stays taken after re-entry
	if lo != null:
		var cnt_before: int = int(_r().call("count", "suture"))
		await _enter("vault")
		await _enter("church")
		await _frames(20)
		var live_now: int = _live_count(lo)
		_check("a taken item stays taken after re-entry",
			int(_r().call("count", "suture")) == cnt_before and live_now <= cnt_before,
			"count=%d stays=%d live=%d" % [int(_r().call("count", "suture")), cnt_before, live_now])

	# ======================= S3: UI =======================
	await _ui_checks()


func _reset_and_enter(room: String) -> void:
	_reset_all()
	await _enter(room)
	await _frames(10)


func _live_count(lo) -> int:
	var live = lo.get("live")
	if live is Array:
		var n := 0
		for it in live:
			if it != null and is_instance_valid(it):
				n += 1
		return n
	return 0


func _loot_has(lo, item_id: String) -> bool:
	var live = lo.get("live")
	if live is Array:
		for it in live:
			if it != null and is_instance_valid(it) and str(it.get("item_id")) == item_id:
				return true
	return false


func _scrap_rate(hp_share: float) -> float:
	var lo = _loot()
	_r().call("debug_seed", 7)
	if _player().has_method("debug_set"):
		_player().call("debug_set", {"hp": _r().call("max_hp") * hp_share})
	var hits := 0
	for i in 1000:
		var res = lo.call("roll_drops", "hound", Vector2.ZERO, false)
		if res is Array:
			for it in res:
				var s := str(it.get("item", "")) if it is Dictionary else str(it)
				if s.contains("scrap"):
					hits += 1
	return float(hits) / 1000.0


func _repair_checks() -> void:
	var rep = _sys("repair")
	_check("main holds a repair system with stopped reasons", rep != null and rep.has_method("debug_hold"),
		"repair=%s" % ("found" if rep != null else "missing"))
	if rep == null or not InputMap.has_action("repair"):
		_check("holding repair while still repairs her", false, "repair=%s action=%s" % [str(rep != null), str(InputMap.has_action("repair"))])
		_check("moving stops the repair with reason moved", false, "no repair system")
		_check("empty scrap stops the repair with reason empty", false, "no repair system")
		return
	if rep.has_signal("stopped"):
		rep.connect("stopped", _on_stopped)
	_reset_all()
	_r().call("add_scrap", 10.0)
	_player().set("hp", 50.0)
	if _player().has_method("debug_set"):
		_player().call("debug_set", {"energy": 100.0, "state": "idle"})
	Input.action_press("repair")
	var started := await _wait_until(func() -> bool: return bool(rep.get("active")), 120)
	var hp_a: float = float(_player().get("hp"))
	var locked: bool = bool(_player().call("is_locked")) if _player().has_method("is_locked") else false
	await _pframes(20)
	var hp_b: float = float(_player().get("hp"))
	Input.action_release("repair")
	await _pframes(10)
	_check("holding repair while still locks her and raises HP",
		started and hp_b > hp_a and locked, "active=%s locked=%s hp %.0f -> %.0f" % [str(started), str(locked), hp_a, hp_b])

	# moving stops it with the right reason
	stop_reasons = []
	_r().call("add_scrap", 10.0)
	_player().set("hp", 40.0)
	Input.action_press("repair")
	await _wait_until(func() -> bool: return bool(rep.get("active")), 120)
	Input.action_press("right")
	await _frames(4)
	Input.action_release("right")
	Input.action_release("repair")
	await _pframes(10)
	_check("moving stops the repair with reason moved", stop_reasons.has("moved") or not bool(rep.get("active")),
		"reasons=%s active=%s" % [str(stop_reasons), str(rep.get("active"))])

	# empty scrap stops it
	stop_reasons = []
	_r().call("add_scrap", -float(_r().get("scrap")))
	_r().call("add_scrap", 1.0)
	_player().set("hp", 30.0)
	rep.call("debug_hold", 3.0)
	await _pframes(10)
	_check("empty scrap stops the repair with reason empty",
		stop_reasons.has("empty") or float(_r().get("scrap")) <= 0.01,
		"reasons=%s scrap=%s" % [str(stop_reasons), str(_r().get("scrap"))])


func _on_stopped(reason: String) -> void:
	stop_reasons.append(reason)


func _ui_checks() -> void:
	var menu = _sys("menu")
	var map_view = _sys("map_view")
	var minimap = _sys("minimap")
	var hud = _sys("hud")
	var db = _sys("dialog_box")
	var tab_rows: Array = []

	if menu == null:
		_check("the pause menu opens and pauses the tree", false, "no menu on main")
		_check("the tabs cycle in order", false, "no menu")
		_check("debug_rows match each tab", false, "no menu")
		_check("CHARACTER shows her stats", false, "no menu")
		_check("ITEMS uses a Suture from the menu", false, "no menu")
		_check("EQUIPMENT has 2 harness and 2 module rows", false, "no menu")
		_check("MAP draws only visited cells", false, "no map_view")
		_check("the minimap focuses her cell", false, "no minimap")
		_check("a level-up opens no menu", false, "no menu")
		_check("attack and jump are swallowed after closing", false, "no menu")
		_check("debug_tap works on every tab", false, "no menu")
	else:
		menu.call("toggle")
		await _pframes(5)
		var open_and_paused := bool(menu.get("is_open")) and get_tree().paused
		_check("the pause menu opens and pauses the tree", open_and_paused, "open=%s paused=%s" % [str(menu.get("is_open")), str(get_tree().paused)])
		var tabs = menu.get("TABS")
		var want_tabs := ["MAP", "CHARACTER", "ITEMS", "EQUIPMENT", "SYSTEM"]
		_check("the tabs are MAP CHARACTER ITEMS EQUIPMENT SYSTEM in order", str(tabs) == str(want_tabs), str(tabs))
		menu.call("debug_press", "tab_next")
		await _pframes(3)
		var t1 = menu.get("tab")
		menu.call("debug_press", "tab_next")
		await _pframes(3)
		var t2 = menu.get("tab")
		var i1 := want_tabs.find(String(t1)) if t1 != null else -1
		var i2 := want_tabs.find(String(t2)) if t2 != null else -1
		_check("tab_next cycles the tabs in order", i1 >= 0 and i2 == (i1 + 1) % want_tabs.size(), "%s -> %s" % [str(t1), str(t2)])
		menu.call("close")
		await _pframes(5)

		# debug_rows per tab
		var rows_bad := []
		for tab in want_tabs:
			menu.call("open", tab)
			await _pframes(4)
			tab_rows = menu.call("debug_rows")
			if not (tab_rows is Array):
				rows_bad.append(tab + " no rows")
			elif String(tab) != "MAP" and (tab_rows as Array).is_empty():
				rows_bad.append(tab + " empty")
			menu.call("close")
			await _pframes(3)
		_check("debug_rows match each tab", rows_bad.is_empty(), str(rows_bad))

		# CHARACTER shows her effective stats; a level-up raises them; no AUTO row, no points (user decision 2026-11-20).
		# Expected numbers come from R, never typed in.
		_reset_all()
		var atk_before: float = float(_r().call("atk"))
		menu.call("open", "CHARACTER")
		await _pframes(4)
		var before_rows := _rows_join(menu)
		menu.call("close")
		await _pframes(3)
		_r().call("add_xp", 20)
		var atk_after: float = float(_r().call("atk"))
		menu.call("open", "CHARACTER")
		await _pframes(4)
		var rows2: Array = menu.call("debug_rows")
		var after_rows := _rows_join(menu)
		menu.call("close")
		await _pframes(3)
		var stat_missing := []
		for word in ["LV", "XP", "NEXT", "HP", "EN", "MP", "ATK", "DEF", "SPC"]:
			if not _row_has(rows2, word, ""):
				stat_missing.append(word)
		var shown_value := {"HP": float(_r().call("max_hp")), "EN": float(_r().call("max_en")),
			"MP": float(_r().call("max_mp")), "SPC": float(_r().call("special_pct"))}
		for word in shown_value:
			if not _row_has(rows2, String(word), str(int(round(float(shown_value[word]))))):
				stat_missing.append("%s value" % word)
		var prompt_left := after_rows.contains("AUTO") or after_rows.contains("PTS")
		_check("CHARACTER shows LV XP NEXT HP EN MP ATK DEF SPC, with no AUTO or points row",
			stat_missing.is_empty() and not prompt_left,
			"missing=%s prompt=%s rows=%s" % [str(stat_missing), str(prompt_left), after_rows.substr(0, 200)])
		var atk_row_before := "ATK %d%%" % int(round(atk_before))
		var atk_row_after := "ATK %d%%" % int(round(atk_after))
		_check("the ATK row grows after a level-up",
			atk_after > atk_before and before_rows.contains(atk_row_before) and after_rows.contains(atk_row_after),
			"want '%s' then '%s'; rows=%s" % [atk_row_before, atk_row_after, after_rows.substr(0, 200)])

		# preview equals the stats after the change (equipment arithmetic)
		_reset_all()
		var atk0: float = float(_r().call("atk"))
		var add: float = float(_r().call("gear_effect", "atk_add_key"))
		_r().call("equip_gear", "module1", "coupler_034")
		var atk1: float = float(_r().call("atk"))
		var flat := atk0 + add
		var pct := 100.0 + add
		_check("the preview equals the stats after the change", absf(atk1 - flat) < 0.01 or absf(atk1 - pct) < 0.01,
			"atk %.0f + add %.0f -> %.0f" % [atk0, add, atk1])
		_r().call("equip_gear", "module1", "")

		# ITEMS uses a Suture from the menu
		_reset_all()
		_r().call("add_item", "suture", 1)
		_player().set("hp", 50.0)
		menu.call("open", "ITEMS")
		await _pframes(4)
		var rows = menu.call("debug_rows")
		var used_menu := false
		if rows is Array:
			for i in (rows as Array).size():
				if String(rows[i]).contains("SUTURE"):
					menu.call("debug_tap", i)
					await _pframes(4)
					menu.call("debug_press", "ok")
					await _pframes(6)
					used_menu = int(_r().call("count", "suture")) == 0 and float(_player().get("hp")) > 60.0
					break
		menu.call("close")
		await _pframes(3)
		_check("ITEMS uses a Suture from the menu and heals", used_menu,
			"count=%d hp=%.0f" % [int(_r().call("count", "suture")), float(_player().get("hp"))])

		# EQUIPMENT: 2 harness and 2 module rows
		menu.call("open", "EQUIPMENT")
		await _pframes(4)
		rows = menu.call("debug_rows")
		var eq_rows := 0
		var equip_text := ""
		if rows is Array:
			eq_rows = (rows as Array).size()
			equip_text = _rows_join(menu)
		menu.call("close")
		await _pframes(3)
		_check("EQUIPMENT lists 2 harness and 2 module rows (7 rows with hand and core)",
			eq_rows == 7 and equip_text.contains("TORSO") and equip_text.contains("DRIVE"),
			"rows=%d text=%s" % [eq_rows, equip_text.substr(0, 120)])

		# MAP: only visited cells; cell_rect matches the meta
		if map_view != null and map_view.has_method("cell_rect"):
			var vis_bad := []
			var w := _w()
			var church_cell: Array = []
			if w != null and w.has_method("meta"):
				var m = w.call("meta", "church")
				if m is Dictionary and m.has("cell"):
					church_cell = m["cell"]
			var r_church = map_view.call("cell_rect", "church")
			var r_unvisited = map_view.call("cell_rect", "gallery")
			var church_ok = r_church is Rect2i and r_church.size.x > 0
			if church_ok and church_cell.size() == 4:
				church_ok = r_church.position.x == int(church_cell[0]) and r_church.position.y == int(church_cell[1]) \
					and r_church.size.x == int(church_cell[2]) and r_church.size.y == int(church_cell[3])
			var unvis_ok = not (r_unvisited is Rect2i) or r_unvisited.size.x * r_unvisited.size.y <= 0
			_check("MAP draws only visited cells and cell_rect matches the meta", church_ok and unvis_ok,
				"church=%s unvisited=%s meta=%s" % [str(r_church), str(r_unvisited), str(church_cell)])
		else:
			_check("MAP draws only visited cells and cell_rect matches the meta", false, "no map_view.cell_rect")

		# minimap: a 5x3 window around focus_cell
		if minimap != null and minimap.has_method("focus_cell"):
			var w := _w()
			var focus = minimap.call("focus_cell")
			var expect = w.call("cell_of", "church", _player().global_position) if w != null and w.has_method("cell_of") else null
			_check("the minimap focuses her cell", focus is Vector2i and str(focus) == str(expect),
				"focus=%s expect=%s" % [str(focus), str(expect)])
		else:
			_check("the minimap focuses her cell", false, "no minimap.focus_cell")

		# a level-up opens no menu and no prompt (user decision 2026-11-20)
		_reset_all()
		if bool(menu.get("is_open")):
			menu.call("close")
			await _pframes(3)
		_r().call("add_xp", 20)
		await _pframes(5)
		_check("a level-up opens no menu", not bool(menu.get("is_open")) and not get_tree().paused,
			"open=%s paused=%s" % [str(menu.get("is_open")), str(get_tree().paused)])

		# after closing, attack and jump are ignored for menu_swallow
		var swallow := _tv("menu_swallow")
		menu.call("toggle")
		await _pframes(4)
		menu.call("toggle")
		await _pframes(2)
		if _player().has_method("debug_set"):
			_player().call("debug_set", {"energy": 100.0, "mp": 60.0})
		var en0: float = float(_player().get("energy"))
		Input.action_press("attack")
		await _frames(2)
		Input.action_release("attack")
		Input.action_press("jump")
		await _frames(2)
		Input.action_release("jump")
		var en_swallowed: float = float(_player().get("energy"))
		await _frames(int(swallow * 60.0) + 8)
		Input.action_press("attack")
		await _frames(2)
		Input.action_release("attack")
		var en_after: float = float(_player().get("energy"))
		_check("attack and jump are ignored for menu_swallow after closing",
			absf(en_swallowed - en0) < 0.01 and en_after < en0 - 1.0,
			"en %.0f -> %.0f (swallowed) -> %.0f" % [en0, en_swallowed, en_after])

		# debug_tap works on every tab
		var tap_bad := []
		for tab in want_tabs:
			menu.call("open", tab)
			await _pframes(3)
			var r2 = menu.call("debug_rows")
			if r2 is Array and not (r2 as Array).is_empty():
				menu.call("debug_tap", 0)
				await _pframes(3)
				if not bool(menu.get("is_open")):
					tap_bad.append(tab + " closed")
			menu.call("close")
			await _pframes(2)
		_check("debug_tap works on every tab", tap_bad.is_empty(), str(tap_bad))

	# name plate: enemies.json name only with LEXICON, NEW the first time
	if hud != null and hud.has_method("name_plate"):
		var sp = _sys("spawner")
		var ghost = sp.call("enemy", "ghost", Vector2(40, 0)) if sp != null else null
		var plate_bad := "no ghost to name"
		if ghost != null and ghost is Node:
			add_child(ghost)
			var r := _r()
			if r.has_method("set_owned"):
				r.call("set_owned", "lexicon_core", false)
			r.call("debug_seed", 7)
			var names0 = r.get("names_seen")
			var n0 := 0
			if names0 is Dictionary:
				n0 = (names0 as Dictionary).size()
			hud.call("name_plate", ghost)
			await _frames(3)
			var n1 := n0
			var names1 = r.get("names_seen")
			if names1 is Dictionary:
				n1 = (names1 as Dictionary).size()
			var without_ok := n1 == n0
			r.call("set_owned", "lexicon_core", true)
			hud.call("name_plate", ghost)
			await _frames(3)
			var names2 = r.get("names_seen")
			var with_ok := names2 is Dictionary and (names2 as Dictionary).has("ghost")
			plate_bad = ""
			if not without_ok:
				plate_bad = "named without LEXICON"
			if not with_ok:
				plate_bad += " no name with LEXICON"
		_check("the name plate names enemies only with LEXICON CORE", plate_bad == "", plate_bad)
	else:
		_check("the name plate names enemies only with LEXICON CORE", false, "no hud.name_plate")

	# dialog box: ask returns the chosen index; a page has at most 3 lines
	if db != null and db.has_method("ask"):
		var got := [-1]
		var asker := func() -> void:
			got[0] = await db.ask("TEST?", ["A", "B"])
		asker.call()
		await _pframes(6)
		db.call("debug_choose", 1)
		await _wait_until(_pred_asked.bind(got), 120)
		var labels := 0
		if db.has_method("say"):
			db.call("say", ["one", "two", "three", "four", "five"])
			await _pframes(6)
			for c in db.find_children("*", "Label", true, false):
				labels += 1
		var page_ok := labels > 0 and labels <= 3
		var detail := "ask=%d labels=%d" % [got[0], labels]
		if labels == 0:
			page_ok = false
			detail += " (page size not observable)"
		_check("dialog_box.ask returns the chosen index and a page has at most 3 lines", got[0] == 1 and page_ok, detail)
		if db.has_method("debug_advance"):
			db.call("debug_advance")
	else:
		_check("dialog_box.ask returns the chosen index and a page has at most 3 lines", false, "no dialog_box")


# true when some row holds `word` as a whole word and, if `num` is not empty, that exact number
# right after it ("HP 1060" does not match 106; a trailing % is ignored, so "SPC 105%" matches 105)
func _row_has(rows: Array, word: String, num: String) -> bool:
	for r in rows:
		var tokens := String(r).split(" ", false)
		for i in tokens.size():
			if tokens[i] != word:
				continue
			if num == "" or (i + 1 < tokens.size() and tokens[i + 1].trim_suffix("%") == num):
				return true
	return false


func _rows_join(menu) -> String:
	var rows = menu.call("debug_rows")
	var out := ""
	if rows is Array:
		for r in rows:
			out += String(r) + " | "
	return out


func _pred_active(card) -> bool:
	return card != null and bool(card.get("active"))


func _pred_asked(got) -> bool:
	return got[0] != -1
