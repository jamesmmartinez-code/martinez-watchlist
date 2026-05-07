# Playtest Report — 2026-05-06T00:00:00Z
- boot_status: PARTIAL — page loaded (title "Realm of Eldoria"), canvas element present, but interaction blocked
- char_select: UNKNOWN — could not click "CLICK HERE TO PLAY" gate to reach char select
- movement: UNKNOWN — never reached gameplay
- scale: UNKNOWN — never reached gameplay
- js_errors: unable to read (console API blocked)
- screenshots: none — screenshot API blocked this run
- regressions_since_last_run: n/a (tooling failure, not game failure)

## Notes
- Chrome MCP partially available: `tabs_context_mcp`, `navigate`, `find`, and `read_page` worked.
- All interactive Chrome MCP calls (`computer:screenshot`, `computer:left_click`, `javascript_tool`) failed with: "Cannot access a chrome-extension:// URL of different extension".
- The site itself loaded (HTTP 200, page title set, canvas tag present, "CLICK HERE TO PLAY" gate found at ref_3), so the deploy looks healthy from a server perspective.
- Cannot confirm CharacterSelect.tscn rendering, player scale, or WASD movement this run.

## Action for next run
- Verify Chrome MCP extension permissions on this host. The "different extension" error suggests another extension is intercepting the page or the MCP extension lost permission for the workers.dev origin.
- If the issue persists, fall back to native computer-use (Safari/Chrome native) for the playtest.
