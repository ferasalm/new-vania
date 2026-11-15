# PROTOTYPE - NOT FOR PRODUCTION
# The player body. Flat rects, feet-anchored, hand-rolled AABB against Rect2 solids.
# Feel knobs the contracts do not name are PROTO (startup/active/recovery pacing).
extends Node2D

const W := 16.0
const H := 40.0
const SPEED := 132.0
const DASH_SPEED := 330.0
const DASH_MS := 150.0
const DASH_CD_MS := 420.0
const GRAVITY := 1100.0
const JUMP_V := -330.0

# PROTO pacing: the strike arc. The contract fixes the window (ATTACK_WINDOW_MS 200).
const LIGHT := {"startup": 60.0, "active": 90.0, "recovery": 120.0}
const HEAVY := {"startup": 110.0, "active": 100.0, "recovery": 170.0}
const COUNTER_WINDOW := 300.0

var solids: Array = []          # Array[Rect2] — world-space solid rects
var hp := float(K.PLAYER_MAX_HP)
var hp_max := float(K.PLAYER_MAX_HP)
var facing := 1
var vel := Vector2.ZERO
var on_ground := false

var state := "idle"             # idle | attack | counter | knockdown | dead
var state_ms := 0.0
var attack_kind := "light"
var attack_raw := K.ATK1_DAMAGE
var attack_power := 1
var strike_id := 0
var hit_done := false
var counter_heavy := false
var counter_done := false

var invuln_ms := 0.0
var dash_ms := 0.0
var dash_cd_ms := 0.0
var flash_ms := 0.0
var locked := false
var combat := true
var down_ms := 0.0


func _ready() -> void:
	z_index = 20


func reset_body(at: Vector2) -> void:
	position = at
	vel = Vector2.ZERO
	hp = hp_max
	state = "idle"
	state_ms = 0.0
	locked = false
	invuln_ms = 0.0


func _physics_process(delta: float) -> void:
	if K.frozen:
		return
	var ms := delta * 1000.0
	if invuln_ms > 0.0:
		invuln_ms = maxf(0.0, invuln_ms - ms)
	if dash_cd_ms > 0.0:
		dash_cd_ms = maxf(0.0, dash_cd_ms - ms)
	if flash_ms > 0.0:
		flash_ms = maxf(0.0, flash_ms - ms)

	if state == "dead" or locked:
		vel.x = move_toward(vel.x, 0.0, 900.0 * delta)
		_integrate(delta)
		queue_redraw()
		return

	state_ms += ms
	match state:
		"knockdown":
			down_ms += ms
			vel.x = move_toward(vel.x, 0.0, 700.0 * delta)
			if down_ms >= K.KNOCKDOWN_TOTAL_MS:
				state = "idle"
				state_ms = 0.0
				down_ms = 0.0
		"attack":
			_tick_attack()
		"counter":
			if state_ms >= COUNTER_WINDOW:
				state = "idle"
				state_ms = 0.0
				counter_done = false
		_:
			_read_input(delta, ms)

	if state != "attack" and state != "counter":
		vel.x = move_toward(vel.x, 0.0, 1400.0 * delta)
		if dash_ms > 0.0:
			dash_ms -= ms
			vel.x = facing * DASH_SPEED
			if dash_ms <= 0.0:
				dash_ms = 0.0
	_integrate(delta)
	queue_redraw()


func _read_input(delta: float, ms: float) -> void:
	if not combat:
		var dir := 0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			dir -= 1
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			dir += 1
		if dir != 0:
			facing = dir
			vel.x = dir * SPEED
		if (Input.is_physical_key_pressed(KEY_SPACE)) and on_ground:
			vel.y = JUMP_V
		return

	var dir := 0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir += 1
	if dir != 0:
		facing = dir
		if dash_ms <= 0.0:
			vel.x = dir * SPEED
	if Input.is_physical_key_pressed(KEY_SPACE) and on_ground:
		vel.y = JUMP_V


func _tick_attack() -> void:
	var cfg: Dictionary = LIGHT if attack_kind == "light" else HEAVY
	var a: float = cfg["startup"]
	var b: float = a + cfg["active"]
	if state_ms >= a + cfg["active"] + cfg["recovery"]:
		state = "idle"
		state_ms = 0.0
		hit_done = false
	elif state_ms > a and state_ms <= b:
		pass


# ── input verbs (the scene calls these so it can lock the body) ─────────────
func try_light() -> void:
	if not combat or state != "idle" or locked:
		return
	state = "attack"
	state_ms = 0.0
	attack_kind = "light"
	attack_raw = K.ATK1_DAMAGE
	attack_power = 1
	strike_id += 1
	hit_done = false


func try_heavy() -> void:
	if not combat or state != "idle" or locked:
		return
	state = "attack"
	state_ms = 0.0
	attack_kind = "heavy"
	attack_raw = K.ATK2_DAMAGE
	attack_power = 2
	strike_id += 1
	hit_done = false


func try_counter() -> void:
	if not combat or locked:
		return
	if state == "counter":
		counter_heavy = true     # K inside the stance upgrades 3 -> 6
		return
	if state != "idle":
		return
	state = "counter"
	state_ms = 0.0
	counter_heavy = false
	counter_done = false


