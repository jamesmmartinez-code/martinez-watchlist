# Forge Recipes — Edda's Anvil

## Tier-1 (5 recipes; cap is 8)
Bootstrap pass — adds first ingot economy and lore-gated re-work of the rusty starter sword.

| Recipe                  | Output         | Unlock          |
|-------------------------|----------------|-----------------|
| forge_iron_ingot        | iron_ingot ×1  | auto            |
| forge_rusty_to_iron     | iron_sword ×1  | npc_taught      |
| forge_iron_sword        | iron_sword ×1  | auto            |
| forge_chainmail_mend    | chainmail ×1   | quest_complete  |
| forge_iron_buckle       | iron_buckle ×4 | auto            |

## Tier-2 (4 recipes; cap is 8) — Whisperwood unlock
Tier-up rule: every tier-2 recipe consumes ≥1 Whisperwood-region material
(wolf_fang, wolf_pelt, leather_strip from cured wolf_pelt, or warband_haft).
None is strictly better than tier-3 vendor steel_blade / chest steel_plate.

| Recipe                    | Output             | Unlock          | New-region input |
|---------------------------|--------------------|-----------------|------------------|
| forge_fanged_dagger       | fang_dagger ×1     | npc_taught      | wolf_fang        |
| forge_pelt_brigandine     | pelt_brigandine ×1 | quest_complete  | leather_strip    |
| forge_warband_axe         | warband_axe ×1     | recipe_book     | warband_haft     |
| forge_studded_buckler     | studded_buckler ×1 | auto            | wolf_pelt        |

## Tier-3 plan (next pass) — Crystal Caves unlock
- forge_steel_blade (output exists: steel_blade) — uses crystal_shard
- forge_steel_plate (output exists: steel_plate) — uses crystal_shard + cave_quench_water
- forge_haethe_listener (Edda's apprentice scene; uses crystal_shard ear-stamp)

## Items still NEEDED from item-designer
### Tier-1 carryover
- iron_ore, iron_ingot, charcoal, leather_strip, iron_buckle

### Tier-2 (this pass)
- fang_dagger (output)        — tier-2 weapon_blade, wolf-fang pommel
- pelt_brigandine (output)    — tier-2 armor_metal, iron-plated leather coat
- warband_axe (output)        — tier-2 weapon_axe, "honest swing, hooked beard"
- warband_haft (input)        — splintered ash-haft, Whisperwood battlefield drop
- studded_buckler (output)    — tier-2 armor_metal, small forearm shield with iron studs

### Tier-3 (future)
- cave_quench_water — Crystal Caves under-stream water for tier-3 quench
