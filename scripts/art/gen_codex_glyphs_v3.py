#!/usr/bin/env python3
"""
Realm of Eldoria — codex glyph icons (batch v3)

Six painterly 128x128 codex chapter glyphs filling the v1+v2 coverage gap.
Each glyph corresponds to an `icon_glyph:` value declared in a
`data/codex/*.md` front-matter that previously had no PNG on disk:

  candle-and-window              → longnight_vigil.md
  coiled-wyrm-and-stone          → pale_wyrm_beneath.md
  kindling-bundle-and-red-ribbon → brigids_ribbon.md
  lantern-and-pond-ripple        → pond_and_lanterns.md
  spine-of-stone-and-ring        → vellums_spine.md
  stag-and-bow-unstrung          → thiars_mercy_owed_to_prey.md

Same disc/ring/grain treatment as v1+v2 so they read as one set in the
codex panel. THEME.md §1 painterly hand-painted feel; §3 palette
(parchment, ink, brass, moss, wine, stone-blue, frost-silver, sunset-gold);
§5 hand-drawn banner/sign aesthetic.

Pure Pillow + NumPy. CC0. No external assets, fonts, or trademarks.

Run:  python3 scripts/art/gen_codex_glyphs_v3.py [out_dir]
"""
from __future__ import annotations

import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter
import numpy as np

SIZE = 128
SEED = 8131  # match repo convention (v1 + v2)

# THEME.md §3 palette
PARCHMENT      = (217, 201, 155, 255)
PARCHMENT_DARK = (181, 161, 116, 255)
INK            = (14, 10, 14, 255)
BRASS          = (176, 116, 42, 255)
BRASS_DARK     = (110, 72, 24, 255)
MOSS           = (74, 112, 56, 255)
WINE           = (140, 32, 32, 255)
STAG_BLOOD     = (160, 32, 32, 255)
STONE_BLUE     = (123, 134, 147, 255)
FROST_SLV      = (200, 224, 229, 255)
SUNSET_GLD     = (255, 216, 107, 255)
CANDLE_FLAME   = (255, 196, 96, 255)
WAX_WHITE      = (236, 226, 196, 255)
PALE_WYRM      = (212, 220, 226, 255)


# ---------- shared base treatments (matches v1 + v2 codex set) -------------

def _parchment_disc(rng):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = cy = SIZE / 2
    r = SIZE * 0.46
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=PARCHMENT)
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
    return img.filter(ImageFilter.GaussianBlur(radius=0.6))


def _bronze_ring(img):
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


def _grain_pass(img, rng):
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


def _ink_stroke(d, pts, width=3, color=INK):
    if len(pts) < 2:
        return
    for i in range(len(pts) - 1):
        d.line([pts[i], pts[i + 1]], fill=color, width=width)
    for x, y in pts:
        rr = max(1, width // 2)
        d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=color)


def _wobble(pts, rng, amp=0.7):
    return [(x + rng.uniform(-amp, amp), y + rng.uniform(-amp, amp)) for x, y in pts]


# ---------- glyph 1: candle-and-window -------------------------------------

def glyph_candle_and_window(rng):
    """A small mullioned window — candle behind it, soft pre-dawn light."""
    img = _parchment_disc(rng)
    cx = cy = SIZE / 2
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    fx0, fy0, fx1, fy1 = cx - 26, cy - 30, cx + 26, cy + 26
    d.rounded_rectangle((fx0, fy0, fx1, fy1), radius=4, fill=(38, 26, 22, 255), outline=BRASS_DARK, width=2)
    d.rounded_rectangle((fx0 + 4, fy0 + 4, fx1 - 4, fy1 - 4), radius=3, fill=(255, 196, 120, 255))
    _ink_stroke(d, _wobble([(cx, fy0 + 4), (cx, fy1 - 4)], rng, amp=0.3), width=3, color=BRASS_DARK)
    _ink_stroke(d, _wobble([(fx0 + 4, cy - 2), (fx1 - 4, cy - 2)], rng, amp=0.3), width=3, color=BRASS_DARK)

    cwx, cwy = cx + 6, cy + 14
    d.rectangle((cwx - 2, cwy - 10, cwx + 2, cwy + 8), fill=WAX_WHITE, outline=INK)
    _ink_stroke(d, [(cwx, cwy - 11), (cwx, cwy - 14)], width=1, color=INK)
    flame = [
        (cwx, cwy - 22), (cwx + 3, cwy - 16), (cwx + 1, cwy - 12),
        (cwx - 1, cwy - 12), (cwx - 3, cwy - 16), (cwx, cwy - 22),
    ]
    d.polygon(flame, fill=CANDLE_FLAME, outline=INK)

    halo = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    for k in range(6):
        rr = 6 + k * 2
        a = max(0, 60 - k * 10)
        hd.ellipse((cwx - rr, cwy - 18 - rr, cwx + rr, cwy - 18 + rr),
                   outline=(255, 220, 140, a), width=1)
    halo = halo.filter(ImageFilter.GaussianBlur(1.2))
    overlay = Image.alpha_composite(overlay, halo)

    sill = [(fx0 - 4, fy1 + 2), (fx1 + 4, fy1 + 2),
            (fx1 + 6, fy1 + 6), (fx0 - 6, fy1 + 6)]
    ImageDraw.Draw(overlay).polygon(sill, fill=BRASS_DARK, outline=INK)

    img = Image.alpha_composite(img, overlay)
    img = _bronze_ring(img)
    img = _grain_pass(img, rng)
    return img


