# PROTOTYPE - NOT FOR PRODUCTION
# The room builder's data: one room as text, with no scene attached, so it can be tested
# without running the game. The text is exactly what rooms/<name>.txt holds:
#   line 1  header  theme=lab,music=music_lab,left=lab,right=boss,...
#   rest    the grid, 16 px per character (see room.gd for what every character means)
# PNG props and tiles live next to it in rooms/<name>.props.json:
#   [{"png": "props/x.png", "x": 32, "y": 48, "flip": false, "layer": "back|solid|front", "tile": false}]
extends RefCounted

const TILE := 16
const EdAssets := preload("res://editor/ed_assets.gd")
const FLYERS := ["m", "G", "C"]
const CEILING_TRAPS := ["p", "u"]
const FLOOR_TRAPS := ["f", "i"]
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
					# JSON loads every number as a float. Keep whole pixel coordinates
					# and cell counts stable without rounding off-grid positions.
					var picture: Dictionary = p.duplicate(true)
					for axis in ["x", "y"]:
						var coordinate = picture.get(axis)
						if coordinate is float and coordinate == floorf(coordinate):
							picture[axis] = int(coordinate)
					var span = picture.get("collision_cells")
					if span is Array:
						for index in span.size():
							if span[index] is float and span[index] == floorf(span[index]):
								span[index] = int(span[index])
					d.props.append(picture)
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
	if is_tile and layer == "solid":
		var footprint := (EdAssets.size_of(png) / TILE).ceil()
		p["collision_cells"] = [int(footprint.x), int(footprint.y)]
	props.append(p)
	return p


## Overlay separately owned PNG collision on empty cells. Existing room glyphs and legacy
## baked-in collision stay intact. Move and erase only need to change the prop itself.
static func compose_rows(base: Array, pictures: Array) -> Array:
	var out := base.duplicate()
	for value in pictures:
		if not (value is Dictionary):
			continue
		var p: Dictionary = value
		var span = p.get("collision_cells", [])
		if p.get("layer") != "solid" or not p.get("tile", false) or not (span is Array) or span.size() != 2:
			continue
		var x0 := floori(float(p.get("x", 0)) / TILE)
		var y0 := floori(float(p.get("y", 0)) / TILE)
		for y in range(maxi(0, y0), mini(out.size(), y0 + int(span[1]))):
			var row: String = out[y]
			for x in range(maxi(0, x0), mini(row.length(), x0 + int(span[0]))):
				if row[x] == ".":
					row = row.substr(0, x) + "#" + row.substr(x + 1)
			out[y] = row
	return out


func effective_rows() -> Array:
	return compose_rows(rows, props)


## The topmost prop whose rectangle holds the pixel (sizes come from the caller, which knows the textures).
func prop_at(px: Vector2, size_of: Callable) -> int:
	for i in range(props.size() - 1, -1, -1):
		var p: Dictionary = props[i]
		var s: Vector2 = size_of.call(String(p["png"]))
		if Rect2(Vector2(p["x"], p["y"]), s).has_point(px):
			return i
	return -1


# ---------- region clipboard & editing ----------

## Copies cells and props whose top-left anchor lands within rect into a clipboard block.
## Returns a block Dictionary with size, cells, and deep-copied props with relative offsets.
func copy_region(rect: Rect2i) -> Dictionary:
	var block := {
		"size": rect.size,
		"cells": [],
		"props": []
	}
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if in_room(x, y):
				block["cells"].append({
					"dx": x - rect.position.x,
					"dy": y - rect.position.y,
					"ch": get_cell(x, y)
				})
	var region_px := Vector2(rect.position * TILE)
	for p in props:
		if not (p is Dictionary):
			continue
		var ax := floori(float(p.get("x", 0)) / TILE)
		var ay := floori(float(p.get("y", 0)) / TILE)
		if rect.has_point(Vector2i(ax, ay)):
			var copy: Dictionary = p.duplicate(true)
			copy["x"] = float(p.get("x", 0)) - region_px.x
			copy["y"] = float(p.get("y", 0)) - region_px.y
			block["props"].append(copy)
	return block


## Cuts cells and props within rect into a clipboard block, clearing cells to "." and removing props.
func cut_region(rect: Rect2i) -> Dictionary:
	var block := copy_region(rect)
	clear_region(rect)
	return block


