# PROTOTYPE - NOT FOR PRODUCTION
# Runs the prototype: loads a room, the hero, the enemies and the boss, resolves
# hits, walks her between rooms through the doors in the room edges, and owns the
# effects (sparks, dust, numbers, shake, the short hit pause), every flying shot,
# the special attack's blade wave, the blue MP orbs and the save terminal.
# The way through: church -> library -> save room -> lab -> (boss door) -> sanctum.
# Behind the church's lower door (opened by the library lever) lies the marrow well, the vault,
# the threshing chapel and the time machine, whose switch turns the whole world inside out.
extends Node2D

const Room := preload("res://room.gd")
const Player := preload("res://player.gd")
const Enemy := preload("res://enemy.gd")
const Boss := preload("res://boss.gd")
const Hud := preload("res://hud.gd")
const TuningPanel := preload("res://tuning_panel.gd")
const Touch := preload("res://touch.gd")
const Offline := preload("res://offline.gd")
const MachineDialog := preload("res://machine_dialog.gd")
const ShiftFx := preload("res://shift.gd")
const Props := preload("res://props.gd")
const ROOMS := ["church", "library", "save", "lab", "save2", "boss", "shaft", "vault", "hazard", "timemachine"]
const TITLES := {"church": "THE NAVE OF ASH", "library": "THE UNREAD STACKS", "save": "CACHE STATION 002",
	"lab": "SPECIMEN HALL", "save2": "CACHE STATION 003", "boss": "THE PALLBEARER", "shaft": "THE MARROW WELL",
	"vault": "CACHE STATION 004", "hazard": "THE THRESHING CHAPEL", "timemachine": "THE ORGAN OF HOURS"}
# where the number keys (and the pause menu) put her: the door side or marker that makes sense in that room
const ENTRY := {"church": "P", "shaft": "right", "hazard": "right", "timemachine": "K"}

var world: Node2D
var room: Node2D
var player: CharacterBody2D
var cam: Camera2D
var hud: CanvasLayer
var panel: CanvasLayer
var touch: Control
var boss: Node2D
var room_name := ""
var enemies: Array = []
var kills := 0
var waves: Array = []        # blade waves in flight: {node, dir, left, hit}
var orbs: Array = []         # blue MP orbs: {node, wait}
var shots: Array = []        # enemy shots in flight (Shot nodes)
var saved := false           # she has cached her memory at the terminal
var saved_room := ""         # the save room she last cached in (she is rebuilt there)
var has_latch := false       # the wall latch: found in the lab, before the warden
var unit := 1                # which Pandora this is: 001, then 002 after a reconstruction...
var hold := false            # she cannot move (she is being rebuilt in the capsule)
var offline: CanvasLayer     # the SYSTEM OFFLINE screen
var dialog: CanvasLayer      # the time machine's YES / NO question
var shift: CanvasLayer       # the after-the-shift picture filter
var has_elegy := false       # the Pallbearer's scythe is hers (E / SWAP work from then on)
var lever_library := false   # the library lever is pulled: the church's lower door opens
var bars_opened := false     # the bars lever is hit: the iron bars are up
var wall_broken := false     # the cracked wall is gone
var _scythe: Node2D          # the scythe pickup, floating where the boss fell
var _whisper_t := 0.0        # seconds to the next voice after the shift
var _relic: Node2D
var _marks: Array = []       # recent blade points, for "show hit areas"
var boss_beaten := false
var _shake_t := 0.0
var _shake_amp := 0.0
var _busy := false           # a door or death transition is running
var _entry := "P"


func _ready() -> void:
	G.main = self
	hud = Hud.new()
	add_child(hud)
	panel = TuningPanel.new()
	add_child(panel)
	var touch_layer := CanvasLayer.new()
	touch_layer.layer = 30
	add_child(touch_layer)
	touch = Touch.new()
	touch_layer.add_child(touch)
	offline = Offline.new()
	add_child(offline)
	dialog = MachineDialog.new()
	add_child(dialog)
	shift = ShiftFx.new()
	add_child(shift)
	T.set_v("weapon", 0.0)      # she starts with Dirge-042 only
	var start := "church"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("room=") and ROOMS.has(a.substr(5)):
			start = a.substr(5)
	enter(start, ENTRY.get(start, "left"))


