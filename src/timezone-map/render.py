#!/usr/bin/python3
"""Background map for the time zone picker (setup wizard, Date & Time): the world's countries as Ukraine sees them,
so Crimea is Ukraine. Draws the same tiles KDE ships (zoom 0-4, 256 px, web map projection) from Natural Earth's
Ukraine-view country borders (public domain).

    render.py COUNTRIES.geojson OUTDIR
"""
import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

WATER, LAND, BORDER = (207, 220, 236), (246, 242, 235), (170, 158, 190)
TILE, ZOOMS, SCALE = 256, range(5), 2   # drawn twice as large, then smoothed down


def project(lon, lat, size):
    lat = max(-85.0511, min(85.0511, lat))
    y = math.log(math.tan(math.pi / 4 + math.radians(lat) / 2))
    return (lon + 180) / 360 * size, (1 - y / math.pi) / 2 * size


def rings(features):
    for f in features:
        g = f["geometry"]
        for poly in g["coordinates"] if g["type"] == "MultiPolygon" else [g["coordinates"]]:
            yield poly


def draw(polys, z):
    size = TILE * 2 ** z * SCALE
    img = Image.new("RGB", (size, size), WATER)
    d = ImageDraw.Draw(img)
    for poly in polys:
        pts = [[project(lon, lat, size) for lon, lat, *_ in ring] for ring in poly]
        d.polygon(pts[0], fill=LAND)
        for hole in pts[1:]:
            d.polygon(hole, fill=WATER)
        for ring in pts:
            d.line(ring + ring[:1], fill=BORDER, width=SCALE)
    return img.resize((size // SCALE, size // SCALE), Image.LANCZOS)


def main(src, out):
    polys = list(rings(json.load(open(src, encoding="utf-8"))["features"]))
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    for z in ZOOMS:
        world = draw(polys, z)
        for x in range(2 ** z):
            for y in range(2 ** z):
                # The name the map's offline tile reader looks for: osm_100-l-1-ZOOM-X-Y.png
                world.crop((x * TILE, y * TILE, (x + 1) * TILE, (y + 1) * TILE)).save(out / f"osm_100-l-1-{z}-{x}-{y}.png", optimize=True)
    print(sum(4 ** z for z in ZOOMS), "map tiles in", out)


if __name__ == "__main__":
    main(*sys.argv[1:])
