# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# SCENE 2 — THE APPROACH. A room you can walk out of.
#
#   feedback #6: two pits, and neither of them can kill you. You fall, you fade,
#                you are put back on the last ground you stood on.
#   feedback #7: no locks. Both mini-bosses leash at 300 px. The only door that
#                seals is hers, and it is on the far side of this room.
#   feedback #8: the plain door on the left is furniture. The arch on the right is
#                not — tall, fluted, sigil-lit, breathing.
#   feedback #9: WARDEN — TIER 3 and THE CHOIR — TIER 2, each with a punish move.
extends "res://fight.gd"

const MINIBOSS := preload("res://miniboss.gd")
const BG := preload("res://bg.gd")

const FLOOR_Y := 440.0
const WORLD_W := 1920.0
const PITS := [[430.0, 500.0], [980.0, 1050.0]]

var bg_node
var cam: Camera2D


func _build() -> void:
	hud_title = "THE APPROACH"
	hud_sub = "no locks — every fight here can be walked out of"
	solids = []
	var x := 0.0
	for pit in PITS:
		solids.append(Rect2(x, FLOOR_Y, float(pit[0]) - x, 160))
		x = float(pit[1])
	solids.append(Rect2(x, FLOOR_Y, WORLD_W - x, 160))
	solids.append(Rect2(-20, 0, 20, 600))
	solids.append(Rect2(WORLD_W, 0, 20, 600))

	bg_node = BG.new()
	bg_node.mode = "approach"
	bg_node.floor_y = FLOOR_Y
	bg_node.world_w = WORLD_W
	for pit in PITS:
		bg_node.floor_gaps.append(Vector2(float(pit[0]), float(pit[1])))
	add_child(bg_node)

	# the plain door: quiet furniture, back to the menu
	var plain = DOOR.new()
	plain.kind = "plain"
	plain.target = "res://menu.tscn"
	plain.position = Vector2(80, FLOOR_Y)
	add_child(plain)
	doors.append(plain)

	# the boss door: the whole door language in one silhouette
	var boss_door = DOOR.new()
	boss_door.kind = "boss"
	boss_door.target = "res://arena.tscn"
	boss_door.position = Vector2(WORLD_W - 90.0, FLOOR_Y)
	add_child(boss_door)
	doors.append(boss_door)

	var w = MINIBOSS.new()
	w.setup("warden", Vector2(760, FLOOR_Y))
	add_child(w)
	w.watch(player)
	enemies.append(w)

	var c = MINIBOSS.new()
	c.setup("choir", Vector2(1380, FLOOR_Y))
	add_child(c)
	c.watch(player)
	enemies.append(c)

	cam = Camera2D.new()
	cam.limit_left = 0
	cam.limit_right = int(WORLD_W)
	cam.limit_top = 0
	cam.limit_bottom = 540
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	player.add_child(cam)
	cam.make_current()


func _physics_process(delta: float) -> void:
	super(delta)
	if bg_node and is_instance_valid(bg_node):
		bg_node.cam_x = player.position.x - 480.0


func _spawn() -> Vector2:
	return Vector2(150, FLOOR_Y)


func _controls() -> Array:
	return [
		"WASD  MOVE      SPACE  JUMP      SHIFT  DASH      J  THE BUTTON      ESC  MENU",
		"the pits are routes: fall and you are handed back to the last ground you stood on",
		"walk away from either fight and it leashes. only her arch locks — and only once you are inside",
	]
