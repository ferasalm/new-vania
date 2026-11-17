# PROTOTYPE - NOT FOR PRODUCTION
# Builds one room from a text grid (rooms/<name>.txt), 16 px per character.
# Line 1 is the header: theme=<look>,music=<event>,left=<room>,right=<room>,title=<words>
#   #  solid          =  thin ledge (jump up through it, Down + Jump to drop)
#   P  start          D  door (only in the first or last column: the edge of the room)
#   X  the boss door  M  the save terminal       O  where the boss waits
#   K  the empty capsule she is rebuilt in       A  the wall-latch relic
#   H hound  G ghost  C choir  S spitter  W warden
# Each theme has its own wall art, tiles, door and music, so no two areas look alike.
extends Node2D

const Door := preload("res://door.gd")
const TILE := 16
const ENEMY := {"H": "hound", "G": "ghost", "C": "choir", "S": "spitter", "W": "warden"}
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
}

var grid: Array = []          # rows of strings
var head := {}                # the header line: theme, music, left, right, title
var theme := {}
var size := Vector2.ZERO      # in pixels
var spawns := {}              # "P"/"left"/"right"/"M"/"O" -> feet position
var enemies: Array = []       # [kind, feet position]
var doors := {}               # "left"/"right" -> Door
var _tiles: Texture2D
var _ledge: Texture2D
var _wall: Texture2D
var _point: Texture2D
const POINT_K := 39.0     # tools/build_save_point.py prints it: the empty capsule's centre


func load_room(room_name: String) -> bool:
	var txt := FileAccess.get_file_as_string("res://rooms/%s.txt" % room_name)
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


func cell(x: int, y: int) -> String:
	if y < 0 or y >= grid.size() or x < 0 or x >= grid[y].length():
		return "#"
	return grid[y][x]


func _build() -> void:
	var solid := StaticBody2D.new()
	solid.collision_layer = 1
	solid.collision_mask = 0
	add_child(solid)
	var ledge := StaticBody2D.new()
	ledge.collision_layer = 2
	ledge.collision_mask = 0
	add_child(ledge)
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
			elif ch == "P" or ch == "M" or ch == "O" or ch == "K" or ch == "A":
				spawns[ch] = feet
			elif ch == "D" or ch == "X":
				# a door lives in the edge column; she walks off the screen through it
				var side := "left" if x == 0 else "right"
				var d := Door.new()
				d.setup(side, ch == "X", theme["door"] if ch == "D" else "boss", head.get(side, ""))
				d.position = Vector2(0.0 if side == "left" else size.x - TILE, feet.y)
				add_child(d)
				doors[side] = d
				spawns[side] = Vector2(26.0 if side == "left" else size.x - 26.0, feet.y)
			x += 1


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
	if _point != null and spawns.has("K"):
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
