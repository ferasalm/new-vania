# PROTOTYPE - NOT FOR PRODUCTION
# Question: does the game feel right when its LANDED numbers are played, not read?
# Date: 2026-11-16
#
# THE ASSET BUILDER (v2). Run ONCE at build time; the game only ever reads
# prototypes/sandbox/assets/. The source library is never referenced at runtime.
#
#   python tools/build_assets.py --src <repo>/inbox/downloads/organized/art
#
# What it does:
#   1. chroma-keys Pandora's three green-screen GIFs -> transparent frame PNGs
#   2. white-keys Arnetria's three poses out of the concept sheet (labels cropped off)
#   3. cuts her broken clock ring out of the reference render -> the arena backdrop
#   4. picks a flung glass shard out of the ATTACK pose -> the shard sprite
#   5. composes the mirror (diamond + a flipped, desaturated Pandora reflection)
#   6. authors the 3-frame cyan slash
#   7. composes the ornate boss door out of pack pieces
#   8. copies the chosen pack sprites (env / fx / mini-bosses) verbatim
#
# Every output is listed in assets/MANIFEST.txt with its source, so the provenance
# of every pixel in this prototype is a file, not a memory.
import os, sys, json, math, shutil
from collections import Counter
import numpy as np
from PIL import Image, ImageSequence, ImageFilter, ImageDraw, ImageChops

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.abspath(os.path.join(HERE, "..", "assets"))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))

CONCEPTS = os.path.join(REPO, "design", "art", "concepts", "new")
PANDORA = os.path.join(CONCEPTS, "characters", "main-character", "sprites")
ARNETRIA = os.path.join(CONCEPTS, "characters", "the-woman-villain", "boss")

SRC = None
for i, a in enumerate(sys.argv):
    if a == "--src" and i + 1 < len(sys.argv):
        SRC = sys.argv[i + 1]
if SRC is None:
    SRC = os.environ.get("ART_SRC") or os.path.join(REPO, "inbox", "downloads", "organized", "art")

MANIFEST = []


def note(out_rel, source, extra=""):
    MANIFEST.append("%-52s <- %s%s" % (out_rel, source, ("   " + extra) if extra else ""))


def ensure(p):
    os.makedirs(p, exist_ok=True)
    return p


# ── 1. the chroma key (Pandora) ──────────────────────────────────────────────
def bg_colors(rgb, strip=40):
    """The green screen is an exact 8-colour dither. Sample it from the borders."""
    a = np.array(rgb)
    edges = np.concatenate([a[:, :strip].reshape(-1, 3), a[:, -strip:].reshape(-1, 3),
                            a[:12, :].reshape(-1, 3)])
    c = Counter(map(tuple, edges))
    return [np.array(k, dtype=np.int16) for k, v in c.items() if v > 30]


