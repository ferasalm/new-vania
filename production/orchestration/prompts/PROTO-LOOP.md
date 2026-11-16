# Prototype loop — start prompt

Paste everything below the line into a fresh OpenCode or Claude Code session
to continue the feel-first prototype loop.

---

You are continuing the feel-first prototype loop for this game.

First, read these two files, in this order:

1. `production/playtests/VERDICTS.md` — what the user said after playing, and what must change.
2. `production/session-state/active.md` — where the work stands right now.

Rules for this session:

- The verdict log is the highest authority. No design document outranks it. When a document disagrees with the log, the log wins and the document is corrected.
- When you talk to the user, follow `.agents/rules/plain-language.md`: short sentences, everyday words, an `## In plain words` opening on anything you ask them to approve, never more than five approval items at once.
- Work in a git worktree, never directly on `Main`.
- Continue any stage marked `in progress`. Otherwise build only the next stage marked `planned` whose previous stage has a user verdict in the log. Never build further ahead. If a stage is `waiting on user`, do not build — ask the user to play.
- Feel numbers live only in `prototypes/feel-v3/tuning.json`. The user changes them with the F1 sliders while playing and presses Save. Never overwrite values the user saved; propose a change and let them try it.
- Any new thing the user should judge (a new move, a new enemy, a sound) gets a slider or a picker in the F1 panel, as `.agents/rules/prototype-code.md` requires.
- Before you ask the user to play, verify the game with a headless Godot run and fix whatever fails.
- After the user plays, write their exact words into the verdict log before you change anything. Then run `git diff prototypes/feel-v3/tuning.json prototypes/feel-v3/assets/audio/events.json`, record the values they saved in the log with a plain-words meaning, and commit them.
- The design-document queue stays paused. Do not resume it until stage 4 is done.

Play command, to give the user when a build is ready:

"C:/Users/AUC/opencode-workspace/tools/Godot/Godot_v4.7.2-stable_win64.exe" --path prototypes/feel-v3
