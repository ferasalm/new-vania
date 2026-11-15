# PROTOTYPE - NOT FOR PRODUCTION
# SCENE 2 — THE CACHE LOOP. Death is a story:
#   the pit / the seam fire the death edge EXACTLY ONCE -> monochrome + glitch,
#   SYSTEM OFFLINE / you are destroyed / the cause row, then the three options
#   (module / reconstruct / quit) unlocked after OFFLINE_HOLD_MS 400.
#   The module reboots on the spot at half a bar + 1000 ms hum, module gone.
#   The reconstruct stamps a new 3-digit designation. The terminal restores fully.
extends Node2D

const PLAYER := preload("res://player.gd")
const HPBAR := preload("res://ui_hp_bar.gd")
const DMG := preload("res://ui_dmg.gd")
const OFFLINE := preload("res://offline.gd")
const BG := preload("res://bg.gd")

const FLOOR_Y := 420.0
const PIT_L := 390.0
const PIT_R := 450.0
const SEAM_L := 872.0
const SEAM_R := 916.0
const TERM_X := 640.0
const TERM_W := 44.0
const TERM_H := 60.0

var player
var solids: Array = []
var dmg
var bar
var world_ms := 0.0
var dead := false
var death_count := 0
var offline = null
var log_lines: Array = []
var stamp := ""
var stamp_ms := 0.0
var terminal_armed := true
var last_safe := Vector2(120, FLOOR_Y)
var cache_acks := 0


func _ready() -> void:
	K.frozen = false
	solids = [
		Rect2(0, FLOOR_Y, PIT_L, 120),
		Rect2(PIT_R, FLOOR_Y, 960 - PIT_R, 120),
		Rect2(-20, 0, 20, 540),
		Rect2(960, 0, 20, 540),
	]
	var bg = BG.new()
	bg.mode = "cache"
	add_child(bg)
	bg.z_index = -1000
	player = PLAYER.new()
	add_child(player)
	player.solids = solids
	player.combat = false
	player.z_index = -5

	var spawn := Vector2(120, FLOOR_Y)
	if K.cache_respawn_at_terminal:
		spawn = Vector2(TERM_X - 70.0, FLOOR_Y)
		K.cache_respawn_at_terminal = false
		player.restore_full()
	player.position = spawn
	last_safe = spawn

	dmg = DMG.new()
	add_child(dmg)
	dmg.z_index = 6

	bar = HPBAR.new()
	add_child(bar)
	bar.position = Vector2(40, 70)
	bar.label = "CHASSIS"
	bar.z_index = 1

	stamp = K.pending_stamp
	stamp_ms = 1600.0 if stamp != "" else 0.0
	K.pending_stamp = ""


func _physics_process(delta: float) -> void:
	var wd := delta * 1000.0
	world_ms += wd
	dmg.step(wd)
	if stamp_ms > 0.0:
		stamp_ms -= wd
	bar.hp = player.hp
	bar.hp_max = player.hp_max

	if dead:
		queue_redraw()
		return

	# the last grounded safe position (TR-CSD-018: the ENVIRONMENT revive placement)
	if player.on_ground and player.position.x > PIT_R + 8.0 and player.position.x < SEAM_L - 8.0:
		last_safe = player.position

	# the terminal: walk in -> the bar goes to hp_max, the first ack grants a module
	var trig := Rect2(TERM_X - 46.0, FLOOR_Y - TERM_H, 92.0, TERM_H)
	var inside: bool = player.hurtbox().intersects(trig)
	if inside and terminal_armed:
		terminal_armed = false
		_ack_cache()
	elif not inside:
		terminal_armed = true

	# the death edges
	if player.position.y > 560.0:
		_die("FAULT: THE PIT · ENVIRONMENT · TICK %d" % int(world_ms / 16.67))
	elif player.hurtbox().intersects(Rect2(SEAM_L, 240.0, SEAM_R - SEAM_L, FLOOR_Y - 240.0)):
		_die("FAULT: THE SEAM · ENVIRONMENT · TICK %d" % int(world_ms / 16.67))
	queue_redraw()


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


func _log(t: String) -> void:
	log_lines.push_front({"text": t, "t": 3200.0})
	if log_lines.size() > 6:
		log_lines.pop_back()


func _die(cause: String) -> void:
	if dead:
		return
	dead = true
	death_count += 1
	player.locked = true
	player.vel = Vector2.ZERO
	var bb := BackBufferCopy.new()
	bb.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(bb)
	offline = OFFLINE.new()
	offline.cause = cause
	offline.has_module = K.restore_modules > 0
	add_child(offline)
	offline.chosen.connect(_on_choice)


func _on_choice(choice: String) -> void:
	match choice:
		"module":
			# the revive: on the spot for a strike death, at last_grounded_safe_pos
			# for the ENVIRONMENT death (TR-CSD-018) — never inside the hazard.
			K.restore_modules -= 1
			K.designations += 1
			K.pending_stamp = "DESIGNATION " + K.designation_text(K.designations)
			player.position = last_safe
			player.revive(K.RESTORE_MODULE_HEAL_PCT)
			dead = false
			offline.queue_free()
			offline = null
			_log("REBOOT — %d ms hum" % K.REVIVE_IFRAME_MS)
			dmg.spawn(player.position + Vector2(0, -56.0), "+%d" % int(player.hp), K.C_CYAN, 16)
		"reconstruct":
			K.designations += 1
			K.pending_stamp = "DESIGNATION " + K.designation_text(K.designations)
			K.cache_respawn_at_terminal = true
			get_tree().reload_current_scene()
		"quit":
			get_tree().change_scene_to_file("res://menu.tscn")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if dead:
		return
	if event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://menu.tscn")


# ── the frame ───────────────────────────────────────────────────────────────
func _draw() -> void:
	# the HUD band behind the controls
	draw_rect(Rect2(0, 470, 960, 70), Color(K.C_BG.r, K.C_BG.g, K.C_BG.b, 0.86))
	draw_rect(Rect2(0, 470, 960, 1), Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.2))

	_text("THE CACHE LOOP", 40, 26, 15, K.C_BONE)
	_text("the pit and the seam are the death edges — walk in", 40, 40, 10, K.C_BONE_DIM)
	_text("DESIGNATION  %s" % K.designation_text(K.designations), 760, 44, 13, K.C_BONE)
	_text("MODULE  %s" % ("CARRIED" if K.restore_modules > 0 else "—"), 760, 62, 11, K.C_BONE_DIM)

	var y := 90.0
	for l in log_lines:
		l["t"] -= 16.6
		var a: float = clampf(l["t"] / 800.0, 0.0, 1.0)
		var c := K.C_BONE
		c.a = a
		_text(l["text"], 40, y, 12, c)
		y += 18.0
	log_lines = log_lines.filter(func(l): return l["t"] > 0.0)

	if stamp_ms > 0.0:
		var a2: float = clampf(stamp_ms / 400.0, 0.0, 1.0)
		var c2 := K.C_AMBER
		c2.a = a2
		_center(stamp, 300, 24, c2)

	if dead:
		return
	var f1 := "WASD / ARROWS  MOVE      SPACE  JUMP      ESC  MENU"
	var f2 := "walk into the terminal to restore the bar · the pit and the seam kill exactly once"
	_center(f1, 500, 11, K.C_BONE)
	_center(f2, 518, 10, Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.85))


func _text(t: String, x: float, y: float, sz: int, c: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(x, y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, c)


func _center(t: String, y: float, sz: int, c: Color) -> void:
	var w := ThemeDB.fallback_font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	_text(t, 480.0 - w * 0.5, y, sz, c)
