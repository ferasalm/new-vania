# PROTOTYPE - NOT FOR PRODUCTION
# Helper 2's screen checks: the HUD at 384x216 (nothing overlaps, nothing runs off the
# screen), the SYSTEM OFFLINE screen, the pause menu and the Pause > CONTROLS editor,
# all driven by pretend fingers (InputEventScreenTouch / Drag through Input, the same
# road a real finger takes). Pictures go to shots/h2_<mode>_<name>.png.
#   pictures:  godot --path prototypes/feel-v3 res://shot_h2.tscn -- shots touch layout=h2_test.json
#   no window: godot --headless --fixed-fps 60 --path prototypes/feel-v3 res://shot_h2.tscn -- touch layout=h2_test.json
#   then the same line again with  phase=2  added: a NEW run reads the saved layout back.
# Always pass layout=<file>: the test then never touches the player's own touch_layout.json.
extends Node

const VIEW := Vector2(384, 216)

var main: Node
var passed := 0
var failed := 0
var shots := false
var tag := "key"
var xf := Transform2D.IDENTITY     # game picture -> window pixels (pretend fingers land in window pixels)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	shots = args.has("shots")
	tag = "touch" if args.has("touch") else "key"
	G.peace = true
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _frames(40)
	xf = get_viewport().get_final_transform()
	print("window %s, picture -> window scale %.2f, touch layout file %s" % [str(get_window().size), xf.get_scale().x, main.touch.layout_file])
	if main.touch.layout_file == main.touch.LAYOUT_FILE:
		print("H2 FAIL  (pass layout=<name>.json so the player's own layout file is left alone)")
		get_tree().quit(1)
		return
	if args.has("phase=2"):
		await _phase2()
	else:
		await _phase1()
	print("H2 %s  passed=%d failed=%d" % ["PASS" if failed == 0 else "FAIL", passed, failed])
	get_tree().quit(0 if failed == 0 else 1)


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("%s  %s  (%s)" % ["ok  " if ok else "FAIL", name, detail])


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _wait(n: int) -> void:
	# works while the game is paused too
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	if not shots:
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://shots"))
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://shots/h2_%s_%s.png" % [tag, name]))


func _finger(pos: Vector2, pressed: bool, idx: int = 0) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = idx
	ev.position = xf * pos
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _tap_at(pos: Vector2) -> void:
	_finger(pos, true)
	await _wait(4)
	_finger(pos, false)
	await _wait(4)


func _drag(from: Vector2, to: Vector2) -> void:
	_finger(from, true)
	await _wait(2)
	var last := from
	for i in 8:
		var at := from.lerp(to, float(i + 1) / 8.0)
		var ev := InputEventScreenDrag.new()
		ev.index = 0
		ev.position = xf * at
		ev.relative = xf.basis_xform(at - last)
		Input.parse_input_event(ev)
		last = at
		await _wait(1)
	_finger(to, false)
	await _wait(3)


func _button(root: Node, text: String) -> Button:
	for c in root.get_children():
		if c is Button and (c.text == text or c.text.begins_with(text)):
			return c
		var b := _button(c, text)
		if b != null:
			return b
	return null


func _press(root: Node, text: String) -> bool:
	# a finger tap in the middle of the button with this text
	var b := _button(root, text)
	if b == null or not b.is_visible_in_tree():
		print("      no visible button '%s'" % text)
		return false
	await _tap_at(b.get_global_rect().get_center())
	return true


func _goto(room_name: String, key: String) -> void:
	main.player.hp = 0.0
	main.enter(room_name, key)
	await _frames(30)


# ---- the HUD: what is on screen, as boxes ----

func _text_box(l: Label) -> Rect2:
	var sz := l.get_minimum_size()
	var x := l.position.x
	if l.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and l.size.x > sz.x:
		x += (l.size.x - sz.x) / 2.0
	if l.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and l.size.x < sz.x:
		x -= (sz.x - l.size.x) / 2.0
	return Rect2(Vector2(x, l.position.y + 2.0), Vector2(sz.x, sz.y - 4.0))     # the letters, without the line padding