func enter(next_room: String, spawn_key: String, from_room: String = "", carry: Dictionary = {}) -> void:
	# from_room: the room she came from. If it is this room's left or right neighbour she appears
	# on that side, whatever door key was asked for. carry: {"vy": speed, "face": facing} for holes.
	if world != null:
		world.queue_free()
	enemies.clear()
	waves.clear()
	orbs.clear()
	shots.clear()
	boss = null
	_scythe = null
	world = Node2D.new()
	add_child(world)
	room = Room.new()
	world.add_child(room)
	room.load_room(next_room, G.shifted)
	room_name = next_room
	if from_room != "":
		if room.head.get("left", "") == from_room:
			spawn_key = "left"
		elif room.head.get("right", "") == from_room:
			spawn_key = "right"
	_entry = spawn_key
	var fresh: bool = player == null or player.hp <= 0.0
	var keep_hp: float = T.v("player_hp") if fresh else player.hp
	var keep_mp: float = T.v("mp_max") if fresh else player.mp
	player = Player.new()
	var fallback: Vector2 = room.spawns.get("left", room.spawns.get("P", Vector2(64, 64)))
	player.position = room.spawns.get(spawn_key, fallback)
	world.add_child(player)
	player.hp = keep_hp
	player.mp = keep_mp
	player.facing = int(carry.get("face", -1 if spawn_key == "right" else 1))
	if carry.has("vy"):
		player.velocity.y = float(carry["vy"])
	if room.tunnels.get(spawn_key, false):
		player.force_slide(1 if spawn_key == "left" else -1)      # a low tunnel: she crawls out of it
	cam = Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(room.size.x)
	cam.limit_bottom = int(room.size.y)
	cam.position = Vector2(0, -28)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 12.0
	player.add_child(cam)
	cam.make_current()
	cam.reset_smoothing()
	for e in room.enemies:
		if Enemy.KINDS.has(e[0]):
			var en := Enemy.new()
			en.position = e[1] if not Enemy.KINDS[e[0]]["fly"] else e[1] - Vector2(0, 8)
			en.setup(e[0])
			world.add_child(en)
			enemies.append(en)
		elif ResourceLoader.exists("res://enemy2.gd"):
			# the marsh enemies (crab, moth, scribe, leech) live in enemy2.gd
			var en2: Node2D = load("res://enemy2.gd").new()
			en2.position = e[1]
			en2.setup(e[0])
			world.add_child(en2)
			enemies.append(en2)
	for h in room.hazards:
		if ResourceLoader.exists("res://hazard.gd"):
			var hz: Node2D = load("res://hazard.gd").new()
			hz.setup(h[0], h[1])
			world.add_child(hz)
	if room.spawns.has("O") and not boss_beaten:
		boss = Boss.new()
		world.add_child(boss)
		boss.setup(room.spawns["O"], room.size)
		enemies.append_array(boss.parts())
	_relic = null
	if room.spawns.has("O") and boss_beaten and not has_elegy:
		_drop_scythe(room.spawns["O"] + Vector2(0, -26))      # she left without it: it waits here
	if room.spawns.has("A") and not has_latch:
		_relic = Relic.new()
		_relic.position = room.spawns["A"] + Vector2(0, -22)
		_relic.z_index = 6
		world.add_child(_relic)
	var marks := Marks.new()
	marks.z_index = 50
	world.add_child(marks)
	for side in room.doors:
		# the church's lower door stays shut until the library lever is pulled
		if room.doors[side].to == "shaft" and not (lever_library or G.shifted):
			room.doors[side].locked = true
			room.doors[side].sealed_msg = "SEALED. Something in the library holds it shut."
	_motes()
	shift.set_room(next_room)
	if G.shifted:
		Sfx.stop_music()
	else:
		Sfx.play_music(room.head.get("music", "music_church"))
	hud.banner(TITLES.get(next_room, ""))
	hud.boss_bar("", 0.0)
	hud.prompt("")


func _motes() -> void:
	# slow drifting specks in the colour of the area: dust in the library, sparks in the lab
	var m := CPUParticles2D.new()
	m.position = room.size / 2.0
	m.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	m.emission_rect_extents = room.size / 2.0
	m.amount = clampi(int(room.size.x * room.size.y / 2600.0), 16, 140)
	m.lifetime = 6.0
	m.preprocess = 6.0
	m.direction = Vector2(0.3, -1)
	m.spread = 40.0
	m.gravity = Vector2.ZERO
	m.initial_velocity_min = 2.0
	m.initial_velocity_max = 9.0
	m.color = room.theme["dust"]
	m.z_index = 1
	world.add_child(m)


