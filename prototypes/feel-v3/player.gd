# PROTOTYPE - NOT FOR PRODUCTION
# The hero's body: run, jump (hold = high, tap = hop), crouch, backdash, two
# attacks that look different, a low attack while crouching, a special attack
# on Up + Attack, a short flinch when hit. No knockdown, no counter.
# Weapons: ONE weapon, equipped in both hands (the user's plan, like Order of
# Ecclesia). J swings the right hand, I the left; the blade materializes in
# the swinging hand and is gone after. Two-handed weapons swing slower, hit
# harder, reach further; pick the weapon in the F1 WEAPONS page.
# Three bars: HP; Energy (attacks and backdashes spend it, it refills by itself);
# MP (the special spends it, blue orbs refill it).
# Every number comes from tuning.json through T.v().
extends CharacterBody2D

const BODY := Vector2(12, 36)
const STEP_EVERY := 0.27

var facing := 1
var state := "move"   # move | crouch | attack | backdash | hurt | dead
var hp := 100.0
var energy := 100.0
var mp := 60.0
var invuln := 0.0

var _spr: AnimatedSprite2D
var _weps := {}             # "weapon-dirge" / "weapon-elegy" -> the overlay sprite
var _coyote := 0.0
var _jump_buf := 0.0
var _attack_t := 0.0
var _attack_btn := ""
var _attack_kind := ""      # stand | crouch | special
var _attack_queued := ""
var _attack_air := false
var _attack_hit: Array = []
var _wave_thrown := false
var _energy_wait := 0.0
var _dash_t := 0.0
var _dash_cd := 0.0
var _hurt_t := 0.0
var _drop_t := 0.0
var _step_t := 0.0
var _ghost_t := 0.0
var _was_floor := true


func _ready() -> void:
	hp = T.v("player_hp")
	energy = T.v("energy_max")
	mp = T.v("mp_max")
	collision_layer = 4
	collision_mask = 1 | 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = BODY
	shape.shape = rect
	shape.position = Vector2(0, -BODY.y / 2.0)
	add_child(shape)
	_spr = G.sprite("hero", {"idle": 7.0, "run": 13.0, "jump": 8.0, "attack": 19.0, "attack2": 19.0,
		"crouch": 1.0, "crouchatk": 19.0}, ["jump", "attack", "attack2", "crouch", "crouchatk"])
	_spr.position = Vector2(-64, -64)   # frame is 128x64, feet at the bottom centre
	add_child(_spr)
	_spr.play("idle")
	# the weapon layer, Order of Ecclesia style: the body frames carry no weapon,
	# the blade sprite is drawn over the hand that swings it and hides after
	for set_name in ["weapon-dirge", "weapon-elegy"]:
		var w := G.sprite(set_name, {"j": 19.0, "i": 19.0, "low": 19.0}, ["j", "i", "low"])
		w.position = Vector2(-64, -64)
		w.visible = false
		add_child(w)
		_weps[set_name] = w
	floor_snap_length = 4.0


func is_low() -> bool:
	return state == "crouch" or (state == "attack" and _attack_kind == "crouch")


func body_rect() -> Rect2:
	# the box enemies can hit; it is shorter while she crouches
	var h := minf(BODY.y, T.v("crouch_height")) if is_low() else BODY.y
	return Rect2(global_position + Vector2(-BODY.x / 2.0, -h), Vector2(BODY.x, h))


func _is_elegy() -> bool:
	# the weapon in hand: 0 = Dirge (one sword, both hands), 1 = Elegy (two-handed)
	return int(T.v("weapon")) == 1


func attack_rect() -> Rect2:
	var reach := T.v("elegy_reach") if _is_elegy() else T.v("attack_reach")
	var x := global_position.x + (4.0 if facing > 0 else -4.0 - reach)
	if _attack_kind == "crouch":
		return Rect2(x, global_position.y - 26.0, reach, 24.0)
	return Rect2(x, global_position.y - 42.0, reach, 38.0)


