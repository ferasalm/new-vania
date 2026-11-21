# Studio S6 acceptance gate. Clipboard positions are relative to the selected cell
# rectangle. A prop belongs to the rectangle containing its top-left anchor.
extends Node

const RoomDoc := preload("res://editor/room_doc.gd")
const Builder := preload("res://editor/room_builder.gd")
const ROOM := "theme=lab\n..........\n.#m.......\n.Pf.......\n..........\n..........\n..........\n..........\n"
const SOURCE := Vector2i(1, 1)
const DEST := Vector2i(5, 4)
const REGION := Rect2i(SOURCE, Vector2i(2, 2))
const TILE := 16

var _passed := 0
var _total := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_document()
	await _check_move()
	await _check_clipboard()
	var ok := _passed == _total
	print("d12_selection %s %d/%d" % ["PASS" if ok else "FAIL", _passed, _total])
	get_tree().quit(0 if ok else 1)


func _check(label: String, condition: bool) -> void:
	_total += 1
	if condition:
		_passed += 1
	else:
		printerr("FAIL: " + label)


func _fixture() -> RefCounted:
	var doc := RoomDoc.parse("d12_fixture", ROOM)
	doc.add_prop("props/sample.png", 24, 20, "back", false, true)
	doc.add_prop("tiles/sample.png", 32, 32, "solid", true)
	doc.props[1]["collision_cells"] = [2, 1]
	return doc


func _check_document() -> void:
	var doc := _fixture()
	var present := doc.has_method("cut_region") and doc.has_method("paste_region")
	_check("room document exposes cut and paste", present)
	if not present:
		return
	var pictures: String = doc.props_text()
	var block: Dictionary = doc.cut_region(REGION)
	_check("cut clears all selected cells and images", _blank(doc, SOURCE) and doc.props.is_empty())
	doc.paste_region(DEST, block)
	_check("paste preserves the four different glyphs", _matches(doc, DEST))
	_check("paste preserves decor offset, flip and solid footprint", _pictures_at(doc, DEST))
	var copy := RoomDoc.parse("d12_fixture", doc.to_text(), doc.props_text())
	_check("a saved selection round-trips", copy.to_text() == doc.to_text() and copy.props_text() == doc.props_text())
	var edge := Vector2i(9, 6)
	doc.paste_region(edge, block)
	_check("edge clips to valid cells without resizing", doc.get_cell(9, 6) == "#" and doc.width() == 10 and doc.height() == 7)
	_check("edge keeps only the in-bounds prop anchor", doc.props.size() == 3 and doc.props[-1]["x"] == 152 and doc.props[-1]["y"] == 100)
	var restored := _fixture()
	restored.cut_region(REGION)
	restored.paste_region(SOURCE, block)
	_check("repeated paste leaves the clipboard intact", restored.props_text() == pictures)


func _open_builder(doc: RefCounted) -> CanvasLayer:
	var builder := Builder.new()
	add_child(builder)
	builder.begin({"room": "church", "doc": doc})
	return builder


func _check_move() -> void:
	var doc := _fixture()
	var original: String = doc.props_text()
	var builder := _open_builder(doc)
	await get_tree().process_frame
	_select(builder, SOURCE + Vector2i.ONE, SOURCE)
	_check("reverse box drag only selects", doc.to_text() == ROOM and not doc.can_undo())
	_mouse_button(builder, SOURCE, true)
	_motion(builder, DEST)
	_mouse_button(builder, DEST, false)
	_check("drag moves terrain, enemy, marker and trap", _blank(doc, SOURCE) and _matches(doc, DEST))
	_check("drag moves both image layers", _pictures_at(doc, DEST))
	_key(builder, KEY_Z, true)
	_check("one undo restores everything from drag", doc.to_text() == ROOM and doc.props_text() == original and not doc.can_undo())
	_key(builder, KEY_Y, true)
	_check("redo reapplies the move", _matches(doc, DEST) and _pictures_at(doc, DEST))
	builder.queue_free()
	await get_tree().process_frame