func _physics_process(delta: float) -> void:
	if _busy or G.frozen() or player == null:
		return
	var body: Rect2 = player.body_rect()
	for en in enemies:
		if is_instance_valid(en) and en.can_hurt() and player.invuln <= 0.0 and en.hurt_rect().intersects(body):
			player.take_hit(en.damage(), en.global_position.x)
			en.touched_player()
	if _busy:
		return      # that hit was the last one: the death fade owns the screen now
	_move_waves(delta)
	_move_orbs(delta)
	_move_shots(delta)
	_terminal()
	_machine()
	_levers()
	_scythe_watch()
	_boss_watch()
	if _relic != null and is_instance_valid(_relic) and _relic.position.distance_to(player.global_position + Vector2(0, -18)) < 18.0:
		_relic.queue_free()
		_relic = null
		has_latch = true
		Sfx.play("pickup", 0.6)
		Sfx.play("special", 1.3)
		ring_fx(player.global_position + Vector2(0, -20), 60.0, Color(0.5, 1.0, 1.0))
		hud.toast("GRIP SERVOS ONLINE  -  jump at a wall and hold toward it to cling, jump again to kick off", 7.0)
	# holes in the top and bottom rows: up and out, or down and through
	var px := player.global_position.x
	var py := player.global_position.y
	if room.up_span.x >= 0.0 and py < 2.0 and px >= room.up_span.x and px <= room.up_span.y:
		_vertical(true)
		return
	if room.down_span.x >= 0.0 and py > room.size.y + 8.0 and px >= room.down_span.x and px <= room.down_span.y:
		_vertical(false)
		return
	# the doors (and the open edges) are in the room edges: walking off the screen goes through
	if px < 5.0 and ((room.doors.has("left") and room.doors["left"].open > 0.85) or room.open_edges.has("left")):
		_through(room.head.get("left", ""), "right")
	elif px > room.size.x - 5.0 and ((room.doors.has("right") and room.doors["right"].open > 0.85) or room.open_edges.has("right")):
		_through(room.head.get("right", ""), "left")


func _process(delta: float) -> void:
	if not _busy and not dialog.active:
		if Input.is_action_just_pressed("restart"):
			reconstruct()
			return
		for i in ROOMS.size():
			# tester shortcut: number keys (1-9, 0) jump straight to a room
			if Input.is_action_just_pressed("room%d" % (i + 1)):
				player.hp = 0.0
				enter(ROOMS[i], ENTRY.get(ROOMS[i], "left"))
				break
	_voices(delta)
	if cam != null and is_instance_valid(cam):
		if _shake_t > 0.0:
			_shake_t -= delta
			cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_amp
		else:
			cam.offset = Vector2.ZERO
	if player == null:
		return
	hud.refresh(player, kills)
	if boss != null and is_instance_valid(boss) and boss.started and boss.alive:
		hud.boss_bar(TITLES["boss"], boss.hp / maxf(1.0, T.v("boss_hp")))


func _terminal() -> void:
	# the save room: stand at the terminal and press Up
	if not room.spawns.has("M"):
		return
	var near: bool = absf(player.global_position.x - room.spawns["M"].x) < 30.0 and player.is_on_floor()
	var touch_on: bool = touch != null and touch.active
	hud.prompt("" if touch_on else (("NO SIGNAL" if G.shifted else "W: cache memory (heal and save)") if near else ""))
	if near and Input.is_action_just_pressed("up") and player.state == "move" and G.shifted:
		# after the shift every cache station is dead: no heal, no save
		Sfx.play_file("sfx/shift/dead_terminal.wav", -4.0)
		hud.toast("NO SIGNAL")
		return
	if near and Input.is_action_just_pressed("up") and player.state == "move":
		saved = true
		saved_room = room_name
		player.hp = T.v("player_hp")
		player.mp = T.v("mp_max")
		Sfx.play("pickup", 0.7)
		Sfx.play("special", 0.6)
		ring_fx(room.spawns["M"] + Vector2(0, -40), 70.0, Color(0.5, 1.0, 1.0))
		hud.toast("MEMORY CACHED")


func interact_target() -> Dictionary:
	# what the touch bubble points at: {"pos": world position, "label": text}, or {} when nothing is near
	if room == null or player == null:
		return {}
	var feet: Vector2 = player.global_position
	if room.spawns.has("M") and absf(feet.x - room.spawns["M"].x) < 30.0 and player.is_on_floor():
		return {"pos": room.spawns["M"] + Vector2(0, -44), "label": "NO SIGNAL" if G.shifted else "CACHE"}
	if room.spawns.has("T") and absf(feet.x - room.spawns["T"].x) < 34.0 and player.is_on_floor() and not G.shifted:
		return {"pos": room.spawns["T"] + Vector2(0, -80), "label": "MACHINE"}
	for pr in room.props:
		if pr is Props.Lever and pr.kind == "library" and not pr.pulled and _near_lever(pr):
			return {"pos": pr.global_position + Vector2(0, -34), "label": "LEVER"}
	return {}


