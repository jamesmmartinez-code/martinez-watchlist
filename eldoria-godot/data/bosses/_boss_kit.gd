extends Resource
class_name BossKit

# Realm of Eldoria — canonical BOSS KIT, owned by the Bestiary Designer agent.
# A boss kit composes a base CreatureDef-like stat block with phases and
# telegraphed mechanics.  The Builder agent consumes `phases[].behavior_tags`
# at HP-threshold crossings; mechanics are wired from `mechanics[]` strings,
# not BT code (same rule as creatures — tags only).
#
# 🚫 ABSOLUTE: every phase must include at least one telegraphed mechanic.
# Tell `wind_up_ms` ≥ 700 (kid-readable), ≥ 1000 on first encounter.

# ─── Identity ────────────────────────────────────────────────────────────────
@export var id: StringName = &""
@export var display_name: String = ""
@export var family: StringName = &""
@export var tier: int = 3                  # 3 = mini-boss; 4 = realm boss
@export var level: int = 8

# ─── Combat stats (phase-1 baseline; phases may override behavior, not stats) ─
@export var hp: int = 1700
@export var armor: float = 0.25
@export var dmg_min: int = 14
@export var dmg_max: int = 22
@export var attack_speed: float = 0.55
@export var attack_cooldown: float = 1.80
@export var move_speed: float = 1.6
@export var chase_speed: float = 2.4
@export var aggro_range: float = 14.0
@export var attack_range: float = 2.4

# ─── AI scaffolding (Builder consumes; tags only) ────────────────────────────
@export var behavior_tags: PackedStringArray = []
# tells: [{ id, vfx_id, audio_id, wind_up_ms, damage_mult, range_m | radius_m }]
@export var tells: Array[Dictionary] = []

# ─── Phase progression ───────────────────────────────────────────────────────
# Each phase: {
#   id: StringName,
#   hp_threshold: float (0..1, transition at-or-below),
#   behavior_tags: PackedStringArray,
#   mechanics: Array[Dictionary]    # each = telegraphed attack ref or summon
# }
@export var phases: Array[Dictionary] = []

# ─── Damage typing ───────────────────────────────────────────────────────────
@export var resistances: Dictionary = {}
@export var weaknesses: Dictionary = {}

# ─── Reward + loot ───────────────────────────────────────────────────────────
@export var xp_value: int = 600
@export var gold_min: int = 80
@export var gold_max: int = 140
@export var loot_table_id: StringName = &""

# ─── Asset & arena ───────────────────────────────────────────────────────────
@export var mesh_path: String = ""
@export var nominal_height_m: float = 2.50
@export var arena_requirements: Dictionary = {}
# arena_requirements: { region, biome, min_radius_m, ceiling_m, has_pillars,
#                       hazard_floor (bool), notes }

@export var regions: PackedStringArray = []

# ─── Validation helpers ──────────────────────────────────────────────────────
func phase_count() -> int:
	return phases.size()

func validate_phases() -> bool:
	if phases.is_empty():
		return false
	for p in phases:
		var mechs: Array = p.get("mechanics", [])
		if mechs.is_empty():
			return false  # banned: phase with zero telegraphed mechanics
	return true
