extends RefCounted

const EdHelp := preload("res://editor/ed_help.gd")
const SIZE := Vector2(1280, 720)
const BACKGROUND := Color("#171923")
const SURFACE := Color("#222634")
const INK := Color("#edf0f8")
const ACCENT := Color("#a6c7ff")


## Mount the editor at its own UI scale while the game keeps its pixel-art viewport.
static func mount(layer: CanvasLayer) -> Control:
	var panel := WorkspacePanel.new()
	panel.size = SIZE
	panel.theme = _theme()
	layer.add_child(panel)
	return panel


## Create a keyboard-focusable toolbar or panel action, with an optional "?" help button.
static func button(parent: Container, label: String, action: Callable, tooltip := "", help_key := "", show_question := true) -> Button:
	var control := Button.new()
	control.text = label
	control.tooltip_text = tooltip
	control.pressed.connect(action)
	parent.add_child(control)
	if not help_key.is_empty():
		EdHelp.attach(control, help_key)
	if not help_key.is_empty() and show_question:
		var help := Button.new()
		help.text = "?"
		help.tooltip_text = "Help: %s" % label
		help.custom_minimum_size = Vector2(28, 0)
		EdHelp.attach(help, help_key)
		help.pressed.connect(func() -> void: EdHelp.show(help_key))
		parent.add_child(help)
	return control


static func _theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16
	theme.set_stylebox("panel", "Panel", _box(BACKGROUND))
	theme.set_stylebox("panel", "PanelContainer", _box(SURFACE, Color("#303549")))
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", Color("#a4adbf"))
	theme.set_color("font_disabled_color", "Button", Color("#858da2"))
	for control in ["Button", "OptionButton", "MenuButton"]:
		theme.set_stylebox("normal", control, _box(Color("#30364a"), Color("#464f68"), 11, 7))
		theme.set_stylebox("hover", control, _box(Color("#3f4860"), ACCENT, 11, 7))
		theme.set_stylebox("pressed", control, _box(Color("#3a4f72"), ACCENT, 11, 7))
		theme.set_stylebox("disabled", control, _box(Color("#252939"), Color("#303549"), 11, 7))
		theme.set_stylebox("focus", control, _box(Color.TRANSPARENT, ACCENT, 11, 7))
	theme.set_stylebox("normal", "LineEdit", _box(BACKGROUND, Color("#535e79"), 9, 7))
	theme.set_stylebox("focus", "LineEdit", _box(Color.TRANSPARENT, ACCENT, 9, 7))
	theme.set_stylebox("panel", "ItemList", _box(BACKGROUND, Color("#303549"), 5, 5))
	theme.set_stylebox("selected", "ItemList", _box(Color("#3a4f72"), ACCENT))
	theme.set_stylebox("selected_focus", "ItemList", _box(Color("#3a4f72"), ACCENT))
	theme.set_constant("v_separation", "ItemList", 10)
	theme.set_constant("h_separation", "ItemList", 8)
	theme.set_constant("separation", "HBoxContainer", 8)
	theme.set_constant("separation", "VBoxContainer", 8)
	return theme


static func _box(fill: Color, border := Color.TRANSPARENT, horizontal := 0, vertical := 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1 if border.a > 0.0 else 0)
	box.set_corner_radius_all(5)
	box.content_margin_left = horizontal
	box.content_margin_right = horizontal
	box.content_margin_top = vertical
	box.content_margin_bottom = vertical
	return box


class WorkspacePanel extends Panel:
	func _ready() -> void:
		get_viewport().size_changed.connect(_fit)
		_fit()

	func _fit() -> void:
		var area := get_viewport_rect().size
		var factor := minf(area.x / size.x, area.y / size.y)
		scale = Vector2.ONE * factor
		position = (area - size * factor) * 0.5
