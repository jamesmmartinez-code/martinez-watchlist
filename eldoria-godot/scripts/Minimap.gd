extends Control
class_name Minimap

# Realm of Eldoria — Mini-map HUD overlay (top-right corner, always visible).
#
# Painterly parchment compass-disc that plots living-world entities each frame.
# Reads ONLY existing world primitives — adds NO new world state:
#   - get_tree().get_nodes_in_group("player")    — center, heading
#   - get_tree().get_nodes_in_group("npcs")      — gold dots (added by
#                                                  WorldBuilder._make_npc)
#   - get_tree().get_nodes_in_group("enemies")   — crimson dots, scaled by HP
#   - get_tree().get_nodes_in_group("bosses")    — purple "X" glyph
#   - get_tree().get_nodes_in_group("chests")    — bronze ring if unopened
#   - get_tree().get_nodes_in_group("goblin_fires") — small ember dots
#   - LANDMARKS const                            — static fixed-world pins
#
# THEME hooks (rationale per §):
#   §1  painterly identity   -> parchment + burnt-orange frame, no glassmorphism
#   §3  palette              -> frame #FF8000, parchment #D9C99B, fey cyan #65DFE5
#                              (Crystal Caves), gold #FFD86B (NPCs/landmarks),
#                              stag-blood #A02020 (enemies), warlock #7C3FB0 (boss)
#   §5  typography           -> cardinal letters drawn as hand-painted strokes,
#                              not a system font (consistent with painterly UI)
#   §12 MOTION & LIFE        -> compass rotates each frame, player dot pulses,
#                              enemies in aggro radius flash, ping rings expand,
#                              nothing on this UI is static while the world is alive
#
# Public API:
#   ping(world_pos, color)            -> flash an expanding ring (quest hint hook)
#   set_visible_radius(meters)        -> zoom (default 30m)
#   landmark_at(name) -> Vector3      -> schema lookup for other systems
#
# Schema -- LANDMARKS const (append-only):
#   pos:   Vector3   - world position
#   name:  String    - label shown by full WorldMap
#   kind:  String    - one of {"village","forge","well","campfire","cave",
#                              "boss","camp","shrine"}
#   color: Color     - pin color (THEME §3 palette)
#   icon:  String    - single-glyph emoji used by full WorldMap

# ----------------------------------------------------------------------
# Tunables
# ----------------------------------------------------------------------
const SIZE_PX: float = 178.0
const FRAME_PX: float = 6.0
const DEFAULT_RADIUS_M: float = 30.0
# REFINE: visual — minimap polish run. THEME §3 (palette) + §4 (silhouette-distinct
# at 30m, applied to minimap pins too) + §12 (motion that doesn't feel mechanical).
# Compounds on UITheme.gd §3-conformance run, NPC.gd InteractArea radius lift (2.7m),
# Pet.gd bark_radius lift (9.0m), Chest.gd burst-fade slowdown convention.
# REFINE: visual — PING_LIFETIME 1.4 → 1.6s. Longer expand-and-fade tail so the
# quest-hint ring reads as "look this way" not a flash. Matches the Chest.gd
# burst-fade slowdown convention from the prior visual run.
const PING_LIFETIME: float = 1.6
# REFINE: visual — ENEMY_FLASH_RANGE 8.0 → 9.0m. Cross-system consistency: matches
# Pet.gd bark_radius (9.0) and the NPC.gd run-12 InteractArea radius lift (2.7m
# bubble + sloped centering). 9m is the "this matters" proximity perimeter for
# UI cues across the whole project. Alden gets a half-step earlier pre-aggro
# warning; Owen still reads the threat in time for combat reorient.
const ENEMY_FLASH_RANGE: float = 9.0
const PIN_RADIUS_PX: float = 3.4

