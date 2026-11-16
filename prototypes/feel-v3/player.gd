# PROTOTYPE - NOT FOR PRODUCTION
# The hero's body: run, jump (hold = high, tap = hop), backdash, attack on the
# ground and in the air, a short flinch when hit. No knockdown, no counter.
# Every number comes from tuning.json through T.v().
extends CharacterBody2D

const BODY := Vector2(12, 36)
const COYOTE := 0.09        # grace time to still jump after leaving a ledge
const JUMP_BUFFER := 0.12   # a jump pressed just before landing still happens
const STEP_EVERY := 0.27

var facing := 1
var state := "move"   # move | attack | backdash | hurt | dead
var hp := 100.0
var invuln := 0.0

var _spr: AnimatedSprite2D
var _coyote := 0.0
var _jump_buf := 0.0
var _attack_t := 0.0
var _attack_btn := ""
var _attack_queued := ""
var _attack_air := false
var _attack_hit: Array = []
var _dash_t := 0.0
var _dash_cd := 0.0
var _hurt_t := 0.0
var _drop_t := 0.0
var _step_t := 0.0
var _ghost_t := 0.0
var _was_floor := true


func _ready() -> void:
	hp = T.v("player_hp")
	collision_layer = 4
	collision_mask = 1 | 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = BODY
	shape.shape = rect
	shape.position = Vector2(0, -BODY.y / 2.0)
	add_child(shape)
	_spr = G.sprite("hero", {"idle": 7.0, "run": 13.0, "jump": 8.0, "attack": 19.0}, ["jump", "attack"])
	_spr.position = Vector2(-64, -64)   # frame is 128x64, feet at the bottom centre
	add_child(_spr)
	_spr.play("idle")
	floor_snap_length = 4.0


func body_rect() -> Rect2:
	return Rect2(global_position + Vector2(-BODY.x / 2.0, -BODY.y), BODY)


func attack_rect() -> Rect2:
	var reach := T.v("attack_reach")
	var x := global_position.x + (4.0 if facing > 0 else -4.0 - reach)
	return Rect2(x, global_position.y - 42.0, reach, 38.0)


func _physics_process(delta: float) -> void:
	if G.frozen() or state == "dead":
		return
	invuln = maxf(0.0, invuln - delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_jump_buf = maxf(0.0, _jump_buf - delta)
	if _drop_t > 0.0:
		_drop_t -= delta
		if _drop_t <= 0.0:
			collision_mask = 1 | 2
	var on_floor := is_on_floor()
	_coyote = COYOTE if on_floor else maxf(0.0, _coyote - delta)
	var dir := signf(Input.get_axis("left", "right")) if absf(Input.get_axis("left", "right")) > 0.3 else 0.0
	if Input.is_action_just_pressed("jump"):
		_jump_buf = JUMP_BUFFER
	var run := T.v("run_speed")

	match state:
		"move":
			_steer(dir, run, on_floor)
			if dir != 0.0:
				facing = int(dir)
			_try_jump()
			if _pressed_attack() != "":
				_start_attack(_pressed_attack())
			elif Input.is_action_just_pressed("backdash") and on_floor and _dash_cd <= 0.0:
				_start_backdash()
		"attack":
			_attack_t += delta
			if _attack_air:
				_steer(dir, run, false)
				if on_floor:
					_end_attack()   # landing cuts an air attack short
			else:
				velocity.x = 0.0
			if state == "attack":
				_attack_step()
		"backdash":
			_dash_t += delta
			var total := T.v("backdash_time")
			velocity.x = -facing * T.v("backdash_speed") * (1.0 - 0.6 * _dash_t / total)
			_ghost_t -= delta
			if _ghost_t <= 0.0:
				_ghost_t = 0.035
				_afterimage()
			if _dash_t >= total:
				state = "move"
				_dash_cd = T.v("backdash_cooldown")
		"hurt":
			_hurt_t -= delta
			if _hurt_t <= 0.0:
				state = "move"

	# letting go of jump early cuts the rise: tap = hop, hold = full jump
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= T.v("jump_cut")
	velocity.y = minf(velocity.y + T.v("gravity") * delta, T.v("max_fall"))
	move_and_slide()

	var now_floor := is_on_floor()
	if now_floor and not _was_floor:
		Sfx.play("land")
		G.main.dust(global_position, 4)
	_was_floor = now_floor
	if now_floor and state == "move" and absf(velocity.x) > 10.0:
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = STEP_EVERY
			Sfx.play("footstep")
	else:
		_step_t = 0.0
	_animate(now_floor)


func _steer(dir: float, run: float, on_floor: bool) -> void:
	if on_floor:
		velocity.x = dir * run   # full speed at once, dead stop on release
	else:
		velocity.x = lerpf(velocity.x, dir * run, T.v("air_control"))


func _try_jump() -> void:
	if _jump_buf <= 0.0 or _coyote <= 0.0:
		return
	_jump_buf = 0.0
	_coyote = 0.0
	if Input.is_action_pressed("down") and _on_ledge():
		collision_mask = 1          # fall through the thin platform
		_drop_t = 0.22
		position.y += 2.0
		return
	velocity.y = -T.v("jump_velocity")
	Sfx.play("jump")
	G.main.dust(global_position, 3)


func _on_ledge() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i).get_collider()
		if c is CollisionObject2D and (c.collision_layer & 2) != 0:
			return true
	return false


