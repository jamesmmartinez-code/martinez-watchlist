#!/usr/bin/env python3
"""
Realm of Eldoria — procedural affix overlay icon generator.

Produces 6 painterly 64×64 PNG badges for the AFFIX_SUFFIXES table in
Items.gd. Each badge is a hand-painted-feel disc with a stylised symbol
in the affix's themed palette per THEME.md §3.

Style targets (THEME.md):
  - painterly, hand-painted concept-art aesthetic (§1)
  - sunset / wine / moss / parchment palette dominant; magic accents
    (fey-cyan, warlock-purple, frost-silver) ONLY for magic affixes (§3)
  - weathered, slightly irregular brushstroke edge (§5: "no flat-UI",
    "no glassmorphism", "Hand-painted look, not crisp vector")

Output: 6 RGBA PNGs at 64×64, transparent background, in
        eldoria-godot/assets/icons/affix/<slug>.png

License: CC0 — generated procedurally with Pillow, no external assets.

Run:  python3 gen_affix_icons.py <out_dir>
"""
from __future__ import annotations

import math
import os
import random
import sys
from PIL import Image, ImageDraw, ImageFilter

SIZE = 64
SUPER = 4  # supersample for smoother painted edge
W = SIZE * SUPER

# THEME.md §3 palette
PARCHMENT = (217, 201, 155, 255)
INK = (14, 10, 14, 255)
SUNSET_GOLD = (255, 200, 80, 255)
CRIMSON = (140, 32, 32, 255)
MOSS = (74, 112, 56, 255)
BRASS = (176, 116, 42, 255)
FROST_CYAN = (101, 223, 229, 255)
ARCANE = (124, 63, 176, 255)
SILVER = (200, 224, 229, 255)
EMBER = (255, 128, 0, 255)
BEAR_BROWN = (135, 90, 50, 255)
SWIFT_GREEN = (140, 200, 110, 255)
DRAGON_GOLD = (255, 215, 70, 255)


def _rand(seed):
	r = random.Random(seed)
	return r


def _alpha_blend(c, a):
	return (c[0], c[1], c[2], int(a * c[3] / 255))


def _paint_disc(img, draw, base, rim, accent, seed):
	"""Painterly badge background — irregular disc with brushstroke rim."""
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	radius = int(W * 0.46)

	# Soft gradient body — radial-ish via concentric translucent discs.
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

	# Rim with brushstroke wobble — short arcs at jittered angles.
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

	# Accent flecks — 6-10 small painterly highlights.
	for _ in range(8):
		ang = r.uniform(0, math.tau)
		rr = r.uniform(0.05, 0.85) * radius
		x = cx + math.cos(ang) * rr
		y = cy + math.sin(ang) * rr
		s = r.randint(2, 4) * SUPER // 2
		col = (accent[0], accent[1], accent[2], r.randint(40, 110))
		draw.ellipse((x - s, y - s, x + s, y + s), fill=col)


def _draw_frost(draw, seed):
	"""Six-arm crystal snowflake."""
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	armlen = int(W * 0.30)
	core = (FROST_CYAN[0], FROST_CYAN[1], FROST_CYAN[2], 255)
	pale = (SILVER[0], SILVER[1], SILVER[2], 240)
	for i in range(6):
		ang = i * math.tau / 6
		dx, dy = math.cos(ang), math.sin(ang)
		x1, y1 = cx + dx * armlen, cy + dy * armlen
		# main arm
		draw.line((cx, cy, x1, y1), fill=core, width=int(SUPER * 1.6))
		# side branches at 1/2 and 2/3 along arm
		for t, sub in ((0.45, 0.35), (0.72, 0.25)):
			bx, by = cx + dx * armlen * t, cy + dy * armlen * t
			for s in (-1, 1):
				ang2 = ang + s * math.pi / 4
				ex = bx + math.cos(ang2) * armlen * sub
				ey = by + math.sin(ang2) * armlen * sub
				draw.line((bx, by, ex, ey), fill=core, width=int(SUPER * 1.1))
		# tip glint
		gs = SUPER * 2
		draw.ellipse((x1 - gs, y1 - gs, x1 + gs, y1 + gs), fill=pale)
	# centre orb
	cs = SUPER * 4
	draw.ellipse((cx - cs, cy - cs, cx + cs, cy + cs), fill=pale)
	cs = SUPER * 2
	draw.ellipse((cx - cs, cy - cs, cx + cs, cy + cs), fill=(255, 255, 255, 230))


