# Wallpapers for the Fennek OS colour themes (Settings > Themes): Amber, Sakura, Royal, Arcade. Pure art, no text:
# each only borrows a palette (Leonote's gold, Kitsumi's night, Olexify's violet and gold, Rook Paper Scissors' neon).
# Writes SVGs; the image build renders them to 4K PNG wallpapers.
#   python branding/theme-wallpapers.py system_files/usr/share/fennek
import math, random, sys

W, H = 3840, 2160
out = sys.argv[1]
FX = '''<filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="160"/></filter>
<filter id="glow2" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="60"/></filter>
<filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="8"/></filter>
<filter id="ng1" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="2.4"/></filter>
<filter id="ng2" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation=".7"/></filter>
<filter id="grain"><feTurbulence type="fractalNoise" baseFrequency=".9" numOctaves="2" seed="3"/><feColorMatrix values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 .045 0"/></filter>'''


def svg(defs, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><defs>{FX}{defs}</defs>'
            f'{body}<rect width="{W}" height="{H}" filter="url(#grain)"/></svg>\n')


def silk(n, y0, spread, amp, freq, phase, drift, grad, width, op, seed):
    """A silk ribbon: many fine strands following one smooth flow, slightly apart; together they shimmer."""
    r = random.Random(seed)
    out = ""
    for i in range(n):
        t = i / (n - 1)
        pts = []
        for x in range(-300, W + 301, 60):
            u = x / W
            y = (y0 + spread * (t - .5) * (1 + .8 * math.sin(u * 3.1 + phase))
                 + amp * math.sin(u * freq + phase + t * drift) + amp * .35 * math.sin(u * freq * 2.3 + phase * 1.7 + t))
            pts.append((x, y))
        d = f"M{pts[0][0]} {pts[0][1]:.1f}" + "".join(
            f" Q{pts[k][0]} {pts[k][1]:.1f} {(pts[k][0] + pts[k + 1][0]) / 2:.0f} {(pts[k][1] + pts[k + 1][1]) / 2:.1f}"
            for k in range(1, len(pts) - 1))
        o = op * (.35 + .65 * math.sin(math.pi * t)) * r.uniform(.7, 1.15)
        out += f'<path d="{d}" fill="none" stroke="url(#{grad})" stroke-width="{width}" opacity="{o:.3f}"/>'
    return out


def bokeh(n, seed, colors, ymin=0, ymax=H, rmin=6, rmax=40):
    r = random.Random(seed)
    return "".join(f'<circle cx="{r.uniform(0, W):.0f}" cy="{r.uniform(ymin, ymax):.0f}" r="{r.uniform(rmin, rmax):.0f}" '
                   f'fill="{r.choice(colors)}" opacity="{r.uniform(.08, .35):.2f}"/>' for _ in range(n))


# Amber: charcoal night, golden silk drifting across, warm light behind it.
amber = svg('''<linearGradient id="abg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#0d0c0f"/><stop offset=".6" stop-color="#141114"/><stop offset="1" stop-color="#1d150c"/></linearGradient>
<linearGradient id="gold" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7a4b12" stop-opacity="0"/><stop offset=".25" stop-color="#e0a84a"/><stop offset=".6" stop-color="#ffd98c"/><stop offset="1" stop-color="#b9792a" stop-opacity=".2"/></linearGradient>
<linearGradient id="gold2" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#e0a84a" stop-opacity=".1"/><stop offset=".5" stop-color="#f6c66e"/><stop offset="1" stop-color="#e0a84a" stop-opacity="0"/></linearGradient>''',
            f'''<rect width="{W}" height="{H}" fill="url(#abg)"/>
<ellipse cx="2400" cy="1150" rx="1600" ry="700" fill="#e0a84a" opacity=".26" filter="url(#glow)"/>
<ellipse cx="900" cy="1500" rx="900" ry="400" fill="#b05a1a" opacity=".12" filter="url(#glow)"/>
{silk(110, 1100, 520, 300, 4.2, .6, 1.4, "gold", 2.2, .95, 1)}
{silk(70, 1380, 300, 220, 3.4, 2.2, 2.0, "gold2", 1.6, .6, 2)}
{bokeh(40, 7, ["#ffd98c", "#e0a84a"], 300, 1900, 4, 22)}''')

# Sakura: deep blue night, a big soft moon, a blossoming branch from the top right, petals drifting down.
r = random.Random(21)
stars = "".join(f'<circle cx="{r.uniform(0, W):.0f}" cy="{r.uniform(0, H * .8):.0f}" r="{r.choice((1.5, 2, 2.6, 3.4)):.1f}" fill="#f3f5fe" opacity="{r.uniform(.2, .8):.2f}"/>' for _ in range(260))


