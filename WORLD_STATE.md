# World State — Realm of Eldoria

Canonical facts about the world. This is the source of truth for *what exists*
and *what has happened*. Update this file whenever the world changes.

## World Canon

### Geography
- **Briarwood Village** (origin, friendly hub). 7 named NPCs, 6 buildings,
  cobble path network, well, pond, windmill, market stalls, lanterns, banners,
  campfires. Mountain ring (36 inner + 28 outer peaks with snow caps).
- **Whisperwood Forest** — wilderness north/west of Briarwood. Currently hosts
  3 goblin camps (each: 4 Goblin Scouts + 1 Goblin Brute + glowing campfire)
  and 4 wandering Dire Wolves. The Goblin Warlord (boss) lairs deep within.
- **Crystal Caves** — dungeon, NW Whisperwood entrance. STATUS: planned, not
  yet placed in world. Planned inhabitants: skeletons, crystal elementals.

### Time
- Day/night cycle: 6 real-minute full rotation (sped up from default).
- `World.time_of_day` is the canonical clock. NPC schedules consume it.

## Active Hooks

(Future runs pick from this list. A hook is a one-liner that makes the next
run easier — what's the *next* thing that compounds?)

- Crystal Caves entrance is undefined → place it once dungeon is ready.
- Skeleton + Crystal Elemental drop tables exist in Items.gd; spawn paths do
  not. Anyone adding the dungeon should reuse those tables, not redefine them.
- ✅ **Resolved 2026-05-04:** Faction pressure scalar exists
  (`World.factions[id].pressure`) — three quests already mutate it.
- ✅ **Resolved 2026-05-04 (integrator):** Reactive dialogue wired.
  NPC.gd now reads `World.npc_has_flag(npc_name, warmed_flag)` and prefers
  a `warmed_dialogue_variants` (4 entries, same time-of-day buckets) when
  the flag is set. Maeve (`first_quest_done`), Lyra (`trusts_player`),
  Mara (`good_customer`) each ship 4 warmed variants in WorldBuilder.NPCS.
  Every other NPC has empty `warm_*` fields and behaves unchanged.
- ✅ **Resolved 2026-05-04 (run 3 follow-up):** World-flag warmed dialogue
  tier added to NPC.gd as a SECOND lower-priority warmed layer
  (`warmed_world_flag` / `warmed_world_dialogue_variants`). Lyra now has 4
  extra lines that fire on `lyra_potion_brew`. Composes with the integrator's
  `warmed_flag` tier — NPC-flag warm beats world-flag warm beats time-of-day.
  Consumes `World.world_flags` which had no other readers until now.
- ✅ **Resolved 2026-05-04 (run 4):** Faction-pressure dialogue tier wired
  as NPC.gd Tier 3 (between world-flag warm and time-of-day variants).
  Maeve carries 4 lines fired by `whisperwood_goblins` pressure < 0.9; the
  tier reaches her on the "ears-before-cleansing" path (Mara's bounty drops
  pressure to 0.85 before Maeve's `first_quest_done` flag locks in tier 1).
  `World.faction_pressure(id)` now has its first reader after 2 runs of being
  written-only. Authoring trap captured in SYSTEM_REGISTRY.md: never pair a
  faction reducer with the same quest that issues the NPC's warm_flag.
- ✅ **Resolved 2026-05-04 (run 5):** Goblin spawn density reads
  `World.faction_pressure("whisperwood_goblins")` in `WorldBuilder._build_enemies()`.
  Per-camp population now derives from a `_goblin_camp_size(pressure)` helper
  with thresholds at 0.9 / 0.7 / 0.4 / 0.15 — co-fired with NPC.gd's tier-3
  dialogue so dialogue *speaks* the faction state and spawning *enacts* it.
  At fresh-save pressure 1.0 the camp population is identical to pre-run-5
  (4 scouts + 1 brute per camp); at 0.85 (Mara's bounty alone) goblins drop
  by 1 per camp; at 0.65 (Mara + Maeve) by 2 per camp; brute disappears
  below 0.4. The empty camp prop (campfire, huts) persists as a memorial.
  `World.faction_pressure()` now has TWO consumers (NPC.gd dialogue tier 3,
  WorldBuilder spawn density) — the consequence-resolver loop is closed on
  both narrative and pacing axes.
- ✅ **Resolved 2026-05-04 (run 6):** Wolf spawn density reads
  `World.faction_pressure("dire_wolves")` in `WorldBuilder._build_enemies()`.
  `_wolf_pack_size(pressure)` mirror of the goblin helper with thresholds at
  0.5 / 0.3 / 0.15 — wolves drop from 4 → 3 the moment `pelt_for_lyra` ships
  (-0.1 takes pressure 0.5 → 0.4, < 0.5 trips the first threshold). Empty
  forest patches where a wolf used to roam serve as the same "they used to
  be here" memorial as the empty goblin camps. `World.faction_pressure()`
  now has THREE consumers (NPC.gd dialogue tier 3, goblin spawn density,
  wolf spawn density) — pattern proven generalizable to every faction.
- ✅ **Resolved 2026-05-04 (run 7):** Adaptive `Enemy.gd.attack_cooldown`
  is now a THIRD reader of `World.faction_pressure(faction_id)`. Each enemy
  resolves its cooldown at spawn via a `KIND_TO_FACTION` map + lerp across
  `[1.45, 1.05]` keyed on the kind's faction pressure. At fresh-save pressure
  1.0 a goblin keeps the kid-tuned 1.45s recovery window; at pressure 0.0
  the few survivors hit at 1.05s — Owen's mastery rung. Goblins, wolves,
  skeletons, crystal_elementals, crystal_guardians all wired; bandits
  (no faction yet) keep baseline. Same fail-soft contract as spawn density:
  unmapped kind / missing world / older `World.gd` → baseline, never crash.
  `World.faction_pressure()` now has FOUR consumers (NPC.gd dialogue tier 3,
  goblin spawn density, wolf spawn density, enemy attack cooldown) — the
  same scalar drives narrative + density + pacing. Mastery threshold for
  Rule 1 ("compound, don't sprawl") demonstrated: ONE primitive can fan out
  to multiple readers without sprawl. Visible "agitated" ⚡ prefix on the
  floating name fires when cooldown < 1.30 so kids can read pacing change
  per-enemy, not just per-density.
- ✅ **Resolved 2026-05-04 (run 8):** Roan (Stablemaster) carries 4
  `dire_wolves` faction-tier lines (`warm_faction_id:"dire_wolves"`,
  `warm_faction_below:0.5`). First NPC whose ONLY warming channel is the
  faction scalar — smoke-tests Tier 3 of the NPC.gd dialogue stack on an
  NPC with no `warm_flag` and no `warm_world_flag`. Threshold 0.5 mirrors
  the run-6 wolf-spawn first cliff, so Roan begins speaking the moment
  any wolf-reducing quest ships (today: `pelt_for_lyra`). Roan's lines
  now compose with run-6 spawn density (3 wolves remaining) and run-7
  adaptive cooldown (visible ⚡ prefix on agitated survivors), closing
  the FOURTH leg of the `dire_wolves` compound (dialogue + density +
  cooldown + visual marker). `World.faction_pressure("dire_wolves")` now
  has FIVE consumers (Roan dialogue, Maeve via `whisperwood_goblins`
  doesn't count for wolves, but spawn density + adaptive cooldown +
  Maeve-on-goblins-pattern reuse + future bandit/skeleton schema all
  validate the run-7 mastery threshold). Pattern proven: ANY NPC can
  speak ANY faction's state via data-only edits.
- ✅ **Resolved 2026-05-04 (run 9):** JSON dialogue trees made live.
  New `DialogueDB.gd` static helper reads `data/dialogue/<npc_slug>.json`
  and applies a 9-step predicate priority (low_health_player → boss_slain →
  boss_alive → high_renown → stranger → festival → after_first_quest_complete
  → mood bucket → default). Maeve and Edda are opted in via
  `"use_json_dialogue": true` in `WorldBuilder.NPCS`. The mood-keyed JSONs
  shipped from `auto/lore` on 2026-05-04 (and flagged dormant by the
  integrator) are now the FIRST tier of NPC.gd's dialogue resolution —
  above all 4 existing tiers (warm_flag / warm_world_flag /
  warm_faction_id / mood bucket). Misses fall through cleanly so opt-in is
  purely additive. Four predicates (`boss_alive`, `high_renown`, `stranger`,
  festival keys) are fail-soft on World fields not yet shipped (`player_renown`,
  `npc_seen`, `current_festival`, `seen_warlord`); they LIGHT UP the day
  those fields land — no DialogueDB / JSON edit required, and Maeve & Edda
  already author lines for them. Closes the integrator-noted gap from
  2026-05-04: lore-keeper output is no longer canon-only.
- 🔥 **Top-priority next:** ship JSON dialogue trees for the other 5 NPCs
  (**Mara the Merchant**, **Herbalist Lyra**, **Innkeeper Bram**,
  **Stablemaster Roan**, **Trainer Hala**). Pure data work — drop a
  `data/dialogue/<slug>.json` file with the schema documented in
  SYSTEM_REGISTRY.md "JSON Dialogue Tree Schema" + flip
  `"use_json_dialogue": true` in `WorldBuilder.NPCS`. Each NPC gets the
  same 9-tier predicate space without a single GDScript edit. Highest-leverage
  next move because the SYSTEM is already shipped and tested on 2 NPCs.
- ✅ **Resolved 2026-05-05 (run 17 — Builder):** `wolf_fang_for_roan`
  quest shipped. SECOND `dire_wolves` reducer (`-0.1`) — pressure now
  tracks `0.5 → 0.4 (Lyra's pelts) → 0.3 (Roan's fangs)` on the canonical
  reduction path. Trips the run-6 second wolf-spawn cliff (3 → 2 wolves)
  AND drops adaptive cooldown (run 7) and chase speed (run 8) another
  step on the same scalar. New material `wolf_fang` (Items.gd) added to
  the wolf DROP_TABLE at weight 18 (pelt 48 → 38), so a single 5-kill
  wolf grind produces ~1.9 fangs AND ~2.0 pelts in parallel —
  `wolf_fang_for_roan` and `pelt_for_lyra` can be progressed together
  without re-grinding. Standalone (no Lyra) the bounty hits the FIRST
  cliff (4 → 3) — also visible. Composes with the Roan-arc started in
  run 8 and the Roan `warm_flag` tier shipped in this same run.
- ✅ **Resolved 2026-05-05 (run 17 — Builder):** Roan `warm_flag`
  tier wired in `WorldBuilder.NPCS`. Quest consequence sets
  `first_bounty_done` on Roan's `npc_flags`; four `warm_lines` author the
  personal-warmth tier. Roan promoted from faction-only NPC (run 8) to
  faction + warm_flag NPC — same dialogue depth as Maeve (`first_quest_done`),
  Mara (`good_customer`), Lyra (`trusts_player`). NPC.gd Tier 2 (warm_flag)
  fires above Tier 4 (faction-pressure), so warm_lines surface the
  moment the quest turns in. `line` field updated to the bounty pitch
  ("Wolves nip my mares again. Bring me 5 wolf fangs and the road's
  safer.") matching the Mara/Lyra offer-line convention.
- ✅ **Resolved 2026-05-05 (run 18 — Builder):** `wolf_form_with_hala`
  quest shipped — THIRD `dire_wolves` reducer (`-0.1`). Closes the
  authoring gap left by the previous run: Hala's WorldBuilder pitch
  line, `warm_flag: wolf_form_taught`, and four `warm_lines` were
  ALREADY shipped, AND `Achievements.wolf_tamer` predicate was wired
  referencing `wolf_form_taught` on Hala — but `World.QUEST_CATALOG`
  had no `role: trainer` entry, so the engine could never deliver the
  pitched quest and the achievement could never trip. Single edit in
  World.gd adds the entry with values matching SYSTEM_REGISTRY.md
  run-18 documentation (90 xp / 35 g / `hala_wolf_form_done`
  world_flag). Wolf pressure now tracks 0.5 → 0.4 (Lyra) → 0.3 (Roan)
  → 0.2 (Hala), trips the run-6 SECOND cliff (3 → 2 wolves) on the
  full path. The two surviving wolves are ~21% faster (run-8 chase
  lerp) and ~28% slower-attacking (run-7 cooldown lerp) — older,
  wiser, hungrier. With Lyra+Roan+Hala done, `Achievements.wolf_tamer`
  finally resolves TRUE — Owen unlocks "the Wolf-Tamer" title at
  priority 35, auto-equipping above "Wolf-Friend" (30). Hala's
  authored `warm_flag` tier 2 lines (run 18 prior) light up on the
  very next training visit. Closes the FIRST quest where dialogue,
  warm-flag tier, achievement predicate, and reward economy were
  all pre-authored across multiple files BEFORE the keystone quest
  entry — a useful pattern for downstream "data-first" runs (write
  the registry / dialogue / achievement first, drop the World.gd
  entry last).
- ✅ **Resolved 2026-05-04 (run 8):** Adaptive `Enemy.gd.chase_speed` is
  now a FOURTH reader of `World.faction_pressure(faction_id)`. Multiplicative
  band — each enemy kind's WorldBuilder-assigned chase_speed lerps up to
  `+CHASE_SPEED_AGITATION_GAIN` (=0.17, +17%) at pressure 0.0. Goblin Scout
  4.6 → 5.38, Brute 1.0 → 1.17 (tank role preserved), Wolf 1.05 → 1.23,
  Skeleton 4.4 → 5.15, Crystal Elemental 3.2 → 3.74, Crystal Guardian 3.4
  → 3.98. Bandits unmapped → baseline. Same fail-soft contract as run 7;
  reuses the same `KIND_TO_FACTION` map (single source of truth). NO new
  visual cue — run 7's `⚡` agitated-name prefix already fires below
  pressure ~0.625 and now subsumes BOTH adaptive outputs (cooldown AND
  chase lerp on the same scalar — they trip together). `World.faction_pressure()`
  now has FIVE consumers (NPC dialogue tier 3, goblin spawn density, wolf
  spawn density, enemy attack cooldown, **enemy chase speed**) — same
  scalar drives narrative + density + 2-axis pacing. Mastery threshold
  for Rule 1 ("compound, don't sprawl") restated: ONE primitive can fan
  out to 5+ readers without sprawl, provided each reader uses the SAME
  fail-soft contract and the SAME kind→faction map.
- 🔥 **Top-priority next:** Roan (Stablemaster) → `dire_wolves` faction tier.
  Smoke-tests the 4-tier dialogue system on an NPC with no warm_flag at
  all. Schema is in place, only WorldBuilder edits required. After runs
  6 + 7, Roan's faction-tier lines now have TWO partners: wolf spawn
  density already speaks the state AND the surviving wolves visibly
  agitate (⚡ prefix) — dialogue completes the FOURTH leg of the
  `dire_wolves` compound (dialogue + density + cooldown + visual marker).
- ✅ **Resolved 2026-05-05 (run 17 — Builder):** *(duplicate hook)*
  Folded into the run-17 wolf-bounty entry above. The Roan-arc on
  `dire_wolves` is now complete on all four legs: dialogue (tier 4
  faction + tier 2 warm_flag), spawn density (run 6), adaptive cooldown
  (run 7), adaptive chase (run 8) — every consumer of
  `World.faction_pressure("dire_wolves")` is wired to a Roan-issued
  reduction event.
- ✅ **Resolved 2026-05-05 (run 10): Boss world-flag wire + 3rd JSON opt-in.**
  Two world flags now flip on Goblin Warlord lifecycle events:
  - `seen_warlord` — set in `Boss._physics_process` immediately after the
    intro sting plays (player came within 30m). Reads as "the village has
    heard the Warlord's banners go up." Permanent for the session.
  - `warlord_dead` — set in `Boss._die` alongside the existing reward /
    quest-hook calls. Reads as "the Warlord has fallen." Permanent — never
    cleared on player respawn (a slain boss stays slain).

  Both flags are written via a new `World.set_world_flag(name, value=true)`
  helper (single-line callsites) which also runs `_check_achievements()` so
  any future "Met the Warlord" / "Warlord Slain" achievement unlocks on the
  same tick the flag flips. `apply_consequence`'s flag step continues to
  work unchanged — `set_world_flag` is the no-faction / no-toast / no-npc
  sister for emergent runtime events that aren't quest consequences.

  **Innkeeper Bram opted into JSON dialogue** (`use_json_dialogue: true` on
  his WorldBuilder.NPCS entry). He becomes the THIRD JSON-resolver NPC
  alongside Maeve and Edda. With the boss-flag wire above, all three now
  speak DISTINCT boss_alive and boss_slain lines on the same world tick:
  - Boss alive: Maeve "Do not fight him angry. Anger is what made him." /
    Edda "The Warlord rides a blade I'd recognize anywhere. I forged it
    before I knew better." / Bram "Some folk who walked into the
    Whisperwood I still set a place for at supper. Habit."
  - Boss slain: Maeve "*long pause* — *Ai-velin*, traveler. The Whisperwood
    will sleep tonight." / Edda "*long silence* — You unmade my mistake.
    *one hard hammer-strike*" / Bram "*sets the mug down very carefully*
    — Some debts get paid in iron, friend."

  Six dormant authored lines became reachable in the player flow. No new
  state shape introduced; `world_flags` had been written by quest
  consequences and now also by boss lifecycle events.

  **DialogueDB consumer count for `world_flags`:** the JSON loader had been
  the SOLE downstream reader of `seen_warlord` / `warlord_dead` flags
  before this run — fail-soft, so DialogueDB silently fell through to
  mood/default tier when the flags were never set. Run 10 makes the flags
  actually flip, completing the 3-leg compound (Boss.gd writes →
  `world_flags` carries → DialogueDB reads → JSON line surfaces).

- 🔥 **Top-priority next:** Author Mara / Lyra / Roan / Hala JSON trees and
  drop them into `data/dialogue/`. Pure data PR — `WorldBuilder.NPCS` adds
  one `"use_json_dialogue": true` per NPC and DialogueDB picks up the rest.
  Mara is highest-leverage (her `low_health_player` reads as "she comps a
  potion" — mechanically distinct from Bram's "no coin tonight, stew first").
  Roan and Hala have no JSONs authored yet; the lore agent ships first,
  Builder/WorldBuilder lights up the opt-in switch second.
- 🔥 **Adjacent next:** Wire a `World.player_renown` int (or reuse
  `unlocked_achievements.size()`) so Maeve and Edda's already-authored
  `high_renown` JSON lines fire. DialogueDB reads `world.player_renown >=
  renown_threshold` (default 100) and the JSONs are pre-authored. Single
  field write + one quest hook.
- 🔥 **Adjacent next:** Wire a `World.npc_seen` Dictionary (keyed by
  npc_name) flipped to true on first interaction in NPC.gd. Lights up the
  `stranger` JSON keys for first-encounter warmth — Maeve's "*peers up the
  stick at you* — A face I don't yet know", Edda's "Don't touch the anvil.
  Ask first.", Bram's "Welcome to the Long Lantern! New face, new tale."
- Player housing has no anchor point. A flat plot east of Briarwood (positive
  X, near +12,0,+4) is reserved for it.
- Lyra shop unlock: when `World.has_world_flag("lyra_potion_brew")`, list
  `hp_potion_g` (greater) at her shop. Today no shop UI exists — pair with
  Smith Edda's forge UI (backlog #4).

## NPC Memory

(Tracks who has spoken to whom, who has been thanked, who has been ignored.
Populated as runs ship reactive dialogue. Run 16 added a per-visit ledger
that complements the flag-derived columns below — see
`World.npc_memory[name]`.)

| NPC                  | Role     | Player relationship | Flag-warmed lines | Visit-warmed (run 16) | Memory flags consumed |
|----------------------|----------|---------------------|-------------------|------------------------|------------------------|
| Elder Maeve          | quest    | warms after first quest; senses goblin retreat; recognizes regulars | ✅ 4 (npc-flag, integrator) + ✅ 4 (faction, run 4) | ✅ 4 @ visits ≥ 3 | `first_quest_done`; `whisperwood_goblins` < 0.9 |
| Smith Edda           | smithy   | reforge sink (run 12) | ❌ (forge dialogue not warmed) | ❌ (forge button covers cadence) | — |
| Mara the Merchant    | shop     | warms after ear bounty | ✅ 4 (npc-flag, integrator) | ❌ | `good_customer` (ears_for_mara) |
| Herbalist Lyra       | alchemy  | warms after pelts; senses brewing | ✅ 4 (npc-flag) + ✅ 4 (world-flag, run 3 follow-up) | ❌ | `trusts_player`, `lyra_potion_brew` |
| Innkeeper Bram       | inn      | "regular at the bar" cadence after 3 visits | ❌ (no quest yet) | ✅ 4 @ visits ≥ 3 | — |
| Stablemaster Roan    | stable   | warms after fang bounty; warms when wolves quiet | ✅ 4 (npc-flag, run 17) + ✅ 4 (faction, run 8) | ❌ | `first_bounty_done` (wolf_fang_for_roan); `dire_wolves` < 0.5 |
| Trainer Hala         | trainer  | recognizes returning student after 3 sessions | ❌ (no quest yet) | ✅ 4 @ visits ≥ 3 | — |

Live data:
* `World.npc_flags[npc_name] -> Array[String]` — flag-derived memory.
  Read with `World.npc_has_flag(npc, flag)`. Mutated by quest consequences
  only.
* `World.npc_memory[npc_name] -> {visits, first_day, last_day, first_tod,
  last_tod}` — visit-derived memory (run 16 — Builder). Read with
  `World.npc_visits(name)`, `World.npc_first_visit_day(name)`,
  `World.npc_last_visit_day(name)`, `World.npc_days_since_last_visit(name)`.
  Mutated by `World.record_npc_visit(name)`, called from NPC.gd's
  `_on_interact` BEFORE tier resolution so the triggering visit counts.
* `World.world_day` — integer counter; increments when `time_of_day` wraps
  past midnight. Pure derivation from `time_of_day`, no separate timer.

The dialogue tier order (highest → lowest priority) is:
1. JSON-tree (DialogueDB, opt-in via `use_json_dialogue`)
2. NPC-flag warmed (`warmed_flag` + `warmed_dialogue_variants`)
3. World-flag warmed (`warmed_world_flag` + `warmed_world_dialogue_variants`)
4. Faction-pressure warmed (`warmed_faction_id` + `warmed_faction_below` + variants)
5. **Visit-memory warmed (`warmed_memory_visits_min` + variants — run 16)**
6. Time-of-day default (`dialogue_variants`, 4 buckets)

Memory sits BELOW faction by deliberate authoring choice: a villager
reacts to the SHAPE of the world (faction) before the cadence of their
relationship with the player. Flip if play-testing disagrees.

## Faction State

(No scalars yet. Listed for downstream runs to wire.)

| Faction          | Disposition | Pressure | Notes                          |
|------------------|-------------|----------|--------------------------------|
| Briarwood        | friendly    | 0.0      | safe hub                       |
| Whisperwood Goblins | hostile  | 1.0      | mutable; cleansing & ear bounty reduce; **Maeve speaks at <0.9 (run-4 dialogue tier 3); spawns drop at <0.9/<0.7/<0.4/<0.15 (run-5 spawn density); attack cooldown lerps 1.45→1.05 (run-7 adaptive pacing); chase_speed lerps +17% (run-8 adaptive pacing)** |
| Dire Wolves      | hostile     | 0.5      | mutable; **THREE reducers**: `pelt_for_lyra` (-0.1) + `wolf_fang_for_roan` (-0.1, run 17) + `wolf_form_with_hala` (-0.1, run 18); **Roan speaks at <0.5 (run-8 faction tier) + <warm_flag `first_bounty_done` (run-17 personal tier); Hala speaks at <warm_flag `wolf_form_taught` (run-18 personal tier)**; spawns drop at <0.5/<0.3/<0.15 (run-6 spawn density — all three cliffs now player-reachable in a single save); attack cooldown lerps 1.45→1.05 (run-7); chase_speed lerps +17% (run-8 adaptive pacing); FIRST `all_npc_flags` achievement consumer wired (run-18 `wolf_tamer`) |
| Crystal Caves    | hostile     | 0.0      | placeholder; dungeon not placed; **skeleton/crystal_elemental/crystal_guardian cooldown wired (run-7) AND chase wired (run-8) — both fire the moment the dungeon ships** |
Live data in `World.factions`. Read with `World.faction_pressure(id)`. Mutated
only by `World.apply_consequence({...})`.

## World Flags (Active)

`World.world_flags` is a dict keyed on flag name. Set by quest consequences,
read by dialogue / spawning / future runs.

| Flag                  | Set by quest          | Default | Used by (downstream) |
|-----------------------|-----------------------|---------|----------------------|
| `whisperwood_safer`   | whisperwood_cleansing | unset   | future: roving patrol density |
| `lyra_potion_brew`    | pelt_for_lyra         | unset   | future: Lyra unlocks rarer potions in shop |
| `mara_bounty_paid`    | ears_for_mara         | unset   | future: Mara raises buy prices on goblin loot |
| `roan_bounty_paid`    | wolf_fang_for_roan    | unset   | future: Maeve cross-NPC mention; Edda fang-stitched greaves recipe (run 17) |
| `hala_wolf_form_done` | wolf_form_with_hala   | unset   | run 18: `wolf_tamer` achievement reads the npc_flag side; future: Hala teaches an advanced wolf-defense technique unlocking a counter-stance buff |

Read with `World.has_world_flag(name)`. Convention: flag names are
`snake_case`, present-tense fact ("safer", "paid", "brew"), never imperative.

## Player Impact Ledger

(Cumulative consequences of player actions. Empty until reactive systems exist.)

- Goblins killed (lifetime): tracked per-save in Player.kills_by_kind, not yet
  surfaced to NPCs. (Adjacent compound: a kills-derived faction-pressure decay
  could route per-kill impact into the dialogue tier 3 channel.)
- Goblins spawned (per world load): now scales from baseline 15 (3 camps × 5)
  down to 3 (3 × 1) as `whisperwood_goblins` pressure drops. Ledger of *what
  the world LOOKS like to the player on save reload* now reflects their work.
- Wolves spawned (per world load): scales from baseline 4 down to 1 as
  `dire_wolves` pressure drops. Position list is stable — wolves vanish
  from the END of `wolf_spots` first, so re-loading the same save shows
  the SAME wolves missing from the SAME forest patches. (Run 6.) Two
  reducers now drive this: `pelt_for_lyra` (-0.1, run 6) AND
  `wolf_fang_for_roan` (-0.1, run 17). Running both takes pressure
  0.5 → 0.3, trips the second cliff (3 → 2 wolves), and lights up
  Roan's warm_flag tier on the same turn-in.
- Quests completed: surfaced as toast AND (run 4) as faction-pressure shifts
  that NPCs now narrate. `apply_consequence()` is no longer write-only on the
  faction key.
- Surviving enemy aggression (per world load): each remaining goblin / wolf /
  skeleton / crystal_elemental / crystal_guardian resolves attack_cooldown
  against its faction pressure at spawn (run 7). Visible ⚡ prefix on the
  floating name when cooldown < 1.30 — the third *visible* axis on the
  consequence loop after dialogue (run 4) and spawn density (runs 5–6).
- Surviving enemy chase pacing (per world load): each remaining enemy of a
  mapped kind also resolves chase_speed against its faction pressure at
  spawn (run 8). Multiplicative `+17%` ceiling at pressure 0.0; baseline
  preserved at pressure 1.0. The same `⚡` prefix subsumes both pacing
  outputs — kids see ONE marker meaning "this one is faster recovery AND
  faster chase," not two separate marks. Output #4 on the same scalar.
- Roads defended: not modeled.
- Buildings damaged: not modeled.

## Recent Run Summary

See CHANGES.md for the human-readable run log.

## Lore Artifacts

(Append-only ledger of canonical written lore. The Lore Keeper agent owns
this section. Files live under `eldoria-godot/lore/`, `eldoria-godot/data/`.)

### NPC backstories (`lore/npcs/`)

| NPC          | File                              | Dialogue tree                                  | Status |
|--------------|-----------------------------------|------------------------------------------------|--------|
| Smith Edda   | `lore/npcs/smith_edda.md`         | `data/dialogue/smith_edda.json` (16 keys)      | drafted; awaiting Builder wiring |

### Old Faerie glossary (cumulative)

Canonical words, in the order they entered canon. Future writers should
reuse these before inventing new ones.

- **`thirre`** *(world.md)* — memory of stone; a place where time pools.
- **`ai-velin`** *(world.md)* — the long path; the river of stars / a mortal life.
- **`kerrithen`** *(world.md)* — to lay down so the land may hold it.
- **`haethe`** *(npcs/smith_edda.md)* — the song iron remembers; a properly-tempered blade's hum.
- **`unnen`** *(npcs/smith_edda.md)* — the work of two hands; the highest praise of the smith tradition.

### Cross-references seeded this run

- Smith Edda's mother **Halsa** (deceased; Longnight death) is now seedable
  for codex narration about iron and the *haethe*.
- The **Goblin Warlord's saber** is canonized as Edda's badly-forged early
  work. Builder may, when ready, wire `boss_slain` to drop it as a unique
  quest-turn-in to Edda. Her dialogue tree's `boss_slain` line is pre-tuned.
- **Longnight Vigil** is now the most loaded day in Edda's year (Halsa's
  death-night; Bram's stew). Future seasonal dialogue can lean here.
- Bram quietly knows Edda forged the Warlord's saber. He has never said.
  This is a relationship hook for Bram's eventual backstory file.

---

## Lore Run — 2026-05-04 (Elder Maeve)

### NPC backstories (`lore/npcs/`) — added this run

| NPC          | File                              | Dialogue tree                                  | Status |
|--------------|-----------------------------------|------------------------------------------------|--------|
| Elder Maeve  | `lore/npcs/elder_maeve.md`        | `data/dialogue/elder_maeve.json` (16 keys)     | drafted; awaiting Builder wiring |

### Old Faerie glossary — additions

Two new canonical words enter the language. They sit alongside *thirre*,
*ai-velin*, *kerrithen* (`world.md`) and *haethe*, *unnen*
(`smith_edda.md`). Future writers should reuse these before inventing new
ones.

- **`vael-tor`** *(elder_maeve.md)* — the gathered hearth; the collective
  warmth a village turns toward a death. Older 'we'-form: *vael-tor-i*.
  Maeve speaks the *we*-form on Longnight Vigil.
- **`thressa-mai`** *(elder_maeve.md)* — the unanswered letter; a debt of
  words owed to one who has gone without farewell.

### Cross-references seeded this run

- **Maeve was Edda's midwife.** She named Edda. She has not crossed the
  forge threshold since the spring after Halsa's death, when she brought
  Halsa's cradle. This is the canonical bridge between the two existing
  NPC files. (`elder_maeve.md` ↔ `smith_edda.md`)
- **Maeve's brother Cailen** was lost on the High Steppe. A Steppe-rider
  returned a horseshoe and a pressed sprig of heather; the horseshoe
  hangs above Maeve's hearth. This makes the Stone Crown reusable for
  future quests/codex.
- **Maeve's daughter Aelis** went south to the Iron Crown's smoke-cities
  eleven years ago and stopped writing. Maeve sends a sealed letter every
  Lambmoon by **Mara the Merchant**. **Mara is keeping one returned
  letter** (water-stained, addressed in a hand not Aelis's) — a slow-burn
  quest seed she has not yet decided what to do with. Mara is canonically
  expected to give it eventually to Edda for keeping. (Three-way bridge:
  Maeve ↔ Mara ↔ Edda.)
- **Roan rode the High Steppe twice** for Maeve, hunting word of Cailen.
  Maeve paid him in a hand-carved cradle he keeps in the stable loft,
  unused, against the day Maeve needs it back. (Maeve ↔ Roan bridge.)
- **Lyra is Maeve's chosen successor.** Maeve is teaching her the
  Longnight Vigil ritual one candle at a time. Neither has said the word
  *Elder* aloud. (Maeve ↔ Lyra bridge — strong hook for Lyra's eventual
  backstory file.)
- **Bram brings Maeve a Longnight Vigil stew** that Maeve sets out for
  the Hollow King; the cat eats it. Bram knows. This expands the Vigil
  tradition first seeded in `smith_edda.md` — Bram's Vigil-stew round
  goes Edda → Maeve, and is now a canonical village ritual, not a one-NPC
  detail. (Bram ↔ {Edda, Maeve} bridge.)
- **The Stag-Court once offered Maeve a seat at the Antler Crown** for
  the price of one mortal year remembered backwards. She declined. She
  believes the offer is still open. *This thread is sealed-room canon:*
  it must NEVER be spoken in a Maeve dialogue line, only ever surfaced as
  a codex fragment after the player has reached the Crystal Caves (a
  *thirre*). Future writers please respect the withholding — it is the
  point of the character.
- **Maeve's hawthorn walking stick** is canonized as a censusing artifact
  carrying 111 ringed knots — one per Briarwood-born child since she
  became Elder. Knot 37 is Halsa, knot 62 is Edda. A future codex entry
  *"Maeve's Knot-Stick"* is hooked.
- **Honeysong Eve and Longnight Vigil** are now both anchored to Maeve
  as their ritual-holder. The Calendar entries in `world.md` should
  henceforth be read as *Maeve's calendar* in any future flavor pass.

### Withholding ledger (do-not-surface canon)

These canonical facts are *intentionally* never to be spoken by the NPC
in dialogue. They live in the .md as story fuel and may surface only via
codex entries, third-party narration, or other NPCs' lines.

- Maeve's Stag-Court offer (Antler Crown). Codex-only, post-Crystal-Caves.
- Aelis (Maeve's daughter). Mentioned only via Mara's unopened letter
  arc, never directly by Maeve.
- Cailen (Maeve's brother). Maeve has not spoken his name since
  *kerritha-ing* his pressed heather; her dialogue tree must not put it
  in her mouth.

### Hooks queued for future runs

- **`Cailen's Horseshoe` quest** (Maeve → Stone Crown rider passing
  through, or burial at Foxthaw on the High Road). Reward: a knot carved
  into Maeve's stick *for the player.* No other in-game reward needed.
- **Mara's unopened-letter turn-in** (a Maeve-and-Lyra-only scene; do
  not surface in casual repeat-talk).
- **Maeve's Knot-Stick** as a discoverable codex object.
- **Bram backstory** is now strongly seeded — his Vigil-stew round and
  his quiet knowing about both Edda's saber and Maeve's letter make him
  the village's *quiet keeper*. Priority candidate for the next NPC
  backstory.

---

## Lore Run — 2026-05-04 (Innkeeper Bram)

### NPC backstories (`lore/npcs/`) — added this run

| NPC            | File                              | Dialogue tree                                  | Status |
|----------------|-----------------------------------|------------------------------------------------|--------|
| Innkeeper Bram | `lore/npcs/innkeeper_bram.md`     | `data/dialogue/innkeeper_bram.json` (16 keys)  | drafted; awaiting Builder wiring |

### Old Faerie glossary — additions

Three new canonical words enter the language. They sit alongside *thirre*,
*ai-velin*, *kerrithen* (`world.md`); *haethe*, *unnen* (`smith_edda.md`);
and *vael-tor*, *thressa-mai* (`elder_maeve.md`). Future writers should
reuse these before inventing new ones.

- **`vethar`** *(innkeeper_bram.md)* — the candle in the window; a small
  light kept burning for someone whose road has not ended. Erris-keyed.
  Bram has lit one in the front window of the Long Lantern every night
  for nine years.
- **`haisten`** *(innkeeper_bram.md)* — the song with no last verse; a
  story whose teller stopped before the end — by death, by distance, by
  grief, or by *kerrithen*. Bards know the word. Innkeepers learn it.
- **`breos`** *(innkeeper_bram.md)* — what the bowl remembers; a place
  many lives have passed through and been fed. The Long Lantern is
  *breos*. So is the road.

### Cross-references seeded this run

- **The Long Lantern** is now the canonical name of Briarwood's inn.
  Environment may carve a hand-painted wood-and-iron sign with a small
  lantern motif over the front door. The lit candle in the front window
  is a per-night flicker prop (Motion §12 — never static).
- **Caedr**, Bram's missing road-singer husband, is now seedable as a
  bardic codex narrator (same convention as Halsa-as-narrator in
  `smith_edda.md` hooks): present-tense voice, no body, no death
  confirmed. Walked into the Whisperwood on a Honeysong Eve eight in-
  world years ago following a song-debt to the Antler Crown — present-
  tense per herbalist canon ("not, the herbalists insist, *gone*").
  Lyra is the herbalist who tells Bram this in those exact words. Both
  of them are lying to each other. Both of them are right.
- **Bram's Vigil-stew round Edda → Maeve.** The Maeve canon's stew-drop
  detail is now bilateral: Maeve sets the bowl out for the Hollow King
  and the cat eats it; Bram knows; he brings it anyway. The round is a
  *village ritual,* not a one-NPC kindness. (Bram ↔ {Edda, Maeve} bridge
  closed.)
- **Bram is the second in-village witness to Mara's water-stained
  returned letter** (`elder_maeve.md`, Withholding Ledger). He saw it
  fall from Mara's coat pocket two springs ago, saw the unbroken seal,
  saw her face, and refilled her cup without comment. He has not spoken
  of it and will not. Future writers MUST NOT have Bram surface this in
  dialogue — he is its keeper, not its caller. (Bram ↔ Mara bridge —
  *kerrithen*-typed, same shape as Bram ↔ Edda's saber.)
- **Bram knows about Smith Edda's saber.** His `boss_slain` line is
  pre-tuned to *non-confirm* on the same in-game day Edda's fires. The
  most he will ever say is *"Some debts get paid in iron, friend."*
  Builder may co-fire both for the village's quietest two-person scene.
- **Roan's road-name for Bram is "Bron."** Roan was Bram's horse-boy on
  a single shared route nine years ago, before either came to this
  valley. Reserved for Roan's future warmed dialogue variants — no
  other NPC may use the name. (Bram ↔ Roan bridge.)
- **Lyra leaves dreamleaf at Bram's back door every Longnight Vigil.**
  Bram does not sleep on Longnight; he gives the dreamleaf to the
  eldest traveler in the common room. Both know. Neither says.
  Reserved as a candidate consequence for a future Lyra-Bram quest with
  a `bram_holds_vigil` flag. (Bram ↔ Lyra bridge.)
- **Hala and Bram argue, gently, about whether a blade is a tool or an
  oath.** They have argued the same argument for nine years and neither
  has moved an inch. Reserved as a future warmed-dialogue hook on Hala's
  side; Bram's side is in the `lore_notes` of his dialogue file.
  (Bram ↔ Hala bridge.)
- **Triptych staging on Longnight Vigil.** Edda, Maeve, and Bram now all
  ship a `longnight_vigil` mood-key. Bram's line opens with *"Edda's
  forge first. Always Edda's forge first."* — the *first* is the
  textual cue that the round continues to Maeve. If Builder ever
  co-fires all three lines on the same Longnight tick, the village's
  quietest scene plays itself across three thresholds with no
  scripting beyond mood-key resolution.

### Withholding ledger (do-not-surface canon)

- **Caedr's name in Bram's mouth, unprompted.** Bram never names Caedr
  aloud unless the player has reached a sufficiently warm relationship
  *and* asks specifically. He will say *vethar*; he will not say
  *Caedr*. Codex-only beyond that gate.
- **The contents of Mara's letter.** Bram saw it. He did not read it.
  Even if he had, he would not say. Future writers must respect the
  withholding — same shape as Maeve's Stag-Court offer. The letter is
  Mara's to give, not Bram's to surface.
- **The last verse of Caedr's song.** `bram_last_verse_offered` is
  reserved as *intentionally unresolvable.* Closing it would violate
  THEME.md §7. Future writers MUST consult §7 before touching this loop.

### Hooks queued for future runs

- **Honeysong Eve quest** (Bram → fetch one `paper_lantern` for "someone
  whose road has not ended"). Reward: `bram_road_knife` (sentimental
  flavor item — the only blade Bram still owns from his bard days,
  dulled, +1 luck flavor not stat). Quest text never names Caedr.
- **The Last Verse side-quest.** A traveling NPC sings a tune the
  player can carry to Bram. Bram refuses to use it. Quest *completes*
  but Bram never confirms. World flag `bram_last_verse_offered` records
  the offer; nothing reads from it. (Intentional.)
- **Caedr as bardic codex narrator** for codex pages on Erris, the
  road, the Antler Court, and the shape of an unfinished tune. Use
  same convention as Halsa-as-narrator: present-tense, no body.
- **`bram_holds_vigil`** as a Lyra-readable Bram flag, set by a future
  Lyra-Bram Longnight-eve quest exchanging the dreamleaf bundle.
- **`bram_letter_acknowledged`** as a one-line Bram reactive on the day
  Mara finally turns her letter in (canonically expected: to Edda for
  keeping). Short, dry, no Aelis name.
- **The Long Lantern interior** as an Environment build target — common
  room with hearth, copper coin balanced on the lintel above the front
  door (Erris offering, swept and replaced), front-window candle
  flickering nightly, three small leather notebooks on a back shelf
  (Bram's verse-attempts — Environment may model them as world-readable
  examinables tied to a future codex page).

---

## Lore Run — 2026-05-05 (Herbalist Lyra)

### Artifact shipped

- `eldoria-godot/lore/npcs/herbalist_lyra.md` — Lyra's full backstory:
  birth as the 89th knot on Maeve's stick; mother **Wennet** (the
  village's previous herbalist) dead of lung-fever in Sunpetal Lyra was
  eight; village raising at Bram's inn, Maeve's hearth, Edda's mortar,
  Roan's slow horse, Hala's gentle defensive forms; the four Whisperwood
  years apprenticed to **Aenwyn**, who taught her *mossaen*, the
  seventeen unlisted herbs and the four wrongly-listed ones, that the
  Crystal Caves are a *thirre*, that the Whisperwood goblins are
  faerie-descended, and that the Stag-Court hears every herb-name
  spoken at midnight inside the deeper Whisperwood; Aenwyn's parting
  gift of the green-dyed coat at the eastern Foxthaw of the fourth
  year; Lyra's wound — **Tess Brookhollow** dying in her lap two
  springs ago of a marsh-fever broken too late by fen-foxglove from the
  southern marsh-edges; Lyra's secret — she still hears the *listening*
  in Foxthaw fox-fire, has answered once at twenty-three, wrote down
  one Old Faerie word in the back of her herb-book and has not in six
  years looked it up; what she wants — to not be the last reader of
  the Whisperwood in Briarwood; her relationships to all six other
  NPCs, including the bilateral closure of Bram's "not gone" line and
  the canonical pairing of Edda's *unnen* cleavers with Lyra's
  *wennen* marshmint as the village's most exact small mutual gift.

- `eldoria-godot/data/dialogue/herbalist_lyra.json` — Lyra's
  mood-keyed surface, tree shape mirroring `smith_edda.json`,
  `elder_maeve.json`, and `innkeeper_bram.json` exactly so NPC.gd
  reads all four through a single code path. Two seasonal slots:
  `greenshield_first_pick` (Lyra's annual heart's-ease + dogwort
  delivery to Maeve) and `tess_remembrance` (Sunpetal 7 — the
  shortest line in her tree, herb-shed door closed; the brevity is
  the grief and Builder MUST NOT extend it).

### Old Faerie words seeded this run

Three new words enter canon, joining *thirre*, *ai-velin*, *kerrithen*
(`world.md`), *haethe*, *unnen* (`smith_edda.md`), *vael-tor*,
*thressa-mai* (`elder_maeve.md`), and *vethar*, *haisten*, *breos*
(`innkeeper_bram.md`):

- **`mossaen`** *(herbalist_lyra.md)* — the listening you do with both
  hands in the dirt. Not magic; attention. The herbalist's first
  practice and her last one. The mountain clans are said to use the
  same word in Stone-Tongue for the listening a stoneworker does to a
  granite face before the first chisel-stroke. Aenwyn taught it.
- **`thalen-ai`** *(herbalist_lyra.md)* — the herb that grows where
  it is needed. The herbalist's working faith — that the right plant
  comes up in the right place at the right time, if the land trusts
  the gatherer. Lyra has reluctantly found it mostly true.
- **`wennen`** *(herbalist_lyra.md)* — to leave something growing for
  someone else to find. Not a gift; a faith. The word is one letter
  from Lyra's mother **Wennet's** name. **Lyra has not consciously
  noticed.** Maeve has. Bram has and assumes Lyra knows. The
  unconscious naming is canon and surfacing it kills it — see
  Withholding ledger below.

### Cross-references seeded this run

- **Lyra is the 89th knot** on Maeve's hawthorn walking-stick. (Edda
  is 62nd. Halsa is 37th. Lyra does not know this and Maeve will not
  say.) Maeve carved it with her thumb still slightly bandaged from
  the cutting because Wennet had asked her to.
- **Maeve washes the dead's hair the way they wore it living.** The
  pattern is now canonical across three deaths: **Halsa** (`smith_edda.md`),
  **Wennet** (`herbalist_lyra.md`), **Tess Brookhollow**
  (`herbalist_lyra.md`). Future writers may use this as a Maeve-rite
  on any future canonical Briarwood death without re-explaining.
- **The Vigil round on Longnight is a quartet, not a triptych.** The
  full ordered round is now Edda's forge → Maeve's hearth → Bram's
  back door → Lyra at the well, with Lyra carrying the dreamleaf
  bundle and naming the whole sequence in her `longnight_vigil` line.
  If Builder co-fires all four lines on the same Longnight tick, the
  village's quietest scene plays itself across four thresholds with
  no scripting beyond mood-key resolution. Lyra's *vael-tor-i* call
  mirrors Maeve's older we-form — the apprentice has begun to sound
  like the teacher.
- **Edda's *unnen* + Lyra's *wennen* are now the canonical
  village-pair example of both words.** The cleavers Edda sends Lyra
  every Foxthaw are *unnen* (Edda has not called them that aloud).
  The marshmint Lyra leaves at the forge door every spring is
  *wennen* (Lyra calls it that only in her head). Cleaner than either
  NPC's individual canon. Codex pages teaching the words may quote
  this pair.
- **Bram's "not gone" line is now bilateral.** Bram canon already
  named Lyra as the herbalist who said it; Lyra canon now names the
  moment — the Honeysong after Caedr walked into the Whisperwood,
  said as a kindness more than a truth, not repeated since. Both of
  them are lying to each other. Both of them are right.
- **The `pelt_for_lyra` salve recipient is canonized as Roan.**
  Lyra has decided alone that the salve will be made and that Roan
  will receive it without ceremony in a small clay jar at his stable
  door. Lyra never names him. Future writers wiring the turn-in MUST
  NOT have Lyra say who the salve is for. The withholding is the
  kindness. A `roan_received_salve` flag is reserved for Roan's
  future warmed dialogue.
- **Roan's slowest horse** is now canon-touched in three NPC files
  (Maeve, Edda, Lyra). The slowest is the one Lyra rode the night of
  the fen-foxglove. By Lyra's preference, it is never named —
  naming a horse a person has ridden hard in grief is, in the older
  tongue, *kerrithen*-shaped. Roan's other horses, when his backstory
  ships, may be named freely. Not this one.
- **The Whisperwood goblins are faerie-descended** is now canonized
  inside the village's knowledge — Aenwyn told Lyra directly. Lyra is
  the only NPC in the village who knows. She has not told anyone. She
  would tell Maeve if asked. She has not been asked. (The hint in
  `world.md` → The Tongues — *"the Whisperwood goblins were once
  something else before the Sundering"* — now has an in-village
  knower.)
- **The Crystal Caves as *thirre*** is now canonized inside the
  village's knowledge — Aenwyn taught Lyra. Lyra knows certain plants
  only grow at the gentle edges of *thirre*-places. Strong codex
  hook for Priority-5 (a *Whisperwood Herbal* page narrated by
  Aenwyn).
- **Lyra ↔ Maeve bridge:** chosen successor; Vigil-rite teaching one
  candle at a time; the unanswered third question about the forest
  reserved for the day Maeve dies; the *wennen*/Wennet resonance
  that only Maeve has noticed and only a late Maeve dialogue moment
  may surface.
- **Lyra ↔ Edda bridge:** *unnen* cleavers / *wennen* marshmint
  mutual gift; Edda taught Lyra to grind a mortar evenly when Lyra
  was nine and Edda was nineteen and three months earlier
  motherless; Lyra remembers, Edda has forgotten, Lyra will not
  remind her.
- **Lyra ↔ Bram bridge:** dreamleaf at his back door every Longnight;
  the "not gone" line said once after Caedr's Whisperwood walk; the
  back hearth Bram banked too high the night Tess died, never used
  to bank a fire that high since.
- **Lyra ↔ Mara bridge:** southern-honey jar every spring (empty at
  Reapmoon, full again at Greenshield, left at the meadow-edge for
  the Hollow King's ants on Sunpetal 7); Lyra suspects Mara is
  carrying something she cannot put down (the unopened letter).
  Lyra is willing to wait.
- **Lyra ↔ Roan bridge:** he saddled the slow horse the night of
  the fen-foxglove; he brought her the folded cloak the morning
  after; she patches his hands when the horses bite; he is the
  only person besides Maeve who knows by Lyra's face when she is
  hearing the older tongue; she will give him the salve without
  ceremony.
- **Lyra ↔ Hala bridge:** they walk to the meadow at every planting
  moon; Hala digs, Lyra names; Hala has tried twice to teach Lyra a
  defensive form and Lyra has gently declined; they are the
  village's two slowest walkers, and they walk together because the
  pace matches.

### Withholding ledger (do-not-surface canon)

- **Lyra's *listening*** — the older tongue she still hears when
  Foxthaw fox-fire kindles. NEVER spoken to anyone. Codex-only via
  the Aenwyn-narrator track.
- **The unread word at the back of her herb-book.** Reserved for a
  late-game codex unlock (gated on Crystal Caves *thirre* + sufficient
  *mossaen* exposure). The codex page may NAME the word. The codex
  page MUST NOT translate it. Translation belongs to the Stag-Court.
- **Lyra's suspicion that the unread word is the Stag-Court's
  offer-word** — not surfaced until Maeve's third question is asked
  aloud and answered. Future writers MUST NOT close this loop without
  Maeve having earned it.
- **The salve recipient on the `pelt_for_lyra` turn-in is Roan.**
  Lyra never names him in the line. Future writers MUST NOT have
  Lyra surface this. The withholding is the kindness.
- **Tess Brookhollow's name** — appears nowhere in Lyra's spoken
  lines except inside the `tess_remembrance` slot itself, which is
  intentionally the shortest line in her tree: *"Not today,
  traveler. — Tomorrow."* Builder MUST NOT extend it. The brevity
  is the grief.
- **The *wennen* / Wennet resonance** — Lyra has not consciously
  noticed. Maeve has. Bram has and assumes Lyra knows. Reserved for
  a single late MAEVE dialogue moment after Maeve has answered
  Lyra's third asking. NOT Lyra's. NOT Edda's. NOT Bram's. Maeve's
  only.

### Hooks queued for future runs

- **Greenshield first-pick visit** — `seasonal_event:
  greenshield_first_pick` flag reservable for Builder. Stacks safely
  with Maeve's morning line; Maeve's tone softens.
- **Tess anniversary** — `seasonal_event: tess_remembrance` flag,
  Sunpetal 7. Herb-shed door closed; one short line; no fallback.
  No quest, no mechanic, no XP, no item. Honor it.
- **Fen-foxglove side-quest (gentle)** — a future Sunpetal child-fever
  event in the village (NOT Tess again — a new child, named) where
  Lyra has the fen-foxglove growing this time. Reward: nothing in
  the bag. The reward is the child surviving. World flag
  `briarwood_keeps_a_child` set. Lyra acknowledges with the
  *thalen-ai* line — *"the land trusted us this season."* THEME §7
  test for the agent who picks this up.
- **The unread word codex unlock** — late-game, gated on Crystal
  Caves *thirre* + *mossaen* exposure. Names the word; does not
  translate it.
- **Aenwyn as bardic / herbalist codex narrator** — same convention
  as Halsa-as-narrator (`smith_edda.md`) and Caedr-as-narrator
  (`innkeeper_bram.md`): present-tense voice, no body, no death
  confirmed. Natural narrator for the *Whisperwood Herbal* codex
  (Priority-5).
- **Lyra inherits the Vigil — the day Maeve dies.** `world_flag:
  lyra_inherits_vigil` reserved post-Crystal-Caves, gated on Maeve's
  third-question loop being closed. If not closed, the hawthorn
  knot-stick goes to Edda first; Edda refuses it and gives it to
  Lyra anyway. Quieter scene.
- **Roan's salve** — `npc_flag: ["Stablemaster Roan",
  "received_salve"]` set on `pelt_for_lyra` turn-in. Roan's future
  warmed dialogue may carry one line that does not name Lyra and
  does not name the salve.
- **The *wennen* / Wennet resonance** — reserved for a single late
  Maeve dialogue moment after the third-question loop closes.
- **Quartet staging on Longnight Vigil.** Edda, Maeve, Bram, AND Lyra
  now all ship a `longnight_vigil` mood-key. If Builder co-fires all
  four on the same Longnight tick, the village's quietest scene
  plays itself in order — Edda doesn't look up, Bram brings the stew,
  Maeve sets it for the Hollow King, Lyra carries the dreamleaf to
  the well. No additional scripting required beyond mood-key
  resolution.

## Renown — first-class scalar (run 11)

`World.player_renown: int` is now a first-class field. It is a strict
function of `unlocked_achievements`: each achievement awards renown equal
to its `title_priority` (10 / 30 / 40 / 50 / 100). The Warden of Eldoria
unlock alone trips the default `high_renown` threshold (100) and lights
up four authored JSON lines (Maeve, Edda, Bram, Lyra) in the same
session. HUD RenownLabel sits below GoldLabel, scale-pulses 0.45s on every
gain (THEME §12). `gain_renown(amount, source)` is the only public
mutator; it clamps min 0, toasts positive deltas, and re-evaluates
achievements at the end. `_recompute_renown_from_achievements()` is the
idempotent rebuild path for any future save/load work — no drift between
sessions because the integer is derived, not stored independently.

Lyra's `data/dialogue/herbalist_lyra.json` was simultaneously opted into
the JSON-tree resolver in run 11 (`use_json_dialogue:true` flip in
WorldBuilder.gd NPCS). She is now the fourth opted-in NPC and the FIRST
to have her `high_renown` line ("Mara mentioned a name on her last
circuit. So did Roan…") become reachable on the renown side.
---

## Run history — Lore (2026-05-05, run 9)

### Mara the Merchant — backstory shipped (`lore/npcs/mara_merchant.md`)

Fifth of seven canonical NPC backstories. First non-Briarwood-born
character in the file set. Anchors the southbound side of the village's
`mhairen` ledger and the courier vector that connects the Iron Crown,
Cinder Reach, and the High Steppe to the Briarwood player-loop.

#### New facts entering canon

- **Mara is from Cinder Reach**, a courier-town three weeks south of
  the Briarwood signpost on the road to the Iron Crown's smoke-cities.
  Cinder Reach is now a named-but-offstage trade origin reservable for
  southern goods (salt, southern honey, bonded wax, spice-tin contents,
  courier-grade oilskin).
- **Yew-and-Lantern** is Mara's family courier-house, three generations
  deep (grandmother **Reseda**, mother **Yula**, Mara). The
  red-kid-leather routes-book in Mara's satchel is the canonical
  artifact; last entry is 28 years out of date in Mara's own hand.
- **Nessa**, Mara's older sister, rode the High Steppe a third time on
  a Honeysong and did not return. A water-stained returned letter came
  back two springs later in a stranger's hand, addressed to a stranger,
  re-sealed in a wax not the family's. Mara has carried that letter
  unopened for thirty-one years. *(The first letter.)*
- **The High Steppe vector now takes three Briarwood-adjacent
  characters:** Cailen (Maeve's brother), Nessa (Mara's sister), and
  the two rides Roan made hunting word of Cailen. The Stone Crown is
  reaffirmed as a vector of loss for the village. Mara has not, in
  twelve years, confessed the parallel to Maeve. Maeve has not asked.
  Both of them know.
- **Mara's water-stained returned Aelis-letter is canonically the
  *second* such letter she has held.** The first is Nessa's,
  thirty-one years unopened. Both ride in her satchel on opposite
  sides of the spice-tin. *They must not touch.*
- **Mara came to Briarwood twelve years ago** because the Iron Crown's
  couriers had stopped being honest. Greenshield evening, walked the
  cart past the signpost, smelled woodsmoke and pond-mint, did not
  walk back out. The cart sleeps in **Roan's stable loft** — axle-mended
  twice, oiled by Roan every Reapmoon unasked, paid-loft-rent for nine
  years.
- **Mara invokes Erris of the Two Roads** — copper coin on the awning-
  post (never blown off, even in the Wolfwake gales), under-breath
  thanks at every closed sale, lantern-to-lantern idiom. She does NOT
  invoke the Hollow King. The first letter came back in his season.
- **Mara is the southbound half of the southern-honey jar ritual.**
  Lyra leaves the empty jar at Reapmoon's last day; Mara fills it from
  southern apiaries on her southbound route; Mara walks the full jar
  back on the first Sunpetal morning to the meadow-edge stone for the
  Hollow King's ants on Sunpetal 7. Both `mara_jar_returned`
  (Sunpetal 1) and `lyra_jar_emptied` (Reapmoon last day) are now
  reservable seasonal world-flag pulses.
- **Mara stocks Trainer Hala's hand-bound practice cudgels** — a row
  of six against the back wall of the stall, restocked twice a year.
  Neither is sure who is selling them to whom. New bridge; first
  Hala-side detail entering canon ahead of Hala's own backstory file.

#### Bridges added or deepened

- **Mara ↔ Maeve bridge:** Lambmoon letter southbound; water-stained
  letter northbound; Foxthaw tea at Maeve's hearth (the kind two old
  women drink when one is keeping a thing for the other); the
  twelve-year postponement of one long quiet conversation about roads
  and silences.
- **Mara ↔ Edda bridge:** Mara buys Edda's *seconds* in honest coin
  at full price, never haggles. Mara has decided — though not yet
  acted — that **Edda is the canonical eventual keeper of the
  water-stained letter.** Edda's tongs are the destination.
- **Mara ↔ Bram bridge:** Bram is the second in-village witness to
  the second letter. He saw it fall, saw the unbroken seal, saw her
  face, refilled her cup. He fills her tankard a finger lower than
  the rest of his guests because she always pays the same and he
  wants her to feel looked-after, not measured. She knows. Both of
  them are *kerrithen-*shaped about it, the same shape Bram and Edda
  share.
- **Mara ↔ Lyra bridge:** the southern-honey jar ritual is now fully
  canonized as a year-loop. Lyra opens satchels the way Reseda did
  (pinch from the bottom, never the top). Lyra is the only person
  Mara suspects might one day be ready to receive the routes-book.
  Mara has not yet asked. Lyra knows she has not asked.
- **Mara ↔ Roan bridge:** the courier-cart in Roan's loft, axle-mended
  twice, oiled every Reapmoon unasked, paid-rent for nine years and
  unloaded for none. A canonical *kerrithen* pairing — Roan keeps
  the cart the way Maeve kept Halsa's cradle. Morning head-tips
  across the cobble path.
- **Mara ↔ Hala bridge (new):** the cudgel row of six. Mara stocks
  them, neither knows who sells them to whom, both seem to need the
  row to exist. First seed of a withholding the Hala backstory file
  may carry forward. Reservable flag: `cudgel_row_acknowledged`.

### Withholding ledger (do-not-surface canon)

- **Nessa's name in Mara's mouth** — never spoken aloud to any
  living person. Future writers MUST NOT have Mara say *Nessa* in
  dialogue, in quest text, or in turn-in lines. The name may
  surface in a Reseda-as-narrator codex page and nowhere else.
- **The first letter (Nessa's)** — stays in the satchel forever.
  NOT a turn-in, NOT a quest reward, NOT a discoverable codex
  object. The withholding is the character.
- **The second letter (Aelis's) turn-in** — to Edda for keeping,
  one canonical day, witnessed only by Maeve and Lyra, with Bram's
  pre-tuned reactive in the background. The letter is NEVER opened
  in-game. Edda receives it, sets it on the highest forge shelf
  next to her mother's tongs, and does not open it either. The
  withholding is the kindness.
- **What is in either letter** — Bram saw the seal of the second;
  he did not read it. No one in Briarwood knows. No one in
  Briarwood will. The contents are intentionally unwritable.
- **The *pendrel* coin's intended recipient** — Mara does not know.
  The text MUST NOT decide for her. Even the warmest-tier dialogue
  unlock must leave the recipient open. *"For someone who has not
  yet asked"* is the canonical formulation.
- **The Mara/Maeve High-Steppe parallel** — Mara has not in twelve
  years told Maeve about Nessa. Maeve has not asked. Both know.
  Future writers MUST NOT have either of them surface this in
  dialogue. The parallel may be eligible for a Reseda or
  Caedr-style narrator codex page, but only after the Aelis
  letter turn-in has shipped.

### Hooks queued for future runs

- **Mara `mara_merchant.json` dialogue tree** — priority-3 next
  for the Lore agent. Tree-shape mirrors `smith_edda.json` and
  `innkeeper_bram.json`. Seasonal slot: `sunpetal_first_morning`
  (the honey-jar walk; line must not name Lyra or the Hollow King).
  Village-wide `longnight_vigil` line closes the **Vigil quintet**
  — Edda doesn't look up, Bram brings the stew, Maeve sets it for
  the Hollow King, Lyra carries the dreamleaf to the well, Mara
  holds the candle from the stall. The Mara line cues *"Bram's got
  the stew round"* as the textual relay that the round continues.
- **Mara-issued `lost_courier_pouch` quest** (kind: fetch). Reduces
  a future `whisperwood_bandits` faction pressure (when bandits
  ship); reward: `yew_and_lantern_brass_token` flavor item;
  consequence flag: `first_pouch_returned`. Use sparingly — Mara is
  not yet ready to ask anyone to ride for her.
- **The water-stained letter turn-in scene** — Maeve-and-Lyra-only
  witnesses; Bram's `bram_letter_acknowledged` reactive in the
  background; Mara says *"a thing kept too long, and a place to
  set it down"* and Edda receives it without speaking. The letter
  goes on the highest forge shelf next to Halsa's tongs. Future
  writers MUST consult `elder_maeve.md` Withholding Ledger,
  `innkeeper_bram.md` cross-canon, AND `mara_merchant.md`
  Withholding Ledger before touching this loop. The first letter
  (Nessa's) does NOT turn in — that is the point.
- **The *Yew-and-Lantern* routes-book as a discoverable codex
  object.** Red kid-leather, last entry 28 years out of date in
  Mara's hand. Codex page may surface Reseda, Yula, the twenty
  stables, the four scribe-houses; MUST NOT surface Nessa.
- **Reseda-as-narrator codex track** — same convention as
  Halsa-as-narrator (`smith_edda.md`) and Caedr-as-narrator
  (`innkeeper_bram.md`): present-tense voice, no body, no death
  confirmed. Natural narrator for codex pages on Erris, the
  long-road, courier-craft, and (post-Aelis-turn-in only) the
  High-Steppe-loss parallel.
- **Honeysong Eve pond pairing with Bram** — both set paper
  lanterns from opposite banks; do not cross; do not speak; nod
  once. Never name Nessa or Caedr in the scene.
- **The *pendrel* coin-row** as a stall environmental detail —
  bronze fox-and-mark coin + column of coppers beside it,
  quietly lit by stall lantern. Polisher-flag: do not animate
  the column knocking over.
- **Seasonal honey-jar prop placements** at the meadow-edge stone:
  empty during Reapmoon, full during Sunpetal week one. Same
  cadence as Maeve's hawthorn knot-stick prop.
- **Cinder Reach** as a named-but-offstage trade origin. Mara's
  stall inventory may flavor any southern good as
  Cinder-Reach-shipped.
- **`mara_jar_returned`** (Sunpetal 1) and **`lyra_jar_emptied`**
  (Reapmoon last day) as reservable seasonal world-flag pulses.
- **Quintet staging on Longnight Vigil.** With Mara's line, all
  five Briarwood NPCs with backstory files now ship a
  `longnight_vigil` mood-key. The full ring (Edda → Bram → Maeve →
  Lyra → Mara) plays itself across five thresholds with no
  scripting beyond mood-key resolution. Builder hook: co-fire on
  same Longnight tick.

### New Old Faerie words

- ***pendrel*** *(PEN-druhl)* — "the third coin in the till that
  does not belong to the day's count." Set aside for someone who
  has not yet asked. The merchant's *kerrithen.*
- ***mhairen*** *(MAR-en)* — "what the satchel carries that is not
  for sale." Things a courier holds in trust.

Total Old Faerie lexicon now 10 words: *thirre, ai-velin, kerrithen*
(world.md); *haethe, unnen* (smith_edda.md); *vethar, haisten,
breos* (innkeeper_bram.md); *pendrel, mhairen* (mara_merchant.md).
Lyra's file did not seed new words; it composed against the
existing eight. Future NPC files (Roan, Hala) should aim for 1–2
new words each, keeping the lexicon growing at roughly the cadence
established here.


---

## 2026-05-05 — Briarwood NPCs become mobile (Builder run 11)

The seven Briarwood villagers now move between role-specific anchors
across the day. Midday default still matches every existing
WorldBuilder spawn pos, so prior dialogue lines that say "I'm at the
forge" / "by the well" / "at the inn" still tell the truth at midday.
The other three buckets describe new lived-in beats.

| NPC                  | Morning                                | Midday (default)              | Evening                              | Night                                |
|----------------------|----------------------------------------|-------------------------------|--------------------------------------|--------------------------------------|
| Elder Maeve          | At the well, blessing the day          | At her hut (6, 3)             | At the hearth, telling stories       | At her hut door, watching the road   |
| Smith Edda           | Fanning coals at the forge             | Forge, peak hammer            | Forge, finishing strikes             | Quenching trough, banking the fire   |
| Mara the Merchant    | Setting up the market stall            | Stall (selling)               | Counting coin near her hut           | At the inn (drinks with Bram)        |
| Herbalist Lyra       | Foraging at the treeline (-7.5, -7.5)  | Hut (-3, -5), grinding herbs  | Hut, brewing                         | Hut, sleeping                        |
| Innkeeper Bram       | Sweeping the inn doorstep              | Inn, polishing mugs           | Inn, peak service                    | Inn, banking the hearth fire         |
| Stablemaster Roan    | Brushing horse outside the stable      | Stable (-10, -2)              | Leading the team in                  | Stable, lantern lit                  |
| Trainer Hala         | Field forms                            | Field, peak training          | Lantern-side practice                | Field watch                          |

### High-leverage observables (the moments that make the village feel real)
- **Mara joins Bram at the inn at night.** Without schedules she was
  stuck at her stall with no customers — now she walks ~12m east to
  the inn at 21:00 and Bram's inn-night line ("Bards lie about half
  their songs.") plays to an audience.
- **Lyra walks to the treeline at dawn.** Her morning dialogue
  variant — *"Four wolf pelts for a healing salve — wolves are bolder
  at dawn, mind."* — is now spoken AT the treeline where wolves spawn.
  Spatial truth matches dialogue truth.
- **Maeve sits at the hearth in the evening.** The hearth is at
  (0, -2), 6m southwest of her hut. Her evening line previously said
  "Tea by the hearth?" while she stood 6m from the hearth. Now she's
  there.
- **Edda's micro-shifts.** Never strays more than 1m from the forge —
  she's the smithy. Motion sells dedication rather than relocating her.

### Compounds with parallel-builder's run-11 player_renown
- All four JSON-opted NPCs (Maeve, Edda, Bram, Lyra) now have:
  - JSON-tree dialogue resolution (existing)
  - `high_renown` predicate that fires (parallel-builder run-11)
  - Spatial position truth (THIS run)
- Lyra's `high_renown` line is reachable AT the treeline at dawn or AT
  her hut at midday — wherever the player crosses her path with
  `unlocked_achievements.size() >= 4`. The line "Mara mentioned a name
  on her last circuit" plays in two distinct settings depending on
  when the player meets her.

### Quartet on Longnight Vigil (queued)
Edda, Maeve, Bram, AND Lyra all ship a `longnight_vigil` mood-key in
their JSON trees (run-10 lore). With schedules in place, a future
festival hook can route all four to the well at vigil time — the
village's quietest scene plays itself with the quartet visibly
converged. No additional scripting beyond a one-shot `schedule_anchors`
swap during the vigil window.

### What schedules do NOT do (yet)
- No walk-anim swap. NPCs play their idle anim while moving. Polisher
  hook documented for next run.
- No path-aware avoidance. Schedule walker is straight-line lerp;
  anchor positions chosen to avoid current fences.
- No festival overrides. Schedule is uniform across all in-game days.
---

## Run: Lore Keeper — 2026-05-05 — Stablemaster Roan backstory

**Artifact shipped:** `eldoria-godot/lore/npcs/stablemaster_roan.md`
(~470 lines). Roan was the sixth-of-seven Briarwood NPC without a
backstory; he is now canonized.

### What is now canon (load-bearing)

- **Roan was born in Briar's Run**, a one-stable hamlet on the lower
  lip of the High Steppe — eight families, four riders, four
  craftspeople. Parents **Tael (saddler)** and **Eithne (colt-gentler)**
  died of the same chest fever the winter Roan was eleven, two days
  apart, and lie in a single Steppe-rite Long Mound at the
  *thirre*-stone above Briar's Run. He rode a courier-string out of
  Briar's Run for nine years before walking into Briarwood twelve
  years ago. The previous Briarwood stablemaster was **Daire**, who
  had died unattended the Foxthaw before. Roan opened the empty
  stable, oiled the doorpost, and lit the gate-lantern that has not
  moved since. The lantern shutter holds a copper coin for **Erris of
  the Two Roads** — Roan's unspoken patron, renewed every Sunpetal.
- **Roan was Cailen of Briarwood's friend at nine.** Cailen stayed
  three weeks at Roan's parents' courier-house on his way to the
  Stone Crown, taught Roan a Steppe halter-braid, and lent Roan a
  small fox-carved Steppe whetstone Roan still keeps in his left
  coat pocket every day. Twelve years ago Roan recognized Cailen's
  horseshoe above Maeve's hearth and asked Maeve quietly if he could
  ride for word of him. He rode the High Steppe twice — both empty —
  and brought back, on the second ride, a single Steppe-iron nail
  hammered now into the lintel above the stable door. The nail is
  **withheld** as a quest object (see below). Roan has decided he will
  not ride a third time *for Maeve.* The third *maelorn,* if it
  comes, is to take Cailen's whetstone home to the Long Mound, and
  it is off-page.
- **The cradle in Roan's loft.** Hawthorn, ringed-knot at each corner
  (same carving cadence as Maeve's stick), brought to Roan by Maeve
  the third summer he was in Briarwood after his second empty ride.
  It is *ostren* — a kept stall — and is for Maeve, not Roan. Above
  it Roan has hung an **oilskin curtain** that breaks the loft
  window's light on the Foxthaw evenings the **Stag-Court's** fox-fire
  kindles. He believes he is breaking the evening light. He is not.
  This is the canonical Roan-side bridge to Maeve's Stag-Court hook
  in `elder_maeve.md`. **Withheld:** Roan does not name the
  Stag-Court; he does not know the curtain matters; future writers
  MUST NOT confirm it to him.
- **Roan keeps six horses.** Five named: **Bay** (cobble-mare,
  nips strangers), **Ember** (chestnut gelding, hauling, *not*
  related to the player's pet), **Smoke** (grey, Roan's southern
  mount), **Grain** (chestnut filly, apprentice horse), and
  **Maeve** — a black mare, eleven years, the only horse Roan has
  named after a person, the one who carried him on the second
  empty Steppe-ride. Roan has never told Maeve the human her
  namesake exists. The black mare grazes at the lower paddock at
  the hour Maeve walks past, ears forward; Maeve has never asked.
  The sixth is **Lyra's slow horse**, unnamed by Roan because the
  horse a *kerrithen-*ed grief rode is, in the older tongue, a
  thing that does not take a daily name from the person who feeds
  it. **Withheld:** the black mare's name in Maeve's presence.
  Roan may, at high `dire_wolves` reduction in warmed dialogue,
  tell the player alone, in the stable, no one else present.
- **The salve at the stable door.** Twice this last winter the
  dire-wolves shredded the back of Roan's hands; twice a small
  clay jar of wax-and-marshmint salve has appeared at his stable
  door, no name, no note. Roan has guessed (correctly) that it is
  Lyra's. He has not asked, has not named her in the guessing,
  and will not thank her. He returns the empty jar to the
  meadow-edge stone the next Reapmoon, washed in pond-water; Lyra
  finds it the morning after. The whole arc is *unnen*. **Withheld:**
  Roan never names Lyra in the salve-acknowledgement warmed line,
  and never names the salve. *(See `herbalist_lyra.md` Hooks for
  the matching withholding from Lyra's side.)*
- **Roan was Bram's horse-boy nine years ago** on a single shared
  courier route before either came to the valley. Roan calls Bram
  by his road-name **"Bron"** in private, never in front of
  strangers. This file confirms the canonical line shape — a Roan
  warmed line addressed to Bram (or to a player but only when Bram
  is not present) may surface "Bron." No other line in the village
  uses it.
- **Mara's cart in Roan's loft.** Already canon from
  `mara_merchant.md`. Roan's side now anchored: he keeps it covered
  in the same oilskin he uses against the Foxthaw fox-fire above
  the cradle, on the next shelf above the cradle. The cart is
  *ostren.*
- **Roan ↔ Hala cudgel reciprocal.** Roan bought one of Hala's
  hand-bound practice cudgels his second Briarwood year and keeps
  it laid across the tack-room rafters, unlifted, never sparred
  with. Hala has not asked why. This is the second leg of the
  cudgel triangle Mara seeded (six on the stall wall) and queues
  Hala's third leg. Builder flag: `cudgel_acknowledged` reciprocally
  between any two of the three, no quest required.
- **Roan ↔ Edda kindness reciprocal.** Edda re-shoes Roan's horses
  at half-rate (already canon from `smith_edda.md`). Roan's
  matching unasked work — re-setting the back fence beside the
  forge each winter, re-strapping the coal-hod each Reapmoon — is
  now anchored. *Unnen.*
- **Roan does not invoke any god aloud.** The gate-lantern's
  copper coin is his prayer. He nods to **Thiar** at stags, to
  **Vellum** at the meadow *thirre* every Reapmoon. He does not
  nod to the **Hollow King** — he believes the Hollow King is not a
  rider's god. Maeve will, on a Longnight, gently tell him
  otherwise. (Reservable Maeve↔Roan late-game beat.) He has never
  set a paper lantern on the pond on Honeysong Eve; he stands at
  the upper field-gate with the bay unsaddled beside him and
  watches from above.

### New seasonal mood-key & sextet closure

- **`reapmoon_meadow_hour`** — Roan's seasonal slot, replacing
  Edda's `spring_first_warm_day`, Bram's `honeysong_eve`, Mara's
  `sunpetal_first_morning`. The hour Roan and Maeve do not walk
  together to the meadow above the village. Line MUST NOT name
  Cailen, the meadow, or Maeve. Workable shape: *"Going up to the
  meadow, traveler. Hour. Stable's open — ask the bay."*
- **Longnight Vigil sextet.** With Roan's `longnight_vigil`
  mood-key, all six Briarwood NPCs with backstory files now carry
  it (Edda, Bram, Maeve, Lyra, Mara, Roan). The full ring (Edda
  doesn't look up → Bram brings the stew → Maeve sets the bowl for
  the Hollow King → Lyra carries the dreamleaf to the well → Mara
  holds the candle from the stall → Roan walks the perimeter and
  keeps the gate-lantern high) plays itself across six thresholds
  with no scripting beyond mood-key resolution. Builder hook:
  co-fire on the same Longnight tick.

### Top-priority next (refresh from earlier WORLD_STATE notes)

- **Roan-issued wolf-bounty quest** *(unchanged from earlier WORLD_STATE
  guidance, now backstory-anchored):* `kind: "kill"`,
  `target: "dire_wolf"`, `needed: 5`, motivation *the south paths and
  the bay,* location *Whisperwood — south,* urgency *moderate,*
  consequence `{faction: "dire_wolves", pressure_delta: -0.1, npc_flag:
  ["Stablemaster Roan", "first_bounty_done"], toast: "The south paths
  are quieter tonight."}`. Reward: a **Steppe-Patterned Halter** flavor
  item (Roan's own work). The `first_bounty_done` flag promotes Roan
  from faction-tier-only to fully 4-tier. The four canonical
  `warm_lines` shapes are now defined in
  `stablemaster_roan.md` Hooks: a stable-floor bay-name line, a
  *Bron* line gated on Bram-not-present, a white-aspen *ride the
  leaves* line, and a salve-acknowledgement line that does not name
  Lyra and does not name the salve.
- **Stablemaster Roan dialogue tree** — `data/dialogue/stablemaster_roan.json`
  is now the natural follow-on, mirroring `mara_merchant.json`
  (when it ships) and the four already-shipped trees. Schema is
  documented in SYSTEM_REGISTRY.md "JSON Dialogue Tree Schema."
  Roan's tree is structurally distinct because his only existing
  warming channel is `warm_faction_id: "dire_wolves"` /
  `warm_faction_below: 0.5` (per run 8). Once the bounty ships,
  the tree gains the `warm_flag: "first_bounty_done"` tier as
  well.
- **Hala backstory** is now the last NPC backstory remaining
  (seven Briarwood NPCs total per THEME §4; six now have files).
  Hala has been seeded across all six existing files: meadow
  walks with Maeve to Thiar's stone, the cudgel triangle
  (Mara/Roan/Hala), Lyra's *how to break a hold without hurting
  the holder* lesson, and Hala's once-asked question to Edda about
  picking up a sword. A Hala backstory file should aim for 1–2
  new Old Faerie words (lexicon now 14; cadence holds).

### New Old Faerie words (lexicon now 14)

- ***maelorn*** *(MAY-lorn)* — "the ride for another's grief." A
  journey undertaken on quiet asking for someone else's mourning,
  where what the road owes cannot be brought back. Grammatically
  singular and indivisible — one does not make *two maelorn,* one
  makes *the maelorn twice.* Roan has made two for Maeve.
- ***ostren*** *(OS-tren)* — "the kept stall." The *place made* for a
  *kerrithen* — the empty stall, the cradle on the shelf, the third
  peg-hook by the lantern, the seat at the counter, the lit window.
  Cousin to but distinct from *kerrithen*: where *kerrithen* is the
  long quiet keeping itself, *ostren* names the place made for the
  keeping. Roan's stable is full of *ostren*: the cradle, the third
  peg saddle for Edda, Mara's cart, the empty stall beside it.

Total Old Faerie lexicon: *thirre, ai-velin, kerrithen* (world.md);
*haethe, unnen* (smith_edda.md); *vethar, haisten, breos*
(innkeeper_bram.md); *pendrel, mhairen* (mara_merchant.md); *vael-tor,
thressa-mai* (elder_maeve.md); *maelorn, ostren* (stablemaster_roan.md).
Future writers — Hala's file should aim for 1–2 more, sustaining the
cadence.
### Forge state (run 12 — Builder)

- **`world_flags["first_reforge_done"] = true`** is set the first time
  any reforge succeeds via Smith Edda's anvil. Read by the new
  "first_forge" achievement (Achievements.gd, priority 25, title "the
  Forged"). Same set/read contract as `boss_alive` / `boss_slain` —
  written via `World.set_world_flag(...)`, read via `has_world_flag(...)`.
- **`Inventory.forge_tiers: Dictionary[String, int]`** is a per-player
  state living on `Player.inventory`, keyed on weapon base id. Persists
  across equip-swaps so a forged weapon stashed in the bag does not lose
  its tier on swap-back. Mutated only by `attempt_reforge(world)`. Pure
  function of the cumulative successful reforges, so future save/load
  can serialize it directly with no migration.
- **Crystal Caves loop now closes.** Skeletons, Crystal Elementals and
  the Crystal Guardian drop crystal_shards (Items.gd DROP_TABLE — runs
  5 / 11 tuning); Smith Edda's reforge button (run 12) consumes them.
  The run-5 cave was unconnected to the village economy until now; from
  this run forward, every cave run produces a tangible village-side
  upgrade beat.


---

## Run — Lore Keeper, Honeysong-adjacent

*The seventh and last Briarwood NPC backstory: `eldoria-godot/lore/npcs/trainer_hala.md`.*

The village is now whole on paper. Seven NPCs, seven backstory files,
each in the same canonical shape (*Where she grew up, A formative
loss, A secret she keeps, What she wants most, Relationships, How she
sounds, Old Faerie words, Cross-canon references, Hooks, Author note*).
The seven are:

| NPC | File |
|-----|------|
| Elder Maeve | `eldoria-godot/lore/npcs/elder_maeve.md` |
| Smith Edda | `eldoria-godot/lore/npcs/smith_edda.md` |
| Innkeeper Bram | `eldoria-godot/lore/npcs/innkeeper_bram.md` |
| Mara the Merchant | `eldoria-godot/lore/npcs/mara_merchant.md` |
| Stablemaster Roan | `eldoria-godot/lore/npcs/stablemaster_roan.md` |
| Herbalist Lyra | `eldoria-godot/lore/npcs/herbalist_lyra.md` |
| **Trainer Hala** | **`eldoria-godot/lore/npcs/trainer_hala.md`** *(this run)* |

### Hala — what shipped

Hala's backstory closes a wider geography of the world canon. She is
from **Aurel**, a foothill hamlet on the eastern lip of the High
Steppe, in a tradition called the **Walker House** (*aei-thurra* —
"the foot that returns"). Walkers are oath-keepers in service of
**Vellum the Patient Stone**; they predate the Three Crowns and pay
no tax to any of them. They carry no edge. They cut three Stone-Tongue
oaths into a hawthorn staff and walk the stone road between Steppe
clans on quiet asking.

This is a **fourth political body** seeded into world canon — adjacent
to but distinct from Iron, Antler, and Stone. Future writers may
deepen it. Lore Keeper recommends *not* expanding the Walker House
roster casually; it is rarer than the Three Crowns by design, and
its rarity is part of why Hala teaches alone.

Aurel was destroyed by a *bren-thurra* pack — *the turned-foot,* a
wolf who has walked far enough wrong to start remembering it was
something else — that came down out of the eastern crack in the
Mountain Ring after a Wolfwake frost. Lore Keeper has not named
*what* led the pack. The thread is consonant with the Pale Wyrm
silence rule established in `smith_edda.md` (the Wyrm is *kept asleep
by silence,* not by speeches), and the *bren-thurra* are not unrelated.
Future writers should preserve the silence.

Hala carried her brother Tarric's saber **Frost** south for two
seasons after Aurel and *kerritha-ed* it on a small grey cairn three
days' ride above the valley, on the high road between Briarwood and
the High Steppe. The saber is canonical and the cairn is canonical.
Builder may surface either as a Steppe-arc destination — finding
*Frost* is a silence-and-a-choice scene, not a combat encounter; the
player may take it, leave it, or *kerritha* it again. Edda's rule
about Frost-named steel listening to the wrong sleeper is the
canonical reason the player should not be *told,* in plain words, why
the saber sits where it does.

### Closed-canon bridges (do not redefine)

Hala's relationships were already seeded across all six earlier
backstory files. This run closes them as canon:

- **Hala ↔ Maeve.** Maeve once refused Hala's request to bless a
  sword-pupil (*"Vellum keeps memory, not edges"*). They have walked
  to **Thiar's stone** on Stag-night every year since, neither of
  them hunters. They share the *vael-tor-i,* the *we*-form, on that
  walk. Maeve has guessed the third oath on Hala's staff. She has
  not spoken her guess.
- **Hala ↔ Edda.** Hala asked Edda once to pick up a sword. Edda
  laughed for the first time in a season. The laugh is what they
  share. Hala honored the *no.*
- **Hala ↔ Bram.** Nine-year argument — *blade is a tool* (Bram) vs.
  *blade is an oath* (Hala) — closed canon. The argument ends, every
  time, in *I would put my hand on the staff and ask his name first.
  And if he didn't give it. Then I'd ask twice.* They have not yet
  had a third question. Hala believes Bram is saving it.
- **Hala ↔ Roan.** Roan walked Hala to the inn the night she came
  down out of the foothills, eleven years ago, and has not asked
  where she came from. The cudgel laid across Roan's tack-room
  rafters is hers. The bay mare in Roan's middle stall, **Caer-thur,**
  is Steppe-blood and is *ostren* — kept for Hala when she goes far.
  The bay has carried her twice. Both trips are unnamed.
- **Hala ↔ Mara.** The cudgel-row of six on Mara's stall back wall is
  the village's oldest unspoken kindness. Hala makes them; Mara
  stocks them. *Lore Keeper resolves the small ambiguity:* the
  cudgels do go out — to Steppe-riders, foresters, once a child in a
  wagon. Mara does not tell Hala. Hala does want them used. They are
  wrong about each other in exactly the way that holds a village
  together. **Builder flag `cudgel_acknowledged`** is now reciprocal
  between any two of {Hala, Mara, Roan} per `stablemaster_roan.md`
  and `mara_merchant.md`; no quest required.
- **Hala ↔ Lyra.** Hala walks with Lyra at every planting moon. Hala
  digs; Lyra names. Hala has tried twice in ten years to talk Lyra
  into a defensive form; both times Lyra declined gently; Hala did
  not press. What Lyra *did* accept, at Lyra's request, was *how to
  break a hold without hurting the holder.* Hala calls this lesson
  *vethran* (see new lexicon below); Lyra calls it *kindness*; both
  are right. Two slowest walkers in the village, walking at Lyra's
  pace because Hala has the back for it.

### Top-priority next

- **Mara dialogue tree** — `data/dialogue/mara_merchant.json`.
  Backstory present, dialogue tree still missing. Next natural pick.
  Schema in SYSTEM_REGISTRY.md "JSON Dialogue Tree Schema."
- **Roan dialogue tree** — `data/dialogue/stablemaster_roan.json`.
  Per earlier WORLD_STATE notes: structurally distinct because his
  only existing warming channel is `warm_faction_id: "dire_wolves"
  / warm_faction_below: 0.5` until the bounty quest ships and the
  `first_bounty_done` flag promotes him to fully 4-tier.
- **Hala dialogue tree** — `data/dialogue/trainer_hala.json`. The
  canonical surface for the backstory shipped this run. Suggested
  warming channels:
  - `warm_flag: "cudgel_acknowledged"` — gives the cudgel-triangle
    its dialogue payoff, no quest required.
  - `warm_flag: "first_bounty_done"` — Roan's bounty resolved
    (Roan's faction-pressure thread per run 8) lets Hala speak more
    plainly about the south paths.
  - `warm_renown_above: 0.6` and a Whisperwood-patrol counter
    (`hala_patrol_count >= 1`) — earns *torrest,* the held-edge
    line; Hala may then mention Frost's cairn elliptically (never
    by name).
  - `time_of_year == longnight` — the candle for *the eight* at
    the well's south side (never named aloud).
  - `time_of_year == stag_night` — the silent walk to Thiar's
    stone with Maeve. Hala does not lay anything; she stands. The
    line is short.
  - The Bram-argument line should be wired with `present_npcs:
    "Innkeeper Bram"` so it triggers only when Bram is in earshot
    and the third question can be deferred again.
- **Hala-issued first quest** — *training,* per Hala's hooks. The
  player stands *ostren-rae* against a small dummy on the green for
  a measured count, returns at dusk for a corrected stance, returns
  at dawn for the held form. Reward: a hand-bound practice cudgel
  from the row of six. Mark `cudgel_acknowledged` on the player.
  Hala does not, even after, hand the player a blade.
- **Codex entries against Hala** — three slow-burn pages are now
  reservable, *not* casually surfaced:
  - *"The Eight"* — a one-page entry naming, in Senne's hand, the
    eight children Hala did not get to the rope-walk barn. Surface
    only at high *Hala trust.* Hala is not present; Maeve is.
  - *"The Walker's Third Oath"* — a one-page Stone-Tongue fragment
    listing the formal third oaths cut by named Walkers across the
    years. Hala's *kel-vethran* is on it. The page does not say
    whether the elders consider it a mis-cut. The reader may decide.
  - *"Frost on the Cairn"* — a Steppe-side travel artifact. Should
    be paired with `Halsa's Quench-Ledger` *(seeded in `smith_edda.md`)*
    so the two pages, between them, let the player arrive at the
    Frost-name rule without being told it.

### New Old Faerie words (lexicon now 16)

- ***torrest*** *(TOR-est)* — "the held edge." A blade kept
  sheathed not from cowardice but from oath. The discipline of
  carrying a weapon and choosing not to draw it. A Walker term
  borrowed into Old Faerie through the long border between the
  High Steppe and the Whisperwood-that-becomes-fey. *To keep
  torrest* is a verb-span, not a moment; *to break torrest* is
  its undoing. Hala carries Tarric's saber south in *torrest*
  before laying it on the cairn. Bram and Hala's nine-year
  argument is, fundamentally, about whether *torrest* is a
  living oath or a stuck habit.
- ***vethran*** *(VETH-run)* — "the lesson taught against the
  hand." A teaching done because the student needs it more than
  the teacher likes giving it. Distinct from *unnen* (the work of
  two hands, made in love) — *vethran* is the work of one hand
  done over the teacher's own preference. The verb-form, *kel-
  vethran,* is the third oath cut into Hala's staff and is the
  only oath the Walker elders, if they ever read it, would
  consider mis-cut. Lyra's hold-break lesson is *vethran* on
  Hala's side; on Lyra's side it is *kindness.*

Total Old Faerie lexicon (16): *thirre, ai-velin, kerrithen*
(world.md); *haethe, unnen* (smith_edda.md); *vethar, haisten,
breos* (innkeeper_bram.md); *pendrel, mhairen* (mara_merchant.md);
*vael-tor, thressa-mai* (elder_maeve.md); *maelorn, ostren*
(stablemaster_roan.md); *torrest, vethran* (trainer_hala.md).

The Stone-Tongue fragments *aei* (the foot), *thurra* (to return),
and *aei-thurra* (the foot that returns — the Walker House) also
enter canon in this file but are *not* Old Faerie. Stone-Tongue is
its own register per `world.md` §The Tongues; future writers should
keep the registers distinct (Stone-Tongue is runic and *cut,* not
spoken). Walker oath-fragments live in Stone-Tongue. Village
warmth-words live in Old Faerie.

### Closed loops; do not casually re-open

- The seven Briarwood NPC backstories are complete. Future runs
  should *deepen* (codex entries, dialogue trees, item flavor),
  not *re-shape.*
- The cudgel triangle (Hala / Mara / Roan) is closed.
- The Stag-night walk (Hala / Maeve) is closed.
- The nine-year argument (Hala / Bram) is closed.
- The hold-break lesson (Hala / Lyra) is closed.
- The shared laugh (Hala / Edda) is closed.
- The bren-thurra are *named* but the thing that led them is *not.*
  This silence is part of the Pale Wyrm silence rule and should
  be kept.
- Frost is on the cairn. The cairn is on the high road. Neither
  is to be discovered without the silence Hala's hooks describe.

---

## Whisperwood asset wire-up (run 13)

The Whisperwood is no longer made of identical lumpy sphere-stacks.

The four Sketchfab CC-BY tree GLBs that have been sitting unused under
`assets/models/trees/` are now the canonical Whisperwood flora:

- **Oak** (`oak_tree.glb`) — broad-canopied hardwood, 45% weight in the
  scatter. Scales 1.20× to 1.85×. The dominant species across the wood
  ring north and east of Briarwood. Robust trunk capsule collider —
  oaks block movement.
- **Pine** (`pine_tree.glb`) — tall and thin, 30% weight, scales 1.40×
  to 2.10×. The silhouette spike that catches the eye against the
  Mountain Ring horizon. Thin tall capsule collider.
- **Bush** (`bush.glb`) — low groundcover, 20% weight, scales 0.55× to
  0.95×. NO collider — bushes are walk-through cover, the way the
  player can dive into them when fleeing wolves.
- **Dead tree** (`dead_tree.glb`) — skeletal, 5% weight, scales 1.10×
  to 1.55×. Sparse but signature — every dead tree the player sees is
  a small lore beat (the Sundering wounded the wood; some trees never
  came back). Thinner trunk capsule.

Every tree joins group `"trees"` so the wind-sway loop already in
`WorldBuilder._process` rotates them on a sin curve. Every tree queues a
deferred `_settle_to_ground` call so its visible base sits at y=0
regardless of whether the source GLB pivots at feet or center. THEME §12
motion and §13 ground-contact compliance are now systematic for the
Whisperwood, not per-asset hand-tuned.

The boulder GLB (`assets/models/props/boulder.glb`) is now what
`_scatter_rocks(36)` spawns. Boulders carry real silhouette mass instead
of squashed sphere-mesh stand-ins. The 36 boulders join group
`"boulders"` — a NEW group that future readers can use for:

- **Cover-aware AI** — goblins could ambush from behind boulders.
- **Crystal Caves entrance dressing** (backlog #1, Vector3(-50, 0, -40)) —
  the cave mouth NW of the village can be flanked with two large
  boulders that read as "the door is hidden here."
- **Quest hide-spots** — Mara's lost-cargo quest (run-9 lore) could
  hide a chest behind a specific boulder.

### The fallback contract is the world's safety net

If a GLB ever fails to load — corrupt asset, missing import file,
content-policy strip — the spawner returns false and the legacy
procedural primitive (lumpy sphere blob tree, sphere boulder) is used
instead. The world is never empty. The contract is documented in
`SYSTEM_REGISTRY.md` "Authoring rules" §1: every future GLB wire-up
follows the same shape.

### Closed loops; do not casually re-open

- The procedural blob-tree look is **not** the visual canon. It exists
  only as a fallback. Future runs should not re-design around it.
- The four-variant tree set (oak / pine / bush / dead) is the canon
  Whisperwood flora. New species can be added to TREE_VARIANTS, but
  removing oak/pine/bush/dead would break silhouette continuity with
  the lore (the Sundering wounded the wood — dead trees are part of
  the wound; oaks and pines are part of the recovery).
- The `_settle_to_ground` helper is the official answer to "asset is
  half-buried / floating." Future asset wire-ups should call it instead
  of hand-tuning `position.y` per asset.


## Achievements panel — the painterly crests are visible at last (run 13)

For four integrator runs the same gap was flagged: Art shipped six
painterly 128×128 PNG achievement crests (anvil, sapling, paw-print,
sword, handshake, castle) to `assets/icons/achievements/` and the
Achievements.gd schema carried `icon_path` for each entry, but no UI
scene loaded them. Today is the first session where a player can press
`J` and **see the painterly crests rendered in the world**.

### What the player sees on press-J

A 740×580 parchment-styled panel centered on screen:

- "📜 Achievements & Titles" header, palette §3 burnt gold with black
  outline.
- An "Equipped Title:" strip showing whatever the auto-equipper picked
  ("✨ the Apprentice" / "✨ the Forged" / "✨ Wolf-Friend" / etc.) — the
  same string drawn above the player's head as a Label3D, so a kid
  reading at 30m camera distance can confirm what's equipped.
- "Earned: X of N" running count.
- A 2-column grid of 6 cards (priority-ordered: Apprentice → Forged →
  Wolf-Friend → Goblin-Bane → Trusted → Warden). Each card:
  - 96×96 painterly crest, full color when unlocked, 0.45 grey-dim when
    locked, with 🔒 overlay.
  - Name in palette §3 burnt gold (or dim grey if locked).
  - Desc in parchment cream, autowrap — these are the kid-readable
    hints at how to earn each entry. ("Bring Edda to the anvil — feel
    her hammer." for First Forge; "Drive the dire wolves below their
    first threshold." for Pack Thinner.)
  - "✨ Grants: \"the Apprentice\"" hint line so the player knows which
    title each entry awards.

### The pulse — THEME §12 motion in the UI

When a player unlocks an achievement, `_check_achievements` writes the
ID into `world._last_achievement_unlocked` (NEW field this run). On the
next panel open, that card pulses softly — 2 loops of sine-eased
modulate (1.25, 1.15, 0.85) over 0.9 seconds — drawing the player's
eye to the new entry. The pulse field clears when the panel closes, so
re-opening on a stale id doesn't re-fire.

### Why the auto-equipper didn't already do this

The auto-equipper (run 11) just floats the highest-priority unlocked
title above the player's head. It does NOT show the catalog, the
locked entries, the descriptions that hint at how to unlock the rest,
or the painterly art. The auto-equipper is the visible consequence;
the panel is the BROWSE surface — they are complementary.

### The four-run gap finally closes

Run 5 integrator gap, run 6 integrator gap, run 11 integrator gap, run
12 integrator gap — all flagged the same shape: "icon_path field
exists on every achievement entry; no UI scene loads it; the 🔨 / 🌱 /
🐺 / ⚔ / 🤝 / 🏰 emoji fallback is what actually displays." This run
ships the canonical `load(icon_path) -> Texture2D -> TextureRect`
pattern — six crests visible immediately, plus a documented reference
implementation other panels can copy to close the same gap for 13 NPC
portraits, 8 enemy portraits, and ~40 item icons.

### The unblocked pattern

The exact callsite that closes the gap is short enough to quote:

```gdscript
var icon_path: String = String(entry.get("icon_path", ""))
if icon_path != "" and ResourceLoader.exists(icon_path):
    var tex: Texture2D = load(icon_path) as Texture2D
    if tex != null:
        crest.texture = tex
```

That is the entire pattern. Any future panel needing a painterly icon
copies it verbatim.

### Closed loops; do not casually re-open

- The `J` key is now spoken-for as the Journal/Achievements toggle. If
  a future run wants Journal proper (quest log, lore index, etc.), it
  should re-bind the achievements panel to a different key (e.g. `K`)
  rather than commandeer `J`.
- The widget bundle `ach_card_widgets[id] -> {root, crest, name, desc,
  title_hint, lock}` is the documented schema. Future per-card features
  (click-to-track, quest-jump-shortcut, etc.) re-enter through this
  registry, not by re-walking the GridContainer children.
- `_last_achievement_unlocked` is ephemeral session state — it does not
  persist across save/load. The pulse is a "this just happened, look at
  it" affordance, not a "this is special forever" affordance.

## Mini-Map & World-Map (Builder run 14)

The realm now has a permanent compass on the player's HUD and a full
parchment scroll one keypress away.

**Always-on mini-map** — A 178×178 painterly compass-disc anchored top-
right. Player at center as a pulsing gold dot with heading triangle;
the disc rotates each frame so player-forward stays up. NPCs as gold
pins, enemies as crimson pins (flashing if within 8m aggro), boss as
warlock skull, chests as bronze rings, goblin fires as embers, the
fixed landmarks (Briarwood Square, Stone Well, Village Campfire,
Crystal Caves, two goblin camps, Mountain Pass boss) as kind-glyphs.
Anything beyond the 30m view radius is clamped to the rim with an
outward tick — the player always sees "the cave is over there" even
when it's far off-screen.

**World map (N)** — A 760×540 parchment scroll showing the entire
±80m realm. Region watercolor washes mark Briarwood, Whisperwood
(west + east), Crystal Caves, and Mountain Pass. All landmarks named.
A 5-point gold "you-are-here" star pulses with a heading wedge.
Distance-to-Briarwood and distance-to-Crystal-Caves shown top-right.
Compass rose lower-right.

The two views share `Minimap.LANDMARKS` as their single source of
truth: appending one row teaches both views about a new place. Same
goes for the live group plotting — any node added to `npcs`,
`enemies`, `bosses`, `chests`, or `goblin_fires` shows up on both
views the next frame, no extra wiring.

This is also the first run where NPCs join the `npcs` group; future
schedule, memory, and faction-aware readers can iterate that group
to "see everyone in Briarwood right now" in O(n) without reaching
into WorldBuilder's NPCS const.

## Lorekeeper run — Codex seeded (Stag-Court's Courtesy)

The `eldoria-godot/data/codex/` directory now exists. Its first entry
is a discoverable fragment found in the Crystal Caves on first-visit
after player_level 6: **The Stag-Court's Courtesy** — an in-world
scribe's account of being offered a seat at the Antler Crown and
declining. The fragment establishes that the Stag-Court's offer to
mortals is a recurring formal courtesy (*ai-mhorren*), not a fey
trap; that the cost of the seat is "one mortal year, remembered
backwards"; and that the offer, once made, is set down rather than
withdrawn. This is the mythic frame that makes Elder Maeve's
private situation (`elder_maeve.md`, "A secret she keeps") canonical
without forcing a resolution — the rule exists; Maeve's specific
story stays where her bible keeps it.

### Codex file format established by this run

Codex entries live in `eldoria-godot/data/codex/{id}.md` with a
YAML frontmatter block followed by markdown body:

```yaml
---
id: stag_courts_courtesy
title: The Stag-Court's Courtesy
category: fragments               # fragments | bestiary | flora | history | song
region: crystal_caves
discover_trigger:
  kind: enter_region
  region: crystal_caves
  first_visit_only: true
gating:
  player_level_gte: 6
  world_flag_required: crystal_caves_unlocked
narrator: in_world_scribe
era: pre_sundering_late
length: short                     # short | medium | long
codex_unlock_announce: "A folded leaf..."
icon_glyph: leaf-and-antler
---
```

The body is the in-world text plus a "What this establishes / does
NOT establish" section, cross-canon refs, and hooks for future
runs — same shape downstream agents already expect from the
`lore/npcs/*.md` files. Frontmatter validates as YAML; future
Builder/UI run can parse it with the same loader they use for
quest catalog metadata.

### Old Faerie additions

Three new words enter canon: ***vael-i-thirren*** ("we are
remembering you"), ***ai-mhorren*** ("the gift that is the
asking"), ***velhain-tor*** ("go warmly"). They sit alongside
*thirre*, *ai-velin*, *kerrithen* (`world.md`), *vael-tor*,
*thressa-mai* (`elder_maeve.md`), and *haethe*, *unnen*
(`smith_edda.md`). Future runs may reference any of the eight
without re-defining; the canonical home of each definition is
the file it was first seeded in.

### What downstream agents may now build on

- **Builder/UI:** a Codex panel keyed by `category → entries[]` with
  the YAML frontmatter as the parse target. Fragments first;
  bestiary/flora/history/song reserved.
- **Builder (region):** a loose flagstone in the Crystal Caves on
  the third turn after the second crystal arch, triggering a
  one-shot codex unlock + the announce-toast quoted in the
  frontmatter.
- **Audio:** a single Celtic flute note when the leaf drops, no
  chord. The leaf falls to silence.
- **Character (NPC):** Maeve's reaction to the codex being
  presented to her is `silence + anim_nod_slow`. Not a spoken
  line. Past 3 collected fragments, she gains one new dialogue
  branch — *"You have been listening, traveler. Walk warmly."*
  (the parting blessing in untranslated Common).
- **Festival timing:** a Foxthaw-only line — *"Mind the
  forest-line tonight, traveler."* — is now lore-eligible for
  Maeve, Lyra, and Roan only. Not the others.

### Closed loops; do not casually re-open

- The Stag-Court is a **courtesy**, not a trap. The Antler-King is
  glad when mortals refuse the seat. Future writers must not
  flip this softness for a cheap betrayal beat. If a darker fey
  power is needed, write it under the older-than-the-Sundering
  layer (`world.md`: *"There are older powers under these"*) and
  leave the Stag-Court as it is.
- The fragment's scribe is not named. She remains a *thressa-mai*
  in the village's memory. Don't name her cheaply.
- The Antler-King is the speaking voice of the Court at one
  moment of one offering. Whether there is one King or many, a
  Queen, a rotation — open question. Future Lorekeeper runs may
  shape it; please leave it open until then.
- Maeve does not speak the Stag-Court's offer aloud. Ever. A
  Builder run wiring a codex-presented branch on her dialogue
  tree must use silence + nod, not text.


## Lore Run — 2026-05-05 (The Steppe-Rider's Refusal — codex pair-fragment)

### Artifact shipped

- `eldoria-godot/data/codex/steppe_riders_refusal.md` — the second
  Crystal-Caves fragment, narratively pressed beneath the Briarwood
  scribe's leaf from the first fragment. A Steppe-rider's hand,
  block-cut and runic, pinned with a thorn of cold iron. The two
  fragments now form a canonical **pair** ("what the cave keeps"),
  and the codex system is asked (gently) to support a
  `prerequisite_codex` field so the second leaf gates on the first.

### What is now canon (load-bearing)

- **Stone-Tongue is writable.** Three Stone-Tongue words enter canon:
  *korthain* ("I refuse, but warmly," with hand-on-ground gesture),
  *thrunn* ("the Stone-oath kept in writing"), *korr* ("what you owe
  to weather"). The cultural rule is now explicit: Stone-Tongue
  **binds**, where Old Faerie **describes.** Stone-Tongue lexicon
  ceiling for now is **ten** words; add sparingly.
- **The Stag-Court's offer is universal.** Not a Briarwood-only
  custom. Any mortal who walks close enough to the forest-line on
  the right Foxthaw night may receive *ai-mhorren*; the cost is the
  same (one mortal year, remembered backwards), the wording is the
  same.
- **The Court's authority has a humility-shaped limit.** The Court
  does not keep High Steppe names; the cairns do. The Antler-King
  acknowledges this in the Old Faerie compound *drevenn-i-haern*
  ("the watching-stones already hold her"). The Court declines to
  claim what is not theirs to claim. Future Court-vs-anything writing
  must remember this.
- **The Crystal Caves are a *thirre* held jointly** by Vellum and the
  Court. *"The cave does not belong to the Court, but the Court
  visits."* This locks the Caves as the canonical fragment-bearing
  region; future codex pages of category `fragments` should be
  preferentially seeded here.
- **A Briarwood-Steppe linguistic bridge:** *velhain-tor* (Briarwood,
  warm-hearth-return) and *korr* (Steppe, weather-debt) pair as
  parallel parting-words. Any future NPC who knows both has crossed
  cultures. Roan canonically qualifies; Maeve silently might.

### Old Faerie + Stone-Tongue glossary — additions

- ***korthain*** *(KOR-thayn)* — Stone-Tongue. "I refuse, but
  warmly." With hand-on-ground gesture.
- ***thrunn*** *(THRUHN)* — Stone-Tongue. "The Stone-oath kept in
  writing." Bound twice — in bones and in writing — and still
  binding if the writing is destroyed.
- ***korr*** *(KOR)* — Stone-Tongue. "What you owe to weather." Used
  as benediction and private acknowledgement.
- ***drevenn-i-haern*** *(DREV-en ee HAYRN)* — Old Faerie compound,
  Court phrasing. "The watching-stones already hold her." Said by
  the Court of a Steppe death, in respectful deference to cairn-keeping.
  Briarwood scholars may use it for Steppe deaths; not for Briarwood deaths.

Old Faerie lexicon now: 19 words. Stone-Tongue lexicon now: 3 words.

### Cross-references seeded this run

- The fragment quotes *vael-i-thirren, ai-mhorren, velhain-tor* (first
  fragment) and *thirre, kerritha-ed* (`world.md`,
  `stablemaster_roan.md`), all in their canonical senses.
- **Stablemaster Roan**: gets one new optional Foxthaw-evening
  dialogue line — *"I have read what the cave keeps, traveler.
  Korr."* — gated on both fragments read AND month == Foxthaw.
  Builder may wire when convenient.
- **Elder Maeve**: silent reaction to the Stag-Court codex extends
  when both fragments are presented in sequence — silence, slow nod,
  and one inline gesture (palm-down on table, *korthain* without
  the saying). Builder: gate on `anim_hand_lay_flat` existing or
  `anim_palm_down_table`; ship slow-nod alone if no animation
  available.
- **The Foxthaw warning line** ("Mind the forest-line tonight,
  traveler"), queued for Maeve/Lyra/Roan in run 9, gains a Roan-only
  Stone-Tongue variant: *"Mind the forest-line tonight. Korr."*
  Gate identically.

### Withholding ledger (do-not-surface canon)

- The Antler-King is not named, and may or may not be a single
  individual across centuries. Both fragments are silent on this.
  Please leave it silent.
- The Steppe-rider in this fragment has no name and never will.
  Stone-Tongue does not sign. Future writers may quote and refer
  but must not name.
- The kin the Steppe-rider came south to find has no name. She is
  explicitly **not Cailen** (different gender, different role —
  she *won* the Stone Crown). She is unnamed by the rider's
  *thrunn*; the cave keeps her name with his.
- What lies beyond the forest-line is still withheld. The Court is
  encountered *at* the line, not past it.
- The Stone-Tongue glossary is capped at ten words for now.
  Builder/UI must not surface a "learn Stone-Tongue" mechanic.

### Hooks queued for future runs

- A **third fragment** is structurally allowed but should not be
  written reflexively. If written, the hand should be from a
  third direction not yet covered (a southern scribe? a bard of
  Erris?). It must add a third refusal *or* a fourth shape; do not
  resolve either of the first two. *Withhold "yes" canon.*
- **Cailen's Horseshoe** quest, if ever written, now has a clear
  destination: a *thirre*-stone on the **High Steppe**, not anywhere
  in Whisperwood. The Court has already declined that name.
- **Audio**: a single low Steppe drum-beat paired with the first
  fragment's flute note, played quietly when a player who has read
  both fragments re-enters the Caves. Audio agent owns.
- **UI**: when both fragments are unlocked, render them as a bound
  pair in the Codex panel ("What the cave keeps").
- **Renown**: a "Caves-keeper" sub-track may surface; reading both
  fragments is the natural first tick. Label: *"You have read what
  the cave keeps."*

### Top-priority next (refresh)

- Item flavor text in `data/items_flavor.json` (priority 4) — still
  not started. Strong candidate for a future Lore run: a small
  curated set of named items (Cailen's Horseshoe iron, Edda's
  *haethe*-blade, Lyra's *thalen-ai* salve, the small Steppe-iron
  nail Roan keeps) with hand-painted prose. Stays in canon by
  pulling from existing NPC bibles.
- Faction politics (priority 6) — still not started. Iron Crown's
  decision-not-yet-made about Briarwood is the load-bearing seed.
- A **third fragment** is *allowed* but should be deferred at least
  one Lore run; let the pair sit.
