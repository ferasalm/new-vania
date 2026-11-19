# PROTOTYPE - NOT FOR PRODUCTION
# Four enemies for the hazard rooms. Every attack is telegraphed: an orange blink, a sound
# and a cue you can see. Same interface as enemy.gd (kind, hurt_rect, can_hurt, damage,
# touched_player, take_hit), so main treats them like any other enemy.
#   crab   (Spine Crab, ground, tanky): its shell blocks cuts from the front. Claw rush, spine fan,
#          or it digs in and bursts out of the floor under her. Hit it from behind or above.
#   moth   (Censer Moth, flying): incense smoke clouds, a wing gust that throws her, an ember dive.
#   scribe (Needle Scribe, floating): pinning needle, ink step (drops from the ceiling above her),
#          a glyph on the floor that bursts. Below half health it leaves a harmless ink clone.
#   leech  (Thread Leech, ceiling): drops when she is under it, latches on and drains her.
# Art: assets/2x/<kind>/meta.json + <anim>_NN.png (double detail). If anything is missing the
# enemy draws simple placeholder shapes, so the game always runs.
extends CharacterBody2D

const KINDS := {
	"crab": {"box": Vector2(44, 22), "fly": false},
	"moth": {"box": Vector2(34, 24), "fly": true},
	"scribe": {"box": Vector2(20, 50), "fly": true},
	"leech": {"box": Vector2(13, 30), "fly": true},
}
const FPS := {"idle": 6.0, "walk": 12.0, "rear": 8.0, "burrow": 10.0, "emerge": 10.0, "fly": 14.0,
	"gust": 8.0, "swing": 12.0, "dive": 10.0, "write": 8.0, "throw": 12.0, "melt": 8.0,
	"hang": 7.0, "drop": 12.0, "latch": 8.0}
const LOOPS := ["idle", "walk", "fly", "hang"]
const GONE := Rect2(Vector2(-9999.0, -9999.0), Vector2.ZERO)

static var _hinted := false

var kind := "crab"
var respawned := false    # it came back from the weak-respawn system
var hp := 1.0
var facing := -1
var state := "idle"
var blocks := 0               # how many cuts the crab's shell has turned away
var _t := 0.0
var _stun := 0.0
var _flash := 0.0
var _cool := 1.0
var _count := 0
var _dead := false
var _fake := false            # an ink clone: copies everything, hurts nothing, pops when hit
var _bob := 0.0
var _d := {}
var _box := Vector2.ZERO
var _spr: AnimatedSprite2D
var _fx: Node2D
var _art := false
var _have := {}
var _canvas := Vector2(112, 72)
var _anchor := Vector2(56, 72)
var _anim := ""
var _aim := Vector2.ZERO
var _p0 := Vector2.ZERO
var _p3 := Vector2.ZERO
var _pc := Vector2.ZERO
var _floor_y := 0.0
var _behind_t := 0.0
var _tick := 0.0
var _trail: Array = []
var _squash := 1.0
var _start_y := 0.0
var _drip := Vector2.ZERO
var _land_y := 0.0
var _clones: Array = []
var _clone_t := 0.0
var _ceil := Vector2.ZERO     # leech: where its thread hangs from
var _len := 24.0
var _sway := 0.0
var _jumps := 0
var _attacks := 0
var _rising := false
var _prev_at := 0.0
var _pstate := ""


func setup(k: String) -> void:
	kind = k
	_d = KINDS[k]
	_box = _d["box"]
	hp = T.v(k + "_hp")
	collision_layer = 8
	collision_mask = 0
	_bob = randf() * TAU
	_cool = 0.9 + randf() * 0.8
	_load_art()
	if _spr != null:
		add_child(_spr)
	_fx = Overlay.new()
	_fx.owner_e = self
	add_child(_fx)
	match k:
		"crab":
			facing = -1
			collision_mask = 1 | 2
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = _box
			shape.shape = rect
			shape.position = Vector2(0, -_box.y / 2.0)
			add_child(shape)
			state = "scuttle"
		"moth":
			position.y -= 30.0
			state = "idle"
		"scribe":
			position.y -= 38.0
			state = "idle"
		"leech":
			_find_ceiling()
			state = "hang"
	_play("idle" if k == "crab" or k == "scribe" else ("fly" if k == "moth" else "hang"))


func _ready() -> void:
	add_to_group("enemy2")


# ---------- art ----------

func _load_art() -> void:
	# checked every time an enemy is made: art that arrives later is picked up at once
	_art = false
	_have.clear()
	var path := "res://assets/2x/%s/meta.json" % kind
	if not FileAccess.file_exists(path):
		return
	var meta = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(meta) != TYPE_DICTIONARY or not meta.has("anims"):
		return
	var cv = meta.get("canvas", [112, 72])
	var an = meta.get("anchor", [56, 72])
	_canvas = Vector2(float(cv[0]), float(cv[1]))
	_anchor = Vector2(float(an[0]), float(an[1]))
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var anims: Dictionary = meta["anims"]
	for a in anims:
		var n := int(anims[a])
		var texs: Array = []
		for i in n:
			var rel := "%s/%s_%02d.png" % [kind, a, i]
			if not (ResourceLoader.exists("res://assets/2x/" + rel) or FileAccess.file_exists("res://assets/2x/" + rel)):
				break
			var t: Texture2D = G.tex(rel)
			if t == null:
				break
			texs.append(t)
		if n <= 0 or texs.size() != n:
			continue
		sf.add_animation(a)
		sf.set_animation_speed(a, float(FPS.get(a, 10.0)))
		sf.set_animation_loop(a, LOOPS.has(a))
		for t in texs:
			sf.add_frame(a, t)
		_have[a] = n
	if _have.is_empty():
		return
	_spr = AnimatedSprite2D.new()
	_spr.sprite_frames = sf
	_spr.centered = false
	_art = true


func _play(anim: String, dur: float = 0.0) -> void:
	_anim = anim
	if not _art:
		return
	var a := anim
	if not _have.has(a):
		a = ""
		for alt in ["idle", "fly", "hang", "walk"]:
			if _have.has(alt):
				a = alt
				break
		if a == "":
			return
	var sf := _spr.sprite_frames
	if dur > 0.0 and not LOOPS.has(a):
		sf.set_animation_speed(a, maxf(1.0, float(_have[a]) / dur))
	else:
		sf.set_animation_speed(a, float(FPS.get(a, 10.0)))
	if _spr.animation != a or not _spr.is_playing():
		_spr.play(a)
		_spr.frame = 0


func _place() -> void:
	# the anchor (half of the picture's anchor, in world units) sits on the node origin
	var a := _anchor / 2.0
	var c := _canvas / 2.0
	var sx := 1.0 + (1.0 - _squash) * 0.5
	_spr.scale = Vector2(sx, _squash)
	_spr.position = Vector2(-(c.x - a.x) * sx if facing < 0 else -a.x * sx, -a.y * _squash)


# ---------- the world, as grid cells ----------

func _find_ceiling() -> void:
	var cx := int(floor(position.x / 16.0))
	var row := int(floor((position.y - 1.0) / 16.0))
	var room: Node2D = G.main.room
	while row >= 0 and room.cell(cx, row) != "#":
		row -= 1
	_ceil = Vector2(position.x, float(row + 1) * 16.0)
	_len = T.v("leech_hang")
	position = _ceil + Vector2(0, _len)


func _blocked(pos: Vector2) -> bool:
	var room: Node2D = G.main.room
	if pos.x < 8.0 or pos.x > room.size.x - 8.0 or pos.y < 8.0 or pos.y > room.size.y - 8.0:
		return true
	var h := _box * 0.4
	for c in [Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(-h.x, h.y), Vector2(h.x, h.y)]:
		if Util.cell(pos.x + c.x, pos.y + c.y) == "#":
			return true
	return false


func _move_free(step: Vector2) -> void:
	var np := global_position + Vector2(step.x, 0.0)
	if not _blocked(np):
		global_position = np
	else:
		velocity.x = 0.0
	np = global_position + Vector2(0.0, step.y)
	if not _blocked(np):
		global_position = np
	else:
		velocity.y = 0.0


func _fly(target: Vector2, speed: float, delta: float) -> void:
	var want := target - global_position
	var vel := want.normalized() * minf(speed, want.length() * 5.0)
	velocity = velocity.move_toward(vel, 520.0 * delta)
	_move_free(velocity * delta)


func _brake(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 420.0 * delta)
	_move_free(velocity * delta)


func _edge(dir: float) -> bool:
	if dir == 0.0:
		return false
	var ch := Util.cell(global_position.x + dir * 24.0, global_position.y + 3.0)
	return ch != "#" and ch != "="


func _face(to: Vector2) -> void:
	if absf(to.x) > 4.0:
		facing = 1 if to.x > 0.0 else -1


