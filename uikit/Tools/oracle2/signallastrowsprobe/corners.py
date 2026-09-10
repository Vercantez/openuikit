#!/usr/bin/env python3
"""Reduce the corner-grid screenshots to per-corner radius estimates.

Usage: corners.py <probe output dir> [out.json]

For every case in signal-last-rows.json `corners.cases` (phase corners1) and
`corners.after` (phase corners2) the red view's bounding box is cut out of
the render-server PNG. For each of its four corners the white "missing" area
A (sum of green/255 over the corner square, side min(w,h)/2) is converted to
an equivalent radius with the area constant measured from the control views:
circular  A = (1 - pi/4) r^2 = 0.2146 r^2
continuous: k measured from control.radius{8,12,20}.continuous.
Also records the max channel difference between each configured view and the
same-size control views, which is what decides the port's mapping.
"""
import json
import math
import struct
import sys
import zlib


def read_png(path):
    data = open(path, 'rb').read()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    pos = 8
    idat = b''
    width = height = None
    while pos < len(data):
        length = struct.unpack('>I', data[pos:pos + 4])[0]
        ctype = data[pos + 4:pos + 8]
        chunk = data[pos + 8:pos + 8 + length]
        if ctype == b'IHDR':
            width, height, depth, ctype_, _, _, _ = struct.unpack('>IIBBBBB', chunk)
            assert depth == 8 and ctype_ in (2, 6), (depth, ctype_)
            channels = 3 if ctype_ == 2 else 4
        elif ctype == b'IDAT':
            idat += chunk
        elif ctype == b'IEND':
            break
        pos += 12 + length
    raw = zlib.decompress(idat)
    stride = width * channels
    rows = []
    prev = bytearray(stride)
    i = 0
    for _ in range(height):
        f = raw[i]
        i += 1
        line = bytearray(raw[i:i + stride])
        i += stride
        if f == 1:
            for x in range(channels, stride):
                line[x] = (line[x] + line[x - channels]) & 255
        elif f == 2:
            for x in range(stride):
                line[x] = (line[x] + prev[x]) & 255
        elif f == 3:
            for x in range(stride):
                a = line[x - channels] if x >= channels else 0
                line[x] = (line[x] + ((a + prev[x]) >> 1)) & 255
        elif f == 4:
            for x in range(stride):
                a = line[x - channels] if x >= channels else 0
                b = prev[x]
                c = prev[x - channels] if x >= channels else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[x] = (line[x] + pr) & 255
        rows.append(bytes(line))
        prev = line
    return width, height, channels, rows


def corner_area(rows, channels, x0, y0, w, h, corner, side):
    """Sum of green/255 (whiteness on a red view) over one corner square."""
    total = 0.0
    for dy in range(side):
        y = y0 + dy if corner[0] == 't' else y0 + h - 1 - dy
        row = rows[y]
        for dx in range(side):
            x = x0 + dx if corner[1] == 'l' else x0 + w - 1 - dx
            total += row[x * channels + 1] / 255.0
    return total


def top_row_profile(rows, channels, x0, y0, w, h, corner, n):
    """Whiteness along the edge row/column of one corner (first n px)."""
    y = y0 if corner[0] == 't' else y0 + h - 1
    out = []
    for dx in range(n):
        x = x0 + dx if corner[1] == 'l' else x0 + w - 1 - dx
        out.append(round(rows[y][x * channels + 1] / 255.0, 3))
    return out


def bbox_diff(rows, channels, a, b):
    """Max abs channel difference between two same-size boxes (x, y, w, h px)."""
    ax, ay, w, h = a
    bx, by, w2, h2 = b
    assert (w, h) == (w2, h2)
    worst = 0
    count = 0
    for dy in range(h):
        ra, rb = rows[ay + dy], rows[by + dy]
        for dx in range(w):
            for c in range(3):
                d = abs(ra[(ax + dx) * channels + c] - rb[(bx + dx) * channels + c])
                if d > worst:
                    worst = d
                if d > 8:
                    count += 1
    return {'maxAbs': worst, 'pixelsOver8': count}


