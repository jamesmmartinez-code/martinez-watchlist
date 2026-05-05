#!/usr/bin/env python3
"""
Realm of Eldoria — Faction Crest Sigils
=======================================

Procedural painterly heraldic crests, 256×256 PNG, transparent-bg shield
escutcheons with faction-specific sigils. Pure Pillow + NumPy, CC0.

Per THEME.md §1-9: painterly hand-painted feel, sunset palette dominant,
faction-flavored accents (10%). No vector-crisp edges — every stroke
carries brushwork irregularity. Lived-in, weathered, age-touched.

Sigils generated:
- briarwood   (oak leaf over crossed axe)         — moss + bronze
- goldhaven   (royal crown)                       — crimson + gold
- ironhold    (hammer over anvil)                 — ember + iron grey
- silverleaf  (single elven leaf, central)        — jade + silver
- stormwatch  (anchor)                            — slate + bronze
- embergrove  (rising flame)                      — sienna + magma
- frostpeak   (six-point snowflake)               — ice blue + steel

Output: eldoria-godot/assets/banners/sigils/<name>_crest.png
"""

import math
import os
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageChops
import numpy as np

SIZE = 256

# THEME §3 palette
SUNSET_GOLD = (255, 216, 107)
WINE = (140, 32, 32)
MOSS = (74, 112, 56)
PARCHMENT = (217, 201, 155)
INK = (14, 10, 14)
BRONZE = (176, 116, 42)
STAG_BLOOD = (160, 32, 32)
STONE_BLUE = (123, 134, 147)
FEY_CYAN = (101, 223, 229)
ARCANE = (124, 63, 176)
SILVER = (200, 224, 229)


FACTIONS = {
    "briarwood": {
        "primary": MOSS,
        "secondary": BRONZE,
        "field": (90, 110, 60),
        "trim": (70, 50, 30),
        "sigil": "oak_axe",
        "tagline": "starter hamlet, oak grove",
    },
    "goldhaven": {
        "primary": SUNSET_GOLD,
        "secondary": WINE,
        "field": (140, 32, 40),
        "trim": (110, 80, 30),
        "sigil": "crown",
        "tagline": "capital city, royal seat",
    },
    "ironhold": {
        "primary": (255, 140, 60),
        "secondary": (140, 140, 145),
        "field": (75, 65, 60),
        "trim": (80, 50, 35),
        "sigil": "hammer_anvil",
        "tagline": "forge city",
    },
    "silverleaf": {
        "primary": (180, 220, 175),
        "secondary": SILVER,
        "field": (60, 95, 75),
        "trim": (90, 110, 95),
        "sigil": "leaf",
        "tagline": "elven grove",
    },
    "stormwatch": {
        "primary": STONE_BLUE,
        "secondary": BRONZE,
        "field": (60, 80, 100),
        "trim": (70, 60, 45),
        "sigil": "anchor",
        "tagline": "coastal port",
    },
    "embergrove": {
        "primary": (255, 130, 50),
        "secondary": (180, 90, 40),
        "field": (150, 70, 40),
        "trim": (120, 70, 35),
        "sigil": "flame",
        "tagline": "desert oasis",
    },
    "frostpeak": {
        "primary": (200, 230, 240),
        "secondary": (140, 160, 180),
        "field": (90, 110, 130),
        "trim": (95, 110, 120),
        "sigil": "snowflake",
        "tagline": "northern garrison",
    },
}


def paper_noise(rng, w, h, scale=0.55):
    arr = np.zeros((h, w, 4), dtype=np.uint8)
    nrng = np.random.default_rng(rng.randint(0, 2**31 - 1))
    grain = (nrng.random((h, w)) - 0.5) * 60.0 * scale
    base = 32 + grain
    alpha = nrng.integers(15, 70, (h, w))
    arr[..., 0] = np.clip(base + 8, 0, 255)
    arr[..., 1] = np.clip(base + 4, 0, 255)
    arr[..., 2] = np.clip(base, 0, 255)
    arr[..., 3] = alpha
    return Image.fromarray(arr, "RGBA")


