# Firefox themes for Olexify's apps (same colours as their Fennek OS themes): Leonote, Kitsumi, Olexify, Rook, Paper,
# Scissors! and Fennek OS itself. Firefox only installs themes signed by Mozilla, so these are uploaded to
# addons.mozilla.org (Developer Hub > Submit a New Theme > upload the .zip); once listed, Fennek OS can offer them.
#   python branding/firefox-themes.py OUTDIR      writes OUTDIR/<name>/manifest.json and OUTDIR/<name>.zip
import json, os, sys, zipfile

T = {  # id: name, description, frame, toolbar, field, text, dim text, accent
    "fennek": ("Fennek OS", "Fennek OS's own colours: deep night violet with a warm accent.",
               "#160f26", "#211837", "#2c2246", "#efeaf8", "#b7accd", "#8a63d2"),
    "leonote": ("Leonote", "Leonote's look: near-black with warm gold. Everything you think, in one instant app.",
                "#0e0e10", "#18181b", "#232327", "#ececef", "#a8a6ad", "#e0a84a"),
    "kitsumi": ("Kitsumi", "Kitsumi's night: deep blue with lavender and peach. Learn languages from the videos you already watch.",
                "#121735", "#1b2253", "#262c68", "#f3f5fe", "#b2b6ca", "#ff9a6a"),
    "olexify": ("Olexify", "The Olexify workshop: dark violet, cream and gold.",
                "#120c22", "#1c1330", "#2a1d44", "#f6ecd6", "#b3a8c9", "#d9a441"),
    "rps": ("Rook, Paper, Scissors!", "Chess until the rules fight back: night purple with violet and orange.",
            "#0c0a14", "#141020", "#221a36", "#f0eef8", "#b6afd4", "#a970ff"),
}


def manifest(key, name, desc, frame, toolbar, field, text, dim, accent):
    return {
        "manifest_version": 2,
        "name": name,
        "version": "1.0",
        "description": desc,
        "browser_specific_settings": {"gecko": {"id": f"{key}-theme@olexify.github.io"}},
        "theme": {"colors": {
            "frame": frame, "frame_inactive": frame, "tab_background_text": dim,
            "tab_selected": toolbar, "tab_text": text, "tab_line": accent, "tab_loading": accent,
            "toolbar": toolbar, "toolbar_text": text, "toolbar_top_separator": frame, "toolbar_bottom_separator": frame,
            "toolbar_field": field, "toolbar_field_text": text, "toolbar_field_border": field,
            "toolbar_field_focus": field, "toolbar_field_text_focus": text, "toolbar_field_border_focus": accent,
            "toolbar_field_highlight": accent, "toolbar_field_highlight_text": frame,
            "button_background_hover": field, "button_background_active": field,
            "icons": text, "icons_attention": accent,
            "popup": toolbar, "popup_text": text, "popup_border": field,
            "popup_highlight": accent, "popup_highlight_text": frame,
            "sidebar": toolbar, "sidebar_text": text, "sidebar_border": frame,
            "sidebar_highlight": accent, "sidebar_highlight_text": frame,
            "ntp_background": frame, "ntp_text": text,
        }},
    }


out = sys.argv[1]
for key, v in T.items():
    d = os.path.join(out, key)
    os.makedirs(d, exist_ok=True)
    m = json.dumps(manifest(key, *v), indent=2, ensure_ascii=False) + "\n"
    open(os.path.join(d, "manifest.json"), "w", encoding="utf-8", newline="\n").write(m)
    with zipfile.ZipFile(os.path.join(out, f"{key}.zip"), "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("manifest.json", m)
print("firefox themes ok:", ", ".join(T))
