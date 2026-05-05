# System Registry — Realm of Eldoria

Canonical schemas for everything the engine manipulates. If a new system needs
to look up "what verbs exist?" or "what fields does an item have?", this is
the single answer. Update this whenever a schema changes.

## Verbs (player actions)

| Verb       | Input             | Source script   | Notes                                |
|------------|-------------------|-----------------|--------------------------------------|
| move       | WASD / Arrows     | Player.gd       | walk_speed=5.5, run_speed=9.0        |
| jump       | Space             | Player.gd       | velocity=5.5                         |
| interact   | E                 | Player.gd / NPC | range-based, dialogue / loot         |
| attack     | Left-click        | Player.gd       | 110° arc, 2.6m range                 |
| quaff      | Inventory click   | Inventory.gd    | consumables                          |
| equip      | Inventory click   | Inventory.gd    | weapon / armor / trinket             |
| mount      | M                 | Player.gd       | Horse / mount swap                   |
| loot       | Walk-over / E     | Chest.gd / drop | weighted DROP_TABLE rolls            |

## Stat Schema (Player)

| Field            | Type   | Default | Notes                            |
|------------------|--------|---------|----------------------------------|
| hp / max_hp      | int    | 120/120 | death triggers respawn at well   |
| mp / max_mp      | int    | 30/30   | not yet consumed                 |
| xp               | int    | 0       | level-up curve in Player._gain_xp|
| level            | int    | 1       | scales attack_damage_base        |
| gold             | int    | 50      | quest + loot rewards             |
| crit_chance      | float  | 0.12    | weapon crit_bonus stacks         |
| crit_multiplier  | float  | 2.0     | flat                             |
| attack_damage_base | int  | 14      | + level scaling                  |

## Combat Formulas

```
roll_damage = attack_damage_base + level_bonus + weapon.damage + variance
if rng < crit_chance + weapon.crit_bonus: roll_damage *= crit_multiplier
incoming = enemy.damage * (1.0 - armor_reduction)   # currently flat 0.15
```

## Item Schema

Common fields (Items.gd):
- `name: String` — display
- `type: String` — `weapon | armor | trinket | consumable | material`
- `slot: String` — `weapon | armor | trinket | ""`
- `rarity: String` — `common | uncommon | rare | epic | legendary`
- `icon: String` — emoji glyph
- `color: Color`
- `value: int` — gold sell price

Type-specific:
- weapon: `damage: int`, `crit_bonus: float?`
- armor:  `armor: int`, `hp_bonus: int?`
- trinket: `hp_bonus?`, `mp_bonus?`, `crit_bonus?`
- consumable: `heal: int?`, `mana: int?`, `stack: bool`
- material: `stack: bool` (used by fetch quests)

Rarity colors → standard MMO palette (white/green/blue/purple/orange).

## Drop Tables

Defined in `Items.DROP_TABLE`. Entries: `{id, weight, qty:[min,max]}`.
Currently keyed: `goblin`, `wolf`, `goblin_warlord`, `skeleton`,
`crystal_elemental`, `bandit` (entries vary). New enemy kinds MUST add a drop
table entry; do not let an enemy ship without loot.

## Status Effects

NONE shipped yet. Reserved schema for downstream runs:
```
{ id: String, duration_s: float, tick_s: float, on_tick: Callable, color: Color }
```
First implementation should add: `bleed`, `slow`, `burn`, `poison`.

## Quest Reward Schema

A quest may grant any combination of:
- `xp_reward: int`
- `gold_reward: int`
- `reward_item: String, reward_item_qty: int`
- `consequence: String` — *reserved*, see QUEST_GRAMMAR.md (faction shifts,
  NPC memory flags, world flags). Not yet wired.

## NPC Schema

Defined in `WorldBuilder.NPCS`. Fields:
- `name: String`, `role: String`, `pos: Vector3`, `tint: Color`,
  `line: String` (default dialogue, used as last-resort fallback)