# ---------- glyph 2: coiled-wyrm-and-stone ---------------------------------

def glyph_coiled_wyrm_and_stone(rng):
    """A pale wyrm coiled around a tall standing stone."""
    img = _parchment_disc(rng)
    cx = cy = SIZE / 2
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    stone_pts = [
        (cx - 9, cy - 30), (cx - 12, cy - 4), (cx - 11, cy + 26),
        (cx + 11, cy + 26), (cx + 13, cy - 2), (cx + 9, cy - 30),
        (cx + 2, cy - 34), (cx - 4, cy - 33),
    ]
    d.polygon(_wobble(stone_pts, rng, amp=0.6), fill=STONE_BLUE, outline=INK)
    _ink_stroke(d, _wobble([(cx - 4, cy - 22), (cx - 1, cy - 6), (cx + 3, cy + 12)],
                            rng, amp=0.5), width=1, color=INK)

    for i, y0 in enumerate([cy - 14, cy + 4, cy + 22]):
        amp = 4.0 - i * 0.2
        side = 1 if i % 2 == 0 else -1
        pts = []
        for x in np.linspace(cx - 22, cx + 22, 32):
            wave = math.sin((x - cx) * 0.18) * amp * side
            pts.append((float(x), float(y0 + wave)))
        _ink_stroke(d, _wobble(pts, rng, amp=0.4), width=4, color=PALE_WYRM)
        _ink_stroke(d, _wobble(pts, rng, amp=0.4), width=2, color=BRASS_DARK)

    hx, hy = cx - 24, cy - 14
    d.ellipse((hx - 5, hy - 4, hx + 3, hy + 4), fill=PALE_WYRM, outline=INK)
    d.ellipse((hx - 2, hy - 1, hx, hy + 1), fill=INK)

    tx, ty = cx + 24, cy + 22
    tail = [(tx, ty), (tx + 6, ty - 3), (tx + 9, ty), (tx + 6, ty + 2)]
    d.polygon(_wobble(tail, rng, amp=0.4), fill=PALE_WYRM, outline=INK)

    img = Image.alpha_composite(img, overlay)
    img = _bronze_ring(img)
    img = _grain_pass(img, rng)
    return img


# ---------- glyph 3: kindling-bundle-and-red-ribbon ------------------------

def glyph_kindling_bundle_and_red_ribbon(rng):
    """Bundle of pine kindling, wound twice with a red lambswool ribbon."""
    img = _parchment_disc(rng)
    cx = cy = SIZE / 2
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    sticks = [
        (cx - 22, cy - 20, cx + 24, cy - 16),
        (cx - 24, cy - 12, cx + 22, cy - 8),
        (cx - 23, cy - 4,  cx + 23, cy),
        (cx - 22, cy + 4,  cx + 24, cy + 8),
        (cx - 24, cy + 12, cx + 22, cy + 16),
        (cx - 23, cy + 20, cx + 23, cy + 24),
    ]
    for x0, y0, x1, y1 in sticks:
        _ink_stroke(d, _wobble([(x0, y0), (x1, y1)], rng, amp=0.4), width=5, color=BRASS_DARK)
        _ink_stroke(d, _wobble([(x0, y0), (x1, y1)], rng, amp=0.4), width=3, color=BRASS)
        d.ellipse((x0 - 2, y0 - 2, x0 + 2, y0 + 2), fill=INK)
        d.ellipse((x1 - 2, y1 - 2, x1 + 2, y1 + 2), fill=INK)

    rb_x0, rb_x1 = cx - 6, cx + 6
    d.rectangle((rb_x0, cy - 26, rb_x1, cy + 28), fill=WINE, outline=INK)
    d.line((cx, cy - 26, cx, cy + 28), fill=STAG_BLOOD, width=1)

    for sgn in (-1, 1):
        loop = [
            (cx, cy + 2),
            (cx + sgn * 8, cy - 4),
            (cx + sgn * 12, cy + 4),
            (cx + sgn * 6, cy + 10),
            (cx, cy + 6),
        ]
        d.polygon(_wobble(loop, rng, amp=0.4), fill=WINE, outline=INK)

    _ink_stroke(d, _wobble([(cx - 4, cy + 8), (cx - 14, cy + 22), (cx - 12, cy + 28)],
                            rng, amp=0.3), width=4, color=WINE)
    _ink_stroke(d, _wobble([(cx + 4, cy + 8), (cx + 16, cy + 20), (cx + 14, cy + 28)],
                            rng, amp=0.3), width=4, color=WINE)

    img = Image.alpha_composite(img, overlay)
    img = _bronze_ring(img)
    img = _grain_pass(img, rng)
    return img


