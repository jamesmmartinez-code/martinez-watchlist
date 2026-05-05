class_name UITheme
extends RefCounted
##
## Eldoria UITheme — single source of truth for UI styling.
##
## THEME §3 (palette) + §5 (typography) + §8 (parchment + iron-and-wood look).
##
## Use as a static helper from any UI builder:
##
##     UITheme.style_panel_parchment($MyPanel)        # parchment 9-slice background
##     UITheme.style_title_label($MyPanel/Title)      # 24pt gold w/ outline
##     UITheme.style_subtitle_label($MyPanel/Sub)     # 16pt gold
##     UITheme.style_body_label($MyPanel/Body)        # 13pt parchment-cream
##     UITheme.style_hint_label($MyPanel/Hint)        # 12pt dim cream
##     UITheme.style_lock_label($Lock)                # the 🔒 overlay style
##     UITheme.style_iron_button($MyButton)           # wood + iron 9-slice button
##     UITheme.make_toast_label("Renown +5")          # one-call medieval toast
##
## All five panels (inventory, achievements, dialogue tscn override, toast,
## future bestiary) should converge on these helpers — flagged for FIVE
## integrator runs as a CARRY before this run. THEME §3 hand-painted parchment
## look replaces the default Godot grey Panel that all current panels render as.
##
## Strict-mode safe: all `var` use explicit type annotations. Godot 4.6 OK.
##

# ═════════════════════════════════════════════════════════════════════════
# Palette — straight from THEME.md §3
# ═════════════════════════════════════════════════════════════════════════

# Primary (70%)
# REFINE: visual — palette §3 conformance: GOLD (1.00,0.85,0.40)→(1.00,0.85,0.42); exact #FFD86B per THEME §3 (was 0.40, low by ~5%; matches the chest glow_color (1.00,0.86,0.42) shipped in the prior Chest.gd polish run).
const GOLD: Color           = Color(1.00, 0.85, 0.42)   # #FFD86B exact, burnt gold
const SUNSET_ORANGE: Color  = Color(1.00, 0.50, 0.00)   # #FF8000
const CRIMSON: Color        = Color(0.55, 0.13, 0.13)   # #8C2020 wine
const MOSS_GREEN: Color     = Color(0.29, 0.44, 0.22)   # #4A7038
const PARCHMENT: Color      = Color(0.85, 0.79, 0.61)   # #D9C99B aged paper
# REFINE: visual — palette §3 conformance: PARCHMENT_CREAM (0.92,0.85,0.65)→(0.94,0.86,0.62); +0.02 R, +0.01 G, −0.03 B pulls the cream toward the §3 sunset-gold family (matches the NPC nameplate modulate (1.0,0.86,0.46) and Chest.gd glow_color (1.0,0.86,0.42) the recent polish runs converged on). Reads warmer against the new sunset HDRI sky-band.
const PARCHMENT_CREAM: Color= Color(0.94, 0.86, 0.62)   # warmer cream tier, §3 sunset-family
const INK_BLACK: Color      = Color(0.05, 0.04, 0.05)   # #0E0A0E

# Secondary (20%)
# REFINE: visual — palette §3 conformance: BRASS (0.69,0.46,0.16)→(0.69,0.45,0.16); exact #B0742A (#B0=0.690, #74=0.455, #2A=0.165). The 0.46 G channel was ~+0.005 hot — small drift but cumulative across micro-hint labels stacked on every panel.
const BRASS: Color          = Color(0.69, 0.45, 0.16)   # #B0742A exact, hammered bronze
const STAG_BLOOD: Color     = Color(0.63, 0.13, 0.13)   # #A02020
const STONE_BLUE: Color     = Color(0.48, 0.53, 0.58)   # #7B8693

# Magic (10% — sparingly)
const FEY_CYAN: Color       = Color(0.40, 0.87, 0.90)   # #65DFE5
const ARCANE_PURPLE: Color  = Color(0.49, 0.25, 0.69)   # #7C3FB0
const FROST_SILVER: Color   = Color(0.78, 0.88, 0.90)   # #C8E0E5

