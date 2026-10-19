# Rook, Paper, Scissors!' own wallpaper (an extra choice, next to Leonote's in branding/leonote-wallpapers.py).
# (The Kitsumi and Olexify ones were retired.) Writes SVGs; the image build renders them to 4K PNGs.
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

for name, s in (("rps", rps),):
    open(f"{out}/theme-{name}.svg", "w", encoding="utf-8", newline="\n").write(s)
print("brand wallpapers ok")
