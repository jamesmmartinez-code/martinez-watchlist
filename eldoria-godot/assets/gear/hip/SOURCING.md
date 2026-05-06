# hip — Sourcing Backlog

Owned by: **Equipment Visualizer**.
Items: sheathed weapons, scabbards, belt pouches, dangling trinkets.

NOTE: This slot has bone-attachment scaffolding in `Player.gd` but no
`_rebuild_hip_visual()` yet. Items.gd does not currently define any
hip-slot items either. First step is to add 1-2 hip-slot items
(e.g. `belt_pouch`, `sheathed_dagger`) in coordination with Item Designer.

## Pose / rigging contract (planned)

- Origin at the belt center (front of the hip bone).
- Pouches/scabbards extend along **-Y** (downward) and slightly along **+X**
  (player's left, where the scabbard hangs for a right-handed swing).
