# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its landed numbers are played, not read?
# Date: 2026-11-16
# DENIAL — the ring is her weapon. SYS-14 grief-boss-framework.md, consumed:
#   hp 60 (BOSS_HP) · hp_floor 20 in LIE_WHOLE (the bar stalls at 1/3) ·
#   3 unanswered ring sweeps crack the lie (CRACK_WHIFFS_REQUIRED) ·
#   the 2000 ms crack beat releases the floor at its first tick (TR-GBF-013) ·
#   the four-cycle decision table, no RNG (TR-GBF-010) · the ring return deflects.
extends Node2D

var hp := float(K.BOSS_HP_POOL)
var hp_max := float(K.BOSS_HP_POOL)
var hp_floor := float(K.BOSS_HP_FLOOR)
var phase := "LIE_WHOLE"        # LIE_WHOLE | LIE_CRACKED
var whiffs := 0
var crack_stage := 0
var cracked_once := false

var state := "idle"             # idle | telegraph | active | recovery | stagger | crack | script | dead
var state_ms := 0.0
var facing := -1
var flash_ms := 0.0
var crack_flash_ms := 0.0
var last_flash_ms := -1000.0

var strike_key := "sweep"
var strike: Dictionary = {}
var strike_id := 0
var hit_done := false
var contact_published := false

var cadence_t := 0.0
var cycle := 0
var beat_t := 0.0
var script_t := 0.0
var script_stage := ""
var anchor := Vector2.ZERO

var proj_alive := false
var proj_pos := Vector2.ZERO
var proj_vel := Vector2.ZERO
var proj_t := 0.0
var proj_telegraph := 0.0
var proj_owner_is_player := false

var _player: Node2D = null
var arena_left := 300.0
var arena_right := 900.0


func setup(at: Vector2, left_x: float, right_x: float) -> void:
	position = at
	anchor = at
	arena_left = left_x
	arena_right = right_x
	z_index = 18


func watch(p: Node2D) -> void:
	_player = p


func _physics_process(delta: float) -> void:
	if K.frozen:
		return
	var ms := delta * 1000.0
	if flash_ms > 0.0:
		flash_ms = maxf(0.0, flash_ms - ms)
	if crack_flash_ms > 0.0:
		crack_flash_ms = maxf(0.0, crack_flash_ms - ms)
	if proj_alive:
		_tick_projectile(delta)

	if state == "dead" or state == "script":
		_tick_script(ms)
		queue_redraw()
		return

	state_ms += ms
	if state == "idle":
		cadence_t += ms
	match state:
		"idle":
			if _player and cadence_t >= _cadence():
				_decide()
		"telegraph":
			if state_ms >= float(strike.get("telegraph", 350)):
				if strike_key == "ring_return":
					_launch_ring_return()
				state = "active"
				state_ms = 0.0
		"active":
			if state_ms >= float(strike.get("active", 100)):
				state = "recovery"
				state_ms = 0.0
		"recovery":
			if state_ms >= float(strike.get("recovery", 133)):
				# the whiff derivation: the active window completed with no contact
				if strike_key == "sweep" and not contact_published and phase == "LIE_WHOLE":
					whiffs += 1
					crack_stage = clampi(whiffs, 0, 3)
					if whiffs >= K.CRACK_WHIFFS_REQUIRED and not cracked_once:
						_begin_crack()
						return
				state = "idle"
				state_ms = 0.0
				cadence_t = 0.0
		"stagger":
			if state_ms >= K.BOSS_COUNTER_STAGGER_MS:
				state = "idle"
				state_ms = 0.0
				cadence_t = 0.0
		"crack":
			if state_ms >= K.CRACK_BEAT_MS:
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
	if dist > 56.0:
		_begin_ring_return()
		return
	# the four-cycle: 0 sweep, 1 lifted, 2 sweep, 3 thrust (TR-GBF-010)
	var order := ["sweep", "lifted", "sweep", "thrust"]
	var idx := cycle % 4
	var picked := ""
	for i in 4:
		var cand: String = order[(idx + i) % 4]
		var d: Dictionary = K.BOSS_STRIKES[cand]
		if dist <= float(d["reach"]):
			picked = cand
			idx = (idx + i) % 4
			break
	if picked == "":
		_begin_ring_return()
		return
	cycle = idx + 1
	_begin_strike(picked)