def flood_key(img, bgs, tol=16, green_dom=25):
    """Key the screen by flood-filling inward from the border only.

    A pixel is background-like if it is within `tol` of one of the sampled dither
    colours, or if it is strongly green-dominant (the jump clip's screen is a
    noisy gradient). Only background CONNECTED TO THE BORDER is removed, so a
    green-adjacent pixel inside the body (a cyan circuit line) survives.
    """
    a = np.array(img.convert("RGB")).astype(np.int16)
    h, w, _ = a.shape
    bgish = np.zeros((h, w), bool)
    for c in bgs:
        bgish |= (np.abs(a - c).max(axis=2) <= tol)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    bgish |= (g > r + green_dom) & (g > b + green_dom) & (g > 90)

    seen = np.zeros((h, w), bool)
    stack = []
    for x in range(w):
        for y in (0, h - 1):
            if bgish[y, x] and not seen[y, x]:
                seen[y, x] = True; stack.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if bgish[y, x] and not seen[y, x]:
                seen[y, x] = True; stack.append((y, x))
    while stack:
        y, x = stack.pop()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and bgish[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True; stack.append((ny, nx))

    out = np.array(img.convert("RGBA"))
    out[..., 3] = np.where(seen, 0, 255)
    return Image.fromarray(out, "RGBA")


def bbox_of(im, thr=8):
    a = np.array(im)[..., 3]
    ys, xs = np.where(a > thr)
    if len(xs) == 0:
        return None
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def normalise(frames, canvas_w, canvas_h, anchor="feet"):
    """Paste every frame onto ONE canvas, feet-anchored at the bottom centre.

    Anchoring by the feet (the centroid of the lowest 10 rows) instead of the
    bbox centre keeps the boots planted while the ponytail and arms sway — the
    bbox centre drifts with the hair and makes an idle read as a slide.
    """
    out = []
    for f in frames:
        bb = bbox_of(f)
        if bb is None:
            out.append(Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0)))
            continue
        spr = f.crop(bb)
        if spr.width > canvas_w or spr.height > canvas_h:
            k = min(canvas_w / spr.width, canvas_h / spr.height)
            spr = spr.resize((max(1, int(spr.width * k)), max(1, int(spr.height * k))), Image.LANCZOS)
        ax = spr.width // 2
        if anchor == "feet":
            a = np.array(spr)[..., 3]
            rows = np.where(a.max(axis=1) > 8)[0]
            if len(rows):
                lo = max(0, rows.max() - 9)
                band = a[lo:rows.max() + 1]
                cols = np.where(band.max(axis=0) > 8)[0]
                if len(cols):
                    ax = int(round(cols.mean()))
        c = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
        c.paste(spr, (int(canvas_w / 2 - ax), canvas_h - spr.height), spr)
        out.append(c)
    return out


def components(mask):
    """4-way connected components -> list of (size, [(y,x)...])."""
    h, w = mask.shape
    lab = np.zeros((h, w), np.int32)
    cur = 0
    comps = []
    for y in range(h):
        row = mask[y]
        for x in range(w):
            if row[x] and lab[y, x] == 0:
                cur += 1
                stack = [(y, x)]; lab[y, x] = cur
                pts = []
                while stack:
                    cy, cx = stack.pop(); pts.append((cy, cx))
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and lab[ny, nx] == 0:
                            lab[ny, nx] = cur; stack.append((ny, nx))
                comps.append((len(pts), pts))
    return comps


def key_jump(img):
    """The jump clip is a different shoot: a noisy, overexposed screen with heavy
    green spill on the body, so a colour-distance key eats her. Split by HUE
    instead — she is blue/cyan, very dark, or desaturated silver; the screen is a
    saturated green — then keep the biggest blob (plus its close neighbours) so
    the silhouette stays whole."""
    a = np.array(img.convert("RGB")).astype(np.float32) / 255.0
    mx = a.max(axis=2); mn = a.min(axis=2)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    val = mx
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    d = mx - mn + 1e-6
    hue = np.zeros_like(mx)
    m = (mx == r); hue[m] = ((g - b)[m] / d[m]) % 6
    m = (mx == g); hue[m] = ((b - r)[m] / d[m]) + 2
    m = (mx == b); hue[m] = ((r - g)[m] / d[m]) + 4
    hue *= 60
    mask = ((hue > 185) & (hue < 305)) | (val < 0.22) | ((sat < 0.18) & (val > 0.45))
    comps = components(mask)
    if not comps:
        return None, 0.0
    comps.sort(key=lambda c: -c[0])
    big = comps[0]
    ys = [p[0] for p in big[1]]; xs = [p[1] for p in big[1]]
    bx0, bx1 = min(xs) - 12, max(xs) + 12
    by0, by1 = min(ys) - 12, max(ys) + 12
    keep = np.zeros_like(mask)
    for size, pts in comps:
        if size < big[0] * 0.01:
            continue
        cys = [p[0] for p in pts]; cxs = [p[1] for p in pts]
        if min(cxs) <= bx1 and max(cxs) >= bx0 and min(cys) <= by1 and max(cys) >= by0:
            for (yy, xx) in pts:
                keep[yy, xx] = True
    alpha = (keep * 255).astype(np.uint8)
    am = Image.fromarray(alpha, "L").filter(ImageFilter.GaussianBlur(0.8))
    am = ImageChops.multiply(am, Image.fromarray(alpha, "L"))
    out = np.array(img.convert("RGBA"))
    out[..., 3] = np.array(am)
    im = Image.fromarray(out, "RGBA")
    bb = bbox_of(im)
    score = 0.0
    if bb:
        bw, bh = bb[2] - bb[0], bb[3] - bb[1]
        if bh > 0 and bw > 0:
            score = bh / bw            # a standing figure is taller than wide
        if big[0] < 1500 or big[0] > 30000:
            score = 0.0
    return im, score


