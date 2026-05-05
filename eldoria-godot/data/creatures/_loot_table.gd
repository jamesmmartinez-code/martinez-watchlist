extends Resource
class_name LootTable

# Realm of Eldoria — drop-table resource consumed by Enemy.gd on death.
# Authority for loot composition is the Bestiary Designer agent; the Items.gd
# DROP_TABLE constant remains the legacy live-game source of truth, with this
# resource as the canonical authoring surface that future runs can migrate
# Enemy.gd to read directly.
#
# 🚫 ABSOLUTE: weights MUST sum to 1.0 (±0.001 rounding tolerance).  The
# loader asserts this on import — a malformed table is a build break, not a
# silent miss.
#
# Each entry: { id: StringName, weight: float, qty_min: int, qty_max: int }

@export var creature_id: StringName = &""
@export var entries: Array[Dictionary] = []

# Validation hint for the loader (and any agent pre-flighting changes).
func sum_weights() -> float:
	var s: float = 0.0
	for e in entries:
		s += float(e.get("weight", 0.0))
	return s

func is_balanced() -> bool:
	return absf(sum_weights() - 1.0) <= 0.001
