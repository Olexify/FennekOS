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
<linearGradient id="fadeX" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000"/><stop offset=".2" stop-color="#fff"/><stop offset=".85" stop-color="#fff"/><stop offset="1" stop-color="#333"/></linearGradient>
<mask id="edgeFade" maskUnits="userSpaceOnUse" x="0" y="0" width="3840" height="2160"><rect width="3840" height="2160" fill="url(#fadeX)"/></mask>
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
<g mask="url(#edgeFade)">{silk(110, 1100, 520, 300, 4.2, .6, 1.4, "gold", 2.2, .95, 1)}
{silk(70, 1380, 300, 220, 3.4, 2.2, 2.0, "gold2", 1.6, .6, 2)}</g>
{bokeh(40, 7, ["#ffd98c", "#e0a84a"], 300, 1900, 4, 22)}''')

# Sakura: a kitsune night in Kitsumi's palette: a huge moon over misty mountain layers, a torii on a hill with a fox
# sitting beside it looking up, soft fox-fire lights drifting, sakura petals in the air.
r = random.Random(21)
stars = "".join(f'<circle cx="{r.uniform(0, W):.0f}" cy="{r.uniform(0, H * .62):.0f}" r="{r.choice((1.4, 2, 2.6, 3.2)):.1f}" fill="#f3f5fe" opacity="{r.uniform(.2, .8):.2f}"/>' for _ in range(240))


def hills(y, amp, ph, color, op=1):
    pts = [(x, y + amp * math.sin(x / W * 4.1 + ph) + amp * .5 * math.sin(x / W * 9.7 + ph * 2)) for x in range(-100, W + 101, 80)]
    return f'<path d="M-100 {H} ' + " ".join(f"L{x} {py:.0f}" for x, py in pts) + f' L{W + 100} {H} Z" fill="{color}" opacity="{op}"/>'


FOX = ("M32 96C29 82 31 69 38 60C34 54 34 47 37 42L34 23L43 33C46 32 49 32 52 33L60 20L59 36C64 38 71 37 80 36"
       "C75 43 67 46 59 46C58 52 56 56 53 60C60 68 62 82 60 96Z"
       "M58 94C80 97 97 86 98 69C99 54 88 45 77 48C86 56 87 69 80 78C73 86 63 89 50 91Z")
TORII = ("M-260 -20Q0 -70 260 -20L250 10Q0 -30 -250 10Z"     # kasagi, the curved top beam
         "M-200 40H200V68H-200Z"                              # nuki
         "M-150 -6H-112V420H-150ZM112 -6H150V420H112Z"        # pillars
         "M-16 10H16V40H-16Z")
fires = ""
for _ in range(14):
    x, y, rr = r.uniform(400, W - 300), r.uniform(700, 1700), r.uniform(10, 26)
    c = r.choice(("#9fb4ff", "#b6a8ff", "#8fe0ff"))
    fires += (f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{rr * 4:.0f}" fill="{c}" opacity=".18" filter="url(#glow2)"/>'
              f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{rr:.0f}" fill="{c}" opacity=".55" filter="url(#soft)"/>'
              f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{rr * .4:.0f}" fill="#ffffff" opacity=".85"/>')
petals = "".join(f'<ellipse cx="0" cy="0" rx="{z * 1.7:.0f}" ry="{z:.0f}" fill="{r.choice(("#f2b3c7", "#e79ab4", "#ffd0dd"))}" opacity="{r.uniform(.5, .9):.2f}" '
                 f'transform="translate({r.uniform(0, W):.0f} {r.uniform(200, H - 80):.0f}) rotate({r.uniform(-70, 70):.0f})"/>'
                 for z in [r.uniform(7, 18) for _ in range(60)])
sakura = svg('''<linearGradient id="sbg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0b0f2c"/><stop offset=".5" stop-color="#1b2258"/><stop offset=".78" stop-color="#4a3a7c"/><stop offset="1" stop-color="#2a2152"/></linearGradient>
<radialGradient id="moon" cx=".45" cy=".4" r=".6"><stop offset="0" stop-color="#fffaf3"/><stop offset=".75" stop-color="#ffe6d6"/><stop offset="1" stop-color="#f6cfc6"/></radialGradient>''',
             f'''<rect width="{W}" height="{H}" fill="url(#sbg)"/>{stars}
