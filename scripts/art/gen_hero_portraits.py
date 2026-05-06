#!/usr/bin/env python3
"""
Realm of Eldoria — playable-hero Character-Select portraits.

Two painterly 256x256 PNG busts of the two playable heroes (Alden the
Pathfinder and Owen the Vanguard), matching the style of the bestiary
portraits in `gen_enemy_portraits.py` / `gen_bandit_captain_portrait.py`
(run-23..run-26). Seeds 7601 / 7602 are additive — they don't collide
with the bestiary seeds 7501..7509.

Why this exists (Art delta — Character Select hero faces):
  - `CharacterSelect.gd` ships two big hero cards (`_make_hero_card`)
    that currently fall back to a giant emoji ("★" Alden, "✦" Owen)
    with the comment "placeholder until hero portrait images ship".
  - The two playable heroes are the FIRST thing every kid sees on
    boot — a painterly bust per hero will read as a real fantasy
    adventurer rather than a star glyph, in the same painterly family
    as the NPC + enemy portraits the codex already uses.
  - Wiring is a fail-soft pattern identical to NPCs: if the PNG loads,
    use TextureRect; otherwise the emoji-Label stays. CharacterSelect.gd
    is updated by the same run that ships these PNGs.

Silhouette differentiation (THEME §4 silhouette-distinct):

  ALDEN — Pathfinder (Bow & wits)
    - Forest-mint hood + leather jerkin (mint = COL_ALDEN in CharacterSelect.gd)
    - Wooden longbow strung diagonally across the back/shoulder
    - Single arrow shaft visible over right shoulder (quiver hint)
    - Younger face, faint freckles, warm hazel eyes (open / curious)
    - Forest moss-and-amber background gradient
    - Brass arrow-tip clasp at hood throat (his "★" star insignia)

  OWEN — Vanguard (Sword & shield)
    - Sunset-orange tabard over chainmail (orange = COL_OWEN, McLaren #FF8000)
    - Round wooden shield held at the chest (visible upper-right rim)
    - Sword pommel poking up over the left shoulder (sheathed on back)
    - Stocky brass-rimmed helm visor up — full face visible
    - Sunset crimson-and-gold background gradient
    - Bronze stag-crest medallion at the chest (his "✦" sigil insignia)

Style targets (THEME.md):
  - §1 painterly hand-painted concept-art aesthetic — same `_draw_painter_blob`
    soft-edge stamping + Gaussian blur + LANCZOS downsample.
  - §3 palette — sunset gold, burnt orange, moss green, parchment, ink,
    crimson, brass. Mint and McLaren-orange accents are pulled directly
    from CharacterSelect.gd's COL_ALDEN / COL_OWEN constants so the
    portrait card frame and the bust read as one unit at full size.
  - §4 silhouette-distinct — Alden=hooded ranger w/ bow over shoulder,
    Owen=helmed swordsman w/ shield — recognisable at 30m thumbnail.
  - §5 hand-painted, not crisp vector — painterly speckle frame +
    soft rounded-rect alpha mask + Gaussian blur on downsample.
  - §7 child-safe — friendly faces, open eyes, no scars (Alden=12,
    Owen=12, Ghibli-mentor warmth, no Game-of-Thrones cynicism).
  - §10 Hard Rule 9 — older / weathered / lived-in: leather creases,
    helm scuffs, frayed hood edge, stubble-free youthful but
    weathered-by-the-road look.

Output: 2 RGBA PNGs at 256x256, transparent rounded-rect background,
saved to <out_dir>/{alden_pathfinder,owen_vanguard}.png. Slugs match
the file names Player.gd's hero_paths uses (sans `.glb` suffix).

License: CC0 — generated procedurally with Pillow, no external assets,
no trademark or third-party reference material.

Run: python3 gen_hero_portraits.py <out_dir>
"""
from __future__ import annotations
import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter

SIZE = 256
SUPER = 4
W = SIZE * SUPER

