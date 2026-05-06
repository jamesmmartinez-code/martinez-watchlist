# Integration Gaps — Integrator Audit
generated_at: 2026-05-06T18:53:50Z
integrator_run: post-merge cycle

## Cycle summary

- Canon QA gate status: PASS_WITH_DEBT (no S1, 7 S2 logged)
- Branches discovered: 10
- Branches merged: auto/character (1 commits), auto/lore (1 commits)
- Branches with no new commits: auto/art, auto/audio, auto/builder, auto/environment, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix
- Final merge SHA: 093cb112a5f657e66a2ddfb679939c2570b715f4

## [GAP: orphan asset]

- `eldoria-godot/assets/models/Fox.glb` — present under `assets/` but no spawn logic in `WorldBuilder.gd`, `Items.gd`, `Enemy.gd`, or `Player.gd`. Either route Fox into a creature/pet spawn table or move out of `assets/models/`.

## [GAP: orphan quest]

- `eldoria-godot/data/quests/crystal_caves/bones_in_the_choirstone.tres` — defined but no NPC dialogue under `data/dialogue/` references it.
- `eldoria-godot/data/quests/crystal_caves/shards_for_mara.tres` — defined but no NPC dialogue under `data/dialogue/` references it.
  (Both are crystal_caves region quests; likely awaiting NPC dialogue authoring. Owner: @quest-writer.)

## [GAP: orphan animation]

- `eldoria-godot/assets/animations/` contains 0 `.tres` AnimationLibraries (435 source FBX files unbuilt).
  Consistent with CQ-S2-07 from canon-qa; tracked there. No new gap.

## [GAP: orphan material]

- 36 `.tres` materials under `assets/materials/` show no static reference from project `.tscn` scenes or core scripts. This is expected — materials are loaded dynamically by constructed paths in WorldBuilder.gd's `_make_*` family. Flag suppressed; if a runtime material miss shows up in QA, revisit per-material.

## Notes for next integrator cycle

- Reset complete: `auto/character` and `auto/lore` fast-forwarded to `refs/heads/main`. Other auto/* branches were already at-or-behind main and need no reset.
- No conflicts encountered. Manual-flag list is empty.
