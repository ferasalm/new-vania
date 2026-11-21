# PROTOTYPE - NOT FOR PRODUCTION
# Selection and clipboard helper for the room builder (F2 group selection).
extends RefCounted

const TILE := 16


## Compute an inclusive bounding rectangle from two cell coordinates, clipped to room bounds.
static func box_rect(from_cell: Vector2i, to_cell: Vector2i, room_bounds: Rect2i) -> Rect2i:
	var low := from_cell.min(to_cell)
	var high := from_cell.max(to_cell)
	var raw := Rect2i(low, high - low + Vector2i.ONE)
	return raw.intersection(room_bounds)


## Does the block hold anything that a cut or delete would remove?
static func has_content(block: Dictionary) -> bool:
	if not block["props"].is_empty():
		return true
	for cell: Dictionary in block["cells"]:
		if cell["ch"] != ".":
			return true
	return false


## Does pasting the clipped block change any cells or add any picture anchors?
static func would_paste(doc: RefCounted, origin: Vector2i, block: Dictionary) -> bool:
	for cell: Dictionary in block["cells"]:
		var at := origin + Vector2i(cell["dx"], cell["dy"])
		if doc.in_room(at.x, at.y) and doc.get_cell(at.x, at.y) != cell["ch"]:
			return true
	for prop: Dictionary in block["props"]:
		var at := origin + Vector2i(floori(float(prop["x"]) / TILE), floori(float(prop["y"]) / TILE))
		if doc.in_room(at.x, at.y):
			return true
	return false


## Reject a move that would lose any glyph or picture anchor at the edge.
static func can_move(doc: RefCounted, origin: Vector2i, block: Dictionary) -> bool:
	for cell: Dictionary in block["cells"]:
		var at := origin + Vector2i(cell["dx"], cell["dy"])
		if cell["ch"] != "." and not doc.in_room(at.x, at.y):
			return false
	for prop: Dictionary in block["props"]:
		var at := origin + Vector2i(floori(float(prop["x"]) / TILE), floori(float(prop["y"]) / TILE))
		if not doc.in_room(at.x, at.y):
			return false
	return true
