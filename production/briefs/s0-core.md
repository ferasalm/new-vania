# BRIEF: S0 Core (proto v4 "area", session 1)

You are implementing slice **S0 Core** for the game in `prototypes/feel-v3` (Godot 4.7.2, GDScript).
Work ONLY inside the worktree you are given (`--dir`). Never run git commands; the lead reviews
your diff and commits. Do not touch any file outside the owner list below.

## Attached files (you cannot read the disk; everything you need is attached)
The lead attaches: contract.md (whole), rpg-items.md (whole), the three locked tests
t_data.gd / t_math.gd / t_rpg.gd, and the code you will modify: main.gd, player.gd, game.gd,
audio.gd, hud.gd, hazard.gd, boss.gd, tuning.gd, tuning_panel.gd, project.godot, tuning.json.
Work from those; do not assume any other file's contents.

## The locked tests are the bar
- The tests are locked (`tests_v4/locks/step0.json`). You must NEVER edit anything under
  `tests_v4/`, nor `smoke.gd`, `hazard_test.gd`, `climb_test.gd`. A builder that edits a test
  fails the slice outright.
- The tests currently FAIL on purpose. After S0: `t_data`, `t_math` and `t_rpg` must PASS
  (exit 0). `t_interact_ui`, `t_world`, `t_bosses` stay FAIL (their features are later slices) -
  do not try to fix them and do not worry that they fail.
- If you believe a test's expectation contradicts the contract, do NOT edit the test and do NOT
  bend the implementation to a guess: stop and report the conflict in your final answer.

## What S0 builds (contract S0, with the lead rulings applied)
- **New autoloads**: `W` (world_state.gd), `R` (rpg.gd), plus `Db` (db.gd: `Db.table(name)`
  returning the parsed data file; data files are read ONLY through it). Register in
  `project.godot` (keep T, G, Sfx). Do NOT declare `class_name W` or `class_name R`
  (autoload names must not collide with global classes).
- **W**: signals room_entered/enemy_hit/enemy_killed/player_hurt/player_down/boss_started/
  boss_down/shift_changed/flag_changed; vars flags, visited, taken, sheet, saved_room, unit,
  best_times; functions flag/set_flag/mark_taken/is_taken/meta/title/room_list/cell_of/
  snapshot/restore/start_shift/end_shift/debug_set (exact signatures in contract S0).
- **R**: signals xp_changed/leveled/stats_changed/items_changed/gear_changed/scrap_changed;
  vars level, xp, points, alloc, items, owned_gear, equip, scrap, quickslot, names_seen, rng;
  functions max_hp/max_en/max_mp/atk/def/special_pct/hit_damage/taken/award_kill/add_xp/
  spend/auto_allocate/has/set_owned/count/add_item/use_item/equip_gear/gear_effect/add_scrap/
  refill_at_terminal/snapshot/restore/reset/debug_set/debug_seed.
