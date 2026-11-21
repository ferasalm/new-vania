# PROTOTYPE - NOT FOR PRODUCTION
# THE UNMUZZLED (LUPERCAL-06): the werewolf in the Kennel. Beating him gives the wall jump.
# The idea of the fight: HE SHOWS YOU THE WALL JUMP BEFORE YOU HAVE IT.
#   stalk      he runs at you along the floor. Jump over him or take the hit.
#   leap       he springs to the wall farthest from you
#   cling      he hangs on the wall and watches you (your warning)
#   pounce     he dives at the spot where you stood. Step aside.
#   land_stun  a pounce that hits the floor leaves him dazed: your chance to cut him
#   ricochet   every second time he bounces from wall to wall first, then pounces
# Under half health he is faster (wolf_rage) and bounces twice.
# His brain is a LimboAI behaviour tree (the ORDER of the moves, see _build_tree);
# this script is his body: the moves themselves, the art, health and hits.
# Every feel number is in tuning.json (wolf_*), so F1 tunes him while playing.
extends Node2D

const WolfAct := preload("res://wolf_act.gd")
const BODY := Vector2(40, 52)        # his hit box standing up: width, height
const CLING_RISE := 80.0             # how high on the wall he clings, above the floor
const GRAVITY := 900.0

var boss_id := "unmuzzled"
var kind := "boss"
var hp := 1.0
var alive := true
var started := false
var state := "idle"                  # idle | stalk | leap | cling | ricochet | pounce | land_stun | dying
var floor_y := 0.0
var left_x := 0.0                    # the wall surfaces he clings to
var right_x := 0.0
var _vy := 0.0
var _t := 0.0                        # time in the current move
var _cycle := 0
var _wall := -1.0                    # the wall he is on: -1 left, 1 right
var _target := Vector2.ZERO
var _dir := Vector2.ZERO
var _bounces := 0
var _flash := 0.0
var _dying := 0.0
var _spr: AnimatedSprite2D
var _bt: BTPlayer


func setup(feet: Vector2, room_size: Vector2) -> void:
	floor_y = room_size.y - 32.0
	left_x = 16.0
	right_x = room_size.x - 16.0
	position = feet
	hp = max_hp()
	z_index = 2
	if _spr == null:
		_spr = AnimatedSprite2D.new()
		_spr.sprite_frames = _frames()
		_spr.position = Vector2(0, -38)          # the frames are 96 x 76: feet at the bottom
		add_child(_spr)
		_spr.play("idle")
	if _bt == null:
		_bt = BTPlayer.new()
		_bt.update_mode = BTPlayer.MANUAL
		_bt.set_scene_root_hint(self)
		add_child(_bt)
		_bt.agent_node = NodePath("..")
		_bt.behavior_tree = _build_tree()


func _frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for a in [["idle", 5, 8.0], ["run", 6, 12.0], ["jump", 2, 8.0], ["fall", 2, 8.0]]:
		sf.add_animation(a[0])
		sf.set_animation_speed(a[0], a[2])
		for i in a[1]:
			sf.add_frame(a[0], G.tex("wolf/werewolf-%s%d.png" % [a[0], i + 1]))
	return sf


func _act(move: StringName) -> BTAction:
	var t: BTAction = WolfAct.new()
	t.move = move
	return t


func _build_tree() -> BehaviorTree:
	# for ever: chase, spring to a wall, cling; on a bounce turn ricochet across and cling
	# again; then pounce, and lie dazed where he lands
	var bounce := BTSequence.new()
	bounce.add_child(_act(&"bounce_turn"))
	bounce.add_child(_act(&"ricochet"))
	bounce.add_child(_act(&"cling"))
	var maybe := BTSelector.new()
	maybe.add_child(bounce)
	maybe.add_child(_act(&"skip"))
	var cycle := BTSequence.new()
	for m in [&"stalk", &"leap", &"cling"]:
		cycle.add_child(_act(m))
	cycle.add_child(maybe)
	cycle.add_child(_act(&"pounce"))
	cycle.add_child(_act(&"land_stun"))
	var root := BTRepeat.new()
	root.forever = true
	root.add_child(cycle)
	var bt := BehaviorTree.new()
	bt.root_task = root
	return bt