def _draw_embers(draw, seed):
	"""Painted flame silhouette with inner glow."""
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	flame_outer = []
	flame_inner = []
	# outer flame contour (teardrop with painterly wobble)
	steps = 36
	h = int(W * 0.36)
	w = int(W * 0.24)
	for i in range(steps):
		t = i / steps
		ang = t * math.tau
		# Flame shape: tall on +y up, pinched at top, broad at base
		dy = -math.cos(ang) * h * (0.85 + 0.15 * math.sin(ang * 3))
		dx = math.sin(ang) * w * (0.8 + 0.2 * math.sin(ang * 2 + 0.3))
		# Top tip stretches up
		if dy < 0:
			dy *= 1.3
		dx += r.uniform(-1.5, 1.5) * SUPER
		dy += r.uniform(-1.5, 1.5) * SUPER
		flame_outer.append((cx + dx, cy + dy))
	draw.polygon(flame_outer, fill=(EMBER[0], EMBER[1], EMBER[2], 240))

	# inner core (yellow-white hot)
	for i in range(steps):
		t = i / steps
		ang = t * math.tau
		dy = -math.cos(ang) * h * 0.55
		dx = math.sin(ang) * w * 0.55
		if dy < 0:
			dy *= 1.25
		flame_inner.append((cx + dx, cy + dy))
	draw.polygon(flame_inner, fill=(SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], 230))
	# white-hot heart
	heart = []
	for i in range(steps):
		t = i / steps
		ang = t * math.tau
		dy = -math.cos(ang) * h * 0.30 - h * 0.10
		dx = math.sin(ang) * w * 0.32
		heart.append((cx + dx, cy + dy))
	draw.polygon(heart, fill=(255, 240, 200, 220))


