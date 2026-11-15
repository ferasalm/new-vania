# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# THE FIGHT FRAME — everything the rooms share.
#
#   · THE ONE BUTTON (feedback #5). One key. The press is classified against the
#     enemy's own clock, and the classification is IMMEDIATE — the punish lands on
#     the press, because the read is the skill:
#         on the telegraph's flash tail -> COUNTER (raw 4 x1.5 = 6, 800 ms stagger)
#         into a live swing             -> CLASH   (both stop, 90 ms, no damage)
#         anywhere else                 -> STRIKE  (raw 2, and you eat the swing)
#   · THE FALL RULE (feedback #6). No fall damage, ever. Below KILL_Y you fade and
#     return to the last safe ground. A pit is a route.
#   · NO LOCKS (feedback #7). This frame never locks the body. Only a boss door
#     seals, and that is the arena's business, not the frame's.
extends Node2D

const Assets = preload("res://assets.gd")
const PLAYER := preload("res://player.gd")
const DMG := preload("res://ui_dmg.gd")
const HPBAR := preload("res://ui_hp_bar.gd")
const WINDOWS := preload("res://ui_windows.gd")
const OFFLINE := preload("res://offline.gd")
const DOOR := preload("res://door.gd")
const HUD := preload("res://ui_hud.gd")

var player
var enemies: Array = []
var doors: Array = []
var hazards: Array = []       # {rect, cause} — the seam, and only things like the seam
var dmg
var bar
var windows
var hud
var hud_layer: CanvasLayer
var solids: Array = []

var world_ms := 0.0
var hitstop_ms := 0.0
var dead := false
var offline = null
var done := false
var log_lines: Array = []
var last_safe := Vector2.ZERO
var fall_count := 0
var stamp := ""
var stamp_ms := 0.0
var hud_title := ""
var hud_sub := ""
var debug := false
var t := 0.0


func _ready() -> void:
	K.frozen = false

	player = PLAYER.new()
	add_child(player)

	# the interface rides a CanvasLayer: a camera moves the room, never the HUD.
	# It exists before _build() so a room can hang its own bars on it.
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)

	_build()                      # the room: solids, backdrop, enemies, doors

	player.solids = solids
	var at := _spawn()
	player.position = at
	last_safe = at

	dmg = DMG.new()
	add_child(dmg)
	dmg.z_index = 40

	bar = HPBAR.new()
	hud_layer.add_child(bar)
	bar.position = Vector2(40, 70)
	bar.label = "CHASSIS"

	windows = WINDOWS.new()
	hud_layer.add_child(windows)
	windows.position = Vector2(480, 452)

	hud = HUD.new()
	hud.scene = self
	hud_layer.add_child(hud)

	stamp = K.pending_stamp
	stamp_ms = 1600.0 if stamp != "" else 0.0
	K.pending_stamp = ""


# ── the subclass hooks ──────────────────────────────────────────────────────
func _build() -> void:
	pass


func _spawn() -> Vector2:
	return Vector2(120, 420)


func _safe_here(_pos: Vector2) -> bool:
	return true


func _respawn_point() -> Vector2:
	return last_safe


func _death_cause() -> String:
	return "FAULT: UNRECORDED"


func _controls() -> Array:
	return [
		"WASD / ARROWS  MOVE      SPACE  JUMP      SHIFT  DASH      J  THE BUTTON      ESC  MENU",
		"J — TAP: STRIKE (2)      ON THE FLASH: COUNTER (6)      INTO THE SWING: CLASH",
		"",
	]


# ── the clock ───────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if hitstop_ms > 0.0:
		hitstop_ms -= delta * 1000.0
		if hitstop_ms <= 0.0:
			K.frozen = false
	var wd := 0.0 if K.frozen else delta * 1000.0
	world_ms += wd
	t += delta
	dmg.step(wd)
	_tick_logs(wd)
	if stamp_ms > 0.0:
		stamp_ms -= delta * 1000.0
	bar.hp = player.hp
	bar.hp_max = player.hp_max
	windows.set_threat(_threat())

	if dead:
		return

	_resolve()
	_update_safe()
	_check_falls()
	_check_doors()
	for hz in hazards:
		if player.hurtbox().intersects(hz["rect"]):
			_die(String(hz["cause"]))
			break
	if player.is_dead():
		_die(_death_cause())


func _update_safe() -> void:
	# A ground PROBE, not the player's own on_ground flag: the flag is one frame
	# stale relative to this call, and a stale true poisons the safe spot with the
	# position you are falling from. A hazard is never "safe" either — standing in
	# the seam must not become the spot a revive returns you to.
	if player.is_idle() and _grounded_now() and not _in_hazard():
		if _safe_here(player.position):
			last_safe = player.position


func _in_hazard() -> bool:
	var hb: Rect2 = player.hurtbox()
	for hz in hazards:
		if hb.intersects(hz["rect"]):
			return true
	return false


func _grounded_now() -> bool:
	var probe := Rect2(player.position.x - 10.0, player.position.y + 1.0, 20.0, 5.0)
	for r in solids:
		if probe.intersects(r):
			return true
	return false