func _side() -> int:
	var s := -1 if (_count % 4) < 2 else 1
	return -s if _fake else s


func _snd(name: String, db: float = -6.0, pitch: float = 1.0) -> void:
	Util.snd(name, global_position, db, pitch)


# ---------- the interface main uses ----------

func hurt_rect() -> Rect2:
	match kind:
		"crab":
			if state == "under" or state == "rumble":
				return GONE
			if state == "erupt":
				return Rect2(global_position + Vector2(-24, -40), Vector2(48, 40))
			var h := 34.0 if (state == "warn_rear" or state == "fan") else 22.0
			return Rect2(global_position + Vector2(-22, -h), Vector2(44, h))
		"scribe":
			if state == "puddle":
				return GONE
			return Rect2(global_position - _box / 2.0, _box)
		"leech":
			return Rect2(global_position + Vector2(-6.5, 0.0), Vector2(13.0, 30.0))
	return Rect2(global_position - _box / 2.0, _box)


func can_hurt() -> bool:
	if G.peace or _dead or _fake or _stun > 0.0:
		return false
	match kind:
		"crab":
			return state == "pinch" or state == "erupt" or state == "scuttle"
		"moth":
			return state == "dive"
		"scribe":
			return state == "fall"
		"leech":
			return state == "drop"
	return false


func damage() -> float:
	if _fake:
		return 0.0
	if kind == "crab" and state == "scuttle":
		return T.v("crab_touch_damage")
	return T.v(kind + "_damage")


func touched_player() -> void:
	if kind == "crab" and state == "pinch":
		_go("rest")
	elif kind == "leech" and state == "drop":
		_latch()


func take_hit(amount: float, dir: int) -> void:
	if _dead:
		return
	if kind == "crab":
		if state == "under" or state == "rumble":
			return
		if _shell_blocks(dir):
			_tink(dir)
			return
	elif kind == "scribe" and state == "puddle":
		return
	if _fake:
		_pop()
		return
	hp -= amount
	_flash = 0.1
	match kind:
		"crab":
			if state == "warn_rear" or state == "fan":
				# caught rearing: the spines are lost and it staggers
				_go("rest")
		"moth":
			if state != "dive":
				_stun = T.v("enemy_stun")
				velocity = Vector2(dir * 80.0, -20.0)
				_cool = maxf(_cool, 0.9)
				if state != "idle":
					state = "hover"
					_t = 0.0
					_play("fly")
		"scribe":
			if state == "hover" or state == "warn_needle" or state == "warn_glyph" or state == "idle":
				_stun = T.v("enemy_stun")
				velocity = Vector2(dir * 80.0, -20.0)
				_cool = maxf(_cool, 0.8)
				if state != "idle":
					state = "hover"
					_t = 0.0
					_play("idle")
		"leech":
			_sway = clampf(_sway + dir * 8.0, -14.0, 14.0)
			if state == "hang" or state == "warn_drop":
				_cool = maxf(_cool, 0.8)
				if state == "warn_drop":
					_go("hang")
	if hp <= 0.0:
		_die()


func _die() -> void:
	_dead = true
	for c in _clones:
		if is_instance_valid(c):
			c._pop()
	G.main.enemy_died(self)
	queue_free()


func _pop() -> void:
	# an ink clone bursts: no kill, no orb, no damage to her
	if _dead:
		return
	_dead = true
	Vfx.burst(global_position, 16, Color(0.3, 0.12, 0.5), -PI / 2.0, PI, Vector2(30.0, 100.0), 0.5, 220.0, 1.5)
	G.main.ring_fx(global_position, 22.0, Color(0.45, 0.2, 0.8))
	_snd("glyph_burst", -10.0, 1.4)
	G.main.enemies.erase(self)
	queue_free()


# ---------- crab shell ----------

func _shell_blocks(dir: int) -> bool:
	# the shell guards the front while the crab is on guard. Open: rearing, sinking, bursting out, emerging.
	if not (state == "scuttle" or state == "warn_pinch" or state == "pinch" or state == "rest"):
		return false
	if dir != -facing:
		return false      # from behind
	var p: Node2D = G.main.player
	if p.global_position.y < global_position.y - 24.0:
		return false      # from above, over the shell
	return true


func _tink(dir: int) -> void:
	blocks += 1
	_flash = 0.06
	_snd("crab_tink", -3.0, randf_range(0.9, 1.2))
	var at := global_position + Vector2(-dir * 20.0, -12.0)
	G.main.fx("spark", at)
	Vfx.burst(at, 6, Color(1.0, 0.85, 0.5), PI / 2.0 + dir * 0.8, 1.0, Vector2(40.0, 110.0), 0.25, 200.0, 1.0, 4.0)
	var p: Node2D = G.main.player
	if p.global_position.distance_to(global_position) < 80.0:
		p.move_and_collide(Vector2(-dir * T.v("crab_tink_push"), 0.0))


# ---------- the loop ----------

func _physics_process(delta: float) -> void:
	if G.frozen() or _dead or G.main == null or G.main.player == null:
		return
	_flash = maxf(0.0, _flash - delta)
	_cool = maxf(0.0, _cool - delta)
	var p: Node2D = G.main.player
	var to := p.global_position - global_position
	if _stun > 0.0:
		_stun -= delta
		_move_free(velocity * delta)
		velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
		_paint()
		return
	_t += delta
	_bob += delta * 3.0
	match kind:
		"crab":
			_crab(delta, to)
		"moth":
			_moth(delta, to)
		"scribe":
			_scribe(delta, to)
		"leech":
			_leech(delta, to)
	_paint()


func _pick() -> String:
	var seq: Array = []
	match kind:
		"crab":
			seq = ["pinch", "rear", "burrow"]
		"moth":
			seq = ["veil", "gust", "dive"]
		"scribe":
			seq = ["needle", "step", "glyph"]
		"leech":
			seq = ["drop"]
	var a: String = seq[_count % seq.size()]
	_count += 1
	return a


func start_attack(a: String) -> void:
	# one entry for the AI and for tests: begin the named attack now
	match kind:
		"crab":
			match a:
				"pinch":
					_go("warn_pinch")
				"rear":
					_go("warn_rear")
				"burrow":
					_go("warn_burrow")
		"moth":
			match a:
				"veil":
					_go("warn_veil")
				"gust":
					_go("warn_gust")
				"dive":
					_go("warn_dive")
		"scribe":
			match a:
				"needle":
					_go("warn_needle")
				"step":
					_go("melt")
				"glyph":
					_go("warn_glyph")
		"leech":
			if a == "drop":
				_go("warn_drop")


func _go(next: String) -> void:
	state = next
	_t = 0.0
	_tick = 0.0
	match kind:
		"crab":
			_enter_crab(next)
		"moth":
			_enter_moth(next)
		"scribe":
			_enter_scribe(next)
		"leech":
			_enter_leech(next)


# ---------- Spine Crab ----------

func _enter_crab(s: String) -> void:
	match s:
		"warn_pinch":
			_play("idle")
			_snd("crab_click", -3.0)
		"pinch":
			_play("walk")
		"warn_rear":
			_play("rear", T.v("crab_rear_warning"))
			_snd("crab_spines", -4.0)
		"fan":
			_fire_fan()
			_snd("crab_spines", -2.0, 1.3)
		"rest":
			_play("idle")
		"warn_burrow":
			_play("burrow", T.v("crab_burrow_time"))
			_snd("crab_burrow", -3.0)
			G.main.dust(global_position, 4)
		"under":
			_floor_y = global_position.y
			collision_mask = 0
			velocity = Vector2.ZERO
			_trail.clear()
		"rumble":
			velocity = Vector2.ZERO
			_snd("crab_burrow", -2.0, 0.75)
		"erupt":
			collision_mask = 1 | 2
			_play("emerge", 0.3)
			G.main.dust(global_position, 8)
			G.main.shake(2.5, 0.2)
			G.main.ring_fx(global_position + Vector2(0, -4), 30.0, Color(0.7, 0.55, 0.4))
			_snd("crab_burrow", -1.0, 1.5)
			var p: Node2D = G.main.player
			if Util.can_hit() and p.invuln <= 0.0 and hurt_rect().intersects(p.body_rect()):
				p.take_hit(T.v("crab_damage"), global_position.x)
		"scuttle":
			_play("idle")


