extends CanvasLayer

signal closed

const MetaPatch := preload("res://editor/meta_patch.gd")
const Workspace := preload("res://editor/workspace_shell.gd")
const WorkspaceFiles := preload("res://editor/workspace_files.gd")
const EdHelp := preload("res://editor/ed_help.gd")
const EdThumbs := preload("res://editor/ed_thumbs.gd")
const RoomScript := preload("res://room.gd")
const SHEETS := ["before", "after", "restored"]
const META_FILE := "data/rooms_meta.json"
const ACCENT := Color("#afccfa")
const WARNING := Color("#f2b674")
const ERROR := Color("#ff9696")

var sheet := "before"
var picked := ""
var warnings: Array = []
var data: Dictionary = {}

var _orig: Dictionary = {}
var _source := ""
var _path := ""
var _had_file := false
var _msg := ""
var _undo: Array = []
var _redo: Array = []
var _cameras: Dictionary = {}
var _view_size := Vector2.ZERO
var _cam := Vector2.ZERO
var _zoom := 12.0
var _gesture: Dictionary = {}
var _workspace: Control
var _view: Control
var _search: LineEdit
var _list: ItemList
var _room_count: Label
var _room_title: Label
var _room_hint: Label
var _issue_title: Label
var _issue_detail: Label
var _issue_list: VBoxContainer
var _status: Label
var _zoom_label: Label
var _overlap: PanelContainer
var _edit_button: Button
var _play_button: Button
var _save_button: Button
var _undo_button: Button
var _redo_button: Button
var _sheet_buttons: Array[Button] = []
var _fields: Array[SpinBox] = []


func _ready() -> void:
	layer = 101


## Load the map draft once. Sheet switches and opening rooms leave the draft intact.
func begin(info: Dictionary) -> void:
	_load()
	var initial_sheet := String(info.get("sheet", W.sheet))
	if SHEETS.has(initial_sheet) and data.get("sheets", {}).has(initial_sheet):
		sheet = initial_sheet
	var room := String(info.get("room", ""))
	if not _rooms().has(room):
		room = String(info.get("file_id", ""))
	if _rooms().has(room):
		picked = room
	_build_ui()
	_refresh_rooms()
	_recheck()
	_fit.call_deferred()


func set_active(active: bool) -> void:
	visible = active
	set_process_unhandled_key_input(active)
	if not active:
		_cancel_gesture()
		_hide_overlap()


# Map documents

func _load() -> void:
	var root: String = Dev.project_dir()
	if root != "":
		_path = root.path_join(META_FILE)
		_had_file = FileAccess.file_exists(_path)
	_source = WorkspaceFiles.read(_path) if _had_file else WorkspaceFiles.read("res://" + META_FILE)
	data = _parse_map(_source)
	_orig = data.duplicate(true)
	if data.is_empty():
		_msg = "Could not read the map. Check %s and reopen the workspace." % META_FILE


func _parse_map(contents: String) -> Dictionary:
	var parsed = JSON.parse_string(contents)
	if not parsed is Dictionary or not parsed.get("sheets") is Dictionary:
		return {}
	var sheets: Dictionary = parsed["sheets"]
	for era in SHEETS:
		if not sheets.get(era) is Dictionary:
			return {}
		var rooms: Dictionary = sheets[era]
		if era == "restored":
			if not rooms.get("add") is Dictionary or not ["before", "after"].has(String(rooms.get("base", "before"))):
				return {}
			rooms = rooms["add"]
		for room in rooms.values():
			if not room is Dictionary or not room.get("cell") is Array or room["cell"].size() != 4:
				return {}
			var index := 0
			for value in room["cell"]:
				if not (value is float or value is int) or int(value) != value or value < (0 if index < 2 else 1):
					return {}
				index += 1
			if not room.get("exits", []) is Array:
				return {}
			for exit in room.get("exits", []):
				if not exit is Dictionary:
					return {}
	return parsed


## Get visible rooms, including inherited rooms on the Restored sheet.
func _rooms(which := "") -> Dictionary:
	var era := sheet if which == "" else which
	var sheets: Dictionary = data.get("sheets", {})
	var page: Dictionary = sheets.get(era, {})
	if era != "restored":
		return page
	var base: Dictionary = sheets.get(String(page.get("base", "before")), {})
	var inherited := base.duplicate()
	inherited.merge(page.get("add", {}), true)
	return inherited


func _home(id: String) -> String:
	if sheet != "restored":
		return sheet
	var restored: Dictionary = data.get("sheets", {}).get("restored", {})
	return "restored" if restored.get("add", {}).has(id) else String(restored.get("base", "before"))


func _stored_rooms(model: Dictionary, era: String) -> Dictionary:
	var page: Dictionary = model.get("sheets", {}).get(era, {})
	return page.get("add", {}) if era == "restored" else page


