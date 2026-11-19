# PROTOTYPE - NOT FOR PRODUCTION
# The spawner system: builds the enemy for an enemies.json id and the boss for a
# boss id. Today's kinds use today's two enemy scripts; a boss whose script does
# not exist yet answers null, so the room simply has no boss.
extends Node

const Enemy := preload("res://enemy.gd")
const Enemy2 := preload("res://enemy2.gd")
const BOSSES := {"pallbearer": "res://boss.gd"}


static func enemy(kind: String, feet: Vector2) -> Node2D:
	# the right enemy node for every enemies.json id, placed with its feet at "feet"
	if Enemy.KINDS.has(kind):
		var en: Node2D = Enemy.new()
		en.position = feet if not Enemy.KINDS[kind]["fly"] else feet - Vector2(0, 8)
		en.setup(kind)
		return en
	if Enemy2.KINDS.has(kind):
		var en2: Node2D = Enemy2.new()
		en2.position = feet
		en2.setup(kind)
		return en2
	return null


static func boss(id: String, feet: Vector2, room_size: Vector2) -> Node2D:
	# the boss node for an id; an id whose script does not exist yet answers null
	var path := String(Db.table("enemies").get(id, {}).get("script", ""))
	if path == "":
		path = String(BOSSES.get(id, ""))
	if path == "" or not ResourceLoader.exists(path):
		return null
	var script = load(path)
	if script == null:
		return null
	var b: Node2D = script.new()
	if b == null:
		return null
	b.setup(feet, room_size)
	return b
