# Integration Gaps — 2026-05-06 integrator run

## Run summary
- Canon QA status: PASS_WITH_DEBT (no S1 blockers)
- Branches merged: auto/lore (1 commit), auto/art (2 commits)
- Branches skipped: auto/scale (CHANGES.md + WorldBuilder.gd conflicts with main)
- Branches with no work: auto/builder, auto/polisher, auto/character, auto/qa, auto/scale-floorfix

## Cross-agent gaps detected

### From auto/lore merge:
- New codex file: `eldoria-godot/data/codex/longnight_vigil.md` (Hollow King + Calendar)
  - [GAP: orphan codex] Not yet referenced in any NPC dialogue or quest. Lorekeeper should hook into a dialogue line or codex-unlock event.

### From auto/art merge:
- New mood-board reference: `mood-boards/architecture_palette.png` (run-27 delta)
- New mood-board reference: `mood-boards/magic_glow_reference.png` (run-28 delta)
  - These are reference assets only — no game-code integration required. Used by artist agents downstream.

### Skipped (auto/scale):
- [INTEGRATOR-MANUAL] auto/scale (76bb428) modifies CHANGES.md and eldoria-godot/scripts/WorldBuilder.gd
  - CHANGES.md conflicts with main's recent additions
  - WorldBuilder.gd diverged from base in both branches
  - Owner @scale-engineer should rebase auto/scale onto latest main
