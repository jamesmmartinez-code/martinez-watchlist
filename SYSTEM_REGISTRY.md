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

## Item ID Catalog (live, audited 2026-05-06 — Architect)

Canonical list of every ID currently defined in `Items.ITEMS`. Drift between
this catalog and `Items.gd` is a §3 ledger violation — fix the ledger or
remove the item, never let them diverge.

**Weapons** (slot=`weapon`, `damage` int, optional `crit_bonus` float):
- `rusty_sword` (common, dmg 3) — starter
- `iron_sword` (common, dmg 6)
- `steel_blade` (uncommon, dmg 12)
- `frost_saber` (rare, dmg 22, +6% crit)
- `ember_axe` (rare, dmg 26)
- `shadow_dagger` (epic, dmg 18, +18% crit)
- `dragonfang` (legendary, dmg 42, +10% crit)

**Armor** (slot=`armor`, `armor` int, optional `hp_bonus` int):
- `cloth` (common, armor 2) — starter
- `leather` (common, armor 6)
- `chainmail` (uncommon, armor 12)
- `steel_plate` (rare, armor 22)
- `emberforge` (epic, armor 34, +35 HP)
- `dragonscale` (legendary, armor 52, +80 HP)

**Trinkets** (slot=`trinket`, mix of `hp_bonus`/`mp_bonus`/`crit_bonus`):
- `ring_focus` (uncommon, +15 MP)
- `talisman_oak` (uncommon, +18 HP)
- `crit_amulet` (rare, +10% crit) — display name "Hawk's Amulet"
- `guardian_core` (legendary, +60 HP / +40 MP / +8% crit)

**Consumables** (slot=`""`, `stack:true`):
- `hp_potion_s` (common, heal 40) — display "Lesser Health Potion"
- `hp_potion_l` (uncommon, heal 130) — display "Greater Health Potion"
- `mp_potion` (common, mana 45) — display "Mana Draught"

**Materials** (slot=`""`, `stack:true`, used by fetch quests & loot):
- `wolf_pelt` (common) — `pelt_for_lyra`
- `wolf_fang` (common) — `wolf_fang_for_roan`
- `wolf_heart` (rare) — `wolf_heart_for_bram`
- `goblin_ear` (common) — `ears_for_mara`
- `warlord_horn` (epic) — Goblin Warlord boss drop
- `crystal_shard` (epic) — Crystal Caves placeholder

**Adding an item:** new IDs MUST be appended here in the same commit that
edits `Items.ITEMS`; otherwise the next architect audit will flag drift.

## Drop Tables

Defined in `Items.DROP_TABLE`. Entries: `{id, weight, qty:[min,max]}`.
Currently keyed: `goblin`, `wolf`, `goblin_warlord`, `skeleton`,
`crystal_elemental`, `bandit`, `bandit_captain` (entries vary). New
enemy kinds MUST add a drop table entry; do not let an enemy ship
without loot.

### Live wolf table (run 20 — Builder)

| id            | weight | qty   | notes                                              |
|---------------|--------|-------|----------------------------------------------------|
| `hp_potion_s` |   22   | 1-2   | Owen-tier survival floor                           |
| `wolf_pelt`   |   35   | 1     | fetch material for `pelt_for_lyra` (38 → 35 run 19) |
| `wolf_fang`   |   15   | 1     | fetch material for `wolf_fang_for_roan` (18 → 15 run 19) |
| `wolf_heart`  |    8   | 1     | **NEW (run 20)** — RARE; fetch material for `wolf_heart_for_bram` |
| `leather`     |   10   | 1     | crafting material (12 → 10 run 19)                 |
| `chainmail`   |    6   | 1     | mid-tier armor                                     |
| `steel_blade` |    4   | 1     | mid-tier weapon                                    |
| **Total**     | **100**|       | weight total preserved at 100 across runs 17 + 19  |

Lyra, Roan, and Bram can all be quested in parallel — a ~13-kill wolf
grind expects ~4.5 pelts + ~1.95 fangs + ~1.04 hearts at the run-19
rebalanced weights, satisfying Lyra's 4 + Roan's 5 + Bram's 3 in one
loop. Hala's 4-kill quest finishes earliest. The drift on each id's
relative odds is < 4% from the run-17 weights, so existing 30-kill grind
expectations are byte-identical within rounding.

### Live bandit_captain table (run 23 — Builder)

| id              | weight | qty | notes                                                |
|-----------------|--------|-----|------------------------------------------------------|
| `steel_blade`   |   24   | 1   | the captain's own blade — readable as "they were a real threat" |
| `chainmail`     |   18   | 1   | gear a captain would actually wear                   |
| `ember_axe`     |   12   | 1   | rare 26-dmg axe, mini-boss tier                      |
| `crystal_shard` |   12   | 2-3 | bridge to Edda's forge for road-tame players         |
| `hp_potion_l`   |   12   | 1-2 | Greater Health, mid-game survival rung               |
| `crit_amulet`   |    8   | 1   | only run-7+ rare; "captain wore the hawk's eye"      |
| `leather`       |    8   | 1-2 | crafting floor                                       |
| `shadow_dagger` |    6   | 1   | epic +18 dmg / +18% crit — the rarest single drop    |
| **Total**       | **100**|     | matches wolf/goblin/bandit ratio convention          |

Bandit Captain spawns ONLY at `bandits` pressure ≥ 0.70 (gated by
`WorldBuilder._bandit_captain_should_spawn(pressure)`) — the same rung
that maxes regular `bandit_count` to 4. So the table is consulted
roughly once per "extreme-tame" world: the moment the player has driven
both goblins and wolves so quiet that opportunists become bold, the
captain rides in with one shot at the loot. The `crystal_shard` slot
was deliberately tuned at qty 2-4 with weight 12 so a single captain
kill (rare) carries roughly the same shard delivery as a Crystal
Elemental kill (more common but less reliable per-fight) — keeps the
forge economy reachable for either play style.

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

## Live Quest Catalog (run 19 update)

Lives in `World.QUEST_CATALOG`. Mapped to NPCs by `role` field via
`World._quest_for_role(role)`. As of run 23 the resolver iterates
QUEST_CATALOG in dict-insertion order and returns the FIRST entry whose
`role` matches AND whose optional `prerequisite_npc_flag` is satisfied
AND whose `consequence.world_flag` is NOT already set on `world_flags`
— so a single role can issue a SEQUENCE of quests, and a completed
quest auto-yields to the next entry in the chain.

Schema fields:
* Required: `giver`, `actor`, `role`, `kind` (`kill`|`fetch`),
  `target`/`item`, `needed`, `title`, `text`, `xp_reward`,
  `gold_reward`, `motivation`, `location`, `urgency`, `world_trigger`,
  `consequence`.
