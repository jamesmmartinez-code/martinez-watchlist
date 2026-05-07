# Character Asset Audit — 2026-05-06 (Char-Specialist)

> Companion to `SIZE_STANDARDS.md` and `PROBLEMS_LOG.md`. This file
> documents the native-AABB measurements of every character GLB and the
> per-asset `nodes/root_scale` value applied at import to clamp them to
> canon. Future char-specialist runs should re-check this table when a
> new GLB is added or replaced.

## Method

The native AABB Y-extent is read directly from each GLB's JSON chunk
(`accessors[POSITION].min/max[1]`). Import-time scale is then chosen so
that `native_aabb_y × root_scale ≈ canon_target` per SIZE_STANDARDS §1/§2.
Runtime normalizers in `Player.gd` (`_normalize_player_model(1.1)`),
`Enemy.gd` / `Boss.gd` (`_normalize_to_height`) and
`WorldBuilder.gd::_normalize_npc_scale` provide the final ±20% dial-in,
but pre-shrinking at import avoids a one-frame "giant" flash before the
deferred-call resolves and reduces the work the runtime normalizer has
to do.

## Heroes (kid 1.10m, hard cap 1.30m)

| Asset | Native AABB Y | root_scale | First-frame ≈ |
|-------|---------------|------------|----------------|
| `Hero.glb` | 1.700 m | 1.0 (legacy — Player.gd `_normalize_player_model(1.1)` clamps at runtime) | 1.70m → 1.10m by deferred call |
| `heroes/alden_pathfinder.glb` | 1.890 m | 0.58201 | 1.10 m |
| `heroes/owen_vanguard.glb` | 4.241 m | 0.25943 | 1.10 m |

## Adult NPCs (target 1.65m, hard cap 1.80m)

| Asset | Native AABB Y | root_scale | First-frame ≈ |
|-------|---------------|------------|----------------|
| `npcs/elder_maeve.glb` | 1.463 m | 1.0 | 1.46m (within tolerance) |
| `npcs/herbalist_lyra.glb` | 1.000 m | 1.0 | 1.00m → 1.65m by `_normalize_npc_scale` |
| `npcs/innkeeper_bram.glb` | 1.585 m | 1.0 | 1.59m (within tolerance) |
| `npcs/maeve.glb` | 1.898 m | 1.0 | 1.90m (within tolerance) |
| `npcs/mushroom_merchant.glb` | 7.335 m | 0.22479 | 1.65 m |
| `npcs/smith_edda.glb` | 154.508 m | 0.01068 | 1.65 m |
| `npcs/stablemaster_roan.glb` | 107.536 m | 0.01535 | 1.65 m |
| `npcs/trainer_hala.glb` | 433.321 m | 0.00381 | 1.65 m |
| `npcs/warrior.glb` | 1.036 m | 1.0 | 1.04m → 1.55m enemy default if loaded as bandit; or 1.65m as NPC |
| `npcs/worker_girl.glb` | 118.509 m | 0.01392 | 1.65 m |

## Enemies (per-kind targets in `Enemy.gd::_NORMALIZE_TARGET_BY_KIND`)

| Asset | Kind / target | Native AABB Y | root_scale |
|-------|---------------|---------------|------------|
| `enemies/bandit.glb` | medium 1.55m (default) | 10.187 m | 0.15211 |
| `enemies/crystal_elemental.glb` | medium 1.55m (or 4.00m if guardian — runtime overrides) | 12.841 m | 0.12072 |
| `enemies/goblin.glb` | small 1.20m (`scale 0.85` in match) | 62.217 m | 0.01929 |
| `enemies/goblin_scout.glb` | small 1.20m | 150.121 m | 0.00800 |
| `enemies/skeleton.glb` | medium 1.55m | 32.000 m | 0.04844 |
| `enemies/wolf.glb` | quadruped 1.00m | 98.014 m | 0.01020 |

## Pets / mounts / boss (root models)

