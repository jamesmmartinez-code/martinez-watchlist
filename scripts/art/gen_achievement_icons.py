#!/usr/bin/env python3
"""
Realm of Eldoria — procedural achievement crest icon generator.

Produces 5 painterly 128x128 PNG heraldic crests, one per entry in
Achievements.ACHIEVEMENTS. Each crest is a hand-painted-feel disc with
a stylised symbol in the achievement's themed palette per THEME.md §3.

Style targets (THEME.md):
  - §1 painterly, hand-painted concept-art aesthetic; warm, weathered
  - §3 palette compliance — sunset gold / wine / moss / parchment
    dominant; magic accents (fey-cyan, frost-silver) used sparingly.
    No neon, no fluorescent, no pure white.
  - §5 hand-painted look, not crisp vector. Soft brushstroke rim,
    Gaussian-softened edges.

Output: 5 RGBA PNGs at 128x128, transparent background.

Slugs (mirror Achievements.ACHIEVEMENTS keys):
  - first_steps      the Apprentice       — sprout on parchment
  - pack_thinner     Wolf-Friend          — wolf head silhouette
  - goblin_bane      Goblin-Bane          — crossed swords
  - trusted_three    the Trusted          — three interlocking rings
  - realm_warden     Warden of Eldoria    — keep tower with banner

License: CC0 — generated procedurally with Pillow, no external assets.

Run: python3 gen_achievement_icons.py <out_dir>
"""
from __future__ import annotations
import math, os, random, sys
from PIL import Image, ImageDraw, ImageFilter

SIZE = 128
SUPER = 4
W = SIZE * SUPER

# THEME.md §3 palette
PARCHMENT = (217, 201, 155, 255)
PARCHMENT_DK = (170, 150, 110, 255)
INK = (14, 10, 14, 255)
SUNSET_GOLD = (255, 200, 80, 255)
SUNSET_DK = (200, 130, 50, 255)
CRIMSON = (140, 32, 32, 255)
WINE = (110, 24, 24, 255)
MOSS = (74, 112, 56, 255)
MOSS_LT = (120, 160, 90, 255)
BRASS = (176, 116, 42, 255)
BRASS_LT = (210, 160, 90, 255)
FROST_CYAN = (101, 223, 229, 255)
SILVER = (200, 224, 229, 255)
BEAR_BROWN = (135, 90, 50, 255)
WOLF_GREY = (170, 175, 180, 255)
STAG_BLOOD = (160, 32, 32, 255)
STONE_BLUE = (123, 134, 147, 255)


def _rand(seed):
	return random.Random(seed)


def _paint_disc(draw, base_dark, base_light, rim, seed):
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	radius = int(W * 0.46)
	for i in range(36, 0, -1):
		t = i / 36.0
		mix = 1.0 - t
		col = (
			int(base_dark[0] * (1 - mix) + base_light[0] * mix),
			int(base_dark[1] * (1 - mix) + base_light[1] * mix),
			int(base_dark[2] * (1 - mix) + base_light[2] * mix),
			min(255, int(230 * t + 25)),
		)
		rr = int(radius * t)
		draw.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=col)
	for k in range(72):
		ang = (k / 72.0) * math.tau + r.uniform(-0.04, 0.04)
		rr = radius + r.randint(-6, 6)
		x0 = cx + int(math.cos(ang) * (rr - 14))
		y0 = cy + int(math.sin(ang) * (rr - 14))
		x1 = cx + int(math.cos(ang) * rr)
		y1 = cy + int(math.sin(ang) * rr)
		col = (rim[0], rim[1], rim[2], r.randint(140, 220))
		draw.line((x0, y0, x1, y1), fill=col, width=r.randint(8, 14))
	for k in range(40):
		ang = r.uniform(0, math.tau)
		rr = int(radius * r.uniform(0.50, 0.90))
		x = cx + int(math.cos(ang) * rr)
		y = cy + int(math.sin(ang) * rr)
		col = (rim[0], rim[1], rim[2], r.randint(20, 60))
		draw.ellipse((x - 8, y - 8, x + 8, y + 8), fill=col)


