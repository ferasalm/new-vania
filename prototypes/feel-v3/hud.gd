# PROTOTYPE - NOT FOR PRODUCTION
# Health bar, the key reminder, and the black fade used by doors and death.
extends CanvasLayer

var _bar: ColorRect
var _back: ColorRect
var _kills: Label
var _fade: ColorRect


func _ready() -> void:
	layer = 5
	_back = ColorRect.new()
	_back.color = Color(0, 0, 0, 0.6)
	_back.position = Vector2(8, 8)
	_back.size = Vector2(82, 6)
	add_child(_back)
	_bar = ColorRect.new()
	_bar.color = Color("#D9BC8F")
	_bar.position = Vector2(9, 9)
	_bar.size = Vector2(80, 4)
	add_child(_bar)
	_kills = _label("", Vector2(96, 4))
	var hint := _label("A/D move   K jump   J/I attack   L backdash   S+K drop   F1 tuning   R restart", Vector2(8, 202))
	hint.modulate = Color(1, 1, 1, 0.6)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.size = Vector2(384, 216)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _label(text: String, at: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = at
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	add_child(l)
	return l


func refresh(hp: float, max_hp: float, kills: int) -> void:
	_bar.size.x = 80.0 * clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	_kills.text = "defeated %d" % kills


func fade(to: float, time: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", to, time)
	await tw.finished
