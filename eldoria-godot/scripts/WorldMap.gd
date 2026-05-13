extends Panel
class_name WorldMap

# Realm of Eldoria — Full-screen World Map (toggled by N).
#
# Companion to Minimap.gd. Renders the WHOLE realm on a parchment scroll with
# named landmarks, faction-tinted regions, and a "you are here" gold star.
# Same data sources as Minimap (LANDMARKS const + node groups), so the two
# stay in sync without any extra plumbing — adding a landmark to one shows
# it in both.
#
# THEME hooks:
#   §1   painterly identity   -> hand-painted parchment scroll, frame
#   §3   palette              -> sunset gold #FFD86B title, #D9C99B parchment
#   §5   typography           -> existing UI font, blackletter title flavor
#   §8   architecture         -> region tints match the stated zones
#                              (Briarwood warm gold, Whisperwood forest green,
#                              Crystal Caves fey cyan, Mountain ring stone-blue)
#   §12  MOTION & LIFE        -> player star pulses, faction tints subtly drift
#                              with faction_pressure when World is reachable

const W: float = 760.0
const H: float = 540.0
const PAD: float = 28.0
const RANGE_M: float = 280.0  # ±280m world radius — covers far castle at 260m

const COL_PARCHMENT: Color = Color(0.851, 0.788, 0.608)  # REFINE: visual — §3 sepia exact #D9C99B (was 0.872/0.808/0.624)
const COL_PARCHMENT_LIGHT: Color = Color(0.94, 0.86, 0.62)  # REFINE: visual — converge with UITheme PARCHMENT_CREAM (was 0.93/0.87/0.69)
const COL_FRAME_ORANGE: Color = Color(1.000, 0.502, 0.000)
const COL_FRAME_BRONZE: Color = Color(0.690, 0.455, 0.165)
const COL_INK: Color = Color(0.055, 0.039, 0.055, 0.92)
const COL_TITLE: Color = Color(1.00, 0.85, 0.42)  # REFINE: visual — exact §3 #FFD86B (matches UITheme GOLD, Chest glow_color)
const COL_PLAYER_STAR: Color = Color(1.00, 0.88, 0.50)  # REFINE: visual — pulled toward §3 sunset-gold; reads as ember not pastel-yellow (was 1.0/0.925/0.55)

# Region polygons — outlines of named zones in WORLD XZ. Drawn first as
# soft watercolor washes underneath the landmarks.  THEME §8 tints.
const REGIONS: Array = [
	# ── Inner Briarwood Village ─────────────────────────────────────────
	{"name": "Briarwood",
	"color": Color(1.00, 0.85, 0.42, 0.22),
	"poly": [Vector2(-22, -22), Vector2(22, -22), Vector2(22, 22), Vector2(-22, 22)]},
	# ── Whisperwood forests (flanking) ──────────────────────────────────
	{"name": "Whisperwood",
	"color": Color(0.290, 0.439, 0.220, 0.22),
	"poly": [Vector2(-120, -100), Vector2(-22, -100), Vector2(-22, 100), Vector2(-120, 100)]},
	{"name": "Whisperwood (East)",
	"color": Color(0.290, 0.439, 0.220, 0.18),
	"poly": [Vector2(22, -100), Vector2(120, -100), Vector2(120, 100), Vector2(22, 100)]},
	# ── Crystal Caves region ─────────────────────────────────────────────
	{"name": "Crystal Caves",
	"color": Color(0.396, 0.875, 0.898, 0.24),
	"poly": [Vector2(-80, -75), Vector2(-35, -75), Vector2(-35, -30), Vector2(-80, -30)]},
	# ── Mountain Pass ─────────────────────────────────────────────────────
	{"name": "Mountain Pass",
	"color": Color(0.482, 0.525, 0.576, 0.30),
	"poly": [Vector2(-120, -140), Vector2(120, -140), Vector2(120, -100), Vector2(-120, -100)]},
	# ── Blighted Ruins (far north — castle + boss zone) ───────────────────
	{"name": "Blighted Ruins",
	"color": Color(0.25, 0.12, 0.32, 0.28),
	"poly": [Vector2(-160, -280), Vector2(-20, -280), Vector2(-20, -160), Vector2(-160, -160)]},
	# ── Wastelands (far east enemy fields) ───────────────────────────────
	{"name": "The Wastelands",
	"color": Color(0.55, 0.38, 0.18, 0.18),
	"poly": [Vector2(50, -50), Vector2(200, -50), Vector2(200, 100), Vector2(50, 100)]},
]

