# Eldoria Agent Roster

18 agents across 5 layers. Each agent has its own spec file in this folder. Use these as system prompts when delegating focused work via the Agent tool.

## Layers

### Creative spine — writes the world
- **Lorekeeper** — canon markdown (regions, factions, NPCs, calendar, creatures)
- **Concept Artist** — 2D reference art for every named entity

### Content — volume drafts, parallel lanes
- **Quest Writer** — `data/quests/` `.tres` files
- **Dialogue Writer** — `data/dialogue/` NPC trees + barks
- **Item Designer** — `data/items/` weapons / armor / consumables / materials / relics
- **Bestiary Designer** — `data/creatures/` + `data/bosses/` stat blocks + kits
- **Recipe Designer** — `data/recipes/` + `data/stations/`
- **Event Designer** — `data/events/` festivals / world / daily + `data/rumors/`

### Experience — player-facing feel
- **UI Designer** — screens, HUD, menus
- **Player Experience** — onboarding, pacing, difficulty, accessibility, juice
- **Audio** — music, SFX, ambient soundscapes
- **Atmosphere** — particles, weather, lighting, fog, time-of-day

### 3D pipeline — build the world
- **Character** — humanoid + creature meshes
- **Architect** — world placement, level layout, props

### Engineering — make it work
- **Builder** — wires content + UI signals into gameplay GDScripts
- **Code QA** — fixes parse/import/runtime errors, runs build verify
- **Canon QA** — audits state vs Lorekeeper/Concept canon, catches drift
- **Integrator** — merges `auto/*` branches every 2 min

## Recent change (2026-05-05)

Split the original 9-agent roster into 18 specialists:

- `content-creator.md` → DEPRECATED. Replaced by 6 lane specialists (quest, dialogue, item, bestiary, recipe, event).
- `qa-triage.md` → DEPRECATED. Replaced by `code-qa.md` + `canon-qa.md`.
- Added `player-experience.md`, `audio.md`, `atmosphere.md` (previously had no owner).

## How to use

Each agent file has:
- **Mission** — one paragraph "what they care about"
- **Inputs** — what they read
- **Outputs** — what they produce, where
- **Boundaries** — what they explicitly do NOT do
- **Handoffs** — who they hand work to
- **Done criteria** — how to know a pass is finished

When spawning a focused agent (via Task / Agent tool), paste the relevant file's body as the agent's system prompt. The boundaries + handoffs sections prevent scope creep.

## Cross-cutting rules

1. **Canon flows in one direction**: Lorekeeper → Content → Engineering. Reverse flow is via flag (`LORE_GAP:`, `CONCEPT_NEEDED:`, `QUEST_FEEDBACK:`).
2. **Branches are short-lived**: every agent works on `auto/<agent>/<topic>` branches. Integrator merges every 2 min if Code QA is green.
3. **Placeholder debt is tracked**: any `.wav`, `.png`, `.glb` that's a placeholder gets a `# PLACEHOLDER` comment and a row in `qa/_placeholder_debt.md`.
4. **Kid-first**: target reading age 9-11. PX has veto over anything that confuses or punishes.
5. **Builder MUST run GDScript indent check before signaling Code QA.** GDScript is whitespace-sensitive — one extra tab causes a silent parse failure that produces a blank world at runtime. This has happened TWICE (pre-2026-05-09 and run-33, 2026-05-09). The check is in `code-qa.md §Recurring failure mode`. No `.gd` edit ships until the checker returns `OK`. CI does NOT catch this — the build step passes and the error only fires when the game loads in the browser.
