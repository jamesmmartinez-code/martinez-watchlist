"""
Eldoria UI parchment-frame generator.

Procedurally generates a coherent set of hand-painted-feel UI panels
in strict THEME.md palette compliance. No AI generation — everything is
deterministic-but-noisy from a numpy PRNG, so the visual style is
reproducible and licence-clean (every byte authored by this script).

Outputs to <repo>/eldoria-godot/assets/ui/:
    parchment_panel.png        512x512  9-slice main panel (64px border)
    parchment_panel_small.png  256x256  tooltip / inventory slot
    wood_panel.png             512x384  wood-and-iron-stud panel
    scroll_banner.png          512x128  narrow quest-title banner
    button_normal.png          192x64   wood button base
    button_hover.png           192x64   wood button bright
    button_pressed.png         192x64   wood button darkened
    divider_ornate.png         384x24   horizontal divider with knot
    ATTRIBUTION.md             credit + reproduction info
"""
from __future__ import annotations
import math
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# ── THEME §3 palette ────────────────────────────────────────────────────────
PARCHMENT     = (217, 201, 155)   # #D9C99B
PARCHMENT_DK  = (170, 150, 105)   # darker variant for vignette
INK           = (14, 10, 14)      # #0E0A0E
BRASS         = (176, 116, 42)    # #B0742A
BRASS_DK      = (120,  78, 28)    # darker brass for shadows
WOOD_LIGHT    = (124,  84,  46)
WOOD_MID      = ( 88,  56,  30)
WOOD_DARK     = ( 56,  34,  18)
MOSS          = ( 74, 112,  56)   # #4A7038
WINE          = (140,  32,  32)   # #8C2020
SUNSET        = (255, 128,   0)   # #FF8000

RNG_SEED = 8131  # any fixed seed; pick one that looks pleasing
rng = np.random.default_rng(RNG_SEED)


