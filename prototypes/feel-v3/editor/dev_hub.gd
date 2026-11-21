# Desktop-only developer workspace and screenshot notes.
extends Node

const WorkspaceShell := preload("res://editor/workspace_shell.gd")
const EdHelp := preload("res://editor/ed_help.gd")
const TOOLS := {
	KEY_F2: ["dev_room", "res://editor/room_builder.gd"],
	KEY_F3: ["dev_map", "res://editor/map_builder.gd"],
	KEY_F4: ["dev_notes", "res://editor/note_tool.gd"],
}
const MAP := "dev_map"
const ROOM := "dev_room"
const NOTES := "dev_notes"

var god := false
var notes_dir_override := ""
var project_dir_override := ""
var tool: Node
var tool_action := ""

var _builders: Dictionary = {}
var _touch_was_blocked := false
var _accept_quit := true
var _previous_scale := 1.0
var _previous_hitboxes := 0.0
var _linked_project := ""
var _close_dialog: ConfirmationDialog
var _play_bar: CanvasLayer
var _play_snapshot: Dictionary = {}
var _launcher: CanvasLayer
var _studio_layer: CanvasLayer
var _studio_was_paused := false
var _studio_query: LineEdit
var _studio_results: ItemList


## The last few hits she took, newest last: {dmg, src, room, msec}. The F4 note lists them,
## so a note like "I lost 40 health here" says where the hits really came from.
var recent_hits: Array = []


func _record_hit(dmg: int, src: String) -> void:
	var room := "?"
	if G.main != null and G.main.get("room_name") != null:
		room = String(G.main.room_name)
	recent_hits.append({"dmg": dmg, "src": src, "room": room, "msec": Time.get_ticks_msec()})
	if recent_hits.size() > 3:
		recent_hits.pop_front()


## The recent hits in plain words, e.g. "20 from trap in gallery 4s ago", or "" when none.
func recent_hits_text() -> String:
	var parts: Array = []
	var now := Time.get_ticks_msec()
	for h in recent_hits:
		parts.append("%d from %s in %s %ds ago" % [h["dmg"], h["src"], h["room"], int((now - int(h["msec"])) / 1000)])
	return "; ".join(parts)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	W.player_hurt.connect(_record_hit)
	if OS.has_feature("mobile") or OS.has_feature("web"):
		set_process_input(false)
		return
	EdHelp.load_file("res://studio/help/help.json")
	if DisplayServer.get_name() != "headless":
		_add_launcher()
	_linked_project = _find_project()
	var saved_map := project_dir().path_join("data/rooms_meta.json")
	if FileAccess.file_exists(saved_map):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(saved_map))
		if data is Dictionary and data.get("sheets") is Dictionary:
			var live := Db.table("rooms_meta")
			live.clear()
			live.merge(data)


func _add_launcher() -> void:
	_launcher = CanvasLayer.new()
	_launcher.layer = 42
	_launcher.hide()
	add_child(_launcher)
	var surface := WorkspaceShell.mount(_launcher)
	surface.self_modulate = Color.TRANSPARENT
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var actions := HBoxContainer.new()
	actions.position = Vector2(1010, 14)
	surface.add_child(actions)
	WorkspaceShell.button(actions, "Builders", show_map, "Open the map workspace (F3). Open the current room with F2.")
	WorkspaceShell.button(actions, "Studio", open_studio, "Find help and the asset library folder.")


## The library path in the linked checkout or portable workspace.
func studio_library_path() -> String:
	return project_dir().path_join("studio/library").replace("\\", "/")


## Open the searchable desktop help window.
func open_studio() -> void:
	if is_instance_valid(_studio_layer) and _studio_layer.visible:
		return
	if not is_instance_valid(_studio_layer):
		_build_studio_dialog()
	_studio_was_paused = get_tree().paused
	get_tree().paused = true
	_studio_layer.show()
	_refresh_studio_help(_studio_query.text)
	_studio_query.grab_focus()


