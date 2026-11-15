# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# THE BOSS BAR — 20 segments over a 60 pool, pale bone, no red.
#
# v2's honesty: while she stores, the bar does not move and the STORED total is
# printed beside it, so the player can see exactly what is being withheld. When a
# mirror breaks, the bar does not step — it LURCHES (BAR_LURCH_MS, eased), because
# a 20-segment bar moving is the only sentence this fight needs.
extends Node2D

const SEG_W := 9.0
const SEG_H := 14.0
const GAP := 2.0

var hp := 60.0
var hp_max := 60.0
var shown := 60.0
var stored := 0.0
var floor_hp := 20.0
var label := "DENIAL"
var phase := "LIE_WHOLE"

var lurch_from := 60.0
var lurch_t := 0.0
var lurching := false
var pulse_t := 0.0


func set_values(new_hp: float, new_stored: float, new_floor: float, new_phase: String) -> void:
	if new_hp < hp - 0.001:
		lurch_from = shown
		lurch_t = 0.0
		lurching = true
	hp = new_hp
	stored = new_stored
	floor_hp = new_floor
	phase = new_phase


func _process(delta: float) -> void:
	pulse_t += delta
	if lurching:
		lurch_t += delta * 1000.0
		var k: float = clampf(lurch_t / float(K.BAR_LURCH_MS), 0.0, 1.0)
		var e: float = 1.0 - pow(1.0 - k, 3.0)      # ease-out: a fall, not a slide
		shown = lerpf(lurch_from, hp, e)
		if k >= 1.0:
			lurching = false
			shown = hp
	elif absf(shown - hp) > 0.01:
		shown = hp
	queue_redraw()


func _draw() -> void:
	var total := float(K.HP_SEGMENTS)
	var ratio: float = clampf(shown / hp_max, 0.0, 1.0)
	var lit := int(ceil(ratio * total - 0.0001))
	var width := total * (SEG_W + GAP)

	draw_rect(Rect2(-4, -4, width + 8, SEG_H + 8), Color(0, 0, 0, 0.6))
	for i in int(total):
		var x := float(i) * (SEG_W + GAP)
		var r := Rect2(x, 0, SEG_W, SEG_H)
		if i < lit:
			draw_rect(r, K.C_BONE)
		else:
			draw_rect(r, K.C_BG2)
			draw_rect(r, Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.18), false, 1.0)

	# the stored band: the damage she is withholding, drawn where it would land
	if stored > 0.5:
		var from: float = ratio * width
		var to: float = maxf(0.0, (shown - stored) / hp_max) * width
		var band := Rect2(to, 2.0, maxf(0.0, from - to), SEG_H - 4.0)
		var a: float = 0.35 + 0.25 * (0.5 + 0.5 * sin(pulse_t * TAU * 1.3))
		draw_rect(band, Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, a * 0.45))
		draw_rect(band, Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, 0.9), false, 1.0)
		draw_line(Vector2(from, -6), Vector2(from, SEG_H + 6), Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, 0.7), 1.0)

	# the floor tick (20/60). While the lie holds it is a bone rule; released, it dims.
	if floor_hp > 0.0:
		var fx: float = width * (floor_hp / hp_max)
		draw_rect(Rect2(fx - 1, -5, 2, SEG_H + 10), K.C_BONE)

	# the labels
	draw_string(ThemeDB.fallback_font, Vector2(0, -10),
		"%s   %d / %d" % [label, int(ceil(shown)), int(hp_max)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, K.C_BONE_DIM)
	if stored > 0.5:
		var s := "STORED  %d" % int(stored)
		var w := ThemeDB.fallback_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(ThemeDB.fallback_font, Vector2(width - w, -10), s,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, K.C_ICE)
