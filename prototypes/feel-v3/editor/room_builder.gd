# PROTOTYPE - NOT FOR PRODUCTION
extends CanvasLayer

const EdHelp := preload("res://editor/ed_help.gd")

signal closed

const RoomDoc := preload("res://editor/room_doc.gd")
const EdSelection := preload("res://editor/ed_selection.gd")
const EdAssets := preload("res://editor/ed_assets.gd")
const EdCatalog := preload("res://editor/ed_catalog.gd")
const EdPalette := preload("res://editor/ed_palette.gd")
const RoomScript := preload("res://room.gd")
const RoomChecks := preload("res://editor/room_checks.gd")
const Shell := preload("res://editor/workspace_shell.gd")
const Files := preload("res://editor/workspace_files.gd")
const TILE := 16
const DESIGN_TINT := Color("#ac9bf1")
const PLAY_TINT := Color("#73e3b7")
const WARNING_TINT := Color("#ecbd73")
const ISSUE_TINT := Color("#fb9896")

var doc: RefCounted
var room_id := ""
var sheet := "before"
var tab := "TERRAIN"
var tool := "SELECT"
var plane := "back"
var sel: Dictionary = {}
var checks: Array = []

var _shell: Control
var _view: Control
var _overlay: Control
var _art: RoomScript
var _status: Label
var _title: Label
var _zoom_label: Label
var _picked_label: Label
var _move_btn: Button
var _delete_btn: Button
var _flip_btn: Button
var _issues: VBoxContainer
var _check_btn: Button
var _issue_summary: Label
var _tabs: OptionButton
var _list: ItemList
var _count: SpinBox
var _spread: VBoxContainer
var _spread_btn: Button
var _plane_choice: OptionButton
var _assets_actions: HBoxContainer
var _empty_palette: Label
var _width: SpinBox
var _height: SpinBox
var _save_btn: Button
var _undo_btn: Button
var _redo_btn: Button
var _tool_buttons := {}
var _entries: Array = []
var _markers := {}
var _copy_btn: Button
var _cut_btn: Button
var _paste_btn: Button
var _dup_btn: Button
var _transform_buttons: Array[Button] = []
var _free_btn: Button
var _clipboard: Dictionary = {}
var _selecting_box := false
var _box_select_start := Vector2i(-1, -1)
var _group_drag := false
var _group_drag_start := Vector2i(-1, -1)

var library_button: Button
var library_palette: Control = null
var _library_overlay: Control

var _cam := Vector2.ZERO
var _zoom := 1.0
var _framing := true
var _hover := Vector2i(-1, -1)
var _mouse := Vector2.ZERO
var _has_mouse := false
var _panning := false
var _pan_button := 0
var _pan_from := Vector2.ZERO
var _cam_from := Vector2.ZERO
var _painting := false
var _stroke_snapshot := false
var _last_brush_cell := Vector2i(-1, -1)
var _selection: Dictionary = {}
var _drag: Dictionary = {}
var _zone := Rect2i()
var _zone_on := false
var _zone_drag := false
var _zone_start := Vector2i.ZERO
var _start_cell := Vector2i(-1, -1)
var _grid := false
var _collisions := false
var _issue_focus := Rect2()
var _playing := false
var _active := true
var _msg := ""
var _revision := 0
var _check_revision := 0
var _check_thread: Thread
var _refresh_pending := false
var _saved_text := ""
var _saved_props := ""
var _save_root := ""
var _expected := {}
var _dirty := false


func _ready() -> void:
	layer = 101


## Load and retain one room/era draft. The Dev hub keeps this view when switching to the map.
func begin(info: Dictionary) -> void:
	var main = G.main
	var current_id := String(main.room_name) if main != null else "church"
	room_id = String(info.get("room", current_id))
	sheet = String(info.get("sheet", W.sheet))
	var file: String = info.get("file_id", Dev.room_file_id(room_id, sheet))
	doc = info.get("doc")
	if doc == null:
		doc = RoomDoc.parse(file, RoomScript.read_room_file(file), _props_source(file))
	elif not info.has("room"):
		room_id = String(doc.file_id).trim_suffix("_shift").trim_suffix("_restored")
	EdAssets.ensure_folders()
	_saved_text = doc.to_text()
	_saved_props = doc.props_text()
	_save_root = Dev.project_dir()
	_expected = _read_expected(_save_root)
	_build_ui()
	_rebuild_markers()
	_set_tab(tab)
	_set_tool(tool)
	_refresh()
	_fit.call_deferred()
	_say("Click an object, or Shift+drag to select a box.")


func _props_source(file: String) -> String:
	var root: String = Dev.project_dir()
	var rel := "rooms/%s.props.json" % file
	var path := root.path_join(rel) if root != "" else ""
	if path != "" and FileAccess.file_exists(path):
		return FileAccess.get_file_as_string(path)
	return FileAccess.get_file_as_string("res://" + rel) if FileAccess.file_exists("res://" + rel) else ""


## Only the active workspace accepts input or shows controls.
func set_active(active: bool) -> void:
	_active = active
	if _shell != null:
		_shell.visible = active
	if not active:
		_end_pointer_actions()