def main():
    out_dir = sys.argv[1]
    dest = sys.argv[2] if len(sys.argv) > 2 else None
    probe = json.load(open(out_dir + '/signal-last-rows.json'))
    scale = int(probe['corners']['scale'])
    result = {'scale': scale}
    for phase, key in (('corners1', 'cases'), ('corners2', 'after')):
        width, height, channels, rows = read_png(f'{out_dir}/screen-{phase}.png')
        cases = probe['corners'][key]
        boxes = {}
        for name, c in cases.items():
            fx, fy, fw, fh = c['frame']
            boxes[name] = (int(fx * scale), int(fy * scale), int(fw * scale), int(fh * scale))
        table = {}
        for name, (x0, y0, w, h) in boxes.items():
            side = min(w, h) // 2
            entry = {'box': [x0, y0, w, h]}
            for corner in ('tl', 'tr', 'bl', 'br'):
                a = corner_area(rows, channels, x0, y0, w, h, corner, side)
                entry[corner] = {
                    'area': round(a, 2),
                    'rCircular': round(math.sqrt(a / (1 - math.pi / 4)) / scale, 3),
                    'edgeProfile': top_row_profile(rows, channels, x0, y0, w, h, corner, min(side, 20 * scale)),
                }
            table[name] = entry
        # Continuous-curve area constant from the controls.
        ks = {}
        for name, e in table.items():
            if name.startswith('control.') and 'continuous' in name:
                r = float(name.split('radius')[1].split('.')[0]) * scale
                ks[name] = round(sum(e[c]['area'] for c in ('tl', 'tr', 'bl', 'br')) / 4 / (r * r), 5)
        if ks:
            k = sum(ks.values()) / len(ks)
            for e in table.values():
                for corner in ('tl', 'tr', 'bl', 'br'):
                    e[corner]['rContinuous'] = round(math.sqrt(e[corner]['area'] / k) / scale, 3)
        diffs = {}
        for a, b in (('uniform.fixed8.100x40', 'control.radius8.continuous.100x40'),
                     ('uniform.fixed8.100x40', 'control.radius8.circular.100x40'),
                     ('control.radius8.continuous.100x40', 'control.radius8.circular.100x40'),
                     ('corners.fixed12.60x60', 'control.radius12.continuous.60x60'),
                     ('corners.fixed12.60x60', 'control.radius12.circular.60x60'),
                     ('capsule.100x40', 'control.radius20.continuous.100x40'),
                     ('capsule.100x40', 'control.radius20.circular.100x40'),
                     ('uniform.fixed40.100x40.oversized', 'control.radius20.continuous.100x40'),
                     ('uniform.fixed40.100x40.oversized', 'control.radius40.circular.100x40'),
                     ('uniform.fixed8.thenLayer2.100x40', 'control.radius8.continuous.100x40'),
                     ('uniform.fixed8.thenLayer2.100x40', 'uniform.fixed8.100x40')):
            if a in boxes and b in boxes:
                diffs[a + ' vs ' + b] = bbox_diff(rows, channels, boxes[a], boxes[b])
        result[phase] = {'kContinuous': ks, 'cases': table, 'diffs': diffs}
    text = json.dumps(result, indent=1, sort_keys=True)
    if dest:
        open(dest, 'w').write(text + '\n')
    summary = {}
    for phase in ('corners1', 'corners2'):
        for name, e in result[phase]['cases'].items():
            summary[phase + ':' + name] = {c: (e[c]['rCircular'], e[c].get('rContinuous')) for c in ('tl', 'tr', 'bl', 'br')}
    print(json.dumps({'k': result['corners1']['kContinuous'], 'diffs': result['corners1']['diffs'], 'radii': summary}, indent=1, sort_keys=True))


if __name__ == '__main__':
    main()