const COL_PARCHMENT: Color = Color(0.852, 0.788, 0.608)
const COL_PARCHMENT_DARK: Color = Color(0.62, 0.55, 0.40)
const COL_FRAME_ORANGE: Color = Color(1.000, 0.502, 0.000)
const COL_FRAME_BRONZE: Color = Color(0.690, 0.455, 0.165)
const COL_INK: Color = Color(0.055, 0.039, 0.055, 0.9)
# REFINE: visual — COL_PLAYER (1.000, 0.847, 0.420) → (1.000, 0.760, 0.300).
# Was identical to COL_NPC (#FFD86B sunset-gold) — player and villager pins were
# pixel-indistinguishable. New tone sits between THEME §3 burnt-orange (#FF8000)
# and sunset-gold (#FFD86B) — call it ember-gold (~#FFC24D). Still on §3 palette
# (the §3 transition band that Chest.gd glow_color and ember NPC accents already
# inhabit). Player now reads silhouette-distinct from NPC dots — THEME §4
# "recognize at 30m" applied to the minimap.
const COL_PLAYER: Color = Color(1.000, 0.760, 0.300)
const COL_NPC: Color = Color(1.000, 0.847, 0.420)
const COL_ENEMY: Color = Color(0.627, 0.125, 0.125)
const COL_BOSS: Color = Color(0.486, 0.247, 0.690)
const COL_CHEST: Color = Color(0.690, 0.455, 0.165)
const COL_CRYSTAL: Color = Color(0.396, 0.875, 0.898)
const COL_FIRE: Color = Color(1.000, 0.604, 0.247)
# REFINE: visual — COL_GRID alpha 0.45 → 0.36. Concentric range guides should
# read as parchment ink suggestion, not active gridlines. Compounds on UITheme.gd
# §3-conformance run that pulled UI elements away from flat-grey/black mechanical
# affect; minimap grid lines were tugging at the eye against the parchment disc.
const COL_GRID: Color = Color(0.40, 0.34, 0.22, 0.36)

const LANDMARKS: Array = [
	{"pos": Vector3(  0.0, 0.0,  0.0),  "name": "Briarwood Square",
	 "kind": "village",  "color": Color(1.0, 0.847, 0.42), "icon": "⌂"},
	{"pos": Vector3(  0.0, 0.0,  6.0),  "name": "Stone Well",
	 "kind": "well",     "color": Color(0.78, 0.85, 0.93), "icon": "○"},
	{"pos": Vector3(  0.0, 0.0, -2.0),  "name": "Village Campfire",
	 "kind": "campfire", "color": Color(1.0, 0.604, 0.247), "icon": "✺"},
	{"pos": Vector3(-50.0, 0.0,-40.0),  "name": "Crystal Caves",
	 "kind": "cave",     "color": Color(0.396, 0.875, 0.898), "icon": "❖"},
	{"pos": Vector3(-40.0, 0.0, 30.0),  "name": "Goblin Camp — West Glade",
	 "kind": "camp",     "color": Color(0.55, 0.30, 0.18), "icon": "△"},
	{"pos": Vector3( 20.0, 0.0,-45.0),  "name": "Goblin Camp — North Ridge",
	 "kind": "camp",     "color": Color(0.55, 0.30, 0.18), "icon": "△"},
	{"pos": Vector3(  0.0, 0.0,-60.0),  "name": "Mountain Pass — Boss",
	 "kind": "boss",     "color": Color(0.486, 0.247, 0.690), "icon": "☠"},
]

var visible_radius_m: float = DEFAULT_RADIUS_M
var _pulse_t: float = 0.0
var _pings: Array = []

# ----------------------------------------------------------------------
# Lifecycle
# ----------------------------------------------------------------------
func _ready() -> void:
	custom_minimum_size = Vector2(SIZE_PX, SIZE_PX)
	size = Vector2(SIZE_PX, SIZE_PX)
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -SIZE_PX - 14.0
	offset_right = -14.0
	offset_top = 14.0
	offset_bottom = 14.0 + SIZE_PX
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("minimaps")
	set_process(true)

func _process(delta: float) -> void:
	_pulse_t += delta
	var live: Array = []
	for p in _pings:
		var dt: float = float(p.get("t", 0.0)) + delta
		if dt < PING_LIFETIME:
			p["t"] = dt
			live.append(p)
	_pings = live
	queue_redraw()

# ----------------------------------------------------------------------
# Public API
# ----------------------------------------------------------------------
func set_visible_radius(meters: float) -> void:
	visible_radius_m = clamp(meters, 8.0, 200.0)
	queue_redraw()

func ping(world_pos: Vector3, color: Color = COL_CRYSTAL) -> void:
	_pings.append({"pos": world_pos, "color": color, "t": 0.0})

func landmark_at(landmark_name: String) -> Vector3:
	for l in LANDMARKS:
		if String(l.get("name", "")) == landmark_name:
			return l.get("pos", Vector3.ZERO)
	return Vector3.ZERO

