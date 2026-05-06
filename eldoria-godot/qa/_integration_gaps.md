# Integration Gaps Log

last_run: 2026-05-06T17:38Z
canon_qa_status_at_run: PASS_WITH_DEBT (s1=0, s2=7, s3=3 — see eldoria-godot/qa/_blocking_status.md)
merged_this_cycle: auto/character (1), auto/lore (1), auto/audio (1), auto/environment (1)
skipped_this_cycle: (none)
push_result: cf303a2

## This cycle merged

- auto/lore — Codex entry "Vellum's Spine" (mason's leaf, 3 new Old Faerie words). Adds eldoria-godot/data/codex/vellums_spine.md and updates WORLD_STATE.md.
- auto/character — Aligned character normalize targets with SIZE_STANDARDS.md canon. Modified scripts/Enemy.gd, scripts/Pet.gd, scripts/WorldBuilder.gd.
- auto/audio — Replaced boss_intro.wav placeholder with a CC0 OGG stinger (eldoria-godot/assets/audio/sfx/boss_intro.ogg + .import; deleted .wav pair; updated audio/ATTRIBUTION.md).
- auto/environment — Market stall awning flap motion (THEME §12). WorldBuilder.gd-only change.

Other auto/* branches (auto/art, auto/builder, auto/polisher, auto/qa, auto/scale, auto/scale-floorfix) were behind main with 0 commits ahead — fast-forwarded only via Step 3 reset.

Note: auto/audio and auto/environment pushed new commits mid-cycle and were caught by a second discovery pass before the run closed.

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

New files added by this cycle (across all four merged branches):

- `eldoria-godot/data/codex/vellums_spine.md` (codex .md, from auto/lore) — joins seven existing codex docs under data/codex/, follows the same convention; no loader registration needed.
- `eldoria-godot/assets/audio/sfx/boss_intro.ogg` + `.import` (from auto/audio) — direct format swap of the existing boss_intro reference; ATTRIBUTION.md updated. Replaces the deleted boss_intro.wav pair.

No new `.glb` in assets/, no `data/quests/*.tres`, no AnimationLibrary `.tres`, and no StandardMaterial3D `.tres` were added this cycle, so the four orphan-asset rules produce zero new entries.

auto/character and auto/environment only modified existing scripts.

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
