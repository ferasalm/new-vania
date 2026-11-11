# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does committed SotN-weight combat (combo + clash + deflect) feel rewarding?
# Date: 2026-11-11
# ALL feel tunables live here. Tweak, press F5 (restarts the scene), judge.

extends Node

# --- Player feel ---
const PLAYER_SPEED := 230.0
const PLAYER_ACCEL := 1900.0
const PLAYER_FRICTION := 2400.0
const JUMP_VELOCITY := -430.0
const GRAVITY := 1250.0

# --- Attack phases (seconds) — committed = real startup + real recovery ---
const ATK1_STARTUP := 0.09
const ATK1_ACTIVE := 0.07
const ATK1_RECOVERY := 0.17
const ATK1_DAMAGE := 10
const ATK1_POWER := 1

const ATK2_STARTUP := 0.10
const ATK2_ACTIVE := 0.08
const ATK2_RECOVERY := 0.25
const ATK2_DAMAGE := 20
const ATK2_POWER := 2  # finisher wins clashes vs light strikes, loses vs heavies

const COMBO_BUFFER := 0.14  # seconds an attack press is remembered during a combo

# --- Clash resolution (power comparison) ---
const CLASH_LOCK_TIME := 0.7     # double-clash weapons-lock duration
const PLAYER_STAGGER_TIME := 0.5
const ENEMY_STAGGER_TIME := 0.8

# --- Juice ---
const HITSTOP_HIT := 0.07
const HITSTOP_CLASH := 0.09
const HITSTOP_DEFLECT := 0.04
const SHAKE_ATTACK2 := 2.0
const SHAKE_CLASH := 5.0
const SHAKE_HURT := 3.0

# --- Enemies ---
const MELEE_HP := 40
const MELEE_WALK := 60.0
const MELEE_AGGRO := 300.0
const MELEE_LIGHT_WINDUP := 0.45   # amber flash
const MELEE_HEAVY_WINDUP := 0.85   # red flash — power 2
const MELEE_ACTIVE := 0.12
const MELEE_RECOVER := 0.55
const MELEE_DAMAGE := 12
const MELEE_COOLDOWN := 1.1

const SHOOTER_HP := 30
const SHOOTER_WINDUP := 0.5
const SHOOTER_COOLDOWN := 2.2
const ORB_SPEED := 170.0
const ORB_SPEED_DEFLECTED := 360.0
const ORB_DAMAGE := 8

# --- World ---
const FLOOR_Y := 520.0
const ARENA_MIN_X := 40.0
const ARENA_MAX_X := 920.0
const PLAYER_HP := 100