def branch(x, y, ang, length, w, depth):
    if depth == 0 or length < 40:
        return "", [(x, y)]
    ex, ey = x + length * math.cos(ang), y + length * math.sin(ang)
    mx, my = (x + ex) / 2 + 40 * math.sin(ang * 3), (y + ey) / 2 + 30
    s = (f'<path d="M{x:.0f} {y:.0f} Q{mx:.0f} {my:.0f} {ex:.0f} {ey:.0f}" stroke="#2a2042" stroke-width="{w:.0f}" stroke-linecap="round" fill="none"/>'
         f'<path d="M{x:.0f} {y - w * .25:.0f} Q{mx:.0f} {my - w * .25:.0f} {ex:.0f} {ey - w * .25:.0f}" stroke="#5a4a7e" stroke-width="{max(1, w * .18):.0f}" stroke-linecap="round" fill="none" opacity=".55"/>')
    tips = []
    if depth <= 3:   # blossoms along the outer twigs, spaced out
        n = max(1, int(length / 140))
        for k in range(n + 1):
            t = k / n
            tips.append(((1 - t) ** 2 * x + 2 * (1 - t) * t * mx + t * t * ex, (1 - t) ** 2 * y + 2 * (1 - t) * t * my + t * t * ey))
    for da, k in ((r.uniform(-.55, -.2), .72), (r.uniform(.25, .7), .6)):
        ss, tt = branch(ex, ey, ang + da, length * k, w * .62, depth - 1)
        s += ss
        tips += tt
    return s, tips


bs, tips = branch(W + 60, 60, math.radians(158), 820, 40, 6)
flower = lambda x, y, s, c: "".join(
    f'<ellipse cx="0" cy="{-s:.1f}" rx="{s * .62:.1f}" ry="{s:.1f}" fill="{c}" transform="translate({x:.0f} {y:.0f}) rotate({a})"/>'
    for a in range(0, 360, 72)) + f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{s * .28:.1f}" fill="#ffd2a8"/>'
blossoms = ""
for (x, y) in tips:
    for _ in range(r.choice((0, 1, 1, 2))):
        blossoms += flower(x + r.uniform(-55, 55), y + r.uniform(-45, 45), r.uniform(14, 26), r.choice(("#f7c4d4", "#efa6bf", "#ffd9e4", "#e791b0")))
petals = "".join(f'<ellipse cx="0" cy="0" rx="{s * 1.7:.0f}" ry="{s:.0f}" fill="{r.choice(("#f2b3c7", "#e79ab4", "#ffd0dd"))}" opacity="{r.uniform(.5, .9):.2f}" '
                 f'transform="translate({r.uniform(200, W - 100):.0f} {r.uniform(300, H - 80):.0f}) rotate({r.uniform(-70, 70):.0f})"/>'
                 for s in [r.uniform(8, 22) for _ in range(70)])
sakura = svg('''<linearGradient id="sbg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0d1130"/><stop offset=".55" stop-color="#1a2156"/><stop offset="1" stop-color="#3a2a63"/></linearGradient>
<radialGradient id="moon" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#fff6ee"/><stop offset=".7" stop-color="#ffe3d2"/><stop offset="1" stop-color="#f5c9c0"/></radialGradient>''',
             f'''<rect width="{W}" height="{H}" fill="url(#sbg)"/>{stars}
<circle cx="1250" cy="760" r="620" fill="#ffd7c4" opacity=".16" filter="url(#glow)"/>
<circle cx="1250" cy="760" r="300" fill="url(#moon)"/>
<circle cx="1250" cy="760" r="300" fill="#ffffff" opacity=".08" filter="url(#glow2)"/>
<ellipse cx="1900" cy="2160" rx="2600" ry="420" fill="#140f2c" opacity=".9"/>
<ellipse cx="400" cy="2200" rx="1500" ry="380" fill="#100c24"/>
{bs}{blossoms}{petals}''')