# ---- the interface the arena, the main scene and the tests use ----

func parts() -> Array:
	return [self]


func max_hp() -> float:
	return T.v("wolf_hp")


func stage() -> int:
	return 2 if hp < max_hp() * 0.5 else 1


func title() -> String:
	return String(Db.table("enemies").get(boss_id, {}).get("name", "THE UNMUZZLED"))


func begin() -> void:
	if started:
		return
	started = true
	state = "stalk"
	if G.main != null and G.main.arena != null:
		G.main.arena.seal()


func body_rect() -> Rect2:
	if state == "cling" and position.y < floor_y - 4.0:
		# on the wall he lies sideways, his feet on the wall
		var w := BODY.y
		return Rect2(position.x if _wall < 0.0 else position.x - w, position.y - BODY.x / 2.0, w, BODY.x)
	return Rect2(position.x - BODY.x / 2.0, position.y - BODY.y, BODY.x, BODY.y)


func hurt_rect() -> Rect2:
	return body_rect()


func can_hurt() -> bool:
	return alive and started and state != "land_stun" and state != "idle"


func damage() -> float:
	return T.v("wolf_damage")


func touched_player() -> void:
	pass


func take_hit(amount: float, _dir_x := 0) -> void:
	if not alive or not started:
		return
	var was := stage()
	hp -= amount
	_flash = 0.1
	if was == 1 and stage() == 2 and hp > 0.0:
		G.main.shake(4.0, 0.5)
		G.main.ring_fx(body_rect().get_center(), 90.0, Color(1.0, 0.3, 0.3))
	if hp <= 0.0:
		hp = 0.0
		alive = false
		state = "dying"
		_dying = 1.6
		G.main.boss_dying()


func hit(amount: float, _part: int) -> void:
	take_hit(amount, 0)


# ---- the moves (the behaviour tree calls these through wolf_act.gd) ----

func _rage() -> float:
	return T.v("wolf_rage") if stage() == 2 else 1.0


func _player() -> Node2D:
	return G.main.player if G.main != null else null


func bt_enter(move: StringName) -> void:
	_t = 0.0
	var p := _player()
	match move:
		&"stalk":
			state = "stalk"
			_cycle += 1
		&"leap":
			state = "leap"
			# the wall farther from her, so his pounce has to cross the room
			var px: float = p.global_position.x if p != null else (left_x + right_x) / 2.0
			_wall = -1.0 if absf(px - left_x) > absf(px - right_x) else 1.0
			_target = Vector2(left_x if _wall < 0.0 else right_x, floor_y - CLING_RISE)
		&"cling":
			state = "cling"
		&"ricochet":
			state = "ricochet"
			_bounces = 2 if stage() == 2 else 1
			_aim_across()
		&"pounce":
			state = "pounce"
			var at: Vector2 = p.global_position if p != null else Vector2((left_x + right_x) / 2.0, floor_y)
			_target = Vector2(clampf(at.x, left_x + 24.0, right_x - 24.0), floor_y)
			_dir = (_target - position).normalized()
			if _dir == Vector2.ZERO:
				_dir = Vector2.DOWN
		&"land_stun":
			state = "land_stun"
			G.main.shake(3.0, 0.25)
			G.main.fx("burst", position + Vector2(0, -6))
			Sfx.play("land", 0.7)


func _aim_across() -> void:
	_wall = -_wall
	_target = Vector2(left_x if _wall < 0.0 else right_x, position.y)


