#!/usr/bin/env python3
"""
Realm of Eldoria — procedural loot icon generator (run-24 expansion).

Run-23 covered wolf_fang.png. Run-24 (this commit) closes the remaining
Items.gd icon-path gaps surfaced by the run-24 audit:

  - wolf_pelt.png   (item id `wolf_pelt`,  Color(0.65,0.55,0.40), stack)
  - wolf_heart.png  (item id `wolf_heart`, Color(0.65,0.18,0.22), stack)
  - wooden_shield.png (item id `wooden_shield`, Color(0.55,0.40,0.25), armor 4)

Style targets (THEME.md §1, §3, §5):
  - §1 painterly, hand-painted concept-art aesthetic; warm, weathered.
  - §3 palette compliance — parchment / sepia ground; ivory bone for
    fang; grey-brown pelt; wine/stag-blood heart with brass rim glow;
    aged oak + iron-band shield. No neon, no fluorescent, no pure white.
  - §5 hand-painted look — soft Gaussian rims, brushy speckle, gentle
    drop shadows. No crisp vector edges.

Output: 128x128 RGBA PNG, fully painted parchment backdrop + subject
on top. Painterly parity with the inventory grid requires a full-frame
painted background, not transparent silhouette (run-23 audit finding).

License: CC0 — generated procedurally with Pillow, no external assets.

Run: python3 gen_loot_icons.py <out_dir>
"""
from __future__ import annotations

import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageChops

SIZE = 128
SUPER = 4
W = SIZE * SUPER

# THEME §3 anchors
PARCHMENT = (217, 201, 155, 255)
PARCHMENT_DK = (170, 150, 110, 255)
INK = (14, 10, 14, 255)
IVORY = (235, 224, 199, 255)
IVORY_LT = (248, 240, 220, 255)
IVORY_SHADE = (170, 150, 120, 255)
BRASS = (176, 116, 42, 255)
WINE = (110, 24, 24, 255)
STAG_BLOOD = (160, 32, 32, 255)
MOSS = (74, 112, 56, 255)
WOOD = (110, 70, 38, 255)
WOOD_LT = (160, 110, 60, 255)
WOOD_DK = (66, 40, 22, 255)
PELT_BROWN = (165, 140, 100, 255)
PELT_BROWN_DK = (110, 88, 58, 255)
PELT_GREY = (130, 122, 110, 255)
IRON = (110, 112, 118, 255)
IRON_LT = (175, 178, 184, 255)
IRON_DK = (62, 64, 70, 255)


def _rand(seed: int) -> random.Random:
    return random.Random(seed)


def _blend(a, b, t):
    return (
        int(a[0] * (1 - t) + b[0] * t),
        int(a[1] * (1 - t) + b[1] * t),
        int(a[2] * (1 - t) + b[2] * t),
        int(a[3] * (1 - t) + b[3] * t),
    )


def _multiply_alpha(a, b):
    return ImageChops.multiply(a, b)


# ---------------------------------------------------------------- backdrop


