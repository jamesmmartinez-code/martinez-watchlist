#!/usr/bin/env python3
"""
Realm of Eldoria — codex glyph icons
====================================

Two codex entries currently reference an `icon_glyph:` value in their YAML
frontmatter but no matching PNG exists yet:

  - eldoria-godot/data/codex/stag_courts_courtesy.md   icon_glyph: leaf-and-antler
  - eldoria-godot/data/codex/steppe_riders_refusal.md  icon_glyph: horseshoe-and-cairn

This script renders both glyphs as 128×128 RGBA PNGs with transparent
background, painterly hand-drawn feel (per THEME.md §1, §5), palette
locked to §3 (parchment, ink, bronze, moss for the Briarwood-side glyph;
stone-blue, ink, frost silver for the Steppe-rider glyph), and a soft
worn ring around the device so it reads as a heraldic patch in the codex
list panel.

Pure Pillow + NumPy. CC0. No external assets.

Output: eldoria-godot/assets/icons/codex/<icon_glyph>.png
Run:    python3 scripts/art/gen_codex_glyphs.py <out_dir>
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
SEED = 8131  # match repo convention from make_ui_frames.py

# THEME §3 palette
PARCHMENT  = (217, 201, 155, 255)
INK        = (14, 10, 14, 255)
BRONZE     = (176, 116, 42, 255)
MOSS       = (74, 112, 56, 255)
WINE       = (140, 32, 32, 255)
STONE_BLUE = (123, 134, 147, 255)
FROST_SILVER = (200, 224, 229, 255)
SUNSET_GOLD = (255, 216, 107, 255)


def painterly_grain(img: Image.Image, sigma: float = 0.7) -> Image.Image:
    """Soft Gaussian + low-amp brush noise on RGB only (preserves alpha)."""
    rgba = np.array(img.convert("RGBA")).astype(np.int16)
    rgb = rgba[..., :3]
    noise = np.random.normal(0, 4, rgb.shape).astype(np.int16)
    rgb = np.clip(rgb + noise, 0, 255).astype(np.uint8)
    rgba[..., :3] = rgb
    out = Image.fromarray(rgba.astype(np.uint8), "RGBA")
    return out.filter(ImageFilter.GaussianBlur(radius=sigma))


def worn_ring(d: ImageDraw.ImageDraw, color, cx=64, cy=64, r=58, width=3):
    """Hand-drawn-ish ring: a few small breaks in the stroke."""
    for a0 in range(0, 360, 24):
        a1 = a0 + 18  # leave 6° gap
        d.arc([cx - r, cy - r, cx + r, cy + r], a0, a1, fill=color, width=width)


def parchment_disc(cx=64, cy=64, r=54):
    """Tinted painterly disc as glyph backdrop (semi-transparent)."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Soft outer halo
    halo = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    hd.ellipse([cx - r - 8, cy - r - 8, cx + r + 8, cy + r + 8],
               fill=(217, 201, 155, 90))
    halo = halo.filter(ImageFilter.GaussianBlur(6))
    img.alpha_composite(halo)
    # Disc
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(217, 201, 155, 210))
    # Mottle
    arr = np.array(img)
    mask = arr[..., 3] > 0
    rng = np.random.default_rng(SEED)
    n = rng.normal(0, 12, arr[..., :3].shape).astype(np.int16)
    rgb = arr[..., :3].astype(np.int16) + n
    arr[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    arr[~mask, :3] = 0
    img = Image.fromarray(arr, "RGBA")
    return img


def draw_oak_leaf(d: ImageDraw.ImageDraw, cx, cy, color, scale=1.0, tilt_deg=-18):
    """Stylized oak leaf via lobed polygon, slightly tilted."""
    pts = []
    # 12 alternating outer/inner vertices around vertical axis
    for i, (r_mul, angle_off) in enumerate([
        (1.00, -90), (0.62, -64), (0.92, -38), (0.55, -16),
        (0.85, 6),   (0.50, 28),  (0.78, 50),  (0.40, 72),
        (0.55, 90),  (0.40, 108), (0.78, 130), (0.50, 152),
        (0.85, 174), (0.55, 196), (0.92, 218), (0.62, 244),
    ]):
        a = math.radians(angle_off + tilt_deg)
        rr = 28 * r_mul * scale
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d.polygon(pts, fill=color, outline=INK)
    # Stem
    a = math.radians(90 + tilt_deg)
    sx = cx + 30 * scale * math.cos(a)
    sy = cy + 30 * scale * math.sin(a)
    bx = cx + 42 * scale * math.cos(a)
    by = cy + 42 * scale * math.sin(a)
    d.line([(sx, sy), (bx, by)], fill=INK, width=2)
    # Veins (radial mid-rib)
    a2 = math.radians(-90 + tilt_deg)
    tx = cx + 26 * scale * math.cos(a2)
    ty = cy + 26 * scale * math.sin(a2)
    d.line([(cx, cy), (tx, ty)], fill=mix(color, INK, 0.5), width=2)


def draw_antler(d: ImageDraw.ImageDraw, cx, cy, color, side=1, scale=1.0):
    """Branched antler — main beam + 4 tines."""
    # main beam, curving outward then up
    for seg, (dx, dy, w) in enumerate([
        (8 * side, -6, 4), (16 * side, -16, 4), (22 * side, -28, 3),
        (24 * side, -42, 3),
    ]):
        x2, y2 = cx + dx * scale, cy + dy * scale
        d.line([(cx, cy), (x2, y2)], fill=color, width=w)
        cx, cy = x2, y2
    # tines branching off the last beam point
    for tdx, tdy in [(10 * side, -4), (4 * side, -10), (-4 * side, -8)]:
        d.line([(cx, cy), (cx + tdx * scale, cy + tdy * scale)],
               fill=color, width=3)


def draw_horseshoe(d: ImageDraw.ImageDraw, cx, cy, color, r=24, thickness=8):
    """Open-bottom horseshoe (U-shape with thickness)."""
    # outer arc
    d.arc([cx - r, cy - r, cx + r, cy + r], 200, 340, fill=color, width=thickness)
    # nail dots
    for ang in (210, 240, 300, 330):
        a = math.radians(ang)
        nx = cx + (r - thickness // 2) * math.cos(a)
        ny = cy + (r - thickness // 2) * math.sin(a)
        d.ellipse([nx - 2, ny - 2, nx + 2, ny + 2], fill=INK)
    # heel ends (small caps)
    for ang in (200, 340):
        a = math.radians(ang)
        ex = cx + r * math.cos(a)
        ey = cy + r * math.sin(a)
        d.ellipse([ex - 4, ey - 4, ex + 4, ey + 4], fill=color)


def draw_cairn(d: ImageDraw.ImageDraw, cx, cy, base_color, top_color):
    """Three-stone stacked cairn, smaller stones on top."""
    # base
    d.ellipse([cx - 22, cy - 4, cx + 22, cy + 14], fill=base_color, outline=INK)
    # mid
    d.ellipse([cx - 16, cy - 18, cx + 16, cy + 0], fill=mix(base_color, top_color, 0.3),
              outline=INK)
    # top
    d.ellipse([cx - 10, cy - 28, cx + 10, cy - 12], fill=top_color, outline=INK)


def mix(a, b, t):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(min(len(a), len(b))))


def render_leaf_and_antler() -> Image.Image:
    """Briarwood Stag-Court fragment glyph: oak leaf + stag antler."""
    img = parchment_disc()
    d = ImageDraw.Draw(img)
    # Worn ring
    worn_ring(d, BRONZE, r=56, width=3)
    # Oak leaf, lower-left
    draw_oak_leaf(d, cx=44, cy=78, color=MOSS, scale=1.0, tilt_deg=-22)
    # Antler, upper-right (from skull pivot at center-right)
    draw_antler(d, cx=80, cy=78, color=mix(BRONZE, INK, 0.3), side=1, scale=1.4)
    # tiny secondary antler going up from another root
    draw_antler(d, cx=80, cy=78, color=mix(BRONZE, INK, 0.45), side=1, scale=0.9)
    img = painterly_grain(img, sigma=0.6)
    return img


def render_horseshoe_and_cairn() -> Image.Image:
    """Steppe-Rider Refusal glyph: horseshoe over a 3-stone cairn."""
    img = parchment_disc()
    d = ImageDraw.Draw(img)
    worn_ring(d, STONE_BLUE, r=56, width=3)
    # Horseshoe arching over upper half
    draw_horseshoe(d, cx=64, cy=48, color=mix(STONE_BLUE, INK, 0.3), r=26, thickness=9)
    # Cairn beneath
    draw_cairn(d, cx=64, cy=92,
               base_color=mix(STONE_BLUE, INK, 0.4),
               top_color=FROST_SILVER)
    img = painterly_grain(img, sigma=0.6)
    return img


def main():
    out_dir = Path(sys.argv[1] if len(sys.argv) > 1
                   else "eldoria-godot/assets/icons/codex")
    out_dir.mkdir(parents=True, exist_ok=True)
    random.seed(SEED)
    np.random.seed(SEED)
    pieces = {
        "leaf-and-antler.png":     render_leaf_and_antler(),
        "horseshoe-and-cairn.png": render_horseshoe_and_cairn(),
    }
    for name, img in pieces.items():
        p = out_dir / name
        img.save(p, optimize=True)
        print(f"  wrote {p}  ({p.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
