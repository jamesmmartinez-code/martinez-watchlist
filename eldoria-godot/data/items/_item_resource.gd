extends Resource
class_name ItemResource
# Realm of Eldoria — canonical item resource. All .tres item files in
# data/items/<category>/ extend this. Stat budget is enforced by _curves.gd.
# Authored by the item-designer agent; runtime stats also live in
# scripts/Items.gd (legacy const dict). When the two diverge, this Resource
# file wins for design balance, Items.gd wins for live drops until a future
# loader run wires this catalog into the runtime.

@export var id: String = ""
@export var name: String = ""
@export var category: String = ""              # weapon|armor|relic|consumable|material
@export var rarity: String = "common"          # common|uncommon|rare|epic|legendary
@export var tier: int = 1                      # 1..10, drives stat budget
@export var stats: Dictionary = {}             # primary + ≤2 secondaries
@export_multiline var flavor: String = ""      # lore-keeper writes; we leave # NEEDS:flavor if empty
@export var acquired_via: String = "drop"      # drop|quest|craft|vendor|chest
@export var value_gold: int = 0
@export var set_id: String = ""                # optional; matches _sets.tres

# Weapon-only
@export var damage_type: String = ""           # slash|pierce|crush|frost|fire|shadow|arcane
@export var attack_speed: float = 1.0          # attacks per second
@export_range(0.0, 30.0) var range_m: float = 1.4
@export var crit_mult: float = 1.5

# Armor-only
@export var slot: String = ""                  # body|head|legs|feet|shield
@export var armor_class: int = 0
@export var move_penalty: float = 0.0          # negative number = downside (slows player)

# Consumable-only
@export var effect: String = ""                # heal|mana|buff|cure|food
@export var duration: float = 0.0              # seconds; 0 = instant
@export var stack_max: int = 1

# Relic-only (trinkets/amulets/rings/cores)
@export var passive_effect: String = ""        # short prose; the WHAT
@export var attunement_cost: int = 0           # downside: bag-slots or focus cost

func is_within_budget(curve_module) -> bool:
    if curve_module == null:
        return true
    return curve_module.is_within_budget(tier, rarity, stats, _has_downside())

func _has_downside() -> bool:
    return move_penalty < 0.0 or attunement_cost > 0
