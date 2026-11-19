# PROTOTYPE - NOT FOR PRODUCTION
# Builds one room from a text grid (rooms/<name>.txt), 16 px per character.
# Line 1 is the header: theme=<look>,music=<event>,left=<room>,right=<room>,up=<room>,down=<room>
#   #  solid          =  thin ledge (jump up through it, Down + Jump to drop)
#   P  start          D  door (only in the first or last column: the edge of the room)
#   X  boss/sealed door  M  save terminal       O  boss spawn
#   K  empty capsule     A  relic               B  bricked arch
#   :  one-way shutter   1-9 markers (items, candles, winch)
#   H hound  G ghost  C choir  S spitter  W warden
#   c crab   m moth   n scribe l leech
#   ^  opening in top row (header up=)      v  opening in bottom row (header down=)
#   <  >  open edge with no door: walking off goes to header left= / right=
#   L  library lever   Y  lever behind iron bars   |  iron bars   %  cracked wall
#   T  time machine (organ)
#   p pendulum, u crusher, f flame vent, i spikes
extends Node2D

const Door := preload("res://door.gd")
const Props := preload("res://props.gd")
const Spawner := preload("res://spawner.gd")
const PropsLayer := preload("res://editor/props_layer.gd")
const TILE := 16
const STAND := 36.0

const HAZARD := {"p": "pendulum", "u": "crusher", "f": "flame", "i": "spikes"}

const PANELS := [
	Rect2(0, 0, 160, 192), Rect2(176, 0, 128, 192), Rect2(320, 0, 128, 192),
	Rect2(464, 0, 80, 192), Rect2(560, 0, 64, 192)
]

const THEMES := {
	"church": {"tiles": "church", "wall": "panels", "tint": Color(0.8, 0.8, 0.9), "tile_tint": Color.WHITE,
		"clear": Color("#16141f"), "door": "church", "dust": Color(0.75, 0.7, 1.0, 0.5)},
	"library": {"tiles": "library", "wall": "env/library_wall.png", "tint": Color.WHITE, "tile_tint": Color.WHITE,
		"clear": Color("#1a0a0e"), "door": "library", "dust": Color(1.0, 0.85, 0.55, 0.55)},
	"lab": {"tiles": "lab", "wall": "env/lab_wall.png", "tint": Color.WHITE, "tile_tint": Color.WHITE,
		"clear": Color("#03080f"), "door": "lab", "dust": Color(0.5, 1.0, 1.0, 0.55)},
	"save": {"tiles": "lab", "wall": "env/save_wall.png", "tint": Color.WHITE, "tile_tint": Color(0.8, 0.95, 1.0),
		"clear": Color("#020608"), "door": "save", "dust": Color(0.6, 1.0, 0.95, 0.5), "point": "env/save_point.png"},
	"save2": {"tiles": "lab", "wall": "env/save_wall2.png", "tint": Color.WHITE, "tile_tint": Color(0.85, 0.7, 1.0),
		"clear": Color("#070310"), "door": "save", "dust": Color(0.85, 0.7, 1.0, 0.5), "point": "env/save_point2.png"},
	"sanctum": {"tiles": "church", "wall": "panels", "tint": Color(0.62, 0.3, 0.85), "tile_tint": Color(0.75, 0.5, 1.0),
		"clear": Color("#0c0416"), "door": "boss", "dust": Color(1.0, 0.8, 0.3, 0.6)},
	"ossuary": {"tiles": "church", "wall": "env/library_wall.png", "tint": Color(0.5, 0.34, 0.2), "tile_tint": Color(0.95, 0.85, 0.65),
		"clear": Color("#0f0a07"), "door": "church", "dust": Color(0.95, 0.75, 0.4, 0.5)},
	"ossuary_save": {"tiles": "church", "wall": "env/save_wall2.png", "tint": Color(1.0, 0.78, 0.5), "tile_tint": Color(0.95, 0.85, 0.65),
		"clear": Color("#0d0805"), "door": "save", "dust": Color(0.95, 0.75, 0.4, 0.5), "point": "env/save_point2.png"},
}

const POINT_K := 39.0

