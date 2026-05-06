# Integration Gaps Report — 2026-05-06T07:46:27Z

Run: scheduled integrator
Canon QA gate: PASS (no _blocking_status.md present, defaulted)
Branches discovered: 7 (auto/art, auto/builder, auto/environment, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix)
Branches merged: auto/environment (1 commit), auto/art (1 commit)
Branches skipped (conflicts): none
Branches with no commits ahead: auto/builder, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix

## Gap Scan
Scanned new files in merged commits for orphan assets / quests / animations / materials.

New / modified files this run:
auto/environment merge:
- eldoria-godot/scripts/WorldBuilder.gd  (modified — script change adding campfire/well/grass spawn logic, no asset additions)

auto/art merge:
- eldoria-godot/assets/icons/_GENERATED.md         (added — generation manifest)
- eldoria-godot/assets/icons/briar_shortbow.png    (added — referenced by data/items/weapons/briar_shortbow.tres)
- eldoria-godot/assets/icons/roan_woodbow.png      (added — referenced by data/items/weapons/roan_woodbow.tres)
- eldoria-godot/assets/icons/mossbound_buckler.png (added — referenced by data/items/armor/mossbound_buckler.tres)

Gap rule checks:
- Orphan asset (.glb in assets/ with no spawn logic in WorldBuilder.gd or _make_*): none — no .glb added; WorldBuilder.gd changes wire CC-BY GLBs and grass sway
- Orphan quest (.tres in data/quests/ with no NPC dialogue): none — no quest .tres added
- Orphan animation (AnimationLibrary .tres with no .tscn ref): none added
- Orphan material (StandardMaterial3D .tres with no MeshInstance use): none added
- Orphan icon (PNG with no .tres reference): none — all 3 new icons referenced by item .tres files

Gaps found: 0
