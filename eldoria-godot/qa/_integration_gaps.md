# Integration Gaps Log

last_run: 2026-05-06T16:46Z
canon_qa_status_at_run: PASS (no _blocking_status.md present — defaulted to PASS)
merged_this_cycle: auto/character (1 commit)
skipped_this_cycle: (none)
nothing_to_merge: auto/art, auto/builder, auto/environment, auto/lore, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix

## This cycle merged

- auto/character (1 commit, 2e8c89d): Replaced Smith Edda placeholder
  (worker_girl.glb) with Sketchfab Viking Framps Blacksmith
  (smith_edda.glb, 2.52 MiB, 22 native anims). Per Pillar 2 / THEME §4
  NPC silhouette table & §2 Norse-undertoned medieval era; OPERATIONS §15
  size budget ✅ (<20MiB).
  Conflict in eldoria-godot/scripts/WorldBuilder.gd auto-merged cleanly
  (char's 1-line NPC_MODELS edit at L30 + main's mountain ring 220m/320m
  upgrade and global-scale-sweep clamps were on disjoint hunks).
  CREDITS.md taken from char branch (main hadn't touched it).
  smith_edda.glb added (new file).

## Gaps surfaced this run

(No new orphan-asset, orphan-quest, orphan-animation, or orphan-material
gaps found relative to main's tree this cycle. Smith Edda's new GLB is
referenced by WorldBuilder.gd:30 NPC_MODELS table. .glb spawn graph
fully resolved across 35 GLBs in eldoria-godot/assets/.)

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
