# PROTOTYPE - NOT FOR PRODUCTION
# Bakes Pandora-001 onto the pack heroine frames: bake, don't generate. The poses
# and the 16-bit density are approved; only the identity changes. Every body
# anim is regenerated from the pristine pack frames in tools/pristine/ (the
# idle/run/jump/attack strips straight from the pack commit), so this script is
# idempotent - run it twice, get the same pixels. It never reads the derived
# stage-1b files it replaces.
# Pipeline order: bake_pandora.py -> bake_weapons.py -> aseprite_correct.py
# (the correction pass rewrites the PNGs out of Aseprite and may drop stray
# single pixels - 12 of them across the set, all pack-art specks - so run it
# last; the chain reproduces the committed frames exactly).
# Usage: python bake_pandora.py
#   idle / run / jump   = recoloured pack frames
#   attack              = pack frames, the baked-in slash arc stripped out
#                         (the weapon layers live in bake_weapons.py now)
#   attack2             = attack frames in the order [0,3,2,1,4], no flip
#   crouch / crouchatk  = idle / attack with the approved thigh surgery
#   eattack / eattack2  = deleted (the Elegy stand-ins are now weapon layers)
# The mapping below was chosen from the cluster table this script prints: the
# gold ramp is the brightest cluster in the head zone (hair), the deep reds and
# greys dominate the torso and limbs (clothes), the bright red is the tiny
# eye/trim/scarf cluster (accents), the near-black rings everything (outline).
# Pandora keeps each role's shading steps but inverts the values: silver-white
# hair over a near-black suit, cyan eyes and seams.
import json
import os
from collections import Counter

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PRISTINE = os.path.join(HERE, "pristine")
HERO = os.path.join(HERE, "..", "assets", "hero")
MANIFEST = os.path.join(HERE, "..", "assets", "frames.json")

# --- the colour-role mapping (source hex -> Pandora hex) ----------------------
HAIR = {  # gold ramp -> silver-white ramp, 4 shading steps kept, brightest role
    "#983E1D": "#9AA6B8",
    "#BC6C17": "#AEB9C9",
    "#E1924D": "#C8D2DF",
    "#FFCC61": "#E8ECF2",
}
SUIT = {  # red dress, purple skirt, limb/foot greys, two run stragglers ->
    "#810936": "#171A22",  # near-black ramp, 5 steps kept, darkest role
    "#4E423D": "#1A1E27",
    "#3C2D32": "#171A22",
    "#4D413C": "#1A1E27",
    "#573B60": "#1D2229",
    "#8A7970": "#20252D",
    "#8A7A71": "#232833",
}
ACCENT = {"#ED053E": "#4FE3F5"}  # the eye / trim / scarf red -> glowing cyan
OUTLINE = {"#130A1B": "#07080C"}  # the rim -> near-black, kept darker than the suit
SKIN_SRC = "#FFD9B9"   # the one pack skin tone
SKIN_FACE = "#E6DCD8"  # cool pale, for the face and anything above the midline
SKIN_LOW = "#20252D"   # the same pack colour on shins and run dust joins the suit
MAP = {}
MAP.update(HAIR)
MAP.update(SUIT)
MAP.update(ACCENT)
MAP.update(OUTLINE)
ROLE = {}
for role, table in (("hair", HAIR), ("suit", SUIT), ("accent", ACCENT), ("outline", OUTLINE)):
    for src in table:
        ROLE[src] = role
ROLE[SKIN_SRC] = "skin"

PACK_COLOURS = set(MAP) | {SKIN_SRC, "#2B92C9", "#FFFFFF"}  # body + the arc pair
ANIMS = {"idle": 4, "run": 7, "jump": 4, "attack": 5}
ATTACK2_ORDER = [0, 3, 2, 1, 4]   # wind up, then the arc runs the other way
CUT_TOP, CUT_ROWS = 43, 11        # the approved crouch surgery from build_stage1b.py
BODY_BOX = [54, 23, 74, 64]        # the idle union box; a recolour must not move it
HERO_ANIMS = {"idle": 4, "run": 7, "jump": 4, "attack": 5, "attack2": 5,
              "crouch": 1, "crouchatk": 5}


def hex2rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


LUT = {hex2rgb(k): hex2rgb(v) for k, v in MAP.items()}


def load_pristine(name):
    img = Image.open(os.path.join(PRISTINE, name + ".png")).convert("RGBA")
    stray = {hex2rgb("#%02X%02X%02X" % px[:3]) for px in img.getdata()
             if px[3] > 0 and hex2rgb("#%02X%02X%02X" % px[:3]) not in
             {hex2rgb(c) for c in PACK_COLOURS}}
    if stray:
        raise SystemExit("tools/pristine/%s.png is not a pack frame: %s"
                         % (name, sorted("#%02X%02X%02X" % c for c in stray)))
    return img


