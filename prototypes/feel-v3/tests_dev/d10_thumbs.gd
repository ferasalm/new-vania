# PROTOTYPE - NOT FOR PRODUCTION
# F3 room thumbnails and help, Studio piece 4.
extends Node

const EdHelp := preload("res://editor/ed_help.gd")
const RoomDoc := preload("res://editor/room_doc.gd")
const THUMB_PATH := "res://editor/ed_thumbs.gd"
const FIXTURE := "theme=lab\n.#i\nmD1\n"

var passed := 0
var failed := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var thumb_script: Script
	if ResourceLoader.exists(THUMB_PATH):
		thumb_script = load(THUMB_PATH)
	_check("room thumbnail tool is available", thumb_script != null)
	if thumb_script != null:
		_test_thumbnail(thumb_script)
	await _test_map()
	print("d10_thumbs %s %d/%d" % ["PASS" if failed == 0 else "FAIL", passed, passed + failed])
	get_tree().quit(0 if failed == 0 else 1)


func _test_thumbnail(thumbs: Script) -> void:
	var icon: Texture2D = thumbs.room(FIXTURE, 1)
	_check("one pixel for each room cell", icon != null and icon.get_size() == Vector2(3, 2))
	if icon == null:
		return
	var img := icon.get_image()
	_check("empty space has its own color", _color_is(img, 0, 0, "#202738"))
	_check("a wall has its own color", _color_is(img, 1, 0, "#8997ad"))
	_check("a trap has its own color", _color_is(img, 2, 0, "#ec925d"))
	_check("an enemy has its own color", _color_is(img, 0, 1, "#e76e86"))
	_check("a door has its own color", _color_is(img, 1, 1, "#79c9f5"))
	_check("a marker has its own color", _color_is(img, 2, 1, "#ead084"))
	var doc := RoomDoc.parse("sample", FIXTURE)
	var enlarged: Texture2D = thumbs.room(doc, 3)
	_check("a room document scales without blurring tiles",
		enlarged != null and enlarged.get_size() == Vector2(9, 6)
		and _color_is(enlarged.get_image(), 4, 1, "#8997ad") and _color_is(enlarged.get_image(), 6, 5, "#ead084"))
	_check("empty input has no thumbnail", thumbs.room("", 1) == null)


func _test_map() -> void:
	var map: CanvasLayer = load("res://editor/map_builder.gd").new()
	add_child(map)
	map.begin({"sheet": "before", "room": "library"})
	await get_tree().process_frame
	var list: ItemList = map._list
	var all_have_previews := list.item_count == 15
	var exact_library := false
	for i in list.item_count:
		var texture := list.get_item_icon(i)
		all_have_previews = all_have_previews and texture != null
		if list.get_item_metadata(i) == "library" and texture != null:
			exact_library = texture.get_size() == Vector2(48, 28)
	_check("F3 shows previews for every room on the first map", all_have_previews)
	_check("F3 shows the actual two-screen Library", exact_library)
	map.set_sheet("after")
	var all_after := list.item_count > 0
	for i in list.item_count:
		all_after = all_after and list.get_item_icon(i) != null
	_check("switching the map keeps previews", all_after)
	var missing := PackedStringArray()
	var help_buttons := 0
	for node in map.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text == "?" or button.is_queued_for_deletion():
			continue
		var i := button.get_index() + 1
		var sibling := button.get_parent().get_child(i) as Button if i < button.get_parent().get_child_count() else null
		if sibling == null or sibling.text != "?":
			missing.append(button.text)
			continue
		help_buttons += 1
		sibling.pressed.emit()
		if not EdHelp.is_open() or EdHelp.shown_text().contains("No help written yet"):
			missing.append(button.text)
		EdHelp.hide()
	_check("every F3 button has help that opens with text: " + ", ".join(missing), help_buttons >= 14 and missing.is_empty())


func _color_is(img: Image, x: int, y: int, hex: String) -> bool:
	return x < img.get_width() and y < img.get_height() and img.get_pixel(x, y).to_html() == Color(hex).to_html()


func _check(label: String, ok: bool) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("FAIL ", label)
