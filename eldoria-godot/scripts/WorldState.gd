extends Node
# Realm of Eldoria — WorldState (autoload singleton)
#
# Single source of truth for world progression: time of day, seasonal arc,
# corruption spread, and the four-stage evolution of the world itself.
# Folds TimeSystem + CorruptionSystem into one lean autoload rather than
# three nodes wiring each other via signals.
#
# Registered as autoload "WorldState" in project.godot [autoload].
#
# ── Time ──────────────────────────────────────────────────────────────────────
#  time_of_day  0.0–24.0  (hours).  Advances in real-time scaled by day_length.
#  day          integer counter, increments each midnight crossing.
#
# ── Season / Arc ─────────────────────────────────────────────────────────────
#  "calm"        — world at rest, low enemy density, friendly NPCs
#  "unrest"      — tensions rising, patrols more aggressive
#  "war"         — open conflict between factions, visible battle events
#  "apocalypse"  — corruption dominant, undead surge, crystal order mobilised
#
# ── Corruption ────────────────────────────────────────────────────────────────
#  0.0 = pristine  →  1.0 = fully corrupted
#  Rises when undead faction kills, falls when player helps crystal_order.
#  Above 0.6 the season tips toward "war"; above 0.85 → "apocalypse".
#
# ── Evolution stage ───────────────────────────────────────────────────────────
#  Stage 1 = tutorial calm  (day 1–4)
#  Stage 2 = first friction  (day 5–10)
#  Stage 3 = faction war     (day 11–20)
#  Stage 4 = end-game push   (day 21+)
#  Clamped at 4 — no regression.

# ==========================================================================
# Config
# ==========================================================================
@export var day_length: float = 300.0   # real seconds per in-game day (5 min)

const CORRUPTION_SPREAD_RATE: float  = 0.0004  # per second (passive, slow)
const CORRUPTION_DECAY_RATE: float   = 0.0008  # per second when crystal_order strong
const CORRUPTION_KILL_BONUS: float   = 0.005   # per undead enemy death
const CORRUPTION_HELP_REDUCTION: float = 0.018 # per crystal_order assist event
const CORRUPTION_ZONE_RATE: float    = 0.0015  # per second when undead hold a zone

# ==========================================================================
# State
# ==========================================================================
var day: int            = 1
var time_of_day: float  = 7.0    # start at 7 AM (morning light)
var season: String      = "calm" # calm | unrest | war | apocalypse
var corruption_level: float = 0.0
var evolution_stage: int    = 1

# Internal
var _day_frac_prev: float = 7.0 / 24.0   # track midnight crossing

# ==========================================================================
# Signals
# ==========================================================================
signal day_changed(new_day: int)
signal time_changed(new_time: float)      # emitted every half-hour of in-game time
signal season_changed(new_season: String)
signal corruption_changed(new_level: float)
signal stage_changed(new_stage: int)
signal midnight_crossed()
signal noon_crossed()

# ==========================================================================
# Lifecycle
# ==========================================================================
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_advance_time(delta)
	_spread_corruption(delta)
	_check_season()

# ==========================================================================
# Time
# ==========================================================================
func _advance_time(delta: float) -> void:
	var hours_per_second := 24.0 / day_length
	var prev := time_of_day
	time_of_day += hours_per_second * delta

	# Half-hour notification (UI clocks, lighting)
	if int(time_of_day * 2.0) != int(prev * 2.0):
		emit_signal("time_changed", time_of_day)

	# Midnight crossing
	if time_of_day >= 24.0:
		time_of_day -= 24.0
		day += 1
		emit_signal("day_changed", day)
		emit_signal("midnight_crossed")
		_check_evolution_stage()

	# Noon crossing
	if prev < 12.0 and time_of_day >= 12.0:
		emit_signal("noon_crossed")

func _check_evolution_stage() -> void:
	var new_stage: int
	if day <= 4:
		new_stage = 1
	elif day <= 10:
		new_stage = 2
	elif day <= 20:
		new_stage = 3
	else:
		new_stage = 4
	if new_stage != evolution_stage:
		evolution_stage = new_stage
		emit_signal("stage_changed", evolution_stage)

func is_daytime() -> bool:
	return time_of_day >= 6.0 and time_of_day < 20.0

func is_night() -> bool:
	return not is_daytime()

