# Start prompt for a fresh OpenCode session (feel-v3)

Written 2026-11-16 by Helper 3, during the 22:24 sprint. The sprint was still running when this
was written. **Where this file and `active.md` disagree, `active.md` wins.**

Who works next: Fable is not available again until 21 November. The next sessions run on Opus
(Claude Code) and on cheaper models (OpenCode: DeepSeek and similar).

Paste everything inside the box below into a new OpenCode session.

---

```text
You are continuing work on the feel-v3 prototype of the game "new-vania" (Godot 4.7.2, GDScript).
The user is not a game developer. Write short plain sentences and everyday words.
Status words are only: done / in progress / planned / not planned / waiting on user.

STEP 0 - READ THESE FIRST, IN THIS ORDER (read, do not change anything yet)
1. C:\Users\AUC\opencode-workspace\workspace\new-vania\production\session-state\active.md
   (the current state; it lives only in the main checkout, it is not in git)
2. C:\Users\AUC\opencode-workspace\workspace\new-vania-proto-v3-patch\production\handoff\OPENCODE-START.md
   (this file: read the parts below the box too)
3. production\handoff\BRIEFS.md      (twelve ready jobs, in order of value)
4. production\handoff\FINDINGS.md    (what the prototype has proven and what it has not; skip if missing)
5. production\playtests\VERDICTS.md  (what the user said after playing; it outranks every design document)
6. prototypes\feel-v3\README.md and prototypes\feel-v3\ANDROID.md
If a file says something different from active.md, active.md wins. Then give a one-line status.

WHERE THE WORK IS
- Worktree: C:\Users\AUC\opencode-workspace\workspace\new-vania-proto-v3-patch
- Branch:   feat/proto-v3-patch (it was cut from feat/proto-v3-android, which is pull request #102)
- Game:     prototypes\feel-v3 inside that worktree
- Never commit to the branch "Main". One worktree per job:
  npm run task:new -- <type>/<topic>   (run it from workspace\new-vania; it prints the new path)
- A new worktree does not contain the git-ignored files. See "Git-ignored files a new worktree needs"
  in OPENCODE-START.md before you run the game there.

HOW TO RUN THINGS (Git Bash, from the worktree root)
  GODOT="/c/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64_console.exe"
- Self-test (the main check):
  timeout 110 "$GODOT" --headless --path prototypes/feel-v3 res://smoke.tscn
  Pass means: the last lines show "SMOKE PASS" and every check passed (58 of 58 at the start of the
  sprint of 2026-11-16; the number may be higher now, see active.md).
- Screenshots: the same command WITHOUT --headless, and with "-- shots" at the end.
  They are saved in prototypes/feel-v3/shots/. Open them and look. Add "touch" after "shots" to show
  the phone controls.
- Wall climb test (if climb_test.tscn exists):
  timeout 110 "$GODOT" --headless --fixed-fps 60 --path prototypes/feel-v3 res://climb_test.tscn
- Phone build (APK), from prototypes/feel-v3:
  "$GODOT" --headless --path . --export-debug "Android" build/android/new-vania-feel-v3-patch.apk
- Do NOT start the game with play.cmd. It can run tools/build_pandora.py, which is on the
  never-touch list. Start it with: "$GODOT" --path prototypes/feel-v3

THE LEGAL RULE FOR THE HEROINE (no exceptions)
The frames in prototypes/feel-v3/assets/hero/ are traced from Castlevania: Order of Ecclesia.
New heroine frames must come ONLY from our own pictures (pandora-001-sprite.jpg,
pandora-001-concept.jpg, or the 3D model made from them), with poses designed from scratch.
Nobody may open, read, view or copy from:
- prototypes/feel-v3/assets/hero/*            (any file)
- the Shanoa reference sheet in assets/references/
- tools/build_pandora.py, tools/bake_pandora.py, tools/shanoa_cells.py
- tools/pristine/                             (the whole folder)
Listing file names is allowed. Opening the files is not.
Never publish the APK or any build that contains assets/hero/. See production/handoff/ASSETS-LICENCES.md.

WHAT MUST NEVER BE TOUCHED
- The files in the legal rule above.
- opencode.json, .opencode/*, .pi, .omp, Hermes settings. Never add a file named .hermes.md.
- .claude/agents and .claude/skills (they are generated; edit .agents/ and run "npm run claude:sync").
- The branch Main. Other people's worktrees and branches. The user removes worktrees and branches.
- A test, to make it pass. Fix the code, not the test.
- Never: git reset --hard, git clean, force-push, a bare git stash, --no-verify.
- Anything outside the workspace, anything that costs money, anything hard to undo: ask Yes / No first.

SHELL GOTCHAS ON THIS MACHINE
- An inline heredoc that contains an apostrophe fails. Write the script or text to a file with the
  file-write tool, then run the file.
- When a script patches a .gd file, match on ONE line at a time. Multi-line matches break.
- Stage in one command, commit in the next. Never "git add x && git commit". A commit check reads
  what is staged when the command starts.
- Commit messages follow Conventional Commits (feat:, fix:, docs:, test:, chore: ...). Put a long
  message in a file and use: git commit -F <file>
- Godot test runs that end by themselves: run them from the shell as shown above, not with the
  Godot MCP "run project" tool.
- Inside prototypes/feel-v3, these are ignored by git on purpose: *.uid, *.import, shots/, build/,
  assets/hero/, assets/references/.

HOW TO WORK
- For any job with more than one step, run /pogr (Plan, Orchestrate, Gate, Review).
  If /pogr is not in the command list yet, read ".agents/skills/pogr/SKILL.md" and follow it.
  (It is on branch feat/pogr-skill until that branch is merged.)
- For one job from BRIEFS.md: do exactly what the brief says, run its check, report the output.
- Two failures in a row on the same step: stop and ask. Do not try a third way.
- Ask the user Yes / No questions, one at a time. Ask "May I write this to <path>?" before writing.
- Commit and push each finished step on the work branch. No merge without the user saying yes.
- Never say a check passed if you did not run it. Write "not run".

FIRST ACTION
Read the files in STEP 0. Then tell the user, in one line, what is done and what is next, and ask
which brief from BRIEFS.md to start with (recommend the first one whose "needs" are met).
```

