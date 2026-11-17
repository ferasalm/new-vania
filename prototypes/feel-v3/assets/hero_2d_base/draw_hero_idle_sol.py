"""Sol-authored native-pixel Pandora idle look test; run with Python/Pillow.

Writes only beside this script. No external images, 3D renders or traced sprites
are sampled. Layered Aseprite output and PNGs share the same native pixel data.
This is one unapproved appearance candidate, not an animation set.
"""
import json
import struct
import zlib
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps

OUT = Path(__file__).resolve().parent
SIZE = (112, 80)


def build():
    """Draw curated native-resolution contours, material planes and pixel accents."""
    palette = json.loads((OUT / 'palette_sol.json').read_text())['colors']
    layers = {}
    draw = None

    def layer(name):
        nonlocal draw
        image = Image.new('RGBA', SIZE)
        layers[name] = image
        draw = ImageDraw.Draw(image)

    def poly(points, color, edge=None):
        draw.polygon(points, fill=palette[color], outline=palette[edge] if edge else None)

    def line(points, color, width=1):
        draw.line(points, fill=palette[color], width=width)

    def dots(points, color):
        for point in points:
            draw.point(point, fill=palette[color])

    # Independent overlapping S-curves: loose tapered locks, not one flat hook.
    layer('hair_back')
    poly([(51,8),(47,9),(44,12),(44,16),(41,19),(39,23),(39,27),
          (40,30),(38,34),(35,37),(34,41),(35,45),(35,48),(32,52),
          (36,51),(40,48),(42,44),(41,40),(43,37),(46,34),(47,31),
          (45,26),(46,22),(48,19),(49,15),(53,12)], 'hair', 'hair_shadow')
    poly([(48,11),(43,14),(39,18),(36,22),(35,25),(32,28),(29,29),
          (33,30),(36,28),(39,25),(41,21),(44,18),(48,16)], 'hair_dark', 'hair_shadow')
    line([(47,12),(43,15),(40,19),(38,23),(35,27),(32,28)], 'hair_light')
    line([(43,16),(40,20),(39,23),(36,27)], 'hair_hi')
    poly([(47,18),(45,23),(45,27),(47,31),(46,35),(43,39),
          (43,42),(46,44),(44,46),(48,44),(49,41),(47,38),
          (49,34),(49,31),(47,26),(49,22)], 'hair_dark', 'hair_shadow')
    line([(48,20),(47,24),(47,27),(48,31),(48,34),(46,38),(45,40),(46,42)], 'hair_light')
    poly([(47,13),(44,17),(42,22),(42,26),(44,30),(44,33),
          (41,37),(38,40),(37,43),(38,46),(36,49),(39,47),
          (40,44),(39,41),(42,38),(45,34),(45,30),(43,26),
          (43,23),(46,18),(49,15)], 'hair_light')
    line([(47,14),(45,17),(43,21),(43,24),(44,27)], 'hair_hi')
    line([(44,31),(43,34),(40,38),(38,41),(38,43)], 'hair_hi')
    line([(41,26),(42,30),(42,33),(39,37),(36,40),(36,43)], 'hair_shadow')
    dots([(37,47),(35,49),(34,50),(46,43)], 'hair_light')

    # Torn scarf-cape flows away from the legs; negative space at the lower hem.
    layer('cape')
    poly([(51,24),(47,27),(46,34),(43,41),(41,47),(38,54),
          (34,61),(36,60),(34,66),(39,63),(38,69),(43,64),
          (46,56),(49,48),(52,38),(55,29)], 'cloth_dark', 'outline')
    poly([(49,29),(47,37),(44,45),(42,51),(37,60),(40,58),
          (39,63),(43,59),(46,51),(48,42),(51,34)], 'cloth')
    line([(47,33),(46,39),(43,46),(42,50)], 'cloth_light')
    line([(46,47),(44,54),(41,60),(40,63)], 'suit_shadow')
    line([(39,56),(36,61)], 'cloth_light')
    dots([(35,63),(38,65),(42,61),(45,54)], 'cloth')

    layer('body')
    # Far leg recedes and carries the weight. Both boot toes face screen-right.
    poly([(51,41),(56,43),(55,48),(53,54),(51,59),(51,63),
          (50,70),(51,72),(55,74),(55,75),(46,75),(46,72),
          (47,69),(47,63),(47,59),(49,53),(49,47)], 'suit_shadow', 'outline')
    poly([(51,46),(54,45),(53,50),(51,55),(49,59),(48,59),
          (49,54),(50,50)], 'suit')
    poly([(48,61),(51,60),(50,66),(49,71),(47,71),(48,67)], 'suit')
    line([(50,61),(50,64),(49,68)], 'metal')
    line([(48,72),(49,73),(52,74)], 'metal')
    line([(47,75),(54,75)], 'suit_light')
    dots([(50,58),(49,59)], 'cyan_dark')
    # Near thigh, articulated knee, fitted shin plate and small angular boot.
    poly([(56,41),(61,42),(62,47),(62,51),(61,56),(62,59),
          (62,65),(63,71),(62,72),(66,74),(67,75),(58,75),
          (58,72),(59,69),(58,64),(58,60),(57,57),(57,53),
          (55,48)], 'suit', 'outline')
    poly([(59,44),(61,45),(61,51),(60,55),(58,56),(58,52),
          (57,48)], 'suit_light')
    line([(61,46),(61,50),(60,52)], 'metal')
    line([(58,44),(58,48),(59,51)], 'cyan_dark')
    poly([(59,56),(61,56),(62,58),(61,60),(59,60),(58,58)], 'metal', 'suit_shadow')
    dots([(60,57),(61,58)], 'metal_hi')
    poly([(60,61),(62,61),(62,65),(63,69),(61,71),(60,68)], 'suit_light')
    line([(62,62),(62,65),(63,68)], 'cyan')
    line([(60,63),(60,66),(61,68)], 'metal')
    poly([(60,72),(62,72),(64,74),(60,74),(59,75),(59,73)], 'metal')
    line([(62,74),(65,74)], 'metal_hi')
    line([(59,75),(67,75)], 'suit_light')
    # Athletic, tapered chassis. Value planes are asymmetric, not a flat box.
    poly([(52,24),(57,24),(62,25),(64,28),(62,32),(60,35),
          (59,38),(61,42),(60,45),(56,44),(54,45),(50,43),
          (51,39),(51,35),(49,31),(49,27)], 'suit', 'outline')
    poly([(51,28),(55,29),(57,32),(55,35),(53,35),(51,32)], 'suit_light')
    line([(51,28),(53,27),(55,28)], 'metal')
    poly([(58,28),(61,27),(62,29),(61,32),(58,34),(57,32)], 'suit_light')
    line([(59,28),(61,28),(61,29)], 'metal')
    poly([(55,35),(57,35),(59,34),(58,38),(59,40),(56,42),
          (53,40),(53,38)], 'suit_shadow')
    line([(52,34),(54,36),(53,39),(52,41)], 'cyan_dark')
    line([(60,33),(58,36),(59,39),(60,41)], 'cyan')
    line([(54,33),(56,35),(58,33)], 'cyan')
    line([(56,35),(56,38)], 'cyan_hi')
    line([(54,40),(56,41),(58,40)], 'metal')
    line([(52,42),(54,43),(55,43)], 'metal')
    line([(57,43),(60,42)], 'cyan_dark')

    layer('arms')
    # Exposed deltoid/biceps with a taper into the mechanical elbow joint.
    poly([(49,27),(51,27),(52,30),(51,33),(50,36),(48,37),
          (47,35),(48,32),(48,29)], 'skin', 'skin_shadow')
    line([(49,28),(50,28),(50,30),(49,33)], 'skin_light')
    dots([(49,29),(49,30)], 'skin_hi')
    line([(48,34),(49,35),(50,34)], 'skin_shadow')
    # Far hand hangs clear of the hip, not hidden as a rectangular shoulder tab.
    poly([(48,36),(50,37),(50,40),(49,42),(50,44),(49,46),
          (47,45),(46,42),(47,39)], 'suit_shadow', 'outline')
    line([(48,38),(49,38),(48,41)], 'metal')
    line([(47,41),(48,43),(49,44)], 'cyan_dark')
    dots([(48,45),(49,45)], 'metal')
    poly([(62,27),(64,28),(65,30),(65,33),(66,35),(65,37),
          (63,36),(62,33),(62,31),(61,29)], 'skin', 'skin_shadow')
    line([(63,28),(64,29),(64,32),(65,34)], 'skin_light')
    dots([(63,29),(63,30)], 'skin_hi')
    line([(63,34),(64,35)], 'skin_shadow')
    # A cocked blade hand; forearm silhouette angles out, then back to the waist.
    poly([(64,36),(66,35),(68,37),(69,40),(68,42),(67,44),
          (67,46),(65,47),(64,45),(65,42),(65,40),(63,38)], 'suit', 'outline')
    poly([(65,37),(66,37),(67,39),(67,41),(65,43),(66,40)], 'metal')
    line([(68,38),(68,40),(67,42)], 'cyan')
    dots([(66,44),(65,45)], 'metal_hi')
    line([(65,46),(66,46)], 'suit_light')
    # Fine, sparse synthetic joint marks: one pixel, not a tattoo-sized stripe.
    dots([(49,31),(64,31)], 'skin_shadow')
    dots([(50,36),(65,36)], 'metal_hi')

    layer('head_hair_front')
    # Neck first, then a deliberately shaped small adult profile.
    poly([(57,19),(61,20),(61,23),(63,24),(60,26),(55,24),
          (57,22)], 'suit_shadow', 'outline')
    line([(58,21),(58,23),(59,24)], 'cyan_dark')
    line([(60,22),(60,24)], 'cyan')
    poly([(57,12),(61,11),(64,13),(64,15),(65,16),(65,17),
          (66,18),(64,19),(64,20),(62,22),(60,22),(58,20),
          (57,17)], 'skin_light', 'skin_shadow')
    poly([(58,14),(59,15),(59,18),(61,20),(63,20),(62,22),
          (60,21),(58,19)], 'skin')
    dots([(63,14),(64,16),(65,18),(63,20)], 'skin_hi')
    line([(62,15),(64,15)], 'skin_ink')
    dots([(63,16)], 'cyan_hi')
    dots([(64,17),(64,19),(61,21)], 'skin_shadow')
    dots([(63,19)], 'skin_ink')
    # Swept crown, broken fringe and the small high-ponytail tie.
    poly([(53,11),(54,9),(57,8),(60,9),(62,10),(63,12),
          (64,14),(62,14),(61,13),(60,15),(58,14),(57,16),
          (56,18),(54,20),(54,23),(53,22),(53,18),(52,16)], 'hair', 'hair_shadow')
    poly([(54,11),(56,9),(59,9),(61,11),(61,12),(59,11),
          (57,12),(56,14),(54,16)], 'hair_light')
    line([(55,11),(57,10),(59,10),(60,11)], 'hair_hi')
    line([(58,12),(59,13),(60,14)], 'hair_hi')
    line([(55,15),(54,18),(54,20)], 'hair_light')
    line([(57,12),(56,14),(55,15)], 'hair_shadow')
    poly([(53,10),(51,9),(50,10),(50,12),(52,13),(54,12)], 'suit_shadow', 'outline')
    dots([(51,10),(52,10)], 'metal')
    # Forelock ends separately from the ponytail, framing rather than hiding face.
    poly([(56,17),(57,18),(56,20),(57,22),(56,25),(54,27),
          (53,27),(55,24),(55,22),(54,20)], 'hair_dark')
    line([(56,18),(55,20),(56,22),(56,24),(54,26)], 'hair_light')

    layer('details')
    # Cloth folds across the collar: shoulder slope no longer a horizontal box.
    poly([(52,23),(55,24),(59,25),(62,23),(63,25),(62,27),
          (59,28),(55,27),(51,26),(50,25)], 'cloth', 'outline')
    line([(52,24),(55,25),(59,26),(61,25)], 'cloth_light')
    line([(54,26),(57,27),(60,27)], 'suit_shadow')
    # Sparse key-facing 1px rim, kept out of exposed flesh and silver highlights.
    line([(63,28),(64,29)], 'cyan_dark')
    dots([(61,34),(60,36),(61,42),(62,48),(63,64),(64,69)], 'cyan_dark')

    image = Image.new('RGBA', SIZE)
    (OUT / 'layers_sol').mkdir(exist_ok=True)
    for name, part in layers.items():
        part.save(OUT / 'layers_sol' / f'{name}.png')
        image = Image.alpha_composite(image, part)
    image.save(OUT / 'pandora_idle_base.png')
    image.resize((448, 320), Image.Resampling.NEAREST).save(OUT / 'pandora_idle_base_4x.png')
    proof(image)
    write_aseprite(layers, palette)
    pixels = list(image.getdata())
    bbox = image.getbbox()
    assert image.size == SIZE and image.mode == 'RGBA'
    assert {p[3] for p in pixels} == {0, 255}
    assert bbox[0] > 0 and bbox[1] > 0 and bbox[2] < 112 and bbox[3] == 76
    assert not any(image.getpixel((x, 76))[3] for x in range(112))
    metadata = {
        'asset': 'pandora_idle_base', 'author': 'Sol direct pixel authoring',
        'production_ready': False, 'approved': False, 'one_frame_only': True,
        'dimensions': list(SIZE), 'logical_pivot': [56, 76], 'sole_row': 75,
        'facing': 'right_3_4', 'bbox_exclusive': list(bbox),
        'opaque_pixels': sum(p[3] == 255 for p in pixels),
        'opaque_colors': len({p for p in pixels if p[3]}),
        'source_reference_filenames': ['Modify_woman_upper_arms_skin_580f0e04.jpg', 'image.png_cbe4f7e4.jpg'],
        'generator': Path(__file__).name, 'palette_file': 'palette_sol.json',
        'palette_note': 'Appearance-spike candidate, not a canonical palette amendment.',
        'layers': list(layers), 'native_source': 'pandora_idle_base.aseprite',
        'note': 'Human look approval required before sheet production or runtime integration.'
    }
    (OUT / 'metadata.json').write_text(json.dumps(metadata, indent=2) + '\n')
    print('SOL BASE CHECK:', json.dumps(metadata))


