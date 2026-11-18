# PROTOTYPE - NOT FOR PRODUCTION
# The boss: the Pallbearer. A hooded shape that floats too high to reach, and its
# two golden hands that fight for it.
# The idea of the fight: ITS ATTACKS ARE YOUR STAIRS. A hand that slams the floor
# stays stuck there for a few seconds. Stand on it and jump, and you can reach the
# body. Hitting a hand hurts it only a little; the body takes full damage.
#   slam   a hand hovers over you (watch the shadow), hangs, then drops. Step aside, then climb it.
#   sweep  a hand slides along the floor from one wall to the other. Jump it.
#   bolts  golden bolts fly across: chest height (crouch) then floor height (jump).
#   clap   (second half) both hands rush together where you stand. Jump out; they stay stuck as a wide step.
#   reap   a hand takes ELEGY-013 (the scythe it keeps), glows for a moment, and a huge slash crosses the
#          room at chest height: crouch or slide under it. Every second reap is low: jump it.
#   throw  a hand takes the scythe, glows, and throws it: it spins across at one height and comes back at
#          another. Crouch the first pass, hop the second (or the other way round).
# Under half health everything is quicker and the clap joins in.
extends Node2D

const HAND := Vector2(36, 36)

var hp := 1.0
var alive := true
var started := false
var floor_y := 0.0
var left_x := 0.0
var right_x := 0.0
var _body: Sprite2D
var _hands: Array = []       # two dictionaries, see _make_hand
var _parts: Array = []       # what her weapon can hit: the body and both hands
var _t := 0.0
var _gap := 2.0
var _cycle := 0
var _phase := 1
var _flash := 0.0
var _cast := 0.0             # > 0 while the body glows before the bolts
var _bolts: Array = []       # times left until each queued bolt: [wait, high?, dir]
var _dying := 0.0
var _home := Vector2.ZERO
var _slash := {"on": false}  # the flying scythe or slash: x, dirx, h (height above the floor), kind, leg, spin, box
var _reaps := 0              # how many reaps so far: every second one is low
var _throws := 0


func setup(feet: Vector2, room_size: Vector2) -> void:
	floor_y = feet.y
	left_x = 34.0
	right_x = room_size.x - 34.0
	_home = Vector2(feet.x, floor_y - 140.0)
	hp = T.v("boss_hp")
	z_index = 2
	_body = Sprite2D.new()
	_body.texture = G.tex("boss/body.png")
	_body.position = _home + Vector2(0, -120)      # it comes down from the dark
	add_child(_body)
	for side in [-1.0, 1.0]:
		_hands.append(_make_hand(side))
	_parts.append(Part.new(self, -1))
	for i in 2:
		_parts.append(Part.new(self, i))
	for p in _parts:
		add_child(p)


func parts() -> Array:
	return _parts


func _make_hand(side: float) -> Dictionary:
	var s := Sprite2D.new()
	s.texture = G.tex("boss/hand.png")
	s.flip_h = side < 0.0
	s.position = _home + Vector2(side * 50.0, -100.0)
	add_child(s)
	# while a hand is stuck in the floor its top is a ledge she can stand on
	var body := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(HAND.x - 4.0, 6.0)
	shape.shape = rect
	shape.one_way_collision = true
	shape.position = Vector2(0, -HAND.y / 2.0 + 5.0)
	shape.disabled = true
	body.add_child(shape)
	s.add_child(body)
	return {"spr": s, "side": side, "state": "rest", "t": 0.0, "shape": shape, "dir": 1.0, "meet": 0.0}


func begin() -> void:
	started = true
	_gap = 1.6


func body_rect() -> Rect2:
	return Rect2(_body.position + Vector2(-16, -34), Vector2(32, 50))


func hand_rect(i: int) -> Rect2:
	return Rect2(_hands[i]["spr"].position - HAND / 2.0 + Vector2(3, 3), HAND - Vector2(6, 6))


func hit(amount: float, part: int) -> void:
	if not alive or not started:
		return
	hp -= amount * (1.0 if part < 0 else T.v("boss_hand_share"))
	_flash = 0.1
	if _phase == 1 and hp <= T.v("boss_hp") * 0.5:
		_phase = 2
		G.main.shake(4.0, 0.5)
		G.main.ring_fx(_body.position, 90.0, Color(1.0, 0.3, 0.9))
		G.main.hud.toast("IT WILL NOT LET GO")
		_gap = 1.8
	if hp <= 0.0:
		hp = 0.0
		alive = false
		_dying = 2.2
		for h in _hands:
			h["state"] = "dead"
			h["shape"].set_deferred("disabled", true)
		G.main.boss_dying()