def _circular_mask():
	mask = Image.new("L", (W, W), 0)
	md = ImageDraw.Draw(mask)
	cx, cy = W // 2, W // 2
	r = int(W * 0.49)
	md.ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)
	mask = mask.filter(ImageFilter.GaussianBlur(W / 256.0))
	return mask


def _finalise(img, mask, out_path):
	img.putalpha(mask)
	img = img.filter(ImageFilter.GaussianBlur(W / 320.0))
	img = img.resize((SIZE, SIZE), Image.LANCZOS)
	img.save(out_path, "PNG", optimize=True)


def _paint_sprout(draw, seed):
	r = _rand(seed)
	cx, cy = W // 2, int(W * 0.56)
	for i in range(14):
		t = i / 14.0
		col = (
			int(BEAR_BROWN[0] * (0.6 + 0.4 * t)),
			int(BEAR_BROWN[1] * (0.6 + 0.4 * t)),
			int(BEAR_BROWN[2] * (0.6 + 0.4 * t)),
			220,
		)
		ry = int(W * 0.18 * (1 - t * 0.4))
		draw.ellipse((cx - int(W * 0.30), cy + i * 4, cx + int(W * 0.30), cy + ry + i * 4), fill=col)
	stem_top = int(W * 0.22)
	for i in range(40):
		t = i / 40.0
		x = cx + int(math.sin(t * math.pi) * W * 0.01) + r.randint(-1, 1)
		y = cy - int((cy - stem_top) * t)
		col = (MOSS[0], MOSS[1], MOSS[2], 230)
		draw.ellipse((x - 7, y - 7, x + 7, y + 7), fill=col)
	def leaf(side):
		angle = math.radians(-30 if side < 0 else 30)
		base_x = cx
		base_y = int(W * 0.36)
		tip_x = base_x + int(math.cos(angle) * W * 0.20) * side
		tip_y = base_y + int(math.sin(angle) * W * 0.20)
		for i in range(20):
			t = i / 20.0
			x = int(base_x + (tip_x - base_x) * t)
			y = int(base_y + (tip_y - base_y) * t)
			rr = int(18 * math.sin(t * math.pi))
			col = (MOSS_LT[0], MOSS_LT[1], MOSS_LT[2], 230)
			draw.ellipse((x - rr, y - rr, x + rr, y + rr), fill=col)
		col = (MOSS[0], MOSS[1], MOSS[2], 200)
		draw.line((base_x, base_y, tip_x, tip_y), fill=col, width=4)
	leaf(-1)
	leaf(1)
	bud_y = stem_top - 4
	col = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], 240)
	draw.ellipse((cx - 14, bud_y - 14, cx + 14, bud_y + 14), fill=col)


def _paint_wolf_head(draw, seed):
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	pts = [
		(cx - int(W * 0.32), cy - int(W * 0.05)),
		(cx - int(W * 0.34), cy - int(W * 0.22)),
		(cx - int(W * 0.30), cy - int(W * 0.32)),
		(cx - int(W * 0.20), cy - int(W * 0.42)),
		(cx - int(W * 0.10), cy - int(W * 0.30)),
		(cx,                cy - int(W * 0.34)),
		(cx + int(W * 0.10), cy - int(W * 0.30)),
		(cx + int(W * 0.20), cy - int(W * 0.42)),
		(cx + int(W * 0.30), cy - int(W * 0.32)),
		(cx + int(W * 0.34), cy - int(W * 0.22)),
		(cx + int(W * 0.32), cy - int(W * 0.05)),
		(cx + int(W * 0.22), cy + int(W * 0.16)),
		(cx + int(W * 0.06), cy + int(W * 0.30)),
		(cx,                cy + int(W * 0.34)),
		(cx - int(W * 0.06), cy + int(W * 0.30)),
		(cx - int(W * 0.22), cy + int(W * 0.16)),
	]
	col = (INK[0], INK[1], INK[2], 240)
	draw.polygon(pts, fill=col)
	for _ in range(30):
		ang = r.uniform(0, math.tau)
		rr = r.uniform(W * 0.10, W * 0.30)
		x = cx + int(math.cos(ang) * rr)
		y = cy + int(math.sin(ang) * rr * 0.85)
		col = (60, 60, 70, r.randint(40, 90))
		draw.ellipse((x - 6, y - 6, x + 6, y + 6), fill=col)
	eye_x, eye_y = cx + int(W * 0.10), cy - int(W * 0.10)
	for i in range(4, 0, -1):
		col = (FROST_CYAN[0], FROST_CYAN[1], FROST_CYAN[2], int(80 * i / 4))
		draw.ellipse((eye_x - 4 * i, eye_y - 4 * i, eye_x + 4 * i, eye_y + 4 * i), fill=col)
	col = (240, 250, 250, 250)
	draw.ellipse((eye_x - 6, eye_y - 6, eye_x + 6, eye_y + 6), fill=col)
	nose_x, nose_y = cx, cy + int(W * 0.30)
	col = (WOLF_GREY[0], WOLF_GREY[1], WOLF_GREY[2], 200)
	draw.ellipse((nose_x - 14, nose_y - 8, nose_x + 14, nose_y + 6), fill=col)


