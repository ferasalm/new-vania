# PROTOTYPE - NOT FOR PRODUCTION
# editor/ed_palette.gd - the searchable asset-library palette (search, categories, thumbnails).
# It only lists the catalog and registers help; the room builder copies a chosen picture with EdAssets.adopt.
extends Control

## Emitted when a row is picked; the dictionary is the catalog entry.
signal entry_picked(entry: Dictionary)
## Emitted when a placeable picture is used (button, double click or use_selected()).
signal entry_used(entry: Dictionary)

const EdCatalog := preload("res://editor/ed_catalog.gd")
const EdAssets := preload("res://editor/ed_assets.gd")
const EdHelp := preload("res://editor/ed_help.gd")
const Preview := preload("res://editor/ed_asset_preview.gd")
const RECENT_LIMIT := 12
const RECENT_CATEGORY := "Recent"

static var _recent_ids: Array[String] = []
const Shell := preload("res://editor/workspace_shell.gd")

## The number of results per page.
const MAX_RESULTS := 300
## The largest thumbnail side, in pixels.
const THUMB := 48

## Pictures actually read from disk since the last clear_thumbs().
static var thumb_loads: int = 0
## Thumbnail cache keyed by entry id (a null value means "no thumbnail").
static var _thumbs: Dictionary = {}

var search_box: LineEdit
var category_box: OptionButton
var room_box: OptionButton
var area_box: OptionButton
var type_box: OptionButton
var preview_image: TextureRect
var inspect_button: Button
var audio_button: Button
var next_button: Button
var _previous_button: Button
var audio_preview: AudioStreamPlayer
var recent_button: CheckButton
var help_button: Button
var use_button: Button

var _list: ItemList
var _info: Label
var _page_label: Label
var _page := 0
var _results: Array = []
var _query := ""
var _category := ""
var _selected_id := ""
var _truncated := false
var _cat_sig := "?"
var _facets := {"room": "", "area": "", "type": ""}
var _asset_path := ""


## Build the palette children and show the whole catalog.
func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	search_box = LineEdit.new()
	EdHelp.attach(search_box, "library.search")
	search_box.placeholder_text = "Search pictures, sounds, tags"
	search_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_box.text_changed.connect(_on_search_changed)
	top.add_child(search_box)
	category_box = OptionButton.new()
	EdHelp.attach(category_box, "library.categories", _show_category_help)
	category_box.item_selected.connect(_on_category_selected)
	top.add_child(category_box)
	recent_button = CheckButton.new()
	recent_button.text = RECENT_CATEGORY
	EdHelp.attach(recent_button, "library.recent")
	recent_button.toggled.connect(func(on: bool): set_category(RECENT_CATEGORY if on else ""))
	top.add_child(recent_button)

	var filters := HBoxContainer.new()
	root.add_child(filters)
	area_box = _add_facet(filters, "area", "Area")
	room_box = _add_facet(filters, "room", "Room")
	type_box = _add_facet(filters, "type", "Type")

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	_list = ItemList.new()
	EdHelp.attach(_list, "library.results")
	_list.select_mode = ItemList.SELECT_SINGLE
	_list.fixed_icon_size = Vector2i(THUMB, THUMB)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_item_selected)
	_list.item_activated.connect(_on_item_activated)
	body.add_child(_list)
	var details := VBoxContainer.new()
	details.custom_minimum_size.x = 320
	body.add_child(details)
	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size.y = 178
	details.add_child(preview_panel)
	preview_image = TextureRect.new()
	preview_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview_panel.add_child(preview_image)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details.add_child(scroll)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info.add_theme_color_override("font_color", Shell.INK)
	scroll.add_child(_info)

	var navigation := HBoxContainer.new()
	root.add_child(navigation)
	_page_label = Label.new()
	_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(_page_label)
	_previous_button = Button.new()
	_previous_button.text = "Previous"
	_previous_button.pressed.connect(_change_page.bind(-1))
	navigation.add_child(_previous_button)
	next_button = Button.new()
	next_button.text = "Next"
	next_button.pressed.connect(_change_page.bind(1))
	navigation.add_child(next_button)

	var bottom := HBoxContainer.new()
	root.add_child(bottom)
	help_button = Button.new()
	EdHelp.attach(help_button, "library.asset_help")
	help_button.text = "?"
	help_button.tooltip_text = "Help for this asset"
	help_button.custom_minimum_size = Vector2(28, 0)
	help_button.pressed.connect(_on_help)
	bottom.add_child(help_button)
	use_button = Button.new()
	EdHelp.attach(use_button, "library.use")
	use_button.text = "Use this picture"
	use_button.tooltip_text = "Copy it into the builder and place it"
	use_button.disabled = true
	use_button.pressed.connect(use_selected)
	bottom.add_child(use_button)
	inspect_button = Button.new()
	inspect_button.text = "Show file"
	inspect_button.pressed.connect(_show_file)
	bottom.add_child(inspect_button)
	audio_button = Button.new()
	audio_button.text = "Play sound"
	audio_button.pressed.connect(_toggle_audio)
	bottom.add_child(audio_button)
	audio_preview = AudioStreamPlayer.new()
	audio_preview.volume_db = -12.0
	audio_preview.finished.connect(_stop_audio)
	add_child(audio_preview)

	refresh()


