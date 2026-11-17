# PROTOTYPE - NOT FOR PRODUCTION
# Pandora's move effects: glowing afterimages, sparks, speed streaks, shock rings,
# a rune circle, energy gathering into her hand and a short screen flash.
# Everything is drawn with "add" blending, so it reads as light, in her colours
# (the cyan of her suit lines, silver, violet). One Vfx node holds one burst and
# frees itself when it is empty. Pauses during the hit pause like the rest.
# F1: "Effects amount" scales how many particles; "Screen flash" can be set to 0.
class_name Vfx
extends Node2D

const CYAN := Color(0.3, 1.0, 0.95)
const ICE := Color(0.82, 0.96, 1.0)
const VIOLET := Color(0.72, 0.42, 1.0)
const EMBER := Color(1.0, 0.72, 0.32)

# particle: {p, v, life, max, col, size, streak, drag, grav, shrink}
var parts: Array = []
# ring: {r0, r1, life, max, col, flat, w}
var rings: Array = []
# rune circle (Requiem): radius, life, max, col, spin
var rune := {}
var _t := 0.0


func _init() -> void:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	z_index = 6


static func _amount() -> float:
	return T.v("fx_amount")


static func _spawn(at: Vector2) -> Vfx:
	var v := Vfx.new()
	v.global_position = at
	if G.main != null and G.main.world != null:
		G.main.world.add_child(v)
	return v


func _process(delta: float) -> void:
	if G.frozen():
		queue_redraw()
		return
	_t += delta
	for p in parts:
		p["life"] -= delta
		p["v"] = p["v"] * maxf(0.0, 1.0 - p["drag"] * delta) + Vector2(0, p["grav"] * delta)
		p["p"] += p["v"] * delta
	parts = parts.filter(func(p): return p["life"] > 0.0)
	for r in rings:
		r["life"] -= delta
	rings = rings.filter(func(r): return r["life"] > 0.0)
	if not rune.is_empty():
		rune["life"] -= delta
		if rune["life"] <= 0.0:
			rune = {}
	queue_redraw()
	if parts.is_empty() and rings.is_empty() and rune.is_empty():
		queue_free()


