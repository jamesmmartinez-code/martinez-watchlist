extends Resource
class_name CreatureDef

@export var id: StringName = &""
@export var display_name: String = ""
@export var family: StringName = &""
@export var tier: int = 1
@export var level: int = 1

@export var hp: int = 30
@export var armor: float = 0.15
@export var dmg_min: int = 4
@export var dmg_max: int = 8
@export var attack_speed: float = 1.0
@export var attack_cooldown: float = 1.45
@export var move_speed: float = 2.6
@export var chase_speed: float = 4.6
@export var aggro_range: float = 8.0
@export var attack_range: float = 1.6

@export var behavior_tags: PackedStringArray = []
# JSON string — Array of {id, vfx_id, audio_id, wind_up_ms, damage_mult, ...}
@export_multiline var tells_json: String = "[]"

# JSON strings — {type: multiplier}
@export_multiline var resistances_json: String = "{}"
@export_multiline var weaknesses_json: String = "{}"

@export var xp_value: int = 24
@export var gold_min: int = 1
@export var gold_max: int = 4
@export var loot_table_id: StringName = &""

@export var mesh_path: String = ""
@export var nominal_height_m: float = 1.40

@export var regions: PackedStringArray = []

# Convenience accessors
func get_tells() -> Array:
	return JSON.parse_string(tells_json) if tells_json != "[]" else []

func get_resistances() -> Dictionary:
	return JSON.parse_string(resistances_json) if resistances_json != "{}" else {}

func get_weaknesses() -> Dictionary:
	return JSON.parse_string(weaknesses_json) if weaknesses_json != "{}" else {}
