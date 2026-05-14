extends Panel
class_name WorldMap

# Realm of Eldoria — World Map (N key toggle)
# Faithfully renders the hand-designed SVG map with live player position.
# Dark parchment style matching the uploaded SVG design.

const W: float = 820.0
const H: float = 820.0
const RANGE_M: float = 280.0   # world radius ±280m
const CX: float = 410.0        # SVG centre X = world origin
const CY: float = 410.0        # SVG centre Y = world origin
const PX_PER_M: float = 400.0 / 280.0  # 400px = 280m

# Colours — matching the SVG
const C_BG       := Color(0.102, 0.071, 0.031)   # #1a1208
const C_GRID     := Color(0.227, 0.188, 0.125, 0.5) # #3a3020
const C_ROAD     := Color(0.353, 0.306, 0.188)   # #5a4e30
const C_FOREST   := Color(0.102, 0.180, 0.071)   # #1a2e12
const C_FOREST2  := Color(0.094, 0.165, 0.063)   # #182a10
const C_TREE_DOT := Color(0.165, 0.251, 0.094)   # #2a4018
const C_FIREFLY  := Color(0.251, 1.0,   0.502, 0.06)
const C_GOBLIN   := Color(0.784, 0.251, 0.063, 0.8) # #c84010
const C_CAVE_BG  := Color(0.165, 0.125, 0.251)   # #2a2040
const C_CAVE_STK := Color(0.314, 0.314, 0.753)   # #5050c0
const C_CAVE_GL  := Color(0.251, 0.376, 1.0,  0.2)
const C_HILL     := Color(0.165, 0.220, 0.094)   # #2a3818
const C_COMPASS  := Color(0.541, 0.478, 0.314)   # #8a7a50
const C_INK      := Color(0.055, 0.039, 0.055, 0.92)
const C_PLAYER   := Color(1.00,  0.88,  0.50)
const C_ENEMY    := Color(0.627, 0.125, 0.125)
const C_BOSS     := Color(0.486, 0.247, 0.690)
const C_NPC      := Color(1.00,  0.847, 0.275)   # gold

# Ring radii in world metres → shown as dashed circles
const RINGS_M := [30.0, 80.0, 160.0, 260.0]
const RING_LABELS := ["30m", "80m", "160m", "260m"]

# Roads: pairs of world XZ points
const ROADS := [
	[Vector2(0, -14),    Vector2(0,   -252)],   # North → Nordic Village
	[Vector2(14,  0),    Vector2(203,  -14)],   # East scrubland
	[Vector2(-14, 0),    Vector2(-185, -17)],   # West → Whisperwood
]

# Tree dots inside Whisperwood (SVG coordinates → world)
const TREE_DOTS_SVG := [
	Vector2(145,315), Vector2(165,300), Vector2(185,308),
	Vector2(200,295), Vector2(155,340), Vector2(175,350),
	Vector2(195,335), Vector2(215,320), Vector2(135,345),
	Vector2(160,375), Vector2(180,368), Vector2(200,358), Vector2(220,342), Vector2(140,360),
]

# Hills (SVG ellipses → world centre + radii)
const HILLS := [
	{"cx":550,"cy":270,"rx":22,"ry":12},
	{"cx":330,"cy":268,"rx":18,"ry":10},
	{"cx":560,"cy":360,"rx":25,"ry":13},
	{"cx":245,"cy":360,"rx":20,"ry":11},
	{"cx":460,"cy":260,"rx":15,"ry": 8},
	{"cx":525,"cy":168,"rx":30,"ry":14},
	{"cx":275,"cy":178,"rx":26,"ry":13},
	{"cx":350,"cy":560,"rx":20,"ry":10},
	{"cx":580,"cy":520,"rx":22,"ry":11},
	{"cx":410,"cy":190,"rx":35,"ry":16},  # big hill on north road
]

