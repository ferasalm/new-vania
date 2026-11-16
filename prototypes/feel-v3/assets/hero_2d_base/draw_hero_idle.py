#!/usr/bin/env python3
"""pandora_idle_base — native 112x80 RGBA pixel art, ONE committed idle frame (spike).

Correction pass: adult face profile, 5 curving tapered hair masses with shade breaks,
deltoid/biceps/elbow arm taper, diagonal shoulders + narrow waist, clean central cyan
emblem, cape/leg negative space. Layers: hair_back, cape, body, arms, head_hair_front,
details. Logical pivot (56, 76); sole row 75. Candidate palette: palette.json.
NOT production-ready, NOT approved, one frame only.
"""
import json, os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 112, 80
PIVOT = (56, 76)
SOLE = 75

with open(os.path.join(HERE, "palette.json")) as f:
    PAL = json.load(f)["palette"]
C = {k: tuple(int(v[i:i+2], 16) for i in (1, 3, 5)) + (255,) for k, v in PAL.items()}
T = (0, 0, 0, 0)

layers = {n: Image.new("RGBA", (W, H), T) for n in
          ["hair_back", "cape", "body", "arms", "head_hair_front", "details"]}
def D(n): return ImageDraw.Draw(layers[n])
def poly(n, pts, col): D(n).polygon(pts, fill=col)
def px(n, pts, col): D(n).point(pts, fill=col)
def hline(n, x0, x1, y, col): D(n).line([(x0, y), (x1, y)], fill=col)
def vline(n, x, y0, y1, col): D(n).line([(x, y0), (x, y1)], fill=col)

# ================================================================ HAIR_BACK
# Five masses: crown arc, main sail, descending lock, loose tip flick, short tie flick.
h = "hair_back"
# M5 — short flick above the tie
poly(h, [(57,9),(61,8),(63,10),(60,12),(57,11)], C["hair_mid"])
px(h, [(61,9),(62,9)], C["hair_light"])
# M1 — crown arc (thick curved crescent, not a bun)
poly(h, [(57,11),(52,9),(46,10),(40,13),(35,17),(32,20),(35,21),(41,17),(47,14),
         (53,12),(57,13)], C["hair_mid"])
px(h, [(35,20),(39,18),(44,16),(49,14),(54,12)], C["hair_shade"])
px(h, [(50,10),(45,11),(40,14),(36,17),(33,19)], C["hair_light"])
# 1px deep break between crown arc and main sail
px(h, [(35,18),(38,16),(41,15),(44,14)], C["hair_deep"])
# M2 — main sail sweeping back and down
poly(h, [(49,13),(43,15),(36,19),(30,25),(26,31),(24,36),(28,37),(31,31),(36,26),
         (42,21),(47,17)], C["hair_mid"])
poly(h, [(28,37),(30,32),(36,27),(43,22),(47,18),(45,20),(38,25),(31,31),(29,36)], C["hair_shade"])
px(h, [(46,13),(40,16),(34,20),(29,25),(26,30)], C["hair_light"])
# M3 — long descending lock, curved and tapering
poly(h, [(31,27),(29,33),(27,41),(25,49),(24,56),(27,57),(28,49),(30,41),(32,34),
         (34,28)], C["hair_mid"])
poly(h, [(29,35),(28,41),(26,49),(25,56),(27,56),(27,49),(28,41),(29,35)], C["hair_shade"])
px(h, [(30,30),(29,35),(28,40),(27,45),(26,50),(25,55)], C["hair_light"])
# 1px deep break between sail and descending lock
px(h, [(30,27),(28,33),(26,40)], C["hair_deep"])
# M4 — loose tip flick tapering separately
poly(h, [(25,54),(27,55),(24,61),(21,64),(20,62),(22,58)], C["hair_mid"])
px(h, [(21,63),(20,62)], C["hair_deep"])
px(h, [(26,56),(25,58),(24,60)], C["hair_light"])

# ================================================================ CAPE
c = "cape"
# back-left drape, tattered hem, held clear of the back leg
poly(c, [(52,30),(57,30),(54,37),(51,45),(48,52),(45,58),(42,63),(40,60),(41,56),
         (39,53),(42,49),(40,45),(43,41),(42,36),(45,32)], C["cape_base"])
