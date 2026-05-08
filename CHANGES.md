## Tech debt

### §15 Asset Budget Violation — Hero.glb (2026-05-08)
- **File**: `eldoria-godot/assets/models/Hero.glb`
- **Size**: 29 MiB (30,258 KB) — exceeds 20 MiB soft cap and 25 MiB hard cap per OPERATIONS.md §15
- **Status**: REFERENCED — cannot delete
  - Referenced in: `eldoria-godot/scripts/Player.gd`, `eldoria-godot/scripts/CharacterSelect.gd`, `eldoria-godot/scenes/Main.tscn`
- **Action required**: Compress or LOD-split Hero.glb to bring under 20 MiB before Cloudflare Pages migration
- **Detected by**: QA Watchdog run 2026-05-08T07:12 UTC



## 2026-05-08 Auto: run 22 -- Smith Edda forge UI (enchant/sell/buy)
Building: Forge UI enchant+sell+Mara shop
THEME s1 (parchment UI) + s12 (toast/button motion)
Files: Inventory.gd +enchant/sell/buy | World.gd +3 buttons+shop | Achievements.gd +first_enchant
5-output: i=show_dialogue wired; ii=attempt_* schema; iii=toast feedback; iv=first_enchant achievement; v=Achievements hook+ShopBtn role dispatch
Next: NPC memory or god-rays