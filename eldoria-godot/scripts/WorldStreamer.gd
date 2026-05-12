extends Node
# Realm of Eldoria — WorldStreamer
#
# Dynamically loads and unloads chunk scenes as the player moves through
# the 3D world.  Keeps only nearby chunks in memory, preventing the entire
# world from living in RAM at once.
#
# Attach to a "WorldStreamer" node in World.tscn (sibling of Player).
# Chunks live in res://chunks/ and follow the naming convention:
#   chunk_X_Z.tscn    (X and Z are signed integer grid coordinates)
#
# Chunk grid: each chunk covers CHUNK_SIZE × CHUNK_SIZE world units on the
# X/Z plane.  Y is ignored for grid purposes (terrain handles height).
#
# Usage:
#   WorldStreamer.set_player(player_node)   # called automatically in _ready
#   WorldStreamer.force_load_chunk(Vector2i(0,0))

# ── Settings ──────────────────────────────────────────────────────────────
@export var player_path: NodePath = NodePath("../Player")
@export var chunk_root_path: NodePath = NodePath("../ChunkRoot")  # Node3D in scene
@export var chunk_size: float  = 64.0    # world units per chunk side
@export var load_radius: int   = 1       # chunks to keep loaded around player
@export var chunk_dir: String  = "res://chunks/"

# ── Internal state ─────────────────────────────────────────────────────────
var loaded_chunks: Dictionary = {}        # Vector2i → Node3D
var _async_loading: Dictionary = {}       # Vector2i → path (pending)
var _player: Node  = null
var _last_player_chunk: Vector2i = Vector2i(-9999, -9999)
var _chunk_root: Node = null

func _ready() -> void:
	_player     = get_node_or_null(player_path)
	_chunk_root = get_node_or_null(chunk_root_path)
	if not _chunk_root:
		_chunk_root = Node3D.new()
		_chunk_root.name = "ChunkRoot"
		get_parent().add_child(_chunk_root)

func set_player(p: Node) -> void:
	_player = p

# ==========================================================================
func _process(_delta: float) -> void:
	if not _player:
		return
	var pc := _player_chunk()
	if pc == _last_player_chunk:
		_poll_async_loads()
		return
	_last_player_chunk = pc
	_update_chunks(pc)
	_poll_async_loads()

# ==========================================================================
# Grid helpers
# ==========================================================================
func _player_chunk() -> Vector2i:
	var pos := _player.global_position
	return Vector2i(int(floor(pos.x / chunk_size)),
	int(floor(pos.z / chunk_size)))

func chunk_world_origin(grid: Vector2i) -> Vector3:
	return Vector3(grid.x * chunk_size, 0.0, grid.y * chunk_size)

# ==========================================================================
# Streaming loop
# ==========================================================================
func _update_chunks(center: Vector2i) -> void:
	var needed: Array[Vector2i] = []

	for dx in range(-load_radius, load_radius + 1):
		for dz in range(-load_radius, load_radius + 1):
			var pos := Vector2i(center.x + dx, center.y + dz)
			needed.append(pos)
			if not loaded_chunks.has(pos) and not _async_loading.has(pos):
				_request_load(pos)

	# Unload chunks outside the radius.
	for pos in loaded_chunks.keys():
		if pos not in needed:
			_unload_chunk(pos)

func _request_load(pos: Vector2i) -> void:
	var path := "%schunk_%d_%d.tscn" % [chunk_dir, pos.x, pos.y]
	if not ResourceLoader.exists(path):
		return
	# Async threaded load — no frame spike.
	ResourceLoader.load_threaded_request(path)
	_async_loading[pos] = path

func _poll_async_loads() -> void:
	for pos: Vector2i in _async_loading.keys():
		var path: String = _async_loading[pos]
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var packed := ResourceLoader.load_threaded_get(path)
			_async_loading.erase(pos)
			_instantiate_chunk(pos, packed)
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			_async_loading.erase(pos)

func _instantiate_chunk(pos: Vector2i, packed: PackedScene) -> void:
	var chunk: Node3D = packed.instantiate()
	chunk.global_position = chunk_world_origin(pos)
	_chunk_root.add_child(chunk)
	loaded_chunks[pos] = chunk

	# Restore persisted enemy/object state if any.
	if is_instance_valid(GameBrain) and GameBrain.global_memory.has(pos):
		_restore_chunk_state(chunk, GameBrain.global_memory[pos])

	# Let the chunk adapt to current playstyle.
	if chunk.has_method("adapt_enemies"):
		chunk.adapt_enemies()

	# Register with map.
	if is_instance_valid(MapSystem):
		MapSystem.register_chunk(pos, chunk_world_origin(pos))

func _unload_chunk(pos: Vector2i) -> void:
	if not loaded_chunks.has(pos):
		return
	var chunk := loaded_chunks[pos]
	# Persist state before removal.
	if is_instance_valid(GameBrain):
		GameBrain.global_memory[pos] = _capture_chunk_state(chunk)
	chunk.queue_free()
	loaded_chunks.erase(pos)

# ==========================================================================
# Chunk state persistence
# ==========================================================================
func _capture_chunk_state(chunk: Node) -> Dictionary:
	if chunk.has_method("get_save_state"):
		return chunk.get_save_state()
	# Default: count living enemies.
	var ec := 0
	for child in chunk.get_children():
		if child.has_method("take_damage"):
			ec += 1
	return {"enemies_alive": ec}

func _restore_chunk_state(chunk: Node, state: Dictionary) -> void:
	if chunk.has_method("load_save_state"):
		chunk.load_save_state(state)

# ==========================================================================
# Public utilities
# ==========================================================================
func force_load_chunk(pos: Vector2i) -> void:
	if not loaded_chunks.has(pos) and not _async_loading.has(pos):
		_request_load(pos)

func get_loaded_positions() -> Array:
	return loaded_chunks.keys()
