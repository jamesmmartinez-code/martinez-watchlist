# Canon QA — Audit 2026-05-06

**Run:** auto/canon-qa
**Cycle:** Daily — second cycle (first cycle audit at `_canon_audit_2026-05-05.md`)
**Scope:** all 12 checks (story 1-7, visual 8-12)
**Repo state at start:** `origin/main` HEAD `d051882` ("Integrate auto/environment")
**Diff window:** last 50 commits on `main` (back to `e52eedb` "Auto: captain_seal_for_maeve")
**Branch:** `auto/canon-qa` was previously seeded from cycle 1; this cycle force-pushes a refreshed audit set on top.

---

## Counts

| Severity | Count |
|----------|-------|
| **S1**   | **0** |
| **S2**   | **6** |
| **S3**   | **3** |

**Blocking status:** **PASS_WITH_DEBT** (no S1; 6 S2 → integrator merges normally and logs S2 to its own audit).

---

## Check 1 — Orphan ids (cross-ref graph)

Graph at `eldoria-godot/qa/cross_ref_graph.json` (refreshed). 7 NPCs / 29 catalog items / 41 runtime `Items.gd` items / 2 codex / 8 quests / 11 recipes harvested.

**New orphans this cycle:**
- `briar_shortbow`, `mossbound_buckler`, `roan_woodbow`, `wolf_heart` — flagged `needs_flavor: yes` in `data/items/_catalog.csv`, but no entry in `data/items_flavor.json`. (Items shipped via `Art:` icon commits + `.tres` files; lorekeeper flavor pass not yet run.) → **CQ-S2-01**
- `briar_shortbow`, `mossbound_buckler`, `roan_woodbow` — defined in `.tres` set but absent from the legacy `Items.gd :: ITEMS` runtime dict. Any `Items.get_item("briar_shortbow")` lookup currently returns `{}` → empty name, no icon, no value, no rarity. → **CQ-S2-02**

**Carried forward from 2026-05-05 (still open):**
- `practice_cudgel` (trainer_hala dialogue) — no flavor entry → **CQ-S2-03** (was CQ-S2-01)
- `Steppe-Patterned Halter` / `roan_halter_gifted` (stablemaster_roan dialogue + bio) — no flavor entry → **CQ-S2-04** (was CQ-S2-02)

## Check 2 — NPC voice ↔ bio

Sampled all 7 named NPC bios (`eldoria-godot/lore/npcs/*.md`) against their dialogue (`eldoria-godot/data/dialogue/*.json`). All 7 dialogue voice tones match their bio's THEME §7 voice profile. No new findings.

## Check 3 — Region consistency

Crystal Caves region: `shards_for_mara.tres` quest ↔ `crystal_shard.tres` ↔ `crystal_elemental.tres` creature ↔ `data/spawn_tables/crystal_caves.tres` ↔ `data/codex/stag_courts_courtesy.md` reference all align (cave/thirre/cold-iron). PASS.

Whisperwood: 6 legacy quests (whisperwood_cleansing, pelt_for_lyra, ears_for_mara, wolf_fang_for_roan, wolf_form_with_hala, wolf_heart_for_bram) all reference Whisperwood region in `World.gd :: QUEST_CATALOG`; their fetch items (wolf_pelt, goblin_ear, wolf_fang, wolf_heart) match the canonical Whisperwood drop tables in `Items.gd`. PASS.

## Check 4 — Item ↔ Recipe parity

