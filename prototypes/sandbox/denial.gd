# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its landed numbers are played, not read?
# Date: 2026-11-16
# SCENE 3 — THE DENIAL LIE. One boss, one arena, the ring is her weapon.
#   hp 60, the phase-1 floor 20: damage lands, the numbers print, the bar STALLS
#   at 20/60 = 1/3. Three unanswered ring sweeps crack the halo; the 2000 ms crack
#   beat releases the floor and the bar finally moves. No HUD counter, no text cue:
#   the halo's hairlines and the bar's stall are the whole teach.
extends Node2D

const PLAYER := preload("res://player.gd")
const BOSS := preload("res://boss.gd")
const HPBAR := preload("res://ui_hp_bar.gd")
const DMG := preload("res://ui_dmg.gd")
const OFFLINE := preload("res://offline.gd")
const BG := preload("res://bg.gd")

const FLOOR_Y := 440.0
const ARENA_L := 40.0
const ARENA_R := 920.0

var player
var boss
var solids: Array = []
var dmg
var bar
var world_ms := 0.0
var hitstop_ms := 0.0
var dead := false
var offline = null
var done := false
var debug := false
var log_lines: Array = []
var stamp := ""
var stamp_ms := 0.0


func _ready() -> void:
	K.frozen = false
	solids = [
		Rect2(0, FLOOR_Y, 960, 100),
		Rect2(-20, 0, 20, 540),
		Rect2(960, 0, 20, 540),
	]
	var bg = BG.new()
	bg.mode = "denial"
	add_child(bg)
	bg.z_index = -1000
	player = PLAYER.new()
	add_child(player)
	player.solids = solids
	player.position = Vector2(240, FLOOR_Y)
	player.z_index = -5

	boss = BOSS.new()
	add_child(boss)
	boss.setup(Vector2(700, FLOOR_Y), ARENA_L, ARENA_R)
	boss.watch(player)
	boss.z_index = -4

	dmg = DMG.new()
	add_child(dmg)
	dmg.z_index = 6

	bar = HPBAR.new()
	add_child(bar)
	bar.position = Vector2(40, 70)
	bar.label = "CHASSIS"
	bar.z_index = 1

	stamp = K.pending_stamp
	stamp_ms = 1600.0 if stamp != "" else 0.0
	K.pending_stamp = ""


func _physics_process(delta: float) -> void:
	if hitstop_ms > 0.0:
		hitstop_ms -= delta * 1000.0
		if hitstop_ms <= 0.0:
			K.frozen = false
	var wd := 0.0 if K.frozen else delta * 1000.0
	world_ms += wd
	dmg.step(wd)
	_tick_logs(wd)
	if stamp_ms > 0.0:
		stamp_ms -= delta * 1000.0
	bar.hp = player.hp
	bar.hp_max = player.hp_max

	if not dead and not done:
		_resolve()
		if player.is_dead():
			_die("FAULT: %s · ENEMY_STRIKE · TICK %d" % [
				boss.current_strike().get("name", "the ring").to_upper(), int(world_ms / 16.67)])
		if boss.script_done():
			done = true
			player.locked = true
	queue_redraw()


