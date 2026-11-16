# Twelve ready jobs for feel-v3 and the first production steps

Written 2026-11-16 by Helper 3, while the sprint was still running. Ordered by value: do the top one first.
Each job is in the POGR brief form (see the `/pogr` skill). Each is sized for a cheaper model.

**Before any job:** read `production/session-state/active.md` in the main checkout. If it says a job
here is already done, skip that job. Tonight's sprint may have finished B01, B03 or B04.

**None of the changes below were run by the author.** They were written from reading the code. The check
in each brief is what proves the job.

## Rules for every brief

- Work in the worktree `C:\Users\AUC\opencode-workspace\workspace\new-vania-proto-v3-patch`
  (branch `feat/proto-v3-patch`), or in a new worktree made with `npm run task:new -- <type>/<topic>`.
- Change only the files under FILES YOU OWN.
- The legal rule: never open `prototypes/feel-v3/assets/hero/*`, the Shanoa sheet,
  `tools/build_pandora.py`, `tools/bake_pandora.py`, `tools/shanoa_cells.py` or `tools/pristine/`.
- Do not weaken, skip or delete a test.
- Write scripts and long text with the file-write tool. Inline heredocs with apostrophes fail here.
- When patching a `.gd` file, match one line at a time. Keep tabs as tabs.
- Stage in one command, commit in the next. Conventional Commit message. Push. No merge.
- Report in at most 120 words: status word, files changed, the last lines of the check output
  (copied), and "not run" for anything not run.

Set this once per shell (Git Bash, worktree root):

```bash
GODOT="/c/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64_console.exe"
```

The two standard checks:

```bash
# SMOKE: pass means the output ends with "SMOKE PASS" and no check says FAIL
timeout 110 "$GODOT" --headless --path prototypes/feel-v3 res://smoke.tscn
# CLIMB: pass means the output ends with "CLIMB PASS"
timeout 110 "$GODOT" --headless --fixed-fps 60 --path prototypes/feel-v3 res://climb_test.tscn
```

| # | Job | Needs first | Who |
|---|---|---|---|
| B01 | Wall jump is not cut short | nothing | cheaper model |
| B02 | Write down the user's verdict on the patch | the user has played | cheaper model |
| B03 | Switch the game to the new heroine frames | a finished new frame set | cheaper model |
| B04 | Give the wall cling its own picture | B03 and a wall frame | cheaper model |
| B05 | Correct the out-of-date heroine lines in SOURCES.md | nothing | cheaper model |
| B06 | Deal with the four music tracks of unknown origin | one answer from the user | cheaper model |
| B07 | Self-test: a moved touch button survives save and load | nothing | cheaper model |
| B08 | List every tuning number for the design documents | nothing | cheaper model |
| B09 | Record the two missing licence texts | the user or the web | cheaper model |
| B10 | Write the concept document from the prototype | B02 | Opus is better |
| B11 | Set up the test framework for production code | a yes from the user | cheaper model |
| B12 | Control manifest, then the first epic and stories (Input) | B11 | Opus is better |

---

## B01: Wall jump is not cut short

```text
BRIEF B01: wall jump is not cut short
GOAL: A player who only taps jump can still climb the tall lab wall.
NEEDS: Skip this brief if "grep -n _kicked prototypes/feel-v3/player.gd" prints any line.
FILES YOU OWN: prototypes/feel-v3/player.gd
READ FIRST: production/handoff/HELPER2-REPORT.md, the part "Exact lines for the lead - player.gd (option A)".
CHANGE:
1. Find the line that starts with:  var _steer_lock := 0.0
   Add this line after it:
   var _kicked := false        # rising from a wall jump: letting go of jump does not cut it short
2. Find the line (4 tabs deep):  _steer_lock = T.v("wall_jump_lock")
   Add this line after it, with the same 4 tabs:  _kicked = true
3. Find the line that starts (1 tab deep) with:  _coyote = T.v("coyote_time") if on_floor else
   Add these two lines after it:
   (1 tab)  if on_floor:
   (2 tabs) _kicked = false
4. Replace the line
   if Input.is_action_just_released("jump") and velocity.y < 0.0:
   with
   if Input.is_action_just_released("jump") and velocity.y < 0.0 and not _kicked:
CONSTRAINTS: Change nothing else. Do not edit rooms/lab.txt or tuning.json.
CHECK: run CLIMB, then SMOKE -> PASS means: "CLIMB PASS" and "SMOKE PASS".
IF IT FAILS TWICE: undo your four edits (git restore prototypes/feel-v3/player.gd), report the
exact error, stop.
REPORT: as in "Rules for every brief".
```

