# PROTOTYPE - NOT FOR PRODUCTION
# Things that stand in a room and answer to her: the two levers (the library lever
# that opens the church's lower door, the lever behind the iron bars), the iron bars,
# the cracked wall, the time machine (the organ), and the scythe the boss leaves behind.
# Each one is drawn by code, so no art is needed. A "cut" prop has prop_rect() and
# prop_cut(): main.player_cut() feeds it her weapon's blade points. The blade wave
# (the Dirge special) never reaches a prop.
extends RefCounted

const TILE := 16.0


static func has_tex(rel: String) -> bool:
	# true when a picture exists (so a missing one stays silent and a placeholder is drawn)
	return ResourceLoader.exists("res://assets/2x/" + rel) or ResourceLoader.exists("res://assets/" + rel) \
		or FileAccess.file_exists("res://assets/2x/" + rel) or FileAccess.file_exists("res://assets/" + rel)


# A lever on a floor. "library": any cut or Up pulls it. "bars": only an Elegy cut moves it.
class Lever extends Node2D:
	var kind := "library"
	var cut_only := false          # true: only the Elegy cut moves it
	var pulled := false
	var _angle := -0.75            # handle angle: up-left (not pulled) .. down-right (pulled)
	var _t := 0.0

	func setup(k: String, is_pulled: bool) -> void:
		kind = k
		cut_only = (k == "bars")
		pulled = is_pulled
		_angle = 0.75 if pulled else -0.75
		z_index = 2

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
		var tw := create_tween()
		tw.tween_property(self, "_angle", 0.75, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sfx.play_file("sfx/world/lever.wav", -4.0)
		G.main.shake(2.0, 0.35)
		G.main.fx("spark", global_position + Vector2(0, -16))
		if kind == "library":
			G.main.lever_library = true
			G.main.hud.toast("Far below, a door grinds open.", 3.5)
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
	var rect := Rect2()            # local to the room
	var open_t := 0.0              # 0 shut .. 1 gone
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
		var tw := create_tween()
		tw.tween_property(self, "open_t", 1.0, T.v("bars_rise_time"))
		Sfx.play_file("sfx/world/bars_open.wav", -3.0)
		G.main.shake(2.5, T.v("bars_rise_time"))

	func _process(_delta: float) -> void:
		if open_t > 0.75 and not _shape.disabled:
			_shape.set_deferred("disabled", true)
			G.main.room_opened(rect)
		queue_redraw()

	func _draw() -> void:
		var drop := rect.size.y * open_t
		var bottom := rect.end.y - drop
		if bottom <= rect.position.y + 1.0:
			return
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, bottom - rect.position.y)), Color(0, 0, 0, 0.55))
		var x := rect.position.x + 2.0
		while x < rect.end.x - 1.0:
			draw_rect(Rect2(x, rect.position.y, 3, bottom - rect.position.y), Color(0.16, 0.15, 0.17))
			draw_rect(Rect2(x, rect.position.y, 1, bottom - rect.position.y), Color(0.5, 0.48, 0.52))
			x += 6.0
		draw_rect(Rect2(rect.position.x, bottom - 3.0, rect.size.x, 3), Color(0.22, 0.2, 0.23))
		draw_rect(Rect2(rect.position.x, bottom - 3.0, rect.size.x, 1), Color(0.55, 0.5, 0.45))
		draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 3), Color(0.22, 0.2, 0.23))