func _build_studio_dialog() -> void:
	_studio_layer = CanvasLayer.new()
	_studio_layer.layer = 109
	add_child(_studio_layer)
	var surface := WorkspaceShell.mount(_studio_layer)
	surface.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.07, 0.11, 0.72)
	surface.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(730, 415)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for edge in ["top", "right", "bottom", "left"]:
		margin.add_theme_constant_override("margin_" + edge, 16)
	panel.add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	margin.add_child(page)
	var title := Label.new()
	title.text = "Studio"
	title.add_theme_font_size_override("font_size", 24)
	page.add_child(title)
	var label := Label.new()
	label.text = "Asset library folder"
	page.add_child(label)
	var path := LineEdit.new()
	path.editable = false
	path.text = studio_library_path()
	path.tooltip_text = path.text
	path.add_theme_font_size_override("font_size", 13)
	page.add_child(path)
	_studio_query = LineEdit.new()
	_studio_query.placeholder_text = "Search help, for example: map resize"
	_studio_query.text_changed.connect(_refresh_studio_help)
	_studio_query.text_submitted.connect(func(_query: String): _open_studio_result(-1))
	page.add_child(_studio_query)
	_studio_results = ItemList.new()
	_studio_results.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_studio_results.item_activated.connect(_open_studio_result)
	page.add_child(_studio_results)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	page.add_child(footer)
	WorkspaceShell.button(footer, "Open selected help", _open_studio_result.bind(-1))
	WorkspaceShell.button(footer, "Close", _close_studio)


func _refresh_studio_help(query: String) -> void:
	_studio_results.clear()
	var keys: Array[String] = ["studio.library", "builder.select", "map.map", "tuning.feel", "studio.notes"]
	if not query.strip_edges().is_empty():
		keys = EdHelp.search(query)
	for key in keys:
		var entry: Dictionary = EdHelp.entries.get(key, {})
		_studio_results.set_item_metadata(_studio_results.add_item(str(entry.get("title", key))), key)
	if _studio_results.item_count > 0:
		_studio_results.select(0)


func _open_studio_result(index: int) -> void:
	if index < 0:
		var selected := _studio_results.get_selected_items()
		if selected.is_empty():
			return
		index = selected[0]
	var key := str(_studio_results.get_item_metadata(index))
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()
	EdHelp.show(key)


func _close_studio() -> void:
	_studio_layer.hide()
	get_tree().paused = _studio_was_paused


func _process(_delta: float) -> void:
	if _launcher != null:
		_launcher.visible = G.main != null and not busy() and not get_tree().paused


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or _close_dialog != null:
		return
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if is_instance_valid(_studio_layer) and _studio_layer.visible:
		if key == KEY_ESCAPE and not EdHelp.is_open():
			get_viewport().set_input_as_handled()
			_close_studio()
		return
	if not _play_snapshot.is_empty():
		if key in [KEY_TAB, KEY_ESCAPE, KEY_F2, KEY_F3]:
			get_viewport().set_input_as_handled()
			return_to_builder()
		elif key == KEY_N and tool_action == ROOM and tool.has_method("spawn_picked"):
			get_viewport().set_input_as_handled()
			tool.spawn_picked()
		return
	if not TOOLS.has(key):
		return
	get_viewport().set_input_as_handled()
	var action: String = TOOLS[key][0]
	if tool_action == action:
		request_close()
	elif tool == null:
		open_tool(action)
	elif action == MAP:
		show_map()
	elif action == ROOM and tool_action == MAP:
		tool.open_in_room_builder()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and busy():
		request_close(get_tree().quit)


## True while a dev tool or its playtest is open.
func busy() -> bool:
	return tool != null


## Open a tool from gameplay. Builder navigation keeps drafts in the same session.
func open_tool(action: String, info := {}) -> Node:
	if tool != null or G.main == null or get_tree().paused:
		return null
	if action not in [ROOM, MAP, NOTES]:
		return null
	if G.main.room == null:
		return null
	_touch_was_blocked = G.main.touch.blocked if G.main.touch != null else false
	_previous_scale = Engine.time_scale
	_previous_hitboxes = T.v("show_hitboxes")
	_accept_quit = get_tree().auto_accept_quit
	get_tree().auto_accept_quit = false
	_pause_for_builder()
	var context := game_info()
	context.merge(info, true)
	if action == NOTES:
		context["image"] = info.get("image") if info.has("image") else _capture_game()
		tool_action = NOTES
		tool = _new_tool(NOTES, context)
		return tool
	if action == ROOM and not info.has("file_id"):
		var doc = info.get("doc")
		context["file_id"] = doc.file_id if doc != null else room_file_id(String(context["room"]), String(context["sheet"]))
	return _show_builder(action, context)


