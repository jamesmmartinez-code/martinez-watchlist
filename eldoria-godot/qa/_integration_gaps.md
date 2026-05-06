# Integration Gaps — Eldoria

generated_at: 2026-05-06T18:27:00Z
integrator_run: 20260506T182805Z

## Summary

Cycle ran clean. Canon QA status was `PASS_WITH_DEBT` (S1=0, S2=7, S3=3); merge proceeded.

## Branches merged this cycle

- `auto/art` (1 commit) → modifies `eldoria-godot/assets/ART_COVERAGE.md` only (documentation update). No new `.glb`, `.tres`, or shader artifacts were introduced, so no orphan-asset gaps were produced by this merge.

## Branches with no new commits (skipped, behind main)

- auto/audio, auto/builder, auto/character, auto/environment, auto/lore, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix
- All show ahead=0 vs main; behind counts range 6–28. These workers should rebase from main on next run (Step 3 only resets merged branches).

## Gaps detected

(none from this cycle's merge)

## Outstanding cross-agent observations

These are not gaps from this cycle but background notes to inform owners on next run:

- Several `.glb` files under `eldoria-godot/assets/models/` (Boss.glb, Fox.glb, Hero.glb, enemies/*.glb, heroes/*.glb, npcs/warrior.glb, npcs/worker_girl.glb) are not referenced by `WorldBuilder.gd`. Spot-check confirms they are referenced from feature scripts (e.g. `Boss.gd`, `PLAYER_MODEL.md`, `CombatScene`-family); these are **not** orphan-spawn gaps but live elsewhere in the spawn graph. Listed for visibility only.
- Canon QA debt log carries 7 S2 items (missing flavor entries, catalog/runtime drift, missing recipe, AnimationLibrary batch not-yet-shipped). Owners: @lorekeeper, @builder. These remain logged for next cycle.

