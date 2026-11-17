# PROTOTYPE - NOT FOR PRODUCTION
# The touch rig for Android: a floating stick in the left 42% of the screen and
# a button cluster on the right. It feeds the same InputMap actions the keyboard
# uses (game.gd), so player.gd, main.gd, enemy.gd and boss.gd do not know it
# exists. Follows design/gdd/input-control-mapping.md where the prototype has
# the verb: stick left 42%, crouch is the stick's down-zone (25 deg entry /
# 45 deg exit, 90 ms hold guard), attack is the largest and innermost button,
# jump sits above it, backdash is double-tap-back on the stick (a flick away
# from where she looks dashes that way), and two small arrow buttons are the
# a11y direct press: "<BD" dashes left and "BD>" dashes right. The save terminal
# gets a world-anchored bubble. The buttons sit in a diamond under the right
# thumb (attack left, jump bottom, the two backdash arrows right, special top),
# the way Bloodstained: Ritual of the Night lays them out on a phone. Pause >
# CONTROLS lets the player drag every button and the stick anywhere, resize
# them, fade them and pick a floating or fixed stick; the layout is kept in
# user://touch_layout.json.
extends Control

const VIEW := Vector2(384, 216)
const ZONE_X := 384.0 * 0.42
const REST := Vector2(64, 150)
const STICK_R := 30.0
const KNOB_R := 11.0
const DEAD := 0.22
const CROUCH_ENTER := 0.4363323129985824   # 25 degrees
const CROUCH_EXIT := 0.7853981633974483    # 45 degrees
const CROUCH_MAG := 0.65
const CROUCH_OUT := 0.40
const CROUCH_GUARD := 0.09
const BACK_WINDOW := 0.28
const BACK_FLICK := 0.55
const BUBBLE_R := 22.0

const DEFAULT_BTN := [
	{"id": "attack", "pos": Vector2(286, 152), "r": 20.0, "label": "ATK", "size": 8},
	{"id": "jump", "pos": Vector2(322, 184), "r": 20.0, "label": "JUMP", "size": 8},
	{"id": "backdash_left", "pos": Vector2(355, 133), "r": 15.0, "label": "<BD", "size": 6},
	{"id": "backdash_right", "pos": Vector2(366, 172), "r": 15.0, "label": "BD>", "size": 6},
	{"id": "special", "pos": Vector2(322, 120), "r": 18.0, "label": "SPEC", "size": 7},
	{"id": "swap", "pos": Vector2(250, 196), "r": 13.0, "label": "SWAP", "size": 6},
	{"id": "pause", "pos": Vector2(366, 14), "r": 10.0, "label": "", "size": 6},
]
const LAYOUT_FILE := "user://touch_layout.json"
const ROOM_LABELS := {"church": "CHURCH", "library": "LIBRARY", "save": "CACHE 1", "lab": "LAB", "save2": "CACHE 2", "boss": "BOSS"}

var active := false
var paused := false
var blocked := false:        # the SYSTEM OFFLINE screen owns the fingers
	set(v):
		blocked = v
		if v:
			_release_all()
		queue_redraw()
var editing := false         # Pause > CONTROLS: drag, resize and fade the buttons
var BTN: Array = []          # the live layout (DEFAULT_BTN + what the player saved)
var rest := REST             # where the stick sits
var fixed_stick := false     # false = the stick appears under the thumb
var see := 1.0               # how solid the controls are drawn (0.3 .. 1.6)
var layout_file := LAYOUT_FILE   # a test passes "layout=<name>.json" to use its own file
var _edit_bar: CanvasLayer
var _edit_row: HBoxContainer   # the editor's own buttons, along the top
var _edit_pick := ""         # the control being edited ("stick" or a button id)
var _edit_drag := false
var _stick_label: Button

