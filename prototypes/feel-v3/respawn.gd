# PROTOTYPE - NOT FOR PRODUCTION
# The weak respawn system: weak enemies (weak: true in enemies.json) return while
# she stays in the room. They return out of her sight, never within respawn_distance,
# never more alive than the room started with, and not in save or boss rooms.
# A faint rattle sounds respawn_warning before, then a pause respawn_attack_delay
# before the first attack. Timers stop while paused.
extends Node

const Spawner := preload("res://spawner.gd")

var pending: Array = []
var _initial_weak: Dictionary = {}
var _current_room := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	W.room_entered.connect(_on_room_entered)
	W.enemy_killed.connect(_on_enemy_killed)


func _on_room_entered(file_id: String) -> void:
	_current_room = file_id
	pending.clear()
	# Record starting weak enemy count if not yet recorded
	var cur_live := live_weak()
	if not _initial_weak.has(file_id) or cur_live > _initial_weak[file_id]:
		_initial_weak[file_id] = cur_live


func _on_enemy_killed(en: Node2D, kind: String, at: Vector2, _respawned: bool) -> void:
	var enemy_def: Dictionary = Db.table("enemies").get(kind, {})
	if not enemy_def.get("weak", false):
		return
	var m: Dictionary = W.meta(_current_room)
	if not m.get("respawn", true) or m.get("save", false) or m.get("boss", "") != "":
		return
	if _current_room == "gallery" or _current_room == "GA":
		return

	var wait_s := 10.0
	if T.data.has("weak_respawn_s"):
		wait_s = T.v("weak_respawn_s")
	elif T.data.has("respawn_time"):
		wait_s = T.v("respawn_time")

	var feet := en.global_position if is_instance_valid(en) else at
	pending.append({
		"kind": kind,
		"pos": at,
		"feet": feet,
		"timer": wait_s,
		"warned": false
	})


func live_weak() -> int:
	var room: Node = G.main.room if G.main != null else null
	if room == null:
		return 0
	var count := 0
	for c in room.get_children():
		if not (c is Node):
			continue
		if c.has_method("is_queued_for_deletion") and c.is_queued_for_deletion():
			continue
		var kd := _kind_of(c)
		if kd != "" and Db.table("enemies").get(kd, {}).get("weak", false):
			count += 1
	return count


func debug_tick(sec: float) -> void:
	_advance(sec)


func _physics_process(delta: float) -> void:
	if get_tree().paused or G.frozen():
		return
	_advance(delta)


func _advance(dt: float) -> void:
	if pending.is_empty():
		return
	var warn_time: float = T.v("respawn_warning") if T.data.has("respawn_warning") else 1.0
	var min_dist: float = T.v("respawn_distance") if T.data.has("respawn_distance") else 96.0
	var max_allowed: int = _initial_weak.get(_current_room, 99)

	var to_spawn: Array = []
	for i in range(pending.size() - 1, -1, -1):
		var item: Dictionary = pending[i]
		item["timer"] = float(item["timer"]) - dt
		if float(item["timer"]) <= warn_time and not bool(item["warned"]):
			item["warned"] = true
			if G.main != null and G.main.ambience != null and G.main.ambience.has_method("cue"):
				G.main.ambience.cue("rattle", item["pos"])

		if float(item["timer"]) <= 0.0:
			# Check distance from player
			var player_node: Node2D = G.main.player if G.main != null else null
			if player_node != null and is_instance_valid(player_node):
				var p_pos: Vector2 = player_node.global_position
				var pos_d: float = p_pos.distance_to(item["pos"])
				var feet_d: float = p_pos.distance_to(item["feet"])
				if pos_d < min_dist or feet_d < min_dist:
					continue
			# Check alive limit
			if live_weak() + to_spawn.size() >= max_allowed:
				continue
			to_spawn.append(item)
			pending.remove_at(i)

	for item in to_spawn:
		_spawn(item)


func _spawn(item: Dictionary) -> void:
	var room: Node = G.main.room if G.main != null else null
	if room == null:
		return
	var en: Node2D = Spawner.enemy(item["kind"], item["feet"])
	if en == null:
		return
	en.set("respawned", true)
	var delay: float = T.v("respawn_attack_delay") if T.data.has("respawn_attack_delay") else 1.0
	en.set("_cool", delay)
	room.add_child(en)
	if G.main != null and G.main.get("enemies") != null:
		var enemies_arr: Array = G.main.get("enemies")
		if not enemies_arr.has(en):
			enemies_arr.append(en)


func _kind_of(n: Node) -> String:
	for prop in ["kind", "enemy_kind", "id", "enemy_id"]:
		var v = n.get(prop)
		if v != null and v is String:
			return v
	return ""