# THEME.md §3 palette anchors — same as enemy/bandit_captain portraits so
# the hero busts read in the same family at codex thumbnail size.
PARCHMENT    = (217, 201, 155, 255)
PARCHMENT_DK = (170, 150, 110, 255)
INK          = (14, 10, 14, 255)
INK_LT       = (40, 32, 36, 255)
SUNSET_GOLD  = (255, 200, 80, 255)
SUNSET_DK    = (200, 130, 50, 255)
CRIMSON      = (140, 32, 32, 255)
WINE         = (110, 24, 24, 255)
BRASS        = (176, 116, 42, 255)
BRASS_LT     = (210, 160, 90, 255)
SKIN_YOUTH   = (220, 180, 140, 255)
SKIN_DK      = (170, 130, 95, 255)
LEATHER_DK   = (60, 42, 28, 255)
LEATHER_LT   = (120, 86, 52, 255)
MOSS_DK      = (50, 80, 45, 255)
MOSS_LT      = (110, 150, 80, 255)
MINT_LT      = (140, 240, 165, 255)   # COL_ALDEN-aligned highlight
MCL_ORANGE   = (255, 128, 0, 255)     # COL_OWEN literal
MCL_DEEP     = (200, 95, 0, 255)
MAIL_GREY    = (130, 132, 140, 255)
MAIL_LT      = (175, 178, 185, 255)
WOOD_BOW     = (135, 88, 50, 255)
WOOD_BOW_LT  = (180, 130, 78, 255)
HAIR_BROWN   = (90, 60, 35, 255)
HAIR_GOLD    = (175, 130, 70, 255)


def _rand(seed):
	return random.Random(seed)


def _paint_bg_gradient(draw, top, bottom, seed):
	"""Vertical gradient + painterly speckle (matches enemy portraits)."""
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
	# painterly speckle to break the flat gradient
	for _ in range(440):
		x = r.randint(0, W - 1)
		y = r.randint(0, W - 1)
		s = r.randint(6, 14)
		jitter = r.randint(-25, 25)
		base = top if y < W // 2 else bottom
		col = (
			max(0, min(255, base[0] + jitter)),
			max(0, min(255, base[1] + jitter)),
			max(0, min(255, base[2] + jitter)),
			r.randint(120, 200),
		)
		draw.ellipse((x - s, y - s, x + s, y + s), fill=col)


def _draw_painter_blob(draw, points, fill, jitter_seed, blob_r=18):
	"""Stamp soft-edge ellipses along a polygon outline — painterly rim."""
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


# ────────────────────────────────────────────────────────────────────────
# ALDEN — Pathfinder (Bow & wits)
# ────────────────────────────────────────────────────────────────────────

