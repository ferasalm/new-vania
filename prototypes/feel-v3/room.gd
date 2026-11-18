# PROTOTYPE - NOT FOR PRODUCTION
# Builds one room from a text grid (rooms/<name>.txt), 16 px per character.
# Line 1 is the header: theme=<look>,music=<event>,left=<room>,right=<room>,up=<room>,down=<room>
#   #  solid          =  thin ledge (jump up through it, Down + Jump to drop)
#   P  start          D  door (only in the first or last column: the edge of the room)
#   X  the boss door  M  the save terminal       O  where the boss waits
#   K  the empty capsule she is rebuilt in       A  the wall-latch relic
#   H hound  G ghost  C choir  S spitter  W warden
#   c crab  m moth  n scribe  l leech  (the marsh enemies, enemy2.gd)
#   ^  an opening in the top row (header up=)      v  an opening in the bottom row (header down=)
#   <  >  an open edge with no door: walking off it goes to header left= / right=
#   L  the library lever   Y  the lever behind the iron bars   |  iron bars   %  a cracked wall
#   T  the time machine (feet position)
#   p pendulum, u crusher (ceiling cells)   f flame vent, i spikes (floor cells; a run of i is one strip)
# Each theme has its own wall art, tiles, door and music, so no two areas look alike.
# After the reality shift (load_room(name, true)) a room can be mirrored, use its <name>_shift.txt,
# and have other doors (SHIFT_ROUTES).
extends Node2D

const Door := preload("res://door.gd")
const Props := preload("res://props.gd")
const TILE := 16
const STAND := 36.0           # her standing height: a tunnel lower than this is a crawl
const ENEMY := {"H": "hound", "G": "ghost", "C": "choir", "S": "spitter", "W": "warden",
	"c": "crab", "m": "moth", "n": "scribe", "l": "leech"}
const HAZARD := {"p": "pendulum", "u": "crusher", "f": "flame", "i": "spikes"}
# rooms drawn back to front after the shift, and the doors that lead somewhere else then
const MIRRORED := ["library", "church"]
const SHIFT_ROUTES := {
	"hazard": {"right": "library"},
	"library": {"left": "hazard", "right": "church"},
	"church": {"left": "library", "right": "shaft"},
}
# pieces of assets/env/church_backgrounds.png (the church and sanctum back wall)
const PANELS := [Rect2(0, 0, 160, 192), Rect2(176, 0, 128, 192), Rect2(320, 0, 128, 192),
	Rect2(464, 0, 80, 192), Rect2(560, 0, 64, 192)]
const THEMES := {
	"church": {"tiles": "church", "wall": "panels", "tint": Color(0.8, 0.8, 0.9), "tile_tint": Color.WHITE,
		"clear": Color("#16141f"), "door": "church", "dust": Color(0.75, 0.7, 1.0, 0.5)},
	"library": {"tiles": "library", "wall": "env/library_wall.png", "tint": Color.WHITE, "tile_tint": Color.WHITE,
		"clear": Color("#1a0a0e"), "door": "library", "dust": Color(1.0, 0.85, 0.55, 0.55)},
	"lab": {"tiles": "lab", "wall": "env/lab_wall.png", "tint": Color.WHITE, "tile_tint": Color.WHITE,
		"clear": Color("#03080f"), "door": "lab", "dust": Color(0.5, 1.0, 1.0, 0.55)},
	# a save room is an ordinary room; the save point (capsules, brain, terminal) stands in it.
	# "point" is drawn so its empty capsule (POINT_K px from its left edge) stands on K.
	"save": {"tiles": "lab", "wall": "env/save_wall.png", "tint": Color.WHITE, "tile_tint": Color(0.8, 0.95, 1.0),
		"clear": Color("#020608"), "door": "save", "dust": Color(0.6, 1.0, 0.95, 0.5), "point": "env/save_point.png"},
	"save2": {"tiles": "lab", "wall": "env/save_wall2.png", "tint": Color.WHITE, "tile_tint": Color(0.85, 0.7, 1.0),
		"clear": Color("#070310"), "door": "save", "dust": Color(0.85, 0.7, 1.0, 0.5), "point": "env/save_point2.png"},
	"sanctum": {"tiles": "church", "wall": "panels", "tint": Color(0.62, 0.3, 0.85), "tile_tint": Color(0.75, 0.5, 1.0),
		"clear": Color("#0c0416"), "door": "boss", "dust": Color(1.0, 0.8, 0.3, 0.6)},
	# the marsh under the church: bone and brass stone, a dark bronze wall behind
	"ossuary": {"tiles": "church", "wall": "env/library_wall.png", "tint": Color(0.5, 0.34, 0.2), "tile_tint": Color(0.95, 0.85, 0.65),
		"clear": Color("#0f0a07"), "door": "church", "dust": Color(0.95, 0.75, 0.4, 0.5)},
	"ossuary_save": {"tiles": "church", "wall": "env/save_wall2.png", "tint": Color(1.0, 0.78, 0.5), "tile_tint": Color(0.95, 0.85, 0.65),
		"clear": Color("#0d0805"), "door": "save", "dust": Color(0.95, 0.75, 0.4, 0.5), "point": "env/save_point2.png"},
}

