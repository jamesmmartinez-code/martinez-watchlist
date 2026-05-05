extends Resource
class_name SpawnTable

# Realm of Eldoria — region-level spawn table. Owns spawn density per
# creature and day/night swap rules.  The Builder agent consumes this when
# wiring WorldBuilder._build_enemies for a region.

@export var region_id: StringName = &""
@export var biome: StringName = &""

# entries: [{ id: StringName, weight: float, count_min: int, count_max: int, time: "any"|"day"|"night" }]
@export var day_entries: Array[Dictionary] = []
@export var night_entries: Array[Dictionary] = []

# Population caps so a single region cannot dominate the global enemy budget.
@export var pop_cap_total: int = 12
@export var pop_cap_per_kind: Dictionary = {}  # { id: int }
