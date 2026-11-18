# PROTOTYPE - NOT FOR PRODUCTION
# The hero's body: run, jump (hold = high, tap = hop), crouch, slide, two
# backdashes (one per direction), two attacks that look different, a low attack
# while crouching, a special attack on Up + Attack, a short flinch when hit.
# No knockdown, no counter.
# Weapons: ONE weapon, equipped in both hands (the plan agreed with the user, like
# Order of Ecclesia). J swings the right hand, I the left; the weapon itself appears
# in the swinging hand, sweeps through the cut, is held out at the end of the arc
# and then fades. E swaps between the two weapons (Dirge-042 and Elegy-013).
# Her frames come from tools/build_pandora.py; the weapon is its own sprite,
# turned around her shoulder by code, so no attack frame can be cropped.
# Three bars: HP; Energy (attacks and backdashes spend it, it refills by itself);
# MP (the special spends it, blue orbs refill it).
# Every number comes from tuning.json through T.v().
extends CharacterBody2D

const BODY := Vector2(12, 36)
const STEP_EVERY := 0.27
const KICK_SHOW := 0.3      # seconds the kick-off picture stays after a wall jump
const WEAPONS := [
	{"name": "DIRGE-042", "tex": "weapon/dirge.png", "grip": Vector2(6, 5)},
	{"name": "ELEGY-013", "tex": "weapon/elegy.png", "grip": Vector2(10, 10)},
]
# one swing: where her shoulder is, the angle the weapon starts and ends at
# (degrees, 0 = straight ahead, minus = up), and how far the hand is from the shoulder
const SWINGS := {
	"stand_j": {"at": Vector2(3, -35), "a0": -150.0, "a1": 30.0, "r0": 9.0, "r1": 22.0},
	"stand_i": {"at": Vector2(1, -34), "a0": 115.0, "a1": -14.0, "r0": 8.0, "r1": 13.0},
	"crouch_j": {"at": Vector2(3, -22), "a0": -120.0, "a1": 4.0, "r0": 9.0, "r1": 22.0},
	"crouch_i": {"at": Vector2(1, -22), "a0": 60.0, "a1": -8.0, "r0": 8.0, "r1": 13.0},
	"air_j": {"at": Vector2(3, -35), "a0": -150.0, "a1": 24.0, "r0": 9.0, "r1": 22.0},
	"air_i": {"at": Vector2(1, -34), "a0": 120.0, "a1": -10.0, "r0": 8.0, "r1": 13.0},
}

var facing := 1
var state := "move"   # move | crouch | slide | attack | backdash | hurt | wall | dead
var hp := 100.0
var energy := 100.0
var mp := 60.0
var invuln := 0.0

