# PROTOTYPE - NOT FOR PRODUCTION
# An item waiting in the world: it glows and bobs, it is taken with Up, and a
# soul orb or scrap is taken by touch. S2.
extends Node2D

signal taken(item_id: String)

var item_id := ""
var touch_take := false
var rare := false
var show_card := true
var life := 12.0

var _life := 12.0
var _t := 0.0
var _taken := false
var _color := Color(0.9, 0.9, 0.8)


func _ready() -> void:
	_life = life
	_t = randf() * 6.0
	_color = _color_for(item_id)
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
	_life -= delta
	if _life <= 0.0:
		_despawn()
		return
	queue_redraw()
	var m = G.main
	var p = null
	if m != null:
		p = m.player
	if p == null:
		return
	var chest: Vector2 = p.global_position + Vector2(0, -18)
	if item_id == "soul_orb" and T.v("orb_magnet") > 0.0 and not _full(p):
		if chest.distance_to(global_position) <= T.v("orb_magnet"):
			global_position = global_position.move_toward(chest, T.v("orb_speed") * delta)
	if touch_take:
		if _full(p):
			return
		if chest.distance_to(global_position) <= T.v("pickup_reach") * 0.66:
			take()
			return


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
	if _life < 3.0:
		a = 0.35 + 0.65 * absf(sin(_t * 9.0))
	var c := Color(_color.r, _color.g, _color.b, a)
	draw_circle(Vector2(0, bob), 8.0, Color(c.r, c.g, c.b, a * 0.18))
	var pts := PackedVector2Array([Vector2(0, bob - 6), Vector2(5, bob), Vector2(0, bob + 6), Vector2(-5, bob)])
	draw_colored_polygon(pts, Color(c.r * 0.4, c.g * 0.4, c.b * 0.4, a))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), c, 1.0)
