#!/usr/bin/env python3
"""
Realm of Eldoria — procedural achievement crest icon generator.

Produces 7 painterly 128x128 PNG heraldic crests, one per entry in
Achievements.ACHIEVEMENTS. Each crest is a hand-painted-feel disc with
a stylised symbol in the achievement's themed palette per THEME.md §3.

Style targets (THEME.md):
  - §1 painterly, hand-painted concept-art aesthetic; warm, weathered
  - §3 palette compliance — sunset gold / wine / moss / parchment
    dominant; magic accents (fey-cyan, frost-silver) used sparingly.
    No neon, no fluorescent, no pure white.
  - §5 hand-painted look, not crisp vector. Soft brushstroke rim,
    Gaussian-softened edges.

Output: 7 RGBA PNGs at 128x128, transparent background.

Slugs (mirror Achievements.ACHIEVEMENTS keys):
  - first_steps      the Apprentice       — sprout on parchment
  - pack_thinner     Wolf-Friend          — wolf head silhouette
  - goblin_bane      Goblin-Bane          — crossed swords
  - trusted_three    the Trusted          — three interlocking rings
  - realm_warden     Warden of Eldoria    — keep tower with banner
  - first_forge      the Forged           — anvil + crossed hammer with sparks
  - wolf_tamer       the Wolf-Tamer       — wolf head profile under three stars
  - road_warden      Road-Warden          — heraldic shield over winding south road, sun rising
  - seal_keeper      Seal-Keeper          — captain's iron seal hung from leather thong, vigil candle behind

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
MOSS_DK = (44, 70, 32, 255)
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


def _paint_anvil_hammer(draw, seed):
	r = _rand(seed)
	cx, cy = W // 2, W // 2

	# Anvil body — classic London-pattern silhouette: top face, waist, base block.
	# Iron-grey core with darker shading underneath; sits in lower half of disc
	# so the crossed hammer above clears the rim.
	top_y = cy - int(W * 0.04)
	top_w = int(W * 0.46)
	top_h = int(W * 0.07)
	waist_w = int(W * 0.14)
	waist_h = int(W * 0.10)
	base_w = int(W * 0.32)
	base_h = int(W * 0.10)

	# Top face (with a curved horn on the right per traditional anvil shape).
	horn_w = int(W * 0.14)
	top_pts = [
		(cx - top_w // 2, top_y),
		(cx + top_w // 2, top_y),
		(cx + top_w // 2 + horn_w, top_y + top_h // 2),
		(cx + top_w // 2, top_y + top_h),
		(cx - top_w // 2, top_y + top_h),
	]
	col = (60, 64, 72, 250)
	draw.polygon(top_pts, fill=col)

	# Highlight strip along the upper edge of the anvil face — hammered metal sheen.
	col = (170, 178, 188, 220)
	draw.line(
		(cx - top_w // 2 + 8, top_y + 6, cx + top_w // 2 - 8, top_y + 6),
		fill=col,
		width=4,
	)

	# Waist (narrowing column under the face).
	waist_y = top_y + top_h
	col = (50, 54, 62, 250)
	draw.polygon(
		[
			(cx - top_w // 4, waist_y),
			(cx + top_w // 4, waist_y),
			(cx + waist_w // 2, waist_y + waist_h),
			(cx - waist_w // 2, waist_y + waist_h),
		],
		fill=col,
	)

	# Base block (heavy plinth).
	base_y = waist_y + waist_h
	col = (44, 48, 54, 250)
	draw.rectangle(
		(cx - base_w // 2, base_y, cx + base_w // 2, base_y + base_h),
		fill=col,
	)
	# Base-shadow cast onto the disc (slight darken under the anvil).
	col = (20, 16, 14, 90)
	draw.ellipse(
		(cx - int(base_w * 0.6), base_y + base_h - 4,
		 cx + int(base_w * 0.6), base_y + base_h + 12),
		fill=col,
	)

	# Hammered-metal pock-marks on the anvil face — soft circular dabs.
	for _ in range(28):
		x = cx + r.randint(-top_w // 2 + 10, top_w // 2 - 10)
		y = top_y + r.randint(4, top_h - 4)
		col = (90, 96, 104, r.randint(100, 170))
		draw.ellipse((x - 3, y - 3, x + 3, y + 3), fill=col)

	# Crossed hammer above the anvil — short-handled smith's hammer angled down-left
	# so its head meets the anvil face. Painted in two passes (handle, head) so
	# brass-banded head reads against the brown haft.
	handle_len = int(W * 0.42)
	handle_ang = math.radians(-30)  # pointing up-right from grip to head
	grip_x = cx - int(math.cos(handle_ang) * handle_len * 0.55)
	grip_y = cy + int(math.sin(handle_ang) * handle_len * 0.55) + int(W * 0.02)
	head_x = cx + int(math.cos(handle_ang) * handle_len * 0.45)
	head_y = cy - int(math.sin(handle_ang) * handle_len * 0.45) - int(W * 0.10)

	# Handle (oak haft) — series of soft brown blobs with grain shading.
	for i in range(34):
		t = i / 34.0
		x = int(grip_x + (head_x - grip_x) * t)
		y = int(grip_y + (head_y - grip_y) * t)
		thickness = int(7 * (0.55 + 0.45 * math.sin(t * math.pi)))
		col = (BEAR_BROWN[0], BEAR_BROWN[1], BEAR_BROWN[2], 240)
		draw.ellipse((x - thickness, y - thickness, x + thickness, y + thickness), fill=col)
	# Grip wrap (leather binding) at the bottom — three darker bands.
	for band in range(3):
		t = 0.06 + band * 0.07
		x = int(grip_x + (head_x - grip_x) * t)
		y = int(grip_y + (head_y - grip_y) * t)
		col = (40, 26, 18, 230)
		draw.ellipse((x - 8, y - 8, x + 8, y + 8), fill=col)

	# Hammer head — broad block of dark iron with brass-band collar where head
	# meets the haft, plus a brighter top edge to read as forged steel.
	head_w = int(W * 0.16)
	head_h = int(W * 0.10)
	perp = handle_ang + math.pi / 2
	def _rotated_rect(rx, ry, rw, rh, ang):
		hx = rw / 2.0
		hy = rh / 2.0
		corners = [(-hx, -hy), (hx, -hy), (hx, hy), (-hx, hy)]
		out = []
		for (px, py) in corners:
			nx = math.cos(ang) * px - math.sin(ang) * py
			ny = math.sin(ang) * px + math.cos(ang) * py
			out.append((rx + nx, ry + ny))
		return out
	head_pts = _rotated_rect(head_x, head_y, head_w, head_h, handle_ang)
	col = (54, 58, 66, 250)
	draw.polygon(head_pts, fill=col)
	# Brass collar where head joins haft.
	collar_x = head_x - int(math.cos(handle_ang) * head_w * 0.45)
	collar_y = head_y + int(math.sin(handle_ang) * head_w * 0.45)
	collar_pts = _rotated_rect(collar_x, collar_y, head_w * 0.18, head_h * 1.05, handle_ang)
	col = (BRASS[0], BRASS[1], BRASS[2], 250)
	draw.polygon(collar_pts, fill=col)
	# Forged-steel top edge highlight on hammer head.
	hi_pts = _rotated_rect(head_x, head_y - head_h * 0.30, head_w * 0.85, 3, handle_ang)
	col = (180, 188, 198, 220)
	draw.polygon(hi_pts, fill=col)

	# Sparks — bright ember dabs radiating outward from impact point on the
	# anvil face just below the hammer head. Placed asymmetrically with random
	# scatter so the painterly forge moment reads as a single instant.
	impact_x = cx - int(W * 0.04)
	impact_y = top_y + 2
	for _ in range(22):
		ang = r.uniform(-math.pi * 0.85, -math.pi * 0.15)  # upper hemisphere
		rr = r.uniform(W * 0.02, W * 0.18)
		x = impact_x + int(math.cos(ang) * rr)
		y = impact_y + int(math.sin(ang) * rr)
		size = r.randint(2, 5)
		# Hot core (bright sunset gold) over a wider amber halo.
		col = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], r.randint(80, 140))
		draw.ellipse((x - size * 2, y - size * 2, x + size * 2, y + size * 2), fill=col)
		col = (255, 230, 160, r.randint(200, 250))
		draw.ellipse((x - size, y - size, x + size, y + size), fill=col)
	# A single bigger glow dab at the actual impact point — anchors the eye.
	col = (255, 200, 80, 220)
	draw.ellipse((impact_x - 14, impact_y - 14, impact_x + 14, impact_y + 14), fill=col)
	col = (255, 240, 200, 250)
	draw.ellipse((impact_x - 6, impact_y - 6, impact_x + 6, impact_y + 6), fill=col)



def _paint_wolf_profile_three_stars(draw, seed):
	"""Wolf head in left-facing profile under three sunset-gold stars
	in a constellation arc — for `wolf_tamer` ("Tamer of the Wolfwoods").

	Visually distinct from `pack_thinner` (frontal head, frost-cyan eye):
	side profile reads as calm / kept-promise. The three stars stand in
	for Lyra / Roan / Hala — the three NPCs whose trust unlocks the
	title.
	"""
	r = _rand(seed)
	cx, cy = W // 2, W // 2

	# Stars first so the head can overlap them slightly.
	star_centers = [
		(cx - int(W * 0.24), cy - int(W * 0.30)),  # Lyra
		(cx,                cy - int(W * 0.36)),   # Roan
		(cx + int(W * 0.24), cy - int(W * 0.30)),  # Hala
	]
	for (sx, sy) in star_centers:
		for k in range(7, 0, -1):
			col = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], int(45 * k / 7))
			draw.ellipse((sx - 3 * k, sy - 3 * k, sx + 3 * k, sy + 3 * k), fill=col)
		col = (255, 240, 200, 250)
		draw.ellipse((sx - 5, sy - 5, sx + 5, sy + 5), fill=col)
		flare = 13
		col = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], 230)
		draw.line((sx - flare, sy, sx + flare, sy), fill=col, width=3)
		draw.line((sx, sy - flare, sx, sy + flare), fill=col, width=3)

	hx = cx + int(W * 0.04)
	hy = cy + int(W * 0.04)
	pts = [
		(hx + int(W * 0.16), hy - int(W * 0.18)),
		(hx + int(W * 0.20), hy - int(W * 0.30)),
		(hx + int(W * 0.24), hy - int(W * 0.16)),
		(hx + int(W * 0.10), hy - int(W * 0.14)),
		(hx + int(W * 0.06), hy - int(W * 0.28)),
		(hx - int(W * 0.02), hy - int(W * 0.14)),
		(hx - int(W * 0.10), hy - int(W * 0.16)),
		(hx - int(W * 0.18), hy - int(W * 0.12)),
		(hx - int(W * 0.26), hy - int(W * 0.04)),
		(hx - int(W * 0.34), hy + int(W * 0.02)),
		(hx - int(W * 0.36), hy + int(W * 0.06)),
		(hx - int(W * 0.32), hy + int(W * 0.10)),
		(hx - int(W * 0.24), hy + int(W * 0.10)),
		(hx - int(W * 0.16), hy + int(W * 0.16)),
		(hx - int(W * 0.06), hy + int(W * 0.20)),
		(hx + int(W * 0.04), hy + int(W * 0.24)),
		(hx + int(W * 0.14), hy + int(W * 0.22)),
		(hx + int(W * 0.22), hy + int(W * 0.06)),
		(hx + int(W * 0.20), hy - int(W * 0.06)),
	]
	col = (INK[0], INK[1], INK[2], 245)
	draw.polygon(pts, fill=col)

	inner_ear_pts = [
		(hx + int(W * 0.20), hy - int(W * 0.27)),
		(hx + int(W * 0.22), hy - int(W * 0.18)),
		(hx + int(W * 0.18), hy - int(W * 0.18)),
	]
	col = (90, 60, 40, 200)
	draw.polygon(inner_ear_pts, fill=col)

	for _ in range(40):
		ang = r.uniform(0, math.tau)
		rx = r.uniform(W * 0.12, W * 0.24)
		ry = r.uniform(W * 0.10, W * 0.22)
		x = hx + int(math.cos(ang) * rx)
		y = hy + int(math.sin(ang) * ry)
		col = (60, 70, 80, r.randint(40, 90))
		draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=col)

	hl_pts = [
		(hx + int(W * 0.16), hy - int(W * 0.16)),
		(hx + int(W * 0.10), hy - int(W * 0.10)),
		(hx + int(W * 0.20), hy + int(W * 0.06)),
	]
	for (x, y) in hl_pts:
		for k in range(5, 0, -1):
			col = (SILVER[0], SILVER[1], SILVER[2], int(55 * k / 5))
			draw.ellipse((x - 5 * k, y - 2 * k, x + 5 * k, y + 2 * k), fill=col)

	eye_x, eye_y = hx - int(W * 0.10), hy - int(W * 0.04)
	for i in range(4, 0, -1):
		col = (MOSS_LT[0], MOSS_LT[1], MOSS_LT[2], int(80 * i / 4))
		draw.ellipse((eye_x - 3 * i, eye_y - 3 * i, eye_x + 3 * i, eye_y + 3 * i), fill=col)
	col = (235, 240, 220, 240)
	draw.ellipse((eye_x - 5, eye_y - 4, eye_x + 5, eye_y + 4), fill=col)
	col = (INK[0], INK[1], INK[2], 240)
	draw.ellipse((eye_x - 2, eye_y - 2, eye_x + 2, eye_y + 2), fill=col)

	nose_x, nose_y = hx - int(W * 0.33), hy + int(W * 0.05)
	col = (40, 38, 42, 240)
	draw.ellipse((nose_x - 6, nose_y - 4, nose_x + 6, nose_y + 4), fill=col)
	col = (SILVER[0], SILVER[1], SILVER[2], 200)
	draw.ellipse((nose_x - 2, nose_y - 3, nose_x + 1, nose_y - 1), fill=col)



def _paint_road_warden(draw, seed):
	"""Heraldic shield with a winding road across its lower half, a small
	watchtower silhouette on the road's horizon, and a low sunrise behind.

	For `road_warden` ("Warden of the South Road") — bandit-clear beat. Visually
	distinct from `realm_warden` (whole keep + banner): this is a SHIELD with
	a road on it, not a building. THEME §3 palette: stone-blue shield body,
	brass rim, sunset-gold sun, parchment road.
	"""
	r = _rand(seed)
	cx, cy = W // 2, W // 2

	# Shield silhouette — heater-shape, narrow at top, pointed at bottom.
	st = int(W * 0.34)  # half-width at top
	sb = int(W * 0.04)  # half-width at point
	top_y = cy - int(W * 0.30)
	mid_y = cy + int(W * 0.05)
	bot_y = cy + int(W * 0.30)
	shield_pts = [
		(cx - st, top_y),
		(cx + st, top_y),
		(cx + st, mid_y - int(W * 0.04)),
		(cx + int(st * 0.85), mid_y + int(W * 0.04)),
		(cx + int(W * 0.20), mid_y + int(W * 0.16)),
		(cx + sb, bot_y),
		(cx - sb, bot_y),
		(cx - int(W * 0.20), mid_y + int(W * 0.16)),
		(cx - int(st * 0.85), mid_y + int(W * 0.04)),
		(cx - st, mid_y - int(W * 0.04)),
	]
	# Shield body — stone-blue base
	col = (STONE_BLUE[0], STONE_BLUE[1], STONE_BLUE[2], 248)
	draw.polygon(shield_pts, fill=col)

	# Painted-rim brass border around shield
	for k in range(0, len(shield_pts)):
		x0, y0 = shield_pts[k]
		x1, y1 = shield_pts[(k + 1) % len(shield_pts)]
		segs = 14
		for i in range(segs):
			t0 = i / segs
			t1 = (i + 1) / segs
			ax = int(x0 + (x1 - x0) * t0)
			ay = int(y0 + (y1 - y0) * t0)
			bx = int(x0 + (x1 - x0) * t1)
			by = int(y0 + (y1 - y0) * t1)
			col = (BRASS[0], BRASS[1], BRASS[2], r.randint(190, 240))
			draw.line((ax, ay, bx, by), fill=col, width=r.randint(5, 7))

	# Horizontal divider / fess line splitting upper "sky" half from lower "road" half
	fess_y = cy - int(W * 0.02)
	col = (BRASS[0], BRASS[1], BRASS[2], 220)
	draw.line((cx - int(st * 0.92), fess_y, cx + int(st * 0.92), fess_y), fill=col, width=4)

	# Upper half: a low sunrise — sunset-gold sun on a wine-deep dawn band
	# Dawn band stripe (thin)
	col = (CRIMSON[0], CRIMSON[1], CRIMSON[2], 100)
	draw.rectangle(
		(cx - int(st * 0.85), fess_y - int(W * 0.07),
		 cx + int(st * 0.85), fess_y - int(W * 0.01)),
		fill=col,
	)
	# Sun disc — half-emerged behind the fess line
	sun_y = fess_y - int(W * 0.03)
	for k in range(8, 0, -1):
		col = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], int(55 * k / 8))
		rr = int(W * 0.10) + 3 * k
		draw.ellipse((cx - rr, sun_y - rr, cx + rr, sun_y + rr), fill=col)
	col = (255, 230, 160, 240)
	draw.ellipse(
		(cx - int(W * 0.09), sun_y - int(W * 0.09),
		 cx + int(W * 0.09), sun_y + int(W * 0.09)),
		fill=col,
	)
	# Sun rays — short stubs above the fess
	for ang_deg in (-50, -30, -10, 10, 30, 50):
		ang = math.radians(ang_deg - 90)
		x0 = cx + int(math.cos(ang) * W * 0.10)
		y0 = sun_y + int(math.sin(ang) * W * 0.10)
		x1 = cx + int(math.cos(ang) * W * 0.16)
		y1 = sun_y + int(math.sin(ang) * W * 0.16)
		col = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], 220)
		draw.line((x0, y0, x1, y1), fill=col, width=4)

	# Lower half: a winding parchment-coloured road from bottom-left to right
	# Road as a series of broad blob brushstrokes for a hand-painted feel
	road_pts = [
		(cx - int(st * 0.78), bot_y - int(W * 0.05)),
		(cx - int(st * 0.40), bot_y - int(W * 0.08)),
		(cx - int(st * 0.10), bot_y - int(W * 0.14)),
		(cx + int(st * 0.20), bot_y - int(W * 0.18)),
		(cx + int(st * 0.55), bot_y - int(W * 0.22)),
	]
	prev = road_pts[0]
	for p in road_pts[1:]:
		segs = 18
		for i in range(segs):
			t = i / segs
			x = int(prev[0] + (p[0] - prev[0]) * t)
			y = int(prev[1] + (p[1] - prev[1]) * t)
			# Cross-section width tapers with t
			w_t = 16 - int(2 * math.sin(t * math.pi))
			col = (PARCHMENT[0], PARCHMENT[1], PARCHMENT[2], 230)
			draw.ellipse((x - w_t, y - 6, x + w_t, y + 6), fill=col)
			# Earthy edge wash
			col = (BEAR_BROWN[0], BEAR_BROWN[1], BEAR_BROWN[2], 110)
			draw.ellipse((x - w_t - 3, y - 8, x + w_t + 3, y + 9), fill=col)
		prev = p

	# Watchtower silhouette on the road's far horizon (right side, near the sun)
	tw_x = cx + int(st * 0.45)
	tw_base_y = bot_y - int(W * 0.20)
	tw_top_y = tw_base_y - int(W * 0.12)
	# Tower body (narrow rectangle)
	col = (40, 36, 32, 235)
	draw.rectangle(
		(tw_x - int(W * 0.025), tw_top_y, tw_x + int(W * 0.025), tw_base_y),
		fill=col,
	)
	# Crenellations
	for i in (-1, 0, 1):
		bx = tw_x + i * int(W * 0.025)
		col = (40, 36, 32, 235)
		draw.rectangle((bx - 2, tw_top_y - int(W * 0.025), bx + 2, tw_top_y), fill=col)
	# Tiny pole + pennant
	col = (BRASS[0], BRASS[1], BRASS[2], 230)
	draw.line((tw_x, tw_top_y - int(W * 0.025), tw_x, tw_top_y - int(W * 0.07)), fill=col, width=2)
	pen_pts = [
		(tw_x, tw_top_y - int(W * 0.07)),
		(tw_x + int(W * 0.04), tw_top_y - int(W * 0.05)),
		(tw_x, tw_top_y - int(W * 0.04)),
	]
	col = (CRIMSON[0], CRIMSON[1], CRIMSON[2], 235)
	draw.polygon(pen_pts, fill=col)

	# Painterly weathering dabs across the shield body
	for _ in range(50):
		x = cx + r.randint(-st + 4, st - 4)
		y = top_y + r.randint(8, bot_y - top_y - 8)
		col = (50, 60, 75, r.randint(40, 95))
		draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=col)


def _paint_seal_keeper(draw, seed):
	"""Captain's iron seal-stamp hung from a leather thong, with a vigil
	candle-flame glowing behind it.

	For `seal_keeper` ("Keeper of the Captain's Seal") — Maeve's-mantle beat.
	Visually distinct from `road_warden` (heraldic shield + road): this is a
	hand-held keepsake / vigil. Iron-grey seal disc with a brass collar and
	a small heraldic mark stamped on the face; sunset-gold candle-flame
	halo behind the disc anchors the "vigil candle" emoji legacy fallback.
	"""
	r = _rand(seed)
	cx, cy = W // 2, W // 2

	# Vigil flame halo behind the seal — soft sunset-gold glow that reads
	# as candlelight even at 32px. Painted FIRST so the seal disc sits over it.
	flame_x, flame_y = cx, cy - int(W * 0.02)
	for k in range(14, 0, -1):
		col = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], int(35 * k / 14))
		rr = int(W * 0.06) + 4 * k
		draw.ellipse(
			(flame_x - rr, flame_y - int(rr * 1.15),
			 flame_x + rr, flame_y + int(rr * 0.85)),
			fill=col,
		)
	# Bright flame core (visible above the seal)
	flame_top_y = cy - int(W * 0.30)
	flame_pts = [
		(cx, flame_top_y),
		(cx + int(W * 0.05), flame_top_y + int(W * 0.10)),
		(cx + int(W * 0.03), flame_top_y + int(W * 0.18)),
		(cx, flame_top_y + int(W * 0.20)),
		(cx - int(W * 0.03), flame_top_y + int(W * 0.18)),
		(cx - int(W * 0.05), flame_top_y + int(W * 0.10)),
	]
	col = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], 220)
	draw.polygon(flame_pts, fill=col)
	# Flame inner-bright
	inner_pts = [
		(cx, flame_top_y + int(W * 0.02)),
		(cx + int(W * 0.025), flame_top_y + int(W * 0.10)),
		(cx, flame_top_y + int(W * 0.16)),
		(cx - int(W * 0.025), flame_top_y + int(W * 0.10)),
	]
	col = (255, 240, 200, 245)
	draw.polygon(inner_pts, fill=col)
	# Flame brightest tip — single dab
	col = (255, 250, 230, 250)
	draw.ellipse(
		(cx - 5, flame_top_y + int(W * 0.06) - 5,
		 cx + 5, flame_top_y + int(W * 0.06) + 5),
		fill=col,
	)

	# Leather thong — two angled lines that hang from the top of the disc
	# meeting at a small loop near the upper rim of the crest.
	loop_x, loop_y = cx, cy - int(W * 0.34)
	# Left thong
	col = (BEAR_BROWN[0], BEAR_BROWN[1], BEAR_BROWN[2], 230)
	draw.line(
		(loop_x - int(W * 0.04), loop_y + 4, cx - int(W * 0.10), cy - int(W * 0.10)),
		fill=col,
		width=5,
	)
	# Right thong
	draw.line(
		(loop_x + int(W * 0.04), loop_y + 4, cx + int(W * 0.10), cy - int(W * 0.10)),
		fill=col,
		width=5,
	)
	# Small thong loop
	col = (40, 26, 18, 220)
	draw.ellipse(
		(loop_x - int(W * 0.04), loop_y - int(W * 0.04),
		 loop_x + int(W * 0.04), loop_y + int(W * 0.02)),
		fill=col,
	)

	# Iron seal disc — sits in lower 60% of the crest
	disc_x, disc_y = cx, cy + int(W * 0.10)
	disc_r = int(W * 0.20)
	# Outer brass collar (slightly larger ring behind the iron disc)
	for k in range(5, 0, -1):
		col = (BRASS[0], BRASS[1], BRASS[2], int(60 + 35 * k / 5))
		rr = disc_r + 4 + k
		draw.ellipse(
			(disc_x - rr, disc_y - rr, disc_x + rr, disc_y + rr),
			fill=col,
		)
	# Iron disc body (dark cast iron)
	for k in range(disc_r, 0, -2):
		t = k / disc_r
		# Slightly lighter at the top-left to suggest light from the candle
		col = (
			int(54 + 40 * (1 - t)),
			int(58 + 40 * (1 - t)),
			int(66 + 40 * (1 - t)),
			248,
		)
		draw.ellipse(
			(disc_x - k, disc_y - k, disc_x + k, disc_y + k),
			fill=col,
		)
	# Hammered-metal pock-marks on the seal face
	for _ in range(40):
		ang = r.uniform(0, math.tau)
		rr = int(disc_r * r.uniform(0.10, 0.85))
		x = disc_x + int(math.cos(ang) * rr)
		y = disc_y + int(math.sin(ang) * rr)
		col = (90, 96, 104, r.randint(70, 140))
		draw.ellipse((x - 3, y - 3, x + 3, y + 3), fill=col)

	# Heraldic mark stamped into the seal: a six-pointed sigil-star with
	# a small dot in the centre, the southroad-watch emblem.
	cx2, cy2 = disc_x, disc_y
	mark_r = int(disc_r * 0.50)
	star_pts = []
	for i in range(12):
		ang = -math.pi / 2 + i * math.pi / 6
		rr = mark_r if i % 2 == 0 else int(mark_r * 0.45)
		star_pts.append((cx2 + int(math.cos(ang) * rr), cy2 + int(math.sin(ang) * rr)))
	col = (BRASS_LT[0], BRASS_LT[1], BRASS_LT[2], 240)
	draw.polygon(star_pts, fill=col)
	# Inner shadow stamp
	col = (60, 50, 30, 180)
	for i in range(12):
		ang = -math.pi / 2 + i * math.pi / 6
		rr = mark_r if i % 2 == 0 else int(mark_r * 0.45)
		x = cx2 + int(math.cos(ang) * rr)
		y = cy2 + int(math.sin(ang) * rr)
		draw.ellipse((x - 2, y - 2, x + 2, y + 2), fill=col)
	# Center mark — small sunset-gold dot (the "kept" point)
	col = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], 245)
	draw.ellipse((cx2 - 4, cy2 - 4, cx2 + 4, cy2 + 4), fill=col)
	col = (255, 230, 160, 250)
	draw.ellipse((cx2 - 2, cy2 - 2, cx2 + 2, cy2 + 2), fill=col)

	# Subtle highlight crescent on the disc — light from the candle above
	for k in range(8, 0, -1):
		col = (SILVER[0], SILVER[1], SILVER[2], int(28 * k / 8))
		hx = disc_x - int(disc_r * 0.30)
		hy = disc_y - int(disc_r * 0.55)
		rr = 5 + k
		draw.ellipse((hx - rr, hy - rr, hx + rr, hy + rr), fill=col)




CRESTS = {
	"first_steps":   {"seed": 9101, "base_dark": (60, 90, 45, 255),  "base_light": MOSS_LT,              "rim": BRASS,             "painter": _paint_sprout},
	"pack_thinner":  {"seed": 9102, "base_dark": (50, 60, 70, 255),  "base_light": (130, 145, 160, 255), "rim": SILVER,            "painter": _paint_wolf_head},
	"goblin_bane":   {"seed": 9103, "base_dark": WINE,                "base_light": (180, 60, 50, 255),  "rim": BRASS,             "painter": _paint_crossed_swords},
	"trusted_three": {"seed": 9104, "base_dark": PARCHMENT_DK,        "base_light": PARCHMENT,           "rim": (110, 80, 30, 255),"painter": _paint_three_rings},
	"realm_warden":  {"seed": 9105, "base_dark": SUNSET_DK,           "base_light": SUNSET_GOLD,         "rim": (110, 60, 20, 255),"painter": _paint_keep},
	"first_forge":   {"seed": 9106, "base_dark": (90, 40, 18, 255),  "base_light": (200, 110, 50, 255), "rim": BRASS,            "painter": _paint_anvil_hammer},
	"wolf_tamer":    {"seed": 9107, "base_dark": MOSS_DK,             "base_light": MOSS_LT,             "rim": BRASS,            "painter": _paint_wolf_profile_three_stars},
	# Run 25+ — Roan / Maeve south-road sequence crests.
	# road_warden disc: stone-blue base, brass rim — duty / road-watch tones.
	# seal_keeper disc: parchment base, dark wine rim — Maeve's mantle / kept-vigil.
	"road_warden":   {"seed": 9108, "base_dark": (60, 70, 88, 255),  "base_light": STONE_BLUE,          "rim": BRASS,            "painter": _paint_road_warden},
	"seal_keeper":   {"seed": 9109, "base_dark": PARCHMENT_DK,        "base_light": PARCHMENT,           "rim": (110, 50, 40, 255),"painter": _paint_seal_keeper},
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
