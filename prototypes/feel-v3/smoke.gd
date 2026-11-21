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
	# no checks at all means the game did not even load: that is a failure, not a pass
	var ok := failed == 0 and passed > 0
	print("SMOKE %s  passed=%d failed=%d" % ["PASS" if ok else "FAIL", passed, failed])
	get_tree().quit(0 if ok else 1)


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
		r.position = Vector2(0, -9000)      # far from the live room: its walls are real
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
	# map.md section 2 (before sheet): hound, ghost, moth, scribe, crab, leech; trolley and orderly come with S4 (then 8)
	_check("the six enemy kinds map.md places before S4 are in the rooms", kinds.size() == 6 and kinds.has("hound") and kinds.has("ghost")
		and kinds.has("moth") and kinds.has("scribe") and kinds.has("crab") and kinds.has("leech"), str(kinds.keys()))
	# map.md line 236: save2 is off the map, so its own look goes; the 15 before rooms use seven looks
	_check("every area has its own look", looks.size() == 7, str(looks.keys()))
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

	# backdash: two buttons, one per direction; her back points where she dashes
	p.global_position = Vector2(main.room.size.x * 0.5, main.room.spawns["P"].y)
	p.velocity = Vector2.ZERO
	await _frames(10)
	var x_bd: float = p.global_position.x
	await _tap("backdash_left", 2)
	await _frames(11)
	await _shot("fx_backdash")
	await _frames(int(T.v("backdash_time") * 60.0) - 5)
	_check("backdash left moves her left and she faces right", p.global_position.x < x_bd - 20.0 and p.facing == 1,
		"x %.0f -> %.0f facing=%d" % [x_bd, p.global_position.x, p.facing])
	p.global_position = Vector2(main.room.size.x * 0.5, main.room.spawns["P"].y)
	p.velocity = Vector2.ZERO
	p.facing = 1
	await _frames(10)
	x_bd = p.global_position.x
	await _tap("backdash_right", 2)
	await _frames(int(T.v("backdash_time") * 60.0) + 6)
	_check("backdash right moves her right and she faces left", p.global_position.x > x_bd + 20.0 and p.facing == -1,
		"x %.0f -> %.0f facing=%d" % [x_bd, p.global_position.x, p.facing])

	# slide: Down + Jump on solid floor, a low box while it lasts, then she stands up
	p.global_position = Vector2(main.room.size.x * 0.5, main.room.spawns["P"].y)
	p.velocity = Vector2.ZERO
	p.facing = -1
	await _frames(10)
	var x_sl: float = p.global_position.x
	Input.action_press("down")
	await _frames(8)
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	await _frames(4)
	var slide_state: String = p.state
	var slide_h: float = p.body_rect().size.y
	await _frames(6)
	await _shot("fx_slide")
	await _frames(int(T.v("slide_time") * 60.0) + 10)
	_check("Down + Jump on solid floor slides", slide_state == "slide" and slide_h <= T.v("slide_height") and x_sl - p.global_position.x > 30.0,
		"state=%s height=%.0f moved=%.0f" % [slide_state, slide_h, x_sl - p.global_position.x])
	_check("the slide ends standing when there is room", p._rect.size.y == p.BODY.y, "shape height=%.0f" % p._rect.size.y)
	_check("holding Down, the slide ends in the crouch picture (not stuck on the last slide frame)",
		p.state == "crouch" and p._spr.animation == "crouch", "state=%s picture=%s" % [p.state, p._spr.animation])
	Input.action_release("down")
	await _frames(10)

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
	main.has_elegy = true      # the swap needs the Pallbearer's scythe (checked further down)
	await _tap("swap", 2)
	_check("E swaps the weapon", int(T.v("weapon")) == 1, "weapon=%d" % int(T.v("weapon")))
	await _tap("swap", 2)
	Input.action_press("up")
	Input.action_press("attack")
	await _frames(2)
	Input.action_release("attack")
	Input.action_release("up")
	await _frames(4)
	await _shot("fx_cast_gather")
	await _frames(8)
	_check("Up + Attack throws the blade wave", main.waves.size() == 1 and p._spr.animation == "cast", "waves=%d anim=%s" % [main.waves.size(), p._spr.animation])
	await _shot("6_special")
	await _frames(60)
	# a special that is cut off before it goes off costs nothing; a hit does not cut it off
	p.mp = T.v("mp_max")
	p.invuln = 0.0
	Input.action_press("up")
	Input.action_press("attack")
	await _frames(2)
	Input.action_release("attack")
	Input.action_release("up")
	_check("the special takes no MP before the wave leaves", p.mp == T.v("mp_max") and p.state == "attack", "mp=%.0f" % p.mp)
	p.take_hit(1.0, p.global_position.x + 10.0)
	await _frames(int(T.v("special_time") * 60.0 * 0.3) + 4)
	_check("a hit does not cancel the special, and now it has cost MP", main.waves.size() >= 1 and p.mp == T.v("mp_max") - T.v("special_cost"), "waves=%d mp=%.0f" % [main.waves.size(), p.mp])
	await _frames(60)
	# in the air: landing must not cut the special short
	p.mp = T.v("mp_max")
	p.invuln = 0.0
	p.hp = T.v("player_hp")
	var before_waves: int = main.waves.size()
	Input.action_press("jump")
	await _frames(26)
	Input.action_release("jump")
	await _frames(20)
	Input.action_press("up")
	Input.action_press("attack")
	await _frames(2)
	Input.action_release("attack")
	Input.action_release("up")
	await _frames(int(T.v("special_time") * 60.0 * 0.3) + 6)
	_check("a special started just before landing still goes off", main.waves.size() == before_waves + 1, "waves=%d" % main.waves.size())
	await _frames(70)
	# Elegy: J and I are the same single cut; the Requiem spins the scythe
	T.set_v("weapon", 1.0)
	p.energy = T.v("energy_max")
	var e0: float = p.energy
	await _tap("attack2", 2)
	_check("Elegy: I gives the same one cut as J, at 1.5x the energy", p._attack_btn == "attack" and is_equal_approx(e0 - p.energy, T.v("attack_energy") * T.v("elegy_energy_mult")), "btn=%s spent=%.1f" % [p._attack_btn, e0 - p.energy])
	await _frames(int(T.v("elegy_time") * 60.0) + 10)
	p.mp = T.v("mp_max")
	Input.action_press("up")
	Input.action_press("attack")
	await _frames(2)
	Input.action_release("attack")
	Input.action_release("up")
	await _frames(int(T.v("elegy_special_time") * 60.0 * 0.4))
	_check("Elegy special spins the scythe and costs its own MP", p.state == "attack" and p._arm.visible and p.mp == T.v("mp_max") - T.v("elegy_special_cost"), "mp=%.0f" % p.mp)
	_check("the Requiem reaches farther", absf(p._blade.position.length() - T.v("elegy_special_radius")) < 1.0
		and is_equal_approx(p._blade.scale.x, T.v("elegy_special_size")),
		"reach=%.1f scale=%.2f" % [p._blade.position.length(), p._blade.scale.x])
	await _shot("6_requiem")
	await _frames(int(T.v("elegy_special_time") * 60.0) + 10)
	T.set_v("weapon", 0.0)
	# the pause menu holds the music
	main.touch.toggle_pause()
	_check("pause holds the music", get_tree().paused and Sfx._music.stream_paused, "")
	main.touch.toggle_pause()
	_check("resume lets the music go on", not get_tree().paused and not Sfx._music.stream_paused, "")

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
	var boss_door: Node2D = null
	for d in main.room.doors_all:
		if String(d.side) == "right" and d.boss and String(d.to) == "ordnance":
			boss_door = d
	_check("the lab leads on to the hallway, and its upper floor to the ordnance ward",
		bd != null and bd.to == "hallway" and boss_door != null,
		"right=%s ordnance_door=%s" % [bd.to if bd != null else "none", str(boss_door != null)])
	_check("the lab's left door leads back to the cache station", main.room.doors.get("left") != null and main.room.doors["left"].to == "save", "")
	_check("the lab holds no wall-jump relic any more (GRIP SERVOS moved to the kennel)", not main.room.spawns.has("A") and main._relic == null, "")
	# the wall jump is THE UNMUZZLED's: he guards the kennel and drops GRIP SERVOS when he
	# falls (user yes 2026-11-21, lane 06; the full fight is in tests_dev/d19_kennel_wolf)
	await _goto("kennel", "O")
	p = main.player
	var kn_wolf = main.boss
	var kn_loose := false
	for it in main.loot.live:
		if is_instance_valid(it) and String(it.get("item_id")) == "wall_jump":
			kn_loose = true
	_check("THE UNMUZZLED guards the kennel and no wall jump lies loose", kn_wolf != null and String(kn_wolf.get("boss_id")) == "unmuzzled" and not kn_loose,
		"room=%s boss=%s loose=%s latch=%s beaten=%s" % [main.room_name, str(kn_wolf), str(kn_loose), str(main.has_latch), str(W.flag("beaten_unmuzzled"))])
	main.arena.debug_win()
	await _frames(6)
	var kn_drop: Node2D = null
	for it in main.loot.live:
		if is_instance_valid(it) and String(it.get("item_id")) == "wall_jump":
			kn_drop = it
	p.global_position = kn_drop.global_position + Vector2(0, 8) if kn_drop != null else p.global_position
	await _frames(6)
	await _tap("up", 2)
	await _frames(6)
	_check("Up at the wall jump he drops gives the wall latch", W.flag("beaten_unmuzzled") and main.has_latch, "")
	main.has_latch = true      # the movement checks below test the latch itself, not the marker
	# the wall latch: jump at the well's wall, cling, kick off
	await _goto("shaft", "right")
	p = main.player
	p.global_position = Vector2(14 * 16 - 7.0, main.room.size.y - 32.0 - 120.0)
	p.velocity = Vector2.ZERO
	Input.action_press("right")
	await _frames(6)
	_check("she clings to the wall", p.state == "wall", "state=%s" % p.state)
	await _shot("14_wall_latch")
	var y_cling: float = p.global_position.y
	Input.action_press("jump")
	await _frames(3)
	Input.action_release("jump")
	_check("jump kicks her off the wall, up and away", p.velocity.x < -50.0 and p.velocity.y < 0.0, "vel=%s" % str(p.velocity))
	await _frames(40)
	Input.action_release("right")
	# one latch per jump: back at the same wall in the air, she cannot grab again
	p.global_position = Vector2(14 * 16 - 7.0, main.room.size.y - 32.0 - 120.0)
	p.velocity = Vector2(0, 20.0)
	Input.action_press("right")
	await _frames(6)
	_check("only one wall latch per jump", p.state != "wall", "state=%s latches=%d" % [p.state, p._air_latches])
	Input.action_release("right")
	await _frames(90)
	_check("landing gives the wall latch back", p._air_latches == 0, "latches=%d on_floor=%s" % [p._air_latches, str(p.is_on_floor())])
	p.global_position = Vector2(14 * 16 - 7.0, main.room.size.y - 32.0 - 120.0)
	p.velocity = Vector2.ZERO
	Input.action_press("right")
	await _frames(int(T.v("wall_latch_time") * 60.0) + 20)
	Input.action_release("right")
	_check("the latch gives out by itself", p.state != "wall", "state=%s" % p.state)
	# the second cache station and the boss door (map.md: S2 and VA are the saves; HW ends in PB)
	await _goto("vault", "left")
	p = main.player
	_check("the second cache station has a capsule and a terminal", main.room.spawns.has("K") and main.room.spawns.has("M"), "")
	p.global_position.x = main.room.spawns["M"].x
	await _frames(10)
	await _tap("up", 2)
	await _frames(4)
	_check("the second cache station saves too", main.saved_room == "vault", main.saved_room)
	await _shot("15_save2")
	# the hallway ends in the boss door (map.md: HW right boss door to PB)
	await _goto("hallway", "left")
	p = main.player
	bd = main.room.doors.get("right")
	_check("the hallway ends in the boss door", bd != null and bd.boss and bd.to == "boss", "")
	# death: SYSTEM OFFLINE, then RECONSTRUCT rebuilds her at the capsule as the next Pandora
	G.peace = false
	p.take_hit(9999.0, 0.0)
	await _frames(130)
	_check("death shows SYSTEM OFFLINE", main.offline.active and main.offline.visible, "")
	await _shot("15_offline")
	# the screen ignores presses for its first 0.9 s (real time); a windowed run gets here sooner
	while main.offline._ready_t > 0.0:
		await _frames(1)
	await _tap("attack", 2)
	await _frames(200)
	G.peace = true
	p = main.player
	_check("RECONSTRUCT rebuilds her at the capsule of the last save room", main.room_name == "vault" and not main.offline.visible and p.hp == T.v("player_hp")
		and absf(p.global_position.x - main.room.spawns["K"].x) < 40.0, "room=%s x=%.0f" % [main.room_name, p.global_position.x])
	_check("she is the next Pandora", main.unit == 2 and main.hud._name.text == "PANDORA-002", main.hud._name.text)
	await _shot("15_reconstructed")
	await _goto("lab", "left")
	p = main.player
	var shot_door: Node2D = null
	for d in main.room.doors_all:
		if String(d.side) == "right" and d.boss:
			shot_door = d
	if shot_door != null:
		p.global_position = Vector2(main.room.size.x - 70.0, shot_door.feet().y)
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
			var ekind: String = String(en.kind)      # read before the watch: an enemy can vanish in it (a moth dive frees it)
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
			woke[ekind] = seen.size()
			if shots:
				await _shot("16_enemy_%s" % ekind)
			_check("%s moves through several states (two attacks, two moves)" % ekind, seen.size() >= 3, "%s -> %s" % [first, str(seen.keys())])
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
	await _boss_attacks()
	main.has_elegy = false      # she does not have the scythe yet: the boss's death must drop it
	boss.hit(9999.0, -1)
	await _frames(200)
	_check("the boss dies and the door unlocks", main.boss_beaten and not main.room.doors["left"].locked, "")
	await _shot("20_boss_dead")
	await _new_area()


