extends Resource
class_name NemesisData
# Realm of Eldoria — NemesisData (Resource)
#
# Persistent memory for a single nemesis enemy.
# Created by NemesisSystem.register_enemy() and stored in
# NemesisSystem.nemeses[id].  Serialised into save data.
#
# ── Trait catalogue ────────────────────────────────────────────────────────
# Each trait is a plain String applied in NemesisSystem.apply_traits().
# Traits stack — a level-3 nemesis can have three independent modifiers.
#
#   "fast"           — move_speed/chase_speed × 1.25
#   "armored"        — max_hp × 1.40, damage × 0.85
#   "rage_mode"      — max_hp × 1.30, damage × 1.30; ignores retreat
#   "dash_counter"   — aggro_range × 1.30; reads "counter_dash" in its blackboard
#   "poisonous"      — attack_cooldown × 0.85 (poisons faster)
#   "regenerating"   — hp regen tag (Enemy._physics_process handles it)
#   "fire_resistant" — (reserved for when elemental damage ships)

# ==========================================================================
# Identity
# ==========================================================================
var nemesis_id:   String = ""
var nemesis_name: String = "Unknown"
var level:        int    = 1

# Faction allegiance inherited from the enemy at registration time.
var faction_id:   String = ""
# The enemy_kind so we can respawn the same archetype.
var enemy_kind:   String = "drifter"

# ==========================================================================
# Trait + history
# ==========================================================================
var traits:  Array = []   # Array[String] — accumulated over lifetime
var history: Array = []   # Array[String] — human-readable events (capped at 30)

# ==========================================================================
# Encounter state
# ==========================================================================
var killed_player:   bool = false
var escaped:         bool = false
var times_defeated:  int  = 0   # increments every time we lose to the player
var spawned_count:   int  = 0   # how many times this nemesis has respawned

# ==========================================================================
# Helpers
# ==========================================================================
func add_history(entry: String) -> void:
	history.append(entry)
	if history.size() > 30:
		history.pop_front()

func add_trait(t: String) -> void:
	if not traits.has(t):
		traits.append(t)

func has_trait(t: String) -> bool:
	return traits.has(t)

# ==========================================================================
# Save / load
# ==========================================================================
func to_dict() -> Dictionary:
	return {
		"nemesis_id":    nemesis_id,
		"nemesis_name":  nemesis_name,
		"level":         level,
		"faction_id":    faction_id,
		"enemy_kind":    enemy_kind,
		"traits":        traits.duplicate(),
		"history":       history.duplicate(),
		"killed_player": killed_player,
		"escaped":       escaped,
		"times_defeated": times_defeated,
		"spawned_count": spawned_count,
	}

func from_dict(d: Dictionary) -> void:
	nemesis_id    = str(d.get("nemesis_id", ""))
	nemesis_name  = str(d.get("nemesis_name", "Unknown"))
	level         = int(d.get("level", 1))
	faction_id    = str(d.get("faction_id", ""))
	enemy_kind    = str(d.get("enemy_kind", "drifter"))
	traits        = Array(d.get("traits", []))
	history       = Array(d.get("history", []))
	killed_player = bool(d.get("killed_player", false))
	escaped       = bool(d.get("escaped", false))
	times_defeated = int(d.get("times_defeated", 0))
	spawned_count = int(d.get("spawned_count", 0))