- **Stat names (ruling 3 overrides the contract's STR/VIT/MAG/END)**: ids `vigor, power, guard,
  stamina, magic` with labels VIGOR, POWER, GUARD, STAMINA, MAGIC. Per point: +10 HP
  (`vigor_hp` 10), +8% ATK (`power_atk` 8), +3 DEF (`guard_def` 3), +8 EN (`stamina_en` 8),
  +8% special and +6 MP (`magic_special` 8, `magic_mp` 6). `levels.json` stats ids use these;
  `auto_order` = vigor, power, guard, vigor, power, magic, vigor, power, guard, stamina.
  `alloc` uses the same ids. DEF caps at `def_cap` 40; max HP never below `max_hp_floor` 50;
  level-ups refill HP/EN/MP when `levelup_refill` is 1; `points_per_level` 2; `level_cap` 10.
- **Tuning**: S0's new keys go in a new `tuning.d/rpg.json` (same 6-field schema as
  tuning.json: value/min/max/step/label/help; `tuning.gd` merges tuning.json + every
  tuning.d/*.json; a key must never appear in two files). Values per contract S0 with these
  overrides from the rulings and tests: `suture_max` 9 (1-9, 1) - Sutures are never refilled
  (ruling 1) and she must be able to carry all 8 that exist; item `suture.refill_at_terminal`
  must be `false`. Include xp_curve_step 10, level_cap 10, start_level 1, points_per_level 2,
  def_cap 40, max_hp_floor 50, levelup_refill 1, area_damage_mult 0.75, xp_respawn_mult 0.5,
  the xp_* keys for all nine enemies plus xp_boss 50 / xp_unmuzzled 30 / xp_arnetria 80,
  suture_heal 40, coupler_damage 5, coupler_hp -40, governor_hp 10, regulator_damage 5,
  cerement_def 8, pall_mp 15, pall_orb_mult 1.5, tether_scrap 4, tether_repair 2 (the gear
  keys rpg-items.md section 7 lists; the last five are consumed by S2 but the keys must exist).
- **rpg_math.gd**: static formulas with the EXACT signatures of contract 2.7
  (xp_total, level_for, dealt, special, taken, scrap_chance; round half up; minimum 1).
- **Data stubs** (schemas in contract 2.6, read only through Db):
  - `data/levels.json`: base hp_max_key player_hp / en_max_key energy_max / mp_max_key mp_max;
    the five stats with label/help/gives pointing at the real tuning keys; auto_order as above.
  - `data/items.json` stub with suture, lexicon_core, wall_jump, elegy_013, soul_orb, scrap.
    suture: type consumable, max_key suture_max, use.heal_hp_key suture_heal, touch_take false,
    refill_at_terminal false (ruling 1). Abilities carry `grants` (their own id).
    soul_orb type orb + touch_take true; scrap type material + touch_take true.
  - `data/gear.json` stub with the seven rpg-items v2 pieces: coupler_034 (module),
    governor_207 (module), regulator_000 (module), restore_module (fixed CORE, no slot),
    cerement_112 (harness), pall_090 (harness), tether_06 (harness). Effects use ONLY the
    closed list atk_add_key, def_add_key, hp_max_add_key, en_max_add_key, mp_max_add_key,
    mag_add_key, orb_reach_add_key, scrap_gain_mult_key, rebuild_here_key, each pointing at a
    real tuning key. R.equip_gear enforces: modules fit module1/module2 only, harnesses fit
    harness1/harness2 only, one id in one slot, COUPLER and REGULATOR never coexist, the
    restore module cannot be slotted, losing max HP clamps current HP, unequipping never heals.
  - `data/enemies.json` stub: the nine ordinary enemies (ghost, leech, spitter, hound, choir,
    moth, scribe, crab, warden) plus the three bosses (pallbearer: reward elegy_013, flag
    beaten_pallbearer, music_cut true; unmuzzled: reward wall_jump; arnetria). Fields per the
    schema: name, kind, boss, script, glyph, xp_key, weak, drops, bestiary. weak=true for
    ghost, leech, spitter, hound; false for the rest. Every xp_key must exist in tuning;
    every drop item must exist in items.json.
  - `data/rooms_meta.json` stub: cell_tiles [24,14]; sheets before/after/restored; the BEFORE
    sheet lists today's ten rooms with code, title, cell (4 ints), entry, save, music, exits
    (side L/R/U/D, at, to, kind from the closed list door/open/hole/tunnel/lever_door/
    boss_door/sealed_x/shutter/bricked), marks (types item/lever/winch/candle/terminal/organ/
    talk/boss). Use today's rooms as they are in main.gd's ROOMS data (same rooms, same doors).
- **spawner.gd**: `static enemy(kind, feet) -> Node2D` (builds the right enemy for every
  enemies.json id, today's enemy scripts for today's kinds) and
  `static boss(id, feet, room_size) -> Node2D` (today's boss for pallbearer; null-safe for
  ids that do not exist yet). New enemies carry the full interface: setup, hurt_rect, can_hurt,
  damage, touched_player, take_hit, kind, hp.
- **arena.gd**: var boss, mode ("normal"|"recall"), fight_time, attach(b), dying(b),
  down(b, at), signal fight_ended(id, won, seconds), debug_win().
- **Extraction (main.gd <= 600 lines today 872)**: move progress/state out of main.gd and
  player.gd into W and R per contract 2.1-2.3. main keeps forwarding properties:
  `has_elegy` -> R.has("elegy_013"), `lever_library` -> W.flag("lever_library"). main gains a
  `SYSTEMS` registry (name -> file path) and creates each system whose file exists; main.gd
  keeps debug_enter(room, side := "left", shifted := false).
- **Hooks (only these lines)**: player.gd reads max_* through R; damage through R.hit_damage
  and R.taken (take_hit(damage, from_x, src := "enemy")); player.lock/unlock/is_locked/
  debug_set (keys hp, energy, mp, facing, state, pos); hud.gd reads through R; hazard.gd passes
  src "trap"; boss.gd passes src "boss"; main _move_shots src "shot"; game.gd adds the input
  actions quick (H), repair (G, held), map (M); audio.gd gains events.d-style event files and
  stays silent on unknown names; tuning.gd merges tuning.d/*.json; tuning_panel.gd gains an
  RPG tab showing the rpg.json rows.
- Also write the first (pure-move) versions of interact.gd, loot.gd, ambience.gd and
  projectiles.gd per contract S0's interface lines (interact.register/nearest/press + signal;
  loot.spawn_pickup/roll_drops(kind, at, respawned) deterministic with R.rng + live array).
  Their full behaviour is S2's - S0 only needs the seams and the deterministic roll entry
  point (orbs/scrap/suture chances from enemies.json + tuning).

## Hard rules
- Style: match the existing files (tabs, `# PROTOTYPE - NOT FOR PRODUCTION` header on new
  files, plain GDScript, no class_name on the new autoload scripts, no singletons beyond the
  autoloads, values read through T.v never hardcoded).
- Behaviour must not change: `res://smoke.tscn` must still print `SMOKE PASS passed=135 failed=0`
  (exit 0), and `res://climb_test.tscn` + `res://hazard_test.tscn` must still pass, with
  NO edits to those test files. If S0 needs a behaviour change that smoke pins, stop and report.
- Numbers in the brief beat the contract where they differ (they encode the rulings).
- Windows PowerShell: no `&&` (use `;`). Always run an import before a test batch.

## How you work
You cannot run Godot or any command: you read the attached files and RETURN every file you
create or change IN FULL (the harness writes them into the worktree at the paths your blocks
name - use paths relative to the worktree root, e.g. `prototypes/feel-v3/world_state.gd`).
Prefer small, precise edits to the attached files; new files are written whole.

## What the lead verifies after you return (you do not run these)
- smoke.tscn: SMOKE PASS passed=135 failed=0 (exit 0), no edits to smoke.gd.
- tests_v4/t_data.tscn, t_math.tscn, t_rpg.tscn: PASS (exit 0), with no edits to the tests.
- hazard_test.tscn and climb_test.tscn still pass.
- main.gd <= 600 lines; the diff touches only the owner files and the named hook lines.

## Report
End your answer with: a short list of what you built, any contract-vs-test conflict you hit
(do not resolve it yourself), and anything left open with the reason.