func _check_falls() -> void:
	# feedback #6: a fall is a route. Fade, return, no damage, no death screen.
	if player.position.y > K.KILL_Y:
		fall_count += 1
		player.teleport(last_safe)
		player.fall_ms = K.FALL_FADE_MS
		_log("the floor gave you back")


func _check_doors() -> void:
	for d in doors:
		if not is_instance_valid(d) or d.sealed:
			continue
		if player.hurtbox().intersects(d.trigger_rect()) and d.armed:
			d.armed = false
			if d.target != "":
				get_tree().change_scene_to_file(d.target)
		elif not player.hurtbox().intersects(d.trigger_rect()):
			d.armed = true


# ── THE ONE BUTTON ──────────────────────────────────────────────────────────
func _threat() -> Dictionary:
	# the nearest committed enemy, with the clock the windows bar needs
	var best: Dictionary = {}
	var best_d := 1e9
	for e in enemies:
		if not is_instance_valid(e) or e.is_dead():
			continue
		var ph: String = e.strike_phase()
		if ph == "none":
			continue
		var d: float = absf(e.position.x - player.position.x)
		if d >= best_d:
			continue
		best_d = d
		var elapsed := 0.0
		if ph == "telegraph":
			elapsed = e.state_ms
		elif ph == "active":
			elapsed = e.telegraph_len() + e.state_ms
		best = {"enemy": e, "phase": ph, "t": elapsed,
			"telegraph": e.telegraph_len(), "active": e.active_len(),
			"name": e.strike_name(), "counterable": e.can_counter(),
			"clashable": e.clashable(), "dist": d,
			"remaining": e.telegraph_len() - e.state_ms if ph == "telegraph" else 0.0}
	return best


func _near_shard() -> Dictionary:
	for e in enemies:
		if not is_instance_valid(e) or not e.has_method("shard_rects"):
			continue
		for s in e.shard_rects():
			if bool(s["mine"]):
				continue
			var r: Rect2 = s["rect"]
			var d: float = absf(r.get_center().x - player.position.x)
			if d <= K.CLASH_REACH and absf(r.get_center().y - (player.position.y - 50.0)) < 90.0:
				return {"enemy": e, "idx": int(s["idx"]), "dist": d}
	return {}


func _on_press() -> void:
	if dead or done or player.is_dead():
		return
	# on the floor is on the floor: a knockdown is the 1200 ms the contracts
	# bought, and no press may cut it short
	if player.is_knocked_down():
		return

	# 1. a shard about to land: the same button deflects it
	var sh := _near_shard()
	if not sh.is_empty():
		player.do_clash()
		sh["enemy"].deflect_shard(int(sh["idx"]))
		windows.flash_outcome("CLASH")
		_hitstop(K.HITSTOP_DEFLECT_MS)
		return

	var th := _threat()
	if th.is_empty():
		player.do_strike()
		windows.flash_outcome("STRIKE", K.STRIKE_RAW)
		return

	var e = th["enemy"]

	# 2. the flash tail: COUNTER — the big punish, and it lands on the press
	if th["phase"] == "telegraph" and e.counter_open() and th["dist"] <= K.COUNTER_REACH:
		player.do_counter()
		var out: int = player.counter_value()
		var res: Dictionary = e.take_damage(out)
		if bool(res.get("dead", false)):
			_on_enemy_death(e)
		else:
			e.stagger(K.BOSS_COUNTER_STAGGER_MS)
		dmg.spawn(Vector2(e.position.x, e.position.y - 70.0), str(out), K.C_AMBER, 21)
		windows.flash_outcome("COUNTER", out)
		_hitstop(K.HITSTOP_CLASH_MS)
		_log("COUNTER  %d" % out)
		return

	# 3. into a live swing: CLASH — both stop, nobody bleeds
	if th["phase"] == "active" and th["dist"] <= K.CLASH_REACH and e.clashable():
		player.do_clash()
		e.consume_strike()
		windows.flash_outcome("CLASH")
		_hitstop(K.HITSTOP_CLASH_MS)
		Assets.fx_burst(self, player.position + Vector2(player.facing * 26.0, -60.0),
			"fx/spark", Assets.FX["spark"], 1.1)
		_log("CLASH")
		return

	# 4. everything else: a plain strike
	player.do_strike()
	windows.flash_outcome("STRIKE", K.STRIKE_RAW)


