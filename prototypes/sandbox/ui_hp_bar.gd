# PROTOTYPE - NOT FOR PRODUCTION
# The segmented HP bar. 20 segments, pale bone on dark, NO red fill; the loss is
# read by length. The low cue (<= 25%) is a slow pulse — never a flash.
# Values: consts.gd HP_SEGMENTS / LOW_HP_RATIO (health-damage.md TR-HD-036 area).
extends Node2D

const SEG_W := 9.0
const SEG_H := 14.0
const GAP := 2.0

var hp := 20.0
var hp_max := 20.0
var label := ""
var show_numbers := true
var pulse_t := 0.0


func _process(delta: float) -> void:
	pulse_t += delta
	queue_redraw()


func _draw() -> void:
	var total := float(K.HP_SEGMENTS)
	var ratio := 0.0 if hp_max <= 0.0 else clampf(hp / hp_max, 0.0, 1.0)
	var lit := int(ceil(ratio * total - 0.0001))
	var low := ratio <= K.LOW_HP_RATIO

	# the slow pulse: a 1.6 s sine on the filled segments' brightness (no flash)
	var bright := 1.0
	if low:
		bright = 0.62 + 0.38 * (0.5 + 0.5 * sin(pulse_t * TAU / 1.6))

	draw_rect(Rect2(-4, -4, total * (SEG_W + GAP) + 8, SEG_H + 8), Color(0, 0, 0, 0.55))
	for i in int(total):
		var x := float(i) * (SEG_W + GAP)
		var r := Rect2(x, 0, SEG_W, SEG_H)
		if i < lit:
			var c := K.C_BONE
			c.a = bright
			draw_rect(r, c)
		else:
			draw_rect(r, K.C_BG2)
			draw_rect(r, Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.18), false, 1.0)

	if show_numbers:
		var txt := "%d / %d" % [int(hp), int(hp_max)]
		draw_string(ThemeDB.fallback_font, Vector2(total * (SEG_W + GAP) + 10, SEG_H - 2),
			txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, K.C_BONE_DIM)
	if label != "":
		draw_string(ThemeDB.fallback_font, Vector2(0, -10), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, K.C_BONE_DIM)
