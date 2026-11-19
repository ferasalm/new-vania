# PROTOTYPE - NOT FOR PRODUCTION
# tests_v4/t_world.gd - locked test (step 0, written from design/contract.md section 4 only).
# The world (S1): every room of every sheet loads with its meta cell size, grid doors match
# meta exits with returns, enemy counts match map.md, reachability with abilities, banned
# hint strings, backdrops, the library filter, weak respawn, the shift, candles and visited.
# Builders never edit this pack. Run: godot --headless --path . res://tests_v4/t_world.tscn
extends Node

const Room := preload("res://room.gd")

# enemy counts per map.md sections 2 and 4, keyed by the loaded file id
const COUNTS := {
	"church": {"hound": 1, "ghost": 1},
	"library": {"moth": 2, "scribe": 1},
	"lab": {"trolley": 2, "orderly": 1},
	"gallery": {"crab": 2, "orderly": 2},
	"hazard": {"crab": 2, "leech": 2},
	"loft": {"leech": 1},
	"shaft_shift": {"ghost": 1},
	"lab_shift": {"trolley": 2, "choir": 2},
	"kennel_shift": {"orderly": 1, "ghost": 1},
	"church_shift": {"warden": 1, "hound": 2},
	"library_shift": {"leech": 2, "ghost": 1},
	"hazard_shift": {"moth": 2, "spitter": 1},
}
# up-holes climbable without the wall jump (map.md: normal jumps / normal jump)
const HOLE_FREE_UP := {"lab>kennel": true, "gallery>hallway": true}
# the shutter opens only from HZ~ toward OR~ (map.md section 4)
const SHUTTER_FROM := {"hazard_shift>timemachine_shift": true}

const HARD_BANNED := ["UNTIL THE NEXT UPDATE", "Far below", "GRIP SERVOS ONLINE -", "E (or SWAP)"]
const SOFT_BANNED := ["ITS HANDS ARE YOUR STAIRS", "IT WILL NOT LET GO"]

var main: Node = null
var passed := 0
var failed := 0


