# PROTOTYPE - NOT FOR PRODUCTION
# Four heavy hazards for the hazard rooms. Each runs on its own beat and warns before it hurts.
# Neighbours get different phase offsets (from their x), so there is a rhythm and a safe moment.
#   pendulum  a giant blade on a long arm from the ceiling, swinging side to side
#   crusher   an iron block on a piston: rattles and trickles dust, then slams to the floor
#   flame     a floor grate: glows and hisses, then a flame column
#   spikes    a floor strip: glints and rumbles, then spikes thrust up
# With G.peace on they still move (the room looks alive) but never hurt.
# Use: var h = load("res://hazard.gd").new(); h.setup(kind, rect); world.add_child(h)
extends Node2D

const IRON_D := Color(0.1, 0.09, 0.13)
const IRON := Color(0.22, 0.2, 0.26)
const IRON_L := Color(0.45, 0.43, 0.52)
const STEEL := Color(0.86, 0.9, 1.0)
const BRASS := Color(0.72, 0.55, 0.25)
const BRASS_D := Color(0.4, 0.29, 0.12)
const BONE := Color(0.88, 0.82, 0.68)
const BLOOD := Color(0.5, 0.08, 0.1)
const HOT := Color(1.0, 0.55, 0.15)
const BH := 28.0          # crusher block height

var kind := "spikes"
var rect := Rect2()
var state := ""
var _s := 0.0             # seconds in the current state
var _clock := 0.0
var _cx := 0.0
var _floor_y := 0.0
var _ceil_y := 0.0
var _len := 100.0
var _swing_t := 0.0
var _prev_ang := 0.0
var _by := 0.0            # crusher block top
var _bw := 24.0
var _rise_from := 0.0
var _rattle := 0.0
var _tick := 0.0
var _silent := true
var _specks: Array = []   # {p, v, life, max, col}
var _fx: Node2D


func setup(k: String, r: Rect2) -> void:
	kind = k
	rect = r
	position = Vector2.ZERO
	z_index = 2
	_cx = r.get_center().x
	var room: Node2D = G.main.room
	var cx := int(floor(_cx / 16.0))
	var row := int(floor(r.position.y / 16.0))
	var cr := row
	while cr > 0 and room.cell(cx, cr - 1) != "#":
		cr -= 1
	_ceil_y = float(cr) * 16.0
	var fr := row
	while fr < room.grid.size() and room.cell(cx, fr) != "#" and room.cell(cx, fr) != "=":
		fr += 1
	_floor_y = float(fr) * 16.0
	_bw = maxf(32.0, r.size.x)
	match kind:
		"pendulum":
			_len = maxf(32.0, _floor_y - T.v("pendulum_clearance") - _ceil_y - 10.0)
		"crusher":
			_by = _ceil_y
	_fx = Fx.new()
	_fx.owner_h = self
	add_child(_fx)
	# a different beat for every hazard, derived from where it stands
	var ph := fposmod(float(cx) * 0.618034, 1.0)
	set_phase(ph * _period())


func _ready() -> void:
	add_to_group("hazard")


func _names() -> Array:
	match kind:
		"crusher":
			return ["wait", "warn", "fall", "sit", "rise"]
		"flame":
			return ["idle", "warn", "active"]
		"spikes":
			return ["hidden", "warn", "up"]
	return ["swing"]


func _dur(s: String) -> float:
	match kind:
		"crusher":
			match s:
				"wait":
					return T.v("crusher_wait")
				"warn":
					return T.v("crusher_warn")
				"sit":
					return T.v("crusher_sit")
				"rise":
					return T.v("crusher_rise")
				_:
					return 99.0
		"flame":
			match s:
				"idle":
					return T.v("flame_idle")
				"warn":
					return T.v("flame_warn")
				_:
					return T.v("flame_time")
		"spikes":
			match s:
				"hidden":
					return T.v("spikes_hidden")
				"warn":
					return T.v("spikes_warn")
				_:
					return T.v("spikes_up")
	return T.v("pendulum_period")


