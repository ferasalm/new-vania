# PROTOTYPE - NOT FOR PRODUCTION
# tests_dev/d19_kennel_wolf.gd - lane 06 gate: the werewolf fight in the Kennel.
# The user's asks (ledger B2, C9; handoff 2026-11-21 assets-stairs-werewolf):
#   - she reaches the Kennel by the real route (up through the hole in the lab's ceiling)
#   - no wall jump lies around before the fight; the werewolf is there
#   - the fight seals the hole she came in by; it opens again when he dies
#   - he clings, pounces and ricochets, and a landing leaves him stunned (her opening)
#   - his death gives exactly one wall jump; taking it lets her latch a wall
#   - beaten stays beaten across re-entry and a save; an old save that already has the
#     wall jump is neither stuck nor given a second one
# Written before the boss existed: every check must fail on the old Kennel.
# Run: godot --headless --path . --fixed-fps 60 res://tests_dev/d19_kennel_wolf.tscn
extends Node

var main: Node = null
var passed := 0
var failed := 0


func _ready() -> void:
	G.peace = false
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _frames(30)
	_fresh()
	await _route_and_fight()
	await _reentry_and_save()
	await _beaten_not_taken()
	await _old_save()
	var ok := failed == 0 and passed > 0
	print("d19_kennel_wolf %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _check(nm: String, ok: bool, detail: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("%s  %s  (%s)" % ["ok  " if ok else "FAIL", nm, detail])


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _fresh() -> void:
	# a new game: no wall jump, the werewolf not beaten, nothing taken
	W.restore({})
	R.restore({})
	G.shifted = false


func _wolf():
	var b = main.boss
	if b != null and is_instance_valid(b) and String(b.get("boss_id")) == "unmuzzled":
		return b
	return null


func _wall_jump_pickups() -> int:
	var n := 0
	for it in main.loot.live:
		if it != null and is_instance_valid(it) and String(it.get("item_id")) == "wall_jump":
			n += 1
	return n


func _keep_alive() -> void:
	var p = main.player
	if p != null and is_instance_valid(p):
		p.hp = R.max_hp()
		p.invuln = 1.0


func _up_from_lab() -> void:
	# the real route: stand under the lab's ceiling hole and go up through it
	await main.debug_enter("lab", "left", false)
	await _frames(10)
	var r = main.room
	var p = main.player
	p.global_position = Vector2((r.up_span.x + r.up_span.y) / 2.0, 1.0)
	p.velocity = Vector2(0, -300)
	await _frames(20)


func _drop_through_hole() -> void:
	# stand on the Kennel's floor hole and press Down + Jump, as a player would
	var r = main.room
	var p = main.player
	p.global_position = Vector2((r.down_span.x + r.down_span.y) / 2.0, r.size.y - 18.0)
	p.velocity = Vector2.ZERO
	await _frames(20)
	Input.action_press("down")
	await _frames(2)
	Input.action_press("jump")
	await _frames(4)
	Input.action_release("jump")
	await _frames(50)
	Input.action_release("down")
	await _frames(10)


func _sealed() -> bool:
	var d = main.room.doors.get("down")
	return d != null and is_instance_valid(d) and bool(d.get("locked"))


func _route_and_fight() -> void:
	await _up_from_lab()
	_check("the hole in the lab's ceiling leads up into the Kennel", main.room_name == "kennel", "room=%s" % main.room_name)
	if main.room_name != "kennel":
		return
	var wolf = _wolf()
	_check("the werewolf is in the Kennel", wolf != null, "boss=%s" % str(main.boss))
	_check("no wall jump lies in the Kennel before the fight", _wall_jump_pickups() == 0 and not main.has_latch,
		"pickups=%d latch=%s" % [_wall_jump_pickups(), str(main.has_latch)])
	if wolf == null:
		return
	# she walks out of the hole into the room: the fight starts and the hole seals
	var p = main.player
	p.global_position = Vector2(200, main.room.size.y - 34.0)
	p.velocity = Vector2.ZERO
	await _frames(30)
	_check("stepping into the room starts the fight", bool(wolf.started), "started=%s" % str(wolf.started))
	_check("the hole she came in by is sealed while he fights", _sealed(), "doors=%s" % str(main.room.doors.keys()))
	_keep_alive()
	await _drop_through_hole()
	_check("Down + Jump on the sealed hole does not leave the Kennel", main.room_name == "kennel", "room=%s" % main.room_name)
	# the fight itself
	_check("he has the health from tuning (wolf_hp)", float(wolf.max_hp()) == T.v("wolf_hp"),
		"max=%s wolf_hp=%s" % [str(wolf.max_hp()), str(T.v("wolf_hp"))])
	var states := {}
	var stun_best := 0.0
	var stun_run := 0.0
	var last := ""
	p.global_position = Vector2(190, main.room.size.y - 34.0)
	for i in 1200:
		_keep_alive()
		var st := String(wolf.state)
		states[st] = true
		if st == last:
			stun_run += 1.0 / 60.0
		else:
			if last.contains("stun"):
				stun_best = maxf(stun_best, stun_run)
			stun_run = 1.0 / 60.0
		last = st
		await _frames(1)
	var missing := []
	for s in ["cling", "pounce", "ricochet"]:
		if not states.has(s):
			missing.append(s)
	_check("he clings to walls, pounces and ricochets", missing.is_empty(), "seen=%s missing=%s" % [str(states.keys()), str(missing)])
	_check("a landing leaves him stunned for wolf_land_stun", stun_best >= T.v("wolf_land_stun") - 0.25,
		"best=%.2f want=%.2f" % [stun_best, T.v("wolf_land_stun")])
	_check("no wall jump appears during the fight", _wall_jump_pickups() == 0 and not main.has_latch, "pickups=%d" % _wall_jump_pickups())
	wolf.hp = wolf.max_hp() * 0.49
	await _frames(3)
	_check("he changes stage under half health", int(wolf.stage()) == 2, "stage=%s" % str(wolf.stage()))
	# her sword finishes him
	wolf.take_hit(99999.0, 1)
	var died := false
	for i in 400:
		_keep_alive()
		if _wolf() == null:
			died = true
			break
		await _frames(1)
	await _frames(10)
	_check("he dies and the fight ends", died and W.flag("beaten_unmuzzled"), "died=%s flag=%s" % [str(died), str(W.flag("beaten_unmuzzled"))])
	_check("the hole opens again when he dies", not _sealed(), "")
	_check("his death leaves exactly one wall jump", _wall_jump_pickups() == 1, "pickups=%d" % _wall_jump_pickups())
	for it in main.loot.live:
		if it != null and is_instance_valid(it) and String(it.get("item_id")) == "wall_jump":
			it.take()
			break
	var card_shown := false
	for i in 120:
		if main.card != null and main.card.active:
			card_shown = true
			break
		await _frames(1)
	_check("the wall jump's card shows what she got", card_shown, "")
	# she closes the card with Up, as a player does
	await _frames(60)
	Input.action_press("up")
	await _frames(2)
	Input.action_release("up")
	await _frames(10)
	_check("taking it gives the wall latch", main.has_latch and R.count("wall_jump") <= 1 and _wall_jump_pickups() == 0,
		"latch=%s count=%d" % [str(main.has_latch), R.count("wall_jump")])
	await _drop_through_hole()
	_check("after the fight the hole takes her back down to the lab", main.room_name == "lab",
		"room=%s at=%s state=%s" % [main.room_name, str(main.player.global_position), str(main.player.state)])


func _reentry_and_save() -> void:
	await _up_from_lab()
	_check("re-entering after the win: no werewolf, no seal, no second wall jump",
		main.room_name == "kennel" and _wolf() == null and not _sealed() and _wall_jump_pickups() == 0,
		"room=%s wolf=%s pickups=%d" % [main.room_name, str(_wolf()), _wall_jump_pickups()])
	# a save and a load: the snapshots are what the save file holds
	var ws: Dictionary = W.snapshot()
	var rs: Dictionary = R.snapshot()
	_fresh()
	W.restore(ws)
	R.restore(rs)
	await _up_from_lab()
	_check("after a save and load the werewolf stays beaten and the wall jump stays hers",
		_wolf() == null and _wall_jump_pickups() == 0 and main.has_latch and not _sealed(),
		"wolf=%s pickups=%d latch=%s" % [str(_wolf()), _wall_jump_pickups(), str(main.has_latch)])


func _beaten_not_taken() -> void:
	# she won but left (or died) before taking it: it waits for her
	_fresh()
	W.set_flag("beaten_unmuzzled", true)
	await _up_from_lab()
	_check("beaten but not taken: the wall jump waits for her, once, with no fight",
		_wolf() == null and _wall_jump_pickups() == 1 and not _sealed(),
		"wolf=%s pickups=%d" % [str(_wolf()), _wall_jump_pickups()])


func _old_save() -> void:
	# a save from before the werewolf existed: she already owns the wall jump
	_fresh()
	R.set_owned("wall_jump", true)
	await _up_from_lab()
	_check("an old save that owns the wall jump meets no fight and no second wall jump",
		_wolf() == null and _wall_jump_pickups() == 0 and not _sealed() and R.count("wall_jump") <= 1,
		"wolf=%s pickups=%d count=%d" % [str(_wolf()), _wall_jump_pickups(), R.count("wall_jump")])
	await _drop_through_hole()
	_check("an old save can still leave the Kennel by the hole", main.room_name == "lab", "room=%s" % main.room_name)
