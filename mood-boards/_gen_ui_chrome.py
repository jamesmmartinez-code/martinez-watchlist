#!/usr/bin/env python3
"""
mood-boards/_gen_ui_chrome.py — Eldoria UI chrome reference.

THEME.md anchor: §1 painterly hand-painted, §3 palette (parchment +
wood + bronze + wine), §5 Typography & UI (medieval serif, hand-painted
banner look, slight irregularity, wood-and-iron frames; banned styles:
Material/iOS, glassmorphism, sharp corners on every panel).

Schematic 2x2 mood-board cell grid showing the assembled UI chrome look
(not just isolated atlas pieces) so UI agents can cite ONE panel
instead of three:

  Cell 1 (top-left)    - ANATOMY OF A PANEL
                         labelled parchment + wood-and-iron frame +
                         brushstroke border + corner-iron studs +
                         ornate divider, with arrow-call-outs.
  Cell 2 (top-right)   - DIVIDERS (three variants)
                         small (between fields), medium (section break),
                         large (chapter break with fleuron).
  Cell 3 (bottom-left) - BUTTON STATES
                         idle / hover / pressed / disabled in a row,
                         same wood-frame primitive, modulated.
  Cell 4 (bottom-right) - COMPOSED QUEST PANEL
                         blackletter-spec'd title + serif body + ornate
                         divider + CTA button on a parchment slate,
                         demonstrating how the primitives compose.

Pattern follows mood-boards/_generate.py,
mood-boards/_gen_architecture_palette.py, and
mood-boards/_gen_magic_glow_reference.py - Pillow-only, pinned
random.seed, byte-stable on re-run. THEME §3 colours imported verbatim
from _generate.py.

Usage:
    python3 mood-boards/_gen_ui_chrome.py
"""
from PIL import Image, ImageDraw, ImageFont
import os
import random


def hex_to_rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


# THEME §3 canon palette (mirrored from mood-boards/_generate.py)
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

# Derivative tones - explicit palette band, no new canonical hues.
DARK_WOOD    = (84, 56, 32)
MID_WOOD     = (138, 92, 50)
LIGHT_WOOD   = (190, 142, 86)
PARCHMENT_LT = (228, 212, 168)
PARCHMENT_DK = (180, 158, 110)
IRON_DK      = (44, 40, 44)
IRON_LT      = (110, 108, 116)
BRONZE_LT    = (200, 156, 92)
INK_FADED    = (60, 40, 24)


def get_font(size, bold=False):
    paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf" if bold
        else "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ]
    for p in paths:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def grain(draw, x0, y0, x1, y1, base_rgb, count=140, jitter=18):
    """THEME §1 'painterly' nod - speckle the fill with +/- jitter brightness."""
    r, g, b = base_rgb
    if x1 - x0 < 4 or y1 - y0 < 4:
        return
    for _ in range(count):
        rx = random.randint(x0 + 1, x1 - 1)
        ry = random.randint(y0 + 1, y1 - 1)
        br = random.randint(-jitter, jitter)
        draw.point((rx, ry), fill=(
            max(0, min(255, r + br)),
            max(0, min(255, g + br)),
            max(0, min(255, b + br)),
        ))


