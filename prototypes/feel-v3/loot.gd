# PROTOTYPE - NOT FOR PRODUCTION
# The loot system: what an enemy leaves behind. It rolls the enemies.json drops
# with R.rng, adds a soul orb (weak enemies 60%) and machine scrap (more often at
# low health), and spawns the pickup. Rare drops come from the enemy's "rare"
# entry. S2.
extends Node

const Pickup := preload("res://pickup.gd")
const RpgMath := preload("res://rpg_math.gd")

var live: Array = []


func _ready() -> void:
	W.enemy_killed.connect(_on_enemy_killed)


func scrap_cap() -> float:
	return T.v("scrap_max") + R.gear_effect("scrap_gain_mult_key")


func _on_enemy_killed(_en: Node2D, kind: String, at: Vector2, respawned: bool) -> void:
	for d in roll_drops(kind, at, respawned):
		spawn_pickup(String(d.get("item", "")), d.get("at", at), {"rare": bool(d.get("rare", false))})


func roll_drops(kind: String, at: Vector2, respawned: bool) -> Array:
	var out: Array = []
	var e = Db.table("enemies").get(kind, {})
	for d in e.get("drops", []):
		if not (d is Dictionary):
			continue
		var ck := String(d.get("chance_key", ""))
		if ck == "" or not T.data.has(ck):
			continue
		var needs := String(d.get("needs", ""))
		if needs != "" and not R.has(needs):
			continue
		if R.rng.randf() < T.v(ck):
			out.append({"item": String(d.get("item", "")), "at": at})
	# the primary drop rolls first: machine scrap rises as her health falls
	var share := 1.0
	var m = G.main
	var p = m.player if m != null else null
	if p != null:
		share = clampf(float(p.hp) / maxf(1.0, R.max_hp()), 0.0, 1.0)
	var scrap_chance := RpgMath.scrap_chance(T.v("scrap_drop_base"), T.v("scrap_drop_low"), share)
	if R.rng.randf() < scrap_chance:
		out.append({"item": "scrap", "at": at})
	var weak := bool(e.get("weak", false))
	var orb_chance := T.v("soul_orb_chance_weak") if weak else 1.0
	if orb_chance >= 1.0 or R.rng.randf() < orb_chance:
		out.append({"item": "soul_orb", "at": at})
	var rare = e.get("rare", {})
	if rare is Dictionary and rare.has("item"):
		var rk := String(rare.get("chance_key", ""))
		if rk != "" and T.data.has(rk):
			var chance := T.v(rk)
			if respawned:
				chance *= T.v("rare_respawn_mult")
			if String(rare["item"]) == "tank_heart" and R.count("tank_heart") >= int(T.v("tank_heart_max")):
				chance = 0.0
			if R.rng.randf() < chance:
				out.append({"item": String(rare["item"]), "at": at, "rare": true})
	return out


func spawn_pickup(item_id: String, at: Vector2, opts := {}) -> Node2D:
	var m = G.main
	if m == null or m.world == null:
		return null
	var data = Db.table("items").get(item_id, {})
	var p = Pickup.new()
	p.item_id = item_id
	p.touch_take = bool(opts.get("touch_take", data.get("touch_take", false)))
	p.rare = bool(opts.get("rare", data.get("rare", false)))
	p.show_card = bool(opts.get("card", true))
	p.life = float(opts.get("life", T.v("rare_life") if p.rare else T.v("drop_life")))
	p.global_position = at + Vector2(0, -10)
	p.z_index = 6
	m.world.add_child(p)
	live.append(p)
	return p as Node2D


func grant(item_id: String, rare := false) -> bool:
	var m = G.main
	var p = m.player if m != null else null
	var items: Dictionary = Db.table("items")
	if items.has(item_id):
		var data = items[item_id]
		var typ := String(data.get("type", ""))
		if typ == "orb":
			# an orb is always collected: with MP to spare it refills her, and at a
			# full gauge it is simply taken in with nothing to refill
			if p == null:
				return false
			if float(p.mp) < R.max_mp() - 0.01:
				p.gain_mp(T.v("mp_pickup"))
				Sfx.play("pickup")
				if m != null:
					m.number(p.global_position + Vector2(0, -30), int(T.v("mp_pickup")), Color("#5AB4FF"))
			return true
		if typ == "material":
			if R.scrap >= scrap_cap() - 0.01:
				return false
			R.add_scrap(T.v("scrap_per_pickup"))
			Sfx.play("pickup")
			if m != null and p != null:
				m.number(p.global_position + Vector2(0, -30), int(T.v("scrap_per_pickup")), Color("#E8A94A"))
			return true
		if typ == "consumable":
			var cap := 999
			var mk := String(data.get("max_key", ""))
			if mk != "" and T.data.has(mk):
				cap = int(T.v(mk))
			if rare:
				cap = mini(cap, int(T.v("rare_stack_max")))
			if R.count(item_id) >= cap:
				return false
			var before := R.count(item_id)
			R.add_item(item_id, 1)
			return R.count(item_id) > before
		var grants := String(data.get("grants", ""))
		R.set_owned(grants if grants != "" else item_id, true)
		if m != null and item_id == "elegy_013":
			m.has_elegy = true
		elif m != null and item_id == "wall_jump":
			m.has_latch = true
		return true
	var gear: Dictionary = Db.table("gear")
	if gear.has(item_id):
		if R.owned_gear.has(item_id) or R.count(item_id) > 0:
			return false
		R.add_item(item_id, 1)
		if not R.owned_gear.has(item_id):
			R.owned_gear.append(item_id)
		return true
	return false


func clear() -> void:
	for p in live:
		if is_instance_valid(p):
			p.queue_free()
	live.clear()


func move_orbs(_delta: float) -> void:
	# orbs are pickups now; main still calls this
	pass


func place_items(room) -> void:
	# the room's item marks (rooms_meta "marks": type "item") become pickups she takes with Up.
	# Each one is taken once for ever: the flag "got_<file>_<mark>" remembers it.
	var marks_meta: Dictionary = room.meta.get("marks", {})
	for key in marks_meta:
		var mk = marks_meta[key]
		if not (mk is Dictionary) or String(mk.get("type", "")) != "item" or not room.spawns.has(key):
			continue
		var item_id := String(mk.get("item", ""))
		var flag := "got_%s_%s" % [room.file_id, key]
		if item_id == "" or W.flag(flag) or (item_id == "wall_jump" and G.main.has_latch):
			continue
		if not (Db.table("items").has(item_id) or Db.table("gear").has(item_id)):
			continue      # no data yet (the BOLT PISTOL arrives with SEXTON-19, session 4)
		var pk: Node2D = spawn_pickup(item_id, room.spawns[key], {"life": 1.0e9, "touch_take": false})
		if pk != null:
			pk.taken.connect(func(_id): W.set_flag(flag, true))
