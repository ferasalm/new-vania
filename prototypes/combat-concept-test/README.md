# PROTOTYPE - NOT FOR PRODUCTION
# Combat Concept-Test — "Five Errands for the Devil"

## Question

Does committed SotN-weight combat — two-hit combo with real startup/recovery, the clash
(power-comparison parry), and projectile deflect — feel intrinsically rewarding on direct
controls? Full context: `SPEC.md`.

## Run

- **Editor**: open this folder (`prototypes/combat-concept-test/`) in Godot 4.7.2 → F5.
- **Headless sanity check** (no SCRIPT ERROR lines = healthy):

```
C:\Users\AUC\opencode-workspace\tools\Godot\Godot_v4.7.2-stable_win64.exe --headless --path prototypes/combat-concept-test --quit-after 120
```

## Controls

| Input | Action |
|---|---|
| A/D or ←/→ | move |
| SPACE / W / ↑ | jump (fixed arc, no variable height) |
| J / Z | attack — J J chains the two-hit combo |

## Designer test protocol (~10 minutes)

1. **Kill 10 dummies** (they respawn). Notice: do you WANT to keep going?
2. **Counter-clash**: attack during a dummy's amber/red windup flash — does the timing
   window feel fair or lucky? (Hit them mid-windup → staggered for 0.8s = free punish.)
3. **Power read**: let a dummy start a strike, then clash it with ATK1 (single J — you
   should LOSE: staggered + half damage), then with ATK2 (J J — should LOCK even).
   Amber windup = light (power 1), red = heavy (power 2). Is the read legible?
4. **Deflect**: swat the shooter's cyan orb with an active swing — it returns amber,
   faster, and hurts whatever it hits (shooter included). Satisfying? Does the returned
   orb hitting another enemy matter to you?
5. **Tune freely** in `tunables.gd` (all windows in seconds). Note every value you change.

## Clash table (what the code implements)

| Situation | Result |
|---|---|
| Player swing connects during enemy WINDUP | COUNTER-CLASH — enemy interrupted + staggered 0.8s |
| Attack powers: player > enemy (ATK2 vs light) | Enemy staggered |
| Powers equal (ATK1 vs light, ATK2 vs heavy) | DOUBLE CLASH — both locked 0.7s |
| Player < enemy (ATK1 vs heavy) | Player staggered 0.5s + half damage |
| Player not attacking during enemy strike | Full damage |
| Swing connects with an orb | DEFLECT — orb returns friendly, 15 dmg to enemies |

## Tuning map (`tunables.gd`)

| Want to change… | Touch… |
|---|---|
| Combo responsiveness | `COMBO_BUFFER` (0.14s press memory), `ATK*_STARTUP/ACTIVE/RECOVERY` |
| Clash windows / lock | `MELEE_LIGHT_WINDUP` (0.45), `MELEE_HEAVY_WINDUP` (0.85), `CLASH_LOCK_TIME` |
| Impact read | `HITSTOP_HIT/CLASH/DEFLECT`, `SHAKE_*` |
| Dummy pacing | `MELEE_WALK`, `MELEE_COOLDOWN`, `MELEE_DAMAGE`, heavy/light ratio (30% in `enemy_melee.gd`) |
| Orb threat | `SHOOTER_COOLDOWN`, `ORB_SPEED`, `ORB_SPEED_DEFLECTED`, `ORB_DAMAGE` |

## Implementation notes (interpretations, keep in mind when judging feel)

- **Committed movement**: horizontal control is locked during swing startup/active/recovery
  and you plant on the spot (grounded); airborne swings keep momentum (committed arc).
  No jump-cancel. Facing locks at swing start.
- **Combo buffer**: a press during ANY ATK1/ATK2 phase is remembered for `COMBO_BUFFER`
  (0.14s); the chain fires the instant recovery begins (or immediately if pressed during
  recovery). Note: a press in the very first frames of ATK1 startup expires before
  recovery starts (0.09 + 0.07 = 0.16 > 0.14) — raise `COMBO_BUFFER` if early double-taps
  should chain.
- **Counter-clash deals no damage** (spec-exact) — the reward is the 0.8s stagger window
  for a free combo. If it feels thin, tell the report, not the code yet.
- **Clash resolution lives in `hurt()`**: the enemy's strike check skips damage while the
  player is mid-swing, so a clash and a strike never resolve twice in the same exchange.
- **Respawns**: both dummy types respawn 1.5s after death at an arena edge (shooter at
  hover height) — keeps the 10-kill session flowing and the deflect target available.
- **Visual readouts** (greybox doctrine): translucent cyan rect = your active hitbox;
  amber/red body flash + lean-back = windup (light/heavy); pale-cyan tint = staggered
  (either side); red translucent rect = enemy strike reach; growing amber eye = orb charge.
- Small feel values that are NOT in `tunables.gd` (knockback magnitudes, melee engage
  distance, shooter retreat/strafe speed, flash times) live as local consts at the top of
  each script — `tunables.gd` was marked DONE and left untouched.

## Files

`project.godot` · `main.tscn` · `tunables.gd` · `main.gd` (orchestrator/HUD/juice) ·
`player.gd` · `enemy_melee.gd` · `enemy_shooter.gd` · `projectile.gd` · `README.md`

## After the playtest

Fill `REPORT.md` per the /prototype skill template. Verdict per SPEC.md success criteria:
**PROCEED** (mostly yes → /design-system combat, formal GDD) · **PIVOT** (mixed → adjust
rules, re-test) · **KILL** (no → rethink combat direction).
