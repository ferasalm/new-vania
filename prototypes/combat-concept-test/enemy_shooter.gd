# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does committed SotN-weight combat (combo + clash + deflect) feel rewarding?
# Date: 2026-11-11
# Shooter dummy — flying; keeps its distance, fires deflectable orbs on a cooldown loop.
# No clash states: any hit is normal damage (deflected orbs included, per SPEC.md).

class_name ProtoEnemyShooter
extends CharacterBody2D

enum State { COOLDOWN, WINDUP }

var main: Node
var dead := false
var hp: int = Tunables.SHOOTER_HP

var _state: int = State.COOLDOWN
var _state_t := 0.0
var _flash := 0.0
var _drift_t := 0.0

# Local consts — not in Tunables (prototype only).
const HOVER_Y := 300.0
const RETREAT_SPEED := 90.0
const STRAFE_SPEED := 22.0
const KEEP_AWAY := 220.0
const FLASH_TIME := 0.12
const RESPAWN_DELAY := 1.5

func _ready() -> void:
	add_to_group("enemies")
	_state_t = Tunables.SHOOTER_COOLDOWN

func _physics_process(delta: float) -> void:
	if dead:
		return
	if _flash > 0.0:
		_flash -= delta
	var p: Variant = main.get("player")
	if p == null:
		return
	var dx: float = p.global_position.x - global_position.x
	_drift_t += delta

	# hover at fixed height; back off when crowded, slow strafe otherwise
	if absf(dx) < KEEP_AWAY:
		velocity.x = -signf(dx) * RETREAT_SPEED
	else:
		velocity.x = sin(_drift_t * 1.7) * STRAFE_SPEED
	velocity.y = 0.0
	move_and_slide()
	global_position.x = clampf(global_position.x, Tunables.ARENA_MIN_X, Tunables.ARENA_MAX_X)
	global_position.y = HOVER_Y

	match _state:
		State.COOLDOWN:
			_state_t -= delta
			if _state_t <= 0.0:
				_state = State.WINDUP
				_state_t = Tunables.SHOOTER_WINDUP
		State.WINDUP:
			_state_t -= delta
			if _state_t <= 0.0:
				main.spawn_orb(global_position, ((p.global_position + Vector2(0.0, -20.0)) - global_position).normalized())
				_state = State.COOLDOWN
				_state_t = Tunables.SHOOTER_COOLDOWN
	queue_redraw()

func hurt(dmg: int, _source_power: int, _from_player_attack: bool) -> void:
	if dead:
		return
	hp -= dmg
	_flash = FLASH_TIME
	if hp <= 0:
		_die()

func _die() -> void:
	dead = true
	visible = false
	velocity = Vector2.ZERO
	main.register_kill()
	_respawn_later()

func _respawn_later() -> void:
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if is_instance_valid(main):
		main.call_deferred("_spawn_shooter")
	if is_inside_tree():
		queue_free()

func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-13.0, -10.0), Vector2(26, 16))

func _draw() -> void:
	var body_c := Color("5a5566")
	if _state == State.WINDUP:
		body_c = Color("ffb45f")
	elif _flash > 0.0:
		body_c = Color(0.93, 0.95, 0.97)
	var body := Rect2(-13.0, -10.0, 26, 16)
	draw_rect(body, body_c)
	draw_rect(body, Color("16131c"), false, 2.0)
	# eye / charge readout toward the player
	var p: Variant = main.get("player")
	var look := 1.0
	if p != null:
		look = signf(p.global_position.x - global_position.x)
		if look == 0.0:
			look = 1.0
	if _state == State.WINDUP:
		var charge := 1.0 - _state_t / Tunables.SHOOTER_WINDUP
		draw_circle(Vector2(look * 9.0, 0.0), 1.0 + 3.0 * charge, Color("ffb45f"))
	else:
		draw_circle(Vector2(look * 9.0, 0.0), 2.0, Color(0.4, 0.45, 0.5))