* Optional: `reward_item`, `reward_item_qty`,
  `prerequisite_npc_flag: ["NPC Name", "flag_name"]` — quest is hidden
  unless the named flag is set on the named NPC's `npc_flags`. (Run 23.
  Quests authored before run 23 omit this field and are equivalent to
  prereq-satisfied. Used today by `bandit_road_for_roan` to gate behind
  Roan's `first_bounty_done`. Future authoring rule: name the prereq's
  source quest in the COMPOUND comment so a future architect can
  trace the chain without grepping npc_flags writers.)

**Authoring rule:** every quest must define a UNIQUE
`consequence.world_flag` (otherwise the auto-skip-on-completion in
`_quest_for_role` would also skip a sibling quest sharing the flag).
All shipped quests (runs 1-23) satisfy this — `first_quest_done` and
similar npc_flags are role-namespaced enough to avoid collisions, and
world_flags are explicitly distinct.

| id                     | giver               | role     | kind  | needed | reward         | faction Δ                  | npc_flag (set)           | world_flag (set)        |
|------------------------|---------------------|----------|-------|--------|----------------|----------------------------|--------------------------|-------------------------|
| `whisperwood_cleansing`| Elder Maeve         | quest    | kill  | 5 goblin | 80 xp / 60 g  | `whisperwood_goblins` -0.2 | `first_quest_done`       | `whisperwood_safer`     |
| `pelt_for_lyra`        | Herbalist Lyra      | alchemy  | fetch | 4 wolf_pelt | 70 xp / 45 g + 2× hp_potion_l | `dire_wolves` -0.1 | `trusts_player`          | `lyra_potion_brew`      |
| `ears_for_mara`        | Mara the Merchant   | shop     | fetch | 6 goblin_ear | 60 xp / 90 g | `whisperwood_goblins` -0.15 | `good_customer`         | `mara_bounty_paid`      |
| `wolf_fang_for_roan`   | Stablemaster Roan   | stable   | fetch | 5 wolf_fang | 65 xp / 50 g | `dire_wolves` -0.1         | `first_bounty_done`      | `roan_bounty_paid`      |
| `wolf_form_with_hala`  | Trainer Hala        | trainer  | kill  | 4 wolf      | 90 xp / 35 g | `dire_wolves` -0.1         | `wolf_form_taught`       | `hala_wolf_form_done`   |
| `wolf_heart_for_bram` ⭐| Innkeeper Bram      | inn      | fetch | 3 wolf_heart| 70 xp / 55 g | `dire_wolves` -0.1         | `nights_quiet`           | `bram_nights_quiet`     |
| `bandit_road_for_roan` ✦| Stablemaster Roan  | stable   | kill  | 4 bandit    | 80 xp / 75 g | `bandits` -0.20            | `road_warden`            | `roan_bandit_road_clear`|

⭐ = NEW in run 19 — FOURTH `dire_wolves` reducer (trips the run-6 third
cliff: pressure 0.1, packs of 1). Bram's role `inn` was QUEST-BLANK before
this entry — `_quest_for_role("inn")` returned `{}`, so the Accept Quest
button never appeared on his dialogue panel in runs 1-18. Now matches
Roan/Mara/Lyra/Hala in dialogue depth (line pitch + warm_flag tier). New
RARE-rarity material `wolf_heart` joins `wolf_pelt` + `wolf_fang` on the
wolf drop table; weights rebalanced to keep total at 100 (relative-odds
drift < 4% per id). Bram is purely additive to the wolf curve, NOT a
fourth flag in the run-18 `wolf_tamer` Achievement predicate — Wolf-Tamer
title still attainable on the Lyra+Roan+Hala arc. The single surviving
wolf at pressure 0.1 reads as "the alpha that wouldn't be hunted" —
boss-feeling fight without a boss-spawn, pure compound on existing
cooldown/chase scalars.

✦ = NEW in run 23 — FIRST quest gated by the new
`prerequisite_npc_flag` schema field (requires Roan's
`first_bounty_done`). FIRST `bandits` faction reducer; the bandits
faction was wired in run 21 with INVERTED pressure semantics (high =
bandits bold), so `pressure_delta: -0.20` is double the wolf-quest
deltas — bandits are meant to be reduced fast. Roan is the FIRST role
with TWO authored quests (`wolf_fang_for_roan` then
`bandit_road_for_roan`); the run-23 resolver handles the sequence
automatically. Composes with the run-22 bandit-camp spawn pattern (the
quest target is the camp the player has already been seeing in cold-
ash form since run 21) and the new run-23 Bandit Captain mini-boss
(spawns at pressure ≥ 0.70, kills count toward the same `target:
"bandit"` counter via `Enemy.KIND_TO_FACTION["bandit_captain"] =
"bandits"`). Reward 80 xp / 75 gold matches Maeve's
`whisperwood_cleansing` tier — Roan's "second errand" sits at the
same gravity as Maeve's "first errand" because by run 23 the player
has earned that weight. Achievement `road_warden` (priority 45,
title "Road-Warden") fires on `roan_bandit_road_clear`.

(Run-18 note retained:) `wolf_form_with_hala` is the run-18 third
`dire_wolves` reducer. Hala's role `trainer` was quest-blank before; now
matches Roan/Mara/Lyra in dialogue depth. FIRST kill-quest after
`whisperwood_cleansing`. Reward economy is XP-heavy (90 xp) / coin-light
(35 g) — befits a teacher who trades knowledge, not gold.

(Original run-17 note retained:) `wolf_fang_for_roan` is the run-17
second `dire_wolves` reducer, mirrors `ears_for_mara` as the second
goblin reducer. Composes with run 6 (spawn density), run 7 (adaptive
cooldown), run 8 (adaptive chase + Roan faction tier), and the run-17
Roan `warm_flag` tier.

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

## Bandit Spawn Schema

✅ **Shipped 2026-05-05 (run 22 — Builder).** Per-load bandit count derives
from `World.faction_pressure("bandits")` with **INVERTED** semantics
relative to the goblin / wolf schemas: high pressure = MORE bandits (bold
on the road), low pressure = NO bandits (dormant). Lives in
`WorldBuilder.gd → _bandit_camp_size(pressure: float) -> Dictionary`.
Returns `{"count": int}` with thresholds:

| Pressure  | Bandits | Co-fires with                                     |
|-----------|---------|---------------------------------------------------|
| < 0.20    | 0       | (camp prop visible as foreshadowing — cold ash)   |
| < 0.40    | 1       | (lone scout; visible BEFORE `bandits_emergent`)   |
| < 0.55    | 2       | `bandits_emergent` flag fires at p ≥ 0.40         |
| < 0.70    | 3       | (player has tamed both goblins & wolves heavily)  |
| ≥ 0.70    | 4       | (extreme-tame state; both factions deeply quieted)|

Pressure is derived by `World.update_bandit_pressure()` as
`raw = (1.0 - 0.5 * (goblin_p + wolf_p)) - 0.20` clamped to `[0, 1]`. At
fresh save (goblin 1.0 + wolf 0.5) raw = 0.05 → `bandit_count = 0`.
Realistic ceiling at extreme tame (goblin 0.0 + wolf 0.0) raw = 0.80 →
`bandit_count = 4`.