func _period() -> float:
	if kind == "pendulum":
		return T.v("pendulum_period")
	var total := 0.0
	for n in _names():
		total += _dur(n) if _dur(n) < 90.0 else 0.15
	return total


func set_phase(sec: float) -> void:
	# start the beat `sec` seconds into its cycle (quietly: no sounds, no shake)
	_silent = true
	if kind == "pendulum":
		_swing_t = sec
		_prev_ang = _ang()
		state = "swing"
		_silent = false
		return
	_set_state(_names()[0])
	var left := sec
	while left > 0.0:
		_step(0.05)
		left -= 0.05
	_silent = false


func jump_to(s: String) -> void:
	# tests and tools: go straight to a named state
	_set_state(s)


func _set_state(s: String) -> void:
	state = s
	_s = 0.0
	if kind == "crusher":
		match s:
			"wait":
				_by = _ceil_y
			"sit":
				_by = _floor_y - BH
			"rise":
				_rise_from = _floor_y - BH
			"warn":
				_by = _ceil_y
	_enter(s)


func _enter(s: String) -> void:
	if _silent:
		return
	match kind:
		"crusher":
			match s:
				"warn":
					_snd("crusher_warn", -3.0)
				"sit":
					_snd("crusher_slam", -1.0)
					_shake(3.0, 0.25)
					if G.main != null:
						G.main.dust(Vector2(_cx, _floor_y), 8)
					for i in 14:
						_speck(Vector2(_cx + randf_range(-_bw * 0.5, _bw * 0.5), _floor_y - 2.0), Vector2(randf_range(-70.0, 70.0), randf_range(-90.0, -30.0)), 0.5, Color(0.7, 0.66, 0.6))
		"flame":
			match s:
				"warn":
					_snd("vent_hiss", -3.0)
				"active":
					_snd("vent_flame", -2.0)
		"spikes":
			match s:
				"warn":
					_snd("crab_burrow", -12.0, 0.6)
					_shake(0.7, 0.4)
				"up":
					_snd("spikes", -2.0)


# ---------- the beat ----------

func _physics_process(delta: float) -> void:
	if G.frozen() or G.main == null or G.main.player == null:
		return
	_clock += delta
	_step(delta)
	_tick += delta
	if _tick >= 0.05:
		_tick = 0.0
		_emit()
	for sp in _specks:
		sp["life"] -= delta
		sp["p"] += sp["v"] * delta
		sp["v"] += Vector2(0.0, 220.0) * delta
	_specks = _specks.filter(func(s): return s["life"] > 0.0)
	queue_redraw()
	_fx.queue_redraw()
	if Util.can_hit():
		var p: Node2D = G.main.player
		if p.invuln <= 0.0 and hits(p.body_rect()):
			p.take_hit(T.v(kind + "_damage"), _hit_x(), "trap")


func _step(dt: float) -> void:
	match kind:
		"pendulum":
			_swing_t += dt
			var a := _ang()
			if (a > 0.0) != (_prev_ang > 0.0) and not _silent:
				_snd("blade_swing", -4.0, randf_range(0.9, 1.1))
			_prev_ang = a
			return
		"crusher":
			_rattle = 0.0
			match state:
				"warn":
					_rattle = 0.7
				"fall":
					_by += T.v("crusher_fall_speed") * dt
					if _by + BH >= _floor_y:
						_by = _floor_y - BH
						_set_state("sit")
						return
				"rise":
					var k := clampf(_s / maxf(0.05, _dur("rise")), 0.0, 1.0)
					_by = lerpf(_rise_from, _ceil_y, k * k * (3.0 - 2.0 * k))
	_s += dt
	var d := _dur(state)
	if _s >= d:
		_s -= d
		var names := _names()
		_set_state(names[(names.find(state) + 1) % names.size()])


func _ang() -> float:
	return deg_to_rad(T.v("pendulum_angle")) * sin(TAU * _swing_t / maxf(0.5, T.v("pendulum_period")))