func _begin_strike(key: String) -> void:
	strike_key = key
	strike = K.BOSS_STRIKES[key]
	state = "telegraph"
	state_ms = 0.0
	strike_id += 1
	hit_done = false
	contact_published = false


func _begin_ring_return() -> void:
	strike_key = "ring_return"
	strike = {"name": "ring return", "power": 2, "telegraph": K.RING_RETURN["telegraph"],
		"active": 0, "recovery": 250, "reach": 0.0, "clashable": false}
	state = "telegraph"
	state_ms = 0.0
	hit_done = true
	contact_published = false
	proj_telegraph = 1.0


func _launch_ring_return() -> void:
	# the ring launches down the straight line to the player's published position
	proj_alive = true
	proj_owner_is_player = false
	proj_pos = position + Vector2(0, -26)
	proj_t = 0.0
	var target := _player.position + Vector2(0, -22) if _player else position + Vector2(facing * 100, -26)
	proj_vel = (target - proj_pos).normalized() * float(K.RING_RETURN["speed"])


func _begin_crack() -> void:
	cracked_once = true
	phase = "LIE_CRACKED"
	hp_floor = 0.0                      # the floor release, at the beat's first tick
	state = "crack"
	state_ms = 0.0
	crack_stage = 3
	_do_flash()


func _do_flash() -> void:
	# the flash law: two flashes from any source >= FLASH_MIN_INTERVAL_MS apart
	var now := Time.get_ticks_msec()
	if float(now - last_flash_ms) >= K.FLASH_MIN_INTERVAL_MS:
		last_flash_ms = float(now)
		crack_flash_ms = 90.0


func _tick_projectile(delta: float) -> void:
	proj_t += delta * 1000.0
	proj_pos += proj_vel * delta
	if proj_t >= float(K.RING_RETURN["lifetime"]):
		proj_alive = false
	if proj_pos.x < arena_left or proj_pos.x > arena_right:
		proj_alive = false


func _tick_script(ms: float) -> void:
	if state != "script":
		return
	script_t += ms
	if script_t < K.RECOGNITION_BEAT_MS:
		script_stage = "recognition"
	elif script_t < K.RECOGNITION_BEAT_MS + K.DISSOLVE_MS:
		script_stage = "dissolve"
	else:
		script_stage = "done"


func script_done() -> bool:
	return state == "script" and script_t >= K.RECOGNITION_BEAT_MS + K.DISSOLVE_MS


# ── the read surface ────────────────────────────────────────────────────────
func is_dead() -> bool:
	return state == "dead"


func in_crack_beat() -> bool:
	return state == "crack"


func is_striking() -> bool:
	return state == "telegraph" or state == "active"


func active_hitbox() -> Rect2:
	if state != "active" or hit_done or strike_key == "ring_return":
		return Rect2()
	var reach := float(strike.get("reach", 40.0))
	var x := position.x + (6.0 if facing > 0 else -6.0 - reach)
	return Rect2(x, position.y - 44.0, reach, 38.0)


func current_strike() -> Dictionary:
	return strike


func strike_is_clashable() -> bool:
	return bool(strike.get("clashable", false))


func consume_strike() -> void:
	hit_done = true


func on_contact() -> void:
	# the publication is the contact: an i-framed hit is still a contact
	contact_published = true


func hurtbox() -> Rect2:
	return Rect2(position.x - 12.0, position.y - 48.0, 24.0, 48.0)


func take_damage(dmg: int) -> Dictionary:
	if state == "dead" or state == "script":
		return {"dealt": 0, "floor": true, "dead": false}
	var before := hp
	hp = maxf(hp_floor, hp - float(dmg))    # the lie's floor clamps the pool
	flash_ms = 90.0
	var dead_now := false
	if hp <= 0.0 and hp_floor <= 0.0:
		state = "script"
		script_t = 0.0
		script_stage = "recognition"
		dead_now = true
	return {"dealt": int(before - hp), "floor": hp <= hp_floor + 0.001, "dead": dead_now}


func stagger(ms: float) -> void:
	if state == "dead" or state == "script":
		return
	state = "stagger"
	state_ms = 0.0
	proj_alive = false


