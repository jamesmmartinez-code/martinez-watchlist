# Eldoria Integration Gaps
generated_at: 2026-05-07T02:56:51Z
by: integrator (auto)
main: 5061c10f6598bb3d2e3612ca8aeee073597079ba
canon_qa_status: PASS_WITH_DEBT (carried from 2026-05-06T11:55:00Z)

## Summary

- orphan assets (`.glb`): 15
- orphan quests (`data/quests/*.tres`): 2 (crystal_caves quests with no NPC dialogue refs)
- orphan animations (AnimationLibrary `.tres`): 0 (no AnimationLibrary .tres present — see CQ-S2-07)
- orphan StandardMaterial3D `.tres`: 26 (carried from 2026-05-06)
- new this run: fishing spot (1), shop (1), recipe (1) — see "new wiring needed" below

## This run merged

- auto/environment, auto/art, auto/lore (with -X theirs conflict resolve), auto/audio, auto/codex, auto/fishing-spot, auto/legend, auto/pastry, auto/shop-vendor (9 branches)
- auto/builder, auto/polisher, auto/scale, auto/animation-sourcer, auto/qa, auto/scale-floorfix were no-op (0 ahead)
- All 9 merged worker branches force-reset to main per Step 3

## [GAP: orphan asset] — `.glb` with no spawn logic in WorldBuilder.gd

GLB files present in `assets/models/` but the basename is not referenced in `scripts/WorldBuilder.gd`. May be wired by a different agent (CharacterSelect.gd, Player.gd, Enemy.gd) — verify owner before removing.

- `eldoria-godot/assets/models/Boss.glb`
- `eldoria-godot/assets/models/CesiumMan.glb`
- `eldoria-godot/assets/models/Fox.glb`
- `eldoria-godot/assets/models/Hero.glb`
- `eldoria-godot/assets/models/Horse.glb`
- `eldoria-godot/assets/models/enemies/bandit.glb`
- `eldoria-godot/assets/models/enemies/crystal_elemental.glb`
- `eldoria-godot/assets/models/enemies/goblin.glb`
- `eldoria-godot/assets/models/enemies/goblin_scout.glb`
- `eldoria-godot/assets/models/enemies/skeleton.glb`
- `eldoria-godot/assets/models/enemies/wolf.glb`
- `eldoria-godot/assets/models/heroes/alden_pathfinder.glb`
- `eldoria-godot/assets/models/heroes/owen_vanguard.glb`
- `eldoria-godot/assets/models/npcs/warrior.glb`
- `eldoria-godot/assets/models/npcs/worker_girl.glb`

## [GAP: orphan quest] — `data/quests/*.tres` with no NPC dialogue mention

Quest resources whose ID/basename is not mentioned in any dialogue JSON nor lore/npcs/. Assign to quest-writer.

- `eldoria-godot/data/quests/crystal_caves/bones_in_the_choirstone.tres` — 0 refs in dialogue/npcs
- `eldoria-godot/data/quests/crystal_caves/shards_for_mara.tres` — 0 refs in dialogue/npcs

## [GAP: new feature data — wiring TBD]

Newly merged data files this run that have no consuming script/scene yet (not strictly an orphan rule, logged for visibility):

- `eldoria-godot/data/fishing/spots/misty_morning_cove.tres` — fishing-spot resource; no consumer in scripts/scenes yet (assign to builder/fishing-system)
- `eldoria-godot/data/shops/whisperwood_wonders.tres` — shop resource; no vendor wiring yet (assign to shop-vendor / builder)
- `eldoria-godot/data/food/pastry/lemon_sunrise_biscuit.tres` — recipe resource; verify recipe registry includes it

## [GAP: orphan material] — carried from prior audit

26 `StandardMaterial3D` .tres files in `assets/materials/{arch,tidesong}/` and one terrain-assets resource still not referenced in any `.tscn` or `.gd`. Unchanged from the 2026-05-06T20:48:44Z audit; ownership remains architect / environment / scale-engineer.

## Canon QA debt log (PASS_WITH_DEBT — S2 carry-over)

These are gating Canon QA's status one notch below PASS. Resolving them flips status to PASS:

- CQ-S2-01 — `data/items_flavor.json` missing flavor entries (briar_shortbow, mossbound_buckler, roan_woodbow, wolf_heart) → @lorekeeper
- CQ-S2-02 — `scripts/Items.gd` legacy ITEMS dict missing same items → @builder
- CQ-S2-03 — `practice_cudgel` no flavor entry (carry-over) → @lorekeeper
- CQ-S2-04 — `Steppe-Patterned Halter` no flavor entry (carry-over) → @lorekeeper
- CQ-S2-05 — `mossbound_buckler` craft recipe missing → @recipe-author
- CQ-S2-06 — tree collision/visual parity unverifiable static → @scale-engineer
- CQ-S2-07 — 435 source FBX, 0 AnimationLibrary .tres shipped → @animation-sourcer