def brushstroke(im, rng, color, count, length_range=(8, 22), width_range=(1, 2),
                jitter=8, bbox=None, alpha_range=(35, 110)):
    draw = ImageDraw.Draw(im, "RGBA")
    if bbox is None:
        bbox = (0, 0, im.width, im.height)
    x0, y0, x1, y1 = bbox
    for _ in range(count):
        cx = rng.randint(x0, x1)
        cy = rng.randint(y0, y1)
        ang = rng.uniform(0, math.tau)
        ln = rng.randint(*length_range)
        w = rng.randint(*width_range)
        dx = math.cos(ang) * ln
        dy = math.sin(ang) * ln
        a = rng.randint(*alpha_range)
        c = (color[0], color[1], color[2], a)
        mid_jx = cx + dx * 0.5 + rng.randint(-jitter, jitter) * 0.1
        mid_jy = cy + dy * 0.5 + rng.randint(-jitter, jitter) * 0.1
        draw.line([(cx, cy), (mid_jx, mid_jy), (cx + dx, cy + dy)], fill=c, width=w)


def vary(c, rng, jitter=18):
    return tuple(int(max(0, min(255, ch + rng.randint(-jitter, jitter)))) for ch in c)


def shield_polygon(cx, cy, w, h, points=64):
    out = []
    half_w = w / 2
    out.append((cx - half_w, cy - h * 0.45))
    out.append((cx + half_w, cy - h * 0.45))
    for i in range(1, points + 1):
        t = i / points
        x = cx + half_w * (1 - t * t)
        y = cy - h * 0.45 + h * 0.95 * t
        out.append((x, y))
    out.append((cx, cy + h * 0.55))
    for i in range(points, 0, -1):
        t = i / points
        x = cx - half_w * (1 - t * t)
        y = cy - h * 0.45 + h * 0.95 * t
        out.append((x, y))
    return out


def make_shield_mask(size, rng):
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    cx, cy = size / 2, size / 2 - 4
    poly = shield_polygon(cx, cy, size * 0.78, size * 0.92)
    poly = [(x + rng.uniform(-1.4, 1.4), y + rng.uniform(-1.4, 1.4)) for (x, y) in poly]
    d.polygon(poly, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(radius=0.7))
    return mask


def paint_field(size, rng, base_color, accent_color):
    field = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = field.load()
    for y in range(size):
        t = y / (size - 1)
        r = int(base_color[0] * (0.85 + 0.30 * (1 - t)))
        g = int(base_color[1] * (0.85 + 0.30 * (1 - t)))
        b = int(base_color[2] * (0.85 + 0.30 * (1 - t)))
        for x in range(size):
            px[x, y] = (min(255, r), min(255, g), min(255, b), 255)
    brushstroke(field, rng, base_color, count=180, length_range=(10, 28),
                width_range=(1, 3), jitter=14, alpha_range=(40, 110))
    brushstroke(field, rng, accent_color, count=60, length_range=(4, 14),
                width_range=(1, 2), jitter=8, alpha_range=(30, 80))
    brushstroke(field, rng, INK, count=80, length_range=(6, 20),
                width_range=(1, 2), jitter=10, alpha_range=(20, 60))
    return field


