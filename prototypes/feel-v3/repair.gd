# PROTOTYPE - NOT FOR PRODUCTION
# SELF-REPAIR: she stands still on the floor and holds repair (G). After
# repair_hold she is locked and turns scrap into health at repair_rate, paying
# repair_cost scrap per HP. Moving, a hit, empty scrap or full health stops it.
extends Node

signal stopped(reason: String)

var active := false

var _hold_t := 0.0
var _debug_hold := 0.0
var _player = null
var _locked := false
var _tick_sound := 0.0


func _ready() -> void:
	W.player_hurt.connect(_on_hurt)
	W.room_entered.connect(_on_room)


func _physics_process(delta: float) -> void:
	var m = G.main
	if m == null or m.player == null:
		return
	_player = m.player
	if active:
		_tick(delta)
		return
	var holding := Input.is_action_pressed("repair")
	if _debug_hold > 0.0:
		_debug_hold = maxf(0.0, _debug_hold - delta)
		holding = true
	if holding:
		_hold_t += delta
		if _hold_t >= T.v("repair_hold"):
			_start()
	else:
		_hold_t = 0.0


func _tick(delta: float) -> void:
	var m = G.main
	if m == null or _player == null or not is_instance_valid(_player):
		_stop("done")
		return
	if _debug_hold <= 0.0 and not Input.is_action_pressed("repair"):
		_stop("done")
		return
	if _player.state == "dead" or m.hold:
		_stop("hit")
		return
	if m.card != null and m.card.active:
		_stop("done")
		return
	if float(_player.hp) >= R.max_hp() - 0.001:
		_stop("done")
		return
	if R.scrap <= 0.0:
		_stop("empty")
		return
	var moving := absf(Input.get_axis("left", "right")) > 0.3
	if not moving and _player.has_method("is_on_floor"):
		moving = not _player.is_on_floor()
	if moving:
		_stop("moved")
		return
	var heal := T.v("repair_rate") * delta
	var cost := heal * T.v("repair_cost")
	if cost > R.scrap:
		cost = R.scrap
		heal = cost / maxf(0.001, T.v("repair_cost"))
	if heal <= 0.0:
		_stop("empty")
		return
	R.add_scrap(-cost)
	_player.hp = minf(R.max_hp(), float(_player.hp) + heal)
	_player._energy_wait = maxf(float(_player._energy_wait), 0.05)
	_tick_sound -= delta
	if _tick_sound <= 0.0:
		_tick_sound = 0.15
		Sfx.play("repair_tick", 0.9)
	if float(_player.hp) >= R.max_hp() - 0.001:
		_stop("done")


func _start() -> void:
	var m = G.main
	if m == null or m.player == null:
		return
	_player = m.player
	if active:
		return
	if m.hold or m._busy:
		_refuse()
		return
	if m.card != null and m.card.active:
		_refuse()
		return
	if m.player.state == "dead" or m.player.state == "attack" or m.player.state == "backdash" or m.player.state == "hurt" or m.player.state == "locked":
		_refuse()
		return
	if m.player.has_method("is_on_floor") and not m.player.is_on_floor():
		_refuse()
		return
	if R.scrap < 1.0 or float(m.player.hp) >= R.max_hp() - 0.001:
		_refuse()
		return
	active = true
	_locked = true
	_hold_t = 0.0
	_tick_sound = 0.0
	m.player.lock("repair")
	Sfx.play("repair_tick", 1.1)
	m.player._energy_wait = 1.0


func _refuse() -> void:
	_hold_t = 0.0
	_debug_hold = 0.0
	Sfx.play("pickup_refuse")


func _stop(reason: String) -> void:
	if not active:
		return
	active = false
	_hold_t = 0.0
	_debug_hold = 0.0
	if _locked and _player != null and is_instance_valid(_player):
		if _player.has_method("unlock"):
			_player.unlock()
	_locked = false
	stopped.emit(reason)


func debug_hold(sec: float) -> void:
	# the test hook: pretend the repair key is held for sec seconds
	_debug_hold = maxf(0.0, sec)
	_hold_t = T.v("repair_hold")
	_start()


func _on_hurt(_dmg: int, _src: String) -> void:
	if active:
		_stop("hit")


func _on_room(_file_id: String) -> void:
	if active:
		_stop("done")
