# PROTOTYPE - NOT FOR PRODUCTION
# The room builder's red warnings. A GDScript port of tools/roomreach.py, tools/roomcheck.py and
# tests_quick/q6_audit.py, with her jump numbers read from tuning.json (jump_velocity, gravity)
# instead of typed in. run(doc) gives [{rect: Rect2 in room pixels, text: String}].
#   ceiling trap     a platform she can stand on but whose ceiling cuts her jump short: less air above it than
#                    builder_jump_clear (0.9) of her jump height, rounded up to a whole tile (4 tiles, 64 px, at the saved jump)
#   jump too high    a climb between platforms steeper than 80% of her best jump
#   she cannot reach an exit, an item, a save terminal or a door entry she cannot get out of
#   door             a door whose head or floor is blocked
#   backdrop         a backdrop= picture that is missing (backdrops are drawn at real size, never stretched)
# `quick` (default) skips the slow reach search; the builder runs the full one when asked.
extends RefCounted

const TILE := 16
const STAND := 36.0
const HEAD_SPARE := 8.0
const SIDE := 6          # a jump reaches 6 tiles sideways
const R2 := 3            # a wall jump adds 3 tiles up, 4 sideways, once per air
const D2 := 4
const RPOP := 3          # a floor-hole pop is 3 tiles
const DFALL := 6

var g: Array = []
var W := 0
var H := 0
var head := {}
var apex := 67.7
var rise_tiles := 4

var _exits := {}
var _cache := {}
var _gates_open := true


## All the warnings for a room. `reach` adds the can-she-get-there search (slower).
func run(doc: RefCounted, reach := false) -> Array:
	head = doc.head
	g = []
	W = doc.width()
	H = doc.height()
	for y in H:
		var row: String = doc.rows[y]
		g.append(row + "#".repeat(maxi(0, W - row.length())))
	var out: Array = []
	if W < 3 or H < 3:
		return out
	var v: float = T.v("jump_velocity")
	var gr: float = T.v("gravity")
	apex = v * v / (2.0 * gr)
	rise_tiles = int(apex / TILE)
	_clearance_and_jumps(out)
	_doors(out)
	_backdrop(out, doc)
	if reach:
		_reach(out)
	return _merge(out)


func _rect(x: int, y: int, w := 1, h := 1) -> Rect2:
	return Rect2(x * TILE, y * TILE, w * TILE, h * TILE)


## Neighbouring flags with the same text on one row become one wide rectangle.
func _merge(items: Array) -> Array:
	var out: Array = []
	for it in items:
		var merged := false
		for o in out:
			if o["text"] == it["text"] and o["rect"].position.y == it["rect"].position.y and o["rect"].size.y == it["rect"].size.y \
					and absf(o["rect"].end.x - it["rect"].position.x) < 0.5:
				o["rect"] = Rect2(o["rect"].position, Vector2(o["rect"].size.x + it["rect"].size.x, o["rect"].size.y))
				merged = true
				break
		if not merged:
			out.append({"rect": it["rect"], "text": it["text"]})
	return out


# ---------- q6: ceiling clearance and climb steps ----------

func _cell(x: int, y: int) -> String:
	if x < 0 or x >= W:
		return "E"
	if y < 0:
		return "^" if g[0][x] == "^" else "#"
	if y >= H:
		return "v" if g[H - 1][x] == "v" else "#"
	return g[y][x]


func _blocker(ch: String) -> bool:
	return ch == "#" or ch == "B" or ch == "%" or ch == "|" or ch == ":"


func _free6(x: int, y: int) -> bool:
	var ch := _cell(x, y)
	return ch != "E" and not _blocker(ch)


func _body6(x: int, y: int) -> bool:
	return _free6(x, y) and _free6(x, y - 1) and _free6(x, y - 2)


func _sup6(x: int, y: int) -> bool:
	var ch := _cell(x, y + 1)
	return _blocker(ch) or ch == "=" or ch == "v"


