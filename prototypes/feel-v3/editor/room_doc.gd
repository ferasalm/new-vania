# PROTOTYPE - NOT FOR PRODUCTION
# The room builder's data: one room as text, with no scene attached, so it can be tested
# without running the game. The text is exactly what rooms/<name>.txt holds:
#   line 1  header  theme=lab,music=music_lab,left=lab,right=boss,...
#   rest    the grid, 16 px per character (see room.gd for what every character means)
# PNG props and tiles live next to it in rooms/<name>.props.json:
#   [{"png": "props/x.png", "x": 32, "y": 48, "flip": false, "layer": "back|solid|front", "tile": false}]
extends RefCounted

const TILE := 16
const FLYERS := ["m", "G"]      # enemy glyphs that hover: spread puts them in open air
const UNDO_MAX := 100

var file_id := ""
var head := {}                  # header key -> value, in file order
var rows: Array = []            # one String per grid row
var props: Array = []           # PNG props and tiles (dictionaries)

var _undo: Array = []
var _redo: Array = []


## Build a document from the text of a room file and (optionally) its props json.
static func parse(id: String, text: String, props_text := "") -> RefCounted:
	var d: RefCounted = load("res://editor/room_doc.gd").new()
	d.file_id = id
	var lines := text.replace("\r", "").split("\n", false)
	if lines.size() > 0:
		for part in lines[0].split(","):
			var kv := part.strip_edges().split("=")
			if kv.size() == 2:
				d.head[kv[0]] = kv[1]
	for i in range(1, lines.size()):
		d.rows.append(lines[i].strip_edges(false, true))
	if props_text.strip_edges() != "":
		var parsed = JSON.parse_string(props_text)
		if parsed is Array:
			for p in parsed:
				if p is Dictionary:
					d.props.append(p.duplicate(true))
	return d


func width() -> int:
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	return w


func height() -> int:
	return rows.size()


func pixel_size() -> Vector2:
	return Vector2(width() * TILE, height() * TILE)


## The character at a cell; anything outside the room counts as solid, like room.gd.
func get_cell(x: int, y: int) -> String:
	if y < 0 or y >= rows.size() or x < 0 or x >= String(rows[y]).length():
		return "#"
	return String(rows[y])[x]


func in_room(x: int, y: int) -> bool:
	return y >= 0 and y < rows.size() and x >= 0 and x < String(rows[y]).length()


## Set one cell. Returns true when something changed.
func set_cell(x: int, y: int, ch: String) -> bool:
	if not in_room(x, y) or ch.length() != 1:
		return false
	var row: String = rows[y]
	if row[x] == ch:
		return false
	rows[y] = row.substr(0, x) + ch + row.substr(x + 1)
	return true


## The text that goes into rooms/<name>.txt.
func to_text() -> String:
	var parts: Array = []
	for k in head:
		parts.append("%s=%s" % [k, head[k]])
	var out := ",".join(parts) + "\n"
	for r in rows:
		out += String(r) + "\n"
	return out


func props_text() -> String:
	return JSON.stringify(props, "  ", false) + "\n"


# ---------- undo / redo (whole-room snapshots: rooms are small) ----------

func _snap() -> Dictionary:
	return {"head": head.duplicate(), "rows": rows.duplicate(), "props": props.duplicate(true)}


func _restore(s: Dictionary) -> void:
	head = s["head"].duplicate()
	rows = s["rows"].duplicate()
	props = s["props"].duplicate(true)


## Call before a change; one call per user action (a whole paint stroke is one step).
func push_undo() -> void:
	_undo.append(_snap())
	if _undo.size() > UNDO_MAX:
		_undo.pop_front()
	_redo.clear()


func can_undo() -> bool:
	return not _undo.is_empty()


func can_redo() -> bool:
	return not _redo.is_empty()


func undo() -> bool:
	if _undo.is_empty():
		return false
	_redo.append(_snap())
	_restore(_undo.pop_back())
	return true


func redo() -> bool:
	if _redo.is_empty():
		return false
	_undo.append(_snap())
	_restore(_redo.pop_back())
	return true


# ---------- resizing ----------

## Make the room w x h characters. New cells are empty air; shrinking cuts the right and bottom.
func resize(w: int, h: int) -> void:
	w = maxi(4, w)
	h = maxi(4, h)
	var out: Array = []
	for y in h:
		var row: String = rows[y] if y < rows.size() else ""
		if row.length() > w:
			row = row.substr(0, w)
		else:
			row += ".".repeat(w - row.length())
		out.append(row)
	rows = out


# ---------- props ----------

func add_prop(png: String, x: int, y: int, layer: String, is_tile: bool, flip := false) -> Dictionary:
	var p := {"png": png, "x": x, "y": y, "flip": flip, "layer": layer, "tile": is_tile}
	props.append(p)
	return p


## The topmost prop whose rectangle holds the pixel (sizes come from the caller, which knows the textures).
func prop_at(px: Vector2, size_of: Callable) -> int:
	for i in range(props.size() - 1, -1, -1):
		var p: Dictionary = props[i]
		var s: Vector2 = size_of.call(String(p["png"]))
		if Rect2(Vector2(p["x"], p["y"]), s).has_point(px):
			return i
	return -1


# ---------- spreading enemies ----------

## Can she stand in this cell: it is empty, solid ground or a ledge is under it, and three tiles
## are clear from the cell up (her height is 36 px, a bit over two tiles).
func standable(x: int, y: int) -> bool:
	if not _open(x, y):
		return false
	var below := get_cell(x, y + 1)
	if below != "#" and below != "=" and below != "B":
		return false
	return _open(x, y - 1) and _open(x, y - 2)


func _open(x: int, y: int) -> bool:
	return in_room(x, y) and get_cell(x, y) == "."


## Open air for a flyer: this cell and the eight around it are empty.
func airy(x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if not _open(x + dx, y + dy):
				return false
	return true


## Place `count` enemies evenly over the cells of `area` (in cells). `glyphs` are enemy letters,
## used in turn. Ground kinds go on standable cells, flyers (m, G) into open air. Returns how
## many were placed: fewer than asked when there is not enough room.
func spread(area: Rect2i, glyphs: Array, count: int) -> int:
	if glyphs.is_empty() or count <= 0:
		return 0
	var ground: Array = []
	var air: Array = []
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if standable(x, y):
				ground.append(Vector2i(x, y))
			if airy(x, y):
				air.append(Vector2i(x, y))
	ground.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	air.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	var placed := 0
	for i in count:
		var g: String = glyphs[i % glyphs.size()]
		var pool: Array = air if g in FLYERS else ground
		if pool.is_empty():
			continue
		# pick evenly along the left-to-right order of what is still free
		var idx := int((float(i) + 0.5) / float(count) * pool.size())
		idx = clampi(idx, 0, pool.size() - 1)
		var c: Vector2i = pool[idx]
		set_cell(c.x, c.y, g)
		pool.remove_at(idx)
		# keep a gap: drop the free cells next to the one just used so enemies are not stacked
		var keep: Array = []
		for q in pool:
			if absi(q.x - c.x) > 2 or absi(q.y - c.y) > 1:
				keep.append(q)
		# but never starve the rest: with little room left the gap is given up
		var left := count - i - 1
		var next_pool: Array = keep if keep.size() >= left else pool
		if g in FLYERS:
			air = next_pool
		else:
			ground = next_pool
		placed += 1
	return placed
