#!/usr/bin/env python3
"""
Realm of Eldoria — procedural dirt-path PBR texture generator.

Briarwood Village and the Whisperwood approach roads need a TILEABLE bare-
earth path texture set so the Builder agent can lay walking paths between
the village square, the smithy, the herbalist, and the meadow gate.

Existing PBR sets in `eldoria-godot/assets/textures/`:
  grass/, wood/, stone/, thatch/, bark/, rock/, snow/

Conspicuously missing: bare dirt / packed-earth path. Adds an 8th set:
  dirt/dirt_diff.jpg  — albedo (1024×1024, sRGB)
  dirt/dirt_norm.jpg  — tangent-space normal map (1024×1024)
  dirt/dirt_rough.jpg — grayscale roughness (1024×1024)

Style targets (THEME.md):
  §1 painterly hand-painted aesthetic — no photoreal grit, no DSLR pebbles.
  §3 palette — sepia parchment (#D9C99B) and ink (#0E0A0E) anchor;
      warm earth tones derived between burnt orange (#FF8000) and
      bronze (#B0742A); occasional moss flecks (#4A7038) lifting from cracks.
  §1 lived-in — packed dirt with hoof prints, twig flecks, occasional
      stone shards; tileable so a 2m × 2m path tile repeats without seams.

Pure Pillow + NumPy. CC0. No external assets. Tileable via wraparound noise.

Run:  python3 scripts/art/gen_dirt_path_texture.py <out_dir>
Out:  <out_dir>/dirt_diff.jpg, dirt_norm.jpg, dirt_rough.jpg
"""
from __future__ import annotations

import math
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

SIZE = 1024
SEED = 8131  # match repo convention

# THEME §3 palette anchors (RGB 0-255)
PARCHMENT  = np.array([217, 201, 155], dtype=np.float32)
INK        = np.array([ 14,  10,  14], dtype=np.float32)
BRONZE     = np.array([176, 116,  42], dtype=np.float32)
SUNSET     = np.array([180, 110,  50], dtype=np.float32)  # damped from #FF8000
EARTH_DARK = np.array([ 92,  64,  38], dtype=np.float32)
EARTH_MID  = np.array([138,  98,  58], dtype=np.float32)
EARTH_LT   = np.array([186, 148,  98], dtype=np.float32)
MOSS       = np.array([ 74, 112,  56], dtype=np.float32)


