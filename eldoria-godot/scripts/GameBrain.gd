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
var playstyle: Dictionary = {
	"aggressive": 0,   # attacks used
	"defensive":  0,   # times hit
	"airborne":   0,   # jumps
	"dash_heavy": 0,   # Dash Attack fires
}

# ── Evolution flags ───────────────────────────────────────────────────────
# Permanent mutations earned through play.  Saved with the game.
var evolution_flags: Dictionary = {}

# ── Rolling action history (last HISTORY_MAX entries) ─────────────────────
var history: Array = []
const HISTORY_MAX: int = 60   # ~1 min of active play at normal pace

# ── Signals ───────────────────────────────────────────────────────────────
signal playstyle_changed(key: String, new_value: int)
signal evolution_unlocked(key: String)

# ─────────────────────────────────────────────────────────────────────────
# Core API
# ─────────────────────────────────────────────────────────────────────────

func record_action(action: String) -> void:
	# Increment the matching playstyle counter and append to history.
	# Silently ignores unknown keys so new playstyles can be tracked without
	# risking a crash on old save files that lack the key.
	if not playstyle.has(action):
		return
	playstyle[action] += 1
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
	return playstyle.get(key, 0)

# ── Evolution flags ───────────────────────────────────────────────────────

func set_evolution(key: String, value: bool = true) -> void:
	if value and not evolution_flags.get(key, false):
		evolution_flags[key] = true
		evolution_unlocked.emit(key)
	elif not value:
		evolution_flags.erase(key)

func has_evolution(key: String) -> bool:
	return evolution_flags.get(key, false)

# ── Save / load ───────────────────────────────────────────────────────────
# Called by Player.gd's save_game() / load_game() so all data survives
# sessions (no need for a separate save slot — piggybacks on player save).

func get_save_data() -> Dictionary:
	return {
		"playstyle":       playstyle.duplicate(),
		"evolution_flags": evolution_flags.duplicate(),
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("playstyle"):
		for k: String in data["playstyle"]:
			if playstyle.has(k):
				playstyle[k] = int(data["playstyle"][k])
	if data.has("evolution_flags"):
		evolution_flags = data["evolution_flags"].duplicate()

# ── World adaptation helpers ──────────────────────────────────────────────
# Called by WorldBuilder.gd on zone transitions to adjust global spawn density
# and patrol frequency based on the player's established playstyle.

func get_world_pressure() -> float:
	# Returns 0.0 (passive) – 1.0 (aggressive) for WorldBuilder spawn scaling.
	# Blends aggression dominance with anti-defensive: a rush player gets a
	# harder world; a player who just keeps getting hit gets a slightly easier one.
	var agg_r := get_playstyle_ratio("aggressive")
	var def_r := get_playstyle_ratio("defensive")
	return clampf(agg_r - def_r * 0.5, 0.0, 1.0)