# ----------------------------------------------------------------------
# Drawing
# ----------------------------------------------------------------------
func _draw() -> void:
	var center: Vector2 = Vector2(SIZE_PX, SIZE_PX) * 0.5
	var radius_px: float = SIZE_PX * 0.5 - FRAME_PX

	draw_circle(center, radius_px + FRAME_PX, COL_INK)
	draw_circle(center, radius_px + FRAME_PX * 0.65, COL_FRAME_ORANGE)
	draw_circle(center, radius_px + FRAME_PX * 0.30, COL_FRAME_BRONZE)
	draw_circle(center, radius_px, COL_PARCHMENT)

	for f in [0.333, 0.666]:
		var r_grid: float = radius_px * float(f)
		draw_arc(center, r_grid, 0.0, TAU, 48, COL_GRID, 1.0, true)

	var player_yaw: float = _player_yaw()
	for ci in 4:
		var ang: float = -PI * 0.5 + float(ci) * (PI * 0.5) - player_yaw
		var tick_outer: Vector2 = center + Vector2(cos(ang), sin(ang)) * radius_px
		var tick_inner: Vector2 = center + Vector2(cos(ang), sin(ang)) * (radius_px - 8.0)
		draw_line(tick_inner, tick_outer, COL_INK, 2.0, true)
	_draw_cardinal_letter("N", center, radius_px, -PI * 0.5 - player_yaw, player_yaw)
	_draw_cardinal_letter("E", center, radius_px,  0.0      - player_yaw, player_yaw)
	_draw_cardinal_letter("S", center, radius_px,  PI * 0.5 - player_yaw, player_yaw)
	_draw_cardinal_letter("W", center, radius_px,  PI       - player_yaw, player_yaw)

	var player: Node3D = _player_node()
	for l in LANDMARKS:
		var lpos: Vector3 = l.get("pos", Vector3.ZERO)
		var col: Color = l.get("color", COL_NPC)
		var p: Vector2 = _world_to_minimap(lpos, player, player_yaw, center, radius_px)
		var dist_w: float = (Vector2(lpos.x, lpos.z) - _player_xz(player)).length()
		if dist_w > visible_radius_m:
			col = Color(col.r, col.g, col.b, 0.55)
		_draw_landmark_glyph(String(l.get("kind", "")), p, col)

	for c: Node3D in get_tree().get_nodes_in_group("chests"):
		if c is Node3D:
			var node3d: Node3D = c
			var ccol: Color = COL_CHEST
			if "looted" in node3d and node3d.get("looted"):
				ccol = Color(ccol.r, ccol.g, ccol.b, 0.35)
			_pin_at(node3d.global_position, ccol, player, player_yaw, center, radius_px,
					PIN_RADIUS_PX - 0.6)

	for f: Node3D in get_tree().get_nodes_in_group("goblin_fires"):
		if f is Node3D:
			_pin_at((f as Node3D).global_position, COL_FIRE, player, player_yaw,
					center, radius_px, PIN_RADIUS_PX - 1.0)

	for n: Node3D in get_tree().get_nodes_in_group("npcs"):
		if n is Node3D:
			_pin_at((n as Node3D).global_position, COL_NPC, player, player_yaw,
					center, radius_px, PIN_RADIUS_PX)

	for e: Node3D in get_tree().get_nodes_in_group("enemies"):
		if e is Node3D:
			var enode: Node3D = e
			var dist_e: float = 999.0
			if player != null:
				dist_e = (enode.global_position - player.global_position).length()
			var ec: Color = COL_ENEMY
			if dist_e < ENEMY_FLASH_RANGE:
				# REFINE: visual — enemy aggro flash rate 8.0 → 6.5 rad/s
				# (≈1.04 Hz vs prior 1.27 Hz). The new wider ENEMY_FLASH_RANGE
				# (9.0m) means more pins flash per frame; each flash should read
				# calmer so the cluster doesn't strobe. THEME §12 motion that
				# doesn't feel mechanical — minimap warning is a heartbeat, not
				# a strobe. Alden's low-to-medium combat tolerance directly served.
				var a: float = 0.55 + 0.45 * (sin(_pulse_t * 6.5) * 0.5 + 0.5)
				ec = Color(ec.r, ec.g, ec.b, a)
			_pin_at(enode.global_position, ec, player, player_yaw,
					center, radius_px, PIN_RADIUS_PX)

	for b: Node3D in get_tree().get_nodes_in_group("bosses"):
		if b is Node3D:
			_pin_at((b as Node3D).global_position, COL_BOSS, player, player_yaw,
					center, radius_px, PIN_RADIUS_PX + 1.6)

	for p in _pings:
		var ppos: Vector3 = p.get("pos", Vector3.ZERO)
		var pcol: Color = p.get("color", COL_CRYSTAL)
		var t: float = float(p.get("t", 0.0))
		var k: float = clamp(t / PING_LIFETIME, 0.0, 1.0)
		var alpha: float = 1.0 - k
		var rad: float = lerp(2.0, 14.0, k)
		var pp: Vector2 = _world_to_minimap(ppos, player, player_yaw, center, radius_px)
		# REFINE: visual — ping ring stroke 1.6 → 1.8 px. Pairs with the longer
		# PING_LIFETIME (1.6s) — the expanding ring now carries visible weight
		# throughout its tail instead of dissolving into one-pixel thinness near
		# the end of the fade.
		draw_arc(pp, rad, 0.0, TAU, 24, Color(pcol.r, pcol.g, pcol.b, alpha), 1.8, true)

	# REFINE: visual — player pulse rate 3.0 → 2.5 rad/s (≈0.40 Hz instead of
	# 0.48 Hz). Matches THEME §12 character idle breathing period (2.5s Y-bob);
	# minimap player heartbeat now syncs with the procedural character breathing
	# the §12 rule describes. Cross-system rhythm.
	var pulse: float = 0.85 + 0.15 * sin(_pulse_t * 2.5)
	# REFINE: visual — player center radius 4.6/3.2 → 5.0/3.6 px. Player reads as
	# the "you are here" anchor; tiny size lift differentiates from NPC pins
	# (PIN_RADIUS_PX 3.4) without overwhelming the disc. Pairs with the COL_PLAYER
	# ember-gold differentiation above — color AND size now both signal
	# "this dot is you", not "this dot is one of seven gold villagers".
	draw_circle(center, 5.0 * pulse, COL_INK)
	draw_circle(center, 3.6 * pulse, COL_PLAYER)
	# REFINE: visual — heading triangle slightly larger (Y -8 → -8.5, flanks
	# ±3.5/-2.5 → ±3.8/-2.7). ~6% more silhouette area reads cleaner at the
	# small minimap scale, especially at the camera polish run's wider rest
	# frame (default distance 8.0m).
	var tri: PackedVector2Array = PackedVector2Array([
		center + Vector2(0.0, -8.5),
		center + Vector2( 3.8, -2.7),
		center + Vector2(-3.8, -2.7),
	])
	draw_colored_polygon(tri, COL_PLAYER)
	draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), COL_INK, 1.2, true)