poly(c, [(53,32),(55,32),(52,40),(49,48),(46,55),(43,60),(42,57),(44,51),(46,45),
         (47,38)], C["cape_shade"])
px(c, [(42,63),(40,60),(41,56),(45,58),(48,52),(51,45)], C["cape_edge"])
px(c, [(54,37),(52,41),(50,45)], C["cape_edge"])

# ================================================================ BODY
b = "body"
# high scarf collar (leaves 2px neck visible above)
poly(b, [(53,29),(62,29),(65,31),(64,33),(60,34),(55,34),(52,32),(51,30)], C["scarf_base"])
poly(b, [(53,29),(55,29),(54,33),(55,34),(53,33),(52,32),(51,30)], C["scarf_shade"])
hline(b, 55, 62, 31, C["cape_edge"])
px(b, [(62,30),(63,31)], C["scarf_shade"])
# torso — diagonal shoulder line, chest taper, narrow waist
poly(b, [(53,31),(66,31),(67,35),(66,38),(64,42),(62,45),(55,45),(53,42),(52,38),
         (52,34)], C["suit_base"])
poly(b, [(53,31),(55,31),(54,41),(56,45),(55,45),(53,42),(52,38),(52,34)], C["suit_shade"])
poly(b, [(66,31),(67,35),(66,38),(64,42),(63,42),(65,37),(65,33)], C["suit_hi"])
hline(b, 56, 63, 38, C["suit_shade"])
# waist/belt + hips
hline(b, 55, 62, 44, C["boot_shade"])
poly(b, [(54,44),(63,44),(64,50),(53,50)], C["suit_base"])
poly(b, [(54,44),(56,44),(55,50),(53,50)], C["suit_shade"])
hline(b, 56, 62, 49, C["suit_hi"])
# BACK LEG — weight-bearing, planted, slight knee bend
poly(b, [(52,49),(57,49),(56,61),(52,61)], C["suit_base"])
poly(b, [(52,49),(54,49),(53,61),(52,61)], C["suit_shade"])
poly(b, [(51,60),(56,60),(56,63),(51,63)], C["boot_shade"])
hline(b, 52, 55, 60, C["boot_hi"])
poly(b, [(52,62),(56,62),(54,69),(50,69)], C["suit_base"])
poly(b, [(52,62),(53,62),(51,68),(50,69)], C["suit_shade"])
poly(b, [(49,68),(56,68),(57,73),(57,75),(45,75),(45,73),(47,72),(48,69)], C["boot_base"])
poly(b, [(49,68),(51,68),(49,72),(47,72),(46,73),(45,75),(45,73),(47,72),(48,69)], C["boot_shade"])
hline(b, 50, 55, 69, C["boot_hi"])
# FRONT LEG — relaxed forward, knee bend
poly(b, [(59,49),(64,49),(63,61),(59,61)], C["suit_base"])
poly(b, [(59,49),(61,49),(60,61),(59,61)], C["suit_shade"])
poly(b, [(58,60),(63,60),(63,63),(58,63)], C["boot_shade"])
hline(b, 59, 62, 60, C["boot_hi"])
poly(b, [(59,62),(63,62),(62,69),(59,69)], C["suit_base"])
poly(b, [(59,62),(60,62),(60,69),(59,69)], C["suit_shade"])
poly(b, [(58,67),(65,67),(67,71),(67,75),(57,75),(57,72),(58,70)], C["boot_base"])
poly(b, [(58,67),(60,67),(60,71),(58,71),(57,73),(57,75),(58,70)], C["boot_shade"])
hline(b, 59, 65, 68, C["boot_hi"])