def _draw_bear(draw, seed):
	"""Three-claw rake mark — diagonal slashes."""
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	# subtle dark patch under the claws to read as fur tear
	patch_col = (40, 24, 16, 110)
	for _ in range(20):
		x = cx + r.randint(-W // 4, W // 4)
		y = cy + r.randint(-W // 4, W // 4)
		s = r.randint(2, 5) * SUPER
		draw.ellipse((x - s, y - s, x + s, y + s), fill=patch_col)
	# 3 claw rakes diagonal top-left → bottom-right
	for i in (-1, 0, 1):
		offset = i * SUPER * 5
		# slight curve via two segments
		x0, y0 = cx - W * 0.26 + offset, cy - W * 0.22
		x1, y1 = cx + offset * 0.6, cy
		x2, y2 = cx + W * 0.24 + offset * 0.6, cy + W * 0.22
		# wider darker base, narrower bright top stroke
		for col, w in (((20, 10, 6, 230), int(SUPER * 4)),
		               ((BEAR_BROWN[0], BEAR_BROWN[1], BEAR_BROWN[2], 250), int(SUPER * 2.5)),
		               ((255, 230, 200, 220), int(SUPER * 1.0))):
			draw.line((x0, y0, x1, y1), fill=col, width=w)
			draw.line((x1, y1, x2, y2), fill=col, width=w)
		# claw nick at the start (sharp triangle highlight)
		nick = [(x0 - SUPER * 2, y0 - SUPER * 2),
		        (x0 + SUPER * 2, y0),
		        (x0, y0 + SUPER * 3)]
		draw.polygon(nick, fill=(255, 240, 220, 200))


def _draw_swiftness(draw, seed):
	"""Three trailing wind streaks."""
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	# big chevron streak top, smaller two below
	streaks = [
		(cx - W * 0.30, cy - W * 0.18, cx + W * 0.30, cy - W * 0.12, int(SUPER * 4)),
		(cx - W * 0.34, cy + W * 0.02, cx + W * 0.26, cy + W * 0.06, int(SUPER * 3)),
		(cx - W * 0.22, cy + W * 0.20, cx + W * 0.30, cy + W * 0.22, int(SUPER * 3)),
	]
	for x0, y0, x1, y1, width in streaks:
		# soft halo
		halo = (SWIFT_GREEN[0], SWIFT_GREEN[1], SWIFT_GREEN[2], 110)
		draw.line((x0, y0, x1, y1), fill=halo, width=width + SUPER * 2)
		# main stroke
		draw.line((x0, y0, x1, y1), fill=(SWIFT_GREEN[0], SWIFT_GREEN[1], SWIFT_GREEN[2], 240), width=width)
		# bright leading edge
		draw.line((x1 - SUPER * 6, y1 - 1, x1, y1), fill=(255, 255, 230, 230), width=max(2, width // 2))
	# leaf flecks for fey-wind feel
	for _ in range(7):
		x = cx + r.randint(-W // 3, W // 3)
		y = cy + r.randint(-W // 4, W // 4)
		s = SUPER * 2
		col = (MOSS[0], MOSS[1], MOSS[2], r.randint(120, 200))
		draw.ellipse((x - s, y - s // 2, x + s, y + s // 2), fill=col)


def _draw_dragon(draw, seed):
	"""Slit-pupil dragon eye — gold iris on shadowed scale."""
	r = _rand(seed)
	cx, cy = W // 2, W // 2

	# scaly eyelid backdrop — overlapping dark crescents
	for i in range(8):
		t = i / 8.0
		ang = math.pi + t * math.pi
		ox = math.cos(ang) * W * 0.30
		oy = math.sin(ang) * W * 0.30
		col = (28 + i * 3, 18 + i * 2, 10 + i * 2, 200)
		s = int(W * 0.18)
		draw.ellipse((cx + ox - s, cy + oy - s, cx + ox + s, cy + oy + s), fill=col)

	# iris (gold radial)
	ir = int(W * 0.30)
	for i in range(ir, 0, -2):
		t = i / ir
		col = (
			int(DRAGON_GOLD[0] * t + 80 * (1 - t)),
			int(DRAGON_GOLD[1] * t + 50 * (1 - t)),
			int(DRAGON_GOLD[2] * t + 20 * (1 - t)),
			255,
		)
		draw.ellipse((cx - i, cy - i, cx + i, cy + i), fill=col)

	# slit pupil
	pw = int(SUPER * 2.2)
	ph = int(W * 0.26)
	draw.ellipse((cx - pw, cy - ph, cx + pw, cy + ph), fill=INK)

	# top highlight
	hi = (255, 240, 200, 220)
	hs = SUPER * 2
	draw.ellipse((cx - hs * 2, cy - int(W * 0.18), cx + hs, cy - int(W * 0.13)), fill=hi)

	# scale ridge above and below
	for sign in (-1, 1):
		for i in range(5):
			x = cx - W * 0.28 + (i / 4.0) * W * 0.56
			y = cy + sign * W * 0.34 + r.uniform(-1, 1) * SUPER
			s = SUPER * 3
			col = (BRASS[0], BRASS[1], BRASS[2], 200)
			draw.ellipse((x - s, y - s // 2, x + s, y + s // 2), fill=col)


def _draw_stars(draw, seed):
	"""Four-point starburst with smaller star companions."""
	r = _rand(seed)
	cx, cy = W // 2, W // 2

	def four_point(cxx, cyy, R, ratio, col, glow_col=None):
		points = []
		for i in range(8):
			ang = -math.pi / 2 + i * math.pi / 4
			rr = R if i % 2 == 0 else R * ratio
			points.append((cxx + math.cos(ang) * rr, cyy + math.sin(ang) * rr))
		if glow_col is not None:
			# soft glow halo
			gpoints = []
			for i in range(8):
				ang = -math.pi / 2 + i * math.pi / 4
				rr = R * 1.25 if i % 2 == 0 else R * ratio * 1.25
				gpoints.append((cxx + math.cos(ang) * rr, cyy + math.sin(ang) * rr))
			draw.polygon(gpoints, fill=glow_col)
		draw.polygon(points, fill=col)

	# central star
	four_point(cx, cy, int(W * 0.30), 0.32,
	           col=(255, 250, 225, 245),
	           glow_col=(SILVER[0], SILVER[1], SILVER[2], 90))
	# inner bright cross
	four_point(cx, cy, int(W * 0.18), 0.28,
	           col=(255, 255, 255, 255))
	# small companion stars
	companions = [
		(cx - W * 0.30, cy - W * 0.20, int(W * 0.07)),
		(cx + W * 0.26, cy - W * 0.28, int(W * 0.06)),
		(cx + W * 0.30, cy + W * 0.22, int(W * 0.08)),
		(cx - W * 0.24, cy + W * 0.28, int(W * 0.05)),
	]
	for (x, y, R) in companions:
		four_point(x, y, R, 0.32,
		           col=(SILVER[0], SILVER[1], SILVER[2], 240),
		           glow_col=(ARCANE[0], ARCANE[1], ARCANE[2], 80))


# Each affix: (slug, palette_base, rim, accent, drawer)
AFFIX_DEFS = [
	("frost",      ( 60, 110, 130, 255), ( 30,  60,  80, 255), FROST_CYAN,  _draw_frost,     7301),
	("embers",     (130,  56,  20, 255), ( 70,  24,  10, 255), EMBER,        _draw_embers,    7302),
	("bear",       ( 95,  62,  35, 255), ( 50,  28,  14, 255), BEAR_BROWN,   _draw_bear,      7303),
	("swiftness",  ( 60,  90,  50, 255), ( 28,  48,  22, 255), SWIFT_GREEN,  _draw_swiftness, 7304),
	("dragon",     (115,  60,  16, 255), ( 60,  28,   8, 255), DRAGON_GOLD,  _draw_dragon,    7305),
	("stars",      ( 50,  40,  85, 255), ( 22,  18,  44, 255), ARCANE,       _draw_stars,     7306),
]


def render_one(slug, base, rim, accent, drawer, seed, out_path):
	img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
	draw = ImageDraw.Draw(img, "RGBA")

	_paint_disc(img, draw, base, rim, accent, seed)
	drawer(draw, seed + 1)

	# Subtle painterly grain overlay
	noise = Image.new("RGBA", (W, W), (0, 0, 0, 0))
	ndraw = ImageDraw.Draw(noise, "RGBA")
	r = _rand(seed + 99)
	for _ in range(900):
		x = r.randint(0, W - 1)
		y = r.randint(0, W - 1)
		a = r.randint(8, 28)
		c = r.randint(0, 1)
		col = (255, 240, 210, a) if c else (10, 6, 4, a)
		ndraw.point((x, y), fill=col)
	img = Image.alpha_composite(img, noise)

	# Soft blur to break vector-crispness — 0.5px after downsample.
	img = img.filter(ImageFilter.GaussianBlur(radius=SUPER * 0.30))

	# Downsample with high-quality filter for painted edges.
	out = img.resize((SIZE, SIZE), Image.LANCZOS)

	# Final: clip away anything outside a soft circular alpha mask so the
	# disc has a clean (but slightly irregular) outline rather than square.
	mask = Image.new("L", (SIZE, SIZE), 0)
	mdraw = ImageDraw.Draw(mask)
	pad = 2
	mdraw.ellipse((pad, pad, SIZE - pad, SIZE - pad), fill=255)
	mask = mask.filter(ImageFilter.GaussianBlur(radius=0.6))
	r2, g2, b2, a2 = out.split()
	a2 = Image.eval(a2, lambda v: v).point(lambda v: v)
	# multiply the existing alpha by the soft circular mask
	from PIL import ImageChops
	a2 = ImageChops.multiply(a2, mask)
	out = Image.merge("RGBA", (r2, g2, b2, a2))

	out.save(out_path, "PNG", optimize=True)
	return out_path


def main():
	out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
	os.makedirs(out_dir, exist_ok=True)
	written = []
	for slug, base, rim, accent, drawer, seed in AFFIX_DEFS:
		p = os.path.join(out_dir, f"{slug}.png")
		render_one(slug, base, rim, accent, drawer, seed, p)
		written.append(p)
	for p in written:
		size = os.path.getsize(p)
		print(f"OK  {p}  {size}B")


if __name__ == "__main__":
	main()