func _draw() -> void:
	for p in parts:
		var k: float = clampf(p["life"] / p["max"], 0.0, 1.0)
		var c: Color = p["col"]
		c.a = k
		var s: float = maxf(1.0, round(p["size"] * (k if p["shrink"] else 1.0)))
		var halo := c
		halo.a = k * 0.28
		if p["streak"] > 0.0:
			var tail: Vector2 = p["v"].normalized() * p["streak"] * (0.4 + 0.6 * k)
			draw_line(p["p"].round(), (p["p"] - tail).round(), halo, 3.0)
			draw_line(p["p"].round(), (p["p"] - tail).round(), c, 1.0)
		else:
			var hs := s + 2.0
			draw_rect(Rect2(p["p"].round() - Vector2(hs, hs) * 0.5, Vector2(hs, hs)), halo)
			draw_rect(Rect2(p["p"].round() - Vector2(s, s) * 0.5, Vector2(s, s)), c)
	for r in rings:
		var k: float = 1.0 - r["life"] / r["max"]
		var e := 1.0 - pow(1.0 - k, 3.0)       # fast out, slow end
		var rad: float = lerpf(r["r0"], r["r1"], e)
		var c: Color = r["col"]
		c.a = 1.0 - k
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, r["flat"]))
		draw_arc(Vector2.ZERO, rad, 0.0, TAU, 40, c, r["w"] * (1.0 - 0.5 * k))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not rune.is_empty():
		var k: float = rune["life"] / rune["max"]
		var fade := clampf(minf(k * 5.0, (1.0 - k) * 8.0), 0.0, 1.0)
		var c: Color = rune["col"]
		c.a = 0.85 * fade
		var R: float = rune["r"]
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
		var glow := c
		glow.a *= 0.3
		draw_arc(Vector2.ZERO, R, 0.0, TAU, 48, glow, 4.0)
		draw_arc(Vector2.ZERO, R, 0.0, TAU, 48, c, 1.5)
		var c2 := c
		c2.a *= 0.6
		draw_arc(Vector2.ZERO, R * 0.72, 0.0, TAU, 40, c2, 1.0)
		# turning marks between the two circles, like a seal being cut
		var spin: float = _t * rune["spin"]
		for i in 12:
			var a := spin + TAU * i / 12.0
			var d := Vector2(cos(a), sin(a))
			draw_line(d * R * 0.74, d * R * 0.98, c if i % 3 == 0 else c2, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------- building blocks ----------

## Sparks or dust from `at`: `angle` (radians, 0 = right) +- `spread`.
static func burst(at: Vector2, count: int, col: Color, angle: float, spread: float,
		speed: Vector2, life: float, grav: float = 0.0, size: float = 1.0,
		streak: float = 0.0, drag: float = 2.0) -> Vfx:
	var v := _spawn(at)
	var n := maxi(1, int(round(count * _amount())))
	for i in n:
		var a := angle + randf_range(-spread, spread)
		var sp := randf_range(speed.x, speed.y)
		var l := life * randf_range(0.6, 1.0)
		var c := col.lerp(ICE, randf() * 0.35)
		v.parts.append({"p": Vector2(randf_range(-1, 1), randf_range(-1, 1)), "v": Vector2(cos(a), sin(a)) * sp,
			"life": l, "max": l, "col": c, "size": size, "streak": streak, "drag": drag, "grav": grav, "shrink": true})
	return v


## An expanding ring; flat < 1 squashes it onto the floor.
static func ring(at: Vector2, r0: float, r1: float, life: float, col: Color, flat: float = 1.0, w: float = 2.0) -> Vfx:
	var v := _spawn(at)
	v.rings.append({"r0": r0, "r1": r1, "life": life, "max": life, "col": col, "flat": flat, "w": w})
	return v


## Light drawn in toward `at` from a circle round it, arriving after `life` seconds.
static func gather(at: Vector2, radius: float, count: int, col: Color, life: float) -> Vfx:
	var v := _spawn(at)
	var n := maxi(1, int(round(count * _amount())))
	for i in n:
		var a := randf() * TAU
		var p := Vector2(cos(a), sin(a)) * radius * randf_range(0.7, 1.0)
		var l := life * randf_range(0.7, 1.0)
		v.parts.append({"p": p, "v": -p / l, "life": l, "max": l, "col": col, "size": 1.0,
			"streak": 3.0, "drag": 0.0, "grav": 0.0, "shrink": false})
	return v


## Horizontal speed lines around a body moving in `dir` (-1 / 1).
static func streaks(at: Vector2, dir: int, count: int, col: Color, height: float = 30.0) -> Vfx:
	var v := _spawn(at)
	var n := maxi(1, int(round(count * _amount())))
	for i in n:
		var l := randf_range(0.12, 0.22)
		v.parts.append({"p": Vector2(randf_range(-8, 8), -randf_range(2, height)), "v": Vector2(-dir * randf_range(60, 120), 0),
			"life": l, "max": l, "col": col, "size": 1.0, "streak": randf_range(6, 14), "drag": 3.0, "grav": 0.0, "shrink": false})
	return v


## The seal under the Requiem.
static func rune_circle(at: Vector2, radius: float, life: float, col: Color, spin: float) -> Vfx:
	var v := _spawn(at)
	v.rune = {"r": radius, "life": life, "max": life, "col": col, "spin": spin}
	return v


static var _sil: Shader

static func _silhouette() -> Shader:
	if _sil == null:
		_sil = Shader.new()
		_sil.code = """shader_type canvas_item;
render_mode blend_add;
void fragment() {
	float a = texture(TEXTURE, UV).a;
	COLOR = vec4(COLOR.rgb * 1.8, a * COLOR.a);
}"""
	return _sil


## A glowing silhouette of her current picture that fades where it was left.
static func ghost(spr: AnimatedSprite2D, col: Color, life: float) -> void:
	if G.main == null or G.main.world == null:
		return
	var g := Sprite2D.new()
	g.texture = spr.sprite_frames.get_frame_texture(spr.animation, spr.frame)
	g.centered = false
	g.flip_h = spr.flip_h
	g.global_position = spr.global_position
	var m := ShaderMaterial.new()
	m.shader = _silhouette()
	g.material = m
	g.modulate = Color(col.r, col.g, col.b, col.a * 0.75)
	G.main.world.add_child(g)
	# on her layer, just behind her (z -1 hid it under the room picture)
	var body := spr.get_parent()
	if body != null and body.get_parent() == G.main.world:
		G.main.world.move_child(g, body.get_index())
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, life).set_ease(Tween.EASE_OUT)
	tw.tween_callback(g.queue_free)