func projectile_active() -> bool:
	return proj_alive and not proj_owner_is_player


func projectile_rect() -> Rect2:
	return Rect2(proj_pos.x - 6.0, proj_pos.y - 6.0, 12.0, 12.0)


func consume_projectile() -> void:
	proj_alive = false


func deflect_projectile() -> void:
	if not proj_alive:
		return
	proj_owner_is_player = true
	proj_vel = -proj_vel.normalized() * float(K.RING_RETURN["deflect_speed"])
	proj_t = 0.0


func player_projectile_active() -> bool:
	return proj_alive and proj_owner_is_player


# ── draw ───────────────────────────────────────────────────────────────────
func _draw() -> void:
	var hb := hurtbox()
	var local := Rect2(hb.position - position, hb.size)
	var alpha := 1.0
	if state == "script" and script_stage == "dissolve":
		alpha = clampf(1.0 - (script_t - K.RECOGNITION_BEAT_MS) / float(K.DISSOLVE_MS), 0.0, 1.0)
	if state == "dead":
		alpha = 0.0

	# the halo: a thin ring above her head — the crack's canvas
	var halo_y := local.position.y - 12.0
	var halo_c := K.C_BONE
	halo_c.a = alpha * 0.85
	if state == "crack" or (phase == "LIE_CRACKED" and script_stage == ""):
		halo_c = K.C_BONE_DIM
		halo_y += 10.0    # the ring lowers
	draw_arc(Vector2(0, halo_y), 13.0, PI, TAU, 18, halo_c, 1.0)
	if crack_stage >= 1:
		draw_line(Vector2(-9, halo_y - 3), Vector2(-2, halo_y - 11), K.C_BONE, 1.0)
	if crack_stage >= 2:
		draw_line(Vector2(6, halo_y - 2), Vector2(11, halo_y - 9), K.C_BONE, 1.0)
	if crack_stage >= 3:
		# the break: the halo's gap + a shard fallen out of the ring
		draw_line(Vector2(0, halo_y - 13), Vector2(0, halo_y - 18), K.C_BONE, 1.0)
		draw_rect(Rect2(4, halo_y - 20, 3, 3), K.C_BONE)

	var body := local
	if state == "telegraph":
		body.position.x += 2.0 * facing
	if state == "active":
		body.position.x += 4.0 * facing

	var c := K.C_BONE
	if flash_ms > 0.0:
		c = Color(1, 1, 1, 1)
	if state == "telegraph" and int(state_ms / 80.0) % 2 == 0:
		c = Color(1, 1, 1, 1)
	if state == "stagger":
		c = Color(K.C_CYAN.r, K.C_CYAN.g, K.C_CYAN.b, 0.8)
	c.a = alpha
	draw_rect(body, c)
	draw_rect(body, Color(0, 0, 0, 0.5), false, 1.0)

	# the hands: clasped at rest, parted for the thrust
	var hand_y := body.position.y + 20.0
	var gap := 1.0 if strike_key != "thrust" else 5.0
	draw_rect(Rect2(body.position.x + body.size.x * 0.5 - gap - 3.0, hand_y, 3, 5), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(body.position.x + body.size.x * 0.5 + gap, hand_y, 3, 5), Color(0, 0, 0, 0.55))

	if state == "active" and strike_key != "ring_return":
		var hbx0 := active_hitbox()
		var hbx := Rect2(hbx0.position - position, hbx0.size)
		draw_rect(hbx, Color(K.C_AMBER.r, K.C_AMBER.g, K.C_AMBER.b, 0.20))
		draw_rect(Rect2(hbx.position.x, hbx.position.y + 14.0, hbx.size.x, 2.0), K.C_AMBER)

	if state == "crack" or state == "script":
		# the stillness: a value-only wash on the floor, no glow, no pulse
		draw_rect(Rect2(-40, -2, 80, 2), Color(K.C_BONE.r, K.C_BONE.g, K.C_BONE.b, 0.35))

	if proj_alive:
		var pc := K.C_CYAN if proj_owner_is_player else K.C_BONE
		var pp := proj_pos - position
		draw_arc(pp, 6.0, 0.0, TAU, 14, pc, 1.5)