func _pressed_attack() -> String:
	if Input.is_action_just_pressed("attack"):
		return "attack"
	if Input.is_action_just_pressed("attack2"):
		return "attack2"
	return ""


func _start_attack(btn: String) -> void:
	state = "attack"
	_attack_t = 0.0
	_attack_btn = btn
	_attack_queued = ""
	_attack_air = not is_on_floor()
	_attack_hit.clear()
	_spr.sprite_frames.set_animation_speed("attack", 5.0 / T.v("attack_time"))
	_spr.play("attack")
	_spr.frame = 0
	Sfx.play("swing", 1.0 if btn == "attack" else 1.12)


func _attack_step() -> void:
	var total := T.v("attack_time")
	var pressed := _pressed_attack()
	if pressed != "":
		_attack_queued = pressed
	# the swing can hurt during the middle of the animation
	if _attack_t >= total * 0.2 and _attack_t <= total * 0.65:
		G.main.player_swing(attack_rect(), T.v("attack_damage"), facing, _attack_hit)
	# alternating the two buttons chains sooner than pressing the same one
	var gate := T.v("attack_chain") if (_attack_queued != "" and _attack_queued != _attack_btn) else total * 0.85
	if _attack_queued != "" and _attack_t >= gate:
		_start_attack(_attack_queued)
		return
	if not _attack_air and _attack_t >= total * 0.5:
		if Input.is_action_just_pressed("backdash") and _dash_cd <= 0.0:
			_start_backdash()
			return
		if _jump_buf > 0.0:
			state = "move"
			_try_jump()
			return
	if _attack_t >= total:
		_end_attack()


func _end_attack() -> void:
	state = "move"
	_attack_queued = ""


func _start_backdash() -> void:
	state = "backdash"
	_dash_t = 0.0
	_ghost_t = 0.0
	invuln = maxf(invuln, T.v("backdash_safe"))
	Sfx.play("backdash")
	G.main.dust(global_position, 3)


func take_hit(damage: float, from_x: float) -> void:
	if invuln > 0.0 or state == "dead":
		return
	hp -= damage
	invuln = T.v("hurt_safe")
	Sfx.play("hurt")
	G.main.number(global_position + Vector2(0, -44), int(damage), Color("#E8A94A"))
	G.main.shake(T.v("shake") * 1.5, 0.16)
	if hp <= 0.0:
		hp = 0.0
		state = "dead"
		velocity = Vector2.ZERO
		G.main.player_died()
		return
	state = "hurt"
	_hurt_t = T.v("hurt_time")
	velocity.x = 90.0 * signf(global_position.x - from_x)
	velocity.y = minf(velocity.y, -90.0)


func _afterimage() -> void:
	var g := Sprite2D.new()
	g.texture = _spr.sprite_frames.get_frame_texture(_spr.animation, _spr.frame)
	g.centered = false
	g.flip_h = _spr.flip_h
	g.global_position = _spr.global_position
	g.modulate = Color(0.45, 0.8, 1.0, 0.55)
	g.z_index = -1
	G.main.world.add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.22)
	tw.tween_callback(g.queue_free)


func _animate(on_floor: bool) -> void:
	_spr.flip_h = facing < 0
	# blink while she cannot be hurt after a hit
	_spr.visible = not (invuln > 0.0 and state != "backdash" and int(invuln * 20.0) % 2 == 0)
	if state == "attack":
		return
	if state == "backdash" or state == "hurt":
		_show("jump", 3)
	elif not on_floor:
		var f := 0
		if velocity.y > 120.0:
			f = 3
		elif velocity.y > 0.0:
			f = 2
		elif velocity.y > -150.0:
			f = 1
		_show("jump", f)
	elif absf(velocity.x) > 10.0:
		if _spr.animation != "run" or not _spr.is_playing():
			_spr.play("run")
	else:
		if _spr.animation != "idle" or not _spr.is_playing():
			_spr.play("idle")


func _show(anim: String, frame: int) -> void:
	if _spr.animation != anim:
		_spr.animation = anim
	_spr.stop()
	_spr.frame = frame
