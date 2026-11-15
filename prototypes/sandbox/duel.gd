# PROTOTYPE - NOT FOR PRODUCTION
# SCENE 1 — THE DUEL RANGE. The combat feel with the landed numbers:
#   light 2 / heavy 4 · counter 3 or 6 (1.5x) · knockdown 1200 ms on power >= 2 ·
#   floating numbers 700 ms world-time · the 20-segment bone bar, no red fill.
extends Node2D

const PLAYER := preload("res://player.gd")
const ENEMY := preload("res://enemy.gd")
const HPBAR := preload("res://ui_hp_bar.gd")
const DMG := preload("res://ui_dmg.gd")
const OFFLINE := preload("res://offline.gd")
const BG := preload("res://bg.gd")

const FLOOR_Y := 420.0

var player
var enemies: Array = []
var solids: Array = []
var dmg
var bar
var world_ms := 0.0
var hitstop_ms := 0.0
var dead := false
var offline = null
var log_lines: Array = []
var stamp := ""
var stamp_ms := 0.0
var award_total := 0
var kills := 0
var hint_ms := 0.0


func _ready() -> void:
	K.frozen = false
	solids = [
		Rect2(0, FLOOR_Y, 960, 120),
		Rect2(-20, 0, 20, 540),
		Rect2(960, 0, 20, 540),
	]
	var bg = BG.new()
	bg.mode = "duel"
	add_child(bg)
	bg.z_index = -1000
	player = PLAYER.new()
	add_child(player)
	player.solids = solids
	player.position = Vector2(200, FLOOR_Y)
	player.z_index = -5

	for i in 3:
		var e = ENEMY.new()
		add_child(e)
		e.setup(i, Vector2(520 + i * 150, FLOOR_Y))
		e.watch(player)
		e.z_index = -6
		enemies.append(e)

	dmg = DMG.new()
	add_child(dmg)
	dmg.z_index = 6

	bar = HPBAR.new()
	add_child(bar)
	bar.position = Vector2(40, 70)
	bar.label = "CHASSIS"
	bar.z_index = 1

	stamp = K.pending_stamp
	stamp_ms = 1400.0 if stamp != "" else 0.0
	K.pending_stamp = ""


func _physics_process(delta: float) -> void:
	if hitstop_ms > 0.0:
		hitstop_ms -= delta * 1000.0
		if hitstop_ms <= 0.0:
			K.frozen = false
	var wd := 0.0 if K.frozen else delta * 1000.0
	world_ms += wd
	dmg.step(wd)
	if stamp_ms > 0.0:
		stamp_ms -= delta * 1000.0
	if hint_ms > 0.0:
		hint_ms -= delta * 1000.0
	bar.hp = player.hp
	bar.hp_max = player.hp_max
	if not dead:
		_resolve()
		if player.is_dead():
			_die("FAULT: THE DUMMIES · ENEMY_STRIKE · TICK %d" % int(world_ms / 16.67))
	queue_redraw()


func _resolve() -> void:
	# player -> enemy (one hit per strike id)
	if player.attack_active() and not player.hit_done:
		var hb: Rect2 = player.hitbox()
		for e in enemies:
			if e.is_dead():
				continue
			if e.hurtbox().intersects(hb):
				var d: int = player.attack_raw
				var was_dead: bool = e.take_damage(d)
				player.consume_strike()
				dmg.spawn(Vector2(e.position.x, e.position.y - 54.0), str(d), K.C_AMBER, 17)
				_hitstop(K.HITSTOP_HIT_MS)
				if was_dead:
					_on_enemy_death(e)
				break

	# enemy -> player (the clash, then the plain hit)
	for e in enemies:
		if e.is_dead():
			continue
		var ehb: Rect2 = e.active_hitbox()
		if ehb.size == Vector2.ZERO:
			continue
		if not ehb.intersects(player.hurtbox()):
			continue
		var p: int = e.power
		if player.is_countering() and not player.counter_done:
			var out: int = player.counter_value()
			player.counter_done = true
			e.consume_strike()
			var was_dead: bool = e.take_damage(out)
			if not was_dead:
				e.stagger(K.BOSS_COUNTER_STAGGER_MS)
			dmg.spawn(Vector2(e.position.x, e.position.y - 58.0), str(out), K.C_AMBER, 21)
			_hitstop(K.HITSTOP_CLASH_MS)
			if was_dead:
				_on_enemy_death(e)
		else:
			var took: bool = player.take_hit(p, e.position.x, K.strike_dmg(p))
			e.consume_strike()
			if took:
				dmg.spawn(Vector2(player.position.x, player.position.y - 52.0),
					str(K.strike_dmg(p)), K.C_BONE, 16)
				_hitstop(K.HITSTOP_HIT_MS)
				if K.knocks_down(p):
					_log("KNOCKDOWN  %d ms" % K.KNOCKDOWN_TOTAL_MS)