def _cell_frame(draw, x0, y0, x1, y1, label, font_label):
    draw.rectangle([x0, y0, x1, y1], fill=PARCHMENT, outline=DARK_WOOD, width=3)
    draw.rectangle([x0 + 6, y0 + 6, x1 - 6, y1 - 6], outline=HAMMERED_BRONZE, width=1)
    plate_h = 28
    draw.rectangle([x0 + 6, y1 - plate_h - 6, x1 - 6, y1 - 6],
                   fill=DARK_WOOD, outline=HAMMERED_BRONZE, width=1)
    bbox = draw.textbbox((0, 0), label, font=font_label)
    tw = bbox[2] - bbox[0]
    cx = (x0 + x1) // 2
    draw.text((cx - tw // 2, y1 - plate_h - 2), label,
              fill=PARCHMENT, font=font_label)


# Primitive: parchment + wood frame panel
def _draw_parchment_panel(draw, x0, y0, x1, y1,
                          parch=PARCHMENT, frame=DARK_WOOD,
                          inner=BRONZE_LT, studs=True, brush_irreg=True,
                          radius=10, modulate=1.0, grain_count=180):
    """Eldoria UI primitive: aged parchment, wood-and-iron frame, rounded
    corners (THEME §5: panels must have 4-6+ px corner radius and a
    parchment/wood border; banned: sharp corners everywhere, glassmorphism,
    Material/iOS flat).

    `modulate` (0.55..1.15) tints the parchment darker (pressed) or
    lighter (hover) - used by BUTTON STATES.
    """
    pr, pg, pb = parch
    pr = max(0, min(255, int(pr * modulate)))
    pg = max(0, min(255, int(pg * modulate)))
    pb = max(0, min(255, int(pb * modulate)))
    parch_mod = (pr, pg, pb)

    try:
        draw.rounded_rectangle([x0, y0, x1, y1], radius=radius,
                               fill=parch_mod, outline=frame, width=3)
    except AttributeError:
        draw.rectangle([x0, y0, x1, y1], fill=parch_mod, outline=frame, width=3)

    try:
        draw.rounded_rectangle([x0 + 6, y0 + 6, x1 - 6, y1 - 6],
                               radius=max(4, radius - 4), outline=inner, width=1)
    except AttributeError:
        draw.rectangle([x0 + 6, y0 + 6, x1 - 6, y1 - 6], outline=inner, width=1)

    grain(draw, x0 + 8, y0 + 8, x1 - 8, y1 - 8, parch_mod,
          count=grain_count, jitter=14)

    if brush_irreg:
        for side in ("top", "bot", "lft", "rgt"):
            for _ in range(3):
                if side in ("top", "bot"):
                    nx = random.randint(x0 + 14, x1 - 14)
                    ny = y0 + 1 if side == "top" else y1 - 2
                    draw.line([(nx, ny), (nx + random.randint(-2, 2),
                                          ny + (1 if side == "top" else -1))],
                              fill=INK_FADED, width=1)
                else:
                    ny = random.randint(y0 + 14, y1 - 14)
                    nx = x0 + 1 if side == "lft" else x1 - 2
                    draw.line([(nx, ny), (nx + (1 if side == "lft" else -1),
                                          ny + random.randint(-2, 2))],
                              fill=INK_FADED, width=1)

    if studs:
        s = 5
        for (sx, sy) in [(x0 + 10, y0 + 10), (x1 - 10, y0 + 10),
                         (x0 + 10, y1 - 10), (x1 - 10, y1 - 10)]:
            draw.ellipse([sx - s, sy - s, sx + s, sy + s],
                         fill=IRON_DK, outline=INK_BLACK, width=1)
            draw.ellipse([sx - 2, sy - 2, sx + 2, sy + 2], fill=IRON_LT)


# Primitive: ornate divider
def _draw_divider(draw, x0, x1, cy, variant="medium"):
    line_color = HAMMERED_BRONZE
    accent = WINE_CRIMSON

    if variant == "small":
        draw.line([(x0, cy), (x1, cy)], fill=line_color, width=1)
        cx = (x0 + x1) // 2
        draw.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=accent)
        return

    cx = (x0 + x1) // 2
    if variant == "medium":
        gap = 22
        draw.line([(x0, cy), (cx - gap, cy)], fill=line_color, width=2)
        draw.line([(cx + gap, cy), (x1, cy)], fill=line_color, width=2)
        draw.polygon([(cx, cy - 8), (cx + 14, cy), (cx, cy + 8), (cx - 14, cy)],
                     fill=accent, outline=line_color)
        draw.line([(cx - 8, cy), (cx + 8, cy)], fill=PARCHMENT_LT, width=1)
        return

    # large - fleuron + arabesque flanks
    gap = 60
    draw.line([(x0, cy), (cx - gap, cy)], fill=line_color, width=2)
    draw.line([(cx + gap, cy), (x1, cy)], fill=line_color, width=2)
    for sign in (-1, 1):
        for k in range(3):
            ax = cx + sign * (gap - 14 - k * 8)
            ay = cy + (-1 if k % 2 == 0 else 1) * (3 + k)
            draw.ellipse([ax - 2, ay - 2, ax + 2, ay + 2], fill=line_color)
    draw.polygon([(cx, cy - 14), (cx + 22, cy), (cx, cy + 14), (cx - 22, cy)],
                 fill=accent, outline=line_color)
    draw.line([(cx - 14, cy), (cx + 14, cy)], fill=PARCHMENT_LT, width=1)
    draw.line([(cx, cy - 8), (cx, cy + 8)], fill=PARCHMENT_LT, width=1)
    for sign in (-1, 1):
        bx = cx + sign * 22
        draw.polygon([(bx, cy - 1), (bx + sign * 8, cy - 4),
                      (bx + sign * 4, cy + 2)],
                     fill=line_color)


