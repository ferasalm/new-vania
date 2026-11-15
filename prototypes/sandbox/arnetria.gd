# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# ARNETRIA, THE MIRROR QUEEN — the Denial boss.
#
# v1's version of her lie was "the bar stalls at 1/3 and three whiffed sweeps crack
# it". v2 is the playtest's version, and it is a better lie: the bar does not move
# AT ALL. Every hit lands and prints, and every point of it is STORED. The store is
# printed beside her bar, so nothing is hidden — the damage exists, she simply
# refuses to file it.
#
# The only conduit is the mirror she casts on a period. Break it inside its timer
# ring and the whole store comes due in one lurch. Miss and the store is cleared —
# the damage never happened, which is exactly what she believes.
#
# The phase ends when the bar finally moves past the stall (hp <= hp_floor 20,
# TR-GBF-012). Phase 2 is her without the lie: direct damage, tighter cadence.
extends Node2D

const Assets = preload("res://assets.gd")
const MIRROR := preload("res://mirror.gd")

var hp := float(K.BOSS_HP_POOL)
var hp_max := float(K.BOSS_HP_POOL)
var hp_floor := float(K.BOSS_HP_FLOOR)
var stored := 0.0
var phase := "LIE_WHOLE"        # LIE_WHOLE | LIE_CRACKED (phase 2)
var mirror = null

var state := "idle"             # idle | telegraph | active | recovery | stagger | script
var state_ms := 0.0
var facing := -1
var flash_ms := 0.0
var strike_key := "sweep"
var strike: Dictionary = {}
var hit_done := false

var cadence_t := 0.0
var mirror_cd := float(K.MIRROR_PERIOD_MS)
var script_t := 0.0
var script_stage := ""
var t := 0.0
var lurch_ms := 0.0
var store_flash_ms := 0.0

var shards: Array = []          # {pos, vel, t, mine}
var anchor := Vector2.ZERO
var arena_left := 40.0
var arena_right := 920.0
var _player: Node2D = null

var tex_idle: Texture2D
var tex_cast: Texture2D
var tex_attack: Texture2D
var tex_shard: Texture2D


func setup(at: Vector2, left_x: float, right_x: float) -> void:
	position = at
	anchor = at
	arena_left = left_x
	arena_right = right_x
	z_index = 14


func watch(p: Node2D) -> void:
	_player = p


func _ready() -> void:
	tex_idle = Assets.tex("res://assets/arnetria/idle.png")
	tex_cast = Assets.tex("res://assets/arnetria/cast.png")
	tex_attack = Assets.tex("res://assets/arnetria/attack.png")
	tex_shard = Assets.tex("res://assets/arnetria/shard.png")


# ── the clock ───────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if K.frozen:
		return
	var ms := delta * 1000.0
	t += delta
	if flash_ms > 0.0:
		flash_ms = maxf(0.0, flash_ms - ms)
	if store_flash_ms > 0.0:
		store_flash_ms = maxf(0.0, store_flash_ms - ms)
	if lurch_ms > 0.0:
		lurch_ms = maxf(0.0, lurch_ms - ms)
	_tick_shards(delta)
	if mirror != null and is_instance_valid(mirror):
		mirror.tick(delta)
		if not mirror.alive:
			_resolve_mirror()

	if state == "script":
		script_t += ms
		if script_t < K.RECOGNITION_BEAT_MS:
			script_stage = "recognition"
		elif script_t < K.RECOGNITION_BEAT_MS + K.DISSOLVE_MS:
			script_stage = "dissolve"
		else:
			script_stage = "done"
		queue_redraw()
		return

	state_ms += ms
	if state == "idle":
		cadence_t += ms
		mirror_cd = maxf(0.0, mirror_cd - ms)

	match state:
		"idle":
			if mirror == null and mirror_cd <= 0.0 and _player:
				_begin_move("cast")
			elif _player and cadence_t >= _cadence():
				_decide()
		"telegraph":
			if state_ms >= float(strike.get("telegraph", 350)):
				state = "active"
				state_ms = 0.0
				if strike_key == "cast":
					_spawn_mirror()
				elif strike_key == "fling":
					_launch_shards()
		"active":
			if state_ms >= float(strike.get("active", 100)):
				state = "recovery"
				state_ms = 0.0
		"recovery":
			if state_ms >= float(strike.get("recovery", 133)):
				state = "idle"
				state_ms = 0.0
				cadence_t = 0.0
		"stagger":
			if state_ms >= K.BOSS_COUNTER_STAGGER_MS:
				state = "idle"
				state_ms = 0.0
				cadence_t = 0.0
	queue_redraw()


func _cadence() -> float:
	return K.BOSS_CADENCE_MS if phase == "LIE_WHOLE" else K.BOSS_CADENCE_CRACKED_MS