# ---------- glyph 4: lantern-and-pond-ripple -------------------------------

def glyph_lantern_and_pond_ripple(rng):
    """A small paper lantern hanging above concentric pond ripples."""
    img = _parchment_disc(rng)
    cx = cy = SIZE / 2
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    lcx, lcy = cx, cy - 14
    d.rounded_rectangle((lcx - 12, lcy - 10, lcx + 12, lcy + 10), radius=4,
                        fill=SUNSET_GLD, outline=INK)
    d.polygon([(lcx - 14, lcy - 10), (lcx + 14, lcy - 10),
               (lcx + 10, lcy - 14), (lcx - 10, lcy - 14)],
              fill=BRASS_DARK, outline=INK)
    _ink_stroke(d, [(lcx, lcy + 10), (lcx, lcy + 16)], width=2, color=BRASS_DARK)
    d.ellipse((lcx - 2, lcy + 16, lcx + 2, lcy + 20), fill=WINE, outline=INK)
    _ink_stroke(d, [(lcx, lcy - 14), (lcx, cy - 38)], width=1, color=INK)

    halo = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    for k in range(5):
        rr = 14 + k * 3
        a = max(0, 70 - k * 14)
        hd.ellipse((lcx - rr, lcy - rr, lcx + rr, lcy + rr),
                   outline=(255, 220, 140, a), width=1)
    halo = halo.filter(ImageFilter.GaussianBlur(1.4))
    overlay = Image.alpha_composite(overlay, halo)

    py = cy + 18
    od = ImageDraw.Draw(overlay)
    for k, (rr, col) in enumerate([(8, FROST_SLV), (15, STONE_BLUE), (22, FROST_SLV)]):
        ribbon_pts = []
        for t in np.linspace(0, math.pi, 36):
            x = cx + math.cos(t) * rr
            y = py + math.sin(t) * (rr * 0.35)
            ribbon_pts.append((float(x), float(y)))
        _ink_stroke(od, _wobble(ribbon_pts, rng, amp=0.4), width=2, color=col)

    od.ellipse((cx - 3, py - 1, cx + 3, py + 3), fill=SUNSET_GLD, outline=INK)

    img = Image.alpha_composite(img, overlay)
    img = _bronze_ring(img)
    img = _grain_pass(img, rng)
    return img


# ---------- glyph 5: spine-of-stone-and-ring -------------------------------

def glyph_spine_of_stone_and_ring(rng):
    """A vertical stone book-spine with a brass ring at its top."""
    img = _parchment_disc(rng)
    cx = cy = SIZE / 2
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    sx0, sy0, sx1, sy1 = cx - 10, cy - 28, cx + 10, cy + 28
    d.rounded_rectangle((sx0, sy0, sx1, sy1), radius=3, fill=STONE_BLUE, outline=INK)

    for k, yy in enumerate(np.linspace(sy0 + 6, sy1 - 6, 5)):
        col = (FROST_SLV if k % 2 == 0 else PARCHMENT_DARK)
        _ink_stroke(d, _wobble([(sx0 + 1, yy), (sx1 - 1, yy)], rng, amp=0.3),
                    width=2, color=col)

    rcx, rcy = cx, sy0 - 6
    d.ellipse((rcx - 8, rcy - 8, rcx + 8, rcy + 8), outline=BRASS_DARK, width=3)
    d.ellipse((rcx - 6, rcy - 6, rcx + 6, rcy + 6), outline=BRASS, width=2)
    _ink_stroke(d, [(rcx, rcy + 6), (rcx, sy0)], width=3, color=BRASS_DARK)

    rune_cx, rune_cy = cx, cy
    d.ellipse((rune_cx - 3, rune_cy - 3, rune_cx + 3, rune_cy + 3), outline=INK, width=1)
    tri = [(rune_cx, rune_cy - 6), (rune_cx + 6, rune_cy + 4), (rune_cx - 6, rune_cy + 4)]
    _ink_stroke(d, _wobble(tri + [tri[0]], rng, amp=0.4), width=2, color=INK)

    for x_off in (-9, 9):
        d.polygon([(cx + x_off - 4, sy1 + 2), (cx + x_off + 4, sy1 + 2),
                   (cx + x_off + 2, sy1 - 1), (cx + x_off - 2, sy1 - 1)],
                  fill=MOSS, outline=INK)

    img = Image.alpha_composite(img, overlay)
    img = _bronze_ring(img)
    img = _grain_pass(img, rng)
    return img


