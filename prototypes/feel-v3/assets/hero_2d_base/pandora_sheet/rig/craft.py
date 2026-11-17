"""craft.py -- careful per-clip sprite sheet crafter (GLM pass).

Quality pipeline applied to EVERY frame:
  - grounded body parts move by whole-pixel translation only (user's exact art survives)
  - unavoidable tilts (hair, cape, airborne limbs) rotate at 4x supersample,
    box-downscale, alpha binarize, snap to the sprite's own 31-color palette
  - contour repair: silhouette edge pixels recolored to colors the SOURCE itself
    uses on its edge (its outline style), anything else -> pure black outline
  - hole fill (>=3 opaque neighbors) and island removal (0 opaque neighbors)
  - numeric validation per frame: palette purity, feet grounding row 75,
    pivot stability, volume stability, frame0 == user art exactly

Usage:
  python craft.py idle          # side-view idle clip
  python craft.py idle_se       # south-east 3/4 idle clip
  python craft.py <clip> --ascii  # also print ASCII preview per frame

Outputs to rig/craft/<clip>/ : frames_1x/, strip_1x.png, strip_4x.png,
anim_4x.gif, report.json
"""
import os
import sys
import json
from collections import Counter
from PIL import Image

W, H = 112, 80
RIG = os.path.dirname(os.path.abspath(__file__))
OUTROOT = os.path.join(RIG, 'craft')

# A variant = one base sprite + its segmented parts + candidate draw orders.
# Later part in an order draws IN FRONT while moving. Contested pixels keep
# the base color in every claiming part, so any full order reproduces the
# base pixel-exactly; the chosen order only decides motion layering.
VARIANTS = {
    'side': {
        'base': 'base_112x80.png',
        'parts_dir': 'parts',
        'parts': ['hair_back', 'cape', 'leg_f', 'leg_n', 'torso', 'head', 'arm_n'],
        'orders': [
            # cape is the visible surface over leg_f (74px) and torso (67px),
            # so it draws after legs+torso but stays behind head; torso over
            # legs so swinging thighs read behind the hip overhang; arm and
            # head last so their motion reads in front.
            ['hair_back', 'leg_f', 'leg_n', 'torso', 'cape', 'head', 'arm_n'],
            ['hair_back', 'cape', 'leg_f', 'leg_n', 'torso', 'head', 'arm_n'],
            ['hair_back', 'cape', 'leg_f', 'torso', 'head', 'leg_n', 'arm_n'],
        ],
    },
    'se': {  # south-east 3/4 base (user: "use the south east for idle")
        'base': 'base_se_112x80.png',
        'parts_dir': 'parts_se',
        'parts': ['hair_back', 'cape', 'body', 'lower'],
        'orders': [
            # ponytail behind everything; torso over planted legs at the hip;
            # tattered cape tails hang in front of the legs; head+arms front.
            ['hair_back', 'lower', 'cape', 'body'],
            ['hair_back', 'cape', 'lower', 'body'],
        ],
    },
}

# Active-variant state, filled by load_variant() before any clip is built.
BASE = None
PARTS_DIR = None
PART_FILES = None
PARTS = None


def load_variant(vname):
    """Load a variant's base and parts; reset palette, snap cache, orders."""
    global BASE, PARTS_DIR, PART_FILES, PARTS, ORDERS, ORDER
    global PAL, _PAL_SET, _snap_cache
    cfg = VARIANTS[vname]
    BASE = Image.open(os.path.join(RIG, cfg['base'])).convert('RGBA')
    PARTS_DIR = os.path.join(RIG, cfg['parts_dir'])
    PART_FILES = cfg['parts']
    PARTS = {n: Image.open(os.path.join(PARTS_DIR, n + '.png')).convert('RGBA')
             for n in PART_FILES}
    ORDERS = cfg['orders']
    ORDER = None
    PAL = sorted(_opaque_rgb_set(BASE))
    _PAL_SET = set(PAL)
    _snap_cache = {}
    print('variant %s: base=%s parts=%s palette=%d colors'
          % (vname, cfg['base'], PART_FILES, len(PAL)))


