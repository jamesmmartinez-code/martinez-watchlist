# left_hand — Sourcing Backlog

Owned by: **Equipment Visualizer**.
Items in this slot: shields, off-hand daggers, focus orbs.

## Items still needing a GLB

| Item id        | Tier      | Shape hint     | Sourcing                                                     |
| -------------- | --------- | -------------- | ------------------------------------------------------------ |
| wooden_shield  | common    | round buckler  | Sketchfab: `wooden round shield low poly cc-by`.             |
| iron_shield    | uncommon  | kite shield    | Sketchfab: `iron kite shield low poly cc-by`.                |
| kite_shield    | rare      | kite shield    | Tier-tint of iron_shield OR new mesh.                        |
| runed_shield   | epic      | rune-etched    | Meshy with rune-etching prompt + emissive glow at runtime.   |

## Meshy prompt template

```
high-fantasy <shield kind>, painterly low-poly, hand-painted gouache,
worn iron banding and leather grip, sunset-warm palette. Studio Ghibli +
WoW Classic art style. Single object, grip-side facing -X, viewer-facing
side facing +X. NO modern, NO sci-fi, max 6000 polygons, max 2 MiB.
```

## Pose / rigging contract

- Origin at grip (back of shield where the arm-strap attaches).
- Shield face along bone-local **+X** (player's left when at rest).
- Player.gd applies a 90° X rotation when parenting under
  `LeftHandShieldAttach`.
