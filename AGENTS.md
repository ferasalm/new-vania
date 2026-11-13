# OpenCode Game Studios

Indie game development managed through 52 coordinated agents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4.7.2
- **Language**: GDScript
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline
- **Agent Harness**: OpenCode

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

> **Note**: Engine-specialist agents exist for Godot, Unity, Unreal, SFML 3,
> Raylib, and Bevy. Use the set matching your engine.

## Project Structure

```text
/
├── AGENTS.md                    # Project configuration
├── opencode.json                # OpenCode V2 config (plugins, MCP, permissions)
├── .pi/                         # Pi config (settings, 9 extensions)
├── .omp/                        # oh-my-pi config, generated agents, MCP
├── .claude/                     # Claude Code: generated .agents/ mirror + settings, hooks
├── .mcp.json                    # Claude Code project MCP servers
├── .codex/                      # Codex target (agents, MCP config)
├── .githooks/                   # Tracked git hooks (commit-msg, pre-commit)
├── .agents/                     # Canonical content (harness-agnostic)
│   ├── agents/                  # 52 agent definitions
│   ├── skills/                  # 78 skill workflows
│   ├── commands/                # 78 slash commands
│   ├── rules/                   # 11 path-scoped coding standards
│   └── modules/                 # 22 module sources (non-OpenCode targets)
├── .opencode/                   # OpenCode-specific
│   ├── plugins/                 # TypeScript plugins (ccgs-hooks, drift-detector, changelog-generator)
│   ├── agents/ → ../.agents/agents/   (generated link, gitignored)
│   ├── skills/ → ../.agents/skills/   (generated link, gitignored)
│   ├── commands/ → ../.agents/commands/ (generated link, gitignored)
│   ├── rules/ → ../.agents/rules/     (generated link, gitignored)
│   └── modules/                 # Module CLI + 22 OpenCode-target module sources
├── docs/
│   ├── architecture/            # Architecture Decision Records (ADRs)
│   ├── engine-reference/        # Curated engine API snapshots (version-pinned)
│   ├── framework/               # OCGS framework reference docs & templates
│   │   ├── director-gates.md    # Quality gate definitions
│   │   ├── technical-preferences.md  # Project tech config (populated by /setup-engine)
│   │   ├── agent-roster.md      # Full agent inventory
│   │   ├── coding-standards.md  # Code review standards
│   │   ├── coordination-rules.md    # Agent coordination rules
│   │   ├── templates/           # Document templates (GDDs, ADRs, specs, etc.)
│   │   └── ...                  # Skills reference, workflow catalog, etc.
│   ├── pi-compatibility.md      # Pi setup guide
│   ├── pi-extensions.md         # Pi extension reference
│   ├── pi-workflow.md           # Pi workflow differences
│   ├── omp-compatibility.md     # oh-my-pi (omp) setup guide
│   ├── authoring-agents.md      # Agent creation guide
│   ├── authoring-skills.md      # Skill creation guide
│   ├── hybrid-workflow.md       # Hybrid workflow reference
│   └── CONTRIBUTING.md          # Framework contribution guide
├── tests/
│   ├── agents/                  # Agent framework validation
│   │   ├── validate.mjs         # Structural compliance checker
│   │   ├── validate-gdscript.mjs # GDScript snippet linter
│   │   └── validation-report.md # Latest audit results
│   ├── extensions/              # Pi extension unit tests
│   ├── e2e/                     # E2E parity tests
│   └── [game-specific tests]
├── src/                         # Game source code
├── assets/                      # Game assets
├── design/                      # Game design documents
├── tools/                       # Build and pipeline tools
│   ├── migrate-to-agents.mjs    # Migration script (.opencode/ → .agents/)
│   ├── git-hooks/               # Hook validators (commit-msg, pre-commit) + installer
│   └── ...
├── prototypes/                  # Throwaway prototypes
└── production/                  # Sprint plans, milestones, session logs
```

## Modular Framework

The framework is partitioned into installable theme modules.

**Core** (always installed): creative-director, technical-director, producer, /start, /help, /concept-brainstorm, /setup-engine, validation suite.

**Available modules:** art, design, architecture, stories, programming, ui, audio, narrative, level-design, qa, release, prototyping, live-ops, localization, data, engine-godot, engine-unity, engine-unreal, engine-sfml3, engine-raylib, engine-bevy.

**Install:** `node .opencode/modules/install.mjs add <name> [--harness <id>]`
**Remove:** `node .opencode/modules/install.mjs remove <name> [--harness <id>]`
**List:** `node .opencode/modules/install.mjs list [--harness <id>]`