# ---------------------------------------------------------------------------------------------
# The Pallbearer's new hand attacks: the reap (a huge slash crossing at chest or floor height)
# and the throw (the scythe goes out at one height and comes back at the other).
# ---------------------------------------------------------------------------------------------

func _slash_damage(kind: String, h: float, pose: String) -> float:
	# puts a slash of the given height in the room, 110 units from her, flying at her; returns the life lost
	var boss = main.boss
	var p: CharacterBody2D = main.player
	boss._gap = 999.0
	var x0: float = (boss.left_x + boss.right_x) / 2.0
	p.global_position = Vector2(x0, boss.floor_y)
	p.velocity = Vector2.ZERO
	p.invuln = 0.0
	p.hp = T.v("player_hp")
	await _frames(20)
	if pose == "crouch":
		Input.action_press("down")
		await _frames(12)
	boss._slash = {"on": true, "kind": kind, "x": x0 + 110.0, "dirx": -1.0, "h": h, "h_back": h, "leg": 0, "spin": 0.0, "start_x": x0 + 110.0, "box": Rect2()}
	G.peace = false
	for i in 90:
		await get_tree().physics_frame
		boss._gap = 999.0
		if pose == "jump" and i == 8:
			Input.action_press("jump")
		if p.hp < T.v("player_hp"):
			break
	G.peace = true
	Input.action_release("down")
	Input.action_release("jump")
	var lost: float = T.v("player_hp") - p.hp
	boss._slash = {"on": false}
	await _frames(40)
	return lost