def save_hero(img, name):
    img.save(os.path.join(HERO, name + ".png"))


def is_arc(px, x):
    # straight from build_stage1b.py: the pack slash is blue with a white core
    r, g, b, a = px
    if a == 0:
        return False
    blue = b > r + 40 and b > 120
    white = r > 215 and g > 215 and b > 215 and x > 78
    return blue or white


def strip_arc(img):
    out = img.copy()
    p = out.load()
    n = 0
    for y in range(img.height):
        for x in range(img.width):
            if is_arc(p[x, y], x):
                p[x, y] = (0, 0, 0, 0)
                n += 1
    return out, n


def crouch(img):
    # the approved thigh surgery from build_stage1b.py: the top 43 rows move
    # down 11 px, the 11 thigh rows in between are gone, the feet stay put
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img.crop((0, 0, img.width, CUT_TOP)), (0, CUT_ROWS))
    low = CUT_TOP + CUT_ROWS
    out.paste(img.crop((0, low, img.width, img.height)), (0, low))
    return out


def recolour(img):
    # exact-colour LUT plus the one positional rule: the pack skin tone is the
    # face above the body's midline but bare shins and dust below it, and
    # Pandora's suit covers those
    out = img.copy()
    p = out.load()
    bbox = img.getchannel("A").getbbox()
    mid = (bbox[1] + bbox[3]) / 2.0
    skin = hex2rgb(SKIN_SRC)
    face, low = hex2rgb(SKIN_FACE), hex2rgb(SKIN_LOW)
    unmapped = set()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = p[x, y]
            if a == 0:
                continue
            c = (r, g, b)
            if c == skin:
                p[x, y] = (face if y < mid else low) + (a,)
            elif c in LUT:
                p[x, y] = LUT[c] + (a,)
            else:
                unmapped.add("#%02X%02X%02X" % c)
    if unmapped:
        raise SystemExit("unmapped colours: %s" % sorted(unmapped))
    return out


def opaque(img):
    return sum(1 for px in img.getdata() if px[3] > 0)


def colours(img):
    return {"#%02X%02X%02X" % px[:3] for px in img.getdata() if px[3] > 0}


def expected_after_surgery(img):
    # pixels above the cut move down, pixels below the seam stay, the 11 rows
    # in between are dropped by the surgery
    p = img.load()
    n = 0
    for y in range(img.height):
        if CUT_TOP <= y < CUT_TOP + CUT_ROWS:
            continue
        for x in range(img.width):
            if p[x, y][3] > 0:
                n += 1
    return n


