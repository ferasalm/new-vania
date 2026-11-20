# Pipeline journal

After each task, at most three lines: what worked, what failed, what to change next time. Rules: `ROUTING-PLAYBOOK.md` section 1.6.

- T0 (2026-11-20): worked: probing every route before real work found the Sol hang cheaply. Failed: the first Sol and image probes ran without `--ignore-user-config` and wasted 2 of 4 Codex calls. Change: always `timeout` + `--ignore-user-config` for Codex; one Sol call per batch of work.