# ── noise helpers ──────────────────────────────────────────────────────────
def value_noise(h: int, w: int, scale: int) -> np.ndarray:
    """Cheap value noise via random grid + bilinear upsample."""
    gh = max(2, h // scale + 2)
    gw = max(2, w // scale + 2)
    grid = rng.random((gh, gw), dtype=np.float32)
    img = Image.fromarray((grid * 255).astype(np.uint8), mode="L")
    img = img.resize((w, h), Image.BILINEAR)
    return np.asarray(img, dtype=np.float32) / 255.0


def fbm(h: int, w: int, octaves: int = 4, base_scale: int = 32) -> np.ndarray:
    """Fractal Brownian Motion — sums noise at decreasing scales."""
    out = np.zeros((h, w), dtype=np.float32)
    amp = 1.0
    total = 0.0
    s = base_scale
    for _ in range(octaves):
        out += amp * value_noise(h, w, s)
        total += amp
        amp *= 0.5
        s = max(2, s // 2)
    out /= total
    return out


def vignette(h: int, w: int, strength: float = 0.55, falloff: float = 1.4) -> np.ndarray:
    """Radial vignette mask: 1.0 at center, ~0 at corners."""
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    cx, cy = (w - 1) / 2.0, (h - 1) / 2.0
    dx = (xx - cx) / cx
    dy = (yy - cy) / cy
    r = np.sqrt(dx * dx + dy * dy)
    mask = 1.0 - np.clip(r, 0.0, 1.0) ** falloff
    return 1.0 - strength * (1.0 - mask)


def lerp_color(a, b, t: np.ndarray) -> np.ndarray:
    """Per-pixel lerp between two RGB tuples by t array (h,w)."""
    a = np.array(a, dtype=np.float32)
    b = np.array(b, dtype=np.float32)
    t3 = t[..., None]
    return (a * (1 - t3) + b * t3).astype(np.uint8)


# ── parchment base ─────────────────────────────────────────────────────────
def make_parchment(w: int, h: int) -> Image.Image:
    """Hand-painted parchment surface with grain, stains, and aged edges."""
    grain = fbm(h, w, octaves=5, base_scale=64)
    fine  = fbm(h, w, octaves=3, base_scale=8)
    blend = np.clip(0.65 * grain + 0.35 * fine, 0.0, 1.0)
    base  = lerp_color(PARCHMENT_DK, PARCHMENT, blend)

    # warm sunset wash on a few patches to feel sun-aged
    stains = fbm(h, w, octaves=3, base_scale=80)
    stain_mask = np.clip((stains - 0.55) * 3.0, 0.0, 0.35)
    base = lerp_color(tuple(base.reshape(-1, 3)[0]),
                      (210, 160,  90),
                      stain_mask).reshape(h, w, 3)
    # actually apply per-pixel
    target = np.array((210, 160,  90), dtype=np.float32)
    src = base.astype(np.float32)
    base = (src * (1 - stain_mask[..., None]) +
            target * stain_mask[..., None]).astype(np.uint8)

    # vignette darkening at edges
    v = vignette(h, w, strength=0.45, falloff=1.6)
    base = (base.astype(np.float32) * v[..., None]).clip(0, 255).astype(np.uint8)

    img = Image.fromarray(base, mode="RGB").convert("RGBA")

    # add a faint tea-stain ring for character (not on every panel — only big)
    if min(w, h) >= 384:
        ring = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        rd = ImageDraw.Draw(ring)
        cx = int(rng.integers(int(w * 0.25), int(w * 0.75)))
        cy = int(rng.integers(int(h * 0.25), int(h * 0.75)))
        r  = int(min(w, h) * 0.18)
        rd.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(120, 80, 30, 60), width=3)
        ring = ring.filter(ImageFilter.GaussianBlur(radius=4))
        img = Image.alpha_composite(img, ring)

    return img


# ── ink border + corner motifs ─────────────────────────────────────────────
def add_ink_border(img: Image.Image, inset: int = 12, line_w: int = 3,
                   corner_radius: int = 14) -> Image.Image:
    """Painted ink border, slightly irregular — never crisp vector."""
    w, h = img.size
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    # outer painted border (slight wobble per segment)
    box = (inset, inset, w - inset - 1, h - inset - 1)
    d.rounded_rectangle(box, radius=corner_radius, outline=INK + (220,), width=line_w)

    # inner thinner accent line for layered painted-edge feel
    inner = (inset + 6, inset + 6, w - inset - 7, h - inset - 7)
    d.rounded_rectangle(inner, radius=max(4, corner_radius - 6),
                        outline=INK + (110,), width=1)

    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=0.6))
    return Image.alpha_composite(img, overlay)


def draw_corner_studs(img: Image.Image, inset: int = 18, r: int = 6,
                      color: tuple = BRASS) -> Image.Image:
    """Bronze studs at 4 corners — lived-in metalwork accent."""
    w, h = img.size
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    pts = [(inset, inset),
           (w - inset, inset),
           (inset, h - inset),
           (w - inset, h - inset)]
    for (x, y) in pts:
        # shadow
        d.ellipse((x - r + 1, y - r + 2, x + r + 1, y + r + 2),
                  fill=(0, 0, 0, 130))
        # base
        d.ellipse((x - r, y - r, x + r, y + r), fill=color + (255,))
        # highlight
        d.ellipse((x - r + 1, y - r + 1, x - 1, y - 1),
                  fill=(min(color[0] + 60, 255),
                        min(color[1] + 60, 255),
                        min(color[2] + 60, 255), 220))
    return Image.alpha_composite(img, overlay)


def draw_celtic_knot(d: ImageDraw.ImageDraw, cx: int, cy: int, r: int,
                     color=INK) -> None:
    """Tiny Celtic-style triquetra stamp — used as ornament."""
    # three overlapping arcs
    arms = 3
    for i in range(arms):
        ang = (i / arms) * 2 * math.pi - math.pi / 2
        ox = int(math.cos(ang) * r * 0.5)
        oy = int(math.sin(ang) * r * 0.5)
        d.ellipse((cx + ox - r, cy + oy - r, cx + ox + r, cy + oy + r),
                  outline=color + (180,), width=2)


