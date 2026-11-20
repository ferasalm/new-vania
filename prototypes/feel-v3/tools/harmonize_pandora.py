# PROTOTYPE - NOT FOR PRODUCTION
"""Harmonize every in-game Pandora frame to skin A (user rule, 2026-11-19: within one skin, every frame shares one
design and one palette), then bake skin B. Run from prototypes/feel-v3:

  python -I tools/harmonize_pandora.py [src_dir] [out_dir]      default art_proof/harmony/original -> art_proof/harmony
  python -I tools/harmonize_pandora.py redrawn <a_dir> <out_dir> re-tone redrawn frames (PixelLab) to the same mix
  python -I tools/harmonize_pandora.py install                   copy A to assets/2x/pandora, B to assets/2x/pandora_b

art_proof/harmony/original holds her hand-made frames as they were before the recolour (moved there 2026-11-19).

The old frames use one 15-colour set (the same colours as sprite-sheet-pandora-5). Each colour has a role outside
the hair, inside the hair and inside skin (palette_proof.MAP, approved on the palette proof). The tool decides
hair / skin / suit for the ambiguous colours from the colours around each pixel (a 7 x 7 window), adds the eye glow
on the face, and writes palette-A frames plus baked B frames, then a contact sheet of every move.
"""
import json
import sys
from collections import Counter
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pandora_skins import read_gpl, PAL_A, bake_image, swap_map, off_palette  # noqa: E402

H = lambda s: tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))  # noqa: E731
OUTLINE = {H("121215"), H("40231e")}
SUIT = {H("151d1a"): 8, H("2b454f"): 9, H("314e3f"): 9}
HAIR_CUE = {H("9a9f87"), H("ede6cb")}                    # colours that sit mostly in her hair
SKIN_CUE = {H("e8b26f"), H("b6834c"), H("704d2b")}       # colours that sit mostly on her skin
SUIT_CUE = set(SUIT)
GLOW_EYE = H("75dfd5")
# ambiguous colour -> (role in suit context, role in hair context, role in skin context); roles are 1-based
AMBIG = {
    H("3a708e"): (9, 5, 9),
    H("4f5d42"): (9, 5, 9),
    H("699fad"): (11, 6, 10),     # suit seams glow cyan (user, 2026-11-19)
    H("9a9f87"): (9, 6, 6),
    H("f5d893"): (4, 7, 4),
    H("ede6cb"): (7, 7, 4),
    H("e8b26f"): (3, 6, 3),
    H("b6834c"): (2, 5, 2),
}
K = 3                                                      # half window: 7 x 7


def _window_counts(px, w, h):
    """Per pixel, counts of hair / skin / suit cue colours in the 7 x 7 window (summed-area tables)."""
    tabs = {}
    for name, cue in (("hair", HAIR_CUE), ("skin", SKIN_CUE), ("suit", SUIT_CUE)):
        acc = [[0] * (w + 1) for _ in range(h + 1)]
        for y in range(h):
            row = 0
            for x in range(w):
                p = px[x, y]
                row += 1 if (p[3] >= 128 and p[:3] in cue) else 0
                acc[y + 1][x + 1] = acc[y][x + 1] + row
        tabs[name] = acc

    def count(name, x, y):
        a = tabs[name]
        x0, y0, x1, y1 = max(0, x - K), max(0, y - K), min(w, x + K + 1), min(h, y + K + 1)
        return a[y1][x1] - a[y0][x1] - a[y1][x0] + a[y0][x0]
    return count