- `lines: Array[String]` — 4 mood-bucketed time-of-day variants
  (morning / midday / evening / night).

✅ **Shipped 2026-05-04 (run 3 — integrator + follow-up): Reactive dialogue.**
NPC.gd consults World on each interaction and walks 4 tiers, picking the
first hit:

1. `warm_flag: String` + `warm_lines: Array[String]` (4 buckets).
   Fires when `World.npc_has_flag(npc_name, warm_flag)` returns true.
   Personal warmth: "you helped *me*". Shipped by integrator.
2. `warm_world_flag: String` + `warm_world_lines: Array[String]` (4 buckets).
   Fires when `World.has_world_flag(warm_world_flag)` returns true AND
   tier 1 didn't already match. World warmth: "you helped our cause."
   Shipped by run-3 follow-up. Reads `World.world_flags`, which had no
   other consumer until now.
3. `warm_faction_id: String` + `warm_faction_below: float` +
   `warm_faction_lines: Array[String]` (4 buckets).
   Fires when `World.faction_pressure(warm_faction_id) < warm_faction_below`
   AND neither flag tier already matched. Faction-shape warmth: "the world
   has changed in a measurable way." Shipped by run 4 (Maeve, secondary
   tier behind her `warm_flag`); generalized by run 8 (Roan, ONLY warming
   tier — no `warm_flag` and no `warm_world_flag`). Run 8 proves the
   schema works as the SOLE warming channel: any NPC can speak any
   faction's state with a 3-field data edit (`warm_faction_id`,
   `warm_faction_below`, `warm_faction_lines`). Reads
   `World.faction_pressure()`, which now has 4 runtime consumers
   (NPC.gd dialogue tier 3 — multiple NPCs / multiple factions —
   plus WorldBuilder spawn density — goblins + wolves — plus Enemy.gd
   adaptive cooldown).
4. `lines: Array[String]` (the mood-bucketed default).
5. `line: String` (single fallback).

`_make_npc()` copies these fields onto the NPC node:
- `npc.warmed_flag` ← `data.warm_flag`
- `npc.warmed_dialogue_variants` ← `data.warm_lines`
- `npc.warmed_world_flag` ← `data.warm_world_flag`
- `npc.warmed_world_dialogue_variants` ← `data.warm_world_lines`
- `npc.warmed_faction_id` ← `data.warm_faction_id`
- `npc.warmed_faction_below` ← `data.warm_faction_below` (default 1.0)
- `npc.warmed_faction_dialogue_variants` ← `data.warm_faction_lines`

Authoring rules:
- `warm_flag` MUST match a flag actually written by some quest's
  `consequence` — see WORLD_STATE.md "NPC Memory" table for the live set.
- `warm_world_flag` MUST match a key in `World.world_flags` — see
  WORLD_STATE.md "World Flags (Active)".
- `warm_faction_id` MUST match a key in `World.factions` — see
  WORLD_STATE.md "Faction State". `warm_faction_below` is a strict
  less-than threshold against `pressure` (range [0.0, 1.0]); use 0.9 / 0.7 /
  0.5 / 0.3 for "any reduction" / "noticeably safer" / "halfway tamed" /
  "definitively tamed".
- Warmed arrays SHOULD have exactly 4 entries (one per time bucket); a
  shorter array clamps to its last entry via `min(bucket, size-1)`.

**Authoring traps (run-4 lesson learned):**
- ⚠ Do NOT pair a faction reducer with the same quest that issues the NPC's
  `warm_flag` *if the NPC's faction tier targets that same faction*. The
  warm_flag tier always wins once set, so the faction tier can only fire
  before the warm_flag is earned — i.e. before the only quest that would
  reduce the faction. Result: unreachable dialogue. Fix: target a DIFFERENT
  faction with the faction tier, OR pick a threshold reachable by a
  different quest's reducer. Maeve targets `whisperwood_goblins` because
  `ears_for_mara` (-0.15) reduces it without setting Maeve's flag, so the
  tier is reachable on the "ears-before-cleansing" path.