func _crab(delta: float, to: Vector2) -> void:
	match state:
		"under":
			velocity = Vector2.ZERO
			_tunnel(delta, to)
			return
		"rumble":
			_tick += delta
			if _tick >= 0.12:
				_tick = 0.0
				G.main.dust(global_position, 2)
				if absf(to.x) < 200.0 and Util.can_hit():
					G.main.shake(1.2, 0.12)
			if _t >= T.v("crab_rumble"):
				_go("erupt")
			return
		"scuttle":
			var side := facing
			if absf(to.x) > 3.0:
				side = 1 if to.x > 0.0 else -1
			if side == facing:
				_behind_t = 0.0
			else:
				# she got behind it: it needs a moment to turn, and its back is open
				_behind_t += delta
				if _behind_t >= T.v("crab_turn_time"):
					facing = side
					_behind_t = 0.0
					G.main.dust(global_position, 2)
			var vx := 0.0
			var near: bool = Util.can_hit() and absf(to.x) < T.v("crab_notice") and absf(to.y) < 64.0
			if near:
				if absf(to.x) > 72.0:
					vx = side * T.v("crab_speed")
				elif absf(to.x) < 44.0:
					vx = -side * T.v("crab_speed") * 0.7
			if _edge(signf(vx)):
				vx = 0.0
			velocity.x = vx
			_play("walk" if absf(vx) > 5.0 else "idle")
			if near and _cool <= 0.0 and is_on_floor() and side == facing:
				start_attack(_pick())
		"warn_pinch":
			velocity.x = 0.0
			if _t >= T.v("crab_pinch_warning"):
				_go("pinch")
		"pinch":
			velocity.x = facing * T.v("crab_rush_speed")
			if _t >= T.v("crab_rush_time") or is_on_wall() or _edge(facing):
				_go("rest")
		"warn_rear":
			velocity.x = 0.0
			if _t >= T.v("crab_rear_warning"):
				_go("fan")
		"fan":
			velocity.x = 0.0
			if _t >= 0.4:
				_go("rest")
		"warn_burrow":
			velocity.x = 0.0
			if _t >= T.v("crab_burrow_time"):
				_go("under")
		"erupt":
			velocity.x = 0.0
			if _t >= 0.3:
				_go("emerge")
		"emerge":
			velocity.x = 0.0
			if _t >= 0.7:
				_cool = T.v("crab_wait")
				_go("scuttle")
		"rest":
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if _t >= T.v("crab_rest"):
				_cool = T.v("crab_wait")
				_go("scuttle")
	velocity.y += T.v("gravity") * delta
	move_and_slide()


func _tunnel(delta: float, to: Vector2) -> void:
	var dir := 0.0
	if absf(to.x) > 3.0:
		dir = signf(to.x)
		facing = int(dir)
	if dir != 0.0 and Util.cell(global_position.x + dir * 14.0, global_position.y - 6.0) != "#":
		global_position.x += dir * T.v("crab_burrow_speed") * delta
	global_position.y = _floor_y
	_tick += delta
	if _tick >= 0.1:
		_tick = 0.0
		G.main.dust(global_position, 1)
	if _trail.is_empty() or absf(_trail.back().x - global_position.x) > 5.0:
		_trail.append(Vector2(global_position.x, 0.8))
	for i in _trail.size():
		var tr: Vector2 = _trail[i]
		_trail[i] = Vector2(tr.x, tr.y - delta)
	_trail = _trail.filter(func(v): return v.y > 0.0)
	if _t >= T.v("crab_burrow_chase"):
		_go("rumble")


func _fire_fan() -> void:
	var src := global_position + Vector2(-facing * 6.0, -24.0)
	for k in 5:
		var elev := deg_to_rad(35.0 + k * 27.5)
		var s := Shot.new()
		s.kind = "spine"
		s.vel = Vector2(cos(elev), -sin(elev)) * T.v("crab_spine_speed") * randf_range(0.93, 1.07)
		s.grav = T.v("crab_spine_gravity")
		s.dmg = T.v("crab_spine_damage")
		s.life = 3.0
		s.position = src
		s.z_index = 4
		G.main.world.add_child(s)


# ---------- Censer Moth ----------

func _enter_moth(s: String) -> void:
	match s:
		"hover", "idle":
			_play("fly")
		"warn_veil":
			_play("fly")
			_snd("censer_chime", -3.0)
		"warn_gust":
			_play("gust", T.v("moth_gust_warning"))
			_snd("moth_flutter", -6.0, 0.8)
		"gust":
			_play("gust")
		"warn_dive":
			_play("swing")
			_snd("moth_flutter", -2.0, 1.5)
		"dive":
			_play("dive")
			_p0 = global_position
			_p3 = Vector2(2.0 * _aim.x - _p0.x, _p0.y)
			_pc = 2.0 * _aim - 0.5 * (_p0 + _p3)
			_snd("moth_flutter", -1.0, 1.2)


func _moth(delta: float, to: Vector2) -> void:
	var p: Node2D = G.main.player
	match state:
		"idle":
			_move_free(Vector2(0.0, sin(_bob) * 8.0) * delta)
			if Util.can_hit() and to.length() < T.v("moth_notice"):
				_go("hover")
		"hover":
			var spot := p.global_position + Vector2(_side() * 74.0, -78.0 + sin(_bob) * 6.0)
			_fly(spot, T.v("moth_speed"), delta)
			_face(to)
			if to.length() > T.v("moth_notice") + 90.0:
				_go("idle")
			elif _cool <= 0.0 and Util.can_hit():
				start_attack(_pick())
		"warn_veil":
			_brake(delta)
			_face(to)
			if _t >= T.v("moth_veil_warning"):
				_spawn_clouds(to)
				_cool = T.v("moth_wait")
				_go("hover")
		"warn_gust":
			_brake(delta)
			_face(to)
			if _t >= T.v("moth_gust_warning"):
				_blow(to)
				_cool = T.v("moth_wait")
				_go("gust")
		"gust":
			_brake(delta)
			if _t >= 0.4:
				_go("hover")
		"warn_dive":
			var start := p.global_position + Vector2(_side() * 90.0, -88.0)
			_fly(start, T.v("moth_speed") * 2.0, delta)
			_face(to)
			if _t < T.v("moth_dive_warning") * 0.55:
				_aim = p.global_position + Vector2(0.0, -16.0)
			if _t >= T.v("moth_dive_warning"):
				_go("dive")
		"dive":
			var u := _t / T.v("moth_dive_time")
			var q := _bez(minf(u, 1.0))
			var step := q - global_position
			if absf(step.x) > 0.5:
				facing = 1 if step.x > 0.0 else -1
			_tick += delta
			if _tick >= 0.14:
				_tick = 0.0
				_drop_ember()
			if u >= 1.0 or _blocked(q):
				_cool = T.v("moth_wait")
				velocity = Vector2.ZERO
				_go("hover")
			else:
				global_position = q


func _bez(u: float) -> Vector2:
	var a := _p0.lerp(_pc, u)
	var b := _pc.lerp(_p3, u)
	return a.lerp(b, u)


func _spawn_clouds(to: Vector2) -> void:
	var src := global_position + Vector2(0.0, 18.0)
	var base := (to + Vector2(0.0, -18.0) - Vector2(0.0, 18.0)).angle()
	for k in [-1, 0, 1]:
		var a: float = base + k * 0.45
		var c := Cloud.new()
		c.vel = Vector2(cos(a), sin(a)) * T.v("moth_cloud_speed") * randf_range(0.8, 1.2)
		c.life = T.v("moth_cloud_life")
		c.max_life = c.life
		c.dmg = T.v("moth_cloud_damage")
		c.position = src + Vector2(k * 5.0, 0.0)
		c.z_index = 7
		G.main.world.add_child(c)
	_snd("censer_chime", -4.0, 0.7)
	G.main.dust(src, 6)


func _blow(to: Vector2) -> void:
	var dir := 1 if to.x >= 0.0 else -1
	var g := Gust.new()
	g.dir = dir
	g.dist = T.v("moth_gust_push")
	g.life = T.v("moth_gust_time")
	g.position = global_position + Vector2(dir * 14.0, 4.0)
	g.z_index = 6
	G.main.world.add_child(g)
	_snd("moth_gust", -1.0)
	G.main.shake(1.0, 0.2)


func _drop_ember() -> void:
	var e := Ember.new()
	e.dmg = T.v("moth_ember_damage")
	e.burn = T.v("moth_ember_burn")
	e.position = global_position + Vector2(randf_range(-4.0, 4.0), 8.0)
	e.z_index = 4
	G.main.world.add_child(e)


# ---------- Needle Scribe ----------

func _enter_scribe(s: String) -> void:
	match s:
		"hover":
			_play("idle")
			_squash = 1.0
		"warn_needle":
			_play("throw", T.v("scribe_needle_warning"))
			_snd("scribe_scratch", -6.0, 1.6)
		"melt":
			_play("melt", 0.5)
			_start_y = global_position.y
			_floor_y = Util.floor_below(global_position.x, global_position.y)
			_snd("ink_drip", -4.0, 0.8)
		"puddle":
			var p: Node2D = G.main.player
			global_position.y = _floor_y - 3.0
			_squash = 0.08
			var cy := Util.ceil_above(p.global_position.x, p.global_position.y - 40.0)
			_drip = Vector2(p.global_position.x, cy)
			_land_y = Util.floor_below(_drip.x, cy + 30.0)
			_snd("ink_drip", -2.0)
		"fall":
			_squash = 1.0
			_play("idle")
			global_position = Vector2(_drip.x, _drip.y + 26.0)
			_floor_y = Util.floor_below(_drip.x, _drip.y + 30.0)
			_snd("ink_drip", -2.0, 1.5)
		"reform":
			_play("idle")
		"warn_glyph":
			_play("write", 0.55)
			_snd("scribe_scratch", -3.0)
			_draw_glyph()