# Royal: violet velvet, gold and violet silk crossing, fine glinting dust.
royal = svg('''<radialGradient id="rbg" cx=".55" cy=".45" r=".85"><stop offset="0" stop-color="#2c1a4a"/><stop offset=".6" stop-color="#170f2a"/><stop offset="1" stop-color="#0b0716"/></radialGradient>
<linearGradient id="rg" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#d9a441" stop-opacity="0"/><stop offset=".35" stop-color="#f4cf7e"/><stop offset=".7" stop-color="#d9a441"/><stop offset="1" stop-color="#d9a441" stop-opacity="0"/></linearGradient>
<linearGradient id="rv" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8f6bff" stop-opacity="0"/><stop offset=".4" stop-color="#b79cff"/><stop offset="1" stop-color="#6c4bd8" stop-opacity=".1"/></linearGradient>''',
            f'''<rect width="{W}" height="{H}" fill="url(#rbg)"/>
<ellipse cx="2100" cy="1000" rx="1400" ry="800" fill="#7d55d9" opacity=".22" filter="url(#glow)"/>
<ellipse cx="2600" cy="1300" rx="800" ry="400" fill="#d9a441" opacity=".12" filter="url(#glow)"/>
{silk(100, 900, 460, 320, 3.6, 1.1, 1.8, "rv", 2.0, .8, 5)}
{silk(80, 1250, 340, 280, 4.6, 3.0, 1.2, "rg", 1.8, .8, 6)}
{bokeh(70, 9, ["#f4cf7e", "#b79cff", "#ffffff"], 100, 2000, 3, 14)}''')

# Arcade: a synthwave horizon: striped glowing sun, neon perspective grid, violet and orange.
hy = 1260
grid = ""
for i in range(-28, 29):
    grid += f'<line x1="{W / 2 + i * 70:.0f}" y1="{hy}" x2="{W / 2 + i * 640:.0f}" y2="{H}" stroke="#a970ff" stroke-width="3" opacity=".55"/>'
for k in range(1, 18):
    y = hy + (H - hy) * (k / 17) ** 2.2
    grid += f'<line x1="0" y1="{y:.0f}" x2="{W}" y2="{y:.0f}" stroke="#ff8a4c" stroke-width="{2 + k * .25:.1f}" opacity="{.25 + k * .03:.2f}"/>'
# Googly-eyed pieces from Rook, Paper, Scissors! (branding/arcade-pieces.json), retro neon: dark bodies, glowing
# outlines, standing on the grid at different depths with a soft light under each.
import json, os
PIECES = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "arcade-pieces.json")))
def ridge(xs, seed, top):
    """A neon-edged mountain range along the horizon (left or right of the sun)."""
    r = random.Random(seed)
    pts, x = [], xs[0]
    while x < xs[1]:
        pts.append((x, hy - r.uniform(top * .35, top)))
        x += r.uniform(120, 260)
    pts.append((xs[1], hy - r.uniform(40, 120)))
    d = f"M{xs[0]} {hy} " + " ".join(f"L{px:.0f} {py:.0f}" for px, py in pts) + f" L{xs[1]} {hy} Z"
    edge = "M" + " L".join(f"{px:.0f} {py:.0f}" for px, py in pts)
    return (f'<path d="{d}" fill="#170c2a"/><path d="{edge}" fill="none" stroke="#c18cff" stroke-width="5" opacity=".7" filter="url(#soft)"/>'
            f'<path d="{edge}" fill="none" stroke="#e7d2ff" stroke-width="2"/>')


mountains = ridge((-60, 1240), 4, 420) + ridge((2600, 3900), 8, 460)


# The rook from Rook, Paper, Scissors! (its own shape: crenellated crown, tapered body, rounded base) given googly eyes,
# lit as neon: a dark body, a coloured glow and a bright core line. In a 45-unit box, standing on y=39.
ROOK = ("M10.4 8.8h5.4v3.6h4.2V8.8h4.8v3.6h4.2V8.8h5.6v8.6l-3.2 2.8h-17.8l-3.2-2.8z"
        "M14.2 20.6h16.6l1.2 10.4H13z"
        "M11.4 31.4h22.2c1.6 0 2.9 1.3 2.9 2.9v1.8c0 1.6-1.3 2.9-2.9 2.9H11.4c-1.6 0-2.9-1.3-2.9-2.9v-1.8c0-1.6 1.3-2.9 2.9-2.9z")