var _stick_id := -1
var _origin := REST
var _vec := Vector2.ZERO
var _crouch_t := 0.0
var _crouch_on := false
var _back_t := -1.0
var _bind := {}          # finger index -> {kind, id}
var _down := {}          # button id -> finger index (for the pressed look)
var _next_attack := "attack"
var _bubble_on := false
var _bubble_pos := Vector2.ZERO
var _overlay: CanvasLayer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = VIEW
	active = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() \
		or OS.get_cmdline_user_args().has("--touch") or OS.get_cmdline_user_args().has("touch")
	visible = active
	set_process(active)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("layout=") and a.get_file().length() > 7:
			layout_file = "user://" + a.substr(7).get_file()
	_load_layout()
	_build_menu()
	_build_edit_bar()
	if active and G.main != null and G.main.hud != null:
		G.main.hud.touch_mode = true
	queue_redraw()


func _build_menu() -> void:
	# The pause surface: one corner control outside every other zone (GDD TR-INP-001).
	_overlay = CanvasLayer.new()
	_overlay.layer = 40
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.visible = false
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.82)
	dim.size = VIEW
	_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.size = VIEW
	_overlay.add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	center.add_child(col)
	col.add_theme_constant_override("separation", 2)
	_menu_button(col, "RESUME", _resume)
	_menu_button(col, "CONTROLS", _edit_start)
	_menu_button(col, "RECONSTRUCT", _restart)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	col.add_child(grid)
	for room in ROOM_LABELS:
		_menu_button(grid, ROOM_LABELS[room], _goto_room.bind(room), 65.0)
	_menu_button(col, "QUIT", get_tree().quit)


func _menu_button(col: Container, text: String, cb: Callable, width: float = 132.0) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 17)
	b.add_theme_font_size_override("font_size", 9)
	b.pressed.connect(cb)
	col.add_child(b)


