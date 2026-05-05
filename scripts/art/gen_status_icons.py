#!/usr/bin/env python3
"""
Realm of Eldoria — procedural status-effect badge generator.

Produces 8 painterly 64x64 PNG badges for the buff/debuff bar — a new
art category complementing the existing affix/achievement crests. Each
badge follows the same painterly disc-with-symbol convention as
gen_affix_icons.py: irregular brushstroke rim, flecked highlights,
THEME.md §3 palette only.

Buffs (positive, warm palette): blessed, swift, shielded, regen
Debuffs (negative, cool/sickly palette): burning, frozen, poisoned, stunned

Style targets (THEME.md):
  - §1 painterly hand-painted concept-art aesthetic
  - §3 palette compliance — no neon, no fluorescent, no pure white
  - §5 hand-painted look, not crisp vector

License: CC0 — generated procedurally with Pillow, no external assets.
"""
from __future__ import annotations

import math
import os
import random
import sys
from PIL import Image, ImageDraw, ImageFilter

SIZE = 64
SUPER = 4
W = SIZE * SUPER

# THEME.md §3 palette
PARCHMENT = (217, 201, 155, 255)
INK = (14, 10, 14, 255)
SUNSET_GOLD = (255, 200, 80, 255)
CRIMSON = (140, 32, 32, 255)
WINE = (104, 28, 32, 255)
MOSS = (74, 112, 56, 255)
BRASS = (176, 116, 42, 255)
BRONZE = (140, 92, 36, 255)
FROST_CYAN = (101, 223, 229, 255)
ARCANE = (124, 63, 176, 255)
SILVER = (200, 224, 229, 255)
EMBER = (255, 128, 0, 255)
BEAR_BROWN = (135, 90, 50, 255)
SWIFT_GREEN = (140, 200, 110, 255)
SLATE = (123, 134, 147, 255)
SICKLY_GREEN = (96, 132, 60, 255)
PALE_GOLD = (255, 216, 107, 255)


def _rand(seed):
    return random.Random(seed)


def _paint_disc(img, draw, base, rim, accent, seed):
    r = _rand(seed)
    cx, cy = W // 2, W // 2
    radius = int(W * 0.46)
    # gradient body
    for i in range(18, 0, -1):
        t = i / 18.0
        col = (
            int(base[0] * (0.55 + 0.45 * (1 - t))),
            int(base[1] * (0.55 + 0.45 * (1 - t))),
            int(base[2] * (0.55 + 0.45 * (1 - t))),
            int(220 * t),
        )
        rr = int(radius * t)
        draw.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=col)
    # rim with brushstroke wobble
    for k in range(48):
        ang = (k / 48.0) * math.tau + r.uniform(-0.05, 0.05)
        jitter = r.uniform(-0.02, 0.02) * radius
        rr = radius + jitter
        x0 = cx + math.cos(ang - 0.06) * rr
        y0 = cy + math.sin(ang - 0.06) * rr
        x1 = cx + math.cos(ang + 0.06) * rr
        y1 = cy + math.sin(ang + 0.06) * rr
        w = max(2, int(SUPER * (1.6 + r.uniform(-0.4, 0.6))))
        draw.line((x0, y0, x1, y1), fill=rim, width=w)
    # accent flecks
    for _ in range(8):
        ang = r.uniform(0, math.tau)
        rr = r.uniform(0.05, 0.85) * radius
        x = cx + math.cos(ang) * rr
        y = cy + math.sin(ang) * rr
        s = r.randint(2, 4) * SUPER // 2
        col = (accent[0], accent[1], accent[2], r.randint(40, 110))
        draw.ellipse((x - s, y - s, x + s, y + s), fill=col)