## B02: Write down the user's verdict on the patch

```text
BRIEF B02: record the playtest verdict
GOAL: What the user said about the patch is saved in the verdict file, in their words.
NEEDS: The user has played the patch (desktop or phone). If not, status is "waiting on user". Stop.
FILES YOU OWN: production/playtests/VERDICTS.md (add one new section at the end; change nothing above it)
READ FIRST: the last section of VERDICTS.md (for the format); active.md, "What the patch does" (8 points).
CHANGE:
1. Ask the user about the 8 points, one at a time, as a choice: "Good, keep it" / "Change it" / "Did not try".
   For "Change it", ask what to change and copy their words.
2. Add a section at the end: "## Feel v3 patch - played <date> - verdict: <approved / changes wanted>".
   One table row per point: what was built, what the user said, what changes, status word.
3. If the user saved numbers with the F1 panel, run "git diff --stat prototypes/feel-v3/tuning.json
   prototypes/feel-v3/assets/audio/events.json" and list the changed values in a second table.
CONSTRAINTS: Never invent or tidy away what the user said. Use the status words only.
CHECK: grep -c "Feel v3 patch - played" production/playtests/VERDICTS.md -> PASS means: prints 1.
IF IT FAILS TWICE: stop and report.
REPORT: as in the rules, plus the number of points marked "Change it".
```

## B03: Switch the game to the new heroine frames

```text
BRIEF B03: use the new heroine frames
GOAL: The game shows the new, legally clean heroine and no longer reads assets/hero/.
NEEDS: active.md names a finished new frame folder (assets/hero_v2 or assets/hero_3d). Call it NEWSET.
  The folder must hold files named <anim>_00.png, <anim>_01.png ... for every animation listed under
  "hero" -> "anims" in assets/frames.json. Check with:  ls prototypes/feel-v3/assets/NEWSET
  If an animation is missing: stop. Status "waiting on art". Report which ones are missing.
FILES YOU OWN: prototypes/feel-v3/player.gd, prototypes/feel-v3/assets/frames.json
READ FIRST: prototypes/feel-v3/player.gd lines 85-95 and 636-640; assets/frames.json (the "hero" entry).
CHANGE:
1. frames.json: add a new entry "NEWSET" beside "hero". Copy the "hero" entry. Set each number under
   "anims" to the number of files that animation really has in the NEWSET folder. Set "size" to the
   width and height of one frame, and "feet" to the point between her feet in that frame
   (the build tool's output or active.md gives these numbers; do not guess: ask if missing).
   Leave the "hero" entry as it is.
2. player.gd: after the last line that starts with "const ", add:   const HERO := "NEWSET"
3. player.gd: in the line that contains  G.sprite("hero",  replace  "hero"  with  HERO
4. player.gd: in the two lines that contain  G.frames["hero"]  replace  "hero"  with  HERO
CONSTRAINTS: Do not open any file in assets/hero/. Do not delete assets/hero/. Do not edit smoke.gd.
CHECK: run SMOKE -> PASS means "SMOKE PASS". Then run the screenshots:
  "$GODOT" --path prototypes/feel-v3 res://smoke.tscn -- shots
  Open 3 pictures from prototypes/feel-v3/shots/ and look: she is visible, stands on the floor,
  faces the way she moves.
IF IT FAILS TWICE: set HERO back to "hero", report the exact error and which picture looked wrong, stop.
REPORT: as in the rules, plus the three picture names you looked at and what you saw.
```

## B04: Give the wall cling its own picture

```text
BRIEF B04: wall cling picture
GOAL: When she clings to a wall she shows a wall pose, not a jump frame.
NEEDS: B03 is done, and NEWSET holds wall_00.png (more frames are fine). If there is no wall frame:
  stop, status "waiting on art".
FILES YOU OWN: prototypes/feel-v3/assets/frames.json
READ FIRST: prototypes/feel-v3/player.gd lines 594-598 (it already plays "wall" when the animation exists).
CHANGE:
1. In frames.json, in the NEWSET entry under "anims", add:  "wall": <number of wall_NN.png files>
CONSTRAINTS: No code change. Do not draw or edit pictures.
CHECK: run SMOKE -> "SMOKE PASS". Then run the screenshots (see B03) and open shots/14_wall_latch.png:
  she is on the wall in the wall pose.
IF IT FAILS TWICE: remove the "wall" entry again, report, stop.
REPORT: as in the rules, plus what 14_wall_latch.png shows.
```

