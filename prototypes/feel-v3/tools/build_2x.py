# PROTOTYPE - NOT FOR PRODUCTION
# Makes the double-detail copies (assets/2x/...) of every older picture, so the
# rooms, doors, enemies, boss and effects match Pandora's new pixel density.
# G.tex() prefers assets/2x/<path> and draws it at the old world size.
#
#   python tools/build_2x.py              (from prototypes/feel-v3)
#
# Pixel-art pictures are doubled with an edge-aware scaler (AdvMAME2x / Scale2x:
# staircase edges become smooth diagonals, flat areas stay flat), then given a light
# dither of their own neighbouring colours so big flat areas are not 2x2 blocks.
# The weapons are rebuilt at twice the size from their concept pictures
# (assets/references/, kept on this machine only) when those are present.
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
A = os.path.join(HERE, "..", "assets")
OUT = os.path.join(A, "2x")
FOLDERS = ["env", "fx", "boss", "hound", "ghost", "choir", "spitter", "warden"]


def scale2x(arr):
    p = np.pad(arr, ((1, 1), (1, 1), (0, 0)), mode="edge")
    E = p[1:-1, 1:-1]
    B = p[:-2, 1:-1]
    D = p[1:-1, :-2]
    F = p[1:-1, 2:]
    H = p[2:, 1:-1]

    def eq(a, b):
        return np.all(a == b, axis=2)

    e0 = np.where((eq(D, B) & ~eq(B, F) & ~eq(D, H))[..., None], D, E)
    e1 = np.where((eq(B, F) & ~eq(B, D) & ~eq(F, H))[..., None], F, E)
    e2 = np.where((eq(D, H) & ~eq(D, B) & ~eq(H, F))[..., None], D, E)
    e3 = np.where((eq(H, F) & ~eq(D, H) & ~eq(B, F))[..., None], F, E)
    h, w, c = arr.shape
    out = np.zeros((h * 2, w * 2, c), arr.dtype)
    out[0::2, 0::2] = e0
    out[0::2, 1::2] = e1
    out[1::2, 0::2] = e2
    out[1::2, 1::2] = e3
    return out


def texture(arr):
    # breaks up flat 2x2 blocks: inside a flat area, one pixel of each block takes a
    # slightly lighter or darker step of the same colour (a soft ordered texture)
    out = arr.astype(np.int16)
    h, w = arr.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    up = np.roll(arr, 1, axis=0)
    left = np.roll(arr, 1, axis=1)
    flat = np.all(arr == up, axis=2) & np.all(arr == left, axis=2) & (arr[..., 3] > 0)
    bayer = np.array([[0, 2], [3, 1]])
    k = bayer[yy % 2, xx % 2]
    shade = np.where(k == 3, 6, np.where(k == 0, -5, 0))
    for c in range(3):
        out[..., c] = np.where(flat, out[..., c] + shade, out[..., c])
    return np.clip(out, 0, 255).astype(np.uint8)


def do_file(src, dst):
    im = Image.open(src).convert("RGBA")
    arr = np.array(im)
    big = scale2x(arr)
    big = texture(big)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    Image.fromarray(big, "RGBA").save(dst)


def weapons():
    ref = os.path.join(A, "references")
    if not os.path.exists(os.path.join(ref, "dirge-042.jpg")):
        print("weapons: references missing, doubling the old weapon pictures instead")
        for n in ["dirge", "elegy"]:
            do_file(os.path.join(A, "weapon", n + ".png"), os.path.join(OUT, "weapon", n + ".png"))
        return
    sys.path.insert(0, HERE)
    sys.argv = [sys.argv[0], ref, ref]
    import build_world as bw
    old_d = Image.open(os.path.join(A, "weapon", "dirge.png")).size
    old_e = Image.open(os.path.join(A, "weapon", "elegy.png")).size
    for name, n, rot, cols, old in [("dirge", "dirge-042", 0, 16, old_d), ("elegy", "elegy-013", -47.5, 18, old_e)]:
        im = bw.key_green(Image.open(os.path.join(ref, n + ".jpg")))
        if rot:
            im = im.rotate(rot, expand=True, resample=Image.BICUBIC)
        im = im.crop(im.getbbox())
        # the same picture as before, at exactly twice the old pixel size (grip points stay valid)
        target = (old[0] * 2 - 2, old[1] * 2 - 2)
        im = im.resize(target, Image.LANCZOS)
        a = np.array(im)
        a[..., 3] = np.where(a[..., 3] >= 128, 255, 0)
        im = Image.fromarray(a, "RGBA")
        im = bw.quant(im, cols)
        im = bw.outline(im)
        canvas = Image.new("RGBA", (old[0] * 2, old[1] * 2), (0, 0, 0, 0))
        canvas.alpha_composite(im, ((canvas.width - im.width) // 2, (canvas.height - im.height) // 2))
        os.makedirs(os.path.join(OUT, "weapon"), exist_ok=True)
        canvas.save(os.path.join(OUT, "weapon", name + ".png"))
        print("weapon", name, canvas.size)


def main():
    n = 0
    for folder in FOLDERS:
        src_dir = os.path.join(A, folder)
        if not os.path.isdir(src_dir):
            continue
        for f in sorted(os.listdir(src_dir)):
            if f.endswith(".png"):
                do_file(os.path.join(src_dir, f), os.path.join(OUT, folder, f))
                n += 1
    weapons()
    print("2x copies:", n)


if __name__ == "__main__":
    main()
