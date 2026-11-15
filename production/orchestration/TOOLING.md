# Tooling Guide — modules, plugins, and how the machine runs

> **Status**: adopted 2026-11-15 (setup/ops session). **Audience**: the user and
> every orchestrator/lane chat.
> **Read with**: `README.md` (the operating manual) · `CONTEXT-POLICY.md` (the
> context budget) · `STATE.md` (live state) · `manifest.yaml` (source of truth).

---

## 1. Module inventory (audited, not reinstalled)

All **22 theme modules** are installed for the **OpenCode** harness at version
**0.6.0**. Manifest: `.opencode/modules/installed.json`.

```bash
node .opencode/modules/install.mjs list --harness opencode
```

| Module | Ver | Why it is here (project need) |
|---|---|---|
| `core` | 0.6.0 | Framework skeleton: 3 directors, `/start`, `/help`, gates, context-management doc |
| `design` | 0.6.0 | GDD authoring: game/systems/economy designers, `/design-system`, `/review-all-gdds`, balance/consistency |
| `architecture` | 0.6.0 | ADRs, architecture review, control manifest, `lead-programmer` |
| `stories` | 0.6.0 | Epics → stories → dev → review → done |
| `programming` | 0.6.0 | Gameplay/AI/engine/network/tools programmers + coding rules |
| `qa` | 0.6.0 | QA lead/tester, test plans, smoke/soak, perf, security, skill testing |
| `art` | 0.6.0 | Art bible, asset specs, art generation, technical artist |
| `audio` | 0.6.0 | Audio director, sound designer, audio team workflow |
| `narrative` | 0.6.0 | Narrative director, world-builder, writer |
| `level-design` | 0.6.0 | Level designer, encounter/room layout |
| `ui` | 0.6.0 | UX designer, UI programmer, accessibility |
| `release` | 0.6.0 | Sprints, milestones, release/launch checklists, changelogs |
| `prototyping` | 0.6.0 | Prototyper, `/prototype`, `/hybrid-prototype`, `/explore` |
| `live-ops` | 0.6.0 | Live-ops designer, community manager |
| `localization` | 0.6.0 | i18n pipeline, translation review |
| `data` | 0.6.0 | Data-file conventions (`rules/data-files.md`) |
| `engine-godot` | 0.6.0 | **The engine**: Godot specialist + GDScript/C#/shader/GDExtension specialists |
| `engine-unity` | 0.6.0 | *Installed, unused* — 5 Unity specialists |
| `engine-unreal` | 0.6.0 | *Installed, unused* — 5 UE5 specialists |
| `engine-sfml3` | 0.6.0 | *Installed, unused* — 1 SFML specialist |
| `engine-raylib` | 0.6.0 | *Installed, unused* — 1 raylib specialist |
| `engine-bevy` | 0.6.0 | *Installed, unused* — 1 Bevy specialist |

**Coverage check against the project** (Godot 4.7.2, GDScript): design,
architecture, stories, programming, qa, art, audio, narrative, level-design, ui,
release, prototyping, live-ops, localization, data, core, engine-godot — **all
present**. No module is missing; no reinstall was performed.

### 1.1 The non-Godot engine modules — the one-click decision

They cost **13 agent definition files**, no MCP servers, no hooks, no runtime
load. They are inert unless a lane explicitly spawns one. Removing them buys
almost nothing and loses the option to prototype in another engine.

**Recommendation: leave them installed.** If you want them gone, it is one
command per module (the CLI removes one at a time):

```bash
node .opencode/modules/install.mjs remove engine-unity --harness opencode
node .opencode/modules/install.mjs remove engine-unreal --harness opencode
node .opencode/modules/install.mjs remove engine-sfml3 --harness opencode
node .opencode/modules/install.mjs remove engine-raylib --harness opencode
node .opencode/modules/install.mjs remove engine-bevy --harness opencode
```

Validation plan before any removal: `node tests/agents/validate.mjs`,
`node tools/orchestration/render-prompts.mjs --check`, `npm run ci`. Removal
preserves user-modified files by design.

