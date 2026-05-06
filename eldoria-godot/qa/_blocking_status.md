# Canon QA Blocking Status
generated_at: 2026-05-06T11:55:00Z
status: PASS_WITH_DEBT
s1_count: 0
s2_count: 7
s3_count: 3

## Reason

Cycle 2 (2026-05-06) of Canon QA found zero S1 violations across all 12 checks (story 1-7 + visual 8-12). Building scale floor (Check 8), windmill ≥6m (also Check 8), tree visual cap ≤14m (Check 9), `.tscn` material discipline (Check 12), and theme-tool compliance (Check 11) are all clean. The user-cited 2026-05-05 "tiny windmill" and "trees that read as walls" failures are no longer reproducible from static source analysis — the 2026-05-06 HAMMER tree-cap commit and the explicit 1.55× windmill scale closed both. Seven S2 issues remain (4 missing flavor entries, 3 catalog/runtime drift items, 1 missing recipe, 1 unverifiable tree collision parity, 1 not-yet-shipped AnimationLibrary batch). None block merge per the integrator's PASS_WITH_DEBT contract.

## S1 issues (block reason)

(none)

## S2 issues (logged for integrator audit)

- `data/items_flavor.json` — missing `briar_shortbow`, `mossbound_buckler`, `roan_woodbow`, `wolf_heart` (catalog flags `needs_flavor: yes`) [CQ-S2-01, owner @lorekeeper]
- `scripts/Items.gd` — legacy ITEMS dict missing `briar_shortbow`, `mossbound_buckler`, `roan_woodbow` (defined as `.tres` only) [CQ-S2-02, owner @builder]
- `data/dialogue/trainer_hala.json` — `practice_cudgel` reward, no flavor entry [CQ-S2-03, carry-over from 2026-05-05]
- `data/dialogue/stablemaster_roan.json` + `lore/npcs/stablemaster_roan.md` — `Steppe-Patterned Halter`, no flavor entry [CQ-S2-04, carry-over from 2026-05-05]
- `data/items/_catalog.csv` row `mossbound_buckler` — `acquired_via:craft` with no recipe under `data/recipes/**` [CQ-S2-05, owner @recipe-author]
- `scripts/WorldBuilder.gd:3028-3052` — tree collision radius vs visual trunk parity unverifiable from static source; in-engine AABB print needed [CQ-S2-06, owner @scale-engineer]
- `eldoria-godot/assets/animations/` — 435 source FBX files, 0 `.tres` AnimationLibraries built; first batch not shipped [CQ-S2-07, owner @animation-sourcer]

## S3 issues (future-debt)

- 16 intermediate recipe-input materials not in catalog (bootstrap) [CQ-S3-01]
- 4 recipe outputs not in catalog (bootstrap intermediates: iron_buckle, iron_ingot, leather_strip, marshmint_dye) [CQ-S3-02]
- No per-NPC reference plate under `concept/`; current convention uses `assets/portraits/` [CQ-S3-03]

## Visual checks 8-12 — explicit pass list (for the integrator log)

| Check | Result | Notes |
|-------|--------|-------|
|  8 — Building scale floor | PASS | hut 5.35m, windmill 8.8m; no curtain-wall/gate-tower in tree yet (N/A) |
|  9 — Tree cap + collision | PARTIAL PASS | visual cap clean post-HAMMER; collision parity unverifiable static → S2 |
| 10 — Animation presence    | PASS_WITH_DEBT | per-character GLBs ship anims; named-NPC AnimationLibrary batch not yet shipped → S2 |
| 11 — Theme tool compliance | PASS | zero figma references; all 20 visual commits properly tool-tagged |
| 12 — Naked-grey mesh       | PASS | 3 `.tscn` files: 1 has material_override, 2 have no MeshInstance3D nodes |

