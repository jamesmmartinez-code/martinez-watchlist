# Integration Gaps Report

generated_at: 2026-05-06T15:39Z
generator: integrator (auto)

## Summary

Cross-agent gap audit run after merging `auto/art` (1 commit) into main.
Canon QA gate status: **PASS_WITH_DEBT** (cycle 2, 2026-05-06). S2/S3 issues from Canon QA are tracked separately in `_blocking_status.md`; this file surfaces only the additional integrator-detected gaps.

## [GAP: orphan asset]

`.glb` files present under `assets/` with no spawn / preload / reference in `scripts/**.gd` or `scenes/**.tscn`:

- `eldoria-godot/assets/models/props/treasure_chest.glb` — no `treasure_chest` reference in `Chest.gd`, `World.gd`, `WorldBuilder.gd`, or any `.tscn`. Owner: @builder. Likely fix: `Chest.gd` should preload this model or `WorldBuilder.gd` should spawn it for chest placements.

## [GAP: orphan quest]

`data/quests/*.tres` with no NPC dialogue mention:

- `eldoria-godot/data/quests/crystal_caves/shards_for_mara.tres` — quest resource exists but not referenced in any of the 7 NPC dialogue JSONs (elder_maeve, herbalist_lyra, innkeeper_bram, mara_merchant, smith_edda, stablemaster_roan, trainer_hala) nor in any `.gd` script. Owner: @quest-writer. Likely fix: add quest hook to `mara_merchant.json` (`crystal_caves` arc) or wire into `DialogueDB.gd` quest table.

## [GAP: orphan animation]

No `AnimationLibrary` `.tres` files exist under `assets/animations/**` yet. Canon QA already tracks this as **CQ-S2-07** (435 source FBX, 0 `.tres` shipped — first batch not yet built). Not double-logging.

## [GAP: orphan material]

`StandardMaterial3D` `.tres` under `assets/materials/arch/` and `assets/materials/tidesong/` with no `.tscn` consumer:

- `assets/materials/arch/` (17 files): `bronze_metal`, `building_door`, `chimney_smoke`, `courtyard_floor`, `curtain_wall_stone`, `gate_tower_main`, `gold_trim`, `hot_forge_metal`, `house_foundation`, `iron_metal`, `mossy_brick_wall`, `overgrown_brick`, `roof_moss_tiles`, `temple_floor`, `whitewashed_plaster`, `wood_beam`, `wood_flooring`. Owner: @architect. Awaiting `.tscn` curtain-wall / gate-tower / hut prefabs that consume these materials. Canon QA Check 8 confirms no curtain-wall / gate-tower in main scene tree yet (N/A) — these materials are pre-staged for upcoming arch work.
- `assets/materials/tidesong/` (8 files): `barnacle_rock`, `driftwood`, `fine_sand_beach`, `island_cliff`, `mossy_island_cliff`, `ocean_spray_planks`, `sand_pebble_beach`, `seaweed`. Owner: @environment. Tidesong realm not yet scaffolded in scenes; materials staged for future biome.

These are **pre-staged**, not stale — both batches map to scoped future work. Not promoted to S1.

## Cycle metadata

- Branches merged this cycle: `auto/art` (1 commit, sha 84bed6bcd9)
- Branches skipped this cycle (manual review): `auto/scale` (diverged 1 ahead / 113 behind, GitHub merges API returned "Merge conflict") `[INTEGRATOR-MANUAL]`
- Branches reset to main this cycle: `auto/art`, `auto/builder`, `auto/polisher`, `auto/character`, `auto/lore`, `auto/qa`, `auto/scale-floorfix`
- Branches NOT reset (held for owner): `auto/scale` (preserves the 1 conflicting commit so a worker / engineer can rebase or re-author)