def build_pandora():
    d = ensure(os.path.join(OUT, "pandora"))
    CANVAS = (128, 200)
    plan = [("idle", 4, CANVAS), ("dash", 6, CANVAS)]
    summary = {}
    for name, every, (cw, ch) in plan:
        p = os.path.join(PANDORA, "pandora-001-%s.gif" % name)
        im = Image.open(p)
        raw = [fr.convert("RGB") for fr in ImageSequence.Iterator(im)]
        bgs = bg_colors(raw[0])
        keyed = [flood_key(fr, bgs) for fr in raw]
        keep = [keyed[i] for i in range(0, len(keyed), every)]
        frames = normalise(keep, cw, ch)
        for i, f in enumerate(frames):
            f.save(os.path.join(d, "%s_%02d.png" % (name, i)))
        note("pandora/%s_00..%02d.png" % (name, len(frames) - 1),
             "concepts/.../sprites/pandora-001-%s.gif" % name,
             "%d of %d frames, %dx%d" % (len(frames), len(keyed), cw, ch))
        summary[name] = {"frames": len(frames), "w": cw, "h": ch}

    # the jump: pick the three best-separated airborne poses out of the clip
    p = os.path.join(PANDORA, "pandora-001-jump.gif")
    im = Image.open(p)
    scored = []
    for idx, fr in enumerate(ImageSequence.Iterator(im)):
        keyed, sc = key_jump(fr.convert("RGB"))
        if keyed is not None and sc > 1.15:
            scored.append((sc, idx, keyed))
    scored.sort(key=lambda t: -t[0])
    picked = []
    for sc, idx, k in scored:
        if all(abs(idx - j) >= 5 for _, j, _ in picked):
            picked.append((sc, idx, k))
        if len(picked) == 3:
            break
    frames = []
    idle0 = Image.open(os.path.join(d, "idle_00.png")).convert("RGBA")
    if picked:
        air = normalise([k for _, _, k in picked], CANVAS[0], CANVAS[1])
        frames = [idle0] + air + [idle0]
    else:
        frames = [idle0]
    for i, f in enumerate(frames):
        f.save(os.path.join(d, "jump_%02d.png" % i))
    note("pandora/jump_00..%02d.png" % (len(frames) - 1),
         "pandora-001-jump.gif (hue/blob key, 3 airborne poses) + idle_00 bookends",
         "%d frames, 128x200, src frames %s" % (len(frames), [i for _, i, _ in picked]))
    summary["jump"] = {"frames": len(frames), "w": 128, "h": 200,
                       "src": [i for _, i, _ in picked], "scores": [round(s, 2) for s, _, _ in picked]}
    return summary


