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

Panels:
    palette.png      — THEME §3 color palette
    prop_sheet.png   — Briarwood village props at unified scale (run 2026-05-06)

Other panels in this directory (era_window, silhouette_check, enemy_silhouettes,
lighting_compass) are bootstrap-fixed from the 2026-05-05 art run; their generators
are intentionally not re-derived here. If THEME §1/§2/§4 change, write a fresh
render_* function following the same pattern (pin seed, write to OUT, document).
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

# ── THEME §3 canon palette (single source — used by every render_*) ───────
SUNSET_GOLD     = hex_to_rgb("FFD86B")
BURNT_ORANGE    = hex_to_rgb("FF8000")
WINE_CRIMSON    = hex_to_rgb("8C2020")
FOREST_MOSS     = hex_to_rgb("4A7038")
PARCHMENT       = hex_to_rgb("D9C99B")
INK_BLACK       = hex_to_rgb("0E0A0E")
HAMMERED_BRONZE = hex_to_rgb("B0742A")
STAG_BLOOD      = hex_to_rgb("A02020")
STONE_GREYBLUE  = hex_to_rgb("7B8693")
FEY_CYAN        = hex_to_rgb("65DFE5")

# Derivative tones — explicitly within palette band, no new canonical hues.
DARK_WOOD   = (84, 56, 32)
MID_WOOD    = (138, 92, 50)
LIGHT_WOOD  = (190, 142, 86)
THATCH_LT   = (200, 162, 90)
THATCH_DK   = (138, 102, 48)
STONE_LT    = (158, 158, 156)
STONE_DK    = (96, 96, 100)
IRON_DK     = (44, 40, 44)
IRON_LT     = (110, 108, 116)
FLAME_HOT   = (255, 224, 140)


def grain(img, draw, x0, y0, x1, y1, base_rgb, count=140, jitter=18):
    """THEME §1 'painterly' nod — speckle the fill with ±jitter brightness."""
    r, g, b = base_rgb
    for _ in range(count):
        rx = random.randint(x0 + 1, x1 - 1)
        ry = random.randint(y0 + 1, y1 - 1)
        br = random.randint(-jitter, jitter)
        draw.point((rx, ry), fill=(
            max(0, min(255, r + br)),
            max(0, min(255, g + br)),
            max(0, min(255, b + br)),
        ))


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


# ---------------- prop_sheet.png ----------------
# Schematic Briarwood prop reference. THEME.md anchor: §1 lived-in /
# §3 palette / §8 timber-stone-thatch architecture. NOT painterly —
# painterly reference art belongs under concept/ per ARTIST_AGENT.md.