func _ang_at(back: float) -> float:
	return deg_to_rad(T.v("pendulum_angle")) * sin(TAU * (_swing_t - back) / maxf(0.5, T.v("pendulum_period")))


func _emit() -> void:
	# dust, sparks and glints that belong to the warning
	match kind:
		"crusher":
			if state == "warn":
				var side := randf_range(-_bw * 0.5, _bw * 0.5)
				_speck(Vector2(_cx + side, _by + BH), Vector2(randf_range(-6.0, 6.0), randf_range(10.0, 40.0)), 0.7, Color(0.62, 0.58, 0.55))
		"flame":
			if state == "warn":
				_speck(Vector2(_cx + randf_range(-6.0, 6.0), _floor_y - 3.0), Vector2(randf_range(-20.0, 20.0), randf_range(-90.0, -40.0)), 0.5, Color(1.0, 0.7, 0.3))
			elif state == "active":
				_speck(Vector2(_cx + randf_range(-6.0, 6.0), _floor_y - randf_range(10.0, _flame_h())), Vector2(randf_range(-14.0, 14.0), randf_range(-70.0, -30.0)), 0.5, Color(1.0, 0.75, 0.3))
		"spikes":
			if state == "warn":
				var n := maxi(1, int(rect.size.x / 8.0))
				var i := randi() % n
				_speck(Vector2(rect.position.x + 4.0 + i * 8.0, _floor_y - 2.0), Vector2(randf_range(-6.0, 6.0), randf_range(-40.0, -15.0)), 0.4, Color(0.8, 0.7, 0.55))


func _speck(at: Vector2, v: Vector2, life: float, col: Color) -> void:
	if _specks.size() > 60:
		return
	_specks.append({"p": at, "v": v, "life": life, "max": life, "col": col})


# ---------- where it hurts ----------

func dangerous() -> bool:
	match kind:
		"pendulum":
			return true
		"crusher":
			return state == "fall" or state == "sit"
		"flame":
			return state == "active"
		"spikes":
			return state == "up" and _ext() > 0.3
	return false


func hits(body: Rect2) -> bool:
	match kind:
		"pendulum":
			for c in _blade_circles():
				if Util.circle_hits(c[0], c[1], body):
					return true
			return false
		"crusher":
			return dangerous() and _block_rect().intersects(body)
		"flame":
			return dangerous() and _flame_rect().intersects(body)
		"spikes":
			return dangerous() and _spike_rect().intersects(body)
	return false


func _hit_x() -> float:
	if kind == "pendulum":
		return _tip(_ang()).x
	return _cx


func _tip(a: float) -> Vector2:
	return Vector2(_cx, _ceil_y) + Vector2(sin(a), cos(a)) * _len


func _blade_circles() -> Array:
	var a := _ang()
	var tip := _tip(a)
	var tangent := Vector2(cos(a), -sin(a))
	var out: Array = []
	for k in [-1.0, 0.0, 1.0]:
		out.append([tip + tangent * k * 10.0 + Vector2(sin(a), cos(a)) * (3.0 - absf(k) * 2.0), 9.0])
	return out


func _block_rect() -> Rect2:
	return Rect2(_cx - _bw * 0.5, _by, _bw, BH)


func _flame_h() -> float:
	var h := T.v("flame_height")
	var d := _dur("active")
	var k := clampf(_s / 0.12, 0.0, 1.0)
	if state == "active" and _s > d - 0.2:
		k = clampf((d - _s) / 0.2, 0.0, 1.0)
	return h * k


func _flame_rect() -> Rect2:
	var h := _flame_h()
	return Rect2(_cx - 6.0, _floor_y - h, 12.0, h)


func _ext() -> float:
	# how far the spikes are out, 0..1: fast out, a short slide back
	if state != "up":
		return 0.0
	var d := _dur("up")
	if _s > d - 0.2:
		return clampf((d - _s) / 0.2, 0.0, 1.0)
	return 1.0 - pow(1.0 - clampf(_s / 0.08, 0.0, 1.0), 3.0)


