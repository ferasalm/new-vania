# PROTOTYPE - NOT FOR PRODUCTION
# The interact system: the Up key. S0 carries the registration seam (register /
# nearest / press / used) and today's terminal, lever and time-machine code,
# moved here unchanged. S2 replaces the body with the real pickup handling.
extends Node

signal used(kind: String, node: Node2D)

const Props := preload("res://props.gd")

var targets: Array = []     # {node, kind, label, cb, reach}


func _ready() -> void:
	W.room_entered.connect(_on_room_entered)


func register(node: Node2D, kind: String, label: String, cb: Callable, reach := 0.0) -> void:
	# make a thing in the room reachable with Up; a reach of 0 uses pickup_reach later
	unregister(node)
	targets.append({"node": node, "kind": kind, "label": label, "cb": cb, "reach": reach})


func unregister(node: Node2D) -> void:
	# forget a thing (it was taken, used or freed)
	targets = targets.filter(func(t): return is_instance_valid(t["node"]) and t["node"] != node)


func nearest() -> Dictionary:
	# the closest registered target in reach: {node, kind, label, pos}, or {}
	var m: Node = G.main
	if m == null or m.player == null:
		return {}
	var p: Vector2 = m.player.global_position
	var best := {}
	var best_d := INF
	for t in targets:
		if not is_instance_valid(t["node"]):
			continue
		var reach := float(t["reach"]) if float(t["reach"]) > 0.0 else 24.0
		var d: float = p.distance_to(t["node"].global_position)
		if d <= reach and d < best_d:
			best_d = d
			best = {"node": t["node"], "kind": t["kind"], "label": t["label"], "pos": t["node"].global_position}
	return best


func press() -> bool:
	# use the nearest registered target; false when there is nothing in reach
	var n := nearest()
	if n.is_empty():
		return false
	var t := _find(n["node"])
	if t.is_empty():
		return false
	if t["cb"] is Callable and t["cb"].is_valid():
		t["cb"].call()
	used.emit(String(n["kind"]), n["node"])
	return true


func _find(node: Node2D) -> Dictionary:
	for t in targets:
		if t["node"] == node:
			return t
	return {}


func _on_room_entered(_file_id: String) -> void:
	# the targets of the old room are gone
	targets.clear()


func tick() -> void:
	# today's Up targets: the save terminal, the time machine and the library lever
	_terminal()
	_machine()
	_levers()


func interact_target() -> Dictionary:
	# what the touch bubble points at: {"pos": world position, "label": text}, or {} when nothing is near
	var m: Node = G.main
	if m == null or m.room == null or m.player == null:
		return {}
	var room: Node2D = m.room
	var player: Node2D = m.player
	var feet: Vector2 = player.global_position
	if room.spawns.has("M") and absf(feet.x - room.spawns["M"].x) < 30.0 and player.is_on_floor():
		return {"pos": room.spawns["M"] + Vector2(0, -44), "label": "NO SIGNAL" if G.shifted else "CACHE"}
	if room.spawns.has("T") and absf(feet.x - room.spawns["T"].x) < 34.0 and player.is_on_floor() and not G.shifted:
		return {"pos": room.spawns["T"] + Vector2(0, -80), "label": "MACHINE"}
	for pr in room.props:
		if pr is Props.Lever and pr.kind == "library" and not pr.pulled and _near_lever(pr):
			return {"pos": pr.global_position + Vector2(0, -34), "label": "LEVER"}
	return {}


func _near_lever(pr: Node2D) -> bool:
	var player: Node2D = G.main.player
	var d: Vector2 = player.global_position - pr.global_position
	return absf(d.x) < T.v("lever_reach") and absf(d.y) < 26.0