func _input(event: InputEvent) -> void:
	if editing:
		_edit_input(event)
		return
	if not active or paused or blocked:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_down_at(event.index, event.position)
		else:
			_up_at(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_drag_at(event.index, event.position)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not active or paused:
		return
	if _stick_id >= 0:
		_update_crouch(delta)
	var near := _near_terminal()
	if near != _bubble_on:
		_bubble_on = near
		queue_redraw()
	if _bubble_on:
		var p := _terminal_screen_pos()
		if p != _bubble_pos:
			_bubble_pos = p
			queue_redraw()


func _down_at(id: int, pos: Vector2) -> void:
	if _bind.has(id):
		return
	# the interact bubble wins over everything under it
	if _bubble_on and pos.distance_to(_bubble_pos) <= BUBBLE_R + 8.0:
		_bind[id] = {"kind": "bubble"}
		_tap("up")
		return
	# buttons first (the cluster sits outside the stick zone)
	for b in BTN:
		if pos.distance_to(b["pos"]) <= float(b["r"]) + 10.0:
			_bind[id] = {"kind": "button", "id": b["id"]}
			_down[b["id"]] = id
			_button_down(b["id"])
			queue_redraw()
			return
	# the floating stick: it appears where the thumb lands, inside the left 42%
	if pos.x <= ZONE_X and _stick_id < 0:
		_stick_id = id
		_bind[id] = {"kind": "stick"}
		_origin = rest if fixed_stick else pos.clamp(Vector2(STICK_R + 4.0, STICK_R + 4.0), VIEW - Vector2(STICK_R + 4.0, STICK_R + 4.0))
		_vec = Vector2.ZERO
		_crouch_t = 0.0
		if fixed_stick:
			_drag_at(id, pos)      # a fixed stick answers the first touch at once
		queue_redraw()


func _drag_at(id: int, pos: Vector2) -> void:
	if String(_bind.get(id, {}).get("kind", "")) != "stick":
		return
	_vec = (pos - _origin) / STICK_R
	if _vec.length() > 1.0:
		_vec = _vec.normalized()
	_apply_move()
	queue_redraw()


func _up_at(id: int) -> void:
	var b: Dictionary = _bind.get(id, {})
	if b.is_empty():
		return
	_bind.erase(id)
	match String(b.get("kind", "")):
		"stick":
			_backdash_check()
			_stick_id = -1
			_vec = Vector2.ZERO
			_release_move()
			queue_redraw()
		"button":
			var bid := String(b["id"])
			_down.erase(bid)
			_button_up(bid)
			queue_redraw()


func _apply_move() -> void:
	Input.action_release("left")
	Input.action_release("right")
	if _vec.x < -DEAD:
		Input.action_press("left", minf(1.0, -_vec.x))
	elif _vec.x > DEAD:
		Input.action_press("right", minf(1.0, _vec.x))


func _update_crouch(delta: float) -> void:
	# GDD TR-INP-066: narrow entry (25 deg / 0.65, 90 ms guard), wide exit (45 deg / 0.40)
	var mag := _vec.length()
	var ang := absf(_vec.angle_to(Vector2.DOWN))
	var in_enter := mag >= CROUCH_MAG and ang <= CROUCH_ENTER
	var in_exit := mag >= CROUCH_OUT and ang <= CROUCH_EXIT
	if not _crouch_on:
		if in_enter:
			_crouch_t += delta
			if _crouch_t >= CROUCH_GUARD:
				_crouch_on = true
				Input.action_press("down")
		else:
			_crouch_t = 0.0
	elif not in_exit:
		_crouch_on = false
		_crouch_t = 0.0
		Input.action_release("down")


func _release_move() -> void:
	Input.action_release("left")
	Input.action_release("right")
	Input.action_release("down")
	_crouch_on = false
	_crouch_t = 0.0


func _backdash_check() -> void:
	# GDD TR-INP-056: flick back -> release -> flick back, both inside 280 ms.
	var p: Node = G.main.player if G.main != null else null
	if p == null:
		return
	if _vec.x * float(p.facing) > -BACK_FLICK or absf(_vec.x) < absf(_vec.y):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if _back_t >= 0.0 and now - _back_t <= BACK_WINDOW:
		_back_t = -1.0
		# a flick away from where she looks = a dash that way
		_tap("backdash_left" if float(p.facing) == 1.0 else "backdash_right")
	else:
		_back_t = now


func _button_down(id: String) -> void:
	match id:
		"attack":
			# one Attack verb (GDD TR-INP-002): alternate the hands so the
			# prototype's faster two-hand chain survives on one button.
			var a := _next_attack
			_next_attack = "attack2" if a == "attack" else "attack"
			_tap(a)
		"jump":
			Input.action_press("jump")
		"special":
			# Up + Attack = the blade wave; both edges land before the physics tick.
			Input.action_release("up")
			Input.action_press("up")
			Input.action_release("attack")
			Input.action_press("attack")
			_release_soon(["up", "attack"])
		"swap":
			_tap("swap")
		"backdash_left":
			_tap("backdash_left")
		"backdash_right":
			_tap("backdash_right")
		"pause":
			_pause()


func _button_up(id: String) -> void:
	if id == "jump":
		Input.action_release("jump")


func _tap(action: String) -> void:
	Input.action_release(action)
	Input.action_press(action)
	_release_soon([action])


func _release_soon(actions: Array) -> void:
	await get_tree().create_timer(0.05).timeout
	for a in actions:
		Input.action_release(a)


func _release_all() -> void:
	for a in ["left", "right", "down", "jump", "attack", "attack2", "up", "backdash_left", "backdash_right", "swap"]:
		Input.action_release(a)
	_stick_id = -1
	_vec = Vector2.ZERO
	_crouch_on = false
	_crouch_t = 0.0
	_bind.clear()
	_down.clear()


func toggle_pause() -> void:
	# Esc / P / Start on a keyboard or pad, the corner button on a phone
	if blocked or editing:
		return
	if paused:
		_resume()
	elif G.main != null and not G.main._busy:
		_pause()


func _pause() -> void:
	_release_all()
	paused = true
	_overlay.visible = true
	get_tree().paused = true
	Sfx.pause_music(true)      # the music stops with the game and picks up where it was
	queue_redraw()


func _resume() -> void:
	_overlay.visible = false
	get_tree().paused = false
	paused = false
	Sfx.pause_music(false)
	queue_redraw()


func _restart() -> void:
	if G.main == null or G.main._busy:
		return
	_resume()
	G.main.reconstruct()


# ---- Pause > CONTROLS: the player's own layout ----

func _load_layout() -> void:
	BTN = []
	for b in DEFAULT_BTN:
		BTN.append(b.duplicate())
	rest = REST
	fixed_stick = false
	see = 1.0
	if not FileAccess.file_exists(layout_file):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(layout_file))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var saved_btn: Dictionary = parsed.get("btn", {})
	# only ids this build knows are read: an old saved entry for the single
	# backdash button is ignored, and a button the file does not mention keeps
	# the default position it has now
	for b in BTN:
		var got = saved_btn.get(b["id"], null)
		if typeof(got) == TYPE_ARRAY and got.size() == 3:
			b["r"] = clampf(float(got[2]), 8.0, 40.0)
			b["pos"] = Vector2(float(got[0]), float(got[1])).clamp(Vector2(b["r"], b["r"]), VIEW - Vector2(b["r"], b["r"]))
	var st = parsed.get("stick", null)
	if typeof(st) == TYPE_ARRAY and st.size() == 2:
		rest = Vector2(float(st[0]), float(st[1])).clamp(Vector2(20, 20), VIEW - Vector2(20, 20))
	fixed_stick = bool(parsed.get("fixed", false))
	see = clampf(float(parsed.get("see", 1.0)), 0.3, 1.6)


