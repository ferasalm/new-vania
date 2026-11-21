# Build contract: proto v4, sessions 1 to 3

Status: draft for the user's review (waiting on user). Author: lead-programmer. Date 2026-11-19.
Game: `prototypes/feel-v3` (Godot 4.7.2, GDScript). Branch today: `feat/proto-v4-backtrack`.
Sources: the lead's brief, `map.md`, `rpg-items.md`, `bosses-story.md`, `sprites.md` (this folder), and the code.
`decisions.md` did not exist when this was written. Where the sources disagree, this order wins:
**decisions.md > the lead's brief > map.md > rpg-items.md / bosses-story.md**. Section 7 lists every
disagreement that changes code, with the default this contract uses.

## In plain words

- We split the work into 11 parts ("slices"). Each part owns its own files, so builders working at the same time do not get in each other's way.
- Session 1 lays the base: her level, XP and items are kept in one place that survives room changes. All 25 rooms and the map data get built, and she takes things by pressing Up.
- Session 2 adds the pause menu (map, character, items, equipment), the corner map, two lab machines and her new animations.
- Session 3 adds the three boss fights, the end of the shift, boss refights at the save terminal, and her voice.
- Tests are written before the code for each part. They are then locked, so a builder cannot weaken them.
- Every number you can feel stays a slider in the F1 panel. Each part adds its own slider page.
- First we prove her drawings: one 5-frame jump, which you approve before 100 more frames get drawn.
- The game stays playable at the end of each session.

---

## 1. Ground rules for every builder

1. Work only in your slice's worktree. Edit only your **owner files**. In a **hook file**, add at most the lines
   listed for your slice, each 1 to 3 lines long. Any other edit stops the slice: report it and ask the lead.
2. Never edit `tests_v4/`, `smoke.gd`, `hazard_test.gd` or `climb_test.gd`. If a test looks wrong, stop and report it.
3. **No new `class_name`.** Use `const X := preload("res://x.gd")`, as the project does today. A headless run without an
   editor import does not refresh the global class cache, so a new `class_name` breaks the test runner.
4. Every number the player can feel goes in tuning: `value/min/max/step/label/help`. You may only add keys to your
   slice's part file `tuning.d/<part>.json` (section 2.4). You may only change the value of an existing key in
   `tuning.json` when this contract names that key for your slice. Labels and help text use plain words.
   Any timing that warns the player has a `min` of at least 0.35.
5. Hardcoded structure is fine in a prototype: state names, glyphs, slot counts, menu layout.
6. Data files hold names, text, kinds and links. A number in a data file is written as the **name of a tuning key**
   (fields ending in `_key`), never as a raw number.
7. The size of `main.gd` is guarded: at most 600 lines after S0 (a test checks this), and at most 10 more lines per later slice.
8. Random rolls for drops, respawns and loot use `R.rng`, never `randf()`. Enemies may keep `randf()` for idle motion.
9. Every new script starts with the prototype header comment (`# PROTOTYPE - NOT FOR PRODUCTION`) and one comment
   line per public function.
10. The pass condition for every slice: its own test, plus `smoke`, `hazard_test` and `climb_test`, all pass in the
    headless runner (section 4), and `worker.mjs verify` reports the test lock unchanged.

---

## 2. Architecture decisions

### 2.1 Why state moves out of `main.gd` and `player.gd`

`main.enter()` frees the world and builds a **new Player node on every room change** (`main.gd:113-120`).
It carries only `hp` and `mp` across. Anything that must survive a room change therefore lives in an autoload.

| Autoload | File | New? | Holds |
|---|---|---|---|
| `T` | tuning.gd | changed (S0) | every tuning number; now also loads `tuning.d/*.json` |
| `G` | game.gd | changed (S0) | hitstop, `main`, `peace`, `shifted`, frames, textures, input map (new actions) |
| `Sfx` | audio.gd | changed (S0) | sounds; now also loads `assets/audio/events.d/*.json`, and an unknown name is silent |
| `W` | world_state.gd | **new (S0)** | world flags, visited map cells, items taken from rooms, map sheet, best times, world signals |
| `R` | rpg.gd | **new (S0)** | level, XP, points, stat points, items and counts, owned and equipped gear, scrap, `rng`, formulas |

Load order in `project.godot`: T, G, Sfx, W, R.
`player.hp/energy/mp` (the current values) stay on the player and are carried by `main.enter()` as today.
**Maximum** values come from `R.max_hp()/max_en()/max_mp()`, replacing every `T.v("player_hp"|"energy_max"|"mp_max")`
read: `player.gd:86-88,179-181,694`, `main.gd:115-116,291-292`, `hud.gd:102-103`.

### 2.2 Where progress state moves

`main.gd` keeps each old name as a **forwarding property**, so the 121 smoke checks and other scripts still work.
Tests use `main.has_latch` 9 times, `has_elegy` 6, `saved_room` 7, `lever_library` 4, `bars_opened` 2,
`wall_broken` 1, `boss_beaten` 1, `saved` 2 and `unit` 1.

```gdscript
var has_elegy: bool:
	get: return R.has("elegy_013")
	set(v): R.set_owned("elegy_013", v)
```

| Today (main.gd line) | Moves to |
|---|---|
| `saved` :43, `saved_room` :44, `unit` :46 | `W.flags["saved"]`, `W.saved_room`, `W.unit` |
| `has_latch` :45 | `R.has("wall_jump")` (the ability is an item) |
| `has_elegy` :51 | `R.has("elegy_013")` |
| `lever_library` :52, `bars_opened` :53, `wall_broken` :54, `boss_beaten` :59 | `W.flag("lever_library")` and so on; `boss_beaten` maps to `W.flag("beaten_pallbearer")` |
| new | `W.flag("winch_pulled")`, `"beaten_unmuzzled"`, `"beaten_arnetria"`, `"candle_1".."candle_3"`, `"shutter_hazard"`, `"organ_silent"`, `"rebuild_charge"` |
| `player.hp/energy/mp` :37-39 | unchanged (current values); the maximums come from `R` |
| `T.set_v("weapon", 0)` at start | unchanged |

Saving stays in memory only. `W.snapshot()/restore()` and `R.snapshot()/restore()` exist for RECALL and the tests.

### 2.3 How `main.gd` stays small (872 lines today, target 600 or fewer)

S0 is a **refactor that changes no behaviour**. It moves code out of `main.gd` into new system nodes and keeps a
one-line delegate wherever a test or another script calls the old name: `interact_target`, `boss_died`,
`boss_dying`, `enemy_died`, `player_swing`, `throw_wave`, and the `_scythe` and `_relic` forwarding properties.

| Moved out of main.gd | Into (S0 creates, later owner) |
|---|---|
| `_terminal`, `interact_target`, `_near_lever`, `_levers`, `_machine`, `_ask_machine`, `_activate_machine` (:276-412) | `interact.gd` (S2) |
| `_drop_orb`, `_move_orbs`, the drop part of `enemy_died` (:616-650) | `loot.gd` (S2) |
| enemy and boss creation in `enter` (:139-170) | `spawner.gd` (S0, then frozen; it reads `data/enemies.json`) |
| `_boss_watch`, `boss_dying`, `boss_died`, `_drop_scythe`, `_scythe_watch`, the relic code (:166-176, 227-234, 425-482) | `arena.gd` (S0, then frozen) |
| `_voices`, `_motes` | `ambience.gd` (S1) |
| waves and shots (:531-597), only if main.gd is still over 560 lines | `projectiles.gd` (S0) |

**The system registry (no later slice edits `main._ready`).** S0 adds:

```gdscript
const SYSTEMS := {"interact": "res://interact.gd", "loot": "res://loot.gd", "arena": "res://arena.gd",
	"ambience": "res://ambience.gd", "respawn": "res://respawn.gd", "repair": "res://repair.gd",
	"card": "res://pickup_card.gd", "dialog_box": "res://dialog_box.gd", "menu": "res://menu.gd",
	"recall": "res://recall.gd", "voice": "res://voice.gd"}
var interact: Node; var loot: Node; var arena: Node; var ambience: Node; var respawn: Node; var repair: Node
var card: Node; var dialog_box: Node; var menu: Node; var recall: Node; var voice: Node
```

`_ready` creates each system whose file exists (`ResourceLoader.exists`), names it, adds it and sets the variable.
A slice that adds `menu.gd` therefore only creates the file. Systems listen to the `W` and `R` signals, and
`main.gd` only emits them.

### 2.4 Tuning and sound split (parallel-safe)