func _physics_process(delta: float) -> void:
	if G.frozen():
		return
	_t += delta
	_flash = maxf(0.0, _flash - delta)
	if not alive:
		_die(delta)
		return
	var player: Node2D = G.main.player
	# the body: floats, and drifts to hang right above a hand that is stuck
	var want_x := clampf(player.global_position.x, left_x + 40.0, right_x - 40.0)
	var speed := 26.0
	for h in _hands:
		if h["state"] == "stuck":
			want_x = h["spr"].position.x
			speed = 80.0
	var target := Vector2(want_x, _home.y + sin(_t * 1.7) * 5.0)
	if not started:
		_body.position = _body.position.move_toward(Vector2(_home.x, target.y), 70.0 * delta)
	else:
		_body.position.x = move_toward(_body.position.x, target.x, speed * delta)
		_body.position.y = move_toward(_body.position.y, target.y, 60.0 * delta)
	for i in 2:
		_hand(i, delta, player)
	if started and not G.peace:
		_think(delta, player)
	_slash_step(delta, player)
	_paint()
	queue_redraw()


func _free_hand() -> int:
	# the next resting hand, alternating sides
	for k in 2:
		var i := (_cycle + k) % 2
		if _hands[i]["state"] == "rest":
			return i
	return -1


func _think(delta: float, player: Node2D) -> void:
	# queued bolts leave one after another
	for b in _bolts.duplicate():
		b[0] -= delta
		if b[0] <= 0.0:
			_bolts.erase(b)
			var from_x := left_x - 10.0 if b[2] > 0.0 else right_x + 10.0
			var y := floor_y - (30.0 if b[1] else 7.0)
			G.main.shoot(Vector2(from_x, y), Vector2(b[2] * T.v("boss_bolt_speed"), 0), "bolt", T.v("boss_damage"))
			Sfx.play("special", 1.4)
	if _cast > 0.0:
		_cast -= delta
	_gap -= delta
	if _gap > 0.0:
		return
	var plan: Array = ["slam", "reap", "slam", "bolts", "throw", "sweep"] if _phase == 1 \
		else ["slam", "reap", "clap", "bolts", "throw", "slam", "reap", "sweep"]
	var act: String = plan[_cycle % plan.size()]
	var quick := 1.0 if _phase == 1 else 0.7
	if act == "bolts":
		_cast = 0.7
		var dir := 1.0 if player.global_position.x > (left_x + right_x) / 2.0 else -1.0
		var n := 3 if _phase == 1 else 5
		for k in n:
			_bolts.append([0.7 + k * 0.55 * quick, k % 2 == 0, dir])
		_gap = T.v("boss_gap") * quick + n * 0.5
	elif act == "clap" and _hands[0]["state"] == "rest" and _hands[1]["state"] == "rest":
		for h in _hands:
			h["state"] = "clap_ready"
			h["t"] = 0.0
		_gap = T.v("boss_gap") * quick + 2.4
	else:
		var i := _free_hand()
		if i < 0 or (act in ["reap", "throw"] and _slash["on"]):
			_gap = 0.3       # both hands are busy: look again in a moment
			return
		var h: Dictionary = _hands[i]
		h["state"] = {"sweep": "sweep_ready", "reap": "reap_ready", "throw": "throw_ready"}.get(act, "track")
		h["t"] = 0.0
		h["dir"] = 1.0 if player.global_position.x > (left_x + right_x) / 2.0 else -1.0
		if act == "reap":
			# every second reap is low: the first is chest height (duck), the next is near the floor (jump)
			h["low"] = _reaps % 2 == 1
			_reaps += 1
		elif act == "throw":
			h["low"] = _throws % 2 == 1      # which height it goes out at; it comes back at the other
			_throws += 1
		var across := (right_x - left_x) / maxf(1.0, T.v("boss_reap_speed") * (1.0 if _phase == 1 else 1.3))
		match act:
			"slam":
				_gap = T.v("boss_gap") * quick + 0.6
			"reap":
				_gap = T.v("boss_gap") * quick + T.v("boss_reap_warn") + across + 0.4
			"throw":
				_gap = T.v("boss_gap") * quick + T.v("boss_reap_warn") + 2.0 * (right_x - left_x) / maxf(1.0, T.v("boss_throw_speed") * (1.0 if _phase == 1 else 1.3)) + 0.4
			_:
				_gap = T.v("boss_gap") * quick + 1.2
	_cycle += 1