# ── 2. the white key (Arnetria) ──────────────────────────────────────────────
def white_key(img, thr=228, feather=1.2):
    """Flood the white page in from the border. Her silver dress survives because
    it is enclosed by dark linework — only page-connected white goes."""
    a = np.array(img.convert("RGB")).astype(np.int16)
    h, w, _ = a.shape
    bgish = a.min(axis=2) >= thr
    seen = np.zeros((h, w), bool)
    stack = []
    for x in range(w):
        for y in (0, h - 1):
            if bgish[y, x] and not seen[y, x]:
                seen[y, x] = True; stack.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if bgish[y, x] and not seen[y, x]:
                seen[y, x] = True; stack.append((y, x))
    while stack:
        y, x = stack.pop()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and bgish[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True; stack.append((ny, nx))

    alpha = np.where(seen, 0, 255).astype(np.uint8)
    am = Image.fromarray(alpha, "L").filter(ImageFilter.GaussianBlur(feather))
    am = ImageChops.multiply(am, Image.fromarray(alpha, "L"))   # never grow the body
    out = np.array(img.convert("RGBA"))
    out[..., 3] = np.array(am)
    return Image.fromarray(out, "RGBA")


def trim(im, pad=2):
    bb = bbox_of(im)
    if bb is None:
        return im
    x0, y0, x1, y1 = bb
    x0 = max(0, x0 - pad); y0 = max(0, y0 - pad)
    x1 = min(im.width, x1 + pad); y1 = min(im.height, y1 + pad)
    return im.crop((x0, y0, x1, y1))


def build_Arnetria():
    d = ensure(os.path.join(OUT, "arnetria"))
    sheet = Image.open(os.path.join(ARNETRIA, "arnetria-concept-1.jpg")).convert("RGB")
    # the three poses, labels excluded (label bands live at y 525-543 and 986-1004)
    crops = {
        "idle":   (86, 34, 467, 512),
        "cast":   (540, 34, 984, 512),
        "attack": (279, 547, 896, 972),   # includes the flung shards to the right
    }
    summary = {}
    for name, box in crops.items():
        k = trim(white_key(sheet.crop(box)), 1)
        k.save(os.path.join(d, "%s.png" % name))
        note("arnetria/%s.png" % name, "arnetria-concept-1.jpg crop %s" % (box,),
             "%dx%d" % (k.width, k.height))
        summary[name] = {"w": k.width, "h": k.height}

    # the broken clock ring: the arena backdrop, cut from the render
    render = Image.open(os.path.join(ARNETRIA, "arnetria-denial.jpg")).convert("RGB")
    ring = trim(white_key(render.crop((188, 8, 902, 586)), 230, 1.0), 0)
    ring.save(os.path.join(d, "ring.png"))
    note("arnetria/ring.png", "arnetria-denial.jpg crop (188,8,902,586)", "%dx%d" % (ring.width, ring.height))
    summary["ring"] = {"w": ring.width, "h": ring.height}
    return summary


def build_shard():
    """Pick the biggest flung shard out of the ATTACK pose — a real shard, not a
    drawn diamond."""
    d = ensure(os.path.join(OUT, "arnetria"))
    sheet = Image.open(os.path.join(ARNETRIA, "arnetria-concept-1.jpg")).convert("RGB")
    region = white_key(sheet.crop((715, 555, 900, 800)), 232, 0.8)
    a = np.array(region)[..., 3]
    # connected components, 4-way
    h, w = a.shape
    lab = np.zeros((h, w), np.int32)
    cur = 0
    best = None
    for y in range(h):
        for x in range(w):
            if a[y, x] > 40 and lab[y, x] == 0:
                cur += 1
                stack = [(y, x)]; lab[y, x] = cur
                pts = []
                while stack:
                    cy, cx = stack.pop(); pts.append((cy, cx))
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < h and 0 <= nx < w and a[ny, nx] > 40 and lab[ny, nx] == 0:
                            lab[ny, nx] = cur; stack.append((ny, nx))
                if best is None or len(pts) > best[0]:
                    best = (len(pts), pts)
    if best:
        ys = [p[0] for p in best[1]]; xs = [p[1] for p in best[1]]
        sh = trim(region.crop((min(xs), min(ys), max(xs) + 1, max(ys) + 1)), 0)
        sh.save(os.path.join(d, "shard.png"))
        note("arnetria/shard.png", "arnetria-concept-1.jpg ATTACK flung shard", "%dx%d" % (sh.width, sh.height))
        return {"w": sh.width, "h": sh.height}
    return {}


def build_mirror():
    """The mirror she spawns: an ice-blue diamond holding a flipped, desaturated
    reflection of Pandora."""
    d = ensure(os.path.join(OUT, "arnetria"))
    W, H = 72, 96
    pan = Image.open(os.path.join(OUT, "pandora", "idle_00.png")).convert("RGBA")
    # desaturate + ice tint, flip, fit inside the diamond
    g = pan.convert("L").convert("RGBA")
    tint = Image.new("RGBA", g.size, (191, 232, 242, 255))
    refl = ImageChops.multiply(g, tint)
    refl = refl.transpose(Image.FLIP_LEFT_RIGHT)
    k = min(58 / refl.width, 82 / refl.height)
    refl = refl.resize((max(1, int(refl.width * k)), max(1, int(refl.height * k))), Image.LANCZOS)
    refl.putalpha(refl.getchannel("A").point(lambda v: int(v * 0.62)))

    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    diamond = [(W // 2, 1), (W - 2, H // 2), (W // 2, H - 2), (2, H // 2)]
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).polygon(diamond, fill=255)
    fill = Image.new("RGBA", (W, H), (191, 232, 242, 96))
    canvas.paste(fill, (0, 0), mask)
    inner = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    inner.paste(refl, ((W - refl.width) // 2, (H - refl.height) // 2), refl)
    canvas.paste(inner, (0, 0), ImageChops.multiply(mask, inner.getchannel("A")))
    # the white edge, two passes: 2px then 1px
    dr = ImageDraw.Draw(canvas)
    dr.line(diamond + [diamond[0]], fill=(255, 255, 255, 235), width=2, joint="curve")
    dr.line([(W // 2, 12), (W - 14, H // 2), (W // 2, H - 12), (14, H // 2), (W // 2, 12)],
            fill=(255, 255, 255, 90), width=1)
    canvas.save(os.path.join(d, "mirror.png"))
    note("arnetria/mirror.png", "authored: diamond + flipped desaturated pandora/idle_00", "%dx%d" % (W, H))
    return {"w": W, "h": H}


def build_slash():
    d = ensure(os.path.join(OUT, "fx"))
    cyan = (79, 200, 220)
    specs = [(58, 26, 3, 210, -70, 15), (78, 32, 6, 255, -85, 45), (104, 38, 2, 110, -95, 70)]
    for i, (size, rad, width, alpha, a0, a1) in enumerate(specs):
        im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        dr = ImageDraw.Draw(im)
        box = [size / 2 - rad, size / 2 - rad, size / 2 + rad, size / 2 + rad]
        dr.arc(box, a0, a1, fill=cyan + (alpha,), width=width)
        if i == 1:
            b2 = [box[0] + 3, box[1] + 3, box[2] - 3, box[3] - 3]
            dr.arc(b2, a0 + 4, a1 - 4, fill=(255, 255, 255, 230), width=2)
        im.save(os.path.join(d, "slash_%02d.png" % i))
    note("fx/slash_00..02.png", "authored: 3-frame cyan crescent (#4FC8DC)")
    return {"frames": 3}


# ── 3. the boss door (a composite, but out of real pack pieces) ──────────────
def build_boss_door():
    d = ensure(os.path.join(OUT, "env"))
    W, H = 184, 268
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dr = ImageDraw.Draw(canvas)
    # the stone mass: a gothic arch, wide at the base, pointed at the top
    arch = [(14, H - 6), (14, 108), (26, 54), (58, 20), (W // 2, 4),
            (W - 58, 20), (W - 26, 54), (W - 14, 108), (W - 14, H - 6)]
    dr.polygon(arch, fill=(58, 56, 62, 255))
    dr.line(arch + [arch[0]], fill=(96, 92, 100, 255), width=3, joint="curve")
    # the inner recess
    inner = [(34, H - 10), (34, 116), (44, 70), (70, 38), (W // 2, 24),
             (W - 70, 38), (W - 44, 70), (W - 34, 116), (W - 34, H - 10)]
    dr.polygon(inner, fill=(18, 17, 22, 255))
    dr.line(inner + [inner[0]], fill=(120, 116, 126, 255), width=2, joint="curve")

    # the leaves: the Fort of Illusion door, doubled and scaled into the recess
    fort = find_dir("Fort of Illusion Files/Assets/Layers/Props")
    door_p = os.path.join(fort, "door.png") if fort else ""
    if door_p and os.path.exists(door_p):
        leaf = Image.open(door_p).convert("RGBA")
        leaf = leaf.resize((int(leaf.width * 1.35), int(leaf.height * 1.35)), Image.LANCZOS)
        canvas.paste(leaf, (W // 2 - leaf.width // 2, H - 8 - leaf.height), leaf)
    # the flanking church columns
    church_env = find_dir("gothicvania church files/Assets/ENVIRONMENT")
    col_p = os.path.join(church_env, "column.png") if church_env else ""
    if col_p and os.path.exists(col_p):
        col = Image.open(col_p).convert("RGBA")
        col = col.resize((34, 176), Image.LANCZOS)
        canvas.paste(col, (0, H - 8 - col.height), col)
        canvas.paste(col.transpose(Image.FLIP_LEFT_RIGHT), (W - col.width, H - 8 - col.height), col)

    # the sigil: a ring with a hairline crack — her mark, the door's tell
    cx, cy = W // 2, 62
    dr.ellipse([cx - 20, cy - 20, cx + 20, cy + 20], outline=(191, 232, 242, 235), width=3)
    dr.ellipse([cx - 12, cy - 12, cx + 12, cy + 12], outline=(191, 232, 242, 110), width=1)
    dr.line([(cx + 2, cy - 19), (cx - 3, cy - 4), (cx + 4, cy + 3), (cx - 1, cy + 19)],
            fill=(255, 255, 255, 210), width=2)
    canvas.save(os.path.join(d, "boss_door.png"))
    note("env/boss_door.png", "composite: Fort door.png + church column.png + authored arch",
         "%dx%d" % (W, H))
    return {"w": W, "h": H}


# ── 4. copy the packs ────────────────────────────────────────────────────────
def find_dir(suffix):
    """The packs nest their own folder name; resolve a directory by suffix so the
    table below never has to know how deep the archive is."""
    suffix = suffix.replace("\\", "/")
    for dirpath, dirnames, _ in os.walk(SRC):
        rel = os.path.relpath(dirpath, SRC).replace("\\", "/")
        if rel.endswith(suffix):
            return dirpath
    return None


COPIES = [
    # mini-bosses + the three tier dummies
    ("WereWolf/Sprites/Idle", "miniboss/warden_idle_%02d.png", "WereWolf idle (5)"),
    ("WereWolf/Sprites/run", "miniboss/warden_run_%02d.png", "WereWolf run (6)"),
    ("gothicvania church files/Assets/SPRITES/angel/idle/sprites", "miniboss/choir_idle_%02d.png", "church angel idle (8)"),
    ("gothicvania church files/Assets/SPRITES/angel/attack/sprites", "miniboss/choir_attack_%02d.png", "church angel attack (3)"),
    ("Super Grotto Escape Files/Assets/Characters/Enemies/Crab/Sprites/Idle", "miniboss/husk_%02d.png", "crab idle (4)"),
    ("Super Grotto Escape Files/Assets/Characters/Enemies/Crab/Sprites/Walk", "miniboss/husk_walk_%02d.png", "crab walk (6)"),
    ("Super Grotto Escape Files/Assets/Characters/Enemies/Bat/Sprites", "miniboss/spitter_%02d.png", "bat (5)"),
    # environment
    ("gothicvania church files/Assets/ENVIRONMENT", "env/church_%s.png", "church ENVIRONMENT"),
    ("Fort of Illusion Files/Assets/Layers/Props", "env/fort_%s.png", "Fort of Illusion props"),
    ("Rocky Pass Files/PNG", "env/rocky_%s.png", "Rocky Pass parallax"),
    ("Metroidvania Kit/Environment/Background parallax/Export", "env/mvkit_%s.png", "Metroidvania Kit parallax"),
    ("Metroidvania Kit/Environment/Tiles/Export", "env/mvkit_%s.png", "Metroidvania Kit tiles"),
    ("Super Grotto Escape Files/Assets/Props/Sprites", "env/grotto_%s.png", "Super Grotto props"),
    # fx
    ("explosion pack 1/Explosions pack/explosion-1-a/Sprites", "fx/burst_%02d.png", "explosion pack 1-a (8)"),
    ("explosion pack 1/Explosions pack/explosion-1-c/Sprites", "fx/shatter_%02d.png", "explosion pack 1-c (10)"),
    ("Magic Pack 9 files/sprites/spark", "fx/spark_%02d.png", "Magic Pack 9 spark (7)"),
]


def copy_packs():
    made = []
    for rel_src, tpl, label in COPIES:
        src_dir = find_dir(rel_src)
        if src_dir is None or not os.path.isdir(src_dir):
            print("  SKIP (missing):", rel_src)
            continue
        files = sorted([f for f in os.listdir(src_dir) if f.lower().endswith(".png")])
        if not files:
            continue
        out_sub = os.path.dirname(tpl)
        ensure(os.path.join(OUT, out_sub))
        n = 0
        for i, fn in enumerate(files):
            stem = os.path.splitext(fn)[0]
            if "%s" in tpl:
                out_name = tpl % stem
            else:
                out_name = tpl % (i + 1)
            dst = os.path.join(OUT, out_name)
            shutil.copyfile(os.path.join(src_dir, fn), dst)
            n += 1
        note(out_sub + "/" + os.path.basename(tpl), rel_src, "%d files (%s)" % (n, label))
        made.append((out_sub, n))
    return made


def main():
    if not os.path.isdir(SRC):
        print("SOURCE LIBRARY NOT FOUND:", SRC)
        print("pass --src <path to inbox/downloads/organized/art>")
        sys.exit(2)
    ensure(OUT)
    print("source:", SRC)
    print("output:", OUT)
    s = {}
    print("[1] pandora");   s["pandora"] = build_pandora()
    print("[2] Arnetria");  s["Arnetria"] = build_Arnetria()
    print("[3] shard");     s["shard"] = build_shard()
    print("[4] mirror");    s["mirror"] = build_mirror()
    print("[5] slash");     s["slash"] = build_slash()
    print("[6] boss door"); s["door"] = build_boss_door()
    print("[7] packs");     copy_packs()
    with open(os.path.join(OUT, "MANIFEST.txt"), "w", encoding="utf-8") as f:
        f.write("PROTOTYPE ASSET MANIFEST — built by tools/build_assets.py\n")
        f.write("source library: inbox/downloads/organized/art (license-verified, user 2026-11-16)\n")
        f.write("every pack here is itch.io/MIT-licensed; promotion to assets/ happens at the asset-spec pass.\n\n")
        f.write("\n".join(MANIFEST))
        f.write("\n\nSIZES\n" + json.dumps(s, indent=2))
    print(json.dumps(s, indent=2))
    print("MANIFEST written.")


if __name__ == "__main__":
    main()