def _paint_alden(draw, seed):
	"""Painterly bust: young hooded ranger with longbow over shoulder.
	Silhouette-distinct: forest-mint hood + diagonal bow + arrow shaft."""
	r = _rand(seed)
	cx = W // 2

	# 1) Cloak base — narrower than vanguard (ranger silhouette is lithe).
	cloak_pts = [
		(int(W * 0.06), int(W * 0.98)), (int(W * 0.10), int(W * 0.66)),
		(int(W * 0.22), int(W * 0.58)), (int(W * 0.36), int(W * 0.54)),
		(int(W * 0.64), int(W * 0.54)), (int(W * 0.78), int(W * 0.58)),
		(int(W * 0.90), int(W * 0.66)), (int(W * 0.94), int(W * 0.98)),
	]
	_draw_painter_blob(draw, cloak_pts, MOSS_DK, seed + 1, blob_r=24)

	# 2) Leather jerkin (chest) — visible under hood, between cloak edges.
	jerkin_pts = [
		(int(W * 0.36), int(W * 0.54)),
		(int(W * 0.40), int(W * 0.66)),
		(int(W * 0.50), int(W * 0.70)),
		(int(W * 0.60), int(W * 0.66)),
		(int(W * 0.64), int(W * 0.54)),
	]
	_draw_painter_blob(draw, jerkin_pts, LEATHER_LT, seed + 2, blob_r=14)
	# Lacing detail (X-pattern on jerkin) — kid-friendly hand-laced look.
	col = (LEATHER_DK[0], LEATHER_DK[1], LEATHER_DK[2], 230)
	for k in range(3):
		yy = int(W * (0.58 + k * 0.04))
		draw.line(
			(int(W * 0.46), yy, int(W * 0.54), yy + int(W * 0.02)),
			fill=col, width=3,
		)
		draw.line(
			(int(W * 0.54), yy, int(W * 0.46), yy + int(W * 0.02)),
			fill=col, width=3,
		)

	# 3) Bow over LEFT shoulder — diagonal from upper-left to lower-right.
	# This is the silhouette differentiator from owen at 30m.
	bow_top    = (int(W * 0.10), int(W * 0.18))
	bow_bottom = (int(W * 0.34), int(W * 0.86))
	# Bow stave — thick wood line.
	col = (WOOD_BOW[0], WOOD_BOW[1], WOOD_BOW[2], 255)
	draw.line((bow_top, bow_bottom), fill=col, width=14)
	# Wood-grain highlight.
	col = (WOOD_BOW_LT[0], WOOD_BOW_LT[1], WOOD_BOW_LT[2], 230)
	draw.line(
		(bow_top[0] + 3, bow_top[1] + 3, bow_bottom[0] + 3, bow_bottom[1] + 3),
		fill=col, width=4,
	)
	# Bow string — taut diagonal slightly inside the stave.
	col = (PARCHMENT[0], PARCHMENT[1], PARCHMENT[2], 200)
	# Curve approximation — three line segments mimicking a slight bow
	mid = (
		int((bow_top[0] + bow_bottom[0]) / 2 + W * 0.04),
		int((bow_top[1] + bow_bottom[1]) / 2),
	)
	draw.line((bow_top, mid), fill=col, width=2)
	draw.line((mid, bow_bottom), fill=col, width=2)

	# 4) Arrow over RIGHT shoulder — quiver hint, fletching at top.
	arrow_top = (int(W * 0.78), int(W * 0.10))
	arrow_bot = (int(W * 0.70), int(W * 0.46))
	col = (WOOD_BOW_LT[0], WOOD_BOW_LT[1], WOOD_BOW_LT[2], 240)
	draw.line((arrow_top, arrow_bot), fill=col, width=4)
	# Arrowhead (small bronze triangle at bottom)
	ah = arrow_bot
	col = (BRASS[0], BRASS[1], BRASS[2], 240)
	draw.polygon(
		[(ah[0] - 5, ah[1] - 8), (ah[0] + 5, ah[1] - 8), (ah[0], ah[1] + 6)],
		fill=col,
	)
	# Fletching (3 small green feathers at top)
	for fk in range(3):
		fx = arrow_top[0] - 4 + fk * 4
		fy = arrow_top[1] - 6
		col = (MOSS_LT[0], MOSS_LT[1], MOSS_LT[2], 230)
		draw.polygon(
			[(fx - 3, fy + 8), (fx + 3, fy + 8), (fx, fy)],
			fill=col,
		)

	# 5) Hood — forest-mint pointed hood, slightly back-folded.
	hood_pts = [
		(int(W * 0.22), int(W * 0.58)),
		(int(W * 0.16), int(W * 0.44)),
		(int(W * 0.18), int(W * 0.26)),
		(int(W * 0.30), int(W * 0.14)),
		(int(W * 0.46), int(W * 0.06)),
		(int(W * 0.50), int(W * 0.04)),
		(int(W * 0.54), int(W * 0.06)),
		(int(W * 0.70), int(W * 0.14)),
		(int(W * 0.82), int(W * 0.26)),
		(int(W * 0.84), int(W * 0.44)),
		(int(W * 0.78), int(W * 0.58)),
		(int(W * 0.64), int(W * 0.54)),
		(int(W * 0.60), int(W * 0.44)),
		(int(W * 0.40), int(W * 0.44)),
		(int(W * 0.36), int(W * 0.54)),
	]
	_draw_painter_blob(draw, hood_pts, MOSS_DK, seed + 3, blob_r=20)
	# Mint highlight on hood ridge — pulls COL_ALDEN into the bust.
	ridge_pts = [
		(int(W * 0.32), int(W * 0.20)),
		(int(W * 0.50), int(W * 0.10)),
		(int(W * 0.68), int(W * 0.20)),
		(int(W * 0.62), int(W * 0.24)),
		(int(W * 0.50), int(W * 0.16)),
		(int(W * 0.38), int(W * 0.24)),
	]
	_draw_painter_blob(draw, ridge_pts, MINT_LT, seed + 4, blob_r=8)

	# 6) Brass arrow-tip clasp at throat (Alden's "★" sigil).
	clasp_cx = cx
	clasp_cy = int(W * 0.58)
	col = (BRASS[0], BRASS[1], BRASS[2], 240)
	# Five-pointed star, simplified into two triangles (no rotation math required)
	# Up-triangle
	tri_up = [
		(clasp_cx, clasp_cy - 14),
		(clasp_cx - 12, clasp_cy + 6),
		(clasp_cx + 12, clasp_cy + 6),
	]
	draw.polygon(tri_up, fill=col)
	# Down-triangle (offset so they form a simplified star silhouette)
	tri_dn = [
		(clasp_cx, clasp_cy + 12),
		(clasp_cx - 12, clasp_cy - 4),
		(clasp_cx + 12, clasp_cy - 4),
	]
	draw.polygon(tri_dn, fill=col)
	# Bright brass core highlight
	col = (BRASS_LT[0], BRASS_LT[1], BRASS_LT[2], 250)
	draw.ellipse(
		(clasp_cx - 4, clasp_cy - 4, clasp_cx + 4, clasp_cy + 4),
		fill=col,
	)

	# 7) Face — visible (open hood, friendly young ranger).
	face_pts = [
		(int(W * 0.40), int(W * 0.44)),
		(int(W * 0.38), int(W * 0.34)),
		(int(W * 0.44), int(W * 0.26)),
		(int(W * 0.50), int(W * 0.24)),
		(int(W * 0.56), int(W * 0.26)),
		(int(W * 0.62), int(W * 0.34)),
		(int(W * 0.60), int(W * 0.44)),
		(int(W * 0.50), int(W * 0.50)),
	]
	_draw_painter_blob(draw, face_pts, SKIN_YOUTH, seed + 5, blob_r=12)
	# Skin highlight on cheek apples — gives the youthful warmth.
	hl_pts = [
		(int(W * 0.42), int(W * 0.36)),
		(int(W * 0.46), int(W * 0.32)),
		(int(W * 0.54), int(W * 0.32)),
		(int(W * 0.58), int(W * 0.36)),
	]
	_draw_painter_blob(
		draw, hl_pts, (240, 210, 175, 200), seed + 6, blob_r=8,
	)
	# Hair tuft escaping hood (front)
	hair_pts = [
		(int(W * 0.42), int(W * 0.24)),
		(int(W * 0.46), int(W * 0.20)),
		(int(W * 0.54), int(W * 0.20)),
		(int(W * 0.58), int(W * 0.24)),
		(int(W * 0.54), int(W * 0.28)),
		(int(W * 0.46), int(W * 0.28)),
	]
	_draw_painter_blob(draw, hair_pts, HAIR_GOLD, seed + 7, blob_r=8)

	# 8) Eyes — open, hazel, curious (Ghibli warmth).
	for ex_off in (-0.06, 0.06):
		ex = cx + int(W * ex_off)
		ey = int(W * 0.36)
		# Eye socket shadow
		col = (INK[0], INK[1], INK[2], 230)
		draw.ellipse((ex - 11, ey - 5, ex + 11, ey + 5), fill=col)
		# Sclera (open, warm)
		col = (245, 240, 225, 255)
		draw.ellipse((ex - 8, ey - 4, ex + 8, ey + 4), fill=col)
		# Hazel iris
		col = (130, 90, 50, 255)
		draw.ellipse((ex - 4, ey - 3, ex + 4, ey + 3), fill=col)
		# Pupil
		col = (INK[0], INK[1], INK[2], 255)
		draw.ellipse((ex - 2, ey - 2, ex + 2, ey + 2), fill=col)
		# Catchlight (Ghibli-style sparkle)
		col = (255, 255, 240, 255)
		draw.ellipse((ex - 1, ey - 3, ex + 1, ey - 1), fill=col)

	# 9) Faint freckles across nose — child-safe whimsy.
	for k in range(7):
		fx = cx - int(W * 0.05) + r.randint(0, int(W * 0.10))
		fy = int(W * 0.40) + r.randint(-int(W * 0.005), int(W * 0.005))
		col = (HAIR_BROWN[0], HAIR_BROWN[1], HAIR_BROWN[2], 180)
		s = r.randint(2, 3)
		draw.ellipse((fx - s, fy - s, fx + s, fy + s), fill=col)

	# 10) Soft smile — gentle upward curve (Ghibli mentor warmth).
	col = (INK_LT[0], INK_LT[1], INK_LT[2], 200)
	draw.line(
		(int(W * 0.46), int(W * 0.46), int(W * 0.54), int(W * 0.46)),
		fill=col, width=3,
	)
	# Smile lift (tiny corners up)
	draw.line(
		(int(W * 0.45), int(W * 0.46), int(W * 0.46), int(W * 0.45)),
		fill=col, width=3,
	)
	draw.line(
		(int(W * 0.54), int(W * 0.45), int(W * 0.55), int(W * 0.46)),
		fill=col, width=3,
	)


