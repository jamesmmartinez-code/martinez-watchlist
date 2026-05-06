# Integration Gaps Log

last_run: 2026-05-06T17:00Z
canon_qa_status_at_run: PASS_WITH_DEBT (s1=0, s2=7, s3=3 — see eldoria-godot/qa/_blocking_status.md)
merged_this_cycle: auto/environment (1 commit), auto/art (1 commit)
skipped_this_cycle: (none)
nothing_to_merge: auto/builder, auto/character, auto/lore, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix

## This cycle merged

- auto/environment (1 commit, b53e7acc): "Env: ambient wildlife — butterflies + pond dragonflies (THEME §12)".
  Net diff against main = 0 files / 0 additions / 0 deletions — the underlying
  changes were already present on main from a prior cycle, so this merge was a
  no-op fast-forward of the branch tip onto main's history. Branch reset to
  main after merge to clear the stale tip.

- auto/art (1 commit, eec8102d): "Art: mood-boards — world_map_sketch.png (run-30)".
  Added mood-boards/_gen_world_map_sketch.py and mood-boards/world_map_sketch.png.
  Modified eldoria-godot/assets/ART_COVERAGE.md to log the new mood board.
  Mood-board assets live outside the runtime tree (no .tscn / .gd reference
  expected); not orphans by definition.

## Gaps surfaced this run

(No new orphan-asset, orphan-quest, orphan-animation, or orphan-material gaps
found in this cycle's diff. Only file additions were two mood-board assets in
mood-boards/, which are reference-only and not loaded by any scene.)

## S2 issues forwarded from canon-qa (PASS_WITH_DEBT contract)

Per CQ cycle-2 audit (2026-05-06T11:55Z), seven S2 items remain logged for
follow-up. Listed here so worker agents pick them up next cycle:

- [CQ-S2-01 @lorekeeper] data/items_flavor.json missing flavor for
  briar_shortbow, mossbound_buckler, roan_woodbow, wolf_heart.
- [CQ-S2-02 @builder] scripts/Items.gd legacy ITEMS dict missing
  briar_shortbow, mossbound_buckler, roan_woodbow (defined as .tres only).
- [CQ-S2-03 carry-over] data/dialogue/trainer_hala.json practice_cudgel reward,
  no flavor entry.
- [CQ-S2-04 carry-over] data/dialogue/stablemaster_roan.json + lore/npcs/
  stablemaster_roan.md "Steppe-Patterned Halter" no flavor entry.
- [CQ-S2-05 @recipe-author] data/items/_catalog.csv row mossbound_buckler
  declares acquired_via:craft but no recipe under data/recipes/**.
- [CQ-S2-06 @scale-engineer] scripts/WorldBuilder.gd:3028-3052 tree collision
  radius vs visual trunk parity unverifiable from static source — needs
  in-engine AABB print.
- [CQ-S2-07 @animation-sourcer] eldoria-godot/assets/animations/ has 435 source
  FBX files, 0 .tres AnimationLibraries built; first batch not shipped.

## Carry-over from prior cycle (still unresolved)

[GAP: orphan quest] eldoria-godot/data/quests/crystal_caves/bones_in_the_choirstone.tres
  — quest file exists in _index.tres and quest_grammar.md but no NPC dialogue
    JSON references it. Owner: @quest-writer or @lorekeeper.

[GAP: orphan quest-dialogue link] eldoria-godot/data/quests/crystal_caves/shards_for_mara.tres
  — quest is in _index.tres and qa cross_ref_graph but no dialogue JSON
    mentions it by name. Owner: @lorekeeper — Mara dialogue (data/dialogue/
    mara_merchant.json) needs the shards-for-mara hook node.

[GAP: orphan material] eldoria-godot/assets/materials/tidesong/* (8 .tres files)
  — biome materials authored but no scene or script references them.
  Tidesong realm may not be in scene tree yet. Owner: @environment / @architect.

[GAP: orphan material] eldoria-godot/assets/materials/arch/* (wood_flooring.tres,
  wood_beam.tres) — architectural material set authored but unreferenced by any
  MeshInstance3D. Owner: @architect.
