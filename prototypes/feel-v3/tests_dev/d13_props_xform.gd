# Studio S7 acceptance gate. Brackets resize decor; R turns it by 15 degrees.
# The Free toggle controls unsnapped decor placement and movement.
extends Node

const RoomDoc := preload("res://editor/room_doc.gd")
const PropsLayer := preload("res://editor/props_layer.gd")
const Builder := preload("res://editor/room_builder.gd")
const EdAssets := preload("res://editor/ed_assets.gd")
const ROOM := "theme=lab\n............\n............\n............\n............\n............\n............\n............\n"
const PNG := "props/d13_fixture.png"

var _total := 0
var _passed := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := ProjectSettings.globalize_path("res://tests_v4/logs/d13_assets")
	var old_root := EdAssets.root_override
	EdAssets.root_override = root
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.CORNFLOWER_BLUE)
	DirAccess.make_dir_recursive_absolute(root.path_join("props"))
	var fixture_ok := image.save_png(root.path_join(PNG)) == OK
	_check("picture fixture created", fixture_ok)
	if fixture_ok:
		_check_draw()
		await _check_editor()
	EdAssets.root_override = old_root
	EdAssets.clear_cache()
	var ok := _passed == _total
	print("d13_props_xform %s %d/%d" % ["PASS" if ok else "FAIL", _passed, _total])
	get_tree().quit(0 if ok else 1)


func _check_draw() -> void:
	var old := {"png": PNG, "x": 16, "y": 32, "layer": "back", "flip": true}
	var decor := {"png": PNG, "x": 37.25, "y": 51.5, "layer": "front", "rot": -45, "scale": 1.75}
	var tile := {"png": PNG, "x": 64, "y": 32, "layer": "solid", "tile": true, "rot": 45, "scale": 2}
	var doc := RoomDoc.parse("d13", ROOM, JSON.stringify([old, decor, tile]))
	var saved := RoomDoc.parse("d13", doc.to_text(), doc.props_text())
	_check("prop transforms and unsnapped coordinates round-trip", saved.props[1] == doc.props[1])
	_check("legacy fields stay optional", saved.props[0] == doc.props[0])
	var layer := PropsLayer.new()
	add_child(layer)
	layer.setup_props(saved.props)
	_check("all three props draw", layer.get_child_count() == 3)
	if layer.get_child_count() == 3:
		var before := layer.get_child(0) as Sprite2D
		var transformed := layer.get_child(1) as Sprite2D
		var solid := layer.get_child(2) as Sprite2D
		_check("old decor retains position, flip and default transform", before.position == Vector2(16, 32) and before.flip_h and not before.centered and is_zero_approx(before.rotation) and before.scale == Vector2.ONE)
		_check("front decor draws the exact free position, rotation and scale", transformed.position == Vector2(37.25, 51.5) and is_equal_approx(transformed.rotation_degrees, -45.0) and transformed.scale == Vector2(1.75, 1.75) and transformed.z_index == 8)
		_check("solid tiles ignore transform fields", solid.position == Vector2(64, 32) and is_zero_approx(solid.rotation) and solid.scale == Vector2.ONE)
	layer.queue_free()


func _check_editor() -> void:
	var doc := RoomDoc.parse("d13", ROOM)
	doc.add_prop(PNG, 16, 16, "back", false)
	doc.add_prop(PNG, 64, 16, "solid", true)
	var builder := Builder.new()
	add_child(builder)
	builder.begin({"room": "church", "doc": doc})
	await get_tree().process_frame
	_click(builder, Vector2(20, 20))
	_key(builder, KEY_R)
	_check("R turns a selected decor prop by 15 degrees", doc.props[0].get("rot", 0) == 15)
	_key(builder, KEY_Z, true)
	_check("one undo restores rotation", doc.props[0].get("rot", 0) == 0 and not doc.can_undo())
	_click(builder, Vector2(20, 20))
	_key(builder, KEY_BRACKETRIGHT)
	_check("right bracket grows the selected prop by a quarter", doc.props[0].get("scale", 1) == 1.25)
	for step in 15:
		_key(builder, KEY_BRACKETRIGHT)
	_check("scale caps at four", doc.props[0].get("scale", 1) == 4)
	for step in 18:
		_key(builder, KEY_BRACKETLEFT)
	_check("scale bottoms out at a quarter", doc.props[0].get("scale", 1) == 0.25)
	_click(builder, Vector2(68, 20))
	var before: String = doc.props_text()
	_key(builder, KEY_R)
	_check("solid selection refuses rotation and explains why", doc.props_text() == before and ("decor" in String(builder.get("_msg")).to_lower() or "tile" in String(builder.get("_msg")).to_lower()))
	_key(builder, KEY_BRACKETRIGHT)
	_check("solid selection refuses scaling", doc.props_text() == before)
	var free := _free_toggle(builder)
	_check("a visible Free toggle is available", free != null and free.is_visible_in_tree())
	if free != null:
		free.button_pressed = true
		builder.set("tab", "PROPS")
		builder.set("plane", "back")
		builder.set("sel", {"png": PNG})
		builder.call("_set_tool", "PLACE")
		_click(builder, Vector2(99, 63))
		var placed: Dictionary = doc.props[-1]
		_check("free decor placement keeps off-grid coordinates", doc.props.size() == 3 and is_equal_approx(float(placed["x"]), 91.0) and is_equal_approx(float(placed["y"]), 55.0))
		builder.set("tab", "TILES")
		builder.set("plane", "solid")
		builder.set("sel", {"png": PNG})
		_click(builder, Vector2(131, 63))
		placed = doc.props[-1]
		_check("tile placement still snaps with Free enabled", doc.props.size() == 4 and placed["x"] == 128 and placed["y"] == 48)
	builder.queue_free()
	await get_tree().process_frame


func _free_toggle(root: Node) -> BaseButton:
	for node in root.find_children("*", "BaseButton", true, false):
		if node.toggle_mode and node.get("text") != null and "free" in String(node.get("text")).to_lower():
			return node
	return null


func _click(builder: CanvasLayer, at: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = builder.call("_to_screen", at)
		builder.call("_on_view_input", event)


func _key(builder: CanvasLayer, key: Key, ctrl := false) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	event.ctrl_pressed = ctrl
	builder.call("_input", event)


func _check(label: String, condition: bool) -> void:
	_total += 1
	if condition:
		_passed += 1
	else:
		printerr("FAIL: " + label)