func _hand(i: int, delta: float, player: Node2D) -> void:
	var h: Dictionary = _hands[i]
	var s: Sprite2D = h["spr"]
	var quick := 1.0 if _phase == 1 else 1.3
	var ground := floor_y - HAND.y / 2.0
	h["t"] += delta
	var danger := false
	match h["state"]:
		"rest":
			var spot := _body.position + Vector2(h["side"] * 48.0, 6.0 + sin(_t * 2.3 + h["side"]) * 5.0)
			s.position = s.position.move_toward(spot, 150.0 * delta)
		"track":
			# it hovers over her head; its shadow on the floor shows where it will land
			var above := Vector2(clampf(player.global_position.x, left_x, right_x), floor_y - 118.0)
			s.position = s.position.move_toward(above, T.v("boss_hand_speed") * quick * delta)
			if h["t"] >= T.v("boss_slam_track") / quick:
				h["state"] = "hang"
				h["t"] = 0.0
		"hang":
			s.position.x += sin(h["t"] * 80.0) * 0.6
			if h["t"] >= T.v("boss_slam_hang"):
				h["state"] = "fall"
		"fall":
			danger = true
			s.position.y += T.v("boss_slam_speed") * delta
			if s.position.y >= ground:
				s.position.y = ground
				_stick(h)
		"stuck":
			if h["t"] >= T.v("boss_stuck") - 0.6:
				s.position.x += sin(h["t"] * 70.0) * 0.5      # it shivers before it pulls free
			if h["t"] >= T.v("boss_stuck"):
				h["shape"].set_deferred("disabled", true)
				h["state"] = "rest"
		"sweep_ready":
			var start := Vector2(right_x if h["dir"] > 0.0 else left_x, ground)
			s.position = s.position.move_toward(start, 260.0 * delta)
			if h["t"] >= T.v("boss_sweep_warning") / quick + 0.5:
				h["state"] = "sweep"
		"sweep":
			danger = true
			s.position.x -= h["dir"] * T.v("boss_sweep_speed") * quick * delta
			if s.position.x < left_x or s.position.x > right_x:
				h["state"] = "rest"
		"reap_ready", "throw_ready":
			# the hand carries the scythe to the wall on her side and holds it up, glowing
			var low: bool = h.get("low", false)
			var band: float = T.v("boss_reap_low") if (low and h["state"] == "reap_ready") else T.v("boss_reap_high")
			var start_h := Vector2(right_x if h["dir"] > 0.0 else left_x, floor_y - band - 14.0)
			s.position = s.position.move_toward(start_h, 320.0 * delta)
			if h["t"] >= T.v("boss_reap_warn") / quick + 0.25:
				_launch(h)
				h["state"] = "reap" if h["state"] == "reap_ready" else "throw"
				h["t"] = 0.0
		"reap", "throw":
			# the hand lets go; it waits at the wall until the scythe is gone
			if not _slash["on"]:
				h["state"] = "rest"
		"clap_ready":
			var edge := Vector2(left_x if h["side"] < 0.0 else right_x, ground)
			s.position = s.position.move_toward(edge, 300.0 * delta)
			h["meet"] = clampf(player.global_position.x, left_x + 60.0, right_x - 60.0)
			if h["t"] >= T.v("boss_sweep_warning") + 0.7:
				h["state"] = "clap"
		"clap":
			danger = true
			var stop: float = h["meet"] + h["side"] * (HAND.x / 2.0)
			s.position.x = move_toward(s.position.x, stop, T.v("boss_sweep_speed") * 1.25 * delta)
			if is_equal_approx(s.position.x, stop):
				_stick(h)
				h["t"] = -T.v("boss_stuck") * 0.3     # the clap leaves them stuck a little longer
	h["danger"] = danger
	if danger and not G.peace and hand_rect(i).intersects(player.body_rect()):
		player.take_hit(T.v("boss_damage"), s.position.x)