func _near_lever(pr: Node2D) -> bool:
	var d: Vector2 = player.global_position - pr.global_position
	return absf(d.x) < T.v("lever_reach") and absf(d.y) < 26.0


func _levers() -> void:
	# the library lever: stand next to it and press Up (a cut pulls it too, see player_cut)
	for pr in room.props:
		if pr is Props.Lever and pr.kind == "library" and not pr.pulled:
			var near := _near_lever(pr)
			var touch_on: bool = touch != null and touch.active
			hud.prompt("W: pull the lever" if near and not touch_on else "")
			if near and Input.is_action_just_pressed("up") and player.state == "move":
				pr.pull()
				hud.prompt("")


func open_bars() -> void:
	# the lever behind the bars was cut with Elegy: the bars rise
	bars_opened = true
	if room.bars != null:
		room.bars.raise()
	hud.toast("The bars grind upward.", 2.5)


func room_opened(r: Rect2) -> void:
	room.clear_cells(r)


func wall_broke(r: Rect2) -> void:
	wall_broken = true
	room.clear_cells(r)
	for pr in room.props.duplicate():
		if pr is Props.CrackWall and pr.broken:
			room.props.erase(pr)


func _machine() -> void:
	# the time machine: Up beside it asks "are you sure?"
	if not room.spawns.has("T") or hold or _busy:
		return
	var t: Vector2 = room.spawns["T"]
	var near: bool = absf(player.global_position.x - t.x) < 34.0 and player.is_on_floor()
	var touch_on: bool = touch != null and touch.active
	hud.prompt("" if touch_on else (("W: the organ is silent" if G.shifted else "W: use the machine") if near else ""))
	if near and Input.is_action_just_pressed("up") and player.state == "move":
		if G.shifted:
			Sfx.play_file("sfx/shift/dead_terminal.wav", -4.0)
			hud.toast("THE ORGAN IS SILENT.")
		else:
			_ask_machine()


func _ask_machine() -> void:
	hold = true
	touch.blocked = true
	var choice: String = await dialog.ask()
	dialog.close()
	touch.blocked = false
	if choice == "yes":
		await _activate_machine()
	else:
		hold = false


func _activate_machine() -> void:
	# the reality shift: the machine wakes, the picture tears and goes white, and under the white
	# the world turns inside out. She comes back next to the machine; this is where she wakes now.
	_busy = true
	hold = true
	if room.organ != null:
		room.organ.charge()
	Sfx.pause_music(true)
	Sfx.play_file("sfx/shift/machine_activate.wav", -2.0)
	shake(1.5, 1.6)
	await get_tree().create_timer(1.6).timeout
	var tear_time: float = T.v("shift_tear_time")
	Sfx.play_file("sfx/shift/shift_tear.wav", -1.0)
	shift.tear(tear_time)
	shake(5.0, tear_time)
	await get_tree().create_timer(tear_time * 0.55).timeout
	G.shifted = true
	saved = true
	saved_room = "timemachine"
	Sfx.pause_music(false)
	Sfx.stop_music()
	Sfx.play_loop("sfx/shift/drone_loop.wav", -8.0)
	_whisper_t = randf_range(T.v("shift_whisper_min"), T.v("shift_whisper_max"))
	enter("timemachine", "K")
	if room.organ != null:
		room.organ.silence()
	await get_tree().create_timer(tear_time * 0.45 + 0.3).timeout
	hud.toast("SOMETHING ANSWERED.", 4.0)
	hold = false
	_busy = false


func _voices(delta: float) -> void:
	# after the shift: now and then a whisper or a chant, at a random loudness and pitch
	if not G.shifted:
		return
	_whisper_t -= delta
	if _whisper_t > 0.0:
		return
	_whisper_t = randf_range(T.v("shift_whisper_min"), T.v("shift_whisper_max"))
	var file := "sfx/shift/incant_%02d.wav" % randi_range(1, 6) if randf() < 0.5 else "sfx/shift/whisper_%02d.wav" % randi_range(1, 5)
	Sfx.play_file(file, randf_range(-16.0, -4.0), randf_range(0.85, 1.12))


