# PROTOTYPE - NOT FOR PRODUCTION
# Autoload "W". Everything about the world that must survive a room change:
# flags, the visited map cells, the taken markers, the map sheet, the save room,
# the unit number and the best times. It also carries the world signals that the
# systems listen to; main only emits them.
extends Node

signal room_entered(file_id: String)
signal enemy_hit(en: Node2D, dmg: int)
signal enemy_killed(en: Node2D, kind: String, at: Vector2, respawned: bool)
signal player_hurt(dmg: int, src: String)
signal player_down()
signal boss_started(id: String)
signal boss_down(id: String, at: Vector2)
signal shift_changed(shifted: bool)
signal flag_changed(key: String, value)

var flags := {}            # key -> value (levers, candles, bosses, saved)
var visited := {}          # {sheet: {file_id: true}}
var taken := {}            # {file_id: {marker: true}}
var sheet := "before"      # before | after | restored
var saved_room := ""       # the save room she last cached in
var unit := 1              # which Pandora this is: 001, then 002 after a reconstruction
var best_times := {}       # {boss_id: seconds}


func flag(key: String, default := false) -> bool:
	# a world flag; a flag that was never set answers with the default
	return bool(flags.get(key, default))


func set_flag(key: String, value) -> void:
	# set a world flag and tell the systems
	flags[key] = value
	flag_changed.emit(key, value)


func mark_taken(file_id: String, marker: String) -> void:
	# an item or a marker in a room has been taken
	if not taken.has(file_id):
		taken[file_id] = {}
	taken[file_id][marker] = true


func is_taken(file_id: String, marker: String) -> bool:
	# true when that item or marker was already taken
	return bool(taken.get(file_id, {}).get(marker, false))


func mark_visited(file_id: String) -> void:
	# the room is on the current map sheet
	if not visited.has(sheet):
		visited[sheet] = {}
	visited[sheet][file_id] = true


func meta(file_id: String) -> Dictionary:
	# the rooms_meta entry of a room on the current sheet, before sheet as fallback
	var sheets: Dictionary = Db.table("rooms_meta").get("sheets", {})
	var page: Dictionary = sheets.get(sheet, {})
	if sheet == "restored":
		var page_base: Dictionary = sheets.get(String(page.get("base", "before")), {})
		var merged := page_base.duplicate(true)
		for k in page.get("add", {}):
			merged[k] = page["add"][k]
		if merged.has(file_id) and merged[file_id] is Dictionary:
			return merged[file_id]
	elif page.has(file_id) and page[file_id] is Dictionary:
		return page[file_id]
	var before: Dictionary = sheets.get("before", {})
	if before.has(file_id) and before[file_id] is Dictionary:
		return before[file_id]
	return {}


func title(file_id: String) -> String:
	# the room's name, as shown on the banner
	return String(meta(file_id).get("title", ""))


func room_list(which: String) -> Array:
	# every room id on a sheet, in data order (restored = its base plus the added rooms)
	var sheets: Dictionary = Db.table("rooms_meta").get("sheets", {})
	if which == "restored":
		var page: Dictionary = sheets.get("restored", {})
		var base: Dictionary = sheets.get(String(page.get("base", "before")), {})
		var out: Array = base.keys()
		for k in page.get("add", {}):
			if not out.has(k):
				out.append(k)
		return out
	return sheets.get(which, {}).keys()


func cell_of(file_id: String, local: Vector2) -> Vector2i:
	# the map cell a point in the room falls in: the room's cell plus the tile offset
	var m: Dictionary = meta(file_id)
	var cell: Array = m.get("cell", [0, 0, 1, 1])
	var tiles: Array = Db.table("rooms_meta").get("cell_tiles", [24, 14])
	var cell_w := float(tiles[0]) * 16.0
	var cell_h := float(tiles[1]) * 16.0
	return Vector2i(int(cell[0]) + int(floor(local.x / cell_w)), int(cell[1]) + int(floor(local.y / cell_h)))


func start_shift() -> void:
	# the reality shift: the world is mirrored, the picture tears and the map sheet changes
	sheet = "after"
	G.shifted = true
	shift_changed.emit(true)


func end_shift() -> void:
	# Arnetria falls: the old sheet returns with her room added and the colour comes back
	sheet = "restored"
	G.shifted = false
	shift_changed.emit(false)


func snapshot() -> Dictionary:
	# a copy of everything the world remembers, for RECALL and the tests
	return {"flags": flags.duplicate(true), "visited": visited.duplicate(true), "taken": taken.duplicate(true),
		"sheet": sheet, "saved_room": saved_room, "unit": unit, "best_times": best_times.duplicate(true)}


func restore(d: Dictionary) -> void:
	# put a snapshot back
	flags = d.get("flags", {}).duplicate(true)
	visited = d.get("visited", {}).duplicate(true)
	taken = d.get("taken", {}).duplicate(true)
	sheet = String(d.get("sheet", "before"))
	saved_room = String(d.get("saved_room", ""))
	unit = int(d.get("unit", 1))
	best_times = d.get("best_times", {}).duplicate(true)
	G.shifted = sheet != "before"
	shift_changed.emit(G.shifted)


func debug_set(d: Dictionary) -> void:
	# the test hook: set only the fields that are named
	for k in d:
		match String(k):
			"flags":
				flags = d[k].duplicate(true)
			"visited":
				visited = d[k].duplicate(true)
			"taken":
				taken = d[k].duplicate(true)
			"sheet":
				sheet = String(d[k])
			"saved_room":
				saved_room = String(d[k])
			"unit":
				unit = int(d[k])
			"best_times":
				best_times = d[k].duplicate(true)
