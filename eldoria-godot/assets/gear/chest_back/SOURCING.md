# chest_back — Sourcing Backlog

Owned by: **Equipment Visualizer**.
Items: capes, cloaks, quivers, wing-packs.

## Items still needing a GLB

| Item id           | Tier      | Shape hint  | Sourcing                                          |
| ----------------- | --------- | ----------- | ------------------------------------------------- |
| traveller_cape    | common    | short cape  | Sketchfab: `short fabric cape low poly cc-by`.    |
| mage_cape         | uncommon  | long cloak  | Tier-tint of traveller_cape with mage palette.    |
| ranger_cape       | uncommon  | hooded cape | Sketchfab: `ranger hooded cloak low poly cc-by`.  |
| royal_cloak       | rare      | regal cloak | Sketchfab: `royal cloak fur trim low poly cc-by`. |
| dragonscale_cape  | epic      | scaled cape | Meshy: `dragonscale cape, hand-painted, low poly`.|

## Pose / rigging contract

- Origin at neckline (top center of the cape, where it clasps).
- Cape hangs along bone-local **-Y** (down).
- Spine bone is what we attach to; cape geometry must NOT clip into the
  player's back at the neckline (z=-0.05 is the safe zone).
- Avoid baking cloth simulation into the GLB — kids run on web/mobile,
  rigid skinned mesh is fine, animated cloth is too expensive.
