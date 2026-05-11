extends Node
# Realm of Eldoria — FactionSystem (autoload singleton)
#
# Central faction registry, war engine, and reputation tracker.
# String IDs (not enum) so new factions can be added in data without
# recompiling.  Every enemy in the "enemies" group reads its faction_id
# from this system at runtime.
#
# Registered as autoload "FactionSystem" in project.godot [autoload].
#
# ── Faction IDs ───────────────────────────────────────────────────────────
# "player"         — the player's faction
# "watchers"       — ranged sentinels, order-aligned
# "drifters"       — shambling undead-adjacent, chaotic
# "bandits"        — organised thieves, hostile to most
# "goblins"        — small raiders, ally with bandits
# "undead"         — skeletal remnants, hostile to all life
# "crystal_order"  — ancient guardians, neutral until provoked
# "wolves"         — territorial beasts, no formal allegiance
#
# ── Relations ─────────────────────────────────────────────────────────────
# -1 = hostile (will attack on sight)
#  0 = neutral  (ignore unless provoked)
# +1 = ally     (will NOT attack; may assist)
# Relations can shift at runtime via reputation changes.

# ==========================================================================
# Static relation table (never mutated — runtime shifts go to _rep_offsets)
# ==========================================================================
const BASE_RELATIONS: Dictionary = {
	"player":       {"watchers":-1,"drifters":0, "bandits":-1,"goblins":-1,"undead":-1,"crystal_order":0, "wolves":0 },
	"watchers":     {"player":-1, "drifters":-1,"bandits":0, "goblins":-1,"undead":-1,"crystal_order":0, "wolves":0 },
	"drifters":     {"player":0,  "watchers":-1,"bandits":-1,"goblins":-1,"undead":0, "crystal_order":0, "wolves":-1},
	"bandits":      {"player":-1, "watchers":0, "drifters":-1,"goblins":1,"undead":-1,"crystal_order":-1,"wolves":0 },
	"goblins":      {"player":-1, "watchers":-1,"drifters":-1,"bandits":1,"undead":-1,"crystal_order":-1,"wolves":0 },
	"undead":       {"player":-1, "watchers":-1,"drifters":0,"bandits":-1,"goblins":-1,"crystal_order":-1,"wolves":-1},
	"crystal_order":{"player":0,  "watchers":0, "drifters":0,"bandits":-1,"goblins":-1,"undead":-1,       "wolves":0 },
	"wolves":       {"player":0,  "watchers":0, "drifters":-1,"bandits":0,"goblins":0,"undead":-1,        "crystal_order":0},
}

# Maps enemy_kind → faction_id (separate from the pressure-cooldown KIND_TO_FACTION in Enemy.gd)
const KIND_TO_FACTION_ID: Dictionary = {
	"drifter":          "drifters",
	"watcher":          "watchers",
	"reactive_scout":   "watchers",
	"goblin":           "goblins",
	"goblin_scout":     "goblins",
	"bandit":           "bandits",
	"bandit_captain":   "bandits",
	"skeleton":         "undead",
	"wolf":             "wolves",
	"crystal_elemental":"crystal_order",
	"crystal_guardian": "crystal_order",
}

# ==========================================================================
# Runtime state
# ==========================================================================

# Faction strength 0.0–1.0.  Falls when members die; recovers slowly.
var faction_strength: Dictionary = {
	"watchers":     1.0, "drifters":     1.0, "bandits":  1.0,
	"goblins":      1.0, "undead":       1.0, "crystal_order": 1.0, "wolves": 0.8,
}

# Player reputation with each faction (-100 hostile → +100 allied).
# High positive rep FLIPS the base relation to +1 (ally).
# Deep negative rep can't get worse than -1, but triggers "hunt" behaviors.
var reputation: Dictionary = {
	"watchers":     0, "drifters":     0, "bandits":   0,
	"goblins":      0, "undead":       0, "crystal_order": 0, "wolves": 0,
}

# Zone ownership: zone_id → faction_id
var zone_control: Dictionary = {}

# Registered FactionZone nodes
var _zones: Array = []

# Strength recovery timer
var _recovery_timer: float = 0.0
const STRENGTH_RECOVERY_INTERVAL: float = 30.0
const STRENGTH_RECOVERY_RATE:     float = 0.008