func _terminal() -> void:
	# the save room: stand at the terminal and press Up
	var m: Node = G.main
	var room: Node2D = m.room
	var player: Node2D = m.player
	if not room.spawns.has("M"):
		return
	var near: bool = absf(player.global_position.x - room.spawns["M"].x) < 30.0 and player.is_on_floor()
	var touch_on: bool = m.touch != null and m.touch.active
	m.hud.prompt("" if touch_on else (("NO SIGNAL" if G.shifted else "W: cache memory (heal and save)") if near else ""))
	if near and Input.is_action_just_pressed("up") and player.state == "move" and G.shifted:
		# after the shift every cache station is dead: no heal, no save
		Sfx.play_file("sfx/shift/dead_terminal.wav", -4.0)
		m.hud.toast("NO SIGNAL")
		return
	if near and Input.is_action_just_pressed("up") and player.state == "move":
		m.saved = true
		m.saved_room = m.room_name
		player.hp = R.max_hp()
		player.mp = R.max_mp()
		Sfx.play("pickup", 0.7)
		Sfx.play("special", 0.6)
		m.ring_fx(room.spawns["M"] + Vector2(0, -40), 70.0, Color(0.5, 1.0, 1.0))
		m.hud.toast("MEMORY CACHED")


func _levers() -> void:
	# the library lever: stand next to it and press Up (a cut pulls it too, see player_cut)
	var m: Node = G.main
	var player: Node2D = m.player
	for pr in m.room.props:
		if pr is Props.Lever and pr.kind == "library" and not pr.pulled:
			var near := _near_lever(pr)
			var touch_on: bool = m.touch != null and m.touch.active
			m.hud.prompt("W: pull the lever" if near and not touch_on else "")
			if near and Input.is_action_just_pressed("up") and player.state == "move":
				pr.pull()
				m.hud.prompt("")


func _machine() -> void:
	# the time machine: Up beside it asks "are you sure?"
	var m: Node = G.main
	var room: Node2D = m.room
	var player: Node2D = m.player
	if not room.spawns.has("T") or m.hold or m._busy:
		return
	var t: Vector2 = room.spawns["T"]
	var near: bool = absf(player.global_position.x - t.x) < 34.0 and player.is_on_floor()
	var touch_on: bool = m.touch != null and m.touch.active
	m.hud.prompt("" if touch_on else (("W: the organ is silent" if G.shifted else "W: use the machine") if near else ""))
	if near and Input.is_action_just_pressed("up") and player.state == "move":
		if G.shifted:
			Sfx.play_file("sfx/shift/dead_terminal.wav", -4.0)
			m.hud.toast("THE ORGAN IS SILENT.")
		else:
			_ask_machine()


func _ask_machine() -> void:
	var m: Node = G.main
	m.hold = true
	m.touch.blocked = true
	var choice: String = await m.dialog.ask()
	m.dialog.close()
	m.touch.blocked = false
	if choice == "yes":
		await _activate_machine()
	else:
		# the key that said NO is still down: she must not swing at the air as the question closes
		await get_tree().create_timer(0.3).timeout
		m.hold = false


func _activate_machine() -> void:
	# the reality shift: the machine wakes, the picture tears and goes white, and under the white
	# the world turns inside out. She comes back next to the machine; this is where she wakes now.
	var m: Node = G.main
	var room: Node2D = m.room
	m._busy = true
	m.hold = true
	if room.organ != null:
		room.organ.charge()
	Sfx.pause_music(true)
	Sfx.play_file("sfx/shift/machine_activate.wav", -2.0)
	m.shake(1.5, T.v("machine_charge_time"))
	await get_tree().create_timer(T.v("machine_charge_time")).timeout
	var tear_time: float = T.v("shift_tear_time")
	Sfx.play_file("sfx/shift/shift_tear.wav", -1.0)
	m.shift.tear(tear_time)
	m.shake(5.0, tear_time)
	await get_tree().create_timer(tear_time * 0.55).timeout
	W.start_shift()
	m.saved = true
	m.saved_room = "timemachine"
	Sfx.pause_music(false)
	Sfx.stop_music()
	Sfx.play_loop("sfx/shift/drone_loop.wav", -8.0)
	m._whisper_t = randf_range(T.v("shift_whisper_min"), T.v("shift_whisper_max"))
	m.enter("timemachine", "K")
	if m.room.organ != null:
		m.room.organ.silence()
	await get_tree().create_timer(tear_time * 0.45 + 0.3).timeout
	m.hud.toast("SOMETHING ANSWERED.", 4.0)
	m.hold = false
	m._busy = false
