# Leonote wallpapers (a friendly promo for Leonote, popup notes): three 4K designs in Leonote's own look — near-black,
# warm gold (#e0a84a), the golden note with its curled corner, an elegant serif line. Writes SVGs; the image build
# renders them to PNG wallpapers (Settings > Background: Leonote Night / Graph / Paper).
# Also Leonote's icon for its Start entry (Leonote, "get it"): the same tile and note, with a download badge.
#   python branding/leonote-wallpapers.py system_files/usr/share/fennek
import math, random, sys

W, H = 3840, 2160
out = sys.argv[1]
SERIF = "Georgia, 'Noto Serif', 'DejaVu Serif', serif"
SANS = "Inter, 'Noto Sans', sans-serif"
MONO = "'Cascadia Mono', 'DejaVu Sans Mono', monospace"


def note(x, y, s, light=False):
    """Leonote's icon: a dark (or white) rounded tile with the golden note and its curled corner. s = tile size."""
    k = s / 560
    tile = "#fbf8f1" if light else "#141215"
    rim = "#e7dfcf" if light else "#2a2420"
    return f'''<g transform="translate({x} {y}) scale({k:.4f})">
  <rect x="0" y="24" width="560" height="560" rx="132" fill="#000" opacity="{.10 if light else .55}" filter="url(#soft)"/>
  <rect x="0" y="0" width="560" height="560" rx="132" fill="{tile}" stroke="{rim}" stroke-width="3"/>
  <rect x="0" y="0" width="560" height="280" rx="132" fill="url(#tileShine)" opacity="{.5 if light else .9}"/>
  <g transform="translate(130 120)">
    <path d="M30 0H226a78 78 0 0 1 78 78V200C304 250 270 296 226 304L150 318H30A30 30 0 0 1 0 288V30A30 30 0 0 1 30 0z"
          fill="url(#sheet)"/>
    <path d="M0 230V288A30 30 0 0 0 30 318H150" fill="none" stroke="#b9842f" stroke-width="5" opacity=".45"/>
    <path d="M304 168C304 252 252 306 150 318C214 298 256 262 266 226C276 194 292 178 304 168z" fill="#7a5216" opacity=".35"
          filter="url(#blur6)" transform="translate(-6 10)"/>
    <path d="M304 168C304 252 252 306 150 318C214 298 256 262 266 226C276 194 292 178 304 168z" fill="url(#curl)"/>
    <path d="M30 4H226a74 74 0 0 1 74 74" fill="none" stroke="#fff6dc" stroke-width="5" opacity=".6"/>
  </g>
</g>'''


DEFS = '''<defs>
  <filter id="soft" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="36"/></filter>
  <filter id="blur6" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="6"/></filter>
  <filter id="glowBlur" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="140"/></filter>
  <linearGradient id="sheet" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#fbe3a2"/><stop offset=".55" stop-color="#ecbd62"/><stop offset="1" stop-color="#d49a3e"/>
  </linearGradient>
  <linearGradient id="curl" x1="1" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#f6cf7c"/><stop offset=".5" stop-color="#c88a2e"/><stop offset="1" stop-color="#8f5c18"/>
  </linearGradient>
  <linearGradient id="tileShine" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#ffffff" stop-opacity=".07"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
  </linearGradient>
</defs>'''


def svg(body, bg):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{DEFS}{bg}{body}</svg>\n'


# 1) Night: the banner look.
night = svg(f'''
<text x="300" y="640" font-family="{SANS}" font-size="64" font-weight="600" fill="#e0a84a" letter-spacing="2">LeoNote</text>
<text font-family="{SERIF}" font-size="190" fill="#ececef">
  <tspan x="292" y="920">Everything you</tspan>
  <tspan x="292" y="1140">think, in one</tspan>
  <tspan x="292" y="1360"><tspan fill="#e0a84a" font-style="italic">instant</tspan> app.</tspan>
</text>
<text x="300" y="1560" font-family="{SANS}" font-size="62" fill="#b9b6bf">Notes · research graph · tasks · video &amp; audio player</text>
<text x="300" y="1680" font-family="{MONO}" font-size="46" fill="#77737d">leonote.app   ·   plain Markdown   ·   pay once</text>
{note(2380, 560, 1040)}''', f'''
<linearGradient id="bgN" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#121119"/><stop offset=".55" stop-color="#0e0e10"/><stop offset="1" stop-color="#1a1309"/></linearGradient>
<rect width="{W}" height="{H}" fill="url(#bgN)"/>
<circle cx="2900" cy="1080" r="1050" fill="#e0a84a" opacity=".22" filter="url(#glowBlur)"/>
<circle cx="3500" cy="1900" r="700" fill="#8a5a14" opacity=".25" filter="url(#glowBlur)"/>''')

