# PROTOTYPE - NOT FOR PRODUCTION
# The tier dummy. Three tiers (hp 6/12/24, awards 3/7/14) that telegraph one strike
# so the clash, the counter and the knockdown can be felt. Pacing is PROTO.
extends Node2D

const AGGRO := 120.0

var tier := 0
var tier_name := "HUSK"
var hp := 6.0
var hp_max := 6.0
var award := 3
var power := 1
var reach := 34.0
var telegraph_ms := 620.0
var active_ms := 200.0
var recovery_ms := 620.0

var state := "idle"      # idle | telegraph | active | recovery | stagger | dead
var state_ms := 0.0
var strike_id := 0
var hit_done := false
var facing := -1
var flash_ms := 0.0
var dead_t := 0.0
var cooldown_ms := 400.0
var home := Vector2.ZERO


func setup(t: int, at: Vector2) -> void:
	tier = t
	var d: Dictionary = K.TIERS[t]
	tier_name = d["name"]
	hp_max = float(d["hp"])
	hp = hp_max
	award = int(d["award"])
	power = 1 if t < 2 else 2
	reach = 30.0 + t * 6.0
	position = at
	home = at
	z_index = 15


func _ready() -> void:
	z_index = 15


func _physics_process(delta: float) -> void:
	if K.frozen:
		return
	var ms := delta * 1000.0
	if flash_ms > 0.0:
		flash_ms = maxf(0.0, flash_ms - ms)
	if state == "dead":
		dead_t += ms
		queue_redraw()
		return
	if cooldown_ms > 0.0:
		cooldown_ms -= ms
	state_ms += ms
	match state:
		"idle":
			# a slow drift back to the post — the dummy holds its ground
			position = position.lerp(home, minf(1.0, delta * 2.0))
			if cooldown_ms <= 0.0 and _player_ref and _player_ref.position.distance_to(position) < AGGRO:
				facing = 1 if _player_ref.position.x > position.x else -1
				state = "telegraph"
				state_ms = 0.0
				strike_id += 1
				hit_done = false
		"telegraph":
			if state_ms >= telegraph_ms:
				state = "active"
				state_ms = 0.0
		"active":
			if state_ms >= active_ms:
				state = "recovery"
				state_ms = 0.0
		"recovery":
			if state_ms >= recovery_ms:
				state = "idle"
				state_ms = 0.0
				cooldown_ms = 700.0
		"stagger":
			if state_ms >= K.BOSS_COUNTER_STAGGER_MS:
				state = "idle"
				state_ms = 0.0
				cooldown_ms = 500.0
	queue_redraw()


var _player_ref: Node2D = null


func watch(p: Node2D) -> void:
	_player_ref = p


func is_dead() -> bool:
	return state == "dead"


func stagger(ms: float) -> void:
	if state == "dead":
		return
	state = "stagger"
	state_ms = 0.0
	telegraph_ms = maxf(telegraph_ms, 0.0)


func active_hitbox() -> Rect2:
	if state != "active" or hit_done:
		return Rect2()
	var w := 34.0
	var x := position.x + (2.0 if facing > 0 else -2.0 - w)
	return Rect2(x, position.y - 40.0, w, 30.0)


func consume_strike() -> void:
	hit_done = true


func hurtbox() -> Rect2:
	var w := 18.0 + tier * 3.0
	var h := 34.0 + tier * 4.0
	return Rect2(position.x - w * 0.5, position.y - h, w, h)


func take_damage(dmg: int) -> bool:
	if state == "dead":
		return false
	hp = maxf(0.0, hp - float(dmg))
	flash_ms = 100.0
	if hp <= 0.0:
		state = "dead"
		state_ms = 0.0
		dead_t = 0.0
		return true
	return false


func _draw() -> void:
	var hb := hurtbox()
	var local := Rect2(hb.position - position, hb.size)
	if state == "dead":
		var a := clampf(1.0 - dead_t / 900.0, 0.0, 1.0)
		draw_rect(Rect2(local.position.x, local.position.y + local.size.y - 6.0, local.size.x, 6.0),
			Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, a * 0.7))
		return

	var c := K.C_BONE_DIM
	if state == "telegraph":
		# the telegraph: a value flash + a shape lean (never an opacity pulse)
		c = K.C_BONE
		if int(state_ms / 90.0) % 2 == 0:
			c = Color(1, 1, 1, 1)
		var lean := 3.0 * facing
		local.position.x += lean
	if state == "active":
		c = K.C_AMBER
	if flash_ms > 0.0:
		c = Color(1, 1, 1, 1)
	if state == "stagger":
		c = Color(K.C_CYAN.r, K.C_CYAN.g, K.C_CYAN.b, 0.7)

	draw_rect(local, c)
	draw_rect(local, Color(0, 0, 0, 0.45), false, 1.0)
	if tier >= 1:
		draw_rect(Rect2(local.position.x + 3.0, local.position.y + 6.0, local.size.x - 6.0, 1.0),
			Color(0, 0, 0, 0.35))
	if tier >= 2:
		draw_rect(Rect2(local.position.x + 3.0, local.position.y + 10.0, local.size.x - 6.0, 1.0),
			Color(0, 0, 0, 0.35))

	if state == "active":
		var hbx0 := active_hitbox()
		var hbx := Rect2(hbx0.position - position, hbx0.size)
		draw_rect(hbx, Color(K.C_AMBER.r, K.C_AMBER.g, K.C_AMBER.b, 0.22))
		draw_rect(Rect2(hbx.position.x, hbx.position.y + 12.0, hbx.size.x, 2.0), K.C_AMBER)

	# the tier's hp pips
	var pips := int(hp_max)
	var pw := maxf(2.0, (local.size.x) / float(pips))
	for i in pips:
		var on := i < int(hp)
		var pc := K.C_BONE if on else Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.25)
		draw_rect(Rect2(local.position.x + i * pw, local.position.y - 6.0, maxf(1.0, pw - 1.0), 3.0), pc)
