# Integration Gaps Log

last_run: 2026-05-06T17:18Z
canon_qa_status_at_run: PASS_WITH_DEBT (s1=0, s2=7, s3=3 — see eldoria-godot/qa/_blocking_status.md)
merged_this_cycle: auto/art (1 commit)
skipped_this_cycle: (none)
push_result: 47dd0f1a

## This cycle merged

- auto/art — Banner sign PNGs for Briarwood / Crystal Caves / Whisperwood (3 textures + attribution + generator script)

Other auto/* branches (auto/builder, auto/character, auto/lore, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix) were all behind main with 0 commits ahead — fast-forwarded only via Step 3 reset.

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
auto/art added 3 banner sign PNGs (sign_to_briarwood.png, sign_to_crystal_caves.png, sign_to_whisperwood.png) under `eldoria-godot/assets/banners/` plus an attribution doc and a generator script. These are 2D textures, not .glb / .tres / AnimationLibrary / StandardMaterial3D, so they fall outside the four orphan-asset rule categories. Builder/architect should wire them onto signpost meshes when the road-sign placement pass runs.

### [GAP: orphan banner] — new sign PNGs not yet wired to signpost meshes [@architect / @builder]

- eldoria-godot/assets/banners/sign_to_briarwood.png — unused (just added this cycle)
- eldoria-godot/assets/banners/sign_to_crystal_caves.png — unused (just added this cycle)
- eldoria-godot/assets/banners/sign_to_whisperwood.png — unused (just added this cycle)

These are net-new this cycle; expected to be wired when the road-sign placement pass runs.

### [GAP: orphan asset] — character/enemy GLBs lacking spawn references in WorldBuilder.gd (carry-over)

- eldoria-godot/assets/models/Fox.glb — no spawn reference (likely glTF sample, false positive)
- eldoria-godot/assets/models/Hero.glb — no spawn reference (likely glTF sample, false positive)
- eldoria-godot/assets/models/RobotExpressive.glb — no spawn reference (likely glTF sample, false positive)
- eldoria-godot/assets/models/Soldier.glb — no spawn reference (likely glTF sample, false positive)
- eldoria-godot/assets/models/enemies/goblin_scout.glb — no spawn reference [@character / @builder]
- eldoria-godot/assets/models/hero_lange.glb — no spawn reference [@character / @builder]
- eldoria-godot/assets/models/heroes/alden_pathfinder.glb — no spawn reference [@character / @builder]
- eldoria-godot/assets/models/heroes/owen_vanguard.glb — no spawn reference [@character / @builder]

### [GAP: orphan codex icon] — codex PNG icons not yet referenced via icon_glyph (carry-over)

- eldoria-godot/assets/icons/codex/the_sundering.png — no codex .md has `icon_glyph: the_sundering` [@lorekeeper]
- eldoria-godot/assets/icons/codex/oath_of_thorns.png — no codex .md has `icon_glyph: oath_of_thorns` [@lorekeeper]
- eldoria-godot/assets/icons/codex/wyrmsong_winds.png — no codex .md has `icon_glyph: wyrmsong_winds` [@lorekeeper]

Renderer falls back to legacy emoji, so non-blocking.

### [GAP: orphan material] — pilot StandardMaterial3D set still not wired (carry-over)

Twenty-six StandardMaterial3D `.tres` files exist under
`eldoria-godot/assets/materials/arch/` and `.../tidesong/` (originated in
pilot/eldoria-materials-v1) but no .tscn MeshInstance references them.
Carries forward from prior cycles.

### [GAP: orphan animation] — animation library not yet built (carry-over from CQ-S2-07)

435 source FBX files staged, 0 .tres AnimationLibraries built. No .tscn
references possible until the first batch ships. Tracked under CQ-S2-07.
