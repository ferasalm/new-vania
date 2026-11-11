# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does committed SotN-weight combat (combo + clash + deflect) feel rewarding?
# Date: 2026-11-11
# Orb — shooter projectile; deflectable by the player's active swing (the "deflect" test).

class_name ProtoOrb
extends Node2D

var main: Node
var velocity := Vector2.ZERO
var friendly := false

const DEFLECT_DAMAGE := 15     # spec: deflected orb hits enemies for 15
const PLAYER_HIT_RADIUS := 16.0
const PLAYER_CENTER := Vector2(0.0, -20.0)  # mid-body, relative to player origin (feet)

func _physics_process(delta: float) -> void:
	position += velocity * delta
	if position.x < -50.0 or position.x > 1010.0 or position.y > 600.0 or position.y < -200.0:
		queue_free()
		return
	var p: Variant = main.get("player")
	if p == null:
		return
	if not friendly:
		# DEFLECT — an active player swing catches the orb
		if p.is_attack_active() and p.attack_hitbox().has_point(global_position):
			velocity = -velocity.normalized() * Tunables.ORB_SPEED_DEFLECTED
			if velocity.x != 0.0 and signf(velocity.x) != signf(float(p.facing)):
				velocity.x = -velocity.x  # always travel toward the player's facing
			friendly = true
			main.on_clash("deflect")
			queue_redraw()
			return
		if global_position.distance_to(p.global_position + PLAYER_CENTER) < PLAYER_HIT_RADIUS:
			p.take_damage(Tunables.ORB_DAMAGE, signf(velocity.x))
			queue_free()
	else:
		for e: Variant in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or e.get("dead"):
				continue
			if e.hurt_rect().has_point(global_position):
				e.hurt(DEFLECT_DAMAGE, 0, false)
				queue_free()
				break

func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color("050912"))
	draw_circle(Vector2.ZERO, 5.0, Color("ffb45f") if friendly else Color("0d7b89"))
