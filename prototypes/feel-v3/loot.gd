# PROTOTYPE - NOT FOR PRODUCTION
# The loot system: what an enemy leaves behind. S0 carries the seam (spawn_pickup,
# roll_drops with R.rng, live) and today's blue MP orb, moved here unchanged.
# S2 replaces the body with orbs, scrap, Sutures and the pickup card.
extends Node

var live: Array = []       # pickups waiting in the room
var orbs: Array = []       # blue MP orbs: {node, wait}


func _ready() -> void:
	W.enemy_killed.connect(_on_enemy_killed)


func _on_enemy_killed(_en: Node2D, kind: String, at: Vector2, respawned: bool) -> void:
	# today's drop: a chance of one blue orb where the enemy fell
	if respawned:
		return
	if R.rng.randf() < T.v("mp_drop_chance"):
		drop_orb(at)


func roll_drops(kind: String, at: Vector2, respawned: bool) -> Array:
	# the deterministic drop roll: one R.rng roll per entry in enemies.json.
	# A returned enemy rolls at half chance in S2 (rare_respawn_mult); S0 has no
	# such key yet, so the roll is the same and the flag is kept for the caller.
	var out: Array = []
	var e: Dictionary = Db.table("enemies").get(kind, {})
	for d in e.get("drops", []):
		if not (d is Dictionary):
			continue
		var ck := String(d.get("chance_key", ""))
		if ck == "" or not T.data.has(ck):
			continue
		if R.rng.randf() < T.v(ck):
			out.append({"item": String(d.get("item", "")), "at": at})
	return out


func spawn_pickup(item_id: String, at: Vector2, opts := {}) -> Node2D:
	# put an item in the world (S2 gives it its glow and its card; S0 is the seam)
	var p := Pickup.new()
	p.item_id = item_id
	p.touch_take = bool(Db.table("items").get(item_id, {}).get("touch_take", false))
	p.global_position = at
	p.z_index = 6
	G.main.world.add_child(p)
	live.append(p)
	return p


func drop_orb(at: Vector2) -> void:
	# a blue MP orb: a small diamond that hangs, then flies to her
	var o := Polygon2D.new()
	o.polygon = PackedVector2Array([Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0)])
	o.color = Color("#5AB4FF")
	o.global_position = at
	o.z_index = 6
	G.main.world.add_child(o)
	orbs.append({"node": o, "wait": T.v("orb_hang")})


func move_orbs(delta: float) -> void:
	# an orb hangs for a moment, then flies to her
	var player: Node2D = G.main.player
	var target: Vector2 = player.global_position + Vector2(0, -18)
	for ob in orbs.duplicate():
		var o: Polygon2D = ob["node"]
		if ob["wait"] > 0.0:
			ob["wait"] -= delta
			continue
		o.global_position = o.global_position.move_toward(target, T.v("orb_speed") * delta)
		if o.global_position.distance_to(target) < 6.0:
			orbs.erase(ob)
			o.queue_free()
			player.gain_mp(T.v("mp_pickup"))
			Sfx.play("pickup")
			G.main.number(target + Vector2(0, -20), int(T.v("mp_pickup")), Color("#5AB4FF"))


func clear() -> void:
	# the room is being freed
	for ob in orbs:
		if is_instance_valid(ob["node"]):
			ob["node"].queue_free()
	orbs.clear()
	for p in live:
		if is_instance_valid(p):
			p.queue_free()
	live.clear()


# An item waiting in the world. S2 gives it the bob, the glow and the card.
class Pickup extends Node2D:
	signal taken(item_id: String)

	var item_id := ""
	var touch_take := false

	func take() -> void:
		taken.emit(item_id)
		if G.main.loot != null:
			G.main.loot.live.erase(self)
		queue_free()