func _cell_from(model: Dictionary, era: String, id: String) -> Array:
	return _stored_rooms(model, era).get(id, {}).get("cell", [])


func _rect(id: String) -> Rect2:
	return _cell_rect(_rooms()[id]["cell"])


func _cell_rect(cell: Array) -> Rect2:
	return Rect2(float(cell[0]), float(cell[1]), float(cell[2]), float(cell[3]))


func _same_cell(a: Array, b: Array) -> bool:
	if a.size() != 4 or b.size() != 4:
		return false
	for i in 4:
		if int(a[i]) != int(b[i]):
			return false
	return true


func is_dirty() -> bool:
	return not changed_rooms().is_empty()


## List the cells changed from disk as [home era, room ID, cell].
func changed_rooms() -> Array:
	var changes: Array = []
	for era in SHEETS:
		var rooms := _stored_rooms(data, era)
		for id in rooms:
			if not _same_cell(rooms[id]["cell"], _cell_from(_orig, era, id)):
				changes.append([era, id, rooms[id]["cell"]])
	return changes


## Save a checked patch to the project file. External edits to other rooms are kept.
func save() -> bool:
	var changes := changed_rooms()
	if changes.is_empty():
		_say("No map changes to save.")
		return true
	if _path == "":
		_say("Choose a writable project folder before saving the map.")
		return false
	var disk: Variant = null
	if FileAccess.file_exists(_path):
		disk = WorkspaceFiles.read(_path)
	elif _had_file:
		_say("The map file was removed outside the builder. Restore it, then try again.")
		return false
	var latest := _source if disk == null else String(disk)
	var next_model := _parse_map(latest)
	if next_model.is_empty():
		_say("The map file is unreadable. Fix it on disk and try saving again.")
		return false
	for change in changes:
		var era := String(change[0])
		var id := String(change[1])
		var cell := _cell_from(next_model, era, id)
		if not _same_cell(cell, _cell_from(_orig, era, id)) and not _same_cell(cell, change[2]):
			_say("%s was changed outside the builder. Your draft is still open." % _name_for(id))
			return false
		_stored_rooms(next_model, era)[id]["cell"] = change[2].map(func(value): return float(value))
	var patched := MetaPatch.set_cells(latest, changes)
	var checked := _parse_map(patched)
	if checked.is_empty() or checked != next_model:
		_say("Could not locate the changed cells in the map file. Your draft is still open.")
		return false
	var problem := WorkspaceFiles.commit({_path: patched}, {_path: disk})
	if problem != "":
		_say(problem)
		return false
	if latest != _source:
		_undo.clear()
		_redo.clear()
	_had_file = true
	_source = patched
	data = checked
	_orig = data.duplicate(true)
	var live: Dictionary = Db.table("rooms_meta")
	for change in changes:
		var rooms := _stored_rooms(live, String(change[0]))
		if rooms.has(change[1]):
			rooms[change[1]]["cell"] = change[2].duplicate()
	if not _rooms().has(picked):
		picked = ""
	_refresh_rooms()
	_recheck()
	_say("Saved %d room changes to %s." % [changes.size(), META_FILE])
	return true


# Editing and navigation

func select(id: String) -> void:
	picked = id if _rooms().has(id) else ""
	_issue_detail.text = ""
	if not _search.text.is_empty() and picked != "" and not _visible_in_list(picked):
		_search.text = ""
		_refresh_rooms()
	else:
		_refresh_selection()
	_refresh_issues()
	_view.queue_redraw()


func set_sheet(which: String) -> void:
	if which == sheet or not SHEETS.has(which) or not data.get("sheets", {}).has(which):
		return
	_cancel_gesture()
	_hide_overlap()
	_cameras[sheet] = [_cam, _zoom]
	sheet = which
	picked = _era_counterpart(picked)
	if _cameras.has(sheet):
		_cam = _cameras[sheet][0]
		_zoom = _cameras[sheet][1]
		_refresh_zoom()
	else:
		_fit()
	_refresh_rooms()
	_recheck()


func _era_counterpart(id: String) -> String:
	var rooms := _rooms()
	if rooms.has(id):
		return id
	var base := id.trim_suffix("_shift").trim_suffix("_restored")
	var suffix := "_shift" if sheet == "after" else "_restored" if sheet == "restored" else ""
	if rooms.has(base + suffix):
		return base + suffix
	return base if rooms.has(base) else ""


func _editable() -> bool:
	return picked != "" and _home(picked) == sheet


## Move the current room in map cells.
func nudge(dx: int, dy: int) -> bool:
	return _edit([dx, dy, 0, 0])


## Adjust the current room's map footprint.
func resize_by(dw: int, dh: int) -> bool:
	return _edit([0, 0, dw, dh])


