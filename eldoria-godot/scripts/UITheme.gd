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
const GOLD: Color           = Color(1.00, 0.85, 0.40)   # #FFD86B-ish, burnt gold
const SUNSET_ORANGE: Color  = Color(1.00, 0.50, 0.00)   # #FF8000
const CRIMSON: Color        = Color(0.55, 0.13, 0.13)   # #8C2020 wine
const MOSS_GREEN: Color     = Color(0.29, 0.44, 0.22)   # #4A7038
const PARCHMENT: Color      = Color(0.85, 0.79, 0.61)   # #D9C99B aged paper
const PARCHMENT_CREAM: Color= Color(0.92, 0.85, 0.65)   # warmer cream tier
const INK_BLACK: Color      = Color(0.05, 0.04, 0.05)   # #0E0A0E

# Secondary (20%)
const BRASS: Color          = Color(0.69, 0.46, 0.16)   # #B0742A hammered bronze
const STAG_BLOOD: Color     = Color(0.63, 0.13, 0.13)   # #A02020
const STONE_BLUE: Color     = Color(0.48, 0.53, 0.58)   # #7B8693

# Magic (10% — sparingly)
const FEY_CYAN: Color       = Color(0.40, 0.87, 0.90)   # #65DFE5
const ARCANE_PURPLE: Color  = Color(0.49, 0.25, 0.69)   # #7C3FB0
const FROST_SILVER: Color   = Color(0.78, 0.88, 0.90)   # #C8E0E5

# Dim helpers
const DIM_GREY: Color       = Color(0.65, 0.60, 0.55)
const LOCK_DIM: Color       = Color(0.45, 0.45, 0.45, 0.85)
const HINT_DIM: Color       = Color(1.00, 1.00, 1.00, 0.65)

# ═════════════════════════════════════════════════════════════════════════
# Font sizes — THEME §5 hierarchy
# ═════════════════════════════════════════════════════════════════════════

const FS_TOAST: int    = 28   # screen-center transient
const FS_TITLE: int    = 24   # panel title (e.g., "🎒 Inventory & Equipment")
const FS_HEADER: int   = 22   # secondary header
const FS_SUBTITLE: int = 16   # column header ("— Equipped —", "— Bag —")
const FS_BODY_LG: int  = 14   # button face
const FS_BODY: int     = 13   # main body text, RichTextLabel default
const FS_BODY_SM: int  = 12   # hint, footer, desc
const FS_TINY: int     = 11   # title-hint micro text
const FS_LOCK: int     = 36   # 🔒 overlay glyph
const FS_BAG_GLYPH: int= 22   # bag-slot item glyph

# Outline sizes
const OL_TITLE: int  = 4
const OL_NAME: int   = 3
const OL_TOAST: int  = 6
const OL_LOCK: int   = 4

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
	lbl.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15, 0.95))
	lbl.add_theme_color_override("font_outline_color", Color(0.95, 0.85, 0.60, 0.80))
	lbl.add_theme_constant_override("outline_size", OL_LOCK)

static func style_tooltip_label(lbl: Label) -> void:
	# 13pt white w/ ink outline — bag-slot tooltip
	lbl.add_theme_font_size_override("font_size", FS_BODY)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.add_theme_color_override("font_outline_color", INK_BLACK)
	lbl.add_theme_constant_override("outline_size", 3)

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
	sb.content_margin_left = 8
	sb.content_margin_top = 4
	sb.content_margin_right = 8
	sb.content_margin_bottom = 4
	return sb

static func style_iron_button(btn: Button) -> void:
	# Wood-and-iron face for the close ✕, action buttons, NPC dialogue choices.
	# Adds three styleboxes (normal/hover/pressed) so hover feels lived-in.
	btn.add_theme_color_override("font_color", PARCHMENT_CREAM)
	btn.add_theme_color_override("font_hover_color", GOLD)
	btn.add_theme_color_override("font_pressed_color", BRASS)
	btn.add_theme_color_override("font_outline_color", INK_BLACK)
	btn.add_theme_constant_override("outline_size", 2)
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