func _scythe_watch() -> void:
	if _scythe == null or not is_instance_valid(_scythe):
		return
	if _scythe.global_position.distance_to(player.global_position + Vector2(0, -18)) < 22.0:
		_scythe.queue_free()
		_scythe = null
		has_elegy = true
		Sfx.play("pickup", 0.6)
		Sfx.play("special", 1.3)
		Sfx.play("pickup", 1.0)
		ring_fx(player.global_position + Vector2(0, -20), 70.0, Color(0.5, 1.0, 1.0))
		hud.toast("ELEGY-013 - the Pallbearer's scythe is yours. E (or SWAP) to change weapon.", 7.0)
		if touch != null:
			touch.queue_redraw()


func _drop_scythe(at: Vector2) -> void:
	# the scythe falls from where the body was and floats a little above the floor
	var sc := Props.Scythe.new()
	var floor_y: float = room.spawns["O"].y if room.spawns.has("O") else room.size.y - 32.0
	sc.setup(at, floor_y - 26.0)
	world.add_child(sc)
	_scythe = sc


func _boss_watch() -> void:
	if boss == null or not is_instance_valid(boss) or boss.started:
		return
	if player.global_position.x > 72.0:
		# the way back shuts and the fight starts
		if room.doors.has("left"):
			room.doors["left"].locked = true
		boss.begin()
		hud.toast("ITS HANDS ARE YOUR STAIRS")


func boss_dying() -> void:
	hud.boss_bar("", 0.0)
	for s in shots:
		s.queue_free()
	shots.clear()
	shake(4.0, 1.2)


func boss_died(at: Vector2 = Vector2.ZERO) -> void:
	boss_beaten = true
	kills += 1
	enemies = enemies.filter(func(e): return is_instance_valid(e) and e.kind != "boss")
	boss = null
	if room.doors.has("left"):
		room.doors["left"].locked = false
	ring_fx(room.size / 2.0, 160.0, Color(1.0, 0.85, 0.4))
	hud.toast("LAID TO REST", 4.0)
	Sfx.play_music("music_save")
	if not has_elegy:
		_drop_scythe(at if at != Vector2.ZERO else room.size / 2.0)


func player_swing(rect: Rect2, dmg: float, dir: int, already: Array) -> void:
	# a box-shaped hit (the blade wave). It only ever hits enemies: levers and cracked walls
	# (room.props, the ones that answer to a cut) never feel it.
	# a copy of the list: an enemy that dies here leaves the real list at once
	for en in enemies.duplicate():
		if not is_instance_valid(en) or already.has(en):
			continue
		if en.hurt_rect().intersects(rect):
			_land_hit(en, dmg, dir, already)


func player_cut(pts: PackedVector2Array, dmg: float, dir: int, already: Array) -> void:
	# a weapon cut: it lands if any point of the blade is inside the enemy.
	# "Hit forgiveness" grows every enemy box a little so near misses still count.
	var pad: float = T.v("hit_thickness")
	if T.v("show_hitboxes") >= 0.5:
		_marks.append({"pts": pts, "t": 0.25})
	for en in enemies.duplicate():
		if not is_instance_valid(en) or already.has(en):
			continue
		var box: Rect2 = en.hurt_rect().grow(pad)
		for p in pts:
			if box.has_point(p):
				_land_hit(en, dmg, dir, already)
				break
	# levers and the cracked wall: any cut reaches them; the bars lever wants the Elegy cut
	for pr in room.props.duplicate():
		if not is_instance_valid(pr) or already.has(pr):
			continue
		var pbox: Rect2 = pr.prop_rect().grow(pad)
		for p in pts:
			if pbox.has_point(p):
				already.append(pr)
				pr.prop_cut(dmg, player._is_elegy())
				break


func _land_hit(en: Node2D, dmg: float, dir: int, already: Array) -> void:
	already.append(en)
	var at: Vector2 = en.hurt_rect().get_center()
	en.take_hit(dmg, dir)
	fx("spark", at)
	number(at + Vector2(0, -14), int(dmg), Color("#F4F0E0"))
	Sfx.play("hit")
	G.hitstop = T.v("hitstop")
	shake(T.v("shake"), 0.1)


func throw_wave(at: Vector2, dir: int) -> void:
	# the special attack: a blade wave that flies forward and cuts through enemies
	var s := Sprite2D.new()
	s.texture = G.tex("fx/wave_00.png")
	s.flip_h = dir < 0
	s.global_position = at
	s.z_index = 4
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD   # the wave is light
	s.material = glow
	world.add_child(s)
	waves.append({"node": s, "dir": dir, "left": T.v("special_range"), "hit": []})


