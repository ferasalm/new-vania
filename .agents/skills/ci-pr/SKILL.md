---
name: ci-pr
description: "Run the GitHub Actions checks locally, then ship a change through a worktree, conventional commit, pull request, CodeRabbit review, and merge."
argument-hint: "[branch-or-pr-number]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Task, question
agent: devops-engineer
---

# CI + PR Workflow

Use this skill whenever a change needs to leave the working tree and reach the
repository's default branch (`Main` in this repo; `development` only if it is
the default). It mirrors the house rules in `AGENTS.md` and the repository SOPs:
never commit on the default branch, always use a worktree, run the same checks
as CI before pushing, and merge only after CI and CodeRabbit are green.

---

## Phase 1: Preflight

Read the repository state before writing anything.

```bash
git -C <repo> status --short --branch
git -C <repo> worktree list
git -C <repo> log --oneline -5
gh auth status
gh repo view <owner>/<repo> --json defaultBranchRef --jq '.defaultBranchRef.name'
node --version
npm --version
```

Set `DEFAULT_BRANCH` from the `gh repo view` output. Query the remote rather
than reading `refs/remotes/origin/HEAD`, which can stay stale after a
default-branch rename.

If the argument is a PR number, record it as `PR_NUMBER` and use it in Phase 6.

Confirm:

- `gh` is authenticated and points at the expected repository.
- Node is 20 or newer (CI uses Node 20).
- The current checkout is not the default branch; if it is, do not commit there.
- Any dirty files on the default branch are user work. Ask before moving or
  discarding them.

If the change is already on a feature branch with a clean worktree, skip to
Phase 3.

Before moving files, creating a worktree, committing, or merging, ask the user:
"May I write ...?" The only exception is a step the user has already approved
explicitly in this session.

---

## Phase 2: Isolate the Work in a Worktree

Create one worktree per topic from `DEFAULT_BRANCH`:

```bash
git -C <repo> worktree add ../<repo>-<topic> -b <branch> "$DEFAULT_BRANCH"
```

If the branch already exists on the remote, omit `-b` and check it out instead:

```bash
git -C <repo> worktree add ../<repo>-<topic> <branch>
```

When `PR_NUMBER` is set, resolve its head branch and reuse an existing worktree
for that branch if one exists; otherwise create the worktree from the PR branch:

```bash
gh pr view "$PR_NUMBER" --repo <owner>/<repo> --json headRefName --jq '.headRefName'
git -C <repo> worktree list
```

Branch naming:

| Prefix | Use |
|---|---|
| `feat/<topic>` | New behavior or capability |
| `fix/<topic>` | Bug fix |
| `docs/<topic>` | Documentation or design content |
| `chore/<topic>` | Tooling, dependencies, maintenance |
| `ci/<topic>` | Workflow or CI-only change |

If the changes are currently uncommitted in the default-branch checkout,
transfer only the approved paths into the worktree.

**Untracked files and directories** — move them:

```powershell
# Windows
Move-Item -LiteralPath <main-repo>\path\to\change -Destination <worktree>\path\to\change
```

```bash
# POSIX
mv <main-repo>/path/to/change <worktree>/path/to/change
```

**Tracked files with uncommitted edits** — copy the diff, apply it in the
worktree, then restore only those paths in the original checkout:

```bash
git -C <main-repo> diff HEAD --binary -- <paths> > /tmp/ci-pr.patch
git -C <worktree> apply /tmp/ci-pr.patch
git -C <main-repo> restore --source=HEAD --staged --worktree -- <paths>
```

Never use a hard reset or a forced clean to make the checkout appear clean.
Leave unrelated changes alone.

Then verify the main checkout is clean and the worktree contains the changes:

```bash
git -C <main-repo> status --short
git -C <worktree> status --short
```

Never create two worktrees for the same topic, and never work in a worktree
another agent is using.

---

## Phase 3: Run Local CI

Run the local mirror of both GitHub workflows from the worktree created in
Phase 2 — not from the original checkout:

```bash
cd <worktree>
npm ci
npm run ci
```

The runner resolves its own repository root from `tools/ci/run-local.mjs`, so
the current directory must be the worktree that contains the change.

The runner maps directly to the workflows:

| Workflow | Local job | Commands |
|---|---|---|
| `test.yml` | `test` | `npm test` |
| `agent-validation.yml` | `agents` | `node tests/agents/validate.mjs`, `node tests/workflow/run-all.mjs`, `node tests/modules/validate-modules.mjs`, `npm run test:modules`, `npm run test:plugins` |
| both | `all` (default) | Both jobs; plugin tests run once |

Useful variants:

```bash
npm run ci -- --job test
npm run ci -- --job agents --skip-install
npm run ci -- --list
```

If a step fails, read the first real error, fix it, and rerun. Two consecutive
failures of the same step means stop and report — do not improvise a third
attempt.

A step is `PASS` only when it exits 0; any other exit code is `FAIL`. Do not
push while local CI is red.

