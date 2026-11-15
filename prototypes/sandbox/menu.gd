# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# The menu: four rooms + quit. Keyboard only, cold start, no build step.
extends Node2D

const BG := preload("res://bg.gd")

const ITEMS := [
	{"title": "THE ONE BUTTON", "file": "res://training.tscn",
		"sub": "one key — strike, clash, counter — with the timing windows on screen"},
	{"title": "THE APPROACH", "file": "res://approach.tscn",
		"sub": "real sprites · pits are routes · no locks · two named mini-bosses · her door"},
	{"title": "THE CACHE LOOP", "file": "res://cache.tscn",
		"sub": "death is a story — the offline screen, the module, the designation"},
	{"title": "ARNETRIA'S ARENA", "file": "res://arena.tscn",
		"sub": "the Mirror Queen — her bar does not move, and the store is printed"},
	{"title": "QUIT", "file": "", "sub": ""},
]

var sel := 0
var t := 0.0


func _ready() -> void:
	K.frozen = false
	var bg = BG.new()
	bg.mode = "arena"
	bg.floor_y = 470.0
	bg.world_w = 960.0
	add_child(bg)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_W, KEY_UP:
			sel = (sel + ITEMS.size() - 1) % ITEMS.size()
		KEY_S, KEY_DOWN:
			sel = (sel + 1) % ITEMS.size()
		KEY_1:
			_go(0)
		KEY_2:
			_go(1)
		KEY_3:
			_go(2)
		KEY_4:
			_go(3)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_go(sel)
		KEY_ESCAPE:
			get_tree().quit()


func _go(i: int) -> void:
	sel = i
	var f: String = ITEMS[i]["file"]
	if f == "":
		get_tree().quit()
		return
	get_tree().change_scene_to_file(f)


func _draw() -> void:
	# the veil over her broken clock
	draw_rect(Rect2(0, 0, 960, 540), Color(K.C_BG.r, K.C_BG.g, K.C_BG.b, 0.55))

	for i in ITEMS.size() - 1:
		var x := 186.0 + i * 152.0
		draw_rect(Rect2(x, 96, 110, 3), K.C_BONE if i == sel else K.C_BONE_DIM)

	_center("THE SANDBOX SUITE", 148, 30, K.C_BONE)
	_center("v2 — the playtest pass. no gates, no docs: play the landed numbers.", 174, 11, K.C_BONE_DIM)

	for i in ITEMS.size():
		var y := 240.0 + i * 50.0
		var on := i == sel
		var c := K.C_BONE if on else Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.8)
		if on:
			var a := 0.08 + 0.04 * sin(t * 3.0)
			draw_rect(Rect2(200, y - 20, 560, 30), Color(K.C_AMBER.r, K.C_AMBER.g, K.C_AMBER.b, a))
			draw_rect(Rect2(200, y - 20, 2, 30), K.C_AMBER)
			c = K.C_AMBER
		_text("%d   %s" % [i + 1, ITEMS[i]["title"]], 216, y, 17, c)
		if ITEMS[i]["sub"] != "":
			_text(ITEMS[i]["sub"], 216, y + 16, 10,
				Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.85))

	_text("DESIGNATION %s    MODULE %s    TRAINING DATA %03d" % [
		K.designation_text(K.designations),
		"CARRIED" if K.restore_modules > 0 else "—",
		K.training_data], 40, 508, 11, K.C_BONE_DIM)
	_center("W/S  SELECT      ENTER  PLAY      ESC  QUIT", 528, 11, K.C_BONE_DIM)


func _text(tt: String, x: float, y: float, sz: int, c: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(x, y), tt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, c)


func _center(tt: String, y: float, sz: int, c: Color) -> void:
	var w := ThemeDB.fallback_font.get_string_size(tt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	_text(tt, 480.0 - w * 0.5, y, sz, c)