## Coordination Rules

1. **Vertical Delegation**: Leadership agents delegate to department leads, who
   delegate to specialists. Never skip a tier for complex decisions.
2. **Horizontal Consultation**: Agents at the same tier may consult each other
   but must not make binding decisions outside their domain.
3. **Conflict Resolution**: When two agents disagree, escalate to the shared
   parent. If no shared parent, escalate to `creative-director` for design
   conflicts or `technical-director` for technical conflicts.
4. **Change Propagation**: When a design change affects multiple domains, the
   `producer` agent coordinates the propagation.
5. **No Unilateral Cross-Domain Changes**: An agent must never modify files
   outside its designated directories without explicit delegation.

## Checkpoint Policy (user priority: never lose progress)

- **Every milestone is a pushed checkpoint**: when a meaningful unit of work completes
  (prototype built, GDD authored, fix landed), commit it and push — the user has
  pre-authorized checkpoint commits for this purpose.
- Prefer small, logical, conventional commits over one giant "checkpoint" commit.
- Push immediately after committing; never leave completed work local-only.
- Never rewrite pushed history (no force-push to shared branches).
- In-flight or untracked work must be checkpointed on a branch before switching context.

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

## Coding Standards

- All game code must include doc comments on public APIs
- Every system must have a corresponding architecture decision record in `docs/architecture/`
- Gameplay values must be data-driven (external config), never hardcoded
- All public methods must be unit-testable (dependency injection over singletons)
- Commits must reference the relevant design document or task ID
- **Verification-driven development**: Write tests first when adding gameplay systems.
  For UI changes, verify with screenshots. Compare expected output to actual output
  before marking work complete. Every implementation should have a way to prove it works.

## Context Management

Context is the most critical resource in an OpenCode session. Manage it actively.

**The file is the memory, not the conversation.** Conversations are ephemeral and
will be compacted or lost. Files on disk persist across compactions and session crashes.

Maintain `production/session-state/active.md` as a living checkpoint. Update it
after each significant milestone:

- Design section approved and written to file
- Architecture decision made
- Implementation milestone reached
- Test results obtained

The state file should contain: current task, progress checklist, key decisions
made, files being worked on, and open questions.

### Working rules (cost without quality loss)

- **Small edits**: when the location is known, use one search and one edit. Do not re-read the file first or after; the edit tool reports a failed match. If an edit fails, read only the target lines, then retry once.
- **Batch**: send independent tool calls in the same step.
- **Read once**: read a file a single time per session. If the whole file is needed, read it in one call, never in overlapping ranges. Do not re-read text already in the conversation. Re-read only when the file may have changed since (a formatter, a test, or another agent touched it); keep the single-read and non-overlapping-range rules for files that have not changed.
- **One task per session**: when a task is done, or the session passes about 150k tokens, update `production/session-state/active.md` and hand off to a fresh session with a start prompt. Never rely on compaction to carry details.
- **Keep `active.md` under 4 KB**: move finished history to `production/session-state/archive/` and leave a one-line pointer.
- **Review briefs**: each specialist reads the document under review once, in full. The delegating agent does not also read it in full unless it must judge the text itself.
- **Godot runs**: `godot_get_debug_output` works only while a `godot_run_project` process is still alive. For a run that exits by itself (tests, smoke checks), start Godot from the shell with `--headless --path <project> --log-file <file> --quit-after <frames>` and read the log file.

## Workflow Modes

This project supports two workflow modes. Choose the one that fits your team size and project maturity:

### Hybrid Workflow (Recommended for Indie Teams)

- **Discovery Phase**: Rapid prototyping to find the fun. Low process overhead, minimal agents, throwaway code in `prototypes/`.
- **Production Phase**: Full OCGS discipline once the design is proven. Formal GDDs, ADRs, tests, and quality gates.
- **Best for**: Teams of 1–5, unknown designs, iterating to find the fun.
- **See**: `docs/hybrid-workflow.md` for full details.

### Full OCGS Workflow

- **All phases formal**: Every feature goes through design → architecture → stories → code → tests → review.
- **Best for**: Teams of 5–15, known designs, long timelines, publisher requirements.
- **See**: Full documentation in `docs/` and `.agents/skills/`.

## Getting Started

### OpenCode

Run `/start` in OpenCode to begin the guided onboarding flow.
Or jump directly to:
- `/concept-brainstorm` — explore game ideas from scratch
- `/setup-engine godot 4.7` — configure your engine (also: unity, unreal, sfml3, raylib, bevy)
- `/project-stage-detect` — analyze an existing project
- `/prototype` — rapid prototype a concept
- `/hybrid-prototype` — fast-lane prototype for discovery phase