func _top_above(x: int, y: int) -> int:
	# pixel row of the lowest blocker above a standing cell (the ceiling over her head)
	var yy := y - 3
	while yy >= 0 and _free6(x, yy):
		yy -= 1
	if yy < 0:
		return 0 if g[0][x] != "^" else -TILE
	return (yy + 1) * TILE


func _clearance_and_jumps(out: Array) -> void:
	# air she needs above a platform to jump almost to the top of her jump (builder_jump_clear of it, rounded up a tile)
	var jump_need := (int(apex * T.v("builder_jump_clear") / TILE) + 1) * TILE
	var limit := 0.8 * apex
	var plats := {}            # platform row -> {x: true}
	for y in H:
		for x in W:
			var ch := _cell(x, y)
			if ch == "^" or ch == "v":
				continue
			if _body6(x, y) and _sup6(x, y):
				if not plats.has(y + 1):
					plats[y + 1] = {}
				plats[y + 1][x] = true
				# a ceiling that cuts her jump short: she can stand but cannot jump to full height
				var top := _top_above(x, y)
				var space := (y + 1) * TILE - top
				if space < jump_need:
					out.append({"rect": Rect2(x * TILE, top, TILE, (y + 1) * TILE - top),
						"text": "ceiling trap: %d px of air above this platform, her jump needs %d" % [space, jump_need]})
	var headroom := {}
	for surf in plats:
		var x0: int = plats[surf].keys()[0]
		headroom[surf] = surf * TILE - _top_above(x0, surf - 1)
	var rows := plats.keys()
	rows.sort()
	for i in rows.size():
		var r2: int = rows[i]
		for j in range(i + 1, rows.size()):
			var r1: int = rows[j]
			var rise := (r1 - r2) * TILE
			if rise <= 0 or float(rise) > apex + 4.0:
				continue
			if float(rise) > float(headroom.get(r1, apex)):
				continue
			if float(rise) <= limit:
				continue
			for xa in plats[r2]:
				var near := false
				for xb in plats[r1]:
					if absi(xa - xb) <= 7:
						near = true
						break
				if near:
					out.append({"rect": Rect2(xa * TILE, r2 * TILE - 4, TILE, 8),
						"text": "jump too high: %d px (her limit is %d)" % [rise, int(limit)]})


# ---------- roomcheck: doors ----------

func _solid5(x: int, y: int) -> bool:
	if y < 0 or y >= H or x < 0 or x >= W:
		return true
	return _blocker(String(g[y][x]))


func _doors(out: Array) -> void:
	for y in H:
		for x in [0, W - 1]:
			var ch: String = g[y][x]
			if ch != "D" and ch != "X":
				continue
			var inner: int = 1 if x == 0 else W - 2
			var blocked := false
			for yy in [y, y - 1, y - 2]:
				for xx in [x, inner]:
					if not (xx == x and yy == y) and _solid5(xx, yy):
						blocked = true
			if blocked:
				out.append({"rect": _rect(x, y - 2, 1, 3), "text": "door head blocked"})
			if y + 1 < H and not (_solid5(inner, y + 1) or g[y + 1][inner] == "="):
				out.append({"rect": _rect(inner, y, 1, 1), "text": "no floor under the door"})


func _backdrop(out: Array, doc: RefCounted) -> void:
	var bd := String(doc.head.get("backdrop", ""))
	if bd == "":
		return
	var EdAssets = load("res://editor/ed_assets.gd")
	if EdAssets.texture("backdrops/" + bd) == null:
		out.append({"rect": _rect(0, 0, mini(W, 6), 1), "text": "backdrop picture '%s' is missing" % bd})


# ---------- roomreach: can she get there ----------

func _c(x: int, y: int) -> String:
	if x < 0 or x >= W:
		return "E"
	if y < 0:
		return "^" if g[0][x] == "^" else "#"
	if y >= H:
		return "v" if g[H - 1][x] == "v" else "#"
	return g[y][x]


