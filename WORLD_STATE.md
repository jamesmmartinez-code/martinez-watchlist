# World State — Realm of Eldoria

Canonical facts about the world. This is the source of truth for *what exists*
and *what has happened*. Update this file whenever the world changes.

## World Canon

### Foundational Lore (canon, see `eldoria-godot/lore/world.md`)
- **The Sundering** — cataclysm that shaped the world. The Pale Wyrm broke
  against Vellum the Patient Stone; the mountains are Vellum's spine, the
  Whisperwood is the Wyrm's exhalation, the Crystal Caves are the wound.
  The Pale Wyrm sleeps but is not dead. (Connects to: existing `frost_saber`
  flavor, `dragonfang`/`dragonscale` legendary tier.)
- **The Three Crowns** — Iron Crown (mortal kings, distant south), Antler
  Crown (fey Stag-Court, deep Whisperwood), Stone Crown (mountain clans of
  the High Steppe). Briarwood pays tribute to none of them.
- **The Wild Pantheon** — Brigid the Forge-Mother (Smith Edda's anvil bears
  her mark), Thiar the Stag (hunters' god), Vellum the Patient Stone
  (oaths), the Hollow King (winter), Erris of the Two Roads (chance,
  travel, songs).
- **The Calendar** — 12 moons of 28 nights. Honeysong (midsummer) and
  Longnight (midwinter) are the two great festivals.
- **The Tongues** — Common (trade), Old Faerie (rare; Stag-Court), Goblin
  Cant (broken descendant of Old Faerie — the goblins were once *something
  else*), Stone-Tongue (mountain clans).
- **Old Faerie words now in canon** — `thirre` (memory of stone, a place
  where time pools), `ai-velin` (the long path / starlight / a life from
  cradle to cairn), `kerrithen` (to lay something down so the land may
  hold it). NPCs and codex entries should use these consistently.

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
- 🔥 **Top-priority next:** Faction-pressure dialogue. NPC.gd already
  resolves the World node and has the precedent of consulting it inside
  `_on_interact()`. One more tier — between world-flag warm and time-of-day
  variants — could let Maeve sense `World.faction_pressure("whisperwood_goblins")
  < 0.4` and say "the Whisperwood is forgetting the goblins." Closes the
  consequence-resolver loop: factions go from "written by quests" to
  "spoken by NPCs" without any new primitive.
- 🔥 **Adjacent next:** Goblin spawn density should read
  `World.faction_pressure("whisperwood_goblins")`. Lower pressure → fewer
  patrols / longer respawn. Single read, big behavior delta.
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
| Elder Maeve          | quest    | warms after first quest | ✅ 4 (npc-flag, integrator) | `first_quest_done` (Whisperwood Cleansing) |
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
| Whisperwood Goblins | hostile  | 1.0      | mutable via `pressure_delta`; cleansing & ear bounty quests both reduce |
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
  surfaced to NPCs.
- Quests completed: surfaced as toast only; no NPC remembers them.
- Roads defended: not modeled.
- Buildings damaged: not modeled.

## Recent Run Summary

See CHANGES.md for the human-readable run log.
