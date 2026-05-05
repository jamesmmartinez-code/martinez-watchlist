#!/usr/bin/env python3
"""
Realm of Eldoria — procedural enemy bestiary portrait generator.

Produces 8 painterly 256x256 PNG bust portraits, one per enemy archetype
in THEME.md S4. Each portrait is a hand-painted-feel silhouette with
themed palette, ready for use in dialogue panels, codex entries, loot
toasts, or boss-intro splashes.

Style targets (THEME.md):
  - S1 painterly, hand-painted concept-art aesthetic; warm, weathered.
    Studio Ghibli + WoW Classic concept art. NOT cute, NOT cartoony.
  - S3 palette compliance — sunset gold / wine / moss / parchment
    dominant; magic accents (fey-cyan, frost-silver, arcane purple)
    used sparingly. No neon, no fluorescent, no pure white.
  - S4 silhouette-distinct — every enemy must read at 30m. Each portrait
    leans into its silhouette band (small/hunched/horned/long-snouted/
    skull-shaped/jagged/cloak-and-hood) so codex thumbnails are legible.
  - S5 hand-painted look, not crisp vector. Soft brushstroke rim,
    Gaussian-softened edges. Painterly background gradient per enemy.

Output: 8 RGBA PNGs at 256x256, transparent rounded-rect background.

Slugs (mirror Enemy / Boss kinds + THEME S4 planned roster):
  - goblin_grunt        feral small green raider with bone fetish
  - goblin_brute        scarred helmed bigger goblin with axe
  - goblin_warlord      boss - gold crown, war banner, red aura
  - dire_wolf           gaunt grey-brown wolf with frost-yellow eyes
  - skeleton_warrior    bleached skull + burial wraps + rusted helm
  - crystal_elemental   crystal humanoid, blue glow, jagged shards
  - crystal_guardian    boss - larger blue-violet crystal silhouette
  - bandit_hooded       hooded human, scarf, charcoal/wine palette

License: CC0 - generated procedurally with Pillow, no external assets,
no trademark or third-party reference material was used.

Run: python3 gen_enemy_portraits.py <out_dir>
"""
from __future__ import annotations
import math, os, random, sys
from PIL import Image, ImageDraw, ImageFilter

SIZE = 256
SUPER = 4
W = SIZE * SUPER

# THEME.md S3 palette
PARCHMENT    = (217, 201, 155, 255)
PARCHMENT_DK = (170, 150, 110, 255)
INK          = (14, 10, 14, 255)
INK_LT       = (40, 32, 36, 255)
SUNSET_GOLD  = (255, 200, 80, 255)
SUNSET_DK    = (200, 130, 50, 255)
CRIMSON      = (140, 32, 32, 255)
WINE         = (110, 24, 24, 255)
MOSS         = (74, 112, 56, 255)
MOSS_DK      = (50, 76, 38, 255)
MOSS_LT      = (120, 160, 90, 255)
BRASS        = (176, 116, 42, 255)
BRASS_LT     = (210, 160, 90, 255)
FROST_CYAN   = (101, 223, 229, 255)
SILVER       = (200, 224, 229, 255)
ARCANE       = (124, 63, 176, 255)
GOBLIN_GREEN = (96, 130, 60, 255)
GOBLIN_DK    = (60, 84, 38, 255)
GOBLIN_LT    = (140, 170, 90, 255)
WOLF_GREY    = (130, 122, 110, 255)
WOLF_DK      = (70, 62, 54, 255)
BONE_PALE    = (228, 218, 188, 255)
BONE_DK      = (160, 148, 118, 255)
STONE_BLUE   = (123, 134, 147, 255)
STAG_BLOOD   = (160, 32, 32, 255)
SKIN_HUMAN   = (190, 150, 110, 255)
LEATHER_DK   = (60, 42, 28, 255)
LEATHER_LT   = (120, 86, 52, 255)


def _rand(seed):
	return random.Random(seed)


def _paint_bg_gradient(draw, top, bottom, seed):
	r = _rand(seed)
	for y in range(W):
		t = y / W
		col = (
			int(top[0] * (1 - t) + bottom[0] * t),
			int(top[1] * (1 - t) + bottom[1] * t),
			int(top[2] * (1 - t) + bottom[2] * t),
			255,
		)
		draw.line((0, y, W, y), fill=col)
	for _ in range(420):
		x = r.randint(0, W - 1)
		y = r.randint(0, W - 1)
		s = r.randint(6, 14)
		jitter = r.randint(-25, 25)
		base = top if y < W // 2 else bottom
		col = (
			max(0, min(255, base[0] + jitter)),
			max(0, min(255, base[1] + jitter)),
			max(0, min(255, base[2] + jitter)),
			r.randint(40, 110),
		)
		draw.ellipse((x - s, y - s, x + s, y + s), fill=col)