func _move_waves(delta: float) -> void:
	for w in waves.duplicate():
		var s: Sprite2D = w["node"]
		var step: float = T.v("special_speed") * delta
		s.global_position.x += w["dir"] * step
		Vfx.wave_trail(s.global_position, w["dir"])
		w["left"] -= step
		s.modulate.a = clampf(w["left"] / 30.0, 0.0, 1.0)
		var size: Vector2 = s.texture.get_size()
		player_swing(Rect2(s.global_position - size / 2.0, size), T.v("special_damage"), w["dir"], w["hit"])
		if w["left"] <= 0.0:
			waves.erase(w)
			s.queue_free()


func shoot(at: Vector2, vel: Vector2, kind: String, dmg: float) -> void:
	# anything an enemy throws: feather (straight), spit (arcs and splats), shock
	# (runs along the floor), bolt (the boss: straight and fast)
	var s := Shot.new()
	s.kind = kind
	s.vel = vel
	s.dmg = dmg
	s.life = {"feather": 2.2, "spit": 3.0, "shock": 0.75, "bolt": 4.0}[kind]
	s.global_position = at
	s.z_index = 4
	world.add_child(s)
	shots.append(s)


func _move_shots(delta: float) -> void:
	var body: Rect2 = player.body_rect()
	for s in shots.duplicate():
		if s.kind == "spit":
			s.vel.y += T.v("shot_gravity") * delta
		s.global_position += s.vel * delta
		s.life -= delta
		s.queue_redraw()
		var p: Vector2 = s.global_position
		var gone: bool = s.life <= 0.0 or p.x < -20.0 or p.x > room.size.x + 20.0
		if not gone and (s.kind == "spit" or s.kind == "feather"):
			if room.is_solid(int(p.x / 16.0), int(p.y / 16.0)):
				gone = true
				dust(p, 3)
		if not gone and not G.peace and s.box().intersects(body) and player.invuln <= 0.0:
			player.take_hit(s.dmg, p.x - signf(s.vel.x) * 4.0)
			gone = s.kind != "shock"
			if _busy:
				return
		if gone:
			shots.erase(s)
			s.queue_free()


func ring(at: Vector2, radius: float, dmg: float) -> void:
	# a burst around a point (the ghost's shriek): hurts her if she is inside it
	ring_fx(at, radius, Color(0.8, 0.6, 1.0))
	shake(1.5, 0.12)
	var c: Vector2 = player.body_rect().get_center()
	if not G.peace and c.distance_to(at) < radius:
		player.take_hit(dmg, at.x)


func ring_fx(at: Vector2, radius: float, color: Color) -> void:
	var r := RingFx.new()
	r.color = color
	r.radius = radius
	r.global_position = at
	r.z_index = 5
	world.add_child(r)


func _drop_orb(at: Vector2) -> void:
	var o := Polygon2D.new()
	o.polygon = PackedVector2Array([Vector2(0, -4), Vector2(4, 0), Vector2(0, 4), Vector2(-4, 0)])
	o.color = Color("#5AB4FF")
	o.global_position = at
	o.z_index = 6
	world.add_child(o)
	orbs.append({"node": o, "wait": T.v("orb_hang")})


func _move_orbs(delta: float) -> void:
	# an orb hangs for a moment, then flies to her
	var target: Vector2 = player.global_position + Vector2(0, -18)
	for ob in orbs.duplicate():
		var o: Polygon2D = ob["node"]
		if ob["wait"] > 0.0:
			ob["wait"] -= delta
			continue
		o.global_position = o.global_position.move_toward(target, T.v("orb_speed") * delta)
		if o.global_position.distance_to(target) < 6.0:
			orbs.erase(ob)
			o.queue_free()
			player.gain_mp(T.v("mp_pickup"))
			Sfx.play("pickup")
			number(target + Vector2(0, -20), int(T.v("mp_pickup")), Color("#5AB4FF"))


func enemy_died(en: Node2D) -> void:
	kills += 1
	enemies.erase(en)
	if randf() < T.v("mp_drop_chance"):
		_drop_orb(en.hurt_rect().get_center())
	fx("burst", en.hurt_rect().get_center())
	Sfx.play("enemy_die")


func player_died() -> void:
	# SYSTEM OFFLINE: the picture loses its colour and breaks up; two choices.
	_busy = true
	await get_tree().create_timer(0.7).timeout      # let her fall first
	Sfx.pause_music(true)
	Sfx.play("no_energy", 0.5)
	touch.blocked = true
	var choice: String = await offline.ask()
	touch.blocked = false
	if choice == "quit":
		get_tree().quit()
		return
	await reconstruct(true)