func _on_enemy_death(e) -> void:
	kills += 1
	award_total += e.award
	K.training_data += e.award
	_log("%s DESTROYED   +%d" % [e.tier_name, e.award])
	dmg.spawn(Vector2(e.position.x, e.position.y - 78.0), "+%d" % e.award, K.C_AMBER, 15)


func _hitstop(ms: float) -> void:
	hitstop_ms = ms
	K.frozen = true


func _log(t: String) -> void:
	log_lines.push_front({"text": t, "t": 2600.0})
	if log_lines.size() > 5:
		log_lines.pop_back()


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
			K.pending_stamp = "DESIGNATION " + K.designation_text(K.designations)
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
	if dead:
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
		KEY_ESCAPE:
			get_tree().change_scene_to_file("res://menu.tscn")


# ── the frame ───────────────────────────────────────────────────────────────
func _draw() -> void:
	# the HUD band behind the controls
	draw_rect(Rect2(0, 470, 960, 70), Color(K.C_BG.r, K.C_BG.g, K.C_BG.b, 0.86))
	draw_rect(Rect2(0, 470, 960, 1), Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.2))

	_text("THE DUEL RANGE", 40, 26, 15, K.C_BONE)
	_text("damage lands · numbers print · the bar loses length", 40, 40, 10, K.C_BONE_DIM)

	# the log (top right, under the run totals)
	var y := 66.0
	for l in log_lines:
		l["t"] -= 16.6
		var a: float = clampf(l["t"] / 700.0, 0.0, 1.0)
		var c := K.C_AMBER
		c.a = a
		_text(l["text"], 920.0 - ThemeDB.fallback_font.get_string_size(l["text"], 0, -1, 11).x, y, 11, c)
		y += 16.0
	log_lines = log_lines.filter(func(l): return l["t"] > 0.0)

	_text("TRAINING DATA %03d" % K.training_data, 792, 26, 11, K.C_BONE_DIM)
	_text("KILLS %d" % kills, 792, 42, 11, K.C_BONE_DIM)

	if stamp_ms > 0.0:
		var a2: float = clampf(stamp_ms / 400.0, 0.0, 1.0)
		var c2 := K.C_AMBER
		c2.a = a2
		_center(stamp, 300, 22, c2)

	# the controls, on screen
	var f1 := "WASD / ARROWS  MOVE      SPACE  JUMP      SHIFT  DASH"
	var f2 := "J  LIGHT (2)      K  HEAVY (4)      L  COUNTER (3 — hold K in the window for 6)"
	var f3 := "the counter's window is 300 ms: open it as the strike lands. a heavy hit knocks you down for 1200 ms."
	_center(f1, 496, 11, K.C_BONE_DIM)
	_center(f2, 512, 11, K.C_BONE)
	_center(f3, 528, 10, Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.8))


func _text(t: String, x: float, y: float, sz: int, c: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, c)


func _center(t: String, y: float, sz: int, c: Color) -> void:
	var w := ThemeDB.fallback_font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	_text(t, 480.0 - w * 0.5, y, sz, c)