def _draw_painter_blob(draw, points, fill, jitter_seed, blob_r=18):
	r = _rand(jitter_seed)
	draw.polygon(points, fill=fill)
	for i in range(len(points)):
		x0, y0 = points[i]
		x1, y1 = points[(i + 1) % len(points)]
		segs = max(8, int(math.hypot(x1 - x0, y1 - y0) / 18))
		for s in range(segs):
			t = s / segs
			x = int(x0 + (x1 - x0) * t)
			y = int(y0 + (y1 - y0) * t)
			rr = r.randint(blob_r // 3, blob_r)
			alpha = r.randint(140, 230)
			col = (fill[0], fill[1], fill[2], alpha)
			draw.ellipse((x - rr, y - rr, x + rr, y + rr), fill=col)


def _paint_goblin_grunt(draw, seed):
	r = _rand(seed)
	cx = W // 2
	shoulder_pts = [
		(int(W * 0.18), int(W * 0.95)), (int(W * 0.22), int(W * 0.78)),
		(int(W * 0.30), int(W * 0.70)), (int(W * 0.40), int(W * 0.66)),
		(int(W * 0.60), int(W * 0.66)), (int(W * 0.72), int(W * 0.72)),
		(int(W * 0.80), int(W * 0.80)), (int(W * 0.84), int(W * 0.95)),
	]
	_draw_painter_blob(draw, shoulder_pts, GOBLIN_DK, seed + 1, blob_r=22)
	for k in range(8):
		x = int(W * (0.32 + k * 0.05))
		col = (LEATHER_DK[0], LEATHER_DK[1], LEATHER_DK[2], 200)
		draw.rectangle((x, int(W * 0.74), x + 10, int(W * 0.78)), fill=col)
	head_w, head_h = int(W * 0.30), int(W * 0.32)
	hx, hy = cx, int(W * 0.38)
	head_pts = []
	for k in range(36):
		ang = (k / 36.0) * math.tau
		jitter = r.uniform(-0.04, 0.04)
		rx = head_w * (1.0 + jitter * 0.3)
		ry = head_h * (1.0 + jitter * 0.3)
		head_pts.append((int(hx + math.cos(ang) * rx * 0.5), int(hy + math.sin(ang) * ry * 0.5)))
	_draw_painter_blob(draw, head_pts, GOBLIN_GREEN, seed + 2, blob_r=20)
	for sgn in (-1, 1):
		ear_pts = [
			(int(hx + sgn * head_w * 0.45), int(hy - head_h * 0.10)),
			(int(hx + sgn * head_w * 0.85), int(hy - head_h * 0.40)),
			(int(hx + sgn * head_w * 0.42), int(hy + head_h * 0.05)),
		]
		_draw_painter_blob(draw, ear_pts, GOBLIN_DK, seed + 3 + sgn, blob_r=10)
	for ex_off in (-0.10, 0.10):
		ex = int(hx + head_w * ex_off)
		ey = int(hy - head_h * 0.05)
		col = (INK[0], INK[1], INK[2], 220)
		draw.ellipse((ex - 14, ey - 10, ex + 14, ey + 10), fill=col)
		col = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], 240)
		draw.ellipse((ex - 8, ey - 6, ex + 8, ey + 6), fill=col)
		col = (INK[0], INK[1], INK[2], 255)
		draw.ellipse((ex - 3, ey - 3, ex + 3, ey + 3), fill=col)
	col = (GOBLIN_DK[0], GOBLIN_DK[1], GOBLIN_DK[2], 220)
	draw.ellipse((cx - 8, hy + int(head_h * 0.08), cx + 8, hy + int(head_h * 0.18)), fill=col)
	for k in range(5):
		tx = cx - 24 + k * 12
		ty = hy + int(head_h * 0.30)
		col = (BONE_PALE[0], BONE_PALE[1], BONE_PALE[2], 240)
		draw.polygon([(tx, ty), (tx + 6, ty), (tx + 3, ty + 12)], fill=col)
	for k in range(3):
		bx = cx - 28 + k * 28
		by = int(W * 0.72)
		col = (BONE_PALE[0], BONE_PALE[1], BONE_PALE[2], 240)
		draw.ellipse((bx - 8, by - 6, bx + 8, by + 6), fill=col)
		col = (INK[0], INK[1], INK[2], 100)
		draw.ellipse((bx - 4, by - 2, bx + 4, by + 2), fill=col)
	col = (BRASS[0], BRASS[1], BRASS[2], 230)
	draw.line((int(W * 0.74), int(W * 0.66), int(W * 0.86), int(W * 0.50)), fill=col, width=10)
	col = (LEATHER_DK[0], LEATHER_DK[1], LEATHER_DK[2], 230)
	draw.line((int(W * 0.72), int(W * 0.68), int(W * 0.76), int(W * 0.64)), fill=col, width=14)


