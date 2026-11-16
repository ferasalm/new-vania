# PROTOTYPE - NOT FOR PRODUCTION
# F1 opens this. Drag a slider and the game changes at once, so the feel can be
# set by playing. "Save" writes tuning.json; "Reset" goes back to the saved values.
extends CanvasLayer

var _root: PanelContainer
var _rows := {}     # key -> [slider, value label]
var _help: Label
var _status: Label


func _ready() -> void:
	layer = 20
	_root = PanelContainer.new()
	_root.position = Vector2(4, 4)
	_root.size = Vector2(230, 208)
	_root.self_modulate = Color(1, 1, 1, 0.92)
	add_child(_root)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	_root.add_child(col)
	col.add_child(_text("TUNING  (F1 closes, the game keeps running)"))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(222, 140)
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for key in T.data:
		var d: Dictionary = T.data[key]
		var row := HBoxContainer.new()
		var name := _text(String(d["label"]))
		name.custom_minimum_size = Vector2(96, 0)
		row.add_child(name)
		var s := HSlider.new()
		s.min_value = float(d["min"])
		s.max_value = float(d["max"])
		s.step = float(d["step"])
		s.value = float(d["value"])
		s.custom_minimum_size = Vector2(84, 10)
		s.focus_mode = Control.FOCUS_NONE
		row.add_child(s)
		var val := _text(_fmt(float(d["value"])))
		row.add_child(val)
		list.add_child(row)
		_rows[key] = [s, val]
		s.value_changed.connect(_changed.bind(key))
		s.mouse_entered.connect(_hover.bind(key))
	_help = _text("Point at a slider to see what it does.")
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help.custom_minimum_size = Vector2(220, 24)
	col.add_child(_help)
	var buttons := HBoxContainer.new()
	col.add_child(buttons)
	buttons.add_child(_button("Save", _save))
	buttons.add_child(_button("Reset", _reset))
	_status = _text("")
	buttons.add_child(_status)
	_root.visible = false


func _text(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 8)
	return l


func _button(t: String, fn: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", 8)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(fn)
	return b


func _fmt(x: float) -> String:
	return str(snappedf(x, 0.01))


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("tuning"):
		_root.visible = not _root.visible


func _changed(value: float, key: String) -> void:
	T.set_v(key, value)
	_rows[key][1].text = _fmt(value)
	_status.text = "changed (not saved)"


func _hover(key: String) -> void:
	_help.text = String(T.data[key]["help"])


func _save() -> void:
	_status.text = "saved" if T.save() else "could not save"


func _reset() -> void:
	T.reset()
	for key in _rows:
		_rows[key][0].set_value_no_signal(T.v(key))
		_rows[key][1].text = _fmt(T.v(key))
	_status.text = "reset"
