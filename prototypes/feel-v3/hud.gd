# PROTOTYPE - NOT FOR PRODUCTION
# Three bars (HP, Energy, MP), the key reminder, and the black fade used by
# doors and death. A bar blinks red when she tries to spend what she has not got.
extends CanvasLayer

const BARS := [["hp", "HP", "#D9BC8F"], ["energy", "EN", "#7BD67B"], ["mp", "MP", "#5AB4FF"]]
const WIDTH := 80.0

var _fill := {}     # name -> the coloured part
var _back := {}     # name -> the dark part behind it
var _flash := {}    # name -> seconds left of the red blink
var _kills: Label
var _fade: ColorRect


func _ready() -> void:
	layer = 5
	for i in BARS.size():
		var name: String = BARS[i][0]
		var y := 6.0 + i * 8.0
		var tag := _label(BARS[i][1], Vector2(6, y - 4.0))
		tag.modulate = Color(BARS[i][2])
		var back := ColorRect.new()
		back.color = Color(0, 0, 0, 0.6)
		back.position = Vector2(21, y)
		back.size = Vector2(WIDTH + 2.0, 6.0 if i == 0 else 5.0)
		add_child(back)
		var fill := ColorRect.new()
		fill.color = Color(BARS[i][2])
		fill.position = Vector2(22, y + 1.0)
		fill.size = Vector2(WIDTH, 4.0 if i == 0 else 3.0)
		add_child(fill)
		_fill[name] = fill
		_back[name] = back
		_flash[name] = 0.0
	_kills = _label("", Vector2(110, 2))
	var hint := _label("A/D move  S crouch  K jump  J/I attack  W+J special  L backdash  F1 tune  R restart", Vector2(6, 202))
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


func refresh(player: Node, kills: int) -> void:
	var now := {"hp": player.hp / maxf(1.0, T.v("player_hp")), "energy": player.energy / maxf(1.0, T.v("energy_max")),
		"mp": player.mp / maxf(1.0, T.v("mp_max"))}
	var delta := get_process_delta_time()
	for name in _fill:
		_fill[name].size.x = WIDTH * clampf(now[name], 0.0, 1.0)
		_flash[name] = maxf(0.0, _flash[name] - delta)
		_back[name].color = Color(0.9, 0.15, 0.15, 0.9) if _flash[name] > 0.0 else Color(0, 0, 0, 0.6)
	_kills.text = "defeated %d" % kills


func flash(name: String) -> void:
	_flash[name] = 0.18


func fade(to: float, time: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", to, time)
	await tw.finished