func _hud_boxes() -> Dictionary:
	var h = main.hud
	var out := {}
	out["name"] = _text_box(h._name)
	for n in h._back:
		out["bar " + n] = Rect2(h._back[n].position, h._back[n].size)
	out["defeated"] = _text_box(h._kills)
	out["weapon"] = _text_box(h._weapon)
	if h._banner.modulate.a > 0.05 and h._banner.text != "":
		out["area name"] = _text_box(h._banner)
	if h._toast.modulate.a > 0.05 and h._toast.text != "":
		out["message"] = _text_box(h._toast)
	if h._prompt.text != "":
		out["prompt"] = _text_box(h._prompt)
	if h._boss_name.visible:
		out["boss name"] = _text_box(h._boss_name)
		out["boss bar"] = Rect2(h._boss_back.position, h._boss_back.size)
	if h._hint.visible:
		out["key hint"] = _text_box(h._hint)
	var t = main.touch
	if t.active:
		for b in t.BTN:
			var r := float(b["r"])
			out["touch " + b["id"]] = Rect2(b["pos"] - Vector2(r, r), Vector2(r, r) * 2.0)
		out["touch stick"] = Rect2(t.rest - Vector2(t.STICK_R, t.STICK_R), Vector2(t.STICK_R, t.STICK_R) * 2.0)
		if t._bubble_on:
			out["touch cache bubble"] = Rect2(t._bubble_pos - Vector2(t.BUBBLE_R, t.BUBBLE_R), Vector2(t.BUBBLE_R, t.BUBBLE_R) * 2.0)
	return out


func _hud_check(where: String) -> void:
	var boxes := _hud_boxes()
	var keys := boxes.keys()
	var bad: Array = []
	var off: Array = []
	for i in keys.size():
		var a: Rect2 = boxes[keys[i]]
		if a.position.x < 0.0 or a.position.y < 0.0 or a.end.x > VIEW.x or a.end.y > VIEW.y:
			off.append("%s %s" % [keys[i], str(Rect2i(a))])
		for j in range(i + 1, keys.size()):
			var b: Rect2 = boxes[keys[j]]
			if keys[i].begins_with("touch ") and keys[j].begins_with("touch "):
				# two round controls: they overlap when the middles are closer than the two radii
				if a.get_center().distance_to(b.get_center()) < (a.size.x + b.size.x) / 2.0 - 0.5:
					bad.append("%s x %s" % [keys[i], keys[j]])
			elif a.intersects(b):
				bad.append("%s x %s" % [keys[i], keys[j]])
	_check("HUD %s: nothing overlaps" % where, bad.is_empty(), "%d boxes; %s" % [keys.size(), "none" if bad.is_empty() else ", ".join(bad)])
	var widest := ""
	if boxes.has("message"):
		widest = "; message is %.0f px wide" % boxes["message"].size.x
	_check("HUD %s: nothing runs off the screen" % where, off.is_empty(), ("none" if off.is_empty() else ", ".join(off)) + widest)


# ---- first run ----

