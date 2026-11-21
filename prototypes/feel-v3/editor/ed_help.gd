# PROTOTYPE - NOT FOR PRODUCTION
# editor/ed_help.gd - the studio "?" help system: one popup, static API.
# Callers preload this file (there is no class_name); all state lives in static vars.

extends RefCounted

const Shell := preload("res://editor/workspace_shell.gd")

## Loaded help entries keyed by id; each value is the dictionary read from JSON.
static var entries: Dictionary = {}
## The one open popup layer, or null when no popup is open.
static var popup_layer: CanvasLayer = null
## The label inside the open popup that shows the text.
static var popup_label: Label = null
## The picture above the text inside the open popup.
static var popup_thumb: TextureRect = null
## The key the open popup was asked to show.
static var popup_key: String = ""
## The plain text the open popup currently displays.
static var popup_text: String = ""
## Optional resolver called with a "thumb" id; return a Texture2D to show a picture.
static var thumb_resolver: Callable = Callable()


## Merge every valid entry of a JSON help file into the table; return how many were added or replaced.
static func load_file(path: String) -> int:
	if path.is_empty() or not FileAccess.file_exists(path):
		return 0
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	var raw := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return 0
	var added := 0
	for key in (parsed as Dictionary):
		var entry: Variant = (parsed as Dictionary)[key]
		if not (entry is Dictionary):
			continue
		var title: Variant = (entry as Dictionary).get("title", "")
		if not (title is String) or (title as String).strip_edges().is_empty():
			continue
		entries[String(key)] = entry
		added += 1
	return added


## Empty the table and close any open popup.
static func clear() -> void:
	entries.clear()
	hide()


## True when a loaded entry exists for this non-empty key.
static func has(key: String) -> bool:
	return not key.is_empty() and entries.has(key)


## The plain text a reader sees for a key: title, then the labelled sections that have content.
static func text_for(key: String) -> String:
	if key.is_empty():
		return "No help written yet"
	if not entries.has(key):
		return "No help written yet\n%s" % key
	var entry: Dictionary = entries[key]
	var blocks: PackedStringArray = []
	var what := _text_field(entry, "what")
	if not what.is_empty():
		blocks.append("What it is\n%s" % what)
	var how := _text_field(entry, "how")
	if not how.is_empty():
		blocks.append("How to use\n%s" % how)
	var limits := _list_lines(entry, "limits", "- ")
	if not limits.is_empty():
		blocks.append("Limits\n%s" % limits)
	var keys := _list_lines(entry, "keys", "")
	if not keys.is_empty():
		blocks.append("Keys\n%s" % keys)
	var title := _text_field(entry, "title")
	if title.is_empty():
		title = key
	if blocks.is_empty():
		return title
	return title + "\n\n" + "\n\n".join(blocks)


## Open the one help popup for a key, reusing it when already open.
static func show(key: String) -> void:
	popup_key = key
	popup_text = text_for(key)
	if is_open():
		popup_label.text = popup_text
		_apply_thumb(_thumb_for(key))
		return
	popup_layer = null
	popup_label = null
	popup_thumb = null
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var layer := HelpLayer.new()
	layer.layer = 110
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(layer)
	layer.add_to_group("ed_help_popup")
	_build_popup(layer)
	_apply_thumb(_thumb_for(key))
	popup_layer = layer


## Close the popup at once; harmless when nothing is open.
static func hide() -> void:
	var layer := popup_layer
	popup_layer = null
	popup_label = null
	popup_thumb = null
	popup_key = ""
	popup_text = ""
	if layer == null or not is_instance_valid(layer):
		return
	if layer.is_in_group("ed_help_popup"):
		layer.remove_from_group("ed_help_popup")
	layer.queue_free()


## True while the popup is open.
static func is_open() -> bool:
	return popup_layer != null and is_instance_valid(popup_layer) and popup_layer.is_in_group("ed_help_popup")


## The key the open popup shows, or an empty string when closed.
static func current_key() -> String:
	if not is_open():
		return ""
	return popup_key