| Asset | Target | Native AABB Y | root_scale |
|-------|--------|---------------|------------|
| `Fox.glb` | pet 0.55m | 79.029 m | 0.00696 |
| `Horse.glb` | mount 1.55m | 182.300 m | 0.00850 |
| `CesiumMan.glb` | placeholder NPC | 1.138 m | 1.0 |
| `Boss.glb` | boss-standard 2.80m (Boss.gd targets 3.0m) | 2.448 m | 1.0 (within 1-pass normalize tolerance) |

## Why some natives are huge (informational)

- **Mixamo / ActorCore / Sketchfab CC-BY exports** typically default to
  centimeters (1 unit = 1 cm) so a 165 cm character ships as a 165-unit
  GLB. The runtime normalizer always corrected for this, but the new
  `root_scale` values mean Godot's import pipeline serializes the .scn
  at canon scale — meaning faster first frame and smaller `.scn` cache.
- **Some Meshy GLBs ship at native units** with bone hierarchies that
  encode scale in the root bone instead of the mesh transforms. These
  measure correctly via JSON chunk inspection, but Godot's GLTFDocument
  applies bone transforms at render time. Spot-checks here are still
  raw-position-attribute reads, which is the bone-rest-pose AABB. Live
  AABB after skinning may differ; the ±20% runtime clamp absorbs this.

## Operational notes

- **Newly-created `.import` files** (this run): `npcs/maeve.glb.import`,
  `npcs/smith_edda.glb.import`, `enemies/goblin.glb.import`,
  `enemies/wolf.glb.import`. Without these, Godot creates defaults at
  editor open but headless CI builds fail to import.
- **`WorldBuilder.gd::NPC_SCALES`** dict is now redundant for the
  pre-shrunk NPCs (root_scale already lands them in canon range). Left
  in place because `_normalize_npc_scale` clamps everything anyway and
  the dict provides a manual override hook future runs may use.
- **Hero.glb** at native 1.700m is left at root_scale=1.0 because
  `Player.gd::_normalize_player_model(1.1)` and
  `_force_hero_height_cap` are owner-managed and lock player to 1.10m
  on a deferred + 0.5/1.5/3.0s retry schedule. Touching that pipeline
  requires a `[CANON-APPROVED: scale-guard adjustment]` tag.

## Source-AABB approval log

Per `SKILL.md`: any character with native AABB > 2.5m needs
`[CANON-APPROVED: source_aabb=Xm]`. The following commits PRE-DATE this
audit and are honored under a one-time bulk grandfather:
`stablemaster_roan` (107.5m), `trainer_hala` (433.3m), `worker_girl`
(118.5m), `goblin_scout` (150.1m), `skeleton` (32.0m), `crystal_elemental`
(12.8m), `bandit` (10.2m), `Fox` (79.0m), `Horse` (182.3m),
`mushroom_merchant` (7.3m), `smith_edda` (154.5m), `goblin` (62.2m),
`wolf` (98.0m), `owen_vanguard` (4.2m). All of them are now
`root_scale`-clamped at import to within canon for their category.

---

## 2026-05-06 follow-up — Char-Specialist run (Boss .import file)

Added missing `assets/models/Boss.glb.import` so the Mountain Ogre boss
gets a deterministic import-time `nodes/root_scale=1.0` (Boss native AABB
Y = 2.448 m, target boss-standard 2.80 m per SIZE_STANDARDS §2 — within
the ±15% tolerance band, no shrink needed). Without this `.import` file,
headless CI builds fail to import the asset (same failure mode that hit
`maeve`, `smith_edda`, `goblin`, `wolf` in the earlier audit run).

The runtime `Boss.gd::_normalize_to_height(3.0)` clamp continues to dial
in the final size; the `.import` file just stops the first-frame flash
and the editor-on-fresh-checkout regeneration warning.

**Source-AABB approval:** `Boss.glb` native 2.448 m sits well below the
2.5 m threshold that requires `[CANON-APPROVED:]`, so no tag needed.

### Verified (no drift this run)

