# Prompt for GLM (opencode): set up the game workspace

Paste this whole file into opencode, started in the repo folder (/<repo>) inside the container. Work on your own until the end, or until a STOP rule applies.

## Goal
`setup/install.sh` runs to the end and prints `DONE`, with every VERIFY line `OK`. Then the smoke test passes, `setup/LOGINS.md` exists, and `setup/` is committed.

## Steps
1. Read `setup/install.sh` in full before you run anything.
2. Check the disk: `df -h /`. Under 15 GB free: STOP (see the stop rules).
3. Run: `set -o pipefail; bash setup/install.sh 2>&1 | tee setup/run1.log`. Retries use run2.log, then run3.log.
4. On failure: read the log at the first error (`grep -n -i -E "error|fail|E: " setup/runN.log | head -n 40`, then the lines just before it). Fix the cause in `setup/install.sh` with the smallest change that works. Add one entry to `setup/FIXES.md` (the error line, the cause, the change). Rerun.
5. When install.sh prints `DONE`, run the smoke test.
6. Write `setup/LOGINS.md`, make sure `setup/FIXES.md` exists (write `No fixes needed.` if there were none), then commit.

## Rules
- The container is Debian 12 (bookworm), run as root, no sudo. Use Debian 12 package names. No Ubuntu-only names, no PPAs.
- Godot stays 4.7.2. Never change `GODOT_VER`.
- Look up URLs and versions only on official sites: godotengine.org (and its GitHub releases), developer.android.com, nodejs.org, cli.github.com, claude.ai, opencode.ai, playwright.dev. Nothing else.
- Check `ANDROID_API` (35) and `BUILD_TOOLS` (35.0.0) in install.sh against the Android export page of the Godot 4.7 docs. Change them only if the docs require it, and log the change in FIXES.md.
- After install.sh passes, set Godot's Android paths: run `godot --headless --quit` once to create the editor settings file under ~/.config/godot/, then set `export/android/android_sdk_path = "/opt/android-sdk"` and `export/android/debug_keystore = "/root/.android/debug.keystore"` in it (user `androiddebugkey`, password `android`). Note it in FIXES.md.
- Do not install Blender. Do not work around a login, password, payment or licence prompt. The Android SDK licences are the only licences install.sh accepts.
- Change only files in setup/, plus the smoke project in /tmp/smoke. Do not push.

## Smoke test
Create these two files, then run the project.

`/tmp/smoke/project.godot`:

```
config_version=5

[application]

config/name="smoke"
run/main_scene="res://main.tscn"
config/features=PackedStringArray("4.7")
```

`/tmp/smoke/main.tscn`:

```
[gd_scene format=3]

[node name="Main" type="Node2D"]
```

Run: `timeout 120 godot --headless --path /tmp/smoke --quit; echo "smoke exit $?"`
It must print `smoke exit 0`. If it does not, read the output, fix the cause (in install.sh if the cause is there), and run again.

## LOGINS.md
Write `setup/LOGINS.md` with exactly this content. The owner does these logins himself; the setup cannot.

```
# Logins: you do these yourself

Open a shell in the container: docker exec -it <container> bash

1. Claude Code: run `claude`, type `/login`, follow the prompt.
2. GitHub: run `gh auth login`, choose GitHub.com and HTTPS, then log in (browser or token). Check: `gh auth status`.
3. Model keys for opencode: run `opencode auth login --standalone`, pick the NVIDIA NIM entry, paste the key. Run the same command again, pick OpenRouter, paste the key.
4. Antigravity CLI (agy): not installed by the setup. The install command is not known yet; the owner installs it and logs in. Do not guess an install command.
5. Git identity: `git config --global user.name "Your Name"` and `git config --global user.email "you@example.com"` (use your GitHub name and email).
```

## Commit
`git add setup && git commit -m "workspace setup: install script, fixes, logins"`

## STOP and report (do not work around it)
- A login, password, payment or licence prompt (other than the Android SDK licences).
- The same step fails 3 times.
- Under 15 GB free on `/`.

## Final report (15 lines max)
1. The VERIFY lines of the last run (all eleven if OK; otherwise the MISSING ones).
2. The smoke exit code.
3. Fixes, one line each, or "no fixes".
4. The five LOGINS.md items, one line each.
5. Any STOP, and why.
