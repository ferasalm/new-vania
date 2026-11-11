# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.7.2 (pinned 2026-11-11; matches the Metroidvania System 1.6.1 addon's bundled editor binaries)
- **Language**: GDScript
- **Rendering**: 2D; renderer choice (Compatibility recommended for mobile pixel art) to be confirmed via ADR in `/create-architecture`
- **Physics**: Godot built-in 2D physics (`CharacterBody2D`); Jolt is 3D-only and not relevant

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: Mobile (iOS/Android) primary; PC (itch.io demo → Steam) secondary
- **Input Methods**: Touch, Keyboard, Gamepad
- **Primary Input**: Touch (floating stick + Attack/Jump buttons; contextual Interact bubble; Quick-use Item via HUD chip hold; Dash socket dormant until unlocked — post-pivot verb set per `design/gdd/input-control-mapping.md`)
- **Gamepad Support**: Partial (keyboard + gamepad supported from day one on PC)
- **Touch Support**: Full (touch-first design; all UI must work with touch)
- **Platform Notes**: Base art resolution ~480×270 with integer scaling; enemies separate from backdrops by value (2px), never opacity pulses; no hover-only interactions; telegraphs = color-flash + shape

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`)
- **Variables/functions**: snake_case (e.g., `move_speed`)
- **Signals/Events**: snake_case past tense (e.g., `health_changed`)
- **Files**: snake_case matching class (e.g., `player_controller.gd`)
- **Scenes/Prefabs**: PascalCase matching root node (e.g., `PlayerController.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

## Performance Budgets

- **Target Framerate**: 60 fps on target mobile devices
- **Frame Budget**: 16.6 ms
- **Draw Calls**: ≤ 150 per frame (mobile 2D budget; verify on device during Polish)
- **Memory Ceiling**: ~150 MB RAM on mid-range mobile devices

## Testing

- **Framework**: GUT (Godot Unit Test)
- **Minimum Coverage**: gameplay formulas and core systems unit-testable (dependency injection over singletons); balance formulas required
- **Required Tests**: Balance formulas, gameplay systems, networking (if applicable)

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- **Metroidvania System (MetSys) 1.6.1** — room/map/minimap/fog-of-war backbone; owned, integration begins with the MVP scaffold (pending promotion from `inbox/downloads/organized/projects/Metroidvania_System_1.6.1` to the Godot project)
- **LimboAI v1.8.1** — CANDIDATE, pending ADR at SYS-13 (Enemy AI) / SYS-14 (Grief-Boss) authoring. Behavior trees + state machines + utility AI for enemy/boss behaviors. MIT; ships as **two distinct artifacts**: (a) the **GDExtension** release — built against Godot 4.6, supports 4.6+ including our 4.7.2 pin; (b) prebuilt **4.7.2-stable editor builds** for the engine-module route (exact match for our engine pin — verified 2026-11-11 via release page). Adoption must pick ONE integration route and verify that route's export binaries. Not required for MVP's 2–3 dummy enemy types (hand-rolled state machines suffice — proven in combat concept-test); pays off for grief-boss state framework and per-reality enemy behaviors.

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for architecture decisions, ADR validation, and cross-cutting code review. Invoke GDScript specialist for code quality, signal architecture, static typing enforcement, and GDScript idioms. Invoke shader specialist for material design and shader code. Invoke GDExtension specialist only when native extensions are involved. Note (harness): OCGS godot specialists route through the `general` subagent in this OpenCode harness.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
