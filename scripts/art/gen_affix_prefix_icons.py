#!/usr/bin/env python3
"""
Realm of Eldoria — procedural affix-prefix tier crest generator.

Produces 7 painterly 64x64 PNG badges for the AFFIX_PREFIXES table in
Items.gd. Each badge is a hand-painted-feel disc with a stylised symbol
keyed to its rarity tier per THEME.md SS3.

Mirrors the schema/style of gen_affix_icons.py (which produced the
6 affix-suffix overlays) so the inventory grid will read with consistent
heraldic vocabulary once a future Builder/Polisher run consumes the new
affix_icon_path field on AFFIX_PREFIXES.

Tier -> palette mapping (THEME.md SS3 compliant):
  uncommon  -> moss green + parchment   (Gleaming, Sharpened, Sturdy)
  rare      -> stone grey-blue + silver (Fierce, Heroic)
  epic      -> arcane purple + silver   (Mythic)
  legendary -> sunset gold + brass      (Ancient)

Symbols (silhouette-distinct at bag-grid scale):
  Gleaming   - polished diamond facet     (loot-shine motif)
  Sharpened  - single bright blade edge   (whetstone motif)
  Sturdy     - kite shield + boss         (defense motif)
  Fierce     - three-fang bite mark       (predator motif)
  Heroic     - laurel + circlet           (oath motif)
  Mythic     - eight-point burst star     (epic-tier motif)
  Ancient    - runic monogram in ring     (lost-language motif)

Output: 7 RGBA PNGs at 64x64, transparent background, in
        eldoria-godot/assets/icons/affix/prefix/<slug>.png

License: CC0 - generated procedurally with Pillow, no external assets.

Run:  python3 gen_affix_prefix_icons.py <out_dir>
"""
from __future__ import annotations

import math
import os
import random
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

SIZE = 64
SUPER = 4
W = SIZE * SUPER

# THEME.md SS3 palette anchors
PARCHMENT = (217, 201, 155, 255)
INK = (14, 10, 14, 255)
SUNSET_GOLD = (255, 200, 80, 255)
CRIMSON = (140, 32, 32, 255)
MOSS = (74, 112, 56, 255)
BRASS = (176, 116, 42, 255)
STONE = (123, 134, 147, 255)
FROST_CYAN = (101, 223, 229, 255)
ARCANE = (124, 63, 176, 255)
SILVER = (200, 224, 229, 255)
EMBER = (255, 128, 0, 255)
DRAGON_GOLD = (255, 215, 70, 255)
WINE = (140, 32, 32, 255)


def _rand(seed):
	return random.Random(seed)


def _paint_disc(draw, base, rim, accent, seed):
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	radius = int(W * 0.46)

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

	for _ in range(8):
		ang = r.uniform(0, math.tau)
		rr = r.uniform(0.05, 0.85) * radius
		x = cx + math.cos(ang) * rr
		y = cy + math.sin(ang) * rr
		s = r.randint(2, 4) * SUPER // 2
		col = (accent[0], accent[1], accent[2], r.randint(40, 110))
		draw.ellipse((x - s, y - s, x + s, y + s), fill=col)


def _draw_gleaming(draw, seed):
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	h = int(W * 0.32)
	w = int(W * 0.20)
	pts = [(cx, cy - h), (cx + w, cy), (cx, cy + h), (cx - w, cy)]
	shadow = [(p[0] + SUPER * 1.5, p[1] + SUPER * 1.5) for p in pts]
	draw.polygon(shadow, fill=(20, 30, 18, 180))
	draw.polygon(pts, fill=(180, 220, 160, 245))
	draw.polygon([pts[0],
	              (cx + int(w * 0.55), cy - int(h * 0.18)),
	              (cx - int(w * 0.55), cy - int(h * 0.18))],
	             fill=(230, 250, 210, 250))
	gx0 = cx - int(w * 0.30); gy0 = cy - int(h * 0.40)
	gx1 = cx + int(w * 0.10); gy1 = cy + int(h * 0.20)
	draw.line((gx0, gy0, gx1, gy1), fill=(255, 255, 240, 230),
	          width=int(SUPER * 1.4))
	draw.line((pts[0], (cx, cy)), fill=(80, 110, 70, 200), width=int(SUPER * 0.7))
	draw.line(((cx, cy), pts[1]), fill=(80, 110, 70, 200), width=int(SUPER * 0.7))
	draw.line(((cx, cy), pts[2]), fill=(80, 110, 70, 200), width=int(SUPER * 0.7))
	draw.line(((cx, cy), pts[3]), fill=(80, 110, 70, 200), width=int(SUPER * 0.7))
	cs = SUPER * 2
	draw.ellipse((cx - cs, cy - cs, cx + cs, cy + cs), fill=(255, 255, 245, 220))