def draw_oak_axe(im, rng, primary, secondary):
    d = ImageDraw.Draw(im, "RGBA")
    cx = im.width / 2
    cy = im.height / 2 + 4
    handle_color = (90, 60, 35, 240)
    blade_color = vary(secondary, rng, 10) + (255,)
    d.line([(cx - 60, cy + 50), (cx + 60, cy - 50)], fill=handle_color, width=7)
    head_pts = [
        (cx + 56, cy - 46), (cx + 80, cy - 60),
        (cx + 86, cy - 38), (cx + 64, cy - 24),
    ]
    d.polygon(head_pts, fill=blade_color, outline=INK)
    d.line([(cx + 60, cy - 52), (cx + 78, cy - 56)], fill=(255, 248, 220, 160), width=2)
    leaf_main = vary(primary, rng, 12) + (255,)
    leaf_dark = (max(0, primary[0] - 35), max(0, primary[1] - 35), max(0, primary[2] - 35), 255)
    poly = []
    for t in np.linspace(-1.0, 1.0, 60):
        y = t * 70
        bump = 1.0 + 0.32 * math.cos(t * math.pi * 4.5)
        x = bump * (1.0 - t * t) * 36
        poly.append((cx + x, cy + y))
    for t in np.linspace(1.0, -1.0, 60):
        y = t * 70
        bump = 1.0 + 0.32 * math.cos(t * math.pi * 4.5)
        x = bump * (1.0 - t * t) * 36
        poly.append((cx - x, cy + y))
    d.polygon(poly, fill=leaf_main, outline=leaf_dark)
    spine_color = (max(0, primary[0] - 50), max(0, primary[1] - 50), max(0, primary[2] - 50), 200)
    d.line([(cx, cy - 70), (cx, cy + 70)], fill=spine_color, width=2)
    for ts in np.linspace(-0.8, 0.8, 7):
        ymid = ts * 70
        bump = 1.0 + 0.32 * math.cos(ts * math.pi * 4.5)
        xtip = bump * (1.0 - ts * ts) * 30
        d.line([(cx, cy + ymid), (cx + xtip, cy + ymid - 4)],
               fill=spine_color, width=1)
        d.line([(cx, cy + ymid), (cx - xtip, cy + ymid - 4)],
               fill=spine_color, width=1)


def draw_crown(im, rng, primary, secondary):
    d = ImageDraw.Draw(im, "RGBA")
    cx = im.width / 2
    cy = im.height / 2 + 8
    gold = vary(primary, rng, 10) + (255,)
    gold_dark = (180, 130, 40, 255)
    band_top = cy + 12
    band_bot = cy + 38
    d.rectangle([cx - 60, band_top, cx + 60, band_bot], fill=gold, outline=gold_dark)
    d.line([(cx - 56, band_top + 14), (cx + 56, band_top + 14)], fill=gold_dark, width=2)
    pts_x = [cx - 60, cx - 30, cx, cx + 30, cx + 60]
    pts_h = [38, 26, 50, 26, 38]
    for x, h in zip(pts_x, pts_h):
        tip = (x, band_top - h)
        left = (x - 18, band_top)
        right = (x + 18, band_top)
        d.polygon([left, tip, right], fill=gold, outline=gold_dark)
        d.ellipse([tip[0] - 5, tip[1] - 5, tip[0] + 5, tip[1] + 5], fill=gold_dark)
    jx, jy = cx, cy + 25
    d.ellipse([jx - 9, jy - 9, jx + 9, jy + 9], fill=secondary + (255,), outline=INK)
    d.ellipse([jx - 6, jy - 7, jx - 2, jy - 3], fill=(255, 220, 200, 200))
    brushstroke(im, rng, primary, count=60, length_range=(2, 6),
                width_range=(1, 1), jitter=4,
                bbox=(int(cx - 80), int(cy - 40), int(cx + 80), int(cy + 50)),
                alpha_range=(30, 80))


