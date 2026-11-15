# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# THE MIRROR — her only honest organ. A diamond of ice holding a flipped, drained
# reflection of Pandora, ringed by a timer that is visible from the moment it is
# cast. Break it inside the ring and everything she has stored comes due at once.
# Let the ring close and the store is gone.
extends Node2D

const Assets = preload("res://assets.gd")

const W := 72.0
const H := 96.0

var hp := float(K.MIRROR_HP)
var hp_max := float(K.MIRROR_HP)
var timer_ms := float(K.MIRROR_TIMER_MS)
var alive := true
var broke := false
var expired := false
var flash_ms := 0.0
var spawn_ms := 0.0
var t := 0.0

var tex: Texture2D


func _ready() -> void:
	z_index = 12
	tex = Assets.tex("res://assets/arnetria/mirror.png")


func tick(delta: float) -> void:
	if not alive:
		return
	var ms := delta * 1000.0
	t += delta
	spawn_ms = minf(spawn_ms + ms, 220.0)
	if flash_ms > 0.0:
		flash_ms = maxf(0.0, flash_ms - ms)
	timer_ms -= ms
	if timer_ms <= 0.0:
		timer_ms = 0.0
		alive = false
		expired = true


func ratio() -> float:
	return clampf(timer_ms / float(K.MIRROR_TIMER_MS), 0.0, 1.0)


func hurtbox() -> Rect2:
	return Rect2(position.x - W * 0.42, position.y - H, W * 0.84, H)


func hit(dmg: int) -> void:
	if not alive:
		return
	hp = maxf(0.0, hp - float(dmg))
	flash_ms = 90.0
	if hp <= 0.0:
		alive = false
		broke = true


func _draw() -> void:
	if not alive and not broke:
		return
	var k: float = clampf(spawn_ms / 220.0, 0.2, 1.0)
	var bob: float = sin(t * 2.2) * 4.0
	var r := Rect2(-W * 0.5 * k, -H * k + bob, W * k, H * k)

	# the shard's cold breath
	draw_set_transform(Vector2(0, -H * 0.5 + bob), 0.0, Vector2(1, 1))
	draw_circle(Vector2.ZERO, 46.0 * k, Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, 0.07))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if tex:
		var m := Color(1, 1, 1, 1)
		if flash_ms > 0.0:
			m = Color(2.0, 2.0, 2.0, 1)
		draw_texture_rect(tex, r, false, m)

	# the timer ring: an arc that closes clockwise, ice on dark
	var c := Vector2(0, -H * 0.5 + bob)
	var rad := 44.0 * k
	draw_arc(c, rad, 0.0, TAU, 40, Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, 0.16), 2.0)
	var rt := ratio()
	var col := K.C_ICE
	if rt < 0.28:
		var pulse: float = 0.5 + 0.5 * sin(t * TAU * 3.0)
		col = Color(1, 1, 1, 0.6 + 0.4 * pulse)
	draw_arc(c, rad, -PI * 0.5, -PI * 0.5 + TAU * rt, 40, col, 3.0)
	# the closing pips: four marks, one per second of the window
	for i in 4:
		var ang: float = -PI * 0.5 + TAU * (float(i) / 4.0)
		draw_line(c + Vector2(cos(ang), sin(ang)) * (rad - 5.0),
			c + Vector2(cos(ang), sin(ang)) * (rad + 5.0),
			Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, 0.5), 1.0)

	# its own health: pips, so the break is a count, not a guess
	for i in int(hp_max):
		var x := -10.0 + i * 12.0
		var on: bool = i < int(hp)
		draw_rect(Rect2(x, -H + bob - 8.0, 8, 3),
			K.C_ICE if on else Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, 0.22))