def _paint_goblin_brute(draw, seed):
	r = _rand(seed)
	cx = W // 2
	shoulder_pts = [
		(int(W * 0.10), int(W * 0.96)), (int(W * 0.14), int(W * 0.74)),
		(int(W * 0.24), int(W * 0.66)), (int(W * 0.40), int(W * 0.62)),
		(int(W * 0.60), int(W * 0.62)), (int(W * 0.76), int(W * 0.66)),
		(int(W * 0.86), int(W * 0.74)), (int(W * 0.90), int(W * 0.96)),
	]
	_draw_painter_blob(draw, shoulder_pts, GOBLIN_DK, seed + 1, blob_r=24)
	for k in range(3):
		px = int(W * (0.18 + k * 0.05))
		py = int(W * 0.80)
		col = (BRASS[0], BRASS[1], BRASS[2], 230)
		draw.ellipse((px - 8, py - 8, px + 8, py + 8), fill=col)
	head_w, head_h = int(W * 0.34), int(W * 0.36)
	hx, hy = cx, int(W * 0.36)
	head_pts = []
	for k in range(36):
		ang = (k / 36.0) * math.tau
		jitter = r.uniform(-0.04, 0.04)
		rx = head_w * (1.0 + jitter * 0.3)
		ry = head_h * (1.0 + jitter * 0.3)
		head_pts.append((int(hx + math.cos(ang) * rx * 0.5), int(hy + math.sin(ang) * ry * 0.5)))
	_draw_painter_blob(draw, head_pts, GOBLIN_GREEN, seed + 2, blob_r=22)
	helm_pts = [
		(hx - int(head_w * 0.55), hy - int(head_h * 0.05)),
		(hx - int(head_w * 0.50), hy - int(head_h * 0.45)),
		(hx, hy - int(head_h * 0.55)),
		(hx + int(head_w * 0.50), hy - int(head_h * 0.45)),
		(hx + int(head_w * 0.55), hy - int(head_h * 0.05)),
	]
	_draw_painter_blob(draw, helm_pts, INK_LT, seed + 3, blob_r=18)
	for k in range(5):
		rx = hx - 50 + k * 25
		ry = hy - int(head_h * 0.18)
		col = (BRASS[0], BRASS[1], BRASS[2], 230)
		draw.ellipse((rx - 5, ry - 5, rx + 5, ry + 5), fill=col)
	ear_pts = [
		(int(hx + head_w * 0.50), int(hy + head_h * 0.05)),
		(int(hx + head_w * 0.78), int(hy - head_h * 0.10)),
		(int(hx + head_w * 0.50), int(hy + head_h * 0.18)),
	]
	_draw_painter_blob(draw, ear_pts, GOBLIN_DK, seed + 4, blob_r=10)
	for ex_off in (-0.12, 0.12):
		ex = int(hx + head_w * ex_off)
		ey = int(hy + head_h * 0.05)
		col = (INK[0], INK[1], INK[2], 220)
		draw.ellipse((ex - 14, ey - 10, ex + 14, ey + 10), fill=col)
		col = (CRIMSON[0], CRIMSON[1], CRIMSON[2], 240)
		draw.ellipse((ex - 8, ey - 6, ex + 8, ey + 6), fill=col)
		col = (INK[0], INK[1], INK[2], 255)
		draw.ellipse((ex - 3, ey - 3, ex + 3, ey + 3), fill=col)
	for tx_off in (-0.06, 0.06):
		tx = int(hx + head_w * tx_off)
		ty = int(hy + head_h * 0.30)
		col = (BONE_PALE[0], BONE_PALE[1], BONE_PALE[2], 240)
		if tx_off < 0:
			pts = [(tx - 8, ty), (tx, ty), (tx - 4, ty + 18)]
		else:
			pts = [(tx, ty), (tx + 8, ty), (tx + 4, ty + 18)]
		draw.polygon(pts, fill=col)
	col = (CRIMSON[0], CRIMSON[1], CRIMSON[2], 200)
	draw.line((hx - 50, hy + 10, hx - 20, hy + 35), fill=col, width=4)
	col = (LEATHER_LT[0], LEATHER_LT[1], LEATHER_LT[2], 240)
	draw.line((int(W * 0.16), int(W * 0.96), int(W * 0.04), int(W * 0.50)), fill=col, width=14)
	axe_cx, axe_cy = int(W * 0.05), int(W * 0.46)
	col = (STONE_BLUE[0], STONE_BLUE[1], STONE_BLUE[2], 240)
	draw.pieslice((axe_cx - 38, axe_cy - 38, axe_cx + 28, axe_cy + 28), start=200, end=340, fill=col)
	col = (BRASS[0], BRASS[1], BRASS[2], 200)
	draw.line((axe_cx - 30, axe_cy - 10, axe_cx + 22, axe_cy + 18), fill=col, width=6)


