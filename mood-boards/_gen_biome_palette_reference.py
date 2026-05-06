#!/usr/bin/env python3
"""
mood-boards/_gen_biome_palette_reference.py — Eldoria region palette atlas.

THEME.md anchor: §3 palette canon, §8 architecture/environment, plus the
TOWN_MANIFEST + sigil ATTRIBUTION which already document each region's
dominant hue family. This sheet collapses all of that into ONE reference:
"which 5 colors define <region>, and what's the one-line atmosphere?"

Why this exists: 11 regions ship with sigils (banners/sigils/) and town
banners (banners/*_<region>.png), but the per-region palette band was
spread across MD files. Builder/Environment/Lorekeeper agents now have
a single PNG to cite when picking biome materials, lighting, NPC tints,
or quest-flavor descriptors.

Pattern follows mood-boards/_generate.py — Pillow-only, pinned random seed,
byte-stable on re-run. Uses THEME §3 hexes verbatim where possible; any
derivative tone is annotated. Composites the existing sigil PNGs at 96px
into each row so the atlas mirrors the heraldry already in the repo.

Usage:
    python3 mood-boards/_gen_biome_palette_reference.py
"""
from PIL import Image, ImageDraw, ImageFont
import os
import random

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)))
REPO = os.path.dirname(OUT)
SIGILS = os.path.join(REPO, "eldoria-godot", "assets", "banners", "sigils")


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def get_font(size, bold=False):
    paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf" if bold
        else "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for p in paths:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


# THEME §3 canon palette
SUNSET_GOLD     = hex_to_rgb("FFD86B")
BURNT_ORANGE    = hex_to_rgb("FF8000")
WINE_CRIMSON    = hex_to_rgb("8C2020")
FOREST_MOSS     = hex_to_rgb("4A7038")
PARCHMENT       = hex_to_rgb("D9C99B")
INK_BLACK       = hex_to_rgb("0E0A0E")
HAMMERED_BRONZE = hex_to_rgb("B0742A")
STAG_BLOOD      = hex_to_rgb("A02020")
STONE_GREYBLUE  = hex_to_rgb("7B8693")
FEY_CYAN        = hex_to_rgb("65DFE5")
WARLOCK_PURPLE  = hex_to_rgb("7C3FB0")
FROST_SILVER    = hex_to_rgb("C8E0E5")

# Per-region palettes (5 swatches each, sourced from TOWN_MANIFEST.md +
# sigil ATTRIBUTION.md, kept inside §3 bands). Tone derivatives are
# annotated where they go beyond canon (still inside the palette band).
ICE_BLUE        = hex_to_rgb("AECEDC")   # Frostpeak
STEEL           = hex_to_rgb("6E7785")   # Frostpeak
JADE            = hex_to_rgb("6FA56A")   # Silverleaf
MOON_SILVER     = hex_to_rgb("D8DDE0")   # Silverleaf
SLATE_BLUE      = hex_to_rgb("4E5C70")   # Stormwatch
SEAFOAM         = hex_to_rgb("9ABFB6")   # Stormwatch
SIENNA          = hex_to_rgb("A85420")   # Embergrove
MAGMA_ORANGE    = hex_to_rgb("E04818")   # Embergrove
BONE            = hex_to_rgb("E2D8B6")   # goblins
EMBER_RED       = hex_to_rgb("C03830")   # Ironhold
IRON_DARK       = hex_to_rgb("3A3A40")   # Ironhold
FROST_YELLOW    = hex_to_rgb("E8C84C")   # Dire Wolves
MID_WOOD        = (138, 92, 50)
WHISPER_DEEP    = (74, 96, 60)
CRYSTAL_DEEP    = (28, 32, 60)
BANDIT_LEATHER  = (60, 44, 36)
BANDIT_SHADOW   = (28, 22, 22)
WOLF_FUR_DARK   = (84, 80, 76)
IRON_TIMBER     = (84, 64, 48)

