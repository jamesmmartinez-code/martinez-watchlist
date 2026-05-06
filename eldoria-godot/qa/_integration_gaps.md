# Integration Gaps Log

last_run: 2026-05-06T17:13Z
canon_qa_status_at_run: PASS_WITH_DEBT (s1=0, s2=7, s3=3 — see eldoria-godot/qa/_blocking_status.md)
merged_this_cycle: auto/environment (1 commit), auto/lore (1 commit)
skipped_this_cycle: (none)
push_result: ea8cefa

## This cycle merged

- auto/environment — Env: enemy camp fires (goblin pits flicker + sparks, THEME §12)
- auto/lore — Lore: codex (Thiar's Mercy, Owed to Prey)

Both branches reset to main via force-with-lease in Step 3 (rebase changed
commit hashes; content is identical so the force-reset is safe).

## Canon QA S2 carry-over (logged for owners)

From eldoria-godot/qa/_blocking_status.md (cycle 2 audit, 2026-05-06):

- [CQ-S2-01 @lorekeeper] data/items_flavor.json — missing briar_shortbow, mossbound_buckler, roan_woodbow, wolf_heart
- [CQ-S2-02 @builder] scripts/Items.gd — legacy ITEMS dict missing briar_shortbow, mossbound_buckler, roan_woodbow
- [CQ-S2-03] data/dialogue/trainer_hala.json — practice_cudgel reward, no flavor entry
- [CQ-S2-04] data/dialogue/stablemaster_roan.json — Steppe-Patterned Halter, no flavor entry
- [CQ-S2-05 @recipe-author] data/items/_catalog.csv row mossbound_buckler — acquired_via:craft, no recipe
- [CQ-S2-06 @scale-engineer] WorldBuilder.gd:3028-3052 — tree collision parity unverifiable static
- [CQ-S2-07 @animation-sourcer] eldoria-godot/assets/animations/ — 435 source FBX, 0 .tres AnimationLibraries

## Gaps surfaced this run

### [GAP: orphan asset] — character/enemy GLBs lacking spawn references in WorldBuilder.gd

Static scan of `eldoria-godot/scripts/WorldBuilder.gd` against added .glb basenames (last 50 commits):

- eldoria-godot/assets/models/Fox.glb — no spawn reference (sample/test asset?)
- eldoria-godot/assets/models/Hero.glb — no spawn reference (sample/test asset?)
- eldoria-godot/assets/models/RobotExpressive.glb — no spawn reference (sample/test asset?)
- eldoria-godot/assets/models/Soldier.glb — no spawn reference (sample/test asset?)
- eldoria-godot/assets/models/enemies/goblin_scout.glb — no spawn reference
- eldoria-godot/assets/models/hero_lange.glb — no spawn reference
- eldoria-godot/assets/models/heroes/alden_pathfinder.glb — no spawn reference
- eldoria-godot/assets/models/heroes/owen_vanguard.glb — no spawn reference

Note: Fox/Hero/RobotExpressive/Soldier appear to be glTF reference samples — likely false positives. The hero_lange / alden_pathfinder / owen_vanguard / goblin_scout entries warrant @character or @builder follow-up.

### [GAP: orphan material] — pilot StandardMaterial3D set still not wired (carry-over)

Twenty-six StandardMaterial3D `.tres` files exist under
`eldoria-godot/assets/materials/arch/` and `.../tidesong/` (originated in
pilot/eldoria-materials-v1) but no .tscn MeshInstance references them.
Carries forward from prior cycle.

### [GAP: orphan animation] — animation library not yet built (carry-over from CQ-S2-07)

435 source FBX files staged, 0 .tres AnimationLibraries built. No .tscn
references possible until the first batch ships. Tracked under CQ-S2-07.
