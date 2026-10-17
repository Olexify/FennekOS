"""Fennek pointers: the classic shapes (white arrow with a black edge, sharp corners), a soft shadow, a violet
busy ring. Writes SVG sources + cursors.txt to <root>/usr/share/fennek/cursor-src; build.sh renders them
(24/32/48/64 px) into the "Fennek-Cursors" pointer theme. Everything not drawn here comes from Breeze.

  python branding/make-cursors.py system_files
"""
import math, os, sys

root = sys.argv[1] if len(sys.argv) > 1 else "system_files"
out = f"{root}/usr/share/fennek/cursor-src"
os.makedirs(out, exist_ok=True)
for f in os.listdir(out):
    os.remove(f"{out}/{f}")

W, B = "#ffffff", "#111111"   # fill, edge
SHADOW = ('<defs><filter id="s" x="-30%" y="-30%" width="160%" height="160%">'
          '<feDropShadow dx="0.6" dy="1" stdDeviation="0.9" flood-color="#000" flood-opacity=".35"/></filter></defs>')


def svg(body, shadow=True):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">{SHADOW}'
            f'<g filter="url(#s)" stroke-linejoin="miter" stroke-miterlimit="10">{body}</g></svg>\n') if shadow else \
           f'<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">{body}</svg>\n'


def shape(d, fill=W, edge=B, w=1.25):
    return f'<path d="{d}" fill="{fill}" stroke="{edge}" stroke-width="{w}"/>'


ARROW = "M3 2.5 L3 22.5 L8 17.8 L11.3 25.6 L14.4 24.3 L11.2 16.7 L17.8 16.7 Z"
HAND = ("M11 3.6 a1.9 1.9 0 0 1 3.8 0 V12.6 a1.8 1.8 0 0 1 3.6 0.4 a1.8 1.8 0 0 1 3.5 0.6 a1.8 1.8 0 0 1 3.5 0.8"
        " V20.5 c0 3.6 -1.6 6.2 -3.6 7.5 H14.2 c-1.8 -1.2 -3.2 -3 -4.6 -5.4 L6.4 17.6 a1.9 1.9 0 0 1 3 -2.3 L11 17.2 Z")


def arrow_with(extra):
    return svg(shape(ARROW) + extra)


def double_arrow(angle):
    # Two-headed resize arrow along the x axis, rotated; sharp heads.
    d = ("M4 16 L9.5 10.5 L9.5 14 L22.5 14 L22.5 10.5 L28 16 L22.5 21.5 L22.5 18 L9.5 18 L9.5 21.5 Z")
    return svg(f'<g transform="rotate({angle} 16 16)">{shape(d)}</g>')


cursors = {}   # name -> (svg, hotspot x, y)  in the 32 px design
cursors["default"] = (svg(shape(ARROW)), 3, 2.5)
cursors["pointer"] = (svg(shape(HAND)), 12.9, 2.4)
cursors["text"] = (svg('<path d="M11.5 5 H14.5 L16 6.4 L17.5 5 H20.5 V7 H17 V25 H20.5 V27 H17.5 L16 25.6 L14.5 27 H11.5 V25 H15 V7 H11.5 Z" '
                       f'fill="{B}" stroke="{W}" stroke-width="1"/>'), 16, 16)
cursors["crosshair"] = (svg(f'<path d="M16 3 V29 M3 16 H29" stroke="{W}" stroke-width="3"/>'
                            f'<path d="M16 3 V29 M3 16 H29" stroke="{B}" stroke-width="1.2"/>'), 16, 16)
cursors["move"] = (svg(shape("M16 2.5 L21 7.5 H17.5 V14.5 H24.5 V11 L29.5 16 L24.5 21 V17.5 H17.5 V24.5 H21 L16 29.5 "
                             "L11 24.5 H14.5 V17.5 H7.5 V21 L2.5 16 L7.5 11 V14.5 H14.5 V7.5 H11 Z")), 16, 16)
cursors["ew-resize"] = (double_arrow(0), 16, 16)
cursors["ns-resize"] = (double_arrow(90), 16, 16)
cursors["nwse-resize"] = (double_arrow(45), 16, 16)
cursors["nesw-resize"] = (double_arrow(-45), 16, 16)
cursors["not-allowed"] = (svg(f'<circle cx="16" cy="16" r="10" fill="none" stroke="{B}" stroke-width="5"/>'
                              f'<circle cx="16" cy="16" r="10" fill="none" stroke="#e5484d" stroke-width="3"/>'
                              f'<path d="M9 9 L23 23" stroke="{B}" stroke-width="5"/><path d="M9 9 L23 23" stroke="#e5484d" stroke-width="3"/>'), 16, 16)
cursors["help"] = (arrow_with(f'<circle cx="23" cy="23" r="6.5" fill="{W}" stroke="{B}" stroke-width="1.2"/>'
                              f'<path d="M20.9 21.6 a2.1 2.1 0 1 1 3 1.9 c-.8 .4 -.9 .8 -.9 1.6" fill="none" stroke="{B}" stroke-width="1.5"/>'
                              f'<circle cx="23" cy="27" r=".95" fill="{B}"/>'), 3, 2.5)