REGIONS = [
    ("briarwood_crest.png", "Briarwood Village", "Friendly hub",
     [FOREST_MOSS, HAMMERED_BRONZE, SUNSET_GOLD, PARCHMENT, MID_WOOD],
     "Timber + thatch hamlet at the forest edge — warm hearth glow at dusk."),
    ("whisperwood_crest.png", "Whisperwood", "Wilderness",
     [FOREST_MOSS, INK_BLACK, WHISPER_DEEP, PARCHMENT, HAMMERED_BRONZE],
     "Dense oak/pine canopy — gold streaks through leaves, distant goblin drums."),
    ("crystal_caves_crest.png", "Crystal Caves", "Dungeon (planned)",
     [FEY_CYAN, WARLOCK_PURPLE, INK_BLACK, FROST_SILVER, CRYSTAL_DEEP],
     "Cool blue glow on jagged crystal walls — echoing drips, ancient runes."),
    ("goldhaven_crest.png", "Goldhaven (capital)", "City",
     [WINE_CRIMSON, SUNSET_GOLD, HAMMERED_BRONZE, PARCHMENT, INK_BLACK],
     "Royal capital — crimson banners on cream stone, gold leaf on every spire."),
    ("ironhold_crest.png", "Ironhold (forge city)", "City",
     [EMBER_RED, IRON_DARK, HAMMERED_BRONZE, BURNT_ORANGE, IRON_TIMBER],
     "Soot-stained timber over hot-iron glow — sparks rain from chimneys."),
    ("silverleaf_crest.png", "Silverleaf (elven grove)", "City",
     [JADE, MOON_SILVER, FROST_SILVER, FOREST_MOSS, PARCHMENT],
     "Vaulted living trees, moon-silver lanterns — quiet, almost reverent."),
    ("stormwatch_crest.png", "Stormwatch Port", "City (coast)",
     [SLATE_BLUE, SEAFOAM, HAMMERED_BRONZE, STONE_GREYBLUE, PARCHMENT],
     "Slate cliffs over cold harbor — wet timber, salt-pitted bronze, gull cries."),
    ("embergrove_crest.png", "Embergrove (desert oasis)", "City",
     [SIENNA, MAGMA_ORANGE, SUNSET_GOLD, PARCHMENT, WINE_CRIMSON],
     "Sunbaked sandstone around a single jade pool — heatwave shimmer at noon."),
    ("frostpeak_crest.png", "Frostpeak Keep", "Garrison (north)",
     [ICE_BLUE, STEEL, FROST_SILVER, STONE_GREYBLUE, INK_BLACK],
     "Snow-capped granite walls, blue shadows, brazier-warm windows in the storm."),
    ("bandits_crest.png", "Bandits", "Hostile faction",
     [STAG_BLOOD, INK_BLACK, BANDIT_LEATHER, HAMMERED_BRONZE, BANDIT_SHADOW],
     "Cold ash camps off the road — leaning planks, no warm light, hidden until late."),
    ("whisperwood_goblins_crest.png", "Whisperwood Goblins", "Hostile faction",
     [FOREST_MOSS, WINE_CRIMSON, BONE, INK_BLACK, HAMMERED_BRONZE],
     "Crude tents, bone fetishes, glowing campfires — feral, never cute."),
    ("dire_wolves_crest.png", "Dire Wolves", "Hostile faction",
     [STONE_GREYBLUE, FROST_YELLOW, INK_BLACK, WOLF_FUR_DARK, PARCHMENT],
     "Gaunt grey-brown coats, scarred — eyes catch firelight at night."),
]


W = 1280
ROW_H = 132
PAD_TOP = 168
PAD_BOTTOM = 56
H = PAD_TOP + ROW_H * len(REGIONS) + PAD_BOTTOM


def grain(draw, x0, y0, x1, y1, base_rgb, count, jitter, rng):
    """THEME §1 painterly hand-painted speckle."""
    r, g, b = base_rgb
    for _ in range(count):
        rx = rng.randint(x0 + 1, max(x0 + 1, x1 - 1))
        ry = rng.randint(y0 + 1, max(y0 + 1, y1 - 1))
        br = rng.randint(-jitter, jitter)
        draw.point((rx, ry), fill=(
            max(0, min(255, r + br)),
            max(0, min(255, g + br)),
            max(0, min(255, b + br)),
        ))


