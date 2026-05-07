# QA — Oversized Assets Log

Tracks per-file violations of the OPERATIONS.md §15 25 MiB hard cap (20 MiB
soft cap, 5 MiB safety margin). Each entry stays here until the responsible
agent re-exports the asset under the soft cap; QA then deletes the entry.

Maintained automatically by the eldoria-qa-triage scheduled task.

## Tech debt

_(none currently — see "Resolved" below for history)_

## Owner-override (NOT flagged)

### Hero.glb — 29.4 MiB
Architect's 2026-05-06T03:00Z audit explicitly chose personalization-for-kid
over the web-perf budget when owner pushed `23cfbd7` (replacement Meshy 11-yr-
old hero). NOT flagged as a §15 violation. Suggested follow-up (non-blocking):
Char to decimate the Meshy mesh (Blender → ~5–8k tris) and re-export, with
LOD0 detailed / LOD1 swap-in beyond ~15m. Track here, do not block deploys.

## Resolved

- **Owen.glb** (was 29.4 MiB) — deleted 2026-05-06 by QA Watchdog after
  Architect's audit confirmed the `cbe88d1` Player.gd → Hero.glb swap
  retired this model. Only remaining references in source were code
  comments in Player.gd. Sidecar `.import` deleted alongside.