def prepare_parts():
    """Binarize part alpha and complete the partition so the parts tile the
    BASE exactly: every base-opaque pixel owned by exactly one part, with the
    base's own color. Then compositing in any order reproduces the user art
    pixel-exactly (f0 == base, diff 0)."""
    base_px = BASE.load()
    for name in PART_FILES:
        px = PARTS[name].load()
        for y in range(H):
            for x in range(W):
                r, g, b, a = px[x, y]
                px[x, y] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
    owners = {}
    for name in PART_FILES:
        px = PARTS[name].load()
        for y in range(H):
            for x in range(W):
                if px[x, y][3] > 0:
                    owners.setdefault((x, y), []).append(name)
    # contested pixels stay in ALL claiming parts (redundant seams):
    # when one part moves away, the other's copy is revealed -> continuous
    # surface instead of a torn seam. Layering in motion is decided by the
    # draw ORDER (later part in front), not by ownership.
    n_contested = sum(1 for v in owners.values() if len(v) > 1)
    # assign uncovered base-opaque pixels to a neighboring part (BFS <= 3)
    fixed = 0
    for y in range(H):
        for x in range(W):
            if base_px[x, y][3] > 0 and (x, y) not in owners:
                got = None
                for r in range(1, 4):
                    for dy in range(-r, r + 1):
                        for dx in range(-r, r + 1):
                            nx, ny = x + dx, y + dy
                            hit = owners.get((nx, ny))
                            if hit:
                                got = hit[0]
                                break
                        if got:
                            break
                    if got:
                        break
                if got:
                    c = base_px[x, y]
                    PARTS[got].load()[x, y] = (c[0], c[1], c[2], 255)
                    owners[(x, y)] = [got]
                    fixed += 1
    # every claimed pixel takes the base's exact color in EVERY claiming part
    for (x, y), names in owners.items():
        c = base_px[x, y]
        for n in set(names):
            PARTS[n].load()[x, y] = (c[0], c[1], c[2], 255)
    print('prepare_parts: %d contested kept redundant, %d uncovered fixed' % (n_contested, fixed))

# Active draw orders for the loaded variant; set by load_variant().
ORDERS = None
ORDER = None
BLACK = (0, 0, 0)


# ---------------------------------------------------------------- palette

def _opaque_rgb_set(img):
    return {p[:3] for p in img.getdata() if p[3] > 0}


PAL = []          # per-variant palette, filled by load_variant()
_PAL_SET = set()

_snap_cache = {}


def snap(rgb):
    key = (int(rgb[0]), int(rgb[1]), int(rgb[2]))
    hit = _snap_cache.get(key)
    if hit is not None:
        return hit
    r, g, b = key
    best = min(PAL, key=lambda p: (p[0] - r) ** 2 + (p[1] - g) ** 2 + (p[2] - b) ** 2)
    _snap_cache[key] = best
    return best


def snap_img(img):
    out = Image.new('RGBA', (W, H))
    po = out.load()
    pi = img.load()
    for y in range(H):
        for x in range(W):
            r, g, b, a = pi[x, y]
            if a >= 128:
                s = snap((r, g, b))
                po[x, y] = (s[0], s[1], s[2], 255)
    return out


# ---------------------------------------------------------------- transforms

def shift(part, dx, dy):
    if dx == 0 and dy == 0:
        return part
    c = Image.new('RGBA', (W, H))
    c.paste(part, (dx, dy))
    return c


def rot_clean(part, pivot, deg):
    """Rotate part by deg screen-degrees around pivot; crisp pixel-art safe."""
    if abs(deg) < 0.01:
        return part.copy()
    up = part.resize((W * 4, H * 4), Image.NEAREST)
    up = up.rotate(-deg, resample=Image.BILINEAR,
                   center=(pivot[0] * 4 + 2, pivot[1] * 4 + 2))
    down = up.resize((W, H), Image.BOX)
    return snap_img(down)