def _draw_burning(draw, seed):
    """Tongue of flame — debuff."""
    r = _rand(seed)
    cx, cy = W // 2, W // 2 + int(W * 0.05)
    h = int(W * 0.42)
    # flame outline as bezier-ish polygon, two layers
    inner = (PALE_GOLD[0], PALE_GOLD[1], PALE_GOLD[2], 255)
    outer = (EMBER[0], EMBER[1], EMBER[2], 255)
    pts_outer = [
        (cx, cy - h),
        (cx + h * 0.45, cy - h * 0.25),
        (cx + h * 0.55, cy + h * 0.30),
        (cx + h * 0.20, cy + h * 0.55),
        (cx - h * 0.20, cy + h * 0.55),
        (cx - h * 0.55, cy + h * 0.30),
        (cx - h * 0.45, cy - h * 0.25),
    ]
    draw.polygon(pts_outer, fill=outer)
    pts_inner = [
        (cx, cy - h * 0.55),
        (cx + h * 0.25, cy - h * 0.05),
        (cx + h * 0.30, cy + h * 0.30),
        (cx, cy + h * 0.45),
        (cx - h * 0.30, cy + h * 0.30),
        (cx - h * 0.25, cy - h * 0.05),
    ]
    draw.polygon(pts_inner, fill=inner)
    # tip drip
    draw.ellipse(
        (cx - h * 0.07, cy - h * 1.05, cx + h * 0.07, cy - h * 0.85),
        fill=outer,
    )


def _draw_frozen(draw, seed):
    """Icicle drip — debuff."""
    r = _rand(seed)
    cx, cy = W // 2, W // 2
    h = int(W * 0.42)
    pale = (SILVER[0], SILVER[1], SILVER[2], 255)
    cyan = (FROST_CYAN[0], FROST_CYAN[1], FROST_CYAN[2], 255)
    # main icicle (downward triangle with rounded top)
    pts = [
        (cx - h * 0.30, cy - h * 0.55),
        (cx + h * 0.30, cy - h * 0.55),
        (cx + h * 0.10, cy + h * 0.85),
        (cx - h * 0.10, cy + h * 0.85),
    ]
    draw.polygon(pts, fill=cyan)
    # highlight stripe
    pts2 = [
        (cx - h * 0.10, cy - h * 0.50),
        (cx + h * 0.05, cy - h * 0.50),
        (cx, cy + h * 0.78),
    ]
    draw.polygon(pts2, fill=pale)
    # rim of top
    draw.ellipse(
        (cx - h * 0.30, cy - h * 0.65, cx + h * 0.30, cy - h * 0.45),
        fill=pale,
    )


def _draw_poisoned(draw, seed):
    """Falling drop with skull-tinge — debuff."""
    r = _rand(seed)
    cx, cy = W // 2, W // 2
    h = int(W * 0.42)
    sick = (SICKLY_GREEN[0], SICKLY_GREEN[1], SICKLY_GREEN[2], 255)
    moss = (MOSS[0], MOSS[1], MOSS[2], 255)
    # teardrop
    pts = [
        (cx, cy - h * 0.75),
        (cx + h * 0.45, cy + h * 0.10),
        (cx + h * 0.30, cy + h * 0.55),
        (cx - h * 0.30, cy + h * 0.55),
        (cx - h * 0.45, cy + h * 0.10),
    ]
    draw.polygon(pts, fill=moss)
    # inner highlight
    pts_in = [
        (cx, cy - h * 0.50),
        (cx + h * 0.20, cy + h * 0.05),
        (cx + h * 0.10, cy + h * 0.35),
        (cx - h * 0.10, cy + h * 0.35),
        (cx - h * 0.20, cy + h * 0.05),
    ]
    draw.polygon(pts_in, fill=sick)
    # bubbles around
    for _ in range(5):
        ang = r.uniform(0, math.tau)
        rr = r.uniform(0.55, 0.78) * h
        x = cx + math.cos(ang) * rr
        y = cy + math.sin(ang) * rr
        s = r.randint(3, 6) * SUPER // 2
        draw.ellipse((x - s, y - s, x + s, y + s), fill=(moss[0], moss[1], moss[2], 200))