func _build_ui() -> void:
	_shell = Shell.mount(self)
	var margin := MarginContainer.new()
	_shell.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	layout.add_child(top)
	Shell.button(top, "Map", func(): Dev.show_map(), "Open the map (F3)", "builder.map", false)
	var room_heading := _label(top, "Room · Right-click for help", 16)
	room_heading.modulate = DESIGN_TINT
	_title = _label(top, "", 19)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_save_btn = Shell.button(top, "Save", save, "Save this room and its PNG placements (Ctrl+S)", "builder.save", false)
	Shell.button(top, "Playtest", play, "Play this room with the current edits (Tab)", "builder.playtest", false)
	Shell.button(top, "Close", func(): Dev.request_close(), "Close the builders", "builder.close", false)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	layout.add_child(actions)
	_tool_button(actions, "SELECT", "Select", "Select an existing object (V)")
	_tool_button(actions, "PLACE", "Place", "Place the selected palette item (B)")
	_tool_button(actions, "MOVE", "Move", "Drag an object to a new spot (M)")
	_tool_button(actions, "ERASE", "Erase", "Erase a glyph or remove a PNG (E)")
	_tool_button(actions, "ZONE", "Spread", "Draw an area for enemies or traps (S)")
	_tool_button(actions, "START", "Play from here", "Choose a playtest start on the canvas (P)")
	_spacer(actions)
	_undo_btn = Shell.button(actions, "Undo", _undo, "Undo (Ctrl+Z)", "builder.undo", false)
	_redo_btn = Shell.button(actions, "Redo", _redo, "Redo (Ctrl+Y)", "builder.undo", false)
	_toggle(actions, "Grid", false, func(value: bool):
		_grid = value
		_overlay.queue_redraw())
	_toggle(actions, "Collision", false, func(value: bool):
		_collisions = value
		_overlay.queue_redraw())

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)
	_build_palette(body)
	_build_canvas(body)
	_build_inspector(body)

	_status = _label(layout, "", 16)
	_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _build_palette(parent: HBoxContainer) -> void:
	var panel := _sidebar(parent, 218)
	_label(panel, "Palette", 22)
	var library_row := HBoxContainer.new()
	panel.add_child(library_row)
	library_button = Shell.button(library_row, "Library", open_library, "Find any picture in the project: search, categories, preview", "studio.library")
	library_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs = OptionButton.new()
	EdHelp.attach(_tabs, "builder.tabs", func(_mouse: InputEventMouseButton):
		EdHelp.show("palette." + tab.to_lower()))
	for label in EdAssets.CATEGORY_LABELS:
		_tabs.add_item(label)
	_tabs.item_selected.connect(func(index: int): _set_tab(EdAssets.TABS[index]))
	panel.add_child(_tabs)
	_list = ItemList.new()
	EdHelp.attach(_list, "builder.palette", _show_palette_help)
	_list.select_mode = ItemList.SELECT_MULTI
	_list.fixed_icon_size = Vector2i(30, 30)
	_list.add_theme_constant_override("v_separation", 6)
	_list.clip_contents = true
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.multi_selected.connect(_on_pick)
	panel.add_child(_list)
	_empty_palette = _label(panel, "Add PNGs in the asset folder, then refresh.", 15)
	_empty_palette.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_assets_actions = HBoxContainer.new()
	panel.add_child(_assets_actions)
	Shell.button(_assets_actions, "Asset Folder", _open_assets, "", "builder.asset_folder", false)
	Shell.button(_assets_actions, "Refresh", _refresh_assets, "", "builder.refresh", false)
	_plane_choice = OptionButton.new()
	EdHelp.attach(_plane_choice, "builder.plane")
	for name in ["Behind", "Solid", "In Front"]:
		_plane_choice.add_item(name)
	_plane_choice.item_selected.connect(func(index: int): plane = ["back", "solid", "front"][index])
	panel.add_child(_plane_choice)
	_spread = VBoxContainer.new()
	panel.add_child(_spread)
	var count_line := HBoxContainer.new()
	_spread.add_child(count_line)
	_label(count_line, "Count", 16)
	_count = _spinner(count_line, 1, 40, 4, "builder.count")
	_spread_btn = Shell.button(_spread, "Apply Spread", spread_zone, "", "builder.apply_spread", false)
	_spread_btn.tooltip_text = "Select enemy or trap types, then draw a region with Spread."


func _build_canvas(parent: HBoxContainer) -> void:
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 6)
	parent.add_child(center)
	var nav := HBoxContainer.new()
	center.add_child(nav)
	var help := _label(nav, "Wheel to zoom · Space + drag to pan", 15)
	help.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Shell.button(nav, "−", func(): _zoom_at(_view.size * 0.5, 1.0 / 1.25), "Zoom out", "builder.zoom_out", false)
	_zoom_label = _label(nav, "100%", 15)
	_zoom_label.custom_minimum_size.x = 56
	_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Shell.button(nav, "+", func(): _zoom_at(_view.size * 0.5, 1.25), "Zoom in", "builder.zoom_in", false)
	Shell.button(nav, "Fit", _fit, "Frame the whole room (F)", "builder.fit", false)
	_view = Control.new()
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view.clip_contents = true
	_view.draw.connect(func(): _view.draw_rect(Rect2(Vector2.ZERO, _view.size), Color("#101015")))
	_view.gui_input.connect(_on_view_input)
	_view.mouse_exited.connect(func():
		_has_mouse = false
		_overlay.queue_redraw())
	center.add_child(_view)
	_art = RoomScript.new()
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_view.add_child(_art)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.z_index = 16
	_view.add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.draw.connect(_on_draw)
	_view.resized.connect(func():
		if _framing:
			_fit()
		else:
			_overlay.queue_redraw())


func _build_inspector(parent: HBoxContainer) -> void:
	var panel := _sidebar(parent, 288)
	_label(panel, "Selection", 22)
	_picked_label = _label(panel, "No object selected", 16)
	_picked_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var picked_actions := HBoxContainer.new()
	panel.add_child(picked_actions)
	_move_btn = Shell.button(picked_actions, "Move", func(): _set_tool("MOVE"), "", "builder.move", false)
	_delete_btn = Shell.button(picked_actions, "Delete", _delete_selection, "", "builder.delete", false)
	_flip_btn = Shell.button(picked_actions, "Flip", _flip_selection, "", "builder.flip", false)
	var clipboard_actions := HBoxContainer.new()
	panel.add_child(clipboard_actions)
	_copy_btn = Shell.button(clipboard_actions, "Copy", _copy_region, "Copy the box (Ctrl+C)", "builder.copy", false)
	_cut_btn = Shell.button(clipboard_actions, "Cut", _cut_region, "Cut the box (Ctrl+X)", "builder.cut", false)
	_paste_btn = Shell.button(clipboard_actions, "Paste", _paste_clipboard, "Paste at the last tile pointed to (Ctrl+V)", "builder.paste", false)
	_dup_btn = Shell.button(clipboard_actions, "Duplicate", _duplicate_region, "Make a second copy (Ctrl+D)", "builder.duplicate", false)
	var picture_actions := HBoxContainer.new()
	panel.add_child(picture_actions)
	_transform_buttons = [
		Shell.button(picture_actions, "Rotate", _rotate_prop, "Turn a decorative picture by 15° (R)", "builder.rotate", false),
		Shell.button(picture_actions, "− Size", _scale_prop.bind(-0.25), "Shrink a decorative picture ([)", "builder.shrink", false),
		Shell.button(picture_actions, "+ Size", _scale_prop.bind(0.25), "Grow a decorative picture (])", "builder.grow", false),
	]
	_free_btn = Shell.button(picture_actions, "Free", _say_free_placement, "Place and move decorative pictures without snapping", "builder.free", false)
	_free_btn.toggle_mode = true
	_label(panel, "Room Size · Tiles", 17)
	var dimensions := HBoxContainer.new()
	panel.add_child(dimensions)
	_width = _spinner(dimensions, 4, 1024, 4, "builder.width")
	_label(dimensions, "×", 16)
	_height = _spinner(dimensions, 4, 1024, 4, "builder.height")
	Shell.button(dimensions, "Apply", _apply_size, "", "builder.resize", false)
	_build_playtest_options(panel)

	_label(panel, "Issues", 22)
	_check_btn = Shell.button(panel, "Check Reachability", run_full_check, "", "builder.check", false)
	_issue_summary = _label(panel, "", 15)
	_issue_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var list := ScrollContainer.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(list)
	_issues = VBoxContainer.new()
	_issues.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(_issues)