- ⚠ NPCs with NO `warm_flag` and NO `warm_world_flag` will fall straight
  through tiers 1+2 to the faction tier. This is intentional — Edda, Bram,
  Roan, Hala are pre-wired for the faction tier the moment they get
  `warm_faction_lines`. No structural code change required.

## Time Schema

`World.time_of_day: float` — 0.0..1.0 (0.0 dawn, 0.25 noon, 0.5 dusk, 0.75
midnight). Full cycle = 360s. NPC schedules should consume this.

## Faction Schema

✅ **Shipped 2026-05-04 (run 2).** Live runtime state on World:
```gdscript
var factions: Dictionary = {
  "briarwood":           {"disposition": "friendly", "pressure": 0.0},
  "whisperwood_goblins": {"disposition": "hostile",  "pressure": 1.0},
  "dire_wolves":         {"disposition": "hostile",  "pressure": 0.5},
  "crystal_caves":       {"disposition": "hostile",  "pressure": 0.0},
}
```
- **Pressure** is a float clamped to [0.0, 1.0]. Higher = more aggressive,
  more spawns, bolder patrols (consumers TBD).
- **Disposition** is a String label. Today it's documentation; later may
  drive NPC reactions to fellow factions.

Read: `World.faction_pressure(id: String) -> float`.
Mutate: ONLY via `World.apply_consequence({"faction": id, "pressure_delta": float})`.
A future run should add per-frame decay toward a faction-specific equilibrium.

## Consequence Schema (Quest → World mutation)

✅ **Shipped 2026-05-04 (run 2).** Single entry point for quest completions to
mutate world state. Lives at `World.apply_consequence(consequence: Dictionary)`.
Supported keys (all optional; empty dict is a no-op):

| Key                | Type      | Effect                                             |
|--------------------|-----------|----------------------------------------------------|
| `faction`          | String    | id of faction in `World.factions` (paired w/ `pressure_delta`) |
| `pressure_delta`   | float     | added to `factions[id].pressure`, clamped [0,1]    |
| `world_flag`       | String    | sets `World.world_flags[name] = world_flag_value`  |
| `world_flag_value` | Variant   | optional; defaults to `true`                       |
| `npc_flag`         | [Str,Str] | `[npc_name, flag_name]`; appended to `npc_flags[npc]` (deduped) |
| `toast`            | String    | optional UI message; calls `_show_toast(toast)`    |

Read accessors:
- `World.faction_pressure(id) -> float`
- `World.has_world_flag(name) -> bool`
- `World.npc_has_flag(npc_name, flag_name) -> bool`

Authoring rule: dialogue + AI READ flags; only `apply_consequence` WRITES.
This guarantees one place to audit world-state churn.

## Goblin Spawn Schema

✅ **Shipped 2026-05-04 (run 5).** Per-camp goblin population derives from
`World.faction_pressure("whisperwood_goblins")`. Lives in
`WorldBuilder.gd → _goblin_camp_size(pressure: float) -> Dictionary`.
Returns `{"scouts": int, "brutes": int}` with thresholds:

| Pressure | Scouts/camp | Brutes/camp | Co-fires with                        |
|----------|-------------|-------------|--------------------------------------|
| ≥ 0.9    | 4           | 1           | (baseline; fresh-save default)       |
| < 0.9    | 3           | 1           | NPC.gd tier-3 dialogue (Maeve "ears-before-cleansing" path) |
| < 0.7    | 2           | 1           | (noticeably safer band)              |
| < 0.4    | 2           | 0           | (halfway tamed; brute suppressed)    |
| < 0.15   | 1           | 0           | (definitively tamed; near-empty wood)|

`_build_enemies()` reads pressure once at world build, derives camp size, and
applies the SAME camp size to all 3 camps (35,0,35), (-40,0,30), (20,0,-45).
Empty camp prop (`_make_goblin_camp(center)`: campfire, log seats) is built
*regardless* of population so a calmed wood reads as "they used to be here"
not "the world forgot this place."

