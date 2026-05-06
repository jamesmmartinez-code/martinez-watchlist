#!/usr/bin/env python3
"""
mood-boards/_gen_architecture_palette.py — Eldoria architecture mood board.

THEME.md anchor: §1 painterly hand-painted, §3 palette, §8 timber/stone/thatch
medieval architecture. Schematic elevations of the six structure archetypes
that appear in Builder/Environment runs (Briarwood cottage, Briarwood inn,
Smithy, Whisperwood goblin tent, Crystal Caves entrance arch, Mountain Ring
watch-tower).

Pattern follows mood-boards/_generate.py — Pillow-only, pinned random.seed,
byte-stable on re-run. THEME §3 colours imported verbatim from _generate.py.

Usage:
    python3 mood-boards/_gen_architecture_palette.py
"""
from PIL import Image, ImageDraw, ImageFont
import os, random, math


def hex_to_rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


# ── THEME §3 canon palette (mirrored from mood-boards/_generate.py) ────────
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
WARLOCK_PURPLE  = hex_to_rgb("7C3FB0")

# Derivative tones — explicit palette band, no new canonical hues.
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
GOBLIN_GREEN = (96, 122, 64)
HIDE_TAN    = (146, 110, 76)
CRYSTAL_LT  = (180, 230, 240)


def get_font(size, bold=False):
    paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ]
    for p in paths:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def grain(img, draw, x0, y0, x1, y1, base_rgb, count=140, jitter=18):
    """THEME §1 painterly speckle — same fn signature as _generate.py."""
    r, g, b = base_rgb
    for _ in range(count):
        rx = random.randint(int(x0) + 1, int(x1) - 1)
        ry = random.randint(int(y0) + 1, int(y1) - 1)
        br = random.randint(-jitter, jitter)
        draw.point((rx, ry), fill=(
            max(0, min(255, r + br)),
            max(0, min(255, g + br)),
            max(0, min(255, b + br)),
        ))


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


# ── Building elevations ────────────────────────────────────────────────────

def _draw_briarwood_cottage(draw, img, cx, cy):
    """Single-story timber-frame, thatched roof — the village staple."""
    # foundation stone
    draw.rectangle([cx - 90, cy + 60, cx + 90, cy + 88], fill=STONE_LT, outline=INK_BLACK, width=2)
    grain(img, draw, cx - 88, cy + 62, cx + 88, cy + 86, STONE_LT, count=80, jitter=14)
    # main wall (daub between timbers)
    draw.rectangle([cx - 86, cy - 10, cx + 86, cy + 60], fill=PARCHMENT, outline=INK_BLACK, width=2)
    grain(img, draw, cx - 84, cy - 8, cx + 84, cy + 58, PARCHMENT, count=120, jitter=10)
    # vertical timbers
    for px in (cx - 86, cx - 28, cx + 28, cx + 86):
        draw.rectangle([px - 4, cy - 10, px + 4, cy + 60], fill=DARK_WOOD, outline=INK_BLACK, width=1)
    # cross-brace timbers
    draw.line([(cx - 86, cy + 60), (cx - 28, cy - 10)], fill=DARK_WOOD, width=3)
    draw.line([(cx + 28, cy - 10), (cx + 86, cy + 60)], fill=DARK_WOOD, width=3)
    draw.line([(cx - 86, cy + 25), (cx + 86, cy + 25)], fill=DARK_WOOD, width=2)
    # door
    draw.rectangle([cx - 14, cy + 14, cx + 14, cy + 60], fill=DARK_WOOD, outline=INK_BLACK, width=2)
    draw.line([(cx, cy + 14), (cx, cy + 60)], fill=INK_BLACK, width=1)
    draw.ellipse([cx + 6, cy + 35, cx + 11, cy + 40], fill=HAMMERED_BRONZE)
    # window with lit candle
    draw.rectangle([cx - 64, cy + 4, cx - 38, cy + 24], fill=SUNSET_GOLD, outline=INK_BLACK, width=2)
    draw.line([(cx - 51, cy + 4), (cx - 51, cy + 24)], fill=INK_BLACK, width=1)
    draw.line([(cx - 64, cy + 14), (cx - 38, cy + 14)], fill=INK_BLACK, width=1)
    # thatched roof
    roof = [(cx - 100, cy - 10), (cx, cy - 78), (cx + 100, cy - 10)]
    draw.polygon(roof, fill=THATCH_DK, outline=INK_BLACK)
    # thatch rake lines
    for i in range(-9, 10):
        x_top = cx + i * 10
        y_off = abs(i) * 6.4
        draw.line([(x_top, cy - 78 + y_off + 4), (x_top + 4, cy - 10)], fill=THATCH_LT, width=1)
    grain(img, draw, cx - 96, cy - 70, cx + 96, cy - 12, THATCH_DK, count=180, jitter=14)
    # ridge cap
    draw.line([(cx - 12, cy - 78), (cx + 12, cy - 78)], fill=DARK_WOOD, width=4)
    # chimney smoke (small)
    draw.rectangle([cx + 38, cy - 56, cx + 50, cy - 18], fill=STONE_DK, outline=INK_BLACK, width=2)
    for s in range(3):
        sx = cx + 44 + s * 3
        draw.ellipse([sx - 5 - s, cy - 70 - s * 8, sx + 5 + s, cy - 60 - s * 8],
                     outline=STONE_GREYBLUE, width=1)