def _draw_sharpened(draw, seed):
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	bx0, by0 = cx - int(W * 0.30), cy + int(W * 0.30)
	bx1, by1 = cx + int(W * 0.30), cy - int(W * 0.30)
	draw.line((bx0, by0, bx1, by1), fill=(70, 90, 80, 230), width=int(SUPER * 4.5))
	dx = (bx1 - bx0); dy = (by1 - by0)
	mag = math.hypot(dx, dy)
	nx, ny = -dy / mag, dx / mag
	offs = SUPER * 1.2
	draw.line((bx0 + nx * offs, by0 + ny * offs,
	           bx1 + nx * offs, by1 + ny * offs),
	          fill=(245, 255, 230, 240), width=int(SUPER * 1.4))
	gx, gy = cx - int(W * 0.18), cy + int(W * 0.18)
	for s in (-1, 1):
		draw.line((gx - s * SUPER * 4, gy + s * SUPER * 4,
		           gx + s * SUPER * 5, gy + s * SUPER * 5),
		          fill=(BRASS[0], BRASS[1], BRASS[2], 240),
		          width=int(SUPER * 2))
	hx, hy = cx - int(W * 0.26), cy + int(W * 0.26)
	ps = SUPER * 3
	draw.ellipse((hx - ps, hy - ps, hx + ps, hy + ps),
	             fill=(BRASS[0], BRASS[1], BRASS[2], 245))
	ps = SUPER * 1
	draw.ellipse((hx - ps, hy - ps, hx + ps, hy + ps),
	             fill=(255, 230, 180, 220))
	for _ in range(5):
		dxs = r.randint(-SUPER * 2, SUPER * 6)
		dys = r.randint(-SUPER * 6, SUPER * 2)
		s = r.randint(1, 2) * SUPER
		col = (255, 240, 200, r.randint(140, 220))
		draw.ellipse((bx1 + dxs - s, by1 + dys - s,
		              bx1 + dxs + s, by1 + dys + s), fill=col)


def _draw_sturdy(draw, seed):
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	top = cy - int(W * 0.30)
	bot = cy + int(W * 0.32)
	mid = cy + int(W * 0.05)
	left = cx - int(W * 0.22)
	right = cx + int(W * 0.22)
	body = [(cx, top), (right, top + int(W * 0.06)),
	        (right, mid), (cx, bot),
	        (left, mid), (left, top + int(W * 0.06))]
	sh = [(p[0] + SUPER, p[1] + SUPER) for p in body]
	draw.polygon(sh, fill=(20, 30, 18, 170))
	draw.polygon(body, fill=(88, 130, 70, 245))
	pts = body + [body[0]]
	for i in range(len(pts) - 1):
		draw.line((pts[i], pts[i + 1]), fill=(40, 64, 32, 230),
		          width=int(SUPER * 1.5))
	draw.line((left + SUPER * 4, top + SUPER * 8,
	           right - SUPER * 4, mid + SUPER * 4),
	          fill=(PARCHMENT[0], PARCHMENT[1], PARCHMENT[2], 235),
	          width=int(SUPER * 3))
	bs = int(W * 0.07)
	bx, by = cx, cy - SUPER * 1
	draw.ellipse((bx - bs, by - bs, bx + bs, by + bs),
	             fill=(BRASS[0], BRASS[1], BRASS[2], 250))
	bs2 = int(bs * 0.55)
	draw.ellipse((bx - bs2, by - bs2, bx + bs2, by + bs2),
	             fill=(255, 220, 150, 230))
	bs3 = int(bs * 0.20)
	draw.ellipse((bx - bs3, by - bs3 - SUPER, bx + bs3, by + bs3 - SUPER),
	             fill=(255, 250, 220, 230))


