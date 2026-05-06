#!/usr/bin/env python3
"""
mood-boards/_gen_magic_glow_reference.py — Eldoria magic glow reference.

THEME.md anchor: §3 "Magic / accent (10% — used sparingly)" — fey cyan
(#65DFE5), warlock purple (#7C3FB0), frost-pale silver (#C8E0E5). §1 cool
tones reserved for night, mist, magic. §4 boss / spell auras. §5 painterly
look — soft Gaussian rims, no crisp vector edges.

Schematic mood-board cell-grid showing the three canonical magic hues at
three calibrated intensities (low / medium / high) against a dusk
background, so VFX/Lighting agents can pick a target hue+intensity
combination by name instead of guessing pixels each run.

Pattern follows mood-boards/_generate.py and
mood-boards/_gen_architecture_palette.py — Pillow-only, pinned random.seed,
byte-stable on re-run. THEME §3 colours imported verbatim from
_generate.py.

Usage:
    python3 mood-boards/_gen_magic_glow_reference.py
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
import random


def hex_to_rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


# THEME canon palette (mirrored from mood-boards/_generate.py)
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
FROST_SILVER    = hex_to_rgb("C8E0E5")

# Derivative tones — explicit palette band, no new canonical hues.
DARK_WOOD   = (84, 56, 32)
MID_WOOD    = (138, 92, 50)
LIGHT_WOOD  = (190, 142, 86)
THATCH_LT   = (200, 162, 90)
THATCH_DK   = (138, 102, 48)
STONE_LT    = (158, 158, 156)
STONE_DK    = (96, 96, 100)

# Dusk background band: deep indigo top, warlock-shaded mid, wine-warm
# horizon, moss-shadow ground. THEME §1 cool-tones-for-magic-only is
# satisfied because the warm-band horizon stays dominant in the lower
# third of each swatch.
DUSK_TOP    = (38, 32, 56)
DUSK_MID    = (62, 44, 70)
DUSK_HORIZ  = (110, 64, 68)
GROUND_DK   = (28, 32, 26)


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
    """Same parchment-and-bronze cell frame used by the architecture board."""
    draw.rectangle([x0, y0, x1, y1], fill=PARCHMENT, outline=DARK_WOOD, width=3)
    draw.rectangle([x0 + 6, y0 + 6, x1 - 6, y1 - 6], outline=HAMMERED_BRONZE, width=1)
    plate_h = 28
    draw.rectangle([x0 + 6, y1 - plate_h - 6, x1 - 6, y1 - 6],
                   fill=DARK_WOOD, outline=HAMMERED_BRONZE, width=1)
    bbox = draw.textbbox((0, 0), label, font=font_label)
    tw = bbox[2] - bbox[0]
    cx = (x0 + x1) // 2
    draw.text((cx - tw // 2, y1 - plate_h - 2), label, fill=PARCHMENT, font=font_label)


def _fill_dusk(img, draw, x0, y0, x1, y1):
    """Vertical dusk gradient inside a swatch — sky -> mid -> horizon
    afterglow -> ground moss-shadow ridge."""
    h = max(1, y1 - y0)
    sky_top   = y0
    sky_mid   = y0 + int(h * 0.45)
    sky_horiz = y0 + int(h * 0.78)
    ground    = y0 + int(h * 0.88)

    for y in range(sky_top, sky_mid):
        t = (y - sky_top) / max(1, sky_mid - sky_top)
        r = int(DUSK_TOP[0] + (DUSK_MID[0] - DUSK_TOP[0]) * t)
        g = int(DUSK_TOP[1] + (DUSK_MID[1] - DUSK_TOP[1]) * t)
        b = int(DUSK_TOP[2] + (DUSK_MID[2] - DUSK_TOP[2]) * t)
        draw.line([(x0, y), (x1, y)], fill=(r, g, b))

    for y in range(sky_mid, sky_horiz):
        t = (y - sky_mid) / max(1, sky_horiz - sky_mid)
        r = int(DUSK_MID[0] + (DUSK_HORIZ[0] - DUSK_MID[0]) * t)
        g = int(DUSK_MID[1] + (DUSK_HORIZ[1] - DUSK_MID[1]) * t)
        b = int(DUSK_MID[2] + (DUSK_HORIZ[2] - DUSK_MID[2]) * t)
        draw.line([(x0, y), (x1, y)], fill=(r, g, b))

    draw.rectangle([x0, sky_horiz, x1, ground], fill=DUSK_HORIZ)
    grain(img, draw, x0, sky_horiz, x1, ground, DUSK_HORIZ, count=60, jitter=10)

    draw.rectangle([x0, ground, x1, y1], fill=GROUND_DK)
    grain(img, draw, x0, ground, x1, y1, GROUND_DK, count=80, jitter=10)

    # silhouette tree-line ridge so the player has a sense of distance
    ridge_pts = []
    for s in range(11):
        rx = x0 + int(s * (x1 - x0) / 10)
        rh = 8 + ((s * 31) % 10)
        ridge_pts.append((rx, ground - rh))
    poly = [(x0, ground)] + ridge_pts + [(x1, ground)]
    draw.polygon(poly, fill=GROUND_DK)


def _draw_glow(img, hue, cx, cy, radius, intensity):
    """Soft additive radial glow — THEME §5 'painterly, hand-painted look,
    not crisp vector'. Layered ellipses then GaussianBlur for a soft rim,
    composited onto the dusk-painted base image. `intensity` in [0,1]."""
    W, H = img.size
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ldraw = ImageDraw.Draw(layer)
    bands = [
        (radius * 1.6, 0.18),
        (radius * 1.2, 0.36),
        (radius * 0.8, 0.62),
        (radius * 0.45, 0.92),
        (radius * 0.22, 1.0),
    ]
    for r, mul in bands:
        a = int(255 * intensity * mul * 0.42)
        a = max(0, min(255, a))
        ldraw.ellipse(
            [cx - r, cy - r, cx + r, cy + r],
            fill=(hue[0], hue[1], hue[2], a),
        )
    blur_r = max(2.5, radius * 0.18)
    layer = layer.filter(ImageFilter.GaussianBlur(blur_r))
    img.alpha_composite(layer)


def _draw_runic_emitter(draw, cx, cy, hue):
    """Tiny stone rune slab at the glow's anchor — THEME §2 era, magic on
    a physical object, not floating in vacuum."""
    slab_w, slab_h = 22, 12
    draw.rectangle(
        [cx - slab_w, cy + 12, cx + slab_w, cy + 12 + slab_h],
        fill=STONE_DK, outline=INK_BLACK, width=1,
    )
    rune_color = (
        max(0, min(255, hue[0] - 30)),
        max(0, min(255, hue[1] - 30)),
        max(0, min(255, hue[2] - 30)),
    )
    draw.line([(cx - 8, cy + 18), (cx, cy + 14)], fill=rune_color, width=2)
    draw.line([(cx, cy + 14), (cx + 8, cy + 18)], fill=rune_color, width=2)


def _draw_intensity_meter(draw, x0, y0, x1, y1, intensity, hue):
    """Three-bar intensity strip below the swatch — fills `intensity` bars."""
    bars = 3
    gap = 4
    bar_w = (x1 - x0 - gap * (bars - 1)) // bars
    if intensity >= 0.9: filled = 3
    elif intensity >= 0.55: filled = 2
    else: filled = 1
    for i in range(bars):
        bx0 = x0 + i * (bar_w + gap)
        bx1 = bx0 + bar_w
        if i < filled:
            draw.rectangle([bx0, y0, bx1, y1], fill=hue, outline=INK_BLACK, width=1)
        else:
            draw.rectangle([bx0, y0, bx1, y1], fill=STONE_DK, outline=INK_BLACK, width=1)


def render_magic_glow_reference():
    random.seed(307)
    W, H = 1024, 1024
    img = Image.new("RGBA", (W, H), (24, 18, 14, 255))
    draw = ImageDraw.Draw(img)

    # header
    for y in range(120):
        t = y / 120
        r = int(60 + (140 - 60) * t)
        g = int(40 + (90 - 40) * t)
        b = int(28 + (50 - 28) * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b, 255))

    f_title  = get_font(40, True)
    f_sub    = get_font(20)
    f_lbl    = get_font(13, True)
    f_caption = get_font(13)

    draw.text((30, 22), "ELDORIA — MAGIC GLOW REFERENCE",
              fill=PARCHMENT, font=f_title)
    draw.text((30, 70),
              "THEME.md §3 magic palette / §1 cool-tones-for-magic-only / §5 painterly soft rim. "
              "Tested against a dusk backdrop — pick a hue+intensity by name.",
              fill=THATCH_LT, font=f_sub)

    draw.rectangle([0, H - 50, W, H], fill=DARK_WOOD, outline=INK_BLACK, width=2)
    grain(img, draw, 4, H - 46, W - 4, H - 4, DARK_WOOD, count=200, jitter=12)
    draw.text((30, H - 38),
              "auto/art — generated procedurally by mood-boards/_gen_magic_glow_reference.py.",
              fill=THATCH_LT, font=f_caption)
    draw.text((30, H - 20),
              "Cite when tuning aura / spell / boss-glow intensity. Magic colour stays under 10% of frame (THEME §3).",
              fill=THATCH_LT, font=f_caption)

    grid_top = 130
    grid_bot = H - 60
    cols, rows = 3, 3
    cell_w = (W - 60) // cols
    cell_h = (grid_bot - grid_top - 30) // rows
    margin_x = 20
    margin_y = 14

    hue_rows = [
        ("FEY CYAN",       FEY_CYAN,       "#65DFE5"),
        ("WARLOCK PURPLE", WARLOCK_PURPLE, "#7C3FB0"),
        ("FROST SILVER",   FROST_SILVER,   "#C8E0E5"),
    ]
    intensities = [
        ("LOW",  0.35),
        ("MED",  0.6),
        ("HIGH", 0.95),
    ]

    for r, (hue_name, hue_rgb, hue_hex) in enumerate(hue_rows):
        for c, (int_name, intensity) in enumerate(intensities):
            x0 = 30 + c * cell_w + margin_x // 2
            y0 = grid_top + r * (cell_h + 8) + margin_y // 2
            x1 = x0 + cell_w - margin_x
            y1 = y0 + cell_h - margin_y
            _cell_frame(draw, x0, y0, x1, y1, hue_name + "  -  " + int_name, f_lbl)

            sw_x0 = x0 + 14
            sw_y0 = y0 + 14
            sw_x1 = x1 - 14
            sw_y1 = y1 - 38
            meter_h = 12
            meter_y0 = sw_y1 - meter_h - 6
            sw_y1_inner = meter_y0 - 6

            draw.rectangle(
                [sw_x0, sw_y0, sw_x1, sw_y1_inner],
                fill=DUSK_TOP, outline=INK_BLACK, width=1,
            )
            _fill_dusk(img, draw, sw_x0 + 1, sw_y0 + 1, sw_x1 - 1, sw_y1_inner - 1)

            cx = (sw_x0 + sw_x1) // 2
            cy = sw_y0 + (sw_y1_inner - sw_y0) // 2 + 4
            radius = min(sw_x1 - sw_x0, sw_y1_inner - sw_y0) // 4
            _draw_glow(img, hue_rgb, cx, cy, radius, intensity)
            _draw_runic_emitter(draw, cx, cy, hue_rgb)

            chip_w = 60
            chip_h = 16
            draw.rectangle(
                [sw_x0 + 6, sw_y0 + 6, sw_x0 + 6 + chip_w, sw_y0 + 6 + chip_h],
                fill=PARCHMENT, outline=INK_BLACK, width=1,
            )
            draw.text((sw_x0 + 10, sw_y0 + 6), hue_hex, fill=INK_BLACK, font=f_caption)

            _draw_intensity_meter(
                draw,
                sw_x0, meter_y0, sw_x1, meter_y0 + meter_h,
                intensity, hue_rgb,
            )

    draw.text((40, grid_bot + 6),
              "LOW = ambient ward / herb glow.   MED = spellcast / unique-item halo.   HIGH = boss aura / Crystal Caves veins.",
              fill=DARK_WOOD, font=f_caption)
    draw.text((40, grid_bot + 22),
              "Frost silver reserved for §3 frost-pale silver — Crystal Caves entries, ice gear, ghostly lore beats.",
              fill=DARK_WOOD, font=f_caption)

    out_dir = os.path.dirname(os.path.abspath(__file__))
    out_path = os.path.join(out_dir, "magic_glow_reference.png")
    Image.alpha_composite(Image.new("RGBA", (W, H), (24, 18, 14, 255)), img).convert("RGB").save(
        out_path, "PNG", optimize=True
    )
    print("Wrote " + out_path + " (" + str(os.path.getsize(out_path)) + " bytes)")


if __name__ == "__main__":
    render_magic_glow_reference()
