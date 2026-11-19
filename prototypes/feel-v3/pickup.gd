# PROTOTYPE - NOT FOR PRODUCTION
# An item waiting in the world: it glows and bobs, it is taken with Up, and a
# soul orb or scrap is taken by touch. It shows assets/items/<id>.png when that
# file exists, otherwise a placeholder square coloured by kind with a letter.
# S2.
extends Node2D

signal taken(item_id: String)

const ItemIcons := preload("res://item_icons.gd")

var item_id := ""
var touch_take := false
var rare := false
var show_card := true
var life := 12.0

var _life := 12.0
var _t := 0.0
var _fly_t := 0.0
var _taken := false
var _waiting := false
var _color := Color(0.9, 0.9, 0.8)
var _tex: Texture2D = null
var _letter := "?"


func _ready() -> void:
	_life = life
	_t = randf() * 6.0
	_color = _color_for(item_id)
	var data = Db.table("items").get(item_id, {})
	if data.is_empty():
		data = Db.table("gear").get(item_id, {})
	_tex = ItemIcons.texture(item_id, String(data.get("icon", "")))
	_letter = ItemIcons.letter(data, item_id)
	W.room_entered.connect(_reregister)
	_reregister("")


func _color_for(id: String) -> Color:
	var data = Db.table("items").get(id, {})
	var typ := String(data.get("type", ""))
	match typ:
		"orb":
			return Color(0.35, 0.7, 1.0)
		"material":
			return Color(0.95, 0.62, 0.25)
		"ability":
			return Color(0.5, 1.0, 1.0)
		"weapon":
			return Color(1.0, 0.85, 0.4)
		"consumable":
			return Color(0.9, 0.9, 0.8)
	if Db.table("gear").has(id):
		return Color(0.8, 0.6, 1.0)
	return Color(0.9, 0.9, 0.8)


func _physics_process(delta: float) -> void:
	if _taken:
		return
	_t += delta
	var m = G.main
	var p = null
	if m != null:
		p = m.player
	# a flying pickup (orb, scrap) whose bar is full waits on the floor: its life
	# does not run down, so nothing is wasted, and it flies to her once there is room
	_waiting = p != null and _flies() and _full(p)
	if not _waiting:
		_life -= delta
	if _life <= 0.0:
		_despawn()
		return
	queue_redraw()
	if p == null:
		return
	var chest: Vector2 = p.global_position + Vector2(0, -18)
	if _waiting:
		_fly_t = 0.0      # pops out again when it starts flying
		return
	if _flies():
		_fly_to(chest, delta)
	if touch_take:
		if chest.distance_to(global_position) <= T.v("pickup_reach") * 0.66:
			take()
			return


func _flies() -> bool:
	# orbs (MP today; HP and XP orbs when they exist) and scrap fly to her on their own
	return item_id == "scrap" or String(Db.table("items").get(item_id, {}).get("type", "")) == "orb"


func _is_orb() -> bool:
	return _flies()


func _fly_to(chest: Vector2, delta: float) -> void:
	# pops out for orb_hang, then flies to her from anywhere on screen with no
	# button and no distance limit. It speeds up as it goes and is collected when
	# it touches her. A full gauge makes it wait instead (see _physics_process).
	_fly_t += delta
	if _fly_t < T.v("orb_hang"):
		return
	var speed: float = minf(T.v("orb_speed") + T.v("orb_accel") * (_fly_t - T.v("orb_hang")), T.v("orb_speed_max"))
	global_position = global_position.move_toward(chest, speed * delta)
	if chest.distance_to(global_position) <= T.v("pickup_reach") * 0.66:
		take()


func _full(p) -> bool:
	if item_id == "soul_orb":
		return float(p.mp) >= R.max_mp() - 0.01
	if item_id == "scrap":
		var m = G.main
		if m == null or m.loot == null:
			return true
		return R.scrap >= m.loot.scrap_cap() - 0.01
	return false


func take(silent := false) -> bool:
	# take the thing: grant it, leave the registry and free this node. Silent skips
	# the card (the arena's legacy touch rewards keep their old feel for smoke).
	if _taken:
		return false
	var m = G.main
	if m == null or m.loot == null:
		return false
	if not bool(m.loot.grant(item_id, rare)):
		Sfx.play("pickup_refuse")
		return false
	_taken = true
	taken.emit(item_id)
	if m.interact != null:
		m.interact.unregister(self)
	m.loot.live.erase(self)
	queue_free()
	if not silent and not touch_take and show_card and m.card != null:
		m.card.present(item_id)
	return true


func _despawn() -> void:
	if _taken:
		return
	_taken = true
	var m = G.main
	if m != null:
		if m.interact != null:
			m.interact.unregister(self)
		if m.loot != null:
			m.loot.live.erase(self)
	queue_free()


func _reregister(_file_id: String) -> void:
	if _taken or touch_take:
		return
	var m = G.main
	if m == null or m.interact == null:
		return
	m.interact.register(self, "item", "TAKE", Callable(self, "take"), 0.0)


func _draw() -> void:
	var bob := sin(_t * 3.0) * 2.0
	var a := 1.0
	if _waiting:
		a = 0.45 + 0.4 * absf(sin(_t * 4.0))      # blinks slowly while it waits for room
	elif _life < 3.0:
		a = 0.35 + 0.65 * absf(sin(_t * 9.0))
	var c := Color(_color.r, _color.g, _color.b, a)
	# the soft glow stays either way: a halo around a real picture, a halo
	# around the placeholder square when there is no picture yet
	draw_circle(Vector2(0, bob), 8.0, Color(c.r, c.g, c.b, a * 0.18))
	if _tex != null:
		# the item has a picture (assets/items/<id>.png): draw it 32x32,
		# centred on the bob position
		draw_texture_rect(_tex, Rect2(-16.0, bob - 16.0, 32.0, 32.0), false, Color(1.0, 1.0, 1.0, a))
	else:
		# no picture yet: a placeholder square coloured by the item's kind with
		# its first letter. Adding assets/items/<id>.png switches this to the
		# picture with no code change.
		draw_rect(Rect2(-6.0, bob - 6.0, 12.0, 12.0), Color(c.r * 0.4, c.g * 0.4, c.b * 0.4, a), true)
		draw_rect(Rect2(-6.0, bob - 6.0, 12.0, 12.0), c, false, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(-6.0, bob + 3.5), _letter,
			HORIZONTAL_ALIGNMENT_CENTER, 12.0, 8, Color(c.r, c.g, c.b, a))
