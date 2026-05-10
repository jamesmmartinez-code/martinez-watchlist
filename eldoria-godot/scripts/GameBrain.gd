extends Node
# Realm of Eldoria — Global Gameplay Brain (autoload singleton)
#
# Single source of truth for playstyle tracking, ability evolution flags,
# and rolling action history.  Every adaptive system reads from here rather
# than querying the Player node directly — this removes brittle node-reference
# chains, makes the data trivially saveable, and lets the boss/enemies react
# even when the player reference hasn't been found yet.
#
# Registered as autoload "GameBrain" in project.godot [autoload] section.
# Access anywhere with: GameBrain.record_action("aggressive")
#                       GameBrain.get_playstyle_ratio("dash_heavy")
#                       GameBrain.has_evolution("slash_multihit")

# ── Playstyle counters ────────────────────────────────────────────────────
# Raw counts.  Use get_playstyle_ratio() for scale-invariant comparisons.
# Stored as floats so decay math works without rounding errors.
# Use get_raw(key) when you need an integer count.
var playstyle: Dictionary = {
	"aggressive": 0.0,   # attacks used
	"defensive":  0.0,   # times hit
	"airborne":   0.0,   # jumps
	"dash_heavy": 0.0,   # Dash Attack fires
}

# ── Decay system ──────────────────────────────────────────────────────────
# Prevents old playstyle data from permanently locking enemies into one
# pattern.  Every DECAY_INTERVAL seconds, all counters are multiplied by
# DECAY_FACTOR.  Half-life ≈ 10 minutes of play (0.97 every 30s × 20 ticks).
const DECAY_INTERVAL: float = 30.0
const DECAY_FACTOR:   float = 0.97
var _decay_timer: float = 0.0

# ── Evolution flags ───────────────────────────────────────────────────────
# Permanent mutations earned through play.  Saved with the game.
var evolution_flags: Dictionary = {}

# ── World / streaming memory ──────────────────────────────────────────────
# Chunk + area state persisted while chunks are unloaded.
# Key: Vector2i grid pos (WorldStreamer) or String area name (WorldManager)
# Value: arbitrary Dictionary produced by the chunk/area on unload.
var global_memory: Dictionary = {}

# ── World flags ───────────────────────────────────────────────────────────
# Lightweight key-value store for world-state events that other systems need
# to query without coupling to a specific node.  Examples:
#   GameBrain.set_flag("helped_crystal_order")
#   GameBrain.has_flag("corrupted_zone_ruins")
#   GameBrain.set_flag("boss_killed", true)
# Values are booleans by default; pass a second argument for richer data.
var world_flags: Dictionary = {}

# Current area the player is in (set by WorldManager).
var current_area: String = ""

# ── Rolling action history (last HISTORY_MAX entries) ─────────────────────
var history: Array = []
const HISTORY_MAX: int = 60   # ~1 min of active play at normal pace

# ── Signals ───────────────────────────────────────────────────────────────
signal playstyle_changed(key: String, new_value: int)
signal evolution_unlocked(key: String)
signal area_changed(area_name: String)

# ─────────────────────────────────────────────────────────────────────────
# Core API
# ─────────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_decay_timer += delta
	if _decay_timer >= DECAY_INTERVAL:
		_decay_timer = 0.0
		_apply_decay()

func _apply_decay() -> void:
	# Soft exponential decay — old habits fade, recent play drives adaptation.
	# Keeps floor at 0; never goes negative.
	for k: String in playstyle.keys():
		playstyle[k] = maxf(0.0, float(playstyle[k]) * DECAY_FACTOR)

func record_action(action: String) -> void:
	# Increment the matching playstyle counter and append to history.
	# Silently ignores unknown keys so new playstyles can be tracked without
	# risking a crash on old save files that lack the key.
	if not playstyle.has(action):
		return
	playstyle[action] = float(playstyle[action]) + 1.0
	history.append({"action": action, "tick": Time.get_ticks_msec()})
	if history.size() > HISTORY_MAX:
		history.pop_front()
	playstyle_changed.emit(action, playstyle[action])