### 1.2 Module commands

```bash
node .opencode/modules/install.mjs list [--harness <id>]
node .opencode/modules/install.mjs info <module>
node .opencode/modules/install.mjs add <module...> [--harness <id>]
node .opencode/modules/install.mjs remove <module> [--harness <id>]
```

Harness ids: `opencode` (default), `pi`, `omp`, `claude`, `codex`. Module sources
are mirrored in `.opencode/modules/` (OpenCode) and `.agents/modules/` (all other
harnesses) — keep both in sync when editing a module.

---

## 2. The two plugins (installed and verified 2026-11-15)

| Plugin | Version / commit | Where configured | Scope |
|---|---|---|---|
| **DCP** — dynamic context pruning | **3.2.0** (npm `latest`) | global `~/.config/opencode/opencode.json` → `plugins` | Every project on this machine |
| **Superpowers** | **`22f0b46`** (git, `main`) | project `opencode.json` → `plugins` | This project only |

Both load alongside the three OCGS plugins. Verified:

```text
$ opencode plugin list
ocgs.ccgs-hooks           local    .opencode/plugins/ccgs-hooks.ts
ocgs.changelog-generator  local    .opencode/plugins/changelog-generator.ts
ocgs.drift-detector       local    .opencode/plugins/drift-detector.ts
opencode-dcp              3.2.0    @tarquinen/opencode-dcp@latest
superpowers               22f0b46  superpowers@git+https://github.com/obra/superpowers.git
```

### 2.1 DCP — install, config, commands

```bash
opencode plugin add @tarquinen/opencode-dcp@latest     # installs + registers globally
opencode plugin list                                    # verify: opencode-dcp 3.2.0
opencode plugin update                                  # later
```

Config search order (later wins): `~/.config/opencode/dcp.jsonc` →
`$OPENCODE_CONFIG_DIR/dcp.jsonc` → `.opencode/dcp.jsonc` (this project).

Project config — `.opencode/dcp.jsonc`:

```jsonc
"compress": {
  "minContextLimit": 250000,   // reminders start here
  "maxContextLimit": 350000,   // strong compression nudges here
  "nudgeFrequency": 5,
  "protectTags": true
}
```

- The model window is 1M; **250k/350k are quality/cost guards**, not capacity.
- `summaryBuffer: false` keeps the configured threshold at `maxContextLimit`.
  With it enabled, DCP adds the active summary tokens to the effective maximum,
  so a 20k summary would push the threshold to 370k — past the policy's hard
  trigger. DCP compares usage with `>` against the latest completed assistant
  message, so the nudge fires *after* 350k: it is a reminder, not an exact
  tripwire. The operator enforces the handoff.
- **Config is read at session start.** Restart OpenCode after editing it.
- Commands: **`/dcp`** (panel: stats, decompress, recompress, help) and
  **`/dcp-compress [focus]`** (one manual compression pass, optional focus).
- `/dcp` is the live test: it shows context, stats, and the active limits.

### 2.2 Superpowers — install, skills, mapping

```jsonc
// opencode.json (V2 form, OpenCode 2.0.4+)
"plugins": [
  "./.opencode/plugins/ccgs-hooks.ts",
  "./.opencode/plugins/drift-detector.ts",
  "./.opencode/plugins/changelog-generator.ts",
  "superpowers@git+https://github.com/obra/superpowers.git"
]
```

The git-backed install **worked on Windows** here; no npm fallback was needed. If
a future OpenCode/Bun build fails to install it:

```powershell
npm install superpowers@git+https://github.com/obra/superpowers.git --prefix "$HOME\.config\opencode"
```

then use the **absolute** package directory in `plugins`
(`C:\\Users\\<you>\\.config\\opencode\\node_modules\\superpowers`) — OpenCode does
not expand `~`. Verify with `opencode plugin list` and by asking *"Tell me about
your superpowers"*.

Skills load through OpenCode's native `skill` tool. The set and its OCGS mapping:

