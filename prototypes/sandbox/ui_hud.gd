# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# THE HUD — drawn on a CanvasLayer so a camera never drags the interface around.
# The band, the room's name, the log, the stamp and the control legend.
extends Node2D

var scene = null      # the fight node


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if scene == null:
		return
	draw_rect(Rect2(0, 470, 960, 70), Color(K.C_BG.r, K.C_BG.g, K.C_BG.b, 0.88))
	draw_rect(Rect2(0, 470, 960, 1), Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.22))

	_text(scene.hud_title, 40, 26, 15, K.C_BONE)
	_text(scene.hud_sub, 40, 41, 10, K.C_BONE_DIM)

	var y := 96.0
	for l in scene.log_lines:
		var a: float = clampf(l["t"] / 800.0, 0.0, 1.0)
		var c := K.C_BONE
		c.a = a
		_text(l["text"], 40, y, 11, c)
		y += 16.0

	if scene.stamp_ms > 0.0:
		var a2: float = clampf(scene.stamp_ms / 400.0, 0.0, 1.0)
		var c2 := K.C_AMBER
		c2.a = a2
		_center(scene.stamp, 300, 22, c2)

	if scene.debug:
		_text("FALLS %d   SAFE %s" % [scene.fall_count, str(scene.last_safe.round())],
			40, 116, 10, K.C_CYAN)

	if not scene.dead:
		var lines: Array = scene._controls()
		for i in lines.size():
			var s := String(lines[i])
			if s == "":
				continue
			_center(s, 496.0 + i * 15.0, 10 if i > 0 else 11, K.C_BONE if i == 0 else K.C_BONE_DIM)


func _text(txt: String, x: float, y: float, sz: int, c: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(x, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, c)


func _center(txt: String, y: float, sz: int, c: Color) -> void:
	var w := ThemeDB.fallback_font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	_text(txt, 480.0 - w * 0.5, y, sz, c)