func _phase1() -> void:
	var p: CharacterBody2D = main.player
	var t = main.touch
	T.set_v("weapon", 1.0)      # the longer weapon name
	await _frames(4)
	await _hud_check("church, area name showing")
	await _shot("hud_church")

	await _goto("lab", "left")
	p = main.player
	p.global_position = main.room.spawns["A"]
	await _frames(20)
	await _hud_check("lab, the long relic message")
	await _shot("hud_relic_message")

	await _goto("boss", "left")
	p = main.player
	p.global_position.x = 120.0
	await _frames(100)
	main.hud.toast("PANDORA-002 RECONSTRUCTED", 3.0)
	await _frames(4)
	await _hud_check("boss fight, boss bar + a message")
	await _shot("hud_boss")

	await _goto("save", "left")
	p = main.player
	p.global_position.x = main.room.spawns["M"].x
	await _frames(20)
	await _hud_check("save room at the terminal")
	await _shot("hud_save")
	Input.action_press("up")
	await _frames(2)
	Input.action_release("up")
	await _frames(6)
	await _hud_check("save room, MEMORY CACHED")

	# a finger really drives the game (only when the touch rig is on)
	if t.active:
		p.global_position.x = main.room.spawns["M"].x + 80.0
		await _frames(10)
		var x0 := p.global_position.x
		_finger(Vector2(60, 150), true, 1)
		await _wait(2)
		var ev := InputEventScreenDrag.new()
		ev.index = 1
		ev.position = xf * Vector2(88, 150)
		Input.parse_input_event(ev)
		await _frames(20)
		_check("a finger on the stick walks her", p.global_position.x > x0 + 20.0, "moved %.0f px" % (p.global_position.x - x0))
		_finger(Vector2(88, 150), false, 1)
		await _frames(6)
		_finger(Vector2(286, 152), true, 2)
		await _frames(4)
		_check("a finger on ATK swings", p.state == "attack", "state=%s" % p.state)
		_finger(Vector2(286, 152), false, 2)
		await _frames(50)

	# SYSTEM OFFLINE
	G.peace = false
	p.invuln = 0.0
	p.take_hit(9999.0, 0.0)
	await _frames(130)
	_check("death shows SYSTEM OFFLINE and takes the fingers away from the game", main.offline.active and main.offline.visible and t.blocked, "")
	var title: Rect2 = _text_box(main.offline._title)
	var b0: Button = main.offline._btns[0]
	var b1: Button = main.offline._btns[1]
	var centred: bool = absf(b0.get_global_rect().get_center().x - 192.0) < 1.5 and absf(b1.get_global_rect().get_center().x - 192.0) < 1.5
	_check("OFFLINE: title and both buttons are centred and on screen", centred and absf(title.get_center().x - 192.0) < 4.0
		and b1.get_global_rect().end.y <= 216.0 and not b0.get_global_rect().intersects(b1.get_global_rect())
		and not _text_box(main.offline._sub).intersects(b0.get_global_rect()),
		"title %s  buttons %s %s" % [str(Rect2i(title)), str(Rect2i(b0.get_global_rect())), str(Rect2i(b1.get_global_rect()))])
	await _shot("offline")
	Input.action_press("down")
	await _wait(3)
	Input.action_release("down")
	await _wait(3)
	_check("OFFLINE: Down moves to QUIT", main.offline._pick == 1, "pick=%d" % main.offline._pick)
	await _shot("offline_quit")
	# a finger on RECONSTRUCT picks it, whatever the keys had selected
	await _tap_at(b0.get_global_rect().get_center())
	await _frames(200)
	G.peace = true
	p = main.player
	_check("OFFLINE: a finger on RECONSTRUCT rebuilds her", main.room_name == "save" and not main.offline.visible and main.unit == 2 and not t.blocked,
		"room=%s unit=%d" % [main.room_name, main.unit])
	await _frames(60)
	await _hud_check("after the rebuild")
	await _shot("rebuilt")

	# the pause menu
	if t.active:
		await _tap_at(Vector2(366, 14))
	else:
		t.toggle_pause()
		await _wait(3)
	_check("pause opens (the corner button on a phone)", get_tree().paused and t._overlay.visible, "paused=%s" % str(get_tree().paused))
	var worst := Rect2()
	var count := 0
	var inside := true
	for b in _all_buttons(t._overlay):
		count += 1
		var r: Rect2 = b.get_global_rect()
		inside = inside and r.position.y >= 0.0 and r.end.y <= 216.0 and r.position.x >= 0.0 and r.end.x <= 384.0
		if r.end.y > worst.end.y:
			worst = r
	_check("pause menu: every button is on the screen", inside, "%d buttons, lowest ends at y=%.0f of 216" % [count, worst.end.y])
	await _shot("pause")

	# Pause > CONTROLS
	await _press(t._overlay, "CONTROLS")
	_check("CONTROLS opens the editor", t.editing and t._edit_bar.visible and not t._overlay.visible, "")
	inside = true
	var bar_end := 0.0
	for b in _all_buttons(t._edit_bar):
		var r: Rect2 = b.get_global_rect()
		inside = inside and r.position.x >= 0.0 and r.end.x <= 384.0
		bar_end = maxf(bar_end, r.end.x)
	_check("editor: the button row fits the screen", inside, "row ends at x=%.0f of 384" % bar_end)
	await _shot("edit_open")
	await _drag(Vector2(286, 152), Vector2(200, 100))
	_check("editor: dragging ATK moves it", _btn(t, "attack")["pos"].distance_to(Vector2(200, 100)) < 1.0 and t._edit_pick == "attack", "pos=%s" % str(_btn(t, "attack")["pos"]))
	await _press(t._edit_bar, "BIGGER")
	await _press(t._edit_bar, "BIGGER")
	await _press(t._edit_bar, "SMALLER")
	_check("editor: BIGGER twice, SMALLER once resizes ATK 20 -> 22", is_equal_approx(_btn(t, "attack")["r"], 22.0), "r=%.0f" % _btn(t, "attack")["r"])
	await _tap_at(Vector2(322, 184))
	await _press(t._edit_bar, "SMALLER")
	_check("editor: a tap picks JUMP, SMALLER shrinks only it", t._edit_pick == "jump" and is_equal_approx(_btn(t, "jump")["r"], 18.0)
		and is_equal_approx(_btn(t, "attack")["r"], 22.0) and _btn(t, "jump")["pos"] == Vector2(322, 184), "pick=%s r=%.0f" % [t._edit_pick, _btn(t, "jump")["r"]])
	await _drag(Vector2(64, 150), Vector2(100, 120))
	_check("editor: dragging the stick moves where it rests", t.rest.distance_to(Vector2(100, 120)) < 1.0 and t._edit_pick == "stick", "rest=%s" % str(t.rest))
	var r_before: float = _btn(t, "jump")["r"]
	await _press(t._edit_bar, "BIGGER")
	_check("editor: with the stick picked, BIGGER changes nothing (the stick has one size)", is_equal_approx(_btn(t, "jump")["r"], r_before), "")
	await _drag(Vector2(366, 14), Vector2(300, 60))
	_check("editor: the pause button can be dragged too", _btn(t, "pause")["pos"].distance_to(Vector2(300, 60)) < 1.0, "pos=%s" % str(_btn(t, "pause")["pos"]))
	await _drag(Vector2(366, 172), Vector2(500, 300))
	_check("editor: a control dragged past the corner stays whole on the screen", _btn(t, "backdash_right")["pos"] == Vector2(369, 201), "pos=%s" % str(_btn(t, "backdash_right")["pos"]))
	await _press(t._edit_bar, "FAINTER")
	await _press(t._edit_bar, "FAINTER")
	_check("editor: FAINTER twice fades 1.00 -> 0.70", is_equal_approx(t.see, 0.7), "see=%.2f" % t.see)
	await _press(t._edit_bar, "STICK")
	_check("editor: the stick button switches to FIXED", t.fixed_stick and t._stick_label.text == "STICK: FIXED", t._stick_label.text)
	await _shot("edit_changed")
	_check("editor: nothing is written before DONE", not FileAccess.file_exists(t.layout_file), t.layout_file)
	await _press(t._edit_bar, "DONE")
	_check("editor: DONE saves the layout and goes back to the pause menu", FileAccess.file_exists(t.layout_file) and not t.editing and t._overlay.visible,
		FileAccess.get_file_as_string(t.layout_file).left(150))
	await _shot("pause_after_edit")
	await _press(t._overlay, "RESUME")
	_check("RESUME goes back to the game", not get_tree().paused and not t.paused, "")
	await _frames(10)
	if t.active:
		await _hud_check("the player's own layout in play")
		await _shot("play_own_layout")