def _paint_crossed_swords(draw, seed):
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	def sword(angle_deg):
		ang = math.radians(angle_deg)
		length = W * 0.40
		start_x = cx - int(math.cos(ang) * length * 0.55)
		start_y = cy - int(math.sin(ang) * length * 0.55)
		end_x = cx + int(math.cos(ang) * length * 0.55)
		end_y = cy + int(math.sin(ang) * length * 0.55)
		for i in range(30):
			t = i / 30.0
			x = int(start_x + (end_x - start_x) * t)
			y = int(start_y + (end_y - start_y) * t)
			thickness = int(7 * math.sin(t * math.pi))
			col = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], 240)
			draw.ellipse((x - thickness, y - thickness, x + thickness, y + thickness), fill=col)
		perp = ang + math.pi / 2
		gx, gy = cx + int(math.cos(ang) * length * 0.05), cy + int(math.sin(ang) * length * 0.05)
		bar = W * 0.10
		bx0 = gx - int(math.cos(perp) * bar)
		by0 = gy - int(math.sin(perp) * bar)
		bx1 = gx + int(math.cos(perp) * bar)
		by1 = gy + int(math.sin(perp) * bar)
		col = (BRASS[0], BRASS[1], BRASS[2], 240)
		draw.line((bx0, by0, bx1, by1), fill=col, width=14)
		px = cx - int(math.cos(ang) * length * 0.62)
		py = cy - int(math.sin(ang) * length * 0.62)
		col = (BRASS_LT[0], BRASS_LT[1], BRASS_LT[2], 240)
		draw.ellipse((px - 12, py - 12, px + 12, py + 12), fill=col)
	sword(45)
	sword(135)


def _paint_three_rings(draw, seed):
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	radius = int(W * 0.18)
	angles = [-math.pi / 2, math.pi / 2 - math.pi / 3, math.pi / 2 + math.pi / 3]
	offset = int(W * 0.12)
	centers = [
		(cx + int(math.cos(a) * offset), cy + int(math.sin(a) * offset))
		for a in angles
	]
	colors = [
		(SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], 240),
		(MOSS_LT[0], MOSS_LT[1], MOSS_LT[2], 240),
		(STAG_BLOOD[0], STAG_BLOOD[1], STAG_BLOOD[2], 240),
	]
	for ((rcx, rcy), col) in zip(centers, colors):
		for k in range(96):
			ang = (k / 96.0) * math.tau + r.uniform(-0.02, 0.02)
			rr = radius + r.randint(-3, 3)
			x = rcx + int(math.cos(ang) * rr)
			y = rcy + int(math.sin(ang) * rr)
			c2 = (col[0], col[1], col[2], r.randint(180, 240))
			draw.ellipse((x - 8, y - 8, x + 8, y + 8), fill=c2)
		for k in range(96):
			ang = (k / 96.0) * math.tau
			rr = radius - 8
			x = rcx + int(math.cos(ang) * rr)
			y = rcy + int(math.sin(ang) * rr)
			c2 = (INK[0], INK[1], INK[2], 100)
			draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=c2)


