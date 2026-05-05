#!/usr/bin/env python3
"""
Realm of Eldoria — procedural loot icon generator (additions).

Fills the loot-icon gap referenced by Items.gd entries whose
`icon_path` points at a PNG that does not yet exist in
`eldoria-godot/assets/icons/`. Discovered gap (run 17 audit):

  - wolf_fang.png  (item id `wolf_fang`, Color(0.92,0.88,0.78), stack)

Style targets (THEME.md §1, §3, §5):
  - §1 painterly, hand-painted concept-art aesthetic; warm, weathered.
  - §3 palette compliance — parchment / sepia ground, ivory bone for
    fang, charcoal ink shadow, brass-amber blood-rim accent. No neon,
    no fluorescent, no pure white.
  - §5 hand-painted look — soft Gaussian rim, brushy speckle, gentle
    drop-shadow.  No crisp vector edges.

Output: 128x128 RGBA PNG with transparent background (no disc — item
icons mirror wolf_pelt.png which is loot-on-transparent so the
inventory grid's parchment cell shows through).

License: CC0 — generated procedurally with Pillow, no external assets.

Run: python3 gen_loot_icons.py <out_dir>
"""
from __future__ import annotations

import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter

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


def _rand(seed: int) -> random.Random:
	return random.Random(seed)


def _fang_path(super_w: int) -> list[tuple[int, int]]:
	"""Curved canine-tooth silhouette as a dense closed polygon.

	Profile: an S-curved fang ~80% canvas height with a J-curl tip,
	flared root that thickens above the gum line and tapers smoothly
	to a sharp point. Sampled with ~40 points so the rim reads as a
	hand-painted curve, not a faceted polygon.

	Bias to the LEFT so it tilts visibly (per THEME §1 hand-painted
	character). Returns SUPER-resolution coordinates.
	"""
	cx = super_w // 2
	top_y = int(super_w * 0.12)        # top of root crown
	gum_y = int(super_w * 0.30)        # widest point — gum-line flare
	tip_y = int(super_w * 0.93)        # sharp tip
	# tip biased LEFT, root biased RIGHT — gives the J-curl feel
	tip_x = cx - int(super_w * 0.08)
	root_cx = cx + int(super_w * 0.02)

	root_half = int(super_w * 0.16)    # crown half-width
	gum_half = int(super_w * 0.21)     # widest at gum line
	N = 40                             # samples per side

	# Right side: from gum-line flare (top right) curving down to tip.
	pts_r = []
	for i in range(N + 1):
		t = i / N
		# y eases from gum_y down to tip_y (cubic ease-in for tip taper)
		y = gum_y + (tip_y - gum_y) * (t * t * (3 - 2 * t))
		# half-width: starts at gum_half, smoothly tapers to 0 with a bezier-like curve
		# c1 controls belly fullness; lower = thinner belly
		w0 = gum_half
		w1 = int(super_w * 0.07)   # belly
		w2 = 0                      # tip
		bezier_w = (1 - t) ** 2 * w0 + 2 * (1 - t) * t * w1 + t ** 2 * w2
		# x bias drift from root_cx toward tip_x
		bias_t = t * t
		bx = root_cx * (1 - bias_t) + tip_x * bias_t
		pts_r.append((int(bx + bezier_w), int(y)))

	# Tip cap (already at tip via t=1)
	# Left side: from tip back UP to top of crown.
	pts_l = []
	for i in range(N + 1):
		t = 1.0 - i / N  # walk from t=1 back to 0
		y = gum_y + (tip_y - gum_y) * (t * t * (3 - 2 * t))
		w0 = gum_half
		w1 = int(super_w * 0.07)
		w2 = 0
		bezier_w = (1 - t) ** 2 * w0 + 2 * (1 - t) * t * w1 + t ** 2 * w2
		bias_t = t * t
		bx = root_cx * (1 - bias_t) + tip_x * bias_t
		pts_l.append((int(bx - bezier_w), int(y)))

	# Crown — root cap from upper-left corner around to upper-right.
	# Walk a small arc from (root_cx - root_half, gum_y) up and over to
	# (root_cx + root_half, gum_y), peaking at top_y.
	crown = []
	M = 18
	for i in range(M + 1):
		t = i / M
		# x walks from -root_half to +root_half
		x = root_cx + (-root_half + 2 * root_half * t)
		# y peaks at top_y in the middle, dipping back to gum_y at edges
		# use a parabola
		dip = 4 * t * (1 - t)  # 0 at edges, 1 at center
		y = gum_y - (gum_y - top_y) * dip
		crown.append((int(x), int(y)))
	# Order: pts_r goes top-gum-right → tip; then pts_l goes tip → top-gum-left;
	# then crown walks left-gum → right-gum (closing the top).
	# We need the polygon to be a single closed loop.
	# Build: crown (left→right at top), pts_r (right gum → tip), pts_l (tip → left gum)
	return crown + pts_r + pts_l


