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

## JSON Dialogue Tree Schema

✅ **Shipped 2026-05-04 (run 9): JSON-driven dialogue trees** via the new
`DialogueDB.gd` static helper. Reads `res://data/dialogue/<npc_slug>.json` and
applies a predicate priority order to choose ONE line per interaction.

Opt-in per NPC: set `"use_json_dialogue": true` in `WorldBuilder.NPCS`. NPC.gd
consults DialogueDB BEFORE the variants/warmed_* pipeline; on miss, falls
through to the existing tiers unchanged. Currently opted-in: **Elder Maeve**,
**Smith Edda**.

### Slug convention
`Elder Maeve` → `elder_maeve` (lowercased, spaces → underscores, trimmed).
JSON file path: `data/dialogue/elder_maeve.json`. Both files for Maeve and
Edda already shipped from `auto/lore` on 2026-05-04 (integrator gap). This
schema makes them live.

### Tree shape (top-level keys, all optional except `default`)

| Key                          | Predicate                                                       | Notes |
|------------------------------|-----------------------------------------------------------------|-------|
| `low_health_player`          | `Player.hp / Player.max_hp < 0.30`                              | Highest priority — fires whenever HP is low, regardless of other state. |
| `boss_slain`                 | `World.has_world_flag("warlord_dead")`                          | Fires after Goblin Warlord kill. |
| `boss_alive`                 | `World.has_world_flag("seen_warlord")`                          | Fires once player encounters the boss. **Fail-soft** — flag not yet written by any system; lights up the day a future Builder writes it. |
| `high_renown`                | `World.player_renown >= 100` (configurable)                     | **Fail-soft** — `player_renown` not on World yet; lights up automatically when a renown system lands. |
| `stranger`                   | `World.npc_seen[npc_name] != true`                              | **Fail-soft** — `npc_seen` not on World yet; lights up when a first-interaction tracker lands. |
| `longnight_vigil` /<br>`honeysong_eve` /<br>`spring_first_warm_day` | `World.current_festival == <key>` | **Fail-soft** — `current_festival` not on World yet; the JSONs already define these beats so they fire the day a calendar lands. |
| `after_first_quest_complete` | `World.npc_has_flag(npc, warmed_flag)` OR `World.has_world_flag("first_quest_done")` | Pairs with the existing `warm_flag` tier on `WorldBuilder.NPCS`. |
| `morning` / `midday` /<br>`evening` / `night` | `World.time_of_day` bucket                       | Same boundaries as NPC.gd's `dialogue_variants[bucket]` (5/11/17/21). |
| `default`                    | always (last resort)                                            | Required for every tree — caller falls back to NPC.gd `dialogue` if missing. |

### Predicate priority (first match wins)

```
1. low_health_player
2. boss_slain
3. boss_alive               (fail-soft on world_flag "seen_warlord")
4. high_renown              (fail-soft on World.player_renown)
5. stranger                 (fail-soft on World.npc_seen)
6. festival key             (fail-soft on World.current_festival)
7. after_first_quest_complete
8. mood bucket (morning/midday/evening/night)
9. default
```

### Wiring
- `eldoria-godot/scripts/DialogueDB.gd` — static helper. Methods:
  - `DialogueDB.load_for(npc_name) -> Dictionary` — cached JSON load (negative cache safe).
  - `DialogueDB.choose_line(npc_name, ctx) -> String` — predicate resolver. Returns `""` on miss.
- `eldoria-godot/scripts/NPC.gd` — `@export var use_dialogue_json: bool`.
  When true, `_on_interact()` builds ctx (world, tod, hp_ratio, warmed_flag),
  calls `choose_line()`, and uses the result if non-empty. Else falls through.
- `eldoria-godot/scripts/WorldBuilder.gd` — per-NPC `"use_json_dialogue": true`
  data field; `_make_npc()` copies it to `npc.use_dialogue_json`.

### Authoring rules
- Every JSON tree MUST define `default` (loader falls through on missing
  default and NPC.gd uses its `dialogue` String fallback — works, but loud
  and silent are different failure modes).
- Tree may omit any optional key — predicate just doesn't fire for that NPC.
- Lines should NOT exceed ~280 chars (UI clamp). Use line breaks `\n` if
  longer narrative is required.
- `lore_notes` and any other keys are IGNORED at runtime — safe parking for
  voice rules, withholding rules, consequence-hook docs (see Maeve / Edda).
