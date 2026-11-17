# Applies Helper 2's proposed lines to player.gd and smoke.gd (for the lead to run; Helper 2
# did not run it on the real files). The lines are read from climb_test_patch.gd, the same
# data the in-memory test runs used, so what was measured is what gets written.
#
#   python production/handoff/helper2_apply.py            dry run: checks every anchor, prints the lines
#   python production/handoff/helper2_apply.py --write    writes player.gd and smoke.gd
#   python production/handoff/helper2_apply.py --write player    only player.gd   (or: smoke)
#   add --dir <folder> to work on another copy of prototypes/feel-v3
import io
import json
import os
import re
import sys

args = sys.argv[1:]
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "prototypes", "feel-v3")
if "--dir" in args:
    root = args[args.index("--dir") + 1]
write = "--write" in args
only = [a for a in args if a in ("player", "smoke")]
src_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "prototypes", "feel-v3")
patch = io.open(os.path.join(src_dir, "climb_test_patch.gd"), encoding="utf-8").read().replace("\r", "")


def edits(name):
    # const NAME := [ [anchor, mode, [lines...]], ... ]  -> python list
    body = patch[patch.index("const %s := [" % name) + len("const %s := " % name):]
    body = body[:body.index("\n]\n") + 2]
    body = re.sub(r",(\s*[\]\)])", r"\1", body)          # trailing commas
    return json.loads(body)


failed = False
for name, fname in (("PLAYER", "player.gd"), ("SMOKE", "smoke.gd")):
    if only and name.lower() not in only:
        continue
    path = os.path.join(root, fname)
    raw = io.open(path, encoding="utf-8", newline="").read()
    eol = "\r\n" if "\r\n" in raw else "\n"
    lines = raw.replace("\r", "").split("\n")
    for anchor, mode, new in edits(name):
        hits = [i for i, l in enumerate(lines) if l == anchor]
        if len(hits) != 1:
            print("FAIL  %s: anchor found %d times: %s" % (fname, len(hits), anchor.strip()))
            failed = True
            break
        at = hits[0]
        print("%s line %d  %s  %s" % (fname, at + 1, mode, anchor.strip()[:70]))
        for l in new:
            print("    + " + l.replace("\t", "    "))
        if mode == "replace":
            lines[at:at + 1] = new
        else:
            lines[at + 1:at + 1] = new
    else:
        if write:
            io.open(path, "w", encoding="utf-8", newline="").write(eol.join(lines))
            print("wrote " + path)
if failed:
    sys.exit(1)
print("done" if write else "dry run only (add --write)")
