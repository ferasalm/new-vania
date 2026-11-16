# PROTOTYPE - NOT FOR PRODUCTION
# The touch rig for Android: a floating stick in the left 42% of the screen and
# a button cluster on the right. It feeds the same InputMap actions the keyboard
# uses (game.gd), so player.gd, main.gd, enemy.gd and boss.gd do not know it
# exists. Follows design/gdd/input-control-mapping.md where the prototype has
# the verb: stick left 42%, crouch is the stick's down-zone (25 deg entry /
# 45 deg exit, 90 ms hold guard), attack is the largest and innermost button,
# jump sits above it, backdash is double-tap-back on the stick, and a small BACK
# button is the a11y direct press. The save terminal gets a world-anchored bubble.
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

const BTN := [
	{"id": "attack", "pos": Vector2(330, 152), "r": 26.0, "label": "ATTACK", "size": 8},
	{"id": "jump", "pos": Vector2(357, 98), "r": 22.0, "label": "JUMP", "size": 8},
	{"id": "special", "pos": Vector2(282, 190), "r": 17.0, "label": "SPEC", "size": 7},
	{"id": "swap", "pos": Vector2(238, 190), "r": 14.0, "label": "SWAP", "size": 6},
	{"id": "backdash", "pos": Vector2(272, 128), "r": 14.0, "label": "BACK", "size": 6},
	{"id": "pause", "pos": Vector2(366, 14), "r": 10.0, "label": "", "size": 6},
]
const ROOM_LABELS := {"church": "CHURCH", "library": "LIBRARY", "save": "CACHE", "lab": "LAB", "boss": "BOSS"}

var active := false
var paused := false

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
	set_process_input(active)
	_build_menu()
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
	_menu_button(col, "RESUME", _resume)
	_menu_button(col, "RESTART", _restart)
	for room in ROOM_LABELS:
		_menu_button(col, ROOM_LABELS[room], _goto_room.bind(room))


func _menu_button(col: VBoxContainer, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(132, 17)
	b.add_theme_font_size_override("font_size", 9)
	b.pressed.connect(cb)
	col.add_child(b)


func _input(event: InputEvent) -> void:
	if not active or paused:
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
		_origin = pos.clamp(Vector2(STICK_R + 4.0, STICK_R + 4.0), VIEW - Vector2(STICK_R + 4.0, STICK_R + 4.0))
		_vec = Vector2.ZERO
		_crouch_t = 0.0
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
		_tap("backdash")
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
		"backdash":
			_tap("backdash")
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
	for a in ["left", "right", "down", "jump", "attack", "attack2", "up", "backdash", "swap"]:
		Input.action_release(a)
	_stick_id = -1
	_vec = Vector2.ZERO
	_crouch_on = false
	_crouch_t = 0.0
	_bind.clear()
	_down.clear()


func _pause() -> void:
	_release_all()
	paused = true
	_overlay.visible = true
	get_tree().paused = true
	queue_redraw()


func _resume() -> void:
	_overlay.visible = false
	get_tree().paused = false
	paused = false
	queue_redraw()


func _restart() -> void:
	if G.main == null or G.main._busy:
		return
	_resume()
	G.main.player.hp = 0.0
	G.main.enter("save" if G.main.saved else "church", "M" if G.main.saved else "P")


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
	if not active or paused:
		return
	# the stick: faint at rest, solid under the thumb
	var base := _origin if _stick_id >= 0 else REST
	var a := 0.38 if _stick_id >= 0 else 0.13
	draw_circle(base, STICK_R, Color(0.03, 0.04, 0.07, a))
	draw_arc(base, STICK_R, 0.0, TAU, 32, Color(0.55, 0.9, 1.0, a + 0.15), 1.5)
	var knob := base + _vec * STICK_R if _stick_id >= 0 else base
	draw_circle(knob, KNOB_R, Color(0.55, 0.9, 1.0, 0.22 if _stick_id < 0 else 0.55))
	draw_arc(knob, KNOB_R, 0.0, TAU, 24, Color(0.8, 1.0, 1.0, 0.5), 1.0)
	# the cluster
	for b in BTN:
		var on: bool = _down.has(b["id"])
		draw_circle(b["pos"], float(b["r"]), Color(0.55, 0.9, 1.0, 0.55) if on else Color(0.05, 0.07, 0.12, 0.55))
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
