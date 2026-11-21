# PROTOTYPE - NOT FOR PRODUCTION
# Runs the prototype: loads a room, the hero, the enemies and the boss, resolves
# hits, walks her between rooms through the doors in the room edges, and owns the
# effects (sparks, dust, numbers, shake, the short hit pause). The systems it
# creates from main.SYSTEMS own the rest: spawning, the arena, interaction, loot,
# ambience and the flying projectiles.
# The way through: church -> library -> save room -> lab -> (boss door) -> sanctum.
# Behind the church's lower door (opened by the library lever) lies the marrow well, the vault,
# the threshing chapel and the time machine, whose switch turns the whole world inside out.
extends Node2D

const Room := preload("res://room.gd")
const Player := preload("res://player.gd")
const Hud := preload("res://hud.gd")
const TuningPanel := preload("res://tuning_panel.gd")
const Touch := preload("res://touch.gd")
const Offline := preload("res://offline.gd")
const MachineDialog := preload("res://machine_dialog.gd")
const ShiftFx := preload("res://shift.gd")
const Spawner := preload("res://spawner.gd")
const Props := preload("res://props.gd")
var ROOMS: Array:
	get: return W.room_list("before")
const TITLES := {"church": "THE NAVE OF ASH", "library": "THE UNREAD STACKS", "save": "CACHE STATION 002",
	"lab": "SPECIMEN HALL", "save2": "CACHE STATION 003", "boss": "THE PALLBEARER", "shaft": "THE MARROW WELL",
	"vault": "CACHE STATION 004", "hazard": "THE THRESHING CHAPEL", "timemachine": "THE ORGAN OF HOURS",
	"scriptorium": "THE SCRIPTORIUM", "kennel": "THE KENNEL", "ordnance": "THE ORDNANCE WARD",
	"hallway": "THE PROCESSIONAL", "gallery": "THE RELIQUARY OF SHELLS", "loft": "THE WINCH LOFT",
	"arnetria": "THE QUIET RING"}
# where the number keys (and the pause menu) put her: the door side or marker that makes sense in that room
var ENTRY: Dictionary:
	get:
		var d := {}
		for r in ROOMS:
			d[r] = String(W.meta(r).get("entry", "left"))
		return d
# every system file a later slice may add. _ready creates each one whose file exists.
const SYSTEMS := {"spawner": "res://spawner.gd", "interact": "res://interact.gd", "loot": "res://loot.gd",
	"arena": "res://arena.gd", "ambience": "res://ambience.gd", "projectiles": "res://projectiles.gd",
	"respawn": "res://respawn.gd", "repair": "res://repair.gd", "card": "res://pickup_card.gd",
	"dialog_box": "res://dialog_box.gd", "menu": "res://menu.gd", "recall": "res://recall.gd",
	"voice": "res://voice.gd"}

var world: Node2D
var room: Node2D
var player: CharacterBody2D
var cam: Camera2D
var hud: CanvasLayer
var panel: CanvasLayer
var touch: Control
var room_name := ""
var enemies: Array = []
var kills := 0
var hold := false            # she cannot move (she is being rebuilt in the capsule)
var offline: CanvasLayer     # the SYSTEM OFFLINE screen
var dialog: CanvasLayer      # the time machine's YES / NO question
var shift: CanvasLayer       # the after-the-shift picture filter
var _marks: Array = []       # recent blade points, for "show hit areas"
var _shake_t := 0.0
var _shake_amp := 0.0
var _busy := false           # a door or death transition is running
var _entry := "P"
# the systems, created from SYSTEMS in _ready
var spawner: Node
var interact: Node
var loot: Node
var arena: Node
var ambience: Node
var projectiles: Node
var respawn: Node
var repair: Node
var card: Node
var dialog_box: Node
var menu: Node
var recall: Node
var voice: Node

# Progress that used to live here now lives in W and R. These keep the old names
# working for every script and test that reaches into main.
var has_elegy: bool:
	get: return R.has("elegy_013")
	set(v): R.set_owned("elegy_013", v)