func _edit(delta: Array) -> bool:
	if not _editable():
		return false
	var cell: Array = _rooms()[picked]["cell"]
	var next: Array = []
	for i in 4:
		next.append(maxi(0 if i < 2 else 1, int(cell[i]) + int(delta[i])))
	return _apply_cell(next)


func _apply_cell(next: Array) -> bool:
	if not _editable():
		return false
	var room: Dictionary = _rooms()[picked]
	if _same_cell(next, room["cell"]):
		return false
	_record_edit(_home(picked), picked, room["cell"], next)
	room["cell"] = next
	_msg = ""
	_recheck()
	return true


func _record_edit(era: String, id: String, previous: Array, next: Array) -> void:
	_undo.append([era, id, previous.duplicate(), next.duplicate()])
	_redo.clear()


func undo() -> void:
	_apply_history(_undo, _redo, 2)


func redo() -> void:
	_apply_history(_redo, _undo, 3)


func _apply_history(from: Array, to: Array, value_index: int) -> void:
	_cancel_gesture()
	if from.is_empty():
		return
	var step: Array = from.pop_back()
	_stored_rooms(data, String(step[0]))[step[1]]["cell"] = step[value_index].duplicate()
	to.append(step)
	_msg = ""
	_recheck()


func open_in_room_builder() -> void:
	if picked != "" and Dev.open_room_editor(picked, sheet) == null:
		_say("Could not open the %s room file in %s." % [_name_for(picked), sheet.capitalize()])


func teleport() -> void:
	if picked != "" and not Dev.play_map_room(picked, sheet):
		_say("Could not start a playtest for %s in %s." % [_name_for(picked), sheet.capitalize()])


# Workspace controls

func _map_button(parent: Container, label: String, action: Callable, tip: String, id: String) -> Button:
	var key := "map." + id
	if not EdHelp.has(key):
		EdHelp.entries[key] = {"title": label, "what": tip}
	var button := Workspace.button(parent, label, action, tip, key)
	var help := parent.get_child(button.get_index() + 1) as Button
	help.custom_minimum_size.x = 22
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := help.get_theme_stylebox(state).duplicate() as StyleBox
		style.content_margin_left = 4
		style.content_margin_right = 4
		help.add_theme_stylebox_override(state, style)
	return button


func _build_ui() -> void:
	_workspace = Workspace.mount(self)
	var padding := MarginContainer.new()
	for edge in ["left", "top", "right", "bottom"]:
		padding.add_theme_constant_override("margin_" + edge, 16)
	_workspace.add_child(padding)
	padding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	padding.add_child(layout)
	var bar := HBoxContainer.new()
	layout.add_child(bar)
	var map_tab := _map_button(bar, "Map", func(): pass, "Shows that the map builder is open.", "map")
	map_tab.toggle_mode = true
	map_tab.set_pressed_no_signal(true)
	map_tab.disabled = true
	_edit_button = _map_button(bar, "Edit Room", open_in_room_builder, "Open the selected room in F2 (Enter)", "edit")
	_play_button = _map_button(bar, "Play Here", teleport, "Playtest the selected room (T)", "play")
	bar.add_spacer(false)
	_undo_button = _map_button(bar, "Undo", undo, "Undo the last map edit (Ctrl+Z)", "undo")
	_redo_button = _map_button(bar, "Redo", redo, "Redo the last undone map edit (Ctrl+Y)", "redo")
	_save_button = _map_button(bar, "Save Map", func(): save(), "Save the room positions and sizes on the map (Ctrl+S)", "save")
	_map_button(bar, "Close", Dev.request_close, "Close both builders", "close")

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	layout.add_child(body)
	_build_room_list(body)
	_build_map_area(body)
	_build_inspector(body)

	_status = Label.new()
	_status.custom_minimum_size.y = 24
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_status)


func _build_room_list(body: HBoxContainer) -> void:
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 228
	sidebar.add_theme_constant_override("separation", 8)
	body.add_child(sidebar)
	_heading(sidebar, "Rooms")
	_search = LineEdit.new()
	_search.placeholder_text = "Search name or code"
	_search.clear_button_enabled = true
	_search.text_changed.connect(func(_query: String): _refresh_rooms())
	sidebar.add_child(_search)
	_list = ItemList.new()
	_list.fixed_icon_size = Vector2i(56, 30)
	_list.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_select_list_room)
	_list.item_activated.connect(func(_index: int): open_in_room_builder())
	sidebar.add_child(_list)
	_room_count = _heading(sidebar, "", 14)


