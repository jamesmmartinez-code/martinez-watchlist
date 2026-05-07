# Playtest Report — 2026-05-06T00:00:00Z
- boot_status: PARTIAL — page loaded (title "Realm of Eldoria"), canvas element present, but interaction blocked
- char_select: UNKNOWN — could not click "CLICK HERE TO PLAY" gate to reach char select
- movement: UNKNOWN — never reached gameplay
- scale: UNKNOWN — never reached gameplay
- js_errors: unable to read (console API blocked)
- screenshots: none — screenshot API blocked this run
- regressions_since_last_run: n/a (tooling failure, not game failure)

## Failure category
TOOLING_FAILURE — not a game regression.

## Notes
- Chrome MCP partially available: `tabs_context_mcp`, `navigate`, `find`, and `read_page` worked.
- All interactive Chrome MCP calls (`computer:screenshot`, `computer:left_click`, `javascript_tool`) failed with: "Cannot access a chrome-extension:// URL of different extension".
- Site itself loaded (HTTP 200, page title "Realm of Eldoria", canvas tag present, "CLICK HERE TO PLAY" gate visible at ref_3) — server-side deploy looks healthy.
- Cannot confirm CharacterSelect.tscn rendering, player scale, or WASD movement this run.

## Recommended QA Triage action
Do NOT open a code regression issue. Open an infra/tooling issue:
"Chrome MCP screenshot+click blocked on workers.dev origin — extension URL conflict"
