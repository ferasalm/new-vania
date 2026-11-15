# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# THE MINI-BOSSES (feedback #9) — a named encounter, not a dummy.
#   A title card on first sight ("WARDEN — TIER 3"), a distinct sprite from the
#   packs, one telegraphed PUNISH move with a long flash, and a LEASH: walk away
#   and it disengages. Nothing in this room locks (feedback #7).
extends Node2D

const Assets = preload("res://assets.gd")

const KINDS := {
	"warden": {"name": "WARDEN", "tier": 3, "scale": 1.35, "telegraph": 600.0,
		"active": 190.0, "recovery": 560.0, "reach": 104.0, "power": 2,
		"idle": "miniboss/warden_idle", "idle_n": 5, "run": "miniboss/warden_run", "run_n": 6,
		"heavy_every": 3, "heavy_telegraph": 900.0},
	"choir": {"name": "THE CHOIR", "tier": 2, "scale": 1.15, "telegraph": 720.0,
		"active": 240.0, "recovery": 520.0, "reach": 128.0, "power": 2,
		"idle": "miniboss/choir_idle", "idle_n": 8, "run": "miniboss/choir_attack", "run_n": 3,
		"heavy_every": 2, "heavy_telegraph": 950.0},
	"husk": {"name": "HUSK", "tier": 1, "scale": 1.5, "telegraph": 700.0,
		"active": 200.0, "recovery": 640.0, "reach": 70.0, "power": 1,
		"idle": "miniboss/husk", "idle_n": 4, "run": "miniboss/husk_walk", "run_n": 6,
		"heavy_every": 4, "heavy_telegraph": 860.0},
	"spitter": {"name": "SPITTER", "tier": 2, "scale": 1.25, "telegraph": 660.0,
		"active": 200.0, "recovery": 600.0, "reach": 96.0, "power": 2,
		"idle": "miniboss/spitter", "idle_n": 5, "run": "miniboss/spitter", "run_n": 5,
		"heavy_every": 3, "heavy_telegraph": 880.0},
}

const AGGRO := 190.0

var kind := "warden"
var cfg: Dictionary = {}
var tier_name := "WARDEN"
var tier := 3
var hp := 24.0
var hp_max := 24.0
var award := 14
var scale_k := 1.35
var strike_power := 2
var reach := 104.0
var telegraph_ms := 600.0
var active_ms := 190.0
var recovery_ms := 560.0

var state := "idle"      # idle | telegraph | active | recovery | stagger | dead | return
var state_ms := 0.0
var facing := -1
var flash_ms := 0.0
var dead_t := 0.0
var cooldown_ms := 500.0
var home := Vector2.ZERO
var attack_n := 0
var heavy := false
var hit_done := false
var title_ms := 0.0
var t := 0.0

var spr: AnimatedSprite2D
var _player: Node2D = null


func setup(k: String, at: Vector2) -> void:
	kind = k
	cfg = KINDS[k]
	tier_name = String(cfg["name"])
	tier = int(cfg["tier"])
	var td: Dictionary = K.TIERS[tier - 1]
	hp_max = float(td["hp"])
	hp = hp_max
	award = int(td["award"])
	scale_k = float(cfg["scale"])
	strike_power = int(cfg["power"])
	reach = float(cfg["reach"])
	telegraph_ms = float(cfg["telegraph"])
	active_ms = float(cfg["active"])
	recovery_ms = float(cfg["recovery"])
	position = at
	home = at
	z_index = 15