func _build_playtest_options(parent: Container) -> void:
	var options := MenuButton.new()
	EdHelp.attach(options, "builder.options")
	options.text = "Playtest Options"
	options.tooltip_text = "Show hitboxes, Invincible, Half speed"
	parent.add_child(options)
	var menu := options.get_popup()
	menu.add_check_item("Show hitboxes", 0)
	menu.add_check_item("Invincible", 1)
	menu.add_check_item("Half speed", 2)
	menu.about_to_popup.connect(func():
		menu.set_item_checked(0, T.v("show_hitboxes") >= 0.5)
		menu.set_item_checked(1, Dev.god)
		menu.set_item_checked(2, Engine.time_scale < 1.0))
	menu.id_pressed.connect(_on_playtest_option)


func _on_playtest_option(id: int) -> void:
	match id:
		0:
			T.set_v("show_hitboxes", 0.0 if T.v("show_hitboxes") >= 0.5 else 1.0)
		1:
			Dev.god = not Dev.god
		2:
			Engine.time_scale = 1.0 if Engine.time_scale < 1.0 else 0.5


func _sidebar(parent: HBoxContainer, width: float) -> VBoxContainer:
	var side := PanelContainer.new()
	side.custom_minimum_size.x = width
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#22202c")
	style.content_margin_left = 11
	style.content_margin_right = 11
	style.content_margin_top = 11
	style.content_margin_bottom = 11
	style.set_corner_radius_all(6)
	side.add_theme_stylebox_override("panel", style)
	parent.add_child(side)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	side.add_child(content)
	return content