# ---------- glyph 6: stag-and-bow-unstrung ---------------------------------

def glyph_stag_and_bow_unstrung(rng):
    """A leaping stag silhouette beside an unstrung longbow."""
    img = _parchment_disc(rng)
    cx = cy = SIZE / 2
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    body = [
        (cx - 22, cy + 6),  (cx - 16, cy - 4), (cx - 4,  cy - 6),
        (cx + 6,  cy - 8),  (cx + 12, cy - 14),(cx + 18, cy - 16),
        (cx + 22, cy - 12), (cx + 18, cy - 8), (cx + 12, cy - 4),
        (cx + 4,  cy + 8),  (cx - 6,  cy + 10),(cx - 14, cy + 14),
        (cx - 22, cy + 6),
    ]
    d.polygon(_wobble(body, rng, amp=0.4), fill=BRASS_DARK, outline=INK)

    head_x, head_y = cx + 18, cy - 16
    for sign in (1, -1):
        antler = [
            (head_x, head_y),
            (head_x + sign * 2, head_y - 6),
            (head_x + sign * 4, head_y - 10),
            (head_x + sign * 7, head_y - 16),
        ]
        _ink_stroke(d, _wobble(antler, rng, amp=0.3), width=2, color=INK)
        _ink_stroke(d, _wobble([(head_x + sign * 4, head_y - 10),
                                 (head_x + sign * 9, head_y - 12)],
                                rng, amp=0.3), width=2, color=INK)
        _ink_stroke(d, _wobble([(head_x + sign * 5, head_y - 13),
                                 (head_x + sign * 10, head_y - 18)],
                                rng, amp=0.3), width=2, color=INK)

    _ink_stroke(d, _wobble([(cx + 6, cy + 4), (cx + 6, cy + 16)], rng, amp=0.3),
                width=3, color=BRASS_DARK)
    _ink_stroke(d, _wobble([(cx - 14, cy + 12), (cx - 14, cy + 22)], rng, amp=0.3),
                width=3, color=BRASS_DARK)
    _ink_stroke(d, _wobble([(cx + 12, cy + 4), (cx + 12, cy + 18)], rng, amp=0.3),
                width=3, color=BRASS_DARK)
    _ink_stroke(d, _wobble([(cx - 8, cy + 14), (cx - 8, cy + 22)], rng, amp=0.3),
                width=3, color=BRASS_DARK)

    d.ellipse((cx + 17, cy - 13, cx + 19, cy - 11), fill=PARCHMENT)

    bow_pts = []
    for t in np.linspace(0, 1, 24):
        a = math.pi * 0.20 + t * (math.pi * 0.60)
        x = cx - 28 + math.cos(a) * 6
        y = cy - 18 + t * 36
        bow_pts.append((x, y))
    _ink_stroke(d, _wobble(bow_pts, rng, amp=0.4), width=3, color=MOSS)
    _ink_stroke(d, _wobble(bow_pts, rng, amp=0.4), width=1, color=INK)

    string_pts = [
        bow_pts[0],
        (bow_pts[0][0] + 4, bow_pts[0][1] + 10),
        (bow_pts[len(bow_pts) // 2][0] + 6, bow_pts[len(bow_pts) // 2][1] + 12),
        (bow_pts[-1][0] + 4, bow_pts[-1][1] - 10),
        bow_pts[-1],
    ]
    _ink_stroke(d, _wobble(string_pts, rng, amp=0.3), width=1, color=INK)

    img = Image.alpha_composite(img, overlay)
    img = _bronze_ring(img)
    img = _grain_pass(img, rng)
    return img


GLYPHS = {
    "candle-and-window":              glyph_candle_and_window,
    "coiled-wyrm-and-stone":          glyph_coiled_wyrm_and_stone,
    "kindling-bundle-and-red-ribbon": glyph_kindling_bundle_and_red_ribbon,
    "lantern-and-pond-ripple":        glyph_lantern_and_pond_ripple,
    "spine-of-stone-and-ring":        glyph_spine_of_stone_and_ring,
    "stag-and-bow-unstrung":          glyph_stag_and_bow_unstrung,
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