<circle cx="2380" cy="860" r="900" fill="#ffd9c8" opacity=".14" filter="url(#glow)"/>
<circle cx="2380" cy="860" r="430" fill="url(#moon)"/>
<circle cx="2240" cy="780" r="60" fill="#f1d3cb" opacity=".16" filter="url(#soft)"/><circle cx="2520" cy="980" r="90" fill="#f1d3cb" opacity=".12" filter="url(#soft)"/>
{hills(1300, 120, .4, "#2f2a66", .85)}
<rect y="1180" width="{W}" height="320" fill="#b9a8ff" opacity=".10" filter="url(#glow2)"/>
{hills(1480, 110, 2.0, "#231e52")}
{hills(1640, 90, 4.2, "#18153c")}
<g transform="translate(1180 1260)" fill="#120e2c">{"" }<path d="{TORII}"/></g>
<g transform="translate(1440 1286) scale(4.2)" fill="#120e2c"><path d="{FOX}"/></g>
<path d="M600 {H}C900 1700 1500 1640 2100 1700S3300 1900 3840 1820V{H}Z" fill="#0e0b22"/>
{fires}{petals}''')

# Royal: violet velvet, gold and violet silk crossing, fine glinting dust.
royal = svg('''<radialGradient id="rbg" cx=".55" cy=".45" r=".85"><stop offset="0" stop-color="#2c1a4a"/><stop offset=".6" stop-color="#170f2a"/><stop offset="1" stop-color="#0b0716"/></radialGradient>
<linearGradient id="rg" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#d9a441" stop-opacity="0"/><stop offset=".35" stop-color="#f4cf7e"/><stop offset=".7" stop-color="#d9a441"/><stop offset="1" stop-color="#d9a441" stop-opacity="0"/></linearGradient>
<linearGradient id="rv" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8f6bff" stop-opacity="0"/><stop offset=".4" stop-color="#b79cff"/><stop offset="1" stop-color="#6c4bd8" stop-opacity=".1"/></linearGradient>''',
            f'''<rect width="{W}" height="{H}" fill="url(#rbg)"/>
<ellipse cx="2100" cy="1000" rx="1400" ry="800" fill="#7d55d9" opacity=".22" filter="url(#glow)"/>
<ellipse cx="2600" cy="1300" rx="800" ry="400" fill="#d9a441" opacity=".12" filter="url(#glow)"/>
<g mask="url(#edgeFade)">{silk(100, 900, 460, 320, 3.6, 1.1, 1.8, "rv", 2.0, .8, 5)}
{silk(80, 1250, 340, 280, 4.6, 3.0, 1.2, "rg", 1.8, .8, 6)}</g>
{bokeh(70, 9, ["#f4cf7e", "#b79cff", "#ffffff"], 100, 2000, 3, 14)}''')

# Arcade: a synthwave horizon: striped glowing sun, neon perspective grid, violet and orange.
hy = 1260
grid = ""
for i in range(-28, 29):
    grid += f'<line x1="{W / 2 + i * 70:.0f}" y1="{hy}" x2="{W / 2 + i * 640:.0f}" y2="{H}" stroke="#a970ff" stroke-width="3" opacity=".55"/>'
for k in range(1, 18):
    y = hy + (H - hy) * (k / 17) ** 2.2
    grid += f'<line x1="0" y1="{y:.0f}" x2="{W}" y2="{y:.0f}" stroke="#ff8a4c" stroke-width="{2 + k * .25:.1f}" opacity="{.25 + k * .03:.2f}"/>'
def ridge(xs, seed, top):
    """A neon-edged mountain range along the horizon (left or right of the sun)."""
    r = random.Random(seed)
    pts, x = [], xs[0] + 140
    while x < xs[1] - 260:
        pts.append((x, hy - r.uniform(top * .35, top)))
        x += r.uniform(120, 260)
    # the range rises from the horizon and settles back into it (no cliffs beside the sun)
    pts = [(xs[0], hy - (0 if xs[0] > 0 else r.uniform(top * .3, top * .6)))] + pts + [(xs[1], hy - (0 if xs[1] < W else top * .4))]
    d = f"M{xs[0]} {hy} " + " ".join(f"L{px:.0f} {py:.0f}" for px, py in pts) + f" L{xs[1]} {hy} Z"
    edge = "M" + " L".join(f"{px:.0f} {py:.0f}" for px, py in pts)
    return (f'<path d="{d}" fill="#170c2a"/><path d="{edge}" fill="none" stroke="#c18cff" stroke-width="5" opacity=".7" filter="url(#soft)"/>'
            f'<path d="{edge}" fill="none" stroke="#e7d2ff" stroke-width="2"/>')


mountains = ridge((-60, 1240), 4, 420) + ridge((2600, 3900), 8, 460)