## B05: Correct the out-of-date heroine lines in SOURCES.md

```text
BRIEF B05: fix SOURCES.md
GOAL: The asset source note tells the truth about the heroine.
FILES YOU OWN: prototypes/feel-v3/assets/SOURCES.md
READ FIRST: production/handoff/ASSETS-LICENCES.md (the rows for hero/ and fx/wave_00.png).
CHANGE:
1. Remove the four lines that start with "- `hero/idle`", "- `hero/run`", "- `hero/jump`", "- `hero/attack`".
2. Remove the last line (it starts with "- `hero/attack2`").
3. Change the first paragraph so it does not say that everything is CC0. Add this paragraph under it:
   "`hero/` is NOT from a free pack. Its frames are traced from Castlevania: Order of Ecclesia. The
   folder is git-ignored, must never be published, and is being replaced. Full table:
   `production/handoff/ASSETS-LICENCES.md`."
4. Add one line: "- `fx/wave` <- made by `tools/build_stage1b.py` from the earlier CC0 heroine; re-check before publishing".
CONSTRAINTS: Docs only. Do not open assets/hero/ or the tools on the never-touch list.
CHECK: grep -c "hero/idle" prototypes/feel-v3/assets/SOURCES.md  -> PASS means: prints 0.
       grep -c "Order of Ecclesia" prototypes/feel-v3/assets/SOURCES.md -> PASS means: prints 1 or more.
IF IT FAILS TWICE: stop and report.
REPORT: as in the rules.
```

## B06: Deal with the four music tracks of unknown origin

```text
BRIEF B06: music of unknown origin
GOAL: No area plays a music track whose licence we cannot show.
NEEDS: Ask the user ONE question first: "Do you know where these four tracks came from and their
  licence? battle_encounter.ogg, battle_encounter_2.ogg, boss_battle.ogg, save_room.ogg"  (Yes / No)
FILES YOU OWN: prototypes/feel-v3/assets/audio/SOURCES.md, prototypes/feel-v3/assets/audio/events.json
READ FIRST: assets/audio/SOURCES.md, the "## Music" table; events.json, the five entries "music_church",
  "music_library", "music_lab", "music_save", "music_boss".
CHANGE if the answer is YES:
1. Add four rows to the "## Music" table in SOURCES.md with the source and licence the user gives.
   Change nothing else. Done.
CHANGE if the answer is NO:
1. In events.json, for each of the five music entries: if "file" is one of the four tracks, set "file" to
   one of these instead (each area a different one): music/cavern_loop.ogg, music/magic_cliffs.ogg,
   music/cyberpunk_city_2.ogg, music/room.ogg, music/boss.ogg.
   Use music/boss.ogg for "music_boss". Only use a file that is already in that entry's "options" list.
2. In each of the five entries, remove the four tracks from the "options" list.
3. Add a line under the "## Music" table in SOURCES.md: "Removed from the game on <date>: four tracks
   of unknown origin (files kept on disk until the user decides)."
CONSTRAINTS: Do not delete or move any sound file. Keep the JSON valid. Keep volume numbers as they are.
CHECK: node -e "JSON.parse(require('fs').readFileSync('prototypes/feel-v3/assets/audio/events.json','utf8'));console.log('json ok')"
       then run SMOKE -> PASS means: "json ok" and "SMOKE PASS" (the self-test checks that the five
       areas each have their own music).
IF IT FAILS TWICE: git restore the two files, report the exact error, stop.
REPORT: as in the rules, plus which track each area now plays.
```

## B07: Self-test: a moved touch button survives save and load