## The room builder's live copy of a room that is not saved yet: file id -> room text.
static var override := {}

var file_id := ""
var grid: Array = []
var head := {}
var theme := {}
var size := Vector2.ZERO
var spawns := {}
var enemies: Array = []       # [kind, feet position], from the enemies.json glyphs
var enemy_nodes: Array = []   # the enemy nodes this room owns
var hazards: Array = []
var doors := {}               # one primary door per side, for the map and the old callers
var doors_all: Array = []     # every door, when a side holds two
var open_edges := {}
var tunnels := {}
var up_span := Vector2(-1.0, -1.0)
var down_span := Vector2(-1.0, -1.0)
var props: Array = []
var organ: Node2D
var bars: Node2D
var shifted := false
var marks: Dictionary = {}

var meta: Dictionary:
	get: return W.meta(file_id)

var _tiles: Texture2D
var _ledge: Texture2D
var _wall: Texture2D
var _point: Texture2D
var _glyphs := {}             # enemy letter -> enemies.json id


func backdrop_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var px := 0.0
	var pw := 160.0
	while px < size.x:
		var w := minf(pw, size.x - px)
		out.append(Rect2(px, 0.0, w, size.y))
		px += w
	return out


func load_room(room_name: String, after_shift: bool = false) -> bool:
	shifted = after_shift or G.shifted or W.sheet == "after"
	var file := room_name

	if W.sheet == "restored":
		if FileAccess.file_exists("res://rooms/%s_restored.txt" % room_name):
			file = room_name + "_restored"
		elif room_name == "vault":
			file = "vault_restored"
	elif shifted:
		if FileAccess.file_exists("res://rooms/%s_shift.txt" % room_name):
			file = room_name + "_shift"
		elif FileAccess.file_exists("res://rooms/%s.txt" % room_name):
			file = room_name

	if not FileAccess.file_exists("res://rooms/%s.txt" % file):
		file = room_name

	file_id = file
	W.mark_visited(file_id)
	W.mark_visited(room_name)

	var txt := String(override[file]) if override.has(file) else FileAccess.get_file_as_string("res://rooms/%s.txt" % file)
	if txt == "":
		push_error("missing room " + file)
		return false

	grid.clear()
	head.clear()
	spawns.clear()
	enemies.clear()
	enemy_nodes.clear()
	hazards.clear()
	doors.clear()
	doors_all.clear()
	open_edges.clear()
	tunnels.clear()
	props.clear()
	marks.clear()

	_glyphs.clear()
	var enemy_defs: Dictionary = Db.table("enemies")
	for id in enemy_defs:
		var glyph := String(enemy_defs[id].get("glyph", ""))
		if glyph != "":
			_glyphs[glyph] = String(id)

	var lines := txt.replace("\r", "").split("\n", false)
	for part in lines[0].split(","):
		var kv := part.strip_edges().split("=")
		if kv.size() == 2:
			head[kv[0]] = kv[1]

	var w := 0
	for i in range(1, lines.size()):
		var row := lines[i].strip_edges(false, true)
		grid.append(row)
		w = maxi(w, row.length())

	size = Vector2(w * TILE, grid.size() * TILE)
	theme = THEMES.get(head.get("theme", "church"), THEMES["church"])
	if theme["tiles"] != "":
		_tiles = G.tex("env/%s_tiles.png" % theme["tiles"])
		_ledge = G.tex("env/%s_ledge.png" % theme["tiles"])
	_wall = G.tex("env/church_backgrounds.png" if theme["wall"] == "panels" else theme["wall"])
	if head.has("backdrop"):
		_wall = PropsLayer.backdrop_texture(String(head["backdrop"]), _wall)      # the builder's own wall picture, tiled at real size
	if theme.has("point"):
		_point = G.tex(theme["point"])

	_build()
	queue_redraw()
	return true


func cell(x: int, y: int) -> String:
	if y < 0 or y >= grid.size() or x < 0 or x >= grid[y].length():
		return "#"
	return grid[y][x]


func is_solid(x: int, y: int) -> bool:
	var c := cell(x, y)
	return c == "#" or c == "|" or c == "%" or c == "B" or c == ":"