def draw_hammer_anvil(im, rng, primary, secondary):
    d = ImageDraw.Draw(im, "RGBA")
    cx = im.width / 2
    cy = im.height / 2 + 4
    iron = vary(secondary, rng, 8) + (255,)
    iron_dark = (60, 60, 65, 255)
    ember_rgb = vary(primary, rng, 12)
    ember = ember_rgb + (255,)
    d.polygon([
        (cx - 56, cy + 50), (cx + 56, cy + 50),
        (cx + 44, cy + 68), (cx - 44, cy + 68),
    ], fill=iron_dark, outline=INK)
    d.rectangle([cx - 20, cy + 24, cx + 20, cy + 50], fill=iron_dark, outline=INK)
    d.polygon([
        (cx - 50, cy), (cx + 50, cy),
        (cx + 62, cy + 14), (cx + 50, cy + 24),
        (cx - 50, cy + 24), (cx - 62, cy + 14),
    ], fill=iron, outline=INK)
    d.line([(cx - 46, cy + 4), (cx + 46, cy + 4)], fill=(220, 220, 230, 180), width=2)
    haft_color = (100, 65, 35, 255)
    d.line([(cx - 38, cy - 32), (cx + 30, cy - 90)], fill=haft_color, width=8)
    head_pts = [
        (cx - 56, cy - 28), (cx - 26, cy - 50),
        (cx - 18, cy - 38), (cx - 48, cy - 16),
    ]
    d.polygon(head_pts, fill=iron, outline=INK)
    d.line([(cx - 52, cy - 24), (cx - 30, cy - 38)], fill=(230, 230, 240, 180), width=2)
    for _ in range(18):
        sx = cx + rng.uniform(-12, 22)
        sy = cy - 5 + rng.uniform(-8, 8)
        r = rng.uniform(1.2, 3.0)
        c = vary(ember_rgb, rng, 25) + (rng.randint(180, 240),)
        d.ellipse([sx - r, sy - r, sx + r, sy + r], fill=c)
    for _ in range(8):
        ang = rng.uniform(-math.pi * 0.9, -math.pi * 0.1)
        ln = rng.uniform(8, 22)
        x0 = cx + rng.uniform(-6, 12)
        y0 = cy + rng.uniform(-4, 4)
        x1 = x0 + math.cos(ang) * ln
        y1 = y0 + math.sin(ang) * ln
        d.line([(x0, y0), (x1, y1)],
               fill=vary(ember_rgb, rng, 15) + (rng.randint(120, 200),),
               width=2)


def draw_leaf(im, rng, primary, secondary):
    d = ImageDraw.Draw(im, "RGBA")
    cx = im.width / 2
    cy = im.height / 2 + 4
    leaf_main = vary(primary, rng, 10) + (255,)
    leaf_dark = (60, 95, 75, 255)
    silver = vary(secondary, rng, 8) + (255,)
    poly = []
    for t in np.linspace(-1.0, 1.0, 72):
        y = t * 90
        x = (1.0 - t * t) ** 0.85 * 36
        poly.append((cx + x, cy + y))
    for t in np.linspace(1.0, -1.0, 72):
        y = t * 90
        x = (1.0 - t * t) ** 0.85 * 36
        poly.append((cx - x, cy + y))
    d.polygon(poly, fill=leaf_main, outline=leaf_dark)
    d.line([(cx, cy - 90), (cx, cy + 90)], fill=silver, width=2)
    for ts in np.linspace(-0.85, 0.85, 11):
        ymid = ts * 88
        x_at = (1.0 - ts * ts) ** 0.85 * 32
        d.line([(cx, cy + ymid), (cx + x_at, cy + ymid - 12)], fill=silver, width=1)
        d.line([(cx, cy + ymid), (cx - x_at, cy + ymid - 12)], fill=silver, width=1)
    d.ellipse([cx - 6, cy - 30, cx + 2, cy - 22], fill=(230, 250, 240, 180))


def draw_anchor(im, rng, primary, secondary):
    d = ImageDraw.Draw(im, "RGBA")
    cx = im.width / 2
    cy = im.height / 2 + 6
    iron = vary(primary, rng, 8) + (255,)
    iron_dark = (60, 70, 80, 255)
    bronze = vary(secondary, rng, 12) + (255,)
    d.line([(cx, cy - 64), (cx, cy + 50)], fill=iron, width=8)
    d.line([(cx - 30, cy - 50), (cx + 30, cy - 50)], fill=iron, width=6)
    d.ellipse([cx - 14, cy - 86, cx + 14, cy - 58], outline=iron, width=5)
    pts_l = []
    for t in np.linspace(0, 1, 30):
        ang = math.pi * (0.5 + 0.5 * t)
        r = 50
        x = cx + math.cos(ang) * r
        y = cy + 10 + math.sin(ang) * r * 0.85
        pts_l.append((x, y))
    pts_l.append((cx - 56, cy + 30))
    pts_l.append((cx - 28, cy + 10))
    d.polygon(pts_l, fill=iron, outline=iron_dark)
    pts_r = [(2 * cx - x, y) for (x, y) in pts_l]
    d.polygon(pts_r, fill=iron, outline=iron_dark)
    d.polygon([(cx - 6, cy + 50), (cx + 6, cy + 50), (cx, cy + 64)],
              fill=iron, outline=iron_dark)
    for offs in range(-10, 12, 4):
        d.line([(cx - 12, cy - 78 + offs), (cx + 12, cy - 80 + offs)],
               fill=bronze, width=1)


