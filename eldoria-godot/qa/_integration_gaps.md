# Integration Gaps Report — 2026-05-06T07:53:47Z

Run: scheduled integrator
Canon QA gate: PASS (no _blocking_status.md present on main, defaulted)
Branches discovered: 8 (auto/art, auto/builder, auto/environment, auto/lore, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix)
Branches merged: auto/environment (1 commit), auto/lore (1 commit)
Branches skipped (conflicts): none
Branches with no commits ahead (skipped): auto/art, auto/builder, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix

## Gap Scan
Scanned new files in merged commits for orphan assets / quests / animations / materials.

New / modified files this run:
auto/environment merge (b978ee72):
- eldoria-godot/scripts/WorldBuilder.gd  (modified — env motion: pond reeds sway, mushroom breathe, boss-banner flap per THEME §12; no new assets)

auto/lore merge (b8a3e940):
- WORLD_STATE.md                                    (modified — record Stablemaster Roan dialogue addition)
- eldoria-godot/data/dialogue/stablemaster_roan.json (modified — 4 new road_warden warm-tier lines mentioning 'between two stones')

Gap rule checks:
- Orphan asset (.glb in assets/ with no spawn logic in WorldBuilder.gd or _make_*): none — no .glb added
- Orphan quest (.tres in data/quests/ with no NPC dialogue): none — no quest .tres added
- Orphan animation (AnimationLibrary .tres with no .tscn ref): none added
- Orphan material (StandardMaterial3D .tres with no MeshInstance use): none added
- Orphan dialogue (dialogue.json edits with no NPC referencing): none — stablemaster_roan.json corresponds to existing Stablemaster Roan NPC

Gaps found: 0