## Bring back the same map draft, selection and viewport.
func show_map() -> Node:
	if tool == null:
		return open_tool(MAP)
	if tool_action != NOTES and _play_snapshot.is_empty():
		return _show_builder(MAP, game_info())
	return null


## Open a specific room and era, keeping all other drafts available.
func open_room_editor(room_id: String, sheet: String) -> Node:
	var file_id := room_file_id(room_id, sheet)
	if not _room_exists(file_id):
		return null
	var context := {"room": room_id, "sheet": sheet, "file_id": file_id}
	if tool == null:
		return open_tool(ROOM, context)
	if tool_action != NOTES and _play_snapshot.is_empty():
		return _show_builder(ROOM, context)
	return null


func _show_builder(action: String, context: Dictionary) -> Node:
	var key := MAP
	if action == ROOM:
		var doc = context.get("doc")
		var file_id := String(context.get("file_id", doc.file_id if doc != null else ""))
		key = _room_key(file_id)
	if tool != null and tool == _builders.get(key):
		return tool
	if tool != null:
		_set_active(tool, false)
	tool_action = action
	if not _builders.has(key):
		_builders[key] = _new_tool(action, context)
	tool = _builders[key]
	if action == ROOM and tool.has_method("set_room_context"):
		tool.set_room_context(String(context.get("room", "")), String(context.get("sheet", W.sheet)))
	_set_active(tool, true)
	return tool


func _new_tool(action: String, context: Dictionary) -> Node:
	var script_path: String
	for entry in TOOLS.values():
		if entry[0] == action:
			script_path = entry[1]
			break
	var script: GDScript = load(script_path)
	var node: Node = script.new()
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(node)
	node.closed.connect(request_close)
	node.begin(context)
	return node


func _set_active(node: Node, active: bool) -> void:
	node.process_mode = Node.PROCESS_MODE_ALWAYS if active else Node.PROCESS_MODE_DISABLED
	if node.has_method("set_active"):
		node.set_active(active)
	else:
		node.visible = active


func _pause_for_builder() -> void:
	get_tree().paused = true
	if G.main != null and G.main.touch != null:
		G.main.touch.blocked = true


## Route every interactive close through an unsaved-changes prompt.
func request_close(after_close := Callable()) -> void:
	if tool == null or _close_dialog != null:
		return
	if not _play_snapshot.is_empty():
		return_to_builder()
	var dirty := _dirty_builders()
	if dirty.is_empty():
		_close_and_continue(after_close)
		return
	var dialog := ConfirmationDialog.new()
	_close_dialog = dialog
	dialog.title = "Unsaved builder changes"
	dialog.dialog_text = "Save changes to %d draft(s) before closing?" % dirty.size()
	dialog.dialog_autowrap = true
	dialog.ok_button_text = "Save all"
	dialog.cancel_button_text = "Keep editing"
	dialog.add_button("Discard", true, "discard")
	dialog.dialog_hide_on_ok = false
	dialog.confirmed.connect(_save_and_close.bind(after_close))
	dialog.custom_action.connect(func(action: StringName) -> void:
		if action == &"discard":
			_close_and_continue(after_close))
	dialog.canceled.connect(_dismiss_close_dialog)
	add_child(dialog)
	dialog.popup_centered(Vector2i(350, 128))


func _dirty_builders() -> Array[Node]:
	var dirty: Array[Node] = []
	for builder in _builders.values():
		if builder.is_dirty():
			dirty.append(builder)
	return dirty


func _save_and_close(after_close: Callable) -> void:
	for builder in _dirty_builders():
		if not builder.save():
			_close_dialog.dialog_text = "A draft could not be saved. Choose Keep editing to review the save error."
			return
	_close_and_continue(after_close)


func _dismiss_close_dialog() -> void:
	if is_instance_valid(_close_dialog):
		_close_dialog.hide()
		_close_dialog.queue_free()
	_close_dialog = null


func _close_and_continue(callback: Callable) -> void:
	close_tool()
	if callback.is_valid():
		callback.call()


