# QA — Oversized Assets Log

Tracks per-file violations of the OPERATIONS.md §15 25 MiB hard cap (20 MiB
soft cap, 5 MiB safety margin). Each entry stays here until the responsible
agent re-exports the asset under the soft cap; QA then deletes the entry.

Maintained automatically by the eldoria-qa-triage scheduled task.

## Tech debt

### oversized-asset-eldoria-godot/assets/models/Owen.glb
- **Size:** 29.4 MiB (over 25 MiB hard cap by 4.4 MiB)
- **Committed by:** Eldoria Character (character@eldoria.local) at b3577215
- **Commit msg:** "Char: swap Player to Owen.glb (Meshy 11-yr-old, Owen's hero) + height normalize"
- **Referenced by:** `eldoria-godot/scripts/Player.gd`, `eldoria-godot/scenes/Main.tscn`
- **Disposition:** Cannot delete — load-bearing player model.
- **Owner:** Char to re-export at lower poly density / texture resolution
  to land under 20 MiB soft cap. Suggested: bake & decimate, drop diffuse
  textures from 4K → 2K, strip unused vertex color channels.
- **First flagged:** 2026-05-05 by QA Watchdog
