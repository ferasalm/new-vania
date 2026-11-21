# PROTOTYPE - NOT FOR PRODUCTION
# The boss arena system: builds the boss the room asks for, seals the way back,
# runs the fight timer, drops the scythe, hands out the reward and owns the
# wall-latch relic that waits in the lab. One boss at a time.
extends Node

signal fight_ended(id: String, won: bool, seconds: float)

const Spawner := preload("res://spawner.gd")
const Props := preload("res://props.gd")

var boss: Node2D
var mode := "normal"       # normal | recall (S8)
var fight_time := 0.0
var _relic: Node2D
var _scythe: Node2D
var _id := ""
var _seal: Node2D             # the bars over a floor hole while a fight is on (the Kennel)
var _reward: Node2D           # the wall jump THE UNMUZZLED leaves


func attach(b: Node2D) -> void:
	# the arena now watches this boss
	boss = b
	var bid = b.get("boss_id")
	_id = String(bid) if bid != null else "pallbearer"
	fight_time = 0.0


func detach() -> void:
	# the room is being freed
	boss = null
	_id = ""
	fight_time = 0.0
	_relic = null
	_scythe = null
	_seal = null
	_reward = null


func spawn(world: Node2D, boss_id: String, feet: Vector2, room_size: Vector2) -> Array:
	# build the boss for this room and return the parts her weapon can hit
	var b: Node2D = Spawner.boss(boss_id, feet, room_size)
	if b == null:
		return []
	world.add_child(b)
	attach(b)
	return b.parts()


func room_setup(room: Node2D, world: Node2D) -> Array:
	# everything the arena adds to a room that is being built: the boss, the
	# scythe she left behind and the wall-latch relic
	boss = null
	_id = ""
	fight_time = 0.0
	_relic = null
	_scythe = null
	_seal = null
	_reward = null
	var parts: Array = []
	if room.spawns.has("O") and _o_boss(room) == "unmuzzled":
		parts = _wolf_setup(room, world)
	elif room.spawns.has("O"):
		if not W.flag("beaten_pallbearer"):
			parts = spawn(world, "pallbearer", room.spawns["O"], room.size)
		elif not G.main.has_elegy:
			drop_scythe(room.spawns["O"] + Vector2(0, -26))
	if room.spawns.has("A") and not G.main.has_latch:
		place_relic(room, world)
	return parts


func tick(delta: float, player: Node2D) -> void:
	# one tick of the arena: the fight starts, the relic and the scythe wait, the timer runs
	_watch(player)
	if boss != null and is_instance_valid(boss) and boss.started and boss.alive:
		fight_time += delta


func _o_boss(room: Node2D) -> String:
	# which boss the room's O mark asks for (rooms_meta marks); none named = the Pallbearer
	var mk = room.meta.get("marks", {}).get("O", {})
	return String(mk.get("boss", "pallbearer")) if mk is Dictionary else "pallbearer"


func _wolf_setup(room: Node2D, world: Node2D) -> Array:
	# the Kennel: the werewolf waits until he is beaten. Beaten but the wall jump not yet
	# taken (she died or left): it waits on the floor. A save from before the werewolf
	# that already owns the wall jump: no fight, no second one, and he counts as beaten.
	var has_wj: bool = G.main.has_latch
	if not W.flag("beaten_unmuzzled") and not has_wj:
		return spawn(world, "unmuzzled", room.spawns["O"], room.size)
	if not W.flag("beaten_unmuzzled"):
		W.set_flag("beaten_unmuzzled", true)
	elif not has_wj:
		drop_wall_jump(room.size.x / 2.0)
	return []


func _watch(player: Node2D) -> void:
	if boss == null or not is_instance_valid(boss) or boss.started:
		return
	if _id == "unmuzzled":
		# the fight starts once she is up out of the hole and standing in the room
		var room: Node2D = G.main.room
		var clear_x: float = room.down_span.y + 4.0 if room.down_span.x >= 0.0 else 72.0
		if player.is_on_floor() and player.global_position.x > clear_x:
			boss.begin()
			W.boss_started.emit(_id)
		return
	if player.global_position.x > 72.0:
		# the way back shuts and the fight starts
		var room: Node2D = G.main.room
		if room.doors.has("left"):
			room.doors["left"].held = true
		boss.begin()
		W.boss_started.emit(_id)


func bar_name(pallbearer_title: String) -> String:
	# the name over the boss bar: a boss that knows its own name says it
	return boss.title() if boss.has_method("title") else pallbearer_title


func bar_fill() -> float:
	# how full the boss bar is, 0..1
	var full: float = boss.max_hp() if boss.has_method("max_hp") else T.v("boss_hp")
	return boss.hp / maxf(1.0, full)


func dying(_b: Node2D) -> void:
	# the boss is breaking up: clear its shots and hold the bar down
	G.main.hud.boss_bar("", 0.0)
	for s in G.main.shots:
		s.queue_free()
	G.main.shots.clear()
	G.main.shake(4.0, 1.2)


func seal() -> void:
	# a fight that seals the way out: every door is held and a floor hole gets bars
	var room: Node2D = G.main.room
	for d in room.doors_all:
		d.held = true
	if room.down_span.x >= 0.0 and (_seal == null or not is_instance_valid(_seal)):
		_seal = HoleSeal.new()
		_seal.setup(room.down_span, room.size.y)
		room.add_child(_seal)
		room.doors["down"] = _seal
	G.main.shake(3.0, 0.3)
	Sfx.play_file("sfx/world/locked.wav", -4.0)


func unseal() -> void:
	var room: Node2D = G.main.room
	for d in room.doors_all:
		d.held = false
	if _seal != null and is_instance_valid(_seal):
		room.doors.erase("down")
		_seal.queue_free()
	_seal = null