# Dim helpers
const DIM_GREY: Color       = Color(0.65, 0.60, 0.55)
# REFINE: visual — THEME §3 violation fix: LOCK_DIM was pure desaturated grey (banned by §3 "pure desaturated grey UI palettes"). Replaced with weathered iron tone (0.32,0.27,0.22) — same darkness, with §3 brass-adjacent warm cast. The 🔒 overlay now reads as forged iron, not motherboard plastic.
const LOCK_DIM: Color       = Color(0.32, 0.27, 0.22, 0.88)
# REFINE: visual — THEME §3 violation fix: HINT_DIM was pure white (banned by §3). Replaced with parchment-cream tier at 0.78 alpha — preserves the "dim hint" feel without the §3-banned pure-white channel. Reads warmer against the new sky-band; matches the §3 "we are not making a productivity app" rule.
const HINT_DIM: Color       = Color(0.92, 0.85, 0.65, 0.78)

# ═════════════════════════════════════════════════════════════════════════
# Font sizes — THEME §5 hierarchy
# ═════════════════════════════════════════════════════════════════════════

const FS_TOAST: int    = 28   # screen-center transient
const FS_TITLE: int    = 24   # panel title (e.g., "🎒 Inventory & Equipment")
const FS_HEADER: int   = 22   # secondary header
const FS_SUBTITLE: int = 16   # column header ("— Equipped —", "— Bag —")
const FS_BODY_LG: int  = 14   # button face
const FS_BODY: int     = 13   # main body text, RichTextLabel default
# REFINE: visual — readability lift for kid players: FS_BODY_SM 12→13. Card descriptions and footer hints were the smallest layout-bearing tier; lifting to 13pt matches FS_BODY exactly so multi-line desc blocks read at the same rhythm as body text. THEME §5 typography hierarchy preserved (still smaller than FS_BODY_LG 14 button face).
const FS_BODY_SM: int  = 13   # hint, footer, desc
# REFINE: visual — readability lift for kid players: FS_TINY 11→12. THEME §4 silhouette-distinct rule extends to UI: Alden (9yo) loses sub-12pt text at default camera distance after the 2026-05-05 camera pass widened the rest frame. +1pt micro-hint with no layout reflow risk (same panel slots, single-line hints).
const FS_TINY: int     = 12   # title-hint micro text
const FS_LOCK: int     = 36   # 🔒 overlay glyph
const FS_BAG_GLYPH: int= 22   # bag-slot item glyph

# Outline sizes
# REFINE: visual — outline lift for new HDRI/post-process era: OL_TITLE 4→5. The 2026-05-05 post-processing pass (glow_threshold 0.66→0.58, glow_intensity 0.42→0.55) raised background luminance against panel titles. +1px outline holds contrast without thickening the visible weight at FS_TITLE 24pt. Mirrors the run-12 NPC nameplate outline_size 6→7 lift on the same reasoning.
const OL_TITLE: int  = 5
# REFINE: visual — outline lift for new HDRI/post-process era: OL_NAME 3→4 (same reasoning as OL_TITLE). Card name labels (achievement entries, item names) sit on parchment AND show through to the brighter sunset background at panel edges; +1px holds the §3 "lived-in, weathered" line.
const OL_NAME: int   = 4
# REFINE: visual — outline lift for new HDRI/post-process era: OL_TOAST 6→7. Toasts spawn at anchor_top 0.3 — squarely in the bright sky-band region of the new HDRI panorama where the 2026-05-04 ambient/fog warm pass and the 2026-05-05 post-processing pass both lifted luminance. +1px restores readability against the warmer background. Same delta the run-12 NPC nameplate outline took.
const OL_TOAST: int  = 7
# REFINE: visual — outline lift for new HDRI/post-process era: OL_LOCK 4→5. The 🔒 glyph at FS_LOCK 36pt sits over crest art — the cream outline (PARCHMENT_CREAM-ish) was losing contrast against the brighter sunset bloom. +1px restores the locked-iron read without making the lock cartoonishly heavy.
const OL_LOCK: int   = 5

# ═════════════════════════════════════════════════════════════════════════
# Asset paths (THEME §3 hand-painted parchment + iron + wood)
# Procedural source: scripts/art/make_ui_frames.py — CC0, seed 8131.
# ═════════════════════════════════════════════════════════════════════════

