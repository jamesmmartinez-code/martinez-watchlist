# Agent Watchdog — 2026-05-07T14:00:48Z

## Summary
- 3 enabled eldoria-* tasks — all HEALTHY
- 2 paused-protected (nightly-builder, polisher — left alone)
- 19 paused-intentional (user-disabled, mostly migrated to GHA crons)
- No overdue, no stuck, no P0 alerts

## Enabled tasks

| Agent | Schedule | Last Run | Status | Action |
|-------|----------|----------|--------|--------|
| eldoria-character-specialist | hourly (0 * * * *) | 13:01:05Z (~59m ago) | HEALTHY | none |
| eldoria-substance-materials | */30 | 13:34:23Z (~26m ago) | HEALTHY | none |
| eldoria-agent-watchdog | */5 | 13:59:53Z (~1m ago) | HEALTHY | self |

## Paused — protected (do not resume)

| Agent | Reason |
|-------|--------|
| eldoria-nightly-builder | was overwriting Player.gd (paused 2026-05-06) |
| eldoria-polisher | was reverting scale fixes (paused 2026-05-06) |

## Paused — intentional (user disabled / migrated to GHA)

eldoria-qa-triage, eldoria-art-director, eldoria-lore-keeper, eldoria-integrator,
eldoria-environment-specialist, eldoria-audio-engineer, eldoria-architect,
eldoria-quest-writer, eldoria-item-designer, eldoria-bestiary-designer,
eldoria-recipe-designer, eldoria-event-designer, eldoria-player-experience,
eldoria-canon-qa, eldoria-physics-engineer, eldoria-equipment-visualizer,
eldoria-animation-sourcer, eldoria-scale-engineer, eldoria-playtest

## Host

- /dev/shm: 489M used of 2.0G (26% full) — OK
- Stale work dirs cleaned: /dev/shm/{integ,canon-qa,anim,scale-eng,eldoria,wd}-* removed

## GitHub

- PAT: HTTP 200 — valid
- Recent CI (last 5): 4 success, 1 cancelled, 0 failure — healthy

## Actions taken this run

- Cleared stale /dev/shm/* watchdog/agent work dirs
- Verified GitHub PAT (200 OK)
- Verified CI: no failures in last 5 runs
- All 3 enabled eldoria-* agents are within 2x cron interval — no re-arm needed

## Alerts

None.
