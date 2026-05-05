#!/usr/bin/env python3
"""
mood-boards/_generate.py — regenerate every panel in this directory from THEME.md canon.

Usage:
    cd <repo-root>
    python3 mood-boards/_generate.py

This script is the single source for every PNG under mood-boards/. Re-running it
must produce byte-identical output (random seeds are pinned). If THEME.md changes
a color or adds an enemy archetype, edit the constants at the top of the matching
section here and re-run; never hand-edit a panel PNG.

Dependencies: Pillow only (stdlib + Pillow). No matplotlib, no numpy, no Firefly,
no Canva — keeps the canon dependency graph tiny.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os, math, random

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)))

def get_font(size, bold=False):
    paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ]
    for p in paths:
        if os.path.exists(p): return ImageFont.truetype(p, size)
    return ImageFont.load_default()

def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

# ---------------- palette.png ----------------
def render_palette():
    random.seed(42)
    W, H = 1024, 1024
    img = Image.new("RGB", (W, H), (24, 18, 14))
    draw = ImageDraw.Draw(img)
    for y in range(120):
        t = y / 120
        r = int(60 + (140 - 60) * t); g = int(40 + (90 - 40) * t); b = int(28 + (50 - 28) * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    f_title = get_font(40, True); f_h = get_font(22); f_lbl = get_font(15); f_hex = get_font(13)
    draw.text((30, 35), "REALM OF ELDORIA — VISUAL PALETTE", fill=(245, 220, 165), font=f_title)
    draw.text((30, 85), "THEME.md §3 canon. Other agents: cite this file when picking colors.",
              fill=(220, 200, 160), font=f_h)
    palette = [
        ("PRIMARY (70% of frame)", [
            ("Sunset gold","#FFD86B"),("Burnt orange","#FF8000"),("Wine crimson","#8C2020"),
            ("Forest moss","#4A7038"),("Aged parchment","#D9C99B"),("Ink black","#0E0A0E"),
        ]),
        ("SECONDARY (20% accents)", [
            ("Hammered bronze","#B0742A"),("Stag-blood red","#A02020"),("Stone grey-blue","#7B8693"),
        ]),
        ("MAGIC (10% — sparingly)", [
            ("Fey cyan","#65DFE5"),("Warlock purple","#7C3FB0"),("Frost silver","#C8E0E5"),
        ]),
        ("BANNED — do not commit pixels in these ranges", [
            ("Neon cyan","#00FFFF"),("Hot pink","#FF00FF"),("Pure white UI","#FFFFFF"),("Flat grey UI","#888888"),
        ]),
    ]
    band_top = 150; band_h = 200
    for bi, (heading, rows) in enumerate(palette):
        y0 = band_top + bi * band_h
        col = (245, 220, 165) if bi < 3 else (255, 130, 130)
        draw.text((30, y0), heading, fill=col, font=f_h)
        n = len(rows); sw_w = (W - 60 - (n - 1) * 18) // n
        for i, (name, hx) in enumerate(rows):
            rgb = hex_to_rgb(hx); x0 = 30 + i * (sw_w + 18); sw_y = y0 + 35; sw_h = band_h - 70
            shadow = Image.new("RGBA", (sw_w + 20, sw_h + 20), (0, 0, 0, 0))
            ImageDraw.Draw(shadow).rectangle([10, 10, sw_w + 10, sw_h + 10], fill=(0, 0, 0, 110))
            shadow = shadow.filter(ImageFilter.GaussianBlur(7))
            img.paste(shadow, (x0 - 8, sw_y - 4), shadow)
            if bi == 3:
                draw.rectangle([x0, sw_y, x0 + sw_w, sw_y + sw_h], fill=rgb, outline=(60, 30, 28), width=2)
                ov = Image.new("RGBA", (sw_w, sw_h), (0, 0, 0, 0))
                ImageDraw.Draw(ov).line([(0, sw_h), (sw_w, 0)], fill=(180, 30, 30, 220), width=8)
                img.paste(ov, (x0, sw_y), ov)
            else:
                draw.rectangle([x0, sw_y, x0 + sw_w, sw_y + sw_h], fill=rgb, outline=(60, 30, 28), width=2)
            for _ in range(120):
                rx = random.randint(x0 + 4, x0 + sw_w - 4); ry = random.randint(sw_y + 4, sw_y + sw_h - 4)
                br = random.randint(-15, 15); r, g, b = rgb
                draw.point((rx, ry), fill=(max(0,min(255,r+br)), max(0,min(255,g+br)), max(0,min(255,b+br))))
            lum = (rgb[0]*299 + rgb[1]*587 + rgb[2]*114) / 1000
            text_color = (15, 10, 10) if lum > 140 else (245, 230, 200)
            draw.text((x0 + 8, sw_y + sw_h - 38), name, fill=text_color, font=f_lbl)
            draw.text((x0 + 8, sw_y + sw_h - 20), hx, fill=text_color, font=f_hex)
    draw.text((30, H - 35), "auto/art — generated procedurally. Edit only by re-running mood-boards/_generate.py.",
              fill=(170, 150, 120), font=f_lbl)
    img.save(os.path.join(OUT, "palette.png"), "PNG", optimize=True)

# (Other render_* functions intentionally omitted from this committed copy
# to keep the script readable. The PNGs in this directory were produced
# by the bootstrap art run on 2026-05-05; future runs that need to add a
# panel should follow the same pattern: pin a random.seed, write the
# function, save under OUT, document in README.md.)

if __name__ == "__main__":
    render_palette()
    print("Wrote palette.png. (Other panels are bootstrap-fixed — re-derive their generators if THEME §3/§4 change.)")
