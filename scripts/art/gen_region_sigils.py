#!/usr/bin/env python3
"""
Realm of Eldoria — Region Sigils (companion to gen_sigils.py)
=============================================================

The seven *town* faction crests live in `gen_sigils.py`. The codex / map /
quest-billboard pipeline also asks for crests for the two non-town
*regions* the player crosses but does not call home:

  - whisperwood   — the goblin-haunted forest between Briarwood and the
                    Crystal Caves. Banner already exists at
                    `banners/whisperwood_danger.png`; this is the matching
                    heraldic crest for the REGION (the wood itself), distinct
                    from the existing `whisperwood_goblins_crest.png` which
                    represents the goblin tribe specifically.

A second region sigil (crystal_caves) was deliberately scoped OUT of this
generator: the `crystal_caves_crest.png` shipped by the prior auto/art
run already covers that case.

Output: 256x256 RGBA PNG, transparent background, painterly heater-shield
escutcheon over a region-flavored field, with a hand-painted device and
weathered trim per THEME.md S3. Pure Pillow + NumPy. CC0.

This script intentionally lives next to (not inside) `gen_sigils.py` to
keep its scope tight: two new sigils, two new drawers, no churn in the
existing seven-faction generator.

Run:
  python3 scripts/art/gen_region_sigils.py eldoria-godot/assets/banners/sigils/

Deterministic - same seeds -> same output.
"""
from __future__ import annotations

import math
import random
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

SIZE = 256

# THEME S3 palette (mirrors gen_sigils.py - keep numbers identical so the
# nine sigils read as ONE set, not "town set" + "region pair").
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
FROST_PALE = (200, 224, 229)


REGIONS = {
    "whisperwood": {
        "primary": MOSS,
        "secondary": WINE,
        "field": (60, 80, 45),
        "trim": (50, 35, 25),
        "sigil": "tusk_thorn",
        "tagline": "goblin-haunted oak forest",
    },
}


# ---------- shared helpers (mirror gen_sigils.py exactly) ----------

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


def draw_tusk_thorn(im, rng, primary, secondary):
    """Curved goblin tusk (ivory) crossing a thorn branch (bark + wine)."""
    d = ImageDraw.Draw(im, "RGBA")
    cx = im.width / 2
    cy = im.height / 2 + 4

    branch_color = (60, 38, 22, 255)
    branch_dark = (32, 20, 12, 255)
    pts = []
    for t in np.linspace(0, 1, 28):
        ax = -72 + 144 * t
        ay = 56 - 112 * t
        bulge = math.sin(t * math.pi) * 10
        pts.append((cx + ax, cy + ay + bulge))
    for i in range(len(pts) - 1):
        x0, y0 = pts[i]
        x1, y1 = pts[i + 1]
        u = i / max(1, len(pts) - 2)
        w = int(6 + 2 * math.sin(u * math.pi))
        d.line([(x0, y0), (x1, y1)], fill=branch_color, width=w)
    for i in range(len(pts) - 1):
        x0, y0 = pts[i]; x1, y1 = pts[i + 1]
        d.line([(x0, y0), (x1, y1)], fill=branch_dark, width=1)

    wine = vary(secondary, rng, 8) + (255,)
    for tfrac in (0.18, 0.40, 0.62, 0.84):
        idx = max(1, int(tfrac * (len(pts) - 1)))
        bx, by = pts[idx]
        px0, py0 = pts[idx - 1]
        px1, py1 = pts[min(len(pts) - 1, idx + 1)]
        tx, ty = (px1 - px0), (py1 - py0)
        nlen = max(1.0, math.hypot(tx, ty))
        nx, ny = -ty / nlen, tx / nlen
        side = 1 if int(tfrac * 10) % 2 == 0 else -1
        tip_x = bx + side * nx * 18
        tip_y = by + side * ny * 18
        base_a = (bx + 4 * (tx / nlen), by + 4 * (ty / nlen))
        base_b = (bx - 4 * (tx / nlen), by - 4 * (ty / nlen))
        d.polygon([base_a, (tip_x, tip_y), base_b],
                  fill=branch_color, outline=INK)
        d.ellipse([tip_x - 2, tip_y - 2, tip_x + 2, tip_y + 2], fill=wine)

    ivory = (235, 222, 196, 255)
    ivory_dark = (170, 150, 110, 255)
    tusk_pts = []
    N = 32
    for i in range(N + 1):
        t = i / N
        ax = -68 + 132 * t
        ay = -56 + 110 * t
        bulge = math.sin(t * math.pi) * -16
        tusk_pts.append((cx + ax, cy + ay + bulge))
    for i in range(N + 1):
        t = 1.0 - i / N
        ax = -68 + 132 * t
        ay = -56 + 110 * t
        bulge = math.sin(t * math.pi) * -6
        tusk_pts.append((cx + ax, cy + ay + bulge))
    d.polygon(tusk_pts, fill=ivory, outline=ivory_dark)

    hi_pts = []
    for i in range(N + 1):
        t = i / N
        ax = -64 + 124 * t
        ay = -50 + 100 * t
        bulge = math.sin(t * math.pi) * -11
        hi_pts.append((cx + ax, cy + ay + bulge))
    for i in range(len(hi_pts) - 1):
        x0, y0 = hi_pts[i]; x1, y1 = hi_pts[i + 1]
        u = i / max(1, len(hi_pts) - 2)
        a = int(160 + 40 * math.sin(u * math.pi))
        d.line([(x0, y0), (x1, y1)], fill=(255, 246, 220, a), width=2)

    rx, ry = cx - 68, cy - 56
    d.ellipse([rx - 8, ry - 6, rx + 8, ry + 8], fill=ivory_dark, outline=INK)
    tx, ty = cx + 64, cy + 54
    d.polygon([(tx - 4, ty - 6), (tx + 4, ty), (tx - 4, ty + 6)],
              fill=ivory_dark, outline=INK)

    moss_rgb = vary(primary, rng, 14)
    for _ in range(22):
        sx = cx + rng.uniform(-90, 90)
        sy = cy + rng.uniform(-90, 90)
        r = rng.uniform(0.8, 2.0)
        a = rng.randint(60, 130)
        d.ellipse([sx - r, sy - r, sx + r, sy + r], fill=moss_rgb + (a,))