var has_latch: bool:
	get: return R.has("wall_jump")
	set(v): R.set_owned("wall_jump", v)
var lever_library: bool:
	get: return W.flag("lever_library")
	set(v): W.set_flag("lever_library", v)
var bars_opened: bool:
	get: return W.flag("bars_opened")
	set(v): W.set_flag("bars_opened", v)
var wall_broken: bool:
	get: return W.flag("wall_broken")
	set(v): W.set_flag("wall_broken", v)
var boss_beaten: bool:
	get: return W.flag("beaten_pallbearer")
	set(v): W.set_flag("beaten_pallbearer", v)
var saved: bool:
	get: return W.flag("saved")
	set(v): W.set_flag("saved", v)
var saved_room: String:
	get: return W.saved_room
	set(v): W.saved_room = String(v)
var unit: int:
	get: return W.unit
	set(v): W.unit = int(v)
var boss: Node2D:
	get: return arena.boss if arena != null else null
	set(v): if arena != null: arena.boss = v
var waves: Array:
	get: return projectiles.waves if projectiles != null else []
var shots: Array:
	get: return projectiles.shots if projectiles != null else []
var _scythe: Node2D:
	get: return arena._scythe if arena != null else null
var _relic: Node2D:
	get: return arena._relic if arena != null else null
var _whisper_t: float:
	get: return ambience.whisper_t if ambience != null else 0.0
	set(v): if ambience != null: ambience.whisper_t = v


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
	_make_systems()
	T.set_v("weapon", 0.0)      # she starts with Dirge-042 only
	var start := "church"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("room=") and ROOMS.has(a.substr(5)):
			start = a.substr(5)
		elif a.begins_with("seed="):
			R.debug_seed(int(a.substr(5)))
	enter(start, ENTRY.get(start, "left"))


func _make_systems() -> void:
	# create every system whose file exists; a later slice only adds its file
	for nm in SYSTEMS:
		var path: String = SYSTEMS[nm]
		if not ResourceLoader.exists(path):
			continue
		var script = load(path)
		if script == null:
			continue
		var node: Node = script.new()
		if node == null:
			continue
		node.name = nm
		add_child(node)
		set(nm, node)


func enter(next_room: String, spawn_key: String, from_room: String = "", carry: Dictionary = {}) -> void:
	# from_room: the room she came from. If it is this room's left or right neighbour she appears
	# on that side, whatever door key was asked for. carry: {"vy": speed, "face": facing} for holes.
	if world != null:
		world.queue_free()
	enemies.clear()
	projectiles.clear()
	loot.clear()
	arena.detach()
	world = Node2D.new()
	add_child(world)
	room = Room.new()
	world.add_child(room)
	next_room = next_room.trim_suffix("_shift")      # room_name is always the plain name; file_id says which sheet
	from_room = from_room.trim_suffix("_shift")
	room.load_room(next_room, G.shifted)
	room_name = next_room
	if from_room != "":
		if String(room.head.get("left", "")).trim_suffix("_shift") == from_room:
			spawn_key = "left"
		elif String(room.head.get("right", "")).trim_suffix("_shift") == from_room:
			spawn_key = "right"
	_entry = spawn_key
	var fresh: bool = player == null or player.hp <= 0.0
	var keep_hp: float = R.max_hp() if fresh else player.hp
	var keep_mp: float = R.max_mp() if fresh else player.mp
	player = Player.new()
	var fallback: Vector2 = room.spawns.get("left", room.spawns.get("P", Vector2(64, 64)))
	player.position = room.spawns.get(spawn_key, fallback)
	for d in room.doors_all:      # two doors on one side: arrive at the one that leads back where she came from
		if from_room != "" and d.side == spawn_key and String(d.to).trim_suffix("_shift") == from_room:
			player.position = Vector2(room.spawns[spawn_key].x, d.feet().y)
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
	for e in room.enemy_nodes:
		enemies.append(e)
	for h in room.hazards:
		if ResourceLoader.exists("res://hazard.gd"):
			var hz: Node2D = load("res://hazard.gd").new()
			hz.setup(h[0], h[1])
			world.add_child(hz)
	enemies.append_array(arena.room_setup(room, world))
	loot.place_items(room)
	var marks := Marks.new()
	marks.z_index = 50
	world.add_child(marks)
	for side in room.doors:
		# the church's lower door stays shut until the library lever is pulled
		if room.doors[side].to == "shaft" and not (lever_library or G.shifted):
			room.doors[side].locked = true
	ambience.motes(room, world)
	shift.set_room(next_room)
	if G.shifted:
		Sfx.stop_music()
	else:
		Sfx.play_music(room.head.get("music", "music_church"))
	hud.banner(TITLES.get(next_room, ""))
	hud.boss_bar("", 0.0)
	hud.prompt("")
	W.mark_visited(next_room)
	W.room_entered.emit(room.file_id)