func reconstruct(from_offline: bool = false) -> void:
	# A new Pandora is built in the empty capsule of the last save room she cached
	# in (the church start if she never cached), steps out, and takes the next number.
	if _busy and not from_offline:
		return
	_busy = true
	hold = true
	await hud.fade(1.0, 0.35)
	offline.close()
	player.hp = 0.0
	var at := saved_room if saved_room != "" else "church"
	enter(at, "K" if saved_room != "" else "P")
	Sfx.pause_music(false)
	unit += 1
	hud.set_unit(unit)
	player.modulate = Color(0.3, 1.0, 1.0, 0.0)
	await hud.fade(0.0, 0.3)
	Sfx.play("special", 0.6)
	ring_fx(player.global_position + Vector2(0, -22), 40.0, Color(0.5, 1.0, 1.0))
	var tw := create_tween()
	tw.tween_property(player, "modulate", Color(0.5, 1.0, 1.0, 1.0), 0.9)
	tw.tween_property(player, "modulate", Color.WHITE, 0.25)
	await tw.finished
	if room.spawns.has("K") and saved_room != "":
		# she steps out of the capsule
		player._spr.play("rise" if player._spr.sprite_frames.has_animation("rise") else "run")
		var step := create_tween()
		step.tween_property(player, "position:x", player.position.x + 30.0, 0.45)
		await step.finished
	Sfx.play("pickup", 0.7)
	hud.toast("PANDORA-%03d RECONSTRUCTED" % unit, 3.0)
	hold = false
	_busy = false


func _through(to: String, spawn_key: String) -> void:
	if to == "":
		return
	_busy = true
	await hud.fade(1.0, 0.18)
	enter(to, spawn_key, room_name)
	await hud.fade(0.0, 0.18)
	_busy = false


func _vertical(going_up: bool) -> void:
	# up through a ^ opening: out of the hole of the room above, with a pop. Down through a v
	# opening: into the top of the room below, at the speed she was falling.
	var to: String = room.head.get("up" if going_up else "down", "")
	if to == "":
		return
	var vy: float = player.velocity.y
	var face: int = player.facing
	enter(to, "hole_down" if going_up else "hole_up", room_name,
		{"vy": minf(vy, -T.v("hole_pop")) if going_up else vy, "face": face})
	hud.fade_in_from(0.7, 0.25)


func shake(amp: float, time: float) -> void:
	_shake_amp = maxf(amp, _shake_amp if _shake_t > 0.0 else 0.0)
	_shake_t = maxf(time, _shake_t)


func fx(kind: String, at: Vector2) -> void:
	var info: Dictionary = G.frames["fx"][kind]
	var s := AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("go")
	sf.set_animation_speed("go", 24.0)
	sf.set_animation_loop("go", false)
	for i in int(info["n"]):
		sf.add_frame("go", G.tex("fx/%s_%02d.png" % [kind, i]))
	s.sprite_frames = sf
	s.global_position = at
	s.z_index = 5
	world.add_child(s)
	s.play("go")
	s.animation_finished.connect(s.queue_free)


func dust(at: Vector2, count: int) -> void:
	for i in count:
		var p := ColorRect.new()
		p.color = Color(0.75, 0.72, 0.85, 0.7)
		p.size = Vector2(2, 2)
		p.position = at + Vector2(randf_range(-6, 6), -2)
		world.add_child(p)
		var tw := p.create_tween().set_parallel(true)
		tw.tween_property(p, "position", p.position + Vector2(randf_range(-10, 10), randf_range(-9, -3)), 0.3)
		tw.tween_property(p, "color:a", 0.0, 0.3)
		tw.chain().tween_callback(p.queue_free)


func number(at: Vector2, value: int, color: Color) -> void:
	var l := Label.new()
	l.text = str(value)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	l.position = at + Vector2(-6, -8)
	l.z_index = 10
	world.add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 18.0, 0.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.25)
	tw.chain().tween_callback(l.queue_free)


# The wall-latch relic: a slowly bobbing cyan claw-mark she walks into.
class Relic extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var y := sin(_t * 3.0) * 2.0
		draw_circle(Vector2(0, y), 9.0 + sin(_t * 5.0), Color(0.3, 1.0, 1.0, 0.18))
		draw_colored_polygon(PackedVector2Array([Vector2(0, y - 7), Vector2(6, y), Vector2(0, y + 7), Vector2(-6, y)]), Color(0.1, 0.25, 0.3))
		draw_polyline(PackedVector2Array([Vector2(0, y - 7), Vector2(6, y), Vector2(0, y + 7), Vector2(-6, y), Vector2(0, y - 7)]), Color(0.6, 1.0, 1.0), 1.0)
		for i in 3:
			draw_line(Vector2(-3 + i * 3, y - 3), Vector2(-4 + i * 3, y + 3), Color(0.8, 1.0, 1.0), 1.0)