func drop_wall_jump(x: float) -> void:
	# GRIP SERVOS: the werewolf's wall jump, on the floor, taken with Up like the scythe
	var room: Node2D = G.main.room
	var safe_x := x
	if room.down_span.x >= 0.0:
		safe_x = maxf(x, room.down_span.y + 24.0)
	safe_x = clampf(safe_x, 40.0, room.size.x - 40.0)
	_reward = G.main.loot.spawn_pickup("wall_jump", Vector2(safe_x, room.size.y - 32.0 - 8.0), {"life": 100000.0, "touch_take": false})
	if _reward != null:
		_reward.taken.connect(func(_i): _reward = null)


func _wolf_down(b: Node2D, at: Vector2) -> void:
	# counts once: the test hook (debug_win) and his own death both end here
	if boss == null:
		return
	if is_instance_valid(b):
		b.queue_free()
	W.set_flag("beaten_unmuzzled", true)
	G.main.kills += 1
	G.main.enemies = G.main.enemies.filter(func(e): return is_instance_valid(e) and e.kind != "boss")
	boss = null
	unseal()
	# no XP, like the Pallbearer: xp_unmuzzled exists in tuning, but no boss pays it yet
	G.main.ring_fx(at, 140.0, Color(1.0, 0.6, 0.4))
	G.main.hud.toast("THE UNMUZZLED LIES STILL", 4.0)
	if not G.main.has_latch:
		drop_wall_jump(at.x)
	W.boss_down.emit("unmuzzled", at)
	fight_ended.emit("unmuzzled", true, fight_time)


func down(b: Node2D, at: Vector2 = Vector2.ZERO) -> void:
	# the boss is dead: flag it, count it, unlock the way, drop the scythe
	if _id == "unmuzzled":
		_wolf_down(b, at)
		return
	var room: Node2D = G.main.room
	W.set_flag("beaten_pallbearer", true)
	G.main.kills += 1
	G.main.enemies = G.main.enemies.filter(func(e): return is_instance_valid(e) and e.kind != "boss")
	boss = null
	if room.doors.has("left"):
		room.doors["left"].held = false
		room.doors["left"].locked = false
	G.main.ring_fx(room.size / 2.0, 160.0, Color(1.0, 0.85, 0.4))
	G.main.hud.toast("LAID TO REST", 4.0)
	Sfx.play_music("music_save")
	if not G.main.has_elegy:
		drop_scythe(at if at != Vector2.ZERO else room.size / 2.0)
	var won_id := _id if _id != "" else "pallbearer"
	W.boss_down.emit(won_id, at)
	fight_ended.emit(won_id, true, fight_time)


func debug_win() -> void:
	# the test hook: end the fight now
	if boss == null or not is_instance_valid(boss):
		return
	boss.hp = 0.0
	boss.alive = false
	down(boss, boss.global_position)


func place_relic(room: Node2D, _world: Node2D) -> void:
	# the wall-latch relic (GRIP SERVOS) is a placed pickup owned by the loot path;
	# it waits for ever, because it is placed, not dropped
	if not room.spawns.has("A"):
		return
	_relic = G.main.loot.spawn_pickup("wall_jump", room.spawns["A"] + Vector2(0, -12), {"life": 100000.0, "touch_take": false})
	_relic.taken.connect(func(_id): _relic = null)


func drop_scythe(at: Vector2) -> void:
	# the scythe falls from where the body was and floats a little above the floor
	var room: Node2D = G.main.room
	var floor_y: float = room.spawns["O"].y if room.spawns.has("O") else room.size.y - 32.0
	# she takes it with Up, and the pickup card shows it (no touch, no toast: user ask C5)
	_scythe = G.main.loot.spawn_pickup("elegy_013", Vector2(at.x, floor_y - 8.0), {"life": 100000.0, "touch_take": false})
	_scythe.taken.connect(_on_scythe_taken)


func _on_scythe_taken(_id: String) -> void:
	_scythe = null
	Sfx.play("special", 1.3)
	var p: Node2D = G.main.player
	if p != null:
		G.main.ring_fx(p.global_position + Vector2(0, -20), 70.0, Color(0.5, 1.0, 1.0))
	if G.main.touch != null:
		G.main.touch.queue_redraw()


# The bars that close a floor hole while a fight is on. It stands in room.doors["down"]
# like a door that is held shut, so everything that asks "is the way out sealed" gets yes.
class HoleSeal extends Node2D:
	var side := "down"
	var to := ""
	var boss := true
	var locked := true
	var held := true
	var _span := Vector2.ZERO
	var _y := 0.0

	func setup(span: Vector2, room_h: float) -> void:
		_span = span
		_y = room_h - 16.0
		z_index = 3
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(span.y - span.x, 16.0)
		shape.shape = rect
		shape.position = Vector2((span.x + span.y) / 2.0, _y + 8.0)
		body.add_child(shape)
		add_child(body)

	func feet() -> Vector2:
		return Vector2((_span.x + _span.y) / 2.0, _y)

	func refuse() -> void:
		Sfx.play_file("sfx/world/locked.wav", -4.0)

	func _draw() -> void:
		draw_rect(Rect2(_span.x, _y, _span.y - _span.x, 5.0), Color(0.35, 0.3, 0.32))
		var x := _span.x + 3.0
		while x < _span.y:
			draw_rect(Rect2(x, _y - 2.0, 3.0, 16.0), Color(0.55, 0.5, 0.5))
			x += 10.0
		draw_rect(Rect2(_span.x, _y + 9.0, _span.y - _span.x, 3.0), Color(0.6, 0.15, 0.15))