def _draw_stunned(draw, seed):
    """Three-star spin — debuff."""
    r = _rand(seed)
    cx, cy = W // 2, W // 2
    h = int(W * 0.42)
    star_col = (PALE_GOLD[0], PALE_GOLD[1], PALE_GOLD[2], 255)
    rim_col = (BRASS[0], BRASS[1], BRASS[2], 240)
    for i in range(3):
        ang = i * math.tau / 3 - math.pi / 2
        rr = h * 0.55
        scx = cx + math.cos(ang) * rr
        scy = cy + math.sin(ang) * rr
        sz = h * 0.25
        # 4-point star
        pts = [
            (scx, scy - sz),
            (scx + sz * 0.30, scy - sz * 0.30),
            (scx + sz, scy),
            (scx + sz * 0.30, scy + sz * 0.30),
            (scx, scy + sz),
            (scx - sz * 0.30, scy + sz * 0.30),
            (scx - sz, scy),
            (scx - sz * 0.30, scy - sz * 0.30),
        ]
        draw.polygon(pts, fill=star_col)
        draw.line((scx, scy - sz, scx, scy + sz), fill=rim_col, width=int(SUPER * 0.8))


def _draw_blessed(draw, seed):
    """Sunburst halo — buff."""
    r = _rand(seed)
    cx, cy = W // 2, W // 2
    h = int(W * 0.42)
    gold = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], 255)
    pale = (PALE_GOLD[0], PALE_GOLD[1], PALE_GOLD[2], 255)
    # 12 rays
    for i in range(12):
        ang = i * math.tau / 12
        long = i % 2 == 0
        ln = h * (0.78 if long else 0.55)
        x1 = cx + math.cos(ang) * ln
        y1 = cy + math.sin(ang) * ln
        draw.line((cx, cy, x1, y1), fill=gold, width=int(SUPER * 1.4))
    # core sun
    rr = int(h * 0.32)
    draw.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=pale)
    rr2 = int(h * 0.20)
    draw.ellipse((cx - rr2, cy - rr2, cx + rr2, cy + rr2), fill=gold)


def _draw_swift(draw, seed):
    """Three trailing wind streaks — buff."""
    r = _rand(seed)
    cx, cy = W // 2, W // 2
    h = int(W * 0.42)
    moss = (MOSS[0], MOSS[1], MOSS[2], 255)
    swift = (SWIFT_GREEN[0], SWIFT_GREEN[1], SWIFT_GREEN[2], 255)
    # three streaks angled rightward
    for i, off in enumerate((-0.42, 0.0, 0.42)):
        sy = cy + h * off
        x0 = cx - h * 0.65
        x1 = cx + h * 0.50 - i * h * 0.05
        col = swift if i == 1 else moss
        draw.line((x0, sy, x1, sy), fill=col, width=int(SUPER * 1.6))
        # arrow tip
        draw.polygon(
            [
                (x1 + h * 0.18, sy),
                (x1, sy - h * 0.10),
                (x1, sy + h * 0.10),
            ],
            fill=col,
        )


def _draw_shielded(draw, seed):
    """Heater shield bracket — buff."""
    r = _rand(seed)
    cx, cy = W // 2, W // 2
    h = int(W * 0.42)
    bronze = (BRONZE[0], BRONZE[1], BRONZE[2], 255)
    brass = (BRASS[0], BRASS[1], BRASS[2], 255)
    # heater shield silhouette
    pts = [
        (cx - h * 0.55, cy - h * 0.65),
        (cx + h * 0.55, cy - h * 0.65),
        (cx + h * 0.55, cy - h * 0.10),
        (cx, cy + h * 0.78),
        (cx - h * 0.55, cy - h * 0.10),
    ]
    draw.polygon(pts, fill=bronze)
    # inner band
    pts_in = [
        (cx - h * 0.42, cy - h * 0.50),
        (cx + h * 0.42, cy - h * 0.50),
        (cx + h * 0.42, cy - h * 0.05),
        (cx, cy + h * 0.55),
        (cx - h * 0.42, cy - h * 0.05),
    ]
    draw.polygon(pts_in, fill=brass)
    # boss stud
    rr = int(h * 0.14)
    draw.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=bronze)


