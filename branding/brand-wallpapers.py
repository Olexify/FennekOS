# Wallpapers for the Fennek OS themes of Olexify's apps (next to Leonote's, branding/leonote-wallpapers.py): Kitsumi,
# Olexify and Rook, Paper, Scissors!, each in its own look. Writes SVGs; the image build renders them to 4K PNGs.
#   python branding/brand-wallpapers.py system_files/usr/share/fennek
import math, random, sys

W, H = 3840, 2160
out = sys.argv[1]
SERIF = "'EB Garamond', Georgia, 'Noto Serif', 'DejaVu Serif', serif"
SANS = "Inter, 'Noto Sans', sans-serif"
MONO = "'Cascadia Mono', 'DejaVu Sans Mono', monospace"
BLUR = '''<filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="140"/></filter>
<filter id="soft" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="30"/></filter>
<filter id="tileGlow" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="22"/></filter>'''


def svg(defs, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><defs>{BLUR}{defs}</defs>'
            f'{body}</svg>\n')


# Kitsumi: like kitsumi.org: a deep blue night, stars, sakura petals drifting across, peach accents, a gold sparkle.
rnd = random.Random(5)
stars = "".join(f'<circle cx="{rnd.uniform(0, W):.0f}" cy="{rnd.uniform(0, H):.0f}" r="{rnd.choice((1.6, 2.2, 3, 3.6)):.1f}" fill="#f3f5fe" '
                f'opacity="{rnd.uniform(.2, .75):.2f}"/>' for _ in range(220))
petals = "".join(f'<ellipse cx="0" cy="0" rx="{s * 1.6:.0f}" ry="{s:.0f}" fill="#e7a6bd" opacity="{rnd.uniform(.45, .85):.2f}" '
                 f'transform="translate({rnd.uniform(1500, W - 60):.0f} {rnd.uniform(60, H - 60):.0f}) rotate({rnd.uniform(-60, 60):.0f})"/>'
                 for s in [rnd.uniform(10, 34) for _ in range(46)])
spark = '<path d="M0 -60 C8 -14 14 -8 60 0 C14 8 8 14 0 60 C-8 14 -14 8 -60 0 C-14 -8 -8 -14 0 -60z" fill="#ffd77a"/>'
kitsumi = svg('''<linearGradient id="kbg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#121735"/><stop offset=".55" stop-color="#1b2253"/><stop offset="1" stop-color="#262c68"/></linearGradient>
<linearGradient id="peach" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#ffb48a"/><stop offset="1" stop-color="#ff8a5c"/></linearGradient>''',
              f'''<rect width="{W}" height="{H}" fill="url(#kbg)"/>{stars}
<circle cx="2900" cy="900" r="900" fill="#6b5bd6" opacity=".22" filter="url(#glow)"/>
<circle cx="700" cy="1900" r="700" fill="#ff8a5c" opacity=".12" filter="url(#glow)"/>
{petals}
<g transform="translate(3420 1820)">{spark}</g><g transform="translate(3250 1700) scale(.4)">{spark}</g>
<text x="300" y="760" font-family="{SANS}" font-size="250" font-weight="700" fill="#f3f5fe" letter-spacing="-6">Kitsumi</text>
<text font-family="{SANS}" font-size="92" font-weight="600" fill="#e4e7f5"><tspan x="306" y="960">Learn languages from the</tspan><tspan x="306" y="1080">videos you <tspan fill="url(#peach)">already watch</tspan>.</tspan></text>
<rect x="306" y="1220" width="560" height="120" rx="60" fill="url(#peach)"/>
<text x="586" y="1300" text-anchor="middle" font-family="{SANS}" font-size="56" font-weight="700" fill="#2a1a12">kitsumi.org</text>''')

# Olexify: the workshop's deep violet night, gold vines curling in from the corners, cream serif name.
def vine(x0, y0, sx, sy, n=7):
    d, leaves, x, y, a = f"M{x0} {y0}", "", x0, y0, 0.0
    for i in range(n):
        nx, ny = x + sx * (260 + 30 * math.sin(i)), y + sy * (120 + 90 * math.cos(i * 1.3))
        cx, cy = x + sx * 160, y - sy * 140 * (1 if i % 2 else -1)
        d += f" Q{cx:.0f} {cy:.0f} {nx:.0f} {ny:.0f}"
        lx, ly = (x + nx) / 2, (y + ny) / 2
        ang = math.degrees(math.atan2(ny - y, nx - x)) + (60 if i % 2 else -60)
        leaves += (f'<path d="M0 0 Q30 -26 70 0 Q30 26 0 0z" fill="#d9a441" opacity=".55" '
                   f'transform="translate({lx:.0f} {ly:.0f}) rotate({ang:.0f})"/>')
        x, y = nx, ny
    return f'<path d="{d}" fill="none" stroke="#d9a441" stroke-width="5" opacity=".55"/>{leaves}'


