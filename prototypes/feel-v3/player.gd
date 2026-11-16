# PROTOTYPE - NOT FOR PRODUCTION
# The hero's body: run, jump (hold = high, tap = hop), crouch, backdash, two
# attacks that look different, a low attack while crouching, a special attack
# on Up + Attack, a short flinch when hit. No knockdown, no counter.
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
const WEAPONS := [
	{"name": "DIRGE-042", "tex": "weapon/dirge.png", "grip": Vector2(6, 5)},
	{"name": "ELEGY-013", "tex": "weapon/elegy.png", "grip": Vector2(10, 10)},
]
# one swing: where her shoulder is, the angle the weapon starts and ends at
# (degrees, 0 = straight ahead, minus = up), and how far the hand is from the shoulder
const SWINGS := {
	"stand_j": {"at": Vector2(3, -35), "a0": -150.0, "a1": 8.0, "r0": 9.0, "r1": 22.0},
	"stand_i": {"at": Vector2(1, -34), "a0": 115.0, "a1": -14.0, "r0": 8.0, "r1": 13.0},
	"crouch_j": {"at": Vector2(3, -17), "a0": -120.0, "a1": 4.0, "r0": 9.0, "r1": 22.0},
	"crouch_i": {"at": Vector2(1, -17), "a0": 60.0, "a1": -8.0, "r0": 8.0, "r1": 13.0},
	"air_j": {"at": Vector2(3, -35), "a0": -150.0, "a1": 24.0, "r0": 9.0, "r1": 22.0},
	"air_i": {"at": Vector2(1, -34), "a0": 120.0, "a1": -10.0, "r0": 8.0, "r1": 13.0},
}

var facing := 1
var state := "move"   # move | crouch | attack | backdash | hurt | dead
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
	_spr = G.sprite("hero", {"idle": 7.0, "run": 20.0, "crouch": 18.0, "backdash": 16.0, "hurt": 8.0,
		"cast": 12.0, "dead": 7.0}, ["jump", "land", "crouch", "attack", "attack2", "crouchatk", "crouchatk2",
		"airatk", "airatk2", "backdash", "hurt", "cast", "dead"])
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
	return state == "crouch" or (state == "attack" and _attack_kind == "crouch")


func body_rect() -> Rect2:
	# the box enemies can hit; it is shorter while she crouches
	var h := minf(BODY.y, T.v("crouch_height")) if is_low() else BODY.y
	return Rect2(global_position + Vector2(-BODY.x / 2.0, -h), Vector2(BODY.x, h))


func _is_elegy() -> bool:
	# the weapon in hand: 0 = Dirge (one sword, both hands), 1 = Elegy (two-handed)
	return int(T.v("weapon")) == 1


func weapon_name() -> String:
	return WEAPONS[1 if _is_elegy() else 0]["name"]


func attack_rect() -> Rect2:
	var reach := T.v("elegy_reach") if _is_elegy() else T.v("attack_reach")
	var x := global_position.x + (4.0 if facing > 0 else -4.0 - reach)
	if _attack_kind == "crouch":
		return Rect2(x, global_position.y - 30.0, reach, 28.0)
	return Rect2(x, global_position.y - 54.0, reach, 48.0)


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
			if Input.is_action_just_pressed("swap"):
				swap_weapon()
			if _pressed_attack() != "" and _begin_attack(_pressed_attack()):
				pass
			elif Input.is_action_just_pressed("backdash") and on_floor:
				_try_backdash()
			elif on_floor and velocity.y >= 0.0 and Input.is_action_pressed("down"):
				state = "crouch"
				velocity.x = 0.0
				_spr.play("crouch")      # she folds down over a few frames, then holds
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
	# the weapon appears in the hand that swings it: J right, I left
	var hand := "j" if btn == "attack" else "i"
	var pose := "air" if _attack_air else ("crouch" if kind == "crouch" else "stand")
	var anim: String = {"stand": "attack", "crouch": "crouchatk", "air": "airatk"}[pose] + ("" if hand == "j" else "2")
	if kind == "special":
		anim = "cast"
	_spr.sprite_frames.set_animation_speed(anim, 5.0 / _attack_total())
	_spr.play(anim)
	_spr.frame = 0
	if kind == "special":
		_arm.visible = false
		Sfx.play("special")
		return
	var w: Dictionary = WEAPONS[1 if _is_elegy() else 0]
	_blade.texture = G.tex(w["tex"])
	_blade.offset = -w["grip"]
	_blade_len = _blade.texture.get_width() - w["grip"].x
	_swing = SWINGS[pose + "_" + hand].duplicate()
	if _is_elegy():
		# the two-handed scythe takes a wider arc
		var down: bool = _swing["a0"] < 0.0
		_swing["a0"] += -25.0 if down else 25.0
		_swing["a1"] += 22.0 if down else -18.0
	_arm.visible = true
	_pose_weapon()
	if _is_elegy():
		Sfx.play("swing_heavy", 1.0 if btn == "attack" else 0.92)
	else:
		Sfx.play("swing", 1.0 if btn == "attack" else 1.12)


func _pose_weapon() -> void:
	# materialize -> sweep through the cut -> hold at the end of the arc -> fade
	var u := clampf(_attack_t / _attack_total(), 0.0, 1.0)
	var s := clampf((u - 0.1) / 0.3, 0.0, 1.0)
	s = 1.0 - (1.0 - s) * (1.0 - s)
	var ang := deg_to_rad(lerpf(_swing["a0"], _swing["a1"], s))
	var r := lerpf(_swing["r0"], _swing["r1"], s)
	_arm.position = Vector2(_swing["at"].x * facing, _swing["at"].y)
	_arm.scale.x = facing
	_blade.position = Vector2(cos(ang), sin(ang)) * r
	_blade.rotation = ang
	var alpha := clampf(u / 0.1, 0.0, 1.0) if u < 0.8 else clampf((1.0 - u) / 0.2, 0.0, 1.0)
	_blade.modulate = Color(1, 1, 1, alpha) if u < 0.8 else Color(0.5, 1.0, 1.0, alpha)
	var back := deg_to_rad(95.0) * signf(_swing["a1"] - _swing["a0"])
	var a0 := deg_to_rad(_swing["a0"])
	var from := ang - back
	if (back > 0.0 and from < a0) or (back < 0.0 and from > a0):
		from = a0
	var glow := clampf(1.0 - (u - 0.4) / 0.25, 0.0, 1.0) if s > 0.0 else 0.0
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
	if _attack_kind != "special":
		_pose_weapon()
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
	var stay_low := _attack_kind == "crouch" and Input.is_action_pressed("down") and is_on_floor()
	state = "crouch" if stay_low else "move"
	if stay_low:
		_show("crouch", 4)
	_attack_queued = ""


func _try_backdash() -> bool:
	if _dash_cd > 0.0 or not _spend_energy(T.v("backdash_energy")):
		return false
	state = "backdash"
	_spr.sprite_frames.set_animation_speed("backdash", 4.0 / maxf(0.05, T.v("backdash_time")))
	_spr.play("backdash")
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
	_hide_weapons()
	if hp <= 0.0:
		hp = 0.0
		state = "dead"
		velocity = Vector2.ZERO
		_spr.visible = true
		_spr.play("dead")
		G.main.player_died()
		return
	state = "hurt"
	_spr.play("hurt")
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
	if state != "attack":
		_arm.visible = false
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
