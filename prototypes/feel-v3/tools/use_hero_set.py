# Chooses which heroine frame set the game uses.
#
#   python tools/use_hero_set.py hero_v2      (run from prototypes/feel-v3)
#
# It reads assets/<set>/frames_hero.json, checks that every frame file is there,
# writes the "hero" entry of assets/frames.json (with "dir": <set>), and keeps the
# other heroine folders out of the Android build (export_presets.cfg).
# The old folder assets/hero/ holds frames traced from another game: it is
# git-ignored, must not be opened, and is always kept out of the build once
# another set is chosen.
import json
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)
ASSETS = os.path.join(GAME, "assets")
HERO_DIRS = ["hero", "hero_v2", "hero_3d"]
NEEDED = {"idle": 6, "run": 16, "jump": 4, "land": 1, "crouch": 5, "attack": 5, "attack2": 5,
          "crouchatk": 5, "crouchatk2": 5, "airatk": 5, "airatk2": 5, "backdash": 4, "hurt": 2,
          "cast": 5, "dead": 4}


def main():
    name = sys.argv[1]
    folder = os.path.join(ASSETS, name)
    entry = json.load(open(os.path.join(folder, "frames_hero.json")))
    problems = []
    for anim, count in NEEDED.items():
        if int(entry["anims"].get(anim, 0)) < count:
            problems.append("animation %s has %s frames, the game needs %d" % (anim, entry["anims"].get(anim), count))
    union = None
    for anim, count in entry["anims"].items():
        for i in range(int(count)):
            path = os.path.join(folder, "%s_%02d.png" % (anim, i))
            if not os.path.exists(path):
                problems.append("missing " + path)
                continue
            img = Image.open(path).convert("RGBA")
            if list(img.size) != list(entry["size"]):
                problems.append("%s is %s, expected %s" % (path, img.size, entry["size"]))
            if anim == "idle":
                box = img.getbbox()
                if box:
                    union = box if union is None else (min(union[0], box[0]), min(union[1], box[1]),
                                                        max(union[2], box[2]), max(union[3], box[3]))
    if problems:
        print("NOT SWITCHED:")
        for p in problems:
            print("  " + p)
        sys.exit(1)
    entry["dir"] = name
    entry.setdefault("faces", "right")
    if union:
        entry["body_box"] = list(union)
    manifest_path = os.path.join(ASSETS, "frames.json")
    manifest = json.load(open(manifest_path))
    manifest["hero"] = entry
    with open(manifest_path, "w", newline="\n") as fh:
        json.dump(manifest, fh, indent=1)

    # keep the heroine folders that are not in use out of the Android build
    presets = os.path.join(GAME, "export_presets.cfg")
    lines = open(presets, encoding="utf-8").read().split("\n")
    for n, line in enumerate(lines):
        if line.startswith("exclude_filter="):
            parts = [p for p in line[len("exclude_filter="):].strip('"').split(",") if p]
            parts = [p for p in parts if p not in ["assets/%s/*" % d for d in HERO_DIRS]]
            parts += ["assets/%s/*" % d for d in HERO_DIRS if d != name]
            lines[n] = 'exclude_filter="%s"' % ",".join(parts)
    with open(presets, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines))
    print("hero set is now %s (%d animations, %d frames)" % (name, len(entry["anims"]),
                                                            sum(int(c) for c in entry["anims"].values())))


if __name__ == "__main__":
    main()
