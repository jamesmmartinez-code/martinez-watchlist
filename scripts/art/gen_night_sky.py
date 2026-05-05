#!/usr/bin/env python3
"""
Realm of Eldoria — procedural night sky equirectangular panorama generator.

Produces a painterly 2048×1024 (and 1024×512) JPG equirectangular night
sky for use as Godot WorldEnvironment.sky_material panorama, paired with
the existing eldoria_sunset_sky_*.jpg for day/night cycle support.

Style targets (THEME.md):
  - §1 painterly, hand-painted concept-art aesthetic; cool tones reserved
    for night, mist, magic — this sky leans cool indigo/violet at zenith
    and softer purple-rose at the horizon, never neon, never bright pure
    white.
  - §3 palette — warlock purple (#7C3FB0) and fey cyan (#65DFE5) and
    frost-pale silver (#C8E0E5) used sparingly as accents, against a
    dominant ink-charcoal black (#0E0A0E) base.
  - §6 mood — quiet, mysterious, "old promises and half-remembered
    legends" (the kids playing at dusk look up and see this).
  - §11 reference — Studio Ghibli night skies (Princess Mononoke forest
    glades, Spirited Away train ride). Painterly, never photoreal.

Output: 2 JPG panoramas (1024×512 + 2048×1024), equirectangular,
        opaque (sky has no alpha).

License: CC0 — generated procedurally with Pillow + NumPy, no external
assets. Safe to ship under the same license as the existing PolyHaven
sunset skies in this folder.

Run: python3 gen_night_sky.py <out_dir>
"""
from __future__ import annotations
import math, os, sys
import numpy as np
from PIL import Image, ImageFilter

# THEME §3 palette anchors. All values RGB 0-255.
INK = np.array([14, 10, 14], dtype=np.float32)             # charcoal/ink black
WARLOCK = np.array([62, 32, 88], dtype=np.float32)         # warlock purple deep
WARLOCK_LT = np.array([124, 63, 176], dtype=np.float32)    # warlock purple
FEY_CYAN = np.array([101, 223, 229], dtype=np.float32)     # fey cyan
SILVER = np.array([200, 224, 229], dtype=np.float32)       # frost-pale silver
ROSE_DUSK = np.array([90, 48, 76], dtype=np.float32)       # warm horizon undertone
SUNSET_EMBER = np.array([130, 60, 50], dtype=np.float32)   # last warmth on horizon


def _gradient_band(width: int, height: int) -> np.ndarray:
    """Vertical zenith→horizon gradient in equirectangular space."""
    t = np.linspace(0.0, 1.0, height, dtype=np.float32)
    out = np.zeros((height, 1, 3), dtype=np.float32)
    for i, ti in enumerate(t):
        if ti < 0.45:
            a = ti / 0.45
            c = INK * (1 - a) + WARLOCK * a
        elif ti < 0.65:
            a = (ti - 0.45) / 0.20
            c = WARLOCK * (1 - a) + WARLOCK_LT * a
        elif ti < 0.92:
            a = (ti - 0.65) / 0.27
            c = WARLOCK_LT * (1 - a) + ROSE_DUSK * a
        else:
            a = (ti - 0.92) / 0.08
            c = ROSE_DUSK * (1 - a) + SUNSET_EMBER * 0.65 * a + ROSE_DUSK * 0.35 * a
        out[i, 0] = c
    return np.broadcast_to(out, (height, width, 3)).copy()


def _box_blur_2d(arr: np.ndarray, k: int) -> np.ndarray:
    if k <= 0:
        return arr
    out = arr.astype(np.float32).copy()
    pad = np.pad(out, ((0, 0), (k, k)), mode="wrap")
    cs = np.cumsum(pad, axis=1)
    out = (cs[:, 2*k:] - cs[:, :-2*k]) / (2 * k)
    pad = np.pad(out, ((k, k), (0, 0)), mode="edge")
    cs = np.cumsum(pad, axis=0)
    out = (cs[2*k:, :] - cs[:-2*k, :]) / (2 * k)
    return out


