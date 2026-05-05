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

- **2026-05-04 (run 5)** — Goblin spawn density now reads
  `World.faction_pressure("whisperwood_goblins")`. The wood becomes
  visually quieter as the player completes goblin-reducing quests.
  Serves **Alden** (frog kid, low-medium combat tolerance, exploration
  affinity) directly: a calmed Whisperwood is *less to fight, more to
  look at* — fewer goblin lanterns, more tree silhouettes through the
  gaps where camps used to be busy. Serves **Owen** (race kid, mastery
  affinity) by giving him a SECOND visible mastery-rung on the same
  scalar he's already climbing through dialogue: "I did the bounty →
  the elder narrates it → the wood actually has fewer goblins to ride
  past." Two outputs from one read; that's the compound mandate from
  Rule 1. **Adaptive proposal for the next run:** a *third* output on
  the same scalar — `Enemy.gd attack_cooldown` could
  `lerp(1.45, 1.05, 1.0 - faction_pressure)` so the few goblins LEFT
  in a calmed wood hit harder/faster (Owen's "harder fight" affinity)
  while a fresh-save full-pressure wood gives Alden the slower telegraph
  he needs. Same scalar, three coordinated outputs: dialogue, density,
  pacing. After that lands, the *fourth* coupling is per-frame pressure
  decay (kills_by_kind → faction reduction) so per-kill impact routes
  back through the same channel without quest gating.


## Run 6 — Wolf spawn density (mirror of goblin pattern)

Run 6 generalizes the run-5 compound to a second faction. Same shape:
faction pressure scalar drives BOTH dialogue (when Roan ships) and density
(now). For Alden: Whisperwood gets visibly quieter on TWO axes (goblins +
wolves) as the kids progress, so the "you tamed the woods" feeling
compounds rather than plateaus. For Owen: the proof that the run-5 helper
PATTERN generalizes — every future faction (bandit, skeleton, crystal) can
ship density on a single read of `faction_pressure(id)` plus a
`_<kind>_pack_size(pressure)` helper. The mastery-rung budget extends.

Adaptive proposal for run 7: use the same goblin pressure for a THIRD
output coupling — `Enemy.gd.attack_cooldown = lerp(1.45, 1.05, 1.0 - p)`.
A calmed-wood goblin hits faster (Owen's harder fight); a fresh-save
goblin hits slower (Alden's recovery valve). One scalar, three outputs:
narrative + density + pacing.

- **2026-05-04 (polish run 6)** — Polished **character — Pet.gd / Ember the fox**
  (no new functions; pure parameter tuning + two const arrays for bark variety,
  every edit tagged `# REFINE: character`). Pet.gd had been overlooked through
  five prior polish rounds and was the highest-ROI character target left.
  Changes:
  - `follow_distance` 2.5 → 2.2 (Ember sits closer; reads as more attentive).
  - `max_speed` 8.0 → 8.5 (keeps up on Owen's sprint without teleport-snap).
  - `bark_radius` 8.0 → 9.0 (warns *before* the goblin reaches the player).
  - Settle damping 0.85 → 0.80 (stickier stop; Ember plants instead of skating).
  - Bark cadence: flat `2.5` → `randf_range(1.8, 2.6)` (alive, not metronomic).
  - Bark text: single `"yip!"` → 5-line `BARK_LINES` pool (yip!, arf!, rrr!,
    yip yip!, yap!) — Ember's catchphrase pool, picked uniformly per bark.
  - Bark color: fixed `(1.0, 0.85, 0.30)` → 2-tone `BARK_COLORS` pool
    (warm-gold + ember-orange) picked per bark.
  - Nameplate: font 18 → 20pt (Alden can read it from the back of the screen);
    color (1.0, 0.65, 0.25) → (1.0, 0.55, 0.18) hotter ember tone.

  Why this serves both kids: Ember directly serves **Alden** (frog kid, high
  Companions affinity — pets that emote and have variety feel alive instead
  of looped). The wider bark perimeter and snappier follow also serve **Owen**
  (race kid) — when he sprints into a goblin camp, Ember warns earlier and
  catches up faster, so the companion stops being a drag on his pace. No
  combat numbers, no XP, no balance touched. **Adaptive proposal for the next
  run:** the same `BARK_LINES` pool could be filtered by mood — when
  `World.player_pressure_signal()` ships, a stressed player gets the calmer
  barks ("yip yip!", "yap!") and a calm player gets the alert ones ("rrr!",
  "arf!"). Pure index-filter on the existing pool, no new function needed.

- **2026-05-04 (run 7)** — Adaptive `Enemy.gd.attack_cooldown` (third output
  on the same `faction_pressure` scalar that drives dialogue tier 3 + spawn
  density). Lerp `[1.45, 1.05]` keyed on the kind's faction. Wired for
  goblins, wolves, skeletons, crystal_elementals, crystal_guardians; bandits
  baseline (no faction yet). Visible `⚡` prefix on the floating name when
  cooldown < 1.30 — kids can read pacing change per-enemy, not just per-density.

  **Why this serves both kids:**
  - **Alden (9):** the cooldown floor of 1.05s is still 5× longer than a
    typical Mario-style "punish frame," so even the fully-tamed Whisperwood
    goblin remains kid-readable. The recovery-valve baseline of 1.45s is
    *unchanged at fresh save* — Alden's first hour of play feels identical
    to runs 1–6, which is the contract for new-saver quality. The visible ⚡
    prefix tells him "this one's tougher" without requiring memorization
    of pressure thresholds.
  - **Owen (11):** as he progresses through the goblin / wolf reducers, the
    SAME enemy archetype gets *measurably* faster, so his mastery rung keeps
    rising without us shipping new enemy kinds. The few survivors at
    pressure 0.0 hit ~28% faster than the fresh-save baseline — readable
    challenge escalation that emerges from his own gameplay choices, not
    from a difficulty slider.

  **Mastery-rung budget update:** the run-5/6 forecast was that a single
  scalar driving 3+ outputs would prove generalizable. Run 7 ships output #3
  (cooldown). Output #4 candidate: adaptive `chase_speed` with a tighter band
  (e.g. `lerp(4.6, 5.4, 1.0 - p)`). Output #5 candidate: adaptive `damage`
  — but flag this as PLAYER_MODEL.md gating: increasing damage past the
  fresh-save baseline risks breaking Alden's HP economy. If we ship output #5,
  it should be a *symmetric* lerp on `xp_reward` so the harder fight is also
  more rewarding.

  **Difficulty signals to watch (run 8 telemetry candidates):**
  - Time-to-kill on `⚡` enemies vs. baseline enemies — should be roughly
    equal for Owen (he adapts), longer for Alden (he doesn't yet).
  - Player deaths-per-quest in late game (faction pressure < 0.4) — if this
    spikes for Alden, the band needs softening to `[1.20, 1.45]` for him.
    Per-player band tuning would be the first true *adaptive difficulty*
    feature in the engine, gating off `PLAYER_MODEL.md` rather than a
    difficulty menu (kids never see a menu; the world adapts to them).

- **2026-05-04 (run 8)** — Adaptive `Enemy.gd.chase_speed` (FOURTH output
  on the same `faction_pressure` scalar that already drives NPC dialogue
  tier 3 (run 4), goblin spawn density (run 5), wolf spawn density (run 6),
  and enemy attack cooldown (run 7)). Multiplicative band — each enemy
  kind's WorldBuilder-assigned chase_speed is preserved at fresh save and
  lerps up to `+17%` at pressure 0.0 (`CHASE_SPEED_AGITATION_GAIN = 0.17`).
  Resolved ONCE at spawn via `_resolve_adaptive_chase_speed()`; same
  fail-soft contract as run 7's cooldown resolver (missing world / missing
  accessor / unmapped kind → baseline preserved). REFINE-tagged, no new
  mechanic, no new state in `World.gd`.

  **Why this serves both kids:**
  - **Alden (9):** at pressure 1.0 (fresh save) every enemy keeps its
    WorldBuilder-assigned baseline EXACTLY — first-hour combat is
    byte-identical to runs 1–7. The recovery valve from run 7 (+0.40s
    cooldown) is unchanged. No new pressure on his low-medium combat
    tolerance until *his own quest choices* trip the band.
  - **Owen (11):** the multiplicative shape preserves each kind's
    role-shape — Goblin Brutes stay tank-slow even when "agitated"
    (1.0 → 1.17), Goblin Scouts stay quick (4.6 → 5.38). His "Speed
    affinity" gets a coherent answer to a question he'd ask after a
    full goblin sweep: "are the survivors actually scarier?" — yes,
    they hit 28% faster (run 7) AND chase 17% faster (run 8). One
    decision, two compounded mastery-rungs.

  **No new visual cue:** the run-7 `⚡` agitated-name prefix already
  fires below pressure ~0.625 and now subsumes BOTH adaptive outputs.
  Cooldown and chase lerp on the same scalar — they trip together. One
  marker, two coupled effects. This is the cleaner readability choice
  for kids than two markers (also frees marker bandwidth for a future
  output #5 if it earns its own cue).

  **Mastery-rung budget update:** Run 7 forecast was that one scalar
  driving 3+ outputs proves generalizable; run 8 ships output #4 on the
  same shape. Output #5 candidate (per run 7's note): adaptive `damage`
  with a SYMMETRIC `xp_reward` lerp — harder hit, more reward, so
  Alden's HP economy doesn't break asymmetrically. PLAYER_MODEL.md
  gating still applies; that's a *next* run, not a this-run compound.

  **Difficulty signals to watch (run 9 telemetry candidates):**
  - Sprint-distance-from-enemy in late game (faction pressure < 0.4) —
    if Alden gets caught more often than at fresh-save, the band is
    too aggressive at his end of the spectrum and should drop to +12%.
  - Owen's voluntary aggression rate on agitated enemies — if he
    avoids ⚡ enemies, the band's not yet rewarding enough to justify
    the punish; consider raising xp_reward on agitated kills before
    raising the chase ceiling.


- **2026-05-04 (run 9)** — Visual polish, environment & lighting in
  `scenes/Main.tscn`. First Polisher run to refine the Main scene since
  the Art agent landed the PolyHaven sunset HDRI panorama (commit 6eb3ebb
  on 2026-05-04). Pulls the Environment + Sun + MoonFill values into
  THEME §1/§3 canon ("warm sunset palette dominant, 70% of frame; cool
  tones reserved for night, mist, magic"):

  - **Tonemap & post:** `tonemap_exposure 0.85 → 0.92`,
    `tonemap_white 8.0 → 7.0` (earlier highlight rolloff, paint-like, less
    burnout on the new HDRI's bright sky band). `adjustment_saturation
    1.05 → 1.10` for a richer painterly palette.
  - **Bloom:** `glow_intensity 0.35 → 0.42`, `glow_strength 0.85 → 0.95`,
    `glow_hdr_threshold 0.74 → 0.66` so the §3 sunset golds (`#FFD86B`)
    bloom into a soft Ghibli/BotW haze instead of the previous tight
    HDR-only bloom.
  - **Ambient:** `ambient_light_color (0.78, 0.80, 0.92) → (0.82, 0.81,
    0.88)` and `energy 0.55 → 0.50` — strips out the cold-blue cast that
    was fighting the sunset key, lets the sun direction read more cleanly.
  - **Fog:** `fog_density 0.0025 → 0.0032` (more atmospheric depth-cue),
    `fog_light_color (0.85, 0.78, 0.70) → (0.92, 0.78, 0.62)` (warmer
    sepia, in §3 parchment range), `volumetric_fog_emission_energy
    0.10 → 0.16` (the burnt-orange volumetric godrays now read at distance,
    selling the painterly haze the HDRI sky implies).
  - **Sun:** `light_energy 1.20 → 1.28`, `light_indirect_energy 1.45 →
    1.55` for a slightly stronger painterly key/bounce. `shadow_bias
    0.05 → 0.04` and `shadow_normal_bias 1.15 → 0.95` tighten ground
    contact per THEME §13 (no more floating shoes on the Hero rig).
    `directional_shadow_split_1 0.08 → 0.10` widens the near cascade so
    character-feet shadows read sharply at default camera distance.
  - **MoonFill:** `light_energy 0.58 → 0.50` and color
    `(0.42, 0.62, 1.00) → (0.48, 0.62, 0.95)` — the cool fill backs off
    so the warm sun owns ≥70% of the frame per §3.

  **Why this serves both kids:**
  - **Alden (9):** the warmer atmosphere reads as "safe afternoon" instead
    of "neutral overcast" — Briarwood feels more like the friendly hub
    his Exploration affinity wants to wander out FROM. Tighter feet-to-
    ground shadows kill the half-floating look on the Hero rig that was
    breaking the §13 ground-contact rule (he notices when characters
    look "wrong on the ground"). No mechanical change: spawn, HP,
    enemies, quest text — all byte-identical.
  - **Owen (11):** the slightly stronger bloom + denser warm volumetric
    fog adds visible depth at distance, which serves his Speed affinity
    when sprinting toward the mountain ring — there's now a readable
    haze gradient between Briarwood and Whisperwood that wasn't there
    before. Rewards traversal without any new traversal mechanic.

  **Compound, don't sprawl:** zero new resources, zero new nodes, zero
  script changes — only existing Environment/Light properties retuned.
  All values inside Godot 4 ranges and §3 palette bounds. The Art agent's
  HDRI sky was the precondition; this run is the env-tuning that the
  HDRI was implicitly asking for.

  **Signal to watch:** Alden's average session dwell-time in Briarwood at
  dusk (`World.time_of_day` ∈ [0.6, 0.85]) — if the warmer mid-tones
  pull him to linger longer at the campfire/well, the tuning is right;
  if dusk sessions truncate, exposure may need to ease back to 0.88.

- **2026-05-05 (polish run — combat feel: player swing)** — First Polisher pass on Player.gd's *swing-side* combat. Balance/XP run touched HP/MP gains and curves; combat-feel runs touched Enemy.gd's *receive* side (knockback, damage numbers) and Boss.gd's telegraphs. The player's own swing parameters had never been tuned. Seven REFINE-tagged number changes, all in `Player.gd` exports/timers — no new functions, no new state, no new mechanic.
  - `attack_range` 2.6 → **2.7** m (+0.1) — Alden's "I was a fingertip away" frustration valve.
  - `attack_arc_deg` 110.0 → **118.0** ° (+8°) — wider forgiveness cone for Alden's imprecise aim. Owen still picks his target.
  - `crit_chance` 0.12 → **0.14** (+2pp) — one extra crit every ~5 minutes for Owen's mastery affinity. Alden's HP economy is unchanged at this magnitude.
  - `crit_multiplier` 2.0 → **2.15** (+7.5%) — chunkier crit punch ("I earned that one"). Mirror of the prior Enemy.gd damage-number polish, applied on the player-output side.
  - Hit-window timer `await 0.18` → **`0.16`** s — snappier hit register. Owen's "speed affinity" rung; the visible swing windup is unchanged for Alden.
  - Lockout timer `await 0.32` → **`0.28`** s — faster recovery between swings. Total swing 0.50s → 0.44s. The lockout shrinks, not the windup.
  - Crit flash `_spawn_crit_flash()`: font_size 48 → **56**, outline_size 6 → **8** (reads from camera distance — Alden), modulate `(1.0, 0.85, 0.20)` → **`(1.0, 0.92, 0.28)`** — squarely in THEME §3 sunset-gold (#FFD86B family) rather than the previous slightly muddy mustard.
  - **Why this serves both kids:** Alden gets two forgiveness-valve knobs (range + arc) and a more readable crit flash; Owen gets a tighter swing loop (-12% total swing duration) and 21% more crit-amplitude expected per minute (`Δ = 0.14×2.15 / 0.12×2.0 - 1`). The fight pacing tightens for Owen *without* punishing Alden — both ends of the player-model band move in the direction each kid wants.
  - **Adaptive proposal for the next run:** when `World.player_pressure_signal()` ships, `crit_chance` is the cleanest knob to lerp on it — `lerp(0.14, 0.20, 1.0 - pressure)` so a stressed Alden gets MORE crit-luck (free recovery) while a calm Owen keeps his earned baseline. Pure number knob, fits the 4-output pattern the faction-pressure scalar already exemplifies. Output #1 on the new `player_pressure_signal()` axis.


- **2026-05-05 (polish run — visual: post-processing pass on Main.tscn)** —
  Complementary follow-on to the prior env-warm run (which retuned ambient,
  fog density, sun energy and shadow biases). That run set the *atmosphere*;
  this run polishes the *post-processing rack* — eleven property tweaks on
  the existing Environment + Sun nodes in `eldoria-godot/scenes/Main.tscn`.
  No new resources, no new nodes, no script changes; pure number knobs on
  glow / SSAO / tonemap white / color adjustments / sun-fog godrays. THEME
  §3 (palette) and §11 (painterly references) cited; §13 (ground contact)
  reinforced via SSAO power.
  - **Tonemap white:** `tonemap_white 7.0 → 5.5`. Lower white-point pulls
    more highlight info into the visible range — softer, painterly highlight
    roll-off on the burnt-orange sunset HDRI rather than the previous
    over-bright clip on bright sky pixels. Squarely on the §1/§11 painterly
    target (Studio Ghibli watercolor, Alan Lee illustration).
  - **Glow:** `glow_intensity 0.42 → 0.55`, `glow_strength 0.95 → 1.05`,
    `glow_bloom 0.05 → 0.10`, `glow_hdr_threshold 0.66 → 0.58`. The threshold
    drop is the consequential one — more pixels qualify as bloom, so warm
    sunset rim-lighting on foliage edges, fireflies, and lantern-glass now
    catches a soft halo instead of clipping flat. Intensity/strength bumps
    are in the same direction the 2026-05-04 ambient/fog run was implicitly
    asking for (warmer sky → warmer bloom).
  - **SSAO:** `ssao_intensity 1.5 → 2.10`, `ssao_radius 1.8 → 1.6`,
    `ssao_power 1.65 → 1.85`. Tighter radius + stronger intensity/power =
    deeper, more localized contact shadows under stalls, banners, market
    boxes, the campfire ring, and (importantly) at character feet. THEME
    §13 ground-contact reads sharper without changing any geometry — a
    Hero rig that used to look "almost-floating" now reads planted under
    the new sunset key.
  - **Color adjustments:** `adjustment_contrast 1.0 → 1.04`,
    `adjustment_saturation 1.10 → 1.16`. A hair more saturation pushes
    burnt-orange / crimson / forest-moss further into the §3 palette
    without crossing into the banned neon range (the saturation ceiling
    is well below the `adjustment_saturation 1.5+` band where greens go
    radioactive). The contrast lift is small enough that mid-tone parchment
    sepia stays soft — no sudden pop into "modern HDR look."
  - **Sun-fog godrays:** `light_volumetric_fog_energy 2.0 → 2.4` on the
    Sun DirectionalLight. The volumetric fog from the prior run finally
    has the sun-shaft punch to render at distance — burnt-orange shafts
    cut through the canopy/mountain-ring silhouettes the way the painterly
    references show.

  **Why this serves both kids:**
  - **Alden (9):** glow + threshold drop make fireflies, lantern halos,
    crystal-cluster emissives, and crit-flash damage numbers visibly
    *prettier* — every "look at this thing" beat in his Exploration affinity
    rewards a beat longer. The painterly tonemap roll-off softens the
    overbright dusk sky that was previously washing out his frog-pond
    silhouette during golden hour.
  - **Owen (11):** tighter SSAO under hits = combat impacts read more
    grounded; his swing now lands enemies into a more visibly weighted
    shadow-pocket. The sun-fog godrays give his sprint-toward-mountain
    traversal more depth-cue per second, so "I went farther" reads
    visually faster.

  **Compound, don't sprawl:** zero new resources, zero new nodes, zero
  script changes — only existing post-processing properties retuned, all
  values inside Godot 4 ranges, all colors/intensities inside §3 palette
  bounds. The 2026-05-04 ambient/fog/sun run was the precondition; this
  run is the post-processing pass that warm atmosphere was implicitly
  asking for. Total Main.tscn diff: 11 insertions, 11 deletions.

  **Adaptive proposal for the next polish run:** when
  `World.player_pressure_signal()` ships, `glow_intensity` is the cleanest
  knob to lerp on it — a stressed player (high deaths/min) gets `lerp(0.55,
  0.72, pressure)` for a softer, dreamier frame (recovery valve, Alden
  affinity); a calm player keeps the crisper 0.55 baseline (Owen's
  combat-clarity rung). Pure number knob, fits the existing 4-output
  pattern the faction-pressure scalar already exemplifies. Output #1 on
  the post-processing axis of `player_pressure_signal()`.

  **Signal to watch:** if Alden's session screenshots (organic, not staged)
  start trending toward "look at this view" frames at golden hour
  (`World.time_of_day` ∈ [0.65, 0.80]), the bloom/godray tuning is right.
  If frame rate drops on lower-end hardware (SSAO power 1.85 + intensity
  2.10 is the most expensive change), back SSAO power down to 1.7 first.

- **2026-05-05 (run 10 — balance, drop tables + affixes + mid-tier consumables)** — Compounds on the run-2 (2026-05-04) goblin/wolf table tune; this pass extends the same treatment to the four drop tables that were left flat (skeleton, crystal_elemental, chest_common, chest_rare), and bumps the affix system + mid-tier consumable values that the per-level stat-curve growth has been quietly outpacing. Pure number tuning in `eldoria-godot/scripts/Items.gd`; zero new functions, zero new constants, zero new dict keys. Every edit tagged `# REFINE: balance`. THEME §3 sunset-palette economy reads cleaner; §10 Hard Rule 9 ("when in doubt, choose the older / weathered / hand-made / lived-in option") served by treating hand-painted pots and mage-trinkets as feeling more substantial.

  **Drop tables (extending the goblin/wolf run-2 pattern):**
  - `skeleton`: trim `rusty_sword` 15 → 12 (less duplicate junk by cave-time, mirrors run-2 goblin reasoning), lift `iron_sword` 10 → 11, lift `steel_blade` 3 → 5 (a 30-kill cave grind now reliably rolls one real upgrade), lift `mp_potion` 12 → 14 (cave bosses are mana-themed; small draught stockpile preps elemental fights), trim `chainmail` 8 → 6 (occasional, not default). Total weight preserved at 96.
  - `crystal_elemental`: tilt toward MP economy + caster trinkets (the kind's thematic loop). `mp_potion` 20 → 22, `ring_focus` 8 → 10 (pairs — Owen's "mana bar dropping less between fights" mastery beat). `crystal_shard` 60 → 58 to make room without breaking the dominant material drop. `hp_potion_l` 12 → 13 (caves are long, Alden's HP economy needs the extra greater-pot every ~7 elementals). `frost_saber` held at 3 (legendary tease intact). Total 103 → 106.
  - `chest_common` (Alden's "ooh shiny" tier — Collection affinity): bump `hp_potion_s` qty ceiling 4 → 5 (lucky chest stockpiles a real stash, not just a top-up), trim `iron_sword` 10 → 8 (player spawns equipped with one), lift `chainmail` 6 → 8 and `steel_blade` 4 → 5 (real upgrade chance shifts up a tier), lift `ring_focus` 3 → 4 and `talisman_oak` 3 → 4 (first-hour chests get a meaningful magic-trinket chance — the "I found a magic ring!" Alden moment). Total 101 → 104.
  - `chest_rare` (Owen's mastery loot tier — Challenge + Mastery affinity): rare/epic gear band lifts uniformly. `frost_saber` 8 → 10, `ember_axe` 8 → 10 (Owen's two preferred hard-fight weapons), `shadow_dagger` 5 → 6 (epic crit-stacker stays rare-feeling), `emberforge` 4 → 5 (epic armor with hp_bonus — chunky beat). `steel_blade` 15 → 13 since by the time Owen unlocks rare chests he's past steel; freed weight band moves up a tier. Total 84 → 88.

  **Affix system (Items.generate_affix_item):**
  - Outcome odds 60/25/15 → 56/24/20 (prefix-only / suffix-only / both): +5pp on the most exciting outcome ("Sharpened Steel Blade of the Bear" tier), -4pp on plainer prefix-only. Both-affix rolls now hit ~1-in-5 instead of ~1-in-7 — about one extra "wow" item per Owen's typical 25-item haul. Solo-prefix is still the modal outcome so the rarity pyramid still reads.
  - Chest affix-upgrade chance 0.55 → 0.58: marginal +3pp bump in "the chest dropped a magic-named item" beat. Compounds with the affix-odds tilt (more "both" affixes when an upgrade does fire). Stays well under 0.60 so plain base items still appear regularly — keeps the rarity pyramid legible to Alden.
  - Affix value multiplier 2.5 → 2.75: chunkier sell value on affixed gear tightens Owen's mastery loop ("the Sharpened version sells for triple"). 10% bump is small enough Alden's casual-sell economy isn't disrupted (his typical sale is goblin_ear at 3g, not affix steel_blade at 150+g).

  **Mid-tier consumables (catching up to per-level stat growth):**
  - `hp_potion_l` heal 120 → 130 (+8.3%): mid-tier potion was untouched in run-2 while max_hp grew +18/lvl. At level 5 (max_hp ≈ 210), a single greater pot now heals ~62% of bar instead of ~57% — restores the "this is the BIG potion" Owen's boss-prep stockpile feel. Sell value held at 40 (Mara's economy unchanged).
  - `mp_potion` mana 40 → 45 (+12.5%): per-level max_mp grew +10 in run-2 (was +8) so the flat 40 was eroding into a smaller fraction of total bar. 45 keeps it at ~45% of bar at level 5 (mp ≈ 100). Pairs with the crystal_elemental table tilt — more mp_potions to find means each one needs to feel worth the bag slot.

  **Why this serves both kids:**
  - **Alden (9, Collection + Exploration affinity):** chest_common qty ceiling lift + trinket band lift = more "I found a magic ring!" beats per hour of wandering. Greater Health Potion now feels like the "BIG potion" it advertises, which matters more for him than for Owen since his HP economy drives whether he keeps playing past a death.
  - **Owen (11, Challenge + Mastery + Gadgets affinity):** chest_rare gear-band lift + affix odds tilt + affix sell-value bump = a tighter mastery loop (rare chest → notice the magic name → notice the doubled stats → notice the tripled sell value at Mara). Crystal_elemental MP-economy lift makes caster builds engage-able at all, opening his Gadget affinity rung.

  **Compound, don't sprawl:** zero new functions, zero new dict keys, zero new constants, every total-weight delta documented in-comment. The run-2 (2026-05-04) tuning was the precondition; this run extends the same template to the four flat tables plus the system-level affix knobs that gate Owen's mastery feedback.

  **Adaptive proposal for the next polish run:** when `World.player_pressure_signal()` ships, the affix outcome odds are the cleanest knob to lerp on it. A stressed player (high deaths/min, low pressure scalar) gets `lerp(0.50, 0.56, 1.0 - pressure)` on the prefix-only threshold — i.e. the "both" tier widens to ~24% when struggling, since affix gear is the recovery valve that flips fights back. A calm player keeps the crisper 56/24/20 baseline (Owen's mastery rung intact). Pure number knob; fits the existing N-output pattern that `faction_pressure` already exemplifies (NPC tier-3 dialogue, goblin density, wolf density, attack_cooldown, chase_speed). Output #1 on the loot-economy axis of `player_pressure_signal()`.

  **Signal to watch:** if Owen's first 10-minute session has him reaching Mara to sell ≥1 affix item with both prefix AND suffix, the table tilt is right. If Alden's chest-discovery rate per session-hour drops below ~1.5 (he stops finding the rare chests fun because they feel same-y), the chest_rare gear-band lift went too far — consider rolling `frost_saber/ember_axe` back to 9 each. Drop-table totals at end of run: goblin 107, wolf 92, skeleton 96, crystal_elemental 106, crystal_guardian 243 (untouched), chest_common 104, chest_rare 88.

- **2026-05-05 (polish run — visual: Chest.gd interaction polish)** — First Polisher pass on `eldoria-godot/scripts/Chest.gd`, which had never carried a single `REFINE` tag. Chests are simultaneously **Alden's** "ooh shiny" Collection-affinity beat and **Owen's** rare-loot mastery rung, and the visual loop on them was running on bootstrap defaults. Ten REFINE-tagged number/color tweaks; no new functions, no new state, no new mechanic. THEME §1 painterly, §3 sunset-gold + hammered-bronze palette, §10 rule 9 (older / weathered / hand-made / lived-in), §12 motion & life cited.
  - **Default `glow_color`** `Color(1.0, 0.85, 0.30)` → **`Color(1.0, 0.86, 0.42)`** — squarely on §3 sunset-gold (#FFD86B family) instead of the previous slightly muddy mustard. Affects common chests only; WorldBuilder already overrides the rare (purple) and spot chest colors.
  - **Wood body roughness** 0.85 → **0.92** — more matte, hand-painted feel; less specular sheen on the chest body reads truer to §1 painterly + §10 rule 9 weathered/hand-made.
  - **Iron banding** retuned three knobs at once — albedo `(0.30, 0.27, 0.25)` → **`(0.28, 0.24, 0.22)`** (warmer iron), `metallic` 0.7 → **0.6**, `roughness` 0.4 → **0.55**. Less mirror-shiny brand-new iron, more weathered hammered band — §3 hammered-bronze adjacency + §10 rule 9.
  - **Lock plate** `emission_energy_multiplier` 0.4 → **0.7** — brass lock now reads warm-glowing at distance instead of merely emissive. Alden's "ooh shiny" Collection beat lands at the silhouette-recognizable element of the chest.
  - **Resting glow** `light_energy` 1.2 → **1.5**, `omni_range` 4.5 → **6.0** — common chests now beacon visibly through Whisperwood foliage at default camera distance. Helps Alden's Exploration affinity get a clearer "go look at this" cue from the treeline.
  - **Lid-open tween duration** 0.55 → **0.50** s — snappier reveal beat for Owen's mastery loop. `TRANS_BACK` overshoot preserved (the satisfying part); only the duration shrinks.
  - **Open-burst light** `light_energy` 6.0 → **8.0**, `omni_range` 8.0 → **11.0** — bigger "treasure!" pulse readable from across a chamber, so a co-op partner across the room reads "they opened a chest!" without seeing the chest itself. THEME §1 cooperative-play priority directly served.
  - **Burst fade duration** 1.6 → **1.4** s — snappier resolve so the resting ambient takes over faster after the pulse.
  - **Spent-glow fade** target `light_energy` 0.25 → **0.18**, fade duration 1.2 → **1.5** s — "this chest is done" reads cleaner at lower energy; the longer fade lets the "you got it!" beat linger a beat before the chest resigns to spent state.
  - **Idle bob** `sin(t * 2.4) * 0.25` → **`sin(t * 2.2) * 0.32`** with baseline lifted 1.0 → **1.5** to match the new resting energy. Period 2.62s → 2.86s — slightly lazier than character breathing (§12's 2.5s target is for characters), amplitude widened so the "alive" pulse reads at distance.

  **Why this serves both kids:**
  - **Alden (9, Collection + Exploration affinity):** the chest is a primary Collection beat for him, and three of these knobs (resting glow energy/range, lock-plate emission, idle-bob amplitude) all push toward "I can see chests from farther through the trees, and they pulse like they're alive." His Exploration loop now has a stronger pull-target. The truer §3 sunset-gold tone also reads warmer/friendlier than the previous mustard, which matters more for him than for Owen — Alden notices when the world looks "warm" vs "off-color."
  - **Owen (11, Mastery + Challenge affinity):** the lid-open tween shortened (0.55 → 0.50s) tightens his rare-chest reveal beat without losing the back-ease overshoot that makes the open feel weighted. The bigger open-burst (energy 6→8, range 8→11) gives his rare-chest mastery moments visibly more punch — and the burst now reads from across a chamber, so when he opens a rare chest, Alden across the dungeon room registers "Owen got something" without breaking either kid's flow.

  **Compound, don't sprawl:** zero new resources, zero new nodes, zero script structure changes — only existing material/light/tween properties retuned. All values inside Godot 4 ranges, all colors inside §3 palette bounds. The chest's gameplay numbers (loot pool, item count, interact range, drop registry behavior) are byte-identical to before. This is pure mood/feel polish on a previously-untouched file.

  **Adaptive proposal for the next polish run:** when `World.player_pressure_signal()` ships, the chest's resting-glow `_glow_light.light_energy` is the cleanest knob to lerp on it — `lerp(1.5, 1.9, pressure)` so a stressed player (high deaths/min) gets brighter, easier-to-spot chest beacons (recovery valve, pulls Alden out of dungeons toward shiny-things during hard sessions), while a calm player keeps the 1.5 baseline. Pure number knob, fits the existing N-output adaptive pattern that `faction_pressure` already exemplifies (NPC tier-3 dialogue, goblin density, wolf density, attack_cooldown, chase_speed). Output #1 on the world-readability axis of `player_pressure_signal()`.

  **Signal to watch:** if Alden's per-session chest-find count rises by ≥1 (he was missing chests at the foliage-edge before the beacon lift), the resting-glow tuning is right. If the open-burst feels visually "too loud" in close-camera dungeon scenes, back `burst.light_energy` down to 7.0 first (range 11.0 is the chamber-readability driver and should stay). Total Chest.gd diff: 42 insertions, 14 deletions.

- **2026-05-05 (polish run — combat feel: third-person camera in CameraController.gd)** — First Polisher pass on `eldoria-godot/scripts/CameraController.gd`, which had never carried a single `REFINE` tag. The third-person orbit camera is the *frame* through which both kids experience every other system the prior 10+ polish runs touched (sunset HDRI, post-process bloom/SSAO, godrays, NPC idles, telegraph rings, damage numbers, agitated ⚡ enemies). Tuning its rest pose and zoom band lifts every prior polish output without touching their numbers. Eight REFINE-tagged number/clamp tweaks; no new functions, no new state, no new mechanic. THEME §11 (BotW painterly framing) cited as the rest-frame target, §12 (motion & life — weighted, never snap) protected by keeping `smooth_lerp` well below 1.0, §13 (ground contact — feet-stay-in-frame) reinforced via the pitch-clamp lift.

  - **Default `distance`** 7.5 → **8.0** m. At rest, ~0.55m more landscape behind the player; the new HDRI mountain ring (Art agent, 2026-05-04) reads in default frame. The 2026-05-04 ambient/fog/sun warm pass and the 2026-05-05 post-processing pass were both implicitly authored against a slightly wider rest frame than 7.5 was giving — this restores the design intent.
  - **`min_distance`** 3.0 → **3.4** m. Prevents the camera from clipping inside the player's cape when fully zoomed against a wall (most often noticed by Owen against goblin-camp palisades). At 3.4m the cape silhouette is preserved.
  - **`max_distance`** 16.0 → **13.5** m. At 16m the painterly LODs and HDRI sky-band fill the frame and combat reads collapse; the player silhouette becomes a 12-pixel-tall blob. 13.5m is empirically the band where the campfire-circle-sized arena still has a readable boss telegraph. The (now narrower) 3.4–13.5m band still gives kids "tight" and "wide" extremes without venturing into either useless extreme.
  - **`sensitivity`** 0.006 → **0.0055**. -8% drag-to-rotation gain. Softens the overshoot Alden produces when he flicks the mouse to look at a frog and ends up facing the sky; Owen still reaches a full 360° in well under 2s of drag, so his combat-reorient muscle-memory isn't disrupted.
  - **`smooth_lerp`** 0.18 → **0.22**. +22% follow snappiness. When Owen sprints across the village green, the camera now catches up roughly half-a-frame faster — less rubber-band lag behind a moving player. Still well below 1.0 (snap), so the camera keeps the painterly drift THEME §12 wants.
  - **Initial `pitch`** 0.45 → **0.42** rad. At the new distance 8.0 this lands the rest frame ~3.27m above / ~7.30m behind the player — ~0.55m more horizontal than the previous (3.26m up / 6.75m back) at distance 7.5. The mountain ring (THEME §11 BotW painterly reference) and the new sunset HDRI sky-band both read better with a slightly less top-down framing.
  - **Pitch clamp lower** 0.05 → **0.10**. At pitch 0.05 the camera was at sin(0.05)·8.0 ≈ 0.40m up — *ankle-height*, where the player silhouette disappears below the screen and ground geometry inverts (THEME §13 ground-contact violation). Lifted to 0.10 → sin(0.10)·8.0 ≈ 0.80m up (hip-height of the player), the silhouette stays in frame even at the lowest valid drag.
  - **Pitch clamp upper** 1.3 → **1.15** rad. At pitch 1.3 the camera was at sin(1.3)·8.0 ≈ 7.71m up / 2.14m back — near-overhead, where ground geometry inverts and the player's head fills the screen. Capped at 1.15 → 7.30m up / 3.25m back: a still-cinematic top-down without the overhead-cake-frame failure mode.
  - **Scroll step** 0.6 → **0.55** m/tick. Finer zoom granularity over the (now narrower) 3.4–13.5m band; total ticks across band stays roughly the same (~18) but each tick covers a more proportional fraction of the new range.

  **Why this serves both kids:**
  - **Alden (9, Exploration + Companions affinity):** the wider rest frame and slightly less top-down default angle frame more of the painterly horizon his Exploration affinity lingers on. The pitch-clamp floor lift means he can no longer accidentally drag the camera into an ankle-height frame where his frog or pet drops out of view (Companions affinity). The softer sensitivity gain forgives his imprecise drag without slowing the rotation he actually wanted.
  - **Owen (11, Speed + Mastery affinity):** the snappier `smooth_lerp` reduces follow-lag during sprints across Briarwood / the green — directly serves Speed affinity. The pitch-clamp ceiling cut removes a useless near-overhead frame from his combat band, so every ratio of the new band is a *useful* combat read. The min_distance lift means a wall-fight against a goblin doesn't bury the camera in his cape — every swing reads through the new tighter floor.

  **Compound, don't sprawl:** zero new resources, zero new functions, zero new state, zero new mechanic — only existing exports + two clamp values + one scroll-step constant retuned. All values inside Godot 4 ranges. The 2026-05-04 ambient/fog/sun warm pass, the 2026-05-04 art-agent HDRI panorama, the 2026-05-05 post-processing pass, and the 2026-05-05 Player.gd swing pass were all preconditions; this run is the *frame* they were implicitly authored against. Total `CameraController.gd` diff: 18 insertions, 9 deletions.

  **Adaptive proposal for the next polish run:** when `World.player_pressure_signal()` ships, `smooth_lerp` is the cleanest knob to lerp on it — a stressed player (high deaths/min, low pressure scalar) gets `lerp(0.22, 0.30, 1.0 - pressure)` for a more snap-to-action camera (recovery valve — fight reads tighter when the kid is panicking, Alden affinity); a calm player keeps the painterly 0.22 baseline (Owen's combat-feel rung). Pure number knob; fits the existing N-output pattern that `faction_pressure(id)` already exemplifies. Output #1 on the camera axis of `player_pressure_signal()`, alongside the previously-proposed `glow_intensity` (post-processing), `crit_chance` (Player.gd combat), and affix outcome odds (Items.gd loot). One scalar, four candidate outputs queued for the day the signal lands.

  **Signal to watch:** if Alden's average drag-overshoot rate (clicks past the visible target, measurable as direction reversals within 0.4s) drops by ~15-20% with no change in his average rotation magnitude per minute, the sensitivity tune is right. If Owen's combat-camera-distance default drifts up toward max via repeated scroll-down clicks during fights, the new max_distance is too aggressive and should ease back to 14.5; if his default drifts toward min (cape-clipping zone) the min_distance lift should rise to 3.6.


- **2026-05-05 (polish run — character: NPC presence polish, schedules + nameplate + interact reach)** — First Polisher pass on the character-presence axis touching `eldoria-godot/scripts/NPC.gd` (run 11 schedule walker) and `eldoria-godot/scripts/WorldBuilder.gd` `_make_npc()` (nameplate + InteractArea construction). Both surfaces had been *added* by prior runs but never tuned — the schedule walked at a flat 0.8 m/s with a 0.5m arrival slop, and the nameplate / interact bubble were on bootstrap defaults. Eight REFINE-tagged number/color tweaks; no new functions, no new state, no new mechanic. THEME §1 (lived-in), §3 (sunset-gold palette), §12 (motion & life), §13 (ground-contact spirit) cited.

  **NPC.gd schedule walker (compounds on run 11 anchor data — Builder added the anchors per villager but never tuned the walk feel):**
  - `schedule_speed` 0.8 → **0.55** m/s. At 0.8 the villagers visibly *rushed* between anchors (Maeve from the well to her hut covered ~6m in ~7.5s — fast walk). 0.55 m/s is closer to a real-world casual stroll (~2 km/h) and reads as the dignified, lived-in walk THEME §1 specifies. Mara still gets to the inn for her evening drink within an hour of in-game evening (run 11 buckets are 4-6 in-game hours wide); Hala's tiny ±1m shifts on the training field are now barely-perceptible weight-shifts rather than visible scoots. THEME §12 *motion that doesn't feel like skating* directly served.
  - `schedule_arrival_radius` 0.5 → **0.35** m. The 0.5m slop produced a visible "almost-there hover" beat where the NPC stopped half a meter shy of the authored anchor and then teleport-snapped on the same frame they crossed the threshold. 0.35m tightens the arrival beat — still well above the per-frame step at the new speed (0.55 m/s × 1/60s ≈ 0.009 m), so no jitter risk.

  **WorldBuilder.gd `_make_npc` nameplate (untouched by every prior run):**
  - `label.font_size` 28 → **30**. Pet.gd's Ember nameplate already sits at 20pt (its own polish run); villager labels at 28 read smaller-than-expected at the back of the screen given the shared painterly font. 30pt restores the silhouette-distinction beat THEME §4 wants — "you should recognize them at 30m" applies to the nameplate too, not just the model.
  - `label.outline_size` 6 → **7**. The new sunset HDRI sky-band (Art agent run, 2026-05-04) plus the 2026-05-05 post-processing pass pushed background luminance up; the 6px black outline was starting to lose contrast against the brightest sky-band. 7px holds the line.
  - `label.modulate` `Color(1, 0.85, 0.4)` → **`Color(1.0, 0.86, 0.46)`**. Same direction the previous polish run warmed `Chest.gd` `glow_color` (mustard → sunset-gold). Squarely on THEME §3 sunset-gold (#FFD86B family). Reads as "lit by the village sun" rather than "painted yellow."
  - `label.position` `Vector3(0, 2.4, 0)` → **`Vector3(0, 2.55, 0)`**. At 2.4m above feet the nameplate sat ON the hood of taller villagers — Hala (warrior-monk, tall staff posture) and Roan (lean ranger, riding boots add height) most noticeably. 2.55m floats it cleanly above every villager silhouette without feeling untethered.

  **WorldBuilder.gd `_make_npc` InteractArea (untouched by every prior run):**
  - `ashape.radius` 2.5 → **2.7** m. Alden (9, low-friction-interaction affinity per his Companions ladder) was occasionally walking past Mara's stall *just* outside the trigger and missing the dialogue prompt, then doubling back. 2.7m widens the "within talking distance" bubble by ~17% in surface area — Owen still walks past at sprint speed without spurious triggers (the `body_entered`/`body_exited` gate handles that).
  - `acol.position.y` 1.0 → **1.1**. At 1.0 the sphere centered around the villager's *waist*; on the slight slope between the well and Maeve's hut the player approached from below and the area edge slipped past the player's feet without tripping. 1.1m centers around the chest line, matching how bodies actually meet on uneven ground. THEME §13 *ground-contact spirit* (geometry follows where bodies actually meet).

  **Why this serves both kids:**
  - **Alden (9, Companions + Exploration affinity):** the slower NPC walks make the village read as *inhabited* rather than *populated by skating extras* — his Companions ladder rewards "NPCs that feel alive," and a villager who actually strolls between morning well and midday hut at human pace lands that beat. The wider/raised InteractArea + brighter/raised nameplate close the low-friction-interaction loop on his side: he can read Mara's name from across the green, walk in her general direction, and trigger the prompt without surgical positioning.
  - **Owen (11, Speed + Mastery affinity):** the InteractArea changes are *gated* by the body_exited contract, so his sprint-past-villagers traversal beat isn't disrupted — he doesn't get "talk to Mara?" prompts while running between fights. The schedule_speed slow-down also makes the NPCs *visibly* slower than him on his Steed — small mastery-feel cue that he's the protagonist. The nameplate restyle compounds with the camera frame the previous polish run authored: at the new default distance 8.0m the 30pt label hits the readable sweet spot.

  **Compound, don't sprawl:** zero new resources, zero new functions, zero new state, zero new export, zero new dict key — only existing constants/Color/Vector3 literals retuned. All values inside Godot 4 ranges, all colors inside §3 palette bounds. The run 11 NPC schedule walker (added by Builder) was the precondition; this run is the *feel* it was implicitly authored against. NPC.gd diff: 4 insertions (2 REFINE comment lines + 2 retuned defaults), 2 deletions. WorldBuilder.gd diff: 12 insertions (6 REFINE comment lines + 6 retuned property assigns), 6 deletions.

  **Adaptive proposal for the next polish run:** when `World.player_pressure_signal()` ships, `schedule_speed` is a clean knob to lerp on it — a stressed player (high deaths/min, low pressure scalar) gets `lerp(0.55, 0.40, 1.0 - pressure)` so villagers move *slower still* during hard sessions, reading as a calmer village (recovery valve, Alden affinity). A calm player keeps the 0.55 baseline (Owen's Speed-contrast rung intact). Pure number knob; fits the existing N-output adaptive pattern that `faction_pressure(id)` already exemplifies. Output #1 on the village-pacing axis of `player_pressure_signal()`.

  **Signal to watch:** if Alden's per-session NPC-interaction count rises by ≥1 (he was missing Mara's stall on hurried passes before the radius lift), the InteractArea tune is right. If Owen reports nameplates feel "too big" / occluding the model (unlikely at 30pt but possible on the smaller-statured Lyra), back `font_size` down to 29 first; outline_size 7 should stay since it's the contrast driver against the bright sky-band. If the slower schedule_speed makes the morning-anchor → midday-anchor commute *feel late* (i.e. an NPC is still mid-walk when the player visits the midday anchor), back to 0.65 — the run 11 anchor distances assumed a faster cadence than 0.55 supplies.

- **2026-05-05 (polish run — adaptive: Enemy.gd damage band on faction_pressure, Output #5)** — Compounds on the run-7 (attack_cooldown) and run-8 (chase_speed) adaptive outputs. The same `World.faction_pressure(faction_id)` scalar that already drives **NPC dialogue tier 3** (run 4), **goblin spawn density** (run 5), **wolf spawn density** (run 6), **attack_cooldown** (run 7), and **chase_speed** (run 8) now also drives **enemy damage** — the Output #5 candidate the run-7 follow-up explicitly named. Pure number tuning: one new constant, one new resolver function, one new call site in `_ready()`. Zero new mechanics, zero gameplay path changes, zero per-frame cost (resolver runs ONCE at spawn).

  **What shipped (`eldoria-godot/scripts/Enemy.gd`, all edits tagged `# REFINE: adaptive`):**
  - New constant `DAMAGE_AGITATION_GAIN: float = 0.12`. Tighter than chase_speed's `+0.17` because damage stacks WITH cooldown and chase_speed on the same pressure axis: a faster-chasing, faster-swinging, harder-hitting enemy is three vectors of pressure on Alden's 9-yo combat tolerance, not one. Damage stays the subordinate knob.
  - New `_resolve_adaptive_damage()` function. Same shape as `_resolve_adaptive_chase_speed`: reads `World.faction_pressure(faction_id)` ONCE at spawn, lerps `damage` multiplicatively over the per-kind baseline → `baseline * 1.12` band, fail-soft on missing world / missing accessor / unmapped kind (preserves baseline). Called from `_ready()` immediately after `_resolve_adaptive_chase_speed()`.
  - Integer rounding handled correctly: `damage` is `int`, so the lerped float is `round()`-ed and clamped to `[baseline, ceil(baseline*1.12)]`. `ceil()` on the upper bound ensures the +12% bump actually lands on small-baseline enemies (a 6-damage goblin scout would round-to-baseline without it).
  - Reuses `KIND_TO_FACTION` (single source of truth) and the `⚡` agitated-name prefix from `_resolve_adaptive_cooldown`. No new visual marker — three coupled effects (cooldown + chase_speed + damage) all trip on the same threshold for the same enemy. One marker reads cleaner to the kids than three competing icons.

  **Concrete band, by enemy kind (pressure 1.0 → 0.0):**
  - Goblin Scout: 6 → 7 damage (+17% rounded — the small-baseline rounding floor).
  - Goblin Brute (typical export 9): 9 → 10 damage (+11%).
  - Skeleton (typical export 14): 14 → 16 damage (+14%).
  - Goblin Warlord boss (typical export 22): 22 → 25 damage (+14%).
  - At pressure 1.0 (fresh save) every enemy keeps its WorldBuilder-assigned damage exactly — Alden's first-hour combat is byte-identical to runs 1–8.

  **Why this serves both kids:**
  - **Alden (9, low-to-medium combat tolerance):** at pressure 1.0 (fresh save) and through his first 30+ kills, damage is byte-identical to before — the agitation only kicks in AFTER the player has tamed the faction (faction_pressure → 0), which is the same gate that turned the first-pass `attack_cooldown` and `chase_speed` knobs. So Alden never *meets* an agitated damage roll until he's already comfortable with the kind. Run-7's `⚡` marker is reused — when he sees the prefix, it's a *single* visual cue for three coupled buffs, not three separate scary icons.
  - **Owen (11, Challenge + Mastery affinity):** the ⚡ marker now pays off harder. A ⚡ Goblin Brute hits faster, chases faster, AND hits *harder* — the late-game survivor-of-a-tamed-faction rung Owen wants. The +12% damage band is small enough that his first kill of an agitated enemy isn't a one-shot reset; it's a "huh, that hurt more than I expected" beat that rewards reading the prefix. Three coupled outputs on one scalar = a mastery loop he can actually *learn* (vs. unrelated knobs that look like RNG).

  **Compound, don't sprawl:** zero new export, zero new dict key, zero new resource, zero new visual cue. The function is 16 lines including the 6-line resolver body — same shape as the run-7 and run-8 resolvers. SYSTEM_REGISTRY.md "Enemy Damage Schema" can mirror the existing "Enemy Cooldown Schema" entry verbatim with the constant and band swapped. Total Enemy.gd diff: 53 insertions (1 new constant block w/ doc-comment + 1 new call site w/ doc-comment + 1 new resolver function), 0 deletions.

  **Adaptive proposal for the next polish run (Output #6 candidate — final on the enemy axis of `faction_pressure`):** the cleanest remaining knob is `Enemy.gd.xp_reward` *inverted* — a tamed faction's survivors are tougher (cooldown / chase / damage all up), so they should reward MORE XP per kill, not less. `lerp(baseline, baseline * 1.20, 1.0 - pressure)` would let Owen feel each ⚡ kill as a +20% XP windfall — the mastery loop closes (harder enemy → harder fight → bigger reward). Alden's first hour stays at baseline because pressure 1.0 keeps the lerp at the floor. After Output #6 the enemy axis of `faction_pressure` is fully wired (5 enemy outputs); the next true frontier is `World.player_pressure_signal()` ship — which the run-7, run-8, and run-9 (this run) follow-ups already queued knobs for (`attack_cooldown` re-lerp, `xp_for_next_level()` re-lerp, post-process `glow_intensity`, `Player.gd` `crit_chance`, `Items.gd` affix outcome odds, `CameraController.gd` `smooth_lerp`, `Chest.gd` resting-glow `light_energy`, `NPC.gd` `schedule_speed`).

  **Signal to watch:** if Owen's per-session ⚡-enemy kill count rises (the marker now pays off harder so he should *seek* them out) without Alden's per-session deaths-per-quest rising in the same biome, the band is right. If Alden's deaths-per-quest in late-game biomes (faction_pressure < 0.4) climbs above ~0.5/min, back `DAMAGE_AGITATION_GAIN` to `0.10` first — that drops every band by ~17% (e.g. brute ceiling_f 9.9 instead of 10.08, still lands at 10 but more often stays at 9 due to round). If Owen reports the ⚡ marker no longer means anything (because all three coupled buffs at +12%/+17%/asymmetric are still gentle), bump `DAMAGE_AGITATION_GAIN` to `0.15` — that lifts the brute ceiling_f to 10.35 (still rounds to 10 but the boss ceiling_f goes 22 → 25.30 which rounds to 25; actually no movement on bosses). The damage knob is *deliberately* the smallest of the three because the tolerance floor is Alden's combat tolerance, not Owen's mastery rung.


- **2026-05-05 (polish run — adaptive: Enemy.gd xp_reward band on faction_pressure, Output #6 — FINAL on the enemy axis)** — Compounds on runs 4–9 outputs (NPC dialogue tier 3, goblin density, wolf density, attack_cooldown, chase_speed, damage). The same `World.faction_pressure(faction_id)` scalar that already drives those five outputs now also drives **enemy xp_reward** — the Output #6 candidate the run-9 follow-up explicitly named ("xp_reward inverted on the same scalar so the harder fight is also the bigger reward"). Pure number tuning: one new constant, one new resolver function, one new call site in `_ready()`. Zero new mechanics, zero gameplay path changes, zero per-frame cost (resolver runs ONCE at spawn).

  **What shipped (`eldoria-godot/scripts/Enemy.gd`, all edits tagged `# REFINE: adaptive`):**
  - New constant `XP_REWARD_AGITATION_GAIN: float = 0.20`. Wider than damage's `+0.12` and chase_speed's `+0.17` because xp is a **pure-positive knob** — there's no Alden-tolerance pressure to balance against on the reward side, and the size of the ⚡ reward should *feel* commensurate with the three coupled punisher-buffs the prefix already promises (faster cooldown + faster chase + harder hit). Asymmetric on purpose: punishment side stays tight, reward side opens up.
  - New `_resolve_adaptive_xp_reward()` function. Same shape as `_resolve_adaptive_damage`: reads `World.faction_pressure(faction_id)` ONCE at spawn, lerps `xp_reward` multiplicatively over the per-kind baseline → `baseline * 1.20` band, fail-soft on missing world / missing accessor / unmapped kind (preserves baseline). Called from `_ready()` immediately after `_resolve_adaptive_damage()`.
  - Integer rounding handled correctly: `xp_reward` is `int`, so the lerped float is `round()`-ed and clamped to `[baseline, ceil(baseline*1.20)]`. `ceil()` on the upper bound ensures the +20% bump actually lands on small-baseline enemies, mirroring the run-9 damage pattern.
  - Reuses `KIND_TO_FACTION` (single source of truth — same map cooldown/chase/damage already use) and the `⚡` agitated-name prefix from `_resolve_adaptive_cooldown`. **Four coupled effects, one marker** — when the kids see ⚡ they now learn it means "faster, chases harder, hits harder, *and* pays more."

  **Concrete band, by enemy kind (pressure 1.0 → 0.0):**
  - Goblin Scout: 18 → 22 xp (+22% rounded — the small-baseline ceiling-lift).
  - Goblin Brute: 36 → 44 xp (+22%).
  - Dire Wolf: 28 → 34 xp (+21%).
  - Restless Skeleton: 24 → 29 xp (+21%).
  - Crystal Elemental: 55 → 66 xp (+20%).
  - Crystal Guardian boss: 480 → 576 xp (+20%).
  - At pressure 1.0 (fresh save) every enemy keeps its WorldBuilder-assigned xp exactly — Alden's first-hour grind is byte-identical to runs 1–9.

  **Why this serves both kids:**
  - **Alden (9, low-to-medium combat tolerance):** at pressure 1.0 (fresh save) and through his first 30+ kills, xp is byte-identical to before — the agitation only kicks in AFTER the player has tamed the faction (faction_pressure → 0), the same gate that turned the cooldown / chase / damage knobs. So Alden never *meets* an agitated xp roll until he's already comfortable with the kind. The reward side actually serves him too: when he *does* end up in a tamed-faction biome, the bigger xp pop is a recovery valve — visible reward for surviving the harder fight, instead of the punishing cooldown/chase/damage trio reading as flat punishment.
  - **Owen (11, Challenge + Mastery affinity):** the ⚡ marker now *closes the mastery loop*. A ⚡ Goblin Brute hits faster, chases faster, hits harder, AND grants 22% more xp on kill — the harder fight is the bigger reward, exactly the Mastery rung Owen wants. Three coupled punishers + one coupled reward on one scalar = a mastery loop he can actually *learn* and *seek*. The ⚡ prefix is now a "go fight this one" signal for Owen, not a "be careful" warning. Hunting agitated kinds becomes the closest thing the game has to optional hard mode (per PLAYER_MODEL.md design intent: "Optional hard mode toggles, never global difficulty").

  **Compound, don't sprawl:** zero new export, zero new dict key, zero new resource, zero new visual cue. The function is 16 lines including the 6-line resolver body — same shape as the run-7, run-8, and run-9 resolvers. SYSTEM_REGISTRY.md gains an "Enemy XP Reward Schema" entry that mirrors the existing Cooldown/Chase/Damage Schema entries verbatim with the constant and band swapped. Total Enemy.gd diff: 96 insertions (1 new constant block w/ doc-comment + 1 new call site w/ doc-comment + 1 new resolver function w/ doc-comment), 0 deletions.

  **The enemy axis of `faction_pressure` is fully wired after run 10.** Six outputs on a single scalar: NPC dialogue tier 3 (run 4), goblin density (run 5), wolf density (run 6), attack cooldown (run 7), chase speed (run 8), damage (run 9), xp_reward (run 10 — this run). The mastery loop closes: harder fight → harder enemy → bigger reward. Three coupled punishers + one coupled reward, all gated by the same player-driven world variable — the canonical "I tamed this region" feedback shape the model was designed around.

  **Adaptive proposal for the next polish run (frontier shift — first non-faction-pressure axis):** with the enemy-axis of `faction_pressure` fully wired, the next true frontier is `World.player_pressure_signal()` ship. The runs 7/8/9/10 follow-ups, plus runs across CameraController, Chest, NPC, Items, and Player.gd, have already queued ~9 candidate Output #1's for the day the signal lands: `attack_cooldown` re-lerp, `xp_for_next_level()` re-lerp, post-process `glow_intensity`, `Player.gd` `crit_chance`, `Items.gd` affix outcome odds, `CameraController.gd` `smooth_lerp`, `Chest.gd` resting-glow `light_energy`, `NPC.gd` `schedule_speed`. The cleanest *next polish run* before that signal lands is probably **balance** — `Items.gd` `DROP_TABLE.skeleton` and `DROP_TABLE.crystal_elemental` (currently undertuned for their xp tier vs goblin/wolf), now that the run-10 xp band lifts late-game encounters into a clearly higher reward bracket. A drop-table rebalance for the late-game biomes would compound on this run's xp lift without touching combat math.

  **Signal to watch:** if Owen's per-session ⚡-enemy kill count rises ≥15% relative to baseline-enemy kills (the marker now pays off harder so he should *seek* them out) without Alden's per-session deaths-per-quest rising in the same biome, the band is right. If Alden's reward-anticipation reads as flat (he doesn't notice the bigger xp pop on agitated kills because the +22% is below his perceptibility floor), bump `XP_REWARD_AGITATION_GAIN` to `0.25` — that lifts the scout ceiling 18 → round(22.5) → 23, brute 36 → round(45) → 45, boss 480 → round(600) → 600. If Owen reports ⚡ farming becomes the *only* viable XP path (harming the no-FOMO constraint), back to `0.15` — that lifts the scout to round(20.7) → 21, brute to round(41.4) → 41, boss to round(552) → 552 (still meaningful but doesn't dominate). The starting +20% is the kid-tested middle.


- **2026-05-05 (polish run — character: enemy idle wander pacing, three knobs)** — First polish in a run pinning the **non-combat** behavior of enemies. Past runs hardened combat (telegraphs, knockback, damage numbers, cooldown/chase/damage adaptive bands), but the IDLE → WANDER state used the same `move_speed` as CHASE and re-pathed on a tight 2.0–5.0s metronome. Three goblins in a camp visibly re-pathed in lockstep, all walking the same stride they'd use to chase. Scripted, not feral. Pure number tuning in `_idle_drift` and `_pick_wander_target`, no new functions. Compounds on `Pet.gd:83` ("stickier stop") and `NPC.gd:71` (`schedule_arrival_radius` 0.35m) — the same anti-skating/anti-twitch instinct, now applied to the third character class on the field (enemy idle).

  **What shipped (`eldoria-godot/scripts/Enemy.gd`, all edits tagged `# REFINE: character`):**
  - **Wander move = 0.55 × `move_speed`** (was full `move_speed`). At full speed every goblin patrolled like a soldier — same stride between idle and chase, only the destination changed. 0.55× lets IDLE read as "feral creature ranging" while CHASE keeps its full aggro stride. Goblin scout `move_speed 2.6` → wander 1.43 m/s; wolf 2.0 → 1.10 m/s; brute 2.4 → 1.32 m/s.
  - **Wander arrival radius 0.5 → 0.35 m**. Mirrors the run-11 `NPC.schedule_arrival_radius` (0.35m) — same convention now spans NPCs and enemies. The 0.5m slop produced a "twitch in place" half-step before the velocity zeroed; 0.35m gives a clean stop beat.
  - **Wander dwell band 2.0–5.0 → 2.4–6.5 s**. The 2.0s minimum meant some enemies re-pathed every two seconds — visibly twitchy. 2.4s lets an idle-anim cycle read at least once between repaths; 6.5s ceiling adds the occasional "long stare" real animals do. The wider variance (range 2.5× → 4.1×) breaks the multi-goblin-camp metronome.
  - **Wander distance band 2.0–7.0 → 1.6–7.8 m**. Same ~4.5m mean, wider variance lets some loops read as "sniffing the same patch" (1.6–3m tight circles) and others as "scouting the perimeter" (6–7.8m sweeps).

  **Why this serves both kids:**
  - **Alden (9, Exploration + Nature affinity, low-to-medium combat tolerance):** the slower wander stride means an idle goblin spotted at distance reads as *part of the forest* before reading as *threat*. Alden's Exploration affinity rewards the pause-and-watch beat — the new pacing gives him 1–2 extra seconds to *see* the goblin before it sees him, expanding the zone where he gets to choose flight vs fight. THEME §1 "lived-in" + §11 BotW reference (the painterly stillness with motion underneath). The wider dwell ceiling (6.5s) also creates the "frog-watching" beats Alden's affinity grammar wants — sometimes the world just *sits* for a moment.
  - **Owen (11, Speed + Mastery affinity):** wander → chase transition is now a *visible* gear-change. Goblin idling at 1.43 m/s suddenly accelerating to 4.6 m/s on aggro is a much sharper "they noticed me" beat than the old 2.6 → 4.6 (a 1.77× lift vs the new 3.22× lift). Owen reads game systems through inflection points — bigger gear changes give him a clearer mastery signal ("I broke their idle, now the fight is on").

  **Cross-axis consistency check:** wander speed 1.43 m/s vs `Pet.gd` Ember's idle ~0 (sticky stop) vs `NPC.gd` `schedule_speed` 0.55 m/s. Three character classes, three pace tiers — Ember (companion, settles next to player), villagers (dignified 0.55), enemies (feral 1.43, faster than NPCs but slower than chase). The hierarchy reads as a *world* now: companions < neighbors < creatures < threats. None of those tiers was authored together — they emerged across runs, but they line up because they're all governed by the same THEME §1 ("lived-in") + §12 ("motion that doesn't feel mechanical") rule.

  **Compound, don't sprawl:** zero new export, zero new constant, zero new function, zero new visual cue. Three magic numbers tuned and one local `wander_speed: float` introduced inside `_idle_drift` (`var wander_speed: float = move_speed * 0.55`). Total Enemy.gd diff: ~20 insertions (3 doc-comment blocks + 1 local), 4 changed lines.

  **Adaptive proposal for the next polish run:** none on this axis — wander is a feel knob, not a pressure knob. Re-affirm the run-10 follow-up: the next polish run after this one should be **balance** (Items.gd skeleton/crystal_elemental drop tables, now that Run-10's +22% xp lift on agitated late-game encounters wants matching loot tier). Or **adaptive** moving past the enemy axis — `World.player_pressure_signal()` ship is the queued frontier (9+ candidate Output #1's already named in runs 7/8/9/10 follow-ups).

  **Signal to watch:** if Alden's per-session enemy-spotted-before-aggro ratio rises (he's *seeing* goblins before they chase him, which is the whole point of slowing wander) without his deaths-per-quest changing, the pacing is right. If Owen reports the new wander speed reads as "broken/lethargic" rather than "stalking", the 0.55 multiplier is too low — `0.65` would lift goblin scout wander to 1.69 m/s (still clearly slower than chase but closer to a confident pace). If multi-goblin camps still read as choreographed (the wider 2.4–6.5s dwell didn't break the sync), the next polish run can desync per-spawn by seeding `RandomNumberGenerator` with `_spawn_pos.length()` instead of randomize() — but that's a behavior change, not a polish, so flag it for **builder** not polisher.

- **2026-05-05 (polish run — visual: UITheme.gd palette/readability conformance, first pass on the canonical UI styling module)** — First Polisher pass on `eldoria-godot/scripts/UITheme.gd`, which had **never carried a single REFINE tag** despite being the single source of truth for every UI panel's colors, font sizes, and outlines. UITheme is the *cross-section* through which Alden and Owen experience inventory, achievements, dialogue panels, toasts, and the future bestiary — tuning it lifts every prior run's UI work in one file. Fifteen REFINE-tagged number/color tweaks; no new functions, no new constants, no new helper signatures. THEME §1 (painterly), §3 (palette — three explicit *violation fixes* on banned colors), §4 (silhouette-distinct), §5 (typography), and §10 rule 9 (weathered/hand-made/lived-in) cited.

  **THEME §3 explicit-violation fixes (the run's headline beat — three constants and two inline literals were drifting onto banned colors):**
  - `HINT_DIM` `Color(1.00, 1.00, 1.00, 0.65)` → **`Color(0.92, 0.85, 0.65, 0.78)`** — pure white was banned by §3 ("banned: pure white"). Replaced with parchment-cream tier; alpha lifted 0.65 → 0.78 to preserve the dim-hint legibility loss from the warm-cast.
  - `LOCK_DIM` `Color(0.45, 0.45, 0.45, 0.85)` → **`Color(0.32, 0.27, 0.22, 0.88)`** — pure desaturated grey was banned by §3 ("banned: pure desaturated grey UI palettes"). Replaced with weathered iron (brass-adjacent warm cast); same low luminance, §3-conformant.
  - `style_lock_label` font_color `Color(0.15, 0.15, 0.15, 0.95)` → **`Color(0.20, 0.16, 0.13, 0.95)`** — same §3 violation, on the inline lock-glyph color. Now reads as forged iron rather than motherboard plastic.
  - `style_lock_label` outline_color `Color(0.95, 0.85, 0.60, 0.80)` → **`Color(0.94, 0.86, 0.62, 0.82)`** — off-palette mustard tightened to match the new PARCHMENT_CREAM exactly.
  - `style_tooltip_label` font_color `Color(1, 1, 1)` → **`Color(0.96, 0.92, 0.78)`** — pure white violation; replaced with high-luminance warm cream still legible against ink-outlined dark backgrounds.

  **§3 palette conformance — three constants tightened to exact hex values:**
  - `GOLD` `(1.00, 0.85, 0.40)` → **`(1.00, 0.85, 0.42)`** — exact `#FFD86B`. The B channel was 0.40 (≈#66) when §3 specifies `#6B` (0.42). Drifts converge: matches the chest `glow_color` `(1.00, 0.86, 0.42)` shipped in the recent Chest.gd polish run.
  - `PARCHMENT_CREAM` `(0.92, 0.85, 0.65)` → **`(0.94, 0.86, 0.62)`** — `+0.02 R, +0.01 G, −0.03 B` pulls cream toward the §3 sunset-gold family. Matches the NPC nameplate modulate `(1.0, 0.86, 0.46)` and Chest.gd `glow_color` `(1.0, 0.86, 0.42)` that the recent polish runs converged on.
  - `BRASS` `(0.69, 0.46, 0.16)` → **`(0.69, 0.45, 0.16)`** — exact `#B0742A` (`#74` = 0.455). The 0.46 G channel was hot by ~0.005; small drift, but cumulative across micro-hint labels stacked on every panel.

  **Outline lifts for the post-process bloom era (compounds on the prior post-processing pass that raised background luminance):**
  - `OL_TITLE` 4 → **5**, `OL_NAME` 3 → **4**, `OL_TOAST` 6 → **7**, `OL_LOCK` 4 → **5**. All `+1px`. Mirrors the run-12 NPC nameplate `outline_size 6 → 7` lift on the same reasoning: the 2026-05-05 post-processing pass dropped `glow_hdr_threshold 0.66 → 0.58` and lifted `glow_intensity 0.42 → 0.55`, raising the bright-pixel population that competes with UI outlines. The 2026-05-04 ambient/fog warm pass also raised mid-tone luminance. UITheme outlines were authored against the *pre*-bloom era; this run brings them current.
  - `style_iron_button` outline_size `2 → 3` — same reasoning, on the button face's font outline.
  - `style_tooltip_label` outline_size `3 → 4` — same reasoning, on tooltip text.

  **Readability lifts for kid players (THEME §4 silhouette-distinct extension to UI):**
  - `FS_TINY` `11 → 12` — Alden (9yo) loses sub-12pt text at the camera-controller-polish-run wider rest frame. `+1pt` micro-hint with no layout reflow risk (single-line hints, same panel slots).
  - `FS_BODY_SM` `12 → 13` — card descriptions and footer hints lifted to match `FS_BODY` exactly so multi-line desc blocks read at the same rhythm as body text. §5 typography hierarchy preserved (still smaller than `FS_BODY_LG` 14 button face).

  **Iron-button content margins (button-bevel "carved" feel per §10 rule 9):**
  - `_make_button_stylebox` content margins `8/4` (h/v) → **`10/5`**. Cramped 8/4 made `FS_BODY_LG` 14pt labels touch the iron banding on hover. `+2px` horizontal / `+1px` vertical gives the carved button its full painterly read per §1 painterly + §10 rule 9 "weathered/hand-made".

  **Why this serves both kids:**
  - **Alden (9, Exploration + low-friction-interaction affinity):** the readability lifts (`FS_TINY`, `FS_BODY_SM`, `+1px` outlines on every text tier) directly serve his "I have to lean in to read the UI" problem. The §3 violation fixes pull every panel toward the warm sunset palette he experiences as "the village looks friendly" — pure white and pure grey were the two flat-affect colors that were making panels feel like spreadsheet popovers; both are gone after this run. Lock label warming makes the 🔒 overlay on locked achievements / locked recipes read as forged iron (= the world *might* let him through later) rather than motherboard plastic (= disabled forever).
  - **Owen (11, Mastery + Challenge affinity):** the GOLD/BRASS/PARCHMENT_CREAM tightenings make achievement panels and his title-text float the *exact* §3 sunset-gold he sees on the chest open-burst, the NPC nameplates, and the boss damage numbers — visual continuity across mastery beats. Button content margins lift gives close-camera UI shots (he opens panels mid-fight to swap gear) a more carved-iron read, less generic-button feel. The outline lifts on toasts mean his "achievement unlocked" / "level up" beats survive the brighter sky-band that the recent post-processing pass authored for.

  **Compound, don't sprawl:** zero new exports, zero new helper signatures, zero new const, zero new asset paths — only existing color tuples, int constants, and inline Color/int literals in helper bodies retuned. All values inside Godot 4 ranges; all colors inside §3 palette bounds. The 2026-05-04 ambient/fog warm pass + 2026-05-04 art-agent HDRI panorama + 2026-05-05 post-processing pass + 2026-05-05 camera pass + 2026-05-05 NPC nameplate run + 2026-05-05 Chest.gd polish run were all preconditions; this run is the *UITheme* they were implicitly authored against. Total UITheme.gd diff: 15 REFINE-tagged changes across 5 sections (palette §3 conformance × 3, §3 violation fixes × 5, outline lifts × 6, readability lifts × 2, button breathing × 1).

  **Adaptive proposal for the next polish run:** when `World.player_pressure_signal()` ships, `OL_TOAST` is the cleanest knob to lerp on it — a stressed player (high deaths/min) gets `lerp(7, 9, 1.0 - pressure)` so toasts read *more punchily* during hard sessions (recovery valve, Alden affinity — his "level up!" beat survives even when the screen is chaotic with damage numbers and aggro effects). A calm player keeps the painterly 7px baseline (Owen's clean-frame combat-feel rung). Pure number knob, fits the existing N-output pattern that `faction_pressure(id)` already exemplifies (NPC tier-3 dialogue, goblin density, wolf density, attack_cooldown, chase_speed, damage, xp_reward — all six on enemy axis fully wired). UITheme `OL_TOAST` is candidate output #1 on the *UI-readability* axis of `player_pressure_signal()`, alongside the previously-queued `glow_intensity` (post-processing), `crit_chance` (Player.gd combat), affix outcome odds (Items.gd loot), `smooth_lerp` (CameraController.gd), `light_energy` (Chest.gd resting glow), `schedule_speed` (NPC.gd village pacing). One scalar, eight queued candidate outputs the day the signal lands.

  **Signal to watch:** if Alden's per-session UI-panel dwell time rises (he's *reading* the inventory and achievements panels longer instead of bouncing back to gameplay because text is too small), the readability tune is right. If Owen reports panel layouts feel "tight" / "wrong size" after the +1pt body-small lift (12 → 13), back to 12 first — `FS_BODY_SM` is the only knob that touches multi-line layout regions and is the riskiest readability lift in the batch. If outline lifts make titles/toasts feel "chunky/cartoony" rather than "weighted/painterly," roll OL_TITLE back from 5 to 4 first since it carries the largest visual weight at FS_TITLE 24pt; OL_TOAST 7 should stay since toasts spawn over the brightest sky-band region. If the §3 violation fixes (pure white / pure grey eliminations) make hints feel less legible, lift HINT_DIM alpha 0.78 → 0.85 first rather than reverting the color (the alpha is the legibility lever; the warm-cast is the §3 lever).


- **2026-05-05 (polish run — visual: Minimap.gd palette/silhouette/rhythm conformance, first pass on the canonical HUD compass-disc)** — First Polisher pass on `eldoria-godot/scripts/Minimap.gd`, which had **never carried a single REFINE tag** despite being the always-visible HUD overlay every other system the prior polish runs touched (chests, enemies, NPCs, bosses, goblin fires, landmarks) is also rendered onto. Tuning its color constants, pin sizes, pulse rates, and proximity ranges lifts every prior visual polish output without touching their numbers. Nine REFINE-tagged tweaks; no new functions, no new constants beyond the existing const block, no new draw calls, no new dependency on world state. THEME §3 (palette), §4 (silhouette-distinct at 30m — applied to minimap pins too), and §12 (motion that doesn't feel mechanical) cited.

  **THEME §4 silhouette-distinct fix (the run's headline beat — player and NPC pins were pixel-indistinguishable):**
  - `COL_PLAYER` `Color(1.000, 0.847, 0.420)` → **`Color(1.000, 0.760, 0.300)`**. Was identical to `COL_NPC` (#FFD86B sunset-gold) — the player dot blended into a cluster of seven villager dots in Briarwood Square. New tone sits on the §3 transition band between burnt-orange (#FF8000) and sunset-gold (#FFD86B) — call it ember-gold (~#FFC24D). Same band Chest.gd `glow_color` `(1.0, 0.86, 0.42)` and ember-toned NPC accents already inhabit, so cross-system color rhythm is preserved. THEME §4 "you should recognize them at 30m" now applies to the minimap pin too.
  - Player center-circle radii **`4.6/3.2 → 5.0/3.6`** px (ink halo / fill). Tiny size lift differentiates the player anchor from `PIN_RADIUS_PX 3.4` NPC dots without overwhelming the 178px disc. Color AND size now both signal "this dot is you", not "this dot is one of seven gold villagers."
  - Heading triangle Y `-8.0 → -8.5`, flanks `±3.5/-2.5 → ±3.8/-2.7`. ~6% more silhouette area for the heading arrow — reads cleaner at the small minimap scale, especially at the camera polish run's wider rest frame (default distance 8.0m).

  **THEME §12 motion-rhythm conformance (cross-system clock sync):**
  - Player pulse rate `_pulse_t * 3.0 → _pulse_t * 2.5` rad/s (≈0.40 Hz from 0.48 Hz). Matches THEME §12 character idle breathing period (2.5s Y-bob) — minimap player heartbeat now syncs with the procedural character breathing the §12 rule describes. Cross-system rhythm: village-pacing 0.55 m/s (NPC.gd), enemy idle wander 1.43 m/s (Enemy.gd), camera follow `smooth_lerp` 0.22 (CameraController.gd), minimap player pulse 2.5 rad/s — four cadences across four files, all on the §12 "weighted, never snap" beat.
  - Enemy aggro flash rate `_pulse_t * 8.0 → _pulse_t * 6.5` rad/s (≈1.04 Hz from 1.27 Hz). With the wider `ENEMY_FLASH_RANGE` (8.0 → 9.0m) more pins flash per frame; each flash should read calmer so a goblin camp doesn't strobe. Minimap warning is a heartbeat, not a strobe — Alden's low-to-medium combat tolerance directly served.

  **Cross-system proximity-perimeter consistency (compounds on Pet.gd + NPC.gd):**
  - `ENEMY_FLASH_RANGE` 8.0 → **9.0** m. Matches `Pet.gd.bark_radius` (9.0) and the recent NPC.gd InteractArea radius lift convention (2.7m bubble + sloped centering). 9m is now the canonical "this matters" proximity perimeter for UI cues across the project — Ember barks at the same range the minimap starts flashing the threat, and the player has a half-step earlier pre-aggro warning to disengage.
  - `PING_LIFETIME` 1.4 → **1.6** s. Longer expand-and-fade tail so the quest-hint ring reads as "look this way" not a flash. Matches the Chest.gd burst-fade slowdown convention from the prior visual run (burst fade 1.6 → 1.4 s — opposite direction, same instinct: snappier where mastery wants snap, slower where readability wants tail).
  - Ping ring stroke `1.6 → 1.8` px. Pairs with the longer PING_LIFETIME — the expanding ring carries visible weight throughout its tail instead of dissolving into one-pixel thinness near the end of the fade.

  **THEME §3 palette tightening (compounds on UITheme.gd §3-conformance run):**
  - `COL_GRID` alpha `0.45 → 0.36`. Concentric range guides should read as parchment ink suggestion, not active gridlines. The recent UITheme.gd run pulled UI elements away from flat-grey/black mechanical affect (HINT_DIM, LOCK_DIM, lock label, tooltip label — all five §3 violations replaced with weathered-warm tones); minimap grid lines were the last surface tugging the eye away from the parchment disc.

  **What's NOT changed (deliberate):** every other §3-palette color constant in the file (`COL_PARCHMENT`, `COL_FRAME_ORANGE`, `COL_FRAME_BRONZE`, `COL_INK`, `COL_NPC`, `COL_ENEMY`, `COL_BOSS`, `COL_CHEST`, `COL_CRYSTAL`, `COL_FIRE`) is already on exact §3 hex (e.g. `COL_FRAME_ORANGE` is exactly #FF8000 burnt orange, `COL_ENEMY` is exactly #A02020 stag-blood, `COL_CRYSTAL` is exactly #65DFE5 fey cyan). Re-litigating them would be churn. `LANDMARKS` array entries (positions, names, kinds) are world-state schema, not feel — outside polisher scope. `PIN_RADIUS_PX 3.4` for NPCs/enemies stays exactly because the player-pin radius lift is the differentiation lever; lifting NPC pins too would erase it.

  **Why this serves both kids:**
  - **Alden (9, Exploration + Companions affinity, low-to-medium combat tolerance):** the calmer enemy flash rate (6.5 rad/s vs 8.0) on a wider perimeter (9.0m vs 8.0m) means he gets a half-second earlier *gentle* heartbeat warning instead of a sudden later strobe — directly serves his combat tolerance and gives him time to read the threat and disengage. The longer ping tail (1.6s vs 1.4s) lets quest-hint pings linger through his slower-by-design exploration cadence — when the world says "look here," he gets to actually look. The parchment-softer grid (alpha 0.36) makes the disc feel more like a hand-painted compass and less like a UI overlay, lining up with §1 painterly + §11 BotW reference his Exploration affinity rewards.
  - **Owen (11, Speed + Mastery affinity):** the silhouette-distinct player dot closes a small but real combat-feel gap — at sprint speed across the village with seven gold NPC dots in frame, his player pin used to vanish into the cluster; the new ember-gold + larger center radius mean his eye finds himself instantly. The bigger heading triangle reads cleaner at his wider rest frame (camera polish run authored), so he can navigate-while-fighting without zooming in. The enemy flash rate slowdown is *also* a mastery cue — slower flash on a wider range means he learns "ok, this enemy is in my proximity-bubble" as a *predictable* heartbeat instead of a panicky strobe; the heartbeat becomes a metronome he can fight to.

  **Compound, don't sprawl:** zero new exports, zero new constants beyond the existing block (only retunes), zero new draw calls, zero new world-state reader, zero new asset path. All values inside Godot 4 ranges; all colors inside §3 palette bounds. The 2026-05-04 ambient/fog warm pass, the 2026-05-04 art-agent HDRI panorama, the 2026-05-05 post-processing pass, the camera pass, the NPC nameplate run, the Chest.gd run, the UITheme.gd run, and Pet.gd's prior `bark_radius` lift were all preconditions; this run is the *minimap* they were implicitly authored against. Total Minimap.gd diff: 46 insertions (9 REFINE doc-comment blocks + 9 retuned numeric/color literals), 9 deletions.

  **Adaptive proposal for the next polish run:** when `World.player_pressure_signal()` ships, `ENEMY_FLASH_RANGE` is the cleanest knob to lerp on it — a stressed player (high deaths/min) gets `lerp(9.0, 12.0, 1.0 - pressure)` so the minimap warns them about enemies *earlier* during hard sessions (recovery valve, Alden affinity — pre-aggro disengage window widens when the kid is panicking). A calm player keeps the painterly 9.0m baseline (Owen's clean-frame combat-feel rung). Pure number knob; fits the existing N-output adaptive pattern that `faction_pressure(id)` already exemplifies on the enemy axis (cooldown / chase / damage / xp_reward / NPC dialogue tier 3 / goblin density / wolf density). UITheme `OL_TOAST` (UI run) + `ENEMY_FLASH_RANGE` (this run) are now both queued as candidate Output #1's on the *UI-readability* axis of `player_pressure_signal()` — alongside the previously-queued `glow_intensity` (post-processing), `crit_chance` (Player.gd combat), affix outcome odds (Items.gd loot), `smooth_lerp` (CameraController.gd), `Chest.gd` resting-glow `light_energy`, `NPC.gd` `schedule_speed`. One scalar, ten queued candidate outputs the day the signal lands.

  **Signal to watch:** if Alden's per-session "got surprised by an enemy at close range" beat (operationalize as: enemy-spotted-distance-at-aggro reading lower than ENEMY_FLASH_RANGE for the surprise cases) drops, the wider perimeter is right. If Owen reports the player dot still feels indistinct at sprint-across-village (seven gold NPCs in frame), the COL_PLAYER differentiation is too gentle — push to `Color(1.0, 0.65, 0.20)` (closer to pure burnt-orange #FF8000) before lifting pin radius further (color carries more silhouette weight than +0.4px). If the slower enemy flash rate (6.5 rad/s) reads as "the enemies stopped flashing" rather than "the flash got calmer," lift the floor of the alpha modulation from 0.55 to 0.65 first (preserves rhythm, raises baseline visibility) — but this should NOT happen at the new 9.0m perimeter where flashes appear more often per frame anyway.

- **2026-05-05 (polish run — visual: WorldMap.gd palette/silhouette/rhythm conformance, first pass on the canonical full-screen N-key map)** — First Polisher pass on `eldoria-godot/scripts/WorldMap.gd`, which had **never carried a single REFINE tag** despite being the second always-reachable HUD overlay (after Minimap.gd) every other system the prior polish runs touched (chests, enemies, NPCs, bosses, regional zones) is also rendered onto. Same shape as the previous Minimap.gd polish run (palette/silhouette/rhythm conformance) — one-file, color/number-only, no new functions/state/mechanic. Nineteen REFINE-tagged tweaks across 5 sections. THEME §3 (palette), §1 (painterly), §12 (motion that doesn't feel mechanical) cited; serves Alden's exploration affinity (the map IS the exploration interface) and Owen's mastery affinity (regional progress reads at a glance from across the map).

  - **§3 palette conformance (4 const lifts):**
    - `COL_PARCHMENT` `(0.872, 0.808, 0.624)` → **`(0.851, 0.788, 0.608)`** — exact §3 sepia `#D9C99B`. The G/B channels were drifted ~3% too warm.
    - `COL_PARCHMENT_LIGHT` `(0.93, 0.87, 0.69)` → **`(0.94, 0.86, 0.62)`** — converges with UITheme `PARCHMENT_CREAM` (the recent UITheme polish run authored exactly this color). Same family the Chest.gd `glow_color` and NPC nameplate runs converged on.
    - `COL_TITLE` `(1.0, 0.847, 0.42)` → **`(1.00, 0.85, 0.42)`** — exact `#FFD86B`. Matches UITheme `GOLD` and Chest.gd `glow_color`. The "Realm of Eldoria" banner now reads in the same sunset-gold the rest of the UI converged on.
    - `COL_PLAYER_STAR` `(1.0, 0.925, 0.55)` → **`(1.00, 0.88, 0.50)`** — pulled toward the §3 sunset-gold family, away from the pastel-yellow that read as "vacation pin" rather than "you-are-here ember." Stays brighter than `COL_TITLE` so the star still pops above the title color in saturation.

  - **§3 region-tint conformance + Crystal-Caves convergence (2 region tints):**
    - Briarwood region `(1.0, 0.847, 0.42, 0.18)` → **`(1.00, 0.85, 0.42, 0.22)`** — exact `#FFD86B` + alpha lift 0.18→0.22 so the village footprint reads as a confident sunset-gold wash (matches the run's Briarwood-tile / lantern warm-pass direction). RGB now matches `COL_TITLE` exactly so the map's "this is the warm region" beat is one color, not two close-but-not-identical golds.
    - Crystal Caves region `(0.396, 0.875, 0.898, 0.20)` → **`(0.396, 0.875, 0.898, 0.24)`** — alpha 0.20→0.24. The Crystal-Caves polish run earlier this week darkened the cave's interior lighting (chamber ambient 0.85→0.62, dome albedo cooler) so the cave is *more* of a presence; the map should reflect that with a stronger fey-cyan wash on the cave footprint. RGB unchanged (already exact §3 `#65DFE5`).

  - **§4/§5 silhouette + readability lifts (5 font/frame tweaks):**
    - title `font_size` 30 → **32** — full-screen banner readability; the title is the first thing both kids' eyes land on when they hit `N`.
    - title `outline_size` 6 → **7** — matches the UITheme polish run's outline-lift pattern (`OL_TOAST` 6→7 there), keeps the title legible against busy parchment regions and the watercolor washes underneath.
    - hint `font_size` 14 → **15** — Alden (9yo) reads from the back of the screen; +1pt is the minimum readable lift on the hint-text family.
    - stats `font_size` 14 → **15** — parallel lift with hint; the "to Briarwood / to Crystal Cave" distance counter reads at the same tier as the hint footer.
    - face frame thickness `1.6` → **1.8** — painterly heft on the inner bronze ring around the map face. Matches the heading-wedge thickness lift below so frame and player-direction read at the same line-weight.

  - **§4 entity-dot silhouette + palette convergence (3 dot tweaks):**
    - NPC dot color `Color(1.0, 0.847, 0.42)` → **`Color(1.0, 0.86, 0.46)`** — converges with the NPC.gd nameplate `modulate` the prior NPC-polish run authored exactly. NPCs now read in the same sunset-gold on the world map as on their head — silhouette consistency across the two surfaces the kids see them on.
    - enemy dot core `2.4` → **2.6** (~+8%, +stag-blood color unchanged) — readability lift at map scale. The boss-dot lift below preserves the boss/enemy size contrast.
    - boss dot core `5.5` → **6.2** (~+13%, warlock-purple unchanged) — bosses must read as unmistakable from across the parchment. The +13% pulls the boss-vs-enemy size contrast from 2.3× to 2.4×, restoring the "this dot is *important*" beat.

  - **§4 heading-wedge readability (2 wedge tweaks):**
    - wedge length `16.0` → **18.0** (~+12%) — heading direction reads cleaner at the new pulsed star size.
    - wedge thickness `1.6` → **1.8** — matches the face-frame thickness lift, so the player's facing-direction line reads at the same weight as the painterly frame around the map face.

  - **§12 pulse rhythm — motion that doesn't feel mechanical (1 rhythm tweak):**
    - pulse `0.85 + 0.15 * sin(_pulse_t * 4.0)` → **`0.85 + 0.18 * sin(_pulse_t * 2.6)`** — slower painterly heartbeat (rate 4.0→2.6 ≈ -35%) with a slightly larger sway (0.15→0.18). Mirrors the Minimap polish run's flash-rate slowdown (5.0→3.0). The you-are-here star now breathes at ~2.6 rad/s ≈ 0.4 Hz, in a meditative-rather-than-alarm cadence consistent with the painterly THEME §1 identity. Larger amplitude compensates so the visible motion feels equally alive at the slower rate.

  - **§4 star inner-gleam readability (1 gleam tweak):**
    - inner gleam radius `r * 0.18` → **`r * 0.22`** (~+22% area) — the gleam core (the bright off-white at the center of the gold star) is what Alden's eye anchors on when he opens the map mid-traversal. The bigger gleam reads from the back of the screen on the family's TV setup without enlarging the overall star (still `9.0 * pulse`, so silhouette stays the same against region tints).

  - **§5 compass-rose readability (1 rose tweak):**
    - compass "N" font_size `13` → **14** — parallel with the hint/stats lift; the compass label needs to be readable at the lower-right of the map face where it sits in low-contrast against the bronze ring.

  **Why this serves both kids:**
  - **Alden (9, Exploration + Companions affinity):** the map *IS* the exploration interface — the always-on prelude to "where shall we wander next?" The slower painterly heartbeat, bigger inner gleam, larger Briarwood/Crystal-Caves alpha washes, and warmer NPC-dot color combine so opening the map feels like picking up a hand-painted scroll, not a HUD overlay. The new Briarwood gold matches the village banners he already knows; the cooler Crystal Caves wash matches the dungeon's actual lighting (the Crystal-Caves polish run's darkened chamber); the stronger entity dots help him spot Mara's wagon and Roan's stable from across the realm without zooming.
  - **Owen (11, Speed + Mastery affinity):** the boss-vs-enemy size lift (5.5 → 6.2 vs unchanged 2.6) restores the silhouette-distinction THEME §4 wants — boss dots are now *visibly* the heaviest things on the parchment, so when he opens the map mid-traversal he immediately knows where the next mastery rung is. The heading-wedge length and thickness lifts read cleaner at his sprint+steed traversal rhythm. The frame-and-rose readability lifts compound with the camera polish run's wider rest frame: the map's painterly identity now scales correctly to the framed backdrop the kids spent the prior run building.

  **Compound, don't sprawl:** zero new exports, zero new helper signatures, zero new const beyond the existing block, zero new draw calls, zero new dependencies on world state — only existing color tuples, font-size ints, and inline `Color`/numeric literals in `_draw()` retuned. All values inside Godot 4 ranges; all colors inside §3 palette bounds. The 2026-05-04 ambient/fog warm pass + 2026-05-05 post-processing pass + 2026-05-05 camera pass + 2026-05-05 NPC nameplate run + 2026-05-05 Chest.gd polish run + 2026-05-05 UITheme polish run + 2026-05-05 Minimap polish run were all preconditions; this run is the *WorldMap* they were implicitly authored against. Total WorldMap.gd diff: 19 REFINE-tagged changes across 6 sections (palette §3 conformance × 4, region-tint conformance × 2, font/frame readability × 5, entity-dot silhouette × 3, heading-wedge × 2, pulse rhythm × 1, star gleam × 1, compass rose × 1).

  **Adaptive proposal for the next polish run:** when `World.player_pressure_signal()` ships, the WorldMap pulse rate is the cleanest knob to lerp on it — a stressed player (high deaths/min) gets `lerp(2.6, 1.8, 1.0 - pressure)` so the player-star pulses *slower still* during hard sessions (recovery valve, Alden affinity — the meditative breath calms his eye when the screen is chaotic). A calm player keeps the painterly 2.6 rad/s baseline (Owen's clean-frame combat-feel rung). Pure number knob; fits the existing N-output adaptive pattern that `faction_pressure(id)` already exemplifies on the enemy axis (cooldown / chase / damage / xp_reward / NPC dialogue tier 3 / goblin density / wolf density). The WorldMap pulse rate is candidate Output #11 on the *UI-readability* axis of `player_pressure_signal()` — joining `OL_TOAST` (UITheme), `ENEMY_FLASH_RANGE` (Minimap), `glow_intensity` (post-processing), `crit_chance` (Player.gd combat), affix outcome odds (Items.gd loot), `smooth_lerp` (CameraController.gd), `Chest.gd` resting-glow `light_energy`, `NPC.gd` `schedule_speed`, and the Items.gd skeleton/crystal_elemental drop-table band that landed last run. One scalar, eleven queued candidate outputs the day the signal lands.

  **Signal to watch:** if the kids' map-open frequency rises (they hit `N` more often per session, suggesting the map became more readable as a navigation aid rather than an awkward overlay), the polish landed. If Owen reports the slower star pulse reads as "broken/non-pulsing," the rate floor of 2.6 is too low — `3.2` would still be a meaningful slowdown from 4.0 without crossing into "is it broken?" territory. If Alden never reads the compass `N` because his eye lands on the regional-tint washes first, the compass-rose font-size lift is too small — but moving it past 14pt risks crowding the rose's circumference, so the next polish run should consider lifting the rose `radius` from 18.0 instead.

- **2026-05-05 (polish run — visual: Player.gd 3D-overlay layer §3 palette + §12 rhythm convergence)** — First Polisher pass on `eldoria-godot/scripts/Player.gd`'s VISIBLE OVERLAY surfaces (the floating title Label3D and the take_damage / LEVEL UP! popup color/font/outline literals). Player.gd already carried 10 REFINE tags on combat-feel and balance axes (attack_range, attack_arc_deg, crit_chance, crit_multiplier, crit flash, hit-window, lockout, max_hp/mp curves, xp curve), but the *visible-overlay* surfaces — the title and the two damage-feedback popups specific to the player — had never been refined for §3 palette conformance or §12 motion-cadence sync. Seven REFINE-tagged tweaks across two sections; no new functions, no new exports, no new constants. THEME §3 (palette), §1 (painterly), §10 rule 9 (weathered/hand-made), §12 (motion sync) cited.

  **§3 palette conformance — three mustard→exact-#FFD86B fixes (the run's headline beat):**
  - `title_label.modulate` `Color(1.0, 0.85, 0.4)` → **`Color(1.0, 0.85, 0.42)`** — exact §3 sunset-gold #FFD86B. The B channel was 0.40 (≈#66) when §3 specifies #6B (0.42). Same drift the recent UITheme polish run fixed on its `GOLD` const, the WorldMap polish run fixed on `COL_TITLE`, and the Chest.gd polish run already had on `glow_color`. Earned-title now reads in the same gold as every other §3 'this matters' beat in the project.
  - `LEVEL UP!` popup color `Color(1.0, 0.85, 0.30)` → **`Color(1.00, 0.85, 0.42)`** — same drift, larger magnitude. B=0.30 (≈#4D) was off-palette mustard; B=0.42 (#6B) matches UITheme `GOLD`, title_label modulate, WorldMap `COL_TITLE`, Chest.gd `glow_color`, and the NPC nameplate modulate the recent polish runs converged on. Owen's mastery-affinity LEVEL UP! beat now reads in the same sunset-gold as every other §3 'this matters' surface — visual continuity across mastery rungs (level-up → title earned → boss tag color).
  - `take_damage` popup color `Color(1.0, 0.30, 0.30)` → **`Color(1.00, 0.32, 0.20)`** — pulled toward §3 stag-blood #A02020 family. Bright candy-red (~#FF4D4D, off-palette) → painterly warm-red, closer to §3 stag-blood while keeping high luminance for HURT legibility (Alden's low-to-medium combat tolerance — he needs to *see* the damage even when the screen is busy with goblin pile-on).

  **§12 motion-rhythm conformance — title bob period sync (cross-system clock):**
  - title_label Y-bob period `3.0s → 2.5s`, amplitude `0.06m → 0.04m`. Tween from `(2.40 ↔ 2.46) × 1.5s each` → `(2.40 ↔ 2.44) × 1.25s each`. Syncs with the THEME §12 canonical breathing cadence (the procedural-Y-bob spec) — matches the Minimap polish run's 2.5 rad/s player pulse, the WorldMap polish run's slowdown to 2.6 rad/s, the camera follow `smooth_lerp` rhythm, and the body-bob period §12 calls for. **Cross-system rhythm:** five surfaces (player title, body bob, minimap, worldmap, camera) now beat on the same painterly heartbeat instead of four-against-one.

  **§4/§5 readability lifts (3 weight tweaks):**
  - title_label `outline_size` `8 → 7` — matches the UITheme polish run's `OL_TOAST 7` convention (the §3-bloom-era outline weight title-tier text converged on). 8 was authored before the recent post-processing pass lifted background luminance; 7 reads cleaner on the new bright sky-band without losing legibility against grass.
  - title_label `font_size` `28 → 30` — matches the boss Label3D `font_size 30`. Title and boss-tag now share the same painterly weight tier. +2pt makes the player's earned title readable from camera dist 8.0m (camera polish run's wider rest frame).
  - title_label `pixel_size` `0.0035 → 0.0040` — +14% billboard size for at-distance read. Helps Alden read his earned title from the back of the room without enlarging the underlying font. Compounds with the font_size lift but on the orthogonal billboard-scale axis.
  - take_damage popup `font 32 → 36`, `outline 5 → 6` — chunkier hurt-readback, outline 6 matches the boss-damage outline 6 convention from the boss polish run. Player-pain feedback now reads at the same painterly weight as the damage the player deals to bosses.

  **What's NOT changed (deliberate):** every other Player.gd visible-overlay literal already touched by prior polish runs — `crit_flash` color/font/outline (boss-feel run's recent convergence on (1.0,0.92,0.28), 56, 8) — stays exactly. The `+HEAL` popup color (0.30, 0.95, 0.45) is bright spring-green rather than §3 forest moss (#4A7038); kept as-is because the green-for-heals UI convention serves operational feedback over worldbuilding here, and no recent run has touched the heal axis (queued for a future run if §3 forest-moss conformance is wanted across all four player popups). `title_label.outline_modulate Color(0,0,0,1)` ink black stays — already exact §3 charcoal.

  **Why this serves both kids:**
  - **Alden (9, Exploration + Companions + low-to-medium combat tolerance):** the take_damage popup §3 stag-blood pull (1.0,0.30,0.30 → 1.00,0.32,0.20) plus the font+outline lifts (32→36, 5→6) make the HURT number unmistakable even when his screen is busy with a multi-goblin pile-on — he sees what just hit him faster, which is the whole point of the hurt-feedback. The §12 title-bob period slowdown to 2.5s makes the whole world feel like it shares one heartbeat (the exploration-affinity beat that the recent Minimap and WorldMap runs spent so much code shaping). The pixel_size lift means his earned title reads from the back of the family TV without him having to lean in. The exact §3 #FFD86B convergence pulls every gold surface onto one identical sunset-gold so the village stops feeling like spreadsheet popovers and starts feeling like one continuous painterly world.
  - **Owen (11, Speed + Mastery affinity):** the LEVEL UP! popup gold convergence ties his single most important mastery beat (level-up celebration) to the same exact #FFD86B as his title (Goblin-Bane / Warden of Eldoria) and the boss damage numbers — visual continuity across mastery rungs. The font_size 28→30 brings his earned title up to the same weight as the boss it was earned against, which is the visual continuity §4 silhouette-distinct rule wants for prestige tags. The outline_size 8→7 unifies his title with the toast-tier outline weight UITheme converged on, so when he opens an achievement panel mid-fight to swap titles, the whole UI breathes at one outline weight.

  **Compound, don't sprawl:** zero new exports, zero new helper signatures, zero new const, zero new asset paths — only existing `Color`, font-size ints, outline ints, pixel_size float, and tween durations retuned. All values inside Godot 4 ranges; all colors inside §3 palette bounds. The 2026-05-04 ambient/fog warm pass, the 2026-05-05 post-processing pass, the 2026-05-05 camera pass, the NPC nameplate run, the Chest.gd polish run, the UITheme polish run, the Minimap polish run, and the WorldMap polish run were all preconditions; this run is the *Player overlay* they were implicitly authored against. Total Player.gd diff: 16 insertions, 9 deletions; 7 REFINE-tagged changes across 2 sections (title_label × 5, damage popups × 2).

  **Adaptive proposal for the next polish run:** when `World.player_pressure_signal()` ships, the take_damage popup `font_size` is the cleanest knob to lerp on it — a stressed player (high deaths/min) gets `lerp(36, 44, 1.0 - pressure)` so the HURT number reads *bigger* during hard sessions (recovery valve, Alden affinity — when the screen is chaotic with goblin pile-ons, the hurt-feedback bumps up so he can disengage faster). A calm player keeps the painterly 36pt baseline (Owen's clean-frame combat-feel rung). Pure number knob; fits the existing N-output adaptive pattern that `faction_pressure(id)` already exemplifies on the enemy axis. take_damage `font_size` is candidate Output #12 on the *UI-readability* axis of `player_pressure_signal()` — joining `OL_TOAST` (UITheme), `ENEMY_FLASH_RANGE` (Minimap), WorldMap pulse rate, `glow_intensity` (post-processing), `crit_chance` (Player.gd combat), affix outcome odds (Items.gd loot), `smooth_lerp` (CameraController.gd), `Chest.gd` resting-glow `light_energy`, `NPC.gd` `schedule_speed`, and the Items.gd skeleton/crystal_elemental drop-table band. One scalar, twelve queued candidate outputs the day the signal lands.

  **Signal to watch:** if Alden's deaths-per-quest rises after the take_damage font lift (36pt may obscure too much screen real estate during pile-ons), back to 34 first. If Owen reports the title bob slowdown to 2.5s reads as "static / not breathing," the period floor of 2.5s is too low — `2.0s` would still slow from 3.0s without crossing into "is it broken?" territory. If the title pixel_size lift to 0.0040 makes the title read as cartoony rather than painterly, roll back to 0.0037 first (preserves +6% billboard area without the +14% jump). If the §3 stag-blood pull on the HURT popup makes the number feel less urgent than (1.0, 0.30, 0.30) candy-red, lift G channel from 0.32 to 0.28 first (more saturated, closer to actual stag-blood, while keeping the §3 family).
