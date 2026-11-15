# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16 (v2 — the playtest feedback pass)
#
# THE PROVENANCE LAW: every constant below is copied from the landed contracts.
# Source is named on the line. Nothing here is invented except lines marked PROTO
# (pacing/geometry the contracts are silent on).
extends Node

# ── the player body ──────────────────────────────────────────────────────────
const PLAYER_MAX_HP := 20        # entities.yaml player_max_hp (health-damage TR-HD-010)
const HP_PER_POINT := 2          # entities.yaml hp_per_point (F-HD-14, the CHASSIS step)
const HP_SEGMENTS := 20          # SYS-24's segmentation; 1 segment = 1 hp of the 20 pool
const LOW_HP_RATIO := 0.25       # health-damage.md: low cue at <= 25% — slow pulse, NEVER a flash

# ── the player's strikes ─────────────────────────────────────────────────────
const ATK1_DAMAGE := 2           # entities.yaml atk1_damage (the tap's strike, raw)
const ATK2_DAMAGE := 4           # entities.yaml atk2_damage (the counter's raw — see v2 ladder)
const COUNTER_CLASH_MULT := 1.5  # combat.md F-CMB-06 — the counter's 1.5x
const KNOCKDOWN_POWER := 2       # entities.yaml knockdown_power (power >= 2 knocks down)
const KNOCKDOWN_MS := 500        # movement.md / health-damage.md
const GETUP_MS := 700            # movement.md
const KNOCKDOWN_TOTAL_MS := 1200 # KNOCKDOWN_MS + GETUP_MS — the 1200 ms floor on heavy hits
const ATTACK_WINDOW_MS := 200    # entities.yaml attack_window_ms (combat's intent override)
const INTENT_WINDOW_MS := 140    # entities.yaml intent_window_ms
const BACKDASH_IFRAME_MS := 140  # entities.yaml backdash_iframe_ms

# ── THE ONE BUTTON (v2) ──────────────────────────────────────────────────────
# One button, three outcomes. The press is classified against the enemy's own
# clock, so the ladder is a read, not a stance:
#   press on the telegraph FLASH tail  -> COUNTER  (the big punish)
#   press into an ACTIVE swing         -> CLASH    (safe, both stop)
#   press anywhere else                -> STRIKE   (raw 2, you eat the swing)
const STRIKE_RAW := ATK1_DAMAGE                      # the tap
const COUNTER_RAW := ATK2_DAMAGE                     # the counter's raw (x1.5 = 6)
const COUNTER_WINDOW_MS := 150   # PROTO: the telegraph tail that reads as a counter
const CLASH_WINDOW_MS := 140     # PROTO (= intent_window_ms): the active-swing press
const COUNTER_REACH := 210.0     # PROTO: you must be in the fight to read it
const CLASH_REACH := 96.0        # PROTO: the swing's own reach + a body

# ── the enemy's strikes (power -> hp) ────────────────────────────────────────
const STRIKE_DMG := {1: 1, 2: 2, 3: 4}  # strike_dmg_p1 / p2 / p3
const HITSTOP_HIT_MS := 70              # entities.yaml hitstop_hit_ms
const HITSTOP_CLASH_MS := 90            # entities.yaml hitstop_clash_ms
const HITSTOP_DEFLECT_MS := 40          # entities.yaml hitstop_deflect_ms

# ── the enemy tiers + their awards (printed on death) ────────────────────────
const TIERS := [
	{"name": "HUSK", "hp": 6, "award": 3},      # roster T1: hp 6, award 3 (XP_T1)
	{"name": "SPITTER", "hp": 12, "award": 7},  # roster T2: hp 12, award 7 (XP_T2)
	{"name": "WARDEN", "hp": 24, "award": 14},  # roster T3: hp 24, award 14 (XP_T3)
]

# ── damage numbers ───────────────────────────────────────────────────────────
const DAMAGE_NUMBER_MS := 700   # health-damage.md TR-HD-036: 700 ms lifetime
const DMG_NUM_POOL := 32        # TR-HD-036: pooled (32)

# ── death, the offline screen, the cache ─────────────────────────────────────
const OFFLINE_HOLD_MS := 400         # entities.yaml offline_hold_ms (options unlock)
const DESIGNATION_PRINT_DIGITS := 3  # entities.yaml designation_print_digits
const RESTORE_MODULE_HEAL_PCT := 0.5 # health-damage.md TR-HD-025 (half a bar)
const REVIVE_IFRAME_MS := 1000       # TR-HD-025 (one second of hum)
const RESTORE_MODULE_CAP_MVP := 1    # TR-HD-025 (carry cap 1)
const HEAL_ITEM_AMOUNT := 5          # TR-HD-030 (the Suture)
const CACHE_REFILL := 3              # TR-HD-032
const FLASH_MIN_INTERVAL_MS := 350   # entities.yaml flash_min_interval_ms (<= 3 flashes/s)