func _build_map_area(body: HBoxContainer) -> void:
	var area := VBoxContainer.new()
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_theme_constant_override("separation", 8)
	body.add_child(area)
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 5)
	area.add_child(tools)
	var group := ButtonGroup.new()
	for era in SHEETS:
		var tab := _map_button(tools, String(era).capitalize(), set_sheet.bind(era), "Show rooms on the %s map." % era, "sheet." + era)
		tab.toggle_mode = true
		tab.button_group = group
		_sheet_buttons.append(tab)
	tools.add_spacer(false)
	_map_button(tools, "−", func(): _zoom_at(_view.size * 0.5, 0.8), "Zoom out to see more rooms.", "zoom_out")
	_zoom_label = _heading(tools, "", 14)
	_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zoom_label.custom_minimum_size.x = 48
	_map_button(tools, "+", func(): _zoom_at(_view.size * 0.5, 1.25), "Zoom in to see the rooms in more detail.", "zoom_in")
	_map_button(tools, "Fit", _fit, "Fit all rooms in view", "fit")
	_map_button(tools, "Center", _center_room, "Center the selected room", "center")
	_view = Control.new()
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_view.clip_contents = true
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.gui_input.connect(_on_view_input)
	_view.draw.connect(_on_draw)
	_view.resized.connect(_on_resize)
	area.add_child(_view)
	var hint := _heading(area, "Drag to move   ·   Drag corner to resize   ·   Wheel to zoom   ·   Middle drag to pan", 13)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _build_inspector(body: HBoxContainer) -> void:
	var details := VBoxContainer.new()
	details.custom_minimum_size.x = 260
	details.add_theme_constant_override("separation", 8)
	body.add_child(details)
	_room_title = _heading(details, "No room selected")
	_room_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_room_hint = _heading(details, "", 14)
	_room_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var grid := GridContainer.new()
	grid.columns = 2
	details.add_child(grid)
	for i in 4:
		var field := VBoxContainer.new()
		field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(field)
		_heading(field, ["Map X", "Map Y", "Width (cells)", "Height (cells)"][i], 14)
		var box := SpinBox.new()
		box.min_value = 0 if i < 2 else 1
		box.max_value = 9999
		box.allow_greater = true
		box.get_line_edit().select_all_on_focus = true
		box.value_changed.connect(_change_field.bind(i))
		field.add_child(box)
		_fields.append(box)
	details.add_child(HSeparator.new())
	_issue_title = _heading(details, "Issues")
	var issue_scroll := ScrollContainer.new()
	issue_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	issue_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.add_child(issue_scroll)
	_issue_list = VBoxContainer.new()
	_issue_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	issue_scroll.add_child(_issue_list)
	_issue_detail = _heading(details, "", 14)
	_issue_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _heading(parent: Container, caption: String, size := 19) -> Label:
	var label := Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label


func _name_for(id: String) -> String:
	return String(_rooms().get(id, {}).get("title", id)).capitalize()


func _refresh_rooms() -> void:
	var query := _search.text.strip_edges().to_lower()
	var rooms := _rooms()
	var ids := rooms.keys()
	ids.sort_custom(func(a, b): return _name_for(a).naturalnocasecmp_to(_name_for(b)) < 0)
	_list.clear()
	for id in ids:
		var title := _name_for(id)
		var code := String(rooms[id].get("code", id))
		if not query.is_empty() and not ("%s %s %s" % [title, code, id]).to_lower().contains(query):
			continue
		var file_id := Dev.room_file_id(String(id), sheet)
		var preview := EdThumbs.room(RoomScript.read_room_file(file_id))
		var i := _list.add_item(title, preview)
		_list.set_item_metadata(i, id)
		_list.set_item_tooltip(i, "%s (%s)" % [title, code])
	_room_count.text = "%d rooms" % ids.size() if _list.item_count == ids.size() else "%d of %d rooms" % [_list.item_count, ids.size()]
	_refresh_selection()


func _select_list_room(index: int) -> void:
	select(String(_list.get_item_metadata(index)))
	var view_rect := Rect2(Vector2.ZERO, _view.size).grow(-20)
	var room_rect := _rect(picked)
	if not view_rect.encloses(Rect2(_to_screen(room_rect.position), room_rect.size * _zoom)):
		_center_room()


func _visible_in_list(id: String) -> bool:
	for i in _list.item_count:
		if _list.get_item_metadata(i) == id:
			return true
	return false


func _change_field(value: float, index: int) -> void:
	if not _editable():
		return
	var next: Array = _rooms()[picked]["cell"].duplicate()
	next[index] = int(value)
	if _apply_cell(next):
		_center_room()