# Neon chess cast, drawn here as neon signs: a pawn, a knight with one big googly eye, a rook. Each is one bright
# tube line in a coloured glow, a dark body behind it, googly eyes on top. 45-unit box, standing on y=40.
PAWN = ("M22.5 5.5a6 6 0 1 1 0 12a6 6 0 1 1 0-12z"
        "M15.6 20.4h13.8"
        "M18.4 20.6c.4 6.4-2.8 10.4-5.8 14.2h19.8c-3-3.8-6.2-7.8-5.8-14.2"
        "M10.4 34.8h24.2a2.6 2.6 0 0 1 2.6 2.6a2.6 2.6 0 0 1-2.6 2.6H10.4a2.6 2.6 0 0 1-2.6-2.6a2.6 2.6 0 0 1 2.6-2.6z")
KNIGHT = ("M14 35C14 27 17 23 21 20C17 21 13 21 11 18L13 13C15 9 19 6 24 5L25 1.5L28.6 4.6C34 6.6 37 12 37 18V35"
          "M9.6 35h25.8a2.4 2.4 0 0 1 2.4 2.4a2.4 2.4 0 0 1-2.4 2.4H9.6a2.4 2.4 0 0 1-2.4-2.4a2.4 2.4 0 0 1 2.4-2.4z"
          "M26 9.4c3.4 2.6 5.4 6.8 5.4 12.2")
ROOKN = ("M11.6 6.4h4.4v3.6h3.8V6.4h5.4v3.6h3.8V6.4h4.4v8.4l-2.8 2.6H14.4l-2.8-2.6z"
         "M15 17.4l-1.6 17.4h18.2L30 17.4"
         "M10 34.8h25a2.6 2.6 0 0 1 2.6 2.6a2.6 2.6 0 0 1-2.6 2.6H10a2.6 2.6 0 0 1-2.6-2.6a2.6 2.6 0 0 1 2.6-2.6z")


def googly(cx, cy, rr, dx, dy, col):
    return (f'<circle cx="{cx}" cy="{cy}" r="{rr}" fill="#fffaf2" stroke="{col}" stroke-width=".5"/>'
            f'<circle cx="{cx + dx:.2f}" cy="{cy + dy:.2f}" r="{rr * .48:.2f}" fill="#140a22"/>'
            f'<circle cx="{cx + dx - rr * .18:.2f}" cy="{cy + dy - rr * .2:.2f}" r="{rr * .13:.2f}" fill="#fff"/>')


def sign(path, x, y, sc, col, eyes, tilt=0):
    tx, ty = x - 22.5 * sc, y - 40 * sc
    g = f'transform="translate({tx:.0f} {ty:.0f}) scale({sc}) rotate({tilt} 22.5 40)" stroke-linecap="round" stroke-linejoin="round"'
    return (f'<ellipse cx="{x}" cy="{y + 6}" rx="{18 * sc:.0f}" ry="{2.8 * sc:.0f}" fill="{col}" opacity=".32" filter="url(#glow2)"/>'
            f'<path d="{path}" {g} fill="#120a20" fill-opacity=".88" stroke="none"/>'
            f'<path d="{path}" {g} fill="none" stroke="{col}" stroke-width="3.8" opacity=".5" filter="url(#ng1)"/>'
            f'<path d="{path}" {g} fill="none" stroke="{col}" stroke-width="1.9" opacity=".9" filter="url(#ng2)"/>'
            f'<path d="{path}" {g} fill="none" stroke="#fff6fd" stroke-width=".8"/>'
            f'<g {g}>' + "".join(googly(*e, col) for e in eyes) + '</g>')


cast = (sign(KNIGHT, 980, 1930, 13, "#ff4fd0", [(19.5, 13.2, 3.4, 1.3, .9)], -4)
        + sign(PAWN, 1920, 1560, 7.2, "#56e1ff", [(20.4, 11.6, 2.1, .7, -.6), (24.6, 11.6, 2.1, -.5, .8)])
        + sign(ROOKN, 2860, 1930, 13, "#ffc94d", [(19.6, 25.6, 2.7, -1.0, .6), (25.4, 25.6, 2.7, .9, -.7)], 4))
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

for name, s in (("amber", amber), ("sakura", sakura), ("royal", royal), ("arcade", arcade_base("")),
                ("arcade-chess", arcade_base(cast))):
    open(f"{out}/theme-{name}.svg", "w", encoding="utf-8", newline="\n").write(s)
print("theme wallpapers ok")