def proof(image):
    """Show full 1x/4x art on two backgrounds; assert proof bounds before paste."""
    dark, light = '#171C25', '#DAD6CA'
    sheet = Image.new('RGB', (952, 472), '#55565A')
    draw = ImageDraw.Draw(sheet)
    for x, bg, label in [(16, dark, 'Native / dark'), (144, light, 'Native / light')]:
        draw.text((x, 8), label, fill='white')
        sheet.paste(bg, (x, 24, x + 112, 104))
        sheet.paste(image, (x, 24), image)
    draw.text((272, 8), 'Native / grayscale', fill='white')
    grey = ImageOps.grayscale(image).convert('RGBA')
    grey.putalpha(image.getchannel('A'))
    sheet.paste(dark, (272, 24, 384, 104))
    sheet.paste(grey, (272, 24), grey)
    enlarged = image.resize((448, 320), Image.Resampling.NEAREST)
    for x, bg, label in [(16, dark, '4x nearest / dark'), (488, light, '4x nearest / light')]:
        y = 136
        assert x + enlarged.width <= sheet.width and y + enlarged.height <= sheet.height
        draw.text((x, 116), label, fill='white')
        sheet.paste(bg, (x, y, x + 448, y + 320))
        sheet.paste(enlarged, (x, y), enlarged)
    sheet.save(OUT / 'proof_pandora_idle_base.png')