func _spike_rect() -> Rect2:
	var h := 14.0 * _ext()
	return Rect2(rect.position.x, _floor_y - 2.0 - h, rect.size.x, h)


# ---------- sound and shake ----------

func _snd(name: String, db: float = -6.0, pitch: float = 1.0) -> void:
	Util.snd(name, Vector2(_cx, _floor_y - 20.0), db, pitch)


func _shake(amp: float, t: float) -> void:
	if G.peace or G.main == null or G.main.player == null:
		return
	if absf(G.main.player.global_position.x - _cx) < 240.0:
		G.main.shake(amp, t)


# ---------- drawing ----------

func _draw() -> void:
	match kind:
		"pendulum":
			_draw_pendulum()
		"crusher":
			_draw_crusher()
		"flame":
			_draw_flame()
		"spikes":
			_draw_spikes()
	for sp in _specks:
		var c: Color = sp["col"]
		c.a = clampf(sp["life"] / sp["max"], 0.0, 1.0)
		draw_rect(Rect2(sp["p"].round(), Vector2(1, 1)), c)


func _crescent(depth_out: float, depth_in: float, r: float, y0: float) -> PackedVector2Array:
	# a half-moon: tips at (+-r, y0), belly curving down, the back edge curving less
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI * i / 12.0
		pts.append(Vector2(cos(a) * r, y0 + sin(a) * depth_out))
	for i in 13:
		var a := PI - PI * i / 12.0
		pts.append(Vector2(cos(a) * r * 0.96, y0 + sin(a) * depth_in))
	return pts