### Pi

Start Pi from the project root:
```bash
pi
```

All OCGS skills and commands load automatically through the `.pi/extensions/` extensions. Pi has no subagent tool; `ocgs-tool-map` maps `Task` to direct work — see `docs/pi-compatibility.md#delegation`.

Pi-specific commands differ from OpenCode in a few cases:
- Use `/generate-changelog` instead of `/changelog` (Pi has a built-in with that name)

See [docs/pi-compatibility.md](docs/pi-compatibility.md) for the full Pi setup guide,
[docs/pi-extensions.md](docs/pi-extensions.md) for the extension reference, and
[docs/pi-workflow.md](docs/pi-workflow.md) for workflow differences.

### oh-my-pi (omp)

Start omp from the project root:
```bash
omp
```

See [docs/omp-compatibility.md](docs/omp-compatibility.md) for omp setup, extension wiring, and known gaps versus Pi.

### Claude Code

Run `npm install` once (hooks need tsx), then start Claude Code from the project root:
```bash
claude
```

`.claude/{agents,skills,rules}` is a generated mirror of `.agents/`: edit `.agents/`, then run
`npm run claude:sync`. `/help` and `/code-review` are `/ocgs-help` and `/ocgs-code-review` in
Claude Code. See [docs/claude-compatibility.md](docs/claude-compatibility.md).

### Key commands by harness

| Command | OpenCode | Pi | oh-my-pi (omp) | Claude Code |
|---------|----------|----|----------------|-------------|
| Delegation | `Task` tool (built-in) | No subagent tool; `ocgs-tool-map` maps `Task` to direct work | omp's built-in task tool; OCGS agents generated into `.omp/agents/` | `Agent` tool; OCGS agents mirrored into `.claude/agents/` |
| Peer review | — | — (removed with `ocgs-delegation`) | — | — |
| Decision capture | question tool | question tool (ocgs-question with TUI) | ask (omp built-in); answers logged to `agent-decisions.jsonl` by ocgs-question | `AskUserQuestion` |
| Skill invocation | `/command-name` | `/command-name` (via prompt templates) | `/skill:<name>` (`skills.enableSkillCommands`) | `/skill-name` (`/ocgs-help`, `/ocgs-code-review` for the renamed two) |

### Harness targets

`/init-template` asks which harness the project uses, and the module CLI accepts
`--harness` on `add`, `remove`, `list`, and `info`:

| Harness | `--harness` | Content target | MCP file |
|---------|-------------|----------------|----------|
| OpenCode | `opencode` (default) | `.opencode/{agents,skills,commands,rules}` | `opencode.json` → `mcp.servers` |
| Pi | `pi` (or `--pi`) | `.agents/{agents,skills,commands,rules}` | `.pi/mcp.json` → `mcpServers` |
| oh-my-pi | `omp` (or `--omp`) | `.omp/agents` + `.agents/{skills,commands,rules}` | `.omp/mcp.json` → `mcpServers` |
| Claude Code | `claude` (or `--claude`) | `.claude/{agents,skills,commands,rules}` | `.mcp.json` → `mcpServers` |
| Codex | `codex` (or `--codex`) | `.codex/agents` + `.agents/skills` | `.codex/config.toml` → `[mcp_servers.*]` |

Module sources live in `.opencode/modules/` (OpenCode target) and
`.agents/modules/` (all other targets). Both trees are tracked; keep them in sync.

## Available Commands

Type `/` in OpenCode to see all available commands. All 78 commands route to
corresponding skills in `.agents/skills/`.

| Category | Commands |
|----------|----------|
| **Onboarding** | `/start`, `/help`, `/project-stage-detect`, `/setup-engine`, `/init-template`, `/adopt` |
| **Design** | `/concept-brainstorm`, `/map-systems`, `/design-system`, `/quick-design`, `/design-review`, `/review-all-gdds`, `/ux-design`, `/ux-review` |
| **Architecture** | `/create-architecture`, `/architecture-decision`, `/architecture-review`, `/create-control-manifest` |
| **Stories** | `/create-epics`, `/create-stories`, `/story-readiness`, `/dev-story`, `/story-done`, `/code-review` |
| **QA** | `/qa-plan`, `/smoke-check`, `/soak-test`, `/regression-suite`, `/test-setup`, `/test-helpers`, `/test-evidence-review`, `/test-flakiness`, `/autopilot-playtest` |
| **Prototyping** | `/prototype`, `/hybrid-prototype`, `/explore`, `/reverse-document` |
| **Team** | `/team-combat`, `/team-narrative`, `/team-ui`, `/team-level`, `/team-audio`, `/team-polish`, `/team-qa`, `/team-release`, `/team-live-ops` |
| **Release** | `/sprint-plan`, `/sprint-status`, `/milestone-review`, `/release-checklist`, `/launch-checklist`, `/retrospective` |
| **Ops** | `/hotfix`, `/day-one-patch`, `/bug-report`, `/bug-triage`, `/security-audit` |
| **Other** | `/balance-check`, `/consistency-check`, `/content-audit`, `/asset-audit`, `/perf-profile`, `/scope-check`, `/gate-check`, `/changelog`, `/patch-notes`, `/localize`, `/onboard`, `/tech-debt`, `/propagate-design-change`, `/estimate`, `/art-bible`, `/asset-spec`, `/art-generate`, `/playtest-report`, `/automated-smoke-test`, `/skill-improve`, `/skill-test` |

