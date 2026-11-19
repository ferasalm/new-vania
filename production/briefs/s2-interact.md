# BRIEF: S2 Interact (proto v4 "area", session 1, parallel with S1)

You are implementing slice **S2 Interact** for `prototypes/feel-v3` (Godot 4.7.2, GDScript).
Work ONLY in the worktree given via --dir. Never run git commands; the lead reviews and commits.
You cannot run Godot or any command: return every file you create or change IN FULL, paths
relative to the worktree root (e.g. `prototypes/feel-v3/pickup.gd`).

## Attached files (everything you may assume)
contract.md (whole - esp. sections S2 Interact, 2.6 data schemas, 2.7 formulas, 8 rulings),
rpg-items.md (whole - sections 3.5, 3.5b, 3.7, 3.8, 3.9, 3.13 are your design authority),
tests_v4/t_interact_ui.gd (LOCKED test = your executable spec; its S2 half must pass, the UI
half belongs to S3 and stays failing), interact.gd + loot.gd (the S0 first versions you now
own), main.gd (for the named hook lines only), player.gd, arena.gd, touch.gd, game.gd,
data/items.json, data/gear.json, data/enemies.json, rpg.gd (R's item/gear/scrap API).

## The locked test is the bar
Never edit anything under `tests_v4/`, nor smoke.gd, hazard_test.gd, climb_test.gd. If a test
expectation contradicts rpg-items.md or the contract, STOP and report; do not bend the code.
After S2, `res://tests_v4/t_interact_ui.tscn` must PASS on its interact half (everything from
"walking across an item" through "a taken item stays taken after re-entry" and
"taking LEXICON CORE gives R.has('lexicon_core')"). The UI checks (pause menu, tabs, rows,
CHARACTER/ITEMS/EQUIPMENT/MAP, minimap, level-up offer, name plate, dialog box, menu_swallow,
debug_tap) belong to S3 and keep failing - do not try to fix them, and list them as expected
failures in your report. smoke.tscn must stay SMOKE PASS 135/135 with no edits to it.

## What S2 builds (contract S2; rpg-items.md is the design authority)
- **Up is the use key (decision 1)**: items, gear and abilities are taken with Up within
  `pickup_reach` 24 px (12-48, 2); walking through never takes; the NEAREST target wins when
  several are in reach; Up together with attack on the same frame is the special attack, not
  a pickup. Levers, terminals and talk targets go through the same interact registry
  (interact.register/unregister/nearest/press + signal used; targets cleared on room_entered).
- **The pickup card (decision 9, rpg-items 3.13)**: new pickup_card.gd -
  `card.present(item_id) -> String` (awaitable: "ok"|"equip_now"|"later"), `card.active`,
  `card.lock_left`, `card.debug_close(choice := "ok")`. The game pauses, screen dims to 70%,
  the item flies to her (0.1 s), chime + voice event; at 0.15 s the card fades in, 232 x 112,
  picture at 2x left, tag (ITEM/ABILITY/WEAPON/HARNESS/MODULE), NAME, description, one effect
  line with {key} replaced through T.v. It cannot close for `pickup_lock` 0.5 s (0-1.5, 0.05),
  then J/K/Up/Enter/tap closes. Gear cards offer EQUIP NOW (J) and LATER (K) - EQUIP NOW fits
  the piece into its first FREE fitting slot (a harness into harness1/harness2, a module into
  module1/module2). She must not jump when the card closes. A missing icon PNG must not crash
  the card (icon paths may point at not-yet-drawn files; the art pass comes later).
- **The special show**: about `special_pickup_time` 1.6 s (0.6-3, 0.1) BEFORE the card for
  abilities, gear and weapons (world freezes, item rises with light rays, she raises her hand,
  flash + ring + sparks, a colour line with one word line), using `player.lock("special")`;
  ordinary items skip it and open the card at once. `input_swallow` 0.15 s after closing.
- **Orbs and scrap by touch (decision 1)**: soul orbs give `mp_pickup` MP (not taken at full
  MP), scrap adds `scrap_per_pickup` 10 (20-300, 10 on a `scrap_max` 100 gauge; not taken when
  full). Both are touch-only, no card.
- **Drops (rpg-items 3.5 + 3.5b)**: loot.gd owns the drop table - `loot.roll_drops(kind, at,
  respawned) -> Array`, deterministic with R.rng; `loot.spawn_pickup(item_id, at, opts)`,
  `loot.live`. Every kill rolls its enemies.json drops (chance keys through T.v), a soul orb
  (`soul_orb_chance_weak` 0.6 weak / always otherwise), and machine scrap for every kind at
  `scrap_chance(scrap_drop_base, scrap_drop_low, hp_share)` = clamp(base + low*(1-hp_share),
  0, 1) with scrap_drop_base 0.10 (0-1, 0.01) and scrap_drop_low 0.35 (0-1, 0.01) - the rate
  rises at low health; returned enemies roll rare drops at `rare_respawn_mult` (the rare
  TABLE of 3.5b belongs in enemies.json/items.json as data; the TANK HEART cap 2).
  `drop_life` 12 s, `rare_life` 20 s, blinking the last 3 s. Drop item ids must exist in
  items.json (add the 3.5b rare consumables and minor gear as items now).
- **data/items.json and data/gear.json**: fill them out per rpg-items 3.8/3.9 and 3.13 (the
  S0 stubs already carry the right ids and slot rules - complete descriptions, effect keys,
  the rare drops, and make sure `suture.refill_at_terminal` stays FALSE: Sutures are NEVER
  refilled, ruling 1. A terminal must leave the Suture count unchanged).
- **The quick key**: the `quick` action (H) uses the quickslot item (default suture): one
  Suture heals `suture_heal` 40, refused at full HP (dull click), count clamped to
  `suture_max` 9.
- **SELF-REPAIR (decision 7, rpg-items 3.7, contract S2 numbers)**: new repair.gd -
  `repair.active`, `signal stopped(reason)` ("done"|"hit"|"moved"|"empty"),
  `repair.debug_hold(sec)`. She stands still on the floor and holds the `repair` action (G):
  after `repair_hold` 0.6 s she is locked in the repair state and heals `repair_rate` 20 HP
  per second, paid `repair_cost` 1.0 scrap per HP (EN does not refill while repairing).
  Moving, a hit, running out of scrap or full health stops it with the right reason.
  Requires at least 1 scrap to start.
- **Hooks (only these lines)**: arena.gd 1 line - the boss reward becomes
  `G.main.loot.spawn_pickup(item, at)` (this removes the touch-pickup scythe/relic and with
  them the hint texts at main.gd:234 "GRIP SERVOS ONLINE -" and main.gd:436 "E (or SWAP)" -
  delete those two main.gd text lines). touch.gd: none (the bubble already uses
  main.interact_target()).
- **tuning.d/items.json**: pickup_reach 24 (12-48, 2), pickup_lock 0.5 (0-1.5, 0.05),
  special_pickup_time 1.6 (0.6-3, 0.1), input_swallow 0.15 (0-0.5, 0.05), drop_life 12
  (4-30, 1), drop_suture_weak 0.04 (0-1, 0.01), drop_suture_other 0.1 (0-1, 0.01), orb_magnet
  0 (0-64, 4), scrap_max 100 (20-300, 10), scrap_per_pickup 10 (1-50, 1), scrap_drop_base
  0.10 (0-1, 0.01), scrap_drop_low 0.35 (0-1, 0.01), repair_hold 0.6 (0.1-2, 0.05),
  repair_rate 20 (5-80, 5), repair_cost 1.0 (0.2-5, 0.1), heal_hold 0.15 (0-0.5, 0.05) -
  plus the rare-drop keys rpg-items section 7 lists (rare_chance_*, rare_respawn_mult 0.5,
  rare_stack_max 3, rare_life 20, tank_heart_hp 20, tank_heart_max 2, and the per-rare effect
  keys). Same 6-field schema; never duplicate a key from tuning.json or tuning.d/rpg.json.
- **assets/audio/events.d/items.json**: the card chime, show sting, equip click, the repair
  ticks, the dull click. Silent when a file is missing.
- **assets/items/*.png**: do NOT draw icons; point icon paths at
  `res://assets/items/<id>.png` and let the card handle a missing texture. The art pass draws
  them later.

## Hard rules
- Match existing style: tabs, `# PROTOTYPE - NOT FOR PRODUCTION` header on new files, plain
  GDScript, values through T.v, no class_name on new scripts, no paid services, no art
  generation.
- Parallel-slice discipline: your owner files are interact.gd, loot.gd, pickup.gd,
  pickup_card.gd, repair.gd, data/items.json, data/gear.json, tuning.d/items.json,
  assets/audio/events.d/items.json, plus the named hook lines in arena.gd and main.gd.
  S1 owns rooms, room.gd, props, respawn and the rest - do not touch them.
- Do not break what works: smoke.tscn stays 135/135; hazard_test and climb_test still pass
  without edits. If smoke pins something your change breaks (the relic is now a card pickup),
  keep the relic BEHAVIOUR working through the new pickup path and report the difference.

## What the lead verifies after you return
- t_interact_ui PASS on its interact half (exit still 1 overall is fine while the UI half
  fails; the summary must show 0 failed among the interact checks), smoke 135/135,
  hazard/climb pass, diff touches only S2 owner files + the named hook lines.

## Report
End with: what you built, which t_interact_ui checks pass now and which stay for S3, and
anything open with a reason.
