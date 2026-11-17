# After midnight: the delayed chores, in order

Written 2026-11-16 by Helper 3. These were held back during the sprint. Do them in this order.
Nothing here was run by the author. Every `gh` and `git` command below is a template: read it before running it.

Repository: `ferasalm/new-vania`. Default branch: `Main`. Commands and rules in full: the `/ci-pr` skill.

**Three rules that apply to every step**

1. **The user says yes before any merge.** Ask "Merge PR #<n>?" and wait.
2. **CodeRabbit: at most two rounds per pull request.** If findings are still open after round two, stop and ask the user.
3. **The user removes worktrees and branches.** Never delete them. Never force-push. Never `reset --hard`.

## Where things stand (check before starting)

| Branch | Worktree | Pull request | Status when this was written |
|---|---|---|---|
| `feat/proto-v3-android` | `workspace\new-vania` (main checkout) | #102, open | waiting on review |
| `feat/proto-v3-patch` | `workspace\new-vania-proto-v3-patch` | none yet | sprint work still landing; check `active.md` |
| `feat/pogr-skill` | `workspace\new-vania-pogr-skill` | none yet | pushed (commits `797a7a2`, `6892482`); checks green |

Check the real state first:

```bash
gh pr list --repo ferasalm/new-vania --state open
git -C /c/Users/AUC/opencode-workspace/workspace/new-vania worktree list
git -C /c/Users/AUC/opencode-workspace/workspace/new-vania-proto-v3-patch status --short --branch
```

If the patch worktree has changes that are not committed: commit them first (stage in one command,
commit in the next), then push. Never leave finished work only on this machine.

## Step 1: PR #102 (Android build), `feat/proto-v3-android`

1. Read the checks: `gh pr checks 102 --repo ferasalm/new-vania`
2. Read the CodeRabbit review: `gh pr view 102 --repo ferasalm/new-vania --comments`
3. Fix real findings in the main checkout (it is on that branch). Reply with a reason to the others.
   Push. Ask for a re-review with the comment `@coderabbitai review`. **That is round one.** One more round at most.
4. Local checks before each push, from that checkout: `npm run ci` (pass: "5/5 steps passed") and the
   self-test (pass: `SMOKE PASS`).
5. Stop here until the user has said yes to merging. Then go to step 5 and 6 for this pull request.

## Step 2: a pull request for `feat/proto-v3-patch`

This branch was cut from `feat/proto-v3-android`. So it contains everything in #102.

- **Simplest route (recommended):** merge #102 first (steps 5 and 6), then open the patch pull request against `Main`. Its diff then shows only the patch.
- If #102 is not merged yet and a review is wanted now: open the patch pull request with
  `--base feat/proto-v3-android`. Change the base to `Main` after #102 is merged.

```bash
cd /c/Users/AUC/opencode-workspace/workspace/new-vania-proto-v3-patch
npm run ci
timeout 110 "/c/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless --path prototypes/feel-v3 res://smoke.tscn
git push -u origin feat/proto-v3-patch
gh pr create --repo ferasalm/new-vania --base Main --head feat/proto-v3-patch \
  --title "feat(feel-v3): playtest patch" --body-file <pr-body.md>
```

The body must say: what changed, the checks that passed with their numbers, what was **not run**
(for example: "not installed on a phone"), and that `assets/hero/` is not in the repository.
Write the body to a file with the file-write tool. Do not use an inline heredoc.

Before opening it, make sure no file from `assets/hero/`, `assets/references/`, `tools/pristine/` or
`build/` is in the diff: `git diff --stat origin/Main...HEAD | grep -E "assets/hero/|references/|pristine|build/"` must print nothing.

## Step 3: a pull request for `feat/pogr-skill`

Independent of the other two. It branches from `Main` and changes only framework files.

```bash
cd /c/Users/AUC/opencode-workspace/workspace/new-vania-pogr-skill
npm run ci                      # pass: "Result: 5/5 steps passed."
npm run claude:check            # pass: ".claude/ mirror is in sync"
gh pr create --repo ferasalm/new-vania --base Main --head feat/pogr-skill \
  --title "feat(skills): add the pogr skill" --body-file <pr-body.md>
```

Things a reviewer should know (put them in the body):

- The docs now say 80 skills and 80 commands. Before, they said 78 and did not count `/ci-pr`.
- There are 86 skill folders on disk. Six of them have no slash command (`agents-orchestrator`, four
  `engineering-*`, `project-management-studio-operations`) and are not in the count of 80.
- The "Field notes" part of the skill was filled from the lead's notes of the first sprint.

After it is merged: every other branch gets `/pogr` only when it is updated from `Main`.

## Step 4: CodeRabbit rounds (each pull request)

1. Wait for the first review. Read the summary and the inline threads.
2. Sort every finding: real problem (fix it, add a test), right but out of scope (reply, open an issue),
   wrong (reply with the evidence).
3. Push the fixes. Comment `@coderabbitai review`. That was round one.
4. One more round at most. **After round two, stop and ask the user**, with the open findings listed.

Do not close a thread without a fix or a written reason.

## Step 5: backup tag (before each merge)

```bash
cd /c/Users/AUC/opencode-workspace/workspace/new-vania
git fetch origin
git tag -a backup/new-vania-Main-pre-pr<number>-20261117 -m "Revert point before PR #<number>" origin/Main
git push origin backup/new-vania-Main-pre-pr<number>-20261117
```

Use the real date. One tag per pull request.

## Step 6: merge (only after the user says yes)

Checklist. All five must be true:

- [ ] Local checks green (`npm run ci`, and the self-test for the game branches).
- [ ] GitHub checks green: `gh pr checks <number> --repo ferasalm/new-vania`
- [ ] CodeRabbit findings fixed or answered.
- [ ] The backup tag exists and is pushed.
- [ ] The user said yes to this pull request, by number.

```bash
gh pr merge <number> --repo ferasalm/new-vania --merge
```

Do not add `--delete-branch`. Suggested order: #102, then the patch, then pogr (pogr may go at any time).

## Step 7: after the merges

1. Update the main checkout. It is on `feat/proto-v3-android`, not on `Main`, so do not pull into it blindly:
   `git -C /c/Users/AUC/opencode-workspace/workspace/new-vania fetch origin` and report what `git status` says.
2. Update `production/session-state/active.md` (main checkout): what merged, the merge commits, what is next.
3. Tell the user which worktrees and branches are now finished, as a list with full paths. **The user removes them.**

   | Worktree | Branch | Finished when |
   |---|---|---|
   | `workspace\new-vania-proto-v3-patch` | `feat/proto-v3-patch` | its pull request is merged, and the git-ignored folders are copied out (see `OPENCODE-START.md`) |
   | `workspace\new-vania-pogr-skill` | `feat/pogr-skill` | its pull request is merged |

   **Before the user removes the patch worktree:** it holds files that are not in git (`assets/hero/`,
   `assets/references/`, `build/`, maybe `tools/models/`). Removing the worktree deletes them. Copy them out first.

## If something fails

Two failures in a row on the same step: stop and ask the user. Put the recommended option first.