def draw_crystal_cluster(im, rng, primary, secondary):
    """Five-shard crystal cluster radiating from a base."""
    d = ImageDraw.Draw(im, "RGBA")
    cx = im.width / 2
    cy = im.height / 2 + 12

    halo = Image.new("RGBA", im.size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    hd.ellipse([cx - 78, cy - 90, cx + 78, cy + 50], fill=(124, 63, 176, 90))
    halo = halo.filter(ImageFilter.GaussianBlur(12))
    im.alpha_composite(halo)

    shard_specs = [
        (-42, 68, 9),
        (-18, 92, 11),
        (  0, 110, 13),
        ( 18, 88, 11),
        ( 42, 64, 9),
    ]

    cyan_main = vary(primary, rng, 8) + (255,)
    cyan_dark = (40, 120, 140, 255)
    arcane_vein = vary(secondary, rng, 12) + (255,)
    silver_tip = vary(SILVER, rng, 4) + (255,)

    d.ellipse([cx - 44, cy + 26, cx + 44, cy + 46],
              fill=(70, 80, 100, 230), outline=INK)

    for ang_deg, length, half_w in shard_specs:
        ang = math.radians(ang_deg - 90)
        bx = cx + ang_deg * 0.6
        by = cy + 30
        tx = bx + math.cos(ang) * length
        ty = by + math.sin(ang) * length
        nx, ny = -math.sin(ang), math.cos(ang)
        lx, ly = bx + nx * half_w, by + ny * half_w
        rx, ry = bx - nx * half_w, by - ny * half_w
        mfront = (
            bx + math.cos(ang) * length * 0.55 + nx * half_w * 0.35,
            by + math.sin(ang) * length * 0.55 + ny * half_w * 0.35,
        )
        mback = (
            bx + math.cos(ang) * length * 0.55 - nx * half_w * 0.35,
            by + math.sin(ang) * length * 0.55 - ny * half_w * 0.35,
        )
        outer_poly = [(lx, ly), mfront, (tx, ty), mback, (rx, ry)]
        d.polygon(outer_poly, fill=cyan_main, outline=cyan_dark)
        light_poly = [(lx, ly), mfront, (tx, ty)]
        d.polygon(light_poly, fill=(180, 240, 245, 220))
        shade_poly = [(rx, ry), mback, (tx, ty)]
        d.polygon(shade_poly, fill=(60, 145, 165, 220))
        d.line([(bx, by), (tx, ty)], fill=cyan_dark, width=1)
        d.line([(bx, by), (tx, ty)],
               fill=(arcane_vein[0], arcane_vein[1], arcane_vein[2], 180),
               width=1)
        d.polygon([
            (tx - 2, ty + 2),
            (tx, ty - 4),
            (tx + 2, ty + 2),
        ], fill=silver_tip)

    for _ in range(14):
        sx = cx + rng.uniform(-70, 70)
        sy = cy + rng.uniform(-100, -40)
        r = rng.uniform(0.8, 2.0)
        a = rng.randint(140, 220)
        spark_color = (
            rng.choice([FEY_CYAN[0], 200]),
            rng.choice([FEY_CYAN[1], 224]),
            rng.choice([FEY_CYAN[2], 229]),
            a,
        )
        d.ellipse([sx - r, sy - r, sx + r, sy + r], fill=spark_color)

    d.ellipse([cx - 6, cy + 30, cx + 6, cy + 38],
              fill=(220, 240, 250, 180))


SIGIL_DRAWERS = {
    "tusk_thorn": draw_tusk_thorn,
    "crystal_cluster": draw_crystal_cluster,
}


def render_crest(name, region, seed):
    rng = random.Random(seed)
    size = SIZE
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    field = paint_field(size, rng, region["field"], region["secondary"])
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
    td.line(poly_jit + [poly_jit[0]], fill=region["trim"] + (240,), width=4, joint="curve")
    poly_inner = [
        (cx + (x - cx) * 0.93, cy + (y - cy) * 0.93) for (x, y) in poly_jit
    ]
    td.line(poly_inner + [poly_inner[0]], fill=region["primary"] + (170,), width=1, joint="curve")
    canvas.alpha_composite(trim)

    sigil_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    SIGIL_DRAWERS[region["sigil"]](sigil_layer, rng, region["primary"], region["secondary"])
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
    out_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
        "eldoria-godot/assets/banners/sigils"
    )
    out_dir.mkdir(parents=True, exist_ok=True)
    seed_base = 14400
    for i, (name, region) in enumerate(REGIONS.items()):
        seed = seed_base + i * 19
        im = render_crest(name, region, seed)
        out = out_dir / f"{name}_crest.png"
        im.save(out, "PNG", optimize=True)
        print(f"  -> {out.name}  ({region['tagline']})  seed={seed}")
    print(f"\nDone. {len(REGIONS)} region sigils -> {out_dir}")


if __name__ == "__main__":
    main()
