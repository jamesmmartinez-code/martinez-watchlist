# Realm of Eldoria — Size Standards (CANON, LOCKED)

> **Status:** LOCKED. Any agent commit that modifies these values without
> a `[CANON-APPROVED: <reason>]` tag in the commit message is auto-rejected
> by Canon QA. Player sees the world through the lens of this file. Get it
> wrong, the world feels wrong.

All measurements are **visible AABB height in meters** unless otherwise specified.
Authority: this file. If a script disagrees, the script is wrong — fix the script.

Last canonical update: **2026-05-06** — kid-sized player (1.10m), aggressive
foreground caps, per-realm scale specifications added.

---

## §1 — Characters (the most-violated category)

| Category               | Target | Tolerance | Hard cap | Notes |
|------------------------|--------|-----------|----------|-------|
| **Player (kid)**       | 1.10m  | ±5%       | 1.30m    | **Alden (9) and Owen (11) are children, NOT adults.** Locked at 1.10m. |
| **Adult NPC**          | 1.65m  | ±10%      | 1.80m    | Maeve, Edda, Bram, Mara, Roan, Hala, Lyra. Visibly taller than player. |
| **Youth NPC**          | 1.30m  | ±10%      | 1.45m    | Apprentices, child villagers. Slightly taller than player. |
| **Pet companion**      | 0.55m  | ±15%      | 0.70m    | Fox, squirrel, owl. Below knee-height of player. |
| **Mount — horse**      | 1.55m  | ±10%      | 1.75m    | Measured at withers. Tall, but kid-rideable. |
| **Mount — dragon**     | 2.40m  | ±15%      | 2.80m    | Riding-size, not boss-size. |

## §2 — Enemies

| Category               | Target | Tolerance | Hard cap |
|------------------------|--------|-----------|----------|
| **Critter (rat, bird)**| 0.30m  | ±25%      | 0.50m    |
| **Small enemy**        | 1.20m  | ±15%      | 1.40m    |
| **Medium enemy**       | 1.55m  | ±15%      | 1.80m    |
| **Elite enemy**        | 2.30m  | ±15%      | 2.60m    |
| **Boss — standard**    | 2.80m  | ±15%      | 3.40m    |
| **Boss — gargantuan**  | 4.00m  | ±15%      | 5.00m    | Crystal Guardian, Mountain Ogre, end-realm boss only. |

## §3 — Buildings (Briarwood + every settlement)

| Category               | Target | Hard floor | Hard cap |
|------------------------|--------|------------|----------|
| **Hut (1-room)**       | 3.20m  | 2.50m      | 4.00m    |
| **House (2-story)**    | 5.50m  | 4.00m      | 7.00m    |
| **Tavern / smithy**    | 6.50m  | 5.00m      | 8.00m    |
| **Temple / hall**      | 8.50m  | 6.50m      | 10.0m    |
| **Tower / windmill**   | 12.0m  | 8.00m      | 14.0m    |
| **Curtain wall**       | 6.00m  | 5.00m      | 8.00m    |
| **Gate tower**         | 12.0m  | 10.0m      | 15.0m    |

## §4 — Trees & vegetation (FOREGROUND, kept short)

| Category               | Target | Hard cap |
|------------------------|--------|----------|
| **Grass tuft / fern**  | 0.30m  | 0.60m    |
| **Bush**               | 0.80m  | 1.20m    |
| **Sapling**            | 1.50m  | 2.00m    |
| **Small tree (oak)**   | 3.00m  | 4.00m    |
| **Tall tree (pine)**   | 4.00m  | 4.50m    |
| **Dead tree**          | 3.50m  | 4.50m    |
| **Ancient/landmark**   | 6.00m  | 8.00m    | One per region max — story marker only. |

**Why low:** at the camera default (16m back, 26° pitch) trees fill the frame
quickly. Foreground caps kept aggressive so the village/NPCs aren't blocked.

## §5 — Props

| Category               | Target | Hard cap | Examples |
|------------------------|--------|----------|----------|
| **Tiny**               | 0.30m  | 0.50m    | Mushroom, candle, gem |
| **Small**              | 0.80m  | 1.20m    | Barrel, chest, stool, log |
| **Medium**             | 1.60m  | 2.20m    | Well, market stall, cart |
| **Large**              | 3.50m  | 5.00m    | Forge, statue, large bell |
| **Landmark**           | 8.00m  | 12.0m    | Briarwood bell tower, monument |

## §6 — Terrain features (per-realm world geometry)

| Category               | Target | Hard cap | Notes |
|------------------------|--------|----------|-------|
| **Hill (gentle)**      | 6.00m  | 12.0m    | Briarwood plateau, Whisperwood undulation |
| **Cliff (small)**      | 8.00m  | 15.0m    | Tidesong shore, cave entrance |
| **Cliff (large)**      | 25.0m  | 40.0m    | Crystal Caves entrance, Ashenmere ridge |
| **Mountain (mid)**     | 60.0m  | 90.0m    | Skyreave foothills |
| **Mountain (peak)**    | 120m   | 180m     | Skyreave summit, end-realm landmark |

**Mountain ring rule:** the surrounding-the-village mountain ring is a SKYBOX
substitute, must sit at 200m+ from village center, never closer than 150m.

## §7 — World-space dimensions per realm

