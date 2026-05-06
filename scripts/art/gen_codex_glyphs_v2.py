#!/usr/bin/env python3
"""
Realm of Eldoria — codex glyph icons (batch v2)
================================================

Adds four new painterly 128x128 codex chapter glyphs that fit THEME.md
sections 1, 3, and 5 (painterly hand-painted, parchment+ink+bronze
palette, hand-drawn-feel banners/signs).

Glyphs added in this batch
--------------------------
  - the_sundering.png   : a broken seal / cracked sun-wheel disk.
                          Symbol for the world-shattering event referenced
                          in THEME.md §7 ("The Sundering destroyed
                          something they're rebuilding").
  - oath_of_thorns.png  : a circle of intertwined briar / thorn branches.
                          Fits Briarwood village identity (THEME.md §8).
  - wyrmsong_winds.png  : curling wind/dragon breath spirals.
                          Whisperwood / Far Mountains atmosphere.
  - sunken_chord.png    : a stylized anchor crossed with a harp string.
                          Stormwatch port lore; coastal mood.

All glyphs share the existing codex disc treatment from
gen_codex_glyphs.py (mottled parchment disc, worn bronze ring, brushy
grain pass) so they read as one consistent set when stacked in the
codex list panel.

Pure Pillow + NumPy. CC0. No external assets, fonts, or trademarks.

Run:  python3 scripts/art/gen_codex_glyphs_v2.py <out_dir>
Output: <out_dir>/{the_sundering,oath_of_thorns,wyrmsong_winds,sunken_chord}.png
"""
from __future__ import annotations

import math
import os
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter
import numpy as np

SIZE = 128
SEED = 8131  # match repo convention

# THEME.md §3 palette
PARCHMENT  = (217, 201, 155, 255)
PARCHMENT_DARK = (181, 161, 116, 255)
INK        = (14, 10, 14, 255)
BRASS      = (176, 116, 42, 255)
BRASS_DARK = (110, 72, 24, 255)
MOSS       = (74, 112, 56, 255)
WINE       = (140, 32, 32, 255)
STONE_BLUE = (123, 134, 147, 255)
FROST_SLV  = (200, 224, 229, 255)
SUNSET_GLD = (255, 216, 107, 255)


# ---------- shared base treatments (matches v1 codex set) ------------------