## End the session after the user has saved or discarded their drafts.
func close_tool() -> void:
	if tool == null:
		return
	if not _play_snapshot.is_empty():
		return_to_builder()
	_dismiss_close_dialog()
	if tool_action == NOTES:
		tool.queue_free()
	for builder in _builders.values():
		_set_active(builder, false)
		builder.queue_free()
	_builders.clear()
	tool = null
	tool_action = ""
	god = false
	Engine.time_scale = _previous_scale
	T.set_v("show_hitboxes", _previous_hitboxes)
	get_tree().auto_accept_quit = _accept_quit
	get_tree().paused = false
	if G.main != null and G.main.touch != null:
		G.main.touch.blocked = _touch_was_blocked


## Play the selected era with the current room draft and optional start marker.
func play_room_draft(doc: RefCounted, room_id: String, sheet: String, feet: Variant = null) -> bool:
	return _start_playtest(room_id, sheet, doc, feet)


## Play from the default entrance while keeping the map draft open.
func play_map_room(room_id: String, sheet: String) -> bool:
	var draft: Node = _builders.get(_room_key(room_file_id(room_id, sheet)))
	return _start_playtest(room_id, sheet, draft.doc if draft != null else null, null)


func _start_playtest(room_id: String, sheet: String, doc: RefCounted, feet: Variant) -> bool:
	var main = G.main
	var file_id := room_file_id(room_id, sheet)
	if main == null or main.player == null or tool == null or not _play_snapshot.is_empty():
		return false
	if doc == null and not _room_exists(file_id):
		return false
	var room_script: GDScript = load("res://room.gd")
	var props_layer: GDScript = load("res://editor/props_layer.gd")
	var player = main.player
	_play_snapshot = {
		"room": main.room_name, "entry": main._entry, "world": W.snapshot(), "rpg": R.snapshot(),
		"position": player.position, "velocity": player.velocity, "hp": player.hp,
		"mp": player.mp, "facing": player.facing, "hitstop": G.hitstop,
		"shifted": G.shifted, "file_id": file_id, "room_versions": room_script.override,
		"prop_versions": props_layer.override, "old_room": room_script.override.get(file_id),
		"old_props": props_layer.override.get(file_id)
	}
	if doc != null:
		room_script.override[file_id] = doc.to_text()
		props_layer.override[file_id] = doc.props_text()
	_set_active(tool, false)
	W.sheet = sheet
	G.shifted = sheet == "after"
	G.hitstop = 0.0
	main.enter(room_id, "left")
	if feet is Vector2:
		main.player.position = feet
		main.player.velocity = Vector2.ZERO
		main.cam.reset_smoothing()
	_show_play_bar(room_id, sheet)
	get_tree().paused = false
	return true


func _show_play_bar(room_id: String, sheet: String) -> void:
	_play_bar = CanvasLayer.new()
	_play_bar.layer = 109
	add_child(_play_bar)
	var surface := WorkspaceShell.mount(_play_bar)
	surface.self_modulate = Color.TRANSPARENT
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var actions := HBoxContainer.new()
	actions.position = Vector2(30, 653)
	surface.add_child(actions)
	WorkspaceShell.button(actions, "Stop Playtest    Tab", return_to_builder)
	var caption := Label.new()
	caption.text = "%s · %s" % [room_id.capitalize(), sheet.capitalize()]
	caption.add_theme_color_override("font_outline_color", Color.BLACK)
	caption.add_theme_constant_override("outline_size", 8)
	actions.add_child(caption)


## Stop playtest and restore the room, sheet and progression that were active beforehand.
func return_to_builder() -> void:
	if _play_snapshot.is_empty():
		return
	_pause_for_builder()
	var snapshot := _play_snapshot
	_play_snapshot = {}
	_restore_override(snapshot["room_versions"], snapshot["file_id"], snapshot["old_room"])
	_restore_override(snapshot["prop_versions"], snapshot["file_id"], snapshot["old_props"])
	if is_instance_valid(_play_bar):
		_play_bar.queue_free()
	_play_bar = null
	var main = G.main
	if main != null:
		W.restore(snapshot["world"])
		R.restore(snapshot["rpg"])
		G.shifted = snapshot["shifted"]
		main.enter(snapshot["room"], snapshot["entry"])
		main.player.position = snapshot["position"]
		main.player.velocity = snapshot["velocity"]
		main.player.hp = snapshot["hp"]
		main.player.mp = snapshot["mp"]
		main.player.facing = snapshot["facing"]
		main.cam.reset_smoothing()
		G.hitstop = snapshot["hitstop"]
	if tool != null:
		if tool.has_method("finish_playtest"):
			tool.finish_playtest()
		_set_active(tool, true)