var _spr: AnimatedSprite2D
var _arm: Node2D            # sits on her shoulder; the weapon turns around it
var _blade: Sprite2D
var _trail: Swoosh
var _swing := {}
var _blade_len := 40.0
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
var _wall_t := 0.0          # seconds left of the wall latch
var _wall_dir := 0          # which side the wall is on: -1 left, 1 right
var _latch_cd := 0.0
var _air_latches := 0       # latches used since her feet last touched the floor
var _slide_t := 0.0         # seconds spent sliding
var _slide_cd := 0.0
var _attack_elegy := false   # the weapon the current attack started with
var _fx_t := 0.0            # time to the next spark/afterimage of a slide or Requiem
var _shape: CollisionShape2D
var _rect: RectangleShape2D
var _steer_lock := 0.0      # after a wall jump she cannot steer back at once
var _kick_t := 0.0          # seconds left of the kick-off picture after a wall jump
var _kicked := false        # rising from a wall jump: letting go of jump does not cut it short
var _swings := {}           # SWINGS, with shoulder and hand distance read from the hero frames
var _prev_ang := 0.0        # where the blade was last tick (the cut sweeps from there)
var _spin_hits := 0
var hit_pts := PackedVector2Array()   # where the blade cut this tick (shown by "show hit areas")


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
	_shape = shape
	_rect = rect
	_spr = G.sprite("hero", {"idle": 7.0, "run": 10.0, "crouch": 18.0, "backdash": 16.0, "slide": 14.0, "hurt": 8.0,
		"cast": 12.0, "dead": 7.0, "rise": 8.0, "turn": 16.0, "dash": 16.0},
		["jump", "land", "crouch", "attack", "attack2", "crouchatk", "crouchatk2",
		"airatk", "airatk2", "backdash", "slide", "hurt", "cast", "dead", "wall", "walljump", "turn", "rise", "dash"])
	_fit_swings()
	var feet: Array = G.frames["hero"]["feet"]
	_spr.position = -Vector2(feet[0], feet[1])   # her feet sit on this node
	add_child(_spr)
	_spr.play("idle")
	# the weapon layer, Order of Ecclesia style: the body frames carry no weapon;
	# the weapon sprite appears in the swinging hand and fades after the cut
	_arm = Node2D.new()
	_arm.z_index = 1
	add_child(_arm)
	_trail = Swoosh.new()
	_arm.add_child(_trail)
	_blade = Sprite2D.new()
	_blade.centered = false
	_arm.add_child(_blade)
	_arm.visible = false
	floor_snap_length = 4.0


func is_low() -> bool:
	return state == "slide" or state == "crouch" or (state == "attack" and _attack_kind == "crouch")


func body_rect() -> Rect2:
	# the box enemies can hit; it is shorter while she crouches or slides
	var h := minf(BODY.y, minf(T.v("crouch_height"), _rect.size.y)) if is_low() else BODY.y
	return Rect2(global_position + Vector2(-BODY.x / 2.0, -h), Vector2(BODY.x, h))


func _is_elegy() -> bool:
	# the weapon in hand: 0 = Dirge (one sword, both hands), 1 = Elegy (two-handed).
	# During an attack, the weapon it started with.
	if state == "attack":
		return _attack_elegy
	return int(T.v("weapon")) == 1


func weapon_name() -> String:
	return WEAPONS[1 if _is_elegy() else 0]["name"]


func blade_points(from_ang: float, to_ang: float) -> PackedVector2Array:
	# The cut is exactly what you see: points along the weapon, from her hand to
	# its tip, for every angle the weapon passed through since the last tick.
	# "Weapon reach" stretches or shrinks it; 1.0 = the picture.
	var pts := PackedVector2Array()
	var r: float = _blade.position.length()
	var tip: float = r + _blade_len * T.v("hit_reach")
	var base := global_position + Vector2(_swing["at"].x * facing, _swing["at"].y)
	var steps := maxi(1, int(ceil(absf(to_ang - from_ang) / 0.12)))
	for i in steps + 1:
		var a := lerpf(from_ang, to_ang, float(i) / steps)
		var d := Vector2(cos(a) * facing, sin(a))
		var x := r
		while x < tip:
			pts.append(base + d * x)
			x += 4.0
		pts.append(base + d * tip)
	return pts


