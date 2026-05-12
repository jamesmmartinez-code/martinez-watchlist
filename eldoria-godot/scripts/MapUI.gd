extends Control
# Realm of Eldoria — MapUI
#
# Full-screen map overlay with fog-of-war, player tracking, objective markers,
# and smooth open/close animation.  Also contains a MiniMap that is always
# visible in the top-right corner of the HUD.
#
# Attach to a Control node named "MapUI" under UI/CanvasLayer in the scene.
# Toggle with the "map" input action (default: M or Tab).
#
# Requires: MapSystem autoload
# Optional: WorldStreamer (for live chunk updates)

# ── Map settings ───────────────────────────────────────────────────────────
const MAP_SCALE:       float  = 0.08    # world units → map pixels
const CHUNK_PIX:       float  = 10.0   # size of one chunk square on map
const AREA_PIX:        float  = 18.0   # size of a named-area badge on map
const DISCOVER_COLOR:  Color  = Color(0.70, 0.80, 0.90)
const UNDISCOVERED:    Color  = Color(0.15, 0.15, 0.20)
const OBJECTIVE_COLOR: Color  = Color(1.00, 0.85, 0.10)
const PLAYER_COLOR:    Color  = Color(0.20, 0.90, 1.00)
const AREA_COLOR:      Color  = Color(0.55, 0.35, 0.80)

# ── Node references (create at runtime if missing) ────────────────────────
var _canvas:         Control     = null   # main map canvas
var _player_dot:     ColorRect   = null
var _icon_container: Control     = null   # holds chunk/area icons
var _minimap:        Control     = null   # always-visible minimap
var _minimap_dot:    ColorRect   = null

# ── External reference ────────────────────────────────────────────────────
var _player: Node = null

func _ready() -> void:
	# Must process even while the game is paused (we pause on open and need
	# input to close again; without ALWAYS we'd be locked out of our own menu).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = get_tree().current_scene.get_node_or_null("Player")
	_build_ui()
	visible = false
	if is_instance_valid(MapSystem):
		MapSystem.map_updated.connect(_on_map_updated)
	_on_map_updated()

# ==========================================================================
# UI construction
# ==========================================================================
func _build_ui() -> void:
	# ── Full-screen dark backdrop ──────────────────────────────────────────
	var bg := ColorRect.new()
	bg.name = "Bg"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.10, 0.88)
	add_child(bg)

	# ── Map title ─────────────────────────────────────────────────────────
	var title := Label.new()
	title.name = "Title"
	title.text = "WORLD MAP"
	title.add_theme_font_size_override("font_size", 20)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 12
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# ── Scrollable icon container ─────────────────────────────────────────
	_icon_container = Control.new()
	_icon_container.name = "IconContainer"
	_icon_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon_container.offset_top = 50
	add_child(_icon_container)

	# ── Player dot ────────────────────────────────────────────────────────
	_player_dot = ColorRect.new()
	_player_dot.name = "PlayerDot"
	_player_dot.size = Vector2(8, 8)
	_player_dot.color = PLAYER_COLOR
	add_child(_player_dot)   # on top of icons

	# ── Close hint ────────────────────────────────────────────────────────
	var hint := Label.new()
	hint.text = "[M] Close"
	hint.add_theme_font_size_override("font_size", 13)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.offset_bottom = -12
	hint.offset_right  = -16
	add_child(hint)

	# ── Minimap (always visible) ──────────────────────────────────────────
	_build_minimap()

# ==========================================================================
func _build_minimap() -> void:
	var parent := get_parent()
	_minimap = Control.new()
	_minimap.name = "MiniMap"
	_minimap.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_minimap.offset_left   = -120
	_minimap.offset_bottom = 120
	_minimap.offset_right  = -8
	_minimap.offset_top    = 8

	var mm_bg := ColorRect.new()
	mm_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mm_bg.color = Color(0.05, 0.05, 0.10, 0.70)
	_minimap.add_child(mm_bg)

	_minimap_dot = ColorRect.new()
	_minimap_dot.name  = "MiniPlayerDot"
	_minimap_dot.size  = Vector2(6, 6)
	_minimap_dot.color = PLAYER_COLOR
	_minimap.add_child(_minimap_dot)

	parent.add_child(_minimap)

