# Godot plugins guide (New Vania, `prototypes/feel-v3`)

Checked 2026-11-21 on Godot 4.7.2, Compatibility renderer, in the main checkout (the only place the
addons exist). Every "Proved" line below comes from a real run; demo scenes are in
`prototypes/feel-v3/tests_dev/plugin_demos/`, screenshots in `docs/tools/img/godot-plugins/`.

**For agents:** read this first. Use the plugin this guide maps to your task. Never skip a plugin the
guide says to use without the user's yes. The addons are local only (`addons/` is in
`.git/info/exclude`): in a worktree, link them with a junction
(`cmd /c mklink /J <worktree>\prototypes\feel-v3\addons <main>\prototypes\feel-v3\addons`) and never
commit `addons/` or the `project.godot` plugin lines (they break a clone without the addons).

**Re-run the proofs** (addons linked; console exe; private `APPDATA`):
`Godot_v4.7.2-stable_win64_console.exe --headless --path prototypes/feel-v3 --fixed-fps 60 res://tests_dev/plugin_demos/<name>_demo.tscn`
for `limbo_console`, `limboai`, `dialogue_manager`, `godot_gas`; look for the `..._DEMO ... pass=true`
line (GAS prints `All 254 out of 254 tests passed`). The visual demos (`liquid2d`, `lit`, `metsys`)
need a window: Fennara `runtime_session start` + `runtime_script` capture.

## Read this before anything else: 3 blockers found

1. **The game does not start in the main checkout right now.** `addons/ModularPlatforms` declares a
   global class `Lever`; `props.gd` line 16 has its own inner `class Lever`. Godot refuses
   (`Class "Lever" hides a global script class`), so `props.gd`, `room.gd` and `main.gd` fail to
   compile. A global `class_name` exists as soon as the file is in the project, plugin on or off.
   ModularPlatforms also declares `HealthComponent`, which clashes with `example/scripts/HealthComponent.gd`.
   Any lane that links `addons/` into its worktree inherits this. Fix options (user decides): remove
   or move ModularPlatforms out of `addons/` (recommended, see its section), or rename our inner class.