# ================================================================ ARMS
a = "arms"
# NEAR ARM: deltoid cap, biceps taper to elbow, dark gauntlet cocked up, gloved fist
poly(a, [(64,31),(67,32),(68,35),(66,37),(64,35),(63,32)], C["skin_base"])
px(a, [(66,32),(67,33)], C["skin_light"])
px(a, [(64,34),(64,35)], C["skin_shade"])
poly(a, [(64,35),(67,36),(66,40),(64,41),(63,37)], C["skin_base"])
poly(a, [(64,35),(65,35),(64,40),(64,41),(63,37)], C["skin_shade"])
px(a, [(66,37),(66,38)], C["skin_light"])
px(a, [(65,41),(66,41)], C["skin_shade"])
poly(a, [(64,41),(66,43),(61,39),(59,37),(58,37),(60,40),(63,43)], C["gauntlet_base"])
px(a, [(64,42),(65,43),(61,39),(60,38)], C["gauntlet_shade"])
px(a, [(62,40),(61,39)], C["boot_hi"])
px(a, [(59,37)], C["cyan_deep"])
poly(a, [(56,33),(59,35),(58,37),(55,36),(55,34)], C["gauntlet_base"])
px(a, [(58,34),(57,35)], C["boot_hi"])
px(a, [(56,36),(57,36)], C["gauntlet_shade"])
# FAR ARM: deltoid, biceps, hanging gauntlet, loose fist
poly(a, [(49,31),(52,32),(53,35),(51,36),(49,34),(48,32)], C["skin_base"])
px(a, [(52,32),(52,33)], C["skin_light"])
px(a, [(49,33),(49,34)], C["skin_shade"])
poly(a, [(49,35),(52,36),(51,41),(49,41),(48,37)], C["skin_base"])
poly(a, [(49,35),(50,35),(49,40),(49,41),(48,37)], C["skin_shade"])
px(a, [(51,36),(51,37)], C["skin_light"])
poly(a, [(48,40),(51,41),(49,47),(45,47),(44,44),(46,41)], C["gauntlet_base"])
poly(a, [(48,40),(49,40),(47,46),(45,47),(44,44)], C["gauntlet_shade"])
px(a, [(50,42),(49,43)], C["boot_hi"])
poly(a, [(42,45),(46,46),(45,49),(42,49),(41,47)], C["gauntlet_base"])
px(a, [(45,47),(44,48)], C["boot_hi"])

# ================================================================ HEAD+HAIR FRONT
f = "head_hair_front"
# hair cap / back-of-head volume
poly(f, [(50,14),(55,11),(60,11),(63,14),(63,19),(61,23),(58,26),(54,25),(51,22),(49,18)], C["hair_mid"])
poly(f, [(50,14),(52,13),(51,21),(54,25),(52,23),(49,18)], C["hair_shade"])
# face — mature right 3/4 profile: brow ridge, projecting nose, jaw, chin
poly(f, [(59,16),(62,17),(63,19),(65,22),(64,23),(63,24),(62,26),(59,27),(57,24),(57,18)], C["skin_base"])
poly(f, [(57,18),(58,17),(58,25),(60,27),(58,27),(57,24)], C["skin_shade"])
px(f, [(62,18),(63,20),(64,21)], C["skin_light"])
px(f, [(62,25),(63,24),(62,26)], C["skin_shade"])
# neck with 1px jaw-shadow separation
poly(f, [(59,27),(62,27),(62,29),(59,29)], C["skin_base"])
px(f, [(59,27),(59,28),(60,28)], C["skin_shade"])
hline(f, 58, 62, 27, C["skin_shade"])
# bangs — layered swept fringe, hairline arc, right-pointing tips
poly(f, [(49,17),(50,13),(54,11),(59,10),(63,13),(64,16),(62,16),(60,14),(58,16),
         (56,14),(55,16),(53,15),(52,18),(50,19)], C["hair_mid"])
px(f, [(52,12),(55,11),(58,11),(60,12),(62,13)], C["hair_light"])
hline(f, 57, 62, 17, C["hair_shade"])
hline(f, 53, 56, 18, C["hair_shade"])
# forelock sweeping right over the brow
poly(f, [(62,14),(66,15),(64,18),(63,16)], C["hair_mid"])
px(f, [(65,15)], C["hair_light"])
px(f, [(64,17)], C["hair_shade"])
# cheek-framing side lock
poly(f, [(50,19),(52,20),(51,26),(49,26),(48,23)], C["hair_mid"])
px(f, [(50,22),(49,24)], C["hair_shade"])
# high tie knot
poly(f, [(54,10),(58,10),(59,13),(54,13)], C["hair_deep"])
px(f, [(55,11),(56,11)], C["hair_shade"])