func _scribe(delta: float, to: Vector2) -> void:
	var p: Node2D = G.main.player
	if not _fake and hp < T.v("scribe_hp") * 0.5 and state == "hover":
		_clones = _clones.filter(func(c): return is_instance_valid(c))
		_clone_t -= delta
		if _clones.is_empty() and _clone_t <= 0.0 and Util.can_hit():
			_spawn_clone()
			_clone_t = T.v("scribe_clone_every")
	match state:
		"idle":
			_move_free(Vector2(0.0, sin(_bob) * 6.0) * delta)
			if Util.can_hit() and to.length() < T.v("scribe_notice"):
				_go("hover")
		"hover":
			var spot := p.global_position + Vector2(_side() * 96.0, -44.0 + sin(_bob) * 5.0)
			_fly(spot, T.v("scribe_speed"), delta)
			_face(to)
			if to.length() > T.v("scribe_notice") + 90.0:
				_go("idle")
			elif _cool <= 0.0 and Util.can_hit():
				start_attack(_pick())
		"warn_needle":
			_brake(delta)
			_face(to)
			if _t < 0.3:
				_aim = p.global_position + Vector2(0.0, -18.0)
			if _t >= T.v("scribe_needle_warning"):
				_throw_needle()
				_cool = T.v("scribe_wait")
				_go("hover")
		"melt":
			_brake(delta)
			var u := clampf(_t / 0.5, 0.0, 1.0)
			global_position.y = lerpf(_start_y, _floor_y - 3.0, u * u)
			_squash = lerpf(1.0, 0.08, u)
			if _t >= 0.5:
				_go("puddle")
		"puddle":
			var dt := T.v("scribe_drip_time")
			if _t < dt * 0.45:
				_drip.x = move_toward(_drip.x, p.global_position.x, 120.0 * delta)
			_land_y = Util.floor_below(_drip.x, _drip.y + 30.0)
			if _t >= dt:
				_go("fall")
		"fall":
			global_position.y += T.v("scribe_drop_speed") * delta
			if global_position.y + 26.0 >= _floor_y:
				global_position.y = _floor_y - 26.0
				G.main.dust(Vector2(global_position.x, _floor_y), 8)
				G.main.shake(1.5, 0.15)
				Vfx.burst(Vector2(global_position.x, _floor_y - 2.0), 12, Color(0.3, 0.12, 0.5), -PI / 2.0, 1.2, Vector2(30.0, 90.0), 0.45, 200.0, 1.5)
				_snd("glyph_burst", -9.0, 1.5)
				_go("reform")
		"reform":
			_squash = 1.0
			if _t >= 0.6:
				_cool = T.v("scribe_wait")
				_go("hover")
		"warn_glyph":
			_brake(delta)
			_face(to)
			if _t >= 0.55:
				_cool = T.v("scribe_wait")
				_go("hover")


func _throw_needle() -> void:
	var from := global_position + Vector2(facing * 14.0, -6.0)
	var s := Shot.new()
	s.kind = "needle"
	s.vel = (_aim - from).normalized() * T.v("scribe_needle_speed")
	s.dmg = 0.0 if _fake else T.v("scribe_damage")
	s.pin = 0.0 if _fake else T.v("scribe_pin_time")
	s.fake = _fake
	s.life = 2.0
	s.position = from
	s.z_index = 4
	G.main.world.add_child(s)
	_snd("scribe_needle", -2.0)


func _draw_glyph() -> void:
	var p: Node2D = G.main.player
	var g := Glyph.new()
	g.fuse = T.v("scribe_glyph_time")
	g.radius = T.v("scribe_glyph_radius")
	g.dmg = T.v("scribe_glyph_damage")
	g.harm = not _fake
	g.position = Vector2(p.global_position.x, Util.floor_below(p.global_position.x, p.global_position.y - 2.0))
	g.z_index = 2
	G.main.world.add_child(g)


func _spawn_clone() -> void:
	var c: CharacterBody2D = get_script().new()
	c.position = global_position + Vector2(-facing * 44.0, 0.0)
	c.position.y += 38.0     # setup lifts a floating enemy by its hover height
	c.setup("scribe")
	c._fake = true
	c.hp = 1.0
	c._count = _count + 2
	c._cool = maxf(_cool, 0.4)
	c.state = "hover"
	c.facing = facing
	G.main.world.add_child(c)
	G.main.enemies.append(c)
	_clones.append(c)
	Vfx.burst(c.position, 14, Color(0.3, 0.12, 0.5), -PI / 2.0, PI, Vector2(30.0, 90.0), 0.5, 100.0, 1.5)
	_snd("ink_drip", -4.0, 1.2)


# ---------- Thread Leech ----------

func _enter_leech(s: String) -> void:
	match s:
		"hang", "climb":
			_play("hang")
		"warn_drop":
			_play("hang")
			_snd("leech_squelch", -6.0, 1.3)
		"drop":
			_play("drop", 0.3)
			_snd("leech_drop", -3.0)
		"latched":
			_play("latch")
			_snd("leech_squelch", -2.0)
		"fallen":
			_play("drop")
			_snd("leech_drop", -6.0, 0.8)


func _under(p: Node2D) -> bool:
	var bx := _ceil.x + _sway
	var dy := p.global_position.y - (global_position.y + 30.0)
	if absf(p.global_position.x - bx) > T.v("leech_notice") or dy < 4.0 or dy > T.v("leech_reach"):
		return false
	# nothing solid between its belly and her head
	var y := global_position.y + 24.0
	while y < p.global_position.y - 30.0:
		if Util.cell(bx, y) == "#":
			return false
		y += 8.0
	return true


func _leech(delta: float, to: Vector2) -> void:
	var p: Node2D = G.main.player
	match state:
		"hang":
			_len = move_toward(_len, T.v("leech_hang"), 40.0 * delta)
			_sway = move_toward(_sway, 0.0, 10.0 * delta)
			global_position = _ceil + Vector2(_sway + sin(_bob * 1.3) * 2.0, _len)
			_face(to)
			if _cool <= 0.0 and Util.can_hit() and _under(p):
				start_attack("drop")
		"warn_drop":
			_sway = move_toward(_sway, clampf(p.global_position.x - _ceil.x, -10.0, 10.0), 24.0 * delta)
			global_position = _ceil + Vector2(_sway + sin(_t * 40.0) * 1.2, _len)
			if _t >= T.v("leech_drop_warning"):
				_go("drop")
		"drop":
			_len += T.v("leech_drop_speed") * delta
			global_position = _ceil + Vector2(_sway, _len)
			if Util.can_hit() and hurt_rect().intersects(p.body_rect()):
				_latch()
				return
			var below := Util.cell(global_position.x, global_position.y + 32.0)
			if below == "#" or below == "=" or _len >= T.v("leech_reach"):
				velocity = Vector2.ZERO
				_stun = 0.0
				_go("fallen")
		"latched":
			_latched(delta, p)
		"fallen":
			velocity.y = minf(velocity.y + T.v("gravity") * delta, 400.0)
			var ny := global_position.y + velocity.y * delta
			var under := Util.cell(global_position.x, ny + 30.0)
			if under == "#" or under == "=":
				velocity.y = 0.0
			else:
				global_position.y = ny
			global_position.x += velocity.x * delta
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			if _t >= T.v("leech_stun"):
				_go("climb")
		"climb":
			var spot := _ceil + Vector2(0.0, T.v("leech_hang"))
			global_position = global_position.move_toward(spot, T.v("leech_climb_speed") * delta)
			_sway = global_position.x - _ceil.x
			_len = global_position.y - _ceil.y
			if global_position.distance_to(spot) < 1.0:
				_sway = 0.0
				_len = T.v("leech_hang")
				_cool = T.v("leech_wait")
				_go("hang")


func _latch() -> void:
	if state == "latched":
		return
	_go("latched")
	var p: Node2D = G.main.player
	_jumps = 0
	_attacks = 0
	_rising = p.velocity.y < -150.0
	_prev_at = float(p.get("_attack_t"))
	_pstate = String(p.state)
	_hinted = true      # no tip on screen (user ask C8)


