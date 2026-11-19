# Q6 applier: rewrites the changed rows of the library and lab room files.
# Every other row is copied byte-for-byte, so markers, doors, enemies and edges
# stay exactly where they were. Run: python tests_quick/q6_apply.py
import os

def row(**runs):
    """Build a row from named runs, left to right. Each key's number is the
    width of the run in cells; the value is the glyph to fill."""
    out = []
    for k, v in runs.items():
        n = int(''.join(c for c in k[1:] if c.isdigit()))
        out.append(v * n)
    return ''.join(out)

d = '.'
H = '#'   # one wall cell

# library-sized rows (48 wide)
L_EMPTY = row(_1=H, _46=d, _1b=H)
L_ITEM  = row(_1=H, _21=d, _1c='1', _24=d, _1b=H)
L_TOP   = row(_1=H, _13=d, _4='=', _1c=d, _7=H, _1b=d, _4b='=', _16=d, _1d=H)
L_SIDES_7  = row(_1=H, _7=d, _4='=', _21=d, _4b='=', _10=d, _1b=H)
L_SIDES_18 = row(_1=H, _7=d, _4='=', _24=d, _4b='=', _7b=d, _1b=H)
L_LEDGE24  = row(_1=H, _10=d, _5='=', _16=d, _5b='=', _10b=d, _1b=H)

# lab-sized rows (72 wide)
B_EMPTY = row(_1=H, _70=d, _1b=H)
B_ROW9  = row(_1=H, _3='=', _8=d, _6='=', _54=d)          # right edge stays open
B_ROW24 = row(_3=d, _4='=', _58=d, _4b='=', _3b=d)        # both edges stay open
S_ROW9  = row(_1=H, _11=d, _6='=', _53=d, _1b=H)          # lab_shift row 9 keeps walls
S_ROW16 = row(_1=H, _38=d, _7='=', _25=d, _1b=H)
S_ROW17 = row(_1=H, _13=d, _7='=', _50=d, _1b=H)
S_ROW23 = row(_14=d, _4='=', _54=d)                        # both edges stay open

CHANGES = {
'library': {
    3:  L_EMPTY,      # item leaves row 3
    4:  L_ITEM,       # ...and lands on the block in row 4
    5:  L_TOP,        # top platform + block, one row down
    6:  L_EMPTY,
    7:  L_SIDES_7,    # side ledges, one row down
    8:  L_EMPTY,      # dead middle perch removed
    17: L_EMPTY,
    18: L_SIDES_18,   # ledges one row down
    23: L_EMPTY,
    24: L_LEDGE24,    # ledges one row down
    32: L_EMPTY,
    33: L_SIDES_18,   # ledges one row down
},
'library_shift': {
    3:  L_EMPTY,
    4:  L_ITEM,
    5:  L_TOP,
    6:  L_EMPTY,
    7:  L_SIDES_7,
    8:  L_EMPTY,
    17: L_EMPTY,
    18: L_SIDES_18,
    23: L_EMPTY,
    24: L_LEDGE24,
    32: L_EMPTY,
    33: L_SIDES_18,
},
'lab': {
    8:  B_EMPTY,      # first ladder step moves down
    9:  B_ROW9,       # ...to row 9 (shaft ledge kept, right edge stays open)
    22: B_EMPTY,      # side perches move down
    24: B_ROW24,      # ...to row 24 (edges stay open)
},
'lab_shift': {
    8:  B_EMPTY,
    9:  S_ROW9,       # ladder step down (walls kept here)
    16: S_ROW16,      # left ledge moves to row 17
    17: S_ROW17,
    22: B_EMPTY,
    23: S_ROW23,      # mid step added (edges stay open)
    24: B_ROW24,
},
}

W = {'library': 48, 'library_shift': 48, 'lab': 72, 'lab_shift': 72}

for rid, changes in CHANGES.items():
    path = os.path.join('rooms', rid + '.txt')
    lines = open(path, encoding='utf-8').read().split('\n')
    idx = [i for i, l in enumerate(lines) if l.strip()]
    grid = idx[1:]
    for row_no, new in sorted(changes.items()):
        li = grid[row_no]
        old = lines[li]
        assert len(new) == W[rid], '%s row %d new width %d' % (rid, row_no, len(new))
        print('%s row %2d' % (rid, row_no))
        print('   old: ' + old)
        print('   new: ' + new)
        lines[li] = new
    open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(lines))
    print('wrote', path)