def _draw_smithy(draw, img, cx, cy):
    """Stocky stone smithy with forge glow + open-air work area."""
    # stone foundation, full height (smithies are stone for fire safety)
    draw.rectangle([cx - 96, cy - 30, cx + 96, cy + 88], fill=STONE_LT, outline=INK_BLACK, width=2)
    grain(img, draw, cx - 94, cy - 28, cx + 94, cy + 86, STONE_LT, count=180, jitter=14)
    # mortar lines
    for r in range(4):
        y = cy - 30 + 24 * r
        draw.line([(cx - 96, y), (cx + 96, y)], fill=STONE_DK, width=1)
        for c in range(7):
            xo = (r % 2) * 14
            draw.line([(cx - 96 + xo + c * 28, y), (cx - 96 + xo + c * 28, y + 24)],
                      fill=STONE_DK, width=1)
    # open forge opening — glow
    draw.rectangle([cx - 38, cy + 12, cx + 38, cy + 70], fill=INK_BLACK, outline=INK_BLACK, width=2)
    # forge fire (concentric warm rings)
    for ring, col in ((22, WINE_CRIMSON), (16, BURNT_ORANGE), (10, SUNSET_GOLD), (5, FLAME_HOT)):
        draw.ellipse([cx - ring, cy + 40 - ring // 2, cx + ring, cy + 40 + ring // 2], fill=col)
    # anvil silhouette in front
    draw.polygon([(cx - 22, cy + 60), (cx + 22, cy + 60), (cx + 16, cy + 70), (cx - 16, cy + 70)],
                 fill=IRON_DK, outline=INK_BLACK)
    draw.rectangle([cx - 6, cy + 70, cx + 6, cy + 86], fill=DARK_WOOD, outline=INK_BLACK, width=1)
    # roof — heavy timber ridge with shingle/thatch
    roof = [(cx - 110, cy - 30), (cx, cy - 92), (cx + 110, cy - 30)]
    draw.polygon(roof, fill=THATCH_DK, outline=INK_BLACK)
    for i in range(-10, 11):
        x_top = cx + i * 10
        y_off = abs(i) * 6.2
        draw.line([(x_top, cy - 92 + y_off + 4), (x_top + 4, cy - 30)], fill=THATCH_LT, width=1)
    grain(img, draw, cx - 104, cy - 84, cx + 104, cy - 32, THATCH_DK, count=160, jitter=14)
    # large stone chimney with billowing smoke (smithy is busy)
    draw.rectangle([cx - 78, cy - 70, cx - 56, cy - 20], fill=STONE_DK, outline=INK_BLACK, width=2)
    grain(img, draw, cx - 76, cy - 68, cx - 58, cy - 22, STONE_DK, count=80, jitter=12)
    # plumes
    for s in range(5):
        sx = cx - 67 + s * 2
        sy = cy - 80 - s * 12
        draw.ellipse([sx - 8 - s, sy - 5 - s, sx + 10 + s, sy + 7 + s],
                     outline=STONE_GREYBLUE, width=1)
    # ember spark
    draw.ellipse([cx - 2, cy + 36, cx + 2, cy + 40], fill=FLAME_HOT)


def _draw_inn(draw, img, cx, cy):
    """Two-story timber-frame Innkeeper Bram's place — bigger, sign hung out."""
    # ground floor
    draw.rectangle([cx - 100, cy + 26, cx + 100, cy + 88], fill=PARCHMENT, outline=INK_BLACK, width=2)
    grain(img, draw, cx - 98, cy + 28, cx + 98, cy + 86, PARCHMENT, count=120, jitter=10)
    # second floor — slight overhang
    draw.rectangle([cx - 108, cy - 22, cx + 108, cy + 26], fill=PARCHMENT, outline=INK_BLACK, width=2)
    grain(img, draw, cx - 106, cy - 20, cx + 106, cy + 24, PARCHMENT, count=120, jitter=10)
    # vertical timbers — first floor
    for px in (cx - 100, cx - 50, cx + 50, cx + 100):
        draw.rectangle([px - 4, cy + 26, px + 4, cy + 88], fill=DARK_WOOD, outline=INK_BLACK, width=1)
    # vertical timbers — second floor
    for px in (cx - 108, cx - 36, cx + 36, cx + 108):
        draw.rectangle([px - 4, cy - 22, px + 4, cy + 26], fill=DARK_WOOD, outline=INK_BLACK, width=1)
    # cross-brace
    draw.line([(cx - 50, cy + 26), (cx + 50, cy + 88)], fill=DARK_WOOD, width=3)
    draw.line([(cx + 50, cy + 26), (cx - 50, cy + 88)], fill=DARK_WOOD, width=3)
    draw.line([(cx - 108, cy + 4), (cx + 108, cy + 4)], fill=DARK_WOOD, width=2)
    # double door — wider for the inn
    draw.rectangle([cx - 22, cy + 38, cx + 22, cy + 88], fill=DARK_WOOD, outline=INK_BLACK, width=2)
    draw.line([(cx, cy + 38), (cx, cy + 88)], fill=INK_BLACK, width=1)
    draw.ellipse([cx - 14, cy + 60, cx - 9, cy + 65], fill=HAMMERED_BRONZE)
    draw.ellipse([cx + 9, cy + 60, cx + 14, cy + 65], fill=HAMMERED_BRONZE)
    # glowing windows ground floor
    for wx in (cx - 70, cx + 56):
        draw.rectangle([wx - 10, cy + 38, wx + 10, cy + 64], fill=SUNSET_GOLD, outline=INK_BLACK, width=2)
        draw.line([(wx, cy + 38), (wx, cy + 64)], fill=INK_BLACK, width=1)
        draw.line([(wx - 10, cy + 51), (wx + 10, cy + 51)], fill=INK_BLACK, width=1)
    # second floor windows (smaller, also lit)
    for wx in (cx - 70, cx, cx + 70):
        draw.rectangle([wx - 8, cy - 12, wx + 8, cy + 12], fill=SUNSET_GOLD, outline=INK_BLACK, width=2)
        draw.line([(wx, cy - 12), (wx, cy + 12)], fill=INK_BLACK, width=1)
    # gabled roof
    roof = [(cx - 116, cy - 22), (cx, cy - 88), (cx + 116, cy - 22)]
    draw.polygon(roof, fill=THATCH_DK, outline=INK_BLACK)
    for i in range(-11, 12):
        x_top = cx + i * 10
        y_off = abs(i) * 6.0
        draw.line([(x_top, cy - 88 + y_off + 4), (x_top + 4, cy - 22)], fill=THATCH_LT, width=1)
    grain(img, draw, cx - 110, cy - 80, cx + 110, cy - 24, THATCH_DK, count=180, jitter=14)
    # hanging sign — wrought iron bracket + parchment-painted board
    draw.line([(cx + 116, cy - 4), (cx + 138, cy - 4)], fill=IRON_DK, width=2)
    draw.line([(cx + 138, cy - 4), (cx + 138, cy + 30)], fill=IRON_DK, width=2)
    draw.line([(cx + 134, cy + 16), (cx + 142, cy + 16)], fill=IRON_DK, width=1)
    draw.rectangle([cx + 124, cy + 18, cx + 152, cy + 46], fill=DARK_WOOD, outline=INK_BLACK, width=2)
    draw.rectangle([cx + 127, cy + 21, cx + 149, cy + 43], fill=PARCHMENT, outline=HAMMERED_BRONZE, width=1)
    # mug glyph on sign
    draw.rectangle([cx + 134, cy + 27, cx + 142, cy + 38], fill=HAMMERED_BRONZE, outline=INK_BLACK, width=1)
    draw.line([(cx + 142, cy + 30), (cx + 145, cy + 32)], fill=INK_BLACK, width=1)


def _draw_goblin_tent(draw, img, cx, cy):
    """Whisperwood goblin tent — hide stretched over crude poles, skull on stake."""
    # ground stamp
    draw.ellipse([cx - 82, cy + 78, cx + 82, cy + 92], fill=DARK_WOOD)
    # main hide drape (asymmetric)
    tent_pts = [(cx - 70, cy + 84), (cx - 56, cy + 14), (cx - 8, cy - 56),
                (cx + 30, cy - 36), (cx + 64, cy + 22), (cx + 80, cy + 84)]
    draw.polygon(tent_pts, fill=HIDE_TAN, outline=INK_BLACK)
    grain(img, draw, cx - 66, cy - 50, cx + 76, cy + 80, HIDE_TAN, count=200, jitter=18)
    # stitch lines (irregular)
    for sy in (-30, 0, 30, 60):
        draw.line([(cx - 50, cy + sy), (cx + 60, cy + sy + 4)], fill=DARK_WOOD, width=1)
    # tear / patch
    patch = [(cx + 18, cy + 6), (cx + 38, cy - 4), (cx + 32, cy + 24), (cx + 12, cy + 18)]
    draw.polygon(patch, fill=DARK_WOOD, outline=INK_BLACK)
    # support poles poking through top
    draw.line([(cx - 8, cy - 56), (cx - 14, cy - 86)], fill=DARK_WOOD, width=3)
    draw.line([(cx + 30, cy - 36), (cx + 38, cy - 70)], fill=DARK_WOOD, width=3)
    # tent flap entrance — dark slit
    flap = [(cx - 18, cy + 32), (cx + 6, cy + 18), (cx + 14, cy + 84), (cx - 12, cy + 84)]
    draw.polygon(flap, fill=INK_BLACK)
    # crude red banner-ish rag tied to a pole
    draw.line([(cx - 80, cy + 84), (cx - 92, cy - 30)], fill=DARK_WOOD, width=3)
    rag = [(cx - 92, cy - 26), (cx - 76, cy - 30), (cx - 70, cy - 8), (cx - 86, cy - 4)]
    draw.polygon(rag, fill=STAG_BLOOD, outline=INK_BLACK)
    grain(img, draw, cx - 90, cy - 28, cx - 72, cy - 6, STAG_BLOOD, count=40, jitter=16)
    # bone fetish on stake (skull silhouette — schematic, child-safe per §7)
    draw.line([(cx + 80, cy + 84), (cx + 84, cy + 18)], fill=DARK_WOOD, width=3)
    draw.ellipse([cx + 76, cy + 4, cx + 96, cy + 22], fill=PARCHMENT, outline=INK_BLACK, width=2)
    # two eye sockets
    draw.ellipse([cx + 80, cy + 10, cx + 84, cy + 14], fill=INK_BLACK)
    draw.ellipse([cx + 88, cy + 10, cx + 92, cy + 14], fill=INK_BLACK)
    # campfire embers in front
    draw.ellipse([cx - 24, cy + 80, cx + 12, cy + 92], fill=DARK_WOOD, outline=INK_BLACK)
    for ring, col in ((10, WINE_CRIMSON), (6, BURNT_ORANGE), (3, SUNSET_GOLD)):
        draw.ellipse([cx - 6 - ring, cy + 84 - ring // 2, cx - 6 + ring, cy + 84 + ring // 2], fill=col)


def _draw_crystal_arch(draw, img, cx, cy):
    """Crystal Caves entrance — stone arch with cyan glow + crystal shards."""
    # mountain stone backdrop
    backdrop = [(cx - 110, cy + 88), (cx - 92, cy - 60), (cx - 50, cy - 90),
                (cx + 50, cy - 90), (cx + 92, cy - 60), (cx + 110, cy + 88)]
    draw.polygon(backdrop, fill=STONE_DK, outline=INK_BLACK)
    grain(img, draw, cx - 106, cy - 80, cx + 106, cy + 86, STONE_DK, count=240, jitter=14)
    # mossy stone highlights
    for _ in range(40):
        rx = cx + random.randint(-90, 90)
        ry = cy + random.randint(-50, 80)
        draw.ellipse([rx - 3, ry - 2, rx + 3, ry + 2], fill=FOREST_MOSS)
    # archway opening — pointed gothic-cave shape
    arch = [(cx - 44, cy + 88), (cx - 44, cy - 10), (cx - 28, cy - 38),
            (cx, cy - 56), (cx + 28, cy - 38), (cx + 44, cy - 10), (cx + 44, cy + 88)]
    draw.polygon(arch, fill=INK_BLACK)
    # cyan glow inner halo
    for off, alpha_col in ((6, (60, 120, 130)), (12, (40, 90, 100)), (18, (28, 60, 70))):
        glow = [(cx - 44 - off, cy + 88), (cx - 44 - off, cy - 10),
                (cx - 28 - off // 2, cy - 38 - off // 2),
                (cx, cy - 56 - off),
                (cx + 28 + off // 2, cy - 38 - off // 2),
                (cx + 44 + off, cy - 10),
                (cx + 44 + off, cy + 88)]
        draw.polygon(glow, outline=alpha_col)
    # cyan light at the very back of the cave
    draw.ellipse([cx - 16, cy - 18, cx + 16, cy + 14], fill=FEY_CYAN)
    draw.ellipse([cx - 8, cy - 10, cx + 8, cy + 6], fill=CRYSTAL_LT)
    # carved keystone runes
    draw.rectangle([cx - 14, cy - 60, cx + 14, cy - 44], fill=STONE_LT, outline=INK_BLACK, width=2)
    for rx in (cx - 8, cx, cx + 8):
        draw.line([(rx, cy - 56), (rx, cy - 48)], fill=INK_BLACK, width=1)
        draw.line([(rx - 2, cy - 52), (rx + 2, cy - 52)], fill=INK_BLACK, width=1)
    # crystal shards growing from rim
    crystals = [(cx - 60, cy + 30, FEY_CYAN), (cx + 64, cy + 50, CRYSTAL_LT),
                (cx - 70, cy - 6, FEY_CYAN), (cx + 74, cy - 14, FEY_CYAN),
                (cx - 30, cy + 86, CRYSTAL_LT), (cx + 38, cy + 88, FEY_CYAN)]
    for sx, sy, col in crystals:
        draw.polygon([(sx - 4, sy + 8), (sx, sy - 12), (sx + 4, sy + 8)],
                     fill=col, outline=INK_BLACK)
    # ground rubble in foreground
    for _ in range(8):
        rx = cx + random.randint(-70, 70)
        ry = cy + random.randint(82, 92)
        draw.ellipse([rx - 5, ry - 2, rx + 5, ry + 2], fill=STONE_LT, outline=INK_BLACK)


def _draw_watchtower(draw, img, cx, cy):
    """Mountain Ring stone watchtower — distant landmark per §8 architecture."""
    # base
    draw.rectangle([cx - 50, cy + 30, cx + 50, cy + 88], fill=STONE_DK, outline=INK_BLACK, width=2)
    grain(img, draw, cx - 48, cy + 32, cx + 48, cy + 86, STONE_DK, count=80, jitter=14)
    # tower body — slightly tapered
    body = [(cx - 44, cy + 30), (cx - 38, cy - 56), (cx + 38, cy - 56), (cx + 44, cy + 30)]
    draw.polygon(body, fill=STONE_LT, outline=INK_BLACK)
    grain(img, draw, cx - 42, cy - 50, cx + 42, cy + 28, STONE_LT, count=160, jitter=14)
    # mortar courses
    for r in range(7):
        y = cy + 24 - r * 12
        x_lo = cx - 44 + (r * 1)
        x_hi = cx + 44 - (r * 1)
        draw.line([(x_lo, y), (x_hi, y)], fill=STONE_DK, width=1)
    # arrow-slit window
    draw.rectangle([cx - 4, cy - 30, cx + 4, cy - 6], fill=INK_BLACK)
    draw.rectangle([cx - 2, cy - 28, cx + 2, cy - 8], fill=SUNSET_GOLD)
    # crenellated parapet — two-tier
    parapet_y = cy - 56
    draw.rectangle([cx - 50, parapet_y - 14, cx + 50, parapet_y], fill=STONE_DK, outline=INK_BLACK, width=2)
    for cx_c in range(cx - 46, cx + 50, 12):
        draw.rectangle([cx_c, parapet_y - 24, cx_c + 6, parapet_y - 14],
                       fill=STONE_DK, outline=INK_BLACK, width=1)
    # banner pole
    draw.line([(cx + 16, parapet_y - 28), (cx + 16, parapet_y - 70)], fill=DARK_WOOD, width=2)
    flag = [(cx + 16, parapet_y - 68), (cx + 44, parapet_y - 64),
            (cx + 38, parapet_y - 56), (cx + 16, parapet_y - 56)]
    draw.polygon(flag, fill=WINE_CRIMSON, outline=INK_BLACK)
    grain(img, draw, cx + 18, parapet_y - 66, cx + 42, parapet_y - 58, WINE_CRIMSON, count=24, jitter=14)
    # window glow at top of tower
    draw.rectangle([cx - 18, parapet_y - 8, cx - 8, parapet_y - 2], fill=SUNSET_GOLD)
    draw.rectangle([cx + 6, parapet_y - 8, cx + 16, parapet_y - 2], fill=SUNSET_GOLD)
    # mountain silhouettes behind (very distant)
    for off, col in ((90, STONE_GREYBLUE), (60, STONE_DK)):
        peaks = [(cx - off - 20, cy + 30), (cx - off + 6, cy - 20), (cx, cy + 30)]
        draw.polygon(peaks, fill=col, outline=INK_BLACK)
        peaks2 = [(cx, cy + 30), (cx + off - 4, cy - 14), (cx + off + 22, cy + 30)]
        draw.polygon(peaks2, fill=col, outline=INK_BLACK)


# ── Main render ────────────────────────────────────────────────────────────

def render_architecture_palette():
    random.seed(206)  # pinned for byte-stable output (run-27)
    W, H = 1024, 1024
    img = Image.new("RGB", (W, H), PARCHMENT)
    draw = ImageDraw.Draw(img)

    # parchment grain
    for _ in range(2400):
        rx = random.randint(0, W - 1); ry = random.randint(0, H - 1)
        br = random.randint(-10, 6); r, g, b = PARCHMENT
        draw.point((rx, ry), fill=(max(0, min(255, r + br)),
                                   max(0, min(255, g + br)),
                                   max(0, min(255, b + br))))

    # header bar
    draw.rectangle([0, 0, W, 110], fill=DARK_WOOD, outline=INK_BLACK, width=2)
    grain(img, draw, 4, 4, W - 4, 106, DARK_WOOD, count=420, jitter=12)

    f_title = get_font(38, True)
    f_sub = get_font(18)
    f_lbl = get_font(15, True)
    f_caption = get_font(13)

    draw.text((30, 22), "ELDORIA — ARCHITECTURE PALETTE", fill=PARCHMENT, font=f_title)
    draw.text((30, 70),
              "THEME.md §1 painterly / §3 palette / §8 timber-stone-thatch. "
              "Match these silhouettes when modeling structures.",
              fill=THATCH_LT, font=f_sub)

    # footer
    draw.rectangle([0, H - 50, W, H], fill=DARK_WOOD, outline=INK_BLACK, width=2)
    grain(img, draw, 4, H - 46, W - 4, H - 4, DARK_WOOD, count=200, jitter=12)
    draw.text((30, H - 38),
              "auto/art — generated procedurally by mood-boards/_gen_architecture_palette.py.",
              fill=THATCH_LT, font=f_caption)
    draw.text((30, H - 20),
              "Mood board panel — cite when sourcing or modeling Eldoria structures.",
              fill=THATCH_LT, font=f_caption)

    # 2x3 grid of structures
    grid_top = 130
    grid_bot = H - 60
    cols, rows = 3, 2
    cell_w = (W - 60) // cols
    cell_h = (grid_bot - grid_top - 30) // rows
    margin_x = 20
    margin_y = 14

    structures = [
        ("BRIARWOOD COTTAGE", _draw_briarwood_cottage),
        ("THE INN",           _draw_inn),
        ("SMITHY (EDDA)",     _draw_smithy),
        ("GOBLIN TENT",       _draw_goblin_tent),
        ("CRYSTAL CAVE ARCH", _draw_crystal_arch),
        ("MOUNTAIN WATCHTOWER", _draw_watchtower),
    ]

    for idx, (label, drawer) in enumerate(structures):
        col = idx % cols
        row = idx // cols
        x0 = 30 + col * cell_w
        y0 = grid_top + row * cell_h
        x1 = x0 + cell_w - margin_x
        y1 = y0 + cell_h - margin_y
        _cell_frame(draw, x0, y0, x1, y1, label, f_lbl)
        cx = (x0 + x1) // 2
        # cy positions silhouette nicely above the bottom plate
        cy = (y0 + y1) // 2 - 8
        drawer(draw, img, cx, cy)

    # column-divider footnote bands
    draw.text((40, grid_bot + 6),
              "Briarwood timber & thatch — sunset-warm, lit windows, painted door.",
              fill=DARK_WOOD, font=f_caption)
    draw.text((40, grid_bot + 22),
              "Goblin / cave / watchtower — colder palette, used 30%-of-frame max.",
              fill=DARK_WOOD, font=f_caption)

    out_dir = os.path.dirname(os.path.abspath(__file__))
    out_path = os.path.join(out_dir, "architecture_palette.png")
    img.save(out_path, "PNG", optimize=True)
    print(f"Wrote {out_path} ({os.path.getsize(out_path)} bytes)")


if __name__ == "__main__":
    render_architecture_palette()