```text
BRIEF B07: test the control editor's save
GOAL: The self-test proves that a touch button the player moved is still moved after saving and loading.
FILES YOU OWN: prototypes/feel-v3/smoke.gd
READ FIRST: prototypes/feel-v3/touch.gd, the functions _load_layout and _save_layout.
CHANGE:
1. Find the line in smoke.gd that starts (1 tab deep) with:  _check("resume lets the music go on",
2. Add these lines after it. Every line starts with 1 tab; the lines under "if" and "else" start with 2 tabs:
	# touch layout: a moved button survives save and load
	var lay := "user://touch_layout.json"
	var had_file := FileAccess.file_exists(lay)
	var old_text := FileAccess.get_file_as_string(lay) if had_file else ""
	var want: Vector2 = main.touch.BTN[0]["pos"] + Vector2(-10, -6)
	main.touch.BTN[0]["pos"] = want
	main.touch._save_layout()
	main.touch._load_layout()
	var got: Vector2 = main.touch.BTN[0]["pos"]
	_check("a moved touch button survives save and load", got.distance_to(want) < 0.5, "pos=%s want=%s" % [str(got), str(want)])
	if had_file:
		var fw := FileAccess.open(lay, FileAccess.WRITE)
		fw.store_string(old_text)
		fw.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(lay))
	main.touch._load_layout()
CONSTRAINTS: Do not change touch.gd. Do not change any other check.
CHECK: run SMOKE -> PASS means: "SMOKE PASS", a line with "a moved touch button survives save and load"
  marked as passed, and one more check in the total than before.
IF IT FAILS TWICE: remove your added lines, report the exact error text, stop. (The author did not run
  this code. A parse error here is possible; report it rather than guessing.)
REPORT: as in the rules, plus the total before and after.
```

## B08: List every tuning number for the design documents

```text
BRIEF B08: tuning numbers table
GOAL: One table shows every number the user tuned, in plain words, ready to go into the design documents.
FILES YOU OWN: production/handoff/TUNING-FOR-GDD.md (new file)
READ FIRST: prototypes/feel-v3/tuning.json (each entry has "value", "label", "help").
CHANGE:
1. Write a small script file (scratch folder) that reads tuning.json and prints one table row per entry:
   key | label | value | help.
2. Write TUNING-FOR-GDD.md: a short intro (3 lines), then the table. Add a last column "Design document":
   write design/gdd/movement.md for run, jump, gravity, backdash, crouch, wall_ entries;
   design/gdd/combat.md for attack, weapon, special, elegy, energy, mp entries;
   design/gdd/enemy-ai-telegraphs.md for enemy entries; design/gdd/grief-boss-framework.md for boss
   entries; "unsure" for the rest.
3. Do NOT edit any file under design/. This job only prepares the table.
CONSTRAINTS: Copy values exactly. Do not round.
CHECK: node -e "const t=require('./prototypes/feel-v3/tuning.json');console.log(Object.keys(t).length)"
       grep -c "^| " production/handoff/TUNING-FOR-GDD.md
       -> PASS means: the second number is the first number plus 1 (the header row).
       Write the divider row as |---|---|---|---|---| with no spaces, so it is not counted.
IF IT FAILS TWICE: stop and report both numbers.
REPORT: as in the rules, plus how many rows say "unsure".
```

## B09: Record the two missing licence texts

```text
BRIEF B09: missing licence texts
GOAL: The licence manifest shows the real licence of the Library pack and the WereWolf pack.
NEEDS: Ask the user: "May I look up the two pack pages on itch.io?" (Yes / No). If No: ask the user to
  paste the licence text. If neither is possible: status "waiting on user". Stop.
FILES YOU OWN: assets/LICENSE-MANIFEST.md (repository root; only the two rows named below)
READ FIRST: in assets/LICENSE-MANIFEST.md, the rows "Metroidvania Library Asset Pack (art)" and
  "WereWolf (art)". Also look for a licence file in inbox/downloads/organized/docs/ (list names first).
CHANGE:
1. For each of the two rows: replace the "Unrecorded in repo" text with the licence as it reads, the
   date checked, and where it was read (file path or web address).
2. If a licence does not allow use in a published game: say so in the row and tell the user at once.
CONSTRAINTS: Quote the licence; do not guess it. Do not change other rows.
CHECK: grep -c "license text pending" assets/LICENSE-MANIFEST.md -> PASS means: 2 fewer than before.
IF IT FAILS TWICE: stop and report.
REPORT: as in the rules, plus one line per pack: publish allowed, yes or no.
```

## B10: Write the concept document from the prototype (Opus is better)