2. **LimboAI is loaded twice.** `prototypes/feel-v3/gdextension/limboai.gdextension` (an untracked
   copy from the LimboAI demo) and `addons/limboai/bin/limboai.gdextension` both register it:
   ~40 "already registered" errors on every run, and every headless run so far ended in a
   segmentation fault on quit (exit 139) after the scene itself finished fine. Moving `gdextension/`
   aside should fix both; that is untested here (user approval needed, it is the user's checkout).
3. **Lit does not work on our renderer** (see Lit). Its autoload `LitManager` still runs in every
   scene and tries to compile 60 shader variants.

## Which plugin for which job

| Job | Use | Instead of |
|---|---|---|
| See a scene, the editor or the running game; check a change | **Fennara** (MCP `mcp__fennara__*`) | guessing from code |
| Edit scenes/nodes/resources live in the editor from chat | **Godot AI** (MCP, new chats) or Fennara `run_scene_edit_script` | hand-editing `.tscn` text |
| Import `.aseprite` art as SpriteFrames / textures (lane 04, art) | **Aseprite Wizard** | exporting PNG strips by hand + writing frame code |
| One asset library with thumbnails, tags, import into project (lane 04) | **Asset Manager** (main-screen tab) | folders + a hand catalog |
| World map, rooms, minimap, map screen, discovered cells (lane 05) | **MetroidvaniaSystem (MetSys)** | our own map code (needs a migration decision) |
| Enemy and boss behaviour (lane 06 werewolf) | **LimboAI** (behaviour trees + state machines) | long `match state:` code |
| Abilities, stats, buffs, cooldowns, damage effects (lane 06, player) | **GodotGAS** | ad-hoc HP/stat variables |
| NPC talk, choices, signs (Warden, lore) | **Dialogue Manager** | strings in code |
| In-game debug commands while playtesting (all lanes) | **LimboConsole** (backtick key) | temporary debug keys |
| Water and lava pools that ripple | **physical_liquids_2d** (`Liquid2D`) | hand-made polygons |
| Automated playtests by an agent | **Autopilot** (not installed yet, see section) | manual play |
| Paste a project slice into a web chat | Flatten for LLM | copying files by hand |
| 2D lighting | Lit: **blocked** on our renderer | Godot's own `PointLight2D` |
| Moving/breaking platforms, fans, spikes | ModularPlatforms: **proposed skip** | our own props |

## Plugins one by one

### Fennara 0.4.1 (MCP, GDExtension, MIT)
- **What it does:** lets an agent look at and drive the real editor and game: scene trees, node
  properties, class docs, screenshots of any scene, a live game session it can press keys in and
  capture, script diagnostics, scene validation (structure + 3 s headless run), project settings.
- **When:** every task. Before editing (read the scene), after editing (validate + screenshot),
  and for feel checks (runtime session + key presses + captures).
- **How:** `mcp__fennara__fennara_status` (editor must be open on feel-v3) →
  `get_scene_tree` / `get_node_properties` → `get_class_info` before any API call →
  `run_scene_edit_script` (mode `inspect` to read, `edit` to change; one-off scripts live in
  `res://.fennara/tmp/`) → `validate_scene` → `screenshot_scene` or `runtime_session start` +
  `runtime_script` (`ctx.tap_action("jump")`, `ctx.capture(...)`) → `runtime_session stop`.
- **Proved:** built every demo scene below with it; screenshots of Pandora, liquids, MetSys map;
  live sessions of three scenes with captures.
- **Problems:** 0.4.3 is out (update when convenient). Runtime captures come out 1152x648.
  Only one live session at a time.

### Godot AI 4.3.1 addon / server 4.4.2 (MCP, MIT)
- **What it does:** a second MCP bridge into the open editor with broad edit tools: nodes, scenes,
  scripts, signals, animation and AnimationTree, tilemaps/tilesets, materials, particles, shaders,
  UI/theme, audio buses, input map, autoloads, project settings, filesystem, tests, batch edits.
- **When:** building scenes and resources live (tilemaps, animations, UI) where Fennara's
  script-only editing is slower. Use Fennara to verify the result.
- **How:** in Godot, Godot AI dock → Claude Code → Configure (done 2026-11-21: user scope,
  `godot-ai attach --port 8000 --ws-port 9500`, status Connected). Its tools appear in chats
  started after that. The server needs `uv`.
- **Proved:** server running and registered; not driven from this chat (tools load at chat start).
  First phase 2 lane: run one read call and note the tool names here.
- **Problems:** HTTP endpoint needs its own token; only the `attach` bridge works for Claude Code.

### Aseprite Wizard 9.8.0 (MIT)
- **What it does:** turns `.aseprite` files into Godot SpriteFrames (with tags as animations),
  AnimationPlayer tracks, static textures or tilesets; re-imports when the file changes.
- **When:** any art that exists as `.aseprite` (Pandora frames, enemies, props). Lane 04 art import.
- **How (editor):** select an `AnimatedSprite2D`/`Sprite2D`/`AnimationPlayer` → Inspector section
  "Aseprite" → pick the file → Import. Or the Aseprite Wizard dock. **How (agent):** see
  `tests_dev/plugin_demos/aseprite_wizard_demo.tscn` and this pattern:
  `file_exporter.gd.generate_aseprite_files(ProjectSettings.globalize_path(src), {output_folder, ...})`,
  then `sprite_frames_creator.gd.create_animations(node, files[0], {"should_create_portable_texture": true})`.
- **Proved:** `assets/hero_2d_base/pandora_idle_base.aseprite` → SpriteFrames on an
  AnimatedSprite2D, screenshot [aseprite_wizard.png](img/godot-plugins/aseprite_wizard.png).
- **Problems:** the editor setting pointed at a missing Steam path; fixed 2026-11-21 to the user's
  own build `C:/Users/AUC/opencode-workspace/tools/aseprite-src/build/bin/aseprite.exe` (backup:
  `%APPDATA%/Godot/editor_settings-4.7.tres.bak-2026-11-21-lane08`). Pass absolute paths, never
  `res://` (Aseprite cannot read `res://`). Without the portable-texture option a fresh PNG fails
  to load until the editor imports it. Only 2 `.aseprite` files in `assets/` today.

### Asset Manager 1.0.7 (GPL-3.0)
- **What it does:** a main-screen tab ("AssetManager") that keeps one library folder outside the
  project, indexes 3D models, 2D images, sounds, materials and scenes, shows thumbnails, tags, and
  imports chosen assets into the project.
- **When:** the user's Studio library wish (one asset folder + catalog + thumbnails, ledger N22-N26),
  lane 04.
- **How:** AssetManager tab → pick a workspace (library) folder → Ingest → tag → Import to project.
  Settings live in `%APPDATA%/AssetManager/settings.cfg`; index in `<library>/.assetmanager/index.db`.
- **Proved:** plugin loads, tab present. No library chosen yet (that writes a per-machine setting:
  the user picks the folder).
- **Problems:** GPL: fine as an editor tool, exclude `addons/asset_manager/` from export presets.
  Overlaps our own Studio library: lane 04 must decide which one is the catalog, not build both.

### MetroidvaniaSystem (MetSys) 1.6 (MIT)
- **What it does:** a world-map database for metroidvanias: a map editor (bottom panel "MetSys")
  where you paint cells, borders, room links and markers; runtime API for discovered/visited cells,
  minimap and map screen drawing, room transitions, saving collected items.
- **When:** lane 05 (Add room + connect), the map screen, the minimap.
- **How:** MetSys tab → draw cells → assign each room scene. Runtime: `MetSys.set_save_data()`,
  `MetSys.visit_cell(Vector3i)`, `MetSys.make_map_view(canvas_item, begin, size, layer)` (keep the
  returned object in a variable or it is freed and draws nothing), `MetSys.get_explored_ratio()`.
- **Proved:** loaded the plugin's sample map and drew it at runtime, [metsys_map.png](img/godot-plugins/metsys_map.png)
  (explored ratio 0.0625 reported).
- **Problems:** our game keeps its own map in `data/rooms_meta.json` (`cell` = [x, y, w, h]), so
  MetSys is a **migration**, not a drop-in: never overwrite the user's cells; a lane must propose
  the mapping first. No `res://MapData.txt` yet ("Map data file does not exist" on every run).
  The sample map's custom elements error outside the sample project (harmless).

### LimboAI 1.8.1 (GDExtension, MIT)
- **What it does:** behaviour trees and hierarchical state machines with a visual editor (main tab
  "LimboAI"), a blackboard for shared values, and a live debugger.
- **When:** lane 06 werewolf (patrol, stalk, lunge, recover), every boss and enemy.
- **How:** LimboAI tab → new BehaviorTree `.tres` → add tasks (Sequence, Selector, Wait, custom
  `BTAction` scripts in GDScript) → add a `BTPlayer` child to the enemy, assign the tree. For phases
  use `LimboHSM` + `LimboState`. In code, add the BTPlayer to the tree, set its `owner`, then set
  `behavior_tree` (see `limboai_demo.gd`).
- **Proved:** a code-built tree (wait 0.1 s → set `phase = "lunge"`) ran; blackboard read back
  `lunge` (`LIMBOAI_DEMO ... pass=true`).
- **Problems:** blocker 2 (double load). README lists 4.6+ for 1.8.x; works on 4.7.2.

### GodotGAS 1.1.0 (MIT)
- **What it does:** a Gameplay Ability System: `AbilitySystemComponent` on a character, attribute
  sets (HP, stamina...), gameplay effects (damage, buffs, durations, stacking), abilities with costs
  and cooldowns, gameplay tags, cues (`GameplayCueManager` autoload) for hit flashes and sounds.
- **When:** player and enemy stats, weapon/ability rules, status effects (lane 06 werewolf damage,
  later player abilities).
- **How:** add `AbilitySystemComponent` to the actor, give it an `AttributeSet` resource, grant
  `GameplayAbility` scripts, apply `GameplayEffect` resources. Tags live in `godot_gas/gameplay_tags.gd`.
- **Proved:** ran its own suite in our project: **254/254 passed**.
- **Problems:** our combat already has stats in `rpg.gd`/`Db`; adopting GAS for one enemy first is
  safer than a full switch. Decide per lane with the user.

### Dialogue Manager 4.2.0 (MIT)
- **What it does:** a dialogue script language (`.dialogue` files) with a dialogue editor tab,
  branches, choices, conditions, mutations, and a ready balloon UI.
- **When:** Warden and any NPC, signs, lore, tutorial prompts.
- **How:** Dialogue tab → new file → write `~ start` / `Name: line` / `- choice`. Show it with
  `DialogueManager.show_dialogue_balloon(load("res://x.dialogue"), "start")`.
- **Proved:** `demo.dialogue` parsed; first line "Warden: You came back for the Kennel key?" with
  2 choices (`DIALOGUE_DEMO ... pass=true`).
- **Problems:** our `t_interact_ui` dialog-box checks already fail (known); a lane that switches
  dialog to this plugin must update those tests with the user's yes.

### LimboConsole 0.8.0 (MIT)
- **What it does:** in-game console, toggled with the backtick key, with autocompletion and history.
- **When:** every playtest: teleport to a room, set HP, spawn the werewolf, toggle god mode.
- **How:** `LimboConsole.register_command(callable, "name", "help")`; in game press `` ` ``.
  Agents can call `LimboConsole.execute_command("name args")` from a Fennara runtime script.
- **Proved:** registered `demo_heal`, ran `demo_heal 5`, hp 1 → 6 (`pass=true`).
- **Problems:** keep commands in a dev-only script so they do not ship.

### physical_liquids_2d (no plugin.cfg, MIT)
- **What it does:** `Liquid2D` (an Area2D) draws a pool with a spring-simulated rippling surface;
  presets Water and Lava; bodies entering make splashes.
- **When:** flooded rooms, lava hazards (level building).
- **How:** add an Area2D, attach `res://addons/physical_liquids_2d/liquid_2d.gd` (or add node
  "Liquid2D"), set `preset`, `width`, `height`. Not in the enabled list because it needs no enabling.
