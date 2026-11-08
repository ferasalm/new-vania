# Skill Test Spec: /ci-pr

> **Category**: utility
> **Priority**: high
> **Spec written**: 2026-11-08

## Skill Summary

`/ci-pr` ships a change from a dirty working tree to a merged pull request. It
creates a worktree, runs the local mirror of both GitHub Actions workflows,
commits with Conventional Commits, opens a PR, watches CI, triages CodeRabbit
feedback, and merges only after the user-approved merge gate passes.

The skill produces a branch, a PR, a merge commit, and a close-out report. It
does not delete branches or worktrees; that remains the user's call.

---

## Static Assertions

- [ ] Frontmatter has `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has 2+ phase headings
- [ ] Contains `PASS` and `FAIL` verdict language
- [ ] Contains `"May I write"` approval language
- [ ] Ends with a next-step handoff section
- [ ] Does not instruct `git reset --hard`, `git clean -fd`, force-push, or `--no-verify`

---

## Director Gate Checks

- **Full mode**: User reviews the deliverable summary before merge.
- **Lean mode**: Same merge gate; CodeRabbit is the automated reviewer.
- **Solo mode**: No director gates, but the user still approves the merge.
- **N/A**: Not a game-design skill; no creative director gates apply.

---

## Test Cases

### Case 1: Happy Path — Dirty Main checkout to merged PR

**Fixture:**
- `Main` checkout has untracked design files.
- No open PR for the topic.
- `gh` is authenticated; CI is green on `Main`.

**Input:** `/ci-pr`

**Expected behavior:**
1. Skill reports the dirty `Main` state and asks before moving files.
2. Skill creates `../<repo>-<topic>` on a `docs/<topic>` branch.
3. Skill moves the untracked files and confirms `Main` is clean.
4. Skill runs `npm ci` and `npm run ci`; all steps `PASS`.
5. Skill commits with a Conventional Commit and pushes the branch.
6. Skill opens a PR to `Main` with summary, validation, and refs.
7. Skill waits for GitHub Actions and CodeRabbit.
8. Skill addresses or dispositions every finding.
9. Skill creates the backup tag and merges after user approval.

**Assertions:**
- [ ] No commit is made on `Main`
- [ ] Worktree path and branch name are reported
- [ ] `npm run ci` is run before the first push
- [ ] PR body includes validation commands and results
- [ ] Merge happens only after checks are green and the user approves
- [ ] Branch and worktree are left in place

**Case Verdict**: PENDING (run `/skill-test spec ci-pr`)

---

### Case 2: Failure / Blocked — Local CI fails

**Fixture:**
- Worktree contains a change that breaks `tests/workflow/run-all.mjs`.
- `npm run ci` exits 1.

**Input:** `/ci-pr`

**Expected behavior:**
1. Skill reports the failing step and its first real error.
2. Skill fixes the cause and reruns `npm run ci`.
3. If the same step fails twice, skill stops and reports instead of pushing.

**Assertions:**
- [ ] No push or PR is created while CI is red
- [ ] The failing command and exit code are reported
- [ ] Two consecutive failures trigger a stop
- [ ] Skill does not bypass the failure with `--no-verify`

**Case Verdict**: PENDING (run `/skill-test spec ci-pr`)

---

### Case 3: Mode Variant — PR already open

**Fixture:**
- Branch is already pushed and PR #N exists.
- New CodeRabbit comments arrived after the last push.

**Input:** `/ci-pr 42`

**Expected behavior:**
1. Skill detects the existing PR and skips worktree creation.
2. Skill reads PR checks and CodeRabbit threads.
3. Skill fixes valid findings, pushes, and requests `@coderabbitai review`.
4. Skill rechecks the merge gate after the new review.

**Assertions:**
- [ ] Existing PR is reused instead of opening a duplicate
- [ ] CodeRabbit findings are triaged, not blindly accepted
- [ ] Merge gate is re-evaluated after new commits

**Case Verdict**: PENDING (run `/skill-test spec ci-pr`)

---

### Case 4: Edge Case — Merge blocked by branch protection

**Fixture:**
- All checks are green, but `gh pr merge` is rejected by branch protection.

**Input:** `/ci-pr`

**Expected behavior:**
1. Skill reports the protection rule and the exact `gh` error.
2. Skill does not force-push or bypass protection.
3. Skill asks the user to resolve the rule or merge manually.

**Assertions:**
- [ ] No force-push is attempted
- [ ] No admin bypass is attempted
- [ ] User receives the exact blocker and next action

**Case Verdict**: PENDING (run `/skill-test spec ci-pr`)