Player-facing feedback: deferred call to `World._show_toast(
"🌿 You sense fewer goblins in the wood.")` at world build if scouts<4 OR
brutes<1. Pairs with apply_consequence's per-quest toasts — quest-completion
announces the *change*, world-build announces the *persistent state*.

Authoring rules:
- Read accessor is `World.faction_pressure("whisperwood_goblins")`. Never
  read `World.factions["whisperwood_goblins"]["pressure"]` directly — go
  through the accessor so the [0.0, 1.0] clamp is enforced.
- The runtime guard `world_node.has_method("faction_pressure")` keeps the
  spawn path fail-soft if an older `World.gd` lacks the accessor; behavior
  falls through to baseline (4 scouts + 1 brute), never crashes.
- Asserts at the top of `_build_enemies()` enforce `scout_count ∈ [0,4]`
  and `brute_count ∈ [0,1]`. Any new threshold edit MUST keep the contract.
- Future enemy kinds (skeleton, bandit, wolf) SHOULD mirror this helper
  pattern: `_<kind>_pack_size(pressure)` with its own faction id.

## Wolf Spawn Schema

✅ **Shipped 2026-05-04 (run 6).** Per-load wolf count derives from
`World.faction_pressure("dire_wolves")`. Lives in
`WorldBuilder.gd → _wolf_pack_size(pressure: float) -> Dictionary`.
Returns `{"count": int}` with thresholds:

| Pressure | Wolves | Co-fires with                                  |
|----------|--------|------------------------------------------------|
| ≥ 0.5    | 4      | (baseline; fresh-save default — `dire_wolves`) |
| < 0.5    | 3      | `pelt_for_lyra` completion (-0.1 → 0.4)        |
| < 0.3    | 2      | (future second reducer, e.g. Roan bounty)      |
| < 0.15   | 1      | (definitively tamed; near-empty wood)          |

`_build_enemies()` reads `dire_wolves` pressure once at world build, derives
pack size, and spawns `wolf_count` wolves from the FRONT of a stable 4-element
`wolf_spots` array. Dropping from the BACK of the list keeps the same wolves
in the same forest patches across loads — a player who eliminates pack #4
sees pack #4's spot stay empty rather than wolves "shuffling around."

Player-facing feedback: deferred call to `World._show_toast(
"🐺 The wolf packs feel thinner.")` at world build if `wolf_count < 4`.
Messaged separately from the goblin toast so kids can tell which faction
shrank — both can co-fire on the same load if both factions are calmed.

Authoring rules:
- Read accessor is `World.faction_pressure("dire_wolves")`. Same fail-soft
  guard as goblins (`world_node.has_method("faction_pressure")` → baseline).
- Assert at the top of the wolf block enforces `wolf_count ∈ [0, 4]`.
  Threshold edits MUST keep the contract.
- The 4-element `wolf_spots` array is the canonical spawn-position registry.
  Never reorder it — saves rely on positional stability across loads.
- Future enemy kinds (skeleton, bandit, crystal_elemental) SHOULD mirror
  this helper pattern: `_<kind>_pack_size(pressure)` returning a Dictionary
  with `{"count": int, ...}` so callers can query named fields, not tuples.

## Enemy Cooldown Schema

✅ **Shipped 2026-05-04 (run 7).** Per-enemy `attack_cooldown` derives from
`World.faction_pressure(faction_id)` at spawn. Lives in
`Enemy.gd → _resolve_adaptive_cooldown()`. Map of kind → faction is the
single source of truth:

