# Wallpapers for the Fennek OS colour themes (Settings > Themes): Amber, Sakura, Royal, Arcade. Pure art, no text:
# each only borrows a palette (Leonote's gold, Kitsumi's night, Olexify's violet and gold, Rook Paper Scissors' neon).
# Painted in layers like a photograph: depth (blurred far and near things), light (bloom, rays, glints, halos), mist,
# a soft vignette and fine grain. Writes SVGs; the image build renders them to 4K PNG wallpapers.
#   python branding/theme-wallpapers.py system_files/usr/share/fennek
import math, random, sys

W, H = 3840, 2160
out = sys.argv[1]
FX = f'''<filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="160"/></filter>
<filter id="glow2" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="60"/></filter>
<filter id="soft" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="8"/></filter>
<filter id="b1" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="4"/></filter>
<filter id="b2" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="14"/></filter>
<filter id="b3" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="34"/></filter>
<filter id="depth" x="-10%" y="-30%" width="120%" height="160%"><feGaussianBlur stdDeviation="18"/></filter>
<linearGradient id="fadeX" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#000"/><stop offset=".2" stop-color="#fff"/><stop offset=".85" stop-color="#fff"/><stop offset="1" stop-color="#333"/></linearGradient>
<mask id="edgeFade" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}"><rect width="{W}" height="{H}" fill="url(#fadeX)"/></mask>
<radialGradient id="vig" cx=".5" cy=".5" r=".75"><stop offset=".55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".55"/></radialGradient>
<linearGradient id="ray" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity=".9"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<filter id="grain"><feTurbulence type="fractalNoise" baseFrequency="1.15" numOctaves="2" seed="3"/><feColorMatrix values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 .035 0"/></filter>'''


def svg(defs, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><defs>{FX}{defs}</defs>'
            f'{body}<rect width="{W}" height="{H}" fill="url(#vig)"/><rect width="{W}" height="{H}" filter="url(#grain)"/></svg>\n')


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