func _refresh_selection() -> void:
	var has_room := picked != ""
	var room: Dictionary = _rooms().get(picked, {})
	_room_title.text = _name_for(picked) if has_room else "No room selected"
	_room_hint.text = "Choose a room by name or click it on the map."
	if has_room:
		var code := String(room.get("code", picked))
		_room_hint.text = "%s · %s era" % [code, sheet.capitalize()]
		if not _editable():
			_room_hint.text += "\nEdit its footprint in %s." % _home(picked).capitalize()
	_edit_button.disabled = not has_room
	_play_button.disabled = not has_room
	for i in 4:
		_fields[i].editable = _editable()
		_fields[i].set_value_no_signal(room["cell"][i] if has_room else _fields[i].min_value)
	_list.deselect_all()
	for i in _list.item_count:
		if _list.get_item_metadata(i) == picked:
			_list.select(i)
			_list.ensure_current_is_visible()
			break
	for i in SHEETS.size():
		_sheet_buttons[i].set_pressed_no_signal(sheet == SHEETS[i])
	_save_button.disabled = not is_dirty()
	_undo_button.disabled = _undo.is_empty()
	_redo_button.disabled = _redo.is_empty()
	if _status != null:
		var state := "Map unavailable" if data.is_empty() else "Unsaved map changes" if is_dirty() else "Map saved"
		_status.text = state if _msg == "" else ("%s   ·   %s" % [state, _msg] if is_dirty() else _msg)


func _say(message: String) -> void:
	_msg = message
	_refresh_selection()


func _recheck() -> void:
	warnings.clear()
	var rooms := _rooms()
	var ids := rooms.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var left: String = ids[i]
			var right: String = ids[j]
			if _cell_rect(rooms[left]["cell"]).intersects(_cell_rect(rooms[right]["cell"])):
				warnings.append({"id": left, "other": right, "kind": "Overlap", "text": "%s overlaps %s" % [left, right]})
				warnings.append({"id": right, "other": left, "kind": "Overlap", "text": "%s overlaps %s" % [right, left]})
	for id in ids:
		for exit in rooms[id].get("exits", []):
			var to := String(exit.get("to", ""))
			var kind := String(exit.get("kind", ""))
			if to == "" and kind != "bricked":
				warnings.append({"id": id, "kind": "Broken exit", "text": "%s has an exit that leads nowhere." % _name_for(id)})
			elif to != "" and not rooms.has(to):
				warnings.append({"id": id, "kind": "Missing room", "text": "%s has an exit to %s, which is absent from this era." % [_name_for(id), to]})
			elif kind == "door" and to != "" and not rooms[to].get("exits", []).any(func(e): return e.get("to", "") == id):
				warnings.append({"id": id, "kind": "One-way door", "text": "%s leads to %s, with no return exit." % [_name_for(id), _name_for(to)]})
	_refresh_selection()
	_refresh_issues()
	_view.queue_redraw()


func _refresh_issues() -> void:
	for child in _issue_list.get_children():
		_issue_list.remove_child(child)
		child.queue_free()
	_issue_detail.text = ""
	var displayed := 0
	var rooms := _rooms()
	for issue in warnings:
		if issue.has("other") and (issue["other"] == picked or (issue["id"] != picked and String(issue["other"]) < String(issue["id"]))):
			continue
		var caption := "%s · %s" % [issue["kind"], _name_for(issue["id"])]
		if issue.has("other"):
			var left: String = rooms[issue["id"]].get("code", issue["id"])
			var right: String = rooms[issue["other"]].get("code", issue["other"])
			caption = "Overlap · %s and %s" % [left, right]
		var row := HBoxContainer.new()
		_issue_list.add_child(row)
		var button := _map_button(row, caption, _focus_issue.bind(issue), "Jump to this map issue.", "issue")
		button.tooltip_text = _issue_text(issue)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		displayed += 1
	_issue_title.text = "Issues (%d)" % displayed
	if displayed == 0:
		_heading(_issue_list, "No map issues on this era.", 14)


func _issue_text(issue: Dictionary) -> String:
	if issue.has("other"):
		return "%s overlaps %s." % [_name_for(issue["id"]), _name_for(issue["other"])]
	return issue["text"]


func _focus_issue(issue: Dictionary) -> void:
	select(issue["id"])
	_center_room()
	_issue_detail.text = _issue_text(issue)


# Map camera and input

func _on_resize() -> void:
	if _view_size == Vector2.ZERO:
		_fit()
	else:
		_cam += (_view_size - _view.size) / (2 * _zoom)
		_view.queue_redraw()
	_view_size = _view.size


func _fit() -> void:
	var rooms := _rooms()
	if rooms.is_empty() or _view.size.x <= 4 or _view.size.y <= 4:
		return
	var box := _cell_rect(rooms.values()[0]["cell"])
	for room in rooms.values():
		box = box.merge(_cell_rect(room["cell"]))
	var avail := (_view.size - Vector2(68, 68)).max(Vector2(4, 4))
	_zoom = minf(minf(avail.x / box.size.x, avail.y / box.size.y), 56.0)
	_cam = box.get_center() - _view.size / (2 * _zoom)
	_refresh_zoom()