def draw_flame(im, rng, primary, secondary):
    d = ImageDraw.Draw(im, "RGBA")
    cx = im.width / 2
    cy = im.height / 2 + 16
    magma_rgb = vary(primary, rng, 10)
    magma = magma_rgb + (255,)
    sienna = vary(secondary, rng, 12) + (255,)
    sun = vary(SUNSET_GOLD, rng, 12) + (255,)
    outer = [
        (cx, cy - 90), (cx + 14, cy - 64), (cx + 28, cy - 38),
        (cx + 42, cy - 6), (cx + 50, cy + 22), (cx + 36, cy + 50),
        (cx, cy + 60), (cx - 36, cy + 50), (cx - 50, cy + 22),
        (cx - 42, cy - 6), (cx - 28, cy - 38), (cx - 14, cy - 64),
    ]
    outer = [(x + rng.uniform(-2.5, 2.5), y + rng.uniform(-2.5, 2.5)) for (x, y) in outer]
    d.polygon(outer, fill=sienna, outline=INK)
    mid = [
        (cx, cy - 60), (cx + 22, cy - 16), (cx + 28, cy + 16),
        (cx + 14, cy + 36), (cx, cy + 42), (cx - 14, cy + 36),
        (cx - 28, cy + 16), (cx - 22, cy - 16),
    ]
    mid = [(x + rng.uniform(-1.5, 1.5), y + rng.uniform(-1.5, 1.5)) for (x, y) in mid]
    d.polygon(mid, fill=magma)
    inner = [
        (cx, cy - 32), (cx + 10, cy - 4), (cx + 12, cy + 18),
        (cx, cy + 26), (cx - 12, cy + 18), (cx - 10, cy - 4),
    ]
    d.polygon(inner, fill=sun)
    for _ in range(14):
        sx = cx + rng.uniform(-44, 44)
        sy = cy + rng.uniform(-100, -50)
        r = rng.uniform(1.2, 2.4)
        d.ellipse([sx - r, sy - r, sx + r, sy + r],
                  fill=vary(magma_rgb, rng, 25) + (rng.randint(140, 220),))


def draw_snowflake(im, rng, primary, secondary):
    d = ImageDraw.Draw(im, "RGBA")
    cx = im.width / 2
    cy = im.height / 2 + 4
    ice = vary(primary, rng, 6) + (255,)
    steel = vary(secondary, rng, 8) + (255,)
    arm_len = 84
    for i in range(6):
        ang = i * math.pi / 3 - math.pi / 2
        ex = cx + math.cos(ang) * arm_len
        ey = cy + math.sin(ang) * arm_len
        d.line([(cx, cy), (ex, ey)], fill=ice, width=4)
        for frac in (0.38, 0.66):
            mx = cx + math.cos(ang) * arm_len * frac
            my = cy + math.sin(ang) * arm_len * frac
            for side in (-1, 1):
                bang = ang + side * math.pi * 0.28
                blen = arm_len * (0.20 if frac > 0.5 else 0.32)
                bx = mx + math.cos(bang) * blen
                by = my + math.sin(bang) * blen
                d.line([(mx, my), (bx, by)], fill=ice, width=3)
        tip_size = 4
        d.polygon([
            (ex, ey - tip_size), (ex + tip_size, ey),
            (ex, ey + tip_size), (ex - tip_size, ey),
        ], fill=steel)
    d.ellipse([cx - 11, cy - 11, cx + 11, cy + 11], fill=steel, outline=INK)
    d.ellipse([cx - 7, cy - 7, cx + 7, cy + 7], fill=ice)
    d.ellipse([cx - 5, cy - 6, cx - 1, cy - 2], fill=(255, 255, 255, 220))


