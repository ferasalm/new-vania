# PROTOTYPE - NOT FOR PRODUCTION
# The weapon layers, Order of Ecclesia style: the slash arcs cut out of the
# pristine attack frames (the same is_arc test bake_pandora.py uses to strip
# them off the bodies), laid on transparent 128x64 frames at the exact body
# positions so they overlay the swings 1:1.
#   weapon-dirge  = the arcs in cyan: the short sword, one blade in both hands
#   weapon-elegy  = the same arcs in violet, scaled 1.2x about the hand end
#                   (the arc's leftmost pixel) for the heavier two-handed read
#   j             = the J swing: attack frames in pack order
#   i             = the I swing: the attack2 order [0,3,2,1,4], no flip
#   low           = the crouching swing: the arcs under the thigh surgery
#                   so they sit on the crouchatk bodies
# Frame 0 of every strip gets the materialize flash at the hand, frame 4 the
# dissolve dots where the blade's tip last was. Idempotent: it reads only
# tools/pristine/ and rewrites assets/weapon-dirge|weapon-elegy plus its own
# frames.json halves, so run it any time after bake_pandora.py.
# Pipeline order: bake_pandora.py -> bake_weapons.py -> aseprite_correct.py
# Usage: python bake_weapons.py
import json
import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PRISTINE = os.path.join(HERE, "pristine")
ASSETS = os.path.join(HERE, "..", "assets")
MANIFEST = os.path.join(ASSETS, "frames.json")

RAMP = {
    "weapon-dirge": {"#2B92C9": "#1B96B8", "#FFFFFF": "#4FE3F5"},  # deep cyan edge, hot core
    "weapon-elegy": {"#2B92C9": "#6E46C2", "#FFFFFF": "#C9A0FF"},   # deep violet edge, violet core
}
BRIGHT = {"weapon-dirge": "#4FE3F5", "weapon-elegy": "#C9A0FF"}   # flash / dot colour
WHITE = "#FFFFFF"
SCALE = 1.2                     # Elegy's heavier read
ORDERS = {"j": [0, 1, 2, 3, 4], "i": [0, 3, 2, 1, 4], "low": [0, 1, 2, 3, 4]}
FLASH_ANCHOR = (60, 42)         # where attack_01's arc roots: the swinging hand
FLASH_ANCHOR_LOW = (60, 53)    # the same hand after the thigh surgery (+11 y)
FLASH = [(0, 0, WHITE), (1, 0, WHITE), (-1, 0, "b"), (0, -1, "b"), (0, 1, "b"), (1, -1, "b")]
DOTS = 3                        # the tip pixels that survive onto frame 4
CUT_TOP, CUT_ROWS = 43, 11      # the approved crouch surgery from build_stage1b.py


def hex2rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def is_arc(px, x):
    # straight from build_stage1b.py: the pack slash is blue with a white core
    r, g, b, a = px
    if a == 0:
        return False
    blue = b > r + 40 and b > 120
    white = r > 215 and g > 215 and b > 215 and x > 78
    return blue or white


def extract_arc(img):
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    p, s = out.load(), img.load()
    for y in range(img.height):
        for x in range(img.width):
            if is_arc(s[x, y], x):
                p[x, y] = s[x, y]
    return out


def crouch(img):
    # the approved thigh surgery, applied to the arc layer so the low blades sit
    # on the crouchatk bodies (rows 43..53 of the source are dropped, the rest
    # rides down with the body)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img.crop((0, 0, img.width, CUT_TOP)), (0, CUT_ROWS))
    low = CUT_TOP + CUT_ROWS
    out.paste(img.crop((0, low, img.width, img.height)), (0, low))
    return out


def recolour(img, table):
    lut = {hex2rgb(k): hex2rgb(v) for k, v in table.items()}
    out = img.copy()
    p = out.load()
    stray = set()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = p[x, y]
            if a == 0:
                continue
            c = (r, g, b)
            if c in lut:
                p[x, y] = lut[c] + (a,)
            else:
                stray.add("#%02X%02X%02X" % c)
    if stray:
        raise SystemExit("unexpected arc colours: %s" % sorted(stray))
    return out


def leftmost(img):
    # the hand end of the blade: the arc's leftmost opaque pixel
    p = img.load()
    xs = [(x, y) for y in range(img.height) for x in range(img.width) if p[x, y][3] > 0]
    if not xs:
        return None
    x0 = min(x for x, _ in xs)
    return x0, round(sum(y for x, y in xs if x == x0) / sum(1 for x, _ in xs if x == x0))


def scale_about(img, pivot, factor):
    # nearest-neighbour pull about the pivot: every pixel of the scaled blade
    # looks back into the source, so the upscale has no holes; anything past
    # the frame edge is simply clamped away
    px, py = pivot
    src = img.load()
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    dst = out.load()
    for y in range(img.height):
        for x in range(img.width):
            sx = int(round(px + (x - px) / factor))
            sy = int(round(py + (y - py) / factor))
            if src[sx, sy][3] > 0:
                dst[x, y] = src[sx, sy]
    return out


def decorate_flash(img, anchor, bright):
    # the materialize read: a small flash of weapon colour plus white at the
    # hand, on the empty wind-up frame, where the blade appears next frame
    p = img.load()
    ax, ay = anchor
    for dx, dy, c in FLASH:
        x, y = ax + dx, ay + dy
        if 0 <= x < img.width and 0 <= y < img.height and p[x, y][3] == 0:
            p[x, y] = hex2rgb(bright if c == "b" else c) + (255,)


