# Integration Gaps Log

last_run: 2026-05-06T17:36Z
canon_qa_status_at_run: PASS_WITH_DEBT (s1=0, s2=7, s3=3 — see eldoria-godot/qa/_blocking_status.md)
merged_this_cycle: auto/character (1 commit), auto/lore (1 commit)
skipped_this_cycle: (none)
push_result: df4d786

## This cycle merged

- auto/lore — Codex entry "Vellum's Spine" (mason's leaf, 3 new Old Faerie words). Adds eldoria-godot/data/codex/vellums_spine.md and updates WORLD_STATE.md.
- auto/character — Aligned character normalize targets with SIZE_STANDARDS.md canon. Modified scripts/Enemy.gd, scripts/Pet.gd, scripts/WorldBuilder.gd.

Other auto/* branches (auto/art, auto/builder, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix) were all behind main with 0 commits ahead — fast-forwarded only via Step 3 reset.

## Canon QA S2 carry-over (logged for owners)

From eldoria-godot/qa/_blocking_status.md (cycle 2 audit, 2026-05-06):

- [CQ-S2-01 @lorekeeper] data/items_flavor.json — missing briar_shortbow, mossbound_buckler, roan_woodbow, wolf_heart
- [CQ-S2-02 @builder] scripts/Items.gd — legacy ITEMS dict missing briar_shortbow, mossbound_buckler, roan_woodbow
- [CQ-S2-03] data/dialogue/trainer_hala.json — practice_cudgel reward, no flavor entry
- [CQ-S2-04] data/dialogue/stablemaster_roan.json — Steppe-Patterned Halter, no flavor entry
- [CQ-S2-05 @recipe-author] data/items/_catalog.csv row mossbound_buckler — acquired_via:craft, no recipe
- [CQ-S2-06 @scale-engineer] WorldBuilder.gd:3028-3052 — tree collision parity unverifiable static
- [CQ-S2-07 @animation-sourcer] eldoria-godot/assets/animations/ — 435 source FBX, 0 .tres AnimationLibraries

## Gaps surfaced this run

### Cycle delta

This cycle added one new file: `eldoria-godot/data/codex/vellums_spine.md` (codex lore entry, from auto/lore). It is a Markdown codex doc, not a .glb / quest .tres / AnimationLibrary / StandardMaterial3D, so it falls outside the four orphan-asset rule categories. It joins the existing seven codex .md files under data/codex/ and follows the same convention; no loader registration step is required.

auto/character only modified existing scripts (Enemy.gd, Pet.gd, WorldBuilder.gd) — no new assets to audit.

No new `.glb`, `data/quests/*.tres`, AnimationLibrary, or StandardMaterial3D files entered main this cycle, so the four orphan-asset rules produce zero new entries.

### [GAP: orphan asset] — character/enemy GLBs lacking spawn references in WorldBuilder.gd (carry-over)

- eldoria-godot/assets/models/Fox.glb — no spawn reference (likely glTF sample, false positive)
- eldoria-godot/assets/models/Hero.glb — no spawn reference (likely glTF sample, false positive)
- eldoria-godot/assets/models/enemies/goblin_scout.glb — no spawn reference [@character / @builder]
- eldoria-godot/assets/models/heroes/alden_pathfinder.glb — no spawn reference [@character / @builder]
- eldoria-godot/assets/models/heroes/owen_vanguard.glb — no spawn reference [@character / @builder]

### [GAP: orphan codex icon] — codex PNG icons not yet referenced via icon_glyph (carry-over)

- eldoria-godot/assets/icons/codex/the_sundering.png — no codex .md has `icon_glyph: the_sundering` [@lorekeeper]
- eldoria-godot/assets/icons/codex/oath_of_thorns.png — no codex .md has `icon_glyph: oath_of_thorns` [@lorekeeper]
- eldoria-godot/assets/icons/codex/wyrmsong_winds.png — no codex .md has `icon_glyph: wyrmsong_winds` [@lorekeeper]

Renderer falls back to legacy emoji, so non-blocking.

### [GAP: orphan banner] — sign PNGs added in prior cycle still not wired (carry-over)

- eldoria-godot/assets/banners/sign_to_briarwood.png — unused [@architect / @builder]
- eldoria-godot/assets/banners/sign_to_crystal_caves.png — unused [@architect / @builder]
- eldoria-godot/assets/banners/sign_to_whisperwood.png — unused [@architect / @builder]

Pending the road-sign placement pass.