| Realm                  | Plaza dia. | Walkable radius | Mountain horizon | Notes |
|------------------------|------------|-----------------|------------------|-------|
| **Eldoria (Lv 1-50)**  | 50m        | 250m            | 350m             | Briarwood + Whisperwood + Crystal Caves |
| **Ashenmere (50-100)** | 60m        | 350m            | 450m             | Volcanic plain |
| **Tidesong (100-150)** | 70m        | 500m            | open ocean       | Coast + sea drake roost |
| **Shadewood (150-200)**| 40m        | 300m            | 400m             | Dense fey forest, smaller plazas |
| **Skyreave (200-250)** | 80m        | 400m            | 500m             | Dragon caves, large open vistas |
| **Hollow (250-300)**   | 100m       | 600m            | infinite         | Endgame, deliberately vast and lonely |

## §8 — Path & road widths

| Category               | Width  | Notes |
|------------------------|--------|-------|
| **Footpath**           | 1.20m  | Single-file kid passage |
| **Cobble path**        | 2.40m  | Two kids side-by-side |
| **Main road**          | 4.00m  | Cart-wide |
| **Plaza margin**       | 1.00m  | Buffer between props and walkways |

## §9 — Camera defaults (locked unless [CANON-APPROVED] tag)

| Property               | Value  | Notes |
|------------------------|--------|-------|
| **Distance — default** | 11.0m  | |
| **Distance — min**     | 3.4m   | |
| **Distance — max**     | 35.0m  | |
| **Pitch — default**    | 0.45 rad (~26°) | Comfortable 3rd-person, NOT isometric |
| **Pitch — clamp**      | 0.20 to 1.30 rad | |
| **Scroll step**        | 1.5m   | |

## §10 — Particle effect size limits (when re-enabled)

| Effect                 | Particle size | Emission spread | Notes |
|------------------------|---------------|-----------------|-------|
| **Firefly**            | 0.04 m²       | 6m box          | Glow, not chunky |
| **Falling leaf**       | 0.10 m²       | 8m box          | Must use a real leaf texture, not white quad |
| **Smoke chimney**      | 0.50 m² → 1.5m² over lifetime | spawns AT chimney top, never ground | Texture: real smoke, not white |
| **Magic spark**        | 0.06 m²       | 1m              | Bright but small |

**Currently disabled** (rendering as oversized white blobs, see commit `efd0d61b`).
Re-enable only after textures are wired and sizes audited.

---

## §99 — How agents must use this file

1. **Before changing any scale value in any script**, check this file. If your
   intended value violates the canon, write a `[CANON-APPROVED: <reason>]` tag
   in your commit message OR don't make the change.
2. **Canon QA enforces this file.** Any commit that introduces a value outside
   the canon ranges is flagged S1 (block) unless [CANON-APPROVED:] is present.
3. **Don't bake scale into `.tscn` transforms.** Use `WorldBuilder.NPC_SCALES`
   or per-class targets. The runtime `_global_scale_sweep` is authoritative.
4. **One scale source per category.** If you find duplicate scale tables in
   different scripts, consolidate them and reference this file.
5. **Add new categories here first**, then in code. If you spawn something
   that doesn't fit any category, document it here as a new row before
   shipping.

## §100 — Recently observed violations (audit log)

- 2026-05-06: trees rendered at 14m+ visual height — capped to 4.5m at runtime
- 2026-05-06: player normalized to 1.80m (adult) — locked to 1.10m (kid)
- 2026-05-06: equipment (boots, helmets) rendered at native GLB scale instead
  of inheriting player scale — fixed via SCALE GUARD on BoneAttachment3D
- 2026-05-06: white-blob particle effects (smoke/leaves/fireflies) blocking
  entire view — temporarily disabled until textures audited

- 2026-05-06: campfire emission_energy_multiplier=6.0 + no soft texture rendered as
  solid bright orange rectangles. Fixed in commit `e69aaca9`. Pattern: ALL
  GPUParticles3D quads must use `_make_soft_particle_texture()` for albedo.
- 2026-05-06: spawn Y=3 + 4m raycast couldn't find ground when player landed
  in a terrain dip → fell forever. Bumped Y=5, raycast=50m, added Y<-2 rescue.
- 2026-05-06: Worker cache-control was 5min for everything. Deployed
  v1.3.0-cache: HTML 60s, JS 1h, WASM/PCK 24h+swr 7d. Repeat-load 12s→2-3s.

- 2026-05-06: Crystal Guardian rendered ~1.55m (medium enemy) instead of canon
  4.00m (gargantuan boss, §2). The deferred normalize was silently cancelling
  the per-kind 1.55× scale multiplier in Enemy.gd. Fixed by adding per-kind
  normalize targets (`_NORMALIZE_TARGET_BY_KIND`) and a new `gargantuan_bosses`
  SIZE_STANDARDS group at 4.00m. crystal_guardian now joins that group on
  spawn so the WorldBuilder global scale sweep keeps it at 4.00m.
- 2026-05-06: bandit_captain visible at ~1.55m even with 1.40× multiplier
  (same deferred-normalize cancellation). Now per-kind targets 2.30m
  (SIZE_STANDARDS §2 elite-enemy band) so the captain reads as a real
  mini-boss rather than a slightly bigger bandit.

Add a new row here whenever a scale fix lands. Helps detect recurring drift.
