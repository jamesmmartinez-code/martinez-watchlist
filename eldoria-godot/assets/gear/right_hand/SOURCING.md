# right_hand — Sourcing Backlog

Owned by: **Equipment Visualizer**.
Items in this slot: weapons (swords, axes, daggers, bows, staves).

Until a `<item_id>.glb` ships here, `Player.gd` falls back to a procedural primitive built from BoxMesh / CylinderMesh / SphereMesh shapes (legacy stop-gap — flagged in THEME.md "replace with authored GLBs ASAP").

## Items still needing a GLB

| Item id        | Tier      | Shape hint     | Sourcing prompt / search                                           |
| -------------- | --------- | -------------- | ------------------------------------------------------------------ |
| rusty_sword    | common    | shortsword     | Sketchfab: `rusty sword low poly cc-by`. Meshy: see prompt below.  |
| iron_sword     | common    | sword          | Sketchfab: `iron sword fantasy low poly cc-by`. Meshy template.    |
| steel_blade    | uncommon  | sword          | Tier-tint of iron_sword OR new mesh.                               |
| frost_saber    | rare      | curved saber   | Sketchfab: `scimitar saber low poly cc-by` + cyan tint at runtime. |
| ember_axe      | rare      | axe            | Sketchfab: `viking axe low poly cc-by`.                            |
| shadow_dagger  | epic      | dagger         | Sketchfab: `assassin dagger low poly cc-by` + dark purple tint.    |
| dragonfang     | legendary | 2H greatsword  | Sketchfab: `dragon greatsword low poly cc-by` + ember glow.        |

## Meshy text-to-3D prompt template

```
high-fantasy <weapon kind>, painterly low-poly, hand-painted gouache textures,
aged metal/leather, sunset-warm color palette (orange/crimson/moss),
Studio Ghibli + WoW Classic art style. Single object, neutral pose with
grip at world origin, blade pointing along +Y. NO modern, NO sci-fi,
NO photoreal, NO anime, NO chibi, max 8000 polygons, max 2 MiB output.
```

## Pose / rigging contract

- Origin = grip (palm contact point).
- Blade points along bone-local **+Y** (up out of palm). Player.gd applies a
  90° X rotation when parenting under `RightHandWeaponAttach` so the blade
  reads as forward-pointing in world space.
- One mesh root, no embedded skeleton.
- File MUST be < 5 MiB (preferably < 2 MiB) — OPERATIONS §15.
