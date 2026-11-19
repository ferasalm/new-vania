# PROTOTYPE - NOT FOR PRODUCTION
# The projectiles system: her blade wave, everything an enemy throws, and the
# rings that burst around a point. Moved out of main.gd unchanged; her special
# now asks R for its damage so MAGIC grows it.
extends Node

var waves: Array = []        # blade waves in flight: {node, dir, left, hit}
var shots: Array = []        # enemy shots in flight (Shot nodes)


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
	G.main.world.add_child(s)
	waves.append({"node": s, "dir": dir, "left": T.v("special_range"), "hit": []})


func move_waves(delta: float) -> void:
	for w in waves.duplicate():
		var s: Sprite2D = w["node"]
		var step: float = T.v("special_speed") * delta
		s.global_position.x += w["dir"] * step
		Vfx.wave_trail(s.global_position, w["dir"])
		w["left"] -= step
		s.modulate.a = clampf(w["left"] / 30.0, 0.0, 1.0)
		var size: Vector2 = s.texture.get_size()
		G.main.player_swing(Rect2(s.global_position - size / 2.0, size), R.hit_damage(T.v("special_damage"), true), w["dir"], w["hit"])
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
	G.main.world.add_child(s)
	shots.append(s)


func move_shots(delta: float) -> void:
	var player: Node2D = G.main.player
	var body: Rect2 = player.body_rect()
	for s in shots.duplicate():
		if s.kind == "spit":
			s.vel.y += T.v("shot_gravity") * delta
		s.global_position += s.vel * delta
		s.life -= delta
		s.queue_redraw()
		var p: Vector2 = s.global_position
		var gone: bool = s.life <= 0.0 or p.x < -20.0 or p.x > G.main.room.size.x + 20.0
		if not gone and (s.kind == "spit" or s.kind == "feather"):
			if G.main.room.is_solid(int(p.x / 16.0), int(p.y / 16.0)):
				gone = true
				G.main.dust(p, 3)
		if not gone and not G.peace and s.box().intersects(body) and player.invuln <= 0.0:
			player.take_hit(s.dmg, p.x - signf(s.vel.x) * 4.0, "shot")
			gone = s.kind != "shock"
			if G.main._busy:
				return
		if gone:
			shots.erase(s)
			s.queue_free()


func ring(at: Vector2, radius: float, dmg: float) -> void:
	# a burst around a point (the ghost's shriek): hurts her if she is inside it
	ring_fx(at, radius, Color(0.8, 0.6, 1.0))
	G.main.shake(1.5, 0.12)
	var c: Vector2 = G.main.player.body_rect().get_center()
	if not G.peace and c.distance_to(at) < radius:
		G.main.player.take_hit(dmg, at.x)


func ring_fx(at: Vector2, radius: float, color: Color) -> void:
	var r := RingFx.new()
	r.color = color
	r.radius = radius
	r.global_position = at
	r.z_index = 5
	G.main.world.add_child(r)


func clear() -> void:
	# the room is being freed
	for w in waves:
		if is_instance_valid(w["node"]):
			w["node"].queue_free()
	waves.clear()
	for s in shots:
		if is_instance_valid(s):
			s.queue_free()
	shots.clear()


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