```text
BRIEF B10: concept document from the prototype
GOAL: What the prototype taught us is written down in the house template, in plain words.
NEEDS: B02 (the verdict) is done. Without a verdict, write only the "what was built" parts and say so.
FILES YOU OWN: prototypes/feel-v3/CONCEPT-FROM-PROTOTYPE.md (new file)
READ FIRST: docs/framework/templates/concept-doc-from-prototype.md; production/handoff/FINDINGS.md;
  production/playtests/VERDICTS.md.
CHANGE:
1. Run /reverse-document for prototypes/feel-v3 with that template, or fill the template by hand.
2. Every claim that something "feels good" must point to a line in VERDICTS.md. If there is none,
   write "not yet judged by the user".
CONSTRAINTS: Do not edit files under design/. Do not open the never-touch files.
CHECK: grep -c "^## " prototypes/feel-v3/CONCEPT-FROM-PROTOTYPE.md -> PASS means: the same number of
  "## " headings as the template has.
IF IT FAILS TWICE: stop and report.
REPORT: as in the rules, plus the list of points marked "not yet judged by the user".
```

## B11: Set up the test framework for production code

```text
BRIEF B11: test framework
GOAL: Production code has a place for tests and one command that runs them.
NEEDS: A yes from the user to start production set-up. Ask: "Start the production test set-up now?"
FILES YOU OWN: whatever /test-setup proposes under tests/ (show the list to the user first, one Yes / No)
READ FIRST: docs/framework/technical-preferences.md (the testing part: the framework is GUT);
  .agents/skills/test-setup/SKILL.md.
CHANGE:
1. Work in a NEW worktree: npm run task:new -- chore/test-setup   (from workspace\new-vania)
2. Run /test-setup and follow it. Accept its defaults for Godot 4.7.2 and GUT.
3. Do not touch prototypes/. Do not touch tests/agents, tests/claude, tests/git-hooks, tests/workflow,
   tests/modules, tests/extensions, tests/omp, tests/e2e, tests/save-twin (they test the framework).
CONSTRAINTS: If /test-setup wants to download an add-on: that is outside the workspace. Ask first.
CHECK: npm run ci -> PASS means: "Result: 5/5 steps passed."  Plus the test command that /test-setup
  prints, run once, with its output copied.
IF IT FAILS TWICE: stop, report the exact error. Leave the worktree as it is.
REPORT: as in the rules, plus the one command that runs the game tests.
```

## B12: Control manifest, then the first epic and stories for Input (Opus is better)

```text
BRIEF B12: first production stories
GOAL: The Input system has an epic and ready-to-build stories, made from the approved design and ADR.
NEEDS: B11 is done. The four ADRs in docs/architecture/ say "Accepted" (they did on 2026-11-16).
FILES YOU OWN: what the three skills write: the control manifest under docs/architecture/, the epic
  and story files under production/ (show each path to the user before writing).
READ FIRST: docs/architecture/adr-0001-input-architecture.md (Status and Decision parts only);
  design/gdd/systems-index.md (the SYS-01 row only); design/gdd/input-control-mapping.md (the
  acceptance criteria part only). Use search first; these files are long.
CHANGE:
1. New worktree: npm run task:new -- docs/input-epic
2. Run /create-control-manifest. Check that it covers ADR-0001 to ADR-0004.
3. Run /create-epics and create ONLY the Input epic (SYS-01, ADR-0001).
4. Run /create-stories for that epic. Then run /story-readiness on the first story.
5. Do NOT start Health and Damage stories: ADR-0004 says the first one waits for ADR-0005
   (not written yet) and for engine checks. Writing ADR-0005 is a job for Opus with the user.
CONSTRAINTS: Do not change any GDD or ADR. If a skill asks a design question, pass it to the user.
CHECK: npm run ci -> "Result: 5/5 steps passed."  And /story-readiness on the first story
  -> PASS means: the verdict is READY. NEEDS WORK or BLOCKED is not a pass: report the listed gaps.
IF IT FAILS TWICE: stop. Report the gaps. Do not edit the story to hide a gap.
REPORT: as in the rules, plus the story file names and the readiness verdict.
```

---

## Not in these briefs, on purpose

These need judgement or the user, so they are not for a cheaper model working alone:

- Drawing or posing the heroine. The legal rule makes this easy to get wrong.
- Feel tuning. The user tunes with the F1 panel; a model must not change feel numbers by itself.
- Writing ADR-0005 (how the systems are started and ticked). It blocks the Health and Damage stories.
- Deciding to merge anything. See `AFTER-MIDNIGHT.md`.
