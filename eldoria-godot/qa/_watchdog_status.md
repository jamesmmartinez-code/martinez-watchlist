# Agent Watchdog — 2026-05-08T06:33:00Z

| Agent | Schedule | Last Run | Age | Status | Action |
|-------|----------|----------|-----|--------|--------|
| eldoria-character-specialist | hourly | 06:20 UTC | 13m ago | HEALTHY | none |
| eldoria-substance-materials | */30 | 06:20 UTC | 13m ago | HEALTHY | none |
| eldoria-agent-watchdog | */5 | 06:31 UTC | 2m ago | HEALTHY (self) | none |
| eldoria-nightly-builder | */5 | 2026-05-06 06:04 | — | PAUSED-PROTECTED | leaving alone |
| eldoria-polisher | */15 | 2026-05-06 06:01 | — | PAUSED-PROTECTED | leaving alone |
| eldoria-qa-triage | */3 | 2026-05-06 14:43 | — | PAUSED-INTENTIONAL | none |
| eldoria-art-director | */30 | 2026-05-07 02:33 | — | PAUSED-INTENTIONAL | none |
| eldoria-lore-keeper | */30 | 2026-05-07 02:36 | — | PAUSED-INTENTIONAL | none |
| eldoria-integrator | */10 | 2026-05-07 02:57 | — | PAUSED-INTENTIONAL | none |
| eldoria-environment-specialist | */10 | 2026-05-07 02:23 | — | PAUSED-INTENTIONAL | none |
| eldoria-audio-engineer | */30 | 2026-05-07 02:23 | — | PAUSED-INTENTIONAL | none |
| eldoria-architect | hourly | 2026-05-06 19:56 | — | PAUSED-INTENTIONAL | none |
| eldoria-quest-writer | */30 | 2026-05-06 11:35 | — | PAUSED-INTENTIONAL (moved to GHA) | none |
| eldoria-item-designer | */30 | 2026-05-06 11:35 | — | PAUSED-INTENTIONAL (moved to GHA) | none |
| eldoria-bestiary-designer | */30 | 2026-05-06 19:40 | — | PAUSED-INTENTIONAL (moved to GHA) | none |
| eldoria-recipe-designer | */30 | 2026-05-06 19:40 | — | PAUSED-INTENTIONAL (moved to GHA) | none |
| eldoria-event-designer | */30 | 2026-05-06 19:40 | — | PAUSED-INTENTIONAL (moved to GHA) | none |
| eldoria-player-experience | */30 | 2026-05-06 11:38 | — | PAUSED-INTENTIONAL | none |
| eldoria-canon-qa | */5 | 2026-05-06 11:44 | — | PAUSED-INTENTIONAL | none |
| eldoria-physics-engineer | */10 | 2026-05-06 11:44 | — | PAUSED-INTENTIONAL | none |
| eldoria-equipment-visualizer | */15 | 2026-05-06 11:16 | — | PAUSED-INTENTIONAL | none |
| eldoria-animation-sourcer | */20 | 2026-05-06 11:25 | — | PAUSED-INTENTIONAL | none |
| eldoria-scale-engineer | */4 | 2026-05-06 11:28 | — | PAUSED-INTENTIONAL | none |
| eldoria-playtest | */25 | 2026-05-06 11:28 | — | PAUSED-INTENTIONAL | none |

## Disk
- Sandbox /: 9.6G total, 8.9G used (93%) — **WARNING: high but stable**
- Root cause: user's mounted project folder contains 21GB Substance materials + 3.5GB Mixamo assets
- /dev/shm: 512M — too small for full repo clone; watchdog now uses sparse clone (~864K)
- No leftover /dev/shm/wd-* or /tmp/wd-* agent dirs found

## GitHub PAT
HTTP 200 — PAT valid ✅

## CI (last 5 runs on jamesmmartinez-code/martinez-watchlist)
- 67d3c320 Build Eldoria (Godot Web Export) — **in_progress** ✅
- 67d3c320 pages build and deployment — in_progress
- 399e6af9 Build Eldoria — cancelled
- 399e6af9 pages build and deployment — cancelled
- 5fbe0079 Build Eldoria — cancelled

No failures. Active build running on latest commit.

## Actions taken this run
- No agent recovery needed — all 3 enabled agents healthy
- Switched watchdog clone strategy to sparse (--filter=blob:none --sparse) to handle full disk
- Protected agents (nightly-builder, polisher) left paused as required
- 19 intentionally-disabled agents untouched

## Summary
**Swarm is healthy.** 3 enabled Cowork-scheduled agents (character-specialist, substance-materials, watchdog) all ran within last 15 minutes. GHA/Cloudflare Worker covers the remaining 60 agent lanes. No alerts.