func _draw_pendulum() -> void:
	var a := _ang()
	var piv := Vector2(_cx, _ceil_y)
	# the bracket on the ceiling
	draw_rect(Rect2(_cx - 9.0, _ceil_y, 18.0, 3.0), IRON)
	draw_rect(Rect2(_cx - 9.0, _ceil_y + 2.5, 18.0, 0.5), IRON_L)
	for sx in [-6.5, 6.5]:
		draw_circle(Vector2(_cx + sx, _ceil_y + 1.5), 0.9, BRASS)
	draw_set_transform(piv, -a, Vector2.ONE)
	draw_circle(Vector2(0.0, 3.5), 3.2, BRASS_D)
	draw_arc(Vector2(0.0, 3.5), 3.2, 0.0, TAU, 10, BRASS, 0.5)
	# the arm: iron chain
	var n := int(_len / 5.0)
	for i in n:
		var y := 6.0 + i * 5.0
		if i % 2 == 0:
			draw_rect(Rect2(-1.3, y, 2.6, 5.5), IRON_D)
			draw_line(Vector2(-1.3, y), Vector2(-1.3, y + 5.5), IRON_L, 0.5)
		else:
			draw_rect(Rect2(-2.2, y + 0.5, 4.4, 4.0), IRON)
			draw_rect(Rect2(-0.8, y + 1.5, 1.6, 2.0), IRON_D)
	# the blade
	var by := _len
	draw_rect(Rect2(-3.5, by - 14.0, 7.0, 10.0), IRON)
	draw_rect(Rect2(-3.5, by - 14.0, 7.0, 1.0), BRASS)
	var cres := _crescent(16.0, 4.0, 19.0, by - 4.0)
	draw_colored_polygon(cres, IRON_D)
	var bevel := _crescent(14.0, 5.0, 17.0, by - 4.0)
	draw_colored_polygon(bevel, IRON)
	var edge := PackedVector2Array()
	for i in 13:
		var an := PI * i / 12.0
		edge.append(Vector2(cos(an) * 19.0, by - 4.0 + sin(an) * 16.0))
	draw_polyline(edge, STEEL, 1.0)
	draw_polyline(edge, Color(1.0, 1.0, 1.0), 0.5)
	for sx in [-9.0, 0.0, 9.0]:
		draw_circle(Vector2(sx, by - 2.0), 0.9, BRASS)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_crusher() -> void:
	var jx := sin(_clock * 90.0) * _rattle
	var bx := _cx - _bw * 0.5 + jx
	var by := _by
	# the footprint on the floor, and the warning marks on it
	draw_rect(Rect2(_cx - _bw * 0.5, _floor_y - 1.0, _bw, 1.0), Color(0.0, 0.0, 0.0, 0.35))
	if state == "warn":
		var blink := int(_s * 14.0) % 2 == 0
		for i in int(_bw / 4.0):
			if (i % 2 == 0) == blink:
				draw_rect(Rect2(_cx - _bw * 0.5 + i * 4.0, _floor_y - 1.5, 3.0, 1.5), HOT)
	# the piston
	draw_rect(Rect2(_cx - 4.0 + jx, _ceil_y, 8.0, maxf(0.0, by - _ceil_y)), IRON)
	draw_rect(Rect2(_cx - 4.0 + jx, _ceil_y, 1.0, maxf(0.0, by - _ceil_y)), IRON_L)
	draw_rect(Rect2(_cx + 3.0 + jx, _ceil_y, 1.0, maxf(0.0, by - _ceil_y)), IRON_D)
	draw_rect(Rect2(_cx - 10.0, _ceil_y, 20.0, 3.0), IRON)
	draw_rect(Rect2(_cx - 10.0, _ceil_y + 2.5, 20.0, 0.5), BRASS_D)
	for sx in [-7.0, 7.0]:
		draw_circle(Vector2(_cx + sx, _ceil_y + 1.5), 0.9, BRASS)
	# the block
	var blk := Rect2(bx, by, _bw, BH)
	draw_rect(blk, IRON)
	draw_rect(Rect2(bx, by, _bw, 1.5), IRON_L)
	draw_rect(Rect2(bx, by, 1.0, BH), IRON_L)
	draw_rect(Rect2(bx + _bw - 1.0, by, 1.0, BH), IRON_D)
	draw_rect(Rect2(bx + 2.0, by + 3.0, _bw - 4.0, BH - 11.0), IRON_D)
	draw_rect(Rect2(bx + 2.5, by + 3.5, _bw - 5.0, 0.5), Color(0.35, 0.33, 0.4))
	# hazard stripes along the bottom
	var sy := by + BH - 5.0
	for i in int(_bw / 4.0):
		var x := bx + i * 4.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, sy + 4.0), Vector2(x + 2.0, sy), Vector2(x + 4.0, sy), Vector2(x + 2.0, sy + 4.0)]), BONE if i % 2 == 0 else IRON_D)
	# teeth under the block
	for i in int(_bw / 4.0):
		var x := bx + i * 4.0
		draw_colored_polygon(PackedVector2Array([Vector2(x + 0.5, by + BH), Vector2(x + 2.0, by + BH + 2.5), Vector2(x + 3.5, by + BH)]), STEEL if state == "fall" else IRON_L)
	for sx in [2.0, _bw - 2.0]:
		draw_circle(Vector2(bx + sx, by + 2.5), 0.9, BRASS)
	if state == "warn":
		draw_rect(Rect2(bx, by + BH - 1.0, _bw, 1.0), Color(HOT.r, HOT.g, HOT.b, 0.5 + 0.5 * sin(_s * 40.0)))