def _paint_goblin_warlord(draw, seed):
	r = _rand(seed)
	cx = W // 2
	for i in range(20, 0, -1):
		t = i / 20.0
		rr = int(W * 0.50 * t)
		col = (STAG_BLOOD[0], STAG_BLOOD[1], STAG_BLOOD[2], int(40 * t))
		draw.ellipse((cx - rr, int(W * 0.45) - rr, cx + rr, int(W * 0.45) + rr), fill=col)
	for side in (-1, 1):
		bx = cx + side * int(W * 0.34)
		col = (LEATHER_DK[0], LEATHER_DK[1], LEATHER_DK[2], 240)
		draw.rectangle((bx - 4, int(W * 0.10), bx + 4, int(W * 0.55)), fill=col)
		pts = [
			(bx, int(W * 0.16)),
			(bx + side * int(W * 0.18), int(W * 0.18)),
			(bx + side * int(W * 0.16), int(W * 0.40)),
			(bx + side * int(W * 0.10), int(W * 0.36)),
			(bx + side * int(W * 0.10), int(W * 0.46)),
			(bx, int(W * 0.42)),
		]
		_draw_painter_blob(draw, pts, WINE, seed + side, blob_r=14)
		mx, my = bx + side * int(W * 0.12), int(W * 0.30)
		col = (BONE_PALE[0], BONE_PALE[1], BONE_PALE[2], 240)
		draw.ellipse((mx - 14, my - 14, mx + 14, my + 8), fill=col)
		col = (INK[0], INK[1], INK[2], 240)
		draw.ellipse((mx - 6, my - 6, mx - 2, my - 2), fill=col)
		draw.ellipse((mx + 2, my - 6, mx + 6, my - 2), fill=col)
	shoulder_pts = [
		(int(W * 0.06), int(W * 0.98)), (int(W * 0.10), int(W * 0.70)),
		(int(W * 0.22), int(W * 0.60)), (int(W * 0.40), int(W * 0.58)),
		(int(W * 0.60), int(W * 0.58)), (int(W * 0.78), int(W * 0.60)),
		(int(W * 0.90), int(W * 0.70)), (int(W * 0.94), int(W * 0.98)),
	]
	_draw_painter_blob(draw, shoulder_pts, GOBLIN_DK, seed + 1, blob_r=26)
	for k in range(2):
		side = -1 if k == 0 else 1
		px = cx + side * int(W * 0.30)
		py = int(W * 0.66)
		col = (BRASS[0], BRASS[1], BRASS[2], 240)
		draw.ellipse((px - 24, py - 14, px + 24, py + 14), fill=col)
		col = (BRASS_LT[0], BRASS_LT[1], BRASS_LT[2], 230)
		draw.ellipse((px - 12, py - 8, px + 12, py + 8), fill=col)
	head_w, head_h = int(W * 0.38), int(W * 0.40)
	hx, hy = cx, int(W * 0.34)
	head_pts = []
	for k in range(36):
		ang = (k / 36.0) * math.tau
		jitter = r.uniform(-0.04, 0.04)
		rx = head_w * (1.0 + jitter * 0.3)
		ry = head_h * (1.0 + jitter * 0.3)
		head_pts.append((int(hx + math.cos(ang) * rx * 0.5), int(hy + math.sin(ang) * ry * 0.5)))
	_draw_painter_blob(draw, head_pts, GOBLIN_GREEN, seed + 2, blob_r=24)
	for k in range(3):
		col = (WINE[0], WINE[1], WINE[2], 200)
		x0 = hx - 60 + k * 40
		draw.line((x0, hy - 30, x0 + 30, hy + 20), fill=col, width=3)
	cy_crown = hy - int(head_h * 0.55)
	for k in range(5):
		t = k / 4.0
		px = hx - int(head_w * 0.45) + int(t * head_w * 0.90)
		py = cy_crown
		pts = [(px - 14, py + 20), (px, py - 26), (px + 14, py + 20)]
		col = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], 250)
		draw.polygon(pts, fill=col)
		col = (CRIMSON[0], CRIMSON[1], CRIMSON[2], 240)
		draw.ellipse((px - 4, py + 4, px + 4, py + 12), fill=col)
	col = (SUNSET_DK[0], SUNSET_DK[1], SUNSET_DK[2], 250)
	draw.rectangle((hx - int(head_w * 0.50), cy_crown + 18, hx + int(head_w * 0.50), cy_crown + 36), fill=col)
	for ex_off in (-0.13, 0.13):
		ex = int(hx + head_w * ex_off)
		ey = int(hy + head_h * 0.05)
		col = (INK[0], INK[1], INK[2], 230)
		draw.ellipse((ex - 16, ey - 12, ex + 16, ey + 12), fill=col)
		col = (STAG_BLOOD[0], STAG_BLOOD[1], STAG_BLOOD[2], 200)
		draw.ellipse((ex - 22, ey - 16, ex + 22, ey + 16), fill=col)
		col = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], 240)
		draw.ellipse((ex - 9, ey - 7, ex + 9, ey + 7), fill=col)
		col = (INK[0], INK[1], INK[2], 255)
		draw.ellipse((ex - 4, ey - 4, ex + 4, ey + 4), fill=col)
	for tx_off in (-0.10, 0.10):
		tx = int(hx + head_w * tx_off)
		ty = int(hy + head_h * 0.32)
		col = (BONE_PALE[0], BONE_PALE[1], BONE_PALE[2], 245)
		if tx_off < 0:
			pts = [(tx - 12, ty), (tx, ty - 4), (tx - 4, ty + 28)]
		else:
			pts = [(tx, ty - 4), (tx + 12, ty), (tx + 4, ty + 28)]
		draw.polygon(pts, fill=col)


def _paint_dire_wolf(draw, seed):
	r = _rand(seed)
	cx = W // 2
	ruff_pts = [
		(int(W * 0.12), int(W * 0.96)), (int(W * 0.18), int(W * 0.74)),
		(int(W * 0.30), int(W * 0.68)), (int(W * 0.70), int(W * 0.68)),
		(int(W * 0.82), int(W * 0.74)), (int(W * 0.88), int(W * 0.96)),
	]
	_draw_painter_blob(draw, ruff_pts, WOLF_DK, seed + 1, blob_r=24)
	head_pts = [
		(int(W * 0.20), int(W * 0.46)), (int(W * 0.18), int(W * 0.34)),
		(int(W * 0.22), int(W * 0.22)), (int(W * 0.30), int(W * 0.14)),
		(int(W * 0.38), int(W * 0.10)), (int(W * 0.46), int(W * 0.18)),
		(int(W * 0.54), int(W * 0.18)), (int(W * 0.62), int(W * 0.10)),
		(int(W * 0.70), int(W * 0.14)), (int(W * 0.78), int(W * 0.22)),
		(int(W * 0.82), int(W * 0.34)), (int(W * 0.80), int(W * 0.46)),
		(int(W * 0.74), int(W * 0.56)), (int(W * 0.62), int(W * 0.66)),
		(int(W * 0.55), int(W * 0.74)), (int(W * 0.48), int(W * 0.78)),
		(int(W * 0.42), int(W * 0.74)), (int(W * 0.38), int(W * 0.66)),
		(int(W * 0.26), int(W * 0.56)),
	]
	_draw_painter_blob(draw, head_pts, WOLF_GREY, seed + 2, blob_r=22)
	for _ in range(120):
		ang = r.uniform(0, math.tau)
		rr = r.uniform(W * 0.10, W * 0.30)
		x = cx + int(math.cos(ang) * rr)
		y = int(W * 0.45) + int(math.sin(ang) * rr * 0.6)
		col = (WOLF_DK[0], WOLF_DK[1], WOLF_DK[2], r.randint(40, 110))
		draw.ellipse((x - 10, y - 10, x + 10, y + 10), fill=col)
	for side in (-1, 1):
		ex = cx + side * int(W * 0.22)
		ey = int(W * 0.16)
		pts = [(ex - 22 * side, ey + 30), (ex + 8 * side, ey - 30), (ex + 30 * side, ey + 18)]
		_draw_painter_blob(draw, pts, WOLF_DK, seed + 3 + side, blob_r=10)
	for _ in range(30):
		ang = r.uniform(0, math.tau)
		rr = r.uniform(W * 0.20, W * 0.34)
		x = cx + int(math.cos(ang) * rr)
		y = int(W * 0.40) + int(math.sin(ang) * rr * 0.7)
		col = (SILVER[0], SILVER[1], SILVER[2], r.randint(100, 180))
		draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=col)
	for ex_off in (-0.10, 0.10):
		ex = cx + int(W * ex_off)
		ey = int(W * 0.36)
		col = (INK[0], INK[1], INK[2], 230)
		draw.ellipse((ex - 14, ey - 10, ex + 14, ey + 10), fill=col)
		col = (SUNSET_GOLD[0], SUNSET_GOLD[1], SUNSET_GOLD[2], 200)
		draw.ellipse((ex - 18, ey - 12, ex + 18, ey + 12), fill=col)
		col = (255, 230, 120, 240)
		draw.ellipse((ex - 8, ey - 6, ex + 8, ey + 6), fill=col)
		col = (INK[0], INK[1], INK[2], 255)
		draw.ellipse((ex - 2, ey - 5, ex + 2, ey + 5), fill=col)
	nose_x, nose_y = cx, int(W * 0.66)
	col = (INK[0], INK[1], INK[2], 240)
	draw.ellipse((nose_x - 14, nose_y - 8, nose_x + 14, nose_y + 8), fill=col)
	for k in range(4):
		fx = cx - 24 + k * 16
		fy = int(W * 0.74)
		col = (BONE_PALE[0], BONE_PALE[1], BONE_PALE[2], 240)
		draw.polygon([(fx, fy), (fx + 8, fy), (fx + 4, fy + 14)], fill=col)
	col = (CRIMSON[0], CRIMSON[1], CRIMSON[2], 180)
	draw.line((cx - 50, int(W * 0.50), cx + 30, int(W * 0.62)), fill=col, width=4)