# Primitive: button (parchment+wood panel sized for a CTA)
def _draw_button(draw, x0, y0, x1, y1, label, font, state="idle"):
    if state == "idle":
        modulate = 0.96; frame = DARK_WOOD; text_color = INK_BLACK
    elif state == "hover":
        modulate = 1.10; frame = HAMMERED_BRONZE; text_color = INK_BLACK
    elif state == "pressed":
        modulate = 0.78; frame = IRON_DK; text_color = WINE_CRIMSON
    elif state == "disabled":
        modulate = 0.85; frame = STONE_GREYBLUE; text_color = (110, 100, 90)
    else:
        modulate = 1.0; frame = DARK_WOOD; text_color = INK_BLACK

    _draw_parchment_panel(
        draw, x0, y0, x1, y1,
        parch=PARCHMENT, frame=frame, inner=HAMMERED_BRONZE,
        studs=True, brush_irreg=(state != "disabled"), radius=8,
        modulate=modulate, grain_count=110,
    )

    bbox = draw.textbbox((0, 0), label, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    cx = (x0 + x1) // 2
    cy = (y0 + y1) // 2
    if state == "pressed":
        cy += 1
    if state != "disabled":
        draw.text((cx - tw // 2 + 1, cy - th // 2 + 1), label,
                  fill=PARCHMENT_DK, font=font)
    draw.text((cx - tw // 2, cy - th // 2), label, fill=text_color, font=font)

    if state == "disabled":
        for off in range(-(y1 - y0), x1 - x0, 9):
            sx0 = max(x0 + 4, x0 + off); sy0 = y0 + 4
            sx1 = min(x1 - 4, x0 + off + (y1 - y0) - 8)
            sy1 = y1 - 4
            if sx1 > sx0:
                draw.line([(sx0, sy0), (sx1, sy1)],
                          fill=(170, 150, 110), width=1)


# Cells
def _draw_anatomy_cell(draw, img, x0, y0, x1, y1, fonts):
    f_caption = fonts["caption"]
    f_label = fonts["label"]
    f_body = fonts["body"]

    panel_x0 = x0 + 24
    panel_y0 = y0 + 28
    panel_x1 = x0 + 240
    panel_y1 = y1 - 20
    _draw_parchment_panel(
        draw, panel_x0, panel_y0, panel_x1, panel_y1,
        parch=PARCHMENT, frame=DARK_WOOD, inner=HAMMERED_BRONZE,
        studs=True, brush_irreg=True, radius=12,
        modulate=1.0, grain_count=200,
    )
    draw.text((panel_x0 + 18, panel_y0 + 16), "QUEST",
              fill=INK_BLACK, font=f_label)
    _draw_divider(draw, panel_x0 + 18, panel_x1 - 18,
                  panel_y0 + 50, variant="medium")
    draw.text((panel_x0 + 18, panel_y0 + 64), "Find the lost lantern.",
              fill=INK_FADED, font=f_body)
    draw.text((panel_x0 + 18, panel_y0 + 84), "Reward: 12 silver.",
              fill=INK_FADED, font=f_body)

    callouts = [
        ((panel_x0 + 8, panel_y0 + 8),
         (panel_x1 + 60, panel_y0 + 4),
         "iron stud (corner)"),
        ((panel_x1 - 8, panel_y0 + (panel_y1 - panel_y0) // 2),
         (panel_x1 + 60, panel_y0 + (panel_y1 - panel_y0) // 2 - 22),
         "wood-and-iron frame"),
        ((panel_x0 + 14, panel_y0 + 50),
         (panel_x1 + 60, panel_y0 + 56),
         "ornate divider"),
        ((panel_x0 + 60, panel_y0 + 80),
         (panel_x1 + 60, panel_y0 + 96),
         "aged parchment"),
        ((panel_x1 - 6, panel_y1 - 14),
         (panel_x1 + 60, panel_y1 - 30),
         "brushstroke edge"),
    ]
    for src, dst, txt in callouts:
        draw.line([src, dst], fill=DARK_WOOD, width=1)
        draw.ellipse([src[0] - 2, src[1] - 2, src[0] + 2, src[1] + 2],
                     fill=WINE_CRIMSON)
        draw.text((dst[0] + 6, dst[1] - 8), txt,
                  fill=INK_BLACK, font=f_caption)


def _draw_dividers_cell(draw, img, x0, y0, x1, y1, fonts):
    f_caption = fonts["caption"]
    inner_x0 = x0 + 28
    inner_x1 = x1 - 28
    rows = [
        ("SMALL  -  between fields",        "small",  y0 + 60),
        ("MEDIUM  -  section break",        "medium", y0 + 130),
        ("LARGE  -  chapter / quest break", "large",  y0 + 210),
    ]
    for label, variant, cy in rows:
        draw.text((inner_x0, cy - 24), label,
                  fill=INK_BLACK, font=f_caption)
        _draw_divider(draw, inner_x0, inner_x1, cy, variant=variant)


def _draw_button_states_cell(draw, img, x0, y0, x1, y1, fonts):
    f_caption = fonts["caption"]
    f_btn = fonts["button"]
    states = ["idle", "hover", "pressed", "disabled"]
    pad_x = 18
    pad_y = 28
    cell_w = (x1 - x0 - 2 * pad_x - 3 * 14) // 4
    btn_top = y0 + pad_y + 18
    btn_h = 56
    for i, state in enumerate(states):
        bx0 = x0 + pad_x + i * (cell_w + 14)
        bx1 = bx0 + cell_w
        _draw_button(draw, bx0, btn_top, bx1, btn_top + btn_h,
                     "Accept", f_btn, state=state)
        bbox = draw.textbbox((0, 0), state.upper(), font=f_caption)
        tw = bbox[2] - bbox[0]
        cx = (bx0 + bx1) // 2
        draw.text((cx - tw // 2, btn_top + btn_h + 8), state.upper(),
                  fill=INK_BLACK, font=f_caption)
    # Second row: secondary CTA themed via wine veil layer.
    for i, state in enumerate(["idle", "hover", "pressed", "disabled"]):
        bx0 = x0 + pad_x + i * (cell_w + 14)
        bx1 = bx0 + cell_w
        by0 = btn_top + btn_h + 36
        by1 = by0 + btn_h
        _draw_button(draw, bx0, by0, bx1, by1, "Refuse", f_btn, state=state)
        veil = Image.new("RGBA", (bx1 - bx0, by1 - by0), (140, 32, 32, 36))
        img.paste(veil, (bx0, by0), veil)
    cap_y = btn_top + 2 * btn_h + 50
    draw.text((x0 + pad_x, cap_y),
              "Same primitive, modulated parchment + frame swap.",
              fill=INK_FADED, font=f_caption)
    draw.text((x0 + pad_x, cap_y + 16),
              "Wine-veil themes the secondary CTA - no new hues.",
              fill=INK_FADED, font=f_caption)


def _draw_composed_cell(draw, img, x0, y0, x1, y1, fonts):
    f_title_section = fonts["title"]
    f_body = fonts["body"]
    f_btn = fonts["button"]
    f_caption = fonts["caption"]

    panel_x0 = x0 + 24
    panel_y0 = y0 + 28
    panel_x1 = x1 - 24
    panel_y1 = y1 - 28
    _draw_parchment_panel(
        draw, panel_x0, panel_y0, panel_x1, panel_y1,
        parch=PARCHMENT, frame=DARK_WOOD, inner=HAMMERED_BRONZE,
        studs=True, brush_irreg=True, radius=12,
        modulate=1.0, grain_count=240,
    )
    title = "THE LOST LANTERN"
    bbox = draw.textbbox((0, 0), title, font=f_title_section)
    tw = bbox[2] - bbox[0]
    cx = (panel_x0 + panel_x1) // 2
    draw.text((cx - tw // 2 + 1, panel_y0 + 28 + 1), title,
              fill=PARCHMENT_DK, font=f_title_section)
    draw.text((cx - tw // 2, panel_y0 + 28), title,
              fill=WINE_CRIMSON, font=f_title_section)

    _draw_divider(draw, panel_x0 + 30, panel_x1 - 30,
                  panel_y0 + 76, variant="large")

    body_lines = [
        "Old Maeve's lantern has gone missing.",
        "She believes a goblin took it down the",
        "north path. Bring it back before dusk -",
        "a kind word and twelve silver await.",
    ]
    for i, line in enumerate(body_lines):
        draw.text((panel_x0 + 36, panel_y0 + 100 + i * 22),
                  line, fill=INK_FADED, font=f_body)

    _draw_divider(draw, panel_x0 + 36, panel_x1 - 36,
                  panel_y0 + 188, variant="small")
    objs = ["* North path scouted",
            "* Goblin scout defeated",
            "* Return to Elder Maeve"]
    for i, line in enumerate(objs):
        draw.text((panel_x0 + 36, panel_y0 + 198 + i * 18),
                  line, fill=INK_BLACK, font=f_body)

    btn_h = 40
    btn_y = panel_y1 - btn_h - 14
    btn_w = 140
    bx0 = panel_x0 + 36
    _draw_button(draw, bx0, btn_y, bx0 + btn_w, btn_y + btn_h,
                 "Accept", f_btn, state="idle")
    bx0b = panel_x1 - 36 - btn_w
    _draw_button(draw, bx0b, btn_y, bx0b + btn_w, btn_y + btn_h,
                 "Refuse", f_btn, state="hover")

    draw.text((panel_x0, panel_y1 + 4),
              "title (blackletter-spec'd) + divider + body + bullets + CTAs.",
              fill=INK_BLACK, font=f_caption)


# Main render
def render_ui_chrome():
    random.seed(411)   # pinned - byte-stable output on re-run.

    W, H = 1024, 1024
    img = Image.new("RGB", (W, H), (24, 18, 14))
    draw = ImageDraw.Draw(img)

    header_h = 110
    for y in range(header_h):
        t = y / header_h
        r = int(60 + (140 - 60) * t)
        g = int(40 + (90 - 40) * t)
        b = int(28 + (50 - 28) * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b))

    f_title = get_font(32, True)
    f_subtitle = get_font(20)
    f_section = get_font(20, True)
    f_label = get_font(15, True)
    f_caption = get_font(13)
    f_body = get_font(15)
    f_button = get_font(17, True)

    fonts = {
        "title":   f_section,
        "label":   f_label,
        "caption": f_caption,
        "body":    f_body,
        "button":  f_button,
    }

    draw.text((30, 28), "REALM OF ELDORIA  -  UI CHROME",
              fill=PARCHMENT, font=f_title)
    draw.text((30, 76),
              "THEME.md §5 typography & UI canon. Cite this panel "
              "when designing a new HUD surface.",
              fill=PARCHMENT_LT, font=f_subtitle)

    grid_top = header_h + 30
    grid_bot = H - 60
    margin_x = 30
    cell_pad = 14
    cells_w = W - 2 * margin_x - cell_pad
    cells_h = grid_bot - grid_top - cell_pad
    cell_w = cells_w // 2
    cell_h = cells_h // 2

    grid = [
        ("ANATOMY OF A PANEL",   _draw_anatomy_cell,        0, 0),
        ("ORNATE DIVIDERS",      _draw_dividers_cell,       1, 0),
        ("BUTTON STATES",        _draw_button_states_cell,  0, 1),
        ("COMPOSED QUEST PANEL", _draw_composed_cell,       1, 1),
    ]

    for label, drawer, col, row in grid:
        x0 = margin_x + col * (cell_w + cell_pad)
        y0 = grid_top + row * (cell_h + cell_pad)
        x1 = x0 + cell_w
        y1 = y0 + cell_h
        _cell_frame(draw, x0, y0, x1, y1, label, f_label)
        drawer(draw, img, x0, y0, x1, y1 - 32, fonts)

    draw.text((30, H - 50),
              "Schematic. Painterly UI specimen art belongs under concept/  "
              "-  this board points at decisions.",
              fill=PARCHMENT_LT, font=f_caption)
    draw.text((30, H - 32),
              "auto/art  -  generated procedurally. Edit only by re-running "
              "mood-boards/_gen_ui_chrome.py (seed 411).",
              fill=(170, 150, 120), font=f_caption)

    out_dir = os.path.dirname(os.path.abspath(__file__))
    out_path = os.path.join(out_dir, "ui_chrome.png")
    img.save(out_path, "PNG", optimize=True)
    print("Wrote " + out_path + " (" + str(os.path.getsize(out_path)) + " bytes)")


if __name__ == "__main__":
    render_ui_chrome()
