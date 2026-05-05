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
- NPC dialogue is static. First reactive dialogue (after first goblin kill,
  after first quest turn-in) compounds 7 NPCs × 3+ states.
- Faction state has no scalar yet. Adding `bandit_pressure: float` to World.gd
  unlocks Rules 5/6/11/12 of the backlog at once.
- Player housing has no anchor point. A flat plot east of Briarwood (positive
  X, near +12,0,+4) is reserved for it.

## NPC Memory

(Tracks who has spoken to whom, who has been thanked, who has been ignored.
Populated as runs ship reactive dialogue.)

| NPC                  | Role     | Player relationship | Memory flags |
|----------------------|----------|---------------------|--------------|
| Elder Maeve          | quest    | neutral             | none         |
| Smith Edda           | smithy   | neutral             | none         |
| Mara the Merchant    | shop     | neutral             | none         |
| Herbalist Lyra       | alchemy  | neutral             | none         |
| Innkeeper Bram       | inn      | neutral             | none         |
| Stablemaster Roan    | stable   | neutral             | none         |
| Trainer Hala         | trainer  | neutral             | none         |

## Faction State

(No scalars yet. Listed for downstream runs to wire.)

| Faction          | Disposition | Pressure | Notes                          |
|------------------|-------------|----------|--------------------------------|
| Briarwood        | friendly    | 0.0      | safe hub                       |
| Whisperwood Goblins | hostile  | 1.0      | static; raids not yet wired    |
| Dire Wolves      | hostile     | 0.5      | wander, no pack behavior yet   |
| Crystal Caves    | hostile     | unset    | dungeon not placed             |

## Player Impact Ledger

(Cumulative consequences of player actions. Empty until reactive systems exist.)

- Goblins killed (lifetime): tracked per-save in Player.kills_by_kind, not yet
  surfaced to NPCs.
- Quests completed: surfaced as toast only; no NPC remembers them.
- Roads defended: not modeled.
- Buildings damaged: not modeled.

## Recent Run Summary

See CHANGES.md for the human-readable run log.