def composite(transformed):
    c = Image.new('RGBA', (W, H))
    for n in ORDER:
        c.alpha_composite(transformed[n])
    return c


# ---------------------------------------------------------------- repair

def edge_color_counts(img):
    px = img.load()
    counts = {}
    for y in range(H):
        for x in range(W):
            if px[x, y][3] == 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if nx < 0 or ny < 0 or nx >= W or ny >= H or px[nx, ny][3] == 0:
                    counts[px[x, y][:3]] = counts.get(px[x, y][:3], 0) + 1
                    break
    return counts


def base_seams():
    """Transparent pixels with >=3 opaque neighbors in the SOURCE art:
    intentional thin gaps (cape/hair splits). Never fill these."""
    px = BASE.load()
    seams = set()
    for y in range(H):
        for x in range(W):
            if px[x, y][3] != 0:
                continue
            n = 0
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < W and 0 <= ny < H and px[nx, ny][3] > 0:
                    n += 1
            if n >= 3:
                seams.add((x, y))
    return seams


def repair(img, edge_ok, skip_holes=frozenset()):
    px = img.load()
    stats = {'holes': 0, 'islands': 0, 'edge_fix': 0, 'filled_at': []}
    for _ in range(6):  # hole-fill to fixpoint (fills can enable earlier holes)
        filled = 0
        for y in range(H):
            for x in range(W):
                if px[x, y][3] == 0 and (x, y) not in skip_holes:
                    nb = []
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < W and 0 <= ny < H and px[nx, ny][3] > 0:
                            nb.append(px[nx, ny][:3])
                    if len(nb) >= 3:
                        col = Counter(nb).most_common(1)[0][0]
                        px[x, y] = (col[0], col[1], col[2], 255)
                        stats['holes'] += 1
                        stats['filled_at'].append([x, y, list(col)])
                        filled += 1
        if filled == 0:
            break
    for y in range(H):
        for x in range(W):
            if px[x, y][3] > 0:
                n = 0
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and px[nx, ny][3] > 0:
                        n += 1
                if n == 0:
                    px[x, y] = (0, 0, 0, 0)
                    stats['islands'] += 1
    for y in range(H):
        for x in range(W):
            if px[x, y][3] == 0:
                continue
            edge = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if nx < 0 or ny < 0 or nx >= W or ny >= H or px[nx, ny][3] == 0:
                    edge = True
                    break
            if edge and px[x, y][:3] not in edge_ok:
                px[x, y] = (BLACK[0], BLACK[1], BLACK[2], 255)
                stats['edge_fix'] += 1
    return img, stats


# ---------------------------------------------------------------- metrics

def measure(img):
    px = img.load()
    n = 0
    minx, miny, maxx, maxy = W, H, 0, 0
    bad_pal = 0
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a > 0:
                n += 1
                minx = min(minx, x)
                maxx = max(maxx, x)
                miny = min(miny, y)
                maxy = max(maxy, y)
                if (r, g, b) not in _PAL_SET:
                    bad_pal += 1
    low_x = [x for x in range(W) if px[x, maxy][3] > 0] if n else []
    cx = round(sum(low_x) / len(low_x), 1) if low_x else None
    return {'opaque': n, 'bbox': [minx, miny, maxx, maxy], 'low_row': maxy,
            'low_cx': cx, 'bad_pal': bad_pal}


def residual(img, skip_holes=frozenset()):
    px = img.load()
    holes = islands = 0
    for y in range(H):
        for x in range(W):
            a = px[x, y][3]
            n = 0
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < W and 0 <= ny < H and px[nx, ny][3] > 0:
                    n += 1
            if a == 0 and n >= 3 and (x, y) not in skip_holes:
                holes += 1
            elif a > 0 and n == 0:
                islands += 1
    return {'holes': holes, 'islands': islands}