## Filter by this text and show it in the search box.
func search_text(text: String) -> void:
	_query = text
	_page = 0
	if search_box.text != text:
		search_box.text = text
	refresh()


## Filter to one category id, Recent, or "" for all, and show it in the category box.
func set_category(id: String) -> void:
	_category = id
	_page = 0
	_select_category_item()
	refresh()


## Rebuild the category box and the result list from the catalog.
func refresh() -> void:
	_refresh_categories()
	var found := EdCatalog.search_ids(_query, _recent_ids, _facets) if _category == RECENT_CATEGORY else EdCatalog.search(_query, _category, 0, _facets)
	var count := found.size()
	var last_page := maxi(0, ceili(float(count) / MAX_RESULTS) - 1)
	_page = clampi(_page, 0, last_page)
	var first := _page * MAX_RESULTS
	var last := mini(first + MAX_RESULTS, count)
	_results = found.slice(first, last)
	_truncated = last_page > 0
	_previous_button.disabled = _page == 0
	next_button.disabled = _page == last_page
	_page_label.text = "No matches" if count == 0 else "%d–%d of %d assets" % [first + 1, last, count]
	_list.clear()
	for entry: Dictionary in _results:
		var sub := String(entry.get("sub", ""))
		_list.add_item(String(entry.get("name", "")) + ("   [%s]" % sub if sub != "" else ""), _thumb_for(entry))
	_selected_id = ""
	use_button.disabled = true
	_show_preview({})
	if EdCatalog.entry_count() == 0:
		_info.text = "The library is empty. Run: node tools/asset_library.mjs --studio"
	elif _category == RECENT_CATEGORY and _recent_ids.is_empty():
		_info.text = "Pictures you use from the library will appear here."
	else:
		_info.text = "Pick an entry to see it here."


## How many rows the current search shows.
func result_count() -> int:
	return _results.size()


## The catalog entry shown in row i, or an empty dictionary.
func result_entry(i: int) -> Dictionary:
	if i < 0 or i >= _results.size():
		return {}
	return _results[i]


## True when the search spans more than one page.
func truncated() -> bool:
	return _truncated


## Select row i, fill the info pane and register its help text.
func pick(i: int) -> void:
	if i < 0 or i >= _results.size():
		return
	var entry: Dictionary = _results[i]
	_selected_id = String(entry.get("id", ""))
	if i < _list.item_count:
		_list.select(i)
	_show_preview(entry)
	_info.text = _info_for(entry)
	_register_help(entry)
	use_button.disabled = not EdCatalog.placeable_reason(entry).is_empty()
	entry_picked.emit(entry)


## The id of the picked entry, or "" when nothing is picked.
func selected_id() -> String:
	return _selected_id


## The help key of the picked entry ("asset:<id>"), or "" when nothing is picked.
func help_key() -> String:
	if _selected_id.is_empty():
		return ""
	return "asset:" + _selected_id


## The plain text in the info pane.
func info_text() -> String:
	return _info.text if _info != null else ""


