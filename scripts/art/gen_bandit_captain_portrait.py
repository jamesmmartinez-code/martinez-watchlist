#!/usr/bin/env python3
"""
Realm of Eldoria — bandit_captain bestiary portrait (delta).

One painterly 256x256 PNG bust of the bandit_captain mini-boss, matching
the style of `gen_enemy_portraits.py` (run-23..run-25). Seed 7509 keeps
this generator additive to the existing ENEMIES dict in that script —
seeds 7501..7508 are already taken by goblin_grunt..bandit_hooded.

Why this exists (Art run-26 delta):
  - `Enemy.gd` ships a dedicated `bandit_captain` kind (mini-boss) that
    currently shares `bandit.glb` with regular bandits, scaled 1.40x and
    re-tinted to a deeper purple-leather (see Enemy.gd KIND_TINT_OVERRIDE
    + COMPOUND comment block on bandit_captain).
  - Run-25 closed the icon-side delta by shipping `captain_seal.png`
    (the trophy material). The portrait-side delta — a face for the
    codex / boss-intro splash / loot-toast header — was still missing.
  - The 8 enemy portraits in `gen_enemy_portraits.py` cover the regular
    `bandit` kind via `bandit_hooded.png`, but bandit_captain has no
    silhouette-distinct face yet. At codex thumbnail size, a regular
    hooded scarfed bandit and a captain should NOT read identical.
  - Per ENEMIES_ATTRIBUTION.md "How a future Builder/UI run can wire
    these": the `ENEMY_PORTRAITS` map can grow a `bandit_captain`
    -> `res://assets/portraits/bandit_captain.png` entry without any
    further art work once this PNG ships.

Silhouette differentiation from `bandit_hooded.png` (THEME §4 silhouette-distinct):
  - Wider / squarer shoulders + a leather pauldron on the right
    (rank stripe — captain insignia, not regular bandit).
  - Wider-brimmed feathered tricorne hood + visible weathered face
    (older mini-boss, scarred cheek), no scarf-over-mouth — captain
    intimidates by being visible.
  - Crossed-daggers chest emblem matches captain_seal.png (the trophy
    that drops from this enemy) so codex + loot-toast share a visual
    motif.
  - Deeper wine + purple-leather tint vs regular bandit's charcoal +
    leather, mirroring KIND_TINT_OVERRIDE's purple-leather comment.

Style targets (THEME.md):
  - §1 painterly, hand-painted concept-art aesthetic — same _draw_painter_blob
    soft-edge stamping + Gaussian blur + LANCZOS downsample as run-23.
  - §3 palette — leather dark, wine, ink, brass, parchment, arcane purple
    (sparingly, only in pauldron rank-stripe). No neon, no fluorescent.
  - §4 silhouette-distinct from bandit_hooded — see differentiation above.
  - §5 hand-painted, not crisp vector — same painterly speckle frame
    + soft rounded-rect alpha mask + 0.30 SUPER Gaussian blur.
  - §7 child-safe — face scar (single line on cheek) + crossed-daggers
    motif (period weaponry, not skulls or gore). No wounds, no blood,
    no missing eye.
  - §10 Hard Rule 9 — older / weathered / hand-made: visible eye-bag,
    cheek scar, weathered hat brim, frayed cloak edge.

Output: 1 RGBA PNG at 256x256, transparent rounded-rect background.
Slug: bandit_captain (mirrors Enemy.gd kind exactly).

License: CC0 — generated procedurally with Pillow, no external assets,
no trademark or third-party reference material was used.

Run: python3 gen_bandit_captain_portrait.py <out_dir>
"""
from __future__ import annotations
import math, os, random, sys
from PIL import Image, ImageDraw, ImageFilter

SIZE = 256
SUPER = 4
W = SIZE * SUPER

