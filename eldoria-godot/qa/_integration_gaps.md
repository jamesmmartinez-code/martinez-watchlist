# Integration Gaps Log

last_run: 2026-05-06T17:02Z
canon_qa_status_at_run: PASS_WITH_DEBT (s1=0, s2=7, s3=3 — see eldoria-godot/qa/_blocking_status.md)
merged_this_cycle: (none — all auto/* branches 0 ahead of main)
skipped_this_cycle: (none)
nothing_to_merge: auto/art, auto/builder, auto/character, auto/environment, auto/lore, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix

## This cycle merged

No worker branches had unmerged commits. Each auto/* branch is 0 ahead /
N behind main this cycle (auto/character behind 11; auto/environment and
auto/art behind 2; the rest behind 19). This is a no-op integrator pass —
worker agents must rebase onto main and push fresh commits before the next
cycle picks anything up.

Per the spec's branch-reset rule (Step 3 only iterates MERGED), no resets
were performed this cycle; resets only occur after a successful merge.
Workers needing a fresh start can fetch and reset locally.

## Gaps surfaced this run

The static-source scan was rerun against current main (sha 7da66998). Two
new gap categories surface that were not previously called out:

### [GAP: orphan material] — pilot StandardMaterial3D set never wired

Twenty-six StandardMaterial3D `.tres` files exist under
`eldoria-godot/assets/materials/arch/` and `.../tidesong/` (originated in
pilot/eldoria-materials-v1) but no `.tscn` MeshInstance and no
WorldBuilder.gd `_make_*` function references them by basename. They are
texture-bound and ready to use, but unhooked. Owner: @builder or
@architect — pick a per-prop or per-region binding pattern and wire them
into the relevant `_make_*` paths.

  - assets/materials/arch/: bronze_metal, building_door, chimney_smoke,
    courtyard_floor, curtain_wall_stone, gate_tower_main, gold_trim,
    hot_forge_metal, house_foundation, iron_metal, mossy_brick_wall,
    overgrown_brick, roof_moss_tiles, temple_floor, whitewashed_plaster,
    wood_beam, wood_flooring (17 files)
  - assets/materials/tidesong/: barnacle_rock, driftwood, fine_sand_beach,
    island_cliff, mossy_island_cliff, ocean_spray_planks, sand_pebble_beach,
    seaweed (8 files)
  - assets/materials/eldoria_terrain_assets.tres — possibly consumed by the
    Terrain3D plugin; verify before flagging.

Note: data/items/materials/*.tres are ItemResource (script_class), not
StandardMaterial3D, and are correctly referenced via the items catalog and
recipes — not flagged.

### [GAP: orphan animation] — none

`eldoria-godot/assets/animations/` contains 435 source FBX files but zero
built `.tres` AnimationLibrary resources, so there is nothing to mark
orphan yet (this is CQ-S2-07's domain — first batch unshipped).

## S2 issues forwarded from canon-qa (PASS_WITH_DEBT contract)

Per CQ cycle-2 audit (2026-05-06T11:55Z), seven S2 items remain logged for
follow-up. Listed here so worker agents pick them up next cycle:

- [CQ-S2-01 @lorekeeper] data/items_flavor.json missing flavor for
  briar_shortbow, mossbound_buckler, roan_woodbow, wolf_heart.
- [CQ-S2-02 @builder] scripts/Items.gd legacy ITEMS dict missing
  briar_shortbow, mossbound_buckler, roan_woodbow (defined as .tres only).
- [CQ-S2-03 carry-over] data/dialogue/trainer_hala.json practice_cudgel
  reward, no flavor entry.
- [CQ-S2-04 carry-over] data/dialogue/stablemaster_roan.json + lore/npcs/
  stablemaster_roan.md "Steppe-Patterned Halter" no flavor entry.
- [CQ-S2-05 @recipe-author] data/items/_catalog.csv row mossbound_buckler
  declares acquired_via:craft but no recipe under data/recipes/**.
- [CQ-S2-06 @scale-engineer] scripts/WorldBuilder.gd:3028-3052 tree collision
  radius vs visual trunk parity unverifiable from static source — needs
  in-engine AABB print.
- [CQ-S2-07 @animation-sourcer] eldoria-godot/assets/animations/ has 435
  source FBX files, 0 .tres AnimationLibraries built; first batch not
  shipped.

## Carry-over from prior cycles (still unresolved)

[GAP: orphan quest] eldoria-godot/data/quests/crystal_caves/bones_in_the_choirstone.tres
  — quest file exists in _index.tres but no NPC dialogue JSON references
    it by id. Owner: @quest-writer or @lorekeeper.

[GAP: orphan quest-dialogue link] eldoria-godot/data/quests/crystal_caves/shards_for_mara.tres
  — quest is in _index.tres and qa cross_ref_graph but Mara dialogue
    (data/dialogue/mara_merchant.json) lacks the shards-for-mara hook
    node. Owner: @lorekeeper.
