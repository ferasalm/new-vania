# POGR field notes (sprint of 2026-11-16, start 22:24)

Lead's running notes. About 5 lines every 20 minutes.

## 22:24 to 22:30
- Plan gap: the first Blender call (`get_addon_status`) did not answer and held the lead for 2 minutes before the harness moved it to the background. A step that depends on an outside program needs a time limit and a fallback written into the plan.
- The three helpers were launched before the Blender answer arrived, against the plan's order ("models first"). Right call: nothing else depended on Blender.
- Briefs that carried exact file ownership, the clock, and the report format took about 3 minutes to write for three helpers. Reusing the user's own wording for Helper 3 saved time.

## 22:30 to 22:40
- The biggest plan error: the premium model ran out about 6 minutes in, not at +100 minutes. It stopped one helper after 3 minutes with nothing saved. Lesson: check the remaining usage before fanning out, and tell every helper to save to disk in the first minutes.
- Fallback that worked: restart the stopped helper on the next model down with the same brief plus the corrections learned so far (file naming, extra data the lead needs).
- The Blender bridge never answered, but the add-on socket did. Talking to it directly with a 40-line script took 3 minutes and unblocked Blender for the whole sprint.
- Gate that caught a real problem: one cheap test request before sending five. The key route failed (no API subscription), and no credits were lost finding that out.
- Wasted: about 8 minutes of lead time on sign-in and key problems. Paid tools need a 2-minute "is it really usable" check before the sprint starts, not inside it.
