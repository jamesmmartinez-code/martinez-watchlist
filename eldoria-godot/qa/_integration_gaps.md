# Integration Gaps Report
generated: 2026-05-06T06:35:00Z
integrator_run: 403f256c7d564a180d9a81369498f3bb1ff34afa

## Summary
- Canon QA gate: PASS (no _blocking_status.md on main — pre-first-audit fallback)
- Branches discovered: 8 (art, builder, character, lore, polisher, qa, scale, scale-floorfix)
- Branches with new commits: 4 (auto/art, auto/builder, auto/polisher, auto/scale)
- Branches merged: 4
- Branches skipped (no commits ahead): 4 (auto/character, auto/lore, auto/qa, auto/scale-floorfix)
- Conflicts: 0
- Gaps detected: 0

## Merge SHAs
- auto/builder   → b1156c9ad709281e3d8607e9e7191b931bed4c71
- auto/polisher  → 285a64faf9ee9a2cdb371e1f0f8a28de8776f176
- auto/scale     → bff6dbc28569117832d0437997359da9dd938e12
- auto/art       → 403f256c7d564a180d9a81369498f3bb1ff34afa

## Findings
No orphan .glb assets, quest .tres files, AnimationLibrary .tres, or StandardMaterial3D .tres added in this cycle. The 5 net-changed files are 4 painterly loot icons (already wired through Items.gd) plus the icon-generation script.

## Worker branches reset
All four merged worker branches fast-forwarded to main (403f256c) so next-cycle agent runs start clean.
