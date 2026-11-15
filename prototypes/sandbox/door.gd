# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# THE DOOR LANGUAGE (feedback #8). Two kinds, never confusable:
#   plain — small, dim, rectangular, silent. It is furniture.
#   boss  — a tall gothic arch, fluted columns, a cracked sigil, and a slow breath
#           of ice light. You can read it from across the room.
# A boss door SEALS behind you (the only lock in the suite).
extends Node2D

const Assets = preload("res://assets.gd")

signal entered

const PLAIN_TEX := "res://assets/env/fort_door.png"
const BOSS_TEX := "res://assets/env/boss_door.png"

var kind := "plain"          # plain | boss
var target := ""             # scene to change to
var sealed := false
var armed := true
var t := 0.0
var seal_ms := 0.0

var tex: Texture2D


func _ready() -> void:
	z_index = 2
	tex = Assets.tex(BOSS_TEX if kind == "boss" else PLAIN_TEX)


func _process(delta: float) -> void:
	t += delta
	if seal_ms > 0.0:
		seal_ms = maxf(0.0, seal_ms - delta * 1000.0)
	queue_redraw()


func size() -> Vector2:
	if kind == "boss":
		return Vector2(184, 268)
	return Vector2(96 * 0.78, 80 * 0.78)


func trigger_rect() -> Rect2:
	var s := size()
	return Rect2(position.x - s.x * 0.5, position.y - s.y, s.x, s.y)


func seal() -> void:
	sealed = true
	seal_ms = 900.0


func _draw() -> void:
	var s := size()
	var r := Rect2(-s.x * 0.5, -s.y, s.x, s.y)

	if kind == "boss":
		# the breath: three rings of ice light behind the arch
		var breath: float = 0.5 + 0.5 * sin(t * TAU * K.DOOR_PULSE_HZ)
		var c := K.C_ICE
		for i in 3:
			var grow := 6.0 + i * 9.0 + breath * 5.0
			var a: float = (0.16 - i * 0.04) * (0.6 + 0.4 * breath)
			draw_rect(r.grow(grow), Color(c.r, c.g, c.b, a), false, 2.0)
		# the rotating sigil
		var cx := 0.0
		var cy := -s.y + 62.0
		var rot := t * 0.6
		for i in 6:
			var ang := rot + i * TAU / 6.0
			draw_line(Vector2(cx, cy) + Vector2(cos(ang), sin(ang)) * 16.0,
				Vector2(cx, cy) + Vector2(cos(ang), sin(ang)) * 26.0,
				Color(c.r, c.g, c.b, 0.35 + 0.35 * breath), 1.5)
		# the floor pool of light
		draw_set_transform(Vector2(0, -2), 0.0, Vector2(1, 0.22))
		draw_circle(Vector2.ZERO, 58.0 + breath * 8.0, Color(c.r, c.g, c.b, 0.10 + 0.06 * breath))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		# plain: a quiet frame, no light at all
		draw_rect(r.grow(2.0), Color(0, 0, 0, 0.55))
		draw_rect(r.grow(2.0), Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.30), false, 1.0)

	if tex:
		var m := Color(1, 1, 1, 1) if kind == "boss" else Color(0.62, 0.60, 0.58, 0.85)
		draw_texture_rect(tex, r, false, m)

	if kind == "boss":
		# the seal: a hot bar across the leaves
		if sealed:
			var hot: float = 0.75 + 0.25 * sin(t * 12.0)
			draw_rect(Rect2(r.position.x + 6, r.position.y + s.y * 0.44, s.x - 12, 3),
				Color(1, 1, 1, hot))
			draw_rect(Rect2(r.position.x + 6, r.position.y + s.y * 0.44 - 3, s.x - 12, 9),
				Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, 0.18))
		if seal_ms > 0.0:
			var a2: float = clampf(seal_ms / 900.0, 0.0, 1.0)
			draw_rect(r.grow(10.0), Color(1, 1, 1, a2 * 0.5), false, 2.0)
