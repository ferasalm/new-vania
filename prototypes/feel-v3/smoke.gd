# PROTOTYPE - NOT FOR PRODUCTION
# The self-test. Plays the game with pretend key presses and checks the numbers.
# Run: godot --headless --path prototypes/feel-v3 res://smoke.tscn
# With "-- shots" after the command (and no --headless) it also saves screenshots.
extends Node

var main: Node
var passed := 0
var failed := 0
var shots := false


func _ready() -> void:
	shots = OS.get_cmdline_user_args().has("shots")
	G.peace = true
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _run()
	print("SMOKE %s  passed=%d failed=%d" % ["PASS" if failed == 0 else "FAIL", passed, failed])
	get_tree().quit(0 if failed == 0 else 1)


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("%s  %s  (%s)" % ["ok  " if ok else "FAIL", name, detail])


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _tap(action: String, hold: int) -> void:
	Input.action_press(action)
	await _frames(hold)
	Input.action_release(action)


func _shot(name: String) -> void:
	if not shots:
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/%s.png" % name))


func _jump_height(hold: int) -> float:
	var p: CharacterBody2D = main.player
	var y0 := p.global_position.y
	var top := y0
	Input.action_press("jump")
	for i in 70:
		if i == hold:
			Input.action_release("jump")
		await get_tree().physics_frame
		top = minf(top, p.global_position.y)
	Input.action_release("jump")
	return y0 - top