func _latched(delta: float, p: Node2D) -> void:
	global_position = p.global_position + Vector2(-int(p.facing) * 4.0 + sin(_t * 18.0) * 0.8, -34.0)
	if Util.can_hit():
		var mp: float = p.mp
		if mp > 0.0:
			p.mp = maxf(0.0, mp - T.v("leech_drain_mp") * delta)
		else:
			p.energy = maxf(0.0, float(p.energy) - T.v("leech_drain_en") * delta)
		var vx: float = p.velocity.x
		if absf(vx) > 1.0:
			p.move_and_collide(Vector2(-signf(vx) * absf(vx) * T.v("leech_slow") * delta, 0.0))
	# she shakes it off by jumping or swinging
	var rising: bool = p.velocity.y < -150.0
	if rising and not _rising:
		_jumps += 1
	_rising = rising
	var at: float = float(p.get("_attack_t"))
	var st := String(p.state)
	if st == "attack" and (_pstate != "attack" or at < _prev_at - 0.01):
		_attacks += 1
	_prev_at = at
	_pstate = st
	var far: bool = global_position.distance_to(_ceil) > T.v("leech_reach") + 60.0
	if _jumps >= int(T.v("leech_jumps")) or _attacks >= int(T.v("leech_attacks")) or _t >= T.v("leech_latch_time") or far or st == "dead":
		velocity = Vector2(-float(p.facing) * 50.0, -140.0)
		_flash = 0.1
		G.main.dust(global_position, 4)
		_go("fallen")


# ---------- drawing ----------

func _paint() -> void:
	var c := Color.WHITE
	if _flash > 0.0:
		c = Color(4.0, 4.0, 4.0)
	elif state.begins_with("warn") or state == "rumble":
		# the warning: a fast orange blink before every attack
		if int(_t * 16.0) % 2 == 0:
			c = Color(2.2, 1.2, 0.5)
	if _fake:
		c = c * Color(0.82, 0.82, 1.0)
	var hide := state == "under" or state == "rumble" or state == "puddle"
	if _spr != null:
		_spr.visible = not hide
		_spr.modulate = c
		_spr.flip_h = facing < 0
		_place()
		if state == "warn_rear":
			_spr.position += Vector2(randf_range(-0.5, 0.5), 0.0)
	self_modulate = c
	queue_redraw()
	if _fx != null:
		_fx.queue_redraw()


func _ell(center: Vector2, rx: float, ry: float, n: int = 14) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _draw() -> void:
	match kind:
		"crab":
			_mound()
			if not _art and state != "under" and state != "rumble":
				_draw_crab()
		"moth":
			if not _art:
				_draw_moth()
		"scribe":
			_ink_marks()
			if not _art and state != "puddle":
				_draw_scribe()
		"leech":
			_thread()
			if not _art:
				_draw_leech()


func _mound() -> void:
	var earth := Color(0.3, 0.26, 0.32)
	var edge := Color(0.5, 0.44, 0.5)
	if state == "under" or state == "rumble":
		var k := 0.35
		var jx := 0.0
		if state == "rumble":
			k = 0.35 + 0.65 * clampf(_t / maxf(0.05, T.v("crab_rumble")), 0.0, 1.0)
			jx = randf_range(-0.7, 0.7)
		var h := 2.0 + 8.0 * k
		var pts := PackedVector2Array()
		for i in 13:
			var x := -22.0 + i * 3.667
			var y := -h * (1.0 - pow(x / 22.0, 2.0))
			pts.append(Vector2(x + jx, y))
		draw_colored_polygon(pts, earth)
		draw_polyline(pts.slice(0, 13), edge, 0.5)
	for tr in _trail:
		var lx: float = tr.x - global_position.x
		var hh: float = 4.0 * clampf(tr.y / 0.8, 0.0, 1.0)
		if hh < 0.4:
			continue
		draw_colored_polygon(PackedVector2Array([Vector2(lx - 5.0, 0.0), Vector2(lx, -hh), Vector2(lx + 5.0, 0.0)]), earth)


func _ink_marks() -> void:
	# the puddle on the floor, and the drip waiting on the ceiling
	var ink := Color(0.1, 0.05, 0.16)
	var shine := Color(0.45, 0.3, 0.7)
	if state == "melt" or state == "puddle" or (state == "reform" and _t < 0.4):
		var k := 1.0
		if state == "melt":
			k = clampf(_t / 0.5, 0.0, 1.0)
		elif state == "reform":
			k = 1.0 - _t / 0.4
		var fy := _floor_y - global_position.y
		var r := 17.0 * k
		if k > 0.06:
			draw_colored_polygon(_ell(Vector2(0.0, fy), r, 3.0 * k + 0.5, 20), ink)
			draw_arc(Vector2(r * 0.3, fy - 0.5), r * 0.4, PI, TAU, 8, shine, 0.5)
	if state == "puddle":
		var dt := T.v("scribe_drip_time")
		var k := clampf(_t / dt, 0.0, 1.0)
		var at := to_local(_drip)
		var sz := 1.5 + 2.5 * k
		draw_line(at, at + Vector2(0.0, 3.0 + 6.0 * k), ink, 1.0)
		draw_circle(at + Vector2(0.0, 5.0 + 7.0 * k), sz, ink)
		draw_circle(at + Vector2(-sz * 0.3, 4.0 + 7.0 * k), sz * 0.3, shine)
		if _t > dt * 0.45 and int(_t * 16.0) % 2 == 0:
			draw_circle(at + Vector2(0.0, 5.0 + 7.0 * k), sz + 1.0, Color(1.0, 0.6, 0.2, 0.45))


func _thread() -> void:
	var tip := to_local(_ceil)
	draw_line(Vector2(0.0, 0.0), tip, Color(0.16, 0.1, 0.2), 1.0)
	draw_line(Vector2(0.4, 0.0), tip + Vector2(0.4, 0.0), Color(0.55, 0.45, 0.65), 0.5)
	draw_rect(Rect2(tip + Vector2(-2.0, -1.0), Vector2(4.0, 2.0)), Color(0.3, 0.25, 0.35))


