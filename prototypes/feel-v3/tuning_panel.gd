# PROTOTYPE - NOT FOR PRODUCTION
# F1 opens this. Three pages:
#   FEEL   - a slider per feel number; the game changes at once.
#   WEAPONS- pick what she swings (previous / next) and set the two-handed feel.
#   SOUNDS - pick each sound and the music by ear (previous / next), set its
#            volume and how much its pitch varies.
# "Save" writes tuning.json and assets/audio/events.json; "Reset" undoes every unsaved change.
extends CanvasLayer

const WEAPON_KEYS := ["weapon", "hit_reach", "hit_thickness", "show_hitboxes", "elegy_time", "elegy_damage_mult", "elegy_energy_mult",
	"elegy_special_cost", "elegy_special_damage", "elegy_special_time"]
const EdHelp := preload("res://editor/ed_help.gd")

var _root: PanelContainer
var _rows := {}     # key -> [slider, value label]
var _wopt: Label    # the WEAPONS page picker's option text
var _picks := {}    # sound name -> option label
var _pitches := {}  # sound name -> pitch slider
var _vols := {}     # sound name -> volume slider
var _pages: Array = []
var _tabs: Array = []
var _help: Label
var _status: Label
var _help_buttons := {}        # tuning key -> its "?" button
var _sound_help_buttons := {}  # sound name -> its "?" button


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
	_pages = [_feel_page(), _weapon_page(), _sound_page()]
	_tabs = [_button("FEEL", _page.bind(0)), _button("WEAPONS", _page.bind(1)), _button("SOUNDS", _page.bind(2))]
	var part_index := _pages.size()
	for part in _parts_loaded():
		_tabs.append(_button(String(part).to_upper(), _page.bind(part_index)))
		_pages.append(_part_page(part))
		part_index += 1
	for t in _tabs:
		top.add_child(t)
	top.add_child(_text("  F1 closes"))
	for pg in _pages:
		col.add_child(pg)
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


func _slider_row(key: String) -> HBoxContainer:
	# one label + slider + value + help row, used by the FEEL and WEAPONS pages
	var d: Dictionary = T.data[key]
	var row := HBoxContainer.new()
	var name := _text(String(d["label"]))
	name.custom_minimum_size = Vector2(80, 0)
	name.clip_text = true
	row.add_child(name)
	var s := _slider(float(d["min"]), float(d["max"]), float(d["step"]), float(d["value"]), 64)
	row.add_child(s)
	var val := _text(_fmt(float(d["value"])))
	val.custom_minimum_size = Vector2(34, 0)
	val.clip_text = true
	row.add_child(val)
	var q := _help_button("Help: " + String(d["label"]), _show_slider_help.bind(key))
	row.add_child(q)
	_help_buttons[key] = q
	_rows[key] = [s, val]
	s.value_changed.connect(_changed.bind(key))
	s.mouse_entered.connect(_hover.bind(String(d["help"])))
	return row


func _feel_page() -> Control:
	var made := _scroll()
	for key in T.data:
		if WEAPON_KEYS.has(key) or String(T.source.get(key, "")) != "":
			continue
		made[1].add_child(_slider_row(key))
	return made[0]


func _parts_loaded() -> Array:
	# every tuning.d part that loaded, in the fixed order (one tab each)
	var out: Array = []
	for part in T.PARTS:
		for key in T.source:
			if String(T.source[key]) == String(part):
				out.append(part)
				break
	return out


func _part_page(part: String) -> Control:
	# the sliders of one tuning.d part file
	var made := _scroll()
	for key in T.data:
		if String(T.source.get(key, "")) == part:
			made[1].add_child(_slider_row(key))
	return made[0]


func _weapon_page() -> Control:
	var made := _scroll()
	var d: Dictionary = T.data["weapon"]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 1)
	var name := _text(String(d["label"]))
	name.custom_minimum_size = Vector2(80, 0)
	name.clip_text = true
	row.add_child(name)
	row.add_child(_button("<", _wpick.bind(-1)))
	_wopt = _text(String(d["options"][int(d["value"])]))
	_wopt.custom_minimum_size = Vector2(60, 0)
	_wopt.clip_text = true
	row.add_child(_wopt)
	row.add_child(_button(">", _wpick.bind(1)))
	var q := _help_button("Help: " + String(d["label"]), _show_picker_help.bind("weapon"))
	row.add_child(q)
	_help_buttons["weapon"] = q
	row.mouse_entered.connect(_hover.bind(String(d["help"])))
	made[1].add_child(row)
	for key in WEAPON_KEYS.slice(1):
		made[1].add_child(_slider_row(key))
	return made[0]


func _sound_page() -> Control:
	var made := _scroll()
	for name in Sfx.pickable():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		var label := _text(String(Sfx.LABELS[name]))
		label.custom_minimum_size = Vector2(48, 0)
		label.clip_text = true
		row.add_child(label)
		row.add_child(_button("<", _pick.bind(name, -1)))
		var opt := _text(Sfx.option_text(name))
		opt.custom_minimum_size = Vector2(64, 0)
		opt.clip_text = true
		row.add_child(opt)
		row.add_child(_button(">", _pick.bind(name, 1)))
		var s := _slider(-30.0, 6.0, 1.0, float(Sfx.ev[name]["volume_db"]), 32)
		row.add_child(s)
		s.value_changed.connect(_volume.bind(name))
		if Sfx.ev[name]["group"] == "sfx":
			# music ignores pitch variation, so it gets no dead slider
			var ps := _slider(0.0, 0.25, 0.01, float(Sfx.ev[name]["pitch_random"]), 20)
			row.add_child(ps)
			ps.value_changed.connect(_pitch.bind(name))
			_pitches[name] = ps
		var q := _help_button("Help: " + String(Sfx.LABELS[name]), _show_sound_help.bind(String(name)))
		row.add_child(q)
		_sound_help_buttons[String(name)] = q
		s.mouse_entered.connect(_hover.bind("< and > try the other sounds for this moment. The sliders are its loudness and its pitch variety."))
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


