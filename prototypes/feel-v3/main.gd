# PROTOTYPE - NOT FOR PRODUCTION
# Runs the prototype: loads a room, the hero and the enemies, resolves hits,
# moves between rooms through doors, and owns the effects (sparks, dust,
# numbers, shake, the short hit pause).
extends Node2D

const Room := preload("res://room.gd")
const Player := preload("res://player.gd")
const Enemy := preload("res://enemy.gd")
const Hud := preload("res://hud.gd")
const TuningPanel := preload("res://tuning_panel.gd")

var world: Node2D
var room: Node2D
var player: CharacterBody2D
var cam: Camera2D
var hud: CanvasLayer
var panel: CanvasLayer
var room_name := ""
var enemies: Array = []
var kills := 0
var _shake_t := 0.0
var _shake_amp := 0.0
var _busy := false           # a door or death transition is running
var _door_armed := false
var _entry := "P"


func _ready() -> void:
	G.main = self
	hud = Hud.new()
	add_child(hud)
	panel = TuningPanel.new()
	add_child(panel)
	enter("room1", "P")
	Sfx.play_music("music_room")


func enter(next_room: String, spawn_key: String) -> void:
	if world != null:
		world.queue_free()
	enemies.clear()
	world = Node2D.new()
	add_child(world)
	room = Room.new()
	world.add_child(room)
	room.load_room(next_room)
	room_name = next_room
	_entry = spawn_key
	var keep_hp: float = player.hp if player != null and player.hp > 0.0 else T.v("player_hp")
	var keep_facing: int = player.facing if player != null else 1
	player = Player.new()
	player.position = room.spawns.get(spawn_key, room.spawns.get("P", Vector2(64, 64)))
	world.add_child(player)
	player.hp = keep_hp
	player.facing = keep_facing if spawn_key != "P" else 1
	if spawn_key == "D":
		player.facing = -1
	elif spawn_key == "B":
		player.facing = 1
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
		var en := Enemy.new()
		en.position = e[1]
		en.setup(e[0])
		world.add_child(en)
		enemies.append(en)
	_door_armed = false


func _physics_process(delta: float) -> void:
	if _busy or G.frozen() or player == null:
		return
	var body: Rect2 = player.body_rect()
	for en in enemies:
		if is_instance_valid(en) and en.can_hurt() and player.invuln <= 0.0 and en.hurt_rect().intersects(body):
			player.take_hit(en.damage(), en.global_position.x)
			en.touched_player()
	# doors: walk into one to go through; it re-arms once you step away
	var in_door := false
	for d in room.doors:
		if d["rect"].intersects(body):
			in_door = true
			if _door_armed and d["to"] != "":
				_through(d["to"], "B" if d["key"] == "D" else "D")
				return
	if not in_door:
		_door_armed = true


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart") and not _busy:
		player.hp = T.v("player_hp")
		enter("room1", "P")
	if cam != null and is_instance_valid(cam):
		if _shake_t > 0.0:
			_shake_t -= delta
			cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_amp
		else:
			cam.offset = Vector2.ZERO
	hud.refresh(player.hp, T.v("player_hp"), kills)


func player_swing(rect: Rect2, dmg: float, dir: int, already: Array) -> void:
	for en in enemies:
		if not is_instance_valid(en) or already.has(en):
			continue
		if en.hurt_rect().intersects(rect):
			already.append(en)
			var at: Vector2 = en.hurt_rect().get_center()
			en.take_hit(dmg, dir)
			fx("spark", at)
			number(at + Vector2(0, -14), int(dmg), Color("#F4F0E0"))
			Sfx.play("hit")
			G.hitstop = T.v("hitstop")
			shake(T.v("shake"), 0.1)


func enemy_died(en: Node2D) -> void:
	kills += 1
	enemies.erase(en)
	fx("burst", en.hurt_rect().get_center())
	Sfx.play("enemy_die")


func player_died() -> void:
	_busy = true
	await hud.fade(1.0, 0.5)
	player.hp = T.v("player_hp")
	enter(room_name, _entry)
	await hud.fade(0.0, 0.3)
	_busy = false


func _through(to: String, spawn_key: String) -> void:
	_busy = true
	Sfx.play("door")
	await hud.fade(1.0, 0.18)
	enter(to, spawn_key)
	await hud.fade(0.0, 0.18)
	_busy = false


func shake(amp: float, time: float) -> void:
	_shake_amp = amp
	_shake_t = time


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