func _ready() -> void:
	z_index = 15
	var frames := Assets.frames(String(cfg.get("idle", "miniboss/warden_idle")), int(cfg.get("idle_n", 5)), 1)
	if frames.is_empty():
		return
	spr = AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("idle")
	sf.set_animation_speed("idle", 6.0)
	for f in frames:
		sf.add_frame("idle", f)
	var run := Assets.frames(String(cfg.get("run", "miniboss/warden_run")), int(cfg.get("run_n", 6)), 1)
	if not run.is_empty():
		sf.add_animation("run")
		sf.set_animation_speed("run", 11.0)
		for f in run:
			sf.add_frame("run", f)
	spr.sprite_frames = sf
	spr.centered = false
	# feet-anchored: the node sits on the floor, the art hangs above it
	var f0: Texture2D = frames[0]
	spr.offset = Vector2(-f0.get_width() * 0.5, -f0.get_height())
	spr.scale = Vector2(scale_k, scale_k)
	add_child(spr)
	spr.play("idle")


func watch(p: Node2D) -> void:
	_player = p


func _physics_process(delta: float) -> void:
	if K.frozen:
		return
	var ms := delta * 1000.0
	t += delta
	if flash_ms > 0.0:
		flash_ms = maxf(0.0, flash_ms - ms)
	if title_ms > 0.0:
		title_ms = maxf(0.0, title_ms - ms)
	if state == "dead":
		dead_t += ms
		_animate()
		queue_redraw()
		return
	if cooldown_ms > 0.0:
		cooldown_ms -= ms
	state_ms += ms
	var dist := 9999.0
	if _player:
		dist = position.distance_to(_player.position)

	match state:
		"idle":
			position = position.lerp(home, minf(1.0, delta * 1.6))
			if cooldown_ms <= 0.0 and dist < AGGRO:
				facing = 1 if _player.position.x > position.x else -1
				_begin_attack()
			elif dist > K.LEASH_PX:
				# the leash: it gives up. Nothing locks you in this room.
				state = "return"
				state_ms = 0.0
		"telegraph":
			if state_ms >= telegraph_ms:
				state = "active"
				state_ms = 0.0
		"active":
			if state_ms >= active_ms:
				state = "recovery"
				state_ms = 0.0
		"recovery":
			if state_ms >= recovery_ms:
				state = "idle"
				state_ms = 0.0
				cooldown_ms = 300.0 if heavy else 620.0
				heavy = false
		"stagger":
			if state_ms >= K.BOSS_COUNTER_STAGGER_MS:
				state = "idle"
				state_ms = 0.0
				cooldown_ms = 520.0
		"return":
			position = position.lerp(home, minf(1.0, delta * 2.4))
			if position.distance_to(home) < 3.0:
				state = "idle"
				state_ms = 0.0
	_animate()
	queue_redraw()


func _begin_attack() -> void:
	attack_n += 1
	heavy = attack_n % int(cfg["heavy_every"]) == 0
	telegraph_ms = float(cfg["heavy_telegraph"]) if heavy else float(cfg["telegraph"])
	recovery_ms = 700.0 if heavy else float(cfg["recovery"])
	state = "telegraph"
	state_ms = 0.0
	hit_done = false
	if attack_n == 1:
		title_ms = 2400.0


func _animate() -> void:
	if spr == null:
		return
	spr.flip_h = facing < 0
	var want := "idle"
	if state == "active" or state == "telegraph" or state == "return":
		want = "run" if spr.sprite_frames.has_animation("run") else "idle"
	if spr.animation != want:
		spr.play(want)
	if flash_ms > 0.0:
		spr.modulate = Color(2.0, 2.0, 2.0, 1)
	elif state == "telegraph" and int(state_ms / 90.0) % 2 == 0:
		spr.modulate = Color(1.7, 1.7, 1.7, 1)
	elif state == "stagger":
		spr.modulate = Color(0.7, 1.4, 1.6, 1)
	else:
		spr.modulate = Color(1, 1, 1, 1)
	if state == "dead":
		spr.modulate = Color(1, 1, 1, clampf(1.0 - dead_t / 900.0, 0.0, 1.0))


# ── the enemy contract ──────────────────────────────────────────────────────
func is_dead() -> bool:
	return state == "dead"


