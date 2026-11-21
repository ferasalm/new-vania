# PROTOTYPE - NOT FOR PRODUCTION
# tests_dev/d18_lever_hallway.gd - the user's two F4 notes of 2026-11-21:
#   1. library: "lever is not working" (Up beside the lever in the user's 2-cell Library)
#   2. hallway: "took 40 damage when I got here from below"
# Run: godot --headless --path . res://tests_dev/d18_lever_hallway.tscn
extends Node

const Props := preload("res://props.gd")

var main: Node = null
var passed := 0
var failed := 0


func _ready() -> void:
	G.peace = true
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _frames(30)
	await _lever_checks()
	await _hallway_checks()
	var ok := failed == 0 and passed > 0
	print("d18_lever_hallway %s %d/%d" % ["PASS" if ok else "FAIL", passed, passed + failed])
	get_tree().quit(0 if ok else 1)


func _check(nm: String, ok: bool, detail: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("%s  %s  (%s)" % ["ok  " if ok else "FAIL", nm, detail])


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _lever() -> Node2D:
	for pr in main.room.props:
		if pr is Props.Lever and pr.kind == "library":
			return pr
	return null


func _lever_checks() -> void:
	W.set_flag("lever_library", false)
	await main.debug_enter("library", "left", false)
	await _frames(20)
	var lv := _lever()
	_check("the library has its lever", lv != null, "props=%d" % main.room.props.size())
	if lv == null:
		return
	var pl: Node2D = main.player
	# stand where the user stood: just right of the lever, on the same floor
	pl.global_position = lv.global_position + Vector2(12, 0)
	pl.velocity = Vector2.ZERO
	await _frames(20)
	var near: Dictionary = main.interact.nearest()
	print("  lever at %s, her at %s, dist %.1f, targets %d, nearest=%s, on_floor=%s" % [
		str(lv.global_position), str(pl.global_position), pl.global_position.distance_to(lv.global_position),
		main.interact.targets.size(), str(near.get("kind", "-")), str(pl.is_on_floor())])
	_check("standing beside the lever, Up reaches it", near.get("node") == lv, "nearest=%s" % str(near.get("kind", "none")))
	Input.action_press("up")
	await _frames(4)
	Input.action_release("up")
	await _frames(20)
	_check("Up pulls the library lever", lv.pulled and W.flag("lever_library"),
		"pulled=%s flag=%s" % [str(lv.pulled), str(W.flag("lever_library"))])
	var said: String = main.hud.get("_toast").text
	_check("the pull stays a mystery: no message names the door", not said.contains("DOOR"), "toast=%s" % said)
	# the door it opens: the church's lower door to the Marrow Well must now be unlocked
	await main.debug_enter("church", "right", false)
	await _frames(10)
	var shaft_door = null
	for d in main.room.doors_all:
		if String(d.to) == "shaft":
			shaft_door = d
	_check("after the pull the church door to the Marrow Well is open", shaft_door != null and not shaft_door.locked,
		"door=%s locked=%s" % [str(shaft_door != null), str(shaft_door.locked if shaft_door != null else "-")])
	await _touch_lever_check()


# the user's PC has a touchscreen, so the touch layer is on and the bubble is the way to use things
func _touch_lever_check() -> void:
	W.set_flag("lever_library", false)
	await main.debug_enter("library", "left", false)
	await _frames(20)
	var lv := _lever()
	var tc: Node = main.touch
	if lv == null or tc == null:
		_check("touch: lever and touch layer exist", false, "lever=%s touch=%s" % [str(lv), str(tc)])
		return
	tc.active = true
	tc.visible = true
	tc.set_process(true)
	main.player.global_position = lv.global_position + Vector2(12, 0)
	main.player.velocity = Vector2.ZERO
	await _frames(20)
	var bubble_on: bool = tc.get("_bubble_on")
	var bpos: Vector2 = tc.get("_bubble_pos")
	print("  touch bubble on=%s at %s label=%s" % [str(bubble_on), str(bpos), str(tc.get("_bubble_label"))])
	_check("touch: the bubble shows beside the lever", bubble_on, "on=%s" % str(bubble_on))
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.position = bpos
	ev.pressed = true
	tc._input(ev)
	await _frames(3)
	ev = ev.duplicate()
	ev.pressed = false
	tc._input(ev)
	await _frames(20)
	_check("touch: tapping the bubble pulls the lever", lv.pulled and W.flag("lever_library"),
		"pulled=%s flag=%s" % [str(lv.pulled), str(W.flag("lever_library"))])
	tc.active = false
	tc.visible = false
	tc.set_process(false)


var _hits: Array = []


# The real cause: on the frame she leaves the Gallery, its crushers still run once and test the
# NEW Pandora (in the hallway) at the same coordinates. Recreate that frame on purpose.
func _old_room_trap_check() -> void:
	await main.debug_enter("gallery", "left", false)
	await _frames(10)
	var hz: Node2D = null
	for c in main.world.get_children():
		if c.get("kind") == "crusher":
			hz = c
			break
	if hz == null:
		_check("the Gallery has a crusher", false, "none")
		return
	var pl: Node2D = main.player
	pl.invuln = 9999.0      # the old Pandora must not be the one hit
	var probe := Rect2()
	var down := false
	for i in 900:
		await _frames(1)
		if hz.dangerous():
			var blk: Rect2 = hz._block_rect()
			var sz: Vector2 = pl.body_rect().size
			probe = Rect2(blk.get_center() - sz / 2.0, sz)
			down = hz.hits(probe)
			if down:
				break
	_check("the Gallery crusher comes down", down, "never hit a probe")
	if not down:
		return
	_hits.clear()
	main.enter("hallway", "hole_down", "gallery")      # the same frame, like _vertical does
	var np: Node2D = main.player
	np.invuln = 0.0
	np.global_position += probe.position - np.body_rect().position
	await _frames(3)
	_check("a trap in the room she just left cannot hit her in the new room", _hits.is_empty(), "hits=%s" % str(_hits))


func _on_hurt(dmg: int, src: String) -> void:
	_hits.append("%d from %s in %s at %s" % [dmg, src, main.room_name, str(main.player.global_position.round())])


# the user came up from the Gallery through its top-left hole and arrived with 40 less health
func _hallway_checks() -> void:
	G.peace = false
	W.player_hurt.connect(_on_hurt)
	await main.debug_enter("gallery", "left", false)
	await _frames(10)
	var pl: Node2D = main.player
	pl.hp = R.max_hp()
	pl.global_position = main.room.spawns["hole_up"] + Vector2(0, 40)
	pl.velocity = Vector2(0, -600)
	var arrived := false
	var rooms: Array = []
	for i in 300:
		await _frames(1)
		if rooms.is_empty() or rooms.back() != main.room_name:
			rooms.append(main.room_name)
		if main.room_name == "hallway":
			arrived = true
		if i == 120 and arrived:
			break
	pl = main.player
	print("  rooms visited: %s, hp %.0f/%.0f, at %s" % [str(rooms), pl.hp, R.max_hp(), str(pl.global_position.round())])
	for h in _hits:
		print("  hit: " + h)
	_check("up from the Gallery she reaches the hallway", arrived, "rooms=%s" % str(rooms))
	_check("arriving in the hallway from below costs no health", _hits.is_empty(), "hits=%s" % str(_hits))
	# then she stands in the hallway for two seconds where the user stood
	_hits.clear()
	await _frames(120)
	_check("standing in the hallway after arriving costs no health", _hits.is_empty(), "hits=%s" % str(_hits))
	await _old_room_trap_check()
	W.player_hurt.disconnect(_on_hurt)
	G.peace = true
	# the F4 note now lists the last hits, so the next "I lost health here" says where from
	main.player.invuln = 0.0
	main.player.take_hit(20.0, main.player.global_position.x + 10.0, "trap")
	var log_text: String = Dev.recent_hits_text()
	_check("the F4 note's hit log names the hit, its source and room", log_text.contains("from trap in hallway"), log_text)
