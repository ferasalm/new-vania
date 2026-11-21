# PROTOTYPE - NOT FOR PRODUCTION
# Autoload "R". Everything about her progress that must survive a room change:
# level, XP, items and counts, owned and equipped gear, scrap, the quickslot and
# the seeded rng for drops. Her stats grow automatically with the level: every
# level above 1 adds the tuning value data/levels.json names. The formulas live
# in rpg_math.gd; every number is read from tuning through T.
extends Node

signal xp_changed(xp: int, level: int)
signal leveled(level: int)
signal stats_changed()
signal items_changed(id: String, count: int)
signal gear_changed(slot: String, id: String)
signal scrap_changed(value: float)

const RpgMath := preload("res://rpg_math.gd")
const SLOTS := ["harness1", "harness2", "module1", "module2"]
# the two DRIVE modules never add up: one id fits one slot and they never coexist
const DRIVE := ["coupler_034", "regulator_000"]

var level := 1
var xp := 0
var items := {}            # id -> count
var owned_gear: Array = []
var equip := {"harness1": "", "harness2": "", "module1": "", "module2": ""}
var scrap := 0.0
var quickslot := "suture"
var names_seen := {}       # enemy id -> true (LEXICON CORE)
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	reset()


func _player() -> Node:
	# the live player, when there is one (the tests build main after the autoloads)
	if G == null or G.main == null:
		return null
	return G.main.get("player")


func _base(key: String) -> float:
	# a base value named by data/levels.json, read through tuning
	var base: Dictionary = Db.table("levels").get("base", {})
	var tkey := String(base.get(key, ""))
	if tkey != "" and T.data.has(tkey):
		return T.v(tkey)
	return 0.0


func growth(kind: String) -> float:
	# what every level above 1 adds of one kind (hp, en, atk, def), read from
	# data/levels.json; a kind that file does not name adds nothing
	var growths: Dictionary = Db.table("levels").get("growth", {})
	var entry: Dictionary = growths.get(kind, {})
	var tkey := String(entry.get("key", ""))
	if tkey != "" and T.data.has(tkey):
		return float(level - 1) * T.v(tkey)
	return 0.0


func max_hp() -> float:
	# player_hp + growth, plus gear, never below max_hp_floor
	var hp := _base("hp_max_key") + growth("hp") + gear_effect("hp_max_add_key")
	return maxf(T.v("max_hp_floor"), hp)


func max_en() -> float:
	# energy_max + growth, plus gear
	return _base("en_max_key") + growth("en") + gear_effect("en_max_add_key")


func max_mp() -> float:
	# mp_max plus gear only: levels never add MP (a harness can add MP, a module "mag")
	return _base("mp_max_key") + gear_effect("mp_max_add_key") + gear_effect("mag_add_key")


func atk() -> float:
	# weapon damage in percent: 100 + growth, plus gear
	return 100.0 + growth("atk") + gear_effect("atk_add_key")


func def() -> float:
	# percent less damage from enemies: growth plus gear, capped
	return minf(T.v("def_cap"), growth("def") + gear_effect("def_add_key"))


func special_pct() -> float:
	# special damage in percent: the same growth as ATK, so specials follow it
	return 100.0 + growth("atk")


func hit_damage(power: float, special: bool) -> int:
	# a weapon swing uses ATK and the flat DRIVE bonus; a special uses SPC only
	if special:
		return RpgMath.special(power, special_pct())
	var add := gear_effect("atk_add_key")
	return RpgMath.dealt(power, atk() - add, add)


func taken(raw: float, src: String) -> int:
	# a hit on her. A trap keeps its raw number and ignores DEF; a boss hit uses
	# mult 1.0 and (the locked t_math pins this) its raw value; an ordinary enemy
	# hit keeps today's value in S0 (hazard_test pins it); any other named source
	# is area damage, where DEF applies.
	if src == "trap":
		return maxi(1, int(round(raw)))
	if src == "boss":
		return maxi(1, int(round(raw)))
	var mult := 1.0 if src == "enemy" else T.v("area_damage_mult")
	return RpgMath.taken(raw, mult, def())


