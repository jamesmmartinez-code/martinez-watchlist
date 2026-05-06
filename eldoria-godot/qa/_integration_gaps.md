# Integration Gaps Log

last_run: 2026-05-06T16:28Z
canon_qa_status_at_run: PASS_WITH_DEBT
merged_this_cycle: auto/scale (1)
skipped_this_cycle: (none)
nothing_to_merge: auto/builder, auto/polisher, auto/qa, auto/scale-floorfix, auto/environment, auto/art, auto/lore

## Gaps surfaced this run

[GAP: orphan quest] eldoria-godot/data/quests/crystal_caves/bones_in_the_choirstone.tres
  — quest file exists in _index.tres and quest_grammar.md but no NPC dialogue
    JSON references it. Owner: @quest-writer or @lorekeeper — needs a hook in
    one of the crystal-caves-adjacent NPCs (Mara is the obvious candidate).

[GAP: orphan quest-dialogue link] eldoria-godot/data/quests/crystal_caves/shards_for_mara.tres
  — quest is in _index.tres and qa cross_ref_graph but no dialogue JSON
    mentions it by name. Owner: @lorekeeper — Mara dialogue (data/dialogue/
    mara_merchant.json) needs the shards-for-mara hook node.

[GAP: orphan material] eldoria-godot/assets/materials/tidesong/* (8 .tres files:
  seaweed, sand_pebble_beach, ocean_spray_planks, mossy_island_cliff, island_cliff,
  fine_sand_beach, driftwood, barnacle_rock) — biome materials authored but no
  scene or script references them. Tidesong realm may not be in scene tree yet.
  Owner: @environment or @architect.

[GAP: orphan material] eldoria-godot/assets/materials/arch/* (wood_flooring.tres,
  wood_beam.tres) — architectural material set authored but unreferenced by any
  MeshInstance3D in scenes/ or scripts/. Owner: @architect.

## This cycle merged

- auto/scale (1 commit, 76bb428): _global_scale_sweep extended to clamp
  windmills, boulders, campfires, banner_poles, chests. CHANGES.md
  conflict resolved by combining the parallel-append sections (HEAD's
  ARCHITECT-NOTE block kept ahead of scale-eng's "missing canon" notes).
  WorldBuilder.gd auto-merged cleanly. Applied via cherry-pick because
  auto/scale was 131 commits behind main and a --no-ff merge would
  have wiped 130 commits of main work.

## Carry-over (from canon-qa _blocking_status.md)

PASS_WITH_DEBT: 7 S2 issues logged in eldoria-godot/qa/_blocking_status.md
(integrator does not block on these; owners listed in the status file).