def _tile_noise(size: int, scale: float, rng: np.random.Generator) -> np.ndarray:
    """Tileable value-noise via FFT phase scrambling on a low-res grid."""
    g = max(2, int(size / scale))
    grid = rng.standard_normal((g, g)).astype(np.float32)
    # Bilinearly upsample by tiling, then a wraparound Gaussian blur.
    img = Image.fromarray((grid - grid.min()) /
                          max(1e-6, grid.max() - grid.min()) * 255).convert("L")
    img = img.resize((size, size), Image.BICUBIC)
    arr = np.array(img, dtype=np.float32) / 255.0
    # Wrap-blur: pad with edge wrap, blur, crop. Keeps tileability.
    pad = max(2, size // 64)
    padded = np.pad(arr, pad, mode="wrap")
    pimg = Image.fromarray((padded * 255).astype(np.uint8), "L")
    pimg = pimg.filter(ImageFilter.GaussianBlur(radius=size / (g * 4.0)))
    arr = (np.array(pimg, dtype=np.float32) / 255.0)[pad:-pad, pad:-pad]
    return arr


def _fbm(size: int, rng: np.random.Generator,
         octaves: int = 5, lacunarity: float = 2.0) -> np.ndarray:
    """Fractal Brownian Motion — sums of tile_noise across octaves."""
    out = np.zeros((size, size), dtype=np.float32)
    amp = 1.0
    scale = 256.0
    norm = 0.0
    for _ in range(octaves):
        out += amp * _tile_noise(size, scale, rng)
        norm += amp
        amp *= 0.5
        scale /= lacunarity
    out /= max(norm, 1e-6)
    # Re-normalize to [0,1]
    lo, hi = float(out.min()), float(out.max())
    return (out - lo) / max(1e-6, hi - lo)


def _hoof_prints(size: int, rng: np.random.Generator,
                 count: int = 14) -> np.ndarray:
    """Sparse oval depressions — half-moon hoof prints scattered & rotated."""
    mask = np.zeros((size, size), dtype=np.float32)
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    for _ in range(count):
        cx = float(rng.uniform(0, size))
        cy = float(rng.uniform(0, size))
        rx = float(rng.uniform(8, 16))
        ry = float(rng.uniform(14, 22))
        ang = float(rng.uniform(0, math.pi))
        ca, sa = math.cos(ang), math.sin(ang)
        # Tileable: replicate at 8 wrap offsets so prints near edges blend.
        for dx in (-size, 0, size):
            for dy in (-size, 0, size):
                u = (xx + dx - cx) * ca + (yy + dy - cy) * sa
                v = -(xx + dx - cx) * sa + (yy + dy - cy) * ca
                d = (u / rx) ** 2 + (v / ry) ** 2
                # Only the lower half (cleft of a hoof) — clamp v>0 contribution.
                d = np.where(v > 0, d * 1.6, d)
                mask = np.maximum(mask, np.exp(-d * 1.8))
    return np.clip(mask, 0.0, 1.0)


def _twig_flecks(size: int, rng: np.random.Generator,
                 count: int = 220) -> np.ndarray:
    """Tiny dark twig/leaf flecks — short oriented streaks."""
    mask = np.zeros((size, size), dtype=np.float32)
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    for _ in range(count):
        cx = float(rng.uniform(0, size))
        cy = float(rng.uniform(0, size))
        L = float(rng.uniform(4, 14))
        W = float(rng.uniform(0.8, 1.6))
        ang = float(rng.uniform(0, math.pi))
        ca, sa = math.cos(ang), math.sin(ang)
        for dx in (-size, 0, size):
            for dy in (-size, 0, size):
                u = (xx + dx - cx) * ca + (yy + dy - cy) * sa
                v = -(xx + dx - cx) * sa + (yy + dy - cy) * ca
                d = (u / L) ** 2 + (v / W) ** 2
                mask = np.maximum(mask, np.exp(-d * 2.4))
    return np.clip(mask, 0.0, 1.0)


def _stone_shards(size: int, rng: np.random.Generator,
                  count: int = 28) -> np.ndarray:
    """Pale-bronze pebble specks — tiny round highlights."""
    mask = np.zeros((size, size), dtype=np.float32)
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    for _ in range(count):
        cx = float(rng.uniform(0, size))
        cy = float(rng.uniform(0, size))
        r = float(rng.uniform(2.5, 6.0))
        for dx in (-size, 0, size):
            for dy in (-size, 0, size):
                d = ((xx + dx - cx) ** 2 + (yy + dy - cy) ** 2) / (r * r)
                mask = np.maximum(mask, np.exp(-d * 1.2))
    return np.clip(mask, 0.0, 1.0)


def render_diffuse(rng: np.random.Generator) -> Image.Image:
    """Albedo: warm packed earth, brushy mottle, lived-in flecks."""
    big = _fbm(SIZE, rng, octaves=6, lacunarity=2.1)
    micro = _fbm(SIZE, rng, octaves=3, lacunarity=2.4)
    base = (0.65 * big + 0.35 * micro)[..., None]

    # Three-stop gradient: dark damp → mid earth → light dusty.
    rgb = (1 - base) * (1 - base) * EARTH_DARK \
        + 2 * base * (1 - base) * EARTH_MID \
        + base * base * EARTH_LT

    # Painterly tint pull toward sunset/parchment in highlights.
    warm = np.clip((base - 0.55) * 2.0, 0, 1)
    rgb = rgb * (1 - 0.18 * warm) + (0.18 * warm) * (PARCHMENT * 0.9 + SUNSET * 0.1)

    # Hoof-print darkening (compressed soil = darker).
    hoof = _hoof_prints(SIZE, rng, count=14)[..., None]
    rgb = rgb * (1 - 0.42 * hoof) + (EARTH_DARK * 0.6) * (0.42 * hoof)

    # Twig flecks: bias toward INK with a hint of EARTH_DARK.
    twig = _twig_flecks(SIZE, rng, count=240)[..., None]
    rgb = rgb * (1 - 0.55 * twig) + (INK * 0.7 + EARTH_DARK * 0.3) * (0.55 * twig)

    # Stone shards: small bright bronze pebble specks.
    shard = _stone_shards(SIZE, rng, count=30)[..., None]
    rgb = rgb * (1 - 0.50 * shard) + (BRONZE * 0.85 + PARCHMENT * 0.15) * (0.50 * shard)

    # Rare moss tufts in the cracks (5% coverage).
    moss_mask = ((_fbm(SIZE, rng, octaves=4) > 0.78) *
                 (big < 0.45)).astype(np.float32)[..., None]
    rgb = rgb * (1 - 0.55 * moss_mask) + (MOSS * 0.95) * (0.55 * moss_mask)

    # Painterly grain pass.
    grain = rng.normal(0, 4.0, rgb.shape).astype(np.float32)
    rgb = np.clip(rgb + grain, 0, 255).astype(np.uint8)
    img = Image.fromarray(rgb, "RGB")
    img = img.filter(ImageFilter.GaussianBlur(radius=0.6))
    return img


def render_normal(diff_height: np.ndarray) -> Image.Image:
    """Tangent-space normal from a height map (Sobel-like)."""
    h = diff_height.astype(np.float32)
    # Wrap-aware central differences for tileability.
    dx = np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)
    dy = np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)
    strength = 6.0
    nx = -dx * strength
    ny = -dy * strength
    nz = np.ones_like(h) * 12.0
    L = np.sqrt(nx * nx + ny * ny + nz * nz) + 1e-6
    nx, ny, nz = nx / L, ny / L, nz / L
    rgb = np.stack([(nx * 0.5 + 0.5) * 255,
                    (ny * 0.5 + 0.5) * 255,
                    (nz * 0.5 + 0.5) * 255], axis=-1)
    return Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB")


