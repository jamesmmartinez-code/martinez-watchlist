# CHANGES

## Tech debt

### 2026-05-08 — §15 Asset Budget Violation: Hero.glb

**QA:** `eldoria-godot/assets/models/Hero.glb` is **29 MiB**, exceeding the OPERATIONS.md §15 soft cap of 20 MiB (hard cap: 25 MiB).

- **Status:** REFERENCED (cannot delete — active player model in `Main.tscn` and `Player.gd`)
- **Rule violated:** OPERATIONS.md §15 — Cloudflare Pages 25 MiB per-file asset budget
- **Required action:** Re-export Hero.glb with mesh LODs, compressed textures, or split into base mesh + animation library to bring under 20 MiB soft cap
- **Logged by:** Eldoria QA Watchdog at 2026-05-08T06:51:02Z