# 2) Graph: a calm golden constellation (Leonote's research graph) around a glowing note.
rnd = random.Random(11)
pts = []
while len(pts) < 70:
    p = (rnd.uniform(120, W - 120), rnd.uniform(120, H - 120))
    if math.hypot(p[0] - W / 2, p[1] - H / 2) > 520:
        pts.append(p)
edges = set()
for i, a in enumerate(pts):
    near = sorted(range(len(pts)), key=lambda j: math.dist(a, pts[j]))[1:3]
    for j in near:
        edges.add(tuple(sorted((i, j))))
lines = "".join(f'<line x1="{pts[i][0]:.0f}" y1="{pts[i][1]:.0f}" x2="{pts[j][0]:.0f}" y2="{pts[j][1]:.0f}"/>' for i, j in edges)
dots = "".join(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{rnd.choice((5, 6, 8, 11)):.0f}" opacity="{rnd.uniform(.35, .9):.2f}"/>' for x, y in pts)
graph = svg(f'''
<g stroke="#e0a84a" stroke-width="2.4" opacity=".22">{lines}</g>
<g fill="#f1c56d">{dots}</g>
{note(W / 2 - 330, H / 2 - 360, 660)}
<text x="{W / 2}" y="{H / 2 + 470}" text-anchor="middle" font-family="{SERIF}" font-size="96" fill="#ececef">Everything you think, connected.</text>
<text x="{W / 2}" y="{H / 2 + 580}" text-anchor="middle" font-family="{MONO}" font-size="44" fill="#8a8590">leonote.app</text>''', f'''
<radialGradient id="bgG" cx=".5" cy=".45" r=".75"><stop offset="0" stop-color="#1d1710"/><stop offset=".6" stop-color="#0f0e12"/><stop offset="1" stop-color="#09090b"/></radialGradient>
<rect width="{W}" height="{H}" fill="url(#bgG)"/>
<circle cx="{W / 2}" cy="{H / 2 - 40}" r="620" fill="#e0a84a" opacity=".20" filter="url(#glowBlur)"/>''')

# 3) Paper: light and warm, for the light look.
paper = svg(f'''
<text x="300" y="700" font-family="{SANS}" font-size="64" font-weight="600" fill="#b8822a" letter-spacing="2">LeoNote</text>
<text font-family="{SERIF}" font-size="190" fill="#18181b">
  <tspan x="292" y="980">Think it once.</tspan>
  <tspan x="292" y="1200">Find it <tspan fill="#c0892e" font-style="italic">instantly</tspan>.</tspan>
</text>
<text x="300" y="1420" font-family="{SANS}" font-size="62" fill="#5c5a62">Notes · research graph · tasks · video &amp; audio player</text>
<text x="300" y="1540" font-family="{MONO}" font-size="46" fill="#8e8a82">leonote.app</text>
{note(2420, 560, 1000, light=True)}''', f'''
<linearGradient id="bgP" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fbf9f4"/><stop offset=".6" stop-color="#f6f0e3"/><stop offset="1" stop-color="#efe1c3"/></linearGradient>
<rect width="{W}" height="{H}" fill="url(#bgP)"/>
<circle cx="2950" cy="1060" r="900" fill="#f0c56a" opacity=".28" filter="url(#glowBlur)"/>''')

for name, s in (("night", night), ("graph", graph), ("paper", paper)):
    open(f"{out}/leonote-{name}.svg", "w", encoding="utf-8", newline="\n").write(s)
# Start entry icon: the tile + note, a small blue download badge (not installed yet).
badge = ('<circle cx="468" cy="468" r="104" fill="#2f6fe0" stroke="#fff" stroke-width="22"/>'
         '<path d="M468 410v100M428 474l40 40 40-40" stroke="#fff" stroke-width="24" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
icon = (f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="-20 -20 600 620">{DEFS}'
        + note(0, 0, 560) + badge + '</svg>\n')
root = out.rsplit("/fennek", 1)[0].rsplit("/share", 1)[0] + "/share"
for d in (f"{root}/icons/Fennek/scalable/apps", f"{root}/icons/hicolor/scalable/apps"):
    open(f"{d}/fennek-get-leonote.svg", "w", encoding="utf-8", newline="\n").write(icon)
print("leonote wallpapers ok")
