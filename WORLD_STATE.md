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
- 🔥 **Top-priority next:** Roan-issued wolf-bounty quest (-0.1 reducer
  for `dire_wolves`). Mirrors `ears_for_mara` as the second goblin reducer.
  After run 8, the dialogue tier is in place but Roan still has no QUEST
  to OFFER as a wolf-pressure reducer — the only path to drop wolves is
  Lyra's pelt fetch. A Roan-issued bounty (-0.1) takes pressure 0.4 → 0.3
  on top of `pelt_for_lyra`, trips the SECOND wolf-spawn threshold (3 → 2),
  AND drops adaptive cooldown another step — one quest, three visible
  world changes (Roan's lines stay warm, fewer wolves, faster surviving
  wolves). Single new quest definition + faction `consequence: -0.1`
  payload. Composes with the Roan-arc started in run 8.
- 🔥 **Adjacent next:** Roan `warm_flag` tier. Once Roan ISSUES the
  bounty quest above, set `first_bounty_done` (or similar) on Roan's
  `npc_flags` and ship 4 `warm_lines` for personal warmth — promoting
  Roan from a faction-only NPC to a fully 4-tier NPC. Mirrors Mara's
  `good_customer` pattern. Together with run 8's faction tier, Roan
  gets the same dialogue depth as Maeve / Mara / Lyra.
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
- 🔥 **Adjacent next:** Roan-issued wolf-bounty quest (-0.1 reducer for
  `dire_wolves`). Mirrors `ears_for_mara` as the second goblin reducer.
  Trips the second wolf-spawn threshold (3 → 2) AND drops cooldown another
  step — single quest, two visible world changes, both readable to a kid.
  Compose with Roan's faction-tier dialogue above to ship a complete
  Roan-arc on the `dire_wolves` compound.
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
Populated as runs ship reactive dialogue.)

| NPC                  | Role     | Player relationship | Reactive lines (run 3) | Memory flags consumed |
|----------------------|----------|---------------------|------------------------|------------------------|
| Elder Maeve          | quest    | warms after first quest; senses goblin retreat | ✅ 4 (npc-flag, integrator) + ✅ 4 (faction, run 4) | `first_quest_done` (Whisperwood Cleansing); `whisperwood_goblins` pressure < 0.9 |
| Smith Edda           | smithy   | neutral             | ❌ (forge UI not shipped) | —                       |
| Mara the Merchant    | shop     | warms after ear bounty | ✅ 4 (npc-flag, integrator) | `good_customer` (ears_for_mara) |
| Herbalist Lyra       | alchemy  | warms after pelts   | ✅ 4 (npc-flag) + ✅ 4 (world-flag, run 3 follow-up) | `trusts_player` (pelt_for_lyra), `lyra_potion_brew` (world flag) |
| Innkeeper Bram       | inn      | neutral             | ❌ (no quest yet) | —                       |
| Stablemaster Roan    | stable   | warms when wolves quiet | ✅ 4 (faction, run 8) | `dire_wolves` pressure < 0.5 |
| Trainer Hala         | trainer  | neutral             | ❌ (no quest yet) | —                       |

Live data in `World.npc_flags[npc_name] -> Array[String]`. Read with
`World.npc_has_flag(npc, flag)`. Mutated by quest consequences only — never
by direct dialogue branches (those READ flags, they don't WRITE them).

## Faction State

(No scalars yet. Listed for downstream runs to wire.)

| Faction          | Disposition | Pressure | Notes                          |
|------------------|-------------|----------|--------------------------------|
| Briarwood        | friendly    | 0.0      | safe hub                       |
| Whisperwood Goblins | hostile  | 1.0      | mutable; cleansing & ear bounty reduce; **Maeve speaks at <0.9 (run-4 dialogue tier 3); spawns drop at <0.9/<0.7/<0.4/<0.15 (run-5 spawn density); attack cooldown lerps 1.45→1.05 (run-7 adaptive pacing); chase_speed lerps +17% (run-8 adaptive pacing)** |
| Dire Wolves      | hostile     | 0.5      | mutable; pelt quest reduces by 0.1; **Roan speaks at <0.5 (run-8 dialogue tier 3); spawns drop at <0.5/<0.3/<0.15 (run-6 spawn density); attack cooldown lerps 1.45→1.05 (run-7 adaptive pacing); chase_speed lerps +17% (run-8 adaptive pacing)** |
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
  the SAME wolves missing from the SAME forest patches. (Run 6.)
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