# ----------------------------------------------------------------------
# Drawing helpers
# ----------------------------------------------------------------------
func _pin_at(world_pos: Vector3, col: Color, player: Node3D, player_yaw: float,
		center: Vector2, radius_px: float, pin_radius: float) -> void:
	var p: Vector2 = _world_to_minimap(world_pos, player, player_yaw, center, radius_px)
	var dist_w: float = (Vector2(world_pos.x, world_pos.z) - _player_xz(player)).length()
	if dist_w > visible_radius_m:
		var ang: float = (p - center).angle()
		p = center + Vector2(cos(ang), sin(ang)) * (radius_px - 4.0)
		col = Color(col.r, col.g, col.b, 0.65)
		var tip: Vector2 = center + Vector2(cos(ang), sin(ang)) * (radius_px - 1.0)
		draw_line(p, tip, COL_INK, 1.2, true)
	draw_circle(p, pin_radius + 0.8, COL_INK)
	draw_circle(p, pin_radius, col)

func _draw_landmark_glyph(kind: String, p: Vector2, col: Color) -> void:
	var base: float = 4.0
	match kind:
		"village":
			var box: Rect2 = Rect2(p - Vector2(base, base * 0.4), Vector2(base * 2.0, base))
			draw_rect(box, col, true)
			var roof: PackedVector2Array = PackedVector2Array([
				p + Vector2(-base - 1.0, -base * 0.4),
				p + Vector2(0.0, -base - 1.0),
				p + Vector2( base + 1.0, -base * 0.4),
			])
			draw_colored_polygon(roof, col)
			draw_polyline(PackedVector2Array([roof[0], roof[1], roof[2]]), COL_INK, 1.0, true)
		"well":
			draw_arc(p, base, 0.0, TAU, 16, col, 1.6, true)
		"campfire":
			var ftri: PackedVector2Array = PackedVector2Array([
				p + Vector2(-base * 0.7,  base * 0.6),
				p + Vector2( base * 0.7,  base * 0.6),
				p + Vector2( 0.0,        -base * 0.9),
			])
			draw_colored_polygon(ftri, col)
		"cave":
			var dia: PackedVector2Array = PackedVector2Array([
				p + Vector2(0.0, -base - 1.0),
				p + Vector2(base + 1.0, 0.0),
				p + Vector2(0.0, base + 1.0),
				p + Vector2(-base - 1.0, 0.0),
			])
			draw_colored_polygon(dia, col)
			draw_polyline(PackedVector2Array([dia[0], dia[1], dia[2], dia[3], dia[0]]),
				COL_INK, 1.0, true)
		"camp":
			var ttri: PackedVector2Array = PackedVector2Array([
				p + Vector2(-base, base * 0.6),
				p + Vector2(0.0, -base - 1.0),
				p + Vector2(base, base * 0.6),
			])
			draw_colored_polygon(ttri, col)
		"boss":
			draw_circle(p, base + 1.0, col)
			draw_circle(p + Vector2(-1.6, -0.8), 1.0, COL_INK)
			draw_circle(p + Vector2( 1.6, -0.8), 1.0, COL_INK)
		_:
			draw_circle(p, base * 0.7, col)

