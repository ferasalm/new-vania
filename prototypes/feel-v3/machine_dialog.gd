# PROTOTYPE - NOT FOR PRODUCTION
# The question at the time machine: "Are you sure you want to activate this machine?"
# YES or NO. Styled like the SYSTEM OFFLINE screen: a dimmed picture, big words, two
# choices. W/S picks, J or K chooses; a finger or the mouse works too. NO is the first pick.
# While it is open main holds her still and the touch buttons are off.
extends CanvasLayer

signal chosen(choice: String)

var active := false
var _box: Control
var _btns: Array = []
var _pick := 1
var _t := 0.0
var _ready_t := 0.0
var _nav_was := true
var _ok_was := true


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_box = Control.new()
	_box.size = Vector2(384, 216)
	add_child(_box)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.0, 0.06, 0.78)
	dim.size = Vector2(384, 216)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_box.add_child(dim)
	_label("THE ORGAN OF HOURS", 62, 14, Color("#E8C8FF"))
	_label("Are you sure you want to activate this machine?", 86, 10, Color("#F2E3A0"))
	for i in 2:
		var b := Button.new()
		b.text = ["YES", "NO"][i]
		b.add_theme_font_size_override("font_size", 10)
		b.custom_minimum_size = Vector2(96, 22)
		b.size = b.get_combined_minimum_size()
		b.position = Vector2((384.0 - b.size.x) / 2.0, 114.0 + i * (b.size.y + 6.0))
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_choose.bind(i))
		b.mouse_entered.connect(func(): _pick = i)
		_box.add_child(b)
		_btns.append(b)


func _label(text: String, y: float, font: int, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.position = Vector2(0, y)
	l.size = Vector2(384, 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	_box.add_child(l)


func ask() -> String:
	# shows the question and waits: "yes" or "no"
	active = true
	visible = true
	_pick = 1
	_t = 0.0
	_ready_t = 0.35      # a button still held from the press that opened it must not answer
	_nav_was = true
	_ok_was = true
	var choice: String = await chosen
	return choice


func close() -> void:
	active = false
	visible = false


func _choose(i: int) -> void:
	if not active or _ready_t > 0.0:
		return
	active = false
	Sfx.play("pickup", 0.9 if i == 0 else 0.5)
	chosen.emit("yes" if i == 0 else "no")


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_ready_t = maxf(0.0, _ready_t - delta)
	for i in _btns.size():
		_btns[i].modulate = Color(1, 1, 1, 1) if i == _pick else Color(0.6, 0.6, 0.6, 0.85)
		_btns[i].text = ("> %s <" if i == _pick else "%s") % ["YES", "NO"][i]
	# own edge checks, like the SYSTEM OFFLINE screen (a press between two frames is not lost)
	var nav := Input.is_action_pressed("up") or Input.is_action_pressed("down")
	var ok := Input.is_action_pressed("attack") or Input.is_action_pressed("jump")
	var nav_edge := nav and not _nav_was
	var ok_edge := ok and not _ok_was
	_nav_was = nav
	_ok_was = ok
	if not active:
		return
	if nav_edge:
		_pick = 1 - _pick
		Sfx.play("no_energy", 1.4)
	if ok_edge:
		_choose(_pick)