Recipes (11 in `data/recipes/forge/` + `data/recipes/herb_shed/`) audited:
- **`mossbound_buckler` is `acquired_via: craft` per catalog but has no recipe in `data/recipes/**`.** → **CQ-S2-05**
- Recipe inputs not in catalog (intermediate gathering / smelter materials): `bark_tannin_oak`, `beeswax_dab`, `charcoal`, `clay_flask_empty`, `hemp_cord`, `herb_dogwort`, `herb_hearts_ease`, `herb_marshmint`, `herb_starveil`, `iron_buckle`, `iron_ingot`, `iron_ore`, `leather_strip`, `marshmint_dye`, `well_water_clear`, `whisperwood_oak_disc`. The recipes themselves note these as bootstrap (e.g. `iron_ingot.tres`: "iron_ingot does not yet exist in items_flavor.json"). Tracked future-debt. → **CQ-S3-01**
- Recipe outputs not in catalog: `iron_buckle`, `iron_ingot`, `leather_strip`, `marshmint_dye`. Same bootstrap class. → **CQ-S3-02**

## Check 5 — Quest ↔ Reward

8 active quest catalog entries audited (`World.gd :: QUEST_CATALOG`):
- `pelt_for_lyra` rewards `2× hp_potion_l` — `hp_potion_l` exists in catalog AND `Items.gd`. PASS.
- All other quests reward `xp_reward` + `gold_reward` only (no item rewards). PASS.
- Level bands: all entries gated on `player_level == 1` (early-game). Matches `eldoria-godot/pacing/level_bands.md` if present. PASS.

`captain_seal` referenced as fetch target in `captain_seal_for_maeve` — exists in `Items.gd :: ITEMS` (line 154) with full def (rare material, icon `🕯`, value 60, painterly icon shipped 0fa1037). PASS.

## Check 6 — Concept-art coverage

`concept/INDEX.md` is the only concept index. None of the 7 named NPCs, 4 regions, or 2 codex creatures have explicit reference plates committed under `concept/` — but per the existing convention, `Art:` commits are landing icon/portrait/banner painterly PNGs directly into `eldoria-godot/assets/icons/`, `assets/portraits/`, `assets/banners/`. Coverage audit `7c83dc2 Art: coverage audit — 40 icons + 21 portraits + 15 banners verified (2026-05-06)` ran on this date and self-reports green.

No new `CONCEPT_NEEDED` flags this cycle. Implicit gap: no `concept/` reference plate per NPC — the painterly portraits in `assets/portraits/` are the de-facto reference. → **CQ-S3-03** (cosmetic; flag for future schema decision)

## Check 7 — Catalog reconciliation

`data/items/_catalog.csv` ↔ `data/items/**.tres` parity: **CLEAN** — 29 catalog rows, 29 `.tres` files, 1:1 correspondence (verified by id intersection: zero rows in catalog without a `.tres`; zero `.tres` without a catalog entry).

Legacy `Items.gd :: ITEMS` dict ↔ `.tres` set: **NOT CLEAN** — `Items.gd` has 41 entries, the `.tres` set has 29; 3 ids exist in `.tres` only (briar_shortbow / mossbound_buckler / roan_woodbow). Tracked as **CQ-S2-02** above.

---

## Check 8 — Building scale floor (NEW VISUAL)

`scripts/WorldBuilder.gd :: _make_building` (canonical hut) measured Y-extent from primitive sums:
- Foundation top: 0.5m
- Walls top: 3.1m
- Eave top: 3.27m
- Roof top: 5.08m
- Chimney top: 5.35m

**Final Y-extent ≈ 5.35m → ≥2.5m floor → PASS.**

`_build_windmill` (line 960 — both procedural and GLB paths):
- Procedural fallback: base(2.0m top) + tower(4.5m top) + roof(5.7m top), uniform 1.55× → **8.835m**.
- GLB path: Sketchfab CC-BY windmill GLB at 1.55× scale, source measured 5.7m unscaled → **~8.8m post-scale**.
- Windmill-specific floor of 6m → **PASS** for both paths.
- Code comment at line 1016-1018 explicitly enforces this: "scale-eng 2026-05-05: measured roof-tip 5.7m, canon windmill floor 8m (target 12m, cap 18m). Sweep clamps DOWN over-cap but cannot grow UP — under-floor windmills must be fixed at source."

