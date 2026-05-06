#!/usr/bin/env python3
"""
Realm of Eldoria — procedural dawn sky equirectangular panorama generator.

Produces a painterly 2048x1024 (and 1024x512) JPG equirectangular dawn
sky for use as Godot WorldEnvironment.sky_material panorama, completing
the day cycle alongside the existing
  - eldoria_sunset_sky_*.jpg  (PolyHaven, evening)
  - eldoria_night_sky_*.jpg   (procedural, deep night)

Dawn sits between night and morning: the warlock-purple zenith of night
has cooled to a muted indigo, the eastern horizon flushes with sunrise
rose/peach, and a small painterly sun crests just above the haze. A
handful of last-gasp stars still hang near zenith - they fade out by
mid-morning in the engine's day cycle but are part of the painterly
mood at the dawn waypoint itself.

Style targets (THEME.md):
  - Sec 1 painterly, hand-painted concept-art aesthetic - Studio Ghibli /
    Howe / Lee dawn skies. Soft brush feel; no neon, no photoreal HDR
    bloom, no chrome. Sunrise warmth without becoming saccharine.
  - Sec 3 palette - sunset gold (#FFD86B) + burnt orange (#FF8000) at the
    horizon flush, parchment/sepia (#D9C99B) as the cloud highlight,
    stone-blue (#7B8693) and warlock-purple (#7C3FB0) at zenith. Wine
    (#8C2020) feathered under the sun disk for the warmest core. No
    pure white, no fluorescent pinks.
  - Sec 6 mood - quiet, hopeful, "the world is wounded but worth saving".
    The Briarwood NPC schedules light up at dawn (Maeve sweeps, Lyra
    forages at the treeline); this sky is what's overhead when they
    start their day.
  - Sec 11 reference - Hobbit illustrations (Alan Lee dawn over Rivendell),
    Princess Mononoke morning forest scenes. Painterly, never photoreal.

Output: 2 JPG panoramas (1024x512 + 2048x1024), equirectangular, opaque.
        Sun is offset to azimuth ~26% across the panorama (eastern
        quadrant) at ~78% down (just above horizon line) so the engine
        can rotate the skybox to put the sun anywhere the directional
        light is pointing.

License: CC0 - generated procedurally with Pillow + NumPy, no external
assets. Safe to ship under the same license as the existing PolyHaven
sunset skies in this folder.

Run: python3 gen_dawn_sky.py <out_dir>
"""
from __future__ import annotations
import math, os, sys
import numpy as np
from PIL import Image, ImageFilter

# THEME Sec 3 palette anchors. All values RGB 0-255.
INK          = np.array([14, 10, 14],     dtype=np.float32)   # charcoal/ink black
WARLOCK      = np.array([62, 32, 88],     dtype=np.float32)   # warlock purple deep
WARLOCK_LT   = np.array([124, 63, 176],   dtype=np.float32)   # warlock purple
STONE_BLUE   = np.array([123, 134, 147],  dtype=np.float32)   # stone grey-blue
DAWN_INDIGO  = np.array([66, 70, 110],    dtype=np.float32)   # cooled night, pre-rose
DAWN_LAVEND  = np.array([130, 116, 158],  dtype=np.float32)   # mid-sky lavender
DAWN_ROSE    = np.array([214, 138, 132],  dtype=np.float32)   # eastern rose flush
DAWN_PEACH   = np.array([240, 178, 128],  dtype=np.float32)   # warm peach band
SUNSET_GOLD  = np.array([255, 216, 107],  dtype=np.float32)   # sunset gold (THEME)
BURNT_ORANGE = np.array([255, 128, 0],    dtype=np.float32)   # sunset orange (THEME)
WINE         = np.array([140, 32, 32],    dtype=np.float32)   # deep crimson wine (THEME)
PARCHMENT    = np.array([217, 201, 155],  dtype=np.float32)   # parchment cloud highlight
SILVER       = np.array([200, 224, 229],  dtype=np.float32)   # frost-pale silver (last stars)
FEY_CYAN     = np.array([101, 223, 229],  dtype=np.float32)   # fey cyan (rare star tint)