def diff_count(a, b):
    return sum(1 for pa, pb in zip(a.getdata(), b.getdata()) if pa != pb)


# ---------------------------------------------------------------- ascii preview

def ascii_preview(img, step=2):
    px = img.load()
    lines = []
    for y in range(0, H, step):
        row = []
        for x in range(0, W, step):
            r, g, b, a = px[x, y]
            if a == 0:
                row.append(' ')
            elif r > 180 and g > 180:
                row.append('o')          # hair whites / skin highlights
            elif g > 100 and b > 100 and r < 110:
                row.append('@')          # cyan
            elif r > 140 and r > g:
                row.append('~')          # skin
            elif max(r, g, b) < 45:
                row.append('#')          # outline / near-black
            else:
                row.append('+')          # suit / mid tones
        lines.append(''.join(row))
    return '\n'.join(lines)


# ---------------------------------------------------------------- clip: idle

HAIR_PIV = (52, 6)    # ponytail attachment at head-back top
CAPE_PIV = (56, 30)  # cape hangs from the shoulders


def build_idle():
    """6-frame idle. f0 == user art exactly.
    Breath (1px upper-body rise) + pendulum hair wave (tip ~4px) + cape
    counter-sway (~3px). Amplitudes chosen so every beat is visible at 1x."""
    breathe = [0, 0, -1, -1, -1, 0]           # upper-body lift, whole px
    hair_deg = [0.0, 4.0, 8.0, 6.0, 0.0, -6.0]
    cape_deg = [0.0, -2.0, -4.0, -3.0, 0.0, 2.0]
    frames = []
    for i in range(6):
        dy = breathe[i]
        t = {
            'hair_back': rot_clean(PARTS['hair_back'], HAIR_PIV, hair_deg[i]),
            'cape': rot_clean(PARTS['cape'], CAPE_PIV, cape_deg[i]),
            'leg_f': PARTS['leg_f'],
            'leg_n': PARTS['leg_n'],
            'torso': shift(PARTS['torso'], 0, dy),
            'head': shift(PARTS['head'], 0, dy),
            'arm_n': shift(PARTS['arm_n'], 0, dy),
        }
        frames.append(composite(t))
    return frames


HAIR_PIV_SE = (48, 10)   # SE ponytail attachment at the head-back crown
CAPE_PIV_SE = (56, 30)   # SE cape hangs from the shoulders


def build_idle_se():
    """6-frame idle on the south-east 3/4 base. f0 == user art exactly.
    Same motion language as the side idle: whole-pixel breath lifts the
    merged upper body (head+torso+arms), the ponytail pendulums around its
    crown attachment, the cape tails counter-sway around the shoulders."""
    breathe = [0, 0, -1, -1, -1, 0]           # upper-body lift, whole px
    hair_deg = [0.0, 4.0, 8.0, 6.0, 0.0, -6.0]
    cape_deg = [0.0, -3.0, -6.0, -4.0, 0.0, 3.0]
    frames = []
    for i in range(6):
        t = {
            'hair_back': rot_clean(PARTS['hair_back'], HAIR_PIV_SE, hair_deg[i]),
            'lower': PARTS['lower'],
            'cape': rot_clean(PARTS['cape'], CAPE_PIV_SE, cape_deg[i]),
            'body': shift(PARTS['body'], 0, breathe[i]),
        }
        frames.append(composite(t))
    return frames


# ---------------------------------------------------------------- runner

def choose_order():
    global ORDER
    for order in ORDERS:
        c = Image.new('RGBA', (W, H))
        for n in order:
            c.alpha_composite(PARTS[n])
        if list(c.getdata()) == list(BASE.getdata()):
            ORDER = order
            return order
    best, bd = None, 1 << 30
    for order in ORDERS:
        c = Image.new('RGBA', (W, H))
        for n in order:
            c.alpha_composite(PARTS[n])
        d = diff_count(c, BASE)
        if d < bd:
            bd, best = d, order
    ORDER = best
    print('WARN: no pixel-exact order; best diff=%d %s' % (bd, best))
    return ORDER