func _center_room() -> void:
	if picked != "":
		_cam = _rect(picked).get_center() - _view.size / (2 * _zoom)
		_view.queue_redraw()


func _to_cell(p: Vector2) -> Vector2:
	return p / _zoom + _cam


func _to_screen(c: Vector2) -> Vector2:
	return (c - _cam) * _zoom


func _zoom_at(p: Vector2, factor: float) -> void:
	var cell := _to_cell(p)
	_zoom = clampf(_zoom * factor, minf(_zoom, 0.04), 100.0)
	_cam = cell - p / _zoom
	_refresh_zoom()


func _refresh_zoom() -> void:
	_zoom_label.text = "%d%%" % roundi(_zoom * 100.0 / 16.0)
	_view.queue_redraw()


func _rooms_at(p: Vector2) -> Array[String]:
	var hits: Array[String] = []
	var cell := _to_cell(p)
	var rooms := _rooms()
	for id in rooms:
		if _cell_rect(rooms[id]["cell"]).has_point(cell):
			hits.append(id)
	if not hits.is_empty():
		return hits
	var stacks := _stacks(rooms)
	for rect in stacks:
		var ids: Array = stacks[rect]
		if ids.size() > 1:
			if _badge_rect(_stack_badge_position(rect), "×%d" % ids.size()).has_point(p):
				hits.assign(ids)
				break
		else:
			var screen := _screen_rect(rect)
			var id: String = ids[0]
			var code := String(rooms[id].get("code", id))
			if _uses_badge(screen) and _badge_rect(screen.position - Vector2(2, 17), code).has_point(p):
				hits.append(id)
				break
	return hits


func _stacks(rooms: Dictionary) -> Dictionary:
	var groups := {}
	for id in rooms:
		var rect := _cell_rect(rooms[id]["cell"])
		if not groups.has(rect):
			groups[rect] = []
		groups[rect].append(id)
	return groups


func _screen_rect(rect: Rect2) -> Rect2:
	return Rect2(_to_screen(rect.position), rect.size * _zoom)


func _stack_badge_position(rect: Rect2) -> Vector2:
	return _to_screen(rect.position + Vector2(rect.size.x, 0)) + Vector2(5, 1)


func _handle_rect() -> Rect2:
	var corner := _to_screen(_rect(picked).end)
	return Rect2(corner - Vector2(6, 6), Vector2(12, 12))


func _has_handle() -> bool:
	if not _editable():
		return false
	var size := _rect(picked).size * _zoom
	return minf(size.x, size.y) >= 18.0


func _on_view_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		if _gesture.is_empty():
			_update_map_tooltip(event.position)
		else:
			_drag_to(event.position)


func _update_map_tooltip(point: Vector2) -> void:
	if _has_handle() and _handle_rect().has_point(point):
		_view.tooltip_text = "Drag to resize " + _name_for(picked)
		return
	var hits := _rooms_at(point)
	var names := PackedStringArray()
	for id in hits:
		names.append(_name_for(id))
	_view.tooltip_text = "\n".join(names)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	var button := event.button_index
	if button == MOUSE_BUTTON_WHEEL_UP or button == MOUSE_BUTTON_WHEEL_DOWN:
		if event.pressed and _gesture.is_empty():
			_hide_overlap()
			_zoom_at(event.position, 1.2 if button == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.2)
		_view.accept_event()
		return
	if not event.pressed:
		if _gesture.get("button") == button:
			_end_gesture(event.position)
		return
	_hide_overlap()
	if button == MOUSE_BUTTON_MIDDLE or button == MOUSE_BUTTON_RIGHT or (button == MOUSE_BUTTON_LEFT and Input.is_key_pressed(KEY_SPACE)):
		_gesture = {"mode": "pan", "button": button, "start": event.position, "cam": _cam}
	elif button == MOUSE_BUTTON_LEFT:
		_begin_selection(event.position)


func _begin_selection(point: Vector2) -> void:
	var hits := _rooms_at(point)
	if _has_handle() and _handle_rect().has_point(point):
		_begin_placement("size", point, [])
	elif hits.size() > 1:
		if hits.has(picked) and _editable():
			_begin_placement("move", point, hits)
		else:
			_show_overlap(point, hits)
	elif hits.size() == 1:
		select(hits[0])
		if _editable():
			_begin_placement("move", point, [])
	else:
		select("")


func _begin_placement(mode: String, point: Vector2, hits: Array) -> void:
	_gesture = {"mode": mode, "button": MOUSE_BUTTON_LEFT, "start": point, "hits": hits,
		"id": picked, "era": _home(picked), "cell": _rooms()[picked]["cell"].duplicate()}