var grid: Array = []          # rows of strings
var head := {}                # the header line: theme, music, left, right, up, down
var theme := {}
var size := Vector2.ZERO      # in pixels
var spawns := {}              # "P"/"left"/"right"/"M"/"O"/"T"/"hole_up"/"hole_down" -> feet position
var enemies: Array = []       # [kind, feet position]
var hazards: Array = []       # [kind, Rect2 in world units]
var doors := {}               # "left"/"right" -> Door
var open_edges := {}          # "left"/"right" -> true when the edge has no door (< or >)
var tunnels := {}             # "left"/"right" -> true when that open edge is too low to stand in
var up_span := Vector2(-1.0, -1.0)    # x range (px) of the ^ cells in the top row
var down_span := Vector2(-1.0, -1.0)  # x range (px) of the v cells in the bottom row
var props: Array = []         # things a weapon cut can reach: levers, the cracked wall (prop_rect / prop_cut)
var organ: Node2D             # the time machine, if the room has one
var bars: Node2D
var shifted := false
var _tiles: Texture2D
var _ledge: Texture2D
var _wall: Texture2D
var _point: Texture2D
const POINT_K := 39.0     # tools/build_save_point.py prints it: the empty capsule's centre


func load_room(room_name: String, after_shift: bool = false) -> bool:
	shifted = after_shift
	var file := room_name
	if after_shift and FileAccess.file_exists("res://rooms/%s_shift.txt" % room_name):
		file = room_name + "_shift"
	var txt := FileAccess.get_file_as_string("res://rooms/%s.txt" % file)
	if txt == "":
		push_error("missing room " + room_name)
		return false
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
	if after_shift and MIRRORED.has(room_name):
		_mirror(w)
	if after_shift and SHIFT_ROUTES.has(room_name):
		for side in SHIFT_ROUTES[room_name]:
			head[side] = SHIFT_ROUTES[room_name][side]
	size = Vector2(w * TILE, grid.size() * TILE)
	theme = THEMES.get(head.get("theme", "church"), THEMES["church"])
	if theme["tiles"] != "":
		_tiles = G.tex("env/%s_tiles.png" % theme["tiles"])
		_ledge = G.tex("env/%s_ledge.png" % theme["tiles"])
	_wall = G.tex("env/church_backgrounds.png" if theme["wall"] == "panels" else theme["wall"])
	if theme.has("point"):
		_point = G.tex(theme["point"])
	_build()
	queue_redraw()
	return true


func _mirror(w: int) -> void:
	# the world turned back to front: every row reversed, left and right swapped
	for y in grid.size():
		var row: String = grid[y]
		while row.length() < w:
			row += "#"
		var flipped := ""
		for x in range(row.length() - 1, -1, -1):
			var ch := row[x]
			flipped += ">" if ch == "<" else ("<" if ch == ">" else ch)
		grid[y] = flipped
	var l: String = head.get("left", "")
	var r: String = head.get("right", "")
	head["left"] = r
	head["right"] = l
	if l == "":
		head.erase("right")
	if r == "":
		head.erase("left")


func cell(x: int, y: int) -> String:
	if y < 0 or y >= grid.size() or x < 0 or x >= grid[y].length():
		return "#"
	return grid[y][x]


func is_solid(x: int, y: int) -> bool:
	# for shots: stone, bars and a wall that has not broken yet
	var c := cell(x, y)
	return c == "#" or c == "|" or c == "%"


func clear_cells(r: Rect2) -> void:
	# bars lifted or a wall broken: those cells are open air now
	for cy in range(int(r.position.y / TILE), int(r.end.y / TILE)):
		for cx in range(int(r.position.x / TILE), int(r.end.x / TILE)):
			if cy >= 0 and cy < grid.size() and cx >= 0 and cx < grid[cy].length():
				var row: String = grid[cy]
				grid[cy] = row.substr(0, cx) + "." + row.substr(cx + 1)