def write_aseprite(layers, palette):
    """Serialize a one-frame RGBA Aseprite source with lossless editable layers."""
    def chunk(kind, data):
        return struct.pack('<IH', len(data) + 6, kind) + data

    chunks = []
    for name in layers:
        encoded = name.encode('utf-8')
        body = struct.pack('<6HB3xH', 1, 0, 0, 0, 0, 0, 255, len(encoded)) + encoded
        chunks.append(chunk(0x2004, body))
    for index, part in enumerate(layers.values()):
        body = struct.pack('<HhhBHh5xHH', index, 0, 0, 255, 2, 0, *SIZE)
        chunks.append(chunk(0x2005, body + zlib.compress(part.tobytes())))
    colors = list(dict.fromkeys(palette.values()))
    entries = b''.join(struct.pack('<H4B', 0, *bytes.fromhex(c.lstrip('#')), 255) for c in colors)
    chunks.append(chunk(0x2019, struct.pack('<III8x', len(colors), 0, len(colors) - 1) + entries))
    data = b''.join(chunks)
    frame = struct.pack('<IHHH2xI', len(data) + 16, 0xF1FA, len(chunks), 100, len(chunks)) + data
    header = bytearray(128)
    struct.pack_into('<I5HIH', header, 0, len(frame) + 128, 0xA5E0, 1, *SIZE, 32, 1, 100)
    struct.pack_into('<HBB', header, 32, len(colors), 1, 1)
    (OUT / 'pandora_idle_base.aseprite').write_bytes(bytes(header) + frame)


if __name__ == '__main__':
    build()
