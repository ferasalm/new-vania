# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does committed SotN-weight combat (combo + clash + deflect) feel rewarding?
# Date: 2026-11-11
# Melee dummy — approach / windup / strike loop; participates in the clash power-comparison.
# Telegraph doctrine: whole body color-flash amber (light) or red (heavy) + rising lean back.
# Contract per SPEC.md: hurt(dmg, source_power, from_player_attack) resolves every clash kind.

class_name ProtoEnemyMelee
extends CharacterBody2D

enum State { IDLE, APPROACH, WINDUP, STRIKE, RECOVER, COOLDOWN, STUNNED, DEAD }

var main: Node
var dead := false
var hp: int = Tunables.MELEE_HP
var my_power := 1        # 1 = light strike, 2 = heavy — set on entering WINDUP
var face := 1

var _state: int = State.IDLE
var _state_t := 0.0
var _windup_total := 0.0
var _windup_heavy := false
var _lean := 0.0         # 0..1 windup lean progress
var _flash := 0.0
var _strike_hit_done := false

# Local consts — not in Tunables (prototype only).
const ENGAGE_X := 46.0          # stop distance; strike reach front edge ≈ 42px
const LUNGE_X := 40.0           # px traveled during the strike's active window
const KNOCKBACK_X := 90.0
const POP_Y := -60.0
const STAGGER_FRICTION := 600.0
const FLASH_TIME := 0.12
const RESPAWN_DELAY := 1.5

func _ready() -> void:
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if dead:
		return
	if _flash > 0.0:
		_flash -= delta
	var p: Variant = main.get("player")
	if p == null:
		return
	var dx: float = p.global_position.x - global_position.x
	var dist := absf(dx)

	match _state:
		State.IDLE:
			velocity.x = 0.0
			if dist < Tunables.MELEE_AGGRO:
				_state = State.APPROACH
		State.APPROACH:
			if absf(dx) > 1.0:
				face = 1 if dx > 0.0 else -1
			velocity.x = face * Tunables.MELEE_WALK
			if dist <= ENGAGE_X:
				velocity.x = 0.0
				_begin_windup()
		State.WINDUP:
			velocity.x = 0.0
			_lean = clampf(1.0 - _state_t / _windup_total, 0.0, 1.0)
			_state_t -= delta
			if _state_t <= 0.0:
				_state = State.STRIKE
				_state_t = Tunables.MELEE_ACTIVE
				_strike_hit_done = false
				velocity.x = face * (LUNGE_X / Tunables.MELEE_ACTIVE)
		State.STRIKE:
			_state_t -= delta
			if not _strike_hit_done:
				_try_strike(p)
			if _state_t <= 0.0:
				_state = State.RECOVER
				_state_t = Tunables.MELEE_RECOVER
				velocity.x = 0.0
		State.RECOVER:
			velocity.x = 0.0
			_state_t -= delta
			if _state_t <= 0.0:
				_state = State.COOLDOWN
				_state_t = Tunables.MELEE_COOLDOWN
		State.COOLDOWN:
			_state_t -= delta
			if _state_t <= 0.0:
				_state = State.APPROACH if dist < Tunables.MELEE_AGGRO else State.IDLE
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, STAGGER_FRICTION * delta)
			_state_t -= delta
			if _state_t <= 0.0:
				_lean = 0.0
				_state = State.APPROACH if dist < Tunables.MELEE_AGGRO else State.IDLE

	# grounded walker
	if global_position.y < Tunables.FLOOR_Y:
		velocity.y += Tunables.GRAVITY * delta
	move_and_slide()
	if global_position.y > Tunables.FLOOR_Y:
		global_position.y = Tunables.FLOOR_Y
		velocity.y = 0.0
	queue_redraw()

func _begin_windup() -> void:
	_windup_heavy = randf() < 0.3  # 30% heavy / 70% light
	my_power = 2 if _windup_heavy else 1
	_state = State.WINDUP
	_windup_total = Tunables.MELEE_HEAVY_WINDUP if _windup_heavy else Tunables.MELEE_LIGHT_WINDUP
	_state_t = _windup_total
	_lean = 0.0
	velocity.x = 0.0

