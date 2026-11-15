# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# SCENE 3 — THE CACHE LOOP. Death is still a story:
#   the offline screen (monochrome + glitch), the three options unlocked after
#   400 ms, the designation counter, the module at half a bar.
#
# v2 change (feedback #6): the PIT is a route now, not a death edge. It fades and
# hands you back your last ground. The SEAM is still the kill-zone — that is what
# carries the death story, and it is a hazard you walk into on purpose.
extends "res://fight.gd"

const BG := preload("res://bg.gd")

const FLOOR_Y := 420.0
const PIT_L := 390.0
const PIT_R := 450.0
const SEAM_L := 872.0
const SEAM_R := 916.0
const TERM_X := 640.0
const TERM_H := 60.0

var terminal_armed := true
var cache_acks := 0


func _build() -> void:
	hud_title = "THE CACHE LOOP"
	hud_sub = "the pit is a route now. the seam is still the seam."
	solids = [
		Rect2(0, FLOOR_Y, PIT_L, 160),
		Rect2(PIT_R, FLOOR_Y, 960 - PIT_R, 160),
		Rect2(-20, 0, 20, 600),
		Rect2(960, 0, 20, 600),
	]
	var bg = BG.new()
	bg.mode = "cache"
	bg.floor_y = FLOOR_Y
	bg.world_w = 960.0
	add_child(bg)

	# the seam: the environmental death edge (TR-CSD-018 territory)
	hazards.append({"rect": Rect2(SEAM_L, 220.0, SEAM_R - SEAM_L, FLOOR_Y - 220.0),
		"cause": "FAULT: THE SEAM · ENVIRONMENT · TICK %d" % 0})


func _physics_process(delta: float) -> void:
	super(delta)
	if dead:
		return
	# the terminal: walk in -> the bar goes to hp_max, the first ack grants a module
	var trig := Rect2(TERM_X - 46.0, FLOOR_Y - TERM_H, 92.0, TERM_H)
	var inside: bool = player.hurtbox().intersects(trig)
	if inside and terminal_armed:
		terminal_armed = false
		_ack_cache()
	elif not inside:
		terminal_armed = true
	if not hazards.is_empty():
		hazards[0]["cause"] = "FAULT: THE SEAM · ENVIRONMENT · TICK %d" % int(world_ms / 16.67)


func _ack_cache() -> void:
	cache_acks += 1
	var before: float = player.hp
	player.restore_full()
	_log("CACHE // ACK")
	_log("CHASSIS RESTORED — %d / %d" % [int(player.hp), int(player.hp_max)])
	if int(before) < int(player.hp):
		dmg.spawn(Vector2(player.position.x, player.position.y - 56.0),
			"+%d" % int(player.hp - before), K.C_CYAN, 15)
	if not K.cache_granted:
		K.cache_granted = true
		K.restore_modules = mini(K.restore_modules + 1, K.RESTORE_MODULE_CAP_MVP)
		_log("RESTORE MODULE GRANTED — carried %d" % K.restore_modules)
	_log("DESIGNATION %s" % K.designation_text(K.designations))


func _spawn() -> Vector2:
	if K.cache_respawn_at_terminal:
		K.cache_respawn_at_terminal = false
		player.restore_full()
		return Vector2(TERM_X - 70.0, FLOOR_Y)
	return Vector2(120, FLOOR_Y)


func _respawn_point() -> Vector2:
	return last_safe


func _death_cause() -> String:
	return "FAULT: THE SEAM · ENVIRONMENT · TICK %d" % int(world_ms / 16.67)


func _on_choice(choice: String) -> void:
	if choice == "reconstruct":
		K.designations += 1
		K.pending_stamp = "DESIGNATION " + K.designation_text(K.designations)
		K.cache_respawn_at_terminal = true
		get_tree().reload_current_scene()
		return
	super(choice)


func _controls() -> Array:
	return [
		"WASD  MOVE      SPACE  JUMP      ESC  MENU",
		"walk into the terminal to restore the bar · the pit hands you back, the seam kills once",
		"",
	]
