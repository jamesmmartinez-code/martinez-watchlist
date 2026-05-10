# Watchdog 2026-05-10T13:39Z

## Active Agent Health

| Agent | Status | Last Run | Interval |
|-------|--------|----------|----------|
| eldoria-nightly-builder | ✅ HEALTHY (manual-exclude) | 5m ago | 30m |
| eldoria-polisher | ✅ HEALTHY (manual-exclude) | 34m ago | 45m |
| eldoria-qa-triage | ✅ HEALTHY | 2m ago | 30m |
| eldoria-integrator | ✅ HEALTHY | 5m ago | 30m |
| eldoria-character-specialist | ✅ HEALTHY | 33m ago | 60m |
| eldoria-physics-engineer | ✅ HEALTHY | 33m ago | 60m |
| eldoria-scale-engineer | ✅ HEALTHY | 32m ago | 60m |
| eldoria-agent-watchdog | ✅ HEALTHY | 1m ago | 30m |

## Paused Agents (Intentional)

| Agent | Reason |
|-------|--------|
| eldoria-art-director | User disabled 2026-05-06; GHA covers content |
| eldoria-lore-keeper | User disabled 2026-05-06; GHA covers lore |
| eldoria-architect | User disabled 2026-05-06; stuck |
| eldoria-quest-writer | Replaced by GHA eldoria-quest-designer.yml |
| eldoria-item-designer | Moved to GHA |
| eldoria-bestiary-designer | Moved to GHA |
| eldoria-recipe-designer | Moved to GHA |
| eldoria-event-designer | Moved to GHA |
| eldoria-player-experience | User disabled 2026-05-06; stuck |
| eldoria-canon-qa | User disabled 2026-05-06; stuck |
| eldoria-equipment-visualizer | User disabled 2026-05-06; stuck |
| eldoria-animation-sourcer | User disabled 2026-05-06; stuck |
| eldoria-playtest | User disabled 2026-05-06; stuck |
| eldoria-substance-materials | Disabled (no Substance exports) |

## Infrastructure

| Check | Result |
|-------|--------|
| PAT | ✅ ok |
| /dev/shm | 0% used (512M free) |
| CI failures (last 5) | 0 |

## Actions Taken

- /dev/shm cleaned (no stale locks found)
- No STUCK agents detected — no re-arms needed

---
_All 8 active agents healthy. No action required._