def render():
    rng = random.Random(20260506)
    img = Image.new("RGB", (W, H), (24, 18, 14))
    draw = ImageDraw.Draw(img)

    # Header sunset gradient
    for y in range(140):
        t = y / 140
        r = int(60 + (140 - 60) * t)
        g = int(40 + (90 - 40) * t)
        b = int(28 + (50 - 28) * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    grain(draw, 0, 0, W, 140, (110, 70, 38), 600, 14, rng)

    f_title = get_font(38, True)
    f_sub   = get_font(20)
    f_name  = get_font(22, True)
    f_tag   = get_font(14)
    f_desc  = get_font(15)
    f_hex   = get_font(11)

    draw.text((30, 30),
              "REALM OF ELDORIA - BIOME & FACTION PALETTE ATLAS",
              fill=(245, 220, 165), font=f_title)
    draw.text((30, 78),
              "11 regions x dominant 5-color band x one-line atmosphere.",
              fill=(232, 210, 165), font=f_sub)
    draw.text((30, 104),
              "Cite this file when tinting biome props, picking lights, or "
              "writing flavor copy. THEME §3 + §8.",
              fill=(210, 192, 150), font=f_sub)

    sigil_x = 28
    sigil_size = 96
    name_x = 144
    swatch_x0 = 144
    swatch_y_offset = 60
    swatch_w = 76
    swatch_h = 38
    swatch_gap = 8
    desc_y_offset = 102

    for idx, (sigil_file, name, tag, palette, desc) in enumerate(REGIONS):
        y0 = PAD_TOP + idx * ROW_H
        y1 = y0 + ROW_H - 12

        base = (44, 34, 28) if idx % 2 == 0 else (54, 42, 32)
        draw.rectangle([(20, y0), (W - 20, y1)], fill=base)
        grain(draw, 20, y0, W - 20, y1, base, 240, 10, rng)
        draw.line([(20, y0), (W - 20, y0)], fill=HAMMERED_BRONZE, width=2)

        sigil_path = os.path.join(SIGILS, sigil_file)
        placed = False
        if os.path.exists(sigil_path):
            try:
                s = Image.open(sigil_path).convert("RGBA")
                s = s.resize((sigil_size, sigil_size), Image.LANCZOS)
                img.paste(s, (sigil_x, y0 + (ROW_H - 12 - sigil_size) // 2), s)
                placed = True
            except Exception:
                pass
        if not placed:
            draw.rectangle(
                [(sigil_x, y0 + 12),
                 (sigil_x + sigil_size, y0 + 12 + sigil_size)],
                outline=PARCHMENT, width=2,
            )

        draw.text((name_x, y0 + 12), name, fill=PARCHMENT, font=f_name)
        try:
            nm_w = draw.textlength(name, font=f_name)
        except AttributeError:
            nm_w = len(name) * 10
        draw.text((name_x + int(nm_w) + 14, y0 + 22),
                  "[" + tag + "]", fill=SUNSET_GOLD, font=f_tag)

        sx = swatch_x0
        sy = y0 + swatch_y_offset
        for color in palette:
            draw.rectangle([(sx, sy), (sx + swatch_w, sy + swatch_h)],
                           fill=color)
            grain(draw, sx, sy, sx + swatch_w, sy + swatch_h,
                  color, 60, 12, rng)
            draw.rectangle([(sx, sy), (sx + swatch_w, sy + swatch_h)],
                           outline=INK_BLACK, width=1)
            hx = "#{:02X}{:02X}{:02X}".format(*color)
            draw.text((sx + 3, sy + swatch_h + 3),
                      hx, fill=PARCHMENT, font=f_hex)
            sx += swatch_w + swatch_gap

        draw.text((swatch_x0, y0 + desc_y_offset),
                  desc, fill=(225, 210, 175), font=f_desc)

    draw.text((30, H - 38),
              "Generated by mood-boards/_gen_biome_palette_reference.py - "
              "Pillow-only, deterministic. Edit THEME §3 + this file together; "
              "never hand-edit the PNG.",
              fill=(180, 162, 130), font=f_hex)

    out_path = os.path.join(OUT, "biome_palette_reference.png")
    img.save(out_path, "PNG")
    print("wrote", out_path)


if __name__ == "__main__":
    render()
