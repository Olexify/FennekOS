#!/usr/bin/env python3
"""Taskbar button artwork for the Fennek panel theme (widgets/tasks.svg), classic style:
running apps get a thin line along the bottom, the focused app a soft rounded background and an accent line,
apps that need attention an amber line; pinned apps that aren't running show just their icon.

  python3 branding/make-taskbar-svg.py   -> system_files/usr/share/plasma/desktoptheme/fennek-dark/widgets/tasks.svg
Colours follow the system (ColorScheme-Text / ColorScheme-Highlight), so the accent colour is respected.
"""
import pathlib

C = 3   # slice size in px = frame margin around the icon
OUT = pathlib.Path(__file__).resolve().parent.parent / "system_files/usr/share/plasma/desktoptheme/fennek-dark/widgets/tasks.svg"
AMBER = "#f0a030"

# prefix: (background opacity, line colour, line opacity); colour None = no line
FRAMES = {
    "normal":          (0.00, "text", 0.55),
    "normal-hover":    (0.08, "text", 0.70),
    "minimized":       (0.00, "text", 0.35),
    "minimized-hover": (0.08, "text", 0.55),
    "focus":           (0.14, "accent", 1.0),
    "focus-hover":     (0.18, "accent", 1.0),
    "attention":       (0.10, "amber", 1.0),
    "attention-hover": (0.16, "amber", 1.0),
    "launcher-hover":  (0.08, None, 0),
    "hover":           (0.08, None, 0),
    "progress":        (0.22, None, 0),
}
FILL = {"text": 'class="ColorScheme-Text" fill="currentColor"', "accent": 'class="ColorScheme-Highlight" fill="currentColor"'}


def fill(kind):
    return FILL.get(kind, f'fill="{AMBER}"')


def frame(prefix, ox, oy, bg, line, line_op):
    out = []
    for row, rname in enumerate(("top", "", "bottom")):
        for col, cname in enumerate(("left", "", "right")):
            name = (rname + cname) or "center"
            x, y = ox + col * C, oy + row * C
            parts = [f'<rect x="{x}" y="{y}" width="{C}" height="{C}" fill="#000" fill-opacity="0"/>']
            if bg:
                corner = rname and cname
                if corner:   # quarter circle: rounded background corners
                    cx = x + C if cname == "left" else x
                    cy = y + C if rname == "top" else y
                    sx = -C if cname == "left" else C
                    sy = -C if rname == "top" else C
                    sweep = 1 if (sx < 0) == (sy < 0) else 0
                    d = f"M{cx} {cy}L{cx + sx} {cy}A{C} {C} 0 0 {sweep} {cx} {cy + sy}Z"
                    parts.append(f'<path d="{d}" {fill("text")} opacity="{bg}"/>')
                else:
                    parts.append(f'<rect x="{x}" y="{y}" width="{C}" height="{C}" {fill("text")} opacity="{bg}"/>')
            if line and rname == "bottom":
                parts.append(f'<rect x="{x}" y="{y + C - 2}" width="{C}" height="2" {fill(line)} opacity="{line_op}"/>')
            out.append(f'<g id="{prefix}-{name}">{"".join(parts)}</g>')
    return "\n".join(out)


def expander(name, x, y, points):
    return (f'<g id="group-expander-{name}"><rect x="{x}" y="{y}" width="8" height="8" fill="#000" fill-opacity="0"/>'
            f'<path d="{points}" {fill("text")} opacity="0.7"/></g>')


def main():
    body = [frame(p, (i % 6) * 12, (i // 6) * 12, *spec) for i, (p, spec) in enumerate(FRAMES.items())]
    y = 40
    body += [expander("top", 0, y, f"M1 {y + 6}L7 {y + 6}L4 {y + 2}Z"),
             expander("bottom", 10, y, f"M11 {y + 2}L17 {y + 2}L14 {y + 6}Z"),
             expander("left", 20, y, f"M26 {y + 1}L26 {y + 7}L22 {y + 4}Z"),
             expander("right", 30, y, f"M32 {y + 1}L32 {y + 7}L36 {y + 4}Z")]
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="72" height="52" viewBox="0 0 72 52">\n'
           '<style id="current-color-scheme">.ColorScheme-Text{color:#fcfcfc}.ColorScheme-Highlight{color:#8a63d2}</style>\n'
           + "\n".join(body) + "\n</svg>\n")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(svg)
    print(f"{OUT} ({len(FRAMES)} frames)")


if __name__ == "__main__":
    main()
