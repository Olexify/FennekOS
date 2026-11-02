#!/usr/bin/python3
"""Start's first tile on a screenshot (P6 PPM, 1600x900): an icon has many colours, a blank tile only a few.
  vm-check-start.py START.ppm DESKTOP.ppm
  vm-check-start.py --selftest
"""
import sys

BOX = (410, 163, 530, 283)   # Firefox's tile
MIN_COLOURS = 1000


def read_ppm(path):
    with open(path, "rb") as f:
        data = f.read()
    fields, pos = [], 0
    while len(fields) < 4:
        end = pos
        while data[end] not in b" \t\r\n":
            end += 1
        fields.append(data[pos:end])
        pos = end + 1
    assert fields[0] == b"P6" and fields[3] == b"255", "not an 8-bit P6 file"
    return int(fields[1]), int(fields[2]), data[pos:]


def crop(image, box=BOX):
    w, h, px = image
    x0, y0, x1, y1 = box
    return [px[(y * w + x) * 3:(y * w + x) * 3 + 3] for y in range(y0, y1) for x in range(x0, x1)]


def has_icon(start, desktop):
    tile = crop(start)
    if tile == crop(desktop):
        return False, "Start isn't open"
    n = len(set(tile))
    return n >= MIN_COLOURS, f"{n} colours on the first tile (needs {MIN_COLOURS})"


def selftest():
    w, h = 600, 300
    flat = (w, h, bytes((40, 30, 80)) * (w * h))
    busy = bytearray(flat[2])
    for y in range(170, 270):
        for x in range(420, 520):
            i = (y * w + x) * 3
            busy[i:i + 3] = bytes((x % 256, y % 256, (x * y) % 256))
    assert has_icon((w, h, bytes(busy)), flat)[0]
    assert not has_icon(flat, flat)[0], "same as the desktop: not open"
    other = (w, h, bytes((41, 31, 81)) * (w * h))
    assert not has_icon(other, flat)[0], "blank tile"
    print("selftest ok")


if __name__ == "__main__":
    if sys.argv[1:] == ["--selftest"]:
        sys.exit(selftest())
    ok, why = has_icon(read_ppm(sys.argv[1]), read_ppm(sys.argv[2]))
    print(why)
    sys.exit(not ok)