func debug_enter(room_id: String, side := "left", shifted := false) -> void:
	# the test hook: jump straight to a room, on the sheet it asks for
	if shifted:
		W.sheet = "after"
	G.shifted = W.sheet != "before"
	if player != null:
		player.hp = 0.0
	enter(room_id, side)


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
	projectiles.move_waves(delta)
	loot.move_orbs(delta)
	projectiles.move_shots(delta)
	if _busy:
		return      # a shot was the last hit
	interact.tick()
	arena.tick(delta, player)
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
	if px < 5.0:
		var left_to := _open_door_to("left")
		if left_to != "":
			_through(left_to, "right")
			return
		if room.open_edges.has("left"):
			_through(room.head.get("left", ""), "right")
	elif px > room.size.x - 5.0:
		var right_to := _open_door_to("right")
		if right_to != "":
			_through(right_to, "left")
			return
		if room.open_edges.has("right"):
			_through(room.head.get("right", ""), "left")


func _open_door_to(side: String) -> String:
	# the room may hold two doors on one side: take the open one nearest her feet
	var best := ""
	var best_dy := INF
	for d in room.doors_all:
		if is_instance_valid(d) and String(d.side) == side and d.open > 0.85 and String(d.to) != "":
			var dy := absf(d.feet().y - player.global_position.y)
			if dy < best_dy:
				best_dy = dy
				best = String(d.to)
	return best


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
	ambience.voices(delta)
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
		hud.boss_bar(arena.bar_name(TITLES["boss"]), arena.bar_fill())


func interact_target() -> Dictionary:
	# what the touch bubble points at: the interact system knows
	return interact.interact_target()


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


func boss_dying() -> void:
	arena.dying(boss)


func boss_died(at: Vector2 = Vector2.ZERO) -> void:
	arena.down(boss, at)


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
	W.enemy_hit.emit(en, int(dmg))


func throw_wave(at: Vector2, dir: int) -> void:
	projectiles.throw_wave(at, dir)


func shoot(at: Vector2, vel: Vector2, kind: String, dmg: float) -> void:
	projectiles.shoot(at, vel, kind, dmg)


func ring(at: Vector2, radius: float, dmg: float) -> void:
	projectiles.ring(at, radius, dmg)


func ring_fx(at: Vector2, radius: float, color: Color) -> void:
	projectiles.ring_fx(at, radius, color)


func enemy_died(en: Node2D) -> void:
	kills += 1
	enemies.erase(en)
	var at: Vector2 = en.hurt_rect().get_center()
	fx("burst", at)
	Sfx.play("enemy_die")
	W.enemy_killed.emit(en, String(en.kind), at, bool(en.get("respawned")))
	# every kill pays XP (half, rounded up, for one that came back): the number floats up in gold
	var xp_gain := R.award_kill(String(en.kind), bool(en.get("respawned")))
	if xp_gain > 0:
		number(at + Vector2(0, -12), xp_gain, Color("#F2D16B"))


func player_died() -> void:
	# SYSTEM OFFLINE: the picture loses its colour and breaks up; two choices.
	_busy = true
	W.player_down.emit()
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