# ── the boss (SYS-14 grief-boss-framework.md) ────────────────────────────────
const BOSS_HP_POOL := 60         # TR-GBF-006: hp_max 60 (BOSS_HP, 40-80)
const BOSS_HP_FLOOR := 20        # TR-GBF-012: the lie's floor — 20/60 = 1/3
const BOSS_CADENCE_MS := 900     # TR-GBF-010: BOSS_DECISION_CADENCE_MS (LIE_WHOLE)
const BOSS_CADENCE_CRACKED_MS := 700  # TR-GBF-010: the tightened cadence (LIE_CRACKED)
const BOSS_COUNTER_STAGGER_MS := 800  # the counter order's 800 ms stagger
const XP_BOSS := 40              # TR-GBF-006: the award on the DefeatEvent
const RECOGNITION_BEAT_MS := 2500     # TR-GBF-021 (she looks)
const DISSOLVE_MS := 1500             # TR-GBF-021

# Arnetria's three moves (v2). The clock is hers; the names are hers.
# telegraph / active / recovery ms, reach px, power, clashable, counterable.
const ARN_MOVES := {
	"sweep": {"name": "ring sweep", "power": 2, "telegraph": 350, "active": 80,
		"recovery": 133, "reach": 120.0, "clashable": false, "counterable": false},
	"fling": {"name": "shard fling", "power": 2, "telegraph": 350, "active": 116,
		"recovery": 133, "reach": 140.0, "clashable": true, "counterable": true},
	"cast": {"name": "mirror cast", "power": 1, "telegraph": 500, "active": 120,
		"recovery": 250, "reach": 90.0, "clashable": true, "counterable": true},
}
const SHARD := {"damage": 2, "telegraph": 300, "speed": 210.0, "lifetime": 1600,
	"deflect_speed": 380.0}   # PROTO: the shard's flight (the ring return's shape, re-skinned)

# ── THE STORED DAMAGE (v2) ───────────────────────────────────────────────────
# Her lie, re-plumbed: hits land and print, the bar does not move. The damage is
# STORED, and the only conduit is the mirror she casts. Break it in time and the
# whole store lands at once; miss and it is gone. The phase ends when the bar
# finally moves past the stall (hp <= BOSS_HP_FLOOR).
const MIRROR_PERIOD_MS := 7000   # PROTO: how often she casts
const MIRROR_TIMER_MS := 6000    # PROTO: the window to break it
const MIRROR_HP := 4             # PROTO: two taps
const STORED_CAP := 60           # PROTO: the store cannot exceed her pool
const BAR_LURCH_MS := 320        # PROTO: the bar's drop after a break (it LURCHES)

# ── the fall rule (v2) ───────────────────────────────────────────────────────
# No fall damage, no death from falling. A fall is a route: fade, return to the
# last safe ground. env_void_damage is NOT applied to pits any more.
const FALL_FADE_MS := 140        # PROTO: the fade out/in
const KILL_Y := 640.0            # PROTO: below the room = fell out

# ── the rooms ────────────────────────────────────────────────────────────────
const LEASH_PX := 300.0          # PROTO: how far you walk to leave a fight (no locks)
const DOOR_PULSE_HZ := 0.85      # PROTO: the boss door's breath
const PLAYER_SCALE := 0.8        # PROTO: the concept art's 131 px body at 0.8 = 105
const ARN_SCALE := 0.62          # PROTO: 478 px of her at 0.62 = 296 = 2.8x the player

# ── the palette ──────────────────────────────────────────────────────────────
const C_BG := Color("#141210")        # dark ground
const C_BG2 := Color("#1D1A16")       # the second value step
const C_BONE := Color("#D9BC8F")      # pale bone — the bar, the print
const C_BONE_DIM := Color("#7A6A52")
const C_CYAN := Color("#4FC8DC")      # truth accent (A) — Pandora's circuits
const C_AMBER := Color("#E8A94A")     # truth accent (B) — enemy damage numbers
const C_ICE := Color("#BFE8F2")       # Arnetria's shards + mirrors
const C_VOID := Color("#0A0908")      # the pit, the kill-zone

# ── session state (the autoload survives scene changes) ──────────────────────
var designations := 0        # designation_counter: counts remade bodies
var restore_modules := 0     # carried restore modules (cap 1)
var training_data := 0       # the awards printed on death, accumulated

# ── the world-time gate (hit-stop freezes the world, never the HUD) ─────────
var frozen := false
var cache_respawn_at_terminal := false
var pending_stamp := ""
var cache_granted := false

# ── helpers ─────────────────────────────────────────────────────────────────
func counter_output(raw: int) -> int:
	# The producer law: raw_damage already includes the counter's 1.5x.
	return int(ceil(raw * COUNTER_CLASH_MULT))


func strike_dmg(power: int) -> int:
	return int(STRIKE_DMG.get(power, 1))


func knocks_down(power: int) -> bool:
	return power >= KNOCKDOWN_POWER


func designation_text(n: int) -> String:
	return str(n).pad_zeros(DESIGNATION_PRINT_DIGITS)


func stored_cap() -> int:
	return mini(STORED_CAP, BOSS_HP_POOL)