# ── wood plank base ────────────────────────────────────────────────────────
def make_wood(w: int, h: int) -> Image.Image:
    """Hand-cut horizontal wood planks with grain and shadows."""
    # base grain
    grain = fbm(h, w, octaves=4, base_scale=128)
    # streaks (anisotropic horizontal grain)
    streaks = fbm(h, w * 4, octaves=4, base_scale=96)
    streaks = np.array(Image.fromarray(
        (streaks * 255).astype(np.uint8)).resize((w, h), Image.BILINEAR),
        dtype=np.float32) / 255.0
    blend = np.clip(0.5 * grain + 0.5 * streaks, 0.0, 1.0)
    img = lerp_color(WOOD_DARK, WOOD_LIGHT, blend)

    # plank seams every ~60px
    plank_h = max(48, h // 5)
    img2 = img.copy()
    for y in range(plank_h, h, plank_h):
        # darker seam line
        img2[max(0, y - 1):y + 1, :] = (img2[max(0, y - 1):y + 1, :] * 0.55).astype(np.uint8)

    # vignette
    v = vignette(h, w, strength=0.35, falloff=1.2)
    img2 = (img2.astype(np.float32) * v[..., None]).clip(0, 255).astype(np.uint8)

    return Image.fromarray(img2, mode="RGB").convert("RGBA")


# ── individual panel builders ──────────────────────────────────────────────
def build_parchment_panel(out: Path, w: int = 512, h: int = 512) -> None:
    img = make_parchment(w, h)
    img = add_ink_border(img, inset=14, line_w=3, corner_radius=18)
    img = draw_corner_studs(img, inset=24, r=7, color=BRASS)
    img.save(out, optimize=True)


def build_parchment_small(out: Path, w: int = 256, h: int = 256) -> None:
    img = make_parchment(w, h)
    img = add_ink_border(img, inset=8, line_w=2, corner_radius=10)
    img = draw_corner_studs(img, inset=14, r=4, color=BRASS)
    img.save(out, optimize=True)


def build_wood_panel(out: Path, w: int = 512, h: int = 384) -> None:
    img = make_wood(w, h)
    # iron-band frame: top + bottom horizontal bars
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    band_h = 14
    for (y0, y1) in [(0, band_h), (h - band_h, h)]:
        d.rectangle((0, y0, w, y1), fill=(38, 32, 30, 230))
        # rivets
        for x in range(20, w - 10, 32):
            cy = (y0 + y1) // 2
            d.ellipse((x - 3, cy - 3, x + 3, cy + 3), fill=BRASS + (255,))
            d.ellipse((x - 2, cy - 2, x + 1, cy + 1),
                      fill=(min(BRASS[0]+50,255), min(BRASS[1]+50,255),
                            min(BRASS[2]+50,255), 220))
    # painted ink border around interior wood
    d.rounded_rectangle((6, band_h + 4, w - 7, h - band_h - 5),
                        radius=8, outline=INK + (180,), width=2)
    img = Image.alpha_composite(img, overlay)
    img.save(out, optimize=True)


def build_scroll_banner(out: Path, w: int = 512, h: int = 128) -> None:
    """Horizontal parchment scroll with rolled ends — for quest titles."""
    img = make_parchment(w, h)
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    # rolled wood ends (left + right caps)
    cap_w = 40
    for (x0, x1) in [(0, cap_w), (w - cap_w, w)]:
        d.rectangle((x0, 8, x1, h - 8), fill=WOOD_MID + (255,))
        # grain lines on cap
        for gy in range(14, h - 8, 6):
            d.line((x0 + 4, gy, x1 - 4, gy), fill=WOOD_DARK + (180,), width=1)
        # bronze end-caps
        d.ellipse((x0 + 6, 4, x1 - 6, 16), fill=BRASS + (255,))
        d.ellipse((x0 + 6, h - 16, x1 - 6, h - 4), fill=BRASS + (255,))
    # ink border on parchment middle
    d.rounded_rectangle((cap_w + 4, 14, w - cap_w - 5, h - 15),
                        radius=8, outline=INK + (200,), width=2)
    img = Image.alpha_composite(img, overlay)
    img.save(out, optimize=True)


def build_button(out: Path, mode: str, w: int = 192, h: int = 64) -> None:
    """Wood button — modes: normal, hover, pressed."""
    img = make_wood(w, h)
    arr = np.array(img).astype(np.float32)
    if mode == "hover":
        arr[..., :3] = np.clip(arr[..., :3] * 1.18 + 14, 0, 255)
    elif mode == "pressed":
        arr[..., :3] = np.clip(arr[..., :3] * 0.72, 0, 255)
    img = Image.fromarray(arr.astype(np.uint8), mode="RGBA")

    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    # ink border
    d.rounded_rectangle((3, 3, w - 4, h - 4), radius=8,
                        outline=INK + (220,), width=2)
    # bronze corner studs
    for (x, y) in [(12, 12), (w - 13, 12), (12, h - 13), (w - 13, h - 13)]:
        d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=BRASS + (255,))
        d.ellipse((x - 3, y - 3, x, y), fill=(220, 170, 90, 220))
    # subtle inner highlight on hover (top edge)
    if mode == "hover":
        d.line((10, 6, w - 10, 6), fill=(255, 220, 150, 90), width=1)
    img = Image.alpha_composite(img, overlay)
    img.save(out, optimize=True)


