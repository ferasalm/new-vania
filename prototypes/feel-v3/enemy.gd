# PROTOTYPE - NOT FOR PRODUCTION
# Five enemies. Each has two ways of moving and two attacks, and each blinks
# orange before it hurts you, so every hit you take is one you could have read.
#   hound   (church) walks a beat; charges along the floor, or pounces if you are high or far.
#   ghost   (church, library) drifts through walls at you; blinks out, reappears behind you and shrieks.
#   choir   (library, lab) hovers out of reach; throws three feathers, or dives through you.
#   spitter (library, lab) sits and lobs arcing shots; sprays a burst if you get close; hops to a new spot.
#   warden  (lab) a big brute: walks you down, lunges with its claws, or leaps and cracks the floor.
extends CharacterBody2D

const KINDS := {
	"hound": {"box": Vector2(34, 20), "origin": Vector2(-32, -48), "art": -1, "fly": false, "heavy": false,
		"fps": {"idle": 10.0, "walk": 12.0, "run": 14.0, "jump": 10.0}},
	"ghost": {"box": Vector2(22, 34), "origin": Vector2(-32, -42), "art": -1, "fly": true, "heavy": false,
		"fps": {"idle": 8.0, "chase": 8.0, "shriek": 10.0, "appear": 10.0, "vanish": 10.0}},
	"choir": {"box": Vector2(30, 46), "origin": Vector2(-61, -67), "art": 0, "fly": true, "heavy": false,
		"fps": {"idle": 10.0, "attack": 8.0}},
	"spitter": {"box": Vector2(20, 34), "origin": Vector2(-23, -43), "art": 0, "fly": false, "heavy": false,
		"fps": {"idle": 7.0}},
	"warden": {"box": Vector2(40, 38), "origin": Vector2(-40, -76), "art": 1, "fly": false, "heavy": true,
		"fps": {"idle": 7.0, "run": 9.0}},
}

var kind := "hound"
var hp := 1.0
var facing := -1
var state := "idle"
var _t := 0.0
var _stun := 0.0
var _flash := 0.0
var _cool := 1.0            # seconds until the next attack may start
var _count := 0             # alternates the two attacks
var _home := Vector2.ZERO
var _aim := Vector2.ZERO
var _spr: AnimatedSprite2D
var _box := Vector2.ZERO
var _bob := 0.0
var _d := {}


func setup(k: String) -> void:
	kind = k
	_d = KINDS[k]
	hp = T.v(k + "_hp")
	_box = _d["box"]
	_spr = G.sprite(k, _d["fps"], ["jump", "appear", "vanish", "attack"])
	_spr.position = _d["origin"]
	add_child(_spr)
	collision_layer = 8
	collision_mask = 0
	_bob = randf() * TAU
	_cool = 0.8 + randf() * 0.8
	if not _d["fly"]:
		collision_mask = 1 | 2
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = _box
		shape.shape = rect
		shape.position = Vector2(0, -_box.y / 2.0)
		add_child(shape)
	_go("patrol" if k == "hound" else "idle", "walk" if k == "hound" else "idle")


func _ready() -> void:
	_home = global_position


func hurt_rect() -> Rect2:
	if _d["fly"]:
		return Rect2(global_position - _box / 2.0, _box)
	return Rect2(global_position + Vector2(-_box.x / 2.0, -_box.y), _box)


func _physics_process(delta: float) -> void:
	if G.frozen():
		return
	_flash = maxf(0.0, _flash - delta)
	_cool = maxf(0.0, _cool - delta)
	var player: Node2D = G.main.player
	var to := player.global_position - global_position
	if _stun > 0.0:
		_stun -= delta
		if _d["fly"]:
			global_position += velocity * delta
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
		else:
			velocity.y += T.v("gravity") * delta
			move_and_slide()
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		_paint()
		return
	_t += delta
	_bob += delta * 3.0
	match kind:
		"hound":
			_hound(delta, to)
		"ghost":
			_ghost(delta, to)
		"choir":
			_choir(delta, to)
		"spitter":
			_spitter(delta, to)
		"warden":
			_warden(delta, to)
	_paint()


func _face(to: Vector2) -> void:
	if to.x != 0.0:
		facing = int(signf(to.x))


func _hound(delta: float, to: Vector2) -> void:
	match state:
		"patrol":
			# turn first, so the walk speed below already points away from the wall
			if is_on_wall():
				facing = int(signf(get_wall_normal().x)) if get_wall_normal().x != 0.0 else -facing
			elif absf(global_position.x - _home.x) > 56.0:
				facing = int(signf(_home.x - global_position.x))
			velocity.x = facing * T.v("hound_patrol_speed")
			if not G.peace and absf(to.x) < T.v("hound_notice") and absf(to.y) < 70.0:
				_face(to)
				_go("warn", "idle")
		"warn":
			velocity.x = 0.0
			if _t >= T.v("hound_warning"):
				# high or far: it jumps at you; close and level: it runs you down
				if to.y < -28.0 or absf(to.x) > 96.0:
					velocity = Vector2(facing * T.v("hound_speed") * 0.75, -T.v("hound_pounce"))
					_go("pounce", "jump")
				else:
					_go("charge", "run")
		"charge":
			velocity.x = facing * T.v("hound_speed")
			if _t >= T.v("hound_charge_time") or is_on_wall():
				_go("rest", "idle")
		"pounce":
			if _t > 0.12 and is_on_floor():
				G.main.dust(global_position, 4)
				_go("rest", "idle")
		"rest":
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _t >= T.v("hound_rest"):
				_go("patrol", "walk")
	velocity.y += T.v("gravity") * delta
	move_and_slide()