`_build_enemies()` reads `bandits` pressure once at world build, derives
camp population, places ONE camp at `Vector3(2, 0, -55)` south of the
path-network terminus, calls `_make_bandit_camp(center)` for the prop,
then spawns `bandit_count` "Bandit Ambusher" enemies in a 2.0–5.5 m
random ring around the camp center. The camp prop is ALWAYS spawned —
even at count 0 — mirroring the goblin "memorial camp" pattern from
run 5: empty camps persist across pressure changes as a "they used to
be here / they will be here" breadcrumb.

Player-facing feedback: deferred call to
`World._show_toast("Hooded figures stalk the south road.")` when
`bandit_count > 0`. Phrased as a fresh threat (not a calmer state) to
match the inverted pressure semantics. Composes with Roan's
`bandits_emergent` warm_world_flag dialogue tier (run 21) — the village
voice and the road state agree at every load.

Authoring rules:
- Read accessor is `World.faction_pressure("bandits")`. Same fail-soft
  guard as goblins/wolves: missing world / missing accessor → baseline
  pressure 0.0 → count 0 (camp prop only).
- Assert at the top of the bandit block enforces `bandit_count ∈ [0, 4]`.
- Bandit stats (HP 42 / dmg 9 / xp 24 / gold 8) sit halfway between
  Goblin Scout (28/6) and Goblin Brute (56/11) — readable as "harder
  than a scout, softer than a brute." Movespd 2.6, chase 4.8 (slightly
  more committed than a scout once seen).
- Bandit `tint` is `Color(0.30, 0.22, 0.18)` — dark weathered leather,
  THEME §3 charcoal palette, §4 hooded silhouette. The
  `KIND_TINT_OVERRIDE["bandit"] = true` entry forces the tint to apply
  to the warrior.glb model (otherwise the painted armor-knight palette
  would override and the enemy would read as a friendly fighter).