func _boss_attacks() -> void:
	var boss = main.boss
	var p: CharacterBody2D = main.player
	var high: float = T.v("boss_reap_high")
	var low: float = T.v("boss_reap_low")
	_check("the chest-high slash starts above a crouch (22) and inside a standing body (36)", high - T.v("boss_reap_thick") / 2.0 > 22.0 and high < 36.0, "bottom=%.0f" % (high - T.v("boss_reap_thick") / 2.0))
	var stand_high: float = await _slash_damage("reap", high, "stand")
	_check("a chest-high reap hurts her standing", stand_high > 0.0, "lost=%.0f" % stand_high)
	var crouch_high: float = await _slash_damage("reap", high, "crouch")
	_check("she ducks under a chest-high reap", crouch_high == 0.0, "lost=%.0f" % crouch_high)
	var crouch_low: float = await _slash_damage("reap", low, "crouch")
	_check("a low reap hurts her crouching", crouch_low > 0.0, "lost=%.0f" % crouch_low)
	var jump_low: float = await _slash_damage("reap", low, "jump")
	_check("she hops over a low reap", jump_low == 0.0, "lost=%.0f" % jump_low)
	# the real thing: a hand takes the scythe, glows, lets go; the slash crosses and the hand goes back to rest
	boss._gap = 999.0
	boss._hands[1]["state"] = "rest"
	boss._reaps = 0
	var h: Dictionary = boss._hands[1]
	h["state"] = "reap_ready"
	h["t"] = 0.0
	h["dir"] = 1.0
	h["low"] = false
	var seen_on := false
	var warn_ok := false
	for i in 900:
		await get_tree().physics_frame
		boss._gap = 999.0
		if not seen_on and h["state"] == "reap_ready" and h["t"] > 0.3:
			warn_ok = true
		if boss._slash["on"]:
			seen_on = true
		if seen_on and not boss._slash["on"]:
			break
	await _frames(30)
	_check("a hand can reap: it warns, the slash crosses the room, the hand rests again", warn_ok and seen_on and h["state"] == "rest", "state=%s" % h["state"])
	h["state"] = "throw_ready"
	h["t"] = 0.0
	h["dir"] = 1.0
	h["low"] = false
	seen_on = false
	var out_h := -1.0
	var back_h := -1.0
	var legs := 0
	for i in 1500:
		await get_tree().physics_frame
		boss._gap = 999.0
		if boss._slash["on"]:
			seen_on = true
			if int(boss._slash["leg"]) == 0:
				out_h = float(boss._slash["h"])
			else:
				back_h = float(boss._slash["h"])
				legs = 1
		if seen_on and not boss._slash["on"]:
			break
	await _frames(30)
	_check("a hand can throw: out at one height, back at the other, then the hand rests", seen_on and legs == 1 and out_h == high and back_h == low and h["state"] == "rest",
		"out=%.0f back=%.0f state=%s" % [out_h, back_h, h["state"]])
	p.global_position = Vector2(boss.left_x + 60.0, boss.floor_y)
	await _frames(10)