func _ghost(delta: float, to: Vector2) -> void:
	var aim := to + Vector2(0, -20)
	match state:
		"idle":
			velocity = Vector2(0, sin(_bob) * 6.0)
			if not G.peace and aim.length() < T.v("ghost_notice"):
				_go("chase", "chase")
		"chase":
			_face(aim)
			velocity = aim.normalized() * T.v("ghost_speed") + Vector2(0, sin(_bob) * 8.0)
			if aim.length() > T.v("ghost_notice") + 70.0:
				_go("idle", "idle")
			elif _cool <= 0.0 and aim.length() < 150.0:
				_go("vanish", "vanish")      # the second trick: it blinks out...
		"vanish":
			velocity = Vector2.ZERO
			if _t >= 0.6:
				# ...and comes back right behind her
				var p: Node2D = G.main.player
				global_position = p.global_position + Vector2(-p.facing * 52.0, -24.0)
				_face(p.global_position - global_position)
				_go("warn", "appear")
		"warn":
			velocity = Vector2.ZERO
			if _t > 0.45 and _spr.animation != "shriek":
				_spr.play("shriek")
			if _t >= T.v("ghost_shriek_warning"):
				G.main.ring(global_position, T.v("ghost_shriek_radius"), damage())
				_cool = T.v("ghost_blink_every")
				_go("retreat", "shriek")
		"retreat":
			velocity = -aim.normalized() * T.v("ghost_speed") * 1.4
			if _t >= T.v("ghost_retreat"):
				_go("chase", "chase")
	global_position += velocity * delta


func _choir(delta: float, to: Vector2) -> void:
	match state:
		"idle":
			velocity = Vector2(0, sin(_bob) * 8.0)
			if not G.peace and to.length() < T.v("choir_notice"):
				_go("hover", "idle")
		"hover":
			# it keeps a spot up and to one side of her, out of sword reach
			var side := -1.0 if (_count % 4) < 2 else 1.0
			var spot: Vector2 = G.main.player.global_position + Vector2(side * 84.0, -84.0) + Vector2(0, sin(_bob) * 6.0)
			velocity = (spot - global_position).limit_length(T.v("choir_speed"))
			_face(to)
			if to.length() > T.v("choir_notice") + 90.0:
				_go("idle", "idle")
			elif _cool <= 0.0:
				_count += 1
				_go("warn_dive" if _count % 2 == 0 else "warn_volley", "attack")
		"warn_volley":
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			if _t >= 0.4:
				var base := (to + Vector2(0, -18)).angle()
				for k in [-1, 0, 1]:
					var a: float = base + k * 0.26
					G.main.shoot(global_position, Vector2(cos(a), sin(a)) * T.v("choir_feather_speed"), "feather", damage())
				_cool = T.v("choir_wait")
				_go("hover", "idle")
		"warn_dive":
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			_aim = G.main.player.global_position + Vector2(0, -16)
			if _t >= T.v("choir_dive_warning"):
				velocity = (_aim - global_position).normalized() * T.v("choir_dive_speed")
				_go("dive", "attack")
		"dive":
			# straight through where she stood, then it pulls up again
			if _t >= 0.2 and (global_position.y >= _aim.y or _t >= 0.9):
				_cool = T.v("choir_wait")
				_go("hover", "idle")
	global_position += velocity * delta


func _spitter(delta: float, to: Vector2) -> void:
	var dist := to.length()
	match state:
		"idle":
			velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
			if not G.peace and _cool <= 0.0 and is_on_floor():
				if dist < T.v("spitter_burst_range"):
					_go("warn_burst", "idle")
				elif dist < T.v("spitter_range"):
					_go("warn_lob", "idle")
		"warn_lob":
			if _t >= 0.4:
				# a slow arcing shot that lands where she is standing now
				var fly := 0.85
				var from := global_position + Vector2(0, -30)
				var d: Vector2 = G.main.player.global_position + Vector2(0, -10) - from
				G.main.shoot(from, Vector2(d.x / fly, d.y / fly - 0.5 * T.v("shot_gravity") * fly), "spit", damage())
				_count += 1
				_cool = T.v("spitter_wait")
				if _count % 2 == 0:
					# every second shot it hops to a new spot, back toward its perch if it strayed
					var dir := signf(_home.x - global_position.x) if absf(_home.x - global_position.x) > 30.0 else (1.0 if randf() < 0.5 else -1.0)
					velocity = Vector2(dir * 70.0, -190.0)
					_go("hop", "idle")
				else:
					_go("idle", "idle")
		"warn_burst":
			if _t >= 0.5:
				for k in 5:
					var a := deg_to_rad(-150.0 + k * 30.0)
					G.main.shoot(global_position + Vector2(0, -30), Vector2(cos(a), sin(a)) * 150.0, "spit", damage())
				_cool = T.v("spitter_wait") * 1.2
				_go("idle", "idle")
		"hop":
			if _t > 0.15 and is_on_floor():
				_go("idle", "idle")
	velocity.y += T.v("gravity") * delta
	move_and_slide()


