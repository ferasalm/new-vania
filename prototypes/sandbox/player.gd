# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# PANDORA — the body. Real frames (chroma-keyed from the concept art), feet-anchored,
# hand-rolled AABB against Rect2 solids.
#
# THE ONE BUTTON: the scene classifies the press (strike / clash / counter) because
# the scene is what knows the enemy's clock; the body only knows how to wear the
# three poses. See fight.gd::_on_press for the ladder.
extends Node2D

const Assets = preload("res://assets.gd")

const W := 26.0
const H := 100.0
const SPEED := 150.0
const DASH_SPEED := 340.0
const DASH_MS := 150.0
const DASH_CD_MS := 420.0
const GRAVITY := 1250.0
const JUMP_V := -380.0

# PROTO pacing: the strike arc. The contract fixes the window (ATTACK_WINDOW_MS 200).
const STRIKE := {"startup": 60.0, "active": 90.0, "recovery": 120.0}
const CLASH_MS := 140.0
const COUNTER_MS := 220.0

var solids: Array = []          # Array[Rect2] — world-space solid rects
var hp := float(K.PLAYER_MAX_HP)
var hp_max := float(K.PLAYER_MAX_HP)
var facing := 1
var vel := Vector2.ZERO
var on_ground := false

var state := "idle"             # idle | strike | clash | counter | knockdown | dead
var state_ms := 0.0
var strike_id := 0
var hit_done := false

var invuln_ms := 0.0
var dash_ms := 0.0
var dash_cd_ms := 0.0
var flash_ms := 0.0
var locked := false
var combat := true
var down_ms := 0.0
var fall_ms := 0.0              # the fall fade (no damage, no death)

var spr: AnimatedSprite2D
var slash: AnimatedSprite2D


func _ready() -> void:
	z_index = 20
	spr = Assets.sheet({
		"idle": {"prefix": "pandora/idle", "n": Assets.PANDORA["idle"], "fps": 9.0},
		"dash": {"prefix": "pandora/dash", "n": Assets.PANDORA["dash"], "fps": 16.0},
		"jump": {"prefix": "pandora/jump", "n": Assets.PANDORA["jump"], "fps": 9.0, "loop": false},
	})
	spr.scale = Vector2(K.PLAYER_SCALE, K.PLAYER_SCALE)
	add_child(spr)
	spr.play("idle")

	slash = Assets.strip("fx/slash", Assets.FX["slash"], 22.0, 0)
	slash.scale = Vector2(1.6, 1.6)
	slash.offset = Vector2(-32, -32)
	slash.z_index = 3
	slash.visible = false
	add_child(slash)


func reset_body(at: Vector2) -> void:
	position = at
	vel = Vector2.ZERO
	hp = hp_max
	state = "idle"
	state_ms = 0.0
	locked = false
	invuln_ms = 0.0
	fall_ms = 0.0


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
	if fall_ms > 0.0:
		fall_ms = maxf(0.0, fall_ms - ms)

	if state == "dead" or locked:
		vel.x = move_toward(vel.x, 0.0, 900.0 * delta)
		_integrate(delta)
		_animate()
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
		"strike":
			if state_ms >= STRIKE["startup"] + STRIKE["active"] + STRIKE["recovery"]:
				state = "idle"
				state_ms = 0.0
				hit_done = false
		"clash":
			if state_ms >= CLASH_MS:
				state = "idle"
				state_ms = 0.0
		"counter":
			if state_ms >= COUNTER_MS:
				state = "idle"
				state_ms = 0.0
		_:
			_read_input(delta, ms)

	if state != "strike" and state != "counter":
		vel.x = move_toward(vel.x, 0.0, 1400.0 * delta)
		if dash_ms > 0.0:
			dash_ms -= ms
			vel.x = facing * DASH_SPEED
			if dash_ms <= 0.0:
				dash_ms = 0.0
	_integrate(delta)
	_animate()
	queue_redraw()


func _read_input(delta: float, ms: float) -> void:
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


# ── the three poses (the scene chooses which) ───────────────────────────────
func do_strike() -> void:
	if state != "idle" or locked or not combat:
		return
	state = "strike"
	state_ms = 0.0
	strike_id += 1
	hit_done = false
	_flash_slash(K.C_CYAN, 1.0)


func do_clash() -> void:
	if locked or not combat:
		return
	state = "clash"
	state_ms = 0.0
	_flash_slash(Color(1, 1, 1, 1), 1.25)