func _run() -> void:
	await _frames(40)
	var p: CharacterBody2D = main.player
	_check("stands on the floor", p.is_on_floor(), "y=%.0f" % p.global_position.y)
	_check("sounds loaded", Sfx.missing.is_empty() and Sfx.count("sfx") >= 11 and Sfx.count("music") >= 2,
		"sfx=%d music=%d missing=%s" % [Sfx.count("sfx"), Sfx.count("music"), str(Sfx.missing)])
	var few: Array = []
	for n in ["hit", "hurt", "backdash", "swing", "music_room"]:
		if not Sfx.ev.has(n) or Sfx.ev[n]["options"].size() < 2:
			few.append(n)
	_check("the disliked sounds have other options to pick", few.is_empty(), "too few: %s" % str(few))
	await _shot("1_start")

	var x0 := p.global_position.x
	await _tap("right", 60)
	var dx := p.global_position.x - x0
	_check("run speed", absf(dx - T.v("run_speed")) < T.v("run_speed") * 0.1, "moved %.0f px in 1 s" % dx)
	await _shot("2_run")
	await _frames(3)
	var x1 := p.global_position.x
	await _frames(10)
	_check("stops at once", absf(p.global_position.x - x1) < 1.0, "drift %.1f px" % (p.global_position.x - x1))

	var full := await _jump_height(60)
	await _frames(20)
	var hop := await _jump_height(3)
	await _frames(20)
	_check("full jump height", full > 45.0 and full < 80.0, "%.0f px" % full)
	_check("tap is a short hop", hop < full * 0.7 and hop > 6.0, "%.0f px vs %.0f px" % [hop, full])

	x0 = p.global_position.x
	await _tap("backdash", 2)
	await _frames(30)
	var back := x0 - p.global_position.x
	_check("backdash moves her backwards", back > 25.0 and back < 90.0, "%.0f px" % back)
	_check("no knockdown state exists", not ("knockdown" in ["move", "attack", "backdash", "hurt", "dead"]), "states: move attack backdash hurt dead")

	# fight: stand next to the first hound and swing until it dies
	var hound: Node2D = null
	for en in main.enemies:
		if en.kind == "hound":
			hound = en
			break
	_check("a hound exists", hound != null, "")
	if hound != null:
		p.global_position = hound.global_position + Vector2(-30, 0)
		p.facing = 1
		await _frames(4)
		var hp0: float = hound.hp
		var swing_frames := int(T.v("attack_time") * 60.0) + 4
		await _tap("attack", 2)
		await _frames(6)
		await _shot("3_attack")
		await _frames(swing_frames - 6)
		var hit_once: bool = (not is_instance_valid(hound)) or hound.hp < hp0
		_check("a swing hurts the hound", hit_once, "hp %.0f -> %s" % [hp0, str(hound.hp) if is_instance_valid(hound) else "dead"])
		var swings := 1
		while is_instance_valid(hound) and swings < 8:
			p.global_position = hound.global_position + Vector2(-30, 0)
			p.facing = 1
			await _tap("attack" if swings % 2 == 0 else "attack2", 2)
			await _frames(swing_frames)
			swings += 1
		_check("the hound dies in 3 swings", not is_instance_valid(hound) and swings == 3, "swings=%d kills=%d" % [swings, main.kills])

	# air attack: jump, swing in the air
	Input.action_press("jump")
	await _frames(8)
	Input.action_release("jump")
	await _tap("attack", 2)
	await _frames(2)
	_check("can attack in the air", p.state == "attack" and not p.is_on_floor(), "state=%s" % p.state)
	await _frames(50)

	# getting hit: a flinch, never a knockdown, then control comes back
	G.peace = false
	var hp_before: float = p.hp
	p.invuln = 0.0
	p.take_hit(8.0, p.global_position.x + 10.0)
	_check("a hit costs health and flinches", p.hp < hp_before and p.state == "hurt", "hp %.0f -> %.0f" % [hp_before, p.hp])
	await _frames(int(T.v("hurt_time") * 60.0) + 4)
	_check("control returns after the flinch", p.state == "move", "state=%s after %.2f s" % [p.state, T.v("hurt_time")])
	G.peace = true

	# ---- stage 1b: crouch, two attack looks, the three bars, the special ----
	var swing_n := int(T.v("attack_time") * 60.0) + 6
	await _frames(40)
	Input.action_press("down")
	await _frames(4)
	_check("Down crouches and makes her shorter", p.state == "crouch" and is_equal_approx(p.body_rect().size.y, T.v("crouch_height")),
		"state=%s height=%.0f" % [p.state, p.body_rect().size.y])
	await _shot("8_crouch")
	var cx := p.global_position.x
	await _tap("right", 10)
	_check("she does not walk while crouching", absf(p.global_position.x - cx) < 1.0, "moved %.1f px" % (p.global_position.x - cx))
	await _tap("attack", 2)
	await _frames(6)
	_check("crouch attack is a low swing with its own animation", p.state == "attack" and p._spr.animation == "crouchatk" and p.attack_rect().position.y > p.global_position.y - 30.0,
		"anim=%s" % p._spr.animation)
	await _shot("9_crouch_attack")
	await _frames(swing_n)
	_check("she stays crouched after the low swing", p.state == "crouch", "state=%s" % p.state)
	Input.action_release("down")
	await _frames(4)
	_check("letting go of Down stands her up", p.state == "move", "state=%s" % p.state)

	await _frames(150)
	var e0: float = p.energy
	await _tap("attack", 2)
	await _frames(3)
	var anim_j := String(p._spr.animation)
	_check("an attack spends Energy", is_equal_approx(e0 - p.energy, T.v("attack_energy")), "%.0f -> %.0f" % [e0, p.energy])
	await _frames(swing_n)
	await _tap("attack2", 2)
	await _frames(8)
	var anim_i := String(p._spr.animation)
	await _shot("10_attack_i")
	_check("the J and I attacks use different animations", anim_j == "attack" and anim_i == "attack2", "J=%s I=%s" % [anim_j, anim_i])
	await _frames(swing_n)
	await _frames(int((T.v("energy_wait") + T.v("energy_max") / T.v("energy_refill")) * 60.0) + 10)
	_check("Energy refills by itself", is_equal_approx(p.energy, T.v("energy_max")), "energy=%.0f" % p.energy)
	e0 = p.energy
	await _tap("backdash", 2)
	await _frames(30)
	_check("a backdash spends Energy", e0 - p.energy > 0.0 or T.v("backdash_energy") == 0.0, "%.0f -> %.0f" % [e0, p.energy])
	p.energy = 0.0
	p._energy_wait = 5.0
	await _tap("attack", 2)
	await _frames(2)
	_check("no Energy, no attack", p.state == "move", "state=%s" % p.state)
	p._energy_wait = 0.0
	await _frames(150)

	# the special: Up + Attack throws a blade wave, costs MP, kills a hound, an orb gives MP back
	T.set_v("mp_drop_chance", 1.0)
	var target: Node2D = null
	for en in main.enemies:
		if en.kind == "hound":
			target = en
			break
	_check("another hound exists for the special", target != null, "")
	if target != null:
		p.global_position = target.global_position + Vector2(-70, 0)
		p.facing = 1
		await _frames(4)
		var mp0: float = p.mp
		var kills0: int = main.kills
		Input.action_press("up")
		await _tap("attack", 2)
		Input.action_release("up")
		await _frames(int(T.v("special_time") * 0.3 * 60.0) + 3)
		_check("Up + Attack throws a blade wave and spends MP", main.waves.size() == 1 and is_equal_approx(mp0 - p.mp, T.v("special_cost")),
			"waves=%d mp %.0f -> %.0f" % [main.waves.size(), mp0, p.mp])
		await _shot("11_special")
		await _frames(50)
		_check("the blade wave defeats the hound", main.kills == kills0 + 1, "kills %d -> %d" % [kills0, main.kills])
		var mp1: float = p.mp
		await _frames(90)
		_check("a blue orb gives MP back", p.mp > mp1 and main.orbs.is_empty(), "mp %.0f -> %.0f" % [mp1, p.mp])
	p.mp = 0.0
	Input.action_press("up")
	await _tap("attack", 2)
	Input.action_release("up")
	await _frames(3)
	_check("with no MP, Up + Attack is a normal swing", p.state == "attack" and p._attack_kind == "stand" and main.waves.is_empty(), "kind=%s" % p._attack_kind)
	await _frames(swing_n)
	p.mp = T.v("mp_max")
	T.reset()

	var bad: Array = []
	for key in T.data:
		var d: Dictionary = T.data[key]
		if String(d.get("label", "")) == "" or String(d.get("help", "")) == "" or float(d["value"]) < float(d["min"]) or float(d["value"]) > float(d["max"]):
			bad.append(key)
	_check("every number has a slider with a label and a help line", bad.is_empty() and T.data.has("energy_max") and T.data.has("special_cost") and T.data.has("crouch_height"),
		"%d sliders, bad: %s" % [T.data.size(), str(bad)])
	var loud: Array = []
	for n in ["special", "pickup", "no_energy"]:
		if not Sfx.ev.has(n) or Sfx.ev[n]["options"].size() < 2:
			loud.append(n)
	_check("the new sounds have options to pick", loud.is_empty(), "problems: %s" % str(loud))

	# ledge: jump onto the first thin platform from below
	p.global_position = Vector2(14 * 16, 12 * 16 + 16)
	await _frames(6)
	await _jump_height(60)
	await _frames(10)
	_check("lands on a ledge from below", p.is_on_floor() and p.global_position.y < 11 * 16 + 2, "y=%.0f" % p.global_position.y)
	await _shot("4_ledge")
	Input.action_press("down")
	await _tap("jump", 2)
	await _frames(30)
	Input.action_release("down")
	_check("Down + Jump drops through", p.global_position.y > 12 * 16, "y=%.0f" % p.global_position.y)

	# door
	p.global_position = Vector2(60 * 16, 13 * 16)
	await _frames(5)
	await _tap("right", 50)
	await _frames(40)
	_check("the door leads to room 2", main.room_name == "room2", "room=%s" % main.room_name)
	await _frames(20)
	await _shot("5_room2")
	_check("room 2 has enemies", main.enemies.size() >= 3, "count=%d" % main.enemies.size())
	if shots:
		main.panel._root.visible = true
		await _frames(3)
		await _shot("6_panel_feel")
		main.panel._page(1)
		await _frames(3)
		await _shot("7_panel_sounds")