func _warden(delta: float, to: Vector2) -> void:
	match state:
		"idle":
			velocity.x = 0.0
			if not G.peace and to.length() < T.v("warden_notice"):
				_go("stalk", "run")
		"stalk":
			_face(to)
			velocity.x = facing * T.v("warden_speed") if absf(to.x) > 34.0 else 0.0
			if _cool <= 0.0 and is_on_floor() and absf(to.x) < 150.0:
				_count += 1
				# the leap when she is above it or far; the lunge when she is close and level
				var leap := to.y < -40.0 or absf(to.x) > 96.0 or _count % 3 == 0
				_go("warn_leap" if leap else "warn_lunge", "idle")
		"warn_lunge":
			velocity.x = 0.0
			if _t >= T.v("warden_warning"):
				_go("lunge", "run")
		"lunge":
			velocity.x = facing * T.v("warden_lunge_speed")
			if _t >= 0.42 or is_on_wall():
				_cool = T.v("warden_wait")
				_go("rest", "idle")
		"warn_leap":
			velocity.x = 0.0
			_face(to)
			if _t >= T.v("warden_warning"):
				var air := 2.0 * T.v("warden_leap") / T.v("gravity")
				velocity = Vector2(clampf(to.x / air, -210.0, 210.0), -T.v("warden_leap"))
				_go("leap", "run")
		"leap":
			if _t > 0.15 and is_on_floor():
				# the landing cracks the floor: two low waves run outward; jump them
				velocity.x = 0.0
				G.main.shake(3.0, 0.2)
				G.main.dust(global_position, 8)
				Sfx.play("land", 0.6)
				for dir in [-1.0, 1.0]:
					G.main.shoot(global_position + Vector2(dir * 18.0, -6.0), Vector2(dir * T.v("warden_wave_speed"), 0), "shock", damage())
				_cool = T.v("warden_wait")
				_go("rest", "idle")
		"rest":
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if _t >= 0.7:
				_go("stalk", "run")
	velocity.y += T.v("gravity") * delta
	move_and_slide()


func _go(next: String, anim: String) -> void:
	state = next
	_t = 0.0
	if _spr.sprite_frames.has_animation(anim):
		_spr.play(anim)
		_spr.frame = 0


func touched_player() -> void:
	if kind == "ghost" and state == "chase":
		_go("retreat", "shriek")


func can_hurt() -> bool:
	if G.peace or _stun > 0.0:
		return false
	match kind:
		"hound":
			return state == "charge" or state == "pounce" or state == "patrol"
		"ghost":
			return state == "chase"
		"choir":
			return state == "dive"
		"warden":
			return state == "lunge" or state == "leap" or state == "stalk"
	return true      # the spitter: do not hug it


func damage() -> float:
	return T.v(kind + "_damage")


func take_hit(amount: float, dir: int) -> void:
	if kind == "ghost" and state == "vanish":
		return      # nothing there to cut
	hp -= amount
	_flash = 0.1
	if not _d["heavy"]:
		# small enemies flinch and lose their attack; the warden shrugs it off
		_stun = T.v("enemy_stun")
		velocity = Vector2(dir * 70.0, 0.0 if _d["fly"] else -40.0)
		if kind == "hound":
			_go("rest", "idle")
		elif kind == "choir":
			_cool = maxf(_cool, 0.8)
			_go("hover", "idle")
		elif kind == "spitter":
			_cool = maxf(_cool, 0.6)
			_go("idle", "idle")
	if hp <= 0.0:
		G.main.enemy_died(self)
		queue_free()


func _paint() -> void:
	if _d["art"] != 0:
		_spr.flip_h = facing != _d["art"]
	_spr.scale = Vector2.ONE
	var c := Color.WHITE
	if kind == "ghost" and state == "vanish":
		c = Color(1, 1, 1, clampf(1.0 - _t / 0.5, 0.0, 1.0))
	if _flash > 0.0:
		c = Color(4, 4, 4)
	elif state.begins_with("warn"):
		# the warning: a fast orange blink before every attack
		if int(_t * 16.0) % 2 == 0:
			c = Color(2.2, 1.2, 0.5)
		if kind == "spitter":
			# it swells before it spits; the sprite grows from its feet
			var s := 1.0 + 0.18 * clampf(_t / 0.4, 0.0, 1.0)
			_spr.scale = Vector2(s, s)
			_spr.position = Vector2(_d["origin"].x * s, _d["origin"].y * s)
	if not state.begins_with("warn") and kind == "spitter":
		_spr.position = _d["origin"]
	_spr.modulate = c