func _try_strike(p: Variant) -> void:
	var player_rect := Rect2(p.global_position + Vector2(-10.0, -34.0), Vector2(20, 44))
	var strike := Rect2(global_position + Vector2(10.0 if face > 0 else -42.0, -28.0), Vector2(32, 36))
	if not strike.intersects(player_rect):
		return
	_strike_hit_done = true
	# If the player is mid-swing, the power comparison resolves inside hurt() when the
	# player's hitbox connects — never apply strike damage on top of a clash.
	if p.is_attack_active():
		return
	p.take_damage(Tunables.MELEE_DAMAGE, float(face))

func hurt(dmg: int, source_power: int, from_player_attack: bool) -> void:
	if dead:
		return
	if not from_player_attack:
		_take_normal_hit(dmg)
		return
	if _state == State.WINDUP:
		# COUNTER-CLASH — interrupted before the blow lands (no damage; stagger is the reward)
		_stun(Tunables.ENEMY_STAGGER_TIME)
		main.on_clash("strong")
		return
	if _state == State.STRIKE:
		_strike_hit_done = true  # the clash consumes the strike
		if source_power > my_power:
			_stun(Tunables.ENEMY_STAGGER_TIME)
			main.on_clash("strong")
		elif source_power == my_power:
			# DOUBLE CLASH — both weapons lock
			_stun(Tunables.CLASH_LOCK_TIME)
			var p: Variant = main.get("player")
			if p != null:
				p.stagger(Tunables.CLASH_LOCK_TIME)
			main.on_clash("even")
		else:
			# outmatched: enemy's strike wins — player staggered + half damage
			_state = State.RECOVER
			_state_t = Tunables.MELEE_RECOVER
			velocity.x = 0.0
			var p2: Variant = main.get("player")
			if p2 != null:
				p2.stagger(Tunables.PLAYER_STAGGER_TIME)
				p2.take_damage(int(Tunables.MELEE_DAMAGE / 2.0), float(face))
			main.on_clash("lose")
		return
	_take_normal_hit(dmg)

func _take_normal_hit(dmg: int) -> void:
	hp -= dmg
	_flash = FLASH_TIME
	velocity.y = POP_Y
	var p: Variant = main.get("player")
	if p != null:
		velocity.x = signf(global_position.x - p.global_position.x) * KNOCKBACK_X
	if hp <= 0:
		_die()

func _stun(t: float) -> void:
	_state = State.STUNNED
	_state_t = t
	_lean = 0.0
	velocity.x = 0.0

func _die() -> void:
	dead = true
	visible = false
	velocity = Vector2.ZERO
	main.register_kill()
	_respawn_later()

func _respawn_later() -> void:
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if is_instance_valid(main):
		var edge_x := Tunables.ARENA_MIN_X if randf() < 0.5 else Tunables.ARENA_MAX_X
		main.call_deferred("_spawn_melee", edge_x)
	if is_inside_tree():
		queue_free()

func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-10.0, -34.0), Vector2(20, 34))

func _draw() -> void:
	var body_c := Color("5a5566")
	if _state == State.WINDUP:
		body_c = Color("ff6b6b") if _windup_heavy else Color("ffb45f")
	elif _state == State.STUNNED:
		body_c = Color("7fd6e8")
	elif _flash > 0.0:
		body_c = Color(0.93, 0.95, 0.97)
	var lx := -float(face) * 5.0 * _lean
	var ly := -3.0 * _lean
	var body := Rect2(-10.0 + lx, -34.0 + ly, 20, 34)
	var head := Rect2(-6.0 + lx, -44.0 + ly, 12, 10)
	draw_rect(body, body_c)
	draw_rect(body, Color("16131c"), false, 2.0)
	draw_rect(head, body_c)
	draw_rect(head, Color("16131c"), false, 2.0)
	if _state == State.STRIKE:
		draw_rect(Rect2(Vector2(10.0 if face > 0 else -42.0, -28.0), Vector2(32, 36)), Color(1.0, 0.42, 0.42, 0.22))