var title_label: Label = null
var hint_label: Label = null
var stats_label: Label = null
var minimap_ref: Minimap = null
var _pulse_t: float = 0.0

func _ready() -> void:
	name = "WorldMap"
	custom_minimum_size = Vector2(W, H)
	size = Vector2(W, H)
	anchor_left = 0.5; anchor_right = 0.5
	anchor_top = 0.5;  anchor_bottom = 0.5
	offset_left = -W * 0.5
	offset_right =  W * 0.5
	offset_top = -H * 0.5
	offset_bottom = H * 0.5
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("world_maps")

	# Painterly parchment background via a styled Panel — but draw the
	# painterly frame ourselves in _draw() so we get the curved corners
	# and the bronze inner ring without theme-asset dependencies.
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = COL_PARCHMENT
	sb.border_color = COL_FRAME_ORANGE
	sb.border_width_left = 4
	sb.border_width_top = 4
	sb.border_width_right = 4
	sb.border_width_bottom = 4
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 8
	add_theme_stylebox_override("panel", sb)

	title_label = Label.new()
	title_label.text = "Realm of Eldoria"
	title_label.add_theme_color_override("font_color", COL_TITLE)
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title_label.add_theme_font_size_override("font_size", 32)  # REFINE: visual — title 30→32 for full-screen banner readability
	title_label.add_theme_constant_override("outline_size", 7)  # REFINE: visual — outline 6→7, matches UITheme outline-lift pattern
	title_label.position = Vector2(PAD, 8)
	add_child(title_label)

	hint_label = Label.new()
	hint_label.text = "[ N ] close   ·   ★ = you   ·   ❖ = cave   ·   ☠ = boss   ·   △ = enemy camp   ·   ✦ = shrine"
	hint_label.add_theme_color_override("font_color", Color(0.30, 0.22, 0.15))
	hint_label.add_theme_font_size_override("font_size", 15)  # REFINE: visual — hint 14→15 for Alden 9yo back-of-screen reading
	hint_label.position = Vector2(PAD, H - 28)
	add_child(hint_label)

	stats_label = Label.new()
	stats_label.add_theme_color_override("font_color", Color(0.30, 0.22, 0.15))
	stats_label.add_theme_font_size_override("font_size", 15)  # REFINE: visual — stats 14→15 parallel with hint
	stats_label.position = Vector2(W - 280, 14)
	stats_label.size = Vector2(260, 60)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(stats_label)

	set_process(true)

func bind_minimap(m: Minimap) -> void:
	minimap_ref = m

func toggle() -> void:
	visible = not visible
	if visible:
		_refresh_stats()
		queue_redraw()

func close() -> void:
	visible = false

func _process(delta: float) -> void:
	if not visible:
		return
	_pulse_t += delta
	queue_redraw()

func _refresh_stats() -> void:
	if stats_label == null:
		return
	var p: Node3D = _player_node()
	if p == null:
		stats_label.text = ""
		return
	var to_cave: Vector3 = Vector3(-50, 0, -40) - p.global_position
	var to_village: Vector3 = Vector3.ZERO - p.global_position
	var to_castle: Vector3 = Vector3(-80, 0, -260) - p.global_position
	stats_label.text = "Briarwood : %dm   Crystal Caves : %dm\nRuined Castle : %dm" % [
		int(round(Vector2(to_village.x, to_village.z).length())),
		int(round(Vector2(to_cave.x, to_cave.z).length())),
		int(round(Vector2(to_castle.x, to_castle.z).length())),
	]

