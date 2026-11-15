# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2)
# The smoke harness. Boots the contract-critical rules headless and prints PASS/FAIL.
# Run: godot --headless --path prototypes/sandbox res://smoke.tscn --quit-after 900
#
# v2 covers the playtest's five new laws:
#   the one-button ladder (strike / clash / counter, classified on the press),
#   the stored damage (bar frozen, store printed, lurch on a break, clear on a miss),
#   the mirror's timer ring,
#   the fall rule (no damage, no death, teleport to the last safe ground),
#   the door language (a sealed boss door, quiet plain doors).
extends Node2D

const MINIBOSS := preload("res://miniboss.gd")
const PLAYER := preload("res://player.gd")
const OFFLINE := preload("res://offline.gd")
const Assets = preload("res://assets.gd")

var phase := 0
var ft := 0
var frames := 0
var passes := 0
var fails := 0

var training = null
var arena = null
var approach = null
var cache_sc = null
var offline_ok := false


func _ready() -> void:
	K.frozen = false
	K.designations = 0
	print("SMOKE: boot")


func check(cond: bool, label: String) -> void:
	if cond:
		passes += 1
		print("  PASS  ", label)
	else:
		fails += 1
		print("  FAIL  ", label)


func _physics_process(_delta: float) -> void:
	ft += 1
	frames += 1
	if frames > 800 and phase < 20:
		print("SMOKE: TIMED OUT at phase %d after %d frames" % [phase, frames])
		get_tree().quit(1)
		return
	match phase:
		0:
			if ft < 4:
				return
			print("SMOKE: the values law")
			check(K.counter_output(K.COUNTER_RAW) == 6, "counter(4) x1.5 -> 6")
			check(K.STRIKE_RAW == 2 and K.COUNTER_RAW == 4, "strike 2 / counter raw 4")
			check(K.strike_dmg(1) == 1 and K.strike_dmg(2) == 2 and K.strike_dmg(3) == 4, "strike 1/2/4")
			check(K.knocks_down(2) and not K.knocks_down(1), "knockdown at power >= 2")
			check(K.KNOCKDOWN_MS + K.GETUP_MS == 1200, "knockdown floor 1200 ms")
			check(K.designation_text(1) == "001" and K.designation_text(42) == "042", "designation 3 digits")
			check(K.HP_SEGMENTS == 20 and K.PLAYER_MAX_HP == 20, "20 segments over a 20 pool")
			check(K.OFFLINE_HOLD_MS == 400, "offline hold 400 ms")
			check(K.BOSS_HP_POOL == 60 and K.BOSS_HP_FLOOR == 20, "boss 60, stall 20")
			check(K.MIRROR_TIMER_MS == 6000 and K.MIRROR_HP == 4, "mirror: 6000 ms, 4 hp")
			check(K.BAR_LURCH_MS == 320, "the bar lurches in 320 ms")
			check(K.KILL_Y > 540.0, "the fall line is below the room")
			check(bool(K.ARN_MOVES["fling"]["counterable"]), "the shard fling is counterable")
			check(not bool(K.ARN_MOVES["sweep"]["clashable"]), "the ring sweep is unclashable")
			phase = 1
			ft = 0

		1:
			if ft < 2:
				return
			print("SMOKE: the one-button ladder")
			training = load("res://training.tscn").instantiate()
			add_child(training)
			phase = 2
			ft = 0

		2:
			if ft < 3:
				return
			var p = training.get("player")
			var ens = training.get("enemies")
			# the spitter has 12 hp, so a counter's 6 is readable in the pool
			var e = ens[1]
			p.position = e.position + Vector2(-100, 0)
			p.facing = 1
			_reset(training)
			e.state = "telegraph"
			e.state_ms = e.telegraph_ms - 100.0
			training.call("_on_press")
			check(p.is_countering(), "a press on the flash tail is a COUNTER")
			check(int(e.hp) == 6, "the counter's 6 lands: SPITTER 12 -> 6")
			check(e.state == "stagger", "and the counter order staggers it")
			phase = 3
			ft = 0

		3:
			if ft < 2:
				return
			var p = training.get("player")
			var e = training.get("enemies")[1]
			_reset(training)
			p.position = e.position + Vector2(-60, 0)
			e.state = "active"
			e.state_ms = 0.0
			e.hit_done = false
			var before := int(e.hp)
			training.call("_on_press")
			check(p.is_clashing(), "a press into a live swing is a CLASH")
			check(int(e.hp) == before, "the clash deals no damage")
			check(e.hit_done, "and the clash consumes the swing")
			phase = 4
			ft = 0

		4:
			if ft < 2:
				return
			var p = training.get("player")
			var e = training.get("enemies")[1]
			_reset(training)
			e.state = "idle"
			e.cooldown_ms = 99999.0
			e.position = Vector2(900, 420)
			p.position = Vector2(200, 420)
			training.call("_on_press")
			check(p.is_attacking(), "a press with no threat is a STRIKE")
			training.queue_free()
			training = null
			phase = 5
			ft = 0

		5:
			if ft < 3:
				return
			print("SMOKE: the stored damage")
			arena = load("res://arena.tscn").instantiate()
			add_child(arena)
			phase = 6
			ft = 0

		6:
			if ft < 3:
				return
			var b = arena.get("boss")
			b.cadence_t = -999999.0
			b.mirror_cd = 999999.0
			var r1: Dictionary = b.take_damage(6)
			check(int(b.hp) == 60, "a hit does NOT move her bar (still 60)")
			check(int(b.stored) == 6, "the hit is stored (6)")
			check(bool(r1.get("stored", false)), "the result reports the store")
			b.take_damage(4)
			check(int(b.stored) == 10, "the store accumulates (10)")
			check(int(b.hp) == 60, "and the bar still has not moved")
			phase = 7
			ft = 0

		7:
			if ft < 2:
				return
			var b = arena.get("boss")
			b._spawn_mirror()
			var m = b.mirror_node()
			check(m != null, "she casts a mirror")
			check(absf(m.ratio() - 1.0) < 0.05, "the mirror's timer ring starts full")
			m.tick(3.0)
			check(m.ratio() < 0.6 and m.ratio() > 0.4, "the ring drains (6000 -> ~3000)")
			m.hit(4)
			check(m.broke, "four damage breaks the mirror")
			b._resolve_mirror()
			check(int(b.hp) == 50, "the whole store lands at once: 60 -> 50")
			check(int(b.stored) == 0, "and the store is emptied")
			check(b.lurch_ms > 0.0, "the bar lurches")
			phase = 8
			ft = 0

		8:
			if ft < 2:
				return
			var b = arena.get("boss")
			b.take_damage(8)
			check(int(b.stored) == 8, "a new store (8)")
			b._spawn_mirror()
			var m = b.mirror_node()
			m.timer_ms = 1.0
			m.tick(0.05)
			check(m.expired and not m.alive, "the ring closes on its own")
			b._resolve_mirror()
			check(int(b.hp) == 50, "a missed mirror leaves the bar where it was")
			check(int(b.stored) == 0, "and CLEARS the store")
			phase = 9
			ft = 0

		9:
			if ft < 2:
				return
			var b = arena.get("boss")
			# the stall: fill the store and break one mirror; the bar stops at 20
			b.take_damage(60)
			check(int(b.stored) == 60, "the store caps at the pool (60)")
			b._spawn_mirror()
			b.mirror_node().hit(4)
			b._resolve_mirror()
			check(int(b.hp) == 20, "the bar moves past the stall only to 20 (the floor)")
			check(b.phase == "LIE_CRACKED", "and that ends phase 1")
			check(b.hp_floor == 0.0, "the floor is released")
			var r2: Dictionary = b.take_damage(5)
			check(int(b.hp) == 15, "phase 2: damage moves the bar directly (20 -> 15)")
			check(not bool(r2.get("stored", true)), "phase 2 does not store")
			phase = 10
			ft = 0

		10:
			if ft < 2:
				return
			print("SMOKE: the door language")
			var doors = arena.get("doors")
			check(doors.size() == 1 and doors[0].kind == "boss", "the arena's door is a boss door")
			check(doors[0].sealed, "and it seals behind you")
			arena.queue_free()
			arena = null
			phase = 11
			ft = 0

		11:
			if ft < 3:
				return
			approach = load("res://approach.tscn").instantiate()
			add_child(approach)
			phase = 12
			ft = 0

		12:
			if ft < 3:
				return
			print("SMOKE: no locks, and the fall rule")
			var doors = approach.get("doors")
			var sealed := 0
			var kinds: Array = []
			for d in doors:
				if d.sealed:
					sealed += 1
				kinds.append(d.kind)
			check(sealed == 0, "nothing in the approach seals")
			check("plain" in kinds and "boss" in kinds, "it carries both door kinds")
			var p = approach.get("player")
			check(not p.locked, "the body is never locked outside her arena")
			# the fall: drop the body out of the room
			var hp_before: float = p.hp
			var safe: Vector2 = approach.get("last_safe")
			p.position = Vector2(700, 700)
			phase = 13
			ft = 0

		13:
			if ft < 4:
				return
			var p = approach.get("player")
			check(p.position.y < 600.0, "a fall teleports you back into the room")
			check(int(p.hp) == 20, "a fall costs no HP")
			check(not bool(approach.get("dead")), "a fall is not a death")
			check(int(approach.get("fall_count")) >= 1, "the fall is counted")
			approach.queue_free()
			approach = null
			phase = 14
			ft = 0

		14:
			if ft < 3:
				return
			print("SMOKE: the cache loop (the pit is a route, the seam kills)")
			cache_sc = load("res://cache.tscn").instantiate()
			add_child(cache_sc)
			phase = 15
			ft = 0

		15:
			if ft < 3:
				return
			var p = cache_sc.get("player")
			# drop into the pit
			p.position = Vector2(420, 700)
			phase = 16
			ft = 0

		16:
			if ft < 4:
				return
			var p = cache_sc.get("player")
			check(not bool(cache_sc.get("dead")), "the pit does not kill any more")
			check(p.position.y < 600.0, "it hands you back to the floor")
			check(int(p.hp) == 20, "and costs nothing")
			# now the seam
			p.position = Vector2(894, 420)
			phase = 17
			ft = 0

		17:
			if ft < 4:
				return
			check(bool(cache_sc.get("dead")), "the seam is still the death edge")
			var off = cache_sc.get("offline")
			check(off != null, "and it raises the offline screen")
			# the 400 ms hold — driven on a STANDALONE surface, because the live one
			# is wired to the cache scene and a commit would reload the room
			var solo = OFFLINE.new()
			solo.cause = "FAULT: THE SEAM · ENVIRONMENT · TICK 1"
			solo.has_module = false
			add_child(solo)
			var ev := InputEventKey.new()
			ev.pressed = true
			ev.keycode = KEY_ENTER
			solo._input(ev)
			check(not offline_ok, "options are dead before OFFLINE_HOLD_MS 400")
			solo.held_ms = 500.0
			solo.chosen.connect(func(c): offline_ok = true)
			solo._input(ev)
			check(offline_ok, "options unlock after the hold")
			solo.queue_free()
			cache_sc.queue_free()
			cache_sc = null
			phase = 18
			ft = 0

		18:
			if ft < 3:
				return
			print("SMOKE: the player's revive")
			var p = PLAYER.new()
			add_child(p)
			p.solids = []
			p.locked = true
			p.hp = 0.0
			p.revive(K.RESTORE_MODULE_HEAL_PCT)
			check(int(p.hp) == 10, "the module revive is half a bar (ceil 20 x 0.5)")
			check(not p.locked, "the revive releases the body lock")
			check(p.is_invulnerable(), "and the 1000 ms hum holds")
			print("SMOKE: the art is wired")
			check(p.spr != null and p.spr.sprite_frames.get_frame_count("idle") == Assets.PANDORA["idle"],
				"pandora's idle is 12 keyed frames")
			check(p.spr.sprite_frames.get_frame_count("dash") == Assets.PANDORA["dash"],
				"her dash is 8 keyed frames")
			check(p.spr.sprite_frames.get_frame_count("jump") == Assets.PANDORA["jump"],
				"her jump is 5 (3 airborne poses + idle bookends)")
			check(p.spr.sprite_frames.get_frame_texture("idle", 0).get_width() == 128,
				"every frame shares the 128x200 canvas (no teleporting sprite)")
			var arn_tex = Assets.tex("res://assets/arnetria/idle.png")
			check(arn_tex != null and arn_tex.get_width() == 381, "Arnetria's idle pose is a real 381 px crop")
			var mirror_tex = Assets.tex("res://assets/arnetria/mirror.png")
			check(mirror_tex != null and mirror_tex.get_width() == 72, "the mirror carries a baked reflection")
			var door_tex = Assets.tex("res://assets/env/boss_door.png")
			check(door_tex != null and door_tex.get_height() == 268, "the boss door is a 268 px arch")
			p.queue_free()
			phase = 19
			ft = 0

		19:
			if ft < 2:
				return
			print("SMOKE: %d passed, %d failed" % [passes, fails])
			print("SMOKE: %s" % ("ALL GREEN" if fails == 0 else "RED"))
			get_tree().quit(0 if fails == 0 else 1)


func _reset(sc) -> void:
	K.frozen = false
	sc.hitstop_ms = 0.0
	var p = sc.get("player")
	if p:
		p.state = "idle"
		p.state_ms = 0.0
		p.hit_done = false
		p.locked = false
		p.hp = p.hp_max
		p.invuln_ms = 0.0
