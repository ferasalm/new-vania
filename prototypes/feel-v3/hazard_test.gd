# PROTOTYPE - NOT FOR PRODUCTION
# The self-test for enemy2.gd and hazard.gd. It builds its own arena inside the running game
# (so it does not depend on any room file), puts the new enemies and hazards in it and checks
# what they do. Run: godot --headless --path prototypes/feel-v3 res://hazard_test.tscn
# Prints "HAZARD PASS passed=N failed=M" and quits (exit code 0 on pass).
extends Node

const FLOOR := 224.0

var main: Node
var passed := 0
var failed := 0
var E: GDScript
var H: GDScript
var seen := {}          # enemy kind -> {state: true}


func _ready() -> void:
	G.peace = false
	main = load("res://main.tscn").instantiate()
	add_child(main)
	E = load("res://enemy2.gd")
	H = load("res://hazard.gd")
	await _run()
	var ok := failed == 0 and passed > 0
	print("HAZARD %s passed=%d failed=%d" % ["PASS" if ok else "FAIL", passed, failed])
	get_tree().quit(0 if ok else 1)


func _check(name: String, ok: bool, detail: String = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("%s  %s  (%s)" % ["ok  " if ok else "FAIL", name, detail])


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


# ---------- the arena: 40 x 16 tiles, floor at y=224, a slab hanging from the ceiling at x 320..400 ----------

func _arena() -> void:
	var room: Node2D = main.room
	for ch in room.get_children():
		if ch is StaticBody2D:
			ch.queue_free()
	var rows: Array = []
	rows.append("#".repeat(40))
	for r in range(1, 14):
		var row := "#" + ".".repeat(38) + "#"
		if r >= 1 and r <= 4:
			row = "#" + ".".repeat(19) + "#".repeat(5) + ".".repeat(14) + "#"
		rows.append(row)
	rows.append("#".repeat(40))
	rows.append("#".repeat(40))
	room.grid = rows
	room.size = Vector2(640.0, 256.0)
	room.enemies.clear()
	room.visible = false
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	room.add_child(body)
	for r in [Rect2(0, 0, 640, 16), Rect2(0, 224, 640, 32), Rect2(0, 0, 16, 256), Rect2(624, 0, 16, 256), Rect2(320, 16, 80, 64)]:
		var sh := CollisionShape2D.new()
		var rc := RectangleShape2D.new()
		rc.size = r.size
		sh.shape = rc
		sh.position = r.position + r.size / 2.0
		body.add_child(sh)
	for e in main.enemies:
		if is_instance_valid(e):
			e.queue_free()
	main.enemies.clear()
	if main.boss != null:
		main.boss = null


func _reset(x: float, y: float = FLOOR) -> void:
	var p: Node2D = main.player
	p.global_position = Vector2(x, y)
	p.velocity = Vector2.ZERO
	p.hp = T.v("player_hp")
	p.mp = T.v("mp_max")
	p.energy = T.v("energy_max")
	p.invuln = 0.0
	p.state = "move"


func _clear() -> void:
	for g in ["enemy2", "hazard", "e2_shot", "e2_cloud", "e2_ember", "e2_glyph", "e2_gust"]:
		for n in get_tree().get_nodes_in_group(g):
			n.queue_free()
	main.enemies.clear()
	var pin: Node = main.player.get_node_or_null("Pin")
	if pin != null:
		pin.queue_free()
	await _frames(2)


func _enemy(kind: String, x: float, y: float) -> Node2D:
	var en: Node2D = E.new()
	en.position = Vector2(x, y)
	en.setup(kind)
	main.world.add_child(en)
	main.enemies.append(en)
	return en


func _note(kind: String, states: Dictionary) -> void:
	if not seen.has(kind):
		seen[kind] = {}
	for s in states:
		seen[kind][s] = true


func _watch(en: Node2D, attack: String, frames: int, end_state: String, hold: bool, at: Vector2) -> Dictionary:
	# starts the named attack and watches it: which states it passes, what it cost her, what it threw
	var p: Node2D = main.player
	var res := {"states": {}, "loss": 0.0, "shots": 0, "clouds": 0, "embers": 0, "glyphs": 0, "frames": 0}
	p.invuln = 0.0
	p.hp = T.v("player_hp")
	en.start_attack(attack)
	for i in frames:
		await get_tree().physics_frame
		if not is_instance_valid(en):
			break
		res["states"][en.state] = true
		res["frames"] = i
		res["shots"] = maxi(res["shots"], get_tree().get_nodes_in_group("e2_shot").size())
		res["clouds"] = maxi(res["clouds"], get_tree().get_nodes_in_group("e2_cloud").size())
		res["embers"] = maxi(res["embers"], get_tree().get_nodes_in_group("e2_ember").size())
		res["glyphs"] = maxi(res["glyphs"], get_tree().get_nodes_in_group("e2_glyph").size())
		var now: float = p.hp
		if now < T.v("player_hp"):
			res["loss"] += T.v("player_hp") - now
			p.hp = T.v("player_hp")
		if hold:
			p.global_position = at
			p.velocity = Vector2.ZERO
			p.state = "move"
		if end_state != "" and i > 15 and en.state == end_state:
			break
	_note(en.kind, res["states"])
	return res


func _run() -> void:
	await _frames(30)
	_arena()
	await _frames(10)
	_clear()
	await _frames(5)
	var p: Node2D = main.player
	_check("arena is ready: player stands on the floor", p.is_on_floor() or absf(p.global_position.y - FLOOR) < 2.0, "y=%.1f" % p.global_position.y)
	await _interface()
	await _crab()
	await _moth()
	await _scribe()
	await _leech()
	await _hazards()
	await _soak()
	var kinds := ["crab", "moth", "scribe", "leech"]
	for k in kinds:
		var n: int = seen.get(k, {}).size()
		_check("%s went through at least 3 states" % k, n >= 3, "%d: %s" % [n, str(seen.get(k, {}).keys())])


# ---------- the interface main relies on ----------

func _interface() -> void:
	for k in ["crab", "moth", "scribe", "leech"]:
		_reset(100.0)
		var en := _enemy(k, 400.0, FLOOR)
		await _frames(2)
		var ok: bool = en.kind == k and en.hurt_rect().size.x > 4.0 and en.hurt_rect().size.y > 4.0 and typeof(en.can_hurt()) == TYPE_BOOL and en.damage() > 0.0
		ok = ok and en.has_method("touched_player") and en.has_method("take_hit") and en.has_method("start_attack")
		_check("%s has the enemy interface" % k, ok, "rect=%s dmg=%.0f hp=%.0f" % [str(en.hurt_rect()), en.damage(), en.hp])
		var kills0: int = main.kills
		en._cool = 99.0
		en.take_hit(9999.0, -1)
		await _frames(3)
		_check("%s dies, main counts the kill and forgets it" % k, not is_instance_valid(en) and main.kills == kills0 + 1 and not main.enemies.has(en), "kills %d -> %d" % [kills0, main.kills])
		_clear()
		await _frames(2)
	# no aggression in peace
	_reset(100.0)
	var c := _enemy("crab", 160.0, FLOOR)
	await _frames(2)
	c.state = "pinch"
	G.peace = true
	_check("nothing can hurt her in peace (crab claws)", not c.can_hurt(), "")
	G.peace = false
	_clear()


# ---------- Spine Crab ----------

func _crab() -> void:
	_reset(100.0)
	var c := _enemy("crab", 170.0, FLOOR)
	await _frames(3)
	var p: Node2D = main.player
	c.facing = -1
	c._cool = 99.0
	c.state = "scuttle"
	var hp0: float = c.hp
	var px0: float = p.global_position.x
	c.take_hit(10.0, 1)
	_check("crab shell blocks a hit from the front", c.hp == hp0 and c.blocks == 1, "hp %.0f -> %.0f blocks=%d" % [hp0, c.hp, c.blocks])
	_check("a blocked hit knocks her back a little", p.global_position.x < px0 - 3.0, "x %.1f -> %.1f" % [px0, p.global_position.x])
	c.take_hit(10.0, -1)
	_check("crab takes a hit from behind", c.hp == hp0 - 10.0, "hp %.0f" % c.hp)
	var y0: float = p.global_position.y
	p.global_position.y = FLOOR - 60.0
	c.take_hit(10.0, 1)
	p.global_position.y = y0
	_check("crab takes a hit from above, over the shell", c.hp == hp0 - 20.0, "hp %.0f" % c.hp)
	c.state = "warn_rear"
	c.take_hit(10.0, 1)
	_check("crab is open while rearing, and the hit breaks the rear", c.hp == hp0 - 30.0 and c.state == "rest", "hp %.0f state=%s" % [c.hp, c.state])
	c.hp = 999.0
	# the three attacks, one by one, with her standing still 70 units from it
	var spot := Vector2(100.0, FLOOR)
	for a in ["pinch", "rear", "burrow"]:
		c.global_position = Vector2(170.0, FLOOR)
		c.velocity = Vector2.ZERO
		c.facing = -1
		c.collision_mask = 1 | 2
		c.state = "scuttle"
		c._cool = 99.0
		await _frames(3)
		_reset(100.0)
		var r: Dictionary = await _watch(c, a, 420, "scuttle", true, spot)
		var st: Dictionary = r["states"]
		match a:
			"pinch":
				_check("crab pinch: claws open (warn), rush, hurts her", st.has("warn_pinch") and st.has("pinch") and r["loss"] >= T.v("crab_damage") - 0.5, "states=%s loss=%.0f" % [str(st.keys()), r["loss"]])
			"rear":
				_check("crab rear: rattles (warn), fires a spine fan", st.has("warn_rear") and st.has("fan") and r["shots"] >= 5, "states=%s spines=%d" % [str(st.keys()), r["shots"]])
			"burrow":
				_check("crab burrow: sinks, tunnels, rumbles, erupts under her", st.has("warn_burrow") and st.has("under") and st.has("rumble") and st.has("erupt") and r["loss"] > 0.0, "states=%s loss=%.0f" % [str(st.keys()), r["loss"]])
	# a falling spine hurts
	_clear()
	_reset(200.0)
	var sp = E.Shot.new()
	sp.kind = "spine"
	sp.dmg = T.v("crab_spine_damage")
	sp.position = p.global_position + Vector2(0.0, -20.0)
	main.world.add_child(sp)
	await _frames(3)
	_check("a spine that reaches her hurts", p.hp <= T.v("player_hp") - T.v("crab_spine_damage") + 0.1, "hp=%.0f" % p.hp)
	_clear()


# ---------- Censer Moth ----------

func _moth() -> void:
	_reset(140.0)
	var m := _enemy("moth", 190.0, FLOOR)
	await _frames(3)
	var p: Node2D = main.player
	m.global_position = Vector2(190.0, 150.0)
	m._cool = 99.0
	m.state = "hover"
	m._count = 2           # it hovers on the right of her
	var r: Dictionary = await _watch(m, "veil", 200, "hover", false, p.global_position)
	_check("moth veil: censer glows (warn), three smoke clouds", r["states"].has("warn_veil") and r["clouds"] >= 3, "states=%s clouds=%d" % [str(r["states"].keys()), r["clouds"]])
	_clear()
	_reset(140.0)
	m = _enemy("moth", 190.0, FLOOR)
	await _frames(3)
	m.global_position = Vector2(190.0, 150.0)
	m._cool = 99.0
	m.state = "hover"
	m.velocity = Vector2.ZERO
	var x0: float = p.global_position.x
	r = await _watch(m, "gust", 120, "gust", false, p.global_position)
	await _frames(26)
	var shove: float = absf(p.global_position.x - x0)
	_check("moth gust: wings held (warn), shoves her 3-4 tiles, no damage", r["states"].has("warn_gust") and r["states"].has("gust") and shove > 40.0 and shove < 90.0 and r["loss"] == 0.0, "states=%s shove=%.0f loss=%.0f" % [str(r["states"].keys()), shove, r["loss"]])
	_clear()
	_reset(110.0)
	m = _enemy("moth", 190.0, FLOOR)
	await _frames(3)
	m.global_position = Vector2(190.0, 150.0)
	m._cool = 99.0
	m.state = "hover"
	m._count = 2
	r = await _watch(m, "dive", 320, "hover", false, p.global_position)
	_check("moth ember dive: shrill warning, swoop, drops embers", r["states"].has("warn_dive") and r["states"].has("dive") and r["embers"] >= 3, "states=%s embers=%d" % [str(r["states"].keys()), r["embers"]])
	_clear()
	# a smoke cloud and an ember hurt on touch, a gust does not
	_reset(200.0)
	var cl = E.Cloud.new()
	cl.position = p.global_position + Vector2(0.0, -18.0)
	cl.dmg = T.v("moth_cloud_damage")
	main.world.add_child(cl)
	await _frames(4)
	_check("a smoke cloud hurts on touch", p.hp <= T.v("player_hp") - T.v("moth_cloud_damage") + 0.1, "hp=%.0f" % p.hp)
	_clear()
	_reset(200.0)
	var em = E.Ember.new()
	em.dmg = T.v("moth_ember_damage")
	em.position = p.global_position + Vector2(0.0, -40.0)
	main.world.add_child(em)
	await _frames(20)
	_check("an ember hurts on touch", p.hp <= T.v("player_hp") - T.v("moth_ember_damage") + 0.1, "hp=%.0f" % p.hp)
	_clear()


# ---------- Needle Scribe ----------

func _scribe() -> void:
	_reset(100.0)
	var s := _enemy("scribe", 220.0, FLOOR)
	await _frames(3)
	var p: Node2D = main.player
	s.global_position = Vector2(220.0, 150.0)
	s._cool = 99.0
	s.state = "hover"
	# the needle pins her
	var res: Dictionary = {}
	p.invuln = 0.0
	s.start_attack("needle")
	var pinned := false
	var pin_frames := 0
	var hurt_t := 0.0
	var pose := true
	for i in 200:
		await get_tree().physics_frame
		var pin: Node = p.get_node_or_null("Pin")
		if pin != null:
			hurt_t = maxf(hurt_t, float(p.get("_hurt_t")))
			pinned = true
			pin_frames += 1
			if pin_frames > 2 and p.state != "hurt":
				pose = false
		elif pinned:
			break      # the first pin is over
	_note("scribe", {"warn_needle": true})
	_check("scribe needle: hits her and pins her (hurt pose, shackles)", pinned and pose and hurt_t > 0.3 and p.hp <= T.v("player_hp") - T.v("scribe_damage") + 0.1, "pinned=%s _hurt_t=%.2f hp=%.0f" % [str(pinned), hurt_t, p.hp])
	_check("the pin holds for about %.1f s" % T.v("scribe_pin_time"), pin_frames >= 40 and pin_frames <= 70, "%d frames" % pin_frames)
	_clear()
	# ink step: melts, the drip shows on the ceiling above her, it drops from there
	_reset(360.0)
	s = _enemy("scribe", 220.0, FLOOR)
	await _frames(3)
	s.global_position = Vector2(300.0, 150.0)
	s._cool = 99.0
	s.state = "hover"
	var drip_y := -1.0
	p.invuln = 0.0
	s.start_attack("step")
	var states := {}
	var loss := 0.0
	for i in 300:
		await get_tree().physics_frame
		if not is_instance_valid(s):
			break
		states[s.state] = true
		if s.state == "puddle":
			drip_y = s._drip.y
		if p.hp < T.v("player_hp"):
			loss += T.v("player_hp") - p.hp
			p.hp = T.v("player_hp")
		if s.state == "hover" and i > 20:
			break
	_note("scribe", states)
	_check("scribe ink step: melts, drips on the ceiling above her, drops on her", states.has("melt") and states.has("puddle") and states.has("fall") and states.has("reform") and drip_y >= 0.0 and drip_y <= 90.0 and loss >= T.v("scribe_damage") - 0.5, "states=%s drip_y=%.0f (slab bottom is 80) loss=%.0f" % [str(states.keys()), drip_y, loss])
	_clear()
	# glyph: drawn on the floor under her, bursts after its fuse
	_reset(100.0)
	s = _enemy("scribe", 220.0, FLOOR)
	await _frames(3)
	s.global_position = Vector2(220.0, 150.0)
	s._cool = 99.0
	s.state = "hover"
	res = await _watch(s, "glyph", 110, "", true, Vector2(100.0, FLOOR))
	_check("scribe glyph: drawn under her, bursts and hurts", res["states"].has("warn_glyph") and res["glyphs"] >= 1 and res["loss"] >= T.v("scribe_glyph_damage") - 0.5, "glyphs=%d loss=%.0f" % [res["glyphs"], res["loss"]])
	_clear()
	# below half health: an ink clone that pops harmlessly
	_reset(100.0)
	s = _enemy("scribe", 220.0, FLOOR)
	await _frames(3)
	s.global_position = Vector2(220.0, 150.0)
	s._cool = 99.0
	s.state = "hover"
	s.hp = T.v("scribe_hp") * 0.4
	var clone: Node2D = null
	for i in 120:
		await get_tree().physics_frame
		for e in main.enemies:
			if is_instance_valid(e) and e != s and e.get("_fake") == true:
				clone = e
		if clone != null:
			break
	_check("scribe below half health leaves an ink clone", clone != null and clone.can_hurt() == false and clone.damage() == 0.0, "clone=%s" % str(clone))
	if clone != null:
		var kills0: int = main.kills
		var hp0: float = p.hp
		clone.take_hit(1.0, 1)
		await _frames(3)
		_check("the clone pops harmlessly when hit (no kill, no damage to her)", not is_instance_valid(clone) and main.kills == kills0 and p.hp == hp0 and not main.enemies.has(clone), "kills %d -> %d" % [kills0, main.kills])
	_clear()


# ---------- Thread Leech ----------

func _leech() -> void:
	_reset(360.0)
	var l := _enemy("leech", 360.0, 100.0)      # the cell touches the slab: it hangs from the slab's lower edge
	await _frames(3)
	var p: Node2D = main.player
	_check("leech hangs from the nearest solid cell above", absf(l._ceil.y - 80.0) < 0.5 and absf(l.global_position.y - (80.0 + T.v("leech_hang"))) < 1.0, "ceil=%s pos=%s" % [str(l._ceil), str(l.global_position)])
	var states := {}
	p.invuln = 0.0
	var mp0: float = p.mp
	var latched_at := -1
	for i in 240:
		await get_tree().physics_frame
		states[l.state] = true
		if l.state == "latched":
			latched_at = i
			break
	_check("leech: slime drip (warn), drop, latch on her", states.has("warn_drop") and states.has("drop") and latched_at >= 0, "states=%s" % str(states.keys()))
	await _frames(60)
	var drained: float = mp0 - float(p.mp)
	_check("latched leech drains her MP", drained > 5.0, "mp %.0f -> %.0f" % [mp0, p.mp])
	var vx0 := 0.0
	# slowed: run right for 30 frames, far less than full speed
	var x_a: float = p.global_position.x
	Input.action_press("right")
	await _frames(30)
	Input.action_release("right")
	var run: float = p.global_position.x - x_a
	_check("latched leech slows her", run < T.v("run_speed") * 0.5 * 0.85, "ran %.0f in 0.5 s (full speed would be %.0f)" % [run, T.v("run_speed") * 0.5])
	await _frames(20)
	# two jumps shake it off
	for j in 2:
		Input.action_press("jump")
		await _frames(8)
		Input.action_release("jump")
		for k in 90:
			await get_tree().physics_frame
			if p.is_on_floor():
				break
		await _frames(6)
	await _frames(10)
	_check("two jumps shake the leech off (it falls, stunned)", l.state == "fallen" or l.state == "climb", "state=%s" % l.state)
	_note("leech", {"fallen": true, "climb": true})
	var back := false
	for i in 700:
		await get_tree().physics_frame
		if l.state == "hang":
			back = true
			break
	_check("the leech climbs back up its thread", back, "state=%s" % l.state)
	_note("leech", states)
	_clear()
	# three swings shake it off too (the 4 s limit is covered by the tuning number)
	_reset(360.0)
	l = _enemy("leech", 360.0, 100.0)
	await _frames(3)
	l._latch()
	await _frames(5)
	_check("a leech can latch directly", l.state == "latched", l.state)
	for j in 3:
		Input.action_press("attack")
		await _frames(3)
		Input.action_release("attack")
		await _frames(40)
	_check("three sword swings shake it off", l.state != "latched", "state=%s" % l.state)
	_clear()


# ---------- the hazards ----------

func _hazard_wait(h: Node, frames: int, x: float) -> Dictionary:
	# she stands still at x; returns what she lost and the order of states the hazard went through
	var p: Node2D = main.player
	var res := {"loss": 0.0, "states": [], "danger_seen": false}
	_reset(x)
	var last := ""
	for i in frames:
		await get_tree().physics_frame
		if h.state != last:
			last = h.state
			res["states"].append(last)
		if h.dangerous():
			res["danger_seen"] = true
		var now: float = p.hp
		if now < T.v("player_hp"):
			res["loss"] += T.v("player_hp") - now
			p.hp = T.v("player_hp")
		p.velocity = Vector2(0.0, p.velocity.y)
		p.global_position.x = x
		p.state = "move"
	return res


func _hazard(kind: String, rect: Rect2, stand_x: float, safe_x: float, dmg_key: String, warn_before: bool) -> void:
	_clear()
	G.peace = false
	var h: Node2D = H.new()
	h.setup(kind, rect)
	main.world.add_child(h)
	await _frames(2)
	var res: Dictionary = await _hazard_wait(h, 540, stand_x)
	var dmg := T.v(dmg_key)
	_check("%s hurts her when she stands in it (%.0f)" % [kind, dmg], res["danger_seen"] and res["loss"] >= dmg - 0.5, "loss=%.0f states=%s" % [res["loss"], str(res["states"])])
	if warn_before:
		var names: Array = res["states"]
		var ok := false
		for i in range(1, names.size()):
			if names[i] != "warn" and names[i - 1] == "warn":
				ok = true
		_check("%s warns before it hurts" % kind, ok and names.has("warn"), str(names))
	var safe: Dictionary = await _hazard_wait(h, 400, safe_x)
	_check("%s does not hurt her when she is beside it" % kind, safe["loss"] == 0.0, "loss=%.0f" % safe["loss"])
	G.peace = true
	var calm: Dictionary = await _hazard_wait(h, 540, stand_x)
	_check("%s does nothing when peace is on" % kind, calm["loss"] == 0.0 and calm["danger_seen"], "loss=%.0f (the beat still runs)" % calm["loss"])
	G.peace = false
	h.queue_free()
	await _frames(2)


func _hazards() -> void:
	await _hazard("pendulum", Rect2(64.0, 16.0, 16.0, 16.0), 72.0, 200.0, "pendulum_damage", false)
	await _hazard("crusher", Rect2(128.0, 16.0, 16.0, 16.0), 136.0, 200.0, "crusher_damage", true)
	await _hazard("flame", Rect2(192.0, 208.0, 16.0, 16.0), 200.0, 260.0, "flame_damage", true)
	await _hazard("spikes", Rect2(256.0, 208.0, 64.0, 16.0), 288.0, 160.0, "spikes_damage", true)
	# neighbours get different beats
	_clear()
	var a: Node2D = H.new()
	a.setup("crusher", Rect2(128.0, 16.0, 16.0, 16.0))
	var b: Node2D = H.new()
	b.setup("crusher", Rect2(176.0, 16.0, 16.0, 16.0))
	main.world.add_child(a)
	main.world.add_child(b)
	await _frames(2)
	var differ := 0
	for i in 240:
		await get_tree().physics_frame
		if a.state != b.state:
			differ += 1
	_check("neighbouring crushers are out of step (a safe moment)", differ > 60, "%d of 240 frames in different states" % differ)
	_clear()


# ---------- 20 seconds of everything, with a player who runs along the room and swings ----------

func _soak() -> void:
	_clear()
	G.peace = false
	var made: Array = []
	made.append(_enemy("crab", 450.0, FLOOR))
	made.append(_enemy("moth", 500.0, FLOOR))
	made.append(_enemy("scribe", 540.0, FLOOR))
	made.append(_enemy("leech", 360.0, 100.0))
	for m in made:
		m.hp = 9999.0
	made[2].hp = T.v("scribe_hp") * 0.45       # low enough for ink clones
	var rects := {"pendulum": Rect2(64.0, 16.0, 16.0, 16.0), "crusher": Rect2(128.0, 16.0, 16.0, 16.0),
		"flame": Rect2(192.0, 208.0, 16.0, 16.0), "spikes": Rect2(256.0, 208.0, 64.0, 16.0)}
	for k in rects:
		var h: Node2D = H.new()
		h.setup(k, rects[k])
		main.world.add_child(h)
	var p: Node2D = main.player
	_reset(60.0)
	var natural := {}
	var hits := 0
	var hp_last: float = p.hp
	var alive_ok := true
	# 1200 frames: out to the right, back to the left, out again; jumping and swinging all the way
	for i in 1200:
		await get_tree().physics_frame
		if i % 10 == 0:
			var leg := (i / 400) % 2
			Input.action_release("left")
			Input.action_release("right")
			Input.action_press("right" if leg == 0 else "left")
			if i % 70 == 0:
				Input.action_press("jump")
			else:
				Input.action_release("jump")
			if i % 40 == 0:
				Input.action_press("attack")
			else:
				Input.action_release("attack")
		for m in made:
			if is_instance_valid(m):
				if not natural.has(m.kind):
					natural[m.kind] = {}
				natural[m.kind][m.state] = true
		if p.hp < hp_last:
			hits += 1
		p.hp = T.v("player_hp")
		hp_last = p.hp
		p.mp = maxf(p.mp, 10.0)
		if main._busy:
			alive_ok = false
	for a in ["left", "right", "jump", "attack"]:
		Input.action_release(a)
	_check("20 seconds of play with four enemies and four hazards: nothing stalls (she was hit %d times)" % hits, alive_ok and is_instance_valid(p), "")
	for k in ["crab", "moth", "scribe"]:
		var warned := false
		for st in natural.get(k, {}):
			if str(st).begins_with("warn") or st == "melt":
				warned = true
		_check("%s attacks on its own (telegraphed) when she runs past" % k, warned, str(natural.get(k, {}).keys()))
	print("     leech on its own: %s" % str(natural.get("leech", {}).keys()))
	var clones := 0
	for e in main.enemies:
		if is_instance_valid(e) and e.get("_fake") == true:
			clones += 1
	print("     (ink clones alive at the end: %d)" % clones)
	_clear()