func _draw_cardinal_letter(letter: String, center: Vector2, radius_px: float,
		ang: float, _yaw_unused: float) -> void:
	var p: Vector2 = center + Vector2(cos(ang), sin(ang)) * (radius_px - 14.0)
	var s: float = 4.0
	var col: Color = COL_INK
	match letter:
		"N":
			draw_line(p + Vector2(-s, s), p + Vector2(-s, -s), col, 1.5, true)
			draw_line(p + Vector2( s, s), p + Vector2( s, -s), col, 1.5, true)
			draw_line(p + Vector2(-s, -s), p + Vector2(s, s), col, 1.5, true)
		"E":
			draw_line(p + Vector2(-s, -s), p + Vector2(-s, s), col, 1.5, true)
			draw_line(p + Vector2(-s, -s), p + Vector2( s, -s), col, 1.5, true)
			draw_line(p + Vector2(-s,  0), p + Vector2( s * 0.5, 0), col, 1.5, true)
			draw_line(p + Vector2(-s,  s), p + Vector2( s, s), col, 1.5, true)
		"S":
			draw_arc(p + Vector2(0, -s * 0.5), s * 0.7, PI * 0.0, PI * 1.2, 12, col, 1.5, true)
			draw_arc(p + Vector2(0,  s * 0.5), s * 0.7, PI * 1.0, PI * 2.2, 12, col, 1.5, true)
		"W":
			draw_line(p + Vector2(-s, -s), p + Vector2(-s * 0.5, s), col, 1.5, true)
			draw_line(p + Vector2(-s * 0.5, s), p + Vector2(0, -s * 0.5), col, 1.5, true)
			draw_line(p + Vector2(0, -s * 0.5), p + Vector2(s * 0.5, s), col, 1.5, true)
			draw_line(p + Vector2(s * 0.5, s), p + Vector2(s, -s), col, 1.5, true)

# ----------------------------------------------------------------------
# Coordinate conversion
# ----------------------------------------------------------------------
func _world_to_minimap(world_pos: Vector3, player: Node3D, player_yaw: float,
		center: Vector2, radius_px: float) -> Vector2:
	var origin: Vector2 = _player_xz(player)
	var rel: Vector2 = Vector2(world_pos.x, world_pos.z) - origin
	var rotated: Vector2 = rel.rotated(-player_yaw)
	var ppm: float = radius_px / visible_radius_m
	return center + Vector2(rotated.x * ppm, rotated.y * ppm)

func _player_node() -> Node3D:
	var arr: Array = get_tree().get_nodes_in_group("player")
	if arr.is_empty():
		return null
	if arr[0] is Node3D:
		return arr[0]
	return null

func _player_xz(player: Node3D) -> Vector2:
	if player == null:
		return Vector2.ZERO
	return Vector2(player.global_position.x, player.global_position.z)

func _player_yaw() -> float:
	var p: Node3D = _player_node()
	if p == null:
		return 0.0
	return p.rotation.y