func strike_phase() -> String:
	if state == "telegraph" or state == "active":
		return state
	return "none"


func counter_open() -> bool:
	return state == "telegraph" and state_ms >= telegraph_ms - K.COUNTER_WINDOW_MS


func can_counter() -> bool:
	return true


func clashable() -> bool:
	return true


func power() -> int:
	return strike_power


func strike_name() -> String:
	return "the pounce" if heavy else "the swing"


func telegraph_len() -> float:
	return telegraph_ms


func active_len() -> float:
	return active_ms


func hurtbox() -> Rect2:
	var h := 76.0 * scale_k
	var w := 54.0 * scale_k
	return Rect2(position.x - w * 0.5, position.y - h, w, h)


func active_hitbox() -> Rect2:
	if state != "active" or hit_done:
		return Rect2()
	var r := reach * (1.25 if heavy else 1.0)
	var x := position.x + (6.0 if facing > 0 else -6.0 - r)
	return Rect2(x, position.y - 70.0 * scale_k, r, 64.0 * scale_k)


func consume_strike() -> void:
	hit_done = true


func on_contact() -> void:
	pass


func stagger(ms: float) -> void:
	if state == "dead":
		return
	state = "stagger"
	state_ms = 0.0


func take_damage(dmg: int) -> Dictionary:
	if state == "dead":
		return {"dealt": 0, "dead": false}
	hp = maxf(0.0, hp - float(dmg))
	flash_ms = 100.0
	if hp <= 0.0:
		state = "dead"
		state_ms = 0.0
		dead_t = 0.0
		return {"dealt": dmg, "dead": true}
	return {"dealt": dmg, "dead": false}


# ── draw ────────────────────────────────────────────────────────────────────
func _draw() -> void:
	var hb := hurtbox()
	var local := Rect2(hb.position - position, hb.size)

	# the title card, on first sight
	if title_ms > 0.0:
		var a: float = clampf(title_ms / 500.0, 0.0, 1.0)
		var s := "%s — TIER %d" % [tier_name, tier]
		var w := ThemeDB.fallback_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		var c := K.C_BONE
		c.a = a
		draw_rect(Rect2(-w * 0.5 - 8, -local.size.y - 34, w + 16, 20), Color(0, 0, 0, 0.55 * a))
		draw_string(ThemeDB.fallback_font, Vector2(-w * 0.5, -local.size.y - 19), s,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, c)

	if state == "dead":
		draw_set_transform(Vector2(0, -2), 0.0, Vector2(1, 0.2))
		draw_circle(Vector2.ZERO, 26.0, Color(0, 0, 0, clampf(1.0 - dead_t / 900.0, 0.0, 0.35)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return

	# the shadow
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1, 0.22))
	draw_circle(Vector2.ZERO, 24.0 * scale_k, Color(0, 0, 0, 0.30))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# the swing's reach, drawn only while it is live
	if state == "active":
		var hbx0 := active_hitbox()
		var hbx := Rect2(hbx0.position - position, hbx0.size)
		draw_rect(hbx, Color(K.C_AMBER.r, K.C_AMBER.g, K.C_AMBER.b, 0.16))
		draw_rect(Rect2(hbx.position.x, hbx.position.y + hbx.size.y * 0.5, hbx.size.x, 2.0), K.C_AMBER)

	# the tier's hp pips
	var pips := int(hp_max)
	var pw: float = maxf(2.0, local.size.x / float(pips))
	for i in pips:
		var on: bool = i < int(hp)
		draw_rect(Rect2(local.position.x + i * pw, local.position.y - 8.0, maxf(1.0, pw - 1.0), 3.0),
			K.C_BONE if on else Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.25))

	# the leash tell: a dim tether to home while it is giving up
	if state == "return":
		draw_line(Vector2.ZERO, home - position,
			Color(K.C_BONE_DIM.r, K.C_BONE_DIM.g, K.C_BONE_DIM.b, 0.25), 1.0)