# ================================================================ DETAILS
d = "details"
# clean central chest emblem: V + spine + diamond
px(d, [(58,34),(59,35),(60,36),(61,35),(62,34)], C["cyan_glow"])
vline(d, 60, 37, 41, C["cyan_glow"])
px(d, [(60,38)], C["rim_cyan"])
px(d, [(59,39),(61,39),(60,40)], C["cyan_deep"])
px(d, [(59,42),(61,42)], C["cyan_deep"])
px(d, [(57,46),(62,46)], C["cyan_deep"])
# leg seams
vline(d, 62, 52, 59, C["cyan_deep"])
px(d, [(62,55)], C["cyan_glow"])
vline(d, 62, 63, 66, C["cyan_deep"])
vline(d, 56, 52, 56, C["cyan_deep"])
px(d, [(63,30)], C["cyan_deep"])
# face: one cyan eye, narrow brow, nose step, mouth, jaw
px(d, [(62,21)], C["eye_cyan"])
px(d, [(61,21)], C["cyan_deep"])
hline(d, 61, 63, 20, C["hair_deep"])
px(d, [(64,23),(63,24),(62,26)], C["skin_shade"])
# 1-px cyan rim key on right contour
px(d, [(67,32),(67,33),(66,34),(66,35),(66,36),(65,40),(64,41),(64,42),(64,50),
       (65,51),(64,52),(64,58),(64,59),(68,69),(68,70),(69,71),(69,72),(69,73),
       (67,74)], C["rim_cyan"])

# ================================================================ COMPOSITE
order = ["hair_back", "cape", "body", "arms", "head_hair_front", "details"]
comp = Image.new("RGBA", (W, H), T)
for n in order:
    comp.alpha_composite(layers[n])

os.makedirs(os.path.join(HERE, "layers"), exist_ok=True)
for n, img in layers.items():
    img.save(os.path.join(HERE, "layers", f"pandora_idle_{n}.png"))
comp.save(os.path.join(HERE, "pandora_idle_base.png"))
comp4 = comp.resize((W * 4, H * 4), Image.NEAREST)
comp4.save(os.path.join(HERE, "pandora_idle_base_4x.png"))

# ---------------------------------------------------------------- PROOF SHEET
# Row 1: native dark / light / grayscale. Row 2: full 4x dark / light / grayscale.
M, GAP, CAP = 8, 8, 14
PANEL_W, PANEL_H = W * 4, H * 4
ROW1_H, ROW2_H = H, PANEL_H
sheet_w = M * 2 + PANEL_W * 3 + GAP * 2
row2_top = M + ROW1_H + CAP + GAP
sheet_h = row2_top + ROW2_H + CAP + M

def on_bg(img, bg):
    base = Image.new("RGBA", (img.width, img.height), bg)
    base.alpha_composite(img)
    return base

DARK, LIGHT = (20, 24, 32, 255), (214, 210, 200, 255)
gl = comp.convert("LA")
gray = Image.merge("RGBA", (gl.split()[0],) * 3 + (gl.split()[1],))
sheet = Image.new("RGBA", (sheet_w, sheet_h), (62, 62, 66, 255))
draw = ImageDraw.Draw(sheet)
font = ImageDraw.Draw(Image.new("RGBA", (1, 1))).getfont() if False else None
from PIL import ImageFont
try:
    font = ImageFont.load_default()
except Exception:
    font = None

def caption(x, y, text):
    if font:
        draw.text((x, y), text, fill=(228, 228, 232, 255), font=font)

panels = [
    (M + 0 * (PANEL_W + GAP), M, on_bg(comp, DARK), "1x dark"),
    (M + 1 * (PANEL_W + GAP), M, on_bg(comp, LIGHT), "1x light"),
    (M + 2 * (PANEL_W + GAP), M, on_bg(gray, DARK), "1x grayscale"),
    (M + 0 * (PANEL_W + GAP), row2_top, on_bg(comp4, DARK), "4x dark"),
    (M + 1 * (PANEL_W + GAP), row2_top, on_bg(comp4, LIGHT), "4x light"),
    (M + 2 * (PANEL_W + GAP), row2_top, on_bg(gray4 := gray.resize((PANEL_W, PANEL_H), Image.NEAREST), DARK), "4x grayscale"),
]
for x, y, im, cap in panels:
    sheet.alpha_composite(im, (x, y))
    caption(x + 2, y + im.height + 2, cap)