# Named landmarks — world XZ positions matching SVG
const LANDMARKS := [
	{"name": "Briarwood",        "pos": Vector3(   0,   0,    0), "kind": "village",  "col": Color(1.00, 0.85, 0.42)},
	{"name": "Nordic Village",   "pos": Vector3(   0,   0, -250), "kind": "village",  "col": Color(0.80, 0.90, 1.00)},
	{"name": "Whisperwood",      "pos": Vector3( -90,   0,    0), "kind": "forest",   "col": Color(0.29, 0.55, 0.22)},
	{"name": "Goblin Camp",      "pos": Vector3(-150,   0,  -45), "kind": "camp",     "col": Color(0.78, 0.25, 0.06)},
	{"name": "Crystal Caves",    "pos": Vector3( -50,   0,  -40), "kind": "cave",     "col": Color(0.38, 0.50, 1.00)},
	{"name": "Hermit's Hut",     "pos": Vector3( -30,   0,  -75), "kind": "hut",      "col": Color(0.70, 0.60, 0.40)},
	{"name": "Barbarian Warband","pos": Vector3(   0,   0, -115), "kind": "camp",     "col": Color(0.90, 0.40, 0.10)},
	{"name": "Riverside Dock",   "pos": Vector3(  45,   0,   65), "kind": "dock",     "col": Color(0.40, 0.65, 0.90)},
	{"name": "Ruined Castle",    "pos": Vector3( -80,   0, -260), "kind": "boss",     "col": Color(0.50, 0.25, 0.70)},
	{"name": "Lord of Darkness", "pos": Vector3(-220,   0, -120), "kind": "boss",     "col": Color(0.30, 0.10, 0.45)},
]

var _pulse: float = 0.0
var _hint: Label

func _ready() -> void:
	name = "WorldMap"
	custom_minimum_size = Vector2(W, H)
	size = Vector2(W, H)
	anchor_left   = 0.5; anchor_right  = 0.5
	anchor_top    = 0.5; anchor_bottom = 0.5
	offset_left   = -W * 0.5; offset_right  = W * 0.5
	offset_top    = -H * 0.5; offset_bottom = H * 0.5
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("world_maps")

	var sb := StyleBoxFlat.new()
	sb.bg_color = C_BG
	sb.border_color = Color(0.541, 0.478, 0.314)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(0)
	add_theme_stylebox_override("panel", sb)

	# Title
	var title := Label.new()
	title.text = "Realm of Eldoria — World Map"
	title.add_theme_color_override("font_color", Color(1.00, 0.85, 0.42))
	title.add_theme_font_size_override("font_size", 22)
	title.position = Vector2(20, 8)
	add_child(title)

	# Hint
	_hint = Label.new()
	_hint.text = "[ N ] close   ·   ★ you   ·   ⚔ enemy camp   ·   ☠ boss   ·   ◆ cave   ·   ● dock"
	_hint.add_theme_color_override("font_color", Color(0.541, 0.478, 0.314))
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.position = Vector2(20, H - 24)
	add_child(_hint)

	set_process(true)

func toggle() -> void:
	visible = not visible
	if visible:
		queue_redraw()

func close() -> void:
	visible = false

func _process(delta: float) -> void:
	if visible:
		_pulse += delta
		queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).pressed:
		var k := (event as InputEventKey).keycode
		if k == KEY_N or k == KEY_ESCAPE or k == KEY_M:
			visible = false
			get_viewport().set_input_as_handled()

