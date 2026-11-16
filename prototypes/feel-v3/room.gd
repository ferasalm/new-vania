# PROTOTYPE - NOT FOR PRODUCTION
# Builds one room from a text grid (rooms/<name>.txt), 16 px per character:
#   #  solid stone      =  thin ledge (jump up through it, Down + Jump to drop)
#   P  start            H  hell-hound        G  ghost
#   D  door to the next room                 B  door back to the previous room
# The first line is "next=<room>" and/or "prev=<room>" (comma separated).
extends Node2D

const TILE := 16
# pieces of assets/env/church_tileset.png
const SLAB := Rect2(64, 167, 48, 16)     # floor top, 3 tiles wide
const FILL := Rect2(16, 112, 32, 32)     # stone below the top, 2x2 tiles
const PANELS := [Rect2(0, 0, 160, 192), Rect2(176, 0, 128, 192), Rect2(320, 0, 128, 192),
	Rect2(464, 0, 80, 192), Rect2(560, 0, 64, 192)]

var grid: Array = []          # rows of strings
var links := {}               # "next"/"prev" -> room name
var size := Vector2.ZERO      # in pixels
var spawns := {}              # "P"/"D"/"B" -> feet position
var enemies: Array = []       # [kind, feet position]
var doors: Array = []         # [{rect, to, key}]
var _tiles: Texture2D
var _bg: Texture2D
var _door: Texture2D


func load_room(room_name: String) -> bool:
	var txt := FileAccess.get_file_as_string("res://rooms/%s.txt" % room_name)
	if txt == "":
		push_error("missing room " + room_name)
		return false
	var lines := txt.split("\n", false)
	for part in lines[0].split(","):
		var kv := part.strip_edges().split("=")
		if kv.size() == 2:
			links[kv[0]] = kv[1]
	var w := 0
	for i in range(1, lines.size()):
		var row := lines[i].strip_edges(false, true)
		grid.append(row)
		w = maxi(w, row.length())
	size = Vector2(w * TILE, grid.size() * TILE)
	_tiles = G.tex("env/church_tileset.png")
	_bg = G.tex("env/church_backgrounds.png")
	_door = G.tex("env/fort_door.png")
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
			match ch:
				"P":
					spawns["P"] = feet
				"H":
					enemies.append(["hound", feet])
				"G":
					enemies.append(["ghost", feet - Vector2(0, 8)])
				"D", "B":
					var key := "next" if ch == "D" else "prev"
					# you arrive standing beside the door, on the room's inner side
					var inward := -1.0 if x > row.length() / 2 else 1.0
					spawns[ch] = feet + Vector2(inward * 44.0, 0)
					doors.append({"rect": Rect2(feet.x - 14, feet.y - 48, 28, 48),
						"to": links.get(key, ""), "key": ch, "feet": feet})
			x += 1


func _draw() -> void:
	# back wall: the church panels, dimmed, tiled over the whole room
	var i := 0
	var py := size.y - TILE * 2 - 192.0
	while py > -192.0:
		var px := 24.0
		while px < size.x:
			var src: Rect2 = PANELS[i % PANELS.size()]
			draw_texture_rect_region(_bg, Rect2(px, py, src.size.x, src.size.y), src, Color(0.8, 0.8, 0.9))
			px += src.size.x + 40.0
			i += 1
		py -= 200.0
	for d in doors:
		var feet: Vector2 = d["feet"]
		draw_texture(_door, feet - Vector2(_door.get_width() / 2.0, _door.get_height()))
	for y in grid.size():
		var row: String = grid[y]
		for x in row.length():
			var ch := row[x]
			var dst := Rect2(x * TILE, y * TILE, TILE, TILE)
			if ch == "#":
				if cell(x, y - 1) != "#":
					draw_texture_rect_region(_tiles, dst,
						Rect2(SLAB.position.x + (x % 3) * TILE, SLAB.position.y, TILE, TILE))
				else:
					draw_texture_rect_region(_tiles, dst,
						Rect2(FILL.position.x + (x % 2) * TILE, FILL.position.y + (y % 2) * TILE, TILE, TILE))
			elif ch == "=":
				draw_texture_rect_region(_tiles, Rect2(x * TILE, y * TILE, TILE, 10),
					Rect2(SLAB.position.x + (x % 3) * TILE, SLAB.position.y, TILE, 10))