def decorate_dots(img, blade, bright):
    # the dematerialize read: the last few tip pixels of the previous frame's
    # blade linger on the empty follow-through frame
    p = img.load()
    tips = sorted(((x, y) for y in range(blade.height) for x in range(blade.width)
                   if blade.load()[x, y][3] > 0), key=lambda xy: (xy[0], -xy[1]))
    for x, y in tips[-DOTS:]:
        if p[x, y][3] == 0:
            p[x, y] = hex2rgb(bright) + (255,)


def points(img):
    return {(x, y) for y in range(img.height) for x in range(img.width)
            if img.load()[x, y][3] > 0}


def bbox(img):
    pts = points(img)
    if not pts:
        return None
    return (min(x for x, _ in pts), min(y for _, y in pts),
            max(x for x, _ in pts) + 1, max(y for _, y in pts) + 1)


def main():
    attacks = [Image.open(os.path.join(PRISTINE, "attack_%02d.png" % i)).convert("RGBA")
               for i in range(5)]
    arcs = [extract_arc(a) for a in attacks]
    low_arcs = [crouch(a) for a in arcs]
    warnings = []

    with open(MANIFEST) as fh:
        manifest = json.load(fh)

    for set_name in ("weapon-dirge", "weapon-elegy"):
        out_dir = os.path.join(ASSETS, set_name)
        os.makedirs(out_dir, exist_ok=True)
        print("=== %s ===" % set_name)
        for strip in ("j", "i", "low"):
            blade3 = None
            for idx, src in enumerate(ORDERS[strip]):
                img = (low_arcs if strip == "low" else arcs)[src].copy()
                if set_name == "weapon-elegy":
                    piv = leftmost(img)
                    if piv:
                        img = scale_about(img, piv, SCALE)
                img = recolour(img, RAMP[set_name])
                if idx == 0:
                    decorate_flash(img, FLASH_ANCHOR_LOW if strip == "low" else FLASH_ANCHOR,
                                   BRIGHT[set_name])
                if idx == 4:
                    decorate_dots(img, blade3, BRIGHT[set_name])
                if idx == 3:
                    blade3 = img
                img.save(os.path.join(out_dir, "%s_%02d.png" % (strip, idx)))
        # verification: per frame counts, bboxes, the overlay proof
        for strip in ("j", "i", "low"):
            for idx in range(5):
                path = os.path.join(out_dir, "%s_%02d.png" % (strip, idx))
                img = Image.open(path).convert("RGBA")
                n = len(points(img))
                box = bbox(img)
                if n == 0:
                    warnings.append("%s/%s_%02d is empty" % (set_name, strip, idx))
                root = leftmost(img)
                tag = ""
                if idx in (0, 4):
                    tag = " (flash)" if idx == 0 else " (dissolve dots)"
                print("%s_%02d %4d px  bbox %-22s root %s%s" % (strip, idx, n, box, root, tag))
        manifest[set_name] = {"anims": {"j": 5, "i": 5, "low": 5}, "size": [128, 64]}

    with open(MANIFEST, "w", newline="\n") as fh:
        json.dump(manifest, fh, indent=1)

    # the overlay proof: the dirge blades sit on the exact pixels that were cut
    # out of the corresponding body frames, so the layers line up by construction
    print("\n=== overlay proof (dirge, unscaled) ===")
    for strip in ("j", "i", "low"):
        for idx in range(5):
            src = ORDERS[strip][idx]
            want = points((low_arcs if strip == "low" else arcs)[src])
            img = Image.open(os.path.join(ASSETS, "weapon-dirge", "%s_%02d.png" % (strip, idx))).convert("RGBA")
            got = points(img)
            ok = want <= got  # frames 0 and 4 carry the flash / dot pixels too
            if not ok:
                warnings.append("dirge %s_%02d lost blade pixels" % (strip, idx))
            print("dirge %s_%02d: blade pixels %d of %d present: %s"
                  % (strip, idx, len(want & got), len(want), ok))
    for strip in ("j", "i", "low"):
        for idx in range(5):
            d = bbox(Image.open(os.path.join(ASSETS, "weapon-dirge", "%s_%02d.png" % (strip, idx))).convert("RGBA"))
            e = bbox(Image.open(os.path.join(ASSETS, "weapon-elegy", "%s_%02d.png" % (strip, idx))).convert("RGBA"))
            if idx in (1, 2, 3) and (e[2] - e[0] <= d[2] - d[0] or e[3] - e[1] <= d[3] - d[1]):
                # pixel counts can drop where the bigger blade is clamped off the
                # frame edge, but the footprint must still be the larger swing
                warnings.append("elegy %s_%02d did not scale up (%s vs %s)" % (strip, idx, e, d))
    palette = set()
    for set_name in ("weapon-dirge", "weapon-elegy"):
        pooled = set()
        for strip in ("j", "i", "low"):
            for idx in range(5):
                img = Image.open(os.path.join(ASSETS, set_name, "%s_%02d.png" % (strip, idx))).convert("RGBA")
                pooled |= {"#%02X%02X%02X" % px[:3] for px in img.getdata() if px[3] > 0}
        print("%s palette: %s" % (set_name, sorted(pooled)))
        palette |= pooled
    stray = palette - {c for table in RAMP.values() for c in table.values()} - {WHITE}
    if stray:
        warnings.append("weapon palettes carry stray colours: %s" % sorted(stray))
    print("\n=== warnings ===")
    for w in warnings or ["none"]:
        print("WARN:", w)


if __name__ == "__main__":
    main()
