# PROTOTYPE - NOT FOR PRODUCTION
extends RefCounted
## The weapon as its own layer, drawn from per-frame keys (frames.json hero.weapon.<anim>):
## for every body frame, where her hand is, the blade (angle, or yaw for a level swing),
## whether it is in front, and whether the swing into it leaves a swoosh.
## Her frames carry no weapon, so any weapon can be held in the same swing
## (user, 2026-11-19: "the character is consistent, the weapon may change").

const SHADER := preload("res://weapon_fx.gdshader")


## The keys for one animation, or [] when the hero set has none (or a frame count that differs).
static func keys_for(anim: String, frame_count: int) -> Array:
	var all: Dictionary = G.frames["hero"].get("weapon", {})
	var k: Array = all.get(anim, [])
	return k if k.size() == frame_count else []


## Her hand for a key, in the player's own space (feet at 0,0), mirrored when she faces left.
static func hand(key: Dictionary, facing: int) -> Vector2:
	var feet: Array = G.frames["hero"]["feet"]
	var density: float = float(G.frames["hero"].get("density", 1))
	return Vector2((key["hand"][0] / density - feet[0]) * facing, key["hand"][1] / density - feet[1])


const FLAT := 0.28    # a level swing seen from the side is an ellipse this flat (tools/attack_rig.py FLAT)


## The blade on screen for a key, before mirroring: a vector of length <= 1 (1 = full length,
## side-on). A level swing gives yaw (0 forward, 90 toward the camera, 180 back, -90 away) and
## tilt (+ = front end down); other keys give the screen angle and a length.
static func vec(key: Dictionary) -> Vector2:
	if key.has("yaw"):
		var y := deg_to_rad(float(key["yaw"]))
		return Vector2(cos(y), FLAT * sin(y)).rotated(deg_to_rad(float(key.get("tilt", 0.0))))
	return Vector2.RIGHT.rotated(deg_to_rad(float(key["angle"]))) * float(key.get("len", 1.0))


## The blade between key a and key b (u 0..1): a level swing turns its yaw the short way round,
## anything else turns its screen angle the short way and changes length on the way.
static func vec_at(a: Dictionary, b: Dictionary, u: float) -> Vector2:
	if a.has("yaw") and b.has("yaw"):
		var dy := wrapf(float(b["yaw"]) - float(a["yaw"]), -180.0, 180.0)
		var ta := float(a.get("tilt", 0.0))
		return vec({"yaw": float(a["yaw"]) + dy * u, "tilt": ta + (float(b.get("tilt", 0.0)) - ta) * u})
	var va := vec(a)
	var vb := vec(b)
	var ang := va.angle() + wrapf(vb.angle() - va.angle(), -PI, PI) * u
	return Vector2.RIGHT.rotated(ang) * lerpf(va.length(), vb.length(), u)


## How far the blade turned from key a to key b, in degrees.
static func turn(a: Dictionary, b: Dictionary) -> float:
	if a.has("yaw") and b.has("yaw"):
		return absf(wrapf(float(b["yaw"]) - float(a["yaw"]), -180.0, 180.0))
	return absf(rad_to_deg(wrapf(vec(b).angle() - vec(a).angle(), -PI, PI)))


static func mirror(v: Vector2, facing: int) -> Vector2:
	return Vector2(v.x * facing, v.y)


