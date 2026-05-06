# Integration Gaps Report — 2026-05-06T08:03:12Z

Run: scheduled integrator
Canon QA gate: PASS (no _blocking_status.md present on main, defaulted)
Branches discovered: 8 (auto/art, auto/builder, auto/environment, auto/lore, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix)
Branches merged: auto/environment (1 commit)
Branches skipped (conflicts): none
Branches with no commits ahead (skipped): auto/art, auto/builder, auto/lore, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix

## Gap Scan
Scanned new files in merged commits for orphan assets / quests / animations / materials.

New / modified files this run:
auto/environment merge (ea810803):
- eldoria-godot/scripts/WorldBuilder.gd  (modified, +74/-0 — env ambient atmosphere: falling leaves drift through Whisperwood canopy per THEME §12; no new assets)

Gap rule checks:
- Orphan asset (.glb in assets/ with no spawn logic in WorldBuilder.gd or _make_*): none — no .glb added
- Orphan quest (.tres in data/quests/ with no NPC dialogue): none — no quest .tres added
- Orphan animation (AnimationLibrary .tres with no .tscn ref): none added
- Orphan material (StandardMaterial3D .tres with no MeshInstance use): none added

Gaps found: 0