func _flags() -> Object:
	return G.main if G.main != null else null


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
	var up_cells: Array = []
	var down_cells: Array = []
	var last_row := grid.size() - 1
	for y in grid.size():
		var x := 0
		var row: String = grid[y]
		while x < row.length():
			var ch := row[x]
			if ch == "#" or ch == "=":
				var start := x
				while x < row.length() and row[x] == ch:
					x += 1
				var shape := CollisionShape2D.new()
				var rect := RectangleShape2D.new()
				var h := float(TILE) if ch == "#" else 6.0
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
			if ENEMY.has(ch):
				enemies.append([ENEMY[ch], feet])
			elif HAZARD.has(ch):
				if ch == "i":
					# a run of spikes is one strip
					var start2 := x
					while x + 1 < row.length() and row[x + 1] == "i":
						x += 1
					hazards.append([HAZARD[ch], Rect2(start2 * TILE, y * TILE, (x - start2 + 1) * TILE, TILE)])
				else:
					hazards.append([HAZARD[ch], Rect2(x * TILE, y * TILE, TILE, TILE)])
			elif ch == "P" or ch == "M" or ch == "O" or ch == "K" or ch == "A" or ch == "T":
				spawns[ch] = feet
			elif ch == "L" or ch == "Y":
				_add_lever(feet, "library" if ch == "L" else "bars")
			elif ch == "|":
				bar_cells.append(Vector2i(x, y))
			elif ch == "%":
				crack_cells.append(Vector2i(x, y))
			elif ch == "^" and y == 0:
				up_cells.append(x)
			elif ch == "v" and y == last_row:
				down_cells.append(x)
			elif ch == "<" or ch == ">":
				_open_edge(x, y, ch)
			elif ch == "D" or ch == "X":
				# a door lives in the edge column; she walks off the screen through it
				var side := "left" if x == 0 else "right"
				var d := Door.new()
				d.setup(side, ch == "X", theme["door"] if ch == "D" else "boss", head.get(side, ""))
				d.position = Vector2(0.0 if side == "left" else size.x - TILE, feet.y)
				if d.to == "":
					d.sealed_msg = "LOCKED - UNTIL THE NEXT UPDATE"
				add_child(d)
				doors[side] = d
				spawns[side] = Vector2(26.0 if side == "left" else size.x - 26.0, feet.y)
			x += 1
	if not up_cells.is_empty():
		up_span = Vector2(up_cells.min() * TILE, (up_cells.max() + 1) * TILE)
		spawns["hole_up"] = Vector2((up_span.x + up_span.y) / 2.0, 6.0)
	if not down_cells.is_empty():
		down_span = Vector2(down_cells.min() * TILE, (down_cells.max() + 1) * TILE)
		spawns["hole_down"] = Vector2((down_span.x + down_span.y) / 2.0, size.y)
	var main: Object = _flags()
	for group in _groups(bar_cells):
		var b := Props.Bars.new()
		b.setup(group, main != null and main.bars_opened)
		add_child(b)
		bars = b
		if main != null and main.bars_opened:
			clear_cells(group)
	for group in _groups(crack_cells):
		var cw := Props.CrackWall.new()
		cw.setup(group, _tiles, theme["tile_tint"], main != null and main.wall_broken)
		add_child(cw)
		if main != null and main.wall_broken:
			clear_cells(group)
		else:
			props.append(cw)
	if spawns.has("T"):
		organ = Props.Organ.new()
		organ.position = spawns["T"]
		organ.dead = G.shifted
		organ.setup()
		add_child(organ)


func _add_lever(feet: Vector2, kind: String) -> void:
	var lv := Props.Lever.new()
	var main: Object = _flags()
	var done := false
	if main != null:
		done = main.lever_library if kind == "library" else main.bars_opened
	lv.setup(kind, done)
	lv.position = feet
	add_child(lv)
	props.append(lv)


func _open_edge(x: int, y: int, ch: String) -> void:
	# a gap in the side wall with no door: she walks off the edge into the next room
	var side := "left" if ch == "<" else "right"
	if (side == "left" and x != 0) or (side == "right" and x != grid[y].length() - 1):
		return
	open_edges[side] = true
	if cell(x, y + 1) == ch:
		return          # not the lowest cell of this opening
	# the lowest cell is where she stands; count the open cells above it
	var open_h := 0
	var yy := y
	while yy >= 0 and cell(x, yy) == ch:
		open_h += 1
		yy -= 1
	spawns[side] = Vector2(14.0 if side == "left" else size.x - 14.0, (y + 1) * TILE)
	tunnels[side] = float(open_h * TILE) < STAND


func _groups(cells: Array) -> Array:
	# neighbouring cells make one rectangle (bars, a cracked wall): the bounding box of each group
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
	if theme["wall"] == "panels":
		# the church panels, dimmed, tiled over the whole room
		var i := 0
		var py := size.y - TILE * 2 - 192.0
		while py > -192.0:
			var px := 24.0
			while px < size.x:
				var src: Rect2 = PANELS[i % PANELS.size()]
				draw_texture_rect_region(_wall, Rect2(px, py, src.size.x, src.size.y), src, tint)
				px += src.size.x + 40.0
				i += 1
			py -= 200.0
	elif _wall != null:
		# one wall picture repeated sideways (and upward in a tall room), standing on the floor
		var ws := _wall.get_size()
		var bottom := size.y if theme["tiles"] == "" else size.y - TILE
		var y := bottom - ws.y
		while y > -ws.y:
			var x := 0.0
			while x < size.x:
				draw_texture(_wall, Vector2(x, y), tint)
				x += ws.x
			y -= ws.y
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
			elif ch == "=":
				draw_texture_rect_region(_ledge, Rect2(x * TILE, y * TILE, TILE, 8),
					Rect2((x % 4) * TILE, 0, TILE, 8), tt)