def _add_milky_way(base: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    """Soft diagonal Milky Way band — subtle bluish-silver dust, low alpha."""
    h, w, _ = base.shape
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    line_y = 0.20 * h + (xx / w) * 0.18 * h
    dist = np.abs(yy - line_y)
    band_width = 0.085 * h
    intensity = np.exp(-(dist / band_width) ** 2).astype(np.float32)
    noise = 0.55 + 0.45 * rng.random((h, w)).astype(np.float32)
    noise = _box_blur_2d(noise, 24)
    intensity *= noise
    dust = (FEY_CYAN * 0.35 + SILVER * 0.65)
    mix = intensity[..., None] * 0.32
    return base * (1.0 - mix) + dust * mix


def _add_stars(base: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    """Scattered painterly stars — denser at zenith, sparser at horizon."""
    h, w, _ = base.shape
    yy_norm = np.arange(h, dtype=np.float32) / h
    density = (1.0 - yy_norm) ** 2.0
    density = 0.05 + 0.95 * density
    star_target = int(0.00045 * h * w)
    star_rows = rng.choice(h, size=star_target, p=density / density.sum())
    star_cols = rng.integers(0, w, size=star_target)
    keep = star_target
    tier = rng.random(keep)
    radius = np.where(tier > 0.985, 4, np.where(tier > 0.92, 2, 1)).astype(np.int32)
    col_choice = rng.random(keep)
    colors = np.zeros((keep, 3), dtype=np.float32)
    for i in range(keep):
        c = col_choice[i]
        jitter = 0.85 + 0.15 * rng.random()
        if c < 0.70:
            colors[i] = SILVER * jitter
        elif c < 0.92:
            colors[i] = FEY_CYAN * jitter
        else:
            colors[i] = np.array([255, 200, 110], dtype=np.float32) * jitter
    out = base.copy()
    for i in range(keep):
        r = int(radius[i])
        y, x = int(star_rows[i]), int(star_cols[i])
        col = colors[i]
        for dy in range(-r - 1, r + 2):
            for dx in range(-r - 1, r + 2):
                yy2 = y + dy
                xx2 = (x + dx) % w
                if yy2 < 0 or yy2 >= h:
                    continue
                d = math.hypot(dy, dx)
                if d > r + 1.5:
                    continue
                falloff = max(0.0, 1.0 - d / (r + 1.5))
                falloff *= falloff
                out[yy2, xx2] = out[yy2, xx2] * (1 - falloff * 0.85) + col * falloff * 0.85
    return out


def _add_moon(base: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    """Single soft moon — silver disk + halo, painterly crater shading."""
    h, w, _ = base.shape
    mx = int(0.27 * w)
    my = int(0.28 * h)
    moon_radius = int(0.045 * h)
    out = base.copy()
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    dx = np.minimum(np.abs(xx - mx), w - np.abs(xx - mx))
    dy = yy - my
    for halo_r, halo_strength in [(moon_radius * 6, 0.06),
                                   (moon_radius * 3, 0.10),
                                   (moon_radius * 1.6, 0.18)]:
        d = np.sqrt(dx * dx + dy * dy)
        mask = np.exp(-(d / halo_r) ** 2)
        halo_color = SILVER * 0.92 + FEY_CYAN * 0.08
        out = out * (1 - mask[..., None] * halo_strength) + halo_color * mask[..., None] * halo_strength
    d = np.sqrt(dx * dx + dy * dy)
    disk_mask = (d <= moon_radius).astype(np.float32)
    soft_edge = np.clip(1.0 - (d - moon_radius + 1.5) / 2.5, 0.0, 1.0)
    disk_mask = np.maximum(disk_mask, soft_edge * 0.7)
    moon_color = SILVER * 0.94
    out = out * (1 - disk_mask[..., None]) + moon_color * disk_mask[..., None]
    for cdx, cdy, cr, dim in [(0.45, 0.32, 0.28, 0.10),
                               (-0.18, -0.40, 0.16, 0.07),
                               (0.30, -0.18, 0.10, 0.06)]:
        ccx = mx + int(cdx * moon_radius)
        ccy = my + int(cdy * moon_radius)
        ccr = max(2, int(cr * moon_radius))
        dx2 = np.minimum(np.abs(xx - ccx), w - np.abs(xx - ccx))
        dy2 = yy - ccy
        d2 = np.sqrt(dx2 * dx2 + dy2 * dy2)
        cmask = np.exp(-(d2 / ccr) ** 2) * disk_mask
        shadow = SILVER * 0.78 + WARLOCK * 0.22
        out = out * (1 - cmask[..., None] * dim) + shadow * cmask[..., None] * dim
    return out


def _painterly_pass(arr: np.ndarray) -> np.ndarray:
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), mode="RGB")
    img = img.filter(ImageFilter.GaussianBlur(radius=0.6))
    rng = np.random.default_rng(2026)
    a = np.array(img, dtype=np.float32)
    grain = (rng.random(a.shape).astype(np.float32) - 0.5) * 5.0
    a = a + grain
    return np.clip(a, 0, 255)


def render(width: int, height: int, seed: int = 1306) -> Image.Image:
    rng = np.random.default_rng(seed)
    base = _gradient_band(width, height)
    base = _add_milky_way(base, rng)
    base = _add_stars(base, rng)
    base = _add_moon(base, rng)
    base = _painterly_pass(base)
    return Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), mode="RGB")


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out_dir, exist_ok=True)
    img2k = render(2048, 1024, seed=1306)
    p2 = os.path.join(out_dir, "eldoria_night_sky_2k.jpg")
    img2k.save(p2, format="JPEG", quality=88, optimize=True)
    print(f"wrote {p2} ({os.path.getsize(p2)} bytes)")
    img1k = img2k.resize((1024, 512), Image.LANCZOS)
    p1 = os.path.join(out_dir, "eldoria_night_sky_1k.jpg")
    img1k.save(p1, format="JPEG", quality=86, optimize=True)
    print(f"wrote {p1} ({os.path.getsize(p1)} bytes)")


if __name__ == "__main__":
    main()