## Lights her up for a moment (a bright tint that settles back).
static func charge(spr: CanvasItem, col: Color, life: float) -> void:
	spr.modulate = Color(1.0 + col.r, 1.0 + col.g, 1.0 + col.b)
	var tw := spr.create_tween()
	tw.tween_property(spr, "modulate", Color.WHITE, life)


## A full-screen flash (F1 "Screen flash" scales it; 0 turns flashes off).
static func flash(col: Color, alpha: float, life: float) -> void:
	var k := T.v("fx_flash")
	if k <= 0.0 or G.main == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = 50
	var r := ColorRect.new()
	r.color = Color(col.r, col.g, col.b, alpha * k)
	r.size = Vector2(384, 216)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	r.material = m
	layer.add_child(r)
	G.main.add_child(layer)
	var tw := r.create_tween()
	tw.tween_property(r, "color:a", 0.0, life)
	tw.tween_callback(layer.queue_free)


# ---------- the moves ----------

## Backdash start: she lights up, the ground cracks with light behind her push.
static func backdash_start(feet: Vector2, dash_dir: int, spr: AnimatedSprite2D) -> void:
	charge(spr, CYAN * 0.9, 0.14)
	ring(feet + Vector2(-dash_dir * 2.0, 0), 2.0, 22.0, 0.3, CYAN, 0.22, 2.0)
	burst(feet + Vector2(-dash_dir * 3.0, -1), 10, CYAN, PI if dash_dir > 0 else 0.0, 0.5, Vector2(70, 160), 0.3, 120.0, 1.0, 4.0)
	burst(feet + Vector2(0, -1), 6, ICE, -PI / 2.0, 1.2, Vector2(20, 50), 0.35, 60.0, 2.0)
	streaks(feet, dash_dir, 10, ICE, 40.0)
	floor_trail(feet, dash_dir, CYAN)
	ghost(spr, Color(ICE.r, ICE.g, ICE.b, 1.0), 0.35)


## A line of light left on the floor behind a fast move.
static func floor_trail(feet: Vector2, dir: int, col: Color) -> void:
	var v := _spawn(feet + Vector2(0, -1))
	var n := maxi(1, int(round(10 * _amount())))
	for i in n:
		var l := randf_range(0.25, 0.4)
		v.parts.append({"p": Vector2(-dir * randf_range(0, 18), randf_range(-1, 0)), "v": Vector2(dir * randf_range(20, 70), 0),
			"life": l, "max": l, "col": col.lerp(ICE, randf() * 0.4), "size": 1.0, "streak": randf_range(10, 22), "drag": 4.0, "grav": 0.0, "shrink": false})


## Backdash end: her heels skid and spit sparks.
static func backdash_end(feet: Vector2, dash_dir: int) -> void:
	burst(feet + Vector2(dash_dir * 3.0, -1), 8, EMBER, -PI / 2.0 + dash_dir * 1.1, 0.35, Vector2(60, 120), 0.28, 300.0, 1.0, 3.0)
	ring(feet, 2.0, 12.0, 0.2, VIOLET, 0.25, 1.0)


