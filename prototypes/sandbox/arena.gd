# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# SCENE 4 — ARNETRIA'S ARENA. One door, and it seals behind you.
#
# The fight (feedback #3 + #4):
#   her bar is 60 and it does not move. every hit prints and is STORED, and the
#   store is printed beside the bar. on a period she casts a MIRROR with a visible
#   timer ring: break it in time and the whole store lands in one lurch; miss and
#   the store is cleared. the phase ends when the bar finally moves past the stall
#   (20/60). phase 2 is her without the lie.
extends "res://fight.gd"

const ARN := preload("res://arnetria.gd")
const BOSSBAR := preload("res://ui_boss_bar.gd")
const BG := preload("res://bg.gd")

const FLOOR_Y := 440.0
const ARENA_L := 40.0
const ARENA_R := 920.0

var boss
var bossbar
var won := false


func _build() -> void:
	hud_title = "ARNETRIA, THE MIRROR QUEEN"
	hud_sub = "she does not file the damage. the mirror is the only way to make it count."
	solids = [
		Rect2(0, FLOOR_Y, 960, 140),
		Rect2(-20, 0, 20, 600),
		Rect2(960, 0, 20, 600),
	]
	var bg = BG.new()
	bg.mode = "arena"
	bg.floor_y = FLOOR_Y
	bg.world_w = 960.0
	add_child(bg)

	boss = ARN.new()
	add_child(boss)
	boss.setup(Vector2(690, FLOOR_Y), ARENA_L, ARENA_R)
	boss.watch(player)
	enemies.append(boss)

	# the one door in the suite that locks, and it locks the moment you are inside
	var d = DOOR.new()
	d.kind = "boss"
	d.target = "res://approach.tscn"
	d.position = Vector2(76, FLOOR_Y)
	add_child(d)
	d.seal()
	doors.append(d)

	bossbar = BOSSBAR.new()
	hud_layer.add_child(bossbar)
	bossbar.position = Vector2(300, 34)
	bossbar.label = "ARNETRIA"


func _physics_process(delta: float) -> void:
	super(delta)
	if boss == null or not is_instance_valid(boss):
		return
	bossbar.set_values(boss.hp, boss.stored, boss.hp_floor, boss.phase)
	if boss.script_done() and not won:
		won = true
		done = true
		player.locked = true


func _spawn() -> Vector2:
	return Vector2(240, FLOOR_Y)


func _controls() -> Array:
	if won:
		return ["", "", ""]
	return [
		"WASD  MOVE      SPACE  JUMP      SHIFT  DASH      J  THE BUTTON      ESC  MENU",
		"her bar will not move while she is storing — break the mirror inside its ring to make it all land at once",
		"the sweep is unclashable (step out) · the fling is your counter · miss the mirror and the store is gone",
	]


func _draw() -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var phase_txt := "PHASE 1 — THE STALL   (her bar cannot move)"
	var col := K.C_ICE
	if boss.phase == "LIE_CRACKED":
		phase_txt = "PHASE 2 — THE BAR MOVES"
		col = K.C_BONE
	var w := ThemeDB.fallback_font.get_string_size(phase_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(ThemeDB.fallback_font, Vector2(480.0 - w * 0.5, 60), phase_txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)

	if won:
		var a: float = clampf((boss.script_t - K.RECOGNITION_BEAT_MS - K.DISSOLVE_MS) / 400.0, 0.0, 1.0)
		var c := K.C_BONE
		c.a = maxf(a, 0.0)
		_center("the room stays perfect. you are the one who changed.", 300, 16, c)
		_center("ENTER — back to the menu", 326, 11, K.C_BONE_DIM)


func _center(txt: String, y: float, sz: int, c: Color) -> void:
	var w := ThemeDB.fallback_font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(ThemeDB.fallback_font, Vector2(480.0 - w * 0.5, y), txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, c)