def _gradient_band(width: int, height: int) -> np.ndarray:
    """Vertical zenith->horizon gradient in equirectangular space.
    Top of frame = zenith (cooled night indigo), bottom = horizon flush.
    """
    t = np.linspace(0.0, 1.0, height, dtype=np.float32)
    out = np.zeros((height, 1, 3), dtype=np.float32)
    for i, ti in enumerate(t):
        if ti < 0.18:
            a = ti / 0.18
            c = WARLOCK * 0.55 + DAWN_INDIGO * 0.45
            c = c * (1 - a) + DAWN_INDIGO * a
        elif ti < 0.42:
            a = (ti - 0.18) / 0.24
            c = DAWN_INDIGO * (1 - a) + DAWN_LAVEND * a
        elif ti < 0.60:
            a = (ti - 0.42) / 0.18
            c = DAWN_LAVEND * (1 - a) + DAWN_ROSE * a
        elif ti < 0.78:
            a = (ti - 0.60) / 0.18
            c = DAWN_ROSE * (1 - a) + DAWN_PEACH * a
        elif ti < 0.92:
            a = (ti - 0.78) / 0.14
            c = DAWN_PEACH * (1 - a) + SUNSET_GOLD * 0.85 * a + DAWN_PEACH * 0.15 * a
        else:
            a = (ti - 0.92) / 0.08
            warm = SUNSET_GOLD * 0.85 + BURNT_ORANGE * 0.15
            floor = SUNSET_GOLD * 0.55 + WINE * 0.18 + PARCHMENT * 0.27
            c = warm * (1 - a) + floor * a
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


def _add_horizon_glow(base: np.ndarray, rng: np.random.Generator,
                      sun_x_frac: float) -> np.ndarray:
    """Eastern bloom around the (rising) sun position - a wider, gentler
    horizontal gold halo so the painted gradient feels like it has a
    light source rather than being a flat horizontal band."""
    h, w, _ = base.shape
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    sx = sun_x_frac * w
    sy = 0.78 * h
    dx = np.minimum(np.abs(xx - sx), w - np.abs(xx - sx))
    dy = (yy - sy)
    radial = (dx / (0.30 * w)) ** 2 + (dy / (0.18 * h)) ** 2
    bloom = np.exp(-radial).astype(np.float32)
    upper_mask = np.clip((yy - 0.40 * h) / (0.20 * h), 0.0, 1.0)
    bloom *= upper_mask
    glow_color = SUNSET_GOLD * 0.65 + BURNT_ORANGE * 0.20 + DAWN_PEACH * 0.15
    mix = bloom[..., None] * 0.32
    return base * (1.0 - mix) + glow_color * mix


