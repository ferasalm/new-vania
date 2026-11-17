# PROTOTYPE - NOT FOR PRODUCTION
# Three bars (HP, Energy, MP), the weapon in hand, the key reminder, the name of
# the area when you walk in, short messages, the boss's health bar, and the black
# fade used by doors and death. A bar blinks red when she tries to spend what she
# has not got.
extends CanvasLayer

const BARS := [["hp", "HP", "#D9BC8F"], ["energy", "EN", "#7BD67B"], ["mp", "MP", "#5AB4FF"]]
const WIDTH := 80.0

var _fill := {}     # name -> the coloured part
var _back := {}     # name -> the dark part behind it
var _flash := {}    # name -> seconds left of the red blink
var _kills: Label
var _weapon: Label
var _banner: Label
var _toast: Label
var _prompt: Label
var _boss_name: Label
var _boss_back: ColorRect
var _boss_fill: ColorRect
var _fade: ColorRect
var _banner_t := 0.0
var _toast_t := 0.0
var _hint: Label
var touch_mode := false
var _name: Label


func _ready() -> void:
	layer = 5
	for i in BARS.size():
		var name: String = BARS[i][0]
		var y := 13.0 + i * 8.0
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
	_name = _label("PANDORA-001", Vector2(6, 0))
	_name.modulate = Color("#BFF6FF")
	_kills = _label("", Vector2(110, 9))
	_weapon = _label("", Vector2(110, 18))
	_weapon.modulate = Color("#7BE6F2")
	_hint = _label("A/D move  S crouch  K jump  J/I attack  W+J special  S+K slide  Q/L backdash left/right  E weapon  Esc pause  F1 tune", Vector2(6, 203))
	_hint.modulate = Color(1, 1, 1, 0.55)
	_banner = _centered(Vector2(0, 60), 16)
	_toast = _centered(Vector2(0, 84), 8)
	_toast.modulate = Color("#F2E3A0")
	_prompt = _centered(Vector2(0, 150), 8)
	_prompt.modulate = Color("#9FF5F5")
	_boss_back = ColorRect.new()
	_boss_back.color = Color(0, 0, 0, 0.7)
	_boss_back.position = Vector2(91, 40)
	_boss_back.size = Vector2(202, 6)
	add_child(_boss_back)
	_boss_fill = ColorRect.new()
	_boss_fill.color = Color("#B04CE0")
	_boss_fill.position = Vector2(92, 41)
	_boss_fill.size = Vector2(200, 4)
	add_child(_boss_fill)
	_boss_name = _centered(Vector2(0, 27), 8)
	_boss_name.modulate = Color("#E8C8FF")
	boss_bar("", 0.0)
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


func _centered(at: Vector2, font: int) -> Label:
	var l := _label("", at)
	l.add_theme_font_size_override("font_size", font)
	l.size = Vector2(384, 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func refresh(player: Node, kills: int) -> void:
	var now := {"hp": player.hp / maxf(1.0, T.v("player_hp")), "energy": player.energy / maxf(1.0, T.v("energy_max")),
		"mp": player.mp / maxf(1.0, T.v("mp_max"))}
	_fill["mp"].modulate = Color.WHITE if player.mp >= player.special_cost() else Color(0.55, 0.55, 0.7)
	var delta := get_process_delta_time()
	for name in _fill:
		_fill[name].size.x = WIDTH * clampf(now[name], 0.0, 1.0)
		_flash[name] = maxf(0.0, _flash[name] - delta)
		_back[name].color = Color(0.9, 0.15, 0.15, 0.9) if _flash[name] > 0.0 else Color(0, 0, 0, 0.6)
	_kills.text = "defeated %d" % kills
	_weapon.text = player.weapon_name()
	_banner_t = maxf(0.0, _banner_t - delta)
	_banner.modulate.a = clampf(_banner_t, 0.0, 1.0)
	_toast_t = maxf(0.0, _toast_t - delta)
	_toast.modulate.a = clampf(_toast_t * 2.0, 0.0, 1.0)
	_hint.visible = not touch_mode


func set_unit(n: int) -> void:
	# the name above the bars: every reconstruction is the next Pandora
	_name.text = "PANDORA-%03d" % n


func flash(name: String) -> void:
	_flash[name] = 0.18


func banner(text: String) -> void:
	# the name of the place, shown for a moment when she walks in
	_banner.text = text
	_banner_t = 2.6


func toast(text: String, time: float = 2.2) -> void:
	_toast.text = text
	_toast_t = time


func prompt(text: String) -> void:
	_prompt.text = text


func boss_bar(title: String, part: float) -> void:
	var on := title != ""
	_boss_name.visible = on
	_boss_back.visible = on
	_boss_fill.visible = on
	_boss_name.text = title
	_boss_fill.size.x = 200.0 * clampf(part, 0.0, 1.0)


func fade(to: float, time: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", to, time)
	await tw.finished
