# Integration Gaps Report — 2026-05-06T07:08:21Z

Run: scheduled integrator
Canon QA gate: PASS (no _blocking_status.md present, defaulted)
Branches discovered: 8 (auto/art, auto/builder, auto/character, auto/lore, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix)
Branches merged: auto/art (1 commit)
Branches skipped (conflicts): auto/lore — content conflict in WORLD_STATE.md (unchanged from prior run; lore branch is 45 commits behind main and needs rebase by its worker) [INTEGRATOR-MANUAL]
Branches with no commits ahead: auto/builder, auto/character, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix

## Gap Scan
Scanned new files in merged commits for orphan assets / quests / animations / materials.

New files this run (from auto/art merge):
- eldoria-godot/assets/icons/captain_seal.png  (UI/quest icon — not a spawnable .glb, no spawn-logic gap)
- eldoria-godot/assets/ART_COVERAGE.md         (documentation update)
- scripts/art/gen_captain_seal_icon.py         (build-time generator, not runtime asset)

Gap rule checks:
- Orphan asset (.glb in assets/ with no spawn logic): none — no .glb added
- Orphan quest (.tres in data/quests/ with no NPC dialogue): none — no quest .tres added
- Orphan animation (AnimationLibrary .tres with no .tscn ref): none added
- Orphan material (StandardMaterial3D .tres with no MeshInstance use): none added

Gaps found: 0