func _ready() -> void:
	G.peace = false
	if ResourceLoader.exists("res://main.tscn"):
		main = load("res://main.tscn").instantiate()
		add_child(main)
		await _frames(30)
	_r_seed()
	await _run()
	var ok := failed == 0 and passed > 0
	print("t_world %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
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


func _r_seed() -> void:
	var r := get_node_or_null("/root/R")
	if r != null and r.has_method("debug_seed"):
		r.debug_seed(7)


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


func _enter(room: String) -> void:
	if main != null and main.has_method("debug_enter"):
		await main.debug_enter(room, "left", false)
	else:
		await _frames(10)


func _arity(obj: Node, mname: String) -> int:
	for md in obj.get_method_list():
		if md["name"] == mname:
			return (md["args"] as Array).size()
	return -1


func _kind_of(n: Node) -> String:
	for prop in ["kind", "enemy_kind", "id", "enemy_id"]:
		var v = n.get(prop)
		if v != null and v is String:
			return v
	return ""


func _find_kind(kd: String) -> Node:
	var room: Node = main.get("room") if main != null else null
	if room == null:
		return null
	for c in room.get_children():
		if c is Node and _kind_of(c) == kd:
			return c
	return null


func _kill(en: Node) -> void:
	if en == null or not en.has_method("take_hit"):
		return
	var args := _arity(en, "take_hit")
	if args <= 1:
		en.call("take_hit", 9999.0)
	else:
		en.call("take_hit", 9999.0, 0.0)
	await _frames(3)


func _run() -> void:
	var w := _w()
	_check("W autoload exists", w != null, "get_node_or_null('/root/W')")
	if w == null:
		return

	var before: Array = w.call("room_list", "before") if w.has_method("room_list") else []
	var after: Array = w.call("room_list", "after") if w.has_method("room_list") else []
	var restored: Array = w.call("room_list", "restored") if w.has_method("room_list") else []
	_check("sheet I has the 15 rooms of map.md", before is Array and before.size() == 15, "n=%s" % str(before.size()))
	_check("sheet II has the 11 rooms of map.md", after is Array and after.size() == 11, "n=%s" % str(after.size()))
	_check("the restored sheet is sheet I plus AR (16)", restored is Array and restored.size() == 16, "n=%s" % str(restored.size()))
	if not (before is Array) or before.size() != 15:
		return

	# ---- reachability on meta (before sheet) ----------------------------------
	var r1 := _reach(w, before, "church", {}, 0, true)
	var r2 := _reach(w, before, "church", {"wall_jump": true, "elegy": true}, 0, true)
	var must1 := ["library", "scriptorium", "save", "lab", "kennel"]
	var miss := []
	for fid in must1:
		if not r1.has(fid):
			miss.append(fid)
	_check("with nothing she reaches LB, SC, S2, LA and KN", miss.is_empty(), "unreachable=%s" % str(miss))
	_check("with nothing she cannot reach the organ or AR",
		not r1.has("timemachine") and not r1.has("arnetria"), "reach=%s" % str(r1.keys()))
	_check("with wall_jump and elegy she reaches the organ", r2.has("timemachine"),
		"reach has organ=%s" % str(r2.has("timemachine")))

	# ---- every before room loads, matches its meta cell, doors and counts -----
	await _check_sheet(w, before, "before")
	var s_before = w.call("snapshot") if w.has_method("snapshot") else null

	# ---- banned hint strings ---------------------------------------------------
	await _banned_strings()

	# ---- backdrops cover the room with no gaps ---------------------------------
	if main != null and main.has_method("debug_enter"):
		await _enter("church")
		var room: Node = main.get("room")
		if room != null and room.has_method("backdrop_rects"):
			var rects = room.call("backdrop_rects")
			_check("the church wall covers 1152 x 256 with no gap", _covers(rects, 1152.0, 256.0), str(_cover_detail(rects, 1152.0, 256.0)))
		else:
			_check("the church wall covers 1152 x 256 with no gap", false, "no room.backdrop_rects()")
		await _enter("boss")
		room = main.get("room")
		if room != null and room.has_method("backdrop_rects"):
			var rects2 = room.call("backdrop_rects")
			_check("the boss wall covers 480 x 224 with no gap", _covers(rects2, 480.0, 224.0), str(_cover_detail(rects2, 480.0, 224.0)))
		else:
			_check("the boss wall covers 480 x 224 with no gap", false, "no room.backdrop_rects()")

	# ---- entering a room marks it visited --------------------------------------
	var visited = w.get("visited")
	var vis_ok = visited is Dictionary and (visited as Dictionary).has("before") \
		and (visited as Dictionary)["before"] is Dictionary and (visited as Dictionary)["before"].has("church")
	_check("entering a room marks it visited", vis_ok, str(visited.keys()) if visited is Dictionary else "no visited")

	# ---- weak respawn ----------------------------------------------------------
	await _weak_respawn()

	# ---- the shift -------------------------------------------------------------
	if w.has_method("start_shift"):
		w.call("set_flag", "lever_library", true)
		w.call("start_shift")
		await _frames(10)
		var shifted: bool = bool(G.get("shifted")) if G.get("shifted") != null else false
		var sheet = w.get("sheet")
		_check("start_shift turns the shift on and moves to sheet II", shifted and String(sheet) == "after",
			"shifted=%s sheet=%s" % [str(shifted), str(sheet)])
		await _enter("church")
		var room: Node = main.get("room")
		var fid = room.get("file_id") if room != null else null
		_check("entering the church after the shift loads its _shift file", String(fid) == "church_shift", "file_id=%s" % str(fid))

		# candles: two leave the X door locked, three open it
		await _enter("vault")
		var xdoor := _find_xdoor()
		var two_state := _door_locked(xdoor)
		w.call("set_flag", "candle_1", true)
		w.call("set_flag", "candle_2", true)
		await _frames(5)
		var locked2 := _door_locked(xdoor)
		w.call("set_flag", "candle_3", true)
		await _frames(5)
		var open3 := not _door_locked(xdoor)
		_check("2 candles leave the X door locked and 3 open it", locked2 and open3,
			"xdoor=%s two=%s three_open=%s" % [str(xdoor != null), str(locked2), str(open3)])

		var r3 := _reach(w, after, "timemachine_shift", {"wall_jump": true, "elegy": true}, 0, false)
		var r4 := _reach(w, after, "timemachine_shift", {"wall_jump": true, "elegy": true}, 3, false)
		var miss3 := []
		for fid2 in after:
			if fid2 != "arnetria" and not r3.has(fid2):
				miss3.append(fid2)
		_check("after the shift all 10 unsealed rooms are reachable from OR~", miss3.is_empty(), "unreachable=%s" % str(miss3))
		_check("AR needs the three candles", not r3.has("arnetria") and r4.has("arnetria"),
			"with 0=%s with 3=%s" % [str(r3.has("arnetria")), str(r4.has("arnetria"))])

		await _check_sheet(w, after, "after")

		# the library filter no longer cubes the brightness
		var shift = _sys("shift")
		var filter_bad := "no shift system"
		if shift != null and shift.has_method("mode_params"):
			var params = shift.call("mode_params", "library_shift")
			if params is Dictionary and not (params as Dictionary).is_empty():
				var found := false
				var got_v := NAN
				for k in params:
					if String(k).to_lower().contains("bright"):
						got_v = float(params[k])
						found = true
				var want := _tv("shift_library_strength")
				if found and not is_nan(got_v) and not is_nan(want):
					if absf(got_v - want) <= 0.02:
						filter_bad = ""
					else:
						filter_bad = "bright=%.3f strength=%.3f (cubic would be %.3f)" % [got_v, want, want * want * want]
				else:
					filter_bad = "no brightness value in %s" % str(params.keys())
			else:
				filter_bad = "mode_params empty"
		_check("the library filter no longer cubes the brightness", filter_bad == "", filter_bad)

		if w.has_method("end_shift"):
			w.call("end_shift")
			await _frames(10)
			var sheet2 = w.get("sheet")
			var kept: bool = bool(w.call("flag", "lever_library"))
			_check("end_shift returns the restored sheet and levers keep their state",
				String(sheet2) == "restored" and kept, "sheet=%s lever=%s" % [str(sheet2), str(kept)])
			await _enter("vault")
			room = main.get("room")
			fid = room.get("file_id") if room != null else null
			var to_arnetria := false
			if w.has_method("meta"):
				var vm = w.call("meta", "vault")
				if vm is Dictionary:
					for ex in vm.get("exits", []):
						if ex is Dictionary and String(ex.get("to", "")) == "arnetria":
							to_arnetria = true
			_check("the restored vault loads with its door to AR", String(fid) == "vault_restored" and to_arnetria,
				"file_id=%s exit_to_arnetria=%s" % [str(fid), str(to_arnetria)])
			await _check_sheet(w, restored, "restored")
		else:
			_check("end_shift returns the restored sheet and levers keep their state", false, "no end_shift")
			_check("the restored vault loads with its door to AR", false, "no end_shift")
	else:
		_check("start_shift turns the shift on and moves to sheet II", false, "no W.start_shift")
		_check("entering the church after the shift loads its _shift file", false, "no start_shift")
		_check("2 candles leave the X door locked and 3 open it", false, "no start_shift")
		_check("after the shift all 10 unsealed rooms are reachable from OR~", false, "no start_shift")
		_check("AR needs the three candles", false, "no start_shift")
		_check("the library filter no longer cubes the brightness", false, "no start_shift")
		_check("end_shift returns the restored sheet and levers keep their state", false, "no end_shift")
		_check("the restored vault loads with its door to AR", false, "no end_shift")

	# back to where we started
	if s_before != null and w.has_method("restore"):
		w.call("restore", s_before)
		await _frames(5)
		_check("W.restore returns the before sheet", String(w.get("sheet")) == "before", "sheet=%s" % str(w.get("sheet")))


func _check_sheet(w: Node, ids: Array, sheet: String) -> void:
	var load_bad := []
	var size_bad := []
	var door_bad := []
	var count_bad := []
	var known := {}
	for sh in ["before", "after", "restored"]:
		for fid in (w.call("room_list", sh) if w.has_method("room_list") else []):
			known[String(fid)] = true
	var i := 0
	for fid in ids:
		var r: Room = Room.new()
		r.position = Vector2(0, -9000.0 - float(i) * 200.0)
		add_child(r)
		var ok: bool = r.load_room(String(fid))
		var loaded_fid := String(fid)
		var file_id_v = r.get("file_id")
		if file_id_v != null and String(file_id_v) != "":
			loaded_fid = String(file_id_v)
		if not ok:
			load_bad.append(String(fid))
		else:
			# tile size matches the meta cell (cell = round(tiles / 24 and / 14))
			var cell: Array = []
			if w.has_method("meta"):
				var m = w.call("meta", String(fid))
				if m is Dictionary and m.has("cell"):
					cell = m["cell"]
			if cell.size() == 4:
				if int(roundf(r.size.x / 24.0)) != int(cell[0]) or int(roundf(r.size.y / 14.0)) != int(cell[1]):
					size_bad.append("%s %s vs cell %s" % [loaded_fid, str(r.size), str(cell)])
			else:
				size_bad.append(loaded_fid + " no meta cell")
			# every grid door sits in an edge, points at a known room, and the meta agrees
			for side in r.doors:
				var d = r.doors[side]
				var edge: bool = (side == "left" and d.position.x == 0.0) or (side == "right" and d.position.x == r.size.x - 16.0)
				var target := String(d.get("to"))
				if not known.has(target):
					edge = false
				var meta_agrees := _meta_has_exit(w, String(fid), side_letter(side), target, ["door", "open", "lever_door", "boss_door", "sealed_x"])
				if not (edge and meta_agrees):
					door_bad.append("%s %s -> %s (edge=%s meta=%s)" % [loaded_fid, side, target, str(edge), str(meta_agrees)])
			# hole exits pair with a hole back in the target (the shutter is exempt)
			if w.has_method("meta"):
				var m2 = w.call("meta", String(fid))
				if m2 is Dictionary:
					for ex in m2.get("exits", []):
						if ex is Dictionary and String(ex.get("kind", "")) == "hole":
							var back := _meta_has_exit(w, String(ex.get("to", "")), opposite_letter(String(ex.get("side", ""))), String(fid), ["hole"])
							if not back:
								door_bad.append("%s hole %s to %s has no way back" % [loaded_fid, str(ex.get("side")), str(ex.get("to"))])
			# enemy counts match map.md
			var want: Dictionary = COUNTS.get(loaded_fid, {})
			var got := {}
			for e in r.enemies:
				var kd := String(e[0])
				got[kd] = int(got.get(kd, 0)) + 1
			if str(got) != str(want):
				count_bad.append("%s got %s want %s" % [loaded_fid, str(got), str(want)])
		i += 1
		r.queue_free()
	_check("every %s room loads" % sheet, load_bad.is_empty(), str(load_bad))
	_check("every %s room matches its meta cell size" % sheet, size_bad.is_empty(), str(size_bad.slice(0, 4)))
	_check("every %s door matches the meta and has a way back" % sheet, door_bad.is_empty(), str(door_bad.slice(0, 4)))
	_check("enemy counts match map.md (%s)" % sheet, count_bad.is_empty(), str(count_bad.slice(0, 4)))


func _meta_has_exit(w: Node, fid: String, side: String, target: String, kinds: Array) -> bool:
	if not w.has_method("meta"):
		return false
	var m = w.call("meta", fid)
	if not (m is Dictionary):
		return false
	for ex in m.get("exits", []):
		if ex is Dictionary and String(ex.get("side", "")) == side and String(ex.get("to", "")) == target \
				and kinds.has(String(ex.get("kind", ""))):
			return true
	return false


# grid door side names to the meta exit letters, and back
func side_letter(side: String) -> String:
	if side == "left":
		return "L"
	if side == "right":
		return "R"
	if side == "top" or side == "up":
		return "U"
	if side == "bottom" or side == "down":
		return "D"
	return ""


func opposite_letter(side: String) -> String:
	if side == "L":
		return "R"
	if side == "R":
		return "L"
	if side == "U":
		return "D"
	if side == "D":
		return "U"
	return ""


func _reach(w: Node, ids: Array, start: String, abilities: Dictionary, candles: int, lever: bool) -> Dictionary:
	var graph := {}
	for fid in ids:
		var edges := []
		if w.has_method("meta"):
			var m = w.call("meta", String(fid))
			if m is Dictionary:
				for ex in m.get("exits", []):
					if ex is Dictionary and String(ex.get("to", "")) != "":
						edges.append({"to": String(ex["to"]), "kind": String(ex.get("kind", "door")), "side": String(ex.get("side", ""))})
		graph[String(fid)] = edges
	var seen := {start: true}
	var queue := [start]
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		for e in graph.get(cur, []):
			var to: String = e["to"]
			if seen.has(to):
				continue
			var up: bool = e["side"] == "U"
			if not _can_pass(e["kind"], up, cur, to, abilities, candles, lever):
				continue
			if not graph.has(to):
				continue
			seen[to] = true
			queue.append(to)
	return seen


func _can_pass(kind: String, up: bool, from: String, to: String, abilities: Dictionary, candles: int, lever: bool) -> bool:
	match kind:
		"door", "open", "boss_door", "tunnel":
			return true
		"hole":
			if not up:
				return true
			if abilities.has("wall_jump"):
				return true
			return HOLE_FREE_UP.has(from + ">" + to)
		"lever_door":
			return lever
		"bricked":
			return false
		"sealed_x":
			return candles >= 3
		"shutter":
			return SHUTTER_FROM.has(from + ">" + to)
	return false


func _banned_strings() -> void:
	var hard_bad := []
	var soft_bad := []
	var d := DirAccess.open("res://")
	if d != null:
		d.list_dir_begin()
		var nm := d.get_next()
		while nm != "":
			if not d.current_is_dir() and nm.ends_with(".gd"):
				var f := FileAccess.open("res://" + nm, FileAccess.READ)
				if f != null:
					var text := f.get_as_text()
					f.close()
					for s in HARD_BANNED:
						if text.contains(s):
							hard_bad.append("%s has '%s'" % [nm, s])
					for s2 in SOFT_BANNED:
						if text.contains(s2):
							soft_bad.append("%s has '%s'" % [nm, s2])
			nm = d.get_next()
	_check("the four S1 hint strings are gone from the scripts", hard_bad.is_empty(), str(hard_bad))
	# S5 removes the last two; until then they are reported as expected, not failures
	print("note  the last two banned strings are expected until S5: %s" % str(soft_bad))


func _covers(rects, want_w: float, want_h: float) -> bool:
	return _cover_detail(rects, want_w, want_h) == ""


func _cover_detail(rects, want_w: float, want_h: float) -> String:
	if not (rects is Array) or (rects as Array).is_empty():
		return "no rects"
	var arr: Array = rects as Array
	for r in arr:
		if not (r is Rect2):
			return "non-rect entry"
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for rc in arr:
		min_x = minf(min_x, rc.position.x)
		max_x = maxf(max_x, rc.end.x)
		min_y = minf(min_y, rc.position.y)
		max_y = maxf(max_y, rc.end.y)
	var sorted := arr.duplicate()
	sorted.sort_custom(func(a, b): return a.position.x < b.position.x)
	for i in sorted.size() - 1:
		if sorted[i + 1].position.x > sorted[i].end.x + 0.5:
			return "gap between %.0f and %.0f" % [sorted[i].end.x, sorted[i + 1].position.x]
	if absf((max_x - min_x) - want_w) > 4.0:
		return "width %.0f want %.0f" % [max_x - min_x, want_w]
	if absf((max_y - min_y) - want_h) > 4.0:
		return "height %.0f want %.0f" % [max_y - min_y, want_h]
	return ""


func _find_xdoor() -> Node:
	var room: Node = main.get("room") if main != null else null
	if room == null:
		return null
	for side in room.doors:
		var d = room.doors[side]
		if String(d.get("to")) == "arnetria":
			return d
	return null


func _door_locked(d) -> bool:
	if d == null:
		return true
	if d.get("locked") != null:
		return bool(d.get("locked"))
	if d.get("lamp") != null:
		return String(d.get("lamp")) == "red"
	return true


func _weak_respawn() -> void:
	var resp = _sys("respawn")
	_check("main holds a respawn system with debug_tick and live_weak",
		resp != null and resp.has_method("debug_tick") and resp.has_method("live_weak"),
		"respawn=%s" % ("found" if resp != null else "missing"))
	if resp == null:
		_check("a weak enemy returns after the wait when she stays far away", false, "no respawn system")
		_check("a weak enemy does not return while she is within respawn_distance", false, "no respawn system")
		_check("a moth does not return until she re-enters", false, "no respawn system")
		_check("a paused tree does not advance the respawn timer", false, "no respawn system")
		return
	var wait: float = _tv("weak_respawn_s", "respawn_time")
	var warn: float = _tv("respawn_warning", "1.0")
	if is_nan(wait):
		wait = 10.0
	if is_nan(warn):
		warn = 1.0
	_check("weak enemies return after 10 s (decision 18)", wait == 10.0, "wait=%s" % str(wait))

	await _enter("church")
	var start: int = int(resp.call("live_weak"))
	var hound := _find_kind("hound")
	if hound == null:
		_check("a weak enemy returns after the wait when she stays far away", false, "no hound in the church")
		_check("a weak enemy does not return while she is within respawn_distance", false, "no hound")
	else:
		await _kill(hound)
		await _frames(10)
		var after_kill: int = int(resp.call("live_weak"))
		if main != null and main.get("player") != null and main.get("player").has_method("debug_set"):
			main.get("player").call("debug_set", {"pos": Vector2(10.0, 10.0)})
		await _frames(5)
		resp.call("debug_tick", wait + warn + 0.5)
		await _frames(5)
		var back: int = int(resp.call("live_weak"))
		var flagged := _find_respawned()
		_check("a weak enemy returns after the wait when she stays far away",
			after_kill == start - 1 and back == start and flagged != null,
			"start=%d after=%d back=%d flagged=%s" % [start, after_kill, back, str(flagged != null)])
		# within respawn_distance it does not come back
		var hound2 := _find_kind("hound")
		var near_pos: Vector2 = hound2.global_position if hound2 != null else Vector2.ZERO
		await _kill(hound2)
		await _frames(10)
		if main.get("player").has_method("debug_set"):
			main.get("player").call("debug_set", {"pos": near_pos + Vector2(6.0, 0.0)})
		resp.call("debug_tick", wait + 3.0)
		await _frames(5)
		var stays: int = int(resp.call("live_weak"))
		_check("a weak enemy does not return while she is within respawn_distance", stays == start - 1,
			"start=%d stays=%d" % [start, stays])

	# a moth does not return until she re-enters (it comes back on re-entry)
	await _enter("library")
	var moth := _find_kind("moth")
	var moth_bad := "no moth in the library"
	if moth != null:
		await _kill(moth)
		await _frames(10)
		if main.get("player").has_method("debug_set"):
			main.get("player").call("debug_set", {"pos": Vector2(10.0, 10.0)})
		resp.call("debug_tick", wait + 5.0)
		await _frames(5)
		var gone := _find_kind("moth") == null
		await _enter("vault")
		await _enter("library")
		await _frames(10)
		var back_moth := _find_kind("moth") != null
		moth_bad = ""
		if not gone:
			moth_bad = "came back without re-entry"
		if not back_moth:
			moth_bad += " not back after re-entry"
	_check("a moth does not return until she re-enters", moth_bad == "", moth_bad)

	# a paused tree does not advance the timer
	await _enter("church")
	var ghost := _find_kind("ghost")
	var pause_bad := "no ghost"
	if ghost != null:
		var start2: int = int(resp.call("live_weak"))
		await _kill(ghost)
		await _frames(10)
		get_tree().paused = true
		await _pframes(720)
		get_tree().paused = false
		await _frames(30)
		var still_dead: bool = _find_kind("ghost") == null and int(resp.call("live_weak")) == start2 - 1
		resp.call("debug_tick", wait + warn + 0.5)
		await _frames(5)
		var can_return: bool = int(resp.call("live_weak")) == start2
		pause_bad = ""
		if not still_dead:
			pause_bad = "returned while paused"
		if not can_return:
			pause_bad += " never returns after unpausing"
	_check("a paused tree does not advance the respawn timer", pause_bad == "", pause_bad)


func _find_respawned() -> Node:
	var room: Node = main.get("room") if main != null else null
	if room == null:
		return null
	for c in room.find_children("*", "", true, false):
		if c is Node and c.get("respawned") != null and bool(c.get("respawned")):
			return c
	return null