def _blend(a: tuple[int, int, int, int], b: tuple[int, int, int, int], t: float):
	return (
		int(a[0] * (1 - t) + b[0] * t),
		int(a[1] * (1 - t) + b[1] * t),
		int(a[2] * (1 - t) + b[2] * t),
		int(a[3] * (1 - t) + b[3] * t),
	)


def _shaded_fang(seed: int) -> Image.Image:
	r = _rand(seed)
	canvas = Image.new("RGBA", (W, W), (0, 0, 0, 0))
	draw = ImageDraw.Draw(canvas, "RGBA")

	poly = _fang_path(W)

	# Drop shadow — soft, offset down-right per THEME warm-light convention.
	shadow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
	sd = ImageDraw.Draw(shadow, "RGBA")
	off = int(W * 0.012)
	shifted = [(x + off, y + off) for x, y in poly]
	sd.polygon(shifted, fill=(0, 0, 0, 110))
	shadow = shadow.filter(ImageFilter.GaussianBlur(radius=W // 60))
	canvas = Image.alpha_composite(canvas, shadow)

	# Base flat fill — ivory mid-tone
	base = Image.new("RGBA", (W, W), (0, 0, 0, 0))
	bd = ImageDraw.Draw(base, "RGBA")
	bd.polygon(poly, fill=IVORY)
	canvas = Image.alpha_composite(canvas, base)

	# Vertical lighting gradient — top-bright (rim-lit), bottom-tip warmer.
	grad = Image.new("RGBA", (W, W), (0, 0, 0, 0))
	gd = ImageDraw.Draw(grad, "RGBA")
	steps = 80
	for i in range(steps):
		t = i / float(steps - 1)
		y0 = int(W * 0.05 + t * W * 0.92)
		y1 = y0 + int(W * 0.92 / steps) + 1
		col = _blend(IVORY_LT, IVORY_SHADE, t * 0.85)
		# alpha tapers so we tint, not paint over
		col = (col[0], col[1], col[2], 95)
		gd.rectangle((0, y0, W, y1), fill=col)
	# mask gradient to the fang shape only
	mask = Image.new("L", (W, W), 0)
	ImageDraw.Draw(mask).polygon(poly, fill=255)
	grad.putalpha(mask)
	canvas = Image.alpha_composite(canvas, grad)

	# Specular highlight — a single soft brushstroke down the LEFT side.
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
	hi.putalpha(ImageChops_multiply_alpha(hi.split()[-1], mask))
	canvas = Image.alpha_composite(canvas, hi)

	# Crack/wear lines — fine ink streaks running along the fang's length.
	# Replaces the prior "blood spots" which read as decorative dots.
	wear = Image.new("RGBA", (W, W), (0, 0, 0, 0))
	wd = ImageDraw.Draw(wear, "RGBA")
	cx = W // 2
	for streak in range(5):
		x_off = int((r.random() - 0.5) * W * 0.16)
		y0 = int(W * 0.32 + r.random() * W * 0.10)
		y1 = int(W * 0.55 + r.random() * W * 0.25)
		jitter = []
		for s in range(8):
			t = s / 7.0
			y = int(y0 + (y1 - y0) * t)
			x = cx + x_off + int((r.random() - 0.5) * W * 0.012)
			jitter.append((x, y))
		col = (INK[0], INK[1], INK[2], 60 + int(r.random() * 50))
		wd.line(jitter, fill=col, width=int(W * 0.005))
	wear = wear.filter(ImageFilter.GaussianBlur(radius=W // 220))
	wm = Image.new("L", (W, W), 0)
	ImageDraw.Draw(wm).polygon(poly, fill=255)
	wm = wm.filter(ImageFilter.MinFilter(7))
	wear.putalpha(ImageChops_multiply_alpha(wear.split()[-1], wm))
	canvas = Image.alpha_composite(canvas, wear)

	# Subtle blood-rim accent at the very root tip — a thin warm wash, not dots.
	blood = Image.new("RGBA", (W, W), (0, 0, 0, 0))
	bld = ImageDraw.Draw(blood, "RGBA")
	root_band = (int(W * 0.30), int(W * 0.12), int(W * 0.70), int(W * 0.20))
	bld.rectangle(root_band, fill=(WINE[0], WINE[1], WINE[2], 75))
	blood = blood.filter(ImageFilter.GaussianBlur(radius=W // 50))
	bm = Image.new("L", (W, W), 0)
	ImageDraw.Draw(bm).polygon(poly, fill=255)
	blood.putalpha(ImageChops_multiply_alpha(blood.split()[-1], bm))
	canvas = Image.alpha_composite(canvas, blood)

	# Ink rim — thin charcoal outline per THEME §5 hand-painted (not crisp).
	rim = Image.new("RGBA", (W, W), (0, 0, 0, 0))
	rd = ImageDraw.Draw(rim, "RGBA")
	rd.polygon(poly, outline=INK, width=int(W * 0.008))
	rim = rim.filter(ImageFilter.GaussianBlur(radius=W // 280))
	canvas = Image.alpha_composite(canvas, rim)

	# Brushy speckle inside fang for hand-painted texture (very subtle).
	speck = Image.new("RGBA", (W, W), (0, 0, 0, 0))
	spd = ImageDraw.Draw(speck, "RGBA")
	for _ in range(160):
		x = r.randint(0, W - 1)
		y = r.randint(0, W - 1)
		rad = r.randint(1, 3) * (W // 128)
		col_choice = r.random()
		if col_choice < 0.55:
			col = (PARCHMENT_DK[0], PARCHMENT_DK[1], PARCHMENT_DK[2], 35)
		elif col_choice < 0.85:
			col = (IVORY_SHADE[0], IVORY_SHADE[1], IVORY_SHADE[2], 28)
		else:
			col = (INK[0], INK[1], INK[2], 22)
		spd.ellipse((x - rad, y - rad, x + rad, y + rad), fill=col)
	sm = Image.new("L", (W, W), 0)
	ImageDraw.Draw(sm).polygon(poly, fill=255)
	speck.putalpha(ImageChops_multiply_alpha(speck.split()[-1], sm))
	canvas = Image.alpha_composite(canvas, speck)

	return canvas.resize((SIZE, SIZE), Image.LANCZOS)


def ImageChops_multiply_alpha(a, b):
	# multiply two L masks to combine — Pillow has ImageChops.multiply
	from PIL import ImageChops
	return ImageChops.multiply(a, b)


def main():
	out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
	os.makedirs(out_dir, exist_ok=True)

	# wolf_fang — single deterministic seed so re-runs produce identical bytes.
	img = _shaded_fang(seed=20260505)
	out = os.path.join(out_dir, "wolf_fang.png")
	img.save(out, "PNG", optimize=True)
	print(f"wrote {out} ({os.path.getsize(out)} bytes)")


if __name__ == "__main__":
	main()
