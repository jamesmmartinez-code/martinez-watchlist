# head — Sourcing Backlog

Owned by: **Equipment Visualizer**.
Items: helmets, hoods, crowns.

## Items still needing a GLB

| Item id        | Tier       | Shape hint  | Sourcing                                              |
| -------------- | ---------- | ----------- | ----------------------------------------------------- |
| iron_helm      | common     | bucket helm | Sketchfab: `medieval bucket helm low poly cc-by`.     |
| steel_helm     | uncommon   | sallet      | Tier-tint of iron_helm OR new mesh.                   |
| silver_helm    | rare       | sallet      | Tier-tint of iron_helm.                               |
| ranger_hood    | uncommon   | leaf hood   | Sketchfab: `ranger hood low poly cc-by`.              |
| crown_eldoria  | legendary  | crown       | Sketchfab: `royal crown low poly cc-by` + gold + gem. |

## Pose / rigging contract

- Origin at the inside of the brim (where it sits on the skull).
- Cranial axis along bone-local **+Y** (upright).
- Player.gd offsets +0.10 forward to account for the skull bone's pivot.
- Diameter ≤ 0.30 world units (kid-hero head size).
