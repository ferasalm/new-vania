# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its landed numbers are played, not read?
# Date: 2026-11-16
# The static furniture, drawn on a node far behind the actors so each scene's own
# _draw can carry the HUD on top. Numbers mirror the scene's own constants.
extends Node2D

var mode := "duel"


func _draw() -> void:
	match mode:
		"duel":
			_floor(420.0)
			for i in 7:
				var x := 120.0 + i * 120.0
				draw_rect(Rect2(x, 426, 1, 5), Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.35))
		"cache":
			# the floor, split by the pit at 390..450
			draw_rect(Rect2(0, 420, 390, 120), K.C_BG2)
			draw_rect(Rect2(450, 420, 510, 120), K.C_BG2)
			draw_rect(Rect2(0, 420, 390, 1), Color(K.C_BONE.r, K.C_BONE.g, K.C_BONE.b, 0.45))
			draw_rect(Rect2(450, 420, 510, 1), Color(K.C_BONE.r, K.C_BONE.g, K.C_BONE.b, 0.45))
			draw_rect(Rect2(390, 420, 60, 120), K.C_VOID)
			draw_rect(Rect2(389, 420, 1, 40), K.C_BONE_DIM)
			draw_rect(Rect2(450, 420, 1, 40), K.C_BONE_DIM)
			# the seam (the kill-zone)
			draw_rect(Rect2(872, 240, 44, 180), Color(0.03, 0.03, 0.03, 0.9))
			for i in 12:
				var y := 246.0 + i * 15.0
				draw_rect(Rect2(872, y, 6, 1), Color(K.C_CYAN.r, K.C_CYAN.g, K.C_CYAN.b, 0.55))
				draw_rect(Rect2(910, y + 7, 6, 1), Color(K.C_CYAN.r, K.C_CYAN.g, K.C_CYAN.b, 0.35))
			# the terminal
			draw_rect(Rect2(618, 360, 44, 60), K.C_BG2)
			draw_rect(Rect2(618, 360, 44, 60), K.C_BONE, false, 1.0)
			draw_rect(Rect2(624, 368, 32, 14), K.C_BG)
			for i in 3:
				draw_rect(Rect2(624, 390 + i * 8, 32, 2),
					Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.7))
			draw_arc(Vector2(640, 350), 4.0, 0, TAU, 10,
				Color(K.C_CYAN.r, K.C_CYAN.g, K.C_CYAN.b, 0.5), 1.5)
		"denial":
			_floor(440.0)
			draw_rect(Rect2(686, 442, 26, 3), Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.35))
			draw_rect(Rect2(36, 120, 2, 320), Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.3))
			draw_rect(Rect2(922, 120, 2, 320), Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.3))


func _floor(y: float) -> void:
	draw_rect(Rect2(0, 0, 960, 540), K.C_BG)
	draw_rect(Rect2(0, y, 960, 540 - y), K.C_BG2)
	draw_rect(Rect2(0, y, 960, 1), Color(K.C_BONE.r, K.C_BONE.g, K.C_BONE.b, 0.45))