func award_kill(enemy_id: String, respawned: bool) -> int:
	# the XP for beating an enemy, half (rounded up) when it had come back
	var e: Dictionary = Db.table("enemies").get(enemy_id, {})
	var key := String(e.get("xp_key", ""))
	var amount := 0
	if key != "" and T.data.has(key):
		amount = int(T.v(key))
	if respawned:
		amount = int(ceil(float(amount) * T.v("xp_respawn_mult")))
	add_xp(amount)
	return amount


func add_xp(n: int) -> void:
	# add XP, level up (one signal for every level gained), and refill on a level-up
	if n <= 0:
		return
	var step := T.v("xp_curve_step")
	var cap := int(T.v("level_cap"))
	xp = mini(xp + n, RpgMath.xp_total(cap, step))
	var new_level := RpgMath.level_for(xp, step, cap)
	if new_level > level:
		level = new_level
		if int(T.v("levelup_refill")) == 1:
			_refill()
		leveled.emit(level)
		stats_changed.emit()
	xp_changed.emit(xp, level)


func _refill() -> void:
	# a level-up refills HP, EN and MP to the maximum
	var p := _player()
	if p == null:
		return
	p.hp = max_hp()
	p.energy = max_en()
	p.mp = max_mp()


func has(id: String) -> bool:
	# an ability, weapon or key item she owns (or a fitted gear id)
	if id == "":
		return false
	return count(id) > 0 or owned_gear.has(id)


func set_owned(id: String, on: bool) -> void:
	# give or take away an ability, weapon or key item
	if id == "":
		return
	if on:
		if int(items.get(id, 0)) < 1:
			items[id] = 1
			items_changed.emit(id, 1)
	elif items.has(id):
		items.erase(id)
		items_changed.emit(id, 0)


func count(id: String) -> int:
	# how many of an item she carries
	return int(items.get(id, 0))


func add_item(id: String, n: int = 1) -> int:
	# add items, up to the cap its data file names (Sutures stop at suture_max)
	if id == "" or n <= 0:
		return count(id)
	var cap := 999
	var data: Dictionary = Db.table("items")
	if data.has(id):
		var mk := String(data[id].get("max_key", ""))
		if mk != "" and T.data.has(mk):
			cap = int(T.v(mk))
	items[id] = mini(int(items.get(id, 0)) + n, cap)
	items_changed.emit(id, int(items[id]))
	return int(items[id])


func use_item(id: String) -> bool:
	# use a consumable; a Suture heals and is refused at full health
	if count(id) <= 0:
		return false
	var data: Dictionary = Db.table("items")
	if not data.has(id):
		return false
	var use: Dictionary = data[id].get("use", {})
	var heal_key := String(use.get("heal_hp_key", ""))
	var p := _player()
	if heal_key == "" or p == null or not T.data.has(heal_key):
		return false
	if float(p.hp) >= max_hp() - 0.001:
		return false
	p.hp = minf(max_hp(), float(p.hp) + T.v(heal_key))
	items[id] = int(items[id]) - 1
	items_changed.emit(id, int(items[id]))
	return true


func equip_gear(slot: String, id: String) -> bool:
	# fit a piece of gear. Modules go in module slots, harnesses in harness slots,
	# one id in one slot, the CORE has no slot, and COUPLER and REGULATOR never coexist.
	if not SLOTS.has(slot):
		return false
	if id == "":
		equip[slot] = ""
		_clamp_hp()
		gear_changed.emit(slot, "")
		stats_changed.emit()
		return true
	var gear: Dictionary = Db.table("gear")
	if not gear.has(id):
		return false
	var kind := String(gear[id].get("slot", ""))
	var want := "harness" if slot.begins_with("harness") else "module"
	if kind != want:
		return false
	for s in SLOTS:
		if s != slot and String(equip.get(s, "")) == id:
			return false
	if DRIVE.has(id):
		for s in SLOTS:
			var other := String(equip.get(s, ""))
			if other != id and DRIVE.has(other):
				return false
	equip[slot] = id
	if not owned_gear.has(id):
		owned_gear.append(id)
	if int(items.get(id, 0)) < 1:
		items[id] = 1
	_clamp_hp()
	gear_changed.emit(slot, id)
	stats_changed.emit()
	return true


