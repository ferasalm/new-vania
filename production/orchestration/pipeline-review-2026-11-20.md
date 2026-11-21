# Studio workflow review

The tests, real game windows, and small checkpoints are worth keeping. Use the cheapest worker that passes a short check from the intended worktree.

| Route | Decision | Evidence |
| --- | --- | --- |
| DeepSeek for a small build | Keep when the exact model works | Three logged Studio builds took about 3, 5.5, and 5.4 minutes. A later session could not select the requested model. |
| agy for a small review | Change | The Studio selection worker timed out after 12 minutes with partial edits. Give it a short read-only question and use a local fallback if it stalls. |
| Codex Sol for writing tests | Drop the old CLI setup until a write check passes | One run reportedly used about 201k tokens and 11 minutes before exposing read-only access. |
| Local Godot and Windows checks | Keep | The help gate went from 0/913 on the old build to 914/914. All seven deliberate help faults were caught. A screenshot caught the clipped Studio window. The final exported build passed the four focused checks. |
| Independent code review and CodeRabbit | Keep | The first Studio review prompted ten inline fixes and one additional check for linked output paths. A local reviewer found no reproducible issues in the S8/S9 help and launcher changes. |

Use a rendered window for screenshot tests. Use fixed simulation timing for long headless tests. The final smoke test passed all 145 checks. Boss, interaction menu, and room enemy count tests gave the same three failures on the previous Windows build, so they remain separate game work.

The logs show approximate elapsed time, reported route failures, and check results. They cannot establish total spend, tokens by task, or savings compared with another workflow. The local review covered routing, verification, and what the logs cannot prove. Automated approval declined the external cost review payload. The three-family review in the original plan was reduced to the local evidence available here.

The playbook now calls for a small route check before giving a worker a full brief, short output from long test runs, and a real game window for visual checks.
