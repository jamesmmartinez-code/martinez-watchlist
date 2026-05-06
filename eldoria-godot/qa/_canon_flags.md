# Canon QA — Flag queue

Per-issue queue. New flags raised this cycle are at the top; carry-overs are in their original section.

Last updated: 2026-05-06 (cycle 2)

---

## OPEN — S2

### CQ-S2-01 — items_flavor.json missing 4 entries flagged `needs_flavor: yes`
- **Owner:** @lorekeeper
- **First raised:** 2026-05-06
- **Status:** OPEN
- **Files:** `eldoria-godot/data/items_flavor.json`, `eldoria-godot/data/items/_catalog.csv`
- **Detail:** Catalog flags `briar_shortbow`, `mossbound_buckler`, `roan_woodbow`, `wolf_heart` as `needs_flavor: yes`. None present in `items_flavor.json :: items`. New `Art:` icon commits landed without lore.
- **Acceptance:** Add 4 entries (one per id) following the same shape as the existing 25 items_flavor entries. Each entry should reference the THEME §7 voice for the relevant NPC (e.g. roan_woodbow is Roan's gift item, briar_shortbow is briarwood-region, mossbound_buckler ties to Whisperwood, wolf_heart ties to Bram's vigil).

### CQ-S2-02 — Items.gd ITEMS dict missing 3 .tres-defined items
- **Owner:** @builder
- **First raised:** 2026-05-06
- **Status:** OPEN
- **Files:** `eldoria-godot/scripts/Items.gd` (line 17, `const ITEMS`)
- **Detail:** `briar_shortbow`, `mossbound_buckler`, `roan_woodbow` defined as `.tres` files but absent from the legacy ITEMS dict. Runtime `Items.get_item("briar_shortbow")` returns `{}` → empty name/icon/value/rarity in any UI that calls it.
- **Acceptance:** Add 3 entries to ITEMS, OR migrate `Items.get_item` to read from the `.tres` set directly. Pick whichever the engine roadmap prefers (the catalog migration plan in `data/items/README.md` may have an opinion).

### CQ-S2-03 — practice_cudgel referenced but undefined (carry-over)
- **Owner:** @lorekeeper
- **First raised:** 2026-05-05 (was CQ-S2-01)
- **Status:** OPEN
- **Files:** `eldoria-godot/data/dialogue/trainer_hala.json`
- **Detail:** Trainer Hala's `after_first_quest_complete` reward references `practice_cudgel`. No entry in `items_flavor.json` and no `.tres` file in `data/items/weapons/`.
- **Acceptance:** Either author the item (catalog row + `.tres` + flavor entry + runtime entry) OR remove the reference from Hala's dialogue.

### CQ-S2-04 — Steppe-Patterned Halter (roan_halter_gifted) undefined (carry-over)
- **Owner:** @lorekeeper
- **First raised:** 2026-05-05 (was CQ-S2-02)
- **Status:** OPEN
- **Files:** `eldoria-godot/data/dialogue/stablemaster_roan.json`, `eldoria-godot/lore/npcs/stablemaster_roan.md`
- **Detail:** Roan gifts a "Steppe-Patterned Halter" (sets `roan_halter_gifted` flag). No item entry anywhere.
- **Acceptance:** As CQ-S2-03.

