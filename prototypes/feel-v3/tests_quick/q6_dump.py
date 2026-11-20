# Q6 helper: dump every non-wall glyph in a room with its row and columns,
# so platform moves keep every marker, door, enemy and edge exactly where it was.
import sys, os
for rid in sys.argv[1:]:
    lines = open(os.path.join('rooms', rid + '.txt'), encoding='utf-8').read().split('\n')
    print('== %s header: %s' % (rid, lines[0]))
    g = [l for l in lines[1:] if l.strip()]
    for y, row in enumerate(g):
        runs = []
        x = 0
        while x < len(row):
            ch = row[x]
            if ch in '.#':
                x += 1; continue
            start = x
            while x < len(row) and row[x] == ch: x += 1
            runs.append('%s:%d-%d' % (ch, start, x - 1))
        print('  row %2d: %s' % (y, '  '.join(runs) if runs else '-'))