- The `npc_name` and `role` keys at the top of the JSON are also ignored —
  the npc name is the dispatch key (slug), the role comes from
  WorldBuilder.NPCS already.

### Composition with existing dialogue tiers

JSON-tree resolution sits ABOVE all 4 existing tiers. The tiers compose:

```
DialogueDB JSON (run 9, this) ─────────── tier 0 (use_json_dialogue=true)
  ↓ miss
warmed_flag        + warmed_dialogue_variants     ── tier 1 (run 3)
  ↓ miss
warmed_world_flag  + warmed_world_dialogue_variants ─ tier 2 (run 3 follow-up)
  ↓ miss
warmed_faction_id  + warmed_faction_dialogue_variants ─ tier 3 (run 4)
  ↓ miss
dialogue_variants  (mood bucket)                   ── tier 4
  ↓ empty
dialogue           (single fallback)               ── tier 5
```

This means an NPC can have BOTH a JSON tree AND warm_lines populated; the
JSON wins when opted in. Authors can migrate per-NPC at their own pace.

### Authoring traps
- ⚠ Slug must match exactly. `Mara the Merchant` → `mara_the_merchant.json`.
  If the file is misnamed, the NPC silently falls back to the variants
  pipeline. This is intentional fail-soft, but log-level "I expected JSON"
  diagnostics are NOT yet wired — author confirms the slug visually.
- ⚠ Predicate priority is intentional and not author-overridable. If you
  want a `morning` greeting to win over a `low_health_player` warning, you
  need to delete `low_health_player` from the tree (or move the threshold
  via `low_hp_below` ctx — currently hard-coded to 0.30).
- ⚠ Fail-soft predicates (`boss_alive`, `high_renown`, `stranger`,
  festival keys) DO NOT fire today. They are forward-compatible. If you
  need them live, add the corresponding World fields BEFORE the JSON tree
  ships — otherwise the line you authored is dead text.

### Future hooks
1. The other 5 NPCs (Mara, Lyra, Bram, Roan, Hala) need only a JSON file
   following this schema + `"use_json_dialogue": true` in WorldBuilder.NPCS.
   Zero code change.
2. `World.player_renown: int` — when added, `high_renown` keys for Maeve +
   Edda fire automatically (their JSONs already define them).
3. `World.current_festival: String` — when a calendar/festival system
   lands, the seasonal keys (`longnight_vigil`, `honeysong_eve`,
   `spring_first_warm_day`) become live without any JSON edit.
4. `World.npc_seen: Dictionary` — when a first-interaction tracker lands,
   every NPC's `stranger` key fires correctly.
5. Per-line portrait / voice-clip extension: `choose_line()` could return a
   Dictionary (line + portrait_path + voice_clip) if any future JSON adds
   those fields. Tree schema is already extensible — added keys are ignored.

## World API additions (run 10)

`World.set_world_flag(name: String, value: Variant = true) -> void`

Direct world-flag write — sister to `apply_consequence`'s flag step but
without faction / NPC / toast side-effects. Sets `world_flags[name] =
value` and re-runs `_check_achievements()`. Used by `Boss.gd` to mark
emergent-runtime facts (`seen_warlord`, `warlord_dead`) that don't come
from a quest turn-in. Returns immediately on empty name. Same fail-soft
contract as the rest of the World API.

Callsites today:
- `Boss._physics_process` — sets `seen_warlord` when the player's distance
  to the boss first drops below 30m (one-shot per session, gated by
  `_intro_played`).
- `Boss._die` — sets `warlord_dead` once the Warlord's HP reaches 0.

DialogueDB.gd consumes both flags via `World.has_world_flag(name)` to
gate the JSON `boss_alive` / `boss_slain` lines (predicate priority slots
2 and 3).

## NPC JSON dialogue — opted-in NPCs (run-10 update)

Three NPCs now resolve dialogue via `DialogueDB.choose_line()` first,
falling back to the legacy `dialogue_variants` / `warmed_*` system on miss:

| NPC | JSON file | Opted in (run) |
|-----|-----------|----------------|
| Elder Maeve | `data/dialogue/elder_maeve.json` | run 9 |
| Smith Edda | `data/dialogue/smith_edda.json` | run 9 |
| Innkeeper Bram | `data/dialogue/innkeeper_bram.json` | **run 10** |

Opt-in is a single field on the WorldBuilder.NPCS entry:
`"use_json_dialogue": true`. WorldBuilder copies it onto the NPC node as
`use_dialogue_json`, which gates the DialogueDB consult in `_on_interact`.

