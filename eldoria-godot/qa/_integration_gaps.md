# Integration Gaps Report — 2026-05-06T07:24:10Z

Run: scheduled integrator
Canon QA gate: PASS (no _blocking_status.md present, defaulted)
Branches discovered: 9 (auto/art, auto/builder, auto/character, auto/environment, auto/lore, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix)
Branches merged: auto/environment (1 commit), auto/art (1 commit)
Branches skipped (conflicts): auto/lore — merge conflict via GitHub merge API (lore branch is 47 commits behind main; needs rebase by its worker) [INTEGRATOR-MANUAL]
Branches with no commits ahead: auto/builder, auto/character, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix

## Gap Scan
Scanned new files in merged commits for orphan assets / quests / animations / materials.

New / modified files this run:
auto/environment merge:
- eldoria-godot/scripts/WorldBuilder.gd  (modified — script change only, no asset additions)

auto/art merge:
- eldoria-godot/assets/icons/achievements/road_warden.png   (added — UI achievement icon, not a spawnable .glb)
- eldoria-godot/assets/icons/achievements/seal_keeper.png   (added — UI achievement icon, not a spawnable .glb)
- eldoria-godot/assets/icons/achievements/ATTRIBUTION.md    (modified — documentation)
- scripts/art/gen_achievement_icons.py                       (modified — build-time generator)

Gap rule checks:
- Orphan asset (.glb in assets/ with no spawn logic in WorldBuilder.gd or _make_*): none — no .glb added
- Orphan quest (.tres in data/quests/ with no NPC dialogue): none — no quest .tres added
- Orphan animation (AnimationLibrary .tres with no .tscn ref): none added
- Orphan material (StandardMaterial3D .tres with no MeshInstance use): none added

Gaps found: 0