func _draw() -> void:
	# Inner bronze ring inside the orange border for the painterly look.
	var inner: Rect2 = Rect2(Vector2(8, 8), Vector2(W - 16, H - 16))
	draw_rect(inner, COL_PARCHMENT_LIGHT, false, 2.0)

	# Map face rect (what we project world XZ onto).
	var face: Rect2 = Rect2(Vector2(PAD, 60), Vector2(W - PAD * 2.0, H - 110))
	draw_rect(face, Color(0.93, 0.86, 0.65), true)
	draw_rect(face, COL_FRAME_BRONZE, false, 1.8)  # REFINE: visual — frame thickness 1.6→1.8 for painterly heft

	# 1. Region watercolor washes.
	for r in REGIONS:
		var col: Color = r.get("color", Color(1, 1, 1, 0.1))
		var poly: Array = r.get("poly", [])
		if poly.size() < 3:
			continue
		var screen: PackedVector2Array = PackedVector2Array()
		for v in poly:
			if v is Vector2:
				screen.append(_world_xz_to_face(v, face))
		draw_colored_polygon(screen, col)

	# 2. Faint world grid (every 20m).
	for gx in range(-80, 81, 20):
		var p1: Vector2 = _world_xz_to_face(Vector2(float(gx), -80.0), face)
		var p2: Vector2 = _world_xz_to_face(Vector2(float(gx),  80.0), face)
		draw_line(p1, p2, Color(0.30, 0.22, 0.15, 0.18), 1.0, true)
	for gz in range(-80, 81, 20):
		var p3: Vector2 = _world_xz_to_face(Vector2(-80.0, float(gz)), face)
		var p4: Vector2 = _world_xz_to_face(Vector2( 80.0, float(gz)), face)
		draw_line(p3, p4, Color(0.30, 0.22, 0.15, 0.18), 1.0, true)

	# 3. Static landmarks.
	var landmarks: Array = Minimap.LANDMARKS
	for l in landmarks:
		var lpos: Vector3 = l.get("pos", Vector3.ZERO)
		var col: Color = l.get("color", Color(1, 1, 1))
		var p: Vector2 = _world_xz_to_face(Vector2(lpos.x, lpos.z), face)
		_draw_lm_glyph(String(l.get("kind", "")), p, col, 7.0)
		# Label.
		var lab: String = String(l.get("name", ""))
		if lab != "":
			draw_string(get_theme_default_font(), p + Vector2(10, 4),
				lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
				Color(0.20, 0.14, 0.08))

	# 4. Live entities.
	for n: Node3D in get_tree().get_nodes_in_group("npcs"):
		if n is Node3D:
			var np: Vector2 = _world_xz_to_face(
				Vector2((n as Node3D).global_position.x, (n as Node3D).global_position.z), face)
			draw_circle(np, 4.5, COL_INK)
			draw_circle(np, 3.0, Color(1.0, 0.86, 0.46))  # REFINE: visual — match NPC nameplate modulate (NPC polish run convergence)
	for e: Node3D in get_tree().get_nodes_in_group("enemies"):
		if e is Node3D:
			var ep: Vector2 = _world_xz_to_face(
				Vector2((e as Node3D).global_position.x, (e as Node3D).global_position.z), face)
			draw_circle(ep, 3.4, COL_INK)
			draw_circle(ep, 2.6, Color(0.627, 0.125, 0.125))  # REFINE: visual — enemy core 2.4→2.6 silhouette readability
	for b: Node3D in get_tree().get_nodes_in_group("bosses"):
		if b is Node3D:
			var bp: Vector2 = _world_xz_to_face(
				Vector2((b as Node3D).global_position.x, (b as Node3D).global_position.z), face)
			draw_circle(bp, 7.0, COL_INK)
			draw_circle(bp, 6.2, Color(0.486, 0.247, 0.690))  # REFINE: visual — boss core 5.5→6.2; bigger contrast vs enemy at map scale

	# 5. Player star (you-are-here) — pulsed gold (THEME §12 motion).
	var player: Node3D = _player_node()
	if player != null:
		var sp: Vector2 = _world_xz_to_face(
			Vector2(player.global_position.x, player.global_position.z), face)
		var pulse: float = 0.85 + 0.18 * sin(_pulse_t * 2.6)  # REFINE: visual — slower painterly heartbeat 4.0→2.6, larger sway 0.15→0.18 (mirrors Minimap flash-rate slowdown)
		_draw_star(sp, 9.0 * pulse, COL_PLAYER_STAR)
		# Heading wedge.
		var yaw: float = player.rotation.y
		var fwd: Vector2 = Vector2(sin(yaw), -cos(yaw))   # world -Z forward → screen up
		# Convert to face-space direction (face flips world-Z to screen-Y).
		var screen_fwd: Vector2 = Vector2(fwd.x, -fwd.y)
		var tip: Vector2 = sp + screen_fwd * 18.0  # REFINE: visual — wedge length 16→18 for heading clarity
		draw_line(sp, tip, COL_INK, 1.8, true)  # REFINE: visual — wedge thickness 1.6→1.8 (matches face frame heft)

	# 6. Compass rose in lower-right of the face.
	var rose_center: Vector2 = Vector2(face.position.x + face.size.x - 30,
									face.position.y + face.size.y - 30)
	draw_circle(rose_center, 18.0, Color(0.93, 0.86, 0.65))
	draw_arc(rose_center, 18.0, 0.0, TAU, 24, COL_FRAME_BRONZE, 1.4, true)
	for i in 4:
		var a: float = -PI * 0.5 + float(i) * PI * 0.5
		var t1: Vector2 = rose_center + Vector2(cos(a), sin(a)) * 14.0
		var t2: Vector2 = rose_center + Vector2(cos(a), sin(a)) * 18.0
		draw_line(t1, t2, COL_INK, 1.4, true)
	draw_string(get_theme_default_font(), rose_center + Vector2(-3, -19),
		"N", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COL_INK)  # REFINE: visual — compass N 13→14 readability

