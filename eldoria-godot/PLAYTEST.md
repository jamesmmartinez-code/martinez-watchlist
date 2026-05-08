# Playtest Report — 2026-05-08T06:44:56Z
- boot_status: PARTIAL — site HTTP 200, page title "Realm of Eldoria" confirmed, canvas present, Godot WASM initializes (tab title progresses through "_ready START" → agent build logs)
- char_select: UNKNOWN — "CLICK HERE TO PLAY" gate present (ref_2 in accessibility tree), but click blocked by Chrome MCP extension conflict; cannot confirm CharacterSelect.tscn rendered inside canvas
- movement: UNKNOWN — canvas interaction (click to focus, WASD key injection) blocked by Chrome MCP extension conflict
- scale: UNKNOWN — no visual verification possible
- js_errors: UNKNOWN — console API blocked by Chrome MCP extension conflict; no JS errors captured
- screenshots: none — screenshot API blocked (same extension conflict)
- regressions_since_last_run: none detected vs 2026-05-06 report — same tooling failure, same site health

## What was confirmed this run
- Site is UP: `https://eldoria-api.james-m-martinez.workers.dev/eldoria/` returns 200
- Page title correctly set to "Realm of Eldoria" on load
- HTML canvas element present in DOM (accessibility tree: ref_1 canvas, ref_2 "CLICK HERE TO PLAY", ref_3 WASD hint)
- Godot WASM engine boots: tab title progresses from "_ready START" → Godot agent build sequence (e_chimneys, _build_campfire, _build_enemies, _build_pet, _build_stable_horse, _build_loot_chests, _build_crystal_caves, etc.)
- Tab survives 30+ seconds without crash (no OOM/tab-crash on this run)

## Persistent tooling block (3rd consecutive run)
- `computer:screenshot`, `computer:left_click`, `javascript_tool` all fail: "Cannot access a chrome-extension:// URL of different extension"
- `read_console_messages` and `read_network_requests` return empty (extension doesn't inject into this origin)
- Root cause: duplicate Claude Chrome extensions on James's Mac (documented in eldoria_validation_walls.md)
- **Fix required**: In Chrome → Extensions, disable the extra Claude extension so only one is active. This will unblock all interactive playtest checks.

## What cannot be verified until tooling is fixed
- CharacterSelect.tscn renders "Choose Your Hero" with Alden/Owen cards
- Player spawn scale (~1.8m vs house ~5m)
- WASD movement (FAIL_FROZEN check)
- JS console errors post-boot
