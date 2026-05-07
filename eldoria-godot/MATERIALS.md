# Eldoria Substance Materials

Auto-generated index of every Substance 3D Sampler material baked into the repo.
Maintained by the `eldoria-substance-materials` agent. Each entry has 4 channels
(basecolor, normal, roughness, ambientocclusion) and a `StandardMaterial3D`
resource at `eldoria-godot/assets/materials/<group>/<name>.tres` ready for
WorldBuilder.gd to assign.

> **Note on filenames:** the agent task spec called for `albedo.jpg` / `ao.jpg`,
> but this repo's existing convention is `basecolor.png` / `ambientocclusion.png`
> (all PNG, no JPG). New materials follow the established convention to stay
> compatible with the 25 sets already wired up.

## Group `arch/` — 17 materials (architecture & interiors)

| Material | Source bake | Maps | Textures path |
|---|---|---|---|
| `bronze_metal` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/bronze_metal/` |
| `building_door` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/building_door/` |
| `chimney_smoke` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/chimney_smoke/` |
| `courtyard_floor` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/courtyard_floor/` |
| `curtain_wall_stone` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/curtain_wall_stone/` |
| `gate_tower_main` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/gate_tower_main/` |
| `gold_trim` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/gold_trim/` |
| `hot_forge_metal` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/hot_forge_metal/` |
| `house_foundation` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/house_foundation/` |
| `iron_metal` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/iron_metal/` |
| `mossy_brick_wall` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/mossy_brick_wall/` |
| `overgrown_brick` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/overgrown_brick/` |
| `roof_moss_tiles` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/roof_moss_tiles/` |
| `temple_floor` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/temple_floor/` |
| `whitewashed_plaster` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/whitewashed_plaster/` |
| `wood_beam` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/wood_beam/` |
| `wood_flooring` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/arch/wood_flooring/` |

## Group `tidesong/` — 8 materials (Tidesong realm: islands, shore, planks)

| Material | Source bake | Maps | Textures path |
|---|---|---|---|
| `barnacle_rock` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/tidesong/barnacle_rock/` |
| `driftwood` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/tidesong/driftwood/` |
| `fine_sand_beach` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/tidesong/fine_sand_beach/` |
| `island_cliff` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/tidesong/island_cliff/` |
| `mossy_island_cliff` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/tidesong/mossy_island_cliff/` |
| `ocean_spray_planks` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/tidesong/ocean_spray_planks/` |
| `sand_pebble_beach` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/tidesong/sand_pebble_beach/` |
| `seaweed` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/tidesong/seaweed/` |

## Group `terrain/` — 4 materials (overworld ground textures)

| Material | Source bake | Maps | Textures path |
|---|---|---|---|
| `briarwood_path` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/terrain/briarwood_path/` |
| `crystal_caves_floor` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/terrain/crystal_caves_floor/` |
| `plateau_grass` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/terrain/plateau_grass/` |
| `whisperwood_floor` | 2026-05-06 · 256x256 | basecolor + normal + roughness + AO | `assets/textures/terrain/whisperwood_floor/` |

## Wireup status

The Environment Specialist agent owns the WorldBuilder.gd integration. The
`MAT_GRASS / MAT_WOOD / MAT_STONE / MAT_BARK / MAT_LEAF` helpers in
WorldBuilder.gd do **not** auto-pick-up new `.tres` — they need explicit
references. After this agent imports a material, the Environment agent decides
where to slot it.

Last sync: 2026-05-06 by `eldoria-substance-materials` agent.