# "Show hit areas" (F1): where the blade cut (yellow), what can be hit (red), her own box (green).
class Marks extends Node2D:
	func _process(delta: float) -> void:
		visible = T.v("show_hitboxes") >= 0.5
		for m in G.main._marks.duplicate():
			m["t"] -= delta
			if m["t"] <= 0.0:
				G.main._marks.erase(m)
		if visible:
			queue_redraw()

	func _draw() -> void:
		var main: Node = G.main
		if main.player == null:
			return
		var pad: float = T.v("hit_thickness")
		for en in main.enemies:
			if is_instance_valid(en):
				draw_rect(en.hurt_rect(), Color(1, 0.2, 0.2, 0.9), false, 1.0)
				draw_rect(en.hurt_rect().grow(pad), Color(1, 0.5, 0.2, 0.5), false, 1.0)
		draw_rect(main.player.body_rect(), Color(0.3, 1, 0.3, 0.9), false, 1.0)
		for m in main._marks:
			for p in m["pts"]:
				draw_rect(Rect2(p - Vector2(0.5, 0.5), Vector2(1, 1)), Color(1, 1, 0.2, m["t"] * 4.0))


# One enemy shot. It draws itself by kind and points the way it flies.
class Shot extends Node2D:
	var kind := "spit"
	var vel := Vector2.ZERO
	var dmg := 5.0
	var life := 2.0

	func box() -> Rect2:
		if kind == "shock":
			return Rect2(global_position + Vector2(-6, -10), Vector2(12, 16))
		if kind == "bolt":
			return Rect2(global_position + Vector2(-6, -3), Vector2(12, 6))
		return Rect2(global_position + Vector2(-3, -3), Vector2(6, 6))

	func _draw() -> void:
		var d := vel.normalized()
		match kind:
			"feather":
				draw_line(-d * 5.0, d * 4.0, Color(1.0, 0.85, 0.9), 2.0)
				draw_line(-d * 2.0, d * 4.0, Color.WHITE, 1.0)
				draw_line(-d * 9.0, -d * 5.0, Color(0.9, 0.3, 0.4, 0.7), 1.0)
			"spit":
				draw_circle(Vector2.ZERO, 4.0, Color(0.25, 0.1, 0.3))
				draw_circle(Vector2.ZERO, 3.0, Color(0.85, 0.9, 0.3))
				draw_rect(Rect2(-2, -2, 2, 1), Color(1, 1, 0.8))
			"shock":
				var up := 8.0 + sin(life * 40.0) * 3.0
				draw_colored_polygon(PackedVector2Array([Vector2(-6, 6), Vector2(6, 6), Vector2(d.x * 3.0, -up)]), Color(0.5, 0.95, 1.0, 0.9))
				draw_colored_polygon(PackedVector2Array([Vector2(-3, 6), Vector2(3, 6), Vector2(d.x * 2.0, -up + 5.0)]), Color.WHITE)
			"bolt":
				draw_rect(Rect2(-d.x * 16.0 - 4.0, -1, 12, 2), Color(1.0, 0.6, 0.1, 0.6))
				draw_colored_polygon(PackedVector2Array([Vector2(-7, 0), Vector2(0, -4), Vector2(7, 0), Vector2(0, 4)]), Color(1.0, 0.8, 0.2))
				draw_colored_polygon(PackedVector2Array([Vector2(-4, 0), Vector2(0, -2), Vector2(4, 0), Vector2(0, 2)]), Color(1.0, 1.0, 0.8))


# A ring that grows and fades: the ghost's shriek, the save, the boss breaking.
class RingFx extends Node2D:
	var color := Color.WHITE
	var radius := 40.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta / 0.35
		queue_redraw()
		if _t >= 1.0:
			queue_free()

	func _draw() -> void:
		var c := color
		c.a = 1.0 - _t
		draw_arc(Vector2.ZERO, radius * (0.3 + 0.7 * _t), 0.0, TAU, 28, c, 2.0)
		c.a *= 0.25
		draw_circle(Vector2.ZERO, radius * (0.3 + 0.7 * _t), c)