def _parchment_backdrop(seed: int, warm_center=(255, 220, 145, 255),
                        edge=(122, 86, 50, 255)) -> Image.Image:
    """THEME §3-compliant warm parchment vignette + brushy noise + edge ring."""
    r = _rand(seed)
    bg = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bg, "RGBA")
    cx, cy = W // 2, int(W * 0.55)
    max_r = int(W * 0.78)
    for band in range(48, 0, -1):
        t = band / 48.0
        rad = int(max_r * t)
        col = _blend(warm_center, edge, t)
        bd.ellipse((cx - rad, cy - rad, cx + rad, cy + rad), fill=col)
    bg = bg.filter(ImageFilter.GaussianBlur(radius=W // 28))

    # brushy painterly noise
    noise = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    nd = ImageDraw.Draw(noise, "RGBA")
    for _ in range(220):
        x = r.randint(0, W - 1)
        y = r.randint(0, W - 1)
        rad = r.randint(1, 3) * (W // 256)
        ch = r.random()
        if ch < 0.55:
            col = (PARCHMENT_DK[0], PARCHMENT_DK[1], PARCHMENT_DK[2],
                   6 + r.randint(0, 12))
        elif ch < 0.88:
            col = (BRASS[0], BRASS[1], BRASS[2], 5 + r.randint(0, 10))
        else:
            col = (INK[0], INK[1], INK[2], 4 + r.randint(0, 8))
        nd.ellipse((x - rad, y - rad, x + rad, y + rad), fill=col)
    noise = noise.filter(ImageFilter.GaussianBlur(radius=W // 220))
    bg = Image.alpha_composite(bg, noise)

    # soft dark vignette ring
    vig = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vig, "RGBA")
    for band in range(20):
        t = band / 19.0
        rad = int(max_r + t * W * 0.18)
        alpha = int(70 * t)
        vd.ellipse((cx - rad, cy - rad, cx + rad, cy + rad),
                   outline=(0, 0, 0, alpha), width=int(W * 0.012))
    vig = vig.filter(ImageFilter.GaussianBlur(radius=W // 30))
    bg = Image.alpha_composite(bg, vig)
    return bg


def _drop_shadow(poly_or_bbox, kind="poly") -> Image.Image:
    sh = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh, "RGBA")
    off = int(W * 0.012)
    if kind == "poly":
        shifted = [(x + off, y + off) for x, y in poly_or_bbox]
        sd.polygon(shifted, fill=(0, 0, 0, 110))
    else:
        x0, y0, x1, y1 = poly_or_bbox
        sd.ellipse((x0 + off, y0 + off, x1 + off, y1 + off),
                   fill=(0, 0, 0, 110))
    return sh.filter(ImageFilter.GaussianBlur(radius=W // 60))


def _ink_rim_poly(poly) -> Image.Image:
    rim = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rim, "RGBA")
    rd.polygon(poly, outline=INK, width=int(W * 0.008))
    return rim.filter(ImageFilter.GaussianBlur(radius=W // 280))


def _speckle_inside(seed, mask_img, palette_choices, count=900) -> Image.Image:
    r = _rand(seed)
    sp = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sp, "RGBA")
    for _ in range(count):
        x = r.randint(0, W - 1)
        y = r.randint(0, W - 1)
        rad = r.randint(1, 3) * (W // 128)
        col = palette_choices[r.randrange(len(palette_choices))]
        sd.ellipse((x - rad, y - rad, x + rad, y + rad), fill=col)
    sp.putalpha(_multiply_alpha(sp.split()[-1], mask_img))
    return sp


# ---------------------------------------------------------------- wolf_pelt


def _pelt_path(seed: int) -> list[tuple[int, int]]:
    """Stretched wolf-pelt silhouette: roughly oval body with four tiny
    paw stubs and a tail. Hand-painted irregular outline.
    """
    r = _rand(seed)
    cx, cy = W // 2, int(W * 0.52)
    rx, ry = int(W * 0.30), int(W * 0.36)
    pts = []
    N = 64
    for i in range(N):
        t = i / N * 2 * math.pi
        # base ellipse + sinusoidal jitter for hand-painted edge
        wob = 1.0 + 0.04 * math.sin(t * 5) + (r.random() - 0.5) * 0.05
        x = int(cx + math.cos(t) * rx * wob)
        y = int(cy + math.sin(t) * ry * wob)
        pts.append((x, y))
    # add four paw bumps and a tail by deforming nearby points
    def bump(angle_deg, out, w):
        a = math.radians(angle_deg)
        cx2 = cx + math.cos(a) * rx * 0.95
        cy2 = cy + math.sin(a) * ry * 0.95
        bx = cx + math.cos(a) * (rx + out)
        by = cy + math.sin(a) * (ry + out)
        # find nearest pt and replace with a small triangular bump
        idx = min(range(len(pts)), key=lambda i: (pts[i][0] - cx2) ** 2 + (pts[i][1] - cy2) ** 2)
        pts[idx] = (int(bx), int(by))
    bump(-130, W * 0.06, W * 0.04)   # front-left paw
    bump(-50, W * 0.06, W * 0.04)    # front-right paw
    bump(130, W * 0.07, W * 0.04)    # back-left paw
    bump(50, W * 0.07, W * 0.04)     # back-right paw
    bump(0, W * 0.10, W * 0.03)      # tail
    return pts


def _shaded_pelt(seed: int) -> Image.Image:
    r = _rand(seed)
    poly = _pelt_path(seed)
    canvas = _parchment_backdrop(seed + 1)

    canvas = Image.alpha_composite(canvas, _drop_shadow(poly, "poly"))

    # base pelt fill — warm grey-brown
    base = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(base, "RGBA").polygon(poly, fill=PELT_BROWN)
    canvas = Image.alpha_composite(canvas, base)

    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)

    # vertical fur-shade gradient
    grad = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad, "RGBA")
    steps = 80
    for i in range(steps):
        t = i / float(steps - 1)
        y0 = int(W * 0.05 + t * W * 0.92)
        y1 = y0 + int(W * 0.92 / steps) + 1
        col = _blend(PELT_BROWN, PELT_BROWN_DK, t * 0.85)
        gd.rectangle((0, y0, W, y1), fill=(col[0], col[1], col[2], 110))
    grad.putalpha(mask)
    canvas = Image.alpha_composite(canvas, grad)

    # fur strokes — short brushy tufts running with body length
    fur = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fur, "RGBA")
    cx, cy = W // 2, int(W * 0.52)
    for _ in range(900):
        x = r.randint(int(cx - W * 0.32), int(cx + W * 0.32))
        y = r.randint(int(cy - W * 0.36), int(cy + W * 0.36))
        length = r.randint(int(W * 0.012), int(W * 0.035))
        ang = r.uniform(-0.4, 0.4)
        x2 = x + int(math.cos(ang) * length)
        y2 = y + int(math.sin(ang) * length)
        ch = r.random()
        if ch < 0.5:
            col = (PELT_BROWN_DK[0], PELT_BROWN_DK[1], PELT_BROWN_DK[2], 80)
        elif ch < 0.8:
            col = (PELT_GREY[0], PELT_GREY[1], PELT_GREY[2], 60)
        else:
            col = (IVORY_LT[0], IVORY_LT[1], IVORY_LT[2], 70)
        fd.line([(x, y), (x2, y2)], fill=col, width=int(W * 0.005))
    fur = fur.filter(ImageFilter.GaussianBlur(radius=W // 220))
    fur.putalpha(_multiply_alpha(fur.split()[-1], mask))
    canvas = Image.alpha_composite(canvas, fur)

    # spine lighter band — warm sun-lit ridge along centerline
    spine = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    spd = ImageDraw.Draw(spine, "RGBA")
    for j in range(60):
        t = j / 59.0
        y = int(W * 0.18 + t * W * 0.66)
        rad = int(W * 0.04 - t * W * 0.012)
        alpha = int(70 * (1 - abs(t - 0.5) * 1.2))
        if alpha < 0: alpha = 0
        spd.ellipse((cx - rad, y - rad, cx + rad, y + rad),
                    fill=(IVORY_LT[0], IVORY_LT[1], IVORY_LT[2], alpha))
    spine = spine.filter(ImageFilter.GaussianBlur(radius=W // 90))
    spine.putalpha(_multiply_alpha(spine.split()[-1], mask))
    canvas = Image.alpha_composite(canvas, spine)

    # ink rim
    canvas = Image.alpha_composite(canvas, _ink_rim_poly(poly))

    # subtle speckle
    sp = _speckle_inside(seed + 7, mask, [
        (PELT_BROWN_DK[0], PELT_BROWN_DK[1], PELT_BROWN_DK[2], 32),
        (IVORY_SHADE[0], IVORY_SHADE[1], IVORY_SHADE[2], 25),
        (INK[0], INK[1], INK[2], 18),
    ], count=600)
    canvas = Image.alpha_composite(canvas, sp)

    return canvas.resize((SIZE, SIZE), Image.LANCZOS)


# ---------------------------------------------------------------- wolf_heart


def _heart_path(seed: int) -> list[tuple[int, int]]:
    """Anatomical-leaning heart silhouette — slightly asymmetric, with a
    cleft at the top and a tapered point at the bottom. Painterly, not
    valentine-cute (THEME §1 — feral wolf trophy)."""
    r = _rand(seed)
    cx, cy = W // 2, int(W * 0.50)
    pts = []
    N = 140
    for i in range(N):
        t = i / N * 2 * math.pi
        # Cardioid-ish: r = a*(1 - sin(t)) with horizontal stretch
        rho = (1 - math.sin(t)) * 0.36 + 0.15
        # asymmetry — slight lean
        rho *= 1.0 + 0.04 * math.cos(t * 3)
        # painterly jitter
        rho *= 1.0 + (r.random() - 0.5) * 0.04
        x = int(cx + math.cos(t) * rho * W)
        y = int(cy - math.sin(t) * rho * W * 0.95 + W * 0.05)
        pts.append((x, y))
    return pts


def _shaded_heart(seed: int) -> Image.Image:
    r = _rand(seed)
    poly = _heart_path(seed)
    canvas = _parchment_backdrop(seed + 1)
    canvas = Image.alpha_composite(canvas, _drop_shadow(poly, "poly"))

    # base wine fill
    base = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(base, "RGBA").polygon(poly, fill=WINE)
    canvas = Image.alpha_composite(canvas, base)

    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)

    # vertical gradient — top-bright (rim-lit) to dark base
    grad = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad, "RGBA")
    steps = 80
    for i in range(steps):
        t = i / float(steps - 1)
        y0 = int(W * 0.05 + t * W * 0.92)
        y1 = y0 + int(W * 0.92 / steps) + 1
        col = _blend(STAG_BLOOD, (60, 12, 12, 255), t * 0.95)
        gd.rectangle((0, y0, W, y1), fill=(col[0], col[1], col[2], 110))
    grad.putalpha(mask)
    canvas = Image.alpha_composite(canvas, grad)

    # wet sheen highlight — soft warm specular on upper-left lobe
    hi = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hi, "RGBA")
    cx = W // 2
    cy = int(W * 0.42)
    for j in range(40):
        t = j / 39.0
        y = int(cy - W * 0.05 + t * W * 0.20)
        x_off = int(W * 0.10 - t * W * 0.04)
        rad = int(W * 0.030 + (1 - t) * W * 0.020)
        alpha = int(150 * (1 - t) + 25)
        hd.ellipse((cx - x_off - rad, y - rad, cx - x_off + rad, y + rad),
                   fill=(IVORY_LT[0], IVORY_LT[1], IVORY_LT[2], alpha))
    hi = hi.filter(ImageFilter.GaussianBlur(radius=W // 90))
    hi.putalpha(_multiply_alpha(hi.split()[-1], mask))
    canvas = Image.alpha_composite(canvas, hi)

    # ventricle vein streaks — fine darker lines tracing the ventricle wall
    veins = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    vd2 = ImageDraw.Draw(veins, "RGBA")
    for k in range(14):
        x0 = int(cx + (r.random() - 0.5) * W * 0.30)
        y0 = int(W * 0.30 + r.random() * W * 0.20)
        path = []
        for s in range(10):
            t = s / 9.0
            x = int(x0 + (r.random() - 0.5) * W * 0.020)
            y = int(y0 + t * W * 0.30)
            path.append((x, y))
        vd2.line(path, fill=(40, 8, 8, 90), width=int(W * 0.005))
    veins = veins.filter(ImageFilter.GaussianBlur(radius=W // 240))
    veins.putalpha(_multiply_alpha(veins.split()[-1], mask))
    canvas = Image.alpha_composite(canvas, veins)

    # brass aorta nub at the top center — small warm ember rim
    aorta = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ad = ImageDraw.Draw(aorta, "RGBA")
    nub_y = int(W * 0.21)
    nub_r = int(W * 0.05)
    ad.ellipse((cx - nub_r, nub_y - nub_r, cx + nub_r, nub_y + nub_r),
               fill=(BRASS[0], BRASS[1], BRASS[2], 200))
    ad.ellipse((cx - nub_r // 2, nub_y - nub_r // 2,
                cx + nub_r // 2, nub_y + nub_r // 2),
               fill=(255, 200, 120, 220))
    aorta = aorta.filter(ImageFilter.GaussianBlur(radius=W // 200))
    canvas = Image.alpha_composite(canvas, aorta)

    # ink rim
    canvas = Image.alpha_composite(canvas, _ink_rim_poly(poly))

    # speckle
    sp = _speckle_inside(seed + 9, mask, [
        (40, 8, 8, 40),
        (STAG_BLOOD[0], STAG_BLOOD[1], STAG_BLOOD[2], 30),
        (INK[0], INK[1], INK[2], 22),
    ], count=700)
    canvas = Image.alpha_composite(canvas, sp)

    return canvas.resize((SIZE, SIZE), Image.LANCZOS)


# ---------------------------------------------------------------- wooden_shield


def _shield_path() -> list[tuple[int, int]]:
    """Heater-style wooden shield: round top, tapered convex sides, point
    at the bottom. Painterly irregular outline.

    Construction walks the silhouette clockwise starting at the left
    shoulder: top semicircle from 9 o'clock around to 3 o'clock, then a
    convex curve down to the bottom point, then a mirror curve back up
    the left side. Side curves bow OUTWARD (cosine-based) so the shield
    reads as wide-then-tapering, not as a tapered diamond.
    """
    cx = W // 2
    top_y = int(W * 0.14)
    shoulder_y = int(W * 0.30)
    bottom_y = int(W * 0.92)
    half_w = int(W * 0.32)

    pts = []
    M = 48
    for i in range(M + 1):
        t = i / M
        a = math.pi - t * math.pi
        x = int(cx + math.cos(a) * half_w)
        y_arc = shoulder_y - int(math.sin(a) * (shoulder_y - top_y))
        pts.append((x, y_arc))
    K = 32
    for i in range(1, K + 1):
        t = i / K
        w = int(half_w * math.cos(t * math.pi / 2.0))
        y = int(shoulder_y + (bottom_y - shoulder_y) * t)
        pts.append((cx + w, y))
    pts.append((cx, bottom_y))
    for i in range(1, K + 1):
        t = 1.0 - i / K
        w = int(half_w * math.cos(t * math.pi / 2.0))
        y = int(shoulder_y + (bottom_y - shoulder_y) * t)
        pts.append((cx - w, y))
    return pts


def _shaded_shield(seed: int) -> Image.Image:
    r = _rand(seed)
    poly = _shield_path()
    canvas = _parchment_backdrop(seed + 1)
    canvas = Image.alpha_composite(canvas, _drop_shadow(poly, "poly"))

    # base wood fill
    base = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(base, "RGBA").polygon(poly, fill=WOOD)
    canvas = Image.alpha_composite(canvas, base)

    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)

    # vertical wood-grain bands — three planks
    planks = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    pd = ImageDraw.Draw(planks, "RGBA")
    cx = W // 2
    plank_xs = [cx - int(W * 0.20), cx, cx + int(W * 0.20)]
    for px in plank_xs:
        # vertical light gradient stripe per plank
        for k in range(40):
            t = k / 39.0
            yk = int(W * 0.15 + t * W * 0.74)
            col = _blend(WOOD_LT, WOOD_DK, t * 0.85 + (px - cx) * 0.0005)
            pd.rectangle((px - int(W * 0.10), yk,
                          px + int(W * 0.10), yk + int(W * 0.74 / 40) + 1),
                         fill=(col[0], col[1], col[2], 110))
    # fine grain lines
    for _ in range(180):
        x0 = r.randint(int(W * 0.16), int(W * 0.84))
        y0 = r.randint(int(W * 0.20), int(W * 0.86))
        length = r.randint(int(W * 0.04), int(W * 0.16))
        col = (WOOD_DK[0], WOOD_DK[1], WOOD_DK[2], 90)
        pd.line([(x0, y0), (x0 + length, y0 + r.randint(-2, 2))],
                fill=col, width=int(W * 0.005))
    planks = planks.filter(ImageFilter.GaussianBlur(radius=W // 220))
    planks.putalpha(mask)
    canvas = Image.alpha_composite(canvas, planks)

    # iron rim band
    rim = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rim, "RGBA")
    rd.polygon(poly, outline=IRON, width=int(W * 0.025))
    rim = rim.filter(ImageFilter.GaussianBlur(radius=W // 220))
    rim.putalpha(_multiply_alpha(rim.split()[-1], mask))
    canvas = Image.alpha_composite(canvas, rim)

    # iron rivets — six rivets evenly spaced just inside the rim
    riv = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    rvd = ImageDraw.Draw(riv, "RGBA")
    rivet_positions = [
        (cx, int(W * 0.18)),
        (cx - int(W * 0.24), int(W * 0.30)),
        (cx + int(W * 0.24), int(W * 0.30)),
        (cx - int(W * 0.18), int(W * 0.74)),
        (cx + int(W * 0.18), int(W * 0.74)),
        (cx, int(W * 0.86)),
    ]
    rad = int(W * 0.024)
    for (x, y) in rivet_positions:
        # shadow under rivet
        rvd.ellipse((x - rad + 2, y - rad + 2, x + rad + 2, y + rad + 2),
                    fill=(0, 0, 0, 120))
        # base rivet
        rvd.ellipse((x - rad, y - rad, x + rad, y + rad), fill=IRON_DK)
        rvd.ellipse((x - rad + 2, y - rad + 2, x + rad - 2, y + rad - 2),
                    fill=IRON)
        # specular dot
        sd_r = max(2, rad // 3)
        rvd.ellipse((x - sd_r, y - sd_r - 2, x + sd_r, y + sd_r - 2),
                    fill=IRON_LT)
    riv = riv.filter(ImageFilter.GaussianBlur(radius=W // 320))
    canvas = Image.alpha_composite(canvas, riv)

    # central iron boss — round dome at the shield's heart
    boss = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    bd = ImageDraw.Draw(boss, "RGBA")
    boss_r = int(W * 0.11)
    cy_b = int(W * 0.50)
    # shadow
    bd.ellipse((cx - boss_r + 4, cy_b - boss_r + 4,
                cx + boss_r + 4, cy_b + boss_r + 4),
               fill=(0, 0, 0, 130))
    bd.ellipse((cx - boss_r, cy_b - boss_r,
                cx + boss_r, cy_b + boss_r),
               fill=IRON_DK)
    # body
    bd.ellipse((cx - boss_r + 4, cy_b - boss_r + 4,
                cx + boss_r - 4, cy_b + boss_r - 4),
               fill=IRON)
    # specular highlight
    spec_r = boss_r // 2
    bd.ellipse((cx - spec_r, cy_b - spec_r - 6,
                cx + spec_r, cy_b + spec_r - 6),
               fill=IRON_LT)
    boss = boss.filter(ImageFilter.GaussianBlur(radius=W // 280))
    canvas = Image.alpha_composite(canvas, boss)

    # ink rim
    canvas = Image.alpha_composite(canvas, _ink_rim_poly(poly))

    # subtle speckle — wear and dirt
    sp = _speckle_inside(seed + 5, mask, [
        (WOOD_DK[0], WOOD_DK[1], WOOD_DK[2], 38),
        (PARCHMENT_DK[0], PARCHMENT_DK[1], PARCHMENT_DK[2], 28),
        (INK[0], INK[1], INK[2], 22),
    ], count=600)
    canvas = Image.alpha_composite(canvas, sp)

    # warm sunset glow at top-left rim — THEME §3 sunset accent
    glow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    gld = ImageDraw.Draw(glow, "RGBA")
    glow_cx = int(W * 0.32)
    glow_cy = int(W * 0.30)
    for radius_band in (W * 0.20, W * 0.14, W * 0.08):
        rb = int(radius_band)
        alpha = int(28 * (1.0 - radius_band / (W * 0.20)) + 18)
        gld.ellipse((glow_cx - rb, glow_cy - rb,
                     glow_cx + rb, glow_cy + rb),
                    fill=(255, 175, 90, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=W // 22))
    glow.putalpha(_multiply_alpha(glow.split()[-1], mask))
    canvas = Image.alpha_composite(canvas, glow)

    return canvas.resize((SIZE, SIZE), Image.LANCZOS)


# ---------------------------------------------------------------- wolf_fang
# (Run-23 implementation — preserved verbatim so re-runs produce identical
# bytes for wolf_fang.png. Compact-form refactor of the original file.)


def _fang_path(super_w: int) -> list[tuple[int, int]]:
    cx = super_w // 2
    top_y = int(super_w * 0.12)
    gum_y = int(super_w * 0.30)
    tip_y = int(super_w * 0.93)
    tip_x = cx - int(super_w * 0.08)
    root_cx = cx + int(super_w * 0.02)
    root_half = int(super_w * 0.16)
    gum_half = int(super_w * 0.21)
    N = 40
    pts_r = []
    for i in range(N + 1):
        t = i / N
        y = gum_y + (tip_y - gum_y) * (t * t * (3 - 2 * t))
        w0 = gum_half
        w1 = int(super_w * 0.07)
        w2 = 0
        bezier_w = (1 - t) ** 2 * w0 + 2 * (1 - t) * t * w1 + t ** 2 * w2
        bias_t = t * t
        bx = root_cx * (1 - bias_t) + tip_x * bias_t
        pts_r.append((int(bx + bezier_w), int(y)))
    pts_l = []
    for i in range(N + 1):
        t = 1.0 - i / N
        y = gum_y + (tip_y - gum_y) * (t * t * (3 - 2 * t))
        w0 = gum_half
        w1 = int(super_w * 0.07)
        w2 = 0
        bezier_w = (1 - t) ** 2 * w0 + 2 * (1 - t) * t * w1 + t ** 2 * w2
        bias_t = t * t
        bx = root_cx * (1 - bias_t) + tip_x * bias_t
        pts_l.append((int(bx - bezier_w), int(y)))
    crown = []
    M = 18
    for i in range(M + 1):
        t = i / M
        x = root_cx + (-root_half + 2 * root_half * t)
        dip = 4 * t * (1 - t)
        y = gum_y - (gum_y - top_y) * dip
        crown.append((int(x), int(y)))
    return crown + pts_r + pts_l


def _shaded_fang(seed: int) -> Image.Image:
    r = _rand(seed)
    poly = _fang_path(W)
    canvas = _parchment_backdrop(seed + 1)
    canvas = Image.alpha_composite(canvas, _drop_shadow(poly, "poly"))

    base = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(base, "RGBA").polygon(poly, fill=IVORY)
    canvas = Image.alpha_composite(canvas, base)

    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)

    grad = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad, "RGBA")
    steps = 80
    for i in range(steps):
        t = i / float(steps - 1)
        y0 = int(W * 0.05 + t * W * 0.92)
        y1 = y0 + int(W * 0.92 / steps) + 1
        col = _blend(IVORY_LT, IVORY_SHADE, t * 0.85)
        gd.rectangle((0, y0, W, y1), fill=(col[0], col[1], col[2], 95))
    grad.putalpha(mask)
    canvas = Image.alpha_composite(canvas, grad)

    hi = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hi, "RGBA")
    cx = W // 2
    for j in range(40):
        t = j / 39.0
        y = int(W * 0.18 + t * W * 0.62)
        x_off = int(W * 0.06 - t * W * 0.04)
        rad = int(W * 0.018 + (1 - t) * W * 0.012)
        alpha = int(150 * (1 - t) + 30)
        hd.ellipse((cx - x_off - rad, y - rad, cx - x_off + rad, y + rad),
                   fill=(IVORY_LT[0], IVORY_LT[1], IVORY_LT[2], alpha))
    hi = hi.filter(ImageFilter.GaussianBlur(radius=W // 90))
    hi.putalpha(_multiply_alpha(hi.split()[-1], mask))
    canvas = Image.alpha_composite(canvas, hi)

    canvas = Image.alpha_composite(canvas, _ink_rim_poly(poly))

    sp = _speckle_inside(seed + 5, mask, [
        (PARCHMENT_DK[0], PARCHMENT_DK[1], PARCHMENT_DK[2], 35),
        (IVORY_SHADE[0], IVORY_SHADE[1], IVORY_SHADE[2], 28),
        (INK[0], INK[1], INK[2], 22),
    ], count=900)
    canvas = Image.alpha_composite(canvas, sp)
    return canvas.resize((SIZE, SIZE), Image.LANCZOS)


# ---------------------------------------------------------------- post


def _palette_quantize(img, colors=128):
    rgb = img.convert("RGB").quantize(
        colors=colors,
        method=Image.Quantize.FASTOCTREE,
        dither=Image.Dither.FLOYDSTEINBERG,
    ).convert("RGBA")
    r, g, b, _ = rgb.split()
    _, _, _, a = img.split()
    import numpy as _np
    a_arr = _np.array(a)
    a_arr = (a_arr // 16) * 16
    from PIL import Image as _PI
    a2 = _PI.fromarray(a_arr, "L")
    return _PI.merge("RGBA", (r, g, b, a2))


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out_dir, exist_ok=True)

    targets = [
        ("wolf_fang.png",      _shaded_fang,    20260505, 96),
        ("wolf_pelt.png",      _shaded_pelt,    20260506, 128),
        ("wolf_heart.png",     _shaded_heart,   20260507, 112),
        ("wooden_shield.png",  _shaded_shield,  20260508, 128),
    ]
    for name, fn, seed, colors in targets:
        img = fn(seed)
        img = _palette_quantize(img, colors=colors)
        out = os.path.join(out_dir, name)
        img.save(out, "PNG", optimize=True)
        print(f"wrote {out} ({os.path.getsize(out)} bytes)")


if __name__ == "__main__":
    main()
