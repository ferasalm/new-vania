# PROTOTYPE - NOT FOR PRODUCTION
# Copies the sprite frames the prototype uses out of the pack library (inbox/, a
# build-time source only) into prototypes/feel-v3/assets/, and writes frames.json.
# Usage: python build_assets.py <path to inbox/downloads/organized/art> <path to prototypes/sandbox/assets>
import json
import os
import shutil
import sys

from PIL import Image

ART = sys.argv[1]
V2 = sys.argv[2]
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")
GV = os.path.join(ART, "Legacy Collection", "Legacy Collection", "Assets", "Gothicvania", "Characters")

# name -> (folder with one sub-folder per animation, {our anim name: their folder name}, faces)
SETS = {
    "hero": (os.path.join(GV, "Bridge Heroine", "Heroine base", "Sprites"),
             {"idle": "idle", "run": "run", "jump": "jump", "attack": "player-attack"}, "right"),
    "hound": (os.path.join(GV, "Hell-Hound-Files", "Sprites"),
              {"idle": "Idle", "walk": "Walk", "run": "Run", "jump": "Jump"}, "left"),
    "ghost": (os.path.join(GV, "Ghost-Files", "Sprites"),
              {"idle": "Idle", "chase": "Chase", "shriek": "Shriek", "appear": "Appear", "vanish": "Vanish"}, "left"),
}
ENV = ["church_backgrounds.png", "church_tileset.png", "church_column.png", "fort_door.png",
       "fort_closed-door.png", "fort_window.png", "fort_banner.png"]
FX = ["burst", "spark", "slash"]


def natural(name):
    digits = "".join(c for c in name if c.isdigit())
    return int(digits) if digits else 0


def main():
    manifest = {}
    sources = []
    for name, (root, anims, faces) in SETS.items():
        dest = os.path.join(OUT, name)
        os.makedirs(dest, exist_ok=True)
        entry = {"faces": faces, "anims": {}}
        union = None
        for ours, theirs in anims.items():
            folder = os.path.join(root, theirs)
            files = sorted((f for f in os.listdir(folder) if f.lower().endswith(".png")), key=natural)
            for i, f in enumerate(files):
                src = os.path.join(folder, f)
                shutil.copyfile(src, os.path.join(dest, "%s_%02d.png" % (ours, i)))
                img = Image.open(src).convert("RGBA")
                entry["size"] = list(img.size)
                if ours in ("idle",):
                    box = img.getbbox()
                    if box:
                        union = box if union is None else (min(union[0], box[0]), min(union[1], box[1]),
                                                            max(union[2], box[2]), max(union[3], box[3]))
            entry["anims"][ours] = len(files)
            sources.append((name + "/" + ours, folder))
        entry["body_box"] = list(union)  # the idle pose's opaque box inside the frame
        manifest[name] = entry

    env = os.path.join(OUT, "env")
    os.makedirs(env, exist_ok=True)
    for f in ENV:
        shutil.copyfile(os.path.join(V2, "env", f), os.path.join(env, f))
    fx = os.path.join(OUT, "fx")
    os.makedirs(fx, exist_ok=True)
    counts = {}
    for f in sorted(os.listdir(os.path.join(V2, "fx"))):
        stem = f.split("_")[0]
        if stem in FX and f.endswith(".png"):
            n = counts.get(stem, 0)
            shutil.copyfile(os.path.join(V2, "fx", f), os.path.join(fx, "%s_%02d.png" % (stem, n)))
            img = Image.open(os.path.join(V2, "fx", f))
            manifest.setdefault("fx", {}).setdefault(stem, {"n": 0, "size": list(img.size)})
            counts[stem] = n + 1
            manifest["fx"][stem]["n"] = n + 1

    with open(os.path.join(OUT, "frames.json"), "w") as fh:
        json.dump(manifest, fh, indent=1)
    with open(os.path.join(OUT, "SOURCES.md"), "w") as fh:
        fh.write("# Sprite sources\n\nAll from the Ansimuz Legacy Collection (CC0, see assets/LICENSE-MANIFEST.md),\n")
        fh.write("except env/ and fx/, copied from prototypes/sandbox/assets (origins in its MANIFEST.txt).\n\n")
        for k, v in sources:
            fh.write("- `%s` <- `%s`\n" % (k, v.replace("\\", "/").split("organized/")[-1]))
    print(json.dumps(manifest))


main()