Future NPCs (Mara, Lyra, Roan, Hala) need only:
1. A JSON file named after the slug (`mara_the_merchant.json`, etc.)
2. `"use_json_dialogue": true` on the NPCS entry

No code edits required — DialogueDB's loader walks `res://data/dialogue/`
and picks up any new file matching the slug pattern.

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

## Achievement & Title Schema

`Achievements.gd` (NEW, run 9) declares `const ACHIEVEMENTS: Dictionary`
keyed by snake_case ID. Each entry has:

| Field            | Type        | Notes                                                                 |
|------------------|-------------|-----------------------------------------------------------------------|
| `name`           | String      | Display label, shown in unlock toast and future achievements panel    |
| `desc`           | String      | One-sentence flavor                                                   |
| `icon`           | String      | Emoji glyph (child-readable)                                          |
| `title_text`     | String      | Granted title; `""` = no title is granted by this achievement         |
| `title_priority` | int         | Higher = preferred when multiple titles unlocked simultaneously       |
| `predicate`      | Dictionary  | Composable predicate against existing world primitives (see below)    |

`Achievements.evaluate(world: Object) -> Array` returns the IDs of every
achievement whose predicate is currently satisfied. Pure read; same
fail-soft contract as the spawn-density helpers (missing world / missing
accessors → empty array, never crash).

`Achievements.best_title(unlocked_ids: Array) -> String` picks the
highest-priority unlocked title. Stable ordering: ties broken by ID
alphabetical so the title above the player's head never flickers.

### Predicate language (queryable schema)

| Kind             | Shape                                                          | Reads from                       |
|------------------|----------------------------------------------------------------|----------------------------------|
| `world_flag`     | `{kind, flag: String}`                                         | `World.has_world_flag(flag)`     |
| `faction_below`  | `{kind, faction: String, value: float}`                        | `World.faction_pressure(faction)`|
| `faction_above`  | `{kind, faction: String, value: float}`                        | `World.faction_pressure(faction)`|
| `all_npc_flags`  | `{kind, flags: Array[[npc_name, flag_name]]}`                  | `World.npc_has_flag(name, flag)` |
| `all_of`         | `{kind, preds: Array[Dictionary]}`                             | (recursive)                      |
| `any_of`         | `{kind, preds: Array[Dictionary]}`                             | (recursive)                      |

