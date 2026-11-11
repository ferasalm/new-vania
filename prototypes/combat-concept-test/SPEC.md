# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does committed SotN-weight combat (combo + clash + deflect) feel rewarding?
# Date: 2026-11-11
# Status: CODE COMPLETE (9/9 files) — smoke-tested (headless boot, 600-frame soak, 20s
# synthetic-input combat driver — zero script errors). Awaiting designer playtest → REPORT.md.

# Prototype 1: Combat Concept-Test — BUILD SPEC (handoff document)

Game: "Five Errands for the Devil" — SotN-school metroidvania. This prototype tests the
game's #1 design bet BEFORE any formal GDD exists (approved fast lane, 2026-11-11).

## Core question

Does committed SotN-weight combat — two-hit combo with real startup/recovery, the clash
(power-comparison parry), and projectile deflect — feel intrinsically rewarding on direct
controls? Success is measured, not vibes: clash window fairness, combo buffer
responsiveness, hit-stop impact read, and the subjective "want to keep fighting after
10 dummy kills" test.

## Build state

| File | State | Notes |
|---|---|---|
| `project.godot` | ✅ DONE | Godot 4.7.2, main scene res://main.tscn, Tunables autoload, 960×540 canvas_items stretch, gl_compatibility |
| `main.tscn` | ✅ DONE | Single Node2D root + script res://main.gd (everything else spawns in code) |
| `tunables.gd` | ✅ DONE | ALL feel constants (player, attacks, clash, juice, enemies, world) |
| `main.gd` | ✅ DONE | Orchestrator: InputMap built in code (AD/arrows move, SPACE/W/Up jump, J/Z attack), spawns player + 2 melee + 1 shooter, Camera2D, HUD (HP bar, dummies-down counter, PANDORA designation death counter, popups, hint line), hitstop() (Engine.time_scale 0.05 + ignore_time_scale timer), shake, on_clash() popups, floor draw. Expects res://player.gd etc. via preload — DO NOT change its API: player.main, player.hp, player.position; main.hitstop/.do_shake/.popup/.register_kill/.register_player_death/.on_player_hurt/.on_clash(kind)/.enemies not required — enemies find each other via group "enemies" |
| `player.gd` | ✅ DONE | Buffer chains at recovery start; committed movement lock; clash participation via hurt() power param |
| `enemy_melee.gd` | ✅ DONE | All clash branches per table; amber/red windup flash + rising lean; 1.5s edge respawn |
| `enemy_shooter.gd` | ✅ DONE | Hover/retreat/strafe; cooldown→windup→fire loop; 1.5s respawn |
| `projectile.gd` | ✅ DONE | Deflect on active hitbox (flips toward facing); friendly orbs deal 15 |
| `README.md` | ✅ DONE | Run instructions + test protocol + tuning map + interpretation notes |

After all files exist: smoke-test headless
`C:\Users\AUC\opencode-workspace\tools\Godot\Godot_v4.7.2-stable_win64.exe --headless --path prototypes/combat-concept-test --quit-after 120`
(fix any script errors), then hand to the designer for playtest, then fill REPORT.md.

## Mechanics contract (build EXACTLY this)

### Player (player.gd, extends CharacterBody2D, class_name ProtoPlayer)
- `var main: Node` injected by main.gd after `.new()`. Add self to group "players".
- Movement: left/right via "move_left"/"move_right"; accel/friction from Tunables; gravity when airborne; `move_and_slide()`.
- Jump: "jump" pressed + on floor → velocity.y = JUMP_VELOCITY. Fixed arc (no variable jump — committed weight).
- Facing: from last horizontal input direction (+1/-1).
- Two-hit combo, phases timed with float countdowns in `_physics_process(delta)`:
  - IDLE → press "attack" → ATK1 (startup ATK1_STARTUP → active ATK1_ACTIVE → recovery ATK1_RECOVERY → IDLE)
  - Pressing "attack" ANY time during ATK1 (store buffer, COMBO_BUFFER expiry) → after ATK1 recovery begins (chain at recovery start feels better: chain immediately into ATK2 startup when buffer present at recovery-start) → ATK2 (same phase pattern)
  - Pressing "attack" during ATK2 → buffer → chains back to ATK1 (infinite 1-2 loop allowed)
- Attack hitbox during ACTIVE frames only: `Rect2(global_position + Vector2(14 if facing>0 else -48, -30), Vector2(34, 40))`
- Damage/power: ATK1 = ATK1_DAMAGE/ATK1_POWER (1), ATK2 = ATK2_DAMAGE/ATK2_POWER (2)
- Each swing hits a given enemy once (track hit set per swing).
- HP from Tunables.PLAYER_HP. `hp` is a public int (main reads it).
- Taking damage: hp -= dmg, small knockback, white flash 0.12s, main.on_player_hurt(); hp ≤ 0 → main.register_player_death(), teleport to (200, FLOOR_Y), hp = full.
- _draw() visuals (on-doctrine greybox): body rect 20×34 steel-cyan #0D7B89 with 2px outline #050912; head 12×10; during ACTIVE frames draw the attack hitbox as a translucent cyan rect; white flash = draw everything near-white while flash timer > 0.