# ==========================================================================
# Signals
# ==========================================================================
signal zone_captured(zone_id: String, new_faction: String, old_faction: String)
signal faction_weakened(faction_id: String, new_strength: float)
signal reputation_changed(faction_id: String, new_value: int)
signal war_event(event_type: String, faction: String, near_pos: Vector3)

# ==========================================================================
# Lifecycle
# ==========================================================================
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_recovery_timer += delta
	if _recovery_timer >= STRENGTH_RECOVERY_INTERVAL:
		_recovery_timer = 0.0
		_recover_strengths()

# ==========================================================================
# Relation API
# ==========================================================================
func get_relation(faction_a: String, faction_b: String) -> int:
	# Returns the runtime-adjusted relation between two factions.
	# Reputation threshold: ≥50 rep converts hostile→neutral or neutral→ally.
	# Player faction uses the reputation table directly.
	if faction_a == faction_b:
		return 1   # same faction is always ally
	if faction_a == "player" or faction_b == "player":
		var other := faction_b if faction_a == "player" else faction_a
		var rep: int = int(reputation.get(other, 0))
		if rep >= 50:
			return 1   # allied
		if rep <= -50:
			return -1  # hunting player
		return int(BASE_RELATIONS.get("player", {}).get(other, 0))
	# Non-player relations: use static table (faction wars don't change mid-game)
	return int(BASE_RELATIONS.get(faction_a, {}).get(faction_b, 0))

func is_hostile(faction_a: String, faction_b: String) -> bool:
	return get_relation(faction_a, faction_b) < 0

func get_faction_for_kind(kind: String) -> String:
	return KIND_TO_FACTION_ID.get(kind, "")

# ==========================================================================
# Reputation
# ==========================================================================
func change_reputation(faction_id: String, delta: int) -> void:
	if not reputation.has(faction_id):
		return
	reputation[faction_id] = clampi(int(reputation[faction_id]) + delta, -100, 100)
	emit_signal("reputation_changed", faction_id, reputation[faction_id])
	# Mirror: helping one faction angers its enemies
	var base: Dictionary = BASE_RELATIONS.get("player", {})
	for other: String in reputation.keys():
		if other == faction_id: continue
		var rel: int = int(base.get(other, 0))
		if rel < 0:
			# Factions hostile to each other: helping one slightly angers the other
			var bleed := int(float(delta) * 0.25)
			if bleed != 0:
				reputation[other] = clampi(int(reputation[other]) - bleed, -100, 100)

# ==========================================================================
# Faction strength
# ==========================================================================
func on_faction_enemy_died(faction_id: String) -> void:
	# Called by Enemy._die() via EnemyDirector callback path.
	if not faction_strength.has(faction_id):
		return
	faction_strength[faction_id] = maxf(0.0, float(faction_strength[faction_id]) - 0.04)
	emit_signal("faction_weakened", faction_id, faction_strength[faction_id])

func weaken_faction(faction_id: String, amount: float = 0.15) -> void:
	if not faction_strength.has(faction_id):
		return
	faction_strength[faction_id] = maxf(0.0, float(faction_strength[faction_id]) - amount)
	emit_signal("faction_weakened", faction_id, faction_strength[faction_id])

func _recover_strengths() -> void:
	for f: String in faction_strength.keys():
		faction_strength[f] = minf(1.0, float(faction_strength[f]) + STRENGTH_RECOVERY_RATE)

# ==========================================================================
# Zone control
# ==========================================================================
func register_zone(zone: Node) -> void:
	if not _zones.has(zone):
		_zones.append(zone)

func unregister_zone(zone: Node) -> void:
	_zones.erase(zone)

func on_zone_captured(zone_id: String, new_faction: String, old_faction: String) -> void:
	zone_control[zone_id] = new_faction
	emit_signal("zone_captured", zone_id, new_faction, old_faction)
	_trigger_war_event(zone_id, new_faction, old_faction)

func get_dominant_faction() -> String:
	# Returns the faction controlling the most zones, or "" if tied/empty.
	var counts: Dictionary = {}
	for faction: String in zone_control.values():
		counts[faction] = int(counts.get(faction, 0)) + 1
	var best := ""
	var best_n := 0
	for f: String in counts:
		if int(counts[f]) > best_n:
			best_n = int(counts[f])
			best = f
	return best