func _draw_crab() -> void:
	var bone := Color(0.9, 0.84, 0.68)
	var shell := Color(0.45, 0.11, 0.14)
	var dark := Color(0.14, 0.04, 0.06)
	var rot := 0.0
	if state == "warn_rear":
		rot = -0.95 * minf(1.0, _t / 0.3) * facing
	elif state == "fan":
		rot = -0.95 * facing
	var s := Vector2(facing, 1.0)
	var pq := Vector2(-14.0, 0.0)
	draw_set_transform(Vector2(-14.0 * facing, 0.0) - (s * pq).rotated(rot), rot, s)
	var walk := sin(_bob * 4.0) * (3.0 if absf(velocity.x) > 5.0 else 0.0)
	for i in 4:
		var lx := -14.0 + i * 9.0
		var sw := walk if i % 2 == 0 else -walk
		draw_line(Vector2(lx, -8.0), Vector2(lx + sw - 3.0, 0.0), bone, 1.0)
		draw_line(Vector2(lx, -8.0), Vector2(lx + sw + 3.0, 0.0), dark, 0.5)
	draw_colored_polygon(_ell(Vector2(0.0, -9.0), 21.0, 10.0, 18), shell)
	draw_arc(Vector2(0.0, -9.0), 21.0, PI, TAU, 14, bone, 0.5)
	for i in 5:
		var sx := -13.0 + i * 6.5
		draw_colored_polygon(PackedVector2Array([Vector2(sx - 2.0, -16.0), Vector2(sx, -23.0 - (i % 2)), Vector2(sx + 2.0, -16.0)]), bone)
	var open := 0.2
	if state == "warn_pinch":
		open = 0.2 + 0.8 * clampf(_t / T.v("crab_pinch_warning"), 0.0, 1.0)
	elif state == "pinch":
		open = 0.9
	draw_line(Vector2(15.0, -10.0), Vector2(24.0, -12.0), bone, 1.5)
	draw_colored_polygon(PackedVector2Array([Vector2(24.0, -12.0), Vector2(31.0, -12.0 - 7.0 * open), Vector2(28.0, -11.0)]), bone)
	draw_colored_polygon(PackedVector2Array([Vector2(24.0, -12.0), Vector2(31.0, -12.0 + 5.0 * open), Vector2(28.0, -11.0)]), bone)
	draw_circle(Vector2(16.0, -17.0), 1.5, bone)
	draw_circle(Vector2(16.4, -17.0), 0.6, Color(1.0, 0.2, 0.2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_moth() -> void:
	var body := Color(0.55, 0.5, 0.62)
	var wing := Color(0.78, 0.74, 0.86)
	var edge := Color(0.3, 0.26, 0.38)
	var lift := sin(_t * 18.0 + _bob)
	if state == "warn_gust" or state == "gust":
		lift = 0.95 + sin(_t * 40.0) * 0.05
	elif state == "dive" or state == "warn_dive":
		lift = -0.7 + (sin(_t * 30.0) * 0.2 if state == "warn_dive" else 0.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	for sd in [-1.0, 1.0]:
		var tip := Vector2(sd * 24.0 * cos(lift * 0.9), -lift * 20.0 - 2.0)
		var fore := Vector2(sd * 15.0 * cos(lift * 0.9), -lift * 14.0 - 9.0)
		var back := Vector2(sd * 17.0 * cos(lift * 0.9), -lift * 13.0 + 10.0)
		draw_colored_polygon(PackedVector2Array([Vector2(sd * 3.0, -3.0), fore, tip, back, Vector2(sd * 3.0, 4.0)]), wing)
		draw_polyline(PackedVector2Array([Vector2(sd * 3.0, -3.0), fore, tip, back, Vector2(sd * 3.0, 4.0)]), edge, 0.5)
		draw_circle(tip.lerp(Vector2(sd * 3.0, 0.0), 0.4), 2.0, Color(0.5, 0.3, 0.45))
	draw_colored_polygon(_ell(Vector2(0.0, 0.0), 4.5, 9.0, 12), body)
	draw_circle(Vector2(0.0, -10.0), 3.2, body)
	draw_line(Vector2(-1.0, -12.0), Vector2(-4.0, -17.0), edge, 0.5)
	draw_line(Vector2(1.0, -12.0), Vector2(4.0, -17.0), edge, 0.5)
	draw_circle(Vector2(1.0, -10.0), 0.8, Color(1.0, 0.7, 0.3))
	draw_line(Vector2(0.0, 9.0), Vector2(0.0, 17.0), Color(0.7, 0.55, 0.3), 0.5)
	draw_circle(Vector2(0.0, 20.0), 3.2, Color(0.7, 0.55, 0.3))
	draw_circle(Vector2(0.0, 20.0), 1.2, Color(0.2, 0.12, 0.05))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_scribe() -> void:
	var robe := Color(0.1, 0.07, 0.16)
	var trim := Color(0.45, 0.35, 0.65)
	var mask := Color(0.9, 0.87, 0.8)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing * (1.0 + (1.0 - _squash) * 0.5), _squash))
	var wob := sin(_bob * 1.3) * 1.5
	var pts := PackedVector2Array([Vector2(0.0, -26.0), Vector2(7.0, -15.0), Vector2(9.0, 4.0), Vector2(13.0, 22.0)])
	for i in 6:
		pts.append(Vector2(13.0 - i * 5.2, 22.0 + (3.0 if i % 2 == 0 else -1.0) + wob))
	pts.append(Vector2(-13.0, 22.0))
	pts.append(Vector2(-9.0, 4.0))
	pts.append(Vector2(-7.0, -15.0))
	draw_colored_polygon(pts, robe)
	draw_polyline(pts, trim, 0.5)
	draw_line(Vector2(0.0, -12.0), Vector2(0.0, 18.0), trim, 0.5)
	draw_circle(Vector2(0.0, -17.0), 4.6, mask)
	draw_line(Vector2(-3.0, -18.0), Vector2(-1.0, -17.0), robe, 0.8)
	draw_line(Vector2(3.0, -18.0), Vector2(1.0, -17.0), robe, 0.8)
	var hand := Vector2(15.0, -6.0)
	if state == "warn_glyph":
		hand = Vector2(12.0 + sin(_t * 20.0) * 3.0, 8.0 + cos(_t * 20.0) * 3.0)
	draw_line(Vector2(6.0, -10.0), hand, robe, 2.0)
	draw_line(hand, hand + Vector2(9.0, -1.0), Color(0.85, 0.9, 1.0), 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_leech() -> void:
	var body := Color(0.5, 0.36, 0.55)
	var belly := Color(0.75, 0.6, 0.7)
	var w := sin(_t * 8.0) * (2.0 if state == "latched" else 0.5)
	for i in 6:
		var y := 4.0 + i * 5.0
		var r := 6.0 - i * 0.7 if i < 5 else 3.0
		draw_colored_polygon(_ell(Vector2(w * (i / 5.0), y), r, 3.6, 10), body if i % 2 == 0 else belly)
	draw_circle(Vector2(w, 29.0), 2.4, Color(0.2, 0.05, 0.1))
	draw_circle(Vector2(w, 29.0), 1.0, Color(0.9, 0.3, 0.4))


func paint_fx(c: CanvasItem) -> void:
	# glows and cues drawn with add blending, not flipped
	var warm := Color(1.0, 0.7, 0.3)
	match kind:
		"crab":
			if state == "warn_pinch":
				var k := clampf(_t / T.v("crab_pinch_warning"), 0.0, 1.0)
				var o := Vector2(facing * 29.0, -12.0)
				for sd in [-1.0, 1.0]:
					c.draw_line(o, o + Vector2(facing * 6.0, sd * (3.0 + 6.0 * k)), Color(1.0, 0.95, 0.7, 0.4 + 0.5 * k), 1.0)
				c.draw_circle(o, 1.2 + 1.4 * k, Color(1.0, 0.85, 0.5, 0.1 + 0.3 * k))
			elif state == "warn_rear":
				for i in 6:
					var a := Vector2(-facing * 8.0 + randf_range(-14.0, 14.0), -26.0 + randf_range(-6.0, 4.0))
					c.draw_rect(Rect2(a, Vector2(1, 1)), Color(1.0, 0.9, 0.6, 0.8))
			elif state == "pinch":
				for i in 3:
					var y := -4.0 - i * 5.0
					c.draw_line(Vector2(-facing * 22.0, y), Vector2(-facing * (34.0 + i * 5.0), y), Color(1.0, 0.8, 0.5, 0.35), 0.5)
		"moth":
			if state == "warn_veil":
				var k := clampf(_t / T.v("moth_veil_warning"), 0.0, 1.0)
				Util.glow(c, Vector2(0.0, 20.0), 6.0 + 6.0 * k, Color(1.0, 0.55, 0.2, 0.2 + 0.4 * k))
				c.draw_circle(Vector2(0.0, 20.0), 1.4, Color(1.0, 0.9, 0.6, 0.9))
			elif state == "warn_gust":
				var k := clampf(_t / T.v("moth_gust_warning"), 0.0, 1.0)
				for sd in [-1.0, 1.0]:
					c.draw_line(Vector2(sd * 12.0, -24.0), Vector2(sd * (12.0 + 10.0 * k), -34.0 - 4.0 * k), Color(0.8, 0.9, 1.0, 0.3 + 0.5 * k), 0.5)
					c.draw_circle(Vector2(sd * 14.0, -22.0), 1.5, Color(0.9, 0.95, 1.0, 0.6))
			elif state == "warn_dive" or state == "dive":
				Util.glow(c, Vector2.ZERO, 14.0, Color(1.0, 0.45, 0.15, 0.3))
				if state == "dive":
					c.draw_line(Vector2.ZERO, -(_bez(minf(_t / T.v("moth_dive_time") + 0.04, 1.0)) - global_position) * 2.0, Color(1.0, 0.6, 0.2, 0.4), 1.0)
		"scribe":
			if state == "warn_needle":
				var k := clampf(_t / T.v("scribe_needle_warning"), 0.0, 1.0)
				var hand := Vector2(facing * 24.0, -7.0)
				var r := 2.0 + 4.0 * k
				Util.glow(c, hand, r + 2.0, Color(1.0, 0.95, 0.8, 0.35))
				c.draw_line(hand - Vector2(r + 2.0, 0.0), hand + Vector2(r + 2.0, 0.0), Color(1.0, 1.0, 0.9, 0.9), 0.5)
				c.draw_line(hand - Vector2(0.0, r + 2.0), hand + Vector2(0.0, r + 2.0), Color(1.0, 1.0, 0.9, 0.9), 0.5)
				if _t >= 0.3:
					var dir := (_aim - global_position - hand).normalized()
					c.draw_line(hand, hand + dir * 70.0, Color(1.0, 0.7, 0.4, 0.25), 0.5)
			elif state == "puddle":
				var dt := T.v("scribe_drip_time")
				var kk := clampf(_t / dt, 0.0, 1.0)
				var at := to_local(_drip) + Vector2(0.0, 5.0 + 7.0 * kk)
				var locked := _t > dt * 0.45
				var hot := locked and int(_t * 16.0) % 2 == 0
				Util.glow(c, at, 7.0, Color(1.0, 0.6, 0.2, 0.55) if hot else Color(0.7, 0.4, 1.0, 0.45))
				var land := to_local(Vector2(_drip.x, _land_y))
				c.draw_set_transform(land, 0.0, Vector2(1.0, 0.3))
				var mc := Color(1.0, 0.6, 0.3, 0.9) if hot else Color(0.75, 0.45, 1.0, 0.5 + 0.3 * kk)
				c.draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 24, mc, 1.0)
				c.draw_arc(Vector2.ZERO, 8.0 * kk, 0.0, TAU, 16, mc, 0.5)
				c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			elif state == "warn_glyph":
				for i in 5:
					c.draw_rect(Rect2(Vector2(randf_range(8.0, 22.0) * facing, randf_range(0.0, 12.0)), Vector2(1, 1)), Color(0.8, 0.6, 1.0, 0.8))
		"leech":
			if state == "warn_drop":
				var k := clampf(_t / T.v("leech_drop_warning"), 0.0, 1.0)
				var fall := k * k * 140.0
				c.draw_circle(Vector2(0.0, 32.0 + fall), 2.0, Color(0.7, 1.0, 0.3, 0.7))
				c.draw_circle(Vector2(0.0, 32.0 + fall), 4.0, Color(0.7, 1.0, 0.3, 0.15))
				Util.glow(c, Vector2(0.0, 18.0), 9.0 + 5.0 * k, Color(1.0, 0.6, 0.3, 0.2 + 0.4 * k))
			elif state == "latched":
				Util.glow(c, Vector2(0.0, 15.0), 12.0, Color(0.9, 0.2, 0.4, 0.25 + 0.15 * sin(_t * 14.0)))


# ---------- helpers shared with the things the enemies throw ----------

class Util:
	static func can_hit() -> bool:
		var m = G.main
		if G.peace or G.frozen() or m == null:
			return false
		if m.player == null or m.player.state == "dead":
			return false
		return not bool(m.get("_busy")) and not bool(m.get("hold"))

	static func cell(x: float, y: float) -> String:
		return G.main.room.cell(int(floor(x / 16.0)), int(floor(y / 16.0)))

	static func floor_below(x: float, y: float) -> float:
		# the top edge of the first solid or ledge cell at or under (x, y)
		var cx := int(floor(x / 16.0))
		var r := int(floor(y / 16.0))
		var rows: int = G.main.room.grid.size()
		while r < rows:
			var ch: String = G.main.room.cell(cx, r)
			if ch == "#" or ch == "=":
				return float(r) * 16.0
			r += 1
		return float(rows) * 16.0

	static func ceil_above(x: float, y: float) -> float:
		# the lower edge of the first solid cell above (x, y)
		var cx := int(floor(x / 16.0))
		var r := int(floor(y / 16.0))
		while r >= 0:
			if G.main.room.cell(cx, r) == "#":
				return float(r + 1) * 16.0
			r -= 1
		return 0.0

	static func snd(name: String, at: Vector2, db: float = -6.0, pitch: float = 1.0) -> void:
		var d := 0.0
		if G.main != null and G.main.player != null:
			d = at.distance_to(G.main.player.global_position)
		if d > 460.0:
			return
		Sfx.play_file("sfx/world/%s.wav" % name, db - clampf((d - 150.0) / 12.0, 0.0, 28.0), pitch * randf_range(0.96, 1.04))

	static func glow(c: CanvasItem, at: Vector2, r: float, col: Color) -> void:
		# a soft light: four nested circles, each faint, so it fades toward the edge
		for i in 4:
			c.draw_circle(at, r * (1.0 - i * 0.22), Color(col.r, col.g, col.b, col.a * 0.3))

	static func circle_hits(center: Vector2, r: float, rect: Rect2) -> bool:
		var cp := Vector2(clampf(center.x, rect.position.x, rect.end.x), clampf(center.y, rect.position.y, rect.end.y))
		return center.distance_to(cp) < r

	static func pin(player: Node2D, secs: float) -> void:
		# the needle roots her: a hurt pose, no movement, a needle and shackles drawn on her
		if player.state == "dead":
			return
		if player.state == "attack" and String(player.get("_attack_kind")) == "special":
			return
		var old: Node = player.get_node_or_null("Pin")
		if old != null:
			old.left = maxf(old.left, secs)
			return
		var pn := Pin.new()
		pn.left = secs
		player.add_child(pn)


# A glow layer on top of an enemy: it asks the enemy what to draw.
class Overlay extends Node2D:
	var owner_e: Node2D

	func _init() -> void:
		z_index = 1
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

	func _draw() -> void:
		if owner_e != null and is_instance_valid(owner_e):
			owner_e.paint_fx(self)


# What an enemy throws: the crab's spines (arc and fall) and the scribe's needle (fast, pins).
class Shot extends Node2D:
	var kind := "spine"
	var vel := Vector2.ZERO
	var grav := 0.0
	var dmg := 10.0
	var pin := 0.0
	var life := 3.0
	var fake := false

	func _ready() -> void:
		add_to_group("e2_shot")

	func _physics_process(delta: float) -> void:
		if G.frozen():
			return
		vel.y += grav * delta
		global_position += vel * delta
		life -= delta
		rotation = vel.angle()
		queue_redraw()
		var p := global_position
		var gone := life <= 0.0
		if not gone and Util.cell(p.x, p.y) == "#":
			gone = true
			G.main.dust(p, 3)
		if not gone and Util.can_hit():
			var player: Node2D = G.main.player
			var box := Rect2(p - Vector2(3, 3), Vector2(6, 6))
			if box.intersects(player.body_rect()):
				if fake:
					G.main.fx("spark", p)
					gone = true
				elif player.invuln <= 0.0:
					player.take_hit(dmg, p.x - signf(vel.x) * 4.0)
					if pin > 0.0 and player.state != "dead":
						Util.pin(player, pin)
					gone = true
		if gone:
			queue_free()

	func _draw() -> void:
		if kind == "needle":
			draw_line(Vector2(-26, 0), Vector2(-9, 0), Color(0.6, 0.4, 0.9, 0.35), 0.5)
			draw_line(Vector2(-9, 0), Vector2(8, 0), Color(0.85, 0.9, 1.0), 1.0)
			draw_line(Vector2(-9, 0), Vector2(8, 0), Color(0.3, 0.3, 0.4), 0.5)
			draw_circle(Vector2(-9, 0), 1.3, Color(0.7, 0.5, 1.0))
			draw_circle(Vector2(8, 0), 0.8, Color(1.0, 1.0, 1.0))
		else:
			draw_line(Vector2(-5, 0), Vector2(4, 0), Color(0.9, 0.84, 0.68), 1.5)
			draw_colored_polygon(PackedVector2Array([Vector2(3, -1.5), Vector2(8, 0), Vector2(3, 1.5)]), Color(0.95, 0.9, 0.78))
			draw_line(Vector2(-5, 0), Vector2(-2, 0), Color(0.45, 0.11, 0.14), 2.0)
			draw_line(Vector2(-1, -0.5), Vector2(5, -0.5), Color(1.0, 1.0, 0.95), 0.5)


# A drifting cloud of incense smoke. It hurts on touch and blocks the view a little.
class Cloud extends Node2D:
	var vel := Vector2.ZERO
	var life := 6.0
	var max_life := 6.0
	var r := 8.0
	var dmg := 10.0
	var _t := 0.0
	var _seed := randf() * TAU

	func _ready() -> void:
		add_to_group("e2_cloud")

	func _physics_process(delta: float) -> void:
		if G.frozen():
			return
		_t += delta
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		r = minf(r + 7.0 * delta, 19.0)
		var wob := Vector2(sin(_t * 1.7 + _seed), cos(_t * 1.3 + _seed)) * 7.0
		var np := global_position + (vel + wob) * delta
		if Util.cell(np.x, np.y) != "#":
			global_position = np
		else:
			vel = -vel * 0.5
		vel *= 1.0 - 0.1 * delta
		queue_redraw()
		if Util.can_hit():
			var player: Node2D = G.main.player
			if player.invuln <= 0.0 and Util.circle_hits(global_position, r * 0.8, player.body_rect()):
				player.take_hit(dmg, global_position.x)

	func _draw() -> void:
		var fade := clampf(life / 1.5, 0.0, 1.0) * clampf(_t / 0.4, 0.0, 1.0)
		for i in 7:
			var a := _seed + i * 0.9 + _t * 0.25
			var o := Vector2(cos(a), sin(a * 1.3)) * r * 0.45
			var rr := r * (0.55 + 0.1 * sin(_t * 2.0 + i))
			draw_circle(o, rr, Color(0.55, 0.5, 0.58, 0.2 * fade))
		draw_circle(Vector2.ZERO, r * 0.7, Color(0.62, 0.55, 0.52, 0.28 * fade))
		draw_arc(Vector2.ZERO, r * 0.95, 0.0, TAU, 20, Color(0.8, 0.65, 0.5, 0.18 * fade), 0.5)


# The wing gust: a push, no damage. It throws her sideways a few tiles.
class Gust extends Node2D:
	var dir := 1
	var dist := 56.0
	var life := 0.35
	var pushing := false
	var _t := 0.0

	func _ready() -> void:
		add_to_group("e2_gust")
		var p: Node2D = G.main.player
		var chest := p.global_position + Vector2(0.0, -18.0)
		var dx := p.global_position.x - global_position.x
		pushing = int(signf(dx)) == dir and absf(dx) < 150.0 and absf(chest.y - global_position.y) < 90.0

	func _physics_process(delta: float) -> void:
		if G.frozen():
			return
		_t += delta
		if pushing and Util.can_hit():
			var p: Node2D = G.main.player
			var vx: float = p.velocity.x
			var opp := maxf(0.0, -dir * vx)
			p.move_and_collide(Vector2(dir * (dist / maxf(life, 0.05) + opp) * delta, 0.0))
		queue_redraw()
		if _t >= life:
			queue_free()

	func _draw() -> void:
		var k := clampf(_t / maxf(life, 0.05), 0.0, 1.0)
		for i in 7:
			var y := -22.0 + i * 8.0
			var x0 := dir * (8.0 + k * 90.0 + i * 5.0)
			draw_line(Vector2(x0, y), Vector2(x0 + dir * (14.0 + 10.0 * (i % 3)), y + sin(i * 2.0 + _t * 30.0) * 2.0), Color(0.85, 0.92, 1.0, 0.6 * (1.0 - k)), 0.5)
		var base := 0.0 if dir > 0 else PI
		draw_arc(Vector2(dir * (10.0 + k * 70.0), -2.0), 14.0, base - 1.1, base + 1.1, 10, Color(0.9, 0.95, 1.0, 0.5 * (1.0 - k)), 0.5)


# An ember: it falls, lands on the floor and burns for a moment.
class Ember extends Node2D:
	var dmg := 8.0
	var burn := 1.0
	var _vy := 0.0
	var _t := 0.0
	var _landed := false

	func _init() -> void:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

	func _ready() -> void:
		add_to_group("e2_ember")

	func _physics_process(delta: float) -> void:
		if G.frozen():
			return
		if not _landed:
			_vy = minf(_vy + 360.0 * delta, 260.0)
			global_position.y += _vy * delta
			var ch := Util.cell(global_position.x, global_position.y + 2.0)
			if ch == "#" or ch == "=":
				_landed = true
				global_position.y = floorf((global_position.y + 2.0) / 16.0) * 16.0
			elif global_position.y > G.main.room.size.y:
				queue_free()
				return
		else:
			_t += delta
			if _t >= burn:
				queue_free()
				return
		queue_redraw()
		if Util.can_hit():
			var player: Node2D = G.main.player
			var box := Rect2(global_position + Vector2(-3, -3), Vector2(6, 6)) if not _landed else Rect2(global_position + Vector2(-4, -9), Vector2(8, 9))
			if player.invuln <= 0.0 and box.intersects(player.body_rect()):
				player.take_hit(dmg, global_position.x)

	func _draw() -> void:
		if not _landed:
			draw_circle(Vector2.ZERO, 1.5, Color(1.0, 0.7, 0.3))
			draw_circle(Vector2.ZERO, 3.5, Color(1.0, 0.4, 0.1, 0.25))
			draw_line(Vector2(0, -1), Vector2(0, -6), Color(1.0, 0.5, 0.15, 0.5), 0.5)
		else:
			var fade := clampf((burn - _t) / 0.3, 0.0, 1.0)
			var h := 6.0 + sin(_t * 30.0) * 2.0 + sin(_t * 17.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-3.5, 0), Vector2(-1.5, -h * 0.7), Vector2(0.5, -h), Vector2(2.0, -h * 0.6), Vector2(3.5, 0)]), Color(1.0, 0.35, 0.08, 0.7 * fade))
			draw_colored_polygon(PackedVector2Array([Vector2(-1.8, 0), Vector2(0, -h * 0.65), Vector2(1.8, 0)]), Color(1.0, 0.85, 0.4, 0.8 * fade))
			draw_circle(Vector2(0, -2), 6.0, Color(1.0, 0.4, 0.1, 0.12 * fade))