---

## Phase 4: Commit

Stage only the intended files and inspect the diff:

```bash
git -C <worktree> add <paths>
git -C <worktree> diff --cached --stat
git -C <worktree> diff --cached
```

Use Conventional Commits:

```text
<type>(<scope>): <imperative summary>

- What changed and why
- Any user-visible behavior or migration note

Refs: <design doc, issue, or PR>
```

Rules enforced by `.githooks/commit-msg`:

- Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `build`, `ci`.
- Lowercase type and scope; no trailing period; header ≤ 100 characters.
- A `!` header requires a `BREAKING CHANGE:` footer.

Never bypass a hook to force a commit. If a hook fails, fix the cause.

---

## Phase 5: Push and Open the PR

```bash
git -C <worktree> push -u origin <branch>

# Reuse an existing open PR for this branch before creating a new one.
PR_NUMBER=$(gh pr list --repo <owner>/<repo> --head <branch> --state open \
  --json number --jq '.[0].number')

if [ -n "$PR_NUMBER" ]; then
  echo "Reusing PR #$PR_NUMBER"
else
  gh pr create --repo <owner>/<repo> --base "$DEFAULT_BRANCH" --head <branch> \
    --title "<conventional title>" --body-file <pr-body.md>
fi
```

If the argument was a PR number, use it directly and skip both the lookup and
creation. Continue with Phase 6 either way.

The PR body must include:

- **Summary** — what changed and why.
- **Validation** — the local commands that passed, with counts.
- **Risk / rollback** — anything reviewers should know.
- **Refs** — design docs or issues.

Keep PRs focused: one feature or fix per PR. If the change mixes unrelated
concerns, split it into separate branches and PRs.

---

## Phase 6: Watch GitHub Actions

```bash
gh pr checks <pr-number> --repo <owner>/<repo> --watch --interval 10
```

For a failing run, inspect the failed logs:

```bash
gh run list --repo <owner>/<repo> --branch <branch> --limit 5
gh run view <run-id> --repo <owner>/<repo> --log-failed
```

Fix locally, rerun `npm run ci`, commit, and push. Do not merge with queued,
pending, or failing checks.

---

## Phase 7: Handle CodeRabbit Feedback

CodeRabbit reviews automatically when the PR opens. Wait for the review, then
read both the summary and the inline threads:

```bash
gh pr view <pr-number> --repo <owner>/<repo> --comments
gh api repos/<owner>/<repo>/pulls/<pr-number>/comments --paginate
gh api repos/<owner>/<repo>/pulls/<pr-number>/reviews --paginate
```

Triage every finding:

| Finding | Action |
|---|---|
| Real bug, security issue, broken test | Fix it, add or adjust a test, push |
| Correct observation but out of scope | Reply with the reason and open a follow-up issue |
| False positive | Reply with evidence and resolve the thread |
| Style preference already covered by repo rules | Reply with the rule reference |

After pushing fixes, request a re-review:

```text
@coderabbitai review
```

Do not resolve a thread without either fixing it or documenting why it does not
apply. Keep the PR conversation factual and link to the relevant file or test.

---

## Phase 8: Merge Gate

Merge only when all of these are true:

- [ ] Local CI is green (`npm run ci`).
- [ ] GitHub Actions checks are green (`gh pr checks`).
- [ ] CodeRabbit findings are fixed or explicitly dispositioned.
- [ ] The user has reviewed the deliverable summary (G2 gate).
- [ ] A pre-merge backup tag exists.

Create the revert point before merging:

```bash
git -C <main-repo> tag -a backup/<repo>-<default-branch>-pre-pr<pr-number>-<YYYYMMDD> \
  -m "Revert point before PR #<pr-number>" "$DEFAULT_BRANCH"
```

Then merge with a merge commit (matching the repository history):

```bash
gh pr merge <pr-number> --repo <owner>/<repo> --merge
```

Do not use `--delete-branch`; branch and worktree removal is the user's call.

---

## Phase 9: Close Out

Sync the main checkout and report:

```bash
git -C <main-repo> pull --ff-only
git -C <main-repo> log --oneline -3
git -C <main-repo> worktree list
```

Report:

- PR number and merge commit.
- CI result and CodeRabbit disposition.
- Any follow-up issues opened.
- The worktree path and branch name, left in place for the user to remove.

---

## Recommended Next Steps

- Run `/code-review` for a deeper architectural review before merging.
- Run `/changelog` after merge when the change is user-facing.
- Open follow-up issues for CodeRabbit findings you deliberately deferred.

## Hard Rules

- Never commit directly to the default branch (`Main`, `master`, or `development`).
- Never rewrite history or discard uncommitted work; never force a push.
- Never bypass commit or push hooks.
- Never merge with red or pending checks.
- Never delete a branch, tag, or worktree without explicit user approval.
- Two consecutive failures of any step: stop, diagnose, report.