def roles_of(img):
    w, h = img.size
    px = img.load()
    count = _window_counts(px, w, h)
    out = [[0] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            c = (r, g, b)
            if a < 128:
                continue
            if c in OUTLINE:
                out[y][x] = 1
            elif c in SUIT:
                out[y][x] = SUIT[c]
            elif c == GLOW_EYE:                                # a bright glint: glow on the suit, light in the hair
                out[y][x] = 12 if count("suit", x, y) >= count("hair", x, y) else 7
            elif c in AMBIG:
                hs, ss, us = count("hair", x, y), count("skin", x, y), count("suit", x, y)
                suit_r, hair_r, skin_r = AMBIG[c]
                if c in (H("e8b26f"), H("b6834c")):           # tan: skin unless hair clearly surrounds it
                    out[y][x] = hair_r if hs > 2 * ss + 2 else skin_r
                elif c in (H("f5d893"), H("ede6cb")):         # cream: hair unless skin dominates
                    out[y][x] = skin_r if ss > hs else hair_r
                elif c == H("699fad"):                         # seam teal glows only deep in the suit, never near hair
                    out[y][x] = hair_r if hs >= 1 else (suit_r if us >= max(ss, 6) else skin_r)
                else:                                          # steel blue, olive, seam teal, grey
                    out[y][x] = hair_r if hs >= max(3, us // 2) else (suit_r if us >= ss else skin_r)
            else:
                out[y][x] = 1                                   # unknown: outline, reported by the check
    return out


def add_eye(roles):
    """Eye glow: the outline pixel inside the face (skin on both sides) that is highest and most forward."""
    h, w = len(roles), len(roles[0])
    ys = [y for y in range(h) if any(roles[y])]
    if not ys:
        return roles
    top = ys[0]
    skin = (2, 3, 4)
    best = None
    for y in range(top, min(h, top + 24)):
        for x in range(1, w - 1):
            if roles[y][x] != 1:
                continue
            n = [roles[y][x - 1], roles[y][x + 1], roles[y - 1][x] if y else 0, roles[y + 1][x] if y + 1 < h else 0]
            if sum(v in skin for v in n) >= 2 and 0 not in n:
                key = (y, -x)
                if best is None or key < best[0]:
                    best = (key, x, y)
    if best and not any(12 in row for row in roles):
        _k, x, y = best
        roles[y][x] = 12
        if roles[y][x - 1] == 1:
            roles[y][x - 1] = 11
    return roles


def paint(roles, pal):
    h, w = len(roles), len(roles[0])
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    p = im.load()
    for y in range(h):
        for x in range(w):
            if roles[y][x]:
                p[x, y] = pal[roles[y][x] - 1] + (255,)
    return im


def sheet(dir_a, dir_b, out_png, extra=None):
    """Every move, one row each: A frames, then B frames below them."""
    moves = {}
    for f in sorted(Path(dir_a).glob("*.png")):
        moves.setdefault(f.stem.rsplit("_", 1)[0], []).append(f.name)
    if extra:
        moves.update(extra)
    box = (52, 50, 172, 156)
    cw, ch = 120, 106
    cols = max(len(v) for v in moves.values())
    img = Image.new("RGB", (90 + cols * cw, len(moves) * (2 * ch + 8)), (30, 30, 36))
    d = ImageDraw.Draw(img)
    for r, (mv, names) in enumerate(moves.items()):
        y = r * (2 * ch + 8)
        d.text((4, y + ch - 6), mv, fill=(255, 255, 0))
        for i, n in enumerate(names):
            for k, base in enumerate((dir_a, dir_b)):
                src = Path(base) / n if not isinstance(n, tuple) else Path(n[k])
                f = Image.open(src).convert("RGBA").crop(box)
                img.paste(f, (90 + i * cw, y + k * ch), f)
    img.save(out_png)
    return out_png


# --- harmonize redrawn frames (PixelLab jump) with the hand-made set ------------------------------------------
# Tone mix of the 115 hand-made frames in skin A (measured 2026-11-19): share of shade / base / light per region.
TONE_MIX = {(2, 3, 4): (0.23, 0.36, 0.41), (5, 6, 7): (0.25, 0.46, 0.29)}


def _roles_from_a(img, pal):
    idx = {c: i + 1 for i, c in enumerate(pal)}
    w, h = img.size
    px = img.load()
    return [[idx.get(px[x, y][:3], 1) if px[x, y][3] >= 128 else 0 for x in range(w)] for y in range(h)]


def retone(roles, region, mix):
    """Re-split one region's tones to the hand-made mix. Order: the frame's own tone first, then the side the light
    comes from (top and front: she faces right), so PixelLab's shading is kept and only re-balanced."""
    h, w = len(roles), len(roles[0])
    inside = lambda x, y: 0 <= x < w and 0 <= y < h and roles[y][x] in region  # noqa: E731
    pts = []
    for y in range(h):
        for x in range(w):
            if roles[y][x] in region:
                lit = sum(not inside(x + dx, y + dy) for dx, dy in ((0, -1), (0, -2), (1, 0), (2, 0)))
                dark = sum(not inside(x + dx, y + dy) for dx, dy in ((0, 1), (0, 2), (-1, 0), (-2, 0)))
                pts.append((region.index(roles[y][x]) + 0.35 * (lit - dark), x, y))
    pts.sort()
    n = len(pts)
    cut1, cut2 = round(n * mix[0]), round(n * (mix[0] + mix[1]))
    for i, (_s, x, y) in enumerate(pts):
        roles[y][x] = region[0] if i < cut1 else (region[1] if i < cut2 else region[2])
    return roles


def add_eye_face(roles):
    """Eye glow on a redrawn frame: the face is the skin patch touching the most hair; the eye is the most forward
    dark pixel in its upper part (she faces right), else a skin pixel there."""
    h, w = len(roles), len(roles[0])
    skin, hair = (2, 3, 4), (5, 6, 7)
    seen, best = set(), None
    for y0 in range(h):
        for x0 in range(w):
            if roles[y0][x0] not in skin or (x0, y0) in seen:
                continue
            comp, stack, touch = [], [(x0, y0)], 0
            seen.add((x0, y0))
            while stack:
                x, y = stack.pop()
                comp.append((x, y))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    a, b = x + dx, y + dy
                    if 0 <= a < w and 0 <= b < h:
                        if roles[b][a] in hair:
                            touch += 1
                        elif roles[b][a] in skin and (a, b) not in seen:
                            seen.add((a, b))
                            stack.append((a, b))
            if best is None or touch > best[0]:
                best = (touch, comp)
    if not best or best[0] == 0:
        return roles
    comp = best[1]
    ys = [p[1] for p in comp]
    top, bot = min(ys), max(ys)
    band = range(top + 1, top + max(2, (bot - top) * 6 // 10) + 1)
    cand = []
    for y in band:
        row = [p[0] for p in comp if p[1] == y]
        if not row:
            continue
        for x in range(min(row), max(row) + 2):
            if 0 <= x < w and roles[y][x] in (1, 2) and roles[y][x - 1] in skin + (1,):
                cand.append((x, -y, x, y))
    if cand:
        _a, _b, x, y = max(cand)
    else:
        y = top + (bot - top) // 3
        x = max(p[0] for p in comp if p[1] == y)
    roles[y][x] = 12
    if x > 0 and roles[y][x - 1] in (1, 2):
        roles[y][x - 1] = 11
    return roles


def eye_from_rig(roles, kp, raw_img):
    """Eye glow on a redrawn frame from the rig: the forward eye keypoint (she faces east) of the pose the frame
    was drawn from, mapped from the raw 256 px picture onto the finished frame through the two bounding boxes."""
    h, w = len(roles), len(roles[0])
    ys = [y for y in range(h) if any(roles[y])]
    xs = [x for x in range(w) if any(roles[y][x] for y in range(h))]
    rb = raw_img.getbbox()
    k = max((p for p in kp if p["label"].endswith("EYE")), key=lambda p: p["x"])
    sx = (xs[-1] - xs[0] + 1) / (rb[2] - rb[0])
    sy = (ys[-1] - ys[0] + 1) / (rb[3] - rb[1])
    ex = round(xs[0] + (k["x"] * raw_img.width - rb[0]) * sx)
    ey = round(ys[0] + (k["y"] * raw_img.height - rb[1]) * sy)
    def at(x, y):
        return roles[y][x] if 0 <= x < w and 0 <= y < h else 0

    best = None
    for y in range(ey - 4, ey + 5):            # 1st choice: the eye PixelLab drew (a glow pixel) near the point
        for x in range(ex - 4, ex + 5):
            if at(x, y) in (11, 12):
                d = abs(x - ex) + abs(y - ey)
                if best is None or d < best[0]:
                    best = (d, x, y)
    if best is None:                           # 2nd choice: a dark pixel inside the face, not on its front edge
        for y in range(ey - 3, ey + 4):
            for x in range(ex - 4, ex + 3):
                if at(x, y) in (1, 2, 8) and at(x + 1, y) and at(x + 2, y)                         and sum(at(x + a, y + b) in (2, 3, 4) for a, b in ((-1, 0), (1, 0), (0, -1), (0, 1))) >= 2:
                    d = abs(x - ex) + abs(y - ey)
                    if best is None or d < best[0]:
                        best = (d, x, y)
    _d, x, y = best if best else (0, ex, ey)
    roles[y][x] = 12
    if x + 1 < w and roles[y][x + 1]:
        roles[y][x + 1] = 11
    return roles, (x, y)


def harmonize_redrawn(src, out, rig="art_proof/jump/pass2/rig/jump_poses.json", raw="art_proof/jump/pass2/raw/seed9"):
    """Re-tone skin and hair of redrawn palette-A frames to the hand-made mix, add the eye glow, bake B."""
    pal, mapping = read_gpl(PAL_A), swap_map()
    oa, ob = Path(out) / "a", Path(out) / "b"
    oa.mkdir(parents=True, exist_ok=True)
    ob.mkdir(parents=True, exist_ok=True)
    for f in sorted(Path(src).glob("*.png")):
        roles = _roles_from_a(Image.open(f).convert("RGBA"), pal)
        roles = drop_strays(roles)
        for region, mix in TONE_MIX.items():
            roles = retone(roles, region, mix)
        n = int(f.stem.rsplit("_", 1)[1])
        poses = json.load(open(rig))["poses"] if rig else None
        if poses and n < len(poses) and (Path(raw) / f.name).exists():
            roles, at = eye_from_rig(roles, poses[n], Image.open(Path(raw) / f.name).convert("RGBA"))
            print(f.name, "eye at", at)
        else:
            roles = add_eye_face(roles)
        a = paint(roles, pal)
        a.save(oa / f.name)
        bake_image(a, mapping).save(ob / f.name)
    print("re-toned", len(list(oa.glob("*.png"))), "frames ->", out)


def drop_strays(roles, min_px=6):
    """Remove specks: opaque islands (8-connected) smaller than min_px pixels."""
    h, w = len(roles), len(roles[0])
    seen = set()
    for y0 in range(h):
        for x0 in range(w):
            if not roles[y0][x0] or (x0, y0) in seen:
                continue
            comp, stack = [], [(x0, y0)]
            seen.add((x0, y0))
            while stack:
                x, y = stack.pop()
                comp.append((x, y))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        a, b = x + dx, y + dy
                        if 0 <= a < w and 0 <= b < h and roles[b][a] and (a, b) not in seen:
                            seen.add((a, b))
                            stack.append((a, b))
            if len(comp) < min_px:
                for x, y in comp:
                    roles[y][x] = 0
    return roles


# where each redrawn jump frame goes in the game (seed 9 order -> game frame name)
# seed 9 order: 00 lean-in crouch, 01 push-off, 02 split leap, 03 knees gather, 04 top tuck, 05 fall glide, 06 land
JUMP_INSTALL = {"land_01": "jump_00", "jump_00": "jump_01", "jump_01": "jump_02", "jump_02": "jump_03",
                "jump_03": "jump_04", "jump_04": "jump_05", "land_00": "jump_06"}   # game name -> seed 9 name


def install(harmony="art_proof/harmony", game="assets/2x"):
    """Copy the harmonized set into the game: skin A to assets/2x/pandora, skin B to assets/2x/pandora_b.
    The originals were moved to art_proof/harmony/original first (they are the recolour source)."""
    import shutil
    ga, gb = Path(game) / "pandora", Path(game) / "pandora_b"
    gb.mkdir(parents=True, exist_ok=True)
    for f in ga.glob("*.png"):
        f.unlink()                     # the originals live on in art_proof/harmony/original and in git
    for f in gb.glob("*.png"):
        f.unlink()
    for k, dst in (("a", ga), ("b", gb)):
        for f in sorted((Path(harmony) / k).glob("*.png")):
            if f.stem.startswith("jump_") or f.stem.startswith("land_"):
                continue               # the old jump and landing are replaced by the redrawn ones
            shutil.copy2(f, dst / f.name)
        for game_name, seed_name in JUMP_INSTALL.items():
            shutil.copy2(Path(harmony) / "jump" / k / f"{seed_name}.png", dst / f"{game_name}.png")
    print("installed", len(list(ga.glob("*.png"))), "A frames and", len(list(gb.glob("*.png"))), "B frames")


# --- her face in the hand-made frames ------------------------------------------------------------------------
# The original art paints her face in the same creams as her hair, so colour alone turns the face silver.
# Her head is found in every frame by matching idle_00's head (colour classes, numpy), then the face mask below
# (idle_00 coordinates, read from the pixels 2026-11-19) is shifted onto it. Inside the mask: cream and tan are
# skin (the "skin box" column of palette_proof.MAP), grey and blue strands stay hair, dark pixels are features,
# and the eye gets the glow pair of the approved proof (12, with 11 one pixel forward).
FACE_REF, FACE_PATCH, FACE_EYE = "idle_00", (116, 62, 134, 82), (126, 73)
FACE_ROWS = {71: (126, 128), 72: (126, 128), 73: (126, 128), 74: (126, 128), 75: (124, 128), 76: (123, 128),
             77: (123, 127), 78: (122, 126)}
FACE_ROLE = {H("f5d893"): 4, H("ede6cb"): 4, H("e8b26f"): 3, H("b6834c"): 2, H("704d2b"): 2, H("4f5d42"): 2,
             H("9a9f87"): 6, H("3a708e"): 5, H("699fad"): 6, H("2b454f"): 5, H("314e3f"): 5, H("151d1a"): 1}


def _classes(img):
    import numpy as np
    a = np.array(img.convert("RGBA"))
    out = np.zeros(a.shape[:2], np.int8)
    groups = ((1, ("121215", "40231e", "151d1a", "2b454f", "314e3f")), (2, ("3a708e", "4f5d42", "699fad", "9a9f87")),
              (3, ("f5d893", "ede6cb", "e8b26f", "b6834c", "704d2b", "75dfd5")))
    for k, cols in groups:
        for c in map(H, cols):
            out[(a[..., 0] == c[0]) & (a[..., 1] == c[1]) & (a[..., 2] == c[2]) & (a[..., 3] >= 128)] = k
    return out


def track_heads(src):
    """Offset of her head from idle_00 in every original frame: {stem: (dx, dy, score)}."""
    import numpy as np
    from numpy.lib.stride_tricks import sliding_window_view
    x0, y0, x1, y1 = FACE_PATCH
    tpl = _classes(Image.open(Path(src) / f"{FACE_REF}.png"))[y0:y1, x0:x1]
    out = {}
    for f in sorted(Path(src).glob("*.png")):
        c = _classes(Image.open(f))
        top = int(np.nonzero(c)[0].min())
        score = (sliding_window_view(c, tpl.shape) == tpl).mean(axis=(2, 3))
        score[: max(0, top - 4)] = 0
        score[top + 40:] = 0
        y, x = np.unravel_index(np.argmax(score), score.shape)
        out[f.stem] = (int(x - x0), int(y - y0), float(score[y, x]))
    return out


def cream_skin(roles, img, min_tan=0.15):
    """Her shoulders and hands are painted in the same creams as her hair. A patch of cream and tan pixels
    (4-connected) whose tan share (her skin shading: e8b26f, b6834c, 704d2b) is at least min_tan is skin; hair
    patches are almost all cream. Measured on cast_02's hand: 10 tan of 26."""
    px = img.convert("RGBA").load()
    h, w = len(roles), len(roles[0])
    cream, tan = {H("f5d893"), H("ede6cb")}, {H("e8b26f"), H("b6834c"), H("704d2b")}
    to_skin = {H("f5d893"): 4, H("ede6cb"): 4, H("e8b26f"): 3, H("b6834c"): 2, H("704d2b"): 2}
    seen = set()
    for y0 in range(h):
        for x0 in range(w):
            if (x0, y0) in seen or px[x0, y0][3] < 128 or px[x0, y0][:3] not in to_skin:
                continue
            comp, stack = [], [(x0, y0)]
            seen.add((x0, y0))
            while stack:
                x, y = stack.pop()
                comp.append((x, y))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    a, b = x + dx, y + dy
                    if 0 <= a < w and 0 <= b < h and (a, b) not in seen and px[a, b][3] >= 128                             and px[a, b][:3] in to_skin:
                        seen.add((a, b))
                        stack.append((a, b))
            n_tan = sum(px[x, y][:3] in tan for x, y in comp)
            if n_tan >= 2 and n_tan / len(comp) >= min_tan:
                for x, y in comp:
                    roles[y][x] = to_skin[px[x, y][:3]]
    return roles


def apply_face(roles, img, dx, dy):
    px = img.convert("RGBA").load()
    h, w = len(roles), len(roles[0])
    for y, (xa, xb) in FACE_ROWS.items():
        for x in range(xa, xb + 1):
            X, Y = x + dx, y + dy
            if 0 <= X < w and 0 <= Y < h and px[X, Y][3] >= 128 and px[X, Y][:3] in FACE_ROLE:
                roles[Y][X] = FACE_ROLE[px[X, Y][:3]]
    ex, ey = FACE_EYE[0] + dx, FACE_EYE[1] + dy
    roles[ey][ex] = 12
    if roles[ey][ex + 1]:
        roles[ey][ex + 1] = 11
    return roles


def main(src="art_proof/harmony/original", out="art_proof/harmony"):
    pal, mapping = read_gpl(PAL_A), swap_map()
    oa, ob = Path(out) / "a", Path(out) / "b"
    oa.mkdir(parents=True, exist_ok=True)
    ob.mkdir(parents=True, exist_ok=True)
    bad, eyes = 0, 0
    heads = track_heads(src)
    low = sorted((round(v[2], 2), k) for k, v in heads.items())[:3]
    print("head match, lowest scores:", low)
    for f in sorted(Path(src).glob("*.png")):
        img = Image.open(f).convert("RGBA")
        dx, dy, _score = heads[f.stem]
        roles = apply_face(cream_skin(roles_of(img), img), img, dx, dy)
        eyes += any(12 in row for row in roles)
        a = paint(roles, pal)
        a.save(oa / f.name)
        bake_image(a, mapping).save(ob / f.name)
        bad += off_palette(a, pal)[0]
    print(f"{len(list(oa.glob('*.png')))} frames; off-palette pixels {bad}; frames with an eye glow {eyes}")
    jump = {"jump (new)": [(f"art_proof/jump/pass2/seed9/a/jump_{i:02d}.png", f"art_proof/jump/pass2/seed9/b/jump_{i:02d}.png")
                           for i in range(7)]}
    print("wrote", sheet(oa, ob, Path(out) / "all_moves_sheet.png", jump))


if __name__ == "__main__":
    if sys.argv[1:2] == ["install"]:          # python -I tools/harmonize_pandora.py install
        install()
    elif sys.argv[1:2] == ["redrawn"]:          # python -I tools/harmonize_pandora.py redrawn <src_a_dir> <out_dir>
        harmonize_redrawn(sys.argv[2], sys.argv[3])
    else:
        main(*sys.argv[1:3])