func _physics_process(delta: float) -> void:
	if G.frozen() or state == "dead" or G.main.hold:
		return
	invuln = maxf(0.0, invuln - delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_slide_cd = maxf(0.0, _slide_cd - delta)
	_latch_cd = maxf(0.0, _latch_cd - delta)
	_steer_lock = maxf(0.0, _steer_lock - delta)
	_kick_t = maxf(0.0, _kick_t - delta)
	hit_pts = PackedVector2Array()
	var hold_y := false
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
	if on_floor:
		_kicked = false
		_air_latches = 0
	# she stands back up as soon as there is room, wherever the small box came from
	if state != "slide" and state != "crouch" and _rect.size.y < BODY.y and _room_to_stand():
		_set_body_height(BODY.y)
	var dir := signf(Input.get_axis("left", "right")) if absf(Input.get_axis("left", "right")) > 0.3 else 0.0
	if Input.is_action_just_pressed("jump"):
		_jump_buf = maxf(T.v("jump_buffer"), 0.02)
	var run := T.v("run_speed")

	match state:
		"move":
			_steer(dir, run, on_floor)
			if dir != 0.0:
				facing = int(dir)
			if _slide_ready(on_floor):
				_start_slide()
			else:
				_try_jump()
				var dash := _dash_pressed()
				if Input.is_action_just_pressed("swap"):
					swap_weapon()
				if _pressed_attack() != "" and _begin_attack(_pressed_attack()):
					pass
				elif dash != 0 and on_floor:
					_try_backdash(dash)
				elif on_floor and velocity.y >= 0.0 and Input.is_action_pressed("down"):
					state = "crouch"
					velocity.x = 0.0
					_spr.play("crouch")      # she folds down over a few frames, then holds
				elif _can_latch(dir, on_floor):
					state = "wall"
					_wall_dir = int(dir)
					_wall_t = T.v("wall_latch_time")
					_air_latches += 1
					facing = -_wall_dir      # she looks away from the wall, ready to kick off
					velocity = Vector2(_wall_dir * 30.0, 0.0)
					Sfx.play("land", 1.3)
					G.main.dust(global_position + Vector2(_wall_dir * 6.0, -20.0), 2)
		"wall":
			# the latch does not last: she slides slowly, then her grip gives out
			_wall_t -= delta
			velocity.x = _wall_dir * 30.0      # keeps her pressed on the wall
			velocity.y = T.v("wall_slide_speed")
			hold_y = true
			if _jump_buf > 0.0:
				_jump_buf = 0.0
				state = "move"
				facing = -_wall_dir
				velocity = Vector2(-_wall_dir * T.v("wall_jump_push"), -T.v("wall_jump_velocity"))
				_steer_lock = T.v("wall_jump_lock")
				_kick_t = KICK_SHOW
				_kicked = true
				_latch_cd = 0.12
				hold_y = false
				Sfx.play("jump", 1.15)
				G.main.dust(global_position + Vector2(_wall_dir * 6.0, -10.0), 4)
			elif _wall_t <= 0.0 or on_floor or not is_on_wall() or Input.is_action_pressed("down"):
				state = "move"
				_latch_cd = 0.35
				hold_y = false
		"crouch":
			velocity.x = 0.0
			if dir != 0.0:
				facing = int(dir)
			if _rect.size.y < BODY.y and _room_to_stand():
				_set_body_height(BODY.y)      # she can stand up again
			if _jump_buf > 0.0:
				if Input.is_action_pressed("down") and not _on_ledge() and _slide_cd <= 0.0:
					_start_slide()
				else:
					state = "move"
					_try_jump()      # Down + Jump on a thin platform drops through it
			elif _pressed_attack() != "" and _begin_attack(_pressed_attack()):
				pass
			elif _dash_pressed() != 0 and _try_backdash(_dash_pressed()):
				pass
			elif not on_floor or not Input.is_action_pressed("down"):
				state = "move"
		"attack":
			_attack_t += delta
			if _attack_air:
				_steer(dir, run, false)
				if on_floor and velocity.y >= 0.0:
					if _attack_kind == "special":
						_attack_air = false   # a special is never cut short by landing
					else:
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
				Vfx.backdash_end(global_position, -facing)
		"slide":
			_slide_t += delta
			_fx_t -= delta
			if _fx_t <= 0.0:
				_fx_t = 0.045
				Vfx.slide_tick(global_position, facing)
				if int(_slide_t / 0.045) % 2 == 0:
					Vfx.ghost(_spr, Color(Vfx.CYAN.r, Vfx.CYAN.g, Vfx.CYAN.b, 0.45), 0.22)
			var total := T.v("slide_time")
			velocity.x = facing * T.v("slide_speed") * (1.0 - 0.5 * minf(_slide_t, total) / total)
			if _slide_t >= 0.08 and _jump_buf > 0.0 and on_floor and _room_to_stand():
				# she can hop out of a slide, but only where she fits standing
				_jump_buf = 0.0
				_coyote = 0.0
				_set_body_height(BODY.y)
				state = "move"
				velocity.y = -T.v("jump_velocity")
				Sfx.play("jump")
				G.main.dust(global_position, 3)
			elif not on_floor:
				# sliding off an edge ends the slide
				if _room_to_stand():
					_set_body_height(BODY.y)
				state = "move"
				_slide_cd = T.v("slide_cooldown")
			elif _slide_t >= total:
				if _room_to_stand():
					_set_body_height(BODY.y)
					state = "crouch" if Input.is_action_pressed("down") else "move"
					_slide_cd = T.v("slide_cooldown")
					if state == "crouch":
						_show_crouched()
				elif is_on_wall():
					# a wall stops her; she stays low until there is room to stand
					state = "crouch"
					velocity.x = 0.0
					_slide_cd = T.v("slide_cooldown")
					_show_crouched()
		"hurt":
			_hurt_t -= delta
			if _hurt_t <= 0.0:
				state = "move"

	# letting go of jump early cuts the rise: tap = hop, hold = full jump
	if Input.is_action_just_released("jump") and velocity.y < 0.0 and not _kicked:
		velocity.y *= T.v("jump_cut")
	if not hold_y:
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
	elif _steer_lock > 0.0:
		pass                     # just kicked off a wall: carry the push
	else:
		velocity.x = lerpf(velocity.x, dir * run, T.v("air_control"))


func _can_latch(dir: float, on_floor: bool) -> bool:
	# the wall latch is an ability she finds before the warden (main.has_latch)
	if on_floor or dir == 0.0 or _latch_cd > 0.0 or not G.main.has_latch:
		return false
	if _air_latches >= int(T.v("wall_latches_per_air")):
		return false
	if velocity.y < -60.0 or not is_on_wall():
		return false
	return signf(get_wall_normal().x) == -dir


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


func _slide_ready(on_floor: bool) -> bool:
	# Down + Jump on solid ground starts a slide; on a thin platform it still drops through
	return on_floor and _jump_buf > 0.0 and Input.is_action_pressed("down") and _slide_cd <= 0.0 and not _on_ledge()


func _set_body_height(h: float) -> void:
	# keeps her feet where they are and moves the top of the box down
	_rect.size = Vector2(BODY.x, h)
	_shape.position = Vector2(0, -h / 2.0)


func _room_to_stand() -> bool:
	return not test_move(global_transform, Vector2(0, -(BODY.y - _rect.size.y)))


func _pressed_attack() -> String:
	if Input.is_action_just_pressed("attack"):
		return "attack"
	if Input.is_action_just_pressed("attack2"):
		return "attack2"
	return ""


func _dash_pressed() -> int:
	# two backdash buttons: left dashes left, right dashes right
	if Input.is_action_just_pressed("backdash_left"):
		return -1
	if Input.is_action_just_pressed("backdash_right"):
		return 1
	return 0


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
	# Up + Attack = the special, if there is MP for it; otherwise a normal swing.
	# The MP is only taken when the special actually goes off (_attack_step).
	# Decide with the weapon this NEW attack will use (a chained attack may follow a swap;
	# _is_elegy() still answers for the attack in progress).
	var elegy := int(T.v("weapon")) == 1
	if Input.is_action_pressed("up"):
		if mp >= (T.v("elegy_special_cost") if elegy else T.v("special_cost")):
			_start_attack(btn, "special")
			return true
		Sfx.play("no_energy")
		G.main.hud.flash("mp")
	# Elegy is two-handed: J and I are the same one heavy cut
	if elegy:
		btn = "attack"
	if not _spend_energy(T.v("attack_energy") * (T.v("elegy_energy_mult") if elegy else 1.0)):
		return false
	var airborne := not is_on_floor() or velocity.y < 0.0
	var low := not airborne and Input.is_action_pressed("down")
	_start_attack(btn, "crouch" if low else "stand")
	return true


func special_cost() -> float:
	return T.v("elegy_special_cost") if _is_elegy() else T.v("special_cost")


func _sweep() -> float:
	# 0 = the weapon is still raised, 1 = the cut is finished
	var u := clampf(_attack_t / _attack_total(), 0.0, 1.0)
	if _attack_kind == "special":
		return clampf((u - 0.12) / 0.7, 0.0, 1.0)      # the Requiem turns at a steady speed
	var s := clampf((u - 0.1) / 0.3, 0.0, 1.0)
	return 1.0 - (1.0 - s) * (1.0 - s)


func _attack_total() -> float:
	if _attack_kind == "special":
		return T.v("elegy_special_time") if _is_elegy() else T.v("special_time")
	return T.v("elegy_time") if _is_elegy() else T.v("attack_time")


func _start_attack(btn: String, kind: String) -> void:
	_attack_elegy = int(T.v("weapon")) == 1
	state = "attack"
	_attack_t = 0.0
	_attack_btn = btn
	_attack_kind = kind
	_attack_queued = ""
	_attack_air = not is_on_floor() or velocity.y < 0.0   # a jump started this tick counts as airborne
	_attack_hit.clear()
	_wave_thrown = false
	# the weapon appears in the hand that swings it: J right, I left
	var hand := "j" if btn == "attack" else "i"
	var pose := "air" if _attack_air else ("crouch" if kind == "crouch" else "stand")
	var anim: String = {"stand": "attack", "crouch": "crouchatk", "air": "airatk"}[pose] + ("" if hand == "j" else "2")
	if kind == "special":
		anim = "cast"
	_spr.sprite_frames.set_animation_speed(anim, 5.0 / _attack_total())
	_spr.play(anim)
	_spr.frame = 0
	_spin_hits = 0
	if kind == "special" and not _is_elegy():
		_arm.visible = false
		Sfx.play("special")
		Vfx.cast_gather(global_position + Vector2(facing * 14.0, -22.0), _attack_total() * 0.3)
		return
	var w: Dictionary = WEAPONS[1 if _is_elegy() else 0]
	_blade.texture = G.tex(w["tex"])
	_blade.offset = -w["grip"]
	_blade.scale = Vector2.ONE
	_blade_len = _blade.texture.get_width() - w["grip"].x
	_swing = _swings[pose + "_" + hand].duplicate()
	if kind == "special":
		# Elegy's special, the Requiem: the scythe turns twice all the way round her,
		# drawn bigger so it reaches farther (the cut follows the picture)
		_swing = {"at": Vector2(0, -26), "a0": -90.0, "a1": 630.0,
			"r0": T.v("elegy_special_radius"), "r1": T.v("elegy_special_radius")}
		_blade.scale = Vector2.ONE * T.v("elegy_special_size")
		_blade_len *= T.v("elegy_special_size")
		_arm.visible = true
		_prev_ang = deg_to_rad(-90.0)
		_pose_weapon()
		_fx_t = 0.0
		Vfx.requiem_start(global_position, _attack_total(), _spr)
		Sfx.play("special", 0.8)
		return
	if _is_elegy():
		# the two-handed scythe takes a wider arc
		var down: bool = _swing["a0"] < 0.0
		_swing["a0"] += -25.0 if down else 25.0
		_swing["a1"] += 22.0 if down else -18.0
	_arm.visible = true
	_prev_ang = deg_to_rad(_swing["a0"])
	_pose_weapon()
	if _is_elegy():
		Sfx.play("swing_heavy", 1.0 if btn == "attack" else 0.92)
	else:
		Sfx.play("swing", 1.0 if btn == "attack" else 1.12)


func _pose_weapon() -> void:
	# materialize -> sweep through the cut -> hold at the end of the arc -> fade
	var u := clampf(_attack_t / _attack_total(), 0.0, 1.0)
	var s := _sweep()
	var ang := deg_to_rad(lerpf(_swing["a0"], _swing["a1"], s))
	var r := lerpf(_swing["r0"], _swing["r1"], s)
	_arm.position = Vector2(_swing["at"].x * facing, _swing["at"].y)
	_arm.scale.x = facing
	_blade.position = Vector2(cos(ang), sin(ang)) * r
	_blade.rotation = ang
	var alpha := clampf(u / 0.1, 0.0, 1.0) if u < 0.8 else clampf((1.0 - u) / 0.2, 0.0, 1.0)
	_blade.modulate = Color(1, 1, 1, alpha) if u < 0.8 else Color(0.5, 1.0, 1.0, alpha)
	if _attack_kind == "special":
		_blade.modulate = Color(0.75, 1.0, 1.0, clampf(u / 0.1, 0.0, 1.0) * clampf((1.0 - u) / 0.15, 0.0, 1.0))
	var back := deg_to_rad(95.0) * signf(_swing["a1"] - _swing["a0"])
	var a0 := deg_to_rad(_swing["a0"])
	var from := ang - back
	if (back > 0.0 and from < a0) or (back < 0.0 and from > a0):
		from = a0
	var glow := clampf(1.0 - (u - 0.4) / 0.25, 0.0, 1.0) if s > 0.0 else 0.0
	if _attack_kind == "special":
		glow = 1.0 if (s > 0.0 and s < 1.0) else 0.0
	_trail.set_arc(from, ang, r + _blade_len * 0.3, r + _blade_len, glow)


func _hide_weapons() -> void:
	_arm.visible = false


func weapon_showing() -> bool:
	return _arm.visible and _blade.modulate.a > 0.5


func swap_weapon() -> void:
	T.set_v("weapon", 0.0 if _is_elegy() else 1.0)
	Sfx.play("pickup", 0.8)
	G.main.hud.toast(weapon_name())


func _attack_step() -> void:
	var total := _attack_total()
	if _arm.visible:
		_pose_weapon()
	var pressed := _pressed_attack()
	if pressed != "":
		_attack_queued = "attack" if _is_elegy() else pressed
	var ang: float = _blade.rotation
	if _attack_kind == "special" and not _is_elegy():
		if not _wave_thrown and _attack_t >= total * 0.3:
			_wave_thrown = true
			mp -= T.v("special_cost")      # paid only now, when the wave really leaves
			G.main.throw_wave(global_position + Vector2(facing * 14.0, -22.0), facing)
			Vfx.cast_release(global_position + Vector2(facing * 14.0, -22.0), facing)
	elif _attack_kind == "special":
		# the Requiem: every half turn of the scythe can cut each enemy once more
		if _attack_t >= total * 0.12 and _attack_t <= total * 0.82:
			if not _wave_thrown:
				_wave_thrown = true
				mp -= T.v("elegy_special_cost")
			var turn := int((ang - deg_to_rad(-90.0)) / PI)
			if turn != _spin_hits:
				_spin_hits = turn
				_attack_hit.clear()
				Sfx.play("swing_heavy", 1.1)
			hit_pts = blade_points(_prev_ang, ang)
			G.main.player_cut(hit_pts, T.v("elegy_special_damage"), facing, _attack_hit)
			_fx_t -= get_physics_process_delta_time()
			if _fx_t <= 0.0:
				_fx_t = 0.035
				var d := Vector2(cos(ang) * facing, sin(ang))
				var tip := global_position + Vector2(_swing["at"].x * facing, _swing["at"].y) + d * (_blade.position.length() + _blade_len)
				Vfx.requiem_tick(tip, atan2(cos(ang), -sin(ang) * facing))
	# the cut hurts exactly where the weapon is: through the sweep, then held out
	elif _attack_t >= total * 0.1 and _attack_t <= total * 0.65:
		var dmg := T.v("attack_damage") * (T.v("elegy_damage_mult") if _is_elegy() else 1.0)
		hit_pts = blade_points(_prev_ang, ang)
		G.main.player_cut(hit_pts, dmg, facing, _attack_hit)
	_prev_ang = ang
	# Dirge: alternating the two buttons chains sooner than pressing the same one.
	# Elegy has one cut and no chain bonus.
	var fast := _attack_queued != "" and _attack_queued != _attack_btn and _attack_kind != "special" and not _is_elegy()
	var gate := T.v("attack_chain") if fast else total * 0.85
	if _attack_queued != "" and _attack_t >= gate:
		var next := _attack_queued
		_attack_queued = ""
		if _begin_attack(next):
			return
	if not _attack_air and _attack_t >= total * 0.5:
		if _dash_pressed() != 0 and _try_backdash(_dash_pressed()):
			return
		if _jump_buf > 0.0:
			state = "move"
			_try_jump()
			return
	if _attack_t >= total:
		_end_attack()


func _end_attack() -> void:
	if _attack_kind == "special" and _is_elegy():
		Vfx.requiem_end(global_position)
	var stay_low := _attack_kind == "crouch" and Input.is_action_pressed("down") and is_on_floor()
	state = "crouch" if stay_low else "move"
	if stay_low:
		_show("crouch", 4)
	_attack_queued = ""


func _try_backdash(dash_dir: int) -> bool:
	if _dash_cd > 0.0 or not _spend_energy(T.v("backdash_energy")):
		return false
	state = "backdash"
	facing = -dash_dir      # her back points where she dashes
	Vfx.backdash_start(global_position, dash_dir, _spr)
	_spr.sprite_frames.set_animation_speed("backdash", 4.0 / maxf(0.05, T.v("backdash_time")))
	_spr.play("backdash")
	_dash_t = 0.0
	_ghost_t = 0.0
	invuln = maxf(invuln, T.v("backdash_safe"))
	Sfx.play("backdash")
	G.main.dust(global_position, 3)
	return true


func _start_slide() -> void:
	state = "slide"
	_slide_t = 0.0
	_jump_buf = 0.0
	velocity.x = facing * T.v("slide_speed")
	_set_body_height(T.v("slide_height"))
	_fx_t = 0.0
	Vfx.slide_start(global_position, facing, _spr)
	Sfx.play("backdash", 0.8)
	G.main.dust(global_position, 2)


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
	var casting := state == "attack" and _attack_kind == "special"
	if not casting or hp <= 0.0:
		_hide_weapons()
	if hp <= 0.0:
		hp = 0.0
		state = "dead"
		velocity = Vector2.ZERO
		_spr.visible = true
		_spr.play("dead")
		G.main.player_died()
		return
	if casting:
		return      # a hit hurts but never breaks a special that has started
	state = "hurt"
	_spr.play("hurt")
	_hurt_t = T.v("hurt_time")
	velocity.x = T.v("hurt_push") * signf(global_position.x - from_x)
	velocity.y = minf(velocity.y, -T.v("hurt_push"))


func _afterimage() -> void:
	# glowing copies left along the dash, cyan at the start turning violet
	var k := clampf(_dash_t / maxf(0.05, T.v("backdash_time")), 0.0, 1.0)
	var c := Vfx.CYAN.lerp(Vfx.VIOLET, k)
	c.a = 0.8
	Vfx.ghost(_spr, c, 0.3)


func _animate(on_floor: bool) -> void:
	_spr.flip_h = facing < 0
	# blink while she cannot be hurt after a hit
	_spr.visible = not (invuln > 0.0 and state != "backdash" and int(invuln * 20.0) % 2 == 0)
	if state != "attack":
		_arm.visible = false
	if state == "wall":
		if _spr.sprite_frames.has_animation("wall"):
			# she grabs on (frame 0), then hangs (frame 1)
			_show("wall", 0 if _wall_t > T.v("wall_latch_time") - 0.1 else 1)
		else:
			_show("jump", 2)
		return
	if _kick_t > 0.0 and not on_floor and state == "move" and _spr.sprite_frames.has_animation("walljump"):
		_show("walljump", clampi(int((1.0 - _kick_t / KICK_SHOW) * 3.0), 0, 2))
		return
	if state == "slide":
		if _spr.sprite_frames.has_animation("slide"):
			if _spr.animation != "slide" or not _spr.is_playing():
				_spr.play("slide")
		else:
			_show("crouch", _spr.sprite_frames.get_frame_count("crouch") - 1)
		return
	# these states started their own animation when they began
	if state == "attack" or state == "backdash" or state == "hurt" or state == "crouch":
		return
	if not on_floor:
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


func _show_crouched() -> void:
	# a slide that ends low hands over to the held crouch picture (the crouch state does not
	# start its own animation, so without this the last slide frame stayed on screen)
	_show("crouch", _spr.sprite_frames.get_frame_count("crouch") - 1)


func _fit_swings() -> void:
	# The swing table says where her shoulder is and how far the hand is from it.
	# A hero set that lists "shoulders" and "hands" per frame (frames.json) overrides
	# those two, so the weapon sits in the hand she actually raises. The angles stay
	# as tuned: they decide where a cut lands.
	_swings = SWINGS.duplicate(true)
	var meta: Dictionary = G.frames["hero"]
	if not (meta.has("hands") and meta.has("shoulders")):
		return
	var feet := Vector2(meta["feet"][0], meta["feet"][1])
	var anim_of := {"stand_j": "attack", "stand_i": "attack2", "crouch_j": "crouchatk",
		"crouch_i": "crouchatk2", "air_j": "airatk", "air_i": "airatk2"}
	for key in anim_of:
		var hands: Array = meta["hands"].get(anim_of[key], [])
		var shoulders: Array = meta["shoulders"].get(anim_of[key], [])
		if hands.size() < 4 or shoulders.size() < 4:
			continue
		var sh := Vector2.ZERO
		for p in shoulders:
			sh += Vector2(p[0], p[1])
		sh /= float(shoulders.size())
		_swings[key]["at"] = sh - feet
		# frame 1 is the wind-up, frame 3 the end of the cut
		_swings[key]["r0"] = clampf(Vector2(hands[1][0], hands[1][1]).distance_to(Vector2(shoulders[1][0], shoulders[1][1])), 4.0, 26.0)
		_swings[key]["r1"] = clampf(Vector2(hands[3][0], hands[3][1]).distance_to(Vector2(shoulders[3][0], shoulders[3][1])), 4.0, 26.0)


func _show(anim: String, frame: int) -> void:
	if _spr.animation != anim:
		_spr.animation = anim
	_spr.stop()
	_spr.frame = frame


# The streak the weapon leaves behind: a curved band that is bright at the blade
# and fades to nothing behind it.
class Swoosh extends Node2D:
	var _from := 0.0
	var _to := 0.0
	var _r0 := 10.0
	var _r1 := 40.0
	var _alpha := 0.0

	func set_arc(from: float, to: float, r0: float, r1: float, alpha: float) -> void:
		_from = from
		_to = to
		_r0 = r0
		_r1 = r1
		_alpha = alpha
		queue_redraw()

	func _draw() -> void:
		if _alpha <= 0.01 or absf(_to - _from) < 0.05:
			return
		var n := 10
		for i in n:
			var a := lerpf(_from, _to, float(i) / n)
			var b := lerpf(_from, _to, float(i + 1) / n)
			var k := float(i + 1) / n
			var inner := lerpf(_r1 - 3.0, _r0, k * k)
			var pts := PackedVector2Array([Vector2(cos(a), sin(a)) * inner, Vector2(cos(a), sin(a)) * _r1,
				Vector2(cos(b), sin(b)) * _r1, Vector2(cos(b), sin(b)) * inner])
			draw_colored_polygon(pts, Color(0.45, 0.95, 1.0, _alpha * k * 0.75))
			draw_line(pts[1], pts[2], Color(0.9, 1.0, 1.0, _alpha * k), 1.0)