def _paint_skeleton_warrior(draw, seed):
	r = _rand(seed)
	cx = W // 2
	shoulder_pts = [
		(int(W * 0.16), int(W * 0.96)), (int(W * 0.20), int(W * 0.78)),
		(int(W * 0.30), int(W * 0.72)), (int(W * 0.70), int(W * 0.72)),
		(int(W * 0.80), int(W * 0.78)), (int(W * 0.84), int(W * 0.96)),
	]
	_draw_painter_blob(draw, shoulder_pts, BONE_DK, seed + 1, blob_r=22)
	for k in range(6):
		x0 = int(W * (0.22 + k * 0.10))
		col = (PARCHMENT_DK[0], PARCHMENT_DK[1], PARCHMENT_DK[2], 200)
		draw.line((x0, int(W * 0.74), x0 + 30, int(W * 0.96)), fill=col, width=8)
	hx, hy = cx, int(W * 0.40)
	head_w, head_h = int(W * 0.34), int(W * 0.36)
	head_pts = []
	for k in range(36):
		ang = (k / 36.0) * math.tau
		jitter = r.uniform(-0.03, 0.03)
		rx = head_w * (1.0 + jitter * 0.3)
		ry = head_h * (1.0 + jitter * 0.3)
		head_pts.append((int(hx + math.cos(ang) * rx * 0.5), int(hy + math.sin(ang) * ry * 0.5)))
	_draw_painter_blob(draw, head_pts, BONE_PALE, seed + 2, blob_r=22)
	for _ in range(80):
		ang = r.uniform(0, math.tau)
		rr = r.uniform(W * 0.10, W * 0.20)
		x = hx + int(math.cos(ang) * rr)
		y = hy + int(math.sin(ang) * rr * 0.7)
		col = (BONE_DK[0], BONE_DK[1], BONE_DK[2], r.randint(40, 100))
		draw.ellipse((x - 8, y - 8, x + 8, y + 8), fill=col)
	for ex_off in (-0.12, 0.12):
		ex = int(hx + head_w * ex_off)
		ey = int(hy - head_h * 0.05)
		col = (INK[0], INK[1], INK[2], 255)
		draw.ellipse((ex - 18, ey - 14, ex + 18, ey + 14), fill=col)
		col = (FROST_CYAN[0], FROST_CYAN[1], FROST_CYAN[2], 220)
		draw.ellipse((ex - 7, ey - 5, ex + 7, ey + 5), fill=col)
		col = (240, 250, 255, 240)
		draw.ellipse((ex - 3, ey - 2, ex + 3, ey + 2), fill=col)
	pts = [
		(cx, hy + int(head_h * 0.04)),
		(cx - 10, hy + int(head_h * 0.18)),
		(cx + 10, hy + int(head_h * 0.18)),
	]
	col = (INK[0], INK[1], INK[2], 255)
	draw.polygon(pts, fill=col)
	col = (BONE_DK[0], BONE_DK[1], BONE_DK[2], 240)
	draw.rectangle((cx - 50, hy + int(head_h * 0.25), cx + 50, hy + int(head_h * 0.40)), fill=col)
	for k in range(8):
		tx = cx - 48 + k * 14
		col = (INK[0], INK[1], INK[2], 240)
		draw.line((tx, hy + int(head_h * 0.25), tx, hy + int(head_h * 0.40)), fill=col, width=2)
	col = (INK[0], INK[1], INK[2], 200)
	draw.line((cx - 30, hy - int(head_h * 0.40), cx + 10, hy - int(head_h * 0.10)), fill=col, width=3)
	draw.line((cx + 10, hy - int(head_h * 0.10), cx + 4, hy + int(head_h * 0.05)), fill=col, width=3)
	col = (130, 80, 40, 230)
	draw.rectangle((hx - int(head_w * 0.55), hy - int(head_h * 0.50), hx + int(head_w * 0.55), hy - int(head_h * 0.34)), fill=col)
	col = (90, 50, 24, 240)
	draw.line((hx - int(head_w * 0.55), hy - int(head_h * 0.42), hx + int(head_w * 0.55), hy - int(head_h * 0.42)), fill=col, width=4)
	for _ in range(30):
		x = hx + r.randint(-int(head_w * 0.55), int(head_w * 0.55))
		y = hy - int(head_h * 0.42) + r.randint(-6, 6)
		col = (60, 30, 12, r.randint(150, 220))
		draw.ellipse((x - 3, y - 3, x + 3, y + 3), fill=col)


