# PROTOTYPE - NOT FOR PRODUCTION
# Stage 1b stand-in frames, made by editing the pack heroine frames already in
# assets/hero (the pack has one attack strip and no crouch). Run after build_assets.py.
# Usage: python build_stage1b.py
#   attack2  = the attack strip in a different order with a pink arc (the chained I attack)
#   crouch   = the guard pose with the thighs shortened
#   crouchatk = the attack strip with the thighs shortened (the low attack)
# All of this is placeholder art; it is replaced when Pandora-001 is redrawn.
import json
import os

from PIL import Image

HERO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "hero")
CUT_TOP, CUT_ROWS = 43, 11      # rows removed from the thighs to make her crouch


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


def recolour(img):
    out = img.copy()
    p = out.load()
    for y in range(out.height):
        for x in range(out.width):
            px = p[x, y]
            if is_arc(px, x):
                r, g, b, a = px
                if r > 215 and g > 215:
                    p[x, y] = (255, 228, 240, a)
                else:
                    p[x, y] = (min(255, b + 20), g // 2, max(r, 150), a)
    return out


def crouch(img):
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img.crop((0, 0, img.width, CUT_TOP)), (0, CUT_ROWS))
    low = CUT_TOP + CUT_ROWS
    out.paste(img.crop((0, low, img.width, img.height)), (0, low))
    return out


def main():
    order = [0, 3, 2, 1, 4]     # wind up, then the arc runs the other way
    for i, src in enumerate(order):
        save(recolour(load("attack_%02d" % src)), "attack2_%02d" % i)
    save(crouch(load("idle_00")), "crouch_00")   # idle faces forward; the wind-up frame looked backward
    for i in range(5):
        save(crouch(load("attack_%02d" % i)), "crouchatk_%02d" % i)
    # the special attack's blade wave: the arc cut out of an attack frame, in violet
    src = load("attack_02")
    arc = Image.new("RGBA", src.size, (0, 0, 0, 0))
    sp, ap = src.load(), arc.load()
    for y in range(src.height):
        for x in range(src.width):
            if is_arc(sp[x, y], x):
                r, g, b, a = sp[x, y]
                ap[x, y] = (245, 235, 255, a) if r > 215 and g > 215 else (min(255, (r + b) // 2 + 60), g // 2, b, a)
    arc.crop(arc.getbbox()).save(os.path.join(HERO, "..", "fx", "wave_00.png"))
    path = os.path.join(HERO, "..", "frames.json")
    with open(path) as fh:
        manifest = json.load(fh)
    manifest["hero"]["anims"].update({"attack2": 5, "crouch": 1, "crouchatk": 5})
    with open(path, "w") as fh:
        json.dump(manifest, fh, indent=1)
    print("stage 1b frames written")


if __name__ == "__main__":
    main()
