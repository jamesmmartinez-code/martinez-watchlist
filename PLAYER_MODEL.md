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
