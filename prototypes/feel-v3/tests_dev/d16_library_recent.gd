extends Node

const Catalog := preload("res://editor/ed_catalog.gd")
const Assets := preload("res://editor/ed_assets.gd")
const RoomDoc := preload("res://editor/room_doc.gd")

var _checks := 0
var _passed := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var path := ProjectSettings.globalize_path("user://d16_library")
	Assets.root_override = path.path_join("editor")
	Assets.library_override = path.path_join("library")
	DirAccess.make_dir_recursive_absolute(Assets.library_override)
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.AQUA)
	var entries: Array = []
	for filename: String in ["Zeta", "alpha", "beta"]:
		var picture := filename + ".png"
		_check("create picture " + filename, image.save_png(Assets.library_override.path_join(picture)) == OK)
		entries.append({"id": filename, "name": filename, "source": picture, "path": picture,
			"category": "environment", "kind": "image", "placeable": "props"})
	var file := FileAccess.open(path.path_join("catalog.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"entries": entries}))
	file.close()
	_check("fixture loads", Catalog.load_file(path.path_join("catalog.json")) == 3)
	var room = load("res://editor/room_builder.gd").new()
	add_child(room)
	room.begin({"room": "church", "doc": RoomDoc.parse("church", "theme=lab\n....\n.P..\n....\n####\n")})
	room.open_library()
	var palette = room.library_palette
	var recent: CheckButton = palette.get("recent_button") if "recent_button" in palette else null
	_check("Recent has its own visible control", recent != null and recent.is_visible_in_tree())
	if recent != null:
		recent.button_pressed = true
	else:
		palette.set_category("Recent")
	_check("Recent starts empty", palette.result_count() == 0)
	palette.set_category("")
	_check("All is alphabetical ignoring case", _ids(palette) == ["alpha", "beta", "Zeta"])
	for key: String in ["Zeta", "alpha", "Zeta"]:
		var row: int = _ids(palette).find(key)
		palette.pick(row)
		_check("placeable picture can be used: " + key, palette.use_selected())
		await get_tree().process_frame
		room.open_library()
		palette = room.library_palette
	palette.set_category("Recent")
	_check("Recent keeps latest first with no duplicates", _ids(palette) == ["Zeta", "alpha"])
	palette.search_text("alpha")
	_check("Search filters the recent list", _ids(palette) == ["alpha"])
	palette.set_category("")
	palette.search_text("")
	_check("All still shows unused entries", _ids(palette) == ["alpha", "beta", "Zeta"])
	print("d16_library_recent %s %d/%d" % ["PASS" if _checks == _passed else "FAIL", _passed, _checks])
	get_tree().quit(0 if _checks == _passed else 1)


func _ids(palette: Control) -> Array[String]:
	var result: Array[String] = []
	for i in palette.result_count():
		result.append(str(palette.result_entry(i).get("id", "")))
	return result


func _check(label: String, ok: bool) -> void:
	_checks += 1
	if ok:
		_passed += 1
	else:
		printerr("FAIL: " + label)