def _cell_frame(draw, x0, y0, x1, y1, label, font_label):
    draw.rectangle([x0, y0, x1, y1], fill=PARCHMENT, outline=DARK_WOOD, width=3)
    draw.rectangle([x0 + 6, y0 + 6, x1 - 6, y1 - 6], outline=HAMMERED_BRONZE, width=1)
    plate_h = 28
    draw.rectangle([x0 + 6, y1 - plate_h - 6, x1 - 6, y1 - 6],
                   fill=DARK_WOOD, outline=HAMMERED_BRONZE, width=1)
    bbox = draw.textbbox((0, 0), label, font=font_label)
    tw = bbox[2] - bbox[0]
    cx = (x0 + x1) // 2
    draw.text((cx - tw // 2, y1 - plate_h - 2), label, fill=PARCHMENT, font=font_label)


def _draw_well(draw, img, cx, cy):
    rim_w, rim_h = 110, 36
    draw.ellipse([cx - rim_w, cy + 10, cx + rim_w, cy + 10 + rim_h], fill=STONE_LT, outline=INK_BLACK, width=2)
    draw.rectangle([cx - rim_w, cy + 10 + rim_h // 2, cx + rim_w, cy + 90], fill=STONE_DK, outline=INK_BLACK, width=2)
    for i in range(4):
        sx = cx - rim_w + 12 + i * 50
        draw.line([(sx, cy + 10 + rim_h // 2), (sx, cy + 90)], fill=INK_BLACK, width=1)
    draw.line([(cx - rim_w, cy + 50), (cx + rim_w, cy + 50)], fill=INK_BLACK, width=1)
    grain(img, draw, cx - rim_w + 2, cy + 25, cx + rim_w - 2, cy + 90, STONE_DK, count=100)
    draw.ellipse([cx - rim_w + 14, cy + 16, cx + rim_w - 14, cy + 38], fill=INK_BLACK)
    draw.rectangle([cx - 70, cy - 70, cx - 60, cy + 14], fill=DARK_WOOD, outline=INK_BLACK, width=1)
    draw.rectangle([cx + 60, cy - 70, cx + 70, cy + 14], fill=DARK_WOOD, outline=INK_BLACK, width=1)
    roof = [(cx - 90, cy - 60), (cx, cy - 110), (cx + 90, cy - 60)]
    draw.polygon(roof, fill=THATCH_DK, outline=INK_BLACK)
    for i in range(-7, 8):
        x_top = cx + i * 11
        y_off = abs(i) * 6
        draw.line([(x_top, cy - 110 + y_off + 4), (x_top + 4, cy - 60)], fill=THATCH_LT, width=1)
    draw.line([(cx, cy - 60), (cx, cy + 6)], fill=INK_BLACK, width=1)
    draw.rectangle([cx - 12, cy + 6, cx + 12, cy + 24], fill=MID_WOOD, outline=INK_BLACK, width=2)
    draw.line([(cx - 12, cy + 12), (cx + 12, cy + 12)], fill=HAMMERED_BRONZE, width=1)


def _draw_banner_pole(draw, img, cx, cy):
    draw.rectangle([cx - 4, cy - 130, cx + 4, cy + 90], fill=DARK_WOOD, outline=INK_BLACK, width=1)
    draw.rectangle([cx - 50, cy - 130, cx + 50, cy - 122], fill=DARK_WOOD, outline=INK_BLACK, width=1)
    draw.polygon([(cx - 7, cy - 130), (cx, cy - 144), (cx + 7, cy - 130)], fill=HAMMERED_BRONZE, outline=INK_BLACK)
    banner_pts = [(cx - 44, cy - 122), (cx + 44, cy - 122), (cx + 44, cy + 30),
                  (cx + 22, cy + 18), (cx, cy + 30), (cx - 22, cy + 18), (cx - 44, cy + 30)]
    draw.polygon(banner_pts, fill=WINE_CRIMSON, outline=INK_BLACK)
    grain(img, draw, cx - 44, cy - 122, cx + 44, cy + 28, WINE_CRIMSON, count=160, jitter=16)
    draw.ellipse([cx - 18, cy - 70, cx + 18, cy - 38], fill=PARCHMENT, outline=INK_BLACK, width=1)
    draw.ellipse([cx - 8, cy - 88, cx + 8, cy - 70], fill=PARCHMENT, outline=INK_BLACK, width=1)
    for sign in (-1, 1):
        for i in range(3):
            x1 = cx + sign * (4 + i * 4); y1 = cy - 88 - i * 6
            x2 = cx + sign * (10 + i * 4); y2 = cy - 96 - i * 6
            draw.line([(x1, y1), (x2, y2)], fill=PARCHMENT, width=2)
    for lx in (-12, -4, 4, 12):
        draw.line([(cx + lx, cy - 40), (cx + lx, cy - 22)], fill=PARCHMENT, width=2)


def _draw_cart(draw, img, cx, cy):
    bed_top = cy - 18; bed_bot = cy + 14; bed_l = cx - 76; bed_r = cx + 60
    draw.rectangle([bed_l, bed_top, bed_r, bed_bot], fill=MID_WOOD, outline=INK_BLACK, width=2)
    for i in range(1, 5):
        px = bed_l + i * (bed_r - bed_l) // 5
        draw.line([(px, bed_top + 2), (px, bed_bot - 2)], fill=INK_BLACK, width=1)
    grain(img, draw, bed_l + 2, bed_top + 2, bed_r - 2, bed_bot - 2, MID_WOOD, count=120)
    draw.rectangle([bed_l, bed_top - 16, bed_l + 8, bed_top + 4], fill=DARK_WOOD, outline=INK_BLACK, width=1)
    draw.rectangle([bed_r - 8, bed_top - 16, bed_r, bed_top + 4], fill=DARK_WOOD, outline=INK_BLACK, width=1)
    draw.line([(bed_l + 4, bed_top - 12), (bed_r - 4, bed_top - 12)], fill=DARK_WOOD, width=3)
    draw.line([(bed_l, bed_top + 8), (bed_l - 50, bed_top + 22)], fill=DARK_WOOD, width=4)
    draw.line([(bed_l, bed_bot - 4), (bed_l - 50, bed_top + 28)], fill=DARK_WOOD, width=4)
    wx, wy = cx - 30, bed_bot + 24
    draw.ellipse([wx - 28, wy - 28, wx + 28, wy + 28], fill=DARK_WOOD, outline=INK_BLACK, width=2)
    draw.ellipse([wx - 10, wy - 10, wx + 10, wy + 10], fill=HAMMERED_BRONZE, outline=INK_BLACK, width=2)
    for ang in range(0, 360, 45):
        rad = math.radians(ang)
        ex = wx + int(math.cos(rad) * 26); ey = wy + int(math.sin(rad) * 26)
        draw.line([(wx, wy), (ex, ey)], fill=INK_BLACK, width=2)


def _draw_woodpile(draw, img, cx, cy):
    log_w = 24; log_h = 24; rows = 3; cols = 5
    base_x = cx - (cols * log_w) // 2; base_y = cy + 30
    for r in range(rows):
        offset = (log_w // 2) if r % 2 else 0
        for c in range(cols - (1 if r % 2 else 0)):
            lx = base_x + offset + c * log_w
            ly = base_y - r * (log_h - 4)
            draw.ellipse([lx, ly - log_h, lx + log_w, ly], fill=MID_WOOD, outline=INK_BLACK, width=2)
            cx0 = lx + log_w // 2; cy0 = ly - log_h // 2
            for rr in (3, 6, 9):
                draw.ellipse([cx0 - rr, cy0 - rr, cx0 + rr, cy0 + rr], outline=DARK_WOOD, width=1)
            grain(img, draw, lx + 2, ly - log_h + 2, lx + log_w - 2, ly - 2, MID_WOOD, count=20)
    draw.line([(cx - 80, base_y + 4), (cx + 80, base_y + 4)], fill=DARK_WOOD, width=2)


def _draw_market_stall(draw, img, cx, cy):
    for px in (cx - 70, cx + 70):
        draw.rectangle([px - 4, cy - 70, px + 4, cy + 80], fill=DARK_WOOD, outline=INK_BLACK, width=1)
    draw.rectangle([cx - 78, cy + 30, cx + 78, cy + 50], fill=MID_WOOD, outline=INK_BLACK, width=2)
    grain(img, draw, cx - 76, cy + 32, cx + 76, cy + 48, MID_WOOD, count=80)
    awning = [(cx - 82, cy - 70), (cx + 82, cy - 70), (cx + 70, cy - 30), (cx - 70, cy - 30)]
    draw.polygon(awning, fill=WINE_CRIMSON, outline=INK_BLACK)
    for i in range(8):
        sx = cx - 82 + i * 22
        col = PARCHMENT if i % 2 else WINE_CRIMSON
        draw.polygon([(sx, cy - 30), (sx + 11, cy - 22), (sx + 22, cy - 30)], fill=col, outline=INK_BLACK)
    for i, color in enumerate([HAMMERED_BRONZE, FEY_CYAN, FOREST_MOSS]):
        bx = cx - 50 + i * 40
        draw.rectangle([bx - 8, cy + 8, bx + 8, cy + 30], fill=color, outline=INK_BLACK, width=1)
        draw.rectangle([bx - 3, cy + 4, bx + 3, cy + 10], fill=DARK_WOOD, outline=INK_BLACK, width=1)


def _draw_lantern(draw, img, cx, cy):
    draw.rectangle([cx - 3, cy - 20, cx + 3, cy + 90], fill=DARK_WOOD, outline=INK_BLACK, width=1)
    draw.rectangle([cx - 18, cy - 30, cx + 18, cy - 20], fill=DARK_WOOD, outline=INK_BLACK, width=1)
    diamond = [(cx, cy - 80), (cx + 30, cy - 50), (cx, cy - 20), (cx - 30, cy - 50)]
    draw.polygon(diamond, fill=IRON_DK, outline=INK_BLACK)
    inner = [(cx, cy - 72), (cx + 22, cy - 50), (cx, cy - 28), (cx - 22, cy - 50)]
    draw.polygon(inner, fill=SUNSET_GOLD, outline=HAMMERED_BRONZE)
    flame = [(cx, cy - 64), (cx + 8, cy - 54), (cx + 4, cy - 46), (cx, cy - 50),
             (cx - 4, cy - 46), (cx - 8, cy - 54)]
    draw.polygon(flame, fill=BURNT_ORANGE, outline=INK_BLACK)
    draw.polygon([(cx, cy - 60), (cx + 4, cy - 53), (cx, cy - 48), (cx - 4, cy - 53)], fill=FLAME_HOT)
    draw.line([(cx - 18, cy - 50), (cx + 18, cy - 50)], fill=IRON_LT, width=1)
    draw.line([(cx, cy - 80), (cx, cy - 20)], fill=IRON_LT, width=1)
    draw.line([(cx, cy - 85), (cx, cy - 80)], fill=IRON_LT, width=2)
    draw.line([(cx, cy - 30), (cx - 12, cy - 30)], fill=IRON_LT, width=1)
    draw.line([(cx, cy - 30), (cx + 12, cy - 30)], fill=IRON_LT, width=1)


def _draw_signpost(draw, img, cx, cy):
    draw.rectangle([cx - 5, cy - 40, cx + 5, cy + 90], fill=DARK_WOOD, outline=INK_BLACK, width=1)
    plank = [(cx - 60, cy - 30), (cx + 30, cy - 30), (cx + 60, cy - 5),
             (cx + 30, cy + 20), (cx - 60, cy + 20)]
    draw.polygon(plank, fill=MID_WOOD, outline=INK_BLACK)
    grain(img, draw, cx - 58, cy - 28, cx + 58, cy + 18, MID_WOOD, count=100)
    draw.line([(cx - 58, cy - 18), (cx + 28, cy - 18)], fill=DARK_WOOD, width=1)
    draw.line([(cx - 58, cy + 8), (cx + 28, cy + 8)], fill=DARK_WOOD, width=1)
    for nx, ny in [(cx - 54, cy - 24), (cx - 54, cy + 14), (cx + 22, cy - 24), (cx + 22, cy + 14)]:
        draw.ellipse([nx - 2, ny - 2, nx + 2, ny + 2], fill=IRON_LT, outline=INK_BLACK)
    plank2 = [(cx + 50, cy + 30), (cx - 30, cy + 30), (cx - 60, cy + 50),
              (cx - 30, cy + 70), (cx + 50, cy + 70)]
    draw.polygon(plank2, fill=MID_WOOD, outline=INK_BLACK)
    draw.line([(cx - 28, cy + 42), (cx + 48, cy + 42)], fill=DARK_WOOD, width=1)
    draw.line([(cx - 28, cy + 58), (cx + 48, cy + 58)], fill=DARK_WOOD, width=1)
    f = get_font(11, True)
    draw.text((cx - 50, cy - 16), "BRIARWOOD", fill=DARK_WOOD, font=f)
    draw.text((cx - 22, cy + 44), "WHISPERWOOD", fill=DARK_WOOD, font=f)


def render_prop_sheet():
    random.seed(73)
    W, H = 1024, 1024
    img = Image.new("RGB", (W, H), PARCHMENT)
    draw = ImageDraw.Draw(img)
    for _ in range(2400):
        rx = random.randint(0, W - 1); ry = random.randint(0, H - 1)
        br = random.randint(-10, 6); r, g, b = PARCHMENT
        draw.point((rx, ry), fill=(max(0,min(255,r+br)), max(0,min(255,g+br)), max(0,min(255,b+br))))
    draw.rectangle([0, 0, W, 110], fill=DARK_WOOD, outline=INK_BLACK, width=2)
    grain(img, draw, 4, 4, W - 4, 106, DARK_WOOD, count=420, jitter=12)
    f_title = get_font(38, True); f_sub = get_font(18); f_lbl = get_font(15, True); f_caption = get_font(13)
    draw.text((30, 22), "BRIARWOOD — PROP SHEET", fill=PARCHMENT, font=f_title)
    draw.text((30, 70),
              "THEME.md §1 lived-in / §3 palette / §8 timber-stone-thatch. "
              "Same scale, same canon — match these silhouettes when modeling props.",
              fill=THATCH_LT, font=f_sub)
    draw.rectangle([0, H - 50, W, H], fill=DARK_WOOD, outline=INK_BLACK, width=2)
    grain(img, draw, 4, H - 46, W - 4, H - 4, DARK_WOOD, count=200, jitter=12)
    draw.text((30, H - 38),
              "auto/art — generated procedurally. Edit only by re-running mood-boards/_generate.py.",
              fill=THATCH_LT, font=f_caption)
    draw.text((30, H - 20),
              "Mood board panel — cite this file when sourcing or modeling Briarwood props.",
              fill=THATCH_LT, font=f_caption)

    grid_top = 130; grid_bot = H - 60
    cols, rows = 3, 3
    cell_w = (W - 60) // cols
    cell_h = (grid_bot - grid_top - 30) // rows
    margin_x = 20; margin_y = 14

    props = [
        ("WELL",         _draw_well),
        ("BANNER POLE",  _draw_banner_pole),
        ("CART",         _draw_cart),
        ("WOODPILE",     _draw_woodpile),
        ("MARKET STALL", _draw_market_stall),
        ("LANTERN",      _draw_lantern),
        ("SIGNPOST",     _draw_signpost),
    ]
    for idx, (label, drawer) in enumerate(props):
        r = idx // cols; c = idx % cols
        x0 = 30 + c * cell_w + margin_x // 2
        y0 = grid_top + r * (cell_h + 8) + margin_y // 2
        x1 = x0 + cell_w - margin_x
        y1 = y0 + cell_h - margin_y
        _cell_frame(draw, x0, y0, x1, y1, label, f_lbl)
        cx = (x0 + x1) // 2; cy = (y0 + y1) // 2 - 6
        drawer(draw, img, cx, cy)

    # Scale-reference cell
    idx = 7; r = idx // cols; c = idx % cols
    x0 = 30 + c * cell_w + margin_x // 2
    y0 = grid_top + r * (cell_h + 8) + margin_y // 2
    x1 = x0 + cell_w - margin_x; y1 = y0 + cell_h - margin_y
    _cell_frame(draw, x0, y0, x1, y1, "SCALE — 1 SQUARE = 0.5 m", f_lbl)
    inner_x0 = x0 + 14; inner_y0 = y0 + 14
    inner_x1 = x1 - 14; inner_y1 = y1 - 38
    draw.rectangle([inner_x0, inner_y0, inner_x1, inner_y1], fill=(228, 214, 170), outline=INK_BLACK, width=1)
    step = 22
    for gx in range(inner_x0, inner_x1 + 1, step):
        draw.line([(gx, inner_y0), (gx, inner_y1)], fill=DARK_WOOD, width=1)
    for gy in range(inner_y0, inner_y1 + 1, step):
        draw.line([(inner_x0, gy), (inner_x1, gy)], fill=DARK_WOOD, width=1)
    px = inner_x0 + 36; py_bot = inner_y1 - 6
    draw.rectangle([px - 5, py_bot - 88, px + 5, py_bot - 30], fill=FOREST_MOSS, outline=INK_BLACK, width=1)
    draw.rectangle([px - 8, py_bot - 30, px + 8, py_bot - 4], fill=DARK_WOOD, outline=INK_BLACK, width=1)
    draw.ellipse([px - 7, py_bot - 100, px + 7, py_bot - 86], fill=PARCHMENT, outline=INK_BLACK, width=1)
    draw.text((px - 22, py_bot - 116), "PLAYER 1.8m", fill=INK_BLACK, font=f_caption)
    mx = inner_x0 + 100
    draw.rectangle([mx - 6, py_bot - 70, mx + 6, py_bot - 4], fill=WINE_CRIMSON, outline=INK_BLACK, width=1)
    draw.ellipse([mx - 7, py_bot - 84, mx + 7, py_bot - 70], fill=PARCHMENT, outline=INK_BLACK, width=1)
    draw.text((mx - 18, py_bot - 100), "MAEVE 1.6m", fill=INK_BLACK, font=f_caption)
    gx = inner_x0 + 170
    draw.rectangle([gx - 5, py_bot - 36, gx + 5, py_bot - 4], fill=FOREST_MOSS, outline=INK_BLACK, width=1)
    draw.ellipse([gx - 6, py_bot - 48, gx + 6, py_bot - 36], fill=(120, 150, 90), outline=INK_BLACK, width=1)
    draw.text((gx - 22, py_bot - 64), "GOBLIN 0.85m", fill=INK_BLACK, font=f_caption)

    img.save(os.path.join(OUT, "prop_sheet.png"), "PNG", optimize=True)


# (Other render_* functions intentionally omitted from this committed copy
# to keep the script readable. The PNGs in this directory were produced
# by the bootstrap art run on 2026-05-05; future runs that need to add a
# panel should follow the same pattern: pin a random.seed, write the
# function, save under OUT, document in README.md.)

if __name__ == "__main__":
    render_palette()
    render_prop_sheet()
    print("Wrote palette.png + prop_sheet.png. (Other panels are bootstrap-fixed — re-derive their generators if THEME §3/§4 change.)")
