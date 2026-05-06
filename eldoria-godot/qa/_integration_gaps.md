# Eldoria Integration Gaps
generated_at: 2026-05-06T20:48:44Z
by: integrator (auto)
main: 6ba54797d3d1d0b98cde06a94122a21d37977230

## Summary

- orphan assets (`.glb`): 7
- orphan quests (`data/quests/*.tres`): 2 (in crystal_caves, no NPC dialogue references yet)
- orphan animations (AnimationLibrary `.tres`): 0 (no AnimationLibrary .tres present — see CQ-S2-07)
- orphan StandardMaterial3D `.tres`: 26

## [GAP: orphan asset] — `.glb` with no spawn logic in WorldBuilder.gd

GLB files present in `assets/models/` but the basename is not referenced in `scripts/WorldBuilder.gd`. May be wired by a different agent (CharacterSelect.gd, Player.gd, Enemy.gd) — verify owner before removing.

- `eldoria-godot/assets/models/Fox.glb`
- `eldoria-godot/assets/models/Hero.glb`
- `eldoria-godot/assets/models/enemies/goblin_scout.glb`
- `eldoria-godot/assets/models/heroes/alden_pathfinder.glb`
- `eldoria-godot/assets/models/heroes/owen_vanguard.glb`
- `eldoria-godot/assets/models/npcs/warrior.glb`
- `eldoria-godot/assets/models/npcs/worker_girl.glb`

## [GAP: orphan quest] — `data/quests/*.tres` with no NPC dialogue mention

Quest resources whose ID/basename is not mentioned in any dialogue JSON. Likely the dialogue hookup hasn't shipped yet — assign to quest-writer.


## [GAP: orphan material] — `StandardMaterial3D` `.tres` with no MeshInstance reference

Material resources under `assets/materials/{arch,tidesong}/` and one terrain-assets resource. Not referenced in any `.tscn` or `.gd` file (excluding addons/) and not loaded via `res://`. Likely produced ahead of the MeshInstance3D wiring; assign to architect / environment / scale-engineer to apply.

- `eldoria-godot/assets/materials/arch/bronze_metal.tres`
- `eldoria-godot/assets/materials/arch/building_door.tres`
- `eldoria-godot/assets/materials/arch/chimney_smoke.tres`
- `eldoria-godot/assets/materials/arch/courtyard_floor.tres`
- `eldoria-godot/assets/materials/arch/curtain_wall_stone.tres`
- `eldoria-godot/assets/materials/arch/gate_tower_main.tres`
- `eldoria-godot/assets/materials/arch/gold_trim.tres`
- `eldoria-godot/assets/materials/arch/hot_forge_metal.tres`
- `eldoria-godot/assets/materials/arch/house_foundation.tres`
- `eldoria-godot/assets/materials/arch/iron_metal.tres`
- `eldoria-godot/assets/materials/arch/mossy_brick_wall.tres`
- `eldoria-godot/assets/materials/arch/overgrown_brick.tres`
- `eldoria-godot/assets/materials/arch/roof_moss_tiles.tres`
- `eldoria-godot/assets/materials/arch/temple_floor.tres`
- `eldoria-godot/assets/materials/arch/whitewashed_plaster.tres`
- `eldoria-godot/assets/materials/arch/wood_beam.tres`
- `eldoria-godot/assets/materials/arch/wood_flooring.tres`
- `eldoria-godot/assets/materials/eldoria_terrain_assets.tres`
- `eldoria-godot/assets/materials/tidesong/barnacle_rock.tres`
- `eldoria-godot/assets/materials/tidesong/driftwood.tres`
- `eldoria-godot/assets/materials/tidesong/fine_sand_beach.tres`
- `eldoria-godot/assets/materials/tidesong/island_cliff.tres`
- `eldoria-godot/assets/materials/tidesong/mossy_island_cliff.tres`
- `eldoria-godot/assets/materials/tidesong/ocean_spray_planks.tres`
- `eldoria-godot/assets/materials/tidesong/sand_pebble_beach.tres`
- `eldoria-godot/assets/materials/tidesong/seaweed.tres`

## Notes

- AnimationLibrary check is currently a no-op: 435 source FBX files exist under `eldoria-godot/assets/animations/` but no `.tres` AnimationLibrary has been built. See Canon QA item CQ-S2-07 (owner @animation-sourcer).
- Owners: orphan assets → builder/character; orphan quests → quest-writer; orphan materials → architect/environment/scale-engineer.