func _drag_to(point: Vector2) -> void:
	var shift: Vector2 = point - _gesture["start"]
	if _gesture["mode"] == "pan":
		_cam = _gesture["cam"] - shift / _zoom
		_view.queue_redraw()
		return
	var delta := Vector2i((shift / _zoom).round())
	var cell: Array = _gesture["cell"]
	var next := cell.duplicate()
	if _gesture["mode"] == "move":
		next[0] = maxi(0, int(cell[0]) + delta.x)
		next[1] = maxi(0, int(cell[1]) + delta.y)
	else:
		next[2] = maxi(1, int(cell[2]) + delta.x)
		next[3] = maxi(1, int(cell[3]) + delta.y)
	var room: Dictionary = _stored_rooms(data, _gesture["era"])[_gesture["id"]]
	if not _same_cell(room["cell"], next):
		room["cell"] = next
		_msg = ""
		_recheck()


func _end_gesture(point: Vector2) -> void:
	var drag := _gesture
	_gesture = {}
	if drag["mode"] == "pan":
		return
	var cell := _cell_from(data, drag["era"], drag["id"])
	if not _same_cell(cell, drag["cell"]):
		_record_edit(drag["era"], drag["id"], drag["cell"], cell)
		_refresh_selection()
	elif not drag["hits"].is_empty():
		_show_overlap(point, drag["hits"])


func _cancel_gesture() -> void:
	if _gesture.is_empty():
		return
	var drag := _gesture
	_gesture = {}
	if drag["mode"] != "pan":
		_stored_rooms(data, drag["era"])[drag["id"]]["cell"] = drag["cell"]
		_recheck()


func _show_overlap(point: Vector2, ids: Array) -> void:
	_overlap = PanelContainer.new()
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("#20293b")
	surface.border_color = ACCENT
	surface.set_border_width_all(1)
	surface.set_corner_radius_all(6)
	for edge in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		surface.set_content_margin(edge, 8)
	_overlap.add_theme_stylebox_override("panel", surface)
	_view.add_child(_overlap)
	var rows := VBoxContainer.new()
	_overlap.add_child(rows)
	_heading(rows, "Rooms at this position", 16)
	for id in ids:
		var room: Dictionary = _rooms()[id]
		var caption := "%s (%s)" % [_name_for(id), room.get("code", id)]
		var row := HBoxContainer.new()
		rows.add_child(row)
		_map_button(row, caption, _choose_overlap.bind(id), "Pick this room from the rooms at this spot.", "overlap_room")
	var cancel_row := HBoxContainer.new()
	rows.add_child(cancel_row)
	_map_button(cancel_row, "Cancel", _hide_overlap, "Close this list and keep the current room selected.", "overlap_cancel")
	_position_overlap.call_deferred(point)


func _position_overlap(point: Vector2) -> void:
	if is_instance_valid(_overlap):
		var available := (_view.size - _overlap.get_combined_minimum_size()).max(Vector2.ZERO)
		_overlap.position = point.clamp(Vector2.ZERO, available)


func _choose_overlap(id: String) -> void:
	select(id)
	_hide_overlap()


func _hide_overlap() -> void:
	if is_instance_valid(_overlap):
		_overlap.hide()
		_overlap.queue_free()
		_overlap = null


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not visible or key == null or not key.pressed or key.echo:
		return
	var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
	if key.ctrl_pressed:
		match code:
			KEY_S: save()
			KEY_Z:
				if key.shift_pressed:
					redo()
				else:
					undo()
			KEY_Y: redo()
			_: return
	else:
		match code:
			KEY_ENTER, KEY_KP_ENTER: open_in_room_builder()
			KEY_T: teleport()
			KEY_1, KEY_2, KEY_3: set_sheet(SHEETS[code - KEY_1])
			KEY_ESCAPE:
				if not _gesture.is_empty():
					_cancel_gesture()
				elif is_instance_valid(_overlap):
					_hide_overlap()
				else:
					Dev.request_close()
			KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN:
				var delta := Vector2i(int(code == KEY_RIGHT) - int(code == KEY_LEFT), int(code == KEY_DOWN) - int(code == KEY_UP))
				if key.alt_pressed:
					nudge(delta.x, delta.y)
				elif key.shift_pressed:
					resize_by(delta.x, delta.y)
				else:
					_cam += Vector2(delta) * 4.0
					_view.queue_redraw()
			_: return
	get_viewport().set_input_as_handled()


# Map rendering