### Melee enemy (enemy_melee.gd, extends CharacterBody2D, class_name ProtoEnemyMelee)
- `var main: Node` injected; add self to group "enemies".
- State machine: IDLE → APPROACH (walk toward player if distance < MELEE_AGGRO) → COOLDOWN (after recover, MELEE_COOLDOWN) → WINDUP → STRIKE → RECOVER → back to APPROACH.
- Strike selection on entering WINDUP: 70% LIGHT (MELEE_LIGHT_WINDUP, power 1, amber flash) / 30% HEAVY (MELEE_HEAVY_WINDUP, power 2, red flash).
- Telegraph doctrine: windup = whole body flashes amber (light) or red (heavy) — color-flash + a rising "wind-up" shape lean (no opacity pulsing).
- STRIKE: lunge 40px toward player during active frames; strike hitbox = Rect2(global_position + Vector2(face>0? 10 : -42, -28), Vector2(32, 36)); overlap player body rect (Rect2(player.global_position + Vector2(-10,-34), Vector2(20,44))) → damage MELEE_DAMAGE + knockback, once per strike.
- Gravity applies (grounded walker), MELEE_WALK speed.
- HP MELEE_HP. Public func `hurt(dmg: int, source_power: int, from_player_attack: bool)`:
  - If state == WINDUP when a player attack connects → COUNTER-CLASH: interrupt → STUNNED (ENEMY_STAGGER_TIME), main.on_clash("strong").
  - If player attack active frames intersect this enemy's STRIKE active frames → power comparison: player_power > my_power → interrupted + STUNNED, main.on_clash("strong"); equal → DOUBLE CLASH: BOTH locked (me STUNNED CLASH_LOCK_TIME, player told via `player.stagger(CLASH_LOCK_TIME)`) main.on_clash("even"); player_power < my_power → player.stagger(PLAYER_STAGGER_TIME) + player takes half damage, main.on_clash("lose").
  - Otherwise (normal hit, enemy not striking) → hp -= dmg, white flash, small knockback.
  - hp ≤ 0 → main.register_kill(), queue_free(); main respawns (timer in enemy is fine: after 1.5s a new instance at random arena edge — simplest: main._spawn_melee(randf range) via a deferred call; or enemy requests respawn through main).
- _draw(): grey-violet body (#5a5566) with outline, amber/red flash overrides windup telegraph, lunge offset during strike.

### Shooter enemy (enemy_shooter.gd, extends CharacterBody2D, class_name ProtoEnemyShooter)
- Flying: no gravity; hover at fixed y (300); keep distance: if player.x within 220 → move away; strafe slowly otherwise.
- Loop: cooldown SHOOTER_COOLDOWN → WINDUP (SHOOTER_WINDUP, amber flash) → fire: main.spawn_orb(global_position, direction_to_player) → cooldown.
- HP SHOOTER_HP, `hurt()` same as melee (no clash states — normal hits only; deflected orbs also damage it).
- Add to group "enemies".

### Projectile (projectile.gd, extends Node2D, class_name ProtoOrb)
- `var main: Node`, `var velocity: Vector2`, `var friendly := false`.
- _physics_process: move; despawn outside arena bounds (x < -50 or > 1010, y > 600).
- If not friendly: if player attack ACTIVE hitbox contains position → DEFLECT: velocity = -velocity.normalized() * ORB_SPEED_DEFLECTED (flip toward facing direction of the player), friendly = true, turn amber, main.on_clash("deflect").
- If not friendly: dist to player center < 16 → player takes ORB_DAMAGE, queue_free.
- If friendly: check every node in group "enemies": hurt-rect contains position → enemy.hurt(15, 0, false), queue_free.
- _draw(): 10px circle, cyan #0d7b89 (friendly: amber #ffb45f) + outline.

### API surfaces main.gd already provides (DO NOT rename)
`hitstop(sec)`, `do_shake(amt)`, `popup(text, color)`, `register_kill()`, `register_player_death()`, `on_player_hurt()`, `on_clash(kind: String)` — kinds: "strong"/"even"/"lose"/"deflect". Spawn helpers: `_spawn_melee(x)`. For the orb: add `spawn_orb(pos, dir)` to main.gd when writing projectile.gd (small addition, allowed).

## Clash rules summary (the design being tested)

| Situation | Result |
|---|---|
| Player attack connects during enemy WINDUP | COUNTER-CLASH — enemy interrupted + staggered |
| Attack powers: player > enemy | Enemy staggered |
| Attack powers: equal (ATK1 vs light, ATK2 vs heavy) | DOUBLE CLASH — weapons lock, neither staggered, flashy |
| Attack powers: player < enemy (ATK1 vs heavy) | Player staggered + half damage |
| Player not attacking during enemy strike | Player takes full damage |
| Attack connects with orb | Deflect — orb returns, friendly, hits enemies |

## Test protocol (designer plays, ~10 minutes)

1. Kill 10 dummies (they respawn). Notice: do you WANT to keep going?
2. Try counter-clashing (attack during amber/red windup) — does the timing window feel fair or lucky?
3. Try clash-vs-heavy with ATK1 (should lose) then ATK2 (should lock even) — is the power read legible?
4. Deflect orbs — satisfying? does the returned orb hitting another enemy matter to you?
5. Tune freely in tunables.gd (windows are in seconds). Note every value you change.

## Success criteria → REPORT.md verdict

- Clash window readable & fair (not luck) · combo buffer ≥120ms feels responsive · 60–90ms hit-stop reads as impact · "want to keep fighting" = yes.
- Mostly yes → PROCEED (then /design-system combat, formal GDD). Mixed → PIVOT (adjust rules, re-test). No → KILL combat direction, rethink.

## Report

Fill `prototypes/combat-concept-test/REPORT.md` per the /prototype skill template after playtest. Review mode is lean — no director gate; the report verdict stands.