- Authoring trap: NEVER pair a bandit-pressure REDUCER (e.g. Roan's
  bandit-clear quest) with `pressure_delta > 0` — that would BUFF
  bandits, the opposite of what the player just did. Reducers MUST use
  `pressure_delta < 0` for the bandit faction.

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
| `bandit`            | `bandits` (INVERTED)    | `[1.05, 1.45]`        |

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
   - 25  `the Forged` (first reforge)
   - 30  `Wolf-Friend` (wolves down 1 cliff)
   - 35  `the Wolf-Tamer` (Lyra + Roan + Hala wolf trio)
   - 40  `Goblin-Bane` (goblins down 1 cliff)
   - 45  `Road-Warden` (run 23 — Roan's bandit-clear)
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

| Achievement                  | Title              | Priority / Renown |
|------------------------------|--------------------|------------------:|
| First Steps                  | the Apprentice     |                10 |
| First Forge                  | the Forged         |                25 |
| Pack Thinner                 | Wolf-Friend        |                30 |
| Tamer of the Wolfwoods       | the Wolf-Tamer     |                35 |
| Bane of the Whisperwood      | Goblin-Bane        |                40 |
| Warden of the South Road ✦   | Road-Warden        |                45 |
| Trusted by Three             | the Trusted        |                50 |
| Warden of the Realm          | Warden of Eldoria  |               100 |

✦ = NEW in run 23 — fires on `world_flag: roan_bandit_road_clear` set
by `bandit_road_for_roan` quest completion. Title slots between
Goblin-Bane and Trusted because clearing the south road is a player-
AGENCY beat (one quest does it) whereas faction-below-threshold and
three-NPC-trust beats accumulate over multiple sessions.

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

---

## Whisperwood asset wire-up (run 13)

### Schema additions

`WorldBuilder.gd`:

| Member                               | Notes                                                       |
|--------------------------------------|-------------------------------------------------------------|
| `TREE_VARIANTS: Array`               | 4 dicts: `{path, weight, scale_min, scale_max, kind}`       |
| `BOULDER_GLB_PATH: String`           | `res://assets/models/props/boulder.glb`                     |

### Helper API

| Method                                                  | Returns       | Notes                                                       |
|---------------------------------------------------------|---------------|-------------------------------------------------------------|
| `_load_glb_safe(path)`                                  | `PackedScene` | `null` if path doesn't exist or doesn't resolve to a scene  |
| `_pick_tree_variant(rng)`                               | `Dictionary`  | Weighted pick over `TREE_VARIANTS`; pure given RNG state    |
| `_settle_to_ground(node)`                               | `void`        | Deferred AABB-driven y-offset fix; idempotent on re-run     |
| `_make_glb_tree(pos, rng)`                              | `bool`        | True on success; false → caller falls back to procedural    |
| `_make_glb_boulder(pos, rng)`                           | `bool`        | True on success; false → caller falls back to sphere        |

### TREE_VARIANTS today

| Path                                          | Weight | Scale band   | Kind   |
|-----------------------------------------------|-------:|--------------|--------|
| `res://assets/models/trees/oak_tree.glb`      |  0.45  | 1.20 → 1.85  | `oak`  |
| `res://assets/models/trees/pine_tree.glb`     |  0.30  | 1.40 → 2.10  | `pine` |
| `res://assets/models/trees/bush.glb`          |  0.20  | 0.55 → 0.95  | `bush` |
| `res://assets/models/trees/dead_tree.glb`     |  0.05  | 1.10 → 1.55  | `dead` |

### Spawned-node groups produced this run

- `"trees"` — already existed, the `_process` wind-sway loop iterates it.
  Now includes GLB-instanced trees in addition to the legacy procedural
  ones. New per-tree metadata: `tree.get_meta("tree_kind")` returns the
  TREE_VARIANTS `kind` tag. Future readers can filter (e.g. cursed-grove
  biome could prefer kind=="dead", quest spawns near kind=="oak").
- `"boulders"` — NEW group. Currently consumed by no readers, but is a
  natural anchor for: cover-aware enemy AI, hide-spot quest triggers,
  Crystal Caves entrance dressing (backlog #1, NW Vector3(-50, 0, -40)).

### Authoring rules

1. **GLB-first, procedural-fallback.** Every spawner using a Sketchfab
   asset MUST go through `_load_glb_safe(path)` and check for null. If
   null, fall through to the legacy primitive code path. The world build
   never goes empty.
2. **Ground contact via deferred AABB.** Any wrapper Node3D that holds an
   instanced GLB SHOULD call `call_deferred("_settle_to_ground", holder)`.
   The function is idempotent so it's safe even if the asset already sits
   correctly.
3. **Group membership is the motion contract.** Adding a tree to group
   `"trees"` is sufficient to wire it into the existing wind-sway loop.
   No per-spawner motion code needed. Future motion groups (e.g.
   `"banners"`, `"flames"`) follow the same pattern.
4. **`kind` metadata is a future-quest hook.** Don't grep tree positions
   to identify species — read `tree.get_meta("tree_kind")`.

### Hooks consumed / produced this run

CONSUMES:
- `_process` wind-sway loop (existing) — auto-applies to every group
  `"trees"` member, including the new GLB instances.
- `_measure_aabb(node)` (existing) — used by `_settle_to_ground` to find
  the visible bottom of any model.
- `ResourceLoader.exists(path)` (Godot built-in) — guards every GLB load
  so missing assets degrade gracefully.

PRODUCES:
- `tree.get_meta("tree_kind")` — biome / quest / lore filter surface.
- `get_tree().get_nodes_in_group("boulders")` — cover-aware AI / quest
  triggers / Crystal Caves dressing.
- `_load_glb_safe(path)` — reusable for any future GLB wire-up (props,
  enemies, market stalls, etc.).
- `_settle_to_ground(node)` — generic ground-contact helper, not
  GLB-specific; can be called after any deferred-spawn flow that needs
  THEME §13 compliance.


## Achievements Panel (run 13 — UI surface)

The Achievements & Titles Panel is the FIRST UI surface in the engine
that loads and renders a painterly icon asset (PNG → Texture2D →
TextureRect). The pattern is intentionally simple so future panels (NPC
portraits, enemy bestiary, item icons) can copy it verbatim.

### Trigger

`KEY_J` in `Player._input` calls `get_tree().call_group("world",
"toggle_achievements")`. Same shape as the KEY_I inventory binding.

### Owner

`World.gd`. Lazy build on first `toggle_achievements()`. Subsequent
opens just flip `visible` and call `_refresh_achievements_ui()`.

### Widget bundle schema

`ach_card_widgets[id] -> Dictionary` with shape:

```
{
  "root":       PanelContainer,   # the card's outer container — pulse target
  "crest":      TextureRect,      # 96×96 painterly PNG (load(icon_path))
  "name":       Label,            # icon + name, palette §3 burnt gold
  "desc":       Label,            # description, parchment cream, autowrap
  "title_hint": Label,            # "Grants: \"<title>\"" line
  "lock":       Label,            # 🔒 over the crest, hidden when unlocked
}
```

### Rendering rules

| State    | crest.modulate              | name color | lock visible |
|----------|-----------------------------|------------|--------------|
| Unlocked | (1, 1, 1, 1)                | gold §3    | false        |
| Locked   | (0.45, 0.45, 0.45, 0.85)    | dim grey   | true         |

### THEME §12 motion contract

`_pulse_card(node)` — 2-loop sine-eased modulate pulse over 0.9s,
amplitude `(1.25, 1.15, 0.85)`. Fires on the card whose id matches
`world._last_achievement_unlocked` when the panel opens. The state
field is written by `_check_achievements` adjacent to the existing
toast logic — same write site, separate read consumer.

### Icon-path → TextureRect pattern (canonical)

```gdscript
var icon_path: String = String(entry.get("icon_path", ""))
if icon_path != "" and ResourceLoader.exists(icon_path):
    var tex: Texture2D = load(icon_path) as Texture2D
    if tex != null:
        crest.texture = tex
```

Future panels (NPC portrait dialogue, item bag tooltip, enemy bestiary)
SHOULD copy this guard verbatim. The `ResourceLoader.exists` check makes
the call fail-soft when an asset is missing — the TextureRect simply
stays empty, the rest of the card renders normally.

### Authoring rules

1. **No new world primitive in this panel.** Same constraint as
   `Achievements.gd` — every render-time read must hit existing world
   state (`unlocked_achievements`, `current_title`,
   `Achievements.evaluate(self)`).
2. **Priority-ordered render.** `_achievements_in_priority_order()` sorts
   by `title_priority` so the panel reads as a left-to-right
   apprenticeship-to-mastery ladder. Lower priority renders first.
3. **Fail-soft on missing assets.** `ResourceLoader.exists` guards every
   `load()`. A missing PNG leaves the TextureRect empty; the emoji
   `entry.icon` glyph remains visible in the name label as the
   text-fallback path.

### Hooks consumed / produced this run

CONSUMES:
- `Achievements.ACHIEVEMENTS` (existing schema) — single source of truth.
- `Achievements.evaluate(self)` (existing pure evaluator).
- `world.unlocked_achievements: Dictionary[String, bool]` (existing).
- `world.current_title: String` (existing).
- `entry.icon_path: String` schema field (existing on Achievements
  entries since run 11; this is the FIRST consumer).
- `assets/icons/achievements/*.png` (Art shipped six painterly crests).

PRODUCES:
- `world.toggle_achievements()` — public method, group-callable.
- `world._last_achievement_unlocked: String` — NEW state field, written
  by `_check_achievements`, consumed by `_refresh_achievements_ui` to
  drive the just-unlocked pulse.
- `world.ach_card_widgets: Dictionary[String, Dictionary]` — widget
  registry, one entry per achievement id; future extensions (per-card
  click-to-show-quest-tip, etc.) can re-enter this registry without a
  rebuild.
- `KEY_J` binding in Player.gd — first new keybinding since the M-mount
  toggle. Future panels (M for map, K for skill tree, etc.) follow the
  same `get_tree().call_group("world", ...)` shape.

## Mini-Map & World-Map (Builder run 14)

A two-tier map system. Both views render from the SAME data, so a new
landmark or zone shows in both simultaneously.

### Schema — `Minimap.LANDMARKS`

| Field   | Type     | Notes                                             |
|---------|----------|---------------------------------------------------|
| `pos`   | Vector3  | World position                                    |
| `name`  | String   | Label shown by the full WorldMap                  |
| `kind`  | String   | Dispatch tag (see kinds below)                    |
| `color` | Color    | Pin color (THEME §3 palette)                      |
| `icon`  | String   | Single-glyph emoji (used by full WorldMap)        |

**Kinds:** `village | well | campfire | cave | camp | boss | shrine`.
A new kind = one new branch in `_draw_landmark_glyph` (Minimap.gd) and
`_draw_lm_glyph` (WorldMap.gd).

### Schema — `WorldMap.REGIONS`

| Field   | Type             | Notes                                |
|---------|------------------|--------------------------------------|
| `name`  | String           | Region label                         |
| `color` | Color (with α)   | Watercolor-wash tint                 |
| `poly`  | Array[Vector2]   | World XZ polygon outline             |

### Group hooks (no new state — read existing groups)

| Group           | Drawn as              | Source                       |
|-----------------|----------------------|-------------------------------|
| `player`        | Centered pulsing dot | Player.gd `_ready` (existing) |
| `npcs`          | Gold pin             | WorldBuilder._make_npc (NEW)  |
| `enemies`       | Crimson pin (flashing in aggro) | Enemy.gd `_ready` |
| `bosses`        | Warlock-purple skull | Boss.gd `_ready`              |
| `chests`        | Bronze ring          | Chest.gd `_ready`             |
| `goblin_fires`  | Ember dot            | WorldBuilder._make_goblin_camp|

### Public API

| Method on World                                  | Effect                              |
|--------------------------------------------------|-------------------------------------|
| `toggle_world_map()`                             | Open/close fullscreen map (KEY_N)   |
| `ping_minimap(world_pos, color)`                 | Flash an expanding ring (1.4s)      |
| `Minimap.set_visible_radius(meters)`             | Zoom (8m..200m, default 30m)        |
| `Minimap.landmark_at(name) -> Vector3`           | Schema lookup                       |

### Inputs

| Key  | Action               | Owner          |
|------|----------------------|----------------|
| N    | Toggle World Map     | Player.gd      |
| —    | Mini-map always-on   | Minimap.gd     |

---

## UITheme module (run-15 ship)

Single-source-of-truth UI styling helper, registered via
`class_name UITheme` (no autoload required — call statically). Replaces the
five-run-flagged duplicate `add_theme_color_override` boilerplate scattered
across panel builders in `World.gd`.

### File
`eldoria-godot/scripts/UITheme.gd` (322 lines, 14 helpers + self-test).

### Palette constants
| Const | Value | THEME §3 source |
|-------|-------|-----------------|
| `UITheme.GOLD` | `Color(1.00, 0.85, 0.40)` | burnt gold (primary) |
| `UITheme.SUNSET_ORANGE` | `Color(1.00, 0.50, 0.00)` | `#FF8000` |
| `UITheme.CRIMSON` | `Color(0.55, 0.13, 0.13)` | `#8C2020` wine |
| `UITheme.MOSS_GREEN` | `Color(0.29, 0.44, 0.22)` | forest moss |
| `UITheme.PARCHMENT` | `Color(0.85, 0.79, 0.61)` | `#D9C99B` |
| `UITheme.PARCHMENT_CREAM` | `Color(0.92, 0.85, 0.65)` | warmer cream tier |
| `UITheme.INK_BLACK` | `Color(0.05, 0.04, 0.05)` | `#0E0A0E` |
| `UITheme.BRASS` | `Color(0.69, 0.46, 0.16)` | `#B0742A` |
| `UITheme.STAG_BLOOD` | `Color(0.63, 0.13, 0.13)` | `#A02020` |
| `UITheme.STONE_BLUE` | `Color(0.48, 0.53, 0.58)` | `#7B8693` |
| `UITheme.FEY_CYAN` | `Color(0.40, 0.87, 0.90)` | magic accent |
| `UITheme.ARCANE_PURPLE` | `Color(0.49, 0.25, 0.69)` | warlock |
| `UITheme.FROST_SILVER` | `Color(0.78, 0.88, 0.90)` | frost |

### Font-size constants (THEME §5 hierarchy)
| Const | Px | Use |
|-------|----|-----|
| `FS_TOAST` | 28 | screen-center transient |
| `FS_TITLE` | 24 | panel header |
| `FS_HEADER` | 22 | secondary header |
| `FS_SUBTITLE` | 16 | column header |
| `FS_BODY_LG` | 14 | button face / counter |
| `FS_BODY` | 13 | RichTextLabel default |
| `FS_BODY_SM` | 12 | hint, footer, desc |
| `FS_TINY` | 11 | title-hint micro |
| `FS_LOCK` | 36 | 🔒 overlay glyph |
| `FS_BAG_GLYPH` | 22 | bag-slot item glyph |

### Asset-path constants (CC0, scripts/art/make_ui_frames.py seed 8131)
- `ASSET_PARCHMENT_LARGE` → `res://assets/ui/parchment_panel.png` (512×512)
- `ASSET_PARCHMENT_SMALL` → `res://assets/ui/parchment_panel_small.png` (256×256)
- `ASSET_WOOD_PANEL` → `res://assets/ui/wood_panel.png` (512×384)
- `ASSET_BTN_NORMAL`/`HOVER`/`PRESSED` → `res://assets/ui/button_*.png` (192×64)
- `ASSET_DIVIDER_ORNATE` → `res://assets/ui/divider_ornate.png` (384×24)
- `ASSET_SCROLL_BANNER` → `res://assets/ui/scroll_banner.png` (512×128)
- 9-slice patches: `PATCH_BIG=64`, `PATCH_SMALL=32`, `PATCH_BTN=16`

### Helper API
```
UITheme.style_panel_parchment(panel)         # NinePatchRect bg, idempotent
UITheme.style_panel_wood(panel)              # wood_panel.png variant
UITheme.style_iron_button(btn)               # 3-state texture stylebox
UITheme.style_title_label(lbl)               # 24pt gold + outline
UITheme.style_subtitle_label(lbl)            # 16pt gold
UITheme.style_name_label(lbl)                # 16pt gold + outline (cards)
UITheme.style_count_label(lbl)               # 14pt cream
UITheme.style_body_label(lbl)                # 13pt cream
UITheme.style_desc_label(lbl)                # 12pt cream
UITheme.style_hint_label(lbl)                # 12pt dim white
UITheme.style_micro_hint_label(lbl)          # 11pt brass
UITheme.style_lock_label(lbl)                # 36pt dim w/ cream outline
UITheme.style_tooltip_label(lbl)             # 13pt white + outline
UITheme.style_richtext(rt)                   # RichTextLabel cream defaults
UITheme.make_toast_label(text) -> Label      # 28pt gold + outline
UITheme.spawn_damage_popup(parent, world_pos, text, color, font_size, outline_size) -> Label3D  # 12-site DRY helper
UITheme.self_test() -> [bool, String]        # asset reachability
```

### Idempotency contract
`style_panel_parchment` and `style_panel_wood` set
`panel.set_meta("_eldoria_themed", true)`. Re-calling on the same panel
is a no-op. Marker child `EldoriaParchmentBG` added at index 0 so all
existing children draw on top.

### Run-15 callsites (initial migration)
- `World.gd::_show_toast` — uses `make_toast_label`
- `World.gd::_build_inventory_ui` — `style_panel_parchment`,
  `style_title_label`, `style_iron_button` (close ✕),
  `style_subtitle_label` (×2), `style_richtext`, `style_hint_label`,
  `style_tooltip_label`
- `World.gd::_build_achievements_ui` — `style_panel_parchment`,
  `style_title_label`, `style_iron_button` (close ✕),
  `style_subtitle_label`, `style_count_label`, `style_desc_label`
- `World.gd::_build_one_achievement_card` — `style_lock_label`,
  `style_name_label`, `style_desc_label`, `style_micro_hint_label`

### Future seams (next-run hooks)
- DialoguePanel (Main.tscn) — replace `theme_override_*` directly in
  the .tscn with `UITheme.style_panel_parchment` + label helpers in
  `_setup_dialogue_actions`
- Future bestiary panel — should call `style_panel_parchment` + grid
  pattern from `_build_achievements_ui`
- HUD bars (HPBar/MPBar/XPBar) — could move to UITheme.style_progressbar
  in a follow-up, currently still tscn-defined
- Smith Edda forge UI (backlog #2) — start with `style_panel_parchment`,
  three-tab layout reusing the bag-grid pattern


## NPC Visit Memory schema (run 16 — Builder)

Per-NPC visit ledger maintained by `World.gd`. Complements the existing
`npc_flags` (quest-derived memory) and `world_flags` (deed-derived memory)
by capturing the CADENCE of player-NPC interaction independent of quests.

### State

```gdscript
# World.gd
var world_day: int = 0          # increments when time_of_day wraps past midnight
var _prev_tod: float = 11.0     # private witness for the wrap detector
var npc_memory: Dictionary = {} # npc_name -> entry dict
```

Entry shape:

```gdscript
{
    "visits":     int,    # total triggered _on_interact calls
    "first_day":  int,    # world_day on first visit (-1 = never met)
    "last_day":   int,    # world_day on most recent visit
    "first_tod":  float,  # time_of_day on first visit
    "last_tod":   float,  # time_of_day on most recent visit
}
```

### API

| Method | Direction | Notes |
|---|---|---|
| `record_npc_visit(name: String)` | mutator (sole writer) | Called from `NPC.gd::_on_interact` BEFORE tier resolution, so the triggering visit is included in the count. Idempotent within frame in the sense that NPC.gd's KEY_E + InteractArea debounce prevents re-fires. |
| `npc_visits(name) -> int` | read | 0 if never met. |
| `npc_first_visit_day(name) -> int` | read | -1 if never met. |
| `npc_last_visit_day(name) -> int` | read | -1 if never met. |
| `npc_days_since_last_visit(name) -> int` | read | -1 if never met (lets caller distinguish "never" from "today"). |

### Dialogue tier integration

NPC.gd consumes `npc_visits(name)` via two new exports:

```gdscript
@export var warmed_memory_visits_min: int = 0
@export var warmed_memory_dialogue_variants: PackedStringArray = PackedStringArray()
```

Threshold of 0 disables the tier (default — purely additive). The tier
sits BETWEEN faction-pressure (tier 4) and time-of-day default (tier 6),
inserted at line ≈185 of NPC.gd `_on_interact`. The same fail-soft
pattern as the other tiers: `w and w.has_method("npc_visits")` so older
World autoloads keep working.

### Tier order (post-run-16)

1. JSON-tree (DialogueDB, `use_json_dialogue`)
2. NPC-flag warmed (`warmed_flag`)
3. World-flag warmed (`warmed_world_flag`)
4. Faction-pressure warmed (`warmed_faction_id` + `warmed_faction_below`)
5. **Visit-memory warmed (`warmed_memory_visits_min` — run 16)**
6. Time-of-day default (`dialogue_variants`)

### Run-16 authored consumers

| NPC | `memory_visits_min` | Variant count | Authoring intent |
|---|---|---|---|
| Elder Maeve | 3 | 4 (tod buckets) | Recognizes regulars; offers tea by hearth |
| Innkeeper Bram | 3 | 4 | "Regular at the bar" cadence; reserved chair |
| Trainer Hala | 3 | 4 | Named-student attention; harder drills |

Threshold uniformity (3 across all three) is deliberate — a player making
the village rounds three times unlocks all memory-aware NPCs together,
keeping the "world warmed up" beat coherent rather than staggered.

### Why memory below faction

A villager who senses the Whisperwood is calmer (faction tier) speaks
about the WORLD; a villager who notices you've come back many times
speaks about the RELATIONSHIP. The world-state line is louder content
when both apply — recognizing a returning friend is the conversational
fallback when nothing more newsworthy is in scope.

### Persistence (forward contract)

`npc_memory` is per-session today. When save/load lands:
- `world_day` persists as an int (1 token).
- Per-NPC entry serializes as `[visits, first_day, last_day]` — the
  `_tod` floats can be dropped on save/load without loss of dialogue
  tiering (only `visits` drives the existing predicate).
- A loaded save with `npc_memory == {}` is indistinguishable from a
  fresh world; nothing breaks if the field is omitted.

### Future seams (next-run hooks)

- **"Visited every villager" achievement** — `Achievements.gd` predicate
  could iterate WorldBuilder.NPCS, count `World.npc_visits(name) > 0`
  for each, and unlock at full coverage. The NPC-flag predicate language
  already exists; a `min_visits_each(npcs[], n)` keyword is a small
  addition.
- **Returning-after-absence variants** — a future tier keyed on
  `npc_days_since_last_visit(name) >= N` (the accessor already returns
  the value). Concept lines: "Where've you BEEN, you stranger?" — fires
  when you skip a villager for 3+ in-game days.
- **Memory-aware quest gating** — quests can require
  `npc_visits("Smith Edda") >= 1` to unlock the forge questline,
  closing the "talked once" → "trusted with errands" loop.
- **Decay** — long-absent visits could halve the visit count or push the
  player back into cold-greeting variants. Today there is no decay; add
  by gating tier resolution on BOTH `visits >= min` AND
  `npc_days_since_last_visit < N`.


## NPC Stranger schema (run 20 — Builder)

`World.npc_seen: Dictionary[String, bool]` is a per-session "have we ever
met?" ledger, set by `World.mark_npc_seen(name)` and read by
`World.is_stranger(name)` and (transparently) by
`DialogueDB.choose_line()`'s pre-existing 5th-tier `stranger` predicate.

### API

| Member | Direction | Notes |
|---|---|---|
| `npc_seen: Dictionary` | field | Public; DialogueDB.choose_line() reads via `world_node.get("npc_seen")` directly. Future readers should prefer `is_stranger(name)`. |
| `mark_npc_seen(name: String)` | mutator (sole writer) | Called from `World.show_dialogue(speaker, …)` AFTER `dialogue_panel.visible = true`. Idempotent. Empty / null name → no-op. |
| `is_stranger(name: String) -> bool` | read | Returns true for any NPC who has not yet had a `show_dialogue` call complete. Future quest predicates / achievements should consume via this accessor, not the raw dict. |

### Why `mark_npc_seen` runs from `show_dialogue` (post-condition)

NPC.gd's `_on_interact` does, in order:
1. `record_npc_visit(name)` — `visits` increments to ≥ 1 (run 16).
2. `DialogueDB.choose_line(name, ctx)` — predicates evaluate against the
   CURRENT `npc_seen` state. The `stranger` check fires only when
   `npc_seen[name] != true` (the ELSE branch of the bool coercion in
   `DialogueDB`).
3. `world.show_dialogue(name, line, role)` — pushes line to UI panel,
   then calls `mark_npc_seen(name)` as the final step.

If `mark_npc_seen` ran any earlier (e.g. inside `record_npc_visit`), the
`stranger` predicate would never fire because by step (2) the entry
would already be `true`. The post-condition order is the only correct
order.

### Distinct from `npc_memory.visits`

| Field | When it changes | First-visit window |
|---|---|---|
| `npc_memory.visits` | TOP of `_on_interact` (`record_npc_visit` — run 16) | invisible to a `visits == 0` predicate; visits is already 1 by the time DialogueDB sees it |
| `npc_seen[name]` | END of `show_dialogue` (`mark_npc_seen` — run 19) | the OLD `false` is what DialogueDB reads on the first hello, the NEW `true` is what every subsequent hello sees |

Both fields are owned by `World`; both are session-scoped today (no
save/load yet); both are pure post-conditions of `_on_interact`.

### Lights up

Wiring `npc_seen` activates the `stranger` JSON key for every NPC that
opts into JSON dialogue. As of run 20 that is **all 7 villagers**:
Elder Maeve, Smith Edda, Mara the Merchant, Herbalist Lyra, Innkeeper
Bram, Stablemaster Roan, Trainer Hala. Each `stranger` key was authored
by the Lore Keeper agent on 2026-05-04 and has been dormant ever since.

The DialogueDB priority order means `stranger` outranks the 4
time-of-day mood buckets and the legacy `after_first_quest_complete`
JSON key — so the FIRST hello to a never-met NPC is guaranteed to be
the authored "stranger" line, not a generic morning/midday greeting.
The SECOND hello falls back into the normal predicate stack.

### Failsafe contract (forward)

- `mark_npc_seen("")` → no-op (defensive against bare/empty speaker
  strings reaching `show_dialogue`).
- Re-marking an already-seen NPC → idempotent overwrite, no events.
- Older saves missing the `npc_seen` field → coerced to empty
  Dictionary by Godot's default-value rule on the typed field.
  Effective behavior: every NPC reads as a stranger on the first
  hello after load. This is the desired UX for save/load semantics
  (the player just woke up; meeting feels fresh).

### Future seams (next-run hooks)

- **"Met every villager" achievement** — `Achievements.gd` predicate
  iterating WorldBuilder.NPCS and checking
  `not World.is_stranger(name)`. Pairs with the run-16 "Visited every
  villager" hook (different threshold: 1 vs N visits).
- **"Stranger no longer" world flag** — could fire once
  `npc_seen.size() >= 7`, opening up cross-NPC dialogue lines that
  reference the ENTIRE village having met the player. Pure derivation
  from `npc_seen`, no new state.
- **Per-NPC first-meeting day** — extending the value type from `bool`
  to `Dictionary {seen: true, met_day: int, met_tod: float}` would let
  NPCs say things like "you've been around three days now". The
  accessor signature stays stable because callers use
  `is_stranger(name)` rather than reading the dict directly.


---

## Bandits faction (run 21 — Builder)

### Schema

| Faction id | Disposition | Initial pressure | Semantics |
|------------|-------------|------------------|-----------|
| `bandits`  | `hostile`   | 0.0 (dormant)    | INVERTED — high = bandits bold, low = bandits hidden |

`bandits` is the FIFTH faction in `World.factions`, sitting alongside
`briarwood`, `whisperwood_goblins`, `dire_wolves`, `crystal_caves`. The
inverted-pressure convention is documented inline; downstream readers
(NPC dialogue tier 3, Enemy.gd cooldown band, Enemy.gd chase-speed band,
WorldBuilder spawn density) operate on the raw 0.0–1.0 scalar without
caring which direction "high" means — the lerp endpoints encode the
intent at each call site.

### Derivation

`World.update_bandit_pressure()` is the SINGLE writer. It recomputes
the bandit pressure as

```
bandit_pressure = clamp(1.0 - 0.5*(goblin_pressure + wolf_pressure) - 0.20, 0.0, 1.0)
```

and is called once per `apply_consequence` (Step 5a, before
`_check_achievements`) so achievements see consistent state.

The 0.20 buffer prevents flicker on a single first-quest pressure drop:
at fresh-save (goblin 1.0, wolf 0.5, avg 0.75 → bandit 0.05) bandits
stay dormant. Only after MULTIPLE quest reducers across both factions
does the bandit scalar climb past the 0.40 emergence threshold.

### `bandits_emergent` world flag

Set in the same call when `bandit_pressure >= 0.40`, cleared otherwise.
This is the FIRST world flag whose value is a DERIVED function of two
faction scalars rather than a direct quest-consequence write. Every
existing world flag (`mara_bounty_paid`, `lyra_potion_brew`, etc.) is
written by `apply_consequence`'s Step 2 — `bandits_emergent` is written
by Step 5a's derivation. Authoring contract: do NOT add this flag to a
quest's `consequence.world_flag` field; it would be overwritten on the
next pressure mutation. Downstream readers treat it as queryable
post-condition, not authored fact.

### Bandit drop table

| id            | weight | qty   | notes                                            |
|---------------|--------|-------|--------------------------------------------------|
| `hp_potion_s` |   28   | 1-2   | floor — bandits carry travel pots                |
| `cloth`       |   22   | 1-2   | "looted from a traveler" junk-tier               |
| `leather`     |   18   | 1     | crafting material — bandit cloak/strap proxy     |
| `rusty_sword` |   12   | 1     | cheap-weapon tier                                |
| `iron_sword`  |   10   | 1     | mid-tier weapon                                  |
| `chainmail`   |    6   | 1     | occasional armor upgrade                         |
| `steel_blade` |    4   | 1     | rare reward — bandit boss-band fodder            |
| **Total**     | **100**|       | matches wolf/goblin ratio-based math             |

Drop table SHIPS BEFORE bandit enemies actually spawn — same fail-soft
contract Items.gd already uses for `skeleton` / `crystal_elemental`
tables that pre-existed their spawn paths. Future runs adding
`coin_pouch` or `lockpick` materials should pull from `cloth` (22), the
junk-tier floor most tolerant of weight rebalancing.

### Lights up

Five existing systems light up automatically the moment a bandit-kind
enemy spawns and `Enemy.gd.KIND_TO_FACTION["bandit"] = "bandits"`
resolves:

1. **`Enemy.attack_cooldown`** (run 7) — pressure 0.8 → ~1.13s recovery
   (agitated band); pressure 0.0 → 1.45s baseline. The agitated ⚡ prefix
   on bandit name reads naturally as "they're feeling brave today."
2. **`Enemy.chase_speed`** (run 8) — same scalar drives the speed band.
3. **`WorldBuilder._build_enemies` density** (runs 5/6 pattern) — when
   the road-spawn pattern lands, a `_bandit_camp_size(pressure)` helper
   mirrors the existing goblin/wolf helpers.
4. **NPC dialogue tier 3** (run 4) — Roan's `warm_world_flag` of
   `bandits_emergent` is the FIRST consumer wired this run.
5. **Achievements.gd predicate eval** — any future
   `[["bandits_emergent", true]]` predicate composes with the existing
   `all_world_flags` checker without code changes.


---

## captain_seal material + Maeve sequence (run 24 — Builder)

### Schema

| Item id        | Type       | Rarity | Value | Stack | Drops from        |
|----------------|------------|--------|-------|-------|-------------------|
| `captain_seal` | material   | rare   |  60   | true  | bandit_captain    |

`captain_seal` is the FIRST new material since run-21 wolf_heart. The
inventory-tooltip blue chip (rarity "rare") fires the moment it drops —
silhouette beat distinct from the bandit pocket-lint floor
(cloth/leather/rusty_sword) and the captain's mid-tier weapon roll
(steel_blade/chainmail). Value 60 sits cleanly between wolf_heart (32)
and warlord_horn (250) on the rarity ladder.

### Drop weight rebalance — `bandit_captain` (Items.gd)

| id             | run-23 weight | run-24 weight | delta |
|----------------|---------------|---------------|-------|
| steel_blade    | 24            | 24            |   —   |
| chainmail      | 18            | 18            |   —   |
| ember_axe      | 12            |  8            |  -4   |
| crystal_shard  | 12            | 12            |   —   |
| hp_potion_l    | 12            | 10            |  -2   |
| crit_amulet    |  8            |  8            |   —   |
| leather        |  8            |  4            |  -4   |
| shadow_dagger  |  6            |  0            |  -6   |
| **captain_seal** | (—)         | **16**        | NEW   |
| **Total**      | **100**       | **100**       |       |

shadow_dagger removal from this single table is fail-soft — the item
remains in the ITEMS catalog and continues to drop from the wolf and
crystal_elemental tables (Items.gd line ~187 wolf table, line ~311
crystal_elemental table).

### Maeve's two-quest sequence (cross-NPC `prerequisite_npc_flag`)

| Order | Quest id                  | Prereq                                 | World flag set         |
|-------|---------------------------|----------------------------------------|------------------------|
| 1st   | `whisperwood_cleansing`   | (none — fresh-save default)            | `whisperwood_safer`    |
| 2nd   | `captain_seal_for_maeve`  | `["Stablemaster Roan", "road_warden"]` | `maeve_seal_kept`      |

This is the FIRST cross-NPC application of run-23's
`prerequisite_npc_flag` schema. Maeve's `quest` role now chains TWO
authored quests, AND the second quest's prerequisite cites a DIFFERENT
NPC's flag (Roan, set by `bandit_road_for_roan`). The schema's
single-role-iteration resolver (run 23) handles this without
modification — first-defined wins, prerequisite check is per-quest, not
per-role.

### Why no faction `pressure_delta`

`captain_seal_for_maeve` deliberately omits the `consequence.faction`
field (Step 1 of `apply_consequence` skips when faction_id is empty).
Two reasons:

1. **Bandits faction is INVERTED + DERIVED.** `update_bandit_pressure()`
   is the SOLE writer of `factions["bandits"].pressure` (run 21,
   Step 5a). Any pressure_delta on bandits in a quest consequence is
   immediately overwritten on the same `apply_consequence` call. Adding
   one would be cosmetic noise.
2. **Goblins / wolves are unrelated to the seal.** The captain commanded
   a hooded camp, not a goblin or wolf war-band. A pressure_delta on
   either would mis-attribute Maeve's memorial gesture to a
   faction-warfare beat — wrong narrative shape.

The quest's consequence is therefore `npc_flag` + `world_flag` + `toast`
+ xp/gold ONLY — canonically the same shape as a memorial errand.
Future memorial-errand quests should mirror this shape rather than
defaulting to faction-tilt.

### `seal_keeper` achievement

| Predicate | `world_flag: maeve_seal_kept` |
|-----------|-------------------------------|
| Title     | "Seal-Keeper"                 |
| Priority  | 47                            |
| Slot      | between Road-Warden (45) and Trusted (50) |
| Icon      | 🕯 (emoji fallback) / `seal_keeper.png` |

Auto-equipper picks Seal-Keeper on quest completion, then yields to
Trusted once the third villager flag flips (assuming Lyra/Roan/Mara are
all bountied). The title's gravity sits above road_warden (a one-quest
beat) but below trusted_three (a multi-NPC accumulation), matching the
canonical weighting: clearing a road is one act; trusting the
neighbors-cycle is many.

### Lights up (immediate)

1. **The `prerequisite_npc_flag` schema's CROSS-NPC contract.** Run 23
   proved intra-NPC sequencing; run 24 proves cross-NPC. The schema is
   now production-ready for any future authored quest sequence (Maeve
   chains, faction-leader chains, ceremonial-quest chains, etc.).
2. **Maeve's second-quest pacing.** Until run 24, Maeve issued ONE
   quest (`whisperwood_cleansing`) and ran out. Now her role yields a
   late-game pitch tied to road politics — closes the
   "Maeve has nothing for me anymore" UX gap.
3. **`maeve_seal_kept` joins the world-flag ledger** as the EIGHTH
   quest-issued flag (after mara_bounty_paid / lyra_potion_brew /
   whisperwood_safer / roan_bounty_paid / hala_wolf_form_done /
   bram_nights_quiet / roan_bandit_road_clear). Future cross-NPC
   warm_world_flag tiers can read it without code changes.
4. **`captain_seal` appears in the inventory tooltip** with the
   blue-chip rarity color the moment it drops — silhouette beat for
   "you killed something *named*" distinct from the captain's mid-tier
   weapon rolls.

### Future seams (next-run hooks)

- **Maeve's `seal_kept` warm_lines** (Lore Keeper). The flag is set on
  quest completion; NPC.gd's tier-2 resolver picks the FIRST flag in
  npc_flags. Authoring 4 `seal_kept` warm_lines AHEAD of the existing
  `first_quest_done` block in WorldBuilder.NPCS would make them
  outrank the older lines once both flags are set.
- **Edda's first warm tier reads `maeve_seal_kept`** (Builder). Edda is
  the only 0-tier NPC. `warm_world_flag: "maeve_seal_kept"` + 4
  cross-NPC lines compounds Edda into the warm-tier club AND validates
  the new flag's cross-NPC reach. Wardens-of-the-Mark canon: Edda (the
  keeping-warm) sees Maeve (the keeping-vigil) keeping the seal.
- **Mara reads `roan_bandit_road_clear` or `maeve_seal_kept`**
  (Builder). Mara has an open warm_world_flag slot — a market-trader's
  commentary on the road becoming travelable again would compound the
  flag economy across a 4th NPC.
- **Captain_seal as a Builder-prop on Maeve's mantle.** Currently the
  captain_seal is an inventory-only item once handed in. A future
  Builder run could surface it as a visible mantle-prop in Maeve's hut
  (gated on `world_flags.has("maeve_seal_kept")`) — closes the
  symbolic loop ("she keeps it") into a literal one.
- **`maeve_seal_kept` on the realm_warden predicate.** The current
  `realm_warden` (Achievements.gd) requires both faction reductions +
  three NPC trusts. A future Builder run could elevate the bar by
  ALSO requiring `maeve_seal_kept`, codifying the political beat into
  the mastery-rung achievement.

