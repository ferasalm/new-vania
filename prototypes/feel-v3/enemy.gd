# PROTOTYPE - NOT FOR PRODUCTION
# Two enemies, one clear behaviour each, both warn before they hurt you.
#   hound: patrols, flashes, then charges along the floor.
#   ghost: drifts through walls toward you, backs off after touching you.
extends CharacterBody2D

const KINDS := {
	"hound": {"hp": 30.0, "damage": 8.0, "box": Vector2(34, 20), "origin": Vector2(-32, -48),
		"fps": {"idle": 10.0, "walk": 12.0, "run": 14.0, "jump": 10.0}},
	"ghost": {"hp": 20.0, "damage": 6.0, "box": Vector2(22, 34), "origin": Vector2(-32, -42),
		"fps": {"idle": 8.0, "chase": 8.0, "shriek": 10.0, "appear": 10.0, "vanish": 10.0}},
}

var kind := "hound"
var hp := 1.0
var facing := -1
var state := "idle"
var _t := 0.0
var _stun := 0.0
var _flash := 0.0
var _home := Vector2.ZERO
var _spr: AnimatedSprite2D
var _box := Vector2.ZERO
var _bob := 0.0


func setup(k: String) -> void:
	kind = k
	var d: Dictionary = KINDS[k]
	hp = d["hp"]
	_box = d["box"]
	_spr = G.sprite(k, d["fps"])
	_spr.position = d["origin"]
	add_child(_spr)
	collision_layer = 8
	if k == "hound":
		collision_mask = 1 | 2
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = _box
		shape.shape = rect
		shape.position = Vector2(0, -_box.y / 2.0)
		add_child(shape)
		state = "patrol"
		_spr.play("walk")
	else:
		collision_mask = 0
		state = "idle"
		_spr.play("idle")
		_bob = randf() * TAU


func _ready() -> void:
	_home = global_position


func hurt_rect() -> Rect2:
	if kind == "ghost":
		return Rect2(global_position - _box / 2.0, _box)
	return Rect2(global_position + Vector2(-_box.x / 2.0, -_box.y), _box)


func _physics_process(delta: float) -> void:
	if G.frozen():
		return
	_flash = maxf(0.0, _flash - delta)
	var player: Node2D = G.main.player
	var to := player.global_position - global_position
	if _stun > 0.0:
		_stun -= delta
		if kind == "hound":
			velocity.y += T.v("gravity") * delta
			move_and_slide()
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		else:
			global_position += velocity * delta
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
		_paint()
		return
	if kind == "hound":
		_hound(delta, to)
	else:
		_ghost(delta, to)
	_paint()


func _hound(delta: float, to: Vector2) -> void:
	_t += delta
	match state:
		"patrol":
			# turn first, so the walk speed below already points away from the wall
			if is_on_wall():
				facing = int(signf(get_wall_normal().x)) if get_wall_normal().x != 0.0 else -facing
			elif absf(global_position.x - _home.x) > 56.0:
				facing = int(signf(_home.x - global_position.x))
			velocity.x = facing * T.v("hound_patrol_speed")
			if not G.peace and absf(to.x) < T.v("hound_notice") and absf(to.y) < 44.0:
				facing = int(signf(to.x)) if to.x != 0.0 else facing
				_go("warn", "idle")
		"warn":
			velocity.x = 0.0
			if _t >= T.v("hound_warning"):
				_go("charge", "run")
		"charge":
			velocity.x = facing * T.v("hound_speed")
			if _t >= T.v("hound_charge_time") or is_on_wall():
				_go("rest", "idle")
		"rest":
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _t >= T.v("hound_rest"):
				_go("patrol", "walk")
	velocity.y += T.v("gravity") * delta
	move_and_slide()


func _ghost(delta: float, to: Vector2) -> void:
	_t += delta
	_bob += delta * 3.0
	var aim := to + Vector2(0, -20)
	match state:
		"idle":
			velocity = Vector2(0, sin(_bob) * 6.0)
			if not G.peace and aim.length() < T.v("ghost_notice"):
				_go("chase", "chase")
		"chase":
			facing = int(signf(aim.x)) if aim.x != 0.0 else facing
			velocity = aim.normalized() * T.v("ghost_speed") + Vector2(0, sin(_bob) * 8.0)
			if aim.length() > T.v("ghost_notice") + 70.0:
				_go("idle", "idle")
		"retreat":
			velocity = -aim.normalized() * T.v("ghost_speed") * 1.4
			if _t >= T.v("ghost_retreat"):
				_go("chase", "chase")
	global_position += velocity * delta


func _go(next: String, anim: String) -> void:
	state = next
	_t = 0.0
	_spr.play(anim)


func touched_player() -> void:
	if kind == "ghost":
		_go("retreat", "shriek")


func can_hurt() -> bool:
	if G.peace or _stun > 0.0:
		return false
	return state == "charge" or kind == "ghost" or state == "patrol"


func damage() -> float:
	return float(KINDS[kind]["damage"])


func take_hit(amount: float, dir: int) -> void:
	hp -= amount
	_flash = 0.1
	_stun = T.v("enemy_stun")
	velocity = Vector2(dir * 70.0, -40.0 if kind == "hound" else 0.0)
	if kind == "hound":
		_go("rest", "idle")
	if hp <= 0.0:
		G.main.enemy_died(self)
		queue_free()


func _paint() -> void:
	_spr.flip_h = facing > 0   # the art faces left
	if _flash > 0.0:
		_spr.modulate = Color(4, 4, 4)
	elif state == "warn":
		# the warning: a fast orange blink before the charge
		_spr.modulate = Color(2.2, 1.2, 0.5) if int(_t * 16.0) % 2 == 0 else Color.WHITE
	else:
		_spr.modulate = Color.WHITE
