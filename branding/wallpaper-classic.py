# Fennek Classic wallpaper (the first signature, kept as an extra choice): desert dusk. Night sky (violet to warm gold at the horizon), faint stars, a crescent moon,
# layered soft dunes. Writes an SVG; the image build renders it to the 4K PNG wallpaper.
#   python branding/wallpaper-classic.py system_files/usr/share/fennek/wallpaper-classic.svg
import random, sys

W, H = 3840, 2160
rnd = random.Random(7)   # same stars every build
stars = "".join(
    f'<circle cx="{rnd.uniform(0, W):.0f}" cy="{rnd.uniform(0, H * 0.48):.0f}" r="{rnd.choice((1.4, 1.8, 2.4, 3)):.1f}" '
    f'fill="#fff" opacity="{rnd.uniform(0.25, 0.8):.2f}"/>'
    for _ in range(140))


def dune(y, amp, phase, top, bottom, edge, opacity=1):
    """A smooth dune band across the screen, starting at height y."""
    pts = [(x, y + amp * __import__("math").sin(x / W * 3.2 + phase) + amp * 0.45 * __import__("math").sin(x / W * 7.1 + phase * 2))
           for x in range(0, W + 1, 160)]
    d = f"M0 {H} L0 {pts[0][1]:.0f} " + " ".join(f"L{x} {py:.0f}" for x, py in pts[1:]) + f" L{W} {H} Z"
    gid = f"g{int(y)}"
    crest = " ".join(f"{'M' if i == 0 else 'L'}{x} {py:.0f}" for i, (x, py) in enumerate(pts))
    return (f'<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/>'
            f'<stop offset="1" stop-color="{bottom}"/></linearGradient>'
            f'<path d="{d}" fill="url(#{gid})" opacity="{opacity}"/>'
            f'<path d="{crest}" fill="none" stroke="{edge}" stroke-width="3" opacity=".35"/>')


svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#120a26"/><stop offset=".33" stop-color="#2c1950"/>
    <stop offset=".52" stop-color="#6a3a72"/><stop offset=".62" stop-color="#c9714a"/><stop offset=".7" stop-color="#f2a65a"/>
  </linearGradient>
  <radialGradient id="glow" cx=".5" cy="1" r=".7"><stop offset="0" stop-color="#ffb76b" stop-opacity=".55"/>
    <stop offset="1" stop-color="#ffb76b" stop-opacity="0"/></radialGradient>
  <radialGradient id="moonglow" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#ffe9c4" stop-opacity=".35"/>
    <stop offset="1" stop-color="#ffe9c4" stop-opacity="0"/></radialGradient>
  <mask id="crescent"><rect width="{W}" height="{H}" fill="#fff"/><circle cx="3020" cy="380" r="118" fill="#000"/></mask>
</defs>
<rect width="{W}" height="{H}" fill="url(#sky)"/>
<rect y="{H * 0.3:.0f}" width="{W}" height="{H * 0.4:.0f}" fill="url(#glow)"/>
{stars}
<circle cx="2980" cy="420" r="260" fill="url(#moonglow)"/>
<circle cx="2980" cy="420" r="130" fill="#ffe6b8" mask="url(#crescent)"/>
{dune(1380, 60, 0.4, "#d98a5c", "#8a4862", "#ffd59a", 0.95)}
{dune(1560, 85, 2.1, "#a85866", "#4a2852", "#ffc27e")}
{dune(1760, 80, 4.0, "#5e2f5f", "#24153a", "#f0a868")}
{dune(1950, 60, 1.2, "#2e1a44", "#120b20", "#d08a52")}
</svg>
'''
open(sys.argv[1], "w", newline="\n").write(svg)
print("ok", len(svg))