func get_playstyle_ratio(key: String) -> float:
	# Returns this key as a fraction of all recorded actions (0.0–1.0).
	# Scale-invariant: a 1-hour session and a 5-minute session produce the
	# same ratio for the same relative habits.  Safe to call every frame.
	var total: int = 0
	for v: int in playstyle.values():
		total += v
	if total == 0:
		return 0.0
	return float(playstyle.get(key, 0)) / float(total)

func get_raw(key: String) -> int:
	return int(round(float(playstyle.get(key, 0.0))))

# ── Debug ─────────────────────────────────────────────────────────────────

func debug_print() -> void:
	print("── GameBrain ─────────────────────")
	for k: String in playstyle:
		var ratio := get_playstyle_ratio(k)
		print("  %-12s  raw=%-6.1f  ratio=%.2f" % [k, float(playstyle[k]), ratio])
	print("  evolutions: %s" % str(evolution_flags.keys()))
	print("  history:    %d entries" % history.size())
	print("─────────────────────────────────")

# ── Evolution flags ───────────────────────────────────────────────────────

func set_evolution(key: String, value: bool = true) -> void:
	if value and not evolution_flags.get(key, false):
		evolution_flags[key] = true
		evolution_unlocked.emit(key)
	elif not value:
		evolution_flags.erase(key)

func has_evolution(key: String) -> bool:
	return evolution_flags.get(key, false)

# ── World flags ───────────────────────────────────────────────────────────

func set_flag(key: String, value: Variant = true) -> void:
	world_flags[key] = value

func has_flag(key: String) -> bool:
	return world_flags.get(key, false) != false

func get_flag(key: String, default: Variant = null) -> Variant:
	return world_flags.get(key, default)

func clear_flag(key: String) -> void:
	world_flags.erase(key)

# ── Save / load ───────────────────────────────────────────────────────────
# Called by Player.gd's save_game() / load_game() so all data survives
# sessions (no need for a separate save slot — piggybacks on player save).

func get_save_data() -> Dictionary:
	return {
		"playstyle":       playstyle.duplicate(),
		"evolution_flags": evolution_flags.duplicate(),
		"current_area":    current_area,
		"world_flags":     world_flags.duplicate(),
		# global_memory keys may be Vector2i — serialise to string.
		"global_memory":   _serialize_memory(),
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("playstyle"):
		for k: String in data["playstyle"]:
			if playstyle.has(k):
				playstyle[k] = float(data["playstyle"][k])
	if data.has("evolution_flags"):
		evolution_flags = data["evolution_flags"].duplicate()
	if data.has("current_area"):
		current_area = str(data["current_area"])
	if data.has("world_flags"):
		world_flags = data["world_flags"].duplicate()
	if data.has("global_memory"):
		_deserialize_memory(data["global_memory"])

func _serialize_memory() -> Dictionary:
	var out: Dictionary = {}
	for k in global_memory.keys():
		var key_str: String = str(k) if k is Vector2i else str(k)
		out[key_str] = global_memory[k]
	return out

func _deserialize_memory(saved: Dictionary) -> void:
	# Area-name keys come back as plain strings; chunk keys are "x,y" pairs.
	for key_str: String in saved.keys():
		var parts := key_str.split(",")
		if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
			global_memory[Vector2i(int(parts[0]), int(parts[1]))] = saved[key_str]
		else:
			global_memory[key_str] = saved[key_str]

# ── World adaptation helpers ──────────────────────────────────────────────
# Called by WorldBuilder.gd on zone transitions to adjust global spawn density
# and patrol frequency based on the player's established playstyle.

func on_area_changed(area_name: String) -> void:
	# Called by WorldManager whenever the player enters a new area.
	# Notifies subscribers and records the transition so singletons
	# (QuestSystem, MapSystem) can react.
	current_area = area_name
	emit_signal("area_changed", area_name)
	if is_instance_valid(QuestSystem):
		QuestSystem.on_area_entered(area_name)

func get_world_pressure() -> float:
	# Returns 0.0 (passive) – 1.0 (aggressive) for WorldBuilder spawn scaling.
	# Blends aggression dominance with anti-defensive: a rush player gets a
	# harder world; a player who just keeps getting hit gets a slightly easier one.
	var agg_r := get_playstyle_ratio("aggressive")
	var def_r := get_playstyle_ratio("defensive")
	return clampf(agg_r - def_r * 0.5, 0.0, 1.0)