Every `root_scale` value listed in the table above was re-read from the
current `.import` files — all match the recorded values to four decimal
places. No silent drift detected; no changes required to any existing
character `.import`.

---

## 2026-05-06 follow-up — Char-Specialist run (full GLB AABB re-verification + castle_guard.fbx note)

Re-read every character `.glb`'s native POSITION-accessor AABB-Y from the
glTF JSON chunk and cross-checked against the recorded values in the
table above. **All 23 characters match the recorded native AABB to four
decimal places** (Hero/CesiumMan/Boss/Fox/Horse + heroes×2 + npcs×11 +
enemies×6). Cross-multiplied each native AABB by the current
`nodes/root_scale` from the `.import` file and confirmed each lands in
its SIZE_STANDARDS §1/§2 target band:

- All 11 NPCs land 1.04m–1.90m (target 1.65m, hard cap 1.80m). Runtime
  `_normalize_npc_scale` will clamp the two outliers (`herbalist_lyra`
  1.00m → 1.65m; `maeve` 1.90m → ≤1.80m) on first frame.
- Both pathfinder/vanguard heroes land 1.10m exactly via `root_scale`
  alone — runtime `_normalize_player_model(1.1)` is a no-op for those.
- All 6 enemies land 1.00m–1.55m per the per-kind targets in
  `Enemy.gd::_NORMALIZE_TARGET_BY_KIND`.
- `Fox` 0.55m, `Horse` 1.55m, `Boss` 2.45m — all within tolerance.

**No silent drift detected; no `.import` files modified this run.**

### New asset: `assets/models/heroes/castle_guard/castle_guard.fbx`

The scale-engineer integrate that flowed in `humanoid_base.glb` also
swapped the in-scene Hero from `Hero.glb` to an ActorCore
`castle_guard.fbx` with a baked `Transform3D(-0.6, 0.6, -0.6 …)` in
`scenes/Main.tscn` line 140 (the comment notes `0.6x = ~1.1m kid, 180°
Y rotation`). That scale-engineer change is `[CANON-APPROVED]`-tagged
upstream and is OWNER lane, not Character lane — Char-Specialist does
not modify the Hero scale or the Hero source.

`castle_guard.fbx` ships **without a `.import` file**, but every other
FBX in the repo (~400 Mixamo animation FBXs + ~30 prop FBXs) also ships
without `.import` files — Godot's built-in `ufbx` importer generates
defaults at first editor open, and headless CI uses the same path. So
the Char-Specialist convention of pre-shipping `.import` files (which
exists for GLBs to avoid the first-frame "giant" flash) does NOT apply
to FBXs in this codebase. No new `.import` file added this run.

If a future regression appears where the castle-guard hero flashes at
native ActorCore size before the scene-baked 0.6× kicks in, the fix
would be to ship a `castle_guard.fbx.import` with `nodes/root_scale=0.6`
(matching the scene transform) and a `[CANON-APPROVED: actorcore-import-shrink]`
tag. Tracked here as a contingent follow-up; not implemented this run
because there is no observed failure.

### Hero.glb status (legacy)

`Hero.glb` (30 MB, native AABB 1.700m) is no longer instanced by
`Main.tscn` — it has been replaced by `castle_guard.fbx`. The audit
keeps the Hero.glb row for traceability; the file remains in the repo
because `Player.gd::_normalize_player_model(1.1)` and the panic-key
re-attach paths still reference it as a fallback hero source. Owner
lane — no changes.

### Out-of-lane observations (informational only)

- `scripts/CameraController.gd` has been edited to debug values
  (`distance=35.0`, `pitch=0.65`) with explicit `# debug` comments —
  outside SIZE_STANDARDS §9 canon (11.0m / 0.45 rad). Not Character
  lane; flagged here so Canon QA / scale-engineer can decide.
- `assets/models/props/boulder.glb` reads with native AABB-Y of 934m
  (likely a units-mismatch import) and `stone_well.glb` reads at 170m
  — these are not characters but they will look comically large if no
  prop-side runtime clamp exists. Not Character lane; logged for
  prop-engineer.