---

## Notes below the box (read these too)

### What is in this folder

| File | What it is |
|---|---|
| `OPENCODE-START.md` | This file. |
| `BRIEFS.md` | Twelve ready jobs in the POGR brief form, sized for a cheaper model. |
| `FINDINGS.md` | What feel-v3 has proven and what is still unproven. |
| `ASSETS-LICENCES.md` | Where each asset comes from and whether it may be published. |
| `AFTER-MIDNIGHT.md` | The delayed chores: pull requests, reviews, backup tag, merge, cleanup. |
| `POGR-FIELD-NOTES.md` | The lead's notes from the sprint. |
| `HELPER2-REPORT.md` | The wall climb measurements and other checks from the sprint. |

### State of tonight's sprint: check, do not guess

Three things were being built when this was written. Their end state is in `active.md`:

- a 2D cut-out heroine in `assets/hero_v2/` (tool: `tools/build_pandora_v2.py`);
- a 3D route in `assets/hero_3d/`, with models in `tools/models/`;
- a wall climb test, `climb_test.gd`, and the fix that follows from it.

### The /pogr skill

- Branch `feat/pogr-skill`, worktree `C:\Users\AUC\opencode-workspace\workspace\new-vania-pogr-skill`.
- Commits `797a7a2` and `6892482`, pushed. Not merged. No pull request yet (see `AFTER-MIDNIGHT.md`).
- Until it is merged into `Main` and the work branch is updated, `/pogr` does not show up in the
  command list of this worktree. Read the skill file from the pogr worktree instead:
  `C:\Users\AUC\opencode-workspace\workspace\new-vania-pogr-skill\.agents\skills\pogr\SKILL.md`.

### Git-ignored files a new worktree needs

> **LEAD TO COMPLETE.** This section is a template. The lead fills in what really exists after the sprint.

A new worktree gets only what is in git. These folders are not in git, and the game or its tools need them:

| Folder (under `prototypes/feel-v3/`) | Needed for | Exists after the sprint? (lead fills in) |
|---|---|---|
| `assets/hero/` | The game shows the heroine from here until the new frames are wired in. Copy the folder; do not open the files. | ______ |
| `assets/references/` | `tools/build_save_rooms.py`, `tools/build_world.py`, and our own Pandora pictures. Contains the Shanoa sheet: do not open it. | ______ |
| `tools/models/` | The 3D models for the 3D heroine route. | ______ |
| `build/` | The Android build output (the APK). Not needed to run the game; only copy it to share the APK. | ______ |
| `assets/hero_v2/`, `assets/hero_3d/` | The new heroine. Check whether they are in git or ignored. | ______ |

Copy command template (Git Bash). Set `NEW` to the new worktree path first:

```bash
OLD="/c/Users/AUC/opencode-workspace/workspace/new-vania-proto-v3-patch/prototypes/feel-v3"
NEW="/c/Users/AUC/opencode-workspace/workspace/<new-worktree>/prototypes/feel-v3"
mkdir -p "$NEW/assets" "$NEW/tools"
cp -r "$OLD/assets/hero"        "$NEW/assets/"
cp -r "$OLD/assets/references"  "$NEW/assets/"
cp -r "$OLD/tools/models"       "$NEW/tools/"     # only if it exists
cp -r "$OLD/build"              "$NEW/"           # only if the APK is wanted there
ls "$NEW/assets/hero" | wc -l                     # lead: write the expected number here: ______
```

Also copy `active.md` if the new session should read it from the worktree (it is not in git):

```bash
cp "/c/Users/AUC/opencode-workspace/workspace/new-vania/production/session-state/active.md" \
   "/c/Users/AUC/opencode-workspace/workspace/<new-worktree>/production/session-state/active.md"
```

Check after copying: run the self-test in the new worktree. It must end with `SMOKE PASS`.

### Not checked when this was written

- The start prompt was not tried in a real OpenCode session.
- The APK command was not run by Helper 3. The self-test was not run by Helper 3 either; the numbers come from `active.md`.