def analysis():
    img = load_pristine("idle_00")
    p = img.load()
    cols = Counter()
    pos = {}
    for y in range(img.height):
        for x in range(img.width):
            if p[x, y][3] > 0:
                c = "#%02X%02X%02X" % p[x, y][:3]
                cols[c] += 1
                x0, y0, n, sx, sy = pos.get(c, (999, 999, 0, 0, 0))
                pos[c] = (min(x0, x), min(y0, y), n + 1, sx + x, sy + y)
    print("=== cluster table, pristine idle_00 (%d colours) ===" % len(cols))
    print("colour     count  meanX  meanY   L  role")
    for c, n in sorted(cols.items(), key=lambda kv: -kv[1]):
        r, g, b = hex2rgb(c)
        x0, y0, _, sx, sy = pos[c]
        print("%s %6d %6.1f %6.1f %4d  %s" % (c, n, sx / n, sy / n, (max(r, g, b) + min(r, g, b)) // 2, ROLE[c]))
    # role positions pooled across every pristine frame: what the mapping hangs on
    pooled = Counter()
    stat = {}
    for anim, count in ANIMS.items():
        for i in range(count):
            im = load_pristine("%s_%02d" % (anim, i))
            pp = im.load()
            for y in range(im.height):
                for x in range(im.width):
                    if pp[x, y][3] > 0:
                        c = "#%02X%02X%02X" % pp[x, y][:3]
                        role = ROLE.get(c, "arc")
                        pooled[role] += 1
                        cx, cy, n = stat.get(role, (0, 0, 0))
                        stat[role] = (cx + x, cy + y, n + 1)
    print("\n=== role stats pooled over all 20 pristine frames ===")
    for role, n in pooled.most_common():
        cx, cy, m = stat[role]
        print("%-8s %6d px  meanX %5.1f  meanY %5.1f" % (role, n, cx / m, cy / m))
    print("\n=== mapping (source -> Pandora) ===")
    for src in sorted(MAP) + [SKIN_SRC]:
        if src == SKIN_SRC:
            print("%s -> %s above the body midline, %s below it  (skin)" % (src, SKIN_FACE, SKIN_LOW))
        else:
            print("%s -> %s  (%s)" % (src, MAP[src], ROLE[src]))
    print("")


def main():
    analysis()
    pristine = {"%s_%02d" % (anim, i): load_pristine("%s_%02d" % (anim, i))
                for anim, count in ANIMS.items() for i in range(count)}
    warnings = []

    # recolour-only anims: alpha must come through untouched
    for anim in ("idle", "run", "jump"):
        for i in range(ANIMS[anim]):
            src = pristine["%s_%02d" % (anim, i)]
            out = recolour(src)
            if opaque(out) != opaque(src):
                warnings.append("%s_%02d: opaque count changed on a recolour" % (anim, i))
            save_hero(out, "%s_%02d" % (anim, i))

    # attack: the arc leaves the body; the bodies stay weaponless from here on
    attacks = {}
    for i in range(5):
        body, n = strip_arc(pristine["attack_%02d" % i])
        before = opaque(pristine["attack_%02d" % i])
        out = recolour(body)
        save_hero(out, "attack_%02d" % i)
        attacks[i] = out
        print("attack_%02d: opaque %4d -> %4d (arc stripped: %d px)" % (i, before, opaque(out), n))
        if before - n != opaque(out):
            warnings.append("attack_%02d: strip maths off" % i)

    # attack2: the same bodies in the chained order, no flip
    for i, src in enumerate(ATTACK2_ORDER):
        save_hero(attacks[src], "attack2_%02d" % i)
        print("attack2_%02d = attack_%02d%s" % (i, src, "" if src == i else " (reordered)"))

    # crouch and crouchatk: the approved surgery on the recoloured pipeline
    idle0 = pristine["idle_00"]
    crouch_img = recolour(crouch(idle0))
    save_hero(crouch_img, "crouch_00")
    if opaque(crouch_img) != expected_after_surgery(idle0):
        warnings.append("crouch_00: surgery count off (%d vs %d)"
                        % (opaque(crouch_img), expected_after_surgery(idle0)))
    for i in range(5):
        body, _ = strip_arc(pristine["attack_%02d" % i])
        out = recolour(crouch(body))
        save_hero(out, "crouchatk_%02d" % i)
        if opaque(out) != expected_after_surgery(body):
            warnings.append("crouchatk_%02d: surgery count off" % i)

    # the Elegy stand-ins are weapon layers now: retire the files and the anims
    removed = 0
    for i in range(5):
        for stem in ("eattack", "eattack2"):
            path = os.path.join(HERO, "%s_%02d.png" % (stem, i))
            if os.path.exists(path):
                os.remove(path)
                removed += 1
    print("retired %d eattack files" % removed)

    with open(MANIFEST) as fh:
        manifest = json.load(fh)
    manifest["hero"]["anims"] = HERO_ANIMS
    union = None
    for i in range(4):
        bbox = Image.open(os.path.join(HERO, "idle_%02d.png" % i)).getchannel("A").getbbox()
        union = bbox if union is None else (min(union[0], bbox[0]), min(union[1], bbox[1]),
                                            max(union[2], bbox[2]), max(union[3], bbox[3]))
    if list(union) != BODY_BOX:
        warnings.append("idle body box moved: %s (was %s)" % (list(union), BODY_BOX))
    manifest["hero"]["body_box"] = list(union)
    with open(MANIFEST, "w", newline="\n") as fh:
        json.dump(manifest, fh, indent=1)

    # verification: per anim, per frame, plus the whole-set colour census
    print("\n=== baked hero set ===")
    palette = set()
    for anim, count in HERO_ANIMS.items():
        pooled = set()
        for i in range(count):
            img = Image.open(os.path.join(HERO, "%s_%02d.png" % (anim, i))).convert("RGBA")
            cs = colours(img)
            pooled |= cs
            print("%-9s %2d  opaque %4d  colours %2d" % ("%s_%02d" % (anim, i), i, opaque(img), len(cs)))
        palette |= pooled
        print("%-9s pooled colours: %2d" % (anim, len(pooled)))
    print("whole hero set: %d colours" % len(palette))
    if len(palette) > 24:
        warnings.append("hero set has %d colours, over the 24 budget" % len(palette))
    leaked = palette & {c for c in MAP} | (palette & {SKIN_SRC})
    if leaked:
        warnings.append("baked palette still contains source colours: %s" % sorted(leaked))
    print("\n=== warnings ===")
    for w in warnings or ["none"]:
        print("WARN:", w)


if __name__ == "__main__":
    main()