| Superpowers skill | Use it for | OCGS counterpart / boundary |
|---|---|---|
| `using-superpowers` | Bootstrap; skill discipline | — (loaded automatically) |
| `brainstorming` | Turning a vague request into a design | OCGS `/concept-brainstorm`, `/design-system` own **game** design |
| `writing-plans` | Multi-step implementation plans | OCGS `/create-stories` owns the story breakdown |
| `executing-plans` | Inline plan execution | OCGS `/dev-story` owns story execution |
| `subagent-driven-development` | Task-per-subagent with review | OCGS lane runners are the outer layer |
| `dispatching-parallel-agents` | 2+ independent tasks | OCGS **WIP limits** still cap concurrency |
| `test-driven-development` | RED-GREEN-REFACTOR | OCGS coding standards require tests-first |
| `systematic-debugging` | Root-cause before fixing | OCGS `/bug-report` for the record |
| `verification-before-completion` | Evidence before "done" | OCGS gates + `/smoke-check` |
| `requesting-code-review` / `receiving-code-review` | Pre-review + feedback triage | OCGS `/code-review` + CodeRabbit are the gate |
| `using-git-worktrees` | Isolated workspaces | OCGS `npm run task:new` is the sanctioned creator |
| `finishing-a-development-branch` | Merge/PR/keep/discard | OCGS git rules: branch + PR + squash, never Main |
| `writing-skills` | Authoring skills | OCGS `/skill-test`, `/skill-improve` |
| `diagnosing-superpowers` | Why a session went wrong | — |

---

## 3. When to use / when not to

| Situation | Use | Do **not** use |
|---|---|---|
| A new GDD section | `/design-system` (OCGS) | Superpowers `brainstorming` — the design process is OCGS's |
| A vague feature idea | Superpowers `brainstorming` **inside a lane** | It cannot replace the CD gate or the GDD |
| A multi-step implementation | `writing-plans` → `executing-plans` or `subagent-driven-development` | Ad-hoc edits without a plan |
| A bug in code | `systematic-debugging` → fix → `verification-before-completion` | Guessing a fix |
| "Is it done?" | `verification-before-completion` (run the command) | Claiming success from memory |
| A long session at 250k | `CONTEXT-POLICY.md` handoff; DCP `compress` for closed spans | Compaction as a substitute for a handoff |
| Two independent spikes | `dispatching-parallel-agents` **within** the WIP limits | Spawning beyond 3 active runners |
| A new worktree | `npm run task:new -- <type>/<topic>` | Raw `git worktree add` (skips the base fetch) |
| Editing a GDD | The lane prompt + `lane-kickoff-master.md` | Superpowers skills (they do not know the frozen contracts) |
| Merging | Branch + PR `--base Main` + squash | Direct push, force-push, merge on Main |
| Removing a module | `install.mjs remove <one>` + validation plan | `rm -rf` on `.agents/` or `.opencode/` |

---

## 4. Division of labor: OCGS vs Superpowers

**OCGS owns the studio.** Process, GDDs, gates, lane orchestration, WIP limits,
model routing, frozen contracts, registry/sync, release.

**Superpowers owns the implementation methodology inside a lane.** TDD, plans,
systematic debugging, code review, worktrees, parallel subagents.

```text
OCGS:  concept → systems map → GDD → CD gate → 3 seats → spot-check → sync → PR → merge
Superpowers:                       └── plan → TDD loop → review → verify ──┘
```

**Conflict rule — the lane prompt and `STATE.md` win.** If a Superpowers skill and
a lane instruction disagree about *what* to do or *when to stop*, the lane wins.
Superpowers may choose *how* to implement within the lane's scope; it may not
change scope, gates, WIP limits, model routing, or frozen contracts.

---

## 5. Model routing (hard rule, unchanged)

| Division | Model |
|---|---|
| **Creative** — art, audio, narrative, world/level, UX/UI, game design, memory, inventory | `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash` |
| **Technical** — save/serialization, progression/economy math, ADRs, QA, sync, engineering | `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017` |