olexify = svg('''<radialGradient id="obg" cx=".5" cy=".9" r="1"><stop offset="0" stop-color="#3a2530"/><stop offset=".45" stop-color="#1c1330"/><stop offset="1" stop-color="#0e0a1a"/></radialGradient>''',
              f'''<rect width="{W}" height="{H}" fill="url(#obg)"/>
<circle cx="{W / 2}" cy="{H + 200}" r="1300" fill="#d9a441" opacity=".14" filter="url(#glow)"/>
{vine(0, 260, 1, 1)}{vine(W, 300, -1, 1)}{vine(0, H - 180, 1, -1, 5)}{vine(W, H - 220, -1, -1, 5)}
<text x="{W / 2}" y="820" text-anchor="middle" font-family="{SERIF}" font-size="64" fill="#d9a441" letter-spacing="22">DIGITAL WORKSHOP · UKRAINE</text>
<text x="{W / 2}" y="1200" text-anchor="middle" font-family="{SERIF}" font-size="380" fill="#f6ecd6">Olexify</text>
<line x1="{W / 2 - 420}" y1="1330" x2="{W / 2 + 420}" y2="1330" stroke="#d9a441" stroke-width="4" opacity=".7"/>
<text x="{W / 2}" y="1480" text-anchor="middle" font-family="{SERIF}" font-size="60" fill="#b3a8c9" letter-spacing="16">REMOVE THE FRICTION, NOT THE EFFORT</text>''')

# Rook, Paper, Scissors!: a tilted chess board in the game's violet, glowing power-up tiles, the coloured title.
sq = 210
board = ""
for r in range(8):
    for c in range(8):
        board += f'<rect x="{c * sq}" y="{r * sq}" width="{sq}" height="{sq}" fill="{"#e3ddf8" if (r + c) % 2 == 0 else "#64559b"}"/>'
tiles = "".join(f'<rect x="{c * sq + 50}" y="{r * sq + 50}" width="{sq - 100}" height="{sq - 100}" rx="22" fill="{col}" filter="url(#tileGlow)"/>'
                f'<rect x="{c * sq + 55}" y="{r * sq + 55}" width="{sq - 110}" height="{sq - 110}" rx="20" fill="{col}"/>'
                for r, c, col in ((1, 6, "#58d6ff"), (4, 2, "#ffd166"), (6, 1, "#a970ff"), (3, 5, "#ff8a4c")))
rook = ('<path d="M-60 120h120v-20h-20l-12-120h22v-60h-26v26h-22v-26h-24v26h-22v-26h-26v60h22l-12 120h-20z" fill="#1d1730"/>')
rps = svg('''<radialGradient id="rbg" cx=".15" cy=".2" r=".9"><stop offset="0" stop-color="#2a1f45"/><stop offset=".55" stop-color="#141020"/><stop offset="1" stop-color="#0c0a14"/></radialGradient>''',
          f'''<rect width="{W}" height="{H}" fill="url(#rbg)"/>
<circle cx="2900" cy="1100" r="1000" fill="#a970ff" opacity=".18" filter="url(#glow)"/>
<g transform="translate(2050 160) rotate(-12)">
  <rect x="-40" y="-40" width="{8 * sq + 80}" height="{8 * sq + 80}" rx="60" fill="#2b2240"/>
  <g>{board}</g>{tiles}
  <g transform="translate({6 * sq + sq / 2} {0 * sq + sq / 2}) scale(.9)">{rook}</g>
  <g transform="translate({0 * sq + sq / 2} {0 * sq + sq / 2}) scale(.9)">{rook}</g>
</g>
<rect x="300" y="380" width="230" height="230" rx="48" fill="#1d1730"/>
<g transform="translate(415 520) scale(1.05)"><path d="M-60 60h120v-20h-20l-12-80h22v-50h-26v22h-22v-22h-24v22h-22v-22h-26v50h22l-12 80h-20z" fill="#a970ff"/></g>
<text font-family="{SERIF}" font-size="230" font-weight="700">
  <tspan x="292" y="900" fill="#c8a8ff">Rook, </tspan><tspan fill="#f0eef8">Paper,</tspan>
  <tspan x="292" y="1150" fill="#ff8a4c">Scissors!</tspan>
</text>
<text x="300" y="1340" font-family="{SANS}" font-size="70" fill="#f0eef8">Chess until the rules fight back.</text>
<text x="300" y="1440" font-family="{SANS}" font-size="56" fill="#b6afd4">Power-up tiles · rule cards · chaos events · bots with opinions</text>
<text x="300" y="1580" font-family="{SERIF}" font-size="50" fill="#a19ac5" letter-spacing="14">ROOKPAPERSCISSORS.COM</text>''')

for name, s in (("kitsumi", kitsumi), ("olexify", olexify), ("rps", rps)):
    open(f"{out}/theme-{name}.svg", "w", encoding="utf-8", newline="\n").write(s)
print("brand wallpapers ok")