func _solid_r(ch: String) -> bool:
	return ch == "#" or ch == "B" or (not _gates_open and (ch == "|" or ch == "%" or ch == ":"))


func _free(x: int, y: int) -> bool:
	var ch := _c(x, y)
	return ch != "E" and not _solid_r(ch)


func _body(x: int, y: int) -> bool:
	return _free(x, y) and _free(x, y - 1) and _free(x, y - 2)


func _sup(x: int, y: int) -> bool:
	var ch := _c(x, y + 1)
	return _solid_r(ch) or ch == "=" or ch == "v" or (ch == ":" and (x == 0 or x == W - 1))


func _edge_exit(x: int, y: int) -> void:
	if x == 0 or x == W - 1:
		var ch: String = g[clampi(y, 0, H - 1)][x]
		var side := "left" if x == 0 else "right"
		if ch in ["D", "X", "<", ">", ":"]:
			_exits[side] = true
		elif ch == ".":
			if String(head.get(side, "")) != "":
				_exits[side] = true
			else:
				_exits["LEAK-" + side] = true


func _fall(x: int, y: int) -> Array:
	var key := Vector4i(0, x, y, 0)
	if _cache.has(key):
		var c: Array = _cache[key]
		for e in c[1]:
			_exits[e] = true
		return c[0]
	var global_ex := _exits.duplicate()
	_exits.clear()
	var out: Array = []
	var seen := {}
	var q: Array = [Vector3i(x, y, 0)]
	var qi := 0
	while qi < q.size():
		var s: Vector3i = q[qi]
		qi += 1
		if seen.has(s):
			continue
		seen[s] = true
		_edge_exit(s.x, s.y)
		if s.y >= H:
			_exits["down"] = true
			continue
		if _sup(s.x, s.y):
			out.append(Vector2i(s.x, s.y))
			continue
		if not _solid_r(_c(s.x, s.y + 1)):
			q.append(Vector3i(s.x, s.y + 1, s.z))
		if s.z < DFALL:
			for nx in [s.x - 1, s.x + 1]:
				if _body(nx, s.y):
					q.append(Vector3i(nx, s.y, s.z + 1))
	var ex := _exits.duplicate()
	_cache[key] = [out, ex]
	_exits = global_ex
	for e in ex:
		_exits[e] = true
	return out


func _air(x: int, y: int, rise: int, side: int, grip: bool) -> Array:
	var key := Vector4i(1, x, y, rise * 64 + side * 2 + (1 if grip else 0))
	if _cache.has(key):
		var c: Array = _cache[key]
		for e in c[1]:
			_exits[e] = true
		return c[0]
	var global_ex := _exits.duplicate()
	_exits.clear()
	var res := {}
	var seen := {}
	var q: Array = [Vector4i(x, y, 0, 0)]
	var qi := 0
	while qi < q.size():
		var s: Vector4i = q[qi]
		qi += 1
		if seen.has(s):
			continue
		seen[s] = true
		res[Vector2i(s.x, s.y)] = true
		_edge_exit(s.x, s.y)
		if s.y <= -1:
			_exits["up"] = true
			continue
		if s.z < rise and _body(s.x, s.y - 1):
			q.append(Vector4i(s.x, s.y - 1, s.z + 1, s.w))
		if s.w < side:
			for nx in [s.x - 1, s.x + 1]:
				if _body(nx, s.y):
					q.append(Vector4i(nx, s.y, s.z, s.w + 1))
	if grip:
		var more: Array = []
		for p in res.keys():
			if not _free(p.x - 1, p.y - 1) or not _free(p.x + 1, p.y - 1):
				more.append_array(_air(p.x, p.y, R2, D2, false))
		for p in more:
			res[p] = true
	var out: Array = res.keys()
	var ex := _exits.duplicate()
	_cache[key] = [out, ex]
	_exits = global_ex
	for e in ex:
		_exits[e] = true
	return out


