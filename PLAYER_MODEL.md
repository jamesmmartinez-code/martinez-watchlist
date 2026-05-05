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

- **2026-05-04** — Polished **balance** for first-session progression and 30+ kill momentum (no new functions; pure number tuning, every edit tagged `# REFINE: balance`).
  - `Player.gd` per-level stat gains: `max_hp` +14 → +18, `max_mp` +8 → +10. Chunkier level-up beat (helps **Owen** read mastery growth, gives **Alden** more survivability headroom).
  - `Player.gd` `xp_for_next_level()` curve: `100 + level*60 + level²*8` → `85 + level*55 + level²*7`. Cuts ~12% off every gate. Level 1→2 was 168 XP, now 147; cumulative-to-level-5 was 1240, now 1100. A 30-mixed-kill session lands at level 3-4 reliably.
  - `Items.gd` `DROP_TABLE.goblin`: trimmed `rusty_sword` (12 → 8) and `goblin_ear` (40 → 38), doubled `steel_blade` (2 → 4), lifted `hp_potion_s` (35 → 36) and `iron_sword` (7 → 9). Less junk-on-pickup since the player spawns with iron_sword equipped; real upgrade chance from goblin grind doubles.
  - `Items.gd` `DROP_TABLE.wolf`: shifted 3 weight points from pots/pelts into the gear band (`leather` 10 → 12, `chainmail` 4 → 6, `steel_blade` 3 → 4); pots 25 → 22, pelts 50 → 48. Wolves now feel like the mid-tier upgrade enemy the world model implies. Total weight preserved at 92.
  - **Adaptive proposal for the next run:** when `World.player_pressure_signal()` ships, `xp_for_next_level()` could *also* read it — the constants `85 / 55 / 7` would become `lerp(80, 95, pressure)` etc., letting a stressed player ding faster (more frequent power spikes = recovery valve) without softening for a calm player.

- **2026-05-04 (run 3 follow-up)** — Layered a world-flag warmed dialogue
  tier on top of the integrator's pattern-A NPC-flag tier. Lyra now has 4
  extra lines that fire on `lyra_potion_brew` (a *world* flag, not a
  personal one) so even on a brand-new save where the player hasn't pelted
  yet, the village feels like it has continuity — the recipe is "loose."
  This serves **Alden** in a slightly different way than personal warming
  serves him: it treats the village itself as a character he can know,
  separate from any one NPC liking him. **Owen**'s playstyle is unaffected
  (still one-button interact, no friction added).


- **2026-05-04 (run 4)** — Layered a faction-pressure warmed dialogue tier
  (Tier 3) on top of the integrator's pattern-A NPC-flag tier and the
  run-3-follow-up world-flag tier. Maeve now picks up 4 lines that fire
  when `whisperwood_goblins` pressure drops below 0.9 — reachable on the
  "ears-before-cleansing" path where Mara's bounty makes the wood notably
  safer before Maeve has any personal reason to warm to the player. Serves
  **Alden** (frog kid, high Companions affinity) by making the village
  respond to the *aggregate* of his work — not just to specific quest
  completions — so the world feels like it has a memory of his choices
  even when he hasn't talked to anyone in particular yet. Serves **Owen**
  (race kid, mastery affinity) by adding one more visible rung to the
  consequence ladder he climbs: "I did the bounty → the wood feels different
  → the elder narrates it back to me." No friction added (one E press still
  resolves to a quest panel). **Adaptive proposal for the next run:** the
  same `faction_pressure(id)` scalar should drive `Enemy.gd attack_cooldown`
  via `lerp(1.45, 1.05, 1.0 - pressure)` — calm-faction enemies recover
  faster (Owen gets the harder fight he wants), stressed-faction enemies
  give more breathing room (Alden gets the recovery valve). One scalar,
  two outputs, both player-models served.

- **2026-05-04 (polish run)** — Polished **visual — Crystal Caves atmosphere** (no new functions; pure number/color tweaks tagged `# REFINE: visual — Crystal Caves`). The dungeon shipped recently with placeholder lighting that read as "lit room with crystals" rather than "oppressive cavern dimly powered by crystals." Changes in `WorldBuilder.gd`:
  - **Cavern dome** albedo (0.06, 0.08, 0.14) → (0.04, 0.05, 0.10), roughness 0.95 → 0.98 — interior shell now darker and more matte so emissive crystals carry the room.
  - **Entrance beacon** emission 3.0 → 4.0; beacon OmniLight energy 2.5 → 3.2, omni_range 14 → 18 — the beacon now actually beacons from the Whisperwood treeline (helps **Alden** spot the cave entrance from his exploration wanders).
  - **Chamber ambient** OmniLight energy 0.85 → 0.62 (range unchanged at 28m) — dims the room so the crystal clusters do the lighting work.
  - **Boss-room violet** OmniLight energy 1.6 → 2.4, omni_range 18 → 24 — stronger violet pool around the Crystal Guardian; boss room reads as cinematic. No combat numbers touched.
  - **Cave floor** albedo (0.18, 0.20, 0.26) → (0.12, 0.14, 0.20), roughness 0.95 → 0.78 — cooler, faintly damp gloss so crystal glow catches a sheen on the rock.
  - **Crystal cluster shards** emission_energy_multiplier 2.4 → 3.2, alpha 0.85 → 0.72 — pushes them toward stained-glass: stronger glow + more translucent so inner light leaks through.
  - **Cave skull pile** albedo (0.85, 0.80, 0.72) → (0.92, 0.86, 0.74), roughness 0.85 → 0.92 — chalkier ivory tint reads clearer under cool blue ambient than the warmer arena-skull color (boss-arena skull pile in `_build_boss_arena` is intentionally untouched — different lighting context).
  - **Adaptive proposal for the next run:** when `World.player_pressure_signal()` ships, the chamber ambient (`amb.light_energy`) is the right knob to *temporarily* lift on respawn-after-death (lerp 0.62 → 0.85 over ~6s) — gives a stressed player one round of clearer footing without changing the cave's resting mood. Pure number knob, fits the existing rule of thumb.

  Why this serves both kids: the darker, crystal-driven look gives **Alden** (frog kid, exploration affinity) a richer "wow, look at this place" beat without raising any combat difficulty. The brighter beacon and violet boss pool give **Owen** (racer / mastery affinity) a more cinematic boss-room reveal — boss arenas should feel like arenas. None of the cave's gameplay numbers (HP, dmg, XP, gold, aggro, telegraph) changed; this is pure mood polish.