| Enemy kind          | Faction id              | Cooldown band         |
|---------------------|-------------------------|-----------------------|
| `goblin`            | `whisperwood_goblins`   | `[1.05, 1.45]`        |
| `wolf`              | `dire_wolves`           | `[1.05, 1.45]`        |
| `skeleton`          | `crystal_caves`         | `[1.05, 1.45]`        |
| `crystal_elemental` | `crystal_caves`         | `[1.05, 1.45]`        |
| `crystal_guardian`  | `crystal_caves`         | `[1.05, 1.45]`        |
| `bandit`            | (unmapped)              | baseline 1.45 only    |

Resolved value = `lerp(BASELINE, MIN, 1.0 - pressure)` where
`BASELINE = 1.45` (Alden's recovery valve) and `MIN = 1.05` (Owen's mastery
rung). Endpoint table:

| Pressure | Cooldown | Co-fires with                                           |
|----------|----------|---------------------------------------------------------|
| ≥ 1.0    | 1.45     | (baseline; identical to pre-run-7 behavior)             |
| 0.85     | 1.39     | (Mara's bounty alone; tiny shift — kid recovery valve)  |
| 0.65     | 1.31     | (Mara + Maeve goblin path; first noticeable acceleration)|
| 0.40     | 1.21     | (halfway tamed band)                                    |
| 0.15     | 1.10     | (definitively tamed; survivors hit fast)                |
| 0.00     | 1.05     | (faction extinct; the few holdouts hit at the floor)    |

Player-facing feedback: enemy_name is prefixed with `⚡ ` when resolved
cooldown < `AGITATED_COOLDOWN_THRESHOLD = 1.30`. Reads at a glance to a
9-year-old as "this one will hit faster" — pairs with the faction-density
toasts (which announce the *count* change) by surfacing the *pacing* change
on a per-enemy basis. The threshold corresponds to roughly pressure ≤ 0.625,
clearly past the first reducer for both goblins and wolves.

Authoring rules:
- Read accessor is `World.faction_pressure(faction_id)`. Same fail-soft
  guards as spawn density: missing world group, missing accessor, OR
  unmapped `enemy_kind` ALL fall through to baseline 1.45 (no crash, no
  hidden behavior change).
- Resolved value is **clamped** to `[ATTACK_COOLDOWN_MIN, ATTACK_COOLDOWN_BASELINE]`
  and asserted against the same band. Threshold edits MUST keep the assert
  passing; widening the band requires a fresh PLAYER_MODEL.md tuning pass.
- Cooldown is resolved ONCE at first `_ready()`. `_respawn()` does NOT
  re-sample — same world, same cooldown, until the player reloads. This
  matches WorldBuilder spawn-density semantics: world reactivity is
  *save-reload* granular, not real-time.
- Future enemy kinds: add to `KIND_TO_FACTION` in `Enemy.gd`. If the kind's
  faction id isn't in `World.factions`, behavior is identical to baseline
  — i.e. it's safe to wire kinds before the dungeon containing them ships
  (see `crystal_caves` rows above).
- The `⚡` prefix is purely cosmetic — `Items.roll_loot(enemy_kind, …)` and
  `quest_listeners.on_enemy_killed(enemy_kind)` operate on `enemy_kind`, not
  on `enemy_name`, so the prefix never breaks loot tables or quest matching.

## Enemy Chase Schema

✅ **Shipped 2026-05-04 (run 8).** Per-enemy `chase_speed` derives from
`World.faction_pressure(faction_id)` at spawn. Lives in
`Enemy.gd → _resolve_adaptive_chase_speed()`. Reuses the `KIND_TO_FACTION`
map that the cooldown schema already declared — single source of truth for
kind → faction routing.

Unlike the cooldown schema's absolute band, chase_speed is **multiplicative**:
each kind's WorldBuilder-assigned baseline is preserved at fresh save and
lifted by up to `+CHASE_SPEED_AGITATION_GAIN` (=`0.17`, +17%) at pressure
0.0. This keeps role-shape intact — Goblin Brutes stay tank-slow, Crystal
Elementals stay ponderous, Goblin Scouts stay quick — while every kind
gets the SAME mastery-rung ceiling experience for Owen.

| Enemy kind          | Faction id              | Baseline → Ceiling (pressure 1.0 → 0.0) |
|---------------------|-------------------------|------------------------------------------|
| `goblin` (Scout)    | `whisperwood_goblins`   | `4.6 → 5.38`                             |
| `goblin` (Brute)    | `whisperwood_goblins`   | `1.0 → 1.17` (tank role preserved)       |
| `wolf`              | `dire_wolves`           | `1.05 → 1.23`                            |
| `skeleton`          | `crystal_caves`         | `4.4 → 5.15`                             |
| `crystal_elemental` | `crystal_caves`         | `3.2 → 3.74`                             |
| `crystal_guardian`  | `crystal_caves`         | `3.4 → 3.98`                             |
| `bandit`            | (unmapped)              | baseline only (no faction yet)           |

Resolved value = `lerp(baseline, baseline * (1 + GAIN), 1.0 - pressure)`
where `baseline` is the chase_speed assigned by `WorldBuilder._spawn_enemy`
(or the `@export` default if WorldBuilder didn't override). Endpoint table
for the default-4.6 scout:

| Pressure | chase_speed | Co-fires with                                       |
|----------|-------------|-----------------------------------------------------|
| ≥ 1.0    | 4.60        | (baseline; identical to pre-run-8 behavior)         |
| 0.85     | 4.72        | (Mara's bounty alone; barely-felt 2.5% bump)        |
| 0.65     | 4.87        | (Mara + Maeve path; first readable acceleration)    |
| 0.40     | 5.07        | (halfway tamed band; +10%)                          |
| 0.15     | 5.27        | (definitively tamed; +14.5%)                        |
| 0.00     | 5.38        | (faction extinct; +17% ceiling, the few hunt hard)  |

Player-facing feedback: **no new visual cue** — the cooldown schema's
`⚡` prefix already fires below pressure ~0.625 and now subsumes BOTH
adaptive outputs. One marker, two coupled effects: kids see one symbol
and learn it means "this one's faster *and* punishier." Adding a second
marker for chase would clutter the floating-name HUD without adding
information (the two outputs lerp on the same scalar — they trip together).

Authoring rules:
- Read accessor is `World.faction_pressure(faction_id)`. Same fail-soft
  guards as the cooldown schema: missing world group, missing accessor, OR
  unmapped `enemy_kind` ALL fall through to the WorldBuilder-assigned
  baseline (no crash, no hidden behavior change).
- Resolved value is **clamped** to `[baseline, baseline * (1 + GAIN)]`
  and asserted against the same band. Widening `CHASE_SPEED_AGITATION_GAIN`
  past 0.17 requires a fresh PLAYER_MODEL.md tuning pass — pushing past
  +25% would risk breaking Alden's "I can outrun them" exploration valve.
- chase_speed is resolved ONCE at first `_ready()` AFTER WorldBuilder has
  assigned the per-kind baseline. `_respawn()` does NOT re-sample — same
  world, same chase, until the player reloads. Matches the cooldown schema
  and WorldBuilder spawn-density semantics: world reactivity is
  *save-reload* granular, not real-time.
- Future enemy kinds: add to `KIND_TO_FACTION` in `Enemy.gd` — the SAME
  map both cooldown and chase consult. If the kind's faction id isn't in
  `World.factions`, behavior is identical to baseline.
- The four `faction_pressure` consumers (NPC dialogue tier 3, goblin spawn
  density, wolf spawn density, enemy attack cooldown, **enemy chase speed**)
  must remain in sync on the `KIND_TO_FACTION` / faction-id keys. Any
  rename of a faction id is a cross-cutting refactor, not a local edit.

## World Flag Conventions

`World.world_flags: Dictionary` is keyed by `snake_case` strings naming a
*present-tense fact*: `whisperwood_safer`, `lyra_potion_brew`,
`mara_bounty_paid`. Never imperative ("save_the_village") and never tied to
quest IDs ("quest_1_done") — flags outlive specific quests.