func _save_layout() -> void:
	var out := {"btn": {}, "stick": [rest.x, rest.y], "fixed": fixed_stick, "see": see}
	for b in BTN:
		out["btn"][b["id"]] = [b["pos"].x, b["pos"].y, b["r"]]
	var f := FileAccess.open(layout_file, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(out))


func _build_edit_bar() -> void:
	_edit_bar = CanvasLayer.new()
	_edit_bar.layer = 41
	_edit_bar.process_mode = Node.PROCESS_MODE_ALWAYS
	_edit_bar.visible = false
	add_child(_edit_bar)
	var row := HBoxContainer.new()
	row.position = Vector2(4, 2)
	_edit_row = row
	row.add_theme_constant_override("separation", 2)
	_edit_bar.add_child(row)
	_menu_button(row, "SMALLER", _edit_size.bind(-2.0), 44.0)
	_menu_button(row, "BIGGER", _edit_size.bind(2.0), 40.0)
	_menu_button(row, "FAINTER", _edit_see.bind(-0.15), 42.0)
	_menu_button(row, "SOLID", _edit_see.bind(0.15), 34.0)
	_stick_label = Button.new()
	_stick_label.custom_minimum_size = Vector2(72, 17)
	_stick_label.add_theme_font_size_override("font_size", 9)
	_stick_label.pressed.connect(_edit_stick_mode)
	row.add_child(_stick_label)
	_menu_button(row, "RESET", _edit_reset, 36.0)
	_menu_button(row, "DONE", _edit_done, 36.0)


func _edit_start() -> void:
	# the game stays paused; the buttons are drawn and can be dragged
	_overlay.visible = false
	editing = true
	visible = true
	_edit_pick = "attack"
	_edit_bar.visible = true
	_stick_label.text = "STICK: FIXED" if fixed_stick else "STICK: FLOATS"
	queue_redraw()


func _edit_done() -> void:
	_save_layout()
	editing = false
	_edit_bar.visible = false
	visible = active
	_overlay.visible = true
	queue_redraw()


func _edit_reset() -> void:
	if FileAccess.file_exists(layout_file):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(layout_file))
	_load_layout()
	_stick_label.text = "STICK: FLOATS"
	queue_redraw()


