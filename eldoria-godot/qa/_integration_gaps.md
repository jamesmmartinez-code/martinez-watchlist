# Integration Gaps — Integrator Audit
generated_at: 2026-05-06T19:05:00Z
integrator_run: post-merge cycle

## Cycle summary

- Canon QA gate status: PASS_WITH_DEBT (no S1, 7 S2 logged)
- Branches discovered: 10 (auto/art, auto/audio, auto/builder, auto/character, auto/environment, auto/lore, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix)
- Branches merged this cycle: auto/environment (1 commit), auto/audio (1 commit)
- Branches with no new commits: auto/art (already integrated upstream), auto/builder, auto/character, auto/lore, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix
- All 9 worker auto/* branches reset to main after merge.
- Merge method: GitHub merges API (HTTP 201 confirmed for environment + audio).

## [GAP: orphan asset]

- `eldoria-godot/assets/models/Fox.glb` — present under `assets/` but no spawn logic in `WorldBuilder.gd`, `Items.gd`, `Enemy.gd`, or `Player.gd`. Either route Fox into a creature/pet spawn table or move out of `assets/models/`. (Carry-over.)

## [GAP: orphan quest]

- `eldoria-godot/data/quests/crystal_caves/bones_in_the_choirstone.tres` — defined but no NPC dialogue under `data/dialogue/` references it.
- `eldoria-godot/data/quests/crystal_caves/shards_for_mara.tres` — defined but no NPC dialogue under `data/dialogue/` references it.
  (Both are crystal_caves region quests; likely awaiting NPC dialogue authoring. Owner: @quest-writer. Carry-over.)

## [GAP: orphan animation]

- `eldoria-godot/assets/animations/` contains 0 `.tres` AnimationLibraries (435 source FBX files unbuilt).
  Consistent with CQ-S2-07 from canon-qa; tracked there. No new gap.

## [GAP: orphan material]

- 36 `.tres` materials under `assets/materials/` show no static reference from project `.tscn` scenes or core scripts. Expected — materials are loaded dynamically by constructed paths in WorldBuilder.gd's `_make_*` family. Flag suppressed; if a runtime material miss shows up in QA, revisit per-material.

## Notes for next integrator cycle

- All 9 auto/* branches were reset to main after this cycle. Next integrator run will start clean.
- auto/environment and auto/audio were the only divergent (ahead) branches; both merged via GitHub merges API (no local checkout, due to repo size).
- All other auto/* branches were "behind ahead=0" — content-equivalent dupes from prior runs that never got reset. Now cleaned up.
- No conflicts encountered. Manual-flag list is empty.
- This integrator run intentionally did NOT do a static cross-agent gap re-scan (no full local checkout was possible this cycle). Carry-over gaps above are preserved from the previous cycle's report.