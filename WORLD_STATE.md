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
- 🔥 **Top-priority next:** Goblin spawn density reads
  `World.faction_pressure("whisperwood_goblins")`. Scale count / respawn
  time inversely with pressure. Pairs with run-4: dialogue *speaks* the
  faction state, spawning *enacts* it. Single read, big behavior delta.
- 🔥 **Adjacent next:** Roan (Stablemaster) → `dire_wolves` faction tier.
  Smoke-tests the 4-tier system on an NPC with no warm_flag at all.
  Schema is in place, only WorldBuilder edits required.
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
| Stablemaster Roan    | stable   | neutral             | ❌ (no quest yet) | —                       |
| Trainer Hala         | trainer  | neutral             | ❌ (no quest yet) | —                       |

Live data in `World.npc_flags[npc_name] -> Array[String]`. Read with
`World.npc_has_flag(npc, flag)`. Mutated by quest consequences only — never
by direct dialogue branches (those READ flags, they don't WRITE them).

## Faction State

(No scalars yet. Listed for downstream runs to wire.)

| Faction          | Disposition | Pressure | Notes                          |
|------------------|-------------|----------|--------------------------------|
| Briarwood        | friendly    | 0.0      | safe hub                       |
| Whisperwood Goblins | hostile  | 1.0      | mutable; cleansing & ear bounty reduce; **Maeve speaks at <0.9 (run-4 dialogue tier 3)** |
| Dire Wolves      | hostile     | 0.5      | mutable; pelt quest reduces by 0.1 |
| Crystal Caves    | hostile     | 0.0      | placeholder; dungeon not placed |

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
- Quests completed: surfaced as toast AND (run 4) as faction-pressure shifts
  that NPCs now narrate. `apply_consequence()` is no longer write-only on the
  faction key.
- Roads defended: not modeled.
- Buildings damaged: not modeled.

## Recent Run Summary

See CHANGES.md for the human-readable run log.