# A wall that gives way after a few cuts: drawn like the stone around it, with cracks.
class CrackWall extends Node2D:
	var rect := Rect2()
	var hits := 0
	var broken := false
	var tiles: Texture2D
	var tint := Color.WHITE
	var _shape: CollisionShape2D
	var _flash := 0.0

	func setup(r: Rect2, tile_tex: Texture2D, tile_tint: Color, is_broken: bool) -> void:
		rect = r
		tiles = tile_tex
		tint = tile_tint
		broken = is_broken
		z_index = 1
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
		_shape.disabled = broken

	func prop_rect() -> Rect2:
		return rect

	func prop_cut(_dmg: float, _elegy: bool) -> bool:
		if broken:
			return false
		hits += 1
		_flash = 0.15
		var at := global_position + rect.get_center()
		G.main.dust(at, 6)
		G.main.fx("spark", at)
		G.main.shake(2.0, 0.15)
		if hits >= int(T.v("crack_hits")):
			broken = true
			_shape.set_deferred("disabled", true)
			Sfx.play_file("sfx/world/wall_crumble.wav", -2.0)
			G.main.shake(4.0, 0.5)
			G.main.dust(at, 16)
			G.main.wall_broke(rect)
			_rubble()
		else:
			Sfx.play_file("sfx/world/wall_crack.wav", -3.0, 0.92 + 0.08 * hits)
		return true

	func _rubble() -> void:
		for i in 14:
			var p := ColorRect.new()
			p.color = Color(0.45, 0.4, 0.35)
			p.size = Vector2(3, 3)
			p.position = rect.position + Vector2(randf() * rect.size.x, randf() * rect.size.y)
			add_child(p)
			var tw := p.create_tween().set_parallel(true)
			tw.tween_property(p, "position:y", rect.end.y - 3.0, 0.4 + randf() * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_property(p, "color:a", 0.0, 0.9)
			tw.chain().tween_callback(p.queue_free)

	func _process(delta: float) -> void:
		_flash = maxf(0.0, _flash - delta)
		queue_redraw()

	func _draw() -> void:
		if broken:
			return
		var cols := int(rect.size.x / TILE)
		var rows := int(rect.size.y / TILE)
		for cy in rows:
			for cx in cols:
				var dst := Rect2(rect.position + Vector2(cx * TILE, cy * TILE), Vector2(TILE, TILE))
				if tiles != null:
					draw_texture_rect_region(tiles, dst, Rect2((cx % 4) * TILE, 0, TILE, TILE), tint * Color(1.15, 1.05, 0.95))
				else:
					draw_rect(dst, Color(0.4, 0.36, 0.3))
		# the cracks grow with every hit; a few hairlines show from the start
		var c := Color(0.02, 0.02, 0.04, 0.9)
		var mid := rect.get_center()
		draw_line(mid + Vector2(-5, -10), mid + Vector2(-2, -3), c, 1.0)
		draw_line(mid + Vector2(-2, -3), mid + Vector2(-6, 4), c, 1.0)
		if hits >= 1:
			draw_line(mid + Vector2(-2, -3), mid + Vector2(5, 0), c, 1.0)
			draw_line(mid + Vector2(5, 0), mid + Vector2(4, 9), c, 1.0)
			draw_line(mid + Vector2(-6, 4), mid + Vector2(-4, 12), c, 1.0)
		if hits >= 2:
			draw_line(mid + Vector2(-5, -10), mid + Vector2(1, -15), c, 1.0)
			draw_line(mid + Vector2(5, 0), mid + Vector2(7, -8), c, 1.0)
			draw_line(mid + Vector2(1, -15), mid + Vector2(4, -12), c, 1.0)
		# a faint pulse says "this one gives"
		var pulse := 0.06 + 0.04 * sin(Time.get_ticks_msec() / 260.0)
		draw_rect(rect, Color(1.0, 0.85, 0.5, pulse + (0.5 if _flash > 0.0 else 0.0)))


# The time machine: a pipe organ the height of two rooms. Uses organ/idle_NN.png when it
# exists (anchored bottom-centre on its feet), a drawn placeholder otherwise.
class Organ extends Node2D:
	var dead := false              # after the shift it is silent
	var _frames: Array = []
	var _t := 0.0
	var _glow := 0.0
	var _hum: AudioStreamPlayer2D

	func setup() -> void:
		z_index = 2
		var n := 0
		while n < 40 and exists("organ/idle_%02d.png" % n):
			_frames.append(G.tex("organ/idle_%02d.png" % n))
			n += 1
		_hum = AudioStreamPlayer2D.new()
		var st: AudioStream = Sfx._load("sfx/shift/machine_hum.wav")
		if st != null:
			if st is AudioStreamWAV:
				st.loop_mode = AudioStreamWAV.LOOP_FORWARD
				st.loop_end = int(st.get_length() * st.mix_rate)
			_hum.stream = st
			_hum.volume_db = -6.0
			_hum.max_distance = 260.0
			_hum.position = Vector2(0, -30)
			add_child(_hum)
			_hum.autoplay = not dead

	static func exists(rel: String) -> bool:
		return ResourceLoader.exists("res://assets/2x/" + rel) or ResourceLoader.exists("res://assets/" + rel) \
			or FileAccess.file_exists("res://assets/2x/" + rel) or FileAccess.file_exists("res://assets/" + rel)

	func silence() -> void:
		dead = true
		if _hum != null:
			_hum.stop()

	func charge() -> void:
		_glow = 1.0

	func _process(delta: float) -> void:
		_t += delta
		_glow = maxf(0.0, _glow - delta * 0.4)
		queue_redraw()

	func _draw() -> void:
		var live := 0.0 if dead else 1.0
		if not _frames.is_empty():
			var tex: Texture2D = _frames[int(_t * 8.0 * live) % _frames.size()]
			var s := tex.get_size()
			draw_texture(tex, Vector2(-s.x / 2.0, -s.y), Color(0.5, 0.5, 0.55) if dead else Color.WHITE)
			return
		# placeholder: a bank of brass pipes, a keyboard, a glowing core
		var w := 76.0
		draw_rect(Rect2(-w / 2.0, -12, w, 12), Color(0.16, 0.1, 0.07))
		draw_rect(Rect2(-w / 2.0 + 4, -22, w - 8, 10), Color(0.22, 0.14, 0.09))
		for i in 11:
			var h := 40.0 + 34.0 * absf(sin(float(i) * 0.9 + 0.5))
			var x := -w / 2.0 + 4.0 + i * 6.4
			var tone := Color(0.78, 0.6, 0.28) if not dead else Color(0.35, 0.3, 0.22)
			draw_rect(Rect2(x, -22.0 - h, 5, h), tone.darkened(0.45))
			draw_rect(Rect2(x, -22.0 - h, 2, h), tone)
			draw_rect(Rect2(x + 1, -22.0 - h - 2, 3, 2), tone.lightened(0.2))
		for k in 14:
			draw_rect(Rect2(-w / 2.0 + 6 + k * 4.6, -13, 3, 6), Color(0.85, 0.82, 0.7) if k % 3 != 2 else Color(0.1, 0.08, 0.08))
		var pulse := (0.5 + 0.5 * sin(_t * 3.0)) * live
		draw_circle(Vector2(0, -52), 9.0 + pulse * 2.0 + _glow * 6.0, Color(0.75, 0.4, 1.0, (0.12 + 0.12 * pulse) * (1.0 + _glow)))
		draw_circle(Vector2(0, -52), 3.0, Color(0.9, 0.7, 1.0, 0.4 + 0.5 * pulse))


# The scythe the Pallbearer drops: it floats at the spot where the body fell. Touch it.
class Scythe extends Node2D:
	var _t := 0.0
	var _base := Vector2.ZERO
	var _target_y := 0.0

	func setup(at: Vector2, rest_y: float) -> void:
		# it starts at "at" (where the body was) and falls to rest_y, then floats there
		position = at
		_base = at
		_target_y = rest_y
		z_index = 6

	func _process(delta: float) -> void:
		_t += delta
		_base.y = move_toward(_base.y, _target_y, 150.0 * delta)
		position = Vector2(_base.x, _base.y + sin(_t * 2.6) * 3.0)
		queue_redraw()

	func _draw() -> void:
		var tex := G.tex("weapon/elegy.png")
		draw_circle(Vector2.ZERO, 16.0 + sin(_t * 5.0) * 2.0, Color(0.5, 0.9, 1.0, 0.16))
		draw_circle(Vector2.ZERO, 9.0, Color(0.7, 1.0, 1.0, 0.12))
		draw_set_transform(Vector2.ZERO, -0.5, Vector2(0.8, 0.8))
		draw_texture(tex, -tex.get_size() / 2.0, Color(0.85, 1.0, 1.0))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
