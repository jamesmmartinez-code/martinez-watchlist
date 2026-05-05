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



CRESTS = {
	"first_steps":   {"seed": 9101, "base_dark": (60, 90, 45, 255),  "base_light": MOSS_LT,              "rim": BRASS,             "painter": _paint_sprout},
	"pack_thinner":  {"seed": 9102, "base_dark": (50, 60, 70, 255),  "base_light": (130, 145, 160, 255), "rim": SILVER,            "painter": _paint_wolf_head},
	"goblin_bane":   {"seed": 9103, "base_dark": WINE,                "base_light": (180, 60, 50, 255),  "rim": BRASS,             "painter": _paint_crossed_swords},
	"trusted_three": {"seed": 9104, "base_dark": PARCHMENT_DK,        "base_light": PARCHMENT,           "rim": (110, 80, 30, 255),"painter": _paint_three_rings},
	"realm_warden":  {"seed": 9105, "base_dark": SUNSET_DK,           "base_light": SUNSET_GOLD,         "rim": (110, 60, 20, 255),"painter": _paint_keep},
	"first_forge":   {"seed": 9106, "base_dark": (90, 40, 18, 255),  "base_light": (200, 110, 50, 255), "rim": BRASS,            "painter": _paint_anvil_hammer},
	"wolf_tamer":    {"seed": 9107, "base_dark": MOSS_DK,             "base_light": MOSS_LT,             "rim": BRASS,            "painter": _paint_wolf_profile_three_stars},
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