- `tuning.gd` loads `res://tuning.json`, then each file in a **fixed list**:
  `const PARTS := ["rpg", "world", "items", "ui", "machines", "pallbearer", "unmuzzled", "arnetria", "recall", "anim", "voice"]`
  from `res://tuning.d/<part>.json`, if the file is there. A fixed list works in an Android export, where listing a
  folder does not. It records `T.source[key] = part`. `T.save()` writes each key back to its own file.
  A key that appears twice is a `push_error`, and `t_core` fails on it.
- `tuning_panel.gd`: one tab per part that loaded, after FEEL / WEAPONS / SOUND.
- `audio.gd`: loads `assets/audio/events.json`, then `assets/audio/events.d/<part>.json` (same list).
  `Sfx.play(name)` with an unknown name prints one warning and stays silent.
- `export_presets.cfg` must include `*.json` (S0 checks this and reports; changing it is a devops edit, so ask first).

### 2.5 New files

| File | Kind | Slice | Purpose |
|---|---|---|---|
| world_state.gd | autoload `W` | S0 | flags, sheets, visited cells, taken marks, signals, snapshot |
| rpg.gd | autoload `R` | S0 | progress, stats, items, gear, scrap, rng |
| rpg_math.gd | RefCounted, static | S0 | pure formulas (unit-tested) |
| db.gd | RefCounted, static | S0 | `Db.table(name) -> Dictionary`, cached JSON loader for `res://data/<name>.json` |
| spawner.gd | RefCounted, static | S0 | `enemy(kind, feet)`, `boss(id, feet, room_size)` from enemies.json `script` |
| arena.gd | Node | S0 | any boss: seal doors, intro, boss bar, timer, reward, recall mode |
| interact.gd | Node | S0 then S2 | the Up key: nearest target of any kind |
| loot.gd | Node | S0 then S2 | drops, soul orbs, scrap, dropped pickups |
| ambience.gd | Node | S0 then S1 | whispers, motes, world cues (sound plus light) |
| respawn.gd | Node | S1 | weak enemies come back while she stays |
| tools/mirror_room.py | tool | S1 | writes a mirrored `<room>_shift.txt` (shaft) |
| pickup.gd | Node2D | S2 | an item in the world (glow, bob; Up or touch) |
| pickup_card.gd | CanvasLayer | S2 | the card and the special show |
| repair.gd | Node | S2 | SELF-REPAIR |
| menu.gd | CanvasLayer | S3 | pause menu: MAP, CHARACTER, ITEMS, EQUIPMENT, SYSTEM |
| map_view.gd | Control | S3 | draws a map sheet (used by the MAP tab and the minimap) |
| minimap.gd | Control | S3 | 5 x 3 cells, top right |
| dialog_box.gd | CanvasLayer | S3 | generic lines and choices (replaces machine_dialog.gd) |
| enemy3.gd | CharacterBody2D | S4 | the two lab machines |
| werewolf.gd | Node2D | S6 | LUPERCAL-06, THE UNMUZZLED |
| arnetria.gd, mirror.gd | Node2D | S7 | ARNETRIA and her mirrors |
| recall.gd | Node | S8 | RECALL refights, REBUILD HERE |
| voice.gd | Node | S10 | Pandora's voice lines on events |
| tests_v4/* | tests | test-writer | section 4 |

### 2.6 Data files (exact schemas)

All live in `res://data/`. They are read only through `Db.table(name)`. Owners are listed in section 3.

**items.json** (S2; S0 writes a stub with suture, lexicon_core, wall_jump, elegy_013, soul_orb, scrap)
```json
{ "suture": {
    "name": "SUTURE", "tag": "ITEM", "type": "consumable",
    "desc": "Black thread that knows where the wound is.",
    "effect": "Heals {suture_heal} HP.",
    "icon": "res://assets/items/suture.png",
    "max_key": "suture_max",
    "use": {"heal_hp_key": "suture_heal"},
    "refill_at_terminal": true,
    "touch_take": false,
    "special_show": false,
    "grants": "" } }
```
- `type`: `consumable | key | ability | weapon | gear | orb | material`.
- `use` keys (closed list): `heal_hp_key`, `heal_mp_key`, `heal_en_key`.
- `grants`: an ability id that `R.has()` answers, such as `"wall_jump"`.
- `{key}` in text is replaced with `T.v(key)` when the text is shown.
- `soul_orb` (`type: orb`, touch, restores `mp_pickup`) and `scrap` (`type: material`, touch, adds `scrap_per_pickup`) are items too.

**gear.json** (S2; the effects code is S0's)
```json
{ "coupler_034": {"name": "COUPLER-034", "slot": "harness", "desc": "...", "icon": "res://assets/items/coupler_034.png",
    "effects": {"atk_add_key": "coupler_damage", "hp_max_add_key": "coupler_hp"}},
  "restore_unit": {"name": "RESTORE UNIT", "slot": "module", "desc": "...", "icon": "...",
    "effects": {"rebuild_here_key": "rebuild_charges"}} }
```
- `slot`: `harness` (fits `harness1` or `harness2`) or `module` (fits `module1` or `module2`). An id can sit in only one slot.
- `effects` (closed list): `atk_add_key, def_add_key, hp_max_add_key, en_max_add_key, mp_max_add_key, mag_add_key,
  orb_reach_add_key, scrap_gain_mult_key, rebuild_here_key`.
- Draft content: `coupler_034`, `governor_207`, `regulator_000` (harnesses, from rpg-items.md), `restore_unit`, `scrap_loom` (modules).

**enemies.json** (S0 writes the 9 enemies plus 3 bosses; S4 owns it from session 2)
```json
{ "hound": {"name": "CHAINBITE HOUND", "kind": "spirit", "boss": false, "script": "res://enemy.gd",
    "glyph": "H", "xp_key": "xp_hound", "weak": true,
    "drops": [{"item": "suture", "chance_key": "drop_suture_weak", "needs": "suture_kit"}],
    "scrap_mult_key": "", "bestiary": "Bred to fetch the dead. Still fetching."},
  "pallbearer": {"name": "THE PALLBEARER", "kind": "spirit", "boss": true, "script": "res://boss.gd",
    "glyph": "", "xp_key": "xp_boss", "weak": false, "drops": [], "reward": "elegy_013",
    "flag": "beaten_pallbearer", "music_cut": true, "bestiary": "..."} }
```
- `kind`: `spirit | machine | cyborg`. `glyph`: its letter in room files (`room.gd` builds its letter table from this).
- `weak: true` means it comes back while she stays. `needs`: the drop happens only once `R.has(needs)`.
- The working names come from bosses-story.md section 6. The writer (builder-eq) may polish them.

**levels.json** (S0)
```json
{ "base": {"hp_max_key": "player_hp", "en_max_key": "energy_max", "mp_max_key": "mp_max"},
  "stats": {
    "str": {"label": "STRENGTH", "help": "Every swing hits harder.", "gives": {"atk_key": "str_atk"}},
    "vit": {"label": "VITALITY", "help": "More health.", "gives": {"hp_max_key": "vit_hp"}},
    "mag": {"label": "MAGIC", "help": "More MP; specials hit harder.", "gives": {"mp_max_key": "mag_mp", "special_key": "mag_special"}},
    "end": {"label": "ENDURANCE", "help": "More energy; takes less.", "gives": {"en_max_key": "end_en", "def_key": "end_def"}} },
  "auto_order": ["vit", "str", "mag", "str", "end", "vit", "str", "mag"] }
```

**rooms_meta.json** (S1; S0 writes the 10 rooms of today with titles and cells)
```json
{ "cell_tiles": [24, 14],
  "sheets": {
    "before": { "church": {
        "code": "CH", "title": "THE NAVE OF ASH", "cell": [7, 4, 3, 1], "entry": "P",
        "save": false, "boss": "", "respawn": true, "music": "music_church",
        "exits": [{"side": "L", "at": 0, "to": "shaft", "kind": "lever_door"},
                  {"side": "R", "at": 0, "to": "library", "kind": "door"}],
        "marks": {"1": {"type": "item", "item": "suture"}},
        "decor": [{"type": "claws", "tile": [10, 4]}] } },
    "after": { "church_shift": {"...": "same fields"} },
    "restored": { "base": "before", "add": {"arnetria": {"...": "same fields"}} } } }
```
- The room key is the **file id** (`church`, `church_shift`, `vault_restored`), not the room name.
- Exit `side`: `L R U D`. `at` is the cell offset along that side. `kind`: `door | open | hole | tunnel | lever_door | boss_door | sealed_x | shutter | bricked`.
- Mark `type`: `item | lever | winch | candle | terminal | organ | talk | boss`. Extra fields: `item`, `flag`, `boss` (enemies.json id), `trigger_x`.
- The map sheets follow map.md sections 2 and 4 exactly (cells, exits, enemies per room).

**dialogue.json** (S7 owns it; builder-eq writes the text)
```json
{ "arnetria_intro": [{"who": "ARNETRIA", "text": "Nothing has changed."}, {"who": "", "text": "> VISUAL MATCH: 97%"}] }
```
At most 3 lines on screen at once. A line starting with `>` is a printed readout.

**voice.json** (S10)
```json
{ "level_up": [{"file": "res://assets/audio/voice/level_up_1.ogg", "text": "...", "status": "pending"}] }
```
`status`: `pending | generated | approved`. A `pending` line never plays.

### 2.7 Formulas (`rpg_math.gd`, static, exact signatures)

```gdscript
static func xp_total(level: int, step: float) -> int        # round(step * (level-1) * (level+2) / 2); step 10 -> 0,20,50,90,140,200,270,350,440,540
static func level_for(xp: int, step: float, cap: int) -> int
static func dealt(power: float, atk: float, add: float) -> int        # max(1, round(power * atk / 100.0 + add))
static func special(power: float, special_pct: float) -> int          # max(1, round(power * special_pct / 100.0)); ignores ATK
static func taken(raw: float, mult: float, def: float) -> int         # max(1, round(raw * mult * (100.0 - def) / 100.0))
static func scrap_chance(base: float, low: float, hp_share: float) -> float   # clamp(base + low * (1.0 - hp_share), 0, 1)
```

- `R.atk()` = 100 + str x `str_atk` + gear `atk` (in percent). `R.def()` = min(`def_cap`, end x `end_def` + gear `def`).
- `R.special_pct()` = 100 + mag x `mag_special`.
- `R.taken(raw, src)`: when `src == "trap"`, the raw number is returned unchanged. When `src == "boss"`, mult is 1.0.
  Otherwise mult is `area_damage_mult`. DEF applies to everything except traps.
- `R.max_hp()` = `player_hp` + vit x `vit_hp` + gear, never below `max_hp_floor`. Gaining max HP from gear does not heal.
  Losing it clamps the current HP.
- Level-up: `points += points_per_level` for each level gained. When `levelup_refill` is 1, HP, EN and MP refill to the
  maximum. Two levels from one kill give one `leveled` signal with the new level.
- Respawned enemies give `ceil(xp x xp_respawn_mult)`. RECALL win: `round(boss xp x recall_xp_share)`.
- Boss hand share stays inside `boss.gd` (`boss_hand_share`), as today.

### 2.8 Room file changes (S1)

- Per-room variants replace `MIRRORED` and `SHIFT_ROUTES` (`room.gd:28-33`). `load_room(name, after_shift)` keeps
  its signature and tries `<name>_shift.txt` when shifted, then `<name>_restored.txt` when `W.sheet == "restored"`,
  then `<name>.txt`. It sets `room.file_id` to the file it loaded. `shaft_shift.txt` is written by `tools/mirror_room.py`.
- New glyphs: `B` bricked arch (solid, its own brick colour). `:` one-way shutter in an edge column (opens on
  `W.flag("shutter_<file_id>")`). Digits `1`-`9` are **markers**: `room.marks["1"] = feet`, and the meaning comes from
  `rooms_meta.marks`. Enemy letters come from the enemies.json `glyph` fields. The existing letters stay valid.
- `L`/`Y` levers, `A` relic and `O` boss spawn keep working in old files. New files use markers instead.
- Backdrops: `room.gd:330-341` today draws 192 px panels with 40 px gaps. The fix covers the full room
  (church 1152 x 256, boss 480 x 224) with no gap. Test hook: `func backdrop_rects() -> Array`.

---

## 3. Slices

Summary (no overlap; every feature in the brief has exactly one owner):

| Slice | Name | Session | Builder | Needs |
|---|---|---|---|---|
| S0 | Core: state, data, formulas, extraction | 1 | builder-iq | none |
| S1 | World: 25 rooms, map data, shift files, backdrops, filter, cues, weak respawn | 1 | builder-iq; lead walks the greybox | S0 |
| S2 | Interact: Up, pickups, card, special show, drops, orbs, scrap, Sutures, self-repair | 1 | builder-iq; text builder-eq | S0 |
| S3 | UI: pause menu, minimap, HUD, dialog box, touch | 2 | builder-iq; best model reviews screenshots | S0, S2 |
| S4 | Machines: 2 lab enemies, names, drops, calmer rooms | 2 | builder-iq; art best model | S0 |
| S5 | THE PALLBEARER rework | 3 | builder-iq; **feel: best model** | S0, S2 |
| S6 | THE UNMUZZLED | 3 | builder-iq; **feel: best model** | S0, S1, S2 |
| S7 | ARNETRIA, candles, end of the shift | 3 | builder-iq; text builder-eq; **feel: best model** | S0, S1, S3 |
| S8 | RECALL and REBUILD HERE | 3 | builder-iq | S0, S3 |
| S9 | Hero frames and animation states | 1 (proof), 2, 3 | **drawing: best model**; wiring builder-iq | S0 |
| S10 | Voice lines | 1 (script), 3 (wiring) | builder-eq; generation only with the user's yes | S0 |

Common test hooks (built by S0): `main.debug_enter(room: String, side := "left", shifted := false)`,
`R.debug_set(d: Dictionary)`, `R.debug_seed(seed: int)` (also the command-line user arg `seed=N`),
`W.debug_set(d: Dictionary)`, `player.debug_set(d: Dictionary)` (keys `hp, energy, mp, facing, state, pos`),
`arena.debug_win()`. `G.peace = true` turns enemies off, as today. Boss tests set it to false.

### S0 Core (session 1, alone, first)

- **Owner:** world_state.gd, rpg.gd, rpg_math.gd, db.gd, spawner.gd, arena.gd, data/levels.json,
  tuning.d/rpg.json, tuning.gd, tuning_panel.gd. It also writes the first versions of interact.gd, loot.gd,
  ambience.gd and projectiles.gd (pure moves) and stubs of data/items.json, gear.json, enemies.json and rooms_meta.json.
- **Hooks (S0 only, these lines only):** main.gd (extraction, registry, forwarding properties, signal emits,
  `debug_enter`, `max_*` reads); player.gd (`max_*` reads; damage through `R.hit_damage` at :615, :624;
  `take_hit(damage, from_x, src := "enemy")` through `R.taken`; `lock/unlock/debug_set`); hud.gd :102-103;
  hazard.gd (`src "trap"`); boss.gd (`src "boss"`); main `_move_shots` (`src "shot"`);
  game.gd KEYS/PAD (new actions); audio.gd (events.d, silent unknown names); project.godot (autoloads).
- **Public interface:**
  - `W`: signals `room_entered(file_id: String)`, `enemy_hit(en: Node2D, dmg: int)`,
    `enemy_killed(en: Node2D, kind: String, at: Vector2, respawned: bool)`, `player_hurt(dmg: int, src: String)`,
    `player_down()`, `boss_started(id: String)`, `boss_down(id: String, at: Vector2)`, `shift_changed(shifted: bool)`,
    `flag_changed(key: String, value)`. Vars `flags`, `visited` ({sheet: {file_id: true}}), `taken`, `sheet`
    (`before|after|restored`), `saved_room`, `unit`, `best_times`. Functions `flag(key, default := false)`,
    `set_flag(key, value)`, `mark_taken(file_id, marker)`, `is_taken(file_id, marker) -> bool`, `start_shift()`,
    `end_shift()` (sets `G.shifted` and `sheet`, emits `shift_changed`), `meta(file_id) -> Dictionary`,
    `title(file_id) -> String`, `room_list(sheet) -> Array`, `cell_of(file_id, local: Vector2) -> Vector2i`,
    `snapshot() -> Dictionary`, `restore(d)`, `debug_set(d)`.
  - **`R`, superseded 2026-11-20 (decision 28):** `leveled(level: int)` only; no `points`, `alloc`, `spend()`, `auto_allocate()` or `STATS`; new `growth(kind: String) -> float`; every stat is computed from `level`; `restore` ignores old `points` and `alloc`. The `R` entry below is the old interface.
  - `R`: signals `xp_changed(xp: int, level: int)`, `leveled(level: int, points: int)`, `stats_changed()`,
    `items_changed(id: String, count: int)`, `gear_changed(slot: String, id: String)`, `scrap_changed(value: float)`.
    Vars `level, xp, points, alloc` ({str, vit, mag, end}), `items` ({id: count}), `owned_gear: Array`,
    `equip` ({harness1, harness2, module1, module2}), `scrap: float`, `quickslot := "suture"`, `names_seen`, `rng`.
    Functions `max_hp() max_en() max_mp() atk() def() special_pct() -> float`,
    `hit_damage(power: float, special: bool) -> int`, `taken(raw: float, src: String) -> int`,
    `award_kill(enemy_id: String, respawned: bool) -> int`, `add_xp(n: int)`, `spend(stat: String) -> bool`,
    `auto_allocate()`, `has(id: String) -> bool`, `set_owned(id: String, on: bool)`, `count(id) -> int`,
    `add_item(id: String, n := 1) -> int`, `use_item(id: String) -> bool`, `equip_gear(slot: String, id: String) -> bool`,
    `gear_effect(effect: String) -> float`, `add_scrap(v: float)`, `refill_at_terminal()`, `snapshot()`, `restore(d)`,
    `reset()`, `debug_set(d)`, `debug_seed(seed: int)`.
  - `player`: `lock(anim := "")` (state `locked`: no input, gravity still on), `unlock()`, `is_locked() -> bool`, `debug_set(d)`.
  - `arena`: `var boss: Node2D`, `var mode := "normal"` (or `"recall"`), `var fight_time: float`, `attach(b: Node2D)`,
    `dying(b)`, `down(b, at: Vector2)`, `signal fight_ended(id: String, won: bool, seconds: float)`, `debug_win()`.
    **Boss interface** (every boss script): `var boss_id: String`, `var hp: float`, `var alive: bool`,
    `var started: bool`, `setup(feet: Vector2, room_size: Vector2)`, `begin()`, `parts() -> Array`,
    `max_hp() -> float`, `stage() -> int`, `debug_stage(n: int)`, `var attack_log: Array` ({name, warn, stage}).
    New bosses call `G.main.arena.dying(self)` and `G.main.arena.down(self, at)`.
  - `interact`: `register(node: Node2D, kind: String, label: String, cb: Callable, reach := 0.0)`, `unregister(node)`,
    `nearest() -> Dictionary` ({node, kind, label, pos}), `press() -> bool`, `signal used(kind: String, node: Node2D)`.
    Targets are cleared on `room_entered`. Up together with attack on the same frame is the special attack, not a use.
  - `spawner`: `static enemy(kind: String, feet: Vector2) -> Node2D`, `static boss(id: String, feet: Vector2, room_size: Vector2) -> Node2D`.
  - New input actions in game.gd: `quick` (H; pad Back), `repair` (G, held; pad Y), `map` (M). Menu navigation reuses existing actions.
- **Tuning (tuning.d/rpg.json):** xp_curve_step 10 (4-30, 1); level_cap 10 (5-20, 1); start_level 1 (1-10, 1);
  points_per_level 2 (1-4, 1); str_atk 8 (0-20, 1); vit_hp 10 (0-30, 1); mag_mp 6 (0-20, 1); mag_special 8 (0-25, 1);
  end_en 6 (0-20, 1); end_def 2 (0-6, 1); def_cap 40 (0-60, 5); max_hp_floor 50 (20-100, 5);
  levelup_refill 1 (0-1, 1); area_damage_mult 0.75 (0.25-1.5, 0.05); xp_respawn_mult 0.5 (0-1, 0.1);
  xp_hound 3, xp_ghost 3, xp_spitter 3, xp_leech 4, xp_choir 6, xp_moth 7, xp_scribe 10, xp_crab 12, xp_warden 14
  (each 0-50, 1); xp_boss 50 (0-200, 5); xp_unmuzzled 30 (0-150, 5); xp_arnetria 80 (0-300, 5);
  suture_heal 40 (10-100, 5); suture_max 3 (1-9, 1); coupler_damage 5 (0-20, 1); coupler_hp -40 (-80-0, 5);
  governor_hp 10 (0-40, 5); regulator_damage 5 (0-20, 1).
- **Acceptance:** the game plays exactly as before; smoke passes with no test changed; main.gd has 600 lines or
  fewer; killing enemies gives XP and level-ups, with a full refill and a plain toast (S3 replaces the toast);
  the F1 panel shows an RPG tab.

### S1 World (session 1, after S0; parallel with S2)

- **Owner:** room.gd, shift.gd, door.gd, props.gd, ambience.gd, respawn.gd, rooms/*.txt (every file),
  data/rooms_meta.json, tuning.d/world.json, assets/audio/events.d/world.json, assets/env/* (backdrops),
  tools/mirror_room.py.
- **Hooks:** main.gd: 2 lines (`ROOMS` and `ENTRY` read from `W.room_list` and the meta `entry`).
  smoke.gd room checks: the test-writer updates them (see section 4.4).
- **Builds:** 14 rooms before the shift and 11 after, exactly as in map.md sections 2, 4 and 5. Each shifted room is its
  own `<room>_shift.txt`, plus `vault_restored.txt` with the door to `arnetria`. At most 2 enemy kinds per room.
  Gates: the lever door, the bars (Elegy only), the cracked wall, the tunnel, the winch, the candles and X door,
  the shutter. **Until S6 lands, KN holds a plain `wall_jump` item marker**, so the critical path can be played.
  No hint text: delete props.gd:54, door.gd:57 and room.gd's "LOCKED - UNTIL THE NEXT UPDATE". Use cues instead:
  door lamp red to pale, chain run and boom, dust, cold air, candle flicker, claw marks (the `decor` entries).
  The library filter gets gentler: shift.gd mode 2 stops cubing the brightness and gets its own strength key.
  Weak enemies come back while she stays in the room. Every other enemy comes back on re-entry, as today.
- **Public interface:** `room.file_id`, `room.marks`, `room.meta`, `room.backdrop_rects()`;
  `shift.set_room(file_id)`, `shift.restore(seconds: float)` (awaitable: the tear runs backwards and the colour
  drains in 12 tolls), `shift.mode_params(file_id) -> Dictionary`; `door.lamp` (`"red"|"pale"|"off"`),
  `door.refuse()`; props `Candle` (`light()`, lights a sconce on the X door, sets `W.flag("candle_n")`), `Winch`,
  `Shutter`, `Decor`; `respawn.pending: Array`, `respawn.debug_tick(sec: float)`, `respawn.live_weak() -> int`;
  `ambience.cue(name: String, at: Vector2)`. Levers, candles and the winch register with `G.main.interact`.
- **Tuning (tuning.d/world.json):** respawn_time 25 (10-120, 5); respawn_warning 1.0 (0.35-2.5, 0.1);
  respawn_distance 96 (32-200, 8); respawn_attack_delay 1.0 (0-3, 0.1); shift_library_strength 0.45 (0-1, 0.05);
  shift_restore_time 12 (4-30, 1); lamp_blink 0.5 (0.2-1.5, 0.05).
- **Acceptance:** every room loads in every sheet. Walking the critical path of map.md section 3 works from the church
  to the organ. After the shift, the loop OR~ to AR works. Each door leads where the map says. The church and boss
  walls show no black gaps. The library after the shift is readable. A weak enemy returns about 25 s after it dies,
  never next to her.

### S2 Interact (session 1, after S0; parallel with S1)

- **Owner:** interact.gd, loot.gd, pickup.gd, pickup_card.gd, repair.gd, data/items.json, data/gear.json,
  tuning.d/items.json, assets/items/* (32 x 32 icons; drawn placeholders are fine until the art pass),
  assets/audio/events.d/items.json.
- **Hooks:** arena.gd: 1 line (the reward becomes `G.main.loot.spawn_pickup(item, at)`). This removes the
  touch-pickup scythe and relic, and with them the texts at main.gd:234 and :436. touch.gd: none (the bubble already
  uses `main.interact_target()`).
- **Builds:** Up takes items, pulls levers, uses terminals and talks. The nearest target wins. The pickup card follows
  rpg-items.md section 8 (it cannot close for 0.5 s; a harness card offers EQUIP NOW or LATER). The special show runs
  about 1.6 s before the card for abilities, gear and weapons; Pandora uses `player.lock("special")`.
  Soul orbs (MP) and scrap are taken by touch. Item drops come from enemies.json. The scrap chance rises at low
  health. The quick key `quick` uses the quickslot item (Suture). A terminal refills Sutures to the maximum.
  SELF-REPAIR: she stands still on the floor and holds `repair`. After `repair_hold` seconds she is locked in the
  `repair` animation and heals `repair_rate` HP per second, paid in scrap. Moving, a hit or running out of scrap
  cancels it.
- **Public interface:** `loot.spawn_pickup(item_id: String, at: Vector2, opts := {}) -> Node2D`,
  `loot.roll_drops(kind: String, at: Vector2, respawned: bool) -> Array` (deterministic with `R.rng`), `loot.live: Array`;
  `pickup.item_id`, `pickup.touch_take`, `pickup.take()`, `signal taken(item_id: String)`;
  `card.present(item_id: String) -> String` (awaitable: `"ok"|"equip_now"|"later"`), `card.active`,
  `card.lock_left`, `card.debug_close(choice := "ok")`; `repair.active`, `signal stopped(reason: String)`
  (`"done"|"hit"|"moved"|"empty"`), `repair.debug_hold(sec: float)`.
- **Tuning (tuning.d/items.json):** pickup_reach 24 (12-48, 2); pickup_lock 0.5 (0-1.5, 0.05);
  special_pickup_time 1.6 (0.6-3, 0.1); input_swallow 0.15 (0-0.5, 0.05); drop_life 12 (4-30, 1);
  drop_suture_weak 0.04 (0-1, 0.01); drop_suture_other 0.1 (0-1, 0.01); orb_magnet 0 (0-64, 4; 0 = touch only);
  scrap_max 100 (20-300, 10); scrap_per_pickup 10 (1-50, 1); scrap_drop_base 0.10 (0-1, 0.01);
  scrap_drop_low 0.35 (0-1, 0.01); repair_hold 0.6 (0.1-2, 0.05); repair_rate 20 (5-80, 5);
  repair_cost 1.0 (0.2-5, 0.1; scrap per HP); heal_hold 0.15 (0-0.5, 0.05; touch).
- **Acceptance:** walking over an item never takes it; Up does. Each special item gets the show and then the card.
  Orbs and scrap are picked up by touch. H heals with a Suture. Holding G while standing still repairs her, and a hit stops it.

### S3 UI (session 2)

- **Owner:** menu.gd, map_view.gd, minimap.gd, dialog_box.gd, hud.gd, touch.gd, machine_dialog.gd (retired:
  no longer used, kept on disk), tuning.d/ui.json.
- **Hooks:** game.gd: 1 line (`pause` opens `G.main.menu.toggle()` instead of `touch.toggle_pause()`).
  interact.gd: 2 lines (the organ question goes through `dialog_box.ask`).
- **Builds:** a pause menu with tabs **MAP, CHARACTER, ITEMS, EQUIPMENT, SYSTEM**. SYSTEM is an addition: it keeps
  today's RESUME, CONTROLS, RECONSTRUCT, QUIT and the tester room list, which have no other home. MAP draws the current
  sheet: visited cells, saves `*`, bosses `!`, exits as ticks, a locked door red, the sealed door with 3 dots.
  CHARACTER spends points (AUTO-ALLOCATE as a row) and previews each change (green if higher, red if lower). ITEMS uses
  and assigns the quickslot. EQUIPMENT has 2 harness rows and 2 module rows, with previews. A level-up shows a gold
  "LEVEL UP" and an offer prompt; opening the menu then goes to CHARACTER. The corner minimap shows 5 x 3 cells, and her
  cell blinks. The HUD adds LV, an XP line, the scrap gauge and the quickslot chip. With LEXICON CORE, the enemy name
  plate appears (NEW the first time). The touch version has tap rows, a BACK button and QUICK, REPAIR and MAP chips.
  The dialog box shows at most 3 lines.
- **Public interface:** `menu.is_open`, `menu.tab`, `const TABS`, `toggle()`, `open(tab := "")`, `close()`,
  `offer_points()`, `signal closed`, `debug_press(action: String)` (`up down left right ok back tab_next tab_prev`),
  `debug_rows() -> Array`, `debug_tap(row: int)`; `map_view.cell_rect(file_id) -> Rect2i`;
  `minimap.focus_cell() -> Vector2i`; `hud.name_plate(en: Node2D)`, `hud.level_up()`;
  `dialog_box.say(lines: Array, speaker := "")` (awaitable), `play(id: String)`,
  `ask(question: String, choices: Array) -> int` (awaitable), `active`, `debug_advance()`, `debug_choose(i: int)`,
  `signal finished`.
- **Tuning (tuning.d/ui.json):** scan_show_time 2.5 (0.5-6, 0.5); levelup_text_time 1.2 (0.4-3, 0.1);
  menu_swallow 0.15 (0-0.5, 0.05); menu_repeat 0.18 (0.08-0.4, 0.02); minimap_alpha 0.8 (0.2-1, 0.05);
  minimap_blink 0.5 (0.2-1.5, 0.05); dialog_char_time 0.03 (0-0.1, 0.005).
- **Acceptance:** Esc, Start or the corner button opens the menu, and the game and music stop. Every tab works with
  keys, pad and touch. Closing never swings or jumps. The minimap shows where she is.

### S4 Machines (session 2; parallel with S3)

- **Owner:** enemy3.gd, data/enemies.json (from session 2), tuning.d/machines.json, assets/enemies/<two ids>/*.
- **Hooks:** enemy.gd and enemy2.gd: 1 line each where the attack rest is set (`* T.v("area_rest_mult")`).
  rooms/lab.txt: placing the `E`/`F` glyphs is **requested from S1's owner**; in session 2 S1 is done, so S4 may edit
  only those glyphs in lab.txt and lab_shift.txt.
- **Builds:** two machine kinds for the lab (`kind: machine`). Their ids and moves come from a one-page designer brief
  written before S4 starts (the drafts give no machine design). Each has its name, XP, drops (more scrap,
  `scrap_machine_mult`) and the enemy interface (`setup`, `hurt_rect`, `can_hurt`, `damage`, `touched_player`,
  `take_hit`, `kind`, `hp`; on death it calls `G.main.enemy_died(self)`).
- **Tuning (tuning.d/machines.json):** for each id `<id>_hp, <id>_damage, <id>_speed, <id>_notice,
  <id>_warning (min 0.35), <id>_wait`; area_rest_mult 1.2 (0.5-2, 0.05); scrap_machine_mult 2 (1-4, 0.25).
- **Acceptance:** two new machines fight in the lab, readable and fair. LEXICON shows their names. They drop scrap more often.

### S5 THE PALLBEARER (session 3)

- **Owner:** boss.gd, assets/boss/*, tuning.d/pallbearer.json. It may change the values of the existing `boss_*`
  keys in tuning.json (boss_hp becomes 330).
- **Hooks:** arena.gd: 1 line (delete the "ITS HANDS ARE YOUR STAIRS" toast).
- **Builds:** bosses-story.md section 2: the body swings the scythe and the hit areas match the drawing. Three stages
  at 60% and 25%. The moves are Slam, Reap, Bells, Throw, Sweep, Coffin Lid (stage 2) and Burial (stage 3). No hint
  toast ("IT WILL NOT LET GO" goes). The boss interface, plus `scythe_rect() -> Rect2` and `hit_rects() -> Array`.
- **Tuning:** boss_stage2 0.6, boss_stage3 0.25 (0.05-0.95, 0.05); boss_min_warn 0.35 (0.35-1, 0.05);
  one warning key and one damage key per move (`boss_<move>_warn`, `boss_<move>_dmg`); boss_stuck1 3.0,
  boss_stuck2 2.6, boss_stuck3 2.2 (1-5, 0.1); boss_speedup 1.2 (1-1.6, 0.05); boss_intro_time 3 (0-6, 0.5).
- **Acceptance:** about a 3-minute fight. Every hit lands where the blade is drawn. Each stage adds something new.
  Elegy-013 is taken with Up and the card.

### S6 THE UNMUZZLED (session 3; parallel with S5 and S7)

- **Owner:** werewolf.gd, assets/boss/unmuzzled/*, tuning.d/unmuzzled.json.
- **Hooks:** rooms_meta.json: 1 line (KN's mark changes from `item wall_jump` to `boss unmuzzled`); enemies.json:
  the `unmuzzled` entry gets `reward: "wall_jump"` (S4 is done by then).
- **Builds:** bosses-story.md section 3: HP 160, 2 stages at 50%. The moves are Lunge, Rend, Wall Pounce, Ricochet
  and Wall Rake. He shows the wall jump all fight. The boss interface plus `var state: String`.
- **Tuning:** wolf_hp 160; wolf_stage2 0.5; wolf_speed 150; wolf_kick_speed 300; wolf_speedup 1.2; wolf_lunge_warn 0.5;
  wolf_rend_warn 0.35; wolf_cling_time 0.6; wolf_howl_warn 1.0; wolf_shadow_warn 0.4; wolf_skid_time 0.8;
  wolf_land_stun 1.2; wolf_ricochet_min 2; wolf_ricochet_max 4; wolf_dmg_lunge 15, wolf_dmg_rend 10,
  wolf_dmg_rend3 15, wolf_dmg_pounce 18, wolf_dmg_ricochet 20, wolf_dmg_rake 15.
- **Acceptance:** a 60 to 90 second fight, beaten in about 2 tries. His reward gives the wall jump, and the well
  can then be climbed.

### S7 ARNETRIA and the end of the shift (session 3; parallel with S5 and S6)

- **Owner:** arnetria.gd, mirror.gd, data/dialogue.json, assets/boss/arnetria/*, tuning.d/arnetria.json.
- **Hooks:** rooms/arnetria.txt: only her spawn marker (S1 built the arena).
- **Builds:** bosses-story.md section 4. Her bar does not move until a mirror breaks (the stored lie). The moves are
  Ring Sweep, Shard Fling, Mirror Cast, Clock Hand, Visor Glare and Shatter Rain. Stages at 66% and 33%; the visor
  cracks at stage 3. Dialogue before, during and after the fight goes through `dialog_box.play(id)`. Her death
  runs `await G.main.shift.restore(T.v("shift_restore_time"))`, then `W.end_shift()`, and the cracked visor stays on
  the floor as a key item.
- **Public interface:** the boss interface plus `shown_hp`, `stored`, `mirrors: Array`, `visor_cracked`, `debug_break_mirror()`.
- **Tuning:** arn_hp 450; arn_stage2 0.66; arn_stage3 0.33; arn_mirror_hp 30; arn_mirror_time1 6, _2 5, _3 4;
  arn_shards1 3, arn_shards2 5; a warning key and damage key per move (warnings at least 0.35); arn_float_speed 60.
- **Acceptance:** 3 lit candles open her door. She talks. A 3 to 4 minute fight. When she dies, the red drains in 12
  tolls, the terminals work again and the first map sheet returns with AR.

### S8 RECALL and REBUILD HERE (session 3; parallel with S5 to S7)

- **Owner:** recall.gd, offline.gd, tuning.d/recall.json.
- **Hooks:** interact.gd: 2 lines (the terminal asks CACHE MEMORY / RECALL / BACK through `dialog_box.ask`).
  arena.gd: 2 lines (`mode == "recall"`: no reward, no OFFLINE screen, `fight_ended` goes to recall).
  menu.gd: 1 line (SYSTEM shows END RECALL while a recall runs). main.gd: 2 lines (`player_died` hands the
  `"rebuild"` choice to `recall.rebuild_here()`).
- **Builds:** RECALL lists beaten bosses with their best times. It is open only while the world is not shifted.
  She starts with full HP, EN and MP, on a cyan memory tint. A win records the best time and gives 25% of the boss
  XP. A loss restores the snapshot and puts her back at the terminal. The restore module adds **REBUILD HERE** to the
  offline screen. It rebuilds her in the same room at her last safe floor spot with `rebuild_hp_share` health. It has
  `rebuild_charges` uses, refilled at a terminal.
- **Public interface:** `recall.options() -> Array`, `start(id: String)`, `end(won: bool)`, `active`,
  `can_rebuild() -> bool`, `rebuild_here()`. `offline.ask()` returns `"reconstruct"|"rebuild"|"quit"`.
- **Tuning (tuning.d/recall.json):** recall_xp_share 0.25 (0-1, 0.05); recall_fade 0.6 (0.1-2, 0.1);
  rebuild_charges 1 (0-3, 1); rebuild_hp_share 0.5 (0.1-1, 0.05).
- **Acceptance:** a refight starts at the terminal and always ends back there. The best time updates. XP is added
  on a win. REBUILD HERE appears only with the module equipped.

### S9 Hero frames and animation (proof in session 1; batches in sessions 2 and 3)

- **Owner:** player.gd `_animate`, `_show` and the new animation states only (lines 733 to the end), tools/build_pandora_v3.py,
  assets/2x/pandora/*, assets/frames.json, the frame sources, tools/check_frames.py, tuning.d/anim.json.
- **Builds (sprites.md):** the 70 required frames, the Elegy set (30) and self-repair (about 6): about 106.
  Plus wiring the idles the user already drew (B, C). New logical states: `jump_still`, `jump_move` (chosen at
  take-off by |vx|), `fall`, `land`, `wall`, `walljump`, six attacks, `cast`, `backdash`, `hurt`, `dead`,
  `repair`, `special`, the idle variants, and `<anim>_elegy` when it exists. Attacks and cast stay at **5 frames**,
  with hand and shoulder points on frames 1 and 3 (`_fit_swings`). If an animation is missing, the old fallback
  plays, so the code never waits for art.
- **Public interface:** `player.anim_state() -> String` (the logical animation chosen this tick).
- **Tuning (tuning.d/anim.json):** anim_jump_move_speed 40 (0-125, 5); anim_fall_speed 60 (0-300, 10);
  anim_land_min_air 0.25 (0-1, 0.05); anim_land_time 0.12 (0-0.4, 0.02); anim_idle_variant_after 6 (2-20, 1).
- **Acceptance:** the user approves each batch on a 4x contact sheet and a game-speed GIF before it is wired in.
  The standing and moving jumps look different. The landing pose plays.

### S10 Voice (script in session 1; wiring in session 3)

- **Owner:** voice.gd, data/voice.json, assets/audio/voice/*, assets/audio/events.d/voice.json, tuning.d/voice.json.
- **Builds:** lines on these events: `pickup_special, level_up, boss_seen, boss_down, offline, rebuild, shift_start,
  shift_end, low_hp, repair_done`. **ElevenLabs is paid: nothing is generated without the user's yes.**
  Until a line is generated it stays `pending` and is silent.
- **Public interface:** `voice.on_event(name: String)`, `voice.last_line: String`.
- **Tuning:** voice_volume -6 (-30-6, 1); voice_chance 0.6 (0-1, 0.05); voice_cooldown 8 (0-30, 1).

---

## 4. Test plan

### 4.1 Layout and pattern

- `tests_v4/harness.gd` is a shared base with `_check(name, ok, detail)`, `_frames(n)` and `_tap(action, hold)`,
  copied from smoke.gd:28-48. It also provides `_enter(room, side, shifted)` (through `main.debug_enter`) and the
  summary line `TEST <name> PASS|FAIL passed=N failed=M`. It exits 0 only if `failed == 0 and passed > 0`.
- One scene per slice, `tests_v4/t_<slice>.tscn`, holding one Node with `t_<slice>.gd`. Each loads main.tscn like
  smoke.gd:15-24 and sets `R.debug_seed(7)` first.
- `tests_v4/run_all.sh` runs smoke, hazard_test, climb_test and every `tests_v4/t_*.tscn`. It prints one line per test
  and `ALL PASS` or the list of failures, and exits non-zero on any failure.

### 4.2 What each test must assert

| Test | Asserts |
|---|---|
| t_core (S0) | Autoloads `W` and `R` exist. No tuning key appears twice; every key has all 6 fields and min <= value <= max. Every `*_key` in the data files exists in `T.data`. Every drop item exists in items.json, and every gear effect is in the closed list. `xp_total` 1..10 = 0,20,50,90,140,200,270,350,440,540. `add_xp(20)` at L1 gives L2, 2 points and exactly one `leveled`; `add_xp(70)` gives L3 and 4 points; XP stops at `level_cap`. A level-up refills HP, EN and MP. `spend("vit")` raises `max_hp` by `vit_hp`. `auto_allocate` spends every point in `auto_order`. Dirge on a ghost (22 HP) takes 3 hits at ATK 100, 2 at ATK 132, and 2 with Coupler. A ghost touch takes 5; a crusher takes 40 at any DEF; a boss hit uses mult 1.0. A Suture heals 40, is refused at full HP and clamps to its maximum. Gear: the max HP floor holds, unequipping never heals, one id fits one slot, and a module will not go in a harness slot. Forwarding: `main.has_elegy = true` gives `R.has("elegy_013")`, and `main.lever_library` maps to `W.flag`. W and R snapshot/restore round trips. `spawner.enemy` returns a node with the full enemy interface for every enemies.json id. The same seed gives the same 20 drop rolls. `main.gd` has 600 lines or fewer. Every system in `SYSTEMS` whose file exists is created. |
| t_world (S1) | Every room in the before, after and restored sheets loads, and its tile size matches its meta cell x (24, 14). Every grid door, edge, hole and tunnel has a meta exit with the same side and target, and a return exit in the target room (except the shutter). Each room has at most 2 enemy kinds, and the counts match map.md. Reachability with abilities: from CH with nothing you reach LB, SC, S2, LA and KN; with wall_jump and elegy you reach OR; after the shift all 11 rooms are reachable from OR~; AR needs 3 candles; no hole is a dead end with the abilities held at that point. The banned strings are absent from the scripts ("UNTIL THE NEXT UPDATE", "Far below", "GRIP SERVOS ONLINE -", "E (or SWAP)", "ITS HANDS ARE YOUR STAIRS", "IT WILL NOT LET GO"); S5 removes the last two, and until then the test reports them as expected failures. `backdrop_rects()` covers 1152 x 256 (church) and 480 x 224 (boss) with no gap. The library `mode_params` no longer cube the brightness. Weak respawn: after a kill plus `debug_tick(respawn_time + warning)` with her far away, the count is back and the enemy is flagged respawned; if she is within `respawn_distance` it does not come back; it never exceeds the starting count; a moth does not return until re-entry; a paused tree does not advance the timer. Shift: `start_shift` loads the `_shift` files, and `end_shift` loads `vault_restored` with its door to arnetria while levers keep their state. 2 candles leave the X door locked; 3 open it. Entering a room marks it visited. |
| t_interact (S2) | Walking across an item does not take it; Up within `pickup_reach` does, and outside it does not. The card is active after a take, cannot close before `pickup_lock`, and closes after it; she does not jump on close. The special show lasts `special_pickup_time` +/-0.1 s for an ability, and an ordinary item skips it. EQUIP NOW fills the first free harness slot. Orbs and scrap are taken by touch. Over 1000 seeded rolls, the scrap rate at 10% HP is higher than at full HP, by `scrap_drop_low` x 0.9 +/- 0.03. The quick key uses one Suture and is refused at full HP. A terminal refills Sutures. Repair: holding `repair` while still with scrap locks her and raises HP; moving, a hit or empty scrap stops it with the right reason. With a lever and an item both in reach, the nearer one wins. Up plus attack on the same frame is the special attack. A taken item stays taken after re-entry. Taking LEXICON CORE gives `R.has("lexicon_core")`. |
| t_ui (S3) | Pause opens the menu and pauses the tree. The tabs cycle in order. `debug_rows` match each tab. CHARACTER: spending STR raises the ATK row, AUTO spends everything, and the preview equals the stats after the change. ITEMS: using a Suture from the menu heals. EQUIPMENT: 2 harness and 2 module rows, and the preview equals the result. MAP: only visited cells are drawn, and `cell_rect` matches the meta. Minimap: a 5 x 3 window around `focus_cell`. The level-up offer leads to CHARACTER. The name plate shows the enemies.json name only with LEXICON, and says NEW the first time. `dialog_box.ask` returns the chosen index, and a page has at most 3 lines. After closing, attack and jump are ignored for `menu_swallow`. `debug_tap` works on every tab. |
| t_machines (S4) | Both ids spawn from their glyphs in the lab and have the full interface. A hit uses the formula. Their damage to her uses `area_damage_mult`. A kill gives the right XP and rolls scrap with `scrap_machine_mult`. `area_rest_mult` lengthens the rest of the old enemies, measured on hound and crab. |
| t_pallbearer (S5) | HP starts at `boss_hp` (330). The stage changes at 60% and 25%. In stage 3 every logged warning is at least 0.35 s. In every attack frame, `hit_rects()` lie inside the grown `scythe_rect()`. Death sets the flag and leaves an `elegy_013` pickup. No toast text appears. |
| t_unmuzzled (S6) | He spawns in KN and the doors seal. HP 160. Stage 2 at 50%. The state log shows cling, pounce and ricochet. Landing stuns last at least `wolf_land_stun`. Death leaves a `wall_jump` pickup, and after taking it `player._can_latch` is true at a wall. |
| t_arnetria (S7) | The X door is locked with 2 candles and open with 3. The intro dialogue is shown. Body hits do not move `shown_hp` until a mirror breaks, and a break applies the stored damage. Stages change at 66% and 33%, and the visor cracks at stage 3. Death leads to `G.shifted == false`, sheet `restored`, the visor present, and a working terminal. |
| t_recall (S8) | RECALL is offered only with a beaten boss and no shift. A win records the best time (only if lower) and adds `round(xp x recall_xp_share)` with no reward item. A loss shows no OFFLINE screen, restores the snapshot and puts her at the terminal. END RECALL works. REBUILD HERE appears only with the module and a charge, places her in the same room, and a terminal refills the charge. |
| t_anim (S9) | Every logical state maps to an existing animation or its documented fallback. Attacks and cast have 5 frames. frames.json has hand and shoulder points on frames 1 and 3. A take-off below `anim_jump_move_speed` gives `jump_still`, above it `jump_move`. `fall` follows the apex, `land` plays after `anim_land_min_air`, `dead` at 0 HP and `repair` during repair. The Elegy set is used when it exists. Plus `python tools/check_frames.py` (outside Godot): 88-92 px tall, feet at (112, 152), palette only, under 8% duplicate pixels. |
| t_voice (S10) | voice.json parses. Every event is in the list. A `generated` line has its file. A pending line is silent with no error. The cooldown holds. |

### 4.3 Run commands (Windows; every test above runs headless)

Git Bash, from the worktree's `prototypes/feel-v3`:
```bash
GODOT=/c/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64_console.exe
mkdir -p tests_v4/logs
"$GODOT" --headless --path . --import          # once, after new PNG files (if this flag is refused: --editor --quit)
"$GODOT" --headless --path . --log-file tests_v4/logs/t_core.log --quit-after 72000 res://tests_v4/t_core.tscn; echo "exit=$?"
bash tests_v4/run_all.sh                       # everything; exit 0 = all pass
```
PowerShell:
```powershell
$G = "C:\Users\AUC\opencode-workspace\tools\Godot\Godot_v4.7.2-stable_win64_console.exe"
& $G --headless --path . --log-file tests_v4\logs\t_core.log --quit-after 72000 res://tests_v4/t_core.tscn; "exit=$LASTEXITCODE"
```
Visual checks do not run headless: screenshots of the menu tabs, minimap, backdrops, library filter and boss frames
(`... res://tests_v4/t_ui.tscn -- shots`, run without `--headless`), plus the S9 contact sheets.
The best model and the user review these. `tests_v4/logs/` is gitignored.

### 4.4 Keeping builders out of the tests

1. Tests are written **before** the builder starts, from this contract only, by the test-writer pair (two model
   families, per lean-orchestrator). They never read the implementation.
2. The lead locks them:
   `node ~/.claude/skills/lean-orchestrator/tools/worker.mjs lock tests_v4/harness.gd tests_v4/run_all.sh tests_v4/t_core.gd tests_v4/t_core.tscn smoke.gd hazard_test.gd climb_test.gd --out tests_v4/locks/s0.json`
   (one lock file per slice).
3. The builder's brief says: never edit `tests_v4/`, `smoke.gd`, `hazard_test.gd` or `climb_test.gd`.
   The worker gets only its owner files through `--files`.
4. Review gate: `worker.mjs verify tests_v4/locks/<slice>.json` must exit 0, and
   `git diff --name-only <base>...HEAD -- tests_v4 smoke.gd hazard_test.gd climb_test.gd` must be empty.
   `git diff --stat` must touch only owner files plus the listed hook lines. Otherwise the slice is rejected.
5. S1 changes rooms on purpose. Before S1 is built, the test-writer rewrites the smoke checks that S1 makes wrong:
   the room list, "five areas of music", the lab relic, the touch-pickup scythe and the hint toasts. The lead
   then locks them again. Builders never do this.

---

## 5. Three-session build split

The lead only briefs, reviews diffs and logs, and runs tests. Slices run in separate worktrees branched from the
integration branch (`feat/proto-v4-backtrack`, or a fresh `feat/proto-v4-rpg`). Each merge is shown to the user
(diff summary plus test log) and waits for a yes (G2). Code goes to **builder-iq (deepseek-flash)**. Item text,
names, help strings and dialogue go to **builder-eq (glm-flash)**. The fallback is the Claude `builder` (Haiku);
never Opus. **Best model (this main session)**: sprite drawing, boss feel and timing, the room greybox walk and
screenshot review.

### Session 1: foundation, world, taking things (plus the art proof)

| Order | Work | Parallel? |
|---|---|---|
| 1 | Test-writer: harness, t_core, t_world, t_interact, smoke rewrites; lock | no |
| 2 | S0 core (builder-iq) | **alone**: it edits main.gd and player.gd |
| 2' | S9 proof: stationary jump, 5 frames (best model draws, then the user approves) | yes, no code files |
| 2'' | S10 script: voice line text (builder-eq), no generation | yes |
| 3 | S1 world, with room grids drafted from map.md by a worker plus `mapgen2.py` | yes, with S2 (separate worktrees) |
| 3 | S2 interact | yes, with S1 |

**Playable checkpoint 1:** all 14 + 11 rooms are walkable in greybox with the right gates. A placeholder wall jump
waits in KN. The organ starts the shift. The candles open Arnetria's empty room. Items are taken with Up, with the
card and the show; orbs and scrap by touch. XP, level-ups and full refill work (auto-allocate for now). H heals, G
repairs. Weak enemies come back. The library filter is gentler, the walls have no gaps, and the old Pallbearer can
still be beaten.
**Lead context:** about 200k (S0 review about 45k, S1 about 40k, S2 about 30k, art proof about 15k, briefs and test setup about 30k, base about 40k).

### Session 2: menus, machines, her new body

| Work | Parallel? |
|---|---|
| Test-writer: t_ui, t_machines, t_anim; lock | first |
| A one-page machine design brief (game-designer, lead approves) | first, with the tests |
| S3 UI (builder-iq; best model reviews the tab screenshots) | yes |
| S4 machines (builder-iq; machine art by the best model) | yes |
| S9 batches 1-3: moving jump, fall and land; wall and wall jump; six attacks and cast (best model draws, builder-iq wires player.gd) | yes (S9 is the only slice touching player.gd now) |

**Playable checkpoint 2:** the pause menu with MAP, CHARACTER, ITEMS, EQUIPMENT and SYSTEM on keys, pad and touch.
The corner minimap. Spend 2 points or AUTO. Equip 2 harnesses and 2 modules. LEXICON names. Two machines in the lab.
Jumps, fall, land, wall moves and all attacks use the new frames.
**Lead context:** about 230k.

### Session 3: bosses and the end of the shift

| Work | Parallel? |
|---|---|
| Test-writer: t_pallbearer, t_unmuzzled, t_arnetria, t_recall, t_voice; lock | first |
| S5 Pallbearer, S6 Unmuzzled, S7 Arnetria (builder-iq builds; the **best model tunes the feel** from `attack_log` and play) | yes, 3 worktrees, separate files |
| S8 RECALL and REBUILD (builder-iq) | yes (it uses the arena interface, not the bosses) |
| S9 batch 4: backdash, hurt, death, repair, the Elegy set, idles | yes |
| S10 wiring; generation only after the user's yes | last |

**Playable checkpoint 3:** a full run of about 60 minutes. Church, then the werewolf (wall jump), then the
Pallbearer in 3 stages, then the shift, the candles, Arnetria and the world restored with the visor left behind.
RECALL refights with best times and 25% XP. The REBUILD HERE module. Voice, if approved.
**Lead context:** about 265k. This is tight under the 295k cap, so hand off after the three bosses if the lead
passes 230k, and run S8 to S10 in a fresh session.

---

## 6. Risks, in the order to remove them

1. **Art volume (biggest).** About 106 hero frames, plus about 135 boss frames (Pallbearer 50, werewolf 40, Arnetria
   45, from bosses-story.md). Remove it first: the 5-frame jump proof in session 1, with the time per frame measured
   before more is drawn. Code never waits: missing animations fall back (t_anim checks this). Bosses start as
   procedural drawings, as boss.gd does today. Boss art needs the user's yes on the look before any drawing.
2. **The S0 refactor breaking what works.** Main.gd has 872 lines, and the tests reach into its fields. Remove it:
   no behaviour change in S0, forwarding properties, and the locked smoke tests must pass before any feature lands.
3. **Design conflicts not yet decided** (section 7). Remove them: decisions.md before S0 freezes the schemas, or the
   defaults below.
4. **25 rooms and soft-locks.** Remove them: the t_world graph and ability reachability test, greybox before art,
   and the lead walks the critical path at checkpoint 1.
5. **Merge clashes between parallel slices.** Remove them: the owner table, the `tuning.d` and `events.d` part files,
   the system registry, one-line hooks only, and a fixed merge order (S0, then S1 and S2; S3, S4 and S9; then
   S5 to S8, then S10).
6. **Boss feel** needs judgement. Every timing is a slider, warnings never go under 0.35 s, the best model reviews,
   and the user playtests.
7. **Menus on a 384 x 216 touch screen.** Screenshot review of every tab, and tap targets at least 22 px.
8. **Reversing the shift** (rooms revert, levers keep their state). W snapshot tests, and `vault_restored`.
9. **Paid voice.** Nothing is generated without a yes; pending lines are silent.
10. **Android.** The fixed `PARTS` list instead of folder listing; `*.json` in the export filter; the minimap drawn
    once per room, not every frame. Test the APK at checkpoint 3.

## 7. Conflicts and defaults used (confirm in decisions.md)

| # | Topic | Drafts say | This contract uses |
|---|---|---|---|
| 1 | Growth | rpg-items: automatic gains, no full heal | brief: 2 points per level (CHARACTER, AUTO), full refill; stats STR, VIT, MAG, END (draft numbers) |
| 2 | Gear slots | DRIVE + FRAME | brief: 2 harness + 2 module slots |
| 3 | RECALL reward | record only | brief: best time + 25% of the boss XP |
| 4 | Weak respawn time | map.md 25 s, rpg-items 40 s | 25 s (slider) |
| 5 | Soul orb | rpg-items: MP orbs fly to her | an MP orb, taken by touch; `orb_magnet` 0 (slider) |
| 6 | Werewolf name and gift | rpg-items: "GAOL-WOLF WARDEN", "WARDEN'S SINEW" | LUPERCAL-06, THE UNMUZZLED; item id `wall_jump`; the old `warden` stays an ordinary enemy |
| 7 | Enemy names | two different lists | enemies.json from bosses-story.md section 6; the writer polishes |
| 8 | "IT WILL NOT LET GO" | bosses-story: keep | brief: no hint text, so removed |
| 9 | Restore module and scrap loom locations | not on the map | the level designer places them in rooms_meta (S1); until then they are found at CACHE STATION 002 |
| 10 | Lucid Cell | rpg-items has it | left out (not in the brief) |
| 11 | Sutures refilled at a terminal | both docs recommend it | yes |
| 12 | Pallbearer's face, Arnetria's look | need a yes | procedural placeholders until approved |

## 8. Lead rulings (2026-11-19) - these override sections 1-7 where they differ

1. Sutures are NEVER refilled (user decision). Only the 8 placed in rpg-items.md v2 exist. Conflict 7.11 is reversed.
2. Weak-enemy return time defaults to 40 s (tuning slider `weak_respawn_s`); the user asked for a slow pace. Conflict 7.4 is reversed.
3. Stat names and per-point gains come from rpg-items.md v2: VIGOR (+10 HP), POWER (+8% ATK), GUARD (+3 DEF), STAMINA (+8 EN), MAGIC (+8% special damage, +6 MP). Wherever the contract says STR/VIT/MAG/END, read these names.
4. Gear slots: harness TORSO + LIMBS, module DRIVE + FRAME. The RESTORE MODULE is a fixed core part without a slot (rules in rpg-items.md v2).
5. Restore module, Sutures, harnesses, modules and LEXICON CORE are placed where map.md (updated) says; the CACHE STATION 002 stand-in in 7.9 no longer applies.
6. S8 (RECALL + REBUILD HERE) moves to session 2 to keep session 3 under budget. Session 3 = S5, S6, S7, the remaining art batches and voice wiring.
7. Model routing: slice coordinators are Sonnet or Haiku-xhigh sub-orchestrators; code goes first to the cheap OpenCode builders (deepseek-flash builder-iq, glm-flash builder-eq) with Haiku-xhigh `builder` as fallback; Opus only for design judgement. Hero frames are drawn by Sonnet (it sees images), reviewed on contact sheets by the lead, approved by the user.
8. Tests in tests_v4/ are written and locked in the planning session (before session 1), not in session 1.
9. Weak enemies return after 10 s (`weak_respawn_s` default 10), out of sight and never within 96 px; in one-screen rooms they walk in through a door. Every 25 s / 40 s value above (S1 text, section 7.4) reads 10 s.
10. New in S4 (session 2): the cyborg mini-boss SEXTON-19, THE BOLTED (bosses-story.md 3b; room OW, map.md) and the BOLT PISTOL off-hand weapon (rpg-items.md 3.14; key N, plus a touch button; usable only with DIRGE-042 in the main hand; bolts never trigger the barred lever). Rare drops (rpg-items.md 3.5b, one strong: TANK HEART) belong to S2 (drops).
11. Quickslot keys 1-4 win; the debug room-jump keys in game.gd move to Ctrl+1..0.
12. Art (S9): true 16-bit Pandora (about 16 colours, 1-px dark outline, flat 2-3 tone shading, about 90 px tall) in a new palette. The user picks palette A, B or C (sprites.md 3b) in session 1; it is saved as assets/palettes/pandora.gpl plus a PNG strip. The jump proof is made both ways (sprites.md 6), and the user picks the method. Pandora total: 134 frames.
13. History: every session ends by copying the PC exe and the phone APK into C:/Users/AUC/opencode-workspace/playable-history/<date>-<name>/ (never overwritten; play-history.cmd lists them), plus a git tag `proto-v4-s<N>-<date>`.