func _resolve() -> void:
	# player -> boss (the numbers print; the floor clamps the pool)
	if player.attack_active() and not player.hit_done:
		if player.hitbox().intersects(boss.hurtbox()):
			var raw: int = player.attack_raw
			var res: Dictionary = boss.take_damage(raw)
			player.consume_strike()
			dmg.spawn(Vector2(boss.position.x, boss.position.y - 60.0), str(raw), K.C_AMBER, 17)
			_hitstop(K.HITSTOP_HIT_MS)
			if res["dead"]:
				_log("the lie is broken")

	# boss -> player
	var hb: Rect2 = boss.active_hitbox()
	if hb.size != Vector2.ZERO and hb.intersects(player.hurtbox()):
		var st: Dictionary = boss.current_strike()
		var p: int = int(st.get("power", 1))
		boss.on_contact()          # the publication is the contact, even if i-framed
		boss.consume_strike()
		if player.is_countering() and boss.strike_is_clashable():
			var out: int = player.counter_value()
			var res3: Dictionary = boss.take_damage(out)
			if not res3["dead"]:
				boss.stagger(K.BOSS_COUNTER_STAGGER_MS)
			dmg.spawn(Vector2(boss.position.x, boss.position.y - 64.0), str(out), K.C_AMBER, 21)
			_hitstop(K.HITSTOP_CLASH_MS)
			if res3["dead"]:
				_log("the lie is broken")
		else:
			var took: bool = player.take_hit(p, boss.position.x, K.strike_dmg(p))
			if took:
				dmg.spawn(Vector2(player.position.x, player.position.y - 52.0),
					str(K.strike_dmg(p)), K.C_BONE, 16)
				_hitstop(K.HITSTOP_HIT_MS)

	# the ring return: deflect it back (L), or wear it
	if boss.projectile_active() and boss.projectile_rect().intersects(player.hurtbox()):
		if player.is_countering():
			boss.deflect_projectile()
			_hitstop(K.HITSTOP_DEFLECT_MS)
		else:
			var took2: bool = player.take_hit(2, boss.projectile_rect().get_center().x, K.RING_RETURN["damage"])
			boss.consume_projectile()
			if took2:
				dmg.spawn(Vector2(player.position.x, player.position.y - 52.0),
					str(K.RING_RETURN["damage"]), K.C_BONE, 16)
				_hitstop(K.HITSTOP_HIT_MS)

	if boss.player_projectile_active() and boss.projectile_rect().intersects(boss.hurtbox()):
		var res2: Dictionary = boss.take_damage(int(K.RING_RETURN["damage"]))
		boss.consume_projectile()
		dmg.spawn(Vector2(boss.position.x, boss.position.y - 60.0),
			str(K.RING_RETURN["damage"]), K.C_CYAN, 17)
		_hitstop(K.HITSTOP_DEFLECT_MS)
		if res2["dead"]:
			_log("her own ring")


func _hitstop(ms: float) -> void:
	hitstop_ms = ms
	K.frozen = true


func _log(t: String) -> void:
	log_lines.push_front({"text": t, "t": 2600.0})
	if log_lines.size() > 4:
		log_lines.pop_back()


func _tick_logs(ms: float) -> void:
	for l in log_lines:
		l["t"] -= ms
	log_lines = log_lines.filter(func(l): return l["t"] > 0.0)


func _die(cause: String) -> void:
	if dead:
		return
	dead = true
	K.frozen = false
	player.locked = true
	var bb := BackBufferCopy.new()
	bb.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(bb)
	offline = OFFLINE.new()
	offline.cause = cause
	offline.has_module = K.restore_modules > 0
	add_child(offline)
	offline.chosen.connect(_on_choice)


func _on_choice(choice: String) -> void:
	match choice:
		"module":
			K.restore_modules -= 1
			K.designations += 1
			stamp = "DESIGNATION " + K.designation_text(K.designations)
			stamp_ms = 1600.0
			K.pending_stamp = ""
			player.revive(K.RESTORE_MODULE_HEAL_PCT)
			dead = false
			offline.queue_free()
			offline = null
			_log("the fight continues mid-phase")
		"reconstruct":
			K.designations += 1
			K.pending_stamp = "DESIGNATION " + K.designation_text(K.designations)
			get_tree().reload_current_scene()
		"quit":
			get_tree().change_scene_to_file("res://menu.tscn")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE:
			get_tree().change_scene_to_file("res://menu.tscn")
		KEY_F1:
			debug = not debug
		KEY_J, KEY_K, KEY_L, KEY_SHIFT:
			if dead:
				return
			if done:
				get_tree().change_scene_to_file("res://menu.tscn")
				return
			match event.keycode:
				KEY_J:
					player.try_light()
				KEY_K:
					if player.is_countering():
						player.try_counter()
					else:
						player.try_heavy()
				KEY_L:
					player.try_counter()
				KEY_SHIFT:
					player.try_dash()
		KEY_ENTER:
			if done:
				get_tree().change_scene_to_file("res://menu.tscn")