## The plain text the open popup shows, or an empty string when closed.
static func shown_text() -> String:
	if not is_open():
		return ""
	return popup_text


## Let a right mouse click on the control open help for a key.
static func attach(control: Control, key: String) -> void:
	if control == null:
		return
	control.set_meta("help_key", key)
	if control.has_meta("help_bound"):
		return
	control.set_meta("help_bound", true)
	control.gui_input.connect(_on_control_gui_input.bind(control))


## Open help when the bound control gets a right mouse button press.
static func _on_control_gui_input(event: InputEvent, control: Control) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_RIGHT:
		return
	if control == null or not is_instance_valid(control):
		return
	show(String(control.get_meta("help_key", "")))


## Read a text field from an entry, trimmed; missing or non-text fields read as empty.
static func _text_field(entry: Dictionary, field: String) -> String:
	var value: Variant = entry.get(field, "")
	if value == null:
		return ""
	return str(value).strip_edges()


## Read a list field from an entry as one line per item, each with an optional prefix.
static func _list_lines(entry: Dictionary, field: String, prefix: String) -> String:
	var value: Variant = entry.get(field, [])
	if not (value is Array):
		return ""
	var lines: PackedStringArray = []
	for item in value:
		var line := str(item).strip_edges()
		if line.is_empty():
			continue
		lines.append(prefix + line)
	return "\n".join(lines)


## Resolve the optional thumbnail for a key; return null when there is none.
static func _thumb_for(key: String) -> Texture2D:
	if not thumb_resolver.is_valid():
		return null
	if not entries.has(key):
		return null
	var entry: Dictionary = entries[key]
	var id: Variant = entry.get("thumb", "")
	if not (id is String) or (id as String).is_empty():
		return null
	var result: Variant = thumb_resolver.call(id)
	if result is Texture2D:
		return result
	return null


## Show or clear the picture above the text in the open popup.
static func _apply_thumb(texture: Texture2D) -> void:
	if popup_thumb == null or not is_instance_valid(popup_thumb):
		return
	popup_thumb.texture = texture
	popup_thumb.visible = texture != null


## Build the dimmed backdrop, the centred panel, the scrolling text and the Close button.
static func _build_popup(layer: CanvasLayer) -> void:
	# The builders draw on a 1280 x 720 canvas scaled to the game's small screen; the popup must live on the same canvas.
	var host := Shell.mount(layer)
	host.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var dim := ColorRect.new()
	var dim_color := Shell.BACKGROUND
	dim_color.a = 0.72
	dim.color = dim_color
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 420)
	panel.add_theme_stylebox_override("panel", _panel_box())
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	var thumb := TextureRect.new()
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.custom_minimum_size = Vector2(0, 96)
	thumb.visible = false
	content.add_child(thumb)

	var body := Label.new()
	body.text = popup_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_color_override("font_color", Shell.INK)
	body.add_theme_font_size_override("font_size", 16)
	content.add_child(body)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(footer)

	var close := Button.new()
	close.text = "Close"
	close.add_theme_color_override("font_color", Shell.INK)
	close.add_theme_color_override("font_hover_color", Shell.ACCENT)
	close.pressed.connect(layer.dismiss)
	footer.add_child(close)

	popup_label = body
	popup_thumb = thumb


## The panel background drawn from the Shell colours.
static func _panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Shell.SURFACE
	box.border_color = Shell.ACCENT
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 16
	box.content_margin_bottom = 16
	return box


## The popup's layer: closes itself on Escape, even while the game is paused.
class HelpLayer extends CanvasLayer:
	## Close and free the popup, dropping it from the group at once.
	func dismiss() -> void:
		if is_in_group("ed_help_popup"):
			remove_from_group("ed_help_popup")
		queue_free()

	## Close the popup when Escape is pressed.
	func _input(event: InputEvent) -> void:
		if not event.is_action_pressed("ui_cancel"):
			return
		get_tree().root.set_input_as_handled()
		dismiss()