func _decide() -> void:
	var dist := 9999.0
	if _player:
		dist = absf(_player.position.x - position.x)
	facing = 1 if (_player and _player.position.x > position.x) else -1
	cadence_t = 0.0
	# the ring sweep owns the close, the shard fling owns the middle
	if dist < 150.0:
		_begin_move("sweep")
	elif dist < 520.0:
		_begin_move("fling")
	else:
		_begin_move("cast" if mirror == null else "fling")


func _begin_move(key: String) -> void:
	strike_key = key
	strike = K.ARN_MOVES[key]
	state = "telegraph"
	state_ms = 0.0
	hit_done = false
	if key == "cast":
		mirror_cd = float(K.MIRROR_PERIOD_MS)


# ── the mirror ──────────────────────────────────────────────────────────────
func _spawn_mirror() -> void:
	if mirror != null or get_parent() == null:
		return
	mirror = MIRROR.new()
	get_parent().add_child(mirror)
	# she sets it where the fight is, not where she is. It hangs LOW on purpose:
	# a ground strike's hitbox tops out 94 px above the floor, so a mirror above
	# that is a mirror nobody can ever break (see MIRROR_HOVER).
	var side := -1.0 if position.x > 480.0 else 1.0
	mirror.position = Vector2(clampf(position.x + side * 150.0, arena_left + 40.0, arena_right - 40.0),
		position.y - K.MIRROR_HOVER)


func mirror_node():
	return mirror


func _resolve_mirror() -> void:
	if mirror == null:
		return
	if mirror.broke:
		# THE LURCH: everything she withheld comes due at once
		hp = maxf(hp_floor, hp - stored)
		stored = 0.0
		lurch_ms = float(K.BAR_LURCH_MS)
		store_flash_ms = 420.0
		_do_flash()
		Assets.fx_burst(get_parent(), mirror.position, "fx/shatter", Assets.FX["shatter"], 1.2)
		if hp <= hp_floor + 0.001 and phase == "LIE_WHOLE":
			_enter_phase_two()
		mirror.queue_free()
		mirror = null
	elif mirror.expired:
		# the store is cleared: the damage never happened
		stored = 0.0
		store_flash_ms = 260.0
		mirror.queue_free()
		mirror = null


func _enter_phase_two() -> void:
	phase = "LIE_CRACKED"
	hp_floor = 0.0
	hp = maxf(hp, 1.0)
	_do_flash()


func _do_flash() -> void:
	flash_ms = 120.0


# ── the shards ──────────────────────────────────────────────────────────────
func _launch_shards() -> void:
	if _player == null:
		return
	var origin := position + Vector2(0, -150)
	var to := (_player.position + Vector2(0, -60) - origin)
	for i in 3:
		var spread := (float(i) - 1.0) * 0.22
		var dir := to.normalized().rotated(spread)
		shards.append({"pos": origin + Vector2(facing * 30.0, 0), "vel": dir * float(K.SHARD["speed"]),
			"t": 0.0, "mine": false})


func _tick_shards(delta: float) -> void:
	for s in shards:
		s["t"] += delta * 1000.0
		s["pos"] += s["vel"] * delta
		if s["pos"].y > anchor.y:
			s["t"] = 99999.0
	shards = shards.filter(func(s): return s["t"] < float(K.SHARD["lifetime"]))


func shard_rects() -> Array:
	var out: Array = []
	for i in shards.size():
		out.append({"idx": i, "rect": Rect2(shards[i]["pos"].x - 12, shards[i]["pos"].y - 12, 24, 24),
			"mine": shards[i]["mine"]})
	return out


func consume_shard(idx: int) -> void:
	if idx >= 0 and idx < shards.size():
		shards[idx]["t"] = 99999.0
	shards = shards.filter(func(s): return s["t"] < float(K.SHARD["lifetime"]))


func deflect_shard(idx: int) -> void:
	if idx < 0 or idx >= shards.size():
		return
	var s: Dictionary = shards[idx]
	s["mine"] = true
	s["vel"] = -s["vel"].normalized() * float(K.SHARD["deflect_speed"])
	s["t"] = 0.0


# ── the read surface (the enemy contract fight.gd speaks) ───────────────────
func is_dead() -> bool:
	return state == "script" and script_t >= K.RECOGNITION_BEAT_MS + K.DISSOLVE_MS


func script_done() -> bool:
	return is_dead()


func strike_phase() -> String:
	if state == "telegraph" or state == "active":
		return state
	return "none"


func counter_open() -> bool:
	if state != "telegraph":
		return false
	if not bool(strike.get("counterable", false)):
		return false
	return state_ms >= float(strike.get("telegraph", 350)) - K.COUNTER_WINDOW_MS


func can_counter() -> bool:
	return bool(strike.get("counterable", false))


func clashable() -> bool:
	return bool(strike.get("clashable", false))


func power() -> int:
	return int(strike.get("power", 1))


func strike_name() -> String:
	return String(strike.get("name", "the ring"))


func telegraph_len() -> float:
	return float(strike.get("telegraph", 350))


func active_len() -> float:
	return float(strike.get("active", 100))


