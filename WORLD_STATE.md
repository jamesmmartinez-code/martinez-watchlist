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
  faction-tier lines on `dire_wolves` < 0.5. He is the FIRST NPC with NO
  `warm_flag` of his own — every prior warm-faction author (Maeve, Lyra)
  also carries an NPC-flag tier, so Roan smoke-tests the 4-tier dialogue
  stack on a villager whose ONLY warm tier is the faction read. The
  schema generalizes. `World.faction_pressure("dire_wolves")` now has
  THREE consumers (wolf spawn density, enemy attack cooldown, Roan
  dialogue tier 3), and the `dire_wolves` compound now has its FOURTH
  leg landed: a single -0.1 quest (`pelt_for_lyra`) changes the world
  on four readable axes — who he sees, how many he sees, how fast they
  hit, and what the stablemaster says about it.
- ✅ **Resolved 2026-05-04 (run 9):** Achievements + Title system shipped.
  `Achievements.gd` (NEW) is a pure read of `factions` / `world_flags` /
  `npc_flags` — no new world primitive. `World.unlocked_achievements:
  Dictionary` and `World.current_title: String` are runtime state mutated
  ONLY by `_check_achievements()`, which fires at the end of every
  `apply_consequence(...)` and once at `_ready()` (deferred). Five
  achievements ship at run 9: `first_steps` (any starter quest, title
  *the Apprentice*), `pack_thinner` (`dire_wolves` < 0.5, title
  *Wolf-Friend*), `goblin_bane` (`whisperwood_goblins` < 0.7, title
  *Goblin-Bane*), `trusted_three` (Maeve + Lyra + Mara warm-flags, title
  *the Trusted*), and `realm_warden` (BOTH factions humbled AND three
  trusts, title *Warden of Eldoria*, priority 100). `Player.set_title(s)`
  drives a Label3D anchored at y=2.4 above feet, billboarded, gold-leaf
  modulate, 8px black outline, looping Y-bob (THEME §12). The auto-
  equipper picks the highest `title_priority` unlocked title — Owen never
  has to fiddle. After run 8 `World.faction_pressure()` had three
  consumers; run 9 adds a FOURTH for `dire_wolves` (achievement
  predicates) and broadens the picture to SIX total consumer-edges across
  all factions: NPC.gd dialogue tier 3, goblin spawn density, wolf spawn
  density, enemy attack cooldown, Roan dialogue, achievement predicates.
  `world_flags` gains its first multi-flag reader (the `any_of` predicate
  of `first_steps` reads three world flags in a single eval). `npc_flags`
  gains its first cross-NPC reader (`all_npc_flags` checks Maeve, Lyra,
  AND Mara in one predicate — previously each NPC only read its own
  flags via NPC.gd Tier 1). Mastery threshold for Rule 1 ("compound,
  don't sprawl") demonstrated AGAIN: an entire reward layer added by
  reading what the world already writes.
- 🔥 **Top-priority next:** Roan-issued wolf-bounty quest (-0.1 reducer
  for `dire_wolves`). Mirrors `ears_for_mara` as the second goblin
  reducer. Trips the second wolf-spawn threshold (0.4 → 0.3, 3 → 2
  wolves) AND drops attack cooldown another step AND keeps Roan's
  faction-tier lines firing — single quest, three visible world changes,
  all readable to a kid. Now that Roan's dialogue (run 8) speaks the
  state, Roan-issuing the bounty is the canonical NPC↔quest pairing.
- 🔥 **Adjacent next:** Bram (Innkeeper) faction-tier on `whisperwood_goblins`
  < 0.4 OR Hala (Trainer) faction-tier on `dire_wolves` < 0.3 — second
  proof of the no-warm_flag pattern Roan just established, and a chance
  to put a dialogue tier on a low-threshold ("the wood is almost
  ours again") moment that the player rarely reaches but that pays
  off enormously when they do. Use the same ~6-line authoring rule
  documented in SYSTEM_REGISTRY.md.
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
| Stablemaster Roan    | stable   | warms when wolves thin | ✅ 4 (faction, run 8) | `dire_wolves` pressure < 0.5 |
| Trainer Hala         | trainer  | neutral             | ❌ (no quest yet) | —                       |

Live data in `World.npc_flags[npc_name] -> Array[String]`. Read with
`World.npc_has_flag(npc, flag)`. Mutated by quest consequences only — never
by direct dialogue branches (those READ flags, they don't WRITE them).

## Faction State

(No scalars yet. Listed for downstream runs to wire.)

| Faction          | Disposition | Pressure | Notes                          |
|------------------|-------------|----------|--------------------------------|
| Briarwood        | friendly    | 0.0      | safe hub                       |
| Whisperwood Goblins | hostile  | 1.0      | mutable; cleansing & ear bounty reduce; **Maeve speaks at <0.9 (run-4 dialogue tier 3); spawns drop at <0.9/<0.7/<0.4/<0.15 (run-5 spawn density); attack cooldown lerps 1.45→1.05 (run-7 adaptive pacing)** |
| Dire Wolves      | hostile     | 0.5      | mutable; pelt quest reduces by 0.1; **spawns drop at <0.5/<0.3/<0.15 (run-6 spawn density); attack cooldown lerps 1.45→1.05 (run-7 adaptive pacing); Roan speaks at <0.5 (run-8 dialogue tier 3)** |
| Crystal Caves    | hostile     | 0.0      | placeholder; dungeon not placed; **skeleton/crystal_elemental/crystal_guardian cooldown wired (run-7) — fires the moment the dungeon ships** |

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
- Achievements unlocked (per session): tracked in
  `World.unlocked_achievements`. Toast on each new unlock; auto-equipped
  title floats above the player's head. Five-deep ladder ends at
  *Warden of Eldoria* (run 9). Each unlock is a *visible* reward for
  the cooperative work the kids have already done — no extra grinding,
  the achievements simply NAME compositions of state that quests already
  produce. Composes with run 4 dialogue (Maeve speaks the goblin
  state), run 5/6 spawn density (forests visibly empty), run 7 cooldown
  (⚡ pacing on survivors), run 8 Roan (wolf-tier dialogue) — the
  achievements layer is the first system that ALL prior runs feed into
  without modification.
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