def dof(n, seed, colors, area=(0, 0, W, H), rmin=8, rmax=60):
    """Out-of-focus lights: the bigger, the softer (near the lens), each with a faint brighter rim like real bokeh."""
    r = random.Random(seed)
    x0, y0, x1, y1 = area
    out = ""
    for _ in range(n):
        rr = r.uniform(rmin, rmax) ** 1.0
        f = "b1" if rr < 18 else "b2" if rr < 40 else "b3"
        c = r.choice(colors)
        x, y = r.uniform(x0, x1), r.uniform(y0, y1)
        o = r.uniform(.12, .38) * (1.2 if rr < 18 else 1)
        out += (f'<g filter="url(#{f})" opacity="{o:.2f}"><circle cx="{x:.0f}" cy="{y:.0f}" r="{rr:.0f}" fill="{c}"/>'
                f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{rr * .92:.0f}" fill="none" stroke="#fff" stroke-width="{max(1, rr * .06):.1f}" opacity=".35"/></g>')
    return out


def glint(x, y, s, color, op=1):
    """A four-pointed sparkle with a little glow."""
    p = f"M0 {-s}C{s * .12} {-s * .12} {s * .12} {-s * .12} {s} 0C{s * .12} {s * .12} {s * .12} {s * .12} 0 {s}C{-s * .12} {s * .12} {-s * .12} {s * .12} {-s} 0C{-s * .12} {-s * .12} {-s * .12} {-s * .12} 0 {-s}Z"
    return (f'<g transform="translate({x:.0f} {y:.0f})" opacity="{op:.2f}"><circle r="{s * .9:.0f}" fill="{color}" opacity=".35" filter="url(#b2)"/>'
            f'<path d="{p}" fill="{color}"/><circle r="{s * .12:.1f}" fill="#fff"/></g>')


def rays(cx, cy, n, color, length, spread, op, seed):
    """Soft light rays fanning out from a light source."""
    r = random.Random(seed)
    out = ""
    for _ in range(n):
        a = r.uniform(*spread)
        w = r.uniform(.02, .06)
        ln = length * r.uniform(.6, 1)
        x1, y1 = cx + ln * math.cos(a - w), cy + ln * math.sin(a - w)
        x2, y2 = cx + ln * math.cos(a + w), cy + ln * math.sin(a + w)
        out += f'<path d="M{cx} {cy}L{x1:.0f} {y1:.0f}L{x2:.0f} {y2:.0f}Z" fill="{color}" opacity="{r.uniform(.04, .1) * op:.3f}"/>'
    return f'<g filter="url(#b3)">{out}</g>'


# Amber: a dark room and golden silk caught in a warm beam: the beam's rays, a soft-focus ribbon far behind, the
# main ribbon with a bright crest, golden dust near and far.
amber = svg('''<radialGradient id="abg" cx=".7" cy=".42" r=".9"><stop offset="0" stop-color="#2a1d10"/><stop offset=".45" stop-color="#140f0d"/><stop offset="1" stop-color="#08070a"/></radialGradient>
<linearGradient id="gold" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7a4b12" stop-opacity="0"/><stop offset=".25" stop-color="#d9a046"/><stop offset=".62" stop-color="#ffdf9a"/><stop offset="1" stop-color="#b9792a" stop-opacity=".2"/></linearGradient>
<linearGradient id="goldHi" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff2cf" stop-opacity="0"/><stop offset=".45" stop-color="#fff6de"/><stop offset=".75" stop-color="#ffe2a0"/><stop offset="1" stop-color="#ffe2a0" stop-opacity="0"/></linearGradient>
<linearGradient id="gold2" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#e0a84a" stop-opacity=".1"/><stop offset=".5" stop-color="#f6c66e"/><stop offset="1" stop-color="#e0a84a" stop-opacity="0"/></linearGradient>''',
            f'''<rect width="{W}" height="{H}" fill="url(#abg)"/>
{rays(3300, -200, 26, "#ffd690", 2600, (1.9, 2.75), 1.2, 4)}
<ellipse cx="2500" cy="1080" rx="1500" ry="620" fill="#e3a64c" opacity=".24" filter="url(#glow)"/>
<ellipse cx="2700" cy="1000" rx="520" ry="220" fill="#ffdc96" opacity=".18" filter="url(#glow2)"/>
<g filter="url(#depth)" opacity=".55" mask="url(#edgeFade)">{silk(60, 640, 360, 240, 3.0, 2.6, 1.6, "gold2", 3, .6, 11)}</g>
{dof(26, 7, ["#ffd98c", "#e0a84a", "#fff1cf"], (200, 200, W - 200, 1000), 8, 46)}
<g mask="url(#edgeFade)">{silk(120, 1100, 520, 300, 4.2, .6, 1.4, "gold", 2.1, .95, 1)}
{silk(18, 1100, 70, 300, 4.2, .6, 1.4, "goldHi", 1.6, .9, 3)}
{silk(70, 1380, 300, 220, 3.4, 2.2, 2.0, "gold2", 1.5, .55, 2)}</g>
{"".join(glint(x, y, s, "#ffe7b0", .9) for x, y, s in ((2560, 1010, 26), (1720, 1130, 16), (3080, 880, 18), (2280, 1180, 12)))}
{dof(14, 17, ["#ffcf7a", "#ffe6b3"], (0, 1500, W, H), 50, 120)}''')

# Sakura: a kitsune night in Kitsumi's palette: a huge moon with a halo, a faint far peak, misty hills in layers, a
# torii and a fox on the near hill rimmed by moonlight, fox-fire, petals near (soft) and far (crisp).
r = random.Random(21)
stars = "".join(f'<circle cx="{r.uniform(0, W):.0f}" cy="{r.uniform(0, H * .62):.0f}" r="{r.choice((1.2, 1.6, 2.2, 2.8)):.1f}" fill="#f3f5fe" opacity="{r.uniform(.2, .8):.2f}"/>' for _ in range(300))
twinkles = "".join(glint(r.uniform(0, W), r.uniform(0, H * .5), r.uniform(10, 18), "#eef0ff", r.uniform(.5, .9)) for _ in range(9))


def hills(y, amp, ph, color, op=1):
    pts = [(x, y + amp * math.sin(x / W * 4.1 + ph) + amp * .5 * math.sin(x / W * 9.7 + ph * 2)) for x in range(-100, W + 101, 80)]
    return f'<path d="M-100 {H} ' + " ".join(f"L{x} {py:.0f}" for x, py in pts) + f' L{W + 100} {H} Z" fill="{color}" opacity="{op}"/>'


def mist(y, h, op):
    return f'<rect x="-200" y="{y}" width="{W + 400}" height="{h}" fill="#c9bcff" opacity="{op}" filter="url(#glow2)"/>'


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
petal = lambda x, y, z, rot, c, o, f="": (f'<ellipse cx="0" cy="0" rx="{z * 1.7:.0f}" ry="{z:.0f}" fill="{c}" opacity="{o:.2f}" '
                                       f'transform="translate({x:.0f} {y:.0f}) rotate({rot:.0f})"{f}/>')
far_petals = "".join(petal(r.uniform(0, W), r.uniform(200, H - 80), r.uniform(6, 14), r.uniform(-70, 70),
                           r.choice(("#f2b3c7", "#e79ab4", "#ffd0dd")), r.uniform(.5, .9)) for _ in range(55))
near_petals = "".join(petal(r.choice((r.uniform(-50, 700), r.uniform(3200, W + 50))), r.uniform(150, H), r.uniform(40, 70),
                            r.uniform(-70, 70), "#f7bcd0", r.uniform(.22, .38), ' filter="url(#b2)"') for _ in range(4))
sakura = svg('''<linearGradient id="sbg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#090c26"/><stop offset=".45" stop-color="#18205a"/><stop offset=".74" stop-color="#4d3c80"/><stop offset="1" stop-color="#2a2152"/></linearGradient>
<radialGradient id="moon" cx=".42" cy=".38" r=".62"><stop offset="0" stop-color="#fffbf5"/><stop offset=".7" stop-color="#ffe9db"/><stop offset="1" stop-color="#f3cdc6"/></radialGradient>
<linearGradient id="peak" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6f60a8"/><stop offset="1" stop-color="#3a3170"/></linearGradient>''',
             f'''<rect width="{W}" height="{H}" fill="url(#sbg)"/>{stars}{twinkles}
<circle cx="2380" cy="860" r="1100" fill="#ffd9c8" opacity=".12" filter="url(#glow)"/>
<circle cx="2380" cy="860" r="640" fill="none" stroke="#ffe6da" stroke-width="40" opacity=".05" filter="url(#b3)"/>
<circle cx="2380" cy="860" r="530" fill="#fff1e6" opacity=".10" filter="url(#glow2)"/>
<circle cx="2380" cy="860" r="430" fill="url(#moon)"/>
<circle cx="2240" cy="780" r="60" fill="#f1d3cb" opacity=".16" filter="url(#soft)"/><circle cx="2520" cy="980" r="90" fill="#f1d3cb" opacity=".12" filter="url(#soft)"/>
<path d="M3000 1330L3380 1010Q3420 980 3460 1010L3840 1300V1400H2900Z" fill="url(#peak)" opacity=".55"/>
<path d="M3340 1040Q3420 975 3500 1040L3470 1050Q3420 1020 3370 1052Z" fill="#e9e1ff" opacity=".35"/>
{mist(1220, 200, .10)}
{hills(1300, 120, .4, "#2f2a66", .85)}
{mist(1380, 180, .12)}
{hills(1480, 110, 2.0, "#231e52")}
{mist(1560, 140, .10)}
{hills(1640, 90, 4.2, "#18153c")}
<g transform="translate(1180 1260)"><path d="{TORII}" fill="#120e2c"/><path d="{TORII}" fill="none" stroke="#ffd9e8" stroke-width="3" opacity=".25"/></g>
<g transform="translate(1440 1286) scale(4.2)"><path d="{FOX}" fill="#120e2c"/><path d="{FOX}" fill="none" stroke="#ffe3ec" stroke-width=".5" opacity=".22"/></g>
<path d="M600 {H}C900 1700 1500 1640 2100 1700S3300 1900 3840 1820V{H}Z" fill="#0e0b22"/>
{fires}{far_petals}{near_petals}''')

# Royal: violet velvet under a soft spotlight, a blurred ribbon far behind, gold and violet silk crossing in front,
# glints on the silk, fine dust and soft lights near the lens.
royal = svg('''<radialGradient id="rbg" cx=".55" cy=".38" r=".85"><stop offset="0" stop-color="#36205a"/><stop offset=".55" stop-color="#170f2a"/><stop offset="1" stop-color="#08050f"/></radialGradient>
<linearGradient id="rg" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#d9a441" stop-opacity="0"/><stop offset=".35" stop-color="#f4cf7e"/><stop offset=".7" stop-color="#d9a441"/><stop offset="1" stop-color="#d9a441" stop-opacity="0"/></linearGradient>
<linearGradient id="rgHi" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff3d6" stop-opacity="0"/><stop offset=".4" stop-color="#fff3d6"/><stop offset="1" stop-color="#fff3d6" stop-opacity="0"/></linearGradient>
<linearGradient id="rv" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8f6bff" stop-opacity="0"/><stop offset=".4" stop-color="#c2abff"/><stop offset="1" stop-color="#6c4bd8" stop-opacity=".1"/></linearGradient>''',
            f'''<rect width="{W}" height="{H}" fill="url(#rbg)"/>
{rays(2100, -300, 22, "#d8c6ff", 2500, (1.2, 1.95), 1, 8)}
<ellipse cx="2100" cy="1000" rx="1400" ry="800" fill="#7d55d9" opacity=".22" filter="url(#glow)"/>
<ellipse cx="2600" cy="1300" rx="800" ry="400" fill="#d9a441" opacity=".12" filter="url(#glow)"/>
<g filter="url(#depth)" opacity=".5" mask="url(#edgeFade)">{silk(60, 560, 300, 220, 2.8, 4.0, 1.4, "rv", 3, .6, 15)}</g>
{dof(30, 9, ["#f4cf7e", "#b79cff", "#ffffff"], (100, 100, W - 100, 1100), 6, 40)}
<g mask="url(#edgeFade)">{silk(100, 900, 460, 320, 3.6, 1.1, 1.8, "rv", 2.0, .8, 5)}
{silk(80, 1250, 340, 280, 4.6, 3.0, 1.2, "rg", 1.8, .8, 6)}
{silk(14, 1250, 50, 280, 4.6, 3.0, 1.2, "rgHi", 1.4, .8, 7)}</g>
{"".join(glint(x, y, s, c, .9) for x, y, s, c in ((2380, 1080, 24, "#fff0c8"), (1500, 980, 16, "#e9dcff"), (3160, 1240, 18, "#fff0c8"), (900, 1180, 12, "#e9dcff")))}
{dof(12, 19, ["#f4cf7e", "#c9b4ff"], (0, 1500, W, H), 50, 110)}''')

# Arcade: a synthwave horizon: a striped sun with bloom and its reflection on the floor, neon mountains, a neon grid
# fading into the horizon haze, stars with a few twinkles.
hy = 1260
grid = ""
for i in range(-28, 29):
    grid += f'<line x1="{W / 2 + i * 70:.0f}" y1="{hy}" x2="{W / 2 + i * 640:.0f}" y2="{H}" stroke="#b07bff" stroke-width="3" opacity=".6"/>'
for k in range(1, 18):
    y = hy + (H - hy) * (k / 17) ** 2.2
    grid += f'<line x1="0" y1="{y:.0f}" x2="{W}" y2="{y:.0f}" stroke="#ff8a4c" stroke-width="{2 + k * .3:.1f}" opacity="{.3 + k * .035:.2f}"/>'


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
    return (f'<path d="{d}" fill="url(#mtn)"/><path d="{edge}" fill="none" stroke="#c18cff" stroke-width="7" opacity=".6" filter="url(#soft)"/>'
            f'<path d="{edge}" fill="none" stroke="#efe0ff" stroke-width="2.4"/>')


mountains = ridge((-60, 1240), 4, 420) + ridge((2600, 3900), 8, 460)
stripes = "".join(f'<rect x="{W / 2 - 700}" y="{hy - 380 + k * 70 + k * k * 2}" width="1400" height="{6 + k * 3}" fill="#140c24"/>' for k in range(2, 9))
rs = random.Random(3)
arcade_stars = "".join(f'<circle cx="{rs.uniform(0, W):.0f}" cy="{rs.uniform(0, hy - 250):.0f}" r="{rs.choice((1.2, 1.8, 2.4)):.1f}" fill="#fff" opacity="{rs.uniform(.2, .8):.2f}"/>' for _ in range(220))
arcade_twinkles = "".join(glint(rs.uniform(0, W), rs.uniform(0, hy - 450), rs.uniform(10, 16), "#f4e8ff", rs.uniform(.5, .9)) for _ in range(7))
arcade = svg('''<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#07060e"/><stop offset=".5" stop-color="#22103a"/><stop offset=".85" stop-color="#4f1d55"/><stop offset="1" stop-color="#6a2458"/></linearGradient>
<linearGradient id="sun" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffe08a"/><stop offset=".5" stop-color="#ff8a4c"/><stop offset="1" stop-color="#e03a8f"/></linearGradient>
<linearGradient id="floor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#26113d"/><stop offset=".35" stop-color="#140b24"/><stop offset="1" stop-color="#07060e"/></linearGradient>
<linearGradient id="mtn" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2a1446"/><stop offset="1" stop-color="#150a26"/></linearGradient>
<linearGradient id="refl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ff9a5c" stop-opacity=".55"/><stop offset="1" stop-color="#e03a8f" stop-opacity="0"/></linearGradient>
<linearGradient id="gridFade" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000"/><stop offset=".18" stop-color="#777"/><stop offset=".5" stop-color="#fff"/></linearGradient>
<mask id="gridMask" maskUnits="userSpaceOnUse" x="0" y="1260" width="3840" height="900"><rect x="0" y="1260" width="3840" height="900" fill="url(#gridFade)"/></mask>
<clipPath id="sunclip"><circle cx="1920" cy="880" r="560"/></clipPath>''',
             f'''<rect width="{W}" height="{H}" fill="url(#sky)"/>{arcade_stars}{arcade_twinkles}
<circle cx="1920" cy="900" r="1050" fill="#ff8a4c" opacity=".20" filter="url(#glow)"/>
<circle cx="1920" cy="880" r="660" fill="#ffb070" opacity=".22" filter="url(#glow2)"/>
<g clip-path="url(#sunclip)"><rect x="1300" y="300" width="1300" height="1200" fill="url(#sun)"/>{stripes}</g>
{mountains}
<rect x="0" y="{hy - 170}" width="{W}" height="220" fill="#ff8a4c" opacity=".12" filter="url(#glow2)"/>
<rect x="0" y="{hy}" width="{W}" height="{H - hy}" fill="url(#floor)"/>
<path d="M1640 {hy}H2200L2420 {H}H1420Z" fill="url(#refl)" opacity=".75" filter="url(#b3)"/>
{"".join(f'<rect x="{1920 - 260 - k * 30}" y="{hy + 30 + k * k * 9}" width="{520 + k * 60}" height="{3 + k}" rx="2" fill="#ffb27a" opacity="{.35 - k * .025:.2f}" filter="url(#b1)"/>' for k in range(10))}
<g mask="url(#gridMask)">{grid}</g>
<rect x="0" y="{hy - 8}" width="{W}" height="16" fill="#ff9ad5" opacity=".7" filter="url(#soft)"/>
<rect x="0" y="{hy - 2}" width="{W}" height="4" fill="#ffe2f3"/>''')

for name, s in (("amber", amber), ("sakura", sakura), ("royal", royal), ("arcade", arcade)):
    open(f"{out}/theme-{name}.svg", "w", encoding="utf-8", newline="\n").write(s)
print("theme wallpapers ok")