def _paint_crystal_elemental(draw, seed):
	r = _rand(seed)
	cx = W // 2
	for i in range(20, 0, -1):
		t = i / 20.0
		rr = int(W * 0.30 * t)
		col = (FROST_CYAN[0], FROST_CYAN[1], FROST_CYAN[2], int(40 * t))
		draw.ellipse((cx - rr, int(W * 0.50) - rr, cx + rr, int(W * 0.50) + rr), fill=col)
	body_pts = [
		(int(W * 0.32), int(W * 0.96)), (int(W * 0.22), int(W * 0.78)),
		(int(W * 0.30), int(W * 0.62)), (int(W * 0.38), int(W * 0.50)),
		(int(W * 0.40), int(W * 0.32)), (int(W * 0.50), int(W * 0.16)),
		(int(W * 0.60), int(W * 0.32)), (int(W * 0.62), int(W * 0.50)),
		(int(W * 0.70), int(W * 0.62)), (int(W * 0.78), int(W * 0.78)),
		(int(W * 0.68), int(W * 0.96)),
	]
	_draw_painter_blob(draw, body_pts, (60, 110, 160, 255), seed + 1, blob_r=24)
	shards = [
		[(cx, int(W * 0.20)), (int(W * 0.42), int(W * 0.36)), (int(W * 0.50), int(W * 0.46)), (int(W * 0.46), int(W * 0.30))],
		[(cx, int(W * 0.20)), (int(W * 0.58), int(W * 0.36)), (int(W * 0.50), int(W * 0.46)), (int(W * 0.54), int(W * 0.30))],
		[(int(W * 0.32), int(W * 0.66)), (int(W * 0.38), int(W * 0.54)), (int(W * 0.46), int(W * 0.66)), (int(W * 0.40), int(W * 0.78))],
		[(int(W * 0.68), int(W * 0.66)), (int(W * 0.62), int(W * 0.54)), (int(W * 0.54), int(W * 0.66)), (int(W * 0.60), int(W * 0.78))],
		[(int(W * 0.40), int(W * 0.86)), (int(W * 0.50), int(W * 0.74)), (int(W * 0.60), int(W * 0.86)), (int(W * 0.50), int(W * 0.94))],
	]
	for sp in shards:
		col = (140, 200, 230, 230)
		draw.polygon(sp, fill=col)
	for sp in shards:
		for i in range(len(sp)):
			a = sp[i]
			b = sp[(i + 1) % len(sp)]
			col = (220, 240, 250, 220)
			draw.line((a, b), fill=col, width=3)
	for _ in range(80):
		ang = r.uniform(0, math.tau)
		rr = r.uniform(W * 0.04, W * 0.30)
		x = cx + int(math.cos(ang) * rr)
		y = int(W * 0.50) + int(math.sin(ang) * rr * 0.9)
		col = (200, 240, 255, r.randint(40, 130))
		draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=col)
	for ex_off in (-0.05, 0.05):
		ex = cx + int(W * ex_off)
		ey = int(W * 0.30)
		col = (FROST_CYAN[0], FROST_CYAN[1], FROST_CYAN[2], 220)
		draw.ellipse((ex - 12, ey - 12, ex + 12, ey + 12), fill=col)
		col = (240, 252, 255, 250)
		draw.ellipse((ex - 6, ey - 6, ex + 6, ey + 6), fill=col)
	for _ in range(8):
		ang = r.uniform(0, math.tau)
		rr = r.uniform(W * 0.34, W * 0.44)
		x = cx + int(math.cos(ang) * rr)
		y = int(W * 0.48) + int(math.sin(ang) * rr * 0.85)
		s = r.randint(6, 12)
		pts = [(x, y - s), (x + s, y), (x, y + s), (x - s, y)]
		col = (140, 200, 230, 230)
		draw.polygon(pts, fill=col)