const ASSET_PARCHMENT_LARGE: String = "res://assets/ui/parchment_panel.png"        # 512×512
const ASSET_PARCHMENT_SMALL: String = "res://assets/ui/parchment_panel_small.png"  # 256×256
const ASSET_WOOD_PANEL: String      = "res://assets/ui/wood_panel.png"             # 512×384
const ASSET_BTN_NORMAL: String      = "res://assets/ui/button_normal.png"          # 192×64
const ASSET_BTN_HOVER: String       = "res://assets/ui/button_hover.png"           # 192×64
const ASSET_BTN_PRESSED: String     = "res://assets/ui/button_pressed.png"         # 192×64
const ASSET_DIVIDER_ORNATE: String  = "res://assets/ui/divider_ornate.png"         # 384×24
const ASSET_SCROLL_BANNER: String   = "res://assets/ui/scroll_banner.png"          # 512×128

# 9-slice borders (per ATTRIBUTION.md: 64px on big panels, 32px on smalls)
const PATCH_BIG: int   = 64
const PATCH_SMALL: int = 32
const PATCH_BTN: int   = 16

# ═════════════════════════════════════════════════════════════════════════
# Label helpers
# ═════════════════════════════════════════════════════════════════════════

static func style_title_label(lbl: Label) -> void:
	# 24pt gold w/ ink outline — panel-header level
	lbl.add_theme_font_size_override("font_size", FS_TITLE)
	lbl.add_theme_color_override("font_color", GOLD)
	lbl.add_theme_color_override("font_outline_color", INK_BLACK)
	lbl.add_theme_constant_override("outline_size", OL_TITLE)

static func style_subtitle_label(lbl: Label) -> void:
	# 16pt gold — column / row header
	lbl.add_theme_font_size_override("font_size", FS_SUBTITLE)
	lbl.add_theme_color_override("font_color", GOLD)

static func style_name_label(lbl: Label) -> void:
	# 16pt gold w/ outline — for cards (achievement name, item name)
	lbl.add_theme_font_size_override("font_size", FS_SUBTITLE)
	lbl.add_theme_color_override("font_color", GOLD)
	lbl.add_theme_color_override("font_outline_color", INK_BLACK)
	lbl.add_theme_constant_override("outline_size", OL_NAME)

static func style_count_label(lbl: Label) -> void:
	# 14pt parchment-cream — counters, stats
	lbl.add_theme_font_size_override("font_size", FS_BODY_LG)
	lbl.add_theme_color_override("font_color", PARCHMENT_CREAM)

static func style_body_label(lbl: Label) -> void:
	# 13pt parchment-cream — generic body
	lbl.add_theme_font_size_override("font_size", FS_BODY)
	lbl.add_theme_color_override("font_color", PARCHMENT_CREAM)

static func style_desc_label(lbl: Label) -> void:
	# 12pt parchment-cream — card descriptions
	lbl.add_theme_font_size_override("font_size", FS_BODY_SM)
	lbl.add_theme_color_override("font_color", PARCHMENT_CREAM)

static func style_hint_label(lbl: Label) -> void:
	# 12pt dim white — footer hint
	lbl.add_theme_font_size_override("font_size", FS_BODY_SM)
	lbl.add_theme_color_override("font_color", HINT_DIM)

static func style_micro_hint_label(lbl: Label) -> void:
	# 11pt brass — title-hint line under achievements
	lbl.add_theme_font_size_override("font_size", FS_TINY)
	lbl.add_theme_color_override("font_color", BRASS)

static func style_lock_label(lbl: Label) -> void:
	# 36pt dim w/ cream outline — 🔒 overlay over locked crests
	lbl.add_theme_font_size_override("font_size", FS_LOCK)
	# REFINE: visual — THEME §3 violation fix on lock-label colors. font_color was pure greyscale Color(0.15,0.15,0.15) (banned by §3 "pure desaturated grey UI palettes"). Replaced with weathered-iron tone (0.20,0.16,0.13) — same low luminance, §3-conformant warm cast. font_outline_color: (0.95,0.85,0.60) was off-palette mustard; tightened to (0.94,0.86,0.62) matching the new PARCHMENT_CREAM exactly.
	lbl.add_theme_color_override("font_color", Color(0.20, 0.16, 0.13, 0.95))
	lbl.add_theme_color_override("font_outline_color", Color(0.94, 0.86, 0.62, 0.82))
	lbl.add_theme_constant_override("outline_size", OL_LOCK)