# The scribe's glyph: it draws itself on the floor and bursts when the fuse runs out.
class Glyph extends Node2D:
	var fuse := 0.9
	var radius := 34.0
	var dmg := 22.0
	var harm := true
	var _t := 0.0

	func _init() -> void:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m

	func _ready() -> void:
		add_to_group("e2_glyph")

	func _physics_process(delta: float) -> void:
		if G.frozen():
			return
		_t += delta
		queue_redraw()
		if _t >= fuse:
			_burst()

	func _burst() -> void:
		Util.snd("glyph_burst", global_position, -2.0)
		G.main.ring_fx(global_position + Vector2(0, -6), radius, Color(0.75, 0.45, 1.0))
		G.main.shake(3.0, 0.2)
		Vfx.burst(global_position, 24, Color(0.7, 0.4, 1.0), -PI / 2.0, 0.9, Vector2(60.0, 180.0), 0.6, 260.0, 1.5, 4.0)
		Vfx.ring(global_position, radius * 0.3, radius, 0.3, Color(0.8, 0.55, 1.0), 0.35, 1.5)
		if harm and Util.can_hit():
			var player: Node2D = G.main.player
			var zone := Rect2(global_position + Vector2(-radius, -44.0), Vector2(radius * 2.0, 48.0))
			if player.invuln <= 0.0 and zone.intersects(player.body_rect()):
				player.take_hit(dmg, global_position.x)
		queue_free()

	func _draw() -> void:
		var k := clampf(_t / fuse, 0.0, 1.0)
		var late := _t > fuse - 0.3
		var blink := late and int(_t * 16.0) % 2 == 0
		var col := Color(1.0, 0.65, 0.3) if blink else Color(0.75, 0.45, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
		var prog := clampf(k * 1.6, 0.0, 1.0)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU * prog, 40, Color(col.r, col.g, col.b, 0.9), 1.0)
		draw_arc(Vector2.ZERO, radius * 0.72, PI, PI + TAU * prog, 32, Color(col.r, col.g, col.b, 0.6), 0.5)
		for i in 10:
			if float(i) / 10.0 > prog:
				break
			var a := TAU * i / 10.0 + k * 0.6
			var d := Vector2(cos(a), sin(a))
			draw_line(d * radius * 0.72, d * radius * 0.98, col, 0.5)
		if k > 0.35:
			var star := PackedVector2Array()
			for i in 6:
				var a := TAU * i / 6.0 + PI / 2.0
				star.append(Vector2(cos(a), sin(a)) * radius * 0.5)
			star.append(star[0])
			draw_polyline(star, Color(col.r, col.g, col.b, 0.8), 0.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if late:
			draw_circle(Vector2(0, -2), radius * 0.3 * (1.0 + (k - 0.67) * 2.0), Color(col.r, col.g, col.b, 0.18))


# The needle's hold: a hurt pose, no movement, a needle through her and shackles at her ankles.
class Pin extends Node2D:
	var left := 0.8
	var _t := 0.0

	func _init() -> void:
		name = "Pin"
		z_index = 5

	func _physics_process(delta: float) -> void:
		if G.frozen():
			return
		var p: Node2D = get_parent()
		_t += delta
		left -= delta
		if p == null or p.state == "dead" or left <= 0.0:
			queue_free()
			return
		p.state = "hurt"
		p.set("_hurt_t", maxf(left, 0.05))
		var v: Vector2 = p.velocity
		v.x = 0.0
		p.velocity = v
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.6 + 0.4 * sin(_t * 20.0)
		var metal := Color(0.82, 0.86, 0.95)
		var violet := Color(0.7, 0.45, 1.0, pulse)
		# the needle, through her chest
		draw_line(Vector2(-9.0, -31.0), Vector2(8.0, -17.0), Color(0.2, 0.2, 0.3), 1.5)
		draw_line(Vector2(-9.0, -31.0), Vector2(8.0, -17.0), metal, 0.5)
		draw_circle(Vector2(-9.0, -31.0), 1.4, violet)
		draw_line(Vector2(-9.0, -31.0), Vector2(-14.0, -38.0), Color(0.6, 0.4, 0.9, 0.6), 0.5)
		# shackles at both ankles, chained to the floor
		for sd in [-1.0, 1.0]:
			var a := Vector2(sd * 4.0, -2.0)
			draw_arc(a, 3.5, 0.0, TAU, 10, Color(0.15, 0.12, 0.2), 1.5)
			draw_arc(a, 3.5, 0.0, TAU, 10, violet, 0.5)
			draw_line(a, Vector2(sd * 12.0, 0.0), Color(0.35, 0.3, 0.45), 0.5)
			draw_circle(Vector2(sd * 12.0, 0.0), 1.0, violet)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
		draw_arc(Vector2(0.0, 0.0), 13.0, 0.0, TAU, 24, Color(violet.r, violet.g, violet.b, 0.5), 0.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