## Emit entry_used for a placeable picked entry; return false and emit nothing otherwise.
func use_selected() -> bool:
	if _selected_id.is_empty():
		return false
	var entry := EdCatalog.entry(_selected_id)
	if entry.is_empty() or not EdCatalog.placeable_reason(entry).is_empty():
		return false
	entry_used.emit(entry)
	return true


## Remember a picture after it was copied into the room builder.
static func record_recent(id: String) -> void:
	if id.is_empty():
		return
	_recent_ids.erase(id)
	_recent_ids.push_front(id)
	if _recent_ids.size() > RECENT_LIMIT:
		_recent_ids.pop_back()


## The thumbnail for row i, or null for non-pictures and pictures missing from the library.
func result_icon(i: int) -> Texture2D:
	if i < 0 or i >= _results.size():
		return null
	return _thumb_for(_results[i])


## Forget every cached thumbnail and reset the disk-read counter.
static func clear_thumbs() -> void:
	_thumbs.clear()
	thumb_loads = 0


## The thumbnail for an entry, read from the library once and cached by id.
static func _thumb_for(entry: Dictionary) -> Texture2D:
	var id := String(entry.get("id", ""))
	if id.is_empty():
		return null
	if _thumbs.has(id):
		return _thumbs[id]
	var tex := Preview.badge(entry)
	var img := Preview.picture(entry)
	if img != null and not img.is_empty():
		thumb_loads += 1
		if img.get_width() > THUMB or img.get_height() > THUMB:
			var scale := minf(float(THUMB) / float(img.get_width()), float(THUMB) / float(img.get_height()))
			img.resize(maxi(1, roundi(img.get_width() * scale)), maxi(1, roundi(img.get_height() * scale)), Image.INTERPOLATE_BILINEAR)
		tex = ImageTexture.create_from_image(img)
	_thumbs[id] = tex
	return tex


## Add a dropdown whose values can be combined with search and category.
func _add_facet(parent: Control, key: String, title: String) -> OptionButton:
	var box := OptionButton.new()
	box.custom_minimum_size.x = 128
	box.fit_to_longest_item = false
	box.add_item(title + ": All")
	box.set_item_metadata(0, "")
	for value: String in EdCatalog.facet_values(key):
		box.add_item(value.capitalize() if key == "type" else value)
		box.set_item_metadata(box.item_count - 1, value)
	box.item_selected.connect(func(index: int) -> void:
		_facets[key] = String(box.get_item_metadata(index))
		_page = 0
		refresh())
	parent.add_child(box)
	return box


func _change_page(delta: int) -> void:
	_page += delta
	refresh()


func _show_preview(entry: Dictionary) -> void:
	_stop_audio()
	_asset_path = Preview.file_path(entry)
	inspect_button.disabled = _asset_path.is_empty()
	audio_button.visible = String(entry.get("kind", "")) == "audio"
	audio_button.disabled = _asset_path.is_empty()
	preview_image.texture = Preview.badge(entry)
	var picture := Preview.picture(entry)
	if picture == null or picture.is_empty():
		return
	var size := picture.get_size()
	if maxi(size.x, size.y) > 640:
		var scale := 640.0 / float(maxi(size.x, size.y))
		picture.resize(maxi(1, roundi(size.x * scale)), maxi(1, roundi(size.y * scale)), Image.INTERPOLATE_BILINEAR)
	preview_image.texture = ImageTexture.create_from_image(picture)


func _show_file() -> void:
	if not _asset_path.is_empty():
		OS.shell_show_in_file_manager(_asset_path)


func _toggle_audio() -> void:
	if audio_preview.playing:
		_stop_audio()
		return
	var stream := Preview.audio(_asset_path)
	if stream == null:
		audio_button.text = "Sound unavailable"
		return
	audio_preview.stream = stream
	audio_preview.play()
	audio_button.text = "Stop sound"


func _stop_audio() -> void:
	audio_preview.stop()
	audio_preview.stream = null
	audio_button.text = "Play sound"