func clear_cells(r: Rect2) -> void:
	for cy in range(int(r.position.y / TILE), int(r.end.y / TILE)):
		for cx in range(int(r.position.x / TILE), int(r.end.x / TILE)):
			if cy >= 0 and cy < grid.size() and cx >= 0 and cx < grid[cy].length():
				var row: String = grid[cy]
				grid[cy] = row.substr(0, cx) + "." + row.substr(cx + 1)


func _build() -> void:
	var solid := StaticBody2D.new()
	solid.collision_layer = 1
	solid.collision_mask = 0
	add_child(solid)

	var ledge := StaticBody2D.new()
	ledge.collision_layer = 2
	ledge.collision_mask = 0
	add_child(ledge)

	var bar_cells: Array = []
	var crack_cells: Array = []
	var shutter_cells: Array = []
	var up_cells: Array = []
	var down_cells: Array = []
	var enemy_spawns: Array = []
	var last_row := grid.size() - 1

	for y in grid.size():
		var x := 0
		var row: String = grid[y]
		while x < row.length():
			var ch := row[x]
			if ch == "#" or ch == "=" or ch == "B":
				var start := x
				while x < row.length() and (row[x] == ch or (ch == "#" and row[x] == "B") or (ch == "B" and row[x] == "#")):
					x += 1
				var shape := CollisionShape2D.new()
				var rect := RectangleShape2D.new()
				var h := float(TILE) if ch != "=" else 6.0
				rect.size = Vector2((x - start) * TILE, h)
				shape.shape = rect
				shape.position = Vector2((start + x) * TILE / 2.0, y * TILE + h / 2.0)
				if ch == "=":
					shape.one_way_collision = true
					ledge.add_child(shape)
				else:
					solid.add_child(shape)
				continue

			var feet := Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)

			if _glyphs.has(ch):
				enemy_spawns.append([_glyphs[ch], feet])
			elif HAZARD.has(ch):
				if ch == "i":
					var start2 := x
					while x + 1 < row.length() and row[x + 1] == "i":
						x += 1
					hazards.append([HAZARD[ch], Rect2(start2 * TILE, y * TILE, (x - start2 + 1) * TILE, TILE)])
				else:
					hazards.append([HAZARD[ch], Rect2(x * TILE, y * TILE, TILE, TILE)])
			elif ch == "P" or ch == "M" or ch == "O" or ch == "K" or ch == "A" or ch == "T":
				spawns[ch] = feet
			elif ch >= "1" and ch <= "9":
				marks[ch] = feet
				spawns[ch] = feet
				_add_marked_prop(ch, feet)
			elif ch == "L" or ch == "Y":
				_add_lever(feet, "library" if ch == "L" else "bars")
			elif ch == "|":
				bar_cells.append(Vector2i(x, y))
			elif ch == "%":
				crack_cells.append(Vector2i(x, y))
			elif ch == ":":
				shutter_cells.append(Vector2i(x, y))
			elif ch == "^" and y == 0:
				up_cells.append(x)
			elif ch == "v" and y == last_row:
				down_cells.append(x)
				var cover := CollisionShape2D.new()
				var cover_rect := RectangleShape2D.new()
				cover_rect.size = Vector2(TILE, 6.0)
				cover.shape = cover_rect
				cover.position = Vector2(x * TILE + TILE / 2.0, y * TILE + 3.0)
				cover.one_way_collision = true
				ledge.add_child(cover)
			elif ch == "<" or ch == ">":
				_open_edge(x, y, ch)
			elif ch == "D" or ch == "X":
				var side := "left" if x == 0 else "right"
				var d := Door.new()
				var door_theme: String = theme["door"] if ch == "D" else "boss"
				d.setup(side, ch == "X", door_theme, _door_target(side, y))
				d.position = Vector2(0.0 if side == "left" else size.x - TILE, feet.y)
				add_child(d)
				doors[side] = d
				doors_all.append(d)
				spawns[side] = Vector2(26.0 if side == "left" else size.x - 26.0, feet.y)
			x += 1

	if not up_cells.is_empty():
		up_span = Vector2(up_cells.min() * TILE, (up_cells.max() + 1) * TILE)
		spawns["hole_up"] = Vector2((up_span.x + up_span.y) / 2.0, 6.0)
	if not down_cells.is_empty():
		down_span = Vector2(down_cells.min() * TILE, (down_cells.max() + 1) * TILE)
		spawns["hole_down"] = Vector2((down_span.x + down_span.y) / 2.0, size.y)

	var main_obj: Object = G.main if G.main != null else null
	for group in _groups(bar_cells):
		var b := Props.Bars.new()
		var bars_done: bool = main_obj != null and main_obj.get("bars_opened")
		b.setup(group, bars_done)
		add_child(b)
		bars = b
		if bars_done:
			clear_cells(group)

	for group in _groups(crack_cells):
		var cw := Props.CrackWall.new()
		var wall_done: bool = main_obj != null and main_obj.get("wall_broken")
		cw.setup(group, _tiles, theme["tile_tint"], wall_done)
		add_child(cw)
		if wall_done:
			clear_cells(group)
		else:
			props.append(cw)

	for group in _groups(shutter_cells):
		var sh := Props.Shutter.new()
		var shutter_done: bool = W.flag("shutter_" + file_id)
		sh.setup(group, file_id, shutter_done)
		add_child(sh)
		if shutter_done:
			clear_cells(group)

	if spawns.has("T"):
		organ = Props.Organ.new()
		organ.position = spawns["T"]
		organ.dead = G.shifted
		organ.setup()
		add_child(organ)

	# Build decor from rooms_meta
	var decor_list: Array = meta.get("decor", [])
	for dec in decor_list:
		if dec is Dictionary:
			var d_type: String = dec.get("type", "claws")
			var d_tile: Array = dec.get("tile", [0, 0])
			var d_node := Props.Decor.new()
			d_node.setup(d_type)
			d_node.position = Vector2(d_tile[0] * TILE + 8, d_tile[1] * TILE + 8)
			add_child(d_node)

	# Record and place every enemy: the room owns the nodes, main only lists them
	for e in enemy_spawns:
		enemies.append(e)
		var en: Node2D = Spawner.enemy(e[0], e[1])
		if en != null:
			add_child(en)
			enemy_nodes.append(en)
	# PNG props and tiles from the room builder sit behind everything that moves
	var pl := PropsLayer.new()
	pl.setup(file_id)
	add_child(pl)
	move_child(pl, 0)