func _launch(h: Dictionary) -> void:
	# the scythe leaves the hand: a slash for the reap, the spinning scythe itself for the throw
	var reap: bool = h["state"] == "reap_ready"
	var low: bool = h.get("low", false)
	var out_h: float = T.v("boss_reap_low") if low else T.v("boss_reap_high")
	var back_h: float = T.v("boss_reap_high") if low else T.v("boss_reap_low")
	_slash = {"on": true, "kind": "reap" if reap else "throw", "x": h["spr"].position.x, "dirx": -h["dir"],
		"h": out_h, "h_back": back_h, "leg": 0, "spin": 0.0, "start_x": h["spr"].position.x, "box": Rect2()}
	Sfx.play("special", 0.8)
	Sfx.play_file("sfx/world/blade_swing.wav", -3.0, 0.8 if reap else 1.0)
	G.main.shake(2.0, 0.2)


func _slash_step(delta: float, player: Node2D) -> void:
	if not _slash["on"]:
		return
	if not alive:
		_slash["on"] = false
		return
	var quick := 1.0 if _phase == 1 else 1.3
	var reap: bool = _slash["kind"] == "reap"
	var speed: float = (T.v("boss_reap_speed") if reap else T.v("boss_throw_speed")) * quick
	_slash["x"] += _slash["dirx"] * speed * delta
	_slash["spin"] += delta * 16.0
	var x: float = _slash["x"]
	var thick: float = T.v("boss_reap_thick")
	if reap:
		if x < left_x - 60.0 or x > right_x + 60.0:
			_slash["on"] = false
	elif _slash["leg"] == 0:
		if (_slash["dirx"] < 0.0 and x < left_x - 14.0) or (_slash["dirx"] > 0.0 and x > right_x + 14.0):
			_slash["leg"] = 1       # at the far wall it turns and comes back at the other height
			_slash["dirx"] = -_slash["dirx"]
			_slash["h"] = _slash["h_back"]
			G.main.shake(1.5, 0.12)
			Sfx.play_file("sfx/world/blade_swing.wav", -6.0, 1.2)
	elif (_slash["dirx"] > 0.0 and x > _slash["start_x"] + 40.0) or (_slash["dirx"] < 0.0 and x < _slash["start_x"] - 40.0):
		_slash["on"] = false
	var half_w := 38.0 if reap else 13.0
	var box := Rect2(Vector2(x - half_w, floor_y - float(_slash["h"]) - thick / 2.0), Vector2(half_w * 2.0, thick))
	_slash["box"] = box
	if _slash["on"] and not G.peace and box.intersects(player.body_rect()):
		player.take_hit(T.v("boss_damage"), x)


func _stick(h: Dictionary) -> void:
	h["state"] = "stuck"
	h["t"] = 0.0
	h["shape"].set_deferred("disabled", false)
	G.main.shake(3.5, 0.22)
	G.main.dust(h["spr"].position + Vector2(0, HAND.y / 2.0), 10)
	Sfx.play("land", 0.55)


func _die(delta: float) -> void:
	_dying -= delta
	_body.position += Vector2(randf_range(-1, 1), randf_range(-1, 1))
	_body.modulate = Color(3, 3, 3) if int(_dying * 14.0) % 2 == 0 else Color(1.0, 0.6, 1.0)
	for h in _hands:
		h["spr"].modulate.a = maxf(0.0, h["spr"].modulate.a - delta)
		h["spr"].position.y += 30.0 * delta
	if int(_dying * 8.0) != int((_dying + delta) * 8.0):
		G.main.fx("burst", _body.position + Vector2(randf_range(-22, 22), randf_range(-40, 40)))
		Sfx.play("enemy_die", randf_range(0.6, 1.0))
	queue_redraw()
	if _dying <= 0.0:
		G.main.boss_died(_body.position)
		queue_free()


func _paint() -> void:
	var c := Color.WHITE if _phase == 1 else Color(1.25, 0.8, 1.0)
	if _cast > 0.0 and int(_cast * 16.0) % 2 == 0:
		c = Color(2.4, 1.8, 0.6)      # gold blink: bolts are coming
	if _flash > 0.0:
		c = Color(4, 4, 4)
	_body.modulate = c
	for h in _hands:
		var hc := Color.WHITE
		var warn: bool = h["state"] == "hang" or h["state"] == "sweep_ready" or h["state"] == "clap_ready" \
			or h["state"] == "reap_ready" or h["state"] == "throw_ready"
		if warn and int(h["t"] * 16.0) % 2 == 0:
			hc = Color(2.4, 1.3, 0.6)
		elif h["state"] == "stuck":
			hc = Color(0.8, 0.9, 1.0)
		h["spr"].modulate = hc