## Fill the category box with "All" and one counted item per category id.
func _refresh_categories() -> void:
	var cats := EdCatalog.categories()
	var sig := ""
	for c: Dictionary in cats:
		sig += "%s:%d|" % [String(c["id"]), int(c["count"])]
	if sig == _cat_sig and category_box.item_count > 0:
		_select_category_item()
		return
	_cat_sig = sig
	category_box.clear()
	category_box.add_item("All")
	category_box.set_item_metadata(0, "")
	for c: Dictionary in cats:
		var index := category_box.item_count
		category_box.add_item("%s (%d)" % [String(c["id"]), int(c["count"])])
		category_box.set_item_metadata(index, String(c["id"]))
	if not _category.is_empty() and _category != RECENT_CATEGORY:
		var known := false
		for c: Dictionary in cats:
			if String(c["id"]) == _category:
				known = true
				break
		if not known:
			_category = ""
	_select_category_item()


## Show the current category in the category box without emitting item_selected.
func _select_category_item() -> void:
	recent_button.set_pressed_no_signal(_category == RECENT_CATEGORY)
	for i in category_box.item_count:
		var value: Variant = category_box.get_item_metadata(i)
		if String(value) == _category:
			category_box.select(i)
			return
	category_box.select(0)


## One plain-text block describing an entry.
func _info_for(entry: Dictionary) -> String:
	var lines: PackedStringArray = []
	var name := String(entry.get("name", ""))
	lines.append(name)
	var category := String(entry.get("category", ""))
	var sub := String(entry.get("sub", ""))
	lines.append("Category: %s" % category if sub.is_empty() else "Category: %s / %s" % [category, sub])
	if String(entry.get("kind", "")) == "image":
		var w := int(entry.get("w", 0))
		var h := int(entry.get("h", 0))
		if w > 0 and h > 0:
			lines.append("Size: %dx%d" % [w, h])
	for key: String in ["area", "room", "type"]:
		var value := String(entry.get(key, ""))
		if not value.is_empty():
			lines.append("%s: %s" % [key.capitalize(), value.capitalize() if key == "type" else value])
	var original := String(entry.get("derived_from", ""))
	if not original.is_empty():
		lines.append("Made from: " + original)
	var path := String(entry.get("path", ""))
	if not path.is_empty():
		lines.append("Library: " + path)
	var source := String(entry.get("source", ""))
	if not source.is_empty():
		lines.append("Source: " + source)
	var excerpt := Preview.excerpt(_asset_path)
	if not excerpt.is_empty():
		lines.append("\n" + excerpt)
	var reason := EdCatalog.placeable_reason(entry)
	if reason.is_empty():
		lines.append("Can be placed as %s" % String(entry.get("placeable", "")))
	else:
		lines.append(reason)
	return "\n".join(lines)


## Write a help entry for this asset into EdHelp's static table.
func _register_help(entry: Dictionary) -> void:
	var id := String(entry.get("id", ""))
	if id.is_empty():
		return
	var name := String(entry.get("name", ""))
	var size := ""
	if String(entry.get("kind", "")) == "image":
		var w := int(entry.get("w", 0))
		var h := int(entry.get("h", 0))
		if w > 0 and h > 0:
			size = ", %dx%d" % [w, h]
	var data := {
		"title": name,
		"what": "%s from %s%s." % [name, String(entry.get("category", "")), size],
	}
	var reason := EdCatalog.placeable_reason(entry)
	if reason.is_empty():
		data["how"] = "Press Use this picture to copy it into the builder and place it."
	else:
		data["how"] = reason
		data["limits"] = [reason]
	EdHelp.entries["asset:" + id] = data


## The search box changed: filter by its text.
func _on_search_changed(text: String) -> void:
	_query = text
	_page = 0
	refresh()


## The category box changed: filter by the picked category id.
func _on_category_selected(index: int) -> void:
	var value: Variant = category_box.get_item_metadata(index)
	_category = "" if value == null else String(value)
	_page = 0
	refresh()


## A row was clicked: pick it unless it is already the picked one.
func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _results.size():
		return
	if String(_results[index].get("id", "")) != _selected_id:
		pick(index)


## A row was double clicked: use it.
func _on_item_activated(_index: int) -> void:
	use_selected()


func _show_category_help(_event: InputEventMouseButton) -> void:
	var key := "library.recent" if _category == RECENT_CATEGORY else "catalog." + _category
	EdHelp.show(key if EdHelp.has(key) else "library.categories")


## The "?" button: open help for the picked asset.
func _on_help() -> void:
	var key := help_key()
	EdHelp.show(key if not key.is_empty() else "library.asset_help")
