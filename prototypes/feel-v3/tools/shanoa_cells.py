"""Finds every sprite on the reference sheet (connected blobs) and groups them in rows.
Used by build_pandora.py; run directly to write labelled preview strips."""
import sys
from PIL import Image
import numpy as np

def cells(path):
    im = Image.open(path).convert("RGBA")
    a = np.array(im)
    bg = ((a[..., 0] == 0) & (a[..., 1] == 255) & (a[..., 2] == 0)) | \
         ((a[..., 0] == 0) & (a[..., 1] == 128) & (a[..., 2] == 128)) | (a[..., 3] == 0)
    fg = ~bg
    fg[:100, 90:360] = False  # the palette swatch block
    # rows = bands of the sheet with any sprite pixel; sprites = runs inside a band
    rows = []
    ys = fg.any(axis=1)
    y = 0
    H = fg.shape[0]
    while y < H:
        if not ys[y]:
            y += 1
            continue
        y0 = y
        while y < H and (ys[y] or ys[y:y + 3].any()):
            y += 1
        band = fg[y0:y]
        xs = band.any(axis=0)
        x = 0
        r = []
        while x < 640:
            if not xs[x]:
                x += 1
                continue
            x0 = x
            while x < 640 and (xs[x] or xs[x:x + 4].any()):
                x += 1
            sub = band[:, x0:x]
            if sub.sum() < 60:
                continue
            yy = np.where(sub.any(axis=1))[0]
            r.append((x0, y0 + yy.min(), x, y0 + yy.max() + 1))
        if r:
            rows.append({"b": r})
    out = []
    for r in rows:
        out.append(sorted(r["b"]))
    return im, fg, out

if __name__ == "__main__":
    from PIL import ImageDraw
    im, fg, rows = cells(sys.argv[1])
    outdir = sys.argv[2]
    Z = 2
    per = 9
    for k in range(0, len(rows), per):
        chunk = rows[k:k + per]
        H = sum(max(b[3] for b in r) - min(b[1] for b in r) + 16 for r in chunk)
        sheet = Image.new("RGB", (640 * Z, H * Z), (60, 60, 70))
        d = ImageDraw.Draw(sheet)
        y = 0
        for ri, r in enumerate(chunk):
            top = min(b[1] for b in r); bot = max(b[3] for b in r)
            for ci, b in enumerate(r):
                c = im.crop(b).resize(((b[2] - b[0]) * Z, (b[3] - b[1]) * Z), Image.NEAREST)
                m = Image.fromarray((fg[b[1]:b[3], b[0]:b[2]] * 255).astype("uint8")).resize(c.size, Image.NEAREST)
                sheet.paste(c, (b[0] * Z, (y + 12 + b[1] - top) * Z), m)
                d.text((b[0] * Z, y * Z + 2), f"{k + ri}.{ci}", fill=(255, 255, 0))
            y += bot - top + 16
        sheet.save(f"{outdir}/rows_{k:02d}.png")
    print(len(rows), [len(r) for r in rows])