def save_clip(name, frames, durations, grounded=True):
    out = os.path.join(OUTROOT, name)
    os.makedirs(os.path.join(out, 'frames_1x'), exist_ok=True)
    edge_ok = set(edge_color_counts(BASE)) | {BLACK}
    seams = base_seams()
    report = {'clip': name, 'frames': len(frames), 'order': ORDER,
              'base_seams': sorted(list(seams)),
              'edge_ok': sorted(list(edge_ok)), 'per_frame': []}
    for i, f in enumerate(frames):
        f, stats = repair(f, edge_ok, seams)
        res = residual(f, seams)
        m = measure(f)
        m['repair'] = stats
        m['residual'] = res
        m['vs_base'] = diff_count(f, BASE) if i == 0 else None
        ok = (m['bad_pal'] == 0 and res['holes'] == 0 and res['islands'] == 0
              and (m['low_row'] == 75 if grounded else True)
              and (m['vs_base'] == 0 if i == 0 else True))
        m['pass'] = bool(ok)
        report['per_frame'].append(m)
        f.save(os.path.join(out, 'frames_1x', 'frame_%02d.png' % i))
    # strips
    strip = Image.new('RGBA', (W * len(frames), H))
    for i, f in enumerate(frames):
        strip.paste(f, (i * W, 0))
    strip.save(os.path.join(out, 'strip_1x.png'))
    big = strip.resize((strip.width * 4, H * 4), Image.NEAREST)
    big.save(os.path.join(out, 'strip_4x.png'))
    # gif
    gf = [f.resize((W * 4, H * 4), Image.NEAREST).convert('P',
          palette=Image.ADAPTIVE, colors=32) for f in frames]
    gf[0].save(os.path.join(out, 'anim_4x.gif'), save_all=True,
               append_images=gf[1:], duration=durations, loop=0)
    n_pass = sum(1 for m in report['per_frame'] if m['pass'])
    print('%s: %d/%d frames PASS' % (name, n_pass, len(frames)))
    for i, m in enumerate(report['per_frame']):
        print('  f%d %s low_row=%s low_cx=%s opaque=%d bad_pal=%d '
              'residual=%s filled=%d vs_base=%s' % (
                  i, 'PASS' if m['pass'] else 'FAIL',
                  m['low_row'], m['low_cx'], m['opaque'], m['bad_pal'],
                  m['residual'], m['repair']['holes'], m['vs_base']))
    diffs_vs0 = [diff_count(frames[0], f) for f in frames]
    diffs_seq = [diff_count(frames[i], frames[i + 1]) for i in range(len(frames) - 1)]
    print('  readability: changed px vs f0 = %s ; consecutive = %s' % (diffs_vs0, diffs_seq))
    report['diffs_vs_f0'] = diffs_vs0
    report['diffs_consecutive'] = diffs_seq
    with open(os.path.join(out, 'report.json'), 'w') as fh:
        json.dump(report, fh, indent=1, default=list)
    return report
    return report


CLIPS = {
    # clip name -> (variant, frame builder)
    'idle': ('side', 'build_idle'),
    'idle_se': ('se', 'build_idle_se'),
}


def main():
    global ORDER
    clip = sys.argv[1] if len(sys.argv) > 1 else 'idle'
    want_ascii = '--ascii' in sys.argv
    if clip not in CLIPS:
        raise SystemExit('unknown clip: %s (have %s)' % (clip, sorted(CLIPS)))
    variant, builder = CLIPS[clip]
    load_variant(variant)
    prepare_parts()
    choose_order()
    frames = globals()[builder]()
    save_clip(clip, frames, [140] * len(frames), grounded=True)
    if want_ascii:
        for i, f in enumerate(frames):
            print('--- %s frame %d ---' % (clip, i))
            print(ascii_preview(f))


if __name__ == '__main__':
    main()