func _restore_override(versions: Dictionary, file_id: String, previous: Variant) -> void:
	if previous == null:
		versions.erase(file_id)
	else:
		versions[file_id] = previous


func _room_key(file_id: String) -> String:
	return "room:" + file_id


## Identify the physical room file used by the specified era.
func room_file_id(room_id: String, sheet: String) -> String:
	if not room_id.is_valid_filename():
		return ""
	var suffix := "_shift" if sheet == "after" else ("_restored" if sheet == "restored" else "")
	var candidate := room_id + suffix
	return candidate if suffix != "" and _room_exists(candidate) else room_id


func _room_exists(file_id: String) -> bool:
	if file_id == "":
		return false
	var path := "rooms/%s.txt" % file_id
	var base := project_dir()
	return (base != "" and FileAccess.file_exists(base.path_join(path))) or FileAccess.file_exists("res://" + path)


## Report the active location and character state for a new tool or note.
func game_info() -> Dictionary:
	var info := {"room": "?", "sheet": W.sheet, "file_id": "", "pos": Vector2.ZERO,
		"state": "?", "hp": 0.0, "facing": 1}
	var main = G.main
	if main == null:
		return info
	info["room"] = String(main.room_name)
	if main.room != null:
		info["file_id"] = String(main.room.file_id)
	var player = main.player
	if player != null:
		info["pos"] = player.global_position
		info["state"] = String(player.state)
		info["hp"] = float(player.hp)
		info["facing"] = int(player.facing)
	return info


func _capture_game() -> Image:
	var image: Image
	if DisplayServer.get_name() != "headless":
		image = get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		image = Image.create(768, 432, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.25, 0.25, 0.28))
	return image


## Use a linked checkout when available, otherwise use a per-user portable workspace.
func project_dir() -> String:
	if project_dir_override != "":
		return project_dir_override
	if OS.has_feature("mobile") or OS.has_feature("web"):
		return ""
	if _linked_project != "":
		return _linked_project
	return ProjectSettings.globalize_path("user://builder_workspace")


func _find_project() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--builder-workspace="):
			var workspace := argument.trim_prefix("--builder-workspace=").simplify_path()
			if workspace.is_absolute_path():
				return workspace
	var local := ProjectSettings.globalize_path("res://").simplify_path()
	if FileAccess.file_exists(local.path_join("project.godot")):
		return local
	var directory := OS.get_executable_path().get_base_dir().simplify_path()
	for _i in 8:
		for relative in ["workspace/new-vania/prototypes/feel-v3", "prototypes/feel-v3",
				"opencode-workspace/workspace/new-vania/prototypes/feel-v3"]:
			var candidate := directory.path_join(relative)
			if FileAccess.file_exists(candidate.path_join("project.godot")):
				return candidate
		var parent := directory.get_base_dir()
		if parent == directory:
			break
		directory = parent
	return ""


## Use the repository playtest notes directory when discoverable.
func notes_dir() -> String:
	if notes_dir_override != "":
		return notes_dir_override
	var starts := [_linked_project, OS.get_executable_path().get_base_dir()]
	for start in starts:
		var directory := String(start).simplify_path()
		while directory != "":
			for relative in ["production/playtests", "workspace/new-vania/production/playtests"]:
				var candidate := directory.path_join(relative)
				if DirAccess.dir_exists_absolute(candidate):
					return candidate.path_join("notes")
			var parent := directory.get_base_dir()
			if parent == directory:
				break
			directory = parent
	return ProjectSettings.globalize_path("user://notes")


## Jump into normal gameplay. The developer menu can use this outside the builders.
func teleport(room_id: String, sheet := "before") -> void:
	if G.main == null or not _room_exists(room_file_id(room_id, sheet)):
		return
	W.sheet = sheet
	G.shifted = sheet == "after"
	G.main.enter(room_id, "left")
