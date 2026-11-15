# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# SCENE 1 — THE ONE BUTTON. The ladder, taught by three tiers that swing at you:
# HUSK (6) / SPITTER (12) / WARDEN (24). No locks: walk away whenever.
extends "res://fight.gd"

const MINIBOSS := preload("res://miniboss.gd")
const BG := preload("res://bg.gd")

const FLOOR_Y := 420.0


func _build() -> void:
	hud_title = "THE ONE BUTTON"
	hud_sub = "tap = strike   ·   on the flash = counter   ·   into the swing = clash"
	solids = [
		Rect2(0, FLOOR_Y, 960, 120),
		Rect2(-20, 0, 20, 540),
		Rect2(960, 0, 20, 540),
	]
	var bg = BG.new()
	bg.mode = "training"
	bg.floor_y = FLOOR_Y
	bg.world_w = 960.0
	add_child(bg)

	var kinds := ["husk", "spitter", "warden"]
	for i in 3:
		var e = MINIBOSS.new()
		e.setup(kinds[i], Vector2(540 + i * 140, FLOOR_Y))
		add_child(e)
		e.watch(player)
		enemies.append(e)


func _spawn() -> Vector2:
	return Vector2(150, FLOOR_Y)


func _controls() -> Array:
	return [
		"WASD  MOVE      SPACE  JUMP      SHIFT  DASH      J  THE BUTTON      ESC  MENU",
		"the bar above the band is the enemy's clock — press inside a zone and the button becomes it",
		"COUNTER prints 6 and staggers 800 ms · CLASH prints nothing and saves you · a mistimed tap eats the swing",
	]
