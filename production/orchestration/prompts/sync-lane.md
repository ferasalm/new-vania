# Sync Lane — the single shared-file writer

> **Role**: the only writer of `design/registry/entities.yaml` and
> `design/gdd/systems-index.md`. Apply queued lane sync requests serially on a
> fresh `origin/Main`. Never force-push. Never edit a GDD.

## 0. Preconditions

1. The orchestrator has set `shared_file_lock: SYNC-LANE` in
   `production/orchestration/STATE.md` and queued at least one request in
   `production/orchestration/review-queue.md` §5.
2. The worktree `../new-vania-sync-shared-files` exists on
   `chore/sync-shared-files` (or create it with
   `npm run task:new -- chore/sync-shared-files`).
3. The lane's GDD is committed and pushed; the lane report contains the exact
   entries/rows and the diff summary. If the request is ambiguous, stop and ask
   the orchestrator; do not invent an entry.

## 1. Rebase immediately before the edit

```bash
git fetch origin
git status --short          # must be clean
git rebase origin/Main      # never force-push
```

If the rebase conflicts, stop and report the conflict; do not resolve it by
discarding the lane's data.

## 2. Apply the request serially

One lane at a time, in queue order:

1. **`design/registry/entities.yaml`** — append the entries under the correct
   section (entities / items / formulas / constants), matching the existing
   indentation and field order. Required fields: `name`, `status`, `source`,
   `referenced_by`, `added`. Add `revised` when an existing value changes.
2. **`design/gdd/systems-index.md`** — update the lane's GDD-status row, the
   design-order row, and the dependency-map bullet. Keep the counts exact (TR /
   formulas / V-invariants / ACs / gate partition). Update `Last Updated`.
3. **Never** delete an entry; set `status: deprecated` instead.
4. **Never** create a duplicate entry; append the lane to `referenced_by` when
   the entry already exists.
5. **Never** edit a GDD, a review log, or a frozen contract.

## 3. Validate

Run all of these before committing:

- **YAML parse** — `node -e "..."` or a YAML parser; the file must parse.
- **Duplicate-name scan** — `grep "^  - name:" | sort | uniq -d` must be empty.
- **Source/referenced_by consistency** — every `source` path exists; every
  `referenced_by` path exists.
- **Index counts** — the lane's counts reproduce from the GDD; the gate
  partition sums to the AC total.
- **Design order** — the lane's row is in the right position; no duplicate order
  number.
- **Status** — the lane's status matches the review record (APPROVED only with
  the gate trail; In Design otherwise).
- **No accidental deletions** — `git diff --stat` shows only the intended
  additions/edits.

If any check fails, stop and report; do not commit a broken shared file.

## 4. Commit + push

```bash
git add design/registry/entities.yaml design/gdd/systems-index.md
git commit -m "docs(sync): <lane> registry + index sync"
git push origin chore/sync-shared-files
```

One commit per lane sync, or one batched commit if the queue is small and the
diff is coherent. Reference the lane ID and the GDD path in the body.

## 5. Update the manifest + STATE

1. Update the lane's `review_state` and `next_action` in
   `production/orchestration/manifest.yaml` (the orchestrator may do this; the
   sync lane records the receipt).
2. In `STATE.md`: add the sync receipt (date, lane, files, commit hash), release
   `shared_file_lock: none`, and move the request out of the queue.
3. If the sync is the last gate before merge, tell the orchestrator; the lane
   runner merges its PR after the sync lands.

## 6. PR

The sync branch is a normal PR `--base Main`; squash-merge after all checks are
green. The admin merge is pre-authorized only for the required-review case
(0 unresolved threads, all required checks green); record the bypass.

## 7. Hard rules

- Only the sync lane edits the two shared files.
- Rebase on `origin/Main` immediately before the edit; never force-push.
- Apply serially; one lane's request at a time.
- Never invent an entry or a count.
- Never edit a GDD, a review log, or a frozen contract.
- If the request conflicts with the current shared file, stop and report; the
  orchestrator resolves it with the lane owner.
