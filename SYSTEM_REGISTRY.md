# System Registry — Realm of Eldoria

Canonical schemas for everything the engine manipulates. If a new system needs
to look up "what verbs exist?" or "what fields does an item have?", this is
the single answer. Update this whenever a schema changes.

## Verbs (player actions)

| Verb       | Input             | Source script   | Notes                                |
|------------|-------------------|-----------------|--------------------------------------|
| move       | WASD / Arrows     | Player.gd       | walk_speed=5.5, run_speed=9.0        |
| jump       | Space             | Player.gd       | velocity=5.5                         |
| interact   | E                 | Player.gd / NPC | range-based, dialogue / loot         |
| attack     | Left-click        | Player.gd       | 110° arc, 2.6m range                 |
| quaff      | Inventory click   | Inventory.gd    | consumables                          |
| equip      | Inventory click   | Inventory.gd    | weapon / armor / trinket             |
| mount      | M                 | Player.gd       | Horse / mount swap                   |
| loot       | Walk-over / E     | Chest.gd / drop | weighted DROP_TABLE rolls            |

## Stat Schema (Player)

| Field            | Type   | Default | Notes                            |
|------------------|--------|---------|----------------------------------|
| hp / max_hp      | int    | 120/120 | death triggers respawn at well   |
| mp / max_mp      | int    | 30/30   | not yet consumed                 |
| xp               | int    | 0       | level-up curve in Player._gain_xp|
| level            | int    | 1       | scales attack_damage_base        |
| gold             | int    | 50      | quest + loot rewards             |
| crit_chance      | float  | 0.12    | weapon crit_bonus stacks         |
| crit_multiplier  | float  | 2.0     | flat                             |
| attack_damage_base | int  | 14      | + level scaling                  |

## Combat Formulas

```
roll_damage = attack_damage_base + level_bonus + weapon.damage + variance
if rng < crit_chance + weapon.crit_bonus: roll_damage *= crit_multiplier
incoming = enemy.damage * (1.0 - armor_reduction)   # currently flat 0.15
```

## Item Schema

Common fields (Items.gd):
- `name: String` — display
- `type: String` — `weapon | armor | trinket | consumable | material`
- `slot: String` — `weapon | armor | trinket | ""`
- `rarity: String` — `common | uncommon | rare | epic | legendary`
- `icon: String` — emoji glyph
- `color: Color`
- `value: int` — gold sell price

Type-specific:
- weapon: `damage: int`, `crit_bonus: float?`
- armor:  `armor: int`, `hp_bonus: int?`
- trinket: `hp_bonus?`, `mp_bonus?`, `crit_bonus?`
- consumable: `heal: int?`, `mana: int?`, `stack: bool`
- material: `stack: bool` (used by fetch quests)

Rarity colors → standard MMO palette (white/green/blue/purple/orange).

## Drop Tables

Defined in `Items.DROP_TABLE`. Entries: `{id, weight, qty:[min,max]}`.
Currently keyed: `goblin`, `wolf`, `goblin_warlord`, `skeleton`,
`crystal_elemental`, `bandit` (entries vary). New enemy kinds MUST add a drop
table entry; do not let an enemy ship without loot.

## Status Effects

NONE shipped yet. Reserved schema for downstream runs:
```
{ id: String, duration_s: float, tick_s: float, on_tick: Callable, color: Color }
```
First implementation should add: `bleed`, `slow`, `burn`, `poison`.

## Quest Reward Schema

A quest may grant any combination of:
- `xp_reward: int`
- `gold_reward: int`
- `reward_item: String, reward_item_qty: int`
- `consequence: String` — *reserved*, see QUEST_GRAMMAR.md (faction shifts,
  NPC memory flags, world flags). Not yet wired.

## NPC Schema

Defined in `WorldBuilder.NPCS`. Fields:
- `name: String`, `role: String`, `pos: Vector3`, `tint: Color`,
  `line: String` (default dialogue)
- *Reserved for reactive dialogue*: `lines: Dictionary` keyed by world flag
  (e.g. `"first_goblin_killed": "..."`). Not yet wired.

## Time Schema

`World.time_of_day: float` — 0.0..1.0 (0.0 dawn, 0.25 noon, 0.5 dusk, 0.75
midnight). Full cycle = 360s. NPC schedules should consume this.

## Faction Schema

✅ **Shipped 2026-05-04 (run 2).** Live runtime state on World:
```gdscript
var factions: Dictionary = {
  "briarwood":           {"disposition": "friendly", "pressure": 0.0},
  "whisperwood_goblins": {"disposition": "hostile",  "pressure": 1.0},
  "dire_wolves":         {"disposition": "hostile",  "pressure": 0.5},
  "crystal_caves":       {"disposition": "hostile",  "pressure": 0.0},
}
```
- **Pressure** is a float clamped to [0.0, 1.0]. Higher = more aggressive,
  more spawns, bolder patrols (consumers TBD).
- **Disposition** is a String label. Today it's documentation; later may
  drive NPC reactions to fellow factions.

Read: `World.faction_pressure(id: String) -> float`.
Mutate: ONLY via `World.apply_consequence({"faction": id, "pressure_delta": float})`.
A future run should add per-frame decay toward a faction-specific equilibrium.

## Consequence Schema (Quest → World mutation)

✅ **Shipped 2026-05-04 (run 2).** Single entry point for quest completions to
mutate world state. Lives at `World.apply_consequence(consequence: Dictionary)`.
Supported keys (all optional; empty dict is a no-op):

| Key                | Type      | Effect                                             |
|--------------------|-----------|----------------------------------------------------|
| `faction`          | String    | id of faction in `World.factions` (paired w/ `pressure_delta`) |
| `pressure_delta`   | float     | added to `factions[id].pressure`, clamped [0,1]    |
| `world_flag`       | String    | sets `World.world_flags[name] = world_flag_value`  |
| `world_flag_value` | Variant   | optional; defaults to `true`                       |
| `npc_flag`         | [Str,Str] | `[npc_name, flag_name]`; appended to `npc_flags[npc]` (deduped) |
| `toast`            | String    | optional UI message; calls `_show_toast(toast)`    |

Read accessors:
- `World.faction_pressure(id) -> float`
- `World.has_world_flag(name) -> bool`
- `World.npc_has_flag(npc_name, flag_name) -> bool`

Authoring rule: dialogue + AI READ flags; only `apply_consequence` WRITES.
This guarantees one place to audit world-state churn.

## World Flag Conventions

`World.world_flags: Dictionary` is keyed by `snake_case` strings naming a
*present-tense fact*: `whisperwood_safer`, `lyra_potion_brew`,
`mara_bounty_paid`. Never imperative ("save_the_village") and never tied to
quest IDs ("quest_1_done") — flags outlive specific quests.