func do_counter() -> void:
	if locked or not combat:
		return
	state = "counter"
	state_ms = 0.0
	_flash_slash(K.C_ICE, 1.5)


func _flash_slash(c: Color, s: float) -> void:
	if slash == null:
		return
	slash.visible = true
	slash.modulate = c
	slash.scale = Vector2(1.6 * s, 1.6 * s)
	slash.position = Vector2(facing * 22.0, -H * 0.55)
	slash.flip_h = facing < 0
	slash.play("run")
	var t := create_tween()
	t.tween_interval(0.16)
	t.tween_callback(func(): slash.visible = false)


func try_dash() -> void:
	if not combat or locked or dash_cd_ms > 0.0 or state != "idle":
		return
	dash_ms = DASH_MS
	dash_cd_ms = DASH_CD_MS
	invuln_ms = maxf(invuln_ms, K.BACKDASH_IFRAME_MS)


# ── the read surface the scenes consume ─────────────────────────────────────
func is_idle() -> bool:
	return state == "idle"


func is_attacking() -> bool:
	return state == "strike"


func is_clashing() -> bool:
	return state == "clash"


func is_countering() -> bool:
	return state == "counter"


func is_knocked_down() -> bool:
	return state == "knockdown"


func is_dead() -> bool:
	return state == "dead"


func is_invulnerable() -> bool:
	return invuln_ms > 0.0


func counter_value() -> int:
	return K.counter_output(K.COUNTER_RAW)


func attack_active() -> bool:
	if state != "strike":
		return false
	var a: float = STRIKE["startup"]
	return state_ms > a and state_ms <= a + STRIKE["active"]


func hitbox() -> Rect2:
	if not attack_active():
		return Rect2()
	var reach := 46.0
	var x := position.x + (4.0 if facing > 0 else -4.0 - reach)
	return Rect2(x, position.y - H + 6.0, reach, 66.0)


func hurtbox() -> Rect2:
	if state == "knockdown":
		return Rect2(position.x - 30.0, position.y - 22.0, 60.0, 22.0)
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
	var dir := -1 if from_x >= position.x else 1
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
	locked = false
	vel = Vector2.ZERO
	invuln_ms = K.REVIVE_IFRAME_MS
	flash_ms = 0.0


func restore_full() -> void:
	hp = hp_max


func teleport(at: Vector2) -> void:
	position = at
	vel = Vector2.ZERO
	state = "idle"
	state_ms = 0.0
	down_ms = 0.0


func _integrate(delta: float) -> void:
	vel.y += GRAVITY * delta
	position.x += vel.x * delta
	for r in solids:
		var hb := hurtbox()
		if hb.intersects(r):
			if vel.x > 0.0:
				position.x = r.position.x - hb.size.x * 0.5 - 0.1
			elif vel.x < 0.0:
				position.x = r.position.x + r.size.x + hb.size.x * 0.5 + 0.1
			vel.x = 0.0
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


func _animate() -> void:
	if spr == null:
		return
	spr.flip_h = facing < 0
	slash.flip_h = facing < 0
	if state == "knockdown" or state == "dead":
		spr.rotation = 1.35 * facing
		spr.position = Vector2(0, -6)
		if spr.animation != "idle":
			spr.play("idle")
		return
	spr.rotation = 0.0
	spr.position = Vector2.ZERO
	var want := "idle"
	if dash_ms > 0.0:
		want = "dash"
	elif not on_ground:
		want = "jump"
	if spr.animation != want:
		spr.play(want)
	if flash_ms > 0.0:
		spr.modulate = Color(1.6, 1.6, 1.6, 1.0)
	elif state == "counter":
		spr.modulate = Color(1.15, 1.25, 1.3, 1.0)
	else:
		spr.modulate = Color(1, 1, 1, 1)
	if invuln_ms > 0.0:
		spr.modulate.a = 0.55 + 0.35 * sin(Time.get_ticks_msec() * 0.012)


# ── draw (only what the sprite cannot say: the shadow, the fade) ────────────
func _draw() -> void:
	if state != "knockdown" and state != "dead":
		draw_set_transform(Vector2(0, 2), 0.0, Vector2(1, 0.32))
		draw_circle(Vector2.ZERO, 17.0, Color(0, 0, 0, 0.28))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if fall_ms > 0.0:
		var a: float = clampf(fall_ms / K.FALL_FADE_MS, 0.0, 1.0)
		draw_rect(Rect2(-40, -140, 80, 150), Color(0.02, 0.02, 0.02, a * 0.9))