## Clear cells and picture anchors in the region. The caller manages undo.
func clear_region(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if in_room(x, y):
				set_cell(x, y, ".")
	for i in range(props.size() - 1, -1, -1):
		var p = props[i]
		if p is Dictionary:
			var ax := floori(float(p.get("x", 0)) / TILE)
			var ay := floori(float(p.get("y", 0)) / TILE)
			if rect.has_point(Vector2i(ax, ay)):
				props.remove_at(i)


## Pastes a clipboard block at origin without resizing the room.
## Out-of-bounds cells and prop anchors are clipped.
## Returns true if destination clipped any cells or props outside the room.
func paste_region(origin: Vector2i, block: Dictionary) -> bool:
	if block.is_empty():
		return false
	var clipped := false
	var cells: Array = block.get("cells", [])
	for c in cells:
		var dst_x: int = origin.x + int(c.get("dx", 0))
		var dst_y: int = origin.y + int(c.get("dy", 0))
		if in_room(dst_x, dst_y):
			set_cell(dst_x, dst_y, String(c.get("ch", ".")))
		else:
			clipped = true
	var block_props: Array = block.get("props", [])
	for p in block_props:
		if not (p is Dictionary):
			continue
		var cp: Dictionary = p.duplicate(true)
		var rel_x: float = float(cp.get("x", 0))
		var rel_y: float = float(cp.get("y", 0))
		var dest_x: float = float(origin.x * TILE) + rel_x
		var dest_y: float = float(origin.y * TILE) + rel_y
		var ax := floori(dest_x / TILE)
		var ay := floori(dest_y / TILE)
		if in_room(ax, ay):
			cp["x"] = int(dest_x) if dest_x == floorf(dest_x) else dest_x
			cp["y"] = int(dest_y) if dest_y == floorf(dest_y) else dest_y
			props.append(cp)
		else:
			clipped = true
	return clipped


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


## Spread the requested enemy or hazard types across legal cells without overwriting any glyphs.
## Hanging traps need a ceiling and a floor, while spikes and flame vents start above a floor.
func spread(area: Rect2i, glyphs: Array, count: int) -> int:
	if glyphs.is_empty() or count <= 0:
		return 0
	var layout := effective_rows()
	var bounds := area.intersection(Rect2i(0, 0, width(), height()))
	var pools := {}
	for glyph in glyphs:
		if pools.has(glyph):
			continue
		var candidates: Array[Vector2i] = []
		for x in range(bounds.position.x, bounds.end.x):
			for y in range(bounds.position.y, bounds.end.y):
				if _spread_supports(layout, glyph, x, y):
					candidates.append(Vector2i(x, y))
		pools[glyph] = candidates
	var placed := 0
	var occupied: Array[Vector2i] = []
	for i in count:
		var glyph: String = glyphs[i % glyphs.size()]
		var available: Array = pools[glyph].filter(func(c: Vector2i) -> bool:
			return get_cell(c.x, c.y) == "." and _spread_available(glyph, c))
		if available.is_empty():
			continue
		var spaced := available.filter(func(c: Vector2i) -> bool:
			return not occupied.any(func(o: Vector2i) -> bool:
				return absi(c.x - o.x) <= 2 and absi(c.y - o.y) <= 1))
		var choices := spaced if not spaced.is_empty() else available
		var wanted_x := bounds.position.x + (float(i) + 0.5) * bounds.size.x / count
		var best: Vector2i = choices[0]
		for c: Vector2i in choices:
			if absf(c.x - wanted_x) < absf(best.x - wanted_x):
				best = c
		if placed == 0:
			push_undo()
		if set_cell(best.x, best.y, glyph):
			occupied.append(best)
			placed += 1
	return placed


func _spread_available(glyph: String, c: Vector2i) -> bool:
	if glyph == "i":
		return get_cell(c.x - 1, c.y) != "i" and get_cell(c.x + 1, c.y) != "i"
	if glyph in FLYERS:
		return airy(c.x, c.y)
	return true


func _spread_supports(layout: Array, glyph: String, x: int, y: int) -> bool:
	if _layout_cell(layout, x, y) != ".":
		return false
	if glyph in CEILING_TRAPS:
		if _layout_cell(layout, x, y - 1) != "#":
			return false
		for floor_y in range(y + 1, layout.size()):
			if _layout_cell(layout, x, floor_y) in ["#", "="]:
				return floor_y - y >= 3
		return false
	if glyph in FLYERS:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if _layout_cell(layout, x + dx, y + dy) != ".":
					return false
		return true
	if not (_layout_cell(layout, x, y + 1) in ["#", "="]):
		return false
	if glyph in FLOOR_TRAPS:
		return true
	return _layout_cell(layout, x, y - 1) == "." and _layout_cell(layout, x, y - 2) == "."


static func _layout_cell(layout: Array, x: int, y: int) -> String:
	if y < 0 or y >= layout.size() or x < 0 or x >= String(layout[y]).length():
		return ""
	return String(layout[y])[x]
