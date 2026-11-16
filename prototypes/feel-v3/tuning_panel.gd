# PROTOTYPE - NOT FOR PRODUCTION
# F1 opens this. Two pages:
#   FEEL   - a slider per feel number; the game changes at once.
#   SOUNDS - pick each sound and the music by ear (previous / next) and set its volume.
# "Save" writes tuning.json and assets/audio/events.json; "Reset" undoes every unsaved change.
extends CanvasLayer

var _root: PanelContainer
var _rows := {}     # key -> [slider, value label]
var _picks := {}    # sound name -> option label
var _vols := {}     # sound name -> volume slider
var _pages: Array = []
var _tabs: Array = []
var _help: Label
var _status: Label


func _ready() -> void:
	layer = 20
	_root = PanelContainer.new()
	_root.position = Vector2(4, 4)
	_root.size = Vector2(236, 208)
	_root.self_modulate = Color(1, 1, 1, 0.92)
	add_child(_root)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	_root.add_child(col)
	var top := HBoxContainer.new()
	col.add_child(top)
	_tabs = [_button("FEEL", _page.bind(0)), _button("SOUNDS", _page.bind(1))]
	top.add_child(_tabs[0])
	top.add_child(_tabs[1])
	top.add_child(_text("  F1 closes"))
	_pages = [_feel_page(), _sound_page()]
	col.add_child(_pages[0])
	col.add_child(_pages[1])
	_help = _text("Point at a slider to see what it does.")
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help.custom_minimum_size = Vector2(226, 24)
	col.add_child(_help)
	var buttons := HBoxContainer.new()
	col.add_child(buttons)
	buttons.add_child(_button("Save", _save))
	buttons.add_child(_button("Reset", _reset))
	_status = _text("")
	buttons.add_child(_status)
	_page(0)
	_root.visible = false


func _scroll() -> Array:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(228, 136)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	return [scroll, list]


func _feel_page() -> Control:
	var made := _scroll()
	for key in T.data:
		var d: Dictionary = T.data[key]
		var row := HBoxContainer.new()
		var name := _text(String(d["label"]))
		name.custom_minimum_size = Vector2(98, 0)
		row.add_child(name)
		var s := _slider(float(d["min"]), float(d["max"]), float(d["step"]), float(d["value"]), 84)
		row.add_child(s)
		var val := _text(_fmt(float(d["value"])))
		row.add_child(val)
		made[1].add_child(row)
		_rows[key] = [s, val]
		s.value_changed.connect(_changed.bind(key))
		s.mouse_entered.connect(_hover.bind(String(d["help"])))
	return made[0]


func _sound_page() -> Control:
	var made := _scroll()
	for name in Sfx.pickable():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		var label := _text(String(Sfx.LABELS[name]))
		label.custom_minimum_size = Vector2(52, 0)
		row.add_child(label)
		row.add_child(_button("<", _pick.bind(name, -1)))
		var opt := _text(Sfx.option_text(name))
		opt.custom_minimum_size = Vector2(84, 0)
		opt.clip_text = true
		row.add_child(opt)
		row.add_child(_button(">", _pick.bind(name, 1)))
		var s := _slider(-30.0, 6.0, 1.0, float(Sfx.ev[name]["volume_db"]), 40)
		row.add_child(s)
		s.value_changed.connect(_volume.bind(name))
		s.mouse_entered.connect(_hover.bind("< and > try the other sounds for this moment. The slider is its loudness."))
		made[1].add_child(row)
		_picks[name] = opt
		_vols[name] = s
	return made[0]


func _slider(lo: float, hi: float, step: float, value: float, width: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(width, 10)
	s.focus_mode = Control.FOCUS_NONE
	return s


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


func _page(i: int) -> void:
	for n in _pages.size():
		_pages[n].visible = n == i
		_tabs[n].modulate = Color.WHITE if n == i else Color(0.6, 0.6, 0.6)
	_help.text = "Point at a slider to see what it does." if i == 0 else "< and > try other sounds. Save keeps your choices."


func _changed(value: float, key: String) -> void:
	T.set_v(key, value)
	_rows[key][1].text = _fmt(value)
	_status.text = "changed (not saved)"


func _pick(name: String, step: int) -> void:
	Sfx.cycle(name, step)
	_picks[name].text = Sfx.option_text(name)
	_status.text = "changed (not saved)"


func _volume(value: float, name: String) -> void:
	Sfx.set_volume(name, value)
	if Sfx.ev[name]["group"] == "sfx":
		Sfx.preview(name)
	_status.text = "changed (not saved)"


func _hover(text: String) -> void:
	_help.text = text


func _save() -> void:
	var ok := T.save()
	ok = Sfx.save() and ok
	_status.text = "saved" if ok else "could not save"


func _reset() -> void:
	T.reset()
	for key in _rows:
		_rows[key][0].set_value_no_signal(T.v(key))
		_rows[key][1].text = _fmt(T.v(key))
	Sfx.reset()
	for name in _picks:
		_picks[name].text = Sfx.option_text(name)
		_vols[name].set_value_no_signal(float(Sfx.ev[name]["volume_db"]))
	_status.text = "back to the saved values"