## The help entry key of one tuning row ("tuning:" + key).
func help_key(key: String) -> String:
	return "tuning:" + key


## The help entry key of one sound row ("tuning:sound:" + name).
func sound_help_key(name: String) -> String:
	return "tuning:sound:" + name


## The "?" button at the end of one tuning row, or null for an unknown key.
func help_button(key: String) -> Button:
	if _help_buttons.has(key):
		return _help_buttons[key]
	return null


## The "?" button at the end of one sound row, or null for an unknown name.
func sound_help_button(name: String) -> Button:
	if _sound_help_buttons.has(name):
		return _sound_help_buttons[name]
	return null


## A tiny "?" with no padding, so it fits at the end of a row.
func _help_button(tip: String, fn: Callable) -> Button:
	var b := _button("?", fn)
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(11, 8)
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, empty)
	return b


## Rebuild a slider row's help from the data as it is now, then open the popup.
func _show_slider_help(key: String) -> void:
	var d: Dictionary = T.data[key]
	EdHelp.entries[help_key(key)] = {
		"title": String(d["label"]),
		"what": String(d["help"]),
		"how": "Drag the slider. The game changes at once. Press Save to keep it.",
		"limits": [
			"Range: %s to %s, steps of %s" % [_fmt(float(d["min"])), _fmt(float(d["max"])), _fmt(float(d["step"]))],
			"Saved value: %s" % _fmt(float(T.defaults[key])),
			"Now: %s" % _fmt(T.v(key)),
		],
	}
	EdHelp.show(help_key(key))


## Rebuild a picker row's help from the data as it is now, then open the popup.
func _show_picker_help(key: String) -> void:
	var d: Dictionary = T.data[key]
	var opts: Array = d["options"]
	var saved_i := clampi(int(T.defaults[key]), 0, opts.size() - 1)
	var now_i := clampi(int(T.v(key)), 0, opts.size() - 1)
	var names := PackedStringArray()
	for o in opts:
		names.append(String(o))
	EdHelp.entries[help_key(key)] = {
		"title": String(d["label"]),
		"what": String(d["help"]),
		"how": "Press < or > to pick another. Press Save to keep it.",
		"limits": [
			"Choices: " + ", ".join(names),
			"Saved choice: " + String(opts[saved_i]),
			"Now: " + String(opts[now_i]),
		],
	}
	EdHelp.show(help_key(key))


## Rebuild a sound row's help from the data as it is now, then open the popup.
func _show_sound_help(name: String) -> void:
	var limits: Array = ["Loudness: %s to %s dB" % [_fmt(-30.0), _fmt(6.0)]]
	if String(Sfx.ev[name]["group"]) == "sfx":
		limits.append("Pitch variety: %s to %s" % [_fmt(0.0), _fmt(0.25)])
	EdHelp.entries[sound_help_key(name)] = {
		"title": String(Sfx.LABELS[name]),
		"what": "< and > try the other sounds for this moment. The sliders are its loudness and its pitch variety.",
		"how": "Press < or > to hear another sound. Press Save to keep it.",
		"limits": limits,
	}
	EdHelp.show(sound_help_key(name))


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("tuning"):
		_root.visible = not _root.visible


func _page(i: int) -> void:
	for n in _pages.size():
		_pages[n].visible = n == i
		_tabs[n].modulate = Color.WHITE if n == i else Color(0.6, 0.6, 0.6)
	if i < 3:
		_help.text = [
			"Point at a slider to see what it does.",
			"Pick what she swings with < and >. The sliders change the two-handed feel at once.",
			"< and > try other sounds. The small sliders are its loudness and its pitch variety.",
		][i]
	else:
		_help.text = "The sliders of the %s page. They change the game at once." % String(_tabs[i].text)


func _wpick(step: int) -> void:
	var opts: Array = T.data["weapon"]["options"]
	var i := posmod(int(T.v("weapon")) + step, opts.size())
	T.set_v("weapon", i)
	_wopt.text = String(opts[i])
	if i == 1:
		Sfx.play("swing_heavy")
	else:
		Sfx.play("swing")
	_status.text = "changed (not saved)"


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


func _pitch(value: float, name: String) -> void:
	Sfx.set_pitch(name, value)
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
	_wopt.text = String(T.data["weapon"]["options"][int(T.v("weapon"))])
	Sfx.reset()
	for name in _picks:
		_picks[name].text = Sfx.option_text(name)
		_vols[name].set_value_no_signal(float(Sfx.ev[name]["volume_db"]))
		if _pitches.has(name):
			_pitches[name].set_value_no_signal(float(Sfx.ev[name]["pitch_random"]))
	_status.text = "back to the saved values"