func _label(parent: Container, value: String, size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label


func _spinner(parent: Container, low: int, high: int, value: int, help_key: String) -> SpinBox:
	var box := SpinBox.new()
	EdHelp.attach(box, help_key)
	EdHelp.attach(box.get_line_edit(), help_key)
	box.min_value = low
	box.max_value = high
	box.value = value
	box.custom_minimum_size.x = 67
	parent.add_child(box)
	return box


func _spacer(parent: Container) -> void:
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(space)


func _toggle(parent: Container, title: String, value: bool, action: Callable) -> void:
	var button := CheckButton.new()
	EdHelp.attach(button, "builder." + title.to_lower())
	button.text = title
	button.button_pressed = value
	button.toggled.connect(action)
	parent.add_child(button)


func _tool_button(parent: Container, mode: String, title: String, hint: String) -> void:
	var button := Shell.button(parent, title, func(): _set_tool(mode), hint, "builder." + mode.to_lower(), false)
	button.toggle_mode = true
	_tool_buttons[mode] = button


## The same on-disk document can appear on more than one map era.
func set_room_context(id: String, era: String) -> void:
	room_id = id
	sheet = era
	_update_status()


func _rebuild_markers() -> void:
	_markers.clear()
	for category in ["ENEMIES", "HAZARDS", "SPOTS"]:
		for entry: Dictionary in EdAssets.entries(category):
			var glyph: String = entry["glyph"]
			var label := String(entry.get("label", entry["name"])).capitalize()
			_markers[glyph] = {"name": label, "icon": _thumbnail(entry, category), "category": category}


func _thumbnail(entry: Dictionary, category: String) -> Texture2D:
	var theme: Dictionary = RoomScript.THEMES.get(doc.head.get("theme", "church"), RoomScript.THEMES["church"])
	return EdAssets.thumbnail(entry, category, theme["tiles"])


func _set_tab(category: String) -> void:
	tab = category
	_tabs.select(EdAssets.TABS.find(category))
	_entries = EdAssets.entries(category)
	_list.clear()
	for entry: Dictionary in _entries:
		var name := String(entry.get("label", entry["name"])).capitalize()
		var index := _list.add_item(name, _thumbnail(entry, category))
		_list.set_item_tooltip(index, name)
	sel = {}
	_assets_actions.visible = category in ["TILES", "PROPS", "BACKDROPS"]
	_empty_palette.visible = _entries.is_empty()
	_plane_choice.visible = category in ["TILES", "PROPS"]
	if category == "TILES":
		plane = "solid"
	elif category == "PROPS":
		plane = "back"
	_plane_choice.select(["back", "solid", "front"].find(plane))
	_update_spread()
	_overlay.queue_redraw()


func _show_palette_help(mouse: InputEventMouseButton) -> void:
	var index := _list.get_item_at_position(mouse.position, true)
	if index < 0:
		EdHelp.show("builder.palette")
		return
	var entry: Dictionary = _entries[index]
	var glyph := str(entry.get("glyph", ""))
	var key := "glyph." + glyph
	if not EdHelp.has(key):
		key = "palette." + tab.to_lower()
	EdHelp.show(key)


func _on_pick(index: int, selected: bool) -> void:
	if selected:
		sel = _entries[index]
		if tool != "ZONE":
			_set_tool("PLACE")
	else:
		var selected_items := _list.get_selected_items()
		sel = {} if selected_items.is_empty() else _entries[selected_items[0]]
	_update_spread()
	_overlay.queue_redraw()


func _open_assets() -> void:
	var path := EdAssets.editor_root()
	if path != "" and OS.shell_open(ProjectSettings.globalize_path(path)) != OK:
		_say("Could not open the asset folder.")


func _refresh_assets() -> void:
	EdAssets.clear_cache()
	_rebuild_markers()
	_set_tab(tab)
	_refresh()
	_say("Asset palette refreshed.")


## Open the searchable asset-library overlay; opening it again keeps the same one.
func open_library() -> void:
	if library_palette != null and is_instance_valid(library_palette):
		return
	if EdCatalog.entry_count() == 0:
		EdCatalog.load_file(EdAssets.catalog_path())
	var overlay := Control.new()
	overlay.z_index = 64   # above the room overlay (z_index 16)
	_shell.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_library_overlay = overlay
	var dim := ColorRect.new()
	dim.color = Color(Shell.BACKGROUND, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(940, 600)
	var style := StyleBoxFlat.new()
	style.bg_color = Shell.SURFACE
	style.border_color = Shell.ACCENT
	style.set_border_width_all(1)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var palette := EdPalette.new()
	palette.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	palette.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(palette)
	library_palette = palette
	palette.entry_used.connect(func(entry: Dictionary) -> void:
		if use_library_entry(entry):
			EdPalette.record_recent(str(entry.get("id", "")))
			close_library())
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(footer)
	Shell.button(footer, "Close", close_library, "", "library.close", false)


## Close the library overlay at once; harmless when it is already closed.
func close_library() -> void:
	var overlay := _library_overlay
	_library_overlay = null
	library_palette = null
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()


## Copy a library picture into the builder, switch to its tab and arm placing.
func use_library_entry(entry: Dictionary) -> bool:
	var reason := EdCatalog.placeable_reason(entry)
	if not reason.is_empty():
		_say(reason)
		return false
	var rel := EdAssets.adopt(entry)
	if rel.is_empty():
		_say("Could not copy that picture into the builder's folder.")
		return false
	EdAssets.clear_cache()
	_set_tab(String(entry.get("placeable", "")).to_upper())
	var index := -1
	for i in _entries.size():
		if String((_entries[i] as Dictionary).get("png", "")) == rel:
			index = i
			break
	if index >= 0:
		_list.select(index)
		_on_pick(index, true)
		_set_tool("PLACE")
	_say("Ready to place %s. Click in the room." % String(entry.get("name", "")))
	return true


func _set_tool(mode: String) -> void:
	_end_pointer_actions()
	tool = mode
	if tool not in ["SELECT", "MOVE"] and _selection.has("region"):
		_selection = {}
		_update_selection()
	for key in _tool_buttons:
		_tool_buttons[key].set_pressed_no_signal(key == tool)
	if mode == "START":
		_say("Click a clear tile to set the playtest start.")
	elif mode == "ZONE":
		_say("Pick enemies or traps and drag across the area to fill.")
	elif mode == "MOVE":
		_say("Drag a room marker, enemy, trap, or PNG to move it.")
	_update_spread()
	_overlay.queue_redraw()


func _update_spread() -> void:
	_spread.visible = tool == "ZONE"
	_spread_btn.disabled = not _zone_on or tab not in ["ENEMIES", "HAZARDS"] or _list.get_selected_items().is_empty()


func _say(message: String) -> void:
	_msg = message
	_update_status()


func _update_status() -> void:
	if _status == null:
		return
	_dirty = is_dirty()
	var name := W.title(room_id)
	if name.is_empty():
		name = room_id.capitalize()
	_title.text = "%s  /  %s  ·  %s" % [name, sheet.capitalize(), "Unsaved changes" if _dirty else "Saved"]
	_save_btn.disabled = not _dirty
	_undo_btn.disabled = not doc.can_undo()
	_redo_btn.disabled = not doc.can_redo()
	_status.text = _msg
	_status.tooltip_text = _msg


func _fit() -> void:
	_framing = true
	if _view.size.x <= 0 or _view.size.y <= 0:
		return
	var room_size: Vector2 = doc.pixel_size()
	var available := (_view.size - Vector2(52, 52)).max(Vector2.ONE)
	_zoom = clampf(minf(available.x / maxf(room_size.x, 1.0), available.y / maxf(room_size.y, 1.0)), 0.05, 4.0)
	_cam = room_size * 0.5 - _view.size * 0.5 / _zoom
	_sync_camera()


func _to_world(at: Vector2) -> Vector2:
	return _cam + at / _zoom


func _to_screen(at: Vector2) -> Vector2:
	return (at - _cam) * _zoom


func _cell_of(at: Vector2) -> Vector2i:
	return Vector2i((at / TILE).floor())


func _zoom_at(at: Vector2, factor: float) -> void:
	_framing = false
	var world := _to_world(at)
	_zoom = clampf(_zoom * factor, 0.05, 8.0)
	_cam = world - at / _zoom
	_sync_camera()


func _sync_camera() -> void:
	_art.position = -_cam * _zoom
	_art.scale = Vector2.ONE * _zoom
	_zoom_label.text = "%d%%" % roundi(_zoom * 100.0)
	if _has_mouse:
		_hover = _cell_of(_to_world(_mouse))
	_overlay.queue_redraw()


func _changed() -> void:
	_revision += 1
	_issue_focus = Rect2()
	_update_status()
	if not _refresh_pending:
		_refresh_pending = true
		_refresh.call_deferred()


func _refresh() -> void:
	_refresh_pending = false
	_art.preview_document(doc)
	_width.set_value_no_signal(doc.width())
	_height.set_value_no_signal(doc.height())
	_update_selection()
	_recheck()
	_sync_camera()


func _recheck() -> void:
	checks = RoomChecks.new().run(doc)
	_show_issues()
	_overlay.queue_redraw()


## The checker snapshots the draft before work starts, so editing and saving stay available.
func run_full_check() -> void:
	if _check_thread != null:
		return
	_recheck()
	var checker := RoomChecks.new()
	checker.prepare(doc)
	_check_revision = _revision
	_check_thread = Thread.new()
	if _check_thread.start(checker.run_reach) != OK:
		_check_thread = null
		_say("Could not start the reachability check.")
	_show_issues()


func _process(_delta: float) -> void:
	if _check_thread == null or _check_thread.is_alive():
		return
	var result: Array = _check_thread.wait_to_finish()
	_check_thread = null
	if _revision == _check_revision:
		checks.append_array(result)
		_say("Reachability check complete.")
	else:
		_say("The room changed during the check. Run it again for the current draft.")
	_show_issues()
	_overlay.queue_redraw()


func _show_issues() -> void:
	_check_btn.disabled = _check_thread != null
	_issue_summary.text = "Checking reachability…" if _check_thread != null else (
		"No issues in the current check." if checks.is_empty() else "%d issues · select one to locate it" % checks.size())
	for child in _issues.get_children():
		_issues.remove_child(child)
		child.queue_free()
	for issue: Dictionary in checks:
		var type := String(issue.get("kind", "route"))
		var heading: String = {"asset": "Missing Asset", "exit": "Blocked Exit",
			"clearance": "Low Jump Clearance", "jump": "Jump Advisory"}.get(type, "Reachability")
		var body := String(issue["text"]).trim_prefix("ceiling trap: ")
		body = body.left(1).to_upper() + body.substr(1)
		var button := Shell.button(_issues, heading, _focus_issue.bind(issue["rect"]), body, "builder.issue", false)
		button.modulate = _issue_color(issue)
		var detail := _label(_issues, body, 14)
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _focus_issue(rect: Rect2) -> void:
	_framing = false
	_issue_focus = rect
	_zoom = maxf(_zoom, 1.2)
	_cam = rect.get_center() - _view.size * 0.5 / _zoom
	_sync_camera()


func _issue_color(issue: Dictionary) -> Color:
	return WARNING_TINT if issue.get("severity") == "advisory" else ISSUE_TINT


func _undo() -> void:
	if doc.undo():
		_selection = {}
		_changed()
		_say("Undone.")


func _redo() -> void:
	if doc.redo():
		_selection = {}
		_changed()
		_say("Redone.")


func _apply_size() -> void:
	var width := int(_width.value)
	var height := int(_height.value)
	if width == doc.width() and height == doc.height():
		return
	doc.push_undo()
	doc.resize(width, height)
	_selection = {}
	if not doc.in_room(_start_cell.x, _start_cell.y):
		_start_cell = Vector2i(-1, -1)
	_changed()
	_fit.call_deferred()
	_say("Room size is %d × %d tiles. Its map footprint is edited in F3." % [width, height])


func _record_stroke() -> void:
	if not _stroke_snapshot:
		doc.push_undo()
		_stroke_snapshot = _painting


func _paint(cell: Vector2i) -> void:
	var glyph := String(sel.get("glyph", ""))
	if glyph == "" or not doc.in_room(cell.x, cell.y) or doc.get_cell(cell.x, cell.y) == glyph:
		return
	_record_stroke()
	if glyph == "P":
		for y in doc.height():
			for x in doc.width():
				if doc.get_cell(x, y) == "P":
					doc.set_cell(x, y, ".")
	doc.set_cell(cell.x, cell.y, glyph)
	_changed()


func _place_picture(at: Vector2) -> void:
	var png := String(sel.get("png", ""))
	if tab == "BACKDROPS":
		var backdrop := png.get_file()
		if doc.head.get("backdrop", "") == backdrop:
			return
		doc.push_undo()
		if backdrop == "":
			doc.head.erase("backdrop")
		else:
			doc.head["backdrop"] = backdrop
	elif png != "":
		var pos := _picture_position(at, png, tab == "TILES")
		if not doc.in_room(_cell_of(at).x, _cell_of(at).y):
			return
		doc.push_undo()
		doc.add_prop(png, pos.x, pos.y, plane, tab == "TILES")
		if _free_btn.button_pressed and (tab == "TILES" or plane == "solid"):
			_say("Solid and tile pictures stay on the grid.")
	else:
		return
	_changed()


func _picture_position(at: Vector2, png: String, is_tile: bool) -> Vector2:
	if is_tile or plane == "solid":
		return Vector2(_cell_of(at)) * TILE
	var anchor := at - EdAssets.size_of(png) * 0.5
	return anchor if _free_btn.button_pressed else (anchor / 8.0).round() * 8.0


func _pick_at(at: Vector2) -> Dictionary:
	var i: int = doc.prop_at(at, EdAssets.size_of)
	if i >= 0:
		return {"prop": i}
	var cell := _cell_of(at)
	if doc.in_room(cell.x, cell.y) and doc.get_cell(cell.x, cell.y) != ".":
		return {"cell": cell}
	return {}


func _update_selection() -> void:
	var movable := false
	var label := "No object selected"
	var group := _selection.has("region")
	if group:
		var rect: Rect2i = _selection["region"]
		label = "%d × %d tiles selected\nDrag or use arrows to move the box." % [rect.size.x, rect.size.y]
	elif _selection.has("prop"):
		var picture: Dictionary = doc.props[_selection["prop"]]
		var layer_name := String(picture.get("layer", "back")).capitalize()
		label = "%s\nPNG · %s" % [String(picture["png"]).get_file(), layer_name]
		movable = true
	elif _selection.has("cell"):
		var c: Vector2i = _selection["cell"]
		var glyph: String = doc.get_cell(c.x, c.y)
		label = "%s  ·  Tile %d, %d" % [_glyph_name(glyph), c.x + 1, c.y + 1]
		movable = glyph not in ["#", "=", ".", "B"]
	_picked_label.text = label
	_move_btn.disabled = not movable
	_delete_btn.disabled = _selection.is_empty()
	_flip_btn.disabled = not _selection.has("prop")
	_copy_btn.disabled = not group
	_cut_btn.disabled = not group
	_dup_btn.disabled = not group
	_paste_btn.disabled = _clipboard.is_empty()
	for button in _transform_buttons:
		button.disabled = not _selection.has("prop")


func _glyph_name(glyph: String) -> String:
	if _markers.has(glyph):
		return _markers[glyph]["name"]
	for terrain in EdAssets.TERRAIN:
		if terrain[0] == glyph:
			return String(terrain[1]).capitalize()
	return glyph


func _erase_at(at: Vector2) -> void:
	_erase_object(_pick_at(at))


func _erase_object(target: Dictionary) -> void:
	if target.is_empty():
		return
	_record_stroke()
	if target.has("prop"):
		doc.props.remove_at(target["prop"])
	else:
		var c: Vector2i = target["cell"]
		doc.set_cell(c.x, c.y, ".")
	_selection = {}
	_changed()


func _delete_selection() -> void:
	if not _selection.has("region"):
		_erase_object(_selection)
		return
	var rect: Rect2i = _selection["region"]
	if EdSelection.has_content(doc.copy_region(rect)):
		doc.push_undo()
		doc.clear_region(rect)
		_changed()
	_selection = {}
	_update_selection()
	_overlay.queue_redraw()


func _room_bounds() -> Rect2i:
	return Rect2i(0, 0, doc.width(), doc.height())


func _update_box_selection() -> void:
	var region := EdSelection.box_rect(_box_select_start, _hover, _room_bounds())
	_selection = {"region": region} if region.has_area() else {}
	_update_selection()


func _move_region(offset: Vector2i) -> void:
	if offset == Vector2i.ZERO:
		return
	var rect: Rect2i = _selection["region"]
	var block: Dictionary = doc.copy_region(rect)
	var target := rect.position + offset
	if not EdSelection.can_move(doc, target, block):
		_say("That move would leave part of the selection outside the room.")
		return
	if EdSelection.has_content(block) or EdSelection.would_paste(doc, target, block):
		doc.push_undo()
		doc.clear_region(rect)
		doc.paste_region(target, block)
		_changed()
	var moved := Rect2i(target, rect.size).intersection(_room_bounds())
	_selection = {"region": moved} if moved.has_area() else {}
	_update_selection()
	_overlay.queue_redraw()


func _copy_region() -> void:
	if not _selection.has("region"):
		return
	_clipboard = doc.copy_region(_selection["region"])
	_update_selection()
	_say("Copied the selection. Point at a tile and press Ctrl+V to paste.")


func _cut_region() -> void:
	if not _selection.has("region"):
		return
	_copy_region()
	_delete_selection()
	_say("Cut the selection. Point at a tile and press Ctrl+V to paste.")


func _paste_clipboard() -> void:
	if not _clipboard.is_empty():
		_paste_region(_hover, _clipboard)


func _duplicate_region() -> void:
	if not _selection.has("region"):
		return
	var rect: Rect2i = _selection["region"]
	var target := _hover
	if rect.has_point(target) or not doc.in_room(target.x, target.y):
		target = rect.position + Vector2i(rect.size.x, 0)
		if not doc.in_room(target.x, target.y):
			target = rect.position - Vector2i(rect.size.x, 0)
	_paste_region(target, doc.copy_region(rect))


func _paste_region(at: Vector2i, block: Dictionary) -> void:
	if not doc.in_room(at.x, at.y):
		_say("Point at a tile in the room before pasting.")
		return
	if EdSelection.would_paste(doc, at, block):
		doc.push_undo()
	var clipped: bool = doc.paste_region(at, block)
	var region := Rect2i(at, block["size"]).intersection(_room_bounds())
	_selection = {"region": region}
	_changed()
	_say("Pasted. The room edge clipped part of the selection." if clipped else "Pasted the selection.")


func _flip_selection() -> void:
	if not _selection.has("prop"):
		return
	doc.push_undo()
	var picture: Dictionary = doc.props[_selection["prop"]]
	picture["flip"] = not bool(picture.get("flip", false))
	_changed()


func _say_free_placement() -> void:
	_say("Free placement is on for decorative pictures." if _free_btn.button_pressed else "Decorative pictures snap as you place and move them.")


func _rotate_prop() -> void:
	_change_prop_transform("rot", 15.0, 0.0)


func _scale_prop(amount: float) -> void:
	_change_prop_transform("scale", amount, 1.0)


func _change_prop_transform(field: String, change: float, default: float) -> void:
	if not _selection.has("prop"):
		return
	var picture: Dictionary = doc.props[_selection["prop"]]
	if not RoomDoc.can_transform_prop(picture):
		_say("Only decorative pictures can turn or resize. Solid and tile pictures stay on the grid.")
		return
	var before := float(picture.get(field, default))
	var after := before + change
	after = wrapf(after, -180.0, 180.0) if field == "rot" else clampf(after, 0.25, 4.0)
	if is_equal_approx(before, after):
		return
	doc.push_undo()
	picture[field] = after
	_changed()
	_say("Picture rotation: %s°." % str(after) if field == "rot" else "Picture size: %s×." % str(after))


func _pick_for_move(at: Vector2) -> void:
	_selection = _pick_at(at)
	_update_selection()
	if _move_btn.disabled:
		return
	_drag = _selection.duplicate()
	if _drag.has("prop"):
		var picture: Dictionary = doc.props[_drag["prop"]]
		_drag["offset"] = at - Vector2(picture["x"], picture["y"])


func _move_picture_anchor(at: Vector2, picture: Dictionary) -> Vector2:
	var desired: Vector2 = at - _drag["offset"]
	if not RoomDoc.can_transform_prop(picture):
		return Vector2(_cell_of(desired)) * TILE
	return desired if _free_btn.button_pressed else (desired / 8.0).round() * 8.0


func _move_preview(at: Vector2) -> Rect2:
	if _drag.has("prop"):
		var picture: Dictionary = doc.props[_drag["prop"]]
		var transform := RoomDoc.prop_transform(picture)
		transform.origin = _move_picture_anchor(at, picture)
		return transform * Rect2(Vector2.ZERO, EdAssets.size_of(picture["png"]))
	return Rect2(Vector2(_cell_of(at)) * TILE, Vector2.ONE * TILE)


func _drop_move(at: Vector2) -> void:
	if _drag.is_empty():
		return
	var to := _cell_of(at)
	if not doc.in_room(to.x, to.y):
		_drag = {}
		return
	if _drag.has("prop"):
		var picture: Dictionary = doc.props[_drag["prop"]]
		var before := Vector2(picture["x"], picture["y"])
		var pos := _move_picture_anchor(at, picture)
		if pos != before:
			doc.push_undo()
			RoomDoc.set_prop_position(picture, pos)
			_changed()
			if _free_btn.button_pressed and not RoomDoc.can_transform_prop(picture):
				_say("Solid and tile pictures stay on the grid.")
	else:
		var origin: Vector2i = _drag["cell"]
		if origin != to and doc.get_cell(to.x, to.y) == ".":
			var glyph: String = doc.get_cell(origin.x, origin.y)
			doc.push_undo()
			doc.set_cell(origin.x, origin.y, ".")
			doc.set_cell(to.x, to.y, glyph)
			_selection = {"cell": to}
			_changed()
	_drag = {}


func spread_zone() -> void:
	if not _zone_on:
		_say("Use the Spread tool to draw an area first.")
		return
	if tab not in ["ENEMIES", "HAZARDS"] or _list.get_selected_items().is_empty():
		_say("Select types from the Enemies or Traps palette.")
		return
	var glyphs: Array = []
	for i in _list.get_selected_items():
		glyphs.append(_entries[i]["glyph"])
	var count := int(_count.value)
	var placed: int = doc.spread(_zone, glyphs, count)
	if placed > 0:
		_changed()
	var kind := "traps" if tab == "HAZARDS" else "enemies"
	_say("Placed %d %s." % [placed, kind] if placed == count else
		"Placed %d of %d %s. Choose a larger area with suitable floor or ceiling space." % [placed, count, kind])


## Dirty state compares both files, so undoing back to the saved draft clears it.
func is_dirty() -> bool:
	return doc != null and (doc.to_text() != _saved_text or doc.props_text() != _saved_props)


func _read_expected(root: String) -> Dictionary:
	var result := {}
	if root == "":
		return result
	for suffix in [".txt", ".props.json"]:
		var path := root.path_join("rooms/" + doc.file_id + suffix)
		result[path] = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else null
	return result


## Save the grid and sidecar as a unit. The draft stays dirty on conflict or write failure.
func save() -> bool:
	var root: String = Dev.project_dir()
	if root == "":
		_say("The builder workspace is unavailable. Your draft is still open.")
		return false
	var path := root.path_join("rooms/%s.txt" % doc.file_id)
	var props_path := root.path_join("rooms/%s.props.json" % doc.file_id)
	var text: String = doc.to_text()
	var pictures: String = doc.props_text()
	var writes := {path: text, props_path: pictures}
	var expected := _expected if _save_root == root else _read_expected(root)
	var stamp := Time.get_datetime_string_from_system(false, true).replace(":", "-").replace(" ", "_")
	var backup := "user://room_backups/%s_%s_%d" % [doc.file_id, stamp, Time.get_ticks_usec()]
	if expected.get(path) != null:
		writes[backup + ".txt"] = expected[path]
	if expected.get(props_path) != null:
		writes[backup + ".props.json"] = expected[props_path]
	var message := Files.commit(writes, expected)
	if message != "":
		_say(message)
		return false
	_save_root = root
	_expected = {path: text, props_path: pictures}
	_saved_text = text
	_saved_props = pictures
	_say("Saved %s and its PNG placements." % doc.file_id)
	return true


func _set_start(cell: Vector2i) -> void:
	if not doc.in_room(cell.x, cell.y):
		return
	for dy in 3:
		if _art.cell(cell.x, cell.y - dy) in ["#", "|", "%", "B", ":"]:
			_say("Pick a tile with enough space for Pandora to stand.")
			return
	_start_cell = cell
	_say("Playtest start set. Click Playtest or press Tab.")
	_overlay.queue_redraw()


## Launch the selected draft and sheet through the shared playtest session.
func play() -> void:
	if _playing:
		return
	var feet = null
	if doc.in_room(_start_cell.x, _start_cell.y):
		feet = Vector2((_start_cell.x + 0.5) * TILE, (_start_cell.y + 1) * TILE - 0.5)
	_playing = true
	if not await Dev.play_room_draft(doc, room_id, sheet, feet):
		_playing = false
		_say("Could not playtest this room. Your draft is still open.")


func edit_again() -> void:
	Dev.return_to_builder()


func finish_playtest() -> void:
	_playing = false
	_say("Back in the draft.")


func spawn_picked() -> void:
	var main = G.main
	if main == null or main.player == null or tab != "ENEMIES" or not sel.has("glyph"):
		return
	var player = main.player
	var at: Vector2 = player.global_position + Vector2(40.0 * player.facing, -4.0)
	var enemy: Node2D = main.spawner.enemy(String(sel["name"]), at)
	if enemy != null:
		main.world.add_child(enemy)
		main.enemies.append(enemy)


func _input(event: InputEvent) -> void:
	if not _active or is_instance_valid(library_palette) or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if _playing:
		if key == KEY_N:
			spawn_picked()
		return
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return
	if event.ctrl_pressed:
		match key:
			KEY_S:
				save()
			KEY_Z:
				if event.shift_pressed:
					_redo()
				else:
					_undo()
			KEY_Y:
				_redo()
			KEY_C:
				_copy_region()
			KEY_X:
				_cut_region()
			KEY_V:
				_paste_clipboard()
			KEY_D:
				_duplicate_region()
			_:
				return
	else:
		match key:
			KEY_TAB:
				play()
			KEY_DELETE:
				_delete_selection()
			KEY_F:
				_fit()
			KEY_V:
				_set_tool("SELECT")
			KEY_B:
				_set_tool("PLACE")
			KEY_M:
				_set_tool("MOVE")
			KEY_E:
				_set_tool("ERASE")
			KEY_S:
				_set_tool("ZONE")
			KEY_P:
				_set_tool("START")
			KEY_R:
				_rotate_prop()
			KEY_BRACKETLEFT:
				_scale_prop(-0.25)
			KEY_BRACKETRIGHT:
				_scale_prop(0.25)
			KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN:
				_framing = false
				var offset := Vector2(int(key == KEY_RIGHT) - int(key == KEY_LEFT), int(key == KEY_DOWN) - int(key == KEY_UP))
				if _selection.has("region"):
					_move_region(Vector2i(offset))
				else:
					_cam += offset * 48.0 / _zoom
					_sync_camera()
			_:
				return
	get_viewport().set_input_as_handled()


func _on_view_input(event: InputEvent) -> void:
	if not _active or _playing:
		return
	if event is InputEventMouseMotion:
		_on_motion(event.position)
	elif event is InputEventMouseButton:
		_on_click(event)
	else:
		return
	_overlay.queue_redraw()
	_view.accept_event()


func _on_motion(at: Vector2) -> void:
	_update_pointer(at)
	if _panning:
		_cam = _cam_from - (at - _pan_from) / _zoom
		_sync_camera()
	elif _selecting_box:
		_update_box_selection()
	elif _zone_drag:
		_set_zone(_hover)
	elif _painting:
		_apply_brush(_hover)


func _update_pointer(at: Vector2) -> void:
	_mouse = at
	_has_mouse = Rect2(Vector2.ZERO, _view.size).has_point(at)
	_hover = _cell_of(_to_world(at))


func _on_click(event: InputEventMouseButton) -> void:
	_update_pointer(event.position)
	var button := event.button_index
	if button in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		if event.pressed:
			_zoom_at(event.position, 1.2 if button == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.2)
		return
	if _panning and button == _pan_button and not event.pressed:
		_panning = false
		return
	var can_pan := button in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT] or (
		button == MOUSE_BUTTON_LEFT and Input.is_physical_key_pressed(KEY_SPACE))
	if can_pan and event.pressed:
		_framing = false
		_panning = true
		_pan_button = button
		_pan_from = event.position
		_cam_from = _cam
		return
	if button != MOUSE_BUTTON_LEFT:
		return
	var at := _to_world(event.position)
	if not event.pressed:
		if _selecting_box:
			_update_box_selection()
		elif _group_drag:
			_move_region(_hover - _group_drag_start)
		elif not _drag.is_empty():
			_drop_move(at)
		_end_pointer_actions()
		return
	if event.shift_pressed:
		_set_tool("SELECT")
		_selecting_box = true
		_box_select_start = _hover
		_update_box_selection()
		return
	if _selection.has("region"):
		var region: Rect2i = _selection["region"]
		if region.has_point(_hover):
			_group_drag = true
			_group_drag_start = _hover
			return
		_selection = {}
		_update_selection()
	match tool:
		"SELECT":
			_selection = _pick_at(at)
			_update_selection()
		"PLACE":
			if sel.has("glyph"):
				_begin_brush()
			else:
				_place_picture(at)
		"ERASE":
			_begin_brush()
		"MOVE":
			_pick_for_move(at)
		"ZONE":
			_zone_start = _hover
			_zone_drag = true
			_set_zone(_hover)
		"START":
			_set_start(_hover)


func _begin_brush() -> void:
	_painting = true
	_last_brush_cell = _hover
	_stroke_snapshot = false
	if tool == "ERASE":
		_erase_at(_to_world(_mouse))
	else:
		_paint(_hover)


func _apply_brush(cell: Vector2i) -> void:
	if tool == "ERASE":
		if cell != _last_brush_cell:
			_erase_at(_to_world(_mouse))
	else:
		var delta := cell - _last_brush_cell
		var steps := maxi(absi(delta.x), absi(delta.y))
		for i in range(1, steps + 1):
			var c := _last_brush_cell + Vector2i((Vector2(delta) * (float(i) / steps)).round())
			_paint(c)
	_last_brush_cell = cell


func _end_pointer_actions() -> void:
	_panning = false
	_painting = false
	_stroke_snapshot = false
	_zone_drag = false
	_selecting_box = false
	_group_drag = false
	_drag = {}


func _set_zone(cell: Vector2i) -> void:
	var low := _zone_start.min(cell)
	var high := _zone_start.max(cell)
	_zone = Rect2i(low, high - low + Vector2i.ONE).intersection(Rect2i(0, 0, doc.width(), doc.height()))
	_zone_on = _zone.has_area()
	_update_spread()


func _on_draw() -> void:
	var pixel_extent: Vector2 = doc.pixel_size()
	var room_rect := Rect2(_to_screen(Vector2.ZERO), pixel_extent * _zoom)
	_overlay.draw_rect(room_rect, Color("#777089"), false, 1.5)
	var first := _cell_of(_cam).max(Vector2i.ZERO)
	var last := (_cell_of(_to_world(_view.size)) + Vector2i.ONE).min(Vector2i(doc.width(), doc.height()))
	var tile_size := TILE * _zoom
	var layout: Array = _art.grid
	for y in range(first.y, last.y):
		for x in range(first.x, mini(last.x, String(layout[y]).length())):
			var rect := Rect2(_to_screen(Vector2(x, y) * TILE), Vector2.ONE * tile_size)
			var glyph: String = layout[y][x]
			if _collisions and glyph in ["#", "B", "|", "%", ":", "=", "v"]:
				var tint := Color("#597eaa") if glyph in ["=", "v"] else Color("#8d69d2")
				_overlay.draw_rect(rect, Color(tint, 0.55))
			if _grid and tile_size >= 5.0:
				_overlay.draw_rect(rect, Color(1.0, 1.0, 1.0, 0.14), false, 1.0)
			_draw_marker(glyph, rect)
	for issue: Dictionary in checks:
		var rect: Rect2 = issue["rect"]
		var screen := Rect2(_to_screen(rect.position), rect.size * _zoom)
		var tint := _issue_color(issue)
		_overlay.draw_rect(screen, Color(tint, 0.12))
		_overlay.draw_rect(screen, tint, false, 2.0 if rect == _issue_focus else 1.0)
	if _zone_on and tool == "ZONE":
		_draw_box(Rect2(Vector2(_zone.position) * TILE, Vector2(_zone.size) * TILE), DESIGN_TINT, 0.18)
	if doc.in_room(_start_cell.x, _start_cell.y):
		var rect := _draw_box(Rect2(Vector2(_start_cell) * TILE, Vector2.ONE * TILE), PLAY_TINT, 0.3)
		_overlay.draw_string(ThemeDB.fallback_font, rect.position + Vector2(3, -5), "PLAY START",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, PLAY_TINT)
	if _selection.has("region"):
		var region: Rect2i = _selection["region"]
		_draw_box(Rect2(Vector2(region.position * TILE), Vector2(region.size * TILE)), DESIGN_TINT, 0.22)
		if _group_drag:
			var target := region.position + _hover - _group_drag_start
			_draw_box(Rect2(Vector2(target * TILE), Vector2(region.size * TILE)), DESIGN_TINT, 0.12)
	elif _selection.has("prop"):
		var picture: Dictionary = doc.props[_selection["prop"]]
		var area := RoomDoc.prop_transform(picture) * Rect2(Vector2.ZERO, EdAssets.size_of(picture["png"]))
		_draw_box(area, DESIGN_TINT, 0.12)
	elif _selection.has("cell"):
		_draw_box(Rect2(Vector2(_selection["cell"]) * TILE, Vector2.ONE * TILE), DESIGN_TINT, 0.12)
	if _has_mouse and not _panning and not _group_drag and not _selecting_box:
		_draw_brush_preview()


func _draw_marker(glyph: String, rect: Rect2) -> void:
	if not _markers.has(glyph):
		if glyph not in [".", "#", "=", "B", "v"]:
			_overlay.draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, rect.size.y * 0.81), glyph,
				HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, maxi(9, int(rect.size.y * 0.75)), Color.WHITE)
		return
	var marker: Dictionary = _markers[glyph]
	var icon: Texture2D = marker["icon"]
	var tint := WARNING_TINT if marker["category"] == "HAZARDS" else DESIGN_TINT
	var radius := clampf(rect.size.x * 0.4, 3.0, 12.0)
	_overlay.draw_circle(rect.get_center(), radius, Color("#1c1625"))
	_overlay.draw_arc(rect.get_center(), radius, 0.0, TAU, 16, tint, 1.3, true)
	if icon != null and rect.size.x >= 8.0:
		var extent := icon.get_size()
		var max_extent := radius * 1.9
		if marker["category"] == "ENEMIES":
			max_extent = maxf(max_extent, minf(rect.size.x * 2.1, 45.0))
		var fitted := extent * (max_extent / maxf(extent.x, extent.y))
		var pos := rect.get_center() - fitted * 0.5
		if marker["category"] == "ENEMIES":
			pos.y = rect.end.y - fitted.y
		_overlay.draw_texture_rect(icon, Rect2(pos, fitted), false, Color.WHITE)