func _btn(t, id: String) -> Dictionary:
	for b in t.BTN:
		if b["id"] == id:
			return b
	return {}


func _all_buttons(root: Node) -> Array:
	var out: Array = []
	for c in root.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_all_buttons(c))
	return out


# ---- second run: a new process reads the file back ----

func _phase2() -> void:
	var p: CharacterBody2D = main.player
	var t = main.touch
	_check("restart: the saved layout file is read back", _btn(t, "attack")["pos"] == Vector2(200, 100) and is_equal_approx(_btn(t, "attack")["r"], 22.0)
		and is_equal_approx(_btn(t, "jump")["r"], 18.0) and t.rest == Vector2(100, 120) and t.fixed_stick and is_equal_approx(t.see, 0.7)
		and _btn(t, "pause")["pos"] == Vector2(300, 60) and _btn(t, "backdash_right")["pos"] == Vector2(369, 201),
		"ATK %s r=%.0f  stick %s fixed=%s see=%.2f" % [str(_btn(t, "attack")["pos"]), _btn(t, "attack")["r"], str(t.rest), str(t.fixed_stick), t.see])
	await _shot("restart_play")
	if t.active:
		# the moved controls are the ones that work now
		_finger(Vector2(286, 152), true, 2)
		await _frames(4)
		_check("restart: the old ATK place does nothing", p.state != "attack", "state=%s" % p.state)
		_finger(Vector2(286, 152), false, 2)
		await _frames(4)
		_finger(Vector2(200, 100), true, 2)
		await _frames(4)
		_check("restart: the new ATK place swings", p.state == "attack", "state=%s" % p.state)
		_finger(Vector2(200, 100), false, 2)
		await _frames(50)
		var x0 := p.global_position.x
		_finger(Vector2(124, 120), true, 1)      # fixed stick: a touch right of its middle walks right at once
		await _frames(20)
		_check("restart: the fixed stick answers the first touch", p.global_position.x > x0 + 20.0 and t._origin == Vector2(100, 120),
			"moved %.0f px, stick middle %s" % [p.global_position.x - x0, str(t._origin)])
		_finger(Vector2(124, 120), false, 1)
		await _frames(6)
		await _tap_at(Vector2(300, 60))
		_check("restart: the moved pause button pauses", get_tree().paused, "")
	else:
		t.toggle_pause()
		await _wait(3)
	await _press(t._overlay, "CONTROLS")
	await _shot("edit_restart")
	await _press(t._edit_bar, "RESET")
	_check("RESET puts everything back and removes the file", _btn(t, "attack")["pos"] == Vector2(286, 152) and is_equal_approx(_btn(t, "attack")["r"], 20.0)
		and t.rest == Vector2(64, 150) and not t.fixed_stick and is_equal_approx(t.see, 1.0) and _btn(t, "pause")["pos"] == Vector2(366, 14)
		and t._stick_label.text == "STICK: FLOATS" and not FileAccess.file_exists(t.layout_file), "file there=%s" % str(FileAccess.file_exists(t.layout_file)))
	await _shot("edit_reset")
	await _press(t._edit_bar, "DONE")
	await _press(t._overlay, "RESUME")
	_check("after RESET and DONE the game runs again", not get_tree().paused, "")
	# the test's own layout file is removed again
	if FileAccess.file_exists(t.layout_file):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(t.layout_file))