func try_dash() -> void:
	if not combat or locked or dash_cd_ms > 0.0 or state == "knockdown":
		return
	dash_ms = DASH_MS
	dash_cd_ms = DASH_CD_MS
	invuln_ms = maxf(invuln_ms, K.BACKDASH_IFRAME_MS)


# ── the read surface the scenes consume ─────────────────────────────────────
func is_idle() -> bool:
	return state == "idle"


func is_attacking() -> bool:
	return state == "attack"


func is_countering() -> bool:
	return state == "counter"


func is_knocked_down() -> bool:
	return state == "knockdown"


func is_dead() -> bool:
	return state == "dead"


func is_invulnerable() -> bool:
	return invuln_ms > 0.0


func counter_value() -> int:
	return K.counter_output(K.ATK2_DAMAGE if counter_heavy else K.ATK1_DAMAGE)


func attack_active() -> bool:
	if state != "attack":
		return false
	var cfg: Dictionary = LIGHT if attack_kind == "light" else HEAVY
	var a: float = cfg["startup"]
	return state_ms > a and state_ms <= a + cfg["active"]


func hitbox() -> Rect2:
	if not attack_active():
		return Rect2()
	var x := position.x + (4.0 if facing > 0 else -34.0)
	return Rect2(x, position.y - H + 4.0, 30.0, 26.0)


func hurtbox() -> Rect2:
	if state == "knockdown":
		return Rect2(position.x - 22.0, position.y - 14.0, 44.0, 14.0)
	return Rect2(position.x - W * 0.5, position.y - H, W, H)


func consume_strike() -> void:
	hit_done = true


# ── damage in ───────────────────────────────────────────────────────────────
func take_hit(power: int, from_x: float, dmg: int) -> bool:
	if state == "dead" or locked:
		return false
	if invuln_ms > 0.0:
		return false
	hp = maxf(0.0, hp - float(dmg))
	flash_ms = 120.0
	var dir := 1 if from_x >= position.x else -1
	if K.knocks_down(power):
		state = "knockdown"
		state_ms = 0.0
		down_ms = 0.0
		vel.x = dir * 170.0
		vel.y = -60.0
	else:
		vel.x = dir * 70.0
	if hp <= 0.0:
		state = "dead"
		vel = Vector2.ZERO
	return true


func revive(pct: float) -> void:
	hp = clampf(ceil(hp_max * pct), 1.0, hp_max)
	state = "idle"
	state_ms = 0.0
	down_ms = 0.0
	invuln_ms = K.REVIVE_IFRAME_MS
	flash_ms = 0.0


func restore_full() -> void:
	hp = hp_max


func _integrate(delta: float) -> void:
	vel.y += GRAVITY * delta
	# x
	position.x += vel.x * delta
	for r in solids:
		var hb := hurtbox()
		if hb.intersects(r):
			if vel.x > 0.0:
				position.x = r.position.x - W * 0.5 - 0.1
			elif vel.x < 0.0:
				position.x = r.position.x + r.size.x + W * 0.5 + 0.1
			vel.x = 0.0
	# y
	on_ground = false
	position.y += vel.y * delta
	for r in solids:
		var hb := hurtbox()
		if hb.intersects(r):
			if vel.y > 0.0:
				position.y = r.position.y
				on_ground = true
			else:
				position.y = r.position.y + r.size.y + H
			vel.y = 0.0


# ── draw ───────────────────────────────────────────────────────────────────
func _draw() -> void:
	var body := Rect2(-W * 0.5, -H, W, H)
	if state == "knockdown" or state == "dead":
		body = Rect2(-22.0, -14.0, 44.0, 14.0)

	var c := K.C_BONE
	if flash_ms > 0.0:
		c = Color(1, 1, 1, 1)
	if state == "dead":
		c = K.C_BONE_DIM
	draw_rect(body, c)
	draw_rect(body, Color(0, 0, 0, 0.45), false, 1.0)

	if state != "knockdown" and state != "dead":
		# the facing mark: a 1px vertical seam on the leading edge
		var sx := W * 0.5 - 2.0 if facing > 0 else -W * 0.5 + 1.0
		draw_rect(Rect2(sx, -H + 8.0, 1.0, 22.0), Color(0, 0, 0, 0.5))

	if invuln_ms > 0.0:
		# the hum, not a shield bubble: a thin cyan outline at breathing alpha
		var a := 0.30 + 0.25 * sin(Time.get_ticks_msec() * 0.012)
		draw_rect(body.grow(2.0), Color(K.C_CYAN.r, K.C_CYAN.g, K.C_CYAN.b, a), false, 1.0)

	if state == "counter":
		# the clashable window: a cyan blade held out front
		var x := 6.0 if facing > 0 else -8.0
		var a2 := 0.55 + 0.35 * sin(Time.get_ticks_msec() * 0.02)
		var col := K.C_CYAN
		col.a = a2
		draw_rect(Rect2(x, -H + 4.0, 2.0, 26.0), col)

	if attack_active():
		var hb0 := hitbox()
		var hb := Rect2(hb0.position - position, hb0.size)
		var ac := K.C_AMBER
		ac.a = 0.30
		draw_rect(hb, ac)
		draw_rect(Rect2(hb.position.x if facing > 0 else hb.position.x, hb.position.y + 6.0,
			hb.size.x, 2.0), K.C_AMBER)