# ---------------------------------------------------------------------------------------------
# The new area: the sealed church door, the lever, the marrow well, the vault, the threshing
# chapel (bars, lever, cracked wall, tunnel), the time machine and the reality shift.
# ---------------------------------------------------------------------------------------------

func _goto_from(room_name: String, key: String, from_room: String) -> void:
	main.player.hp = 0.0
	main.enter(room_name, key, from_room)
	await _frames(30)


func _climb_hop(p: CharacterBody2D, target_top: float, start_x: float) -> bool:
	# jump at the right wall, latch it, kick off up and left onto the next ledge (human timing).
	# She starts at the right end of the ledge (x 172), where a player would take the run.
	p.global_position.x = start_x
	p.velocity = Vector2.ZERO
	await _frames(6)
	Input.action_press("right")
	Input.action_press("jump")
	var latched := false
	for i in 60:
		await get_tree().physics_frame
		if p.state == "wall":
			latched = true
			break
	Input.action_release("jump")
	if not latched:
		Input.action_release("right")
		return false
	await _frames(10)
	Input.action_release("right")
	Input.action_press("left")
	Input.action_press("jump")
	await _frames(20)
	Input.action_release("jump")
	await _frames(55)
	Input.action_release("left")
	await _frames(10)
	var ok: bool = p.is_on_floor() and absf(p.global_position.y - target_top) < 3.0 and p.global_position.x < 192.0      # the ledge and its lip end at x 192
	print("      hop to y=%.0f: latched=%s now x=%.0f y=%.0f floor=%s" % [target_top, str(latched), p.global_position.x, p.global_position.y, str(p.is_on_floor())])
	return ok


func _until_room(name: String, frames: int) -> void:
	for i in frames:
		if main.room_name == name:
			break
		await get_tree().physics_frame


