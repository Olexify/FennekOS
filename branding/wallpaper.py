# Fennek OS signature wallpaper: the desert at dusk under a crescent moon. Painted in layers: a night sky warming
# to gold at the horizon, stars and a few glints, the moon with its halo, dunes lit on their crests by the last light
# here and there, mist in the hollows, a soft vignette and fine grain. Writes an SVG; the image build renders it to the 4K PNG wallpaper (and a darker night version).
#   python branding/wallpaper.py system_files/usr/share/fennek/wallpaper.svg
import math, random, sys

W, H = 3840, 2160
r = random.Random(7)   # the same sky every build


def glint(x, y, s, op):
    p = (f"M0 {-s}C{s * .12} {-s * .12} {s * .12} {-s * .12} {s} 0C{s * .12} {s * .12} {s * .12} {s * .12} 0 {s}"
         f"C{-s * .12} {s * .12} {-s * .12} {s * .12} {-s} 0C{-s * .12} {-s * .12} {-s * .12} {-s * .12} 0 {-s}Z")
    return (f'<g transform="translate({x:.0f} {y:.0f})" opacity="{op:.2f}"><circle r="{s * .9:.0f}" fill="#fff4e0" opacity=".3" filter="url(#b2)"/>'
            f'<path d="{p}" fill="#fff6e8"/></g>')


stars = "".join(f'<circle cx="{r.uniform(0, W):.0f}" cy="{r.uniform(0, H * .5):.0f}" r="{r.choice((1.2, 1.6, 2.2, 2.8)):.1f}" '
                f'fill="#fff" opacity="{r.uniform(.25, .85):.2f}"/>' for _ in range(320))
glints = "".join(glint(r.uniform(0, W), r.uniform(0, H * .38), r.uniform(10, 18), r.uniform(.5, .9)) for _ in range(9))


def dune(y, amp, ph, top, bottom, rim, rim_op, wob=3.2):
    """A dune band: lit crest (rim light), body shading down into shadow."""
    pts = [(x, y + amp * math.sin(x / W * wob + ph) + amp * .45 * math.sin(x / W * 7.3 + ph * 2)) for x in range(-160, W + 161, 80)]
    d = f"M-160 {H} " + " ".join(f"L{x} {py:.0f}" for x, py in pts) + f" L{W + 160} {H} Z"
    crest = "M" + " L".join(f"{x} {py:.0f}" for x, py in pts)
    gid = f"d{int(y)}"
    # the last light catches the crest here and there, fading in between
    rr = random.Random(int(y))
    stops = "".join(f'<stop offset="{o:.2f}" stop-color="{rim}" stop-opacity="{a:.2f}"/>'
                    for o, a in [(0, 0)] + sorted((rr.uniform(.05, .95), rr.choice((.15, .9, 1, .3))) for _ in range(6)) + [(1, 0)])
    return (f'<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset=".35" stop-color="{bottom}"/></linearGradient>'
            f'<linearGradient id="r{gid}" x1="0" y1="0" x2="1" y2="0">{stops}</linearGradient>'
            f'<path d="{d}" fill="url(#{gid})"/>'
            f'<path d="{crest}" fill="none" stroke="url(#r{gid})" stroke-width="12" opacity="{rim_op * .45:.2f}" filter="url(#b1)"/>'
            f'<path d="{crest}" fill="none" stroke="url(#r{gid})" stroke-width="2.4" opacity="{rim_op:.2f}"/>'), pts


def mist(y, h, op, c="#ffc3a0"):
    return f'<rect x="-200" y="{y}" width="{W + 400}" height="{h}" fill="{c}" opacity="{op}" filter="url(#glow2)"/>'


d1, _ = dune(1290, 70, .6, "#e8996a", "#9a536b", "#ffd7a0", .9)
d2, _ = dune(1470, 90, 2.3, "#b45f6c", "#55305d", "#ffc890", .85)
d3, _ = dune(1680, 90, 4.1, "#6b3667", "#2a1840", "#ffb57a", .8)
d4, _ = dune(1880, 70, 1.4, "#3a2150", "#120a20", "#f0a868", .9, 2.4)
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
<defs>
  <filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="170"/></filter>
  <filter id="glow2" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="60"/></filter>
  <filter id="b1" x="-20%" y="-50%" width="140%" height="200%"><feGaussianBlur stdDeviation="5"/></filter>
  <filter id="b2" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="14"/></filter>
  <filter id="b3" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="30"/></filter>
  <filter id="grain"><feTurbulence type="fractalNoise" baseFrequency="1.15" numOctaves="2" seed="5"/><feColorMatrix values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 .035 0"/></filter>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#0b0820"/><stop offset=".28" stop-color="#1f1546"/><stop offset=".46" stop-color="#4b2a6a"/>
    <stop offset=".56" stop-color="#9c4f6c"/><stop offset=".62" stop-color="#e2865c"/><stop offset=".66" stop-color="#ffbe78"/>
  </linearGradient>
  <radialGradient id="moon" cx=".4" cy=".35" r=".7"><stop offset="0" stop-color="#fff8ea"/><stop offset="1" stop-color="#f6dcb4"/></radialGradient>
  <mask id="crescent"><rect width="{W}" height="{H}" fill="#fff"/><circle cx="3060" cy="400" r="150" fill="#000"/></mask>
  <radialGradient id="vig" cx=".5" cy=".5" r=".75"><stop offset=".55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".5"/></radialGradient>
</defs>
<rect width="{W}" height="{H}" fill="url(#sky)"/>
{stars}{glints}
<ellipse cx="{W / 2}" cy="1320" rx="2600" ry="420" fill="#ffb56e" opacity=".42" filter="url(#glow)"/>
<ellipse cx="1500" cy="1300" rx="900" ry="200" fill="#ffd9a0" opacity=".25" filter="url(#glow2)"/>
<circle cx="3000" cy="440" r="420" fill="#ffe7c0" opacity=".14" filter="url(#glow)"/>
<circle cx="3000" cy="440" r="220" fill="#fff0d6" opacity=".12" filter="url(#glow2)"/>
<circle cx="3000" cy="440" r="160" fill="url(#moon)" mask="url(#crescent)"/>
{d1}
{mist(1330, 160, .12)}
{d2}
{mist(1540, 140, .10, "#d9a0c0")}
{d3}
{mist(1740, 120, .08, "#c28ad0")}
{d4}
<rect width="{W}" height="{H}" fill="url(#vig)"/>
<rect width="{W}" height="{H}" filter="url(#grain)"/>
</svg>
'''
open(sys.argv[1], "w", newline="\n").write(svg)
print("ok", len(svg))