def _paint_keep(draw, seed):
	r = _rand(seed)
	cx, cy = W // 2, W // 2
	tw = int(W * 0.30)
	th = int(W * 0.40)
	tx0 = cx - tw // 2
	ty0 = cy - int(W * 0.05)
	tx1 = cx + tw // 2
	ty1 = ty0 + th
	col = (STONE_BLUE[0], STONE_BLUE[1], STONE_BLUE[2], 245)
	draw.rectangle((tx0, ty0, tx1, ty1), fill=col)
	for i in range(1, 5):
		y = ty0 + (th * i) // 5
		col = (60, 70, 80, 160)
		draw.line((tx0 + 4, y, tx1 - 4, y), fill=col, width=3)
	cren_w = tw // 7
	for i in range(3):
		bx0 = tx0 + (tw - cren_w * 5) // 2 + i * cren_w * 2
		bx1 = bx0 + cren_w
		col = (STONE_BLUE[0], STONE_BLUE[1], STONE_BLUE[2], 245)
		draw.rectangle((bx0, ty0 - cren_w, bx1, ty0), fill=col)
	dw = tw // 3
	dh = th // 3
	dx0 = cx - dw // 2
	dy0 = ty1 - dh
	dx1 = cx + dw // 2
	dy1 = ty1
	col = (40, 28, 20, 250)
	draw.rectangle((dx0, dy0, dx1, dy1), fill=col)
	draw.ellipse((dx0, dy0 - dw // 2, dx1, dy0 + dw // 2), fill=col)
	pole_x = cx
	pole_top = ty0 - int(W * 0.20)
	col = (BRASS[0], BRASS[1], BRASS[2], 245)
	draw.line((pole_x, ty0 - cren_w, pole_x, pole_top), fill=col, width=4)
	pts = [
		(pole_x, pole_top),
		(pole_x + int(W * 0.13), pole_top + int(W * 0.04)),
		(pole_x, pole_top + int(W * 0.08)),
	]
	col = (CRIMSON[0], CRIMSON[1], CRIMSON[2], 245)
	draw.polygon(pts, fill=col)
	sx, sy = pole_x + int(W * 0.04), pole_top + int(W * 0.04)
	col = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], 245)
	draw.ellipse((sx - 4, sy - 4, sx + 4, sy + 4), fill=col)


CRESTS = {
	"first_steps":   {"seed": 9101, "base_dark": (60, 90, 45, 255),  "base_light": MOSS_LT,              "rim": BRASS,             "painter": _paint_sprout},
	"pack_thinner":  {"seed": 9102, "base_dark": (50, 60, 70, 255),  "base_light": (130, 145, 160, 255), "rim": SILVER,            "painter": _paint_wolf_head},
	"goblin_bane":   {"seed": 9103, "base_dark": WINE,                "base_light": (180, 60, 50, 255),  "rim": BRASS,             "painter": _paint_crossed_swords},
	"trusted_three": {"seed": 9104, "base_dark": PARCHMENT_DK,        "base_light": PARCHMENT,           "rim": (110, 80, 30, 255),"painter": _paint_three_rings},
	"realm_warden":  {"seed": 9105, "base_dark": SUNSET_DK,           "base_light": SUNSET_GOLD,         "rim": (110, 60, 20, 255),"painter": _paint_keep},
}


def render_one(slug, spec, out_dir):
	img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
	draw = ImageDraw.Draw(img)
	_paint_disc(draw, spec["base_dark"], spec["base_light"], spec["rim"], spec["seed"])
	spec["painter"](draw, spec["seed"] + 17)
	mask = _circular_mask()
	out_path = os.path.join(out_dir, f"{slug}.png")
	_finalise(img, mask, out_path)
	return out_path


def main(argv):
	if len(argv) < 2:
		print("usage: gen_achievement_icons.py <out_dir>", file=sys.stderr)
		return 2
	out_dir = argv[1]
	os.makedirs(out_dir, exist_ok=True)
	for slug, spec in CRESTS.items():
		path = render_one(slug, spec, out_dir)
		print(f"  wrote {path}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main(sys.argv))