func _draw_flame() -> void:
	var f := _floor_y
	draw_rect(Rect2(_cx - 8.0, f - 2.5, 16.0, 2.5), IRON_D)
	draw_rect(Rect2(_cx - 8.0, f - 2.5, 16.0, 0.5), IRON_L)
	draw_rect(Rect2(_cx - 8.0, f - 2.5, 1.0, 2.5), BRASS_D)
	draw_rect(Rect2(_cx + 7.0, f - 2.5, 1.0, 2.5), BRASS_D)
	var glow := 0.0
	if state == "warn":
		glow = clampf(_s / maxf(0.05, _dur("warn")), 0.0, 1.0)
	elif state == "active":
		glow = 1.0
	for i in 5:
		var x := _cx - 5.0 + i * 2.5
		var c := Color(0.02, 0.02, 0.03)
		if glow > 0.0:
			c = Color(HOT.r, HOT.g * (0.5 + 0.5 * glow), 0.1, 0.4 + 0.6 * glow)
		draw_rect(Rect2(x - 0.5, f - 2.0, 1.0, 1.5), c)
	if state == "active":
		var h := _flame_h()
		if h > 1.0:
			draw_colored_polygon(_flame_poly(h, 17.0, 0.0), Color(0.85, 0.22, 0.06, 0.85))
			draw_colored_polygon(_flame_poly(h * 0.82, 12.0, 1.7), Color(1.0, 0.5, 0.1, 0.9))
			draw_colored_polygon(_flame_poly(h * 0.58, 8.0, 3.1), Color(1.0, 0.85, 0.35, 0.95))
			draw_colored_polygon(_flame_poly(h * 0.3, 3.5, 4.6), Color(1.0, 1.0, 0.85))


func _flame_poly(h: float, w: float, seed: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 8
	for i in n + 1:
		var fr := float(i) / n
		var sway := sin(_clock * 14.0 + fr * 5.0 + seed) * 2.5 * fr
		pts.append(Vector2(_cx - w * 0.5 * pow(1.0 - fr, 0.75) + sway, _floor_y - 2.0 - h * fr))
	for i in range(n - 1, -1, -1):
		var fr := float(i) / n
		var sway := sin(_clock * 14.0 + fr * 5.0 + seed) * 2.5 * fr
		pts.append(Vector2(_cx + w * 0.5 * pow(1.0 - fr, 0.75) + sway, _floor_y - 2.0 - h * fr))
	return pts


func _draw_spikes() -> void:
	var f := _floor_y
	var x0 := rect.position.x
	var w := rect.size.x
	draw_rect(Rect2(x0, f - 2.0, w, 2.0), IRON)
	draw_rect(Rect2(x0, f - 2.0, w, 0.5), IRON_L)
	var n := maxi(1, int(w / 8.0))
	var e := _ext()
	var warn := state == "warn"
	for i in n:
		var x := x0 + 4.0 + i * 8.0
		var c := Color(0.02, 0.02, 0.03)
		if warn:
			c = Color(HOT.r, HOT.g, 0.1, 0.35 + 0.35 * sin(_s * 30.0 + i))
		draw_rect(Rect2(x - 2.0, f - 1.7, 4.0, 1.4), c)
		if e > 0.02:
			var h := 14.0 * e * (1.0 if i % 2 == 0 else 0.85)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 2.5, f - 2.0), Vector2(x, f - 2.0 - h), Vector2(x + 2.5, f - 2.0)]), BONE)
			draw_colored_polygon(PackedVector2Array([Vector2(x, f - 2.0), Vector2(x, f - 2.0 - h), Vector2(x + 2.5, f - 2.0)]), Color(0.62, 0.56, 0.46))
			draw_line(Vector2(x - 0.6, f - 3.0), Vector2(x - 0.1, f - 2.0 - h + 1.5), Color(1.0, 1.0, 0.92), 0.5)
			draw_circle(Vector2(x, f - 2.0 - h + 1.5), 0.7, BLOOD)
	draw_rect(Rect2(x0, f - 0.5, w, 0.5), IRON_D)


