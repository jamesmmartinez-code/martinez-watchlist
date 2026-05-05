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
  `line: String` (default dialogue, used as last-resort fallback)
- `lines: Array[String]` — 4 mood-bucketed time-of-day variants
  (morning / midday / evening / night).

✅ **Shipped 2026-05-04 (run 3 — integrator + follow-up): Reactive dialogue.**
NPC.gd consults World on each interaction and walks 4 tiers, picking the
first hit:

1. `warm_flag: String` + `warm_lines: Array[String]` (4 buckets).
   Fires when `World.npc_has_flag(npc_name, warm_flag)` returns true.
   Personal warmth: "you helped *me*". Shipped by integrator.
2. `warm_world_flag: String` + `warm_world_lines: Array[String]` (4 buckets).
   Fires when `World.has_world_flag(warm_world_flag)` returns true AND
   tier 1 didn't already match. World warmth: "you helped our cause."
   Shipped by run-3 follow-up. Reads `World.world_flags`, which had no
   other consumer until now.
3. `warm_faction_id: String` + `warm_faction_below: float` +
   `warm_faction_lines: Array[String]` (4 buckets).
   Fires when `World.faction_pressure(warm_faction_id) < warm_faction_below`
   AND neither flag tier already matched. Faction-shape warmth: "the world
   has changed in a measurable way." Shipped by run 4. Reads
   `World.faction_pressure()`, which had no other consumer until now.
4. `lines: Array[String]` (the mood-bucketed default).
5. `line: String` (single fallback).

`_make_npc()` copies these fields onto the NPC node:
- `npc.warmed_flag` ← `data.warm_flag`
- `npc.warmed_dialogue_variants` ← `data.warm_lines`
- `npc.warmed_world_flag` ← `data.warm_world_flag`
- `npc.warmed_world_dialogue_variants` ← `data.warm_world_lines`
- `npc.warmed_faction_id` ← `data.warm_faction_id`
- `npc.warmed_faction_below` ← `data.warm_faction_below` (default 1.0)
- `npc.warmed_faction_dialogue_variants` ← `data.warm_faction_lines`

Authoring rules:
- `warm_flag` MUST match a flag actually written by some quest's
  `consequence` — see WORLD_STATE.md "NPC Memory" table for the live set.
- `warm_world_flag` MUST match a key in `World.world_flags` — see
  WORLD_STATE.md "World Flags (Active)".
- `warm_faction_id` MUST match a key in `World.factions` — see
  WORLD_STATE.md "Faction State". `warm_faction_below` is a strict
  less-than threshold against `pressure` (range [0.0, 1.0]); use 0.9 / 0.7 /
  0.5 / 0.3 for "any reduction" / "noticeably safer" / "halfway tamed" /
  "definitively tamed".
- Warmed arrays SHOULD have exactly 4 entries (one per time bucket); a
  shorter array clamps to its last entry via `min(bucket, size-1)`.

**Authoring traps (run-4 lesson learned):**
- ⚠ Do NOT pair a faction reducer with the same quest that issues the NPC's
  `warm_flag` *if the NPC's faction tier targets that same faction*. The
  warm_flag tier always wins once set, so the faction tier can only fire
  before the warm_flag is earned — i.e. before the only quest that would
  reduce the faction. Result: unreachable dialogue. Fix: target a DIFFERENT
  faction with the faction tier, OR pick a threshold reachable by a
  different quest's reducer. Maeve targets `whisperwood_goblins` because
  `ears_for_mara` (-0.15) reduces it without setting Maeve's flag, so the
  tier is reachable on the "ears-before-cleansing" path.
- ⚠ NPCs with NO `warm_flag` and NO `warm_world_flag` will fall straight
  through tiers 1+2 to the faction tier. This is intentional — Edda, Bram,
  Roan, Hala are pre-wired for the faction tier the moment they get
  `warm_faction_lines`. No structural code change required.

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