sheet.save(os.path.join(HERE, "proof_pandora_idle_base.png"))

# ---------------------------------------------------------------- METADATA
meta = {
    "asset": "pandora_idle_base",
    "production_ready": False,
    "approved": False,
    "one_frame_only": True,
    "revision": "correction_pass_1",
    "first_draft_backup": "first_draft/",
    "dimensions": [W, H],
    "logical_pivot": list(PIVOT),
    "sole_row": SOLE,
    "facing": "right_3_4",
    "source_reference_filenames": [
        "Modify_woman_upper_arms_skin_580f0e04.jpg",
        "image.png_cbe4f7e4.jpg",
    ],
    "source_reference_dir": "prototypes/feel-v3/assets/pandora_proportion_study/reference/",
    "palette_file": "palette.json",
    "palette_note": "candidate visual-spike palette, NOT a bible table amendment; needs art-director approval",
    "generator": "draw_hero_idle.py (PIL, native pixel geometry)",
    "layers": order,
    "proof_layout": {
        "size": [sheet_w, sheet_h],
        "row1_native_h": ROW1_H, "row2_4x_h": ROW2_H, "row2_top": row2_top,
        "caption_px": CAP, "margin_px": M, "gap_px": GAP,
    },
}
with open(os.path.join(HERE, "metadata.json"), "w") as fp:
    json.dump(meta, fp, indent=2)

# ---------------------------------------------------------------- ASSERTIONS
bb = comp.getbbox()
assert comp.size == (W, H), "composite must be native 112x80"
assert {p[3] for p in comp.getdata()} <= {0, 255}, "alpha must be binary 0/255"
assert bb[0] >= 1 and bb[1] >= 1, "left/top padding >= 1px"
assert W - bb[2] >= 1, "right padding >= 1px"
assert bb[3] == SOLE + 1, f"content must end at sole row {SOLE} (exclusive bbox end {bb[3]})"
assert all(comp.getpixel((x, PIVOT[1]))[3] == 0 for x in range(W)), "pivot row must be empty"
assert sheet.size == (sheet_w, sheet_h), "proof sheet dimensions"
assert row2_top + ROW2_H + CAP <= sheet_h - M + 1, "4x row must fit with caption"
assert sheet_h >= M + ROW1_H + CAP + GAP + ROW2_H + CAP + M - 1, "proof height fits both rows"
# every panel must contain the whole sprite with >=4px margin (no clipping)
for x, y, im, cap in panels:
    s = 4 if "4x" in cap else 1
    pbb = (bb[0] * s, bb[1] * s, bb[2] * s, bb[3] * s)
    assert pbb[0] >= 4 and pbb[1] >= 4, f"{cap}: left/top margin"
    assert pbb[2] <= im.width - 4 and pbb[3] <= im.height - 4, f"{cap}: right/bottom margin"
    assert x + im.width <= sheet_w and y + im.height <= sheet_h, f"{cap}: panel inside sheet"
# panels must not overlap
assert M + 3 * PANEL_W + 2 * GAP + M == sheet_w

cols = sorted({p for p in comp.getdata() if p[3] > 0})
print("dims", comp.size, "bbox", bb, "height_px", bb[3] - bb[1])
print("alpha_values", sorted({p[3] for p in comp.getdata()}), "unique_rgba", len(cols))
print("padding L/T/R/B", bb[0], bb[1], W - 1 - bb[2], H - 1 - bb[3])
print("pivot row empty", all(comp.getpixel((x, PIVOT[1]))[3] == 0 for x in range(W)))
print("feet opaque at sole", sum(1 for x in range(W) if comp.getpixel((x, SOLE))[3] == 255))
print("proof", sheet.size, "row2_top", row2_top, "row2_bottom", row2_top + ROW2_H)