# ────────────────────────────────────────────────────────────────────────
# OWEN — Vanguard (Sword & shield)
# ────────────────────────────────────────────────────────────────────────

def _paint_owen(draw, seed):
	"""Painterly bust: young helmed swordsman with shield + back-sheathed
	sword. Silhouette-distinct: brass-rimmed helm + round shield + pommel."""
	r = _rand(seed)
	cx = W // 2

	# 1) Cloak base — squarer shoulders than alden (vanguard silhouette).
	cloak_pts = [
		(int(W * 0.04), int(W * 0.98)), (int(W * 0.06), int(W * 0.62)),
		(int(W * 0.16), int(W * 0.54)), (int(W * 0.30), int(W * 0.50)),
		(int(W * 0.70), int(W * 0.50)), (int(W * 0.84), int(W * 0.54)),
		(int(W * 0.94), int(W * 0.62)), (int(W * 0.96), int(W * 0.98)),
	]
	_draw_painter_blob(draw, cloak_pts, LEATHER_DK, seed + 1, blob_r=26)

	# 2) Chainmail collar (visible between cloak top and tabard).
	mail_pts = [
		(int(W * 0.30), int(W * 0.50)),
		(int(W * 0.34), int(W * 0.62)),
		(int(W * 0.66), int(W * 0.62)),
		(int(W * 0.70), int(W * 0.50)),
	]
	_draw_painter_blob(draw, mail_pts, MAIL_GREY, seed + 2, blob_r=14)
	# Mail rings dot pattern — painterly chainmail texture.
	for k in range(80):
		mx = int(W * (0.32 + (k % 10) * 0.036))
		my = int(W * (0.52 + (k // 10) * 0.013))
		col = (MAIL_LT[0], MAIL_LT[1], MAIL_LT[2], r.randint(140, 220))
		s = r.randint(2, 3)
		draw.ellipse((mx - s, my - s, mx + s, my + s), fill=col)

	# 3) Sunset-orange tabard (chest centre) — pulls COL_OWEN into the bust.
	tabard_pts = [
		(int(W * 0.40), int(W * 0.56)),
		(int(W * 0.42), int(W * 0.92)),
		(int(W * 0.50), int(W * 0.96)),
		(int(W * 0.58), int(W * 0.92)),
		(int(W * 0.60), int(W * 0.56)),
	]
	_draw_painter_blob(draw, tabard_pts, MCL_ORANGE, seed + 3, blob_r=16)
	# Deep-orange shading on tabard fold (left side under cloak).
	fold_pts = [
		(int(W * 0.40), int(W * 0.62)),
		(int(W * 0.42), int(W * 0.92)),
		(int(W * 0.46), int(W * 0.92)),
		(int(W * 0.46), int(W * 0.62)),
	]
	_draw_painter_blob(draw, fold_pts, MCL_DEEP, seed + 4, blob_r=10)

	# 4) Round wooden shield over LEFT arm — visible upper-right rim.
	# This is the silhouette differentiator from alden.
	shield_cx = int(W * 0.78)
	shield_cy = int(W * 0.78)
	shield_r  = int(W * 0.18)
	# Outer wood
	col = (WOOD_BOW[0], WOOD_BOW[1], WOOD_BOW[2], 250)
	draw.ellipse(
		(shield_cx - shield_r, shield_cy - shield_r,
		 shield_cx + shield_r, shield_cy + shield_r),
		fill=col,
	)
	# Inner rim (brass)
	col = (BRASS[0], BRASS[1], BRASS[2], 240)
	for ring_off in range(3):
		rr = shield_r - ring_off * 2
		draw.ellipse(
			(shield_cx - rr, shield_cy - rr, shield_cx + rr, shield_cy + rr),
			outline=col, width=2,
		)
	# Wood plank lines (3 vertical stripes)
	col = (LEATHER_DK[0], LEATHER_DK[1], LEATHER_DK[2], 200)
	for plank_off in (-shield_r // 2, 0, shield_r // 2):
		draw.line(
			(shield_cx + plank_off, shield_cy - shield_r + 6,
			 shield_cx + plank_off, shield_cy + shield_r - 6),
			fill=col, width=3,
		)
	# Centre boss (brass dome)
	col = (BRASS_LT[0], BRASS_LT[1], BRASS_LT[2], 250)
	bo = int(shield_r * 0.35)
	draw.ellipse(
		(shield_cx - bo, shield_cy - bo, shield_cx + bo, shield_cy + bo),
		fill=col,
	)
	# Crimson stag-crest on the boss (Owen's sigil)
	col = (CRIMSON[0], CRIMSON[1], CRIMSON[2], 240)
	bs = int(bo * 0.65)
	# Simplified stag silhouette: head + 2 antler points
	draw.line((shield_cx, shield_cy - bs, shield_cx, shield_cy), fill=col, width=4)
	draw.line(
		(shield_cx, shield_cy - bs, shield_cx - bs, shield_cy - bs - 2),
		fill=col, width=3,
	)
	draw.line(
		(shield_cx, shield_cy - bs, shield_cx + bs, shield_cy - bs - 2),
		fill=col, width=3,
	)

	# 5) Sword pommel over LEFT shoulder (sheathed on back).
	# Hilt diagonal up-left so the pommel pokes above the helm.
	pommel_cx = int(W * 0.20)
	pommel_cy = int(W * 0.20)
	# Pommel ball (brass)
	col = (BRASS[0], BRASS[1], BRASS[2], 250)
	draw.ellipse(
		(pommel_cx - 12, pommel_cy - 12, pommel_cx + 12, pommel_cy + 12),
		fill=col,
	)
	col = (BRASS_LT[0], BRASS_LT[1], BRASS_LT[2], 250)
	draw.ellipse(
		(pommel_cx - 6, pommel_cy - 6, pommel_cx + 4, pommel_cy + 4),
		fill=col,
	)
	# Crossguard
	col = (BRASS_LT[0], BRASS_LT[1], BRASS_LT[2], 250)
	draw.line(
		(pommel_cx - 18, pommel_cy + 12, pommel_cx + 14, pommel_cy + 24),
		fill=col, width=8,
	)
	# Grip wrap
	col = (LEATHER_DK[0], LEATHER_DK[1], LEATHER_DK[2], 250)
	draw.line(
		(pommel_cx, pommel_cy + 10, pommel_cx + 4, pommel_cy + 22),
		fill=col, width=6,
	)

	# 6) Helm — open-face brass-rimmed steel helm (stocky vanguard read).
	helm_pts = [
		(int(W * 0.30), int(W * 0.46)),
		(int(W * 0.30), int(W * 0.30)),
		(int(W * 0.36), int(W * 0.16)),
		(int(W * 0.46), int(W * 0.10)),
		(int(W * 0.50), int(W * 0.08)),
		(int(W * 0.54), int(W * 0.10)),
		(int(W * 0.64), int(W * 0.16)),
		(int(W * 0.70), int(W * 0.30)),
		(int(W * 0.70), int(W * 0.46)),
		(int(W * 0.62), int(W * 0.50)),
		(int(W * 0.38), int(W * 0.50)),
	]
	_draw_painter_blob(draw, helm_pts, MAIL_GREY, seed + 5, blob_r=20)
	# Helm-top dome highlight (steel polish)
	dome_pts = [
		(int(W * 0.40), int(W * 0.18)),
		(int(W * 0.50), int(W * 0.10)),
		(int(W * 0.60), int(W * 0.18)),
		(int(W * 0.56), int(W * 0.22)),
		(int(W * 0.50), int(W * 0.16)),
		(int(W * 0.44), int(W * 0.22)),
	]
	_draw_painter_blob(draw, dome_pts, MAIL_LT, seed + 6, blob_r=8)
	# Brass rim across forehead (helm-band, captain insignia equivalent)
	col = (BRASS[0], BRASS[1], BRASS[2], 240)
	draw.line(
		(int(W * 0.32), int(W * 0.36), int(W * 0.68), int(W * 0.36)),
		fill=col, width=8,
	)
	# Brass rivets along the rim — 5 bumps.
	for k in range(5):
		t = (k + 0.5) / 5.0
		px = int(W * (0.34 + t * 0.32))
		py = int(W * 0.36)
		col = (BRASS_LT[0], BRASS_LT[1], BRASS_LT[2], 240)
		draw.ellipse((px - 5, py - 5, px + 5, py + 5), fill=col)
	# Helm cheek guards (left and right flanges)
	for cgx in (int(W * 0.30), int(W * 0.66)):
		col = (MAIL_GREY[0], MAIL_GREY[1], MAIL_GREY[2], 240)
		draw.line(
			(cgx, int(W * 0.40), cgx, int(W * 0.50)),
			fill=col, width=8,
		)

	# 7) Face — visible (open helm, friendly young squire).
	face_pts = [
		(int(W * 0.40), int(W * 0.50)),
		(int(W * 0.40), int(W * 0.40)),
		(int(W * 0.46), int(W * 0.36)),
		(int(W * 0.54), int(W * 0.36)),
		(int(W * 0.60), int(W * 0.40)),
		(int(W * 0.60), int(W * 0.50)),
		(int(W * 0.50), int(W * 0.54)),
	]
	_draw_painter_blob(draw, face_pts, SKIN_YOUTH, seed + 7, blob_r=12)
	# Skin highlight on cheekbones / brow
	hl_pts = [
		(int(W * 0.42), int(W * 0.42)),
		(int(W * 0.46), int(W * 0.40)),
		(int(W * 0.54), int(W * 0.40)),
		(int(W * 0.58), int(W * 0.42)),
	]
	_draw_painter_blob(
		draw, hl_pts, (240, 210, 175, 200), seed + 8, blob_r=8,
	)

	# 8) Eyes — determined, blue-grey (vanguard resolve).
	for ex_off in (-0.06, 0.06):
		ex = cx + int(W * ex_off)
		ey = int(W * 0.42)
		# Eye socket shadow
		col = (INK[0], INK[1], INK[2], 230)
		draw.ellipse((ex - 11, ey - 5, ex + 11, ey + 5), fill=col)
		# Sclera
		col = (245, 240, 225, 255)
		draw.ellipse((ex - 8, ey - 4, ex + 8, ey + 4), fill=col)
		# Blue-grey iris
		col = (90, 110, 130, 255)
		draw.ellipse((ex - 4, ey - 3, ex + 4, ey + 3), fill=col)
		# Pupil
		col = (INK[0], INK[1], INK[2], 255)
		draw.ellipse((ex - 2, ey - 2, ex + 2, ey + 2), fill=col)
		# Catchlight
		col = (255, 255, 240, 255)
		draw.ellipse((ex - 1, ey - 3, ex + 1, ey - 1), fill=col)

	# 9) Determined mouth (firm line, slight smile lift)
	col = (INK_LT[0], INK_LT[1], INK_LT[2], 220)
	draw.line(
		(int(W * 0.46), int(W * 0.50), int(W * 0.54), int(W * 0.50)),
		fill=col, width=3,
	)


# ────────────────────────────────────────────────────────────────────────
# Frame, mask, finalise (matches existing portrait scripts)
# ────────────────────────────────────────────────────────────────────────

def _rounded_mask():
	"""Soft rounded-rect alpha mask (matches gen_enemy_portraits.py)."""
	mask = Image.new("L", (W, W), 0)
	md = ImageDraw.Draw(mask)
	pad = int(W * 0.02)
	radius = int(W * 0.10)
	md.rounded_rectangle((pad, pad, W - pad, W - pad), radius=radius, fill=255)
	mask = mask.filter(ImageFilter.GaussianBlur(W / 256.0))
	return mask


def _add_painterly_frame(draw, seed):
	"""Painterly speckle around the rounded-rect edge (matches enemies)."""
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


# ────────────────────────────────────────────────────────────────────────
# Hero specs — gradient + paint-fn pairing.
# ────────────────────────────────────────────────────────────────────────

HEROES = {
	# Forest moss-and-amber background — ranger reading at thumbnail size.
	"alden_pathfinder": {
		"seed": 7601,
		"bg_top": (62, 88, 60),     # forest moss top (slightly lifted into mint)
		"bg_bot": (28, 40, 26),     # deep forest under-canopy bottom
		"paint_fn": _paint_alden,
	},
	# Sunset crimson-and-gold background — vanguard at thumbnail size.
	"owen_vanguard": {
		"seed": 7602,
		"bg_top": (170, 80, 38),    # sunset crimson-orange top
		"bg_bot": (50, 22, 20),     # ink-wine bottom for grounded weight
		"paint_fn": _paint_owen,
	},
}


def render_one(out_dir, slug, spec):
	img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
	draw = ImageDraw.Draw(img)
	_paint_bg_gradient(draw, spec["bg_top"], spec["bg_bot"], spec["seed"])
	spec["paint_fn"](draw, spec["seed"] + 17)
	_add_painterly_frame(draw, spec["seed"] + 91)
	mask = _rounded_mask()
	out_path = os.path.join(out_dir, f"{slug}.png")
	_finalise(img, mask, out_path)
	return out_path


def main(argv):
	if len(argv) < 2:
		print("usage: gen_hero_portraits.py <out_dir>", file=sys.stderr)
		return 2
	out_dir = argv[1]
	os.makedirs(out_dir, exist_ok=True)
	for slug, spec in HEROES.items():
		path = render_one(out_dir, slug, spec)
		print(f"  wrote {path}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main(sys.argv))
