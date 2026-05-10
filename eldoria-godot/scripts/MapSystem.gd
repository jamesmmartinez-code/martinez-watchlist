extends Node
# Realm of Eldoria — MapSystem (autoload singleton)
#
# Single source of truth for world map data.
# Tracks all registered chunks + named areas, which ones the player
# has discovered, and objective marker positions.
#
# Registered as autoload "MapSystem" in project.godot [autoload].
# Any script can call:
#   MapSystem.discover_chunk(Vector2i(1, 0))
#   MapSystem.on_area_entered("BossArea")
#   MapSystem.set_objective("kill_echo_knight", pos)

signal map_updated                              # UI should redraw
signal chunk_discovered(grid_pos: Vector2i)
signal area_discovered(area_name: String)

# ── Chunk registry ─────────────────────────────────────────────────────────
# grid_pos (Vector2i) → world origin (Vector3)
var all_chunks: Dictionary      = {}
# grid_pos (Vector2i) → true
var discovered_chunks: Dictionary = {}

# ── Named area registry ────────────────────────────────────────────────────
# area_name (String) → { "pos": Vector3, "discovered": bool }
var all_areas: Dictionary       = {}
var current_area: String        = ""

# ── Objective markers ──────────────────────────────────────────────────────
# marker_id (String) → Vector3 world position
var objectives: Dictionary      = {}

# ── Fast-travel nodes (unlocked positions) ────────────────────────────────
var fast_travel_nodes: Array[Dictionary] = []  # [{ "id", "name", "pos" }]

# ==========================================================================
# Chunk API (used by WorldStreamer)
# ==========================================================================
func register_chunk(grid: Vector2i, world_origin: Vector3) -> void:
	all_chunks[grid] = world_origin

func discover_chunk(grid: Vector2i) -> void:
	if discovered_chunks.has(grid):
		return
	discovered_chunks[grid] = true
	emit_signal("chunk_discovered", grid)
	emit_signal("map_updated")

func is_chunk_discovered(grid: Vector2i) -> bool:
	return discovered_chunks.get(grid, false)

# ==========================================================================
# Named-area API (used by WorldManager)
# ==========================================================================
func register_area(name: String, world_pos: Vector3) -> void:
	all_areas[name] = {"pos": world_pos, "discovered": false}

func on_area_entered(area_name: String) -> void:
	current_area = area_name
	if not all_areas.has(area_name):
		all_areas[area_name] = {"pos": Vector3.ZERO, "discovered": false}
	if not all_areas[area_name]["discovered"]:
		all_areas[area_name]["discovered"] = true
		emit_signal("area_discovered", area_name)
		emit_signal("map_updated")

func is_area_discovered(area_name: String) -> bool:
	return all_areas.get(area_name, {}).get("discovered", false)

# ==========================================================================
# Objective markers
# ==========================================================================
func set_objective(marker_id: String, world_pos: Vector3) -> void:
	objectives[marker_id] = world_pos
	emit_signal("map_updated")

func clear_objective(marker_id: String) -> void:
	objectives.erase(marker_id)
	emit_signal("map_updated")

func get_objectives() -> Dictionary:
	return objectives

# ==========================================================================
# Fast travel
# ==========================================================================
func unlock_fast_travel(id: String, display_name: String, world_pos: Vector3) -> void:
	for ft in fast_travel_nodes:
		if ft["id"] == id:
			return   # already registered
	fast_travel_nodes.append({"id": id, "name": display_name, "pos": world_pos})
	emit_signal("map_updated")

func get_fast_travel_nodes() -> Array[Dictionary]:
	return fast_travel_nodes

# ==========================================================================
# Save / load (piggybacked on Player save)
# ==========================================================================
func get_save_data() -> Dictionary:
	# Convert Vector2i keys to strings for JSON serialisation.
	var dc: Dictionary = {}
	for k: Vector2i in discovered_chunks.keys():
		dc["%d,%d" % [k.x, k.y]] = true
	return {
		"discovered_chunks": dc,
		"all_areas":         all_areas.duplicate(true),
		"fast_travel":       fast_travel_nodes.duplicate(true),
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("discovered_chunks"):
		for key: String in data["discovered_chunks"]:
			var parts := key.split(",")
			if parts.size() == 2:
				discovered_chunks[Vector2i(int(parts[0]), int(parts[1]))] = true
	if data.has("all_areas"):
		all_areas = data["all_areas"].duplicate(true)
	if data.has("fast_travel"):
		fast_travel_nodes = data["fast_travel"].duplicate(true)