func _door_target(side: String, y: int) -> String:
	# the header names the room's main door; a second door on the same side takes
	# its target from the meta exit in the same cell row
	var fallback := String(head.get(side, ""))
	var at := int(floor(float(y) / 14.0))
	var letter := "L" if side == "left" else "R"
	var m: Dictionary = meta
	for ex in m.get("exits", []):
		if ex is Dictionary and String(ex.get("side", "")) == letter and int(ex.get("at", 0)) == at:
			return String(ex.get("to", fallback))
	return fallback


func _add_marked_prop(marker_char: String, feet: Vector2) -> void:
	var m_meta: Dictionary = meta.get("marks", {}).get(marker_char, {})
	var m_type: String = m_meta.get("type", "")
	match m_type:
		"candle":
			var c_num: int = int(m_meta.get("candle", 1))
			var candle_prop := Props.Candle.new()
			candle_prop.setup(c_num, W.flag("candle_%d" % c_num))
			candle_prop.position = feet
			add_child(candle_prop)
			props.append(candle_prop)
		"winch":
			var winch_prop := Props.Winch.new()
			winch_prop.setup(W.flag("winch_turned"))
			winch_prop.position = feet
			add_child(winch_prop)
			props.append(winch_prop)
		"lever":
			var l_flag: String = m_meta.get("flag", "lever_library")
			_add_lever(feet, "library" if l_flag == "lever_library" else "bars")


func _add_lever(feet: Vector2, kind: String) -> void:
	var lv := Props.Lever.new()
	var done := false
	if G.main != null:
		done = G.main.lever_library if kind == "library" else G.main.bars_opened
	else:
		done = W.flag("lever_library" if kind == "library" else "bars_opened")
	lv.setup(kind, done)
	lv.position = feet
	add_child(lv)
	props.append(lv)