SIGIL_DRAWERS = {
    "oak_axe": draw_oak_axe,
    "crown": draw_crown,
    "hammer_anvil": draw_hammer_anvil,
    "leaf": draw_leaf,
    "anchor": draw_anchor,
    "flame": draw_flame,
    "snowflake": draw_snowflake,
}


def render_crest(name, faction, seed):
    rng = random.Random(seed)
    size = SIZE
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    field = paint_field(size, rng, faction["field"], faction["secondary"])
    mask = make_shield_mask(size, rng)
    field.putalpha(mask)
    canvas.alpha_composite(field)

    grain = paper_noise(rng, size, size, scale=0.55)
    grain.putalpha(ImageChops.multiply(grain.split()[3], mask))
    canvas.alpha_composite(grain)

    trim = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    td = ImageDraw.Draw(trim, "RGBA")
    cx, cy = size / 2, size / 2 - 4
    poly = shield_polygon(cx, cy, size * 0.78, size * 0.92)
    poly_jit = [(x + rng.uniform(-1.0, 1.0), y + rng.uniform(-1.0, 1.0)) for (x, y) in poly]
    td.line(poly_jit + [poly_jit[0]], fill=faction["trim"] + (240,), width=4, joint="curve")
    poly_inner = [
        (cx + (x - cx) * 0.93, cy + (y - cy) * 0.93) for (x, y) in poly_jit
    ]
    td.line(poly_inner + [poly_inner[0]], fill=faction["primary"] + (170,), width=1, joint="curve")
    canvas.alpha_composite(trim)

    sigil_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    SIGIL_DRAWERS[faction["sigil"]](sigil_layer, rng, faction["primary"], faction["secondary"])

    shadow_alpha = sigil_layer.split()[3].filter(ImageFilter.GaussianBlur(2.5))
    shadow_arr = np.zeros((size, size, 4), dtype=np.uint8)
    shadow_arr[..., 3] = (np.array(shadow_alpha) * 0.55).astype(np.uint8)
    shadow_img = Image.fromarray(shadow_arr, "RGBA")
    canvas.alpha_composite(shadow_img, (3, 4))
    canvas.alpha_composite(sigil_layer)

    weather = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    brushstroke(weather, rng, INK, count=60,
                length_range=(2, 10), width_range=(1, 1), jitter=2,
                alpha_range=(20, 60), bbox=(20, 20, size - 20, size - 20))
    brushstroke(weather, rng, PARCHMENT, count=30,
                length_range=(1, 4), width_range=(1, 1), jitter=1,
                alpha_range=(30, 80), bbox=(20, 20, size - 20, size - 20))
    weather.putalpha(ImageChops.multiply(weather.split()[3], mask))
    canvas.alpha_composite(weather)

    larr = np.zeros((size, size, 4), dtype=np.uint8)
    for y in range(size):
        a = max(0, int(60 * (1 - y / (size * 0.6))))
        larr[y, :, 0] = SUNSET_GOLD[0]
        larr[y, :, 1] = SUNSET_GOLD[1]
        larr[y, :, 2] = SUNSET_GOLD[2]
        larr[y, :, 3] = a
    light = Image.fromarray(larr, "RGBA")
    light.putalpha(ImageChops.multiply(light.split()[3], mask))
    canvas.alpha_composite(light)

    return canvas


def main():
    out_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("eldoria-godot/assets/banners/sigils")
    out_dir.mkdir(parents=True, exist_ok=True)
    seed_base = 13130
    for i, (name, faction) in enumerate(FACTIONS.items()):
        seed = seed_base + i * 17
        im = render_crest(name, faction, seed)
        out = out_dir / f"{name}_crest.png"
        im.save(out, "PNG", optimize=True)
        print(f"  -> {out.name}  ({faction['tagline']})  seed={seed}")
    print(f"\nDone. {len(FACTIONS)} sigils -> {out_dir}")


if __name__ == "__main__":
    main()