def build_divider(out: Path, w: int = 384, h: int = 24) -> None:
    """Horizontal divider — fading ink line with celtic knot in center."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx = w // 2
    cy = h // 2
    # left + right fading line segments
    line_y = cy
    for x in range(20, cx - 18):
        # fade from 0 alpha at left to ~220 toward center
        a = int(220 * (x - 20) / (cx - 38))
        d.line((x, line_y, x + 1, line_y), fill=INK + (a,), width=2)
    for x in range(cx + 18, w - 20):
        a = int(220 * (1 - (x - cx - 18) / (w - cx - 38)))
        d.line((x, line_y, x + 1, line_y), fill=INK + (a,), width=2)
    # center knot
    draw_celtic_knot(d, cx, cy, r=7, color=BRASS_DK)
    img.save(out, optimize=True)


def write_attribution(out: Path) -> None:
    out.write_text(
        "# Eldoria UI Frames — Attribution\n\n"
        "All assets in this directory are procedurally generated by\n"
        "`scripts/art/make_ui_frames.py` (committed alongside).\n"
        "No third-party images, fonts, or trademarks are used.\n\n"
        "Style: hand-painted parchment + iron-and-wood, THEME §3 palette\n"
        "(parchment #D9C99B, ink #0E0A0E, brass #B0742A, wood tones).\n"
        "9-slice friendly: 64px borders on big panels, 32px on smalls.\n\n"
        "License: CC0 (per repo convention).\n"
        f"Seed: {RNG_SEED} (deterministic regeneration).\n",
        encoding="utf-8",
    )


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: make_ui_frames.py <out_dir>", file=sys.stderr)
        return 2
    out_dir = Path(sys.argv[1])
    out_dir.mkdir(parents=True, exist_ok=True)

    build_parchment_panel(out_dir / "parchment_panel.png")
    build_parchment_small(out_dir / "parchment_panel_small.png")
    build_wood_panel(out_dir / "wood_panel.png")
    build_scroll_banner(out_dir / "scroll_banner.png")
    build_button(out_dir / "button_normal.png", "normal")
    build_button(out_dir / "button_hover.png", "hover")
    build_button(out_dir / "button_pressed.png", "pressed")
    build_divider(out_dir / "divider_ornate.png")
    write_attribution(out_dir / "ATTRIBUTION.md")

    print("Generated UI frames:")
    for p in sorted(out_dir.iterdir()):
        if p.is_file():
            print(f"  {p.name:<32} {p.stat().st_size:>7} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
