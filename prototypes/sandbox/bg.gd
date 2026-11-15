# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# THE BACKDROPS — real parallax art from the packs, drawn on a node far behind
# everything. Each room names its mode; the floor line is drawn here so the room
# reads as a place, not a void.
extends Node2D

const Assets = preload("res://assets.gd")

var mode := "training"
var floor_y := 420.0
var world_w := 960.0
var cam_x := 0.0
var floor_gaps: Array = []      # Array[Vector2] — the pits: floor is NOT drawn there
var seam_rect := Rect2()        # the cache's kill-zone, so it is visible before it kills
var t := 0.0
var _last_cam := -99999.0

var tex_a: Texture2D
var tex_b: Texture2D
var tex_c: Texture2D
var tex_ring: Texture2D


func _ready() -> void:
	z_index = -1000
	match mode:
		"training":
			tex_a = Assets.tex("res://assets/env/mvkit_background.png")
			tex_b = Assets.tex("res://assets/env/church_column.png")
		"approach":
			tex_a = Assets.tex("res://assets/env/rocky_back.png")
			tex_b = Assets.tex("res://assets/env/rocky_near.png")
			tex_c = Assets.tex("res://assets/env/church_column.png")
		"cache":
			tex_a = Assets.tex("res://assets/env/rocky_back.png")
			tex_b = Assets.tex("res://assets/env/grotto_back-panels.png")
		"arena":
			tex_a = Assets.tex("res://assets/env/mvkit_background.png")
			tex_ring = Assets.tex("res://assets/arnetria/ring.png")


func _process(delta: float) -> void:
	t += delta
	# Godot caches _draw() commands: anything that moves the backdrop must ask for
	# a redraw, or the parallax freezes at its first offset.
	if mode == "arena" or not is_equal_approx(cam_x, _last_cam):
		_last_cam = cam_x
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, world_w, 540), K.C_BG)

	match mode:
		"training":
			_parallax(tex_a, 2.35, 0.10, Color(0.55, 0.58, 0.62, 0.55))
			_columns(tex_b, 0.62, Color(0.5, 0.5, 0.55, 0.55), 2)
		"approach":
			_parallax(tex_a, 1.95, 0.10, Color(0.50, 0.52, 0.58, 0.65))
			_parallax(tex_b, 2.0, 0.30, Color(0.62, 0.62, 0.66, 0.75))
			_columns(tex_c, 0.72, Color(0.42, 0.42, 0.48, 0.55), 6)
		"cache":
			_parallax(tex_a, 1.95, 0.08, Color(0.42, 0.45, 0.50, 0.55))
			_parallax(tex_b, 2.6, 0.22, Color(0.40, 0.44, 0.50, 0.45))
			_seam()
		"arena":
			_parallax(tex_a, 2.4, 0.06, Color(0.40, 0.44, 0.52, 0.35))
			_ring()

	# the floor, in SOLID SPANS: a pit has no floor, so it must not be painted as
	# if it did. The gaps are the routes.
	for sp in _floor_spans():
		var x0: float = sp.x
		var x1: float = sp.y
		if x1 - x0 < 1.0:
			continue
		draw_rect(Rect2(x0, floor_y, x1 - x0, 540 - floor_y),
			Color(K.C_BG2.r, K.C_BG2.g, K.C_BG2.b, 0.9))
		draw_rect(Rect2(x0, floor_y, x1 - x0, 1), Color(K.C_BONE.r, K.C_BONE.g, K.C_BONE.b, 0.40))
		var tick := ceilf(x0 / 64.0) * 64.0
		while tick < x1:
			draw_rect(Rect2(tick, floor_y + 6, 1, 5),
				Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.20))
			tick += 64.0


func _floor_spans() -> Array:
	var spans: Array = []
	var x := 0.0
	for g in floor_gaps:
		spans.append(Vector2(x, float(g.x)))
		x = float(g.y)
	spans.append(Vector2(x, world_w))
	return spans


func _seam() -> void:
	if seam_rect.size == Vector2.ZERO:
		return
	# the kill-zone, drawn so it can be seen: a tear of void with cyan stitches
	draw_rect(seam_rect, Color(0.03, 0.03, 0.035, 0.94))
	draw_rect(Rect2(seam_rect.position.x - 1, seam_rect.position.y, 1, seam_rect.size.y),
		Color(K.C_CYAN.r, K.C_CYAN.g, K.C_CYAN.b, 0.30))
	draw_rect(Rect2(seam_rect.end.x, seam_rect.position.y, 1, seam_rect.size.y),
		Color(K.C_CYAN.r, K.C_CYAN.g, K.C_CYAN.b, 0.30))
	var n := int(seam_rect.size.y / 15.0)
	for i in n:
		var y := seam_rect.position.y + 6.0 + i * 15.0
		draw_rect(Rect2(seam_rect.position.x, y, 6, 1),
			Color(K.C_CYAN.r, K.C_CYAN.g, K.C_CYAN.b, 0.55))
		draw_rect(Rect2(seam_rect.end.x - 6, y + 7, 6, 1),
			Color(K.C_CYAN.r, K.C_CYAN.g, K.C_CYAN.b, 0.35))


func _parallax(tex: Texture2D, k: float, depth: float, col: Color) -> void:
	if tex == null:
		return
	var w: float = tex.get_width() * k
	var h: float = tex.get_height() * k
	var off: float = -cam_x * depth
	var x := fposmod(off, w) - w
	var y := floor_y - h + 8.0
	while x < world_w:
		draw_texture_rect(tex, Rect2(x, y, w, h), false, col)
		x += w


func _columns(tex: Texture2D, k: float, col: Color, n: int) -> void:
	if tex == null:
		return
	var w: float = tex.get_width() * k
	var h: float = tex.get_height() * k
	for i in n:
		var x: float = 90.0 + i * (world_w / float(n))
		draw_texture_rect(tex, Rect2(x, floor_y - h, w, h), false, col)


func _ring() -> void:
	if tex_ring == null:
		return
	# her broken clock, set into the arena: huge, dim, and breathing
	var k := 1.42
	var w: float = tex_ring.get_width() * k
	var h: float = tex_ring.get_height() * k
	var breath: float = 0.5 + 0.5 * sin(t * TAU * 0.22)
	var col := Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, 0.20 + 0.07 * breath)
	draw_texture_rect(tex_ring, Rect2(480.0 - w * 0.5, 300.0 - h * 0.5, w, h), false, col)
	# the crack: two hairlines across the dial, the whole point of the room
	draw_line(Vector2(300, 210), Vector2(392, 300), Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, 0.28), 2.0)
	draw_line(Vector2(392, 300), Vector2(360, 396), Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, 0.22), 1.5)