func paint_fx(c: CanvasItem) -> void:
	# light: drawn with add blending on top of everything
	match kind:
		"pendulum":
			# the smear behind the blade, so its speed shows
			var piv := Vector2(_cx, _ceil_y)
			for k in range(1, 6):
				var a := _ang_at(k * 0.025)
				var pts := PackedVector2Array()
				for i in 13:
					var an := PI * i / 12.0
					var v := Vector2(cos(an) * 19.0, _len - 4.0 + sin(an) * 16.0).rotated(-a)
					pts.append(piv + v)
				c.draw_polyline(pts, Color(0.5, 0.65, 1.0, 0.16 * (6 - k) / 5.0), 1.0)
		"crusher":
			if state == "warn":
				var k := clampf(_s / maxf(0.05, _dur("warn")), 0.0, 1.0)
				c.draw_rect(Rect2(_cx - _bw * 0.5, _by + BH, _bw, 4.0 + 6.0 * k), Color(HOT.r, HOT.g, HOT.b, 0.12 + 0.2 * k))
			elif state == "sit" and _s < 0.2:
				c.draw_rect(Rect2(_cx - _bw * 0.5 - 4.0, _floor_y - 2.0, _bw + 8.0, 2.0), Color(1.0, 0.9, 0.7, 0.6 * (1.0 - _s / 0.2)))
		"flame":
			if state == "warn":
				var k := clampf(_s / maxf(0.05, _dur("warn")), 0.0, 1.0)
				Util.glow(c, Vector2(_cx, _floor_y - 3.0), 8.0 + 4.0 * k, Color(HOT.r, HOT.g, HOT.b, 0.2 + 0.4 * k))
				for i in 3:
					var x := _cx + sin(_clock * 12.0 + i * 2.0) * 4.0
					c.draw_line(Vector2(x, _floor_y - 5.0), Vector2(x, _floor_y - 11.0 - 6.0 * k), Color(1.0, 0.8, 0.5, 0.2 + 0.3 * k), 0.5)
			elif state == "active":
				var h := _flame_h()
				Util.glow(c, Vector2(_cx, _floor_y - 6.0), 20.0, Color(1.0, 0.45, 0.1, 0.3))
				Util.glow(c, Vector2(_cx, _floor_y - h * 0.5), 13.0, Color(1.0, 0.5, 0.15, 0.25))
				c.draw_rect(Rect2(_cx - 14.0, _floor_y - 2.0, 28.0, 1.5), Color(1.0, 0.6, 0.2, 0.3))
		"spikes":
			if state == "warn":
				var n := maxi(1, int(rect.size.x / 8.0))
				for i in n:
					var x := rect.position.x + 4.0 + i * 8.0
					if int(_s * 22.0 + i * 3.0) % 4 == 0:
						c.draw_line(Vector2(x - 2.5, _floor_y - 2.0), Vector2(x + 2.5, _floor_y - 2.0), Color(1.0, 0.95, 0.7, 0.9), 0.5)
						c.draw_line(Vector2(x, _floor_y - 5.0), Vector2(x, _floor_y + 1.0), Color(1.0, 0.95, 0.7, 0.9), 0.5)
						Util.glow(c, Vector2(x, _floor_y - 2.0), 3.5, Color(1.0, 0.6, 0.2, 0.4))


# A glow layer on top: it asks the hazard what to draw.
class Fx extends Node2D:
	var owner_h: Node2D

	func _init() -> void:
		z_index = 2
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

	func _draw() -> void:
		if owner_h != null and is_instance_valid(owner_h):
			owner_h.paint_fx(self)


class Util:
	static func can_hit() -> bool:
		var m = G.main
		if G.peace or G.frozen() or m == null:
			return false
		if m.player == null or m.player.state == "dead":
			return false
		return not bool(m.get("_busy")) and not bool(m.get("hold"))

	static func glow(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
		for i in 4:
			c.draw_circle(at, r * (1.0 - i * 0.22), Color(col.r, col.g, col.b, col.a * 0.3))

	static func circle_hits(center: Vector2, r: float, rect: Rect2) -> bool:
		var cp := Vector2(clampf(center.x, rect.position.x, rect.end.x), clampf(center.y, rect.position.y, rect.end.y))
		return center.distance_to(cp) < r

	static func snd(name: String, at: Vector2, db: float = -6.0, pitch: float = 1.0) -> void:
		var d := 0.0
		if G.main != null and G.main.player != null:
			d = at.distance_to(G.main.player.global_position)
		if d > 460.0:
			return
		Sfx.play_file("sfx/world/%s.wav" % name, db - clampf((d - 150.0) / 12.0, 0.0, 28.0), pitch * randf_range(0.96, 1.04))