# ── Main draw ─────────────────────────────────────────────────────────────────
func _draw() -> void:
	# 1. Ground circle
	draw_circle(Vector2(CX, CY), 400.0, C_BG)

	# 2. Hills (terrain mounds — faint green blobs)
	for h in HILLS:
		_draw_ellipse(Vector2(h.cx, h.cy), h.rx, h.ry, C_HILL, 0.6)

	# 3. Distance rings
	var ring_alphas := [0.55, 0.45, 0.35, 0.28]
	var ring_dashes := [3.0, 3.0, 2.0, 2.0]
	for i in RINGS_M.size():
		var r_px: float = RINGS_M[i] * PX_PER_M
		var col := Color(C_GRID.r, C_GRID.g, C_GRID.b, ring_alphas[i])
		_draw_dashed_circle(Vector2(CX, CY), r_px, col, 1.0, ring_dashes[i])
		# Ring label at top of circle
		var lx: float = CX
		var ly: float = CY - r_px - 8.0
		draw_string(get_theme_default_font(), Vector2(lx - 12, ly),
			RING_LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
			Color(0.29, 0.25, 0.17, 0.8))

	# 4. Roads
	for road in ROADS:
		var p1: Vector2 = _w2s(road[0])
		var p2: Vector2 = _w2s(road[1])
		_draw_dashed_line(p1, p2, C_ROAD, 2.5, 8.0, 4.0, 0.7)

	# 5. Whisperwood forest blobs
	_draw_ellipse(Vector2(175, 330), 90, 70, C_FOREST,  0.85)
	_draw_ellipse(Vector2(155, 360), 70, 55, C_FOREST2, 0.70)
	# Tree dots
	for dot in TREE_DOTS_SVG:
		draw_circle(dot, 6.0, Color(C_TREE_DOT.r, C_TREE_DOT.g, C_TREE_DOT.b, 0.9))
	# Firefly glow
	draw_circle(Vector2(175, 335), 18.0, Color(C_FIREFLY.r, C_FIREFLY.g, C_FIREFLY.b, 0.06))

	# 6. Crystal Caves entrance (two pillars + arch + glow)
	draw_rect(Rect2(226, 496, 16, 28), C_CAVE_BG)
	draw_rect(Rect2(226, 496, 16, 28), C_CAVE_STK, false, 1.5)
	draw_rect(Rect2(250, 496, 16, 28), C_CAVE_BG)
	draw_rect(Rect2(250, 496, 16, 28), C_CAVE_STK, false, 1.5)
	draw_rect(Rect2(224, 492, 44,  8), Color(0.188, 0.188, 0.627))
	draw_circle(Vector2(246, 490), 14.0, Color(0.251, 0.376, 1.0, 0.20))
	draw_circle(Vector2(246, 490),  5.0, Color(0.376, 0.502, 1.0, 0.70))
	draw_string(get_theme_default_font(), Vector2(216, 538),
		"Crystal Caves", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.376, 0.502, 0.878))
	draw_string(get_theme_default_font(), Vector2(222, 550),
		"⟱ Underground", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.251, 0.314, 0.627))

	# 7. Landmarks
	for lm in LANDMARKS:
		var p: Vector2 = _w2s(Vector2((lm.pos as Vector3).x, (lm.pos as Vector3).z))
		var col: Color = lm.col
		var kind: String = lm.kind
		_draw_landmark(p, kind, col)
		var lname: String = lm.name
		if lname != "Briarwood":   # Briarwood label drawn bigger below
			draw_string(get_theme_default_font(), p + Vector2(10, 4),
				lname, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.78, 0.71, 0.55))

	# Briarwood label (bigger, at centre)
	draw_string(get_theme_default_font(), Vector2(CX - 40, CY + 28),
		"Briarwood", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.00, 0.85, 0.42))

	# Whisperwood label
	draw_string(get_theme_default_font(), Vector2(145, 290),
		"Whisperwood", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.29, 0.47, 0.20))

	# 8. Live NPCs (gold dots)
	for n in get_tree().get_nodes_in_group("npcs"):
		if n is Node3D:
			var nd := n as Node3D
			var np: Vector2 = _w2s(Vector2(nd.global_position.x, nd.global_position.z))
			draw_circle(np, 3.5, C_INK)
			draw_circle(np, 2.2, C_NPC)

	# 9. Live enemies (red dots)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node3D:
			var ed := e as Node3D
			var ep: Vector2 = _w2s(Vector2(ed.global_position.x, ed.global_position.z))
			draw_circle(ep, 3.0, C_INK)
			draw_circle(ep, 2.0, C_ENEMY)

	# 10. Bosses (purple)
	for b in get_tree().get_nodes_in_group("bosses"):
		if b is Node3D:
			var bd := b as Node3D
			var bp: Vector2 = _w2s(Vector2(bd.global_position.x, bd.global_position.z))
			draw_circle(bp, 6.0, C_INK)
			draw_circle(bp, 5.0, C_BOSS)

	# 11. Player star — pulsing gold
	var player := _player()
	if player != null:
		var pp: Vector2 = _w2s(Vector2(player.global_position.x, player.global_position.z))
		var pulse_r: float = 9.0 * (0.85 + 0.15 * sin(_pulse * 2.6))
		_draw_star(pp, pulse_r, C_PLAYER)
		# Heading line
		var fwd := Vector2(sin(player.rotation.y), -cos(player.rotation.y))
		draw_line(pp, pp + fwd * 18.0, C_INK, 1.8, true)

	# 12. Compass rose (top-centre)
	var rc := Vector2(CX, 36.0)
	draw_string(get_theme_default_font(), rc + Vector2(-4, -10), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_COMPASS)
	draw_string(get_theme_default_font(), Vector2(CX - 4, H - 38), "S", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, C_COMPASS)
	draw_string(get_theme_default_font(), Vector2(14, CY + 5),      "W", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, C_COMPASS)
	draw_string(get_theme_default_font(), Vector2(796, CY + 5),     "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, C_COMPASS)

# ── Landmark glyphs ───────────────────────────────────────────────────────────
func _draw_landmark(p: Vector2, kind: String, col: Color) -> void:
	match kind:
		"village":
			# House icon
			draw_rect(Rect2(p.x - 8, p.y - 4, 16, 9), col, true)
			var roof := PackedVector2Array([p + Vector2(-10,-4), p + Vector2(0,-12), p + Vector2(10,-4)])
			draw_colored_polygon(roof, col)
			draw_polyline(PackedVector2Array([roof[0],roof[1],roof[2]]), C_INK, 1.2, true)
		"forest":
			# Tree circle
			draw_circle(p, 8.0, col)
			draw_circle(p, 8.0, Color(col.r, col.g, col.b, 0.4), false)
		"camp":
			# Triangle tent
			var tri := PackedVector2Array([p+Vector2(-8,6), p+Vector2(0,-9), p+Vector2(8,6)])
			draw_colored_polygon(tri, col)
			draw_polyline(PackedVector2Array([tri[0],tri[1],tri[2],tri[0]]), C_INK, 1.2, true)
		"cave":
			# Diamond
			var dia := PackedVector2Array([p+Vector2(0,-9), p+Vector2(9,0), p+Vector2(0,9), p+Vector2(-9,0)])
			draw_colored_polygon(dia, col)
			draw_polyline(PackedVector2Array([dia[0],dia[1],dia[2],dia[3],dia[0]]), C_INK, 1.2, true)
		"boss":
			# Skull-ish: big circle with eyes
			draw_circle(p, 9.0, col)
			draw_circle(p + Vector2(-3, -1.5), 1.8, C_INK)
			draw_circle(p + Vector2( 3, -1.5), 1.8, C_INK)
			draw_line(p + Vector2(-3.5, 3), p + Vector2(3.5, 3), C_INK, 1.2, true)
		"hut":
			draw_circle(p, 5.0, col, true)
			draw_circle(p, 5.0, C_INK, false, 1.2)
		"dock":
			draw_rect(Rect2(p.x - 7, p.y - 3, 14, 6), col, true)
			draw_rect(Rect2(p.x - 7, p.y - 3, 14, 6), C_INK, false, 1.2)
		_:
			draw_circle(p, 5.0, col, true)

# ── Helpers ───────────────────────────────────────────────────────────────────
func _w2s(world_xz: Vector2) -> Vector2:
	# World metres → SVG pixel space (origin at CX,CY)
	return Vector2(CX + world_xz.x * PX_PER_M, CY + world_xz.y * PX_PER_M)

func _draw_star(p: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang: float = -PI * 0.5 + float(i) * (PI / 5.0)
		var rr: float = r if i % 2 == 0 else r * 0.42
		pts.append(p + Vector2(cos(ang), sin(ang)) * rr)
	draw_colored_polygon(pts, col)
	draw_polyline(pts, C_INK, 1.2, true)
	draw_circle(p, r * 0.22, Color(1.0, 1.0, 0.85))

func _draw_ellipse(centre: Vector2, rx: float, ry: float, col: Color, alpha: float) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a: float = float(i) / 32.0 * TAU
		pts.append(centre + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, Color(col.r, col.g, col.b, alpha))

func _draw_dashed_circle(centre: Vector2, radius: float, col: Color, width: float, dash: float) -> void:
	var circ: float = TAU * radius
	var steps: int = int(circ / (dash * 2.0))
	for i in steps:
		var a1: float = float(i * 2) / float(steps * 2) * TAU
		var a2: float = float(i * 2 + 1) / float(steps * 2) * TAU
		var p1: Vector2 = centre + Vector2(cos(a1), sin(a1)) * radius
		var p2: Vector2 = centre + Vector2(cos(a2), sin(a2)) * radius
		draw_line(p1, p2, col, width, true)

func _draw_dashed_line(p1: Vector2, p2: Vector2, col: Color, width: float,
		dash: float, gap: float, alpha: float) -> void:
	var dir: Vector2 = (p2 - p1)
	var total: float = dir.length()
	if total < 0.001:
		return
	dir = dir / total
	var t: float = 0.0
	var drawing: bool = true
	var c := Color(col.r, col.g, col.b, alpha)
	while t < total:
		var seg: float = dash if drawing else gap
		var end_t: float = min(t + seg, total)
		if drawing:
			draw_line(p1 + dir * t, p1 + dir * end_t, c, width, true)
		t = end_t
		drawing = not drawing

func _player() -> Node3D:
	var arr: Array = get_tree().get_nodes_in_group("player")
	if arr.is_empty():
		return null
	return arr[0] as Node3D