func _on_draw() -> void:
	_view.draw_rect(Rect2(Vector2.ZERO, _view.size), Color("#141c2b"))
	_draw_grid()
	var rooms := _rooms()
	var room_issues := {}
	for issue in warnings:
		var id: String = issue["id"]
		var advisory: bool = issue["kind"] in ["Overlap", "One-way door"]
		if not room_issues.has(id) or not advisory:
			room_issues[id] = WARNING if advisory else ERROR
	var stacks := _stacks(rooms)
	if picked != "":
		var origin := _to_screen(_rect(picked).get_center())
		for exit in rooms[picked].get("exits", []):
			var to := String(exit.get("to", ""))
			if rooms.has(to):
				_view.draw_line(origin, _to_screen(_rect(to).get_center()), Color(ACCENT, 0.42), 1.5, true)
	for id in rooms:
		if id != picked:
			var solo: bool = stacks[_cell_rect(rooms[id]["cell"])].size() == 1
			_draw_room(id, rooms[id], room_issues.get(id, Color.TRANSPARENT), solo)
	if picked != "":
		var solo: bool = stacks[_cell_rect(rooms[picked]["cell"])].size() == 1
		_draw_room(picked, rooms[picked], room_issues.get(picked, Color.TRANSPARENT), solo)
		if _has_handle():
			_view.draw_rect(_handle_rect(), ACCENT)
	for rect in stacks:
		var count: int = stacks[rect].size()
		if count > 1:
			_draw_badge(_stack_badge_position(rect), "×%d" % count, WARNING)


func _draw_grid() -> void:
	var step := maxi(1, ceili(22.0 / _zoom))
	var spacing := float(step) * _zoom
	var origin := Vector2(fposmod(-_cam.x * _zoom, spacing), fposmod(-_cam.y * _zoom, spacing))
	var line := Color(0.55, 0.64, 0.8, 0.10)
	for i in ceili(_view.size.x / spacing):
		var x := origin.x + i * spacing
		_view.draw_line(Vector2(x, 0), Vector2(x, _view.size.y), line)
	for i in ceili(_view.size.y / spacing):
		var y := origin.y + i * spacing
		_view.draw_line(Vector2(0, y), Vector2(_view.size.x, y), line)


func _draw_room(id: String, room: Dictionary, issue_color: Color, show_label: bool) -> void:
	var rect := _cell_rect(room["cell"])
	var screen := _screen_rect(rect)
	var fill := Color("#33496f")
	if String(room.get("boss", "")) != "":
		fill = Color("#593c63")
	elif room.get("save", false):
		fill = Color("#30534f")
	elif sheet == "restored" and _home(id) != "restored":
		fill = fill.darkened(0.25)
	if id == picked:
		fill = Color("#5174a2")
	_view.draw_rect(screen, fill)
	var outline := ACCENT if id == picked else Color("#8196b5")
	if issue_color != Color.TRANSPARENT and id != picked:
		outline = issue_color
	_view.draw_rect(screen, outline, false, 2.5 if id == picked else 1.25)
	if id == picked and issue_color != Color.TRANSPARENT:
		_view.draw_circle(screen.position + Vector2(3, 3), 4.0, issue_color)
	for exit in room.get("exits", []):
		_draw_exit(rect, exit)
	if show_label:
		var code := String(room.get("code", id))
		if not _uses_badge(screen):
			var baseline := screen.get_center().y + 4
			_view.draw_string(ThemeDB.fallback_font, Vector2(screen.position.x, baseline), code, HORIZONTAL_ALIGNMENT_CENTER, screen.size.x, 13, Color("#f4f7ff"))
		else:
			_draw_badge(screen.position - Vector2(2, 17), code, Color("#e0e8f7"))


func _draw_badge(at: Vector2, caption: String, color: Color) -> void:
	_view.draw_rect(_badge_rect(at, caption), Color("#232c3e"))
	_view.draw_string(ThemeDB.fallback_font, at + Vector2(3, 12), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)


func _uses_badge(screen: Rect2) -> bool:
	return screen.size.x < 26 or screen.size.y < 18


func _badge_rect(at: Vector2, caption: String) -> Rect2:
	var font := ThemeDB.fallback_font
	var size := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	return Rect2(at, Vector2(size.x + 6, 15))


func _draw_exit(rect: Rect2, exit: Dictionary) -> void:
	var at := float(exit.get("at", 0)) + 0.5
	var side := String(exit.get("side", ""))
	var center := rect.position
	var direction := Vector2.RIGHT
	match side:
		"L": center += Vector2(0, clampf(at, 0.5, rect.size.y - 0.5))
		"R": center += Vector2(rect.size.x, clampf(at, 0.5, rect.size.y - 0.5))
		"U":
			center += Vector2(clampf(at, 0.5, rect.size.x - 0.5), 0)
			direction = Vector2.DOWN
		"D":
			center += Vector2(clampf(at, 0.5, rect.size.x - 0.5), rect.size.y)
			direction = Vector2.DOWN
		_: return
	var p := _to_screen(center)
	var color := Color("#6d788e") if exit.get("kind", "") == "bricked" else Color("#d4deed")
	_view.draw_line(p - direction * 3.5, p + direction * 3.5, color, 2.0, true)