func _edit_size(by: float) -> void:
	for b in BTN:
		if b["id"] == _edit_pick:
			b["r"] = clampf(float(b["r"]) + by, 8.0, 40.0)
			b["pos"] = _on_screen(b["pos"], float(b["r"]))      # a control that grew at the edge moves in
	queue_redraw()


func _edit_see(by: float) -> void:
	see = clampf(see + by, 0.3, 1.6)
	queue_redraw()


func _edit_stick_mode() -> void:
	fixed_stick = not fixed_stick
	_stick_label.text = "STICK: FIXED" if fixed_stick else "STICK: FLOATS"


func _edit_input(event: InputEvent) -> void:
	# a finger (or the mouse, on a computer) picks a control up and moves it
	var pos := Vector2.ZERO
	var down := false
	var up := false
	var move := false
	var desk := not OS.has_feature("mobile")
	if event is InputEventScreenTouch:
		pos = event.position
		down = event.pressed
		up = not event.pressed
	elif event is InputEventScreenDrag:
		pos = event.position
		move = true
	elif desk and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
		down = event.pressed
		up = not event.pressed
	elif desk and event is InputEventMouseMotion:
		pos = event.position
		move = true
	else:
		return
	if down and not _on_edit_row(pos):
		_edit_drag = false
		var best := 9999.0
		for b in BTN:
			var d: float = pos.distance_to(b["pos"]) - float(b["r"])
			if d < 8.0 and d < best:
				best = d
				_edit_pick = b["id"]
				_edit_drag = true
		if not _edit_drag and pos.distance_to(rest) < STICK_R + 8.0:
			_edit_pick = "stick"
			_edit_drag = true
		queue_redraw()
	elif up:
		_edit_drag = false
	elif move and _edit_drag:
		if _edit_pick == "stick":
			rest = _on_screen(pos, STICK_R).clamp(Vector2(STICK_R, STICK_R), Vector2(ZONE_X - 4.0, VIEW.y - STICK_R))
		else:
			for b in BTN:
				if b["id"] == _edit_pick:
					b["pos"] = _on_screen(pos, float(b["r"]))
		queue_redraw()


func _on_edit_row(pos: Vector2) -> bool:
	# a press on the editor's own row of buttons is for those buttons, not for a control
	return _edit_row != null and _edit_row.get_global_rect().grow(3.0).has_point(pos)


func _on_screen(at: Vector2, r: float) -> Vector2:
	# the whole control stays on the screen, and out from under the editor's row of buttons
	var top := r
	if _edit_row != null and at.x - r < _edit_row.get_global_rect().end.x + 3.0:
		top = maxf(r, _edit_row.get_global_rect().end.y + 3.0 + r)
	return at.clamp(Vector2(r, top), VIEW - Vector2(r, r))


func _goto_room(room: String) -> void:
	if G.main == null or G.main._busy:
		return
	_resume()
	G.main.player.hp = 0.0
	G.main.enter(room, "P" if room == "church" else "left")


func _near_terminal() -> bool:
	if G.main == null or G.main.player == null or G.main.room == null:
		return false
	if not G.main.room.spawns.has("M"):
		return false
	var p: Node = G.main.player
	return absf(p.global_position.x - G.main.room.spawns["M"].x) < 30.0 and p.is_on_floor()


func _terminal_screen_pos() -> Vector2:
	var at: Vector2 = G.main.room.spawns["M"] + Vector2(0, -44)
	var p: Vector2 = G.main.get_viewport().get_canvas_transform() * at
	return p.clamp(Vector2(BUBBLE_R + 2.0, BUBBLE_R + 2.0), VIEW - Vector2(BUBBLE_R + 2.0, BUBBLE_R + 2.0))


func _notification(what: int) -> void:
	# a call or the home button must not leave the stick held down
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release_all()


