# `.opencode/*` symlink vs. junction conflict on Windows

Tooling record for the `new-vania` repo. Measured on 2026-11-13 with Git
**2.56.0.windows.2** on Windows 11, PowerShell 5.1, non-administrator shell,
OpenCode **v2.2.2**.

**Status: resolved structurally (2026-11-13).** The four paths are no longer
tracked: `.gitignore` excludes them and `npm install` generates them through
`tools/fix-opencode-symlinks.mjs` (junction on Windows, directory symlink on
POSIX), so the index and the filesystem can no longer disagree. The
index-level guard in `tools/git-hooks/pre-commit.mjs` stays as defence for
clones that predate this change. The `mode: all` agent commit (`3c494fe`) is
unrelated to this defect.

---

## 1. Summary

Git tracks `.opencode/{agents,commands,skills,rules}` as **symlinks**. On this
machine they exist on disk as **NTFS junctions**, because real symlinks require
Developer Mode or administrator rights and neither is available. Git cannot
represent a junction, so a full index scan (`git add -A`) reads the paths as
"symlink deleted, 228 files added". `git status` hides this behind cached
`stat` data, and the pre-commit hook validates the filesystem instead of the
index, so nothing stops the conversion from being committed.

The risk is not the file count. On a POSIX clone the converted paths become
independent copies, so edits under `.agents/` stop propagating and the two
trees drift silently.

---

## 2. Evidence

```
$ git ls-files -s .opencode/agents
120000 4c8a5fc93dd07a2f87261d230b24fa63ddaa0c4f 0        .opencode/agents

$ git config --get core.symlinks
false                          # repo-local, .git/config

$ Get-Item .opencode/agents | Select Name,LinkType
agents    Junction              # -> .agents\agents, created 2026-11-08

$ git status --short
                               # clean: stat cache skips the mismatch

$ git add -A --dry-run | Measure-Object -Line
232                            # 4x "remove '.opencode/<name>'" + 228 adds
```

Creating a real symlink fails on this machine:

```
New-Item -ItemType SymbolicLink ...
  Administrator privilege required for this operation.
```

Consequence already observed once: a `git add -A` produced a 388-file commit
(156 intended + 232 unintended). It was reset before pushing.

---

## 3. Root cause chain

1. `.opencode/{agents,commands,skills,rules}` are committed as `120000`
   symlinks to `../.agents/<name>`.
2. With `core.symlinks=false`, `git checkout` writes a **text stub** containing
   the target path instead of a link. OpenCode's `.opencode/` discovery then
   silently finds nothing — documented in `tools/fix-opencode-symlinks.mjs:5-10`.
3. `tools/fix-opencode-symlinks.mjs` repairs the stub by replacing it with a
   **junction** (`fs.symlinkSync(..., "junction")`, line 70), which needs no
   elevation.
4. Index and working tree now describe the same path incompatibly: symlink vs.
   directory. Git has no way to reconcile them.
5. `git status` reports clean because the cached `stat` data matches; only a
   content scan such as `git add -A` exposes the difference.
6. `tools/git-hooks/pre-commit.mjs:246-271` checks the **filesystem** and
   explicitly accepts a directory:

   ```js
   if (!stat.isDirectory()) {
       errors.push(`.opencode/${name} is neither a link, redirect stub nor directory.`)
   }
   ```

   A junction passes. The hook never inspects the **index**, so it validates
   the wrong side of the conflict. Hooks are active
   (`core.hooksPath=.githooks`), which makes the gap easy to miss.

---

## 4. Options

| Approach | Fixes root cause | Assessment |
| --- | --- | --- |
| Discipline: explicit `git add <paths>`, never `-A` | No | Already failed once. Not enforceable across agents and scripts. |
| `git update-index --skip-worktree` on the 4 paths | No | Guards `-A`, but per-clone, invisible to other machines, and hides a broken junction from `git status`. |
| Enable Developer Mode + `core.symlinks=true`, re-checkout | **Yes** | Disk then matches HEAD exactly. Requires an OS-level change and elevation once; unavailable here. |
| Track the junctions as real directories | No | ~228 duplicated files, and POSIX clones get two independent trees that drift. Contradicts `AGENTS.md`. |
| **Index-level pre-commit guard** | Blocks the symptom | Small, additive, protects every human and agent. |
| **Untrack the 4 links, generate them post-clone** | **Yes** | Removes the conflict rather than guarding it; adds a setup step and changes the committed layout. |

Recommended sequence: the index guard first (cheap, immediate), the untracking
change second if the setup-step cost is acceptable.

**Landed 2026-11-13:** `checkFrameworkLinkStaging` in
`tools/git-hooks/pre-commit.mjs` reads `git diff --cached --name-status` and
blocks a staged deletion, retype, or addition beneath any of the four link
paths. Covered by four tests in `tests/git-hooks/test-pre-commit.mjs`, and
verified against this repository: staging `.opencode/agents` produced
`D .opencode/agents` plus 52 `A` entries and the commit was rejected with the
recovery command in the message.