func get_ambient_light_factor() -> float:
	# 0.0 = full dark night, 1.0 = midday brightness.
	# Smooth sinusoidal transition — not a hard step.
	var t := time_of_day / 24.0
	return clampf(sin(t * PI) * 1.2, 0.0, 1.0)

# ==========================================================================
# Corruption
# ==========================================================================
func _spread_corruption(delta: float) -> void:
	# Passive spread (world naturally corrupts over time, very slowly).
	var net := CORRUPTION_SPREAD_RATE

	# Faster if undead hold zones (FactionSystem zone_control)
	if is_instance_valid(FactionSystem):
		var undead_zones := 0
		for f: String in FactionSystem.zone_control.values():
			if f == "undead":
				undead_zones += 1
		net += float(undead_zones) * CORRUPTION_ZONE_RATE

		# Crystal Order strength counteracts spread
		var co_strength: float = float(FactionSystem.faction_strength.get("crystal_order", 1.0))
		if co_strength > 0.6:
			net -= CORRUPTION_DECAY_RATE * (co_strength - 0.6) / 0.4

	corruption_level = clampf(corruption_level + net * delta, 0.0, 1.0)

func corrupt_from_undead_kill() -> void:
	# Called by FactionSystem.on_faction_enemy_died when the dead was undead.
	# Paradox: undead dying means corruption might clear slightly — but if they
	# were killed by the player it's actually a good sign. We leave this to the
	# caller; this helper just applies a fixed bump for undead spreading damage.
	pass  # intentionally passive — callers use add_corruption / reduce_corruption

func add_corruption(amount: float) -> void:
	var prev := corruption_level
	corruption_level = clampf(corruption_level + amount, 0.0, 1.0)
	if abs(corruption_level - prev) > 0.001:
		emit_signal("corruption_changed", corruption_level)
	_check_season()

func reduce_corruption(amount: float) -> void:
	add_corruption(-amount)

func on_player_helped_crystal_order() -> void:
	reduce_corruption(CORRUPTION_HELP_REDUCTION)

# ==========================================================================
# Season
# ==========================================================================
func _check_season() -> void:
	var new_season: String
	if corruption_level >= 0.85:
		new_season = "apocalypse"
	elif corruption_level >= 0.55 or evolution_stage >= 3:
		new_season = "war"
	elif corruption_level >= 0.25 or evolution_stage >= 2:
		new_season = "unrest"
	else:
		new_season = "calm"

	if new_season != season:
		season = new_season
		emit_signal("season_changed", season)

func get_enemy_density_multiplier() -> float:
	# EnemyDirector reads this to scale MAX_DC_ENEMIES ceiling.
	match season:
		"calm":       return 0.75
		"unrest":     return 1.00
		"war":        return 1.35
		"apocalypse": return 1.70
	return 1.00

func get_corruption_intensity_bonus() -> float:
	# Added to EnemyDirector intensity each second (passive pressure).
	return corruption_level * 0.018

# ==========================================================================
# Zone corruption (visual + mechanical)
# ==========================================================================
func corrupt_zone(zone_id: String) -> void:
	# Called by FactionZone when undead capture a zone.
	# Applies a fixed chunk of corruption and logs to GameBrain.
	add_corruption(0.04)
	if is_instance_valid(GameBrain):
		GameBrain.set_flag("corrupted_" + zone_id)

func cleanse_zone(zone_id: String) -> void:
	reduce_corruption(0.025)
	if is_instance_valid(GameBrain):
		GameBrain.set_flag("cleansed_" + zone_id)

# ==========================================================================
# Save / load
# ==========================================================================
func get_save_data() -> Dictionary:
	return {
		"day":              day,
		"time_of_day":      time_of_day,
		"season":           season,
		"corruption_level": corruption_level,
		"evolution_stage":  evolution_stage,
	}

func load_save_data(data: Dictionary) -> void:
	day              = int(data.get("day", 1))
	time_of_day      = float(data.get("time_of_day", 7.0))
	season           = str(data.get("season", "calm"))
	corruption_level = float(data.get("corruption_level", 0.0))
	evolution_stage  = int(data.get("evolution_stage", 1))
	emit_signal("corruption_changed", corruption_level)
	emit_signal("season_changed", season)
	emit_signal("stage_changed", evolution_stage)
