# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does committed SotN-weight combat (combo + clash + deflect) feel rewarding?
# Date: 2026-11-11

# Combat concept-test for "Five Errands for the Devil".
# Keyboard-first greybox arena. Everything drawn in code, all tunables in tunables.gd.
# PLAYTEST: arrows/AD move, SPACE jump, J or Z attack. Read README.md for the test protocol.

extends Node2D

var player: CharacterBody2D
var camera: Camera2D
var shake := 0.0
var in_hitstop := false
var dummies_downed := 0
var designation := 1  # death counter — PANDORA-001, 002, ...

# HUD
var hud: CanvasLayer
var hp_bar_bg: ColorRect
var hp_bar: ColorRect
var score_label: Label
var pop_label: Label
var desig_label: Label
var pop_t := 0.0

func _ready() -> void:
	_setup_input()
	var bg := ColorRect.new()
	bg.color = Color("0a1620")
	bg.size = Vector2(960, 540)
	bg.z_index = -10
	add_child(bg)

	player = preload("res://player.gd").new()
	player.main = self
	player.position = Vector2(200, Tunables.FLOOR_Y)
	add_child(player)

	_spawn_melee(620)
	_spawn_melee(820)
	var shooter := preload("res://enemy_shooter.gd").new()
	shooter.main = self
	shooter.position = Vector2(860, 300)
	add_child(shooter)

	camera = Camera2D.new()
	camera.position = Vector2(480, 270)
	camera.enabled = true
	add_child(camera)

	_build_hud()

func _setup_input() -> void:
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_action("attack", [KEY_J, KEY_Z])

func _add_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func _spawn_melee(x: float) -> void:
	var e := preload("res://enemy_melee.gd").new()
	e.main = self
	e.position = Vector2(x, Tunables.FLOOR_Y)
	add_child(e)

func _spawn_shooter() -> void:
	var s := preload("res://enemy_shooter.gd").new()
	s.main = self
	s.position = Vector2(randf_range(Tunables.ARENA_MIN_X + 60.0, Tunables.ARENA_MAX_X - 60.0), 300.0)
	add_child(s)

func spawn_orb(pos: Vector2, dir: Vector2) -> void:
	var orb := preload("res://projectile.gd").new()
	orb.main = self
	orb.position = pos
	orb.velocity = dir.normalized() * Tunables.ORB_SPEED
	add_child(orb)

func _process(delta: float) -> void:
	if shake > 0.0:
		shake = maxf(shake - 30.0 * delta, 0.0)
		camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	else:
		camera.offset = Vector2.ZERO
	if pop_t > 0.0:
		pop_t -= delta
		pop_label.modulate.a = clampf(pop_t / 0.5, 0.0, 1.0)
	hp_bar.size.x = 240.0 * clampf(player.hp / float(Tunables.PLAYER_HP), 0.0, 1.0)

func _draw() -> void:
	# floor strip
	draw_rect(Rect2(0, Tunables.FLOOR_Y, 960, 20), Color("1b2a33"))
	draw_rect(Rect2(0, Tunables.FLOOR_Y, 960, 3), Color("0d7b89"))

func hitstop(seconds: float) -> void:
	if in_hitstop:
		return
	in_hitstop = true
	Engine.time_scale = 0.05
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0
	in_hitstop = false

func do_shake(amount: float) -> void:
	shake = maxf(shake, amount)

func popup(text: String, color: Color) -> void:
	pop_label.text = text
	pop_label.modulate = color
	pop_label.modulate.a = 1.0
	pop_t = 0.8

func register_kill() -> void:
	dummies_downed += 1
	score_label.text = "DUMMIES DOWN: %d" % dummies_downed

func register_player_death() -> void:
	designation += 1
	desig_label.text = "DESIGNATION: PANDORA-%03d" % designation
	popup("REBUILT — MEMORY CACHED", Color("7fd6e8"))

func on_player_hurt() -> void:
	do_shake(Tunables.SHAKE_HURT)

func on_clash(kind: String) -> void:
	match kind:
		"strong":
			popup("COUNTER-CLASH! STAGGERED", Color("ffd27f"))
			do_shake(Tunables.SHAKE_CLASH)
			hitstop(Tunables.HITSTOP_CLASH)
		"even":
			popup("DOUBLE CLASH — LOCKED", Color("ffffff"))
			do_shake(Tunables.SHAKE_CLASH)
			hitstop(Tunables.HITSTOP_CLASH)
		"lose":
			popup("OUTMATCHED — STAGGERED", Color("ff6b6b"))
			do_shake(Tunables.SHAKE_CLASH)
			hitstop(Tunables.HITSTOP_CLASH)
		"deflect":
			popup("DEFLECTED", Color("7fd6e8"))
			hitstop(Tunables.HITSTOP_DEFLECT)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	hp_bar_bg = ColorRect.new()
	hp_bar_bg.position = Vector2(20, 20)
	hp_bar_bg.size = Vector2(240, 14)
	hp_bar_bg.color = Color("10222c")
	hud.add_child(hp_bar_bg)
	hp_bar = ColorRect.new()
	hp_bar.position = Vector2(20, 20)
	hp_bar.size = Vector2(240, 14)
	hp_bar.color = Color("0d7b89")
	hud.add_child(hp_bar)
	score_label = Label.new()
	score_label.position = Vector2(20, 44)
	score_label.text = "DUMMIES DOWN: 0"
	hud.add_child(score_label)
	desig_label = Label.new()
	desig_label.position = Vector2(20, 66)
	desig_label.text = "DESIGNATION: PANDORA-001"
	desig_label.modulate = Color("7fd6e8")
	hud.add_child(desig_label)
	var hint := Label.new()
	hint.position = Vector2(20, 496)
	hint.text = "AD / arrows move · SPACE jump · J or Z attack · attack during windup = counter-clash · attack2 (J J) wins light clashes"
	hint.modulate = Color("88a7b3")
	hud.add_child(hint)
	pop_label = Label.new()
	pop_label.position = Vector2(300, 110)
	pop_label.text = ""
	hud.add_child(pop_label)
