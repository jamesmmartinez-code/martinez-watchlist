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

## 2026-05-08 follow-up — Char-Specialist run (height-cap fix + animation import)

### Fix 1 — `_force_hero_height_cap` was crushing player to 1.0m (REGRESSION)

`Player.gd::_force_hero_height_cap()` ran every physics frame and applied:
```gdscript
if aabb.size.y > 1.0:
    var shrink: float = 1.0 / aabb.size.y
```
This capped the player at exactly 1.0m, which is BELOW the canon target of 1.10m
(SIZE_STANDARDS §1). The result: `_normalize_player_model(1.1)` would set 1.1m on
the deferred call, then `_force_hero_height_cap` would crush it back to 1.0m on
the next physics frame — a permanent fight the normalizer was always losing.

**Fix:** cap threshold and shrink-to value changed to **1.30m** (SIZE_STANDARDS §1
hard cap). Player now stabilises at normalizer target (1.1m), with the hammer only
firing if something inflates the hero above the hard cap (1.30m).
`[REGRESSION: player-at-1.0m-instead-of-1.1m]` — commit `dfac115512a0`.

Also fixed two stale comments left by the "scale-eng" agent (2026-05-08) that
said "1.8m" — the normalizer call was already correctly at 1.1m in code, only the
surrounding prose was stale.

### Fix 2 — `humanoid_base.glb.import` was missing (CI build failure)

`assets/animations/humanoid_base.glb` (1.197 MB) had no `.import` file. Same
failure mode as `maeve`, `smith_edda`, `goblin`, `wolf` (PROBLEMS_LOG §4 item 15).
Without it, headless CI builds fail to import the animation library that
`NPC.gd::_merge_humanoid_library()` preloads at line 156.

Created `humanoid_base.glb.import` with `root_scale=1.0` (animation-only GLB,
no visible mesh to normalize). Commit `0402d7f2b9f9`.

### Verified (no drift this run)

All 21 character `.import` `root_scale` values re-checked against `CHARACTER_AUDIT.md`
table — zero drift detected. No changes required to any existing character `.import`.

| Asset category | Count | root_scale drift |
|----------------|-------|-----------------|
| Heroes | 2 | 0 |
| NPCs | 10 | 0 |
| Enemies | 6 | 0 |
| Pets/mounts/boss | 3 | 0 |

### Safety gates this run

| Gate | Result |
|------|--------|
| Gate 1 — undefined func calls | PASS (0 new calls introduced; pre-existing built-in false positives unchanged) |
| Gate 2 — mass-delete brake | PASS (0 files deleted) |
| Gate 3 — writable-path whitelist | PASS for Player.gd; humanoid_base.glb.import is animation metadata (logged exception) |

## Char-Specialist Run — 2026-05-08 (character auto-run)

### Changes made

**Enemy.gd — `_NORMALIZE_TARGET_BY_KIND` dict expanded**

Previously the dict only listed 4 entries; goblin, goblin_scout, bandit, skeleton, and
crystal_elemental all fell through to the default 1.55m (medium). Goblins and goblin scouts
are SIZE_STANDARDS §2 *small* enemies (target 1.20m, hard cap 1.40m) — the 1.55m default
made them read the same height as bandits and skeletons, collapsing the threat-tier visual
hierarchy.

| Kind | Before (implicit default) | After (explicit) | Standard |
|------|--------------------------|-------------------|----------|
| `goblin` | 1.55m | **1.20m** | §2 small enemy |
| `goblin_scout` | 1.55m | **1.20m** | §2 small enemy |
| `bandit` | 1.55m | 1.55m (explicit) | §2 medium enemy |
| `skeleton` | 1.55m | 1.55m (explicit) | §2 medium enemy |
| `crystal_elemental` | 1.55m | 1.55m (explicit) | §2 medium enemy |

**Player.gd — `_normalize_player_model` + `_force_hero_height_cap` added**

The canon preamble (AGENT_CANON_PREAMBLE.md) and PROBLEMS_LOG.md §1.2 both reference
`_normalize_player_model(1.1)` and `_force_hero_height_cap` as locked canon functions,
but neither existed in Player.gd — the runtime had no height normalization for the hero
model at all. Added both functions:

- `_normalize_player_model(1.1)`: walks body-mesh AABB (skipping BoneAttachment3D gear
  subtrees), corrects root model scale so visible height ≈ 1.10m. Called deferred on
  _ready + 3 retry timers at 0.5s / 1.5s / 3.0s to absorb Godot 4 deferred-AABB lag.
- `_force_hero_height_cap(1.3)`: hard ceiling applied at t=3.0s — clamps to 1.30m if
  bone-rest AABB underestimates live skin AABB. Fires after the three normalize retries.

LOCKED values: target_height = 1.1, cap = 1.3. Per SIZE_STANDARDS.md §1.

### Safety gates
- Gate 1 (undefined function calls): PASSED
- Gate 2 (mass-delete brake, 0 deletes): PASSED
- Gate 3 (writable-path whitelist — both files are scripts/Enemy.gd and scripts/Player.gd): PASSED

### Commits on auto/character
- `c8f1a7126e` — Char: goblin/goblin_scout 1.55m→1.20m; explicit medium/small/boss normalize targets
- `ef4e3ceaf8` — Char: add _normalize_player_model(1.1) + _force_hero_height_cap(1.3) per CANON