func _clamp_hp() -> void:
	# losing max HP (COUPLER) lowers the current HP; gaining it never heals
	var p := _player()
	if p != null:
		p.hp = minf(float(p.hp), max_hp())


func gear_effect(effect: String) -> float:
	# the sum of one effect over everything she has fitted
	var total := 0.0
	var gear: Dictionary = Db.table("gear")
	for slot in SLOTS:
		var id := String(equip.get(slot, ""))
		if id == "" or not gear.has(id):
			continue
		var fx: Dictionary = gear[id].get("effects", {})
		var key := String(fx.get(effect, ""))
		if key != "" and T.data.has(key):
			total += T.v(key)
	return total


func add_scrap(v: float) -> void:
	# add scrap, up to the gauge size (S2 adds the tuning key; until then 100)
	var cap := 100.0
	if T.data.has("scrap_max"):
		cap = T.v("scrap_max") + gear_effect("scrap_gain_mult_key")
	scrap = clampf(scrap + v, 0.0, cap)
	scrap_changed.emit(scrap)


func refill_at_terminal() -> void:
	# a working terminal recharges the RESTORE module (S8). Sutures are never
	# refilled (lead ruling 1), so nothing else happens here.
	pass


func snapshot() -> Dictionary:
	# a copy of her whole sheet, for RECALL and the tests
	return {"level": level, "xp": xp,
		"items": items.duplicate(true), "owned_gear": owned_gear.duplicate(), "equip": equip.duplicate(true),
		"scrap": scrap, "quickslot": quickslot, "names_seen": names_seen.duplicate(true)}


func restore(d: Dictionary) -> void:
	# put a snapshot back; an old save's points and alloc are ignored, since
	# every stat now comes from the level
	level = int(d.get("level", 1))
	xp = int(d.get("xp", 0))
	items = d.get("items", {}).duplicate(true)
	owned_gear = d.get("owned_gear", []).duplicate()
	equip = _equip_dict(d.get("equip", {}))
	scrap = float(d.get("scrap", 0.0))
	quickslot = String(d.get("quickslot", "suture"))
	names_seen = d.get("names_seen", {}).duplicate(true)
	xp_changed.emit(xp, level)
	stats_changed.emit()


func reset() -> void:
	# back to a fresh sheet at start_level (the tests call this between checks)
	level = int(T.v("start_level")) if T.data.has("start_level") else 1
	xp = 0
	items = {}
	owned_gear = []
	equip = _equip_dict({})
	scrap = 0.0
	quickslot = "suture"
	names_seen = {}
	xp_changed.emit(xp, level)
	stats_changed.emit()


func _equip_dict(d: Dictionary) -> Dictionary:
	# every slot always exists
	var out := {}
	for s in SLOTS:
		out[s] = String(d.get(s, ""))
	return out


func debug_set(d: Dictionary) -> void:
	# the test hook: set only the fields that are named (an old save's points and
	# alloc are ignored)
	for k in d:
		match String(k):
			"level":
				level = int(d[k])
			"xp":
				xp = int(d[k])
			"items":
				items = d[k].duplicate(true)
			"owned_gear":
				owned_gear = d[k].duplicate()
			"equip":
				equip = _equip_dict(d[k])
			"scrap":
				scrap = float(d[k])
			"quickslot":
				quickslot = String(d[k])
			"names_seen":
				names_seen = d[k].duplicate(true)
	stats_changed.emit()


func debug_seed(seed: int) -> void:
	# make every drop roll reproducible
	rng.seed = seed
