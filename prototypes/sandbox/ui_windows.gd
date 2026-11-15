# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# THE WINDOWS — the one button's timing, drawn honestly.
#
# When an enemy commits, its own clock is drawn as one bar:
#   [ the telegraph ..................... ][ the swing ]
#     strike zone            counter zone   clash zone
# The playhead is where the enemy is right now. Press inside a zone and that is
# what the button becomes. With no threat, the bar is the legend.
extends Node2D

const W := 460.0
const H := 16.0

var threat: Dictionary = {}     # {phase, t, telegraph, active, name, counterable, clashable}
var outcome := ""
var outcome_ms := 0.0
var outcome_color := K.C_BONE
var t := 0.0


func set_threat(d: Dictionary) -> void:
	threat = d


func flash_outcome(kind: String, value: int = -1) -> void:
	outcome_color = K.C_CYAN if kind == "CLASH" else (K.C_ICE if kind == "COUNTER" else K.C_BONE)
	outcome = kind if value < 0 else "%s  %d" % [kind, value]
	outcome_ms = 900.0


func _process(delta: float) -> void:
	t += delta
	if outcome_ms > 0.0:
		outcome_ms = maxf(0.0, outcome_ms - delta * 1000.0)
	queue_redraw()


func _draw() -> void:
	var x0 := -W * 0.5
	var y0 := 0.0
	var has := not threat.is_empty()

	# the rail
	draw_rect(Rect2(x0 - 3, y0 - 3, W + 6, H + 6), Color(0, 0, 0, 0.62))

	if has:
		var tele := maxf(1.0, float(threat.get("telegraph", 350.0)))
		var act := maxf(1.0, float(threat.get("active", 100.0)))
		var total := tele + act
		var k := W / total
		var tc := float(threat.get("t", 0.0))
		var counterable := bool(threat.get("counterable", true))
		var clashable := bool(threat.get("clashable", true))
		var dist := float(threat.get("dist", 0.0))
		# the bar must not promise a window the press cannot take: out of reach the
		# zone is still shown, but dimmed to a rumour
		var near_c := 1.0 if dist <= K.COUNTER_REACH else 0.22
		var near_x := 1.0 if dist <= K.CLASH_REACH else 0.22

		# strike zone (the telegraph, before the flash)
		var strike_w: float = tele * k
		if counterable:
			strike_w = maxf(0.0, tele - K.COUNTER_WINDOW_MS) * k
		draw_rect(Rect2(x0, y0, strike_w, H), Color(K.C_BONE.r, K.C_BONE.g, K.C_BONE.b, 0.20))

		# counter zone (the flash tail) — only if the move can be countered
		var cx := x0 + strike_w
		if counterable:
			var cw: float = K.COUNTER_WINDOW_MS * k
			var pulse: float = 0.55 + 0.45 * (0.5 + 0.5 * sin(t * TAU * 2.2))
			draw_rect(Rect2(cx, y0, cw, H),
				Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, pulse * 0.55 * near_c))
			draw_rect(Rect2(cx, y0, cw, H),
				Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, near_c), false, 1.0)

		# clash zone (the swing)
		var clx := x0 + tele * k
		var clw: float = act * k
		if clashable:
			draw_rect(Rect2(clx, y0, clw, H),
				Color(K.C_CYAN.r, K.C_CYAN.g, K.C_CYAN.b, 0.45 * near_x))
		else:
			draw_rect(Rect2(clx, y0, clw, H), Color(K.C_BONE.r, K.C_BONE.g, K.C_BONE.b, 0.10))
			draw_line(Vector2(clx + 2, y0 + H), Vector2(clx + clw - 2, y0),
				Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.8), 1.0)

		# the playhead
		var px := x0 + clampf(tc, 0.0, total) * k
		draw_rect(Rect2(px - 1, y0 - 4, 2, H + 8), Color(1, 1, 1, 0.95))

		# the labels, under the zones
		_label("STRIKE", x0 + 4, y0 + H + 12, K.C_BONE_DIM)
		if counterable:
			_label("COUNTER", cx + 2, y0 + H + 12,
				Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, near_c))
		if clashable:
			_label("CLASH", clx + clw - 40, y0 + H + 12,
				Color(K.C_CYAN.r, K.C_CYAN.g, K.C_CYAN.b, near_x))
		var nm := String(threat.get("name", ""))
		if nm != "":
			_right(nm.to_upper(), x0 + W, y0 - 8, K.C_BONE_DIM)
	else:
		# the legend: the whole bar, one colour per zone, at rest
		draw_rect(Rect2(x0, y0, W * 0.62, H), Color(K.C_BONE.r, K.C_BONE.g, K.C_BONE.b, 0.14))
		draw_rect(Rect2(x0 + W * 0.62, y0, W * 0.20, H), Color(K.C_ICE.r, K.C_ICE.g, K.C_ICE.b, 0.30))
		draw_rect(Rect2(x0 + W * 0.82, y0, W * 0.18, H), Color(K.C_CYAN.r, K.C_CYAN.g, K.C_CYAN.b, 0.30))
		_label("STRIKE", x0 + 4, y0 + H + 12, K.C_BONE_DIM)
		_label("COUNTER", x0 + W * 0.62 + 2, y0 + H + 12, K.C_ICE)
		_label("CLASH", x0 + W * 0.84, y0 + H + 12, K.C_CYAN)

	if outcome_ms > 0.0:
		var a: float = clampf(outcome_ms / 300.0, 0.0, 1.0)
		var c := outcome_color
		c.a = a
		_center(outcome, y0 - 12, 16, c)


func _label(s: String, x: float, y: float, c: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(x, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, c)


func _right(s: String, x: float, y: float, c: Color) -> void:
	var w := ThemeDB.fallback_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	_label(s, x - w, y, c)


func _center(s: String, y: float, sz: int, c: Color) -> void:
	var w := ThemeDB.fallback_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(ThemeDB.fallback_font, Vector2(-w * 0.5, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, c)