# THEME.md §3 palette — same anchors as gen_enemy_portraits.py so the
# bandit_captain.png reads in the same family at codex thumbnail size.
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
ARCANE       = (124, 63, 176, 255)
ARCANE_DK    = (66, 30, 100, 255)
SKIN_HUMAN   = (190, 150, 110, 255)
SKIN_DK      = (140, 100, 70, 255)
LEATHER_DK   = (60, 42, 28, 255)
LEATHER_LT   = (120, 86, 52, 255)
LEATHER_PURP = (74, 50, 70, 255)   # bandit_captain-distinct purple-leather
SCAR_PINK    = (180, 110, 100, 255)


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


def _paint_bandit_captain(draw, seed):
	"""Painterly bust: hooded captain with leather pauldron + crossed-daggers
	chest emblem + scarred cheek + wider-brimmed weathered hat."""
	r = _rand(seed)
	cx = W // 2

	# 1) Cloak base — wider than regular bandit (captain = broader silhouette).
	# Slightly squarer shoulders so the codex thumbnail reads "officer" not "rogue".
	cloak_pts = [
		(int(W * 0.02), int(W * 0.98)), (int(W * 0.06), int(W * 0.62)),
		(int(W * 0.16), int(W * 0.54)), (int(W * 0.30), int(W * 0.50)),
		(int(W * 0.70), int(W * 0.50)), (int(W * 0.84), int(W * 0.54)),
		(int(W * 0.94), int(W * 0.62)), (int(W * 0.98), int(W * 0.98)),
	]
	_draw_painter_blob(draw, cloak_pts, LEATHER_DK, seed + 1, blob_r=26)

	# 2) Pauldron rank-stripe (right shoulder) — purple-leather captain insignia.
	# This is the silhouette differentiator from bandit_hooded at 30m.
	pauld_pts = [
		(int(W * 0.66), int(W * 0.50)), (int(W * 0.78), int(W * 0.48)),
		(int(W * 0.86), int(W * 0.54)), (int(W * 0.84), int(W * 0.62)),
		(int(W * 0.74), int(W * 0.62)), (int(W * 0.66), int(W * 0.58)),
	]
	_draw_painter_blob(draw, pauld_pts, LEATHER_PURP, seed + 2, blob_r=18)
	# Brass rivets along the pauldron rim.
	for k in range(4):
		t = (k + 0.5) / 4.0
		px = int(W * (0.68 + t * 0.16))
		py = int(W * (0.51 + math.sin(t * math.pi) * -0.02))
		col = (BRASS_LT[0], BRASS_LT[1], BRASS_LT[2], 230)
		draw.ellipse((px - 5, py - 5, px + 5, py + 5), fill=col)

	# 3) Chest crossed-daggers emblem — matches captain_seal.png so the
	# codex face + the trophy item share a motif.
	emb_cx = cx - int(W * 0.02)
	emb_cy = int(W * 0.78)
	col = (BRASS[0], BRASS[1], BRASS[2], 230)
	# Disc backing
	draw.ellipse((emb_cx - 28, emb_cy - 28, emb_cx + 28, emb_cy + 28), fill=col)
	col = (LEATHER_DK[0], LEATHER_DK[1], LEATHER_DK[2], 220)
	draw.ellipse((emb_cx - 24, emb_cy - 24, emb_cx + 24, emb_cy + 24), fill=col)
	# Crossed daggers (two thin rectangles rotated 45 / -45)
	col = (BRASS_LT[0], BRASS_LT[1], BRASS_LT[2], 240)
	# diagonal 1 (top-left -> bottom-right)
	draw.line(
		(emb_cx - 18, emb_cy - 18, emb_cx + 18, emb_cy + 18),
		fill=col, width=5,
	)
	# diagonal 2 (top-right -> bottom-left)
	draw.line(
		(emb_cx + 18, emb_cy - 18, emb_cx - 18, emb_cy + 18),
		fill=col, width=5,
	)
	# Hilts (tiny bronze bulbs at each blade tip-end) — gives the daggers
	# a hilted read at thumbnail size.
	for hx, hy in (
		(emb_cx - 18, emb_cy - 18), (emb_cx + 18, emb_cy + 18),
		(emb_cx + 18, emb_cy - 18), (emb_cx - 18, emb_cy + 18),
	):
		col = (BRASS[0], BRASS[1], BRASS[2], 240)
		draw.ellipse((hx - 4, hy - 4, hx + 4, hy + 4), fill=col)

	# 4) Hood — wider-brimmed feathered tricorne shape (captain's hat),
	# silhouette-distinct from bandit_hooded's plain pointed hood.
	hood_pts = [
		(int(W * 0.16), int(W * 0.62)), (int(W * 0.10), int(W * 0.40)),
		(int(W * 0.18), int(W * 0.22)), (int(W * 0.32), int(W * 0.12)),
		(int(W * 0.44), int(W * 0.04)),  # left brim peak
		(int(W * 0.50), int(W * 0.08)),
		(int(W * 0.56), int(W * 0.04)),  # right brim peak
		(int(W * 0.68), int(W * 0.12)),
		(int(W * 0.82), int(W * 0.22)),
		(int(W * 0.90), int(W * 0.40)),
		(int(W * 0.84), int(W * 0.62)),
		(int(W * 0.66), int(W * 0.58)),
		(int(W * 0.60), int(W * 0.50)),
		(int(W * 0.40), int(W * 0.50)),
		(int(W * 0.34), int(W * 0.58)),
	]
	_draw_painter_blob(draw, hood_pts, INK_LT, seed + 3, blob_r=22)

	# Hat-band (wine ribbon under brim) — captain rank detail.
	band_pts = [
		(int(W * 0.18), int(W * 0.22)),
		(int(W * 0.50), int(W * 0.20)),
		(int(W * 0.82), int(W * 0.22)),
		(int(W * 0.78), int(W * 0.26)),
		(int(W * 0.50), int(W * 0.28)),
		(int(W * 0.22), int(W * 0.26)),
	]
	_draw_painter_blob(draw, band_pts, WINE, seed + 4, blob_r=10)

	# Single feather plume (right side of hat) — captain flair.
	feather_pts = [
		(int(W * 0.78), int(W * 0.18)),
		(int(W * 0.86), int(W * 0.10)),
		(int(W * 0.92), int(W * 0.04)),
		(int(W * 0.90), int(W * 0.12)),
		(int(W * 0.84), int(W * 0.20)),
	]
	_draw_painter_blob(draw, feather_pts, CRIMSON, seed + 5, blob_r=10)
	# Feather quill spine (single ink line)
	col = (INK[0], INK[1], INK[2], 200)
	draw.line(
		(int(W * 0.78), int(W * 0.18), int(W * 0.92), int(W * 0.04)),
		fill=col, width=3,
	)

	# 5) Face — visible (no scarf-over-mouth, captain intimidates by being seen).
	face_pts = [
		(int(W * 0.34), int(W * 0.58)),
		(int(W * 0.36), int(W * 0.42)),
		(int(W * 0.42), int(W * 0.30)),
		(int(W * 0.50), int(W * 0.28)),
		(int(W * 0.58), int(W * 0.30)),
		(int(W * 0.64), int(W * 0.42)),
		(int(W * 0.66), int(W * 0.58)),
		(int(W * 0.50), int(W * 0.62)),
	]
	_draw_painter_blob(draw, face_pts, SKIN_DK, seed + 6, blob_r=14)
	# Skin highlight on cheekbones / brow bridge
	skin_pts = [
		(int(W * 0.40), int(W * 0.42)),
		(int(W * 0.46), int(W * 0.36)),
		(int(W * 0.54), int(W * 0.36)),
		(int(W * 0.60), int(W * 0.42)),
		(int(W * 0.56), int(W * 0.48)),
		(int(W * 0.44), int(W * 0.48)),
	]
	_draw_painter_blob(draw, skin_pts, SKIN_HUMAN, seed + 7, blob_r=10)

	# 6) Eyes — narrowed (older / weathered captain stare).
	for ex_off in (-0.07, 0.07):
		ex = cx + int(W * ex_off)
		ey = int(W * 0.46)
		# Eye socket shadow
		col = (INK[0], INK[1], INK[2], 250)
		draw.ellipse((ex - 14, ey - 5, ex + 14, ey + 5), fill=col)
		# Sclera (narrowed — only thin slit visible)
		col = (240, 240, 230, 250)
		draw.ellipse((ex - 9, ey - 2, ex + 9, ey + 2), fill=col)
		# Iron-grey iris (captain authority colour)
		col = (90, 90, 95, 250)
		draw.ellipse((ex - 4, ey - 2, ex + 4, ey + 2), fill=col)
		# Pupil
		col = (INK[0], INK[1], INK[2], 250)
		draw.ellipse((ex - 2, ey - 1, ex + 2, ey + 1), fill=col)

	# Hooded brow shadow
	col = (INK[0], INK[1], INK[2], 200)
	draw.line(
		(int(W * 0.36), int(W * 0.42), int(W * 0.46), int(W * 0.40)),
		fill=col, width=4,
	)
	draw.line(
		(int(W * 0.54), int(W * 0.40), int(W * 0.64), int(W * 0.42)),
		fill=col, width=4,
	)

	# 7) Cheek scar (single thin line, child-safe — no detailed wound).
	col = (SCAR_PINK[0], SCAR_PINK[1], SCAR_PINK[2], 220)
	draw.line(
		(int(W * 0.56), int(W * 0.50), int(W * 0.62), int(W * 0.58)),
		fill=col, width=3,
	)

	# 8) Stubble / weathered jaw line — same wine-ink dab pattern as
	# bandit_hooded but heavier (captain is older).
	for k in range(14):
		t = k / 14.0
		x = int(W * (0.40 + t * 0.20))
		y = int(W * (0.60 + math.sin(t * math.pi * 2) * 0.012))
		col = (INK_LT[0], INK_LT[1], INK_LT[2], r.randint(150, 220))
		s = r.randint(2, 4)
		draw.ellipse((x - s, y - s, x + s, y + s), fill=col)

	# 9) Frayed cloak edge speckle (parchment dust at collar) — same
	# weathered-detail flourish as bandit_hooded so the two read in family.
	col = (PARCHMENT_DK[0], PARCHMENT_DK[1], PARCHMENT_DK[2], 160)
	for k in range(22):
		t = k / 22.0
		x = int(W * (0.18 + t * 0.64))
		y = int(W * (0.62 + math.sin(t * math.pi) * -0.04))
		s = r.randint(2, 4)
		draw.ellipse((x - s, y - s, x + s, y + s), fill=col)


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
	"""Painterly speckle around the rounded-rect edge (matches enemy portraits)."""
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


