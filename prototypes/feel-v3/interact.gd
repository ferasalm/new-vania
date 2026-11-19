# PROTOTYPE - NOT FOR PRODUCTION
# The interact system: the Up key. S2 unifies items, levers, terminals and the
# time machine in one registry; the nearest target wins, and Up + attack on the
# same frame is the special attack instead of a use.
extends Node

signal used(kind: String, node: Node2D)

const Props := preload("res://props.gd")

var targets: Array = []     # {node, kind, label, cb, reach}
var _markers: Array = []


func _ready() -> void:
	W.room_entered.connect(_on_room_entered)


func register(node: Node2D, kind: String, label: String, cb: Callable, reach := 0.0) -> void:
	# make a thing in the room reachable with Up; a reach of 0 uses pickup_reach
	unregister(node)
	targets.append({"node": node, "kind": kind, "label": label, "cb": cb, "reach": reach})


func unregister(node: Node2D) -> void:
	# forget a thing (it was taken, used or freed)
	targets = targets.filter(func(t): return is_instance_valid(t["node"]) and t["node"] != node)


func nearest() -> Dictionary:
	# the closest registered target in reach: {node, kind, label, pos}, or {}
	var m = G.main
	if m == null or m.player == null:
		return {}
	var p: Vector2 = m.player.global_position
	var best := {}
	var best_d := INF
	for t in targets:
		if not is_instance_valid(t["node"]):
			continue
		var node = t["node"]
		if node is Props.Lever and node.pulled:
			continue
		var reach := float(t["reach"]) if float(t["reach"]) > 0.0 else T.v("pickup_reach")
		var d: float = p.distance_to(node.global_position)
		if d <= reach and d < best_d:
			best_d = d
			best = {"node": node, "kind": t["kind"], "label": t["label"], "pos": node.global_position}
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
	if is_instance_valid(n["node"]):
		used.emit(String(n["kind"]), n["node"])
		if n["node"] is Props.Lever and n["node"].pulled:
			unregister(n["node"])
	return true


func _find(node: Node2D) -> Dictionary:
	for t in targets:
		if t["node"] == node:
			return t
	return {}


func _on_room_entered(_file_id: String) -> void:
	# the targets and markers of the old room are gone
	targets.clear()
	for mk in _markers:
		if is_instance_valid(mk):
			mk.queue_free()
	_markers.clear()
	var m = G.main
	if m == null or m.room == null:
		return
	if m.room.spawns.has("M"):
		_marker(m.room.spawns["M"], "terminal", "NO SIGNAL" if G.shifted else "CACHE", Callable(self, "_terminal_use"))
	if m.room.spawns.has("T"):
		_marker(m.room.spawns["T"], "machine", "THE ORGAN IS SILENT" if G.shifted else "MACHINE", Callable(self, "_machine_use"))
	for pr in m.room.props:
		if pr is Props.Lever and not pr.cut_only and not pr.pulled:
			register(pr, "lever", "LEVER", Callable(self, "_lever_use").bind(pr), T.v("lever_reach"))


func _marker(at: Vector2, kind: String, label: String, cb: Callable) -> void:
	var mk := Node2D.new()
	mk.position = at
	G.main.room.add_child(mk)
	_markers.append(mk)
	register(mk, kind, label, cb, 0.0)


func _lever_use(pr) -> void:
	if pr is Props.Lever and not pr.pulled:
		pr.pull()


func _terminal_use() -> void:
	# the save room: Up at the terminal heals, refills and saves (never Sutures)
	var m = G.main
	if m == null or m.player == null:
		return
	if G.shifted:
		# after the shift every cache station is dead: no heal, no save
		Sfx.play_file("sfx/shift/dead_terminal.wav", -4.0)
		m.hud.toast("NO SIGNAL")
		return
	m.saved = true
	m.saved_room = m.room_name
	m.player.hp = R.max_hp()
	m.player.mp = R.max_mp()
	R.refill_at_terminal()
	Sfx.play("pickup", 0.7)
	Sfx.play("special", 0.6)
	m.ring_fx(m.room.spawns["M"] + Vector2(0, -40), 70.0, Color(0.5, 1.0, 1.0))
	m.hud.toast("MEMORY CACHED")


func _machine_use() -> void:
	# the time machine: Up beside it asks "are you sure?"
	var m = G.main
	if m == null or m.hold or m._busy:
		return
	if G.shifted:
		Sfx.play_file("sfx/shift/dead_terminal.wav", -4.0)
		m.hud.toast("THE ORGAN IS SILENT.")
		return
	_ask_machine()


func tick() -> void:
	var m = G.main
	if m == null or m.room == null or m.player == null:
		return
	if m.hold or m._busy:
		m.hud.prompt("")
		return
	if m.card != null and (m.card.active or m.card.lock_left > 0.0 or m.card.swallow_left > 0.0):
		m.hud.prompt("")
		return
	if m.repair != null and m.repair.active:
		m.hud.prompt("")
		return
	if m.dialog != null and m.dialog.active:
		m.hud.prompt("")
		return
	if Input.is_action_just_pressed("quick"):
		_use_quick()
		return
	var n := nearest()
	var touch_on: bool = m.touch != null and m.touch.active
	if n.is_empty():
		m.hud.prompt("")
	elif not touch_on:
		m.hud.prompt("W: " + String(n["label"]))
	if not Input.is_action_just_pressed("up"):
		return
	if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("attack2"):
		return
	if m.player.has_method("is_locked") and m.player.is_locked():
		return
	press()


func _use_quick() -> void:
	# the quick key (H) uses what sits in the quickslot, a Suture by default
	var m = G.main
	if m == null or m.player == null:
		return
	var id := String(R.quickslot) if String(R.quickslot) != "" else "suture"
	if R.use_item(id):
		Sfx.play("pickup", 0.8)
		if id == "suture":
			m.number(m.player.global_position + Vector2(0, -44), int(T.v("suture_heal")), Color("#8FE38F"))
	else:
		Sfx.play("pickup_refuse")


func interact_target() -> Dictionary:
	# what the touch bubble points at: {"pos": world position, "label": text}, or {} when nothing is near
	var n := nearest()
	if n.is_empty():
		return {}
	return {"pos": n["pos"] + Vector2(0, -22), "label": String(n["label"])}


func _ask_machine() -> void:
	var m = G.main
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
	var m = G.main
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