**Landed 2026-11-13 (structural):** the untracking option. See §7.

---

## 5. Handoff brief

Copy everything inside the block:

```
Repo: C:\Users\AUC\opencode-workspace\workspace\new-vania (Windows 11, non-admin)
Git: 2.56.0.windows.2. `core.symlinks=false` set in .git/config (repo-local).
Creating real symlinks fails: "Administrator privilege required".

CONFLICT
- Git tracks .opencode/{agents,commands,skills,rules} as symlinks
  (mode 120000 -> ../.agents/<name>).
- On disk they are NTFS junctions -> .agents/<name>, created by
  tools/fix-opencode-symlinks.mjs, because with core.symlinks=false git writes
  inert text stubs that break OpenCode discovery.
- git status reports clean (stat cache), but `git add -A --dry-run` stages
  4x "remove '.opencode/<name>'" plus 228 added files = 232 changes.
- tools/git-hooks/pre-commit.mjs:246-271 validates the filesystem and accepts a
  directory, so it passes. It never inspects the index.
  Hooks are active (core.hooksPath=.githooks).

GOAL
Make it impossible for `git add -A` (human or agent) to commit the
symlink->directory conversion, while keeping junctions working on this machine
and keeping POSIX clones (real symlinks) working.

CONSTRAINTS
- No admin / Developer Mode.
- Do not change the symlink representation that POSIX clones rely on.
- Keep npm test green; add a unit test for any new hook logic.

SUGGESTED FIX (evaluate, do not assume)
1. Add an index-level guard to tools/git-hooks/pre-commit.mjs: fail when staged
   changes delete or retype .opencode/{agents,commands,skills,rules}, or add
   files beneath them. The message should point at
   tools/fix-opencode-symlinks.mjs and `git restore --staged .opencode`.
2. Optionally untrack the 4 links, add them to .gitignore, add an
   `npm run fix:symlinks` script, and document the post-clone step.
3. Add tests in tests/git-hooks/test-pre-commit.mjs for blocked and allowed cases.

ACCEPTANCE
- `git add -A` followed by a commit is rejected with a clear message.
- Normal commits (e.g. editing .agents/agents/x.md) still pass.
- npm test green.
```

---

## 6. Verification notes for whoever implements this

- Reproduce the trap with `git add -A --dry-run`; expect 232 lines. Do not run
  plain `git add -A` — it rewrites the index and must be undone with
  `git restore --staged .opencode`.
- The guard must read the **index** (`git diff --cached --name-status`), not the
  working tree. Checking the filesystem is what already fails.
- A correct guard leaves the junction untouched on disk; it only refuses to
  stage it.
- After any accidental staging, recovery is to unstage only the four link
  entries:
  `git restore --staged .opencode/agents .opencode/commands .opencode/rules .opencode/skills`
  then check `git diff --cached` and re-stage any intended `.opencode/modules`
  or `.opencode/plugins` changes. The working tree is not modified.
- Related files: `tools/fix-opencode-symlinks.mjs`,
  `tools/git-hooks/pre-commit.mjs`, `tests/git-hooks/test-pre-commit.mjs`,
  `AGENTS.md` (project structure section).

---

## 7. Structural fix (landed 2026-11-13)

The four paths are **generated, not tracked**.

| Before | After |
| --- | --- |
| Index holds `120000` symlinks | Index holds nothing for these paths |
| `git checkout` writes stubs, then a script repairs them | `npm install` creates the link directly |
| Index and disk can disagree | They cannot: git no longer sees the paths |
| `git add -A` stages a 232-entry conversion | `git add -A` stages nothing for them |

Implementation:

- `.gitignore` excludes `/.opencode/{agents,commands,rules,skills}`.
- `tools/fix-opencode-symlinks.mjs` creates each link: an NTFS **junction** on
  Windows (no elevation), a directory **symlink** on POSIX. It is idempotent,
  reports a materialised directory instead of deleting it, and supports
  `--check` (exit 1 when a link is missing or broken).
- `package.json` runs it from `prepare`, so `npm install` and `npm ci` create
  the links automatically. `npm run fix:symlinks` and `npm run check:symlinks`
  are the manual forms.
- `AGENTS.md` structure section and the pre-commit description now say
  "generated link", not "symlink"/"redirect stub".

Consequences to know:

- **A clone must run `npm install` once** before OpenCode can discover the
  agents/skills/commands/rules through `.opencode/`. The repository already
  required that step for the git hooks and the `tsx` loader, so no new
  prerequisite is introduced.
- Other harnesses (Pi, omp, Claude Code, Codex) read `.agents/` directly and
  are unaffected.
- The index guard stays. A clone that has not pulled this change still has the
  symlinks tracked, and the guard protects it during the transition.
- `.opencode/plugins/` and `.opencode/modules/` remain tracked; only the four
  mirrors are generated.

Migration for an existing clone: pull, then `npm install` (or
`npm run fix:symlinks`). The junctions already on disk are left untouched —
the generator reports them as `ok`.
