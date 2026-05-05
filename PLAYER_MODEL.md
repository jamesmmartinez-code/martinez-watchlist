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

- **2026-05-04** — Polished **combat — boss feel** (Goblin Warlord readability + heft). Pure number tweaks tagged `# REFINE: combat — boss feel`; no new functions, no new patterns.
  - **Telegraph readability** (`Boss.gd::_show_telegraph_ring`, `::_show_telegraph_line`): albedo alpha `0.55 → 0.72` and emission_energy_multiplier `1.6 → 2.6`. The slam ring and charge lane now pop hard against the dappled forest canopy. This is the single biggest knob for **Alden**'s combat tolerance — the rule "telegraphs that linger" applies to brightness as well as duration.
  - **Telegraph windups** (`_attack_slam`: `0.7 → 0.9`, `_attack_charge`: `0.6 → 0.78`, both for the visual *and* the `await create_timer().timeout`): roughly +0.2s and +0.18s respectively. Big enough that a 9-year-old can react, small enough that **Owen** still has to actually move out of the way. Slam damage (×1.4) and charge speed (`18.0`) and charge-hit damage (×1.6) are *unchanged* — Owen's "the boss is dangerous" feel is preserved.
  - **Aura presence** (`Boss.gd::_ready` BossAura `OmniLight3D`): `light_energy 2.5 → 2.9`, `omni_range 14.0 → 15.5`. The Warlord glows more cinematically as the player approaches; helps the boss read as a *boss* even from outside the 30m intro radius.
  - **Boss damage numbers** (`Boss.gd::_spawn_damage_number`): `font_size 44 → 50`, outline `6 → 7`, modulate `(1.0, 0.65, 0.30) → (1.0, 0.74, 0.32)`. Brighter / chunkier hits per Owen's mastery-feedback affinity. Note: regular `Enemy.gd` damage numbers were already polished in run 3 (font 38/56→44/62) — this brings the boss numbers up another notch above the mob baseline so Owen can feel that boss hits matter more.
  - **Adaptive proposal for the next run:** when `World.player_pressure_signal()` ships, telegraph windup is the first knob to wire — `lerp(0.78, 1.05, 1.0 - pressure)` on charge and `lerp(0.9, 1.20, 1.0 - pressure)` on slam. A stressed player gets even more reaction time; a calm player faces tighter telegraphs. Combine with `World.faction_pressure(id)` per the formula already noted above. Telegraph alpha/emission stay constant — readability shouldn't be a difficulty axis, only timing.