# ----------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------
func _draw_lm_glyph(kind: String, p: Vector2, col: Color, glyph_size: float) -> void:
	match kind:
		"village":
			var box: Rect2 = Rect2(p - Vector2(glyph_size, glyph_size * 0.45),
				Vector2(glyph_size * 2.0, glyph_size * 0.9))
			draw_rect(box, col, true)
			var roof: PackedVector2Array = PackedVector2Array([
				p + Vector2(-glyph_size - 1.5, -glyph_size * 0.45),
				p + Vector2(0.0, -glyph_size - 1.5),
				p + Vector2( glyph_size + 1.5, -glyph_size * 0.45),
			])
			draw_colored_polygon(roof, col)
			draw_polyline(PackedVector2Array([roof[0], roof[1], roof[2]]), COL_INK, 1.2, true)
		"well":
			draw_arc(p, glyph_size * 0.7, 0.0, TAU, 18, col, 1.8, true)
		"campfire":
			var ftri: PackedVector2Array = PackedVector2Array([
				p + Vector2(-glyph_size * 0.6,  glyph_size * 0.5),
				p + Vector2( glyph_size * 0.6,  glyph_size * 0.5),
				p + Vector2( 0.0,        -glyph_size * 0.8),
			])
			draw_colored_polygon(ftri, col)
		"cave":
			var dia: PackedVector2Array = PackedVector2Array([
				p + Vector2(0.0, -glyph_size - 1.0),
				p + Vector2(glyph_size + 1.0, 0.0),
				p + Vector2(0.0, glyph_size + 1.0),
				p + Vector2(-glyph_size - 1.0, 0.0),
			])
			draw_colored_polygon(dia, col)
			draw_polyline(PackedVector2Array([dia[0], dia[1], dia[2], dia[3], dia[0]]),
				COL_INK, 1.2, true)
		"camp":
			var ttri: PackedVector2Array = PackedVector2Array([
				p + Vector2(-glyph_size, glyph_size * 0.55),
				p + Vector2(0.0, -glyph_size - 1.0),
				p + Vector2(glyph_size, glyph_size * 0.55),
			])
			draw_colored_polygon(ttri, col)
		"boss":
			draw_circle(p, glyph_size + 1.0, col)
			draw_circle(p + Vector2(-2.6, -1.2), 1.6, COL_INK)
			draw_circle(p + Vector2( 2.6, -1.2), 1.6, COL_INK)
			draw_line(p + Vector2(-3.0, 2.5), p + Vector2(3.0, 2.5), COL_INK, 1.2, true)
		_:
			draw_circle(p, glyph_size * 0.7, col)

func _draw_star(p: Vector2, r: float, col: Color) -> void:
	# 5-point star — gold + ink outline.
	var pts: PackedVector2Array = PackedVector2Array()
	var inner_r: float = r * 0.42
	for i in 10:
		var ang: float = -PI * 0.5 + float(i) * (PI / 5.0)
		var rr: float = r if i % 2 == 0 else inner_r
		pts.append(p + Vector2(cos(ang), sin(ang)) * rr)
	draw_colored_polygon(pts, col)
	draw_polyline(pts, COL_INK, 1.2, true)
	# Inner gleam.
	draw_circle(p, r * 0.22, Color(1.0, 1.0, 0.85))  # REFINE: visual — gleam core 0.18→0.22; player-star reads from back of screen

func _world_xz_to_face(world_xz: Vector2, face: Rect2) -> Vector2:
	# Map world (-RANGE_M..RANGE_M) → face rect.  +X right, +Z down (screen).
	var nx: float = (world_xz.x + RANGE_M) / (RANGE_M * 2.0)
	var nz: float = (world_xz.y + RANGE_M) / (RANGE_M * 2.0)
	return face.position + Vector2(nx * face.size.x, nz * face.size.y)

func _player_node() -> Node3D:
	var arr: Array = get_tree().get_nodes_in_group("player")
	if arr.is_empty():
		return null
	if arr[0] is Node3D:
		return arr[0]
	return null
