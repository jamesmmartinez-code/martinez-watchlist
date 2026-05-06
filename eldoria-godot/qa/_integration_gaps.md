# Integration Gaps — 2026-05-06T19:49:12Z

Auto-detected cross-agent gaps after integrator merge of 4 branches:
auto/character, auto/bestiary, auto/event, auto/recipe.

Scope: files newly added in this integrator run.

## NEW .glb assets

Newly added: 4
  - eldoria-godot/assets/models/enemies/goblin.glb
  - eldoria-godot/assets/models/enemies/wolf.glb
  - eldoria-godot/assets/models/npcs/maeve.glb
  - eldoria-godot/assets/models/npcs/smith_edda.glb

Not referenced in eldoria-godot/scripts/: 0
(none — all new GLBs referenced)

## NEW data resources

Creatures added: 2
  - eldoria-godot/data/creatures/briar_chat_validate_thorn_stalker.tres
  - eldoria-godot/data/creatures/briar_chat_validate_willow_wisp.tres
**Orphan (not referenced in dialogue/lore/scripts):**
```
[GAP: orphan creature] eldoria-godot/data/creatures/briar_chat_validate_thorn_stalker.tres
[GAP: orphan creature] eldoria-godot/data/creatures/briar_chat_validate_willow_wisp.tres
```

Recipes added: 2
  - eldoria-godot/data/recipes/cooking_pot/chat_validate_moonlit_morsel.tres
  - eldoria-godot/data/recipes/cooking_pot/chat_validate_starlight_stew.tres
**Orphan:**
```
[GAP: orphan recipe] eldoria-godot/data/recipes/cooking_pot/chat_validate_moonlit_morsel.tres
[GAP: orphan recipe] eldoria-godot/data/recipes/cooking_pot/chat_validate_starlight_stew.tres
```

Events added: 1
  - eldoria-godot/data/events/festivals/chat_validate_briarwood_festival.tres
**Orphan:**
```
[GAP: orphan event] eldoria-godot/data/events/festivals/chat_validate_briarwood_festival.tres
```

Rumors added: 1
  - eldoria-godot/data/rumors/briarwood_chat_validate.tres
**Orphan:**
```
[GAP: orphan rumor] eldoria-godot/data/rumors/briarwood_chat_validate.tres
```

## NEW AnimationLibrary / Materials

(none added in this integrator run)

## Canon QA debt carried (S2)

From PASS_WITH_DEBT status:

## S2 issues (logged for integrator audit)

- `data/items_flavor.json` — missing `briar_shortbow`, `mossbound_buckler`, `roan_woodbow`, `wolf_heart` (catalog flags `needs_flavor: yes`) [CQ-S2-01, owner @lorekeeper]
- `scripts/Items.gd` — legacy ITEMS dict missing `briar_shortbow`, `mossbound_buckler`, `roan_woodbow` (defined as `.tres` only) [CQ-S2-02, owner @builder]
- `data/dialogue/trainer_hala.json` — `practice_cudgel` reward, no flavor entry [CQ-S2-03, carry-over from 2026-05-05]
- `data/dialogue/stablemaster_roan.json` + `lore/npcs/stablemaster_roan.md` — `Steppe-Patterned Halter`, no flavor entry [CQ-S2-04, carry-over from 2026-05-05]
- `data/items/_catalog.csv` row `mossbound_buckler` — `acquired_via:craft` with no recipe under `data/recipes/**` [CQ-S2-05, owner @recipe-author]
- `scripts/WorldBuilder.gd:3028-3052` — tree collision radius vs visual trunk parity unverifiable from static source; in-engine AABB print needed [CQ-S2-06, owner @scale-engineer]
- `eldoria-godot/assets/animations/` — 435 source FBX files, 0 `.tres` AnimationLibraries built; first batch not shipped [CQ-S2-07, owner @animation-sourcer]

## S3 issues (future-debt)