# Background gradient picked to harmonise with bandit_hooded
# (70,60,50)->(28,22,18) but pushed slightly toward wine/purple so the
# captain is silhouette-distinct against the regular bandit's portrait
# in side-by-side codex panels.
SPEC = {
	"seed": 7509,
	"bg_top": (90, 56, 70),    # purple-wine top (vs bandit's 70,60,50 charcoal-leather)
	"bg_bot": (32, 18, 28),    # deeper ink-purple bottom
}


def render_one(out_dir):
	img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
	draw = ImageDraw.Draw(img)
	_paint_bg_gradient(draw, SPEC["bg_top"], SPEC["bg_bot"], SPEC["seed"])
	_paint_bandit_captain(draw, SPEC["seed"] + 17)
	_add_painterly_frame(draw, SPEC["seed"] + 91)
	mask = _rounded_mask()
	out_path = os.path.join(out_dir, "bandit_captain.png")
	_finalise(img, mask, out_path)
	return out_path


def main(argv):
	if len(argv) < 2:
		print("usage: gen_bandit_captain_portrait.py <out_dir>", file=sys.stderr)
		return 2
	out_dir = argv[1]
	os.makedirs(out_dir, exist_ok=True)
	path = render_one(out_dir)
	print(f"  wrote {path}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main(sys.argv))