The lane runner's model is the manifest `model`; seats are set per their briefs.
A creative lane that ran on DS is rerun on GLM.

**Failure fallback (user decision, 2026-11-15)**: up to 4 spawn attempts on
server-side errors (`ProviderModelNotFoundError`, `AiError: Capacity temporarily
exceeded`, HTTP 5xx / rate limits). Then the asymmetry applies: **DS → GLM** is
an authorized autonomous fallback (recorded in `decisions.md`); **GLM → DS is
forbidden** without an explicit user decision — creativity is not to be
compromised by a fallback. Park the lane `PAUSED` and surface the decision, or
issue a launch package for a parallel chat on the same model.

---

## 6. Context policy (summary)

- **Soft 250k**: update `STATE.md`, write the handoff, finish the atomic step,
  stop starting new work.
- **Hard 350k**: stop and hand off.
- Window is 1M; the cap is quality, cost, and latency.
- Modes: (a) fresh chat — default for creative/design/architecture; (b) `/clear` —
  technical/ops, transcript saved, context verifiably empty; (c) compaction —
  mechanical only, with *"the summary is an index, not the source of truth."*
- DCP `compress` buys room inside a session; it is **not** a handoff.
- Harness auto-compaction is a backstop at ~898k (`compaction.buffer: 150000`).

Full policy and measured thresholds: **`CONTEXT-POLICY.md`**.

---

## 7. The 10-minute walkthrough

1. **Minute 0–2 — inventory.** `node .opencode/modules/install.mjs list --harness
   opencode` → 22 × `installed` @ 0.6.0. Confirm `engine-godot` is present and the
   non-Godot engines are the only unused ones.
2. **Minute 2–4 — plugins.** `opencode plugin list` → 5 entries (3 OCGS + DCP
   3.2.0 + Superpowers 22f0b46). In a session, type `/dcp` and read the panel.
3. **Minute 4–6 — skills.** Ask *"Tell me about your superpowers"*, then load
   `test-driven-development` with the `skill` tool. Read its first 20 lines.
4. **Minute 6–8 — orchestration.** `node tools/orchestration/render-prompts.mjs
   --check` → ✔. Open `prompts/NEXT.md`; compare its `Hash:` to
   `manifest.yaml` → `next.hash` (`555c18812b03`).
5. **Minute 8–10 — the policy.** Read `CONTEXT-POLICY.md` §2–§3. Decide which mode
   you would use to hand off *this* session, and why.

---

## 8. Three exercises

**Exercise 1 — audit without installing (5 min).**
Run the list command. For each module in §1, name one project artifact it would
produce (e.g. `qa` → `/qa-plan`; `engine-godot` → the GDScript specialist). If
you cannot name one for a module, flag it as a removal candidate — do not remove
it in the same breath.

**Exercise 2 — prove a plugin is live (5 min).**
In a fresh session: run `/dcp`, note the reported limits (should read 250000 /
350000 after a restart). Then ask the agent to load `verification-before-completion`
and have it state what evidence it would require before claiming a test passes.
If `/dcp` reports 100000, the session predates the config — restart and repeat.

**Exercise 3 — write a handoff at 250k (10 min).**
Copy `prompts/handoff.md`, fill every section for a real lane, and check it
against the seven questions in `CONTEXT-POLICY.md` §5. Then run the paste-check
and confirm the hash. Do not paste it yet; the point is the muscle memory.

---

## 9. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `/dcp` missing | Plugin not loaded | `opencode plugin list`; restart; check `~/.config/opencode/opencode.json` |
| DCP nudges at 100k | Session started before the project config landed | Restart OpenCode |
| Superpowers skills absent | Git install failed | npm fallback + absolute path (§2.2) |
| `configured plugin path must be a directory` warning | OCGS local `.ts` plugins load as files | Harmless; the plugins still load |
| `--check` hash mismatch | A prompt was hand-edited | Re-run the renderer; never hand-edit generated prompts |
| Module files missing after a checkout | Windows symlinks inert | `npm run fix:symlinks` / Developer Mode |
