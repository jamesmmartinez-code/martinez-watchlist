"""
Eldoria Art Director — Sign Banner Generator
Generates painterly wooden signposts for the three origin towns
(Briarwood, Whisperwood, Crystal Caves) that lacked sign_to_*.png
counterparts. Style matches sign_to_silverleaf.png and stays in
THEME.md §3 palette (sunset gold, moss green, parchment, ink).

Output: 512x256 RGBA PNGs.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import random
import os

# THEME.md §3 anchors
WOOD_DARK    = (76, 56, 40)
WOOD_MID     = (104, 76, 50)
WOOD_LIGHT   = (140, 102, 64)
WOOD_GRAIN   = (60, 42, 28)
PARCHMENT    = (217, 201, 155)
SUNSET_GOLD  = (255, 216, 107)
INK          = (14, 10, 14)
MOSS         = (74, 112, 56)
JADE_PALE    = (200, 224, 200)
CRYSTAL_CYAN = (101, 223, 229)
WINE         = (140, 32, 32)
IRON_NAIL    = (60, 50, 44)

W, H = 512, 256

SUPER = 2  # supersample for smooth painterly edges

SERIF_PATH       = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
SERIF_LIGHT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf"


def jitter(c, amt=8):
    return tuple(max(0, min(255, v + random.randint(-amt, amt))) for v in c[:3])


def wood_plank(draw, box, base=WOOD_MID, light=WOOD_LIGHT, dark=WOOD_DARK):
    """Fill a rounded box with vertical wood-grain shading."""
    x0, y0, x1, y1 = box
    # base fill
    draw.rounded_rectangle(box, radius=12, fill=base)
    # grain stripes — irregular, hand-painted feel
    rng = random.Random(hash((x0, y0, x1, y1)) & 0xffffffff)
    for _ in range((x1 - x0) // 4):
        gx = rng.randint(x0 + 4, x1 - 4)
        c = light if rng.random() > 0.5 else dark
        c = jitter(c, 6)
        h_off = rng.randint(-2, 2)
        draw.line([(gx, y0 + 6 + h_off), (gx, y1 - 6 + h_off)], fill=c + (rng.randint(60, 130),) if len(c) == 3 else c, width=1)
    # darker top + bottom shading (carved bevel)
    for i in range(4):
        a = 90 - i * 18
        draw.line([(x0 + 6, y0 + i), (x1 - 6, y0 + i)], fill=dark + (a,), width=1)
        draw.line([(x0 + 6, y1 - i), (x1 - 6, y1 - i)], fill=dark + (a,), width=1)


def make_sign(town_name, subtitle, accent_color, arrow_dir="left", out_path=""):
    """Render a 512x256 painterly signpost. arrow_dir = 'left' or 'right'."""
    sw, sh = W * SUPER, H * SUPER
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")

    # ---- post (vertical) ----
    post_x_center = sw // 2
    post_w = 22 * SUPER
    post_top = int(sh * 0.62)
    post_bottom = sh - 4 * SUPER
    post_box = (post_x_center - post_w // 2, post_top, post_x_center + post_w // 2, post_bottom)
    wood_plank(d, post_box, WOOD_MID, WOOD_LIGHT, WOOD_DARK)

    # ---- plank (horizontal sign) ----
    p_left = 14 * SUPER
    p_right = sw - 14 * SUPER
    p_top = 24 * SUPER
    p_bot = int(sh * 0.62) + 8 * SUPER

    # arrow tip — cut a triangular notch on chosen side, draw the rest as plank
    plank_box = (p_left, p_top, p_right, p_bot)
    wood_plank(d, plank_box, WOOD_MID, WOOD_LIGHT, WOOD_DARK)

    # arrow accent triangle (jade/cyan/moss tip)
    tip_w = 32 * SUPER
    if arrow_dir == "left":
        tri = [(p_left + 2 * SUPER, (p_top + p_bot) // 2),
               (p_left + tip_w, p_top + 8 * SUPER),
               (p_left + tip_w, p_bot - 8 * SUPER)]
        # darker accent fill
        d.polygon(tri, fill=accent_color)
        # subtle inner highlight
        ihl = [(p_left + 6 * SUPER, (p_top + p_bot) // 2),
               (p_left + tip_w - 4 * SUPER, p_top + 14 * SUPER),
               (p_left + tip_w - 4 * SUPER, p_bot - 14 * SUPER)]
        d.polygon(ihl, fill=tuple(min(255, c + 25) for c in accent_color))
    else:
        tri = [(p_right - 2 * SUPER, (p_top + p_bot) // 2),
               (p_right - tip_w, p_top + 8 * SUPER),
               (p_right - tip_w, p_bot - 8 * SUPER)]
        d.polygon(tri, fill=accent_color)
        ihl = [(p_right - 6 * SUPER, (p_top + p_bot) // 2),
               (p_right - tip_w + 4 * SUPER, p_top + 14 * SUPER),
               (p_right - tip_w + 4 * SUPER, p_bot - 14 * SUPER)]
        d.polygon(ihl, fill=tuple(min(255, c + 25) for c in accent_color))

    # iron nails (4 corners)
    nail_r = 4 * SUPER
    n_inset = 18 * SUPER
    if arrow_dir == "left":
        nails_xy = [(p_right - n_inset, p_top + n_inset),
                    (p_right - n_inset, p_bot - n_inset),
                    (p_left + tip_w + 8 * SUPER, p_top + n_inset),
                    (p_left + tip_w + 8 * SUPER, p_bot - n_inset)]
    else:
        nails_xy = [(p_left + n_inset, p_top + n_inset),
                    (p_left + n_inset, p_bot - n_inset),
                    (p_right - tip_w - 8 * SUPER, p_top + n_inset),
                    (p_right - tip_w - 8 * SUPER, p_bot - n_inset)]
    for nx, ny in nails_xy:
        d.ellipse((nx - nail_r, ny - nail_r, nx + nail_r, ny + nail_r),
                  fill=IRON_NAIL, outline=jitter(IRON_NAIL, 12))
        d.ellipse((nx - nail_r + 1, ny - nail_r + 1, nx - nail_r + 4, ny - nail_r + 4),
                  fill=(120, 110, 102, 180))

    # ---- text ----
    try:
        fnt_title = ImageFont.truetype(SERIF_PATH, 56 * SUPER)
        fnt_sub   = ImageFont.truetype(SERIF_LIGHT_PATH, 24 * SUPER)
    except Exception:
        fnt_title = ImageFont.load_default()
        fnt_sub   = ImageFont.load_default()

    # title
    title = town_name
    bbox = d.textbbox((0, 0), title, font=fnt_title)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    text_x = (sw - tw) // 2
    if arrow_dir == "left":
        text_x += 8 * SUPER  # nudge away from the tip
    else:
        text_x -= 8 * SUPER
    text_y = p_top + 14 * SUPER
    # ink shadow
    d.text((text_x + 2, text_y + 3), title, font=fnt_title, fill=(0, 0, 0, 200))
    # gold stroke (cream)
    for dx, dy in [(-2,0),(2,0),(0,-2),(0,2)]:
        d.text((text_x+dx, text_y+dy), title, font=fnt_title, fill=(40, 28, 16, 230))
    d.text((text_x, text_y), title, font=fnt_title, fill=SUNSET_GOLD + (255,))

    # subtitle
    sbbox = d.textbbox((0, 0), subtitle, font=fnt_sub)
    sw_, sh_ = sbbox[2] - sbbox[0], sbbox[3] - sbbox[1]
    sx = (sw - sw_) // 2
    if arrow_dir == "left":
        sx += 8 * SUPER
    else:
        sx -= 8 * SUPER
    sy = text_y + th + 14 * SUPER
    d.text((sx + 1, sy + 2), subtitle, font=fnt_sub, fill=(0, 0, 0, 160))
    d.text((sx, sy), subtitle, font=fnt_sub, fill=(40, 28, 16, 235))

    # ---- painterly soften ----
    # tiny gaussian blur to break crisp vector look (per THEME.md §5)
    img = img.filter(ImageFilter.GaussianBlur(radius=0.6 * SUPER))
    # add a faint moss/lichen speckle on the plank for "lived-in" feel (§1)
    rng = random.Random(hash(town_name) & 0xffffffff)
    for _ in range(60):
        sx_ = rng.randint(p_left + 12 * SUPER, p_right - 12 * SUPER)
        sy_ = rng.randint(p_top + 6 * SUPER, p_bot - 6 * SUPER)
        cc = MOSS if rng.random() > 0.5 else WOOD_DARK
        a = rng.randint(15, 60)
        d2 = ImageDraw.Draw(img, "RGBA")
        rr = rng.randint(1, 3) * SUPER
        d2.ellipse((sx_, sy_, sx_ + rr, sy_ + rr), fill=cc + (a,))

    # downsample with LANCZOS — painterly result
    out = img.resize((W, H), Image.LANCZOS)
    out.save(out_path, "PNG", optimize=True)
    print(f"wrote {out_path} ({os.path.getsize(out_path)} bytes)")


if __name__ == "__main__":
    out_dir = "/dev/shm/work/banners_out"
    os.makedirs(out_dir, exist_ok=True)

    make_sign(
        town_name="Briarwood",
        subtitle="Hearth & Home",
        accent_color=PARCHMENT,
        arrow_dir="right",
        out_path=os.path.join(out_dir, "sign_to_briarwood.png"),
    )
    make_sign(
        town_name="Whisperwood",
        subtitle="Beware the Drums",
        accent_color=MOSS,
        arrow_dir="left",
        out_path=os.path.join(out_dir, "sign_to_whisperwood.png"),
    )
    make_sign(
        town_name="Crystal Caves",
        subtitle="Echoes Below",
        accent_color=CRYSTAL_CYAN,
        arrow_dir="left",
        out_path=os.path.join(out_dir, "sign_to_crystal_caves.png"),
    )