func _open_edge(x: int, y: int, ch: String) -> void:
	var side := "left" if ch == "<" else "right"
	if (side == "left" and x != 0) or (side == "right" and x != grid[y].length() - 1):
		return
	open_edges[side] = true
	if cell(x, y + 1) == ch:
		return
	var open_h := 0
	var yy := y
	while yy >= 0 and cell(x, yy) == ch:
		open_h += 1
		yy -= 1
	spawns[side] = Vector2(14.0 if side == "left" else size.x - 14.0, (y + 1) * TILE)
	tunnels[side] = float(open_h * TILE) < STAND


func _groups(cells: Array) -> Array:
	var out: Array = []
	var left: Array = cells.duplicate()
	while not left.is_empty():
		var todo: Array = [left.pop_back()]
		var lo: Vector2i = todo[0]
		var hi: Vector2i = todo[0]
		while not todo.is_empty():
			var c: Vector2i = todo.pop_back()
			lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
			hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
			for n in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if left.has(c + n):
					left.erase(c + n)
					todo.append(c + n)
		out.append(Rect2(Vector2(lo) * TILE, Vector2(hi - lo + Vector2i.ONE) * TILE))
	return out


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), theme["clear"])
	var tint: Color = theme["tint"]

	# Draw the backdrop wall behind the whole room: the picture keeps its
	# real size and is repeated to fill, so it is never squeezed or stretched
	for rect in backdrop_rects():
		if _wall != null:
			_draw_wall(rect, tint)
		else:
			draw_rect(rect, theme["clear"] * Color(1.2, 1.2, 1.2))

	if _point != null and spawns.has("K") and theme.has("point"):
		var k: Vector2 = spawns["K"]
		draw_texture(_point, Vector2(round(k.x - POINT_K), k.y - _point.get_size().y))

	if _tiles == null:
		return

	var tt: Color = theme["tile_tint"]
	for y in grid.size():
		var row: String = grid[y]
		for x in row.length():
			var ch := row[x]
			if ch == "#":
				var depth := 0
				if cell(x, y - 1) == "#":
					depth = 1 if cell(x, y - 2) != "#" else 2
				draw_texture_rect_region(_tiles, Rect2(x * TILE, y * TILE, TILE, TILE),
					Rect2((x % 4) * TILE, depth * TILE, TILE, TILE), tt)
			elif ch == "B":
				# Bricked arch (dark amber/reddish brick)
				draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), Color(0.35, 0.2, 0.18))
				draw_rect(Rect2(x * TILE + 1, y * TILE + 1, TILE - 2, TILE - 2), Color(0.48, 0.28, 0.22))
			elif ch == "=" or ch == "v":
				draw_texture_rect_region(_ledge, Rect2(x * TILE, y * TILE, TILE, 8),
					Rect2((x % 4) * TILE, 0, TILE, 8), tt)


# The backdrop wall is painted with copies of the picture at its real size,
# so it is never stretched out of shape. Copies repeat across the room from
# its left edge, and on rooms taller than the picture more copies stack
# upwards from the floor, so the picture always sits on the ground line.
func _draw_wall(rect: Rect2, tint: Color) -> void:
	var tw := _wall.get_size().x
	var th := _wall.get_size().y
	if tw <= 0.0 or th <= 0.0:
		return
	var j0 := int(floorf(rect.position.x / tw))
	var j1 := int(floorf((rect.position.x + rect.size.x - 0.01) / tw))
	var k := 0
	while size.y - k * th > rect.position.y:
		var y := size.y - (k + 1) * th
		if y < rect.end.y:
			for j in range(j0, j1 + 1):
				var where := Rect2(j * tw, y, tw, th)
				var vis := where.intersection(rect)
				if vis.size.x <= 0.0 or vis.size.y <= 0.0:
					continue
				draw_texture_rect_region(_wall, vis,
					Rect2(vis.position - where.position, vis.size), tint)
		k += 1
