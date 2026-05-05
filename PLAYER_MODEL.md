# Player Model — Realm of Eldoria

What we know about the two real players. Used to bias backlog decisions:
when two features compete, pick the one that serves the underrepresented kid
or the underused playstyle.

## Players

### Alden — age 9 — 🐸 the frog kid
Affinities (high → low):
- Exploration: wandering, finding hidden things, looking up at sky/water
- Companions: pets, NPCs that talk to him by name, the frog
- Nature: trees, ponds, fireflies, weather, animals
- Collection: picking things up just because they're shiny
- Combat tolerance: low-to-medium; gets discouraged by deaths

Designs that serve Alden:
- Pets and companions that follow and emote (Pet.gd already exists — extend)
- Hidden glades, named trees, things that respond to proximity
- Forgiving combat: telegraphs that linger, large hit windows
- Frogs anywhere, always
- Quests with no time pressure

### Owen — age 11 — 🏎️ the racer
Affinities (high → low):
- Speed: mounts, sprint, fast traversal, slides, jumps
- Gadgets: tools with combos, charged attacks, status effects
- Challenge: bosses, optional hard fights, rankings, badges
- Mastery loops: noticing he's gotten better at a system
- Combat tolerance: high; *wants* harder fights

Designs that serve Owen:
- Mount upgrades, shortcuts, jumps, races against the clock
- Status-effect combos (bleed × slow × burn)
- Tougher boss telegraphs, second-phase mechanics
- Visible mastery: damage numbers, kill counts, achievement chains
- Optional hard mode toggles, never global difficulty

## Co-op Constraints

The kids play *together*. Therefore:
- Co-op objectives > PvP. No mechanic that pits them against each other.
- Asymmetric roles welcome (Alden tames pets, Owen drives the boss).
- Death of one player should not strand the other.
- Loot is shared by default.

## Difficulty Signals

(Operational telemetry. None of these are wired yet — listed so the next
adaptive-difficulty run knows where to start.)

| Signal             | Source                         | Meaning                  |
|--------------------|--------------------------------|--------------------------|
| deaths_per_minute  | Player.respawn count + clock   | too hard if > 0.5        |
| time_to_kill       | Enemy.gd → World.gd timer      | too easy if < 1.5s       |
| quest_abandon_rate | (not tracked yet)              | quest UX too friction-y  |
| session_length     | (not tracked yet)              | engagement health        |
| revisit_count      | (not tracked yet)              | which biomes they re-enter |

The *first* implementation should track `deaths_per_minute` and `time_to_kill`
in a rolling 90-second window inside World.gd, and expose them as
`World.player_pressure_signal(): float` in [0,1]. Then enemy spawners can
read it to dampen or escalate. Telegraph timing should be the FIRST knob.

### Faction-pressure feedback (shipped 2026-05-04, run 2)

`World.faction_pressure(id)` now exists and is mutated by quest consequences.
This is the *world's* pressure on the player (how hostile the region feels),
distinct from `player_pressure_signal()` (how stressed the player looks).

The two SHOULD be combined when a future run lands adaptive difficulty:
final spawn intensity = `lerp(low, high, faction_pressure * (1.0 - player_pressure))`.
This makes "I'm winning" loops feel like the world calms, and "I'm dying"
loops feel like the world relents — both child-friendly outcomes per Rule 6.

## Hard Constraints (NEVER violate)

- No FOMO. No "this disappears if you don't act now" timers in the world.
- No monetization. No external links to stores. No virtual currency outside the
  in-game gold loop.
- No persuasive UI. No dark patterns. No accidental clicks that cost progress.
- No social-pressure mechanics. No leaderboards beyond local kid-vs-kid.
- Failure is forgiving. Respawn at the well, keep XP, keep gear, lose a small
  gold tax if anything.

## Open Questions (for runs to answer with playtest data, not assumptions)

- Does Alden know how to mount? (Probably — but maybe rebind from M to a more
  obvious key, per backlog item 10.)
- Does Owen find the existing 3 enemy types repetitive? (Backlog item 6 —
  Skeleton/Bandit variety.)
- Is the day/night cycle (6 min) too fast for Alden's exploration? (Watch:
  if he never sees the same biome twice in one session, lengthen.)

## Polish Notes — visual envelope (auto-logged)

- **2026-05-04** — Polished Main.tscn for cooler shadows / warmer highlights:
  ambient pushed cool-blue (0.78, 0.80, 0.92) at energy 0.60; sun warmed to
  (1.0, 0.78, 0.46) at energy 1.95; moon-fill lifted to (0.42, 0.62, 1.0) at 0.58.
  Volumetric fog density 0.015 → 0.022 and length 80 → 110 for richer god-rays.
  Glow threshold 0.92 → 0.74 + bloom 0.22 → 0.34 so foliage rims and fireflies
  pop more — should help **Alden** (frog kid, exploration affinity) notice
  pretty things in the world. SSAO intensity 2.85 → 3.30 deepens contact shadows
  under trees/props which makes **Owen's** combat hits feel more grounded.

- **2026-05-04** — Polished NPC dialogue depth: each of the 7 villagers now carries 4 mood-dependent lines that swap by **time_of_day** (morning / midday / evening / night), plus one personal detail per NPC (Maeve fears the wolves, Edda wishes the dew lasted, Mara grudges miscounters, Lyra remembers her mother's garden, Bram boasts of three valleys, Roan trusts horses over men, Hala says strength is loud and mastery is quiet). Implementation: `NPC.gd` gained a `dialogue_variants: PackedStringArray` export with inline time-bucket selection; `WorldBuilder.gd` `NPCS` const now feeds `lines` per-NPC. No new functions, no balance change. This serves **Alden** (frog kid, high Companions affinity — NPCs that 'talk to him' feel more alive when the village shifts as the sun moves) without raising friction for **Owen** (one button-press still ends in a quest panel).

- **2026-05-04** — Polished combat feel for **Alden's low-to-medium combat tolerance** (without flattening the difficulty for **Owen**). All edits are number tweaks on existing exports/constants — no new behavior. (1) `Enemy.gd` `aggro_range` 9.0 → 8.0 (shorter chase initiation; less "they all rushed me at once" pile-ons). (2) `Enemy.gd` `attack_cooldown` 1.2 → 1.45 (a noticeably longer recovery window between enemy swings, the kid-friendly knob the model calls out). (3) `Enemy.gd` knockback impulse 3.0 → 4.5 (heavier hit beat — readable thump that Owen will feel as "good game feel" and that gives Alden a moment of separation to recover). (4) `Enemy.gd` damage-number font 38/56 → 44/62 with brighter modulate — visible mastery feedback per Owen's affinity ladder. (5) `DamageNumber.gd` motion: `_life` 1.0 → 1.18, vertical `_drift` 1.4 → 1.75, horizontal scatter ±0.4 → ±0.55, scale punch 0.25 → 0.38 peaking at 18% (was 20%), fade-out start 60% → 55% — pop-on snappier, dwell longer, easier to read. Adaptive proposal for the next run: when `World.player_pressure_signal()` ships, the same `attack_cooldown` knob should be the FIRST one wired to it (`lerp(1.45, 1.05, 1.0 - pressure)` so a calm player faces tighter swings, a stressed player gets even more breathing room).
