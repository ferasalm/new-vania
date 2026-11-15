# PROTOTYPE - NOT FOR PRODUCTION
# The menu: three rooms + quit. Keyboard only, cold start.
extends Node2D

const ITEMS := [
	{"title": "THE DUEL RANGE", "file": "res://duel.tscn",
		"sub": "the combat feel — light 2 / heavy 4 / counter 3 or 6 / knockdown 1200 ms"},
	{"title": "THE CACHE LOOP", "file": "res://cache.tscn",
		"sub": "death is a story — the offline screen, the module, the designation"},
	{"title": "THE DENIAL LIE", "file": "res://denial.tscn",
		"sub": "the boss read — hp 60, the floor 20, three unanswered sweeps"},
	{"title": "QUIT", "file": "", "sub": ""},
]

var sel := 0
var t := 0.0


func _ready() -> void:
	K.frozen = false


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
	draw_rect(Rect2(0, 0, 960, 540), K.C_BG)
	# the three rooms as three flat rects on a line — the whole suite at a glance
	for i in 3:
		var x := 210.0 + i * 180.0
		draw_rect(Rect2(x, 96, 120, 4), K.C_BONE if i == sel else K.C_BONE_DIM)

	_center("THREE ROOMS TO FEEL", 150, 30, K.C_BONE)
	_center("no gates, no docs — play the landed numbers", 176, 11, K.C_BONE_DIM)

	for i in ITEMS.size():
		var y := 250.0 + i * 52.0
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
		K.training_data], 40, 500, 11, K.C_BONE_DIM)
	_center("W/S  SELECT      ENTER  PLAY      ESC  QUIT", 522, 11, K.C_BONE_DIM)


func _text(tt: String, x: float, y: float, sz: int, c: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(x, y), tt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, c)


func _center(tt: String, y: float, sz: int, c: Color) -> void:
	var w := ThemeDB.fallback_font.get_string_size(tt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	_text(tt, 480.0 - w * 0.5, y, sz, c)
