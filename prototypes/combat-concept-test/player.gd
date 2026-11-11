# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does committed SotN-weight combat (combo + clash + deflect) feel rewarding?
# Date: 2026-11-11
# Player — two-hit committed combo. Contract per SPEC.md (main.gd + enemies depend on it).
# Public surface: main (injected), hp (int), facing, stagger(sec), take_damage(dmg, dir_x),
# is_attack_active(), attack_hitbox(). Everything else is internal.

class_name ProtoPlayer
extends CharacterBody2D

enum Phase {
	IDLE,
	ATK1_STARTUP, ATK1_ACTIVE, ATK1_RECOVERY,
	ATK2_STARTUP, ATK2_ACTIVE, ATK2_RECOVERY,
	STAGGER,
}

var main: Node
var hp: int = Tunables.PLAYER_HP
var facing := 1

var _phase: int = Phase.IDLE
var _phase_t := 0.0            # countdown for the current phase (seconds)
var _swing := 1                # which swing the ACTIVE phase belongs to (1 or 2)
var _buffered := false         # combo buffer: an attack press waiting to chain
var _buffer_t := 0.0
var _swing_hits := {}          # enemies already connected with this swing (once each)
var _flash := 0.0              # white hit-flash countdown
var _grounded := true

# Local consts — small feel values not worth a Tunables entry (prototype only).
const KNOCKBACK_X := 140.0
const KNOCKBACK_Y := -70.0
const FLASH_TIME := 0.12

func _ready() -> void:
	add_to_group("players")

func _physics_process(delta: float) -> void:
	# --- timers ---
	if _buffer_t > 0.0:
		_buffer_t -= delta
		if _buffer_t <= 0.0:
			_buffered = false
	if _flash > 0.0:
		_flash -= delta

	# --- attack input (buffered during any swing phase, ignored while staggered) ---
	if _phase != Phase.STAGGER and Input.is_action_just_pressed("attack"):
		if _phase == Phase.IDLE:
			_start_swing(1)
		else:
			_buffered = true
			_buffer_t = Tunables.COMBO_BUFFER

	# --- phase countdown / transitions / combo chain ---
	if _phase == Phase.STAGGER:
		_phase_t -= delta
		if _phase_t <= 0.0:
			_phase = Phase.IDLE
	elif _phase != Phase.IDLE:
		_phase_t -= delta
		if _phase_t <= 0.0:
			match _phase:
				Phase.ATK1_STARTUP:
					_enter_phase(Phase.ATK1_ACTIVE, Tunables.ATK1_ACTIVE)
				Phase.ATK1_ACTIVE:
					_enter_phase(Phase.ATK1_RECOVERY, Tunables.ATK1_RECOVERY)
				Phase.ATK1_RECOVERY:
					_phase = Phase.IDLE
				Phase.ATK2_STARTUP:
					_enter_phase(Phase.ATK2_ACTIVE, Tunables.ATK2_ACTIVE)
				Phase.ATK2_ACTIVE:
					_enter_phase(Phase.ATK2_RECOVERY, Tunables.ATK2_RECOVERY)
				Phase.ATK2_RECOVERY:
					_phase = Phase.IDLE
		# chain the moment recovery begins (or instantly if the press landed during recovery)
		if _buffered and (_phase == Phase.ATK1_RECOVERY or _phase == Phase.ATK2_RECOVERY):
			_buffered = false
			_start_swing(2 if _phase == Phase.ATK1_RECOVERY else 1)

	# --- movement: committed — no steering mid-swing, no jump-cancel ---
	_grounded = position.y >= Tunables.FLOOR_Y - 0.5
	var can_act := _phase == Phase.IDLE
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0 and can_act:
		facing = 1 if dir > 0.0 else -1
		velocity.x = move_toward(velocity.x, dir * Tunables.PLAYER_SPEED, Tunables.PLAYER_ACCEL * delta)
	elif _grounded:
		velocity.x = move_toward(velocity.x, 0.0, Tunables.PLAYER_FRICTION * delta)
	# airborne mid-swing keeps momentum: committed arc
	if _grounded and can_act and Input.is_action_just_pressed("jump"):
		velocity.y = Tunables.JUMP_VELOCITY
		_grounded = false
	if not _grounded:
		velocity.y += Tunables.GRAVITY * delta

	move_and_slide()
	if position.y > Tunables.FLOOR_Y:
		position.y = Tunables.FLOOR_Y
		velocity.y = 0.0
		_grounded = true

	# --- active frames: connect with enemies ---
	if _phase == Phase.ATK1_ACTIVE or _phase == Phase.ATK2_ACTIVE:
		_apply_hits()

	queue_redraw()

