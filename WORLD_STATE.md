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
| Whisperwood Goblins | hostile  | 1.0      | mutable; cleansing & ear bounty reduce; **Maeve speaks at <0.9 (run-4 dialogue tier 3); spawns drop at <0.9/<0.7/<0.4/<0.15 (run-5 spawn density); attack cooldown lerps 1.45→1.05 (run-7 adaptive pacing)** |
| Dire Wolves      | hostile     | 0.5      | mutable; pelt quest reduces by 0.1; **spawns drop at <0.5/<0.3/<0.15 (run-6 spawn density); attack cooldown lerps 1.45→1.05 (run-7 adaptive pacing)** |
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
