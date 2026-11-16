# PROTOTYPE - NOT FOR PRODUCTION
# The self-test. Plays the game with pretend key presses and checks the numbers.
# Run: godot --headless --path prototypes/feel-v3 res://smoke.tscn
# With "-- shots" after the command (and no --headless) it also saves screenshots.
extends Node

const Room := preload("res://room.gd")

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


func _goto(room_name: String, key: String) -> void:
	main.player.hp = 0.0
	main.enter(room_name, key)
	await _frames(30)


func _run() -> void:
	await _frames(40)
	var p: CharacterBody2D = main.player
	_check("starts in the church, on the floor", main.room_name == "church" and p.is_on_floor(), "room=%s y=%.0f" % [main.room_name, p.global_position.y])
	_check("sounds loaded", Sfx.missing.is_empty() and Sfx.count("sfx") >= 11, "sfx=%d missing=%s" % [Sfx.count("sfx"), str(Sfx.missing)])
	var tracks := {}
	for n in ["music_church", "music_library", "music_lab", "music_save", "music_boss"]:
		if Sfx.ev.has(n):
			tracks[Sfx.ev[n]["options"][Sfx.ev[n]["index"]]["file"]] = true
	_check("each of the five areas has its own music", tracks.size() == 5, str(tracks.keys()))

	# the map: every room loads, has the doors it should, and each door leads to a real room
	var kinds := {}
	var looks := {}
	for name in main.ROOMS:
		var r := Room.new()
		add_child(r)
		var ok: bool = r.load_room(name)
		for side in r.doors:
			var d = r.doors[side]
			var edge: bool = (side == "left" and d.position.x == 0.0) or (side == "right" and d.position.x == r.size.x - 16.0)
			ok = ok and edge and main.ROOMS.has(d.to)
		for e in r.enemies:
			kinds[e[0]] = true
		looks[r.head.get("theme", "")] = true
		_check("room '%s' loads, doors sit in the room edge" % name, ok, "size=%s doors=%s" % [str(r.size), str(r.doors.keys())])
		r.queue_free()
	_check("five enemy kinds are placed in the rooms", kinds.size() == 5, str(kinds.keys()))
	_check("every room has its own look", looks.size() == 5, str(looks.keys()))
	await _shot("1_church_start")

	var x0 := p.global_position.x
	await _tap("right", 60)
	var dx := p.global_position.x - x0
	_check("run speed", absf(dx - T.v("run_speed")) < T.v("run_speed") * 0.1, "moved %.0f px in 1 s" % dx)
	await _shot("2_run")
	await _frames(12)
	var full := await _jump_height(60)
	await _frames(20)
	var hop := await _jump_height(3)
	await _frames(20)
	_check("full jump height", full > 45.0 and full < 80.0, "%.0f px" % full)
	_check("tap is a short hop", hop < full * 0.7 and hop > 6.0, "%.0f px vs %.0f px" % [hop, full])

	# crouch: a real crouch pose, and a shorter body
	var tall: float = p.body_rect().size.y
	Input.action_press("down")
	await _frames(20)
	_check("crouch uses the crouch frames and a lower body", p._spr.animation == "crouch" and p.body_rect().size.y < tall,
		"anim=%s height %.0f -> %.0f" % [p._spr.animation, tall, p.body_rect().size.y])
	await _shot("3_crouch")
	Input.action_press("attack")
	await _frames(2)
	Input.action_release("attack")
	await _frames(int(T.v("attack_time") * 60.0 * 0.55))
	_check("low attack plays its own frames with the weapon out", p._spr.animation == "crouchatk" and p.weapon_showing(), "anim=%s" % p._spr.animation)
	await _shot("4_crouch_attack")
	Input.action_release("down")
	await _frames(40)

	# the weapon is on screen at the end of the cut, for both weapons
	for w in 2:
		T.set_v("weapon", float(w))
		p.energy = T.v("energy_max")
		var total := T.v("elegy_time") if w == 1 else T.v("attack_time")
		Input.action_press("attack")
		await _frames(2)
		Input.action_release("attack")
		await _frames(int(total * 60.0 * 0.6) - 2)
		_check("%s is visible at the end of the swing" % p.weapon_name(), p.state == "attack" and p.weapon_showing(), "state=%s" % p.state)
		await _shot("5_swing_%d" % w)
		await _frames(int(total * 60.0 * 0.6) + 10)
		_check("%s is gone after the swing" % p.weapon_name(), not p.weapon_showing(), "")
	T.set_v("weapon", 0.0)
	await _tap("swap", 2)
	_check("E swaps the weapon", int(T.v("weapon")) == 1, "weapon=%d" % int(T.v("weapon")))
	await _tap("swap", 2)
	Input.action_press("up")
	Input.action_press("attack")
	await _frames(2)
	Input.action_release("attack")
	Input.action_release("up")
	await _frames(12)
	_check("Up + Attack throws the blade wave", main.waves.size() == 1 and p._spr.animation == "cast", "waves=%d anim=%s" % [main.waves.size(), p._spr.animation])
	await _shot("6_special")
	await _frames(60)

	# fight: stand next to the first hound and swing until it dies
	var hound: Node2D = null
	for en in main.enemies:
		if en.kind == "hound":
			hound = en
			break
	_check("a hound waits in the church", hound != null, "")
	if hound != null:
		var before: int = main.kills
		for i in 8:
			if not is_instance_valid(hound):
				break
			p.global_position = hound.global_position + Vector2(-30, 0)
			p.facing = 1
			p.energy = T.v("energy_max")
			await _tap("attack", 2)
			await _frames(30)
		_check("the hound dies to her sword", main.kills == before + 1, "kills=%d" % main.kills)

	# the door is in the room edge: it opens as she comes near and she walks off the screen
	var door = main.room.doors["right"]
	p.global_position = Vector2(main.room.size.x - 90.0, door.feet().y)
	await _frames(10)
	_check("the door is shut while she is away", door.open < 0.1, "open=%.2f" % door.open)
	await _shot("7_door_shut")
	Input.action_press("right")
	await _frames(35)
	await _shot("8_door_opening")
	for i in 240:
		if main.room_name != "church":
			break
		await get_tree().physics_frame
	Input.action_release("right")
	await _frames(40)
	p = main.player
	_check("walking through the edge door leads to the library", main.room_name == "library" and p.global_position.x < 60.0,
		"room=%s x=%.0f" % [main.room_name, p.global_position.x])
	await _shot("9_library_entry")
	if shots:
		for i in 4:
			p.global_position = Vector2(main.room.size.x * (0.3 + 0.15 * i), main.room.size.y - 60.0 - i * 120.0)
			p.velocity = Vector2.ZERO
			await _frames(3)
			await _shot("10_library_%d" % i)

	await _goto("save", "left")
	p = main.player
	p.hp = 20.0
	p.global_position.x = main.room.spawns["M"].x
	await _frames(10)
	await _shot("11_save_room")
	await _tap("up", 2)
	await _frames(4)
	_check("the terminal saves and heals", main.saved and p.hp == T.v("player_hp"), "saved=%s hp=%.0f" % [str(main.saved), p.hp])
	await _shot("12_saved")

	await _goto("lab", "left")
	p = main.player
	await _shot("13_lab_entry")
	if shots:
		for i in 4:
			p.global_position.x = main.room.size.x * (0.25 + 0.2 * i)
			p.global_position.y = main.room.size.y - 40.0
			await _frames(6)
			await _shot("14_lab_%d" % i)
	var bd = main.room.doors.get("right")
	_check("the lab ends in the special boss door", bd != null and bd.boss and bd.to == "boss", "")
	if bd != null:
		p.global_position = Vector2(main.room.size.x - 70.0, bd.feet().y)
		await _frames(30)
		await _shot("15_boss_door")

	# enemies really attack: with peace off, each kind leaves its idle state near her
	G.peace = false
	var woke := {}
	for name in ["church", "library", "lab"]:
		await _goto(name, "left")
		p = main.player
		for en in main.enemies.duplicate():
			if not is_instance_valid(en) or woke.has(en.kind):
				continue
			p.global_position = en.global_position + Vector2(-60, 0 if not en._d["fly"] else 60)
			p.velocity = Vector2.ZERO
			p.invuln = 99.0
			var first: String = en.state
			var seen := {}
			for i in 420:
				await get_tree().physics_frame
				if not is_instance_valid(en):
					break
				seen[en.state] = true
				p.invuln = 99.0
				if i % 30 == 0:
					p.global_position = en.global_position + Vector2(-60, 0 if not en._d["fly"] else 60)
					p.velocity = Vector2.ZERO
			woke[en.kind] = seen.size()
			if shots:
				await _shot("16_enemy_%s" % en.kind)
			_check("%s moves through several states (two attacks, two moves)" % en.kind, seen.size() >= 3, "%s -> %s" % [first, str(seen.keys())])
	G.peace = true

	# the boss
	await _goto("boss", "left")
	p = main.player
	var boss = main.boss
	_check("the boss waits in the sanctum", boss != null and not boss.started, "")
	await _shot("17_boss_room")
	p.global_position.x = 120.0
	await _frames(90)
	_check("walking in starts the fight and locks the door", boss.started and main.room.doors["left"].locked, "")
	var unreachable: bool = boss.body_rect().end.y < p.global_position.y - 54.0 - (T.v("jump_velocity") * T.v("jump_velocity") / (2.0 * T.v("gravity")))
	_check("the body floats out of reach from the floor", unreachable, "body bottom y=%.0f, floor y=%.0f" % [boss.body_rect().end.y, p.global_position.y])
	boss._hands[0]["state"] = "track"
	boss._hands[0]["t"] = 0.0
	for i in 200:
		await get_tree().physics_frame
		if boss._hands[0]["state"] == "stuck":
			break
	_check("a slammed hand sticks in the floor as a step", boss._hands[0]["state"] == "stuck" and not boss._hands[0]["shape"].disabled, "state=%s" % boss._hands[0]["state"])
	await _shot("18_boss_hand_stuck")
	# climb it: stand on the hand, jump, and cut the body
	var hand_top: Vector2 = boss._hands[0]["spr"].position + Vector2(0, -20)
	p.global_position = hand_top
	p.velocity = Vector2.ZERO
	await _frames(12)
	_check("she can stand on the stuck hand", p.is_on_floor() and p.global_position.y < boss.floor_y - 20.0, "y=%.0f floor=%.0f" % [p.global_position.y, boss.floor_y])
	boss._body.position.x = p.global_position.x + 14.0
	var hp0: float = boss.hp
	p.facing = 1
	Input.action_press("jump")
	await _frames(15)
	Input.action_press("attack")
	await _frames(2)
	Input.action_release("attack")
	await _shot("19_boss_reach")
	await _frames(14)
	Input.action_release("jump")
	_check("a jump from the hand reaches the body", boss.hp <= hp0 - T.v("attack_damage") + 0.01, "boss hp %.0f -> %.0f" % [hp0, boss.hp])
	await _frames(50)
	boss.hit(boss.hp * 0.6, -1)
	_check("under half health it changes phase", boss._phase == 2, "phase=%d" % boss._phase)
	boss.hit(9999.0, -1)
	await _frames(200)
	_check("the boss dies and the door unlocks", main.boss_beaten and not main.room.doors["left"].locked, "")
	await _shot("20_boss_dead")