def _draw_fierce(draw, seed):
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	tooth_len = int(W * 0.28)
	gum_y = cy - int(W * 0.10)
	draw.line((cx - int(W * 0.30), gum_y, cx + int(W * 0.30), gum_y),
	          fill=(60, 30, 30, 180), width=int(SUPER * 2))
	for i, ox in enumerate((-int(W * 0.18), 0, int(W * 0.18))):
		tip_y = gum_y + tooth_len + (0 if i == 1 else -int(W * 0.04))
		base_l = (cx + ox - int(W * 0.07), gum_y)
		base_r = (cx + ox + int(W * 0.07), gum_y)
		tip = (cx + ox, tip_y)
		draw.polygon([(base_l[0] + SUPER, base_l[1] + SUPER),
		              (base_r[0] + SUPER, base_r[1] + SUPER),
		              (tip[0] + SUPER, tip[1] + SUPER)],
		             fill=(20, 20, 30, 160))
		draw.polygon([base_l, base_r, tip], fill=(245, 235, 215, 250))
		draw.polygon([(cx + ox, gum_y), base_r,
		              (tip[0] + SUPER * 1, tip[1] - SUPER * 2)],
		             fill=(180, 165, 140, 200))
	mid_tip_y = gum_y + tooth_len
	for k in range(4):
		dy = SUPER * 2 + k * SUPER * 3
		dx = r.randint(-SUPER, SUPER)
		s = SUPER * (2 - k // 2)
		draw.ellipse((cx + dx - s, mid_tip_y + dy - s,
		              cx + dx + s, mid_tip_y + dy + s),
		             fill=(WINE[0], WINE[1], WINE[2], 170))


def _draw_heroic(draw, seed):
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	radius = int(W * 0.28)
	for side in (-1, 1):
		for k in range(6):
			t = k / 5.0
			ang = math.pi * (0.55 - t * 0.55) if side > 0 else math.pi * (0.45 + t * 0.55)
			lx = cx + math.cos(ang) * radius * side
			ly = cy + math.sin(ang) * radius
			leaf_w = SUPER * 4
			leaf_h = SUPER * 2
			draw.ellipse((lx - leaf_w + SUPER, ly - leaf_h + SUPER,
			              lx + leaf_w + SUPER, ly + leaf_h + SUPER),
			             fill=(30, 50, 22, 200))
			draw.ellipse((lx - leaf_w, ly - leaf_h,
			              lx + leaf_w, ly + leaf_h),
			             fill=(MOSS[0] + 10, MOSS[1] + 30, MOSS[2] + 10, 240))
			draw.line((lx - leaf_w + SUPER, ly,
			           lx + leaf_w - SUPER, ly),
			          fill=(180, 220, 130, 200), width=int(SUPER * 0.7))
	band_y = cy + int(W * 0.04)
	band_w = int(W * 0.30)
	draw.line((cx - band_w, band_y, cx + band_w, band_y),
	          fill=(BRASS[0], BRASS[1], BRASS[2], 250),
	          width=int(SUPER * 3))
	draw.line((cx - band_w, band_y - SUPER, cx + band_w, band_y - SUPER),
	          fill=(255, 230, 180, 210), width=int(SUPER * 1))
	for ox in (-band_w * 0.55, 0, band_w * 0.55):
		px = cx + int(ox)
		draw.polygon([(px - SUPER * 3, band_y - SUPER * 2),
		              (px + SUPER * 3, band_y - SUPER * 2),
		              (px, band_y - SUPER * 7)],
		             fill=(BRASS[0], BRASS[1], BRASS[2], 250))
		if ox == 0:
			gs = SUPER * 1
			draw.ellipse((px - gs, band_y - SUPER * 5 - gs,
			              px + gs, band_y - SUPER * 5 + gs),
			             fill=(WINE[0], WINE[1], WINE[2], 250))


def _draw_mythic(draw, seed):
	r = _rand(seed)
	cx, cy = W // 2, W // 2

	def n_point(cxx, cyy, R, ratio, n, col, glow_col=None):
		points = []
		for i in range(n * 2):
			ang = -math.pi / 2 + i * math.pi / n
			rr = R if i % 2 == 0 else R * ratio
			points.append((cxx + math.cos(ang) * rr, cyy + math.sin(ang) * rr))
		if glow_col is not None:
			gp = []
			for i in range(n * 2):
				ang = -math.pi / 2 + i * math.pi / n
				rr = R * 1.3 if i % 2 == 0 else R * ratio * 1.3
				gp.append((cxx + math.cos(ang) * rr, cyy + math.sin(ang) * rr))
			draw.polygon(gp, fill=glow_col)
		draw.polygon(points, fill=col)

	hr = int(W * 0.42)
	for i in range(hr, hr - 8, -1):
		t = (hr - i) / 8.0
		col = (ARCANE[0], ARCANE[1], ARCANE[2], int(70 * (1 - t)))
		draw.ellipse((cx - i, cy - i, cx + i, cy + i), fill=col)

	n_point(cx, cy, int(W * 0.32), 0.30, 8,
	        col=(245, 235, 255, 245),
	        glow_col=(SILVER[0], SILVER[1], SILVER[2], 110))
	n_point(cx, cy, int(W * 0.18), 0.25, 4,
	        col=(255, 255, 255, 255))
	for k in range(7):
		ang = k * math.tau / 7 + 0.3
		rr = int(W * 0.36)
		px = cx + math.cos(ang) * rr
		py = cy + math.sin(ang) * rr
		s = SUPER * (2 if k % 2 == 0 else 1)
		col = (ARCANE[0] + 30, ARCANE[1] + 30, ARCANE[2] + 30, 230)
		draw.ellipse((px - s, py - s, px + s, py + s), fill=col)


def _draw_ancient(draw, seed):
	r = _rand(seed)
	cx, cy = W // 2, W // 2

	ir = int(W * 0.34)
	for i in range(ir, ir - 6, -1):
		t = (ir - i) / 6.0
		col = (DRAGON_GOLD[0], DRAGON_GOLD[1], DRAGON_GOLD[2], int(180 * (1 - t)))
		draw.ellipse((cx - i, cy - i, cx + i, cy + i), outline=col, width=int(SUPER * 0.8))

	v0 = (cx, cy - int(W * 0.22))
	v1 = (cx, cy + int(W * 0.22))
	draw.line((v0[0] - SUPER, v0[1], v1[0] - SUPER, v1[1]),
	          fill=(DRAGON_GOLD[0], DRAGON_GOLD[1], DRAGON_GOLD[2], 100),
	          width=int(SUPER * 5))
	draw.line(v0 + v1, fill=(20, 14, 6, 245), width=int(SUPER * 2.6))
	draw.line((cx, cy - int(W * 0.10),
	           cx + int(W * 0.18), cy - int(W * 0.22)),
	          fill=(20, 14, 6, 245), width=int(SUPER * 2.2))
	draw.line((cx, cy + int(W * 0.04),
	           cx - int(W * 0.18), cy + int(W * 0.18)),
	          fill=(20, 14, 6, 245), width=int(SUPER * 2.2))
	for (x0, y0, x1, y1) in (
		(cx + SUPER, v0[1], cx + SUPER, v1[1]),
		(cx + SUPER, cy - int(W * 0.10) + SUPER,
		 cx + int(W * 0.18) + SUPER, cy - int(W * 0.22) + SUPER),
		(cx + SUPER, cy + int(W * 0.04) + SUPER,
		 cx - int(W * 0.18) + SUPER, cy + int(W * 0.18) + SUPER),
	):
		draw.line((x0, y0, x1, y1),
		          fill=(255, 230, 160, 170), width=int(SUPER * 0.6))

	for ang in (0, math.pi / 2, math.pi, 3 * math.pi / 2):
		rr = int(W * 0.36)
		px = cx + math.cos(ang) * rr
		py = cy + math.sin(ang) * rr
		s = SUPER * 1
		draw.ellipse((px - s, py - s, px + s, py + s),
		             fill=(DRAGON_GOLD[0], DRAGON_GOLD[1], DRAGON_GOLD[2], 240))

	for _ in range(10):
		ang = r.uniform(0, math.tau)
		rr = r.uniform(0.20, 0.40) * W
		px = cx + math.cos(ang) * rr
		py = cy + math.sin(ang) * rr
		s = SUPER * 1
		col = (DRAGON_GOLD[0], DRAGON_GOLD[1], DRAGON_GOLD[2], r.randint(60, 140))
		draw.ellipse((px - s, py - s, px + s, py + s), fill=col)


PREFIX_DEFS = [
	("gleaming",   ( 60,  92,  46, 255), ( 28,  48,  22, 255), (180, 220, 160, 255), _draw_gleaming,  7401),
	("sharpened",  ( 56,  88,  44, 255), ( 26,  46,  20, 255), (210, 220, 170, 255), _draw_sharpened, 7402),
	("sturdy",     ( 70, 100,  50, 255), ( 32,  52,  24, 255), (220, 200, 140, 255), _draw_sturdy,    7403),
	("fierce",     ( 70,  82, 100, 255), ( 28,  36,  52, 255), (220, 230, 240, 255), _draw_fierce,    7404),
	("heroic",     ( 64,  78,  98, 255), ( 26,  34,  50, 255), (BRASS[0], BRASS[1], BRASS[2], 255),  _draw_heroic, 7405),
	("mythic",     ( 60,  44,  90, 255), ( 28,  20,  44, 255), (ARCANE[0], ARCANE[1], ARCANE[2], 255), _draw_mythic, 7406),
	("ancient",    (115,  46,  28, 255), ( 60,  24,  14, 255), (DRAGON_GOLD[0], DRAGON_GOLD[1], DRAGON_GOLD[2], 255), _draw_ancient, 7407),
]


def render_one(slug, base, rim, accent, drawer, seed, out_path):
	img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
	draw = ImageDraw.Draw(img, "RGBA")

	_paint_disc(draw, base, rim, accent, seed)
	drawer(draw, seed + 1)

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

	img = img.filter(ImageFilter.GaussianBlur(radius=SUPER * 0.30))
	out = img.resize((SIZE, SIZE), Image.LANCZOS)

	mask = Image.new("L", (SIZE, SIZE), 0)
	mdraw = ImageDraw.Draw(mask)
	pad = 2
	mdraw.ellipse((pad, pad, SIZE - pad, SIZE - pad), fill=255)
	mask = mask.filter(ImageFilter.GaussianBlur(radius=0.6))
	r2, g2, b2, a2 = out.split()
	a2 = ImageChops.multiply(a2, mask)
	out = Image.merge("RGBA", (r2, g2, b2, a2))

	out.save(out_path, "PNG", optimize=True)
	return out_path


def main():
	out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
	os.makedirs(out_dir, exist_ok=True)
	written = []
	for slug, base, rim, accent, drawer, seed in PREFIX_DEFS:
		p = os.path.join(out_dir, f"{slug}.png")
		render_one(slug, base, rim, accent, drawer, seed, p)
		written.append(p)
	for p in written:
		size = os.path.getsize(p)
		print(f"OK  {p}  {size}B")


if __name__ == "__main__":
	main()