# ── the frame ───────────────────────────────────────────────────────────────
func _draw() -> void:
	# the HUD band behind the controls
	draw_rect(Rect2(0, 470, 960, 70), Color(K.C_BG.r, K.C_BG.g, K.C_BG.b, 0.86))
	draw_rect(Rect2(0, 470, 960, 1), Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.2))

	_boss_bar()

	_text("DENIAL", 40, 26, 15, K.C_BONE)
	_text("the ring is her weapon", 40, 40, 10, K.C_BONE_DIM)

	var y := 92.0
	for l in log_lines:
		var a: float = clampf(l["t"] / 800.0, 0.0, 1.0)
		var c := K.C_BONE
		c.a = a
		_text(l["text"], 40, y, 11, c)
		y += 16.0

	if stamp_ms > 0.0:
		var a2: float = clampf(stamp_ms / 400.0, 0.0, 1.0)
		var c2 := K.C_AMBER
		c2.a = a2
		_center(stamp, 300, 24, c2)

	if done:
		_center("the room stays perfect. you are the one who changed.", 300, 16, K.C_BONE)
		_center("ENTER — back to the menu", 326, 11, K.C_BONE_DIM)
		return
	if dead:
		return

	if debug:
		var d1 := "whiffs %d / %d   phase %s   stage %d   floor %.0f   state %s" % [
			boss.whiffs, K.CRACK_WHIFFS_REQUIRED, boss.phase, boss.crack_stage,
			boss.hp_floor, boss.state]
		_text(d1, 40, 116, 10, K.C_CYAN)

	var f1 := "WASD / ARROWS  MOVE      SPACE  JUMP      SHIFT  DASH (140 ms i-frames)"
	var f2 := "J  LIGHT (2)      K  HEAVY (4)      L  COUNTER (3 — K in the window = 6) / DEFLECT THE RING"
	var f3 := "the wide sweep is unclashable: step out of it. three unanswered sweeps crack her halo."
	_center(f1, 496, 11, K.C_BONE_DIM)
	_center(f2, 512, 11, K.C_BONE)
	_center(f3, 528, 10, Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.85))


func _boss_bar() -> void:
	var bx := 300.0
	var by := 34.0
	var bw := 360.0
	var bh := 12.0
	var ratio := clampf(boss.hp / boss.hp_max, 0.0, 1.0)
	draw_rect(Rect2(bx - 2, by - 2, bw + 4, bh + 4), Color(0, 0, 0, 0.6))
	for i in int(K.HP_SEGMENTS):
		var w := bw / float(K.HP_SEGMENTS)
		var x := bx + i * w
		var on := float(i) < ratio * float(K.HP_SEGMENTS) - 0.0001
		draw_rect(Rect2(x, by, maxf(1.0, w - 1.5), bh), K.C_BONE if on else K.C_BG2)
	# the floor tick: 20/60 = 1/3. While the lie holds it is a bone rule; released, it dims.
	var fx := bx + bw * (float(K.BOSS_HP_FLOOR) / float(K.BOSS_HP_POOL))
	var fc := K.C_BONE if boss.phase == "LIE_WHOLE" else Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.35)
	draw_rect(Rect2(fx - 1, by - 5, 2, bh + 10), fc)
	_center("DENIAL   %d / %d" % [int(boss.hp), int(boss.hp_max)], by - 8, 10, K.C_BONE_DIM)


func _text(t: String, x: float, y: float, sz: int, c: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, c)


func _center(t: String, y: float, sz: int, c: Color) -> void:
	var w := ThemeDB.fallback_font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	_text(t, 480.0 - w * 0.5, y, sz, c)
