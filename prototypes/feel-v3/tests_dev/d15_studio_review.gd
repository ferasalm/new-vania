# Studio review gate. Uses real input dispatch for the modal keyboard checks.
extends Node

const EdHelp := preload("res://editor/ed_help.gd")
const EdCatalog := preload("res://editor/ed_catalog.gd")
const EdAssets := preload("res://editor/ed_assets.gd")
const RoomDoc := preload("res://editor/room_doc.gd")

var _passed := 0
var _total := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _run() -> void:
	_check("Studio startup loads the Library help seed", EdHelp.has("studio.library"))
	var main = load("res://main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await main.debug_enter("church", "left", false)
	var map := Dev.show_map()
	await get_tree().process_frame
	EdHelp.show("studio.library")
	_check("help draws above F3", EdHelp.popup_layer.layer > map.layer)
	await _key(KEY_ESCAPE)
	_check("Escape dismisses help through actual input dispatch", not EdHelp.is_open())
	_check("Escape from help does not close the map", is_instance_valid(map) and Dev.tool == map)
	EdHelp.hide()
	Dev.close_tool()
	await get_tree().process_frame
	await _check_library()
	var ok := _passed == _total
	print("d15_studio_review %s %d/%d" % ["PASS" if ok else "FAIL", _passed, _total])
	get_tree().quit(0 if ok else 1)


func _check_library() -> void:
	var root := ProjectSettings.globalize_path("res://tests_v4/logs/d15_assets")
	EdAssets.root_override = root.path_join("editor")
	EdAssets.library_override = root.path_join("library")
	var picture := "environment/lamp.png"
	var file := EdAssets.library_override.path_join(picture)
	DirAccess.make_dir_recursive_absolute(file.get_base_dir())
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.GOLD)
	var png_ok := image.save_png(file) == OK
	_check("library PNG fixture is present", png_ok)
	var entry := {"id": "lamp_aabbcc", "name": "1x lamp", "source": picture, "path": picture, "category": "environment", "kind": "image", "placeable": "props"}
	var jpeg := entry.duplicate()
	jpeg["path"] = "environment/lamp.jpg"
	_check("older catalogs cannot enable Use on a JPEG", not EdCatalog.placeable_reason(jpeg).is_empty())
	var catalog := root.path_join("catalog.json")
	var output := FileAccess.open(catalog, FileAccess.WRITE)
	output.store_string(JSON.stringify({"entries": [entry]}))
	output.close()
	EdCatalog.load_file(catalog)
	_check("tab and newline split search words", EdCatalog.search("1x\t\nlamp").size() == 1)
	_check("ordinary search and empty search still work", EdCatalog.search("1x lamp").size() == 1 and EdCatalog.search("").size() == 1)
	var doc := RoomDoc.parse("d15_fixture", "theme=lab\n....\n.P..\n....\n####\n")
	var builder: CanvasLayer = load("res://editor/room_builder.gd").new()
	builder.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(builder)
	builder.begin({"room": "church", "doc": doc})
	await get_tree().process_frame
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = builder.call("_to_screen", Vector2(24, 24))
	builder.call("_on_view_input", mouse)
	builder.open_library()
	await get_tree().process_frame
	builder.library_palette.search_box.release_focus()
	await _key(KEY_DELETE)
	var kept_marker: bool = doc.get_cell(1, 1) == "P"
	_check("Delete cannot modify the obscured room", kept_marker)
	builder.close_library()
	await get_tree().process_frame
	if kept_marker:
		await _key(KEY_DELETE)
	_check("room shortcuts return when the library closes", doc.get_cell(1, 1) == ".")
	builder.call("_set_tool", "ZONE")
	var adopted: bool = builder.use_library_entry(entry)
	_check("using a PNG from Spread arms Place", adopted and builder.tool == "PLACE")
	builder.queue_free()
	await get_tree().process_frame
	EdAssets.root_override = ""
	EdAssets.library_override = ""


func _key(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await get_tree().process_frame


func _check(label: String, condition: bool) -> void:
	_total += 1
	if condition:
		_passed += 1
	else:
		printerr("FAIL: " + label)