func _reach(out: Array) -> void:
	_cache = {}
	_exits = {}
	var entries: Array = []        # [name, Vector2i where, [Vector3i(kind, x, y)]]
	for y in H:
		for x in [0, W - 1]:
			var ch: String = g[y][x]
			if ch in ["D", "X", "<", ">"] and (y + 1 >= H or not (String(g[y + 1][x]) in ["D", "X", "<", ">"])):
				entries.append([ch, Vector2i(x, y), [Vector3i(0 if _body(x, y) else 1, x, y)]])
	for x in W:
		if g[0][x] == "^" and _free(x, 1):
			var st: Array = []
			for p in _fall(x, 0):
				st.append(Vector3i(0, p.x, p.y))
			entries.append(["^", Vector2i(x, 0), st])
		if g[H - 1][x] == "v":
			var st2: Array = []
			for a in _air(x, H - 1, RPOP, 5, true):
				for p in _fall(a.x, a.y):
					st2.append(Vector3i(0, p.x, p.y))
			entries.append(["v", Vector2i(x, H - 1), st2])
	for y in H:
		for x in W:
			var ch2: String = g[y][x]
			if ch2 == "P" or ch2 == "K":
				var st3: Array = []
				for p in _fall(x, y):
					st3.append(Vector3i(0, p.x, p.y))
				entries.append([ch2, Vector2i(x, y), st3])
	var all_stand := {}
	for en in entries:
		var stand := {}
		var crawl := {}
		_exits = {}
		var q: Array = en[2].duplicate()
		var qi := 0
		while qi < q.size():
			var s: Vector3i = q[qi]
			qi += 1
			var pos := Vector2i(s.y, s.z)
			if s.x == 0:
				if stand.has(pos):
					continue
				stand[pos] = true
			else:
				if crawl.has(pos):
					continue
				crawl[pos] = true
			_edge_exit(pos.x, pos.y)
			for nx in [pos.x - 1, pos.x + 1]:
				if _body(nx, pos.y):
					for p in _fall(nx, pos.y):
						q.append(Vector3i(0, p.x, p.y))
				elif _free(nx, pos.y) and _sup(nx, pos.y):
					q.append(Vector3i(1, nx, pos.y))
			if s.x == 1:
				continue
			if _c(pos.x, pos.y + 1) == "v":
				_exits["down"] = true
			if _c(pos.x, pos.y + 1) == "=":
				for p in _fall(pos.x, pos.y + 1):
					q.append(Vector3i(0, p.x, p.y))
			for a in _air(pos.x, pos.y, rise_tiles, SIDE, true):
				for p in _fall(a.x, a.y):
					q.append(Vector3i(0, p.x, p.y))
		for p in stand:
			all_stand[p] = true
		var real := false
		for e in _exits:
			if not String(e).begins_with("LEAK"):
				real = true
		var at: Vector2i = en[1]
		if not real:
			out.append({"rect": _rect(at.x, at.y - 2, 1, 3), "text": "trapped: she cannot get out from here"})
		for e in _exits:
			if String(e).begins_with("LEAK"):
				out.append({"rect": _rect(at.x, at.y - 2, 1, 3), "text": "open edge with no exit (%s)" % String(e).substr(5)})
		for want in ["left", "right", "up", "down"]:
			if String(head.get(want, "")) != "" and not _exits.has(want) and String(en[0]) in ["D", "X", "<", ">", "^", "v", "P", "K"]:
				out.append({"rect": _rect(at.x, at.y - 2, 1, 3), "text": "she cannot reach the %s exit (%s)" % [want, head[want]]})
	for y in H:
		for x in W:
			var m: String = g[y][x]
			if (m >= "0" and m <= "9") or m == "M" or m == "T":
				var ok := false
				for sx in range(x - 1, x + 2):
					for sy in range(y - 1, y + 2):
						if all_stand.has(Vector2i(sx, sy)):
							ok = true
				if not ok:
					out.append({"rect": _rect(x, y), "text": "she cannot reach this (%s)" % m})
