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
	var parts: Array = []
	if room.spawns.has("O"):
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
	_relic_watch(player)
	_scythe_watch(player)
	if boss != null and is_instance_valid(boss) and boss.started and boss.alive:
		fight_time += delta


func _watch(player: Node2D) -> void:
	if boss == null or not is_instance_valid(boss) or boss.started:
		return
	if player.global_position.x > 72.0:
		# the way back shuts and the fight starts
		var room: Node2D = G.main.room
		if room.doors.has("left"):
			room.doors["left"].locked = true
		boss.begin()
		W.boss_started.emit(_id)
		G.main.hud.toast("ITS HANDS ARE YOUR STAIRS")


func dying(_b: Node2D) -> void:
	# the boss is breaking up: clear its shots and hold the bar down
	G.main.hud.boss_bar("", 0.0)
	for s in G.main.shots:
		s.queue_free()
	G.main.shots.clear()
	G.main.shake(4.0, 1.2)


func down(b: Node2D, at: Vector2 = Vector2.ZERO) -> void:
	# the boss is dead: flag it, count it, unlock the way, drop the scythe
	var room: Node2D = G.main.room
	W.set_flag("beaten_pallbearer", true)
	G.main.kills += 1
	G.main.enemies = G.main.enemies.filter(func(e): return is_instance_valid(e) and e.kind != "boss")
	boss = null
	if room.doors.has("left"):
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


func place_relic(room: Node2D, world: Node2D) -> void:
	# the wall-latch relic: a slowly bobbing cyan claw-mark she walks into
	if not room.spawns.has("A"):
		return
	_relic = Relic.new()
	_relic.position = room.spawns["A"] + Vector2(0, -22)
	_relic.z_index = 6
	world.add_child(_relic)


func _relic_watch(player: Node2D) -> void:
	if _relic == null or not is_instance_valid(_relic):
		return
	if _relic.position.distance_to(player.global_position + Vector2(0, -18)) < 18.0:
		_relic.queue_free()
		_relic = null
		G.main.has_latch = true
		Sfx.play("pickup", 0.6)
		Sfx.play("special", 1.3)
		G.main.ring_fx(player.global_position + Vector2(0, -20), 60.0, Color(0.5, 1.0, 1.0))
		G.main.hud.toast("GRIP SERVOS ONLINE  -  jump at a wall and hold toward it to cling, jump again to kick off", 7.0)


func drop_scythe(at: Vector2) -> void:
	# the scythe falls from where the body was and floats a little above the floor
	var room: Node2D = G.main.room
	var sc := Props.Scythe.new()
	var floor_y: float = room.spawns["O"].y if room.spawns.has("O") else room.size.y - 32.0
	sc.setup(at, floor_y - 26.0)
	G.main.world.add_child(sc)
	_scythe = sc


func _scythe_watch(player: Node2D) -> void:
	if _scythe == null or not is_instance_valid(_scythe):
		return
	if _scythe.global_position.distance_to(player.global_position + Vector2(0, -18)) < 22.0:
		_scythe.queue_free()
		_scythe = null
		G.main.has_elegy = true
		Sfx.play("pickup", 0.6)
		Sfx.play("special", 1.3)
		Sfx.play("pickup", 1.0)
		G.main.ring_fx(player.global_position + Vector2(0, -20), 70.0, Color(0.5, 1.0, 1.0))
		G.main.hud.toast("ELEGY-013 - the Pallbearer's scythe is yours. E (or SWAP) to change weapon.", 7.0)
		if G.main.touch != null:
			G.main.touch.queue_redraw()


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