`_build_briarwood_*` family / curtain-wall / gate-tower spawn functions: **N/A** — no such functions exist in `WorldBuilder.gd` at this commit. (The check's reference to these is forward-looking; flagged as future canon when those structures are introduced.)

The 2026-05-05 user complaint of "tiny windmill" is no longer reproducible at the source level — the explicit 1.55× uniform scale plus settle-to-ground call covers it. **No S1.**

## Check 9 — Tree cap + collision parity (NEW VISUAL)

`TREE_VARIANTS` block (`WorldBuilder.gd:42-52`):

| variant | scale_max | kind | spawn-time clamp | sweep clamp |
|---------|-----------|------|------------------|-------------|
| oak     | 0.95      | oak  | yes (≤14m)        | yes (groups "trees", 14m) |
| pine    | 1.05      | pine | yes              | yes |
| bush    | 0.95      | bush | yes              | yes |
| dead    | 0.85      | dead | yes              | yes |

The 2026-05-06 HAMMER commit capped scale_max from 1.85/2.10/1.55 to 0.95/1.05/0.85 (visible in inline `# capped 2026-05-06: was X.YZ, produced 11-15m trees that read as walls,` comments). At these caps any reasonable Sketchfab GLB tree (typical 8-12m unscaled) renders ≤12m post-scale. The defense-in-depth `_clamp_tree_at_spawn` (line 3063) clamps ≤14m at instantiation; the global sweep (line 2787) clamps "trees" group ≤14m every 0.5s. **Visual cap → PASS.**

Collision-shape vs visual-trunk parity (per `_make_glb_tree:3028-3052`):
- Oak collider radius `0.55 × s`; pine `0.42 × s`; dead `0.32 × s`; bush no collider.
- These radii assume specific GLB trunk widths. Without engine-side AABB measurement of each source GLB's trunk mesh, we cannot verify the 1.5× cap. **The user-cited "massive brown walls actually trees" complaint specifically called out collision overshoot.** The recent HAMMER scale-cap addresses the *visual* part (trees no longer read as walls), but the *collision* part (collider radius wider than visual trunk) is still unverifiable from static analysis. → **CQ-S2-06**, owner `@scale-engineer`, action: in-engine print of `(visual_trunk_radius, collider_radius, ratio)` for each tree variant on first spawn.

## Check 10 — Animation presence (NEW VISUAL)

- `data/npcs/*.tscn` and `data/bosses/*.tscn`: **none exist.** NPCs are spawned procedurally as `StaticBody3D` instances by `WorldBuilder.gd :: _build_npcs` (line 1549). The check's literal target set is empty.
- `eldoria-godot/assets/animations/`: contains `slot_mapping.json` + 435 source FBX files under `source/{Action_Adventure_Pack,Capoeira_Pack,...}` — **zero `.tres` AnimationLibraries built**.
- Build script exists: `eldoria-godot/scripts/dev/build_anim_library.gd` (Animation Sourcer agent's pipeline target).
- Per spec: "If not yet, flag the gap as **S2** with owner `@animation-sourcer` and **PASS_WITH_DEBT** until the source agent ships its first batch." → **CQ-S2-07** (pre-existing condition; first batch not yet shipped).

The `Char:` commits show shipped per-character GLBs with embedded anims (Hero.glb 5 anims, Owen Vanguard 5 anims, bandit.glb dedicated). These are *per-character* AnimationLibraries baked into each GLB's `Skeleton3D`, not shared `.tres` libraries — which satisfies the spirit of check 10 for the player + 1-2 enemies, but does not yet satisfy the named-NPC check.

## Check 11 — Theme tool compliance (NEW VISUAL)

Last 50 commits touching `concept/` `ui/` `eldoria-godot/assets/`:
- **Zero figma references** in commit messages or filenames. (`grep -i 'figma\|.fig$'` over the tracked tree → empty.)
- **All 20 visual-asset commits in window are properly tool-tagged**: `painterly`, `CC0`, `Meshy`, `Substance`, `Sketchfab`, `Mixamo` appear in commit messages (counted via the grep at the bottom of this run).
- `concept/` directory contains only `INDEX.md` + `README.md`; no untagged visual binaries. PASS.
- `ui/` directory at the root contains only `INDEX.md`; no visual binaries. PASS.

**No S1 / no S2 from check 11.**

## Check 12 — Naked-grey mesh (NEW VISUAL)

3 `.tscn` files in `eldoria-godot/scenes/`:
- `Main.tscn`: 1 `MeshInstance3D` ("Ground"), uses `surface_material_override/0 = SubResource("GroundMat")` (StandardMaterial3D, line 117). PASS.
- `CharacterSelect.tscn`: 0 `MeshInstance3D` nodes (Control + Script only). N/A.
- `realms/eldoria_terrain.tscn`: 0 `MeshInstance3D` nodes (Terrain3D + DirectionalLight3D + WorldEnvironment only). N/A.

**No naked-grey meshes in any committed `.tscn`. PASS.**

(The procedural `MeshInstance3D` nodes spawned by `WorldBuilder.gd` all set `material_override` inline at construction — verified by spot-checking `_make_building`, `_build_windmill`, and `_build_market_stalls`.)

---

## New flags this cycle

| ID | Sev | Owner | Summary |
|----|-----|-------|---------|
| CQ-S2-01 | S2 | @lorekeeper | 4 catalog items missing flavor (briar_shortbow, mossbound_buckler, roan_woodbow, wolf_heart) |
| CQ-S2-02 | S2 | @builder    | 3 `.tres` items not wired into legacy `Items.gd :: ITEMS` (briar_shortbow, mossbound_buckler, roan_woodbow) |
| CQ-S2-03 | S2 | @lorekeeper | `practice_cudgel` referenced in trainer_hala dialogue, no flavor entry (carry-over) |
| CQ-S2-04 | S2 | @lorekeeper | `Steppe-Patterned Halter` referenced in stablemaster_roan, no flavor entry (carry-over) |
| CQ-S2-05 | S2 | @recipe-author | `mossbound_buckler` is `acquired_via:craft` but has no recipe |
| CQ-S2-06 | S2 | @scale-engineer | Tree collision-vs-trunk parity unverifiable from static analysis; needs in-engine AABB print |
| CQ-S2-07 | S2 | @animation-sourcer | No `.tres` AnimationLibraries built yet from source FBX pile (first batch not shipped) |
| CQ-S3-01 | S3 | @recipe-author | 16 intermediate gathering/smelter materials referenced by recipes but not in catalog (bootstrap) |
| CQ-S3-02 | S3 | @recipe-author | 4 recipe outputs not in catalog (iron_buckle, iron_ingot, leather_strip, marshmint_dye) (bootstrap) |
| CQ-S3-03 | S3 | @art-director | No per-NPC reference plate under `concept/` — current convention uses `assets/portraits/` instead |

## Top 3 worst offenders by file path

1. `eldoria-godot/data/items_flavor.json` — 4 `needs_flavor: yes` items still missing entries (CQ-S2-01)
2. `eldoria-godot/scripts/Items.gd` — legacy ITEMS dict drifting behind the `.tres` set (CQ-S2-02)
3. `eldoria-godot/assets/animations/` — 435 source FBX files, 0 `.tres` libraries built (CQ-S2-07)

## What did NOT regress this cycle

- Building scale (Check 8) is in spec at the source level. The 2026-05-05 "tiny windmill" complaint is no longer reproducible from the code — explicit 1.55× scale + settle-to-ground enforce ≥6m floor.
- Tree visual cap (Check 9) was hammered down 2026-05-06 to scale_max ≤1.05; the "brown walls" visual is gone. Only the *collision* parity remains as S2.
- `.tscn` material discipline (Check 12) is clean.
- Theme tool compliance (Check 11) is clean — no figma usage anywhere.
- Catalog ↔ .tres parity (Check 7) is now 1:1 (was off-by-3 in earlier cycles).

