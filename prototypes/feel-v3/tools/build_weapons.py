# PROTOTYPE - NOT FOR PRODUCTION
# Weapons stage stand-in frames, made by editing the pack heroine frames already in
# assets/hero (same trick as build_stage1b.py, which must run first). Idempotent.
# Usage: python build_weapons.py
#   eattack  = the attack strip recoloured to a violet arc (Elegy, J / right hand)
#   eattack2 = the attack strip in reverse order recoloured to a gold arc (Elegy, I / left hand)
# All of this is placeholder art; it is replaced when Pandora-001 is redrawn.
import json
import os

from PIL import Image

HERO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "hero")


def load(name):
    return Image.open(os.path.join(HERO, name + ".png")).convert("RGBA")


def save(img, name):
    img.save(os.path.join(HERO, name + ".png"))


def is_arc(px, x):
    r, g, b, a = px
    if a == 0:
        return False
    blue = b > r + 40 and b > 120
    white = r > 215 and g > 215 and b > 215 and x > 78
    return blue or white


def recolour(img, blue_to, white_to):
    # blue_to / white_to are (r, g, b); the arc pixels keep their alpha shading
    out = img.copy()
    p = out.load()
    for y in range(out.height):
        for x in range(out.width):
            px = p[x, y]
            if is_arc(px, x):
                r, g, b, a = px
                if r > 215 and g > 215:
                    p[x, y] = white_to + (a,)
                else:
                    p[x, y] = blue_to + (a,)
    return out


def main():
    violet = (170, 120, 255)     # Elegy J: a violet arc
    gold = (255, 205, 96)        # Elegy I: a gold arc
    for i in range(5):
        save(recolour(load("attack_%02d" % i), violet, gold), "eattack_%02d" % i)
    order = [4, 3, 2, 1, 0]      # the I swing runs the other way, like attack2
    for i, src in enumerate(order):
        save(recolour(load("attack_%02d" % src), gold, violet), "eattack2_%02d" % i)
    path = os.path.join(HERO, "..", "frames.json")
    with open(path) as fh:
        manifest = json.load(fh)
    manifest["hero"]["anims"].update({"eattack": 5, "eattack2": 5})
    with open(path, "w") as fh:
        json.dump(manifest, fh, indent=1)
    print("weapons stand-in frames written")


if __name__ == "__main__":
    main()
