extends Node

const Catalog := preload("res://editor/ed_catalog.gd")
const Assets := preload("res://editor/ed_assets.gd")
const Palette := preload("res://editor/ed_palette.gd")

var _failed := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := ProjectSettings.globalize_path("user://d17_library")
	Assets.library_override = root
	DirAccess.make_dir_recursive_absolute(root)
	var image := Image.create(96, 36, false, Image.FORMAT_RGBA8)
	image.fill(Color.SEA_GREEN)
	_check(image.save_png(root.path_join("tank.png")) == OK, "fixture image")
	_write(root.path_join("notes.txt"), "Uses the original color key.")
	_make_wav(root.path_join("chime.wav"))
	var catalog_file := root.path_join("catalog.json")
	var entries := [
		{"id":"tank", "name":"Empty Tank", "category":"original art", "kind":"image", "type":"sprite",
			"room":"Save Room", "area":"Demon Court", "path":"tank.png", "placeable":"props",
			"derived_from":"Original assets/Tank source.jpg"},
		{"id":"desk", "name":"Empty Desk", "category":"reference packs", "kind":"source", "type":"document",
			"room":"Save Room", "area":"Arnetria", "path":"notes.txt"},
		{"id":"sound", "name":"Save Chime", "category":"reference packs", "kind":"audio", "type":"audio",
			"room":"Save Room", "area":"Demon Court", "path":"chime.wav"},
		{"id":"bench", "name":"Save Bench", "category":"original art", "kind":"image", "type":"sprite",
			"room":"Save Room", "area":"Arnetria", "path":"tank.png"},
		{"id":"extra", "name":"Other Sprite", "category":"original art", "kind":"image", "type":"sprite",
			"room":"Kennel", "area":"Demon Court", "path":"tank.png"},
	]
	_write(catalog_file, JSON.stringify({"entries":entries}))
	_check(Catalog.load_file(catalog_file) == 5, "fixture catalog")
	var palette := Palette.new()
	add_child(palette)
	_check(palette.result_count() == 5, "all entries listed")
	var area := palette.get("area_box") as OptionButton
	var room := palette.get("room_box") as OptionButton
	var type := palette.get("type_box") as OptionButton
	if area == null or room == null or type == null:
		_check(false, "area, room and type filters exist")
		get_tree().quit(1)
		return
	_select(area, "Demon Court")
	_select(room, "Save Room")
	_select(type, "sprite")
	_check(palette.result_count() == 1 and palette.result_entry(0).get("id") == "tank", "filters combine before text search")
	palette.search_text("tank source")
	_check(palette.result_count() == 1 and palette.result_entry(0).get("id") == "tank", "filters combine and search provenance")
	palette.pick(0)
	var preview := palette.get("preview_image") as TextureRect
	_check(preview != null and preview.texture != null and preview.texture.get_width() == 96, "selected art displays a large real preview")
	_check(not palette.use_button.disabled, "sprite placement enabled")
	_check(palette.info_text().contains("Original assets/Tank source.jpg"), "provenance visible")
	_select(area, "")
	_select(room, "")
	_select(type, "document")
	palette.search_text("")
	palette.pick(0)
	_check(palette.result_count() == 1 and palette.result_icon(0) != null, "document has a thumbnail")
	_check(palette.info_text().contains("Uses the original color key."), "document textual preview")
	var inspect := palette.get("inspect_button") as Button
	_check(inspect != null and not inspect.disabled, "document can reveal its file")
	_select(type, "audio")
	palette.pick(0)
	var audio := palette.get("audio_button") as Button
	var player := palette.get("audio_preview") as AudioStreamPlayer
	_check(palette.result_count() == 1 and palette.result_icon(0) != null, "audio has a thumbnail")
	_check(audio != null and not audio.disabled, "audio play control enabled")
	if audio != null:
		audio.pressed.emit()
	_check(player != null and player.playing and player.stream != null, "audio plays")
	_select(type, "sprite")
	_check(player != null and not player.playing, "leaving a result stops audio")
	for i in 301:
		entries.append({"id":"page-%03d" % i, "name":"Paged %03d" % i, "kind":"source", "type":"document", "path":"notes.txt"})
	_write(catalog_file, JSON.stringify({"entries":entries}))
	_check(Catalog.load_file(catalog_file) == 306, "large catalog fixture")
	var browser := Palette.new()
	add_child(browser)
	browser.search_text("paged")
	var next := browser.get("next_button") as Button
	_check(next != null and not next.disabled, "next page available past 300 results")
	if next != null:
		next.pressed.emit()
	_check(browser.result_count() == 1 and browser.result_entry(0).get("id") == "page-300", "last asset reachable by paging")
	browser.free()
	palette.free()
	Catalog.clear()
	print("d17_reference_library failures=", _failed)
	get_tree().quit(0 if _failed == 0 else 1)


func _select(box: OptionButton, value: String) -> void:
	for index in box.item_count:
		if str(box.get_item_metadata(index)) == value:
			box.select(index)
			box.item_selected.emit(index)
			return
	_check(false, "missing filter value " + value)


func _write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()


func _make_wav(path: String) -> void:
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = 8000
	var data := PackedByteArray()
	data.resize(8000)
	for i in data.size():
		data[i] = 16 if i % 40 < 20 else 240
	audio.data = data
	_check(audio.save_to_wav(path.trim_suffix(".wav")) == OK, "fixture waveform")


func _check(ok: bool, label: String) -> void:
	if not ok:
		_failed += 1
		printerr("FAIL: ", label)
