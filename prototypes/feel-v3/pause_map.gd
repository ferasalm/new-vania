# PROTOTYPE - NOT FOR PRODUCTION
extends Control

signal room_selected(id: String)

var _rooms: Dictionary = {}
var _layout: Dictionary = {}
var _current := ""
var _selected := ""


## Refresh the visible rooms using the current world sheet.
func show_rooms(ids: Array, current: String) -> void:
	_current = current
	_rooms.clear()
	var bounds := Rect2i()
	for id in ids:
		var cell: Array = W.meta(String(id)).get("cell", [])
		if cell.size() != 4 or int(cell[2]) < 1 or int(cell[3]) < 1:
			continue
		var rect := Rect2i(int(cell[0]), int(cell[1]), int(cell[2]), int(cell[3]))
		bounds = rect if _rooms.is_empty() else bounds.merge(rect)
		_rooms[id] = rect
	_layout.clear()
	if not _rooms.is_empty():
		var unit := minf(18.0, minf((size.x - 12.0) / bounds.size.x,
			(size.y - 12.0) / bounds.size.y))
		var origin := (size - Vector2(bounds.size) * unit) * 0.5
		for id in _rooms:
			var cell: Rect2i = _rooms[id]
			var area := Vector2(cell.size) * unit
			_layout[id] = Rect2(origin + Vector2(cell.position - bounds.position) * unit,
				(area - Vector2.ONE).max(Vector2.ONE))
	queue_redraw()


## Highlight the room selected in the pause menu.
func select_room(id: String) -> void:
	_selected = id
	queue_redraw()


## Return the selected sheet's metadata rectangle for a visible room.
func cell_rect(id: String) -> Rect2i:
	return _rooms.get(id, Rect2i())


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#111827"))
	for id in _layout:
		if id != _selected:
			_draw_room(id)
	if _layout.has(_selected):
		_draw_room(_selected)
	if _layout.has(_current):
		var rect: Rect2 = _layout[_current]
		draw_circle(rect.get_center(), minf(2.0, rect.size.y / 3.0), Color("#f6ce82"))


func _draw_room(id: String) -> void:
	var rect: Rect2 = _layout[id]
	draw_rect(rect, Color("#266456") if id == _selected else Color("#334467"))
	draw_rect(rect, Color("#90f1c8") if id == _selected else Color("#657d9b"), false)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT or not click.pressed:
		return
	var hits: Array[String] = []
	for id in _layout:
		if (_layout[id] as Rect2).has_point(click.position):
			hits.append(id)
	if not hits.is_empty():
		room_selected.emit(hits[(hits.find(_selected) + 1) % hits.size()])
		accept_event()
