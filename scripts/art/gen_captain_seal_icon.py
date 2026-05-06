#!/usr/bin/env python3
"""
Realm of Eldoria — captain_seal item icon generator (run-25 delta).

Closes the single Items.gd icon_path gap surfaced by the run-25 audit:

  - captain_seal.png  (item id `captain_seal`,  Color(0.55,0.45,0.30), rare)

Lore (Items.gd run-24 comment):
  "An iron-cast hand-stamp the south-road captain wore on a leather thong;
   Maeve keeps it on her hut mantle once the player turns it in."
  Rarity: rare. Period-correct for late medieval / early Renaissance.
  THEME §1: lived-in / weathered — meant to sit on a mantle, not be polished.

Style targets (THEME.md §1, §2, §3, §5):
  - §1 painterly, hand-painted concept-art aesthetic; warm, weathered.
  - §2 era — late medieval iron-cast hand-stamp seal, leather thong.
  - §3 palette — desaturated brass/bronze body (Items.gd Color anchor
    Color(0.55,0.45,0.30) ≈ rgb(140,115,75)), parchment ground, ink rim,
    sunset highlight rim, no neon / no fluorescent / no pure white.
  - §5 hand-painted look — soft Gaussian rims, brushy speckle, gentle
    drop shadow. No crisp vector edges.

Subject: a circular iron-cast seal disc viewed slightly off-axis, hanging
from a short leather thong threaded through a small top loop. Embossed
emblem on the face: two crossed daggers (period-correct bandit motif,
THEME §2 allowed weaponry, child-safe — no skull / no gore).

Output: 128x128 RGBA PNG, fully-painted parchment backdrop + subject on
top. Painterly parity with the inventory grid (matches gen_loot_icons.py
run-23 / run-24 contract).

License: CC0 — generated procedurally with Pillow, no external assets.

Run: python3 gen_captain_seal_icon.py <out_dir>
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
BRASS = (176, 116, 42, 255)
BRASS_DK = (110, 70, 24, 255)
BRASS_LT = (220, 168, 96, 255)
# Items.gd Color(0.55,0.45,0.30) — patinated iron-cast, anchor for the disc
IRON_PATINA = (140, 115, 75, 255)
IRON_PATINA_DK = (90, 70, 42, 255)
IRON_PATINA_LT = (190, 162, 110, 255)
IRON_DK = (62, 52, 38, 255)
IRON_RIM = (78, 64, 42, 255)
LEATHER = (110, 70, 38, 255)
LEATHER_DK = (66, 40, 22, 255)
LEATHER_LT = (160, 110, 60, 255)
MOSS = (74, 112, 56, 255)
SUNSET = (255, 175, 90, 255)


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


def _parchment_backdrop(seed: int,
                        warm_center=(255, 220, 145, 255),
                        edge=(122, 86, 50, 255)) -> Image.Image:
    """THEME §3-compliant warm parchment vignette + brushy noise + edge ring.
    Mirrors gen_loot_icons.py for inventory grid consistency."""
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


def _drop_shadow_ellipse(bbox, off_factor=0.012) -> Image.Image:
    sh = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh, "RGBA")
    off = int(W * off_factor)
    x0, y0, x1, y1 = bbox
    sd.ellipse((x0 + off, y0 + off, x1 + off, y1 + off),
               fill=(0, 0, 0, 110))
    return sh.filter(ImageFilter.GaussianBlur(radius=W // 60))


def _ink_rim_ellipse(bbox) -> Image.Image:
    x0, y0, x1, y1 = bbox
    rim = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rim, "RGBA")
    rd.ellipse((x0, y0, x1, y1), outline=INK, width=int(W * 0.008))
    return rim.filter(ImageFilter.GaussianBlur(radius=W // 280))


def _speckle_inside(seed, mask_img, palette_choices, count=700) -> Image.Image:
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


# ---------------------------------------------------------------- subject


def _disc_bbox():
    """Bounding box of the seal disc on the supersample canvas."""
    cx, cy = W // 2, int(W * 0.58)
    rad = int(W * 0.34)
    return (cx - rad, cy - rad, cx + rad, cy + rad), (cx, cy, rad)


def _crossed_daggers_polys(cx, cy, half):
    """Return two thin elongated polygons for crossed daggers, each rotated
    +/- 30deg from vertical, centered on (cx, cy). Daggers point UP-LEFT and
    UP-RIGHT (handles down) — the classic period-correct bandit motif. Half
    is the dagger length (tip to pommel)."""
    daggers = []
    for sign in (-1, +1):
        ang = math.radians(sign * 28.0)
        cos_a, sin_a = math.cos(ang), math.sin(ang)
        # Dagger built along local y-axis: tip up at y=-half, pommel down at y=+half*0.55
        # Blade shape: tip→shoulders, shoulders→guard. Guard wider. Then pommel grip.
        local = [
            (0, -half),                       # tip
            (-half * 0.10, -half * 0.20),     # left shoulder
            (-half * 0.13, +half * 0.10),     # left guard tip
            (-half * 0.05, +half * 0.10),     # left guard inner
            (-half * 0.05, +half * 0.45),     # left grip lower
            (0, +half * 0.55),                # pommel center
            (+half * 0.05, +half * 0.45),     # right grip lower
            (+half * 0.05, +half * 0.10),     # right guard inner
            (+half * 0.13, +half * 0.10),     # right guard tip
            (+half * 0.10, -half * 0.20),     # right shoulder
        ]
        world = []
        for (x, y) in local:
            wx = int(cx + x * cos_a - y * sin_a)
            wy = int(cy + x * sin_a + y * cos_a)
            world.append((wx, wy))
        daggers.append(world)
    return daggers


def _shaded_seal(seed: int) -> Image.Image:
    r = _rand(seed)
    canvas = _parchment_backdrop(seed + 1)

    bbox, (dx, dy, drad) = _disc_bbox()

    # 1. Drop shadow under the disc
    canvas = Image.alpha_composite(canvas, _drop_shadow_ellipse(bbox, 0.014))

    # 2. Disc base — patinated iron warm-brown
    base = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(base, "RGBA").ellipse(bbox, fill=IRON_PATINA)
    canvas = Image.alpha_composite(canvas, base)

    # Disc mask for clipping subsequent layers
    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).ellipse(bbox, fill=255)

    # 3. Vertical patina gradient — top-bright, bottom-shaded
    grad = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad, "RGBA")
    steps = 80
    for i in range(steps):
        t = i / float(steps - 1)
        y0 = int(W * 0.05 + t * W * 0.92)
        y1 = y0 + int(W * 0.92 / steps) + 1
        col = _blend(IRON_PATINA_LT, IRON_PATINA_DK, t * 0.95)
        gd.rectangle((0, y0, W, y1), fill=(col[0], col[1], col[2], 110))
    grad.putalpha(mask)
    canvas = Image.alpha_composite(canvas, grad)

    # 4. Outer iron rim band — slightly darker ring just inside the perimeter
    rim_band = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    rbd = ImageDraw.Draw(rim_band, "RGBA")
    rbd.ellipse(bbox, outline=IRON_RIM, width=int(W * 0.022))
    rim_band = rim_band.filter(ImageFilter.GaussianBlur(radius=W // 220))
    rim_band.putalpha(_multiply_alpha(rim_band.split()[-1], mask))
    canvas = Image.alpha_composite(canvas, rim_band)

    # 5. Inner recessed ring — the seal's stamping field is depressed slightly
    inner_r = int(drad * 0.78)
    inner_bbox = (dx - inner_r, dy - inner_r, dx + inner_r, dy + inner_r)
    inner_shadow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    isd = ImageDraw.Draw(inner_shadow, "RGBA")
    isd.ellipse(inner_bbox, outline=(40, 28, 16, 200), width=int(W * 0.012))
    inner_shadow = inner_shadow.filter(ImageFilter.GaussianBlur(radius=W // 200))
    inner_shadow.putalpha(_multiply_alpha(inner_shadow.split()[-1], mask))
    canvas = Image.alpha_composite(canvas, inner_shadow)

    # 6. Crossed daggers emblem — embossed darker shadow + raised highlight
    half = int(drad * 0.62)
    daggers = _crossed_daggers_polys(dx, dy, half)

    # 6a. Recessed shadow (offset down-right) cast by the embossed emblem
    emb_sh = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    esd = ImageDraw.Draw(emb_sh, "RGBA")
    sh_off = int(W * 0.008)
    for poly in daggers:
        shifted = [(x + sh_off, y + sh_off) for (x, y) in poly]
        esd.polygon(shifted, fill=(30, 22, 14, 180))
    emb_sh = emb_sh.filter(ImageFilter.GaussianBlur(radius=W // 240))
    emb_sh.putalpha(_multiply_alpha(emb_sh.split()[-1], mask))
    canvas = Image.alpha_composite(canvas, emb_sh)

    # 6b. Raised dagger fill — slightly LIGHTER patina (raised metal catches light)
    emb = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    edd = ImageDraw.Draw(emb, "RGBA")
    for poly in daggers:
        edd.polygon(poly, fill=IRON_PATINA_LT)
    # darker outline to define the cast edge
    for poly in daggers:
        edd.polygon(poly, outline=IRON_RIM, width=int(W * 0.005))
    emb = emb.filter(ImageFilter.GaussianBlur(radius=W // 320))
    emb.putalpha(_multiply_alpha(emb.split()[-1], mask))
    canvas = Image.alpha_composite(canvas, emb)

    # 6c. Tiny brass guard nubs at the dagger crosspieces — period detail
    nubs = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    nd = ImageDraw.Draw(nubs, "RGBA")
    nub_r = int(W * 0.008)
    for poly in daggers:
        # the guard tips are points 2 and 8 in our local-poly order
        for idx in (2, 8):
            (gx, gy) = poly[idx]
            nd.ellipse((gx - nub_r, gy - nub_r, gx + nub_r, gy + nub_r),
                       fill=BRASS_LT)
    nubs = nubs.filter(ImageFilter.GaussianBlur(radius=W // 320))
    nubs.putalpha(_multiply_alpha(nubs.split()[-1], mask))
    canvas = Image.alpha_composite(canvas, nubs)

    # 7. Top loop — small ring above the disc where the leather threads
    loop_cx = dx
    loop_cy = bbox[1] + int(W * 0.005)  # sits at the top edge
    loop_r = int(W * 0.040)
    loop_bbox = (loop_cx - loop_r, loop_cy - loop_r,
                 loop_cx + loop_r, loop_cy + loop_r)
    loop = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ld = ImageDraw.Draw(loop, "RGBA")
    # outer dark ring
    ld.ellipse(loop_bbox, fill=IRON_DK)
    # inner hole (showing parchment through)
    inner_lr = int(loop_r * 0.45)
    ld.ellipse((loop_cx - inner_lr, loop_cy - inner_lr,
                loop_cx + inner_lr, loop_cy + inner_lr),
               fill=(0, 0, 0, 0))
    # brass highlight on top of the loop
    hl_r = int(loop_r * 0.9)
    ld.arc((loop_cx - hl_r, loop_cy - hl_r,
            loop_cx + hl_r, loop_cy + hl_r),
           start=200, end=340, fill=BRASS_LT, width=int(W * 0.005))
    canvas = Image.alpha_composite(canvas, loop)

    # 8. Leather thong fragment threaded through the loop —
    #    short curved segment exiting top-left and top-right of the loop.
    thong = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    td = ImageDraw.Draw(thong, "RGBA")
    thong_w = int(W * 0.018)
    # left strand: from loop NW to upper-left corner of frame
    p1l = (loop_cx - int(loop_r * 0.85), loop_cy - int(loop_r * 0.4))
    p2l = (loop_cx - int(W * 0.18), loop_cy - int(W * 0.10))
    # right strand
    p1r = (loop_cx + int(loop_r * 0.85), loop_cy - int(loop_r * 0.4))
    p2r = (loop_cx + int(W * 0.18), loop_cy - int(W * 0.10))
    # base shadow
    td.line([p1l, p2l], fill=LEATHER_DK, width=thong_w + int(W * 0.005))
    td.line([p1r, p2r], fill=LEATHER_DK, width=thong_w + int(W * 0.005))
    # body
    td.line([p1l, p2l], fill=LEATHER, width=thong_w)
    td.line([p1r, p2r], fill=LEATHER, width=thong_w)
    # highlight stripe along the top of each strand
    td.line([p1l, p2l], fill=LEATHER_LT, width=int(W * 0.005))
    td.line([p1r, p2r], fill=LEATHER_LT, width=int(W * 0.005))
    thong = thong.filter(ImageFilter.GaussianBlur(radius=W // 280))
    canvas = Image.alpha_composite(canvas, thong)

    # 9. Pitting and moss flecks — weathered, lived-in (THEME §1)
    pitting = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    pd = ImageDraw.Draw(pitting, "RGBA")
    for _ in range(110):
        # constrain to disc area
        ang = r.uniform(0, 2 * math.pi)
        rho = r.uniform(0, drad * 0.92)
        x = int(dx + math.cos(ang) * rho)
        y = int(dy + math.sin(ang) * rho)
        rad = r.randint(2, 5) * (W // 256)
        ch = r.random()
        if ch < 0.55:
            col = (IRON_PATINA_DK[0], IRON_PATINA_DK[1], IRON_PATINA_DK[2],
                   90 + r.randint(0, 60))
        elif ch < 0.85:
            col = (40, 26, 16, 80)
        else:
            col = (MOSS[0], MOSS[1], MOSS[2], 70 + r.randint(0, 60))
        pd.ellipse((x - rad, y - rad, x + rad, y + rad), fill=col)
    pitting = pitting.filter(ImageFilter.GaussianBlur(radius=W // 320))
    pitting.putalpha(_multiply_alpha(pitting.split()[-1], mask))
    canvas = Image.alpha_composite(canvas, pitting)

    # 10. Ink rim around the disc perimeter
    canvas = Image.alpha_composite(canvas, _ink_rim_ellipse(bbox))

    # 11. Sunset highlight crescent on the upper-left rim — THEME §3 sunset accent
    glow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    gld = ImageDraw.Draw(glow, "RGBA")
    glow_cx = dx - int(drad * 0.45)
    glow_cy = dy - int(drad * 0.45)
    for radius_band in (W * 0.18, W * 0.12, W * 0.07):
        rb = int(radius_band)
        alpha = int(28 * (1.0 - radius_band / (W * 0.18)) + 22)
        gld.ellipse((glow_cx - rb, glow_cy - rb,
                     glow_cx + rb, glow_cy + rb),
                    fill=(SUNSET[0], SUNSET[1], SUNSET[2], alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=W // 22))
    glow.putalpha(_multiply_alpha(glow.split()[-1], mask))
    canvas = Image.alpha_composite(canvas, glow)

    # 12. Subtle disc-wide speckle (wear and dirt on the parchment too)
    sp = _speckle_inside(seed + 7, mask, [
        (IRON_PATINA_DK[0], IRON_PATINA_DK[1], IRON_PATINA_DK[2], 40),
        (PARCHMENT_DK[0], PARCHMENT_DK[1], PARCHMENT_DK[2], 28),
        (INK[0], INK[1], INK[2], 22),
    ], count=600)
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
    img = _shaded_seal(20260506)
    img = _palette_quantize(img, colors=112)
    out = os.path.join(out_dir, "captain_seal.png")
    img.save(out, "PNG", optimize=True)
    print(f"wrote {out} ({os.path.getsize(out)} bytes)")


if __name__ == "__main__":
    main()