# ==========================================================================
# Map update
# ==========================================================================
func _on_map_updated() -> void:
	if not is_instance_valid(MapSystem):
		return
	# Rebuild icons for all known chunks.
	for child in _icon_container.get_children():
		child.queue_free()

	# ── Chunk icons ────────────────────────────────────────────────────────
	for grid: Vector2i in MapSystem.all_chunks.keys():
		var world_origin: Vector3 = MapSystem.all_chunks[grid]
		var map_pos := _world_to_map(world_origin)
		var cr := ColorRect.new()
		cr.size  = Vector2(CHUNK_PIX - 1, CHUNK_PIX - 1)
		cr.position = map_pos - Vector2(CHUNK_PIX * 0.5, CHUNK_PIX * 0.5)
		cr.color = DISCOVER_COLOR if MapSystem.is_chunk_discovered(grid) else UNDISCOVERED
		_icon_container.add_child(cr)

	# ── Named area badges ──────────────────────────────────────────────────
	for area_name: String in MapSystem.all_areas.keys():
		var entry   := MapSystem.all_areas[area_name]
		var map_pos: Vector3 = _world_to_map(Vector3(entry["pos"]))
		var disc    := bool(entry.get("discovered", false))
		var lbl := Label.new()
		lbl.text = area_name if disc else "???"
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.modulate = AREA_COLOR if disc else UNDISCOVERED
		lbl.position = map_pos + Vector2(4, -8)
		_icon_container.add_child(lbl)

	# ── Objective markers ──────────────────────────────────────────────────
	for marker_id: String in MapSystem.objectives.keys():
		var map_pos := _world_to_map(MapSystem.objectives[marker_id])
		var star := Label.new()
		star.text     = "★"
		star.modulate = OBJECTIVE_COLOR
		star.add_theme_font_size_override("font_size", 14)
		star.position = map_pos - Vector2(6, 7)
		_icon_container.add_child(star)

# ==========================================================================
# Per-frame: track player + minimap
# ==========================================================================
func _process(_delta: float) -> void:
	if not _player:
		_player = get_tree().current_scene.get_node_or_null("Player")
		return
	var map_pos := _world_to_map(_player.global_position)

	# Full-screen map player dot.
	if visible and _player_dot:
		_player_dot.position = map_pos - _player_dot.size * 0.5

	# Minimap player dot — uses a tighter scale.
	if _minimap_dot:
		var mini_scale := MAP_SCALE * 0.3
		var mp := _world_to_map_scaled(_player.global_position, mini_scale)
		var mm_center := _minimap.size * 0.5
		_minimap_dot.position = mm_center + mp - _minimap_dot.size * 0.5

# ==========================================================================
# Input
# ==========================================================================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		_toggle()

func _toggle() -> void:
	if visible:
		_close()
	else:
		_open()

func _open() -> void:
	visible     = true
	scale       = Vector2(0.90, 0.90)
	modulate.a  = 0.0
	var tw      := create_tween().set_parallel(true)
	tw.tween_property(self, "scale",      Vector2.ONE, 0.18).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "modulate:a", 1.0,         0.18)
	get_tree().paused = true

func _close() -> void:
	get_tree().paused = false
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale",      Vector2(0.90, 0.90), 0.14).set_trans(Tween.TRANS_EXPO)
	tw.tween_property(self, "modulate:a", 0.0,                 0.14)
	tw.chain().tween_callback(func() -> void: visible = false)

# ==========================================================================
# Coordinate helpers
# ==========================================================================
func _world_to_map(world_pos: Vector3) -> Vector2:
	return _world_to_map_scaled(world_pos, MAP_SCALE)

func _world_to_map_scaled(world_pos: Vector3, scale_factor: float) -> Vector2:
	# Projects 3D world (x,z) to 2D map space, centred in the panel.
	var half := size * 0.5
	return half + Vector2(world_pos.x, world_pos.z) * scale_factor

# ==========================================================================
# Direction arrow helper (call from HUD if desired)
# ==========================================================================
func get_direction_to_objective(objective_id: String) -> float:
	if not _player or not is_instance_valid(MapSystem):
		return 0.0
	var obj_pos: Vector3 = MapSystem.objectives.get(objective_id, Vector3.ZERO)
	var diff := obj_pos - _player.global_position
	return Vector2(diff.x, diff.z).angle()