def _paint_crystal_guardian(draw, seed):
	r = _rand(seed)
	cx = W // 2
	for i in range(28, 0, -1):
		t = i / 28.0
		rr = int(W * 0.46 * t)
		col = (ARCANE[0], ARCANE[1], ARCANE[2], int(30 * t))
		draw.ellipse((cx - rr, int(W * 0.46) - rr, cx + rr, int(W * 0.46) + rr), fill=col)
	body_pts = [
		(int(W * 0.20), int(W * 0.98)), (int(W * 0.10), int(W * 0.78)),
		(int(W * 0.20), int(W * 0.58)), (int(W * 0.32), int(W * 0.42)),
		(int(W * 0.34), int(W * 0.22)), (int(W * 0.50), int(W * 0.06)),
		(int(W * 0.66), int(W * 0.22)), (int(W * 0.68), int(W * 0.42)),
		(int(W * 0.80), int(W * 0.58)), (int(W * 0.90), int(W * 0.78)),
		(int(W * 0.80), int(W * 0.98)),
	]
	_draw_painter_blob(draw, body_pts, (70, 90, 150, 255), seed + 1, blob_r=26)
	head_pts = [
		(cx, int(W * 0.06)),
		(int(W * 0.36), int(W * 0.30)),
		(int(W * 0.50), int(W * 0.46)),
		(int(W * 0.64), int(W * 0.30)),
	]
	_draw_painter_blob(draw, head_pts, (110, 140, 200, 255), seed + 2, blob_r=20)
	side_l = [(int(W * 0.12), int(W * 0.66)), (int(W * 0.30), int(W * 0.50)), (int(W * 0.36), int(W * 0.78)), (int(W * 0.20), int(W * 0.84))]
	side_r = [(int(W * 0.88), int(W * 0.66)), (int(W * 0.70), int(W * 0.50)), (int(W * 0.64), int(W * 0.78)), (int(W * 0.80), int(W * 0.84))]
	for sp in (side_l, side_r):
		_draw_painter_blob(draw, sp, (140, 110, 190, 255), seed + 3, blob_r=18)
	for sp, col in ((head_pts, (200, 220, 250, 230)), (side_l, (210, 180, 240, 220)), (side_r, (210, 180, 240, 220))):
		for i in range(len(sp)):
			a = sp[i]
			b = sp[(i + 1) % len(sp)]
			draw.line((a, b), fill=col, width=4)
	for _ in range(14):
		ang = r.uniform(0, math.tau)
		rr = r.uniform(W * 0.06, W * 0.30)
		x = cx + int(math.cos(ang) * rr)
		y = int(W * 0.46) + int(math.sin(ang) * rr * 0.9)
		col = (ARCANE[0], ARCANE[1], ARCANE[2], r.randint(180, 240))
		draw.line((x - 6, y, x + 6, y), fill=col, width=3)
		draw.line((x, y - 6, x, y + 6), fill=col, width=3)
	core_x, core_y = cx, int(W * 0.30)
	for i in range(8, 0, -1):
		t = i / 8.0
		rr = int(20 * t)
		col = (240, 200, 255, int(180 * t))
		draw.ellipse((core_x - rr, core_y - rr, core_x + rr, core_y + rr), fill=col)
	col = (255, 240, 255, 250)
	draw.ellipse((core_x - 8, core_y - 8, core_x + 8, core_y + 8), fill=col)
	for k in range(10):
		ang = (k / 10.0) * math.tau
		rr = W * 0.42
		x = cx + int(math.cos(ang) * rr)
		y = int(W * 0.46) + int(math.sin(ang) * rr * 0.85)
		s = r.randint(8, 16)
		pts = [(x, y - s), (x + s, y), (x, y + s), (x - s, y)]
		col = (180, 160, 230, 220)
		draw.polygon(pts, fill=col)
		col = (220, 200, 250, 240)
		for i in range(4):
			draw.line((pts[i], pts[(i + 1) % 4]), fill=col, width=2)


def _paint_bandit_hooded(draw, seed):
	r = _rand(seed)
	cx = W // 2
	cloak_pts = [
		(int(W * 0.06), int(W * 0.98)), (int(W * 0.10), int(W * 0.66)),
		(int(W * 0.20), int(W * 0.58)), (int(W * 0.34), int(W * 0.54)),
		(int(W * 0.66), int(W * 0.54)), (int(W * 0.80), int(W * 0.58)),
		(int(W * 0.90), int(W * 0.66)), (int(W * 0.94), int(W * 0.98)),
	]
	_draw_painter_blob(draw, cloak_pts, LEATHER_DK, seed + 1, blob_r=24)
	col = (BRASS[0], BRASS[1], BRASS[2], 240)
	draw.ellipse((cx - 12, int(W * 0.62), cx + 12, int(W * 0.74)), fill=col)
	col = (CRIMSON[0], CRIMSON[1], CRIMSON[2], 240)
	draw.ellipse((cx - 5, int(W * 0.66), cx + 5, int(W * 0.72)), fill=col)
	hood_pts = [
		(int(W * 0.22), int(W * 0.62)), (int(W * 0.18), int(W * 0.40)),
		(int(W * 0.24), int(W * 0.20)), (int(W * 0.36), int(W * 0.10)),
		(int(W * 0.50), int(W * 0.06)), (int(W * 0.64), int(W * 0.10)),
		(int(W * 0.76), int(W * 0.20)), (int(W * 0.82), int(W * 0.40)),
		(int(W * 0.78), int(W * 0.62)), (int(W * 0.66), int(W * 0.58)),
		(int(W * 0.60), int(W * 0.50)), (int(W * 0.40), int(W * 0.50)),
		(int(W * 0.34), int(W * 0.58)),
	]
	_draw_painter_blob(draw, hood_pts, INK_LT, seed + 2, blob_r=22)
	face_pts = [
		(int(W * 0.34), int(W * 0.56)), (int(W * 0.36), int(W * 0.40)),
		(int(W * 0.50), int(W * 0.30)), (int(W * 0.64), int(W * 0.40)),
		(int(W * 0.66), int(W * 0.56)), (int(W * 0.50), int(W * 0.62)),
	]
	_draw_painter_blob(draw, face_pts, (50, 30, 24, 255), seed + 3, blob_r=14)
	skin_pts = [
		(int(W * 0.36), int(W * 0.46)), (int(W * 0.40), int(W * 0.40)),
		(int(W * 0.60), int(W * 0.40)), (int(W * 0.64), int(W * 0.46)),
		(int(W * 0.60), int(W * 0.50)), (int(W * 0.40), int(W * 0.50)),
	]
	_draw_painter_blob(draw, skin_pts, SKIN_HUMAN, seed + 4, blob_r=10)
	for ex_off in (-0.08, 0.08):
		ex = cx + int(W * ex_off)
		ey = int(W * 0.45)
		col = (INK[0], INK[1], INK[2], 250)
		draw.ellipse((ex - 12, ey - 6, ex + 12, ey + 6), fill=col)
		col = (240, 240, 230, 250)
		draw.ellipse((ex - 8, ey - 3, ex + 8, ey + 3), fill=col)
		col = (60, 50, 40, 250)
		draw.ellipse((ex - 4, ey - 2, ex + 4, ey + 2), fill=col)
		col = (INK[0], INK[1], INK[2], 250)
		draw.ellipse((ex - 2, ey - 1, ex + 2, ey + 1), fill=col)
	col = (INK[0], INK[1], INK[2], 200)
	draw.line((int(W * 0.36), int(W * 0.41), int(W * 0.46), int(W * 0.39)), fill=col, width=4)
	draw.line((int(W * 0.54), int(W * 0.39), int(W * 0.64), int(W * 0.41)), fill=col, width=4)
	scarf_pts = [
		(int(W * 0.34), int(W * 0.50)), (int(W * 0.40), int(W * 0.48)),
		(int(W * 0.60), int(W * 0.48)), (int(W * 0.66), int(W * 0.50)),
		(int(W * 0.66), int(W * 0.62)), (int(W * 0.50), int(W * 0.66)),
		(int(W * 0.34), int(W * 0.62)),
	]
	_draw_painter_blob(draw, scarf_pts, WINE, seed + 5, blob_r=14)
	for k in range(3):
		col = (CRIMSON[0], CRIMSON[1], CRIMSON[2], 200)
		y = int(W * (0.54 + k * 0.03))
		draw.line((int(W * 0.36), y, int(W * 0.64), y - 4), fill=col, width=3)
	col = (PARCHMENT_DK[0], PARCHMENT_DK[1], PARCHMENT_DK[2], 160)
	for k in range(20):
		t = k / 20.0
		x = int(W * (0.22 + t * 0.56))
		y = int(W * (0.20 + math.sin(t * math.pi) * -0.08 + t * 0.10))
		draw.ellipse((x - 3, y - 3, x + 3, y + 3), fill=col)


