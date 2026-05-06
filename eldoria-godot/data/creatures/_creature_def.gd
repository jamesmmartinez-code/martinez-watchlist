extends Resource
class_name CreatureDef

# Realm of Eldoria — canonical CREATURE STAT BLOCK, owned by the Bestiary
# Designer agent.  Consumed by the Builder agent to wire BT nodes from
# `behavior_tags`, by Enemy.gd at spawn (preferred over @export defaults when
# present), and by the spawn-table loader to choose where this creature can
# appear.  See SYSTEM_REGISTRY.md "Creature Definition Schema."
#
# 🚫 ABSOLUTE: behavior_tags are STRINGS — the Builder implements behavior
# trees from these tags.  Do NOT inline BT logic here.

# ─── Identity ────────────────────────────────────────────────────────────────
@export var id: StringName = &""           # canonical id, must match Items.gd DROP_TABLE key
@export var display_name: String = ""      # in-game label
@export var family: StringName = &""        # "undead" | "elemental" | "beast" | "humanoid" | ...
@export var tier: int = 1                  # 1=trash, 2=elite, 3=mini-boss
@export var level: int = 1                 # nominal player level band

# ─── Combat stats ────────────────────────────────────────────────────────────
@export var hp: int = 30
@export var armor: float = 0.15            # flat damage-reduction multiplier (matches SYSTEM_REGISTRY)
@export var dmg_min: int = 4
@export var dmg_max: int = 8
@export var attack_speed: float = 1.0      # swings/sec target — readable by Builder
@export var attack_cooldown: float = 1.45  # seconds between swings — Enemy.gd reads this
@export var move_speed: float = 2.6
@export var chase_speed: float = 4.6
@export var aggro_range: float = 8.0
@export var attack_range: float = 1.6

# ─── AI scaffolding (Builder consumes) ───────────────────────────────────────
# Keep these as STRINGS only; no BT node code lives here.
@export var behavior_tags: PackedStringArray = []
# Telegraphed attacks. Each tell = { vfx_id, audio_id, wind_up_ms (>= 700 at first encounter) }
@export var tells: Array[Dictionary] = []

# ─── Damage typing (coordinate with item-designer before adding new types) ──
@export var resistances: Dictionary = {}   # { "physical": 0.0..1.0 }
@export var weaknesses: Dictionary = {}    # { "fire": 0.0..1.0 } — multiplier above 1.0

# ─── Reward + loot ───────────────────────────────────────────────────────────
@export var xp_value: int = 24
@export var gold_min: int = 1
@export var gold_max: int = 4
@export var loot_table_id: StringName = &""  # filename (sans .tres) under _loot/

# ─── Asset references (Bestiary FILES needs, Builder/Artist resolve) ────────
@export var mesh_path: String = ""           # path to GLB; agent files NEEDS:mesh:<spec> if missing
@export var nominal_height_m: float = 1.40   # SIZE_STANDARDS.md band

# ─── Region eligibility (spawn-table cross-check) ────────────────────────────
@export var regions: PackedStringArray = []  # ids that may roll this creature