def render_roughness(diff_height: np.ndarray, rng: np.random.Generator) -> Image.Image:
    """Roughness: dirt is mostly rough; pebble specks slightly glossier; hoof
    compaction more glossy too."""
    base = 0.78 + 0.10 * (diff_height - 0.5)  # mostly rough
    pebble = _stone_shards(SIZE, rng, count=30)
    hoof = _hoof_prints(SIZE, rng, count=14)
    base -= 0.20 * pebble  # pebbles smoother
    base -= 0.10 * hoof    # compacted hoof prints slightly smoother
    base += rng.normal(0, 0.012, base.shape)
    base = np.clip(base, 0.55, 0.97)
    img = (base * 255).astype(np.uint8)
    return Image.fromarray(img, "L").convert("RGB")


def main():
    out_dir = Path(sys.argv[1] if len(sys.argv) > 1
                   else "eldoria-godot/assets/textures/dirt")
    out_dir.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(SEED)

    diff_img = render_diffuse(rng)
    diff_path = out_dir / "dirt_diff.jpg"
    diff_img.save(diff_path, "JPEG", quality=88, optimize=True)
    print(f"  wrote {diff_path}  ({diff_path.stat().st_size} bytes)")

    # Build a height proxy from the diff (luminance).
    diff_arr = np.array(diff_img, dtype=np.float32) / 255.0
    height = 0.30 * diff_arr[..., 0] + 0.59 * diff_arr[..., 1] + 0.11 * diff_arr[..., 2]
    # Soft height blur so normals don't latch on grain noise.
    height_img = Image.fromarray((height * 255).astype(np.uint8), "L")
    height_img = height_img.filter(ImageFilter.GaussianBlur(radius=1.4))
    height = np.array(height_img, dtype=np.float32) / 255.0

    norm_img = render_normal(height)
    norm_path = out_dir / "dirt_norm.jpg"
    norm_img.save(norm_path, "JPEG", quality=92, optimize=True)
    print(f"  wrote {norm_path}  ({norm_path.stat().st_size} bytes)")

    rng2 = np.random.default_rng(SEED + 1)
    rough_img = render_roughness(height, rng2)
    rough_path = out_dir / "dirt_rough.jpg"
    rough_img.save(rough_path, "JPEG", quality=88, optimize=True)
    print(f"  wrote {rough_path}  ({rough_path.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