# ── the exchange ────────────────────────────────────────────────────────────
func _resolve() -> void:
	# player -> enemies
	if player.attack_active() and not player.hit_done:
		var hb: Rect2 = player.hitbox()
		for e in enemies:
			if not is_instance_valid(e) or e.is_dead():
				continue
			if not e.hurtbox().intersects(hb):
				continue
			var raw: int = K.STRIKE_RAW
			var res: Dictionary = e.take_damage(raw)
			player.consume_strike()
			dmg.spawn(Vector2(e.position.x, e.position.y - 64.0), str(raw), K.C_AMBER, 17)
			_hitstop(K.HITSTOP_HIT_MS)
			if bool(res.get("stored", false)):
				_log("STORED  %d" % int(raw))
			if bool(res.get("dead", false)):
				_on_enemy_death(e)
			break

	# player -> the mirror (a STRIKE breaks it; the counter is aimed at a telegraph,
	# and the mirror never telegraphs — it just hangs there and runs out)
	if player.attack_active() and not player.hit_done:
		var mb = _live_mirror()
		if mb != null and mb.hurtbox().intersects(player.hitbox()):
			player.consume_strike()
			mb.hit(K.STRIKE_RAW)
			dmg.spawn(Vector2(mb.position.x, mb.position.y - 96.0), str(K.STRIKE_RAW), K.C_ICE, 16)
			_hitstop(K.HITSTOP_HIT_MS)
			if mb.broke:
				_log("THE MIRROR BREAKS")

	# enemies -> player
	for e in enemies:
		if not is_instance_valid(e) or e.is_dead():
			continue
		var hb2: Rect2 = e.active_hitbox()
		if hb2.size == Vector2.ZERO:
			continue
		if not hb2.intersects(player.hurtbox()):
			continue
		var p: int = e.power()
		e.on_contact()
		e.consume_strike()
		var took: bool = player.take_hit(p, e.position.x, K.strike_dmg(p))
		if took:
			dmg.spawn(Vector2(player.position.x, player.position.y - 52.0),
				str(K.strike_dmg(p)), K.C_BONE, 16)
			_hitstop(K.HITSTOP_HIT_MS)
			if K.knocks_down(p):
				_log("KNOCKDOWN  %d ms" % K.KNOCKDOWN_TOTAL_MS)

	# her shards
	for e in enemies:
		if not is_instance_valid(e) or not e.has_method("shard_rects"):
			continue
		for s in e.shard_rects():
			if bool(s["mine"]):
				continue
			var r: Rect2 = s["rect"]
			if not r.intersects(player.hurtbox()):
				continue
			e.consume_shard(int(s["idx"]))
			var took2: bool = player.take_hit(2, r.get_center().x, int(K.SHARD["damage"]))
			if took2:
				dmg.spawn(Vector2(player.position.x, player.position.y - 52.0),
					str(int(K.SHARD["damage"])), K.C_BONE, 16)
				_hitstop(K.HITSTOP_HIT_MS)
			break


func _live_mirror():
	for e in enemies:
		if is_instance_valid(e) and e.has_method("mirror_node"):
			var m = e.mirror_node()
			if m != null and is_instance_valid(m) and m.alive:
				return m
	return null


func _on_enemy_death(e) -> void:
	var award := 0
	if e.get("award") != null:
		award = int(e.award)
	if award > 0:
		K.training_data += award
		_log("%s DESTROYED   +%d" % [String(e.tier_name), award])
		dmg.spawn(Vector2(e.position.x, e.position.y - 84.0), "+%d" % award, K.C_AMBER, 15)
	Assets.fx_burst(self, e.position + Vector2(0, -20), "fx/burst", Assets.FX["burst"], 1.6)


func _hitstop(ms: float) -> void:
	hitstop_ms = ms
	K.frozen = true


func _log(txt: String) -> void:
	log_lines.push_front({"text": txt, "t": 2600.0})
	if log_lines.size() > 5:
		log_lines.pop_back()


func _tick_logs(ms: float) -> void:
	for l in log_lines:
		l["t"] -= ms
	log_lines = log_lines.filter(func(l): return l["t"] > 0.0)


# ── death (the cache loop's surface, unchanged) ─────────────────────────────
func _die(cause: String) -> void:
	if dead:
		return
	dead = true
	K.frozen = false
	player.locked = true
	var bb := BackBufferCopy.new()
	bb.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	hud_layer.add_child(bb)
	offline = OFFLINE.new()
	offline.cause = cause
	offline.has_module = K.restore_modules > 0
	hud_layer.add_child(offline)
	offline.chosen.connect(_on_choice)


func _on_choice(choice: String) -> void:
	match choice:
		"module":
			K.restore_modules -= 1
			K.designations += 1
			stamp = "DESIGNATION " + K.designation_text(K.designations)
			stamp_ms = 1600.0
			K.pending_stamp = ""
			player.teleport(_respawn_point())
			player.revive(K.RESTORE_MODULE_HEAL_PCT)
			dead = false
			offline.queue_free()
			offline = null
			_log("REBOOT   half a bar   %d ms hum" % K.REVIVE_IFRAME_MS)
		"reconstruct":
			K.designations += 1
			K.pending_stamp = "DESIGNATION " + K.designation_text(K.designations)
			get_tree().reload_current_scene()
		"quit":
			get_tree().change_scene_to_file("res://menu.tscn")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://menu.tscn")
		return
	if event.keycode == KEY_F1:
		debug = not debug
		return
	if dead:
		return
	if done:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_tree().change_scene_to_file("res://menu.tscn")
		return
	match event.keycode:
		KEY_J:
			_on_press()
		KEY_SHIFT:
			player.try_dash()
