extends Resource
class_name ItemSetResource
# Set bonus definition. _sets.tres contains an array of these.

@export var set_id: String = ""
@export var set_name: String = ""
@export_multiline var flavor: String = ""
@export var member_ids: Array[String] = []
# Bonus tiers keyed by piece-count: { 2: { "hp_bonus": 30 }, 3: { ... } }
@export var bonuses_by_pieces: Dictionary = {}
