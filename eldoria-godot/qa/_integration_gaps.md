# Integration Gaps Log

last_run: 2026-05-06T18:04Z
canon_qa_status_at_run: PASS_WITH_DEBT (s1=0, s2=7, s3=3 — see eldoria-godot/qa/_blocking_status.md)
merged_this_cycle: auto/environment (1), auto/art (1), auto/lore (1)
skipped_this_cycle: (none)
push_result: 1d8d8ca

## This cycle merged

- auto/environment — 1 commit ahead. Server-side merge.
- auto/art — Two hero portrait PNGs (alden_pathfinder, owen_vanguard), HEROES_ATTRIBUTION.md, plus scripts/art/gen_hero_portraits.py generator.
- auto/lore — New codex entry data/codex/brigids_ribbon.md.

Other auto/* branches (auto/builder, auto/polisher, auto/scale, auto/character, auto/audio, auto/qa, auto/scale-floorfix) were behind main with 0 commits ahead — fast-forwarded only via Step 3 reset for the three merged branches.

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

Files added by this cycle (3 merged branches):

- `eldoria-godot/assets/portraits/alden_pathfinder.png` (from auto/art) — UI portrait companion to existing hero GLB.
- `eldoria-godot/assets/portraits/owen_vanguard.png` (from auto/art) — UI portrait companion to existing hero GLB.
- `eldoria-godot/assets/portraits/HEROES_ATTRIBUTION.md` (from auto/art) — attribution metadata.
- `eldoria-godot/data/codex/brigids_ribbon.md` (from auto/lore) — joins existing codex docs under data/codex/, follows same convention; no loader registration needed.
- `scripts/art/gen_hero_portraits.py` (from auto/art) — generator script, build-time only.

No new `.glb` in `assets/`, no `data/quests/*.tres`, no AnimationLibrary `.tres`, and no StandardMaterial3D `.tres` were added this cycle, so the four orphan-asset rules produce zero new entries.

### [GAP: orphan asset] — hero/enemy GLBs lacking spawn references in WorldBuilder.gd (carry-over)

- eldoria-godot/assets/models/Fox.glb — no spawn reference (likely glTF sample, false positive)
- eldoria-godot/assets/models/Hero.glb — no spawn reference (likely glTF sample, false positive)
- eldoria-godot/assets/models/enemies/goblin_scout.glb — no spawn reference [@character / @builder]
- eldoria-godot/assets/models/heroes/alden_pathfinder.glb — no spawn reference [@character / @builder]  *(portrait now shipped by auto/art this cycle — visual side advancing, spawn side still pending)*
- eldoria-godot/assets/models/heroes/owen_vanguard.glb — no spawn reference [@character / @builder]  *(portrait now shipped by auto/art this cycle — visual side advancing, spawn side still pending)*

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
