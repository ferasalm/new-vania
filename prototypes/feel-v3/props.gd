# PROTOTYPE - NOT FOR PRODUCTION
# Things that stand in a room and answer to her: levers, iron bars, the cracked wall,
# candles, the winch, shutters, decor cues, and the time machine (the organ).
# Levers, candles and the winch register with G.main.interact.
extends RefCounted

const TILE := 16.0


static func has_tex(rel: String) -> bool:
	return ResourceLoader.exists("res://assets/2x/" + rel) or ResourceLoader.exists("res://assets/" + rel) \
		or FileAccess.file_exists("res://assets/2x/" + rel) or FileAccess.file_exists("res://assets/" + rel)


# A lever on a floor. "library": any cut or Up pulls it. "bars": only an Elegy cut moves it.
class Lever extends Node2D:
	var kind := "library"
	var cut_only := false
	var pulled := false
	var _angle := -0.75
	var _t := 0.0

	func setup(k: String, is_pulled: bool) -> void:
		kind = k
		cut_only = (k == "bars")
		pulled = is_pulled
		_angle = 0.75 if pulled else -0.75
		z_index = 2
		_register()

	func _register() -> void:
		if not pulled and G.main != null and G.main.get("interact") != null:
			G.main.get("interact").register(self, "lever", "PULL", Callable(self, "pull"), 24.0)

	func prop_rect() -> Rect2:
		return Rect2(global_position + Vector2(-8, -28), Vector2(16, 28))

	func prop_cut(_dmg: float, elegy: bool) -> bool:
		if pulled or (cut_only and not elegy):
			return false
		pull()
		return true

	func pull() -> void:
		if pulled:
			return
		pulled = true
		if G.main != null and G.main.get("interact") != null:
			G.main.get("interact").unregister(self)
		var tw := create_tween()
		tw.tween_property(self, "_angle", 0.75, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sfx.play_file("sfx/world/lever.wav", -4.0)
		if G.main != null:
			G.main.shake(2.0, 0.35)
			G.main.fx("spark", global_position + Vector2(0, -16))
			if kind == "library":
				G.main.lever_library = true
				if G.main.get("ambience") != null and G.main.get("ambience").has_method("cue"):
					G.main.get("ambience").cue("chain_boom", global_position)
			else:
				G.main.open_bars()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var brass := Color(0.85, 0.65, 0.3) if kind == "bars" else Color(0.7, 0.8, 0.85)
		if not pulled:
			var g := 0.5 + 0.5 * sin(_t * 4.0)
			draw_circle(Vector2(0, -14), 13.0 + g * 2.0, Color(1.0, 0.8, 0.3, 0.10 + 0.08 * g))
		draw_rect(Rect2(-7, -4, 14, 4), Color(0.12, 0.11, 0.13))
		draw_rect(Rect2(-7, -4, 14, 1), Color(0.35, 0.33, 0.38))
		draw_rect(Rect2(-2, -9, 4, 5), Color(0.2, 0.19, 0.22))
		var tip := Vector2(0, -8) + Vector2(sin(_angle), -cos(_angle)) * 14.0
		draw_line(Vector2(0, -8), tip, Color(0.1, 0.08, 0.08), 3.0)
		draw_line(Vector2(0, -8), tip, brass, 1.5)
		draw_circle(tip, 2.6, Color(0.1, 0.08, 0.08))
		draw_circle(tip, 1.8, Color(0.4, 1.0, 0.5) if pulled else Color(1.0, 0.3, 0.25))


# Iron bars across an opening. They block her until a lever lifts them out of the way.
class Bars extends Node2D:
	var rect := Rect2()
	var open_t := 0.0
	var _shape: CollisionShape2D

	func setup(r: Rect2, already_open: bool) -> void:
		rect = r
		z_index = 2
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		_shape = CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = r.size
		_shape.shape = rs
		_shape.position = r.get_center()
		body.add_child(_shape)
		add_child(body)
		if already_open:
			open_t = 1.0
			_shape.disabled = true

	func raise() -> void:
		if open_t >= 1.0:
			return
		_shape.disabled = true
		Sfx.play_file("sfx/world/lever.wav", -2.0)
		var tw := create_tween()
		tw.tween_property(self, "open_t", 1.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func():
			if G.main != null:
				G.main.room_opened(rect)
		)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if open_t >= 1.0:
			return
		var lift := rect.size.y * open_t
		var iron := Color(0.28, 0.27, 0.3)
		var edge := Color(0.5, 0.48, 0.55)
		var count := maxi(1, int(rect.size.x / 8.0))
		for i in count:
			var x := rect.position.x + (i + 0.5) * (rect.size.x / count)
			var top := rect.position.y - lift
			var bot := rect.end.y - lift
			draw_line(Vector2(x, top), Vector2(x, bot), iron, 2.0)
			draw_line(Vector2(x - 0.5, top), Vector2(x - 0.5, bot), edge, 0.5)


# A cracked wall: breaks when struck 3 times with any weapon.
class CrackWall extends Node2D:
	var rect := Rect2()
	var broken := false
	var hits := 0
	var _tiles: Texture2D
	var _tint: Color
	var _shape: CollisionShape2D
	var _dust_t := 0.0

	func setup(r: Rect2, tiles: Texture2D, tint: Color, is_broken: bool) -> void:
		rect = r
		_tiles = tiles
		_tint = tint
		broken = is_broken
		z_index = 2
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		_shape = CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = r.size
		_shape.shape = rs
		_shape.position = r.get_center()
		body.add_child(_shape)
		add_child(body)
		if broken:
			_shape.disabled = true

	func prop_rect() -> Rect2:
		return Rect2(global_position + rect.position, rect.size)

	func prop_cut(_dmg: float, _elegy: bool) -> bool:
		if broken:
			return false
		hits += 1
		if hits >= 3:
			break_wall()
		else:
			Sfx.play_file("sfx/world/locked.wav", -6.0)
			if G.main != null:
				G.main.shake(1.2, 0.15)
				G.main.dust(global_position + rect.get_center(), 6)
			queue_redraw()
		return true

	func break_wall() -> void:
		if broken:
			return
		broken = true
		_shape.disabled = true
		Sfx.play_file("sfx/world/boom.wav", -2.0)
		if G.main != null:
			G.main.shake(3.0, 0.4)
			G.main.dust(global_position + rect.get_center(), 18)
			G.main.wall_broke(rect)
		queue_redraw()

	func _process(delta: float) -> void:
		if not broken:
			_dust_t += delta
			if _dust_t >= 2.5:
				_dust_t = 0.0
				if G.main != null and G.main.get("ambience") != null and G.main.get("ambience").has_method("cue"):
					G.main.get("ambience").cue("dust", global_position + rect.get_center())

	func _draw() -> void:
		if broken:
			return
		draw_rect(rect, Color(0.1, 0.08, 0.1))
		var cx := rect.get_center().x
		var cy := rect.get_center().y
		var crack_col := Color(0.9, 0.7, 0.4, 0.7)
		draw_line(Vector2(cx, rect.position.y), Vector2(cx + (hits * 2.0), cy), crack_col, 1.0)
		draw_line(Vector2(cx + (hits * 2.0), cy), Vector2(cx - 3.0, rect.end.y), crack_col, 1.0)


# A candle stand. Lighting it tolls a bell, sets W.flag("candle_n"), and lights a sconce on the X door.
class Candle extends Node2D:
	var num := 1
	var lit := false
	var _flicker := 0.0

	func setup(n: int, is_lit: bool) -> void:
		num = n
		lit = is_lit
		z_index = 2
		_register()

	func _register() -> void:
		if not lit and G.main != null and G.main.get("interact") != null:
			G.main.get("interact").register(self, "candle", "LIGHT", Callable(self, "light"), 24.0)

	func light() -> void:
		if lit:
			return
		lit = true
		W.set_flag("candle_%d" % num, true)
		if G.main != null and G.main.get("interact") != null:
			G.main.get("interact").unregister(self)
		if G.main != null and G.main.get("ambience") != null and G.main.get("ambience").has_method("cue"):
			G.main.get("ambience").cue("candle", global_position)
		queue_redraw()

	func _process(delta: float) -> void:
		_flicker += delta * 12.0
		queue_redraw()

	func _draw() -> void:
		# Stand
		draw_rect(Rect2(-4, -2, 8, 2), Color(0.2, 0.18, 0.16))
		draw_line(Vector2(0, -2), Vector2(0, -14), Color(0.35, 0.3, 0.25), 1.5)
		draw_circle(Vector2(0, -14), 2.0, Color(0.4, 0.35, 0.3))
		# Candle wax
		draw_rect(Rect2(-2, -22, 4, 8), Color(0.85, 0.82, 0.75))
		if lit:
			var fl := sin(_flicker) * 0.8
			draw_circle(Vector2(fl * 0.5, -25), 3.0, Color(1.0, 0.7, 0.2, 0.8))
			draw_circle(Vector2(fl * 0.5, -25), 1.5, Color(1.0, 0.95, 0.6))
			draw_circle(Vector2(0, -24), 8.0, Color(1.0, 0.6, 0.1, 0.15))


# A winch. Turning it stops every HZ trap for good.
class Winch extends Node2D:
	var turned := false
	var _angle := 0.0

	func setup(is_turned: bool) -> void:
		turned = is_turned
		_angle = PI * 0.5 if turned else 0.0
		z_index = 2
		_register()

	func _register() -> void:
		if not turned and G.main != null and G.main.get("interact") != null:
			G.main.get("interact").register(self, "winch", "TURN", Callable(self, "turn"), 24.0)

	func turn() -> void:
		if turned:
			return
		turned = true
		W.set_flag("winch_turned", true)
		if G.main != null and G.main.get("interact") != null:
			G.main.get("interact").unregister(self)
		var tw := create_tween()
		tw.tween_property(self, "_angle", PI * 2.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if G.main != null and G.main.get("ambience") != null and G.main.get("ambience").has_method("cue"):
			G.main.get("ambience").cue("winch", global_position)
		queue_redraw()

	func _draw() -> void:
		# Wheel and chain spool
		draw_circle(Vector2(0, -16), 10.0, Color(0.3, 0.28, 0.32))
		draw_circle(Vector2(0, -16), 7.0, Color(0.15, 0.14, 0.16))
		for i in 4:
			var a := _angle + i * (PI / 2.0)
			draw_line(Vector2(0, -16), Vector2(cos(a) * 9.0, -16 + sin(a) * 9.0), Color(0.6, 0.55, 0.5), 1.5)
		draw_rect(Rect2(-3, -8, 6, 8), Color(0.2, 0.18, 0.2))


# One-way shutter: opens only from HZ~ toward OR~.
class Shutter extends Node2D:
	var open := false
	var file_id := ""
	var _shape: CollisionShape2D
	var _open_t := 0.0

	func setup(r: Rect2, fid: String, is_open: bool) -> void:
		file_id = fid
		open = is_open
		_open_t = 1.0 if open else 0.0
		z_index = 2
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		_shape = CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = r.size
		_shape.shape = rs
		_shape.position = r.get_center()
		body.add_child(_shape)
		add_child(body)
		if open:
			_shape.disabled = true

	func open_shutter() -> void:
		if open:
			return
		open = true
		_shape.disabled = true
		W.set_flag("shutter_" + file_id, true)
		var tw := create_tween()
		tw.tween_property(self, "_open_t", 1.0, 0.4)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if _open_t >= 1.0:
			return
		var h := 32.0 * (1.0 - _open_t)
		draw_rect(Rect2(-4, -h, 8, h), Color(0.4, 0.38, 0.42))
		for i in int(h / 6.0):
			draw_line(Vector2(-3, -h + i * 6.0), Vector2(3, -h + i * 6.0), Color(0.2, 0.18, 0.2), 1.0)


# Decor: visual cues placed in the world (claw marks, fur, cold air markers).
class Decor extends Node2D:
	var kind := "claws"

	func setup(k: String) -> void:
		kind = k
		z_index = 1

	func _draw() -> void:
		if kind == "claws":
			var c := Color(0.15, 0.12, 0.18, 0.8)
			for i in 3:
				var ox := -4.0 + i * 3.5
				draw_line(Vector2(ox, -6), Vector2(ox + 3.0, 6), c, 1.0)
		elif kind == "cold_air":
			var c := Color(0.6, 0.8, 1.0, 0.25)
			draw_arc(Vector2.ZERO, 6.0, 0.0, PI, 8, c, 0.5)


# The Organ of Hours (time machine).
class Organ extends Node2D:
	var dead := false

	func setup() -> void:
		z_index = 2
		_register()

	func _register() -> void:
		if not dead and G.main != null and G.main.get("interact") != null:
			G.main.get("interact").register(self, "organ", "USE", Callable(self, "use"), 32.0)

	func use() -> void:
		if dead:
			Sfx.play_file("sfx/world/locked.wav", -4.0)
			return
		if G.main != null and G.main.get("dialog") != null:
			G.main.get("dialog").ask()

	func _draw() -> void:
		# Organ console placeholder
		draw_rect(Rect2(-16, -28, 32, 28), Color(0.18, 0.12, 0.16))
		draw_rect(Rect2(-12, -24, 24, 10), Color(0.3, 0.2, 0.28))
		for i in 6:
			var px := -10.0 + i * 4.0
			draw_line(Vector2(px, -24), Vector2(px, -36 - (i % 3) * 4), Color(0.7, 0.55, 0.3), 1.5)
