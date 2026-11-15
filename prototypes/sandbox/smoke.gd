# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its landed numbers are played, not read?
# Date: 2026-11-16
# The smoke harness. Boots the contract-critical rules headless and prints PASS/FAIL.
# Run: godot --headless --path prototypes/sandbox res://smoke.tscn --quit-after 900
# (900 main-loop iterations is the measured bound that reaches phase 9; the harness
#  also self-guards — a run that stalls prints SMOKE: TIMED OUT and exits non-zero,
#  so a wrapper may check both the exit status and the final SMOKE summary line.)
extends Node2D

const BOSS := preload("res://boss.gd")
const PLAYER := preload("res://player.gd")
const OFFLINE := preload("res://offline.gd")

var phase := 0
var ft := 0
var frames := 0
var passes := 0
var fails := 0
var boss
var player
var sweep_n := 0
var duel: Node = null
var den: Node = null
var offline_ok := false
var offline_early := false


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
	if frames > 800 and phase < 11:
		print("SMOKE: TIMED OUT at phase %d after %d frames" % [phase, frames])
		get_tree().quit(1)
		return
	match phase:
		0:
			if ft < 4:
				return
			print("SMOKE: constants")
			check(K.counter_output(K.ATK1_DAMAGE) == 3, "counter(light 2) -> 3")
			check(K.counter_output(K.ATK2_DAMAGE) == 6, "counter(heavy 4) -> 6")
			check(K.strike_dmg(1) == 1 and K.strike_dmg(2) == 2 and K.strike_dmg(3) == 4, "strike 1/2/4")
			check(K.knocks_down(2) and not K.knocks_down(1), "knockdown at power >= 2")
			check(K.KNOCKDOWN_MS + K.GETUP_MS == 1200, "knockdown floor 1200 ms")
			check(K.designation_text(1) == "001" and K.designation_text(42) == "042", "designation 3 digits")
			check(K.HP_SEGMENTS == 20 and K.PLAYER_MAX_HP == 20, "20 segments over a 20 pool")
			check(K.OFFLINE_HOLD_MS == 400 and K.CRACK_WHIFFS_REQUIRED == 3, "hold 400 / crack 3")
			check(K.BOSS_HP_POOL == 60 and K.BOSS_HP_FLOOR == 20, "boss 60, floor 20")

			print("SMOKE: the player's counter")
			player = PLAYER.new()
			add_child(player)
			player.solids = []
			player.try_counter()
			check(player.counter_value() == 3, "counter stance -> 3")
			player.try_counter()
			check(player.counter_value() == 6, "K in the stance -> 6")
			player.queue_free()

			print("SMOKE: the boss's lie")
			boss = BOSS.new()
			add_child(boss)
			boss.setup(Vector2(400, 400), 40.0, 920.0)
			boss.cadence_t = -999999.0     # decisions off; the sweeps are driven by hand
			boss.hp = 22.0
			var r1: Dictionary = boss.take_damage(4)
			check(int(boss.hp) == 20, "hp 22 - 4 clamps to the floor 20 (the stall)")
			check(bool(r1["floor"]), "the floor flag is set")
			phase = 1
			ft = 0

		1:
			if ft < 2:
				return
			if boss.state != "idle":
				return
			sweep_n += 1
			boss._begin_strike("sweep")
			phase = 2
			ft = 0

		2:
			if ft < 45:
				return
			check(boss.whiffs == sweep_n, "unanswered sweep %d -> whiff %d" % [sweep_n, sweep_n])
			check(boss.crack_stage == sweep_n, "halo stage %d" % sweep_n)
			if sweep_n < 3:
				phase = 1
			else:
				phase = 3
			ft = 0

		3:
			if ft < 3:
				return
			check(boss.state == "crack", "the crack beat fires at 3 whiffs")
			check(boss.phase == "LIE_CRACKED", "phase -> LIE_CRACKED")
			check(boss.hp_floor == 0.0, "the floor is released at the beat's first tick")
			phase = 4
			ft = 0

		4:
			if ft < 130:
				return
			check(boss.state == "idle", "the beat ends after 2000 ms")
			var r2: Dictionary = boss.take_damage(20)
			check(int(boss.hp) == 0, "post-crack damage moves the bar (20 -> 0)")
			check(bool(r2["dead"]) and boss.state == "script", "the death edge is reachable; the script starts")
			phase = 5
			ft = 0

		5:
			if ft < 2:
				return
			print("SMOKE: the offline hold")
			var off = OFFLINE.new()
			off.cause = "FAULT: THE PIT · ENVIRONMENT · TICK 1"
			off.has_module = false
			off.chosen.connect(func(c): offline_ok = true)
			add_child(off)
			var ev := InputEventKey.new()
			ev.pressed = true
			ev.keycode = KEY_ENTER
			off._input(ev)
			check(not offline_ok, "options are dead before OFFLINE_HOLD_MS 400")
			off.held_ms = 500.0
			off._input(ev)
			check(offline_ok, "options unlock after the hold")
			off.queue_free()
			phase = 6
			ft = 0

		6:
			if ft < 2:
				return
			print("SMOKE: the duel resolver (the hitbox lands the number)")
			duel = load("res://duel.tscn").instantiate()
			add_child(duel)
			phase = 7
			ft = 0

		7:
			if ft < 3:
				return
			var p = duel.get("player")
			p.position = Vector2(500, 420)
			p.facing = 1
			p.try_light()
			phase = 8
			ft = 0

		8:
			if ft < 25:
				return
			var ens = duel.get("enemies")
			check(int(ens[0].hp) == 4, "light (2) lands: HUSK 6 -> 4")
			check(ens[0].state == "idle", "the dummy survives one light strike")
			phase = 9
			ft = 0

		9:
			if ft < 3:
				return
			print("SMOKE: the boss's exchange (the counter lands)")
			den = load("res://denial.tscn").instantiate()
			add_child(den)
			phase = 10
			ft = 0

		10:
			if ft < 3:
				return
			var dp = den.get("player")
			var db = den.get("boss")
			dp.position = Vector2(660, 440)
			dp.facing = 1
			dp.try_counter()
			db._begin_strike("lifted")
			db.state = "active"
			db.state_ms = 0.0
			db.hit_done = false
			db.facing = -1
			den.call("_resolve")
			check(int(db.hp) == 57, "the counter's 3 reaches her pool: 60 -> 57")
			check(db.state == "stagger", "and the counter order staggers her")
			dp.locked = true
			dp.hp = 0.0
			dp.revive(K.RESTORE_MODULE_HEAL_PCT)
			check(int(dp.hp) == 10, "the module revive is half a bar (ceil 20 x 0.5)")
			check(not dp.locked, "the revive releases the body lock")
			phase = 11
			ft = 0

		11:
			if ft < 2:
				return
			print("SMOKE: %d passed, %d failed" % [passes, fails])
			print("SMOKE: %s" % ("ALL GREEN" if fails == 0 else "RED"))
			get_tree().quit(0 if fails == 0 else 1)