- **Proved:** water and lava pools rendered with wavy surfaces, [liquid2d.png](img/godot-plugins/liquid2d.png).
- **Problems:** it builds its children at runtime, so the editor view is empty until you play.

### Autopilot 1.0.0 (agent playtester)
- **What it does:** an agent plays the game from the editor: verify a claim, reach a goal, explore
  for bugs; writes a report. Skill: `/autopilot-playtest`; integration notes:
  `docs/framework/autopilot-integration.md`.
- **When:** after each lane's change, for an automated play check (never as a human playtest).
- **How:** needs the Autopilot agent service (`autopilot` command, wheel in
  `addons/autopilot/agent_service/`), Bun (installed), a TypeSafe decision key and an LLM key in
  `autopilot.env`, sharing turned off in the dock. The skill documents OpenCode/Pi/omp only.
- **Proved:** addon loads (autoload `AutopilotPlaytest`, dock). **Not runnable yet:** the service
  is not installed and there are no keys. **Waiting on user:** install + keys (the LLM key costs money).

### Flatten for LLM 1.1.1 (MIT)
- **What it does:** a dock that writes the project's `.gd`, `.tscn`, `.tres`, `.gdshader` files into
  one Markdown file per type.
- **When:** only when pasting project context into a web chat (ChatGPT/Gemini web).
- **Proved:** flattened `tests_dev/plugin_demos` into `project_context_gd.md` (3.7 KB).
- **Problems:** agents here read files directly, so it adds nothing for them (proposed skip below).