### CQ-S2-05 — mossbound_buckler is `acquired_via:craft` with no recipe
- **Owner:** @recipe-author
- **First raised:** 2026-05-06
- **Status:** OPEN
- **Files:** `eldoria-godot/data/items/armor/mossbound_buckler.tres`, `eldoria-godot/data/recipes/**`
- **Detail:** Catalog row says craft, but no recipe outputs `mossbound_buckler`. The Whisperwood theme suggests this should live under `data/recipes/herb_shed/` (Lyra's wood-craft) or a new `data/recipes/wood_shed/` station.
- **Acceptance:** Author one recipe `.tres` whose `metadata/output.item_id == "mossbound_buckler"`. Inputs likely include `whisperwood_oak_disc` (already referenced by `oak_talisman.tres`) and `hemp_cord` for the strap.

### CQ-S2-06 — Tree collision parity unverifiable from static source
- **Owner:** @scale-engineer
- **First raised:** 2026-05-06
- **Status:** OPEN
- **Files:** `eldoria-godot/scripts/WorldBuilder.gd:3028-3052`
- **Detail:** `_make_glb_tree` builds a `CapsuleShape3D` collision body whose radius is `0.55 × s` (oak), `0.42 × s` (pine), or `0.32 × s` (dead). These constants assume specific GLB trunk widths that aren't measured at spawn. The user's 2026-05-05 complaint of "massive brown walls I can't get through that are actually trees" specifically called out collision overshoot. The 2026-05-06 HAMMER scale-cap addresses the *visual* part; the collision part is still unverified from static analysis.
- **Acceptance:** In `_make_glb_tree` after the GLB is instantiated, walk the tree's `Skeleton3D`/`MeshInstance3D` set, find the trunk mesh by name match (`trunk`, `bark`, …) or AABB-X-min-extent, measure its visual radius, and either (a) print `[TreeColl] kind=%s s=%.2f visual_r=%.2f coll_r=%.2f ratio=%.2f` so canon-qa can ingest the numbers, or (b) directly clamp `radius = min(0.55*s, visual_r * 1.5)`.

### CQ-S2-07 — No .tres AnimationLibraries built yet (Animation Sourcer pending)
- **Owner:** @animation-sourcer
- **First raised:** 2026-05-06 (pre-existing pre-condition; flagged this cycle for visibility)
- **Status:** OPEN
- **Files:** `eldoria-godot/assets/animations/source/**` (435 FBX), `eldoria-godot/scripts/dev/build_anim_library.gd`
- **Detail:** The first batch of `.tres` AnimationLibraries built from the source FBX pile has not yet shipped. Per spec this is **PASS_WITH_DEBT**, not BLOCK.
- **Acceptance:** Ship at least one `eldoria-godot/assets/animations/<set>.tres` AnimationLibrary covering `idle / walk / attack` for the named-NPC humanoid skeleton, plus a wiring example showing how `WorldBuilder._build_npcs` would attach it to a procedural NPC body.

---

## OPEN — S3

### CQ-S3-01 — 16 intermediate gathering/smelter materials referenced by recipes but not in catalog
- **Owner:** @recipe-author
- **First raised:** 2026-05-06
- **Detail:** `bark_tannin_oak`, `beeswax_dab`, `charcoal`, `clay_flask_empty`, `hemp_cord`, `herb_dogwort`, `herb_hearts_ease`, `herb_marshmint`, `herb_starveil`, `iron_buckle`, `iron_ingot`, `iron_ore`, `leather_strip`, `marshmint_dye`, `well_water_clear`, `whisperwood_oak_disc`. Recipes self-document this as bootstrap.
- **Acceptance:** When the materials catalog migration runs, add stub catalog rows for each. No urgent action.

### CQ-S3-02 — 4 recipe outputs not in catalog (bootstrap intermediates)
- **Owner:** @recipe-author
- **First raised:** 2026-05-06
- **Detail:** `iron_buckle`, `iron_ingot`, `leather_strip`, `marshmint_dye` are recipe outputs but not catalog items.
- **Acceptance:** Same migration pass as CQ-S3-01.

### CQ-S3-03 — No per-NPC reference plate in concept/
- **Owner:** @art-director
- **First raised:** 2026-05-06
- **Detail:** Convention currently uses `assets/portraits/<npc>.png` instead of `concept/<npc>.png` reference plates. The check 6 spec says "named NPC has reference plate OR `CONCEPT_NEEDED` flag". Painterly portraits cover the spirit of this; the schema decision is whether to formalize that or add a parallel concept folder.
- **Acceptance:** Document the convention in `concept/README.md`, OR add explicit reference plates.

---

## RESOLVED THIS CYCLE

(none — first cycle was 2026-05-05; all 2026-05-05 flags are still open since the work hasn't been done. No regressions to resolve.)

---

## RESOLVED PRIOR CYCLES

(none yet — only one prior cycle; nothing has been closed.)

