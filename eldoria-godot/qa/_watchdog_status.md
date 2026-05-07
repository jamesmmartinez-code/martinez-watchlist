# Agent Watchdog — 2026-05-07T13:55Z

| Agent | Schedule | Last Run | Status | Action |
|-------|----------|----------|--------|--------|
| eldoria-agent-watchdog | */5 min | 13:53 (2m ago) | HEALTHY | self |
| eldoria-character-specialist | hourly | 13:01 (54m ago) | HEALTHY | none |
| eldoria-substance-materials | */30 min | 13:34 (21m ago) | HEALTHY | none |
| eldoria-nightly-builder | */5 min | 2026-05-06 06:04 | PAUSED-PROTECTED | leaving alone (was overwriting Player.gd) |
| eldoria-polisher | */15 min | 2026-05-06 06:01 | PAUSED-PROTECTED | leaving alone (was reverting scale fixes) |
| eldoria-qa-triage | */3 min | 2026-05-06 14:43 | DISABLED | enabled:false (user-paused 2026-05-06) |
| eldoria-integrator | */10 min | 2026-05-07 02:57 | DISABLED | enabled:false (no DISABLED prefix in desc — flag for user) |
| eldoria-physics-engineer | */10 min | 2026-05-06 11:44 | DISABLED | enabled:false (no DISABLED prefix in desc — flag for user) |
| eldoria-scale-engineer | */4 min | 2026-05-06 11:28 | DISABLED | enabled:false (no DISABLED prefix in desc — flag for user) |
| eldoria-art-director | */30 min | 2026-05-07 02:33 | DISABLED | desc: "DISABLED 2026-05-06 — user requested off" |
| eldoria-lore-keeper | */30 min | 2026-05-07 02:36 | DISABLED | desc: "DISABLED 2026-05-06 — user requested off" |
| eldoria-environment-specialist | */10 min | 2026-05-07 02:23 | DISABLED | desc: "DISABLED 2026-05-06" (GHA covers) |
| eldoria-audio-engineer | */30 min | 2026-05-07 02:23 | DISABLED | desc: "DISABLED 2026-05-06" |
| eldoria-architect | hourly | 2026-05-06 19:56 | DISABLED | desc: "DISABLED 2026-05-06" |
| eldoria-quest-writer | */30 min | 2026-05-06 11:35 | DISABLED | desc: "DISABLED — replaced by GHA" |
| eldoria-item-designer | */30 min | 2026-05-06 11:35 | DISABLED | desc: "DISABLED — moved to GHA" |
| eldoria-bestiary-designer | */30 min | 2026-05-06 19:40 | DISABLED | desc: "DISABLED — moved to GHA" |
| eldoria-recipe-designer | */30 min | 2026-05-06 19:40 | DISABLED | desc: "DISABLED — moved to GHA" |
| eldoria-event-designer | */30 min | 2026-05-06 19:40 | DISABLED | desc: "DISABLED — moved to GHA" |
| eldoria-player-experience | */30 min | 2026-05-06 11:38 | DISABLED | desc: "DISABLED 2026-05-06" |
| eldoria-canon-qa | */5 min | 2026-05-06 11:44 | DISABLED | desc: "DISABLED 2026-05-06" |
| eldoria-equipment-visualizer | */15 min | 2026-05-06 11:16 | DISABLED | desc: "DISABLED 2026-05-06" |
| eldoria-animation-sourcer | */20 min | 2026-05-06 11:25 | DISABLED | desc: "DISABLED 2026-05-06" |
| eldoria-playtest | */25 min | 2026-05-06 11:28 | DISABLED | desc: "DISABLED 2026-05-06" |

## Disk

`/dev/shm`: 1.5GB free of 2.0GB (22% used) — OK. Many stale wd-* dirs from prior runs owned by another user; not blocking.

## GitHub Auth

PAT health check on `jamesmmartinez-code/martinez-watchlist` -> HTTP 200. Valid.

## CI

Last 5 workflow runs on `martinez-watchlist`: 4 success, 1 cancelled, 0 failures. Build pipeline is green (Build Eldoria + Pages deploys both passing).

## Stuck / overdue agents

NONE. Of 24 Eldoria scheduled tasks:
- 3 enabled and healthy (character-specialist, substance-materials, agent-watchdog/self)
- 2 paused under watchdog protection (nightly-builder, polisher)
- 19 user-disabled (mostly migrated to GHA crons or intentionally turned off)

## Actions taken this run

- Cleared stale `/dev/shm` working dirs where permission allowed (some left by another user uid).
- Verified GitHub PAT is still valid (HTTP 200).
- Verified recent CI: no failures.
- No agents required re-arming — all enabled agents fired within their expected window.
- Switched commit path from `git clone` to GitHub Contents API after `git clone` repeatedly timed out at 40s — likely related to the known "Cowork dispatcher stuck" symptom.

## Notes for user

Four disabled tasks have **no "DISABLED"/"PAUSED" prefix in their description** even though `enabled:false`. Consider editing the description to start with "PAUSED" or "DISABLED" so the watchdog classification rule matches them cleanly:
- `eldoria-qa-triage`
- `eldoria-integrator`
- `eldoria-physics-engineer`
- `eldoria-scale-engineer`

Currently classifying these as DISABLED (not stuck) because `enabled:false`.

The Eldoria swarm is now mostly running on the Cloudflare Worker cron (`realm-of-eldoria.james-m-martinez.workers.dev`) per the recent migration — local Cowork-side scheduled tasks are intentionally minimal.