def _draw_regen(draw, seed):
    """Leaf-heart pairing — buff."""
    r = _rand(seed)
    cx, cy = W // 2, W // 2
    h = int(W * 0.42)
    moss = (MOSS[0], MOSS[1], MOSS[2], 255)
    swift = (SWIFT_GREEN[0], SWIFT_GREEN[1], SWIFT_GREEN[2], 255)
    crimson = (CRIMSON[0], CRIMSON[1], CRIMSON[2], 255)
    # leaf body (almond shape)
    pts = [
        (cx, cy - h * 0.75),
        (cx + h * 0.45, cy - h * 0.10),
        (cx + h * 0.10, cy + h * 0.65),
        (cx - h * 0.10, cy + h * 0.65),
        (cx - h * 0.45, cy - h * 0.10),
    ]
    draw.polygon(pts, fill=moss)
    pts_in = [
        (cx, cy - h * 0.55),
        (cx + h * 0.28, cy - h * 0.05),
        (cx, cy + h * 0.50),
        (cx - h * 0.28, cy - h * 0.05),
    ]
    draw.polygon(pts_in, fill=swift)
    # central stem
    draw.line(
        (cx, cy - h * 0.55, cx, cy + h * 0.50),
        fill=moss,
        width=int(SUPER * 0.8),
    )
    # tiny heart at base
    hr = int(h * 0.18)
    draw.ellipse((cx - hr, cy + h * 0.20, cx, cy + h * 0.20 + hr), fill=crimson)
    draw.ellipse((cx, cy + h * 0.20, cx + hr, cy + h * 0.20 + hr), fill=crimson)
    draw.polygon(
        [
            (cx - hr, cy + h * 0.20 + hr * 0.55),
            (cx + hr, cy + h * 0.20 + hr * 0.55),
            (cx, cy + h * 0.55),
        ],
        fill=crimson,
    )


BADGES = [
    # (slug, base, rim, accent, draw_fn)
    ("burning",  (140, 60, 30, 255), EMBER,       SUNSET_GOLD,  _draw_burning),
    ("frozen",   (60, 90, 110, 255), FROST_CYAN,  SILVER,       _draw_frozen),
    ("poisoned", (60, 80, 50, 255),  MOSS,        SWIFT_GREEN,  _draw_poisoned),
    ("stunned",  (90, 95, 105, 255), SLATE,       PALE_GOLD,    _draw_stunned),
    ("blessed",  (140, 110, 40, 255),SUNSET_GOLD, PALE_GOLD,    _draw_blessed),
    ("swift",    (70, 110, 60, 255), MOSS,        SWIFT_GREEN,  _draw_swift),
    ("shielded", (130, 90, 35, 255), BRONZE,      BRASS,        _draw_shielded),
    ("regen",    (80, 120, 70, 255), MOSS,        SWIFT_GREEN,  _draw_regen),
]


def make_badge(slug, base, rim, accent, draw_fn):
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    seed_base = sum(ord(c) for c in slug) * 7
    _paint_disc(img, draw, base, rim, accent, seed_base)
    draw_fn(draw, seed_base + 17)
    # painterly soften
    img = img.filter(ImageFilter.GaussianBlur(radius=0.30 * SUPER))
    # circular alpha mask
    mask = Image.new("L", (W, W), 0)
    md = ImageDraw.Draw(mask)
    cx, cy = W // 2, W // 2
    radius = int(W * 0.49)
    md.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(radius=0.18 * SUPER))
    img.putalpha(mask)
    out = img.resize((SIZE, SIZE), Image.LANCZOS)
    return out


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out_dir, exist_ok=True)
    for slug, base, rim, accent, fn in BADGES:
        img = make_badge(slug, base, rim, accent, fn)
        path = os.path.join(out_dir, f"{slug}.png")
        img.save(path)
        print(f"  wrote {path}")


if __name__ == "__main__":
    main()
