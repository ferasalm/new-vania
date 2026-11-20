# Pipeline log (append only, one row per slice)

Started 2026-11-20. Rules and column meaning: `ROUTING-PLAYBOOK.md` section 1.6. Judged at T7 (cost, quality, speed).

| date | task | slice | route (model, effort) | why | wall min | Claude weekly change | Codex calls | first pass? | rework rounds | gate result | reviewer findings (real/total) | note |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-11-20 | T0 | setup + probes | Sonnet direct, no subagents; probes on DeepSeek, Gemini, Terra, Sol | small edits and short commands; probes before any work to find broken routes | about 25 | 87% at start (finish measured at T1 start) | 4 (Terra 1, Sol 3) | yes | 0 | probes recorded in the playbook | n/a | Sol hangs without `--ignore-user-config`; about 60k tokens per Sol call; image tool unproven |