### Lit 1.1.8 (MIT)
- **What it does:** uncapped 2D lights, soft shadows, light cookies, post effects (bloom, CRT...).
- **Proved:** **fails on our renderer.** The game uses Compatibility (`gl_compatibility`); Lit needs
  Forward+. In `lit_demo.tscn` its shaders fail to compile (`screen_uv_to_sdf` unknown) and the lit
  sprite disappears ([lit_compat_blank.png](img/godot-plugins/lit_compat_blank.png)).
- **Options (user decides):** switch the project to Forward+ (affects every scene and the web/low-end
  target; needs its own test pass), or leave Lit unused and disable it so `LitManager` stops running.

### ModularPlatforms "Terrain Kit" 1.1 (MIT)
- **What it does:** template platforms, moving/breaking platforms, fans, spikes, levers, buttons,
  health/hit components, configured in the Inspector.
- **Proved:** 5 templates placed in `modular_platforms_demo.tscn`; they are empty until each gets
  a sprite, collision shape and texture.
- **Problems:** causes blocker 1 (`Lever`, `HealthComponent` class clashes). Our rooms already have
  their own props, levers and hazards.

## Waiting on user approval to skip (at most 5)
1. **ModularPlatforms**: it stops the game from starting (class clash), and our own props already
   do its job. Recommend moving it out of `addons/`.
2. **Flatten for LLM**: agents read files directly; it only helps when pasting into a web chat.
3. **Lit**: does not work unless the whole game switches to Forward+; recommend disabling it for now.

## Project settings the addons need (record only; never commit)
`project.godot` `[editor_plugins] enabled` lists AsepriteWizard, GodotGAS, MetSys (+ EditorExtension),
ModularPlatforms, asset_manager, autopilot, dialogue_manager, flatten_for_llm, godot_ai,
limbo_console, lit. Autoloads added by addons: `AutopilotPlaytest`, `MetSys`, `_fennara_game_capture`,
`_mcp_game_helper`, `LitManager`, `GameplayCueManager`, `DialogueManager`, `LimboConsole`.
Also `[autopilot] project_id` and `MetSysSettings.tres` at the project root.