ENEMIES = {
	"goblin_grunt":     {"seed": 7501, "bg_top": (110, 80, 40),  "bg_bot": (50, 30, 18),  "painter": _paint_goblin_grunt},
	"goblin_brute":     {"seed": 7502, "bg_top": (90, 60, 30),   "bg_bot": (40, 24, 14),  "painter": _paint_goblin_brute},
	"goblin_warlord":   {"seed": 7503, "bg_top": (120, 30, 30),  "bg_bot": (50, 14, 14),  "painter": _paint_goblin_warlord},
	"dire_wolf":        {"seed": 7504, "bg_top": (70, 80, 90),   "bg_bot": (28, 28, 36),  "painter": _paint_dire_wolf},
	"skeleton_warrior": {"seed": 7505, "bg_top": (60, 70, 70),   "bg_bot": (24, 28, 30),  "painter": _paint_skeleton_warrior},
	"crystal_elemental":{"seed": 7506, "bg_top": (40, 70, 110),  "bg_bot": (16, 24, 50),  "painter": _paint_crystal_elemental},
	"crystal_guardian": {"seed": 7507, "bg_top": (60, 50, 110),  "bg_bot": (20, 16, 50),  "painter": _paint_crystal_guardian},
	"bandit_hooded":    {"seed": 7508, "bg_top": (70, 60, 50),   "bg_bot": (28, 22, 18),  "painter": _paint_bandit_hooded},
}


def _rounded_mask():
	mask = Image.new("L", (W, W), 0)
	md = ImageDraw.Draw(mask)
	pad = int(W * 0.02)
	radius = int(W * 0.10)
	md.rounded_rectangle((pad, pad, W - pad, W - pad), radius=radius, fill=255)
	mask = mask.filter(ImageFilter.GaussianBlur(W / 256.0))
	return mask


def _add_painterly_frame(draw, seed):
	r = _rand(seed)
	pad = int(W * 0.04)
	for k in range(120):
		t = k / 120.0
		side = int(t * 4) % 4
		u = (t * 4) % 1.0
		if side == 0:
			x, y = int(pad + (W - 2 * pad) * u), pad
		elif side == 1:
			x, y = W - pad, int(pad + (W - 2 * pad) * u)
		elif side == 2:
			x, y = int(W - pad - (W - 2 * pad) * u), W - pad
		else:
			x, y = pad, int(W - pad - (W - 2 * pad) * u)
		col = (PARCHMENT_DK[0], PARCHMENT_DK[1], PARCHMENT_DK[2], r.randint(80, 160))
		draw.ellipse((x - 6, y - 6, x + 6, y + 6), fill=col)


def _finalise(img, mask, out_path):
	img.putalpha(mask)
	img = img.filter(ImageFilter.GaussianBlur(W / 320.0))
	img = img.resize((SIZE, SIZE), Image.LANCZOS)
	img.save(out_path, "PNG", optimize=True)


def render_one(slug, spec, out_dir):
	img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
	draw = ImageDraw.Draw(img)
	_paint_bg_gradient(draw, spec["bg_top"], spec["bg_bot"], spec["seed"])
	spec["painter"](draw, spec["seed"] + 17)
	_add_painterly_frame(draw, spec["seed"] + 91)
	mask = _rounded_mask()
	out_path = os.path.join(out_dir, f"{slug}.png")
	_finalise(img, mask, out_path)
	return out_path


def main(argv):
	if len(argv) < 2:
		print("usage: gen_enemy_portraits.py <out_dir>", file=sys.stderr)
		return 2
	out_dir = argv[1]
	os.makedirs(out_dir, exist_ok=True)
	for slug, spec in ENEMIES.items():
		path = render_one(slug, spec, out_dir)
		print(f"  wrote {path}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main(sys.argv))