func _draw() -> void:
	if editing:
		_draw_edit()
		return
	if not active or paused or blocked:
		return
	modulate.a = clampf(see, 0.3, 1.0)
	var boost := maxf(1.0, see)      # past 1.0 the fills themselves get more solid
	# the stick: faint at rest, solid under the thumb
	var base := _origin if _stick_id >= 0 else rest
	var a := (0.38 if _stick_id >= 0 else 0.13) * boost
	draw_circle(base, STICK_R, Color(0.03, 0.04, 0.07, a))
	draw_arc(base, STICK_R, 0.0, TAU, 32, Color(0.55, 0.9, 1.0, a + 0.15), 1.5)
	var knob := base + _vec * STICK_R if _stick_id >= 0 else base
	draw_circle(knob, KNOB_R, Color(0.55, 0.9, 1.0, 0.22 if _stick_id < 0 else 0.55))
	draw_arc(knob, KNOB_R, 0.0, TAU, 24, Color(0.8, 1.0, 1.0, 0.5), 1.0)
	# the cluster
	for b in BTN:
		var on: bool = _down.has(b["id"])
		draw_circle(b["pos"], float(b["r"]), Color(0.55, 0.9, 1.0, 0.55) if on else Color(0.05, 0.07, 0.12, minf(0.95, 0.55 * boost)))
		draw_arc(b["pos"], float(b["r"]), 0.0, TAU, 28, Color(0.55, 0.9, 1.0, 0.7 if on else 0.35), 1.2)
		if b["id"] == "pause":
			draw_rect(Rect2(b["pos"] + Vector2(-3, -4), Vector2(2, 8)), Color(1, 1, 1, 0.85))
			draw_rect(Rect2(b["pos"] + Vector2(1, -4), Vector2(2, 8)), Color(1, 1, 1, 0.85))
		elif String(b["label"]) != "":
			_text_centered(String(b["label"]), b["pos"], int(b["size"]), Color(1, 1, 1, 0.85))
	# the save terminal's floating bubble
	if _bubble_on:
		draw_circle(_bubble_pos, BUBBLE_R, Color(0.05, 0.25, 0.25, 0.72))
		draw_arc(_bubble_pos, BUBBLE_R, 0.0, TAU, 28, Color(0.6, 1.0, 1.0, 0.9), 1.5)
		_text_centered("CACHE", _bubble_pos, 7, Color(0.85, 1.0, 1.0))


func _text_centered(text: String, at: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, at + Vector2(-w / 2.0, font_size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_edit() -> void:
	modulate.a = 1.0
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.02, 0.02, 0.05, 0.55))
	_text_centered("drag a control to move it  -  tap one, then SMALLER / BIGGER", Vector2(192, 34), 7, Color(0.85, 1.0, 1.0))
	draw_line(Vector2(ZONE_X, 44), Vector2(ZONE_X, VIEW.y), Color(0.55, 0.9, 1.0, 0.2), 1.0)
	_text_centered("the stick works anywhere left of this line", Vector2(ZONE_X * 0.5, 50), 6, Color(0.7, 0.9, 1.0, 0.7))
	var picked := _edit_pick == "stick"
	draw_circle(rest, STICK_R, Color(0.03, 0.04, 0.07, 0.6))
	draw_arc(rest, STICK_R, 0.0, TAU, 32, Color(1.0, 0.9, 0.3) if picked else Color(0.55, 0.9, 1.0, 0.7), 2.0 if picked else 1.2)
	draw_circle(rest, KNOB_R, Color(0.55, 0.9, 1.0, 0.5))
	_text_centered("STICK", rest + Vector2(0, STICK_R + 6.0), 6, Color(1, 1, 1, 0.8))
	for b in BTN:
		picked = _edit_pick == b["id"]
		draw_circle(b["pos"], float(b["r"]), Color(0.05, 0.07, 0.12, 0.8))
		draw_arc(b["pos"], float(b["r"]), 0.0, TAU, 28, Color(1.0, 0.9, 0.3) if picked else Color(0.55, 0.9, 1.0, 0.7), 2.0 if picked else 1.2)
		_text_centered(String(b["label"]) if String(b["label"]) != "" else "II", b["pos"], int(b["size"]), Color(1, 1, 1, 0.9))