## Slide start: a line of light along the floor.
static func slide_start(feet: Vector2, dir: int, spr: AnimatedSprite2D) -> void:
	charge(spr, ICE * 0.7, 0.12)
	ring(feet, 4.0, 30.0, 0.28, CYAN, 0.1, 2.0)
	burst(feet + Vector2(-dir * 4.0, -1), 12, ICE, -PI / 2.0 - dir * 0.9, 0.5, Vector2(40, 110), 0.35, 160.0, 2.0)
	floor_trail(feet, dir, CYAN)
	ghost(spr, Color(ICE.r, ICE.g, ICE.b, 1.0), 0.3)


## Every few frames while she slides: sparks off the heel, dust, streaks.
static func slide_tick(feet: Vector2, dir: int) -> void:
	burst(feet + Vector2(dir * 10.0, -1), 5, EMBER, -PI / 2.0 - dir * 1.25, 0.3, Vector2(70, 140), 0.25, 380.0, 1.0, 3.0)
	burst(feet + Vector2(-dir * 6.0, -2), 2, Color(0.55, 0.6, 0.75), -PI / 2.0 - dir * 0.6, 0.6, Vector2(10, 30), 0.4, -10.0, 2.0)
	streaks(feet, dir, 3, CYAN, 16.0)
	floor_trail(feet, -dir, CYAN)


## Dirge special wind-up: light gathers into her hand.
static func cast_gather(hand: Vector2, life: float) -> void:
	gather(hand, 30.0, 28, CYAN, life)
	gather(hand, 18.0, 12, VIOLET, life * 0.8)
	ring(hand, 30.0, 3.0, life, CYAN, 1.0, 2.0)
	ring(hand, 18.0, 2.0, life * 0.7, VIOLET, 1.0, 1.0)


## Dirge special release: burst, ring, flash.
static func cast_release(hand: Vector2, dir: int) -> void:
	ring(hand, 2.0, 26.0, 0.32, CYAN, 1.0, 2.0)
	ring(hand, 2.0, 14.0, 0.22, ICE, 1.0, 1.0)
	burst(hand, 16, CYAN, 0.0 if dir > 0 else PI, 0.7, Vector2(80, 200), 0.35, 0.0, 1.0, 5.0, 4.0)
	flash(CYAN, 0.22, 0.14)
	if G.main != null:
		G.main.shake(1.5, 0.12)


## The flying wave sheds light.
static func wave_trail(at: Vector2, dir: int) -> void:
	burst(at + Vector2(-dir * 4.0, randf_range(-10, 10)), 2, CYAN, PI if dir > 0 else 0.0, 0.3, Vector2(30, 70), 0.3, 0.0, 1.0, 3.0)


## Requiem start: the seal opens under her, light gathers.
static func requiem_start(feet: Vector2, life: float, spr: AnimatedSprite2D) -> void:
	charge(spr, VIOLET * 0.8, 0.2)
	rune_circle(feet, 30.0, life, VIOLET, 2.4)
	ring(feet, 4.0, 34.0, 0.4, CYAN, 0.32, 2.0)
	gather(feet + Vector2(0, -24), 30.0, 14, VIOLET, 0.25)


## Requiem, every few frames: sparks thrown off the scythe tip.
## `a` = the direction the tip is travelling (radians, world space).
static func requiem_tick(tip: Vector2, a: float) -> void:
	burst(tip, 3, CYAN, a, 0.4, Vector2(40, 110), 0.3, 40.0, 1.0, 4.0)
	burst(tip, 1, VIOLET, a + PI, 0.6, Vector2(10, 30), 0.4, 0.0, 2.0)


## Requiem end: the last turn bursts out.
static func requiem_end(feet: Vector2) -> void:
	ring(feet + Vector2(0, -24), 6.0, 46.0, 0.4, VIOLET, 1.0, 2.0)
	ring(feet + Vector2(0, -24), 4.0, 32.0, 0.3, CYAN, 1.0, 1.0)
	burst(feet + Vector2(0, -24), 22, CYAN, 0.0, PI, Vector2(60, 170), 0.45, 60.0, 1.0, 4.0, 3.0)
	flash(VIOLET, 0.2, 0.18)
	if G.main != null:
		G.main.shake(2.5, 0.18)
