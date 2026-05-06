# Integration Gaps — 2026-05-06T15:20Z integrator run

## Run summary
- Canon QA status: PASS_WITH_DEBT (no S1 blockers; 7 S2 + 3 S3 logged)
- Branches discovered: 8 (auto/art, auto/builder, auto/character, auto/lore, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix)
- Branches merged: auto/character (1 commit, monk silhouette for Trainer Hala), auto/lore (1 commit, bandits faction)
- Branches skipped: auto/scale (CHANGES.md + WorldBuilder.gd conflicts with main)
- Branches with no work (0 ahead): auto/art, auto/builder, auto/polisher, auto/qa, auto/scale-floorfix

## Cross-agent gaps detected

### Orphan quests
- `eldoria-godot/data/quests/crystal_caves/bones_in_the_choirstone.tres` — [GAP: orphan quest] no NPC dialogue references it. Owner @quest-writer should wire it into a dialogue line or quest-giver hook.
- `eldoria-godot/data/quests/crystal_caves/shards_for_mara.tres` — [GAP: orphan quest] no NPC dialogue references it. Owner @quest-writer should add a dialogue branch (likely under a Crystal Caves NPC).

### Orphan materials (29 total — top items)
StandardMaterial3D `.tres` not referenced in any `.tscn` or `.gd`:
- Architecture set (17): `arch/bronze_metal`, `arch/building_door`, `arch/chimney_smoke`, `arch/courtyard_floor`, `arch/curtain_wall_stone`, `arch/gate_tower_main`, `arch/gold_trim`, `arch/hot_forge_metal`, `arch/house_foundation`, `arch/iron_metal`, `arch/mossy_brick_wall`, `arch/overgrown_brick`, `arch/roof_moss_tiles`, `arch/temple_floor`, `arch/whitewashed_plaster`, `arch/wood_beam`, `arch/wood_flooring`
- Tidesong set: `tidesong/barnacle_rock`, `tidesong/driftwood` (and ~10 more siblings)
- Misc: `eldoria_terrain_assets.tres`
- [GAP: orphan material] Owner @scale-engineer / @architect should either wire into MeshInstance3D nodes or move under `assets/materials/_unused/` to silence the audit.

### From auto/character merge
- `eldoria-godot/assets/models/npcs/trainer_hala.glb` — replaced placeholder with monk silhouette. WorldBuilder.gd already references `trainer_hala`, so spawn logic is intact. No gap.

### From auto/lore merge
- `eldoria-godot/data/lore/factions/bandits.md` (bandits faction) — codex/lore content; no in-game wiring required for this delta.

### Skipped (auto/scale)
- [INTEGRATOR-MANUAL] auto/scale commit `76bb428` (Scale: extend sweep to windmills/boulders/campfires/banner_poles/chests) conflicts with main:
  - `CHANGES.md` content conflict
  - `eldoria-godot/scripts/WorldBuilder.gd` content conflict
  - Owner @scale-engineer should rebase auto/scale onto current main (`b01e238`) and resolve.

### Orphan assets (.glb)
- 0 detected — all 33 `.glb` models are referenced by at least one `.gd` script.

### Orphan animations (.tres)
- 0 detected — no AnimationLibrary `.tres` files exist yet (consistent with Canon QA S2 issue CQ-S2-07: 435 source FBX, 0 `.tres` shipped).
