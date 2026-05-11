extends Resource
class_name BossKit

@export var id: StringName = &""
@export var display_name: String = ""
@export var family: StringName = &""
@export var tier: int = 3
@export var level: int = 8

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

@export var behavior_tags: PackedStringArray = []
# JSON strings for complex nested data (Array[Dictionary] not supported in .tres)
@export_multiline var tells_json: String = "[]"
@export_multiline var phases_json: String = "[]"
@export_multiline var resistances_json: String = "{}"
@export_multiline var weaknesses_json: String = "{}"
@export_multiline var arena_requirements_json: String = "{}"

@export var xp_value: int = 750
@export var gold_min: int = 90
@export var gold_max: int = 160
@export var loot_table_id: StringName = &""

@export var mesh_path: String = ""
@export var nominal_height_m: float = 2.50
@export var regions: PackedStringArray = []

func get_tells() -> Array:
	return JSON.parse_string(tells_json) if tells_json != "[]" else []
func get_phases() -> Array:
	return JSON.parse_string(phases_json) if phases_json != "[]" else []
func get_resistances() -> Dictionary:
	return JSON.parse_string(resistances_json) if resistances_json != "{}" else {}
func get_weaknesses() -> Dictionary:
	return JSON.parse_string(weaknesses_json) if weaknesses_json != "{}" else {}