func _check_clipboard() -> void:
	var doc := _fixture()
	var builder := _open_builder(doc)
	await get_tree().process_frame
	_select(builder, SOURCE, SOURCE + Vector2i.ONE)
	_key(builder, KEY_C, true)
	_check("copy leaves the room and undo history alone", doc.to_text() == ROOM and not doc.can_undo())
	_motion(builder, DEST)
	_key(builder, KEY_V, true)
	_check("paste adds a second block and both images", _matches(doc, SOURCE) and _matches(doc, DEST) and doc.props.size() == 4)
	_key(builder, KEY_Z, true)
	_check("one undo removes the whole paste", doc.to_text() == ROOM and doc.props.size() == 2 and not doc.can_undo())
	_select(builder, SOURCE, SOURCE + Vector2i.ONE)
	_key(builder, KEY_RIGHT)
	_check("right arrow nudges by one cell", _matches(doc, SOURCE + Vector2i.RIGHT) and doc.get_cell(1, 1) == "." and _pictures_at(doc, SOURCE + Vector2i.RIGHT))
	_key(builder, KEY_Z, true)
	_check("nudge is one undo step", doc.to_text() == ROOM and _pictures_at(doc, SOURCE) and not doc.can_undo())
	_select(builder, SOURCE, SOURCE + Vector2i.ONE)
	_key(builder, KEY_X, true)
	_check("cut clears the whole selection", _blank(doc, SOURCE) and doc.props.is_empty())
	_key(builder, KEY_Z, true)
	_check("cut is one undo step", doc.to_text() == ROOM and _pictures_at(doc, SOURCE) and not doc.can_undo())
	_motion(builder, Vector2i(9, 6))
	_key(builder, KEY_V, true)
	_check("cut also copies, and paste reports clipping", doc.get_cell(9, 6) == "#" and "clip" in String(builder.get("_msg")).to_lower())
	_key(builder, KEY_Z, true)
	_select(builder, SOURCE, SOURCE + Vector2i.ONE)
	_motion(builder, DEST)
	_key(builder, KEY_D, true)
	_check("duplicate leaves source, creates another block", _matches(doc, SOURCE) and _matches(doc, DEST) and doc.props.size() == 4)
	_key(builder, KEY_Z, true)
	_check("duplicate is one undo step", doc.to_text() == ROOM and _pictures_at(doc, SOURCE) and not doc.can_undo())
	_select(builder, SOURCE, SOURCE + Vector2i.ONE)
	_key(builder, KEY_DELETE)
	_check("delete clears the whole selection", _blank(doc, SOURCE) and doc.props.is_empty())
	_key(builder, KEY_Z, true)
	_check("delete is one undo step", doc.to_text() == ROOM and _pictures_at(doc, SOURCE) and not doc.can_undo())
	builder.queue_free()
	await get_tree().process_frame


func _matches(doc: RefCounted, at: Vector2i) -> bool:
	return doc.get_cell(at.x, at.y) == "#" and doc.get_cell(at.x + 1, at.y) == "m" and doc.get_cell(at.x, at.y + 1) == "P" and doc.get_cell(at.x + 1, at.y + 1) == "f"


func _blank(doc: RefCounted, at: Vector2i) -> bool:
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE]:
		var cell: Vector2i = at + offset
		if doc.get_cell(cell.x, cell.y) != ".":
			return false
	return true


func _pictures_at(doc: RefCounted, at: Vector2i) -> bool:
	if doc.props.size() != 2:
		return false
	var decor: Dictionary = doc.props[0]
	var solid: Dictionary = doc.props[1]
	return (
		decor.get("x") == at.x * TILE + 8 and decor.get("y") == at.y * TILE + 4
		and decor.get("flip") == true and decor.get("layer") == "back"
		and solid.get("x") == (at.x + 1) * TILE and solid.get("y") == (at.y + 1) * TILE
		and solid.get("collision_cells") == [2, 1] and solid.get("layer") == "solid"
	)


func _select(builder: CanvasLayer, from: Vector2i, to: Vector2i) -> void:
	_mouse_button(builder, from, true, true)
	_motion(builder, to)
	_mouse_button(builder, to, false, true)


func _mouse_button(builder: CanvasLayer, cell: Vector2i, down: bool, shift := false) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.shift_pressed = shift
	event.position = builder.call("_to_screen", Vector2(cell * TILE) + Vector2(8, 8))
	builder.call("_on_view_input", event)


func _motion(builder: CanvasLayer, cell: Vector2i) -> void:
	var event := InputEventMouseMotion.new()
	event.position = builder.call("_to_screen", Vector2(cell * TILE) + Vector2(8, 8))
	builder.call("_on_view_input", event)


func _key(builder: CanvasLayer, key: Key, ctrl := false) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	event.ctrl_pressed = ctrl
	builder.call("_input", event)