cursors["copy"] = (arrow_with(f'<rect x="18" y="18" width="11" height="11" fill="{W}" stroke="{B}" stroke-width="1.2"/>'
                              f'<path d="M23.5 20.5 V26.5 M20.5 23.5 H26.5" stroke="{B}" stroke-width="1.6"/>'), 3, 2.5)
cursors["alias"] = (arrow_with(f'<rect x="18" y="18" width="11" height="11" fill="{W}" stroke="{B}" stroke-width="1.2"/>'
                               f'<path d="M21 26.5 L26 21.5 M22.5 21.5 H26 V25" fill="none" stroke="{B}" stroke-width="1.5"/>'), 3, 2.5)
cursors["grab"] = (svg(shape(HAND)), 16, 14)
cursors["grabbing"] = (svg(shape("M9.5 13 a1.8 1.8 0 0 1 3.6 -0.2 a1.8 1.8 0 0 1 3.5 0.2 a1.8 1.8 0 0 1 3.5 0.6 a1.8 1.8 0 0 1 3.5 0.8"
                                 " V20.5 c0 3.6 -1.6 6.2 -3.6 7.5 H13 c-1.8 -1.2 -3.5 -3.5 -3.5 -7 Z")), 16, 16)

# Busy: a ring that turns (and the arrow with a small ring while an app is starting).
FRAMES = 18
ACCENT = "#8a63d2"


def ring(cx, cy, r, w, frame):
    a0 = 2 * math.pi * frame / FRAMES
    a1 = a0 + math.pi * 0.6
    x0, y0 = cx + r * math.cos(a0), cy + r * math.sin(a0)
    x1, y1 = cx + r * math.cos(a1), cy + r * math.sin(a1)
    return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{W}" stroke-width="{w + 1.6}"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="#d9d3e8" stroke-width="{w}"/>'
            f'<path d="M{x0:.2f} {y0:.2f} A{r} {r} 0 0 1 {x1:.2f} {y1:.2f}" fill="none" stroke="{ACCENT}" '
            f'stroke-width="{w}" stroke-linecap="round"/>')


animated = {}
animated["wait"] = ([svg(ring(16, 16, 9, 3.2, f)) for f in range(FRAMES)], 16, 16)
animated["progress"] = ([svg(shape(ARROW) + ring(23, 23, 5, 2.4, f)) for f in range(FRAMES)], 3, 2.5)

# Names apps ask for -> our shape (X11 and CSS names, and the hashes some toolkits use).
ALIASES = {
    "default": "left_ptr arrow top_left_arrow dnd-move dnd-none",
    "pointer": "hand1 hand2 hand pointing_hand e29285e634086352946a0e7090d73106 9d800788f1b08800ae810202380a0822",
    "text": "xterm ibeam",
    "crosshair": "cross tcross",
    "move": "all-scroll fleur size_all 4498f0e0c1937ffe01fd06f973665830 9081237383d90e509aa00f00170e968f",
    "ew-resize": "e-resize w-resize size_hor sb_h_double_arrow h_double_arrow left_side right_side col-resize split_h "
                 "028006030e0e7ebffc7f7070c0600140 14fef782d02440884392942c11205230",
    "ns-resize": "n-resize s-resize size_ver sb_v_double_arrow v_double_arrow top_side bottom_side row-resize split_v "
                 "00008160000006810000408080010102 2870a09082c103050810ffdffffe0204",
    "nwse-resize": "nw-resize se-resize size_fdiag bd_double_arrow top_left_corner bottom_right_corner c7088f0f3e6c8088236ef8e1e3e70000",
    "nesw-resize": "ne-resize sw-resize size_bdiag fd_double_arrow top_right_corner bottom_left_corner fcf1c3c7cd4491d801f1e1c78f100000",
    "not-allowed": "forbidden crossed_circle no-drop dnd-no-drop circle 03b6e0fcb3499374a867c041f52298f0",
    "help": "question_arrow whats_this left_ptr_help d9ce0ab605698f320427677b458ad60b 5c6cd98b3f3ebcb1f9c7f1c204630408",
    "copy": "dnd-copy 1081e37283d90000800003c07f3ef6bf 6407b0e94181790501fd1e167b474872",
    "alias": "link dnd-link 3085a0e285430894940527032f8b26df 640fb0e74195791501fd1ee57b41c9ab",
    "grab": "openhand",
    "grabbing": "closedhand",
    "wait": "watch",
    "progress": "left_ptr_watch half-busy 3ecb610c1bf2410f44200f48c40d3599 08e8e1c95fe2fc01f976f1e063a24ccd",
}

lines = []
for name, (s, x, y) in cursors.items():
    open(f"{out}/{name}.svg", "w", newline="\n").write(s)
    lines.append(f"{name} {x} {y} 0 {ALIASES.get(name, '')}".rstrip())
for name, (frames, x, y) in animated.items():
    for i, s in enumerate(frames):
        open(f"{out}/{name}-{i:02d}.svg", "w", newline="\n").write(s)
    lines.append(f"{name} {x} {y} {len(frames)} {ALIASES.get(name, '')}".rstrip())
# name hotspot-x hotspot-y frames aliases... (hotspots in the 32 px design; frames 0 = still)
open(f"{out}/cursors.txt", "w", newline="\n").write("\n".join(lines) + "\n")
print(f"{len(cursors) + len(animated)} pointers")