static func style_tooltip_label(lbl: Label) -> void:
	# 13pt white w/ ink outline — bag-slot tooltip
	lbl.add_theme_font_size_override("font_size", FS_BODY)
	# REFINE: visual — THEME §3 violation fix + outline lift: tooltip font_color was pure white Color(1,1,1) (banned by §3). Replaced with PARCHMENT_CREAM-ish (0.96,0.92,0.78) — still high-luminance/legible but warm-cast per §3 sunset palette. Outline 3→4 same reasoning as OL_NAME (post-process bloom era).
	lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.78))
	lbl.add_theme_color_override("font_outline_color", INK_BLACK)
	lbl.add_theme_constant_override("outline_size", 4)

static func style_richtext(rt: RichTextLabel) -> void:
	# 13pt RichTextLabel for stats blocks
	rt.add_theme_font_size_override("normal_font_size", FS_BODY)
	rt.add_theme_color_override("default_color", PARCHMENT_CREAM)

# ═════════════════════════════════════════════════════════════════════════
# Panel helpers — adds a parchment 9-slice NinePatchRect AS A CHILD AT THE
# BACK so the existing default-grey Panel.new() panels finally look medieval.
#
# Idempotent: re-calling on the same panel detects the marker child and skips.
# Also tags the panel with metadata "_eldoria_themed" = true.
# ═════════════════════════════════════════════════════════════════════════

const _BG_NODE_NAME: String = "EldoriaParchmentBG"
const _META_THEMED: String  = "_eldoria_themed"

static func _make_parchment_nine_patch(use_small: bool) -> NinePatchRect:
	var n: NinePatchRect = NinePatchRect.new()
	n.name = _BG_NODE_NAME
	# 9-slice — fill, draw_center true, patch margins per ATTRIBUTION.md
	var path: String = ASSET_PARCHMENT_SMALL if use_small else ASSET_PARCHMENT_LARGE
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			n.texture = tex
	var pad: int = PATCH_SMALL if use_small else PATCH_BIG
	n.patch_margin_left = pad
	n.patch_margin_top = pad
	n.patch_margin_right = pad
	n.patch_margin_bottom = pad
	# Fill its parent
	n.anchor_left = 0.0
	n.anchor_top = 0.0
	n.anchor_right = 1.0
	n.anchor_bottom = 1.0
	n.offset_left = 0.0
	n.offset_top = 0.0
	n.offset_right = 0.0
	n.offset_bottom = 0.0
	# Don't catch mouse — children of the host panel handle input
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Soft tint so painted texture doesn't blow out the children
	n.modulate = Color(1, 1, 1, 1)
	# Draw behind everything — z_index relative
	n.z_index = -1
	return n

static func style_panel_parchment(panel: Control, use_small: bool = false) -> void:
	# Skip if already styled
	if panel.has_meta(_META_THEMED):
		return
	if panel.has_node(_BG_NODE_NAME):
		return
	# Strip the default grey StyleBoxFlat off the Panel by overriding with
	# an empty stylebox. Without this you'd see grey UNDER the parchment.
	var empty_sb: StyleBoxEmpty = StyleBoxEmpty.new()
	panel.add_theme_stylebox_override("panel", empty_sb)
	# Add parchment NinePatch as the FIRST child so it draws behind siblings.
	var bg: NinePatchRect = _make_parchment_nine_patch(use_small)
	panel.add_child(bg)
	panel.move_child(bg, 0)
	panel.set_meta(_META_THEMED, true)

static func style_panel_wood(panel: Control) -> void:
	# Wood-textured panel for inventory bag area, etc.
	if panel.has_meta(_META_THEMED):
		return
	if panel.has_node(_BG_NODE_NAME):
		return
	var empty_sb: StyleBoxEmpty = StyleBoxEmpty.new()
	panel.add_theme_stylebox_override("panel", empty_sb)
	var n: NinePatchRect = NinePatchRect.new()
	n.name = _BG_NODE_NAME
	if ResourceLoader.exists(ASSET_WOOD_PANEL):
		var tex: Texture2D = load(ASSET_WOOD_PANEL) as Texture2D
		if tex != null:
			n.texture = tex
	n.patch_margin_left = PATCH_BIG
	n.patch_margin_top = PATCH_BIG
	n.patch_margin_right = PATCH_BIG
	n.patch_margin_bottom = PATCH_BIG
	n.anchor_right = 1.0
	n.anchor_bottom = 1.0
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.z_index = -1
	panel.add_child(n)
	panel.move_child(n, 0)
	panel.set_meta(_META_THEMED, true)