def _add_clouds(base: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    """Painterly streak clouds - wispy horizontal bands lit from below
    by the sunrise. Wraps cleanly at the panorama seam."""
    h, w, _ = base.shape
    sw, sh = w // 8, h // 8
    base_noise = rng.random((sh, sw)).astype(np.float32)
    stretched = _box_blur_2d(base_noise, 4)
    stretched = np.maximum(stretched - 0.46, 0.0)
    field = Image.fromarray((stretched * 255).clip(0, 255).astype(np.uint8))
    field = field.resize((w, h), Image.BILINEAR)
    cloud_alpha = (np.array(field, dtype=np.float32) / 255.0)
    cloud_alpha = _box_blur_2d(cloud_alpha, 8)
    yy = np.arange(h, dtype=np.float32) / h
    band = np.exp(-((yy - 0.62) / 0.18) ** 2)
    cloud_alpha *= band[:, None]
    yy_full = np.broadcast_to(yy[:, None], (h, w)).astype(np.float32)
    underlit = np.clip((yy_full - 0.55) / 0.20, 0.0, 1.0)
    cool = DAWN_LAVEND * 0.55 + STONE_BLUE * 0.45
    warm = PARCHMENT * 0.55 + DAWN_PEACH * 0.45
    cloud_color = cool[None, None, :] * (1.0 - underlit[..., None]) \
                + warm[None, None, :] * underlit[..., None]
    mix = cloud_alpha[..., None] * 0.55
    return base * (1.0 - mix) + cloud_color * mix


def _add_fading_stars(base: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    """A handful of pale stars near zenith - sparser than night, dimmer."""
    h, w, _ = base.shape
    yy_norm = np.arange(h, dtype=np.float32) / h
    density = np.clip(0.25 - yy_norm, 0.0, 0.25) ** 1.5
    if density.sum() <= 0.0:
        return base
    star_target = max(1, int(0.00012 * h * w))
    star_rows = rng.choice(h, size=star_target, p=density / density.sum())
    star_cols = rng.integers(0, w, size=star_target)
    out = base.copy()
    tier = rng.random(star_target)
    for i in range(star_target):
        r = 1
        c = rng.random()
        if c < 0.55:
            col = SILVER * (0.78 + 0.18 * rng.random())
        elif c < 0.85:
            col = (SILVER * 0.55 + DAWN_LAVEND * 0.45) * (0.80 + 0.15 * rng.random())
        else:
            col = FEY_CYAN * (0.65 + 0.15 * rng.random())
        y, x = int(star_rows[i]), int(star_cols[i])
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
                falloff *= falloff * 0.55
                out[yy2, xx2] = out[yy2, xx2] * (1 - falloff) + col * falloff
    return out


def _add_sun(base: np.ndarray, rng: np.random.Generator,
             sun_x_frac: float) -> np.ndarray:
    """Soft painterly sun cresting the horizon - small disc, layered halo,
    warm wine undertone in the immediate horizon below it."""
    h, w, _ = base.shape
    sx = int(sun_x_frac * w)
    sy = int(0.78 * h)
    sun_radius = int(0.030 * h)
    out = base.copy()
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    dx = np.minimum(np.abs(xx - sx), w - np.abs(xx - sx))
    dy = yy - sy

    for halo_r, halo_strength, tint in [
        (sun_radius * 9,   0.10, SUNSET_GOLD * 0.55 + DAWN_PEACH * 0.45),
        (sun_radius * 4.5, 0.16, SUNSET_GOLD * 0.75 + BURNT_ORANGE * 0.25),
        (sun_radius * 2.0, 0.22, SUNSET_GOLD),
    ]:
        d = np.sqrt(dx * dx + dy * dy)
        mask = np.exp(-(d / halo_r) ** 2)
        out = out * (1 - mask[..., None] * halo_strength) \
              + tint * mask[..., None] * halo_strength

    d = np.sqrt(dx * dx + dy * dy)
    disk_mask = (d <= sun_radius).astype(np.float32)
    soft_edge = np.clip(1.0 - (d - sun_radius + 1.5) / 2.5, 0.0, 1.0)
    disk_mask = np.maximum(disk_mask, soft_edge * 0.7)
    sun_color = SUNSET_GOLD * 0.92 + PARCHMENT * 0.08
    out = out * (1 - disk_mask[..., None]) + sun_color * disk_mask[..., None]

    band_y = np.exp(-((yy - 0.92 * h) / (0.05 * h)) ** 2)
    band_x = np.exp(-(dx / (0.15 * w)) ** 2)
    smudge = (band_y * band_x).astype(np.float32)
    smudge_color = WINE * 0.70 + BURNT_ORANGE * 0.30
    mix = smudge[..., None] * 0.18
    out = out * (1 - mix) + smudge_color * mix

    return out


def _painterly_pass(arr: np.ndarray) -> np.ndarray:
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), mode="RGB")
    img = img.filter(ImageFilter.GaussianBlur(radius=0.7))
    rng = np.random.default_rng(2026)
    a = np.array(img, dtype=np.float32)
    grain = (rng.random(a.shape).astype(np.float32) - 0.5) * 5.5
    a = a + grain
    return np.clip(a, 0, 255)


def render(width: int, height: int, seed: int = 1409,
           sun_x_frac: float = 0.26) -> Image.Image:
    """Render an equirectangular dawn-sky panorama.

    Args:
        seed: deterministic dawn-waypoint seed (matches gen_night_sky's
              `1306` and gen_sigils' integer-pinning convention).
        sun_x_frac: horizontal fraction (0..1) where the rising sun sits;
              the engine rotates the skybox at runtime so the actual
              direction comes from the directional-light angle.
    """
    rng = np.random.default_rng(seed)
    base = _gradient_band(width, height)
    base = _add_horizon_glow(base, rng, sun_x_frac)
    base = _add_clouds(base, rng)
    base = _add_fading_stars(base, rng)
    base = _add_sun(base, rng, sun_x_frac)
    base = _painterly_pass(base)
    return Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), mode="RGB")


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out_dir, exist_ok=True)
    img2k = render(2048, 1024, seed=1409)
    p2 = os.path.join(out_dir, "eldoria_dawn_sky_2k.jpg")
    img2k.save(p2, format="JPEG", quality=88, optimize=True)
    print(f"wrote {p2} ({os.path.getsize(p2)} bytes)")
    img1k = img2k.resize((1024, 512), Image.LANCZOS)
    p1 = os.path.join(out_dir, "eldoria_dawn_sky_1k.jpg")
    img1k.save(p1, format="JPEG", quality=86, optimize=True)
    print(f"wrote {p1} ({os.path.getsize(p1)} bytes)")


if __name__ == "__main__":
    main()