func _start_swing(n: int) -> void:
	_swing = n
	_swing_hits.clear()
	if _grounded:
		velocity.x = 0.0  # committed: plant on the spot
	_enter_phase(Phase.ATK1_STARTUP if n == 1 else Phase.ATK2_STARTUP,
			Tunables.ATK1_STARTUP if n == 1 else Tunables.ATK2_STARTUP)

func _enter_phase(ph: int, t: float) -> void:
	_phase = ph
	_phase_t = t

func is_attack_active() -> bool:
	return _phase == Phase.ATK1_ACTIVE or _phase == Phase.ATK2_ACTIVE

func attack_hitbox() -> Rect2:
	return Rect2(global_position + Vector2(14.0 if facing > 0 else -48.0, -30.0), Vector2(34, 40))

func _apply_hits() -> void:
	var hb := attack_hitbox()
	for e: Variant in get_tree().get_nodes_in_group("enemies"):
		if _swing_hits.has(e):
			continue
		if not is_instance_valid(e) or e.get("dead"):
			continue
		if not hb.intersects(e.hurt_rect()):
			continue
		_swing_hits[e] = true
		var power := 1 if _swing == 1 else 2
		e.hurt(Tunables.ATK1_DAMAGE if _swing == 1 else Tunables.ATK2_DAMAGE, power, true)
		main.hitstop(Tunables.HITSTOP_HIT)  # clash hitstop (0.09) wins via in_hitstop guard
		if _swing == 2:
			main.do_shake(Tunables.SHAKE_ATTACK2)

func stagger(time: float) -> void:
	# weapons-locked / outmatched: swing canceled, input locked
	_phase = Phase.STAGGER
	_phase_t = time
	_buffered = false
	_swing_hits.clear()
	velocity.x = 0.0

func take_damage(dmg: int, from_dir: float) -> void:
	if _phase != Phase.STAGGER:
		_phase = Phase.IDLE
		_buffered = false
	hp -= dmg
	_flash = FLASH_TIME
	velocity.x = from_dir * KNOCKBACK_X
	velocity.y = KNOCKBACK_Y
	main.on_player_hurt()
	if hp <= 0:
		main.register_player_death()
		position = Vector2(200, Tunables.FLOOR_Y)
		velocity = Vector2.ZERO
		hp = Tunables.PLAYER_HP
		_phase = Phase.IDLE
		_grounded = true

func _draw() -> void:
	var body_c := Color("0d7b89")
	if _flash > 0.0:
		body_c = Color(0.93, 0.95, 0.97)
	if _phase == Phase.STAGGER:
		body_c = Color("7fd6e8")
	var body := Rect2(-10.0, -34.0, 20, 34)
	var head := Rect2(-6.0, -44.0, 12, 10)
	draw_rect(body, body_c)
	draw_rect(body, Color("050912"), false, 2.0)
	draw_rect(head, body_c)
	draw_rect(head, Color("050912"), false, 2.0)
	draw_rect(Rect2(2.0 if facing > 0 else -6.0, -40.0, 4, 3), Color("050912"))  # facing notch
	if _phase == Phase.ATK1_ACTIVE or _phase == Phase.ATK2_ACTIVE:
		var hb := attack_hitbox()
		var local := Rect2(hb.position - global_position, hb.size)
		draw_rect(local, Color("0d7b894d"))
		draw_rect(local, Color("7fd6e88c"), false, 1.0)