# ==========================================================================
# War events
# ==========================================================================
func _trigger_war_event(zone_id: String, capturing_faction: String, lost_faction: String) -> void:
	# Find the zone node so we have a world position to spawn near.
	var zone_pos := Vector3.ZERO
	for z in _zones:
		if is_instance_valid(z) and z.zone_id == zone_id:
			zone_pos = z.global_position
			break

	if randf() < 0.55:
		_spawn_reinforcements(capturing_faction, zone_pos)
		emit_signal("war_event", "reinforcements", capturing_faction, zone_pos)
	else:
		_spawn_counter_attack(capturing_faction, lost_faction, zone_pos)
		emit_signal("war_event", "counter_attack", lost_faction, zone_pos)

func _spawn_reinforcements(faction_id: String, near_pos: Vector3) -> void:
	var kind := _pick_kind_for_faction(faction_id)
	for i: int in 3:
		_spawn_faction_enemy(kind, near_pos + Vector3(randf_range(-6,6), 0, randf_range(-6,6)))

func _spawn_counter_attack(attacking_faction: String, defending_faction: String, near_pos: Vector3) -> void:
	# Counter-attacker pushes back with slightly more numbers.
	var counter := _pick_kind_for_faction(attacking_faction)
	for i: int in 4:
		_spawn_faction_enemy(counter, near_pos + Vector3(randf_range(-10,10), 0, randf_range(-10,10)))

func _pick_kind_for_faction(faction_id: String) -> String:
	match faction_id:
		"watchers":    return "watcher" if randf() < 0.6 else "reactive_scout"
		"drifters":    return "drifter"
		"bandits":     return "bandit"
		"goblins":     return "goblin_scout" if randf() < 0.5 else "goblin"
		"undead":      return "skeleton"
		"crystal_order": return "crystal_elemental"
		_:             return "drifter"

const ENEMY_SCRIPT = preload("res://scripts/Enemy.gd")

func _spawn_faction_enemy(kind: String, pos: Vector3) -> void:
	var scene := get_tree().current_scene
	if not scene: return
	var e := CharacterBody3D.new()
	e.set_script(ENEMY_SCRIPT)
	e.set("enemy_kind", kind)
	e.set("tint", _faction_tint(KIND_TO_FACTION_ID.get(kind, "")))
	scene.add_child(e)
	e.global_position = pos
	# Notify EnemyDirector so it can track the count
	if is_instance_valid(EnemyDirector):
		EnemyDirector._dc_count += 1
		if e.has_signal("died"):
			e.died.connect(EnemyDirector._on_enemy_died)

func _faction_tint(faction_id: String) -> Color:
	match faction_id:
		"watchers":      return Color(0.38, 0.60, 0.92)
		"drifters":      return Color(0.62, 0.52, 0.38)
		"bandits":       return Color(0.75, 0.30, 0.20)
		"goblins":       return Color(0.20, 0.78, 0.25)
		"undead":        return Color(0.70, 0.75, 0.65)
		"crystal_order": return Color(0.30, 0.70, 0.95)
		_:               return Color(0.45, 0.85, 0.30)

# ==========================================================================
# Player impact helpers (called from game events)
# ==========================================================================
func on_player_killed_faction_enemy(faction_id: String) -> void:
	on_faction_enemy_died(faction_id)
	# Killing enemies of a hostile faction slightly improves rep with allies
	var base: Dictionary = BASE_RELATIONS.get("player", {})
	for other: String in reputation.keys():
		if other == faction_id: continue
		if int(base.get(other, 0)) < 0 and int(BASE_RELATIONS.get(other, {}).get(faction_id, 0)) < 0:
			# Player killed an enemy of a faction that hates the killed faction
			change_reputation(other, 1)

func on_player_helped_faction(faction_id: String, amount: int = 20) -> void:
	change_reputation(faction_id, amount)
	# Notify GameBrain for world flags
	if is_instance_valid(GameBrain):
		GameBrain.set_flag("helped_" + faction_id)

# ==========================================================================
# Save / load
# ==========================================================================
func get_save_data() -> Dictionary:
	return {
		"reputation":      reputation.duplicate(),
		"faction_strength":faction_strength.duplicate(),
		"zone_control":    zone_control.duplicate(),
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("reputation"):
		for k: String in data["reputation"]:
			if reputation.has(k):
				reputation[k] = int(data["reputation"][k])
	if data.has("faction_strength"):
		for k: String in data["faction_strength"]:
			if faction_strength.has(k):
				faction_strength[k] = float(data["faction_strength"][k])
	if data.has("zone_control"):
		zone_control = data["zone_control"].duplicate()