def neon(cast):
    out = ""
    for x, y, sc, col, look in cast:
        tx, ty = x - 22.5 * sc, y - 39 * sc
        g = f'transform="translate({tx:.0f} {ty:.0f}) scale({sc})" fill="none" stroke-linecap="round" stroke-linejoin="round"'
        eyes = ""
        for ex, (dx, dy) in ((19.2, look[0]), (25.8, look[1])):
            eyes += (f'<circle cx="{ex}" cy="25.6" r="2.7" fill="#fffaf2" stroke="{col}" stroke-width=".6"/>'
                     f'<circle cx="{ex + dx:.2f}" cy="{25.6 + dy:.2f}" r="1.3" fill="#140a22"/>')
        out += (f'<ellipse cx="{x}" cy="{y + 4}" rx="{19 * sc:.0f}" ry="{3 * sc:.0f}" fill="{col}" opacity=".28" filter="url(#glow2)"/>'
                f'<path d="{ROOK}" {g.replace("fill=\"none\"", "fill=\"#170c28\"")} stroke="none" opacity=".92"/>'
                f'<path d="{ROOK}" {g} stroke="{col}" stroke-width="3.6" opacity=".55" filter="url(#ng1)"/>'
                f'<path d="{ROOK}" {g} stroke="{col}" stroke-width="1.8" opacity=".9" filter="url(#ng2)"/>'
                f'<path d="{ROOK}" {g} stroke="#fff4ff" stroke-width=".75"/>'
                f'<g {g.replace(" fill=\"none\"", "")}>{eyes}</g>')
    return out


def cast_neon(cast):
    out = ""
    for k, x, y, sc, col in cast:
        tx, ty = x - 22.5 * sc, y - 39 * sc
        out += (f'<ellipse cx="{x}" cy="{y + 4}" rx="{17 * sc:.0f}" ry="{3.2 * sc:.0f}" fill="{col}" opacity=".35" filter="url(#glow2)"/>'
                f'<g transform="translate({tx:.0f} {ty:.0f}) scale({sc})" fill="none" stroke="{col}" stroke-width="2.4" opacity=".6" filter="url(#soft)">{PIECES[k]}</g>'
                f'<g transform="translate({tx:.0f} {ty:.0f}) scale({sc})" fill="#1b1030" stroke="{col}" stroke-width="1.1" stroke-linejoin="round">{PIECES[k]}</g>')
    return out


# Arcade: just rooks (the one-eyed rook), a few at different depths. Arcade Crew: the whole googly-eyed cast.
rooks = neon(((1020, 1880, 12.5, "#ff5fd2", ((1.1, .4), (1.2, .7))), (2820, 1880, 12.5, "#4fd8ff", ((-1.2, .6), (-1.0, .3)))))
crew = cast_neon((("o", 520, 1990, 11.5, "#ff7ad9"), ("z", 960, 1660, 8.6, "#58d6ff"), ("u", 1420, 1470, 6.2, "#a970ff"),
             ("S", 2060, 1930, 9.4, "#ffd166"), ("g", 2620, 1560, 7.2, "#58d6ff"), ("d", 3190, 1830, 10.4, "#ff7ad9")))
stripes = "".join(f'<rect x="{W / 2 - 700}" y="{hy - 380 + k * 70 + k * k * 2}" width="1400" height="{6 + k * 3}" fill="#140c24"/>' for k in range(2, 9))
arcade_base = lambda cast: svg('''<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0c0a14"/><stop offset=".55" stop-color="#26123f"/><stop offset="1" stop-color="#4a1d4f"/></linearGradient>
<linearGradient id="sun" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffd166"/><stop offset=".55" stop-color="#ff8a4c"/><stop offset="1" stop-color="#d43f8d"/></linearGradient>
<linearGradient id="floor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1c0f30"/><stop offset="1" stop-color="#0c0a14"/></linearGradient>
<clipPath id="sunclip"><circle cx="1920" cy="880" r="560"/></clipPath>''',
             f'''<rect width="{W}" height="{H}" fill="url(#sky)"/>
{bokeh(160, 3, ["#ffffff", "#c8a8ff"], 0, hy - 200, 1, 3)}
<circle cx="1920" cy="900" r="900" fill="#ff8a4c" opacity=".22" filter="url(#glow)"/>
<g clip-path="url(#sunclip)"><rect x="1300" y="300" width="1300" height="1200" fill="url(#sun)"/>{stripes}</g>
{mountains}
<rect x="0" y="{hy - 160}" width="{W}" height="200" fill="#ff8a4c" opacity=".10" filter="url(#glow2)"/>
<rect x="0" y="{hy}" width="{W}" height="{H - hy}" fill="url(#floor)"/>
<g>{grid}</g>
<rect x="0" y="{hy - 6}" width="{W}" height="12" fill="#ff9ad5" opacity=".75" filter="url(#soft)"/>
<rect x="0" y="{hy - 2}" width="{W}" height="4" fill="#ffd6ef"/>
{cast}''')

for name, s in (("amber", amber), ("sakura", sakura), ("royal", royal), ("arcade", arcade_base(rooks)),
                ("arcade-crew", arcade_base(crew))):
    open(f"{out}/theme-{name}.svg", "w", encoding="utf-8", newline="\n").write(s)
print("theme wallpapers ok")