func _draw_brush_preview() -> void:
	if not _drag.is_empty():
		_draw_box(_move_preview(_to_world(_mouse)), DESIGN_TINT, 0.2)
		return
	if not doc.in_room(_hover.x, _hover.y) or tool in ["ZONE", "MOVE"]:
		return
	var color := PLAY_TINT if tool == "START" else ISSUE_TINT if tool == "ERASE" else Color.WHITE
	var area := Rect2(Vector2(_hover) * TILE, Vector2.ONE * TILE)
	if tool == "PLACE" and sel.has("png") and tab != "BACKDROPS":
		var path: String = sel["png"]
		var art := EdAssets.texture(path)
		area = Rect2(_picture_position(_to_world(_mouse), path, tab == "TILES"), EdAssets.size_of(path))
		if art != null:
			_overlay.draw_texture_rect(art, Rect2(_to_screen(area.position), area.size * _zoom), false, Color(1, 1, 1, 0.55))
	var rect := _draw_box(area, color, 0.08)
	if tool == "PLACE" and sel.has("glyph"):
		_draw_marker(String(sel["glyph"]), rect)


func _draw_box(area: Rect2, tint: Color, alpha: float) -> Rect2:
	var rect := Rect2(_to_screen(area.position), area.size * _zoom)
	_overlay.draw_rect(rect, Color(tint, alpha))
	_overlay.draw_rect(rect, tint, false, 1.8)
	return rect


func _exit_tree() -> void:
	if _check_thread != null and _check_thread.is_started():
		_check_thread.wait_to_finish()
