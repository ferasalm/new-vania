# PROTOTYPE - NOT FOR PRODUCTION
"""Turn frames of the user's AI jump GIFs (135 x 240, green screen, 3-3-2 colours) into palette-A
frames on the 224 x 160 canvas (feet at 112, 152), about 90 px tall, then bake skin B.

Steps per frame: key out the green; give every pixel a role (outline, skin, hair, suit, glow) from its
colour; shrink by majority vote per role (no colour mixing); add the 1 px dark outline; drop lone pixels.
This is the FIRST PASS (pose pick). The rig and PixelLab passes clean it further (sprites.md 6).

  python -I tools/gif_to_palette.py assets/sprites-pandora/jump art_proof/jump/pass1   (from prototypes/feel-v3)
"""
import sys
from collections import Counter
from pathlib import Path
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pandora_skins import read_gpl, PAL_A, bake_image, swap_map  # noqa: E402

# (gif, frame, scale relative to j1, beat). Scales: head match against j1:13 (tools note in the report).
PICKS = [
    ("j1", 7, 1.05, "crouch"),
    ("j1", 10, 1.075, "push-off"),
    ("j3", 17, 0.825, "rise"),
    ("j1", 19, 1.0, "rise, slower"),
    ("j3", 29, 0.85, "top"),
    ("j1", 43, 1.025, "fall"),
    ("j1", 64, 1.15, "land"),
]
STAND_PX = 238.0      # her standing height in j1 frame 0, hair included
TARGET_PX = 90.0      # sprites.md 5b
FEET = (112, 152)
CANVAS = (224, 160)


def is_bg(r, g, b):
    return g > 120 and r < 110 and b < 130 and g > r + 50


def role_of(r, g, b):
    """Role index 1-16 of palette A for one GIF colour (0 = see-through)."""
    if is_bg(r, g, b):
        return 0
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    if r <= 108 and ((b == 255 and g >= 144) or (b >= 170 and g >= 216)):   # suit seams: glow
        return 12 if g >= 252 else 11
    if r >= 180 and r - g >= 36 and b >= 170:                # skin
        return 4 if g >= 216 else 3
    if r >= 144 and r - g >= 36:                             # warm shadow on skin
        return 2
    if r >= 144 and abs(r - g) <= 36:                        # hair
        return 7 if r >= 216 else (6 if r >= 180 else 5)
    if lum < 22:
        return 1
    if lum < 45:
        return 8
    if lum < 70:
        return 9
    return 10


def _pale_hair(r, g, b):
    return r >= 180 and abs(r - g) <= 36 and not is_bg(r, g, b)


def roles_of(frame):
    """Roles per pixel. Blue-grey and dark pixels with pale hair all around them are hair shadow."""
    w, h = frame.size
    px = frame.load()
    pale = [[_pale_hair(*px[x, y]) for x in range(w)] for y in range(h)]
    # running sum for a fast 7 x 7 count of pale-hair pixels
    acc = [[0] * (w + 1) for _ in range(h + 1)]
    for y in range(h):
        row = 0
        for x in range(w):
            row += pale[y][x]
            acc[y + 1][x + 1] = acc[y][x + 1] + row
    def near(x, y, k=3):
        x0, y0, x1, y1 = max(0, x - k), max(0, y - k), min(w, x + k + 1), min(h, y + k + 1)
        return acc[y1][x1] - acc[y0][x1] - acc[y1][x0] + acc[y0][x0]
    out = []
    for y in range(h):
        line = []
        for x in range(w):
            r = role_of(*px[x, y])
            if r in (8, 9, 10) and near(x, y) >= 14:
                r = 5 if r != 10 else 6
            line.append(r)
        out.append(line)
    return out


def shrink(roles, factor):
    """Majority vote per output pixel; see-through wins only when it is the majority."""
    h, w = len(roles), len(roles[0])
    ow, oh = max(1, round(w * factor)), max(1, round(h * factor))
    out = [[0] * ow for _ in range(oh)]
    for oy in range(oh):
        y0, y1 = int(oy / factor), max(int(oy / factor) + 1, int((oy + 1) / factor))
        for ox in range(ow):
            x0, x1 = int(ox / factor), max(int(ox / factor) + 1, int((ox + 1) / factor))
            c = Counter(roles[y][x] for y in range(y0, min(y1, h)) for x in range(x0, min(x1, w)))
            body = sum(n for r, n in c.items() if r)
            if body * 2 < sum(c.values()):
                continue
            del c[0]
            # glow and skin survive small shares so thin seams and the face stay readable
            for keep in (12, 11, 4):
                if c.get(keep, 0) * (7 if keep != 4 else 4) >= body:
                    out[oy][ox] = keep
                    break
            else:
                out[oy][ox] = c.most_common(1)[0][0]
    return out


def clean(r):
    """1 px outline around the body, and lone pixels take their neighbours' role."""
    h, w = len(r), len(r[0])
    get = lambda x, y: r[y][x] if 0 <= x < w and 0 <= y < h else 0
    out = [row[:] for row in r]
    for y in range(h):
        for x in range(w):
            if not r[y][x]:
                continue
            n4 = [get(x + 1, y), get(x - 1, y), get(x, y + 1), get(x, y - 1)]
            if 0 in n4:
                out[y][x] = 1
                continue
            if r[y][x] not in (11, 12) and all(v != r[y][x] for v in n4):
                out[y][x] = Counter(n4).most_common(1)[0][0]
    return out


def to_canvas(roles, pal):
    h, w = len(roles), len(roles[0])
    fig = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            if roles[y][x]:
                fig.putpixel((x, y), pal[roles[y][x] - 1] + (255,))
    bb = fig.getbbox()
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    if bb:
        fig = fig.crop(bb)
        canvas.paste(fig, (FEET[0] - fig.width // 2, FEET[1] - fig.height))
    return canvas


def main(gif_dir, out_dir):
    out = Path(out_dir)
    (out / "a").mkdir(parents=True, exist_ok=True)
    (out / "b").mkdir(parents=True, exist_ok=True)
    pal, mapping = read_gpl(PAL_A), swap_map()
    for n, (gif, idx, scale, beat) in enumerate(PICKS):
        im = Image.open(Path(gif_dir) / f"{gif}.gif")
        im.seek(idx)
        frame = im.convert("RGB")
        factor = TARGET_PX / STAND_PX / scale
        a = to_canvas(clean(shrink(roles_of(frame), factor)), pal)
        name = f"jump_{n:02d}.png"
        a.save(out / "a" / name)
        bake_image(a, mapping).save(out / "b" / name)
        print(f"{name}: {gif}:{idx} ({beat}) height {a.getbbox()[3] - a.getbbox()[1]} px")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