func _new_area() -> void:
	var p: CharacterBody2D = main.player
	# ---- the scythe the boss leaves, and the swap gate ----
	_check("the boss leaves its scythe floating where it fell", main._scythe != null and is_instance_valid(main._scythe), "")
	main.has_elegy = false
	T.set_v("weapon", 0.0)
	await _tap("swap", 2)
	_check("E does nothing before the scythe is hers", int(T.v("weapon")) == 0 and not main.has_elegy, "weapon=%d" % int(T.v("weapon")))
	p.swap_weapon()
	_check("a direct swap is refused too", int(T.v("weapon")) == 0, "")
	await _frames(100)
	p.global_position = Vector2(main._scythe.global_position.x, main.room.spawns["O"].y)
	await _frames(8)
	# user ask C5 (2026-11-18): every pickup with Up, never by touch; the card shows it
	_check("touching the scythe does not take it", not main.has_elegy and main._scythe != null, "")
	await _tap("up", 2)
	var card_shown := false
	for i in 120:      # a special pickup plays its show first, then the card opens
		await _frames(1)
		if main.card != null and main.card.active:
			card_shown = true
			break
	_check("Up at the scythe gives ELEGY-013 and shows its card", main.has_elegy and main._scythe == null and card_shown, "")
	await _frames(60)
	await _tap("up", 2)
	await _frames(8)
	await _tap("swap", 2)
	_check("E swaps once the scythe is hers", int(T.v("weapon")) == 1, "")
	T.set_v("weapon", 0.0)

	# ---- the church's lower door and the library lever ----
	main.lever_library = false
	await _goto("church", "P")
	p = main.player
	var cd = main.room.doors.get("left")
	_check("the church has a lower left door to the shaft", cd != null and cd.to == "shaft" and absf(cd.position.x) < 0.1, "")
	_check("the church door is locked before the lever", cd != null and cd.locked, "")
	p.global_position = Vector2(60.0, cd.feet().y)
	await _frames(6)
	Input.action_press("left")
	await _frames(70)
	Input.action_release("left")
	_check("walking into it leaves it shut, with its lamp red", cd.open < 0.1 and main.room_name == "church" and cd.lamp == "red",
		"open=%.2f lamp=%s" % [cd.open, cd.lamp])
	await _goto("library", "left")
	p = main.player
	var lever: Node2D = null
	for pr in main.room.props:
		if pr.kind == "library":
			lever = pr
	_check("the library has a lever on the climb", lever != null and not lever.pulled, "")
	p.global_position = lever.global_position + Vector2(-30.0, 0.0)
	p.facing = 1
	await _frames(25)      # the lever's feet sit one tile above the floor: let her land first
	await _tap("attack", 2)
	await _frames(25)
	_check("a cut pulls the library lever", lever.pulled and main.lever_library, "pulled=%s flag=%s" % [str(lever.pulled), str(main.lever_library)])
	main.lever_library = false
	await _goto("library", "left")
	p = main.player
	for pr in main.room.props:
		if pr.kind == "library":
			lever = pr
	p.global_position = lever.global_position + Vector2(-10.0, 0.0)
	await _frames(6)
	await _tap("up", 2)
	await _frames(4)
	_check("Up beside the lever pulls it too", lever.pulled and main.lever_library, "")
	await _goto("church", "P")
	p = main.player
	cd = main.room.doors["left"]
	_check("after the lever the church door is not locked, and its lamp is pale", not cd.locked and cd.lamp == "pale", "lamp=%s" % cd.lamp)
	p.global_position = Vector2(60.0, cd.feet().y)
	await _frames(6)
	Input.action_press("left")
	await _until_room("shaft", 300)
	Input.action_release("left")
	await _frames(30)
	p = main.player
	_check("it opens into the shaft, at its bottom right", main.room_name == "shaft" and p.global_position.x > main.room.size.x - 60.0 and p.is_on_floor(),
		"room=%s x=%.0f" % [main.room_name, p.global_position.x])

	# ---- up and down between the shaft and the vault ----
	var up_span: Vector2 = main.room.up_span
	p.global_position = Vector2((up_span.x + up_span.y) / 2.0, 6.0)
	p.velocity = Vector2(0.0, -250.0)
	await _frames(3)
	p = main.player
	_check("up through the top opening of the shaft leads to the vault", main.room_name == "vault", main.room_name)
	await _frames(10)
	var dn: Vector2 = main.room.down_span
	_check("she pops out of the vault hole, above its floor", absf(p.global_position.x - (dn.x + dn.y) / 2.0) < 6.0
		and p.global_position.y < main.room.size.y - 8.0 and p.velocity.y < 0.0, "x=%.0f y=%.0f vy=%.0f" % [p.global_position.x, p.global_position.y, p.velocity.y])
	Input.action_press("right")
	await _frames(45)
	Input.action_release("right")
	await _frames(20)
	p = main.player
	_check("steering in the air she lands on the vault floor beside the hole", main.room_name == "vault" and p.is_on_floor() and p.global_position.x > dn.y + 2.0,
		"room=%s x=%.0f floor=%s" % [main.room_name, p.global_position.x, str(p.is_on_floor())])
	# the hole is covered by a thin ledge: standing on it she stays in the vault
	p.global_position = Vector2((dn.x + dn.y) / 2.0, main.room.size.y - 20.0)
	p.velocity = Vector2.ZERO
	await _frames(30)
	p = main.player
	_check("a thin ledge covers the vault hole: she stands on it and does not fall back", main.room_name == "vault" and p.is_on_floor(),
		"room=%s y=%.0f floor=%s" % [main.room_name, p.global_position.y, str(p.is_on_floor())])
	Input.action_press("down")
	await _frames(2)
	Input.action_press("jump")
	await _frames(3)
	Input.action_release("jump")
	await _until_room("shaft", 120)
	Input.action_release("down")
	await _frames(1)
	p = main.player
	_check("Down + Jump on the hole ledge drops her back into the top of the shaft, still falling", main.room_name == "shaft" and p.global_position.y < 80.0 and p.velocity.y > 0.0,
		"room=%s y=%.0f vy=%.0f" % [main.room_name, p.global_position.y, p.velocity.y])

	# ---- the ledges: 80 apart with a one-way lip (user decision 2026-11-19), so a plain jump cannot do it ----
	await _goto_from("shaft", "right", "church")
	main.has_latch = false
	p = main.player
	var ledges: Array = []
	for y in main.room.grid.size():
		if main.room.cell(9, y) == "#" and main.room.cell(10, y) == "#" and (main.room.cell(11, y) == "." or main.room.cell(11, y) == "=") and main.room.cell(9, y - 1) == "." and y < 27:
			ledges.append(float(y * 16))
	ledges.reverse()
	var jump_up: float = T.v("jump_velocity") * T.v("jump_velocity") / (2.0 * T.v("gravity"))
	var spacing_ok := ledges.size() == 5
	for i in range(ledges.size() - 1):
		spacing_ok = spacing_ok and absf(ledges[i] - ledges[i + 1] - 80.0) < 0.1
	_check("five ledges, 80 apart, more than a jump rises (%.0f)" % jump_up, spacing_ok and 80.0 > jump_up + 10.0, str(ledges))
	var best := 9999.0
	for variant in ["", "right", "left"]:
		p.global_position = Vector2(160.0, ledges[0] - 1.0)
		p.velocity = Vector2.ZERO
		await _frames(10)
		if variant != "":
			Input.action_press(variant)
		Input.action_press("jump")
		for i in 70:
			await get_tree().physics_frame
			best = minf(best, p.global_position.y)
		Input.action_release("jump")
		if variant != "":
			Input.action_release(variant)
		await _frames(70)
	_check("without the grip a plain jump from ledge 1 stays below ledge 2", best > ledges[1] + 8.0, "highest feet y=%.0f, ledge 2 top=%.0f" % [best, ledges[1]])
	# with the grip: floor -> ledge 1 -> ... -> 5, then out through the top
	main.has_latch = true
	p.global_position = Vector2(180.0, 447.0)
	p.velocity = Vector2.ZERO
	await _frames(15)
	var hops: Array = []
	for k in ledges.size():
		var hop_ok: bool = await _climb_hop(p, float(ledges[k]), 180.0 if k == 0 else 172.0)
		hops.append(hop_ok)
		if not hop_ok:
			break
	_check("with the grip she climbs floor -> 5 ledges (latch the right wall, kick up and left)", hops.size() == 5 and not hops.has(false), str(hops))
	if hops.size() == 5 and not hops.has(false):
		Input.action_press("jump")
		await _until_room("vault", 60)
		Input.action_release("jump")
		_check("and out through the top into the vault", main.room_name == "vault", main.room_name)
	else:
		_check("and out through the top into the vault", false, "climb failed")
	main.has_latch = true

	# ---- the threshing chapel: map.md's two enemy kinds and two traps ----
	var hz := Room.new()
	hz.position = Vector2(0, -9000)
	add_child(hz)
	hz.load_room("hazard")
	var cnt := {}
	for h in hz.hazards:
		cnt[h[0]] = int(cnt.get(h[0], 0)) + 1
	for e in hz.enemies:
		cnt[e[0]] = int(cnt.get(e[0], 0)) + 1
	_check("the threshing chapel holds 2 crabs, 2 leeches, 2 pendulums and 2 crushers", cnt.size() == 4
		and cnt.get("crab", 0) == 2 and cnt.get("leech", 0) == 2 and cnt.get("pendulum", 0) == 2 and cnt.get("crusher", 0) == 2, str(cnt))
	var floor_h: Array = []
	for h in hz.hazards:
		if h[1].end.y >= 14.0 * 16.0 - 0.1:
			floor_h.append(h[1])
	floor_h.sort_custom(func(a, b): return a.position.x < b.position.x)
	var gaps_ok := true
	var min_gap := 999.0
	for i in range(floor_h.size() - 1):
		var gap: float = floor_h[i + 1].position.x - floor_h[i].end.x
		min_gap = minf(min_gap, gap)
		gaps_ok = gaps_ok and gap >= 3.0 * 16.0 - 0.1
	_check("at least 3 tiles of safe floor between the floor hazards", gaps_ok, "floor hazards=%d smallest gap=%.0f px" % [floor_h.size(), min_gap])
	hz.queue_free()

	# ---- bars, the lever behind them, the cracked wall, the tunnel ----
	await _goto("hazard", "right")
	p = main.player
	var bars: Node2D = main.room.bars
	var ylever: Node2D = null
	var wall: Node2D = null
	for pr in main.room.props:
		if pr.has_method("pull") and pr.kind == "bars":
			ylever = pr
		elif pr.has_method("prop_cut") and not pr.has_method("pull"):
			wall = pr
	_check("the hazard room has iron bars, a lever behind them and a cracked wall", bars != null and ylever != null and wall != null, "")
	var floor_y: float = bars.rect.end.y
	p.global_position = Vector2(bars.rect.end.x + 30.0, floor_y - 1.0)
	p.facing = -1
	await _frames(10)
	Input.action_press("left")
	await _frames(45)
	Input.action_release("left")
	_check("she can stand against the bars: they are solid", absf(p.global_position.x - (bars.rect.end.x + 6.0)) < 3.0, "x=%.1f" % p.global_position.x)
	main.has_elegy = true
	T.set_v("weapon", 0.0)
	p.facing = -1
	p.energy = T.v("energy_max")
	await _tap("attack", 2)
	await _frames(40)
	p.energy = T.v("energy_max")
	Input.action_press("down")
	await _frames(20)
	await _tap("attack", 2)
	await _frames(40)
	Input.action_release("down")
	await _frames(20)
	p.energy = T.v("energy_max")
	p.facing = -1
	Input.action_press("jump")
	await _frames(14)
	await _tap("attack", 2)
	await _frames(14)
	Input.action_release("jump")
	await _frames(50)
	main.throw_wave(ylever.global_position + Vector2(50.0, -14.0), -1)
	main.player_swing(ylever.prop_rect(), 50.0, -1, [])
	await _frames(40)
	_check("the Dirge cut (standing, crouching, jumping) and the blade wave never reach the bars lever",
		not ylever.pulled and not main.bars_opened, "pulled=%s dist=%.0f" % [str(ylever.pulled), p.global_position.x - ylever.prop_rect().end.x])
	p.global_position = Vector2(bars.rect.end.x + 6.0, floor_y - 1.0)
	p.facing = -1
	await _frames(6)
	T.set_v("weapon", 1.0)
	p.energy = T.v("energy_max")
	await _tap("attack", 2)
	await _frames(45)
	_check("an Elegy cut reaches it: the bars rise", ylever.pulled and main.bars_opened, "pulled=%s" % str(ylever.pulled))
	await _frames(int(T.v("bars_rise_time") * 60.0) + 30)
	var bar_cell := Vector2i(int(bars.rect.position.x / 16.0), int(bars.rect.position.y / 16.0))
	_check("the bars are gone and the way through is open", bars._shape.disabled and main.room.cell(bar_cell.x, bar_cell.y) == ".", "cell=%s" % str(bar_cell))
	Input.action_press("left")
	await _frames(70)
	Input.action_release("left")
	_check("she walks through the opening to the left half", p.global_position.x < bars.rect.position.x - 8.0, "x=%.0f" % p.global_position.x)
	T.set_v("weapon", 0.0)
	# the cracked wall at the west end (map.md: 3 hits, any weapon)
	await _goto("hazard", "right")
	p = main.player
	for pr in main.room.props:
		if pr.has_method("prop_cut") and not pr.has_method("pull"):
			wall = pr
	var wall_end_x: float = wall.rect.end.x if wall != null else 0.0
	if wall != null:
		p.global_position = Vector2(wall.rect.end.x + 8.0, wall.rect.end.y - 1.0)
		p.facing = -1
		await _frames(6)
		Input.action_press("left")
		await _frames(15)
		Input.action_release("left")
		var hits: Array = []
		for k in 3:
			p.energy = T.v("energy_max")
			await _tap("attack", 2)
			await _frames(30)
			hits.append(wall.hits)
		_check("the cracked wall breaks on the third cut, not before", hits == [1, 2, 3] and wall.broken and main.wall_broken, str(hits))
	else:
		_check("the cracked wall breaks on the third cut, not before", false, "no cracked wall in rooms/hazard.txt")
	Input.action_press("left")
	await _frames(90)
	Input.action_release("left")
	_check("standing, she cannot enter the 2-tile tunnel", p.global_position.x > wall_end_x + 3.0 and main.room_name == "hazard", "x=%.1f" % p.global_position.x)
	p.facing = -1
	Input.action_press("down")
	await _frames(8)
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	await _frames(4)
	var slide_ok: bool = p.state == "slide"
	await _until_room("timemachine", 300)
	Input.action_release("down")
	await _frames(20)
	p = main.player
	_check("a slide passes the tunnel and leaves by the open edge into the time machine room",
		slide_ok and main.room_name == "timemachine" and p.global_position.x > main.room.size.x - 120.0, "room=%s x=%.0f" % [main.room_name, p.global_position.x])      # her arrival slide carries her about 4 tiles in (user decision 2026-11-19)
	main.enter("hazard", "left", "timemachine")
	await _frames(4)
	_check("arriving at the low tunnel puts her into a slide", main.player.state == "slide" and main.room.tunnels.get("left", false), "state=%s" % main.player.state)
	await _frames(110)
	_check("she comes out of the tunnel into the hall", main.player.global_position.x > wall_end_x + 6.0, "x=%.0f" % main.player.global_position.x)

	# ---- the time machine, the question, the shift ----
	await _goto("timemachine", "K")
	p = main.player
	var tpos: Vector2 = main.room.spawns["T"]
	# map.md line 61: OR R0 `~` HZ, so the way back to the chapel is the low crawl (slide), no longer a tall edge
	_check("the organ stands in the room; the way back is the low crawl", main.room.organ != null and main.room.open_edges.has("right")
		and main.room.tunnels.get("right", false), "")
	p.global_position = Vector2(tpos.x, tpos.y - 1.0)
	await _frames(10)
	var saved_before: String = main.saved_room
	await _tap("up", 2)
	await _frames(4)
	_check("Up beside the machine asks the question and holds her still", main.dialog.active and main.hold, "")
	Input.action_press("right")
	await _frames(20)
	Input.action_release("right")
	_check("while the question is open she cannot move", absf(p.global_position.x - tpos.x) < 2.0, "x=%.1f" % p.global_position.x)
	while main.dialog._ready_t > 0.0:
		await _frames(1)
	_check("the first pick is NO", main.dialog._pick == 1, "")
	await _tap("attack", 6)      # NO is the first pick
	await _frames(40)
	_check("NO changes nothing", not main.dialog.active and not G.shifted and not main.hold and main.saved_room == saved_before, "saved_room=%s" % main.saved_room)
	await _tap("up", 2)
	await _frames(4)
	_check("asking again opens the question again", main.dialog.active, "")
	while main.dialog._ready_t > 0.0:
		await _frames(1)
	await _tap("up", 6)          # up/down moves the pick to YES
	await _frames(4)
	_check("W moves the pick to YES", main.dialog._pick == 0, "pick=%d" % main.dialog._pick)
	await _tap("attack", 6)
	await _frames(4)
	for i in 900:
		await get_tree().physics_frame
		if G.shifted and not main._busy:
			break
	await _frames(20)
	p = main.player
	var wake: Vector2 = main.room.spawns.get("K", Vector2(-9999, -9999))
	_check("YES: the world is shifted, and she wakes next to the machine", G.shifted and main.saved_room == "timemachine" and main.room_name == "timemachine"
		and main.room.spawns.has("K") and absf(p.global_position.x - wake.x) < 6.0,
		"shifted=%s room=%s K=%s" % [str(G.shifted), main.room_name, str(main.room.spawns.has("K"))])
	_check("the filter is on and the voices are scheduled", main.shift.visible and main._whisper_t > 0.0 and main._whisper_t <= T.v("shift_whisper_max") + 0.5,
		"visible=%s next=%.1f" % [str(main.shift.visible), main._whisper_t])
	_check("the shift tears the picture, then settles", main.shift.mode == 6, "mode=%d" % main.shift.mode)

	# ---- after the shift ----
	if G.shifted:
		main.player.hp = 0.0
		await main.reconstruct()
		_check("death keeps the world shifted and wakes her at the time machine", G.shifted and main.room_name == "timemachine" and main.player.hp == T.v("player_hp"), main.room_name)
		await _goto("vault", "left")
		p = main.player
		_check("the shifted vault has a sealed door on the right, to Arnetria's room", main.room.doors.has("right") and main.room.doors["right"].boss
			and main.room.doors["right"].to == "arnetria" and main.room.doors["right"].locked, "")
		p.hp = 20.0
		p.global_position.x = main.room.spawns["M"].x
		await _frames(10)
		await _tap("up", 2)
		await _frames(6)
		_check("a shifted terminal heals and saves nothing: NO SIGNAL", p.hp == 20.0 and main.saved_room == "timemachine" and main.hud._toast.text == "NO SIGNAL", main.hud._toast.text)
		var xd = main.room.doors["right"]
		p.global_position = Vector2(main.room.size.x - 90.0, xd.feet().y)
		await _frames(6)
		Input.action_press("right")
		await _frames(90)
		Input.action_release("right")
		_check("the sealed door stays shut with no candles lit, and its lamp is red", xd.open < 0.1 and main.room_name == "vault" and xd.locked and xd.lamp == "red"
			and not (W.flag("candle_1") or W.flag("candle_2") or W.flag("candle_3")), "open=%.2f lamp=%s" % [xd.open, xd.lamp])
		# the shifted rooms are their own files now (map.md section 5)
		var mc := Room.new()
		mc.position = Vector2(0, -9000)
		add_child(mc)
		mc.load_room("church", true)
		_check("the shifted church is church_shift: the library on the left, the lab on the right, the bier hole above",
			mc.file_id == "church_shift" and mc.head.get("left", "") == "library_shift" and mc.head.get("right", "") == "lab_shift"
			and mc.head.get("up", "") == "boss_shift", "file=%s head=%s" % [mc.file_id, str(mc.head)])
		var ml := Room.new()
		ml.position = Vector2(0, -9000)
		add_child(ml)
		ml.load_room("library", true)
		_check("the shifted library is library_shift: the scriptorium crawl on the left, the chapel on the right",
			ml.file_id == "library_shift" and ml.head.get("left", "") == "scriptorium_shift" and ml.tunnels.get("left", false)
			and ml.head.get("right", "") == "hazard_shift", "file=%s left=%s right=%s" % [ml.file_id, ml.head.get("left", ""), ml.head.get("right", "")])
		var mh := Room.new()
		mh.position = Vector2(0, -9000)
		add_child(mh)
		mh.load_room("hazard", true)
		_check("the shifted chapel is hazard_shift: the library on the left, the one-way shutter to the organ on the right",
			mh.file_id == "hazard_shift" and mh.head.get("left", "") == "library_shift" and mh.head.get("right", "") == "timemachine_shift", "file=%s" % mh.file_id)
		for r in [mc, ml, mh]:
			r.queue_free()
		# the shifted way back: chapel -> library -> church -> lab -> well -> vault (map.md section 4)
		await _goto("hazard", "right")
		p = main.player
		var d = main.room.doors["left"]
		p.global_position = Vector2(70.0, d.feet().y)
		await _frames(6)
		Input.action_press("left")
		await _until_room("library", 300)
		Input.action_release("left")
		await _frames(30)
		p = main.player
		_check("chapel -> shifted library, arriving at its top-right door", main.room_name == "library" and main.room.file_id == "library_shift"
			and p.global_position.x > main.room.size.x - 60.0 and p.global_position.y < 220.0,
			"room=%s file=%s x=%.0f y=%.0f" % [main.room_name, main.room.file_id, p.global_position.x, p.global_position.y])
		d = main.room.doors["right"]
		_check("the shifted library's bottom-right door leads to the shifted church", d.to == "church_shift", d.to)
		p.global_position = Vector2(main.room.size.x - 90.0, d.feet().y)
		p.velocity = Vector2.ZERO
		await _frames(20)
		Input.action_press("right")
		await _until_room("church", 300)
		Input.action_release("right")
		await _frames(30)
		p = main.player
		_check("library -> shifted church, arriving at its left door", main.room_name == "church" and main.room.file_id == "church_shift" and p.global_position.x < 60.0,
			"room=%s x=%.0f" % [main.room_name, p.global_position.x])
		d = main.room.doors["right"]
		p.global_position = Vector2(main.room.size.x - 90.0, d.feet().y)
		await _frames(10)
		Input.action_press("right")
		await _until_room("lab", 300)
		Input.action_release("right")
		await _frames(30)
		p = main.player
		_check("church -> shifted lab, arriving at its left door", main.room_name == "lab" and main.room.file_id == "lab_shift" and p.global_position.x < 60.0,
			"room=%s x=%.0f" % [main.room_name, p.global_position.x])
		d = main.room.doors["right"]
		p.global_position = Vector2(main.room.size.x - 90.0, d.feet().y)
		await _frames(10)
		Input.action_press("right")
		await _until_room("shaft", 300)
		Input.action_release("right")
		await _frames(30)
		p = main.player
		_check("lab -> the drained well, arriving at its left door", main.room_name == "shaft" and main.room.file_id == "shaft_shift" and p.global_position.x < 60.0,
			"room=%s x=%.0f" % [main.room_name, p.global_position.x])
		up_span = main.room.up_span
		p.global_position = Vector2((up_span.x + up_span.y) / 2.0, 6.0)
		p.velocity = Vector2(0.0, -250.0)
		await _frames(5)
		_check("the drained well -> the sealed station", main.room_name == "vault" and main.room.file_id == "vault_shift", main.room.file_id)

	else:
		_check("the shift runs and the after-shift rooms can be walked", false, "the world did not shift (see the YES check above)")

	# ---- the tester keys 7, 8, 9, 0 (map.md section 2 rows 7-10) ----
	var seen: Array = []
	for k in ["room7", "room8", "room9", "room10"]:
		await _tap(k, 2)
		await _frames(4)
		seen.append(main.room_name)
	_check("keys 7, 8, 9, 0 go to the ordnance ward, the hallway, the Pallbearer and the reliquary",
		seen == ["ordnance", "hallway", "boss", "gallery"], str(seen))
	_check("the pause menu lists all fifteen before-shift rooms", main.touch.ROOM_LABELS.size() == 15, "")