func hurtbox() -> Rect2:
	var h := 300.0
	var w := 120.0
	return Rect2(position.x - w * 0.5, position.y - h, w, h)


func active_hitbox() -> Rect2:
	if state != "active" or hit_done:
		return Rect2()
	var reach := float(strike.get("reach", 120.0))
	var x := position.x + (10.0 if facing > 0 else -10.0 - reach)
	return Rect2(x, position.y - 150.0, reach, 130.0)


func consume_strike() -> void:
	hit_done = true


func on_contact() -> void:
	pass


func stagger(ms: float) -> void:
	if state == "script":
		return
	state = "stagger"
	state_ms = 0.0
	for s in shards:
		s["t"] = 99999.0
	shards.clear()


func take_damage(dmg: int) -> Dictionary:
	if state == "script":
		return {"dealt": 0, "dead": false, "stored": true}
	flash_ms = 90.0
	if phase == "LIE_WHOLE":
		# the lie: nothing files. The store grows, the bar does not move.
		stored = minf(stored + float(dmg), float(K.stored_cap()))
		store_flash_ms = 180.0
		return {"dealt": 0, "dead": false, "stored": true}
	hp = maxf(0.0, hp - float(dmg))
	if hp <= 0.0:
		state = "script"
		script_t = 0.0
		script_stage = "recognition"
		return {"dealt": dmg, "dead": true, "stored": false}
	return {"dealt": dmg, "dead": false, "stored": false}


# ── draw ────────────────────────────────────────────────────────────────────
func _tex() -> Texture2D:
	if state == "script":
		return tex_idle
	if strike_key == "cast" and (state == "telegraph" or state == "active"):
		return tex_cast
	if strike_key == "fling" and (state == "telegraph" or state == "active"):
		return tex_attack
	return tex_idle


func _draw() -> void:
	var bob: float = sin(t * 1.3) * 7.0
	var sc: float = K.ARN_SCALE
	var tx := _tex()
	var alpha := 1.0
	if state == "script" and script_stage == "dissolve":
		alpha = clampf(1.0 - (script_t - K.RECOGNITION_BEAT_MS) / float(K.DISSOLVE_MS), 0.0, 1.0)
	if state == "script" and script_stage == "done":
		alpha = 0.0

	# the floor pool: she floats, so she casts a thin, wide shadow
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1, 0.18))
	draw_circle(Vector2.ZERO, 62.0, Color(0, 0, 0, 0.30 * alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if tx:
		var w: float = tx.get_width() * sc
		var h: float = tx.get_height() * sc
		var m := Color(1, 1, 1, alpha)
		if flash_ms > 0.0:
			m = Color(2.2, 2.2, 2.2, alpha)
		elif state == "telegraph" and int(state_ms / 80.0) % 2 == 0:
			m = Color(1.5, 1.6, 1.7, alpha)
		elif state == "stagger":
			m = Color(0.7, 1.3, 1.5, alpha)
		# she faces the player; the art is drawn facing left, so flip on facing
		var sx := -1.0 if facing > 0 else 1.0
		draw_set_transform(Vector2(0, bob), 0.0, Vector2(sx, 1))
		draw_texture_rect(tx, Rect2(-w * 0.5, -h, w, h), false, m)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# the store, made visible: ice motes orbiting her while she withholds
	if stored > 0.5:
		for i in int(minf(12.0, stored)):
			var ang: float = t * 0.9 + i * TAU / 12.0
			var rad: float = 70.0 + 14.0 * sin(t * 1.7 + i)
			var p := Vector2(cos(ang) * rad, -150.0 + sin(ang) * rad * 0.45 + bob)
			draw_circle(p, 2.0, Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, 0.55))

	# the shards in flight
	for s in shards:
		var p: Vector2 = s["pos"] - position
		var col: Color = K.C_CYAN if bool(s["mine"]) else Color(1, 1, 1, 1)
		if tex_shard:
			var sw: float = tex_shard.get_width() * 0.7
			var sh: float = tex_shard.get_height() * 0.7
			draw_texture_rect(tex_shard, Rect2(p.x - sw * 0.5, p.y - sh * 0.5, sw, sh), false, col)
		else:
			draw_circle(p, 7.0, col)

	# phase 2: the stall is broken, the ring cracks
	if phase == "LIE_CRACKED":
		var ring_c := Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, 0.35)
		draw_arc(Vector2(0, -150.0 + bob), 96.0, PI * 0.15, PI * 0.85, 24, ring_c, 2.0)
		draw_line(Vector2(-30, -240 + bob), Vector2(-14, -200 + bob), ring_c, 2.0)
		draw_line(Vector2(28, -238 + bob), Vector2(44, -206 + bob), ring_c, 2.0)

	if store_flash_ms > 0.0:
		var a2: float = clampf(store_flash_ms / 420.0, 0.0, 1.0)
		draw_rect(Rect2(-120, -330, 240, 340), Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, a2 * 0.10))