func bt_tick(move: StringName, delta: float) -> int:
	# 0 = still doing it, 1 = done, -1 = did not happen
	_t += delta
	var r := _rage()
	match move:
		&"skip":
			return 1
		&"bounce_turn":
			return 1 if _cycle % 2 == 0 else -1
		&"stalk":
			if _fall(delta):
				return 0
			var p := _player()
			if p != null:
				var dx: float = p.global_position.x - position.x
				if absf(dx) > 6.0:
					position.x = move_toward(position.x, p.global_position.x, T.v("wolf_run_speed") * r * delta)
					_face(signf(dx))
			position.x = clampf(position.x, left_x + BODY.x / 2.0, right_x - BODY.x / 2.0)
			return 1 if _t >= T.v("wolf_stalk_time") / r else 0
		&"leap":
			return 1 if _fly(T.v("wolf_leap_speed") * r, delta) else 0
		&"cling":
			# a hang after a bounce is shorter
			var hold: float = T.v("wolf_cling_time") / r
			if _bounces < 0:
				hold *= 0.5
			if _t >= hold:
				_bounces = 0
				return 1
			return 0
		&"ricochet":
			if _fly(T.v("wolf_ricochet_speed") * r, delta):
				_bounces -= 1
				G.main.fx("spark", position + Vector2(0, -10))
				if _bounces > 0:
					_aim_across()
					return 0
				_bounces = -1          # tells the next cling to be short
				return 1
			return 0
		&"pounce":
			position += _dir * T.v("wolf_pounce_speed") * r * delta
			position.x = clampf(position.x, left_x + BODY.x / 2.0, right_x - BODY.x / 2.0)
			if position.y >= floor_y:
				position.y = floor_y
				return 1
			return 0
		&"land_stun":
			return 1 if _t >= T.v("wolf_land_stun") else 0
	return 1


func _fall(delta: float) -> bool:
	# true while he is still in the air (he starts the fight up on the ledge)
	if position.y >= floor_y:
		position.y = floor_y
		_vy = 0.0
		return false
	_vy += GRAVITY * delta
	position.y = minf(floor_y, position.y + _vy * delta)
	_t = 0.0
	return true


func _fly(speed: float, delta: float) -> bool:
	position = position.move_toward(_target, speed * delta)
	_face(signf(_target.x - position.x))
	return position.distance_to(_target) < 1.0


func _face(dx: float) -> void:
	if dx != 0.0 and _spr != null:
		_spr.flip_h = dx < 0.0


# ---- every frame ----

func _physics_process(delta: float) -> void:
	if G.frozen() or G.leaving(self):
		return
	_flash = maxf(0.0, _flash - delta)
	if not alive:
		_die(delta)
		return
	if started and not G.peace and _bt != null:
		_bt.update(delta)
	elif not started:
		_t += delta
	_paint()


func _die(delta: float) -> void:
	_dying -= delta
	_fall(delta)
	if int(_dying * 8.0) != int((_dying + delta) * 8.0):
		G.main.fx("burst", body_rect().get_center() + Vector2(randf_range(-16, 16), randf_range(-20, 20)))
		Sfx.play("enemy_die", randf_range(0.6, 1.0))
	_spr.rotation = 0.0
	_spr.modulate = Color(3, 3, 3) if int(_dying * 14.0) % 2 == 0 else Color(1.0, 0.5, 0.5)
	if _dying <= 0.0:
		G.main.boss_died(position + Vector2(0, -8))
		queue_free()


func _paint() -> void:
	var anim := "idle"
	_spr.rotation = 0.0
	_spr.position = Vector2(0, -38)
	match state:
		"stalk":
			anim = "run" if position.y >= floor_y else "fall"
		"leap", "ricochet":
			anim = "jump"
		"pounce":
			anim = "fall"
		"cling":
			anim = "idle"
			if position.y < floor_y - 4.0:
				# sideways on the wall, feet on the wall, looking into the room
				_spr.rotation = PI / 2.0 if _wall < 0.0 else -PI / 2.0
				_spr.position = Vector2(0, -38).rotated(_spr.rotation)      # turn about his feet
		"land_stun":
			anim = "idle"
	if _spr.animation != anim:
		_spr.play(anim)
	if state == "land_stun":
		_spr.modulate = Color(0.75, 0.75, 1.0)
		_spr.speed_scale = 0.3
	else:
		_spr.modulate = Color(3, 3, 3) if _flash > 0.0 else (Color(1.2, 0.85, 0.85) if stage() == 2 else Color.WHITE)
		_spr.speed_scale = _rage()