## Points along the blade (player space): from key a to key b with the hand and blade in
## between, or just key b's blade when a is empty. The cut is exactly what you see.
static func cut_points(a: Dictionary, b: Dictionary, facing: int, reach: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var hb := hand(b, facing)
	var steps := 1 if a.is_empty() else maxi(1, int(ceil(turn(a, b) / 7.0)))
	for i in steps + 1:
		var u := float(i) / steps
		var h := hb if a.is_empty() else hand(a, facing).lerp(hb, u)
		var v := mirror(vec(b) if a.is_empty() else vec_at(a, b, u), facing) * reach
		var n := maxi(1, int(v.length() / 4.0))
		for j in n + 1:
			pts.append(h + v * (float(j) / n))
	return pts


## The texture for a weapon in her current skin: the glowing version when it exists, with its grip.
static func texture(w: Dictionary) -> Array:
	var base: String = String(w["tex"]).get_basename()
	var name := base + ("_glow_b.png" if T.v("pandora_skin") >= 0.5 else "_glow.png")
	if ResourceLoader.exists("res://assets/2x/" + name) or FileAccess.file_exists("res://assets/2x/" + name):
		return [G.tex(name), w["grip"] + Vector2(0.5, 0.5)]
	return [G.tex(w["tex"]), w["grip"]]


static func material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	return m


static func set_phase(spr: Sprite2D, mode: int, t: float) -> void:
	var m := spr.material as ShaderMaterial
	if m == null or spr.texture == null:
		return
	m.set_shader_parameter("mode", mode)
	m.set_shader_parameter("t", t)
	m.set_shader_parameter("glow", Vfx.her().lerp(Color.WHITE, 0.6))
	var tex := spr.texture
	var size := tex.get_size()
	var inner = tex.get("inner")          # the double-detail picture behind a G.HalfTexture
	if inner is Texture2D:
		size = (inner as Texture2D).get_size()
	m.set_shader_parameter("px", size)


## After the swing the weapon stays where it was and breaks into rising sparks.
static func vanish(blade: Sprite2D, world: Node, from_t: float, life: float) -> void:
	if world == null or blade.texture == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = blade.texture
	ghost.centered = false
	ghost.offset = blade.offset
	ghost.material = material()
	ghost.z_index = 2
	world.add_child(ghost)
	ghost.global_transform = blade.global_transform
	set_phase(ghost, 2, from_t)
	var tw := ghost.create_tween()
	tw.tween_method(func(v: float) -> void: set_phase(ghost, 2, v), from_t, 1.0, life)
	tw.tween_callback(ghost.queue_free)
	# sparks drift up from along the blade
	var blade_len := blade.texture.get_width() * absf(blade.global_scale.x)
	var d := Vector2.RIGHT.rotated(blade.global_rotation) * signf(blade.global_scale.x)
	var at := blade.global_position
	var x := 4.0
	while x < blade_len:
		Vfx.burst(at + d * x, 1, Vfx.her(), -PI / 2.0, 0.6, Vector2(10.0, 26.0), life * 1.6, -12.0, 1.0)
		x += 7.0


## The band the outer blade swept through from key a to key b (player space): [outer, inner].
## Thick at the new end, thin at the old.
static func band(a: Dictionary, b: Dictionary, facing: int, reach: float) -> Array:
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 13:
		var u := float(i) / 12.0
		var h := hand(a, facing).lerp(hand(b, facing), u)
		var v := mirror(vec_at(a, b, u), facing) * reach
		var part := 0.08 + 0.42 * pow(u, 1.5)
		outer.append(h + v)
		inner.append(h + v * (1.0 - part))
	return [outer, inner]


## The streak a keyed swing leaves (see band); it fades over about one and a half frames.
class KeyTrail extends Node2D:
	var _outer := PackedVector2Array()
	var _inner := PackedVector2Array()
	var _life := 0.0
	var _max := 1.0

	func show_band(outer_inner: Array, life: float) -> void:
		_outer = outer_inner[0]
		_inner = outer_inner[1]
		_life = life
		_max = maxf(0.01, life)
		queue_redraw()

	func clear() -> void:
		_life = 0.0
		queue_redraw()

	func _process(delta: float) -> void:
		if _life > 0.0:
			_life -= delta
			queue_redraw()

	func _draw() -> void:
		if _life <= 0.0 or _outer.size() < 2:
			return
		var k := clampf(_life / _max, 0.0, 1.0)
		var skin_b := T.v("pandora_skin") >= 0.5
		var arc := Color(1.0, 0.3, 0.36) if skin_b else Color(0.45, 0.95, 1.0)
		var edge := Color(1.0, 0.82, 0.85) if skin_b else Color(0.9, 1.0, 1.0)
		var poly := PackedVector2Array(_outer)
		for i in range(_inner.size() - 1, -1, -1):
			poly.append(_inner[i])
		if Geometry2D.triangulate_polygon(poly).size() > 0:
			draw_colored_polygon(poly, Color(arc.r, arc.g, arc.b, 0.45 * k))
		draw_polyline(_outer.slice(3), Color(edge.r, edge.g, edge.b, 0.9 * k), 1.0)