func _draw() -> void:
	if not alive:
		return
	_draw_scythe()
	for h in _hands:
		if h["state"] == "track" or h["state"] == "hang" or h["state"] == "fall":
			# the landing mark
			var x: float = h["spr"].position.x
			var a := 0.35 if h["state"] == "track" else 0.7
			draw_rect(Rect2(x - 16.0, floor_y - 2.0, 32.0, 2.0), Color(1.0, 0.75, 0.2, a))
			draw_rect(Rect2(x - 10.0, floor_y - 3.0, 20.0, 1.0), Color(1.0, 0.9, 0.5, a))
		elif h["state"] == "stuck":
			# an arrow: climb here
			var p: Vector2 = h["spr"].position + Vector2(0, -HAND.y / 2.0 - 8.0 - absf(sin(_t * 5.0)) * 3.0)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(4, 0), p + Vector2(0, -5)]), Color(0.6, 1.0, 1.0, 0.9))


func _draw_scythe() -> void:
	# the scythe in a hand that is about to use it (scaled up, blinking), the lane it will cross
	# at, and the flying slash or the spinning scythe
	var tex := G.tex("weapon/elegy.png")
	for h in _hands:
		if h["state"] != "reap_ready" and h["state"] != "throw_ready":
			continue
		var reap: bool = h["state"] == "reap_ready"
		var band: float = T.v("boss_reap_low") if (h.get("low", false) and reap) else T.v("boss_reap_high")
		var blink := int(h["t"] * 16.0) % 2 == 0
		var lane_a := 0.12 + (0.25 if blink else 0.0)
		draw_rect(Rect2(left_x - 20.0, floor_y - band - T.v("boss_reap_thick") / 2.0, right_x - left_x + 40.0, T.v("boss_reap_thick")),
			Color(1.0, 0.6, 0.2, lane_a))
		var p: Vector2 = h["spr"].position
		var face := -float(h["dir"])      # the way it will fly
		draw_set_transform(p + Vector2(face * 6.0, -4.0), -0.35 * face, Vector2(2.2 * face, 2.2))
		draw_texture(tex, -Vector2(10, 10), Color(2.4, 1.8, 0.7) if blink else Color(0.8, 1.0, 1.0))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not _slash["on"]:
		return
	var box: Rect2 = _slash["box"]
	var c := box.get_center()
	if _slash["kind"] == "reap":
		var d: float = _slash["dirx"]
		var f := d * 38.0
		draw_colored_polygon(PackedVector2Array([c + Vector2(f, 0), c + Vector2(f * 0.45, -box.size.y * 0.5 - 2.0),
			c + Vector2(-f, -box.size.y * 0.5 - 9.0), c + Vector2(-f * 0.7, 0), c + Vector2(-f, box.size.y * 0.5 + 9.0),
			c + Vector2(f * 0.45, box.size.y * 0.5 + 2.0)]), Color(1.0, 0.8, 0.35, 0.85))
		draw_colored_polygon(PackedVector2Array([c + Vector2(f * 0.9, 0), c + Vector2(f * 0.4, -box.size.y * 0.25),
			c + Vector2(-f * 0.4, 0), c + Vector2(f * 0.4, box.size.y * 0.25)]), Color(1.0, 1.0, 0.9, 0.95))
		for k in range(1, 4):
			draw_rect(Rect2(c.x - d * (40.0 + k * 14.0), c.y - 1.0, 12.0, 2.0), Color(1.0, 0.8, 0.4, 0.5 - 0.1 * k))
	else:
		draw_circle(c, 15.0, Color(1.0, 0.7, 0.3, 0.18))
		draw_set_transform(c, _slash["spin"], Vector2(1.1, 1.1))
		draw_texture(tex, -tex.get_size() / 2.0, Color(1.6, 1.3, 0.8))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(box, Color(1.0, 0.5, 0.2, 0.25), false, 1.0)


# One hittable piece of the boss. The main scene treats it like an enemy that never
# touches you: the hands hurt through the boss itself.
class Part extends Node2D:
	var boss: Node2D
	var index := -1
	var kind := "boss"

	func _init(owner_boss: Node2D, i: int) -> void:
		boss = owner_boss
		index = i

	func hurt_rect() -> Rect2:
		return boss.body_rect() if index < 0 else boss.hand_rect(index)

	func can_hurt() -> bool:
		return false

	func damage() -> float:
		return 0.0

	func touched_player() -> void:
		pass

	func take_hit(amount: float, _dir: int) -> void:
		boss.hit(amount, index)
