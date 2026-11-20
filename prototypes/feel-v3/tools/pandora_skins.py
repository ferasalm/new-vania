# PROTOTYPE - NOT FOR PRODUCTION
"""Pandora's skins: palette A (main, cyan glow) and skin B (oxblood, red glow).

Every Pandora sprite is drawn in palette A only (assets/palettes/pandora.gpl). Skin B is never
drawn by hand: this tool bakes it by swapping colour i of A for colour i of B
(assets/palettes/pandora_b.gpl). Workflow: design/skins.md.

  python -I tools/pandora_skins.py strips                       write the 16 x 1 px palette strips
  python -I tools/pandora_skins.py check <png|dir> ...          every pixel must be in palette A
  python -I tools/pandora_skins.py bake <png|dir> ... --out D   write the skin-B copies into D

Run from prototypes/feel-v3. `bake` refuses a frame with any colour outside palette A
(fix the frame first; nothing is guessed). See-through pixels stay see-through.
"""
import sys
from pathlib import Path
from PIL import Image

HERE = Path(__file__).resolve().parent.parent
PAL_A = HERE / "assets/palettes/pandora.gpl"
PAL_B = HERE / "assets/palettes/pandora_b.gpl"


def read_gpl(path):
    """The palette's colours in file order, as (r, g, b) tuples."""
    out = []
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        parts = line.split()
        if len(parts) >= 3 and all(p.isdigit() for p in parts[:3]):
            out.append(tuple(int(p) for p in parts[:3]))
    if len(out) != 16:
        raise SystemExit(f"{path}: expected 16 colours, found {len(out)}")
    return out


def swap_map():
    """Palette A colour -> skin B colour."""
    return dict(zip(read_gpl(PAL_A), read_gpl(PAL_B)))


def off_palette(img, pal):
    """Opaque pixels whose colour is not in pal, as a count and the first few colours."""
    allowed = set(pal)
    bad = {}
    for r, g, b, a in img.convert("RGBA").getdata():
        if a and (r, g, b) not in allowed:
            bad[(r, g, b)] = bad.get((r, g, b), 0) + 1
    return sum(bad.values()), sorted(bad, key=bad.get, reverse=True)[:5]


def bake_image(img, mapping):
    """The skin-B copy of a palette-A image (alpha kept as is)."""
    src = img.convert("RGBA")
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    out.putdata([(mapping[(r, g, b)] + (a,)) if a else (0, 0, 0, 0) for r, g, b, a in src.getdata()])
    return out


def _pngs(args):
    for a in args:
        p = Path(a)
        if p.is_dir():
            yield from sorted(p.glob("*.png"))
        else:
            yield p


def main(argv):
    if not argv:
        raise SystemExit(__doc__)
    cmd = argv[0]
    if cmd == "strips":
        for gpl in (PAL_A, PAL_B):
            strip = Image.new("RGB", (16, 1))
            strip.putdata(read_gpl(gpl))
            strip.save(gpl.with_suffix(".png"))
            print("wrote", gpl.with_suffix(".png").name)
        return 0
    if cmd == "check":
        pal, failed = read_gpl(PAL_A), 0
        for p in _pngs(argv[1:]):
            n, cols = off_palette(Image.open(p), pal)
            if n:
                failed += 1
                print(f"FAIL {p}: {n} px off palette A, e.g. {cols}")
        print("check:", "FAIL" if failed else "OK")
        return 1 if failed else 0
    if cmd == "bake":
        if "--out" not in argv:
            raise SystemExit("bake needs --out <dir>")
        i = argv.index("--out")
        out_dir, files = Path(argv[i + 1]), argv[1:i] + argv[i + 2:]
        out_dir.mkdir(parents=True, exist_ok=True)
        mapping, pal = swap_map(), read_gpl(PAL_A)
        done = 0
        for p in _pngs(files):
            img = Image.open(p)
            n, cols = off_palette(img, pal)
            if n:
                raise SystemExit(f"{p}: {n} px off palette A, e.g. {cols}; clean it before baking skin B")
            bake_image(img, mapping).save(out_dir / p.name)
            done += 1
        print(f"baked {done} frame(s) into {out_dir}")
        return 0
    raise SystemExit(__doc__)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
