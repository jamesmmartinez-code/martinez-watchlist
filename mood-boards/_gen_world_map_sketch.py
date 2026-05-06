#!/usr/bin/env python3
"""
mood-boards/_gen_world_map_sketch.py — Eldoria world-map reference panel.

THEME.md anchors:
  §1  painterly hand-painted concept-art aesthetic; warm sunset palette,
      cool tones reserved for night/mist/magic.
  §3  canon palette (parchment, ink, wine, sunset gold, forest moss,
      hammered bronze, stone grey-blue, fey cyan for magic only).
  §5  hand-painted look not crisp vector; brushstroke edges; serif
      typography (DejaVuSerif as the Cinzel/EB-Garamond proxy).
  §8  architecture & environment: Briarwood Village (forest edge),
      Whisperwood (dense oak/pine), Crystal Caves (cool blue glow,
      crystals), Mountain Ring (impassable peaks framing horizon).
  §10 hard rules: every visual asset CC0; no Firefly / Canva calls;
      pinned random.seed for byte-stable re-renders.

Subject: a Tolkien-style hand-painted parchment world map of Eldoria
showing the four canonical regions spatially arranged as the player
encounters them, with a dotted Briarwood -> Whisperwood -> Crystal Caves
trail. It exists so Lore / Builder / Quest agents can cite ONE map and
stop re-deriving spatial relationships from prose. Schematic-not-
painterly per `mood-boards/README.md` Provenance — the boards exist to
point at decisions, not to inspire by mood (sibling to palette.png /
prop_sheet.png / architecture_palette.png / magic_glow_reference.png /
ui_chrome.png).

Pattern follows mood-boards/_generate.py,
mood-boards/_gen_architecture_palette.py,
mood-boards/_gen_magic_glow_reference.py, and
mood-boards/_gen_ui_chrome.py — Pillow-only, pinned random.seed,
byte-stable on re-run. THEME §3 colours imported verbatim from
_generate.py.

Usage:
    python3 mood-boards/_gen_world_map_sketch.py
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
import math
import random


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


# THEME §3 canon palette (mirrored from mood-boards/_generate.py)
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

# Derivative tones — explicit palette band, no new canonical hues.
DARK_WOOD     = (84, 56, 32)
MID_WOOD      = (138, 92, 50)
LIGHT_WOOD    = (190, 142, 86)
PARCHMENT_LT  = (228, 212, 168)
PARCHMENT_DK  = (180, 158, 110)
PARCHMENT_BRN = (148, 122, 78)
STONE_LT      = (158, 158, 156)
STONE_DK      = (96, 96, 100)
MOSS_DK       = (52, 78, 38)
MOSS_LT       = (96, 138, 70)
INK_FADED     = (60, 40, 24)
SEPIA         = (78, 52, 30)
THATCH_LT     = (200, 162, 90)


SIZE = 1024
SEED = 512  # pinned for byte-stable output (sibling seeds: 206, 307, 411)


def get_font(size, bold=False):
    paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf" if bold
        else "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ]
    for p in paths:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def grain(draw, x0, y0, x1, y1, base_rgb, count=140, jitter=18):
    """THEME §1 'painterly' nod — speckle the fill with +/- jitter brightness."""
    if x1 - x0 < 4 or y1 - y0 < 4:
        return
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


def _aged_parchment_background(draw):
    """Solid PARCHMENT_LT base with browned/scorched edge band and grain."""
    draw.rectangle([0, 0, SIZE, SIZE], fill=PARCHMENT_LT)
    margin = 32
    for step in range(margin):
        t = step / max(1, margin - 1)
        cr = int(PARCHMENT_BRN[0] * (1 - t) + PARCHMENT[0] * t)
        cg = int(PARCHMENT_BRN[1] * (1 - t) + PARCHMENT[1] * t)
        cb = int(PARCHMENT_BRN[2] * (1 - t) + PARCHMENT[2] * t)
        draw.rectangle([step, step, SIZE - 1 - step, SIZE - 1 - step],
                       outline=(cr, cg, cb), width=1)
    grain(draw, 16, 16, SIZE - 16, SIZE - 16, PARCHMENT_LT,
          count=2400, jitter=14)
    for _ in range(900):
        side = random.choice(("t", "b", "l", "r"))
        if side == "t":
            x = random.randint(8, SIZE - 8); y = random.randint(4, 50)
        elif side == "b":
            x = random.randint(8, SIZE - 8); y = random.randint(SIZE - 50, SIZE - 4)
        elif side == "l":
            x = random.randint(4, 50); y = random.randint(8, SIZE - 8)
        else:
            x = random.randint(SIZE - 50, SIZE - 4); y = random.randint(8, SIZE - 8)
        c = random.choice([PARCHMENT_DK, PARCHMENT_BRN, INK_FADED])
        draw.point((x, y), fill=c)


def _scroll_corner_curls(draw):
    r = 26
    for cx, cy in [(r + 8, r + 8), (SIZE - r - 8, r + 8),
                   (r + 8, SIZE - r - 8), (SIZE - r - 8, SIZE - r - 8)]:
        draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                     outline=DARK_WOOD, width=2)
        draw.ellipse([cx - r + 6, cy - r + 6, cx + r - 6, cy + r - 6],
                     outline=HAMMERED_BRONZE, width=1)


def _mountain_ring(draw):
    """THEME §8: distant impassable peaks framing the horizon."""
    # top peaks — primary range, snow caps
    for i in range(14):
        bx = 80 + i * 64
        h = 70 + (i % 3) * 24 + random.randint(-8, 8)
        peak_x = bx + 32 + random.randint(-6, 6)
        draw.polygon([(bx, 110), (peak_x, 110 - h), (bx + 64, 110)],
                     fill=STONE_DK, outline=INK_BLACK)
        draw.polygon([(peak_x - 12, 110 - h + 14), (peak_x, 110 - h),
                      (peak_x + 12, 110 - h + 14)], fill=PARCHMENT_LT)
    # left peaks
    for i in range(8):
        by = 140 + i * 96
        w = 60 + (i % 2) * 18
        peak_y = by + 48 + random.randint(-6, 6)
        draw.polygon([(80, by), (80 + w, peak_y), (80, by + 96)],
                     fill=STONE_GREYBLUE, outline=INK_BLACK)
    # right peaks
    for i in range(8):
        by = 140 + i * 96
        w = 60 + (i % 2) * 18
        peak_y = by + 48 + random.randint(-6, 6)
        draw.polygon([(SIZE - 80, by), (SIZE - 80 - w, peak_y),
                      (SIZE - 80, by + 96)],
                     fill=STONE_GREYBLUE, outline=INK_BLACK)
    # bottom peaks (warmer — sunset-tinted)
    for i in range(14):
        bx = 80 + i * 64
        h = 50 + (i % 3) * 18 + random.randint(-6, 6)
        peak_x = bx + 32 + random.randint(-6, 6)
        col = (min(255, STONE_DK[0] + 20), min(255, STONE_DK[1] + 12),
               STONE_DK[2])
        draw.polygon([(bx, SIZE - 110), (peak_x, SIZE - 110 + h),
                      (bx + 64, SIZE - 110)],
                     fill=col, outline=INK_BLACK)


def _whisperwood_canopy(draw):
    """THEME §8: dense oak/pine forest covering the central band."""
    cx = SIZE // 2 - 20
    cy = SIZE // 2 + 40
    rx, ry = 360, 180
    draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry],
                 fill=MOSS_LT, outline=MOSS_DK, width=2)
    grain(draw, cx - rx + 4, cy - ry + 4, cx + rx - 4, cy + ry - 4,
          MOSS_LT, count=800, jitter=18)
    for _ in range(140):
        px = random.randint(cx - rx + 12, cx + rx - 12)
        py = random.randint(cy - ry + 12, cy + ry - 12)
        nx = (px - cx) / rx
        ny = (py - cy) / ry
        if nx * nx + ny * ny > 0.92:
            continue
        kind = random.choice(("pine", "oak", "oak"))
        if kind == "pine":
            tw = random.randint(8, 12)
            th = random.randint(20, 34)
            for k in range(3):
                top = py - th + k * (th // 3)
                bot = py - th + (k + 1) * (th // 3) + 4
                wfac = 0.55 + 0.20 * k
                draw.polygon(
                    [(px - int(tw * wfac), bot),
                     (px, top),
                     (px + int(tw * wfac), bot)],
                    fill=MOSS_DK, outline=INK_BLACK)
            draw.line([(px, py), (px, py + 4)], fill=DARK_WOOD, width=1)
        else:
            r = random.randint(7, 12)
            draw.ellipse([px - r, py - r, px + r, py - r // 2 + 2],
                         fill=MOSS_DK, outline=INK_BLACK)
            draw.line([(px, py - r // 2 + 2), (px, py + 4)],
                      fill=DARK_WOOD, width=1)


def _crystal_caves(draw):
    """THEME §8: Crystal Caves entrance — cool blue glow, crystal shards.
    Returns (glow_layer, anchor_point) so caller can composite."""
    cx, cy = 800, 280
    draw.polygon(
        [(cx - 60, cy + 40), (cx - 60, cy - 10),
         (cx, cy - 70), (cx + 60, cy - 10), (cx + 60, cy + 40)],
        fill=STONE_DK, outline=INK_BLACK)
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    for layer in range(4):
        a = 70 - layer * 15
        rad = 28 + layer * 14
        gdraw.ellipse([cx - rad, cy - rad // 2, cx + rad, cy + rad // 2],
                      fill=(*FEY_CYAN, a))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=6))
    return glow, (cx, cy)


def _briarwood_marker(draw):
    """THEME §8: cottage glyph + lit windows + smoking chimney."""
    cx, cy = 470, 720
    draw.ellipse([cx - 80, cy - 20, cx + 80, cy + 30],
                 fill=PARCHMENT, outline=PARCHMENT_DK)
    draw.rectangle([cx - 24, cy - 24, cx + 24, cy + 8],
                   fill=LIGHT_WOOD, outline=DARK_WOOD, width=2)
    draw.polygon(
        [(cx - 30, cy - 24), (cx, cy - 50), (cx + 30, cy - 24)],
        fill=THATCH_LT, outline=DARK_WOOD)
    draw.rectangle([cx - 6, cy - 12, cx + 6, cy + 8], fill=DARK_WOOD)
    draw.rectangle([cx - 18, cy - 18, cx - 10, cy - 10], fill=SUNSET_GOLD)
    draw.rectangle([cx + 10, cy - 18, cx + 18, cy - 10], fill=SUNSET_GOLD)
    draw.rectangle([cx + 12, cy - 44, cx + 18, cy - 28], fill=STONE_DK)
    for k in range(3):
        sy = cy - 50 - k * 6
        sx = cx + 15 + k * 2
        draw.ellipse([sx - 4, sy - 4, sx + 4, sy + 4], fill=PARCHMENT_DK)
    fcx, fcy = cx + 56, cy + 4
    draw.ellipse([fcx - 8, fcy - 4, fcx + 8, fcy + 4], fill=DARK_WOOD)
    draw.polygon([(fcx - 5, fcy), (fcx, fcy - 10), (fcx + 5, fcy)],
                 fill=BURNT_ORANGE, outline=WINE_CRIMSON)
    draw.polygon([(fcx - 3, fcy - 2), (fcx, fcy - 6), (fcx + 3, fcy - 2)],
                 fill=SUNSET_GOLD)


def _trail(draw):
    """Dotted trail Briarwood -> through Whisperwood -> Crystal Caves."""
    pts = [
        (470, 720), (510, 660), (560, 600), (620, 540),
        (680, 480), (730, 420), (770, 360), (800, 300),
    ]
    for i in range(len(pts) - 1):
        x0, y0 = pts[i]; x1, y1 = pts[i + 1]
        steps = 8
        for s in range(steps):
            t = s / steps
            px = int(x0 * (1 - t) + x1 * t)
            py = int(y0 * (1 - t) + y1 * t)
            draw.ellipse([px - 2, py - 2, px + 2, py + 2], fill=SEPIA)


def _compass_rose(draw):
    """Hand-drawn compass rose lower-left."""
    cx, cy = 130, 880
    r = 36
    draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                 outline=DARK_WOOD, width=2)
    draw.ellipse([cx - r + 4, cy - r + 4, cx + r - 4, cy + r - 4],
                 outline=HAMMERED_BRONZE, width=1)
    long_r = r - 6
    short_r = (r - 6) // 3
    pts = []
    for i in range(8):
        ang = math.radians(i * 45 - 90)
        d = long_r if i % 2 == 0 else short_r
        pts.append((cx + math.cos(ang) * d, cy + math.sin(ang) * d))
    draw.polygon(pts, fill=PARCHMENT_DK, outline=INK_BLACK)
    n_pts = [
        (cx, cy - long_r),
        (cx - short_r, cy),
        (cx, cy - short_r // 2),
        (cx + short_r, cy),
    ]
    draw.polygon(n_pts, fill=WINE_CRIMSON, outline=INK_BLACK)
    f = get_font(13, bold=True)
    for label, dx, dy in [("N", 0, -r - 14), ("S", 0, r + 2),
                          ("E", r + 2, -7), ("W", -r - 12, -7)]:
        draw.text((cx + dx, cy + dy), label, fill=INK_BLACK, font=f)


def _label(draw, x, y, text, size=20, bold=True, fill=SEPIA, anchor="mm"):
    """Sepia serif label with parchment backing for legibility."""
    f = get_font(size, bold=bold)
    bbox = draw.textbbox((0, 0), text, font=f)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    if anchor == "mm":
        tx, ty = x - tw // 2, y - th // 2
    elif anchor == "lm":
        tx, ty = x, y - th // 2
    else:
        tx, ty = x, y
    pad_x, pad_y = 4, 1
    draw.rectangle([tx - pad_x, ty - pad_y,
                    tx + tw + pad_x, ty + th + pad_y],
                   fill=PARCHMENT)
    draw.rectangle([tx - pad_x, ty - pad_y,
                    tx + tw + pad_x, ty + th + pad_y],
                   outline=PARCHMENT_DK, width=1)
    draw.text((tx, ty), text, fill=fill, font=f)


def _title_cartouche(draw):
    """Top-of-page title plaque with serif title (DejaVuSerif as §5 proxy)."""
    x0, y0, x1, y1 = 230, 30, SIZE - 230, 92
    draw.rectangle([x0, y0, x1, y1],
                   fill=PARCHMENT, outline=DARK_WOOD, width=2)
    draw.rectangle([x0 + 4, y0 + 4, x1 - 4, y1 - 4],
                   outline=HAMMERED_BRONZE, width=1)
    for fx in (x0 + 18, x1 - 18):
        cy = (y0 + y1) // 2
        draw.polygon(
            [(fx, cy - 6), (fx + 8, cy), (fx, cy + 6), (fx - 8, cy)],
            fill=WINE_CRIMSON, outline=DARK_WOOD)
    f_title = get_font(28, bold=True)
    title = "ELDORIA"
    bbox = draw.textbbox((0, 0), title, font=f_title)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    cx = (x0 + x1) // 2
    cy = (y0 + y1) // 2
    draw.text((cx - tw // 2, cy - th // 2 - 8), title,
              fill=INK_BLACK, font=f_title)
    f_sub = get_font(13)
    sub = "Hand-painted World Map  -  Briarwood / Whisperwood / Crystal Caves"
    bbox2 = draw.textbbox((0, 0), sub, font=f_sub)
    sw = bbox2[2] - bbox2[0]
    sh = bbox2[3] - bbox2[1]
    draw.text((cx - sw // 2, cy - sh // 2 + 16), sub,
              fill=SEPIA, font=f_sub)


def _footer(draw):
    f = get_font(11)
    txt = ("THEME paragraph 3/8 - Briarwood (forest edge) "
           "- Whisperwood (oak/pine canopy) "
           "- Crystal Caves (cool fey-cyan glow) "
           "- Mountain Ring (impassable peaks)")
    bbox = draw.textbbox((0, 0), txt, font=f)
    tw = bbox[2] - bbox[0]
    cx = SIZE // 2
    draw.text((cx - tw // 2, SIZE - 28), txt, fill=SEPIA, font=f)


def _scale_bar(draw):
    x0, y = 760, 880
    seg = 30
    for i in range(4):
        col = INK_BLACK if i % 2 == 0 else PARCHMENT
        draw.rectangle([x0 + i * seg, y, x0 + (i + 1) * seg, y + 10],
                       fill=col, outline=INK_BLACK)
    f = get_font(11)
    draw.text((x0, y + 14), "1 day's march", fill=SEPIA, font=f)


def render():
    random.seed(SEED)
    img = Image.new("RGB", (SIZE, SIZE), PARCHMENT_LT)
    draw = ImageDraw.Draw(img)

    _aged_parchment_background(draw)
    _scroll_corner_curls(draw)
    _mountain_ring(draw)
    _whisperwood_canopy(draw)
    glow, cave_pt = _crystal_caves(draw)
    img.paste(glow, (0, 0), glow)
    draw = ImageDraw.Draw(img)
    _briarwood_marker(draw)
    _trail(draw)
    _title_cartouche(draw)
    _compass_rose(draw)
    _scale_bar(draw)
    _footer(draw)

    _label(draw, SIZE // 2, 144, "MOUNTAIN  RING", size=20, fill=INK_BLACK)
    _label(draw, SIZE // 2 - 20, SIZE // 2 - 100, "WHISPERWOOD",
           size=22, fill=INK_BLACK)
    _label(draw, cave_pt[0], cave_pt[1] + 70, "Crystal Caves",
           size=16, fill=INK_BLACK)
    _label(draw, 470, 770, "Briarwood Village", size=15, fill=INK_BLACK)
    _label(draw, SIZE // 2, SIZE - 110,
           "( Mountain Ring continues - impassable )", size=12, fill=SEPIA)

    for _ in range(60):
        side = random.choice(("t", "b", "l", "r"))
        if side == "t":
            x = random.randint(40, SIZE - 40); y = random.randint(2, 18)
            draw.line([(x, y), (x + random.randint(-3, 3), y + 4)],
                      fill=INK_FADED, width=1)
        elif side == "b":
            x = random.randint(40, SIZE - 40); y = random.randint(SIZE - 18, SIZE - 2)
            draw.line([(x, y), (x + random.randint(-3, 3), y - 4)],
                      fill=INK_FADED, width=1)
        elif side == "l":
            x = random.randint(2, 18); y = random.randint(40, SIZE - 40)
            draw.line([(x, y), (x + 4, y + random.randint(-3, 3))],
                      fill=INK_FADED, width=1)
        else:
            x = random.randint(SIZE - 18, SIZE - 2); y = random.randint(40, SIZE - 40)
            draw.line([(x, y), (x - 4, y + random.randint(-3, 3))],
                      fill=INK_FADED, width=1)

    out = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "world_map_sketch.png")
    img.save(out, "PNG", optimize=True)
    return out


if __name__ == "__main__":
    path = render()
    print(f"wrote {path}")