# ═════════════════════════════════════════════════════════════════════════
# Button helpers — 9-slice wood/iron texture for a medieval feel.
# Falls back gracefully if textures aren't imported yet (still readable).
# ═════════════════════════════════════════════════════════════════════════

static func _make_button_stylebox(path: String) -> StyleBoxTexture:
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			sb.texture = tex
	sb.texture_margin_left = PATCH_BTN
	sb.texture_margin_top = PATCH_BTN
	sb.texture_margin_right = PATCH_BTN
	sb.texture_margin_bottom = PATCH_BTN
	# REFINE: visual — content margins lift (8/4 → 10/5). The wood-and-iron 9-slice frame reads as a carved button only when the label has breathing room inside the bevel; cramped 8/4 margins made FS_BODY_LG 14pt labels touch the iron banding on hover. +2px horizontal / +1px vertical gives the carved look its full painterly read per THEME §1 painterly + §10 rule 9 "weathered/hand-made".
	sb.content_margin_left = 10
	sb.content_margin_top = 5
	sb.content_margin_right = 10
	sb.content_margin_bottom = 5
	return sb

static func style_iron_button(btn: Button) -> void:
	# Wood-and-iron face for the close ✕, action buttons, NPC dialogue choices.
	# Adds three styleboxes (normal/hover/pressed) so hover feels lived-in.
	btn.add_theme_color_override("font_color", PARCHMENT_CREAM)
	btn.add_theme_color_override("font_hover_color", GOLD)
	btn.add_theme_color_override("font_pressed_color", BRASS)
	btn.add_theme_color_override("font_outline_color", INK_BLACK)
	# REFINE: visual — iron-button outline lift 2→3 for new HDRI/post-process era. The button face sits on wood-and-iron texture which already reads dark, but the FONT outline against PARCHMENT_CREAM hover/normal needed +1px to survive the brighter rim-bloom on button edges in close-camera UI shots.
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_font_size_override("font_size", FS_BODY_LG)
	btn.add_theme_stylebox_override("normal",  _make_button_stylebox(ASSET_BTN_NORMAL))
	btn.add_theme_stylebox_override("hover",   _make_button_stylebox(ASSET_BTN_HOVER))
	btn.add_theme_stylebox_override("pressed", _make_button_stylebox(ASSET_BTN_PRESSED))

# ═════════════════════════════════════════════════════════════════════════
# Toast — single-call medieval toast Label with parchment-gold font, ink
# outline. Mirrors World.gd's previous _show_toast styling exactly so visual
# parity is preserved while sourcing the Color from the canonical palette.
# Returns the toast Label — caller add_child()'s it to its UI layer and
# attaches its own tween (fade-out + queue_free).
# ═════════════════════════════════════════════════════════════════════════

static func make_toast_label(text: String) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", FS_TOAST)
	lbl.add_theme_color_override("font_color", GOLD)
	lbl.add_theme_color_override("font_outline_color", INK_BLACK)
	lbl.add_theme_constant_override("outline_size", OL_TOAST)
	lbl.anchor_left = 0.5
	lbl.anchor_right = 0.5
	lbl.anchor_top = 0.3
	lbl.offset_left = -360
	lbl.offset_right = 360
	lbl.offset_top = 0
	lbl.offset_bottom = 60
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

# ═════════════════════════════════════════════════════════════════════════
# Eval probes (i-v in 5-output rule)
# ═════════════════════════════════════════════════════════════════════════

# Sanity self-test — used by World.gd one-liner at boot to log that the
# theme module loaded and the assets are reachable. Returns a [bool, String].
static func self_test() -> Array:
	var ok: bool = true
	var notes: PackedStringArray = PackedStringArray()
	for p in [ASSET_PARCHMENT_LARGE, ASSET_PARCHMENT_SMALL, ASSET_WOOD_PANEL,
			ASSET_BTN_NORMAL, ASSET_BTN_HOVER, ASSET_BTN_PRESSED,
			ASSET_DIVIDER_ORNATE, ASSET_SCROLL_BANNER]:
		if not ResourceLoader.exists(p):
			ok = false
			notes.append("missing: " + p)
	if ok:
		notes.append("UITheme: 8/8 frames present, palette §3 active")
	return [ok, ", ".join(notes)]