def _parchment_disc(rng: random.Random) -> Image.Image:
    """Soft mottled parchment circle on transparent canvas."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = cy = SIZE / 2
    r = SIZE * 0.46
    # base disc
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=PARCHMENT)
    # mottle: scatter darker translucent dabs
    for _ in range(160):
        x = rng.uniform(0, SIZE)
        y = rng.uniform(0, SIZE)
        if (x - cx) ** 2 + (y - cy) ** 2 > (r - 2) ** 2:
            continue
        rad = rng.uniform(1.2, 3.5)
        a = rng.randint(18, 60)
        col = (PARCHMENT_DARK[0], PARCHMENT_DARK[1], PARCHMENT_DARK[2], a)
        m = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        ImageDraw.Draw(m).ellipse((x - rad, y - rad, x + rad, y + rad), fill=col)
        img = Image.alpha_composite(img, m)
    img = img.filter(ImageFilter.GaussianBlur(radius=0.6))
    return img


def _bronze_ring(img: Image.Image) -> Image.Image:
    """Worn bronze ring around the disc."""
    cx = cy = SIZE / 2
    r = SIZE * 0.46
    ring = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(ring)
    d.ellipse((cx - r - 3, cy - r - 3, cx + r + 3, cy + r + 3), outline=BRASS_DARK, width=3)
    d.ellipse((cx - r - 1, cy - r - 1, cx + r + 1, cy + r + 1), outline=BRASS, width=2)
    rng = random.Random(SEED + 17)
    for _ in range(28):
        ang = rng.uniform(0, math.tau)
        rr = r + rng.uniform(-1.5, 2.5)
        x = cx + math.cos(ang) * rr
        y = cy + math.sin(ang) * rr
        ImageDraw.Draw(ring).ellipse((x - 1.5, y - 1.5, x + 1.5, y + 1.5), fill=(0, 0, 0, 0))
    return Image.alpha_composite(img, ring)


def _grain_pass(img: Image.Image, rng: random.Random) -> Image.Image:
    """Add brushy grain so it feels hand-painted."""
    grain = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(grain)
    cx = cy = SIZE / 2
    r = SIZE * 0.46
    for _ in range(220):
        x = rng.uniform(2, SIZE - 2)
        y = rng.uniform(2, SIZE - 2)
        if (x - cx) ** 2 + (y - cy) ** 2 > (r - 1) ** 2:
            continue
        a = rng.randint(8, 36)
        d.point((x, y), fill=(14, 10, 14, a))
    return Image.alpha_composite(img, grain)


def _ink_stroke(d: ImageDraw.ImageDraw, pts, width=3, color=INK):
    """Hand-painted-feel polyline (slight wobble)."""
    if len(pts) < 2:
        return
    for i in range(len(pts) - 1):
        d.line([pts[i], pts[i + 1]], fill=color, width=width)
    for x, y in pts:
        rr = max(1, width // 2)
        d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=color)


def _wobble(pts, rng: random.Random, amp=0.7):
    out = []
    for x, y in pts:
        out.append((x + rng.uniform(-amp, amp), y + rng.uniform(-amp, amp)))
    return out


# ---------- glyph 1: the_sundering — cracked sun-wheel ---------------------

def glyph_the_sundering(rng: random.Random) -> Image.Image:
    img = _parchment_disc(rng)
    cx = cy = SIZE / 2

    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    rr = SIZE * 0.27
    d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=SUNSET_GLD)
    for k in range(8):
        a = k * math.tau / 8 + math.pi / 16
        x1 = cx + math.cos(a) * (rr + 2)
        y1 = cy + math.sin(a) * (rr + 2)
        x2 = cx + math.cos(a) * (rr + 12)
        y2 = cy + math.sin(a) * (rr + 12)
        _ink_stroke(d, _wobble([(x1, y1), (x2, y2)], rng, amp=0.6), width=3, color=BRASS_DARK)
    img = Image.alpha_composite(img, overlay)

    crack_pts = [
        (cx - rr * 1.05, cy - rr * 0.25),
        (cx - rr * 0.30, cy + rr * 0.10),
        (cx + rr * 0.05, cy - rr * 0.20),
        (cx + rr * 0.45, cy + rr * 0.30),
        (cx + rr * 1.05, cy + rr * 0.05),
    ]
    crack = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cd = ImageDraw.Draw(crack)
    _ink_stroke(cd, _wobble(crack_pts, rng, amp=0.9), width=4, color=WINE)
    _ink_stroke(cd, _wobble(crack_pts, rng, amp=0.4), width=2, color=INK)
    img = Image.alpha_composite(img, crack)

    img = _bronze_ring(img)
    img = _grain_pass(img, rng)
    return img


# ---------- glyph 2: oath_of_thorns — briar wreath -------------------------

def glyph_oath_of_thorns(rng: random.Random) -> Image.Image:
    img = _parchment_disc(rng)
    cx = cy = SIZE / 2

    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    R = SIZE * 0.30
    for direction in (1, -1):
        pts = []
        for t in np.linspace(0, math.tau, 96):
            wob = math.sin(t * 5 + (0 if direction == 1 else 1.4)) * 3.0
            x = cx + math.cos(t) * (R + wob * direction)
            y = cy + math.sin(t) * (R + wob * direction)
            pts.append((x, y))
        _ink_stroke(d, _wobble(pts, rng, amp=0.5), width=2, color=MOSS)

    for k in range(20):
        t = k * math.tau / 20 + 0.05
        bx = cx + math.cos(t) * R
        by = cy + math.sin(t) * R
        nx = math.cos(t + math.pi / 2) * 5
        ny = math.sin(t + math.pi / 2) * 5
        _ink_stroke(
            d,
            _wobble([(bx, by), (bx + nx, by + ny)], rng, amp=0.4),
            width=2,
            color=INK,
        )

    leaf_centers = []
    for angle in (math.radians(-30), math.radians(150)):
        lx = cx + math.cos(angle) * 6
        ly = cy + math.sin(angle) * 6
        leaf_centers.append((lx, ly))
    for lx, ly in leaf_centers:
        leaf = [
            (lx, ly - 8),
            (lx + 5, ly - 2),
            (lx, ly + 8),
            (lx - 5, ly - 2),
            (lx, ly - 8),
        ]
        d.polygon(leaf, fill=MOSS, outline=INK)

    img = Image.alpha_composite(img, overlay)
    img = _bronze_ring(img)
    img = _grain_pass(img, rng)
    return img


# ---------- glyph 3: wyrmsong_winds — curling wind spirals ----------------

def glyph_wyrmsong_winds(rng: random.Random) -> Image.Image:
    img = _parchment_disc(rng)
    cx = cy = SIZE / 2

    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    bands = [
        (cy - 14, STONE_BLUE),
        (cy + 2,  FROST_SLV),
        (cy + 18, STONE_BLUE),
    ]
    for y0, col in bands:
        pts = []
        for x in np.linspace(cx - SIZE * 0.30, cx + SIZE * 0.30, 60):
            wave = math.sin((x - cx) * 0.18) * 3.5
            pts.append((float(x), float(y0 + wave)))
        _ink_stroke(d, _wobble(pts, rng, amp=0.5), width=3, color=col)
        ex, ey = pts[-1]
        for k in range(14):
            ang = k * 0.55
            r = 1.2 + k * 0.45
            sx = ex + math.cos(ang) * r
            sy = ey + math.sin(ang) * r
            d.ellipse((sx - 1.0, sy - 1.0, sx + 1.0, sy + 1.0), fill=col)

    _ink_stroke(
        d,
        _wobble([(cx - 30, cy + 2), (cx + 30, cy + 2)], rng, amp=0.3),
        width=1,
        color=INK,
    )

    img = Image.alpha_composite(img, overlay)
    img = _bronze_ring(img)
    img = _grain_pass(img, rng)
    return img


# ---------- glyph 4: sunken_chord — anchor + harp-string ------------------

def glyph_sunken_chord(rng: random.Random) -> Image.Image:
    img = _parchment_disc(rng)
    cx = cy = SIZE / 2

    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    shaft = [(cx, cy - 22), (cx, cy + 18)]
    _ink_stroke(d, _wobble(shaft, rng, amp=0.4), width=4, color=STONE_BLUE)

    bar = [(cx - 14, cy - 16), (cx + 14, cy - 16)]
    _ink_stroke(d, _wobble(bar, rng, amp=0.3), width=3, color=STONE_BLUE)

    d.ellipse((cx - 5, cy - 30, cx + 5, cy - 20), outline=STONE_BLUE, width=2)

    arc_pts_l = []
    arc_pts_r = []
    for t in np.linspace(0, 1, 24):
        a = math.pi * 0.55 + t * (math.pi * 0.40)
        x = cx + math.cos(a) * 18
        y = cy + 6 + abs(math.sin(a)) * 14
        arc_pts_l.append((x, y))
    for t in np.linspace(0, 1, 24):
        a = math.pi * 0.05 + t * (math.pi * 0.40)
        x = cx + math.cos(a) * 18
        y = cy + 6 + abs(math.sin(a)) * 14
        arc_pts_r.append((x, y))
    _ink_stroke(d, _wobble(arc_pts_l, rng, amp=0.4), width=3, color=STONE_BLUE)
    _ink_stroke(d, _wobble(arc_pts_r, rng, amp=0.4), width=3, color=STONE_BLUE)

    chord = [(cx - 22, cy + 24), (cx + 22, cy - 28)]
    _ink_stroke(d, _wobble(chord, rng, amp=0.3), width=2, color=BRASS)
    for px, py in [(cx - 12, cy + 12), (cx + 6, cy - 8)]:
        d.ellipse((px - 2, py - 2, px + 2, py + 2), fill=BRASS_DARK)

    img = Image.alpha_composite(img, overlay)
    img = _bronze_ring(img)
    img = _grain_pass(img, rng)
    return img


# ---------- driver ---------------------------------------------------------

GLYPHS = {
    "the_sundering":   glyph_the_sundering,
    "oath_of_thorns":  glyph_oath_of_thorns,
    "wyrmsong_winds":  glyph_wyrmsong_winds,
    "sunken_chord":    glyph_sunken_chord,
}


def main() -> int:
    out_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("eldoria-godot/assets/icons/codex")
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, fn in GLYPHS.items():
        sub_rng = random.Random(SEED + sum(ord(c) for c in name))
        img = fn(sub_rng)
        path = out_dir / f"{name}.png"
        img.save(path, "PNG", optimize=True)
        print(f"wrote {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
