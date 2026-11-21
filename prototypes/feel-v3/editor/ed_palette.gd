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
const RECENT_LIMIT := 12
const RECENT_CATEGORY := "Recent"

static var _recent_ids: Array[String] = []
const Shell := preload("res://editor/workspace_shell.gd")

## The most rows shown at once; a broader search says so and asks for more text.
const MAX_RESULTS := 300
## The largest thumbnail side, in pixels.
const THUMB := 48

## Pictures actually read from disk since the last clear_thumbs().
static var thumb_loads: int = 0
## Thumbnail cache keyed by entry id (a null value means "no thumbnail").
static var _thumbs: Dictionary = {}

var search_box: LineEdit
var category_box: OptionButton
var recent_button: CheckButton
var help_button: Button
var use_button: Button

var _list: ItemList
var _info: Label
var _truncated_label: Label
var _results: Array = []
var _query := ""
var _category := ""
var _selected_id := ""
var _truncated := false
var _cat_sig := "?"


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
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(320, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info.add_theme_color_override("font_color", Shell.INK)
	scroll.add_child(_info)

	_truncated_label = Label.new()
	_truncated_label.text = "Showing the first %d matches. Type more to narrow." % MAX_RESULTS
	_truncated_label.visible = false
	root.add_child(_truncated_label)

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

	refresh()


## Filter by this text and show it in the search box.
func search_text(text: String) -> void:
	_query = text
	if search_box.text != text:
		search_box.text = text
	refresh()


## Filter to one category id, Recent, or "" for all, and show it in the category box.
func set_category(id: String) -> void:
	_category = id
	_select_category_item()
	refresh()


## Rebuild the category box and the result list from the catalog.
func refresh() -> void:
	_refresh_categories()
	var found := EdCatalog.search_ids(_query, _recent_ids) if _category == RECENT_CATEGORY else EdCatalog.search(_query, _category, MAX_RESULTS + 1)
	_truncated = found.size() > MAX_RESULTS
	if _truncated:
		found.resize(MAX_RESULTS)
	_results = found
	_list.clear()
	for entry: Dictionary in _results:
		var sub := String(entry.get("sub", ""))
		_list.add_item(String(entry.get("name", "")) + ("   [%s]" % sub if sub != "" else ""), _thumb_for(entry))
	_truncated_label.visible = _truncated
	_selected_id = ""
	use_button.disabled = true
	if EdCatalog.entry_count() == 0:
		_info.text = "The library is empty. Run: node tools/asset_library.mjs"
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


## True when the search matched more than MAX_RESULTS entries.
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
	var tex: Texture2D = null
	if String(entry.get("kind", "")) == "image":
		var rel := String(entry.get("path", ""))
		var root := EdAssets.library_root()
		if not rel.is_empty() and not root.is_empty():
			var path := root.path_join(rel)
			if FileAccess.file_exists(path):
				var img := Image.load_from_file(path)
				if img != null and not img.is_empty():
					thumb_loads += 1
					if img.get_width() > THUMB or img.get_height() > THUMB:
						var scale := minf(float(THUMB) / float(img.get_width()), float(THUMB) / float(img.get_height()))
						img.resize(maxi(1, roundi(img.get_width() * scale)), maxi(1, roundi(img.get_height() * scale)), Image.INTERPOLATE_BILINEAR)
					tex = ImageTexture.create_from_image(img)
	_thumbs[id] = tex
	return tex


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
	var path := String(entry.get("path", ""))
	if not path.is_empty():
		lines.append("Library: " + path)
	var source := String(entry.get("source", ""))
	if not source.is_empty():
		lines.append("Source: " + source)
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
	refresh()


## The category box changed: filter by the picked category id.
func _on_category_selected(index: int) -> void:
	var value: Variant = category_box.get_item_metadata(index)
	_category = "" if value == null else String(value)
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