func _physics_process(delta: float) -> void:
	if G.frozen() or state == "dead":
		return
	invuln = maxf(0.0, invuln - delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_jump_buf = maxf(0.0, _jump_buf - delta)
	if _energy_wait > 0.0:
		_energy_wait -= delta
	else:
		energy = minf(T.v("energy_max"), energy + T.v("energy_refill") * delta)
	energy = minf(energy, T.v("energy_max"))
	mp = minf(mp, T.v("mp_max"))
	if _drop_t > 0.0:
		_drop_t -= delta
		if _drop_t <= 0.0:
			collision_mask = 1 | 2
	var on_floor := is_on_floor()
	_coyote = T.v("coyote_time") if on_floor else maxf(0.0, _coyote - delta)
	var dir := signf(Input.get_axis("left", "right")) if absf(Input.get_axis("left", "right")) > 0.3 else 0.0
	if Input.is_action_just_pressed("jump"):
		_jump_buf = maxf(T.v("jump_buffer"), 0.02)
	var run := T.v("run_speed")

	match state:
		"move":
			_steer(dir, run, on_floor)
			if dir != 0.0:
				facing = int(dir)
			_try_jump()
			if _pressed_attack() != "" and _begin_attack(_pressed_attack()):
				pass
			elif Input.is_action_just_pressed("backdash") and on_floor:
				_try_backdash()
			elif on_floor and velocity.y >= 0.0 and Input.is_action_pressed("down"):
				state = "crouch"
				velocity.x = 0.0
		"crouch":
			velocity.x = 0.0
			if dir != 0.0:
				facing = int(dir)
			if _jump_buf > 0.0:
				state = "move"
				_try_jump()      # Down + Jump on a thin platform drops through it
			elif _pressed_attack() != "" and _begin_attack(_pressed_attack()):
				pass
			elif Input.is_action_just_pressed("backdash") and _try_backdash():
				pass
			elif not on_floor or not Input.is_action_pressed("down"):
				state = "move"
		"attack":
			_attack_t += delta
			if _attack_air:
				_steer(dir, run, false)
				if on_floor and velocity.y >= 0.0:
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
		_drop_t = T.v("drop_time")
		position.y += 2.0
		return
	velocity.y = -T.v("jump_velocity")
	if not Input.is_action_pressed("jump"):
		velocity.y *= T.v("jump_cut")   # pressed early and already let go: still a hop
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


func _spend_energy(cost: float) -> bool:
	if energy < cost:
		Sfx.play("no_energy")
		G.main.hud.flash("energy")
		return false
	if cost > 0.0:
		energy -= cost
		_energy_wait = T.v("energy_wait")
	return true


func _begin_attack(btn: String) -> bool:
	# Up + Attack = the special, if there is MP for it; otherwise a normal swing
	if Input.is_action_pressed("up"):
		if mp >= T.v("special_cost"):
			mp -= T.v("special_cost")
			_start_attack(btn, "special")
			return true
		Sfx.play("no_energy")
		G.main.hud.flash("mp")
	if not _spend_energy(T.v("elegy_energy") if _is_elegy() else T.v("attack_energy")):
		return false
	var airborne := not is_on_floor() or velocity.y < 0.0
	var low := not airborne and Input.is_action_pressed("down")
	_start_attack(btn, "crouch" if low else "stand")
	return true


func _attack_total() -> float:
	if _attack_kind == "special":
		return T.v("special_time")
	return T.v("elegy_time") if _is_elegy() else T.v("attack_time")


func _start_attack(btn: String, kind: String) -> void:
	state = "attack"
	_attack_t = 0.0
	_attack_btn = btn
	_attack_kind = kind
	_attack_queued = ""
	_attack_air = not is_on_floor() or velocity.y < 0.0   # a jump started this tick counts as airborne
	_attack_hit.clear()
	_wave_thrown = false
	# the sword materializes in the hand that swings it: J right, I left. The
	# body swings the same either way; the weapon layer carries the blade
	var anim := "attack" if btn == "attack" else "attack2"
	if kind == "crouch":
		anim = "crouchatk"
	elif kind == "special":
		anim = "attack2"
	_spr.sprite_frames.set_animation_speed(anim, 5.0 / _attack_total())
	_spr.play(anim)
	_spr.frame = 0
	if kind == "special":
		_hide_weapons()
	else:
		var set_name := "weapon-elegy" if _is_elegy() else "weapon-dirge"
		var wa := "low" if kind == "crouch" else ("j" if btn == "attack" else "i")
		# a weapon picked mid-swing in the panel must not stack two blades
		_hide_weapons()
		_weps[set_name].sprite_frames.set_animation_speed(wa, 5.0 / _attack_total())
		_weps[set_name].play(wa)
		_weps[set_name].frame = 0
		_weps[set_name].visible = true
	if kind == "special":
		Sfx.play("special")
	elif _is_elegy():
		Sfx.play("swing_heavy", 1.0 if btn == "attack" else 0.92)
	else:
		Sfx.play("swing", 1.0 if btn == "attack" else 1.12)


func _hide_weapons() -> void:
	for w in _weps.values():
		w.visible = false


func _attack_step() -> void:
	var total := _attack_total()
	var pressed := _pressed_attack()
	if pressed != "":
		_attack_queued = pressed
	if _attack_kind == "special":
		if not _wave_thrown and _attack_t >= total * 0.3:
			_wave_thrown = true
			G.main.throw_wave(global_position + Vector2(facing * 14.0, -22.0), facing)
	# the swing can hurt during the middle of the animation
	elif _attack_t >= total * 0.2 and _attack_t <= total * 0.65:
		var dmg := T.v("elegy_damage") if _is_elegy() else T.v("attack_damage")
		G.main.player_swing(attack_rect(), dmg, facing, _attack_hit)
	# alternating the two buttons chains sooner than pressing the same one
	var chain := T.v("elegy_chain") if _is_elegy() else T.v("attack_chain")
	var gate := chain if (_attack_queued != "" and _attack_queued != _attack_btn and _attack_kind != "special") else total * 0.85
	if _attack_queued != "" and _attack_t >= gate:
		var next := _attack_queued
		_attack_queued = ""
		if _begin_attack(next):
			return
	if not _attack_air and _attack_t >= total * 0.5:
		if Input.is_action_just_pressed("backdash") and _try_backdash():
			return
		if _jump_buf > 0.0:
			state = "move"
			_try_jump()
			return
	if _attack_t >= total:
		_end_attack()


func _end_attack() -> void:
	state = "crouch" if (_attack_kind == "crouch" and Input.is_action_pressed("down") and is_on_floor()) else "move"
	_attack_queued = ""


func _try_backdash() -> bool:
	if _dash_cd > 0.0 or not _spend_energy(T.v("backdash_energy")):
		return false
	state = "backdash"
	_dash_t = 0.0
	_ghost_t = 0.0
	invuln = maxf(invuln, T.v("backdash_safe"))
	Sfx.play("backdash")
	G.main.dust(global_position, 3)
	return true


func gain_mp(amount: float) -> void:
	mp = minf(T.v("mp_max"), mp + amount)


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
		_hide_weapons()
		G.main.player_died()
		return
	state = "hurt"
	_hurt_t = T.v("hurt_time")
	velocity.x = T.v("hurt_push") * signf(global_position.x - from_x)
	velocity.y = minf(velocity.y, -T.v("hurt_push"))


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
	# the weapon overlay follows her facing, and rests hidden outside a swing
	for w in _weps.values():
		w.flip_h = _spr.flip_h
		if state != "attack":
			w.visible = false
	if state == "attack":
		return
	if state == "crouch":
		_show("crouch", 0)
	elif state == "backdash" or state == "hurt":
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