## Studio Hierarchy

```
Tier 1 — Directors (Primary agents)
  creative-director    technical-director    producer

Tier 2 — Department Leads (Subagents)
  game-designer        lead-programmer       art-director
  audio-director       narrative-director    qa-lead
  release-manager      localization-lead

Tier 3 — Specialists (Subagents)
  gameplay-programmer  engine-programmer     ai-programmer
  network-programmer   tools-programmer      ui-programmer
  systems-designer     level-designer        economy-designer
  technical-artist     sound-designer        writer
  world-builder        ux-designer           prototyper
  performance-analyst  devops-engineer       analytics-engineer
  security-engineer    qa-tester             accessibility-specialist
  live-ops-designer    community-manager
```

## Engine Specialists

- **Godot 4**: `godot-specialist` + `godot-gdscript-specialist`, `godot-csharp-specialist`, `godot-shader-specialist`, `godot-gdextension-specialist`
- **Unity**: `unity-specialist` + `unity-dots-specialist`, `unity-shader-specialist`, `unity-addressables-specialist`, `unity-ui-specialist`
- **Unreal Engine 5**: `unreal-specialist` + `ue-blueprint-specialist`, `ue-gas-specialist`, `ue-replication-specialist`, `ue-umg-specialist`
- **SFML 3**: `sfml-specialist` (single agent — covers Graphics, Audio, Network, Window, System)
- **Raylib**: `raylib-specialist` (single agent — covers core, rlgl, raudio, raymath, raygui)
- **Bevy**: `bevy-specialist` (single agent — ECS, 2D/3D rendering, bevy_ui, assets, audio)

## Quality Gates

Before merging to `Main`, the CI must pass:

- **Agent validation** (`.github/workflows/agent-validation.yml`):
  - All agent files have required frontmatter and sections
  - All skill files have valid cross-references to existing agents
  - All command files reference valid skill directories
- **Plugin tests** (`npm run test:plugins`):
  - 19 test suites, 177 tests
- **Local CI mirror** (`npm run ci`): runs the same checks as both workflows
  before a push; see `tools/ci/README.md`
- **Git hooks** (`.githooks/`, installed by `npm run hooks:install`):
  - 21 suites, 86 tests (`npm run test:hooks`)
  - Start every task with `npm run task:new -- <type>/<topic>`: it fetches, then creates a worktree and
    branch from `origin/Main`. `.githooks/pre-commit` blocks commits on `Main` and on branches that
    predate the generated `.opencode` links
  - `.githooks/post-checkout` and `.githooks/post-merge` restore `.agents/` files that git removed
    through the link junctions and regenerate the links
  - `.githooks/commit-msg` enforces Conventional Commits
  - `.githooks/pre-commit` blocks credentials, conflict markers and >20 MB files,
    checks that the generated `.opencode/*` entries exist and resolve to directories, and runs framework validation plus
    workflow integrity, plugin tests, or the Claude Code mirror check when their
    paths are staged
- **Claude Code mirror** (`npm run claude:check`): `.claude/` matches `.agents/`;
  `npm run test:claude` (part of `npm test`) covers the mirror and hook adapter

## Notes

This is a port of [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)
to OpenCode. The 78 skills are in `.agents/skills/`, the 52 agents are in
`.agents/agents/`, and the 12 original bash hooks are implemented as a
TypeScript plugin in `.opencode/plugins/ccgs-hooks.ts`.

Additional plugins (`drift-detector.ts`, `changelog-generator.ts`) extend the
framework beyond the original port. See `.opencode/plugins/README.md` for the
plugin architecture guide.

To contribute to the framework itself — adding agents, skills, commands, rules,
or plugins — see `docs/CONTRIBUTING.md`.