The evaluator is invoked from `World._check_achievements()` which fires
at the END of `apply_consequence(...)` and once at `_ready()` (deferred so
Player's nameplate exists). The `unlocked_achievements: Dictionary` keeps
unlock state. On each new unlock, a toast fires (`🏆 <icon> <name> — <desc>`),
multiple unlocks on the same frame are staggered 0.6s apart.

Title display: `Player.title_label` is a Label3D anchored at `y = 2.4`
above the feet pivot, billboarded, gold-leaf modulate (palette §3 burnt
gold), 8px black outline (matches HUD damage numbers). Hidden when the
title string is empty. THEME §12 motion-and-life: bound by a looping
`create_tween()` that bobs `position:y` between 2.40 and 2.46 every 1.5s
so the label breathes. `Player.set_title(t: String)` is the single setter;
World calls it via `_apply_title_to_player(t)` which is a no-op if the
player isn't ready yet.

### Authoring rules

1. **NEVER add a new world primitive in `Achievements.gd`.** If a predicate
   cannot be expressed against `factions` / `world_flags` / `npc_flags`,
   add the new READER first (see runs 5–7 for the spawn-density pattern),
   then write the achievement.
2. Keep `title_text` ≤ 18 characters. The Label3D is `pixel_size 0.0035`,
   font_size 28; longer titles wrap and look cluttered.
3. Use a UNIQUE `title_priority` across achievements that can co-unlock so
   the auto-equipper's pick is unambiguous. Current ladder:
   - 10  `the Apprentice` (first quest)
   - 30  `Wolf-Friend` (wolves down 1 cliff)
   - 40  `Goblin-Bane` (goblins down 1 cliff)
   - 50  `the Trusted` (3 NPC trusts)
   - 100 `Warden of Eldoria` (mastery — both factions tamed + 3 trusts)
4. Predicate evaluation MUST be PURE. The evaluator runs on every
   `apply_consequence` and on `_ready` — side effects would cascade.

### Authoring trap captured this run

Predicates that compose `faction_below` with `all_npc_flags` (e.g.
`realm_warden`) will trip the moment the LAST quest in the chain
applies its consequence, because `_check_achievements()` runs AFTER all
consequence steps. Do not order tier-4 achievements assuming an extra
quest beyond their last input — the unlock fires on the same frame as
the last input quest's toast. Stagger of 0.6s in the toast queue is the
only thing keeping the unlock toast from being clobbered.

## Renown Schema (run 11 — Builder)

`World.player_renown: int` is a first-class scalar that DialogueDB.gd has
been reading via `"player_renown" in world_node` since the JSON-tree
resolver shipped (run 9). The field landed in run 11 — until then the
predicate was fail-soft (no field, no fire). Authored `high_renown` lines
on Maeve, Edda, Bram, and Lyra now actually reach players.

### Public API (World.gd)

| Method                                         | Notes                                                           |
|------------------------------------------------|-----------------------------------------------------------------|
| `gain_renown(amount: int, source: String)`     | Sole public mutator. Clamps min 0. Toasts on positive delta.    |
| `_recompute_renown_from_achievements()`        | Idempotent rebuild from `unlocked_achievements`. Save-safe.     |

### Renown ladder (today)

Renown is a strict function of `unlocked_achievements`. Each newly-unlocked
achievement awards renown equal to its `title_priority`:

| Achievement              | Title              | Priority / Renown |
|--------------------------|--------------------|------------------:|
| First Steps              | the Apprentice     |                10 |
| Pack Thinner             | Wolf-Friend        |                30 |
| Bane of the Whisperwood  | Goblin-Bane        |                40 |
| Trusted by Three         | the Trusted        |                50 |
| Warden of the Realm      | Warden of Eldoria  |               100 |

Crossing the default `high_renown` threshold (100, set in DialogueDB) takes
**all five** of the current achievements OR the Warden tier alone. By the
time the player has earned the Warden title, the high-renown JSON line is
exactly two ticks behind the title equip — readable and earned.

### Authoring rules

1. **Renown is read-only outside `World.gd`.** All mutation goes through
   `gain_renown(...)`. Future quests can extend by adding a `"renown": int`
   field to consequence payloads — `apply_consequence` is the natural
   forwarding site (not wired this run; achievements are the sole source).
2. **Never grant negative renown.** The clamp to 0 is defensive; this
   realm has no infamy mechanic and adding one would split the schema.
3. **`title_priority` doubles as the renown grant.** Adding a new
   achievement at priority 25 grants 25 renown. Keep priorities unique
   per the existing rule (auto-equipper picks the highest title); the
   renown side benefits for free.
4. **`high_renown` predicate fires lazily.** It only resolves on the next
   `DialogueDB.choose_line(...)` call (= next time the player talks to
   that NPC). No background loop. Same fail-soft contract as every other
   tree key — missing data, no fire, no crash.

### HUD readout

`UI/HUD/RenownLabel` (Main.tscn, added run 11) sits directly below the
GoldLabel at the same x-offset and font size, in a slightly cooler gold
(`Color(1, 0.78, 0.32)` vs Gold's `Color(1, 0.85, 0.40)`) so they read as
a related pair without competing for attention. THEME §12 motion-and-life:
the label scale-pulses 1.0 → 1.18 → 1.0 over 0.45s on every gain (same
back-then-sine grammar as damage numbers).


---

## NPC schedules (run 11)

Schema for `NPC.schedule_anchors` and the schedule walker. Authored in
`scripts/NPC.gd` + `scripts/WorldBuilder.gd`.

### Schema: `NPC.schedule_anchors`
- Type: `Array` (untyped Array of `Vector3`, up to 4 entries).
- Index meaning (matches the canonical mood-bucket cliffs reused by
  `dialogue_variants` / `warmed_*` / DialogueDB time-of-day keys):
    [0] morning  (5.0  ≤ tod < 11.0)
    [1] midday   (11.0 ≤ tod < 17.0)
    [2] evening  (17.0 ≤ tod < 21.0)
    [3] night    (tod < 5.0  OR  tod ≥ 21.0)
- Empty / missing → legacy stationary behavior. Shorter arrays clamp to
  last entry — a 1-element array means "always at this anchor".
- Authored ONLY in `WorldBuilder.NPCS[].schedule`. `_make_npc` filters
  out non-Vector3 entries before assigning.

### Knobs
- `NPC.schedule_speed: float` — m/s walk speed. Default 0.8.
- `NPC.schedule_arrival_radius: float` — within this distance of target,
  position snaps and walker idles. Default 0.5m. Avoid below 0.25m.

### Internal state
- `NPC._spawn_y: float` — cached `global_position.y` at `_ready`. Walker
  preserves this y on every position write so THEME §13 GROUND CONTACT
  cannot be violated.
- `NPC._last_bucket: int` — debug / future bucket-change hook.

### Walker semantics
- Halts when `player_in_range`. Resumes on `body_exited`.
- xz-only motion; y locked to `_spawn_y`.
- Faces direction of motion via `look_at(face_at, Vector3.UP)`, guarded
  against zero-direction degeneracy by 0.001m length check.
- Free op when `schedule_anchors.is_empty()` — early return in `_process`.

### Author rules
1. Schedule anchors should be authored on a 5–10m radius around the NPC's
   spawn pos. Larger walks at 0.8m/s feel sluggish (a 20m walk takes
   25s real-time at default speed).
2. Keep `y = 0` in authored anchors. Walker forces `_spawn_y` regardless.
3. Never anchor an NPC inside a building wall or impassable path —
   NPCs are `StaticBody3D`, the player capsule will collide.
4. If an NPC's dialogue *describes* a specific spot ("at the well"),
   the schedule's matching-bucket anchor should put them there.

### Compound graph as of run 11

```
World.time_of_day  ──→  4 buckets ──→  dialogue_variants  (legacy mood)
                                  ──→  warmed_*_dialogue_variants (3 tiers)
                                  ──→  DialogueDB time-of-day keys
                                  ──→  NPC.schedule_anchors (NEW THIS RUN)

World.unlocked_achievements (size) ──→ World.player_renown (parallel run)
                                  ──→ DialogueDB.high_renown predicate

NPC._spawn_y (cached _ready) ──→ schedule walker y-clamp (THEME §13)
WorldBuilder.NPCS[].schedule ──→ NPC.schedule_anchors (per-NPC author)
```

### Smoke-test checklist for QA agents
- Spawn the player, observe each NPC at midday — should match each
  `NPCS[].pos` value.
- Set `World.time_of_day = 6.0` → all NPCs walk toward morning anchor
  over the next ~10s of real time.
- Set `time_of_day = 22.0` → Maeve at hut door, Bram at inn, Mara at
  inn (drinks with Bram — high-leverage observable), Lyra at hut,
  Edda at quenching trough, Roan at stable, Hala at field watch.
- Approach an NPC — they halt motion within 1 frame of `player_in_range`.
- Walk away — they resume walking on next `_process` tick.
## Forge Schema (run 12 — Builder)

`Smith Edda's anvil` is the Crystal-Cave-shard sink — the loop closure
that's been missing since the cave shipped. Crystal Caves drop crystal_shards
(via skeleton / crystal_elemental / crystal_guardian drop tables tuned in
runs 5–11); the player brings them to Smith Edda; the dialogue panel shows
a 🔨 Reforge button that consumes shards and stamps a "+N" suffix on the
currently-equipped weapon.

### Public API

`Items.gd` constants (read-only catalog):

| Constant                  | Value             | Notes                                             |
|---------------------------|-------------------|---------------------------------------------------|
| `REFORGE_MAX_TIER`        | `3`               | Max upgrade tier (visible suffixes "+1"/"+2"/"+3")|
| `REFORGE_COSTS`           | `[5, 10, 18]`     | Per-step crystal_shard cost (T0→T1, T1→T2, T2→T3) |
| `REFORGE_DAMAGE_BONUS`    | `[2, 4, 6]`       | Cumulative flat bonus added by `bonus_damage()`   |
| `REFORGE_SUFFIXES`        | `["+1","+2","+3"]`| Display suffix per tier                           |
| `REFORGE_TIER_COLORS`     | bronze/brass/cyan | THEME §3 palette band (paperdoll polish hook)     |

`Items.gd` static helpers (pure):

| Method                                   | Notes                                           |
|------------------------------------------|-------------------------------------------------|
| `forged_name(base_id, tier) -> String`   | "Iron Sword +2"; tier 0 returns base name       |
| `forge_damage_bonus(tier) -> int`        | Flat additive bonus; tier 0 returns 0           |
| `forge_next_tier_cost(tier) -> int`      | Cost to step up; max tier returns 0             |

`Inventory.gd` (state + mutator):

| Member                                     | Notes                                                     |
|--------------------------------------------|-----------------------------------------------------------|
| `forge_tiers: Dictionary`                  | weapon_id → int. Empty = none. Persists across equip swaps|
| `weapon_forge_tier(weapon_id="") -> int`   | Defaults to currently-equipped weapon                     |
| `weapon_display_name(weapon_id="") -> String` | "Iron Sword +N" via `Items.forged_name`                |
| `bonus_damage() -> int`                    | Now adds tier bonus (compound on top of base)             |
| `attempt_reforge(world: Object) -> Dictionary` | Validates cost/cap, mutates state, returns {ok, ...} |

`World.gd` (UI wiring):

| Method                                            | Notes                                                |
|---------------------------------------------------|------------------------------------------------------|
| `_refresh_reforge_button(btn, role, player)`      | Pure read of inv state; sets label + disabled flag   |
| `_on_reforge_pressed()`                           | Calls `Inventory.attempt_reforge`; toasts result     |

### Cost / damage ladder (today)

| Step       | Crystal Shards | New display name | Damage delta |
|------------|---------------:|------------------|-------------:|
| T0 → T1    |              5 | <weapon> +1      |           +2 |
| T1 → T2    |             10 | <weapon> +2      |           +4 |
| T2 → T3    |             18 | <weapon> +3      |           +6 |
| **Total**  |         **33** |                  |       **+6** |

Tuned so:
- First +1 reachable in ~1 elemental kill (1-2 shards) plus 2-3 skeleton
  drops — Alden's first cave run yields the first reforge naturally.
- Max +3 takes ~3 cave runs at typical drop rates — Owen's Mastery loop
  has a clear, finite goal that doesn't overwhelm the loot pyramid.
- 60% damage uplift on iron_sword (6 → 12), ~14% on dragonfang (42 → 48):
  flat-bonus curve favors low-tier weapons (kid-friendly catch-up) without
  trivializing top-tier loot. A forged iron_sword sits in steel_blade's
  damage band — NOT in frost_saber's — so the affix system (run 5+) and
  the rare-chest loop (Items.gd `chest_rare`) still feel meaningful.

### Authoring rules

1. **Tier is per-weapon-id, not per-equipped-slot.** Swapping weapons does
   NOT clear the tier of the previous weapon. This means the player can
   keep multiple forged weapons in their bag and swap between them as the
   situation calls — a pure win that costs nothing in save complexity.
2. **`first_reforge_done` world flag is the achievement hook.** Set on the
   first successful `attempt_reforge`. The "first_forge" achievement
   (priority 25, title "the Forged") in Achievements.gd reads it via the
   existing `world_flag` predicate kind. Renown ladder award: 25 (between
   Apprentice 10 and Wolf-Friend 30).
3. **Reforge does not write a runtime registry entry.** Unlike the run-5
   affix system (`Items.generate_affix_item` → `World.register_runtime_item`),
   forge tiers are a sparse Dict keyed on the BASE id. Save-load is a
   trivial Dict serialize; the runtime registry stays focused on
   chest-rolled affix variants.
4. **The button itself teaches the system.** When the player has no shards,
   the button reads "Reforge Iron Sword → +1  (need 5 💎, have 2)" so the
   gap is visible. When at max, "Iron Sword +3 already — peerless work".
   No separate forge UI panel is needed today; future Builder work can
   open a dedicated panel if multi-weapon reforge becomes desirable.

### Hooks consumed / produced this run

CONSUMES (existing readers / data):
- `Items.ITEMS["crystal_shard"]` (run 5) — the resource sink
- `World.set_world_flag` (run 11) — the achievement-trigger contract
- `Achievements.evaluate` (run 11) — fires "first_forge" on the same tick
  the flag is set
- `World.gain_renown` (run 11) — receives the +25 renown grant via the
  existing `_check_achievements()` chain
- `Inventory.equipped_weapon_id` (existing) — the dialogue button reads it

PRODUCES (new readers can write against):
- `Inventory.weapon_forge_tier(weapon_id)` — DialogueDB predicate idea
  (`forge_tier_at_least`) for future Edda lines that warm with player's
  forged weapon, or QUEST_GRAMMAR triggers gating on forge progress
- `world_flags["first_reforge_done"]` — quest hooks (e.g. Edda's deeper
  questline could world_trigger on this flag)
- `Inventory.weapon_display_name()` — HUD readout (Player paperdoll text
  could substitute the forged display name in future polish)
- `Inventory.forge_tiers` Dict — save/load surface (future persistence)
